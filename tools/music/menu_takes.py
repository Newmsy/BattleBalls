#!/usr/bin/env python3
"""Two fresh takes on the main background track (Newms: no arpeggios, not
church-y, keep the pads). Renders demo WAVs; the chosen one moves into
make_music.py. Usage: python3 tools/music/menu_takes.py OUT_DIR"""
import functools
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(__file__))
from make_music import (SR, Song, bass, clap, crash, env, hat, kick, lp, midi, perc, pulse, saw,  # noqa: E402
                        shaker, sine, snare, supersaw, svf_lp, write_wav)


@functools.lru_cache(maxsize=None)
def epiano(notes, seconds):
    """FM electric piano: warm, round stabs instead of an arpeggio."""
    n = int(seconds * SR)
    t = np.arange(n) / SR
    out = np.zeros(n)
    for m in notes:
        f = midi(m)
        index = 1.4 * np.exp(-t / 0.18) + 0.2
        tine = np.sin(2 * np.pi * f * t + index * np.sin(2 * np.pi * f * t))
        bark = np.sin(2 * np.pi * f * 14 * t) * np.exp(-t / 0.01) * 0.08
        out += tine + bark
    trem = 1 + 0.12 * np.sin(2 * np.pi * 4.5 * t)
    return out / len(notes) ** 0.6 * env(n, 0.003, 0.5, 0.25, 0.08) * trem * 0.45


@functools.lru_cache(maxsize=None)
def talk(note, seconds, from_note=None):
    """A vocal-ish lead: saw through a bright filter, scooping up into the note."""
    n = int(seconds * SR)
    t = np.arange(n) / SR
    start = midi(from_note if from_note is not None else note - 1)
    f = midi(note) + (start - midi(note)) * np.exp(-t / 0.035)
    f = f * (1 + 0.005 * np.sin(2 * np.pi * 5.2 * t) * np.clip((t - 0.2) / 0.2, 0, 1))
    x = saw(f, n) * 0.6 + pulse(f * 0.5, n, 0.5) * 0.25
    cut = 1400 + 1800 * np.exp(-t / 0.15)
    return svf_lp(x, cut, 2.2) * env(n, 0.006, 0.4, 0.7, min(0.06, seconds * 0.3)) * 0.45


@functools.lru_cache(maxsize=None)
def funk_bass(note, seconds):
    n = int(seconds * SR)
    t = np.arange(n) / SR
    f = midi(note)
    x = saw(f, n) * 0.5 + pulse(f, n, 0.3) * 0.5
    y = svf_lp(x, 300 + 2200 * np.exp(-t / 0.05), 1.6) + sine(f, n) * 0.25
    return np.tanh(y * 2.2) * env(n, 0.002, 0.12, 0.45, 0.02) * 0.5


def melody(s, bar, notes, inst, bus, gain):
    prev = None
    for beat, length, note in notes:
        s.add(bus, inst(note, s.sec(length), prev if prev is not None else note - 2), bar * 4 + beat, 0, gain)
        prev = note


