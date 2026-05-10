#!/usr/bin/env bash
# Copyright (c) 2025 Salvo Giangreco
# SPDX-License-Identifier: GPL-3.0-or-later

# [
source "$SRC_DIR/scripts/utils/firmware_utils.sh" || exit 1
source "$TOOLS_DIR/venv/bin/activate" || exit 1

FORCE=false
JOBS="${DOWNLOAD_FW_JOBS:-1}"
SAMLOADER_JOBS="${SAMLOADER_DOWNLOAD_JOBS:-16}"

FIRMWARES=()
QUEUE_FIRMWARES=()
QUEUE_LABELS=()
MODEL=""
CSC=""
IMEI=""
SERIAL_NO=""
LATEST_FIRMWARE=""
ZIP_FILE=""

PREPARE_SCRIPT()
{
    local EXTRA_FIRMWARES=()
    local IGNORE_SOURCE=false
    local IGNORE_TARGET=false

    while [ "$#" != 0 ]; do
        if [[ "$1" == "--force" ]] || [[ "$1" == "-f" ]]; then
            FORCE=true
        elif [[ "$1" == "--jobs" ]] || [[ "$1" == "-j" ]]; then
            shift
            if [ ! "$1" ]; then
                LOGE "No jobs value supplied"
                PRINT_USAGE
                exit 1
            fi
            JOBS="$1"
        elif [[ "$1" == "--jobs="* ]]; then
            JOBS="${1#*=}"
        elif [[ "$1" == "--samloader-jobs" ]]; then
            shift
            if [ ! "$1" ]; then
                LOGE "No samloader jobs value supplied"
                PRINT_USAGE
                exit 1
            fi
            SAMLOADER_JOBS="$1"
        elif [[ "$1" == "--samloader-jobs="* ]]; then
            SAMLOADER_JOBS="${1#*=}"
        elif [[ "$1" == "--ignore-source" ]]; then
            IGNORE_SOURCE=true
        elif [[ "$1" == "--ignore-target" ]]; then
            IGNORE_TARGET=true
        elif [[ "$1" == "-"* ]]; then
            LOGE "Unknown option: $1"
            PRINT_USAGE
            exit 1
        else
            EXTRA_FIRMWARES+=("$1")
        fi

        shift
    done

    if ! $IGNORE_SOURCE; then
        _CHECK_NON_EMPTY_PARAM "SOURCE_FIRMWARE" "$SOURCE_FIRMWARE" || exit 1
        FIRMWARES+=("$SOURCE_FIRMWARE")
        IFS=':' read -r -a SOURCE_EXTRA_FIRMWARES <<< "$SOURCE_EXTRA_FIRMWARES"
        if [ "${#SOURCE_EXTRA_FIRMWARES[@]}" -ge 1 ]; then
            FIRMWARES+=("${SOURCE_EXTRA_FIRMWARES[@]}")
        fi
    fi

    if ! $IGNORE_TARGET; then
        _CHECK_NON_EMPTY_PARAM "TARGET_FIRMWARE" "$TARGET_FIRMWARE" || exit 1
        FIRMWARES+=("$TARGET_FIRMWARE")
        IFS=':' read -r -a TARGET_EXTRA_FIRMWARES <<< "$TARGET_EXTRA_FIRMWARES"
        if [ "${#TARGET_EXTRA_FIRMWARES[@]}" -ge 1 ]; then
            FIRMWARES+=("${TARGET_EXTRA_FIRMWARES[@]}")
        fi
    fi

    if [ "${#EXTRA_FIRMWARES[@]}" -ge 1 ]; then
        FIRMWARES+=("${EXTRA_FIRMWARES[@]}")
    fi
}

PRINT_USAGE()
{
    echo "Usage: download_fw [options] <firmware>" >&2
    echo " --ignore-source : Skip parsing source firmware flags" >&2
    echo " --ignore-target : Skip parsing target firmware flags" >&2
    echo " -j, --jobs <n> : Number of firmwares to process in parallel (default: ${DOWNLOAD_FW_JOBS:-1})" >&2
    echo " --samloader-jobs <n> : Number of ranged samloader connections per firmware (default: ${SAMLOADER_DOWNLOAD_JOBS:-16})" >&2
    echo " -f, --force : Force firmware download" >&2
}

