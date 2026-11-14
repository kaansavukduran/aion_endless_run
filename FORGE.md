# Ground material update · scope and handoff

Baseline clean main f2142f9. Live AIONIA1.7/regression1.1 read. Replace game.gd flat road/regular dashes with cached authored pixel-material strips in terrain_view.gd; six biome palettes, fixed real ground, preserved pits/props/characters/input/saves.146 terrain coverage/alpha/grid/RNG tests;1136 focused source checks PASS;40 real-render fixture checks PASS including50% blend/pit/rotation.88 normal browser assertions pass on candidateac5c460bbdcc83eb; final change only corrects double-compositing the biome fill. Source runtime and release assets otherwise preserved. Production verification is recorded in docs/evidence-terrain. Existing0.22.0 packages are not overwritten.

# 0.22.0 · Model-faithful visual and ability revision

Published0.22.0: final source CI2a782f5/run43578174636 passes all five gates;21 suites/12178 checks,265 browser assertions and15 native Android inputs. Tag87cb29e and publication43579686335 attempt2 preserve the verified runtime. All11 public assets match hashes; downloaded stable APK v2/v3 signer/code26, Mac universal ZIP and19-file offline archive verified. First publication attempt failed on a list response missing the newly created draft, before uploads. Main now reads the create response directly. Evidence: docs/evidence-v0220/verification.json. Physical devices remain NOT TESTED.

Six new original AI-assisted sheets preserve model identity: upright biped sheep, original Aion gills/coat/DNA-tail, low shoulder rotations, steady owl glide/flaps, Eren charge/leap, crow/gnome material detail and18 distinct collectibles.56 prior PNGs remain byte-identical. New sources are isolated by actual alpha spans with anatomical anchors and one calibrated scale per source; physical actors are not shifted to mask frame errors.

Owl gets three upward airborne flaps on fresh Jump presses, held glide remains and landing refills. Eren now shares hold/release charge with Emre, without changing their distinct art. Branded loader fills/percent/ellipsis are uniformly strawberry red. Flora uses opaque connected roots and the actual support plane. Existing weapons, bosses/story, saves, gamepad and split-touch layout remain.

[Evidence and current delivery scope](docs/evidence-v0220/README.md).21 strict Godot suites; real exported controls plus independent rendered-face RGB checks. New art is technically reviewed; final owner art approval is separate. Older records follow without losing their historical scope.

## 0.21.0 · Hikâyeli boss, gerçek ayak teması

Kullanıcının son kararı, önceki tek takla+baskıda çömelme davranışını değiştirir: basılı giriş altı alçak omuz taklası karesini döndürür. Boss aralığı5; sarılmalar10 olarak kalır. Üç farklı boss konuşması, altı kahramanın yüzüne ellerini götürdüğü çizimler, yardımcının kırmızı tabanca teslimi, Devam/Atla, duraklatma ve yön değiştirme desteklenir. Ara sahne normal fizik/koşu/seviye sayaçlarını durdurur. Kaynak kenarına değen ilk nötr kuyruk pozu seçilmez; eksiksiz ikinci nötr kullanılır. Yeni kaynak paftada42 çizim vardır; bunların hepsi ayrı canlı oynatma karesi gibi sayılmaz.

Ayak sorununun kanıtı: eski yerdeki paftada yüzün Y konumunu da sabitlemek0,6–9,7 dünya pikseline varan boşluklar bırakıyordu. X aynı yüz probuna bağlı kalır; yerde Y opak ayak sınırına bağlandı. Havada/süzülmede gövde sabitleme korunur. Namlu konumu da gerçek seçilen kareye bağlanır. Önceki55 PNG değiştirilmez. Skor bandı46px,200% yazıda76px; okunabilir font ve Pause alanı korunur. [Kanıt ve test kapsamı](docs/evidence-v0210/README.md).

## 0.20.0 · Altı yeni pixel-art kahraman

Altı yeni pafta/396 kaynak kare, özgün karakter kimlikleri, daha belirgin malzeme gölgeleri ve piksel kümeleri. Tam bağlı siluet kesimi, bütün-yüz kaydı, tek karakter ölçeği, alçak tek omuz taklası, ayrı Emre şarjı, Ömer uçuşu, Melun dört ayak deparı ve dar silah eki. Son72 element pozu da sabitlendi; eski49 PNG byte olarak korunur.

[Doğrulama](docs/evidence-v0200/README.md):19 temiz CI paketi/10970 kontrol,166 tarayıcı,11 native Android giriş,36 açık durum render fixture'ı. Dokuz paket/iki makbuz yayımlandı ve kamu özetleri doğrulandı. Güncel Pages çalışır; Vercel son yamada günlük kota nedeniyle BLOCKED. Fiziksel Poco/iPhone/kol NOT TESTED.

# Published delivery · 0.19.0

Releasev0.19.0 is public with9 platform packages and2 receipts. Exact artifacts from verified run43480686993 (source4fea30b), documentation tagf2b7f79 and stable APK application537391a are recorded separately. All11 server asset digests verified before publication; actual public APK bytes/signer/code23 and Mac ZIP CRC/universal CPUs verified afterward. Pages and Vercel actual final build IDs/scopes are in docs/evidence-v0190/verification.json. Runtime unchanged after the final HUD fix.

Managed direct uploads.github.com returned401. The scoped GitHub-owned publisher37b396d /run43488404252 solved delivery using existing repository authorization and GITHUB_TOKEN, not another local credential. Manual/repository dispatch requires a successful main Test and package run, all5 platform gates, matching version and byte-identical runtime source; it restores only the matching stable APK, uploads the existing draft, validates every server digest and then publishes. Do not overwrite a published release or delete release-assets/v0.19.0, which is needed for reproducing the signed APK. No signing keys were committed. Source/tests/assets/scene/loader contents were unchanged by this publication workflow.

# Delivery update · 0.19.0 final portrait HUD

Application537391a, verified CI4fea30b /43480686993, Pages43482053479.9,556 source checks; final17 DPR,40 live and3 actual-release-archive offline checks;11 native Android inputs. Original47 PNGs unchanged. Native touch fonts have a24 minimum: long portrait ability instructions exceeded the slot. The slot now shows live one-line jump count/flock/glide/boost/charge with full accessible/tutorial guidance, without shrinking text or covering Jump. All11 locales and active states have actual shaped bounds checks. The language code control has its own minimum and covers no roster card at200%.

Reproduce rapid trusted DPR3 swipes with browser_swipe_quality.py; avoid converting a fast gesture into a long press by waiting for separate remote acknowledgements. The126-check pose tour predates only the final HUD patch; source hashes/functions prove every animation/input path unchanged. Godot strict runner rejects exit0 after SCRIPT ERROR. Delivery reuses exact fully successful CI artifacts rather than rebuilding identical runtime sources for documentation-only tags. Record artifact source commit separately from release tag/documentation commit. APK stable signer/code23 retained; no private signing keys in source or staging.

# Current handoff · 0.19.0 registration, shoulder rolls and Eren

Baseline main54a8136544bf1c741fa320915dbbf6826b84c444 was clean and up to date. Godot4.6.3 retained. Fragaria Unslop applied to this requested game/UI pass. Live owner standardv1.7 and reference/regression indices were read; this is scoped implementation and testing, not blanket certification. The linked ChatGPT thread was not readable because read_thread is unavailable. A macro definition alone does not activate k44/Aionlaştır/dynamic aionia. Private standard/reference contents are not copied wholesale into this public repo.

