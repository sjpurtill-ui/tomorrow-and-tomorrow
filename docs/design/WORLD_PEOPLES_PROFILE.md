# World peoples: selected civilization profile

The 14 October 2026 review rejected the all-country card list and its sparse headline statistics. The Modern Strategy palette remains; this checkpoint changes the structure of World > Peoples.

- A searchable, sorted civilization selector opens one profile. The first foreign people in the chosen order is selected initially; our own people remain available. Selection, query, ordering and town-page state survive live refreshes.
- Identity, Talk, provenance and the relationship lead. Allure, awe, fear, respect, trust, resentment, envy and contempt are explicitly **their view of us**. The exact consequences remain under “What this means.”
- Four compact groups expose learning capacity, production/output/stores, population/health/fighters/defences, and cultural/social strengths. Independent columns avoid equal-row blank areas. These are finite profile readings, not a catalogue.
- Town-report readings still come exclusively from `peoples_known_model`. The fighter estimate still uses the same `enemy_strength` reading as War. Relative ranks and uncertainty evidence remain in tooltips; the small count bands retain our benchmark.
- The nine wider strengths reuse Standing's already certainty-gated `theirs` estimates. Approximate values are marked `~` and retain their full range/qualification. Our profile uses our exact Standing readings. Unreported customs and unavailable intelligence remain unknown; the renderer never consults foreign truth.
- Known towns open a reader of four reports per page. Every report callback remains available. Empty hearsay is one quiet line with its existing map action.

No simulation, calculation, save schema, or command callback changes. The provider fingerprint now includes its existing regard and our-strength readings so those parts refresh when their evidence changes.

Review loop: A critiqued the first actual render, requested relationship-first hierarchy, shorter empty hearsay, a clear Sort label and an explicit learning-capacity label. The revised populated profile was accepted at 1600 and 1024 in Daylight. The private GPU fixture covers 2869, 1600 and 1024, our own profile, reported foreign readings, limited intelligence, and town disclosure, in isolated Test userdata with Dummy audio. Generated captures remain in `artifacts/`.

Regression coverage retains model uncertainty/ranking tests and adds selected-profile visibility, selector search/sort, bounded town pages and real callbacks, separation of estimates and regard, live focus/selection retention, both-mode contrast, and the empty-hearsay map action. The unfinished Home People/Council work is deliberately excluded from this checkpoint.

## Hearsay follow-up

Nonempty hearsay now uses one selected telling with a searchable selector. The selector popup is capped in height; its full route, provenance, uncertainty and previous unsuccessful searches appear together with the existing map/expedition actions. A visible match/total count explains the search. A query with no matches hides the previous telling until the search is cleared, while remembering the selection. The provider no longer truncates its presentation to six network leads/eight total tellings; the complete existing intelligence remains reachable. Long civilization and telling names cannot widen the page through the native selector's minimum size.

The 21-telling native fixture checks unfiltered, filtered and no-match cases at 2869, 1600 and 1024. Tests verify late entries remain available, selection/query/focus survive updates, and original map/planning callbacks still fire. A independently critiqued the first render; the visible matching count and shorter unsuccessful-search wording address that review.
