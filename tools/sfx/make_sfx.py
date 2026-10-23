#!/usr/bin/env python3
"""Renders every Battle Balls sound effect from code (music: tools/music/).

Each sound is a small recipe (oscillators, noise, pitch sweeps, envelopes)
in the style of sfxr, so any sound can be tweaked by editing a number here
and re-running. Output goes to game/audio/ and is committed, so CI and the
game never need Python.

Usage: python3 tools/sfx/make_sfx.py [--only NAME_PREFIX]
Needs numpy.

Rules of thumb (see /design/sound.md):
- Phone speakers play almost nothing below ~250 Hz, so "weight" comes from a
  click transient plus a pitched body in the 300 Hz - 3 kHz band.
- Rendering is seeded, so re-running gives byte-identical files.
"""
import argparse
import os
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


def crit():
    """A critical hit: a bright two-note 'ka-ching' ring over a hard crack."""
    crack = bandnoise(0.05, 1200, 9000) * env(0.05, 0.0004, 6)
    ring = mix(osc(np.full(int(0.22 * SR), midi(91)), "sine") * env(0.22, 0.001, 5) * 0.45,
               osc(np.full(int(0.22 * SR), midi(91) * 2.76), "sine") * env(0.22, 0.001, 8) * 0.15)
    ring2 = osc(np.full(int(0.26 * SR), midi(96)), "sine") * env(0.26, 0.001, 5) * 0.4
    return seq([(0, crack), (0.005, ring), (0.06, ring2)])


def backstab():
    """A hit from behind: a quick rising swish, then a sharp low 'thwack'."""
    swish = bandnoise(0.12, 2000, 8000) * env(0.12, 0.08, 2) * 0.35
    thwack = mix(bandnoise(0.03, 600, 6000) * env(0.03, 0.0004, 6),
                 osc(sweep(520, 180, 0.12, 0.5), "tri") * env(0.12, 0.001, 6) * 0.8)
    return seq([(0, swish), (0.1, thwack)])


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


# --- Summons -----------------------------------------------------------------

def summon_pop():
    """A capsule popping open: a bubbly 'pok' then a quick rising sparkle.
    The game raises its pitch a step per rarity."""
    pop = mix(bandnoise(0.025, 400, 7000) * env(0.025, 0.0004, 6) * 0.7,
              osc(sweep(380, 1300, 0.09, 0.5), "sine") * env(0.09, 0.0008, 5))
    sparkle = mix(*[delay(osc(np.full(int(0.14 * SR), midi(n)), "sine") * env(0.14, 0.001, 6) * 0.32, i * 0.035)
                    for i, n in enumerate([84, 88, 91])])
    return seq([(0, pop), (0.05, sparkle)])


def summon_land():
    """An egg dropping onto the floor of the portal: a soft, hollow shell 'tok'."""
    tok = mix(bandnoise(0.02, 800, 5000) * env(0.02, 0.0004, 7) * 0.5,
              osc(sweep(720, 420, 0.07, 0.5), "tri") * env(0.07, 0.0008, 7) * 0.8)
    return tok * 0.8


def summon_charge():
    """A Legendary capsule shaking before it bursts: a rising shimmering swell."""
    dur = 0.6
    f = sweep(300, 1400, dur, 1.6) * (1 + 0.04 * np.sin(2 * np.pi * 22 * t_axis(dur)))
    swell = lowpass(osc(f, "saw"), 3000) * np.linspace(0.05, 1, int(dur * SR)) ** 2 * 0.45
    air = lowpass(noise(dur), sweep(800, 8000, dur, 1.5)) * np.linspace(0, 1, int(dur * SR)) ** 2 * 0.35
    return mix(swell, air)


def summon_legend():
    """A Legendary bursting out: a big crack, then a bright major fanfare and shimmer."""
    crack = mix(bandnoise(0.06, 500, 9000) * env(0.06, 0.0004, 5),
                osc(sweep(900, 200, 0.15, 0.5), "tri") * env(0.15, 0.001, 5) * 0.7)
    fan = jingle([72, 76, 79, 84, 88], 0.07, 0.9, shape="square", cutoff=5000)
    chord = mix(*[osc(np.full(int(1.0 * SR), midi(n)), "tri") * env(1.0, 0.01, 2.5) * 0.22 for n in [76, 79, 84, 88]])
    shimmer = mix(*[delay(osc(np.full(int(0.16 * SR), midi(n)), "sine") * env(0.16, 0.001, 6) * 0.25, 0.3 + i * 0.05)
                    for i, n in enumerate([96, 100, 103, 108, 103, 108])])
    return seq([(0, crack), (0.04, fan), (0.32, chord), (0, shimmer)])


# --- Critter signature sounds (render + sound pass, 2026-10) -------------------

def chomp():
    """Count Nibbles' bite: two quick teeth clacks and a wet crunch."""
    def clack(f):
        return mix(bandnoise(0.02, 2000, 9000) * env(0.02, 0.0005, 8),
                   osc(sweep(f, f * 0.6, 0.05, 0.5), "tri") * env(0.05, 0.0005, 9) * 0.8)
    crunch = bandnoise(0.12, 600, 4000) * (rng.uniform(0, 1, int(0.12 * SR)) > 0.5) * env(0.12, 0.002, 5) * 0.7
    return seq([(0.0, clack(1500)), (0.055, clack(1100)), (0.06, crunch)])


def thwomp():
    """Boulder landing a hit: a heavy stone 'THWOMP' with gravel rattle."""
    dur = 0.42
    thud = osc(sweep(420, 95, dur, 0.4), "sine") * env(dur, 0.001, 5) * 1.0
    body = osc(sweep(260, 120, dur, 0.5), "tri") * env(dur, 0.001, 7) * 0.6
    crack = bandnoise(0.05, 800, 6000) * env(0.05, 0.0005, 6) * 0.9
    gravel = bandnoise(0.3, 1200, 5000) * (rng.uniform(0, 1, int(0.3 * SR)) > 0.85) * env(0.3, 0.01, 4) * 0.6
    return mix(crack, thud, body, delay(gravel, 0.04))


def pew():
    """Pip's pea: a springy 'thoop' as it spits."""
    dur = 0.13
    pop = osc(sweep(380, 1500, dur, 0.6), "sine") * env(dur, 0.002, 6)
    air = bandnoise(0.05, 1500, 7000) * env(0.05, 0.001, 7) * 0.4
    return mix(pop, air)


def crackle():
    """Static's zap: a sharp electric snap with a buzzing crackle tail."""
    dur = 0.3
    snap = bandnoise(0.015, 3000, 12000) * env(0.015, 0.0003, 5) * 1.2
    sparks = bandnoise(dur, 2000, 10000) * (rng.uniform(0, 1, int(dur * SR)) > 0.82) * env(dur, 0.001, 5)
    buzz = osc(np.full(int(dur * SR), 95.0), "square") * bandnoise(dur, 800, 4000) * env(dur, 0.001, 6) * 0.6
    tone = osc(sweep(1800, 600, dur, 0.5), "saw") * env(dur, 0.001, 8) * 0.25
    return mix(snap, sparks, buzz, tone)


def rustle():
    """Tumble gathering a twig: a dry crackle of sticks and a soft whoomp."""
    dur = 0.28
    sticks = bandnoise(dur, 1500, 7000) * (rng.uniform(0, 1, int(dur * SR)) > 0.9) * env(dur, 0.005, 3)
    swish = bandnoise(dur, 600, 3000) * env(dur, 0.04, 4) * 0.4
    whoomp = osc(sweep(260, 420, dur, 0.7), "sine") * env(dur, 0.01, 6) * 0.5
    return mix(sticks * 1.4, swish, whoomp)


