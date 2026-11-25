# Mission 1 arcade art

The full-bleed `m1-selection-portraits.png` illustrations were generated with the previous six approved portraits as the character reference. Rows follow the playable roster. The 256 × 256 cells show open, half-closed, and closed eyes. Only the selected hero blinks. The packing step uses the open illustration for the entire cell and copies the two alternate eye poses inside registered windows. The character silhouette, clothing, and background stay pixel-identical across the three cels.

`m1-frog-spit.png` uses the original gnome, beetle, crow and slime art. Each has a closed-eye pose and four discrete airborne orientations. Source cells are 76 × 76 pixels. Gameplay controls the movement and impact separately from the image.

`m1-locks-and-traps.png` contains three materials for the six gate poses and five poses each for electric, vine and claw traps. Gate cells are 64 × 96. Trap cells are 64 × 56 and start at atlas Y 288. The bottom of each cell anchors to the terrain. Drawn at 2×, with smaller standalone mechanism gates.

`m1-sluice-trap.png` is an original 64 × 48 pixel strip with five poses for the Flooded Channel sluice. The set shows the inset grate, pressure warning, rising water, full surge and falloff. Each frame registers its bottom edge to the floor and draws at 2×.

Regenerate the spit and lock atlases from the repository root with Godot 4.6.3 and Pillow.

```sh
godot --headless --script packaging/m1_arcade_sprite_sources.gd -- /tmp/aion-arcade-cels
python3 packaging/draw_m1_arcade_art.py /tmp/aion-arcade-cels
```

To repack the portrait atlas, add `--portraits OPEN.png HALF.png CLOSED.png` with the three registered 1024 × 1536 source mosaics in reading order. Ordinary builds use the packed atlas.

`campaign-field-supplies.png` contains three original, transparent 32 × 32 cels in one row. From left to right they show a waxed-canvas field dressing, a copper repair case with a wrench, and a purple capacitor for the existing power-shot reward. The same cels appear in the keeper handover and on the ground. The mouth of each keeper's satchel is registered against its original handover cel. The reward lands at the same position used by the collision check.

The gate cels in `m1-locks-and-traps.png` use copper, canal iron and root-station finishes. The plate stack retracts behind a fixed counterweight and the two feet stay anchored throughout the six cels. `m1-root-hatch.png` contains a repeatable 64 × 14 lid tile, a broken lip and an 80-pixel fence post. `m1-route-hazards.png` uses two rows of five 64 × 72 cels for the terrace gust and crystal emitter. The crystal’s outlet aligns to the projectile height.

`m1-sprint-fire.png` has eight 64 × 36 cels for each of two original flame ribbons. Each cel shares the same foot pivot. The rear ribbon travels behind the hero and the near ribbon passes across the shins. Both layers mirror with travel and use 2× nearest-pixel sampling. Reduced motion uses a single cel for each layer. `packaging/draw_m1_arcade_art.py` generates the PNGs.
