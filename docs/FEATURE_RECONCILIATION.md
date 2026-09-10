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

## September 9 — distinctive civilizations, visible envoy journeys and local AI setup

INTEGRATED `fae9761` (source `6f1500b` plus validation corrections) by conflict-free fast-forward into canonical Mac main from `a31088e`. New worlds receive unique civilization and city names and distinct flags; map cards show the reported controlling civilization. Registering a player home no longer relocates three rivals nearby. Envoy dispatch retains the destination, schedule and map focus; returned outcomes open in a paused leader conversation. Nested settings preserve the prior speed, and speed shortcuts cannot bypass a conversation pause. The connection panel accepts a session-only API key locally and distinguishes missing credentials from HTTP failures. Foreign leaders share civic personality axes and have priorities that affect strategy and negotiations.

All **69 canonical focused tests pass**, zero errors/failures/skips/orphans, exit 0 (`/tmp/tt-civ-canonical-tests.log`). Across the source checkout, **138 named tests are verified** including the full century and billion-population cases and targeted reruns after correcting an obsolete instant-training fixture. The foreign-diplomacy integration probe and local mock HTTP contract probe pass. Flags were inspected at map sizes; dialogs received headless layout checks. No live API connection or native player-window visual audit is claimed. Existing names/locations remain on load; new naming applies to new worlds. The canonical test override was removed.

**HELD:** `1e918e3` in `/Users/seanpurtill/Documents/Codex/tt-civ-identities`, branch `codex/distinct-civilization-identities`, contains incomplete shared demographics and real-city records. It is excluded. Full human/AI rule parity, real opponent founding, shared city economies and multiplayer readiness are unfinished. No artificial population slowdown is delivered. The existing iteration heartbeat now prioritizes completing those shared systems; networking is explicitly outside scope. See `CIVILIZATION_PARITY_AUDIT.md` and `CIV_IDENTITY_DIPLOMACY_HANDOFF.md`.

No player or editor was stopped or launched. The earlier standalone player had already exited when checked. The release is being prepared for the next user-requested launch.

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

## September 8 — service-wide training indicators

Integrated `a3f1300`; all 79 relevant canonical tests pass. Navy/Air training now reports the entire service with four visual counts, actual crew attendance and grouped pause reasons. Stale activity clears after base/equipment failures and proficiency-target completion. No save migration, rate changes or player restart. See SERVICE_TRAINING_OVERVIEW_HANDOFF.md.

## September 8 — scout route planning

Integrated `77049fc`; all 60 focused canonical checks pass. Automatic route selection validates before departure, searches all compass sectors and allows local surveys. Cards show actual planned outward distance with return/survey time included. No live discoveries, unearned safety rating or quoted-route reroll. The existing peace-incident fixture failure is documented separately in SCOUT_ROUTE_PLANNING_HANDOFF.md. Saves and ongoing missions remain compatible; no player restart or graphical probe.

## September 8 — automatic crew training recovery

Integrated `1683ba1`; all 74 relevant canonical tests pass. Navy/Air repairs finish before training resumes, training suspension permits essential repairs, and repeated daily checks preserve attendance. Rival messages no longer overwrite player staff reports; roster activity exposes actual repair shortages and travel. Existing saves remain compatible. No player restart or graphical probe. See SERVICE_TRAINING_RECOVERY_HANDOFF.md.

## September 7 — joint operations and modern architecture integrated

INTEGRATED source `f4a7d78` / `f466f20` from `codex/fifty-units` through merge `f996fa6`; integration fixes `2b2e3ea` and `f66bfcb`. This supersedes the held `33ab016` milestone. Canonical Mac checkout is `/Users/seanpurtill/Documents/Codex/tomorrow-and-tomorrow`.

The player build now contains 50 neutral land archetypes, 21 naval types and 16 air types; researched production, city-funded bases, aggregate crews, carriers, transport, geography-checked sea routes, player-drawn operating polygons, mission effects, rival industrial/combat operations, fleet screening and submarine detection. Detailed settlement architecture adds 24 masonry/industrial/modern building families through the shared saved-parcel placement system, named construction research and paid upgrades. Historic districts retain their built form.

