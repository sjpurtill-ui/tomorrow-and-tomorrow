# Strategic charts

Adds observed population to Settlement / People and civilization population to the population ledger. Economy / Food & Water shows reserve runway and daily production/consumption; Materials shows delivered physical stocks. Economy / Wealth shows the selected city's stocks and, after adoption, local weighed-metal or currency accounts. Currency holdings are not a valuation of land, buildings or enterprises.

History is sampled after primary and secondary daily resource processing. Each owned city and the civilization population scope retain at most 120 monthly and 256 annual observations. Annual points are the last observation of their year, not annual averages. No resident objects or foreign intelligence are added. Removed cities' chart ledgers are pruned on sampling. Sampling begins on the next simulation day and then every 30 days; gaps are not backfilled.

Existing food/water, economic and demographic logs are reused only where they actually recorded a measure. Missing observations are not zero. No historic private currency is inferred from supply. At most 1200 observations are sent to a plot. Date spacing uses actual elapsed days; hover reports the observation date and values. Range controls cover 1, 10, 100 years or all available observations, ending at the latest recorded observation, and retain their choice by chart/city.

GameState's reflected save system persists strategic_history. An old save without this field starts empty and can use its existing genuine logs. No save format bump or migration of other systems is required. Reload the integrated build to load the sampling hook; workers do not restart the player.

The shared dock now creates tabs from provider metadata rather than assuming three tabs. Existing sections retain their labels and behavior; previously hidden fourth tabs become reachable.

## Validation

- Focused GdUnit tests: bounded 400-year history, billion-person counts, distinct city stocks and money, missing observations, legacy observations, range controls, actual save/load and an old save with the field removed. Temporary uniquely named save slot is removed by the test.
- Existing city resource regression suite.
- Muted isolated GPU probe (`tools/strategic_charts_probe.tscn`): actual DockPanel and Economy provider, fourth tab, chart sizes, range controls, hover; self exits. Its explicitly labeled synthetic test data is never saved to the campaign. Capture under artifacts/strategic-charts.png is not a source asset.

## Integration

Shared hooks: GameState dictionary/reset; one local_terrain sample call after _process_other_city_resources; DockBlocks trend_chart arm; DockPanel dynamic tabs. Preserve concurrent scout_archive renderer and military KPI bindings. No terrain, scouting, military simulation or CivilizationSystem changes.
