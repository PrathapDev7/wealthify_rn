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

RATE = 22050  # Plenty for a tone under 5 kHz, and half the size of 44.1k.
AMPLITUDE = 0.55  # Loud enough to hear over a gym, short of clipping.
OUT_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "assets", "sounds")


def tone(freq, ms, gain=1.0, sharp=False, fade_ms=6.0):
    """One note, fading either end so it starts and stops without a click.

    sharp=True adds 2nd/3rd harmonics so the cue cuts through gym noise
    instead of sounding like a soft sine blip. A longer fade (tens of ms)
    softens the attack into a rounder, more professional timer chime.
    """
    total = int(RATE * ms / 1000)
    fade = max(1, int(RATE * fade_ms / 1000))
    samples = []
    for i in range(total):
        envelope = min(1.0, i / fade, (total - i) / fade)
        s = math.sin(2 * math.pi * freq * i / RATE)
        if sharp:
            s += 0.35 * math.sin(2 * math.pi * freq * 2 * i / RATE)
            s += 0.15 * math.sin(2 * math.pi * freq * 3 * i / RATE)
            s /= 1.5
        samples.append(AMPLITUDE * gain * envelope * s)
    return samples


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


# The rest-over cue: a single soft 1 s chime — pure sine, no harsh harmonics,
# gentle 60 ms fades so it reads as a professional timer, not an OS alert.
CUES = {
    "workout_beep.wav": tone(1046, 1000, fade_ms=60),
}

if __name__ == "__main__":
    os.makedirs(OUT_DIR, exist_ok=True)
    for filename, samples in CUES.items():
        write(filename, samples)
