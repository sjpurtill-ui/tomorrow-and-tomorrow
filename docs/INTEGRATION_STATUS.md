## September 9 — Stone Selection artwork correction

INTEGRATED `786390de07ad031ead4de6185fdd4a7b4d8165fa` by conflict-free fast-forward from canonical Mac `4928607e19e202ab3c978b64c7ce20aff0962980`. Stone Selection now shows people selecting/testing rocks in discovery announcements, research cards, inspector and tree. The old pottery image came from the generic Craft & Industry field assignment; the discovery name and effects were already correct. Other generic illustrations are explicitly labeled FIELD ILLUSTRATION. Hidden subjects retain generic art.

All **29 canonical focused tests pass**, zero errors/failures/skips/orphans (`/tmp/tt-discovery-art-canonical-tests.log`). Native capture-only verification passes Stone Selection and Clay Vessels at 1200 × 900 and 800 × 600, plus research card/tree captures. Artwork, visible labels, exact effects and dismissal controls were inspected; the probe exits. See `DISCOVERY_ART_HANDOFF.md` and `assets/ui/research/PROMPTS.md` for scope and built-in image-generation provenance.

Normal standalone release target **2026.09.09.11** is packaged through `tools/launch_game_macos.py --build-only`; `build.ok` records its integrated source revision. Owned overrides removed. Player PID 74445 remains on 2026.09.09.9, untouched; the updated art requires a normal relaunch. Save schema, simulation effects and human/opponent mechanics are unchanged. This is a specific Stone Selection correction, not individual artwork for every discovery. Landscape iteration remains ACTIVE as recorded below.

## September 9 — landscape iteration 6: climate-driven seasonal cover

INTEGRATED `80c79a2e9ffd940e62d356c8dd83b1869b5624ad` by conflict-free fast-forward from canonical Mac `d07dc6e01b3404ccc70ff40876bdd605ee69c39c`. Ground cover, scrub and woodland now change with the existing climate/calendar temperature. The hemispheres reverse; bare drylands and warm tropical cover retain their appropriate appearance. Material updates leave tree positions, counts, resources and meshes fixed. The HUD now shares food's ambient-temperature model, correcting its separate north-only seasonal calculation. Existing food/profile arithmetic and human/opponent rules are unchanged.

All **64 canonical combined tests pass**, zero errors/failures/skips/orphans (`/tmp/tt-season-canonical-tests.log`). Native capture-only verification passes six actual seeded sites, opposite hemisphere color changes, paused pixel stability, preserved plant identities, exact fog concealment and all four camera distances. Representative seasonal/crown pairs and distance captures were inspected; both probes exit cleanly. Normal isolated headless boot is clean. See `SEASONAL_LANDSCAPE_HANDOFF.md` for exact evidence, performance and remaining limits.

Normal standalone release target **2026.09.09.10** is packaged through the build-only Mac launcher, with the exact integrated revision in `build.ok`. Owned overrides are removed. Player PID 74445 remains on release 2026.09.09.9 and was not interrupted or relaunched. No save schema changes. This delivery adds vegetation dormancy; it does not invent snow, rainfall records or species. Landscape iteration remains ACTIVE: improve natural ground detail, canopy appearance and transitions at real camera distances, preserving physical climate, stable placement, fog and performance.

## September 9 — landscape iteration 5: far-world surface precision

INTEGRATED `bc3b0e248ad401b8408af5eb08b2a036ddffb29e` by conflict-free fast-forward from canonical Mac `149cebf5494e8494dc338c5d42468481a5bff246`. Close ground and water no longer acquire vertical bands from large world coordinates. Pixel filtering uses nearby coordinates; repeating ground/forest textures and fine material noise retain world phase, while water phases are reduced precisely before upload. Actual far-world captures also exposed lost camera yaw near vertical: the camera now derives its orientation directly from the requested angles while retaining its position, distances and clipping planes.

All **59 canonical combined tests pass**, zero errors/failures/skips/orphans (`/tmp/tt-precision-canonical-tests.log`). The camera regression reproduced the old failure before correction. Three native capture-only audits pass analytical filtering and coordinate-shift comparisons, actual far-world drylands/cold barrens/coast, all four camera distances, 48 shoreline checks, GPU bed sampling, distant wave filtering, fog concealment and world-edge clipping. Original and corrected surface captures were inspected; probes exit without errors or camera warnings. Normal headless boot is clean. See `SURFACE_PRECISION_HANDOFF.md` for measurements and limits.

Release target **2026.09.09.9** uses the normal standalone build-only Mac launcher, with the exact packaged revision recorded in `build.ok`. Owned test overrides are removed; no player/editor was interrupted or active at integration. Physical terrain, resources, climate, save schema and shared civilization rules are unchanged. This corrects specific surface/camera errors, not every engine precision limit. Iteration remains ACTIVE: continue natural ground and vegetation variety and seasonal appearance based on actual simulation data.

## September 9 — landscape iteration 4: sampled landforms and continental coasts

INTEGRATED `fe31c00c66ab6bd4271b9f16cd2c1d33afcb00a1` by conflict-free fast-forward from canonical Mac `504be6a2b3c732761ae6ea21bb9278f03ffea485`. Detailed terrain now continues through continental view instead of disappearing above the old 820 km cutoff. Regional/continental meshes sample the actual geography at up to 513 × 513 vertices. Progressive previews, cancellation, complete-mesh installation and a four-entry/600,000-vertex cache bound the work. The previous/global ground stays visible during refinement. Water uses the matching installed bed; terrain stops at the finite planet boundary. Unknown mountains, plains and ocean share one unlit fog veil.

All **54 canonical combined tests pass**, zero errors/failures/skips/orphans (`/tmp/tt-lod-canonical-tests.log`). A physical seed audit improves regional interpolation RMSE from 77.9 m to 11.8 m and reduces incorrect land/water classification from 84 to 37 of 251 coastal samples. Native capture-only checks pass all four actual camera distances, fallback/cancellation, equal hidden pixels and world-edge clipping. Before/after regional and continental captures were inspected; probes exit normally. Normal headless project boot is clean. See `TERRAIN_LOD_HANDOFF.md` for exact sampling, performance and limits.

Release target **2026.09.09.8** uses the normal standalone build-only Mac launcher, whose `build.ok` records the exact packaged revision. Owned overrides are removed; no player/editor was interrupted or active at integration. Save format and all simulation geography, resources and human/opponent rules are unchanged. Full detail still takes seconds to refine behind useful previews, and coastlines remain sampled. Iteration remains ACTIVE: next address close surface precision at extreme world coordinates, then richer natural ground/vegetation and seasonal appearance. This does not claim a finished landscape or all-world visual audit.

## September 9 — landscape iteration 3: physical ground materials

INTEGRATED `e4db83e36587599325c565ebc70b93df76e40089` by conflict-free fast-forward from canonical Mac `150af912814573331020bacb7400bc179dd00598`. The terrain no longer draws an unrelated satellite photograph's mountains over the generated land. Base, regional and close meshes carry actual climate and resource-geology fields; dry earth, damp ground and steep exposed rock use those fields. Woodland/depletion channels remain intact. Fine detail filters with distance, integer hashing avoids distant soil precision artifacts, and coarse normal/hillshade smoothing reduces abrupt lighting facets without changing physical geometry.

All **44 canonical combined tests pass**, zero errors/failures/skips/orphans (`/tmp/tt-ground-canonical-tests.log`). The native capture-only audit passes actual dryland/grassland/woodland/cold-barren sites, controlled geological families, fog concealment and four live camera distances. Eleven images were inspected, including real base/regional meshes; the probe exits. Normal project headless boot is clean. See `GROUND_SURFACE_HANDOFF.md` for sampling data, scope and limitations.

Normal standalone release **2026.09.09.7** is packaged through `tools/launch_game_macos.py --build-only`; its `build.ok` records the exact source revision. Owned overrides removed; no player/editor interrupted and none active at integration. Save schema, physical heights, resources, climate and civilization mechanics are unchanged. The material families are illustrative surface treatments, not revealed ores. Iteration remains ACTIVE: coarse regional/continental landform and coastline quality still need improvement, followed by seasonal cover and richer natural materials. This does not claim the landscape is finished.

## September 9 — landscape iteration 2: real sea level and coastal depth

INTEGRATED `7a16b3e5bd373904676d3caac296b15f08d3de10` by conflict-free fast-forward from canonical Mac `4edac93deb789201384a89b9a91921d7dda8d343`. The ocean no longer renders twelve metres above its physical datum. Coastal colors use the actual regional terrain mesh heights, with muted shallows, shelf and deep water. A bounded local surface and matching far-water cutout follow streamed patches. World-anchored ripples fade before becoming unresolved noise; continental coloring suppresses the moving regional depth window. Fog conceals depth and highlights.

All **35 canonical combined tests pass**, zero errors/failures/skips/orphans (`/tmp/tt-coastal-canonical-tests.log`). Native Compatibility captures pass 48 shoreline samples, dry ground/old-height flooding comparison, three depth colors, four GPU-versus-mesh-ray checks, all four map scales, distant animation filtering, continental patch concealment and unknown-water pixel equality. Controlled top-down/perspective coast and water-scale images were inspected; the capture-only probe exits. The normal project also boots/exits cleanly headlessly. See `COASTAL_WATER_HANDOFF.md` for precise scope and limitations.

Normal standalone release **2026.09.09.6** is packaged through `tools/launch_game_macos.py --build-only`, with its source revision in `build.ok`. Owned test overrides removed. No player/editor was interrupted; no player was active at integration. Save schema, physical terrain, water supply, founding rules, resources and shared civilization mechanics are unchanged. Landscape iteration remains ACTIVE: ground materials, geological/seasonal variety and broader scenic quality are still being improved.

## September 9 — landscape iteration 1: biome-faithful, persistent vegetation

INTEGRATED `1c38347c972ba6a02d1b6be81daf9831fd04d4bc` by conflict-free fast-forward from `a5fff97810f36a209307623085f74186e01f4d7a`, on top of the illustrated research/discovery release. Broad trees now use the surveyed woodland field; close/legacy trees reject water and treeless ground. Scrub follows local precipitation and temperature. Fixed world cells, independent cluster seeds and position-based atlas variants keep plants stable when detail patches move or a nearby parcel is cleared. Vegetation and forest floors honor the same discovery mask and woodland depletion as the map, with weak material references.

All **50 canonical combined landscape and research/popup tests pass**, zero errors/failures/skips/orphans (`/tmp/tt-landscape-canonical-tests.log`). The native capture-only probe checks 803 rendered crowns for unchanged position, shape, tint and variant, and verifies hidden foliage produces the same pixels as no foliage. Four climate render comparisons were inspected; the probe passes and exits. Source also passes 36 terrain/resource/harvest/mesh/river tests and a clean headless normal-scene boot. Save schema, physical resources, climate generation and player/opponent mechanics are unchanged. See `LANDSCAPE_COVER_HANDOFF.md`.

Normal standalone release **2026.09.09.5** is packaged with `tools/launch_game_macos.py --build-only`; `build.ok` records its source revision. Test overrides removed; no user game/editor was interrupted or test scene presented as the player. Landscape iteration remains ACTIVE under the existing task heartbeat, now prioritizing honest ground surfaces, shoreline/river appearance, vegetation variety, seasons and scenic quality. This is the first landscape correction, not a claim that all realism is finished.

## September 9 — illustrated research teams and discovery announcements

INTEGRATED `c2cdb0614a2c0f82af4bf3f650a5a00dea79b9c9` by conflict-free fast-forward from `93cc5f578411c0ed8e9fa5dd70a195adefefbf08`. Inquiry opens painted active research cards with real named supervising leaders, acting/vacant offices, equivalent workforce, evidence progress and bottlenecks. The prerequisite tree and established knowledge remain available, with field/leader/name filters and hidden outcomes withheld. Small-window inspectors use a full-width view and Back control; daily updates preserve live cards and navigation.

New player discoveries from the actual calendar open one illustrated popup with signed effects, benefits/trade-offs, adoption explanation, queued Next, Dismiss all, Escape and outside dismissal. Reading pauses with nested pause ownership and restores prior speed. It does not replay history or announce enemy research. The nonexistent steam prerequisite for Safety Lifts is corrected to the existing Steam Propulsion discovery.

All **86 canonical combined tests pass**, zero errors/failures/skips/orphans (`/tmp/tt-research-canonical-tests.log`). The real HUD/calendar probe passes at 1280×900 and 800×600, including an actual completion opening the paused popup and restoring speed. Nine native capture-only renders were inspected; the probe exited without script errors. See `RESEARCH_VISUAL_HANDOFF.md` and `assets/ui/research/PROMPTS.md` for scope, tests, art provenance and limits. Save schema unchanged. Artwork identifies research fields; it does not invent individual researchers. Test overrides removed; normal release version **2026.09.09.4** is built with the canonical Mac launcher, with source revision in `build.ok`. No user game/editor was interrupted; no player process was active at packaging.

## September 9 — illustrated forces, compact map surveys and local construction materials

