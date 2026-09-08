# Civilian construction workforce gates — September 8, 2026

READY; isolated development only.
Worktree: /Users/seanpurtill/.codex/worktrees/c2aa/tomorrow-and-tomorrow
Branch: codex/settlement-workforce-gates
Base: 15c2c27661a92f637608a41b9a72f3c26736be68

Civilian household/workshop starts, inherited-building renewal and satellite
quarter expansion now use GameState.effective_workers("Construction") for builder
thresholds and renewal throughput. They previously counted raw assigned people,
although monthly progress already deducted lasting-injury capacity and the share
reserved for military bases. With five assigned builders and 25% reserved, a new
civilian project correctly waits at 3.75 effective builders instead of spending
materials despite missing the four-builder threshold. Completing the base releases
that share and permits construction again. There is no second labor authority.

Files owned: scripts/settlement_model.gd, new test_settlement_workforce_gates.gd.
No civic allocation, military reservation, progress-rate, research, population,
geometry, culture or save-format changes. Existing structures are preserved.
The change governs future starts/renewals; work already underway still progresses
under existing labor-sharing rules. Monthly renewal/infill remain coarse actions,
not a complete per-project construction labor budget.

53/53 tests passed: five new workforce cases, all 43 settlement-model cases, and
five joint-operation cases. Zero errors, failures, skipped tests or orphans.
Log /tmp/settlement-workforce-regression.log. New checks exercise actual military
base reservation, resumption after release, injury capacity, material conservation,
workshops, renewal, and a 2,000-person quarter. Headless only, existing private
worker application and Dummy audio. Diff check passes; no player/test windows,
canonical writes, live-campaign changes or restart.

Integration queue: 936e3d7 on codex/settlement-ready-bundle remains separately
READY for affordable infill and funded material consistency, based on 75a1f32.
This workforce branch starts from latest main and does not contain that bundle.
Both touch settlement_model.gd, including nearby household and renewal code;
combine deliberately and retest. The new test file avoids its previous EOF
conflict. Preserve both completed branches. Main has newer architecture knowledge
and modern recipe changes; do not overwrite those with older model files.
