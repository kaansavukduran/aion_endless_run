# Mission 1 physical junctions

Mission 1's route decisions are physical spaces. `fork_one` follows the quay; `fork_two` follows the canopy. Neither opens a choice dialog or stops the world to select text. The former route buttons and their unused thumbnail cache were removed.

| Junction | Upper exit | Lower exit |
| --- | --- | --- |
| Lantern Junction / Fener Kavşağı | Canopy | Water |
| Hanging Passage / Asma Geçit | Terrace | Roots |

Move normally with the existing keyboard, fixed joystick or gamepad. Jump onto the wooden steps to take the upper bridge, or continue below into the channel. Down alone crawls. Down + Jump drops through a one-way platform, allowing a player to change lanes before reaching an exit. Both rabbit identities can use their existing charged leap. The exit resolves only when the actor's actual feet touch the destination support, not while flying over it.

Each junction is 1,800 world pixels wide. Entry floor is Y0, the lower channel begins at X650 and rests at Y90, and the upper route uses raised surfaces at −65, −130 and −195. Exit contact begins at X1480. The material top caps, posts, props, enemies and loot use the same support coordinates as collision. Walking backward into the lower ledge is blocked until the actor jumps high enough to climb it; the landing solver cannot snap actors or vehicles up ninety pixels. Shell dive contact uses the same foot offset as the vehicle physics. The lower camera tracks up to the real 90-pixel descent so a portrait player is not hidden behind the joystick. The two junctions reuse approved forest and hanging-garden backgrounds and existing, different sentry types. They add no new lore or third-party assets.

Route completion records the same three destinations and converges at the relay/arena as before. Junction checkpoints restore into live gameplay. The old `choose_route` model method remains for old isolated callers; no gameplay UI calls it.

All ordinary section exits continue through the existing automatic 0.36-second fade; no Next button is required. Reduced motion shortens that fade to 0.10 seconds. A focus interruption freezes the transition, and input sources are canceled at entry, destination loading and completion, so a press during the fade cannot leak into the next encounter. Live inventory, vehicle damage, route history and unclaimed bag gifts survive the handoff. Mission introduction, boss narration and the final outro retain their separate story beats.

Verification is separated by scope. `tests/test_campaign_routes.gd` uses real move/jump/drop/interact model actions in a deliberately isolated geometry fixture; it is not a claim of a full combat playthrough. It covers both exits at both forks, all current playable heroes, support-aware camera, checkpoint restoration, no route buttons and vehicle exit/reboarding on raised/lowered support. `tests/render_campaign_routes.gd` captures eight authored native fixtures across desktop and portrait, using actual terrain and sprite rendering. Normal-entry browser playthroughs are verified separately by the main delivery report.

The route regression also runs the actual Game process across corridor and fork exits without calling `finish_travel` or pressing a menu control. It checks transition duration, reduced motion, focus interruption, held-input cleanup, damaged vehicle carry, inventory and persistent unclaimed-gift/checkpoint state. The fixture starts near an exit to isolate that handoff; it does not stand in for playing the preceding combat section.
