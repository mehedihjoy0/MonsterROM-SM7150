# Dynamic One UI SELinux patcher
# Author: @mehedihjoy0

GET_SYSTEM_EXT()
{
    if $TARGET_OS_BUILD_SYSTEM_EXT_PARTITION; then
        echo "system_ext"
    else
        echo "system/system/system_ext"
    fi
}
SYSTEM_EXT_PATH="$WORK_DIR/$(GET_SYSTEM_EXT)"
CIL_NAME="$(head -n 1 "$WORK_DIR/vendor/etc/selinux/plat_sepolicy_vers.txt")"
PATCHED=false

MAPPING_FILE="$SYSTEM_EXT_PATH/etc/selinux/mapping/$CIL_NAME.cil"
VENDOR_PUB_CIL="$WORK_DIR/vendor/etc/selinux/plat_pub_versioned.cil"

if [ ! -f "$MAPPING_FILE" ] || [ ! -f "$VENDOR_PUB_CIL" ]; then
    LOGW "Missing critical SELinux policy files. Skipping dynamic patch."
    return 1
fi

# Create temporary working files
TMP_MAP=$(mktemp)
TMP_VEND=$(mktemp)
TMP_DROP=$(mktemp)

# ==========================================================================
# 1. DYNAMIC SYSTEM/VENDOR TYPE MISMATCH PATCH
# ==========================================================================

# Extract all base types handled by system_ext mapping
sed -n 's/.*(typeattributeset [^ ]* (\([^)]*\))).*/\1/p' "$MAPPING_FILE" | sort -u > "$TMP_MAP"

# Extract all public types supported by target vendor
sed -n 's/.*(type \([^)]*\)).*/\1/p' "$VENDOR_PUB_CIL" | sort -u > "$TMP_VEND"

# Find types present in system mapping but completely missing from vendor
comm -23 "$TMP_MAP" "$TMP_VEND" > "$TMP_DROP"

# Fetch VENDOR_API_LIST for secondary cleanups
VENDOR_API_LIST="$(find "$SYSTEM_EXT_PATH/etc/selinux/mapping" -type f -printf "%f\n" | \
                    sed '/.compat./d' | sed 's/.cil//' | sed 's/\./_/' | sort)"

# Drop the unsupported entries dynamically
while read -r e; do
    [ -z "$e" ] && continue
    PATCHED=true
    LOG "- Dynamic Wipe: \"$e\" SELinux entry not supported by vendor. Removing"
    
    sed -i "/($e)/d" "$MAPPING_FILE"
    for a in $VENDOR_API_LIST; do
        sed -i "/${e}_${a}/d" "$MAPPING_FILE"
    done
    if grep -q "genfscon.*$e" "$SYSTEM_EXT_PATH/etc/selinux/system_ext_sepolicy.cil" 2>/dev/null; then
        sed -i "/genfscon.*$e/d" "$SYSTEM_EXT_PATH/etc/selinux/system_ext_sepolicy.cil"
    fi
    if grep -q "genfscon.*$e" "$WORK_DIR/system/system/etc/selinux/plat_sepolicy.cil" 2>/dev/null; then
        sed -i "/genfscon.*$e/d" "$WORK_DIR/system/system/etc/selinux/plat_sepolicy.cil"
    fi
done < "$TMP_DROP"

# ==========================================================================
# 2. DYNAMIC PROPERTY CONTEXTS DUPLICATE PATCH
# ==========================================================================
if [ -f "$SYSTEM_EXT_PATH/etc/selinux/system_ext_property_contexts" ] && \
   [ -f "$WORK_DIR/vendor/etc/selinux/vendor_property_contexts" ]; then
    
    TMP_SYS_PROP=$(mktemp)
    TMP_VEN_PROP=$(mktemp)
    TMP_PROP_DUP=$(mktemp)

    # Extract clean property tokens (skipping comments/empty lines)
    awk '/^[a-zA-Z0-9_.-]+/ {print $1}' "$SYSTEM_EXT_PATH/etc/selinux/system_ext_property_contexts" | sort -u > "$TMP_SYS_PROP"
    awk '/^[a-zA-Z0-9_.-]+/ {print $1}' "$WORK_DIR/vendor/etc/selinux/vendor_property_contexts" | sort -u > "$TMP_VEN_PROP"

    # Intersect to find properties defined in BOTH layers
    comm -12 "$TMP_SYS_PROP" "$TMP_VEN_PROP" > "$TMP_PROP_DUP"

    while read -r prop; do
        [ -z "$prop" ] && continue
        PATCHED=true
        LOG "- Dynamic Duplicate Wipe: \"$prop\" property found in both layers. Commenting vendor entry."
        sed -i "s|^$prop|#SEC_DUPLICATE: $prop|g" "$WORK_DIR/vendor/etc/selinux/vendor_property_contexts"
    done < "$TMP_PROP_DUP"

    rm -f "$TMP_SYS_PROP" "$TMP_VEN_PROP" "$TMP_PROP_DUP"
fi

# Clean up remaining temp files
rm -f "$TMP_MAP" "$TMP_VEND" "$TMP_DROP"

if ! $PATCHED; then
    LOG "\033[0;33m! Dynamic Analysis complete: Nothing to do\033[0m"
fisbauth
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
