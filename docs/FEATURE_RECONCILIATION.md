# Canonical feature reconciliation — 2026-09-05

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
