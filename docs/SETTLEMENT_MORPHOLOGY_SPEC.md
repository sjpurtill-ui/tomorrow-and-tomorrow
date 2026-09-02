# Settlement Morphology and 200-Year Building Progression

Status: implementation specification  
Audience: Codex and future maintainers  
Project: Tomorrow and Tomorrow (Godot 4.7)  
Map scale: 1 world unit = 1 kilometre

## 1. Product intent

Settlements must read as real inhabited landscapes from a Google Earth-like camera. The simulation should not place a growing collection of individually authored miniature buildings. It should preserve the history of land parcels and render that history as irregular plots, compounds, blocks, fields, yards, paths, vacant ground, and ruins.

The authoritative simulation unit is a persistent **plot**. A plot can grow, subdivide, merge, change use, become overcrowded, lose health, be damaged, become vacant, or survive as a ruin. At normal strategic camera heights, the polygon, its surface treatment, and its approximate roof coverage imply detail without exposing repetitive assets.

Settlement labels are descriptions of function. Crossing a population number must never directly promote a village to a town or a town to a city.

## 2. Design principles

1. **Land remembers.** Plot boundaries, old paths, abandoned yards, and absorbed hamlets persist after their original use ends.
2. **Function precedes title.** A town is a place used as a town: it serves outsiders, contains specialists, and coordinates exchange.
3. **Distance is travel cost.** Walking time, slope, water crossings, roads, boats, and danger matter more than circular radius.
4. **Buildings emerge from households and institutions.** Housing demand creates compounds; exchange creates stalls and stores; authority creates civic space.
5. **Mixed use is normal.** A household plot may combine sleeping, craft, animals, storage, and exchange. Pure residential and pure commercial zoning should be late and conditional.
6. **Progression is an envelope, not a script.** Year bands define plausible available forms. Resources, discoveries, institutions, climate, shocks, and choices determine what actually appears.
7. **Decay is visible.** Population loss does not make polygons vanish. Vacant plots, gardens, salvage, burned shells, and ruins create legible history.
8. **Render aggregates.** At high altitude, batch plots by visual class. Do not create one node or draw call per building.
9. **Culture is spatial grammar, not an asset list.** Civilization values alter alignment, courts, permeability, enclosure, monumentality, and terrain response. They do not select a literal building for every household.

## 3. Human distance model

All spatial decisions use travel-time cost derived from these baseline distances.

| Relationship | Baseline distance | Simulation meaning |
|---|---:|---|
| Adjacent households | 10–40 m | Shared yard, conversation, immediate mutual aid |
| Daily communal errand | 100–400 m | Well, hearth, store, workshop, meeting place |
| One walkable settlement | 0.5–1.5 km | One socially continuous place without fast transport |
| Daily field commute | 1–3 km | Viable but consumes meaningful labour |
| Outer resource territory | 3–8 km | Grazing, firewood, clay, hunting, charcoal |
| Regular neighbouring settlement | 5–15 km | Frequent contact or half-day journey |
| Periodic market catchment | 15–30 km | Market-day round trip under favourable terrain |
| Regional catchment | 30–80 km | Requires roads, lodging, pack animals, or water transport |

Use a travel-cost multiplier rather than Euclidean distance alone:

```text
effective_hours = distance_km / base_speed_km_hour
                * slope_cost
                * surface_cost
                * crossing_cost
                * danger_cost
                / transport_bonus
```

Initial walking speed should be about 4 km/hour on easy ground. A routine round trip should generally fit within 8–10 hours. River transport may make a settlement 30 km away functionally closer than one 8 km away across rough terrain.

## 4. Simulation architecture

```text
Citizen registry / households         resources / logistics / discoveries
                 \                         /
                  settlement pressures
                          |
                  SettlementModel
            +-------------+--------------+
            |                            |
       persistent plots             morphology metrics
            |                            |
      batched plot meshes         functional class + UI
            |
    altitude-dependent visual detail
                 ^
       six-value architecture profile
```

`SettlementModel` owns morphology rules. `GameState` owns serializable campaign state. `local_terrain.gd` only converts model output into meshes and UI. The renderer must not invent, move, or delete plots based on the current population.

### Update frequency

- Daily systems continue to process food, health, population, resources, and construction.
- Settlement pressures may be sampled daily but accumulated.
- Morphology updates once every 30 simulated days.
- Classification updates every 30 days and immediately after major shocks.
- Expensive district and catchment summaries update once per simulated year.
- Rendering rebuilds only when a quantized visible morphology signature, the LOD band, or a quantized civilization architecture band changes. Tiny prosperity and condition drift remains authoritative but does not churn the mesh until it crosses a visible tone bucket.

This keeps a 200-year simulation tractable and prevents the visible settlement from flickering every time population changes.

### Civilization-level built expression

`SocietalValuesModel` derives exactly six bounded visual values—axiality, monumentality, civic space, permeability, defensive depth, and terrain conformity. `local_terrain.gd` consumes them while constructing the existing plot batches:

- axiality aligns roof masses and main approaches toward a persistent civic axis;
- terrain conformity bends the same masses along local contours;
- civic space preserves irregular shared courts inside communal, market, sacred, and civic plots;
- monumentality changes the mass and vertical emphasis of public fabric;
- permeability changes lane prominence and openings in compound edges;
- defensive depth produces tighter perimeter compounds and stronger enclosure without claiming that an unfortified settlement has walls.

The renderer stores no cultural building instances. A billion-person civilization still adds six floats, and a visible settlement still commits a bounded set of combined surfaces. Slow value drift is quantized into twenty visual bands per axis so it can change the landscape over generations without forcing daily mesh rebuilds.

### Bounded urban stage renderer

The implemented strategic renderer expresses founding camp, hamlet, village, town,
city, metropolis, and megalopolis as a nested physical grammar rather than seven
icons or seven authored models.

- Population changes geographic extent through a stage-specific aggregate density;
  it never creates one render item per resident.
- Existing nuclei remain fixed as later stages add new cores and satellite towns.
  Classification can add complexity but cannot teleport inherited centres.
- District cover grows around those centres. Transport connects inhabited places;
  it does not generate a radial star or imply an unexplained orbital belt.
- Broad developed corridors use feathered, world-space fabric. Major transport
  lines remain thinner and appear only where routes or infrastructure support them.
- Circumferential transport requires both infrastructure capability and an actually
  engineered route surface. Capability alone never paints a ring.
- Preserved open space is expressed as irregular pockets and breaks in the urban
  fabric, not rectangular green bars.
- Aggregate construction tone is weighted from the material families of real plot
  area. Organic, earth, and stone building histories therefore remain visible at
  regional scale without simulating every roof.
- Civic and productive anchors come from real active land uses. Industrial belts
  require production capability and render as bounded irregular districts.
- Water channels and cliff-scale gradients clip every aggregate patch and ribbon.
  World cities follow buildable valleys and terraces instead of draping across
  rivers, oceans, or peaks.
- The aggregate aerial mesh crossfades before plot-level inspection. Authoritative
  roofs, yards, scars, paths, and damage become the close-view source of truth.

Urban cover, metropolitan mobility, preserved open space, and skyline/defense
massing are the only four late-stage batches. The billion-person unengineered probe
must remain below 5,000 vertices; the fully engineered probe must remain below
9,000. The shader supplies stable world-space block, street, canopy, and material
grain, so visual richness does not add objects or draw calls.

`tools/settlement_stage_visual_audit.tscn` is the visual-regression harness. It can
render any stage, population, material family, and founding focus without starting
the full simulation. Audit city, metropolis, and megalopolis at strategic scale and
compare at least organic/provision, earth/industry, and stone/defense variants before
accepting morphology changes.

### Planetary marker and border budget

- Only settlement boundaries intersecting the current orthographic view are tessellated.
- Relief sampling becomes coarser by zoom band; the authoritative 32-point border never changes.
- Camera panning crosses large view buckets before a border batch rebuild is permitted.
- All visible secondary-settlement symbols use one `MultiMeshInstance3D` draw.
- Every visible secondary settlement also receives physical urban cover in one shared surface. Geographic radius follows aggregate population and stage density, while topology is capped at 512 total patches for the entire network.
- Larger places receive additional persistent lobes only after every visible place receives a core. This keeps a megalopolis polycentric without erasing small settlements under the same camera.
- Only recorded access axes may add a secondary-settlement corridor, and the complete view is capped at 128 such corridors.
- Labels are population-prioritized and thin from 24 to 16 to 8 as the camera reaches continental scale.
- Beyond the territorial display LOD, settlements remain simulated but generate no border vertices.
- Close inspection retains only plots and routes intersecting the camera view plus a safety margin.
- Intermediate zoom keeps every plot's ground/land-use signal but caps roof, yard, field-row, and repair detail at 768, 512, or 320 stable plot samples.
- Sampled roofs expand into a few aggregate masses so coverage survives without pretending that every household has been rendered.

