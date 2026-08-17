if [ ! "$(GET_PROP "system" "ro.unica.version")" ]; then
    SET_PROP "system" "ro.unica.version" "$ROM_VERSION"
fi

# Show battery regulatory info in Settings
# Requires SEM_BATTERY_PROPERTY_IC_AUTHENTICATION_RESULT support
if [ "$(GET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_BATTERY_SUPPORT_BSOH_SETTINGS")" ]; then
    SET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_BATTERY_SUPPORT_BSOH_SETTINGS" --delete
fi
SET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_SETTINGS_ENABLE_EU_BATTERY_REGULATORY" "TRUE"

SMALI_PATCH "system" "system/framework/framework.jar" \
    "smali/android/app/Instrumentation.smali" "replace" \
    'newApplication(Ljava/lang/Class;Landroid/content/Context;)Landroid/app/Application;' \
    'invoke-virtual {p0, p1}, Landroid/app/Application;->attach(Landroid/content/Context;)V' \
    '    invoke-virtual {p0, p1}, Landroid/app/Application;->attach(Landroid/content/Context;)V\n\n    invoke-static {p1}, Lio/mesalabs/unica/SamsungPropsHooks;->init(Landroid/content/Context;)V' \
    > /dev/null
SMALI_PATCH "system" "system/framework/framework.jar" \
    "smali/android/app/Instrumentation.smali" "replace" \
    'newApplication(Ljava/lang/ClassLoader;Ljava/lang/String;Landroid/content/Context;)Landroid/app/Application;' \
    'invoke-virtual {p0, p3}, Landroid/app/Application;->attach(Landroid/content/Context;)V' \
    '    invoke-virtual {p0, p3}, Landroid/app/Application;->attach(Landroid/content/Context;)V\n\n    invoke-static {p3}, Lio/mesalabs/unica/SamsungPropsHooks;->init(Landroid/content/Context;)V' \
    > /dev/null

DECODE_APK "system" "system/priv-app/SecSettings/SecSettings.apk"

# Disable stock OTA references
if [ ! -f "$WORK_DIR/system/system/priv-app/ChoiDujour/ChoiDujour.apk" ]; then
    if [ "$SOURCE_PLATFORM_SDK_VERSION" -ge "37" ]; then
        # Android 17 removed isOTAUpgradeAllowed(). SoftwareUpdateVariant now
        # resolves only enabled FOTA packages; SoftwareUpdateLinkData catches
        # the empty result and marks the top-level link unavailable. Keep this
        # stock fail-closed path intact and abort if Samsung changes it again.
        OTA_VARIANT="$APKTOOL_DIR/system/priv-app/SecSettings/SecSettings.apk/smali_classes3/com/samsung/android/settings/softwareupdate/SoftwareUpdateVariant.smali"
        OTA_LINK_DATA="$APKTOOL_DIR/system/priv-app/SecSettings/SecSettings.apk/smali_classes3/com/samsung/android/settings/softwareupdate/SoftwareUpdateLinkData.smali"
        if [ "$(grep -c 'Lcom/android/settings/Utils;->isPackageEnabled(Landroid/content/Context;Ljava/lang/String;)Z' "$OTA_VARIANT")" -ne 1 ] || \
                [ "$(grep -c 'const-string p0, "No packages enabled"' "$OTA_VARIANT")" -ne 1 ] || \
                [ "$(grep -c '\.catch Ljava/lang/RuntimeException;' "$OTA_LINK_DATA")" -ne 1 ] || \
                [ "$(grep -c 'iput-boolean v1, p0, Lcom/samsung/android/settings/softwareupdate/SoftwareUpdateLinkData;->packageEnabled:Z' "$OTA_LINK_DATA")" -ne 1 ]; then
            LOG_MISSING_PATCHES "A17 SecSettings FOTA package-enabled fallback"
        fi
    else
        SMALI_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
            "smali_classes3/com/samsung/android/settings/softwareupdate/SoftwareUpdateUtils.smali" "return" \
            'isOTAUpgradeAllowed(Landroid/content/Context;)Z' \
            'false'
    fi
fi

# Always show One UI minor version
if [ "$SOURCE_PLATFORM_SDK_VERSION" -ge "37" ]; then
    SETTINGS_DEVICEINFO_SMALI="smali_classes3"
    SETTINGS_SEARCH_SMALI="smali_classes2"
else
    SETTINGS_DEVICEINFO_SMALI="smali_classes4"
    SETTINGS_SEARCH_SMALI="smali"
fi
SMALI_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
    "$SETTINGS_DEVICEINFO_SMALI/com/samsung/android/settings/deviceinfo/softwareinfo/OneUIVersionPreferenceController.smali" "replace" \
    'isDeviceWithMicroVersion()Z' \
    'move-result p0' \
    'const/4 p0, 0x1'

# Show real device model number
SMALI_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
    "$SETTINGS_DEVICEINFO_SMALI/com/samsung/android/settings/deviceinfo/aboutphone/ModelNameGetter.smali" "replace" \
    'getModelName()Ljava/lang/String;' \
    'ro.product.model' \
    'ro.boot.em.model'

