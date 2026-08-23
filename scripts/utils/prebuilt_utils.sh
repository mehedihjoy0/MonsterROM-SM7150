#!/usr/bin/env bash
# Copyright (c) 2026 The UN1CA Project
# SPDX-License-Identifier: GPL-3.0-or-later

# REMOVE_EXISTING_SPLIT_FILE <file>
# Removes an unsplit file and siblings whose complete suffix is numeric.
# Terminal all-numeric suffixes are reserved for split chunks in this tree.
REMOVE_EXISTING_SPLIT_FILE()
{
    local CHUNK_PATH
    local FILE_PATH="$1"

    [ "$FILE_PATH" ] || return 1
    rm -f -- "$FILE_PATH" || return 1
    for CHUNK_PATH in "$FILE_PATH".*; do
        [ -e "$CHUNK_PATH" ] || [ -L "$CHUNK_PATH" ] || continue
        [[ "${CHUNK_PATH##*.}" =~ ^[0-9]+$ ]] || continue
        rm -f -- "$CHUNK_PATH" || return 1
    done
}
