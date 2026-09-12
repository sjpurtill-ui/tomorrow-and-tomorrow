# Experimental material consignments

A civilization can now pay an established contact to bring home finite material supplies for fifteen investigations. This addresses research that was blocked solely by a missing local occurrence even though the relevant experiment could use imported material. It complements the existing general trade system; it is a research-support order, not a recurring industrial freight contract.

## Player flow

1. Open an exposed unresolved investigation whose knowledge foundations are ready. Material Accounting and Standard Measures must be known.
2. Choose **Purchase experimental materials**, a located foreign settlement and a physical payment. The quote lists the missing quantities, provisions and travel time without revealing the supplier’s inventory.
3. Dispatch the ordinary envoys. Payment and travel provisions leave the buyer’s stores.
4. At actual arrival, the supplier must have all requested stock and at least one effective Logistics worker. Pickup is all-or-nothing. The supplier’s stock is debited once; the shipment is carried by the returning delegation.
5. On return, the normal embassy transaction settles payment and delivers the cargo once. Failure to obtain the consignment returns the unused payment; consumed journey provisions are not refunded.
6. Researchers still complete the investigation. The imported stock can later be consumed by normal manufacturing. The shipment creates no local deposit, mine, workshop or discovery.

## Supported material basis

Quantities are game-design thresholds for an experimental material basis, not chemical stoichiometry or tonnes. Existing qualifying local occurrences remain valid alternatives. Only the shortfall is requested.

| Investigation | Imported stock alternative |
|---|---|
| `lime_burning` | 5 Limestone |
| `lime_mortar` | 5 Limestone, 3 Fine Sand |
| `copper_smelting` | 5 Copper Ore |
| `copper_casting` | 5 Copper Ore, 3 Clay |
| `bronze_alloying` | 5 Copper Ore, 3 Tin Ore |
| `bloomery_smelting` | 5 Iron Ore |
| `forge_welding` | 5 Iron Ore |
| `hardened_edges` | 5 Iron Ore |
| `coke_firing` | 5 Coal |
| `refractory_furnaces` | 5 Refractory Clay |
| `blast_furnace` | 10 Iron Ore, 10 Coal, 5 Limestone |
| `sulfur_purification` | 5 Sulfur |
| `phosphate_dressing` | 5 Phosphate Rock |
| `graphite_marking` | 2 Graphite |
| `graphite_crucibles` | 5 Graphite, 5 Refractory Clay |

## Reconverging furnace paths

Continuous Blast Furnace retains refractory practice and lifting organization as common foundations. Its prior Mine Drainage route remains available; an alternative builds on Bloomery Smelting. This lets established forced-air reduction support experiments with imported supplies rather than making a local aquifer essential. The route is a game-design inference. The distinction between furnace inputs and mining location is informed by the [EPA description of integrated ironmaking](https://archive.epa.gov/sectors/web/html/steel.html), which describes ore, fuel and flux charged to a furnace. The game’s current coal stock still aggregates the prepared fuel chain.

## Disadvantages and limits

The buyer pays physical goods, provisions and travel time and risks supplier refusal. Stocks are finite, can be consumed, and provide weaker material evidence than a fully worked local supply. The order grants no purchased-study bonus. Site-dependent work such as Mine Shoring still requires a local occurrence. Knowledge prerequisites are preserved; this does not claim every geographically constrained research branch is solved.

The fifteen stock alternatives also work with goods acquired through existing ordinary commerce. This new order is limited to unresolved investigations; routine industrial replenishment continues to depend on other trade and supply systems. Market-based negotiation, freight capacity by commodity, grade-specific assay batches, research-consumable depletion, licenses and imported operating services remain incomplete.

Optional mission fields are saved with strict mode, subject, quantity and delivery-flag validation. Old missions need no new fields. The panel action and ordinary embassy/payment/manufacturing paths have headless regression coverage; native player interaction has not been verified.
