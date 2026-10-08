# Foreign city report view

Foreign city dossiers replace the line-drawn skyline with a large, textured 3D
view. The view uses the same early/town building meshes as the map, the existing
foreign settlement layout and identity styles, public terrain heights, and
terrain-following paths and yards. Reported figures, comparisons with home,
source, freshness, ownership and actions remain below the image. Show on map
uses the existing reported-city navigation action.

## Evidence and rendering

The player's own report camera can show live owned ground. A foreign report is
dated evidence: its private world contains only the existing representative
foreign-town geometry, sized by the original observed population bounds. Aging
uncertainty does not enlarge the city. It does not read a hidden civilization's
current buildings, population, resources, defense works or discoveries. Exact
foreign plot geometry and architecture inventories are not recorded in current
reports; this remains a representative view, not an invented historical image.
Reports without population evidence retain an explicit unknown-population note.
Reported fortifications and damage remain in the account and figures.

The view has at most 128 representative buildings, a 33-by-33 terrain grid,
bounded paths/yards and a viewport capped at 1440 by 960 pixels. It renders on
demand, retains its scene through age/source/home-comparison updates and stops
when hidden. Resizing reframes it; changed observed geometry rebuilds it. There
are no walking people, extra simulated citizens or continuous scene updates.
Opening a report does not change the main camera, settlement ground records,
population ledgers or the player's saved portrait album.

`foreign_settlement_visual.build` has an optional ground-publication flag,
defaulting to its previous map behavior. The report supplies false and uses the
resulting local plan for its own ground. The exact held-town report and existing
Sketch subclass remain available to their current callers. No save migration.

## Validation

Focused tests cover observed-bound stability, hidden-state independence, private
world side effects, bounded geometry/no people, hidden/on-demand lifecycle,
actual foreign dock integration and in-place daily text updates. Existing city
intelligence, held-town and own-town checks protect the shared report paths.

The isolated GPU fixture uses the actual ForeignCity provider and DockPanel,
with Felik reported at 7,600 people, home at 18,000 and evidence 40 days old. It
checks 1907x658, 1280x900 and narrow 640x800 layouts, saves the real UI plus native
portrait, and verifies that an unseen increase to 76,000 inhabitants cannot
change the report geometry. Public topography is a bounded fixture, not a
campaign capture. Logs and captures stay in ignored
`artifacts/foreign-city-report-view/`.

The first GPU review caught undrawn wide viewports and a culled terrain surface;
those captures were rejected and retained separately for diagnosis. Final test
and capture results are recorded at delivery below.