INTEGRATED `161f0db` and `0ff1c90` by conflict-free fast-forward from canonical Mac `6d127d8f9b3e6c00d25a8cfe2fa458f3d8213735`. The three service rosters use compact illustrated rows, 15 painted portraits, role insignia, actual readiness meters, filters and expandable details. Automated staff training retains its existing costs/time and gets visual policy cards. The user's corrected survey scope is the revealed resource details on the map: compact material icons, distance, qualitative quality/abundance, access and expandable explanations. Unknown information stays unknown.

Dryland terrain uses its climate hue at every rendering scale; green meadow/lush additions respect climate. Starter works and later household/court/workshop recipes choose feasible bills from each city's delivered stores; earthen homes require clay-shaping knowledge. Completed starter works preserve the paid material family in their converted plots, including the existing earthen building kit. This changes neither climate/resources nor the human/opponent distinction. It does not make clay a substitute for industrial fuel or every advanced structural input.

All **79 canonical combined tests pass**, zero errors/failures/skips/orphans (`/tmp/tt-survey-canonical-tests.log`), including civilization ownership and save continuation. The complete-save fixture now resets player military state as the normal new-world entry point does, preventing earlier UI sample bases from contaminating its save. Source verification also passed 88 settlement/resource/visual regressions and 23 focused material/survey/secondary-city cases. Native capture-only roster and terrain/survey probes passed and exited; actual widgets and shader output were inspected. The integrated normal scene booted and exited headlessly without script or cleanup errors. See `MILITARY_VISUAL_ROSTER_HANDOFF.md` and `RESOURCE_SURVEY_MATERIAL_HANDOFF.md` for limits and exact validation.

Save schema unchanged; older built forms remain recorded. Owned test overrides removed. Normal release version **2026.09.09.3** is packaged through `tools/launch_game_macos.py --build-only`, with exact source revision in its `build.ok`. Player PID 55512 remains the older `6d127d8f9b3e` / 2026.09.09.2 standalone session; it was not interrupted or replaced. A normal restart is required to receive these changes. No test scene is the player game.

## September 9 — readable founding convoy and consistent water assessment

INTEGRATED `660f863` by conflict-free fast-forward from `418027a1dbcf00148eb2383076bc90d44b6fbadc` into canonical Mac main. Founding convoys use the shared compact map card, with an aspect-preserving small flag, population and short water status. The oversized 3D banner/text are suppressed at all four distances. Cards follow convoy movement, open site review directly and avoid its panel. The bounded review scrolls its details while keeping close/founding controls visible. The final integration preserves the player's typed founding-site name casing.

Daily collection and founding advice now use the same physical source projection; submerged drainage lines no longer count as fresh water. Review explains nearby open water separately from a confirmed drinking source. Human and opponent starting searches use the same dry-ground/channel clearance and water checks. No population pacing or opponent-specific placement changes.

All **64 canonical tests pass**, zero errors/failures/skips/orphans, exit 0 (`/tmp/tt-founding-clarity-canonical-tests.log`); all **40 focused tests pass again** after the final name-casing correction (`/tmp/tt-founding-clarity-canonical-final.log`). Source validation includes **91 starting positions across seven seeds**, zero failures, and the real normal scene at all four distances with the review open, no script errors or leaks. Headless layout verification is not a native visual capture. See `FOUNDING_MAP_CLARITY_HANDOFF.md` for exact scope and limits.

Owned test overrides removed. Save schema unchanged; physical water is reassessed on load. Normal release version is **2026.09.09.2**, built via the canonical Mac launcher; its artifact `build.ok` records the exact source commit. Player PID 53240 remains the earlier standalone `418027a1dbcf` release, uninterrupted. No editor or player was stopped and no test window was presented as the current game. A normal restart is required to load the update.

## September 9 — shared civilization rules and 12-opponent default

INTEGRATED `40761bb` by conflict-free fast-forward from `ad90266903bf51ff1e56b9d2a206014fbab689ff` into canonical Mac main. New worlds give each civilization independent owned instances of the same daily systems, equal 120-person starts, real founding and local city economies, and ordinary paid equipment/recruitment/training. Controllers issue validated decisions. Shared geography, bilateral trade, scouts, combat, siege, occupation and allied relief resolve to real owner ledgers. Default: 12 opponents; 6/24/36 remain new-world options.

All 318 focused and regression tests pass, zero errors/failures/skips/orphans. A 365-day real-geography world with 12 opponents validates cleanly; a 36-opponent starting check finds reachable water for every party. The optimized food forecast matches 72 base-formula comparisons exactly. The normal opening scene boots and shuts down cleanly headlessly. See `FULL_CIVILIZATION_PARITY_HANDOFF.md` for details and limits. This is common simulation and ownership, not multiplayer networking or proof of 2,500-year balance. The old held `1e918e3` adapter is excluded. Legacy saves keep their old opponent model; new worlds use the new rules.

All 19 ownership tests also pass on canonical main, zero errors/failures/skips/orphans (`/tmp/tt-parity-canonical-tests.log`); the integrated normal opening scene boots and shuts down cleanly (`/tmp/tt-parity-canonical-main.log`). Canonical tests used isolated userdata and their override was removed. Normal release builds are produced through `tools/launch_game_macos.py`; each artifact records its exact source commit in `build.ok`. No player game/editor has been stopped or launched for this delivery.

## September 9 — distinctive civilizations, visible envoy journeys and local AI setup

INTEGRATED `fae9761` (source `6f1500b` plus validation corrections) by conflict-free fast-forward into canonical Mac main from `a31088e`. New worlds receive unique civilization and city names and distinct flags; map cards show the reported controlling civilization. Registering a player home no longer relocates three rivals nearby. Envoy dispatch retains the destination, schedule and map focus; returned outcomes open in a paused leader conversation. Nested settings preserve the prior speed, and speed shortcuts cannot bypass a conversation pause. The connection panel accepts a session-only API key locally and distinguishes missing credentials from HTTP failures. Foreign leaders share civic personality axes and have priorities that affect strategy and negotiations.

All **69 canonical focused tests pass**, zero errors/failures/skips/orphans, exit 0 (`/tmp/tt-civ-canonical-tests.log`). Across the source checkout, **138 named tests are verified** including the full century and billion-population cases and targeted reruns after correcting an obsolete instant-training fixture. The foreign-diplomacy integration probe and local mock HTTP contract probe pass. Flags were inspected at map sizes; dialogs received headless layout checks. No live API connection or native player-window visual audit is claimed. Existing names/locations remain on load; new naming applies to new worlds. The canonical test override was removed.

**HELD:** `1e918e3` in `/Users/seanpurtill/Documents/Codex/tt-civ-identities`, branch `codex/distinct-civilization-identities`, contains incomplete shared demographics and real-city records. It is excluded. Full human/AI rule parity, real opponent founding, shared city economies and multiplayer readiness are unfinished. No artificial population slowdown is delivered. The existing iteration heartbeat now prioritizes completing those shared systems; networking is explicitly outside scope. See `CIVILIZATION_PARITY_AUDIT.md` and `CIV_IDENTITY_DIPLOMACY_HANDOFF.md`.

No player or editor was stopped or launched. The earlier standalone player had already exited when checked. The release is being prepared for the next user-requested launch.

## September 9 — naval patrols keep searching their drawn area

INTEGRATED `b486157332be9cd0b32ab7dfd0c257c9a69219e2` by conflict-free fast-forward from `3843839` into canonical Mac main. Patrols and convoy raiders now move to fresh search waypoints after first arrival. Each new search leg stays inside the drawn operating polygon, on sampled water, within home-port range and within a day's sailing distance. Status text identifies patrols, convoy searches or waiting on station when no clear search leg is found. Existing contact pursuit takes priority, with patrol search resuming after reports expire; strike forces keep waiting for contacts in port and returning when reports lapse. Fuel shortage halts movement and resupply resumes the retained order.

All **137 canonical tests pass**, zero errors/failures/skips/orphans, exit 0, across joint campaign, joint operations, training strategy, main-map services and command hierarchy (`/tmp/tt-naval-patrol-canonical.log`). Five added regressions cover repeated early/powered-craft search, island and concave-area navigation, range/speed limits, shortage and deterministic JSON save continuation, contact/strike behavior and repair/stand-down priority. The first regression reproduced the old stationary behavior before the fix. Existing transport/carrier conservation and service UI checks remain green. Owned test overrides removed; no save schema, personnel, equipment, training-policy or land-command changes. See NAVAL_PATROL_MOVEMENT_HANDOFF.md.

Search remains daily, with a bounded 64-candidate local scan and existing two-kilometre water sampling. Tiny or isolated areas can hold station; this does not add continuous path spotting, guaranteed exhaustive coverage or numerical HOI4 parity. Initial transit and pursuit retain existing routing. No player/editor was launched or stopped, and no native visual or live-performance verification is claimed. The standalone release is prepared for the next user-requested launch.

## September 9 — visual fleet and air-command preparation

INTEGRATED `fc2f087157a0bce1ffbc2dac06b5076f9ffc965b` by conflict-free fast-forward from `3a7257f` into canonical Mac main. Fleet and Air Force command now show compact training, condition and next-zone coverage meters with the selected command's full mission fuel budget and shared reserve. Headquarters sum subordinate requirements, so one fuel reserve is not counted as sufficient separately for every wing. Exact detachment previews report their own craft/range/fuel and assembly restrictions without creating units. Progress and resupply refresh the display without replacing drafts or issued orders. Valid objectives may wait for staff preparation; unsupported missions remain disabled. Land command remains separate.

All **132 canonical tests pass**, zero errors/failures/skips/orphans, exit 0, across command hierarchy, joint operations, joint campaign, training strategy and main-map services (`/tmp/tt-service-preparation-canonical.log`). Six new regressions verify shared budgeting and no state mutation, virtual craft/assembly, empty next-zone and suspended instruction, live meters/resupply, repair-warning agreement/absent craft training estimates, and service isolation. Existing minimum-window layout checks include visible meters and keep Give objective reachable. Readiness now agrees with the existing staff repair threshold and ignores zero-count craft when estimating training time. Owned overrides removed; no simulation policy, save schema or population changes. See SERVICE_PREPARATION_PREVIEW_HANDOFF.md.

The display is advisory: final terrain routing and assignment validation still apply, other forces/exercises share fuel, and range coverage is not battlefield control. No numerical HOI4 parity or native visual inspection is claimed. No player/editor was started or stopped. The updated standalone release becomes available on the next user-requested launch.

## September 9 — city names, flags and population in a shared map layout

INTEGRATED `8f7d2091385c919a1a25f5904cb6fd41b2295a60` by conflict-free fast-forward from `1de8c8a` into canonical Mac main. Owned and reported city labels now use compact screen-space cards with civilization flags/colors, preserved name casing and population or estimate on a separate line. Cards avoid one another and city pins; leader lines preserve geographic association. Stable offsets prevent small-pan slot changes, and unchanged views reuse layout. Excess entries have a counted scrollable list instead of overlapping text. Cards and list items select their own city, with visible cards taking precedence over military markers beneath them. Reported knowledge, the inline intelligence summary and all four zoom distances remain intact.

All **29 canonical tests pass**, zero errors/failures/skips/orphans, exit 0, across city label layout, foreign labels, dismissal, distance levels, secondary city design and separate military map services (`/tmp/tt-city-label-layout-canonical.log`). The full-map/menu/display probe passes **77 checks**, zero failures, exit 0 (`/tmp/tt-city-label-full-map-canonical.log`). Six new regressions cover clustered placement, pan stability, dense-view conservation, names, list actions and direct map picking. A synthetic layout diagram was visually checked; it is not a native game capture. Owned overrides removed; no save schema or simulation changes. See CITY_LABEL_LAYOUT_HANDOFF.md.

The previously launched standalone player PID 15785 has exited by final verification. No player/editor was stopped or relaunched by this work. The release build will include these city cards and the previously verified grounded-air fuel fix on the next user-requested launch. Existing marker inventory budgets remain; dense views expose excess labels in the list. Native usability assessment is still pending actual play.

## September 8 — grounded air missions preserve fuel and standing orders

INTEGRATED `08fcf7693b439ae2c282a7e9209e21f3208397c6` by conflict-free fast-forward from `705e015` into canonical Mac main. Wings with no range coverage or no operating area now wait without spending sortie fuel. Carrier movement can ground a wing; returning within range resumes its retained order automatically, including after operations save/load. Air command shows flight fuel actually used today separately from the mission requirement and reserve. Partial coverage still operates, and naval movement, carrier/airbase ferry flights, repair returns and transport retain their charges. Training remains an independent paid policy.

All **71 canonical tests pass**, zero errors/failures/skips/orphans, exit 0, across joint campaign, joint operations, training strategy and main-map services (`/tmp/tt-grounded-air-fuel-canonical.log`). The new carrier regression first reproduced the old erroneous charge of four fuel for four grounded aircraft. The four new regressions cover actual carrier movement, resumption, saved orders, report text, partial coverage, resupply, movement costs and missing-region grounding. Owned test overrides removed; no save schema or population changes. See GROUNDED_AIR_FUEL_HANDOFF.md.

Player PID 15785 remains running standalone source `705e015b8b5d`; no session was interrupted. This source integration becomes playable on the next updated standalone launch. Native inspection and numerical HOI4 parity are not claimed.

