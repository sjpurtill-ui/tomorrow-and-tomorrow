# Observed pacing export

The former `tools/plot_discovery_pacing.py` generated a synthetic 3,000-year curve from 48 channels, eight lenses, twelve calendar-gated stages and 121 additional foundations. It did not call the current research system, use the authored discovery graph or consume physical production. Its optimistic millennial title was not campaign evidence. Those calculations are retired from the tool; archived historical files are preserved and must not be treated as measurements of the current game.

The replacement exports actual recorded observations to CSV and a provenance-bearing JSON summary. It requires an explicit input report and output directory. It generates no projected discoveries, interpolation, calendar gates or claimed future performance. The legacy filename is retained so existing references lead to the correction rather than another synthetic model.

Example from an explicit worktree:

```sh
python3 tools/plot_discovery_pacing.py docs/technology-review/pacing/catalog-476-250-terminal.json --out /tmp/tt-observed-pacing-export
```

The archived report records 250 years against the 476-discovery catalog, ending with 320 known discoveries. This compact report provides initial and final discovery-count samples; the export preserves those two observations without inventing annual counts. The endpoint records zero retained civilian lines and installed units. It does not prove that none ever operated between samples. Its separate annual production observations remain in the original report and are not silently converted into discovery samples.

Outputs identify input SHA-256, any recorded source commit and original report hash, scenario, catalog size, observed duration, stop reason and source limitations. Missing provenance fields remain null. Structural sample checks cannot authenticate a report or certify gameplay. The exporter therefore never promotes an input's completion flag into full-campaign approval.

Verification on the archived 476-catalog report preserved day91,250 and320 known discoveries exactly. Three malformed cases were rejected: a discovery count beyond the recorded catalog, conflicting same-day observations, and a final sample outside the declared endpoint. No simulation, calibration or rate changed, and no long probe ran. `git diff --check` passed.

The 2,500–3,000-year requirement remains unverified. Next gameplay evidence must demonstrate sustained physical operation and historical progression in the current model, followed by multiple civilizations, constrained foreign recovery and full-horizon viability. A synthetic curve, a completed shorter diagnostic, or a reachable graph cannot substitute for that evidence.

Handoff: branch `codex/pacing-evidence-correction`, worktree `/Users/seanpurtill/Documents/Codex/tt-pacing-evidence-correction`, base `6fed85fb93fef79b3cabd134047b010b04437150`. Owned files are the exporter and this document only. No discovery counts, runtime files, save fields, artwork, shared ledgers or archived reports changed. No player launch. Integration review is required before presenting this tool correction as canonical.