VERIFY_ODIN_PACKAGES()
{
    local FILE_NAME
    local LENGTH
    local STORED_HASH
    local CALCULATED_HASH

    while IFS= read -r f; do
        FILE_NAME="$(basename "$f")"
        LOG_STEP_IN "- Verifying $FILE_NAME..."

        FILE_NAME="${FILE_NAME%.md5}"

        # Samsung stores the output of `md5sum` at the very end of the file
        LENGTH="32" # Length of MD5 hash
        LENGTH="$((LENGTH + 2))" # 2 whitespace chars
        LENGTH="$((LENGTH + ${#FILE_NAME}))" # File name without .md5 extension
        LENGTH="$((LENGTH + 1))" # 1 newline char

        STORED_HASH="$(tail -c "$LENGTH" "$f" | cut -d " " -f 1 -s)"
        if [ ! "$STORED_HASH" ] || [[ "${#STORED_HASH}" != "32" ]]; then
            LOG "\033[0;31m! Expected hash could not be parsed\033[0m"
            return 1
        fi

        CALCULATED_HASH="$(head -c-$LENGTH "$f" | md5sum | cut -d " " -f 1 -s)"

        if [[ "$STORED_HASH" != "$CALCULATED_HASH" ]]; then
            LOG "\033[0;31m! File is damaged\033[0m"
            return 1
        fi

        LOG_STEP_OUT
    done < <(find "$ODIN_DIR/${MODEL}_${CSC}" -type f -name "*.md5")

    return 0
}

PREPARE_DOWNLOAD_QUEUE()
{
    local i
    local KEY
    local SEEN_KEYS=""

    if [[ ! "$JOBS" =~ ^[0-9]+$ ]] || [ "$JOBS" -lt 1 ]; then
        LOGE "Invalid jobs value: $JOBS"
        return 1
    fi
    if [[ ! "$SAMLOADER_JOBS" =~ ^[0-9]+$ ]] || [ "$SAMLOADER_JOBS" -lt 1 ]; then
        LOGE "Invalid samloader jobs value: $SAMLOADER_JOBS"
        return 1
    fi

    for i in "${FIRMWARES[@]}"; do
        MODEL=""
        CSC=""
        IMEI=""
        SERIAL_NO=""

        PARSE_FIRMWARE_STRING "$i" || return 1

        KEY="${MODEL}_${CSC}"
        if grep -qxF "$KEY" <<< "$SEEN_KEYS"; then
            LOGW "Duplicate firmware target skipped: $MODEL/$CSC"
            continue
        fi

        SEEN_KEYS+="${KEY}"$'\n'
        QUEUE_FIRMWARES+=("$i")
        QUEUE_LABELS+=("$MODEL/$CSC")
    done

    if [ "${#QUEUE_FIRMWARES[@]}" -gt 0 ] && [ "$JOBS" -gt "${#QUEUE_FIRMWARES[@]}" ]; then
        JOBS="${#QUEUE_FIRMWARES[@]}"
    fi
}

