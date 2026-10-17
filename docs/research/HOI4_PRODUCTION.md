# Production board and shortages

Reference: the player's supplied HOI4 production screenshot. Stacked olive rows,
resource/capacity header, product art, output and efficiency bars, capacity grid,
priority arrows, pause, target and category filters. Military is the default;
Civilian is one adjacent tab. All existing land equipment, consumables, transport,
naval and air recipes use the same board. Equipment production does not enlist
people or bypass generals, commissioning, training or research.

## Research, 2026-10-17

Checked the locally installed **Hearts of Iron IV, Case Green 1.18.0.0 (3bae)**:
`common/defines/00_defines.lua`, line 656 sets
`PRODUCTION_RESOURCE_LACK_PENALTY = -0.05`.
`localisation/english/production_l_english.yml` exposes the resource penalty on
production lines. No Paradox assets or source files are included in this project.

Online references consulted:
- https://hoi4.paradoxwikis.com/Production (publisher-hosted wiki; automated access returned 401).
- https://forum.paradoxplaza.com/forum/threads/hoi-iv-dev-corner-military-production.1934736/
- https://steamcommunity.com/games/394360/announcements/detail/671748399637202678

The implemented baseline loses 5 percentage points per cumulative missing input
unit at each capacity slot. The largest resource penalty wins, rather than adding
all resource types. At 20 missing units that slot stops. Other slots can continue.
Higher lines receive first claim; unmet demand carries down the priority ledger.
Example: 11 slots needing 2 steel and 1 aluminum, with 2 steel and no aluminum,
have penalties 5, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100 percent (mean 50.45%).
The numeric baseline is verified against the installed game's definition, not a
claim about every future patch, mod or modifier.

## Adaptation to Tomorrow and Tomorrow

Capacity slots represent existing assigned makers, not invented factories or a
second population pool. Per-slot input weights are the rounded-up recipe bill.
Available stored material is normalized into capacity inputs using nominal daily
consumption. One shared priority ledger supplies both the actual day and the UI
forecast. Evaluation uses bounded arithmetic intervals, not loops per citizen.

Operating inputs are now strategic availability constraints: reduced-speed work
can finish despite a missing ingredient, as requested. A line draws up to the
available stock for its actual output; stores never become negative and no hidden
resource debt is added. This intentionally replaces the old strict fractional
bill constraint. Setup tooling, research and operational bases remain required.
Paused lines and fulfilled targets claim no inputs. Completed stocks, saved
progress, targets and installed tools remain in their existing save fields.

Civilian household goods retain their existing substitutable material basket
(timber/fiber/clay/stone/flint); shortages of the combined basket use the same
capacity penalty. Automatic watch arms use the same formula and retain the
researched equipment age when an input runs out, instead of silently downgrading.
The board reports actual civilian goods, food and extraction outputs and sends
labor edits to the existing People allocation screen. It does not fabricate
independent recipe lines for techniques that the game models as aggregate goods.
