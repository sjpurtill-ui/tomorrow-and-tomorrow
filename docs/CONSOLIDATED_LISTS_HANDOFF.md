# Consolidated population and scout lists — September 7, 2026

Worker /Users/seanpurtill/.codex/worktrees/c2aa/tomorrow-and-tomorrow,
codex/consolidate-ledgers, base f0416ef.

Deaths default to a cause summary across retained records. The separate Death
Records tab lists dated place/cause groups newest first, eight per page; summary
pages are also bounded to eight causes. Lifetime KPIs remain separate from totals
in the retained ledger. The legacy population modal has the same summary and a
separate paged Dated Deaths tab. No demographic records or counts are changed.

Scout dispatch uses category, destination, then an account selector only when
multiple accounts exist. Repeated leads for one people share a destination row;
individual reports keep their exact IDs, uncertainty, descriptions and routes.
The selected account's evidence is visible beneath the controls. Dropdown height
is bounded. Category changes update heading availability and duration quotes
through the original dispatch callback; selecting an account sends no expedition.
No evidence is merged or silently discarded, including conflicting reports.

Owned changes: population detail provider, new scout_target_picker, small wiring
and legacy ledger changes in shared hotspot local_terrain.gd, focused tests.
No simulation or save-format changes. Compatible with existing saves.

Worker focused list and rumor tests: 15/15 pass. Tests conserve totals across 400
records and traverse all pages; 32 accounts consolidate to two people while exact
selected targets survive initialization and category/destination changes. Rumor
regressions cover carried evidence, routing, costs and disclosure. Clean headless
import and diff check. A broader city-direct-orders run has three assertions in
the far-order marching test failing identically on unchanged canonical f0416ef;
that existing issue is outside this presentation change.

Canonical verification recorded in INTEGRATION_STATUS.md. No live session restart,
no saved-data deletion, no remote push. GPU interaction was not audited this pass.