Combined canonical validation: **139 tests passed**, zero errors/failures/orphans, across 12 suites. After the final keyboard/map/manpower integration refinements, all **30 joint campaign and city-intelligence tests passed** again. The documented baseline raid-intelligence fixture now provides viable military strength explicitly, preserving all hidden/stale-intelligence assertions. Actual current-save compatibility restored day 25512, population 777, seed 1792946605 in isolated test userdata.

Canonical editor Run Project launched version **2026.09.07.1**, player **PID 60507**, from code commit `f66bfcb`. Process command line explicitly contains the canonical absolute project path, `res://local_terrain.tscn` and `--resume-saved`. Startup log confirms the saved world and contains no script errors. Previous player sessions were saved and quit through their own UI. No worker/test scene was shown as the player game. Temporary test-userdata and editor-resume settings were removed.

Live checks: city flags/colors and Military entry cards visible; **Shift+F6** opens Naval & Air Command; **Escape** returns directly to the map. The operations screen shows the home city, foreign names/estimated populations, separate labels, the researched War Canoes choice, base/production controls and polygon-drawing controls. The final player remains paused on that screen. Polygon drawing and mission execution have headless behavioral checks; native mouse drawing was not verified because embedded-window coordinate automation is unreliable. Modern mesh/placement behavior is tested; the current early-era campaign was not artificially advanced to modern architecture for a visual claim.

Limits: HOI4 numerical/combat-system parity is **not complete**. Combat remains aggregate and daily, with simplified fleet screening, detection and air performance. Rival overseas invasions/supply convoys, full doctrine and component-design simulation remain outside this integrated iteration. See `docs/FIFTY_UNITS_HANDOFF.md` for exact behavior and scope. Prior production clarity `da9f917`, flags `a0ff5d5`, staffing `fab7843`, and foreign-label/intel fixes are included in this relaunched player.

## September 7 — army staffing clarity

INTEGRATED `fab7843` by conflict-free fast-forward from `1589e37`. Recruit & Train shows available recruits, training places and work allocation separately. Per-city watch/training priority actions replace the vague allocation detour and retain GovernmentPeopleSystem authority and occupation guards. Eleven targeted and existing recruitment tests pass; no save or calculation changes. See ARMY_STAFFING_HANDOFF.md. The city flag update `a0ff5d5` is included in this base. Player PID 47271 has not been restarted; receipt by the live session is not claimed.

## September 7 — city civilization flags

INTEGRATED `a0ff5d5` by conflict-free fast-forward into canonical Mac main from `86f2971`. City flags, name colors and pins share reported civilization identity at all four camera distances; owned labels use the founding banner. Three isolated targeted checks pass, including stable refresh sizing and changes of reported control. No save schema changes. See CITY_FLAGS_HANDOFF.md. Player PID 47271 is still running; no restart or receipt of these changes by that process is claimed.

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

# General campaign integration — release .14

Source codex/general-campaign from canonical 2961a15. Added the bounded authored Alderford War without replacing existing terrain, civics, force ownership or combat resolution. Verified full victory/defeat, real UI objective/withdrawal/recovery/save loop, 56 combined tests and seven actual Terra exchanges. See RELEASE_2026_09_05_14.md and INTEGRATION_STATUS.md. The full historical campaign remains outside this slice.

# Canonical feature reconciliation — 2026-09-05

Latest consolidation: release 2026.09.05.5 integrates the battle/siege HUD series
through 018cedd, excluding its isolated project settings. The branch audit found
other differing historical hashes already reconciled as described below. See
RELEASE_2026_09_05_5.md and INTEGRATION_STATUS.md for current scope and evidence.

The playable checkout is `C:/Users/sjpur/TomorrowandTomorrow`, branch `main`.
This record distinguishes recovered behavior from old implementations that have
been superseded. A newer file timestamp is not a reason to replace an entire system.

## Civic and leader work

Reconciled the civic changes from `d085c74` through the consolidation in
`d0f2ab3`, and the statistical decree changes in `b5d794d`, into the current
GovernmentPeopleSystem settlement conversation path:

