# Pixel 6 Android 15 QPR1 Beta 1 is the last official G78/Job Manager image
# carrying the exact r49p0 userspace release. Extract only vendor.img from the
# immutable factory ZIP, then pin every installed file by digest.
MALI_R49_FACTORY_URL="https://dl.google.com/developers/android/vic/images/factory/oriole_beta-ap41.240726.009-factory-05406aad.zip"
MALI_R49_FACTORY_VENDOR_RANGE="594610965-858370220"
MALI_R49_FACTORY_VENDOR_COMPRESSED_SIZE="263759256"
MALI_R49_FACTORY_VENDOR_SIZE="595206144"
MALI_R49_FACTORY_VENDOR_SHA256="4f1269dd6921bc8e3cbda24a223cefa755d7167a0d728411e328e1e69b3eebe5"
MALI_R49_CACHE_DIR="$SRC_DIR/out/gpu-cache/oriole-ap41.240726.009-r49p0"
MALI_R49_LOCAL_DONOR_DIR="$SRC_DIR/out/gpu-donors/pixel-oriole-r49p0-ap41"

# relative destination|sha256|SELinux label
MALI_R49_DRIVER_FILES=(
    "vendor/lib/egl/libGLES_mali.so|0875f4194d1bb04f612b5c41afd77b7faa0ba3a92853b95b2d927266a4f73a97|u:object_r:same_process_hal_file:s0"
    "vendor/lib64/egl/libGLES_mali.so|650814353861e1916981034f65dc3fed39eba8e846d8404f8946aafa44d8ad0b|u:object_r:same_process_hal_file:s0"
    "vendor/lib/hw/vulkan.mali.so|37cdd47abeb440fb6431f2bb6edcf497f08820844f11590ee54c08d97bec0ecb|u:object_r:vendor_file:s0"
    "vendor/lib64/hw/vulkan.mali.so|1f53d8bc7fe7eff0ebf4c005d2938c97cddeebc874a54cdc0d31f162bef1e155|u:object_r:vendor_file:s0"
)

# relative destination|sha256|ELF class|SELinux label
MALI_R49_RUNTIME_FILES=(
    "vendor/lib/android.hardware.common-V2-ndk.so|5e2ba5b94f88c0d605c48f1285b00a8b9153479c6586dedef10ba98837a9f5a7|ELF32|u:object_r:same_process_hal_file:s0"
    "vendor/lib/android.hardware.graphics.allocator-V2-ndk.so|f1522a3bc820966e1552e0aad5ba44776b627c4a8ef2513e913e53db75f7faf3|ELF32|u:object_r:same_process_hal_file:s0"
    "vendor/lib/android.hardware.graphics.common-V5-ndk.so|bb8d455fbbfe50118d5277702d097ded7e1160be9911e3f96bd0026ba3983318|ELF32|u:object_r:same_process_hal_file:s0"
    "vendor/lib/libdmabufheap.so|f52ce6cededbed04d68a5aa2683805bb6ab7a1e4a9a77bdba6ca5c7d75f2e124|ELF32|u:object_r:same_process_hal_file:s0"
    "vendor/lib/libdrm.so|27f1f456344a4366967123384c5a2b7ac44115aef6b655da34e87f3a6cd2babf|ELF32|u:object_r:same_process_hal_file:s0"
    "vendor/lib64/android.hardware.common-V2-ndk.so|49522b6082eb8a6e46a03d0f061e6ccc88a0a3ab4399ecbb4b5768448da41585|ELF64|u:object_r:same_process_hal_file:s0"
    "vendor/lib64/android.hardware.graphics.allocator-V2-ndk.so|ebb6121276aea9830ced81878a60d4cde37886d26f39239cf93a807ec7b44204|ELF64|u:object_r:same_process_hal_file:s0"
    "vendor/lib64/android.hardware.graphics.common-V5-ndk.so|021114549e807febccb38eba361164e806284f19ca2f5f07c54afb763f20c886|ELF64|u:object_r:same_process_hal_file:s0"
    "vendor/lib64/libdmabufheap.so|f78818076768143ce5d1ecc5e50ee0f2c8650d22be957719d8e3a1f3af0a7783|ELF64|u:object_r:same_process_hal_file:s0"
    "vendor/lib64/libdrm.so|234e1f719354f75ab89addaa47a123e9bf63c375df065882fe85bd1ba215f356|ELF64|u:object_r:same_process_hal_file:s0"
)

