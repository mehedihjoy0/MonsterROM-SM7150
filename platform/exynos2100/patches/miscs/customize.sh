LOG "- Disabling encryption"
# Encryption
LINE=$(sed -n "/^\/dev\/block\/by-name\/userdata/=" "$WORK_DIR/vendor/etc/fstab.exynos2100")
sed -i "${LINE}s/,fileencryption=aes-256-xts:aes-256-cts:v2//g" "$WORK_DIR/vendor/etc/fstab.exynos2100"

# ODE
sed -i -e "/ODE/d" -e "/keydata/d" -e "/keyrefuge/d" "$WORK_DIR/vendor/etc/fstab.exynos2100"

LOG_STEP_IN "- Fixing vendor display props"
# DPI
LCD_DENSITY="$(GET_PROP "vendor" "ro.sf.lcd_density")"
if [ "$LCD_DENSITY" ]; then
    SET_PROP "vendor" "ro.sf.init.lcd_density" "$LCD_DENSITY"
else
    ABORT "ro.sf.lcd_density prop not found in vendor"
fi
LOG_STEP_OUT
_FIX_STRONGBOX_KEYMASTER_RC()
{
    local RC="$WORK_DIR/vendor/etc/init/android.hardware.keymaster@4.0_strongbox-service.rc"

    [ -f "$RC" ] || return 0

    if ! grep -q "^    interface android\.hardware\.keymaster@4\.0::IKeymasterDevice strongbox$" "$RC"; then
        sed -i \
            "/^service vendor\.keymaster-4-0_strongbox /a\\    interface android.hardware.keymaster@4.0::IKeymasterDevice strongbox" \
            "$RC"
    fi
}

_DISABLE_STALE_KEYMASTER_WAIT()
{
    LOG "- Disabling stale wait_for_keymaster init hook"
    _FOR_EACH_EXYNOS_INIT 's/^\([[:space:]]*\)exec_start wait_for_keymaster$/\1# exec_start wait_for_keymaster/g'
}

_PATCH_SENSORHUB_SYSFS_LOG_NOISE()
{
    local SENSORHUB="$WORK_DIR/vendor/lib64/sensors.sensorhub.so"

    [ -f "$SENSORHUB" ] || return 0

    LOG "- Suppressing noisy sensorhub sysfs write error logs"
    HEX_PATCH "$SENSORHUB" \
        "c0008052e30316aae503142a245d0094e00315aa" \
        "c0008052e30316aae503142a1f2003d5e00315aa" || true
    HEX_PATCH "$SENSORHUB" \
        "c0008052e30313aae503142a115d0094" \
        "c0008052e30313aae503142a1f2003d5" || true
}

_DROP_MISSING_SENSOR_HAL_BLOBS()
{
    local HALS_CONF="$WORK_DIR/vendor/etc/sensors/hals.conf"
    local HAL_BLOB
    local HAL_PATTERN

    [ -f "$HALS_CONF" ] || return 0

    for HAL_BLOB in sensors.bio.so; do
        [ ! -f "$WORK_DIR/vendor/lib64/$HAL_BLOB" ] || continue
        HAL_PATTERN="${HAL_BLOB//./\\.}"

        if grep -q "$HAL_BLOB" "$HALS_CONF"; then
            LOG "- Removing absent $HAL_BLOB from vendor sensors hals.conf"
            sed -i "/$HAL_PATTERN/d" "$HALS_CONF"
        fi
    done
}

_DISABLE_SURFACEFLINGER_SHADER_CACHE()
{
    local INIT_RC="$WORK_DIR/system/system/etc/init/hw/init.rc"
    local PROP

    [ -f "$INIT_RC" ] || return 0

    if grep -q "^[[:space:]]*setprop service\.sf\.cache_dir_available 1$" "$INIT_RC"; then
        LOG "- Disabling SurfaceFlinger shader cache priming for legacy gralloc"
        sed -i \
            's/^\([[:space:]]*\)setprop service\.sf\.cache_dir_available 1$/\1# setprop service.sf.cache_dir_available 1/g' \
            "$INIT_RC"
    fi

    LOG "- Disabling SurfaceFlinger prime shader cache"
    SET_PROP "product" "service.sf.cache_dir_available" "0"
    SET_PROP "product" "service.sf.prime_shader_cache" "0"

    for PROP in \
        debug.sf.prime_shader_cache.clipped_dimmed_image_layers \
        debug.sf.prime_shader_cache.clipped_layers \
        debug.sf.prime_shader_cache.edge_extension_shader \
        debug.sf.prime_shader_cache.hole_punch \
        debug.sf.prime_shader_cache.image_dimmed_layers \
        debug.sf.prime_shader_cache.image_layers \
        debug.sf.prime_shader_cache.pip_image_layers \
        debug.sf.prime_shader_cache.shadow_layers \
        debug.sf.prime_shader_cache.solid_dimmed_layers \
        debug.sf.prime_shader_cache.solid_layers \
        debug.sf.prime_shader_cache.transparent_image_dimmed_layers; do
        SET_PROP "product" "$PROP" "0"
    done
}

