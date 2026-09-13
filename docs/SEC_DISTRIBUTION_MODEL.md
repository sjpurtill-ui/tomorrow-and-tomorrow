# Bounded retained PEG distribution measurement

Status: connected to a built instrument, finite column/reference supply, paid
daily calibration and acquisition, saved retained specimens and two binder routes.
This remains isolated and unintegrated; it is not a campaign completion claim.

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
fraction of at least 0.9 is the proposed narrow-binder qualification. The selected route uses one qualified batch and four work units; broad-range
rework uses 1.2 recovered batches and six work units for the same binder output. It is a selected game material
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


## Connected operating evidence

The bench is assembled from a manufactured metering pump and optical flow cell;
column packing and reference-solution recipes consume the supplied materials.
Commissioning costs actual bench capital, steel and 16 work units. One effective
operator and two power units provide one daily column-time unit. Preparation
consumes a packed column and reference set, water and paper, then spends six
instrument-time units on conditioning and observed references. A column supports
at most eight runs and expires after 30 days. A run reserves one retained batch,
water and paper and spends four instrument-time units. Expiry during a run loses
that run; no grade appears. Material shortages are atomic and duplicate calls
cannot exceed the shared daily channel.

The existing sample ledger holds separate SEC preparation records; NMR does not
acquire them. Synthesized game samples have either a narrow three-component or
broader two-component distribution, not a claim of perfectly monodisperse output.
Accepted results release one corresponding physical batch into the selected or
rework route. Both produce Binder-Grade PEG, then the existing aqueous binder
consumer. The operations panel reports the selected result. Partial and completed
full save/load checks preserve spent materials and prevent duplicate release.


## Ownership and store scope

SEC and NMR laboratories operate only at the primary settled home through the
existing technology-operations service owner. Secondary stores cannot spend that
service. Pending selection filters sample source stores before commissioning or
calibration, so a remote-only specimen cannot consume primary supplies. Two
civilizations can have the same local sample ID while keeping their columns,
work, stocks and released grades independent. This is not support for secondary
laboratories or automatic transport of retained samples.
