# Early founding travel, scouting clarity and visible exploration returns

READY. Worker delivery; not integrated into canonical `main` or the player build.

Worktree: `/Users/seanpurtill/.codex/worktrees/early-scouting-clarity`

Branch: `codex/early-scouting-clarity`

Base: `e6c447c3f47df24d7c7342a3c0bc0f5f1f8570b2`

Prerequisite feature commit reconciled onto this base: `c4ff4f6` (the artifact collection mechanics originally delivered by `94393c3`).

## Player-visible behavior

Before the first settlement, the founding convoy can be ordered directly into true black-map ground. A moving convoy now exposes `HALT & FORAGE` in the Settlement view. This fixes the camp at the convoy's current physical position and switches it from reduced moving forage to the existing stationary local food simulation. Food workers therefore gather from the actual camp terrain while time advances. Replenished stores increase the allowed distance of the next leg; an overlong route explicitly tells the player to choose a nearer black-map point, camp, forage and continue. Map help and status text state that black-map travel and staged foraging are available.

The Travel Council now gives a live provisions-based verdict: `CONTINUE`, `CAMP SOON`, or `STOP & FORAGE` while moving, and `KEEP FORAGING` or `READY TO CONTINUE` while camped. It compares projected endurance with the remaining leg, shows approximate next-leg reach, and raises one named-advisor report when a camp rebuilds a viable reserve. Advice never moves or stops the caravan automatically.

Recruitment is no longer an unexplained repeat lottery. The scouting panel now distinguishes searching from visiting a known community, names the nearest known target, reports whether invitations are viable, and gives the actual blocker: housing, water, food, a weaker offer, or insufficient trust. Recruiters still move real households rather than creating population. A comparable known community can now accept a viable first invitation, while goodwill, respect and familiarity improve later invitations. Influence visits add familiarity on return, so repeated peaceful contact is productive even when nobody moves yet. A zero-result return records the community visited and the reason no household transferred instead of claiming the recruiters met nobody.

Scouting can originate from any player-controlled expansion city. The scouting panel exposes a departure-city selector; previews, range checks, land routing, active-party details, journals, world events, saved missions and return reports all preserve that city's name and physical position. A captured city is not offered as an origin, and legacy missions without origin fields continue to read as home departures.

Every expedition return now raises a persistent, non-pausing digest over the main HUD. It queues up to eight reports, summarizes the latest outcome, and opens the complete illustrated report directly. Reports remain in the permanent scouting archive. Time speed and an existing manual pause are not changed.

The previously READY exploration collection implementation is reconciled with current main. Returned artifacts have 4,096 deterministic named catalogue variants, rarity, custody age, appraisal, prestige, research/cultural support, exchanges, sales, gifts and museum exhibition. Collection cards and discovery blocks now show the bound subject painting instead of a generic production icon or text-only result. The collection remains searchable and paged, including at narrow resolutions.

## Validation

Godot 4.7.2 cleanly imported and booted headlessly from the explicit worktree. A 120-frame project boot exited 0 and reached `DIRECTION_SCREEN_READY`.

The relevant combined gdUnit run covered 133 cases across society exchange, scouting staff, artifact collections, ancient scouting UI, scout archive, return-speed behavior, discovery projects and civilization-owned simulation. After correcting one test-double signature found in that run, the affected return suite passed 2/2; all 133 covered cases therefore pass with zero remaining errors or failures. Artifact collection alone passes 42/42, including 4,096-record bounds/performance, save roundtrip, narrow layout and subject-art binding.

Founding convoy travel passes 6/6 new cases: an uncharted destination is accepted, deliberate camping occurs at the interpolated physical position, arrival becomes a stationary forage camp, replenished stores make a previously impossible next leg viable, and advisor stop/continue/readiness states follow provisions. Existing founding water guidance passes 16/16. Scouting staff and route planning pass 27/27, including a physical route beginning and ending at a selected expansion city. Five of six map-onboarding cases pass; the remaining assertion expects the older words `SEND FOR 30 DAYS`, while current base main already renders the newer `30-DAY EXPEDITION` label. This delivery did not alter that scouting button label.

The full civilization system suite passes 69/69 after replacing two obsolete assertions that expected expeditions to create random wanderers and updating its fixed bounded-save allowance for the 4,096-entry collection catalogue. The new assertions require population conservation unless an actual source-household reservation exists.

An unrelated existing research-visual assertion expects reviewed paper images no larger than 768 pixels, while ten current main assets are 1,254 pixels. That suite's other tests passed; this delivery neither introduced nor modified those raster files.

## Compatibility, limitations and integration

Existing saves remain compatible. `camped_foraging`, its day and physical position are optional fields inside the already-saved founding journey dictionary. Scouting origin policy, mission and report fields are optional and default to the primary home. Recruitment outcome fields and artifact metadata are also optional, legacy records receive defaults, and no migration invents population. The change does not retroactively create artifacts or recruits for already completed expeditions.

The separate `codex/artifact-paper-art` line ending at `8c817f4` remains HELD and is not included here. It contains a large partially reviewed raster bank, but its requested full set and final import audit were never completed. This delivery makes the already-bound research subject paintings visible now; it does not misrepresent that held image bank as finished.

Shared integration conflicts are expected in `scripts/society_exchange.gd`, `scripts/discovery_system.gd`, `scripts/civilization_system.gd`, `scripts/local_terrain.gd` and the scouting/collection HUD. The origin-routing work also touches `scripts/scout_frontier.gd` and `scripts/rumor_network.gd`. Reconcile these two worker commits as a unit and rerun the listed suites on combined main. No canonical files were changed, no player/editor process was stopped, and no graphical/player build was launched.
