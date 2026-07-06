#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TOOLS="$ROOT/.tools"
JDK_DIR="$TOOLS/jdk"
SDK_DIR="$TOOLS/android-sdk"
CMD_TOOLS="$SDK_DIR/cmdline-tools/latest"

mkdir -p "$TOOLS" "$JDK_DIR" "$SDK_DIR"

if [ ! -x "$JDK_DIR/bin/java" ] && [ ! -x "$JDK_DIR/Contents/Home/bin/java" ]; then
  echo "Downloading JDK 21..."
  curl -fsSL --retry 3 --retry-delay 3 "https://api.adoptium.net/v3/binary/latest/21/ga/mac/aarch64/jdk/hotspot/normal/eclipse?project=jdk" -o "$TOOLS/jdk.tar.gz"
  rm -rf "$JDK_DIR"
  mkdir -p "$JDK_DIR"
  tar -xzf "$TOOLS/jdk.tar.gz" -C "$JDK_DIR" --strip-components=1
  rm "$TOOLS/jdk.tar.gz"
fi

if [ -x "$JDK_DIR/Contents/Home/bin/java" ]; then
  export JAVA_HOME="$JDK_DIR/Contents/Home"
else
  export JAVA_HOME="$JDK_DIR"
fi

if [ ! -f "$CMD_TOOLS/bin/sdkmanager" ]; then
  echo "Downloading Android command line tools..."
  curl -fsSL --retry 3 --retry-delay 3 --connect-timeout 30 --max-time 600 \
    "https://mirrors.cloud.tencent.com/AndroidSDK/commandlinetools-mac-11076708_latest.zip" \
    -o "$TOOLS/cmdline-tools.zip"
  mkdir -p "$SDK_DIR/cmdline-tools/latest"
  unzip -q "$TOOLS/cmdline-tools.zip" -d "$TOOLS/cmdline-tools-tmp"
  mv "$TOOLS/cmdline-tools-tmp/cmdline-tools/"* "$CMD_TOOLS/"
  rm -rf "$TOOLS/cmdline-tools-tmp" "$TOOLS/cmdline-tools.zip"
fi

export ANDROID_HOME="$SDK_DIR"
export GRADLE_USER_HOME="$TOOLS/gradle-home"
export PATH="$JAVA_HOME/bin:$CMD_TOOLS/bin:$ANDROID_HOME/platform-tools:$PATH"

mkdir -p "$HOME/.android"
cat > "$HOME/.android/repositories.cfg" <<'EOF'
### User Sources for Android SDK Manager
count=1
enabled00=true
src00=https://mirrors.cloud.tencent.com/AndroidSDK
EOF

if [ ! -d "$ANDROID_HOME/platforms/android-35" ]; then
  yes | sdkmanager --sdk_root="$ANDROID_HOME" \
    "platform-tools" \
    "platforms;android-35" \
    "build-tools;35.0.0" || true
fi

cd "$ROOT"
echo "sdk.dir=$ANDROID_HOME" > android/local.properties
npm run android:sync
cd android
GRADLE_USER_HOME="$GRADLE_USER_HOME" ./gradlew assembleDebug --no-daemon

APK="$ROOT/android/app/build/outputs/apk/debug/app-debug.apk"
OUT="$ROOT/dist/紫微命盘-1.0.0-android.apk"
mkdir -p "$ROOT/dist"
cp "$APK" "$OUT"
echo "Built: $OUT"
