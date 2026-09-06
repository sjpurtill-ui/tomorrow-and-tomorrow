# Current journey scope audit — release .13

The sustained review resumed after .12. Three expeditions returned in one genuine
new world, at days 45, 522 and 612, with ordinary simulation time and isolated
save/resume. First planned 30 days took 35; second planned 365 took 477.
The third eastward 365-day option was terrain-blocked; a 90-day option worked.
No foreign polity was encountered. First contact and continuous diplomatic dispatch
remain unverified: generated homelands can be thousands of kilometres away and
scout routes must approach within 58 km. No neighbors or contacts were injected.
Do not continue unbounded random expeditions merely hoping for a contact.

Completed this batch: readable return timing/contact prerequisites; truthful full
route blockers and shorter-trip recovery; visible map-order feedback; direct
army water-route checks, in-transit stopping and runner reports; low-supply advice.
130/130 tests passed across nine suites. GPU first-return/archive review and
coastal water rejection, valid inland march and supply review completed.
The coastal test uses authored placement and chart coverage on actual terrain;
it does not establish naturally unlocked military progression. East heading was
selected through the OptionButton signal; dispatch and elapsed-time controls
used normal UI. Route sampling is not automatic pathfinding or naval transport.

Remaining: natural first contact/reachable diplomacy; remote AI quality; broader
campaign balance and actual novice observation. Secondary records still scroll.
This batch does not claim the entire gameplay/learnability objective is finished.

---
# Historical .12 audit (superseded status)

# Current journey scope audit â€” release .12

Status: representative planned journeys and concrete review findings complete.
This integration pass stops after the final canonical import and save/process
check. The remaining follow-up coverage below is not an active background task.

Acceptance principle: both the mechanic and the act of playing must make sense.
Passing tests does not establish that the game is great or intuitive to a novice.

| Journey | Concrete coverage | Limit |
| --- | --- | --- |
| Founding to early development | One fresh world, actual choice/site/name, normal time through Hearth Circle, water/research direction, waiting army order, scout departure | About 10 days; no continuous founding-to-empire claim |
| Army preparation and supply | Actual UI recruitment, daily instruction, deployment; equipment/ammunition/carts/repair costs, reservation and work completion | Authored supplies/knowledge for later workshop options |
| Field-army map orders | Mouse selection, right-click dry charted destination, ordinary-time arrival, runner delivery, blocked disband, return and home arrival | One local land route; not all terrain or supply disruption |
| Civic and foreign decisions | Focused conversation/reports/preferences, reviewable offers, exact costs, toggles and actual dispatch | Remote AI quality not validated by AI-off tests |
| Siege/battle/occupation | Same live city world through siege/assault; actual equipped battle victory, sufficient surviving force, garrison detachment, real aftermath and occupation | Authored battle fixture; not unlocked by the fresh-world run |
| Occupation and recovery | Real copied-save decisions, preview without mutation, commit/cooldown/stale review; recovery prepare/commit/cancel | Representative policies and two sizes, not every possible history |

Review fixes completed: covered time controls; legacy founding labor panel;
premature local leadership actions; fractional garrison requirement; stale
post-battle map count; report-age clarity; literal garrison headcount versus
adjusted capacity. Test overlay chrome removed from final occupation capture.

Follow-up coverage worth scheduling:
- Longer continuous settlement growth through first foreign contact and diplomacy.
- Multiple field routes, water crossings/path constraints, interception and supply
  disruption. The local march check does not certify a general land pathfinder.
- Late-unit and large-campaign balance, remote civic interpretation quality.
- Observe actual new players attempting these tasks without expert prompting.
- Secondary long records/training detail can still scroll on small windows; core
  tested order controls remain visible. Further layout review can target those.

Evidence: RELEASE_2026_09_05_7.md through RELEASE_2026_09_05_12.md and their exact
artifact logs. Historical backlog entries below describe earlier checkpoints;
they do not override this current status.

---
# Historical progress log

