# Machine-tool manufacture and retained workshop tooling

Twenty-four distinct discoveries and recipes establish a physical path from reference surfaces and screw feeds to complete basic and precision machine-tool sets. Newly installed motor-driven workshops require a basic set. Electronically controlled, sequenced and programmable workshops require a precision set. Motor manufacture itself requires a basic set as paid setup tooling. The basic machines can be constructed without electricity, avoiding an electric-motor bootstrap cycle.

| Practice | Physical output |
|---|---|
| Three-Plate Lapping | Surface Plates |
| Straightedge Scraping | Machinist Straightedges |
| Machine-Way Scraping | Scraped Machine Ways |
| Lead-Screw Cutting | Machine Lead Screws |
| Split Feed Nuts | Machine Feed Nuts |
| Cross-Slide Assembly | Machine Cross Slides |
| Four-Jaw Chucks | Workholding Chucks |
| Tailstock Fitting | Lathe Tailstocks |
| Tool-Bit Heat Treatment | Steel Tool Bits |
| Centre-Lathe Assembly | Metalworking Lathes |
| Drill-Bit Fluting | Drill Bits |
| Quill Feed Mechanisms | Drill Quills |
| Column Drilling Machines | Column Drills |
| Milling Cutter Relief | Milling Cutters |
| Milling Table Feeds | Milling Tables |
| Milling Spindle Heads | Milling Spindle Heads |
| Horizontal Milling Machines | Horizontal Mills |
| Worm Dividing Heads | Dividing Heads |
| Drill Jig Bushings | Drill Jig Bushings |
| Drill Jig Layout | Drill Jigs |
| Gauge-Block Lapping | Gauge Blocks |
| Bench-Vise Screws | Machine Bench Vises |
| Basic Machine Shops | Basic Machine Tool Sets |
| Precision Toolrooms | Precision Machine Tool Sets |

Each discovery has causal prerequisites, no calendar unlock and a finite physical production contract. Surface references and screw feeds branch into workholding and guided motion; these reconverge in lathes, then drilling and milling equipment. Basic sets assemble a lathe, column drill and vise. Precision sets add a horizontal mill, dividing head, drill jig and gauge blocks. Existing materials, bearings, gears and optical-lens production supply upstream inputs. The existing licensed civilian-production route remains available when an actual contract covers the method.

## Operation and retained tools

Knowledge creates no machinery. Manufacturing consumes batch inputs and assigned workshop work. Establishing a production line assigns its setup tools out of warehouse stock. Motor manufacture now assigns a basic machine-tool set once per line, then consumes iron, wire and cable for each motor. A complete powered workshop additionally requires its normal motor, cables, installation labor, operating workforce and electricity. The four workshop service quantities and staffing rules are unchanged; this change gives their machinery a physical production chain.

Retooling now preserves paid setup tools in that same workshop. Only the positive difference between the new setup requirements and the tools already installed is charged. Tools remain assigned to that line: they are not returned to warehouse stock, duplicated across lines, or available as raw batch ingredients. Efficiencies still fall during retooling, and consumed unfinished work is not refunded. Closing a line still retires its assigned tools without a salvage refund under the existing closure model.

The recursive civilian planner accounts for retained tools on the same completed, unpaused line that the controller would reuse when capacity is full. It does not take tools from another active or paused workshop. This matters to the actual chain: the first constrained fixture repeatedly rebuilt reference plates and lathes when every retool discarded setup; retaining those tools allows the entire chain to finish with one line. This is a material-accounting correction, not an unlimited capacity grant.

## Validation

Seven focused machine-tool cases pass with zero errors, failures, skips or orphans. They cover all twenty-four manufacturing processes through a complete precision set and its later powered operation; basic tools and two motors manufactured without electricity; missing physical sets blocking all four workshop types without debits; unknown methods and missing reference tools; fractional production through JSON serialization; incremental retooling charges with raw inputs kept separate; and retained-tool save state, old-line fallback and invalid quantity rejection.

Nineteen existing persistent-production cases and eight civilian supply-planner cases pass after the retention change. Fourteen operating-plant cases and three microprogramming cases passed against the new workshop installation costs earlier in this batch; those unchanged subsystems were not rerun after the retention-only change. The microprogramming fixture now supplies its required precision machine-tool set explicitly. Total relevant cases: 51, across staged focused checks rather than a broad gameplay sweep.

The final graph and ideal-resource audit reports 532 discoveries, 212 recipes and 12 plants with no structural errors. The complete-chain fixture supplies upstream metals, bearings, gears, lenses, stone, clay, timber, water and fuel; it is not evidence that an ordinary society discovered and supplied this industry naturally. Workshop operation uses explicit upstream motor/controller and generation fixtures. No native player or canonical integration claim.

## Saves, integration and limits

An optional `installed_tooling` dictionary extends each persistent production job. It is serialized with the existing job ledger and checked for known tooling resources, finite positive quantities and bounds. Older jobs without that field retain only their current recorded paid setup; tools already lost through historical retooling are not reconstructed. Existing machinery installations stay installed, and older production materials and fractional work are preserved. There is no new top-level save authority or population system.

Shared integration conflicts: discovery_system.gd, civilian_industry.gd, technology_operations.gd, persistent_production.gd and civilian_production_planner.gd. The one-line fixture update in test_microprogramming.gd accompanies the changed installation cost. No canonical merge, player launch, save deletion or military command change.

The workshop model aggregates human mechanical effort and does not separately simulate treadles, line shafts, individual cutting speeds, tolerances, wear, thermal expansion or dimensional inspection results. Gauge blocks are physical reference equipment, not a claim of simulated metrological accuracy. The new machinery does not establish balanced industrial growth or the requested full-history horizon. Automatic investment in new powered machine shops remains outside this batch; the existing production planner can build the required tools for motor orders and physical installation costs are enforced for player orders.

## Primary references

The [Science Museum Group's Maudslay lathe](https://collection.sciencemuseumgroup.org.uk/objects/co46284/henry-maudslays-original-screw-cutting-lathe-c-1800) documents the relationship between a slide rest, screw feed and controlled cutting depth. The [Powerhouse's bench lathe](https://collection.powerhouse.com.au/object/385413) records a bed, mandrel, tailstock, slide rest and foot wheel, supporting manufacture before electric drive. [NIST's Gauge Block Handbook](https://www.nist.gov/publications/gage-block-handbook) describes dimensional reference blocks and their calibration. These inform the component distinctions; game quantities and work costs are authored balance values rather than historical measurements or manufacturing instructions.
