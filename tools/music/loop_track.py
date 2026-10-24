#!/usr/bin/env python3
"""Turns a finished song into a seamless game loop: finds the two points (one
near the beginning, one later) that sound most alike, cuts between them and
folds the audio just before the first onto the loop's end, so playback flows
from the end straight back to the start.

With --bpm the cut points sit on the beat grid and the loop is a whole number
of bars long (--bars, several to choose from), and --stretch speeds the loop
up or down without changing its pitch.

Used for:
- music_menu.ogg: "Nocturnal Menu" (FreeMusic AI, https://www.freemusic.ai/song/8gDPk9kFvR)
    loop_track.py nocturnal-menu.mp3 music_menu.ogg
- music_fight.ogg / music_overtime.ogg: "Neon Pulse" (FreeMusic AI, 140 BPM,
  https://www.freemusic.ai/song/fWpO3tKXjn), slowed to 120 BPM for fights:
    loop_track.py neon-pulse.mp3 music_fight.ogg --bpm 140.04 --bars 16,24,32 --from 30-90 --to 50-185 --stretch 0.857
    loop_track.py neon-pulse.mp3 music_overtime.ogg --bpm 140.04 --bars 8,16 --from 100-170 --to 110-190

Usage: python3 tools/music/loop_track.py SONG.mp3 OUT.ogg [--from 8-45] [--to 140-192]
       [--bpm B --bars 8,16] [--stretch R]
Needs numpy and ffmpeg (libvorbis).
"""
import argparse
import subprocess

import numpy as np

SR = 24000  # Same as the rest of the music: plenty for a phone speaker.
RMS = 0.14  # The loudness every music track renders to (see make_music.py).
FADE = 1.0  # Seconds of crossfade folded onto the loop's end.


def load(path, stretch=1.0):
    args = ["ffmpeg", "-v", "error", "-i", path, "-ac", "2", "-ar", str(SR)]
    if stretch != 1.0:
        args += ["-af", "atempo=%.4f" % stretch]
    raw = subprocess.run(args + ["-f", "s16le", "-"], capture_output=True, check=True).stdout
    return (np.frombuffer(raw, "<i2").reshape(-1, 2).T / 32768.0).copy()


def bands(mono, hop=480, n=2048):
    """Log energy in 40 bands per frame, mean removed: a coarse timbre print."""
    frames = np.lib.stride_tricks.sliding_window_view(mono, n)[::hop] * np.hanning(n)
    spec = np.abs(np.fft.rfft(frames, axis=1))
    f = np.fft.rfftfreq(n, 1 / SR)
    edges = np.geomspace(60, 8000, 41)
    b = np.stack([spec[:, (f >= edges[i]) & (f < edges[i + 1])].sum(1) for i in range(40)], 1)
    b = np.log1p(b * 10)
    return b - b.mean(0), SR / hop


def beat_phase(mono, bpm):
    """Seconds to the first beat: where spectral-flux onsets line up best."""
    hop, n = 48, 1024
    frames = np.lib.stride_tricks.sliding_window_view(mono, n)[::hop] * np.hanning(n)
    s = np.log1p(np.abs(np.fft.rfft(frames, axis=1)))
    flux = np.maximum(np.diff(s, axis=0), 0).sum(1)
    fps, period = SR / hop, 60 / bpm
    best = (-1.0, 0.0)
    for ph in np.linspace(0, period, 64, endpoint=False):
        idx = np.round((ph + np.arange(0, len(flux) / fps - 1, period)) * fps).astype(int)
        best = max(best, (flux[idx[idx < len(flux)]].mean(), ph))
    return best[1]


def find_loop(x, start_range, end_range, bpm=0.0, bars=(), window=6.0):
    """(start, end, match) in seconds: the pair whose surroundings match best."""
    b, fps = bands(x.mean(0))
    w = int(window * fps)

    def feat(t):
        i = int(t * fps)
        v = b[max(i - w // 3, 0):i + w].ravel()  # A little before the cut too: that's what the fade blends.
        return v / np.linalg.norm(v)
    if bpm:
        beat = 60 / bpm
        ph = beat_phase(x.mean(0), bpm)
        starts = [t for t in np.arange(ph, start_range[1], beat) if t >= start_range[0]]
        pairs = [(a, a + n * 4 * beat) for a in starts for n in bars if end_range[0] <= a + n * 4 * beat <= end_range[1]]
    else:
        step = 2 / fps
        pairs = [(a, e) for a in np.arange(*start_range, step) for e in np.arange(*end_range, step)]
    best = max(((float(feat(a) @ feat(e)), a, e) for a, e in pairs), key=lambda p: p[0])
    score, a, e = best
    if not bpm:  # Off the grid: nudge the end by up to 40 ms so the waveforms line up.
        mono = x.mean(0)
        ref = mono[int(a * SR):int(a * SR) + 2400]
        lo = int(e * SR) - 960
        e = (lo + int(np.argmax(np.correlate(mono[lo:lo + 4320], ref, "valid")))) / SR
    return a, e, score


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("song")
    ap.add_argument("out")
    ap.add_argument("--from", dest="start", default="8-45")
    ap.add_argument("--to", dest="end", default="140-192")
    ap.add_argument("--bpm", type=float, default=0.0)
    ap.add_argument("--bars", default="8,16,32")
    ap.add_argument("--stretch", type=float, default=1.0)
    args = ap.parse_args()
    x = load(args.song)
    a, e, score = find_loop(x, [float(v) for v in args.start.split("-")], [float(v) for v in args.end.split("-")],
                            args.bpm, [int(v) for v in args.bars.split(",")])
    if args.stretch != 1.0:  # Cut the same musical span out of the stretched audio.
        x = load(args.song, args.stretch)
        a, e = a / args.stretch, e / args.stretch
    sa, se, f = int(round(a * SR)), int(round(e * SR)), int(FADE * SR)
    loop = x[:, sa:se].copy()
    w = np.sin(np.linspace(0, np.pi / 2, f)) ** 2
    loop[:, -f:] = loop[:, -f:] * (1 - w) + x[:, sa - f:sa] * w
    loop *= RMS / np.sqrt(np.mean(loop ** 2))
    # Soft limiter, as in make_music.py: transparent below ~0.6.
    loop = np.where(np.abs(loop) < 0.6, loop, np.sign(loop) * (0.6 + 0.35 * np.tanh((np.abs(loop) - 0.6) / 0.35)))
    pcm = (np.clip(loop.T, -1, 1) * 32767).astype("<i2").tobytes()
    subprocess.run(["ffmpeg", "-y", "-v", "error", "-f", "s16le", "-ar", str(SR), "-ac", "2", "-i", "-",
                    "-c:a", "libvorbis", "-q:a", "0", "-map_metadata", "-1", "-fflags", "+bitexact",
                    "-flags:a", "+bitexact", args.out], input=pcm, check=True)
    print("loop %.2f s -> %.2f s (%.1f s, match %.2f) -> %s" % (a, e, e - a, score, args.out))


if __name__ == "__main__":
    main()
