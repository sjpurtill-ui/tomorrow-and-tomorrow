# Whole-catalog field allocation

The 5,000-discovery target counts each stable identity exactly once. Previous draft-only field counts excluded 604 existing identities and could not accurately show the remaining depth. `baseline-field-allocation.json` now gives each of the 556 baseline and 48 pending communications identities one primary editorial field. It preserves their source status; it changes no runtime domains or discovery behavior.

At commit-parent checkpoint `411f654`, 1,437 master drafts plus those 604 identities account for **2,041**, leaving **2,959** to author. This is not a count of implemented player discoveries. The 556 baseline is worktree-tested; pending and draft records are not certified gameplay. None of these figures establishes canonical integration.

## Reconciled allocation

The targets are editorial coverage goals from the approved review, not automatic permissions to create filler, interchangeable variants or duplicate umbrella discoveries. Every remaining identity still needs a distinct mechanism, causal foundations, physical requirements and meaningful consequences. A future reallocation must preserve the overall target and document why it improves coverage.

| Field | Target | Implemented baseline | Pending code | Master drafts | Accounted | Remaining to target |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| D01 Food and agriculture | 280 | 43 | 0 | 60 | 103 | 177 |
| D02 Water and sanitation | 180 | 16 | 0 | 59 | 75 | 105 |
| D03 Ecology and land stewardship | 180 | 7 | 0 | 60 | 67 | 113 |
| D04 Materials and chemical processes | 300 | 67 | 0 | 60 | 127 | 173 |
| D05 Energy | 260 | 19 | 0 | 60 | 79 | 181 |
| D06 Machinery and mechanical production | 240 | 71 | 0 | 60 | 131 | 109 |
| D07 Fibers and domestic technologies | 120 | 16 | 0 | 60 | 76 | 44 |
| D08 Buildings and settlements | 220 | 13 | 0 | 60 | 73 | 147 |
| D09 Overland transport | 180 | 24 | 0 | 60 | 84 | 96 |
| D10 Maritime technologies | 160 | 27 | 0 | 61 | 88 | 72 |
| D11 Flight | 160 | 7 | 0 | 60 | 67 | 93 |
| D12 Mathematics measurement and physical models | 180 | 65 | 0 | 60 | 125 | 55 |
| D13 Records and communications | 240 | 20 | 34 | 60 | 114 | 126 |
| D14 Medicine and care | 280 | 13 | 0 | 60 | 73 | 207 |
| D15 Biology | 200 | 0 | 0 | 61 | 61 | 139 |
| D16 Governance | 240 | 6 | 0 | 60 | 66 | 174 |
| D17 Economy and exchange | 200 | 7 | 0 | 60 | 67 | 133 |
| D18 Learning and organized work | 160 | 9 | 0 | 60 | 69 | 91 |
| D19 Culture | 180 | 9 | 0 | 59 | 68 | 112 |
| D20 Military systems | 280 | 67 | 0 | 61 | 128 | 152 |
| D21 Electronics and computation | 300 | 34 | 14 | 60 | 108 | 192 |
| D22 Earth systems and resources | 160 | 16 | 0 | 60 | 76 | 84 |
| D23 Space | 180 | 0 | 0 | 60 | 60 | 120 |
| D24 Human futures integration | 120 | 0 | 0 | 56 | 56 | 64 |
| **Total** | **5,000** | **556** | **48** | **1,437** | **2,041** | **2,959** |

## Classification decisions

A primary field identifies the main mechanism or operating application; it is not an exclusive boundary. Cross-field dependencies remain intact. Every assignment is explicit and reviewable in the JSON mapping.

- Broad shipbuilding and flight mechanisms belong to maritime or flight even if their existing runtime domain is security. Military-specific doctrine, field care and military logistics remain military systems.
- Electronic components belong to electronics; communication codes, transmission practices and networks belong to records and communications. General physical measurement remains mathematics and measurement.
- Materials processing belongs to materials, fuels and generation to energy, general machine tooling to machinery, and application-specific cart running gear to overland transport.
- Practical fiber manufacture remains fibers; paper production and printing machinery belong to records. Printmaking techniques intended as cultural expression belong to culture.
- Government, public service, trade and learning mechanisms are classified by their practice, not all grouped under the existing institutions runtime label.
- Future mechanisms already span medicine, biology, energy, computation, space and other fields. D24 is the integration field; its 120 target is not the total future content allowance.

These choices are editorial proposals. They do not assert first-invention dates, country ownership, guaranteed future maturity or a preferred political regime. Where an existing identity is broad, later work must narrow or explicitly reconcile it before counting equivalent specialized descendants.

## Next expansion priorities

The largest remaining field gaps are medicine (207), electronics/computation (192), energy (181), food/agriculture (177), governance (174) and materials (173). Military systems still need 152 distinct identities; general-led operations and actual equipment/service capacity remain requirements.

Medicine's next authored section should deepen diagnostic reasoning, clinical physiology, infection prevention, maternal/child care, medicines, rehabilitation and evidence-bounded future treatment. Match against the existing medical, biological, military-care and future-humanity records before adding identities. Counting procedural names is insufficient if the same mechanism is already represented.

The second coverage axis remains incomplete: every identity needs one historical horizon for editorial review, totaling the approved survival, settlement, complex-society, industrial, modern and substantial-future allocations. These horizons are metadata, never research gates. A classification must follow the mechanism and evidence rather than a name-prefix heuristic. Field coverage alone cannot establish exhaustive history or a playable 2,500–3,000-year progression.

## Validation and handoff

The checker now requires all 604 baseline/pending identities exactly once, matching recorded names and source status, and valid fields for all drafts. It requires 24 unique field targets totaling 5,000. It preserves negative remaining values if a field eventually exceeds its allocation instead of silently clipping overages. The combined graph still checks identity uniqueness and AND/OR reachability. It assumes baseline and pending knowledge available for draft reachability; it does not validate their execution.

Exact source totals reconcile to 2,041 accounted and 2,959 remaining. Six deliberately malformed allocations were rejected: omission, duplication, changed source status, unknown field, stale name and changed target total. No Godot runs, simulations, imagery jobs, save changes or player launches were needed for this accounting change.

Delivery is isolated in `/Users/seanpurtill/Documents/Codex/tt-technology-implementation`, `codex/technology-implementation`, based on `411f654`; original worktree base `940d5a2ad848d9f45b8d98825cd5219a3eda83e9`. Owned files are the allocation JSON, this review, coverage report, master README, execution ledger and `tools/technology-review/check_master_catalog.py`. Unfinished communications runtime edits remain excluded. No shared simulation hotspot changes or save compatibility changes. Canonical integration remains unverified.