Root cause verified in original pixels: Aion canonical gun-fire frame2 marked a lower blue feature as its eye (~28.5 source-pixel horizontal error); Wolf fire frame3 had a similar turquoise-feature registration error. Old eye_world tests reused that bad marker and therefore could not catch it. New full nose/cheek/face template registration fixes metadata, keeps one source pixel phase and physically unchanged actor/scale. Shared gun-run neutral reference aligns run/fire seams; wing/tail motion remains. Low-confidence blink comparisons are constrained to reviewed local anatomy to avoid tail/other-eye matches. No physics wobble workaround, no retouched prior PNG.

New shoulder atlas60 cells; Eren own79 cells. Omuz roll enters once, turns forward once, settles low if held, and recovers on release. Emre charge/release1.2s and own clothing retained. Eren is independent, long-eared, eyelashed, freckled, dark teal jacket/striped tie; standard immediate single jump because owner specified no extra ability. Long ears are not squashed to force an arbitrary roll-height ratio.

Unlimited Fire removes inventory/reload code, keeps0.32cadence/0.30animation/pending muzzle timing/damage/XP and saved mappings. Attack/X/J/R becomes an independent alternate source of shared Fire. No Reload control or magazine HUD remains. Passive browser ammo compatibility attributes are infinite/zero; there are no setters.

Main panel sizes to shaped content plus real theme margins; enlarged split main vertically centres it. Six cards and all3 actions remain visible with saved font/theme/preferences. Touch skin/hit mask is one exact symmetric cut-corner family, proportional icon and label, integer device-pixel grid including DPR3. Approved split input and alternate right-cluster stay; no joystick. All11 help texts match actual controls, Eren has its own card/name/hints.

Source runner now rejects Godot exit0 after SCRIPT ERROR, missing RESULT, FAIL lines or nonzero failure count. Independent source-pixel probes and actual six-hero browser inputs supplement the old iris tests. See docs/evidence-v0190 for concrete results and platform limits. Older notes below describe their historical versions, not current reload or roll behavior.

# Current handoff · 0.18.0 low rolls, charged Emre and fitted pages

Baseline mainc3b041f61480afc37c762f99ba0a6f7b364f92aa, clean. Godot4.6.3 retained. New macro definitions alone do not activate k44, Aionlaştır or dynamic aionia. Existing approved split touch,11 locales, dark/system-font defaults, stable APK signer,15-second levels, firearm5 rounds/1s reload, records and offline loader are preserved.

New60-pose low-somersault sheet keeps original46 PNGs. Dedicated low-roll alias precedes old Emre/canonical mappings. Enter crouch once, loop compact angles while held, recover on release; follower trail records roll remaining/held state at each spatial sample. No vertical squash or frame-dependent character scaling. New PNG remains unchanged; registration reads alpha only.

Emre charges while grounded and releases one jump:1.2s cap, impulse0.65–1.35×JUMP_SPEED plus existing power multipliers. No automatic launch at cap, no airborne recharge, no latent launch after cancel/pause/rotation. Multiple input sources commit only on the final valid release. Charge stance uses drawn crouch poses and the same original pistol overlay; emitted muzzle shares its14-unit lowered offset. Charge body height follows its drawn stance. Roll and damage cancel charge. Short phone hint and five small charge pips avoid an oversized progress bar.

Real Chrome CDP touchCancel exposed Godot mapping the cancelled touch to a normal release. A capture-phase DOM touchcancel callback clears input ownership first, so Emre never launches on cancellation. Do not also subscribe to pointercancel: Chrome emits compatibility pointercancel during valid long legacy-touch holds; doing so incorrectly cancels sheep rolls and rabbit charging. Verified with real browser touch start/end/cancel, not only synthetic Godot events.

Proven UI causes: settings/enlarged pages/language/tutorial instantiated ScrollContainers; hidden autowrapped Labels could expose one-pixel paragraph measurement until shaped. RunnerMenuPages forces Label.get_line_count before reading minimum size, pages actual controls and long paragraphs, reflows wide rows, pins results actions, retains focused option across option rebuilds, keeps range name/control together. Settings no longer force wheel use. Normal main geometry/approved preferences are unchanged. Avoid asynchronous RefCounted callbacks across scene shutdown; an initially observed exit crash was fixed by using the host Node's own deferred metadata refresh.

User explicitly authorized an additional GitHub Pages address after the Vercel daily quota blocked recent deployments. User then enabled Pages Source=GitHub Actions; API read confirmed workflow mode. A separate workflow deploys the exact successful main-run web output artifact after source, native Android and desktop gates. Keep Vercel and its origin-local records. Different origin has separate records; do not claim migration.

First remote CI run43349358325 correctly blocked publication: the host resolves the system font to the wider DejaVu Sans; at200% and960×540 logical view the fifth hero card and three languages overflowed. Reproduced locally with an explicit real DejaVu system font. Enlarged landscape now gives60% width to the roster and40% to wrapped main actions, and uses the Label's shaped line count for measured card height. The System language option shares the language grid, avoiding an extra tall row. Added both DejaVu Sans and Liberation Sans, both orientations and TR/EN at200% as explicit regression cases. No smaller text scale or font substitution hides the failure.

Final publication: main CI43350354438 and tag CI43351637933 success; source8,492 local/8,579 CI checks,89 final-candidate Chromium,18 actual Pages Firefox153/Chromium151,3 real subpath offline and11 offline Android ADB checks. Pages run43351182798 publishes2dc5e96fab077b9f at https://kaansavukduran.github.io/aion_endless_run/ . Public beta0.18.0 has9 packages, exact source tag295b008, appdc3bcf4, stable APK code22/SHA46e1e311733f5e5b58b3cbf3dcc2ab065a9d4422eb1b3661ab4ae3ba387821ca. Public APK bytes/signature/version and Mac ZIP CRC/x86_64+arm64 verified. Existing staging branch is retained for repeatable hash-only APK restore, no signing secrets.

Vercel did publish the first0.18.0 candidatec9ab407/c75d65b445ea55a7; the final wide-font fixdc3bcf4 hit its renewed daily quota. Recommend Pages for current UI; origin records remain separate. No paid plan or automatic retry was configured. Final live Chromium initially hit the diagnostic CDP100MiB transfer cap when base64-fulfilling91MB PCK; log proves capacity failure. A16MiB diagnostic range relay preserves original live bytes and loader SHA checks; no app change or TLS validation bypass. Firefox used the full verified response.

Local evidence and final platform/publication states: docs/evidence-v0180/. Verify real runtime before reporting a deploy as playable. Native iOS/Apple Developer ID remain owner-signing limitations; no physical phone/controller claim.

# Current handoff · 0.17.1 help and native screenshot correction

All11 secondary motion/gamepad/lightning explanations now describe15 active seconds and X/Square Reload;201 firearm/menu checks include22 assertions against help drift.16 source suites:5,720 checks.0.17.0 passed9 real ADB inputs, then failed the obsolete android-melee.png image gate; no release was published.0.17.1 checks actual fire/reload images. Stable-signed APK code21 derives from8d175d9; later changes only record release metadata/evidence. Current proof: docs/evidence-v0171/.

