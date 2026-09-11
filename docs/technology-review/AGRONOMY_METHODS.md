# Agronomy methods

Twenty distinct discoveries extend the production catalog to 361. They affect staffed, settled cultivation after seed selection; they do not grant food, seeds, farmland or workers. All use authored causal prerequisites and recognized fertile soil, with no calendar gates.

| Discovery | Foundations | Practice family |
|---|---|---|
| Germination Trials | seed_selection, standard_measures | establishment |
| Seed Cleaning | seed_selection, basketry | establishment |
| Sowing Depth Trials | germination_trials, experimental_controls | establishment |
| Row Spacing Trials | germination_trials, standard_measures | establishment |
| Seedbed Firming | sowing_depth_trials, crop_calendars | establishment |
| Mass Seed Selection | seed_reserves, crop_calendars | breeding |
| Progeny Rows | mass_seed_selection, tallies | breeding |
| Controlled Pollination | progeny_rows, experimental_controls | breeding |
| Field Variety Trials | progeny_rows, statistical_sampling | breeding |
| Regional Seed Trials | field_variety_trials, regional_maps | breeding |
| Crop Residue Cover | managed_fallow, cordage | cover |
| Green Manure Crops | crop_rotation, seed_reserves | cover |
| Cover Crop Mixtures | green_manure_crops, field_variety_trials | cover |
| Contour Cultivation | geometric_survey, crop_calendars | tillage |
| Strip Cropping | contour_cultivation, crop_rotation | tillage |
| Reduced Tillage | contour_cultivation, soil_assays | tillage |
| Soil Infiltration Trials | soil_assays, standard_measures | water |
| Mulch Water Management | crop_residue_cover, soil_infiltration_trials | water |
| Irrigation Loss Accounts | irrigation_schedules, material_accounting | water |
| Soil Moisture Scheduling | soil_infiltration_trials, irrigation_loss_accounts | water |

## Operating behavior

Within each family, the highest rank multiplied by adoption selects the operating practice. Its adoption scales benefits and costs. Across families, gross yield gain is capped at 30%, labor cost at 20%, harvest-area cost at 15%, soil-wear protection at 65%, and adverse-weather loss reduction at 30%. Net cultivation yield multiplies gross performance by the remaining labor and harvest area. Green manure can therefore reduce current harvest while protecting soil. Weather buffering reduces adverse losses; it does not amplify favorable weather. Soil protection reduces existing cultivation pressure damage and does not instantly restore land.

These are explicit game-design coefficients, not measured agronomic results. Labor and land costs are aggregate output multipliers rather than separately assigned work or individual plots. The model does not yet represent crop genotypes, seed inventories, nitrogen balances, field geometry, water distribution or climate-specific practice selection. The ranked family choice is not an agronomic optimizer.

## Validation and compatibility

57 cases passed with zero errors, failures, skips or orphans: eight agronomy, ten food/water, nineteen owned simulation, eleven research atlas and nine technology tree. Tests exercise actual output, soil wear, costs, gating, adoption, bounded family stacking, adverse weather and civilization isolation. The graph has 361 identities and 135 explicit learning routes with no errors. The ideal resource-dependency audit reaches all 361; it does not simulate production costs or pacing. Native presentation remains unverified.

No new save record shape. Discoveries use existing known-identity and adoption storage. Older builds do not recognize new identities. Shared files include DiscoverySystem and FoodSystem; changes remain in the implementation worktree pending integration.

## Historical grounding

The distinctions among soil cover, reduced disturbance and crop diversity follow [NRCS soil-health principles](https://www.nrcs.usda.gov/conservation-basics/soil/soil-health/soil-health-on-cropland) and its discussion of [cover crops](https://www.nrcs.usda.gov/conservation-basics/soil/soil-health/cover-crops-for-soil-health). Selection and deliberate crossing are distinct practices in the [USDA ARS history of corn breeding](https://www.ars.usda.gov/oc/timeline/corn/). These sources support the distinctions, not universal benefits, prerequisite chronology or game coefficients.
