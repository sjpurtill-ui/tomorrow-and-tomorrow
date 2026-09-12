# Wheelwright and cart production

Sixteen authored discoveries and seventeen workshop recipes connect wooden wheels, axle fittings, load beds, drawbars and haul harness to the existing Transport Carts stock. Newly started persistent cart lines and the older batch-order interface consume physical cart assembly kits. Finished carts contribute to the existing delivery system, which still requires assigned Logistics workers. There is no discovery-only delivery bonus.

| Practice | Manufactured result |
|---|---|
| Wheel Blank Jointing | Joined Wheel Blanks from timber |
| Wheel Hub Boring | Bored Wheel Hubs |
| Spoke Tenon Cutting | Spoke Sets |
| Felloe Jointing | Curved Felloe Sets |
| Solid Wheel Assembly | Wheel Pairs from blanks and hubs |
| Spoked Wheel Assembly | Wheel Pairs from hubs, spokes and felloes |
| Iron Tyre Fitting | Iron-Tired Wheel Pairs, consuming wheels, wrought iron and charcoal |
| Wooden Axle Shaping | Wooden Axles |
| Wooden Axle Boxes | Axle Boxes |
| Axle Sleeve Fitting | Axle Sleeves from boxes and wrought iron |
| Linchpin Retention | Removable Cart Linchpins |
| Cart Bed Framing | Braced Cart Beds, consuming timber and treenails |
| Drawbar Fitting | Cart Drawbars from timber and rope |
| Haul Harness Weaving | Haul Harness from woven cloth and rope |
| Cart Running Gear | Cart Assembly Kits, and final assembly into Transport Carts |
| Sleeved Cart Assembly | An alternative Cart Assembly Kit recipe using iron-bound wheels and sleeved bearings |

Cart Running Gear reconverges after either solid-wheel or spoked-wheel knowledge while retaining the same axle, bed, drawbar and harness prerequisites. All sixteen discoveries have zero calendar unlock day. Production depends on the corresponding adopted methods or the existing paid civilian-production license system; the final legacy cart API retains its Joinery gate but must obtain actual fitted kits. Components may therefore be obtained through existing acquisition systems without pretending that possession teaches every upstream craft.

A solid wheel pair uses two broad joined blanks and two hubs. The spoked pair uses two hubs, two spoke batches and two felloe batches, requiring more distinct fitting operations but less timber. The ordinary kit uses wooden bearing boxes and five assembly work units; the sleeved kit uses prepared iron-bound wheels and metal bearing sleeves with three final assembly work units. Upstream iron preparation is additional work. Both produce the same aggregate cart capability: this patch does not invent an unimplemented speed, durability or payload distinction. Final commissioning takes one work unit per kit through either production interface.

## Automatic production and operation

The controller considers cart manufacture during ordinary military planning when the society is not hungry. Its target is limited by assigned Logistics workers and one cart per twenty-four current home, field or occupation personnel. It requests no carts when there are no supported troops, no effective Crafting or Logistics labor, an unsettled/travelling site, or a secondary-city resource scope. Existing stocks count toward the target.

The shared production planner follows manufactured inputs to a feasible next workshop order. It cannot grant missing raw resources or unknown methods, override paused upstream work, or expand workshop capacity. The controller reuses only completed, unpaused civilian lines. Actual cart stocks feed the pre-existing provision-delivery coverage and equipment-delivery calculations; carts alone do not deliver equipment with zero assigned logistics staff. No new authority for people, commanders, stockpiles or saves is introduced.

## Verification and integration

The focused tests exercise a complete recursive production chain, actual timber consumption, two completed carts and their effect on staffed delivery; both prerequisite routes and missing common foundations; batch reservation and cancellation of actual kits; absent demand, raw shortages, unknown methods and paused upstream work; legacy reservation normalization and serialized fractional cart production; and both ordinary and sleeved kit recipes with actual component debits. The isolated fixture supplies upstream cloth, rope, iron and treenails; it is not proof of a naturally developed economy.

All six focused cases pass with zero errors, failures, skips or orphans. All nineteen existing persistent-production adapter cases also pass because the cart input recipe changes. Its generic transport fixture now supplies Cart Assembly Kits instead of relying on the removed raw-timber recipe. No broad unrelated gameplay regression is required for this batch. Full-world progression, native player acceptance and canonical integration remain outstanding.

No save schema changes. Already reserved batch inputs remain attached to their jobs. Very old cart batches lacking a reservation retain the historical timber/fiber reconstruction basis during normalization, avoiding a newly fabricated kit refund. Retained persistent lines keep their stored recipe and fractional work. New lines use the new kit recipe. This preserves existing equipment and work; it does not migrate old lines to the new recipe automatically.

Shared integration conflicts: the append in discovery_system.gd, the two small transport changes in military_campaign.gd, civilian_industry.gd, and the military-planning call in civilization_controller.gd. General-led objectives and battlefield operation are unchanged.

## Historical grounding and abstraction

[Colonial Williamsburg's wheelwright account](https://research.colonialwilliamsburg.org/Foundation/journal/Winter04-05/wheel.cfm) describes wooden hubs, spokes and rims with iron tyres and the role of carts in transport. Its [craft interview](https://podcast.history.org/2007/09/03/carriages-carts-and-wagons/) discusses precise spoke mortises and fitting. The [National Park Service's wagon study](https://www.nps.gov/safe/learn/historyculture/upload/Wagons-on-the-Santa-Fe-Trail-by-Mark-Gardner-508.pdf) documents hubs, felloes, axle boxes and retaining hardware in surviving specifications. These support the component distinctions, not the game's costs or a universal chronology.

All quantities are gameplay batches. Timber species, lubrication and wear, live draught animals, harness fit, road grades, turning geometry and separate four-wheel wagon payloads are not modeled here. Broad woven haul harness is a manufactured hauling connection; production does not create animals. This batch supplies the game's existing aggregate cart capability rather than asserting that every culture used one vehicle design.
