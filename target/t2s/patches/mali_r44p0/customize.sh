SKIPUNZIP=1

T2S_MALI_DDK="${T2S_MALI_DDK:-r44p0}"
case "$T2S_MALI_DDK" in
    r38p1|r44p0) ;;
    *) ABORT "T2S_MALI_DDK must be r38p1 or r44p0" ;;
esac

MALI_KERNEL_MANIFEST="$SRC_DIR/out/kernel-builds/latest-mali-ddk.txt"

MALI_R44_REPOSITORY="ProjectEverest-Devices/proprietary_vendor_google_oriole"
MALI_R44_COMMIT="f1cd31f58c37e4e4f6e9129806f02dcbb13e664c"
MALI_R44_BASE_URL="https://raw.githubusercontent.com/$MALI_R44_REPOSITORY/$MALI_R44_COMMIT/proprietary"
MALI_R44_CACHE_DIR="$SRC_DIR/out/gpu-cache/oriole-r44p0-$MALI_R44_COMMIT"
MALI_R44_LOCAL_DONOR_DIR="$SRC_DIR/out/gpu-donors/pixel-oriole-r44p0/proprietary"

# libdrm is not part of Google's VNDK v34 prebuilts or the proprietary-only
# donor tree above. Fetch the exact vendor copies from the same Pixel factory
# build as the r44 UMD, using the immutable ZIP byte range for vendor.img.
MALI_R44_FACTORY_URL="https://dl.google.com/dl/android/aosp/oriole-uq1a.231205.015-factory-6a8ae3fb.zip"
MALI_R44_FACTORY_VENDOR_RANGE="596402833-903438321"
MALI_R44_FACTORY_VENDOR_COMPRESSED_SIZE="307035489"
MALI_R44_FACTORY_VENDOR_SIZE="690286592"
MALI_R44_FACTORY_VENDOR_SHA256="a6749722b4064f3c9567db02425184d5b428d3b8d97741d2c1b3dfcd728ea208"
MALI_R44_LIBDRM_CACHE_DIR="$SRC_DIR/out/gpu-cache/oriole-uq1a.231205.015-libdrm"

MALI_V34_COMMIT="912e0c51bc2557a8d4b396bad1b6e39fe4c0b358"
MALI_V34_BASE_URL="https://android.googlesource.com/platform/prebuilts/vndk/v34/+/$MALI_V34_COMMIT"
MALI_V34_CACHE_DIR="$SRC_DIR/out/gpu-cache/aosp-vndk-v34-$MALI_V34_COMMIT"

MALI_R38_REPOSITORY="RandomPush/samsung_a54x_dump"
MALI_R38_COMMIT="a205e1ffdd8f483b30fc8100bd9eb13944462e62"
MALI_R38_BASE_URL="https://raw.githubusercontent.com/$MALI_R38_REPOSITORY/$MALI_R38_COMMIT"
MALI_R38_CACHE_DIR="$SRC_DIR/out/gpu-cache/a54x-r38p1-$MALI_R38_COMMIT"
MALI_R38_LOCAL_DONOR_DIR="$SRC_DIR/out/gpu-donors/a54x-dump"

# relative destination|sha256|SELinux label
MALI_R44_DRIVER_FILES=(
    "vendor/lib/egl/libGLES_mali.so|1786f9c21e0975729a1325e8e15539d3ec59d6e06e931b1cd62d9496bf24a06a|u:object_r:same_process_hal_file:s0"
    "vendor/lib64/egl/libGLES_mali.so|da9b2e32c4d0425ee4f7614719145b293e79490a6d290e2c2105e7d309ff2ccc|u:object_r:same_process_hal_file:s0"
    "vendor/lib/hw/vulkan.mali.so|1a71ce74073b2294aa00b7f1a8cc9965dfa32a752de34293b1301bb6c130693e|u:object_r:vendor_file:s0"
    "vendor/lib64/hw/vulkan.mali.so|e71815f64d53d41ecd20da2c5b72709fcc79ebbd3a851f0a617535aa652aadf1|u:object_r:vendor_file:s0"
)

# relative destination|Gitiles source path|sha256|SELinux label
MALI_V34_FILES=(
    "vendor/lib/android.hardware.common-V2-ndk.so|arm/arch-arm-armv7-a-neon/shared/vndk-sp/android.hardware.common-V2-ndk.so|02243a813fe37e8cd9eef809aaf2cc24c58a8fa0402b238d741257b80dc08079|u:object_r:same_process_hal_file:s0"
    "vendor/lib/android.hardware.graphics.allocator-V2-ndk.so|arm/arch-arm-armv7-a-neon/shared/vndk-sp/android.hardware.graphics.allocator-V2-ndk.so|f487ce4f109e11a70f3180d71f8f39c1db078226eb0f9f26ebe17adce1533ad1|u:object_r:same_process_hal_file:s0"
    "vendor/lib/android.hardware.graphics.common-V4-ndk.so|arm/arch-arm-armv7-a-neon/shared/vndk-sp/android.hardware.graphics.common-V4-ndk.so|69f3439bab452a8a658253782c8bab1ac892e3745057ccb2d0d02ca80dedc9a9|u:object_r:same_process_hal_file:s0"
    "vendor/lib64/android.hardware.common-V2-ndk.so|arm64/arch-arm64-armv8-a/shared/vndk-sp/android.hardware.common-V2-ndk.so|4d3c49c51b5081fd02a95a4b00b6d2ed9fadc757063422ea356add330fc5d034|u:object_r:same_process_hal_file:s0"
    "vendor/lib64/android.hardware.graphics.allocator-V2-ndk.so|arm64/arch-arm64-armv8-a/shared/vndk-sp/android.hardware.graphics.allocator-V2-ndk.so|05636a80e1879926b5d4f5c4fce1b9690e25282bfdcf1e25b6ff60e5a7bf4d7c|u:object_r:same_process_hal_file:s0"
    "vendor/lib64/android.hardware.graphics.common-V4-ndk.so|arm64/arch-arm64-armv8-a/shared/vndk-sp/android.hardware.graphics.common-V4-ndk.so|88f2e1c821254168cac99b100b81dd01f35e561b02cfb412d5cc054274368da3|u:object_r:same_process_hal_file:s0"
    "vendor/lib/libdmabufheap.so|arm/arch-arm-armv7-a-neon/shared/vndk-sp/libdmabufheap.so|42a6142fbf9b0b7f6d16a4afc92c90f8c8f80aa7de7ad241aaace424ca040324|u:object_r:same_process_hal_file:s0"
    "vendor/lib64/libdmabufheap.so|arm64/arch-arm64-armv8-a/shared/vndk-sp/libdmabufheap.so|d54b562d43075c3d0e4622b17151ad51343525e97d086ee01ed0265a7449dca0|u:object_r:same_process_hal_file:s0"
)

