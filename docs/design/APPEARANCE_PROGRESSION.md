# Appearance follows progression

Status: READY on `codex/appearance-progression`, based on
`1df2277270556b175377fbe6933dbccbc25ec8b5`. Not integrated into the player checkout.
Worktree: `C:/Users/sjpur/.codex/worktrees/food-folio/TomorrowandTomorrow`.

## Audit and behavior

The previous city selector combined capacity and knowledge with settlement-age
ceilings (including 700 years for industrial and 1,500 for metropolitan forms).
The previous court selector advanced in 200-year chapters and capped the room by
construction knowledge or a civic stage. It could also mirror a room solely
because another 200 years elapsed. Clothing and equipment already used discoveries.

City form eligibility now uses adopted building practices (at least 20% adoption),
existing crews, completed works, districts and operating capabilities. Paid city
construction still controls achieved development; new research does not instantly
replace inherited buildings. The Buildings page names missing adopted practices.

| City milestone | Relevant adopted practices (alternatives within each group) |
| --- | --- |
| Hamlet | framing, post-and-beam connections, or central hall houses |
| Village | adobe, mould-made mudbrick, dry-stone walls, or post-and-beam connections |
| Local centre | graded roads, stone-lined drains, or urban street plans |
| Town | shared party walls, standard lots, or urban street plans |
| Mature town | stone-lined drains, street gratings, or coordinated building drainage |
| Urban system | dressed stone, fired bricks, or ashlar masonry |
| City consolidation | urban street plans or standard lots |
| Historic landscape | merchant houses, jettied timber houses, or stone party walls |
| Regional system | brick sewers or street utility ducts |
| Industrial | structural steel AND steam power or central power stations |
| Metropolitan | reinforced concrete AND safety lifts |

Markets, guest houses, civic plots and extraction industry no longer wait for
10/15/25/40 years of settlement age. Existing staffing demand, material recipes,
known material techniques, site checks and construction constraints govern them.
New connected quarters retain their annual evaluation cadence and real population,
logistics, route knowledge, builders and material requirements, without a four-year
minimum settlement age. Time still measures construction work, weathering, damage,
seasons and recorded history; those are not style unlocks.

Courts choose the highest applicable authored room from the host's actual known
construction or civic practices. Timber halls, masonry, columns and vaults unlock
the corresponding early structures; chancery, secretariat, cabinet and ministry
practices unlock their office layouts. Concrete/steel and precast construction
unlock the final conference rooms. Political lean and discovered equipment remain
independent. A civic-stage label alone cannot grant construction knowledge.
All sixteen mappings are in `scripts/hud/court_chapters.gd::CONSTRUCTION`.

## Validation

107 distinct checks pass across six suites: settlement model (48), construction
page (14), city visual geometry (8), court chapters (18), all sixteen court model
sets (9), and court presentation (10). Reports 29, 28 and the presentation suite
in report 26 respectively. Earlier fixture expectations tied to dates were updated;
the final court and city reruns have no failures, errors, skips or orphans.

Checks cover unchanged knowledge across widely different dates, adoption thresholds,
all live discovery IDs, every city form at day zero with prepared capabilities,
foreign hosts' independent knowledge, equipment gates, circulation and inherited
plots. A private GPU probe rendered court milestones 1, 8 and 15 at the same day
zero with different knowledge snapshots: PASS 3, PID 58472 exited 0. Captures are
local under `reports/court_chapters/*-year-0000-room.png`; no player session was
launched or restarted. The low-quality compatibility renderer reports its existing
unsupported depth-of-field warning. This validates selection, not a visual redesign.

Default court and city form matrix probes now use same-date capability specimens.
Optional dated reference fixtures remain prepared catalog snapshots, not claims
about the pace or outcome of a simulated campaign. The full settlement growth GPU
matrix was updated but not rerun in this batch; city geometry was checked headless.

## Compatibility and integration

No save-schema change. Saved buildings retain their recorded form and condition;
future construction uses the new rules. Courts recalculate from knowledge when
opened, so an existing campaign may show a different room immediately after loading
this change. Research discovery pacing itself is outside this appearance fix.

Only task files are included. Generated imports, UIDs, logs and captures remain
local. Shared integration surfaces are `settlement_model.gd`, court chapter policy,
architecture knowledge and the Buildings provider. Top-bar brightness and removal
of settlement figures remain separate preview branches. Integrate only after the
user's requested preview review; a pushed task branch is not the player build.
