# Mission 1 playable body layers

Seven new, unmodified generated RGBA PNGs supply **168 source cels**. The runtime uses **120**: four heroes × five actions × six cels. The 48 original crouch draft cels in the four base sheets are superseded by the deeper crouch sheets; they are not counted again as usable animations. A rejected earlier sheep crouch generation remains outside the project in the task working archive.

| Hero key | Game identity | Base source | Crouch source |
| --- | --- | --- | --- |
| aion | Aion, original pink axolotl scientist | m1-body-aion.png | m1-aion-crouch.png |
| sheep | Kutsanmış, cream bipedal sheep/halo | m1-body-sheep.png | m1-sheep-crouch.png |
| rabbit | Ayça, owner-requested feminine rabbit variant | m1-body-ayca.png | m1-rabbit-crouch.png rows0–1 |
| eren | Eren, original russet rabbit/dark-teal jacket | m1-body-eren.png | m1-rabbit-crouch.png rows2–3 |

Ayça's ivory blouse, teal/rose skirt, opaque leggings and bow are the user's new in-game variant. Old Emre source art remains untouched. This is not a change to the private global character canon. Aion retains pink skin, blue-tipped gills, blue eyes, white coat/badges and DNA tail. Kutsanmış runs on two legs; its low commando crouch folds the same two legs and arms. Eren retains its own original costume.

`M1HeroArt.metrics(hero,action,frame)` is JSON-only and allocates no textures. `pose()` adds a cached isolated texture using exactly those metrics. Actions are `walk`, `idle_fire`, `air_fire`, `crouch_walk`, `crouch_fire`, all six cels. Walk follows174world pixels; crouch walk110; firing reaction.28s. Idle is `idle_fire` frame0. Air cels follow actual jump phase.

Each sheet is body-only with an empty two-handed grip. The separate weapon pivots at `grip_local`, and projectile physics must use the same grip and measured weapon barrel length. Aiming never swaps/scales the entire hero. Grip translation follows a bounded RGB/alpha wrist patch, independently of the full-face reference. This preserves small authored arm recoil without shifting the physics actor.

Registration uses actual alpha gutters, complete connected bodies, separate transparent texture padding, whole-face anatomical anchors and actual sole baselines. A source scale is constant for a hero/atlas, never recalculated from a frame's bounding box or weapon effect. Alternate crouch sheets use one calibrated full-face size ratio for the whole clip. Crouched skulls retain their physical size; joints/hips lower the silhouette. Grounded feet meet zero; air uses the standing head/body root. The detached magical halo is retained.

Reproduce metadata with `python3 packaging/register_m1_heroes.py`. It never rewrites PNG pixels and atomically replaces `M1-HEROES-PROVENANCE.json`. Tests: `tests/test_m1_hero_art.gd`; source receipts and diagnostic face/grip contact sheets are in `/workspace/work/m1-art/`. Those sheets are authored art QA, not normal-input or physical-device evidence. Generation was AI-assisted under the user's explicit request; original approved PNGs are unchanged and final user art approval is separate from technical PASS.
