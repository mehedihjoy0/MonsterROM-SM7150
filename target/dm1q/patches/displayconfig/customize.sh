# Spoof ro.product.vendor.device for temporary display configuration fix on affected devices. (Some users have reported that their display (configuration) looked weird after installing a Magisk module called Ultimate Module S23X (version 3.5, fixed in later versions!) or RWACA - ROM Without A Cool Acronym - OneUI 7 Beta port.)
# This does not seem to cause any problems on non-affected devices.
DEVICE_INIT="$WORK_DIR/vendor/etc/init/hw/init.${TARGET_CODENAME}.rc"
SPOOFED_DEVICE_INIT="$WORK_DIR/vendor/etc/init/hw/init.${TARGET_CODENAME}xxx.rc"
if [ -f "$DEVICE_INIT" ] && [ ! -f "$SPOOFED_DEVICE_INIT" ]; then
    LOG "- Preserving the S23 device init for the spoofed vendor device name"
    cp -a "$DEVICE_INIT" "$SPOOFED_DEVICE_INIT"
    SET_METADATA "vendor" "etc/init/hw/init.${TARGET_CODENAME}xxx.rc" 0 0 644 "u:object_r:vendor_configs_file:s0"
fi

LCD_DENSITY="$(GET_PROP "vendor" "ro.sf.lcd_density")"
if [ "$LCD_DENSITY" ]; then
    SET_PROP "vendor" "ro.sf.init.lcd_density" "$LCD_DENSITY"
fi

SET_PROP "vendor" "ro.product.vendor.device" "${TARGET_CODENAME}xxx"

unset DEVICE_INIT SPOOFED_DEVICE_INIT LCD_DENSITY
