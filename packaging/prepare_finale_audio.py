"""Render the original Root Engine theme and science-fiction weapon sounds."""
from pathlib import Path
import subprocess
import tempfile
import wave

import numpy as np


AUDIO = Path(__file__).resolve().parents[1] / "assets" / "audio"
RATE = 32_000
TAU = 2 * np.pi


def pcm(path, signal):
    data = np.rint(np.clip(signal, -1, 1) * 32767).astype("<i2")
    with wave.open(str(path), "wb") as target:
        target.setnchannels(1 if signal.ndim == 1 else signal.shape[1])
        target.setsampwidth(2)
        target.setframerate(RATE)
        target.writeframes(data.tobytes())


def chirp(t, pitch, drift):
    return np.sin(TAU * t * (pitch + drift * t / 2))


def render_effects():
    # Length, pitch and slide, body decay, grit, tick pitch and second tone.
    profiles = {
        "pistol": (0.105, 182, -710, 37, .62, 2410, 0),
        "heavy": (0.088, 256, -1050, 52, .70, 3180, 850),
        "scatter": (0.235, 128, -360, 19, .89, 2100, 165),
        "arc": (0.145, 820, 2400, 23, .20, 4300, 1530),
        "beam": (0.280, 1060, -2100, 11, .14, 3600, 1130),
        "disc": (0.195, 395, 1160, 16, .30, 1580, 585),
        "harpoon": (0.225, 204, -440, 21, .48, 1570, 420),
        "seeker": (0.145, 540, 2190, 23, .27, 2450, 705),
        "spore": (0.230, 293, -840, 19, .31, 920, 442),
        "trap": (0.210, 154, 510, 25, .38, 1260, 237),
        "nova": (0.320, 105, -150, 9, .52, 755, 260),
        "skimmer": (0.117, 315, -320, 30, .34, 2220, 511),
        "wind": (0.112, 290, 590, 30, .40, 1740, 663),
        "shell": (0.132, 134, -385, 31, .68, 2900, 182),
        "drill": (0.147, 188, -320, 26, .41, 2050, 576),
    }
    rng = np.random.default_rng(482)
    for name, (duration, pitch, drift, decay, grit, tick, overtone) in profiles.items():
        t = np.arange(round(RATE * duration)) / RATE
        raw = rng.uniform(-1, 1, t.size)
        crack = (raw - np.roll(raw, 1) * .69) * np.exp(-90 * t)
        transient = chirp(t, tick, -16000) * np.exp(-145 * t)
        body = chirp(t, pitch, drift) + .28 * chirp(t, pitch * 2, drift * 2)
        if overtone:
            body += .37 * chirp(t, overtone, drift * .57)
        attack = np.minimum(1, t / .0011)
        tail = np.minimum(1, (duration - t) / .008)
        signal = (crack * grit * .52 + transient * .19 + body * .47 * np.exp(-decay * t))
        pcm(AUDIO / f"fire-{name}.wav", np.tanh(signal * 1.35) * attack * tail * .77)

    t = np.arange(round(RATE * .48)) / RATE
    alert = chirp(t, 142, 440) * .38 + chirp(t, 760, -180) * .17 + chirp(t, 1137, -260) * .13
    pulse = .68 + .32 * np.cos(TAU * 9. * t)
    curve = np.minimum(1, t / .018) * np.minimum(1, (.48 - t) / .075)
    pcm(AUDIO / "root-charge.wav", alert * pulse * curve)


def render_sprint():
    duration = .42
    t = np.arange(round(RATE * duration)) / RATE
    rng = np.random.default_rng(143)
    noise = rng.uniform(-1., 1., len(t))
    broad = np.convolve(noise, np.ones(18)/18, mode="same")
    sparks = (noise - np.roll(noise, 1)) * np.maximum(0., np.sin(TAU*34*t+.6))**5
    swell = np.minimum(1., t/.025) * np.minimum(1., (duration-t)/.12) * np.exp(-3.8*t)
    body = .19 * chirp(t, 115, -115) + .055 * chirp(t, 289, -380)
    pcm(AUDIO / "sprint-ignite.wav", swell * (.56*broad + .09*sparks + body))


def render_rocket():
    rng = np.random.default_rng(611)
    launch_time = .36
    t = np.arange(round(RATE * launch_time)) / RATE
    noise = rng.uniform(-1., 1., len(t))
    jet = np.convolve(noise, np.ones(7) / 7, mode="same")
    ignition = np.exp(-58. * t) * (.31 * chirp(t, 148, -195) + .31 * noise)
    thrust = np.exp(-8. * t) * (.55 * jet + .14 * chirp(t, 510, -925))
    envelope = np.minimum(1., t / .003) * np.minimum(1., (launch_time - t) / .035)
    pcm(AUDIO / "fire-rocket.wav", np.tanh((ignition + thrust) * 1.44) * envelope * .75)

    impact_time = .46
    t = np.arange(round(RATE * impact_time)) / RATE
    noise = rng.uniform(-1., 1., len(t))
    debris = np.convolve(noise, np.ones(11) / 11, mode="same")
    crack = (.50 * noise + .11 * chirp(t, 2400, -8400)) * np.exp(-43. * t)
    blast = (.59 * chirp(t, 103, -156) + .23 * chirp(t, 176, -260) + .29 * debris) * np.exp(-10. * t)
    envelope = np.minimum(1., t / .0025) * np.minimum(1., (impact_time - t) / .045)
    pcm(AUDIO / "rocket-impact.wav", np.tanh((crack + blast) * 1.28) * envelope * .72)


