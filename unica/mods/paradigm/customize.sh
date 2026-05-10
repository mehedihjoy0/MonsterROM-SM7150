if [ ! "$(GET_PROP "system" "ro.unica.codename")" ]; then
    # Match latest Samsung's flagship device codename
    ROM_CODENAME="$(basename "$MODPATH")"
    SET_PROP "system" "ro.unica.codename" "${ROM_CODENAME^}"
    unset ROM_CODENAME
fi

# 2025 Audio Pack
LOG_STEP_IN "- Adding 2025 Audio Pack"
if $TARGET_AUDIO_SUPPORT_ACH_RINGTONE; then
    SET_PROP "vendor" "ro.config.ringtone" "ACH_Galaxy_Bells.ogg"
    SET_PROP "vendor" "ro.config.notification_sound" "ACH_Brightline.ogg"
    SET_PROP "vendor" "ro.config.alarm_alert" "ACH_Morning_Xylophone.ogg"
    SET_PROP "vendor" "ro.config.media_sound" "Media_preview_Over_the_horizon.ogg"
    SET_PROP "vendor" "ro.config.ringtone_2" "ACH_Atomic_Bell.ogg"
    SET_PROP "vendor" "ro.config.notification_sound_2" "ACH_Three_Star.ogg"
else
    SET_PROP "vendor" "ro.config.ringtone" "Galaxy_Bells.ogg"
    SET_PROP "vendor" "ro.config.notification_sound" "Brightline.ogg"
    SET_PROP "vendor" "ro.config.alarm_alert" "Morning_Xylophone.ogg"
    SET_PROP "vendor" "ro.config.media_sound" "Media_preview_Over_the_horizon.ogg"
    SET_PROP "vendor" "ro.config.ringtone_2" "Atomic_Bell.ogg"
    SET_PROP "vendor" "ro.config.notification_sound_2" "Three_Star.ogg"
fi
LOG_STEP_OUT

# Adaptive colour tone is already included in One UI 8.5.

# Media Context Analyzer
LOG_STEP_IN "- Adding Media Context Analyzer feature"
EVAL "ln -s \"human-pet-pose_SR-V200.tflite\" \"$WORK_DIR/system/system/etc/mediacontextanalyzer/Pose.tflite\""
SET_METADATA "system" "system/etc/mediacontextanalyzer/Pose.tflite" 0 0 644 "u:object_r:system_file:s0"
SET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_MMFW_CONFIG_MEDIA_CONTEXT_ANALYZER_CORE" "GPU"
SET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_MMFW_SUPPORT_MEDIA_CONTEXT_ANALYZER" "TRUE"
LOG_STEP_OUT

# Audio eraser
# Requires SEC_PRODUCT_FEATURE_MMFW_SUPPORT_MEDIA_CONTEXT_ANALYZER
LOG_STEP_IN "- Adding Audio eraser feature"
SET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_AUDIO_CONFIG_MULTISOURCE_SEPARATOR" "{FastScanning_6, SourceSeparator_4, Version_1.3.0}"
LOG_STEP_OUT

