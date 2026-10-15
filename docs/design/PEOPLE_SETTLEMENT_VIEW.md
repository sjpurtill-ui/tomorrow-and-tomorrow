# Living People settlement renderer

This private SubViewport presents copied settlement plots and routes. It is a presentation component, not a second settlement or population authority.

## Data and interaction

- `configure(context)` and `update_state(context)` accept settlement ID, terrain, population and allocations; explicit plots/routes/origin support isolated fixtures.
- `focus_role(role)` moves smoothly to an existing relevant parcel. `reset_view()` returns to the inhabited center. Wheel zoom remains reversible; the painterly view limits right-drag orbit to the illustration's shallow three-quarter range.
- `annotation_obstacles()` exposes clipped projected rectangles of visible painted buildings and trees for soft label-avoidance.
- `role_anchors_changed` emits local pixel anchors. `role_anchor_metadata()` includes projected actual parcel polygons and distinguishes a real role parcel from shared work ground, so the overlay can avoid implying a mine or school exists when it does not.
- Building forms, materials, damage and construction stages come from recorded fabric. Population/year changes do not reskin buildings. New recorded parcels can expand the footprint.
- The renderer never calls `remember_layout` on live plots. Scene snapshots are detached; the original record bytes are checked in the fixture.

## Private presentation

The camera frames the inhabited core while outlying parcels remain reachable through role focus and zoom. Transparent modular paintings replace supported recorded building forms, roof families and supplies. Their ground contact is cropped from each atlas cell, including fractional cell sizes. Installed wall material, roof, storeys, damage and construction determine the choice; unsupported fabric keeps its existing geometry. Matching unfinished and damaged timber, earth and stone art retain those materials. Modest timber variation is stable per recorded plot. Chimneys require installed material evidence. A timber construction frame never replaces a hide shelter or unfinished reed lean-to. Existing per-house supply placements remain authoritative; painted replacements use terrain contact rather than the original mesh's base offset.

Seeded vegetation keeps the map's candidate sites and biome decisions, with painted foliage, subtle motion and private whole-tree sightline fading. A terrain-following meadow texture follows actual contours and climate tint. Paths retain recorded routes with smooth, feathered edges and contact wear around inhabited buildings. A water-service plot renders its recorded service object, not an invented pond; rivers use actual terrain courses. Small smoke wisps originate only from recorded hearths. No scene or map material cache is mutated.

Up to 48 illustrated people represent activity on real routes and occupied work parcels. They are not individual population records. The private people material does not change the main map's visibility policy. Unchanged population, allocations and clothing evidence reuse the visual batch. Costume appearance reads known sewing/weaving techniques, adoption and the selected settlement's last issued-clothing report. Early hide/fiber wraps remain when supply evidence is missing; no date threshold outfits the population. Clothing changes reuse the settlement geometry.

Foreground tree crowns fade cohesively around the selected site, retaining their original positions and trunks. Returning to overview restores the crowns.

## Validation and review

The painterly renderer is a new review pass following the user's rejection of the earlier low-poly scene and large overlay panels. Earlier layout acceptance is not graphical acceptance of this pass.

`tests/test_people_settlement_view.gd` covers detached state, no calendar-driven upgrades, parcel truth, geometry reuse, focus projection, bounded people, actual expansion, water-service truth, shared-material isolation, clothing refresh, faithful artwork gates and atlas cell bounds. `tests/people_settlement_view_capture.tscn` captures early and mature recorded fabric, work focus and narrow overview on a private desktop; its Food mode checks whole-tree cutaway and reset without changing tree positions or rebuilding fabric.

The first painterly GPU capture completed successfully. A second private run emitted early/mature images but the safety helper then reported that it could not verify the input desktop; that run is not counted as a pass and no bypass or retry was attempted. Updated ground, roof-family coverage, people depth order and compact overlay composition require a fresh combined private GPU review by the integrator. The headless tests and read-only fixture are run before handoff. These representative states are not asserted as a historical sequence.

The ground/depth follow-up passed a fresh private GPU run (six early/mature/focused/narrow captures) and nine focused tests. The overview frames an actual near residential cluster, with calmer ground texture, worn door/work yards, tighter contact shadows and a subtle edge finish. B accepted these composition changes and the obstacle API. The remaining visual finding is the contrast between painted buildings and unsupported construction/damage/workplace geometry; it remains open for the next bounded art pass.

The matching-fabric follow-up closes that finding for the representative fixtures: all 31 early and 92 mature building instances use appropriate paintings, including the active plank-roof workshop, new timber frame and damaged timber homes. Eleven focused cases pass, including material/floor gates and transparent atlas-cell boundaries. Six private native captures verify read-only records, yard ground contact and removal of the replaced communal construction frame. Timber atlas v2 corrects roof artwork that crossed nominal cell boundaries and appeared as isolated roof fragments. The integrator owns final combined review with the new people artwork and annotation controls; these component captures do not claim whole-screen graphical acceptance.

Final combined acceptance: actual HUD Night/Daylight journeys pass 154/174 checks
and 32 narrow/wide/ultrawide captures. A and B accepted the combined art and
annotations after correcting the mature Crafting sightline: a camera-facing
crown must be tested at its painted position, not a world-up proxy. Root's real
shortage/protection fixture also passes with 15 captures. See
`LIVING_PEOPLE_ART_REVIEW.md` for specific findings and dispositions. Game state
and recorded fabric remain unchanged during the final reader/preview journeys.