# Current handoff · 0.17.0 pistol and fitted menu

Started clean on main74c00e6632c5d7cf01c7cd9f92f34daaa43d1848, Godot4.6.3. No AGENTS files found. Main was fetched, not reset to the older prompt commit.

Proven: enlarged text previously made main a ScrollContainer; the reported light/200% combination reproduced overflow. Main now always fits its five portrait/name cards and three actions; 200% landscape uses a two-column split, portrait uses a compact two-column roster. Font size/theme are preserved. The previous language loader prioritized a saved override. The actual reason for the user's Italian preference cannot be recovered from a screenshot: a documented legacy-save fixture reproduces that state. A versioned one-time migration follows locale; new deliberate overrides persist. System language is selectable. Native OS locale is direct; browser Intl locale is the closest exposed system/browser setting, not privileged access to the OS.

All heroes always carry the existing faithful pistol, five rounds and one-active-second manual reload. No user input reaches melee. Existing internal contact-attack model tests remain historical coverage; current UI/input tests assert firearm/no-melee behavior. Left/right click/F and RB/RT fire; R/J, X/Square and separate touch Reload refill. Bullets travel straight; ordinary enemies use swept hit tests, existing XP and one-hit defeat. Lightning attaches to an emitted normal-run bullet. Reload freezes across pause/hug/boss intro. Running and boss combat share the magazine.

Preserve wolf four-legged gallop, owl calm glide and jump/roll/defeat poses. An isolated part from each hero's registered gun artwork overlays special mobility, never another hero's body. A real paused-wolf-pose regression found during this change was fixed. All45 pre-existing assets PNGs remain byte-identical; the additional original flora PNG has18 drawn poses and common root/scale registrations. Reduced motion keeps it still. No source PNG is retouched.

15 active seconds advance each level; no distance gate, background catch-up or boss/hug time. Long level/XP bars removed; boss HP and numeric level/XP remain. Proper names across11 languages are exactly Aion, Kutsanmış, Melun, Ömer, Emre. New translations and offline CJK glyphs added. Save records, stable APK signer, Firefox loader2, offline updates and split touch preference remain.

Tests and remaining platform limits: docs/evidence-v0170/. k44/Aionlaştır were not activated. Do not claim browser locale identifies OS when they differ, physical Poco tests, Apple distribution signing, or a background sync to Drive.

# Current handoff · 0.16.0 Aionverse orchard and Emre

Started clean on main d502658, Godot4.6.3. Verified actual cause: spawn_encounter appended one crystal at the same X/-112 altitude for every encounter including flying carriers. Normal collectible spawning now belongs to scripts/orchard.gd:3–5 mixed fruit per ribbon,650–1050 travel-unit gaps, ground-reachable-32..-40 Y, geometry clearance and revalidation against later hazards. Legacy gems counter/event/+25 score and fortune/magnet behavior remain for compatibility. Fragaria's rare cosmetic strawberry remains distinct. Six original scene panels render at uniform scale with mirrored edge repeats, shared travel/crossfade/day-night/weather and faster botanical foreground details.

Emre is the fifth hero, based on authorized Drive model reference1_gDPSpL7sQDdO791wWfx4zzZWQksbZPk. Two unchanged PNG atlases /144 actual poses; single common0.70 scale, registered near green iris/floor, isolated frames; measured weapon muzzle. Added bank aliases for runner-rabbit, punch/kick, roll, weapons and defeats; existing four hero aliases unchanged. Combat-versus-roll sentinel now uses FRIENDS.size(), avoiding treating the fifth attack as a roll. One stronger single jump(1.12 velocity multiplier), not Aion's double jump. Five-card short landscape menus stack portraits and place secondary actions side by side without reducing touch sizes.11 locales include name/help/fruits; offline OFL CJK subset expands while preserving previous glyphs. All41 pre-existing PNGs byte-identical. k44 and Aionlaştır were not activated by instruction definitions.

Tests/evidence: docs/evidence-v0160/. Preserve touch ownership/cancel behavior,11-language English fallback rule, save data, stable native signer, Godot4.6.3,20-second levels and verified Firefox loader2. GitHub remains the development source; no continuous Drive sync was established by this visual/gameplay task.

Delivery0.16.0: application932c3e7, release da37225, successful full native CI43329490987.9 public package digests match receipt; downloaded APK stable signer/hash and universal Mac ZIP validated. Production dpl_HaPifEMKqaGMZzqqP1jUtRbJLvmf READY, Firefox6 checks on build86324583a4955132;39 local browser checks and7 native Android input/layout checks. Actual normal-play video and screenshots distinguish seeded visual fixtures from unseeded gameplay. Physical phone/controller and native iOS distribution limits remain explicit in evidence-v0160.

# Current handoff · 0.15.1 visual polish

Started clean on main d8ae342ee9855f79e52b403a093476dd90118412, Godot4.6.3. The four 0.15 newcomers were drawn with coarse procedural primitives; replace only their rendering with 24 original AI-assisted drawn poses in woodland-creatures.png. register_creatures.py is read-only: transparent alpha spans, explicit near-iris regions, one scale/species, shared floors. Physics, HP, spawn randomness and hitboxes are unchanged. Existing 40 PNGs (heroes, crow/gnome, bosses and scenery) are byte-identical to the starting commit.

Touch rims now use a mirrored integral two-unit raster mask shared by rendering and hit testing. Six authored bitmap icons distinguish jump, melee, clockwise roll, boost, lightning and pistol. Cached rim/icon textures avoid per-frame tiny draw calls. Preserve the selected split layout, right-cluster option, ownership/cancellation, simultaneous inputs, labels, accessibility names, cooldown and disabled behavior. 152 new targeted checks join the existing suites. Evidence and real-play screenshots: docs/evidence-v0151/.

# Current handoff · 0.15.0

See docs/UPGRADE-0.15.0.md for the diagnosed causes, implemented changes, and preserved behavior. Final evidence is in docs/evidence-v0150/. Existing 40 PNGs are byte-identical to 2f15b5e. Languages now number eleven, with offline OFL fallback fonts.

Delivery0.15.1: applicationcfb1ca9, release9d15440, successful full CI43322478219, production dpl_EyW74pwkhprEwTZVZ9ch946HDnD9 READY. 3604 source checks +11 packaging tests +35 local browser checks +6 live Firefox checks +7 native Android checks. Nine public packages verified against receipt; actual downloaded stable APK signer/hash and universal Mac ZIP verified. Evidence distinguishes fixture scenes, normal play and unavailable physical-device checks.

# Current handoff · 0.13.0 runner UX

Start reference and actual starting main: 03fd1f4a400345847da7b0b471272ec75602a62a, clean working tree; Godot4.6.3. Preserve the verified Firefox loader2, offline caches/IndexedDB and existing native signer.

Hero PNG bytes are unchanged. register_canonical.py now excludes Aion far iris/gills, owl beak/chin/eyebrow and sheep halo/hooves from near-iris registration. Blink interpolation accounts for actual atlas gutters. The sheep's back-facing kick uses a reviewed wool/head-body center and common floor offset, not an invented visible eye. frame_bank.gd honors the explicit turn-body registration. Regenerate canonical before agility; the latter keeps reviewed near-iris search windows and shared scales. Dedicated clockwise rolls, all abilities and authored combat lunges remain.

