#!/usr/bin/env python3
"""Composes and renders Battle Balls' music from code: original "Neon Critters"
synthwave, so there is no licence to worry about.

Tracks (all share one hook, A-D-E-F-E-D in minor, G-C-D-E-D-C in major, so
the game sounds like one piece):
- music_intro:   "Welcome" sting when the game opens, then the menu loop.
- music_menu:    "Neon Drift", the calm home-screen loop (96 BPM, D minor).
- music_fight:   "Bounce Brawl", the fight loop (128 BPM, A minor).
- music_overtime: "Overtime Rush", the same fight at 152 BPM, a semitone up.
- music_victory: "Champion", a 2-bar fanfare then a happy loop (loop_offset).

Every loop is rendered with its reverb/delay tail folded back onto its start,
so it loops seamlessly. Rendering is seeded: re-running gives the same audio.

Usage: python3 tools/music/make_music.py [--only NAME_PREFIX] [--wav DIR]
Needs numpy, scipy and ffmpeg (with libvorbis).
"""
import argparse
import functools
import os
import subprocess
import tempfile
import wave

import numpy as np
from scipy.signal import butter, lfilter, sosfilt

SR = 24000  # Plenty for a phone speaker; keeps the web download small.
OUT = os.path.join(os.path.dirname(__file__), "..", "..", "game", "audio")
TARGET_RMS = 0.14  # Every track renders to about the same loudness.


def midi(n):
    return 440.0 * 2 ** ((n - 69) / 12.0)


# --- Oscillators and filters --------------------------------------------------

def _blep(t, dt):
    out = np.zeros_like(t)
    lo = t < dt
    x = t[lo] / dt[lo]
    out[lo] = x + x - x * x - 1
    hi = t > 1 - dt
    x = (t[hi] - 1) / dt[hi]
    out[hi] = x * x + x + x + 1
    return out


def _freqs(freq, n):
    return np.full(n, float(freq)) if np.isscalar(freq) else np.asarray(freq, float)


def saw(freq, n, phase=0.0):
    f = _freqs(freq, n)
    dt = f / SR
    t = (phase + np.cumsum(dt)) % 1.0
    return 2 * t - 1 - _blep(t, dt)


def pulse(freq, n, width=0.5, phase=0.0):
    f = _freqs(freq, n)
    dt = f / SR
    t = (phase + np.cumsum(dt)) % 1.0
    t2 = (t + 1 - width) % 1.0
    return (2 * t - 1 - _blep(t, dt)) - (2 * t2 - 1 - _blep(t2, dt))


def sine(freq, n, phase=0.0):
    return np.sin(2 * np.pi * (phase + np.cumsum(_freqs(freq, n) / SR)))


def tri(freq, n):
    t = np.cumsum(_freqs(freq, n) / SR) % 1.0
    return 4 * np.abs(t - 0.5) - 1


def svf_lp(x, cutoff, q=0.8):
    """Resonant low-pass whose cutoff can move per sample (a filter sweep)."""
    fc = np.clip(_freqs(cutoff, len(x)), 20, SR * 0.45)
    g = np.tan(np.pi * fc / SR)
    k = 1.0 / q
    a1 = 1 / (1 + g * (g + k))
    a2 = g * a1
    a3 = g * a2
    y = np.empty_like(x)
    ic1 = ic2 = 0.0
    for i in range(len(x)):
        v3 = x[i] - ic2
        v1 = a1[i] * ic1 + a2[i] * v3
        v2 = ic2 + a2[i] * ic1 + a3[i] * v3
        ic1 = 2 * v1 - ic1
        ic2 = 2 * v2 - ic2
        y[i] = v2
    return y


def lp(x, cutoff, order=2):
    return sosfilt(butter(order, cutoff, "low", fs=SR, output="sos"), x)


def hp(x, cutoff, order=2):
    return sosfilt(butter(order, cutoff, "high", fs=SR, output="sos"), x)


def bp(x, lo, hi, order=2):
    return sosfilt(butter(order, [lo, hi], "band", fs=SR, output="sos"), x)


def env(n, attack=0.005, decay=0.2, sustain=0.0, release=0.05, hold=None):
    """ADSR over n samples; hold = seconds before release (default: all of it)."""
    t = np.arange(n) / SR
    hold = n / SR - release if hold is None else hold
    a = np.minimum(1.0, t / max(attack, 1e-4))
    d = sustain + (1 - sustain) * np.exp(-np.maximum(0, t - attack) / max(decay, 1e-4))
    e = np.where(t < attack, a, d)
    r = np.clip(1 - (t - hold) / max(release, 1e-4), 0, 1)
    return e * np.where(t > hold, r, 1.0)


