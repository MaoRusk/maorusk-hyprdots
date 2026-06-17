#!/usr/bin/env python3
import json, sys, urllib.request

API_KEY = "21475691915fdff68122ceca2651cd6e"
CITY = "Monterrey"
URL = f"https://api.openweathermap.org/data/2.5/weather?q={CITY}&appid={API_KEY}&units=metric&lang=es"

icons = {
    "01d": "󰖙", "01n": "󰖔", "02d": "󰖕", "02n": "󰼱",
    "03d": "󰖐", "03n": "󰖐", "04d": "󰖐", "04n": "󰖐",
    "09d": "󰖗", "09n": "󰖗", "10d": "󰖖", "10n": "󰖖",
    "11d": "󰙾", "11n": "󰙾", "13d": "󰖘", "13n": "󰖘",
    "50d": "󰖑", "50n": "󰖑"
}

field = sys.argv[1] if len(sys.argv) > 1 else "current_temp"

try:
    req = urllib.request.Request(URL, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req, timeout=5) as r:
        d = json.loads(r.read().decode())
    if field == "current_temp":
        print(round(d["main"]["temp"]))
    elif field == "weather_desc":
        print(d["weather"][0]["description"].capitalize())
    elif field == "feels_like":
        print(round(d["main"]["feels_like"]))
    elif field == "humidity":
        print(d["main"]["humidity"])
    elif field == "icon":
        print(icons.get(d["weather"][0]["icon"], "󰖐"))
    elif field == "wind":
        print(round(d["wind"]["speed"] * 3.6, 1))
    else:
        print("N/A")
except Exception:
    print("N/A")