_T2S_MALI_VERIFY_R49_SOURCE()
{
    local SOURCE="$1"
    local ENTRY REL EXPECTED CLASS LABEL

    for ENTRY in "${MALI_R49_DRIVER_FILES[@]}"; do
        IFS="|" read -r REL EXPECTED LABEL <<< "$ENTRY"
        _T2S_MALI_FILE_MATCHES "$SOURCE/$REL" "$EXPECTED" || return 1
    done
    for ENTRY in "${MALI_R49_RUNTIME_FILES[@]}"; do
        IFS="|" read -r REL EXPECTED CLASS LABEL <<< "$ENTRY"
        _T2S_MALI_FILE_MATCHES "$SOURCE/$REL" "$EXPECTED" || return 1
    done
}

_T2S_MALI_FETCH_R49()
{
    local PAYLOAD="$MALI_R49_CACHE_DIR/vendor.img.deflate.download"
    local IMAGE="$MALI_R49_CACHE_DIR/vendor.img.download"
    local ENTRY REL EXPECTED CLASS LABEL OUTPUT TEMP TOOL

    _T2S_MALI_VERIFY_R49_SOURCE "$MALI_R49_CACHE_DIR" && return 0

    for TOOL in curl debugfs python3 stat; do
        command -v "$TOOL" >/dev/null || \
            ABORT "Required Pixel r49 factory extraction tool is missing: $TOOL"
    done

    mkdir -p "$MALI_R49_CACHE_DIR"
    rm -f "$PAYLOAD" "$IMAGE"
    LOG "- Range-downloading Pixel 6 AP41.240726.009 vendor.img"
    if ! curl --fail --location --retry 3 --retry-delay 2 \
            --max-filesize "$MALI_R49_FACTORY_VENDOR_COMPRESSED_SIZE" \
            --range "$MALI_R49_FACTORY_VENDOR_RANGE" \
            --output "$PAYLOAD" "$MALI_R49_FACTORY_URL"; then
        rm -f "$PAYLOAD" "$IMAGE"
        ABORT "Failed to download the pinned Pixel r49 vendor.img range"
    fi
    if [ "$(stat -c '%s' "$PAYLOAD")" != "$MALI_R49_FACTORY_VENDOR_COMPRESSED_SIZE" ]; then
        rm -f "$PAYLOAD" "$IMAGE"
        ABORT "Pixel r49 vendor.img compressed range has an unexpected size"
    fi

    LOG "- Inflating and verifying the pinned Pixel r49 vendor.img"
    if python3 - "$PAYLOAD" "$IMAGE" <<'PY'
import sys
import zlib

source, target = sys.argv[1:]
decoder = zlib.decompressobj(-zlib.MAX_WBITS)
with open(source, "rb") as src, open(target, "wb") as dst:
    while chunk := src.read(8 * 1024 * 1024):
        dst.write(decoder.decompress(chunk))
    dst.write(decoder.flush())
if not decoder.eof or decoder.unused_data or decoder.unconsumed_tail:
    raise SystemExit("incomplete or trailing raw DEFLATE stream")
PY
    then
        :
    else
        rm -f "$PAYLOAD" "$IMAGE"
        ABORT "Failed to inflate the pinned Pixel r49 vendor.img"
    fi
    rm -f "$PAYLOAD"
    if [ "$(stat -c '%s' "$IMAGE")" != "$MALI_R49_FACTORY_VENDOR_SIZE" ] || \
            ! _T2S_MALI_FILE_MATCHES "$IMAGE" "$MALI_R49_FACTORY_VENDOR_SHA256"; then
        rm -f "$IMAGE"
        ABORT "Pixel r49 vendor.img checksum or size mismatch"
    fi

    for ENTRY in "${MALI_R49_DRIVER_FILES[@]}" "${MALI_R49_RUNTIME_FILES[@]}"; do
        IFS="|" read -r REL EXPECTED CLASS LABEL <<< "$ENTRY"
        OUTPUT="$MALI_R49_CACHE_DIR/$REL"
        TEMP="$OUTPUT.download"
        mkdir -p "$(dirname "$OUTPUT")"
        rm -f "$TEMP"
        if ! debugfs -R "dump /${REL#vendor/} $TEMP" "$IMAGE" >/dev/null 2>&1; then
            rm -f "$TEMP" "$IMAGE"
            ABORT "Failed to extract $REL from the pinned Pixel r49 vendor.img"
        fi
        _T2S_MALI_FILE_MATCHES "$TEMP" "$EXPECTED" || {
            rm -f "$TEMP" "$IMAGE"
            ABORT "Pixel r49 factory checksum mismatch: $REL"
        }
        mv -f "$TEMP" "$OUTPUT"
    done
    rm -f "$IMAGE"

    _T2S_MALI_VERIFY_R49_SOURCE "$MALI_R49_CACHE_DIR" || \
        ABORT "Extracted Pixel r49 userspace failed checksum validation"
}

