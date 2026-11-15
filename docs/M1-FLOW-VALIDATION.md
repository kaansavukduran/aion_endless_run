# Mission 1 flow validation

Recorded **2026-11-15 13:09 Europe/Istanbul**. The checkout is `feat/mission1-flow`, based on commit `4864b09ce7efea0d2c1b4eaead8703b9cb465b0e`. The inspected working project declares **0.26.0** and runs with **Godot 4.6.3 stable**. The changes described here are working-tree changes above that baseline; this document does not identify them as a clean copy of the baseline commit or as a published deployment.

## Physical route contract

Mission 1 retains its three destination routes and their existing convergence. Both junctions now run ordinary movement, collision, combat and pickup simulation. They do not open a route menu, stop for a text choice, or require a hidden confirmation.

| Playable junction | Upper exit | Lower exit |
| --- | --- | --- |
| Fener Kavşağı / Lantern Junction | Canopy, then the second junction | Water |
| Asma Geçit / Hanging Passage | Terrace | Roots |

Each junction spans 1,800 world pixels. Three actual one-way decks provide steps at Y−65, Y−130 and Y−195. The lower collision floor starts at X650 and descends to Y90. Destination contact requires grounded feet at X1480 or later on the corresponding support. Flying across that X coordinate does not silently select a route. All four current heroes can climb the steps with their existing jump rules.

Down alone crawls. Down + Jump drops through a one-way deck, so a player can change lanes before reaching an exit. Moving backward into the ninety-pixel ledge is blocked until the character jumps high enough to climb it; the generic landing solver cannot teleport a character or vehicle up the step. The diving shell uses the same contact-foot offset for route contact, grounded physics and the lower camera.

The wooden deck caps, support posts, lanterns, fruit trails and two exit flags meet their real support coordinates. The deck crossing X650 computes each post's individual support height. The former single flag at Y0 is not drawn over the lower channel. These structures reuse the project's terrain, forest/garden backgrounds and existing lantern art; they are traversable route scenery rather than a new decorative choice screen. The lower camera follows the real descent, keeping the portrait actor above the controls. Representative desktop and portrait images were visually checked for those relationships.

Implementation: [`campaign_routes.gd`](../scripts/campaign_routes.gd), its narrow world/view/game hooks, and [`PHYSICAL-ROUTES.md`](PHYSICAL-ROUTES.md).

## Section handoffs

The existing automatic section fade is preserved: 0.36 seconds normally and 0.10 seconds with reduced motion. Corridor and route exits load their destination without a Next button. Mission introduction, boss narration and the final outro keep their separate story beats; they are not route-choice substitutes.

The transition freezes while the application is inactive. Held input is canceled at transition entry, destination loading and completion. New presses during either fade half cannot remain cached and fire or jump when the next encounter opens. Live weapon/ammunition, score, damaged vehicle state, route history, destination checkpoint and unclaimed bag gifts are preserved. Passive `travel_active` observations include the fade-in half, during which the loaded world already reports `playing` but controls remain temporarily unavailable.

## Local evidence

These are real local engine runs, not CI results. Final logs were checked for script/parse errors as well as their assertion totals.

| Verification | Result | Actual task-local receipt |
| --- | --- | --- |
| Route physics and actual Game handoffs | **138 checks, 0 failures** | `/workspace/work/routes-ledge-final.log` |
| Campaign UI layout, controller event dispatch and touch handlers | **991 checks, 0 failures** | `/workspace/work/routes-ui-stable-final.log` |
| Campaign presentation and localized layouts | **504 checks, 0 failures** | `/workspace/work/routes-presentation-stable.log` |
| Native route rendering | **8 captures, 0 failures** | `/workspace/work/routes-render-final.log` |

The route suite uses real move/jump/drop/interact model actions in an explicitly isolated geometry fixture. It covers both exits at both junctions, reachability for every current hero, actual floor contact, camera support, route checkpoint restoration, no route buttons, and vehicle exit/reboarding on raised and lowered decks. Its handoff cases call the actual Game `_process` loop across five corridor links and both lower junction exits, without calling `finish_travel` directly or activating a menu button. They check bounded fade time, reduced motion, focus interruption, canceled held sources, vehicle HP, inventory and saved unclaimed-gift state.

