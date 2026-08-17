# shellcheck disable=SC2034
SKIPUNZIP=1

if ! $ROM_IS_OFFICIAL; then
    LOG "\033[0;33m! Build is not official. Skipping\033[0m"
    return 0
fi

if [ ! "$(GET_PROP "system" "ro.unica.version")" ]; then
    SET_PROP "system" "ro.unica.version" "$ROM_VERSION"
fi
if [ ! "$(GET_PROP "system" "ro.unica.timestamp")" ]; then
    SET_PROP "system" "ro.unica.timestamp" "$ROM_BUILD_TIMESTAMP"
fi
if [ ! "$(GET_PROP "system" "ro.unica.device")" ]; then
    SET_PROP "system" "ro.unica.device" "$TARGET_CODENAME"
fi

ADD_TO_WORK_DIR "$MODPATH" "system" "." 0 0 755 "u:object_r:system_file:s0"

LOG "- Patching /system/system/etc/security/otacerts.zip"
EVAL "rm \"$WORK_DIR/system/system/etc/security/otacerts.zip\""
EVAL "cd \"$SRC_DIR\"; zip -q \"$WORK_DIR/system/system/etc/security/otacerts.zip\" \"./security/unica_ota.x509.pem\""

DECODE_APK "system" "system/priv-app/SecSettings/SecSettings.apk"

if ! [[ "$SOURCE_PLATFORM_SDK_VERSION" =~ ^[0-9]+$ ]]; then
    ABORT "Invalid source platform SDK: $SOURCE_PLATFORM_SDK_VERSION"
elif [ "$SOURCE_PLATFORM_SDK_VERSION" -eq "37" ]; then
    CHOIDUJOUR_SETTINGS="$WORK_DIR/system/system/priv-app/SecSettings/SecSettings.apk"
    CHOIDUJOUR_SETTINGS_BUILD="$(GET_PROP "system" "ro.build.version.incremental")"
    CHOIDUJOUR_SETTINGS_SHA256="$(sha256sum "$CHOIDUJOUR_SETTINGS" | cut -d " " -f 1 -s)"

    case "$CHOIDUJOUR_SETTINGS_BUILD:$CHOIDUJOUR_SETTINGS_SHA256" in
        "S942BXXU4ZZH6:1eed31f97438ff8c1b847498b773bb7d8b6ee75416524a69e41579784bb28c24" | \
        "F976BXXS2AZH7:7bc68acd868d19b37f18ba60826fa69c9c95ae1e6cd1076acb1334a130a9d8b3")
            ;;
        *)
            ABORT "Unaudited Android 17 SecSettings artifact for UN1CA Updates: build=$CHOIDUJOUR_SETTINGS_BUILD sha256=$CHOIDUJOUR_SETTINGS_SHA256"
            ;;
    esac

    APPLY_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
        "$MODPATH/suggestions/SecSettings.apk/0001-Launch-UN1CA-Updates-from-suggestions-API-37.patch"

    # One UI 9 removed isOTAUpgradeAllowed(). The stock link now becomes
    # unavailable when all FOTA packages are absent; FotaAgent is deliberately
    # removed by debloat, so validate that fail-closed architecture instead of
    # replaying an obsolete method patch.
    CHOIDUJOUR_OTA_VARIANT="$APKTOOL_DIR/system/priv-app/SecSettings/SecSettings.apk/smali_classes3/com/samsung/android/settings/softwareupdate/SoftwareUpdateVariant.smali"
    CHOIDUJOUR_OTA_LINK="$APKTOOL_DIR/system/priv-app/SecSettings/SecSettings.apk/smali_classes3/com/samsung/android/settings/softwareupdate/SoftwareUpdateLinkData.smali"
    if [ "$(grep -F -c 'Lcom/android/settings/Utils;->isPackageEnabled(Landroid/content/Context;Ljava/lang/String;)Z' "$CHOIDUJOUR_OTA_VARIANT")" -ne 1 ] || \
            [ "$(grep -F -c 'const-string p0, "No packages enabled"' "$CHOIDUJOUR_OTA_VARIANT")" -ne 1 ] || \
            [ "$(grep -F -c '.catch Ljava/lang/RuntimeException;' "$CHOIDUJOUR_OTA_LINK")" -ne 1 ] || \
            [ "$(grep -F -c 'iput-boolean v1, p0, Lcom/samsung/android/settings/softwareupdate/SoftwareUpdateLinkData;->packageEnabled:Z' "$CHOIDUJOUR_OTA_LINK")" -ne 1 ]; then
        ABORT "Unexpected Android 17 SecSettings FOTA fallback topology"
    fi

    unset CHOIDUJOUR_SETTINGS CHOIDUJOUR_SETTINGS_BUILD CHOIDUJOUR_SETTINGS_SHA256 \
        CHOIDUJOUR_OTA_VARIANT CHOIDUJOUR_OTA_LINK
