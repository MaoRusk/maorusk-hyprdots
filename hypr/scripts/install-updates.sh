#!/usr/bin/env bash
#     _             _        _   _           _       _
#    / \   _ __ ___| |__    | | | |_ __   __| | __ _| |_ ___  ___
#   / _ \ | '__/ __| '_ \   | | | | '_ \ / _` |/ _` | __/ _ \/ __|
#  / ___ \| | | (__| | | |  | |_| | |_) | (_| | (_| | ||  __/\__ \
# /_/   \_\_|  \___|_| |_|   \___/| .__/ \__,_|\__,_|\__\___||___/
#                                  |_|

sleep 0.5
clear

cat << "EOF"
     _             _        _   _           _       _
    / \   _ __ ___| |__    | | | |_ __   __| | __ _| |_ ___  ___
   / _ \ | '__/ __| '_ \   | | | | '_ \ / _` |/ _` | __/ _ \/ __|
  / ___ \| | | (__| | | |  | |_| | |_) | (_| | (_| | ||  __/\__ \
 /_/   \_\_|  \___|_| |_|   \___/| .__/ \__,_|\__,_|\__\___||___/
                                  |_|
EOF

# Header
if command -v figlet >/dev/null 2>&1; then
    figlet -f smslant "Arch Updates"
else
    echo "=== Arch Updates ==="
fi
echo

# Confirmation
if command -v gum >/dev/null 2>&1; then
    gum confirm "DO YOU WANT TO START THE UPDATE NOW?" || {
        echo
        echo ":: Update cancelled."
        sleep 1
        exit 0
    }
else
    read -rp "Start update? [y/N]: " confirm
    [[ "$confirm" =~ ^[Yy]$ ]] || {
        echo
        echo ":: Update cancelled."
        exit 0
    }
fi

echo
echo ":: Starting update..."
echo

# System update (pacman + AUR)
if command -v yay >/dev/null 2>&1; then
    yay -Syu --needed
else
    echo ":: yay is not installed, using pacman..."
    sudo pacman -Syu --needed
fi

echo

# Flatpak (if available)
if command -v flatpak >/dev/null 2>&1; then
    echo ":: Checking Flatpak updates..."
    flatpak update -y
    echo
fi

echo
echo ":: Done! Press [ENTER] to exit."
read