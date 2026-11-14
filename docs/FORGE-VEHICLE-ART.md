# Vehicle support and cannon registration

`FORGE-VEHICLES-PROVENANCE.json` is derivative measurement metadata for existing art. It does not redraw, resample or replace `campaign-vehicles.png`, `arcade-machines.png` or their earlier registration files. The 84 registered drawings already existed and are **not new artwork**.

The shell, wind and drill vehicles each have the existing six-frame neutral, cannon, hurt and collapse rows. The legacy skimmer has only six hover and six cannon drawings; absent wreck/hurt requests resolve to its existing hover row rather than inventing a new death sequence.

The neutral anatomical support-to-top height is calibrated once per vehicle to twice the actual Aion gun-run body height: 2 × 73.2427184466 = 146.4854368932 world pixels. Every other phase uses that same source scale. Wings, muzzle flashes and collapsed debris never trigger per-frame size normalization.

Intact horizontal origins follow distinct rear-wheel, gem, fixed-seat or hull-stripe patches. They do not follow the armed silhouette's bounding-box centre. Anatomical support uses the actual largest connected body floor; detached sparks do not become the support reference. Collapsed sprites use a fixed authored atlas-cell root and their lower wreck support, preserving the intended collapse instead of recentering shrinking debris.

`ForgeVehicleArt.pose()` returns world-unit texture offset/size, `muzzle_local`, `pivot_local` and `barrel_length`. `ForgeVehicleArt.anchors()` provides the same measurements without loading textures. These points are relative to the **vehicle ground origin**, not the seated hero's head. For the existing seated hero origin at Y = ground − 42, callers add `(0, 42)` before converting a vehicle point to hero-relative coordinates.

| Vehicle | Neutral pivot from ground | Neutral muzzle from ground |
|---|---|---|
| Shell | (39.159, −50.762) | (69.617, −50.762) |
| Wind | (40.517, −67.009) | (87.268, −67.009) |
| Drill | (35.465, −64.762) | (86.349, −64.762) |
| Skimmer | (70.253, −65.769) | (104.632, −65.769) |

The previous mounted formula spawned a shell shot about 136 pixels above the ground while its visible barrel was approximately 51 pixels above it. Using the same measured pivot and barrel length for rendering and physics fixes that disagreement. Eight-direction shots rotate around this measured pivot rather than an unrelated actor offset. A collapse phase is not a usable weapon; `anchors().can_fire` is false for it.

The existing cannon rows include horizontal flashes and rings baked into their art. A nonhorizontal shot must use the neutral hull with its separately aimed barrel and effect so the source's horizontal flash does not contradict the real shot direction. The deployed legacy skimmer cannon rims were reviewed individually to avoid mistaking the large luminous hull window for a muzzle.

Registration: `python3 packaging/register_forge_vehicles.py`. Annotated source previews are written to `build/forge-vehicle-review`; these are measurement fixtures, not normal-input gameplay evidence. Focused Godot check: `godot --headless --script tests/test_forge_vehicle_art.gd`. Final in-game/browser/device status is reported separately.
