# Home popup review

Modern Strategy presentation pass. No simulation, appointment, work-allocation,
population, care, discovery or save calculations change.

## Overview structure revision — 14 October 2026

The user rejected the earlier spacious composition. The active renderer is
`overview_folio.gd`; changes to its inherited legacy page alone do not change
Home. The current Overview replaces its equal-row grid with independent People,
Defense, and Homes and works stacks. Homes, Mood, and Growth live together with
their exact supporting readings. Labels and values stay adjacent, and the leader's
conversation action sits beside the identity. Places are local summaries with
Rename and Visit next to the corresponding place, rather than full-width table
columns. No essential readings or commands are removed or hidden.

Three columns become two independent stacks and then one column as the available
viewport narrows. The layout reads available viewport width as well as its own
width, so a previous wide minimum cannot prevent it shrinking. Place refresh uses
a virtual presentation hook; the source rows, callbacks, and refresh shape remain
unchanged. A focused regression proves live values stay with their source rows and
the focused leader action survives a refresh.

Designer A critiqued the first native wide captures, requested consistent
label-first reading order, and accepted the revision at 2869, 1600 and 1024 px.
Later-town Daylight captures, including larger army counts and waterworks, were
also rechecked. The private Home probe now includes those three widths, actual
viewport bounds, a late-town option, and a repeated wide/narrow Overview cycle.
29 focused Home/action/live-refresh/persistence tests pass with no failures,
errors, or orphans. The full Night probe covers all four Home tabs and nested
records; the forthcoming remaining-tab composition pass is tracked separately.

## Decisions and navigation

- Overview starts with the leader, conversation command and work choices. Homes
  and Mood sit nearby; Growth and Army retain their original actions and exact
  readings within People and Strength. Supporting facts retain source tooltips.
- People keeps the representative portraits and job pictographs. Person records
  stay inline; larger narrative text and portrait proportions preserve context.
  Manual work controls retain all existing callbacks and quantities.
- Culture keeps the course review and collection opener. A sole course's exact
  memory share is quiet text; multiple memories retain their segmented chart.
- Council remains a distinct task for calling office holders. One roster replaces
  duplicated column headings and provides explicit Summon commands.
- Health leads with the situation and available care choices. Historical and
  numerical evidence follows. Sickness & disasters remains a separate growing
  record; its empty state is short and its explanation opens inline.
- Births and deaths keeps Overview and Every death because summary and chronological
  lookup are different tasks. The log omits duplicated overview readings.
- Capacity detail leads with its meaning and current drivers before history.
- Leadership removes its redundant single tab. Responsibility and population
  context lead, followed by candidates grouped with their original appointments.

## Critique loop

Designer A reviewed actual narrow People, person, Culture and Council captures.
Revisions enlarged supporting text, widened the selected portrait, separated
metadata and quieted the single-course stripe. A then requested task-first
Overview composition and narrative-first Health, plus direct record views.
Those revisions were rendered and accepted in Night. Daylight is checked too.

## Shared presentation changes

With integrator authorization, home_ledger buttons and dense_blocks verbs use
the shared 40 px secondary style. DockBlocks uses 14 px supporting text, 16 px
body and row names, wrapping driver labels and section notes below headings.
Signatures, callbacks, availability and data meanings remain unchanged.

## Validation

- 50 existing tests pass across Home docks, own-town page, Culture, capacity
  history, population read stability and dense blocks; zero errors/failures/orphans.
- Existing assertions were updated for intentional presentation ordering and
  the new 40 px controls. Numerical and action assertions remain intact; Home's
  four reading destinations are exercised on the actual inline controls.
- Private GPU probe captures 1600×1000 and 1024×720 in Night and Daylight,
  including all four Home tabs, selected person, manual work, Health, hardships,
  births/deaths, capacity and leadership. Filled record fixtures cover pagination;
  an available-care fixture invokes the original half-share callback and checks it.
- Probes use isolated Test user data, Dummy audio and a private desktop, exit
  afterward, and never launch the player game or read/write its save.

Capture source: tests/home_redesign_probe.gd. Images and logs remain in artifacts.
The old paper texture is removed by the already integrated shared foundation.