The number of simulated people therefore has no renderer cost, and the number of owned settlements affects only the visible/candidate scan rather than scene-node or draw-call count.

## 5. Persistent data model

Add the following campaign state to `scripts/game_state.gd`:

```gdscript
var settlement_founded_day := -1
var settlement_plots: Array[Dictionary] = []
var settlement_nuclei: Array[Dictionary] = []
var settlement_routes: Array[Dictionary] = []
var settlement_morphology: Dictionary = {}
var next_settlement_plot_id := 1
var next_settlement_nucleus_id := 1
var morphology_revision := 0
var last_morphology_day := -1
```

### Plot schema

Coordinates are local offsets in kilometres from `GameState.settlement_founded_at`. Keeping them local preserves precision and makes settlement relocation or map streaming manageable.

```gdscript
{
    "id": 17,
    "seed": 12844821,
    "nucleus_id": 1,
    "parent_plot_id": -1,
    "lineage_ids": [],
    "polygon": PackedVector2Array([...]),
    "centroid": Vector2(0.042, -0.018),
    "area_ha": 0.16,
    "frontage_route_id": 3,

    "land_use": "residential_compound",
    "secondary_use": "craft",
    "form": "light_shelter_cluster",
    "material_family": "organic",
    "material_mix": {"Timber": 0.42, "Fiber Plants": 0.33, "Clay": 0.08},
    "construction_recipe": "light_timber_and_fiber",
    "supply_provenance": {"Timber": "timber_4", "Fiber Plants": "local_stockpile"},
    "replacement_debt": {"Timber": 0.0, "Fiber Plants": 0.6},
    "roof_coverage": 0.24,
    "storeys": 1,

    "resident_capacity": 8,
    "resident_count": 6,
    "worker_capacity": 2,
    "worker_count": 1,
    "storage_capacity": 3.0,

    "condition": 0.81,
    "maintenance_debt": 0.08,
    "service_access": 0.67,
    "hazard_exposure": 0.12,
    "prosperity": 0.41,
    "status": "active",
    "pre_damage_use": "",
    "damage": {
        "structural": 0.0,
        "fire": 0.0,
        "contamination": 0.0,
        "looting": 0.0,
        "neglect": 0.04
    },
    "habitability": 0.86,
    "repair_state": "maintained",
    "reoccupation_state": "occupied",
    "displaced_households": 0,
    "returning_households": 0,
    "claim_pressure": 0.0,

    "created_day": 19,
    "converted_day": -1,
    "damaged_day": -1,
    "abandoned_day": -1,
    "last_update_day": 30
}
```

Required `status` values:

- `active`
- `under_construction`
- `stressed`
- `damaged`
- `vacant`
- `ruin`
- `reclaimed`

Required `repair_state` values:

- `maintained`
- `emergency_stabilization`
- `awaiting_assessment`
- `awaiting_materials`
- `repairing`
- `rebuilding`
- `salvaging`
- `unrepairable`

Required `reoccupation_state` values:

- `occupied`
- `evacuating`
- `displaced`
- `unsafe_return`
- `temporary_use`
- `returning`
- `partially_reoccupied`
- `reoccupied`
- `contested_claim`
- `permanently_abandoned`

Required `land_use` values for the first implementation:

- `residential_compound`
- `mixed_household`
- `communal`
- `civic`
- `sacred`
- `market`
- `workshop`
- `dirty_industry`
- `storage`
- `hospitality`
- `defense`
- `water`
- `waste`
- `transport`
- `field`
- `pasture`
- `vacant`
- `ruin`

Do not encode individual cultural building names as land uses. Culture-specific names and visuals should map onto these functional categories later.

### Nucleus schema

A nucleus is a centre of local gravity: the founding hearth, a market, harbour, crossing, citadel, shrine, industrial site, or satellite hamlet.

```gdscript
{
    "id": 1,
    "kind": "founding_hearth",
    "position": Vector2.ZERO,
    "pull": 1.0,
    "active": true,
    "created_day": 0,
    "absorbed_day": -1
}
```

Multiple nuclei are required. The settlement must not remain a circular gradient around its first hearth for 200 years.

### Morphology summary schema

```gdscript
{
    "classification": "village",
    "classification_confidence": 0.76,
    "resident_population": 684,
    "service_population": 1130,
    "built_area_ha": 18.4,
    "occupied_area_ha": 14.1,
    "vacancy_ratio": 0.08,
    "ruin_ratio": 0.03,
    "mean_condition": 0.73,
    "density_people_ha": 48.5,
    "permanence": 0.68,
    "specialization": 0.31,
    "exchange": 0.27,
    "institutions": 0.24,
    "connectivity": 0.35,
    "infrastructure": 0.29,
    "diversity": 0.33,
    "food_import_share": 0.06,
    "active_nuclei": 2,
    "district_count": 1,
    "limiting_factors": ["market remains periodic", "no regional transport"]
}
```

## 6. Plot generation and spatial growth

### 6.1 Founding layout

When `Hearth Circle` completes:

1. Record `settlement_founded_day`.
2. Create a founding-hearth nucleus at local `(0, 0)`.
3. Create 18–30 initial plots for 120 people:
   - 14–22 residential or mixed household compounds
   - 1 communal plot
   - 1 storage plot
   - 1 open workshop plot
   - 1 water-access plot if a water source is reachable
   - 1 waste plot placed away from water and down-gradient
4. Create short desire-path segments between household compounds, water, storage, and the hearth.
5. Keep the initial occupied footprint approximately 100–220 m across, modified by terrain and household dispersion.

These are spatial aggregates, not one household or dwelling each. Assign numeric resident and household-equivalent counts to residential plots; never store human IDs or household membership records in settlement geometry.

### 6.2 Polygon construction

Phase 1 may use irregular convex polygons generated around a centre:

1. Choose 5–9 angular samples.
2. Perturb radius by the plot seed.
3. Bias one side toward its frontage route.
4. Clip or reject intersections with water, excessive slope, and existing plots.
5. Maintain a 1.5–4 m gap or route corridor between unrelated plots.

Phase 2 should replace rejection sampling with clipped Voronoi parcels or a planar subdivision when settlement sizes make overlap checking expensive.

Never reseed existing geometry using current population. A plot's polygon changes only through an explicit split, merge, encroachment, erosion, damage, or infrastructure event.

### 6.3 Growth-front selection

New plots originate from one of four processes:

- **Infill:** vacant or underused land close to services becomes occupied.
- **Edge accretion:** a new plot attaches to the reachable settlement perimeter.
- **Ribbon growth:** plots prefer frontage on a route, river landing, or market approach.
- **Satellite founding:** a separate nucleus appears near fields, a deposit, crossing, port, shrine, defensive position, or factional community.

Score candidate sites using:

```text
site_score = access_to_route
           + access_to_water
           + preferred_nucleus_pull
           + compatible_neighbour_bonus
           + available_land
           - slope
           - flood_or_fire_risk
           - travel_cost_to_daily_needs
           - incompatible_neighbour_penalty
           - overlap_penalty
```

Land-use preferences:

| Use | Preferred location |
|---|---|
| Residential / mixed household | Walkable water and communal access; away from severe nuisance |
| Market / hospitality | Route intersection, landing, gate, bridge, or civic frontage |
| Storage | Dry ground with route access; near production or market but guarded from fire |
| Workshop | Household frontage or work-yard cluster |
| Dirty industry | Edge, downwind/downstream where applicable, near water/fuel/material route |
| Civic / sacred | Central, prominent, inherited sacred site, or new political nucleus |
| Defense | Approach, high ground, crossing, perimeter, or protected store |
| Field / pasture | Outside built core within practical daily travel cost |

### 6.4 Demand, construction, and conversion

Monthly plot demand is derived from actual pressures:

```text
housing_pressure = residents / usable_resident_capacity
workshop_pressure = crafting_labor * material_flow * specialization
storage_pressure = throughput / usable_storage_capacity
exchange_pressure = surplus * logistics * specialization * service_population
civic_pressure = population * institutional_load / state_capacity
hospitality_pressure = external_visits * average_trip_duration
```

Plot creation consumes accumulated construction work and appropriate material capacity. A pressure creates a candidate project; it does not instantly create a completed plot.

Prefer, in order:

1. Reoccupy a healthy vacant plot.
2. Convert a compatible underused plot.
3. Subdivide an oversized plot.
4. Infill reachable vacant ground.
5. Add an edge plot.
6. Found a satellite when daily travel or land conflict makes the existing core unattractive.

### 6.5 Split, merge, and shrink

