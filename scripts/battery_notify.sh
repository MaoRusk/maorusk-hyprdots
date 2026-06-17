#!/usr/bin/env bash

LAST_NOTIFIED=""

while true; do
    BAT=$(cat /sys/class/power_supply/BAT*/capacity)
    STATUS=$(cat /sys/class/power_supply/BAT*/status)

    if [[ "$STATUS" != "Charging" ]]; then
        if [[ "$BAT" == "15" && "$LAST_NOTIFIED" != "15" ]]; then
            notify-send -u normal "󰚥 Low Battery" "15% remaining"
            LAST_NOTIFIED="15"
        elif [[ "$BAT" == "10" && "$LAST_NOTIFIED" != "10" ]]; then
            notify-send -u critical " Very Low Battery" "10% remaining"
            LAST_NOTIFIED="10"
        elif [[ "$BAT" == "5" && "$LAST_NOTIFIED" != "5" ]]; then
            notify-send -u critical " Critical Battery" "5% remaining"
            LAST_NOTIFIED="5"
        fi
    fi

    sleep 60
done