def perc(n, decay, attack=0.001):
    t = np.arange(n) / SR
    return np.minimum(1, t / attack) * np.exp(-t / decay)


_noise_rng = np.random.default_rng(2026)
_NOISE = _noise_rng.uniform(-1, 1, SR * 4)


def noise(n, offset=0):
    offset %= len(_NOISE) - n
    return _NOISE[offset:offset + n].copy()


# --- Instruments (memoised: the same note renders once) -----------------------

@functools.lru_cache(maxsize=None)
def kick(punch=1.0):
    n = int(0.32 * SR)
    t = np.arange(n) / SR
    f = 48 + 120 * np.exp(-t / 0.035)
    body = np.sin(2 * np.pi * np.cumsum(f) / SR) * perc(n, 0.16)
    click = hp(noise(n, 11), 2500) * perc(n, 0.004) * 0.5
    # Saturation adds harmonics a phone speaker can actually play.
    return np.tanh((body + click) * 2.2 * punch) * 0.5


@functools.lru_cache(maxsize=None)
def snare(tone=190.0, length=0.2):
    n = int(length * SR)
    body = (sine(tone, n) * 0.6 + sine(tone * 1.7, n) * 0.3) * perc(n, 0.05)
    rattle = bp(noise(n, 300), 1500, 9000) * perc(n, length * 0.35)
    return (body + rattle * 0.9) * 0.7


@functools.lru_cache(maxsize=None)
def clap():
    n = int(0.25 * SR)
    burst = np.zeros(n)
    for i, at in enumerate((0.0, 0.011, 0.022)):
        s = int(at * SR)
        burst[s:] += perc(n - s, 0.006 if i < 2 else 0.09)
    return bp(noise(n, 900), 900, 4000) * burst * 0.8


@functools.lru_cache(maxsize=None)
def hat(open_=False, variant=0):
    n = int((0.22 if open_ else 0.05) * SR)
    s = hp(noise(n, 2000 + variant * 977), 7000, 4)
    return s * perc(n, 0.08 if open_ else 0.013) * 0.9


@functools.lru_cache(maxsize=None)
def shaker(variant=0):
    n = int(0.07 * SR)
    s = bp(noise(n, 5000 + variant * 501), 4000, 11000)
    return s * env(n, 0.015, 0.02, 0, 0.02) * 0.3


@functools.lru_cache(maxsize=None)
def crash(length=1.8):
    n = int(length * SR)
    t = np.arange(n) / SR
    metal = sum(np.sin(2 * np.pi * f * t) for f in (3170, 4730, 5590, 7410)) * 0.08
    s = hp(noise(n, 7000) + metal, 3500)
    return s * perc(n, length * 0.3, 0.002) * 0.6


@functools.lru_cache(maxsize=None)
def tom(note):
    n = int(0.3 * SR)
    t = np.arange(n) / SR
    f = midi(note) * (1 + 0.6 * np.exp(-t / 0.03))
    return np.tanh(np.sin(2 * np.pi * np.cumsum(f) / SR) * perc(n, 0.12) * 1.8) * 0.6


def riser(seconds):
    n = int(seconds * SR)
    t = np.linspace(0, 1, n)
    s = svf_lp(noise(n, 12000), 300 + 9000 * t ** 2, 2.5)
    return s * t ** 1.5 * 0.45


def boom():
    n = int(2.0 * SR)
    t = np.arange(n) / SR
    low = np.sin(2 * np.pi * np.cumsum(40 + 60 * np.exp(-t / 0.08)) / SR) * perc(n, 0.6)
    air = lp(noise(n, 15000), 1800) * perc(n, 0.35)
    return np.tanh((low + air * 0.6) * 1.8) * 0.8


@functools.lru_cache(maxsize=None)
def pluck(note, beats_len, bpm, bright=1.0):
    """Saw + square through a closing filter: the arp."""
    n = int(max(0.12, beats_len * 60 / bpm) * SR)
    f = midi(note)
    x = saw(f, n) * 0.6 + pulse(f * 1.002, n, 0.35) * 0.4
    t = np.arange(n) / SR
    cut = 500 + 4200 * bright * np.exp(-t / 0.07)
    return svf_lp(x, cut, 1.4) * perc(n, 0.16) * 0.5


@functools.lru_cache(maxsize=None)
def bass(note, seconds, drive=1.6, bright=1.0):
    n = int(seconds * SR)
    f = midi(note)
    x = saw(f, n) * 0.7 + pulse(f, n, 0.5) * 0.3
    t = np.arange(n) / SR
    cut = 180 + 1300 * bright * np.exp(-t / 0.06)
    y = svf_lp(x, cut, 1.1) + sine(f, n) * 0.3
    return np.tanh(y * drive) * env(n, 0.003, 0.25, 0.6, 0.02) * 0.55