- Split when a healthy plot is over capacity, has enough frontage, and construction capacity exists.
- Merge when adjoining plots share ownership/use pressure and larger scale improves storage, civic, market, or industrial function.
- Do not geometrically shrink plots merely because population falls.
- Depopulation first reduces occupancy and roof coverage.
- Long vacancy may convert the plot to garden, pasture, salvage yard, or ruin.
- Reclamation by vegetation changes rendering but preserves the boundary in lineage data.
- Major river migration, erosion, or planned infrastructure may physically clip a polygon through an explicit event.

### 6.6 Resources are hard gates

Construction form, scale, condition, roof coverage, repair, and visible material must be consequences of resources that have actually been recognized, made accessible, extracted, delivered, and reserved. A discovery establishes knowledge; it does not create matter.

The settlement model must query:

- `GameState.resource_stockpiles`
- `GameState.material_metrics`
- `GameState.resource_deposits`
- `ResourceSystem.visible_deposits()`
- deposit accessibility, remaining amount, delivery history, route, distance, and bottleneck
- relevant `DiscoverySystem` practices and adoption
- extraction, logistics, crafting, and construction labour

Every construction or major repair project has a material bill. Projects reserve delivered stock when work begins and consume it as work proceeds. If required material stops arriving, the project pauses, reduces scope, or chooses a physically valid substitution. It must not complete as its intended form for free.

```gdscript
{
    "project_id": 31,
    "plot_id": 17,
    "target_form": "durable_timber_compound",
    "required": {"Timber": 18.0, "Fiber Plants": 7.0, "Clay": 2.0},
    "reserved": {"Timber": 11.0, "Fiber Plants": 7.0, "Clay": 0.4},
    "consumed": {"Timber": 4.0, "Fiber Plants": 2.0, "Clay": 0.2},
    "substitutions": ["earth_infill", "smaller_footprint"],
    "state": "material_constrained"
}
```

Material feasibility should be evaluated as:

```text
feasible_supply = delivered_stock_reserved
                + reliable_deliveries_during_build

form_feasibility = min(
    required_material_coverage,
    construction_knowledge,
    skilled_labor,
    tool_capacity,
    transport_capacity
)
```

Do not count material still at a deposit as building supply. It must reach the settlement or construction site. Bulk, common buildings should overwhelmingly use local resources because the transport cost of stone, earth, timber, and fuel is high. A wealthy institution may import a limited prestige material only when exchange capacity, a functioning route, logistics labour, and a recorded delivered quantity pay for it.

#### Initial resource-to-form rules

| Resource and knowledge | Forms enabled | Constraints and consequences |
|---|---|---|
| Timber | Posts, log walls, frames, floors, long roof spans, palisades, shingles if practiced | Fire, rot, insects, maintenance, and forest depletion; large buildings require exceptional members and transport |
| Fiber Plants | Cordage, mats, woven walls, thatch, light roof covering | Frequent replacement, fire risk, moisture decay; enables light structures but not massive spans by itself |
| Clay / suitable earth | Packed floors, daub, cob/adobe-like walls, storage lining | Unfired earth needs weather protection; local soil suitability matters and roofs still require a spanning material |
| Clay + sustained fuel + firing practice | Pottery, fired brick, drain/roof tile where developed | Fuel intensive; kilns create dirty-industry plots and can drive deforestation or fuel trade |
| Stone | Rubble foundations, paving, retaining walls, defensive mass, durable walls | Quarrying, shaping, hauling, and lifting are expensive; ordinary `Stone` must not silently become dressed marble |
| Limestone + firing fuel | Lime wash, plaster, mortar, improved masonry | Requires quarry access, heat, containers, specialist adoption, and continuing fuel |
| Sand + appropriate heat/practice | Mortar aggregate and eventually glass-related uses | Sand alone does not unlock glass; high-quality transparent material is never automatic |
| Copper/bronze/iron | Tools, fittings, fasteners, weapons, limited architectural reinforcement | Early metal supply improves construction capability but is too scarce for mass structural fabric |
| Peat/charcoal/coal | Process heat, firing, lime, metal production | Creates extraction, storage, smoke, transport, pollution, and fire burdens; it is not a wall material |

`Stone` is currently a broad resource in `resource_system.gd`. Until geological subtypes exist, render it as local rubble/fieldstone. Monumental dressed stone, marble, granite ashlar, and similar prestige families must wait for explicit deposit identities, quarry development, specialist knowledge, and delivered stock.

#### Valid substitutions

Substitution changes the resulting form rather than merely changing a label:

- Insufficient timber may produce smaller rooms, shorter spans, earth walls, shared party walls, or unfinished roofs.
- Insufficient fiber may delay roofing or substitute bark/wood roofing only when local timber and practice permit it.
- Insufficient stone may remove foundations, paving, retaining walls, and vertical scale; it must not produce a differently colored stone building.
- Insufficient fuel may keep clay unfired, halt lime production, and reduce metal/tool availability.
- Insufficient transport may force smaller local construction even when a distant deposit is known.
- Insufficient maintenance inputs reduces condition and usable capacity before the structure collapses.

Substitution may also fail. The model must be willing to leave a project incomplete.

#### Resource environments must create different settlements

- A timber-rich, stone-poor valley should show timber compounds, thatch or wood roofs, fire spacing, wood yards, and frequent rebuilding. It should not acquire a masonry skyline from population growth.
- A clay-rich, fuel-poor plain should rely on unfired earth and imported or scarce roof members. Fired-brick expansion remains limited until fuel logistics exist.
- A stony upland with little timber may build durable low rubble walls yet remain roof-span constrained. Dense multistorey forms do not follow automatically.
- A reed/fiber wetland may support light, frequently renewed buildings on selected dry or raised ground, with morphology dominated by water access.
- A connected trade centre may import scarce materials for a hall, gate, shrine, or quay, while ordinary households continue using local vernacular materials.

Resource exhaustion changes the town. It can shift building form, increase repair debt, cause salvage, move industry toward a new deposit/route nucleus, or leave obsolete plots. Existing buildings do not instantly change material when a deposit is discovered.

## 7. Plot health, damage, and destruction

Each monthly update computes maintenance demand and available maintenance labour/materials.

```text
maintenance_supply = construction_labor
                   * labor_efficiency
                   * material_capacity
                   * institutional_coordination

condition_delta = routine_maintenance
                - age_and_material_decay
                - overcrowding
                - hazard_damage
                - conflict_damage
                - abandonment_decay
```

Suggested condition interpretation:

| Condition | State |
|---:|---|
| 0.80–1.00 | Healthy / recently maintained |
| 0.60–0.79 | Worn but functional |
| 0.40–0.59 | Stressed; reduced capacity |
| 0.20–0.39 | Damaged; strong visual scars |
| 0.01–0.19 | Unsafe shell or ruin |
| 0.00 | Destroyed footprint; rubble or reclaimed plot |

Damage APIs must target exact plots or a spatial footprint:

```gdscript
SettlementModel.apply_plot_damage(plot_id: int, severity: float, cause: String)
SettlementModel.apply_area_damage(center_km: Vector2, radius_km: float, severity: float, cause: String)
SettlementModel.abandon_plot(plot_id: int, cause: String)
```

Fire should spread along roof coverage, material flammability, wind, and plot spacing. Flood should follow elevation. Warfare should follow attack direction, defenses, routes, and strategic targets. The first implementation may apply bounded area damage without fully simulating spread, but it must leave persistent damaged and ruined plots.

### 7.1 Warfare uses spatial combat footprints

Provincial army presence is not enough to determine settlement damage. A battle, raid, siege, assault, bombardment, occupation, or retreat must emit a spatial event describing what forces attempted and where. The warfare system decides military action and outcome; `SettlementModel` translates the resulting footprint into plot-level consequences.

```text
army state + doctrine + weapons + supplies + objective + approach terrain
                                  |
                           CombatFootprint
                                  |
             +--------------------+--------------------+
             |                    |                    |
       plot exposure        people exposure      resource exposure
             |                    |                    |
      condition/status     demographic events     loss/seizure/fire
             \____________________|____________________/
                                  |
                    repair, return, and land-use cycle
```

Combat event schema:

```gdscript
{
    "id": 144,
    "day": 18742,
    "kind": "raid",
    "attacker_id": 8,
    "defender_id": 2,
    "objective": "seize_food_stores",
    "approach_origin_km": Vector2(1.4, -0.8),
    "affected_polygon": PackedVector2Array([...]),
    "primary_route_ids": [3],
    "intensity": 0.58,
    "duration_days": 2.0,
    "attack_channels": {
        "close_assault": 0.62,
        "fire": 0.35,
        "projectile": 0.12,
        "siege": 0.0,
        "powder": 0.0
    },
    "control_after": "defender",
    "discipline": 0.48,
    "scorched_ground": false,
    "source_resources": {"Timber": 8.0, "Fiber Plants": 3.0},
    "resolved": false
}
```

Add these APIs:

