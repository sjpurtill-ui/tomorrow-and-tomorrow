# Army figures across city zoom

Army figures are a bounded visual sample of the military's existing numeric
formation records. They are not simulated people and never drive casualties,
movement, manpower, readiness, or equipment accounting.

## Scale and composition

| Soldiers represented | Displayed figures |
| ---: | ---: |
| 100 | 16 |
| 1,000 | 40 |
| 10,000 | 101 |
| 100,000 | 254 |
| 1,000,000 and above | 256 |

Figure count is `min(troops, clamp(round(16 * (troops / 100)^0.4), 1, 256))`;
an empty army has no figures. More strength means more ranks and a wider/deeper
footprint, not larger bodies. Once the cap is reached the label still reports
the real strength. Visual counts are deliberately not a headcount scale.

Levy, line infantry, skirmisher, cavalry, siege engineer, field artillery,
rifle infantry, machine-gun company, and motorized infantry
counts are apportioned using largest remainders. Artillery and archers occupy
rear ranks; line infantry and cavalry are forward. Formations containing support
assets use wider spacing for horses, crews, and equipment; trucks use wider
spacing again. Armored formations and modern artillery do not have models yet.
See `MILITARY_MODEL_ROSTER.md` for the full roster. For legacy records with no
formation breakdown, a levy presentation is used.

## Main-map behavior

Existing strategic counters remain at camera sizes 8 and above. Below 8, up to
four revealed nearby player armies get animated figures, selected army first,
then nearest to the camera target. Each uses the same `0.002` detail scale as
city structures. Positions are in the map's kilometre coordinate system and
each instance is fitted to the terrain surface. Co-located armies get separated
visual blocks; authoritative locations stay unchanged.

Idle/walk follows stationed/moving state; animations pause with game time. Each
formation keeps its real strength label. Zooming back out releases its instances.
At most 1,024 figure instances and 36 mesh batches are active for this layer,
whether the armies contain hundreds or billions of troops. This is a rendering
budget, not a claim of tested frame rate on every graphics device.

Enemy intelligence remains on the existing presentation path. Attack and death
are available in the crowd renderer and demo, but battle event/casualty timing is
not connected to these figures yet.

## Shared animation

`tools/bake_basic_unit_crowds.py` reads the editable Blender source and writes a
base mesh description and position/normal EXRs for each unit. These contain 52
sampled poses across idle, walk, attack, and death. The Godot shader interpolates
between sampled poses, with phase offsets for variation. Per-instance color is
white to preserve vertex material colors; faction color changes the chest tab.

Godot builds and caches one ArrayMesh and two animation textures per unit type.
Each displayed army uses up to nine MultiMeshes with its own animation clock.
There are no per-figure nodes, skeletons, AI agents, or animation players.
After editing animations, run the basic-unit builder, then the crowd bake, then
Godot's import. The original GLBs remain available for individual unit previews.

## Review

Run `tools/army_scale_preview.tscn`: choose Founding forces, Reinforcements,
Industrial forces, or Mixed army; choose 100 through 1B troops; use Overview,
Formation, or Inspect, and try the four clips. Scroll zooms, left-drag orbits,
right-drag pans. This is a side-by-side scale/animation comparison, not a combat
simulation.

`tools/verify_army_figures.gd` verifies monotonic capped budgets, exact composition
allocation, fixed node counts, cached unchanged layouts, white instance tint,
and EXR coordinates against base mesh positions. The warfare runtime probe also
checks close-map integration, city scale, labels, skeleton-free rendering, and
cleanup when zooming out.
