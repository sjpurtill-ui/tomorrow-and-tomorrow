# Civilization parity — September 9, 2026

The crowded opening came from five prepopulated strategic districts per opponent being drawn as cities, plus a separate monthly opponent growth/expansion model. Opponents were also previously relocated relative to the player's home. This was a difference in implementation, not evidence that equal population mechanics required a growth penalty.

The new owned simulation replaces those paths for new worlds. Every civilization starts as a 120-person party and uses the same local food, water, material, construction, population, labor, knowledge and military functions. Additional cities require the ordinary founding transaction and arrival. World records display actual founded cities and actual units. Opponent origins are independent of the player's movements. The approved default is 12 opponents, with 6, 24 and 36 selectable for a new game.

Cross-owner trade, gifts, scouts, combat, occupation and relief operate on the actual owner ledgers. One siege is processed once and has views for attacker and defender. Air and naval contacts resolve real hardware and crew losses in their separate service systems. Controllers choose orders under common validation and costs.

See [the implementation handoff](FULL_CIVILIZATION_PARITY_HANDOFF.md) for ownership, validation, save compatibility and limitations, and [integration status](INTEGRATION_STATUS.md) for the delivered commit. The old `1e918e3` adapter remains held and was not merged.

The simulation architecture supports replacing an AI decision maker with another controller later. Multiplayer transport is outside scope. Shared rules do not, by themselves, establish balanced AI decisions or acceptable performance for every late-game world size. No artificial population slowdown was introduced.