```gdscript
SettlementModel.resolve_combat_footprint(event: Dictionary) -> Dictionary
SettlementModel.begin_occupation(event: Dictionary) -> Dictionary
SettlementModel.end_occupation(event: Dictionary) -> Dictionary
SettlementModel.plot_exposure_to_footprint(plot: Dictionary, event: Dictionary) -> float
```

The result should return affected plot IDs, demographic exposure, displaced-household demand, destroyed/looted resource quantities, route interruptions, water/food contamination, and event text. It must not directly invent citizen deaths; the demographic consequence system consumes exposure and records actual deaths, injuries, separations, or flight.

### 7.2 Different forms of warfare produce different land scars

| Military event | Primary spatial pattern | Likely plot effects |
|---|---|---|
| Field battle outside settlement | Approach corridors, fields, pasture, camps | Trampling, harvest loss, temporary earthworks, abandoned equipment, limited core damage |
| Raid | Fast route from edge to selected objective | Looted stores, seized animals, burned workshops/houses, short displacement, selective damage |
| Sack | Broad movement through accessible core after defenses fail | Looting, arson, killing/exposure, civic desecration, widespread vacancy, claim disruption |
| Siege | Defensive perimeter, gates, water, stores, nearby fields | Consumed timber/earth for works, cut routes, food loss, disease, contaminated water, demolished approaches |
| Assault | Narrow breaches and approach lanes | Extreme gate/wall/frontage damage, rubble corridors, concentrated casualties, secondary fire |
| Bombardment | Weapon-dependent impact fields | Structural and fire damage shaped by range, accuracy, ammunition, roof material, and density |
| Occupation | Strategic plots rather than random destruction | Requisitioned housing, barracks, guarded stores, offices, checkpoint routes, crowding and neglect |
| Retreat / scorched earth | Supply route and denied assets | Burned stores, bridges, fields, workshops, boats, and defenses selected for denial value |
| Civil conflict | Patchy neighbourhood and institutional targets | Contested claims, barricades, selective reprisal, fragmented service access, persistent social boundaries |

Combat should not apply uniform percentage damage across the settlement. Objectives select likely targets; approach routes and defenses shape access; weapon channels shape the kind of damage; discipline and doctrine shape spillover.

### 7.3 Military capability is resource constrained

Warfare cannot generate damage channels unsupported by knowledge, weapons, ammunition, fuel, and logistics.

- Field fortifications consume earth-moving labour, timber, fiber, stakes, stone, baskets, and tools as appropriate.
- Siege frames require delivered timber, cordage, tools, skilled crews, transport, and time.
- Incendiary attack requires a plausible ignition material and delivery method; wet weather and fire-resistant material reduce spread.
- Stone or metal projectiles must be quarried, produced, transported, and expended.
- Powder artillery requires the existing sulfur, nitrate, charcoal, iron, knowledge, and supply chain gates.
- Defenders consume food, missiles/ammunition, repair material, water, medical supply, and replacement weapons.
- A besieger without supply cannot maintain maximum intensity indefinitely.

The combat event records expended source resources. Resolution must validate the requested attack channels against those resources. Unsupported channel intensity is reduced rather than silently granted. This is the warfare equivalent of “no marble towers in a timber-only land.”

### 7.4 Plot-level damage resolution

For each intersected plot:

```text
exposure = footprint_overlap
         * approach_access
         * objective_priority
         * event_intensity

effective_damage[channel] = exposure
                          * channel_strength
                          * plot_vulnerability[channel]
                          * duration
                          * randomness_from_event_and_plot_seed
                          * defense_failure
```

Vulnerability depends on real form and material mix:

- Timber/fiber roofs burn readily but may be rebuilt relatively quickly if local supply survives.
- Earth walls resist fire but erode after roof loss and prolonged weather exposure.
- Rubble masonry may survive fire while floors, roofs, doors, and inhabitants do not.
- Dense roof coverage increases spread and obstructs firefighting and evacuation.
- Open yards may buffer fire yet expose stored bulk and animals to seizure.
- Fortified stores resist casual raids but become priority siege targets.
- Water, drainage, medical, storage, and route plots cause system-wide secondary effects when disabled.

Separate damage channels because they demand different recovery:

- `structural`: foundations, walls, roof support, bridge/route body
- `fire`: combustible fabric and heat damage
- `contamination`: wells, food stores, waste, corpses, flood/siege pollution
- `looting`: movable stock, tools, animals, fittings, records
- `neglect`: weather and failure after displacement or occupation

Looting may devastate a plot's function while leaving its shell intact. A visually standing workshop without tools, fuel, workers, or doors is not healthy productive capacity.

### 7.5 Immediate civilian and service consequences

Plot resolution returns exposure; the demographic system applies it to numeric population cohorts. Resident-density and household-equivalent distributions make risk non-uniform without tactical human simulation.

Possible consequences:

- evacuation before contact when warning and routes exist
- people trapped by fire, breach, crowding, disability, or blocked routes
- injury and mortality exposure
- household separation, missing people, captivity, or flight
- loss of stored food, tools, records, seed, animals, and medicine
- water contamination and disease after combat
- loss of shelter capacity before the population count changes
- cascading food, health, logistics, legitimacy, knowledge, and security failures

An empty building is not proof its residents survived, and surviving residents are not proof they can remain. Demographic and morphology histories must cross-reference a shared event ID.

### 7.6 Repair is a plot decision, not automatic regeneration

After damage, evaluate one action per plot:

- emergency stabilization
- patch repair
- faithful restoration
- reduced-scope rebuilding
- resource-substituted rebuilding
- adaptive reuse
- salvage and demolition
- secured ruin
- abandonment

Decision score:

```text
repair_priority = habitability_gain
                + restored_service_value
                + household_attachment
                + economic_value
                + heritage_or_legitimacy_value
                + defense_value
                - remaining_hazard
                - material_cost
                - labor_cost
                - access_blockage
                - claim_conflict
```

Repair bills derive from the plot's actual missing fabric, not a generic health bar. A burned timber roof needs timber/fiber and labour. A breached rubble wall needs compatible stone, fill, lifting, and tools. A looted shop needs tools and stock more than wall material. A contaminated well requires cleaning, safe disposal, time, and health knowledge.

Suggested time envelopes under adequate supply:

| Damage | Earliest stabilization | Typical functional recovery |
|---|---:|---:|
| Looted but structurally sound | Days–weeks | 1–12 months, depending on replacement tools/stock |
| Light roof/wall damage | Days–weeks | 1–6 months |
| Serious partial structural damage | Weeks–months | 1–5 years |
| Burned or breached shell | Months | 2–10 years |
| Destroyed civic/bridge/water work | Months–years | 3–20 years |
| Ruined district after sack/siege | Years | 10–40 years or never |

These are not timers that guarantee completion. Shortages, insecurity, repeated fighting, displacement, disease, winter, and claim disputes can freeze a plot in any stage.

Emergency work must compete with new housing, defenses, food production, and military supply for the same construction labour and delivered resources. Repairs reserve and consume materials through `ResourceSystem` exactly like new construction. Salvage produces bounded recovered stock based on material, fire intensity, looting, contamination, tool capacity, and labour; it must not recover the full original bill.

Rebuilding may create a visibly different patchwork form. Preserve `pre_damage_use`, original material history, repair events, and substitutions so a stone shell with a timber patch or an earth replacement wing remains legible.

### 7.7 Repopulation is a staged household process

Vacant capacity does not automatically attract population. Return depends on safety, kinship, claims, employment, water, food, services, health, transport, trauma, and confidence that the peace will last.

Required stages:

1. **Flight or evacuation:** households leave threatened plots for intact local plots, satellite settlements, camps, or other regions.
2. **Displacement:** temporary crowding stresses host plots and may create emergency shelter polygons.
3. **Security assessment:** routes, hazards, unexploded/unsafe remnants where applicable, contamination, and control are evaluated.
4. **Claim and access:** prior occupants, heirs, occupiers, institutions, newcomers, and authorities may assert conflicting rights.
5. **Salvage/temporary use:** gardens, pens, markets, shelters, workshops, or material salvage may return before residence.
6. **Household return:** some former residents return when minimum habitability and safety exist.
7. **Service reopening:** water, food exchange, schooling/healing, worship, workshops, and transport make broader return sustainable.
8. **New settlement:** migrants or new households occupy abandoned land, possibly changing culture, use, density, and street access.

Monthly return propensity for a displaced household cohort:

```text
return_propensity = security
                  * habitability
                  * water_and_food_access
                  * livelihood_access
                  * route_access
                  * kin_and_place_attachment
                  * claim_certainty
                  * expected_peace
                  - disease_risk
                  - trauma_or_stigma
                  - reconstruction_burden
                  - opportunity_elsewhere
```

Track displaced population cohorts in aggregate; there are no citizen records to bloat:

