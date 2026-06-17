#!/usr/bin/env sh
# Abre o cierra la ventana `time` de Eww (mismo widget que en eww.yuck).
EWW_DIR="${EWW_DIR:-$HOME/.config/eww/left_bar}"

if ! eww -c "$EWW_DIR" ping >/dev/null 2>&1; then
	eww -c "$EWW_DIR" daemon
	# Esperar a que el socket del daemon esté listo
	i=0
	while ! eww -c "$EWW_DIR" ping >/dev/null 2>&1 && [ "$i" -lt 30 ]; do
		sleep 0.1
		i=$((i + 1))
	done
fi

exec eww -c "$EWW_DIR" open --toggle time