_DISABLE_UNSUPPORTED_MAINLINE_FEATURES()
{
    LOG "- Disabling UFFD GC and RKP paths unsupported by Exynos2100 vendor"
    SET_PROP "product" "ro.dalvik.vm.enable_uffd_gc" "false"
    SET_PROP "product" "persist.device_config.runtime_native_boot.enable_uffd_gc" "false"
    SET_PROP "product" "remote_provisioning.enable_rkpd" "false"
    SET_PROP "product" "remote_provisioning.tee.rkp_only" "0"
    DELETE_FROM_WORK_DIR "system" "system/apex/com.google.android.rkpd_compressed.apex"
    _SED_DELETE_IF_EXISTS "$WORK_DIR/system/system/etc/irremovable_list.txt" "/com\.\(android\|google\.android\)\.rkpd/d"
    _SED_DELETE_IF_EXISTS "$WORK_DIR/system/system/etc/permissions/platform.xml" "/com\.android\.rkpdapp/d"
}

_DISABLE_UNSUPPORTED_BT_OFFLOAD()
{
    LOG "- Disabling Bluetooth audio offload paths unsupported by Exynos2100 vendor"
    SET_PROP "product" "persist.bluetooth.a2dp_offload.disabled" "true"
    SET_PROP "product" "persist.bluetooth.leaudio_offload.disabled" "true"
    SET_PROP "product" "persist.vendor.bt.a2dp_offload.disabled" "true"
    SET_PROP "product" "persist.vendor.bluetooth.a2dp_offload.disabled" "true"
    SET_PROP "product" "ro.bluetooth.leaudio_offload.supported" "false"
    SET_PROP "product" "persist.bluetooth.samsung.a2dp_offload.cap" --delete
    SET_PROP "product" "persist.bluetooth.samsung.a2dp.cap" "SBC,AAC"
    SET_PROP "product" "persist.bluetooth.samsung.leaudio.livecast" "false"
    SET_PROP "product" "media.stagefright.enable-fma2dp" "false"
    SET_PROP "product" "ro.bluetooth.library_name" --delete
    SET_PROP "product" "bluetooth.a2dp.source.sbc_priority.config" "1001"
    SET_PROP "product" "bluetooth.a2dp.source.aac_priority.config" "900000"
    SET_PROP "product" "bluetooth.a2dp.source.aptx_priority.config" "-1"
    SET_PROP "product" "bluetooth.a2dp.source.aptx_hd_priority.config" "-1"
    SET_PROP "product" "bluetooth.a2dp.source.ldac_priority.config" "-1"
    SET_PROP "product" "bluetooth.a2dp.source.opus_priority.config" "-1"
    SET_PROP "product" "bluetooth.a2dp.source.lhdcv5_priority.config" "-1"
    SET_PROP "product" "audio.offload.disable" "1"
    SET_PROP "product" "audio.offload.video" "false"
    SET_PROP "product" "audio.deep_buffer.media" "false"
    SET_PROP "product" "tunnel.audio.encode" "false"
    SET_PROP "product" "media.stagefright.audio.deep" "false"
}

