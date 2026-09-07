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
Military work has not started; this integration stops for originating-task review.

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

# General campaign integration — release .14

Source codex/general-campaign from canonical 2961a15. Added the bounded authored Alderford War without replacing existing terrain, civics, force ownership or combat resolution. Verified full victory/defeat, real UI objective/withdrawal/recovery/save loop, 56 combined tests and seven actual Terra exchanges. See RELEASE_2026_09_05_14.md and INTEGRATION_STATUS.md. The full historical campaign remains outside this slice.

# Canonical feature reconciliation — 2026-09-05

Latest consolidation: release 2026.09.05.5 integrates the battle/siege HUD series
through 018cedd, excluding its isolated project settings. The branch audit found
other differing historical hashes already reconciled as described below. See
RELEASE_2026_09_05_5.md and INTEGRATION_STATUS.md for current scope and evidence.

The playable checkout is `C:/Users/sjpur/TomorrowandTomorrow`, branch `main`.
This record distinguishes recovered behavior from old implementations that have
been superseded. A newer file timestamp is not a reason to replace an entire system.

## Civic and leader work

Reconciled the civic changes from `d085c74` through the consolidation in
`d0f2ab3`, and the statistical decree changes in `b5d794d`, into the current
GovernmentPeopleSystem settlement conversation path:

- Conversational first-person responses, eight recent turns of bounded context,
  and adequate response budget. Questions remain discussion; only explicit
  instructions reach deterministic execution checks.
- Clear orders proceed without repeated mandatory ethical confirmations or a
  personality veto. Leaders retain objections and relationships; population,
  resources and institutional capacity still constrain implementation.
- Six validated immediate metric estimates, with uncertainty and causal reasons.
  Estimates are simulation inputs, not measured causal facts. Food, water, labor
  and production continue through their existing systems.
- Exact counted actions affect the eligible aggregate population once, record
  their actual result and death ledger linkage, and do not become standing policy.
- Follow-up reports distinguish immediate receipts from observed later changes.
  Existing saves retain their records; no retroactive events are fabricated.

The old separate `LeaderConversation` autoload and office popup are not restored:
the current settlement conversations already own named leaders, history, intent
clarification, execution and follow-up reports. Restoring the alternate UI would
create another authority and a separate conversation store. The older standalone
draft/Issue panel itself is not part of the current interface.

Validation: 71 civic/directive/government tests, city-civic runtime probe, and
whole-game save/load probe passed. The live paid API probe is available but was
not run during this reconciliation. Existing renderer/ObjectDB shutdown leak
warnings remain in runtime probes.

## Other scope

Animated armies, historical figures, ambitions, community networks, diplomacy,
current terrain and the subsequent graphics work were integrated before this
pass. Expedition findings, mobility and billion-scale verification were integrated from the scoped handoff below. Combined validation follows.

See `WORKER_HANDOFF.md` for ownership, worktree and integration rules.

## Combined canonical verification

After civic `fb5c118` and expedition/mobility commits through `95a6b0d`:

- 272/272 tests across nine suites passed (report 728, 3m14s), covering civics,
  directives, government, expedition findings, civilization, military development,
  settlement architecture and warfare presentation. The civilization suite
  includes a century with billion-person populations and bounded save records.
- Canonical population-scale probe passed with nine cohorts and one formation;
  whole-game save/load passed after the combined changes.
- GPU expedition report probe passed; both report and journey captures inspected.
  Five painting assets are imported. The real return handler opens the same
  report provider, also reachable through World reports.
- GPU warfare-map runtime probe passed, including current route geometry and hover.
- Existing shutdown resource leaks remain. No paid API call was made by this pass.

The worker's additional 133-test demographics/government/architecture sweep passed
in its isolated checkout; this is supporting evidence, not additional canonical
coverage claimed on top of the 272 tests above.

## Expedition, mobility and scale handoff (worker evidence)

# Feature reconciliation — September 5, 2026

Worker checkout: `C:/Users/sjpur/tt-feature-reconciliation`, branch `codex/feature-reconciliation`, base `9c0aaacd7bc6c37dcbc705ead87cccf06119f157`.

This is a feature inventory, not a claim that a passing subset proves every game feature complete. Canonical integration and editor launch belong to the integrator.

| Work | Evidence and disposition |
| --- | --- |
| Billion-scale population, resources, food, labor and military counts | Already in base. Population probe passes at one billion, nine cohort keys, one 500,000-person formation after one million recruits, and three consequence days. No ordinary citizen registry restored. |
| Bounded civilization simulation | Already in base. Century probe passes: 23 rivals, 115 regions, 1,217 turns, bounded events and 446,929-byte exported civilization state in this fixture. |
| Bounded named leaders | Preserve current GovernmentPeopleSystem and its 96-person ceiling, rather than restoring the superseded institutional-only or 512-citizen implementations. |
| Expedition chronicles and route chart | Omitted from base; restored selectively from 818d9d8, followed by later decisions. Two report tabs, actual days away and grounded discovery records. |
| Five expedition paintings | Omitted from base; restored from 12a60ea plus original dawn cover. Static reusable art, no runtime image-generation charges. |
| Retired illustrated landmarks | Apply 1d7b045 after the chronicle to preserve the later retirement decision; old artwork is archived, not deleted. Existing genuine findings survive load. |
| Mounted scout pursuit and sustained march speeds | Omitted from base; restored from 8cb853b. Army proximity, speed, readiness and scout evasion affect interception; mixed columns respect their slowest element. |
| Scout hover presentation | Selectively reimplemented from 37d92d9/b9c9ae3. Hover-only route captions replace permanent labels. Preserve newer grounded ribbons, correct directional triangles, layer priorities, scale cache and zoom handling instead of replacing the whole renderer with the old overlay. |
| Battle view and unit builds | Already in base: 27 models / 108 animation clips verified. Military UI exposes Inspect in 3D and View Battle. Historical appearance variants are not all separate recruitable combat classes. Battle probe passes with a 192-figure ceiling. |
| Decree statistics / remaining civic checkpoint | b5d794d and d085c74 audited separately by canonical integrator; do not restore an obsolete duplicate LeaderConversation authority. Not claimed complete by this worker. |

