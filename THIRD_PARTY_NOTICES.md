# Third-party notices

Original game code is MPL-2.0 (`LICENSE`).

## Owner-authorized artwork

The unchanged runner PNG, owl/wolf/sheep PNGs and their provenance are reused at the owner's explicit request from:

- https://github.com/kaansavukduran/fire-axolotl-extension at `c440c352f3b97f1efccbec871fd96d6ed5a6a6ed`.
- Its original donor https://github.com/kaansavukduran/fire-axolotl at `ad76813936a4b933780e1a4c712452a6b21d014b`.

The donor records original AI-generated, user-authorized artwork under MPL-2.0 to the extent licensable. Individual artwork records are preserved in `assets/RUNNER-PROVENANCE.json` and `assets/CHARACTERS-PROVENANCE.json`. This game does not include GPL browser extension components or third-party browser engines. No claim of exclusive copyright in AI-generated output, transfer of mascot ownership, or third-party endorsement is made.

The packaged PNG hashes match the donor. Display pixelation of companions happens in a shader; the source images are unchanged. Aion is Kaan's personal mascot. No Chrome dinosaur assets or code and no built-in ChatGPT Pet artwork are included.

## Font

Lexend, SIL Open Font License 1.1. The unchanged local font and its license are included in `assets/Lexend.ttf` and `assets/LEXEND-OFL.txt`. The font is bundled and requires no network request. Upstream: https://github.com/google/fonts/tree/main/ofl/lexend .

## Engine

Godot Engine 4.6.3, MIT license, https://godotengine.org/license/ . Native and web exports embed the Godot runtime and its third-party components. Full engine copyright/license notices: https://github.com/godotengine/godot/blob/4.6.3-stable/COPYRIGHT.txt and https://github.com/godotengine/godot/blob/4.6.3-stable/LICENSE.txt . A copy is included as `assets/GODOT-COPYRIGHT.txt` and `assets/GODOT-LICENSE.txt` in this source and game resources.

Original procedural scenery and synthesized game sounds are part of this project's MPL-2.0 source. No downloaded audio or paid asset pack is used.

## Companion runner atlas (0.2.0)

`assets/companions-runner.png` is a newly generated owner-authorized derivative of the existing wolf/sheep/owl identities, with Aion as the pixel-art style reference. Six columns × six rows contain sequential right-facing running, jumping and gliding poses. It is not the old idle sheet translated across the screen. The generated PNG is unchanged; runtime source rectangles, registered baselines and alpha discard handle alignment/transparency. Provenance and SHA-256: `assets/COMPANION-RUNNER-PROVENANCE.json`. Same MPL-2.0 artwork terms and AI-output limitations apply.