def fizzpop():
    """Fizz bursting: a can-tab 'pssshk' with bubbling hiss."""
    tab = bandnoise(0.02, 1500, 8000) * env(0.02, 0.0005, 6)
    dur = 0.55
    hiss = bandnoise(dur, 3000, 11000) * env(dur, 0.003, 3) * 0.8
    fizz = bandnoise(dur, 2500, 9000) * (rng.uniform(0, 1, int(dur * SR)) > 0.93) * env(dur, 0.01, 2)
    return mix(tab, delay(hiss, 0.01), delay(fizz * 1.3, 0.05))


def drum():
    """Drum: a punchy tom with a snare rattle."""
    dur = 0.3
    tom = osc(sweep(330, 180, dur, 0.5), "sine") * env(dur, 0.001, 6)
    skin = osc(sweep(560, 300, 0.08, 0.5), "tri") * env(0.08, 0.001, 7) * 0.5
    snare = bandnoise(0.15, 1500, 7000) * env(0.15, 0.001, 6) * 0.45
    return mix(tom, skin, snare)


def rain():
    """Drizzle's shower: a second of soft rain patter."""
    dur = 1.0
    wash = bandnoise(dur, 1200, 6000) * 0.35
    drops = bandnoise(dur, 2500, 9000) * (rng.uniform(0, 1, int(dur * SR)) > 0.97) * 1.4
    e = np.minimum(1, np.minimum(t_axis(dur) / 0.15, (dur - t_axis(dur)) / 0.25))
    return mix(wash, drops) * e


def hum():
    """Quasar flaring its beams to the walls: a deep rising 'vwoooom'."""
    dur = 0.9
    f = sweep(140, 260, dur, 0.6)
    body = osc(f, "saw") * 0.5 + osc(f * 2.0, "square") * 0.25 + osc(f * 3.01, "sine") * 0.3
    body = lowpass(body, sweep(900, 2500, dur, 0.8)) * env(dur, 0.08, 2, hold=0.3)
    shimmer = bandnoise(dur, 2000, 6000) * env(dur, 0.1, 3) * 0.15
    return mix(body, shimmer)


def ticktock():
    """Clockwork's tick ring: a crisp tick-tock and a spring twang."""
    tick = bandnoise(0.03, 2500, 7000) * env(0.03, 0.0005, 8)
    tock = bandnoise(0.04, 900, 3000) * env(0.04, 0.0005, 7) * 0.9
    dur = 0.35
    twang = osc(sweep(900, 700, dur, 0.5), "tri") * env(dur, 0.002, 4) * 0.25
    return mix(tick, delay(tock, 0.16), delay(twang, 0.02))


def splash():
    """Leviathan bursting up: a deep water whoomp and a wash of spray."""
    dur = 0.7
    boom = osc(sweep(120, 55, dur, 0.4), "sine") * env(dur, 0.005, 4)
    wash = lowpass(bandnoise(dur, 300, 6000), sweep(6000, 1200, dur, 0.6)) * env(dur, 0.01, 2.5) * 0.9
    drops = bandnoise(dur, 2000, 8000) * (rng.uniform(0, 1, int(dur * SR)) > 0.96) * env(dur, 0.05, 2) * 0.8
    return mix(boom, wash, delay(drops, 0.08))


def shatter():
    """Ice shattering: a glassy crack with tinkling shards."""
    crack = bandnoise(0.06, 2000, 10000) * env(0.06, 0.0005, 6)
    dur = 0.6
    bells = sum(osc(np.full(int(dur * SR), f), "sine") * env(dur, 0.001, 5 + i) * 0.18
                for i, f in enumerate([2637, 3520, 4186, 5274]))
    grit = bandnoise(dur, 4000, 11000) * (rng.uniform(0, 1, int(dur * SR)) > 0.95) * env(dur, 0.01, 3) * 0.6
    return mix(crack * 1.2, delay(bells, 0.01), delay(grit, 0.02))


def clunk():
    """Gearbox shifting / Clam clamping: a heavy metal clunk with a ratchet."""
    body = osc(sweep(180, 90, 0.18, 0.5), "square") * env(0.18, 0.001, 9) * 0.5
    knock = lowpass(bandnoise(0.08, 300, 3000), 2500) * env(0.08, 0.0005, 7)
    ratchet = mix(*[delay(bandnoise(0.015, 2000, 6000) * env(0.015, 0.0005, 6) * 0.5, 0.03 * i) for i in range(3)])
    return mix(knock * 1.2, body, ratchet)


def glug():
    """Brewster's cauldron: a bubbly glug-glug and a little pop."""
    parts = []
    for i, f in enumerate([220, 300, 260]):
        d = 0.09
        parts.append(delay(osc(sweep(f, f * 1.8, d, 0.6), "sine") * env(d, 0.004, 5) * 0.8, 0.07 * i))
    pop = delay(osc(sweep(900, 1500, 0.04, 1.0), "sine") * env(0.04, 0.001, 6) * 0.6, 0.24)
    return mix(*parts, pop)


def whoosh():
    """Drako's fire breath: a roaring rush of flame."""
    dur = 0.6
    roar = lowpass(bandnoise(dur, 150, 5000), sweep(800, 3500, dur, 0.4)) * env(dur, 0.03, 2.5)
    rumble = osc(sweep(90, 60, dur, 0.5), "saw") * env(dur, 0.02, 3) * 0.25
    crackle = bandnoise(dur, 2500, 9000) * (rng.uniform(0, 1, int(dur * SR)) > 0.97) * env(dur, 0.05, 2) * 0.6
    return mix(roar * 1.3, lowpass(rumble, 600), crackle)


def buzz():
    """A bee: a short buzzy zzz with a wobble."""
    dur = 0.3
    t = t_axis(dur)
    f = 210 + 25 * np.sin(2 * np.pi * 18 * t)
    return lowpass(osc(f, "saw"), 2200) * env(dur, 0.01, 3) * 0.6


def puff():
    """Whiff's cloud blooming: a soft airy 'pfff' with a low wobble."""
    dur = 0.5
    air = lowpass(bandnoise(dur, 200, 4000), sweep(3000, 700, dur, 0.5)) * env(dur, 0.02, 3)
    wob = osc(sweep(140, 90, dur, 0.5), "sine") * (1 + 0.5 * np.sin(2 * np.pi * 22 * t_axis(dur))) * env(dur, 0.01, 4) * 0.35
    return mix(air, wob)


def roar():
    """Yeti's roar: a big growl with a snowy rumble."""
    dur = 0.8
    t = t_axis(dur)
    f = sweep(160, 95, dur, 0.6) * (1 + 0.04 * np.sin(2 * np.pi * 30 * t))
    growl = lowpass(osc(f, "saw"), 1200) * env(dur, 0.03, 2.2) * 0.8
    breath = lowpass(bandnoise(dur, 200, 3000), 1500) * env(dur, 0.05, 2) * 0.5
    snow = delay(bandnoise(0.5, 1500, 8000) * env(0.5, 0.05, 3) * 0.3, 0.25)
    return mix(growl, breath, snow)


def cannon():
    """Mortar firing: a toy-cannon 'thoomp' with a puff of smoke."""
    dur = 0.45
    thump = osc(sweep(140, 45, dur, 0.4), "sine") * env(dur, 0.002, 6)
    blast = lowpass(bandnoise(0.2, 100, 4000), 1800) * env(0.2, 0.001, 8) * 0.9
    smoke = lowpass(bandnoise(dur, 200, 2000), 900) * env(dur, 0.05, 3) * 0.35
    return mix(thump, blast, smoke)


def splat():
    """Painter's paint: a wet, cartoon splat."""
    dur = 0.25
    wet = lowpass(bandnoise(dur, 300, 5000), sweep(5000, 800, dur, 0.5)) * env(dur, 0.002, 6)
    blob = osc(sweep(420, 160, 0.12, 0.6), "sine") * env(0.12, 0.002, 6) * 0.6
    return mix(wet, blob)


def sonar():
    """Sonar's ping: a clear sonar blip with an echo."""
    dur = 0.25
    blip = osc(sweep(1900, 1750, dur, 1.0), "sine") * env(dur, 0.002, 5) * 0.8
    return mix(blip, delay(blip * 0.4, 0.14), delay(blip * 0.15, 0.28))


