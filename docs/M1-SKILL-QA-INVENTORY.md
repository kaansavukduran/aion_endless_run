# Mission 1 rework: skill packaging and initial QA inventory

Recorded 15 November 2026, Europe/Istanbul. Baseline `main` is `4864b09ce7efea0d2c1b4eaead8703b9cb465b0e`. The application remains Godot4.6.3. This inventory uses `git show HEAD:<path>` so concurrent implementation edits are not mislabeled as baseline observations. Runtime observations and final acceptance results must be recorded separately after integration.

## Skill update status

The user explicitly requested updates to **Unslop** and **Fragaria Unslop**. The current cloud manifests and all ten referenced source pages were read through `skills.read`. Available skill tools expose listing/reading, not writing these cloud-owned skill packages. **Cloud-installed versions: NOT CHANGED / write access unavailable.** This is not a claim that a different plugin update API can edit user skills.

Two complete project-local packages are installed at:

- `.agents/skills/unslop/SKILL.md`
- `.agents/skills/fragaria-unslop/SKILL.md`

These files are available to an agent host that discovers repository `.agents/skills`; the active cloud catalogue is unchanged. Each package has its original manifest, five bundled original reference pages and two new reference pages. Existing privacy, authorization, verification and scoped-repair safeguards remain. The copied Fragaria profile resolves private authority documents from active task/project sources instead of republishing private Drive URLs. Original Aion/Emre canon guidance is retained, with an explicit game-local variant rule so Ayça does not silently overwrite shared reference archives.

The new `game-regression-gates.md` covers authored facing versus world facing, actual NPC velocity, fixed anatomical scale, full idle/walk/air/crouch fire states, real muzzle pixels, continuous vehicle aim, physical forks, contact-only world pickups, limited assists, deployable expiry, model/HUD health agreement and first-click readiness after actual engine layout. The generic package does not impose AIONIA lore; numerical values are isolated in the repository-specific `project-contract.md`.

**PASS:** `python3 packaging/validate_project_skills.py --output build/m1-skill-validation.json` checks both manifests, all16 Markdown pages and16 relative links. Private authority URLs are absent from the public package. This is packaging validation, not proof that game behaviors pass. No guidance file guarantees that future bugs cannot occur.

## Baseline findings and acceptance targets