_T2S_MALI_VERIFY_R49_ABI()
{
    local LIBDIR UMD VULKAN CLASS DEP FILE SONAME

    if ! grep -qF '<name>android.hardware.graphics.allocator</name>' \
            "$WORK_DIR/vendor/etc/vintf/manifest.xml" || \
            ! grep -qF '@4.0::IAllocator/default' \
            "$WORK_DIR/vendor/etc/vintf/manifest.xml"; then
        ABORT "Target HIDL graphics allocator 4.0 service is not declared"
    fi

    for LIBDIR in lib lib64; do
        UMD="$MALI_R49_SOURCE_DIR/vendor/$LIBDIR/egl/libGLES_mali.so"
        VULKAN="$MALI_R49_SOURCE_DIR/vendor/$LIBDIR/hw/vulkan.mali.so"
        [ "$LIBDIR" = "lib" ] && CLASS="ELF32" || CLASS="ELF64"

        readelf -h "$UMD" | grep "Class:.*$CLASS" >/dev/null || \
            ABORT "Mali r49 $LIBDIR UMD has the wrong ELF class"
        strings "$UMD" | grep -F 'r49p0-00eac0' >/dev/null || \
            ABORT "Mali r49 $LIBDIR UMD has the wrong release"
        strings "$UMD" | grep -F 'Mali-G78' >/dev/null || \
            ABORT "Mali r49 $LIBDIR UMD does not advertise Mali-G78 support"
        for DEP in \
            android.hardware.graphics.allocator-V2-ndk.so \
            android.hardware.graphics.common-V5-ndk.so \
            libdrm.so libdmabufheap.so libvndksupport.so; do
            readelf -d "$UMD" | grep -F "[$DEP]" >/dev/null || \
                ABORT "Mali r49 $LIBDIR UMD lacks dependency: $DEP"
        done
        readelf --dyn-syms --wide "$UMD" | grep ' AServiceManager_checkService@' >/dev/null || \
            ABORT "Mali r49 $LIBDIR UMD lacks the optional AIDL allocator probe"
        readelf --dyn-syms --wide "$UMD" | grep 'IMapper10getService' >/dev/null || \
            ABORT "Mali r49 $LIBDIR UMD lacks the HIDL Mapper 4 fallback"
        readelf --dyn-syms --wide "$UMD" | grep ' eglGetDisplay$' >/dev/null || \
            ABORT "Mali r49 $LIBDIR UMD lacks EGL exports"
        readelf --dyn-syms --wide "$UMD" | grep ' glGetString$' >/dev/null || \
            ABORT "Mali r49 $LIBDIR UMD lacks GLES exports"

        readelf -h "$VULKAN" | grep "Class:.*$CLASS" >/dev/null || \
            ABORT "Mali r49 $LIBDIR Vulkan shim has the wrong ELF class"
        readelf -d "$VULKAN" | grep -F '[libGLES_mali.so]' >/dev/null || \
            ABORT "Mali r49 $LIBDIR Vulkan shim is not paired with libGLES_mali"
        readelf -d "$VULKAN" | grep -F 'Library runpath: [$ORIGIN/../egl]' >/dev/null || \
            ABORT "Mali r49 $LIBDIR Vulkan shim has an unexpected runpath"

        for FILE in \
            android.hardware.common-V2-ndk.so \
            android.hardware.graphics.allocator-V2-ndk.so \
            android.hardware.graphics.common-V5-ndk.so \
            libdmabufheap.so libdrm.so; do
            readelf -h "$MALI_R49_SOURCE_DIR/vendor/$LIBDIR/$FILE" | \
                grep "Class:.*$CLASS" >/dev/null || \
                ABORT "Pixel r49 $LIBDIR/$FILE has the wrong ELF class"
            SONAME="$(readelf -d "$MALI_R49_SOURCE_DIR/vendor/$LIBDIR/$FILE" | \
                sed -n 's/.*Library soname: \[\(.*\)\]/\1/p')"
            [ "$SONAME" = "$FILE" ] || \
                ABORT "Pixel r49 $LIBDIR/$FILE has the wrong SONAME"
        done

        for DEP in \
            libbinder_ndk.so libnativewindow.so libutils.so \
            android.hardware.graphics.mapper@4.0.so liblog.so \
            libgralloctypes.so libhidlbase.so libvndksupport.so \
            libcutils.so libhardware.so libbase.so libz.so \
            libc++.so libc.so libm.so libdl.so; do
            if [ ! -e "$WORK_DIR/vendor/$LIBDIR/$DEP" ] && \
                    [ ! -L "$WORK_DIR/vendor/$LIBDIR/$DEP" ] && \
                    [ ! -e "$WORK_DIR/system/system/$LIBDIR/$DEP" ] && \
                    [ ! -L "$WORK_DIR/system/system/$LIBDIR/$DEP" ]; then
                ABORT "Target $LIBDIR runtime lacks Mali r49 dependency: $DEP"
            fi
        done

        readelf -d "$MALI_R49_SOURCE_DIR/vendor/$LIBDIR/android.hardware.graphics.allocator-V2-ndk.so" | \
            grep -F '[android.hardware.graphics.common-V5-ndk.so]' >/dev/null || \
            ABORT "Pixel r49 $LIBDIR allocator dependency closure is incomplete"
        readelf -d "$MALI_R49_SOURCE_DIR/vendor/$LIBDIR/android.hardware.graphics.common-V5-ndk.so" | \
            grep -F '[android.hardware.common-V2-ndk.so]' >/dev/null || \
            ABORT "Pixel r49 $LIBDIR graphics-common dependency closure is incomplete"
    done
}

