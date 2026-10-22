#!/usr/bin/env python3
"""Builds the game's music from "Crypto" by Kevin MacLeod (incompetech.com),
licensed under Creative Commons: By Attribution 4.0
(https://creativecommons.org/licenses/by/4.0/). CC-BY allows adaptations;
the credit lives in CREDITS.md and on the in-game credits line.

Crypto is 80 BPM (one bar = 3.0 s), in F# major. From it:
- music_intro:    its opening bars, a riser and a big F# hit (~9 s, plays once).
- music_menu:     a 32-bar seamless loop of the track itself.
- music_fight:    16 bars sped up to 100 BPM (pitch kept) with added drums.
- music_overtime: 8 bars at 120 BPM with busier drums.
- music_victory:  a one-bar F# brass hit, then an 8-bar loop at 88 BPM with
                  claps (VICTORY_LOOP_FROM in sfx.gd = the hit's length).

Usage: python3 tools/music/remix_crypto.py [--src Crypto.mp3] [--out DIR] [--wav DIR]
The source mp3 is downloaded from incompetech if --src is missing.
Needs numpy, scipy and ffmpeg (libvorbis, libmp3lame).
"""
import argparse
import os
import subprocess
import sys
import tempfile
import urllib.request

import numpy as np

sys.path.insert(0, os.path.dirname(__file__))
from make_music import SR, boom, brass, clap, crash, hat, kick, riser, snare, write_wav  # noqa: E402

SRC_URL = "https://incompetech.com/music/royalty-free/mp3-royaltyfree/Crypto.mp3"
OUT = os.path.join(os.path.dirname(__file__), "..", "..", "game", "audio")
BAR = 3.0  # Seconds per bar at Crypto's 80 BPM; beat 1 of bar 0 is at 0.0 s.
F_SHARP = (66, 70, 73, 78)  # F#4 A#4 C#5 F#5: the track's home chord.


def load(path, tempo=1.0):
    """Decodes to (2, n) float at SR, optionally time-stretched (pitch kept)."""
    args = ["ffmpeg", "-v", "error", "-i", path, "-ac", "2", "-ar", str(SR)]
    if tempo != 1.0:
        args += ["-af", "atempo=%.4f" % tempo]
    raw = subprocess.run(args + ["-f", "s16le", "-"], capture_output=True, check=True).stdout
    return (np.frombuffer(raw, "<i2").reshape(-1, 2).T / 32768.0).copy()


def secs(t):
    return int(round(t * SR))


def add(buf, sig, t, gain=1.0, pan=0.0, wrap=True):
    """Mixes mono or stereo sig into buf at t seconds; wraps past the end for loops."""
    if sig.ndim == 1:
        a = (pan + 1) * np.pi / 4
        sig = np.vstack([sig * np.cos(a) * 1.414, sig * np.sin(a) * 1.414])
    s = secs(t)
    n = buf.shape[1]
    end = s + sig.shape[1]
    if end <= n:
        buf[:, s:end] += sig * gain
    else:
        buf[:, s:n] += sig[:, :n - s] * gain
        if wrap:
            rest = sig[:, n - s:]
            buf[:, :rest.shape[1]] += rest[:, :n] * gain


def seam_loop(x, start, length, fade=0.3):
    """x[start:start+length] whose last `fade` seconds blend into the audio just
    before `start`, so the loop's end flows straight into its beginning."""
    a, n, f = secs(start), secs(length), secs(fade)
    out = x[:, a:a + n].copy()
    w = np.sin(np.linspace(0, np.pi / 2, f)) ** 2
    out[:, n - f:] = out[:, n - f:] * (1 - w) + x[:, a - f:a] * w
    return out


