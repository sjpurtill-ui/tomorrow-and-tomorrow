# Optical instrument methods — authored review

This delivery adds 22 distinct authored discoveries. They connect optical craft,
measurement, coatings and biological imaging to existing foundations. They are
catalog designs with proposed operating consequences, not implemented instruments.
No runtime discoveries, recipes or artwork are promoted by this delivery.

Worktree: `/Users/seanpurtill/Documents/Codex/tt-optical-instruments-coverage`.
Branch: `codex/optical-instruments-coverage`.
Base: `50bbb263a38157fae35817a22795f5a55dc80495`.
Owned files: the new optical-instrument-methods.json, this review, and additive
historical-horizon mappings. The generated coverage summary is validation output;
the integrator should regenerate it against combined main.

## Scope and duplicate review

Coronagraphic starlight suppression already exists and is excluded. Confocal optical
sectioning was also excluded after mechanism review found the existing differently
named `confocal_biological_imaging`. Neither adds an identity. Existing broad optical
lenses, experimental optics, lens centering, optical glass homogeneity, interferometry,
biological fluorescence imaging and thin-film deposition remain their own methods.

The new coatings specify optical response, rather than repeating generic deposition.
Aspheric figuring controls shape; roughness control addresses scatter at smaller
surface scales. Achromatic matching corrects color-dependent focus; lens centering
aligns axes. Darkfield, phase contrast and differential interference create different
contrast signals. Light sheets restrict illumination geometry; multiphoton imaging
uses nonlinear excitation. Structured illumination and sparse emitter localization
use different acquisition and reconstruction strategies. Wavefront measurement is
separate from commanded deformable-mirror correction. These distinctions must survive
runtime implementation; they are not interchangeable percentage bonuses.

## Branching and disadvantaged acquisition

All mandatory parents and one member of each alternative group apply. CCD or active
pixel sensing are alternative camera foundations for the explicitly digital methods.
Ruled and holographically recorded gratings are sibling manufacturing routes.
Microscopy contrast modes do not require each other. Adaptive correction requires
measured wavefront error and feedback stability; simply owning a telescope does not
produce a correction service. Holographic recording requires interference knowledge
and physically adequate coherent illumination, but not laser manufacture: a suitable
source can be acquired. Operating requirements apply even when equipment is imported.

Each entry includes five paid recovery proposals: traveling scholar, research
partnership, commissioned research, imported/licensed service and reverse engineering.
They retain local demonstration and calibration, finite provider/transport capacity,
resource expenditure and delay. Buying a working component permits only its qualified
service; it does not grant manufacturing mastery or all parent discoveries. The
individual route contracts are attached to their destination IDs in the JSON.

The horizon assignments are capability classes, never dates or unlock gates. Modern
methods are classified H05 even when useful to a future telescope or civilization.
This addition does not pretend to close the remaining H06 coverage gap.

## Discovery review

The mechanisms below are informed by the linked primary technical sources. Parent
choices, operating costs, consequences and acquisition terms are game-design proposals.

