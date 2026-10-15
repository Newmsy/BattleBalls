#!/usr/bin/env python3
"""Renders every Battle Balls sound effect and music loop from code.

Each sound is a small recipe (oscillators, noise, pitch sweeps, envelopes)
in the style of sfxr, so any sound can be tweaked by editing a number here
and re-running. Output goes to game/audio/ and is committed, so CI and the
game never need Python.

Usage: python3 tools/sfx/make_sfx.py [--only NAME_PREFIX]
Needs numpy, and ffmpeg (with libvorbis) for the music loops.

Rules of thumb (see /design/sound.md):
- Phone speakers play almost nothing below ~250 Hz, so "weight" comes from a
  click transient plus a pitched body in the 300 Hz - 3 kHz band.
- Rendering is seeded, so re-running gives byte-identical files.
"""
import argparse
import os
import subprocess
import tempfile
import wave
import zlib

import numpy as np

SR = 32000
OUT = os.path.join(os.path.dirname(__file__), "..", "..", "game", "audio")
rng = np.random.default_rng(1234)


# --- Building blocks ---------------------------------------------------------

def t_axis(dur):
    return np.arange(int(dur * SR)) / SR


def sweep(f0, f1, dur, curve=1.0):
    """Instantaneous frequency going from f0 to f1 (exponential-ish when curve>1)."""
    x = np.linspace(0, 1, int(dur * SR)) ** curve
    return f0 * (f1 / f0) ** x


def osc(freq, shape="sine"):
    """freq: array of instantaneous frequencies. Returns a waveform."""
    phase = 2 * np.pi * np.cumsum(freq) / SR
    if shape == "sine":
        return np.sin(phase)
    if shape == "tri":
        return 2 / np.pi * np.arcsin(np.sin(phase))
    if shape == "square":
        return np.tanh(np.sin(phase) * 6)
    if shape == "saw":
        p = (phase / (2 * np.pi)) % 1.0
        return 2 * p - 1
    raise ValueError(shape)


def env(dur, attack=0.003, decay=None, hold=0.0, power=1.0):
    """Attack then exponential-ish decay over the remaining time."""
    n = int(dur * SR)
    a = max(1, int(attack * SR))
    h = int(hold * SR)
    out = np.ones(n)
    out[:a] = np.linspace(0, 1, a)
    rest = n - a - h
    if rest > 0:
        d = np.linspace(0, 1, rest)
        k = decay if decay is not None else 5.0
        out[a + h:] = np.exp(-k * d) * (1 - d) ** power
    return out


def noise(dur):
    return rng.uniform(-1, 1, int(dur * SR))


def lowpass(x, cutoff):
    """One-pole lowpass; cutoff may be an array."""
    cutoff = np.broadcast_to(np.asarray(cutoff, dtype=float), x.shape)
    alpha = 1 - np.exp(-2 * np.pi * cutoff / SR)
    y = np.empty_like(x)
    acc = 0.0
    for i in range(len(x)):
        acc += alpha[i] * (x[i] - acc)
        y[i] = acc
    return y


def highpass(x, cutoff):
    return x - lowpass(x, cutoff)


def bandnoise(dur, lo, hi):
    return highpass(lowpass(noise(dur), hi), lo)


def mix(*parts):
    n = max(len(p) for p in parts)
    out = np.zeros(n)
    for p in parts:
        out[:len(p)] += p
    return out


def delay(x, seconds):
    return np.concatenate([np.zeros(int(seconds * SR)), x])


def seq(notes):
    """notes: list of (start_seconds, samples)."""
    return mix(*[delay(s, t) for t, s in notes])


def finish(x, peak=0.9, fade=0.004):
    x = np.asarray(x, dtype=float)
    f = min(len(x), int(fade * SR))
    if f:
        x[-f:] *= np.linspace(1, 0, f)
    m = np.max(np.abs(x)) or 1.0
    return x / m * peak


def write_wav(name, x, peak=0.9):
    x = finish(x, peak)
    path = os.path.join(OUT, name + ".wav")
    data = (np.clip(x, -1, 1) * 32767).astype("<i2").tobytes()
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data)
    return path


def midi(n):
    return 440.0 * 2 ** ((n - 69) / 12)


