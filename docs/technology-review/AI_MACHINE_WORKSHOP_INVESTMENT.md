# Civilian machine-workshop investment

The civilian controller can now commission mechanical assistance for sustained production. Previously, all five workshop installations could be ordered by the player, but the controller had no investment policy for them.

The planner considers programmable, hardwired-sequenced, electronically controlled, motor-driven and pneumatic workshops using their existing discovery gates and physical recipes. It requires at least 30 estimated days of materially supplied persistent work. Paused, completed, unavailable and unfed jobs do not contribute. A copied stock ledger prevents counting the same material twice across candidate jobs; outstanding fractional work and current efficiency are included. This is a present-stock horizon, not an invented promise of future imports or output.

Investment requires local adoption, spare Crafting staff, and positive net mechanical assistance after subtracting operators. The existing 50-percent assistance cap limits expansion. Existing enabled construction is completed before another investment. Disabled installations remain disabled. The controller retains its hunger and war guards, and the planner only acts at the primary settled home.

All equipment is paid through ordinary production or installation orders. Missing manufactured components are requested recursively only when their prerequisites and inputs are feasible. Pneumatic equipment needs a month of compressed-air inputs. Electric installations require available generation; otherwise the existing power planner proposes paid generation first. No power, equipment, knowledge, workers, production slots or discoveries are granted. A full workshop queue does not evict an active line to manufacture investment inputs.

## Evidence and limits

Six new cases pass, covering paid controller installation and commissioning, improved real production rate, all five workshop families, adoption, paused and nearly finished work, material shortages, operator costs, assistance saturation, disabled installations, motor supply requests, full-queue preservation, generation-first sequencing and emergency guards. Twelve existing power-investment cases also pass. Both suites report zero errors, failures, skips and orphans. Logs: `/tmp/tt-machine-investment.log` and `/tmp/tt-machine-investment-power.log`.

The fixtures supply explicit technologies, raw inputs and generation where stated. These tests demonstrate the implemented decision and execution path, not historical emergence or campaign-scale industrial balance. The 30-day horizon is a policy constant, not a calibrated return-on-investment model. Existing aggregate machinery dispatch, wear limitations and primary-settlement scope are unchanged. Blocked active production slots must become available through the ordinary production system; the planner does not add capacity or forcibly cancel work. Cold-store investment remains separate outstanding work.

## Integration

Worktree: `/Users/seanpurtill/Documents/Codex/tt-technology-implementation`; branch `codex/technology-implementation`; original base `940d5a2ad848d9f45b8d98825cd5219a3eda83e9`; preceding commit `632ca15`.

New files: `scripts/machine_workshop_investment.gd` and its focused test. Shared integration file: `scripts/civilization_controller.gd`, with one call after scientific and canning investment. No simulation authority, save field, discovery identity or artwork changes. Existing installations and production jobs remain valid. No canonical merge or player launch was performed.
