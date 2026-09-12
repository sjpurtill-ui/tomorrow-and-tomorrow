# Early food processing worker delivery

READY for integrator review of this bounded slice; not integrated into canonical main or a player release.

Worktree: `/Users/seanpurtill/.codex/worktrees/ef8f/tomorrow-and-tomorrow`
Branch: `codex/tech-tree-revamp`
Canonical base: `2041666f666d9a487795326325df4d714dcda61f`
Committed design/runtime source: `82b574e` on `codex/technology-implementation`
Isolated compatibility merge: `bde683e55ec889a30607bd62e8ff915280b96e90`

The source task explicitly approved using the isolated compatibility merge as this worker's baseline after clarifying its warning against blanket canonical integration. The source's unfinished communications files were excluded. The extra `codex/tech-food-processing` branch points at unchanged canonical base and contains no delivery.

## Behavior

Three exact authored IDs are implemented from `food-agriculture-depth.json`: `hearth_roasting_control`, `earth_oven_cooking`, and `food_steaming_vessels`. Hearth roasting is an empirical root. Earth ovens require hearth roasting. Steaming retains hearth roasting AND either clay shaping OR basketry. No calendar gates or automatic mastery; ordinary research and adoption remain authoritative.

Settled meal preparation reserves at most 10% of existing Logistics worker capacity before ordinary preservation. It selects the most productive adopted method with supplied inputs. At full adoption one worker-day handles 8 roasting, 12 earth-oven, or 10 steaming rations. Preparation is bounded by actual fresh food consumed that day. It consumes Timber at 0.03/0.015/0.02 per prepared ration respectively; ovens additionally use 0.002 Stone, and steaming 0.04 Freshwater plus 0.002 Clay or Fiber Plants for utensil upkeep. Quantities are initial game balance values, not physical-unit claims.

Prepared fresh rations contribute `0.04 * prepared / all_eaten` to the existing diet-quality calculation, capped with the existing total quality range. This applies neither to uneaten stores nor dry/preserved foods. No calories, shelf life, population, discoveries, staff or new inventory authority are created. Travel, absent settlement, absent workers, no adoption and missing inputs prevent operation. Material shortages at execution reduce actual work; reserved but unused processing time remains idle for that day.

The existing preservation pathways now have an explicit material tradeoff: air drying converts plants to dry staples at the existing 88% yield without fuel; smoking converts meat/fish at the existing 82% yield while consuming 0.04 Timber per input ration. Fuel shortages bound smoking output. Zero adoption no longer receives a fabricated 5% operating floor. Cooking competes with this same Logistics capacity, while existing Crafting participation remains unchanged. Food reports show actual prepared meals, material inputs and smoking fuel; research summaries explain conditions.

Compatibility inspection also repaired an inherited source bug: sixteen shipbuilding discoveries used `Movement`, which became an unsupported thirteenth research domain. The classifier now maps that legacy direction to Logistics. The graph audit rejects unsupported research domains/subcategories. A canonical research-redistribution test was updated to the approved absence of calendar locks; it still checks prerequisite waiting and conservation.

## Verification

Godot 4.7.2, explicit worktree path, headless only. **78 cases pass**, with zero errors, failures, skips or orphan nodes, in separate suite processes:

| Suite | Cases |
| --- | ---: |
| food_preparation | 12 |
| technology_requirements | 12 |
| research_redistribution | 2 |
| food_water_knowledge | 10 |
| canning_preservation | 8 |
| discovery_projects | 9 |
| technology_tree | 9 |
| shipbuilding | 5 |
| research_visual_atlas | 11 |

Invocation: `/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/seanpurtill/.codex/worktrees/ef8f/tomorrow-and-tomorrow -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode -a res://tests/test_<suite>.gd`.

Final logs are `/tmp/tt-food-<suite>.log`, except requirements at `/tmp/tt-food-requirements.log`. New tests exercise actual daily food execution, food/input conservation, shortage fallback, adoption, staffing competition, travel, UI report data, separate rival ownership and serialized WorldSimulation round trip.

Graph audit: `-s res://tools/audit_technology_graph.gd`; `/tmp/tt-food-final-graph.log` reports **559 live definitions, 336 explicit learning routes, 240 recipes, 12 plants, zero graph/channel/production-closure errors**. This is structural closure, not campaign completion evidence. Normal headless entry boots cleanly (`--quit-after 3`, `/tmp/tt-food-boot.log`). Initial asset import and `git diff --check` pass. No graphical game/editor process was launched or stopped. Headless interface tests do not establish native visual layout quality.

## Integration and limits

Changes owned by this worker: new `scripts/food_preparation.gd`, `tests/test_food_preparation.gd`, and this handoff; small wiring/behavior changes in DiscoverySystem, FoodSystem, technology_catalog_contract, dock_content_economy, audit_technology_graph and two existing tests. DiscoverySystem and audit_technology_graph overlap the source's unfinished communications work: integrate those hunks deliberately. The 625-file inherited compatibility merge is **not** a claim that this worker authored or exhaustively validated the whole baseline. Review it separately from the food commit; do not blindly cherry-pick the food commit onto canonical without its technology infrastructure dependencies.

Save schema and existing IDs are unchanged by the food slice. Optional daily report data uses existing metrics; stocks, adoption and nutrition retain existing persistence. Rival state round trip passes. Source-baseline save extensions have their own compatibility limits and were not all revalidated here. No canonical integration, player release, whole-history pacing or 5,000-discovery completion is claimed.

Cooking utensils are represented by supplied material upkeep, not separately commissioned kitchen assets. Staff time may be conservatively reserved for food later preserved or spoiled. The existing food forecast projects stock balance and does not simulate future cooking or smoking fuel purchases; it must not be read as an exact future production schedule. There is no fire/weather safety model or crop/species-specific cooking model. Freezing, controlled atmospheres, oil quality and later food-processing designs require their own storage/commodity operating models; they were not added as passive universal bonuses. New subject artwork remains absent. The source design documents, coverage and ledger remain read-only and unchanged.
