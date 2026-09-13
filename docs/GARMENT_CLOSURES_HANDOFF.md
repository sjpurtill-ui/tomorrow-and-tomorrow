# Paid garment closures

Worktree: `/Users/seanpurtill/.codex/worktrees/ef8f/tomorrow-and-tomorrow`.
Branch: `codex/garment-closures`; base: `6fed85fb93fef79b3cabd134047b010b04437150`.

Two authored identities retain exact predicates: buttonhole reinforcement requires
bone-needle sewing and garment-pattern cutting; snap closures require leather-goods
patterning and elastic deformation. Neither has an OR prerequisite.

Ten workshop recipes make actual components and checked panels. The selected
button route shapes steel hand needles and wooden buttons, stitches reinforced
cloth openings, then fits and checks the assembled fronts. Actual fronts plus
remaining cloth and thread become ordinary fitted garments. The snap route makes
forming dies, matching shell parts and resilient rings from tempered coils, checks
their assembly, gauges supported leather tabs, and sets/checks the attachment.
Actual checked panels, leather and thread become ordinary leather garments.

Existing workshop setup consumes tooling; each panel, ring, button and trial
allowance also costs stock and finite work. A missing spring blocks assembly;
loose parts, raw cloth and ungauged leather cannot substitute for checked output.
The existing production planner/controller can order missing checked fronts and
the daily clothing owner consumes them through its shared Logistics budget.
No new labor, daily simulation, installation, household-lot or save owner exists.

These are fixed compatible game designs. Checking work and the 1.02 input
allowance represent a bounded acceptance process, not a simulated arbitrary
geometry, force trace or certification standard. The units are game batches.
Woven cloth or flexible leather is the selected substrate class; incompatible
grades do not become valid through knowledge alone. There is no separate
fastener-failure simulation. Finished garments use the existing fitted/leather
condition, issue, washing and repair behavior; ordinary textile or leather repair
does not claim to replace broken hardware. No insulation, waterproofing or
strength bonus is granted. Production reports and stock labels identify the
closure route; aggregate garment lots do not retain individual hardware identity.

Seven focused cases pass: exact predicates and all ten fractional paid recipes;
both complete manufactured-component chains into issued clothing; unchecked and
missing parts; paid installation and same-day limits; planner/controller demand;
and partial full-save continuation with separate actor garments and no duplicate
completion. Another 118 regression cases pass across clothing, leather, quilting,
sewing machinery, persistent production, planning, civilization ownership and
dependency auditing. Initial fixture errors were corrected to account for setup
tooling consumption and production-start rejection; runtime owners were unchanged.
Two dedicated illustrations retain native originals and use 768-pixel mipmapped
Godot imports. Final atlas/canonical verification is recorded in INTEGRATION_STATUS.

Existing saves retain their current lot formats and methods. Only two optional
method-tool entries and ordinary production jobs/stocks are added. Shared-file
changes are additive in `clothing_knowledge.gd`, `civilian_industry.gd` and
`hud/research_visuals.gd`; the existing method-count test is updated to 18.
No player launch or package rebuild is included.

JUKI describes separate buttonhole edge and bar-tack tension control and prevention
of unraveling in its [buttonholing-machine documentation](https://www.juki.co.jp/industrial_e/products_e/appareljin_e/button_hole_jin/detail_jin.php?cd=B-1E_E).
This supports the functional distinction, not the speed or historical dating of
the selected hand-work route. YKK identifies spring-snap families in its
[snap-button overview](https://www.ykk.dk/en/produkter/trykknapper) and warns that
uneven substrate thickness can cause attachment failure or weak engagement in its
[attachment FAQ](https://ykkamericas.com/about-us/faqs/). Costs, prerequisites,
fixed part classes and inspection yields here are game-design inferences.
