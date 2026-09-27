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

**Built in round two (section 8):** convoy lanes, air-defence belts and a blockade that squeezes a port's supply and trade over time.

**Still designed only:** sea fronts as contested water between two fleets' zones. They need rival zones to become public observations first.

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

**Designed in round one, built in round two (section 8):**
- Clicking a front, arrow, clash, zone, lane or formation mark to open a note and talk to its general or the Marshal.
- Clash marks for the command hierarchy's parallel battles.
- A fallback line taken from each general's own withdrawal route.
- Corps and army-group marks at continental zoom.
- Convoy lanes, air-defence belts and blockades that bite.

**Still designed only:** sea fronts between rival fleets (section 5).

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


## 8. Round two: the real map, captions, conversation and blockades

Branch `codex/war-fronts-2`. Round one was checked on a flat stand-in. This round was checked on the real renderer: the real terrain, city cards, great works, borders, army counters and HUD, using a copy of a mature save (day 30,162, "Seanstone") and the authored Alderford war.

### What was wrong on the real map (the "before" plates)

- **Captions collided.** They landed on city cards, on each other and on the army counters. The siege caption and the objective mark covered the besieged town's card.
- **War ink sat above the city cards.** The overlay shared canvas layer 0 with the cards and was added later, so it drew on top.
- **Zones were invisible on real ground.** The air arm's olive ink matched the olive terrain, and the fleet's slate matched dark water.
- **Continental zoom collapsed.** Every caption and clash diagram piled into one knot. The front washes produced "triangulation failed" errors when the line folded on screen.
- **The Alderford war did not appear.** The coalition's two hosts were missing from the main map; the only mark was a straight march ribbon.
- **A new report restarted the morph.** The front jumped back to its last target before easing again.

### What changed

- **Captions** use the city labels' placement test. A new shared `CityLabels.free_spot` is used by the great-work cards and by `CityLabels.place_notes`.
  - Captions are placed highest priority first: battle and pocket, then siege, harbour and formation mark, then zone and sighting, then stale-report age.
  - They keep clear of city cards and pins, great-work emblems and cards, the feud tags, army and contact counters, and the open note.
  - A caption with no clear spot is dropped, never overlapped. Each keeps its spot between frames.
  - Captions use the book serif in italic, as the chart letters places.
- **Layering.** War ink moved to canvas layer -1, beneath the city cards and above the 3D map. The note is on its own layer above.
- **Contrast.** Fleet ink is a deep sea blue with pale hatching, which reads on dark water. The air arm uses a cool slate that no ground matches. Zone outlines have a paper halo.
- **Washes and arrows.** Each side's ground is drawn as two soft strokes, not as polygons, so a folded line cannot fail. Plan arrows have a paper halo and a stronger fill.
- **Scale per zoom band.**
  - Battle diagrams are sized to the gap between the two sides on screen, capped at 56 px close up and 40 px regionally.
  - A battle smaller than 20 px, or any battle at continental scale, becomes a crossed-strokes mark with its caption.
  - At continental scale the front loses its washes, and captions show only formation marks.
  - Long lines (supply roads, fallback lines, lanes, zone edges) are subdivided before projection, so they drape over hills and split where they pass behind the camera.

### Newly built

- **Talk from the map.** A click on a front, a plan arrow, a battle, a pocket, a siege, a fallback line, a zone, a convoy lane, a blockaded harbour, a formation mark or a dated sighting opens a small paper note.
  - The note says in plain words:
    - who holds that stretch;
    - what the general is doing (his own `command_status`);
    - the tactic being fought;
    - where he would fall back;
    - how old the reports are.
  - It offers one conversation, never an order:
    - a named war leader is summoned into the court by `figure_id`;
    - the Alderford general opens his own campaign screen;
    - otherwise the Marshal's office holder is summoned, or the court opens. The Marshal's office commands the fleet and air arm, because no admiral office exists yet.
  - A click on an army counter still selects it, as before, and its general's note opens too.
