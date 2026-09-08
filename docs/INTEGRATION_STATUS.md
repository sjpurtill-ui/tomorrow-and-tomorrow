## September 7 — production clarity integrated; expanded forces held

INTEGRATED `da9f917`: finite default production targets, concrete material/worker
blockers, forecast/stock/target visibility, known-equipment selectors, clear
simple-levy weapon naming and all valid army equipment choices. Source worktree
`tt-production-clarity`; 25 unique production/quote checks passed. Fast-forward
integration preserved the validated source. See PRODUCTION_CLARITY_HANDOFF.md.
No new player launch or live-session receipt is claimed.

HELD `33ab016`, branch `codex/fifty-units`, worktree
`/Users/seanpurtill/Documents/Codex/tt-fifty-units`, base `da9f917`.
User scope is **50 land units PLUS full naval and air chains**. This checkpoint
has the 50-land catalog/combat/equipment/research foundation, a progression view,
and experimental naval/air state. 81 unique focused/regression checks pass.
It is not merged or player-ready: convoy effects, carriers, transport missions,
rival operations, geographic operating controls and labor/economic integration
remain incomplete. See that worktree's docs/FIFTY_UNITS_HANDOFF.md for the exact
roster, tests, compatibility and release blockers. Do not report catalog counts
as complete HOI4 naval/air functionality.

## September 7 — army staffing clarity

INTEGRATED `fab7843` by conflict-free fast-forward from `1589e37`. Recruit & Train shows available recruits, training places and work allocation separately. Per-city watch/training priority actions replace the vague allocation detour and retain GovernmentPeopleSystem authority and occupation guards. Eleven targeted and existing recruitment tests pass; no save or calculation changes. See ARMY_STAFFING_HANDOFF.md. The city flag update `a0ff5d5` is included in this base. Player PID 47271 has not been restarted; receipt by the live session is not claimed.

## September 7 — foreign city labels and map intelligence

Integrated `824ea64` and `4614b5e` from `codex/foreign-city-labels` by fast-forward. Known foreign cities retain name/population-estimate labels at every distance. Clicking a city opens a compact intelligence dock on the map; the full report remains optional. A live check found a competing font-size refresh that caused shrinking/blinking; the follow-up preserves aerial normalization. Two targeted regression cases pass, including normalization followed by marker refresh at all four distances. The older intelligence AI-target test remains a reproduced baseline failure (see FOREIGN_CITY_LABELS_HANDOFF.md). No save schema changes.

Canonical editor Run Project resumed Seanston, day 2374, population 147, seed 1792946605. Player PID 47271 has the explicit canonical project path and `res://local_terrain.tscn` with `--resume-saved`; startup log confirms restoration with no script errors. Live Region screenshot shows foreign names at readable size matching Seanston. Campaign remains paused. The temporary editor resume argument was removed from project.godot after launch. Click/summary behavior is covered by targeted checks; native automation could inspect the embedded game but redirected coordinate clicks to the editor, so no live mouse-click validation is claimed.

# Compact speed dropdown integrated — September 7, 2026

INTEGRATED 45b24d1 in canonical Mac main by conflict-free fast-forward from
ad943db. Canonical HUD file matches the tested worker exactly; tracked tree clean.
Five persistent speed buttons become one dropdown plus pause/resume. Actual rates
and keyboard shortcuts are unchanged. Repeated speed text is removed; checked
representative width is 380 px. Isolated clean import and all five selection,
pause/resume and width checks passed. See SPEED_DROPDOWN_HANDOFF.md.

Player PID 42977 remains running and was not restarted. The last native screenshot
still shows the previous bar; live script application is not claimed. The new
control appears on HUD recreation/next launch, or supported live script reload.
No save changes or shared simulation edits; no remote push.

---

# City parity and four-distance controls integrated — September 7, 2026

INTEGRATED in canonical Mac main:
/Users/seanpurtill/Documents/Codex/tomorrow-and-tomorrow
Source 3768cbe, fast-forwarded from 06c236c with no conflicts.

Added cities use recorded settlement design and local housing/construction,
resources, health, economy and demographic updates. HUD keeps overall and selected
city population together. City map labels use names and known/estimated population.
Four recovered distances: 10,000 ft, 50,000 ft, Region, Continent; discrete scroll
steps, slower fine adjustment and bounded transitions. Vacant intact buildings
remain visible; saved sites prevent maintenance redraws moving existing homes.

Canonical clean headless import and 91/91 targeted cases pass, zero errors,
failures, skips or orphans. Logs: /tmp/city-parity-canonical-import.log and
/tmp/city-parity-canonical-tests.log. Worktree real-terrain navigation probe passes;
shutdown resource warning documented in CITY_PARITY_DISTANCE_HANDOFF.md.

Canonical test override removed. All 118 pre-existing untracked files retain their
hashes. New optional dictionary data uses existing save serialization; round-trip
verified. No schema bump or arbitrary reset. The separate READY affordable-infill
69d9db9 remains outside this integration. No remote push.

Scope limits: existing national military/fortification authority remains; distant
baked imagery and large-scale performance profiling are not delivered. Actual
completed Lean-to work still converts household forms on monthly synchronization.
Full details and recovered design provenance: CITY_PARITY_DISTANCE_HANDOFF.md.
Canonical player launched through editor Run Project (Command-B), PID 42977.
Verified command includes --path /Users/seanpurtill/Documents/Codex/tomorrow-and-tomorrow
and --scene res://local_terrain.tscn. Native screenshot confirms the normal opening
direction screen, day 0; no direction chosen or campaign advanced. Player startup
log contains no script errors. This verifies launch, not visual signoff of every city.

---

# Consolidated deaths and investigation choices — September 7, 2026

INTEGRATED `28a06ac` in canonical Mac main by fast-forward from f0416ef.
Population views summarize deaths by cause with separate paged dated details.
Scout dispatch groups destinations by category and repeated accounts by people,
retaining each exact target and visible evidence. Original records, counts, mission
behavior and save format are unchanged. See CONSOLIDATED_LISTS_HANDOFF.md.

