# UN1CA SELinux entries removal list
# - Append new type entries to the ENTRIES list
# - Add the EXACT type entry, DO NOT just add a common pattern (eg. "fabriccrypto", "fabriccrypto_exec" and NOT just "fabriccrypto")
# - DO NOT add the API version at the end of the entry (eg. "fabriccrypto" and NOT "fabriccrypto_30_0")
# - DO NOT add any parenthesis or statements (eg. "fabriccrypto" and NOT "expanttypeattribute ... (fabriccrypto)")
# - DO NOT add unnecessary types or remove the existing ones unless they aren't necessary anymore for all devices

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

CIL_NAME="$(head -n 1 "$WORK_DIR/vendor/etc/selinux/plat_sepolicy_vers.txt")"
PATCHED=false
MAPPING_DIRS=(
    "$WORK_DIR/system/system/etc/selinux/mapping"
    "$WORK_DIR/$(GET_SYSTEM_EXT)/etc/selinux/mapping"
    "$WORK_DIR/product/etc/selinux/mapping"
)
MAPPING_FILES=()
for d in "${MAPPING_DIRS[@]}"; do
    [ -d "$d" ] || continue
    while IFS= read -r f; do
        MAPPING_FILES+=("$f")
    done < <(find "$d" -maxdepth 1 -type f -name '*.cil' ! -name '*.compat.cil' | sort)
done
# ]

for e in $ENTRIES; do
    ENTRY_PRESENT=false
    for f in "${MAPPING_FILES[@]}"; do
        if grep -q -F "($e)" "$f" || grep -q -F "${e}_${CIL_NAME//./_}" "$f"; then
            ENTRY_PRESENT=true
            break
        fi
    done
    if $ENTRY_PRESENT; then
        # The source mapping exposes this type; remove it when target vendor does not.
        if ! grep -q -F "(type $e)" "$WORK_DIR/vendor/etc/selinux/plat_pub_versioned.cil"; then
            PATCHED=true
            LOG "- \"$e\" SELinux entry not supported. Removing"
            for f in "${MAPPING_FILES[@]}"; do
                sed -i -e "/($e)/d" -e "/${e}_[0-9][0-9]_[0-9]/d" "$f"
            done
            if grep -q "genfscon.*$e" "$WORK_DIR/$(GET_SYSTEM_EXT)/etc/selinux/system_ext_sepolicy.cil"; then
                sed -i "/genfscon.*$e/d" "$WORK_DIR/$(GET_SYSTEM_EXT)/etc/selinux/system_ext_sepolicy.cil"
            fi
            if grep -q "genfscon.*$e" "$WORK_DIR/system/system/etc/selinux/plat_sepolicy.cil"; then
                sed -i "/genfscon.*$e/d" "$WORK_DIR/system/system/etc/selinux/plat_sepolicy.cil"
            fi
        fi
    fi
done

for e in $DUPLICATES; do
    if grep -q "^$e.*" "$WORK_DIR/$(GET_SYSTEM_EXT)/etc/selinux/system_ext_property_contexts"; then
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

unset ENTRIES DUPLICATES CIL_NAME PATCHED ENTRY_PRESENT MAPPING_DIRS MAPPING_FILES
unset -f GET_SYSTEM_EXT
