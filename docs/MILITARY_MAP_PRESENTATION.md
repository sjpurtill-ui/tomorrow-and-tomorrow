# Military presentation on the map

Branch `codex/war-fronts`. This note covers three things: how war looks on the map from the first feud to theatre war, how fronts are derived, and how generals, fleet commanders and air commanders fight with real tactics gated by era.

The governing rules do not change (docs/GENERAL_CAMPAIGN_DESIGN.md). Generals execute every battlefield decision in every era. The map shows what they are doing and what they intend, and what came of it. It never offers the player unit control or tactic picking. Population changes the numbers on a formation, never the number of map nodes. Enemy positions come only from dated observations.

## 1. What the map shows today (survey of main `330d88c3`)

| Layer | Source | What it draws |
|---|---|---|
| Formation counters | `local_terrain._refresh_player_field_army_markers` → `WarfareMapPresentation.build_snapshot` | A 3D plate per army, up to 12 own and 24 foreign. Each carries a role glyph, echelon bars, a readiness pip, a supply track, damage scars and a selection ring. Away armies appear at their last runner report until the people have signal-era communications. |
| Occupied ground | `army_front_visual.gd` | An aggregate polygon under each counter. It is per army; nothing joins two armies. |
| March orders | `_create_player_field_army_path` | A straight two-point ribbon to the destination, with chevrons and a ring. |
| Front tokens | `_refresh_warfare_front_markers` | Built every refresh, then hidden (`marker.visible=false`). |
| Wars and feuds | `hud/war_map_overlay.gd` + `war_map_marks.gd` | For each war:<br>- one feud icon at the midpoint between home and the enemy's nearest known town;<br>- a dashed "border" stub across that line;<br>- raid smoke, fading over 24 days;<br>- our band icon sliding along the straight line from home to the enemy;<br>- plain words on hover. |
| Command fronts | `land_command._build_fronts`, `service_world_overlay.gd` | Three-point contact stubs, drawn only in the service planning view. |
| Sea and air | `service_world_overlay.gd`, `joint_operations.gd` | Player-drawn operating zones with a mission each, plus bases, force dots and last sightings, all in the service view. Missions resolve daily in `joint_effects.gd`. |
| Authored campaign | `general_campaign_map.gd` | The Alderford board: dated enemy counters and the general's route. |

**What is weak** (from the first draft of this note):

1. **There is no front.** Two opposing armies are two separate counters, so a war has no shape.
2. **The war mark is misplaced.** It sits halfway between the two capitals whatever the armies are doing.
3. **Intent is a straight line to a point.** It never says "to take that town" or "to cut them off".
4. **Battles have no shape and no tactics.** The resolver's random local events hard-code two force names ("River Host", "Hill Guard"). No general ever flanks, feigns or encircles.
5. **Every era looks the same.** A stone-age band of twelve gets the same plate as a mechanised corps.
6. **Sieges** are not on the map.

The "before" captures (section 7) reproduce these rules on fixed positions.

## 2. The front "worm" (`scripts/war_front_model.gd`, pure and deterministic)

1. **Sources**
   - Our armies, at the same reported positions the counters use.
   - Enemy formations, from dated sightings only: those visible now plus the recent list (90 days or less).
   - Each enemy report weighs `sqrt(strength) × (0.35 + 0.65·e^(−age/45 days))`. An enemy nobody has seen does not exist for the front.
2. **Field.** Each source puts a Gaussian bump on a fixed 32×32 lattice over the theatre. Its reach follows the typical gap between the two sides and grows slowly with strength.
3. **Line.** The front is the zero contour of ours − theirs, taken in raw strength. It is traced by marching squares and the pieces are chained into lines. The stronger side pushes the line toward the weaker, and that push is the **bulge**.
4. **Contact.** A stretch is kept only where the equal influence on it is at least 22% of the weaker side's peak. Where the forces part, the front **breaks** into separate lines. When they close again it rejoins.
5. **Per vertex.** Each point of the line carries four values:
   - **width**: how massed both sides are there. A stretched line is drawn thin.
   - **age**: the age of the reports behind it. Stale stretches are dashed and paler, with the caption "Their line here as last seen, N days ago".
   - **toward**: the enemy side, which the teeth point into.
   - **pressure**: which side is leaning on the line.