RunnerPixelInterface builds compact warm pixel menus, with main/result scrolling eliminated and long settings still scrollable. RunnerTouchControls owns finger IDs, deferred world-tap/hold vs down-swipe resolution, move-out/cancel/release, common action dispatch and disabled-target consumption. Touch GUI tutorial buttons must retain their emulated mouse events; gameplay suppresses duplicates. Native sensor orientation and unrotated portrait layout replace forced landscape. UI and uniform world-camera transforms are separate; scene dimensions and safe-area input coordinates agree.

Levels use20 active normal simulation seconds, no distance gate or catch-up loop. Half mushroom candidates are emitted across wave boundaries with a seven-alive safety cap; 128 seeds/10seconds/400px per second:3340 legacy versus1634 new (48.92%). Ambient gnomes unchanged. Fragaria offers once after each hundred-level threshold's first eligible boss victory; practice excluded, no rewards of any kind, short independent banner. Full supplied prompt was truncated mid-rule; interpretation is disclosed in delivery documents, not invented as recovered chat history. Separate normal ChatGPT chats were not accessible.

Web splash uses a transparent owner-reference cutout, bundled Pixelify Sans and real PCK byte percentage, then indeterminate preparation; no fake timer. Actual manifest hashes and fixed virtual /aion.pck loading remain. Native/package verification and release/Drive readbacks are recorded after completion. tests/test_runner_ux.gd covers reviewed anatomical samples, timer, population, rare item and actual scene touch/damage/menu flows.

# Current handoff · 0.12.0 web loader hotfix

Poco X7 / Firefox report: native missing-PCK modal during web startup. Web loader revision2 validates the complete PCK byte count, GDPC header and SHA-256 before allocating the engine, retries bad responses, repairs only corrupt pack cache entries and preloads verified bytes at the fixed virtual path /aion.pck. Network filenames remain fingerprinted. A stale shell can recover once through aion-latest.json. Offline installation starts after game startup and validates files sequentially, reusing the verified PCK. Firefox activation probes modern clients rather than forcing navigation based only on a potentially stale Client.url. IndexedDB is never cleared.

Game code, character art, version0.12.0 and published native packages are unchanged. This is a web-only deployment. Five packaging contracts and real Chromium/Firefox packet-fault, touch, retry, cache-repair and offline tests are in tests/test_web_packaging.py and tests/browser_loader.py; PWA migration checks now wait for shell build identity even when game versions match. Evidence and test limits: docs/evidence-web-loader/README.md.

# Application handoff · 0.12.0

AGILITY-PROVENANCE overrides nullable aliases before canonical. Two new original unchanged PNGs /64 poses (8×4 each). Wolf rows0 four-legged gallop,1 bite,2 claw,3 sprint pounce bite; owl0 calm glide,1/2 forward wing swipes,3 flying beak. Only wolf/owl movement/combat replaced. Aion/sheep and other hero poses stay canonical. Registration explicitly selects the large near iris, not golden beak/feathers or wolf far eye; blinks interpolate landmarks. One scale per hero atlas. Review near-eye markers against source art; metadata alignment alone does not establish that the chosen landmark is anatomically correct.

Sprint attack posture snapshots on attack start, so releasing Shift mid-swing cannot flip the pose. Actual smooth lunges: wolf48 sprint/34 bite/24 claw pixels, owl18 air peck/0 grounded wing; sheep unchanged. Real wolf melee reach extends142/124 and preserves mushroom scaling. Three claw contact traces attach in front; no projectile/beam. Gliding normal and gust aliases both point to the same calm row, with fixed horizontal gaze. Single press/cooldown remain.

Nine source/scene suites1975 assertions. Maintained browser driver uses passive real rendered sprite X and registered eye observations, without world setters. Stable Android versionCode12. Retain Mac explicit DMG capacity sizing/verify. Package and publication results append once verified; keep prior releases.

0.12 delivery: final application1532cb787fe034760ef41bf37771c085c97b282b, successful nativeCI42926160897, release source4d2f079 and publisher42927273447. Source1975 and browser55 checks. Actual live sprite displacements48/34/18px; registered near-eye X302 remains constant in glide and ground-wing. Nine public packages plus receipt/sums verified; downloaded Mac ZIP CRC/version12/universal and stable APK bytesa0ba8c60bb1f53a5543a158787ed273f4f8774c60a1181bf4d72929323ceaf8c verified. APK transfer branch deleted. Prior releases retained. docs/evidence-v012 records scope/limits and full playback.

Historical handoff follows.

# Current handoff · 0.11.0

Canonical hero identity release. assets/CANONICAL-PROVENANCE.json takes alias priority. Five new original unchanged PNGs contain 449 drawn poses: 14 rows per hero with actual counts7/8, plus four8-pose compact clockwise roll rows. Original T-pose references linked in provenance were read from owner-authorized Drive. Aion is pink external feathery gills/blue eyes/labcoat/DNA tail; wolf gray-lavender bare fur/curse; sheep ivory wool/gold halo; owl brown feathers/amber eyes. Do not substitute generic aquatic fins, beam attacks, wolf clothing or random anatomy.

Common scale per hero, iris-based anatomical origins for run/jump/melee/weapon poses; authored smooth lunges separate from frame placement. Independent padded textures prevent neighboring fragments. Roll source order is visually reviewed right/down-right/down/down-left/left/up-left/up/up-right, fixed center32px above road. Use dedicated canonical-rolls, not the mixed prep/recovery rows. Wolf incorrectly generated icy row6 is excluded; boost uses bare-fur running plus existing moving wind. Owl ashes retain the prior correct sheet. Physical attack rows3/4, gun7/8, impact9/prone10, airborne owl beak13.

Fresh motion/effects/audio/celebrations true even with browser reduced-motion setting, per explicit owner instruction; explicit saved false remains false. Accessible On/Off labels supplement CheckButton icon. Eight source/scene suites1773 checks after observed frame counts replace older count quotas. Future art prioritizes identity, alignment and pose quality over frame count. Build/sign/package0.11, Android code11; same stable signer. Prior boss/flock/gamepad/languages/offline features preserved. Release verification details follow in docs.

0.11 delivery complete: application4a91af9, Mac packaging follow-up4b64701, successful nativeCI42921167868, release source016da55cdb01a41b2ad3acf17eae03b7a855b2f1 and publisher42922436056. 1773 source/scene and91 local/live/PWA browser checks. Nine packages plus receipt/sums verified; stable APK checksumd606bb74ca59bd4c1c7d3f53222df7985896f505b8e8f4fc07b1d40e81a209d7, versionCode11. Actual downloaded Mac ZIP CRC/version11/universal architectures verified. Transfer branch deleted. All old releases preserved. GitHub CLI REST credential later expired; connected GitHub tool confirmed publication and public HTTPS downloads verified bytes. Normal Git transport remained functional. No credentials were replaced or requested.

Historical handoff follows.

# Current handoff · 0.10.0

