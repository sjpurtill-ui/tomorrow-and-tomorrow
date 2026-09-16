# Catalog chronology ledger

The ledger turns catalog review into bounded classification rather than repeated
prose. `live-catalog-ledger.tsv` is generated from the frozen implemented-baseline,
field-allocation, and historical-horizon records. Editorial columns begin blank or
`unreviewed` and are completed transformation by transformation.

The generated ledger is planning data only. Runtime code must not load it.

## Columns

| Column | Meaning |
| --- | --- |
| `id` | Stable discovery identity. |
| `name` | Current reviewed display name. |
| `source_domain` | Existing runtime research domain. This is not the historical field. |
| `primary_field` | Existing D01–D24 editorial field assignment. |
| `current_horizon` | Existing H01–H06 assignment when one has been explicitly reviewed. Blank means unassigned, not early. |
| `legacy_ordering_day` | Existing non-gating catalog ordering metadata. It never authorizes chronology. |
| `relative_chance` | Existing discoverability weight for later pacing review. |
| `requires_all` | Current common foundations. |
| `requires_any` | Current alternative foundation groups. |
| `learning_route_count` | Current explicit ways of learning the discovery. |
| `learning_route_foundations` | The actual AND/OR knowledge required by each current learning route. |
| `reference_transformation` | T01–T24 placement accepted in this review. |
| `role` | `anchor`, `significant`, `supporting`, `refinement`, or `standard`. |
| `review_status` | `unreviewed`, `keep`, `repair`, `merge_split_review`, `quarantine`, or `remove`. |
| `presentation_tier` | `landmark`, `notice`, `program_report`, or `digest`. |
| `stack_gaps` | Missing indispensable energy, materials, manufacture, measurement, information, people, institution, logistics, or maintenance stack. |
| `chronology_risk` | `none`, `root_density`, `shallow_path`, `cross_field_gap`, `scope_mismatch`, `foreign_bypass`, `duplicate`, or a concise combination. |
| `review_note` | Short explanation only when the classification is not self-evident. |

## Review discipline

1. Review anchors before supporting work.
2. Review T01–T04 before later transformations.
3. Record exceptions rather than writing an essay for every row.
4. A blank historical assignment never defaults to H01.
5. An advanced discovery is not repaired by adding an arbitrary early parent. Repair
   the actual missing stack shared by the affected family.
6. A foreign route is reviewed twice: once for knowledge transfer and once for the
   recipient's ability to reproduce and operate the capability.
7. Draft identities receive the same fields immediately before their implementation
   wave, avoiding a premature manual review of all 2,592 drafts.

## Batch size

Review one transformation or 25–50 connected discoveries at a time. A batch ends
with an accepted exception list and implementation queue. It does not end with a
full test run because ledger review changes no gameplay.
