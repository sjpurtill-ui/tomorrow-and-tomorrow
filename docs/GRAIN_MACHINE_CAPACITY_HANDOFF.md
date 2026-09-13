# Shared daily grain-machine capacity

Base `b227f9a1b99719a1ed39953ea1e1a0fee8531d02`; worktree `/Users/seanpurtill/.codex/worktrees/ef8f/tomorrow-and-tomorrow`, branch `codex/grain-machine-capacity`. Scope: grain processing and its tests only.

One installed mill previously received a fresh capacity allowance for each dry, tested and clean stock. Daily throughput now subtracts the same day's already processed amount across every source. A paid handmill can process remaining grain, including the same source, once powered capacity or fuel is exhausted. Shared worker charges, food losses and electrical consumption remain real; tomorrow starts with a fresh quota. The existing aggregate power-demand prediction now agrees with the machine limit.

Focused validation: 59 checks pass across grain (20), food batches (23) and operating facilities (16). The final grain suite was rerun after adding same-source handmill fallback: 20 pass, zero errors/failures/flaky cases/skips/orphans. New cases verify one handmill produces only its ten-ration daily allowance across three stocked inputs, next-day reset, and one powered mill plus one handmill processing 45 rations with 1.4 electricity consumed. Conservation includes their actual milling loss. Logs `/tmp/tt-grain-capacity-results.json` and `/tmp/tt-grain-capacity-final.log`.

No discovery IDs, save fields, schema, research rules or owner authority change. Existing equipment can now produce less where the old multi-stock loop exceeded its installed capacity. Shared-file conflicts are limited to `scripts/grain_processing.gd`; the water-conveyance worker owns no overlapping hunk. No player launch.
