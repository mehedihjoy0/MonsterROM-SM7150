LOG_STEP_IN "- Adding \"ro.netflix.bsp_rev\" prop with \"Q7250-19133-1\" in /system/system/build.prop"
EVAL "sed -i \"/ro.smps.gain.spk/i ro.netflix.bsp_rev=Q7250-19133-1\" \"$WORK_DIR/system/system/build.prop\""
LOG_STEP_OUT 

LOG_STEP_IN "- Removing frp"
SET_PROP "product" "ro.frp.pst" --delete
SET_PROP "vendor" "ro.frp.pst" --delete
LOG_STEP_OUT 

LOG_STEP_IN "- Removing WAV 32-bit PCM support"
SET_PROP "system" "media.extractor.sec.pcm-32bit" --delete
LOG_STEP_OUT

LOG_STEP_IN "- Fixing edge lighting"
SET_PROP "system" "ro.factory.model" "$(GET_PROP "vendor" "ro.product.vendor.model")"
LOG_STEP_OUT 

LOG_STEP_IN "- Increasing audio offload buffer size"
SET_PROP "vendor" "vendor.audio.offload.buffer.size.kb" "256"
LOG_STEP_OUT

LOG_STEP_IN "- Decreasing touch latency"
SET_PROP "vendor" "ro.surface_flinger.use_content_detection_for_refresh_rate" "true"
LOG "- Adding \"ro.surface_flinger.set_idle_timer_ms\" prop with \"4000\" in /vendor/default.prop"
EVAL "sed -i \"/use_content_detection/a ro.surface_flinger.set_idle_timer_ms=4000\" \"$WORK_DIR/vendor/default.prop\""
LOG "- Adding \"ro.surface_flinger.set_touch_timer_ms\" prop with \"4000\" in /vendor/default.prop"
EVAL "sed -i \"/set_idle_timer_ms/a ro.surface_flinger.set_touch_timer_ms=4000\" \"$WORK_DIR/vendor/default.prop\""
SET_PROP "vendor" "ro.surface_flinger.enable_frame_rate_override" "true"
LOG_STEP_OUT

LOG_STEP_IN "- Setting FUSE passthrough"
SET_PROP "vendor" "persist.sys.fuse.passthrough.enable" "true"
LOG_STEP_OUT

LOG_STEP_IN "- Fixing vendor display props"
# DPI
LCD_DENSITY="$(GET_PROP "vendor" "ro.sf.lcd_density")"
if [ "$LCD_DENSITY" ]; then
    SET_PROP "vendor" "ro.sf.init.lcd_density" "$LCD_DENSITY"
else
    ABORT "ro.sf.lcd_density prop not found in vendor"
fi
LOG_STEP_OUT

LOG_STEP_IN "- Removing unsupported Qualcomm location/QCC stack"
GET_SYSTEM_EXT()
{
    if $TARGET_OS_BUILD_SYSTEM_EXT_PARTITION; then
        echo "system_ext"
    else
        echo "system/system/system_ext"
    fi
}

_SED_DELETE_IF_EXISTS()
{
    [ -f "$1" ] || return 0
    sed -i "$2" "$1"
}

_FOR_EACH_SNAPDRAGON_INIT()
{
    local SED_EXPR="$1"
    local INIT_RC

    for INIT_RC in \
        "$WORK_DIR/vendor/etc/init/init.target.rc"; do
        _SED_DELETE_IF_EXISTS "$INIT_RC" "$SED_EXPR"
    done
}

_DISABLE_PERFETTO_TRACED()
{
    local PERFETTO_RC="$WORK_DIR/system/system/etc/init/perfetto.rc"

    [ -f "$PERFETTO_RC" ] || return 0

    LOG "- Disabling Perfetto traced daemon for legacy Snapdragon kernel"
    sed -i \
        -e 's/^\([[:space:]]*\)setprop persist\.traced\.enable 1$/\1# setprop persist.traced.enable 1/g' \
        -e 's/^\([[:space:]]*\)start traced$/\1# start traced/g' \
        -e 's/^\([[:space:]]*\)start traced_relay$/\1# start traced_relay/g' \
        -e 's/^\([[:space:]]*\)start traced_probes$/\1# start traced_probes/g' \
        -e 's/^\([[:space:]]*\)wait_for_prop sys\.trace\.traced_started 1$/\1# wait_for_prop sys.trace.traced_started 1/g' \
        "$PERFETTO_RC"
    SET_PROP_IF_DIFF "system" "persist.traced.enable" "0"
}