| ID | Severity | Baseline evidence | Requested acceptance / test impact |
| --- | --- | --- | --- |
| M1-QA-01 | Medium | `scripts/campaign_game.gd:265–269` renders `fork_one`/`fork_two` as `Route_*` text buttons calling `world.choose_route()`. | Ordinary movement reaches upper/lower physical exits for both splits. No gameplay route-choice modal. Existing three destinations and route/checkpoint state must remain coherent. |
| M1-QA-02 | Medium | `scripts/campaign_game.gd:664–667` quantizes the aim vector to sign components and writes `move_axis=Vector2(axis,0)`. | Continuous mounted analog aim retains non45-degree angles; Down/S/controller/touch down reaches real crouch movement, lowered collision and firing. |
| M1-QA-03 | Medium | `scripts/campaign_world.gd:104` defaults vehicle HP4; repair at457 clamps4. `scripts/campaign_hud.gd:32` displays `/4`. | Model, damage/destruction/ejection, repair, HUD and old saved HP normalize to the requested maximum3. |
| M1-QA-04 | Medium | `scripts/campaign_weapons.gd:15,49,74…` gives trap life6, gravity, then zero velocity on landing; proximity detonation. `scripts/campaign_view.gd:283` draws a simple stationary trap shape. | Walking spider seeks a live target, contact detonation and hard no-target self-detonation by5seconds. Verify target death/missing/unreachable cases and visual cleanup. |
| M1-QA-05 | Medium | `scripts/campaign_rescue.gd:87–96,124` handover directly calls `award/collect` after the thank-you timer. | Bag handoff spawns a visible persistent world item; only actual pickup contact applies its effect once. Test no-contact, departure, death/retry and resume without duplicate gifts. |
| M1-QA-06 | Medium | Source at `scripts/campaign_view.gd:167` passes roaming/departing NPC facing straight into texture mirroring. Model at `campaign_rescue.gd:128` moves left with facing−1. | Inspect actual source walk direction; compare the rendered face with world velocity in both directions. User reports backward walking; exact source orientation/render reproduction is pending before assigning the mirror cause as confirmed. |
| M1-QA-07 | Medium | `scripts/campaign_world.gd:297–312` chooses a full-body directional keypose for nonhorizontal aim; `campaign_view.gd:69–84` selects firing and movement clips separately. | Verify actual stationary/walking/ascending/descending/crouch fire, real shot/damage and consistent locomotion. A directional still is not a full walk cycle. User-reported failed firing is not yet proven as an input failure by this source inspection. |
| M1-QA-08 | Medium | User reports changing rabbit/body proportions while looking down and holding the pistol. Existing Forge pose metadata uses per-row scales but that alone does not prove consistent anatomical drawing. | Measure face/skull/torso landmarks and constant source scale through every action and direction. Do not normalize whole texture bounds or force crouch body height to equal standing. Runtime/art measurements are pending. |
| M1-QA-09 | Approved scope change | `campaign_world.gd:6` has6playable keys; `text.gd:4` has11languages. | Four playable identities: Aion, Kutsanmış, Ayça (legacy keyrabbit allowed), Eren. Owl/wolf become two-attack assists; active languages onlyTR/EN. Preserve old assets, scores and deliberate migrations. |
| M1-QA-10 | Approved balance change | Crow dive source `campaign_world.gd:475,514` follows an authored dive target/return path. | Identify the forward lunge component and reduce it by10% relative to recorded baseline, without altering all enemy speed/spawn balance. |
| M1-QA-11 | Approved presentation scope | Existing front/menu and action art require the user's requested quality review. | Original cohesive arcade menu through real Mission1 completion, readable HUD and all4heroes. Reference quality does not authorize copying Metal Slug artwork. Static art previews do not stand in for working UI. |

## Existing tests that must be adapted, not silently skipped

- `tests/browser_forge.py` selects six heroes including owl/wolf. The new four-character selection flow and Ayça label/art need ordinary activation checks. Preserve all still-applicable control, pause, first-click and save assertions.
- `tests/browser_campaign.py` chooses `Route_canopy`, `Route_water`, `Route_terrace` and `Route_roots` buttons. Replace that path with real movement/jump/drop through actual branch geometry. Do not call `choose_route()` through a debug setter and label it normal play.
- `packaging/android_input_smoke.py` exercises TR/CS/EN and old playable owl glide/three flaps. Update explicitly for TR/EN and current playable actions/assists; retain the physical meaning of input and screenshot assertions. Do not claim a removed owl-player test passed.
- `tests/test_campaign_directional.gd`, `test_armed_muzzles.gd`, `test_vehicle_muzzles.gd`, `test_campaign_art.gd`, `test_forge_visual.gd` and `test_pixel_heroes.gd` encode art rows, pose/muzzle and scale contracts. Keep historical six-row source indexing where assets remain archived, while testing only four current playable identities in menu/gameplay contracts.
- `tests/test_campaign.gd`, `test_campaign_expansion.gd`, `test_campaign_forge.gd`, `test_campaign_ui.gd` and presentation tests contain route, health, reward and roster expectations. Change assertions only for the documented new behavior; preserve real damage, save and one-time effect checks.
- `tests/test_enemy_facing.gd` retains the prior enemy facing fix. Extend or pair it with actual freed-NPC velocity/facing observations instead of assuming all source atlases face the same way.
- Render fixtures must acknowledge actual intro/mission presentation and refresh poses after resize. Ordinary first clicks must await real engine layout acknowledgement, not two browser animation frames.