# --- Combat ------------------------------------------------------------------

def hit(variant, big=False):
    """The signature 'bonk': click transient + rubbery pitched body + noise tail."""
    dur = 0.32 if big else 0.22
    base = [430, 480, 390][variant]
    click = bandnoise(0.012, 1500, 9000) * env(0.012, 0.0005, 6)
    body_f = sweep(base * 1.9, base * 0.75, dur, 0.35)
    wobble = 1 + 0.06 * np.sin(2 * np.pi * 28 * t_axis(dur)) * np.exp(-12 * t_axis(dur))
    body = osc(body_f * wobble, "tri") * env(dur, 0.001, 7)
    sub = osc(sweep(base * 0.9, base * 0.45, dur, 0.5), "sine") * env(dur, 0.001, 9) * 0.6
    tail = bandnoise(0.09, 400, 3500) * env(0.09, 0.001, 8) * 0.35
    parts = [click * 0.7, body, sub, tail * 0.7]
    if big:
        crack = bandnoise(0.06, 900, 7000) * env(0.06, 0.0005, 5) * 1.2
        thump = osc(sweep(340, 110, 0.3, 0.5), "sine") * env(0.3, 0.001, 6) * 0.6
        parts += [crack, thump]
    return mix(*parts)


def wall(variant):
    """Glassy neon 'ting' off the arena border. Kept quiet and short."""
    f = [1760, 1980, 2350][variant]
    dur = 0.16
    t = t_axis(dur)
    tone = (np.sin(2 * np.pi * f * t) + 0.4 * np.sin(2 * np.pi * f * 2.76 * t)
            + 0.2 * np.sin(2 * np.pi * f * 5.4 * t))
    tick = bandnoise(0.006, 3000, 12000) * env(0.006, 0.0003, 5) * 0.5
    return mix(tone * env(dur, 0.001, 9), tick)


def ouch_vampire(variant):
    """Count Nibbles: a smug little 'heh!' that turns into a squeak when hit."""
    p = [1.0, 1.12][variant]
    dur = 0.16
    f = sweep(820 * p, 1250 * p, dur * 0.4, 1).tolist() + sweep(1250 * p, 700 * p, dur * 0.6, 1).tolist()
    f = np.array(f)
    vib = 1 + 0.03 * np.sin(2 * np.pi * 35 * t_axis(len(f) / SR))
    voice = osc(f * vib, "square") * 0.5 + osc(f * 2 * vib, "sine") * 0.3
    voice = lowpass(voice, 3200) * env(len(f) / SR, 0.004, 4)
    breath = bandnoise(0.05, 2000, 6000) * env(0.05, 0.002, 5) * 0.15
    return mix(voice, breath)


def ouch_laser(variant):
    """Optic-style robot: two quick descending bleeps."""
    p = [1.0, 1.1][variant]
    a = osc(np.full(int(0.05 * SR), 1320 * p), "square") * env(0.05, 0.001, 2)
    b = osc(np.full(int(0.08 * SR), 880 * p), "square") * env(0.08, 0.001, 4)
    return lowpass(seq([(0, a), (0.055, b)]), 4500) * 0.8


def ouch_magnet(variant):
    """Flux: a buzzy 'bzzt-ow!' with a little metal ring."""
    p = [1.0, 1.12][variant]
    dur = 0.15
    f = sweep(1000 * p, 620 * p, dur, 1)
    buzz = 1 + 0.5 * np.sign(np.sin(2 * np.pi * 90 * t_axis(dur)))
    voice = lowpass(osc(f, "square") * buzz * 0.4, 3000) * env(dur, 0.003, 4)
    ring = osc(np.full(int(0.12 * SR), 2950 * p), "sine") * env(0.12, 0.001, 6) * 0.25
    return mix(voice, ring)


def flip():
    """Flux's field flipping: a short rising 'vwom' hum."""
    dur = 0.2
    f = sweep(140, 420, dur, 0.7)
    hum = lowpass(osc(f, "saw"), 1800) * env(dur, 0.03, 2) * 0.6
    return mix(hum, osc(f * 2, "sine") * env(dur, 0.03, 3) * 0.3)


