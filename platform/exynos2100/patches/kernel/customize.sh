# FloppyKernel source and packaging configuration. All values can be
# overridden from the environment without changing this module.
FLOPPY_KERNEL_REPO="${FLOPPY_KERNEL_REPO:-https://github.com/FlopKernel-Series/flop_exynos2100_kernel}"
FLOPPY_KERNEL_BRANCH="${FLOPPY_KERNEL_BRANCH:-floppy-main}"
FLOPPY_ANYKERNEL_REPO="${FLOPPY_ANYKERNEL_REPO:-https://github.com/FlopKernel-Series/AnyKernel3-exynos2100}"
FLOPPY_ANYKERNEL_BRANCH="${FLOPPY_ANYKERNEL_BRANCH:-floppy-unity}"
FLOPPY_KERNEL_BUILD_ARGS="${FLOPPY_KERNEL_BUILD_ARGS:-kcR}"
FLOPPY_KERNEL_JOBS="${FLOPPY_KERNEL_JOBS:-1}"
FLOPPY_BPF_SPOOF_MODE="${FLOPPY_BPF_SPOOF_MODE:-2}"
# Mode 0 leaves enforcement under Android init's control. Production init
# loads the split policy and switches to enforcing itself; Floppy mode 1
# instead hard-locks every SELinux check before Android has finished booting.
# Keep mode 2 available as an explicit permissive recovery override.
FLOPPY_SELINUX_MODE="${FLOPPY_SELINUX_MODE:-0}"

# Experimental Mali upgrades are enabled only for t2s. Other Exynos 2100
# devices retain Floppy's proven r38p1 stack even if the selector is exported
# globally. r44 remains the default/recovery stack; r49 must be selected
# explicitly until it has been device-tested.
if [ "${TARGET_CODENAME:-}" = "t2s" ]; then
    T2S_MALI_DDK="${T2S_MALI_DDK:-r44p0}"
else
    T2S_MALI_DDK="r38p1"
fi

MALI_R44_KERNEL_REPO="${MALI_R44_KERNEL_REPO:-https://github.com/Mesa-Labs-Archive/android_kernel_samsung_s5e8835}"
MALI_R44_KERNEL_COMMIT="${MALI_R44_KERNEL_COMMIT:-ed39d840e85ab23495efb36001d0cd792862c5c6}"
MALI_R49_BACKPORT_REPO="${MALI_R49_BACKPORT_REPO:-https://github.com/Dozairu/KawaKernel-A217X}"
MALI_R49_BACKPORT_COMMIT="${MALI_R49_BACKPORT_COMMIT:-3aa1f7b4b02dff89881cd283ee56c5854444a514}"
MALI_R49_UPSTREAM_REPO="${MALI_R49_UPSTREAM_REPO:-https://android.googlesource.com/kernel/google-modules/gpu}"
MALI_R49_UPSTREAM_COMMIT="${MALI_R49_UPSTREAM_COMMIT:-14fdd7d6beeb8d54b027634eb519251b27d9e8e1}"

KERNEL_CACHE_DIR="$SRC_DIR/out/kernel-cache/flop_exynos2100_kernel"
KERNEL_WORKSPACE_DIR="$SRC_DIR/out/kernel-cache/floppy-workspace"
KERNEL_BUILD_DIR="$TMP_DIR/floppykernel"
KERNEL_SOURCE_DIR="$KERNEL_BUILD_DIR/source"
ANYKERNEL_DIR="$KERNEL_BUILD_DIR/anykernel"
KERNEL_ARTIFACT_DIR="$SRC_DIR/out/kernel-builds"
KERNEL_MALI_MANIFEST="$KERNEL_ARTIFACT_DIR/latest-mali-ddk.txt"
KERNEL_LOCK_FILE="$SRC_DIR/out/kernel-cache/floppy-build.lock"
MALI_R44_KERNEL_CACHE_DIR="$SRC_DIR/out/kernel-cache/mali-r44p0-s5e8835"
MALI_R49_BACKPORT_CACHE_DIR="$SRC_DIR/out/kernel-cache/mali-r49p0-kawa"
MALI_R49_UPSTREAM_CACHE_DIR="$SRC_DIR/out/kernel-cache/mali-r49p0-google"

_FLOPPY_CLEAN_BUILD_TREE()
{
    if [ -d "$KERNEL_CACHE_DIR/.git" ] && [ -e "$KERNEL_SOURCE_DIR" ]; then
        git -C "$KERNEL_CACHE_DIR" worktree remove --force "$KERNEL_SOURCE_DIR" >/dev/null 2>&1 || true
    fi

    case "$KERNEL_BUILD_DIR" in
        "$TMP_DIR"/floppykernel)
            rm -rf "$KERNEL_BUILD_DIR"
            ;;
        *)
            ABORT "Refusing to clean unexpected kernel build path: $KERNEL_BUILD_DIR"
            ;;
    esac

    if [ -d "$KERNEL_CACHE_DIR/.git" ]; then
        git -C "$KERNEL_CACHE_DIR" worktree prune
    fi
}