def supersaw(notes, seconds, cutoff=1800, attack=0.4, release=0.8, voices=5, spread=0.012):
    """Detuned saws per note, as (left, right): the pad and the big stabs."""
    n = int(seconds * SR)
    left = np.zeros(n)
    right = np.zeros(n)
    rng = np.random.default_rng(int(sum(notes) * 7 + seconds * 100))
    for note in notes:
        for v in range(voices):
            det = 1 + spread * (v / (voices - 1) - 0.5) * 2
            s = saw(midi(note) * det, n, rng.uniform())
            pan = v / (voices - 1)
            left += s * (1 - pan * 0.7)
            right += s * (0.3 + pan * 0.7)
    e = env(n, attack, 1.0, 1.0, release)
    scale = 0.5 / (len(notes) * voices) ** 0.5
    return lp(left, cutoff) * e * scale, lp(right, cutoff) * e * scale


@functools.lru_cache(maxsize=None)
def lead(note, seconds, shape="saw", vibrato=True):
    n = int(seconds * SR)
    t = np.arange(n) / SR
    f = midi(note) * np.ones(n)
    if vibrato:
        f *= 1 + 0.006 * np.sin(2 * np.pi * 5.5 * t) * np.clip((t - 0.15) / 0.2, 0, 1)
    if shape == "saw":
        x = saw(f, n) * 0.55 + saw(f * 1.004, n, 0.3) * 0.45
        x = lp(x, 3800)
    elif shape == "soft":  # Sine + triangle: the calm menu lead.
        x = sine(f, n) * 0.7 + tri(f * 2, n) * 0.15 + tri(f, n) * 0.3
    else:
        x = pulse(f, n, 0.3)
        x = lp(x, 3000)
    return x * env(n, 0.01, 0.3, 0.7, min(0.08, seconds * 0.4)) * 0.4


@functools.lru_cache(maxsize=None)
def bell(note, seconds=1.2):
    """FM bell: bright chime for the hook."""
    n = int(seconds * SR)
    t = np.arange(n) / SR
    f = midi(note)
    index = 3.0 * np.exp(-t / 0.25)
    mod = np.sin(2 * np.pi * f * 3.5 * t) * index
    return np.sin(2 * np.pi * f * t + mod) * perc(n, seconds * 0.35) * 0.35


@functools.lru_cache(maxsize=None)
def brass(notes, seconds):
    """Bright saw stab with a filter swell: the victory fanfare."""
    n = int(seconds * SR)
    t = np.arange(n) / SR
    x = sum(saw(midi(m), n) + saw(midi(m) * 1.006, n, 0.5) for m in notes) / len(notes)
    cut = 900 + 3000 * (1 - np.exp(-t / 0.05)) * np.exp(-t / 0.6) + 500
    return svf_lp(x, cut, 0.9) * env(n, 0.012, 0.4, 0.55, 0.08) * 0.8


# --- Mixing -----------------------------------------------------------------

class Song:
    """A buffer of buses; notes are placed in beats. Bus fx run at render."""

    def __init__(self, bpm, bars, tail=3.0):
        self.bpm = bpm
        self.beat = 60.0 / bpm
        self.bars = bars
        self.n = int(round(bars * 4 * self.beat * SR))
        self.total = self.n + int(tail * SR)
        self.buses = {}
        self.kicks = []

    def sec(self, beats):
        return beats * self.beat

    def add(self, bus, sig, beat, pan=0.0, gain=1.0):
        if isinstance(sig, tuple):
            left, right = sig
        else:
            a = (pan + 1) * np.pi / 4
            left, right = sig * np.cos(a) * 1.414, sig * np.sin(a) * 1.414
        buf = self.buses.setdefault(bus, np.zeros((2, self.total)))
        s = int(round(self.sec(beat) * SR))
        if s >= self.total:
            return
        e = min(self.total, s + len(left))
        buf[0, s:e] += left[:e - s] * gain
        buf[1, s:e] += right[:e - s] * gain

    def kick(self, beat, gain=1.0):
        self.add("drums", kick(), beat, 0, gain)
        self.kicks.append(beat)

    def duck_curve(self, depth=0.6, release=0.22):
        """Side-chain pump: the pad and bass breathe with the kick."""
        g = np.ones(self.total)
        shape_n = int(release * SR)
        t = np.arange(shape_n) / shape_n
        shape = 1 - depth * (1 - t) ** 2
        for b in self.kicks:
            s = int(self.sec(b) * SR)
            e = min(self.total, s + shape_n)
            g[s:e] = np.minimum(g[s:e], shape[:e - s])
        return g

    def render(self, sends, ducked=(), duck=0.6, loop_from=0.0, loop=True, delay_beats=0.75):
        """Mixes the buses with reverb/delay sends; folds the tail for loops."""
        dry = np.zeros((2, self.total))
        rev_in = np.zeros((2, self.total))
        dly_in = np.zeros((2, self.total))
        curve = self.duck_curve(duck) if self.kicks and ducked else None
        for name, buf in self.buses.items():
            if curve is not None and name in ducked:
                buf = buf * curve
            dry += buf
            r, d = sends.get(name, (0.0, 0.0))
            rev_in += buf * r
            dly_in += buf * d
        wet_d = ping_pong(dly_in, self.sec(delay_beats), 0.42)
        out = dry + wet_d * 0.6 + reverb(rev_in + wet_d * 0.25) * 0.9
        out = np.vstack([hp(out[0], 35), hp(out[1], 35)])
        if loop:
            start = int(round(self.sec(loop_from * 4) * SR))
            tail = out[:, self.n:]
            out = out[:, :self.n].copy()
            out[:, start:start + tail.shape[1]] += tail[:, :self.n - start]
        else:
            out = out[:, :self.total]
        return master(out)


