# Military presentation on the map

Branch `codex/war-fronts`. How war looks on the map from the first feud to
theatre-wide war, how fronts are derived, which real battle tactics generals
use and when, and how sea and air zones fit in.

The governing rules do not change. Generals execute every battlefield decision
in every era (docs/GENERAL_CAMPAIGN_DESIGN.md). The map shows what the generals
are doing and what they intend, and what came of it. It never offers the player
unit control or tactic picking. A click on a front, arrow or clash opens
information or the conversation with the general who owns it. Population
changes the numbers on a formation, never the number of map nodes. Enemy
positions come only from dated observations.

## 1. What the map shows today (survey of main 330d88c3)

| Layer | Source | What it draws |
|---|---|---|
| Formation counters | `local_terrain._refresh_player_field_army_markers` → `WarfareMapPresentation.build_snapshot` | A 3D plate per army (max 12 own, 24 foreign): role glyph, echelon bars, readiness pip, supply track, damage scars, selection ring. Away armies appear at their last runner report before signal-era communications. |
| Occupied ground | `army_front_visual.gd` | An aggregate filled polygon under each counter (area from troops and equipment). It is per army; nothing joins two armies. |
| March orders | `_create_player_field_army_path` | A straight two-point ribbon from the army to its destination, 3–5 chevrons and an objective ring. |
| Front tokens | `front_marker` / `_refresh_warfare_front_markers` | Built every refresh, then **hidden** (`marker.visible=false`): the old diamond-and-percentages token was retired. |
| Wars and feuds | `hud/war_map_overlay.gd` + `war_map_marks.gd` | One feud/war icon at the geometric midpoint between home and the nearest known enemy city, a short dashed "border" across that line, raid smoke icons near home (fading over 24 days) and our band icon sliding along the straight home→enemy line. Plain-words hover text. |
| Battle close-up | `close_army_figures`, battle contact shader, battle screens | Figures and contact ground when zoomed to a battle; the round-by-round engagement card in the war-planning dock. |
| Sea and air | `hud/service_world_overlay.gd`, `joint_operations.gd` | Player-drawn operating areas (polygons), bases, force positions and routes. Missions (patrol, convoy raiding, air superiority, close air support…) are assigned per area and resolved by `joint_effects.gd`. |
| Authored campaign | `general_campaign_map.gd` | A separate 2D board for the Alderford War with dated enemy counters and the general's route. |

### What is weak

1. **There is no front.** Two opposing armies are two separate counters with
   two separate ground blobs. Nothing shows who holds what or where the
   contact is, so a war has no shape.
2. **The war mark sits in the wrong place.** It is drawn halfway between the
   two capitals whatever the armies are doing, so the fighting and the mark
   can be far apart.
3. **Intent is a straight line to a point.** A march ribbon says "going
   there". It never says "to take that crossing" or "to cut them off", and
   there are no objective markers beyond the ring at the end of the line.
4. **Battles have no shape and no tactics.** The resolver draws random local
   events whose text hard-codes two force names ("River Host", "Hill Guard")
   whoever is fighting. No general ever flanks, feigns or encircles.
5. **Every era looks the same.** A stone-age band of twelve gets the same
   plate, bars and pips as a mechanised corps.
6. **Sieges** appear only in the siege screen, not on the map.

## 2. Target presentation by era

The presentation stage is derived from what the civilization actually fields
and knows (`WarFrontLines.stage`), not the calendar:

| Stage | Chosen when | Land presentation |
|---|---|---|
| **skirmish** | largest force under 250, or before writing with no drilled formation | No front lines. Inked raid paths (dotted, from the raiders' side to what they struck), smoke where they struck, a small crossed-spears clash mark where bands met, our band's footpath out and back. |
| **host** | forces under about 1,000, or no formation drill yet | Each host has a leader's standard and its marching route (a curved inked arrow to the general's objective). When two hosts are in contact a short facing line is drawn between them only; no continuous front exists. |
| **field** | drilled forces of 1,000+ | Front segments where armies face each other, bulging toward the weaker side; offensive arrows from the front to the general's objective; objective marker; clash marks at engagements; siege rings around invested cities (arc = share of approaches held, ring tightens with pressure). |
| **theatre** | military staffs known and 20,000+ in the field, or three or more field armies | Contacts join into one continuous front per enemy; a dashed fallback line behind our own front; several arrows (converging marches); pockets drawn when a breakthrough closes. |
| **modern** | theatre plus radio and armour | As theatre, with breakthrough arrows, closing pockets and trench hardening (a second parallel line behind the front, a sign of defence in depth). |

