MISCS_MODULE_ROOT="$MODPATH"
MISCS_PLATFORM_SDK="${SOURCE_PLATFORM_SDK_VERSION:-$(GET_PROP "system" "ro.build.version.sdk")}"

SET_PROP_IF_DIFF "vendor" "ro.oem_unlock_supported" "0"

# Better device/model detection in CoreRune
SMALI_PATCH "system" "system/framework/framework.jar" \
    "smali_classes6/com/samsung/android/rune/CoreRune.smali" "replace" \
    '<clinit>()V' \
    'ro.product.model' \
    'ro.product.vendor.model'
SMALI_PATCH "system" "system/framework/framework.jar" \
    "smali_classes6/com/samsung/android/rune/CoreRune.smali" "replace" \
    '<clinit>()V' \
    'ro.product.device' \
    'ro.product.vendor.device'

# shellcheck disable=SC2016
# Disable RescueParty
if [ "$MISCS_PLATFORM_SDK" -ge "37" ]; then
    # Samsung replaced AOSP RescueParty with SecRescueParty in API 37. Its
    # SystemServer entry point only registers the package-health observer, so
    # nullifying that exact void method prevents destructive recovery actions
    # without fabricating a class or patching unrelated boot reporting code.
    SMALI_PATCH "system" "system/framework/services.jar" \
        "smali/com/android/server/SecRescueParty.smali" "null" \
        'secRescuePartyRegisterHealthObserver(Landroid/content/Context;)V'
else
    SMALI_PATCH "system" "system/framework/services.jar" \
        "smali/com/android/server/RescueParty.smali" "return" \
        '-$$Nest$smisDisabled()Z' \
        'true'
fi

# Better model detection in FreecessController
SMALI_PATCH "system" "system/framework/services.jar" \
    "smali/com/android/server/am/FreecessController.smali" "replace" \
    '<clinit>()V' \
    'ro.product.model' \
    'ro.product.vendor.model'

