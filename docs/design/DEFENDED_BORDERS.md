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
and send real replacements to vacant stations. Growing armies reinforce occupied
stations through actual marching transfers. Moving the border remarches the
bands; retasking a band releases its old station. An army already fighting
cannot also defend a second battle or leave a duplicate occupied station.

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
Battle and army cards measure their numbers and avoid one another. A departing
attacker receives a compact fighting ribbon at its actual battle, without
claiming held territory. Battle readouts move away from the contact so the
opposing worms remain visible. Pause and reduced motion hold the animation still.

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

## Three refinement passes

The first implementation received separate engine and art critiques. Pass two
fixed reinforcement of occupied posts, remarching after border changes, stale
assignments after new orders, neutral commanded invasions, and preservation of
the original target after an intervening battle. It also moved battle readouts
off the fighting, corrected cluster counts, and made unavailable border-watch
actions truthful.

A second critic review found duplicate defender reservations, recalled posts
reappearing over their replacements, and homeward bands ignoring new duties.
Pass three fixes these lifecycle cases, separates crowded army counters, keeps
battle captions close to their cards, and refreshes border-watch ink even while
the pointer is away. A real combat exchange exposed the missing attacking
ribbon; both sides now have current, bounded fighting geometry.
The combined crowded-battle test then exposed redundant placement work for
tiny combat ribbons. Coalescing their footprint and skipping candidates whose
distance already exceeds the best placement reduced drawing from 86.6 ms to
16.8 ms, without relaxing the 60 ms test budget or counter separation.

## Validation

- Final combined core run: 127 cases, 126 passed, zero errors or orphans.
  This covers actual council deployment and arrival, 32 spatial crossings,
  delivered reports through normal collection/composition, reserve conservation,
  save/load, successive defenses, real owned casualty commitment, target
  preservation, command hierarchy, and the critic's deployment lifecycle cases.
- The engine critic's final acceptance passes all 14 focused cases, including
  reinforcement, remarching, recalling reserved posts, new map/city duties,
  neutral contact and duplicate defender reservations.
- Final combined visual run: all 95 cases passed, zero errors or orphans.
  It covers front geometry, current battle collection, moving fighting fronts,
  counter and battle layout, captions, click targets, and the bounded combat
  helper. The 50-band/20-battle case composes in 6.0 ms and draws in 16.8 ms
  on this machine; this is a focused draw measurement, not whole-game FPS.
- The council defense regression now tests physical deployment. Its unrelated
  long-run raid cadence assertion also fails on unchanged `16982712` (two
  bands where it expects at least three); it is preserved, not weakened.
- The border UI probe passes 71 checks across 14 captures, including actual
  staffing availability and a draw refresh with the pointer away from the map.
- Private GPU fixtures use copied campaign terrain and authored real armies.
  The production collection probe runs the council, marches, delivers reports,
  collects observations and starts real battles. These are labelled TEST
  fixtures, not a claimed natural campaign replay.

Headless evidence is local in `artifacts/border-critic-final-core.log` and
`artifacts/border-critic-final-visual.log`; border UI
evidence is in `artifacts/border-art/critic-r2/`. Production collection uses
`tests/border_defense_collection_probe.tscn`, launched only through
`tools/run_isolated_gpu_probe.ps1` with a copied save in ignored artifacts.
It verifies that the copied source and frozen campaign day remain unchanged.
