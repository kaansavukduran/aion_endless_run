# Verification

This file records evidence, not a promise of identical behavior on every device.

## Automated game tests

Godot 4.6.3, actual main scene and deterministic physics: **39 checks passed**. Grounded jump, double-jump rejection, pause freezing time/distance/height, fire/ice collisions, genuine pickups and obstacle clears without double awards, a long generated run through both biomes, retry counters, Space/Esc at the real scene entry, character selection, pause/resume preservation, on-screen language switching, disk persistence of best/character/settings, gameplay with sound/animation disabled.

The test uses a separate local data directory. It does not infer successful device installation from a source import or archive creation.

## Runtime and packages

Runtime screenshots, exported web UI tests and CI package statuses are added after verification. Until recorded here, a platform export preset is preparation, not a verified install. iOS App Store/TestFlight installation and macOS Developer ID/notarization require the owner's Apple distribution setup.
