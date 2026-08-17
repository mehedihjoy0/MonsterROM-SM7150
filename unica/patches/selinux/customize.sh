# UN1CA SELinux entries removal list
# - Append new type entries to the ENTRIES list
# - Add the EXACT type entry, DO NOT just add a common pattern (eg. "fabriccrypto", "fabriccrypto_exec" and NOT just "fabriccrypto")
# - DO NOT add the API version at the end of the entry (eg. "fabriccrypto" and NOT "fabriccrypto_30_0")
# - DO NOT add any parenthesis or statements (eg. "fabriccrypto" and NOT "expanttypeattribute ... (fabriccrypto)")
# - DO NOT add unnecessary types or remove the existing ones unless they aren't necessary anymore for all devices

# One UI 9.0 additions
ENTRIES+="
mosey_app
"

# One UI 8.0 additions
ENTRIES+="
heatmap_default
heatmap_default_exec
"

DUPLICATES+="
init.svc.vendor.wvkprov_server_hal
"

# One UI 7.0 additions
ENTRIES+="
attiqi_app
attiqi_app_data_file
ker_app
kpp_app
kpp_data_file
"

# One UI 6.1.1 additions
ENTRIES+="
hal_dsms_default
hal_dsms_default_exec
proc_compaction_proactiveness
sbauth
sbauth_exec
"

# One UI 5.1.1 additions
ENTRIES+="
audiomirroring
audiomirroring_exec
audiomirroring_service
fabriccrypto
fabriccrypto_exec
fabriccrypto_data_file
hal_dsms_service
uwb_regulation_skip_prop
"

# [
GET_SYSTEM_EXT()
{
    if $TARGET_OS_BUILD_SYSTEM_EXT_PARTITION; then
        echo "system_ext"
    else
        echo "system/system/system_ext"
    fi
}

# RESTORE_TARGET_MAPPING <partition> <file> <work file>
RESTORE_TARGET_MAPPING()
{
    local PARTITION="$1"
    local FILE="$2"
    local WORK_FILE="$3"

    if [ ! -f "$WORK_FILE" ]; then
        LOG "- Restoring /$PARTITION/$FILE from target firmware"
        ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "$PARTITION" "$FILE" \
            0 0 644 "u:object_r:system_file:s0" || \
            ABORT "Failed to restore target SELinux mapping: /$PARTITION/$FILE"
        PATCHED=true
    fi

    if [ ! -s "$WORK_FILE" ]; then
        ABORT "Missing target SELinux mapping: ${WORK_FILE//$WORK_DIR/}"
    fi
}

CIL_NAME="$(head -n 1 "$WORK_DIR/vendor/etc/selinux/plat_sepolicy_vers.txt")"
PATCHED=false
SYSTEM_EXT_DIR="$(GET_SYSTEM_EXT)"

# Android 17 no longer provides API 30 compatibility mappings. Restore both
# halves of the target's policy mapping floor; retaining only system_ext is not
# sufficient for a vendor whose plat_sepolicy_vers is 30.0.
if [[ "$CIL_NAME" == "30.0" ]]; then
    RESTORE_TARGET_MAPPING "system" "system/etc/selinux/mapping/$CIL_NAME.cil" \
        "$WORK_DIR/system/system/etc/selinux/mapping/$CIL_NAME.cil"
    RESTORE_TARGET_MAPPING "system" "system/etc/selinux/mapping/$CIL_NAME.compat.cil" \
        "$WORK_DIR/system/system/etc/selinux/mapping/$CIL_NAME.compat.cil"
    RESTORE_TARGET_MAPPING "system_ext" "etc/selinux/mapping/$CIL_NAME.cil" \
        "$WORK_DIR/$SYSTEM_EXT_DIR/etc/selinux/mapping/$CIL_NAME.cil"
    RESTORE_TARGET_MAPPING "system_ext" "etc/selinux/mapping/$CIL_NAME.compat.cil" \
        "$WORK_DIR/$SYSTEM_EXT_DIR/etc/selinux/mapping/$CIL_NAME.compat.cil"
fi

VENDOR_API_LIST="$(find "$WORK_DIR/$SYSTEM_EXT_DIR/etc/selinux/mapping" -type f -printf "%f\n" | \
                    sed '/.compat./d' | sed 's/.cil//' | sed 's/\./_/' | sort)"
# ]

for e in $ENTRIES; do
    if grep -q -F "($e)" "$WORK_DIR/$SYSTEM_EXT_DIR/etc/selinux/mapping/$CIL_NAME.cil" || \
         grep -q -F "${e}_${CIL_NAME//./_}" "$WORK_DIR/$SYSTEM_EXT_DIR/etc/selinux/mapping/$CIL_NAME.cil"; then
        # the problematic entry is currently present in system_ext, check if we need to remove it
        if ! grep -q -F "(type $e)" "$WORK_DIR/vendor/etc/selinux/plat_pub_versioned.cil"; then
            PATCHED=true
            # the problematic entry is not supported by the target device
            LOG "- \"$e\" SELinux entry not supported. Removing"
            sed -i "/($e)/d" "$WORK_DIR/$SYSTEM_EXT_DIR/etc/selinux/mapping/$CIL_NAME.cil"
            for a in $VENDOR_API_LIST; do
                sed -i "/${e}_${a}/d" "$WORK_DIR/$SYSTEM_EXT_DIR/etc/selinux/mapping/$CIL_NAME.cil"
            done
            if grep -q "genfscon.*$e" "$WORK_DIR/$SYSTEM_EXT_DIR/etc/selinux/system_ext_sepolicy.cil"; then
                sed -i "/genfscon.*$e/d" "$WORK_DIR/$SYSTEM_EXT_DIR/etc/selinux/system_ext_sepolicy.cil"
            fi
            if grep -q "genfscon.*$e" "$WORK_DIR/system/system/etc/selinux/plat_sepolicy.cil"; then
                sed -i "/genfscon.*$e/d" "$WORK_DIR/system/system/etc/selinux/plat_sepolicy.cil"
            fi
        fi
    fi
done

for e in $DUPLICATES; do
    if grep -q "^$e.*" "$WORK_DIR/$SYSTEM_EXT_DIR/etc/selinux/system_ext_property_contexts"; then
        # the problematic entry is currently present in system_ext, check if we need to remove it
        if grep -q "^$e.*" "$WORK_DIR/vendor/etc/selinux/vendor_property_contexts"; then
            PATCHED=true
            # the problematic entry is found in target vendor
            LOG "- \"$e\" SELinux duplicate entry found. Removing"
            sed -i "s/^$e/#SEC_DUPLICATE: $e/g" "$WORK_DIR/vendor/etc/selinux/vendor_property_contexts"
        fi
    fi
done

if ! $PATCHED; then
    LOG "\033[0;33m! Nothing to do\033[0m"
fi

unset ENTRIES DUPLICATES CIL_NAME PATCHED SYSTEM_EXT_DIR VENDOR_API_LIST
unset -f GET_SYSTEM_EXT RESTORE_TARGET_MAPPING
