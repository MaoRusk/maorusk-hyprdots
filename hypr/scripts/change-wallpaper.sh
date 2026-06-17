#!/usr/bin/env bash

CONFIG="$HOME/.config/hypr/hyprpaper.conf"
STATE="$HOME/.config/hypr/.last_wallpapers"

MONITORS=($(hyprctl monitors | grep "Monitor" | awk '{print $2}'))

WALL1="$1"
WALL2="$2"

# Aplicar fondos
hyprctl hyprpaper preload "$WALL1"
hyprctl hyprpaper wallpaper "${MONITORS[0]},$WALL1"

if [ "${#MONITORS[@]}" -gt 1 ] && [ -n "$WALL2" ]; then
    hyprctl hyprpaper preload "$WALL2"
    hyprctl hyprpaper wallpaper "${MONITORS[1]},$WALL2"
fi

# Guardar estado (clave 🔥)
echo "${MONITORS[0]}|$WALL1" > "$STATE"

if [ "${#MONITORS[@]}" -gt 1 ] && [ -n "$WALL2" ]; then
    echo "${MONITORS[1]}|$WALL2" >> "$STATE"
fi

# También actualizar hyprpaper.conf
echo "" > "$CONFIG"

while IFS="|" read -r MON WALL; do
    echo "preload = $WALL" >> "$CONFIG"
    echo "wallpaper = $MON,$WALL" >> "$CONFIG"
done < "$STATE"