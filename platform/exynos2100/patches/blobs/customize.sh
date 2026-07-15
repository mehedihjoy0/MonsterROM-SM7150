LOG_STEP_IN "- Adding stock SoundBooster libs"
if [[ "$TARGET_CODENAME" == "r9s" ]]; then
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib/lib_SoundBooster_ver1070.so" 0 0 644 "u:object_r:system_lib_file:s0"
else
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib/lib_SoundBooster_ver1050.so" 0 0 644 "u:object_r:system_lib_file:s0"
fi
if [ -f "$FW_DIR/$_TARGET_FIRMWARE_PATH/system/system/lib64/lib_SAG_EQ_ver2090.so" ]; then
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/lib_SAG_EQ_ver2090.so" 0 0 644 "u:object_r:system_lib_file:s0"
elif [[ "$TARGET_CODENAME" == "r9s" ]]; then
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/lib_SoundBooster_ver1070.so" 0 0 644 "u:object_r:system_lib_file:s0"
else
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/lib_SoundBooster_ver1050.so" 0 0 644 "u:object_r:system_lib_file:s0"
fi
DELETE_FROM_WORK_DIR "system" "system/lib64/lib_SoundBooster_ver2090.so"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/lib_SoundAlive_play_plus_ver500.so" 0 0 644 "u:object_r:system_lib_file:s0"
DELETE_FROM_WORK_DIR "system" "system/lib64/lib_SoundAlive_play_plus_ver900.so"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libaudiosaplus_sec_legacy.so" 0 0 644 "u:object_r:system_lib_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libsamsungSoundbooster_plus_legacy.so" 0 0 644 "u:object_r:system_lib_file:s0"
if grep -q 'stream type="sec_voice_communication"' "$WORK_DIR/vendor/etc/audio_effects_sec.xml" 2>/dev/null; then
    LOG "- Removing unsupported sec_voice_communication audio effect stream"
    sed -i '/<stream type="sec_voice_communication">/,/<\/stream>/d' "$WORK_DIR/vendor/etc/audio_effects_sec.xml"
fi
LOG_STEP_OUT

LOG_STEP_IN "- Adding OK Google Hotword Enrollment blobs"
DELETE_FROM_WORK_DIR "product" "priv-app/HotwordEnrollmentXGoogleEx6_WIDEBAND_LARGE"
DELETE_FROM_WORK_DIR "product" "priv-app/HotwordEnrollmentYGoogleEx6_WIDEBAND_LARGE"
ADD_TO_WORK_DIR "r9sxxx" "product" "priv-app/HotwordEnrollmentOKGoogleEx3CORTEXM4/HotwordEnrollmentOKGoogleEx3CORTEXM4.apk" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "r9sxxx" "product" "priv-app/HotwordEnrollmentXGoogleEx3CORTEXM4/HotwordEnrollmentXGoogleEx3CORTEXM4.apk" 0 0 644 "u:object_r:system_file:s0"
LOG_STEP_OUT

ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/priv-app/DevGPUDriver-EX2100/DevGPUDriver-EX2100.apk" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/priv-app/GameDriver-EX2100/GameDriver-EX2100.apk" 0 0 644 "u:object_r:system_file:s0"

if [[ "$TARGET_CODENAME" == "r9s" ]]; then
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/etc/init/rscmgr_s21fe.rc" 0 0 644 "u:object_r:system_file:s0"
fi

ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/etc/permissions/android.hardware.sensor.hifi_sensors.xml" 0 0 644 "u:object_r:system_file:s0"

if [[ "$TARGET_CODENAME" != "r9s" ]]; then
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/etc/permissions/privapp-permissions-com.samsung.android.app.ledbackcover.xml" 0 0 644 "u:object_r:system_file:s0"
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/priv-app/LedBackCoverAppUnbound/LedBackCoverAppUnbound.apk" 0 0 644 "u:object_r:system_file:s0"
fi