This inventory does not own runtime implementation and does not assign PASS to pending features. Final normal-input acceptance must cover both forks/all destinations, all four heroes, TR/EN, portrait/landscape, keyboard/mouse/touch/gamepad, pause/resume, boss victory/result and saved-data continuity. Physical phones/controllers remain NOT TESTED unless actually used.

## Verification work completed before final integration

These are separately scoped results, not a claim that the final game build has passed every flow:

- Project skill packaging: **PASS**, 16 Markdown files and 16 local reference links; `build/m1-skill-validation.json` records the machine-readable result.
- Browser/native Python drivers: **PASS** compilation with `python3 -m py_compile`. Compilation alone does not exercise gameplay.
- Android passive campaign diagnostics: **PASS**, Godot4.6.3 `--check-only` on `scripts/campaign_native_diagnostics.gd`.
- Android two-finger injector: **PASS**, Java8-target bytecode compilation with the JDK21 compiler against API35 `android.jar`. The test jar was read from the Sable Android platform mirror; SHA-256 `4566663c3876e022b4fa4ced8c8697c4ab1688267f090114fd92d027b32e619b`. This proves source/API compatibility, not a successful emulator gesture. No physical phone or physical gamepad was tested by this step.
- Localization/registration engine suite: **PASS**, 35 checks after updating active TR/EN and four-character contracts. The old six-row source-sheet registration checks remain explicit archive checks.
- Archived campaign-art engine suite: **PASS**, 204 checks. New M1 body art has a separate current-runtime suite; archived art passing does not prove the new runtime art.

The ordinary browser drivers now traverse both real fork geometries without route buttons, and require a visible bag item plus actual pickup contact before a rescued NPC reward is recorded. They contain no world setters, save injection, teleportation or invulnerability. Their final execution status belongs in the integration report after a fresh web export. Virtual browser gamepad events, emulated browser touch and native Android ADB touch must remain distinctly labeled.

During integration, the retained layout checks detected genuine 200%-text character-card overflow and a 453px heading rectangle whose measured text minimum was only35px. These were sent to the presentation owner for a source fix; assertions were not removed to make the result pass. Simultaneous weapon calibration invalidated an in-flight armed-muzzle run; that partial log is diagnostic evidence, not a reliable failure count for a frozen build. The final run must occur after the weapon texture/socket API is frozen.

**Layout recheck after the actual source fix: PASS.** `aionia`476 checks and `charge_roll_ui`2522 checks passed in Godot4.6.3. The heading now receives its real width before it enters the tree; its height is36px. Oversized wide-font landscape rosters use actual two-card pages. All previous viewport/card overlap assertions remain; the additional pager checks run rather than skipping the affected characters.

**Frozen held-weapon recheck: PASS**, 2925 actual pose/muzzle checks. The suite uses the final canonical held texture and its registered source pixels, independently transforms the drawn barrel into world space, checks actual projectile origins, tests all four current heroes across eight aim directions, idle/movement/air/crouch states, and verifies animated/static renderer frames. All eleven held weapon variants have opaque grip and muzzle pixels with matching real canvas dimensions. Grounded shots that would enter supporting terrain stay horizontal without detaching the gun from the hand; airborne eight-direction shots retain their requested direction. The earlier in-flight failure log was superseded by this frozen-source run.

The optional ordinary-play browser profile now records actual Godot process/physics frame-counter deltas separately from browser `requestAnimationFrame` intervals. A browser paint interval is not reported as a measured engine frame rate. The metadata remains read-only.

**Last-shot and restart regression recheck: PASS**, the armed suite now contains3206 checks. Forty additional scenarios exercise the actual final special round for all ten special weapons in idle, walking, airborne and crouch-moving states. They require the spent special gun to remain visible through its real shot flash, verify that shot's drawn barrel, advance normal simulation until expiry, then fire the actual fallback pistol. A real new-run test exposed a stale flash/latch; the explicit begin/retry reset fixed it. The last-shot presentation latch is absent from checkpoint inventory.
