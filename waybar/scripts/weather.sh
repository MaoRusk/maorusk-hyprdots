#!/bin/bash

# A simple script to get weather from wttr.in and handle errors gracefully

WEATHER=$(curl -s --max-time 5 'https://wttr.in/?format=1' || echo "")

if [ -z "$WEATHER" ] || [[ "$WEATHER" == *"Unknown location"* ]] || [[ "$WEATHER" == *"503"* ]]; then
    # Return a fallback text so the Waybar module doesn't disappear completely
    echo "󰖐 N/A"
else
    # Output the downloaded weather
    echo "$WEATHER"
fi
