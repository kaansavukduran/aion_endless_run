# Recurring game regression gates

These gates apply only to the changed game surface and its approved rules. They supplement, rather than replace, the original UI, behavior, sprite and game checks.

## 1. Authored facing is distinct from world facing

- Record the native facing of each atlas row or action clip, including mixed-source enemies, companions, freed NPCs and vehicles. Inspect the actual drawing; a row name or a world sign is not evidence of the drawing's orientation.
- Derive a texture mirror from world intent and authored source facing. Do not interpret a world direction of -1 as an unconditional instruction to flip every texture. Preserve camera and physics coordinates.
- Exercise left/right approach, stopped aim, attack, hurt and defeat. Test crossing to the other side of a target. For a roaming NPC, compare the visible nose/face with actual world velocity; require an explicit intentional-backpedal contract before accepting backward walking.
- Inspect both directions in the real renderer at game scale, with a visible target and fixed camera. Pair semantic direction checks with actual source pixels or an inspected rendered frame. A unit test that repeats the same mirror formula can pass while the wrong source row is used.

## 2. One anatomical scale across action states

- Calibrate each character from a neutral approved body, using meaningful head/skull and torso landmarks. Keep the same source-to-world scale across idle, walk, jump, falling, landing, crouch, attack and held-weapon variants.
- Do not normalize a whole texture or alpha bounding box independently for each pose. Weapons, tails, ears, hair, skirts, wings, muzzle flashes and particles may change bounds without changing anatomical size.
- Crouching legitimately lowers total body height through bent joints and posture. It must not shrink the skull, stretch the torso, flatten the whole image or grow the actor when aiming down.
- Record actor world origin, face landmark, feet/support contact, actual scale, source row/frame and camera transform through every loop and transition. Keep intended natural body movement; do not hide registration defects by moving the physics root every frame or freezing animation.
- Include weapon equipped/unequipped and vehicle entry/exit in the matrix when relevant. Riders, companions and foreground masks must share the real support/facing contract. Old assets and identity references remain archived when an explicitly approved variant replaces a playable design.

## 3. Movement and fire must work together

- Use the real fire action while stationary, moving left/right, ascending, descending and crouch-moving. Exercise the same states through keyboard/mouse, touch and gamepad where supported. Verify actual shot count, real damage/collision, animation and muzzle, rather than only a pressed state or sound.
- Cover eight authored aim directions when supported, and transitions between them. A held directional keypose is not a complete animated run or jump cycle. Do not replace walking physics with a stationary full-body aiming picture and call it walking fire.
- Resolve the muzzle from the actual selected pose/attachment and mirror. Check the first shot, loop seam and static/reduced-motion mode. Compare the projectile origin with the visible barrel pixel at game scale, including crouched and airborne firing.
- If a vehicle promises circular analog aim, test non-cardinal/non-45-degree input angles. An eight-way body or icon atlas must not quantize the actual analog aim vector. Keep the barrel's real pivot, scale, direction and projectile origin aligned.
- When crouching is supported, verify posture, crawl speed, lowered collision/hit center, firing and standing clearance through the common action path. Hold/release/cancel and pause/rotation must not leave it stuck.

## 4. Physical navigation, pickups and limited effects

- Read the product contract before choosing a route UI. When gameplay must remain continuous, a text/modal choice is not an implementation of a physical fork. Navigate every real upper/lower path using ordinary movement, jump, drop or interaction. Verify all currently playable characters can reach and leave the intended branch.
- A reward animation, timer or toast does not prove a collectible was picked up. When the contract requires a world item, verify its visible spawn, support/landing, contact, applied effect and one-time persistent claim. Check no-contact, departure, death/retry and reload without duplication.
- For seeking deployables, test an available target, target death, missing target, unreachable target and hard expiry. Trace both damage and visual removal. A still mine is not a walking seeker.
- Limited assists require actual use counters and damage events. Test that the effect performs its permitted number of attacks, stops afterwards, and cannot be replayed by reload or duplicate input when the contract forbids it.
- Vehicle health must come from the real model maximum. Test hits, destruction/ejection, repair, HUD maximum and old-save clamping together. Do not merely change the displayed denominator.
- When a route adds nonzero floors or raised surfaces, audit every support consumer: standing/jumping, grounded checks, mount entry/exit targets, parked hull drawing, passengers, NPC roaming/departure, dropped items, projectiles, collisions and camera clearance. A correct player floor with a hardcoded vehicle Y=0 is still broken. Test exit and re-entry on the actual upper and lower surfaces.
- If a state identifier changes from a dialog into a playable location, audit all copy consumers too: HUD title, controls, help, accessibility summary, Continue/checkpoint and result labels. Old question text must not remain as the location name.
- Numerical values belong to the project's current contract. Do not apply one game's health, expiry or attack count to another product.

