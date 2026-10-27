# بناء APK على فيدورا (مرة واحدة للإعداد، ثم أمر واحد)

> كل أمر أدناه ينسخ ويلصق في الترمنال، واحداً تلو الآخر.

## 1) الأدوات الأساسية (جافا 17 + git ...)
```bash
sudo dnf install -y git curl unzip xz zip python3 java-17-openjdk-devel
```

## 2) Flutter
```bash
git clone https://github.com/flutter/flutter.git -b stable ~/flutter
```
```bash
echo 'export PATH="$HOME/flutter/bin:$PATH"' >> ~/.bashrc && source ~/.bashrc
```
```bash
flutter --version
```

## 3) Android SDK (بدون Android Studio)
```bash
mkdir -p ~/Android/Sdk/cmdline-tools && cd ~/Android/Sdk/cmdline-tools && curl -LO https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip && unzip -q commandlinetools-linux-11076708_latest.zip && mv cmdline-tools latest && cd ~
```
(إن أعطى الرابط 404: افتح developer.android.com/studio، قسم «Command line tools only»، وانسخ رابط linux الأحدث مكانه.)
```bash
echo 'export ANDROID_HOME="$HOME/Android/Sdk"; export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools"' >> ~/.bashrc && source ~/.bashrc
```
```bash
sdkmanager "platform-tools" "platforms;android-35" "build-tools;35.0.0"
```
```bash
flutter config --android-sdk ~/Android/Sdk
```
```bash
flutter doctor --android-licenses
```
```bash
flutter doctor -v
```
المطلوب فقط أن تظهر علامة ✓ أمام Flutter وAndroid toolchain (تجاهل Chrome وLinux desktop).

إذا اشتكى من الجافا: `sudo alternatives --config java` واختر 17، ثم
`flutter config --jdk-dir /usr/lib/jvm/java-17-openjdk`

## 4) بناء التطبيق
```bash
unzip gym_app.zip -d ~ && cd ~/gym_app
```
```bash
bash tool/setup.sh
```
أول مرة تستغرق عدة دقائق (تنزيل Gradle وحزم). الناتج:

`~/gym_app/build/app/outputs/flutter-apk/app-release.apk`

## 5) التثبيت على الهاتف
- أرسل الملف للهاتف (كابل / تيليجرام / سيرفرك) وافتحه، وفعّل «التثبيت من مصادر غير معروفة».
- أو بالكابل مع تفعيل «تصحيح USB»: `adb install -r build/app/outputs/flutter-apk/app-release.apk`

## تحديث التطبيق لاحقاً
عدّل الكود ثم أعد `bash tool/setup.sh` وثبّت الملف فوق القديم (البيانات تبقى لأن التوقيع واحد على نفس الجهاز).

## إذا ظهر خطأ
انسخ آخر 30 سطراً من الخطأ (أو صوّر الشاشة) وأرسلها لي. إذا كان الخطأ في إعدادات أندرويد فقط:
`rm -rf android && bash tool/setup.sh`