Canonical clean headless import and 15/15 focused list/rumor tests passed with
zero errors, failures, skips or orphans. Logs: /tmp/consolidated-canonical-import.log
and /tmp/consolidated-canonical-tests.log. The broader far-order city-marching case
failed the same three assertions on unchanged f0416ef; no military fix is included.
The private test application override was removed. Player PID 36402 and editor
35944 remain running; restart normally to load this update. No remote push.

---

# Citizen production integrated — September 7, 2026

INTEGRATED source `3dbca50` in canonical Mac main, fast-forwarded from `937cd65`.
The worker was rebased without conflicts to preserve the concurrently integrated
foreign-settlement refresh and its launch record. Original development base was
`1e57003`; no foreign-refresh changes were overwritten.

Military / Supply now defaults to persistent stockpile or continuous production.
Citizen condition, effective Crafting workers, logistics and recorded workplace
condition determine output. The adjustable military crafting share also governs
legacy batch orders and leaves the remaining share to existing civilian systems.
Shortages pause, stock targets replenish after issue, priorities divide capacity,
and retooling carries an efficiency/WIP cost. Finished goods use existing stocks,
training and field delivery. Full behavior and limits: CITIZEN_PRODUCTION_HANDOFF.md.

Canonical clean headless import and six-suite 62/62 regression passed, zero errors,
failures, skips or orphans. Includes 14 new persistent-production and dock-layout
checks. Logs: /tmp/production-canonical-import.log and
/tmp/production-canonical-tests.log. Test userdata was isolated by a temporary
application override with Dummy audio; that override was removed after validation.
New test UID is included in this integration record; unrelated files are retained.

The canonical player PID 36402 was launched by the foreign-refresh task while this
work was integrating. It and editor PID 35944 were preserved. The running player
loaded the prior scripts and needs a normal restart to use production changes.
No new player/test window was launched by this delivery. No remote push.

---

# Foreign settlement refresh integrated — September 7, 2026

INTEGRATED source 0bb8659068e61cb4f4b3df1b010ed310568160ae by conflict-free
fast-forward from 1e57003 in canonical Mac main:
/Users/seanpurtill/Documents/Codex/tomorrow-and-tomorrow.
The integration-record commit contains this entry.

Foreign settlement visuals now share the authored town house assets, arranged
around courts with narrow feathered paths. Primitive houses and yard mats are
removed. Foreign architecture remains representative because city reports lack
construction records. The city sidebar opens on single-column estimates, with
separately scrolling Report, Scouting and Military tabs. No simulation/save schema
or military-order behavior changes. Source scope and limits are documented in
FOREIGN_SETTLEMENT_REFRESH_HANDOFF.md.

Canonical Godot 4.7.2 headless import passed without errors; the dedicated foreign
refresh probe passed with zero failures at all three viewport sizes. Combined
organic-town and city-intelligence regression: 22/23 passed, zero errors, skipped
cases or orphans. The sole failure is the previously reproduced base-code raid
expectation at test_city_intelligence.gd:93 (one expected, zero received).
Logs: /tmp/foreign-integrated-import.log, /tmp/foreign-integrated-probe.log,
/tmp/foreign-integrated-tests.log. All pre-existing untracked files retain their
hashes. The temporary isolated test configuration was removed.

No Godot player/editor was running before integration. User authorized integration
and loading the game. Canonical editor Run Project (Command-B on this Mac) launched
PID 36402 at gameplay/integration commit 63ef4fd, using the explicit canonical
absolute path and res://local_terrain.tscn. Startup log confirms the new-world
opening at day zero and no script errors. No save was overwritten or live session
interrupted. Graphical sign-off of the foreign view remains pending. No remote push.

---

# Settlement neighborhoods and routine raids — September 7, 2026

INTEGRATED in canonical Mac main by conflict-free fast-forward from 8536c15:
settlement neighborhoods d6bc405, routine raid correction 4ef88ea.
New household courts, actual-footprint shelter density, reserved central hearth,
feathered doorway paths and human-scale service objects replace early parcel mats,
old thick paths and oversized central props. New founding claims cluster more
closely. Existing records are not migrated; later unsupported architecture remains.

Rivals no longer invent three-person raiding parties or knowingly raid overwhelming
observed defenses. Failed raids delay later attempts. Small, outmatched home raids
use the real calendar/combat simulation without forced battle screens or pauses.
Real aftermath policy decisions remain. See SETTLEMENT_NEIGHBORHOODS_HANDOFF.md
and RAID_ROUTINE_HANDOFF.md for scope, save compatibility and limitations.

Canonical clean headless import and 174/174 selected checks passed, zero errors,
failures, skips or orphans. Seven suites: early visual 14, organic town 9,
settlement architecture 83, settlement model 43, raid policy 4, battle injuries 9,
army front visual 12. Evidence /tmp/neighborhood-canonical-import.log and
/tmp/neighborhood-canonical-tests.log. A separate broader worker run hit the
previously documented siege-withdrawal test failure; that issue remains separate.
The test override was removed. Three new script UID files are tracked with this
record; pre-existing unrelated untracked files are retained. No live player was
running at launch preparation. User requested a fresh game after completion;
canonical fresh launch is the next step. No remote push.

---

# Early primitive removal — September 7, 2026

INTEGRATED source `4f73017` as canonical `06862bc`, without conflicts.
Removed the duplicate central Lean-to Shelters tent ring and its unused primitive
mesh helper. Supported early plot forms never fall back to legacy roof/wall
massing, including when no footprint fits. Compact assets retry placement using
their authored envelope, retaining road, parcel, obstacle and land checks.
No-fit parcels can remain visually empty; construction no longer displays legacy
roof massing. Unsupported later forms and communal/service features remain.
No simulation or save-format changes. Local terrain is the shared-file hotspot.
Worker and isolated canonical runs each passed all 104 cases (12 early assets,
9 organic town, 83 settlement architecture), zero errors/failures/orphans.
Logs: `/tmp/early-removal-tests.log`, `/tmp/early-removal-canonical-tests.log`.
The temporary canonical test override was removed. User explicitly requested
that the running test campaign be discarded and a fresh game relaunched, replacing
the earlier resume-only instruction. Canonical fresh launch follows verification.

---

# Early settlement assets integrated — September 7, 2026

