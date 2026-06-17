#!/usr/bin/env bash
set -euo pipefail

BASE="$HOME/.config/theme-switcher"
THEMES_DIR="$BASE/themes"
THEME_JSON="theme.json"
THUMB_GEN="$BASE/thumb-gen.sh"

declare -A MAP
declare -A ICON_MAP
keys=()

while IFS= read -r -d '' dir; do
  id="$(basename "$dir")"
  file="$dir/$THEME_JSON"
  name="$id"
  preview=""

  if [[ -f "$file" ]]; then
    name="$(jq -r '.name // empty' "$file" || echo "$id")"
    json_id="$(jq -r '.id // empty' "$file" || echo "$id")"
    [[ -n "${name:-}" ]] || name="$id"
    [[ -n "${json_id:-}" ]] && id="$json_id"
    
    # Buscar preview: preview.png > wallpaper en theme.json > primer .jpg/.png
    if [[ -f "$dir/preview.png" ]]; then
        preview="$dir/preview.png"
    else
        wp_rel="$(jq -r '.default_wallpaper // empty' "$file")"
        if [[ -n "$wp_rel" && -f "$dir/$wp_rel" ]]; then
            preview="$dir/$wp_rel"
        else
            preview="$(find "$dir" -maxdepth 1 -type f \( -name "*.jpg" -o -name "*.png" \) | head -n1)"
        fi
    fi
  fi

  key="$name"
  if [[ -n "${MAP[$key]+x}" ]]; then
    key="$name [$id]"
  fi

  MAP["$key"]="$id"
  if [[ -n "$preview" ]]; then
      thumb=$("$THUMB_GEN" "$preview")
      ICON_MAP["$key"]="$thumb"
  fi
  keys+=("$key")
done < <(find "$THEMES_DIR" -mindepth 1 -maxdepth 1 -type d -print0)

choices_sorted="$(printf "%s\n" "${keys[@]}" | sort -f)"
menu_data=""
while IFS= read -r key; do
    [[ -z "$key" ]] && continue
    if [[ -n "${ICON_MAP[$key]:-}" ]]; then
        menu_data+="${key}\x00icon\x1f${ICON_MAP[$key]}\n"
    else
        menu_data+="${key}\n"
    fi
done <<< "$choices_sorted"

choice="$(echo -ne "$menu_data" | rofi -dmenu -i -p "Theme" -config ~/.config/rofi/theme-picker.rasi)"
[[ -z "${choice:-}" ]] && exit 0

theme_id="${MAP[$choice]}"
"$BASE/apply-theme.sh" "$theme_id"
