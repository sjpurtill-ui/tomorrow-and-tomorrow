# Armor manufacturing and issued infantry equipment

Status: READY for integrator review; not integrated by this worktree.

Worktree: `/Users/seanpurtill/Documents/Codex/tt-armor-runtime`
Branch: `codex/armor-runtime`
Base: `ee07b536319ac13a8c20a36d5165cd25dcd5d2af`

The operating family connects distinct armor production methods to complete spear kits for existing spearmen and line infantry. A discovery does not grant equipment or strengthen an existing formation. Workshops consume local stocks and finite Crafting labor; military inventory, training, delivery, wear and repair retain their existing owners. Generals retain operational command. There are no new unit archetypes or cohort controls.

Six existing identities are promoted: shield-equipment fitting, textile armor layering, lamellar assembly, scale attachment, mail fabrication and articulated plate armor. No duplicate identities are added.

## Manufacturing

| Route | Physical inputs | Output | Work per batch |
|---|---|---|---:|
| Fitted shield | Timber, binding fiber, cloth covering | Fitted Shields | 2.5 |
| Bronze elements | Refined copper, refined tin, charcoal | Armor Plates | 3 |
| Iron elements | Wrought iron, charcoal | Armor Plates | 4 |
| Textile armor | Woven cloth, prepared fibers, yarn | Padded Armor | 4 |
| Lamellar assembly | Armor plates, binding fiber, cloth | Lamellar Armor | 5 |
| Scale attachment | Armor plates, woven backing, yarn | Scale Armor | 4 |
| Mail fabrication | Wrought iron, charcoal, cloth underlayer | Mail Armor | 12 |
| Hand-formed plate | Wrought iron, charcoal, cloth underlayer | Fitted Plate Armor | 18 |
| Rolled-sheet plate | Steel sheets, charcoal, cloth underlayer | Fitted Plate Armor | 10 |

Every component line also requires paid tooling. Bronze and iron elements use their respective existing material discovery gates; an armor assembly cannot conjure alloy stock by taking the other discovery branch. Mail includes wire preparation and joining work in its own paid batch, without imposing industrial steel-wire machinery. Hand-formed plate includes local metal conditioning and does not require rolled sheet or the much later bulk Steel Refining process. Compatible armor elements share one stock class; this does not simulate arbitrary metallurgy or garment geometry.

The shield-and-spear kit consumes a fitted shield and spear materials, takes 1.5 work and has delivery load 1.5. Its protection value is 0.50. The five body-armor kits consume one finished armor batch plus timber and stone for a spear. Their work costs are 2 / 3 / 2.5 / 4 / 6 and delivery loads 1.5 / 2.5 / 2.4 / 2.3 / 3 for textile / lamellar / scale / mail / plate. These are explicit game quantities, not SI units or measured historical costs. Existing cheaper weapons remain available.

## Equipment choice and combat

Automatic recruitment first preserves its choice of unit role. Within the two affected infantry roles, it compares feasible equipment using attack, defense, protection preference, assembly work and delivery load. Other unit roles retain their original first-feasible-equipment selection. Missing raw inputs, unknown methods, absent labor and paused upstream production prevent an armor investment. A feasible missing component is requested in batches of at most 32 through the existing civilian production planner; ordinary supplied infantry can continue training while that investment completes. With one free workshop slot, a finished component line can switch to kit assembly. An idle controller-managed armor line can temporarily make a missing ancestor input, then resume assembly. Manual/paused lines and any paid partial work are protected. Orders create neither materials nor soldiers.

Armor and penetration now scale with issued equipment divided by required equipment. Crew-served equipment uses the existing equipment-per-crew requirement. Full equipment retains its existing values. This corrects the prior ability of an unequipped formation to retain its weapon's nominal armor and penetration. It changes both aggregate force ratings and detailed formation defense/enemy penetration. The existing baseline penalties for missing weapons remain; armor confers no additional protection at zero issuance.

Armor values are 0.30 / 0.80 / 0.70 / 0.85 / 1.35 for the five kits. All retain the spear's attack, base defense and penetration. Armor protection is reduced by enemy penetration through the existing combat formula; no kit guarantees invulnerability. There is no new per-body-part, fatigue, projectile or material-breakage simulation in this delivery.

## Historical basis and causal review

