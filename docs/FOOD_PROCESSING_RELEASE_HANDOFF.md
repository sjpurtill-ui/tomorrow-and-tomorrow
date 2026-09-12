# Food processing release integration

Release target: **2026.09.12.1**. Bounded integration candidate based directly on canonical `2041666f666d9a487795326325df4d714dcda61f`, branch `codex/food-release-integration`, worktree `/Users/seanpurtill/.codex/worktrees/ef8f/tomorrow-and-tomorrow`.

The originating coordinator designated this task integrator on September 12. Source task `01a08e7d-a646-7131-a24e-5276075de165` acknowledged an exclusive canonical runtime window while continuing design-only work in its separate technology worktree.

## Independently reviewed integration scope

Worker `c247e8d840816d777a17e2170e5930dba1d8392c` was originally tested on compatibility merge `bde683e`, which included source `82b574e` and canonical `2041666`. Review of that inherited baseline identified 102 runtime files and roughly 14,700 added lines spanning military, production plants, research acquisition, licensing, staffing and save extensions. Those systems are not dependencies of the food operating helper. The full 625-file merge is excluded.

This candidate ports only the cooking/preservation implementation and report from `c247e8d`. It separately includes the reviewed pure `technology_requirements.gd` AND/OR evaluator from the source baseline, with minimal support in canonical pathways and inspector/tree presentation. The new methods keep source identity, shared hearth prerequisite and clay-shaping OR basketry alternative. Returned foreign studies cannot bypass either common or alternative prerequisites. Saved origins record the actual supporting vessel route. All three new nodes use day zero; preexisting canonical progression rules are outside this bounded port.

The canonical live catalog becomes **200 discoveries (197 existing plus three)**. The source's 556-node baseline, unfinished communications, shipbuilding-domain repair, art, industrial services, and master drafts are not included or claimed integrated. Original worker commit remains intact on `codex/tech-tree-revamp` for separate review.

## Delivered behavior

- Hearth Roasting Control, Earth Oven Cooking, and Food Steaming Vessels are ordinary researchable/adoptable discoveries.
- Supplied meal preparation uses at most 10% of existing Logistics capacity, reserved before ordinary preservation. No new staff allocation or population authority is introduced.
- At full adoption one worker-day handles 8/12/10 rations for roasting/earth ovens/steaming. Timber costs are 0.03/0.015/0.02 per actual prepared ration. Ovens also consume 0.002 Stone for upkeep; steaming consumes 0.04 Freshwater and 0.002 Clay or Fiber Plants.
- Only fresh food actually eaten receives preparation. Existing diet quality gains at most `0.04 * prepared / all_eaten`, bounded by its existing range; no new calories or shelf life are created. These quantities are initial game balance values, not physical-unit or food-safety claims.
- Smoking retains its 82% ration yield but now consumes 0.04 Timber per input ration. Missing fuel limits actual preservation. Air drying remains a fuel-free plant route with 88% yield. Zero adoption no longer receives an invented 5% processing floor.
- Food reports show actual meals, inputs and smoking fuel. The research inspector shows operating requirements, common prerequisites and the explicit vessel alternative. Tree links include alternative foundations, with existing unknown-name redaction preserved.

## Worktree verification

**69 cases pass**, zero errors/failures/skips/orphans: food preparation 14, technology tree 9, research redistribution 2, research visual atlas 9, discovery projects 9, society exchange 26. Tests include real daily food execution, shortages, preservation losses, shared staff, rival owner isolation, WorldSimulation serialization round trip, foreign evidence gates and inspector data.

Command per suite: `/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/seanpurtill/.codex/worktrees/ef8f/tomorrow-and-tomorrow -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode -a res://tests/test_<suite>.gd`. Logs: `/tmp/tt-food-port-<suite>.log`.

`tools/audit_food_integration.gd` reports 200 live definitions, three new methods and zero identity/prerequisite/reachability/channel errors. Its first draft preloaded an autoload-dependent script too early; changing the standalone audit to load it after autoload initialization fixes that tool error. The failed audit process was stopped; no player/editor was stopped. Final log: `/tmp/tt-food-port-audit.log`. `git diff --check` passes.

## Compatibility and limitations

No save schema or existing ID changes. Existing food, resource, discovery, adoption, metrics and nutrition authorities persist all state. Old saves begin using fuel limits when advanced by this build. Cooking utensil upkeep is abstract rather than a separately commissioned kitchen asset. Planned staff may be conservatively idle if food is subsequently preserved/spoiled or inputs run out. Existing forecasts do not simulate a future fuel-purchase schedule. No new cooking illustrations, fire/weather safety model, species-specific food handling or full-history pacing claim. Later grain/freezing/controlled-atmosphere operating systems remain separate work.

The food changes in DiscoverySystem and knowledge_pathways must be preserved when future technology baseline/communications changes are integrated. Only task files are committed; generated Godot UIDs/caches remain local. Canonical integration, canonical tests and packaged/running revision are recorded separately in `INTEGRATION_STATUS.md` and `FEATURE_RECONCILIATION.md` after verification.
