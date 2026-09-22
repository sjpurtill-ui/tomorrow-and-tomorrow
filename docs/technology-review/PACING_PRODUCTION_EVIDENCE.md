# Production evidence in historical pacing reports

Schema 15 records civilian recipe availability, retained lines and progress, manufactured stocks, actual lifetime output, government succession, installations and daily operating services. It also distinguishes recipe knowledge, stored equipment, equipped forces and carried/stored ammunition for every authored military equipment category. Final diagnostics include startup blockers, settlement output ledgers, active investigations and current resource conditions.

Knowledge is not manufacture, inventory is not domestic output, and equipment in storage is not a fielded force. Lifetime workshop output survives line replacement; household practice maintains its own stocks and is not uniformly represented in isolated actors' workshop ledgers. An annual first-observed production date is an upper bound, not an exact completion date. Remaining daily services are after consumption, not total generation. A stale operating ledger cannot establish current operation.

`tools/audit_history_pacing.gd --real-geography` uses actual terrain sampling, hydrology and catchments without rendering, including the same stable surface-material provider as the game. Without this flag it uses a synthetic reference environment. The harness advances every ordinary day, uses normal controller orders and century choices, and grants no extra knowledge, stock, energy or population. Its `--days` target is absolute, including when resuming. A wall-time stop is not target completion. The isolated harness does not model foreign acquisition or war.

`tests/owned_world_geography_probe.tscn` exercises the player and independent opponents together on actual terrain and retains real whole-game save checkpoints. Its `--days` parameter means additional days on resume. Both harnesses can check exact restoration and next-day continuation. Neither establishes rendered performance or visual quality.

Long campaigns resumed across fixes are migration/recovery evidence. Record the runtime and checkpoint for each segment; do not describe those campaigns as uninterrupted fresh runs on the final build. Matched comparisons must start from identical geography and state and differ only in the declared choices. See `pacing/first300-matched-decisions-75.json` for a completed controlled comparison and `FIRST_300_YEARS_PACING.md` for current release status.

## Government roster counts (schema 16)

`active_roster` includes active officeholders and unappointed candidates. `officeholders` counts distinct active people holding a central office or settlement leadership role. `central_officeholders` and `settlement_leaders` count each role separately; a person holding both is counted once in `officeholders`. `recorded_people` includes inactive historical records. These named people are representatives within the aggregate population, not an additional population or a count of administration workers.

Earlier evidence used the misleading key `serving_people` for the entire active roster and `historical_people` for all records. Interpret those older fields accordingly, including retained annual snapshots in resumed audits. At cold-campaign day 56,575, the reported 90 consisted of 36 distinct officeholders and 54 unappointed candidates: 33 settlement leaders and five central officeholders, with two people holding both roles.