_IMPORT_SOURCE_FLOATING_FEATURE_FLAGS()
{
    local SOURCE_FILE="$1"
    local FEATURE
    local CURRENT_VALUE
    local IMPORTED_COUNT=0

    if [ ! -f "$SOURCE_FILE" ]; then
        LOGW "Source firmware floating_feature.xml not found; skipping S26 floating feature flags"
        return 0
    fi

    while IFS= read -r FEATURE; do
        [ "$FEATURE" ] || continue
        CURRENT_VALUE="$(GET_FLOATING_FEATURE_CONFIG "$FEATURE")"
        if [[ "${CURRENT_VALUE^^}" == "TRUE" ]]; then
            continue
        fi

        SET_FLOATING_FEATURE_CONFIG "$FEATURE" "TRUE"
        IMPORTED_COUNT=$((IMPORTED_COUNT + 1))
    done < <(perl -0777 -ne '
        while (/<(SEC_FLOATING_FEATURE_[A-Z0-9_]+)>([^<]*)<\/\1>/g) {
            my ($feature, $value) = ($1, $2);
            $value =~ s/^\s+|\s+$//g;
            next unless uc($value) eq "TRUE";
            next unless $feature =~ /_(SUPPORT|ENABLE|FUNCTION)(_|$)/;
            print "$feature\n";
        }
    ' "$SOURCE_FILE")

    LOG "- Imported $IMPORTED_COUNT S26 floating feature flag(s)"
}

_IMPORT_SOURCE_FLOATING_FEATURE_CONFIGS()
{
    local SOURCE_FILE="$1"
    local CONFIG
    local VALUE
    local IMPORTED_COUNT=0

    if [ ! -f "$SOURCE_FILE" ]; then
        LOGW "Source firmware floating_feature.xml not found; skipping S26 floating feature configs"
        return 0
    fi

    for CONFIG in \
            "SEC_FLOATING_FEATURE_FRAMEWORK_CONFIG_APPFUNCTION_AGENT_APPLIST"; do
        VALUE="$(GET_FLOATING_FEATURE_CONFIG "$SOURCE_FILE" "$CONFIG")"
        [ "$VALUE" ] || continue

        SET_FLOATING_FEATURE_CONFIG "$CONFIG" "$VALUE"
        IMPORTED_COUNT=$((IMPORTED_COUNT + 1))
    done

    LOG "- Imported $IMPORTED_COUNT S26 floating feature config(s)"
}

# Now brief / Now Nudge
# Requires SEC_FLOATING_FEATURE_COMMON_CONFIG_AI_VERSION >= 20251
# or SEC_FLOATING_FEATURE_FRAMEWORK_SUPPORT_AI_BRIEF_FOR_UT
LOG_STEP_IN "- Adding Now brief and Now Nudge features"
SOURCE_FIRMWARE_PATH="$(cut -d "/" -f 1 -s <<< "$SOURCE_FIRMWARE")_$(cut -d "/" -f 2 -s <<< "$SOURCE_FIRMWARE")"
SOURCE_FLOATING_FEATURE="$FW_DIR/$SOURCE_FIRMWARE_PATH/system/system/etc/floating_feature.xml"
if [ -f "$SOURCE_FLOATING_FEATURE" ]; then
    AI_VERSION="$(GET_FLOATING_FEATURE_CONFIG "$SOURCE_FLOATING_FEATURE" "SEC_FLOATING_FEATURE_COMMON_CONFIG_AI_VERSION")"
else
    AI_VERSION=""
fi
if [ ! "$AI_VERSION" ]; then
    LOGW "SEC_FLOATING_FEATURE_COMMON_CONFIG_AI_VERSION not found in source firmware, using S26 default"
    AI_VERSION="20261"
fi
SET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_COMMON_CONFIG_AI_VERSION" "$AI_VERSION"
SET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_FRAMEWORK_SUPPORT_PERSONALIZED_DATA_CORE" "TRUE"
LOG_STEP_OUT

LOG_STEP_IN "- Importing S26 floating feature flags"
_IMPORT_SOURCE_FLOATING_FEATURE_FLAGS "$SOURCE_FLOATING_FEATURE"
_IMPORT_SOURCE_FLOATING_FEATURE_CONFIGS "$SOURCE_FLOATING_FEATURE"
unset AI_VERSION SOURCE_FLOATING_FEATURE SOURCE_FIRMWARE_PATH FEATURE CURRENT_VALUE CONFIG VALUE IMPORTED_COUNT
unset -f _IMPORT_SOURCE_FLOATING_FEATURE_FLAGS _IMPORT_SOURCE_FLOATING_FEATURE_CONFIGS
LOG_STEP_OUT

# S26 neural stack
# Required by the S26 AIOS/SSNeuralCore userspace used by Now Nudge and Semantic Search.
if [[ "$TARGET_PLATFORM" == "exynos2100" ]]; then
    LOG_STEP_IN "- Backporting S26 neural stack"
    S26_ENN_VENDOR_FILES="
bin/hw/vendor.samsung_slsi.hardware.enn_aidl-service
etc/enn
etc/init/enn-lazy.rc
etc/vintf/manifest/enn-default.xml
lib64/libenn_common_utils.so
lib64/libenn_cpu_operators.so
lib64/libenn_engine.so
lib64/libenn_engine_lib.so
lib64/libenn_model.so
lib64/libenn_public_api_cpp.so
lib64/libenn_public_api_cpp_lib.so
lib64/libenn_user.samsung_slsi.so
lib64/libenn_user_driver_cpu.so
lib64/libenn_user_driver_gpu.so
lib64/libenn_user_driver_gpu_lib.so
lib64/libenn_user_driver_unified.so
lib64/libenn_user_lib.so
lib64/libenn_wrapper.so
lib64/vendor.samsung_slsi.hardware.enn_aidl-V1-ndk.so
"
    while IFS= read -r ENN_FILE; do
        [ "$ENN_FILE" ] || continue
        ADD_TO_WORK_DIR "$SOURCE_FIRMWARE" "vendor" "$ENN_FILE"
    done <<< "$S26_ENN_VENDOR_FILES"
    unset ENN_FILE S26_ENN_VENDOR_FILES

    if ! grep -q -F "vendor.samsung_slsi.hardware.enn_aidl.IEnnInterfaceAidl/default" "$WORK_DIR/vendor/etc/selinux/vendor_service_contexts"; then
        echo "vendor.samsung_slsi.hardware.enn_aidl.IEnnInterfaceAidl/default     u:object_r:hal_enn_service:s0" >> "$WORK_DIR/vendor/etc/selinux/vendor_service_contexts"
    fi

    if ! grep -q -F "vendor.samsung_slsi.hardware.enn::IEnnInterface" "$WORK_DIR/vendor/etc/selinux/vendor_hwservice_contexts"; then
        echo "vendor.samsung_slsi.hardware.enn::IEnnInterface                         u:object_r:hal_enn_hwservice:s0" >> "$WORK_DIR/vendor/etc/selinux/vendor_hwservice_contexts"
    fi

    if ! grep -q -F "(type hal_enn_default)" "$WORK_DIR/vendor/etc/selinux/vendor_sepolicy.cil"; then
        cat >> "$WORK_DIR/vendor/etc/selinux/vendor_sepolicy.cil" <<'EOF'

; S26 ENN AIDL neural stack backport.
(type hal_enn_default)
(roletype object_r hal_enn_default)
(type hal_enn_default_exec)
(roletype object_r hal_enn_default_exec)
(type hal_enn_hwservice)
(roletype object_r hal_enn_hwservice)
(type hal_enn_service)
(roletype object_r hal_enn_service)
(typeattributeset domain (hal_enn_default))
(typeattributeset halserverdomain (hal_enn_default))
(typeattributeset halclientdomain (hal_enn_default))
(typeattributeset hal_neuralnetworks (hal_enn_default))
(typeattributeset hal_neuralnetworks_server (hal_enn_default))
(typeattributeset exec_type (hal_enn_default_exec))
(typeattributeset vendor_file_type (hal_enn_default_exec))
(typeattributeset file_type (hal_enn_default_exec))
(typeattributeset service_manager_type (hal_enn_service))
(typeattributeset hal_service_type (hal_enn_service))
(typeattributeset hwservice_manager_type (hal_enn_hwservice))
(allow init_30_0 hal_enn_default_exec (file (read getattr map execute open)))
(allow init_30_0 hal_enn_default (process (transition siginh rlimitinh)))
(dontaudit init_30_0 hal_enn_default (process (noatsecure)))
(typetransition init_30_0 hal_enn_default_exec process hal_enn_default)
(allow hal_enn_default hal_enn_default_exec (file (read getattr map execute open entrypoint)))
(allow hal_enn_default hwservicemanager_30_0 (binder (call transfer)))
(allow hal_enn_default hidl_base_hwservice_30_0 (hwservice_manager (add)))
(allow hal_enn_default hidl_allocator_hwservice_30_0 (hwservice_manager (find)))
(allow hal_enn_default hal_enn_hwservice (hwservice_manager (add find)))
(allow hal_enn_default servicemanager_30_0 (binder (call transfer)))
(allow servicemanager_30_0 hal_enn_default (binder (call transfer)))
(allow hal_enn_default servicemanager_30_0 (fd (use)))
(allow hal_enn_default hal_enn_service (service_manager (add)))
(allow untrusted_app_all hal_enn_service (service_manager (find)))
(allow untrusted_app_all hal_enn_hwservice (hwservice_manager (find)))
(allow untrusted_app_all hal_enn_default (binder (call transfer)))
(allow hal_enn_default untrusted_app_all (binder (call transfer)))
(allow hal_enn_default untrusted_app_all (fd (use)))
(allow system_app_30_0 hal_enn_service (service_manager (find)))
(allow platform_app_30_0 hal_enn_service (service_manager (find)))
(allow priv_app_30_0 hal_enn_service (service_manager (find)))
(allow system_app_30_0 hal_enn_default (binder (call transfer)))
(allow platform_app_30_0 hal_enn_default (binder (call transfer)))
(allow priv_app_30_0 hal_enn_default (binder (call transfer)))
(allow hal_enn_default system_app_30_0 (binder (call transfer)))
(allow hal_enn_default platform_app_30_0 (binder (call transfer)))
(allow hal_enn_default priv_app_30_0 (binder (call transfer)))
(allow hal_enn_default system_app_30_0 (fd (use)))
(allow hal_enn_default platform_app_30_0 (fd (use)))
(allow hal_enn_default priv_app_30_0 (fd (use)))
(allow hal_enn_default ion_device_30_0 (chr_file (ioctl read write getattr map open)))
; This device type has no 30.0 mapping alias, so use the public platform type directly.
(allow hal_enn_default dmabuf_system_heap_device (chr_file (ioctl read write getattr map open)))
(allow hal_enn_default vendor_npu_device (chr_file (ioctl read write getattr map open)))
(allow hal_enn_default vendor_dsp_device (chr_file (ioctl read write getattr map open)))
; This sysfs type has no 30.0 mapping alias either.
(allow hal_enn_default sysfs_gpu (file (ioctl read getattr lock map open watch watch_reads)))
(allow hal_enn_default sysfs_gpu (dir (ioctl read getattr lock open watch watch_reads search)))
(allow hal_enn_default gpu_device_30_0 (chr_file (ioctl read write getattr map open)))
(allow hal_enn_default gpu_device_30_0 (dir (ioctl read getattr lock open watch watch_reads search)))
EOF
    fi

    # Repair older generated ENN blocks when rebuilding without recreating work_dir.
    sed -i \
        -e 's/(allow hal_enn_default dmabuf_system_heap_device_30_0 /(allow hal_enn_default dmabuf_system_heap_device /g' \
        -e '/(allow hal_enn_default sysfs_gpu_30_0 (lnk_file /d' \
        -e '/(allow hal_enn_default sysfs_gpu (lnk_file /d' \
        -e 's/(allow hal_enn_default sysfs_gpu_30_0 /(allow hal_enn_default sysfs_gpu /g' \
        "$WORK_DIR/vendor/etc/selinux/vendor_sepolicy.cil"

    DECODE_APK "system" "system/priv-app/AIOSKernelService/AIOSKernelService.apk"
    AIOS_CONFIG="$APKTOOL_DIR/system/priv-app/AIOSKernelService/AIOSKernelService.apk/assets/config/supported_config.json"
    if [ -f "$AIOS_CONFIG" ]; then
        LOG "- Enabling Exynos2100 AIOS neural config"
        cat > "$AIOS_CONFIG" <<'EOF'
{
  "qc_sm8850": {
    "LLM": {
      "libssneural_vndk.so": "3.5.0"
    },
    "LLMV": {
      "libssneural_vndk.so": "3.5.0"
    },
    "LVM": {
      "libssneural_vndk.so": "0.9.0.0"
    }
  },
  "slsi_s5e9965": {
    "LLM": {
      "libssneural_vndk.so": "3.5.0"
    },
    "LLMV": {
      "libssneural_vndk.so": "3.5.0"
    },
    "LVM": {
      "libssneural_vndk.so": "0.9.0.0"
    }
  },
  "exynos2100": {
    "LLM": {
      "libssneural_vndk.so": "3.5.0"
    },
    "LLMV": {
      "libssneural_vndk.so": "3.5.0"
    },
    "LVM": {
      "libssneural_vndk.so": "0.9.0.0"
    }
  },
  "slsi_exynos2100": {
    "LLM": {
      "libssneural_vndk.so": "3.5.0"
    },
    "LLMV": {
      "libssneural_vndk.so": "3.5.0"
    },
    "LVM": {
      "libssneural_vndk.so": "0.9.0.0"
    }
  },
  "universal2100_r": {
    "LLM": {
      "libssneural_vndk.so": "3.5.0"
    },
    "LLMV": {
      "libssneural_vndk.so": "3.5.0"
    },
    "LVM": {
      "libssneural_vndk.so": "0.9.0.0"
    }
  },
  "Exynos 2100": {
    "LLM": {
      "libssneural_vndk.so": "3.5.0"
    },
    "LLMV": {
      "libssneural_vndk.so": "3.5.0"
    },
    "LVM": {
      "libssneural_vndk.so": "0.9.0.0"
    }
  }
}
EOF
    else
        LOGW "AIOS supported_config.json not found; skipping Exynos2100 neural config"
    fi
    unset AIOS_CONFIG
    LOG_STEP_OUT
fi

# Semantic search
# Requires SEC_FLOATING_FEATURE_COMMON_CONFIG_AI_VERSION >= 20251
DECODE_APK "system" "system/priv-app/SecSettingsIntelligence/SecSettingsIntelligence.apk"
LOG "- Enabling Semantic search feature in /system/system/priv-app/SecSettingsIntelligence/SecSettingsIntelligence.apk"
SEMANTIC_RAW_DIR="$MODPATH/semanticsearch/SecSettingsIntelligence.apk/res/raw"
if [ -d "$SEMANTIC_RAW_DIR" ]; then
    EVAL "cp -a \"$SEMANTIC_RAW_DIR/\"* \"$APKTOOL_DIR/system/priv-app/SecSettingsIntelligence/SecSettingsIntelligence.apk/res/raw\""
else
    LOGW "Semantic search raw resources not found in module; using resources already bundled in SecSettingsIntelligence"
fi
SET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_MSCH_SUPPORT_NLSEARCH" "TRUE"
LOG_STEP_OUT