def groove():
    """Take A, "Neon Groove": 108 BPM city-pop funk in F. Bbmaj7 Am7 Gm7 C7sus."""
    s = Song(108, 16, tail=2.5)
    chords = {  # pad voicing, e-piano voicing, bass root
        "Bbmaj7": ([58, 62, 65, 69], (62, 65, 69, 72), 34),
        "Am7": ([57, 60, 64, 67], (60, 64, 67, 72), 33),
        "Gm7": ([55, 58, 62, 65], (58, 62, 65, 70), 31),
        "C7sus": ([55, 60, 65, 70], (60, 65, 67, 70), 36),
        "Dm7": ([57, 60, 62, 65], (60, 62, 65, 69), 38),
    }
    prog = ["Bbmaj7", "Am7", "Gm7", "C7sus"] * 2 + ["Bbmaj7", "Am7", "Dm7", "Gm7", "Bbmaj7", "Am7", "Gm7", "C7sus"]
    # Syncopated bass: (beat, length, interval above the root).
    bass_line = [(0, 0.4, 0), (0.75, 0.2, 12), (1.5, 0.4, 0), (2.25, 0.2, 12), (2.5, 0.4, 10), (3.25, 0.4, 7), (3.75, 0.2, 12)]
    comp = [0.5, 1.75, 2.5, 3.75]  # E-piano stabs, off the beat.
    for bar, name in enumerate(prog):
        pad, keys, root = chords[name]
        s.add("pad", supersaw(pad, s.sec(4) + 0.5, 1700, 0.25, 0.5), bar * 4, gain=0.75)
        for b, l, iv in bass_line:
            s.add("bass", funk_bass(root + 12 + iv, s.sec(l)), bar * 4 + b, 0, 0.8)
        if bar >= 2:
            for b in comp:
                s.add("keys", epiano(keys, s.sec(0.6)), bar * 4 + b, 0.2, 0.8)
        for b in range(4):
            s.kick(bar * 4 + b, 0.85 if b % 2 == 0 else 0.6)
        for b in (1, 3):
            s.add("drums", clap(), bar * 4 + b, 0, 0.8)
            s.add("drums", snare(230, 0.15), bar * 4 + b, 0, 0.35)
        for i in range(16):
            swing = 0.04 if i % 2 else 0.0  # A little swing on the 16ths.
            s.add("hats", hat(i % 4 == 2, i % 3), bar * 4 + i * 0.25 + swing, 0.3, 0.45 if i % 4 == 2 else (0.3 if i % 2 == 0 else 0.18))
    tune = {  # Bar -> phrase. Hook: a sunny call and answer.
        4: [(0, .5, 77), (.5, .5, 76), (1, 1, 74), (2.5, .5, 72), (3, 1, 74)],
        5: [(0, .75, 76), (.75, .75, 72), (1.5, 2, 69)],
        6: [(0, .5, 70), (.5, .5, 72), (1, .5, 74), (1.5, 1, 77), (2.5, .5, 74), (3, 1, 72)],
        7: [(0, 3, 72), (3.5, .5, 69)],
        8: [(0, .5, 77), (.5, .5, 76), (1, 1, 74), (2.5, .5, 72), (3, 1, 81)],
        9: [(0, .75, 79), (.75, .75, 76), (1.5, 2, 72)],
        10: [(0, .5, 74), (.5, .5, 76), (1, .5, 77), (1.5, 1, 81), (2.5, .5, 79), (3, 1, 77)],
        11: [(0, 2, 74), (2, 1, 72), (3, 1, 70)],
        12: [(0, .5, 77), (.5, .5, 76), (1, 1, 74), (2.5, .5, 72), (3, 1, 74)],
        13: [(0, .75, 76), (.75, .75, 72), (1.5, 2, 69)],
        14: [(0, .5, 70), (.5, .5, 74), (1, 1, 77), (2, 1, 76), (3, 1, 74)],
        15: [(0, 2, 72), (2.5, .5, 74), (3, .5, 76), (3.5, .5, 77)],
    }
    for bar, notes in tune.items():
        melody(s, bar, notes, talk, "lead", 1.2)
    s.add("fx", crash(2.0), 16, 0.2, 0.35)
    s.add("fx", crash(2.0), 32, -0.2, 0.35)
    sends = {"pad": (0.25, 0.0), "keys": (0.2, 0.15), "lead": (0.22, 0.3), "drums": (0.08, 0.0), "fx": (0.25, 0.0)}
    return s.render(sends, ducked=("pad", "bass", "keys"), duck=0.4, delay_beats=0.75)


