# Food processing service coverage

READY authored-only delivery: 23 new discoveries in `master-catalog/food-processing-service-depth.json`. Worktree `/Users/seanpurtill/Documents/Codex/tt-food-processing-coverage`, branch `codex/food-processing-coverage`, base `7c7efe01eceae0b439cc30c5d9799d665e442753`. The entries define proposed mechanics; they do not add operating recipes, inventory resources, buildings, artwork or save fields.

## New historical coverage

| Area | Discoveries | Proposed consequence |
|---|---|---|
| Gathering and crop preparation | Nut Kernel Shelling; Acorn Leaching; Root Grating and Dewatering; Pulse Splitting; Grain Parboiling | Recover usable fractions with species-appropriate preparation, actual losses, labor, water and fuel costs. |
| Fruit and sweeteners | Fruit Pulp Screening; Pectin Gel Preservation; Sugar Crystal Recovery; Refractometric Food Solids Testing | Produce and qualify different retained fractions; concentration never creates ingredients and optical readings do not prove safety. |
| Dairy | Cheese Ripening Control; Cultured Milk Processing; Milk Fat Clarification; Whey Protein Recovery; Centrifugal Cream Separation | Expand use of milk and its co-products while consuming storage capacity, energy and handling time. |
| Drying and oil | Indirect Solar Food Drying; Edible Oil Winterization | Use available weather or controlled cooling to produce suitable stored products, with finite capacity and separation losses. |
| Qualified industrial food service | Modified Atmosphere Food Packing; Food Metal Detection; Food X-ray Foreign Body Inspection; Membrane Food Fractionation; High Pressure Food Processing; Pulsed Electric Food Treatment; Food Enzyme Process Control | Add specific preservation, inspection and separation options that require compatible products and maintained equipment. |

This is a mechanism catalog, not a list of flavors. Shelling removes hard external material; pulse splitting prepares cotyledon fractions; existing milling remains general comminution. Existing curd processing creates curd and whey; maturation occupies controlled storage, cream separation partitions fat, and whey recovery uses a previously separated stream. Each proposed output must retain its share of the original mass. Nutrient retention, spoilage and labor-release effects need implementation and tuning, not unconditional bonuses.

## Duplicate and branching review

Existing cereal dehulling was removed from this delivery when checked against the implemented baseline. Existing starch washing separation, food acidity measurement, water activity measurement, general drying, smoking, package leak detection and package barrier testing are also excluded from the new count. Indirect solar drying is a particular collector/chamber service; it does not replace or recount general drying. Modified-atmosphere packing changes an actual package environment; barrier testing only supplies qualification evidence. Membrane food fractionation is a hygienic product-stream service, not a duplicate of the general water membrane method.

Mandatory prerequisites combine with one member of every alternative group. Early practices use empirical knowledge and local preparation traditions. Heated preserving and dairy methods do not require bread-oven discovery: their heat foundation is `hearth_heat_retention`. Nut processing and root preparation accept appropriate alternative tool traditions. Pulse-field processing accepts alternative electrical foundations; it does not force battery manufacture. Food X-ray inspection uses radiation and physics foundations rather than importing the whole medical diagnostic profession into a food-processing branch.

Compatible tools, cultures, ingredients and treatment services can be acquired externally. Every entry proposes paid specialist travel, contributed partnership trials, commissioned research, licensed/imported service and analysis of acquired products or records. Each route remains delayed, provider-limited and subject to local demonstration. A finished food cannot establish its hidden preparation process or keeping quality. Imported equipment does not grant the ability to manufacture it.

## Sources and scope

The sources establish technical or ethnographic mechanisms. Horizon assignments, causal learning dependencies, operating costs and recovery contracts are editorial game design. No unique inventor, universal sequence or calendar unlock is asserted. No food-preparation recipe or real-world safety certification is provided.

- [FAO oil-bearing material processing](https://www.fao.org/4/X5043E/x5043E03.htm) supports shell separation; [NPS account of Cahuilla acorn preparation](https://home.nps.gov/articles/000/recipes-acorn-bread-chia-pudding.htm) supports the specifically bounded leaching subject. That account is not proof that any unfamiliar plant is edible.
- [FAO roots and tubers](https://www.fao.org/4/x5415e/x5415e05.htm), [cereal processing](https://www.fao.org/4/v5380e/v5380e06.htm) and [ICAR pulse processing](https://www.icar-iipr.org.in/wp-content/themes/ICAR-wp/images/pdf/postbulletins2may13.pdf) support the distinct preparation operations. Root pressing alone does not establish a safe finished product.
- [FAO fruit processing](https://www.fao.org/4/v5030e/V5030E0y.htm) and [preservation methods](https://www.fao.org/4/V5030E/V5030E0c.htm) support pulp, gels, optical solids assessment and solar drying.
- [FAO dairy processing](https://www.fao.org/4/t0755e/t0755e01.htm), [milk processing overview](https://www.fao.org/dairy-production-products/processing/milk-processing/en) and [milk separation proceedings](https://www.fao.org/fileadmin/user_upload/ags/publications/econf-proc-english.pdf) distinguish maturation, culture, fat concentration, whey recovery and centrifugal separation.
- [FAO edible oils report](https://www.fao.org/4/a1090e/a1090e00.pdf) supports winterization; [agribusiness handbook](https://www.fao.org/4/ae374e/ae374e00.pdf) supports sugar-crystal recovery.
- [FDA food-code discussion](https://www.fda.gov/media/184685/download) informs the bounded packing subject, without importing current legal requirements into game rules. [FDA metal-inclusion guidance](https://www.fda.gov/files/food/published/Fish-and-Fishery-Products-Hazards-and-Controls-Guidance-Chapter-20--Metal-Inclusion-Download.pdf) and [X-ray inspection research](https://arxiv.org/abs/2104.05326) support different detection mechanisms.
- [FAO juice separation](https://www.fao.org/4/y2515e/y2515e07.htm), [EFSA pressure-treatment assessment](https://www.efsa.europa.eu/en/news/high-pressure-processing-food-safety-without-compromising-quality), [USDA pulse-field research](https://www.ars.usda.gov/research/publications/publication/?seqNo115=369869) and [FAO enzyme-assisted juice processing](https://www.fao.org/4/v5030e/V5030E0o.htm) support the industrial-service subjects. Benefits remain product- and process-dependent.

## Acceptance and integration

`python3 tools/technology-review/check_master_catalog.py` passes: 23 new unique IDs and normalized names, all parents resolved, no unreachable drafts, and all 23 horizon mappings have matching scope digests. `git diff --check` passes. No gameplay tests or player launch were performed for an authored-only document change.

The isolated base accounts for 673 implemented definitions plus 2,442 drafts = 3,115 identities, leaving 1,885 to author. The separately delivered rail batch `412d360` adds another 24: once both deliveries are integrated, the unique authored total should be 3,139 and the remaining authoring work 1,861. These are authored totals, not live-discovery totals. Preserve newer implementation promotions and regenerate coverage rather than copying this branch's derived report over canonical state.

D01 has 184 identities against its allocated 280 in this branch. The batch contributes two H01, five H02, six H03, three H04 and seven H05 assignments. No candidate-atlas completion is claimed. Integrate the new JSON, this review and the 23 horizon additions, preserving rail and any later mappings. There are no simulation or save-format changes; remaining runtime, full-history balance and imagery work stays open.