# relative destination|sha256|ELF class|SELinux label
MALI_R44_LIBDRM_FILES=(
    "vendor/lib/libdrm.so|5ab80073d1c49bb087b27be80a51de76e5e07534f58057bb9f344328bb6d1e84|ELF32|u:object_r:same_process_hal_file:s0"
    "vendor/lib64/libdrm.so|451d94afe1a6f1b603e8e26af7629b7c6a2f5e03e910d0a906e57fd73682a815|ELF64|u:object_r:same_process_hal_file:s0"
)

MALI_R38_DRIVER_FILES=(
    "vendor/lib/egl/libGLES_mali.so|2d17d55694b70f5e63023bcc1e89f17077f95f05a008b87b1547452b54d464fe|u:object_r:same_process_hal_file:s0"
    "vendor/lib64/egl/libGLES_mali.so|11b09aed6a1504ff5e49f3f12f4ebef18786ae31ca53af4383c8eadb93a30d1d|u:object_r:same_process_hal_file:s0"
    "vendor/lib/hw/vulkan.mali.so|71410b2c08b5064c1106a87e548764c8c5f0c25d90aec763d40801664dc7a777|u:object_r:vendor_file:s0"
    "vendor/lib64/hw/vulkan.mali.so|95275e8ff53d469e7b102bc1d3e0269ff643ab6519030b4cac59821b83ef4d82|u:object_r:vendor_file:s0"
    "vendor/lib/mali_symlink.so|049aeccad548f29d1f4a9b246951c69d4a4be6d7d3bc5a4a9e688d194346259b|u:object_r:vendor_file:s0"
    "vendor/lib64/mali_symlink.so|9d42468ca6bcc2744ce65424d30a4ae529b403ddc2aa19680aa9ee8c73234ece|u:object_r:vendor_file:s0"
)

_T2S_MALI_FILE_MATCHES()
{
    local FILE="$1"
    local EXPECTED="$2"

    [ -f "$FILE" ] && [ "$(sha256sum "$FILE" | cut -d ' ' -f 1)" = "$EXPECTED" ]
}

_T2S_MALI_MANIFEST_VALUE()
{
    sed -n "s/^$1=//p" "$MALI_KERNEL_MANIFEST" | tail -n 1
}

_T2S_MALI_VERIFY_KERNEL_PAIRING()
{
    local EXPECTED_RELEASE EXPECTED_ABI EXPECTED_DONOR
    local BOOT_HASH VENDOR_BOOT_HASH

    [ -s "$MALI_KERNEL_MANIFEST" ] || \
        ABORT "Mali kernel build manifest is missing; build FloppyKernel before installing its userspace"
    [ "$(_T2S_MALI_MANIFEST_VALUE target)" = "t2s" ] || \
        ABORT "Mali kernel manifest belongs to a different target"
    [ "$(_T2S_MALI_MANIFEST_VALUE selector)" = "$T2S_MALI_DDK" ] || \
        ABORT "Mali kernel/userspace selector mismatch"

    case "$T2S_MALI_DDK" in
        r44p0)
            EXPECTED_RELEASE="r44p0-01eac0"
            EXPECTED_ABI="11.39"
            EXPECTED_DONOR="ed39d840e85ab23495efb36001d0cd792862c5c6"
            ;;
        r38p1)
            EXPECTED_RELEASE="r38p1-01eac0"
            EXPECTED_ABI="11.35"
            EXPECTED_DONOR="floppy"
            ;;
    esac
    [ "$(_T2S_MALI_MANIFEST_VALUE ddk)" = "$EXPECTED_RELEASE" ] || \
        ABORT "Mali kernel release does not match $EXPECTED_RELEASE"
    [ "$(_T2S_MALI_MANIFEST_VALUE uk_abi)" = "$EXPECTED_ABI" ] || \
        ABORT "Mali kernel UK ABI does not match $EXPECTED_ABI"
    [ "$(_T2S_MALI_MANIFEST_VALUE donor)" = "$EXPECTED_DONOR" ] || \
        ABORT "Mali kernel donor does not match the pinned source"
    [ -n "$(_T2S_MALI_MANIFEST_VALUE kernel_module_sha256)" ] || \
        ABORT "Mali kernel module checksum is missing from the build manifest"

    [ -f "$WORK_DIR/kernel/boot.img" ] || ABORT "Installed boot.img is missing"
    [ -f "$WORK_DIR/kernel/vendor_boot.img" ] || ABORT "Installed vendor_boot.img is missing"
    BOOT_HASH="$(sha256sum "$WORK_DIR/kernel/boot.img" | cut -d ' ' -f 1)"
    VENDOR_BOOT_HASH="$(sha256sum "$WORK_DIR/kernel/vendor_boot.img" | cut -d ' ' -f 1)"
    [ "$(_T2S_MALI_MANIFEST_VALUE boot_sha256)" = "$BOOT_HASH" ] || \
        ABORT "boot.img no longer matches the verified Mali kernel build"
    [ "$(_T2S_MALI_MANIFEST_VALUE vendor_boot_sha256)" = "$VENDOR_BOOT_HASH" ] || \
        ABORT "vendor_boot.img no longer matches the verified Mali kernel build"

    LOG "- KMD/UMD pairing: $EXPECTED_RELEASE, Job Manager UK ABI $EXPECTED_ABI"
}