INTEGRATED in canonical Mac `main` at
`/Users/seanpurtill/Documents/Codex/tomorrow-and-tomorrow`.
Previous canonical HEAD: `4f68230a3c9c94064a91b3c2909ae806411f2297`.
Source: `a59910960ca453516d13432ab0df9521f6885615`.
Reviewed correction: `5c11d38faf8e716a5f9666f8bf50c9dc42fd9a7b`.
Both were integrated by conflict-free fast-forwards. The commit containing this
entry records final canonical verification; prior organic-town and military-front
sources remain ancestors.

Eight active assets now depict recorded carried shelters, rooted lean-tos,
round/earthen/rubble households, raised stores and covered workshops. They join
the earlier timber town kit. Existing resource/research recipes and completed
work supply the recorded built form; population and calendar do not repaint
buildings. Later/unknown forms are explicitly excluded from the early adapter,
including its shared-solver fallback. Identity meshes preserve imported LOD and
shadow resources. No new simulation/save authority or migration was introduced.

Three authored cultural/political studies remain INACTIVE: crafted household,
open common hall and enclosed authority hall. They are not unlocked in play.
Construction-era cultural/patronage records and appropriate public-parcel
placement are still required; current cultural or political shifts must not
instantly replace inherited architecture. See `EARLY_SETTLEMENT_PROGRESSION.md`.

Canonical Godot 4.7.2 clean headless import passed (exit 0, no script/import errors).
Combined **156/156 passed**, zero errors/failures/skips/orphans: early assets 9,
organic town 9, settlement architecture 83, settlement model 43, military fronts 12.
Evidence: `/tmp/early-canonical-final-import.log`,
`/tmp/early-canonical-final-tests.log` (canonical `reports/report_4/`).

Tests used a newly created isolated `Early_Canonical_a599109_Test` application
name with Dummy audio. That override was removed afterward; none was copied from
the worktree. All 118 pre-existing untracked files retain their exact set and
SHA-256 hashes; all three original save/settings files were unchanged after tests.
See `/tmp/early-canonical-preservation-result.txt`. No unrelated files were staged
or removed. Integration records are the only additional tracked edits.

The user explicitly requested integration and launch. No game/editor was running
before integration. Normal canonical saved-game resume is the next launch step;
no fresh-world/reset/showcase mutation is authorized or required. Offline Blender
asset plates are not game screenshots or FPS verification. Earlier schematic
military limits and the pre-existing siege-withdrawal issue remain unchanged.
No remote push. Further cultural gameplay and later architectural eras are not
claimed complete by this delivery.

---

# Military front integration — September 7, 2026

INTEGRATED in canonical Mac source; graphical review remains pending.
Canonical checkout: `/Users/seanpurtill/Documents/Codex/tomorrow-and-tomorrow`, `main`.
Previous HEAD: `577f8aa5d17310674b9d75454c2f584317c6c7aa`.
Reviewed source: `8ea1a7c73dab231bb46c1b187fcf6511c85f78a2`.
Reviewed correction and integrated gameplay HEAD: `45ce52f5605ad234a4755e84e7dd1baa4794fd0c`.
Both commits entered by a normal fast-forward with no conflicts. The commit
containing this entry records the completed canonical verification.

Bounded physical army fronts now replace soldier/mounted-general actors in the
field-army map, dated foreign sightings, eligible occupation garrisons, home
invasion/field battle observation and replay, general campaign map/replay, and
active siege city view. Metre geometry scales by .001 on kilometre terrain;
separate informational glyphs retain distant readability. Real active counts,
equipment and recorded losses determine area; recorded captives are excluded from
combat footprints without becoming casualties. No new combat, fire, control,
prisoner or save authority was added. Legacy direct-cohort controls cannot issue
orders; strategic conversation remains in GeneralCampaignScreen.

The reviewed correction includes occupation fronts in the actual terrain advance
hook, honors pause and inherited visibility, and invalidates siege geometry when
termination alone changes. **Deployment is schematic** where current battle
records lack cohort coordinates and maneuver topology. Optional renderer spatial
inputs do not constitute implemented encirclement or an independent combat solver.
Occupation ground is withheld before live communications when no dated strength
report exists. Full scope and limits: `MILITARY_FRONT_GRAPHICS_HANDOFF.md`.

Canonical Godot 4.7.2 validation, all headless with explicit canonical paths:

- Clean editor import: exit 0, no script/import errors.
- Combined front (12), general campaign (15), battle injury (9), organic town (9)
  and military development (16): **61 passed; zero errors, failures, skips or
  orphans; exit 0**.
- Actual invasion UI/replay probe: **PASS**, exit 0. Verifies zero soldier/general
  actors, responsive observation controls, one resolution, unchanged military
  export/calendar on replay, and pause.

Evidence: `/tmp/military-canonical-import.log`, `/tmp/military-canonical-tests.log`,
`/tmp/military-canonical-ui.log`, and `/tmp/military-canonical-preservation-result.txt`.
The existing siege-withdrawal failure in `test_siege_progression.gd:145` remains
unresolved: expected moving, received stationed. Worker verification reproduced
it on untouched `577f8aa` (8/9 passed). It was not concealed by graphics changes
or counted among the 61 passing canonical cases.

Organic town source `4251a3d98d6ca16af58fc2b102ecb6ecab7f2810` and integration
record `577f8aa` remain ancestors. The earlier 135-case town integration is retained;
its nine organic-town visual cases pass again alongside military on canonical main.

Temporary test configuration used the isolated
`TomorrowAndTomorrow_Military_Canonical_45ce52f_Test` user directory and Dummy audio.
No worktree override was copied. The new override and only the newly generated
front-test UID were removed after checks. All **117 pre-existing untracked files**
and all **three existing save/settings files** retain their SHA-256 hashes; the
original untracked set is exact. No unrelated file was staged, removed or replaced.
The integration-record commit changes only this document and
`FEATURE_RECONCILIATION.md`; tracked source is otherwise clean.

No Godot process was present before or after integration. No player/editor was
interrupted, no graphical test/demo or canonical game was launched, no restart or
push occurred. This verifies source integration, not rendered appearance, FPS or
that a player session has loaded these scripts. **Graphical review is pending.**
Work stops after this integration; no additional phase is started.

---

# Organic town integration — September 7, 2026

