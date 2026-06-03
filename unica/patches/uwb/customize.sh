SOURCE_FIRMWARE_PATH="$(cut -d "/" -f 1 -s <<< "$SOURCE_FIRMWARE")_$(cut -d "/" -f 2 -s <<< "$SOURCE_FIRMWARE")"
TARGET_FIRMWARE_PATH="$(cut -d "/" -f 1 -s <<< "$TARGET_FIRMWARE")_$(cut -d "/" -f 2 -s <<< "$TARGET_FIRMWARE")"

SOURCE_HAS_UWB="$(test -f "$FW_DIR/$SOURCE_FIRMWARE_PATH/vendor/etc/permissions/android.hardware.uwb.xml" && echo "true" || echo "false")"
TARGET_HAS_UWB="$(test -f "$FW_DIR/$TARGET_FIRMWARE_PATH/vendor/etc/permissions/android.hardware.uwb.xml" && echo "true" || echo "false")"

DELETE_IF_EXISTS()
{
    local PARTITION="$1"
    local FILE="$2"
    local FILE_PATH="$WORK_DIR"

    while [[ "${FILE:0:1}" == "/" ]]; do
        FILE="${FILE:1}"
    done

    if [[ "$PARTITION" == "system_ext" ]]; then
        if $TARGET_OS_BUILD_SYSTEM_EXT_PARTITION; then
            FILE_PATH+="/system_ext/$FILE"
        else
            FILE_PATH+="/system/system_ext/$FILE"
        fi
    else
        FILE_PATH+="/$PARTITION/$FILE"
    fi

    if [ -e "$FILE_PATH" ] || [ -L "$FILE_PATH" ]; then
        DELETE_FROM_WORK_DIR "$PARTITION" "$FILE"
    fi
}

if ! $SOURCE_HAS_UWB; then
    if $TARGET_HAS_UWB; then
        LOG "- Adding \"ro.boot.uwbcountrycode\" prop with \"ff\" in /product/etc/build.prop"
        EVAL "sed -i \"/usb.config/a ro.boot.uwbcountrycode=ff\" \"$WORK_DIR/product/etc/build.prop\""

        ADD_TO_WORK_DIR "b0qxxx" "product" \
            "overlay/UwbRROverlay.apk" 0 0 644 "u:object_r:system_file:s0"
        ADD_TO_WORK_DIR "b0qxxx" "system" \
            "system/app/UwbTest/UwbTest.apk" 0 0 644 "u:object_r:system_file:s0"
        ADD_TO_WORK_DIR "$([[ "$TARGET_OS_SINGLE_SYSTEM_IMAGE" == "qssi" ]] && echo "b0qxxx" || echo "b0sxxx")" \
            "system" "system/etc/classpaths/bootclasspath.pb" 0 0 644 "u:object_r:system_file:s0"
        ADD_TO_WORK_DIR "b0qxxx" "system" \
            "system/etc/init/init.system.uwb.rc" 0 0 644 "u:object_r:system_file:s0"
        ADD_TO_WORK_DIR "b0qxxx" "system" \
            "system/etc/permissions/com.samsung.android.uwb_extras.xml" 0 0 644 "u:object_r:system_file:s0"
        ADD_TO_WORK_DIR "b0qxxx" "system" \
            "system/etc/permissions/org.carconnectivity.android.digitalkey.timesync.xml" 0 0 644 "u:object_r:system_file:s0"
        ADD_TO_WORK_DIR "b0qxxx" "system" \
            "system/etc/permissions/privapp-permissions-com.samsung.android.dcktimesync.xml" 0 0 644 "u:object_r:system_file:s0"
        ADD_TO_WORK_DIR "b0qxxx" "system" \
            "system/etc/permissions/privapp-permissions-com.sec.android.app.uwbtest.xml" 0 0 644 "u:object_r:system_file:s0"
        ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" \
            "system/etc/libuwb-cal.conf" 0 0 644 "u:object_r:system_file:s0"
        ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" \
            "system/etc/pp_model.tflite" 0 0 644 "u:object_r:system_file:s0"
        ADD_TO_WORK_DIR "b0qxxx" "system" \
            "system/framework/com.samsung.android.uwb_extras.jar" 0 0 644 "u:object_r:system_file:s0"
        ADD_TO_WORK_DIR "b0qxxx" "system" \
            "system/framework/semuwb-service.jar" 0 0 644 "u:object_r:system_file:s0"
        ADD_TO_WORK_DIR "b0qxxx" "system" \
            "system/lib/libtflite_uwb_jni.so" 0 0 644 "u:object_r:system_lib_file:s0"
        ADD_TO_WORK_DIR "b0qxxx" "system" \
            "system/lib64/libtflite_uwb_jni.so" 0 0 644 "u:object_r:system_lib_file:s0"
        ADD_TO_WORK_DIR "b0qxxx" "system_ext" \
            "framework/org.carconnectivity.android.digitalkey.timesync.jar" 0 0 644 "u:object_r:system_file:s0"
        ADD_TO_WORK_DIR "b0qxxx" "system_ext" \
            "priv-app/DckTimeSyncService/DckTimeSyncService.apk" 0 0 644 "u:object_r:system_file:s0"
    else
        LOG "\033[0;33m! Nothing to do\033[0m"
    fi
