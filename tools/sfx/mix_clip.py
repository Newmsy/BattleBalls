#!/usr/bin/env python3
"""Mixes a fight's sounds (JSON from tools/sfx/fight_clip.gd) into one audio
file, the way the game layers them: each sound at its time, volume and pitch.
Music is left out. Usage: python3 tools/sfx/mix_clip.py cues.json out.wav|out.m4a
"""
import json
import subprocess
import sys
import wave

import numpy as np

SR = 32000


def load(path, cache={}):
    if path not in cache:
        with wave.open(path) as w:
            x = np.frombuffer(w.readframes(w.getnframes()), "<i2").astype(float) / 32768
            cache[path] = (x, w.getframerate())
    return cache[path]


def main():
    data = json.load(open(sys.argv[1]))
    out = np.zeros(int((data["length"] + 2.0) * SR))
    for c in data["cues"]:
        x, rate = load(c["file"])
        # Pitch shifts by playing faster, as Godot's pitch_scale does.
        step = rate / SR * c["pitch"]
        idx = np.arange(0, len(x) - 1, step)
        y = np.interp(idx, np.arange(len(x)), x) * 10 ** (c["db"] / 20)
        s = int(c["t"] * SR)
        out[s:s + len(y)] += y[:len(out) - s]
    out = np.tanh(out * 1.2) / np.tanh(1.2) # A soft limiter, like a busy phone speaker.
    target = sys.argv[2]
    wav_path = target if target.endswith(".wav") else target + ".tmp.wav"
    with wave.open(wav_path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes((np.clip(out, -1, 1) * 32767).astype("<i2").tobytes())
    if wav_path != target:
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wav_path, "-b:a", "128k", target], check=True)
        subprocess.run(["rm", wav_path])


if __name__ == "__main__":
    main()