INTEGRATED in canonical Mac source, with graphical sign-off pending.
Canonical checkout: `/Users/seanpurtill/Documents/Codex/tomorrow-and-tomorrow`, `main`.
Previous HEAD: `1b9e121f481d1382eb1ecce9e7dde17b66b9e754`.
Reviewed worker/source commit and integrated gameplay commit:
`4251a3d98d6ca16af58fc2b102ecb6ecab7f2810` (normal fast-forward, no conflicts).
The integration-record commit is the commit containing this entry.

Compatible inherited single-storey timber/thatch plots now use metre-scale modular
homes along saved lanes, with small garden beds in clear leftover household ground.
Four 24 m² variants, a 12 m² small-parcel derivative and a 120 m² market hall share
bounded batches (512 buildings maximum). No-fit parcels retain existing roofs;
portable camps and unsupported traditions remain under their existing renderer.
The early primary-settlement slice replaces the legacy stage mass/density overlay
through 5,000 population and 128 recorded plots. Authoritative defenses and the
computed settlement extent remain. Houses use uniform scale 0.001, saved plot/route
identities and the same source geometry across camera distances. Inherited kit
houses persist across later population growth; no new population/economy/save
owner was added. Full scope and worker evidence: `ORGANIC_TOWN_HANDOFF.md`.

Canonical Godot 4.7.2 headless import: exit 0, no script/import errors. Combined
`test_organic_town_visual.gd`, `test_settlement_visual_architecture.gd` and
`test_settlement_model.gd`: **135 cases passed; zero errors, failures, skips or
orphans; exit 0**. This reruns the complete reviewed delivery on integrated main.
Checks cover asset dimensions/colors, supplied scale/transforms, camera/population
stability, supported history/materials, road/water/plot clearance, no-fit fallback,
condition/construction/reoccupation, preserved extent/defenses and bounded counts.
Local evidence: `/tmp/organic-canonical-import.log`,
`/tmp/organic-canonical-tests.log`, and canonical `reports/report_1/`.

A newly created temporary test override used isolated
`TomorrowAndTomorrow_OrganicTown_Canonical_Test` user data and Dummy audio. It was
removed after the run; no worktree override was copied, and no pre-existing
canonical override existed. All 117 original untracked files and all three existing
save/settings files retained their SHA-256 hashes. No player save was loaded or
written, no runtime preference changed, and no unrelated sidecar was staged or
removed. Tests exited; no Godot process was present before or after this integration.

**No graphical in-engine sign-off or FPS claim.** No second graphical game/test
window, canonical game launch, live-session interruption or remote push occurred.
The wider mature/continent land-cover transition, foreign towns, later traditions
and slope-specific foundations remain outside this slice. Headless supplied
transforms are not rendered-pixel verification. See the handoff's detailed limits.
At this earlier town checkpoint, military work had not started; the reviewed military integration is recorded above.

---

# Final Mac follow-up integration — September 6, 2026

Canonical Mac `main` integrates `60c95ee61e429ce350a1a5be530c794a185d6dfb`
(training/action feedback and ammunition gate consistency), followed by
`eb39198a83abb0d9ae3db0bb95109ab3544bf8db` (obsolete toolbar layer buttons),
both based on the earlier Mac checkpoint `515f191`.

Feedback wrapping now fits 520×67 in the canonical fixture. Exercise status,
completion and cancel availability update while hovered. Ammunition entry/catalog
use the existing authoritative research/adoption gate. Recruiting timing, production
costs, simulation rules and save schema are unchanged. Resources/Borders/Charted
buttons and unused toolbar state are removed; resource controls in Economy/Atlas
and other toolbar actions remain.

Canonical final combined training probe: 32 checks passed, zero failures, exit 0.
An intermediate rerun found a test-only stale button reference across awaited
layout frames; this checkpoint reacquires the current button before clicking.
Canonical onboarding probe passes toolbar absence/default-resource/bounds checks
but exits 1 on the pre-existing “retired Lens was constructed during normal
inspection” assertion. Worker unchanged-baseline log reproduces that Lens failure;
its separate old toolbar bounds failure is absent after cleanup. No full onboarding
pass is claimed, and no Lens/campaign/battle redesign was added to this batch.

All 117 original untracked import sidecars retain their hashes. Tests did not
save/load a player world. Existing before_river_war.save mtime 15:54:52 predates
this integration; no restore or overwrite performed. No QA override copied.
Player PID 3981 was preserved running the earlier Mac build; normal Save & Quit
and canonical relaunch are required to load these follow-ups. No restart or push
performed. This closes the authorized delegated batch; further work stays with
the coordinator. Older checkpoints below describe their historical state.

---

# Mac integration — September 6, 2026

Canonical Mac checkout: `/Users/seanpurtill/Documents/Codex/tomorrow-and-tomorrow`, `main`.
Gameplay commit: `39942ef03111cae82dc6f8975ddf2aba57feab3f`; fast-forwarded from
`7fb7e96288313099af9d5801ae5b5f36441fb627`, including input commit `f15e59f`.

INTEGRATED: native gesture and keyboard map zoom; 10 Hz presentation snapshots;
persistent scalable UI, 3D resolution, shadows and frame limit; persistent music
volume/mute on the Music bus; discoverable confirmed Quit with save failure protection.
Campaign redesign/removal remains PAUSED. No campaign or world-reset behavior changed.

Canonical Godot 4.7.2 headless checks: 24 input and 69 display/music/save/quit checks
passed, zero failures, exit 0. CPU probe passed, exit 0: per-frame schedule batches
211.423/208.960/204.248 ms versus 56.805/55.300/62.295 ms at 10 Hz for 120 paused
process calls; 120 versus 19 snapshot refreshes each. Day/population unchanged.
These are CPU workload measurements, not FPS. Presentation may lag by 100 ms.
Coordinator separately verified 67 graphical checks on Apple M1 Pro and inspected
1280×720 and 1440×900 top/bottom menu captures. No extra graphical launch by integrator.

Save writer review: payload/slots unchanged; sibling temporary file, flush/error check,
then replacement. Open/write/rename errors propagate; Save & Quit remains open on error.
Canonical probes cover replacement success, blocked temporary writes preserving prior
save, and quit failure/cancel/discard paths. No power-loss durability claim is made.