## September 8 — exact naval and air detachment equipment and range

INTEGRATED `8d6098c` by conflict-free fast-forward from `699eefa` into canonical Mac main. Selecting a virtual naval/air subdivision now previews the exact craft it will receive, using the same allocation function as real materialization. Mission availability and the live selected-command tooltip use that composition. Assignment validates the selected craft and their operating range before splitting: balloon-only elements cannot receive fighter missions, while a fighter element can use its own range even when its parent contains short-range balloons. Rejected orders leave assets and hierarchy unchanged; accepted splits retain established ordering and original-force replacement deficits.

All **68 canonical tests pass**, zero errors/failures/skips/orphans, exit 0, across hierarchy, main-map services, dismissal and joint operations (`/tmp/tt-detachment-equipment-canonical.log`). Five new regressions cover exact mixed-craft previews, unsupported refusal, independent nested naval/air splits and JSON save/load conservation, correct detached range and live read-only composition/mission refresh. Existing land, selection, current-order, native expansion, layout and cancellation checks pass. Owned overrides removed. No save schema changes or shared hotspot conflicts. See DETACHMENT_EQUIPMENT_PREVIEW_HANDOFF.md.

This resolves the previous parent-capability limitation for virtual service subdivisions. Base/transport/assembly checks and training, fuel and repairs remain governed by the existing systems; it is not a complete readiness forecast or numerical HOI4 parity. No player/editor was interrupted or test window presented as the game. Native UI inspection remains pending a normal updated standalone launch.

## September 8 — command objectives show equipment limitations before issuing

INTEGRATED `f9e4c61` by conflict-free fast-forward from `bf56e14` into canonical Mac main. Fleet and Air Force objective menus disable missions their selected ships/aircraft cannot support, using the existing mission capability authority. Headquarters check every real subordinate; tooltips identify incompatible commands. A retained draft becomes visibly unavailable after switching to incompatible forces or losing specialized equipment, without changing the draft or issued orders. Replacements and compatible selections restore availability. Give objective and map right-click recheck the same feedback. Land mission choices remain intact; empty/stale selections cannot submit.

All **63 canonical tests pass**, zero errors/failures/skips/orphans, exit 0, across command hierarchy, main-map services, dismissal and joint operations (`/tmp/tt-mission-capabilities-canonical.log`). Five new regressions cover aircraft roles, mixed headquarters and virtual selection, equipment loss/replacement refresh with no order mutation, actual naval assignment and empty/land selection. Existing minimum-window checks include the new visible warning while keeping primary actions reachable. Owned overrides removed; no simulation/save changes or shared hotspot conflicts. See COMMAND_MISSION_CAPABILITIES_HANDOFF.md.

This is equipment feedback, not a full readiness forecast. Routes, bases, range, transport commitments and final detached composition remain validated by assignment; training, supply and repairs can delay execution. Virtual subdivisions use parent capability until assembled. No native visual verification or numerical HOI4 parity is claimed. No player/editor was stopped; previously recorded player PID 11813 has already exited. The updated standalone build receives this UI on its next normal launch.

## September 8 — faster, adjustable map scrolling

INTEGRATED `6d2b749` by conflict-free fast-forward from `9d5966b` into canonical Mac main. Two-finger panning now defaults to 4× the previous pace. Menu → Map Controls → Map scroll speed offers 0.5×–12×, a live numeric readout and Default (4×). It appears near the top, applies immediately and persists between games in the existing local preferences. Old settings gain the faster default while retaining display/audio choices. Invalid values are bounded or replaced with the default. Arrow zoom and panel scrolling are unchanged; settings keyboard adjustments cannot also pan the background map.

Canonical validation: **9 gdUnit tests**, **49 input checks** and **77 full-map display/menu checks** pass, exit 0, with no reported errors/failures/skips/orphans. Includes live sensitivity, persistence/reopening/default, legacy settings, all four distances, GUI input isolation and immediate slider visibility at 1280×720/1440×900 with 100–175% UI scale. Logs: `/tmp/tt-scroll-sensitivity-canonical-tests.log`, `/tmp/tt-scroll-sensitivity-canonical-input.log`, `/tmp/tt-scroll-sensitivity-canonical-display.log`. Owned overrides removed; no simulation/save format changes. See MAP_SCROLL_SPEED_HANDOFF.md.

Player PID 11813 remains uninterrupted on standalone source `9d5966b7e1c5`. This source integration does not change its bundled controls. The next updated standalone launch receives the setting; subsequent slider changes need no restart. Native trackpad feel remains for player assessment.

## September 8 — two-finger map pan and Up/Down distance

INTEGRATED `6c91a4e` by conflict-free fast-forward from `154d2c5` into canonical Mac main. Two-finger movement pans both map axes at the current scale without zooming; finger spread cannot change altitude during a pan. Up/Down selects the adjacent distance with the existing smooth four-level transition. Holding arrows does not repeat or also pan. Map hints and Mac controls documentation now match. Toolbar focus no longer swallows map arrow zoom; hovered panels, text fields and decision/menu input retain their controls.

The real viewport input probe passes **49 checks** and the four canonical gdUnit suites pass **27 tests**, with zero errors/failures/skips/orphans; both exit normally. Logs: `/tmp/tt-trackpad-pan-canonical-probe.log` and `/tmp/tt-trackpad-pan-canonical-tests.log`. The probe covers rotated and fractional panning, all four scales, no altitude drift, arrow direction/bounds/repeat, actual GUI propagation and modal guards. Existing physical-altitude, smooth-transition, founding, dismissal and separate-service map checks pass. Owned test overrides removed. No simulation/save changes. See TRACKPAD_PAN_HANDOFF.md.

No player or editor was stopped by this task. Previously recorded player PID 9776 has already exited. Native trackpad feel is not established by synthetic events. The updated controls are included in the next standalone build; an older exported app keeps its bundled input code.

## September 8 — normal standalone release launched

INTEGRATED `fc7b43c` by conflict-free fast-forward from `d9e0f44`. At the user's explicit request, closed the old editor/debug session through Godot's normal Stop & Quit dialog and launched a fresh standalone release with `python3 tools/launch_game_macos.py` from the canonical Mac checkout. No editor, remote debugger or embedded-window arguments are present.

The canonical export succeeds and its ad-hoc signature verifies. The official executable identifies itself as a release export template. Player **PID 9776** runs `/Users/seanpurtill/Documents/Codex/tomorrow-and-tomorrow/artifacts/macos-release/fc7b43c89cfa/Tomorrow and Tomorrow.app/Contents/MacOS/Tomorrow and Tomorrow`; the absolute app path and `build.ok` bind it to this canonical build. Its title is **Tomorrow and Tomorrow · 2026.09.08.1**, without DEBUG. Native inspection shows the real map, **Year 1 / Day 1**, population **120**, and the founding convoy beside a river. Editor PID 2812 and debug player 6076 have exited. The new release remains running.

The launcher starts fresh by default and refuses another active player; this guard was exercised against PID 9776 without opening a duplicate. The packaged main scene also initialized in an isolated headless worktree check; the immediate three-frame shutdown's two-object/one-resource cleanup warning is recorded in MACOS_RELEASE_LAUNCH_HANDOFF.md. Native startup is verified visually; the release log files were still buffered/empty during inspection, so no detailed live-log pass is claimed. No simulation or save-schema changes. Project settings add the ARM-required texture import format and update the visible version; renderer and main scene are retained. See MAC_SETUP.md for the ordinary release launcher.

## September 8 — issued objectives are distinct from military drafts

INTEGRATED `eaca48a` by conflict-free fast-forward from `d312ad0`. Army, Fleet and Air Force command panels show a colored Now line for the actual issued objective and zone/reported city, while the mission picker explicitly labels the Next objective. Current information refreshes without replacing the player's draft. Headquarters identify shared orders, mixed orders and subordinate exceptions. Edit loads the current mission, map zone, reported city and brief into the draft without issuing it or changing forces; unavailable/cancelled orders and transport do not load misleading defaults.

All **53 canonical tests pass**, zero errors/failures/skips/orphans across command hierarchy, main-map services and dismissal (`/tmp/tt-current-orders-canonical.log`). Six new regressions cover read-only editing, inheritance/overrides/mixed headquarters, real separate-service order updates, reported-city targeting and hidden-name isolation, unavailable/cancelled orders, and transport. Extended 1280×720 and 1024×640 layout checks cover the new strip and Edit button with long text while preserving accessible primary actions. No simulation, camera or save changes; see CURRENT_COMMAND_ORDERS_HANDOFF.md. Owned test overrides removed.

Editor PID 2812 and player PID 6076 remain uninterrupted in the canonical checkout. This pass does not claim native visual verification or receipt by the running player. Recreated panels after effective reload, or the next normal project launch, receive the UI. The summary describes issued objectives; it does not imply operational readiness or successful execution.

## September 8 — cancellation respects the selected military command

INTEGRATED `49ef49c` by conflict-free fast-forward from `63e62ab` into canonical Mac main. Cancel orders now retains the selected subdivision path, detaches only that available branch and leaves sibling objectives executing. Changed-strength or busy subdivisions are refused without cancelling their parents; unassigned subdivisions stay read-only. Whole naval/air stand-down validates all subordinates before committing, reports convoy/route refusals and distinguishes port, airbase/carrier and land behavior. Already committed land battles continue resolving.

All **97 canonical tests pass**, zero errors/failures/skips/orphans across six suites (`/tmp/tt-scoped-cancel-canonical.log`). Seven new regressions cover the actual cancel button, exact selection, conserved assets and saved overrides, independent sibling execution, refusal/no-op cases, atomic naval/air cancellation and continued battle resolution. Existing command, service, carrier, transport, siege and layout/dismissal checks pass. No save schema changes or shared hotspot conflicts; see SCOPED_COMMAND_CANCELLATION_HANDOFF.md. Owned test overrides removed.

Player PID 6076 and editor PID 2812 remain running from the canonical checkout; neither was interrupted or relaunched. Native visual verification and receipt by the already-running game are not claimed. The next normal project launch loads the integrated scripts. Virtual subdivisions still require an available assembled force before they can detach.

## September 8 — live founding-overlay correction

INTEGRATED `bd247db` by conflict-free fast-forward from `465390d`. Native inspection of player PID 6076 found the full-size map overlay was incorrectly captured by the global modal fitting contract, collapsing the card. The overlay now opts into its own existing responsive-layout convention. The regression invokes that actual shared contract, verifies the card remains unwrapped and visible, and still checks small-window bounds.

All **16 focused canonical tests pass**, zero errors/failures/orphans (`/tmp/tt-founding-live-layout-canonical.log`). The preceding feature integration passed 107 canonical tests. Owned test overrides are removed. No simulation/save changes in this correction; see FOUNDING_SITE_LIVE_LAYOUT_HANDOFF.md.

Launch verification: canonical editor Run Project launched player **6076** from **465390d**, using the absolute canonical path and `res://local_terrain.tscn`, parent editor **2812**. Native inspection saw the real main map and new water readout, source line and site markers. Startup log has no script errors. The release display remains 2026.09.07.2. This new world used seed 1788457137 and was subsequently running at Year 2; no settlement was committed by the agent.

The corrected card's final native appearance is **not verified**. The desktop-control tool repeatedly focused the editor instead of the embedded game, then returned `windowNotFoundAtPosition` on fresh game-view coordinates. The game window remains running; it was not forcibly stopped or saved over another campaign. Reopening the card after effective script synchronization, or a normal project restart, is required for the final UI correction. The active process command line verifies its checkout, not receipt of this later hotfix.

## September 8 — settlement water guidance and neighbor resentment

INTEGRATED `e434bc8` by conflict-free fast-forward from `bd1992c` into the canonical Mac checkout. Review Founding Site now previews actual known water, carrying distance and household coverage before the first commitment. First/later founding rechecks exact dry ground and confirmed water within the existing 6 km collection limit. The main-map card marks nearby suitable sites and their water; clicking a numbered site uses the agreed 50,000-foot view. Ground inspection and later convoy confirmation carry the same water and neighbor warnings.

Returned foreign-city reports predict stronger resentment at shorter distances. When neighbors observe or learn of the founded city, a quadratic penalty inside 30 km changes real opinion and border tension. Each player city creates at most one current grievance per affected civilization; repeated reports and days do not repeatedly charge it. Nearby cities use their established 12 km sight radius; distant cities wait for reports. Optional grievance dictionaries persist in the existing relations save data. Existing observed cities may acquire their first grievance on update. No hidden cities are exposed by preview.

All **107 canonical tests pass**, zero errors/failures/skips/orphans across seven suites (`/tmp/tt-founding-water-canonical.log`); canonical headless editor import passes (`/tmp/tt-founding-water-canonical-import.log`). Includes real founding, later-city checks, existing city management and intelligence, exact water-limit boundaries, known-only suggestions, 1024×640 controls and warnings, distance ordering, observation delays, multi-city penalties and serialized deduplication. Owned test overrides removed. No player/editor was stopped or campaign save overwritten. See FOUNDING_SITE_GUIDANCE_HANDOFF.md for scope, limits and logs.

