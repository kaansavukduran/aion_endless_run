# Mission 1 project contract

Scope: Aion Endless Run at this repository only. This file records the explicit user request of 15 November 2026 (Europe/Istanbul). It is an acceptance contract, not a statement that the implementation or tests already pass. Source implementation, exact commit and results belong in the task's final report. Do not copy these game-specific values into unrelated projects.

## Current requested behavior

| Area | Requested acceptance |
| --- | --- |
| Playable roster | Mission 1: Aion, Kutsanmış, Ayça, Eren, Armadillo and Frog, preserving original four save keys/order. Classic Endless retains the original four; never silently map a new hero to Aion. Retired playable owl/Ömer and wolf/Melun remain limited assist power-ups. Existing original artwork and old save data remain preserved. |
| Ayça variant | Game-local female rabbit variant of the former playable Emre role, energetic feminine silhouette and skirt. Keep Eren visually distinct. The internal legacy rabbit save key may be retained with an explicit display/art migration. Shared universe references are not silently rewritten. |
| Hero art | Preserve approved colors, silhouette, badges and identity, especially Aion's pink axolotl, blue eyes/gill tips, white lab coat and DNA tail. High-quality distinct poses at a constant anatomical scale. |
| Fire/action matrix | Standing fire, walking fire, airborne fire and crouch-moving fire must genuinely work. Eight-way artwork must not alter anatomical proportions or freeze required locomotion. |
| Crouch | Down/S and the established equivalent gamepad/touch down input permit low movement and fire. This is posture, not a stretched body or a ball animation. |
| Physical route forks | Both Mission 1 route splits are traversable upper/lower geometry selected by movement. No text route-choice menu during gameplay. Three destination routes and real route/save state remain coherent. |
| Owl assist | Feather pickup summons the owl to drop rocks from above for exactly two area attacks. Owl is no longer a playable menu option. |
| Wolf assist | Wolf pickup summons the wolf to run up and bite enemies exactly twice. Wolf is no longer a playable menu option. |
| Vehicles | Three actual HP; health UI, damage, repair, destruction/ejection and old-save clamping agree. Circular aiming uses continuous analog directions where available. Selected rider remains inside its actual vehicle. |
| Spider mine | The deployed mine visibly becomes a walking spider seeking an enemy and exploding on contact. If it finds no enemy, it self-detonates no later than five seconds after deployment. |
| Rescued NPC | Freed NPC walks in the direction it visibly faces. Thank-you/bag handoff produces a visible world power-up. Only player contact collects it and applies the persistent one-time reward. |
| Crow | Reduce the forward lunge component by ten percent from the recorded baseline, rather than reducing unrelated spawn counts or every enemy's speed. |
| Language | Only Türkçe and English in the active game. Existing unsupported saved languages migrate deliberately; do not corrupt records or character progress. |
| Presentation | Original cohesive arcade entry screen through Mission 1 completion, using the game's own art. Reference quality does not authorize copying another game's assets or graphics. |

## Evidence to retain

- Reproduce reported animation/proportion/fire problems before assigning a cause. Compare actual landmark/scale/muzzle observations, not only texture dimensions.
- Test all six Mission 1 identities (and the separate original-four Endless contract), every relevant action and aim direction, both physical route forks and all resulting destinations.
- Use normal keyboard, touch and virtual gamepad paths for real play. Mark physical devices/controllers separately as NOT TESTED unless actually used.
- Preserve old saved owl/wolf selections, language values, rewards and vehicle HP in migration fixtures. Verify the chosen compatible fallback and no duplicate reward on retry/resume.
- Record UI/menu, gameplay, boss, victory/result and return/continue outcomes with build-specific evidence. No global “bug-free” claim.


## Mission 1 animation regression gates

- Opposed travel must use actual backstep art while preserving pointer/stick aim; grounded crouch does not steal pointer aim. Do not reverse a forward clip to label it new backward art.
- Throw: one simulation release, one charge, measured visible hand, same held/flying prop scale; no gun in the open follow-through hand. Pause freezes, focus/death cancel unspent windup, retry clears transient cooldown.
- Every crouch/throw/hurt/death pose must fit the actual low ceiling at one fixed hero scale. Test opaque silhouette against ceiling, not only physics root. Never hide overlap with clipping or enlarge a passage silently.
- Enemy recovery starts after its active movement and remains visible/targetable. Timed beams fire once when the warning crosses zero; smoke must not obscure critical warning lanes.
- Original sources and game-local candidate adaptations remain separately attributed; user art acceptance is not inferred from a passing model test.
