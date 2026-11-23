# Mission 1: additional hero action cels

The original Aion, Kutsanmış, Ayça and Eren sources remain unchanged. Sixteen new AI-assisted source PNGs add genuine backward steps and grenade body gestures. These are game-specific production variants awaiting the owner's visual acceptance, not a canon change or a claim that the AKIO/Metal Slug quality target has been accepted.

`M1-HERO-ACTIONS.json` records source hashes, generation identifiers, full source rectangles, connected opaque body spans, the anatomical face marker, ground origin, hand sockets and one fixed scale per hero/source. The registration tool is `packaging/register_m1_actions.py`; it changes metadata only. Each runtime cel is isolated with a two-pixel transparent gutter. Whole-face registration fixes horizontal placement; the connected foot sole fixes vertical placement. Detached sheep halos remain visible.

The three-row `m1-actions-*.png` sources contain standing backward steps, an unused earlier crouch candidate and standing throws. The two-row `m1-low-actions-*.png` sources contain the final low backward steps and low throws. Four `m1-empty-actions-*.png` edit sources replace only standing throw cels 1 and 2 with imagegen-redrawn empty fingers. The original standing backsteps and all other standing throw cels keep their original source. In total 192 source cells contain 120 original drawn poses plus eight hand-edit variations; 64 unused reference cells in the edit sources are not counted as additional animation. The 24 taller crouch candidates and eight earlier held-object variations are superseded. Runtime animation remains 96 cels.

| Action | Authored cels | Runtime selection |
| --- | --- | --- |
| `walk_back` | 6 new backward weight-transfer poses | Ground velocity opposes stable aiming-facing; 132 world pixels per cycle |
| `crouch_walk_back` | 6 new low backward steps | Same rule while crouching; 94 world pixels per cycle |
| `grenade_throw` | 6 anticipation/release/follow-through poses | Simulation throw clock, starts 0/.04/.10/.16/.24/.33 seconds, ends .42 seconds |
| `crouch_grenade_throw` | 6 independently drawn floor-hugging arm/body poses | Same throw clock, with its own measured hand and crouched silhouette |

`M1HeroArt.metrics/pose/clip_spec` routes these actions to `M1HeroActionArt`; the existing five base actions and their sources remain intact. The bank also forwards new heroes to `MissionHeroArt`. `M1CombatArt.body_spec` selects backward locomotion using actual horizontal velocity and stable aim-facing. Its distance phase continues through weapon recoil. Grenade direction is captured by the simulation; rendering never consumes ammunition or creates a projectile. The necessary throw poses continue under reduced decorative motion.

Every runtime throwing cel has an empty hand and uses the same separate grenade object until release. The earlier baked green grenade was replaced through imagegen-drawn empty fingers, so it cannot change identity into the cyan steel projectile at release. Cel 3 is the open hand at the actual .16-second release. Both the held object and the projectile event use `grenade_hand_local`, mirrored once. The gun is suppressed for the whole throwing action.

The final low variants preserve the approved floor-hugging silhouette, including laid-back rabbit ears. Neutral face heights above the floor are approximately 28/27/31/36 world pixels for Aion/Kutsanmış/Ayça/Eren, compared with 47/56/61/59 in the new standing throw sources. Earlier taller low-pose candidates were rejected during scale review and remain only in the private work area.

`tests/test_campaign_backwalk.gd` exercises actual World movement and fire operations, both facing sides, crouching, six-cel gait progress, stable near-vertical facing, shared gun grips, independent gutters, source uniqueness and exact release-cel timing. It is deterministic simulation evidence. The native CampaignGame render strips in the task evidence directory are staged art review fixtures. Neither is ordinary-input mission completion, physical device coverage, or owner art approval.


The unchanged pier crawlway has 55 world pixels of clearance. Staged native review found the earlier low Aion gills, Kutsanmış halo and Eren fur intersecting its roof; Ayça's original forward crouch also exceeded it. Four `m1-tunnel-*.png` sheets therefore add independently drawn backward crawl, forward crawl, sidearm gesture and ready/recoil rows. `CampaignRoutes.low_ceiling` selects these compact anatomies; other scenes keep their previous variants. The chin moves down, ears/gills tuck horizontally, and Kutsanmış tilts the entire halo behind its skull. The source is never vertically compressed or scaled frame by frame. Maximum complete silhouettes are approximately 43.79/54.79/49.09/43.32 world pixels, respectively. The regression additionally checks the rounded draw offset and first opaque texture row against the actual ceiling.

The complete action-bank inventory is now 288 source cells, including 216 original pose drawings and eight edited hand variations; 64 unused reference cells in the edit sheets are excluded from the drawing count. There are 192 runtime cels, with 32 earlier variants superseded. These counts describe this bank alone, not the separately authored Armadillo/Frog bank or a quality score.


The held pistol now uses the separate `m1-held-pistol.png` gameplay variant at the same 28-world-pixel width. Its cyan pressure lens, brass rim and angled brown grip remain recognizable at native scale; the ornate pickup is unchanged. `M1-HELD-VARIANTS.json` records its exact source SHA, connected silhouette, independent gutter, grip and front-rim muzzle. The other ten held weapons keep their existing paths and registrations. `tests/test_held_weapon_art.gd` compares all runtime colored pixels against the appropriate original registered source and checks both opaque sockets; the original pickup SHA and cached pickup pixels remain protected.

Under a low ceiling, the old four heroes' existing dying/dead pose fallback now uses the compact ready cel 5. It is an adaptation of an existing low pose, not a newly authored death animation. The regression triggers real fatal damage and advances the actual death timer while checking support and opaque roof bounds.