# Player journey acceptance and evidence

Base: canonical main 6fb1802, release 2026.09.05.6. Worktree:
C:/Users/sjpur/tt-focused-player-journeys, codex/focused-player-journeys.

Every change must pass both questions: does the mechanic make sense, and does
playing it make sense? Explain actual causes, requirements, costs and results.
Prefer focused screens with context and Back over dense dashboards. Retain depth.

## Acceptance
- First settlement overview presents leadership/direction before accounting.
- Only one dock report is visible; Back restores its parent tab and position.
- Routine work remains delegated; advanced charts and controls remain reachable.
- Small-force presence never implies effective city control. Siege, capture and
  coercive actions enforce their requirements in the simulation, not just buttons.
- Test normal/small renders and real actions. Preserve saves and the running game.

## In progress
- Focused settlement/economy reports and nested Back navigation.
- Population/resistance/supply/readiness control; perimeter-based siege capacity;
  victory without enough occupation survivors; coercive action capacity/cooldown.
- New force-capacity regressions and rendered journey checks.

## Remaining journeys
- Army creation, training, provisioning, deployment and map orders.
- First founding choices, resource recognition and research direction.
- People/civics/diplomacy, prerequisites and action feedback.
- Siege/aftermath/recovery under both viable and unsupported control.

No new batch is integrated yet. Add exact test/render evidence as completed.

## Verified batch: release .7
Settlement/economy focused navigation, water action/report flow, city control rules
and occupation capacity feedback are ready for integration. Combined187 passed,
two renderer-only skips; GPU focused-water-verified, focused-shell-verified,
occupation-capacity-ui and copied campaign checks passed. Earlier in-progress
list describes this batch's origin; remaining journeys above stay active.

## Verified batch: release .8
Army composition/recruitment/deployment split, real first-army runtime fix,
recruitment shortage routes and manufacture previews. 171 passed /2 renderer-only
skips, real GPU army and equipment actions, water/shell regression and copied-save
resume passed. Details: RELEASE_2026_09_05_8.md.

## Next checks
- Enemy victory at player home must require surviving occupation capacity too.
- Ammunition/transport order cost previews and field orders/provisioning.
- Founding and inquiry: focused first choices and actionable discovery requirements.
- Civics/diplomacy: precise costs, commitments, feedback and focused navigation.
- Remaining siege/recovery flow under viable and unsupported control.

## Verified batch: release .9
Focused inquiry directions, explicit shares/evidence/research work, wrapping action
cards, and enemy-home capture capacity. 123 passed; inquiry, army and command-shell
private GPU walkthroughs passed. See RELEASE_2026_09_05_9.md.
The enemy-home capacity item above is now complete; remaining journeys stay open.

## Verified batch: release .10
Founding review/commit; focused civic and government reports; diplomatic offer
costs, toggles and actual dispatch. 80 passed, three GPU journeys at two sizes,
copied-save resume exact. See RELEASE_2026_09_05_10.md.
Remaining: ammunition/transport previews, field orders/provisioning, and continuous
siege/recovery decision checks. Broader edge cases remain ongoing, not certified
merely by the three representative journeys.


## Verified batch: release .11
Ammunition/cart/repair previews and real production, first-founding leadership
availability, reachable time controls, and fractional garrison correction.
177 passing cases; supply/army/occupation/recovery/shared-world GPU evidence.
Actual equipped battle victory -> natural capture -> real garrison -> actual
aftermath -> occupation passed. Coherent fresh-world founding -> ordinary time
-> Hearth Circle -> water/research direction -> army/scouting actions passed.
These replace the corresponding pending items above. See release.11 evidence.

Remaining coverage: longer continuous settlement growth and first foreign contact,
field movement/return across varied terrain and supply disruption, late-unit
balance, remote civic interpretation, and genuine novice observation. Earlier
synthetic aftermath fixtures are not evidence of natural occupation; the new full
victory journey is. Secondary long records can still scroll on small windows.
