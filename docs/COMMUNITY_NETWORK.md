# Community network

F9 opens the community network; F8 also links to it after the opening ambition choice. Contacts remain hidden until encountered. Select a known community to send a trade or non-aggression proposal using the existing physical envoy system, including destination knowledge, provisions, travel, and acceptance. One treaty replaces another under the current diplomacy rules. The graph shows relationships, not geography.

Three player-backed traditions provide the first collective-project loop:

| Project | Requirement | Material cost | Work at four knowledge/administration workers | Permanent research benefit |
| --- | --- | --- | --- | --- |
| Shared records | One known discovery | 8 Timber, 4 Fiber Plants | 120 days | Knowledge +12% |
| Recurring gathering | Chosen settlement site and direct foreign contact | 16 Timber, 8 Fiber Plants | 180 days | Culture +12% |
| Route-keeping tradition | Returned scout report | 6 Timber, 6 Fiber Plants | 150 days | Logistics +12% |

One project can run at a time. Materials are charged once. Existing aggregate workers carry out the work; fewer than four slow it proportionately, and zero workers pause it. Active projects reduce all research by 8% as an opportunity cost. No worker-by-worker orders are needed. Benefits apply once; projects cannot be repeated. Requirements are checked again during work. These projects do not yet pool contributions from foreign communities or create new political federations.

State is nested in PeopleDirection's campaign save state; older saves without a network remain compatible. A new world clears the network. Import validates before mutation. Internal domain progression tiers remain available to the simulation, while the terrain UI shows capabilities rather than era names. There is no date-based gate on these projects.

Validation: `tests/community_network_probe.tscn` covers hidden contacts, destination requirements, prerequisites, exact costs, duplicate actions/days, aggregate work, completion benefits, and JSON validation. `tests/people_opening_probe.tscn` checks that the opening ambition flow still starts the map. `tools/community_network_preview.tscn` is an isolated visual preview.
