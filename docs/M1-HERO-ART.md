# Mission 1 playable body layers

The four original playable bodies share five locomotion actions with six cels each. Aion and Kutsanmış additionally use their 0.51 redraw for the forward and backward gaits, close actions, reactions and low passages. Ayça and Eren keep their existing body atlases.

| Hero key | Game identity | Base source | Crouch source |
| --- | --- | --- | --- |
| aion | Aion, original pink axolotl scientist | m1-redraw-aion.png | m1-redraw-aion-crouch.png |
| sheep | Kutsanmış, cream bipedal sheep/halo | m1-redraw-sheep.png | m1-redraw-sheep-crouch.png |
| rabbit | Ayça, owner-requested feminine rabbit variant | m1-body-ayca.png | m1-rabbit-crouch.png rows0–1 |
| eren | Eren, original russet rabbit/dark-teal jacket | m1-body-eren.png | m1-rabbit-crouch.png rows2–3 |

Ayça's ivory blouse, teal/rose skirt, opaque leggings and bow are the user's new in-game variant. Old Emre source art remains untouched. This is not a change to the private global character canon. Aion retains pink skin, blue-tipped gills, blue eyes, white coat/badges and DNA tail. Kutsanmış runs on two legs; its low commando crouch folds the same two legs and arms. Eren retains its own original costume.

`M1HeroArt.metrics(hero,action,frame)` is JSON-only and allocates no textures. `pose()` adds a cached isolated texture using exactly those metrics. Actions are `walk`, `idle_fire`, `air_fire`, `crouch_walk`, `crouch_fire`, all six cels. Walk follows174world pixels; crouch walk110; firing reaction.28s. Idle is `idle_fire` frame0. Air cels follow actual jump phase.

Each sheet is body-only with an empty two-handed grip. The separate weapon pivots at `grip_local`, and projectile physics must use the same grip and measured weapon barrel length. Aiming never swaps/scales the entire hero. Grip translation follows a bounded RGB/alpha wrist patch, independently of the full-face reference. This preserves small authored arm recoil without shifting the physics actor.

Registration uses actual alpha gutters, complete connected bodies, separate transparent texture padding, whole-face anatomical anchors and actual sole baselines. A source scale is constant for a hero/atlas, never recalculated from a frame's bounding box or weapon effect. Alternate crouch sheets use one calibrated full-face size ratio for the whole clip. Crouched skulls retain their physical size; joints/hips lower the silhouette. Grounded feet meet zero; air uses the standing head/body root. The detached magical halo is retained.

## Aion and Kutsanmış redraw

Aion's model follows the main character reference and `Aion_T_Poz_Pafta_Varyant_A.png`. The selected tail retains the pink DNA pattern, cyan-edged external gills, blue eyes and two blue lab-coat patches. Kutsanmış follows `Kuzu_Modelleme_Paftasi_v02.png` for the separate gold halo, curled forelock, cream wool, amber eyes, peach ear interior and paired hooves. The regular gait stays bipedal. Artwork is AI-assisted and registered against the model references. The original approved PNGs remain in Git.

Ten new RGBA sheets contain 228 drawn cels. Of these, 204 are bound to runtime clips. The 24 shallow crouch drafts in the base sheets are unused. Each hero has six distinct cels in every active clip.

| Sheet per hero | Active clips |
| --- | --- |
| Base | Walk, idle/standing fire, jump/air fire |
| Crouch | Crouch walk, crouch fire |
| Actions | Aimed backstep, crouched backstep, standing throw, crouched throw, standing hurt, death |
| Tunnel | Backward crawl, forward crawl, low throw, low idle |
| Contact | Standing close strike, rope cut |

The knife follows the measured wrist during the same rope contact event. The unarmed strike uses its drawn fist or hoof; its impact coincides with the existing close-damage event. Fresh body cels also appear in selection, the Mission 1 intro and victory presentation, and shared Classic locomotion. Classic-specific death effects and older story portraits still use their own banks.

Run `python3 packaging/register_m1_redraw.py` to reproduce the two runtime JSON manifests. If the historical registration recipes are rerun, apply this one last. It validates solid hand sockets, rejects nonfinite registration values and checks authored tunnel clearance before replacing the manifests. Registration reads the untouched art sources and never rewrites PNG pixels. Tests are in `tests/test_m1_hero_art.gd`, `tests/test_campaign_backwalk.gd` and the normal-input `tests/browser_six_heroes.py` matrix. Artwork approval remains with the user.
