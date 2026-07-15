# [
LK3RD_REPO="https://github.com/Android-Artisan/lk3rd"

BUILD_LK3RD()
{
    local PARENT
    PARENT=$(pwd)

    # Ensure we are in the correct directory
    cd "$LK3RD_TMP_DIR" || ABORT "BUILD_LK3RD: Cannot find $LK3RD_TMP_DIR"

    LOG "- Running build for ${TARGET_CODENAME}"
    EVAL "PATH=\"$LK3RD_TOOLCHAIN_DIR:\$PATH\" TOOLCHAIN_PREFIX=\"$LK3RD_TOOLCHAIN_PREFIX\" ./build.sh ${TARGET_CODENAME} -u -v y" || {
        cd "$PARENT"
        return 1
    }

    cd "$PARENT"
}

PREPARE_LK3RD_TOOLCHAIN()
{
    local CLANG_DIR="$PWD/out/kernel_tmp-${TARGET_PLATFORM}/toolchain/clang_14"
    local CLANG_BIN
    local LINK
    local SHIM_DIR="$LK3RD_TMP_DIR/.monsterrom-toolchain"

    if [ -x "$CLANG_DIR/bin/clang-14" ]; then
        CLANG_BIN="$CLANG_DIR/bin/clang-14"
    else
        CLANG_DIR="$PWD/out/kernel-cache/floppy-workspace/toolchains/aospclang"
        CLANG_BIN="$CLANG_DIR/bin/clang-22"
    fi

    if [ ! -x "$CLANG_BIN" ]; then
        ABORT "No compatible AOSP Clang toolchain found for lk3rd"
        return 1
    fi

    EVAL "mkdir -p \"$SHIM_DIR\""
    EVAL "ln -sfn \"$CLANG_BIN\" \"$SHIM_DIR/aarch64-none-elf-gcc\""
    EVAL "ln -sfn \"$PWD/external/android-tools/vendor/mkbootimg/mkbootimg.py\" \"$SHIM_DIR/mkbootimg\""
    for LINK in \
        "ld:ld.lld" \
        "objdump:llvm-objdump" \
        "objcopy:llvm-objcopy" \
        "c++filt:llvm-cxxfilt" \
        "size:llvm-size" \
        "nm:llvm-nm" \
        "strip:llvm-strip"; do
        EVAL "ln -sfn \"$CLANG_DIR/bin/${LINK#*:}\" \"$SHIM_DIR/aarch64-none-elf-${LINK%%:*}\""
    done

    LK3RD_TOOLCHAIN_DIR="$PWD/$SHIM_DIR"
    LK3RD_TOOLCHAIN_PREFIX="$LK3RD_TOOLCHAIN_DIR/aarch64-none-elf-"
}

SAFE_PULL_CHANGES()
{
    set -eo pipefail
    PARENT=$(pwd)

    cd "$LK3RD_TMP_DIR" || ABORT "SAFE_PULL: Directory missing"
    EVAL "git fetch origin"

    LOCAL=$(git rev-parse @)
    REMOTE=$(git rev-parse origin/main)
    BASE=$(git merge-base @ origin/main)

    if [[ "$LOCAL" == "$REMOTE" ]]; then
        LOG "- Local branch is up-to-date."
    elif [[ "$LOCAL" == "$BASE" ]]; then
        LOG "- Fast-forwarding."
        EVAL "git pull --ff-only"
    else
        LOGW "- Local branch diverged or ahead. Resetting to remote."
        git reset --hard origin/main
    fi

    cd "$PARENT"
}

ADD_LK3RD_BINARIES()
{
    # 1. Define the directory name based on your requirement
    # Using 'out' as the parent folder
    LK3RD_TMP_DIR="out/lk3rd_tmp-${TARGET_PLATFORM}"

    # 2. Check if the directory is missing
    if [[ ! -d "$LK3RD_TMP_DIR" ]]; then
        LOG "- lk3rd directory missing. Cloning into $LK3RD_TMP_DIR..."
        mkdir -p -- "out"
        EVAL "git clone --branch dev --single-branch --recurse-submodules \"$LK3RD_REPO\" \"$LK3RD_TMP_DIR\"" || ABORT "Clone failed"
    fi

    # 3. Repository Sync
    if [[ -d "$LK3RD_TMP_DIR/.git" ]]; then
        cd "$LK3RD_TMP_DIR" || exit
        LOG "- Syncing source code..."
        git fetch --all
        git reset --hard FETCH_HEAD
        cd - > /dev/null || exit
    else
        ABORT "Directory exists but is not a git repo: $LK3RD_TMP_DIR"
    fi

    LOG "- Applying lk3rd AOSP Clang compatibility"
    EVAL "git -C \"$LK3RD_TMP_DIR\" apply --check \"$MODPATH/patches/0001-Clang-toolchain-compatibility.patch\"" || return 1
    EVAL "git -C \"$LK3RD_TMP_DIR\" apply \"$MODPATH/patches/0001-Clang-toolchain-compatibility.patch\"" || return 1
    PREPARE_LK3RD_TOOLCHAIN || return 1

    # 4. Execute Build
    LOG "- Starting lk3rd build process."
    BUILD_LK3RD || return 1

    # 5. Artifact Management
    [[ ! -d "$WORK_DIR/kernel" ]] && mkdir -p -- "$WORK_DIR/kernel"

    SRC="$LK3RD_TMP_DIR/build/${TARGET_CODENAME}/lk3rd-${TARGET_CODENAME}.img"

    if [[ -f "$SRC" ]]; then
        rm -f "$WORK_DIR/kernel/lk3rd.img"
        mv -f "$SRC" "$WORK_DIR/kernel/lk3rd.img"
    else
        ABORT "Artifact lk3rd-${TARGET_CODENAME}.img not found at $SRC"
        return 1
    fi
}

ADD_LK3RD_BINARIES
# ]
