#!/usr/bin/env bash
# يبني APK للتطبيق. شغّله من أي مكان:  bash tool/setup.sh   (أضف --prepare لتهيئة أندرويد فقط بدون بناء)
set -euo pipefail
cd "$(dirname "$0")/.."

command -v flutter >/dev/null || { echo "❌ flutter غير موجود في PATH (راجع BUILD_FEDORA.md)"; exit 1; }

if [ ! -d android ]; then
  echo "▶ إنشاء مشروع أندرويد..."
  TMP="$(mktemp -d)"
  flutter create --platforms=android --org com.alienshtain --project-name gym_app "$TMP/gym_app"
  cp -r "$TMP/gym_app/android" ./android
  rm -rf "$TMP"
fi

# توقيع ثابت اختياري (GitHub Actions): KEYSTORE_BASE64 KEYSTORE_PASSWORD KEY_ALIAS KEY_PASSWORD
if [ -n "${KEYSTORE_BASE64:-}" ]; then
  echo "$KEYSTORE_BASE64" | base64 -d > android/app/release.jks
  cat > android/key.properties <<EOF
storeFile=$(pwd)/android/app/release.jks
storePassword=${KEYSTORE_PASSWORD}
keyAlias=${KEY_ALIAS}
keyPassword=${KEY_PASSWORD:-$KEYSTORE_PASSWORD}
EOF
fi

echo "▶ تهيئة أندرويد..."
python3 tool/patch_android.py

echo "▶ تنزيل الحزم..."
flutter pub get

if [ "${1:-}" = "--prepare" ]; then
  echo "✅ تمت التهيئة (بدون بناء)"; exit 0
fi

echo "▶ بناء APK..."
flutter build apk --release

APK="build/app/outputs/flutter-apk/app-release.apk"
echo
echo "✅ تم البناء: $(pwd)/$APK"
