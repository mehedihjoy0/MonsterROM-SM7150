#!/usr/bin/env bash
# Copyright (c) 2026 The UN1CA Project
# SPDX-License-Identifier: GPL-3.0-or-later

set -euo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
source "$SRC_DIR/scripts/utils/prebuilt_utils.sh"

TEST_DIR="$(mktemp -d)"
trap 'rm -rf -- "$TEST_DIR"' EXIT
FILE_PATH="$TEST_DIR/blob"

touch "$FILE_PATH" \
    "$FILE_PATH.00" \
    "$FILE_PATH.89" \
    "$FILE_PATH.9000" \
    "$FILE_PATH.keep" \
    "$FILE_PATH.00.sig"

REMOVE_EXISTING_SPLIT_FILE "$FILE_PATH"

[ ! -e "$FILE_PATH" ]
[ ! -e "$FILE_PATH.00" ]
[ ! -e "$FILE_PATH.89" ]
[ ! -e "$FILE_PATH.9000" ]
[ -e "$FILE_PATH.keep" ]
[ -e "$FILE_PATH.00.sig" ]

echo "prebuilt split cleanup tests passed"