Authoritative main. Three new unchanged original PNGs / 300 frames registered in ENCOUNTERS-PROVENANCE. Current frame bank adds gun-run/gun-fire/deaths/boss-designs while preserving 0.9 motion sources. Gun anticipation0.075s emits at the measured muzzle; 0.30s animation, 0.32s cadence. All heroes keep a single pair scale. Death cause is separate from legacy bonk state; enemy selects prone row, solid/projectile selects impact row. Fatal airborne impacts descend; gun poses never cover defeat.

Boss designs rotate with milestone10/20/30. Three patterns each, one required dodge lane per salvo, half-health faster phase, moving X/Y. Training is an explicit main-menu option, separate from normal progression/records; selected hero retained, sheep gets3 for practice. Never call it a naturally reached level10 browser run. Boss flock uses chase_distance with spatial history and rebases history on return. No follower hiding in boss mode.

Gamepad handler is scripts/gamepad.gd: actual UI activation A/X (Cross/Square), direction/left-stick navigation/repeat, B back, Start pause, RT/R2 fire; disconnect clears held controls. Existing keyboard/touch preserved. Source tests1344; browser virtual standard-controller tests do not prove physical hardware. Background celebrants are drawn inside scenery BEFORE foreground trees at ground-58, fully opaque on a bank, parallax.45; hug moves forward.

Keep all old releases. Increment Android stable-signed versionCode10. APK transfer uses <=40 MiB same-repo temporary parts with hashes, never private signing material. Verify native CI and public files then delete transfer branch. Owner Apple signing/notarization remains outstanding. Delivery details append when complete.

Historical handoff follows.

# Current handoff · 0.9.0

Repository main is authoritative. Current motion release work: ten new unmodified original PNGs / 997 physical frames; dynamic count registry; one common scale per hero sheet; isolated padded textures. Future animation sheets require >=10 actually drawn columns, no duplicated/interpolated padding. Static props exempt.

Progression requires >=30 seconds active normal running AND >=12000 distance since the previous level. No level catch-up loop; pause/hug/boss excluded. Background girls face left, scroll with distance, last five seconds. Every tenth level still hugs/hands off a gun and runs the isolated robot chase. Owl airborne strike selects beak row8. Wolf gun row7 stays bare purple/cream fur. No inverted-U spawn: ground pads grant 3.5s 1.18x rush, two crow-carried loads support rolling or aerial destruction.

Six Godot suites pass 1200 checks. See docs/VALIDATION.md for browser/native/delivery results as finalized. Keep prior releases/tags unchanged. No credentials/signing material in source or Release. Signed APK now exceeds the GitHub single-blob limit; stage <=40 MiB parts in a temporary same-repository branch with APK-PARTS.json, reconstruct and hash-check in publisher, delete branch after public verification. Android signer remains stable; Apple owner signing/notarization remains outstanding.

Historical handoff follows.

# Forge · Aion Endless Run

Yetkili kaynak: https://github.com/kaansavukduran/aion_endless_run · `main`.

Yeni bağımsız Godot 4.6.3 oyunu. FireAxolotl kaynaklarına değişiklik yapılmadı. Kaynak PNG'ler değiştirilmeden alındı ve provenance kayıtları korundu. Aion 6×8 koşu paftası gerçek karelerini kullanır. 0.2.0 için wolf/sheep/owl kimliklerinden yeni sağa bakan 6×6 koşu/zıplama/süzülme paftası üretildi. Orijinal paftalar korunur; yeni PNG değiştirilmeden çizilir, hücre taban çizgileri kayıtlıdır.

Ana akış: Space/sol tık/dokunma zıplama, Esc duraklatma; karakter seçimi, ayarlar, gerçek skor ve kristaller, kalıcı rekor/tercihler, ateş/buz sonlanması, iki biyom, gündüz/gece. Ses yerel sentezlenir. Ağ çağrısı/telemetri yok.

`tests/test_game.gd`: 84 anlamlı fizik ve gerçek sahne/menü/kayıt kontrolü. Son platform ve görsel doğrulama: `docs/VALIDATION.md`. Release kapsamı: `docs/RELEASE.md`. Paketleme: `.github/workflows/build.yml`, `packaging/`, `docs/BUILD.md`. Özel anahtarları kaynağa veya arşive ekleme.

Öncelikli sonraki işler: fiziksel dokunmatik cihaz deneyimi, Apple Developer ID/noter onayı ve iOS TestFlight kurulumu. Kaynak projenin iOS hedefinin varlığı iPhone'da kurulabilir paket üretildiği anlamına gelmez. Mevcut ilk beta paketlerini ve etiketlerini koru.

İlk teslim 0.1.0 beta: Windows NSIS+ZIP, Linux DEB+AppImage+tar.gz, macOS universal DMG+ZIP, Android release APK ve ek Web arşivi. 40 kaynak/gerçek sahne kontrolü ve 12 gerçek tarayıcı kontrolü. Native Android emülatör testi ANGLE/SwiftShader ile ekran içeriğini ve offline başlangıç/Space/Esc akışını denetler; eski GLES çeviricisinin boş ekranı başarısız kabul edilir. Windows ve Linux kurulumdan sonra da açılır; macOS native ilk açılışı CI’da geçti.

Android release imza anahtarı `/workspace/work/signing` özel derleme alanındadır, kaynakta veya Release içinde değildir. GitHub secrets yazma denemesi 403 döndürdü. İleriki imzalı güncellemeler için aynı anahtarın güvenli saklanması ve sahibinin GitHub Actions secret ayarını tamamlaması gerekir; `docs/BUILD.md` izlenir. iOS App Store/TestFlight ve macOS Developer ID/noter onayı tamamlanmadı.

0.1.0 için doğrulanmış oyun kodu: `c36b105`. Tam başarılı CI: https://github.com/kaansavukduran/aion_endless_run/actions/runs/42825770482 . Sonraki yalnızca belge/ekran görüntüsü kaydı oyun kaynaklarını değiştirmez. Release içindeki BUILD-RECEIPT.json ile SHA256SUMS gerçek yüklenen dosyaları tanımlar.

## 0.2.0 geliştirmesi

Aion çift zıplar. Baykuş tek zıplar; Space/dokunma basılıyken düşüşte süzülür ve bırakınca normal düşer. Koyun aralıklı görünen arkadaşları temasla toplar; toplam en fazla 3 koyun, her koyun 1 can. Kurt Shift veya karakter üzerine basılı tutularak 1.55 kat hızlanır; ikinci dokunma parmağıyla aynı anda zıplanır. Tüm basılı kontroller duraklatma, odak kaybı ve karakter seçiminde temizlenir.

Yerelde 84 kaynak/sahne kontrolü, 12 temel web akışı ve 12 yeni yetenek/touch akışı geçti. Ekran görüntüleri `docs/evidence-v02/` içinde kaydedilir. Vercel kaynak derlemesi hem hazır Godot hem sıfırdan resmi indirmeyle doğrulandı. Kullanıcının Vercel adresi: https://aionendlessrun.vercel.app/ . Bu adresin 0.2.0 yayını yeni main gönderiminden sonra ayrıca doğrulanır. Native CI ve 0.2.0 Release teslimi tamamlanınca son kayıt eklenir; 0.1.0 korunur.

## 0.2.0 teslim sonucu

