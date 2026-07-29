"""
Synthesize a loopable music-box arrangement of great-grandma's lullaby
(family_song_loop.wav melody: F#-centered, soft high chimes + gentle bass).

Writes: assets/audio/grandma_theme_loop.wav
"""
from __future__ import annotations

import math
import struct
import wave
from pathlib import Path

RATE = 22050
OUT = Path(__file__).resolve().parents[1] / "assets" / "audio" / "grandma_theme_loop.wav"

# MIDI helpers
def midi_hz(m: float) -> float:
    return 440.0 * (2.0 ** ((m - 69) / 12.0))


# Melody transcribed / cleaned from family_song_loop pitch analysis.
# Each entry: (midi_or_None_for_rest, beats)
# Tempo ~ 72 BPM → beat = 60/72 sec
BPM = 72.0
BEAT = 60.0 / BPM

# Phrase mirroring the source: lingering F#5, D5 answer, rising C5–D5–F5–F#5, soft G#5 close.
MELODY: list[tuple[float | None, float]] = [
    # Phrase 1
    (78, 2.0),   # F#5
    (78, 1.5),   # F#5
    (80, 0.5),   # G#5 ornament
    (78, 2.0),   # F#5
    (74, 1.0),   # D5
    (None, 0.5),
    # Phrase 2
    (78, 2.0),
    (78, 1.0),
    (77, 0.5),   # F5
    (78, 1.5),
    (None, 0.5),
    # Phrase 3 — rise
    (72, 0.5),   # C5
    (74, 0.5),   # D5
    (77, 0.5),   # F5
    (78, 2.5),   # F#5 peak
    (80, 2.0),   # G#5 settle
    (None, 1.0),
    # Soft echo of phrase 1 for seamless loop
    (78, 2.0),
    (74, 1.0),
    (78, 1.5),
    (None, 0.5),
]

# Soft bass pedal tones under phrases (B / D / A from source)
BASS: list[tuple[float | None, float]] = [
    (47, 4.0),   # B2
    (50, 3.5),   # D3
    (None, 0.5),
    (47, 3.5),
    (None, 0.5),
    (45, 4.0),   # A2
    (47, 4.0),
    (50, 3.5),
    (None, 0.5),
]


def env_adsr(i: int, n: int, a=0.02, d=0.08, s=0.55, r=0.25) -> float:
    """Simple ADSR; a/d/r are fractions of note length."""
    if n <= 1:
        return 0.0
    t = i / n
    if t < a:
        return t / a
    if t < a + d:
        return 1.0 - (1.0 - s) * ((t - a) / d)
    if t > 1.0 - r:
        return s * max(0.0, (1.0 - t) / r)
    return s


def render_note(
    buf: list[float],
    start: int,
    dur_sec: float,
    midi: float | None,
    *,
    amp: float,
    music_box: bool,
) -> None:
    if midi is None:
        return
    n = int(dur_sec * RATE)
    freq = midi_hz(midi)
    for i in range(n):
        t = i / RATE
        e = env_adsr(i, n)
        if music_box:
            # Soft chime: fundamental + weak 2nd/3rd + tiny inharmonic sparkle
            sig = (
                1.00 * math.sin(2 * math.pi * freq * t)
                + 0.35 * math.sin(2 * math.pi * freq * 2 * t)
                + 0.12 * math.sin(2 * math.pi * freq * 3.01 * t)
                + 0.05 * math.sin(2 * math.pi * freq * 4.97 * t)
            )
            # Gentle tremolo
            sig *= 1.0 + 0.04 * math.sin(2 * math.pi * 5.5 * t)
        else:
            # Warm sine bass
            sig = math.sin(2 * math.pi * freq * t) + 0.2 * math.sin(
                2 * math.pi * freq * 2 * t
            )
        idx = start + i
        if idx >= len(buf):
            break
        buf[idx] += amp * e * sig


def expand(events: list[tuple[float | None, float]]) -> list[tuple[float | None, float, float]]:
    """Return (midi, start_sec, dur_sec)."""
    t = 0.0
    out = []
    for midi, beats in events:
        dur = beats * BEAT
        out.append((midi, t, dur))
        t += dur
    return out


def main() -> None:
    mel = expand(MELODY)
    bass = expand(BASS)
    total_sec = max(m[1] + m[2] for m in mel + bass) + 0.15
    # Snap length so loop edges are quiet
    n = int(total_sec * RATE)
    buf = [0.0] * n

    for midi, start_s, dur in bass:
        render_note(buf, int(start_s * RATE), dur, midi, amp=0.18, music_box=False)

    for midi, start_s, dur in mel:
        render_note(buf, int(start_s * RATE), dur, midi, amp=0.42, music_box=True)

    # Soft fade in/out for seamless looping
    fade = int(0.12 * RATE)
    for i in range(fade):
        g = i / fade
        buf[i] *= g
        buf[-1 - i] *= g

    peak = max(abs(x) for x in buf) or 1.0
    scale = 0.72 / peak
    pcm = [max(-32767, min(32767, int(x * scale * 32767))) for x in buf]

    OUT.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(OUT), "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(struct.pack("<" + "h" * len(pcm), *pcm))

    print(f"wrote {OUT} ({len(pcm)/RATE:.2f}s, {len(pcm)} frames)")


if __name__ == "__main__":
    main()