def twinkle():
    """Comet's shooting star: a quick sparkly run up."""
    parts = []
    for i, n in enumerate([84, 88, 91, 96]):
        d = 0.12
        parts.append(delay(osc(np.full(int(d * SR), midi(n)), "sine") * env(d, 0.002, 6) * 0.45, 0.04 * i))
    return mix(*parts)


def zing():
    """A family edge hit: a bright upward 'zing' laid over the normal hit.
    The game pitches it per family (and higher on a very good hit)."""
    d = 0.2
    body = osc(sweep(midi(79), midi(91), d, 0.4), "tri") * env(d, 0.001, 5) * 0.4
    shine = osc(sweep(midi(91), midi(98), d, 0.4), "sine") * env(d, 0.001, 7) * 0.22
    tick = bandnoise(0.025, 3000, 10000) * env(0.025, 0.0004, 6) * 0.3
    return mix(tick, body, shine)


SOUNDS = {
    "hit_0": lambda: hit(0), "hit_1": lambda: hit(1), "hit_2": lambda: hit(2),
    "hit_big": lambda: hit(0, big=True),
    "wall_0": lambda: wall(0), "wall_1": lambda: wall(1), "wall_2": lambda: wall(2),
    "flip": flip, "snap": snap, "crit": crit, "backstab": backstab,
    "ko": ko, "heal": heal, "slurp": slurp, "zap": zap, "sizzle": sizzle,
    "overtime": overtime, "heartbeat": heartbeat,
    "win": win, "lose": lose, "draw": draw, "go": go, "launch": launch, "stretch": stretch, "click": click,
    "summon_pop": summon_pop, "summon_land": summon_land, "summon_charge": summon_charge, "summon_legend": summon_legend,
    "chomp": chomp, "thwomp": thwomp, "pew": pew,
    "crackle": crackle, "rustle": rustle, "fizzpop": fizzpop, "drum": drum, "rain": rain, "hum": hum,
    "ticktock": ticktock, "splash": splash, "shatter": shatter,
    "clunk": clunk, "glug": glug, "whoosh": whoosh, "buzz": buzz, "puff": puff, "roar": roar,
    "cannon": cannon, "splat": splat, "sonar": sonar, "twinkle": twinkle, "zing": zing,
}



# --- Battle sound pass (2026-10-22) -------------------------------------------
# Family voices, family collision knocks, and a signature sound for every
# critter whose ability used to borrow a generic zap or flip. Rendered at
# BATTLE_RATE and imported as QOA (compress/mode=2 in each .wav.import; set it
# for any new sound here) to keep the download small; phone speakers stop well
# below it, and the web build decodes QOA when it registers each sound.

BATTLE_RATE = 22050


def tone(f, dur, shape="sine"):
    """A steady note (f may be a number or an array of frequencies)."""
    return osc(np.broadcast_to(np.asarray(f, dtype=float), (int(dur * SR),)).copy(), shape)


def bell(f, dur, decay=6.0, partials=((1, 1.0), (2.76, 0.35), (5.4, 0.15))):
    """A struck metal/glass note: inharmonic partials, each fading faster."""
    return mix(*[tone(f * r, dur) * env(dur, 0.0008, decay * (1 + i * 0.6)) * a
                 for i, (r, a) in enumerate(partials) if f * r < 0.45 * SR]) # Nothing past Nyquist.


def pluck(f, dur, bright=4000):
    """A plucked string: a decaying saw through a closing lowpass."""
    return lowpass(tone(f, dur, "saw"), sweep(bright, 300, dur, 0.4)) * env(dur, 0.001, 5)


def crackles(dur, density=0.9, lo=1500, hi=8000):
    """Sparse random ticks: fire, gravel, static."""
    return bandnoise(dur, lo, hi) * (rng.uniform(0, 1, int(dur * SR)) > density)


def glide(f0, f1, f2, dur, split, curve=1.0):
    """f0 to f1 over the first `split` seconds, then on to f2: exactly dur long."""
    n = int(dur * SR)
    a = int(split * SR)
    return np.concatenate([f0 * (f1 / f0) ** np.linspace(0, 1, a) ** curve, f1 * (f2 / f1) ** np.linspace(0, 1, n - a)])


def vib(dur, rate, depth):
    return 1 + depth * np.sin(2 * np.pi * rate * t_axis(dur))


# Family voices: the 'ouch' a critter squeaks when hurt, pitched per critter
# by its file's sound.pitch. Two takes each so repeats don't sound copied.

def ouch_nature(v):
    """A little bird-like chirp-tweet."""
    p = [1.0, 1.1][v]
    d = 0.14
    f = glide(1500 * p, 2600 * p, 1300 * p, d, 0.05)
    voice = osc(f * vib(d, 30, 0.03), "sine") * env(d, 0.003, 3) + osc(f * 2, "sine") * env(d, 0.003, 6) * 0.2
    click = bandnoise(0.01, 1500, 6000) * env(0.01, 0.0005, 6) * 0.3
    return mix(click, voice)


def ouch_sea(v):
    """A bubbly 'blub!' with a wobble."""
    p = [1.0, 1.12][v]
    d = 0.17
    f = sweep(900 * p, 420 * p, d, 0.6) * vib(d, 38, 0.12)
    voice = osc(f, "sine") * env(d, 0.004, 3) + osc(f * 1.5, "tri") * env(d, 0.004, 6) * 0.25
    pops = mix(*[delay(tone(1800 * p + 300 * i, 0.03) * env(0.03, 0.001, 6) * 0.25, 0.05 + 0.04 * i) for i in range(2)])
    return mix(voice, pops)


def ouch_tech(v):
    """A robot 'bee-boop!': two ring-modulated bleeps."""
    p = [1.0, 1.1][v]
    def bleep(f, d):
        return tone(f, d, "square") * tone(f * 0.5 + 70, d) * env(d, 0.001, 2.5)
    return lowpass(seq([(0, bleep(1400 * p, 0.05)), (0.055, bleep(900 * p, 0.09))]), 5000) * 0.9


def ouch_sweet(v):
    """A squishy little 'eep!' with a wet squelch."""
    p = [1.0, 1.1][v]
    d = 0.15
    f = glide(1100 * p, 1800 * p, 1500 * p, d, 0.04) * vib(d, 24, 0.04)
    voice = lowpass(osc(f, "tri"), 4500) * env(d, 0.005, 3)
    squelch = lowpass(noise(0.07), sweep(600, 2500, 0.07)) * env(0.07, 0.005, 4) * 0.45
    return mix(squelch, voice)


def ouch_frost(v):
    """A crystalline 'ii!' with bell sparkle and a frosty breath."""
    p = [1.0, 1.08][v]
    d = 0.18
    f = sweep(1900 * p, 1500 * p, d, 0.5)
    voice = osc(f, "sine") * env(d, 0.004, 3) * 0.8
    sparkle = bell(3600 * p, d, 7) * 0.3
    breath = bandnoise(d, 3000, 9000) * env(d, 0.02, 4) * 0.2
    return mix(voice, sparkle, breath)


def ouch_toybox(v):
    """A rubber squeaky toy being squeezed."""
    p = [1.0, 1.12][v]
    d = 0.18
    f = glide(800 * p, 1400 * p, 1400 * p, d, 0.03) * vib(d, 22, 0.06)
    voice = lowpass(osc(f, "square"), 3500) * env(d, 0.004, 2.2) * 0.55
    air = bandnoise(d, 2500, 7000) * env(d, 0.004, 3) * 0.12
    return mix(voice, air)


def ouch_spooky(v):
    """A ghostly 'oo-eek' that wavers and echoes."""
    p = [1.0, 1.1][v]
    d = 0.2
    f = sweep(700 * p, 1300 * p, d, 1.4) * vib(d, 9, 0.06)
    voice = osc(f, "sine") * env(d, 0.03, 2) + osc(f * 1.01, "tri") * env(d, 0.03, 3) * 0.3
    return mix(voice, delay(voice * 0.35, 0.07), delay(voice * 0.15, 0.14))


