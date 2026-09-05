# Unit mobility and scout pursuit

Branch: codex/unit-mobility-pursuit
Base: ffefea66752e12ccd6e59ae4ecf85c829ef901b9

Armies can pursue observed scouts through the contact card and attempt capture
at contact. Success depends on the actual army/scout speed ratio. Armies provide
close observation within 12 km. Lost contact stops pursuit.

Army pace now depends on unit class, training, condition, supply and logistics.
The slowest attached unit constrains the column. Cavalry base pace is 55 km/day,
levy 24, skirmishers 32 and siege engineers 14; support reduces actual pace.
Motorized and armored forces have distinct speeds. Era progression no longer
accelerates every foot soldier. New foreign scout missions use 16–32 km/day.

Validation: headless import passed; 16 military-development tests passed,
including scout pursuit, baggage constraints and supply penalties.

Save compatibility: no schema changes or player save writes. Active foreign
routes retain saved timing until replaced. Existing armies use the new pace on
their next movement day. Cavalry knowledge and equipment gates remain intact.

Limitations: terrain march costs, pathfinding, convoy, diplomat and player
exploration timing remain unchanged. Pursuit regression covers order/contact
resolution; integration should include a long moving-scout chase check.
Local watch capture remains available alongside army pursuit.

Shared conflict surfaces: military_campaign.gd movement and engagement;
civilization_system.gd observation and scout capture; contact-card scout actions;
test_military_development.gd. No merge or player launch performed.
