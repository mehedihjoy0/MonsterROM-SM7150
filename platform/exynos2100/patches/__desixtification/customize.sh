TARGET_FIRMWARE_PATH="$(cut -d "/" -f 1 -s <<< "$TARGET_FIRMWARE")_$(cut -d "/" -f 2 -s <<< "$TARGET_FIRMWARE")"

ADD_TARGET_VENDOR_FILE_IF_EXISTS()
{
    local FILE="$1"

    [ -e "$FW_DIR/$TARGET_FIRMWARE_PATH/vendor/$FILE" ] || return 0
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "vendor" "$FILE"
}

DELETE_VENDOR_FILE_IF_EXISTS()
{
    local FILE="$1"

    [ -e "$WORK_DIR/vendor/$FILE" ] || return 0
    DELETE_FROM_WORK_DIR "vendor" "$FILE"
}

LOG_STEP_IN "- Forcing 64-bit-only vendor ABI"
SET_PROP "vendor" "ro.vendor.product.cpu.abilist" "arm64-v8a"
SET_PROP "vendor" "ro.vendor.product.cpu.abilist32" ""
SET_PROP "vendor" "ro.vendor.product.cpu.abilist64" "arm64-v8a"
SET_PROP "vendor" "ro.zygote" "zygote64"
SET_PROP "vendor" "dalvik.vm.dex2oat64.enabled" "true"
LOG_STEP_OUT

LOG_STEP_IN "- Syncing 64-bit Exynos media blobs"
EXYNOS_MEDIA_BLOBS="
lib64/libExynosC2Av1Dec.so
lib64/libExynosC2ComponentStore.so
lib64/libExynosC2H264Dec.so
lib64/libExynosC2H264Enc.so
lib64/libExynosC2HevcDec.so
lib64/libExynosC2HevcEnc.so
lib64/libExynosC2Vp8Dec.so
lib64/libExynosC2Vp8Enc.so
lib64/libExynosC2Vp9Dec.so
lib64/libExynosC2Vp9Enc.so
lib64/libExynosOMX_Core.so
lib64/libExynosOMX_Resourcemanager.so
lib64/libSecC2ComponentStore.so
lib64/libcodec2_hidl@1.0.so
lib64/libcodec2_hidl@1.1.so
lib64/libcodec2_vndk.so
"
for blob in $EXYNOS_MEDIA_BLOBS
do
    ADD_TARGET_VENDOR_FILE_IF_EXISTS "$blob"
done
LOG_STEP_OUT

LOG_STEP_IN "- Removing 32-bit vendor runtime"
DELETE_VENDOR_FILE_IF_EXISTS "bin/boringssl_self_test32"
DELETE_VENDOR_FILE_IF_EXISTS "bin/wvkprov"
DELETE_VENDOR_FILE_IF_EXISTS "bin/hw/android.hardware.audio.service"
DELETE_VENDOR_FILE_IF_EXISTS "bin/hw/android.hardware.cas@1.2-service-lazy"
DELETE_VENDOR_FILE_IF_EXISTS "bin/hw/android.hardware.drm@1.3-service.widevine"
DELETE_VENDOR_FILE_IF_EXISTS "bin/hw/android.hardware.media.omx@1.0-service"
DELETE_VENDOR_FILE_IF_EXISTS "etc/init/android.hardware.audio.service.rc"
DELETE_VENDOR_FILE_IF_EXISTS "etc/init/android.hardware.cas@1.2-service-lazy.rc"
DELETE_VENDOR_FILE_IF_EXISTS "etc/init/android.hardware.drm@1.3-service.widevine.rc"
DELETE_VENDOR_FILE_IF_EXISTS "etc/init/android.hardware.media.omx@1.0-service.rc"
DELETE_VENDOR_FILE_IF_EXISTS "etc/init/boringssl_self_test.rc"
DELETE_FROM_WORK_DIR "vendor" "lib"
ADD_TARGET_VENDOR_FILE_IF_EXISTS "lib/egl/egl.cfg"
ADD_TARGET_VENDOR_FILE_IF_EXISTS "lib/modules"
LOG_STEP_OUT

unset TARGET_FIRMWARE_PATH EXYNOS_MEDIA_BLOBS
unset -f ADD_TARGET_VENDOR_FILE_IF_EXISTS DELETE_VENDOR_FILE_IF_EXISTS