_FLOPPY_RELEASE_LOCK()
{
    if [ -n "${FLOPPY_LOCK_FD:-}" ]; then
        flock -u "$FLOPPY_LOCK_FD" 2>/dev/null || true
        exec {FLOPPY_LOCK_FD}>&-
    fi
}

_FLOPPY_VERIFY_KSUNEXT_BUILD()
{
    local KSU_CONFIG="$KERNEL_SOURCE_DIR/out/.config"
    local KSU_RUNTIME="$KERNEL_SOURCE_DIR/drivers/kernelsu/kernel/runtime/ksud_integration.c"
    local KSU_IMAGE="$KERNEL_SOURCE_DIR/out/arch/arm64/boot/Image"
    local INIT_MAIN="$KERNEL_SOURCE_DIR/init/main.c"
    local OPTION

    for OPTION in CONFIG_KSU_NEXT CONFIG_KSU CONFIG_KSU_MANUAL_HOOK CONFIG_KSU_SUSFS; do
        if ! grep -qx "$OPTION=y" "$KSU_CONFIG"; then
            ABORT "Built FloppyKernel is missing required KernelSU option: $OPTION"
            return 1
        fi
    done
    if grep -qF 'task_work_add(' "$KSU_RUNTIME"; then
        ABORT "KernelSU boot integration still contains deferred task-work callbacks"
        return 1
    fi
    if ! grep -qF 'on property:sys.user.0.ce_available=true' "$KSU_RUNTIME" || \
            ! grep -qF 'on_post_fs_data();' "$KSU_RUNTIME"; then
        ABORT "KernelSU Android 17 boot triggers are missing"
        return 1
    fi
    if [ ! -f "$KSU_IMAGE" ] || \
            ! grep -aFq '/data/adb/ksud' "$KSU_IMAGE"; then
        ABORT "Built kernel image does not contain the KernelSU daemon integration"
        return 1
    fi
    if ! grep -qF 'if (selinux_mode_cmdline_set)' "$INIT_MAIN" || \
            ! grep -aFq "selinux_mode=$FLOPPY_SELINUX_MODE" "$KSU_IMAGE"; then
        ABORT "Built kernel image does not contain the requested SELinux mode and override precedence"
        return 1
    fi
}

_FLOPPY_IMPORT_MALI_R44()
{
    local TREE

    if [ ! -d "$MALI_R44_KERNEL_CACHE_DIR/.git" ]; then
        if [ -e "$MALI_R44_KERNEL_CACHE_DIR" ]; then
            ABORT "Mali r44 kernel cache exists but is not a Git checkout: $MALI_R44_KERNEL_CACHE_DIR"
            return 1
        fi
        git clone --filter=blob:none --no-checkout --depth=1 \
            "$MALI_R44_KERNEL_REPO" "$MALI_R44_KERNEL_CACHE_DIR"
    else
        git -C "$MALI_R44_KERNEL_CACHE_DIR" remote set-url origin "$MALI_R44_KERNEL_REPO"
    fi

    if ! git -C "$MALI_R44_KERNEL_CACHE_DIR" \
            cat-file -e "$MALI_R44_KERNEL_COMMIT^{commit}" 2>/dev/null; then
        git -C "$MALI_R44_KERNEL_CACHE_DIR" fetch --filter=blob:none --depth=1 \
            origin "$MALI_R44_KERNEL_COMMIT"
    fi
    if ! git -C "$MALI_R44_KERNEL_CACHE_DIR" \
            cat-file -e "$MALI_R44_KERNEL_COMMIT^{commit}" 2>/dev/null; then
        ABORT "Pinned Mali r44 kernel donor commit is unavailable"
        return 1
    fi

    # Populate all selected blobs in one sparse-checkout transaction. Running
    # git archive directly against a blobless partial clone can otherwise make
    # one lazy network request per object.
    git -C "$MALI_R44_KERNEL_CACHE_DIR" sparse-checkout init --cone
    git -C "$MALI_R44_KERNEL_CACHE_DIR" sparse-checkout set \
        drivers/gpu/arm/v_r44p0 \
        include/linux/v_r44p0 \
        include/uapi/gpu/arm/v_r44p0
    git -C "$MALI_R44_KERNEL_CACHE_DIR" checkout --force --detach \
        "$MALI_R44_KERNEL_COMMIT"
    if [ "$(git -C "$MALI_R44_KERNEL_CACHE_DIR" rev-parse HEAD)" != \
            "$MALI_R44_KERNEL_COMMIT" ]; then
        ABORT "Mali r44 sparse checkout did not resolve the pinned commit"
        return 1
    fi
    case "$MALI_R44_KERNEL_CACHE_DIR" in
        "$SRC_DIR"/out/kernel-cache/mali-r44p0-s5e8835)
            git -C "$MALI_R44_KERNEL_CACHE_DIR" clean -ffd
            ;;
        *)
            ABORT "Refusing to clean unexpected Mali r44 cache path"
            return 1
            ;;
    esac

    for TREE in \
        drivers/gpu/arm/v_r44p0 \
        include/linux/v_r44p0 \
        include/uapi/gpu/arm/v_r44p0; do
        if [ ! -d "$MALI_R44_KERNEL_CACHE_DIR/$TREE" ]; then
            ABORT "Pinned Mali r44 donor tree is missing: $TREE"
            return 1
        fi
        if [ -e "$KERNEL_SOURCE_DIR/$TREE" ]; then
            ABORT "Refusing to overwrite an existing Mali r44 tree: $TREE"
            return 1
        fi
        mkdir -p "$(dirname "$KERNEL_SOURCE_DIR/$TREE")"
        cp -a -T "$MALI_R44_KERNEL_CACHE_DIR/$TREE" "$KERNEL_SOURCE_DIR/$TREE"
    done

    if ! grep -qF 'r44p0-01eac0' \
            "$KERNEL_SOURCE_DIR/drivers/gpu/arm/v_r44p0/Kbuild"; then
        ABORT "Imported Mali KMD is not r44p0-01eac0"
        return 1
    fi
    if ! grep -qF '#define BASE_UK_VERSION_MINOR 39' \
            "$KERNEL_SOURCE_DIR/include/uapi/gpu/arm/v_r44p0/jm/mali_kbase_jm_ioctl.h"; then
        ABORT "Imported Mali KMD does not expose Job Manager UK ABI 11.39"
        return 1
    fi
}