_T2S_MALI_VERIFY_R49_INSTALLED_CLOSURE()
{
    local LIBDIR FILE DEP ENTRY REL EXPECTED CLASS LABEL CONTEXT_PATH
    local -a FILES

    for ENTRY in "${MALI_R49_DRIVER_FILES[@]}"; do
        IFS="|" read -r REL EXPECTED LABEL <<< "$ENTRY"
        _T2S_MALI_FILE_MATCHES "$WORK_DIR/$REL" "$EXPECTED" || \
            ABORT "Installed Mali r49 file differs from its pinned source: $REL"
        grep -qxF "$REL 0 0 644 capabilities=0x0" \
            "$WORK_DIR/configs/fs_config-vendor" || \
            ABORT "Installed $REL has incorrect filesystem metadata"
        CONTEXT_PATH="/${REL//./\\.} $LABEL"
        grep -qxF "$CONTEXT_PATH" "$WORK_DIR/configs/file_context-vendor" || \
            ABORT "Installed $REL has the wrong SELinux label"
    done
    for ENTRY in "${MALI_R49_RUNTIME_FILES[@]}"; do
        IFS="|" read -r REL EXPECTED CLASS LABEL <<< "$ENTRY"
        _T2S_MALI_FILE_MATCHES "$WORK_DIR/$REL" "$EXPECTED" || \
            ABORT "Installed Pixel r49 runtime differs from its pinned source: $REL"
        grep -qxF "$REL 0 0 644 capabilities=0x0" \
            "$WORK_DIR/configs/fs_config-vendor" || \
            ABORT "Installed $REL has incorrect filesystem metadata"
        CONTEXT_PATH="/${REL//./\\.} $LABEL"
        grep -qxF "$CONTEXT_PATH" "$WORK_DIR/configs/file_context-vendor" || \
            ABORT "Installed $REL is not labeled as an SP-HAL library"
    done

    for LIBDIR in lib lib64; do
        FILES=(
            "$WORK_DIR/vendor/$LIBDIR/egl/libGLES_mali.so"
            "$WORK_DIR/vendor/$LIBDIR/hw/vulkan.mali.so"
            "$WORK_DIR/vendor/$LIBDIR/android.hardware.common-V2-ndk.so"
            "$WORK_DIR/vendor/$LIBDIR/android.hardware.graphics.allocator-V2-ndk.so"
            "$WORK_DIR/vendor/$LIBDIR/android.hardware.graphics.common-V5-ndk.so"
            "$WORK_DIR/vendor/$LIBDIR/libdmabufheap.so"
            "$WORK_DIR/vendor/$LIBDIR/libdrm.so"
        )
        for FILE in "${FILES[@]}"; do
            [ -f "$FILE" ] || \
                ABORT "Installed Mali r49 closure file is missing: ${FILE//$WORK_DIR\//}"
            while IFS= read -r DEP; do
                case "$DEP" in
                    libGLES_mali.so)
                        [ -f "$WORK_DIR/vendor/$LIBDIR/egl/$DEP" ] || \
                            ABORT "Mali r49 $LIBDIR Vulkan dependency is unresolved: $DEP"
                        ;;
                    libdrm.so|libdmabufheap.so|android.hardware.common-V2-ndk.so|\
                    android.hardware.graphics.allocator-V2-ndk.so|\
                    android.hardware.graphics.common-V5-ndk.so)
                        [ -f "$WORK_DIR/vendor/$LIBDIR/$DEP" ] || \
                            ABORT "Mali r49 $LIBDIR SP-HAL dependency is not vendor-visible: $DEP"
                        ;;
                    *)
                        if [ ! -e "$WORK_DIR/vendor/$LIBDIR/$DEP" ] && \
                                [ ! -L "$WORK_DIR/vendor/$LIBDIR/$DEP" ] && \
                                [ ! -e "$WORK_DIR/system/system/$LIBDIR/$DEP" ] && \
                                [ ! -L "$WORK_DIR/system/system/$LIBDIR/$DEP" ]; then
                            ABORT "Mali r49 $LIBDIR dependency is unresolved: $DEP"
                        fi
                        ;;
                esac
            done < <(readelf -d "$FILE" | \
                sed -n 's/.*Shared library: \[\(.*\)\]/\1/p' | LC_ALL=C sort -u)
        done
    done
}

