# Settlement reference: first review checkpoint

Base: 7261fa1, September 22, 2026. This is a measured visual prototype, not a replacement city system or completed performance fix.

## What the current campaign measured

One isolated headless step from the current quicksave (day 20975, civilization population 299, four settlements). The primary settlement had 23 plots and 23 routes. Rendering and simulation were measured separately; no player save was written.

| Operation | Observed CPU time |
|---|---:|
| Primary plot fabric, close / middle / distant builds | 585 / 647 / 585 ms |
| Opponent advancement, one day | 1,470 ms |
| Player resource processing | 45.7 ms |
| Secondary settlement processing | 39.3 ms |
| Player military and travel | 22.1 ms |
| Player settlement morphology | 0.155 ms |

These are individual diagnostic samples, not averages, live FPS, or a before/after simulation benchmark. Loading is excluded. Cold geography and asset caches may affect them. The fabric count excludes other world layers; opponent advancement excludes the rest of the complete world step.

## Prototype and visual findings

The prototype renders the existing saved plots and imported building assets once. Three perspective cameras at 1,000, 3,000 and 10,000 feet reuse identical mesh/MultiMesh resource identities. It uses a fixed terrain patch to remove streaming transitions from this comparison, disables simulation, and uses a private desktop with no visible windows or input-desktop switch.

Baseline images reveal forest canopy drawn underneath occupied sites and paths/thresholds concealed by interpolated terrain. The prototype grounds existing structures against the rendered height grid, uses bounded clearing masks around recorded occupied plots, and softens the mask edges. No new artwork or simulated resources are generated. These are visual clearing approximations, not a new harvest or land-use authority.

The final prototype built once in 513 ms. Across its three views it reported 70 / 61 / 48 total scene draw calls. Total rendered primitives were approximately 1.40m / 1.39m / 1.10m; these include terrain, water, shadows and other passes, so they are NOT city triangle counts. No claim of steady frame rate or a general GPU speedup follows from these numbers.

**Keep:** stable saved plots, existing building kits, batched rendering, and shared geometry across camera distances.

**Not accepted as finished:** forest color/scale still dominates; cleared sites need actual polygon-based land-use integration; small hamlets remain physically small from 10,000 feet; growth, farmland expansion, and battle damage have not been exercised by this prototype. The wider terrain/coast representation remains outside this checkpoint.

## Next bounded implementation

1. Cache a small settlement's assembled appearance across camera changes; invalidate only changed physical state. Retain a bounded path for large cities.
2. Make visible-ground alignment and occupied land cover part of one coherent rendering layer. Avoid merely raising every object or drawing through terrain.
3. Demonstrate three states of this same layout: original, one added neighborhood/field, and localized battle damage. Unaffected geometry must retain its identity.
4. Measure one repeat of the same CPU/render workload. Separately investigate and schedule opponent daily work across frames; the present navigation clock hold is only a mitigation.

Stop at each review checkpoint. No new image generation, long campaign replay, broad refactor, or repeated unchanged benchmarks.

## Reproduction and local outputs

`tests/settlement_cost_reference.tscn` is an opt-in headless, one-day cost probe. `tests/settlement_grounding_reference.tscn` is an opt-in visual specimen; run it only through `tools/run_isolated_gpu_probe.ps1` on the private desktop. Both require the `--settlement-reference` user argument. Both READ the current quicksave; the cost probe advances only its own in-memory world. Neither writes a save. Copy or freeze a chosen quicksave before future paired comparisons; the three camera captures within one run share one loaded state.

Local-only outputs, intentionally excluded from Git: `artifacts/settlement-baseline.json`, `artifacts/settlement-reference-1000.png` (and 3000/10000), `artifacts/settlement-prototype-1000.png` (and 3000/10000), `artifacts/settlement-prototype.json`, probe logs and `artifacts/settlement-review.html`. Private saves and generated captures are not included in the repository.

Validation: one completed diagnostic day; baseline and prototype GPU captures at three heights; final prototype exits zero with geometry identity checks true and no logged script errors. Live game appearance, simulation behavior and saves are unchanged by this checkpoint.