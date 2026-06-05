# One UI 9 framework jars can reference Android 16/S26 native signatures that do
# not exist in the S21 Exynos 2100 base. Patch only when those signatures are
# present, so older or already-adapted sources are left alone.

ONEUI9_COMPAT_DIR="$SRC_DIR/unica/patches/oneui9_compat"
HWUI_LIB="$WORK_DIR/system/system/lib64/libhwui.so"

if [ -f "$HWUI_LIB" ]; then
    if xxd -p -c 0 "$HWUI_LIB" | grep -q "8000f8379fe206f19422009141ffff54007c1f13"; then
        HEX_PATCH "$HWUI_LIB" \
            "8000f8379fe206f19422009141ffff54007c1f13" \
            "1f2003d59fe206f19422009141ffff54e0031f2a"
    elif ! xxd -p -c 0 "$HWUI_LIB" | grep -q "1f2003d59fe206f19422009141ffff54e0031f2a"; then
        LOGE "One UI 9 libhwui workaround pattern not found"
        return 1
    fi
fi

DECODE_APK "system" "system/framework/framework.jar" || return 1
FRAMEWORK_DIR="$APKTOOL_DIR/system/framework/framework.jar"
MEMORY_INT_ARRAY="$FRAMEWORK_DIR/smali_classes4/android/util/MemoryIntArray.smali"
POWER_MANAGER="$FRAMEWORK_DIR/smali_classes3/android/os/PowerManager.smali"
ANDROID_OS_FLAGS="$FRAMEWORK_DIR/smali_classes5/com/android/internal/hidden_from_bootclasspath/android/os/Flags.smali"

if [ -f "$MEMORY_INT_ARRAY" ] && grep -q "nativeOpen(IZI)J" "$MEMORY_INT_ARRAY"; then
    PATCH="$ONEUI9_COMPAT_DIR/framework.jar/0001-Adapt-MemoryIntArray-native-ABI.patch"
    if ! LC_ALL=C git apply --check --directory="$FRAMEWORK_DIR" --unsafe-paths "$PATCH" >/dev/null 2>&1; then
        LOGE "One UI 9 MemoryIntArray ABI patch does not apply"
        return 1
    fi
    APPLY_PATCH "system" "system/framework/framework.jar" "$PATCH"
fi

if [ -f "$POWER_MANAGER" ] && grep -q "0x1050158" "$POWER_MANAGER" && grep -q "Resources;->getFloat(I)F" "$POWER_MANAGER"; then
    PATCH="$ONEUI9_COMPAT_DIR/framework.jar/0002-Use-integer-backlight-fallbacks.patch"
    if ! LC_ALL=C git apply --check --directory="$FRAMEWORK_DIR" --unsafe-paths "$PATCH" >/dev/null 2>&1; then
        LOGE "One UI 9 PowerManager backlight fallback patch does not apply"
        return 1
    fi
    APPLY_PATCH "system" "system/framework/framework.jar" "$PATCH"
fi

if [ -f "$ANDROID_OS_FLAGS" ] && grep -A5 "perfettoSdkTracingV3()Z" "$ANDROID_OS_FLAGS" | grep -q "const/4 v0, 0x1"; then
    PATCH="$ONEUI9_COMPAT_DIR/framework.jar/0003-Disable-Perfetto-SDK-tracing-on-SDK36-base.patch"
    if ! LC_ALL=C git apply --check --directory="$FRAMEWORK_DIR" --unsafe-paths "$PATCH" >/dev/null 2>&1; then
        LOGE "One UI 9 Perfetto SDK tracing flag patch does not apply"
        return 1
    fi
    APPLY_PATCH "system" "system/framework/framework.jar" "$PATCH"
fi

DECODE_APK "system" "system/framework/services.jar" || return 1
SERVICES_DIR="$APKTOOL_DIR/system/framework/services.jar"
DISPLAY_CONTROL="$SERVICES_DIR/smali/com/android/server/display/DisplayControl.smali"
ADB_PAIRING="$SERVICES_DIR/smali/com/android/server/adb/AdbPairingThread.smali"

if [ -f "$DISPLAY_CONTROL" ] && \
    grep -q "nativeCreateVirtualDisplay(Ljava/lang/String;ZZLjava/lang/String;IF)" "$DISPLAY_CONTROL" && \
    ! grep -q "nativeCreateVirtualDisplay(Ljava/lang/String;ZZLjava/lang/String;F)" "$DISPLAY_CONTROL"; then
    PATCH="$ONEUI9_COMPAT_DIR/services.jar/0001-Adapt-DisplayControl-native-ABI.patch"
    if ! LC_ALL=C git apply --check --directory="$SERVICES_DIR" --unsafe-paths "$PATCH" >/dev/null 2>&1; then
        LOGE "One UI 9 DisplayControl ABI patch does not apply"
        return 1
    fi
    APPLY_PATCH "system" "system/framework/services.jar" "$PATCH"
fi

if [ -f "$ADB_PAIRING" ] && ! grep -q "native_pairing_cancel()V" "$ADB_PAIRING"; then
    PATCH="$ONEUI9_COMPAT_DIR/services.jar/0002-Add-legacy-AdbPairingThread-native-ABI.patch"
    if ! LC_ALL=C git apply --check --directory="$SERVICES_DIR" --unsafe-paths "$PATCH" >/dev/null 2>&1; then
        LOGE "One UI 9 ADB pairing ABI patch does not apply"
        return 1
    fi
    APPLY_PATCH "system" "system/framework/services.jar" "$PATCH"
fi

unset ONEUI9_COMPAT_DIR HWUI_LIB FRAMEWORK_DIR MEMORY_INT_ARRAY POWER_MANAGER ANDROID_OS_FLAGS SERVICES_DIR DISPLAY_CONTROL ADB_PAIRING PATCH