def _fb_delay(x, d, g, damp=4000):
    """Feedback comb y[n] = x[n] + g*lp(y[n-d]), block by block (fast in numpy)."""
    y = x.copy()
    b, a = butter(1, damp, "low", fs=SR)
    for s in range(d, len(x), d):
        e = min(len(x), s + d)
        y[s:e] += g * lfilter(b, a, y[s - d:e - d])
    return y


def _allpass(x, d, g=0.5):
    y = np.zeros_like(x)
    y[:d] = -g * x[:d]
    for s in range(d, len(x), d):
        e = min(len(x), s + d)
        y[s:e] = -g * x[s:e] + x[s - d:e - d] + g * y[s - d:e - d]
    return y


def reverb(x):
    """A small Schroeder hall: parallel combs then allpasses, per channel."""
    out = np.zeros_like(x)
    for ch, offset in ((0, 0), (1, 23)):
        src = lp(hp(x[ch], 200), 7000)
        acc = np.zeros_like(src)
        for d in (1116, 1188, 1277, 1356, 1422, 1491):
            acc += _fb_delay(src, int((d + offset) * SR / 44100), 0.8, 3500)
        acc /= 6
        for d in (556, 441, 341):
            acc = _allpass(acc, int((d + offset) * SR / 44100))
        out[ch] = acc
    return out * 0.6


def ping_pong(x, seconds, fb):
    d = int(seconds * SR)
    mono = (x[0] + x[1]) * 0.5
    y = np.zeros_like(x)
    # Echoes alternate right, left, right... and fade by fb each time.
    lp_mono = lp(mono, 3500)
    for k in range(1, 7):
        s = d * k
        if s >= len(mono):
            break
        y[k % 2, s:] += lp_mono[:len(mono) - s] * fb ** k
    return y


def master(x):
    # Phone speakers play little below ~250 Hz: thin the lows, lift the mids.
    for ch in range(2):
        c = hp(x[ch], 50)
        c = c - 0.5 * lp(c, 140)
        x[ch] = c + 0.6 * bp(c, 1200, 4500)
    rms = np.sqrt(np.mean(x ** 2))
    x = x * (TARGET_RMS / max(rms, 1e-9))
    # Soft limiter: transparent below ~0.6, rounds off peaks above it.
    return np.where(np.abs(x) < 0.6, x, np.sign(x) * (0.6 + 0.35 * np.tanh((np.abs(x) - 0.6) / 0.35)))


# --- Shared musical bits -----------------------------------------------------

def hook(root, major=False):
    """The game's hook, from the fifth: A-D-E-F-E-D (minor) / G-C-D-E-D-C (major)."""
    third = 4 if major else 3
    steps = [0, 5, 7, 7 + third - 2, 7, 5]
    return [(0.0, 0.5, root + steps[0]), (0.5, 0.5, root + steps[1]), (1.0, 0.5, root + steps[2]),
            (1.5, 1.5, root + steps[3]), (3.0, 0.5, root + steps[4]), (3.5, 0.5, root + steps[5])]


def arp(song, bar, chord, pattern, octave=12, bus="arp", bright=1.0, gain=1.0, step=0.25):
    for i, idx in enumerate(pattern):
        note = chord[idx % len(chord)] + octave
        pan = 0.35 if i % 2 else -0.35
        song.add(bus, pluck(note, step, song.bpm, bright), bar * 4 + i * step, pan, gain)


def melody(song, bar, notes, inst, bus="lead", gain=1.0, transpose=0):
    for beat, length, note in notes:
        song.add(bus, inst(note + transpose, song.sec(length)), bar * 4 + beat, 0, gain)


# --- The tracks ---------------------------------------------------------------