Preservation audit: all 117 pre-existing untracked `.gd.uid` sidecars and the existing
`before_river_war.save` retain their SHA-256 hashes. No QA override.cfg was present or
integrated. Generated probe artifacts remain ignored. No push or player launch performed.
Coordinator owns final relaunch. The in-game release label remains `2026.09.06.2`;
identify this Mac checkpoint by Git commit, not that unchanged label.

See `MAC_DISPLAY_VALIDATION.md` and `MAC_SETUP.md` for controls, worker evidence and limits.

---

# Current integration: 2026.09.06.2

Stable foreign district rendering, from codex/district-hover-fix based on db0419b. Independent district caching and stable visual population eliminate repeated geometry replacement from aging reports, overlapping lookout estimates and other cities' updates. Report uncertainty remains intact. See RELEASE_2026_09_06_2.md for baseline reproduction, GPU verification and exact-scene limitation.

Canonical: C:/Users/sjpur/TomorrowandTomorrow, main. Private remote: https://github.com/sjpurtill-ui/tomorrow-and-tomorrow.git. Includes all earlier integrated work. No other feature batch is active. Held prototypes remain preserved. Player PID50068 was left running with its loaded .1 scripts; normal save/exit/relaunch is needed, never a forced restart.

---

# Historical integration: 2026.09.06.1

Canonical player game: C:/Users/sjpur/TomorrowandTomorrow, main. Includes all prior integrated releases through 4d1c0e6 plus the validated contact-report and envoy-entry changes from codex/contact-dialogue. See RELEASE_2026_09_06_1.md for tests and limitations.

| Delivery | Current status |
| --- | --- |
| Earlier terrain, military units/battles, leaders, diplomacy, opening art/score, neighboring societies and continuing history | INTEGRATED through 4d1c0e6 |
| Dated contact reports and direct leader-audience entry | INTEGRATED in this release; 21 tests and actual envoy-return GPU journey pass |
| Outpost model, Blender authoring experiment, sliced vegetation, superseded military usability rewrite | HELD; preserved in their worktrees, not ready for wholesale integration |
| New feature assignments | None started during this consolidation |

Launch only with tools/launch_game.ps1. Worker prompt: WORKER_PROMPT.txt. A worker handoff is not a player release. Do not infer delivery from file dates or a branch preview. No player/editor process was running at the initial September 6 integration audit; subsequent launch evidence belongs in artifacts/player-*.log.

Everything below is historical. Old process IDs, pending items and "latest" headings describe their dated checkpoint, not the current queue above.

---

# Historical integration: 2026.09.05.16

Nearby connected-land societies in new worlds, objective-led contact investigation, and continuing history after dominance or distress. See RELEASE_2026_09_05_16.md for actual gameplay evidence and limits. Includes .15 artwork/new score and .14 general campaign. Remaining work: WHOLE_GAME_COHERENCE.md. Mac clone/access instructions: MAC_SETUP.md.

---

# Previous integration: 2026.09.05.15

Illustrated eight-choice opening/century-focus screen and the supplied Tomorrow-001.mp3 score. Source codex/opening-screen from553a9ff. See RELEASE_2026_09_05_15.md. Includes .14 general campaign and prior releases. Whole-game coherence work remains separate in C:/Users/sjpur/tt-campaign-coherence and is not part of this release.

---

# Latest integration: 2026.09.05.14

General-led Alderford War: conversation, validated objectives, simultaneous world time, finite logistics, opponent plans, actual battles, reports and replay. Enter through Military → Play General Campaign. All previous integrated releases remain included.

Canonical checkout: C:/Users/sjpur/TomorrowandTomorrow, main. Feature source: codex/general-campaign, base 2961a15. See RELEASE_2026_09_05_14.md for evidence and limits. A running older process keeps its loaded build until exited and relaunched through tools/launch_game.ps1. Worker instructions: WORKER_PROMPT.txt and WORKER_HANDOFF.md. General direction: GENERAL_CAMPAIGN_DESIGN.md.

---

# Current integration checkpoint

## Latest: release 2026.09.05.13

Scouting now explains report timing, contact prerequisites and terrain-blocked recovery.
Army marches validate land routes and report water obstruction and low supply visibly.
Includes all previous integrated releases. See RELEASE_2026_09_05_13.md.

Player checkout: C:/Users/sjpur/TomorrowandTomorrow, main. Loaded PID46888 retains
.6 until a normal save/exit and canonical launcher restart. No forced restart.
Workers should use WORKER_PROMPT.txt and WORKER_HANDOFF.md.
The resumed continuous journey reached day 612 with three natural scout returns,
without foreign contact. This batch is integrated; the broader learnability work
is not certified complete. Current evidence and limits are in PLAYER_JOURNEY_BACKLOG.md.

---
# Historical checkpoints

# Current integration checkpoint

## Latest: release 2026.09.05.11

Connected founding/time controls, supply order reviews and effective garrison
assignment. Includes all earlier integrated deliveries through.10.
See RELEASE_2026_09_05_11.md for exact coverage and limits.

Canonical player: C:/Users/sjpur/TomorrowandTomorrow on main.
Running PID46888 retains loaded.6; save and exit normally, then launch with
its tools/launch_game.ps1 or the Play Tomorrow and Tomorrow desktop shortcut.
The launcher prevents a duplicate player; restarting is never forced.
Workers: use WORKER_PROMPT.txt and WORKER_HANDOFF.md. Older prototypes remain
preserved for selective migration, not wholesale replacement.

---
# Previous checkpoints (historical process IDs and limits follow)

# Current integration checkpoint

## Latest: release 2026.09.05.10

Founding review, focused civic/government reports and diplomatic conversation /
offer / record screens. Real costs, refundable offers and waiting outcomes are
explicit. See RELEASE_2026_09_05_10.md for validation and limits. Includes .7â€“.9.

Player PID46888 retains loaded .6. Save and exit normally, then launch only with
C:/Users/sjpur/TomorrowandTomorrow/tools/launch_game.ps1. No automated restart.
Further journey work stays isolated until verified; prior worktrees are preserved.

---
# Previous integration checkpoint

## Latest: release 2026.09.05.9