_FLOPPY_IMPORT_MALI_R49()
{
    local TREE HEADER FROM TO FILE

    if [ ! -d "$MALI_R49_BACKPORT_CACHE_DIR/.git" ]; then
        if [ -e "$MALI_R49_BACKPORT_CACHE_DIR" ]; then
            ABORT "Mali r49 backport cache exists but is not a Git checkout: $MALI_R49_BACKPORT_CACHE_DIR"
            return 1
        fi
        git clone --filter=blob:none --no-checkout \
            "$MALI_R49_BACKPORT_REPO" "$MALI_R49_BACKPORT_CACHE_DIR"
    else
        git -C "$MALI_R49_BACKPORT_CACHE_DIR" remote set-url origin \
            "$MALI_R49_BACKPORT_REPO"
    fi
    if ! git -C "$MALI_R49_BACKPORT_CACHE_DIR" \
            cat-file -e "$MALI_R49_BACKPORT_COMMIT^{commit}" 2>/dev/null; then
        git -C "$MALI_R49_BACKPORT_CACHE_DIR" fetch --filter=blob:none --depth=1 \
            origin "$MALI_R49_BACKPORT_COMMIT"
    fi
    if ! git -C "$MALI_R49_BACKPORT_CACHE_DIR" \
            cat-file -e "$MALI_R49_BACKPORT_COMMIT^{commit}" 2>/dev/null; then
        ABORT "Pinned Mali r49 Linux 4.19 backport commit is unavailable"
        return 1
    fi

    if [ ! -d "$MALI_R49_UPSTREAM_CACHE_DIR/.git" ]; then
        if [ -e "$MALI_R49_UPSTREAM_CACHE_DIR" ]; then
            ABORT "Mali r49 upstream cache exists but is not a Git checkout: $MALI_R49_UPSTREAM_CACHE_DIR"
            return 1
        fi
        git clone --filter=blob:none --no-checkout \
            "$MALI_R49_UPSTREAM_REPO" "$MALI_R49_UPSTREAM_CACHE_DIR"
    else
        git -C "$MALI_R49_UPSTREAM_CACHE_DIR" remote set-url origin \
            "$MALI_R49_UPSTREAM_REPO"
    fi
    if ! git -C "$MALI_R49_UPSTREAM_CACHE_DIR" \
            cat-file -e "$MALI_R49_UPSTREAM_COMMIT^{commit}" 2>/dev/null; then
        git -C "$MALI_R49_UPSTREAM_CACHE_DIR" fetch --filter=blob:none --depth=1 \
            origin "$MALI_R49_UPSTREAM_COMMIT"
    fi
    if ! git -C "$MALI_R49_UPSTREAM_CACHE_DIR" \
            cat-file -e "$MALI_R49_UPSTREAM_COMMIT^{commit}" 2>/dev/null; then
        ABORT "Pinned official Google Mali r49 commit is unavailable"
        return 1
    fi

    git -C "$MALI_R49_BACKPORT_CACHE_DIR" sparse-checkout init --cone
    git -C "$MALI_R49_BACKPORT_CACHE_DIR" sparse-checkout set \
        drivers/gpu/arm/bv_r49p0 \
        include/uapi/gpu/arm/bv_r49p0
    git -C "$MALI_R49_BACKPORT_CACHE_DIR" checkout --force --detach \
        "$MALI_R49_BACKPORT_COMMIT"
    if [ "$(git -C "$MALI_R49_BACKPORT_CACHE_DIR" rev-parse HEAD)" != \
            "$MALI_R49_BACKPORT_COMMIT" ]; then
        ABORT "Mali r49 sparse checkout did not resolve the pinned commit"
        return 1
    fi
    case "$MALI_R49_BACKPORT_CACHE_DIR" in
        "$SRC_DIR"/out/kernel-cache/mali-r49p0-kawa)
            git -C "$MALI_R49_BACKPORT_CACHE_DIR" clean -ffd
            ;;
        *)
            ABORT "Refusing to clean unexpected Mali r49 cache path"
            return 1
            ;;
    esac

    for TREE in \
        drivers/gpu/arm/bv_r49p0 \
        include/uapi/gpu/arm/bv_r49p0; do
        if [ ! -d "$MALI_R49_BACKPORT_CACHE_DIR/$TREE" ]; then
            ABORT "Pinned Mali r49 backport tree is missing: $TREE"
            return 1
        fi
        if [ -e "$KERNEL_SOURCE_DIR/$TREE" ]; then
            ABORT "Refusing to overwrite an existing Mali r49 tree: $TREE"
            return 1
        fi
        mkdir -p "$(dirname "$KERNEL_SOURCE_DIR/$TREE")"
        cp -a -T "$MALI_R49_BACKPORT_CACHE_DIR/$TREE" "$KERNEL_SOURCE_DIR/$TREE"
    done

    if [ -e "$KERNEL_SOURCE_DIR/include/linux/v_r49p0" ]; then
        ABORT "Refusing to overwrite existing Mali r49 compatibility headers"
        return 1
    fi
    mkdir -p "$KERNEL_SOURCE_DIR/include/linux/v_r49p0"
    for HEADER in \
        mali_arbiter_interface.h \
        mali_hw_access.h \
        mali_kbase_debug_coresight_csf.h \
        memory_group_manager.h \
        priority_control_manager.h \
        protected_memory_allocator.h \
        protected_mode_switcher.h; do
        if ! git -C "$MALI_R49_BACKPORT_CACHE_DIR" show \
                "$MALI_R49_BACKPORT_COMMIT:include/linux/$HEADER" \
                > "$KERNEL_SOURCE_DIR/include/linux/v_r49p0/$HEADER"; then
            ABORT "Pinned Mali r49 backport header is unavailable: $HEADER"
            return 1
        fi
    done
    if ! git -C "$MALI_R49_UPSTREAM_CACHE_DIR" show \
            "$MALI_R49_UPSTREAM_COMMIT:common/include/linux/version_compat_defs.h" \
            > "$KERNEL_SOURCE_DIR/include/linux/v_r49p0/version_compat_defs.h"; then
        ABORT "Official Mali r49 kernel compatibility header is unavailable"
        return 1
    fi

    # Namespace DDK-private Linux interfaces so the r49 module does not alter
    # headers used by Floppy's legacy Mali trees or by unrelated drivers.
    for HEADER in \
        mali_arbiter_interface.h \
        mali_hw_access.h \
        mali_kbase_debug_coresight_csf.h \
        memory_group_manager.h \
        priority_control_manager.h \
        protected_memory_allocator.h \
        version_compat_defs.h; do
        FROM="linux/$HEADER"
        TO="linux/v_r49p0/$HEADER"
        if ! grep -RIlF "$FROM" \
                "$KERNEL_SOURCE_DIR/drivers/gpu/arm/bv_r49p0" >/dev/null; then
            ABORT "Mali r49 private-header reference is missing: $FROM"
            return 1
        fi
        while IFS= read -r FILE; do
            sed -i "s|$FROM|$TO|g" "$FILE"
        done < <(grep -RIlF "$FROM" \
            "$KERNEL_SOURCE_DIR/drivers/gpu/arm/bv_r49p0")
    done
    FROM='#include <protected_mode_switcher.h>'
    TO='#include <linux/v_r49p0/protected_mode_switcher.h>'
    FILE="$KERNEL_SOURCE_DIR/drivers/gpu/arm/bv_r49p0/mali_kbase_defs.h"
    if ! grep -qF "$FROM" "$FILE"; then
        ABORT "Mali r49 protected-mode header reference is missing"
        return 1
    fi
    sed -i "s|$FROM|$TO|" "$FILE"

    if ! grep -qF 'r49p0-00eac0' \
            "$KERNEL_SOURCE_DIR/drivers/gpu/arm/bv_r49p0/Kbuild"; then
        ABORT "Imported Mali KMD is not r49p0-00eac0"
        return 1
    fi
    if ! grep -qF '#define BASE_UK_VERSION_MINOR 45' \
            "$KERNEL_SOURCE_DIR/include/uapi/gpu/arm/bv_r49p0/jm/mali_kbase_jm_ioctl.h"; then
        ABORT "Imported Mali r49 KMD does not expose Job Manager UK ABI 11.45"
        return 1
    fi
    if ! git -C "$MALI_R49_UPSTREAM_CACHE_DIR" show \
            "$MALI_R49_UPSTREAM_COMMIT:mali_kbase/Kbuild" | \
            grep -qF 'r49p0-00eac0'; then
        ABORT "Pinned official Google source is not Mali r49p0-00eac0"
        return 1
    fi
    if ! git -C "$MALI_R49_UPSTREAM_CACHE_DIR" show \
            "$MALI_R49_UPSTREAM_COMMIT:common/include/uapi/gpu/arm/midgard/jm/mali_kbase_jm_ioctl.h" | \
            grep -qF '#define BASE_UK_VERSION_MINOR 45'; then
        ABORT "Pinned official Google source does not expose Job Manager UK ABI 11.45"
        return 1
    fi
}

