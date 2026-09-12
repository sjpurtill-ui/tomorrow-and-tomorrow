# Research catalog scaling

Base: `2fc24b49ff607ba2c4a6f6e1990db6e5a674e4db`. Worktree: `/Users/seanpurtill/.codex/worktrees/ef8f/tomorrow-and-tomorrow`, branch `codex/research-catalog-scaling`.

Requirement validation now revisits only discoveries whose prerequisite has become reachable. AND foundations, grouped OR alternatives, route foundations and optional cycles retain their meaning. Research channel scans and technology-tree snapshots build one temporary known-discovery dictionary, avoiding repeated linear membership scans. Existing array callers remain supported. No persistent cache survives a knowledge mutation or owner switch; research scoring, selection order, evidence, supplies and calendar behavior remain unchanged.

Validation: 62 cases across seven suites pass with zero errors, failures, flaky cases, skips or orphans: technology requirements (15), technology tree (9), civilization ownership (19), research foundations (5), redistribution (2), discovery projects (9), controller viability (3). New tests compare the work queue with the previous fixed-point algorithm on 20 deterministic mixed graphs, verify a reversed 5,000-node graph and blocked cycle, and exercise knowledge removal/acquisition between channel scans. The full live graph audit remains 614 discoveries, 396 explicit routes, 282 recipes and 17 facilities, with no broken dependencies.

Synthetic local measurements: the previous validator took 3,311,600 microseconds for a reversed 1,000-node chain; the new validator took 7,193. A forward 5,000-node chain dropped from 280,416 to 30,230 microseconds. The committed headless diagnostic `tools/benchmark_technology_requirements.gd` subsequently measured 33,828 microseconds forward and 40,248 reverse for 5,000 nodes. These are small CPU diagnostics, not frame-rate or complete 5,000-discovery campaign claims. Fixtures never enter the live catalog.

Save compatibility: no state fields or format changes. Shared files: `scripts/discovery_system.gd` eligibility/channel/tree loops only; no registration edits. Other changes are KnowledgePathways, TechnologyRequirements, their regression suite and the diagnostic. Construction workers can retain their registration hunk independently. No player launch or restart.

Evidence: `/tmp/tt-scaling-results.json`, `/tmp/tt-scaling-selection-results.json`, `/tmp/tt-scaling-graph.log`, `/tmp/tt-scaling-benchmark.log`.
