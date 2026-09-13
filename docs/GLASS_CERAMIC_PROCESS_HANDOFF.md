# Glass and ceramic workshop processes

Worktree `/Users/seanpurtill/.codex/worktrees/ef8f/tomorrow-and-tomorrow`, branch `codex/glass-ceramic-processes`, base `b5e23d5779c9160749fc95d986615807affc70b1`. Integrator scope: new glass_ceramic_process_knowledge.gd, additive CivilianIndustry recipes and Discovery registration, focused tests and this handoff. Concurrent textile work owns its separate definitions, planner and HouseholdClothing changes.

## Operating behavior

Five existing authored identities, with original AND/OR prerequisites retained: glass_batch_composition_control, glass_annealing_schedules, ceramic_slip_casting, high_fire_stoneware and ceramic_glaze_formulation. No new identities or passive numerical discovery effects.

Eleven recipes use the existing finite-work, paid-tooling PersistentProduction owner:

- Recorded compatible cullet preparation consumes 1.25 Glass and a fraction of actual Clay Record Tablets per batch, rejecting unqualified feed; remelting returns one Glass using fuel, crucible and refractory equipment. A complete cycle loses material and uses work. This represents sorting and proportioning compatible existing glass, not arbitrary composition measurement or free mineral extraction.
- Annealing consumes formed glass stock, fuel and refractory equipment over three worker-days. The resulting blank supports a separate lens-grinding route, which pays abrasive and labor and supplies existing lens mounts and optics.
- Pottery mold preparation consumes real Gypsum, water, fuel and work. Gypsum currently comes from the existing industrial recipe or imports, so local slip casting can be supply-limited despite early prerequisites. It does not conjure an early gypsum deposit.
- Stoneware-body trials consume extra prepared clay, silica, water and fuel, including rejected test material. This is a bounded qualified clay class; arbitrary local clay chemistry, feldspar selection and kiln atmospheres are not simulated. Hand forming and slip casting are alternatives. Slip casting consumes mold wear and water, produces a dry green form, and still needs a separately paid high-fire route.
- Glazing consumes 1.1 fired vessels per accepted batch plus prepared glaze ingredients, water and another firing. The extra vessel fraction pays for fit trials and rejection. Only the resulting compatible glazed vessels are accepted by the new brine-purification setup; green forms and bare stoneware cannot substitute there.

Imported intermediate goods work with downstream skills without granting upstream manufacturing knowledge. Each workshop uses the existing crafting allocation, paid setup and proportionally consumed material records. No duplicate stock, daily simulation, population or save authority is added. New names are ordinary stockpile goods; existing production jobs preserve paid partial work and materials.

## Physical references and abstraction limits

[Corning Museum of Glass: annealing](https://allaboutglass.cmog.org/definition/annealing) describes controlled slow cooling of formed objects. [USG ceramics application guide](https://www.usg.com/content/dam/USG/pdpmovedocuments/plasters-gypsum-cements-for-ceramics-application-guide-en-IG526.pdf) explains absorbent molds and their drying constraints. [Digitalfire casting slip](https://digitalfire.com/glossary/casting%2Bslip), [glaze fit](https://www.digitalfire.com/glossary/glaze%2Bfit) and [vitrification](https://digitalfire.com/glossary/95) motivate separated forming, firing and compatibility checks.

The coefficients are game-scale material and work quantities, not manufacturing instructions or certification. Work includes drying/cooling; it does not yet track elapsed thermal histories, residual stress, mold moisture, body porosity, chemical assay values or individual rejected defects. Glazed vessels qualify for the specific brine workshop only; no universal food, medical, acid or refractory compatibility is implied. New standalone art and full historical pacing remain outstanding.

## Acceptance

Worktree verification: 65 distinct cases pass: new processes6, persistent production19, civilian planner15, refractory ceramics3, prior glassworking4 and clinical care18. The initial new suite had two untyped test locals, then a fixture incorrectly expected all inputs consumed up front; corrected to verify the existing proportional consumption across partial-save continuation. Final six pass; no runtime owner was changed to satisfy a fixture. Graph is clean at708 discoveries,490 routes,352 recipes and18 facilities. INTEGRATED canonical `5449d0f3bbdb7c691cfe30e869549f92b22454bb`: 40 cases pass (new6, persistent19, planner15); exact708 snapshot and15 ledger tests pass. Clean normal headless boot. Logs `/tmp/tt-glass-ceramic-final-results.json` and `/tmp/tt-glass-ceramic-canonical-canonical-results.json`. Verified behaviors include: actual downstream consumption, conserved feed/fuel and mold wear, shortages before setup, inability to use unfired/unglazed intermediates as finished apparatus, imported inputs and partial paid-work continuation. Retain current clinical and textile integration behavior.