_DISABLE_UNSUPPORTED_OUI9_INIT_WRITES()
{
    LOG "- Removing One UI 9 init writes rejected by the Exynos2100 kernel"
    _SED_DELETE_IF_EXISTS "$WORK_DIR/system/system/etc/init/init.memory.rc" "/\/sys\/kernel\/mm\/transparent_hugepage\/khugepaged\/max_ptes_shared/d"
    _SED_DELETE_IF_EXISTS "$WORK_DIR/system/system/etc/init/atrace.rc" "/\/sys\/kernel\/tracing\/synthetic_events/d"
    _SED_DELETE_IF_EXISTS "$WORK_DIR/system/system/etc/init/hw/init.rc" \
        -e "/\/dev\/blkio\/blkio\.weight/d" \
        -e "/\/dev\/blkio\/background\/blkio\.weight/d" \
        -e "/\/dev\/blkio\/background\/blkio\.bfq\.weight/d" \
        -e "/\/dev\/blkio\/blkio\.group_idle/d" \
        -e "/\/dev\/blkio\/background\/blkio\.group_idle/d" \
        -e "/\/dev\/blkio\/background\/blkio\.prio\.class/d" \
        -e "/\/dev\/blkio\/top\/blkio\.ssg\.boost_on/d" \
        -e "/\/dev\/blkio\/high\/blkio\.ssg\.max_available_ratio/d" \
        -e "/\/dev\/blkio\/normal\/blkio\.ssg\.max_available_ratio/d" \
        -e "/\/dev\/blkio\/low\/blkio\.ssg\.max_available_ratio/d" \
        -e "/\/sys\/class\/sensors\/grip_sensor\/grip_request_firmware/d" \
        -e "/\/dev\/sys\/fs\/by-name\/userdata\/seq_file_ra_mul/d" \
        -e "/\/sys\/class\/power_supply\/battery\/batt_update_data/d"
    _SED_DELETE_IF_EXISTS "$WORK_DIR/system/system/etc/init/init.sec-charger.rc" "/\/sys\/class\/power_supply\/battery\/batt_update_data/d"
    _SED_DELETE_IF_EXISTS "$WORK_DIR/vendor/etc/init/init.exynos2100.rc" \
        -e "/\/dev\/freezer\/frozen\/freezer\.killable/d" \
        -e "/\/dev\/cpuctl\/foreground\/cpu\.rt_runtime_us/d" \
        -e "/\/dev\/cpuctl\/background\/cpu\.rt_runtime_us/d" \
        -e "/\/dev\/cpuctl\/top-app\/cpu\.rt_runtime_us/d" \
        -e "/\/proc\/sys\/net\/core\/netdev_max_backlog/d"
    _SED_DELETE_IF_EXISTS "$WORK_DIR/vendor/etc/init/init.baseband.rc" "/\/proc\/sys\/net\/core\/netdev_max_backlog/d"
    _SED_DELETE_IF_EXISTS "$WORK_DIR/vendor/etc/init/init.nfc.samsung.rc" "/\/sys\/class\/nfc_sec\/pvdd/d"
}

_SET_LOG_TAG_LEVEL()
{
    local TAG="$1"
    local LEVEL="$2"

    SET_PROP "product" "log.tag.$TAG" "$LEVEL"
    SET_PROP "product" "persist.log.tag.$TAG" "$LEVEL"
}

_PATCH_CONST_BEFORE_BOOL_IPUT()
{
    local FILE="$1"
    local FIELD="$2"
    local COUNT

    awk -v FIELD="$FIELD" '
        { line[NR] = $0 }
        END {
            for (i = 1; i <= NR; i++) {
                if (index(line[i], FIELD) && line[i] ~ /iput-boolean/) {
                    for (j = i - 1; j >= 1 && j >= i - 6; j--) {
                        if (line[j] ~ /^[[:space:]]*const\/4 [vp][0-9]+, 0x1$/) {
                            sub(/0x1$/, "0x0", line[j])
                            changed++
                            break
                        }
                    }
                }
            }
            for (i = 1; i <= NR; i++) print line[i]
            if (!changed) exit 2
            print changed > "/dev/stderr"
        }
    ' "$FILE" > "$FILE.tmp" 2> "$FILE.count" && mv "$FILE.tmp" "$FILE" || {
        rm -f "$FILE.tmp" "$FILE.count"
        ABORT "Failed to patch boolean assignment for $FIELD in ${FILE//$SRC_DIR\//}"
    }

    COUNT="$(cat "$FILE.count")"
    rm -f "$FILE.count"
    LOG "- Patched $COUNT boolean assignment(s) for $FIELD"
}

_PATCH_BOOL_METHOD_RETURN()
{
    local FILE="$1"
    local METHOD="$2"
    local VALUE="$3"
    local HEX="0x0"

    [ "$VALUE" = "true" ] && HEX="0x1"

    awk -v METHOD="$METHOD" -v HEX="$HEX" '
        BEGIN { inside = 0; changed = 0 }
        /^\.method/ && index($0, METHOD) {
            print
            print "    .locals 1"
            print ""
            print "    const/4 v0, " HEX
            print ""
            print "    return v0"
            inside = 1
            changed = 1
            next
        }
        inside && /^\.end method/ {
            print
            inside = 0
            next
        }
        inside { next }
        { print }
        END { if (!changed) exit 2 }
    ' "$FILE" > "$FILE.tmp" && mv "$FILE.tmp" "$FILE" || {
        rm -f "$FILE.tmp"
        ABORT "Failed to patch method $METHOD in ${FILE//$SRC_DIR\//}"
    }

    LOG "- Forced $METHOD to return $VALUE"
}