LOG_STEP_IN "- Adding UN1CA Settings"

# Dynamically patch SecSettings
# - Add missing/non-xml files in place
# - Patch existing files
#   - Use the first line of the file to tell sed how to apply the rest of the content
#   - Exception made for files under *res/values* where the "resources" tag gets nuked
while IFS= read -r f; do
    f="${f//$MODPATH\/SecSettings.apk\//}"

    # API37 has no SearchIndexableResourcesMobile constructor: R8 inlined it
    # into SearchFeatureProviderImpl's lambda. The legacy subclass would call
    # a nonexistent super constructor, so its four entries are injected into
    # that lambda below instead.
    if [ "$SOURCE_PLATFORM_SDK_VERSION" -ge "37" ] && \
            [ "$f" = "smali_classes4/io/mesalabs/unica/search/UnicaSearchIndexableResources.smali" ]; then
        continue
    fi

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

# Add UN1CA Settings SearchIndexableData registrations
if [ "$SOURCE_PLATFORM_SDK_VERSION" -ge "37" ]; then
    SETTINGS_SEARCH_LAMBDA="$APKTOOL_DIR/system/priv-app/SecSettings/SecSettings.apk/$SETTINGS_SEARCH_SMALI/com/android/settings/search/SearchFeatureProviderImpl\$\$ExternalSyntheticLambda0.smali"
    if [ "$(grep -c 'invoke-direct {p0}, Ljava/lang/Object;-><init>()V' "$SETTINGS_SEARCH_LAMBDA")" -ne 1 ] || \
            [ "$(grep -c 'return-object p0' "$SETTINGS_SEARCH_LAMBDA")" -ne 1 ] || \
            [ "$(grep -c 'Lcom/android/settingslib/search/SearchIndexableResourcesBase;->addIndex' "$SETTINGS_SEARCH_LAMBDA")" -lt 1 ]; then
        LOG_MISSING_PATCHES "A17 SecSettings inlined search-index constructor"
    fi
    SMALI_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
        "$SETTINGS_SEARCH_SMALI/com/android/settings/search/SearchFeatureProviderImpl\$\$ExternalSyntheticLambda0.smali" "replace" \
        'invoke()Ljava/lang/Object;' \
        'return-object p0' \
        '    new-instance v0, Lcom/android/settingslib/search/SearchIndexableData;\n\n    const-class v1, Lio/mesalabs/unica/settings/UnicaSettingsFragment;\n\n    sget-object v2, Lio/mesalabs/unica/settings/UnicaSettingsFragment;->SEARCH_INDEX_DATA_PROVIDER:Lcom/android/settings/search/BaseSearchIndexProvider;\n\n    invoke-direct {v0, v1, v2}, Lcom/android/settingslib/search/SearchIndexableData;-><init>(Ljava/lang/Class;Lcom/android/settingslib/search/Indexable$SearchIndexProvider;)V\n\n    invoke-virtual {p0, v0}, Lcom/android/settingslib/search/SearchIndexableResourcesBase;->addIndex(Lcom/android/settingslib/search/SearchIndexableData;)V\n\n    new-instance v0, Lcom/android/settingslib/search/SearchIndexableData;\n\n    const-class v1, Lio/mesalabs/unica/settings/extra/ExtraSettingsFragment;\n\n    sget-object v2, Lio/mesalabs/unica/settings/extra/ExtraSettingsFragment;->SEARCH_INDEX_DATA_PROVIDER:Lcom/android/settings/search/BaseSearchIndexProvider;\n\n    invoke-direct {v0, v1, v2}, Lcom/android/settingslib/search/SearchIndexableData;-><init>(Ljava/lang/Class;Lcom/android/settingslib/search/Indexable$SearchIndexProvider;)V\n\n    invoke-virtual {p0, v0}, Lcom/android/settingslib/search/SearchIndexableResourcesBase;->addIndex(Lcom/android/settingslib/search/SearchIndexableData;)V\n\n    new-instance v0, Lcom/android/settingslib/search/SearchIndexableData;\n\n    const-class v1, Lio/mesalabs/unica/settings/spoof/SpoofSettingsFragment;\n\n    sget-object v2, Lio/mesalabs/unica/settings/spoof/SpoofSettingsFragment;->SEARCH_INDEX_DATA_PROVIDER:Lcom/android/settings/search/BaseSearchIndexProvider;\n\n    invoke-direct {v0, v1, v2}, Lcom/android/settingslib/search/SearchIndexableData;-><init>(Ljava/lang/Class;Lcom/android/settingslib/search/Indexable$SearchIndexProvider;)V\n\n    invoke-virtual {p0, v0}, Lcom/android/settingslib/search/SearchIndexableResourcesBase;->addIndex(Lcom/android/settingslib/search/SearchIndexableData;)V\n\n    new-instance v0, Lcom/android/settingslib/search/SearchIndexableData;\n\n    const-class v1, Lio/mesalabs/unica/settings/ui/UISettingsFragment;\n\n    sget-object v2, Lio/mesalabs/unica/settings/ui/UISettingsFragment;->SEARCH_INDEX_DATA_PROVIDER:Lcom/android/settings/search/BaseSearchIndexProvider;\n\n    invoke-direct {v0, v1, v2}, Lcom/android/settingslib/search/SearchIndexableData;-><init>(Ljava/lang/Class;Lcom/android/settingslib/search/Indexable$SearchIndexProvider;)V\n\n    invoke-virtual {p0, v0}, Lcom/android/settingslib/search/SearchIndexableResourcesBase;->addIndex(Lcom/android/settingslib/search/SearchIndexableData;)V\n\n    return-object p0' \
        > /dev/null
