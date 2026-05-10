#!/usr/bin/env bash
# Copyright (c) 2026 Salvo Giangreco
# SPDX-License-Identifier: GPL-3.0-or-later

# [
source "$SRC_DIR/scripts/utils/build_utils.sh" || exit 1

DIRECT_BUILD=false
TARGET_INPUT=""
OUTPUT_FILE=""

PREPARE_SCRIPT()
{
    while [[ "$1" == "-"* ]]; do
        if [[ "$1" == "--output" ]] || [[ "$1" == "-o" ]]; then
            shift; OUTPUT_FILE="$1"
            if [[ "$OUTPUT_FILE" != *".zip" ]]; then
                LOGE "Output file name must have \".zip\" extension"
                exit 1
            fi
        else
            LOGE "Unknown option: $1"
            exit 1
        fi

        shift
    done

    TARGET_INPUT="$1"
    if [ ! "$TARGET_INPUT" ]; then
        DIRECT_BUILD=true
        TARGET_INPUT="$OUT_DIR/target/$TARGET_CODENAME/target_files"
    elif [ -d "$TARGET_INPUT" ]; then
        if [ ! -f "$TARGET_INPUT/build_info.txt" ]; then
            LOGE "File not found: ${TARGET_INPUT//$SRC_DIR\//}/build_info.txt"
            exit 1
        fi
    elif [ ! -f "$TARGET_INPUT" ]; then
        LOGE "File not found: ${TARGET_INPUT//$SRC_DIR\//}"
        exit 1
    fi
}

GET_BUILD_INFO()
{
    if [ -d "$TARGET_INPUT" ]; then
        cat "$TARGET_INPUT/build_info.txt"
    else
        EVAL "unzip -p \"$TARGET_INPUT\" \"build_info.txt\"" || exit 1
        unzip -p "$TARGET_INPUT" "build_info.txt"
    fi
}

GENERATE_OUTPUT_FILE()
{
    if [ ! "$OUTPUT_FILE" ]; then
        local TARGET_BUILD_INFO

        TARGET_BUILD_INFO="$(GET_BUILD_INFO)"

        OUTPUT_FILE="$OUT_DIR/MonsterROM-REBORN_"
        OUTPUT_FILE+="$(grep "^version" <<< "$TARGET_BUILD_INFO" | cut -d "=" -f 2 -s)"
        OUTPUT_FILE+="_"
        OUTPUT_FILE+="$(date -d "@$(grep "^timestamp" <<< "$TARGET_BUILD_INFO" | cut -d "=" -f 2 -s)" "+%Y%m%d")"
        OUTPUT_FILE+="_"
        OUTPUT_FILE+="$(grep "^device" <<< "$TARGET_BUILD_INFO" | cut -d "=" -f 2 -s)"
        if ! $DEBUG || $ROM_IS_OFFICIAL; then
            OUTPUT_FILE+="-sign"
        fi
        OUTPUT_FILE+=".zip"
    fi
}

PRINT_USAGE()
{
    echo "Usage: build_flashable_zip [options] [target-files]" >&2
    echo " -o, --output : Specify the output zip path, defaults to $OUT_DIR" >&2
}
# ]

PREPARE_SCRIPT "$@"

if $DIRECT_BUILD; then
    LOG "- Building target files"
    "$SRC_DIR/scripts/internal/create_target_files_zip.sh" --directory "$TARGET_INPUT" || exit 1
fi

GENERATE_OUTPUT_FILE
"$SRC_DIR/scripts/internal/build_full_ota_zip.sh" "$TARGET_INPUT" "$OUTPUT_FILE" || exit 1

exit 0
