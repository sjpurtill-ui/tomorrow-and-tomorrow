# Bounded retained PEG distribution measurement

Status: measured-response core implemented; instrument operation, paid acquisition
and the distribution-dependent consumer are not yet connected. This is not an
accepted runtime discovery or a campaign completion claim.

`sec_elution_model.gd` accepts an explicit retained mixture of chain sizes and
number fractions. It forms a concentration-detector response weighted by chain
mass, separates sizes by a selected logarithmic retention relation and broadens
that response with column width and receiver noise. Returned evidence contains
601 measured points, flow, sample identity, injected mass and a column epoch; it
does not contain the latent chain sizes or fractions. The numerical retention,
width and sensitivity values are bounded synthetic game assumptions.

`sec_distribution_analysis.gd` uses separate observed injections of the three
assigned narrow PEG references (DP10, DP40, DP160) to establish the retention
curve, response scale and resolution. It rejects invalid provenance, weak or
unresolved reference traces and inconsistent flow/order/curve measurements.
Sample interpretation checks identity, column epoch, flow, recovered signal,
sensitivity and finite calibrated range. Boundary samples whose broadened signal
cannot be assigned within the range are rejected rather than extrapolated.

The report contains four observed mass-fraction bins (10–20, 20–40, 40–80 and
80–160), with instrumental broadening retained. It explicitly denies exact chain
reconstruction or absolute mass certification. A conservative interior fraction
for the 20–80 interval discounts measured reference width and receiver noise; a
fraction of at least 0.9 is the proposed narrow-binder qualification. This rule
still needs the paid manufacturing consumer. It is a selected game material
specification, not an empirical universal PEG adhesive-performance claim.

Five focused cases pass: same-number-mean/different-distribution samples produce
different measured bins and qualification decisions; out-of-range and boundary
samples fail; bad resolution/reference assignment fails; changed epoch/flow,
loss and weak sensitivity fail; malformed saved evidence is rejected. A pure
DP35 specimen and equal chain counts at DP15/55 share mean DP35, while their
observed concentration profiles and binder candidacy differ.

The method follows the relative calibration and stable-flow structure described
in [Waters' aqueous PEG/PEO application](https://www.waters.com/nextgen/in/en/library/application-notes/2021/arc-hplc-aqueous-sec-gpc-separation-of-peo-peg.html)
and [calibration primer](https://www.waters.com/nextgen/ca/en/education/primers/beginners-guide-to-size-exclusion-chromatography/calibration-of-the-gpc-system1.html).
Their commercial instrument coefficients are not used as game performance claims.
Compatible medium and assigned standards have the explicit finite supplier
boundary documented in `SEC_SPECIALIST_SUPPLY.md`; generic polymer inventory does
not supply reference provenance.