_T2S_MALI_VERIFY_R44_SOURCE()
{
    local SOURCE="$1"
    local ENTRY REL EXPECTED LABEL

    for ENTRY in "${MALI_R44_DRIVER_FILES[@]}"; do
        IFS="|" read -r REL EXPECTED LABEL <<< "$ENTRY"
        _T2S_MALI_FILE_MATCHES "$SOURCE/$REL" "$EXPECTED" || return 1
    done
}

_T2S_MALI_VERIFY_V34_SOURCE()
{
    local SOURCE="$1"
    local ENTRY REL REMOTE EXPECTED LABEL

    for ENTRY in "${MALI_V34_FILES[@]}"; do
        IFS="|" read -r REL REMOTE EXPECTED LABEL <<< "$ENTRY"
        _T2S_MALI_FILE_MATCHES "$SOURCE/$REL" "$EXPECTED" || return 1
    done
}

_T2S_MALI_VERIFY_R44_LIBDRM_SOURCE()
{
    local SOURCE="$1"
    local ENTRY REL EXPECTED CLASS LABEL FILE NEEDED

    for ENTRY in "${MALI_R44_LIBDRM_FILES[@]}"; do
        IFS="|" read -r REL EXPECTED CLASS LABEL <<< "$ENTRY"
        FILE="$SOURCE/$REL"
        _T2S_MALI_FILE_MATCHES "$FILE" "$EXPECTED" || return 1
        readelf -h "$FILE" | grep -q "Class:.*$CLASS" || return 1
        readelf -d "$FILE" | grep -qF 'Library soname: [libdrm.so]' || return 1

        NEEDED="$(readelf -d "$FILE" | \
            sed -n 's/.*Shared library: \[\(.*\)\]/\1/p' | LC_ALL=C sort | xargs)"
        [ "$NEEDED" = "libc++.so libc.so libdl.so libm.so" ] || return 1
    done
}

_T2S_MALI_VERIFY_R38_SOURCE()
{
    local SOURCE="$1"
    local ENTRY REL EXPECTED LABEL

    for ENTRY in "${MALI_R38_DRIVER_FILES[@]}"; do
        IFS="|" read -r REL EXPECTED LABEL <<< "$ENTRY"
        _T2S_MALI_FILE_MATCHES "$SOURCE/$REL" "$EXPECTED" || return 1
    done
}

_T2S_MALI_FETCH_R44()
{
    local ENTRY REL EXPECTED LABEL OUTPUT TEMP

    for ENTRY in "${MALI_R44_DRIVER_FILES[@]}"; do
        IFS="|" read -r REL EXPECTED LABEL <<< "$ENTRY"
        OUTPUT="$MALI_R44_CACHE_DIR/$REL"
        TEMP="$OUTPUT.download"
        _T2S_MALI_FILE_MATCHES "$OUTPUT" "$EXPECTED" && continue

        LOG "- Downloading $REL from the pinned Pixel 6 r44p0 donor"
        mkdir -p "$(dirname "$OUTPUT")"
        rm -f "$TEMP"
        DOWNLOAD_FILE "$MALI_R44_BASE_URL/$REL" "$TEMP" || \
            ABORT "Failed to download Mali r44 donor file: $REL"
        _T2S_MALI_FILE_MATCHES "$TEMP" "$EXPECTED" || {
            rm -f "$TEMP"
            ABORT "Mali r44 donor checksum mismatch: $REL"
        }
        mv -f "$TEMP" "$OUTPUT"
    done
}

_T2S_MALI_FETCH_V34()
{
    local ENTRY REL REMOTE EXPECTED LABEL OUTPUT TEMP ENCODED

    for ENTRY in "${MALI_V34_FILES[@]}"; do
        IFS="|" read -r REL REMOTE EXPECTED LABEL <<< "$ENTRY"
        OUTPUT="$MALI_V34_CACHE_DIR/$REL"
        TEMP="$OUTPUT.download"
        ENCODED="$TEMP.base64"
        _T2S_MALI_FILE_MATCHES "$OUTPUT" "$EXPECTED" && continue

        LOG "- Downloading $REL from the pinned Android 14 VNDK"
        mkdir -p "$(dirname "$OUTPUT")"
        rm -f "$TEMP" "$ENCODED"
        DOWNLOAD_FILE "$MALI_V34_BASE_URL/$REMOTE?format=TEXT" "$ENCODED" || \
            ABORT "Failed to download Android 14 VNDK dependency: $REL"
        if ! base64 -d "$ENCODED" > "$TEMP"; then
            rm -f "$TEMP" "$ENCODED"
            ABORT "Failed to decode Android 14 VNDK dependency: $REL"
        fi
        rm -f "$ENCODED"
        _T2S_MALI_FILE_MATCHES "$TEMP" "$EXPECTED" || {
            rm -f "$TEMP"
            ABORT "Android 14 VNDK dependency checksum mismatch: $REL"
        }
        mv -f "$TEMP" "$OUTPUT"
    done
}