def ouch_fire(v):
    """A crackly little 'yip!' with sparks."""
    p = [1.0, 1.1][v]
    d = 0.14
    f = sweep(1500 * p, 800 * p, d, 0.6)
    voice = lowpass(osc(f, "saw"), 3500) * env(d, 0.003, 3) * 0.6
    sparks = crackles(0.16, 0.9, 2500, 9000) * env(0.16, 0.003, 3) * 0.6
    return mix(voice, sparks)


def ouch_cosmic(v):
    """A sparkly falling 'wiu' with a shimmery chorus."""
    p = [1.0, 1.1][v]
    d = 0.2
    f = sweep(1700 * p, 900 * p, d, 0.5)
    voice = mix(osc(f, "sine"), osc(f * 1.008, "sine") * 0.7, osc(f * 2.01, "sine") * 0.2) * env(d, 0.004, 3) * 0.7
    twink = delay(bell(4200 * p, 0.12, 8) * 0.25, 0.04)
    return mix(voice, twink)


# Family knocks: a short tap of the family's material laid under every bump.

def knock_nature():
    """Wood block."""
    return mix(bandnoise(0.008, 2000, 7000) * env(0.008, 0.0004, 6) * 0.5,
               tone(950, 0.09, "tri") * env(0.09, 0.0006, 9), tone(2600, 0.04) * env(0.04, 0.0005, 9) * 0.3)


def knock_sea():
    """A water bloop."""
    return osc(sweep(350, 1100, 0.09, 0.6), "sine") * env(0.09, 0.002, 5)


def knock_tech():
    """A metal tink with a digital blip."""
    return mix(bell(2100, 0.12, 8, ((1, 1.0), (2.4, 0.4), (4.1, 0.2))), delay(tone(1300, 0.025, "square") * 0.25, 0.0))


def knock_sweet():
    """A jelly squish."""
    d = 0.11
    return mix(lowpass(noise(d), sweep(400, 1800, d, 0.5)) * env(d, 0.004, 4) * 1.2,
               osc(sweep(260, 520, d, 0.5) * vib(d, 30, 0.1), "sine") * env(d, 0.004, 5) * 0.6)


def knock_frost():
    """An ice clink."""
    return bell(3100, 0.14, 7, ((1, 1.0), (2.1, 0.5), (3.9, 0.3)))


def knock_toybox():
    """A rubbery boing."""
    d = 0.14
    return osc(sweep(300, 600, d, 0.3) * vib(d, 18, 0.12), "tri") * env(d, 0.002, 5)


def knock_spooky():
    """A hollow bone clack, twice."""
    k = mix(bandnoise(0.01, 1200, 5000) * env(0.01, 0.0004, 6), tone(720, 0.05, "tri") * env(0.05, 0.0005, 9))
    return seq([(0, k), (0.045, k * 0.6)])


def knock_fire():
    """An ember pop with a few sparks."""
    return mix(bandnoise(0.02, 300, 4000) * env(0.02, 0.0005, 6),
               osc(sweep(400, 160, 0.06), "sine") * env(0.06, 0.0005, 6) * 0.6,
               delay(crackles(0.1, 0.94, 3000, 9000) * env(0.1, 0.002, 3) * 0.7, 0.01))


def knock_cosmic():
    """A shimmering FM ping."""
    d = 0.16
    t = t_axis(d)
    return np.sin(2 * np.pi * 1600 * t + 2.5 * np.exp(-20 * t) * np.sin(2 * np.pi * 2240 * t)) * env(d, 0.001, 6)


# Critter signatures.

def zoom():
    """Zip speeding up off a wall: a tight rising whoosh (pitched up per stack)."""
    d = 0.22
    air = lowpass(bandnoise(d, 600, 8000), sweep(1200, 7000, d, 0.6)) * env(d, 0.05, 3)
    whine = osc(sweep(500, 1300, d, 0.6), "saw") * env(d, 0.03, 4) * 0.15
    return mix(air, lowpass(whine, 3000))


def kaboom():
    """A cartoon bomb: a hard crack, a round boom and falling debris."""
    d = 0.6
    crack = bandnoise(0.04, 600, 9000) * env(0.04, 0.0004, 5)
    boom = osc(sweep(260, 50, d, 0.35), "sine") * env(d, 0.001, 4)
    body = lowpass(bandnoise(d, 100, 5000), sweep(5000, 500, d, 0.5)) * env(d, 0.002, 3.5) * 0.9
    debris = delay(crackles(0.35, 0.95, 1500, 7000) * env(0.35, 0.02, 3) * 0.5, 0.12)
    return mix(crack, boom, body, debris)


def mine_drop():
    """A mine plopping down and arming: a soft plunk then a fuse hiss and a beep."""
    plunk = tone(520, 0.05, "tri") * env(0.05, 0.001, 7)
    hiss = bandnoise(0.2, 4000, 10000) * env(0.2, 0.01, 2) * 0.25
    beep = tone(1760, 0.04, "square") * env(0.04, 0.001, 2) * 0.25
    return seq([(0, plunk), (0.03, hiss), (0.2, lowpass(beep, 5000))])


def frost_crunch():
    """Chill's icy trail biting: a crisp frosty crackle."""
    d = 0.16
    return mix(crackles(d, 0.86, 3000, 11000) * env(d, 0.002, 3),
               bell(4400, d, 9, ((1, 0.25), (1.6, 0.15))))


def frost_breath():
    """A soft frosty 'fffff' with a glint."""
    d = 0.45
    breath = lowpass(bandnoise(d, 1500, 9000), sweep(9000, 3000, d)) * env(d, 0.06, 3) * 0.8
    return mix(breath, delay(bell(3800, 0.25, 6) * 0.25, 0.05))


def thorn_snap():
    """Bramble's thorns biting back: a woody snap with a metallic 'shing'."""
    snap = mix(bandnoise(0.015, 1500, 7000) * env(0.015, 0.0004, 6), tone(820, 0.05, "tri") * env(0.05, 0.0005, 9))
    shing = osc(sweep(2400, 3400, 0.18, 0.5), "sine") * env(0.18, 0.002, 5) * 0.35
    return mix(snap, delay(shing, 0.01))


def moon_bonk():
    """Orbit's moon bonking a foe: a deep warbling bonk."""
    d = 0.3
    return mix(osc(sweep(500, 200, d, 0.5) * vib(d, 14, 0.05), "sine") * env(d, 0.001, 5),
               bandnoise(0.02, 800, 5000) * env(0.02, 0.0005, 6) * 0.5)


def warble():
    """Orbit's gravity flaring: a low pulsing drone swell."""
    d = 0.5
    f = sweep(170, 240, d, 0.6) * vib(d, 7, 0.04)
    drone = lowpass(osc(f, "saw") * 0.6 + osc(f * 2, "sine") * 0.4, 1400) * env(d, 0.12, 2, hold=0.1)
    return drone


def void_suck():
    """Void collapsing: a reversed rush sucking inward, then dead silence."""
    d = 0.55
    rush = lowpass(bandnoise(d, 200, 8000), sweep(500, 7000, d, 2.0)) * np.linspace(0, 1, int(d * SR)) ** 2.5
    tone_up = osc(sweep(100, 500, d, 2.0), "saw") * np.linspace(0, 1, int(d * SR)) ** 3 * 0.3
    return mix(rush, lowpass(tone_up, 2000))


def nova_boom():
    """A star blowing up: a huge bright boom with a shimmering ring."""
    d = 0.8
    boom = osc(sweep(300, 45, d, 0.35), "sine") * env(d, 0.001, 3.5)
    blast = lowpass(bandnoise(d, 200, 9000), sweep(9000, 800, d, 0.5)) * env(d, 0.001, 3) * 0.8
    ring = mix(*[tone(midi(n), d) * env(d, 0.01, 3.5) * 0.18 for n in (84, 88, 91, 96)])
    return mix(boom, blast, delay(ring, 0.03))