- Conversational first-person responses, eight recent turns of bounded context,
  and adequate response budget. Questions remain discussion; only explicit
  instructions reach deterministic execution checks.
- Clear orders proceed without repeated mandatory ethical confirmations or a
  personality veto. Leaders retain objections and relationships; population,
  resources and institutional capacity still constrain implementation.
- Six validated immediate metric estimates, with uncertainty and causal reasons.
  Estimates are simulation inputs, not measured causal facts. Food, water, labor
  and production continue through their existing systems.
- Exact counted actions affect the eligible aggregate population once, record
  their actual result and death ledger linkage, and do not become standing policy.
- Follow-up reports distinguish immediate receipts from observed later changes.
  Existing saves retain their records; no retroactive events are fabricated.

The old separate `LeaderConversation` autoload and office popup are not restored:
the current settlement conversations already own named leaders, history, intent
clarification, execution and follow-up reports. Restoring the alternate UI would
create another authority and a separate conversation store. The older standalone
draft/Issue panel itself is not part of the current interface.

Validation: 71 civic/directive/government tests, city-civic runtime probe, and
whole-game save/load probe passed. The live paid API probe is available but was
not run during this reconciliation. Existing renderer/ObjectDB shutdown leak
warnings remain in runtime probes.

## Other scope

Animated armies, historical figures, ambitions, community networks, diplomacy,
current terrain and the subsequent graphics work were integrated before this
pass. Expedition findings, mobility and billion-scale verification were integrated from the scoped handoff below. Combined validation follows.

See `WORKER_HANDOFF.md` for ownership, worktree and integration rules.

## Combined canonical verification

After civic `fb5c118` and expedition/mobility commits through `95a6b0d`:

- 272/272 tests across nine suites passed (report 728, 3m14s), covering civics,
  directives, government, expedition findings, civilization, military development,
  settlement architecture and warfare presentation. The civilization suite
  includes a century with billion-person populations and bounded save records.
- Canonical population-scale probe passed with nine cohorts and one formation;
  whole-game save/load passed after the combined changes.
- GPU expedition report probe passed; both report and journey captures inspected.
  Five painting assets are imported. The real return handler opens the same
  report provider, also reachable through World reports.
- GPU warfare-map runtime probe passed, including current route geometry and hover.
- Existing shutdown resource leaks remain. No paid API call was made by this pass.

The worker's additional 133-test demographics/government/architecture sweep passed
in its isolated checkout; this is supporting evidence, not additional canonical
coverage claimed on top of the 272 tests above.

## Expedition, mobility and scale handoff (worker evidence)

# Feature reconciliation — September 5, 2026

Worker checkout: `C:/Users/sjpur/tt-feature-reconciliation`, branch `codex/feature-reconciliation`, base `9c0aaacd7bc6c37dcbc705ead87cccf06119f157`.

This is a feature inventory, not a claim that a passing subset proves every game feature complete. Canonical integration and editor launch belong to the integrator.

| Work | Evidence and disposition |
| --- | --- |
| Billion-scale population, resources, food, labor and military counts | Already in base. Population probe passes at one billion, nine cohort keys, one 500,000-person formation after one million recruits, and three consequence days. No ordinary citizen registry restored. |
| Bounded civilization simulation | Already in base. Century probe passes: 23 rivals, 115 regions, 1,217 turns, bounded events and 446,929-byte exported civilization state in this fixture. |
| Bounded named leaders | Preserve current GovernmentPeopleSystem and its 96-person ceiling, rather than restoring the superseded institutional-only or 512-citizen implementations. |
| Expedition chronicles and route chart | Omitted from base; restored selectively from 818d9d8, followed by later decisions. Two report tabs, actual days away and grounded discovery records. |
| Five expedition paintings | Omitted from base; restored from 12a60ea plus original dawn cover. Static reusable art, no runtime image-generation charges. |
| Retired illustrated landmarks | Apply 1d7b045 after the chronicle to preserve the later retirement decision; old artwork is archived, not deleted. Existing genuine findings survive load. |
| Mounted scout pursuit and sustained march speeds | Omitted from base; restored from 8cb853b. Army proximity, speed, readiness and scout evasion affect interception; mixed columns respect their slowest element. |
| Scout hover presentation | Selectively reimplemented from 37d92d9/b9c9ae3. Hover-only route captions replace permanent labels. Preserve newer grounded ribbons, correct directional triangles, layer priorities, scale cache and zoom handling instead of replacing the whole renderer with the old overlay. |
| Battle view and unit builds | Already in base: 27 models / 108 animation clips verified. Military UI exposes Inspect in 3D and View Battle. Historical appearance variants are not all separate recruitable combat classes. Battle probe passes with a 192-figure ceiling. |
| Decree statistics / remaining civic checkpoint | b5d794d and d085c74 audited separately by canonical integrator; do not restore an obsolete duplicate LeaderConversation authority. Not claimed complete by this worker. |

