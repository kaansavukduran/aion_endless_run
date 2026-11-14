# Hero weapon carry and vehicle entry art

Four new original AI-assisted PNG atlases preserve the six existing local hero references. These drawings are game-art drafts; canon or final aesthetic approval is not implied. Existing source PNGs are unchanged. No Metal Slug art, sound, logo or interface fragment is used.

| Source | Layout | Actual new drawings | Playback |
|---|---|---:|---|
| `forge-mouth-carry.png` | 4 rows × 6 | 24 | Owl glide 1.0 s loop; owl flap 0.30 s; quadruped wolf gallop 0.42 s loop; wolf mouth-fire 0.30 s |
| `forge-embark.png` | 6 rows × 6 | 36 | Each hero climbs, ducks and sits over 0.45 s. Exit reuses the reverse sequence and is not counted as new art. |
| `forge-eightway.png` | 6 rows × 8 | 48 | Eight distinct directional keyposes per hero. These are held aiming poses, not 48 separate animated clips. |
| `forge-mouth-aim.png` | 2 rows × 8 | 16 | Owl airborne and quadruped wolf mouth-held gun keyposes in all eight directions. |

Total: **124 distinct cropped drawings**, ten drawn animation sequences, six reverse exit playbacks and 64 directional keyposes. Hero row order in embark/eightway is Aion, Melun, Kutsanmış, Ömer, Emre, Eren. Direction order is right, up-right, up, up-left, left, down-left, down, down-right. Mouth-aim row order is owl, wolf.

The references are `polish-aion`, `pixel-wolf`, `polish-sheep`, `polish-abilities`, `pixel-rabbit` and `pixel-eren`. Generation IDs, source hashes, actual alpha regions, per-source scales, origins, face landmarks, timings and muzzle points are in `assets/FORGE-HEROES-PROVENANCE.json`. The reproducible registration tool is `packaging/register_forge_heroes.py`; it does not resample or rewrite the source PNGs.

`ForgeHeroArt` returns isolated textures with two transparent sampling pixels and world-unit offset/size. `gun_embedded` prevents drawing a duplicate gun. Directional keyposes are already drawn facing the requested absolute direction; the renderer must not mirror a left keypose again. Right-authored carry loops and hatch-entry sequences can be mirrored normally.

Mouth-carry loops share a fixed whole-face reference and source scale. The wolf's ground anchor uses anatomical foot contact; the owl's flight uses a shared body/face reference. Directional aim origins use face landmarks and feet rather than an armed silhouette's bounding-box centre. A downward barrel is excluded from the foot measurement. Hatch origins use the fixed authored atlas cell root, never the crop rectangle's centre. Weapons, wings, tail, halo and gun flashes are not size references.

Calibration records distinguish bounded whole-face patch fitting from explicitly reviewed skull-proportion corrections. Aion's blue gill and the wolf's cyan iris were caught in the annotated muzzle review and explicitly excluded from the two upward muzzle measurements. `muzzle_local` is the resulting registered barrel tip in actor-relative world units. Visual poses do not change physical actor coordinates or collision shapes; gameplay owns the existing hitbox and action timing.

The source-level review matrices in `build/forge-art-review` are annotated registration previews, not normal-input browser proof. The focused runtime check is `godot --headless --script tests/test_forge_hero_art.gd`. In-game and physical-device status belongs to the final task verification report.
