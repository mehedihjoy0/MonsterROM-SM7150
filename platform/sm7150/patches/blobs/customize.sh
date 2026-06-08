LOG_STEP_IN "- Adding Google Hotword Enrollment blobs from a73xqxx"
DELETE_FROM_WORK_DIR "product" "priv-app/HotwordEnrollmentOKGoogleEx4HEXAGON"
DELETE_FROM_WORK_DIR "product" "priv-app/HotwordEnrollmentXGoogleEx4HEXAGON"
ADD_TO_WORK_DIR "a73xqxx" "product" "priv-app/HotwordEnrollmentOKGoogleEx3HEXAGON"
ADD_TO_WORK_DIR "a73xqxx" "product" "priv-app/HotwordEnrollmentXGoogleEx3HEXAGON"
LOG_STEP_OUT

LOG_STEP_IN "- Adding light blobs from a73xqxx"
ADD_TO_WORK_DIR "a73xqxx" "vendor" "bin/hw/vendor.samsung.hardware.light-service"
ADD_TO_WORK_DIR "a73xqxx" "vendor" "lib64/vendor.samsung.hardware.light-V1-ndk_platform.so"
LOG_STEP_OUT

LOG_STEP_IN "- Adding SoundBooster libs from stock"
DELETE_FROM_WORK_DIR "system" "system/lib/lib_SoundBooster_ver1100.so"
DELETE_FROM_WORK_DIR "system" "system/lib64/lib_SoundBooster_ver1100.so"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib/lib_SoundBooster_ver1050.so"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/lib_SoundBooster_ver1050.so"
DELETE_FROM_WORK_DIR "system" "system/lib/lib_SoundAlive_play_plus_ver800.so"
DELETE_FROM_WORK_DIR "system" "system/lib64/lib_SoundAlive_play_plus_ver800.so"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib/lib_SoundAlive_play_plus_ver500.so"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/lib_SoundAlive_play_plus_ver500.so"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib/libaudiosaplus_sec_legacy.so"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libaudiosaplus_sec_legacy.so"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib/libsamsungSoundbooster_plus_legacy.so"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libsamsungSoundbooster_plus_legacy.so"
LOG_STEP_OUT

LOG_STEP_IN "- Replacing radio HAL version with 1.5"
EVAL "sed -i \"s/1.4::IRadio/1.5::IRadio/g\" \"$WORK_DIR/vendor/etc/vintf/manifest.xml\""
LOG_STEP_OUT
