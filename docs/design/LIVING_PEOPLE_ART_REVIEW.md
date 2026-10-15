# Living People: illustrated scene acceptance

Status: new visual pass in progress; the previous functional checkpoint is not
visual acceptance. The user rejected the rendered scene and its large panels
after seeing the approved illustration. This review applies to the actual
Home → People screen and its assignment states, not a separate concept page.

## Reference and observed problem

Art-direction reference:
`C:/Users/sjpur/.codex/generated_images/01a13b4e-53d9-7361-8d69-93b20c9c91ec/exec-a522c89b-b2ad-41f3-91ec-12967044f402.png`.

Rejected baseline:
`artifacts/popup-audit/living-people/learning-draft-wide.png` in the integration
worktree, reviewed against integrated baseline `ee661650`.

The illustration leads with a coherent inhabited place: layered huts and yards,
connected paths, vegetation, working people, materials and soft natural light.
Short readings explain the nearby buildings and activities. The current image
leads with two large dark rectangles over a relatively sparse model. A manual
estimate from the 1600 × 1000 capture puts those rectangles at about 29% of the
scene area; the scene starts about 24% down the complete window. These are
approximate composition measurements, not automated test results.

The existing controls already provide useful worker transfers, food depletion,
research effort and construction estimates. Preserve those meanings while
changing their presentation. Smaller versions of the same two panels, a static
painting beneath them, or additional decorative bars do not satisfy this pass.

## Visual review gates

The following are review guardrails. Passing a percentage cannot substitute for
an independent comparison with the reference at normal display size.

| Gate | Required result | Evidence |
| --- | --- | --- |
| Scene leads | At least 80% of the overview scene and 75% of a focused scene remain unobscured by UI backing, text and controls. The first visual read is the inhabited place. | Actual overview and draft captures at 1024, 1600 and 2869 widths; count translucent panels as coverage. |
| Place remains visible | The selected worksite and enough adjoining paths/buildings to identify it remain visible. UI must not cover the selected anchor or its immediate context. | Focus every work area; inspect tree/foreground occlusion and narrow layout. |
| Compact action | One local assignment cluster contains role, current/proposed workers, existing step controls and Apply/Cancel. Normal assignment needs no preliminary Inspect action. Avoid empty backing or repeated headings. | Normal and changed drafts, pointer and keyboard operation. |
| Consequence before detail | One primary consequence is readable beside the relevant place without opening another page. Additional exact evidence is available without competing equally for attention. | Food, learning and active home-building drafts. |
| Integrated information | A small annotation has a physical association with its worksite, stock, route or building. Repeated cards and metric grids must not become the page structure. | Wide and narrow composition reviewed beside the illustration. |
| Rich, coherent environment | Materials, silhouettes, paths, planted/uncultivated ground, vegetation and human activity form one consistent scene. Avoid broad uniform carpet, disconnected props and repetitive geometric crowns. | Early and mature settlements at normal scene scale. |
| Readability | Text remains readable against changing scenery; local backing/shadow is only as large as necessary. Controls retain at least 40px targets and visible focus. Risk is stated in words as well as colour. | Both palettes, bright/dark scenery and narrow capture. |
| Real change | Recorded footprint, completed/building/damaged structures and supported activity alter the rendered settlement. Focus moves to an actual corresponding place. | Before/after isolated state fixtures using real records. |

At narrow widths, prioritize the selected place and its decision. Two stacked
dashboards are not an acceptable fallback. A short line near the relevant place
can replace a full-width graph when the graph adds no useful comparison.

## Meaning and era are part of the design

- The illustration supplies composition, material treatment and light. It does
  not authorize its watermill, masonry tower, river, fields, bridges, numbers or
  clothing in a state that has not acquired them.
- Use recorded plots, fabric, work grounds and routes. A role that shares a yard
  must not acquire a fictitious dedicated workshop or research building merely
  to provide a convenient anchor.
- A small early settlement should feel close and inhabited through framing,
  material variation, ground detail and bounded visual activity. Do not invent
  extra functional buildings or population to fill the canvas.
- Visual people remain representatives. Keep aggregate counts authoritative.
  Local scene imagery must not imply that realm-wide assignment counts belong
  entirely to the displayed town; retain the concise scope explanation.
- Earliest clothing stays hide/fibre wraps with exposed limbs and natural tones.
  Woven or sewn variants follow actual known technology, adoption and recorded
  clothing supply. Calendar progress alone does not change the wardrobe.
- Background texture and incidental natural clutter may enrich the view without
  implying a new resource, building, technology or mechanical benefit.

Existing `assets/ui/overview/village-v2.png` and `town-v2.png` demonstrate warm
material detail and close habitation. They contain later clothing, buildings
and infrastructure, so they are style references, not valid whole backdrops for
the earliest settlement. Their single fixed perspective also cannot replace a
scene that develops with the recorded town.

## Assignment semantics that must survive the visual change

