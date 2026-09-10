# Exploration, migration and knowledge exchange

Task: `codex/knowledge-exchange`, worktree `/Users/seanpurtill/Documents/Codex/tt-knowledge-exchange`, base `7440a7e5d973f2cee82f15564598f3a3cef188a2`. Sole integrator; no concurrent worker edits. Target normal Mac release: **2026.09.10.3**.

## Player behavior

- **Explore:** standing staff prefer uncharted connected ground. Physical visits can collect material specimens, handmade gifts, accounts and cultural practices. Carriers must return before the home collection receives them. Outward teaching reaches the host during the actual visit. Empty journeys no longer invent households, nomad bands, salvage or arbitrary research jumps.
- **Recruit:** standing staff visit reported communities instead of searching random long corridors for newly generated people. Existing households compare food, shelter, health, security and social conditions. Invitations require real spare housing, adequate water, at least fourteen days of home food and administrative reception capacity. Party size affects how many offers can be handled; actual source adults, destination room and provisions constrain the result.
- **Stay home:** people remain available for normal work and research. Administration integrates actual arrivals over time. Housing, food and staffing shortages increase the consequences of rapid arrivals; there is no artificial population-growth throttle or population-size research penalty. Ordinary research retains its existing logarithmic team scaling.

Population is conserved across a migration transaction. Accepted travelers remain on the source population ledger but count as physically absent from work and home provisioning; the destination has reserved their places. Their actual age-cohort quantities transfer once on return. Failed/expired journeys release reservations. Emigration no longer increments mortality-by-age counters. Integration creates bounded labor/cohesion/administration pressure. Travel contact uses the existing environmental disease hazard for both visitors and hosts, rather than a foreign-identity penalty.

## Knowledge and culture

The collection retains provenance, actual encounter/return dates, related investigation and study progress. Examination uses 15% of the existing Knowledge effort while finds await study. Studied evidence supports a particular subject; it is not an instant unlock or an extra copy of discovery effects.

Fifteen authored alternative foundation routes cover early preservation, containers, woodworking, water, measures, institutions, logistics, formation drill, watercraft and public culture. Original and alternative routes reconverge on the same discovery/adoption record. Studied imported practices can change timing and accelerate investigation while retaining material and foundational requirements. The research inspector identifies the chosen route; the tree distinguishes alternative links. Completion records which route and evidence were used.

Eleven environment-backed specimen subjects cover clay, stone, fiber, timber, flint, salt, medicinal plants, copper-bearing minerals, iron-bearing minerals, coal and soil. Samples require actually visited uncharted ground with the relevant potential and usable foundations; repeated collection of the same specimen subject does not farm rewards. These are study samples, not free industrial stock. A source can teach only discoveries it actually knows and has adopted. Handmade gifts debit an existing material stock and require an active crafts workforce. Cultural accounts can matter even when both societies already know the underlying practice.

## Relations and leaders

Each civilization chooses reception and sharing policy through the same validated command. Open sharing includes useful technical practices; selective sharing includes culture and simple crafts; private know-how blocks outward teaching. Foreign rulers choose according to their existing personality and current conditions. Pressure from arrivals shifts their stated goals and research emphasis toward institutions, housing and belonging. Hunger can make them keep people home.

Studying another society's accounts creates familiarity and respect. These enter diplomatic assessment and actual opponent order selection. Recorded departures create friction, especially for assertive rulers. The conversation receives dated exchange/migration records and the foreign ruler's communicated concerns. It does not gain a hidden global technology score.

Peaceful envoys carry practices through the same encounter and return system. Research understandings give reciprocal support to both real owners instead of modifying a foreign display-only capability. Border understandings suspend mutual recruitment invitations for their duration. War ends cooperation; peace does not silently reactivate it. Cultural influence can improve cooperation without adding soldiers or population, and never automatically converts cities.

## Interface

**Scouting → Objects, knowledge & culture** opens **Brought Home**, also accessible from the research inspector. It shows provenance, examination progress, related investigations, reception capacity, unsettled arrivals and sharing/reception policies. Required materials or foundations are explained before research can be directed. It scrolls at small sizes and closes by clicking outside it or pressing Escape. It uses existing symbolic icons; this delivery does not claim new individual raster artwork.

## Validation

All **132 combined cases pass**, with zero errors, failures, skips or orphans (`/tmp/tt-exchange-final-tests.log`). The combined regression covers exchange behavior, ordinary research, research UI, standing scouts, ruler strategies, diplomatic journeys, owner parity/save continuation, routes, expedition archive, city intelligence and performance invariants. New cases cover finite/idempotent migration, overlapping invitations, real age/cohort and mortality accounting, human-owner aliases, physical envoy carriage, source adoption/sharing gates, repeated reward prevention, material sampling, alternate foundations, cultural influence, reciprocal agreements and war termination.

Native capture-only verification renders the real collection at 960×720 and 340×640. Panel/filter containment and real map-click/Escape dismissal pass. Captures are in `artifacts/knowledge-exchange/`; the private background guard prevented activation/window ordering, monitored the owned process, and verified it exited without a visible test window or focus change. No player/editor was stopped or relaunched.

A private copy of the existing day-11238 campaign loads with all twelve opponents. Twelve ordinary daily steps average **256.23 ms**, range **231.85–325.98 ms**, headless (`/tmp/tt-exchange-performance.log`). No actor/day was skipped. This is a short CPU sample, not an FPS claim or proof that frame stalls are solved. Existing mature-campaign frame stalls remain.

## Save compatibility and bounds

The added record belongs to each existing GameState and uses the reflected save system. Old saves receive empty records; old expeditions can encounter actual communities on their remaining journey, but do not receive invented retrospective artifacts or migrants. Previously awarded population/knowledge is not removed. Existing pending simulation, research and troop records keep their authorities. Nested collection/evidence/provenance/mission data is validated before restoration.

The collection is bounded at 1,024 items per society, exchange history at 64, and interface rendering at 40 filtered cards. Research effects still have one completion/adoption record. Households are currently recruited from actual civilization populations; no separate independent nomad-population simulation is claimed. Reception is at the home settlement, not an automatic selection among secondary cities. Handcrafted gifts use aggregate crafts availability/materials rather than individual artifact manufacturing jobs. Alternate local foundation routes are authored for the listed early subjects; imported-learning routes support the broader catalog. Future frontier inventions and a complete historical balance audit remain outside this delivery. No assertion that all strategic choices are equally strong across a 2,500-year campaign.

Shared files touched: `game_state.gd`, `discovery_system.gd`, `save_system.gd`, and the release version in `project.godot`. Current terrain, military command and rendering changes are preserved. No merge conflicts expected against unchanged base main. Remove the owned `override.cfg` before packaging. Integrate and verify canonical main before claiming availability; launch only through the normal Mac launcher, and only when requested.
