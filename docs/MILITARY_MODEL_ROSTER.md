# Military model coverage

The expanded target roster is [Historical military roster selection](HISTORICAL_MILITARY_ROSTER.md):
**130 field archetypes across 18 eras**, plus **10 command and strategic capabilities**,
selected from the user's historical study. This checklist tracks implemented assets only.

The currently implemented combat roster is `CombatSimulator.UNIT_TYPES` in
`scripts/combat_simulator.gd`. It contains **11 broad prototype unit types**;
these are not the full intended roster.
`MilitaryCampaign.UNIT_EQUIPMENT` and `UNIT_KNOWLEDGE` govern their equipment
choices and availability. Do not mistake formation sizes or visual roles for
additional unit types.

| Game unit type | Model | Status |
| --- | --- | --- |
| Levy | Stone-club levy | Built, animated, crowd-ready |
| Line Infantry | Spear-and-shield infantry | Built, animated, crowd-ready |
| Skirmisher | Bow archer | Built, animated, crowd-ready |
| Cavalry | Mounted lancer | Built, animated, crowd-ready |
| Siege Engineers | Crewed ballista | Built, animated, crowd-ready |
| Field Artillery | Wheeled cannon with crew | Built, animated, crowd-ready |
| Rifle Infantry | Helmeted rifleman | Built, animated, crowd-ready |
| Machine-Gun Company | Tripod machine gun with operator | Built, animated, crowd-ready |
| Motorized Infantry | Troop truck with rifleman | Built, animated, crowd-ready |
| Armored Formation | Armored vehicle/tank | Not built |
| Modern Artillery | Modern field gun | Not built |

## Study-selected historical batch

Six additional animated visual prototypes are built: **slinger, javelin skirmisher,
crossbow infantry, chariot archer, horse archer, and camel cavalry**. They have shared crowd animation
textures and a historical preset in the army-scale preview. Their new IDs are
visual-catalog entries; they are not yet recruitable combat types.

See [Historical unit assets](../assets/models/basic_units/HISTORICAL_UNITS.md)
for source files, previews, rebuild commands, and limitations.

## Classical batch

Six more animated prototypes are built: **pike phalanx, legionary infantry,
war elephant, battering ram, siege tower, and trireme**.
The trireme has a separate water preview and is not part of land formations.
These new types are visual prototypes; recruitment and combat integration remain
pending. See [Classical unit assets](../assets/models/basic_units/CLASSICAL_UNITS.md).

## Medieval batch

Six more prototypes are built: **armored foot soldier, pavise crossbowman,
longbowman, counterweight trebuchet, hand-cannon team, and bombard**. The library
now has **27 models / 108 clips**, with **26 land models** in the crowd renderer
and one separate naval model. The medieval preset includes all six additions.
Recruitment and combat integration remain pending.
See [Medieval unit assets](../assets/models/basic_units/MEDIEVAL_UNITS.md).

## Equipment variants

The combat catalog has **12 weapon/equipment categories**: improvised arms,
spears, bows, sword and shield, lances, siege kits, field guns, service rifles,
machine guns, motorized equipment, armored vehicles, and modern field guns.

Some unit types accept more than one equipment category. The current models
do not yet switch appearance based on that equipment choice. Missing alternate
looks include spear-equipped levy, sword-and-shield line infantry, and
sword-and-shield cavalry. A ballista is our chosen first visual interpretation
of the generic siege kit; it is not a separate roster type.

The military development catalog also defines nine formation-size categories,
from war band to theater force. Those change the organizational scale and numeric
strength of existing types, rather than adding nine different soldiers/vehicles.

## Industrial batch

The three industrial models have idle, walk/transport, attack, and death/disabled
clips (2 s, 1 s, 1.75 s, and 2.5 s). They are stylized first-pass assets. Rifle
fire has recoil and flash; the machine gun fires bursts; the truck has animated
wheels, a firing rifleman, and a disabled pose with displaced hood/wheel. Movement
is in place, and gameplay projectiles/casualties are still separate from the clips.

Editable source: `art_source/industrial_units/industrial_units.blend`.
Individual viewer: `tools/industrial_units_preview.tscn`.
Army-scale viewer: choose **Industrial forces** or **Mixed army** in
`tools/army_scale_preview.tscn`. Vehicle formations have wider spacing.

```text
blender --background --python tools/build_industrial_units.py
blender --background --python tools/bake_basic_unit_crowds.py -- --industrial
godot --headless --path . --editor --import
godot --headless --path . --script tools/verify_basic_units.gd
godot --headless --path . --script tools/verify_army_figures.gd
```

The crowd check verifies every supported model ID against the actual combat
roster. New models do not change unlocks, equipment stores, recruitment, or combat
balance. Update this checklist when adding models or changing the live roster.
Follow the historical selection's next modeling batches to fill the early-era
gaps before treating the remaining two prototype types as the end of the roster.