elif [ "$SOURCE_PLATFORM_SDK_VERSION" -lt "37" ]; then
    APPLY_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
        "$MODPATH/suggestions/SecSettings.apk/0001-Launch-UN1CA-Updates-from-suggestions.patch"

    # Disable stock OTA references.
    SMALI_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
        "smali_classes3/com/samsung/android/settings/softwareupdate/SoftwareUpdateUtils.smali" "return" \
        "isOTAUpgradeAllowed(Landroid/content/Context;)Z" "false"
else
    ABORT "UN1CA Updates has not been audited for source SDK $SOURCE_PLATFORM_SDK_VERSION"
fi

# Dynamically patch SecSettings
# - Add missing/non-xml files in place
# - Patch existing files
#   - Use the first line of the file to tell sed how to apply the rest of the content
#   - Exception made for files under *res/values* where the "resources" tag gets nuked
while IFS= read -r f; do
    f="${f//$MODPATH\/SecSettings.apk\//}"

    if [ ! -f "$APKTOOL_DIR/system/priv-app/SecSettings/SecSettings.apk/$f" ] || \
            [[ "$f" != *".xml" ]]; then
        LOG "- Adding \"$f\" to /system/system/priv-app/SecSettings.apk"
        EVAL "mkdir -p \"$(dirname "$APKTOOL_DIR/system/priv-app/SecSettings/SecSettings.apk/$f")\""
        EVAL "cp -a \"$MODPATH/SecSettings.apk/${f//\$/\\$}\" \"$APKTOOL_DIR/system/priv-app/SecSettings/SecSettings.apk/${f//\$/\\$}\""
    else
        LOG "- Patching \"$f\" in /system/system/priv-app/SecSettings.apk"
        if [[ "$f" == *"res/values"* ]]; then
            PATCH_INST="/<\/resources>/i"
            CONTENT="$(sed -e "/?xml/d" -e "/resources>/d" "$MODPATH/SecSettings.apk/$f")"
        else
            PATCH_INST="$(head -n 1 "$MODPATH/SecSettings.apk/$f")"
            CONTENT="$(tail -n +2 "$MODPATH/SecSettings.apk/$f")"
        fi
        CONTENT="$(sed -e "s/\"/\\\\\"/g" -e "s/\\$/\\\\$/g" -e "s/ /\\\ /g" -e "s/\\\\n/\\\\\\\\\n/g" <<< "$CONTENT")"
        CONTENT="$(sed -E ':a;N;$!ba;s/\r{0,1}\n/\\n/g' <<< "$CONTENT")"
        EVAL "sed -i \"$PATCH_INST $CONTENT\" \"$APKTOOL_DIR/system/priv-app/SecSettings/SecSettings.apk/$f\""
    fi
done < <(find "$MODPATH/SecSettings.apk" -type f)

unset PATCH_INST CONTENT