Zoom bands (`WarfareMapPresentation.scale_band`): at **ground** the battle
close-up owns the screen and the front layer draws only clash marks. At
**local** and **regional** everything above is drawn with widths held in
screen pixels. At **continental** fronts and arrows remain, and clash marks
merge per front. At **world** only one line per war remains.

### Art

Everything is ink on the painted map, per docs/ART_DIRECTION.md: a paper halo
under an iron-gall ink stroke, and owner colour only as a thin tint on arrows
and front teeth. Front lines carry the classic war-map teeth (small triangles
on the side that is pushing). Arrows are tapered, filled with a light owner
wash and outlined in ink. Stale enemy sections are dashed and faded. Glyphs
(clash, objective, standard) come from `resource_icons.gd`; no image assets.

## 3. The front "worm" model

A front is derived, never authored. Inputs are what the map may honestly know:

- **Own forces**: the same reported positions the counters use (runner
  reports before signal-era communications), troops, status, destination and
  the general's current objective.
- **Enemy forces**: `local_observation_snapshot()` `visible` and `recent`
  sightings only, each with a strength range and `last_seen_day`. An enemy
  force that has not been observed does not exist for the front.

Derivation (`scripts/war_front_lines.gd`, pure static functions, coordinates
in map km):

1. **Contacts.** Each own force is paired with every observed enemy force
   within the stage's contact distance (3 km skirmish, 6 km host, 14 km field,
   40 km theatre).
2. **Where the line sits.** For a pair, the contact point sits between them at
   `s = clamp(0.5 + 0.35·(own−enemy)/(own+enemy), 0.2, 0.8)` of the way from us
   to them: the stronger side has pushed the line toward the weaker. This is
   the **bulge**.
3. **Frontage.** The line at a contact runs perpendicular to the pair axis for
   a half-width that grows with the square root of the troops in contact,
   bounded between 0.4 and 12 km. A larger army holds a wider front, but the
   number of points does not grow.
4. **Joining and breaking.** Contacts against one opponent are ordered along
   the theatre axis. In the theatre stage, neighbours whose ends are within
   the join gap become one line; otherwise each contact is its own segment. A
   gap wider than the join gap is a **break**: the front is drawn as two lines
   with open ends, the visible sign of a breakthrough or a hole.
5. **Smoothing and bounds.** Two passes of corner cutting; each front is
   resampled to at most 48 points; at most 8 fronts are drawn.
6. **Observation age.** Each vertex takes the confidence of the enemy sighting
   that shaped it: `1 − age/90 days`. Below 0.5 the stroke is dashed and faded;
   this is "their line as last seen on day N".
7. **Deformation.** When the derived line changes, the overlay resamples old
   and new lines to the same count and eases between them over 0.8 s. There
   is no per-frame wobble and no noise.
8. **Tactic shape.** During an engagement, the active tactic adds a bounded
   offset to the contact: wings curling forward (envelopment), a bulge that
   sags back and snaps forward (feigned flight), a wedge (column assault), a
   closing ring (pocket), a doubled line (defence in depth). The offset comes
   from the round being resolved, so the shape follows the actual battle.

**Offensive arrows** come only from the general's structured intent: a field
army's `destination_position` when moving, its `city_operation` (attack or
besiege), or its intercept target. The arrow starts at the front contact
nearest the army (or at the army when no front exists) and ends at the
objective marker. Enemy arrows are drawn only for an observed moving
formation, as a short dated "seen heading" arrow that fades with age.

**Fallback lines** (theatre stage) are a dashed line offset behind our front
toward home. They show where the general will withdraw to; they do not
command anything.

**Sieges**: a ring round the target city whose drawn arc is the blockade share
from the siege model and whose radius tightens with pressure.

## 4. Real battle tactics, chosen by generals

