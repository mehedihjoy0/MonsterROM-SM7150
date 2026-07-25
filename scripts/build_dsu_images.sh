#!/usr/bin/env bash
# Copyright (c) 2026 Salvo Giangreco
# SPDX-License-Identifier: GPL-3.0-or-later

source "$SRC_DIR/scripts/utils/build_utils.sh" || exit 1

if [ ! -f "$WORK_DIR/.completed" ]; then
    LOGE "The work directory is incomplete. Run scripts/make_rom.sh -x first."
    exit 1
fi

OUTPUT_DIR="${1:-$OUT_DIR/dsu/$TARGET_CODENAME}"
PARTITIONS=(system product system_ext odm)

mkdir -p "$OUTPUT_DIR"

for PARTITION in "${PARTITIONS[@]}"; do
    if [ ! -d "$WORK_DIR/$PARTITION" ]; then
        LOGE "Partition directory missing: ${WORK_DIR//$SRC_DIR\//}/$PARTITION"
        exit 1
    fi

    LOG_STEP_IN "- Building $PARTITION.img"
    "$SRC_DIR/scripts/build_fs_image.sh" "$TARGET_OS_FILE_SYSTEM_TYPE" \
        -o "$OUTPUT_DIR/$PARTITION.img" -m -S \
        "$WORK_DIR/$PARTITION" \
        "$WORK_DIR/configs/file_context-$PARTITION" \
        "$WORK_DIR/configs/fs_config-$PARTITION" || exit 1
    LOG_STEP_OUT
done

(
    cd "$OUTPUT_DIR" || exit 1
    sha256sum "${PARTITIONS[@]/%/.img}" > SHA256SUMS
    rm -f "$TARGET_CODENAME-dsu-non-oem-signed.zip"
    zip -q -0 -X "$TARGET_CODENAME-dsu-non-oem-signed.zip" "${PARTITIONS[@]/%/.img}"
    sha256sum "$TARGET_CODENAME-dsu-non-oem-signed.zip" > \
        "$TARGET_CODENAME-dsu-non-oem-signed.zip.sha256"
)

LOG "- Created ${OUTPUT_DIR//$SRC_DIR\//}/$TARGET_CODENAME-dsu-non-oem-signed.zip"
LOGW "Images use the build system's local AVB key, are not signed by Samsung's OEM key, and have not been installed on a device."