def coal_hiss():
    """Sooty's hot patch: a sizzling hiss with ember crackles."""
    d = 0.5
    hiss = bandnoise(d, 3000, 10000) * env(d, 0.02, 3) * 0.5
    embers = crackles(d, 0.94, 1500, 7000) * env(d, 0.02, 2.5)
    return mix(hiss, embers, osc(sweep(200, 140, 0.2), "sine") * env(0.2, 0.002, 5) * 0.4)


def squirt():
    """Ink squirting a cloud: a wet squelchy spurt."""
    d = 0.3
    f = sweep(700, 250, d, 0.5) * vib(d, 26, 0.15)
    gush = lowpass(noise(d), f * 3) * env(d, 0.004, 3) * 1.4
    return mix(gush, osc(f, "sine") * env(d, 0.004, 4) * 0.4)


def lava_blorp():
    """Magmo's lava: a thick gloopy bubble and a hiss."""
    d = 0.28
    blorp = osc(sweep(160, 420, 0.12, 1.5), "sine") * env(0.12, 0.004, 4)
    pop = delay(osc(sweep(500, 900, 0.03), "sine") * env(0.03, 0.001, 5) * 0.6, 0.11)
    hiss = delay(bandnoise(0.2, 3000, 9000) * env(0.2, 0.01, 4) * 0.3, 0.1)
    return mix(blorp, pop, hiss, crackles(d, 0.96, 2000, 7000) * env(d, 0.01, 3) * 0.5)


def ghost_wooo():
    """Wisp phasing out: a breathy reversed shimmer that fades away."""
    d = 0.5
    f = sweep(600, 1100, d, 1.0) * vib(d, 6, 0.05)
    voice = osc(f, "sine") * env(d, 0.15, 3) * 0.5 + osc(f * 1.5, "sine") * env(d, 0.2, 4) * 0.2
    air = lowpass(bandnoise(d, 1000, 6000), 4000) * np.linspace(1, 0, int(d * SR)) ** 1.5 * np.linspace(0, 1, int(d * SR)) * 0.6
    return mix(voice, air, delay(voice * 0.3, 0.09))


def spook_hit():
    """Wisp's ambush: a sudden ghostly 'whoosh-BOO' hit."""
    swish = lowpass(bandnoise(0.1, 800, 6000), sweep(1500, 6000, 0.1)) * np.linspace(0, 1, int(0.1 * SR)) * 0.6
    boo = osc(sweep(380, 180, 0.25, 0.4) * vib(0.25, 8, 0.05), "tri") * env(0.25, 0.002, 4)
    return seq([(0, swish), (0.09, boo), (0.09, bandnoise(0.03, 600, 5000) * env(0.03, 0.0005, 6))])


def chrome_ching():
    """Echo copying an ability: a bright chrome 'ching' with a tinny shimmer."""
    return mix(bell(2600, 0.4, 4, ((1, 1.0), (2.0, 0.5), (3.01, 0.35), (4.2, 0.2))),
               delay(bell(3900, 0.3, 5) * 0.4, 0.05),
               osc(sweep(800, 3000, 0.15), "saw") * env(0.15, 0.002, 6) * 0.08)


def pinball_ding(v=0):
    """Pinball lighting a bumper: an arcade bell ding (pitched up per light)."""
    return mix(bell(1320, 0.35, 5, ((1, 1.0), (2.0, 0.3), (3.0, 0.15))), tone(2640, 0.03, "square") * env(0.03, 0.001, 3) * 0.15)


def flipper():
    """A pinball flipper: a solid plastic clack with a spring."""
    clack = mix(bandnoise(0.02, 1000, 7000) * env(0.02, 0.0004, 7), tone(380, 0.06, "square") * env(0.06, 0.0005, 9) * 0.4)
    spring = delay(osc(sweep(900, 700, 0.15) * vib(0.15, 45, 0.05), "tri") * env(0.15, 0.002, 5) * 0.25, 0.01)
    return mix(clack, spring)


def crunch():
    """A cookie bite: a dry crumbly crunch."""
    d = 0.18
    return mix(crackles(d, 0.7, 800, 6000) * env(d, 0.002, 4),
               bandnoise(0.03, 500, 3000) * env(0.03, 0.001, 6) * 0.7)


def bubble_blow():
    """Bubbles blowing its shield: a rising, wobbly 'bloooop'."""
    d = 0.3
    f = sweep(250, 900, d, 0.6) * vib(d, 12, 0.06)
    return osc(f, "sine") * env(d, 0.03, 2.5) + osc(f * 2, "sine") * env(d, 0.03, 4) * 0.2


def bubble_pop():
    """A bubble popping: a bright 'plip'."""
    return mix(osc(sweep(800, 2400, 0.05, 0.5), "sine") * env(0.05, 0.0005, 5),
               bandnoise(0.01, 3000, 10000) * env(0.01, 0.0003, 6) * 0.4)


def gum_stretch():
    """Gumdrop's gum string: a sticky rubbery stretch."""
    d = 0.3
    f = sweep(240, 520, d, 0.7)
    rub = lowpass(osc(f, "saw") * (0.6 + 0.4 * tone(f * 0.25 + 30, d, "square")), 1600) * env(d, 0.02, 2)
    stick = lowpass(noise(d), 1200) * (rng.uniform(0, 1, int(d * SR)) > 0.97) * env(d, 0.01, 2) * 0.8
    return mix(rub * 0.7, stick)


def gum_snap():
    """The gum string letting go: a wet elastic 'thwip'."""
    return mix(osc(sweep(1200, 300, 0.08, 0.5), "sine") * env(0.08, 0.0005, 5),
               lowpass(noise(0.05), 2500) * env(0.05, 0.001, 6) * 0.6)


def inflate():
    """Puff puffing up: a quick balloon-inflating 'fwoomp'."""
    d = 0.3
    air = lowpass(bandnoise(d, 300, 5000), sweep(800, 3500, d, 0.6)) * env(d, 0.05, 2) * 0.7
    body = osc(sweep(200, 480, d, 0.5), "sine") * env(d, 0.03, 3) * 0.6
    return mix(air, body)


def spines():
    """Puff's spines blasting out: a burst of tiny 'tsk' needles."""
    return mix(*[delay(bandnoise(0.02, 3000, 10000) * env(0.02, 0.0004, 6) * (0.8 - i * 0.1), i * 0.025) for i in range(5)],
               osc(sweep(1800, 2600, 0.12), "sine") * env(0.12, 0.001, 6) * 0.25)


def shell_clack():
    """Shelly pulling into its shell: a heavy hollow clack."""
    return mix(bandnoise(0.02, 600, 4000) * env(0.02, 0.0005, 6),
               tone(310, 0.18, "tri") * env(0.18, 0.001, 7), tone(680, 0.1) * env(0.1, 0.001, 9) * 0.4)


def dart():
    """Minnow panicking: a quick bubbly darting swish."""
    d = 0.25
    swish = lowpass(bandnoise(d, 600, 6000), sweep(2000, 6000, d, 0.5)) * env(d, 0.02, 3) * 0.6
    bubbles = mix(*[delay(osc(sweep(900 + 300 * i, 1800 + 300 * i, 0.03), "sine") * env(0.03, 0.001, 5) * 0.3, 0.03 + i * 0.04) for i in range(4)])
    return mix(swish, bubbles)


def spore():
    """A soft spore puff (Mossy's moss)."""
    d = 0.22
    return lowpass(bandnoise(d, 300, 3000), sweep(2500, 800, d)) * env(d, 0.02, 4) * 0.8


