# OSC Ambient Weather Synth

This project generates ambient music in SuperCollider, driven by real-time weather data. It fetches weather information for a configurable location and sends musical parameters (frequency, amplitude, reverb, pan, filter cutoff) via OSC to a SuperCollider synth, creating evolving soundscapes based on the current weather.

## Features
- Fetches live weather data (temperature, cloud cover, wind, humidity, wind direction, pressure, precipitation)
- Maps weather parameters to musical controls
- Supports microtonal, just intonation, and quarter-tone scales
- Sends OSC messages to SuperCollider for real-time sound synthesis
- Includes a SuperCollider script for ambient drone and drum synths

## Requirements
- Python 3.7+
- [SuperCollider](https://supercollider.github.io/) (for running `SC.scd`)
- Python packages: `python-osc`, `requests`

## Installation
1. Clone this repository.
2. Install Python dependencies:
   ```bash
   pip install -r requirement.txt
   ```
3. Install [SuperCollider](https://supercollider.github.io/download) if you haven't already.

## Configuration
Edit `config.py` to set your desired location and OSC connection:
- `CITY_LAT`, `CITY_LON`: Latitude and longitude for weather data
- `SC_IP`, `SC_PORT`: IP and port for SuperCollider OSC server (default: 127.0.0.1:57120)
- `FREQ_RANGE`, `AMP_RANGE`: Ranges for musical parameters

## Usage
1. **Start SuperCollider:**
   - Open `SC.scd` in the SuperCollider IDE.
   - Evaluate the entire file (Ctrl+A, then Ctrl+Enter) to boot the server, load synths, and set up OSC responders.
2. **Run the Python script:**
   ```bash
   python run.py
   ```
   The script will fetch weather data every 8 seconds and send OSC messages to SuperCollider, modulating the ambient synth in real time.

## Files
- `run.py`: Main entry point. Runs the weather-to-OSC loop.
- `controller.py`: Main logic for mapping weather to sound parameters.
- `data_fetch.py`: Fetches weather data from Open-Meteo API.
- `microtonal.py`: Functions for generating microtonal, just intonation, and quarter-tone frequencies.
- `osc_sender.py`: Sends OSC messages to SuperCollider.
- `config.py`: Configuration for location and OSC connection.
- `SC.scd`: SuperCollider script for synth definitions and OSC responders.
- `requirement.txt`: Python dependencies.

## Notes
- No API key is required for weather data (uses Open-Meteo).
- You can customize the synths or OSC mappings in `SC.scd`.
- The script prints weather and sound parameters to the console for monitoring.

## License
MIT License (add your own if needed) 