_PATCH_A2DP_LEGACY_CODEC_PRIORITIES()
{
    local SMALI="$1"

    [ -f "$SMALI" ] || ABORT "A2dpCodecConfig.smali not found"

    if grep -q "MonsterROM One UI 9 legacy BT codec guard" "$SMALI"; then
        LOG "- A2DP legacy codec priorities already patched"
        return 0
    fi

    awk '
        {
            print
            if ($0 ~ /iput v1, p0, Lcom\/android\/bluetooth\/a2dp\/A2dpCodecConfig;->mA2dpSourceCodecPrioritySscUhq:I/) {
                print ""
                print "    # MonsterROM One UI 9 legacy BT codec guard"
                print "    const/16 v0, 0x3e9"
                print "    iput v0, p0, Lcom/android/bluetooth/a2dp/A2dpCodecConfig;->mA2dpSourceCodecPrioritySbc:I"
                print ""
                print "    const v0, 0xdbba0"
                print "    iput v0, p0, Lcom/android/bluetooth/a2dp/A2dpCodecConfig;->mA2dpSourceCodecPriorityAac:I"
                print ""
                print "    const/4 v0, -0x1"
                print "    iput v0, p0, Lcom/android/bluetooth/a2dp/A2dpCodecConfig;->mA2dpSourceCodecPriorityAptx:I"
                print "    iput v0, p0, Lcom/android/bluetooth/a2dp/A2dpCodecConfig;->mA2dpSourceCodecPriorityAptxHd:I"
                print "    iput v0, p0, Lcom/android/bluetooth/a2dp/A2dpCodecConfig;->mA2dpSourceCodecPriorityLdac:I"
                print "    iput v0, p0, Lcom/android/bluetooth/a2dp/A2dpCodecConfig;->mA2dpSourceCodecPriorityOpus:I"
                print "    iput v0, p0, Lcom/android/bluetooth/a2dp/A2dpCodecConfig;->mA2dpSourceCodecPriorityLhdcv5:I"
                print "    iput v0, p0, Lcom/android/bluetooth/a2dp/A2dpCodecConfig;->mA2dpSourceCodecPrioritySsc:I"
                print "    iput v0, p0, Lcom/android/bluetooth/a2dp/A2dpCodecConfig;->mA2dpSourceCodecPrioritySscUhq:I"
                patched = 1
            }
        }
        END { if (!patched) exit 2 }
    ' "$SMALI" > "$SMALI.tmp" && mv "$SMALI.tmp" "$SMALI" || {
        rm -f "$SMALI.tmp"
        ABORT "Failed to patch A2DP legacy codec priorities"
    }

    LOG "- Forced A2DP codec priorities to AAC/SBC and disabled LDAC/SSC/aptX"
}

_PATCH_AUDIO_MUTE_AWAIT_CONNECTION_DUPLICATE()
{
    local SMALI
    local COUNT

    LOG "- Making duplicate Bluetooth mute-await requests non-fatal"
    DECODE_APK "system" "system/framework/services.jar" || ABORT "Failed to decode services.jar"

    SMALI="$APKTOOL_DIR/system/framework/services.jar/smali/com/android/server/audio/AudioService.smali"
    [ -f "$SMALI" ] || ABORT "AudioService.smali not found in decoded services.jar"

    if ! grep -q "muteAwaitConnection already in progress" "$SMALI"; then
        LOG "- AudioService duplicate mute-await branch already patched"
        return 0
    fi

    awk '
        BEGIN {
            inside = 0
            skip_throw_branch = 0
            cleanup_catch = 0
            patched = 0
        }
        /^\.method/ && index($0, "muteAwaitConnection([ILandroid/media/AudioDeviceAttributes;J)V") {
            inside = 1
        }
        inside && index($0, "new-instance p0, Ljava/lang/IllegalStateException;") {
            print "    monitor-exit v1"
            print "    :try_end_1"
            print "    .catchall {:try_start_1 .. :try_end_1} :catchall_0"
            print ""
            print "    return-void"
            print ""
            skip_throw_branch = 1
            patched = 1
            next
        }
        inside && skip_throw_branch {
            if ($0 ~ /^[[:space:]]*:goto_0/) {
                print
                skip_throw_branch = 0
                cleanup_catch = 1
            }
            next
        }
        inside && cleanup_catch && ($0 ~ /^[[:space:]]*:try_end_1$/ || index($0, ".catchall {:try_start_1 .. :try_end_1} :catchall_0")) {
            next
        }
        inside && /^\.end method/ {
            inside = 0
            cleanup_catch = 0
        }
        { print }
        END {
            if (!patched) exit 2
            print patched > "/dev/stderr"
        }
    ' "$SMALI" > "$SMALI.tmp" 2> "$SMALI.count" && mv "$SMALI.tmp" "$SMALI" || {
        rm -f "$SMALI.tmp" "$SMALI.count"
        ABORT "Failed to patch AudioService duplicate mute-await branch"
    }

    COUNT="$(cat "$SMALI.count")"
    rm -f "$SMALI.count"
    LOG "- Patched $COUNT AudioService duplicate mute-await branch"
}

