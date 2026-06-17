#!/usr/bin/env python3

import json
import urllib.request
import urllib.error
import sys

API_KEY = "21475691915fdff68122ceca2651cd6e"
CITY = "Monterrey"
URL = f"https://api.openweathermap.org/data/2.5/weather?q={CITY}&appid={API_KEY}&units=metric&lang=es"

def main():
    try:
        req = urllib.request.Request(URL, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req, timeout=5) as response:
            data = json.loads(response.read().decode())
        
        temp = round(data['main']['temp'])
        description = data['weather'][0]['description']
        icon_code = data['weather'][0]['icon']
        
        # Determine icon based on OpenWeatherMap icon code
        # Format mapping: https://openweathermap.org/weather-conditions
        icons = {
            "01d": "󰖙", "01n": "󰖔",
            "02d": "󰖕", "02n": "󰼱",
            "03d": "󰖐", "03n": "󰖐",
            "04d": "󰖐", "04n": "󰖐",
            "09d": "󰖗", "09n": "󰖗",
            "10d": "󰖖", "10n": "󰖖",
            "11d": "󰙾", "11n": "󰙾",
            "13d": "󰖘", "13n": "󰖘",
            "50d": "󰖑", "50n": "󰖑"
        }
        
        icon = icons.get(icon_code, "󰖐")
        text = f"{icon} {temp}°C"

        feels_like = round(data['main']['feels_like'])
        temp_min = round(data['main']['temp_min'])
        temp_max = round(data['main']['temp_max'])
        humidity = data['main']['humidity']
        wind_speed = round(data['wind']['speed'] * 3.6)  # m/s -> km/h
        pressure = data['main']['pressure']
        city_name = data['name']
        country = data['sys']['country']

        sep = "<span size='4096'> </span>"

        tooltip = (
            f"<span size='xx-large' weight='bold'>{icon}  {temp}°C</span>\n"
            f"<span size='large' color='#aaaaaa'>{description.capitalize()}</span>\n"
            f"<span size='small' color='#666666'>📍 {city_name}, {country}</span>\n"
            f"{sep}\n"
            f"<span color='#ffcc66'>🤔  Sensación</span>     <span weight='bold'>{feels_like}°C</span>\n"
            f"<span color='#88ccff'>⬇️  Mínima</span>         <span weight='bold'>{temp_min}°C</span>\n"
            f"<span color='#ff8888'>⬆️  Máxima</span>         <span weight='bold'>{temp_max}°C</span>\n"
            f"{sep}\n"
            f"<span color='#88ddff'>💧  Humedad</span>       <span weight='bold'>{humidity}%</span>\n"
            f"<span color='#aaffaa'>💨  Viento</span>           <span weight='bold'>{wind_speed} km/h</span>\n"
            f"<span color='#ccaaff'>🔵  Presión</span>          <span weight='bold'>{pressure} hPa</span>"
        )

        print(json.dumps({"text": text, "tooltip": tooltip}))
        
    except Exception as e:
        print(json.dumps({"text": "󰖐 N/A", "tooltip": str(e)}))

if __name__ == "__main__":
    main()