_T2S_MALI_FETCH_R44_LIBDRM()
{
    local PAYLOAD="$MALI_R44_LIBDRM_CACHE_DIR/vendor.img.deflate.download"
    local IMAGE="$MALI_R44_LIBDRM_CACHE_DIR/vendor.img.download"
    local ENTRY REL EXPECTED CLASS LABEL OUTPUT TEMP TOOL

    _T2S_MALI_VERIFY_R44_LIBDRM_SOURCE "$MALI_R44_LIBDRM_CACHE_DIR" && return 0

    for TOOL in curl debugfs python3 stat; do
        command -v "$TOOL" >/dev/null || \
            ABORT "Required Pixel factory extraction tool is missing: $TOOL"
    done

    mkdir -p "$MALI_R44_LIBDRM_CACHE_DIR"
    rm -f "$PAYLOAD" "$IMAGE"
    LOG "- Range-downloading Pixel 6 UQ1A.231205.015 vendor.img"
    if ! curl --fail --location --retry 3 --retry-delay 2 \
            --max-filesize "$MALI_R44_FACTORY_VENDOR_COMPRESSED_SIZE" \
            --range "$MALI_R44_FACTORY_VENDOR_RANGE" \
            --output "$PAYLOAD" "$MALI_R44_FACTORY_URL"; then
        rm -f "$PAYLOAD" "$IMAGE"
        ABORT "Failed to download the pinned Pixel vendor.img range"
    fi
    if [ "$(stat -c '%s' "$PAYLOAD")" != "$MALI_R44_FACTORY_VENDOR_COMPRESSED_SIZE" ]; then
        rm -f "$PAYLOAD" "$IMAGE"
        ABORT "Pixel vendor.img compressed range has an unexpected size"
    fi

    LOG "- Inflating and verifying the pinned Pixel vendor.img"
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
        ABORT "Failed to inflate the pinned Pixel vendor.img"
    fi
    rm -f "$PAYLOAD"
    if [ "$(stat -c '%s' "$IMAGE")" != "$MALI_R44_FACTORY_VENDOR_SIZE" ] || \
            ! _T2S_MALI_FILE_MATCHES "$IMAGE" "$MALI_R44_FACTORY_VENDOR_SHA256"; then
        rm -f "$IMAGE"
        ABORT "Pixel vendor.img checksum or size mismatch"
    fi

    for ENTRY in "${MALI_R44_LIBDRM_FILES[@]}"; do
        IFS="|" read -r REL EXPECTED CLASS LABEL <<< "$ENTRY"
        OUTPUT="$MALI_R44_LIBDRM_CACHE_DIR/$REL"
        TEMP="$OUTPUT.download"
        mkdir -p "$(dirname "$OUTPUT")"
        rm -f "$TEMP"
        if ! debugfs -R "dump -p /${REL#vendor/} $TEMP" "$IMAGE" >/dev/null 2>&1; then
            rm -f "$TEMP" "$IMAGE"
            ABORT "Failed to extract $REL from the pinned Pixel vendor.img"
        fi
        _T2S_MALI_FILE_MATCHES "$TEMP" "$EXPECTED" || {
            rm -f "$TEMP" "$IMAGE"
            ABORT "Pixel factory libdrm checksum mismatch: $REL"
        }
        mv -f "$TEMP" "$OUTPUT"
    done
    rm -f "$IMAGE"

    _T2S_MALI_VERIFY_R44_LIBDRM_SOURCE "$MALI_R44_LIBDRM_CACHE_DIR" || \
        ABORT "Extracted Pixel factory libdrm pair failed ABI validation"
}

_T2S_MALI_FETCH_R38()
{
    local ENTRY REL EXPECTED LABEL OUTPUT TEMP

    for ENTRY in "${MALI_R38_DRIVER_FILES[@]}"; do
        IFS="|" read -r REL EXPECTED LABEL <<< "$ENTRY"
        OUTPUT="$MALI_R38_CACHE_DIR/$REL"
        TEMP="$OUTPUT.download"
        _T2S_MALI_FILE_MATCHES "$OUTPUT" "$EXPECTED" && continue

        LOG "- Downloading $REL from the pinned Galaxy A54 r38p1 donor"
        mkdir -p "$(dirname "$OUTPUT")"
        rm -f "$TEMP"
        DOWNLOAD_FILE "$MALI_R38_BASE_URL/$REL" "$TEMP" || \
            ABORT "Failed to download Mali r38 donor file: $REL"
        _T2S_MALI_FILE_MATCHES "$TEMP" "$EXPECTED" || {
            rm -f "$TEMP"
            ABORT "Mali r38 donor checksum mismatch: $REL"
        }
        mv -f "$TEMP" "$OUTPUT"
    done
}