| Situation | Required visible meaning |
| --- | --- |
| No draft | Current workers and current condition; do not suggest a proposed change or offer a needless takeover. |
| Changed allocation | Requested workers/transfers and the relevant likely consequence. Preserve headcount conservation and the original donor rule. |
| Food protection | Distinguish requested allocation from effective allocation after the existing food safeguard. Explain a consequential redirection of workers. |
| Current shortage | Clearly state that food is insufficient now. Show actual production/need or intake evidence; no invented death count. |
| Future depletion | State when stores are forecast to run out only when the existing forecast supports it. Label the horizon and assumptions. |
| Stores falling despite enough production | Include spoilage and the actual net store change; production minus demand alone is not the complete balance. |
| Research | Describe effort/teams at current supplies, not guaranteed discoveries. |
| Construction | Show active batch and estimated pace only while building; a larger requested crew is not a promise of faster building after food protection. |
| Water | Show an estimate only when measured inputs exist on the compared sides. Unknown is not zero or a fabricated full bar. |
| Extraction/crafting | Use actual available evidence and effective crew changes. Do not infer exact yields from workers when the preview supplies no such forecast. |
| Delegated work | Explicit takeover wording before applying the original manual commands. |
| Stale draft | Recalculate/replay intentions and visibly require a fresh Apply. No silent commit of revised estimates. |
| Cancel, zero-net draft or navigation | No live allocation changes, no needless takeover, and no automatic pause/resume. |

Graphs must encode actual values with a clear unit, baseline and horizon. Use
food entering/leaving storage or a measured trajectory when it helps the
decision; an arbitrary decorative bar or fake animated flow is misleading.
Risk and food protection take priority over secondary annotation when space is
tight. Detailed calculations can remain in a deliberate disclosure or tooltip,
but a player must see a serious consequence before applying.

## Evidence required for acceptance

1. Review the actual combined HUD at 1024 × 768, 1600 × 1000 and the existing
   2869-wide fixture, including both palettes and native logical-size output.
2. Capture an early overview, a mature overview, a normal unchanged focus, a
   changed learning draft, active construction, and all nine work-area routes.
3. Capture the deterministic real shortage plus safeguard fixture. Its existing
   representative-day output, requested/effective workers and stored food must
   drive the warning; do not fabricate a warning for an attractive screenshot.
4. Exercise no-op, cancelled, delegated, stale and valid Apply paths. Confirm
   preview immutability, original callbacks, conservation and retained access
   to named people, care, records and other existing People actions.
5. Inspect scene/annotation bounds, overlap, foreground occlusion and focus after
   repeated 1024 → 1600 → 1024 resizing and live value refresh.
6. Compare first pass, revised pass and reference side by side. Record concrete
   findings and the independent reviewer's disposition. A clean runtime or a
   collection of passing tests establishes behaviour, not visual acceptance.

Existing coverage to retain includes `test_civilization_people_screen.gd`,
`test_people_work_commit.gd`, `test_people_work_navigation.gd`,
`test_workforce_preview.gd`, `test_people_settlement_view.gd`,
`test_people_settlement_costumes.gd` and `living_people_journey_probe.gd`.
New tests should cover a missing meaningful invariant in the new composition,
not duplicate these tests or assert an arbitrary implementation structure.

## Review record

- 2026-10-14: A inspected the approved illustration and rejected actual Learning
  draft, sent the scene/controls owners the gates above, and inspected the two
  existing overview paintings for reusable art direction. No new-render
  acceptance has been granted. Forecast, simulation and renderer sources were
  not changed by this review.
- Atlas review: the three new `assets/ui/people/settlement-*-v1.png` sheets have
  coherent warm material detail and distinct early silhouettes. Early cells
  9/10/11 (zero based) depict a masonry-footed timber frame, a damaged plaster
  house and a stone ruin; they must not replace construction/damage/ruin of
  hide or reed shelters. Details cell 7 combines baskets and pottery, so it
  cannot appear from basket knowledge alone. Cell 11 depicts grain, not any
  food-gathering ground. Mature chimneys and tiles require the corresponding
  recorded installed fabric. The renderer owner corrected these mappings.
- First painterly scene: early material detail and softer paths improve the
  scene, but broad empty ground and widely spaced repeated shelters still fall
  short of the reference. Closer inhabited-core composition and subtle actual
  door/yard contact treatment are requested. Mature buildings correctly use
  fallback geometry where the atlas roof type does not match; that truthful
  fallback still needs matching art before visual acceptance.
- Controls revision: the large panel backings are gone. Requested transfers,
  the actual food cost and starvation warning now appear beside Apply. Housing
  and food graphics explicitly label current/draft and daily need. Unchanged
  focus hides needless disabled Apply/Cancel controls. The real shortage
  fixture distinguishes requested 13 food workers from 48 after protection,
  with production 27.5 against need 89 and no stores. This is semantic/layout
  direction acceptance; combined scene composition remains under review.
- Native keyboard regression exposed focus loss when the focused Assign marker
  was hidden. The controls owner added focus transfer into the assignment and
  restoration to the originating marker on Overview. The independent
  `test_people_work_keyboard.gd` now dispatches Enter and Tab through the actual
  controls, confirms hidden markers are excluded, edits the draft, applies once
  and returns focus to the original marker. Validated against that corrected UI
  on a private GPU desktop: process 7812 exited 0, one case with no errors,
  failures or orphans (B report 52). This test depends on that UI focus fix.
