# Sewing and garment repair

Worktree `/Users/seanpurtill/.codex/worktrees/ef8f/tomorrow-and-tomorrow`, branch `codex/sewn-garments-and-repair`, base `7331505d9b8c708c815fd44423f88c591faa1242`. Scope: clothing knowledge, household clothing, actual hunting byproducts, city defaults, clothing supply planning, inspector and focused tests.

Four discoveries implement bone-needle sewing, cutting patterns, size grading and textile repair. Sewing consumes cloth and yarn using paid tools. Patterns reduce cloth waste; grading consumes paper and increases work throughput. Repair consumes cloth, yarn and shared daily equipment capacity, restoring only the treated share of recoverable garments without creating garments or restoring ruined stock. Inspector details show garment kinds, material costs and the local bone reserve.

Recovered bone comes only from actual new hunting harvest after the existing siege gate, once per local day and after sewing adoption. Stored or imported meat and forecasts do not generate it. The bounded city-local reserve pays for needles and repair tools. It is not a map deposit or freely tradable resource. The automatic planner obtains real yarn before paid sewing; existing workshop management and upstream resumption remain intact.

All 90 cases pass: clothing 21, civilian planner 14, food batches 23, owned simulation 19 and city resources 13. Coverage includes actual FoodSystem hunting, duplicate-day prevention, proportional repair, exhausted inputs, primary/secondary ownership, save round trips and the automatic yarn-to-sewing chain. Evidence: `/tmp/tt-sewing-results.json`. The graph is clean at 671 discoveries, 453 explicit routes, 309 recipes and 17 facilities.

Save compatibility: the optional `bone_stock` defaults to zero in old clothing records; malformed or nonfinite values are rejected. New garment kinds persist in the existing bounded lot state. Existing six clothing definitions remain unchanged. No finished-garment trade, tanning, hides, wool or milk is invented. Work and insulation coefficients are game abstractions, not engineering or medical ratings. No player launch, package update or historical-pacing claim is included. Shared-file changes are the single actual-harvest argument in FoodSystem and the additive settlement clothing default; no terrain or military edits.

Canonical runtime `638629a669cb62946f88fa51761793941df07e61` passes all 35 clothing and planner cases (`/tmp/tt-sewing-canonical-results.json`). All 671 runtime definitions exactly match the promoted ledger; 15 ledger-tool checks pass.