6. **Bounds and cost.**
   - At most 12 friendly and 24 enemy sources, 6 fronts, 96 points a front, 12 arrows and 8 clashes.
   - Deriving a front from 200 and 400 input armies (clipped to those bounds) took 12–19 ms headless.
   - Composing a full scene took 0.1–7 ms.
   - The model reruns only when its inputs change, checked at most every 0.5 s.
7. **Deformation.** When the inputs change, the old and new lines are resampled to the same count and eased over 0.9 s. There is no per-frame noise, so there is no jitter. Nothing redraws unless the camera moves or a morph is running.

**Intent.**
- **Offensive arrows** come from the general's actual objective: the army's `destination_position` while it marches, or the last point of its commanded route. An arrow starts at the nearest point of the front, or at the army if there is no front. It is a tapered, lightly filled war-map arrow with an inked edge, and ends at an objective mark.
- **Enemy arrows** are drawn only for an observed moving formation. They are dashed, and stale ones fade.

**Fallback and supply lines** appear in theatre mode only. The fallback line is the front offset toward home. Supply roads run from home to each army.

**Siege works** are a ring around the invested town:
- the ring tightens as the siege's pressure rises;
- a loose blockade is a dashed ring of camps;
- where the besieger knows field fortifications or siege engineering, the ring becomes lines with teeth facing inward and outward.

## 3. Presentation by era

The stage comes from what the people know and field, not the calendar: `WarFrontModel.mode(stage, known, largest force, armies, theatre troops)`.

| Mode | When | Drawn |
|---|---|---|
| **raid** | No formation drill and bands under 250 (or hearth-stage bands under 1,000 without drill) | No fronts and no plan arrows. Dotted raid tracks, like the scout charts: our band's path out, and their raid coming in and ending in a crossed-strokes clash. The existing feud marks and smoke stay. |
| **host** | Drill or 250+, but under 1,000 or not drilled | A short face-off arc only where two hosts are within reach, sitting nearer the weaker. Plan arrows and objective marks. |
| **front** | Drilled, 1,000+ | Continuous fronts:<br>- each side's wash either side of the line;<br>- oxblood teeth into the enemy;<br>- weight by massing, stale stretches dashed.<br>Plus plan arrows, dated enemy arrows, clashes with the tactic's shape, and siege works. |
| **theatre** | Military staffs and 3+ armies or 20,000+ in the field | As front, plus fallback lines and supply roads. |

**Zoom bands:**
- **ground**: nothing is drawn. The close battle figures own the view.
- **local**: fronts, clashes with their tactic shapes, and captions.
- **regional**: all of the above, plus the naval and air zones.
- **world**: fronts and arrows only, with no captions.

**Art.** Everything is iron-gall ink on the painted map with a paper halo (docs/ART_DIRECTION.md). Owner colour appears only as a thin wash and tint. Stale work is dashed. No image assets are used.

## 4. Real tactics, chosen by generals (`scripts/battle_tactics.gd`)

A tactic is available only when all of the following hold:
- every discovery in `requires_all` is known, and at least one in `requires_any`;
- the force has the composition it needs, measured as equipment-weighted shares of missile, mobile, shock, pike, firearm, artillery, engineer, armour and assault troops;
- the troop count, training, the general's command, the odds and the ground allow it.

Rivals follow the same rules. Their knowledge comes only from the gates of the units they field plus their general level of knowledge (`known_from_force`).

The general's choice is weighted and deterministic for the battle's seed:
- An unskilled general mostly fights head-on.
- Bold, careful or cunning character shifts the weights.
- A flank manoeuvre is more attractive against a rigid line the general can see.

Names are generic and plain, in the era's words: "hearth" before writing, then "lettered" and "reckoned".

