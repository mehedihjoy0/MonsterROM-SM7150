LOG_STEP_IN "- Adding Google Hotword Enrollment blobs from a73xqxx"
for f in "$WORK_DIR"/product/priv-app/HotwordEnrollment*; do [ -e "$f" ] && DELETE_FROM_WORK_DIR "product" "priv-app/${f##*/}"; done
ADD_TO_WORK_DIR "a73xqxx" "product" "priv-app/HotwordEnrollmentOKGoogleEx3HEXAGON"
ADD_TO_WORK_DIR "a73xqxx" "product" "priv-app/HotwordEnrollmentXGoogleEx3HEXAGON"
LOG_STEP_OUT

LOG_STEP_IN "- Adding wpa_supplicant from a73xqxx"
ADD_TO_WORK_DIR "a73xqxx" "vendor" "bin/hw/wpa_supplicant"
LOG_STEP_OUT

# LOG_STEP_IN "- Adding 32-bit WFD blobs from source"
# ADD_TO_WORK_DIR "$SOURCE_EXTRA_FIRMWARES" "system" "system/bin/insthk"
# ADD_TO_WORK_DIR "$SOURCE_EXTRA_FIRMWARES" "system" "system/bin/remotedisplay"
# DELETE_FROM_WORK_DIR "system" "system/lib64/libhdcp_client_aidl.so"
# DELETE_FROM_WORK_DIR "system" "system/lib64/libhdcp2.so"
# DELETE_FROM_WORK_DIR "system" "system/lib64/libremotedisplay_wfd.so"
# DELETE_FROM_WORK_DIR "system" "system/lib64/libremotedisplayservice.so"
# DELETE_FROM_WORK_DIR "system" "system/lib64/libsecuibc.so"
# DELETE_FROM_WORK_DIR "system" "system/lib64/libstagefright_hdcp.so"
# DELETE_FROM_WORK_DIR "system" "system/lib64/vendor.samsung.hardware.security.hdcp.wifidisplay-V2-ndk.so"
# DELETE_FROM_WORK_DIR "system" "system/lib64/wfd_log.so"
# LOG_STEP_OUT

LOG_STEP_IN "- Adding light blobs from source"
ADD_TO_WORK_DIR "$SOURCE_EXTRA_FIRMWARES" "vendor" "bin/hw/vendor.samsung.hardware.light-service"
ADD_TO_WORK_DIR "$SOURCE_EXTRA_FIRMWARES" "vendor" "lib64/vendor.samsung.hardware.light-V1-ndk_platform.so"
LOG_STEP_OUT

LOG_STEP_IN "- Adding SoundBooster libs from stock"
# for f in "$WORK_DIR"/system/system/lib/lib_SAG_EQ_ver*.so; do [ -e "$f" ] && DELETE_FROM_WORK_DIR "system" "system/lib/${f##*/}"; done
for f in "$WORK_DIR"/system/system/lib64/lib_SAG_EQ_ver*.so; do [ -e "$f" ] && DELETE_FROM_WORK_DIR "system" "system/lib64/${f##*/}"; done

# for f in "$WORK_DIR"/system/system/lib/lib_SoundBooster_ver*.so; do [ -e "$f" ] && DELETE_FROM_WORK_DIR "system" "system/lib/${f##*/}"; done
# ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib/lib_SoundBooster_ver1050.so"
for f in "$WORK_DIR"/system/system/lib64/lib_SoundBooster_ver*.so; do [ -e "$f" ] && DELETE_FROM_WORK_DIR "system" "system/lib64/${f##*/}"; done
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/lib_SoundBooster_ver1050.so"

# for f in "$WORK_DIR"/system/system/lib/lib_SoundAlive_play_plus_ver*.so; do [ -e "$f" ] && DELETE_FROM_WORK_DIR "system" "system/lib/${f##*/}"; done
# ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib/lib_SoundAlive_play_plus_ver500.so"
for f in "$WORK_DIR"/system/system/lib64/lib_SoundAlive_play_plus_ver*.so; do [ -e "$f" ] && DELETE_FROM_WORK_DIR "system" "system/lib64/${f##*/}"; done
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/lib_SoundAlive_play_plus_ver500.so"

# ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib/libaudiosaplus_sec_legacy.so"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libaudiosaplus_sec_legacy.so"
# ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib/libsamsungSoundbooster_plus_legacy.so"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libsamsungSoundbooster_plus_legacy.so"
LOG_STEP_OUT

# LOG_STEP_IN "- Adding HWUI libs from source"
# ADD_TO_WORK_DIR "$SOURCE_EXTRA_FIRMWARES" "system" "system/lib64/libhwui.so"
# LOG_STEP_OUT

# LOG_STEP_IN "- Adding keymaster 4.0 libs from source"
# DELETE_FROM_WORK_DIR "system" "system/lib64/android.hardware.security.keymint-V1-ndk.so"
# ADD_TO_WORK_DIR "$SOURCE_EXTRA_FIRMWARES" "system" "system/lib64/lib_nativeJni.dk.samsung.so"
# DELETE_FROM_WORK_DIR "system" "system/lib64/libdk_native_keymint.so"
# ADD_TO_WORK_DIR "$SOURCE_EXTRA_FIRMWARES" "system" "system/lib64/libdk_native_keymaster.so"
# DELETE_FROM_WORK_DIR "system" "system/lib64/vendor.samsung.hardware.keymint-V1-ndk.so"
# LOG_STEP_OUT

# LOG_STEP_IN "- Adding FM radio blobs from stock"
# ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/etc/permissions/privapp-permissions-com.sec.android.app.fm.xml"
# ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/etc/sysconfig/preinstalled-packages-com.sec.android.app.fm.xml"
# ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/priv-app/HybridRadio/HybridRadio.apk"
# ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib/libfmradio_jni.so"
# ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libfmradio_jni.so"
# ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib/fm_helium.so"
# ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib/libbeluga.so"
# ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib/libfm-hci.so"
# ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib/vendor.qti.hardware.fm@1.0.so"
# ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib64/fm_helium.so"
# ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib64/libbeluga.so"
# ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib64/libfm-hci.so"
# ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib64/vendor.qti.hardware.fm@1.0.so"
# LOG_STEP_OUT

LOG_STEP_IN "- Replacing radio HAL version with 1.5"
EVAL "sed -i \"s/1.4::IRadio/1.5::IRadio/g\" \"$WORK_DIR/vendor/etc/vintf/manifest.xml\""
LOG_STEP_OUT