def render_theme():
    # 16 bars at 124 BPM. The half-time B section opens into a denser reprise.
    beat = 60 / 124
    length = round(64 * beat * RATE)
    mix = np.zeros((length, 2))
    rng = np.random.default_rng(73)

    def place(start, signal, pan, gain):
        indices = (round(start * beat * RATE) + np.arange(len(signal))) % length
        mix[indices, 0] += signal * gain * np.sqrt(.5 * (1 - pan))
        mix[indices, 1] += signal * gain * np.sqrt(.5 * (1 + pan))

    def voice(start, duration, midi, voice_kind, pan=0, gain=1):
        t = np.arange(round(beat * duration * RATE)) / RATE
        p = TAU * 440 * 2 ** ((midi - 69) / 12) * t
        if voice_kind == "bass":
            signal = np.sin(p) + .39 * np.sin(2 * p) + .12 * np.sin(3 * p)
            attack, release, level = .006, .054, .22
        elif voice_kind == "strings":
            signal = (np.sin(p) + .47 * np.sin(2 * p) + .26 * np.sin(3 * p + .25 * np.sin(TAU * 3.5 * t))) / 1.55
            attack, release, level = .11, .2, .105
        else:
            vibrato = p + .1 * np.sin(t * TAU * 5.6)
            signal = (np.sin(vibrato) + .55 * np.sin(2 * vibrato) + .2 * np.sin(4 * vibrato)) / 1.7
            attack, release, level = .021, .085, .2
        env = np.minimum(1, t / attack) * np.minimum(1, (beat * duration - t) / release)
        place(start, signal * env, pan, gain * level)

    def drum(start, kind, gain=1, pan=0):
        t = np.arange(round(RATE * .26)) / RATE
        noise = rng.uniform(-1, 1, t.size)
        if kind == "kick":
            phase = TAU * (48 * t + 6.1 * (1 - np.exp(-21 * t)))
            signal = (.8 * np.sin(phase) * np.exp(-19 * t) + noise * .09 * np.exp(-120 * t))
        elif kind == "snare":
            signal = (.64 * noise + .22 * chirp(t, 200, -320)) * np.exp(-24 * t)
        elif kind == "tom":
            signal = (.73 * chirp(t, 128, -250) + .25 * noise) * np.exp(-17 * t)
        else:
            signal = (noise - np.roll(noise, 1)) * np.exp(-70 * t) * .16
        envelope = np.minimum(1, t / .0015) * np.minimum(1, (.26 - t) / .012)
        place(start, signal * envelope, pan, .27 * gain)

    # D minor, Bb, G minor and A, with brass call-and-answer.
    roots = [38, 34, 31, 33, 38, 34, 31, 33, 34, 31, 38, 33, 38, 34, 31, 33]
    motif = [(0, .65, 74), (.75, .21, 72), (1, .48, 69), (1.5, .42, 65), (2.5, 1.1, 69)]
    reply = [(0, 1.25, 70), (1.5, .46, 69), (2.0, .63, 67), (2.75, 1.05, 64)]
    for bar, root in enumerate(roots):
        base = bar * 4
        bridge = 8 <= bar < 12
        for hop in ([0, 1.5, 2.5, 3.5] if bridge else [0, .5, 1, 1.5, 2, 2.75, 3.25, 3.5]):
            voice(base + hop, .41, root + (12 if hop == 3.5 else 0), "bass", gain=.74 if bridge else 1.)
        third = 4 if root in [34, 33] else 3
        for index, note in enumerate([root + 12, root + 12 + third, root + 19, root + 24]):
            voice(base, 4.12, note, "strings", (index - 1.5) * .37, .63 if index == 3 else .84)
        for offset in ([0, 2.75] if bridge else [0, 1.5, 2, 3.25]):
            drum(base + offset, "kick")
        for offset in ([2.] if bridge else [1., 3.]):
            drum(base + offset, "snare", .9, -.13)
        for index in range(4 if bridge else 8):
            drum(base + index * (1 if bridge else .5), "hat", .72 if index % 2 else 1., .34 if index % 2 else -.27)
        if bar in [3, 7, 11, 15]:
            for i, offset in enumerate([2.5, 2.75, 3, 3.5, 3.75]):
                drum(base + offset, "tom", .9, -.56 + i * .28)
        phrase = [(0, 1.65, 77), (2, 1.8, 74)] if bridge else (motif if bar % 2 == 0 else reply)
        for offset, duration, note in phrase:
            voice(base + offset, duration, note, "brass", -.22, .86)
            voice(base + offset + .045, duration, note - (12 if bar >= 12 else 5), "brass", .35, .47 if bar >= 12 else .23)
            voice(base + offset + .28, duration * .62, note, "brass", .56, .16)

    signal = np.tanh(mix * 1.32)
    signal *= .85 / np.max(np.abs(signal))
    with tempfile.TemporaryDirectory() as scratch:
        source = Path(scratch) / "theme.wav"
        pcm(source, signal)
        subprocess.run(
            ["ffmpeg", "-nostdin", "-loglevel", "error", "-y", "-i", str(source),
             "-c:a", "libvorbis", "-q:a", "5", str(AUDIO / "mission1-boss-battle.ogg")],
            check=True,
        )


if __name__ == "__main__":
    render_effects()
    render_sprint()
    render_rocket()
    render_theme()
