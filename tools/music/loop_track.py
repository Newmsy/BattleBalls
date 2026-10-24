#!/usr/bin/env python3
"""Turns a finished song into a seamless game loop: finds the two section
starts (one near the beginning, one near the end) that sound most alike, cuts
between them and folds the audio just before the first onto the loop's end,
so playback flows from the end straight back to the start.

Used for music_menu.ogg: "Nocturnal Menu", made by Newms on FreeMusic AI
(https://www.freemusic.ai/song/8gDPk9kFvR).

Usage: python3 tools/music/loop_track.py SONG.mp3 OUT.ogg [--from 8-45] [--to 140-192]
Needs numpy and ffmpeg (libvorbis).
"""
import argparse
import subprocess

import numpy as np

SR = 24000  # Same as the rest of the music: plenty for a phone speaker.
RMS = 0.14  # The loudness every music track renders to (see make_music.py).
FADE = 1.0  # Seconds of crossfade folded onto the loop's end.


def load(path):
    raw = subprocess.run(["ffmpeg", "-v", "error", "-i", path, "-ac", "2", "-ar", str(SR), "-f", "s16le", "-"],
                         capture_output=True, check=True).stdout
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


def find_loop(x, start_range, end_range, window=6.0):
    """(start, end, match) in seconds: the pair whose next `window` seconds match best."""
    b, fps = bands(x.mean(0))
    w = int(window * fps)

    def feat(i):
        v = b[i:i + w].ravel()
        return v / np.linalg.norm(v)
    best = (-2.0, 0, 0)
    for a in range(int(start_range[0] * fps), int(start_range[1] * fps), 2):
        fa = feat(a)
        for e in range(int(end_range[0] * fps), int(end_range[1] * fps), 2):
            s = float(fa @ feat(e))
            if s > best[0]:
                best = (s, a, e)
    a, e = best[1] / fps, best[2] / fps
    # Nudge the end by up to 40 ms so the waveforms line up at the seam.
    mono = x.mean(0)
    ref = mono[int(a * SR):int(a * SR) + 2400]
    lo = int(e * SR) - 960
    xc = np.correlate(mono[lo:lo + 2400 + 1920], ref, "valid")
    e = (lo + int(np.argmax(xc))) / SR
    return a, e, best[0]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("song")
    ap.add_argument("out")
    ap.add_argument("--from", dest="start", default="8-45")
    ap.add_argument("--to", dest="end", default="140-192")
    args = ap.parse_args()
    x = load(args.song)
    a, e, score = find_loop(x, [float(v) for v in args.start.split("-")], [float(v) for v in args.end.split("-")])
    sa, se, f = int(a * SR), int(e * SR), int(FADE * SR)
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
