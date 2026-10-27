#!/usr/bin/env python3
"""يهيّئ مشروع أندرويد المُنشأ بـ flutter create: صلاحيات، مستقبلات الإشعارات، desugaring، الأيقونة، اسم التطبيق."""
import os, re, shutil, sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
AND = os.path.join(ROOT, "android")
MANIFEST = os.path.join(AND, "app/src/main/AndroidManifest.xml")

def read(p):
    with open(p, encoding="utf-8") as f:
        return f.read()

def write(p, s):
    with open(p, "w", encoding="utf-8") as f:
        f.write(s)

# ---------- AndroidManifest ----------
m = read(MANIFEST)
if "ScheduledNotificationReceiver" not in m:
    perms = """    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    <uses-permission android:name="android.permission.VIBRATE"/>
    <uses-permission android:name="android.permission.WAKE_LOCK"/>
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
    <uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
    <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" android:maxSdkVersion="32"/>
"""
    m = m.replace("<application", perms + "    <application", 1)
    receivers = """        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
                <action android:name="android.intent.action.QUICKBOOT_POWERON" />
                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
            </intent-filter>
        </receiver>
"""
    m = m.replace("</application>", receivers + "    </application>", 1)
    https = """        <intent>
            <action android:name="android.intent.action.VIEW" />
            <data android:scheme="https" />
        </intent>
"""
    if "</queries>" in m:
        m = m.replace("</queries>", https + "    </queries>", 1)
    else:
        m = m.replace("</manifest>", "    <queries>\n" + https + "    </queries>\n</manifest>", 1)
m = re.sub(r'android:label="[^"]*"', 'android:label="Tamreeni"', m, count=1)
# INTERNET مطلوب في نسخة release (قالب Flutter يضعه في debug فقط)
if 'android.permission.INTERNET' not in m:
    m = m.replace("<application", '    <uses-permission android:name="android.permission.INTERNET"/>\n    <application', 1)
write(MANIFEST, m)
print("OK manifest")

# ---------- Gradle: desugaring ----------
kts = os.path.join(AND, "app/build.gradle.kts")
groovy = os.path.join(AND, "app/build.gradle")
DESUGAR = "com.android.tools:desugar_jdk_libs:2.1.4"
if os.path.exists(kts):
    g = read(kts)
    if "isCoreLibraryDesugaringEnabled" not in g:
        g = re.sub(r"(compileOptions\s*\{)", r"\1\n        isCoreLibraryDesugaringEnabled = true", g, count=1)
    if "coreLibraryDesugaring(" not in g:
        g += '\n\ndependencies {\n    coreLibraryDesugaring("%s")\n}\n' % DESUGAR
    # توقيع release بمفتاح ثابت إن وُجد android/key.properties (يُنشأ في GitHub Actions)
    if os.path.exists(os.path.join(AND, "key.properties")) and 'create("release")' not in g:
        g = "import java.util.Properties\nimport java.io.FileInputStream\n\n" + g
        sign = '''signingConfigs {
        create("release") {
            val props = Properties()
            props.load(FileInputStream(rootProject.file("key.properties")))
            keyAlias = props["keyAlias"] as String
            keyPassword = props["keyPassword"] as String
            storeFile = file(props["storeFile"] as String)
            storePassword = props["storePassword"] as String
        }
    }

    '''
        g = g.replace("buildTypes {", sign + "buildTypes {", 1)
        g = g.replace('signingConfig = signingConfigs.getByName("debug")', 'signingConfig = signingConfigs.getByName("release")')
        print("OK release signing")
    write(kts, g)
    print("OK gradle.kts")
elif os.path.exists(groovy):
    g = read(groovy)
    if "coreLibraryDesugaringEnabled" not in g:
        g = re.sub(r"(compileOptions\s*\{)", r"\1\n        coreLibraryDesugaringEnabled true", g, count=1)
    if "coreLibraryDesugaring '" not in g:
        g += "\n\ndependencies {\n    coreLibraryDesugaring '%s'\n}\n" % DESUGAR
    write(groovy, g)
    print("OK gradle")
else:
    sys.exit("لم يوجد build.gradle(.kts) داخل android/app")

# ---------- الأيقونة ----------
src = os.path.join(ROOT, "tool/icons")
res = os.path.join(AND, "app/src/main/res")
if os.path.isdir(src):
    for d in os.listdir(src):
        if d.startswith("mipmap-"):
            os.makedirs(os.path.join(res, d), exist_ok=True)
            shutil.copy(os.path.join(src, d, "ic_launcher.png"), os.path.join(res, d, "ic_launcher.png"))
    print("OK icons")

# ---------- compileSdk 36 لكل الإضافات (file_picker وغيره يُترجم على 34 وهذا يكسر البناء) ----------
rk, rg = os.path.join(AND, "build.gradle.kts"), os.path.join(AND, "build.gradle")
MARK = "// tamreeni-compilesdk"
if os.path.exists(rk):
    s = read(rk)
    if MARK not in s:
        s = MARK + '''
subprojects {
    val forceSdk = {
        extensions.findByName("android")?.withGroovyBuilder { "compileSdkVersion"(36) }
    }
    if (state.executed) forceSdk() else afterEvaluate { forceSdk() }
}

''' + s
        write(rk, s)
    print("OK compileSdk 36")
elif os.path.exists(rg):
    s = read(rg)
    if MARK not in s:
        s = MARK + '''
subprojects {
    def forceSdk = { p -> if (p.hasProperty("android")) p.android.compileSdkVersion 36 }
    if (state.executed) forceSdk(it) else afterEvaluate { forceSdk(it) }
}

''' + s
        write(rg, s)
    print("OK compileSdk 36")
