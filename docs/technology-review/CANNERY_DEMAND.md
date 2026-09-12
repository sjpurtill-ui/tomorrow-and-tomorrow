# Cannery operation follows available food

Cannery operation now checks current food before spending cans, coal, water or operator time. A shared read-only calculation limits available input to the lesser of perishable stock and total stock above three days of current demand. Investment, daily operation and actual preservation all use this calculation.

At full condition, three eligible food units cause one installed cannery to operate at 0.3 units: it prepares capacity for three food units, reserves 0.6 Crafting workers, and consumes 0.06 Food Can Sets, 0.06 Coal and 0.15 Freshwater. Actual conversion yields 2.7 Preserved food, accounting for the existing ten-percent processing loss. With no eligible perishables or with food below the reserve, the cannery spends none of those operating inputs and reserves no operating workers. It resumes automatically at a later daily review when eligible food becomes available, retaining its enabled/paused setting.

The plant status explains when it is waiting for surplus perishable food. Staff and material shortages remain ordinary operating constraints. Construction remains separately paid work even when an already installed plant is idle. The primary-site, travel, current-day service and saved-record rules are unchanged.

Operation runs before daily harvest and existing drying/smoking. It deliberately does not count future harvest as already available. Subsequent food movement or preservation can therefore leave some prepared capacity unused; there is no refund or speculative future food grant. This is aggregate proportional daily operation, not a simulation of indivisible retort loads or individual sealed cans.

No save fields, discovery identities or recipes changed. Tests cover zero-input idle operation, released operators, automatic resumption, exact proportional supplies/workers at partial demand, protection of the food reserve before spending, and existing manufacture/conversion/save behavior. Campaign economics and long-horizon demand prediction remain unverified.
