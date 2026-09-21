# Campaign accumulation audit

Base `e7a22a40`; branch `codex/campaign-accumulation`; worktree `/Users/seanpurtill/.codex/worktrees/campaign-performance`.

## Confirmed and fixed

**Unchanged fog copied all exploration records every frame.** `_refresh_discovery_mask` called `fog_snapshot`, which deep-copied every circle, trail and trail point before checking `fog_revision`. The copy happened while paused as well as playing. Now the renderer reads the revision and live convoy origin first, updates material origin uniforms as before, and only requests the full snapshot when a repaint is needed. Force refreshes and new exploration retain the existing painter. No discovery record is removed or changed.

Synthetic tests call the actual refresh function 120 times with an unchanged revision, no material objects, and 64 points per trail (below the authored 128-point bound):

| Explored trails | Before, ms/frame | After, ms/frame |
| --- | ---: | ---: |
| 0 | 0.0031 | 0.0007 |
| 64 | 2.747 | 0.0007 |
| 256 | 11.464 | 0.0007 |
| 1,024 | 49.586 | 0.0007 |

These are CPU costs of this function, not measured frame rates. Real material updates and GPU work are additional. At the large workload the old copy alone exceeded an entire 60 FPS frame budget. A record cap did not prevent a serious accumulated cost.

**Finished early buildings scanned permanent construction history.** `_synchronize_early_works` looked up shelter and hall materials before finding whether any plot still needed conversion. A missing matching record could scan the complete ledger twice per call indefinitely. Material lookup is now lazy: shelters read once when the first eligible plot converts; the hall reads only when its eligible plot exists. Missing materials, settlement filtering, event order and first matching record semantics are unchanged. No persistent cache or archive pruning is introduced.

With no pending conversions, the actual method grew from 0.731 ms at 1,000 unrelated ledger records to 9.251 ms at 10,000 and 88.161 ms at 100,000. It now remains about 0.004–0.005 ms. Counts represent synthetic workloads, not claims about a particular campaign year. The permanent building ledger remains intact.

## Validation

Eight focused cases cover unchanged fog, live origin updates, expired material references, revision and force repaints, both trail/circle dispatch, finished conversions, actual conversions, original settlement-specific materials and permanent building records. Actual rasterization formulas are unchanged. The headless stress probe is `tools/accumulated_history_probe.tscn`; it does not read or write saves or launch a player window. Raw component measurements are in campaign-accumulation-2026-09-20.json.

The same 24-day, twelve-opponent day-11238 world replay also matches full saved simulation state, excluding only the wall-clock timestamp. Mean daily CPU was essentially unchanged (587.47 → 588.06 ms in these runs); this pass claims no whole-world daily speedup from that fixture. The main benefit is avoided per-frame history copying, which the daily-tick harness does not measure, and avoided scans under larger building histories. Replay shutdown retains the previously observed two-object/one-resource warning; focused tests have zero orphans.

## Other accumulation findings and next priorities

- **Exploration changes still repaint all retained areas.** The unchanged-frame problem is fixed; the full rasterization on new scout reports is not. A future incremental mask must correctly handle history trimming, extended trails, new worlds and forced rebuilds before replacing this path.
- **World size multiplies ordinary work.** `WorldSimulation.refresh_views` refreshes each observer's view of other civilizations. Civilization count creates pairwise work; additional strategic regions/settlements enlarge each view. Existing equality checks avoid some copying but still compare nested values. Measure settlement/formation counts independently of campaign age before changing update scheduling or information propagation.
- **Ordinary histories are mostly already bounded.** Economic ledger reaches 1,000 records and economy history 730 in the available day-11238 fixture. Code also bounds scout reports at 256, diplomatic history at 24, war history at 64, discovery log at 512 and demographic episodes at 120. Health history reaches 375 monthly entries in the fixture and is capped at 480. Their mere retention does not imply unlimited growth; their frequent consumers still need scrutiny. The inventory inspected representative nested array records rather than claiming a complete memory profile.
- **Permanent architecture deserves indexing, not deletion.** The lazy lookup fixes idle scanning. Actual conversions and open historical screens can still scan the ledger. An append-aware index or paged read can retain the full history if measurements warrant it.
- **Separate longevity correctness concerns:** government candidate creation tests total `people.size()<96`, while deceased records remain in that array. Historical figures similarly stop creation at 512 total records. These can exhaust succession/emergence over a long campaign; they are not evidence of unbounded CPU growth. Fixing this requires separating active capacity from archived identities while preserving references and names, rather than deleting the past or raising every active limit. No succession rules were changed in this performance pass. Strategic charts also retain only 256 annual samples; that is an existing historical-coverage limitation, not an infinite archive.

No player/editor restart, save-schema change, food simplification, skipped days or reduced AI decision cadence. The original year-100 campaign remains unavailable; these fixes confirm accumulating cost mechanisms without proving the entire reported slowdown is resolved.
