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