At integration, canonical editor PID 2812 is open and the prior player has already exited. Native inspection and the updated player launch are being verified separately; passing tests alone do not establish live receipt.

## September 8 — latest integrated build running after reopening

At the user's launch request, opened the canonical project in Godot. Editor PID **2812** and new player PID **3034** run `/Users/seanpurtill/Documents/Codex/tomorrow-and-tomorrow`; the player command line names `res://local_terrain.tscn` and its canonical editor parent. The checkout at launch is **d9aeec5**, including command-panel layout `7a1310c` and exact command-selection refresh `41a97ff` (40 canonical tests passed before launch).

Native inspection shows the actual main map in a new world, Year 1/Day 1, population 120, with the founding convoy and ground inspection visible. The startup log has no script errors and reports seed 1788281429. The displayed release string remains 2026.09.07.2. The earlier embedded-view capture problem is no longer present in this reopened session. No further restart or save load was performed after observing the active game. A temporary editor resume argument was removed; it was not present in this player's command line. The proposed current-order summary follow-up has no source changes and is not part of this build.

## September 8 — exact military selection during refresh

INTEGRATED `41a97ff` by conflict-free fast-forward from `f0b0fe4`. Hierarchy clicks now use the displayed strength and order. Resized detachments can receive orders after the required reselection instead of repeatedly failing a stale-strength check. Vanished subdivisions clear the active order target. Structural refreshes retain the exact active subdivision and other selected commands, preventing an unnoticed switch from a small detachment to its whole parent force. Ordinary count updates preserve existing rows and expansion.

All **40 canonical tests pass**, zero errors/failures/orphans (`/tmp/tt-command-refresh-canonical.log`). New cases cover strength changes, reselection and real asset conservation, disappeared/reappearing teams, placeholder input, and exact subdivision/multi-selection/draft retention in all three services. Native expansion and existing layout/map/command regressions pass. No simulation/save schema changes or shared-file conflicts. See COMMAND_REFRESH_HANDOFF.md. Temporary test overrides removed.

No game/editor UI actions or restart in this pass; player PID 95563 and editor PID 93974 remain running. Native visual verification and receipt by already-open controls are not claimed. Recreated controls after script reload or the next normal launch receive this code.

## September 8 — compact military command panels

INTEGRATED `7a1310c` by conflict-free fast-forward from `241e532`. Army, Fleet and Air Force command panels keep Give objective and Cancel orders outside the scrolling form, give the hierarchy more room, put objective selection first and collapse optional names/briefs. Drawing-only actions appear during a draft. Personnel/craft headers fit; single-line headings and scrollable reports keep the panel within the minimum logical canvas.

All **37 canonical tests pass**, zero errors/failures/orphans (`/tmp/tt-command-panel-canonical.log`). Layout checks cover all three services at explicit logical sizes of 1280×720 and 1024×640 with expanded details, long feedback and scrolling; existing hierarchy, native expansion and map-dismissal checks pass. No simulation/save changes or shared-file conflicts. Temporary test overrides removed. See COMMAND_PANEL_LAYOUT_HANDOFF.md.

The existing player PID 95563 remains running; this integration does not claim that its already-open panel has rebuilt. No player/editor restart was performed. Native inspection of the new layout is pending.

## September 8 — command tree mouse expansion and live inspection

INTEGRATED `388ae88` by fast-forward from `17eb240`. Native mouse expansion now defers row creation until Godot releases its Tree selection lock. Deferred work uses an instance ID and ignores rows removed by a refresh. This fixes the runtime pause found while showing the actual Army Command UI; the earlier direct-method/headless checks did not cover that native event path.

All **35 canonical tests pass**, zero errors/failures/orphans (`/tmp/tt-command-tree-canonical.log`), including a native viewport mouse-event regression and a pending-expansion/rebuild case. No simulation/save changes. Test overrides removed. See COMMAND_TREE_CLICK_HANDOFF.md.

Live verification: canonical editor Run Project launched player **PID 95563** from code commit `388ae88`; its command line contains `/Users/seanpurtill/Documents/Codex/tomorrow-and-tomorrow` and `res://local_terrain.tscn`. Loaded the existing Seanston save at day 29337/population 1047, opened Military → Command on map, expanded the 10-person squad and selected it without the previous error. The game remains paused in Army Command. No objective was issued or saved campaign overwritten.

## September 8 — military hierarchy and autonomous battle zones

INTEGRATED `d220fa1` by conflict-free fast-forward from `41d410b` into the canonical Mac checkout. Military → Army Command, or Forces → Command on map, now opens a real-force command tree on the main terrain. Select an Army down to a Team, or a separate naval/air command, and assign its subtree a drawn zone and objective. Land commanders execute movement, observed contact, flanking, city assaults, siege assaults and occupation detachments. Neutral borders halt unauthorized advances; hostile contact creates dynamic front ribbons. Separate commander battles progress concurrently without duplicating participants or forcing a battle/aftermath screen.

All **163 canonical tests pass**, zero errors/failures/orphans across 12 suites (`/tmp/tt-command-delivery-canonical.log`); the canonical headless editor import also passes (`/tmp/tt-command-canonical-import.log`). Tests include real personnel/equipment conservation, simultaneous battles and save/load, parent/child orders, automatic city outcomes, terrain routing, border/contact behavior, separate service orders, stable hierarchy refresh and 1280×720 panel bounds. New optional hierarchy/battle data is backward compatible with older saves. Temporary test overrides removed; no player/editor interruption or native visual verification. The running game needs a normal project restart to load this structural change.

Limits: local aggregate fronts, not full HOI4 province/supply simulation; the existing siege system still allows one active siege and gates new land engagements during it. Occupation detachments remain in their existing ledger. No future mech catalog is added in this change. See [COMMAND_HIERARCHY_HANDOFF.md](COMMAND_HIERARCHY_HANDOFF.md) for scope, accounting and exact validation.

## September 8 — whole-service training overview

INTEGRATED `a3f1300` by conflict-free fast-forward from `8871aed`. Navy/Air strategy views show four colored counts and proportion bars for Training, On assignment, Target met and Paused, plus crew attendance and grouped pause reasons. Summaries include all owned forces in the selected service and no longer depend on which force was processed last. Base/equipment failures clear stale attendance, target completion clears the old exercise message, and repairs expose their actual status.

All **79 canonical tests pass**, zero errors/failures/orphans (`/tmp/tt-service-overview-canonical.log`), covering mixed-service summaries, read-only/order-independent counts, recovery, target completion, stable UI/layout and existing military operations/accounting/map checks. No save schema or rate changes. See SERVICE_TRAINING_OVERVIEW_HANDOFF.md. Native visual interaction is not claimed; no player/editor interruption. Test overrides removed. Next normal launch receives the integrated changes.

## September 8 — scout route previews and local surveys

INTEGRATED `77049fc` by conflict-free fast-forward from `ce45a15`. Automatic headings now receive the same validated route preview as ordered headings, search the full compass and permit nearby surveys when long routes are blocked. Departure follows the quoted route and validates it before spending. Cards show planned outward distance, include surveying/return travel and no longer label unknown country generally low-risk. Route-only reuse prevents repeated toolbar planning; supplies and people remain current.

All **60 focused canonical tests pass**, zero errors/failures/orphans (`/tmp/tt-scout-planning-canonical.log`), covering new route/preview cases and existing scouting, reports, rumor, findings, onboarding and return-speed checks. Generated terrain from the latest logged world seed has valid proposals for all four durations. No save migration or travel-rate rebalance. A broader unrelated peace-incident fixture failure was reproduced on the unchanged base; no full civilization-suite pass is claimed. See SCOUT_ROUTE_PLANNING_HANDOFF.md. Test overrides and baseline fixture removed. Player/editor remain uninterrupted; next normal launch receives the changes.

## September 8 — crew repair and training recovery

INTEGRATED `1683ba1` by conflict-free fast-forward from `06798ef`. Initial and qualified Navy/Air crews finish repairs before training resumes; suspending instruction still permits essential repairs. Repair shortages spend nothing until funded. Same-day calls preserve attendance/status, rival messages stay out of player staff reports, and the roster shows actual travel and repair shortages. Initial instruction reports completion/time instead of a misleading rotation percentage.

All **74 canonical tests pass**, zero errors/failures/orphans (`/tmp/tt-service-training-canonical.log`), across training strategy, accounting, operations, campaign, main-map services and dismissal. No save schema changes. See SERVICE_TRAINING_RECOVERY_HANDOFF.md. Test overrides removed. Running player/editor left uninterrupted; next normal launch receives these scripts.

## September 8 — automatic service training and broad military roster

INTEGRATED `ab0c4b4` by conflict-free fast-forward from `17da40a`. Army, Navy and Air now have independent saved Suspend/Maintain/Regular/Intensive training policies. Staff choose eligible rotations, fund exercises, protect civilian food reserves and pause for shortages; repeated orders grant no progress. Army exercises are six times longer with four times the per-participant daily ration/wear rates. Initial land and crew instruction use longer durations and real recurring costs. Rival training uses the shared policy/course limits and paid resource rules instead of its prior faster land formula.

Military/F6 opens the broad visual roster and training strategy view. Separate naval/air map commands remain available; Close, Escape and exposed-map clicks dismiss the roster. New army reports carry dated formation data. Optional save fields migrate existing course completion fractions once and preserve service policies and paid progress.

All **80 canonical tests pass**, zero errors/failures/orphans (`/tmp/tt-training-canonical.log`), including 15 new strategy/UI cases and existing accounting, defense, operations, campaign, catalog and dismissal suites. Headless checks cover controls, layout width and dismissal/state behavior; native visual interaction is not claimed. See TRAINING_STRATEGY_HANDOFF.md. Both temporary test-userdata overrides were removed. The running game/editor were not interrupted or relaunched; the next normal launch receives the integrated scripts.

## September 8 — click map to dismiss panels and help

INTEGRATED `e493ab5` from base 889199f. Bare-map clicks close ordinary/detail docks and map-help tips together, consuming the click before world orders. Supported report/menu/dispatch backdrops close on clicks outside their bodies. Military drawing and actual marker/region selection retain their input; otherwise blank map dismisses command mode. Mandatory decision dialogs keep explicit controls. Opening map-help copy now describes real pan, four-distance zoom, city inspection and map-click dismissal, with a clearer Close button.

All **11 canonical tests pass**, zero errors/failures/orphans (/tmp/tt-map-dismiss-canonical.log), including no accidental settler movement after dismissal, content/backdrop distinction, service input and distance controls. No save changes. See MAP_DISMISSAL_HANDOFF.md. Native control reported user activity; a read-only screenshot shows an actively running new campaign, Year 6/population 162. No save/quit/relaunch was performed. The next normal launch receives this change; live application is not claimed. Test userdata override removed.

## September 8 — latest integrated game launched

At the user's request, saved and quit player PID 67340 normally and launched canonical editor Run Project from code commit **be55da7**. New player **PID 74514** has the explicit canonical project path, res://local_terrain.tscn and --resume-saved. Startup log confirms day 29337, population 1047, Seanston, seed 1792946605, with no script errors. This launch includes the carrier transitions, carrier-map position correction and stable command selection fixes. Displayed release remains 2026.09.07.2. Temporary resume arguments removed; editor preserved.

## September 8 — stable military order selection

INTEGRATED `6145949` by fast-forward from 48d860b. Command-panel refreshes and failed orders preserve the selected region and proposed mission. Explicit force selection restores that force's actual order; current orders are labelled separately, and region control text updates. No simulation/save changes. All **36 canonical tests pass**, zero errors/failures/orphans (/tmp/tt-order-selection-canonical.log). See MILITARY_ORDER_SELECTION_HANDOFF.md. Running player untouched; next normal launch receives this change. Temporary test userdata override removed.

## September 8 — carrier wing map positions

INTEGRATED `24d2d18` plus fixture correction `ec1cd9c`. Carrier-wing markers, click targets and route origins now use the authoritative carrier-following position. Detaching restores independent positioning; stored coordinates and save format are unchanged. Canonical main-map/campaign checks: **34 passed**, zero errors/failures/orphans (/tmp/tt-carrier-markers-canonical-fixed.log). The initial fixture omitted required display/base data and failed during rendering; the corrected run supersedes it. Running player/editor not touched; next normal launch receives this change. See CARRIER_MAP_HANDOFF.md.

## September 7 — carrier and force order transitions

INTEGRATED `947ad09` by fast-forward from c53a964. Carrier ferries are cancelled by rebase orders; deck-wing stand-down preserves the carrier assignment; reorganization/disbanding requires physical arrival at an operational home base; carrier removal cannot orphan attached or incoming wings; carrier merges redirect incoming wings as well as attached ones. No new save fields. All **38 canonical tests pass**, zero errors/failures/orphans, including four new transition/conservation/save-reference cases. Log: /tmp/tt-carrier-transitions-canonical.log. See CARRIER_TRANSITIONS_HANDOFF.md.

The scheduled pass did not restart or interact with the player/editor session. New-process availability is at the next normal launch; live receipt is not claimed. Temporary test userdata override was removed. This is a bounded order-correctness improvement, not full HOI4 mechanics parity.

