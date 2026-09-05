# Battle terrain, contact and persistent injuries

Base: af76241; worker area: C:/Users/sjpur/tt-battle-contact-landscape.

Campaign battles resolve their encounter position and sample the map ground authority when available. The bounded 320m mesh uses source heights/biome colors and actual river footprints clipped and draped onto the battle patch. Without a map authority the view labels its regional estimate. Trees and rocks are bounded habitat representatives, not exact copies of individual map objects. Camera picking follows the terrain.

Opposing melee/mobile representatives pair up with staggered existing attack clips, guard poses, approach, lunges, recoil and contact flashes. This is presentation only; it does not alter combat decisions or allocate a soldier object per person. Existing VAT assets are reused. No new rig export is claimed.

The header reconciles fighting, out-of-action, casualties, deaths, wounded, scattered and lasting injuries. Disability is a subset of wounded survivors. New disabling wounds stay out of ordinary recovery; home demobilization transfers them exactly once into two persistent civilian cohorts. Effective capacity varies by job, and drives food, extraction, logistics and construction. Headcount, rations and payroll remain distinct. The capacity coefficients are game calibration, not clinical estimates. Home veteran cohorts do not penalize unrelated satellite city production. Individual impairment types, civilian migration of these cohorts, and treatment/adaptation policy are not implemented.

Validation: 9 injury/geometry cases; 24 existing military training/development cases; actual save/load probe; GPU battle graphics probe (including cursor camera anchors, combat invariance, casualty idempotence and 192 representative cap); inspected GPU capture. Pre-existing shutdown resource leak warnings remain.

Unfinished Blender authoring experiment remains unstaged in the worker. Its source blend dependencies are absent. It is not required by the runtime and must not be claimed as delivered animation assets.
