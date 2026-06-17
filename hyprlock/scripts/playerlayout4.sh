#!/bin/env bash

THUMB=/tmp/hyde-mpris
THUMB_BLURRED=/tmp/hyde-mpris-blurred
# Mismo tamaño que Spotify para todas las fuentes (640x640)
THUMB_SIZE=640

if [ $# -eq 0 ]; then
    echo "Usage: $0 --title | --arturl | --artist | --position | --length | --album | --source"
    exit 1
fi

# Function to get metadata using playerctl
get_metadata() {
    key=$1
    playerctl metadata --format "{{ $key }}" 2>/dev/null
    

}

# Function to determine the source and return an icon and text
get_source_info() {
    trackid=$(get_metadata "mpris:trackid")
    if [[ "$trackid" == *"firefox"* ]]; then
        echo -e "Firefox 󰈹 "
    elif [[ "$trackid" == *"spotify"* ]]; then
        echo -e "Spotify  "
    elif [[ "$trackid" == *"chromium"* ]]; then
        echo -e "Chrome  "
    elif [[ "$trackid" == *"YoutubeMusic"* ]]; then
        echo -e "YouTubeMusic  "
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
    printf "%d:%02d m" $minutes $remaining_seconds
}

# Function to convert seconds to minutes and seconds
convert_position() {
    local position=$1
    local seconds=${position%.*} # Remove fractional part if exists
    local minutes=$((seconds / 60))
    local remaining_seconds=$((seconds % 60))
    printf "%d:%02d" $minutes $remaining_seconds
}

# Obtiene el reproductor MPRIS actual
get_current_player() {
    playerctl -l 2>/dev/null | head -n 1
}

# Borra la caché de miniatura para no mostrar arte de un reproductor anterior
clear_thumb_cache() {
    rm -f "${THUMB}"* "${THUMB_BLURRED}.png" 2>/dev/null
    pkill -USR2 hyprlock 2>/dev/null
}

# Descarga la miniatura del reproductor actual (cualquier MPRIS)
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
    pkill -USR2 hyprlock 2>/dev/null
}

# Si no hay reproductor, borrar caché; si hay, actualizar miniatura en segundo plano
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
--arturl)
    url=$(get_metadata "mpris:artUrl")
    if [[ -z "$url" ]] || [[ "$(playerctl status 2>/dev/null)" != "Playing" ]]; then
        rm -f /tmp/hyde-mpris* 2>/dev/null
    fi
    ;;
--artist)
    artist=$(get_metadata "xesam:artist")
    if [ -z "$artist" ]; then
        echo ""
    else
        echo "${artist:0:20}" # Limit the output to 50 characters
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
        echo "󰎆"
    elif [[ $status == "Paused" ]]; then
        echo "󱑽"
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
    echo "Usage: $0 --title | --arturl | --artist | --position | --length | --album | --source" ; exit 1
    ;;
esac
