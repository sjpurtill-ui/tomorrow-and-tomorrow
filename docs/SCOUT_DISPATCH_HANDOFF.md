# Scouting departure correction

Base: `2835f00b4114c9aa0241822e77ad3a4c5ecffc61`.
Worktree: `/Users/seanpurtill/Documents/Codex/tt-scout-dispatch`, branch `codex/scout-dispatch`.

## Problem and behavior

The previous release required spare reception capacity before choosing any recruitment destination. It also required a known city, tried only that one destination, considered only 30/90-day staff trips, and waited if the full proposed party could not be supplied. Consequently a standing recruitment allocation could leave everyone at home. The user's closed session was not saved recently enough to identify its particular active blocker; the code paths and their reproductions are established independently.

Recruitment/influence staff now visit known peaceful communities even when invitations must wait. Without a usable known destination they physically search for communities, with no invented households or remote revelation. A visit can exchange practices and build goodwill. Household invitations still require actual source people, a better offer, home reception capacity and paid travel; home overcrowding does not magically disappear. Consolidate pauses invitations rather than peaceful visits.

Staff use smaller parties that fit available adults and provisions, keep the seven-day civilian food reserve, and consider the existing 180/365-day budgets when shorter trips cannot serve the objective. They check up to three reported destinations per review, rotating beyond inaccessible ones, then try a connected-ground search. Targeted route plans are cached between duration quotes and cleared by geography-authority changes. Frontier search keeps its bounded 96-node work budget, scales its coarse step with longer travel allowances, and retains a fine fallback for small islands. No promise of exhaustive global pathfinding is made.

The Scouting sheet separates departure status from invitation readiness, names specific housing/food/water/administration shortages, shows the next staff review, and correctly labels targeted visits as Recruitment & influence. No player needs to spam departure controls. Policy review remains weekly; new policy is considered on the next game day. Physical return rules, troop commitments and the shared human/opponent simulation remain intact.

## Compatibility and ownership

Existing active missions retain their route and timing. The optional validated `target_cursor` field defaults to zero in older saves and preserves fair destination rotation after reload. No schema bump or population conversion. Scope: `scouting_staff.gd`, `society_exchange.gd`, `civilization_system.gd`, scouting sheet, two existing test suites, release version/docs. No terrain rendering, government labor authority or military orders were changed.

## Verification

Worktree verification: **113/113 cases pass**, zero errors, failures, skipped cases or orphan nodes, across scouting staff, society exchange, scout routes, city intelligence, civilization ownership/save continuation, diplomatic journeys, scout archives and performance invariants (`/tmp/tt-dispatch-regression.log`, 127.023 seconds). The new cases cover full-home visits, first-contact search, distant destinations, blocked nearest routes, smaller provisioned parties, clear shortages, a more distant exploration frontier, narrow/large panel containment, and a physical visit returning knowledge without unauthorized immigration. No new live frame-rate or visual-art claim is made. No live player or editor was stopped; the user closed the game. Tests use the private `TomorrowScoutDispatchTests` user directory and explicit worktree path. Remove the owned override before packaging. Normal release target: **2026.09.10.4**.

Integrated gameplay commit: `96b4f371f9081e854395bfef3166a424556677d7`. Canonical confirmation: **52/52 scouting, exchange and route cases pass**, zero errors/failures/skips/orphans (`/tmp/tt-dispatch-canonical.log`, 39.144 seconds).