The ledge and diving-shell tests first reproduced four failing assertions in `/workspace/work/routes-ledge-before.log`; the corrected run passes all 138. The UI suite explicitly clears the saved checkpoint only in its first-visit fixture, so a prior test run's valid Continue action cannot be confused with the tutorial's first-run action. The 991 total includes the reused user-directory Continue layout; the fresh-directory earlier run had 967 checks. Both counts describe the same responsive matrix with different valid save-dependent actions.

The eight PNGs exist under `/workspace/work/routes-render-final-images/`: both junctions × both lanes × **1152×648 desktop** and **393×873 portrait**. Their dimensions and nonempty files were checked. The captures use a real native X11/OpenGL compatibility renderer with llvmpipe and actual game terrain/sprites. They are authored scene fixtures positioned to inspect the routes, not screenshots taken during a normal-entry playthrough. They were captured before the later held-weapon visual refinement; they establish route geometry/camera composition, not approval of every final weapon cel.

The task-local receipts and images above are workspace artifacts, not invented repository, Drive, release or deployment links. Their retention/export is handled by the overall delivery.

## Existing CI render entry points, executed locally

The repository's two existing native render scripts were also brought forward to the current four-hero/body-source contract. This is a local execution of those entry points, **not a claim that GitHub Actions ran successfully**.

| Entry point | Local result | Actual output |
| --- | --- | --- |
| `tests/render_campaign_review.gd` | **654 checks, 0 failures** | `/workspace/work/campaign-review-m1-final.log`; **47 PNGs** and **144 rows** in `/workspace/work/campaign-review-m1-final/fixtures.json` |
| `tests/render_campaign_expansion.gd` | **226 checks, 0 failures** | `/workspace/work/campaign-expansion-m1-final.log`; **44 PNGs** in `/workspace/work/campaign-expansion-m1-final/` |

The old review genuinely reproduced 24 obsolete-source failures across its 72 current-roster checks (`/workspace/work/campaign-review-before.log`). The replacement retains real viewport pixel capture and physical-anchor checks, then verifies the actual renderer's registered hero/source row/cel for four identities × six clips × six cels. Clips are walk, idle fire, air fire, crouch walk, crouch fire and melee; melee reuses its actual registered body clip with the live hand overlay. The 24 diagnostic strips are 1080×160. A pink guide marks the actor root; an air root does not mean ground contact. Captures also include both lanes at each physical junction, all three destination routes, mounted sheep followers, companion powers, bosses, rabbit charging/high jumps and both mobile orientations. Files use `<hero>-<clip>-cycle.png`, `fork_one-{upper,lower}.png`, `fork_two-{upper,lower}.png` and the named region/mobile views.

The expansion fixture uses the real attack action to start each contextual cut, advances through its timing, approaches for actual NPC contact, verifies a physical unclaimed bag drop, then walks into it before checking the reward claim. Each current hero has `-knife.png` (a seven-cel 1680×200 strip), `-thanks.png`, `-gift.png` and `-gift-collected.png`. Each of water, terrace and roots also records `-vehicle-entry.png`, waits for the real entry transition to complete, checks mounted state/three HP, and captures the mounted view plus `-vehicle-aim-left.png`. It retains guardian, biome, boss-phase and rotated mobile views.

These runs used DISPLAY `:103`, isolated test-user data, X11/OpenGL compatibility rendering and llvmpipe. PNG dimensions and nonempty files were checked. They were rerun after the later held-weapon refinement and HUD-avatar correction. Native visual review found that the former `gun-run` HUD thumbnail still showed the old Emre costume for Ayça; the HUD owner switched it to the same current M1 idle body, and the corrected `rabbit-gift.png` was visually checked. The original finding image remains at `/workspace/work/campaign-expansion-before-hud-avatar.png`.

## Limits and integration boundary

This scoped evidence does **not** certify a full Mission 1 combat playthrough, all three normal-entry browser routes, physical-phone touch behavior, a physical Xbox/PlayStation controller, device performance, or Vercel/GitHub Pages publication. Headless UI input tests exercise the real handlers using engine input events; that is distinct from hardware testing. Normal-entry browser and device results belong in the overall validation report once those separate runs complete.

An independent source review checked the current Mission 1 roster/body/weapon attachment, crouch and aim, vehicle support/carry, bag-drop persistence, companion helpers and route flow changes. It found the ledge/contact bugs documented above and no additional confirmed blocking flow defect in the reviewed diff. Source review and generated art registration do not substitute for visual approval or runtime acceptance.

No private Google Docs or conversation text is reproduced here.
