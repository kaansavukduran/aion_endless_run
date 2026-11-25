# Mission 1 soundtrack

- `mission1-forest.ogg` is MintoDog’s [Forest Stage](https://opengameart.org/content/forest-stage), published under [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/). The canal and roots keep their dedicated ambience.
- `mission1-boss-battle.ogg` is the original Root Engine theme. The 16-bar score has a D minor brass motif, a half-time bridge and a heavier reprise. It begins when the boss engages and fades into the victory cue.
- `fire-*.wav` and `root-charge.wav` are original, code-authored synthesizer effects with no external samples. Each weapon and vehicle triggers its sound on the projectile and muzzle-flash event. The charge alert plays when the danger lane first appears.
- `sprint-ignite.wav` is the original 420 ms ember and rushing-air cue for Ayça and Eren. Each powered sprint plays it once at ignition.

Rebuild the original theme and effects with `python3 packaging/prepare_finale_audio.py` using NumPy and FFmpeg with libvorbis. The game uses the same sound and volume settings for all tracks.
