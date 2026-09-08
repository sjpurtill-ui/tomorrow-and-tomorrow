# Command hierarchy and autonomous land objectives

INTEGRATED as `d220fa1`; all 163 canonical checks also pass in `/tmp/tt-command-delivery-canonical.log`. Base `41d410bcd89a32cd173073a118f217cfc765a498`; branch `codex/command-hierarchy`; worktree `/Users/seanpurtill/Documents/Codex/tt-command-hierarchy`. The integration record supplies the delivery commit and canonical verification.

## Player behavior

- Military → Army Command, or Forces → Command on map, opens a hierarchy over the real terrain/camera. Navy and Air have separate hierarchy panels and retain their own operating-area missions, bases, equipment and training systems.
- Expand Army/Corps/Division/Regiment or Brigade/Battalion/Company/Platoon/Squad/Team. Browsing is read-only. Giving a subordinate an order physically detaches its actual personnel, equipment and ammunition. Select a headquarters to order its subtree; a later child order creates an exception. Organization groups existing commands under higher headquarters.
- Draw a boundary on the main map, select a command and give a defend/patrol, encircle, defeat, capture-city, besiege/occupy, raze-infrastructure or withdrawal objective. Leaders move on calendar time, seek observed opponents, attempt flanks, hold contested approaches and withdraw when supply/morale fail. Explicit city attacks authorize crossing that target civilization's border; other orders respect neutral borders.
- Existing rival aggregate formations physically react to nearby hostile armies. Contact front ribbons depend on actual opposing positions/frontage; a drawn zone grants no territory. Encirclement samples 24 escape directions and requires supplied forces to cover them.
- Nearby commands with the same objective can fight together. Cohort losses, disability, prisoners and equipment changes return to each original force without duplicating people. Up to 32 independent commander battles advance daily and persist across saves. Engaged commands cannot march, subdivide, disband or join training through legacy controls.
- Commanded city assaults and siege assaults do not force open a battle/aftermath screen. Siege staff choose when pressure supports an assault. Captured cities receive real occupation detachments; razing follows the existing control-gated infrastructure policy, not automatic deletion of city population.
- The hierarchy refreshes counts in place, preserves expanded branches and supports bare-map/Escape/Close dismissal. Remote markers and picking share dated runner reports; modern communication retains live reporting.

## Validation

Godot 4.7.2, headless, explicit worktree path, isolated userdata `TomorrowCommandHierarchyTests`. All **163 tests pass**, zero errors/failures/orphans, in `/tmp/tt-command-delivery-worktree.log` (12 suites): command hierarchy, command city operations (including inherited siege checks), training strategy, joint operations, joint campaign loop, main-map services, map-panel dismissal, city direct orders, general campaign, field-route safety, military training accounting and army staffing actions.

New behavioral checks cover lazy 120,000-person hierarchy browsing; detached people/gear/pool conservation; parent/child orders; invalid-order atomicity; daily clock/movement; land routing, cached-route revalidation and water rejection; neutral borders; encirclement and dynamic contact; rival physical response; shared-battle casualty accounting; simultaneous engagements and save restoration; automatic city/siege/raze execution; service mission rollback; stable tree items; and panel bounds at 1280×720. Native pointer interaction and rendered visual quality were not assessed in this pass. No graphical probe or player restart occurred.

The existing city-direct-order test fixture now supplies and clears its own land authority; it previously depended on terrain authority left behind by another suite.

## Compatibility and integration

New optional `military.command_hierarchy` state stores organization, zones, contact ribbons and ongoing commander battles. Older saves initialize an empty hierarchy over their existing real forces. Full MilitaryCampaign JSON round trips pass; malformed cycles, force references and duplicate battle participation are rejected without changing live state. Foreign response positions persist in existing aggregate formation dictionaries. No population/labor authority changes, project settings changes or migration of old terrain.

Shared hotspots: `military_campaign.gd` (ownership, battle accounting, save hooks, command cap), `civilization_system.gd` (physical response position), `local_terrain.gd` (managed-battle attention), `joint_operations.gd` and existing HUD entry points/overlay. No concurrent canonical changes were present at review time. Commit only these task files and the new modules/tests; generated UID files and test overrides are excluded.

## Limits

- This is aggregate daily combat and local contact geometry, not complete HOI4 province control, logistics or numerical parity. The existing siege system still permits one active siege and gates new land engagements while that siege is active.
- Independent land forces are bounded at 256 and organization at 1,024 nodes; browsing virtual subdivisions creates no records. Detached units preserve their real equipment mix rather than assuming historically fixed templates.
- Rank labels express the game hierarchy. Every small unit does not create a new HistoricalFigures person. The optional brief is a saved note beside a supported objective, not a new natural-language order interpreter.
- Occupation detachments remain in the existing occupation ledger/roster rather than becoming independently selectable hierarchy leaves. The existing 50 land archetypes are reused; this change does not add a future mech catalog.
- The running player process was not restarted. Canonical integration and a normal project restart are required to load the new command system.