The [Met's armor overview](https://www.metmuseum.org/essays/the-function-of-armor-in-medieval-and-renaissance-europe) describes layered fabric, joined mail, plate and their combined use, including fitted and padded undergarments. Its [Tibetan lamellar shoulder defenses](https://www.metmuseum.org/art/collection/search/788894) distinguish self-supporting laced elements and document bronze and iron examples across regions. [Royal Armouries' Hundred Years' War account](https://royalarmouries.org/objects-and-stories/stories/the-hundred-years-war-1337-1453) explains padding under mail and the adoption of plate. These sources support mechanism distinctions; they do not establish the numerical game ratings above.

Two authored prerequisites were found to be absent from the live catalog: shield-equipment fitting and surgical anatomy. The implemented correction adds shield fitting physically and replaces surgical anatomy with standard measures for armor fitting, while retaining hardened edges and the rolled-sheet OR structural-load-testing branch. This is a causal design inference: making a fitted protective garment requires sizing and practical movement trials, not surgical practice. The exact original and revised predicates are retained in `technology-review/master-catalog/armor-pathway-reconciliation.json`, and the source JSON/TSV are updated. The designated integrator approved this bounded correction; canonical promotion remains their responsibility.

## Validation and remaining work

**70 distinct runtime cases and 15 catalog-tool cases pass.** The final armor suite has 15 cases; relevant existing suites cover 20 combat, 6 equipment quotes, 4 combined-arms recruitment, 10 training-accounting and 15 civilian production-planner cases. All final applicable runs have zero errors, failures, skips and orphans. Verification is focused on this equipment family, not the complete historical campaign.

Commands use `/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/seanpurtill/Documents/Codex/tt-armor-runtime`. GdUnit runs add `-s addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode -a <suite>`:

- Final armor acceptance: `tests/test_armor_runtime.gd`, all 15 passing in 4.983 seconds, `/tmp/tt-armor-ready-acceptance.log`; production, physical issuance, partial/missing/full armor and penetration, crew-served legacy ratings, real automatic military orders, one-slot manufacturing and replenishment, manual/partial-work protection, full save/load.
- Combat and training regressions: `tests/test_combat_simulator.gd` and `tests/test_military_training_accounting.gd`, 30 passing cases in `/tmp/tt-armor-final-acceptance.log`. The one failing assertion in that earlier multi-suite run was an armor test ruler's preference for levies; the final test uses an infantry-preferring ruler without changing unit strategy.
- Equipment quote fixture correction: `tests/test_equipment_order_quotes.gd`, all 6 passing in `/tmp/tt-armor-final-focused.log`. Current carts reserve and return Cart Assembly Kits, not obsolete raw timber/fiber.
- Final controller/workshop regressions: `tests/test_combined_arms_recruitment.gd` and `tests/test_civilian_production_planner.gd`, all 19 passing alongside armor in `/tmp/tt-armor-workshop-acceptance.log`.
- `-s tools/audit_technology_graph.gd`: **722 discoveries / 504 explicit routes / 374 civilian recipes / 18 facilities**, no graph or production closure errors; `/tmp/tt-armor-final-graph.log`. Structural reachability is not campaign pacing.
- `python3 tools/technology-review/check_master_catalog.py`: no duplicate names, missing parents or unreachable drafts. Existing ledger remains 716 integrated + 2,497 drafts = 3,213 until integrator promotion; this work adds no identities.
- `python3 -m unittest discover -s tools/technology-review -p 'test_*.py'`: all 15 cases pass, `/tmp/tt-armor-ledger-tests.log`.
- Fresh headless import succeeded. Normal headless boot with `--quit-after 3` reached `DIRECTION_SCREEN_READY` without script errors, but emitted the existing exit-time two-ObjectDB/one-resource cleanup warning. `/tmp/tt-armor-boot.log`. This is not a clean resource-shutdown claim.

Shared-file conflicts are additive armor entries in CivilianIndustry, DiscoverySystem, MilitaryUnitCatalog and MilitaryEquipmentExtension; the controller and combat changes require deliberate review. No GameState, SaveSystem, HouseholdClothing, map, project-settings or player session changes. Six subject illustrations remain outstanding.


No top-level save schema changes. Existing generic military inventories, formations and partial workshop jobs carry the new item identifiers. Full binary save/load of a partial mail job, issued formation and damaged kit passed in the initial tests. A saved old weapon remains that weapon; there is no automatic conversion of formations.

This is a partial contribution to the 5,000-discovery goal. The full history ledger, acquisition coverage, historical progression and complete illustration set remain outstanding. No player launch, canonical promotion or full-campaign pacing claim is made by this worktree.
