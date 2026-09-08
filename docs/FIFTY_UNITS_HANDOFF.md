# Fifty land units and additional naval/air chains — development checkpoint

Status: **HELD, not integrated or launched.** This checkpoint is not a complete
naval/air game and is not HOI4 parity. The user requires 50 land units plus full
naval and air chains, available neutrally to every civilization.

Worktree `/Users/seanpurtill/Documents/Codex/tt-fifty-units`, branch
`codex/fifty-units`, base `da9f91718a182230c3ebb5286ed8556dd8bb6829`.

## Implemented in this isolated checkpoint

Exactly 50 land archetypes, combat coefficients, equipment links, recipes,
training durations, marching pace and selected counter relationships. The
progression dock shows separate 50-land / naval / air tabs with roles, lineage,
knowledge blockers and reserve equipment. Modern weapon gates now require named
adopted technologies rather than broad development tiers. Added research
prerequisites are checked for missing entries and cycles.

Twenty naval and sixteen air catalog entries, with research, recipes, crews,
range and mission roles. The experimental joint-operations adapter uses the
campaign clock, aggregate population commitments and reserve equipment. Base
construction, commissioning, training, disbanding, mission validation, repair,
fuel use, contact detection, primitive force attrition, replacement and optional
save state exist, but are not an end-to-end operating system.

## Required before release

- Real geographic sea connectivity, transit and fleet/task-force organization;
  multi-region operations and physical rebasing. Present region grid is a draft.
- Convoy routing, raiding, escort, naval dominance and invasion transport with
  actual supply/army consequences. Current convoy list has no implementation.
- Carrier wings and deck operations; transport/paradrop/air-assault execution;
  CAS, bombing, logistics strike and air-supply effects on actual campaign state.
  Current mission labels do not establish those capabilities.
- Rival production, basing, missions and losses from the same resource/crew model.
  Current detection/combat needs manually constructed opponents.
- Geographic force/region map and usable operations UI, commander objectives,
  reports and replacement explanations. Only the progression dock is wired.
- Integrate base construction/dockyard/aircraft labor with existing city labor
  without double counting. Current prototype work allocation is insufficient.
- Proper fuel production and late industrial inputs. Coal-derived fuel and draft
  hull/aircraft costs are placeholders requiring economic design and balance.
- Validate all land specialist roles in live battlefield contexts; marines,
  paratroopers and air assault currently march on foot without transport support.
  Expanded coefficients are not evidence of 50 independently balanced roles.
- Stronger adversarial save validation, external population mortality handling,
  independent regional weather, mission engagement timing and visual journeys.

## Validation

81 unique targeted/regression cases passed across seven suites: catalog/UI 6,
joint operations 5, persistent production 19, equipment quotes 6, combat 20,
military development 16, recruitment reconciliation 9. These are isolated
headless checks, not a live campaign or full naval/air validation. Every land
recipe produces exactly one target item after its concrete research; joint
commission/disband conserves equipment and aggregate crew commitments; corrupt
base/equipment references reject before campaign mutation; same day cannot train
twice. Legacy development tests now explicitly require research after domain
capacity reaches the industrial band.

Logs: `/tmp/fifty-unit-map-tests.log`, `/tmp/joint-operations-tests-3.log`,
`/tmp/fifty-land-regressions.log`, `/tmp/fifty-land-regressions-2.log`.
Initial test discovery had a corrected test variable parse error; Godot then
crashed during failure cleanup. Subsequent runs pass without runtime errors.

## Compatibility and ownership

Existing equipment and unit IDs remain. No stock deletion or automatic unit
upgrade. New optional `joint_operations` state defaults empty for old saves;
existing modern stocks remain, but new production/training requires the new
research. This intentionally changes the former broad-tier unlock behavior.
Shared hotspots: military_campaign.gd and discovery_system.gd. Also owns combat,
unit/equipment/knowledge catalogs, persistent production, military dock, new
progression provider and tests. Unrelated generated UID files are not included.
No canonical player restart and no remote push.

## Land roster

