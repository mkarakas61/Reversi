#!/usr/bin/env python3
"""Synthesises the game's sound effects and background music as WAV files.

Pure standard library (no numpy/ffmpeg). The aesthetic is soft / minimal /
modern: sine-based tones with gentle envelopes, modest amplitudes. Output goes
to assets/audio/. Re-run to regenerate; tweak the parameters to taste.
"""

import math
import os
import struct
import wave

OUT_DIR = os.path.join(os.path.dirname(__file__), "..", "assets", "audio")
SFX_RATE = 44100
BGM_RATE = 22050


def write_wav(name, samples, rate):
    os.makedirs(OUT_DIR, exist_ok=True)
    path = os.path.join(OUT_DIR, name)
    # Soft-clip and convert to 16-bit PCM.
    frames = bytearray()
    for s in samples:
        if s > 1.0:
            s = 1.0
        elif s < -1.0:
            s = -1.0
        frames += struct.pack("<h", int(s * 32767))
    with wave.open(path, "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(rate)
        w.writeframes(bytes(frames))
    print(f"  {name}: {len(samples)/rate:.2f}s, {len(frames)//1024} KB")


def env_ad(n, i, attack, decay):
    """Attack-decay envelope in [0,1]; attack/decay are fractions of n."""
    a = max(1, int(n * attack))
    d = max(1, int(n * decay))
    if i < a:
        return i / a
    if i > n - d:
        return max(0.0, (n - i) / d)
    return 1.0


def tone(freq, dur, rate, amp=0.5, attack=0.01, decay=0.3, harmonics=(1.0,),
         glide_to=None, vibrato=0.0):
    n = int(dur * rate)
    out = []
    for i in range(n):
        t = i / rate
        f = freq if glide_to is None else freq + (glide_to - freq) * (i / n)
        if vibrato:
            f *= 1.0 + vibrato * math.sin(2 * math.pi * 5.5 * t)
        v = 0.0
        for k, hamp in enumerate(harmonics, start=1):
            v += hamp * math.sin(2 * math.pi * f * k * t)
        # Exponential-ish decay shaped by env.
        e = env_ad(n, i, attack, decay) * math.exp(-3.0 * (i / n) * decay)
        out.append(amp * e * v)
    return out


def silence(dur, rate):
    return [0.0] * int(dur * rate)


def mix(*tracks):
    n = max(len(t) for t in tracks)
    out = [0.0] * n
    for t in tracks:
        for i, s in enumerate(t):
            out[i] += s
    return out


def concat(*parts):
    out = []
    for p in parts:
        out.extend(p)
    return out


def note(name):
    """Equal-tempered frequency for names like 'A4', 'C#5'."""
    semis = {"C": 0, "C#": 1, "D": 2, "D#": 3, "E": 4, "F": 5,
             "F#": 6, "G": 7, "G#": 8, "A": 9, "A#": 10, "B": 11}
    pitch = name[:-1]
    octave = int(name[-1])
    n = semis[pitch] + (octave + 1) * 12
    return 440.0 * (2 ** ((n - 69) / 12))


# ─────────────────────────── SOUND EFFECTS ───────────────────────────

def sfx_place():
    body = tone(180, 0.13, SFX_RATE, amp=0.55, attack=0.005, decay=0.9,
                harmonics=(1.0, 0.3))
    click = tone(1200, 0.03, SFX_RATE, amp=0.25, attack=0.002, decay=1.0)
    return mix(body, click)


def sfx_flip():
    return tone(360, 0.16, SFX_RATE, amp=0.4, attack=0.01, decay=0.8,
                harmonics=(1.0, 0.4), glide_to=700)


def sfx_invalid():
    t = tone(150, 0.1, SFX_RATE, amp=0.35, attack=0.01, decay=0.7,
             harmonics=(1.0, 0.5, 0.25))
    return concat(t, silence(0.04, SFX_RATE), t)


def sfx_button():
    return tone(520, 0.07, SFX_RATE, amp=0.35, attack=0.005, decay=1.0,
                harmonics=(1.0, 0.2))


def sfx_tick():
    return tone(1500, 0.035, SFX_RATE, amp=0.3, attack=0.002, decay=1.0)


def sfx_timeup():
    return tone(440, 0.6, SFX_RATE, amp=0.45, attack=0.01, decay=0.6,
                harmonics=(1.0, 0.5, 0.3), glide_to=190, vibrato=0.015)


def sfx_win():
    notes = ["C5", "E5", "G5", "C6"]
    parts = []
    for nm in notes:
        parts.append(tone(note(nm), 0.14, SFX_RATE, amp=0.4, attack=0.01,
                          decay=0.6, harmonics=(1.0, 0.5, 0.2)))
    # let the final note ring
    parts[-1] = tone(note("C6"), 0.4, SFX_RATE, amp=0.42, attack=0.01,
                     decay=0.5, harmonics=(1.0, 0.5, 0.25))
    return concat(*parts)


def sfx_lose():
    notes = ["G4", "E4", "C4"]
    parts = [tone(note(nm), 0.26, SFX_RATE, amp=0.4, attack=0.02, decay=0.5,
                  harmonics=(1.0, 0.4)) for nm in notes]
    return concat(*parts)


def sfx_draw():
    a = tone(note("E5"), 0.2, SFX_RATE, amp=0.38, attack=0.01, decay=0.6,
             harmonics=(1.0, 0.3))
    b = tone(note("E5"), 0.24, SFX_RATE, amp=0.36, attack=0.01, decay=0.5,
             harmonics=(1.0, 0.3))
    return concat(a, b)


# ─────────────────────────── BACKGROUND MUSIC ───────────────────────────

def pad_note(freq, dur, rate, amp):
    """Soft sustained pad voice with slow attack/release."""
    n = int(dur * rate)
    out = []
    for i in range(n):
        t = i / rate
        # slow attack, slow release
        a = min(1.0, i / (0.25 * n))
        r = min(1.0, (n - i) / (0.25 * n))
        e = min(a, r)
        v = (math.sin(2 * math.pi * freq * t)
             + 0.3 * math.sin(2 * math.pi * freq * 2 * t)
             + 0.15 * math.sin(2 * math.pi * freq * 3 * t))
        out.append(amp * e * v)
    return out


def chord(freqs, dur, rate, amp):
    voices = [pad_note(f, dur, rate, amp) for f in freqs]
    return mix(*voices)


def pluck(freq, dur, rate, amp):
    """Short soft arpeggio voice."""
    return tone(freq, dur, rate, amp=amp, attack=0.01, decay=0.9,
                harmonics=(1.0, 0.35, 0.12))


def bgm_game():
    """Calm: slow Cmaj7 → Fmaj7 → Am7 → G pad, very soft."""
    rate = BGM_RATE
    seg = 5.0
    prog = [
        [note("C3"), note("E3"), note("G3"), note("B3")],
        [note("F3"), note("A3"), note("C4"), note("E4")],
        [note("A2"), note("C3"), note("E3"), note("G3")],
        [note("G2"), note("B2"), note("D3"), note("F3")],
    ]
    parts = [chord(c, seg, rate, amp=0.14) for c in prog]
    out = concat(*parts)
    return fade_edges(out, rate, 0.04)


def bgm_menu():
    """Energetic-but-soft: Am–F–C–G with an eighth-note arpeggio + soft pad."""
    rate = BGM_RATE
    bar = 2.0  # seconds per chord
    eighth = bar / 4
    prog = [
        ("Am", [note("A3"), note("C4"), note("E4")]),
        ("F",  [note("F3"), note("A3"), note("C4")]),
        ("C",  [note("C4"), note("E4"), note("G4")]),
        ("G",  [note("G3"), note("B3"), note("D4")]),
    ]
    out = []
    # Two passes through the progression → 16s loop.
    for _ in range(2):
        for _name, notes in prog:
            pad = chord(notes, bar, rate, amp=0.08)
            # arpeggio: up over four eighth notes, repeated
            arp_seq = [notes[0], notes[1], notes[2], notes[1]]
            arp = []
            for f in arp_seq:
                arp.extend(pluck(f * 2, eighth, rate, amp=0.16))
            bass = pad_note(notes[0] / 2, bar, rate, amp=0.10)
            out.extend(mix(pad, arp, bass))
    return fade_edges(out, rate, 0.03)


def fade_edges(samples, rate, secs):
    n = int(secs * rate)
    out = list(samples)
    for i in range(min(n, len(out))):
        g = i / n
        out[i] *= g
        out[-1 - i] *= g
    return out


def main():
    print("SFX:")
    write_wav("place.wav", sfx_place(), SFX_RATE)
    write_wav("flip.wav", sfx_flip(), SFX_RATE)
    write_wav("invalid.wav", sfx_invalid(), SFX_RATE)
    write_wav("button.wav", sfx_button(), SFX_RATE)
    write_wav("tick.wav", sfx_tick(), SFX_RATE)
    write_wav("timeup.wav", sfx_timeup(), SFX_RATE)
    write_wav("win.wav", sfx_win(), SFX_RATE)
    write_wav("lose.wav", sfx_lose(), SFX_RATE)
    write_wav("draw.wav", sfx_draw(), SFX_RATE)
    print("BGM:")
    write_wav("menu_music.wav", bgm_menu(), BGM_RATE)
    write_wav("game_music.wav", bgm_game(), BGM_RATE)


if __name__ == "__main__":
    main()