_APEX_PAYLOAD_COPY_OUT()
{
    local PAYLOAD="$1"
    local SRC="$2"
    local DST="$3"

    if command -v e2cp > /dev/null 2>&1; then
        EVAL "e2cp \"$PAYLOAD:$SRC\" \"$DST\""
    elif command -v debugfs > /dev/null 2>&1; then
        EVAL "debugfs -R \"dump -p $SRC $DST\" \"$PAYLOAD\""
    else
        ABORT "Neither e2cp nor debugfs is available to unpack APEX image"
    fi
}

_APEX_PAYLOAD_COPY_IN()
{
    local SRC="$1"
    local PAYLOAD="$2"
    local DST="$3"

    if command -v e2cp > /dev/null 2>&1 && command -v e2rm > /dev/null 2>&1; then
        EVAL "e2rm \"$PAYLOAD:$DST\""
        EVAL "e2cp \"$SRC\" \"$PAYLOAD:$DST\""
    elif command -v debugfs > /dev/null 2>&1; then
        debugfs -w -R "rm $DST" "$PAYLOAD" >/dev/null 2>&1 || true
        EVAL "debugfs -w -R \"write $SRC $DST\" \"$PAYLOAD\""
    else
        ABORT "Neither e2cp/e2rm nor debugfs is available to update APEX image"
    fi
}

_PATCH_BEACONMANAGER_LOCATION_PERMISSIONS()
{
    local BEACON_APK="system/priv-app/BeaconManager/BeaconManager.apk"
    local BEACON_DECODED="$APKTOOL_DIR/system/${BEACON_APK//system\/}"
    local MANIFEST="$BEACON_DECODED/AndroidManifest.xml"
    local PERM

    [ -f "$WORK_DIR/system/$BEACON_APK" ] || return 0

    LOG_STEP_IN "- Adding BeaconManager BLE location permissions"
    DECODE_APK "system" "$BEACON_APK" || ABORT "Failed to decode BeaconManager.apk"

    [ -f "$MANIFEST" ] || ABORT "Decoded BeaconManager manifest not found"

    for PERM in \
        android.permission.ACCESS_COARSE_LOCATION \
        android.permission.ACCESS_FINE_LOCATION \
        android.permission.ACCESS_BACKGROUND_LOCATION; do
        if ! grep -q "android:name=\"$PERM\"" "$MANIFEST"; then
            sed -i "0,/^[[:space:]]*<application/{s#^[[:space:]]*<application#    <uses-permission android:name=\"$PERM\" />\\n\\n    <application#}" "$MANIFEST"
            LOG "- Added $PERM"
        fi
    done

    LOG_STEP_OUT
}

ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/etc/selinux/mapping/29.0.cil" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/etc/selinux/mapping/29.0.compat.cil" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/etc/selinux/mapping/30.0.cil" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/etc/selinux/mapping/30.0.compat.cil" 0 0 644 "u:object_r:system_file:s0"

ADD_TO_WORK_DIR "platform/exynos2100/patches/miscs" "vendor" "etc/ueventd.rc" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "platform/exynos2100/patches/miscs" "vendor" "ueventd.rc" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "platform/exynos2100/patches/miscs" "vendor" "etc/bluetooth_audio_policy_configuration.xml" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "platform/exynos2100/patches/miscs" "vendor" "etc/init/android.hardware.sensors@2.0-service-multihal.rc" 0 0 644 "u:object_r:vendor_configs_file:s0"
ADD_TO_WORK_DIR "platform/exynos2100/patches/miscs" "vendor" "bin/monsterrom_wait_sensors_ready.sh" 0 2000 755 "u:object_r:vendor_file:s0"
ADD_TO_WORK_DIR "platform/exynos2100/patches/miscs" "system" "system/etc/default-permissions/default-permissions-com.samsung.android.beaconmanager.xml" 0 0 644 "u:object_r:system_file:s0"