| # | Unit | Role |
|---|---|---|
| 1 | Levy | Numbers, garrison mass, and the mobilization base every later form draws on. |
| 2 | Line Infantry | Holds ground in formation; the anchor other arms maneuver around. |
| 3 | Skirmisher | Screens, harasses, and scouts ahead of the line; the army's forward eyes. |
| 4 | Cavalry | Shock, pursuit, and operational reach; turns victories into routs. |
| 5 | Siege Engineers | Breaks fortifications and builds the works that protect a besieging army. |
| 6 | Field Artillery | Massed fire against formations and works alike. |
| 7 | Rifle Infantry | Dispersed accurate fire; the standard formation of industrial war. |
| 8 | Machine-Gun Company | Sustained suppression; makes open ground impassable. |
| 9 | Motorized Infantry | Operational mobility for infantry; reach without exhaustion. |
| 10 | Armored Formation | Protected shock and breakthrough; the war wagon's industrial heir. |
| 11 | Modern Artillery | Long-range indirect fire coordinated by survey and signals. |
| 12 | Spearmen | Stop mounted charges with ranked reach |
| 13 | Axemen | Break shielded infantry at close quarters |
| 14 | Slingers | Cheap standoff harassment with stone ammunition |
| 15 | Javelineers | Disrupt a charge before withdrawing |
| 16 | Massed Archers | Concentrate missile fire behind a protective line |
| 17 | Pikemen | Deny cavalry and frontal approaches; exposed to missiles |
| 18 | Crossbowmen | Pierce armor with deliberate ranged volleys |
| 19 | Armored Swordsmen | Close assault against missile troops and lighter infantry |
| 20 | Light Infantry | Screen and exploit broken ground; avoid sustained shock |
| 21 | Mountain Infantry | Hold difficult terrain with portable weapons and specialist kit |
| 22 | Light Cavalry | Scout, pursue, and attack exposed missile troops |
| 23 | Horse Archers | Mobile missile harassment; weak in a fixed melee |
| 24 | War Chariots | Fast missile and shock platforms on open ground |
| 25 | Armored Cavalry | Massed shock against an unprepared line |
| 26 | War Elephants | Heavy shock and morale pressure; vulnerable to dispersed missiles |
| 27 | Dragoons | Ride to position and fight dismounted with firearms |
| 28 | Battering Ram Crews | Breach gates under protective timber |
| 29 | Catapult Crews | Mechanical bombardment of walls and concentrated troops |
| 30 | Trebuchet Crews | Heavy long-range siege bombardment; costly to move |
| 31 | Bombard Crews | Demolish fortifications with heavy powder guns |
| 32 | Horse Artillery | Move light guns quickly with mounted columns |
| 33 | Mortar Teams | Portable high-angle fire against covered infantry |
| 34 | Rocket Artillery | Area saturation with high ammunition demand |
| 35 | Hand Cannoneers | Early close-range gunpowder fire with low cohesion |
| 36 | Musketeers | Disciplined firearm volleys protected by other troops |
| 37 | Grenadiers | Assault enclosed defenses and close infantry positions |
| 38 | Sharpshooters | Precision harassment; low mass and weak close defense |
| 39 | Assault Infantry | Infiltrate and clear trenches at close range |
| 40 | Marines | Train for shore landings and fighting around ports |
| 41 | Airborne Infantry | Air insertion infantry; requires transport aircraft for a drop |
| 42 | Combat Engineers | Breach field defenses and support fortified fighting |
| 43 | Antitank Teams | Defeat armor at the cost of general infantry firepower |
| 44 | Antiaircraft Batteries | Protect concentrations from aircraft; vulnerable to ground assault |
| 45 | Armored Reconnaissance | Fast protected reconnaissance; light armor only |
| 46 | Light Tanks | Exploit gaps quickly; avoid heavier armor |
| 47 | Heavy Tanks | Break defended fronts with heavy protection and a large supply burden |
| 48 | Tank Destroyers | Concentrate armor-piercing fire; weak against close infantry |
| 49 | Mechanized Infantry | Protected infantry keeps pace with armored forces |
| 50 | Air Assault Infantry | Helicopter-lift infantry; land movement remains on foot without lift |

## Naval chain (additional to 50 land)

- War Canoes — patrol; requires river craft.
- Ram Galleys — strike force; requires galley navigation.
- Heavy Boarding Galleys — strike force; requires naval arsenals.
- Sailing Warships — patrol; requires ocean sailing.
- Sailing Frigates — convoy escort; requires naval gunnery.
- Ships of the Line — strike force; requires naval gunnery.
- Steam Corvettes — convoy escort; requires steam propulsion.
- Ironclads — strike force; requires armored hulls.
- Torpedo Boats — convoy raiding; requires naval torpedoes.
- Destroyers — convoy escort; requires naval torpedoes.
- Light Cruisers — patrol; requires armored hulls.
- Heavy Cruisers — strike force; requires naval fire control.
- Battleships — strike force; requires naval fire control.
- Submarines — convoy raiding; requires submersible hulls.
- Aircraft Carriers — strike force; requires carrier aviation.
- Amphibious Assault Ships — invasion support; requires amphibious operations.
- Missile Patrol Boats — strike force; requires guided weapons.
- Missile Destroyers — convoy escort; requires naval missiles.
- Nuclear Submarines — convoy raiding; requires nuclear propulsion.
- Fleet Support Ships — convoy escort; requires naval logistics.

## Air chain (additional to 50 land)

- Observation Balloons — reconnaissance; requires aerostat observation.
- Patrol Airships — reconnaissance; requires powered flight.
- Reconnaissance Aircraft — reconnaissance; requires powered flight.
- Fighters — air superiority; requires fighter tactics.
- Heavy Fighters — interception; requires advanced airframes.
- Ground-Attack Aircraft — close air support; requires aerial bombardment.
- Tactical Bombers — logistics strike; requires aerial bombardment.
- Strategic Bombers — strategic bombing; requires advanced airframes.
- Naval Bombers — naval strike; requires naval aviation.
- Transport Aircraft — air supply; requires airborne operations.
- Jet Fighters — air superiority; requires jet propulsion.
- Jet Bombers — strategic bombing; requires jet propulsion.
- Transport Helicopters — air supply; requires rotary wing.
- Attack Helicopters — close air support; requires guided weapons.
- Reconnaissance Drones — reconnaissance; requires remote aircraft.
- Strike Drones — close air support; requires remote aircraft.