- **Parallel battles.** `battles_to_draw` draws the watched engagement plus every battle in `command_hierarchy.data.battles`, each once, up to 8. Each carries its own tactic shape and caption. Its note says it was fought under the command staff's plan.
- **Fallback from withdrawal intent.** Each general's fallback point is one day's march (`_field_army_speed`) along the road he would actually take:
  - the Alderford board's road home (`GeneralCampaign.route`);
  - his commanded route, when he is already withdrawing;
  - for a commanded army, the land route home (`land_command.route`, cached by position);
  - otherwise, the road home, which is where the engine sends a beaten army.

  The fallback line runs through the holders' points in order along the front. A single army gets a short line across its road back. A general who is withdrawing shows his road home, dashed, in place of an attack arrow.
- **Corps and army groups.** `echelons_from` reads the command tree:
  - corps (level 7) and armies (level 8) with troops;
  - organised headquarters whose children are all corps or larger, drawn as army groups.

  Each sits where its armies were last reported. At continental and world zoom it is drawn as an inked plate with its echelon crosses (XXX corps, XXXX army, XXXXX army group). A group's own corps give way to its mark when they would crowd it.
- **Pockets.** A front that closes round a seen enemy host, with none of ours inside, is a pocket. It is hatched inside. While a gap remains it has a ring at the gap and the caption "Pocket closing: about N thousand, K km gap". Once the ring closes, the caption reads "cut off". The closure eases.
- **Dated sightings without counters.** The Alderford coalition's hosts are drawn where the general last saw them (`state.seen`), fading with age, e.g. "Bracken Hold: about 160, seen today". Nothing newer is shown.
- **Convoy lanes.** Each player convoy (`joint_operations.state.convoys`) is drawn as a dashed lane for the route still to run:
  - escort ticks where `convoy_escort` power works that water;
  - a raider's warning where hostile `convoy_raiding` power does;
  - a note naming the branch commander.
- **Air-defence belts.** An air zone on `interception` is drawn as a belt: a double rim with ticks facing out. Under ground-directed interception, watchers' rings appear at the airfield.
- **Blockades that bite** (`scripts/naval_blockade.gd`, run daily from `joint_operations._advance_blockades`).
  - **Level.** A fleet whose commander chose a close or distant blockade raises the level of every hostile port inside its zone. The rate is 1/90 a day for a close blockade and 1/180 for a distant one, times how firmly the zone is held. The level caps at 0.6 (close) or 0.4 (distant). Once the fleet leaves it eases by 1/30 a day.
  - **Trade.** A port loses at most 0.8 × level of its sea trade, about half at the close cap. This applies to AI–AI and player–AI trade in `civilization_system`.
  - **Fish.** Our own blockaded port loses at most 0.5 × level of its fish harvest (`food_system`).
  - **A whole people.** A blockaded civilisation's food output falls by up to 0.35 × exposure and its supply by up to 0.3 × exposure, through `siege_effects_for_civilization`. Exposure is the level weighted by the share of its people at that port.
  - **Calibration.** Blockades of the sail and steam eras cut a port's sea trade by a half to four fifths within months. Runners still got through, and food fell far less than trade because most food came overland.
  - **Map.** The cordon closes and gains pickets as the level rises. The port's caption reads "Blockaded N days: sea trade X% down". Our own blockaded harbour shows their cordon in their ink.
  - **Saves.** The ledger is saved as `joint_operations.state.blockades` (bounded to 64 ports and validated). Older saves load with an empty ledger.
- **Motion.** The fronts no longer restart a 0.9 s morph on each report.
  - Every drawn front is carried on 48 points and chases its newest derivation with a 0.5 s time constant, so control shifting over days reads as a line that eases.
  - A new report mid-ease continues from where the line is drawn, with no jump.
  - A new front unrolls from its middle, and one that is gone fades where it was.
  - A test caps any one frame's movement at a small share of the change.
  - Pocket closure and battle shapes ease the same way.

### Cost (measured on the real renderer, 1600×900, fixture war with 5 armies, 6 sightings, 2 battles, a siege, 2 zones, a lane and a harbour)

