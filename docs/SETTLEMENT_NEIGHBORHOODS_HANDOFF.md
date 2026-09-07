# Early settlement neighborhoods

Base: canonical Mac 8536c15. Scope: local_terrain, early ground renderer,
shared building placement, founding claims, and early visual regression tests.

Early households now share small courts, with occupancy based on completed roof
coverage and actual asset footprints. Founding claims reserve the communal hearth
first and use tighter three-group placement. Counts remain aggregate and capped;
new world founding changes do not migrate existing plot history. Construction,
materials, research and growth authority remain in SettlementModel.

At early settlement scale the neighborhood renderer replaces parcel-wide ground
polygons, old thick route rendering, and the oversized central prop collection.
It draws feathered footpaths at recorded widths, door connections that avoid
other buildings, worn thresholds, and human-scale communal/service objects at
recorded service parcels. Construction has frames, not old roof placeholders.
Fields and unsupported later forms keep their existing renderer. Cultural public
buildings remain unimplemented gameplay, not implied by this delivery.

Worker validation: 149/149 headless checks, zero errors/failures/orphans across
early visual, organic town, settlement architecture and settlement model suites.
Log: /tmp/neighborhood-final-tests.log. Assembled geometry exported headlessly and
reviewed in Blender: /tmp/neighborhood-review.png (offline geometry review, not a
player screenshot). No player session was changed during tests.

Limits: early neighborhood mode retains the existing 128-plot budget; no-fit
parcels can omit buildings. Door paths are visual connections, not new simulation
routes. Later infrastructure and construction-era culture/politics need further
work. No new save format or population authority. Shared conflicts: local_terrain,
settlement_model and organic_town_visual; integrate by commit, never folder copy.
