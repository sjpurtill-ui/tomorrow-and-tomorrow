# Defended borders and fighting worms

October 10, 2026. Worker delivery on `codex/border-art-direction`, based on
integrated main `16982712`; combined with the border art direction in PR #205.
The canonical player checkout has not been changed by this delivery.

## What the player gets

The ruler gives the general a defensive or offensive objective. On defense,
the council detaches real soldiers from the existing army into at most eight
border bands, retains the home reserve, and marches them to surveyed land
stations on the fort-defined border. A station holds nothing until its army
arrives. Its held length depends on actual soldiers, readiness, food and
military organization. Small forces leave gaps; sufficient developed armies
can cover the complete land perimeter. Fort watchmen are not duplicated into
these bands. Repeated councils preserve surviving stations and the reserve,
and send real replacements to vacant stations.

The general reports soldiers deployed, kilometres held against kilometres
assigned, and people retained at home. Drill, military staffs and radio
increase sustainable frontage through discoveries, rather than a calendar gate.

Ordinary marches and command-zone movement sweep the actual route against
hostile armies and held sectors. A stronger army also has to fight. The first
contact halts that day's march and opens the existing battle at the crossing.
An overwhelming attack can win immediately, but still resolves real combat
and casualties. An army's capital objective and road survive a breakthrough;
the same survivors can meet a second line inland. The capital still requires
its existing battle, siege and occupation conditions. Defeat opens the sector
and triggers regrouping; an inconclusive fight does not invent a breach.

When scouts have reported a held line, the general can choose a bounded land
detour around its reported flank. Reports older than 30 days and unseen live
enemy positions do not inform that choice. A reported gap is an approach to
investigate, not a guarantee that the enemy has stayed still.

The map draws flowing blue and red ribbons from held coverage, with distinct
ends at gaps. Political boundaries remain quiet context. Actual battles heat
the contact and the existing mobile fronts follow fighting inland. Own runner
reports and dated enemy observations retain their uncertainty. Enemy lines
are clipped to visible ground; separate glimpses cannot become a continuous
invented front. Witnessed defeat clears that particular remembered ribbon.
Battle and army cards measure their numbers and avoid one another.

## Ownership and compatibility

`border_defense.gd` is bounded geometry and deployment arithmetic, without a
second army ledger. `army_front_contact.gd` joins it to military movement and
the existing battle reservation/casualty pipeline. Rival contact views refresh
from the actual owning army; an obsolete retreat report cannot overrule a
recovered defender. Combat uses the same rules for the player and other actors.

Optional sector metadata is stored inside existing army dictionaries. Report
geometry uses serializable x/z points; old saves without it remain valid.
No save version change, player-session restart, population expansion or new
individual-soldier simulation is introduced. Rendering stays bounded and
respects pause and reduced motion.

## Validation

- Combined headless run: 115 cases passed, zero errors, failures or orphans.
  This covers campaign contact, complete peak perimeter deployment, reserve
  conservation, save/load during combat, successive defenses, real owned
  casualty commitment, command hierarchy and the existing worm presentation.
- The second combined run passes 23 of 24 cases, with zero errors or orphans.
  Three outcome/intelligence regressions pass: inconclusive fronts remain,
  witnessed breaches clear, recovered real defenders override old reports.
- Two observed-approach cases pass: recent evidence changes the route while
  stale or missing evidence leaves it unchanged.
- The council defense regression now tests physical deployment. Its unrelated
  long-run raid cadence assertion also fails on unchanged `16982712` (two
  bands where it expects at least three); it is preserved, not weakened.
- Private GPU fixtures show held ground, thinly staffed gaps, two contact phases,
  inland fighting and regional overview on copied campaign terrain. These are
  labelled staged observations, not a claimed natural campaign replay.

Evidence is local under `artifacts/border-defense-*.log` and the capture
worktree's `artifacts/border-defense/terrain-ready/` (six captures, all checks
passed; private process 23316 exited normally). The probe is
`tests/border_defense_capture.tscn`, launched only through
`tools/run_isolated_gpu_probe.ps1` with a copied save in ignored artifacts.
It verifies that the copied source and frozen campaign day remain unchanged.
