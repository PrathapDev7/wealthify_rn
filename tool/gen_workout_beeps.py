"""Generates the workout timer's beeps.

Synthesised rather than sourced so the cues stay tiny (a few KB of PCM), carry
no licence, and can be retuned by editing three numbers instead of hunting for
another sample.

Run from the app root:  python tool/gen_workout_beeps.py
Writes into assets/sounds/, which pubspec.yaml ships.
"""

import math
import os
import struct
import wave

RATE = 22050  # Plenty for a sine under 1.5 kHz, and half the size of 44.1k.
AMPLITUDE = 0.55  # Loud enough to hear over a gym, short of clipping.
OUT_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "assets", "sounds")


def tone(freq, ms, gain=1.0):
    """One note, with a 6 ms fade either end so it starts and stops without a click."""
    total = int(RATE * ms / 1000)
    fade = max(1, int(RATE * 0.006))
    samples = []
    for i in range(total):
        envelope = min(1.0, i / fade, (total - i) / fade)
        samples.append(AMPLITUDE * gain * envelope * math.sin(2 * math.pi * freq * i / RATE))
    return samples


def silence(ms):
    return [0.0] * int(RATE * ms / 1000)


def write(name, samples):
    path = os.path.join(OUT_DIR, name)
    with wave.open(path, "w") as out:
        out.setnchannels(1)
        out.setsampwidth(2)
        out.setframerate(RATE)
        out.writeframes(b"".join(
            struct.pack("<h", int(max(-1.0, min(1.0, s)) * 32767)) for s in samples
        ))
    print(f"{name}: {os.path.getsize(path) / 1024:.1f} KB")


# The four cues, deliberately distinguishable without looking at the screen:
# one blip acknowledges, a rising pair means go, three flat blips mean the rest
# is over, and the fanfare only ever plays once.
CUES = {
    # A set was ticked off.
    "set_done.wav": tone(880, 90),
    # The workout just started.
    "workout_start.wav": tone(660, 110) + silence(40) + tone(990, 140),
    # Rest is over, next set now.
    "rest_over.wav": tone(1046, 80) + silence(70) + tone(1046, 80) + silence(70) + tone(1318, 160),
    # The whole workout is done.
    "workout_done.wav": tone(660, 120) + tone(880, 120) + tone(1318, 260),
}

if __name__ == "__main__":
    os.makedirs(OUT_DIR, exist_ok=True)
    for filename, samples in CUES.items():
        write(filename, samples)
