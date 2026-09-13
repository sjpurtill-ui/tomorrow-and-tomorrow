# Machine energy save correction — READY for sequential integration

Base: `d20aeee43121d3cfa70086ea623fb4af94137cd6` (frozen manufacturing delivery).
Worktree: `/Users/seanpurtill/Documents/Codex/tt-machine-energy-correction`.
Branch: `codex/machine-energy-correction`.

The existing coordinate validator permits any finite monotonic energy history.
The workshop adapter now additionally requires the retained total and every
trace frame to equal work multiplied by the recipe's power/days rate, within
the existing 0.000001 numerical tolerance. This prevents malformed saves from
claiming completed motion with unpaid energy or altered process evidence.
Actual production and electricity debits are unchanged.

Owned changes: `scripts/machine_workshop.gd`,
`tests/test_machine_process_parts.gd`, and this handoff. No shared authority,
catalog, imagery, player launch, or canonical checkout changes.

Validation: explicit-worktree headless gdUnit command:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/seanpurtill/Documents/Codex/tt-machine-energy-correction -s addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode -a tests/test_machine_process_parts.gd
```

Result: **12/12 tests, zero errors/failures/skips/orphans**, 5.972 seconds;
`/tmp/tt-machine-energy-tests-final.log`. New tests reject zero total energy
at partial motion and zero frame energy with a correct total, through both
the adapter and production save validator. A real SaveSystem save/load at
1.25 machining work resumes through machining and inspection, preserves
reserved feed, debits precisely the remaining 5.5 electricity, and produces
one accepted plate. Existing eight-process and partial-inspection coverage
also passes. Initial test assertion used an integer expected value for a
float; corrected to 1.0. First fresh import crashed during font import;
the retry completed successfully before testing.

Compatibility: ordinary older jobs have no machine state and remain valid.
Legitimate states produced by the frozen implementation satisfy this invariant;
inconsistent manually altered states are rejected. No schema change.
Limitation: validates the internal recipe/work/energy relationship, not an
independent historical stock ledger. This correction adds no discoveries and
does not establish full-history completion or progression viability.

Apply after the frozen manufacturing delivery. Possible conflict only if the
integrator separately edited this adapter or test suite; do not overwrite
other branches. The original manufacturing worktree remains frozen.
