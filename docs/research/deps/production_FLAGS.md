# Production year flags

Registry years left unchanged.

- `ore_assaying` (85) vs `copper_outcrop_signs` (ecology 140): the order is reversed, as `REGISTRY_NOTES` already records. `copper_outcrop_signs` is kept as a precedent only. Suggest moving `copper_outcrop_signs` to about 80, or treating it as a later prospecting refinement.
- `goldsmith_filigree` (400) vs `hard_soldering` (450): granulation and filigree need solder. `hard_soldering` is mapped to require filigree (sheet goldwork comes first). Suggest moving `hard_soldering` to about 400, or reading "granulation" at 400 as colloidal/diffusion bonding.
- `copper_carpentry_tools` (350) vs `timber_post_beam_connections` (infrastructure 180, "cut with copper chisels"): mortising at 180 depends on `copper_casting` (105), not on this item. Suggest moving `copper_carpentry_tools` to about 200–250, or keeping 350 as the saws and stone-cutting set only.
- `cored_socket_casting` (540) vs `socketed_spearheads` (security 450): a socketed spear needs a cored casting. Suggest moving `cored_socket_casting` to about 440, or letting security map spearheads on `closed_moulds` (380).
- `copper_smelting` (90) is named "in crucibles", but `ceramic_crucibles` (570) is "refractory crucibles". The early crucibles are plain clay. This is a naming overlap, not a year error.
- `pot_bellows` (420) comes after `tin_smelting` (330) and `bronze_alloying` (360). This is plausible, because blowpipe smelting came first. No change.
- `peat_drying` (490): the technique is simple and could come much earlier. It is mapped on fuel pressure (`fuelwood_rotation` 275). It needs an environment gate (wetland/bog), but the contract has no such value.
- `meteoric_iron_working` (265): the resource gate "Meteoric iron" may not exist in game resources. Verify the name.
- The resource-gate names used here (Clay, Copper, Limestone, Lead, Tin, Gold, Sulfur, Alum, Bitumen, Gypsum) need checking against the game's resource names.
