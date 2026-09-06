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
