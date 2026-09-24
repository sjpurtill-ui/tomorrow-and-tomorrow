# Dependency mapping contract

Registry: `docs/research/registry.json` (1,101 canonical ids). Use ONLY registry ids (canonical, not aliases). Each mapper owns 3 lines and writes, per line:

- `docs/research/deps/<line>.json` — array of `{ "id", "requires_all": [ids], "requires_any": [[ids], ...], "precedents": [ids], "conditions": {...}, "note": "≤12 words" }`
  - `requires_all`: hard prerequisites (must be known). Keep to the 1–3 that truly matter; do not list transitive ancestors.
  - `requires_any`: alternative routes; each inner array is a set where ANY one satisfies (e.g. `[["clay_record_tablets","knotted_record_systems"]]`).
  - `precedents`: softer historical influences that make it easier/faster but are not required.
  - `conditions` (optional): non-discovery gates the engine can check — `min_population`, `min_settlements`, `resources_known` (e.g. "Clay"), `environment` ("river","coast","woodland","dry"), `institutions_min` (0–1), `contact_required` (true if typically borrowed from a contacted people).
  - Cross-line prerequisites are expected and encouraged — reference other lines' ids.
- `docs/research/deps/<LINE>_DEPENDENCIES.md` — the same, as a compact table: Year | Discovery | Requires (all) | Requires (any) | Precedents | Conditions.

Rules: a prerequisite's target_year must be ≤ the dependent's target_year (band overlap allowed only for requires_any/precedents); no cycles; every item except true starting knowledge (year ≤ ~5) should have ≥1 requirement; items at year 0–5 may have none. Keep notes minimal. Flag any registry item whose year looks wrong given its prerequisites in `docs/research/deps/<line>_FLAGS.md` (short list) instead of changing the registry.