else
    LOG "- Patching \"$SETTINGS_SEARCH_SMALI/com/android/settingslib/search/SearchIndexableResourcesMobile.smali\" in /system/system/priv-app/SecSettings.apk"
    SMALI_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
        "$SETTINGS_SEARCH_SMALI/com/android/settingslib/search/SearchIndexableResourcesMobile.smali" "replaceall" \
        '.class public final Lcom/android/settingslib/search/SearchIndexableResourcesMobile;' \
        '.class public Lcom/android/settingslib/search/SearchIndexableResourcesMobile;' \
        > /dev/null
    LOG "- Patching \"$SETTINGS_SEARCH_SMALI/com/android/settings/search/SearchFeatureProviderImpl\$\$ExternalSyntheticLambda0.smali\" in /system/system/priv-app/SecSettings.apk"
    SMALI_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
        "$SETTINGS_SEARCH_SMALI/com/android/settings/search/SearchFeatureProviderImpl\$\$ExternalSyntheticLambda0.smali" "replace" \
        'invoke()Ljava/lang/Object;' \
        'new-instance p0, Lcom/android/settingslib/search/SearchIndexableResourcesMobile;' \
        'new-instance p0, Lio/mesalabs/unica/search/UnicaSearchIndexableResources;' \
        > /dev/null
    SMALI_PATCH "system" "system/priv-app/SecSettings/SecSettings.apk" \
        "$SETTINGS_SEARCH_SMALI/com/android/settings/search/SearchFeatureProviderImpl\$\$ExternalSyntheticLambda0.smali" "replace" \
        'invoke()Ljava/lang/Object;' \
        'invoke-direct {p0}, Lcom/android/settingslib/search/SearchIndexableResourcesBase;-><init>()V' \
        'invoke-direct {p0}, Lio/mesalabs/unica/search/UnicaSearchIndexableResources;-><init>()V' \
        > /dev/null
fi

DECODE_APK "system" "system/priv-app/SecSettingsIntelligence/SecSettingsIntelligence.apk"
LOG "- Patching \"smali_classes2/com/samsung/android/settings/intelligence/search/categorizing/TopLevelKeysCollector.smali\" in /system/system/priv-app/SecSettingsIntelligence/SecSettingsIntelligence.apk"
if [ "$SOURCE_PLATFORM_SDK_VERSION" -ge "37" ]; then
    SETTINGS_INTELLIGENCE_LOCALS_OLD=37
    SETTINGS_INTELLIGENCE_LOCALS_NEW=38
    SETTINGS_INTELLIGENCE_LAST_OLD=36
    SETTINGS_INTELLIGENCE_LAST_NEW=37
else
    SETTINGS_INTELLIGENCE_LOCALS_OLD=36
    SETTINGS_INTELLIGENCE_LOCALS_NEW=37
    SETTINGS_INTELLIGENCE_LAST_OLD=35
    SETTINGS_INTELLIGENCE_LAST_NEW=36
fi
SMALI_PATCH "system" "system/priv-app/SecSettingsIntelligence/SecSettingsIntelligence.apk" \
    "smali_classes2/com/samsung/android/settings/intelligence/search/categorizing/TopLevelKeysCollector.smali" "replace" \
    '<init>(Landroid/content/Context;)V' \
    ".locals $SETTINGS_INTELLIGENCE_LOCALS_OLD" \
    ".locals $SETTINGS_INTELLIGENCE_LOCALS_NEW" \
    > /dev/null
SMALI_PATCH "system" "system/priv-app/SecSettingsIntelligence/SecSettingsIntelligence.apk" \
    "smali_classes2/com/samsung/android/settings/intelligence/search/categorizing/TopLevelKeysCollector.smali" "replace" \
    '<init>(Landroid/content/Context;)V' \
    "filled-new-array/range {v1 .. v$SETTINGS_INTELLIGENCE_LAST_OLD}, [Ljava/lang/String;" \
    "    const-string v$SETTINGS_INTELLIGENCE_LAST_NEW, \"top_level_unica\"\n\n    filled-new-array/range {v1 .. v$SETTINGS_INTELLIGENCE_LAST_NEW}, [Ljava/lang/String;" \
    > /dev/null

# Show Vulkan renderer toggle if required
if [[ "$(GET_PROP "ro.hwui.use_vulkan")" != "true" ]]; then
    SET_PROP "system" "persist.sys.unica.vulkan" "false"
fi

LOG_STEP_OUT

