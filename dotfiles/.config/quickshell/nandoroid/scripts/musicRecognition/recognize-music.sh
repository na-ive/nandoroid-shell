#!/bin/bash
# Ported from 'ii'
# NANDOROID Music Recognition Script
# Optimized to use native songrec recognition

INTERVAL=5
TOTAL_DURATION=30
SOURCE_TYPE="monitor"  # monitor | input

while getopts "i:t:s:" opt; do
  case $opt in
    i) INTERVAL=$OPTARG ;;
    t) TOTAL_DURATION=$OPTARG ;;
    s) SOURCE_TYPE=$OPTARG ;;
    *) exit 1 ;;
  esac
done

# Try to find the device string for songrec
if [ "$SOURCE_TYPE" = "monitor" ]; then
    # Look for the default sink's monitor
    DEFAULT_SINK=$(pactl get-default-sink)
    DEVICE_STRING=$(songrec recognize -l | grep "$DEFAULT_SINK.monitor" | head -n 1 | awk '{print $4}')
    
    # Fallback: just search for any monitor if specific one fails
    if [ -z "$DEVICE_STRING" ]; then
        DEVICE_STRING=$(songrec recognize -l | grep ".monitor" | head -n 1 | awk '{print $4}')
    fi
else
    # Look for default input source
    DEFAULT_SOURCE=$(pactl get-default-source)
    DEVICE_STRING=$(songrec recognize -l | grep "$DEFAULT_SOURCE" | head -n 1 | awk '{print $4}')
    
    # Fallback: search for any analog-stereo input
    if [ -z "$DEVICE_STRING" ]; then
        DEVICE_STRING=$(songrec recognize -l | grep "input" | grep -v ".monitor" | head -n 1 | awk '{print $4}')
    fi
fi

if ! command -v songrec >/dev/null 2>&1; then
    exit 1
fi

# Run songrec directly. -j for JSON, -i for interval.
# We use timeout command to limit the duration.
if [ -n "$DEVICE_STRING" ]; then
    timeout "$TOTAL_DURATION" songrec recognize -j -d "$DEVICE_STRING" -i "$INTERVAL"
else
    # Last resort: just use default mic
    timeout "$TOTAL_DURATION" songrec recognize -j -i "$INTERVAL"
fi
