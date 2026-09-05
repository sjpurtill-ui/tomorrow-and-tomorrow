# Full Chat Queue Audit

This is the acceptance ledger for the full design queue. A requirement is complete only when simulation rules, player knowledge, AI parity, UI access, bounded persistence/rendering, and regression coverage agree.

Status vocabulary:

- **VERIFIED** — implemented and exercised by a named test/probe.
- **PARTIAL** — a playable path exists, but at least one requested consequence or presentation is incomplete.
- **MISSING** — no coherent playable path exists yet.
- **SUPERSEDED** — a later explicit request replaced the earlier presentation, while preserving its underlying mechanic.

## Scale, population, and economy

- Population is aggregate numeric state at every scale; no individual-human entities.
- Population quantities ripple through labor, support, dependency, research, expeditions, diplomacy, military service, casualties, settlement founding, production, and food.
- Founding, million-person, billion-person, and full-planet states remain the same bounded record class.
- Food reporting identifies daily consumers separately from scout, diplomat, military, and settlement-convoy withdrawals.
- Longer expeditions pay more provisions at departure and remove their aggregate people from available functions.
- Rivers and drainage are real freshwater/access inputs; they are not represented as arbitrary water dots.
- Materials and logistics remain aggregate and readable at settlement, regional, continental, and planetary scale.

## Discovery, research, and society

- Broad inquiry is uncertain, but every completed discovery names a concrete mechanism, evidence, capability change, and social consequence.
- The seeded possibility space contains thousands of outcomes through modern maturity without exposing a deterministic checklist.
- Aggregate researcher allocation and emphasis shape discovery throughput and civilizational path; population alone grants no capability.
- Completed lines redirect researchers automatically rather than generating permanent micromanagement alerts.
- All twelve civilizational dynamics progress toward modern, full-planet capacity.
- Values evolve from founding focus, material history, institutions, organization, and adopted forms.
- The player chooses an adjustable founding focus; every AI civilization chooses under the same rules.
- Societal values alter architecture and spatial practice without storing a literal building for every person.

## Fog, scouting, observation, and intelligence

- A new game begins isolated on a huge planet; no immediate forced first contact.
- The map is hidden outside locally observed ground and returned traveler/scout charts.
- Scout information remains physically with the party and becomes player knowledge only after return.
- Encountering a formation or scout can identify a polity and encounter site without revealing its home, population, forces, score, intent, territory, or the world's polity count.
- Nearby foreign formations are visible only while in lookout range; departed formations become stale historical sightings, not live tracking.
- Returned contact reports support targeted area investigation and settlement observation once a home is actually located.
- Scouts may return with small aggregate recruit groups.
- Scouts are fast/stealthy but can be killed or seized; seizure supports questioning, coercion, and unreliable torture with consequences.
- A compact world-discovery map records returned routes, encounter sites, confirmed homes, and bounded current sightings.
- Contact-site annotations are transient/selectable information, not permanent giant world labels.

## Diplomacy and information travel

- Contact is not a diplomatic destination; diplomats require a confirmed foreign settlement and a known route.
- Diplomatic missions consume real people, provisions, and any selected gift.
- Trade, non-aggression, peace, aid, and other proposals travel at era-appropriate speed.
- Unilateral declarations take effect on arrival; bilateral agreements take effect only after an accepted reply returns.
- Diplomatic observations, route knowledge, history, and intelligence arrive only when the delegation returns.
- Diplomats bring bounded information about the visited society as well as the negotiated reply.
- AI diplomacy obeys the same travel and knowledge rules.

## Competition, scoring, and rivals

- Other civilizations grow, allocate population, research, organize, train, produce, trade, fight, win, and collapse under the same rules as the player.
- Unmet civilizations, their count, rankings, and global standing remain unknown.
- Contact does not reveal a universal scoring ontology; comparison improves only through records, concepts, and sustained intelligence.
- Victory and defeat use identical sustainable gates and time requirements for player and AI.
- Rival strategies and founding focuses produce divergent strengths from equivalent inputs.

## Military, defense, war, and conquest

- Settlement defense has material upgrades, damage, repair, home-ground effects, and fixed-size state.
- Training choices improve personnel, formations, commanders, command institutions, readiness, and doctrine while spending real time/resources.
- Research drives available unit types, equipment, ammunition, production lines, organization, and modern HOI-style fronts.
- Trained personnel form bounded armies; armies receive physical movement orders across known geography.
- Home reserves cannot teleport into a distant campaign; an offensive requires a formed field army at its objective.
- Foreign formations can be observed on the map under the same lookout/fog rules.
- Wars are named and recorded; history separates military deaths, wounded/captured personnel, and civilian casualties.
- City/region takeover proceeds through explicit fronts, capture, occupation, resistance, integration, relief, recapture, and peace leverage.
- Conquest changes control of existing strategic regions rather than manufacturing duplicate territory or population.

## Settlements, borders, convoys, and territory

- The original founding expedition becomes a settlement; its UI no longer calls an established settlement a convoy.
- New settlements are founded through a paid aggregate convoy launched from Actions.
- Land selection is temporary and explicit; the authoritative model rejects uncharted land, disconnected returned charts, water, existing claims, early completion, and destination diversion.
- Founding convoy travel time is physical and distance-bounded; population, provisions, timber, and fiber are committed once.
- Settlement borders grow organically from population, work, routes, terrain, water, logistics, defense, institutions, and maturity.
- Border geometry, access axes, settlement count, and occupied strategic regions have explicit world-scale caps.
- Settlement hit-testing uses the actual bounded polygon, not a misleading circle.

## Map, rendering, architecture, and controls

- Terrain supports close settlement detail through continental/planetary strategic scale without per-person or per-building growth.
- Settlement morphology uses bounded plots, fixed mesh/material batches, LOD, culling, and aggregate symbols.
- Resource view is a lower-right toggle, defaults on during settlement targeting, and shows only recognized resources.
- Rivers remain continuous map features and are never rendered as freshwater deposit dots.
- Resource occurrences cluster and cap at world scale; active supply nodes receive priority.
- Each civilization's architectural grammar derives from values and can visibly diverge without increasing record/draw-call class.
- Camera movement and zoom direction are intuitive and consistent with the visible world.

## Interface and signal-to-noise

- Persistent header chrome is compact; detailed systems open in bounded modals.
- Contextual helpers appear wherever a player can reasonably be confused: first-use guidance, concise tooltips, empty-state explanations, inline term definitions, disabled-action reasons, and a clear next step. Helpers remain compact, dismissible where appropriate, and never become notification spam.
- Found settlement, send scout, and send diplomat live under Actions rather than permanent fixtures.
- The retired Lens is not constructed in ordinary play; recognized resources use the resource view.
- Population view communicates productive/support/dependent/mobilized/away roles with useful color and does not duplicate food information.
- Council deduplicates routine reports and separates observations from decisions.
- Inquiry cards explain what was found, evidence, why capacity changed, social effect, and capacity effect.
- World Strategy includes a mini discovery map and uses progressive disclosure instead of a wall of scores, regions, locks, and omniscient detail.
- Materials presents aggregate extraction, transit, delivery, storage, workforce, and bottlenecks without settlement-scale clutter at continental scale.
- First-contact and unit-sighting events are announced, actionable, centerable, and dismissible.

## Final gates

- Headless editor/autoload parse.
- Actual main-scene startup.
- Full GdUnit suite.
- Economy, food, resource, population, discovery, society, military, strategic-region, civilization-scale, UI, and Council probes.
- No whitespace errors or stale references to retired systems.
- Normal game launches for an interactive playthrough without interrupting the audit.
