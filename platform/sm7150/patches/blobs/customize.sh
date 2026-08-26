LOG_STEP_IN "- Adding Google Hotword Enrollment blobs from a73xqxx"
for f in "$WORK_DIR"/product/priv-app/HotwordEnrollment*; do [ -e "$f" ] && DELETE_FROM_WORK_DIR "product" "priv-app/${f##*/}"; done
ADD_TO_WORK_DIR "a73xqxx" "product" "priv-app/HotwordEnrollmentOKGoogleEx3HEXAGON"
ADD_TO_WORK_DIR "a73xqxx" "product" "priv-app/HotwordEnrollmentXGoogleEx3HEXAGON"
LOG_STEP_OUT

LOG_STEP_IN "- Adding wpa_supplicant from a73xqxx"
ADD_TO_WORK_DIR "a73xqxx" "vendor" "bin/hw/wpa_supplicant"
LOG_STEP_OUT

LOG_STEP_IN "- Adding light blobs from source"
ADD_TO_WORK_DIR "$SOURCE_FIRMWARE" "vendor" "bin/hw/vendor.samsung.hardware.light-service"
ADD_TO_WORK_DIR "$SOURCE_FIRMWARE" "vendor" "lib64/vendor.samsung.hardware.light-V1-ndk_platform.so"
LOG_STEP_OUT

LOG_STEP_IN "- Adding SoundBooster libs from stock"
 for f in "$WORK_DIR"/system/system/lib/lib_SAG_EQ_ver*.so; do [ -e "$f" ] && DELETE_FROM_WORK_DIR "system" "system/lib/${f##*/}"; done
for f in "$WORK_DIR"/system/system/lib64/lib_SAG_EQ_ver*.so; do [ -e "$f" ] && DELETE_FROM_WORK_DIR "system" "system/lib64/${f##*/}"; done

 for f in "$WORK_DIR"/system/system/lib/lib_SoundBooster_ver*.so; do [ -e "$f" ] && DELETE_FROM_WORK_DIR "system" "system/lib/${f##*/}"; done
 ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib/lib_SoundBooster_ver1050.so"
for f in "$WORK_DIR"/system/system/lib64/lib_SoundBooster_ver*.so; do [ -e "$f" ] && DELETE_FROM_WORK_DIR "system" "system/lib64/${f##*/}"; done
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/lib_SoundBooster_ver1050.so"

 for f in "$WORK_DIR"/system/system/lib/lib_SoundAlive_play_plus_ver*.so; do [ -e "$f" ] && DELETE_FROM_WORK_DIR "system" "system/lib/${f##*/}"; done
 ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib/lib_SoundAlive_play_plus_ver500.so"
for f in "$WORK_DIR"/system/system/lib64/lib_SoundAlive_play_plus_ver*.so; do [ -e "$f" ] && DELETE_FROM_WORK_DIR "system" "system/lib64/${f##*/}"; done
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/lib_SoundAlive_play_plus_ver500.so"

 ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib/libaudiosaplus_sec_legacy.so"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libaudiosaplus_sec_legacy.so"
 ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib/libsamsungSoundbooster_plus_legacy.so"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libsamsungSoundbooster_plus_legacy.so"
LOG_STEP_OUT

LOG_STEP_IN "- Adding FM radio blobs from stock"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib/libfmradio_jni.so"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libfmradio_jni.so"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib/fm_helium.so"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib/libbeluga.so"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib/libfm-hci.so"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib/vendor.qti.hardware.fm@1.0.so"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib64/fm_helium.so"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib64/libbeluga.so"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib64/libfm-hci.so"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system_ext" "lib64/vendor.qti.hardware.fm@1.0.so"
LOG_STEP_OUT

LOG_STEP_IN "- Replacing radio HAL version with 1.5"
EVAL "sed -i \"s/1.4::IRadio/1.5::IRadio/g\" \"$WORK_DIR/vendor/etc/vintf/manifest.xml\""
LOG_STEP_OUT