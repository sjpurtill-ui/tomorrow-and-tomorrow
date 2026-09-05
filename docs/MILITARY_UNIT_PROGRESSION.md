# Military Unit Progression — Current Logic

> **As-built update.** The §18 framework from `docs/Historical_Military_Unit_Progression.docx`
> is now implemented on top of the logic below:
> - **Archetype catalog** (`scripts/military_unit_catalog.gd`): all unit identity, gates,
>   lineage spines (§17 branches), equipment, training days, and doctrine text are data;
>   `military_campaign.gd` reads it everywhere the old constants lived.
> - **Capability ladder** (`unit_capability_state`): unobserved → observed (problem/frontier
>   visible) → understood (discovery established) → established (≥10% adoption; normal
>   fielding) → scalable (≥25% adoption + ≥2 production lines) → mature (fielded formations
>   with army experience). Legacy/obsolescence is future work.
> - **Prototype fielding**: at *understood*, one experimental cohort (≤8, 2.5× training time)
>   may be raised, and understood equipment can be produced in experimental workshop batches
>   (≤12 items, 2× workshop time). Tier-gated industrial units have no shortcut.
>   Surface: the PROTOTYPE button in ARMY BUILDS.
> - **Readiness bands** (§18.4): ASSEMBLING / GREEN / TRAINED / READY / VETERAN / DEGRADED /
>   BROKEN derived from each formation's training, condition, and experience; shown on
>   every formation row. Verified by `tests/military_progression_probe.tscn`.

How units, equipment, and military development actually unlock today, as implemented.
Sources: `scripts/military_campaign.gd` (gates, units, training), `scripts/military_development_catalog.gd`
(eras, formation scales), `scripts/progression_system.gd` (domain tiers from adopted discoveries).

## The one gate mechanism

Everything military unlocks through `_knowledge_gate(discovery, minimum_adoption)`:

1. **Empty gate (`""`)** — always available (levies, improvised weapons).
2. **A discovery id** — the discovery must be **established** (in `known_discoveries`) *and* **adopted**
   by at least **10%** of society for units, **8%** for equipment. Knowing is not enough; the society
   model's adoption spread is the real clock.
3. **`__military_tier_N__`** — gated on the military development band (below), itself derived from
   adopted research. Used for the industrial-era units.

So every unit is ultimately research-driven; the only difference is whether it hangs off one named
discovery or off the aggregate development band.

## Military development bands (eras)

`era_for_tiers(security, production, logistics, institutions)` — the four **domain tiers** come from
`ProgressionSystem.domain_tier(...)`, which counts adopted discoveries per domain. The band is:

```
supported = min(security, production+1, logistics+1, institutions+1)
```

Security leads, but a mass army cannot outrun the production, logistics, and administration that
feed it — each support domain caps the band at one tier above itself.

| Tier | Band | Formation | Command | Production lines | Fronts |
|---|---|---|---|---|---|
| 0 | FOUNDING DEFENSE | war band | one field host | 1 | 1 |
| 1 | ORGANIZED MILITIA | company | muster commands | 2 | 1 |
| 2 | FORTIFIED ARMIES | regiment | regional commands | 3 | 2 |
| 3 | PROFESSIONAL FORCES | brigade | field staffs | 4 | 3 |
| 4 | STATE DEFENSE SYSTEM | division | general staff | 5 | 4 |
| 5 | INDUSTRIAL WARFARE | division | theater commands | 6 | 6 |
| 6 | NATIONAL JOINT COMMAND | field army | joint national command | 8 | 8 |
| 7 | GLOBAL FORCE SYSTEM | army group | global commands | 10 | 10 |
| 8 | PLANETARY SECURITY | theater force | planetary coordination | 12 | 12 |

Tier 5 is also the **signal era**: army runners are replaced by live reporting (`_live_army_reporting`).

## Units

| Unit | Gate | Weapons | Base training days |
|---|---|---|---|
| Levy | — (always) | improvised, spear | 7 |
| Line infantry | `shield_wall` ≥10% | spear, sword & shield | 30 |
| Skirmisher | `bow_craft` ≥10% | bow | 21 |
| Cavalry | `domesticated_mounts` ≥10% *(new — was a permanent lock)* | lance, sword & shield | 45 |
| Siege engineer | `siege_engineering` ≥10% | siege kit | 48 |
| Field artillery | `powder_artillery` ≥10% | field gun | 60 |
| Rifle infantry | military tier 5 | service rifle | 42 |
| Machine gun company | military tier 5 | machine gun | 56 |
| Motorized infantry | military tier 6 | motorized kit | 70 |
| Armored formation | military tier 6 | armored vehicle | 110 |
| Modern artillery | military tier 6 | modern field gun | 84 |

Training days come from `start_training`; the effective rate also scales with security capacity,
`formation_drill` / `professional_corps` adoption, founding effects, and `warfare_readiness` research.

## Equipment

Same gate mechanism at 8% adoption: spear←`hafted_weapons`, bow←`bow_craft`,
sword & shield←`bronze_weaponry`, lance←`domesticated_mounts`, siege kit←`siege_engineering`,
field gun←`powder_artillery`; rifle/MG at tier 5; motorized/armored/modern gun at tier 6.
Each item has a delivery load (logistics weight) from 0.8 (improvised) to 28 (armored vehicle) —
heavier gear leans harder on hauling capacity. Consumables gate likewise (arrows←`bow_craft`,
artillery rounds←`powder_artillery`, small-arms ammo tier 5, heavy shells tier 6).
Transport carts require `joinery`.

## The surrounding constraints (why units alone aren't power)

- **Mobilization capacity**: 4% of able population baseline → 8% (`watch_rotation` ≥10%) →
  18% (`public_levies` ≥15%) → 30% (`professional_corps` ≥20%). Army builds are hard-capped here.
- **Training capacity**: `3 + Defense workers × 0.30 + commander skill × 3`, scaled by
  `formation_drill`, `professional_corps`, `military_staffs` adoption and founding/research effects.
- **Formation scale labels** are pure headcount bands (war band <250 … theater force ≥10M) —
  cosmetic organization, not gates.
- **Training programs** (camp drill, staff exercise, …) each carry their own `required_discovery`
  and minimum adoption.

## The new lines feeding this system

- **Domestication**: `animal_taming` (ecology) → `pack_animals` (haul capacity) →
  `domesticated_mounts` (**unlocks cavalry + lance**) → `mounted_scouts` (+50% scout range at
  full adoption).
- **Watercraft**: `hide_floats` → `river_craft` (10 km water crossings for scouts) →
  `coastal_watercraft` (40 km crossings — straits and bay mouths open; open sea stays closed).
  No naval units exist yet; the watercraft line currently serves scouting and is the natural
  anchor for any future naval progression.