| Measure | Value |
|---|---|
| Compose | 21–62 µs |
| Full draw with the camera still | 2.2 ms, and 0 redraws over 120 still frames |
| While a front eases | redrawn at most 30 times a second (61 redraws in 120 frames), worst draw 5.2 ms, settled within 2 s |

The costs are bounded as follows:
- Zone outlines and hatching are cached per camera view.
- Hatching and dashes are drawn as one batch per line.
- Heights are cached on a 50 m grid.
- A headless compose of 200 against 400 armies stays under 60 ms, with fewer than 120 primitives.

### Captures (real renderer, not committed)

The plates are written to `artifacts/war_fronts_real/` by `tests/war_fronts_real_capture.tscn`, run only through `tools/run_isolated_gpu_probe.ps1`. That run used a test-only `override.cfg` pointing `user://` at a private copy of the quicksave.

The save is still at the hearth. The fixture sets the presentation to a staffed theatre war (`mode: theatre`, `stage: reckoned`) near the real home and its nearest known foreign town, Tsaren.

**Before** (round-one code, same fixture):
- `mature_regional_before`: captions over the fronts and cards.
- `mature_local_before`: a readable front; the zone ink is invisible.
- `mature_continental_before`: everything piled into one knot, plus triangulation errors in the log.
- `alderford_local_before`: one march ribbon and no enemy at all.

**After:**
- `mature_regional_after` (200 km) and `mature_regional-wide_after` (453 km): captions clear of cards and counters; the air-defence belt in slate; battle diagrams scaled.
- `mature_local_after`: the front with both washes, the stale stretch, plan and enemy arrows, and the fallback line from the generals' roads.
- `mature_continental_after`: the "Northern Group · 54,000" army-group mark in place of its two corps; the harbour cordon.
- `mature_local_note_after`: the note opened on the front.
- `mature_local_motion0/1/2_after`: the line easing as their hosts are pushed back, a third of a second apart.
- `alderford_local_after`: the expedition's dotted track and the two coalition hosts as dated marks.

### Tests

`tests/test_war_fronts_round_two.gd` (16 cases) covers:
- caption placement: no overlap, drop order, stability, and the shared test with great works;
- the front note and its conversation-only action;
- summoning a named general;
- parallel battles;
- fallback along the road, and a withdrawing general's road;
- corps and army groups;
- the blockade over a year (slow, capped, eases away, bounded effects) and its campaign wiring;
- save validation of the ledger;
- belts and bounded lanes;
- easing without jumps;
- pocket detection and closure easing;
- theatre-scale cost;
- dated marks for hosts with no counter.

`tests/test_war_front_model.gd` now expects the raid-age band's own track.

### Limits

- **The captures use a fixture.** The mature save has no war, so the enemy side is supplied through the overlay's test-only `extra_inputs`. Our armies are real field armies in the private copy. Enemy counters for the fixture hosts are therefore absent. The Alderford plate is the authored war itself.
- **Army counters crowd the ground.** At regional and continental zoom, the terrain's army counters and their 3D labels still cover much of a small front. (Resolved in round three, section 9.)
- **The fleet and air arm answer through the Marshal.** Each fleet and wing now has a named admiral or air commander (section 10), but map notes still summon the Marshal.
- **Rival fleets' zones are not observed**, so sea fronts between fleets remain designed only.
- **Fixture change.** The "before" fixture had the second host at 9,000; the "after" fixture has it at 30,000, so that two corps form the army group.


## 9. Round three: forces as inked marks

Branch `codex/war-fronts-3`. The real-map captures of round two showed the terrain's own 3D army counters dominating the chart:
- large teal hexagons with plus marks;
- bold white world-space text ("Our band · 30000 fighters", "LAST REPORT · 0 DAYS OLD", "6.0K").

They covered small fronts at regional and continental zoom. The words were wrong too: 30,000 fighters is not a band, and the report line was staff jargon.

### What changed

