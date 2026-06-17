#!/bin/env bash

THUMB="/tmp/hyde-mpris"
THUMB_BLURRED="/tmp/hyde-mpris-blurred"
ART_INFO="${THUMB}.inf"
# Mismo tamaño que Spotify para todas las fuentes (640x640)
THUMB_SIZE=640
# Color del placeholder cuando no hay reproductor/arte (One Dark bg3)
PLACEHOLDER_COLOR="#1d2738"

cleanup() {
    rm -f "${THUMB}"* "${THUMB_BLURRED}.png" "${ART_INFO}"
}

# Crea una imagen placeholder válida para que hyprlock no falle si no hay arte
ensure_placeholder() {
    magick -size "${THUMB_SIZE}x${THUMB_SIZE}" "xc:${PLACEHOLDER_COLOR}" "${THUMB}.png" 2>/dev/null || true
}

# Obtiene el reproductor MPRIS actual (Spotify, Firefox, Chromium, etc.)
get_current_player() {
    playerctl -l 2>/dev/null | head -n 1
}

fetch_thumb() {
    local current_player artUrl
    current_player=$(get_current_player)
    if [[ -z "$current_player" ]]; then
        [[ -n "$PRELOCK" ]] && ensure_placeholder
        cleanup
        return 1
    fi

    artUrl=$(playerctl -p "$current_player" metadata --format '{{mpris:artUrl}}' 2>/dev/null)
    if [[ -z "$artUrl" ]]; then
        [[ -n "$PRELOCK" ]] && ensure_placeholder
        cleanup
        return 1
    fi

    # Omitir si la URL no ha cambiado (solo en modo normal, no prelock)
    if [[ -z "$PRELOCK" && -f "$ART_INFO" && "$(cat "$ART_INFO")" == "$artUrl" ]]; then
        return 0
    fi
    echo "$artUrl" > "$ART_INFO"

    if ! curl -sS "$artUrl" -o "${THUMB}.png"; then
        [[ -n "$PRELOCK" ]] && ensure_placeholder
        cleanup
        return 1
    fi
    magick "${THUMB}.png" -resize "${THUMB_SIZE}x${THUMB_SIZE}^" -gravity center -extent "${THUMB_SIZE}x${THUMB_SIZE}" -quality 50 "${THUMB}.png"
    magick "${THUMB}.png" -blur 200x7 -resize 1920x^ -gravity center -extent 1920x1080 "${THUMB_BLURRED}.png"
    [[ -z "$PRELOCK" ]] && pkill -USR2 hyprlock 2>/dev/null
    return 0
}

# Comprobar comandos necesarios
for cmd in playerctl curl magick; do
    command -v "$cmd" &>/dev/null || { echo "Error: $cmd is required but not installed."; exit 1; }
done
if [[ "$1" != "--prelock" ]]; then
    command -v pkill &>/dev/null || { echo "Error: pkill is required."; exit 1; }
fi

PRELOCK=""
[[ "$1" == "--prelock" ]] && PRELOCK=1

if [[ -n "$PRELOCK" ]]; then
    # Modo prelock: solo asegurar que el archivo exista (rápido). No descargar ni procesar.
    # Si ya hay miniatura (p. ej. del daemon), no hacer nada. Si no, crear placeholder.
    if [[ -f "${THUMB}.png" ]]; then
        exit 0
    fi
    ensure_placeholder
    exit 0
fi

# Modo normal: actualizar miniatura en segundo plano
current=$(get_current_player)
if [[ -n "$current" ]]; then
    fetch_thumb &
else
    cleanup &
fi

exit 0
