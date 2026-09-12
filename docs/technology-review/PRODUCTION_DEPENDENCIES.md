# Production dependency validation

The common technology graph audit now checks civilian manufacturing and operating-installation dependencies alongside discovery prerequisites. A standalone entry point is `tools/audit_production_dependencies.gd`; both use the same pure audit helper.

The audit begins with named raw resources from ResourceSystem. A recipe becomes structurally fabricable only when every material and setup tool has a reachable source. Its main output and by-products then become available. A powered recipe also needs electricity from a fabricable generator: generator construction components and operating inputs must already have sources. An empty storage installation cannot introduce electricity. Alternative recipes can break otherwise circular tooling or power dependencies. Unknown stock names, unknown method gates and invalid quantities/work/power values are reported.

Current result: all 130 civilian recipes and eleven installation types have structural paths, with no missing named sources or blocked chains. The ordinary graph audit also reports 453 discovery identities and 227 explicit learning routes without errors.

Seven tests cover an invented input name, self-tooling cycles with and without an independent initial recipe, a solar-only electricity bootstrap failure and its generator alternative, by-products behind a power requirement, empty storage, invalid numeric costs and the entire live civilian/installation catalog. The helper does not mutate input catalogs.

This is an authoring check, not campaign completion evidence. It assumes all raw resources obtainable and every method known. It does not simulate research/material coupling, geography, finite quantities, workforce, commissioning duration, production-line capacity, simultaneous power demand or acquisition delays. Military recipes outside the civilian product catalog remain outside this audit. Those coupled and campaign-level requirements still need separate validation.