_T2S_MALI_VERIFY_R44_ABI()
{
    local LIBDIR UMD VULKAN DMABUF CLASS DEP

    if ! grep -qF '<name>android.hardware.graphics.allocator</name>' \
            "$WORK_DIR/vendor/etc/vintf/manifest.xml" || \
            ! grep -qF '@4.0::IAllocator/default' \
            "$WORK_DIR/vendor/etc/vintf/manifest.xml"; then
        ABORT "Target HIDL graphics allocator 4.0 service is not declared"
    fi

    _T2S_MALI_VERIFY_R44_LIBDRM_SOURCE "$MALI_R44_LIBDRM_SOURCE_DIR" || \
        ABORT "Pixel factory libdrm pair failed ABI validation"

    for LIBDIR in lib lib64; do
        UMD="$MALI_R44_SOURCE_DIR/vendor/$LIBDIR/egl/libGLES_mali.so"
        VULKAN="$MALI_R44_SOURCE_DIR/vendor/$LIBDIR/hw/vulkan.mali.so"
        DMABUF="$MALI_V34_SOURCE_DIR/vendor/$LIBDIR/libdmabufheap.so"
        [ "$LIBDIR" = "lib" ] && CLASS="ELF32" || CLASS="ELF64"

        readelf -h "$UMD" | grep "Class:.*$CLASS" >/dev/null || \
            ABORT "Mali r44 $LIBDIR UMD has the wrong ELF class"
        strings "$UMD" | grep -F 'U:r44p0-01eac0' >/dev/null || \
            ABORT "Mali r44 $LIBDIR UMD has the wrong release"
        strings "$UMD" | grep -F 'Mali-G78' >/dev/null || \
            ABORT "Mali r44 $LIBDIR UMD does not advertise Mali-G78 support"
        readelf -d "$UMD" | grep -F '[android.hardware.graphics.allocator-V2-ndk.so]' >/dev/null || \
            ABORT "Mali r44 $LIBDIR UMD lacks its allocator V2 dependency"
        readelf -d "$UMD" | grep -F '[android.hardware.graphics.common-V4-ndk.so]' >/dev/null || \
            ABORT "Mali r44 $LIBDIR UMD lacks its graphics common V4 dependency"
        readelf -d "$UMD" | grep -F '[libdrm.so]' >/dev/null || \
            ABORT "Mali r44 $LIBDIR UMD lacks its libdrm dependency"
        readelf -d "$UMD" | grep -F '[libdmabufheap.so]' >/dev/null || \
            ABORT "Mali r44 $LIBDIR UMD lacks its DMA-BUF heap dependency"
        readelf --dyn-syms --wide "$UMD" | grep ' AServiceManager_checkService@' >/dev/null || \
            ABORT "Mali r44 $LIBDIR UMD lacks the optional AIDL allocator probe"
        readelf --dyn-syms --wide "$UMD" | grep 'IMapper10getService' >/dev/null || \
            ABORT "Mali r44 $LIBDIR UMD lacks the HIDL Mapper 4 fallback"
        readelf --dyn-syms --wide "$UMD" | grep ' eglGetDisplay$' >/dev/null || \
            ABORT "Mali r44 $LIBDIR UMD lacks EGL exports"
        readelf --dyn-syms --wide "$UMD" | grep ' glGetString$' >/dev/null || \
            ABORT "Mali r44 $LIBDIR UMD lacks GLES exports"

        readelf -h "$VULKAN" | grep "Class:.*$CLASS" >/dev/null || \
            ABORT "Mali r44 $LIBDIR Vulkan shim has the wrong ELF class"
        readelf -d "$VULKAN" | grep -F '[libGLES_mali.so]' >/dev/null || \
            ABORT "Mali r44 $LIBDIR Vulkan shim is not paired with libGLES_mali"
        readelf -d "$VULKAN" | grep -F 'Library runpath: [$ORIGIN/../egl]' >/dev/null || \
            ABORT "Mali r44 $LIBDIR Vulkan shim has an unexpected runpath"

        readelf -h "$DMABUF" | grep "Class:.*$CLASS" >/dev/null || \
            ABORT "Android 14 $LIBDIR libdmabufheap has the wrong ELF class"
        readelf -d "$DMABUF" | grep -F 'Library soname: [libdmabufheap.so]' >/dev/null || \
            ABORT "Android 14 $LIBDIR libdmabufheap has the wrong SONAME"

        for DEP in \
            libbinder_ndk.so libnativewindow.so libutils.so \
            android.hardware.graphics.mapper@4.0.so liblog.so \
            libgralloctypes.so libhidlbase.so libcutils.so libhardware.so \
            libbase.so libz.so libc++.so libc.so libm.so libdl.so; do
            if [ ! -e "$WORK_DIR/vendor/$LIBDIR/$DEP" ] && \
                    [ ! -L "$WORK_DIR/vendor/$LIBDIR/$DEP" ] && \
                    [ ! -e "$WORK_DIR/system/system/$LIBDIR/$DEP" ] && \
                    [ ! -L "$WORK_DIR/system/system/$LIBDIR/$DEP" ]; then
                ABORT "Target $LIBDIR runtime lacks Mali r44 dependency: $DEP"
            fi
        done
    done

    for LIBDIR in lib lib64; do
        readelf -d "$MALI_V34_SOURCE_DIR/vendor/$LIBDIR/android.hardware.graphics.allocator-V2-ndk.so" | \
            grep -F '[android.hardware.graphics.common-V4-ndk.so]' >/dev/null || \
            ABORT "Android 14 $LIBDIR allocator dependency closure is incomplete"
        readelf -d "$MALI_V34_SOURCE_DIR/vendor/$LIBDIR/android.hardware.graphics.common-V4-ndk.so" | \
            grep -F '[android.hardware.common-V2-ndk.so]' >/dev/null || \
            ABORT "Android 14 $LIBDIR graphics-common dependency closure is incomplete"
    done
}