| Tactic | First age | Requires | Needs | Effect (bounded exposure multipliers) | Map shape |
|---|---|---|---|---|---|
| Head-on (baseline) | stone | – | – | none | clash |
| Dawn raid | stone | – | ≤800, attacker | round 1: them ×1.45, us ×0.75 | strike marks |
| Ambush | stone | – | ground ≥1.08, ≤4,000 | round 1: them ×1.6, us ×0.7 | strike from the side |
| Missile harassment / skirmish screen | stone | bow, sling or hafted weapons | 20% missile | rounds 1–2: us ×0.8, them ×1.2, lower intensity | dotted screen |
| Shield wall | bronze | shield_wall | 35% shock | us ×0.82; rigid | shield line |
| Deep line of spears | bronze | formation_drill + spear/pike/bronze/shield | 40% shock, 300+ | us ×0.9, them ×1.12; rigid | dense line |
| Feigned retreat | bronze | mounts or drill | 20% mobile, or 30% missile with training ≥0.55 | round 1 yields (us ×1.15). Rounds 2–3: them ×1.55 if their training is lower; otherwise it fails (us ×1.2) | bulge back, then snap forward |
| Flank attack | bronze | mounts or chariots | 15% mobile | from round 2: them ×1.22, more against a rigid line | hook |
| Reserve held back | bronze | drill | 800+, command ≥0.5 | rounds 1–3 hold; then them ×1.25 | reserve block moving up |
| Fortified camp / field works | bronze | field_fortifications | defender, odds ≤1.1 | us ×0.78, them ×1.1 | works hatching |
| Escalade | bronze | – | assault on a town | us ×1.25 | storm |
| Hammer and anvil | classical | drill + mounts | 30% shock, 15% mobile, 1,000+ | from round 3: them ×1.35 | hook to the rear |
| Double envelopment | classical | drill + mounts or chariots | 18% mobile, 2,000+, command ≥0.62, odds ≥0.8 | rounds 1–2: the centre yields (us ×1.15). Then, at ≥46% power share, them ×1.55 (+0.15 vs a rigid line); otherwise the centre breaks (us ×1.3) | both wings curl, pocket closes |
| Oblique order | classical | drill + professional_corps | 3,000+, training ≥0.6 | from round 2: them ×1.2 | one wing forward |
| Breach and storm | classical | siege engineering, counterweights, powder artillery or field fortifications | 3% artillery or engineers | from round 3: them ×1.3 | breach |
| Pike and shot | gunpowder | pike_drill + matchlock_drill | 15% pikes, 20% firearms | us ×0.88 (×0.8 vs cavalry); rigid | squares |
| Firing line | gunpowder | drill + firearms | 40% firearms | us ×0.92, them ×1.18; rigid | volley line |
| Attack in columns | gunpowder | professional_corps + firearms | 30% firearms, 2,000+ | both ×1.12–1.2, higher intensity | column |
| Converging corps | gunpowder | military_staffs + optical, electrical or radio telegraphy | 20,000+ | from round 2: them ×1.28 | converging wings |
| Trench lines | industrial | field_fortifications + cartridges or automatic weapons | 40% firearms, defender | us ×0.7, them ×1.25 | trench hatching thickening each round |
| Defence in depth | industrial | staffs + indirect fire + field fortifications | 5,000+, defender | rounds 1–2 yield; then us ×0.85, them ×1.35 | staggered lines |
| Infiltration | industrial | automatic_actions + indirect_fire | 8% assault troops, or firearms with artillery | them ×1.25 (more vs trenches) | thin arrows through |
| Armoured breakthrough and pocket | modern | armored_vehicles + internal_combustion + radio | 12% armour | rounds 1–2 break in. Then, at ≥50% power share, them ×1.6 and the pocket closes; otherwise it stalls | spear, then ring |
| Combined arms | modern | armour + indirect fire + radio | armour and artillery | us ×0.88, them ×1.2 | layered |
| Pursuit (automatic, never chosen) | bronze | mounts | 15% mobile | their morale <0.38 from round 2: them ×1.3 | – |
| Siege works | – | none (blockade camps); field fortifications or siege engineering (lines) | – | presentation only; the siege model owns pressure | ring |