## Verification in reconciliation checkout

- Import completed; no parser failure observed.
- Expedition, civilization and military-development suites: 92/92 pass. Civic implementation suite separately: 4/4 pass. An initial mistyped civic test path was corrected and rerun; it was not counted as coverage.
- Population and civilization scale probes pass (figures above).
- Scout gamble dispatch/return probe passes; status calls measured in microseconds in this fixture.
- Warfare runtime passes headless and GPU, preserving route geometry/direction tests and asserting hover account presence / permanent labels hidden.
- All 27 model imports and 108 animated clips pass verification.
- Battle graphics probe passes combat invariance, metadata, casualties, reset, retreat, pause, save and fixed visual count.
- Whole-game save/load probe passes. Only dedicated QA slots used; player saves and running session untouched.
- Actual report dock GPU probe passes and captures both tabs and four alternate paintings. Inspected `artifacts/expedition-report.png` and `artifacts/expedition-journey.png`.

Existing Godot shutdown texture/RID/ObjectDB leak diagnostics remain on several graphical probes. Passing assertions do not establish unlimited-world performance or zero leaks. Paid API behavior is not covered by these offline checks.

## Integration

Review and cherry-pick this branch's task commits in order. Shared hunks include civilization_system.gd, military_campaign.gd, local_terrain.gd, dock_blocks.gd and save_load_probe.gd. Preserve newer integrator civic work when resolving. Do not copy whole systems from the consolidated/archived branch. Before announcing shipment, verify the main report component exposes both tabs, five asset paths exist, the actual return handler opens that component, and the canonical combined tests pass.

User requested visible Godot editor and game with supported built-in external-script reload / live scene synchronization after integration. Preserve any unsaved current session; ask before replacing it if necessary. Worker did not launch a preview as the player game.


## Combined checkpoint: century, battle, conversation and scout returns

The authoritative main now includes `69bc384` (century choices), `3485f1b` (battle terrain/contact and persistent veteran injuries), `2dff85c` (leader dialogue continuity), `cf3a058` (noninterrupting scout returns) and `4bc66f4` (first-page recruitment outcomes/HUD cleanup). Earlier eight-turn civic context is expanded to 24 messages plus recent decisions. See INTEGRATION_STATUS.md for validation and explicit held prototypes; no folder overwrite or blanket old-branch merge was used. Player saves and live campaign were preserved.


## September 5 — sustained sieges and independent protection leagues

Integrated siege worker `1f10c0d` as `8077fa3`, diplomacy worker `4ce8a64` as `60910ec`, and real relief/save integration tests `d727f9d` as `7964a29`. Canonical 98-case checks, world save/load and GPU siege UI pass. These extend the existing food, population, army and ForeignDiplomacy owners rather than creating duplicate simulation authorities. Main retains all previous terrain, battle, injury, century and dialogue changes. The open player from `883a8f2` is preserved and needs a save/relaunch to load structural changes. Details and limits are in docs/INTEGRATION_STATUS.md; chart work is pending, held prototypes remain excluded.


## September 5 — scalable scouting archive