LOG_STEP_IN "- Preparing Pixel 6 Mali r49p0 userspace-only backport"
if [ -n "${T2S_MALI_R49P0_DONOR_DIR:-}" ]; then
    MALI_R49_SOURCE_DIR="$T2S_MALI_R49P0_DONOR_DIR"
elif [ -d "$MALI_R49_LOCAL_DONOR_DIR" ] && \
        _T2S_MALI_VERIFY_R49_SOURCE "$MALI_R49_LOCAL_DONOR_DIR"; then
    MALI_R49_SOURCE_DIR="$MALI_R49_LOCAL_DONOR_DIR"
else
    _T2S_MALI_FETCH_R49
    MALI_R49_SOURCE_DIR="$MALI_R49_CACHE_DIR"
fi
_T2S_MALI_VERIFY_R49_SOURCE "$MALI_R49_SOURCE_DIR" || \
    ABORT "Mali r49 donor is incomplete or does not match pinned checksums"
LOG "- UMD donor: Pixel 6 AP41.240726.009 factory vendor image"
LOG "- Kernel remains selected independently as $T2S_MALI_DDK"
LOG_STEP_OUT

LOG_STEP_IN "- Validating Mali r49p0 G78/HIDL/SP-HAL compatibility"
_T2S_MALI_VERIFY_R49_ABI
LOG "- AIDL allocator is optional; target HIDL Mapper 4 fallback is present"
LOG_STEP_OUT

LOG_STEP_IN "- Installing Mali r49p0 userspace with its pinned runtime closure"
for ENTRY in "${MALI_R49_RUNTIME_FILES[@]}"; do
    IFS="|" read -r REL EXPECTED CLASS LABEL <<< "$ENTRY"
    ADD_TO_WORK_DIR "$MALI_R49_SOURCE_DIR" "vendor" "${REL#vendor/}" 0 0 644 "$LABEL"
    SET_METADATA "vendor" "${REL#vendor/}" 0 0 644 "$LABEL"
done
for ENTRY in "${MALI_R49_DRIVER_FILES[@]}"; do
    IFS="|" read -r REL EXPECTED LABEL <<< "$ENTRY"
    ADD_TO_WORK_DIR "$MALI_R49_SOURCE_DIR" "vendor" "${REL#vendor/}" 0 0 644 "$LABEL"
    # A donor swap must replace stale metadata instead of inheriting it.
    SET_METADATA "vendor" "${REL#vendor/}" 0 0 644 "$LABEL"
done
ADD_TO_WORK_DIR "$MODPATH" "vendor" \
    "etc/permissions/android.hardware.vulkan.version.xml" \
    0 0 644 "u:object_r:vendor_configs_file:s0"
LOG_STEP_OUT

LOG_STEP_IN "- Verifying installed Mali r49p0 vendor/SP-HAL closure"
_T2S_MALI_VERIFY_R49_INSTALLED_CLOSURE
LOG_STEP_OUT

unset T2S_MALI_R49P0_DONOR_DIR
unset MALI_R49_FACTORY_URL MALI_R49_FACTORY_VENDOR_RANGE
unset MALI_R49_FACTORY_VENDOR_COMPRESSED_SIZE MALI_R49_FACTORY_VENDOR_SIZE
unset MALI_R49_FACTORY_VENDOR_SHA256 MALI_R49_CACHE_DIR
unset MALI_R49_LOCAL_DONOR_DIR MALI_R49_SOURCE_DIR
unset MALI_R49_DRIVER_FILES MALI_R49_RUNTIME_FILES
unset -f _T2S_MALI_VERIFY_R49_SOURCE _T2S_MALI_FETCH_R49
unset -f _T2S_MALI_VERIFY_R49_ABI _T2S_MALI_VERIFY_R49_INSTALLED_CLOSURE
