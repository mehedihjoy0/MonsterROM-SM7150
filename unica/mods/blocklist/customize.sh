DELETE_FROM_WORK_DIR "system" "system/etc/ldu_blocklist.xml"

APPLY_PATCH "system" "system/framework/services.jar" \
    "$MODPATH/services.jar/0001-Allow-custom-PackageBlockListPolicy.patch"
APPLY_PATCH "system" "system/framework/services.jar" \
    "$MODPATH/services.jar/0002-Allow-custom-PackageBlockListPolicy-Fold8.patch"
SMALI_PATCH "system" "system/framework/services.jar" \
    "smali_classes2/com/samsung/android/server/pm/install/PackageBlockListPolicy\$1.smali" 'remove'
