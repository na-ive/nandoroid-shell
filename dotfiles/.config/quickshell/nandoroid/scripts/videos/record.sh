#!/usr/bin/env bash

# NANDOROID Screen Recorder
# Ported from 'ii' with adjustments for nandoroid paths

CONFIG_FILE="$HOME/.config/quickshell/nandoroid/config.json"
JSON_PATH=".screenRecord.savePath"

STATE_FILE="/tmp/nandoroid_states.json" # NANDOROID might not have a persistent state JSON like ii yet
STATE_JSON_PATH=".screenRecord.active"

CUSTOM_PATH=$(jq -r "$JSON_PATH" "$CONFIG_FILE" 2>/dev/null)

RECORDING_DIR=""
DEBUG_LOG="/tmp/record_debug.log"

exec 2>>"$DEBUG_LOG"
echo "--- Record script started at $(date) ---" >> "$DEBUG_LOG"
echo "Args: $@" >> "$DEBUG_LOG"

TIMER_PID=""  
SECONDS_ELAPSED=-1

if [[ -n "$CUSTOM_PATH" && "$CUSTOM_PATH" != "null" ]]; then
    RECORDING_DIR="$CUSTOM_PATH"
else
    RECORDING_DIR="$HOME/Videos" # Use default path
fi

# Ensure state file exists
if [ ! -f "$STATE_FILE" ]; then
    echo '{"screenRecord": {"active": false, "seconds": 0}}' > "$STATE_FILE"
fi

start_timer() {
    if [[ -n "$TIMER_PID" ]]; then
        kill "$TIMER_PID" 2>/dev/null
    fi

    ( 
        while true; do
            SECONDS_ELAPSED=$((SECONDS_ELAPSED + 1))
            jq ".screenRecord.seconds = $SECONDS_ELAPSED" "$STATE_FILE" > "${STATE_FILE}.tmp" && cat "${STATE_FILE}.tmp" > "$STATE_FILE"
            sleep 1
        done
    ) &
    TIMER_PID=$!
}

stop_timer() {
    if [[ -n "$TIMER_PID" ]]; then
        kill "$TIMER_PID" 2>/dev/null
        wait "$TIMER_PID" 2>/dev/null
        TIMER_PID=""
        jq ".screenRecord.seconds = 0" "$STATE_FILE" > "${STATE_FILE}.tmp" && cat "${STATE_FILE}.tmp" > "$STATE_FILE" # setting it to 0 after killing the timer
    fi
}

trap "updatestate false" EXIT

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
    jq ".screenRecord.active = $state_value | .screenRecord.geometry = $geometry" "$STATE_FILE" > "${STATE_FILE}.tmp" && cat "${STATE_FILE}.tmp" > "$STATE_FILE"
    if [[ "$state_value" == "true" ]]; then
        start_timer
    else
        stop_timer
    fi
}

mkdir -p "$RECORDING_DIR"
cd "$RECORDING_DIR" || exit

# parse --region <value> without modifying $@
ARGS=("$@")
MANUAL_REGION=""
SOUND_FLAG=0
FULLSCREEN_FLAG=0

for ((i=0;i<${#ARGS[@]};i++)); do
    if [[ "${ARGS[i]}" == "--region" ]]; then
        if (( i+1 < ${#ARGS[@]} )); then
            MANUAL_REGION="${ARGS[i+1]}"
        else
            notify-send "Recording cancelled" "No region specified for --region" -a 'Recorder' -i media-record -t 3000 & disown
            updatestate false
            exit 1
        fi
    elif [[ "${ARGS[i]}" == "--sound" ]]; then
        SOUND_FLAG=1
    elif [[ "${ARGS[i]}" == "--fullscreen" ]]; then
        FULLSCREEN_FLAG=1
    fi
done

if pgrep wf-recorder > /dev/null; then
    notify-send "Recording Stopped" "Video saved to $RECORDING_DIR" -a 'Recorder' -i media-record -t 5000 &
    updatestate false
    pkill wf-recorder &
else
    filename="recording_$(getdate).mp4"
    if [[ $FULLSCREEN_FLAG -eq 1 ]]; then
        notify-send "Starting recording" "$filename" -a 'Recorder' -i media-record -t 3000 & disown
        updatestate true "fullscreen"
        if [[ $SOUND_FLAG -eq 1 ]]; then
            wf-recorder -o "$(getactivemonitor)" --pixel-format yuv420p -f "$filename" --audio="$(getaudiooutput)"
        else
            wf-recorder -o "$(getactivemonitor)" --pixel-format yuv420p -f "$filename"
        fi
    else
        # If a manual region was provided via --region, use it; otherwise run slurp as before.
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
