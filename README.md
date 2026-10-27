<div align="center">

# 💪 Tamreeni — تمريني

**Home workout, nutrition & medication tracker · Arabic / English · No account, no ads, no tracking**

[Download APK](../../releases/latest) · [Exercise catalog](catalog/README.md) · [العربية ↓](#-العربية)

</div>

## English

Tamreeni is a free, open-source Android app (Flutter) for building muscle at home. Everything is stored **locally on your phone** — no sign-up, no ads, no analytics.

### Features
- 🗓️ **Smart plan** – pick a template (Upper/Lower, Push/Pull/Legs, Full body...) for any number of days. Miss a day and the schedule shifts automatically.
- ⏱️ **Guided workout** – rep ring (manual or auto-count), timers for timed exercises, automatic rest timer with sound/vibration, weight & RPE log, PRs, 1RM, progressive overload, deload weeks.
- 📚 **Exercise catalog (105+ exercises)** – every exercise has Arabic + English names, muscles, step-by-step instructions, tips, illustration photos and a **YouTube tutorial that plays inside the app**. Tap **Update** to pull new/changed exercises from this GitHub repository.
- 🤖 **AI plan builder** – describe what you want, copy the ready-made prompt (it includes the catalog) into any AI, paste the answer back, and it becomes your plan instantly.
- 💧🍽️ **Water & food** – daily goals for water, calories, protein and carbs. **Saved meals** you can re-add with one tap, and a **photo → AI prompt** flow: photograph the meal, share it with the prompt to any AI, paste the JSON result back and the macros are logged.
- 💊 **Medications & treatments** – doses, times, weekdays, course length, before/after-meal notes, reminders (+ optional second reminder if you did not mark it taken) and an adherence history.
- 🔥 **Streak nudges** – if you are late for your workout time you get a random motivational notification.
- 🌐 **Arabic (RTL) & English**, light/dark theme, import/export (Excel / JSON), full backup.

### Install
- **Direct:** download the latest `Tamreeni-vX.Y.Z.apk` from [Releases](../../releases/latest) and open it on your phone (allow "install unknown apps" for your browser).
- **F-Droid:** see [F-Droid](#f-droid) below.

### Build from source
You need Flutter (stable), JDK 17 and the Android SDK.
```bash
git clone https://github.com/alienshtain/tamreeni.git && cd tamreeni && bash tool/setup.sh
```
The APK is created at `build/app/outputs/flutter-apk/app-release.apk`. (`tool/setup.sh` generates the `android/` folder and applies the required manifest patches — notifications, internet permission, icon.) Detailed Fedora walkthrough: [BUILD_FEDORA.md](BUILD_FEDORA.md).

### Exercise catalog
The catalog lives in [`catalog/exercises.json`](catalog/exercises.json) and is read by the app from this repository (`raw.githubusercontent.com`). Edit an exercise, add a video, add new exercises — then bump `version` and the app's **Update** button picks it up. See [catalog/README.md](catalog/README.md). Using a fork? In the app: *More → Catalog source*.

> Video links were collected by search and are not individually verified — if one is wrong or removed, please fix it with a pull request.

### Release signing (maintainers)
Releases built by GitHub Actions are signed with the debug key unless you add these repository secrets (so every release has the same key and users can update in place): `KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD`.
```bash
keytool -genkeypair -v -keystore tamreeni.jks -alias tamreeni -keyalg RSA -keysize 4096 -validity 36500
```
```bash
base64 -w0 tamreeni.jks | gh secret set KEYSTORE_BASE64 && gh secret set KEYSTORE_PASSWORD && gh secret set KEY_ALIAS --body tamreeni
```
Publishing a release: `git tag v1.1.0 && git push origin v1.1.0` — the workflow builds the APK and attaches it to the release.

### F-Droid
Metadata is ready in [`metadata/com.alienshtain.gym_app.yml`](metadata/com.alienshtain.gym_app.yml) and `fastlane/metadata/android/`. To get listed in the official F-Droid repository, open a merge request to [fdroiddata](https://gitlab.com/fdroid/fdroiddata) with that file (the maintainers review it; the Flutter version line must be set to a current stable tag). Until then, F-Droid users can install the APK from Releases (or add it with [Obtainium](https://github.com/ImranR98/Obtainium) pointing at this repository). Anti-feature: *NonFreeNet* (tutorial videos are played from YouTube).

### Credits & license
App code: MIT (see [LICENSE](LICENSE)). Exercise illustration photos come from [free-exercise-db](https://github.com/yuhonas/free-exercise-db) (public domain / Unlicense). Exercise texts were written for this project.

---

## 🇸🇦 العربية

**تمريني** تطبيق أندرويد مجاني ومفتوح المصدر لبناء العضلات في المنزل. كل بياناتك **محفوظة على هاتفك فقط** — بلا حساب ولا إعلانات ولا تتبّع.

### المميزات
- 🗓️ **خطة ذكية** من قوالب جاهزة (علوي/سفلي، دفع/سحب/أرجل، جسم كامل...) لأي عدد أيام. إذا فاتك يوم يتحرك الجدول تلقائياً.
- ⏱️ **تمرين تفاعلي**: حلقة عدات (يدوي أو تلقائي)، مؤقتات، راحة تلقائية بصوت واهتزاز، سجل أوزان، أرقام قياسية، حمل تدريجي، أسبوع تخفيف.
- 📚 **كتالوج تمارين (105+ تمرين)**: أسماء بالعربية والإنكليزية، العضلات، خطوات الأداء، نصائح، صور توضيحية، و**فيديو يوتيوب يعمل داخل التطبيق**. زر **تحديث** يجلب التمارين الجديدة والتعديلات من هذا المستودع.
- 🤖 **خطة بالذكاء الاصطناعي**: اكتب ما تريده، انسخ البرومبت الجاهز (يحوي الكتالوج) وأرسله لأي ذكاء اصطناعي، ثم الصق الرد فتتحول خطتك مباشرة إلى التطبيق.
- 💧🍽️ **الماء والأكل**: أهداف يومية للماء والسعرات والبروتين والكربوهيدرات، **وجبات محفوظة** تعيد اختيارها بضغطة، و**تحليل صورة الوجبة**: صوّر الوجبة وأرسلها مع البرومبت لأي ذكاء اصطناعي ثم الصق النتيجة لتُسجَّل القيم تلقائياً.
- 💊 **الأدوية والعلاجات**: جرعات وأوقات وأيام ومدة علاج وتعليمات قبل/بعد الأكل، تذكيرات (وتذكير ثانٍ اختياري) وسجل التزام.
- 🔥 **تحفيز السلسلة**: إذا تأخرت عن وقت التمرين يصلك إشعار تحفيزي عشوائي.
- 🌐 عربي (RTL) وإنكليزي، مظهر فاتح/داكن، استيراد/تصدير Excel وJSON، نسخ احتياطي كامل.

### التثبيت
- **مباشرة:** نزّل أحدث ملف `Tamreeni-vX.Y.Z.apk` من صفحة [Releases](../../releases/latest) وافتحه على هاتفك (فعّل «تثبيت من مصادر غير معروفة» للمتصفح).
- **F-Droid:** راجع قسم F-Droid أعلاه.

### البناء من المصدر
```bash
git clone https://github.com/alienshtain/tamreeni.git && cd tamreeni && bash tool/setup.sh
```
يظهر الـAPK في `build/app/outputs/flutter-apk/app-release.apk`. شرح مفصل لفيدورا: [BUILD_FEDORA.md](BUILD_FEDORA.md).

### تعديل التمارين
ملف التمارين هو [`catalog/exercises.json`](catalog/exercises.json). عدّل أي تمرين أو أضف فيديو أو تمريناً جديداً، ارفع `version` بمقدار 1، وسيلتقطه زر «تحديث التمارين من GitHub» داخل التطبيق. التفاصيل في [catalog/README.md](catalog/README.md).

### الرخصة
كود التطبيق بترخيص MIT. صور التمارين التوضيحية من [free-exercise-db](https://github.com/yuhonas/free-exercise-db) (ملكية عامة).