```gdscript
{
    "id": 12,
    "origin_plot_ids": [41, 42, 57],
    "households": 19,
    "people": 83,
    "displaced_day": 18742,
    "current_location_kind": "local_host_plots",
    "current_location_id": 8,
    "cause_event_id": 144,
    "returning_households": 3,
    "permanently_resettled_households": 2,
    "claim_strength": 0.78,
    "return_propensity": 0.41
}
```

Use cohort summaries at every scale. Displaced totals must reconcile with the authoritative numeric population cohorts; plot demand never creates replacement residents.

### 7.8 Repopulation changes plots unevenly

- Intact plots near reopened water and markets repopulate first.
- Heavily damaged but prestigious or central plots may be repaired before peripheral housing.
- Poor households may occupy unsafe shells or contested land before formal repair, creating `unsafe_return`.
- Returning craftspeople prioritize workshop access; farmers prioritize fields, animals, and routes.
- Occupation-era barracks/offices may become housing, civic plots, or contested compounds.
- Ruins may become gardens, shrines, memorials, salvage yards, informal markets, or defensive clear ground.
- A depopulated district may never regain its former use even if total settlement population later recovers.
- Newcomers can create new nuclei rather than filling the old centre, especially when claims, trauma, hazards, or obsolete routes make it unattractive.

Repopulation therefore changes `resident_count`, `worker_count`, `secondary_use`, `roof_coverage`, `condition`, `claim_pressure`, and sometimes `land_use` or `form`. It does not normally change the inherited polygon immediately.

### 7.9 Recovery metrics and history

Add to `settlement_morphology`:

```gdscript
"displaced_population": 83,
"host_crowding_population": 61,
"returned_population_last_year": 18,
"plots_awaiting_repair": 14,
"plots_under_repair": 6,
"plots_contested": 3,
"service_recovery": 0.52,
"prewar_housing_capacity": 740,
"usable_housing_capacity": 468,
"reconstruction_material_shortfall": {"Timber": 42.0, "Stone": 18.0},
"last_conflict_day": 18742
```

Keep a bounded plot-history ledger containing event ID, day, old/new state, cause, resource bill, recovered salvage, occupant change, and responsible authority. Aggregate old monthly entries after a threshold, but never discard founding, destruction, occupation, major repair, land-use conversion, or reoccupation milestones.

## 8. Functional settlement classification

### 8.1 Core scores

All scores are in `[0, 1]` and use current systems wherever possible.

- **Permanence:** durable occupied plots, water reliability, seasonal storage, multigenerational continuity.
- **Specialization:** share of able population in crafting, extraction, knowledge, administration, logistics, and services; capped by actual facilities.
- **Exchange:** surplus, delivered material flow, market plots, external route traffic, and hospitality.
- **Institutions:** administration labour, communal/civic plots, legitimacy, customary practices, public stores.
- **Connectivity:** reachable settlements/resources and route quality expressed in travel time.
- **Infrastructure:** water, drainage, storage, streets/routes, sanitation, defense, and maintained public works.
- **Diversity:** distinct active land uses, forms, materials, nuclei, occupations, and origins. Do not use cosmetic color variation as diversity.

### 8.2 Class gates

Population bands are diagnostic expectations only. They are not direct unlocks.

| Class | Typical residents | Required functional evidence |
|---|---:|---|
| Founding camp | 20–200 | Provisional shelter; permanence below 0.35 |
| Hamlet | 40–300 | Permanent households and reliable water; little specialization |
| Village | 150–1,500 | Permanence >= 0.50; shared institution; seasonal storage; collective identity |
| Large village / local centre | 600–3,000 | Periodic exchange; several specialists; serves nearby households or hamlets |
| Town | 1,500–15,000 | Exchange >= 0.35; specialization >= 0.30; connectivity >= 0.30; permanent market or equivalent service role |
| City | 10,000–100,000+ | Regional catchment; food import dependency; multiple districts/nuclei; layered institutions and infrastructure |
| Metropolis | 100,000+ | Coordinates multiple regions; high-volume logistics; several specialised centres; failure has regional effects |

Recommended hard gates:

```text
village:    permanence >= .50 and communal_functions >= 2
town:       exchange >= .35 and specialization >= .30
            and connectivity >= .30 and service_population > resident_population
city:       exchange >= .55 and institutions >= .50
            and infrastructure >= .50 and food_import_share >= .15
            and district_count >= 3 and service_population >= 1.5 * residents
metropolis: connectivity >= .70 and institutions >= .65
            and active_nuclei >= 5 and regional_dependency >= .60
```

A 1,300-person river port may therefore be a town. A 2,500-person farming agglomeration with weak exchange may remain a large village.

Display both the classification and its limiting factors in UI. Example:

```text
LARGE VILLAGE — 2,180 residents; serves 3,040 people
Weekly exchange and six specialist plot clusters.
Limited by unreliable regional transport and weak administration.
```

## 9. Building and plot progression: years 0–200

The clock is measured from `settlement_founded_day`, not global campaign day. “Available” means the form may emerge when its prerequisites exist. It is not granted automatically at the listed year.

Every entry below is subordinate to the resource rules in section 6.6. References to durable halls, warehouses, paving, walls, upper levels, bridges, quays, fired products, or monumental construction are conditional descriptions of function and scale. Their actual form must be generated from local and delivered materials. Two settlements at year 100 should look structurally different when one has timber and clay while the other has quarry stone, lime fuel, and water transport.

### Years 0–0.25: halt and survival camp

- **Dwellings:** wagons, tents, bedroll clusters, lean-tos, shared sleeping shelters.
- **Productive:** open butchery/cooking area, tool-repair cloth, animal tethering, gathering piles.
- **Storage:** guarded baggage circle, raised bundles, temporary caches.
- **Communal/civic:** hearth circle and council gathering space.
- **Water/waste:** carried-water point; latrine and refuse plots placed away from intake.
- **Morphology:** 100–220 m irregular cluster; 18–30 coarse plots; paths are desire lines.
- **Failure form:** scattered abandoned camp stains and salvaged ground, not a vanished marker.

### Years 0.25–1: permanent foothold

- **Dwellings:** light household huts, pit or semi-sunken houses where suitable, small long shelters, fenced family compounds.
- **Productive:** open work yards, food-drying racks, fibre working, carpentry/joinery yard when known.
- **Storage:** lined pits, roofed communal store, protected seed/food cache.
- **Commercial:** informal household exchange around hearth or landing; no dedicated shop requirement.
- **Institutional:** watch post, customary meeting place, burial or remembrance ground.
- **Infrastructure:** drainage cuts, improved path to water, simple footbridge where needed.
- **Morphology:** household plots stabilize; wet or unsafe sites are abandoned; first frontage appears.

### Years 1–3: hamlet formation

- **Dwellings:** durable timber/earth/reed compounds; extensions for births, elders, animals, and storage.
- **Productive:** dedicated potting area, kiln/pit-firing edge plot, woodworking shelter, fishing or landing yard.
- **Storage:** granary form where cultivation exists; sealed vessel store; separate fuel stack.
- **Commercial:** exchange ground used on irregular surplus days.
- **Institutional:** shrine, ritual enclosure, healer’s household, formal watch shelter.
- **Infrastructure:** shallow drains, lined well if discovered, maintained field and resource paths.
- **Morphology:** 1–3 kin clusters may form; the founding hearth remains important but need not be geometric centre.

### Years 3–5: established hamlet or early village

- **Dwellings:** rebuilt second-generation houses; joined compounds; early material differences reflecting prosperity.
- **Productive:** clustered craft yards; smoke, kiln, slaughter, and waste uses begin moving outward.
- **Storage:** household plus communal storage; guarded high-value store.
- **Commercial:** periodic stalls; visiting traders may camp at the edge.
- **Civic/sacred:** more permanent meeting hall or ritual structure if collective labour supports it.
- **Infrastructure:** stable lanes, culverts, small landing, fenced or ditched defended edge where danger warrants it.
- **Morphology:** infill begins; oversized compounds can subdivide; first satellite farmstead possible at 1–3 km.

### Years 5–10: village fabric

- **Dwellings:** courtyard-like compounds, longhouses, clustered huts, or freestanding houses according to culture and climate.
- **Productive:** full-time or near-full-time workshop plots; mills only where power source and knowledge exist; larger kilns and food-processing yards.
- **Storage:** communal granary/storehouse; material yard connected to extraction routes.
- **Commercial:** scheduled market ground; guest shelter, food/drink household, pack-animal yard.
- **Civic/sacred:** council hall, public store, dedicated ritual precinct, defensive muster space.
- **Infrastructure:** maintained streets/lanes, wells, drainage network, simple bridges, boundary works.
- **Morphology:** recognizable central place and edge uses; field polygons preserve former footpaths and property lines.

### Years 10–15: diversified village

