#!/usr/bin/env bash

while true; do
    # Detectar si está conectado a corriente
    if grep -q "1" /sys/class/power_supply/AC*/online 2>/dev/null; then
        brightnessctl -d '*::kbd_backlight' set 100%
    fi
    sleep 5
done
