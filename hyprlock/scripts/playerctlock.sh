#!/bin/env bash

THUMB=/tmp/hyde-mpris
THUMB_BLURRED=/tmp/hyde-mpris-blurred
# Mismo tamaño para todas las fuentes (Spotify suele usar 640x640)
THUMB_SIZE=640

if [ $# -eq 0 ]; then
    echo "Usage: $0 --title | --arturl | --artist | --position | --length | --album | --source"
    exit 1
fi

# Obtiene el reproductor actual (el primero activo en playerctl)
get_current_player() {
    playerctl -l 2>/dev/null | head -n 1
}

# Function to get metadata using playerctl (reproductor actual por defecto)
get_metadata() {
    key=$1
    playerctl metadata --format "{{ $key }}" 2>/dev/null
}

# Function to determine the source and return an icon and text (cualquier reproductor MPRIS)
get_source_info() {
    local trackid player_name
    trackid=$(get_metadata "mpris:trackid")
    player_name=$(get_current_player)
    if [[ "$trackid" == *"spotify"* ]]; then
        echo -e "Spotify 󰓇 "
    elif [[ "$trackid" == *"firefox"* ]] || [[ "$player_name" == *"firefox"* ]]; then
        echo -e "Firefox 󰈹 "
    elif [[ "$trackid" == *"chromium"* ]] || [[ "$player_name" == *"chromium"* ]]; then
        echo -e "Chrome 󰊯 "
    elif [[ "$trackid" == *"youtube"* ]] || [[ "$player_name" == *"youtube"* ]] || [[ "$player_name" == *"YoutubeMusic"* ]]; then
        echo -e "YouTube 󰗃 "
    elif [[ -n "$player_name" ]]; then
        echo "${player_name}"
    else
        echo ""
    fi
}

# Function to get position using playerctl
get_position() {
    playerctl position 2>/dev/null
}

# Function to convert microseconds to minutes and seconds
convert_length() {
    local length=$1
    local seconds=$((length / 1000000))
    local minutes=$((seconds / 60))
    local remaining_seconds=$((seconds % 60))
    printf "%d:%02d min" $minutes $remaining_seconds
}

# Function to convert seconds to minutes and seconds
convert_position() {
    local position=$1
    local seconds=${position%.*} # Remove fractional part if exists
    local minutes=$((seconds / 60))
    local remaining_seconds=$((seconds % 60))
    printf "%d:%02d" $minutes $remaining_seconds
}

# Borra la caché de miniatura para no mostrar arte de un reproductor anterior
clear_thumb_cache() {
    rm -f "${THUMB}"* "${THUMB_BLURRED}.png" 2>/dev/null
    pkill -USR2 hyprlock 2>/dev/null
}

# Descarga la miniatura del reproductor actual (cualquier MPRIS: Spotify, Firefox, etc.)
fetch_thumb() {
    local artUrl current_player
    current_player=$(get_current_player)
    [[ -z "$current_player" ]] && { clear_thumb_cache; return 1; }

    artUrl=$(playerctl -p "$current_player" metadata --format '{{mpris:artUrl}}' 2>/dev/null)
    [[ -z "$artUrl" ]] && { clear_thumb_cache; return 1; }
    [[ -f "${THUMB}.inf" && "${artUrl}" = "$(cat "${THUMB}.inf")" ]] && return 0

    printf "%s\n" "$artUrl" > "${THUMB}.inf"
    curl -so "${THUMB}.png" "$artUrl" || { clear_thumb_cache; return 1; }
    magick "${THUMB}.png" -resize "${THUMB_SIZE}x${THUMB_SIZE}^" -gravity center -extent "${THUMB_SIZE}x${THUMB_SIZE}" -quality 50 "${THUMB}.png" || { clear_thumb_cache; return 1; }
    magick "${THUMB}.png" -blur 200x7 -resize 1920x^ -gravity center -extent 1920x1080\! "${THUMB_BLURRED}.png"
    pkill -USR2 hyprlock 2>/dev/null
}

# Si no hay reproductor, borrar caché para no mostrar imagen anterior
current=$(get_current_player)
if [[ -z "$current" ]]; then
    clear_thumb_cache
else
    { fetch_thumb; } &
fi

# Parse the argument
case "$1" in
--title)
    title=$(get_metadata "xesam:title")
    if [ -z "$title" ]; then
        echo ""
    else
        echo "${title:0:18}..." # Limit the output to 50 characters
    fi
    ;;
--artist)
    artist=$(get_metadata "xesam:artist")
    if [ -z "$artist" ]; then
        echo ""
    else
        echo "${artist:0:20}" #mit the output to 50 characters
    fi
    ;;
--position)
    position=$(get_position)
    length=$(get_metadata "mpris:length")
    if [ -z "$position" ] || [ -z "$length" ]; then
        echo ""
    else
        position_formatted=$(convert_position "$position")
        length_formatted=$(convert_length "$length")
        echo "$position_formatted/$length_formatted"
    fi
    ;;
--length)
    length=$(get_metadata "mpris:length")
    if [ -z "$length" ]; then
        echo ""
    else
        convert_length "$length"
    fi
    ;;
--status)
    status=$(playerctl status 2>/dev/null)
    if [[ $status == "Playing" ]]; then
        echo "⏸"
    elif [[ $status == "Paused" ]]; then
        echo "▶"
    else
        echo ""
    fi
    ;;
--album)
    album=$(playerctl metadata --format "{{ xesam:album }}" 2>/dev/null)
    if [[ -n $album ]]; then
        echo "$album"
    else
        status=$(playerctl status 2>/dev/null)
        if [[ -n $status ]]; then
            echo "Not album"
        else
            echo ""
        fi
    fi
    ;;
--source)
    get_source_info
    ;;
*)
    echo "Invalid option: $1"
    echo "Usage: $0 --title | --arturl | --artist | --position | --length | --album | --source"
    exit 1
    ;;
esac