## September 7 — separate main-map military commands and operational iteration

INTEGRATED `7fb5dc2`, `fecf99f`, `ff2f02b`, `5ae5714` by sequential fast-forwards into canonical Mac main. This replaces the previous Naval & Air secondary screen completely: Navy and Air each have separate command panels, tabs and operational controls over the real world map. Draw/select regions there; Shift+F5 Navy, Shift+F6 Air, D draw, Enter finish, Escape cancel/close. Existing camera and four distances remain in use. The obsolete independent operations map is deleted.

Military follow-up: visible readiness and read-only commissioning quotes; local recipe-funded repairs and explicit shortages; separate naval repair capacity versus air sortie crowding; airborne-only superiority/interception targets; physical port strikes; bounded naval contact/fire ranges and dated-contact pursuit. Reports separate service-specific losses. Empty services lead directly to setup; unusable mission controls stay hidden. Full numerical HOI4 parity is not claimed; combat remains daily and aggregate with simplified ranges and doctrine.

Combined canonical checks: **63 tests pass**, zero errors/failures/orphans across main-map services, joint campaign loop, joint operations, force catalog, land combat simulator and camera distances. Log: /tmp/tt-services-delivery-canonical.log. No new required save fields. Both service panels were visually inspected over the original terrain in the actual resumed campaign at fecf99f. Native pointer drawing remains unverified because embedded-window coordinate automation redirects clicks to the editor; projection, boundary persistence and input handling have headless behavioral checks. Source details: docs/MAIN_MAP_SERVICES_HANDOFF.md.

Release **2026.09.07.2** is running from code commit **5ae5714**, player **PID 67340**, launched through canonical editor Run Project. Command line confirms the canonical absolute project path, res://local_terrain.tscn and --resume-saved; startup log restores day 29337/population 1047 with no script errors. Both final panels were visually checked: all four tabs fit, separate Navy/Air setup actions are visible and empty mission/organization forms are hidden. Keyboard D drawing and Escape draft cancellation were checked live; the campaign remains paused on Air Command. The final compact-layout refinement passed all 34 relevant canonical tests again. Temporary launch arguments and test userdata overrides were removed. Ongoing military iteration heartbeat `iterate-military-gameplay-and-ui` is active in this task every 30 minutes; the existing settlement-development task remains separate.

## September 7 — joint operations and modern architecture integrated

INTEGRATED source `f4a7d78` / `f466f20` from `codex/fifty-units` through merge `f996fa6`; integration fixes `2b2e3ea` and `f66bfcb`. This supersedes the held `33ab016` milestone. Canonical Mac checkout is `/Users/seanpurtill/Documents/Codex/tomorrow-and-tomorrow`.

The player build now contains 50 neutral land archetypes, 21 naval types and 16 air types; researched production, city-funded bases, aggregate crews, carriers, transport, geography-checked sea routes, player-drawn operating polygons, mission effects, rival industrial/combat operations, fleet screening and submarine detection. Detailed settlement architecture adds 24 masonry/industrial/modern building families through the shared saved-parcel placement system, named construction research and paid upgrades. Historic districts retain their built form.

Combined canonical validation: **139 tests passed**, zero errors/failures/orphans, across 12 suites. After the final keyboard/map/manpower integration refinements, all **30 joint campaign and city-intelligence tests passed** again. The documented baseline raid-intelligence fixture now provides viable military strength explicitly, preserving all hidden/stale-intelligence assertions. Actual current-save compatibility restored day 25512, population 777, seed 1792946605 in isolated test userdata.

Canonical editor Run Project launched version **2026.09.07.1**, player **PID 60507**, from code commit `f66bfcb`. Process command line explicitly contains the canonical absolute project path, `res://local_terrain.tscn` and `--resume-saved`. Startup log confirms the saved world and contains no script errors. Previous player sessions were saved and quit through their own UI. No worker/test scene was shown as the player game. Temporary test-userdata and editor-resume settings were removed.

Live checks: city flags/colors and Military entry cards visible; **Shift+F6** opens Naval & Air Command; **Escape** returns directly to the map. The operations screen shows the home city, foreign names/estimated populations, separate labels, the researched War Canoes choice, base/production controls and polygon-drawing controls. The final player remains paused on that screen. Polygon drawing and mission execution have headless behavioral checks; native mouse drawing was not verified because embedded-window coordinate automation is unreliable. Modern mesh/placement behavior is tested; the current early-era campaign was not artificially advanced to modern architecture for a visual claim.

Limits: HOI4 numerical/combat-system parity is **not complete**. Combat remains aggregate and daily, with simplified fleet screening, detection and air performance. Rival overseas invasions/supply convoys, full doctrine and component-design simulation remain outside this integrated iteration. See `docs/FIFTY_UNITS_HANDOFF.md` for exact behavior and scope. Prior production clarity `da9f917`, flags `a0ff5d5`, staffing `fab7843`, and foreign-label/intel fixes are included in this relaunched player.

## September 7 — army staffing clarity

INTEGRATED `fab7843` by conflict-free fast-forward from `1589e37`. Recruit & Train shows available recruits, training places and work allocation separately. Per-city watch/training priority actions replace the vague allocation detour and retain GovernmentPeopleSystem authority and occupation guards. Eleven targeted and existing recruitment tests pass; no save or calculation changes. See ARMY_STAFFING_HANDOFF.md. The city flag update `a0ff5d5` is included in this base. Player PID 47271 has not been restarted; receipt by the live session is not claimed.

## September 7 — foreign city labels and map intelligence

Integrated `824ea64` and `4614b5e` from `codex/foreign-city-labels` by fast-forward. Known foreign cities retain name/population-estimate labels at every distance. Clicking a city opens a compact intelligence dock on the map; the full report remains optional. A live check found a competing font-size refresh that caused shrinking/blinking; the follow-up preserves aerial normalization. Two targeted regression cases pass, including normalization followed by marker refresh at all four distances. The older intelligence AI-target test remains a reproduced baseline failure (see FOREIGN_CITY_LABELS_HANDOFF.md). No save schema changes.

Canonical editor Run Project resumed Seanston, day 2374, population 147, seed 1792946605. Player PID 47271 has the explicit canonical project path and `res://local_terrain.tscn` with `--resume-saved`; startup log confirms restoration with no script errors. Live Region screenshot shows foreign names at readable size matching Seanston. Campaign remains paused. The temporary editor resume argument was removed from project.godot after launch. Click/summary behavior is covered by targeted checks; native automation could inspect the embedded game but redirected coordinate clicks to the editor, so no live mouse-click validation is claimed.

# Compact speed dropdown integrated — September 7, 2026

INTEGRATED 45b24d1 in canonical Mac main by conflict-free fast-forward from
ad943db. Canonical HUD file matches the tested worker exactly; tracked tree clean.
Five persistent speed buttons become one dropdown plus pause/resume. Actual rates
and keyboard shortcuts are unchanged. Repeated speed text is removed; checked
representative width is 380 px. Isolated clean import and all five selection,
pause/resume and width checks passed. See SPEED_DROPDOWN_HANDOFF.md.

Player PID 42977 remains running and was not restarted. The last native screenshot
still shows the previous bar; live script application is not claimed. The new
control appears on HUD recreation/next launch, or supported live script reload.
No save changes or shared simulation edits; no remote push.

---

# City parity and four-distance controls integrated — September 7, 2026

INTEGRATED in canonical Mac main:
/Users/seanpurtill/Documents/Codex/tomorrow-and-tomorrow
Source 3768cbe, fast-forwarded from 06c236c with no conflicts.

Added cities use recorded settlement design and local housing/construction,
resources, health, economy and demographic updates. HUD keeps overall and selected
city population together. City map labels use names and known/estimated population.
Four recovered distances: 10,000 ft, 50,000 ft, Region, Continent; discrete scroll
steps, slower fine adjustment and bounded transitions. Vacant intact buildings
remain visible; saved sites prevent maintenance redraws moving existing homes.

Canonical clean headless import and 91/91 targeted cases pass, zero errors,
failures, skips or orphans. Logs: /tmp/city-parity-canonical-import.log and
/tmp/city-parity-canonical-tests.log. Worktree real-terrain navigation probe passes;
shutdown resource warning documented in CITY_PARITY_DISTANCE_HANDOFF.md.

Canonical test override removed. All 118 pre-existing untracked files retain their
hashes. New optional dictionary data uses existing save serialization; round-trip
verified. No schema bump or arbitrary reset. The separate READY affordable-infill
69d9db9 remains outside this integration. No remote push.

Scope limits: existing national military/fortification authority remains; distant
baked imagery and large-scale performance profiling are not delivered. Actual
completed Lean-to work still converts household forms on monthly synchronization.
Full details and recovered design provenance: CITY_PARITY_DISTANCE_HANDOFF.md.
Canonical player launched through editor Run Project (Command-B), PID 42977.
Verified command includes --path /Users/seanpurtill/Documents/Codex/tomorrow-and-tomorrow
and --scene res://local_terrain.tscn. Native screenshot confirms the normal opening
direction screen, day 0; no direction chosen or campaign advanced. Player startup
log contains no script errors. This verifies launch, not visual signoff of every city.

---

# Consolidated deaths and investigation choices — September 7, 2026

INTEGRATED `28a06ac` in canonical Mac main by fast-forward from f0416ef.
Population views summarize deaths by cause with separate paged dated details.
Scout dispatch groups destinations by category and repeated accounts by people,
retaining each exact target and visible evidence. Original records, counts, mission
behavior and save format are unchanged. See CONSOLIDATED_LISTS_HANDOFF.md.

Canonical clean headless import and 15/15 focused list/rumor tests passed with
zero errors, failures, skips or orphans. Logs: /tmp/consolidated-canonical-import.log
and /tmp/consolidated-canonical-tests.log. The broader far-order city-marching case
failed the same three assertions on unchanged f0416ef; no military fix is included.
The private test application override was removed. Player PID 36402 and editor
35944 remain running; restart normally to load this update. No remote push.

---

# Citizen production integrated — September 7, 2026

INTEGRATED source `3dbca50` in canonical Mac main, fast-forwarded from `937cd65`.
The worker was rebased without conflicts to preserve the concurrently integrated
foreign-settlement refresh and its launch record. Original development base was
`1e57003`; no foreign-refresh changes were overwritten.

Military / Supply now defaults to persistent stockpile or continuous production.
Citizen condition, effective Crafting workers, logistics and recorded workplace
condition determine output. The adjustable military crafting share also governs
legacy batch orders and leaves the remaining share to existing civilian systems.
Shortages pause, stock targets replenish after issue, priorities divide capacity,
and retooling carries an efficiency/WIP cost. Finished goods use existing stocks,
training and field delivery. Full behavior and limits: CITIZEN_PRODUCTION_HANDOFF.md.

Canonical clean headless import and six-suite 62/62 regression passed, zero errors,
failures, skips or orphans. Includes 14 new persistent-production and dock-layout
checks. Logs: /tmp/production-canonical-import.log and
/tmp/production-canonical-tests.log. Test userdata was isolated by a temporary
application override with Dummy audio; that override was removed after validation.
New test UID is included in this integration record; unrelated files are retained.

The canonical player PID 36402 was launched by the foreign-refresh task while this
work was integrating. It and editor PID 35944 were preserved. The running player
loaded the prior scripts and needs a normal restart to use production changes.
No new player/test window was launched by this delivery. No remote push.

---

# Foreign settlement refresh integrated — September 7, 2026

INTEGRATED source 0bb8659068e61cb4f4b3df1b010ed310568160ae by conflict-free
fast-forward from 1e57003 in canonical Mac main:
/Users/seanpurtill/Documents/Codex/tomorrow-and-tomorrow.
The integration-record commit contains this entry.

Foreign settlement visuals now share the authored town house assets, arranged
around courts with narrow feathered paths. Primitive houses and yard mats are
removed. Foreign architecture remains representative because city reports lack
construction records. The city sidebar opens on single-column estimates, with
separately scrolling Report, Scouting and Military tabs. No simulation/save schema
or military-order behavior changes. Source scope and limits are documented in
FOREIGN_SETTLEMENT_REFRESH_HANDOFF.md.

Canonical Godot 4.7.2 headless import passed without errors; the dedicated foreign
refresh probe passed with zero failures at all three viewport sizes. Combined
organic-town and city-intelligence regression: 22/23 passed, zero errors, skipped
cases or orphans. The sole failure is the previously reproduced base-code raid
expectation at test_city_intelligence.gd:93 (one expected, zero received).
Logs: /tmp/foreign-integrated-import.log, /tmp/foreign-integrated-probe.log,
/tmp/foreign-integrated-tests.log. All pre-existing untracked files retain their
hashes. The temporary isolated test configuration was removed.

No Godot player/editor was running before integration. User authorized integration
and loading the game. Canonical editor Run Project (Command-B on this Mac) launched
PID 36402 at gameplay/integration commit 63ef4fd, using the explicit canonical
absolute path and res://local_terrain.tscn. Startup log confirms the new-world
opening at day zero and no script errors. No save was overwritten or live session
interrupted. Graphical sign-off of the foreign view remains pending. No remote push.

---

# Settlement neighborhoods and routine raids — September 7, 2026

