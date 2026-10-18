# All-screen visual audit and proposals

October 18, 2026 · source baseline `2a2fc5c9c5d0324c524f070716ae2f7447281282`

## Decision

Make each screen show the relationship the player is deciding about. Trade's **WE NEED / THEY CAN SPARE** is the reference: recognizable things, aligned quantities, and a visible gap. Apply that to resources, construction, workers, research, armies and political influence. Another stack of paragraph-filled cards would repeat the same problem.

This document proposes changes; it does not declare the proposed redesign implemented. The Trade comparisons and household identity correction are integrated separately. The standing visual rule is saved in [AGENTS.md](../AGENTS.md#visual-game-ui--standing-user-preference).

## Coverage and confidence

Audited the current navigation, its content providers and renderers: Home, Economy, Buildings, Research, War, World and Chronicle, plus health, court, map details, collections, orders, founding and utility overlays. Navigation comes from [command_rail_hud.gd](../scripts/hud/command_rail_hud.gd) and provider registration in [local_terrain.gd](../scripts/local_terrain.gd). The production provider's third Military entry is a hidden compatibility alias, not evidence of a second visible Military tab. Legacy appointment/council helpers are not automatically counted as current screens merely because their files remain.

**This is an implementation/source audit informed by the user's screenshots and feedback.** The revised Trade widget was also rendered and inspected offscreen. This pass did not navigate every screen in a running campaign or validate every late-game state. Earlier screenshots describe the problems and priorities; they do not prove the latest source still renders identically. Where an existing screen already has useful visuals, the proposals preserve them.

P0 = correctness or interaction that blocks understanding/actions. P1 = primary gameplay redesign. P2 = secondary comparison, archive or utility polish. Priorities describe proposed work, not newly confirmed runtime bugs.

## Proposed implementation order

| Batch | Deliverable | Player should immediately understand |
|---|---|---|
| 0 | Trustworthy controls and scope | Which town this affects; who controls allocation; why an action is unavailable; whether a click worked. No control moves under the pointer during play. |
| 1 | Buildings, every storage class, Food and Materials | What is missing; how much fits; what will be lost; which build or exchange closes the gap. |
| 2 | People and production | Where the people are; the effect of moving some; which input limits a line and by how much. |
| 3 | Research and longevity | What research unlocked, what is actually being used, and the last three discoveries' real effects. |
| 4 | Households, families, Culture and public spending | Who wants what; who gains/loses; actual bonuses, costs and cultural direction. |
| 5 | War, World and expeditions | Manpower and supply limits; actual fronts; known versus uncertain information. |
| 6 | Archives, collections and settings | Find a record or control without reading a page of prose. |

These are presentation batches using existing systems unless a row explicitly calls for new instrumentation. Do not add a new economic or military subsystem to make a diagram look richer.

## Visual vocabulary across the game

| Question | Use | Avoid |
|---|---|---|
| Do we have enough? | Named resource icon; **need / available / missing**; comparable bars sharing a unit and scale. | A paragraph describing a shortage; a total that adds unrelated materials. |
| Is there room? | Filled capacity bar, reserved space if recorded, incoming cargo, overflow quantity, adjacent expansion action. | A storage warning without a way to resolve it. |
| Where does it go? | Source → store → use, with quantities per day or per season explicitly stated. | Unlabelled arrows or mixing stocks and daily rates. |
| What changes if I act? | Current → proposed paired readings; costs beside gains; one blocker next to the action. | Long tooltips carrying the only meaningful consequence. |
| Who is assigned? | One population allocation strip, direct controls, a clear selected mode. | Multiple implied manpower pools; unexplained automatic overrides. |
| What is progressing? | Compact production/research lanes, pips for assignments, progress and rate as separate readings. | Giant item descriptions as the default working view. |
| What happened? | Timeline or cause totals, then one selected account. | Every event's full narrative expanded at once. |
| What do they believe/want? | Portraits, relationships, paired value markers and actual effect chips. | An invented single influence score hiding distinct causes. |
| How certain is it? | Report date, source and unknown/estimated markers next to the number. | Showing unobserved rival state as exact intelligence. |

Names accompany icons; labels accompany color. Keep typography readable while reducing oversized headings, padding and repeated labels. Use bounded grids, search and pagination for large collections. Direct visible choices replace primary gameplay dropdowns; do not replace a dropdown of hundreds of items with hundreds of permanently visible buttons. Narrative belongs in the selected story, character conversation or precise decision confirmation.

## Global interface and Home

| Screen/surface | Current finding | Proposal | Priority |
|---|---|---|---|
| Map, thin sidebar and top bar | Compact rail and population readings exist; town and zoom selectors remain. Scope can become hard to infer when switching town details. | Keep the thin rail and small icons. Always show population with an explicit town/realm scope. Keep essential food, water and storage risk readings stable. Four zoom levels become a small visible segmented control; towns are selected on the map or in a bounded town tray. | P0/P1 |
| Live refresh, throughout | Several boards retain view state; Inquiry explicitly returns false from `update_block`, allowing recreation. Source alone cannot establish whether every board loses focus or jumps. | Update numbers/bars in place. Preserve selected item, scroll, keyboard focus and pointer targets. Delay sorting while a person interacts. Run a click-and-scroll check at fast time on each screen. A changed estimate must not erase or swallow an allocation click. | P0 |
| Home → Overview | Already has town art, coverage bars, infant-survival dots and trends. Work selection still uses an OptionButton; some comparisons remain prose. | One compact overview: food/water/shelter/care coverage, population change and three actionable pressures. Keep the town illustration and survival dots. Show shelter places versus residents and current → proposed effects alongside direct care/work actions. Replace the work selector with visible project icons. | P1 |
| Home → People | Direct work-area buttons, manual/leader control and estimates exist. Prior user reports include non-working allocation and “estimate unavailable.” | One workforce strip reconciled to the population ledger; all work areas below with count and direct ± controls. A proposed move highlights donor and recipient, then previews food, care and other measured changes. Manual/automatic mode is unmistakable. Show an exact estimate failure reason without silently disabling a valid allocation action. | P0/P1 |
| Home → Culture | Existing bonus tiles and historical ribbons are useful. An OptionButton hides all but one societal value. | Show the value axes together as paired **official position / lived practice** markers. Selecting one reveals the cause and family pressure. Keep actual bonuses separate from tendencies with no current effect. Retain the history ribbon. | P1 |

Sources: [home_lives_view.gd](../scripts/hud/home_lives_view.gd), [people_allocator_screen.gd](../scripts/hud/people_allocator_screen.gd), [culture_panel.gd](../scripts/hud/culture_panel.gd), [inquiry_board.gd](../scripts/hud/inquiry_board.gd).

## Economy and production

| Screen/tab | Current finding | Proposal | Priority |
|---|---|---|---|
| Food and water | Illustrated pantry, reserve headline, trends, daily flow and storage controls already exist. Several readings require mentally combining separate cells. | Show **gathered/imported → stored → eaten/spoiled/exported** with aligned rates. Water gets its own source → carrying → households comparison. Put reserve runway and capacity beside each other; label forecast assumptions. Keep the existing trend. | P1 |
| Materials | Stockyard art, paged inventory, selected item details, carrying information and seven storage expansions exist. | Inventory tiles show stock, committed, free and capacity where those measures exist. Select timber and see **incoming → store → building/workshop demand**. Carrying bottlenecks and storage overflow appear next to the relevant flow. | P1 |
| All storage, across screens | Repeatable expansions now exist for seven classes; visibility and connection to the next build still need consistent treatment. | Use the same capacity tile everywhere: stored/capacity, incoming, loss risk, expansion cost and added capacity. **Expand / Build first / Assign builders** sit with the relevant store, showing queue position and blockers. Show the automatic expansion request's actual status. Never treat food as the only storage system. | P1 |
| Wealth and public purse | Account balances, selected records, constraints and stage-dependent behavior exist; abstraction can obscure what spending buys. | Separate physical reserves from currency accounts. Show each funded service's cost beside its actual coverage/effect and unpaid gap. Compare current spending with a proposed change. Early play should lead with useful goods and needs, not a meaningless wealth total. | P1 |
| Trade | Integrated named GIVE/RECEIVE loads, visible partners, cargo legs, needs/spares and coverage tiles are a useful foundation. Policies can still crowd the screen at maturity. | Keep the paired resource comparison as the main view. Add a compact route/cargo progress strip and **shortage before → after delivery**. Group policy controls by the selected partner without hiding the exchange. No-offer state should pinpoint the failed condition: no surplus, full store, no carrying capacity, or terms blocked. | P1 |
| Military production | Current implementation already has dense simultaneous production rows. It should not regress to the large catalog description shown in the user's older screenshot. | Refine the HOI4-style working row: equipment image/name, assignment pips, input coverage, efficiency, output rate, stock/target and priority controls. Show the resource penalty numerically and the actual stop threshold. Product description belongs in selection/detail. | P1 |
| Civilian production | Progress, stocks, targets, bottlenecks and receipts are separate existing readings. | Use the same compact row structure with a persistent Military/Civilian switch. Inputs → output, workers, rate and stock target stay in the row. Include purpose: building supply, household use or export. Avoid a fictional generic-goods benefit. | P1 |
| Production catalog, line details and output history | Catalogs and optional history can still grow into description-heavy secondary screens. | Bounded equipment/product grid; costs and functional result visible on each choice. One selected line shows efficiency history and losses. History leads with output totals and a short timeline, then paged receipts. | P2 |

Sources: [food_folio.gd](../scripts/hud/food_folio.gd), [materials_ledger.gd](../scripts/hud/materials_ledger.gd), [wealth_ledger.gd](../scripts/hud/wealth_ledger.gd), [purse_board.gd](../scripts/hud/purse_board.gd), [trade_board.gd](../scripts/hud/trade_board.gd), [production_queue.gd](../scripts/hud/production_queue.gd), [production_board.gd](../scripts/hud/production_board.gd).

Resource-penalty presentation must read the actual simulation formula. This audit does not certify exact HOI4 parity or propose changing the formula without a separate mechanics check.

## Buildings

| Tab/detail | Current finding | Proposal | Priority |
|---|---|---|---|
| The Town | Existing board has selected work, real costs/effects and direct actions; its section choice is a dropdown. Some housing gains become prose. | Visible category chips and a compact town diagram. Select a work and compare **cost have/need** beside **capacity now/after**. Show builder assignment and the next queued work in one narrow lane. Housing gains become places added, not sentences. | P1 |
| Civic Works | Shares the work-board structure; the purpose of a project must compete with detailed readings. | Building icon grid with actual benefit badges, prerequisites and missing materials. Selecting one pins the bill and outcome; all primary actions remain visible. | P1 |
| Infrastructure | Map-linked networks and defense information sit alongside project readings. | Draw endpoints and relevant routes; compare carrying demand/capacity on the selected link. Show a border fort's location, area served and real effects explicitly. Verify the rejected town-watch effects are absent before exposing them as benefits. | P1 |
| Landmarks and Great Works atlas | Separate landmark/atlas views already exist; atlas has a watch-pace selector. | Preserve the atlas and artwork. Show construction stages, staff, material gaps and actual unlocked effects. Direct pace chips if there are only a few modes. Distinguish current progress from an uncertain completion forecast. | P2 |
| Construction queue and building ledger | Detailed histories and material records remain useful but are naturally dense. | Compact queue lanes with material gaps and builder demand. Built history becomes a silhouette timeline with totals; select one building for its account, material bill and effects. | P2 |

Sources: [dock_content_construction.gd](../scripts/hud/content/dock_content_construction.gd), [buildings_board.gd](../scripts/hud/buildings_board.gd), [great_works_atlas.gd](../scripts/hud/great_works_atlas.gd), [dock_detail_building_ledger.gd](../scripts/hud/content/dock_detail_building_ledger.gd).

## Research, health and population records

| Tab/detail | Current finding | Proposal | Priority |
|---|---|---|---|
| Work under way | Illustrated investigations and bounded active fields exist. Waiting fields are selected through a dropdown; rebuilding remains a refresh risk. | Three compact investigation lanes: question/art, teams, evidence progress, known blocker and result. Waiting fields are an icon strip with bounded paging. Select a lane to see precise effects. Retain controls while time advances. | P1 |
| Explore knowledge | A dependency view exists, but field/status selectors hide choices. | Visible field icons and state chips around a bounded connected branch. Pin selected discovery effects and prerequisite icons. Search jumps to the relevant branch; do not render thousands of nodes at once. | P1 |
| What we know | Archive filters and individual records can dominate the player-facing summary. | Lead with aggregate unlocked bonuses by additive category, displayed together without a dropdown. Then show the **last three discoveries**, each with a functional effect badge. Full archive is a deliberate secondary view. | P1 |
| Health → Lives | Trend, discovery markers, aggregate research readings, care and recent discoveries exist. The relationship between unlocked knowledge and realized benefit is still the central question. | Pair **unlocked research benefit / benefit currently delivered** where the model supports both. Show conditions blocking delivery. Keep the longevity trend and last three discoveries. A selected marker explains recorded effects without claiming the whole subsequent lifespan increase was caused by that discovery. | P1 |
| Health → Sickness & disasters | Newer implementation already has decade totals, annual death columns, six event selectors and one selected account. | Keep that structure. Add compact sick/dead/displaced/resource-loss pictograms to the selected event. The story is optional detail; do not restore the old stack of fully expanded accounts. | P2 |
| Population ledger → Overview | Numeric records can require reading multiple rows to reconcile change. | Births + arrivals − deaths − departures = population change. Add an age/cohort view only if the current ledger exposes reliable cohorts. No synthetic demographic precision. | P2 |
| Population ledger → Every death | A manual archive is useful; automatic routine announcements are unwanted. | Searchable compact records and cause totals. One selected person's account. Ordinary deaths remain quiet; executions retain the requested notice behavior. | P2 |
| Capacity/history and settlement-people details | Specialized readings expose histories and breakdowns outside the primary screen. | Reuse the same units, scope and comparison from the parent screen. One trend and its actual components; no second incompatible “capacity” total or duplicate Daily work label. | P2 |

Sources: [inquiry_board.gd](../scripts/hud/inquiry_board.gd), [knowledge_tree_board.gd](../scripts/hud/knowledge_tree_board.gd), [health_dashboard.gd](../scripts/hud/health_dashboard.gd), [hardship_dashboard.gd](../scripts/hud/hardship_dashboard.gd), [dock_detail_population_ledger.gd](../scripts/hud/content/dock_detail_population_ledger.gd), [dock_detail_capacity.gd](../scripts/hud/content/dock_detail_capacity.gd).

“Research adds X years” is allowed only if the ledger actually attributes that quantity. Otherwise show the real additive categories and their units. A discovery marker is an event marker, not proof of causal attribution.

## Court, families and society

| Surface | Current finding | Proposal | Priority |
|---|---|---|---|
| Early household court | Skill-derived titles such as Pathfinder survived in the fallback identity. That fallback is now corrected to actual households and wants; a full visual court redesign is still pending. | A small gathering of recognizable people/households. Portrait, name, one desire and one consequential request. Early visitors should arise from the settlement's actual needs and scale, rather than presenting a cabinet of offices. | P1 |
| Major families | `court_families_panel.gd` contains a family selector beside a long details column: constituency, loyalty, rival, program, values, bonuses, funding and trade. This is a strong remaining example of the rejected text-list design. | Portrait/crest chooser; selected head at center; **program gains / drawbacks / cost** on one comparison board. Show their rival nearby and the actual cultural direction. Keep wants/fears and one characteristic line of dialogue; full narrative stays in conversation. | P1 |
| Family evolution and parties | Source already tracks stages, population thresholds and organization time. | A compact maturity path: favored trade heads at 10k → competing influence at 100k → political families at 500k → nascent parties at 5m → full parties at 20m. Show organization requirements as well as population eligibility. Large party views aggregate constituencies and retain the founding families behind them. | P1 |
| Favor, endorsement and funding | These actions have different effects; long text currently explains the distinction. | Adjacent visible actions, each with its own before/after preview. Favor shows support/rival reaction; endorsement shows actual bonuses/deficits; funding shows cost and delivered service. Workforce allocations remain unchanged. | P1 |
| Audience, diplomacy and orders | Conversation is appropriate here, but several action/person/city choices remain dropdown-driven. | Select a visible person/target and an action icon, then show a compact decision receipt: target, costs, immediate effects, stated odds and possible outcomes. Keep confirmation for consequential actions. AI speaks from the adjudicated facts; it does not invent outcomes. | P1 |
| Family values and Culture connection | Personality, official values, public acceptance and lasting traditions are distinct existing concepts. | Selecting a head highlights the affected Culture axes. Show current official/lived positions and measured direction, with recent reasons. No decorative arrow claiming a numerical prediction that the engine does not calculate. | P1 |

Sources: [audience_modal.gd](../scripts/hud/audience_modal.gd), [court_roster.gd](../scripts/hud/court_roster.gd), [court_families_panel.gd](../scripts/hud/court_families_panel.gd), [major_families.gd](../scripts/major_families.gd), [culture_panel.gd](../scripts/hud/culture_panel.gd). Mechanics constraints: [ADJUDICATION.md](ADJUDICATION.md).

The court should not expose the old appointments system under new headings. Internal civic service ownership can remain necessary to the simulation while the player interacts through households, families and parties. Strong personalities should follow actual wants, fears and era circumstances; humor belongs in their voice, not invented mechanical benefits.

## War and military overlays

| Screen/surface | Current finding | Proposal | Priority |
|---|---|---|---|
| War → Army | Existing army overview covers manpower, guard, readiness and costs. Selectors and cost detail can separate related limits. | One reconciled chain: **People allocated to Defense → available / at home / in the field**. Equipment coverage and readiness are separate. Show the actual foraging capacity against army need, with the extra supplies required above it. | P1 |
| War → Fronts and map armies | Existing map-focused front presentation is the right location. This source audit does not certify all marching, deployment, flanking or penetration animations. | Preserve marching columns that spread from the head into a V, then form fluid opposing fronts. Small forces use blobs. Both sides cover the front; weaker sectors are thinner. Losses visibly reduce mass. Flanks and a penetration splitting a front must reflect actual combat state. No separate zoomed-in battle arena. | P1 |
| War → Leaders and command hierarchy | Leader/formation/town/mission selectors remain in command views. | Portrait hierarchy beside the map; direct objective choices and map targets; named commander, committed manpower, supply situation and current intent. Generals execute maneuvers. No direct-cohort micromanagement or mandatory logistics forms. | P1 |
| Recruitment/service/force details | Secondary recruitment/service widgets can imply a separate pool unless they reconcile visibly with People. | Display the same Defense allocation and its existing commitments. Equipment and training limit deployment independently. Use direct destination chips/map targets where needed. Verify which legacy detail routes remain reachable before redesigning them. | P0/P2 |
| Siege | Existing briefing stacks own army, enemy, walls, intent and recent events largely as prose. | Put the city on a small contextual map: blocked approaches, wall condition, own supply and reported enemy endurance. Two force summaries flank it. Keep one general-intent sentence and direct conversation/objective actions. Unknown enemy readings remain uncertain. | P1 |
| Battle report | Already compares both sides, followed by tactics, phases, situation and advice as stacked text. | Proportional before/after force bars split by recorded outcomes; compact phase timeline; territory/objective result; one selected phase narrative and the general's advice. Distinguish confirmed enemy losses from estimates. | P2 |
| Occupation/held town | Already has condition bars, but garrison required/available is buried in the lead paragraph. | Lead with **garrison needed / present / supplied**. Keep resistance, welfare, trust, grievances and damage distinct; compact their explanations. Policy decisions go through the proper court/commander path with real consequences. | P1 |
| Recovery | Survivor count, journey progress and food duration are combined in prose. | Map route with survivors, food runway and distance as visible readings. Occupied towns are selectable markers. Show the risk/cost of escape, resistance and resettlement next to each action. Preserve uncertainty and decision confirmation. | P2 |

Sources: [war_board.gd](../scripts/hud/war_board.gd), [command_hierarchy_panel.gd](../scripts/hud/command_hierarchy_panel.gd), [leaders_board.gd](../scripts/hud/leaders_board.gd), [war_front_overlay.gd](../scripts/hud/war_front_overlay.gd), [siege_screen.gd](../scripts/hud/siege_screen.gd), [battle_report_panel.gd](../scripts/hud/battle_report_panel.gd), [occupation_view.gd](../scripts/hud/occupation_view.gd), [recovery_screen.gd](../scripts/hud/recovery_screen.gd). Direction: [GENERAL_CAMPAIGN_DESIGN.md](GENERAL_CAMPAIGN_DESIGN.md).

## World, travel and intelligence

| Tab/detail | Current finding | Proposal | Priority |
|---|---|---|---|
| Peoples | Reported capabilities and selected towns exist; people/sort selectors hide comparisons. | Searchable emblem tray and a selected **ours / theirs** comparison using native units. Town markers link to the map. Every rival number carries its report age/uncertainty. | P1 |
| Known world and rumored contacts | Chart, known places and unconfirmed leads already differ in the data; a lead dropdown remains. | Select leads directly on the known-world chart or a bounded illustrated tray. Visually distinguish seen, reported and rumored. One next action beside the selected lead. | P2 |
| Expeditions and dispatch | Parties, tellings and reports are grouped/paged; origin and target selectors still require menus. | Pick origin and objective on the map, with direct objective icons. Before dispatch show people required, food/foraging, route and ETA. Returning parties contribute compact resource/knowledge/contact findings. Keep the existing bounded report archive. | P1 |
| Standing | Radar, numeric strengths and relationship readings already exist; comparison/people selectors obscure the side-by-side question. | Visible neighbor emblems; aligned paired bars for selected comparisons. Keep radar as an optional overview. Feelings become a compact labelled matrix with changed values and recorded causes. No fabricated single overall standing score. | P1 |
| Spies | Network selector, intensity choices, coverage and trust costs exist. | Network map/tiles showing strength, exposure and personnel. Selected operation compares coverage gained with trust/cost paid. Direct intensity choices and one selected report. | P2 |
| World history | Already a bounded recent/archive selection with one account. | Keep the bounded structure. Link timeline markers to places/peoples; use event icons and concise outcomes. Expand only the chosen story. | P2 |
| Civilization/city/scout/contact reports | Specialized dossiers combine what was seen, where/when, people and accounts. | Consistent report header: subject, place, observer/date and confidence. Actual findings become resource/settlement/army tiles. Observed and held-town states must remain distinct. One account for context. | P2 |
| Community network | Relationship graph is useful; project dropdown and cost/effect paragraph hide the decision. | Keep the graph, add labelled relationship lines. Shared projects become visible tiles with resource bills, work requirement, benefit and the actual research slowdown. Selecting a partner opens the relevant conversation. | P2 |

Sources: [peoples_known_board.gd](../scripts/hud/peoples_known_board.gd), [known_world_board.gd](../scripts/hud/known_world_board.gd), [expeditions_board.gd](../scripts/hud/expeditions_board.gd), [scout_target_picker.gd](../scripts/hud/scout_target_picker.gd), [standing_board.gd](../scripts/hud/standing_board.gd), [covert_board.gd](../scripts/hud/covert_board.gd), [world_history_board.gd](../scripts/hud/world_history_board.gd), [community_network_screen.gd](../scripts/community_network_screen.gd).

## Chronicle, collections and utility screens

| Screen/surface | Current finding | Proposal | Priority |
|---|---|---|---|
| Chronicle → The years | Year spiral, filters and bounded records already provide a visual structure. | Preserve the spiral. Selected year leads with actual population/resource/building changes and event markers; one chosen account expands. | P2 |
| Chronicle → Births and deaths | Narrative records overlap with the need for an aggregate demographic view. | Reuse the population-change flow and cause totals. Person records remain searchable. Do not re-enable routine death popups. | P2 |
| Chronicle → What was built | Bounded recent/archive entries and selected details exist. | Building silhouettes on a timeline; completed capacity totals by compatible category; one selected construction account with material icons. | P2 |
| Artifact gallery | Artwork is already central; sort choice is still a dropdown. | Keep the image grid. Visible sort/filter chips, custody/study badges and one selected object's provenance. Avoid a second wall of descriptions underneath. | P2 |
| Collection exchange | Recipient/wanted/filter selectors hide the actual objects in the exchange. | Two trays: **we give / we receive**, each with the object's image and identity. Select the counterpart by portrait/emblem; show any real knowledge/cultural consequence. | P2 |
| Discovery reader | Appropriate as an intentionally opened illustrated account. | Preserve art and story; keep an effect strip visible. Open manually from research/history, not automatically after every discovery. | P2 |
| Notifications and orders | Routine weakness/death/discovery interruptions have already been suppressed; actionable notices and order states remain. | Keep routine events in records. Compact badges for actual decisions, failures and execution notices. Orders show target, progress, blocker and destination link; expand one receipt. Do not restore Map help as a permanent button. | P0/P2 |
| Founding, travel and naming | Founding site guide already has water coverage, resources and nearby communities. A previous resume observation showed a founding-path choice on an established campaign; the cause is not established here. | Keep site comparisons and map selection. Add visible **settlers' need / site's coverage**. Gate founding-only prompts to the correct state; investigate the resume observation separately. Naming remains a simple field. | P0/P2 |
| Pause/save/load/restart | Menu uses a tall scrolling panel with disclosures; saved-world metadata exists. | Compact visible sections for campaign, display, sound and controls. Save entry shows world/town, date, population and timestamp. Clearly separate Resume, New game and Restart; preserve save/quit confirmations. | P2 |
| Display, audio, map controls and AI connection | Utility controls and status exist; audio quality cannot be assessed from UI source. | A short settings layout with direct preset choices, sliders and immediate status. Audio provides independent controls for available buses and a voice test where supported; investigate the reported hiss with a real recording rather than assuming it is intentional. Keep secrets out of diagnostic output. | P2 |

Sources: [chronicle_feed.gd](../scripts/hud/chronicle_feed.gd), [chronicle_works_reader.gd](../scripts/hud/chronicle_works_reader.gd), [artifact_gallery.gd](../scripts/hud/artifact_gallery.gd), [exchange_collection_panel.gd](../scripts/hud/exchange_collection_panel.gd), [notification_stack.gd](../scripts/hud/notification_stack.gd), [order_stack.gd](../scripts/hud/order_stack.gd), [founding_site_guide.gd](../scripts/hud/founding_site_guide.gd), [game_menu.gd](../scripts/hud/game_menu.gd), [ai_connection_panel.gd](../scripts/hud/ai_connection_panel.gd).

## Rule conflicts and instrumentation to resolve before drawing promises

1. **Border forts:** World still builds a tooltip describing additional visibility from “the watch's alertness”; `home_defense.gd` also references watch labor and defense effects. This is confirmed source language, not proof of which non-fort effects remain active. Trace the actual benefit ledger against the user's border-fort-only instruction. Correct the rule first if necessary, then its UI.
2. **One manpower source:** Every military view must reconcile to People allocation. Check reachable recruitment, home guard, expedition and command paths; do not imply another kind of recruit because an old widget still exists.
3. **Families replace the court presentation:** Household labels are corrected, but the later panel still needs redesign and all reachable conversation/action titles need a runtime check. Do not imply that merely renaming a title completes this replacement.
4. **Research attribution:** Exact marginal longevity contributions and before/after policy forecasts may need new read-only snapshot calculations. Reuse simulation logic; do not create a parallel formula in UI code. Until available, show measured effects and explicit uncertainty.
5. **Production penalties:** Display the actual resource-speed penalty and stopping condition. Verify separately against the requested model before claiming equivalence with HOI4.
6. **Early versus late scale:** Early screens focus on food, shelter, material needs, real visitors and small armies. Later screens aggregate cities, families and parties with bounded representatives. Population thresholds should expose real mechanics, not empty placeholders or an enormous list.
7. **Foreign knowledge:** Use reported state and report dates. “Unknown” is preferable to a precise number read from hidden rival state.

## Acceptance checks for each implemented batch

- At normal window size, identify the screen's subject, current problem and available action without scrolling through explanatory paragraphs.
- Primary decisions use direct visible controls. Large collections stay bounded and searchable. The screen has one clear title; repeated labels are removed or given distinct units/scope.
- At narrower widths and larger text scale, keep numbers, units and actions readable; do not solve density with tiny text or clipped buttons.
- Keep simulation running while changing selection, scrolling and clicking. Focus, scroll and action targets remain stable; changed data cannot silently reset a choice.
- Exercise empty, blocked, shortage, surplus, locked, early-game and large-population states. Disabled actions explain the actual blocker beside the control.
- Compare displayed values against the authoritative ledger, including town versus realm scope. Preview must not mutate state. Actual actions use the same rules as previews.
- Capture and inspect the real rendered screen. Source tests establish logic; they cannot certify visual clarity or interaction during play.

## Delivery boundary

Completed before this proposal: Trade give/receive and needs/spares presentation; direct Trade choices; early household identity/want correction; permanent visual design rule. The four related test suites passed 62 checks with zero errors, failures or orphans. Trade received an offscreen native render review. Full court runtime review and the remaining screen redesigns above are outstanding proposals, not delivered features. No player session was restarted for this audit.