`scripts/battle_tactics.gd` holds the catalogue. Each engagement records one
tactic per side (`engagement.tactics`). The general chooses it from what his
force can do, what the people know, the ground, the odds and his own traits.
Rivals use the same rules; their knowledge is inferred from the units they
field and their civilization's knowledge level. The player never picks a
tactic. He can ask the general about it in conversation.

Tactic names are generic and plain, in the era's words. No real battle,
commander or nation names are used.

### Capabilities

Derived from actual formations (surviving, equipped counts):
`missile` (bows, slings, javelins, crossbows, horse archers), `dense_foot`
(spear, pike, line, heavy foot), `pike`, `mounted` (cavalry of any kind,
chariots, dragoons), `heavy_mounted`, `gunpowder_foot`, `rifles` (rifles,
machine guns), `assault`, `artillery`, `armor` (tanks, mechanised and
motorised), `engineers`. Knowledge gates: `formation_drill`,
`domesticated_mounts`, `field_fortifications`, `military_staffs`,
`electrical_telegraphy` or `radio_telegraphy`, `radio_telegraphy`.

### Catalogue

| Tactic (plain name) | Earliest | Requires | Effect on resolution (bounded) | Map shape |
|---|---|---|---|---|
| Rush together | always | nothing | none; the default clash | clash mark |
| Dawn raid | band era | attacker, 250 or fewer on either side | first round: enemy caught unready; then the raiders break off early | raid path + clash |
| Ambush | band era | rough ground or small forces, general's tactics ≥ 0.5 | first two rounds: enemy exposure high; blunted by an enemy missile screen | hook round the road |
| Harry with missiles | bows | missile troops ≥ 25% | first three rounds: low losses on both sides, then normal | dotted screen ahead of the line |
| Shield wall | drill | dense foot ≥ 50% and formation drill (or pikes) | better defence, fewer own losses, slightly weaker attack; brittle against envelopment and flanking | thickened, straight line |
| Feigned flight | mounts or veteran drill | mounted ≥ 20%, or drill with tactics ≥ 0.65 | rounds 1–2 give ground; round 3 the pursuers are caught. If readiness is under 0.55 the flight becomes real | bulge sags back, snaps forward |
| Turn their flank | mounts | mounted ≥ 15% and domesticated mounts | from round 2 the enemy takes more losses; more so against a rigid line | one wing hooks forward |
| Hold a reserve | drill | drill, 500+ troops | weaker early, stronger from round 4 | a second short line behind |
| Hold them and strike from behind (hammer and anvil) | mounts + drill | dense foot ≥ 35% and heavy mounted ≥ 15% | hold two rounds, then heavy enemy losses | anvil line + hammer arrow |
| Close both wings round them (double envelopment) | mounts + drill | mounted ≥ 20%, dense foot ≥ 35%, drill, tactics ≥ 0.7 | the centre gives and takes losses; from round 3 either the pocket closes (heavy enemy losses) or the centre breaks. More likely to close against a rigid line and with more mounted troops | both wings curl into a pocket |
| Strengthen one wing (oblique order) | drill | drill, 1,000+ troops, tactics ≥ 0.65 | fewer own losses, more enemy losses from round 2 | the line angled, one end forward |
| Fortified camp | earthworks | defender with field fortifications or engineers | better defence, fewer own losses | small square camp |
| Siege lines | earthworks | a siege with engineers or field fortifications | presentation; the siege model already weighs starving against assault | ring round the city |
| Pike and shot | gunpowder | pikes and gunpowder foot | strong against mounted attack, slightly better fire | chequer of squares |
| Firing line | gunpowder + drill | gunpowder or rifles ≥ 40% and drill | better fire, a little more exposed | long thin line |
| Attack in column | gunpowder + drill | attacker, drill, line or gunpowder foot | first two rounds: shock both ways | wedge |
| Converging marches (corps) | staffs | military staffs and 20,000+ troops | the enemy is struck from several sides | several arrows meeting |
| Defence in depth | trenches + wire | rifles or machine guns, field fortifications, telegraph or radio | far fewer own losses; the attacker pays | doubled line with trench teeth |
| Infiltration | assault troops | attacker with assault infantry | rounds 2–4 hurt the enemy; weaker against defence in depth than a mass assault | thin arrows through gaps |
| Break through and encircle | armour + radio | attacker, armour ≥ 20%, radio | rounds 1–2 costly, then a pocket; blunted by antitank troops | spearhead arrow, closing pocket |
| Combined arms | armour + artillery + radio | armour, rifles or mechanised infantry, artillery and radio | steady advantage, fewer own losses | layered arrow |

