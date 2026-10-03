# Field overview painting recovery

Worker base: 0515193e42c6adc8b7ac9319315ac7f0294c2d3f. Twelve existing field overview photographs are replaced with wide handmade paintings. Eleven generated originals retain each field's established medium; ecology reuses the reviewed seasonal-patterns painting unchanged. Exact prompts, references, source paths, old/new hashes and dimensions are in selected.json. Prior photographs remain recoverable from the Git base; generated originals remain at their recorded source paths.

The two-line art() guard chooses these wide field paintings before the legacy opening-era paper crop. Specific discovery bindings, priority, availability and hidden gating remain unchanged. Existing generic catalog fallbacks that use the same v1 paths receive the corrected painting too. Full sources and wide cards reviewed; private GPU grid also checks 92-square inquiry thumbnails and 230x190 culture-panel crops. Images illustrate broad game fields and imagined early practices, not archaeological reconstructions of a particular site or culture.

Validation: final clean import, headless OVERVIEW01_ART_PASS 12, successful private GPU capture. First private GPU startup failed before rendering; retry passed. First cold import produced existing missing-font/KPI dependency errors; subsequent import was clean. No simulation, saves, player/editor launches or canonical checkout edits. Local captures, override.cfg and unrelated generated import/UID churn are excluded.

Integration: selectively apply only the two art() guard lines in scripts/hud/research_visuals.gd. Other opening-art PRs touch this helper; retain their discovery focus changes. This guard supersedes the ecology-only opening field-art workaround in PR25 once all twelve overview assets are integrated. Do not copy the whole helper over a later version.

To reproduce, configure temporary custom user data TomorrowAndTomorrow_StylizedArt_Test, import, run verify_batch.tscn headlessly, then use tools/run_isolated_gpu_probe.ps1 for its private capture. Remove the temporary override before handoff. Research imports use size_limit=0 to preserve wide source dimensions.
