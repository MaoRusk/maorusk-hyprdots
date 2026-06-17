#!/usr/bin/env bash

THEMES_DIR="$HOME/.config/color-schemas"

choice=$(ls "$THEMES_DIR" | grep -v current | rofi -dmenu -theme ~/.config/rofi/color-schema/color-schema.rasi)
# choice=$(ls "$THEMES_DIR" | grep -v current | rofi -dmenu -p "Theme")
# -theme ${dir}/app-launcher.rasi

[ -z "$choice" ] && exit 0

CURRENT_DIR="$THEMES_DIR/current"
SOURCE_DIR="$THEMES_DIR/$choice"

if [ -L "$CURRENT_DIR" ]; then
  rm -f "$CURRENT_DIR"
fi

mkdir -p "$CURRENT_DIR"

rsync -a --delete -- "$SOURCE_DIR"/ "$CURRENT_DIR"/

killall -9 waybar
waybar &
killall -9 swaync
swaync &
killall -9 wifi-manager
wifi-manager &

notify-send "Theme switched" "$choice theme selected"