INTEGRATED in canonical Mac main by conflict-free fast-forward from 8536c15:
settlement neighborhoods d6bc405, routine raid correction 4ef88ea.
New household courts, actual-footprint shelter density, reserved central hearth,
feathered doorway paths and human-scale service objects replace early parcel mats,
old thick paths and oversized central props. New founding claims cluster more
closely. Existing records are not migrated; later unsupported architecture remains.

Rivals no longer invent three-person raiding parties or knowingly raid overwhelming
observed defenses. Failed raids delay later attempts. Small, outmatched home raids
use the real calendar/combat simulation without forced battle screens or pauses.
Real aftermath policy decisions remain. See SETTLEMENT_NEIGHBORHOODS_HANDOFF.md
and RAID_ROUTINE_HANDOFF.md for scope, save compatibility and limitations.

Canonical clean headless import and 174/174 selected checks passed, zero errors,
failures, skips or orphans. Seven suites: early visual 14, organic town 9,
settlement architecture 83, settlement model 43, raid policy 4, battle injuries 9,
army front visual 12. Evidence /tmp/neighborhood-canonical-import.log and
/tmp/neighborhood-canonical-tests.log. A separate broader worker run hit the
previously documented siege-withdrawal test failure; that issue remains separate.
The test override was removed. Three new script UID files are tracked with this
record; pre-existing unrelated untracked files are retained. No live player was
running at launch preparation. User requested a fresh game after completion;
canonical fresh launch is the next step. No remote push.

---

# Early primitive removal — September 7, 2026

INTEGRATED source `4f73017` as canonical `06862bc`, without conflicts.
Removed the duplicate central Lean-to Shelters tent ring and its unused primitive
mesh helper. Supported early plot forms never fall back to legacy roof/wall
massing, including when no footprint fits. Compact assets retry placement using
their authored envelope, retaining road, parcel, obstacle and land checks.
No-fit parcels can remain visually empty; construction no longer displays legacy
roof massing. Unsupported later forms and communal/service features remain.
No simulation or save-format changes. Local terrain is the shared-file hotspot.
Worker and isolated canonical runs each passed all 104 cases (12 early assets,
9 organic town, 83 settlement architecture), zero errors/failures/orphans.
Logs: `/tmp/early-removal-tests.log`, `/tmp/early-removal-canonical-tests.log`.
The temporary canonical test override was removed. User explicitly requested
that the running test campaign be discarded and a fresh game relaunched, replacing
the earlier resume-only instruction. Canonical fresh launch follows verification.

---

# Early settlement assets integrated — September 7, 2026

INTEGRATED in canonical Mac `main` at
`/Users/seanpurtill/Documents/Codex/tomorrow-and-tomorrow`.
Previous canonical HEAD: `4f68230a3c9c94064a91b3c2909ae806411f2297`.
Source: `a59910960ca453516d13432ab0df9521f6885615`.
Reviewed correction: `5c11d38faf8e716a5f9666f8bf50c9dc42fd9a7b`.
Both were integrated by conflict-free fast-forwards. The commit containing this
entry records final canonical verification; prior organic-town and military-front
sources remain ancestors.

Eight active assets now depict recorded carried shelters, rooted lean-tos,
round/earthen/rubble households, raised stores and covered workshops. They join
the earlier timber town kit. Existing resource/research recipes and completed
work supply the recorded built form; population and calendar do not repaint
buildings. Later/unknown forms are explicitly excluded from the early adapter,
including its shared-solver fallback. Identity meshes preserve imported LOD and
shadow resources. No new simulation/save authority or migration was introduced.

Three authored cultural/political studies remain INACTIVE: crafted household,
open common hall and enclosed authority hall. They are not unlocked in play.
Construction-era cultural/patronage records and appropriate public-parcel
placement are still required; current cultural or political shifts must not
instantly replace inherited architecture. See `EARLY_SETTLEMENT_PROGRESSION.md`.

Canonical Godot 4.7.2 clean headless import passed (exit 0, no script/import errors).
Combined **156/156 passed**, zero errors/failures/skips/orphans: early assets 9,
organic town 9, settlement architecture 83, settlement model 43, military fronts 12.
Evidence: `/tmp/early-canonical-final-import.log`,
`/tmp/early-canonical-final-tests.log` (canonical `reports/report_4/`).

Tests used a newly created isolated `Early_Canonical_a599109_Test` application
name with Dummy audio. That override was removed afterward; none was copied from
the worktree. All 118 pre-existing untracked files retain their exact set and
SHA-256 hashes; all three original save/settings files were unchanged after tests.
See `/tmp/early-canonical-preservation-result.txt`. No unrelated files were staged
or removed. Integration records are the only additional tracked edits.

The user explicitly requested integration and launch. No game/editor was running
before integration. Normal canonical saved-game resume is the next launch step;
no fresh-world/reset/showcase mutation is authorized or required. Offline Blender
asset plates are not game screenshots or FPS verification. Earlier schematic
military limits and the pre-existing siege-withdrawal issue remain unchanged.
No remote push. Further cultural gameplay and later architectural eras are not
claimed complete by this delivery.

---

# Military front integration — September 7, 2026

INTEGRATED in canonical Mac source; graphical review remains pending.
Canonical checkout: `/Users/seanpurtill/Documents/Codex/tomorrow-and-tomorrow`, `main`.
Previous HEAD: `577f8aa5d17310674b9d75454c2f584317c6c7aa`.
Reviewed source: `8ea1a7c73dab231bb46c1b187fcf6511c85f78a2`.
Reviewed correction and integrated gameplay HEAD: `45ce52f5605ad234a4755e84e7dd1baa4794fd0c`.
Both commits entered by a normal fast-forward with no conflicts. The commit
containing this entry records the completed canonical verification.

Bounded physical army fronts now replace soldier/mounted-general actors in the
field-army map, dated foreign sightings, eligible occupation garrisons, home
invasion/field battle observation and replay, general campaign map/replay, and
active siege city view. Metre geometry scales by .001 on kilometre terrain;
separate informational glyphs retain distant readability. Real active counts,
equipment and recorded losses determine area; recorded captives are excluded from
combat footprints without becoming casualties. No new combat, fire, control,
prisoner or save authority was added. Legacy direct-cohort controls cannot issue
orders; strategic conversation remains in GeneralCampaignScreen.

The reviewed correction includes occupation fronts in the actual terrain advance
hook, honors pause and inherited visibility, and invalidates siege geometry when
termination alone changes. **Deployment is schematic** where current battle
records lack cohort coordinates and maneuver topology. Optional renderer spatial
inputs do not constitute implemented encirclement or an independent combat solver.
Occupation ground is withheld before live communications when no dated strength
report exists. Full scope and limits: `MILITARY_FRONT_GRAPHICS_HANDOFF.md`.

Canonical Godot 4.7.2 validation, all headless with explicit canonical paths:

- Clean editor import: exit 0, no script/import errors.
- Combined front (12), general campaign (15), battle injury (9), organic town (9)
  and military development (16): **61 passed; zero errors, failures, skips or
  orphans; exit 0**.
- Actual invasion UI/replay probe: **PASS**, exit 0. Verifies zero soldier/general
  actors, responsive observation controls, one resolution, unchanged military
  export/calendar on replay, and pause.

Evidence: `/tmp/military-canonical-import.log`, `/tmp/military-canonical-tests.log`,
`/tmp/military-canonical-ui.log`, and `/tmp/military-canonical-preservation-result.txt`.
The existing siege-withdrawal failure in `test_siege_progression.gd:145` remains
unresolved: expected moving, received stationed. Worker verification reproduced
it on untouched `577f8aa` (8/9 passed). It was not concealed by graphics changes
or counted among the 61 passing canonical cases.

Organic town source `4251a3d98d6ca16af58fc2b102ecb6ecab7f2810` and integration
record `577f8aa` remain ancestors. The earlier 135-case town integration is retained;
its nine organic-town visual cases pass again alongside military on canonical main.

Temporary test configuration used the isolated
`TomorrowAndTomorrow_Military_Canonical_45ce52f_Test` user directory and Dummy audio.
No worktree override was copied. The new override and only the newly generated
front-test UID were removed after checks. All **117 pre-existing untracked files**
and all **three existing save/settings files** retain their SHA-256 hashes; the
original untracked set is exact. No unrelated file was staged, removed or replaced.
The integration-record commit changes only this document and
`FEATURE_RECONCILIATION.md`; tracked source is otherwise clean.

No Godot process was present before or after integration. No player/editor was
interrupted, no graphical test/demo or canonical game was launched, no restart or
push occurred. This verifies source integration, not rendered appearance, FPS or
that a player session has loaded these scripts. **Graphical review is pending.**
Work stops after this integration; no additional phase is started.

---

# Organic town integration — September 7, 2026

INTEGRATED in canonical Mac source, with graphical sign-off pending.
Canonical checkout: `/Users/seanpurtill/Documents/Codex/tomorrow-and-tomorrow`, `main`.
Previous HEAD: `1b9e121f481d1382eb1ecce9e7dde17b66b9e754`.
Reviewed worker/source commit and integrated gameplay commit:
`4251a3d98d6ca16af58fc2b102ecb6ecab7f2810` (normal fast-forward, no conflicts).
The integration-record commit is the commit containing this entry.

Compatible inherited single-storey timber/thatch plots now use metre-scale modular
homes along saved lanes, with small garden beds in clear leftover household ground.
Four 24 m² variants, a 12 m² small-parcel derivative and a 120 m² market hall share
bounded batches (512 buildings maximum). No-fit parcels retain existing roofs;
portable camps and unsupported traditions remain under their existing renderer.
The early primary-settlement slice replaces the legacy stage mass/density overlay
through 5,000 population and 128 recorded plots. Authoritative defenses and the
computed settlement extent remain. Houses use uniform scale 0.001, saved plot/route
identities and the same source geometry across camera distances. Inherited kit
houses persist across later population growth; no new population/economy/save
owner was added. Full scope and worker evidence: `ORGANIC_TOWN_HANDOFF.md`.

Canonical Godot 4.7.2 headless import: exit 0, no script/import errors. Combined
`test_organic_town_visual.gd`, `test_settlement_visual_architecture.gd` and
`test_settlement_model.gd`: **135 cases passed; zero errors, failures, skips or
orphans; exit 0**. This reruns the complete reviewed delivery on integrated main.
Checks cover asset dimensions/colors, supplied scale/transforms, camera/population
stability, supported history/materials, road/water/plot clearance, no-fit fallback,
condition/construction/reoccupation, preserved extent/defenses and bounded counts.
Local evidence: `/tmp/organic-canonical-import.log`,
`/tmp/organic-canonical-tests.log`, and canonical `reports/report_1/`.

A newly created temporary test override used isolated
`TomorrowAndTomorrow_OrganicTown_Canonical_Test` user data and Dummy audio. It was
removed after the run; no worktree override was copied, and no pre-existing
canonical override existed. All 117 original untracked files and all three existing
save/settings files retained their SHA-256 hashes. No player save was loaded or
written, no runtime preference changed, and no unrelated sidecar was staged or
removed. Tests exited; no Godot process was present before or after this integration.

**No graphical in-engine sign-off or FPS claim.** No second graphical game/test
window, canonical game launch, live-session interruption or remote push occurred.
The wider mature/continent land-cover transition, foreign towns, later traditions
and slope-specific foundations remain outside this slice. Headless supplied
transforms are not rendered-pixel verification. See the handoff's detailed limits.
At this earlier town checkpoint, military work had not started; the reviewed military integration is recorded above.

---

# Final Mac follow-up integration — September 6, 2026

Canonical Mac `main` integrates `60c95ee61e429ce350a1a5be530c794a185d6dfb`
(training/action feedback and ammunition gate consistency), followed by
`eb39198a83abb0d9ae3db0bb95109ab3544bf8db` (obsolete toolbar layer buttons),
both based on the earlier Mac checkpoint `515f191`.

Feedback wrapping now fits 520×67 in the canonical fixture. Exercise status,
completion and cancel availability update while hovered. Ammunition entry/catalog
use the existing authoritative research/adoption gate. Recruiting timing, production
costs, simulation rules and save schema are unchanged. Resources/Borders/Charted
buttons and unused toolbar state are removed; resource controls in Economy/Atlas
and other toolbar actions remain.

Canonical final combined training probe: 32 checks passed, zero failures, exit 0.
An intermediate rerun found a test-only stale button reference across awaited
layout frames; this checkpoint reacquires the current button before clicking.
Canonical onboarding probe passes toolbar absence/default-resource/bounds checks
but exits 1 on the pre-existing “retired Lens was constructed during normal
inspection” assertion. Worker unchanged-baseline log reproduces that Lens failure;
its separate old toolbar bounds failure is absent after cleanup. No full onboarding
pass is claimed, and no Lens/campaign/battle redesign was added to this batch.

All 117 original untracked import sidecars retain their hashes. Tests did not
save/load a player world. Existing before_river_war.save mtime 15:54:52 predates
this integration; no restore or overwrite performed. No QA override copied.
Player PID 3981 was preserved running the earlier Mac build; normal Save & Quit
and canonical relaunch are required to load these follow-ups. No restart or push
performed. This closes the authorized delegated batch; further work stays with
the coordinator. Older checkpoints below describe their historical state.