def snap():
    """Flux's Snap hit: a hard metal clack with a spark."""
    clack = mix(bandnoise(0.04, 1500, 9000) * env(0.04, 0.0003, 8),
                osc(np.full(int(0.09 * SR), 1720.0), "square") * env(0.09, 0.0005, 7) * 0.4)
    spark = bandnoise(0.12, 5000, 12000) * env(0.12, 0.002, 5) * 0.3
    return lowpass(seq([(0, clack), (0.02, spark)]), 9000)


def ko():
    """Deflating squeak, then a pop and a sparkle."""
    dur = 0.55
    f = sweep(900, 160, dur, 0.8) * (1 + 0.05 * np.sin(2 * np.pi * 16 * t_axis(dur)))
    deflate = lowpass(osc(f, "square"), 2500) * env(dur, 0.01, 1.5) * 0.6
    air = bandnoise(dur, 800, 4000) * env(dur, 0.02, 2) * 0.25
    pop = mix(bandnoise(0.03, 300, 6000) * env(0.03, 0.0005, 6),
              osc(sweep(600, 120, 0.08), "sine") * env(0.08, 0.0005, 6))
    sparkle = mix(*[delay(osc(np.full(int(0.12 * SR), midi(n)), "sine") * env(0.12, 0.001, 6) * 0.3, i * 0.045)
                    for i, n in enumerate([88, 91, 95, 100])])
    return seq([(0, deflate), (0, air), (dur, pop * 1.2), (dur + 0.05, sparkle)])


def heal():
    """Rising sparkle chime."""
    notes = [76, 79, 83, 88]
    parts = []
    for i, n in enumerate(notes):
        d = 0.18
        t = t_axis(d)
        tone = np.sin(2 * np.pi * midi(n) * t) + 0.3 * np.sin(2 * np.pi * midi(n) * 3 * t)
        parts.append((i * 0.04, tone * env(d, 0.002, 6) * (0.6 + 0.1 * i)))
    return seq(parts)


def slurp():
    """Count Nibbles' bite: wet rising slurp."""
    dur = 0.22
    f = sweep(300, 1100, dur, 1.3)
    gurgle = 1 + 0.25 * np.sin(2 * np.pi * 22 * t_axis(dur))
    wet = lowpass(noise(dur), f * gurgle * 2) * 1.6
    tone = osc(f * gurgle, "sine") * 0.4
    return mix(wet, tone) * env(dur, 0.02, 3)


def zap():
    """Optic's laser beam: bright downward zap with an electric buzz."""
    dur = 0.24
    f = sweep(2600, 380, dur, 0.5)
    beam = lowpass(osc(f, "saw"), 5000) * env(dur, 0.001, 4) * 0.7
    buzz = osc(np.full(int(dur * SR), 120.0), "square") * bandnoise(dur, 1000, 5000) * env(dur, 0.001, 5) * 0.5
    return mix(beam, buzz, osc(f * 1.5, "sine") * env(dur, 0.001, 6) * 0.3)


def sizzle():
    """Laser beam burning a ball."""
    dur = 0.14
    crackle = bandnoise(dur, 2500, 9000) * (rng.uniform(0, 1, int(dur * SR)) > 0.6)
    hum = osc(np.full(int(dur * SR), 660.0), "saw") * 0.3
    return lowpass(mix(crackle * 1.3, hum), 8000) * env(dur, 0.002, 4)


def overtime():
    """Rising alarm sweep, twice."""
    one = lowpass(osc(sweep(400, 1300, 0.35, 1.0), "tri"), 3500) * env(0.35, 0.01, 0.5, hold=0.2)
    return seq([(0, one * 0.6), (0.4, one * 0.7)])


def heartbeat():
    """Low-HP pulse for the player's ball; pitched high enough for phone speakers."""
    def thud(f):
        return osc(sweep(f * 1.6, f, 0.12, 0.5), "tri") * env(0.12, 0.002, 6)
    return seq([(0, thud(260)), (0.16, thud(230) * 0.7)])


# --- Flow and UI -------------------------------------------------------------

