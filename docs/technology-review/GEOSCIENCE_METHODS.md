# Field geology and prospecting implementation review

Sixteen individually authored discoveries connect mineral observation, mapped geology, representative sampling and spatial estimation. The dependency graph and numerical benefits below are game design choices, not claims that every civilization followed one historical sequence. No calendar or era gate applies.

The distinction between mineral hardness and density is grounded in the [USGS mineral properties guide](https://pubs.usgs.gov/gip/gemstones/mineral.html). Relative layering and cross-cutting relationships follow the [USGS explanation of stratigraphy](https://pubs.usgs.gov/gip/fossils/laws.html). Mapping, sampling, geochemistry and deposit models are distinct components of [USGS mineral resource assessment](https://pubs.usgs.gov/of/2007/1434/). Spatially located measurements and covariance models follow the [USGS geostatistics primer](https://pubs.usgs.gov/publication/ofr20091103); geochemical anomaly interpretation is informed by [USGS geochemical mapping methods](https://pubs.usgs.gov/tm/11c05/).

## Authored capabilities

| Discovery | Causal foundations | Practical method | Survey-effort improvements at full adoption |
|---|---|---|---|
| Mineral Streak Tests | `stone_sorting`, `pit_firing` | Compare fresh surfaces and powder streaks from several samples before assigning a mineral identity. | Identification +12%; extent survey +4% |
| Cleavage and Fracture Classification | `stone_sorting`, `quarry_reading` | Record how fresh pieces split and compare those patterns across outcrops. | Identification +10%; extent survey +8% |
| Comparative Mineral Hardness | `controlled_flaking`, `standard_measures` | Rank paired scratch tests rather than judging stones by color or how hard they seem to strike. | Identification +12%; extent survey +6% |
| Mineral Specific Gravity | `fractional_quantities`, `standard_measures`, `displacement_buoyancy` | Weigh representative pieces and compare their displacement against the same water reference. | Identification +15%; extent survey +8% |
| Relative Stratigraphy | `quarry_reading`, `route_memory` | Trace exposed layers and record which beds overlie or cut across others. | Identification +8%; extent survey +14% |
| Lithologic Correlation | `relative_stratigraphy`, `mineral_cleavage`, `regional_maps` | Correlate texture, mineral content and neighboring beds across recorded localities. | Identification +10%; extent survey +16% |
| Geologic Cross Sections | `geometric_survey`, `relative_stratigraphy`, `similar_triangles` | Draw sections through measured exposures and revise them when new observations disagree. | Identification +6%; extent survey +20% |
| Structural Geologic Mapping | `geologic_cross_sections`, `trigonometry`, `regional_maps` | Measure orientations and connect structural observations across mapped exposures. | Identification +8%; extent survey +22% |
| Sediment Provenance | `relative_stratigraphy`, `mineral_specific_gravity`, `seasonal_patterns` | Compare sorted sediment at successive locations while accounting for transport and seasonal flow. | Identification +16%; extent survey +8% |
| Systematic Channel Sampling | `ore_assaying`, `standard_measures`, `geometric_survey` | Keep sample widths, locations and barren intervals in the record alongside promising assays. | Identification +6%; extent survey +20% |
| Geochemical Baselines | `chemical_distillation`, `statistical_sampling`, `systematic_channel_sampling` | Compare consistent sample media and analytical procedures across representative background ground. | Identification +18%; extent survey +12% |
| Geochemical Anomaly Mapping | `geochemical_baselines`, `regional_maps`, `measurement_uncertainty` | Map departures from local baselines and test whether neighboring samples reproduce the pattern. | Identification +20%; extent survey +18% |
| Grade–Tonnage Models | `ore_assaying`, `statistical_sampling`, `geologic_cross_sections`, `ratio_proportion` | Compare measured geometry with distributions from sampled occurrences and retain uncertainty. | Identification +4%; extent survey +24% |
| Spatial Variograms | `statistical_inference`, `coordinate_geometry`, `systematic_channel_sampling` | Compare differences between sample pairs over several separation distances and orientations. | Identification +4%; extent survey +20% |
| Resource Kriging | `spatial_variograms`, `matrix_algebra`, `least_squares_estimation` | Solve weighted spatial estimates and test them against withheld sample measurements. | Identification +4%; extent survey +28% |
| Orebody Block Models | `geologic_cross_sections`, `resource_kriging`, `grade_tonnage_models` | Estimate bounded blocks, retain uncertain regions and revise the model as sampling proceeds. | Identification +2%; extent survey +30% |

## Operating rules

Benefits apply only to the Survey workforce contribution for the explicitly authored resource targets. They do not amplify passive clues or research-emphasis terms. Adoption scales the benefit; no Survey workers means no benefit. Similar methods use the strongest adopted contribution within each of five families: identification, mapping, sampling, interpretation and estimation. Contributions across families combine, capped at 75%. These are balance parameters.

The calculation is rebuilt once per local resource day, so ownership, adoption and staffing changes are observed without a persistent cross-civilization cache. Existing special identification rules remain mandatory. Methods cannot create occurrences, grant stock, change reserve quantities, make extraction sites accessible or unveil the map. The research inspector names only already visible target materials. Earlier discoveries retain their original routes; none requires the new branch to remain reachable.

## Implementation and limits

The current implementation converts these methods into targeted reconnaissance and extent-survey efficiency. It does not compute a real three-dimensional orebody, display a geologic map, store individual sample assays, calculate reserve confidence intervals, or model instrument supply and laboratory consumables. The underlying survey allocation across occurrences retains its existing aggregate behavior; this checkpoint does not claim a new per-expedition labor allocator. Those deeper field and operating systems remain work toward the full simulation goal.

The new entries use normal discovery/adoption records and need no new saved-state shape. Old empirical-route tests continue to check the earlier catalog while recognizing that later geostatistics legitimately depends on mathematics. The 5,000-discovery target remains unchanged.
