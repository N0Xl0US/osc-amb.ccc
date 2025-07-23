import requests

def get_weather(city_lat, city_lon):
    url = (
        f"https://api.open-meteo.com/v1/forecast"
        f"?latitude={city_lat}&longitude={city_lon}"
        f"&current=temperature_2m,cloudcover,windspeed_10m,relative_humidity_2m,winddirection_10m,pressure_msl,precipitation"
    )

    try:
        res = requests.get(url)
        res.raise_for_status()
        data = res.json()

        current = data["current"]
        temp = current.get("temperature_2m", 25.0)
        cloud = current.get("cloudcover", 50) / 100  
        wind = current.get("windspeed_10m", 2.0)
        humidity = current.get("relative_humidity_2m", 50) / 100
        wind_dir = current.get("winddirection_10m", 0)
        pressure = current.get("pressure_msl", 1013)
        precipitation = current.get("precipitation", 0.0)

        return temp, cloud, wind, humidity, wind_dir, pressure, precipitation
    except Exception as e:
        print("Error fetching weather:", e)
        return 25.0, 0.5, 2.0, 0.5, 0, 1013, 0.0
