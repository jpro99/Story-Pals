"""Extract approximate melody from family_song_loop.wav via autocorrelation."""
import wave
import struct
import math
import collections

path = r"c:\Projects\Story Pals\assets\audio\family_song_loop.wav"
w = wave.open(path)
rate = w.getframerate()
n = w.getnframes()
raw = w.readframes(n)
w.close()
samples = list(struct.unpack("<" + "h" * n, raw))
mx = max(abs(s) for s in samples) or 1
samples = [s / mx for s in samples]

win = int(rate * 0.25)
hop = int(rate * 0.125)
min_lag = int(rate / 800)
max_lag = int(rate / 100)

notes = []
for start in range(0, n - win, hop):
    chunk = samples[start : start + win]
    energy = math.sqrt(sum(x * x for x in chunk) / len(chunk))
    if energy < 0.02:
        notes.append((start / rate, None, energy))
        continue
    mean = sum(chunk) / len(chunk)
    c = [x - mean for x in chunk]
    best_lag, best_corr = min_lag, -1.0
    for lag in range(min_lag, max_lag):
        corr = 0.0
        for i in range(0, len(c) - lag, 2):  # stride for speed
            corr += c[i] * c[i + lag]
        if corr > best_corr:
            best_corr = corr
            best_lag = lag
    freq = rate / best_lag
    notes.append((start / rate, freq, energy))


def hz_to_midi(hz: float) -> float:
    return 69 + 12 * math.log2(hz / 440.0)


def midi_name(m: float) -> tuple[str, int]:
    names = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
    mi = int(round(m))
    return names[mi % 12] + str(mi // 12 - 1), mi


print("duration", n / rate)
for t, f, e in notes:
    if f is None:
        print(f"{t:5.2f}s  rest  e={e:.3f}")
    else:
        name, midi = midi_name(hz_to_midi(f))
        print(f"{t:5.2f}s  {f:6.1f}Hz  {name:4} midi={midi} e={e:.3f}")

counts: collections.Counter[str] = collections.Counter()
for t, f, e in notes:
    if f and e > 0.03:
        name, _ = midi_name(hz_to_midi(f))
        counts[name] += 1
print("common", counts.most_common(16))
