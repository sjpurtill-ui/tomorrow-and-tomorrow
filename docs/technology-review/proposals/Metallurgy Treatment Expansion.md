# Eight additional metallurgy discovery proposals

These are new authored proposals for review, outside the reconciled master ledger and runtime. None counts as an integrated discovery. Identity/name checks found no exact duplicates across the existing array-backed drafts and dictionary-backed baseline/pending catalogs; all proposed parents resolve there. The existing twelve-discovery implementation batch is unchanged.

Sources support the distinct technical mechanisms. Branches, costs, applications and failure behavior below are game-design proposals; no dates or universal chronology are asserted.

## Jominy End-Quench Testing

Quench one end of a heated steel specimen and measure hardness along its length to characterize hardenability. [Source](https://www.mdpi.com/2227-9717/9/4/607).

**Common foundations:** hardened_edges, dimensional_metrology. **Alternative foundation:** experimental_controls OR material_phase_diagrams.

**Operation:** Consume a representative bar, furnace energy, controlled water jet and surface preparation; use qualified temperature, distance and indentation measurements.

**Consequence:** Select steel and cooling conditions for section-dependent hardening of shafts, gears and armor components; retain a distance-hardness curve tied to the sampled heat.

**Failure/limits:** Uneven transfer, poor jet control or invalid indentations invalidate the curve. Hardenability is not maximum attainable hardness; the test does not prove full-part performance.

**Why separate:** Generic hardened edges and induction surface treatment do not measure a cooling-gradient response along a standard specimen.

## Charpy Notched Impact Testing

Strike a supported notched specimen with a pendulum and determine absorbed fracture energy at a recorded test temperature. [Source](https://www.twi-global.com/technical-knowledge/faqs/faq-what-is-charpy-testing).

**Common foundations:** stress_strain_relations, dimensional_metrology, precision_thermometry.

**Operation:** Pay specimen machining and destruction, temperature conditioning, calibrated pendulum/anvil operation and repeated observations.

**Consequence:** Compare notch-impact behavior for cold-service hull plate, welds and machinery; reject lots that fail the declared service-temperature requirement.

**Failure/limits:** Notch, striker or temperature differences prevent direct comparison. Absorbed impact energy does not supply a fracture-toughness value.

**Why separate:** Distinct from precracked fracture testing: a notched high-rate pendulum test has its own measured quantity and acceptance scope.

## Steel Austempering

Quench suitable austenitized steel to a controlled temperature above martensite start and hold for bainitic transformation. [Source](https://www.bodycote.com/what-we-do/precision-heat-treatment/hardening-and-tempering-atmosphere-vacuum/austempering/).

**Common foundations:** metal_annealing_control, precision_thermometry. **Alternative foundation:** experimental_controls OR material_phase_diagrams.

**Operation:** Pay selected feed, heating, bath control, transfer, holding time, waste handling and verification on the actual section.

**Consequence:** Produce qualified clips, springs and thin components with a measured hardness/toughness/distortion combination.

**Failure/limits:** An unsuitable alloy, excessive section thickness or missed transfer/hold conditions can produce mixed structures and rejected parts.

**Why separate:** Distinct from martempering: the intermediate hold is intended to transform the structure, rather than only equalize temperature.

## Steel Martempering

Interrupt quenching near the transformation range to equalize a component temperature before subsequent cooling. [Source](https://www.bodycote.com/fr/glossaire-technique/martempering/).

**Common foundations:** metal_annealing_control, precision_thermometry. **Alternative foundation:** experimental_controls OR material_phase_diagrams.

**Operation:** Pay a controlled bath, known material transformation behavior, transfer and equalization work, subsequent cooling, tempering where required and dimensional checks.

**Consequence:** Offer a distortion-control route for hardenable gears and tooling while preserving component-specific acceptance tests.

**Failure/limits:** Holding too long or choosing the wrong temperature can cause unwanted transformation; temperature equalization alone does not establish acceptable hardness.

**Why separate:** Distinct from austempering and ordinary tempering; it controls the quench sequence rather than substituting a generic heat-treatment bonus.

## Steel Carbonitriding

Diffuse carbon and nitrogen into a suitable steel surface in a controlled atmosphere and subsequently harden the case. [Source](https://www.bodycote.com/?p=17895).

**Common foundations:** hardened_edges, steel_nitriding_qualification. **Alternative foundation:** experimental_controls OR material_phase_diagrams.

**Operation:** Pay carbon-bearing gas, ammonia supply, atmosphere control, furnace energy, quenching and case-depth/composition/hardness checks.

**Consequence:** Produce accepted shallow-case wear parts such as pins and small gears with separately verified core and case behavior.

**Failure/limits:** Incorrect gas potential, temperature or quenching can create a brittle or inadequate case; imported gases do not confer process mastery.

**Why separate:** Distinct from nitriding-only treatment and induction heating: carbon and nitrogen diffusion jointly modify the case.

## Controlled Shot Peening

Use controlled repeated shot impacts to plastically deform the surface and introduce a residual compressive layer. [Source](https://surfacetechnologies.curtisswright.com/our-services/shot-peening/controlling-the-shot-peening-process).

**Common foundations:** stress_strain_relations, cyclic_fatigue. **Alternative foundation:** residual_stress_assessment OR experimental_controls.

**Operation:** Pay graded media, powered delivery, coverage/intensity control, masking and part-specific qualification with retained process records.

**Consequence:** Treat qualified springs, shafts and airframe parts for their specified cyclic-loading conditions; record the treated surface and consumed media.

**Failure/limits:** Poor coverage, unsuitable media or excessive intensity can damage the surface. A visual finish alone does not certify the treatment.

**Why separate:** Distinct from abrasive cleaning and residual-stress measurement: this is a controlled surface-working operation.

## Electroslag Remelting

Pass current through a slag bath to remelt a consumable electrode into a controlled, cooled ingot. [Source](https://www.ald-vt.com/wp-content/uploads/2017/12/general-broschure.pdf).

**Common foundations:** electric_arc_furnaces, metal_casting_feed_design.

**Operation:** Pay an electrode, selected slag, electrical power, mold cooling and melt-rate control; inspect ingot chemistry and soundness.

**Consequence:** Produce qualified remelted stock for heavy forgings, tooling and demanding machinery while charging remelting losses and time.

**Failure/limits:** Slag chemistry, electrode feed or cooling failures can cause inclusions or unsound solidification; remelting never guarantees purity.

**Why separate:** Distinct from vacuum arc remelting: the slag-mediated process is the defining mechanism and does not require vacuum as a common foundation.

## Vacuum Arc Remelting

Remelt a consumable metal electrode with an arc under vacuum while controlling the solidifying ingot. [Source](https://www.ald-vt.com/portfolio/engineering/processes/).

**Common foundations:** electric_arc_furnaces, vacuum_metal_melting, metal_casting_feed_design.

**Operation:** Pay electrode preparation, vacuum pumping, arc power, mold cooling and melt-rate monitoring; inspect the resulting ingot.

**Consequence:** Supply qualified stock for demanding turbine, aerospace and other machinery applications with tracked remelting cost and yield.

**Failure/limits:** Unstable arc or melt rate, vacuum loss and solidification defects can reject the ingot; vacuum alone does not qualify its structure.

**Why separate:** Distinct from ordinary vacuum melting and electroslag remelting: consumable-electrode arc remelting is a separate controlled operation.

## Acquisition and next steps

Every proposal includes paid specialist instruction, bilateral research, commissioned studies and imported processing contracts. All retain delivery, local demonstration, finite capacity and supplier dependency; none grants instant mastery. Imported parts can provide a temporary operating advantage while domestic research remains incomplete.

Integrator reconciliation must review semantic overlap, causal branches and source scope before adding these eight to the authoritative authored count. Implementation, AI use, military/civilian consumers, save behavior, pacing and approved imagery are still required. See the adjacent JSON for machine-readable records.
