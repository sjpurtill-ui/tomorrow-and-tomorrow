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
