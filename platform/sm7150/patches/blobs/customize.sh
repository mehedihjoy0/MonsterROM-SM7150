LOG_STEP_IN "- Adding Google Hotword Enrollment blobs from a73xqxx"
rm -rf $WORK_DIR/product/priv-app/HotwordEnrollmentOKGoogle*
ADD_TO_WORK_DIR "a73xqxx" "product" "priv-app/HotwordEnrollmentOKGoogleEx3HEXAGON"
ADD_TO_WORK_DIR "a73xqxx" "product" "priv-app/HotwordEnrollmentXGoogleEx3HEXAGON"
LOG_STEP_OUT

LOG_STEP_IN "- Adding SoundBooster libs from stock"
DELETE_FROM_WORK_DIR "system" "system/lib64/lib_SAG_EQ_ver2090.so"
DELETE_FROM_WORK_DIR "system" "system/lib64/lib_SoundBooster_ver2090.so"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/lib_SoundBooster_ver1050.so"
DELETE_FROM_WORK_DIR "system" "system/lib64/lib_SoundAlive_play_plus_ver900.so"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/lib_SoundAlive_play_plus_ver500.so"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libaudiosaplus_sec_legacy.so"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib64/libsamsungSoundbooster_plus_legacy.so"
LOG_STEP_OUT

LOG_STEP_IN "- Replacing radio HAL version with 1.5"
EVAL "sed -i \"s/1.4::IRadio/1.5::IRadio/g\" \"$WORK_DIR/vendor/etc/vintf/manifest.xml\""
LOG_STEP_OUT
