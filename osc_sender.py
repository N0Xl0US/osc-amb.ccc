from pythonosc.udp_client import SimpleUDPClient
import config

client = SimpleUDPClient(config.SC_IP, config.SC_PORT)

def send_freq(freq):
    client.send_message("/temp", freq)

def send_amp(amp):
    client.send_message("/light", amp)

def send_reverb(reverb):
    client.send_message("/reverb", reverb)

def send_pan(pan):
    client.send_message("/pan", pan)

def send_cutoff(cutoff):
    client.send_message("/cutoff", cutoff)

def send_perc_trig(perc_trig):
    client.send_message("/perc_trig", perc_trig)

def send_perc_intensity(intensity):
    client.send_message("/perc_intensity", intensity)

def send_modspeed(mod_speed):
    client.send_message("/mod_speed", mod_speed)