_SED_DELETE_IF_EXISTS "$WORK_DIR/system/system/etc/init/netbpfload.rc" "/reboot_on_failure[[:space:]][[:space:]]*reboot,netbpfload-missing/d"
_SED_DELETE_IF_EXISTS "$WORK_DIR/system/system/etc/init/vold.rc" "/reboot_on_failure[[:space:]][[:space:]]*reboot,vold-failed/d"

DELETE_FROM_WORK_DIR "system_ext" "priv-app/com.qualcomm.location"
DELETE_FROM_WORK_DIR "system_ext" "etc/permissions/com.qualcomm.location.xml"
DELETE_FROM_WORK_DIR "system_ext" "etc/permissions/privapp-permissions-com.qualcomm.location.xml"
DELETE_FROM_WORK_DIR "system_ext" "bin/perfservice"
DELETE_FROM_WORK_DIR "system_ext" "etc/init/perfservice.rc"
DELETE_FROM_WORK_DIR "system_ext" "etc/seccomp_policy/perfservice.policy"
DELETE_FROM_WORK_DIR "system_ext" "app/QCC"
DELETE_FROM_WORK_DIR "system_ext" "etc/permissions/com.qti.qcc.vendor_qcc.xml"
DELETE_FROM_WORK_DIR "system_ext" "bin/qccsyshal@1.2-service"
DELETE_FROM_WORK_DIR "system_ext" "bin/qccsyshal_aidl-service"
DELETE_FROM_WORK_DIR "system_ext" "etc/init/vendor.qti.hardware.qccsyshal@1.2-service.rc"
DELETE_FROM_WORK_DIR "system_ext" "etc/init/vendor.qti.qccsyshal_aidl-service.rc"
DELETE_FROM_WORK_DIR "system_ext" "etc/vintf/manifest/vendor.qti.qccsyshal_aidl-service.xml"
DELETE_FROM_WORK_DIR "system_ext" "lib64/libqcc.so"
DELETE_FROM_WORK_DIR "system_ext" "lib64/libqcc_file_agent_sys.so"
DELETE_FROM_WORK_DIR "system_ext" "lib64/libqccdme.so"
DELETE_FROM_WORK_DIR "system_ext" "lib64/libqccfileservice.so"

_SED_DELETE_IF_EXISTS "$WORK_DIR/$(GET_SYSTEM_EXT)/etc/sysconfig/qti_whitelist_system_ext.xml" "/com\.qualcomm\.location/d"
_SED_DELETE_IF_EXISTS "$WORK_DIR/system/system/etc/sysconfig/qti_whitelist.xml" "/com\.qualcomm\.location/d"
_SED_DELETE_IF_EXISTS "$WORK_DIR/system/system/etc/deviceidle/reviewed_allowlist.xml" "/com\.qualcomm\.location/d"
_SED_DELETE_IF_EXISTS "$WORK_DIR/system/system/etc/permissions/platform.xml" "/com\.qualcomm\.location/d"

LOG_STEP_IN "- Removing invalid vendor property sets"
_SED_DELETE_IF_EXISTS "$WORK_DIR/vendor/build.prop" "/^\(net\.dns1\|net\.dns2\|persist\.demo\.hdmirotationlock\|ro\.em\.version\|vendor\.hwc\.vsync_mode\|ro\.smps\.enable\|security\.securehw\.available\|security\.securenvm\.available\|ro\.apk_verity\.mode\)=/d"
_FOR_EACH_SNAPDRAGON_INIT "/setprop persist\.rmnet\.mux /d"
_FOR_EACH_SNAPDRAGON_INIT "/setprop persist\.rmnet\.data\.enable /d"
_FOR_EACH_SNAPDRAGON_INIT "/setprop persist\.data\.wda\.enable /d"
_FOR_EACH_SNAPDRAGON_INIT "/setprop persist\.data\.df\.agg\.dl_pkt /d"
_FOR_EACH_SNAPDRAGON_INIT "/setprop persist\.data\.df\.agg\.dl_size /d"
_FOR_EACH_SNAPDRAGON_INIT "/setprop ro\.crypto\.fuse_sdcard /d"
_DISABLE_PERFETTO_TRACED
LOG_STEP_OUT

unset -f GET_SYSTEM_EXT _SED_DELETE_IF_EXISTS _FOR_EACH_SNAPDRAGON_INIT _DISABLE_PERFETTO_TRACED
LOG_STEP_OUT