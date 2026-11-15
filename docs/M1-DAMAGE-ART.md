# Ayça damage art

Ayça now has her own damage drawings. The previous male rabbit art remains
unchanged and is not reused for her costume, ice, fire or collapse states.

The new source is `assets/m1-damage-ayca.png`: four rows of six individually
drawn poses, in the order `freeze`, `fire`, `impact`, `faceplant`. The freezing
shell grows around the same rabbit; the fire sequence dissolves into a small
ash mound with her bow; the two collapse clips progressively bend knees and
elbows into side-lying and face-down poses. These are source poses, not rotations
or squeezed versions of an idle image. Her tan fur, green eyes, rose bow, ivory
blouse, teal skirt with rose hem, opaque leggings and boots follow the current
Ayça model sheet.

`M1DamageArt.metrics(hero, action, frame)` reads registration only; `pose` adds
the cached isolated texture. The supported hero key is `rabbit`; frame indices
are 0–5. Offset and size are already world units. Use `source_scale` only when
converting source pixels. The returned fields include source key/row/frame,
height, ground contact, face visibility, face position and head size.

One neutral full-face comparison calibrates a source ratio of 1.10 against the
current Ayça sheet. All 24 poses share source scale 0.39357627297325787. Visible
faces remain at actor-relative X=14, and actual connected soles/body contact the
ground. A growing ice shell or collapsing torso does not resize the skull.
The final ashes explicitly have no face landmark or head size. Green diagnostic
markers identify the reviewed open/closed-eye point; they are not runtime art.

The generated RGBA source stays byte-for-byte unchanged. The registrar keeps
alpha >=192 connected silhouette spans, copies them into separate textures, and
adds two transparent pixels around each cel. Low-alpha hidden RGB backdrop
colors and neighboring cells therefore cannot enter rendering. Soft smoke may
be reduced by this deliberate isolation rule. Metadata records the original
generation identifier, source SHA-256 and registration method in
`assets/M1-DAMAGE-PROVENANCE.json`.

Rebuild metadata with `python3 packaging/register_m1_damage.py` and run the
isolated checks with `godot --headless --script tests/test_m1_damage_art.gd`.
The 254 checks validate actual source identity, 24 unique isolated pixel cels,
opaque face markers, fixed scale/head registration, transparent gutters,
ground contact and lowering collapse poses. They do not replace gameplay or
browser verification of the complete death sequence.
