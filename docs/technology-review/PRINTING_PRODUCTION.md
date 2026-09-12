# Printing materials, forms and presses

Eight authored discoveries refine the existing Repeatable Printing topic without replacing its identity. Each enables a paid manufacturing operation. All have day-zero causal eligibility; no era/calendar unlock is added.

| Discovery | Foundations | Physical production |
| --- | --- | --- |
| Seed Oil Pressing | Selective Planting, Stone Selection | Drying Oil |
| Lampblack Capture | Charcoal, Clay Shaping | Lampblack |
| Oil-Based Printing Inks | Seed Oil Pressing, Lampblack Capture | Printing Ink |
| Relief Block Cutting | Repeatable Printing, Wood Joinery | Printing Forms |
| Wooden Movable Type | Repeatable Printing, Wood Joinery, Standard Measures | Printing Forms |
| Hand Relief Printing | Paper Making, Oil-Based Printing Inks, plus relief blocks **or** wooden type | Printed Sheets |
| Screw-Press Printing | Hand Relief Printing, Paper Sheet Pressing, Workshop Standards | Printed Sheets with less impression labor |
| Cylinder-Press Printing | Screw-Press Printing, Bearing Surfaces, Gear Ratios | Hand-cranked or motor-driven Printed Sheets |

The Library of Congress describes [printing with oil and lampblack ink](https://blogs.loc.gov/bibliomania/2025/01/24/before-control-p-the-printing-process/). The Met explains [relief woodcut preparation and impression](https://www.metmuseum.org/ko/perspectives/materials-and-techniques-printmaking-woodcut). These support the basic material and relief-printing mechanisms; game batch sizes, dependencies, work requirements and study coefficients are design choices. This implementation is an oil-ink production route, not a claim that all historical woodblock printing used oil inks.

Nine recipes link physical ingredients to a usable output. Oil pressing consumes the raw **Fiber Plants** resource as an aggregate of seed-bearing plants such as flax, not processed textile fibers. Lampblack capture consumes timber as combustion feedstock. Ink manufacture consumes half a Drying Oil batch, half a Lampblack batch and timber fuel. Carved blocks and composed wooden type each provide a Printing Form. A form is consumed when setting up a printing line and remains deployed as its reusable tooling. Each completed sheet batch consumes one Paper and 0.10 Printing Ink for hand/screw methods, or 0.08 for cylinders. Work per batch is 3, 1.5, 1 or 0.5 respectively. The motor route additionally requires motor/bearing/gear tooling and consumes one shared electricity unit per batch. It cannot print without power.

During local collection examination, Printed Sheets are consumed at 0.01 batch per supported worker-day and support 30% extra examination progress. Ordinary Paper supports 20% at the same consumption rate. Printed sheets are used first; paper may support remaining work, but the same worker-day never receives both bonuses. Total supported work is bounded by available staff effort, remaining examination and actual stocks. Neither commodity creates a collection, a discovery or subject-specific evidence; these are aids for reproducing and comparing information already physically present. Study without either remains possible.

AI production planning now prefers an affordable printing supply chain and counts existing printed stock against pending study demand. It keeps the ten-batch stock-target cap and falls back to paper when printing is unavailable. Existing finite workshop slots, paid retooling and manufacturing constraints remain. The collection panel explains the two alternative consumables.

Abstractions and unfinished work: raw oilseed species, seed yields and crop processing are aggregated into Fiber Plants; no pressing of purified fiber is intended. Drying/varnish chemistry, resin additives, fumes, pigment particle grades, type composition time, individual text identity, movable-type reuse between jobs, block wear, registration, paper grades, literacy, censorship and book distribution are not simulated here. Printing Forms abstract compatible tooling rather than recording the precise relief form's provenance. Existing broad Repeatable Printing effects remain; this addition does not reconcile those legacy bonuses. Printing imagery is queued. No new plant type or save field is added; old builds cannot operate these new recipe/resource/discovery IDs.
