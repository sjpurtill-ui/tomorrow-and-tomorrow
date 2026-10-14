# Living People settlement renderer

This private SubViewport presents copied settlement plots and routes. It is a presentation component, not a second settlement or population authority.

## Data and interaction

- `configure(context)` and `update_state(context)` accept settlement ID, terrain, population and allocations; explicit plots/routes/origin support isolated fixtures.
- `focus_role(role)` moves smoothly to an existing relevant parcel. `reset_view()` returns to the inhabited center. Wheel zoom and right-drag orbit remain reversible.
- `role_anchors_changed` emits local pixel anchors. `role_anchor_metadata()` distinguishes a real role parcel from shared work ground, so the overlay can avoid implying a mine or school exists when it does not.
- Building forms, materials, damage and construction stages come from recorded fabric. Population/year changes do not reskin buildings. New recorded parcels can expand the footprint.
- The renderer never calls `remember_layout` on live plots. Scene snapshots are detached; the original record bytes are checked in the fixture.

## Private presentation

The camera reads the inhabited core closely while outlying parcels remain reachable through role focus and zoom. Existing building and prop meshes are rendered with independent material instances. Seeded vegetation keeps the map's candidate sites and biome colors; volumetric crowns/trunks suit the lower camera. The bounded foliage budget selects nearby candidates first. A water-service plot renders its recorded service object, not an invented pond; rivers use actual terrain courses.

Up to48 illustrated people represent activity on real routes and occupied work parcels. They are not individual population records. The private people material does not change the main map's visibility policy. Unchanged population/allocations reuse the visual batch.

## Validation and review

`tests/test_people_settlement_view.gd`: five passing cases cover detached state, no calendar-driven upgrades, parcel truth, geometry reuse, focus projection, bounded people, actual expansion, water-service truth and shared-material isolation. `tests/people_settlement_view_capture.tscn` captures early and mature recorded fabric plus Crafting, Construction, Administration and narrow overview on a private desktop. The early/mature fixtures are representative states, not an asserted historical sequence.

The closer Construction view was independently accepted for integration with the spatial overlay. Final graphical acceptance belongs to the combined People journey; this component checkpoint does not claim the entire screen meets the approved illustration.
