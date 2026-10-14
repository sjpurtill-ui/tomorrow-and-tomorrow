# Research popup redesign

Base: `d179b5ee6f86e0a8ed3c4cbbb641e230905ef713`. Shared popup shell:
`7170557aa57b349a89c99c569fd7d01331c5665b` (worker cherry-pick `22c23cde`).

## Screen decisions

- **Work under way** keeps current effort, evidence, timing and attention controls together. Illustrated journal entries replace the twelve-column-style field ledger. Fields without work stay compact. A field's name leads directly to its exploration page.
- **Explore knowledge** remains a separate task: choosing future work. One field selector replaces twelve navigation chips. The selected question has an illustration, clear state and an inline full account. Study paths group the available and waiting questions; additional open questions now expand into usable choices in place.
- **What we know** remains the record of accumulated discoveries and current benefits. Known fields lead the index. Fields with no discoveries are available under a disclosure. Effects and findings expand within their field, without another popup.
- **Discovery reading card** uses the shared light/night paper palette and open benefit rows. Its existing artwork, queue, dismiss/continue behavior, research link and adoption explanation remain intact.

Research purchase and technology-operation panels have no production callers in this checkout and were left alone. No simulation, catalog, save format, allocation calculation or research action was changed.

## Reciprocal critique

Designer B implemented Research while Designer A implemented Production. B reviewed Production's first pass; A reviewed Research's actual first-pass captures. A requested that narrow exploration show choices above the fold, the red pace diagnostic become secondary, zero-known fields stop competing with established knowledge, and tooltip-only accounts become visibly readable. The revision addresses all four. Long field/question names retain wrapping and full labels. The three research destinations were accepted as distinct tasks.

## Validation and evidence

The private-desktop probe is `tests/research_redesign_probe.tscn`, with Dummy audio through `tools/run_isolated_gpu_probe.ps1`. It resets only an isolated fixture, never loads or writes a player save, and checks:

- both 1600×1000 and 1024×720 research layouts;
- all twelve fields and unchanged attention callbacks;
- unchanged population and discoveries after attention changes;
- expansion of additional question choices and full question details;
- access to all twelve archive fields;
- discovery-card layout at large and narrow windows.

Use an isolated Godot user directory whose name contains `Test`; the probe refuses a player directory and stores only its display configuration there. Pass `--dark` for the night palette. The optional `--baseline` uses uncommitted snapshots under `artifacts/research-baseline/` retained in the worker worktree; it is only for reproducing the baseline comparison there.

Existing suites: `test_research_questions.gd`, `test_research_pace_board.gd`, `test_research_announcements.gd`, plus shared-shell `test_one_screen_per_category.gd`. The existing question layout assertion was adapted to the journal entries; its field coverage, full names, wrapping and width checks remain.

Final combined result: **20/20 cases pass**, with zero errors, failures or orphans. The final light and actual night GPU probes both pass and exit normally. Revised light/narrow/night layouts received independent critique and acceptance from Designer A. Two explicit border-color assignments then replaced default white thin rules with the intended palette colors. Their follow-up GPU capture could not start because the private-desktop runner reported `Cannot verify input desktop`; the supplied final images precede those two cosmetic lines.

Local evidence in `C:/Users/sjpur/tt-popup-design-b/artifacts/`:

- `research-baseline-1600-tab0.png` through `tab2.png` (preserved baseline boards, same fixture);
- `research-redesign-1600-tab0.png` through `tab2.png`, and 1024 equivalents;
- `research-redesign-dark-*` night equivalents;
- `research-redesign-discovery.png` and `research-redesign-discovery-narrow.png`;
- final GPU logs `research-final-light.log` / `research-final-dark-verified.log` and `.runner.txt` exit records;
- final test log `research-shell-tests-console.log`.

Captures, import changes, generated UIDs unrelated to this work and the isolated `override.cfg` are excluded from the source delivery. The player game was not launched or restarted. No save migration is needed.