Oyun kodu `3af5c07`; paket/native CI https://github.com/kaansavukduran/aion_endless_run/actions/runs/42842185612 tamamen başarılı. Sonraki değişiklikler test zamanlaması/belgelerdir. Android tutma sırasında görüntü alma kontrolü https://github.com/kaansavukduran/aion_endless_run/actions/runs/42844605684 ile tekrar geçti; yeni baykuş karesi native ekranda açıldı.

Yayın: https://github.com/kaansavukduran/aion_endless_run/releases/tag/v0.2.0 . Yayımlama işi: https://github.com/kaansavukduran/aion_endless_run/actions/runs/42845252854 . 9 paket + BUILD-RECEIPT.json + SHA256SUMS yüklendi; Android imzası ve yayımlanan dosya SHA-256 değeri doğrulandı. 0.1.0 etiketi ve 11 varlığı korundu. APK geçici olarak aynı GitHub deposunun release-assets/v0.2.0 dalından Actions’a aktarıldı; yayımdan sonra bu geçici dal silindi. İmza anahtarı aktarılmadı.

Vercel: https://aionendlessrun.vercel.app/ . 84 kaynak/sahne + 24 yerel gerçek tarayıcı kontrolü geçti. Canlı kaynaklardan da 12 temel ve 12 yetenek kontrolü geçti. Bu bulut ortamında Chromium sistem proxy CA’sını tanımadığı için canlı test trafiği sistem CA’sıyla TLS doğrulayan bir sürücüden geçirildi; worklet modülleri aynı doğrulanmış içerikten yüklendi. Canlı PWA service-worker önbellek kurulumu bu sürücüde doğrulanmadı; native çevrimdışı test ve webin yüklenmiş halde çevrimdışı oynanması ayrıdır.

## 0.3.0 animasyon ve web güncelleme düzeltmesi

Kullanıcı portable sürümü doğru, Vercel görünümünü eski buldu. Önceki doğrulama eski bir tarayıcı profilinin cache-first Godot servis çalışanından yükseltmesini kapsamıyordu. Üç karakter için ayrı 48 karelik Aion tarzı koşu/zıplama/donma/ateş/kül/yetenek/iniş paftaları eklendi. Dosyalar orijinal çıktı olarak korundu; bölge ve zemin metadata ile hizalanır. Kurtta depar, baykuşta süzülme ayrı animasyon kullanır; koşu mesafeye bağlandı. Tüm önceki yetenekler korundu.

Web motoru ve PCK aynı içerik kimliğine ait dosya adlarını kullanır. Sabit eski worker URL’si yeni atomik çevrimdışı önbelleği kurar, skipWaiting/claim ile eski kabuktan bir kez geçer. Kullanıcı IndexedDB kaydı silinmez. Sonraki güncellemeler aktif koşuyu bölmeden düğme gösterir; tıklanınca pause/save ve IDBFS flush sonrasında açılır. HUD ve canvas sürüm numarası verir. 96 Godot + 35 gerçek browser/PWA kontrolü geçti. 0.1.0’dan aynı origin üzerinde çevrimdışı önbellek, kayıt koruması, 0.3'e geçiş ve sonraki düğmeli güncelleme gerçek worker ile doğrulandı. Paketler/yayın için CI sonuçları ayrıca kaydedilir.

## 0.3.0 tamamlanan teslim

Oyun/paketleme kodu `7183dc8`. Native CI: https://github.com/kaansavukduran/aion_endless_run/actions/runs/42851228198 tamamen başarılı (Windows kurulum/portable, Linux DEB/AppImage/portable, macOS universal app/DMG, Android çevrimdışı emülatör). Yayın: https://github.com/kaansavukduran/aion_endless_run/releases/tag/v0.3.0 . Yayımlama işi: https://github.com/kaansavukduran/aion_endless_run/actions/runs/42852589885 . 9 paket ve 2 doğrulama dosyası yayımlandı; GitHub asset digest/size değerleri receipt ile, yayımlanan APK da yerel imzalı dosyayla eşleşiyor. Android uygulama kimliği ve sertifikası aynı, versionCode 3. Geçici APK aktarım dalı yayın doğrulaması sonrası kaldırıldı. Eski sürümler korundu.

Canlı Vercel adresinde 12 temel + 12 yetenek/touch kontrolü geçti. Gerçek yayımlanan worker/engine/PCK dosyaları TLS doğrulamasıyla indirildi; 0.1.0 ve 0.2.0 eski arşivlerinden ayrı ayrı aynı yerel origin üzerinde yükseltme testlerinin 11'er kontrolü geçti. Hiçbir worker unregister/IndexedDB temizliği yapılmadı; kayıtlar korundu, güncel sürüm offline yeniden açıldı. Sonraki sürüm düğmesi açık koşuyu kesmeden belirdi; tıklama pause/save sonrasında açtı. Bulut Chromium proxy CA kısıtı nedeniyle bu gerçek-worker testi üretim dosyalarının yerel aynasında yapıldı; doğrudan canlı kontrollerde TLS doğrulayan yönlendirme sürücüsü kullanıldı. Native Android ekranında v0.3.0 yeni koşan baykuş görüldü; gerçek fiziksel cihaz/iOS imza durumu için yeni iddia yok.

## 0.4.0 sıralı sürü ve rüzgâr

Kullanıcı ikinci ve üçüncü koyunun öndekinin zıpladığı dünya noktasına geldiğinde sırayla zıplamasını, kurdun sabit üç hız çizgisinin hareketli rüzgâra dönüşmesini ve baykuşun aralıklı havada yükselen rüzgâr yakalamasını istedi. Sürü artık liderin kısa mesafe/poz geçmişini 64 ve 128 piksel geriden örnekler; hız bağımsız uzamsal zamanlama, farklı uçuş/iniş kareleri, pause/reset koruması vardır. Bellek geçmişi sınırlıdır. Kurt rüzgârı 12 bağımsız eğri/fade fazıyla akar. Baykuş görünür, geçen akımlarda basılı tutarak gerçekten yükselir; sınırlı yükseklik, bırakma ve sonlu uçuş korunur. Yeni 18 karelik ek orijinal pafta depar/kuyruk, yükselen hava kanatları, koyun esneme ve yumuşak inişini sağlar. Eski donma/kül paftaları korunur. 121 kaynak/sahne kontrolü geçti. Yayın/native sonuçları tamamlanınca ayrıca kaydedilir.

## 0.4.0 tamamlanan teslim

Oyun kodu `6d1f2b6`; yalnızca Mac çalıştırıcı seçimini değiştiren paketleme/doğrulama kodu `f224c46`. 121 kaynak/sahne, 42 yerel gerçek browser/PWA kontrolü, canlı adreste 12 temel + 19 yetenek/dinamik kontrolü geçti. Sürünün gerçek Space girdisiyle lider→ikinci→üçüncü sırası DOM gözlem zaman çizelgesinde kaydedildi; oyuna durum enjekte edilmedi. Baykuş doğal beliren akımda gerçek irtifa kazandı, kurt yeni pafta ve akan geometriyi kullandı. Üretim dosyalarının TLS doğrulanmış kopyasında 0.3→0.4 gerçek worker/düğme/IndexedDB/offline geçişi 11 kontrolle geçti. Native Android ekranında GLIDING etiketiyle basılı tutma gösterildi; akımda yükselmenin native fiziksel cihazda test edildiği iddia edilmez.

