# Retained PEG specimen end-group interpretation

Worktree: `/Users/seanpurtill/.codex/worktrees/ef8f/tomorrow-and-tomorrow`; branch `codex/polymer-peg-endgroup-assay`; base `0947d0efc8db5c6a5696526b67ffb6e33dec40f1`. Scope is the new pure helper, its test suite and this note. The polymer worker owns acquisition, actual instruments, preparation, specimen retention, consumer integration and save validation. This helper alone promotes no discovery.

## Supported inference

For declared linear alpha,omega-dihydroxy PEG, `HO(CH2CH2O)nH`, each molecule has two terminal CH2OH carbon atoms and `2n-2` other carbon atoms. With quantitative carbon response, let E be the combined area of both terminal carbons and B the combined area of **all other carbons**, including shifted near-terminal carbons. Then the sample's number-mean repeat count is `DPn = 1 + B/E`. This is a stoichiometric derivation under the stated structure assumption. Integrating only the central backbone resonance can omit near-terminal carbons and is rejected by the completeness contract.

The function returns the conditional number mean and an interval computed from supplied absolute area-error bounds:

`lower = 1 + (B - error_B)/(E + error_E)`

`upper = 1 + (B + error_B)/(E - error_E)`

These are conservative ratio bounds given those input bounds, not an independently calibrated confidence interval. They do not establish molecular-weight distribution, dispersity, tacticity, purity, a synthesis setting, or the quality of another specimen or bulk stock. Equal molecule counts of DP 10 and DP 30 produce a mean of 20; the two component lengths cannot be recovered from these two integrals.

## Input contract

Call `evaluate(observation, expected_sample_id, expected_store)`. It never accesses world state and never changes its input. The caller must obtain expected provenance from the retained specimen record, not copy it blindly from an observation. Empty `expected_store` denotes the existing primary store.

- Identity: `sample_id`, `source_store`, unique `acquisition_id`, `assay = linear_peg_terminal_carbon_v1`, `nucleus = 13C`.
- Established structure/assignment: `structure = linear_dihydroxy_peg`, `endgroup_assignment = two_terminal_ch2oh_carbons`, `assignment_unambiguous = true`, `all_nonterminal_carbons_included = true`. These are externally established assay premises. The helper cannot prove linearity, exclude cyclic contaminants or identify end groups from two area numbers. Unknown, branched, cyclic and singly capped material is unsupported. Do not set these flags merely because a stock name says PEG.
- `reference`: accepted measured `reference_id`, matching `acquisition_id`, `valid_during_acquisition = true`, finite `shift_error` and `temperature_drift`. Attaching a newer reference to an old trace does not establish validity.
- `quantitative`: `method = inverse_gated_13c`, `relaxation_verified = true`, measured `delay_over_longest_t1 >= 5`. An ordinary broadband-decoupled spectrum does not automatically provide quantitative area ratios. The caller must connect this contract to its actual paid acquisition model and validated relaxation evidence.
- Exactly two `peaks` integration regions, assignments `terminal_ch2oh` and `remaining_backbone`. Each contains positive finite `area`, nonnegative absolute `area_uncertainty`, `snr`, finite ordered `lower`/`upper` region boundaries, `resolved = true`, `contaminated = false`. Regions must be strictly disjoint. The backbone region may include multiple assigned resonances; the complete assigned area must be supplied.

Selected **game** acceptance limits are SNR at least 10, each area bound at most 10%, reference shift error at most 0.05, thermal drift at most 0.5, and the entire DP interval between 2 and 1,000. Coordinate and drift units are synthetic assay units, not chemical shifts or hardware specifications. These are bounded gameplay acceptance choices, not universal laboratory standards. The helper rejects results outside its supported interval instead of clipping them to a passing value. Exchangeable OH proton integration is not this carbon assay.

Accepted results retain specimen/acquisition provenance, `scope = retained_sample_only`, `distribution_measured = false`, `stock_qualified = false`. Failures contain a reason and no numerical result. The helper does not authorize a material consumer; the worker must retain, account for and consume the actual characterized specimen in its paid route. No stock, discovery, recipe, day, save or UI owner changes here. Existing saves are unaffected until the worker adds its separately validated acquisition fields.

## Primary sources and limits

[Liu, 1968, NMR analysis of PEG near-end groups](https://doi.org/10.1002/macp.1968.021160115) reports number-average molecular-weight inference from chain-segment/near-end NMR ratios. Only the indexed abstract was accessible; no specific experiment or calibration constants from its full paper are claimed here.

[Harrison and coauthors, 2000, PEG vinyl-ether end groups](https://doi.org/10.1002/%28SICI%291099-0518%2820000101%2938%3A1%3C152%3A%3AAID-POLA20%3E3.0.CO%3B2-3) reports distinct internal, terminal CH2OH and adjacent-carbon resonances and multiple end-group species. This supports keeping end identity and complete region assignment explicit; it does not establish that every produced PEG specimen is linear dihydroxy material. The implementation uses synthetic coordinates rather than copying solvent-specific shifts.

[JEOL, quantitative carbon measurements](https://www.jeol.com/solutions/applications/details/NM190016E.php) explains that quantitative acquisition requires sufficient magnetization recovery and distinguishes quantitative methods from intensity-biased spectra. [Giraudeau, Wang and Baguet, inverse-gated quantitative carbon NMR](https://comptes-rendus.academie-sciences.fr/chimie/articles/en/10.1016/j.crci.2005.06.030/) discusses inverse-gated decoupling and relaxation-delay requirements. The five-T1 minimum is the selected lower acceptance boundary of this game method; successful timing alone cannot resolve overlapping peaks or establish unknown sample structure.

## Verification

Focused tests cover a known carbon-count ratio and uncertainty bounds, a chain-length mixture, input immutability, wrong sample/store/acquisition provenance, unsupported structures/end groups, missing or ambiguous integration, overlap and duplicate assignments, resolution/noise/contamination, nonquantitative acquisition, reference drift/validity, malformed/nonfinite values and out-of-range intervals. Combined runtime connection, paid preparation/acquisition, save continuation and actual consumer use remain the worker's integration checks.

Godot 4.7.2 focused run: **9 cases, 0 errors, 0 failures, 0 skipped, 0 orphans**, 44 ms suite time. Log `/tmp/tt-peg-endgroup-tests.log`; explicit worktree path as above. No player launch or main merge.