def drums(bars, bar_s, kind):
    """A drum loop: 'fight' (four on the floor, claps, 8ths) or 'ot' (16ths, rolls)."""
    beat = bar_s / 4
    buf = np.zeros((2, secs(bars * bar_s)))
    for b in range(bars):
        t0 = b * bar_s
        for k in range(4):
            add(buf, kick(), t0 + k * beat, 0.9)
        for k in (1, 3):
            add(buf, clap(), t0 + k * beat, 0.7)
            add(buf, snare(220, 0.16), t0 + k * beat, 0.35)
        steps = 16 if kind == "ot" else 8
        for i in range(steps):
            off = i % (steps // 4) == steps // 8
            add(buf, hat(off, i % 3), t0 + i * bar_s / steps, 0.45 if off else 0.25, 0.3)
        if kind == "ot" and b % 4 == 3:
            for i in range(8):
                add(buf, snare(230 + i * 10, 0.1), t0 + 2 * beat + i * beat / 4, 0.2 + 0.05 * i)
    for b in range(0, bars, 8):
        add(buf, crash(1.8), b * bar_s, 0.45, 0.2)
    return buf


def master(x, rms=0.14):
    x = x * (rms / max(np.sqrt(np.mean(x ** 2)), 1e-9))
    return np.where(np.abs(x) < 0.6, x, np.sign(x) * (0.6 + 0.35 * np.tanh((np.abs(x) - 0.6) / 0.35)))


def best_loop(x, bars, first=2, last_bar=62):
    """The start bar whose loop seam sounds most alike on both sides."""
    def feat(t):
        seg = x.mean(0)[secs(t - 1.5):secs(t + 1.5)]
        spec = np.abs(np.fft.rfft(seg * np.hanning(len(seg))))
        return np.log1p(spec[::64])
    best = None
    for a in range(first, last_bar - bars + 1):
        fa, fb = feat(a * BAR), feat((a + bars) * BAR)
        score = np.dot(fa, fb) / (np.linalg.norm(fa) * np.linalg.norm(fb))
        if best is None or score > best[0]:
            best = (score, a)
    return best[1]


def bar_energy(x):
    m = x.mean(0)
    return [np.sqrt(np.mean(m[secs(i * BAR):secs((i + 1) * BAR)] ** 2)) for i in range(int(len(m) / SR / BAR))]


def build(src):
    x = load(src)
    energy = bar_energy(x)
    tracks = {}

    # Menu: 32 bars of the track as it is.
    a = best_loop(x, 32)
    tracks["music_menu"] = master(seam_loop(x, a * BAR, 32 * BAR))

    # Fight: the busiest 16 bars, sped up to 100 BPM, with drums on top.
    t = 1.25
    xf = load(src, t)
    starts = range(2, len(energy) - 18)
    fa = max(starts, key=lambda i: sum(energy[i:i + 16]))
    loop = seam_loop(xf, fa * BAR / t, 16 * BAR / t)
    tracks["music_fight"] = master(loop * 0.8 + drums(16, BAR / t, "fight")[:, :loop.shape[1]])

    # Overtime: 8 bars at 120 BPM, busier drums.
    t = 1.5
    xo = load(src, t)
    loop = seam_loop(xo, fa * BAR / t, 8 * BAR / t)
    tracks["music_overtime"] = master(loop * 0.75 + drums(8, BAR / t, "ot")[:, :loop.shape[1]])

    # Victory: a one-bar brass hit on F#, then 8 bars at 88 BPM with claps.
    t = 1.1
    xv = load(src, t)
    va = best_loop(x, 8, first=4)
    hit_len = BAR / t
    hit = xv[:, secs((va - 1) * BAR / t):secs(va * BAR / t)].copy() * 0.7
    stab = brass(F_SHARP, 1.6)
    add(hit, stab, 0.0, 1.1, wrap=False)
    add(hit, brass(tuple(n + 12 for n in F_SHARP), 1.2), hit_len / 2, 0.6, wrap=False)
    add(hit, crash(2.4), 0.0, 0.6, wrap=False)
    add(hit, boom(), 0.0, 0.5, wrap=False)
    loop = seam_loop(xv, va * BAR / t, 8 * BAR / t)
    claps = np.zeros_like(loop)
    for b in range(8):
        for k in (1, 3):
            add(claps, clap(), b * hit_len + k * hit_len / 4, 0.6)
        add(claps, kick(), b * hit_len, 0.6)
        add(claps, kick(), b * hit_len + hit_len / 2, 0.5)
    victory = np.hstack([hit, loop * 0.85 + claps])
    tracks["music_victory"] = master(victory)

    # Intro: the opening two bars under a riser, then the big hit ringing out.
    n_open = secs(2 * BAR)
    intro = np.zeros((2, n_open + secs(3.0)))
    intro[:, :n_open] = x[:, :n_open]
    add(intro, riser(BAR), BAR, 0.9, wrap=False)
    add(intro, kick(), 2 * BAR, 1.0, wrap=False)
    add(intro, boom(), 2 * BAR, 0.8, wrap=False)
    add(intro, crash(2.6), 2 * BAR, 0.6, wrap=False)
    add(intro, brass(F_SHARP, 2.8), 2 * BAR, 1.0, wrap=False)
    tail = x[:, n_open:n_open + secs(3.0)]
    intro[:, n_open:n_open + tail.shape[1]] += tail * 0.8
    fade = secs(1.5)
    intro[:, -fade:] *= np.linspace(1, 0, fade) ** 2
    tracks["music_intro"] = master(intro)
    print("menu loop from bar %d, fight/overtime from bar %d, victory from bar %d, hit %.4f s" % (a, fa, va, hit_len))
    return tracks


def write_ogg(name, x, out, wav_dir=""):
    path = os.path.join(out, name + ".ogg")
    with tempfile.TemporaryDirectory() as tmp:
        wav_path = os.path.join(wav_dir or tmp, name + ".wav")
        write_wav(wav_path, x)
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wav_path, "-c:a", "libvorbis",
                        "-q:a", "0", "-map_metadata", "-1", "-fflags", "+bitexact", "-flags:a", "+bitexact",
                        path], check=True)
    return path


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--src", default="")
    ap.add_argument("--wav", default="")
    ap.add_argument("--out", default=OUT)
    args = ap.parse_args()
    src = args.src
    if not src or not os.path.exists(src):
        src = os.path.join(tempfile.gettempdir(), "Crypto.mp3")
        if not os.path.exists(src):
            urllib.request.urlretrieve(SRC_URL, src)
    for name, x in build(src).items():
        print(write_ogg(name, x, args.out, args.wav), "%.1fs" % (x.shape[1] / SR))


if __name__ == "__main__":
    main()
