LOG_STEP_IN "- Applying codec2-patch"

CODEC2_POLICY="$WORK_DIR/vendor/etc/seccomp_policy/samsung.software.media.c2-base-policy"

if [ -f "$CODEC2_POLICY" ]; then
    LOG "- Updating mremap rule in $CODEC2_POLICY"
    # Replace the existing line if present
    sed -i 's/^mremap: arg3 == 3$/mremap: arg3 == 3 || arg3 == MREMAP_MAYMOVE/' "$CODEC2_POLICY"

    # If the line wasn't found, append it
    if ! grep -q "mremap: arg3 == 3 || arg3 == MREMAP_MAYMOVE" "$CODEC2_POLICY"; then
        echo "mremap: arg3 == 3 || arg3 == MREMAP_MAYMOVE" >> "$CODEC2_POLICY"
    fi
    
    EVAL "uniq \"$WORK_DIR/system/system/build.prop\" \"$WORK_DIR/system/system/tmp\" && mv -f \"$WORK_DIR/system/system/tmp\" \"$WORK_DIR/system/system/build.prop\""
    LOG "- Adding \"debug.codec2.stop_hal_before_surface\" prop with \"1\" in /system/system/build.prop"
    EVAL "sed -i \"/spatializer_enabled=true/a debug.codec2.stop_hal_before_surface=1\" \"$WORK_DIR/system/system/build.prop\""
    EVAL "sed -i \"/stop_hal_before_surface/i ro.audio.spatializer_enabled=true\" \"$WORK_DIR/system/system/build.prop\""
    EVAL "sed -i \"/PRODUCT_SYSTEM_DEFAULT_PROPERTIES/a ####################################\" \"$WORK_DIR/system/system/build.prop\""
fi

LOG_STEP_OUT