PROCESS_FIRMWARE()
{
    local FIRMWARE="$1"
    local SAMLOADER_WORK_DIR
    local SAMLOADER_DOWNLOAD_ARGS=()

    MODEL=""
    CSC=""
    IMEI=""
    SERIAL_NO=""
    LATEST_FIRMWARE=""
    ZIP_FILE=""

    PARSE_FIRMWARE_STRING "$FIRMWARE" || return 1

    LATEST_FIRMWARE="$(GET_LATEST_FIRMWARE "$MODEL" "$CSC")"
    if [ ! "$LATEST_FIRMWARE" ]; then
        LOGE "Latest available firmware could not be fetched"
        return 1
    fi

    LOG_STEP_IN "- Processing $MODEL firmware with $CSC CSC"
    LOG "- Downloaded firmware: $(cat "$ODIN_DIR/${MODEL}_${CSC}/.downloaded" 2> /dev/null)"
    LOG "- Extracted firmware: $(cat "$FW_DIR/${MODEL}_${CSC}/.extracted" 2> /dev/null)"
    LOG "- Latest available firmware: $LATEST_FIRMWARE"

    LOG_STEP_IN

    if ! $FORCE; then
        # Skip if firmware has been extracted and equal/newer than the one in FUS
        if [ -f "$FW_DIR/${MODEL}_${CSC}/.extracted" ]; then
            if COMPARE_SEC_BUILD_VERSION "$(cat "$FW_DIR/${MODEL}_${CSC}/.extracted")" "$LATEST_FIRMWARE"; then
                LOG "\033[0;33m! This firmware has already been extracted, skipping\033[0m"
                LOG_STEP_OUT; LOG_STEP_OUT
                return 0
            fi
        fi

        # Skip if firmware has already been downloaded
        if [ -f "$ODIN_DIR/${MODEL}_${CSC}/.downloaded" ]; then
            if ! COMPARE_SEC_BUILD_VERSION "$(cat "$ODIN_DIR/${MODEL}_${CSC}/.downloaded")" "$LATEST_FIRMWARE"; then
                LOG "\033[0;33m! A newer firmware is available for download, use --force flag if you want to overwrite it\033[0m"
            else
                LOG "\033[0;33m! This firmware has already been downloaded\033[0m"
            fi
            LOG_STEP_OUT; LOG_STEP_OUT
            return 0
        fi
    fi

    LOG "- Downloading firmware..."
    [ -f "$ODIN_DIR/${MODEL}_${CSC}/.downloaded" ] && rm -rf "$ODIN_DIR/${MODEL}_${CSC}"
    mkdir -p "$ODIN_DIR/${MODEL}_${CSC}"

    # Anan's samloader stores logs in the current working directory. Keep each
    # parallel downloader isolated so jobs do not overwrite each other's logs.
    SAMLOADER_WORK_DIR="$OUT_DIR/tmp/samloader/${MODEL}_${CSC}"
    rm -rf "$SAMLOADER_WORK_DIR"
    mkdir -p "$SAMLOADER_WORK_DIR"
    if samloader -m "$MODEL" -r "$CSC" -i "$IMEI" -s "$SERIAL_NO" download --help 2>&1 | grep -q -- "--jobs"; then
        SAMLOADER_DOWNLOAD_ARGS=(-j "$SAMLOADER_JOBS")
        LOG "- Using $SAMLOADER_JOBS parallel samloader connection(s)"
    elif [ "$SAMLOADER_JOBS" -gt 1 ]; then
        LOGW "Installed samloader does not support parallel ranged downloads; run build_dependencies to update it"
    fi
    (
    cd "$SAMLOADER_WORK_DIR" || exit 1
    samloader -m "$MODEL" -r "$CSC" -i "$IMEI" -s "$SERIAL_NO" download "${SAMLOADER_DOWNLOAD_ARGS[@]}" -O "$ODIN_DIR/${MODEL}_${CSC}" || exit 1
    ) || return 1

    ZIP_FILE="$(find "$ODIN_DIR/${MODEL}_${CSC}" -name "*.zip" | sort -r | head -n 1)"
    if [ ! "$ZIP_FILE" ] || [ ! -f "$ZIP_FILE" ]; then
        LOG "\033[0;31m! Download failed\033[0m"
        return 1
    fi

    LOG "- Extracting $(basename "$ZIP_FILE")..."
    EVAL "unzip -o \"$ZIP_FILE\" -d \"$ODIN_DIR/${MODEL}_${CSC}\" && rm -rf \"$ZIP_FILE\"" || return 1

    VERIFY_ODIN_PACKAGES || return 1

    echo -n "$LATEST_FIRMWARE" > "$ODIN_DIR/${MODEL}_${CSC}/.downloaded"

    LOG_STEP_OUT; LOG_STEP_OUT
}

