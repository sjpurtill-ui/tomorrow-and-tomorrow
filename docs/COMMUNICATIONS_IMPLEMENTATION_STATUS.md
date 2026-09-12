# Communications runtime handoff

Worktree: `/Users/seanpurtill/Documents/Codex/tt-communications-implementation`.
Branch: `codex/technology-communications`. Base: `604567c4bc6ae414ff256238a52e57513ed67d8c`.
Status: READY for integrator review. This is not a player release.

## Implemented behavior

Adds 48 communications discoveries to the integrated 559-discovery baseline. The isolated graph contains 607 discoveries, 389 explicit learning routes, 282 civilian recipes, and 17 facility types. Structural reachability passes; it does not prove campaign progression or 5,000-discovery completion.

Telephone repeaters and feedback oscillators accept valve or transistor amplification while retaining common foundations. Alternative recipes consume actual intermediates and workshop time. Four commissioned analysis benches consume operators, supplies, and power for finite subject-specific assistance with acquired communications equipment. Rival controllers invest against returned study demand through ordinary costed production and installation.

Paired research radio stations consume radio sets, construction materials, commissioning work, operators, paper and electricity. Once envoys physically reach a known settlement and negotiate purchased research or a partnership, stations within 120 map kilometers may transmit agreed records. Each record consumes one station service unit at each endpoint. Actual station locations must match both endpoints; war, travel, missing equipment, stale operating duty, shortages or disabled stations prevent delivery. Sequential actor updates allow unspent station duty from the immediately preceding day as a bounded receive buffer. This does not generate power or capacity. Without a link, the existing physical return carries the study.

Transmitted records still require Knowledge labor and study before evidence becomes usable. No contact, technology mastery, people, artifacts, material cargo or licenses are transmitted. Envoy return schedules remain unchanged. Mission receipts survive serialization, prevent duplicate transmission and preserve the paid research transaction when the envoys return. Rival controllers may construct one station against an active research mission; this uses local information and does not inspect hidden partner technologies. The facility inspector and purchase quote explain the operating rule.

## Verification

Headless import was clean before the radio addition; subsequent relevant runtime suites load the changed scripts successfully. Graph audit has no causal or production closure errors. Logs: `/tmp/tt-communications-graph.log`, `/tmp/tt-communications-link-tests.log`, `/tmp/tt-communications-arrival-tests.log`, `/tmp/tt-communications-final-tests.log`.

88 distinct cases pass across seven suites: communications knowledge 4, communications links 5, electronic components 5, technology operations 16, society exchange 28, research purchase 20, and research partnerships 10. Zero errors, failures, skips or orphans in their final runs.

Focused tests cover manufacturing input/work consumption, alternative foundations, finite analysis, rival paid construction, staffed radio operation, both endpoint budgets, disabled/power-starved stations, range/contact/war exclusion, physical-artifact exclusion, serialized receipts, and real purchased-research dispatch/arrival/payment/return. Existing electronic-component, operations, society-exchange, purchase and partnership regressions are included. The expanded maximum-commissioning test uses all actual facility types and rejects a workforce beyond their aggregate ceiling.

## Integration and remaining scope

Integrator owns grain processing, including a small `TechnologyOperations` workshop demand addition for `Grain.power_demand()`. Preserve it. Communications touches DiscoverySystem registration, CivilianIndustry recipes, TechnologyOperations specifications/validation, SocietyExchange analysis/arrival validation, ResearchPurchase and ResearchPartnerships return handling, the operations panel, one CivilizationController recommendation, and the graph audit, plus dedicated modules/tests. No new state authority or save version; older missions default to no transmission receipts, and existing facility data remains valid. An older executable does not know the new discoveries/facilities and is not promised forward-save compatibility.

The integrator must reconcile shared files, test combined main and verify integration before claiming player delivery. No player/editor has been launched or interrupted. Remaining full-goal work includes the other discoveries, campaign-wide historical pacing and bootstrap, broader military/civilian coverage, and the approved individual artwork. The radio link range/throughput are initial simulation tuning, not historical performance claims. This batch does not implement arbitrary remote purchase negotiations or a map-wide wired network; foreign acquisition still depends on paid physical contact and local research.

## Integration review follow-up: compatible analysis families

Independent integrator review found that the original shared analysis pool allowed optical benches to assist digital specimens. The follow-up partitions both specimen compatibility and generated service into optical, electrical, radio and digital families. Each paid recipe belongs to an explicit family; unknown/nonphysical subjects receive no service. Rival demand and installed capacity are evaluated within that same family. Existing saved `signal_analysis` values remain structurally accepted but are never consumed by the new analysis path. Family services have individual bounded save validation. The inspector names the compatible family.

Focused regression tests reject optical assistance for telephone, radio and packet-router equipment, exercise every declared communications recipe's family, and ensure rivals choose the compatible bench despite unrelated installed capacity. Logs: `/tmp/tt-communications-family-tests.log` and `/tmp/tt-communications-family-final.log`.
