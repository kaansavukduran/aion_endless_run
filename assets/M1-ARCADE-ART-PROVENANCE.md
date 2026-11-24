# Mission 1 arcade art

The six original hero designs supply the busts in `m1-selection-portraits.png`. The crop and eyes have fixed registration. Each hero has three authored eye poses. Only the selected hero blinks. Rows follow the playable roster. Cells are 136 × 112 source pixels.

`m1-frog-spit.png` uses the original gnome, beetle, crow and slime art. Each has a closed-eye pose and four discrete airborne orientations. Source cells are 76 × 76 pixels. Gameplay controls the movement and impact separately from the image.

`m1-locks-and-traps.png` contains three materials for the six gate poses and five poses each for electric, vine and claw traps. Gate cells are 64 × 96. Trap cells are 64 × 56 and start at atlas Y 288. The bottom of each cell anchors to the terrain. Drawn at 2×, with smaller standalone mechanism gates.

Regenerate from the repository root with Godot 4.6.3 and Pillow.

```sh
godot --headless --script packaging/m1_arcade_sprite_sources.gd -- /tmp/aion-arcade-cels
python3 packaging/draw_m1_arcade_art.py /tmp/aion-arcade-cels
```
