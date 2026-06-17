#!/usr/bin/env bash
# Waybar custom/updates: solo muestra el icono si hay actualizaciones pendientes (sin contador).

count=$(checkupdates 2>/dev/null | wc -l)

if [ "$count" -eq 0 ]; then
  printf '%s\n' '{"text":"","class":"updated"}'
else
  printf '%s\n' '{"text":"","class":"pending"}'
fi
