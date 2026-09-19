# Government auto-officials handoff

Status: READY

Base: `f0e9f559ad79625a6d28497b8237d1ab6c44572e`

Branch: `codex/government-auto-officials`

Owned scope: GovernmentPeopleSystem central and local succession; command-rail navigation and icons; Government, Civilization, Settlement and Economy dock links; focused government tests. `local_terrain.gd` changes only register the new provider and reroute the existing council notice.

## Behavior

- Government is a separate command-rail destination with a drawn civic-building icon.
- Every rail destination uses a distinct drawn pictogram instead of an ambiguous Unicode symbol.
- Every unlocked central office fills automatically from living public figures in a stable seed-dependent order. Local leadership remains automatic.
- The normal Government and Settlement flows no longer expose candidate selection.
- Officeholders show durable traits and their three strongest visible skills.
- The player may dismiss or execute central and local leaders. Succession is immediate when an eligible person exists. Executions remove exactly one aggregate person and impose larger legitimacy and cohesion costs.
- The public-figure name banks are materially broader in length and sound. Existing named people in saves are unchanged.

## Validation

- `test_government_people_system.gd`: 34/34 passed.
- `test_government_hud.gd`: 2/2 passed.
- The combined appointment suite was not used as evidence because the isolated worktree lacked imported scouting textures; its failure was unrelated resource discovery, before test execution. The focused Government suite and HUD provider suite compile and execute the changed systems.

## Compatibility and limitations

No save migration is required. Existing officials, person IDs, skills and traits remain valid. Loading a save with an unlocked vacant office fills it automatically. Legacy appointment APIs and old diagnostic panels remain for compatibility and probes, but normal player navigation does not expose them.

The new icons are code-drawn and theme-aware; no image assets or import changes are involved. No broad graphical audit was run.