MENU_CHORDS = {  # D minor: pad voicing, bass root.
    "Dm": ([57, 62, 65, 69], 38), "Bb": ([58, 62, 65, 70], 34), "F": ([57, 60, 65, 69], 41),
    "C": ([55, 60, 64, 67], 36), "Gm": ([55, 62, 67, 70], 43), "A": ([57, 61, 64, 69], 45),
}


def menu():
    """Neon Drift: a calm 16-bar loop for the home screens."""
    s = Song(96, 16)
    prog = ["Dm", "Bb", "F", "C"] * 2 + ["Gm", "Bb", "Dm", "C", "Gm", "Bb", "F", "A"]
    for bar, name in enumerate(prog):
        chord, root = MENU_CHORDS[name]
        s.add("pad", supersaw(chord, s.sec(4) + 0.6, 1500, 0.5, 0.6), bar * 4)
        arp(s, bar, chord, [0, 2, 1, 3, 2, 0, 3, 1] * 2, bright=0.6, gain=0.55)
        for i in range(8):  # Soft eighths, octave jump on the offbeat.
            s.add("bass", bass(root + (12 if i % 4 == 3 else 0), s.sec(0.45), 1.3, 0.6), bar * 4 + i * 0.5, 0, 0.6)
        if bar >= 4:
            s.kick(bar * 4, 0.8)
            s.kick(bar * 4 + 2, 0.7)
            if bar % 4 == 3:
                s.kick(bar * 4 + 3.5, 0.5)
            s.add("drums", snare(210, 0.25), bar * 4 + 1, 0, 0.55)
            s.add("drums", snare(210, 0.25), bar * 4 + 3, 0, 0.55)
            for i in range(8):
                s.add("hats", hat(False, i % 3), bar * 4 + i * 0.5 + 0.0, 0.25, 0.5 if i % 2 else 0.25)
        else:
            s.kick(bar * 4, 0.6)
        for i in range(16):
            s.add("hats", shaker(i % 4), bar * 4 + i * 0.25, -0.3, 0.7 if i % 4 == 2 else 0.35)
    for bar in (4, 6):  # The hook on bells, answered by the arp.
        melody(s, bar, hook(69), lambda note, sec: bell(note, 1.4), "bells", 1.3)
    tune = [
        [(0, 1.5, 74), (1.5, 0.5, 72), (2, 1, 70), (3, 1, 67)],
        [(0, 1.5, 65), (1.5, 0.5, 67), (2, 1.5, 70), (3.5, 0.5, 69)],
        [(0, 3, 69), (3, 0.5, 65), (3.5, 0.5, 67)],
        [(0, 2, 67), (2, 1, 64), (3, 1, 60)],
        [(0, 1.5, 74), (1.5, 0.5, 72), (2, 1, 70), (3, 1, 74)],
        [(0, 1.5, 77), (1.5, 0.5, 74), (2, 1, 72), (3, 1, 70)],
        [(0, 2, 69), (2, 1, 72), (3, 1, 77)],
        [(0, 3, 76), (3, 1, 73)],
    ]
    for i, notes in enumerate(tune):
        melody(s, 8 + i, notes, lambda note, sec: lead(note, sec, "soft"), "lead", 1.3)
    s.add("fx", crash(2.0), 4 * 4, 0.2, 0.35)
    s.add("fx", crash(2.0), 8 * 4, -0.2, 0.4)
    for i, note in enumerate([50, 53, 57, 60]):  # Tom fill into the loop.
        s.add("drums", tom(note), 15 * 4 + 3 + i * 0.25, -0.4 + i * 0.25, 0.5)
    sends = {"pad": (0.35, 0.0), "arp": (0.25, 0.45), "lead": (0.4, 0.35), "bells": (0.5, 0.3),
             "drums": (0.12, 0.0), "hats": (0.05, 0.0), "fx": (0.3, 0.0)}
    return s.render(sends, ducked=("pad", "bass", "arp"), duck=0.45)


FIGHT_CHORDS = {  # A minor.
    "Am": ([57, 60, 64, 69], 33), "F": ([57, 60, 65, 69], 29), "C": ([55, 60, 64, 67], 36),
    "G": ([55, 59, 62, 67], 31), "E": ([56, 59, 64, 68], 28),
}
FIGHT_HOOK = [  # Bars 5-8 over Am F C G, then 13-16 over F G E E.
    [(0, .5, 76), (.5, .5, 81), (1, .5, 83), (1.5, 1, 84), (2.5, .5, 83), (3, 1, 81)],
    [(0, .5, 77), (.5, .5, 81), (1, 1, 84), (2, .5, 86), (2.5, .5, 84), (3, 1, 81)],
    [(0, .5, 79), (.5, .5, 84), (1, .5, 86), (1.5, 1.5, 88), (3, .5, 86), (3.5, .5, 84)],
    [(0, 2, 83), (2, .5, 79), (2.5, .5, 81), (3, 1, 83)],
]
FIGHT_HOOK_2 = [
    [(0, .5, 81), (.5, .5, 84), (1, 1, 88), (2, .5, 86), (2.5, .5, 84), (3, 1, 81)],
    [(0, .5, 83), (.5, .5, 86), (1, 1, 91), (2, .5, 88), (2.5, .5, 86), (3, 1, 83)],
    [(0, 1, 80), (1, .5, 83), (1.5, 1.5, 88), (3, .5, 86), (3.5, .5, 83)],
    [(0, 2, 88)],
]