---

# Mac integration — September 6, 2026

Canonical Mac checkout: `/Users/seanpurtill/Documents/Codex/tomorrow-and-tomorrow`, `main`.
Gameplay commit: `39942ef03111cae82dc6f8975ddf2aba57feab3f`; fast-forwarded from
`7fb7e96288313099af9d5801ae5b5f36441fb627`, including input commit `f15e59f`.

INTEGRATED: native gesture and keyboard map zoom; 10 Hz presentation snapshots;
persistent scalable UI, 3D resolution, shadows and frame limit; persistent music
volume/mute on the Music bus; discoverable confirmed Quit with save failure protection.
Campaign redesign/removal remains PAUSED. No campaign or world-reset behavior changed.

Canonical Godot 4.7.2 headless checks: 24 input and 69 display/music/save/quit checks
passed, zero failures, exit 0. CPU probe passed, exit 0: per-frame schedule batches
211.423/208.960/204.248 ms versus 56.805/55.300/62.295 ms at 10 Hz for 120 paused
process calls; 120 versus 19 snapshot refreshes each. Day/population unchanged.
These are CPU workload measurements, not FPS. Presentation may lag by 100 ms.
Coordinator separately verified 67 graphical checks on Apple M1 Pro and inspected
1280×720 and 1440×900 top/bottom menu captures. No extra graphical launch by integrator.

Save writer review: payload/slots unchanged; sibling temporary file, flush/error check,
then replacement. Open/write/rename errors propagate; Save & Quit remains open on error.
Canonical probes cover replacement success, blocked temporary writes preserving prior
save, and quit failure/cancel/discard paths. No power-loss durability claim is made.

Preservation audit: all 117 pre-existing untracked `.gd.uid` sidecars and the existing
`before_river_war.save` retain their SHA-256 hashes. No QA override.cfg was present or
integrated. Generated probe artifacts remain ignored. No push or player launch performed.
Coordinator owns final relaunch. The in-game release label remains `2026.09.06.2`;
identify this Mac checkpoint by Git commit, not that unchanged label.

See `MAC_DISPLAY_VALIDATION.md` and `MAC_SETUP.md` for controls, worker evidence and limits.

---

# Current integration: 2026.09.06.2

Stable foreign district rendering, from codex/district-hover-fix based on db0419b. Independent district caching and stable visual population eliminate repeated geometry replacement from aging reports, overlapping lookout estimates and other cities' updates. Report uncertainty remains intact. See RELEASE_2026_09_06_2.md for baseline reproduction, GPU verification and exact-scene limitation.

Canonical: C:/Users/sjpur/TomorrowandTomorrow, main. Private remote: https://github.com/sjpurtill-ui/tomorrow-and-tomorrow.git. Includes all earlier integrated work. No other feature batch is active. Held prototypes remain preserved. Player PID50068 was left running with its loaded .1 scripts; normal save/exit/relaunch is needed, never a forced restart.

---

# Historical integration: 2026.09.06.1

Canonical player game: C:/Users/sjpur/TomorrowandTomorrow, main. Includes all prior integrated releases through 4d1c0e6 plus the validated contact-report and envoy-entry changes from codex/contact-dialogue. See RELEASE_2026_09_06_1.md for tests and limitations.

| Delivery | Current status |
| --- | --- |
| Earlier terrain, military units/battles, leaders, diplomacy, opening art/score, neighboring societies and continuing history | INTEGRATED through 4d1c0e6 |
| Dated contact reports and direct leader-audience entry | INTEGRATED in this release; 21 tests and actual envoy-return GPU journey pass |
| Outpost model, Blender authoring experiment, sliced vegetation, superseded military usability rewrite | HELD; preserved in their worktrees, not ready for wholesale integration |
| New feature assignments | None started during this consolidation |

Launch only with tools/launch_game.ps1. Worker prompt: WORKER_PROMPT.txt. A worker handoff is not a player release. Do not infer delivery from file dates or a branch preview. No player/editor process was running at the initial September 6 integration audit; subsequent launch evidence belongs in artifacts/player-*.log.

Everything below is historical. Old process IDs, pending items and "latest" headings describe their dated checkpoint, not the current queue above.

---

# Historical integration: 2026.09.05.16

Nearby connected-land societies in new worlds, objective-led contact investigation, and continuing history after dominance or distress. See RELEASE_2026_09_05_16.md for actual gameplay evidence and limits. Includes .15 artwork/new score and .14 general campaign. Remaining work: WHOLE_GAME_COHERENCE.md. Mac clone/access instructions: MAC_SETUP.md.

---

# Previous integration: 2026.09.05.15

Illustrated eight-choice opening/century-focus screen and the supplied Tomorrow-001.mp3 score. Source codex/opening-screen from553a9ff. See RELEASE_2026_09_05_15.md. Includes .14 general campaign and prior releases. Whole-game coherence work remains separate in C:/Users/sjpur/tt-campaign-coherence and is not part of this release.

---

# Latest integration: 2026.09.05.14

General-led Alderford War: conversation, validated objectives, simultaneous world time, finite logistics, opponent plans, actual battles, reports and replay. Enter through Military → Play General Campaign. All previous integrated releases remain included.

Canonical checkout: C:/Users/sjpur/TomorrowandTomorrow, main. Feature source: codex/general-campaign, base 2961a15. See RELEASE_2026_09_05_14.md for evidence and limits. A running older process keeps its loaded build until exited and relaunched through tools/launch_game.ps1. Worker instructions: WORKER_PROMPT.txt and WORKER_HANDOFF.md. General direction: GENERAL_CAMPAIGN_DESIGN.md.

---

# Current integration checkpoint

## Latest: release 2026.09.05.13

Scouting now explains report timing, contact prerequisites and terrain-blocked recovery.
Army marches validate land routes and report water obstruction and low supply visibly.
Includes all previous integrated releases. See RELEASE_2026_09_05_13.md.

Player checkout: C:/Users/sjpur/TomorrowandTomorrow, main. Loaded PID46888 retains
.6 until a normal save/exit and canonical launcher restart. No forced restart.
Workers should use WORKER_PROMPT.txt and WORKER_HANDOFF.md.
The resumed continuous journey reached day 612 with three natural scout returns,
without foreign contact. This batch is integrated; the broader learnability work
is not certified complete. Current evidence and limits are in PLAYER_JOURNEY_BACKLOG.md.

---
# Historical checkpoints

# Current integration checkpoint

## Latest: release 2026.09.05.11

Connected founding/time controls, supply order reviews and effective garrison
assignment. Includes all earlier integrated deliveries through.10.
See RELEASE_2026_09_05_11.md for exact coverage and limits.

Canonical player: C:/Users/sjpur/TomorrowandTomorrow on main.
Running PID46888 retains loaded.6; save and exit normally, then launch with
its tools/launch_game.ps1 or the Play Tomorrow and Tomorrow desktop shortcut.
The launcher prevents a duplicate player; restarting is never forced.
Workers: use WORKER_PROMPT.txt and WORKER_HANDOFF.md. Older prototypes remain
preserved for selective migration, not wholesale replacement.

---
# Previous checkpoints (historical process IDs and limits follow)

# Current integration checkpoint

## Latest: release 2026.09.05.10

Founding review, focused civic/government reports and diplomatic conversation /
offer / record screens. Real costs, refundable offers and waiting outcomes are
explicit. See RELEASE_2026_09_05_10.md for validation and limits. Includes .7â€“.9.

Player PID46888 retains loaded .6. Save and exit normally, then launch only with
C:/Users/sjpur/TomorrowandTomorrow/tools/launch_game.ps1. No automated restart.
Further journey work stays isolated until verified; prior worktrees are preserved.

---
# Previous integration checkpoint

## Latest: release 2026.09.05.9

Focused inquiry directions/evidence/work-priority screens, wrapping action cards,
and enemy-home occupation capacity are integrated. Details and exact checks:
RELEASE_2026_09_05_9.md. Earlier .7/.8 features are included.

The running player PID46888 retains .6. Save and exit normally, then use the
canonical tools/launch_game.ps1 to load the integrated game. Existing saves and
unrelated changes remain preserved. Further journey work stays isolated until ready.

---
# Previous integration checkpoint

## Latest: release 2026.09.05.8

Focused army command and three-step preparation, actionable recruitment shortages,
first-army intake runtime fix, and equipment manufacture with actual cost previews.
See RELEASE_2026_09_05_8.md for exact validation and remaining journey scope.

The running player PID46888 still has .6 loaded. Save and exit normally, then run
C:/Users/sjpur/TomorrowandTomorrow/tools/launch_game.ps1 to load integrated updates.
No worker preview is the player game. Save and unrelated changes are preserved.

---
# Previous integration checkpoint

## Latest: release 2026.09.05.7

Focused settlement/economy reports, nested Back navigation and actionable water
access are integrated with authoritative city-force capacity rules. Small patrols
cannot sustain a populated-city siege or automatically capture/control it after
battle. Coercive orders require effective control and capacity; old saves remain
intact. See RELEASE_2026_09_05_7.md and PLAYER_JOURNEY_BACKLOG.md.

Running player PID46888 was launched on .6 and has not been interrupted. Save and
exit normally, then use the canonical launcher to load structural updates.
Further army/new-player journey work continues separately until verified.

---
# Historical integration checkpoint

## Latest: release 2026.09.05.6

Continuous actual-world city encounters, faction uniforms and the occupation /
recovery decision interface are integrated from codex/continuous-city-encounter,
base 87d184d, integrated gameplay commit 0df3415. See RELEASE_2026_09_05_6.md for scope and verification.
Verified canonical player launch 18:01:37: PID46888, release .6, SeanTown/day9432/population405.
Canonical checks: 177 passed, two renderer-only skips; exact saved time and save hash preserved.

City approach, siege, assault, round result and return share the same live city
geometry. Friendly and enemy troops have distinct cloth and marked standards.
Occupation policies, resident conditions, movement and destructive decisions have
separate controls and explicit consequences. Existing saves remain compatible.

Outposts, sliced vegetation and unfinished Blender authoring remain HELD.
Prior worktrees and unrelated local changes are preserved. Only tested deliveries
reach main; a stopped worker's partial code is not automatically release-ready.

Use WORKER_PROMPT.txt for new workers and WORKER_HANDOFF.md for coordination.
Canonical player: C:/Users/sjpur/TomorrowandTomorrow on main, launched only via
tools/launch_game.ps1 or the Play Tomorrow and Tomorrow desktop shortcut.
A running process requires a normal save/exit/relaunch to load structural changes.

---
# Historical integration checkpoints

## Latest: release 2026.09.05.5

Battle/siege HUD delivery through worker 018cedd is integrated as 540d1d4
from c89b895 with test project settings excluded. Includes formation orders,
replay, siege controls and linked battle history. Saved notification restoration
preserves fractional time. See RELEASE_2026_09_05_5.md for validation and audit.
The sections below are historical checkpoints, not the current launch record.

Continuous actual-world city encounters and faction uniforms remain PENDING;
no implementation commit exists yet. Outposts, sliced vegetation and unfinished
Blender authoring remain HELD. All prior worktrees/local changes are preserved.
Copy-ready worker prompt: WORKER_PROMPT.txt. Player: canonical main via the
desktop shortcut. A running test scene is never the current campaign.

Verified canonical launch September5 16:56:05: PID3672, source540d1d4,
release2026.09.05.5, --resume-saved. Title and log confirm SeanTown/day9432/
population405. Exact saved time9432.03296121855 passed the isolated resume check.
The disposable siege preview PID51828 closed normally; no worker was stopped.
Original quicksave hash remains unchanged. Latest validation:174/174 cases plus
private-desktop battle/siege interaction probes and actual copied-save GPU check.

Canonical player checkout: `C:/Users/sjpur/TomorrowandTomorrow`, branch `main`.
The OneDrive project is archived. Use `tools/launch_game.ps1` or the existing **Play Tomorrow and Tomorrow** desktop shortcut. The launcher prints the commit it starts. F5 runs the game; F6 may run a preview scene.

Release **2026.09.05.4** is integrated on canonical main (gameplay `3657301`, worker `1d71971`). It includes all prior releases plus direct city orders, visible battle starts, occupation figures, retained scattered-personnel records and compact death summaries. Canonical combined validation: **118 tests passed**. Real GPU mouse probes pass; both renderer-only figure tests also pass. Player launched source `3963fde`, PID41076, September5 14:14:24; title/log confirm .4 and resumed SeanTown/day9432/population405. See `docs/RELEASE_2026_09_05_4.md` for the final launch record. A worker branch alone never updates the running player.

Current saved campaign: September 5 13:45:30, SeanTown, day9432, population405, seed1792400273. The day9049 battle left four occupation soldiers and two scattered, zero killed; pending aftermath is preserved. Previous .1/.2/.3 launch records below are historical, not the current build.

