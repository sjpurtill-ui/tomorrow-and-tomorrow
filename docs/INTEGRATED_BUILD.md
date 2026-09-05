# Integrated player build — September 4, 2026

Canonical checkout: `C:/Users/sjpur/TomorrowandTomorrow`. Existing current map, rivers, resource behavior, civics, government people, inquiry, military progression, occupation/runner systems, and whole-game saves remain the base.

Integrated from the archived OneDrive work:

- 27 Blender unit assets and 26 GPU crowd variants, bounded map armies, live battle view, improved camera control, cartoon battle effects, visible commanders, cosmetic appearance choices, and clear battle figures/round summaries.
- Exceptional people, generated biographies, patronage, recorded deeds and earned legacies. An appointed government Marshal retains their official identity and aptitudes; independent field generals use chronicle identities.
- Four opening ambitions, gradual cultural direction and non-expiring visions. Current settlement leaders retain daily labor delegation; the older parallel allocator is retired.
- Known-community network and three collective projects with actual prerequisites, material costs, aggregate work and research effects.
- Foreign leader preparations, temperament, bounded memories, envoy-carried proposals, counteroffers, escrowed Timber, two-year understandings and consequences when war interrupts cooperation. Optional free conversation drafts terms through the configured civic provider; it never enacts them. The deterministic controls also work without a provider.
- Player-facing capability labels instead of historical era labels in progression. Internal balancing tiers remain.

Controls: F6 military; F7 aerial inspection (preserved); F8 ambitions; F9 connections; F10 people and legacies. Known leaders can be opened through the community network or World Strategy. Existing worlds keep their founding state; new worlds get the ambition opening. A launch does not automatically load a saved world: use the existing load control to resume it.

Both source working copies and Git histories were backed up before integration at `C:/Users/sjpur/game-integration-backups/2026-09-04`. No old game save was replaced by a test save. The old project launch redirects to the canonical launcher, and the canonical launcher rejects other checkout paths.

Validation includes historical figures, ambition opening/direction, network, battle renderer, military balance/progression, map runtime, civic-city behavior, whole-game saves, foreign diplomacy, and an end-to-end main-scene/crowd/leader/combined-save probe. All 27 unit imports and 108 clips verify. Targeted GdUnit suites passed 27 river/terrain/resource cases and 36 government/civic-implementation cases (63 total). Headless terrain probes report engine shutdown resource warnings; these are tracked separately from assertion or script failures. Live paid-provider dialogue quality is not covered by the offline draft-contract probe.

See WORKER_HANDOFF.md for the shared workflow and worker prompt.