else
    if ! $TARGET_HAS_UWB; then
        LOG "- Removing UWB blobs for non-UWB target"
        EVAL "sed -i \"/^ro.boot.uwbcountrycode=/d\" \"$WORK_DIR/product/etc/build.prop\""

        DELETE_IF_EXISTS "product" "overlay/UwbRROverlay.apk"
        DELETE_IF_EXISTS "system" "system/app/UwbTest"
        DELETE_IF_EXISTS "system" "system/etc/init/digitalkey_init_uwb_tss2.rc"
        DELETE_IF_EXISTS "system" "system/etc/init/init.system.uwb.rc"
        DELETE_IF_EXISTS "system" "system/etc/libuwb-cal.conf"
        DELETE_IF_EXISTS "system" "system/etc/permissions/com.samsung.android.uwb_extras.xml"
        DELETE_IF_EXISTS "system" "system/etc/permissions/org.carconnectivity.android.digitalkey.rangingintent.xml"
        DELETE_IF_EXISTS "system" "system/etc/permissions/org.carconnectivity.android.digitalkey.secureelement.xml"
        DELETE_IF_EXISTS "system" "system/etc/permissions/org.carconnectivity.android.digitalkey.timesync.xml"
        DELETE_IF_EXISTS "system" "system/etc/permissions/privapp-permissions-com.samsung.android.dcktimesync.xml"
        DELETE_IF_EXISTS "system" "system/etc/permissions/privapp-permissions-com.sec.android.app.uwbtest.xml"
        DELETE_IF_EXISTS "system" "system/etc/sysconfig/digitalkey.xml"
        ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" \
            "system/etc/classpaths/bootclasspath.pb" 0 0 644 "u:object_r:system_file:s0"
        DELETE_IF_EXISTS "system" "system/framework/arm64/boot-com.samsung.android.uwb_extras.art"
        DELETE_IF_EXISTS "system" "system/framework/arm64/boot-com.samsung.android.uwb_extras.art.fsv_meta"
        DELETE_IF_EXISTS "system" "system/framework/arm64/boot-com.samsung.android.uwb_extras.oat"
        DELETE_IF_EXISTS "system" "system/framework/arm64/boot-com.samsung.android.uwb_extras.oat.fsv_meta"
        DELETE_IF_EXISTS "system" "system/framework/arm64/boot-com.samsung.android.uwb_extras.vdex"
        DELETE_IF_EXISTS "system" "system/framework/arm64/boot-com.samsung.android.uwb_extras.vdex.fsv_meta"
        DELETE_IF_EXISTS "system" "system/framework/boot-com.samsung.android.uwb_extras.vdex"
        DELETE_IF_EXISTS "system" "system/framework/boot-com.samsung.android.uwb_extras.vdex.fsv_meta"
        DELETE_IF_EXISTS "system" "system/framework/com.samsung.android.uwb_extras.jar"
        DELETE_IF_EXISTS "system" "system/framework/com.samsung.android.uwb_extras.jar.fsv_meta"
        DELETE_IF_EXISTS "system" "system/framework/oat/arm64/semuwb-service.odex"
        DELETE_IF_EXISTS "system" "system/framework/oat/arm64/semuwb-service.odex.fsv_meta"
        DELETE_IF_EXISTS "system" "system/framework/oat/arm64/semuwb-service.vdex"
        DELETE_IF_EXISTS "system" "system/framework/oat/arm64/semuwb-service.vdex.fsv_meta"
        DELETE_IF_EXISTS "system" "system/framework/semuwb-service.jar"
        DELETE_IF_EXISTS "system" "system/framework/semuwb-service.jar.fsv_meta"
        DELETE_IF_EXISTS "system" "system/lib64/libtflite_uwb_jni.so"
        DELETE_IF_EXISTS "system" "system/priv-app/DigitalKey"
        DELETE_IF_EXISTS "system_ext" "framework/oat/arm64/org.carconnectivity.android.digitalkey.rangingintent.odex"
        DELETE_IF_EXISTS "system_ext" "framework/oat/arm64/org.carconnectivity.android.digitalkey.rangingintent.odex.fsv_meta"
        DELETE_IF_EXISTS "system_ext" "framework/oat/arm64/org.carconnectivity.android.digitalkey.rangingintent.vdex"
        DELETE_IF_EXISTS "system_ext" "framework/oat/arm64/org.carconnectivity.android.digitalkey.rangingintent.vdex.fsv_meta"
        DELETE_IF_EXISTS "system_ext" "framework/oat/arm64/org.carconnectivity.android.digitalkey.secureelement.odex"
        DELETE_IF_EXISTS "system_ext" "framework/oat/arm64/org.carconnectivity.android.digitalkey.secureelement.odex.fsv_meta"
        DELETE_IF_EXISTS "system_ext" "framework/oat/arm64/org.carconnectivity.android.digitalkey.secureelement.vdex"
        DELETE_IF_EXISTS "system_ext" "framework/oat/arm64/org.carconnectivity.android.digitalkey.secureelement.vdex.fsv_meta"
        DELETE_IF_EXISTS "system_ext" "framework/org.carconnectivity.android.digitalkey.rangingintent.jar"
        DELETE_IF_EXISTS "system_ext" "framework/org.carconnectivity.android.digitalkey.rangingintent.jar.fsv_meta"
        DELETE_IF_EXISTS "system_ext" "framework/org.carconnectivity.android.digitalkey.secureelement.jar"
        DELETE_IF_EXISTS "system_ext" "framework/org.carconnectivity.android.digitalkey.secureelement.jar.fsv_meta"
        DELETE_IF_EXISTS "system_ext" "framework/org.carconnectivity.android.digitalkey.timesync.jar"
        DELETE_IF_EXISTS "system_ext" "framework/org.carconnectivity.android.digitalkey.timesync.jar.fsv_meta"
        DELETE_IF_EXISTS "system_ext" "priv-app/DckTimeSyncService"
    fi
fi

unset -f DELETE_IF_EXISTS
unset SOURCE_FIRMWARE_PATH TARGET_FIRMWARE_PATH SOURCE_HAS_UWB TARGET_HAS_UWB