def _fight_bar(s, bar, name, transpose, intensity, bars_total):
    chord, root = FIGHT_CHORDS[name]
    chord = [c + transpose for c in chord]
    root += transpose
    s.add("pad", supersaw(chord, s.sec(4) + 0.3, 2200, 0.05, 0.3), bar * 4, gain=0.7)
    pattern = [0, 1, 2, 3, 2, 1, 3, 2] * 2 if intensity < 2 else [0, 2, 3, 1, 3, 2, 3, 0] * 2
    arp(s, bar, chord, pattern, bright=1.0, gain=0.6)
    # Driving bass: root on the beat, octave on the offbeat, 16ths in overtime.
    step = 0.25 if intensity >= 2 else 0.5
    for i in range(int(4 / step)):
        up = 12 if (i % 2 == 1) else 0
        s.add("bass", bass(root + 12 + up, s.sec(step * 0.9), 2.0, 1.0), bar * 4 + i * step, 0, 0.6)
    for b in range(4):
        s.kick(bar * 4 + b)
    for b in (1, 3):
        s.add("drums", clap(), bar * 4 + b, 0, 0.7)
        s.add("drums", snare(200, 0.18), bar * 4 + b, 0, 0.5)
    for i in range(16):
        accent = 0.6 if i % 4 == 2 else 0.28
        if i % 4 == 2:
            s.add("hats", hat(True, i % 2), bar * 4 + i * 0.25, 0.3, 0.35)
        elif intensity >= 1 or i % 2 == 0:
            s.add("hats", hat(False, i % 3), bar * 4 + i * 0.25, 0.3 if i % 2 else -0.2, accent)
    if (bar + 1) % 8 == 0 or bar == bars_total - 1:  # Snare roll into the next phrase.
        for i in range(8):
            s.add("drums", snare(220 + i * 12, 0.12), bar * 4 + 2 + i * 0.25, 0, 0.25 + 0.06 * i)


def fight():
    """Bounce Brawl: the 16-bar fight loop."""
    s = Song(128, 16)
    prog = ["Am", "F", "C", "G"] * 2 + ["F", "G", "Am", "Am", "F", "G", "E", "E"]
    for bar, name in enumerate(prog):
        _fight_bar(s, bar, name, 0, 0 if bar < 4 else 1, 16)
    for i, notes in enumerate(FIGHT_HOOK):
        melody(s, 4 + i, notes, lambda note, sec: lead(note, sec, "saw"), "lead", 1.6)
    for i, notes in enumerate(FIGHT_HOOK_2):
        melody(s, 12 + i, notes, lambda note, sec: lead(note, sec, "saw"), "lead", 1.7)
    for bar in range(8, 12):  # Offbeat stabs while the lead rests.
        chord, _ = FIGHT_CHORDS[prog[bar]]
        for b in (0.5, 1.5, 2.5, 3.5):
            s.add("stabs", supersaw([c + 12 for c in chord], s.sec(0.3), 4000, 0.004, 0.1), bar * 4 + b, gain=0.6)
    for bar in (0, 8):
        s.add("fx", crash(), bar * 4, 0.2, 0.5)
    s.add("fx", riser(s.sec(8)), 10 * 4, 0, 0.6)
    sends = {"pad": (0.25, 0.0), "arp": (0.2, 0.35), "lead": (0.3, 0.3), "stabs": (0.3, 0.2),
             "drums": (0.08, 0.0), "fx": (0.25, 0.0)}
    return s.render(sends, ducked=("pad", "bass", "arp", "stabs"), duck=0.55, delay_beats=0.75)