_FLOPPY_PATCH_LITERAL()
{
    local FILE="$1"
    local FROM="$2"
    local TO="$3"

    if [ ! -f "$FILE" ]; then
        ABORT "FloppyKernel patch target not found: $FILE"
        return 1
    fi
    if ! grep -qF "$FROM" "$FILE"; then
        ABORT "FloppyKernel patch context not found in $FILE: $FROM"
        return 1
    fi

    sed -i "s|$FROM|$TO|g" "$FILE"
}

_FLOPPY_SET_MODE_DEFAULT()
{
    local FILE="$1"
    local KEY="$2"
    local VALUE="$3"

    if [ ! -f "$FILE" ]; then
        ABORT "FloppyKernel mode target not found: $FILE"
        return 1
    fi
    if ! grep -qE "${KEY}=[0-2]" "$FILE"; then
        ABORT "FloppyKernel mode context not found in $FILE: $KEY"
        return 1
    fi

    sed -i -E "s|${KEY}=[0-2]|${KEY}=${VALUE}|g" "$FILE"
}

case "$FLOPPY_KERNEL_JOBS" in
    ''|0|*[!0-9]*) ABORT "FLOPPY_KERNEL_JOBS must be a positive integer" ;;
esac
case "$FLOPPY_BPF_SPOOF_MODE" in
    0|1|2) ;;
    *) ABORT "FLOPPY_BPF_SPOOF_MODE must be 0, 1, or 2" ;;
