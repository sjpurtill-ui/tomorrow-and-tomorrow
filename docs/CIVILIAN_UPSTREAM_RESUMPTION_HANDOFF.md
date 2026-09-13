# Continuous civilian input supply

Worktree `/Users/seanpurtill/.codex/worktrees/ef8f/tomorrow-and-tomorrow`, branch `codex/civilian-upstream-resumption`, base `ba458bdedaa9db396176f4128bb5f4b4f5e46b44`. Scope: civilian supply planning, controller line ownership and persistent-line validation. No discoveries or recipes are added.

Reproduced problem: a single automatic workshop makes prepared fiber and then yarn. Once clothing consumes yarn, its persistent yarn target becomes unmet while prepared fiber is exhausted. The planner requests retting, but the only workshop can be reused only after its yarn target is met. Production stalls despite supplied raw fiber, water, tools and workers.

The controller now records which civilian lines it manages. An idle, input-blocked automatic line may produce an actual upstream input in its dependency chain. The existing paid retool operation retains installed tools and charges missing tools; the next ordinary demand decision resumes downstream production. No extra workshop, materials, work or instant output is created. Existing completed-target reuse remains unchanged.

Paused lines, work in progress, reserved materials, military lines and user-controlled unfinished lines are not reused. Manual target/pause or retool operations clear automatic management; controller updates preserve ownership only for lines already controlled by that controller. Unrelated production demand cannot take an unfinished target's slot.

The optional boolean `planner_managed` persists in the existing production-line record and is validated. Old records without it remain valid and are not presumed automatic. This conservative default means an old unmarked blocked line may still need user intervention or another workshop. Partial-work shortages are not solved by discarding paid work.

The causal regression runs three repeated raw-fiber → prepared-fiber → yarn → garment cycles using one workshop. Additional checks cover manual control, pauses, work in progress, reservations, unrelated inputs, saved management state, retained tooling costs and malformed flags. All 65 cases across four suites pass: civilian planner13, persistent production19, water operations14 and owned simulation19. Evidence: `/tmp/tt-upstream-results.json`; the initial failing reproduction is `/tmp/tt-upstream-reproduction.log`. No player/editor launch, package update or historical-pacing claim is included.

Canonical runtime `cd6accf0cd2dc24b51842bfc3280530ec8c2b52f` passes all 32 planner and persistent-production cases (`/tmp/tt-upstream-canonical-results.json`).
