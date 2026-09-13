# Selected food resources and preparation

READY for integration review. Isolated worktree:
`/Users/seanpurtill/Documents/Codex/tt-selected-food-processing`, branch
`codex/selected-food-processing`, base
`25f03199593b1bc25c8f4d873b17420e8da6986f`.
This delivery does not claim to be the current player build.

Six existing authored identities become operating discoveries:
edible_resource_recognition, nut_kernel_shelling, acorn_leaching,
root_grating_dewatering, pulse_splitting and fruit_pulp_screening.
Every original ALL and grouped OR predicate is retained. All parents resolve.
Recognition remains an early root, without a calendar or modern laboratory gate.
Existing acquisition/adoption systems remain authoritative. No instant mastery,
free resources, calorie multiplier or new population/labor owner is introduced.

## Actual operating behavior

The new helper models **curated compatible ingredient opportunity classes** in
this generated world. It is explicitly not a botanical species-observation map.
The world seed and one-kilometre location cell choose stable occurrences and
abundances, conditioned on the existing land, temperature, precipitation and
woodland profile. Knowledge and day do not reroll occurrence. Seasonal conditions
and the existing Wild gathering source-health ledger limit collection.

Adopted recognition and an adopted applicable preparation method allow a small
collection allocation, at most eight percent of existing Food workers. Source
classes share that allocation. Each source also has a bounded local daily
opportunity (at most 40 pre-processing ration-equivalent units before abundance,
health and seasonal reductions). A collector cannot obtain unlimited ingredients
by assigning an arbitrarily large workforce. Actual collector time is subtracted
before ordinary hunting/gathering/cultivation runs. Siege access also bounds
collection. A saved local daily stamp prevents repeated harvest calls. Actual
selected gathering participates in the existing source-health pressure update.

Only typed identified lots are produced: selected nuts, acorns, roots, pulses and
fruit. Generic Fresh plants, dry staples, unfamiliar organisms and unrelated
stocks cannot be relabeled into these ingredients. Source class, source-cell ID
and finite coordinates travel with the lot. Processing rejects malformed or
mismatched source records before spending work or ingredients.

The five preparation methods use the existing FoodBatches equipment quotes,
paid material installation and shared Logistics handling budget. Each has finite
throughput, adopted method capacity, real tooling upkeep and handling losses:

| Method | Actual result | Continuing requirements |
| --- | --- | --- |
| Nut shelling | 72% recovered kernels into Dry staples | Stone tool upkeep and sorting work |
| Acorn leaching | 65% leached meal, held two days | Mortar/retaining equipment, substantial water, fiber upkeep and handling |
| Root grating/dewatering | 80% pressed pulp, held until next day | Grating/pressing tools, water, stone upkeep and work |
| Pulse splitting | 82% split fraction, held until next day | Conditioning water, tools and sorting work |
| Fruit pulp screening | 75% pulp into Fresh plants | Screens/vessels, cleaning water, fiber upkeep and work |

Leached acorn meal, pressed root pulp and split pulses are **not edible rations**.
After their holding period, an adopted hearth cooking method spends additional
Logistics time, timber, water and stone upkeep; acorns and pulses also require
adopted clay shaping and vessel upkeep. Cooking returns 95% of the prepared
fraction into the ordinary Fresh plants meal category. Missing knowledge, water,
fuel, work or vessels leaves it unavailable. Root processing is not a universal
cassava detoxification claim. The curated root class covers compatible food roots
whose defined subsequent preparation is sufficient in this model.

All finished outputs enter existing consumption, diet, spoilage, storage and
food-obligation systems. Kernels retain dry-staple storage behavior; fresh pulp and
cooked meals remain perishable. Raw and in-process lots occupy existing food-batch
storage capacity and can spoil or be discarded; they never feed people early.
Losses are recorded as lost food energy, not extra shell/peel fuel resources.

Automatic installation requires an actual suitable waiting lot, remaining
Logistics work, supplies and an edible three-day reserve. It buys at most one
needed setup per processing call through the ordinary quote/payment path. Existing
manual equipment controls expose the five methods and explain their limited
ingredient eligibility and later cooking requirements.

## Verification

Godot 4.7.2, all processes headless with this explicit worktree:

- Import exits 0, no parser/import errors.
- Normal main-scene headless boot reaches `DIRECTION_SCREEN_READY` and exits 0,
  but shutdown reports two ObjectDB instances and one resource still in use.
  No clean-shutdown claim; log `/tmp/tt-selected-food-boot.log`.