def snuff():
    """Flicker's flame going out: a short breathy 'fff' and a little smoke."""
    d = 0.3
    blow = lowpass(bandnoise(d, 500, 6000), sweep(5000, 900, d)) * env(d, 0.01, 4)
    return mix(blow, osc(sweep(300, 180, 0.12), "sine") * env(0.12, 0.002, 6) * 0.3)


def fwoomp():
    """A fire lighting up: a rising roar that catches."""
    d = 0.35
    roar = lowpass(bandnoise(d, 150, 6000), sweep(600, 5000, d, 0.5)) * env(d, 0.04, 3)
    return mix(roar, crackles(d, 0.95, 2500, 9000) * env(d, 0.05, 3) * 0.7)


def spring_boing():
    """Cogs unwinding: a big cartoon spring 'boyoyoing'."""
    d = 0.5
    f = sweep(260, 360, d, 0.5) * vib(d, 16, 0.18 * np.exp(-3 * t_axis(d)))
    return mix(osc(f, "tri") * env(d, 0.002, 3), osc(f * 2, "sine") * env(d, 0.002, 5) * 0.3,
               bandnoise(0.02, 1500, 7000) * env(0.02, 0.0004, 6) * 0.5)


def ratchet():
    """Cogs winding up: a quick ratchet click."""
    return mix(*[delay(bandnoise(0.012, 1500, 7000) * env(0.012, 0.0004, 7) * (0.6 + 0.2 * i), 0.035 * i) for i in range(3)],
               tone(1600, 0.03, "square") * env(0.03, 0.001, 6) * 0.1)


def sour():
    """Pucker souring a foe: a tight puckered wet squeak."""
    d = 0.16
    f = sweep(1400, 2100, d, 0.4) * vib(d, 40, 0.04)
    return mix(lowpass(osc(f, "square"), 3500) * env(d, 0.004, 3) * 0.4,
               lowpass(noise(d), 2000) * env(d, 0.002, 4) * 0.4)


def pucker_pop():
    """Full sour: a big juicy splurt."""
    d = 0.32
    splurt = lowpass(noise(d), sweep(4000, 600, d, 0.5) * vib(d, 30, 0.2)) * env(d, 0.002, 3) * 1.4
    return mix(splurt, osc(sweep(900, 300, 0.15), "sine") * env(0.15, 0.001, 5) * 0.6)


def seed_puff():
    """Pollen puffing its seeds: a light fluffy 'pfff' with a breeze."""
    d = 0.35
    air = lowpass(bandnoise(d, 800, 8000), sweep(6000, 2000, d)) * env(d, 0.01, 3) * 0.7
    return mix(air, delay(bell(2900, 0.15, 7) * 0.12, 0.03))


def candy_clack():
    """A hard candy knocking: a glassy, sugary 'tok'."""
    return mix(bell(1900, 0.12, 9, ((1, 1.0), (2.3, 0.4))), bandnoise(0.01, 2000, 8000) * env(0.01, 0.0004, 6) * 0.5)


def reel():
    """Hook's grapple: a whip crack and a fast fishing-reel ratchet."""
    whip = osc(sweep(400, 2400, 0.06, 0.4), "saw") * env(0.06, 0.001, 3) * 0.3
    clicks = mix(*[delay(bandnoise(0.008, 2500, 8000) * env(0.008, 0.0003, 6) * 0.5, 0.05 + 0.022 * i) for i in range(8)])
    return mix(lowpass(whip, 5000), bandnoise(0.02, 1500, 9000) * env(0.02, 0.0004, 5) * 0.6, clicks)


def disco_laser():
    """Disco's light beams: a funky little two-note synth 'pew-pew' chord."""
    def zip_(n):
        return lowpass(osc(sweep(midi(n) * 2, midi(n), 0.12, 0.4), "square"), 4000) * env(0.12, 0.001, 4) * 0.4
    return seq([(0, mix(zip_(76), zip_(83))), (0.07, mix(zip_(79), zip_(86)))])


def stoke():
    """Drako stoking its fire: a short rising crackle."""
    d = 0.2
    return mix(lowpass(bandnoise(d, 200, 4000), sweep(500, 3000, d)) * env(d, 0.03, 3) * 0.6,
               crackles(d, 0.9, 2500, 9000) * env(d, 0.01, 3))


def trumpet():
    """Mammoth's tusks: a short brassy trumpet blare."""
    d = 0.45
    f = glide(330, 470, 470, d, 0.08) * vib(d, 6, 0.012)
    brass = lowpass(osc(f, "saw"), sweep(900, 3000, d, 0.3)) * env(d, 0.03, 2, hold=0.1)
    return brass * 0.7


def ice_lock():
    """A foe freezing solid: a crisp crackling freeze with a glassy ring."""
    d = 0.35
    return mix(crackles(0.12, 0.8, 2000, 11000) * env(0.12, 0.001, 3),
               bell(2300, d, 5, ((1, 0.6), (1.5, 0.4), (2.6, 0.3))), bandnoise(0.03, 1000, 8000) * env(0.03, 0.0005, 6) * 0.6)


def nom():
    """Munch taking a bite: a cute 'nom'."""
    d = 0.12
    f = sweep(500, 700, d, 0.5)
    voice = lowpass(osc(f, "square"), sweep(800, 2000, d)) * env(d, 0.01, 3) * 0.6
    return mix(voice, bandnoise(0.02, 1500, 6000) * env(0.02, 0.0005, 7) * 0.3)


def gulp():
    """Munch swallowing a foe whole: a big descending gulp."""
    d = 0.3
    return mix(osc(sweep(400, 120, d, 0.6), "sine") * env(d, 0.01, 3),
               lowpass(noise(d), sweep(1500, 300, d)) * env(d, 0.01, 3) * 0.6)


def ptoo():
    """Munch spitting the foe out: a puffed-cheek 'ptoo!'"""
    p = bandnoise(0.02, 800, 6000) * env(0.02, 0.0004, 6)
    too = lowpass(osc(sweep(700, 400, 0.15), "square"), 1500) * env(0.15, 0.004, 4) * 0.5
    air = lowpass(bandnoise(0.2, 400, 4000), 3000) * env(0.2, 0.005, 4) * 0.5
    return mix(p, delay(too, 0.01), delay(air, 0.01))


def burp():
    """A belly burp: a growly low 'brap'."""
    d = 0.35
    f = sweep(170, 130, d, 0.6)
    pulses = 0.6 + 0.4 * np.sign(np.sin(2 * np.pi * 34 * t_axis(d)))
    return lowpass(osc(f, "saw") * pulses, 1400) * env(d, 0.02, 2.5)


def wreck_clang():
    """Wrecker's ball: a heavy iron clang with a rattling chain."""
    clang = bell(410, 0.5, 4, ((1, 1.0), (2.3, 0.6), (3.7, 0.4), (5.2, 0.2)))
    chain = mix(*[delay(bandnoise(0.02, 2500, 8000) * env(0.02, 0.0004, 5) * 0.4, 0.06 + 0.03 * i) for i in range(4)])
    return mix(bandnoise(0.03, 500, 5000) * env(0.03, 0.0004, 5), clang, chain)


def totem_knock():
    """Totem stacking a carved face: two hollow wooden log drums."""
    def log(f):
        return mix(tone(f, 0.15, "tri") * env(0.15, 0.001, 7), bandnoise(0.01, 1500, 5000) * env(0.01, 0.0004, 6) * 0.4)
    return seq([(0, log(520)), (0.08, log(780) * 0.8)])


def yoyo_whirr():
    """Yo-Yo spinning on its string: a rising whirring hum."""
    d = 0.45
    f = sweep(300, 600, d, 0.6)
    whirr = lowpass(osc(f, "saw") * (0.6 + 0.4 * tone(f * 0.12 + 20, d)), 2200) * env(d, 0.05, 2, hold=0.1)
    return whirr * 0.7


