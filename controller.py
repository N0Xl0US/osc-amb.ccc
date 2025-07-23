import time
import config
from random import uniform
from data_fetch import get_weather
from microtonal import generate_microtonal_freq, just_intonation, quarter_tone
from osc_sender import send_freq, send_amp, send_reverb, send_pan, send_cutoff, send_modspeed

def scale(val, src_min, src_max, dst_min, dst_max):
    return dst_min + (dst_max - dst_min) * ((val - src_min) / (src_max - src_min))

def run_loop():
    while True:
        temp, cloud, wind, humidity, wind_dir, pressure, precipitation = get_weather(config.CITY_LAT, config.CITY_LON)
        light = 1.0 - cloud
        
        if wind > 10:
            freq = quarter_tone()
        elif wind > 5:
            freq = generate_microtonal_freq()
        else:
            freq = just_intonation()
        
        amp = scale(light, 0, 1, *config.AMP_RANGE)
        reverb = scale(humidity, 0, 1, 0, 1)
        pan = scale(wind_dir, 0, 360, -1, 1)
        cutoff = scale(pressure, 950, 1050, 500, 5000)
        mod_speed = uniform(0.05, 0.15)
        

        send_freq(freq)
        send_amp(amp)
        send_reverb(reverb)
        send_pan(pan)
        send_cutoff(cutoff)
        send_modspeed(mod_speed)

        print(f"→ Temp: {temp:.1f}°C | Light: {light:.2f} | Wind: {wind:.1f} | Humidity: {humidity:.2f} | WindDir: {wind_dir:.1f} | Pressure: {pressure:.1f} | Precip: {precipitation:.2f} → freq: {freq:.1f}, amp: {amp:.2f}, reverb: {reverb:.2f}, pan: {pan:.2f}, cutoff: {cutoff:.1f}")
        time.sleep(8)