Tam başarılı CI: https://github.com/kaansavukduran/aion_endless_run/actions/runs/42857645429 . GitHub'ın resmî Actions aksaklığı sırasında macos-latest işi kuyrukta kaldı. Standart macos-15-intel çalıştırıcısı başladıktan sonra eski 42855580376 işi iptal edildi; yeni iş universal app/DMG üretip çalıştırdı. Windows tekrarında dış Chocolatey NSIS kaynağı 504 verdi; o işin tekrarı başarılı oldu. Yeni Mac ZIP gerçekten indirildi, CRC ve Mach-O x86_64/arm64 mimarileri doğrulandı.

Yayın: https://github.com/kaansavukduran/aion_endless_run/releases/tag/v0.4.0 . Yayın işi: https://github.com/kaansavukduran/aion_endless_run/actions/runs/42859234637 . 9 paket + 2 doğrulama dosyası yayımlandı. Tüm sunucu SHA-256/size değerleri receipt ve SHA256SUMS ile eşleşti; APK yerel aynı sertifikalı dosyayla eşleşti (versionCode 4, Internet izni yok). Geçici release-assets/v0.4.0 APK aktarım dalı yayım doğrulamasından sonra silindi; anahtar aktarılmadı. Önceki sürümler korundu. Web: https://aionendlessrun.vercel.app/?v=0.4.0 .

## 0.5.0 savaş ve değişken koşular

Kullanıcı karga, saldırı/hasar, düşmana basma, eğilme/dal, eşya güçleri, mantar sonrası devlik ve küçük kırmızı şapkalı cüceler, hava/şimşek, daha rastgele karşılaşma/tempo, belirgin gecikmeli koyunlar ve her zaman yatay telefon düzeni istedi. 102 yeni özgün kare üç değişmemiş PNG olarak üretildi; dört karakterin saldırı/eğilme, karga, cüce ve eşya/dal animasyonları vardır. Oyun mantığı RunnerAdventure ve ayrı çizim bileşenine ayrıldı. Temas penceresi, vuruş aralığı, can/kalkan/geri tepme, üstüne basma sekmesi ve yedi geçici güç gerçek fiziğe bağlıdır. Geniş sürü aralığı 112/224 pikseldir. Süzülme, yükselen hava, çift zıplama ve kurt deparı korunur. Telefon yön kilidi desteklenmezse dünya ve arayüz yataya döner; dokunma parmak kimliğiyle yönlenir.

Sure Footing üretim yazısı ve Microsoft XAG 117/118 araştırmasından seçilen adil aralıklar/tempo, kısa hedefler, kombo ve kapatılabilen düşük genlikli kamera/şimşek tasarımı `docs/GAME-DESIGN.md` içinde açıklanır. Araştırma fikirlerinin uygulanmayanları açıkça ayrıdır. 178 kaynak kontrolü, 12 temel ve 11 gerçek worker güncelleme kontrolü geçti. 29 yeni oynanış/touch ve 10 eski yetenek akışıyla yerel toplam 62 gerçek browser/PWA kontrolü geçti. Lider→ikinci→üçüncü sırası üç can korunurken kaydedildi. Oyun/paket kodu c7c6f20; tam native CI 42872138632 başarılı. Üretimin 0.5.0 / 4d293da0d95edc60 dosyaları TLS doğrulamasıyla indirildi; aynı dosyaların yerel HTTP aynasında 0.4→0.5 gerçek worker/IndexedDB/offline geçişi 11 kontrolle geçti. Canlı input ve Release bütünlüğünün son kaydı yayım sonrası eklenir. Android kod 5 aynı sertifikayla imzalı, Internet izni yok. Önceki sürümler korunur; Apple yerel dağıtımı için önceki sahip imzası sınırı sürer.

## 0.5.0 tamamlanan teslim

Oyun/paket kodu c7c6f20, tam başarılı native CI 42872138632. Yerelde 178 kaynak/sahne ve 62 gerçek browser/PWA kontrolü geçti. Canlı HTTPS adresinde 29 yeni oynanış/telefon ve 12 temel kontrolle toplam 41 kontrol de geçti. Eski 0.4 arşivinden üretilen gerçek worker/kayıt/offline geçişi hem yerel export hem üretim dosyalarının TLS doğrulanmış yerel aynasında 11'er kontrolle doğrulandı. Doğrudan canlı input testinde Chromium proxy CA sınırı için doğrulanan TLS sürücüsü kullanıldı; production-origin worker kurulumu iddia edilmez. Yerel örnekte ikinci koyun ~0,309 s, üçüncü ~0,639 s sonra havalandı; hız değişse de aynı dünya noktası izlenir. Native Android görüntüsünde gerçek eğilme var; iki tek kareden saldırı/süzülme çıkarımı yapılmadı.

Yayın v0.5.0, yayın işi 42873274104: 9 paket + 2 doğrulama dosyası yayımlandı. Tüm asset SHA-256/size değerleri receipt/sums ile, Android de yerel aynı sertifikalı kod-5 APK ile eşleşti. Gerçek Mac ZIP CRC ve x86_64/arm64 dilimleri doğrulandı. Geçici APK aktarım dalı yayım doğrulaması sonrası silindi; anahtar aktarılmadı. Önceki dört sürüm korunuyor. Oyna: https://aionendlessrun.vercel.app/?v=0.5.0 ; indir: https://github.com/kaansavukduran/aion_endless_run/releases/tag/v0.5.0 . Yerel iPhone App Store/TestFlight, sahibin Apple imzalama/dağıtım kurulumu bekler; Safari web alternatifi vardır.

## 0.6.0 üç dil ve tutarlı ölçek

Kullanıcı TR/EN/CS, ilk açılışta tarayıcı/cihaz ana dili, diğer dillerde İngilizce, kalıcı manuel seçim, tam yerelleşmiş karakter adları, başlangıçta görünür seçim ve koşu sırasında karakter kilidi istedi. Ayrıca koyun/kurt zıplaması ve baykuş yükselen hava hareketinin boyut farkını kaldırıp lideri normal, takipçileri küçük istedi. Üç dilin tüm oyun anahtarları çevrildi. Başlangıç kartları ve yataya dönen telefonla da çalışan açılır dil listesi eklendi. Dil modu otomatik/manuel ayrılır; eski geçerli tercih korunur. Karakter seçimi hem arayüz hem işlev guard'ı ile koşuda kilitli. Orijinal PNG'ler değiştirilmedi; 210 mevcut kare için opak bileşen kayıtları çıkarılıp hareket pozları 90 mantıksal piksele hizalandı, takipçi oranı %72. Eğilme ve kasıtlı mantar büyümesi ayrı kalır. 207 kaynak/sahne kontrolü geçti. Mevcut savaş/güç/hava/çoklu dokunma/çevrimdışı özellikleri korunur. 30 dil/ölçek, 30 macera/sürü/telefon, 10 yetenek, 12 temel ve 11 gerçek worker 0.5→0.6 geçiş kontrolüyle yerel toplam 93 gerçek browser kontrolü geçti. Oyun/paket kodu 44fc0bc. Vercel başarılı; üretim dosyaları TLS doğrulanmış olarak indirildi. Native, doğrudan canlı input ve Release bütünlük sonuçları tamamlanınca kaydedilir.