Focused inquiry directions/evidence/work-priority screens, wrapping action cards,
and enemy-home occupation capacity are integrated. Details and exact checks:
RELEASE_2026_09_05_9.md. Earlier .7/.8 features are included.

The running player PID46888 retains .6. Save and exit normally, then use the
canonical tools/launch_game.ps1 to load the integrated game. Existing saves and
unrelated changes remain preserved. Further journey work stays isolated until ready.

---
# Previous integration checkpoint

## Latest: release 2026.09.05.8

Focused army command and three-step preparation, actionable recruitment shortages,
first-army intake runtime fix, and equipment manufacture with actual cost previews.
See RELEASE_2026_09_05_8.md for exact validation and remaining journey scope.

The running player PID46888 still has .6 loaded. Save and exit normally, then run
C:/Users/sjpur/TomorrowandTomorrow/tools/launch_game.ps1 to load integrated updates.
No worker preview is the player game. Save and unrelated changes are preserved.

---
# Previous integration checkpoint

## Latest: release 2026.09.05.7

Focused settlement/economy reports, nested Back navigation and actionable water
access are integrated with authoritative city-force capacity rules. Small patrols
cannot sustain a populated-city siege or automatically capture/control it after
battle. Coercive orders require effective control and capacity; old saves remain
intact. See RELEASE_2026_09_05_7.md and PLAYER_JOURNEY_BACKLOG.md.

Running player PID46888 was launched on .6 and has not been interrupted. Save and
exit normally, then use the canonical launcher to load structural updates.
Further army/new-player journey work continues separately until verified.

---
# Historical integration checkpoint

## Latest: release 2026.09.05.6

Continuous actual-world city encounters, faction uniforms and the occupation /
recovery decision interface are integrated from codex/continuous-city-encounter,
base 87d184d, integrated gameplay commit 0df3415. See RELEASE_2026_09_05_6.md for scope and verification.
Verified canonical player launch 18:01:37: PID46888, release .6, SeanTown/day9432/population405.
Canonical checks: 177 passed, two renderer-only skips; exact saved time and save hash preserved.

City approach, siege, assault, round result and return share the same live city
geometry. Friendly and enemy troops have distinct cloth and marked standards.
Occupation policies, resident conditions, movement and destructive decisions have
separate controls and explicit consequences. Existing saves remain compatible.

Outposts, sliced vegetation and unfinished Blender authoring remain HELD.
Prior worktrees and unrelated local changes are preserved. Only tested deliveries
reach main; a stopped worker's partial code is not automatically release-ready.

Use WORKER_PROMPT.txt for new workers and WORKER_HANDOFF.md for coordination.
Canonical player: C:/Users/sjpur/TomorrowandTomorrow on main, launched only via
tools/launch_game.ps1 or the Play Tomorrow and Tomorrow desktop shortcut.
A running process requires a normal save/exit/relaunch to load structural changes.

---
# Historical integration checkpoints

## Latest: release 2026.09.05.5

Battle/siege HUD delivery through worker 018cedd is integrated as 540d1d4
from c89b895 with test project settings excluded. Includes formation orders,
replay, siege controls and linked battle history. Saved notification restoration
preserves fractional time. See RELEASE_2026_09_05_5.md for validation and audit.
The sections below are historical checkpoints, not the current launch record.

Continuous actual-world city encounters and faction uniforms remain PENDING;
no implementation commit exists yet. Outposts, sliced vegetation and unfinished
Blender authoring remain HELD. All prior worktrees/local changes are preserved.
Copy-ready worker prompt: WORKER_PROMPT.txt. Player: canonical main via the
desktop shortcut. A running test scene is never the current campaign.

Verified canonical launch September5 16:56:05: PID3672, source540d1d4,
release2026.09.05.5, --resume-saved. Title and log confirm SeanTown/day9432/
population405. Exact saved time9432.03296121855 passed the isolated resume check.
The disposable siege preview PID51828 closed normally; no worker was stopped.
Original quicksave hash remains unchanged. Latest validation:174/174 cases plus
private-desktop battle/siege interaction probes and actual copied-save GPU check.

Canonical player checkout: `C:/Users/sjpur/TomorrowandTomorrow`, branch `main`.
The OneDrive project is archived. Use `tools/launch_game.ps1` or the existing **Play Tomorrow and Tomorrow** desktop shortcut. The launcher prints the commit it starts. F5 runs the game; F6 may run a preview scene.

Release **2026.09.05.4** is integrated on canonical main (gameplay `3657301`, worker `1d71971`). It includes all prior releases plus direct city orders, visible battle starts, occupation figures, retained scattered-personnel records and compact death summaries. Canonical combined validation: **118 tests passed**. Real GPU mouse probes pass; both renderer-only figure tests also pass. Player launched source `3963fde`, PID41076, September5 14:14:24; title/log confirm .4 and resumed SeanTown/day9432/population405. See `docs/RELEASE_2026_09_05_4.md` for the final launch record. A worker branch alone never updates the running player.

Current saved campaign: September 5 13:45:30, SeanTown, day9432, population405, seed1792400273. The day9049 battle left four occupation soldiers and two scattered, zero killed; pending aftermath is preserved. Previous .1/.2/.3 launch records below are historical, not the current build.

Military readability `cc5ffc5`, rumors `1672447`, Inquiry/Materials/scouting `aba8c73`, occupation `5c39a0f`/`81c38d2`, recovery `d8bf575`, final guards/version `c337a0f`, and isolated spatial report `a9dddbb` are integrated. See docs/RELEASE_2026_09_05_1.md for behavior-specific validation and limits. Canonical combined suite:125 cases pass. Outposts, unrelated economy, sliced vegetation and unfinished Blender authoring remain HELD.

## Consolidation queue â€” September 5

| Delivery | State | Location / evidence |
| --- | --- | --- |
| Strategic charts and dynamic dock tabs | INTEGRATED | Worker `4107fd1` â†’ main `12d16a3`; 64 combined tests + GPU |
| Discovered city intelligence | INTEGRATED | Worker `02a6587` â†’ main `efbff12`, follow-up `691eed6` â†’ `d418704`; 113 combined tests + 14 focused follow-up cases + GPU |
| Zoom terrain fill | INTEGRATED | Worker `1142441` â†’ main `42595fb`; five terrain cases and expanded camera runtime probe pass |
| Military usability redesign | INTEGRATED | cc5ffc5 after explicit reauthorization; live progress/focus/selection and canonical GPU checks |
| Outposts, sliced vegetation, unrelated economy and Blender authoring experiment | HELD | Preserved prototypes below; excluded from the player build |