Integrated `6e6b6d0` as `d0315c9`; military console audit `ee0283b` as `de1d41d` is evidence/recommendations only. Searchable five-card pages, 256 full reports, explicit review/retention semantics, compact recent highlights, terrain-evidenced detail-only art. Canonical 71-case checks and GPU archive pass; prior siege/protection code preserved. Chart/city-intel/zoom-fill workers continue separately. See INTEGRATION_STATUS.md for checks, limits and restart status.

## September 5 — consolidation of tested deliveries

Worker strategic charts `4107fd1` integrated as `12d16a3`. Both scout_archive and trend_chart renderers are retained in the shared dock; dynamic provider tabs expose Economy Wealth and Military Supply. Canonical combined 64 cases pass, plus muted GPU chart layout/range/hover checks. The player session is preserved; a normal save/exit/relaunch is required for newly integrated scripts. See INTEGRATION_STATUS.md for the current queue and held unfinished work.

City intelligence `02a6587` integrated as `efbff12`, preserving archive retention/review and chart sampling. The combined eight-suite 113-case regression passes. Independent discovered cities and reciprocal dated evidence extend existing simulation/save owners; see CITY_INTELLIGENCE_HANDOFF.md for scope and limits.

Follow-up `691eed6` → `d418704` restores the existing intelligence threshold for exposing founding focus. Canonical targeted 14/14 cases pass. Worker century and billion-population runs passed; its full run was 117/118 before this isolated guard fix, not an unqualified 118/118 claim.

Zoom streaming `1142441` → `42595fb` cancels obsolete work, fills geography before detail, retains outside coverage and caches four completed meshes. Canonical five terrain cases and expanded camera runtime probe pass; existing city/chart/scout hooks preserved. Full limits and benchmark evidence are in ZOOM_PERFORMANCE_HANDOFF.md. The military usability rewrite remains held and is not part of this release.


## September 7, 2026 — main-map Navy and Air correction

Integrated 7fb5dc2, fecf99f, ff2f02b and 5ae5714; release 2026.09.07.2. Navy and Air have separate panels and service-specific operational rules over the actual terrain camera. The secondary map is removed. Readiness, commissioning quotes, recipe-funded local repairs, airbase crowding, airborne versus port targeting and physical naval contact/fire ranges are implemented and tested. All 63 combined checks passed; the final layout refinement passed 34 relevant cases again. Canonical player PID 67340 runs code 5ae5714 with the explicit project path and resumed campaign; both final panels checked live, paused on Air Command. No new required save fields. Native pointer drawing remains unverified; headless tests cover projection and input behavior. Exact HOI4 numerical parity remains unfinished. See MAIN_MAP_SERVICES_HANDOFF.md and INTEGRATION_STATUS.md.


## September 7 — carrier order correctness

Integrated 947ad09 on canonical main: rebase cancels obsolete carrier ferries; carrier-wing stand-down stays on deck; force reorganization and disbanding require actual home-base arrival; carrier merges preserve pending wing references and carrier removal cannot orphan wings. All 38 relevant canonical tests pass; no save migration. Running player/editor untouched; next normal launch receives this pass. See CARRIER_TRANSITIONS_HANDOFF.md.


## September 8 — carrier wing markers

Integrated 24d2d18 and fixture correction ec1cd9c. Carrier-wing drawing, selection and route origins follow actual carrier positions; detachment restores independent position. Corrected canonical run passes 34 tests; no save changes, no player/editor interruption. See CARRIER_MAP_HANDOFF.md.


## September 8 — military order selection

Integrated 6145949. Region and mission choices survive command-panel refreshes and failed orders, while explicit force selection follows the existing assignment. Current order is labelled separately. All 36 canonical checks pass; no save changes or player restart. See MILITARY_ORDER_SELECTION_HANDOFF.md.


## September 8 — easier panel closing

Integrated e493ab5; 11 canonical checks pass. Bare map dismisses docks/help without issuing world orders; report backdrops dismiss supported screens. Military drawing remains functional. Map-help text and close label clarified. Running new campaign left untouched after user activity was detected; next launch receives the change. See MAP_DISMISSAL_HANDOFF.md.
