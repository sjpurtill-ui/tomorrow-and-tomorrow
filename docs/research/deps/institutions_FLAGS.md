# Institutions flags

Registry years that look wrong given their prerequisites. The registry was not changed.

| Id (year) | Issue | Suggestion |
|---|---|---|
| `household_task_ledgers` (6) | "Household task tallies" comes before knowledge `tallies` (10). It is mapped on `counting_words`, with `tallies` only as a precedent. | Move to 10 or later, or reword it as remembered task counts. |
| `public_grain_weighing` (80) | "Weighed" comes before any weights (`standard_weight_sets` 165, `balance_beam_weights` 320). It is mapped on volume measures. | Reword it as measured by vessel, or move to 165 or later. |
| `area_harvest_assessment` (460) | Assessment by area needs knowledge `area_volume_rules` (470). That link is an any-route, allowed only because the bands overlap. | Move it to about 475, or move `area_volume_rules` to 455 or earlier. |
| `seasonal_crisis_leader` (24) | This is a merge gap: security's alias sits at 170. | Keep 24 for a crisis leader. The 170 war leader fits under `paramount_chiefdom` and `kingship`, which already depend on it. |

## Cross-line cycle for the labor mapper

- In labor, `hired_labor_contracts` (520) lists `price_wage_schedules` (540) as a precedent. This institutions file requires `hired_labor_contracts` → `price_wage_schedules`, which creates a cycle. The labor precedent points to a later item, so it should be dropped.