esac
case "$FLOPPY_SELINUX_MODE" in
    0|1|2) ;;
    *) ABORT "FLOPPY_SELINUX_MODE must be 0, 1, or 2" ;;
esac
case "$T2S_MALI_DDK" in
    r38p1|r44p0|r49p0) ;;
    *) ABORT "T2S_MALI_DDK must be r38p1, r44p0, or r49p0" ;;
esac

command -v flock >/dev/null || ABORT "Required kernel build lock tool is missing: flock"
mkdir -p "$(dirname "$KERNEL_LOCK_FILE")" "$KERNEL_ARTIFACT_DIR"
exec {FLOPPY_LOCK_FD}>"$KERNEL_LOCK_FILE"
LOG "- Waiting for the exclusive FloppyKernel build lock"
flock "$FLOPPY_LOCK_FD"
# Never allow an old successful build to authorize new userspace after a
# preparation or compilation failure.
rm -f "$KERNEL_MALI_MANIFEST" "$KERNEL_MALI_MANIFEST.tmp"

LOG_STEP_IN "- Updating FloppyKernel source"
mkdir -p "$(dirname "$KERNEL_CACHE_DIR")" "$KERNEL_WORKSPACE_DIR"

AOSP_CLANG_DIR="$KERNEL_WORKSPACE_DIR/toolchains/aospclang"
if [ -d "$AOSP_CLANG_DIR" ] && \
        [ ! "$(find "$AOSP_CLANG_DIR/lib/clang" -path '*/include/stddef.h' -print -quit 2>/dev/null)" ]; then
    LOG "- Removing incomplete AOSP Clang cache"
    case "$AOSP_CLANG_DIR" in
        "$KERNEL_WORKSPACE_DIR"/toolchains/aospclang) rm -rf "$AOSP_CLANG_DIR" ;;
        *) ABORT "Refusing to remove unexpected toolchain path: $AOSP_CLANG_DIR" ;;
    esac
fi

if [ ! -d "$KERNEL_CACHE_DIR/.git" ]; then
    if [ -e "$KERNEL_CACHE_DIR" ]; then
        ABORT "Kernel cache exists but is not a Git checkout: $KERNEL_CACHE_DIR"
    fi
    git clone --filter=blob:none --no-checkout --branch "$FLOPPY_KERNEL_BRANCH" \
        "$FLOPPY_KERNEL_REPO" "$KERNEL_CACHE_DIR"
else
    git -C "$KERNEL_CACHE_DIR" remote set-url origin "$FLOPPY_KERNEL_REPO"
fi

git -C "$KERNEL_CACHE_DIR" fetch --prune --depth=1 origin "$FLOPPY_KERNEL_BRANCH"
KERNEL_COMMIT="$(git -C "$KERNEL_CACHE_DIR" rev-parse FETCH_HEAD)"
KERNEL_COMMIT_SHORT="$(git -C "$KERNEL_CACHE_DIR" rev-parse --short=12 "$KERNEL_COMMIT")"
LOG "- Building upstream commit $KERNEL_COMMIT_SHORT"