Historical consolidation session: player PID 65696 started before the integrations; the user later saved and closed it. See the current release/session status above. Save and exit normally, then use **Play Tomorrow and Tomorrow** to load the integrated code. The shortcut's target and working directory were verified canonical. Older process references below are historical checkpoints, not current status.

## Integrated

- Existing terrain, cities, animated armies, battle generals/carnage/cameras, scouting, military progression, civics, historical people, ambitions and diplomacy: retained from the prior reconciliation through `af76241`.
- Player century focus and council recommendations: `69bc384`, from worker `4967e43`.
- Encounter terrain, opposing contact choreography, clearer battle losses and persistent injured veteran workforce capacity: `3485f1b`, from worker `64d7c7f`.

- Civic and foreign leader conversation continuity: `2dff85c`, from worker `e11302c`; 24 civic context messages, recent decisions, persistent foreign discussions and recoverable failures.
- Scout returns preserve simulation speed and keep reports available for later reading: `cf3a058`. Recruitment outcomes restored to first report page and unused HUD label removed: `4bc66f4`.

## Preserved pending work

- Frontier outposts: uncommitted isolated prototype in `C:/Users/sjpur/tt-frontier-outposts`; explicitly not ready for the game. No autoload, shared state, UI or save hooks are integrated.
- Blender contact clip authoring experiment: preserved in `C:/Users/sjpur/tt-battle-contact-landscape`; missing source blend dependencies prevented export. Existing runtime animation assets remain in use.
- Sliced vegetation: uncommitted, unvalidated prototype in `C:/Users/sjpur/tt-sliced-vegetation`, held outside the player build.
- Older worktrees are retained for traceability. Many commits were cherry-picked/reconciled, so differing hashes do not imply missing features. Do not bulk-merge their old versions.

## Ownership and delivery

One integrator owns main. Every worker starts from the current integrated main in its own `codex/<task>` worktree, reports file ownership, tests, and returns a task-only commit. A worker's preview is not a player release. Update this file and `FEATURE_RECONCILIATION.md` when integration is verified. Keep unfinished prototypes explicit; never claim all planned features shipped.

Preserve saves, existing uncommitted files and active player sessions. A running process may still contain older scripts/state. Save and restart after structural integration; do not kill a live game to make it look current. No automatic folder synchronization or copying from the archived OneDrive tree.

Copy-ready worker instructions are in `docs/WORKER_HANDOFF.md`.

## Verification at this checkpoint

The broad suite ran 522 cases (two skipped). It exposed four assertions in one recruitment-report test and an orphan HUD label. Both causes were fixed. The final combined focused run passed 66 cases with zero errors, failures or orphans (dialogue continuity, 39 UI cases, scout return speed, injuries/geometry and century focus). The earlier broad suite covered century-scale rivals, billion-population bounded state and military accounting. It was not rerun in full after the isolated fixes.

Actual save/load, opening/century renewal, GPU battle graphics and foreign diplomacy probes passed. The offline pronouncement probe now explicitly disables API access for its offline cases and passes. Worker HTTP failure/retry and four live Terra conversation turns passed before integration. Engine shutdown still reports two ObjectDB instances and one resource in the final save probe; no clean shutdown claim is made.

Revised battle demo was visibly replayed from canonical main and verified via a fresh screenshot. It is explicitly labeled BATTLE DEMONSTRATION. The separate campaign process and editor were preserved. Save and restart the campaign through the canonical launcher to load all integrated structural changes.

## Latest visual refinement

Integrated `1af3fbe` from `codex/battle-planted`: fighters stay planted after approach, use varied guarded weapon strikes and small upper-body hit reactions instead of reciprocal whole-body sliding. A 100-frame/five-second GPU temporal probe measured zero root drift while attack and guard poses changed; the battle graphics regression passed. No casualty, population or save rules changed.

## Sustained sieges and protection diplomacy â€” September 5

Canonical implementation checkpoint: `7964a29` (sieges `8077fa3`, protection/leagues `60910ec`, combined relief persistence tests `7964a29`). These changes are integrated into main, not yet loaded in a player process started at `883a8f2`. Preserve its session; save and relaunch through the canonical launcher when ready.

- Fortified home settlements can hold through sustained sieges, including the unattended threat deadline. Ordinary raids and occupation defenses keep their existing controls. A stationed field army can choose **BESIEGE SETTLEMENT** in foreign civilization actions, then use **WAR PLANNING** to continue, negotiate, seek allied relief, assault/sortie, or withdraw.
- Blockade reduces actual home harvest and the target region's share of rival food production. Existing reserves bridge shortfalls; rival aggregate demography responds after reserves can no longer bridge lost production. Supply and besieger endurance limit the investment. Army movement is locked during investment, and withdrawal uses its physical return route. Starting a siege does not transfer people or territory.
- Protection treaties and leagues require provisioned envoy negotiation and consent. Existing promises cover verified future defensive attacks, not retroactive aid for player-started wars. Independent members can disagree, leave, or refuse unaffordable relief. See `PROTECTION_FACTIONS_HANDOFF.md` for the diplomacy model and limits.
- Delivered relief is a one-use receipt, a separate allied camp, and a physically timed return. Donor military/food accounts stay separate from player population. Camps consume 0.55 Food per troop per day, matching the donor's reserved thirty-day provisions. Camps affect access and do not participate in tactical casualty rounds; all surviving camp personnel return through the same donor ledger.
- Enemy stores are never displayed as a live exact number: the siege view shows returned, dated observations or unknown. Orders precede detailed assessments in the dock. Reputation abbreviations were replaced by explicit Mercy/Fear/Grievance labels.

Validation on canonical main: **98 cases, zero errors/failures/skips/orphans**, across siege progression, real relief integration plus inherited commitments, dialogue continuity, 39 UI cases, military accounting, injuries, and century focus. Actual full-world `SAVE_LOAD_PROBE PASS`; GPU `SIEGE_UI_PASS`, capture inspected and test window closed. Import clean. The worker also supplied 96-case civilization/century regression, final 19 commitment/dialogue cases, actual persistence, live Terra negotiation and council GPU evidence before integration. No repeated full 522-case claim.

