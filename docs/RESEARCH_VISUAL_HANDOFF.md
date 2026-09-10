# Illustrated research and discovery announcements

Task branch: `codex/research-visuals` in `/Users/seanpurtill/Documents/Codex/tt-research-visuals`, based on canonical `93cc5f578411c0ed8e9fa5dd70a195adefefbf08`. Sole integrator; no concurrent workers.

## Behavior

The Inquiry tree entry opens an illustrated research workspace. Being researched shows each live subject, named supervising officeholder, actual equivalent workforce, evidence progress and short bottleneck. Knowledge tree preserves prerequisite links and hides redacted future outcomes by default; Established shows learned effects. Field, leader and known-name filters work across views. Selection, live cards, scroll and tree camera survive ordinary progress updates. Small windows open a selected inspector at full width with a Back button. Research staffing and explicit focus use existing game actions.

The same discovery leadership mapping now supplies the UI and execution multiplier. Acting Steward coverage and vacancies follow GovernmentPeopleSystem. Reading assignments does not refresh targets, redistribute workforce, change progress or grant discoveries. Workers remain aggregate full-time-equivalent effort, not invented individual scientists. Research math is unchanged.

New player discoveries from `advance_world_time` open an illustrated, dismissible announcement showing their real effects, signed percentages, benefits/trade-offs, causal explanation and gradual adoption. A batch queues in one surface with Next, Dismiss all, Escape and outside-click dismissal. Nested pause ownership restores the prior speed after reading. Historical discoveries are not replayed on load; opponents' discoveries do not route to this player UI. View in research opens the established discovery.

Safety Lifts previously required nonexistent `steam_power`; it now requires the existing `steam_propulsion` technology alongside Precision Machinery. The full prerequisite graph validates again.

## Assets and scope

Twelve painted field illustrations were generated with the built-in image tool, reviewed and imported at 768 pixels with mipmaps. Complete prompts and provenance: `assets/ui/research/PROMPTS.md`. Art depicts research fields; it is not a factual portrait of the named leader or a unique illustration for every individual technology. Material atlas behavior is preserved.

Shared files: `scripts/discovery_system.gd` (read-only leadership/assignment projection), `scripts/local_terrain.gd` (one daily event hook), `scripts/hud/atlas_data.gd`, `scripts/hud/knowledge_atlas.gd` (inquiry routing), `scripts/settlement_architecture_knowledge.gd` (valid prerequisite). New UI scripts and probes are task-owned. No save schema or population mechanics change. Existing knowledge, staffing, progress and adoption load normally. No external credentials required.

## Validation

- 61 cases pass across research visual atlas, atlas data, discovery projects, technology tree and government people suites (`/tmp/tt-research-tests.log`).
- All 14 final visual-atlas/popup cases pass (`/tmp/tt-final-ui-tests.log`): read-only assignment, daily identity preservation, zero workers, acting/vacant authority, hidden names, focus isolation, small/large layout, art presence, queued notices, actual signed effects, no unearned knowledge, Escape, nested pause and reachable dismissal.
- Real `knowledge_atlas_probe.tscn` opens Inquiry and Materials via the actual HUD, checks 1280×900 and 800×600, preserved ledger and focus behavior, and completes a discovery through the real calendar to verify the paused popup and speed restoration.
- Native capture-only `research_visual_probe.tscn` passes, exits and saves nine inspected captures in ignored `artifacts/research/`. It runs in isolated userdata, with Dummy audio, offscreen and minimized. It is not the player game.
- No save-format migration, no multiplayer change. Player process is not interrupted; a normal restart is required to load the integrated release.