def jingle(notes, step, length, shape="square", cutoff=4000):
    parts = []
    for i, n in enumerate(notes):
        d = length if i == len(notes) - 1 else step * 1.1
        t = t_axis(d)
        f = np.full(len(t), midi(n)) * (1 + 0.006 * np.sin(2 * np.pi * 6 * t))
        tone = lowpass(osc(f, shape) * 0.6 + osc(f * 2, "sine") * 0.2, cutoff)
        parts.append((i * step, tone * env(d, 0.004, 3 if i == len(notes) - 1 else 5)))
    return seq(parts)


def win():
    fan = jingle([72, 76, 79, 84], 0.11, 0.6)
    chord = mix(*[osc(np.full(int(0.6 * SR), midi(n)), "tri") * env(0.6, 0.01, 3) * 0.25 for n in [72, 76, 79]])
    return seq([(0, fan), (0.33, chord)])


def lose():
    return jingle([67, 66, 65, 62], 0.16, 0.7, shape="tri", cutoff=2500)


def draw():
    """A shrug: up a step, back down, ending on the note it started on."""
    return jingle([69, 72, 69], 0.14, 0.6, shape="tri", cutoff=3500)


def go():
    """Fight start: a quick rising whoosh with a bright 'ding'."""
    dur = 0.35
    whoosh = lowpass(noise(dur), sweep(500, 6000, dur, 1.5)) * env(dur, 0.2, 3) * 0.8
    ding = jingle([84], 0.1, 0.3, shape="sine")
    return seq([(0, whoosh), (0.22, ding * 0.8)])


def launch():
    """Rubber-band 'fwip' on release."""
    dur = 0.18
    f = sweep(300, 1500, dur, 0.6)
    twang = osc(f, "tri") * env(dur, 0.002, 4) * 0.6
    air = lowpass(noise(dur), sweep(1000, 7000, dur)) * env(dur, 0.01, 3) * 0.6
    return mix(twang, air)


def stretch():
    """Short rubber creak played while dragging to aim; pitch follows pull."""
    dur = 0.09
    f = 180 * (1 + 0.5 * (rng.uniform(0, 1, int(dur * SR)) > 0.93))
    creak = lowpass(osc(np.full(int(dur * SR), 520.0), "saw") * (osc(f, "square") * 0.5 + 0.5), 2200)
    return creak * env(dur, 0.01, 2) * 0.6


def click():
    """Soft bubble pop for buttons."""
    dur = 0.07
    return osc(sweep(500, 1400, dur, 0.4), "sine") * env(dur, 0.001, 5)


SOUNDS = {
    "hit_0": lambda: hit(0), "hit_1": lambda: hit(1), "hit_2": lambda: hit(2),
    "hit_big": lambda: hit(0, big=True),
    "wall_0": lambda: wall(0), "wall_1": lambda: wall(1), "wall_2": lambda: wall(2),
    "ouch_vampire_0": lambda: ouch_vampire(0), "ouch_vampire_1": lambda: ouch_vampire(1),
    "ouch_laser_0": lambda: ouch_laser(0), "ouch_laser_1": lambda: ouch_laser(1),
    "ouch_magnet_0": lambda: ouch_magnet(0), "ouch_magnet_1": lambda: ouch_magnet(1),
    "flip": flip, "snap": snap,
    "ko": ko, "heal": heal, "slurp": slurp, "zap": zap, "sizzle": sizzle,
    "overtime": overtime, "heartbeat": heartbeat,
    "win": win, "lose": lose, "draw": draw, "go": go, "launch": launch, "stretch": stretch, "click": click,
}


# --- Music (placeholder synthwave loops) -------------------------------------

BPM = 112
BEAT = 60.0 / BPM
MSR = 22050  # Music sample rate: plenty for a phone speaker, half the size.


def _m_osc(freq, dur, shape):
    t = np.arange(int(dur * MSR)) / MSR
    ph = 2 * np.pi * freq * t
    if shape == "saw":
        return 2 * ((freq * t) % 1.0) - 1
    if shape == "square":
        return np.sign(np.sin(ph)) * 0.7
    return np.sin(ph)


def _m_env(n, a, k):
    e = np.exp(-k * np.linspace(0, 1, n))
    a = max(1, int(a * MSR))
    e[:a] *= np.linspace(0, 1, a)
    return e