Military readability `cc5ffc5`, rumors `1672447`, Inquiry/Materials/scouting `aba8c73`, occupation `5c39a0f`/`81c38d2`, recovery `d8bf575`, final guards/version `c337a0f`, and isolated spatial report `a9dddbb` are integrated. See docs/RELEASE_2026_09_05_1.md for behavior-specific validation and limits. Canonical combined suite:125 cases pass. Outposts, unrelated economy, sliced vegetation and unfinished Blender authoring remain HELD.

## Consolidation queue â€” September 5

| Delivery | State | Location / evidence |
| --- | --- | --- |
| Strategic charts and dynamic dock tabs | INTEGRATED | Worker `4107fd1` â†’ main `12d16a3`; 64 combined tests + GPU |
| Discovered city intelligence | INTEGRATED | Worker `02a6587` â†’ main `efbff12`, follow-up `691eed6` â†’ `d418704`; 113 combined tests + 14 focused follow-up cases + GPU |
| Zoom terrain fill | INTEGRATED | Worker `1142441` â†’ main `42595fb`; five terrain cases and expanded camera runtime probe pass |
| Military usability redesign | INTEGRATED | cc5ffc5 after explicit reauthorization; live progress/focus/selection and canonical GPU checks |
| Outposts, sliced vegetation, unrelated economy and Blender authoring experiment | HELD | Preserved prototypes below; excluded from the player build |

Historical consolidation session: player PID 65696 started before the integrations; the user later saved and closed it. See the current release/session status above. Save and exit normally, then use **Play Tomorrow and Tomorrow** to load the integrated code. The shortcut's target and working directory were verified canonical. Older process references below are historical checkpoints, not current status.

## Integrated

- Existing terrain, cities, animated armies, battle generals/carnage/cameras, scouting, military progression, civics, historical people, ambitions and diplomacy: retained from the prior reconciliation through `af76241`.
- Player century focus and council recommendations: `69bc384`, from worker `4967e43`.
- Encounter terrain, opposing contact choreography, clearer battle losses and persistent injured veteran workforce capacity: `3485f1b`, from worker `64d7c7f`.

- Civic and foreign leader conversation continuity: `2dff85c`, from worker `e11302c`; 24 civic context messages, recent decisions, persistent foreign discussions and recoverable failures.
- Scout returns preserve simulation speed and keep reports available for later reading: `cf3a058`. Recruitment outcomes restored to first report page and unused HUD label removed: `4bc66f4`.

## Preserved pending work

- Frontier outposts: uncommitted isolated prototype in `C:/Users/sjpur/tt-frontier-outposts`; explicitly not ready for the game. No autoload, shared state, UI or save hooks are integrated.
- Blender contact clip authoring experiment: preserved in `C:/Users/sjpur/tt-battle-contact-landscape`; missing source blend dependencies prevented export. Existing runtime animation assets remain in use.
- Sliced vegetation: uncommitted, unvalidated prototype in `C:/Users/sjpur/tt-sliced-vegetation`, held outside the player build.
- Older worktrees are retained for traceability. Many commits were cherry-picked/reconciled, so differing hashes do not imply missing features. Do not bulk-merge their old versions.

## Ownership and delivery

One integrator owns main. Every worker starts from the current integrated main in its own `codex/<task>` worktree, reports file ownership, tests, and returns a task-only commit. A worker's preview is not a player release. Update this file and `FEATURE_RECONCILIATION.md` when integration is verified. Keep unfinished prototypes explicit; never claim all planned features shipped.

Preserve saves, existing uncommitted files and active player sessions. A running process may still contain older scripts/state. Save and restart after structural integration; do not kill a live game to make it look current. No automatic folder synchronization or copying from the archived OneDrive tree.

Copy-ready worker instructions are in `docs/WORKER_HANDOFF.md`.

## Verification at this checkpoint

The broad suite ran 522 cases (two skipped). It exposed four assertions in one recruitment-report test and an orphan HUD label. Both causes were fixed. The final combined focused run passed 66 cases with zero errors, failures or orphans (dialogue continuity, 39 UI cases, scout return speed, injuries/geometry and century focus). The earlier broad suite covered century-scale rivals, billion-population bounded state and military accounting. It was not rerun in full after the isolated fixes.

Actual save/load, opening/century renewal, GPU battle graphics and foreign diplomacy probes passed. The offline pronouncement probe now explicitly disables API access for its offline cases and passes. Worker HTTP failure/retry and four live Terra conversation turns passed before integration. Engine shutdown still reports two ObjectDB instances and one resource in the final save probe; no clean shutdown claim is made.

Revised battle demo was visibly replayed from canonical main and verified via a fresh screenshot. It is explicitly labeled BATTLE DEMONSTRATION. The separate campaign process and editor were preserved. Save and restart the campaign through the canonical launcher to load all integrated structural changes.

## Latest visual refinement

Integrated `1af3fbe` from `codex/battle-planted`: fighters stay planted after approach, use varied guarded weapon strikes and small upper-body hit reactions instead of reciprocal whole-body sliding. A 100-frame/five-second GPU temporal probe measured zero root drift while attack and guard poses changed; the battle graphics regression passed. No casualty, population or save rules changed.

## Sustained sieges and protection diplomacy â€” September 5

Canonical implementation checkpoint: `7964a29` (sieges `8077fa3`, protection/leagues `60910ec`, combined relief persistence tests `7964a29`). These changes are integrated into main, not yet loaded in a player process started at `883a8f2`. Preserve its session; save and relaunch through the canonical launcher when ready.

- Fortified home settlements can hold through sustained sieges, including the unattended threat deadline. Ordinary raids and occupation defenses keep their existing controls. A stationed field army can choose **BESIEGE SETTLEMENT** in foreign civilization actions, then use **WAR PLANNING** to continue, negotiate, seek allied relief, assault/sortie, or withdraw.
- Blockade reduces actual home harvest and the target region's share of rival food production. Existing reserves bridge shortfalls; rival aggregate demography responds after reserves can no longer bridge lost production. Supply and besieger endurance limit the investment. Army movement is locked during investment, and withdrawal uses its physical return route. Starting a siege does not transfer people or territory.
- Protection treaties and leagues require provisioned envoy negotiation and consent. Existing promises cover verified future defensive attacks, not retroactive aid for player-started wars. Independent members can disagree, leave, or refuse unaffordable relief. See `PROTECTION_FACTIONS_HANDOFF.md` for the diplomacy model and limits.
- Delivered relief is a one-use receipt, a separate allied camp, and a physically timed return. Donor military/food accounts stay separate from player population. Camps consume 0.55 Food per troop per day, matching the donor's reserved thirty-day provisions. Camps affect access and do not participate in tactical casualty rounds; all surviving camp personnel return through the same donor ledger.
- Enemy stores are never displayed as a live exact number: the siege view shows returned, dated observations or unknown. Orders precede detailed assessments in the dock. Reputation abbreviations were replaced by explicit Mercy/Fear/Grievance labels.

Validation on canonical main: **98 cases, zero errors/failures/skips/orphans**, across siege progression, real relief integration plus inherited commitments, dialogue continuity, 39 UI cases, military accounting, injuries, and century focus. Actual full-world `SAVE_LOAD_PROBE PASS`; GPU `SIEGE_UI_PASS`, capture inspected and test window closed. Import clean. The worker also supplied 96-case civilization/century regression, final 19 commitment/dialogue cases, actual persistence, live Terra negotiation and council GPU evidence before integration. No repeated full 522-case claim.

Current limits: one player siege at a time; no rival-only playable siege scenes, automatic foreign-only relief combat, ocean transport/pathfinder, or siege of a third party's occupied territory. Foreign food/demography retains the simulation's monthly resolution. The existing camp/army records remain bounded; history retains 24 sieges.

Strategic charts are newly authorized but still being implemented in `C:/Users/sjpur/tt-strategic-charts`, branch `codex/strategic-charts`, base `883a8f2`. They are not in this checkpoint. Its held vegetation prototype remains held, as do outposts and other unrelated economy prototypes.

## Scouting archive and military audit â€” September 5

Integrated scout worker `6e6b6d0` as `d0315c9`. World / Scouting shows up to three highlights from the latest eight returns plus **Expedition Archive**. The archive renders five cards per page, supports saved-text search (including exact `party N` / `day N`), All/Findings/Routine/Losses/Unread filters, and significance/newest sorting. Each card opens the retained full report; Back to Archive restores the query, filter, sorting and page. Routine evidence is summarized on the findings page and retained in Journey & Accounts.

Full report retention increased from 24 to 256; existing reports are preserved and no knowledge/deposit/formation simulation was changed. Unread metadata begins with new returns; older records have unknown review status until explicitly opened. Reports already evicted from older saves cannot be restored. Earlier map/contact/resource knowledge remains under its existing authorities. The UI states the retention limit rather than implying an infinite archive.

Large repeated cover art is removed from the findings page. Journey details may show a 112px illustration selected only from saved terrain words. Forest, river, mountain and desert records select matching existing art; absent terrain evidence gets no decorative fallback. The actual saved route chart remains available. No new illustrated landmarks or map evidence were invented.

Canonical validation: 71 cases pass with zero errors/failures/skips/orphans (archive, 39 existing UI, return-speed, siege and real relief tests). GPU archive passes at the real 540px dock width: 256 reports, 5 rendered cards, 29 search matches, empty-result behavior. Worktree GPU navigation also verifies opening a report and returning preserves search/page. Probe windows closed; player/editor preserved. No-autopause behavior remains intact.

Military audit `docs/MILITARY_CONSOLE_AUDIT.md` and `tests/military_console_audit_probe.tscn`: reproduced hover-induced frozen progress labels, fractional work versus calendar-day ambiguity, and condition-based BROKEN semantics. Proposed plain-language status/grouping fixes are documented. No military usability fix is claimed integrated by this audit.

Historical session at this earlier checkpoint: PID 54444 at 883a8f2; see the top of this document for current session status. Save and relaunch through the canonical launcher to load later features; it was not silently restarted. Newly authorized charts, discovered-city intelligence, and measured zoom-fill work continue in separate worktrees with explicit shared-file ownership. Held outpost/economy/vegetation prototypes remain held.

## September 5 â€” independent city intelligence

Worker `02a6587` integrated as `efbff12`. Foreign cities use the existing five strategic urban regions per polity, independent markers and hit targets, and per-observer dated reports. Discovering one does not expose the others. Estimates age and remain frozen between observations; scouts, envoys and army runners deliver reports through their return paths. AI player-city knowledge uses the same evidence model and gates targeting. Existing secondary-city defense simulation remains absent rather than fabricated; the military campaign still targets the player primary city. Regional food outlook is not a per-city warehouse ledger. Full bounds, save compatibility and limitations: CITY_INTELLIGENCE_HANDOFF.md.

Canonical eight-suite 113-case regression passes. This includes actual city-intelligence and strategic-history save/load coverage. The worker's full 118-case civilization/century run finished with 117 passes and one founding-focus visibility failure, zero runtime errors. Both 36,500-day scale simulations passed, including billion-population bounded state. The one-line visibility guard was restored in `d418704`; the failed case plus all 13 city-intelligence cases then passed canonically (14/14). The entire 118-case suite was not repeated after that isolated fix. Canonical city-report GPU capture and three independent hit targets pass; probe exited and stderr is empty.

## September 5 â€” zoom terrain streaming

Worker `1142441` integrated as `42595fb`, preserving independent-city marker/hit-test code, chart daily sampling, and the scouting archive. Obsolete camera jobs are canceled, a geographic coverage pass precedes full detail, four completed meshes and their river-height fields are cached, and the world mesh remains visible outside the streamed rectangle. Save format unchanged.

Canonical five terrain cases pass; expanded camera probe passes smooth/anchored zoom, north reset, cancellation, coarse-to-fine scheduling and bounded exact mesh reuse. Camera probe shutdown reports two ObjectDB instances and one resource still in use; no clean-shutdown claim. Worker GPU comparison measured zero uncovered frames versus up to 338, and cached revisits of 40â€“81ms versus seconds. Cold fine detail still takes roughly six seconds, and some frame spikes remain. Synthetic million-person fixture is not a loaded mature campaign benchmark. See ZOOM_PERFORMANCE_HANDOFF.md for comparable measurements and limits.

All agreed completed deliveries are integrated; no further feature expansion is underway for this consolidation. Military usability and older unfinished prototypes remain HELD.

Final canonical GPU zoom run completed all eight transitions with zero uncovered frames; screenshots inspected. Its test process exited. Like the camera probe, it reports two ObjectDB instances and one resource in shutdown cleanup; no new script/parser errors appeared. This capture run is visual/integration evidence, not the screenshot-free comparative benchmark above. Player PID 65696 remains the only canonical campaign process and was not restarted.


September 5 follow-up integrated: fd7b360, version 2026.09.05.2. Reported-settlement close rendering and complete-batch recruitment/readiness corrections. Canonical 78-case regression and both actual-save GPU probes pass. See docs/RELEASE_2026_09_05_2.md for current campaign blockers, evidence, and limits.


Release2026.09.05.3 integrated187bea5: polished foreign city reports, named city army arrival, explicit scout labels and successful deliberate attack/siege starts war without declaration. Canonical88tests +actual-save GPU verification pass. See docs/RELEASE_2026_09_05_3.md; peacetime trespass response remains unimplemented.
