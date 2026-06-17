#!/usr/bin/env bash

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
# Asegurar que /tmp/hyde-mpris.png exista antes de bloquear (evita errores de hyprlock)
"$SCRIPT_DIR/hlock_mpris.sh" --prelock 2>/dev/null || true

if [[ "$(playerctl -p spotify status 2>/dev/null)" == "Playing" ]]; then
    pkill glava

    # Start Glava (NOT desktop mode)
    glava &
    sleep 0.6

    # Focus Glava window
    hyprctl dispatch focuswindow class:glava
    sleep 0.1

    # Fullscreen focused window
    hyprctl dispatch fullscreen 

    # Lock screen
    hyprlock --config ~/.config/hyprlock/music.conf
else
    hyprlock
fi

pkill glava