- **91 distinct behavior cases passed across targeted runs**: selected-food 14,
  FoodBatches 30, grain processing 20, meal preparation 14, crop nutrition 13.
  The final selected-food run passes all 14 with zero errors, failures, skipped,
  flaky or orphan cases (`/tmp/tt-selected-food-ready-tests.log`).
- The 68-case food/cooking/nutrition run passed before the final narrow guard
  preventing automatic installation with zero remaining work; the final 14-case
  run covers that guard. Grain's 20 cases passed separately during the combined
  acceptance run. Logs: `/tmp/tt-selected-food-finaltests.log` and
  `/tmp/tt-selected-food-acceptance.log`.
- Cases cover stable/incompatible local sources, finite collector and local
  capacity, same-day collection/processing conservation, zero/partial work and
  water, rejected source records, no generic-food conversion, material and yield
  losses, delayed cooking, actual daily collector subtraction, demand-driven paid
  equipment, secondary-city and separate-actor isolation, and full binary save
  continuation of unfinished acorn meal with its source identity and paid steps.
- Existing shared-budget regression includes every old and new food-lot kind;
  its fixture now supplies valid source provenance for the new selected classes.
  An initial malformed-fixture interruption exposed the missing defensive check,
  which is corrected and covered by a dedicated rejection case.
- Standalone graph: **737 discoveries / 519 explicit routes / 396 recipes /
  20 facilities** on this base, with no graph/dependency errors. Five new food
  equipment methods are operating FoodBatches processes, not civilian workshop
  recipe-count inflation. Current canonical's two type discoveries are absent
  from this older isolated base; integration should produce 739 if no other
  identities change. Log: `/tmp/tt-selected-food-graph.log`.
- All 15 catalog-tool tests pass; original predicates remain unchanged.

Graph closure is not evidence of geographical availability or long campaign
pacing. No long campaign run was restarted.

## Save compatibility, limits and integration

No new top-level save field. Selected raw/intermediate kinds and equipment share
FoodBatches; the optional local `selected_harvest_day` field is validated. Selected
lots require a matching class/cell source ID and finite coordinates. Old cereal
lots need no new fields. Existing secondary-city resource swapping and binary save
validation preserve the extended food ledger; they require no new state owner.

Files owned: new SelectedFoodProcessing/SelectedFoodKnowledge, narrow FoodSystem,
FoodBatches/FoodBatchKnowledge, FoodBatchesPanel, additive DiscoverySystem, focused
tests and this handoff. No CivilianIndustry, GameState, SaveSystem, population,
terrain or CivilizationDay edits. At integration, preserve the integrator's
new `Ops.advance(day,daily_context)` call and type-discovery additions.

Limits: compatible-source opportunities are aggregate procedural classes, not a
complete species/geographic-history database. They use existing settlement-local
source health, not a new globally depleted botanical patch map. Rates, energy
fractions and one/two-day holds are game abstractions, not human food-preparation
instructions or scientific safety thresholds. Finished food retains the existing
coarse five-category diet model; no species-specific nutrient chemistry is claimed.
Future forecasts remain conservative and do not promise these new raw lots as
edible future meals. The six illustrations are a separate pending delivery.
Full 5,000-discovery coverage and 2,500–3,000-year progression remain incomplete.

Mechanism references (not invention dates or unlock rules):

- [National Park Service: acorn preparation](https://home.nps.gov/articles/000/recipes-acorn-bread-chia-pudding.htm)
  describes distinct shelling, grinding, leaching and cooking steps in a documented
  Cahuilla preparation tradition.
- [FAO: root and tuber processing](https://www.fao.org/4/x5415e/x5415e05.htm)
  distinguishes multi-step, ingredient-specific processing and subsequent heat
  treatments; grating and pressing alone do not establish universal edibility.
- [FAO: fruit and vegetable process flows](https://www.fao.org/4/v5030e/V5030E0y.htm)
  supplies context for screening and subsequent food-processing routes.

Canonical combined acceptance `c1f13057d6dee1e53cce319d16fc7fc112c5820c`:166 runtime worktree and98 canonical cases pass, plus12 atlas on both. Seven new textures768/mips; clean740/522/402/20 graph, boot, exact snapshot and15ledger tests. Art162/740; no player launch or package rebuild. See latest integration status for combined sources and limits.