## 5. Acceptance evidence and durable handoff

- Build a state matrix before claiming complete coverage. Keep source/model tests, authored render fixtures, ordinary-input play, native emulator and physical-device evidence distinct.
- Capture an ordinary first interaction after intro/demo/menu reveal. Wait for the engine's actual layout acknowledgment; browser animation frames do not prove that a hidden Godot container has sorted. Record the target rectangle and first resulting state. Preserve a missed first action before any retry.
- A route/model/debug setter, direct damage helper, removed enemy, teleport or invulnerability can help isolate a defect but cannot stand in for normal-input completion.
- Keep original failures and changed expectations. Update fixtures only for a documented new user decision or a demonstrated incorrect precondition; do not weaken the outcome assertion to make a release green.
- Exercise transition fades through both halves. A destination may already be loaded while input is intentionally suppressed; release/cancel held controls and verify a new ordinary press works after the entire transition, without a stale cached key or delayed action.
- Keep engine frame/physics rates, browser paint (`requestAnimationFrame`) intervals and wall-clock duration distinct. A fast browser paint loop does not prove the game simulation or renderer advances at that rate. State the sampling window, renderer and device/emulator scope.
- Record source commit, artifact/build ID, viewport, locale, scale, input, selected character, action row/frame, counters and before/after outcome. Do not relabel earlier candidate results as final-package results.
- Where skill installation is involved, distinguish a project-local package from an updated cloud-installed skill. Check frontmatter and every relative reference. Report unavailable write access honestly; a guidance file cannot guarantee absence of future defects.


- When replacing a locomotion bank, audit damage/elemental/story states, HUD portraits, previews and companions independently. A correct new hero body must not silently erase an existing defeat clip or revive a retired visual identity in an avatar.
- Test the final round of a limited-ammunition weapon: logical inventory may fall back immediately, while the visible fired weapon and its true muzzle must stay coherent until that shot ends. Verify first, last and next shots, not just a manually selected static pose.
- Refreshing a companion must not delete already released projectiles. A lifetime boundary must stop new attacks even while existing projectiles finish. Crossing a physical section must not accidentally refresh an effect lifetime.
- Exercise physical ledges in both directions on foot and mounted; a floor-height change must not teleport an actor onto a higher ledge. Use the same foot offset for collision, route selection, camera and any vehicle dive.

- Before a bounded posture, movement or firing check, prove the actor is alive and the action is available. Preserve a preceding death as evidence; use the ordinary user-facing checkpoint/retry action to establish the next test's precondition. Do not expect a dead actor to crouch, and do not substitute immunity, teleportation or a state setter.
- After native orientation or display-size restoration, wait for a fresh engine UI record with the expected orientation and physical target bounds before tapping. An ADB/window-manager command returning is not an engine layout acknowledgment. Log the exact chosen target, orientation and display bounds before the first tap; preserve stale-layout rejections and the original failure.

- A cold-start page named main, or controls behind an opening overlay, does not prove the menu is actionable. Observe the real opening phase/Skip control, then require the overlay to disappear and the actual main actions to be ready before capturing a main-menu screenshot or tapping through it. Keep the original early frame; do not weaken image thresholds to accept the intentionally sparse opening as the interactive game.
- After an in-game menu tap, wait for a new engine UI generation and its readiness acknowledgment before branching on the destination menu or issuing the next action. A fixed wall-clock delay can leave stale briefing metadata and skip a required help screen, even when the real first tap worked.
