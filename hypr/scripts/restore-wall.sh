#!/usr/bin/env bash
set -euo pipefail

CONF="$HOME/.config/hypr/wallpaper.conf"
WALT_STATE="$HOME/.config/walt/rotation-state.json"

usage() {
  cat <<'EOF'
Uso:
  restore-wall.sh --apply
    Aplica el último wallpaper guardado (prioridad):
      1) ~/.config/hypr/wallpaper.conf (si existe y tiene entradas)
      2) ~/.config/walt/rotation-state.json (last_wallpaper)

  restore-wall.sh <imagen> [monitor]
    Guarda y aplica <imagen>. Si no se indica monitor, aplica a todos los monitores activos.

Notas:
  - Requiere hyprpaper con ipc=true (ya lo tienes).
  - Este script usa hyprctl hyprpaper (no edita hyprpaper.conf).
EOF
}

get_monitors() {
  hyprctl monitors -j 2>/dev/null | rg -o '"name":"[^"]+"' | cut -d'"' -f4
}

wait_for_hyprpaper() {
  # Espera breve a que hyprpaper IPC esté listo
  for _ in {1..30}; do
    if hyprctl hyprpaper listloaded >/dev/null 2>&1; then
      return 0
    fi
    sleep 0.1
  done
  return 1
}

apply_img_to_monitor() {
  local img="$1"
  local mon="$2"
  hyprctl hyprpaper preload "$img" >/dev/null 2>&1 || true
  hyprctl hyprpaper wallpaper "$mon,$img" >/dev/null 2>&1 || true
}

apply_from_conf() {
  [[ -f "$CONF" ]] || return 1
  rg -q '^wallpaper = ' "$CONF" || return 1

  # Preloads
  rg '^preload = ' "$CONF" | sed -E 's/^preload = //' | while IFS= read -r img; do
    [[ -n "$img" ]] && hyprctl hyprpaper preload "$img" >/dev/null 2>&1 || true
  done

  # Wallpapers
  rg '^wallpaper = ' "$CONF" | sed -E 's/^wallpaper = //' | while IFS= read -r pair; do
    mon="${pair%%,*}"
    img="${pair#*,}"
    [[ -n "$mon" && -n "$img" ]] && apply_img_to_monitor "$img" "$mon"
  done
}

extract_walt_last_wallpaper() {
  [[ -f "$WALT_STATE" ]] || return 1
  rg -o '"last_wallpaper"\s*:\s*"[^"]+"' "$WALT_STATE" | head -n 1 | cut -d'"' -f4
}

save_conf_all_monitors() {
  local img="$1"
  mkdir -p "$(dirname "$CONF")"

  # Regeneramos el archivo para evitar duplicados y mantenerlo consistente
  : > "$CONF"
  echo "preload = $img" >> "$CONF"
  while IFS= read -r mon; do
    echo "wallpaper = $mon,$img" >> "$CONF"
  done < <(get_monitors)
}

save_conf_one_monitor() {
  local img="$1"
  local mon="$2"
  mkdir -p "$(dirname "$CONF")"
  touch "$CONF"

  # Quitar línea previa de ese monitor
  rg -v "^wallpaper = ${mon}," "$CONF" > "$CONF.tmp" || true
  mv "$CONF.tmp" "$CONF"

  # Evitar duplicar preload infinitamente: regeneramos preloads únicos
  # (si ya existe, no lo repetimos)
  if ! rg -qF "preload = $img" "$CONF"; then
    echo "preload = $img" >> "$CONF"
  fi
  echo "wallpaper = $mon,$img" >> "$CONF"
}

main() {
  if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
    exit 0
  fi

  if ! wait_for_hyprpaper; then
    exit 0
  fi

  if [[ "${1:-}" == "--apply" ]]; then
    if apply_from_conf; then
      exit 0
    fi

    img="$(extract_walt_last_wallpaper || true)"
    if [[ -n "${img:-}" ]]; then
      save_conf_all_monitors "$img"
      while IFS= read -r mon; do
        apply_img_to_monitor "$img" "$mon"
      done < <(get_monitors)
    fi
    exit 0
  fi

  img="${1:-}"
  mon="${2:-}"

  [[ -n "$img" ]] || { usage; exit 1; }

  if [[ -z "$mon" || "$mon" == "all" ]]; then
    save_conf_all_monitors "$img"
    while IFS= read -r m; do
      apply_img_to_monitor "$img" "$m"
    done < <(get_monitors)
  else
    save_conf_one_monitor "$img" "$mon"
    apply_img_to_monitor "$img" "$mon"
  fi
}

main "$@"