- **Dwellings:** higher roof coverage; plot extensions and inheritance subdivisions; a small number of higher-status compounds.
- **Productive:** specialized metal, ceramic, textile, carpentry, food, or boat-work clusters as discoveries and resources allow.
- **Storage/logistics:** loading yard, route-side warehouse precursor, public reserve.
- **Commercial:** regular periodic market; permanent stall foundations where exchange pressure is sustained.
- **Institutional:** record/tally space, specialist healer, teaching or apprenticeship household.
- **Infrastructure:** improved approaches; landing, ferry, or bridge becomes a secondary nucleus when strategically placed.
- **Morphology:** mixed-use frontage around market route; nuisance industries clearly separate from clean water and dense housing.

### Years 15–25: large village or local centre

- **Dwellings:** denser compounds, shared walls in constrained cores, satellite farm hamlets.
- **Productive:** purpose-built workshops; ore preparation and charcoal plots where relevant; larger communal processing.
- **Storage/logistics:** guarded warehouses, caravan/boat unloading ground, standardized containers or measures when known.
- **Commercial:** permanent stalls, inn/guest court, trader storage, specialist service households.
- **Civic/sacred:** durable hall, court/assembly space, tax/tribute or redistribution store if institutions develop.
- **Infrastructure:** named streets or route segments, maintained bridge/wharf, defensive gate or ditch where necessary.
- **Morphology:** market/crossing may rival the hearth as centre; route ribbons and absorbed farmsteads create irregular arms.

### Years 25–40: town candidate

- **Dwellings:** dense mixed-use core plots; rear workshops and upper/later sleeping mass implied at medium LOD.
- **Productive:** workshop quarters emerge from compatibility and route access, not zoning commands.
- **Storage/logistics:** warehouse frontage, bulk yards, protected food reserves, animal/change station.
- **Commercial:** daily or near-daily exchange becomes possible; multiple inns and permanent shops only if external demand supports them.
- **Civic:** administrative hall, guard house, archive/tally store, dispute court, public works yard.
- **Infrastructure:** surfaced high-traffic routes, drains, quay/bridge works, firebreaks, perimeter defenses where needed.
- **Morphology:** first true blocks may appear; gates and bridges focus land value; poorer or migrant edge clusters may form.

### Years 40–60: early town

- **Dwellings:** compact rows or courtyard compounds in valuable core; larger peripheral household plots remain common.
- **Productive:** ironworking becomes possible after recognition and supply; fuel-intensive work concentrates at transport-accessible edges.
- **Storage/logistics:** specialized grain, fuel, timber, ore, and valuable-goods stores.
- **Commercial:** permanent market hall/court form, shops with household use, lodging district around arrival routes.
- **Civic/sacred:** layered offices or precincts; formal watch, courts, or temple establishment depending on society.
- **Infrastructure:** bridge replacement, quay expansion, trunk drains, wells/cisterns, maintained defenses and fire response.
- **Morphology:** several neighbourhood identities; abandoned founding-era plots survive inside denser later fabric.

### Years 60–80: mature town

- **Dwellings:** one- and two-level massing may be implied where material/engineering permit; rental or subdivided occupancy can emerge under crowding.
- **Productive:** larger standardized shops, repair yards, transport services, concentrated dirty industry.
- **Storage/logistics:** warehouse rows near wharf/road; distribution stores inside neighbourhoods.
- **Commercial:** specialized streets or clusters emerge from footfall; secondary markets serve outer wards.
- **Institutional:** schools/archives/healing houses only where knowledge and sustained support exist; public granaries and organized maintenance.
- **Infrastructure:** water distribution points, broader drainage, paved/surfaced civic routes, substantial walls or forts if strategically justified.
- **Morphology:** ward-like clusters and secondary nuclei; first satellite hamlets may be physically absorbed.

### Years 80–100: regional town or city candidate

- **Dwellings:** clear wealth and tenure variation; dense core, courtyard neighbourhoods, peripheral self-built compounds.
- **Productive:** industrial yards tied to fuel and bulk transport; craft/service districts; large mills where power permits.
- **Commercial:** multiple markets with different rhythms and goods; larger inns, depots, and counting/record space.
- **Civic/sacred:** monumental or durable public precinct becomes possible but must consume real surplus and labour.
- **Infrastructure:** trunk water, drainage, waste removal routes, bridges/quays, road hierarchy, organized fire and security capacity.
- **Morphology:** three or more functional districts are possible; routes between nuclei become developed corridors.

### Years 100–125: multi-nuclear urban system

- **Dwellings:** rebuilding cycles replace some early organic structures while preserving old plot boundaries; dense shared-wall fabric in expensive locations.
- **Productive:** specialist production complexes and regulated nuisance sites; material depots at the urban edge.
- **Commercial/logistics:** wholesale and local exchange separate spatially; warehouses cluster near bulk transport.
- **Institutional:** administrative, legal, educational, healing, sacred, and security functions can occupy distinct plots.
- **Infrastructure:** engineered crossings, maintained arterial approaches, cistern/reservoir or aqueduct-like works only with suitable knowledge and state capacity.
- **Morphology:** old village core, market core, transport core, and industrial edge coexist; classification may still be town if regional dependency is weak.

### Years 125–150: city consolidation, if achieved

- **Dwellings:** dense rental/subdivided compounds, courtyard blocks, planned institutional housing, and broad peripheral diversity.
- **Productive:** larger production precincts, repair economies, construction-material yards, food-processing districts.
- **Commercial:** hierarchical markets; high-value central exchange; bulk trade at gates, quays, or depots.
- **Civic:** layered administration and neighbourhood institutions; public works become continuous rather than episodic.
- **Infrastructure:** high-capacity water, waste, streets, defenses, and transport consume a permanent labour share.
- **Morphology:** infill and vertical intensity substitute for endless outward expansion where travel costs or walls constrain land.

### Years 150–175: regional city or extensive town network

- **Dwellings:** successive rebuilding produces heterogeneous roof materials, heights, lot coverage, and condition.
- **Productive:** old inner workshops may convert to housing/commerce while heavier production moves to new route or water nuclei.
- **Commercial/logistics:** specialized commercial centres, major depots, financial/record functions if institutions support abstraction and credit.
- **Civic/cultural:** multiple major precincts and neighbourhood identities; former villages retain distinct centres after absorption.
- **Infrastructure:** circumferential connectors may emerge from actual cross-town traffic; do not add ring roads based on population alone.
- **Morphology:** conurbation is possible. Green wedges, flood ground, walls, elite holdings, or ruins interrupt continuous fabric.

### Years 175–200: mature historic landscape

- **Dwellings:** every era remains visible: founding boundaries, old compounds, dense cores, planned expansions, informal edges, reconstructed disaster zones.
- **Productive:** multi-stage production and logistics landscapes; obsolete facilities convert, decline, or remain ruins.
- **Commercial:** several centres serve different catchments and social groups; centrality may shift away from the original core.
- **Civic/infrastructure:** regional-scale systems are possible only if maintained by durable institutions and surplus.
- **Morphology:** city, town network, dispersed agrarian region, fortified centre, port corridor, or partially abandoned landscape are all valid outcomes.
- **Failure form:** a former city can end year 200 as inhabited fragments among fields and ruins while retaining the classification history of its peak.

## Bounded visual grammar from camp to megalopolis

The renderer distinguishes seven achieved functional stages: founding camp, hamlet,
village, town, city, metropolis, and megalopolis. Population alone must not promote a
classified camp into town or city graphics. Functional classification, infrastructure,
production, route engineering, persistent plots, societal architecture, and damage all
contribute to the resulting form.

Mature stages add a nested sequence of polycentric cores, development corridors,
satellite centres, green seams, industrial/logistics belts, and skyline samples. Earlier
cores retain their seeded locations when a later stage is reached. Axiality,
monumentality, civic space, permeability, defensive depth, and terrain conformity alter
geometry as well as palette. Vertical massing is capped by infrastructure progress;
industrial belts require production progress; circumferential connectors require actual
engineered-route or infrastructure capacity.

Stage labels are thresholds, not visual jump cuts. While the current label remains
authoritative, the renderer quantizes progress toward the next stage from the weakest
real functional gate. A city approaching metropolitan function may therefore accumulate
additional persistent cores, satellite centres, corridors, and spatial weight before the
classification changes; a populous but disconnected city does not. Bounded neighbourhood
lobes and asymmetric development arms fill the aggregate footprint between authoritative
plots without inventing per-building state. Ordinary town approaches terminate at real
nuclei and grow outward; only mature metropolitan systems acquire selected through-routes.

Settlement defense is part of the same physical history. Watch posts, earthworks,
palisades, walled districts, and bastion networks are batched into the existing urban and
massing surfaces. Construction reveals deterministic advancing sections rather than a
ghosted complete wall. Integrity loss removes deterministic sections and lowers surviving
mass, so siege damage remains visible after combat. The strongest network is capped at
four strategic rings, twelve post/bastion proxies, and the same four total stage surfaces.
Five-percent construction and integrity buckets prevent daily fractional work from
thrashing the renderer.

