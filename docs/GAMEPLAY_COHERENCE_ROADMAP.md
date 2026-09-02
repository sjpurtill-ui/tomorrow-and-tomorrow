# Gameplay Coherence Roadmap

This document is the integration contract for the queued design work. A feature is not complete merely because its screen exists; its simulation, information flow, costs, AI rules, presentation, save format, and scale behavior must agree.

## Non-negotiable world rules

1. **People are quantities.** Population, workers, researchers, recruits, troops, casualties, migrants, dependents, and prisoners are aggregate conserved numbers. Population growth must not increase record, node, pathfinding-agent, or draw-call counts.
2. **State is not knowledge.** The simulation may know the planet and every polity. The player sees only locally observed information and reports that physically returned to an owned settlement.
3. **Contact is not location.** Seeing a foreign person or formation can identify a polity and mark an encounter site. It does not reveal that polity's settlement, territory, population, score, forces, intentions, or total number of civilizations.
4. **Messages travel.** Scouts, diplomats, trade proposals, treaties, declarations, orders, and intelligence move at the speed available to people and transport in that era. Effects and reports occur on arrival or return, never at button press.
5. **Every contender pays.** Player and computer civilizations use the same demographic, food, labor, material, research, military, diplomatic, victory, and collapse rules. AI may choose automatically; it may not receive free outcomes.
6. **Progression changes possibility.** Discoveries unlock concrete understood mechanisms and capabilities. Research emphasis changes which possibilities become likely. The graph contains thousands of seeded routes, but active and saved records remain bounded.
7. **Strategic scale replaces literal detail.** A settlement, army, front, resource basin, production network, and urban region are bounded aggregates whose visuals refine or batch by zoom. Billions of people never produce billions of objects.
8. **The UI answers decisions.** Persistent chrome shows only urgent state. Actions open compact modals. Every number or label must answer what happened, why it matters, what is known, how certain it is, and what the player can do next.

## Coordinated workstreams

| Workstream | Required playable result | Scale boundary | Verification gate |
|---|---|---|---|
| Population and economy | Cohorts show productive, supported, mobilized, absent, and dependent shares; food and material ledgers show consumers and expeditions without duplicating unrelated panels | Fixed cohort and ledger categories | Conservation tests at founding and billion scale |
| Discovery and society | Player allocates aggregate researchers among broad inquiries; each completion names a concrete mechanism, evidence, capability, and social consequence; values and institutions evolve | Thousands of deterministic candidate routes, bounded active projects/history | Seed variance, concrete-text, allocation, save-size, and modern-horizon tests |
| Exploration and knowledge | Fog clears through local lookout or returned travel; a compact world map records reports, encounter sites, confirmed settlements, and current nearby sightings | Fixed discovery mask and capped reports/routes | No reveal before return; no unknown polity leaks |
| Diplomacy | Envoys require a confirmed destination, consume provisions/gifts, take real travel time, and return with bounded observations and a charted route | One active aggregate mission plus capped history | Encounter is not destination; no treaty/info before arrival/return |
| Competition and AI | Rival civilizations grow, research, choose focuses, trade, defend, fight, score, win, and collapse under the same rules | Fixed active polity records and relation graph | Player/AI parity and billion-scale turn-cost tests |
| Military | Research drives training, equipment, doctrine, formations, armies, fronts, and production; armies receive movement orders to known destinations; wars are named and record military/civilian losses | Aggregate formations/fronts and capped war history | Manpower/equipment conservation, unknown-map gating, war-history tests |
| Settlements and territory | Convoys found settlements through an action and clear land-selection mode; organic borders grow by travel, work, terrain, water, and institutions; conquest and occupation are legible | Persistent aggregate plots/regions with altitude batching | Plot/region count caps, border continuity, capture/occupation tests |
| Map and architecture | Rivers provide local freshwater/access effects; recognized resource overlay is optional and defaults on during settlement placement; culture changes spatial grammar and batched appearance | LOD meshes/material batches, never one building per person | Visual bounds/capture and population-independent render-count tests |
| Interface and reports | Header is compact; World Strategy, Materials, Population, Council, and Inquiry default to summaries with drill-down modals; notifications are deduplicated and actionable | Capped queues and virtualized/bounded lists | Signal-to-noise, bounds, and legibility capture tests |

## Information ladder

```text
unknown world
  -> nearby unidentified movement
  -> direct encounter and encounter-site marker
  -> returned account identifying a polity
  -> returned investigation locating a settlement
  -> envoy/scout observations producing bounded estimates
  -> repeated visits, trade, records, and institutions improving confidence
```

No later rung may be inferred merely because an earlier rung exists. Stale reports remain historical knowledge; they do not become live tracking.

## Performance budget

- No loop or collection may scale with individual population.
- Candidate discoveries are generated/indexed deterministically; only bounded active selections and history are advanced.
- Rival strategic simulation advances on coarse turns; only current local formations and missions need finer updates.
- Map fog, borders, settlement morphology, and resource overlays use fixed-resolution masks, capped geometry, instancing, and altitude-dependent batching.
- Histories, reports, events, wars, missions, routes, occupations, and notifications have explicit caps and JSON-safe validation.

## Integration order

1. Enforce information and travel gates at the simulation API, then reflect them in every button and panel.
2. Connect aggregate population allocation to food, materials, research, military, expeditions, and AI choices.
3. Make each competitive action playable from preparation through visible consequence and history.
4. Simplify the default interface and move detail into decision-specific modals.
5. Prove identical record/save-size classes at founding and billion population, then run visual capture and cross-system regression suites.
