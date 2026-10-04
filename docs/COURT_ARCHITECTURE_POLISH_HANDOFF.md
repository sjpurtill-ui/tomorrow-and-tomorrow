# Court architecture second pass

Base: `b0ee8709b8a731c2c786421f1fc715c12b26aa0d`; worker branch `codex/court-architecture-polish` in the isolated court-chapter-assets worktree. Owns the chapter builder, raw validator, additive manifest and sixteen GLBs. Runtime, cameras, shaders, figure assets, simulation and saves are unchanged.

## Visible changes

The first pass repeated one large-window facade and left many rooms looking like empty rectangular boxes. This batch replaces that facade with explicit, different aperture layouts, deep jambs, smaller shuttered early openings, clerestories, transoms, framed entry openings and an open side-door leaf. Side walls join the rear wall without coplanar top surfaces. Existing actor, seat approach/exit, petitioner, execution and door marks remain identical to the delivered baseline.

Each room gains a purposeful composition: curved portable windbreaks and hide rolls; braced timber and household chests; courtyard portico and tablet store; an axial colored audience recess and entablature; colonnade/frieze with council records; an actual rear vault bay and clerical shelving; clerestory archive wall; braced medieval trusses and hanging; buttressed stone hall; chancery book wall; a secretariat rear anteroom facade; paneled cabinet room; ministerial library/consultation alcove; dispatch shelving and connected industrial beams; acoustic conference zone with ceiling raft; and a contemporary reception soffit, briefing backdrop and suspended linear fixtures.

Indoor open hearths now sit on flush noncombustible stone insets rather than bare timber flooring. Every added record collection and electrical fixture keeps its appropriate writing, bound-records or electrical capability gate. Shutters use `no_glazing`; window glass uses `glazing`. No new technology IDs or simulation authorities are introduced.

Room light/look metadata varies direct sun, diffuse fill, warmth and ambient exposure by composition. Window fills use existing `fx.fill:[x,y,z,energy,range]` and represent daylight, independent of electricity. Later rooms retain the integrated restrained wall/wood finishes; the ministerial room has a muted sage finish, and conference carpets use subdued neutral cloth. No indoor smoke or animal effects are added.

Conference CRTs are confined to the chapter-14 secretary station. Chapter-15 meeting displays top out at 1.05 m above the floor, preserving seated face sightlines. Redundant conference table lamps are removed in favor of gated ceiling fixtures. The earlier typewriter orientation correction is preserved.

## Historical grounding

These remain stylized room families rather than replicas of particular buildings. The design uses the game's nonlinear elapsed-year timeline.

- The Metropolitan Museum's [Middle Kingdom house model](https://www.metmuseum.org/art/collection/search/544249) records a columned portico, enclosed courtyard and barred window. Its [daily-life bulletin](https://resources.metmuseum.org/resources/metpublications/pdf/The_Daily_Life_of_the_Ancient_Egyptians_The_Metropolitan_Museum_of_Art_Bulletin_v_31_no_3_Spring_1973.pdf) describes raised central rooms ventilated by clerestories. These support the ancient courtyard/high-aperture vocabulary, not a claim that every society used an Egyptian plan.
- English Heritage's [Old Soar Manor history](https://www.english-heritage.org.uk/visit/places/old-soar-manor/history/) distinguishes the open-hearth great hall from the private fireplace-equipped solar and documents shutters and window seats. The National Trust's [architecture history](https://www.nationaltrust.org.uk/discover/history/architecture/history-of-architecture) describes the side-entry screens passage and later industrial small-pane cast-iron windows. These informed medieval structure/circulation and the industrial facade.
- The U.S. Department of State's [headquarters history](https://history.state.gov/departmenthistory/buildings/section29) distinguishes reception/waiting circulation, staff offices, conference rooms and delegates' lounges. The modern rooms accordingly separate reception/records functions from a usable meeting table rather than scattering chairs around isolated props.

## Validation and remaining combined checks

Raw asset validator: **16/16 pass**, 90 authored seats; all sixteen complete mark dictionaries compared identical to the base. Total bundle: 140,492 triangles and approximately 13.5 MB; largest room remains below the existing 12,000-triangle limit. Tests cover raw GLB hashes/top-level named meshes, distinct geometry, gate targets, desk contact, typewriter orientation, early aperture dimensions, shutter gates, daylight-fill bounds, indoor hearthstones, record gates, conference sightlines, foreground clearance and conservative seat-exit clearance.

All sixteen rebuilt silhouettes received private headless Blender previews. Those previews show all gated variants with simple colors and do not certify final Godot lighting/materials. Final actual-mesh route tests, real-aspect camera captures, and in-game actor/architecture review belong to the integrator's combined checkpoint. Do not reuse the prior batch's 192-route result as evidence for these new meshes. Generated previews, build logs and Python caches are excluded from source delivery.

Save compatibility is unchanged. No canonical player/editor was launched or interrupted. The prior integrated finish metadata is preserved and extended in its builder function. Integrator changes to the same manifest/builder require deliberate conflict resolution. A worker branch push does not establish delivery to main or the running player.

The first combined import found that decimal coordinates in two chapter-15 pendant names were sanitized by Godot, leaving their electricity gates unbound. The strengthened raw validator also caught two chapter-05 record-shelf targets with the same problem. Both builders now use stable integer indices; rebuilt GLBs 05 and 15 retain identical geometry and marks. All gate groups reject Godot-reserved node-name characters before delivery. The raw sixteen-room validator passes after this repair; actual-mesh route and imported runtime results are recorded separately after those checks complete.
