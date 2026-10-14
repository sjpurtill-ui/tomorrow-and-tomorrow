# Modern Strategy: World, records and collections

Presentation-only delivery for the complete popup redesign. Runtime ledgers,
simulation rules, costs, odds, callbacks, intelligence freshness, pause behavior
and saved data retain their existing owners. No save migration is required.

## Screen coverage and page decisions

| Family | Reviewed surfaces | Final treatment |
| --- | --- | --- |
| World | Peoples, Expeditions, our history, Standing, Eyes and ears | Distinct tasks retained. Foreign people use dossiers with inline relationship detail; our people use a compact comparison strip. Expeditions group source, task and action. Standing keeps its graphic and makes exact factors optional. |
| Nested World | City report, foreign city dossier, held town dossier, people report | Reported model, freshness and uncertainty retained. Whole town is the initial model framing. Controls use shared typography and touch targets. Existing held-town and diplomatic actions remain reachable. |
| Scouts and exploration | Findings, Journey, Map of hearsay, expedition planner | Findings and Journey remain distinct queries. A missing route uses a compact message; recorded routes and journals remain complete. Hearsay keeps its uncertainty graphic and selected account. Planner scrolling leaves Send and Close available. |
| Chronicle | Years, Births/deaths, What was built, year-count disclosure | Distinct record types retained. Built records become stacked readable entries with every date, event, material and note. The count chart is optional on narrow layouts. |
| Collection gallery | Grid, object detail, studied/unstudied states, sets, rumors, Allure effects | Art remains dominant. Allure effects move inline. Rumors hide an unrelated object inspector. Narrow object detail hides collection controls until Back, preserving search and filter state. Study, Exhibit and Exchange remain available. |
| Brought home | Populated collection, filters/search, study state, exchange offers, people exchange preferences | Header and Close remain outside scrolling. Controls wrap at narrow widths; one-page collections show a count without redundant paging buttons. |
| People and legacies | Biography, every recorded deed, person navigation, support | Removes arbitrary three-event chapter pages. One continuous reader keeps person navigation and support visible. |
| Our direction | Our course, Our character | Keeps two meaningful tasks. Selected page has a visible fill and underline. Confirmation remains the primary action. |
| Great Works | Ours, foreign works, model inspection, legacy record, shrine slots, ceremony | Model/artwork and existing story remain central. Legacy record becomes an inline disclosure available on narrow layouts. Model controls use the shared 40 px / 14 px contract. |

## Independent review and revision

The integrator reviewed rendered captures while this worker critiqued War,
Court, commands, service rosters, battle reports, opening, Settings, orders,
occupation, recovery, siege, travel and map overlays. Findings were revised and
reviewed again before handoff.

Closed findings include the duplicate foreign relationship card stack, oversized
own-people card, stale gallery inspector on Rumors, excessive narrow gallery
chrome, indistinguishable Direction tabs, unreadable built-record columns,
empty scout chart, blank initial city framing, and small Great Works controls.
The shared KPI renderer fix belongs to Designer B and is integrated before the
final nested captures; long facts and their supporting copy now wrap.
The final Great Works probe also caught a stale host reference on reopening;
the view now validates that reference before checking its type.

## Validation

- World focused suites: 41 World, 23 Standing, 14 Peoples and 20 Covert cases
  passed during their respective checkpoints.
- Chronicle / one-Chronicle / figures: 34 cases passed.
- Great Works inspection, view, ceremony stage, culture and held-town suites:
  50 cases passed.
- Final reported-city, complete-person-reader, scout-route and Great Works
  inspection/view/reopening suites: 26 cases passed, zero
  errors/failures/skips/orphans.
- Private GPU probes exercised the real gallery opener, filtering, study,
  exhibit and exchange paths; populated exchange at 960x720 and 340x640;
  nested reports, empty/populated route, hearsay and planner at 1024x720;
  Direction, figures and Great Works layouts in both themes.
- The comprehensive Great Works experience probe retains one existing failure:
  the second dedication ceremony can omit its architect speech. A baseline
  run using the unchanged ceremony/director reproduced the same failure.
  This UI delivery does not change narration or ceremony game logic.

Evidence remains private in the worker's `artifacts/popup-modern-c`,
`artifacts/knowledge-exchange`, and `reports/great-works` directories. Captures,
test userdata, generated imports and caches are excluded from commits.
