# Great Works, rewards and an enduring civilization

Buildings → Undertakings shows each settlement's Great Works: possibilities,
construction stage, architect, pending decisions, dedication, current effects,
history and the civilization's victory progress. World → Standing also shows
victory progress. The binding design is `docs/GREAT_WORKS_DESIGN.md`.

## Great Works (G1 core)

- **World-unique.** 36 works span the founding, classical, medieval, industrial
  and modern eras (`scripts/undertaking_catalog.gd`). Each exists at most once in
  the world. Availability depends on discoveries, population and environment —
  no calendar cap and no per-settlement dice. The player and AI civilizations
  use the same functions (`scripts/great_works.gd` facade). The first to finish
  claims a work; every other site of it becomes a named unfinished rival
  monument that can be repurposed as a lesser monument (allure only, no claim,
  no rewards) or quarried for 40% of its built-in materials.
- **Upgrade in place.** Ancestors' Ring → Temple of the Ring → Cathedral of the
  Ring; Long Song → Archive; Granary → Vaults of the Covenant; Steps → Tower of
  the Watching Sky. The site keeps its name, events, reputation accounts,
  enshrined objects and the earlier work's claim. Abandoning a rebuilding
  reopens the older work.
- **Architect and stages.** Each work commissions a named Architect (a
  historical figure) with style, vision and ego. Construction passes
  foundations → raising → crowning → dedication. Gates at 25%, 45% and 70% pause
  work for a decision: grander or practical design; pour stored food into the
  crews or protect it; paid crews, a forced-labor levy (recorded hardship,
  cohesion and legitimacy fall) or volunteers; plus a proud architect's demand.
  AI rulers decide within two days; a player's council decides cautiously after
  90 days of silence.
- **Events.** Deterministic from the world seed and day, at most two per stage:
  collapse, accident (named dead removed from the population), strike, ingenious
  solution, omen, architect's demand, poaching by a rival building the same
  work, and fire of unknown cause. Deliberate sabotage, sieges, capture and
  looting belong to `scripts/great_works_rivalry.gd`.
- **Dedication.** Completion creates a pending ceremony. Up to four contacted,
  friendly peoples attend; their gifts are taken from their real stores and
  delivered to the builder's (goods are conserved; the human player's stores are
  never given away automatically). Dedication names the work, records the
  witnesses' accounts (real diplomatic reputation), writes the chronicle and
  news, and adds an allure spike that fades over five years.
- **Transformative effects** (`scripts/undertaking_effects.gd`), each needing a
  held, functioning work and scaled by condition: the Watching Sky forecasts
  lean seasons and famine 120/365 days ahead; the Covenant seals a famine
  reserve from real surplus and releases it in shortage; the Long Song passes
  leaders' memories to successors and restores up to 1/3 lost discoveries a
  year; deterrence (≤0.25) and traffic (≤0.40) are exposed for rival and trade
  logic. Captured works serve their occupier. Each work has one decree text.
- **Allure and artifacts.** Great Works are the largest allure source
  (`GreatWorks.allure_contribution`). Artifacts the owner holds can be
  enshrined in works with shrine places.

## Practical rewards

Maximum effects at full condition, in addition to the catalog's local
worker-effectiveness bonus (`scripts/undertaking_rewards.gd`). Ruined, abandoned,
unfinished and lesser sites give no reward. Construction and upkeep still require
existing workers and materials. Capacity does not fill itself; preservation
operates on actual food; attraction changes existing migration decisions. Combined
special work/attraction bonuses cap at 20%, food spoilage reduction at 40%, and
combined catalog/special worker bonuses at 30%.

After a year of operation, travelers encountering another society carry accounts
of achievements; dedication witnesses carry them at once. Diplomacy uses only the
accounts a society received (combined bonus capped at 0.20), fading over thirty
years. Recorded construction hardship halves the reputation benefit.

## Enduring Civilization victory

Three functioning Great Works at 60% condition or better, each with twenty years
of maintained operation; three different achievement categories; and current
accounts reaching two foreign societies. The panel counts Great Works held,
claimed in your history (including earlier layers of rebuilt sites) and claimed
in the whole world. The award records the year and any construction hardship,
persists through later decline, and does not end play.

## Saves

Existing undertaking records load unchanged; missing Great Works fields are added
lazily and gates already passed are not re-posed. New fields (architect, gates,
decisions, ceremony, layers, enshrined, covenant, archive, rivalry, …) are
optional and validated. Tests: `tests/test_great_works.gd` plus the existing
undertaking suites.