| Discovery | Required knowledge | Proposed operating consequence | Mechanism source |
|---|---|---|---|
| Achromatic Doublet Matching | optical_lenses + experimental_optics | Produces a corrected objective for a declared wavelength range; mismatched elements require rework. | [source 1](https://www.edmundoptics.com/knowledge-center/application-notes/optics/why-use-an-achromatic-lens) |
| Aspheric Surface Figuring | optical_lenses + abrasive_grinding_control | Supplies aspheric elements; difficult profiles consume more workshop time and suffer rejection. | [source 1](https://www.edmundoptics.com/capabilities/precision-optics/capabilities/aspheric-lenses) |
| Optical Surface Roughness Control | optical_lenses + abrasive_grinding_control | Reduces scatter for demanding optics; a smooth surface with wrong figure still fails acceptance. | [source 1](https://www.edmundoptics.com/knowledge-center/application-notes/optics/superpolished-optics/) |
| Antireflection Layer Design | thin_film_deposition + experimental_optics | Improves usable light throughput within the design band; off-band or damaged coatings can degrade it. | [source 1](https://www.edmundoptics.com/knowledge-center/application-notes/lasers/anti-reflection-coatings) |
| Dielectric Mirror Stacks | thin_film_deposition + experimental_optics | Makes specialized reflective optics; coating stress and angle sensitivity constrain service. | [source 1](https://www.edmundoptics.com/capabilities/precision-optics/capabilities/optical-coatings) |
| Spectral Beamsplitter Coatings | thin_film_deposition + spectroscopy | Enables distinct illumination and detection channels; spectral leakage contaminates measurements. | [source 1](https://www.edmundoptics.com/capabilities/precision-optics/capabilities/optical-coatings) |
| Ruled Diffraction Gratings | experimental_optics + workshop_standards | Supplies dispersive components; groove errors and stray orders reduce usable spectral detail. | [source 1](https://www.edmundoptics.com/Knowledge-Center/application-notes/optics/all-about-diffraction-gratings/) |
| Holographic Grating Recording | optical_interferometry | Provides a separate grating manufacturing route; exposure instability spoils batches. | [source 1](https://www.edmundoptics.com/Knowledge-Center/application-notes/optics/all-about-diffraction-gratings/) |
| Optical Polarization Analysis | experimental_optics | Distinguishes polarization-dependent specimen and instrument behavior; poor extinction limits sensitivity. | [source 1](https://www.edmundoptics.com/c/polarization/620/) |
| Birefringent Retardation Control | optical_polarization_analysis | Changes polarization in compatible optical paths; wavelength and alignment errors change the result. | [source 1](https://www.thorlabs.com/newgrouppage9.cfm?objectgroup_id=7234&tabname=Tutorial) |
| Darkfield Illumination | compound_microscopy | Reveals weakly scattering structures against a dark field; dust also produces misleading bright features. | [source 1](https://www.youtube.com/watch?v=I4ZQm-CAgL8) |
| Phase-Contrast Microscopy | compound_microscopy + experimental_optics | Shows suitable unstained specimens; halos can obscure or exaggerate boundaries. | [source 1](https://www.microscopyu.com/techniques/phase-contrast/introduction-to-phase-contrast-microscopy) |
| Differential Interference Microscopy | compound_microscopy + birefringent_retardation_control | Improves edge contrast; apparent relief is not a measured surface height. | [source 1](https://pmc.ncbi.nlm.nih.gov/articles/PMC2762238/) |
| Multiphoton Excitation Imaging | biological_fluorescence_imaging + laser_light_generation | Supports imaging within suitable thick samples; scattering and exposure still limit useful depth. | [source 1](https://www.microscope.healthcare.nikon.com/en_AOM/products/confocal-microscopes) |
| Light-Sheet Illumination | biological_fluorescence_imaging | Limits unnecessary illumination in volume imaging; shadowing and alignment create incomplete sections. | [source 1](https://www.microscopyu.com/techniques/light-sheet/light-sheet-fluorescence-microscopy) |
| Structured-Illumination Reconstruction | biological_fluorescence_imaging + (charge_coupled_image_sensors OR active_pixel_image_sensors) | Improves resolved detail on qualified samples; motion and model mismatch create artifacts. | [source 1](https://www.nikon.com/company/technology/technology_fields/optics/super-resolution_microscopic/) |
| Single-Molecule Localization Imaging | biological_fluorescence_imaging + (charge_coupled_image_sensors OR active_pixel_image_sensors) | Maps labeled features below ordinary image resolution; crowding and sparse sampling distort reconstructions. | [source 1](https://www.microscope.healthcare.nikon.com/en_EU/products/super-resolution-microscopes/n-storm-super-resolution) |
| Wavefront Sensor Calibration | experimental_optics + (charge_coupled_image_sensors OR active_pixel_image_sensors) | Produces bounded optical-error estimates; noise and unsensed modes remain explicit uncertainty. | [source 1](https://opg.optica.org/ao/abstract.cfm?uri=ao-44-30-6419), [source 2](https://www.thorlabs.com/images/Catalog/V21/V21_7_LightAnalysis.pdf) |
| Deformable Mirror Correction | wavefront_sensor_calibration + feedback_stability_analysis | Corrects supported optical aberrations; actuator limits and delayed feedback leave residual error. | [source 1](https://arxiv.org/abs/2309.05748) |
| Optical Stray-Light Baffling | experimental_optics | Improves contrast under bright surroundings; poorly placed baffles vignette the desired field. | [source 1](https://ntrs.nasa.gov/archive/nasa/casi.ntrs.nasa.gov/19730014804.pdf) |
| Immersion Objective Matching | compound_microscopy + experimental_optics | Preserves useful numerical aperture and correction; mismatched media introduce aberrations. | [source 1](https://www.microscopyu.com/microscopy-basics/water-immersion-objectives) |
| Optical Spatial Filtering | optical_lenses + experimental_optics | Supplies a cleaner beam for compatible experiments; misalignment loses light and can damage the aperture. | [source 1](https://www.newport.com/c/spatial-filters), [source 2](https://www.newport.com.cn/n/spatial-filters) |

## Acceptance and remaining work

The catalog validator checks ID/name uniqueness, known parent references, AND/OR
reachability, required fields, field totals and digest-matched horizon mappings.
A separate semantic pass checked the neighboring optical, biological and space
methods and removed the two overlaps identified above. These checks do not prove
historical chronology, useful game balance or functioning production.

Runtime implementation must attach actual manufactured/imported equipment, local
operator and research time, samples, calibration/error records, finite throughput,
maintenance and failure behavior. Observation and image quality must affect eligible
research evidence rather than inventing specimens or guaranteeing a discovery.
Human and owned civilizations need the same scoped service rules and save support.
Later implementation must validate those mechanisms and UI with focused behavioral
checks. Artwork, global pacing and the full 5,000-discovery target remain unfinished.

Validated outcome: 22 new identities; 3,161 total authored identities on this base; 1,839 remain to author. No missing parents, unreachable drafts or duplicate normalized names. New field allocation: D04=3, D06=4, D12=7, D15=8. Horizon allocation: H03=1, H04=6, H05=15. All 22 entries retain five destination-specific paid recovery proposals. Catalog check and git diff --check exit 0. Operating tests are intentionally deferred until runtime consumers exist.