## 0.6.0 teslim ve doğrulama

Oyun/paket kodu 44fc0bc; native CI 42877557249 tamamen başarılı. 207 kaynak ve 93 yerel browser kontrolü, canlı HTTPS'te 30 yeni dil/boyut kontrolü geçti. Gerçek rüzgâr yakalayan normal baykuşta yükselen hava pozu ve 90 piksel yükseklik doğrulandı; canlı görüntü RISING/YÜKSELİYOR durumunu gösterir. 0.5→0.6 gerçek worker/kayıt/offline geçişi hem yerel export hem üretimin TLS doğrulanmış dosyalarının HTTP aynasında 11'er kontrolle geçti. Doğrudan canlı testlerde proxy CA için doğrulanan TLS sürücüsü, worker testi için gerçek yerel ayna kullanıldı. Native görüntülerde dört başlangıç kartı ve Omar adı var; dosya adlarından duraklama/darbe/süzülme anlamı çıkarılmadı.

Yayın v0.6.0, yayın işi 42878585247: 9 paket ve 2 bütünlük dosyası doğrulandı. Tüm GitHub SHA-256/size değerleri receipt/sums ile eşleşiyor. Mac ZIP CRC ve Intel/Apple Silicon dilimleri kontrol edildi. Android aynı sertifika, kod 6, Internet izni yok; yayımlanan APK yerel imzalı dosyayla eşleşiyor. Geçici APK aktarım dalı kaldırıldı. Önceki beş sürüm korundu. Daha sonra eklenen kanıt/test kayıtları oyun kaynaklarını değiştirmez.

Canlı kararlı girişte 30 macera kontrolü de tamamlandı; doğrudan HTTPS toplamı 60 oldu. Üç canlı koyunda lider→ikinci→üçüncü sırası, küçük takipçiler ve telefonda eşzamanlı zıplama/vurma doğrulandı. Sürü gözlem testi, arkada henüz teması süren engelleri de bekleyerek gerçek bir can kaybının ölçümü bozmasını önler; oyun kuralları değişmedi. Sonraki değişiklikler belge ve test gözlem kaydıdır. Oyna: https://aionendlessrun.vercel.app/?v=0.6.0 ; indir: https://github.com/kaansavukduran/aion_endless_run/releases/tag/v0.6.0 .


## 0.9.0 completed delivery

Published release: https://github.com/kaansavukduran/aion_endless_run/releases/tag/v0.9.0 . Publisher workflow **42909252937** succeeded, source/tag `a6448251ba963b37e13eeaa26765c9a50b8da6b2`; verified application/native source `de4269a40506e5b1db04516463a227894152ec73`. Only tests/documentation differ between these commits, with no change to exported application resources. All nine GitHub asset sizes/SHA-256 values match the downloaded receipt and sums. Both integrity files match GitHub digests, and the receipt matches SHA256SUMS. The published Android APK matches the locally stable-key signed bytes, SHA-256 `7799acf9ee7e5d2446c0a5079447eea3de81a0f0480436ffcec7f9b53400bd4a` (106726737 bytes). Downloaded macOS portable ZIP passes CRC and contains x86_64/arm64 Mach-O slices. The temporary three-part APK transfer branch was deleted after verification; private signing material was never transferred. Prior 0.1–0.8 releases remain published.

The normal canonical HTTPS entry opens 0.9.0; its regular updater selects immutable build `b5c4a95ad0c05545` and the observed URL `https://aionendlessrun.vercel.app/?build=b5c4a95ad0c05545`. This was observed without storage clearing or manual cache bypass. The same actual public bundle underwent real-worker offline migration on a mirror origin. Direct production-origin worker installation remains outside this cloud proxy's browser verification scope. Package integrity results, receipt, sums, CI summary and current-entry screenshot are in evidence-v09.

## 0.10.0 completed delivery

Application/native source7f139f7ed3039a068b60b771ba7e2b13d09f56d5; full native CI42913367815 succeeds. Source/tag ddcd117966a727b935a2d9690f87e1bff21373e3 contains final tests/evidence, no exported app changes. 1344 source/scene +91 browser/PWA executions pass, including actual virtual-controller UI and all three training victories locally and via verified HTTPS. Physical controller testing is not claimed. Releasev0.10.0 / publisher42914898071 complete:9 packages+receipt+sums; all server digests/sizes, stable APK bytes and downloaded Mac CRC/architectures verified. Staging branch deleted; private key never transferred. Old releases retained. See docs/evidence-v010 and docs/VALIDATION.md.


## 0.13.1 portrait boss follow-up

Manual portrait review exposed a clipped boss status label missed by the menu-button checks. The label wraps, portrait HP/notice geometry is separate, and mobile help/lives are shown once. Eleven source suites2218 and46 current local browser checks pass; evidence and exact scope: docs/evidence-v0131. The0.13 evidence and published packages are preserved. Native/public outcomes are recorded only after their real completion.

## 0.14.0 · AIONIA v1.4

Normatif belge ve bağlı AER-001–013 kaydı okundu; sürümlü kaynak/hash ve tasarım/sanat/kontrol kararları eklendi. Kullanıcı iki yana bölünmüş düğmeleri seçti. Varsayılan koyu/sistem yazısı, light/system seçenekleri, büyütülmüş metin, azaltılmış dekorasyon, erişilebilir menü karşılıkları ve kol ayarları mevcut Godot altyapısına bağlandı. Kahraman PNG'leri korunur. Fragaria yükleyicisi ve sekiz kişilik arka kutlama tamamlandı. Kaynak kontrolü 2549, tarayıcı 190, paket sözleşmesi 5; fiziksel cihaz ve yayın sınırları `docs/AIONIA-QA.md` içinde. Native CI/yayın sonucu son makbuzda ayrı kaydedilir.

0.14 son düzeltme: CI font farkı için gerçek Label ölçümü, DejaVu/Liberation regresyonu; hızlı yenilemeye karşı sürümlü senkron browser kurtarma kopyası. Güncel yerel kontrol 2549 kaynak/sahne + 190 browser + 6 paket sözleşmesidir.

### 0.14.1 — gerçek Android görüntüsündeki menü çakışması

0.14.0 giriş testi geçmesine rağmen API30 ekran görüntüsünde sistem yazı tipiyle Settings/karakter başlığı çakıştı. 9:16 ekranda sabit yüksekliğe sığmayan başlık/altbaşlık/üç düğme minimum toplamı kanıtlandı. İki telefon yönünde kompakt tek satır logo ve 64 birimlik okunaklı eylemler kullanılır; panel yüksekliği karakter seçimi başlangıcından hesaplanır. 1440×2560 kaynak ve 450×800 gerçek tarayıcı durumları, ayrıca Android pasif UI bölge sınırı kontrolü eklendi. Oyun girdisi ve kahraman paftaları değişmedi.

Platform fontu regresyonu ayrıca önizleme/roster bütçesine ve sıfır genişlikte şekillenen Label’ın eski yüksekliğine indirgenmiştir. Metin boşken gerçek genişlik kurulur, sonra çevrilmiş metin atanır. Gerçek native TR/EN/CS görüntüsü ve 7 ADB kontrolü, sekiz tarayıcı ölçüsü, iki alternatif sistem fontu doğrulandı.