_FLOPPY_CLEAN_BUILD_TREE
mkdir -p "$KERNEL_BUILD_DIR"
git -C "$KERNEL_CACHE_DIR" worktree add --detach "$KERNEL_SOURCE_DIR" "$KERNEL_COMMIT"
LOG_STEP_OUT

LOG_STEP_IN "- Applying UN1CA kernel compatibility"
if grep -qF 'MAKE_JOBS="-j$(nproc --all)"' "$KERNEL_SOURCE_DIR/build/scripts/build.sh"; then
    _FLOPPY_PATCH_LITERAL "$KERNEL_SOURCE_DIR/build/scripts/build.sh" \
        'MAKE_JOBS="-j$(nproc --all)"' 'MAKE_JOBS="-j${KERNEL_BUILD_JOBS:-1}"'
elif ! grep -qF 'KERNEL_BUILD_JOBS' "$KERNEL_SOURCE_DIR/build/scripts/build.sh"; then
    ABORT "FloppyKernel build job configuration is no longer compatible"
fi
# The bundled AOSP toolchain already provides cross-binutils. Upstream checks
# for the Debian package name as if it were a command, causing apt on every run.
sed -i 's/ binutils-aarch64-linux-gnu//g' "$KERNEL_SOURCE_DIR/build/scripts/deps.sh"

if [ "$T2S_MALI_DDK" = "r44p0" ]; then
    LOG "- Importing pinned Samsung Mali r44p0 KMD"
    _FLOPPY_IMPORT_MALI_R44
    LOG "- Applying Mali r44p0 Exynos 2100 integration"
    git -C "$KERNEL_SOURCE_DIR" apply --check "$MODPATH/mali-r44p0.patch"
    git -C "$KERNEL_SOURCE_DIR" apply "$MODPATH/mali-r44p0.patch"
elif [ "$T2S_MALI_DDK" = "r49p0" ]; then
    LOG "- Importing pinned Mali r49p0 Linux 4.19 backport"
    _FLOPPY_IMPORT_MALI_R49
    LOG "- Applying Mali r49p0 Exynos 2100 integration"
    git -C "$KERNEL_SOURCE_DIR" apply --check "$MODPATH/mali-r49p0.patch"
    git -C "$KERNEL_SOURCE_DIR" apply "$MODPATH/mali-r49p0.patch"
fi

while IFS= read -r PATCH; do
    [ -n "$PATCH" ] || continue
    LOG "- Applying $(basename "$PATCH")"
    git -C "$KERNEL_SOURCE_DIR" apply --check "$PATCH"
    git -C "$KERNEL_SOURCE_DIR" apply "$PATCH"
done < <(find "$MODPATH/kernel-patches" -maxdepth 1 -type f -name "*.patch" 2>/dev/null | LC_ALL=C sort)

# Keep the pinned upstream text intact until every compatibility patch has
# applied. These defaults are build-time policy and are embedded afterwards.
_FLOPPY_SET_MODE_DEFAULT "$KERNEL_SOURCE_DIR/init/main.c" \
    "uname_bpf_spoof" "$FLOPPY_BPF_SPOOF_MODE"
_FLOPPY_SET_MODE_DEFAULT "$KERNEL_SOURCE_DIR/init/main.c" \
    "selinux_mode" "$FLOPPY_SELINUX_MODE"
LOG_STEP_OUT

LOG_STEP_IN "- Preparing Android 17+ AnyKernel"
git clone --depth=1 --branch "$FLOPPY_ANYKERNEL_BRANCH" \
    "$FLOPPY_ANYKERNEL_REPO" "$ANYKERNEL_DIR"
if ! grep -q '^supported\.versions=' "$ANYKERNEL_DIR/anykernel.sh"; then
    ABORT "AnyKernel Android version configuration not found"
fi
sed -i 's/^supported\.versions=.*/supported.versions=11.0-99.0/' "$ANYKERNEL_DIR/anykernel.sh"

while IFS= read -r PATCH; do
    [ -n "$PATCH" ] || continue
    LOG "- Applying $(basename "$PATCH")"
    git -C "$ANYKERNEL_DIR" apply --check "$PATCH"
    git -C "$ANYKERNEL_DIR" apply "$PATCH"
done < <(find "$MODPATH/anykernel-patches" -maxdepth 1 -type f -name "*.patch" 2>/dev/null | LC_ALL=C sort)
LOG_STEP_OUT

if [ "${FLOPPY_KERNEL_SKIP_BUILD:-0}" = "1" ]; then
    LOG "- FLOPPY_KERNEL_SKIP_BUILD=1, source preparation verified"
    _FLOPPY_CLEAN_BUILD_TREE
    _FLOPPY_RELEASE_LOCK
    unset -f _FLOPPY_CLEAN_BUILD_TREE _FLOPPY_RELEASE_LOCK
    unset -f _FLOPPY_IMPORT_MALI_R44 _FLOPPY_IMPORT_MALI_R49
    unset -f _FLOPPY_PATCH_LITERAL _FLOPPY_SET_MODE_DEFAULT
    unset -f _FLOPPY_VERIFY_KSUNEXT_BUILD
    return 0