**Bounds.**
- Each side's per-round multiplier stays within [0.6, 1.7]; the combined multiplier per side within [0.55, 1.9]; intensity within [0.8, 1.2].
- A risky manoeuvre succeeds or fails by the fighting itself (the side's power share in the decisive round), never by a pre-rolled coin.
- Without a plan, the resolver is unchanged; a test confirms this.

**Tested outcome bound.** Over 40 seeded battles between equal armies, a double envelopment against a deep line may raise the attacker's wins by at most 18 of the 40. The defender's losses stay within 1.5 times the plain fight's.

**Multi-era check.** `test_tactics_appear_only_in_their_age` chose tactics for 300 seeds, both roles, with a typical force for each age. Shares are of battles:

| Age | Chosen |
|---|---|
| stone | head-on 59%, missile harassment 21%, dawn raid 13%, ambush 7% |
| bronze | head-on 45%, deep line 18%, shield wall 17%, reserve 13%, ambush 5%, fortified camp 3% |
| classical | head-on 36%, deep line 18%, shield wall 13%, reserve 11%, flank attack 10%, hammer and anvil 6%, oblique 4%, camp 2% |
| gunpowder | head-on 32%, pike and shot 11%, flank 11%, reserve 10%, shield wall 8%, firing line 8%, hammer and anvil 7%, columns 5%, converging corps 4%, oblique 3%, camp 3% |
| industrial | head-on 38%, firing line 14%, reserve 12%, trenches 9%, infiltration 6%, columns 6%, oblique 5%, camp 4%, converging corps 4%, depth 4% |
| modern | head-on 27%, combined arms 9%, firing line 9%, reserve 7%, flank 7%, trenches 6%, feigned retreat 5%, breakthrough 5%, oblique 4%, infiltration 4%, columns 4%, depth 4%, double envelopment 3%, camp 3%, converging corps 3% |

- No tactic appeared before its age.
- The plain fight stays the commonest in every age.
- Double envelopment stays rare, as in the record. In the classical sample the cavalry share was just under what it needs.

**Wired into:**
- **`MilitaryCampaign.begin_threat_engagement`** records `active_engagement.tactics`. Ours come from the player's discoveries and troops. Theirs come from their troops and `threat.technology`, which is now recorded on the threat.
- **`advance_engagement`** passes the plan and the round offset to `CombatSimulator.simulate(options.tactics)`. Every round record carries `tactic_event` and each side's phase. The final result carries `tactics`.
- **The battle report** names both tactics in era words: "Our general chose a double envelopment. The enemy answered with a shield wall." Before writing, it reads "We fell on them at first light."
- **The War Planning engagement card** shows "How they fight": our tactic with the round's event, and theirs.
- **The Alderford general campaign** plans every battle from the general's character and prefixes the report with the tactic sentence. Its public context gives the conversation `ways_we_can_fight`, so the player can discuss tactics. The general still chooses on the day.
- **Feud and raid clashes in `war_loop.gd`** plan from what each band fields.
- **The player never picks a tactic.** The existing HOLD / PUSH / RETREAT round actions are unchanged.

## 5. Navy and air: drawn zones, run by their commanders

The user's rule is that naval and air forces stay drawn zones, the current mechanic, governed by the leaders of those branches. The player draws a zone and assigns a mission, as the service view already allows.

Each day, inside the zone, the fleet or air commander chooses a zone tactic (`ZONE_TACTICS`):
- **Gates.** The choice is limited by the gates of the hulls and airframes the force actually has, plus, for the player, the player's discoveries.
- **Conditions.** A blockade needs a known hostile port inside the zone. Escorted day bombing needs friendly fighters working an overlapping zone.
- **Stability.** The commander keeps a tactic while it still fits.
- **Reporting.** A change is reported once in the joint events, for example "Home Fleet: a distant blockade, watching the approaches."
- **Effects.** The tactic scales the existing damage, detection and damage-received factors in `joint_battle.gd` within [0.8, 1.25].

**Sea tactics:** coastal raiding (canoes and galleys), grapple and board, ramming in line abreast (galleys), close blockade (sail era), distant blockade (torpedo era), line of battle (naval gunnery), crossing the enemy's line (fire control), commerce raiding, submarine packs (radio), escorted convoys, fleet in being, carrier strike.

**Air tactics:** balloon observation, air reconnaissance, fighter sweeps, ground-directed interception (radio plus radio detection), close support, interdiction, escorted day bombing, night area bombing, airlift.

**On the main map (regional zoom and wider), drawn by `war_front_overlay.gd`:**
- **Shading.** Each active player zone is shaded as contested water or air. Our wash deepens with `effects.control`; theirs shows where control is weak.
- **Hatching.** Ink hatching grows denser the more firmly the zone is held. Interception zones are cross-hatched.
- **Sortie arcs.** Air zones and carrier strikes get dashed sortie arcs from their base.
- **Blockade cordons.** A blockade draws a cordon of pickets across the harbour mouth: tight for a close blockade, wide for a distant one.
- **Contacts.** Dated contact rings fade over six days.
- **Caption.** The commander's tactic labels the zone.
- **Honesty.** Only our own zones and dated contacts are drawn.

**Designed only, not built:**
- Convoy lanes drawn from `logistics` convoys, with escort ticks.
- Air-defence belts, which need a layer showing where anti-air units are.
- Sea fronts as contested water between two fleets' zones, which need rival zones to become public observations.
- A blockade that cuts a port's supply over time; today the land siege model owns `blockade`.

## 6. Implemented vs designed only

**Implemented (this branch):**
- Front derivation, face-offs, fallback and supply lines.
- Plan arrows and objective marks, and dated enemy arrows.
- Clashes with the tactic's shape, which eases between rounds.
- Siege works and raid tracks.
- Naval and air zone shading, sortie arcs and cordons.
- All of the above in `hud/war_front_overlay.gd`, attached beneath the war marks in `local_terrain._ensure_war_map_overlay`, a two-line edit.
- The land tactic catalogue with gates, bounded resolution, reports, the engagement card, the general campaign context and war-loop raids.
- Naval and air zone tactics with bounded effects and events.

**Designed only:**
- Clicking a front or clash to open its general. Clicks pass through today, and counters already open War Planning.
- Clash marks for the command hierarchy's parallel battles (`command_hierarchy.data.battles`); only the active engagement is drawn.
- A fallback line taken from a general's actual withdrawal plan rather than a fixed offset.
- Corps and army-group marks at continental zoom.
- The sea and air items listed in section 5.

**Earlier draft.** A forked copy of this task wrote the first draft of this note and a first `battle_tactics.gd`. The final catalogue keeps three ideas from that draft:
- equipment-weighted composition;
- rigid lines being punished by flank attacks;
- the map `shape()` keys.

## 7. Captures

`tests/war_fronts_capture.tscn` is a test scene, run only through `tools/run_isolated_gpu_probe.ps1`. It writes six 1600×900 plates to `artifacts/war_fronts/`; they are not committed. The plates use a flat painted ground and flat counter stand-ins, so they show the overlay's composition and ink rather than the full in-game frame.

**Early raid** (`early_raid_before`, `early_raid_after`)
- **Before:** a border stub, a feud mark, a band icon and raid smoke.
- **After:** no front. Dotted raid tracks, their raid ending in a clash near our fields, and our band's dawn raid drawn as strike marks, captioned "Fell on them at first light".

**Mid campaign** (`mid_campaign_before`, `mid_campaign_after`): two armies, three dated sightings (one seen 25 days ago, one moving) and a siege.
- **Before:** straight blue ribbons to two rings.
- **After:**
  - one inked front with our wash and their teeth;
  - the stretch from the old sighting dashed and captioned with its age;
  - tapered plan arrows from the front to the objective and to the town;
  - a dashed enemy movement arrow;
  - the hammer-and-anvil hook at the clash, captioned in lettered words;
  - siege lines around the town.

**Late theatre** (`late_theatre_before`, `late_theatre_after`): six armies against eight observed formations, an air-superiority zone and a sea blockade.
- **Before:** counters only.
- **After:**
  - one continuous front with stale stretches;
  - a fallback line and supply roads;
  - the armoured-breakthrough pocket and their defence in depth, each named;
  - the hatched air zone with its sortie arc;
  - the blockade cordon of pickets offshore.