Current limits: one player siege at a time; no rival-only playable siege scenes, automatic foreign-only relief combat, ocean transport/pathfinder, or siege of a third party's occupied territory. Foreign food/demography retains the simulation's monthly resolution. The existing camp/army records remain bounded; history retains 24 sieges.

Strategic charts are newly authorized but still being implemented in `C:/Users/sjpur/tt-strategic-charts`, branch `codex/strategic-charts`, base `883a8f2`. They are not in this checkpoint. Its held vegetation prototype remains held, as do outposts and other unrelated economy prototypes.

## Scouting archive and military audit â€” September 5

Integrated scout worker `6e6b6d0` as `d0315c9`. World / Scouting shows up to three highlights from the latest eight returns plus **Expedition Archive**. The archive renders five cards per page, supports saved-text search (including exact `party N` / `day N`), All/Findings/Routine/Losses/Unread filters, and significance/newest sorting. Each card opens the retained full report; Back to Archive restores the query, filter, sorting and page. Routine evidence is summarized on the findings page and retained in Journey & Accounts.

Full report retention increased from 24 to 256; existing reports are preserved and no knowledge/deposit/formation simulation was changed. Unread metadata begins with new returns; older records have unknown review status until explicitly opened. Reports already evicted from older saves cannot be restored. Earlier map/contact/resource knowledge remains under its existing authorities. The UI states the retention limit rather than implying an infinite archive.

Large repeated cover art is removed from the findings page. Journey details may show a 112px illustration selected only from saved terrain words. Forest, river, mountain and desert records select matching existing art; absent terrain evidence gets no decorative fallback. The actual saved route chart remains available. No new illustrated landmarks or map evidence were invented.

Canonical validation: 71 cases pass with zero errors/failures/skips/orphans (archive, 39 existing UI, return-speed, siege and real relief tests). GPU archive passes at the real 540px dock width: 256 reports, 5 rendered cards, 29 search matches, empty-result behavior. Worktree GPU navigation also verifies opening a report and returning preserves search/page. Probe windows closed; player/editor preserved. No-autopause behavior remains intact.

Military audit `docs/MILITARY_CONSOLE_AUDIT.md` and `tests/military_console_audit_probe.tscn`: reproduced hover-induced frozen progress labels, fractional work versus calendar-day ambiguity, and condition-based BROKEN semantics. Proposed plain-language status/grouping fixes are documented. No military usability fix is claimed integrated by this audit.

Historical session at this earlier checkpoint: PID 54444 at 883a8f2; see the top of this document for current session status. Save and relaunch through the canonical launcher to load later features; it was not silently restarted. Newly authorized charts, discovered-city intelligence, and measured zoom-fill work continue in separate worktrees with explicit shared-file ownership. Held outpost/economy/vegetation prototypes remain held.

## September 5 â€” independent city intelligence

Worker `02a6587` integrated as `efbff12`. Foreign cities use the existing five strategic urban regions per polity, independent markers and hit targets, and per-observer dated reports. Discovering one does not expose the others. Estimates age and remain frozen between observations; scouts, envoys and army runners deliver reports through their return paths. AI player-city knowledge uses the same evidence model and gates targeting. Existing secondary-city defense simulation remains absent rather than fabricated; the military campaign still targets the player primary city. Regional food outlook is not a per-city warehouse ledger. Full bounds, save compatibility and limitations: CITY_INTELLIGENCE_HANDOFF.md.

Canonical eight-suite 113-case regression passes. This includes actual city-intelligence and strategic-history save/load coverage. The worker's full 118-case civilization/century run finished with 117 passes and one founding-focus visibility failure, zero runtime errors. Both 36,500-day scale simulations passed, including billion-population bounded state. The one-line visibility guard was restored in `d418704`; the failed case plus all 13 city-intelligence cases then passed canonically (14/14). The entire 118-case suite was not repeated after that isolated fix. Canonical city-report GPU capture and three independent hit targets pass; probe exited and stderr is empty.

## September 5 â€” zoom terrain streaming

Worker `1142441` integrated as `42595fb`, preserving independent-city marker/hit-test code, chart daily sampling, and the scouting archive. Obsolete camera jobs are canceled, a geographic coverage pass precedes full detail, four completed meshes and their river-height fields are cached, and the world mesh remains visible outside the streamed rectangle. Save format unchanged.

Canonical five terrain cases pass; expanded camera probe passes smooth/anchored zoom, north reset, cancellation, coarse-to-fine scheduling and bounded exact mesh reuse. Camera probe shutdown reports two ObjectDB instances and one resource still in use; no clean-shutdown claim. Worker GPU comparison measured zero uncovered frames versus up to 338, and cached revisits of 40â€“81ms versus seconds. Cold fine detail still takes roughly six seconds, and some frame spikes remain. Synthetic million-person fixture is not a loaded mature campaign benchmark. See ZOOM_PERFORMANCE_HANDOFF.md for comparable measurements and limits.

All agreed completed deliveries are integrated; no further feature expansion is underway for this consolidation. Military usability and older unfinished prototypes remain HELD.

Final canonical GPU zoom run completed all eight transitions with zero uncovered frames; screenshots inspected. Its test process exited. Like the camera probe, it reports two ObjectDB instances and one resource in shutdown cleanup; no new script/parser errors appeared. This capture run is visual/integration evidence, not the screenshot-free comparative benchmark above. Player PID 65696 remains the only canonical campaign process and was not restarted.


September 5 follow-up integrated: fd7b360, version 2026.09.05.2. Reported-settlement close rendering and complete-batch recruitment/readiness corrections. Canonical 78-case regression and both actual-save GPU probes pass. See docs/RELEASE_2026_09_05_2.md for current campaign blockers, evidence, and limits.


Release2026.09.05.3 integrated187bea5: polished foreign city reports, named city army arrival, explicit scout labels and successful deliberate attack/siege starts war without declaration. Canonical88tests +actual-save GPU verification pass. See docs/RELEASE_2026_09_05_3.md; peacetime trespass response remains unimplemented.