fi

LOG_STEP_IN "- Building FloppyKernel ($FLOPPY_KERNEL_JOBS jobs)"
mkdir -p "$KERNEL_SOURCE_DIR/out/.thinlto-cache" "$KERNEL_SOURCE_DIR/.thinlto-cache"
LOG "- Initializing FloppyKernel mkbootimg submodule"
if ! git -C "$KERNEL_SOURCE_DIR" submodule update --init --depth=1 --recommend-shallow build/mkbootimg; then
    _FLOPPY_CLEAN_BUILD_TREE
    ABORT "Failed to initialize FloppyKernel mkbootimg submodule"
fi
if [ ! -f "$KERNEL_SOURCE_DIR/build/mkbootimg/mkbootimg.py" ]; then
    _FLOPPY_CLEAN_BUILD_TREE
    ABORT "FloppyKernel mkbootimg submodule was not initialized"
fi
LOG "- Disabling LTO to work around LLVM segfault (DO_NOLTO=1)"
if ! (
    cd "$KERNEL_SOURCE_DIR"
    AK3_DIR="$ANYKERNEL_DIR" \
    WP="$KERNEL_WORKSPACE_DIR" \
    KERNEL_BUILD_JOBS="$FLOPPY_KERNEL_JOBS" \
    DO_NOLTO=1 \
    USE_CCACHE=1 \
    DO_ZIP=1 \
    DO_TAR=0 \
    PLATFORM_VERSION=11 \
    ANDROID_MAJOR_VERSION=r \
    BOOT_OS_VERSION=17.0.0 \
    bash do_build.sh "$FLOPPY_KERNEL_BUILD_ARGS"
); then
    _FLOPPY_CLEAN_BUILD_TREE
    ABORT "FloppyKernel build failed at commit $KERNEL_COMMIT_SHORT"
fi
LOG_STEP_OUT

LOG_STEP_IN "- Verifying KernelSU Next runtime integration"
_FLOPPY_VERIFY_KSUNEXT_BUILD
LOG "- KernelSU Next manual hooks, synchronous boot events, and SUSFS are built in"
LOG "- SELinux mode $FLOPPY_SELINUX_MODE is embedded with command-line override support"
LOG_STEP_OUT

LOG_STEP_IN "- Verifying the built Mali kernel driver"
case "$T2S_MALI_DDK" in
    r49p0)
        MALI_KERNEL_MODULE_REL="drivers/gpu/arm/bv_r49p0/mali_kbase.ko"
        MALI_DDK_RELEASE="r49p0-00eac0"
        MALI_DDK_UK_ABI="11.45"
        MALI_DDK_DONOR="$MALI_R49_BACKPORT_COMMIT"
        ;;
    r44p0)
        MALI_KERNEL_MODULE_REL="drivers/gpu/arm/v_r44p0/mali_kbase.ko"
        MALI_DDK_RELEASE="r44p0-01eac0"
        MALI_DDK_UK_ABI="11.39"
        MALI_DDK_DONOR="$MALI_R44_KERNEL_COMMIT"
        ;;
    r38p1)
        MALI_KERNEL_MODULE_REL="drivers/gpu/arm/v_r38p1/mali_kbase.ko"
        MALI_DDK_RELEASE="r38p1-01eac0"
        MALI_DDK_UK_ABI="11.35"
        MALI_DDK_DONOR="floppy"
        ;;
esac
MALI_KERNEL_MODULE="$KERNEL_SOURCE_DIR/out/$MALI_KERNEL_MODULE_REL"
if [ ! -f "$MALI_KERNEL_MODULE" ]; then
    _FLOPPY_CLEAN_BUILD_TREE
    ABORT "Built Mali kernel module not found: $MALI_KERNEL_MODULE_REL"
fi
if ! strings "$MALI_KERNEL_MODULE" | \
        grep -F "version=$MALI_DDK_RELEASE (UK version $MALI_DDK_UK_ABI)" >/dev/null; then
    _FLOPPY_CLEAN_BUILD_TREE
    ABORT "Built Mali kernel module release/UK ABI does not match $MALI_DDK_RELEASE"
fi
if [ ! -f "$KERNEL_SOURCE_DIR/out/modules.order" ] || \
        ! grep -qF "$MALI_KERNEL_MODULE_REL" "$KERNEL_SOURCE_DIR/out/modules.order"; then
    _FLOPPY_CLEAN_BUILD_TREE
    ABORT "Built Mali kernel module is missing from modules.order"
fi
MALI_KERNEL_MODULE_SHA256="$(sha256sum "$MALI_KERNEL_MODULE" | cut -d ' ' -f 1)"
LOG "- KMD/UK ABI: $MALI_DDK_RELEASE / $MALI_DDK_UK_ABI"
LOG_STEP_OUT

