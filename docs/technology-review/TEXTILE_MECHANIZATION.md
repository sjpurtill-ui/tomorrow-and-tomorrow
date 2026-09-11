# Textile mechanization

Six distinct discoveries extend hand textile production: Spinning Wheels, Flyer Spinning, Multi-Spindle Spinning, Mule Spinning, Flying Shuttles and Electric Power Looms. Seven paid workshop routes produce the existing Spun Yarn and Woven Cloth stocks. Existing drop-spindle and plain-weaving routes remain available. There are no year gates or mutually exclusive paths.

| Route | Inputs per batch | Work | Electricity per batch |
|---|---|---:|---:|
| Wheel-spun yarn | 1 Prepared Fibers | 2 | 0 |
| Flyer-spun yarn | 1 Prepared Fibers | 1.5 | 0 |
| Hand-frame yarn | 1 Combed Fibers | 1 | 0 |
| Hand-mule yarn | 0.9 Combed Fibers | 0.85 | 0 |
| Motor-driven mule yarn | 0.9 Combed Fibers | 0.5 | 2 |
| Flying-shuttle cloth | 2 Spun Yarn | 2.5 | 0 |
| Electric-loom cloth | 2 Spun Yarn | 1 | 2 |

Tooling is paid separately. Wheels use timber, stone and fiber; flyer frames use shaft bearings; multi-spindle frames use timber and iron; mule machinery uses gearing and bearings. Electric routes add manufactured motors, steel, and crank assemblies for the loom. Both powered routes advertise one unit of daily electrical demand through the ordinary workshop-energy allocator. Inputs and power are consumed only as productive work occurs. Stock targets, scarce workshop slots, existing crafting allocation and partial-work saves remain active constraints. Closing a completed persistent line preserves its finished goods but does not refund setup tooling.

These mechanisms connect to the same cloth-to-dressings use introduced in TEXTILE_PRODUCTION.md. Manufacturing licenses and destructive examination discover the new recipes through the existing civilian product catalog; no separate acquisition ledger or special free output is introduced.

The distinctions are historically grounded in the [Science Museum Group's discussion of flying shuttles and powered looms](https://ceblog.sciencemuseumgroup.org.uk/2023/06/23/lets-digitally-reassemble-industrial-heritage-collections/), its [working spinning-mule model](https://collection.sciencemuseumgroup.org.uk/objects/co44850/working-model-of-a-spinning-mule), and [The Henry Ford's hand-operated multi-spindle frame](https://www.thehenryford.org/collections/explore/artifact/191535). The motor-driven recipes are electrical implementations, not claims that the original mule or first power looms used electricity.

Amounts, work savings and electricity are game-design coefficients. Yarn count, strength, warp/weft suitability, fiber-species compatibility, breakage, mill hazards, water/steam line shafts, pattern weaving and automated tending remain unmodeled. Output quality is currently aggregated into common yarn/cloth stocks, so the system does not yet reproduce every historical tradeoff between spinning methods. These six mechanisms are individually authored discoveries, not a combinatorial technology expansion.