def overtime():
    """Overtime Rush: the fight at 152 BPM, a semitone up, everything doubled."""
    s = Song(152, 8)
    prog = ["Am", "F", "C", "G"] * 2
    for bar, name in enumerate(prog):
        _fight_bar(s, bar, name, 1, 2, 8)
    for half in (0, 4):
        for i, notes in enumerate(FIGHT_HOOK):
            melody(s, half + i, notes, lambda note, sec: lead(note, sec, "saw"), "lead", 1.4, 1)
            if half:
                melody(s, half + i, notes, lambda note, sec: lead(note, sec, "square"), "lead", 0.7, 13)
    for bar in range(4):  # An alarm wail under the first half.
        for b in range(0, 4, 2):
            n = int(s.sec(2) * SR)
            t = np.arange(n) / SR
            f = midi(81 + 1) * (1 + 0.06 * np.sin(2 * np.pi * t / s.sec(2) - np.pi / 2))
            s.add("fx", lp(pulse(f, n, 0.5), 2500) * env(n, 0.05, 1, 1, 0.1) * 0.08, bar * 4 + b, 0.3)
    s.add("fx", crash(), 0, 0.2, 0.55)
    s.add("fx", crash(), 16, -0.2, 0.5)
    sends = {"pad": (0.2, 0.0), "arp": (0.15, 0.3), "lead": (0.25, 0.25), "drums": (0.06, 0.0), "fx": (0.2, 0.0)}
    return s.render(sends, ducked=("pad", "bass", "arp"), duck=0.55, delay_beats=0.75)


VICTORY_CHORDS = {  # C major.
    "C": ([60, 64, 67, 72], 36), "G": ([59, 62, 67, 71], 43), "Am": ([60, 64, 69, 72], 45),
    "F": ([60, 65, 69, 72], 41),
}
VICTORY_FANFARE_BARS = 2


def victory():
    """Champion: a 2-bar fanfare, then an 8-bar loop (loop_offset skips the fanfare)."""
    s = Song(124, VICTORY_FANFARE_BARS + 8)
    # Fanfare: triplet pickup, a big C, a run up, then a held C with a crash.
    for i in range(3):
        s.add("brass", brass((67, 72), s.sec(1 / 3)), i / 3, 0, 0.8)
    s.add("brass", brass((60, 64, 67, 72), s.sec(1.5)), 1, 0, 1.0)
    s.add("brass", brass((64, 67, 76), s.sec(0.5)), 2.5, 0, 0.9)
    s.add("brass", brass((67, 72, 79), s.sec(1.0)), 3, 0, 0.95)
    s.add("brass", brass((60, 64, 67, 72, 84), s.sec(3.5)), 4, 0, 1.1)
    s.add("fx", crash(2.2), 4, 0, 0.6)
    s.add("fx", boom(), 4, 0, 0.5)
    for k in (1, 4):
        s.kick(k)
    for i, note in enumerate([72, 76, 79, 84, 88, 91]):  # Sparkle run.
        s.add("bells", bell(note, 1.0), 4.5 + i * 0.25, -0.5 + i * 0.2, 0.6)
    for i in range(4):
        s.add("drums", tom(52 + i * 3), 7 + i * 0.25, -0.3 + i * 0.2, 0.5)
    prog = ["C", "G", "Am", "F", "C", "G", "F", "G"]
    tune = [
        hook(67, True),
        [(0, 1.5, 74), (1.5, .5, 71), (2, 2, 67)],
        hook(72, True),
        [(0, 2, 77), (2, 1, 76), (3, 1, 74)],
        hook(67, True),
        [(0, 1.5, 79), (1.5, .5, 77), (2, 1, 76), (3, 1, 74)],
        [(0, 1, 72), (1, 1, 74), (2, 1, 76), (3, 1, 77)],
        [(0, 3, 79), (3, .5, 74), (3.5, .5, 71)],
    ]
    for i, name in enumerate(prog):
        bar = VICTORY_FANFARE_BARS + i
        chord, root = VICTORY_CHORDS[name]
        s.add("pad", supersaw(chord, s.sec(4) + 0.3, 2600, 0.03, 0.3), bar * 4, gain=0.55)
        arp(s, bar, chord, [0, 1, 2, 3, 2, 3, 1, 2] * 2, bright=1.2, gain=0.45)
        for b in range(4):  # Bouncy offbeat bass.
            s.add("bass", bass(root, s.sec(0.4), 1.6, 1.2), bar * 4 + b + 0.5, 0, 0.6)
            s.kick(bar * 4 + b, 0.9 if b % 2 == 0 else 0.6)
        for b in (1, 3):
            s.add("drums", clap(), bar * 4 + b, 0, 0.75)
        for k in range(8):
            s.add("hats", hat(k % 2 == 1, k % 3), bar * 4 + k * 0.5, 0.25, 0.3 if k % 2 else 0.2)
        melody(s, bar, tune[i], lambda note, sec: bell(note, max(0.6, sec + 0.4)), "bells", 0.9)
        melody(s, bar, tune[i], lambda note, sec: lead(note - 12, sec, "square", False), "lead", 0.45)
    sends = {"brass": (0.35, 0.15), "bells": (0.4, 0.3), "pad": (0.25, 0.0), "arp": (0.2, 0.3),
             "lead": (0.25, 0.2), "drums": (0.1, 0.0), "fx": (0.3, 0.0)}
    return s.render(sends, ducked=("pad", "bass", "arp"), duck=0.45, loop_from=VICTORY_FANFARE_BARS)