LOG_STEP_IN "- Installing FloppyKernel images"
for IMAGE_MAP in \
    "build/images/boot_oneui.img:boot.img" \
    "build/images/vendor_boot.img:vendor_boot.img"; do
    SOURCE_IMAGE="$KERNEL_SOURCE_DIR/${IMAGE_MAP%%:*}"
    TARGET_IMAGE="$WORK_DIR/kernel/${IMAGE_MAP##*:}"

    if [ ! -f "$SOURCE_IMAGE" ]; then
        _FLOPPY_CLEAN_BUILD_TREE
        ABORT "Built kernel image not found: $SOURCE_IMAGE"
    fi

    LOG "- Replacing $(basename "$TARGET_IMAGE")"
    cp -f "$SOURCE_IMAGE" "$TARGET_IMAGE"
done

mkdir -p "$KERNEL_ARTIFACT_DIR"
KERNEL_ZIP="$(find "$KERNEL_SOURCE_DIR/build" -maxdepth 1 -type f -name 'Floppy_*.zip' | LC_ALL=C sort | tail -n 1)"
if [ -n "$KERNEL_ZIP" ]; then
    cp -f "$KERNEL_ZIP" "$KERNEL_ARTIFACT_DIR/"
fi
printf '%s\n' "$KERNEL_COMMIT" > "$KERNEL_ARTIFACT_DIR/latest-commit.txt"
BOOT_IMAGE_SHA256="$(sha256sum "$WORK_DIR/kernel/boot.img" | cut -d ' ' -f 1)"
VENDOR_BOOT_IMAGE_SHA256="$(sha256sum "$WORK_DIR/kernel/vendor_boot.img" | cut -d ' ' -f 1)"
{
    printf 'target=%s\n' "$TARGET_CODENAME"
    printf 'selector=%s\n' "$T2S_MALI_DDK"
    printf 'ddk=%s\n' "$MALI_DDK_RELEASE"
    printf 'uk_abi=%s\n' "$MALI_DDK_UK_ABI"
    printf 'floppy_commit=%s\n' "$KERNEL_COMMIT"
    printf 'donor=%s\n' "$MALI_DDK_DONOR"
    printf 'kernel_module_sha256=%s\n' "$MALI_KERNEL_MODULE_SHA256"
    printf 'boot_sha256=%s\n' "$BOOT_IMAGE_SHA256"
    printf 'vendor_boot_sha256=%s\n' "$VENDOR_BOOT_IMAGE_SHA256"
} > "$KERNEL_MALI_MANIFEST.tmp"
mv -f "$KERNEL_MALI_MANIFEST.tmp" "$KERNEL_MALI_MANIFEST"
LOG "- FloppyKernel commit: $KERNEL_COMMIT"
LOG_STEP_OUT

_FLOPPY_CLEAN_BUILD_TREE
_FLOPPY_RELEASE_LOCK

unset FLOPPY_KERNEL_REPO FLOPPY_KERNEL_BRANCH
unset FLOPPY_ANYKERNEL_REPO FLOPPY_ANYKERNEL_BRANCH
unset FLOPPY_KERNEL_BUILD_ARGS FLOPPY_KERNEL_JOBS
unset FLOPPY_BPF_SPOOF_MODE FLOPPY_SELINUX_MODE
unset T2S_MALI_DDK MALI_R44_KERNEL_REPO MALI_R44_KERNEL_COMMIT
unset MALI_R49_BACKPORT_REPO MALI_R49_BACKPORT_COMMIT
unset MALI_R49_UPSTREAM_REPO MALI_R49_UPSTREAM_COMMIT
unset KERNEL_CACHE_DIR KERNEL_WORKSPACE_DIR KERNEL_BUILD_DIR KERNEL_SOURCE_DIR
unset ANYKERNEL_DIR KERNEL_ARTIFACT_DIR KERNEL_MALI_MANIFEST KERNEL_LOCK_FILE
unset KERNEL_COMMIT KERNEL_COMMIT_SHORT MALI_R44_KERNEL_CACHE_DIR
unset MALI_R49_BACKPORT_CACHE_DIR MALI_R49_UPSTREAM_CACHE_DIR
unset IMAGE_MAP SOURCE_IMAGE TARGET_IMAGE KERNEL_ZIP PATCH
unset AOSP_CLANG_DIR
unset MALI_KERNEL_MODULE_REL MALI_KERNEL_MODULE MALI_KERNEL_MODULE_SHA256
unset MALI_DDK_RELEASE MALI_DDK_UK_ABI MALI_DDK_DONOR
unset BOOT_IMAGE_SHA256 VENDOR_BOOT_IMAGE_SHA256 FLOPPY_LOCK_FD
unset -f _FLOPPY_CLEAN_BUILD_TREE _FLOPPY_RELEASE_LOCK
unset -f _FLOPPY_IMPORT_MALI_R44 _FLOPPY_IMPORT_MALI_R49
unset -f _FLOPPY_PATCH_LITERAL _FLOPPY_SET_MODE_DEFAULT
unset -f _FLOPPY_VERIFY_KSUNEXT_BUILD
