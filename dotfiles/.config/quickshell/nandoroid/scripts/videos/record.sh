#!/usr/bin/env bash

# NANDOROID Screen Recorder
# Ported from 'ii' with adjustments for nandoroid paths

CONFIG_FILE="$HOME/.config/quickshell/nandoroid/config.json"
STATE_FILE="/tmp/nandoroid_states.json"

DEBUG_LOG="/tmp/record_debug.log"
exec 2>>"$DEBUG_LOG"
echo "--- Record script started at $(date) ---" >> "$DEBUG_LOG"
echo "Args: $@" >> "$DEBUG_LOG"

# Ensure state file exists
if [ ! -f "$STATE_FILE" ]; then
    echo '{"screenRecord": {"active": false, "seconds": 0}}' > "$STATE_FILE"
fi

# Clean up any leftover PID file from old record.sh versions
rm -f "/tmp/nandoroid_record_timer.pid"

# EXIT trap: clean up state only if no new recording has started
cleanup_exit() {
    if ! pgrep wf-recorder > /dev/null 2>&1; then
        jq ".screenRecord.active = false | .screenRecord.seconds = 0 | .screenRecord.geometry = null" "$STATE_FILE" > "${STATE_FILE}.tmp" && cat "${STATE_FILE}.tmp" > "$STATE_FILE"
    fi
}
trap "cleanup_exit" EXIT

getdate() {
    date '+%Y-%m-%d_%H.%M.%S'
}

getaudiooutput() {
    pactl list sources | grep 'Name' | grep 'monitor' | cut -d ' ' -f2
}

getactivemonitor() {
    hyprctl monitors -j | jq -r '.[] | select(.focused == true) | .name'
}

updatestate() {
    local state_value=$1
    local geometry=$2
    if [[ -z "$geometry" ]]; then
        geometry="null"
    else
        geometry="\"$geometry\""
    fi
    jq ".screenRecord.active = $state_value | .screenRecord.seconds = 0 | .screenRecord.geometry = $geometry" "$STATE_FILE" > "${STATE_FILE}.tmp" && cat "${STATE_FILE}.tmp" > "$STATE_FILE"
}

# Parse arguments
ARGS=("$@")
MANUAL_REGION=""
SOUND_FLAG=0
FULLSCREEN_FLAG=0
RECORDING_DIR=""

for ((i=0;i<${#ARGS[@]};i++)); do
    if [[ "${ARGS[i]}" == "--region" ]]; then
        if (( i+1 < ${#ARGS[@]} )); then
            MANUAL_REGION="${ARGS[i+1]}"
        fi
    elif [[ "${ARGS[i]}" == "--sound" ]]; then
        SOUND_FLAG=1
    elif [[ "${ARGS[i]}" == "--fullscreen" ]]; then
        FULLSCREEN_FLAG=1
    elif [[ "${ARGS[i]}" == "--path" ]]; then
        if (( i+1 < ${#ARGS[@]} )); then
            RECORDING_DIR="${ARGS[i+1]}"
        fi
    fi
done

# Resolve recording directory
if [[ -z "$RECORDING_DIR" ]]; then
    CUSTOM_PATH=$(jq -r ".screenshot.recordPath" "$CONFIG_FILE" 2>/dev/null)
    if [[ -n "$CUSTOM_PATH" && "$CUSTOM_PATH" != "null" ]]; then
        RECORDING_DIR="$CUSTOM_PATH"
    else
        RECORDING_DIR="$HOME/Videos/Recordings"
    fi
fi

mkdir -p "$RECORDING_DIR"
cd "$RECORDING_DIR" || exit

if pgrep wf-recorder > /dev/null; then
    notify-send "Recording Stopped" "Video saved to $RECORDING_DIR" -a 'Recorder' -i media-record -t 5000 &
    updatestate false
    pkill wf-recorder &
else
    filename="Recording_$(date '+%Y-%m-%d-%H-%M-%S').mp4"
    if [[ $FULLSCREEN_FLAG -eq 1 ]]; then
        notify-send "Starting recording" "$filename" -a 'Recorder' -i media-record -t 3000 & disown
        updatestate true "fullscreen"
        if [[ $SOUND_FLAG -eq 1 ]]; then
            wf-recorder -o "$(getactivemonitor)" --pixel-format yuv420p -f "$filename" --audio="$(getaudiooutput)"
        else
            wf-recorder -o "$(getactivemonitor)" --pixel-format yuv420p -f "$filename"
        fi
    else
        if [[ -n "$MANUAL_REGION" ]]; then
            region="$MANUAL_REGION"
        else
            if ! region="$(slurp 2>&1)"; then
                notify-send "Recording cancelled" "Selection was cancelled" -a 'Recorder' -i media-record -t 3000 & disown
                updatestate false
                exit 1
            fi
        fi

        pos="${region%% *}"      # x,y
        size="${region##* }"     # WxH
        x="${pos%,*}"
        y="${pos#*,}"
        geometry="${x},${y} ${size}"

        notify-send "Starting recording" "$filename" -a 'Recorder' -i media-record -t 3000 & disown
        updatestate true "$geometry"
        if [[ $SOUND_FLAG -eq 1 ]]; then
            wf-recorder -o "$(getactivemonitor)" --pixel-format yuv420p -f "$filename" --geometry "$geometry" --audio="$(getaudiooutput)"
        else
            wf-recorder -o "$(getactivemonitor)" --pixel-format yuv420p -f "$filename" --geometry "$geometry"
        fi
    fi
fi