def night_drive():
    """Take B, "Night Drive": 92 BPM half-time, E dorian. Em9 A13 Cmaj7 Bm7."""
    s = Song(92, 16, tail=3.0)
    chords = {
        "Em9": ([55, 59, 62, 66], 40), "A": ([55, 61, 64, 66], 45),
        "Cmaj7": ([55, 59, 64, 67], 36), "Bm7": ([54, 57, 62, 66], 47),
        "Gmaj7": ([54, 59, 62, 67], 43), "D": ([54, 57, 62, 66], 38),
    }
    prog = ["Em9", "A", "Cmaj7", "Bm7"] * 2 + ["Cmaj7", "D", "Bm7", "Em9", "Cmaj7", "D", "Gmaj7", "Bm7"]
    for bar, name in enumerate(prog):
        pad, root = chords[name]
        s.add("pad", supersaw(pad, s.sec(4) + 0.8, 1500, 0.6, 0.8), bar * 4, gain=0.9)
        # Long bass notes with a pickup into the next bar.
        s.add("bass", bass(root, s.sec(2.5), 1.5, 0.5), bar * 4, 0, 0.7)
        s.add("bass", bass(root + 7, s.sec(0.4), 1.5, 0.7), bar * 4 + 3, 0, 0.55)
        s.add("bass", bass(root + 12, s.sec(0.4), 1.5, 0.7), bar * 4 + 3.5, 0, 0.55)
        s.kick(bar * 4, 0.9)
        s.kick(bar * 4 + 2.5, 0.6)
        if bar >= 2:
            s.add("drums", snare(200, 0.25), bar * 4 + 2, 0, 0.7)
            s.add("drums", clap(), bar * 4 + 2, 0, 0.5)
        for i in range(8):
            s.add("hats", hat(False, i % 3), bar * 4 + i * 0.5 + (0.06 if i % 2 else 0), 0.3, 0.3 if i % 2 else 0.18)
        for i in range(16):
            s.add("hats", shaker(i % 4), bar * 4 + i * 0.25, -0.3, 0.25 if i % 2 else 0.12)
    tune = {
        4: [(0, 1.5, 71), (1.5, .5, 74), (2, 2, 76)],
        5: [(0, .5, 78), (.5, 1, 76), (1.5, .5, 74), (2, 2, 73)],
        6: [(0, 1.5, 71), (1.5, .5, 72), (2, 1, 74), (3, 1, 76)],
        7: [(0, 3.5, 74)],
        8: [(0, 1, 79), (1, .5, 78), (1.5, .5, 76), (2, 2, 74)],
        9: [(0, 1, 78), (1, .5, 76), (1.5, .5, 74), (2, 2, 73)],
        10: [(0, 1, 74), (1, .5, 76), (1.5, .5, 78), (2, 1.5, 81), (3.5, .5, 79)],
        11: [(0, 3.5, 78)],
        12: [(0, 1, 79), (1, .5, 78), (1.5, .5, 76), (2, 2, 74)],
        13: [(0, 1, 78), (1, .5, 76), (1.5, .5, 74), (2, 2, 73)],
        14: [(0, 1, 74), (1, 1, 76), (2, 2, 78)],
        15: [(0, 3, 76), (3, 1, 71)],
    }
    for bar, notes in tune.items():
        melody(s, bar, notes, talk, "lead", 1.1)
    s.add("fx", crash(2.4), 16, 0.2, 0.35)
    s.add("fx", crash(2.4), 32, -0.2, 0.4)
    sends = {"pad": (0.3, 0.0), "lead": (0.3, 0.35), "drums": (0.15, 0.0), "fx": (0.3, 0.0)}
    return s.render(sends, ducked=("pad", "bass"), duck=0.35, delay_beats=1.5)


if __name__ == "__main__":
    out = sys.argv[1]
    for name, make in (("take-a-neon-groove", groove), ("take-b-night-drive", night_drive)):
        x = make()
        write_wav(os.path.join(out, name + ".wav"), x)
        print(name, "%.1fs" % (x.shape[1] / SR))