Any tactic whose side has mounted troops adds a **pursuit**: when the enemy's
morale falls under 0.35, it takes extra losses (cavalry pursuit).

Bounds: per round, attack and defence multipliers stay within 0.85–1.25 and
exposure multipliers within 0.7–1.75 (the resolver clamps them again). The
tests check that no tactic appears before its requirements and that casualty
ratios over many seeded battles shift by bounded amounts.

### How a general chooses

Scores start from each eligible tactic's fit (odds, terrain, what the enemy
fields) and are weighted by the general's tactics skill and caution. Most
battles are plain clashes or simple tactics; the elaborate ones need a skilled
general and the right troops, which keeps them rare, as they were. The choice
is deterministic from the engagement seed, so a replay shows the same battle.

### Where it is wired

- `combat_simulator.gd`: `options.tactics` → per-round multipliers from
  `BattleTactics.round_effects`; each round records `tactic_event`.
- `military_campaign.gd`: the engagement chooses tactics when it begins and
  passes them each round; the result carries `tactics`.
- `war_loop.gd` (feud raids) and `general_campaign.gd` (Alderford) pass
  tactics to their one-shot battles; the general's report names the tactic.
- The war-planning engagement card names both sides' tactics.

## 5. Sea and air: drawn zones, run by their commanders

The user's rule: sea and air **stay drawn zones**, the current mechanic,
governed by the leaders of those branches. They are never turned into land
fronts, and no new control scheme is added.

Today the player draws an operating area (`joint_operations.create_region`),
and a fleet or wing is assigned to it with a mission. Missions resolve daily
(`joint_operations.advance`, `joint_effects.advance`): patrol routes are
generated inside the area, contacts lead to fights, and air missions become
`joint_air_support` / `joint_air_pressure` on land armies under that sky.

Target, inside each zone and chosen by the admiral or air commander:

| Branch tactic | Era gate | Drawn inside the zone |
|---|---|---|
| Coastal patrol / search lines | boats | patrol tracks (the generated route) as a fine dotted wake |
| Blockade cordon | sailing warships | a picket arc across the port approach; cuts the port city's supply (siege-style supply factor) |
| Convoy and escort | naval logistics | convoy routes with escort ticks |
| Commerce raiding | patrol + raiders; submarines later | dashed hunting tracks, sinking marks |
| Line of battle / fleet action | naval gunnery | two short opposed lines at a fleet contact, clash mark |
| Carrier strike | carriers | sortie arcs from the carrier |
| Air superiority patrol | powered flight | contested-air hatching over the zone; densest where control is near 50% |
| Close air support | bombers + radio | small strike ticks over the land front inside the zone |
| Interdiction / logistics strike | bombers | broken supply chevrons on roads under the zone |
| Air defence belt | antiaircraft | rings around defended points |

Bounded interactions with the land fronts (existing hooks, kept bounded):
air control over a front raises the owner's support and the enemy's pressure
(already capped at +30% / −25% attack); a blockade reduces a port's supply the
way a land siege's blockade share does; logistics strikes reduce an army's
supply by at most 0.1 a day. The front overlay hatches the stretch of a land
front lying under contested air.

## 6. Implemented in this branch vs designed only

See the handoff report for the exact status. In short: the tactic catalogue,
its gates, the general's choice and bounded resolution are implemented and
wired into field engagements, feud raids and the authored campaign. The front
derivation and the front overlay (fronts, bulges, breaks, stale dashing,
arrows, objective markers, clash marks, siege rings, eased deformation, tactic
shapes, era stages) are implemented. Early raids draw inked raid paths. Sea
and air zone tactics are designed here and not implemented.

## 7. Multi-era tactic check

`tests/test_battle_tactics.gd::test_multi_era_tactic_table` builds a
representative force for each era and prints the tactics a skilled and an
average general would choose. The printed table is copied into the handoff.
