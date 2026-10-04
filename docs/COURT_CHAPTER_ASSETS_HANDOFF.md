# Court chapter architecture assets

Worker branch: `codex/court-chapter-assets`, based on `3b620e3296ff851c74d72d8a7265781fc473975f`.
This checkpoint contains only additive assets, their Blender builder, raw validator and this handoff. It does not change runtime selection, path code, the five existing sets, simulation, saves or the canonical player checkout.

## Coverage

Sixteen unique meshes cover elapsed years 0–3000 in 200-year steps. These are game years, not AD dates. The medieval chapters occupy years 1400, 1600 and 1800, following the game's nonlinear historical curve.

| Key | Elapsed | Room |
|---|---:|---|
| chapter_00 | 0 | Open hearth gathering, log seats and hide windbreaks |
| chapter_01 | 200 | Enclosed timber community hall |
| chapter_02 | 400 | Plastered courtyard record hall |
| chapter_03 | 600 | Axial masonry audience hall |
| chapter_04 | 800 | Colonnaded council room |
| chapter_05 | 1000 | Vaulted administrative room |
| chapter_06 | 1200 | Partitioned late-antique record chamber |
| chapter_07 | 1400 | Timber great hall with king-post trusses |
| chapter_08 | 1600 | Stone great hall, pointed arches and solar doorway |
| chapter_09 | 1800 | Chancery/guild chamber with trestle desks and record chests |
| chapter_10 | 2000 | Secretariat with anteroom screens |
| chapter_11 | 2200 | Cabinet room with oval council table and chimney wall |
| chapter_12 | 2400 | Ministerial consultation office |
| chapter_13 | 2600 | Industrial department with paired workstations |
| chapter_14 | 2800 | Executive conference room with broad windows |
| chapter_15 | 3000 | Contemporary conference and reception zones |

Chapters 11/14/15 group six inward-facing chairs around a 4.6 m meeting table. Chapters 9/10/12/13 provide two working chairs close to the desks; remaining seats serve waiting/consultation roles. Furniture and architecture remain individually named top-level meshes for runtime obstacle extraction. Every chapter changes geometry, not just colors.

## Integration contract

- Additive manifest: `assets/court_sets/court_chapters.json`; 16 corresponding `court_chapter_XX.glb` files.
- Retains legacy `gates` era tags. `technology_gates` uses agreed capability names, and `institution_gates` separates assembly/throne decor. Window glass, paper, bound books and equipment are individually gated. Chapter 15 intentionally shows no CRT when only older computer technology is known: the room retains its paper/table presentation until flat screens are available.
- `indoor`, `has_hearth`, `floor` (`earth`/`wood`/`stone`), and `rustic_trophies` are explicit. Rustic trophies are enabled only before chapter 9.
- Only chapters 0/1/7/8 have an actual hearth, `fire` mark and fire FX. Indoor hearths specify `smoke:false`. No indoor animal marks. No-hearth rooms have `focus` and open foreground `execution` marks instead of a fabricated fire anchor.
- Chairs: `officials_0..5`, `sit:true`, `seat:0.47`, `external_seat:true`, `seat_mesh`, absolute `seat_exit:[x,0,z]`, and optional lateral `seat_approach:[x,0,z]`. `face` is a three-component target point; runtime must support this alongside legacy two-component targets.
- Close working chairs use a short lateral access leg; modern meeting chairs are armless to keep that leg physically clear. Final exits have at least 0.65 m conservative furniture clearance. The modern reception console preserves a 1.445 m physical aisle beside the end chair.
- Material slots additionally require the integrator's `WINDOW_GLASS` and `PAPER` palettes. Vertex colors remain the kit's AO/wear/variation data, not display RGB.

## Validation and limits

`python tools/blender/validate_court_chapters.py`: 16/16 pass. Checks raw GLB hashes, distinct position/index geometry, individual root meshes, triangle budgets, gate targets/capabilities, desk-object contact, hearth/environment contracts, authored seat exits and foreground marks. All rooms are below 10,000 triangles; the complete bundle is approximately 11.2 MB.

The chair integration worker tested these actual GLBs directly with the completed runtime route implementation: **192/192 pass**, covering 96 official-to-door departures and all 96 reverse arrivals, with zero script/engine errors. This includes the six standing chapter-0 roles and all 90 authored chairs. Tests use the explicit isolated project and do not launch the player.

All 16 rooms received private Blender geometry previews; these use simple slot colors and display all capability/institution alternatives simultaneously. They are not game screenshots. Final Godot materials, actor seating and combined policy/GPU review are the integrator's remaining verification responsibility. These are stylized, reusable room families, not literal reconstructions of particular historical buildings or every culture. Optional equipment is still purely a visual prop; no new office interaction simulation is claimed.

Build with Blender 5.2 using `--background --factory-startup --python tools/blender/court_chapter_sets.py`; optional `-- --chapters 9,15` rebuilds a subset while preserving the other manifest entries. Generated previews, logs, caches and imports are excluded from delivery. Save format compatibility is unchanged. All source paths are new, so no shared-file merge conflicts are expected. A worker-branch push is not delivery to main or the player build.
