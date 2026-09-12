# Electrical storage

Seven authored discoveries connect lead smelting and sheet working, porous separators, lead oxide, lead-acid cells, bank wiring and charge regulation. The graph reconverges with existing electrochemistry, paper, acid production, insulation, sensing and relays. No calendar gates or research-granted energy.

Seven workshop recipes turn real feedstocks into refined lead, sheets, oxide, separators, cells, banks and controllers. Cell manufacture uses the shared electrical service budget. Two installation types consume banks and cable, with controllers needed for regulated storage. Commissioning uses assigned Crafting workers. Newly completed installations are empty until a later operating day charges them.

Storage has finite energy, transfer rates, operators and losses. Each basic bank holds 12 service-energy units, charges/discharges at up to 3 daily, and uses 80% efficiency each way. Regulated banks hold 12, transfer up to 6, use 90% each way and fewer operators. Daily idle retention is 99.9% / 99.95%. These are game coefficients, not engineering specifications. Health and labor condition limit operation.

Generation serves current supplied consumers and workshop demand first. Banks can cover shortages while reserving consumer operators and workshop labor. Charging uses remaining generation after consumer operation and the workshop power/labor reservation. Generation capacity is shared across both passes. No bank charges on a day any bank discharges. Daily delivery is idempotent; disabled and traveling stores retain their energy subject to idle loss, but deliver nothing. Cooling forecasts stop promising the current battery contribution when remaining stored energy cannot sustain it.

Stored energy and daily transfer records live in the existing installation ledger. Missing fields default to zero, supporting earlier saves. Validation rejects negative, nonfinite and over-capacity energy or transfers. New discovery, product and installation IDs require this catalog revision. Government remains the owner of daily labor assignments.

## Grounding

The [DOE energy-storage overview](https://www.energy.gov/documents/qtr2015-3c-electric-energy-storagepdf) describes the lead/lead-dioxide/sulfuric-acid cell system. The [DOE supply-chain report](https://www.energy.gov/sites/default/files/2022-02/Energy%20Storage%20Supply%20Chain%20Report%20-%20final.pdf) identifies the material-processing context and stationary applications. [DOE's battery explanation](https://www.energy.gov/science/doe-explainsbatteries) explains rechargeable electrochemistry and its imperfect reversibility. The abstraction here omits manufacturing chemistry details and operational engineering instructions.

## Limits

Primary-settlement stationary storage only. Solar generation remains a daily aggregate; this does not introduce nights or weather. No battery wear, replacement lifetime, electrolyte depletion, mobile batteries or electrical network model yet. Automatic operation applies to installed banks. AI can now invest in a bounded reserve after surplus generation exists and can start a line from actual charged storage; banks are not treated as permanent generation. Forecasts assume no future charging and can understate alternate-bank or generator substitution. Workshop power reserved but unused later that day is not recovered by a second charging pass. Labor reservation is conservative rather than an optimized dispatch solver.

Full-history catalog, art, millennial pacing and canonical integration remain unfinished.
