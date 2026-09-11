# Ancient scouting window

Status: READY for sole-integrator review from base `ede2e04ea33fdb95e1e8c443dcd0d9b9c6a7121e`.

Worktree: `/Users/seanpurtill/Documents/Codex/tt-ancient-scouting-window`  
Branch: `codex/ancient-scouting-window`

## Player behavior

The accepted ancient Scouting mockup is implemented in the actual native scouting window. Original expedition artwork, a clay surface, Cinzel headings, mineral colors and a pebble slider replace the generic teal form. The live population commitment and two purposes sit side by side on larger screens and stack on narrow screens. Short party rows show personnel and planned return timing; opening a row reveals its destination, provisions and expected duration. Expanded details scroll into view and remain open across refreshes. Their controls are retained rather than rebuilt every day.

A returned-find card reads the actual collection, with the approved selected-stone image only for a Stone Selection specimen or artifact. Oral traditions and other subjects use their type symbol rather than an unrelated object. Items still carried by absent parties never appear. The Brought home action opens the existing collection window. City intelligence remains available under Details.

Recruitment visits remain distinct from household invitations. A compact invitation status opens to the actual housing, food, water or reception explanation. The header close, fixed Done action, Escape and map click dismiss normally through the existing caller. Empty windows shrink to content; the scroll area keeps actions reachable at small sizes. Existing controls still issue the same standing policy; merely opening, refreshing, expanding or changing presentation cannot dispatch a party, spend food, reveal fog or create a find.

The primitive expedition painting is retired when either knowledge or production reaches the existing industrial capability band. That fallback uses neutral expedition scenery. This is **one shipped ancient window**, not the complete six-era skin system or a redesign of every window. Later-era material systems and subject-specific art remain separate ongoing work. The painting illustrates scouting, not the geography or literal party size of the current world.

## Validation

Godot 4.7.2, explicit worktree path, private `TomorrowAncientScoutingTests` userdata. All **59 cases pass**, zero errors, failures, skipped cases or orphans, across:

- `test_ancient_scouting_window.gd` — 7 cases: live/externally changed policy, no side effects, retained party controls, overdue privacy, actual returned subject artwork, small-screen containment, existing parties after stopping, advanced-art fallback (some checks share a case).
- `test_scouting_staff.gd` — 18 cases.
- `test_society_exchange.gd` — 26 cases.
- `test_scout_route_planning.gd` — 8 cases.

Exact invocation:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/seanpurtill/Documents/Codex/tt-ancient-scouting-window --script addons/gdUnit4/bin/GdUnitCmdTool.gd -a tests/test_ancient_scouting_window.gd -a tests/test_scouting_staff.gd -a tests/test_society_exchange.gd -a tests/test_scout_route_planning.gd --ignoreHeadlessMode
```

Final worktree log: `artifacts/ancient-scouting/worktree-tests.log` (18.462 seconds). Headless checks are not claimed as mouse-input tests.

Native `python3 tools/macos_capture/run.py ancient_scouting_probe` passes and exits through the existing verified background harness. Its allowlist now includes this exact probe and selects the matching private userdata name. Canary: visible=0, active=0, policy=2; the private Godot confirms guard loading and blocks four window/activation actions. Installed Godot and normal release signatures are unchanged. No player or editor was opened or stopped.

Native captures and actual input cover 1440×1000, 960×720 and 340×640: purpose button, allocation keyboard step, invitation disclosure, party disclosure and scroll visibility, retained controls after advancing a day, map/close/Done/Escape dismissal, empty state and advanced-art fallback. The exact runtime widget is used; sample state belongs only to the isolated probe. Reviewed captures are in `artifacts/ancient-scouting/`; logs in `artifacts/macos-background-capture/`.

## Scope and integration

Runtime ownership: `scripts/hud/scouting_policy_panel.gd`, new `scripts/hud/scouting_window_art.gd`, the three accepted scouting JPEG assets and bundled Cinzel font/OFL. Test ownership: one new regression suite, native probe/scene and the narrow capture-runner allowlist update. No shared simulation hotspot changes. Other worktrees are untouched.

Save compatible: no save schema, migration, scout path, population, research, reception, calendar, economy or opponent-rule changes. The existing caller retains its pause/resume behavior. No campaign performance claim; this avoids daily UI-node churn while the window is open, but does not solve mature-campaign frame stalls.

The font is bundled with its SIL Open Font License; provenance is recorded in `assets/ui/scouting/README.md`. Generated captures/import caches are excluded from commits. Remove the owned override before integration packaging. Package through the normal canonical build-only launcher after combined validation; this delivery does not authorize a player restart.
