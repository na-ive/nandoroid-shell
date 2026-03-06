#!/bin/bash

STATE_FILE="/tmp/ryzen_mode"

apply_ryzenadj() {
    # $1=Power(mW), $2=Temp(C), $3=Time(Sec)
    sudo ryzenadj \
        --stapm-limit=$1 --fast-limit=$1 --slow-limit=$1 \
        --tctl-temp=$2 --stapm-time=$3 --slow-time=$3 \
        --vrm-current=45000 > /dev/null 2>&1
}

while true; do
    MODE=$(cat $STATE_FILE 2>/dev/null || echo "daily")

    case $MODE in
        "performance"|"gaming")
            apply_ryzenadj 25000 92 3600
            ;;
        "work"|"balanced")
            apply_ryzenadj 20000 82 120
            ;;
        *)
            apply_ryzenadj 15000 75 60
            ;;
    esac

    sleep 5
done