def _m_lp(x, cutoff):
    alpha = 1 - np.exp(-2 * np.pi * cutoff / MSR)
    # Cheap: filter twice with a vectorised IIR via scipy-free loop on chunks.
    y = np.empty_like(x)
    acc = 0.0
    for i in range(len(x)):
        acc += alpha * (x[i] - acc)
        y[i] = acc
    return y


def music(drums):
    """8 bars of Am - F - C - G synthwave: pad, arp, bass and (fight) drums."""
    bars = 8
    total = int(bars * 4 * BEAT * MSR)
    out = np.zeros(total)
    chords = [[57, 60, 64], [53, 57, 60], [48, 52, 55], [55, 59, 62]]
    mrng = np.random.default_rng(7)

    def put(sig, start):
        s = int(start * MSR)
        e = min(total, s + len(sig))
        out[s:e] += sig[:e - s]

    for bar in range(bars):
        ch = chords[bar % 4]
        t0 = bar * 4 * BEAT
        # Pad: detuned saws, soft attack.
        d = 4 * BEAT
        pad = sum(_m_osc(midi(n) * det, d, "saw") for n in ch for det in (0.997, 1.003))
        put(_m_lp(pad, 1400) * _m_env(len(pad), 0.3, 0.6) * 0.05, t0)
        # Arp: 16th notes over the chord, an octave up.
        arp_notes = [ch[0] + 12, ch[1] + 12, ch[2] + 12, ch[1] + 24]
        for i in range(16):
            n = arp_notes[i % 4]
            s = _m_osc(midi(n), BEAT / 4, "square")
            put(_m_lp(s, 2600) * _m_env(len(s), 0.003, 6) * 0.07, t0 + i * BEAT / 4)
        # Bass: 8th notes on the root, phone-audible octave.
        for i in range(8):
            n = ch[0] - 12 + (12 if i % 2 else 0)
            s = _m_osc(midi(n), BEAT / 2, "saw")
            put(_m_lp(s, 900) * _m_env(len(s), 0.005, 3) * 0.16, t0 + i * BEAT / 2)
        if drums:
            for beat in range(4):
                bt = t0 + beat * BEAT
                kick_f = 150 * (55 / 150) ** np.linspace(0, 1, int(0.18 * MSR)) ** 0.4
                kick = np.sin(2 * np.pi * np.cumsum(kick_f) / MSR) * _m_env(int(0.18 * MSR), 0.001, 5)
                put(kick * 0.5, bt)
                hat = mrng.uniform(-1, 1, int(0.04 * MSR))
                hat = (hat - _m_lp(hat, 7000)) * _m_env(len(hat), 0.001, 6) * 0.12
                put(hat, bt + BEAT / 2)
                if beat in (1, 3):
                    sn = mrng.uniform(-1, 1, int(0.16 * MSR))
                    sn = (sn - _m_lp(sn, 1200)) * _m_env(len(sn), 0.001, 5) * 0.25
                    put(sn + _m_osc(220, 0.16, "sine") * _m_env(len(sn), 0.001, 8) * 0.15, bt)
    out = out / np.max(np.abs(out)) * 0.8
    return out


def write_ogg(name, x):
    path = os.path.join(OUT, name + ".ogg")
    with tempfile.TemporaryDirectory() as tmp:
        wav_path = os.path.join(tmp, "m.wav")
        with wave.open(wav_path, "wb") as w:
            w.setnchannels(1)
            w.setsampwidth(2)
            w.setframerate(MSR)
            w.writeframes((np.clip(x, -1, 1) * 32767).astype("<i2").tobytes())
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wav_path, "-c:a", "libvorbis",
                        "-q:a", "2", "-map_metadata", "-1", "-fflags", "+bitexact", "-flags:a", "+bitexact",
                        path], check=True)
    return path


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--only", default="")
    args = ap.parse_args()
    os.makedirs(OUT, exist_ok=True)
    for name, make in SOUNDS.items():
        if name.startswith(args.only):
            global rng
            rng = np.random.default_rng(zlib.crc32(name.encode()))
            print(write_wav(name, make()))
    if "music".startswith(args.only) or args.only.startswith("music"):
        print(write_ogg("music_menu", music(drums=False)))
        print(write_ogg("music_fight", music(drums=True)))


if __name__ == "__main__":
    main()
