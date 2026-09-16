# Technology chronology planning package

This package is the authority for planning the playable 2,500–3,000-year
technology arc before further mass implementation. It does not add calendar
gates, change research rates, promote draft discoveries, or modify the player
build.

## Current checkpoint

At source commit `9fe1f235a3b1a2f47cc426942afa5db8c308d680` the reviewed catalog records:

- 883 implemented discoveries;
- 3,470 distinct implemented or authored identities;
- 1,530 identities still to author toward the 5,000 target;
- 1,366 identities with an explicit historical-horizon assignment;
- 2,104 identities still lacking that editorial assignment; and
- 660 explicit learning routes in the live graph.

Structural reachability is not chronological validity. A discovery can be
reachable in the graph and still have an implausibly shallow material,
institutional, energy, measurement, or production foundation.

## Authority and player-facing rule

Historical eras are editorial and validation concepts. They are never shown as
global player labels and never unlock discoveries by date. The player experiences
historical change through altered production, institutions, warfare, information,
daily life, and research capacity.

Civilizations may progress faster or slower than the reference chronology. They
may not obtain a capability without the physical and social system that can
produce, reproduce, operate, and maintain it. Foreign knowledge may shorten
investigation; it cannot supply missing plant, energy, materials, instruments,
skills, logistics, or organizations by implication.

## Files

- `HIDDEN_CHRONOLOGY.md` defines 24 progressive civilizational transformations.
- `FULL_5000_JOURNEY.md` plots the complete narrative, branching, pacing, and
  military arc and assigns all 5,000 discovery slots.
- `ANCHOR_SPINE.md` defines the 300-slot load-bearing discovery spine and its
  selection rules.
- `journey-allocation.json` is the machine-readable allocation authority.
- `transformation-field-allocation.tsv` is the complete 24-by-24 field and
  transformation matrix.
- `build_journey_allocation.py` regenerates and validates both allocation files.
- `EARLY_GAME_EXPERIENCE.md` defines what makes the slow opening active and
  dramatic without frequent technology rewards.
- `CATALOG_LEDGER_SCHEMA.md` defines the review record used for live and draft
  discoveries.
- `OPENING_SPINE_REVIEW.md` fills the T01–T04 anchor slots, records the first
  chronology exceptions, and proposes the first connected implementation wave.
- `opening-spine-review.json` carries those decisions into the generated ledger.
- `live-catalog-ledger.tsv` is a generated planning ledger for all 878 live
  discoveries; it is not runtime data.
- `DECISION_LOG.md` preserves accepted rules and prevents repeated redesign.
- `EXECUTION_QUEUE.md` gives the bounded order of work and test cadence.

## Review order

1. Maintain the accepted 24 transformations and 5,000-slot allocation.
2. Apply the anchor-spine rules and slot distribution.
3. Review the early-game experience independently of research speed.
4. Classify the 883 live discoveries, starting with anchors and chronology risks.
5. Repair only the first connected historical slice.
6. Expand one transformation at a time after the preceding slice is playable.

The 2,592 authored drafts remain available source material. They are reviewed
before activation, not exhaustively rewritten during the first live-catalog pass.