- **The 3D counter is gone.** `local_terrain` keeps only a position node per force, its occupied ground up close, and a close-view label in plain words. The plate, glyph meshes, echelon bars, readiness tab, supply stripe, scars, selection torus and count label were removed, along with their mesh builders.
- **The war chart inks each force** (`hud/war_front_overlay.gd` with the new pure `hud/army_marks.gd`). Marks come from the procedural icon engine (`resource_icons.army_texture`), with no image assets. Each is drawn in iron-gall ink with a paper halo. Owner colour appears only on a streamer, a tally's tie, or a wash on the cloth.

  | Mark | When | Drawn |
  |---|---|---|
  | Spear tally | under 250 | 2 to 5 spears bound by one tally stroke; more spears for a bigger band |
  | Leader's standard | hosts; every force before writing | pole, finial, crossbar and streamer |
  | Framed standard | 5,000 or more in the lettered and printed ages | a hung cloth with the arm's sign (crossed spears, horse, bow, gun wheel) |
  | Staff-map box | rifles, machine guns, motors or armour (or staffs and 1,000 or more) | branch symbol (X foot, / horse, dot guns, oval armour, X with wheels for motors, bracket for engineers) with X, XX, XXX or XXXX strokes above |

- **Screen-space size per band:**
  - local 22 to 30 px;
  - regional four fifths of that;
  - continental about half, never below 12 px;
  - nothing at world scale.

  A force keeps the same size on screen however far the camera is within a band.
- **Crowding** (`ArmyMarks.layout`, pure over screen positions):
  - Overlapping marks of one side become one mark with a count roundel.
  - A mark on the front steps back toward its own side, with a hairline to where it stands.
  - Opposing marks are pushed apart.
  - Armies under a drawn corps or army-group mark give way to it, unless selected.
  - At most 12 of ours and 24 of theirs are drawn.
- **Paper cards.** Cards are placed with the city labels' placement test, and dropped rather than overlapped. They are budgeted: 6 local, 4 regional, none wider. The selected force always gets one. Each card has two lines, for example "Arno's army, about 30,000" above "Marching on Tsaren · reported three days ago". A card carries:
  - the noun by size and era: band, war party, host, great host, army before print; regiment, army or corps with powder; battalion, brigade, division, corps and army with rifles;
  - the strength rounded as a clerk would say it;
  - the general's first name (a placeholder staff is never named);
  - what the force is doing, from its status and the staff's own notes, said plainly: "marching on Tsaren", "marching west", "going after Cedar League", "holding the line, asking for help", "laying siege", "falling back home";
  - its wear ("worn", "badly mauled");
  - the report's age, only from two days old.
- **Their marks** come only from dated sightings: the hostile ones seen now and recently, and strangers in sight. They sit exactly where the host was seen. A mark fades with the sighting's age, never below a third. From 20 days it is ringed with dashes, as the front's stale stretches are. Before writing, strangers are left to the feud marks, and only a general's own dated sightings (the Alderford board) are marked.
- **Clicks.**
  - A click on our mark still selects the army, through the chart's own hit test (`mark_at`, used by `local_terrain`), and opens the general's note.
  - A host in sight opens the contact card as before.
  - An older sighting opens a note about what was seen.
  - The general's note now reads "Leads an army of about 6,000, marching west", and "The last runner came three days ago".
- **The 3D labels** that remain (close view only) and the presentation's aggregate labels use the same plain words. `counter_strength`, "LAST REPORT", "6.0K", "READY 78%" and "CLICK TO INTERCEPT" are gone.

### Cost

Measured on the real renderer with the round-two fixture:
- **Draw:** a full draw with five armies, six sightings, two battles, a siege, zones and cards took 2.8 ms with the camera still (3.2 ms before). There were 0 redraws over 120 still frames. While easing, the worst draw was 5.7 ms.
- **Baking:** each mark texture bakes once, in about 6 ms at 64 px (`_render_boxed` evaluates each stroke only inside its bounds). The 35 kinds and branches together took under 0.25 s headless.

### Captures (real renderer, not committed)

