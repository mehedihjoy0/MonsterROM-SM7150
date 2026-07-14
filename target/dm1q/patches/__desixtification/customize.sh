LOG_STEP_IN "- Adding Galaxy S23 32-bit compatibility runtime"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/lib" 0 0 644

BLOBS_LIST="
system/apex/com.android.i18n.apex
system/apex/com.android.runtime.apex
system/apex/com.google.android.tzdata6.apex
system/bin/bootstrap/linker
system/bin/bootstrap/linker_asan
"
for blob in $BLOBS_LIST
do
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "$blob"
done
LOG_STEP_OUT

LOG_STEP_IN "- Creating 32-bit linker symlinks"
ln -sf "/apex/com.android.runtime/bin/linker" "$WORK_DIR/system/system/bin/linker"
ln -sf "/apex/com.android.runtime/bin/linker" "$WORK_DIR/system/system/bin/linker_asan"
SET_METADATA "system" "system/bin/linker" 0 0 755 "u:object_r:system_file:s0"
SET_METADATA "system" "system/bin/linker_asan" 0 0 755 "u:object_r:system_file:s0"
LOG_STEP_OUT

LOG_STEP_IN "- Selecting the S26 Ultra 64-bit zygote"
SET_PROP "vendor" "ro.vendor.product.cpu.abilist" "arm64-v8a"
SET_PROP "vendor" "ro.vendor.product.cpu.abilist32" ""
SET_PROP "vendor" "ro.vendor.product.cpu.abilist64" "arm64-v8a"
SET_PROP "vendor" "ro.zygote" "zygote64"
SET_PROP "vendor" "dalvik.vm.dex2oat64.enabled" "true"
LOG_STEP_OUT