_T2S_MALI_VERIFY_R44_INSTALLED_CLOSURE()
{
    local LIBDIR CLASS FILE DEP ENTRY REL REMOTE EXPECTED LABEL
    local CONTEXT_PATH
    local -a FILES

    for ENTRY in "${MALI_R44_DRIVER_FILES[@]}"; do
        IFS="|" read -r REL EXPECTED LABEL <<< "$ENTRY"
        _T2S_MALI_FILE_MATCHES "$WORK_DIR/$REL" "$EXPECTED" || \
            ABORT "Installed Mali r44 file differs from its pinned source: $REL"
    done
    for ENTRY in "${MALI_V34_FILES[@]}"; do
        IFS="|" read -r REL REMOTE EXPECTED LABEL <<< "$ENTRY"
        _T2S_MALI_FILE_MATCHES "$WORK_DIR/$REL" "$EXPECTED" || \
            ABORT "Installed Android 14 dependency differs from its pinned source: $REL"
    done
    for ENTRY in "${MALI_R44_LIBDRM_FILES[@]}"; do
        IFS="|" read -r REL EXPECTED CLASS LABEL <<< "$ENTRY"
        _T2S_MALI_FILE_MATCHES "$WORK_DIR/$REL" "$EXPECTED" || \
            ABORT "Installed Pixel factory dependency differs from its pinned source: $REL"
    done

    for LIBDIR in lib lib64; do
        [ "$LIBDIR" = "lib" ] && CLASS="ELF32" || CLASS="ELF64"
        for FILE in libdrm.so libdmabufheap.so; do
            readelf -h "$WORK_DIR/vendor/$LIBDIR/$FILE" | \
                grep "Class:.*$CLASS" >/dev/null || \
                ABORT "Installed vendor/$LIBDIR/$FILE has the wrong ELF class"
            readelf -d "$WORK_DIR/vendor/$LIBDIR/$FILE" | \
                grep -F "Library soname: [$FILE]" >/dev/null || \
                ABORT "Installed vendor/$LIBDIR/$FILE has the wrong SONAME"

            REL="vendor/$LIBDIR/$FILE"
            grep -qxF "$REL 0 0 644 capabilities=0x0" \
                "$WORK_DIR/configs/fs_config-vendor" || \
                ABORT "Installed $REL has incorrect filesystem metadata"
            CONTEXT_PATH="/${REL//./\\.} u:object_r:same_process_hal_file:s0"
            grep -qxF "$CONTEXT_PATH" "$WORK_DIR/configs/file_context-vendor" || \
                ABORT "Installed $REL is not labeled as an SP-HAL library"
        done

        FILES=(
            "$WORK_DIR/vendor/$LIBDIR/egl/libGLES_mali.so"
            "$WORK_DIR/vendor/$LIBDIR/hw/vulkan.mali.so"
            "$WORK_DIR/vendor/$LIBDIR/libdrm.so"
            "$WORK_DIR/vendor/$LIBDIR/libdmabufheap.so"
            "$WORK_DIR/vendor/$LIBDIR/android.hardware.common-V2-ndk.so"
            "$WORK_DIR/vendor/$LIBDIR/android.hardware.graphics.allocator-V2-ndk.so"
            "$WORK_DIR/vendor/$LIBDIR/android.hardware.graphics.common-V4-ndk.so"
        )
        for FILE in "${FILES[@]}"; do
            [ -f "$FILE" ] || ABORT "Installed Mali r44 closure file is missing: ${FILE//$WORK_DIR\//}"
            while IFS= read -r DEP; do
                case "$DEP" in
                    libGLES_mali.so)
                        [ -f "$WORK_DIR/vendor/$LIBDIR/egl/$DEP" ] || \
                            ABORT "Mali r44 $LIBDIR Vulkan dependency is unresolved: $DEP"
                        ;;
                    libdrm.so|libdmabufheap.so|android.hardware.common-V2-ndk.so|\
                    android.hardware.graphics.allocator-V2-ndk.so|\
                    android.hardware.graphics.common-V4-ndk.so)
                        [ -f "$WORK_DIR/vendor/$LIBDIR/$DEP" ] || \
                            ABORT "Mali r44 $LIBDIR SP-HAL dependency is not vendor-visible: $DEP"
                        ;;
                    *)
                        if [ ! -e "$WORK_DIR/vendor/$LIBDIR/$DEP" ] && \
                                [ ! -L "$WORK_DIR/vendor/$LIBDIR/$DEP" ] && \
                                [ ! -e "$WORK_DIR/system/system/$LIBDIR/$DEP" ] && \
                                [ ! -L "$WORK_DIR/system/system/$LIBDIR/$DEP" ]; then
                            ABORT "Mali r44 $LIBDIR dependency is unresolved: $DEP"
                        fi
                        ;;
                esac
            done < <(readelf -d "$FILE" | \
                sed -n 's/.*Shared library: \[\(.*\)\]/\1/p' | LC_ALL=C sort -u)
        done
    done
}