def intro():
    """Welcome: a riser into a big hit and the hook on bells, ringing out into the menu."""
    s = Song(96, 4, tail=1.5)
    # Bar 1: the menu's Dm pad opening up under a riser and a speeding arp.
    n = int(s.sec(4) * SR)
    left, right = supersaw([57, 62, 65, 69], s.sec(4), 6000, 1.5, 0.2)
    sweep = 400 + 3000 * np.linspace(0, 1, n) ** 2
    s.add("pad", (svf_lp(left, sweep, 1.2), svf_lp(right, sweep, 1.2)), 0, gain=0.8)
    s.add("fx", riser(s.sec(4)), 0, 0, 0.9)
    for i, (beat, note) in enumerate([(0, 62), (1, 65), (2, 69), (2.5, 74), (3, 77), (3.25, 81), (3.5, 86), (3.75, 89)]):
        s.add("arp", pluck(note, 0.5, 96, 0.5 + i * 0.1), beat, -0.4 + (i % 2) * 0.8, 0.6)
    # Bar 2: the hit, then the hook.
    s.kick(4, 1.2)
    s.add("fx", boom(), 4, 0, 0.8)
    s.add("fx", crash(2.6), 4, 0, 0.7)
    s.add("stabs", supersaw([50, 57, 62, 65, 69, 76], s.sec(8), 3200, 0.005, 3.0), 4, gain=0.8)
    melody(s, 1, hook(69), lambda note, sec: bell(note, 1.6), "bells", 1.0)
    melody(s, 1, hook(69), lambda note, sec: lead(note, sec, "soft"), "lead", 0.5)
    # Bar 3: the answer, landing on D with Bb then A under it.
    answer = [(0, 1.5, 77), (1.5, .5, 76), (2, 2, 74)]
    melody(s, 2, answer, lambda note, sec: bell(note, 2.0), "bells", 0.9)
    melody(s, 2, answer, lambda note, sec: lead(note, sec, "soft"), "lead", 0.5)
    s.add("pad", supersaw([58, 62, 65, 70], s.sec(2) + 0.5, 2200, 0.3, 0.8), 8, gain=0.6)
    s.add("pad", supersaw([57, 62, 65, 69], s.sec(6), 1800, 0.3, 3.0), 10, gain=0.6)
    s.add("bass", bass(38, s.sec(6), 1.4, 0.5), 4, 0, 0.8)
    s.add("bass", bass(34, s.sec(2), 1.4, 0.5), 8, 0, 0.8)
    s.add("bass", bass(38, s.sec(6), 1.4, 0.5), 10, 0, 0.8)
    s.add("drums", tom(57), 7.5, 0.3, 0.5)
    s.add("drums", tom(62), 7.75, -0.3, 0.5)
    s.kick(8, 0.8)
    sends = {"pad": (0.35, 0.0), "arp": (0.3, 0.4), "bells": (0.5, 0.35), "lead": (0.4, 0.3),
             "stabs": (0.4, 0.0), "fx": (0.3, 0.0), "drums": (0.15, 0.0)}
    out = s.render(sends, loop=False)
    fade = int(1.2 * SR)
    out[:, -fade:] *= np.linspace(1, 0, fade) ** 2
    return out


TRACKS = {
    "music_intro": intro,
    "music_menu": menu,
    "music_fight": fight,
    "music_overtime": overtime,
    "music_victory": victory,
}


def write_wav(path, x):
    with wave.open(path, "wb") as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes((np.clip(x.T, -1, 1) * 32767).astype("<i2").tobytes())


def write_ogg(name, x, wav_dir=""):
    path = os.path.join(OUT, name + ".ogg")
    with tempfile.TemporaryDirectory() as tmp:
        wav_path = os.path.join(wav_dir or tmp, name + ".wav")
        write_wav(wav_path, x)
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wav_path, "-c:a", "libvorbis",
                        "-q:a", "0", "-map_metadata", "-1", "-fflags", "+bitexact", "-flags:a", "+bitexact",
                        path], check=True)
    return path


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--only", default="")
    ap.add_argument("--wav", default="", help="also keep the .wav files in this folder")
    args = ap.parse_args()
    for name, make in TRACKS.items():
        if name.startswith(args.only) or name.startswith("music_" + args.only):
            x = make()
            print(write_ogg(name, x, args.wav), "%.1fs" % (x.shape[1] / SR))


if __name__ == "__main__":
    main()
