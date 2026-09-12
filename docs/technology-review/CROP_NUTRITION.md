# Crop nutrients and industrial fertilizer

Implemented in the technology worktree, pending canonical integration. This adds eleven authored discoveries and twelve physical recipes, including a manufacturing recipe attached to the existing Phosphate Dressing identity.

| Discovery | Foundations | Implemented consequence |
|---|---|---|
| Nutrient Response Trials | Comparative Soil Assays + Experimental Controls | Farmers apply manufactured nutrients; uptake consumes local reserves and changes cultivation output. |
| Mineral Nitrate Dressing | Nitrate Beds + Nutrient Response Trials | Prepared nitrate fertilizer from actual nitrate stock. |
| Sulfur Dioxide Recovery | Sulfur Purification + Sealed Vessels | Recovered industrial sulfur feedstock. |
| Sulfuric Acid Production | Sulfur Dioxide Recovery + Chemical Distillation + Pressure Vessels | An acid feedstock for phosphate and ammonium sulfate manufacture. |
| Phosphate Solubilization | Phosphate Dressing + Sulfuric Acid Production + Nutrient Response Trials | More available phosphate input, requiring manufactured acid. |
| Compressed Air Systems | Pressure Vessels + Electric Motors | Powered compressed-air feedstock; atmospheric air is ambient, but apparatus, labor and electricity are required. |
| Cryogenic Air Separation | Compressed Air Systems + Mechanical Refrigeration + Chemical Distillation | Powered nitrogen production with oxygen coproduct. |
| Water Electrolysis | Electrochemical Cells + Electrical Generators + Pressure Vessels | Powered hydrogen production with oxygen coproduct. |
| Iron Ammonia Catalysts | Bloomery Smelting + Experimental Controls + Chemical Distillation | Manufactured catalyst installed as ammonia-line tooling. |
| Catalytic Ammonia Synthesis | Iron Ammonia Catalysts + Cryogenic Air Separation + Pressure Vessels; either Chlor-Alkali Cells or Water Electrolysis | Powered manufacture using actual nitrogen and hydrogen, preserving two hydrogen research routes. |
| Ammonium Sulfate Fertilizer | Catalytic Ammonia Synthesis + Sulfuric Acid Production + Nutrient Response Trials | Industrial nitrogen fertilizer without dependence on a nitrate deposit. |

Every new discovery has day zero metadata and causal prerequisites. There are no calendar unlock gates. These are distinct feedstocks, processes or field operations; the eleven entries are not repeated percentage modifiers.

All twelve recipes use normal workshop setup and shared production labor. Powered recipes draw from the same finite current-day electrical service as other manufacturing. Inputs are consumed as work progresses, finished batches and coproducts enter actual stores, and saved partial work cannot issue its output twice. Installed catalyst is setup equipment, rather than a recurring full batch of feedstock. Nitrogen and hydrogen quantities are game batches, not molar proportions or operating instructions.

The industrial chain was tested from stocked construction components, sulfur and water through commissioned photovoltaic generation, gas separation, electrolysis, catalyst, acid, ammonia and ammonium sulfate. No intermediate nitrogen, hydrogen, ammonia or fertilizer was granted in that test. The mineral route was separately tested from nitrate and phosphate-rock stocks into manufactured dressing and crop uptake.

## Cultivation behavior

The existing ambient fertility and cultivation-health model remains the baseline. The new `cultivation_nutrients` dictionary records **additional fertilizer-derived nitrogen and phosphorus reserves**, not total soil chemistry. Each settlement has its own two bounded balances; these reserves are not tradable stock and are not copied from the capital when a secondary city is created.

At full adoption, application fills up to seven days of expected uptake. The abstract demand is 0.01 nitrogen and 0.006 phosphorus per baseline cultivated ration. Nitrate Fertilizer and Ammonium Sulfate supply nitrogen; Soluble Phosphate and Ground Phosphate supply phosphorus. Ground phosphate has an initial availability factor of 0.3 against soluble phosphate's 1.0. The smaller available share of the two nutrients limits the extra harvest, with a maximum 25% increase at full adoption. Uptake debits both reserves. Adoption scales application and effective use; no research alone manufactures fertilizer or grants food.

During operating cultivation, retained nitrogen loses 0.2% and phosphorus 0.05% before application and uptake. These coefficients, availability factors, reserve target and yield ceiling are explicit initial game-balance assumptions. They are not measured crop, soil or industrial efficiencies. Cultivation already consumes its normal Food labor; no extra workers are created. No application or bonus occurs while traveling, without cultivated output, or without adopted Nutrient Response Trials. Unused land does not currently simulate seasonal leaching.

The earlier Phosphate Dressing identity now produces Ground Phosphate and no longer grants its old automatic food/soil-productivity/pollution effects. Old saves keep the discovery ID but receive the new physical behavior. This is an intentional balance change, not an unchanged-save-behavior claim.

Daily food reporting records baseline cultivated output, actual fertilizer consumption and extra harvest. The 90-day forecast keeps independent copies of just the fertilizer stocks and nutrient reserves, applies seasonal output and finite uptake, and stops projecting a continuing fertilizer advantage once supplies are exhausted. It never consumes live stocks and assumes no uncommitted future fertilizer manufacture. When no fertilizer bonus exists, the extra projection work is skipped.

## Civilizations and persistence

The normal civilian production planner considers fertilizer needs after its existing study-supply work. It uses observed cultivated output, local reserves and stock equivalents to seek a bounded replenishment target. It favors the less-covered nutrient and avoids producing an unusable complement when no current supply route exists. Existing paid workshop setup/retooling, paused-line protection and generation planning still apply. The ordinary controller was tested submitting a fertilizer production line. Its existing hunger/war investment suppression remains; emergency fertilizer investment and broader procurement planning are future work.

Primary and secondary reserves persist through the normal owned and human state representation. Missing older-save reserves default to zero. Human and owned-world preflight checks reject negative, nonfinite, oversized or malformed primary/secondary reserves before loading. The upper bound is one billion abstract units per nutrient. Owned save export/import, local-city isolation and legacy migration are covered.

## Grounding and remaining depth

The distinction between nutrient supply, crop response and context-dependent availability follows FAO's treatment of plant nutrition and fertilizer management. The simplified reserve model does not reproduce its crop-specific uptake, soil reactions or recommendations. [FAO, Plant nutrition for food security](https://www.fao.org/4/a0443e/a0443e.pdf).

Ammonia synthesis from nitrogen and hydrogen with a catalyst supplies the industrial branch's central chemical relationship. The two hydrogen-source routes and all game costs are design choices. [Nobel Prize, Fritz Haber biographical account](https://www.nobelprize.org/prizes/chemistry/1918/haber/biographical/).

Recovering nitrogen and oxygen together through cryogenic air separation is grounded in an actual industrial separation process. The game abstracts its machinery, purity and thermal design. [Linde, Air Separation Plants](https://www.linde-engineering.com/products-and-services/process-plants/air-separation-plants).

Still required for a fuller model: potassium and micronutrients, crop-specific limiting nutrients, pH and phosphorus fixation, organic nutrient cycling, field area and crop rotations in the reserve model, runoff/leaching and pollution consequences, industrial gas containment and leakage, catalyst wear, additional ammonia/hydrogen routes, fertilizer transport and acquisition planning, and natural campaign balance. The existing global soil model is not replaced by a complete nutrient simulation. No long-run completion or player-build integration is claimed.