## Verification in reconciliation checkout

- Import completed; no parser failure observed.
- Expedition, civilization and military-development suites: 92/92 pass. Civic implementation suite separately: 4/4 pass. An initial mistyped civic test path was corrected and rerun; it was not counted as coverage.
- Population and civilization scale probes pass (figures above).
- Scout gamble dispatch/return probe passes; status calls measured in microseconds in this fixture.
- Warfare runtime passes headless and GPU, preserving route geometry/direction tests and asserting hover account presence / permanent labels hidden.
- All 27 model imports and 108 animated clips pass verification.
- Battle graphics probe passes combat invariance, metadata, casualties, reset, retreat, pause, save and fixed visual count.
- Whole-game save/load probe passes. Only dedicated QA slots used; player saves and running session untouched.
- Actual report dock GPU probe passes and captures both tabs and four alternate paintings. Inspected `artifacts/expedition-report.png` and `artifacts/expedition-journey.png`.

Existing Godot shutdown texture/RID/ObjectDB leak diagnostics remain on several graphical probes. Passing assertions do not establish unlimited-world performance or zero leaks. Paid API behavior is not covered by these offline checks.

## Integration

Review and cherry-pick this branch's task commits in order. Shared hunks include civilization_system.gd, military_campaign.gd, local_terrain.gd, dock_blocks.gd and save_load_probe.gd. Preserve newer integrator civic work when resolving. Do not copy whole systems from the consolidated/archived branch. Before announcing shipment, verify the main report component exposes both tabs, five asset paths exist, the actual return handler opens that component, and the canonical combined tests pass.

User requested visible Godot editor and game with supported built-in external-script reload / live scene synchronization after integration. Preserve any unsaved current session; ask before replacing it if necessary. Worker did not launch a preview as the player game.


## Combined checkpoint: century, battle, conversation and scout returns

The authoritative main now includes `69bc384` (century choices), `3485f1b` (battle terrain/contact and persistent veteran injuries), `2dff85c` (leader dialogue continuity), `cf3a058` (noninterrupting scout returns) and `4bc66f4` (first-page recruitment outcomes/HUD cleanup). Earlier eight-turn civic context is expanded to 24 messages plus recent decisions. See INTEGRATION_STATUS.md for validation and explicit held prototypes; no folder overwrite or blanket old-branch merge was used. Player saves and live campaign were preserved.


## September 5 — sustained sieges and independent protection leagues

Integrated siege worker `1f10c0d` as `8077fa3`, diplomacy worker `4ce8a64` as `60910ec`, and real relief/save integration tests `d727f9d` as `7964a29`. Canonical 98-case checks, world save/load and GPU siege UI pass. These extend the existing food, population, army and ForeignDiplomacy owners rather than creating duplicate simulation authorities. Main retains all previous terrain, battle, injury, century and dialogue changes. The open player from `883a8f2` is preserved and needs a save/relaunch to load structural changes. Details and limits are in docs/INTEGRATION_STATUS.md; chart work is pending, held prototypes remain excluded.


## September 5 — scalable scouting archive

Integrated `6e6b6d0` as `d0315c9`; military console audit `ee0283b` as `de1d41d` is evidence/recommendations only. Searchable five-card pages, 256 full reports, explicit review/retention semantics, compact recent highlights, terrain-evidenced detail-only art. Canonical 71-case checks and GPU archive pass; prior siege/protection code preserved. Chart/city-intel/zoom-fill workers continue separately. See INTEGRATION_STATUS.md for checks, limits and restart status.

## September 5 — consolidation of tested deliveries

Worker strategic charts `4107fd1` integrated as `12d16a3`. Both scout_archive and trend_chart renderers are retained in the shared dock; dynamic provider tabs expose Economy Wealth and Military Supply. Canonical combined 64 cases pass, plus muted GPU chart layout/range/hover checks. The player session is preserved; a normal save/exit/relaunch is required for newly integrated scripts. See INTEGRATION_STATUS.md for the current queue and held unfinished work.

City intelligence `02a6587` integrated as `efbff12`, preserving archive retention/review and chart sampling. The combined eight-suite 113-case regression passes. Independent discovered cities and reciprocal dated evidence extend existing simulation/save owners; see CITY_INTELLIGENCE_HANDOFF.md for scope and limits.

Follow-up `691eed6` → `d418704` restores the existing intelligence threshold for exposing founding focus. Canonical targeted 14/14 cases pass. Worker century and billion-population runs passed; its full run was 117/118 before this isolated guard fix, not an unqualified 118/118 claim.

Zoom streaming `1142441` → `42595fb` cancels obsolete work, fills geography before detail, retains outside coverage and caches four completed meshes. Canonical five terrain cases and expanded camera runtime probe pass; existing city/chart/scout hooks preserved. Full limits and benchmark evidence are in ZOOM_PERFORMANCE_HANDOFF.md. The military usability rewrite remains held and is not part of this release.
