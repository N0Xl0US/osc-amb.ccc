import random
import math

def generate_microtonal_freq(base=440, steps=10):
    ratio = 2 ** (1 / steps)
    return base * (ratio ** random.randint(-10, 10))

def just_intonation(base=220):
    ratios = [1/1, 9/8, 5/4, 4/3, 3/2, 5/3, 15/8]
    return base * random.choice(ratios)

def quarter_tone(base=440):
    ratio = 2 ** (1 / 24)
    return base * (ratio ** random.randint(-12, 12))