_T2S_MALI_VERIFY_R38_ABI()
{
    local ABI_DIR="$TMP_DIR/t2s-mali-r38p1-abi"
    local LIBDIR TARGET_UMD DONOR_UMD

    case "$ABI_DIR" in
        "$TMP_DIR"/t2s-mali-r38p1-abi) rm -rf "$ABI_DIR" ;;
        *) ABORT "Refusing to clean unexpected Mali ABI path: $ABI_DIR" ;;
    esac
    mkdir -p "$ABI_DIR"

    for LIBDIR in lib lib64; do
        TARGET_UMD="$WORK_DIR/vendor/$LIBDIR/egl/libGLES_mali.so"
        DONOR_UMD="$MALI_R38_SOURCE_DIR/vendor/$LIBDIR/egl/libGLES_mali.so"
        [ -f "$TARGET_UMD" ] || ABORT "Target Mali UMD is missing: $TARGET_UMD"
        strings "$DONOR_UMD" | grep -F 'U:r38p1-01eac0' >/dev/null || \
            ABORT "Mali r38 $LIBDIR UMD has the wrong release"
        strings "$DONOR_UMD" | grep -F 'Mali-G78' >/dev/null || \
            ABORT "Mali r38 $LIBDIR UMD does not advertise Mali-G78 support"

        readelf -d "$TARGET_UMD" | sed -n 's/.*Shared library: \[\(.*\)\]/\1/p' | \
            LC_ALL=C sort -u > "$ABI_DIR/$LIBDIR.target.needed"
        readelf -d "$DONOR_UMD" | sed -n 's/.*Shared library: \[\(.*\)\]/\1/p' | \
            LC_ALL=C sort -u > "$ABI_DIR/$LIBDIR.donor.needed"
        cmp -s "$ABI_DIR/$LIBDIR.target.needed" "$ABI_DIR/$LIBDIR.donor.needed" || \
            ABORT "Mali r38 $LIBDIR UMD changed its shared-library ABI"
    done

    rm -rf "$ABI_DIR"
}

for TOOL in base64 cmp readelf sha256sum strings; do
    command -v "$TOOL" >/dev/null || ABORT "Required Mali validation tool is missing: $TOOL"
done

LOG_STEP_IN "- Verifying matched Mali kernel/userspace ABI"
_T2S_MALI_VERIFY_KERNEL_PAIRING
LOG_STEP_OUT

case "$T2S_MALI_DDK" in
    r44p0)
        LOG_STEP_IN "- Preparing Pixel 6 Mali r44p0 userspace"
        if [ -n "${T2S_MALI_R44P0_DONOR_DIR:-}" ]; then
            MALI_R44_SOURCE_DIR="$T2S_MALI_R44P0_DONOR_DIR"
        elif [ -d "$MALI_R44_LOCAL_DONOR_DIR" ] && \
                _T2S_MALI_VERIFY_R44_SOURCE "$MALI_R44_LOCAL_DONOR_DIR"; then
            MALI_R44_SOURCE_DIR="$MALI_R44_LOCAL_DONOR_DIR"
        else
            _T2S_MALI_FETCH_R44
            MALI_R44_SOURCE_DIR="$MALI_R44_CACHE_DIR"
        fi
        _T2S_MALI_VERIFY_R44_SOURCE "$MALI_R44_SOURCE_DIR" || \
            ABORT "Mali r44 donor is incomplete or does not match pinned checksums"

        if [ -n "${T2S_MALI_V34_DONOR_DIR:-}" ]; then
            MALI_V34_SOURCE_DIR="$T2S_MALI_V34_DONOR_DIR"
        else
            _T2S_MALI_FETCH_V34
            MALI_V34_SOURCE_DIR="$MALI_V34_CACHE_DIR"
        fi
        _T2S_MALI_VERIFY_V34_SOURCE "$MALI_V34_SOURCE_DIR" || \
            ABORT "Android 14 VNDK graphics closure is incomplete or does not match pinned checksums"

        if [ -n "${T2S_MALI_R44P0_LIBDRM_DIR:-}" ]; then
            MALI_R44_LIBDRM_SOURCE_DIR="$T2S_MALI_R44P0_LIBDRM_DIR"
        else
            _T2S_MALI_FETCH_R44_LIBDRM
            MALI_R44_LIBDRM_SOURCE_DIR="$MALI_R44_LIBDRM_CACHE_DIR"
        fi
        _T2S_MALI_VERIFY_R44_LIBDRM_SOURCE "$MALI_R44_LIBDRM_SOURCE_DIR" || \
            ABORT "Pixel factory libdrm donor is incomplete or does not match pinned checksums"
        LOG "- UMD donor: $MALI_R44_REPOSITORY@$MALI_R44_COMMIT"
        LOG "- VNDK donor: platform/prebuilts/vndk/v34@$MALI_V34_COMMIT"
        LOG "- libdrm donor: Pixel 6 UQ1A.231205.015 factory vendor image"
        LOG_STEP_OUT

        LOG_STEP_IN "- Validating Mali r44p0 HIDL/SP-HAL compatibility"
        _T2S_MALI_VERIFY_R44_ABI
        LOG "- AIDL allocator is optional; target HIDL Mapper 4 fallback is present"
        LOG_STEP_OUT

        LOG_STEP_IN "- Installing matched Mali r44p0 userspace"
        for ENTRY in "${MALI_V34_FILES[@]}"; do
            IFS="|" read -r REL REMOTE EXPECTED LABEL <<< "$ENTRY"
            ADD_TO_WORK_DIR "$MALI_V34_SOURCE_DIR" "vendor" "${REL#vendor/}" 0 0 644 "$LABEL"
        done
        for ENTRY in "${MALI_R44_LIBDRM_FILES[@]}"; do
            IFS="|" read -r REL EXPECTED CLASS LABEL <<< "$ENTRY"
            ADD_TO_WORK_DIR "$MALI_R44_LIBDRM_SOURCE_DIR" "vendor" "${REL#vendor/}" \
                0 0 644 "$LABEL"
        done
        for ENTRY in "${MALI_R44_DRIVER_FILES[@]}"; do
            IFS="|" read -r REL EXPECTED LABEL <<< "$ENTRY"
            ADD_TO_WORK_DIR "$MALI_R44_SOURCE_DIR" "vendor" "${REL#vendor/}" 0 0 644 "$LABEL"
        done
        ADD_TO_WORK_DIR "$MODPATH" "vendor" \
            "etc/permissions/android.hardware.vulkan.version.xml" \
            0 0 644 "u:object_r:vendor_configs_file:s0"
        LOG_STEP_OUT

        LOG_STEP_IN "- Verifying installed Mali r44p0 vendor/SP-HAL closure"
        _T2S_MALI_VERIFY_R44_INSTALLED_CLOSURE
        LOG_STEP_OUT
        ;;

    r38p1)
        LOG_STEP_IN "- Preparing Galaxy A54 Mali r38p1 rollback userspace"
        if [ -n "${T2S_MALI_R38P1_DONOR_DIR:-}" ]; then
            MALI_R38_SOURCE_DIR="$T2S_MALI_R38P1_DONOR_DIR"
        elif [ -d "$MALI_R38_LOCAL_DONOR_DIR/.git" ] && \
                [ "$(git -C "$MALI_R38_LOCAL_DONOR_DIR" rev-parse HEAD 2>/dev/null)" = "$MALI_R38_COMMIT" ] && \
                _T2S_MALI_VERIFY_R38_SOURCE "$MALI_R38_LOCAL_DONOR_DIR"; then
            MALI_R38_SOURCE_DIR="$MALI_R38_LOCAL_DONOR_DIR"
        else
            _T2S_MALI_FETCH_R38
            MALI_R38_SOURCE_DIR="$MALI_R38_CACHE_DIR"
        fi
        _T2S_MALI_VERIFY_R38_SOURCE "$MALI_R38_SOURCE_DIR" || \
            ABORT "Mali r38 donor is incomplete or does not match pinned checksums"
        LOG_STEP_OUT

        LOG_STEP_IN "- Validating Mali r38p1 userspace ABI"
        _T2S_MALI_VERIFY_R38_ABI
        LOG_STEP_OUT

        LOG_STEP_IN "- Installing matched Mali r38p1 userspace"
        for ENTRY in "${MALI_R38_DRIVER_FILES[@]}"; do
            IFS="|" read -r REL EXPECTED LABEL <<< "$ENTRY"
            ADD_TO_WORK_DIR "$MALI_R38_SOURCE_DIR" "vendor" "${REL#vendor/}" 0 0 644 "$LABEL"
        done
        LOG_STEP_OUT
        ;;