The strategic stage renderer commits no more than four batched surfaces for the primary
urban system. A megalopolis uses at most eight cores, eight satellite centres, eight
corridors, twenty-four aggregate neighbourhood patches, three broken circumferential
connectors, four green seams, and sixty-four skyline mass proxies. Geometry is clipped to
authoritative land and river channels and remains fixed-budget at a billion residents.
Roofs and parcels cull at regional scale;
the bounded metropolis/megalopolis system persists farther so a hundreds-of-kilometres
urban region remains visible before finally collapsing into its strategic locator.

## 10. Rendering specification

### 10.1 LOD bands

Use apparent screen size or camera footprint, not only raw camera distance.

| LOD | Visual representation |
|---|---|
| Continental / regional | One settlement extent, density heat, route connections; no individual plots |
| Metropolitan / settlement | Batched plot polygons by use and condition; district/nucleus texture; major routes |
| Neighbourhood | Plot polygons plus deterministic roof-coverage polygons and yards; simple height variation |
| Founding close view | Existing authored hearth, shelters, pits, and work props may remain, aligned to simulated plots |

### 10.2 Plot appearance

Do not use one literal color per land-use category. Compute a constrained palette from:

- material family
- roof coverage
- condition
- moisture/vegetation
- prosperity
- fire/flood damage
- vacancy and reclamation
- age cohort

At settlement LOD, a plot should usually be one base polygon plus optional inset roof-coverage polygons. The inset geometry is seeded by `plot.seed` and never changes unless form or roof coverage changes.

Suggested visual cues:

- Healthy active: coherent surface, moderate contrast, maintained edge.
- Overcrowded/stressed: high roof coverage, narrow open space, darker or more varied inset massing.
- Vacant: low/no roof coverage, muted yard, partial vegetation.
- Damaged: broken inset coverage, dark scar or exposed substrate.
- Ruin: fragmented inset geometry and vegetation penetration; boundary remains faintly legible.
- Reclaimed: terrain-toned polygon with subtle boundary/history signature.

### 10.3 Batching and performance

- Build one `ArrayMesh` surface per visual bucket, not one `MeshInstance3D` per plot.
- Initial buckets: land-use family x condition band x LOD, with a practical cap of about 24 surfaces.
- Use vertex colors with a shared material.
- Keep plot count bounded by aggregation. One rendered residential plot may represent multiple adjacent household holdings at far LOD.
- Target 1,500 simulated plots and 50,000 polygon vertices for the first 200-year settlement prototype.
- A morphology rebuild should remain under 25 ms on the development machine; if not, move annual spatial work across frames or cache mesh chunks by district.

### 10.4 Immediate replacement in `local_terrain.gd`

The current `_create_urban_fabric()` reseeds rectangular blocks from current population. This makes the entire urban pattern jump whenever it rebuilds and loses historical continuity. Replace it with `_create_plot_fabric()` reading `GameState.settlement_plots`.

The current field generator may remain temporarily, but its population-seeded geometry has the same problem. Phase 2 should move field polygons into `SettlementModel` and preserve them as plots.

The current `urban_radius_km = sqrt(population / (PI * 1100))` may remain only as a fallback/diagnostic estimate. The rendered extent must ultimately be calculated from actual plot polygons.

## 11. Integration plan for this repository

### Phase A: stable model foundation

Create `scripts/settlement_model.gd` and register it as an autoload in `project.godot`.

Public API:

```gdscript
func process_month(context: Dictionary = {}) -> Array[Dictionary]
func ensure_founded() -> void
func rebuild_summary() -> Dictionary
func classification() -> String
func classification_reason() -> String
func plots_for_lod(lod: int) -> Array[Dictionary]
func apply_plot_damage(plot_id: int, severity: float, cause: String) -> Dictionary
func apply_area_damage(center_km: Vector2, radius_km: float, severity: float, cause: String) -> Array[int]
func validate_state() -> PackedStringArray
```

Add state fields from section 5 to `scripts/game_state.gd`.

In `scripts/local_terrain.gd`:

- Set `settlement_founded_day` when Hearth Circle completes.
- Call `SettlementModel.ensure_founded()` after the founding event.
- Call `SettlementModel.process_month(_discovery_context())` at 30-day boundaries after population/resources/consequences have processed.
- Replace the population-only footprint invalidation with `morphology_revision` tracking.
- Keep `_spawn_settlement_structure()` for close founding LOD only.

### Phase B: persistent renderer

In `scripts/local_terrain.gd`:

- Add `_create_plot_fabric(center, plots, lod, parent)`.
- Convert each local `Vector2` vertex to world `Vector3` using `center` and `_height_at()`.
- Triangulate concave polygons with `Geometry2D.triangulate_polygon()`.
- Batch triangles into visual buckets.
- Render damaged/ruined roof coverage deterministically from plot state.
- Calculate footprint bounds from polygons.
- Stop calling `_create_urban_fabric()` after migration succeeds.

### Phase C: residential and functional demand

- Derive occupied residential capacity from population, density, and aggregate household-equivalent demand.
- Link plots only to numeric resident and household-equivalent counts, never human references.
- Generate workshop, storage, market, civic, hospitality, water, and waste demand from real simulation metrics.
- Add construction recipes, reservations, consumption, provenance, valid substitutions, and incomplete-project states.
- Require delivered stock rather than known deposits for all plot construction and repair.
- Make plot capacity contribute to `GameState.housing_capacity`; remove the free-floating automatic housing increase after parity is proven.

Extend `scripts/resource_system.gd` rather than allowing `SettlementModel` to mutate stockpiles ad hoc:

```gdscript
func available_delivered_stock(resource_name: String) -> float
func reserve_materials(project_id: int, requested: Dictionary) -> Dictionary
func consume_reserved(project_id: int, requested: Dictionary) -> Dictionary
func release_reservation(project_id: int) -> void
func reservation_for(project_id: int) -> Dictionary
```

Store outstanding reservations in `GameState` so save/load and deterministic probes cannot duplicate material. `available_delivered_stock()` must subtract all other active reservations. `consume_reserved()` is the only construction path that removes reserved stock from the settlement inventory. Project completion must assert that the target form's non-substituted bill was consumed.

Add `scripts/settlement_construction_catalog.gd` or a data resource containing recipes. Keep recipes separate from spatial algorithms so balance can change without rewriting plot growth. Each recipe defines required practices, allowed material inputs, ratios, valid substitutions, labour, capacity, durability, flammability, maintenance bill, roof-span limit, and visual family.

Example catalog entry:

```gdscript
"durable_timber_compound": {
    "requires_practices": ["cordage", "joinery"],
    "materials": {"Timber": 18.0, "Fiber Plants": 7.0, "Clay": 2.0},
    "labor_days": 110.0,
    "resident_capacity": 9,
    "durability": 0.58,
    "flammability": 0.78,
    "maintenance_per_year": {"Timber": 0.35, "Fiber Plants": 0.75},
    "max_storeys": 1,
    "visual_family": "timber_fiber",
    "substitutions": ["earth_infill_compound", "small_light_compound"]
}
```

### Phase D: routes, fields, satellites, and damage

- Persist settlement routes and desire paths.
- Migrate fields from procedural render-only geometry to persistent `field` plots.
- Create satellite nuclei from travel-cost and economic triggers.
- Integrate fire, flood, conflict, abandonment, and reclamation events.
- Add historical peak class and class-change events to the ledger.

### Phase E: 200-year scale

- Add plot aggregation/chunking by district.
- Add yearly catchment graph and service population.
- Add conversion, split, merge, and absorbed-hamlet lineage.
- Profile maximum expected settlement size and enforce spatial-update budgets.

## 12. Determinism and migration

- Seed all new choices from `GameState.world_seed`, plot/nucleus ID, and the relevant simulated month.
- Never seed established plot geometry from population.
- Processing the same initial state through the same days must produce identical plots and classification.
- Existing campaigns or test states with a completed Hearth Circle and no plot data should lazily bootstrap via `ensure_founded()`.
- Do not clear existing settlement plots during a renderer refresh.

## 13. Tests and acceptance criteria

Create `tests/test_settlement_model.gd`.

### Model tests

