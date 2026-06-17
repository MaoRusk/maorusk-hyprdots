#!/bin/bash

PASS1="1234"
PASS2="todopaste.com"

if [ -z "$1" ]; then
    echo "Uso: $0 /ruta/al/directorio"
    exit 1
fi

DIR="$1"

find "$DIR" -type f \( -iname "*.rar" \) | while read -r file; do
    echo "Procesando: $file"

    DESTINO="$(dirname "$file")"

    if unrar t -inul -p"$PASS1" "$file"; then
        echo "✔ Contraseña correcta: $PASS1"
        unrar x -y -p"$PASS1" "$file" "$DESTINO/"
        continue
    fi

    if unrar t -inul -p"$PASS2" "$file"; then
        echo "✔ Contraseña correcta: $PASS2"
        unrar x -y -p"$PASS2" "$file" "$DESTINO/"
        continue
    fi

    echo "✘ Ninguna contraseña funcionó para: $file"
done
