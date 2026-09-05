# Century focus handoff

Worker: `C:/Users/sjpur/tt-century-focus`, `codex/century-focus`.
Base: `af76241693721265ff56803f54faaae81c393b9d`.

The player chooses one of eight focuses at founding and each 36,500-day boundary.
Highlighting a card is not a decision: confirmation is required. The same focus
can be renewed. No advisor selects a focus. Existing research modifiers and
gradual cultural changes remain; no supplies, wars or discoveries are granted.
Serving officials recommend using their roles, domestic needs and an allowlist
of confirmed foreign relations. Vacant offices produce no invented advisors.
Traditions retain their decisions and do not expire.

The simulation clamps to the century boundary and pauses. Excess wall-clock
frame time is discarded, not accumulated into unchosen simulation days.
Founding confirmation starts normal time through the existing opening callback;
later century confirmation leaves the game paused for explicit player resumption.

Save version 2 records the chosen century. Version 1 preserves its existing
ambition for the current century. Empty legacy choices prompt the player.
Histories remain bounded to 24 records; labor ownership is unchanged.

Validation in the worker: nine GdUnit cases passed, including boundary renewal,
100-century skip, JSON/v1 migration, invalid import, eight domains/axes, actual
officeholders, hidden-foreign-information isolation, role advice and growing
office roster. Existing people-direction runtime probe passed. Actual opening
probe passed, including the next-century pause and explicit renewal. GPU focus
and advice captures inspected at 1440x900. Existing shutdown resource warnings
remain; no paid API calls. Smaller-window exhaustive layout testing is not claimed.

Shared hunk: `local_terrain.gd::_process`, century pause gate and elapsed-day cap.
No injury, casualty, workforce, economy or outpost changes are included.
Integrator must test combined main before announcing shipment. Preserve live
player session; script/state changes may require a saved-session restart to take
effect. Worker has not merged or launched the canonical game.
