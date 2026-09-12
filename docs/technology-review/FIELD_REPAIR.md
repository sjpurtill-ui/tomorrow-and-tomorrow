# Field repair companies

Implemented in the technology worktree; not integrated into the player build.

**Field Armorer Teams** reconverges Wood Joinery and Workshop Standards without a calendar gate. It enables Armorer Tools and a Field Repair Company. This is one discovery with an operating consequence, rather than a series of differently named percentage bonuses.

The company uses the normal recruit pool, 45-day base training requirement, issued equipment, losses and demobilization. Each tool set costs two Timber, two Stone and three base workshop-days. These aggregate tools represent basic repair capability; the materials for each repaired item still come from that item's own recipe. The unit and equipment contribute zero offensive attack.

At home, trained repair staff contribute 0.1 repair-work days per equipped person per day, multiplied by training, personnel condition, adoption, force supply and current food intake. These are explicit game balance coefficients. Traveling settlements, unavailable home workshops, active engagements and army-wide exercises prevent this work. Field armies must be stationed at player_home and not engaged. Mobilized personnel do not become extra civilian Crafting workers.

The daily work budget is shared across eligible repair batches, never repeated for each line. A crew can automatically reserve one affordable batch of up to ten damaged items when no eligible repair is already queued. It uses the ordinary workshop capacity and payment checks. Existing batches receive work even with no civilian Crafting staff. Paused jobs receive none. Normal civilian workshop work continues to share its existing allocation budget.

Company-assisted repair requires the equipment's local knowledge gate at 10% adoption. Imported advanced equipment therefore does not become repairable merely because a civilization can organize basic tool crews. Existing ordinary repair rules are unchanged. Repair costs remain 18% of the manufacturing materials and 38% of manufacturing work. Reserved damaged items leave the damage pool; completion returns serviceable items to inventory. Cancellation returns unfinished damaged equipment and the existing partial-work material refund. No dead soldiers, destroyed equipment or battlefield salvage are recreated.

This checkpoint handles home workshops only. Forward recovery, spare-parts cargo, component-specific faults, repair priorities chosen by generals, and specialized ship/aircraft maintenance remain unfinished. The support role is available through the normal military roster; autonomous composition preferences are not claimed. Further repair discoveries should add those distinct behaviors rather than inflate the catalog with equivalent modifiers.

Save representation uses existing formation, equipment and batch-job fields. New identifiers require the updated catalog. Tests cover paid production and training, progression validation, full military export/import, partial repair job serialization and cancellation, finite materials, knowledge gates, shared budgets, paused work, staffing, movement, food and exercises.
