#!/usr/bin/env bash
set -Eeuo pipefail

wallpaperDir="$HOME/Pictures/walt"
rofiTheme="$HOME/.config/rofi/wall-launcher/wallpaper-select.rasi"

need() { command -v "$1" >/dev/null 2>&1; }
need rofi || { notify-send -u critical "Falta dependencia: rofi"; exit 1; }
need awww || { notify-send -u critical "Falta dependencia: awww"; exit 1; }
need realpath || { notify-send -u critical "Falta dependencia: realpath"; exit 1; }

wallpaper_real="$(realpath -e "$wallpaperDir")"

list_wallpapers() {
  find "$wallpaper_real" -type f \
    \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" \) \
    -print0 | sort -z
}

generate_menu() {
  local wp rel
  while IFS= read -r -d '' wp; do
    rel="${wp#"$wallpaper_real"/}"
    # Rofi devuelve el "texto" de la entrada. Usamos la ruta completa como valor real,
    # y mostramos la ruta relativa para evitar duplicados.
    printf '%s\0icon\x1f%s\n' "$wp" "$wp"
  done < <(list_wallpapers)
}

apply_wallpaper() {
  local wp="$1"
  local wp_real

  # Si rofi devolvió una ruta relativa, la resolvemos dentro de $wallpaperDir.
  if [[ "$wp" != /* ]]; then
    wp="$wallpaper_real/$wp"
  fi

  wp_real="$(realpath -e "$wp")"

  case "$wp_real" in
    "$wallpaper_real"/*) ;;
    *)
      notify-send -u critical "Wallpaper inválido" "Solo se permiten archivos en: $wallpaperDir"
      exit 1
      ;;
  esac

  awww img "$wp_real" \
    --transition-type random \
    --resize fit \
    --transition-duration 1 \
    --transition-fps 60 \
    --transition-bezier 0.4,0.2,0.2,1
}

open_menu() {
  local selected

  if [[ -f "$rofiTheme" ]]; then
    selected="$(generate_menu | rofi -dmenu -p "Wallpaper" -show-icons -markup-rows -theme "$rofiTheme")"
  else
    selected="$(generate_menu | rofi -dmenu -p "Wallpaper" -show-icons -markup-rows)"
  fi

  [[ -z "${selected:-}" ]] && exit 0
  apply_wallpaper "$selected"
}

open_menu