def snow_burst():
    """Blizz's snowflake mine: a soft icy 'pomf' and tinkling flakes."""
    d = 0.45
    pomf = lowpass(bandnoise(d, 200, 5000), sweep(5000, 600, d)) * env(d, 0.002, 4)
    flakes = mix(*[delay(bell(f, 0.2, 7) * 0.15, 0.03 * i) for i, f in enumerate([3520, 4186, 3136, 4699])])
    return mix(pomf, osc(sweep(220, 90, 0.2), "sine") * env(0.2, 0.002, 5) * 0.5, flakes)


def snowflake():
    """Blizz dropping a snowflake: a tiny crystalline chime."""
    return mix(bell(3136, 0.25, 6) * 0.6, delay(bell(4186, 0.2, 7) * 0.4, 0.05))


def foghorn():
    """Beacon's lighthouse beam: a short low foghorn with a glint."""
    d = 0.6
    f = np.full(int(d * SR), 220.0) * vib(d, 5, 0.008)
    horn = lowpass(osc(f, "saw") + osc(f * 1.5, "saw") * 0.5, sweep(500, 1600, d, 0.3)) * env(d, 0.06, 2, hold=0.2)
    return mix(horn * 0.6, delay(bell(2640, 0.3, 6) * 0.25, 0.05))


def hiss():
    """Pounce marking its prey: a cat's sharp hiss."""
    d = 0.3
    return bandnoise(d, 2500, 9000) * env(d, 0.01, 3, hold=0.05)


def swipe():
    """Pounce leaping in: a quick claw swish."""
    d = 0.15
    return mix(lowpass(bandnoise(d, 1500, 9000), sweep(2000, 9000, d)) * env(d, 0.06, 3),
               delay(bandnoise(0.03, 2000, 8000) * env(0.03, 0.0005, 6) * 0.6, 0.1))


def warp_8bit():
    """Pixel teleporting: a chiptune arpeggio blip."""
    notes = [72, 79, 84, 91]
    return seq([(i * 0.03, tone(midi(n), 0.035, "square") * env(0.035, 0.001, 1.5) * 0.4) for i, n in enumerate(notes)])