START_DOWNLOAD_JOB()
{
    local INDEX="$1"
    local LOG_DIR="$OUT_DIR/logs/download_fw"
    local LOG_FILE="$LOG_DIR/${QUEUE_LABELS[$INDEX]//\//_}.log"

    mkdir -p "$LOG_DIR"
    : > "$LOG_FILE"

    LOG "- Starting ${QUEUE_LABELS[$INDEX]}"
    (
    PROCESS_FIRMWARE "${QUEUE_FIRMWARES[$INDEX]}"
    ) > "$LOG_FILE" 2>&1 &

    RUNNING_PIDS+=("$!")
    RUNNING_LOGS+=("$LOG_FILE")
    RUNNING_LABELS+=("${QUEUE_LABELS[$INDEX]}")
}

REAP_DOWNLOAD_JOB()
{
    local DONE_PID
    local STATUS
    local i
    local LOG_FILE
    local LABEL

    wait -n -p DONE_PID
    STATUS="$?"

    for i in "${!RUNNING_PIDS[@]}"; do
        if [[ "${RUNNING_PIDS[$i]}" == "$DONE_PID" ]]; then
            LOG_FILE="${RUNNING_LOGS[$i]}"
            LABEL="${RUNNING_LABELS[$i]}"
            unset 'RUNNING_PIDS[i]' 'RUNNING_LOGS[i]' 'RUNNING_LABELS[i]'
            RUNNING_PIDS=("${RUNNING_PIDS[@]}")
            RUNNING_LOGS=("${RUNNING_LOGS[@]}")
            RUNNING_LABELS=("${RUNNING_LABELS[@]}")
            break
        fi
    done

    [ -f "$LOG_FILE" ] && cat "$LOG_FILE"

    if [ "$STATUS" != "0" ]; then
        LOGE "Download job failed for $LABEL (exit code $STATUS)"
        return "$STATUS"
    fi

    return 0
}

RUN_DOWNLOAD_QUEUE()
{
    local NEXT_JOB=0
    local EXIT_CODE=0
    RUNNING_PIDS=()
    RUNNING_LOGS=()
    RUNNING_LABELS=()

    if [ "${#QUEUE_FIRMWARES[@]}" -eq 0 ]; then
        LOGW "No firmware downloads requested"
        return 0
    fi

    LOG "- Running ${#QUEUE_FIRMWARES[@]} firmware download(s) with $JOBS parallel job(s)"

    if [ "$JOBS" -eq 1 ]; then
        while [ "$NEXT_JOB" -lt "${#QUEUE_FIRMWARES[@]}" ]; do
            LOG "- Starting ${QUEUE_LABELS[$NEXT_JOB]}"
            PROCESS_FIRMWARE "${QUEUE_FIRMWARES[$NEXT_JOB]}" || return "$?"
            NEXT_JOB="$((NEXT_JOB + 1))"
        done

        return 0
    fi

    while [ "$NEXT_JOB" -lt "${#QUEUE_FIRMWARES[@]}" ] || [ "${#RUNNING_PIDS[@]}" -gt 0 ]; do
        while [ "$EXIT_CODE" = "0" ] && \
                [ "$NEXT_JOB" -lt "${#QUEUE_FIRMWARES[@]}" ] && \
                [ "${#RUNNING_PIDS[@]}" -lt "$JOBS" ]; do
            START_DOWNLOAD_JOB "$NEXT_JOB"
            NEXT_JOB="$((NEXT_JOB + 1))"
        done

        if [ "${#RUNNING_PIDS[@]}" -gt 0 ]; then
            REAP_DOWNLOAD_JOB || EXIT_CODE="$?"
        fi
    done

    return "$EXIT_CODE"
}
# ]

PREPARE_SCRIPT "$@"
PREPARE_DOWNLOAD_QUEUE || exit 1

RUN_DOWNLOAD_QUEUE || exit 1

deactivate

exit 0