The fixture gives two armies named generals, puts one army's runner three days behind, and selects one army.
- `mature_*_before`: round-two code.
- `mature_regional_after`, `mature_local_after`, `mature_continental_after`: the new marks and cards.
- `mature_early_local_after`: the raid age with spear tallies.
- `mature_modern_local_after`, `mature_modern_regional_after`: rifles and armour as staff boxes with echelon strokes.

### Tests

- `tests/test_army_marks.gd` (13 cases): nouns by size and era; marks by era; strength rounding; report age; plain doing words; jargon-free cards across every age, size and age of report; presentation labels at every band and stage; screen-space size; stacking and card budgets; giving way to the front and army groups; bounds; observation honesty and fading; selection and notes.
- `test_warfare_map_presentation.gd` and `test_war_map_marks.gd` now expect plain words.
- `warfare_map_runtime_probe` checks that no 3D counter geometry survives, that the chart draws the mark at its band size, and that clicking it selects the army.

### Limits

- **Terrain features are not named yet.** "Holding the ford" needs a terrain-feature lookup; the card says "holding at <place>" or "holding its ground".
- **Enemy wear** is shown only in the presentation labels, not yet on the chart's cards.
- **At continental zoom, city cards sit above the war ink.** Marks of forces standing at a town can hide under its card, which is the layering round two chose.

## 10. What the air and sea war costs (`scripts/air_naval_consequences.gd`)

Branch `codex/air-naval-consequences`. Consequences run in the live world model through each civilization's own systems.

- **Blockades reach the blockaded.** `civilization_joint_contact.share_sea_pressure` mirrors each fleet's blockade into the target's own ledger every day (entries marked `mirrored`, keyed by the target's city). The target's fish, sea trade (`civilization_exchange` budget), field-army supply and its own harbour on the map read it.
- **Commerce raiding.** Raiders with zones near a people's ports cut its sea trade by at most half, blunted by its convoy escorts, and drown a few merchant crews. Both sides get one plain event.
- **Striking towns.** Bombing, port strikes and shelling from the sea need the ruler's word: the Court for the human (`naval_bombardment` is a new restricted practice), a council decision for a rival (`MilitaryCampaign.record_ruler_decision`, refused in the human scope). Without it, bombers hold and ships fire only on defences.
- **The cost to a struck town.** Deaths are bounded by era (early aircraft, heavy bombers, jets, ships' guns). People are driven out when there is another town to go to. Buildings are damaged and stay so until builders repair them; ruins are rebuilt after a year or more. Stores burn, fear rises, and cohesion and morale fall. The grudge and war-weariness land on both sides. Zone tactics change a raid's weight.
- **Crews.** Crews of lost ships and aircraft are killed, wounded, rescued or captured, by branch, era and whether they came down over home. Hits short of a loss wound crews too. The wounded recover in the service's pool (counted in its strength), prisoners reach the captor, and crews short after hits are made up at base.
- **Defences and carriers.** Guns and walls over a target bring down raiders (at most 0.7% of a wing a day). Close-support aircraft over a battle take ground fire. A sunk carrier takes most of its wings, and an overloaded deck loses the overflow. Interceptors hunt air transports.
- **Landings.** An invasion convoy fights an opposed landing on arrival. Naval and air support lower its cost, and a beach held too strongly throws it back.
- **Repairs.** Struck airfields (weeks) and harbours (months) are repaired for materials and builders; one knocked out is rebuilt.
- **Commanders.** Admirals and air commanders are HistoricalFigures with the realm's own names. They gain renown, and can fall, be wounded or be taken when their ships go down.
- **Record and Chronicle.** Air and sea losses reach each war's record monthly and raise war exhaustion. The Chronicle tells big sinkings, bad days in the air, bombed towns and drowned transports, and folds the rest into the year's entry.
- **Rivals.** At war, rival commanders aim zones at known enemy towns, harbours and fleets, and can order landings. They obey their own ruler's decision.
- **Tests.** `tests/test_air_naval_consequences.gd` covers these in the live model, including a three-year two-civilization war check.