def boom_8bit():
    """Pixel's bomb: a crunchy 8-bit noise explosion."""
    d = 0.45
    n = int(d * SR)
    step = 12
    crunchy = np.repeat(rng.uniform(-1, 1, n // step + 1), step)[:n]
    return lowpass(crunchy, sweep(5000, 500, d)) * env(d, 0.001, 3) + tone(sweep(160, 50, d), d, "square") * env(d, 0.001, 4) * 0.3


def kaleido_click():
    """Kaleido turning to its next mode: a glassy click and a prism chime."""
    click = bandnoise(0.01, 2500, 9000) * env(0.01, 0.0003, 6)
    chime = mix(*[delay(bell(midi(n), 0.25, 6) * 0.3, 0.02 + 0.03 * i) for i, n in enumerate([88, 92, 95])])
    return mix(click, chime)


def puppet_string():
    """Puppeteer tying its string on: a taut plucked string."""
    return mix(pluck(392, 0.35, 5000), pluck(784, 0.25, 6000) * 0.3)


def tada():
    """Puppeteer's bow: a tiny 'ta-da!' flourish."""
    return seq([(0, tone(midi(79), 0.08, "tri") * env(0.08, 0.002, 4) * 0.5),
                (0.08, mix(*[tone(midi(n), 0.3, "tri") * env(0.3, 0.002, 3) * 0.3 for n in (84, 88, 91)]))])


def rocket():
    """A homing rocket launching: a hissing 'fssshoo'."""
    d = 0.35
    return mix(bandnoise(0.02, 800, 6000) * env(0.02, 0.0004, 6),
               lowpass(bandnoise(d, 1000, 9000), sweep(8000, 2500, d)) * env(d, 0.01, 2.5) * 0.7,
               osc(sweep(900, 1500, d), "saw") * env(d, 0.01, 4) * 0.08)


def lockon():
    """Megabot locking on: three quick rising beeps."""
    return seq([(i * 0.07, tone(1500 + 300 * i, 0.05, "square") * env(0.05, 0.001, 1.5) * 0.35) for i in range(3)])


def shield_up():
    """A shield going up: a rising glassy hum that rings."""
    d = 0.35
    return mix(osc(sweep(400, 1200, d, 0.5), "sine") * env(d, 0.05, 3) * 0.6,
               osc(sweep(800, 2400, d, 0.5), "tri") * env(d, 0.05, 4) * 0.2, delay(bell(2400, 0.2, 6) * 0.25, 0.15))


def shield_tink():
    """A hit landing on a shield: a soft energy 'tink'."""
    return mix(bell(1800, 0.15, 8, ((1, 1.0), (1.5, 0.4))), osc(sweep(1200, 600, 0.06), "saw") * env(0.06, 0.001, 6) * 0.1)


def scoop():
    """Sundae stacking a scoop: a soft creamy 'plop'."""
    d = 0.14
    return mix(osc(sweep(300, 700, d, 0.3), "sine") * env(d, 0.003, 5), lowpass(noise(0.05), 1500) * env(0.05, 0.002, 6) * 0.4)


def swell():
    """Supernova swelling: a short rising shimmer (pitched up per swell)."""
    d = 0.3
    f = sweep(500, 800, d, 0.6)
    return mix(osc(f, "sine") * env(d, 0.08, 3) * 0.5, osc(f * 1.5, "sine") * env(d, 0.08, 4) * 0.25,
               bandnoise(d, 4000, 9000) * env(d, 0.1, 4) * 0.12)


def slot_spin():
    """Jackpot's reels: a fast ticking spin and a 'ding!'"""
    ticks = mix(*[delay(bandnoise(0.01, 1800, 7000) * env(0.01, 0.0003, 6) * 0.5, 0.03 * i + 0.002 * i * i) for i in range(10)])
    ding = delay(mix(bell(1760, 0.35, 5), bell(2637, 0.3, 6) * 0.5), 0.46)
    return mix(ticks, ding)


def coins():
    """Jackpot's coin spray: a jingle of coins."""
    return mix(*[delay(bell(f, 0.15, 8, ((1, 1.0), (2.7, 0.4))) * 0.35, t) for f, t in [(2400, 0), (3100, 0.03), (2700, 0.06), (3500, 0.08), (2900, 0.12)]])


def tentacle_slap():
    """Kraken's tentacles slamming down: a big wet slap."""
    d = 0.3
    return mix(bandnoise(0.03, 400, 5000) * env(0.03, 0.0005, 5),
               lowpass(noise(d), sweep(3000, 500, d)) * env(d, 0.002, 4) * 0.8,
               osc(sweep(200, 80, 0.2), "sine") * env(0.2, 0.002, 5) * 0.6)


def squelch():
    """A slimy squelch (Kraken's hug)."""
    d = 0.3
    return lowpass(noise(d), sweep(400, 2000, d) * vib(d, 20, 0.3)) * env(d, 0.02, 3) * 1.2


def thunder():
    """Stormwing's chain lightning: a sharp crack that rolls into thunder."""
    d = 0.9
    crack = bandnoise(0.03, 1000, 11000) * env(0.03, 0.0003, 4) * 1.2
    roll = lowpass(bandnoise(d, 60, 2000), sweep(1800, 300, d)) * env(d, 0.01, 3) * (0.7 + 0.3 * np.sin(2 * np.pi * 9 * t_axis(d)))
    return mix(crack, delay(roll, 0.02), crackles(0.2, 0.85, 2500, 10000) * env(0.2, 0.001, 3) * 0.6)


def fox_whisper():
    """Foxfire splitting into illusions: a spectral rising chime with a breath."""
    chime = mix(*[delay(bell(midi(n), 0.4, 5) * 0.25, 0.05 * i) for i, n in enumerate([81, 85, 88, 93])])
    breath = lowpass(bandnoise(0.4, 1000, 6000), 3000) * env(0.4, 0.15, 3) * 0.3
    return mix(chime, breath)


def howl():
    """Frostfang hunting: a short wolf howl."""
    d = 0.6
    f = glide(420, 700, 520, d, 0.15, 0.7) * vib(d, 5.5, 0.015)
    voice = lowpass(osc(f, "saw") * 0.5 + osc(f, "sine"), 2200) * env(d, 0.06, 2, hold=0.15)
    return mix(voice * 0.7, bandnoise(d, 1500, 5000) * env(d, 0.05, 3) * 0.1)


def whale_call():
    """Narwhal charging: a whale-song whoop."""
    d = 0.4
    f = sweep(300, 900, d, 1.4) * vib(d, 7, 0.02)
    return osc(f, "sine") * env(d, 0.05, 2.5) * 0.8 + osc(f * 2, "sine") * env(d, 0.05, 4) * 0.15


def eclipse_flip():
    """Eclipse turning between sun and moon: a deep gong with a shimmer."""
    gong = bell(330, 0.8, 3, ((1, 1.0), (1.48, 0.5), (2.1, 0.3), (2.9, 0.2)))
    return mix(gong, delay(osc(sweep(1000, 2000, 0.4), "sine") * env(0.4, 0.1, 4) * 0.15, 0.05))


def ribbon():
    """Bonbon gift-wrapping a foe: a crinkly wrapper rustle."""
    d = 0.3
    return mix(crackles(d, 0.8, 3000, 11000) * env(d, 0.01, 2), lowpass(bandnoise(d, 2000, 8000), 6000) * env(d, 0.02, 3) * 0.2)


def confetti_pop():
    """The ribbon bursting: a party popper with confetti."""
    pop = mix(bandnoise(0.03, 500, 8000) * env(0.03, 0.0004, 5), osc(sweep(700, 200, 0.06), "sine") * env(0.06, 0.0005, 5) * 0.6)
    paper = delay(crackles(0.3, 0.9, 3000, 10000) * env(0.3, 0.01, 2.5) * 0.5, 0.03)
    return mix(pop, paper, delay(bell(midi(96), 0.2, 6) * 0.15, 0.05))


def prism_ray():
    """Spectra's rainbow beam: a fast sparkly arpeggio over a soft zap."""
    zip_ = osc(sweep(2400, 800, 0.15, 0.5), "sine") * env(0.15, 0.001, 5) * 0.3
    arp = seq([(0.02 * i, tone(midi(n), 0.06, "tri") * env(0.06, 0.001, 4) * 0.3) for i, n in enumerate([84, 88, 91, 95, 100])])
    return mix(zip_, arp)


def ripple_wash():
    """Ripple running along a wall: a quick watery swish."""
    d = 0.3
    return lowpass(bandnoise(d, 500, 6000), sweep(1500, 4500, d, 0.6) * vib(d, 14, 0.2)) * env(d, 0.05, 3) * 0.8


def spine():
    """Prickles shooting a spike: a tiny metallic 'tsing'."""
    return mix(osc(sweep(2600, 3400, 0.08), "sine") * env(0.08, 0.001, 6) * 0.6, bandnoise(0.01, 3000, 9000) * env(0.01, 0.0003, 6) * 0.3)


def shing():
    """Prickles growing a spike: a metallic 'shing' (pitched up per spike)."""
    d = 0.22
    return mix(osc(sweep(1800, 2600, d, 0.4), "sine") * env(d, 0.002, 4) * 0.5,
               bandnoise(d, 4000, 10000) * env(d, 0.002, 5) * 0.3)


def honey_squelch():
    """A foe stuck in honey: a thick, sticky squelch."""
    d = 0.3
    return lowpass(noise(d), sweep(300, 1200, d) * vib(d, 12, 0.3)) * env(d, 0.02, 3) * 1.2 + osc(sweep(180, 260, d), "sine") * env(d, 0.02, 4) * 0.4


def honey_drip():
    """A honey drip landing: a soft, sticky 'plip'."""
    return mix(osc(sweep(900, 400, 0.08, 0.5), "sine") * env(0.08, 0.002, 5), lowpass(noise(0.05), 1500) * env(0.05, 0.002, 5) * 0.3)


def dizzy():
    """A stunned foe: cartoon birdies tweeting round its head."""
    tw = [delay(osc(sweep(2400, 3000, 0.05) * vib(0.05, 60, 0.05), "sine") * env(0.05, 0.003, 3) * 0.4, 0.07 * i) for i in range(4)]
    return mix(*tw)


def dig():
    """Mole burrowing: a gritty dirt scrape."""
    d = 0.3
    return lowpass(crackles(d, 0.6, 400, 4000), 3000) * env(d, 0.03, 3) + lowpass(bandnoise(d, 200, 1500), 1000) * env(d, 0.03, 3) * 0.4


def ot_tick():
    """The overtime clock: a tense, dry tick."""
    return mix(bandnoise(0.012, 2000, 8000) * env(0.012, 0.0004, 6), tone(1200, 0.03, "square") * env(0.03, 0.001, 6) * 0.15)


def t5_shine():
    """Laid over a T5 critter's ability: a short golden shimmer."""
    return mix(*[delay(tone(midi(n), 0.14) * env(0.14, 0.002, 5) * 0.3, 0.025 * i) for i, n in enumerate([91, 96, 100])])


def ko_final():
    """The final KO stinger: a punchy impact and a falling whoosh."""
    d = 0.5
    impact = mix(bandnoise(0.04, 400, 9000) * env(0.04, 0.0004, 5), osc(sweep(400, 60, d, 0.35), "sine") * env(d, 0.001, 4))
    fall = lowpass(bandnoise(d, 300, 6000), sweep(6000, 400, d)) * env(d, 0.01, 3) * 0.5
    return mix(impact, fall)


BATTLE = {
    **{f"ouch_{fam}_{v}": (lambda f=fam, v=v: globals()[f"ouch_{f}"](v))
       for fam in ["nature", "sea", "tech", "sweet", "frost", "toybox", "spooky", "fire", "cosmic"] for v in range(2)},
    **{f"knock_{fam}": globals()[f"knock_{fam}"]
       for fam in ["nature", "sea", "tech", "sweet", "frost", "toybox", "spooky", "fire", "cosmic"]},
    **{n: globals()[n] for n in [
        "zoom", "kaboom", "mine_drop", "frost_crunch", "frost_breath", "thorn_snap", "moon_bonk", "warble",
        "void_suck", "nova_boom", "coal_hiss", "squirt", "lava_blorp", "ghost_wooo", "spook_hit", "chrome_ching",
        "pinball_ding", "flipper", "crunch", "bubble_blow", "bubble_pop", "gum_stretch", "gum_snap", "inflate",
        "spines", "shell_clack", "dart", "spore", "snuff", "fwoomp", "spring_boing", "ratchet", "sour",
        "pucker_pop", "seed_puff", "candy_clack", "reel", "disco_laser", "stoke", "trumpet", "ice_lock", "nom",
        "gulp", "ptoo", "burp", "wreck_clang", "totem_knock", "yoyo_whirr", "snow_burst", "snowflake", "foghorn",
        "hiss", "swipe", "warp_8bit", "boom_8bit", "kaleido_click", "puppet_string", "tada", "rocket", "lockon",
        "shield_up", "shield_tink", "scoop", "swell", "slot_spin", "coins", "tentacle_slap", "squelch", "thunder",
        "fox_whisper", "howl", "whale_call", "eclipse_flip", "ribbon", "confetti_pop", "prism_ray", "ripple_wash",
        "spine", "shing", "honey_squelch", "honey_drip", "dizzy", "dig", "ot_tick", "t5_shine", "ko_final"]},
}
SOUNDS.update(BATTLE)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--only", default="")
    args = ap.parse_args()
    os.makedirs(OUT, exist_ok=True)
    for name, make in SOUNDS.items():
        if name.startswith(args.only):
            global rng, SR
            rng = np.random.default_rng(zlib.crc32(name.encode()))
            SR = BATTLE_RATE if name in BATTLE else 32000
            print(write_wav(name, make()))


if __name__ == "__main__":
    main()