1. Founding 120 residents creates 18–30 plots and at least residential, communal, storage, workshop, and waste functions.
2. Every polygon has at least three vertices, positive area, a unique ID, and a centroid close to its contained geometry.
3. Initial occupied extent is approximately 0.10–0.22 km across unless terrain forces dispersion.
4. Running the same seed twice yields identical plot IDs, polygons, uses, and conditions.
5. A population-only render refresh does not change existing plot polygons.
6. Growth reuses vacant plots before claiming distant edge land when access and condition are adequate.
7. Sustained housing pressure creates capacity only when construction labour and material capacity exist.
8. Population decline produces vacancy before reclamation and does not erase plot lineage.
9. Area damage changes condition/status and remains visible after later model updates.
10. A settlement cannot classify as a town using population alone.
11. A small, highly connected service centre can classify as a town when all functional gates are met.
12. A city classification requires regional service, food import dependency, multiple districts, institutions, and infrastructure.
13. A timber-only fixture never creates masonry forms, stone paving, or stone visual buckets.
14. A known but inaccessible stone deposit does not satisfy a construction bill.
15. A distant extracted material does not become usable until a shipment is delivered.
16. Fuel shortage prevents or constrains fired brick, lime, and metal-dependent construction.
17. Valid substitution changes form, capacity, durability, and appearance; it does not only rename the original project.
18. Material exhaustion increases repair debt and can pause new construction without erasing existing structures.
19. A raid follows an approach corridor and objective; it does not damage every plot by a uniform percentage.
20. A field battle outside the settlement can damage fields and routes without arbitrarily burning the urban core.
21. Unsupported siege, incendiary, projectile, or powder channels are reduced when the attacker lacks the necessary knowledge, weapons, ammunition, or delivered supply.
22. Timber/fiber, earth, and rubble plots respond differently to the same fire and structural footprint.
23. Looting removes or disables movable resources and productive capacity without requiring major structural damage.
24. Destroyed housing immediately reduces usable housing capacity and creates reconciled displacement demand.
25. Repair cannot progress without labour, access, safety, and reserved delivered materials matching the actual damage channel.
26. Salvage never returns the full original material bill and is reduced by fire, looting, contamination, and poor tool access.
27. Vacant capacity alone does not trigger return when security, water, food, claim certainty, or expected peace is inadequate.
28. Returning households prefer viable origin plots or appropriate livelihoods, while contested or hazardous plots can remain vacant during broader population recovery.
29. Repeated conflict can interrupt repair and displace partially returned households without resetting plot history.
30. Repopulation reconciles with authoritative population and displaced-cohort counts and never creates population merely to fill repaired plots.

### Renderer tests / probes

1. Headless mesh creation succeeds for active, vacant, damaged, ruin, and reclaimed plots.
2. Batched surface count remains below the configured bucket cap.
3. A 1,500-plot fixture stays below 50,000 plot vertices at settlement LOD.
4. Advancing population without a morphology month does not rebuild or move the settlement fabric.
5. Rebuilding the same revision produces identical mesh bounds and vertex counts.

### 200-year scenario probes

Add deterministic probes rather than assuming one canonical outcome:

- **Stable agrarian:** remains a village/large village with dispersed fields and low food imports.
- **River exchange:** becomes a small town at lower resident population due to service catchment and transport.
- **Isolated growth:** reaches a large population but fails town/city gates because connectivity and exchange remain weak.
- **Urban success:** develops multiple nuclei and reaches city function only after logistics, institutions, and imports support it.
- **Rise and decline:** reaches town/city form, loses population after a shock, and retains vacant districts and ruins at year 200.
- **Timber vernacular:** reaches town function without accessible stone and remains visibly timber/earth rather than receiving generic masonry.
- **Quarry trade:** a small quantity of imported dressed material appears only in the funded civic plot while ordinary housing remains local.
- **Raid and return:** targeted stores and edge housing are looted/burned; displaced households crowd intact plots, then return unevenly as safety and services recover.
- **Long siege:** routes, fields, water, defenses, and food systems fail in sequence; postwar recovery remains constrained by disease, rubble, material loss, and damaged logistics.
- **Failed reconstruction:** peace returns but resource exhaustion and claim conflict leave a formerly dense district as temporary gardens, salvage plots, and ruins.

### Definition of done for the first implementation slice

- Founding produces persistent plot polygons.
- Plots do not jump when population changes.
- Monthly growth adds or converts plots from simulation pressures.
- Condition, vacancy, damage, and ruin have distinct stored states and visible treatments.
- Settlement classification uses functional gates and explains limiting factors.
- Existing close-view founding structures still work.
- Existing demographics and resource-flow tests pass.
- New settlement-model tests pass headlessly.

## 14. Codex execution order

Implement in reviewable slices. Do not attempt the entire 200-year system in one edit.

### Slice 1: state, founding plots, and determinism

Files:

- `project.godot`
- `scripts/game_state.gd`
- new `scripts/settlement_model.gd`
- new `tests/test_settlement_model.gd`

Deliver persistent founding plots, schemas, deterministic generation, validation, and lazy migration. Do not change housing capacity or the renderer yet.

### Slice 2: plot renderer and stable visual history

Files:

- `scripts/local_terrain.gd`
- renderer tests or a headless probe

Render batched active/vacant/damaged/ruin plot polygons. Stop using `_create_urban_fabric()` for founded settlements. Verify that changing population without processing a morphology month does not move plot geometry.

### Slice 3: resource-backed construction

Files:

- `scripts/resource_system.gd`
- `scripts/game_state.gd`
- new `scripts/settlement_construction_catalog.gd`
- `scripts/settlement_model.gd`
- resource and settlement tests

Add reservations, recipes, consumption, substitutions, provenance, paused projects, and maintenance inputs. Preserve the existing material-flow probe. This slice is not complete until the timber-only and inaccessible-stone tests pass.

### Slice 4: monthly demand, condition, vacancy, and classification

Files:

- `scripts/settlement_model.gd`
- `scripts/local_terrain.gd`
- `scripts/consequence_engine.gd` only if a clean event hook is required
- settlement tests

Connect actual population, labour, health, logistics, resources, and institutions to plot demand. Add functional class gates and limiting-factor text. Keep current `housing_capacity` behaviour behind a compatibility path until plot-derived capacity passes balance probes.

### Slice 5: routes, fields, nuclei, damage, and 200-year probes

Files:

- `scripts/settlement_model.gd`
- `scripts/local_terrain.gd`
- deterministic scenario probes under `tests/`

Persist routes and fields, support satellite nuclei and absorbed hamlets, add area damage/ruins, then run the deterministic 200-year scenario suite. Optimize only after profiling the actual fixtures.

### Slice 6: warfare, displacement, repair, and repopulation

Files:

- new `scripts/warfare_system.gd` or the eventual authoritative combat system
- `scripts/settlement_model.gd`
- `scripts/resource_system.gd`
- `scripts/consequence_engine.gd`
- `scripts/game_state.gd`
- `scripts/local_terrain.gd`
- new deterministic combat/recovery probes under `tests/`

Do not begin this slice by adding cosmetic scorch colors. First establish the `CombatFootprint` contract and one authoritative event ID shared by warfare, demographics, resources, and plots. Implement in this order:

1. Resolve a resource-validated raid against target plots and approach routes.
2. Produce demographic exposure, resource loss, capacity loss, and displaced cohorts without double-counting people or stock.
3. Add damage-channel-specific visuals and service outages.
4. Add repair decisions, material reservations, salvage, and interrupted work.
5. Add staged return, claims, host-plot crowding, and new-settlement outcomes.
6. Expand from raids to field battles, siege, assault, occupation, scorched retreat, and later weapon-dependent bombardment.

The existing `scripts/main.gd` only moves abstract armies between provinces, while `scripts/consequence_engine.gd` models security as a settlement-wide metric. Preserve those behaviours until a tested warfare system can supply spatial events. Do not infer detailed urban destruction merely because an enemy army entered a province.

For every slice, Codex must first run the existing demographics, food-balance, and resource-flow suites; preserve unrelated user changes; and report measured test/probe results rather than claiming visual correctness from code inspection alone.

## 15. Explicit trade-offs

### Persistent polygons vs. population-generated texture

Persistent polygons cost memory and require migration logic, but they are necessary for historical continuity, destruction, inherited street patterns, and player recognition. Population-generated texture is cheaper but makes the map visually dishonest.

### Aggregate plots vs. individual buildings

Aggregate plots cannot represent every household object. They are appropriate at this camera scale and can still derive capacity from households. A later close LOD can decorate each plot deterministically without changing the authoritative model.

### Organic growth vs. perfect physical simulation

Weighted spatial heuristics are preferable to simulating every land transaction. The important requirement is that every spatial change has a legible pressure and preserves history.

### Monthly morphology vs. daily updates

Monthly updates reduce cost and visual noise. Major damage events may force an immediate update, but ordinary growth should not occur one frame or one day at a time.

## 16. Revisit after the foundation works

- Culture-specific plot forms and materials
- Ownership, tenure, rent, land value, and displacement
- Formal planning, cadastral surveys, expropriation, and planned grids
- Multiple independent settlements per province
- Inter-settlement migration and service-catchment graphs
- Climate-specific water, shade, heating, and construction logic
- Navigable waterways and port morphology
- True polygon clipping and district mesh streaming
- Close-LOD procedural roof masses and landmark assets

These should extend the persistent plot model rather than replace it.