esac

unset T2S_MALI_DDK T2S_MALI_R44P0_DONOR_DIR T2S_MALI_R44P0_LIBDRM_DIR
unset T2S_MALI_V34_DONOR_DIR T2S_MALI_R38P1_DONOR_DIR
unset MALI_KERNEL_MANIFEST MALI_R44_REPOSITORY MALI_R44_COMMIT MALI_R44_BASE_URL
unset MALI_R44_CACHE_DIR MALI_R44_LOCAL_DONOR_DIR MALI_R44_SOURCE_DIR
unset MALI_R44_FACTORY_URL MALI_R44_FACTORY_VENDOR_RANGE
unset MALI_R44_FACTORY_VENDOR_COMPRESSED_SIZE MALI_R44_FACTORY_VENDOR_SIZE
unset MALI_R44_FACTORY_VENDOR_SHA256 MALI_R44_LIBDRM_CACHE_DIR MALI_R44_LIBDRM_SOURCE_DIR
unset MALI_V34_COMMIT MALI_V34_BASE_URL MALI_V34_CACHE_DIR MALI_V34_SOURCE_DIR
unset MALI_R38_REPOSITORY MALI_R38_COMMIT MALI_R38_BASE_URL
unset MALI_R38_CACHE_DIR MALI_R38_LOCAL_DONOR_DIR MALI_R38_SOURCE_DIR
unset MALI_R44_DRIVER_FILES MALI_R44_LIBDRM_FILES MALI_V34_FILES MALI_R38_DRIVER_FILES
unset ENTRY REL REMOTE EXPECTED LABEL OUTPUT TEMP ENCODED TOOL LIBDIR DEP FILE
unset UMD VULKAN DMABUF CLASS EXPECTED_RELEASE EXPECTED_ABI EXPECTED_DONOR
unset BOOT_HASH VENDOR_BOOT_HASH ABI_DIR TARGET_UMD DONOR_UMD
unset -f _T2S_MALI_FILE_MATCHES _T2S_MALI_MANIFEST_VALUE
unset -f _T2S_MALI_VERIFY_KERNEL_PAIRING _T2S_MALI_VERIFY_R44_SOURCE
unset -f _T2S_MALI_VERIFY_V34_SOURCE _T2S_MALI_VERIFY_R44_LIBDRM_SOURCE
unset -f _T2S_MALI_VERIFY_R38_SOURCE
unset -f _T2S_MALI_FETCH_R44 _T2S_MALI_FETCH_V34 _T2S_MALI_FETCH_R44_LIBDRM
unset -f _T2S_MALI_FETCH_R38
unset -f _T2S_MALI_VERIFY_R44_ABI _T2S_MALI_VERIFY_R44_INSTALLED_CLOSURE
unset -f _T2S_MALI_VERIFY_R38_ABI
