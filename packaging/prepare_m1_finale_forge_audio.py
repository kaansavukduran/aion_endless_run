"""Render the Root Engine's original mono encounter cues."""

import math
from pathlib import Path
import random
import struct
import wave


OUTPUT = Path(__file__).resolve().parents[1] / "assets" / "audio"
RATE = 22_050
TAU = math.tau


def chirp(t, pitch, slide=0.0):
    return math.sin(TAU * t * (pitch + slide * t / 2))


def write_cue(name, duration, sound):
    rng = random.Random(1587)
    count = round(RATE * duration)
    samples = bytearray(count * 2)
    for i in range(count):
        t = i / RATE
        taper = min(1, t / 0.005, (duration - t) / 0.028)
        struct.pack_into("<h", samples, i * 2, round(32767 * taper * sound(t, rng)))
    with wave.open(str(OUTPUT / f"m1-finale-forge-{name}.wav"), "wb") as target:
        target.setparams((1, 2, RATE, count, "NONE", "not compressed"))
        target.writeframes(samples)


def ground_wave(t, rng):
    dirt = rng.uniform(-1, 1) * math.exp(-22 * t)
    return 0.42 * chirp(t, 99, -136) * math.exp(-6 * t) + 0.14 * dirt


def wave_echo(t, rng):
    low = 0.31 * chirp(t, 137, -195) * math.exp(-10 * t)
    high = 0.16 * chirp(t, 560, 510) * math.exp(-17 * t)
    second = max(0, t - 0.075)
    reply = 0.18 * chirp(second, 780, -1450) * math.exp(-19 * second)
    return low + high + reply + 0.07 * rng.uniform(-1, 1) * math.exp(-25 * t)


def eruption(t, rng):
    dirt = rng.uniform(-1, 1) * (0.16 + 0.1 * chirp(t, 58)) * math.exp(-12 * t)
    crack = 0.19 * chirp(t, 1700, -2300) * math.exp(-37 * t)
    roots = 0.38 * chirp(t, 117, -310) * math.exp(-7 * t)
    return dirt + crack + roots


def core_release(t, _rng):
    latch = 0.18 * chirp(t, 380, -190) * math.exp(-25 * t)
    spark = 0.23 * chirp(t, 1090, 640) * math.exp(-11 * t)
    glass = 0.1 * chirp(t, 1635, 540) * math.exp(-9 * t)
    return latch + spark + glass


def lantern(t, _rng):
    second = max(0, t - 0.044)
    lower = 0.23 * chirp(t, 679) * math.exp(-10 * t)
    higher = 0.18 * chirp(second, 1019) * math.exp(-11 * second)
    return lower + higher + 0.065 * chirp(second, 1528) * math.exp(-22 * second)


if __name__ == "__main__":
    for cue in [
        ("wave", 0.42, ground_wave),
        ("echo", 0.33, wave_echo),
        ("eruption", 0.40, eruption),
        ("core", 0.28, core_release),
        ("lantern", 0.34, lantern),
    ]:
        write_cue(*cue)
