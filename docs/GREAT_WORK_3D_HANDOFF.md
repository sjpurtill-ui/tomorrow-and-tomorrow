# Great Works: construction and dedication

Base: synchronized canonical and origin/main
`9984106042088ef8f499128d5dfa740602f8116a`.
Integrator workspace:
`C:/Users/sjpur/.codex/worktrees/settlement-growth-integration/TomorrowandTomorrow`.
Branch: `codex/great-works-experience`.

## Experience

The Great Works dock opens the selected work in an interactive 3D inspection
view. The model reads its existing form, material, ambition and actual completed
fraction. Rotation, zoom, construction scaffolds and a clearly marked planned
outline help the player understand what has been built and what remains.
Small list thumbnails remain inexpensive 2D artwork.

Inspection pauses the world. The explicit Watch time pass action releases this
screen's pause and lets the normal game clock continue. It starts normal speed
if the player had paused before opening the screen, and restores that pause
when inspection resumes or the screen closes. Another modal's pause cannot be
released by this control. The familiar five game speeds remain available while
watching. A half-second check reads the live work record;
unchanged geometry and camera pose are retained. New decisions, accidents or
completion refresh the available actions. No view advances construction itself.
When a dedication becomes ready, live watching pauses at that real completion
so the invitation does not race past while the player uses the fastest clock.

The finished work's pending dedication opens the existing ceremony through the
Audience Director. The ceremony uses a 3D forecourt, the completed work and the
court's figure/acting systems, with a bounded cast drawn from recorded people
and attendees. Its ritual and props follow the supported era. Naming and
dedication still use GreatWorks.dedicate, the sole owner of gifts, chronicle
events and effects. Merely watching or postponing a ceremony changes none of
those quantities.

## Ownership

- Integrator: `scripts/hud/great_works_atlas.gd`,
  `scripts/hud/content/dock_content_undertakings.gd`, inspection regression
  tests and integration records. A narrow fix in `great_work_plate.gd` keeps
  ruined list thumbnails triangulable after their uneven break is drawn.
  `simulation_pause.gd` gains a resume-speed adjustment for the case where a
  second modal pauses a temporarily running inspection; it never unpauses
  another active owner. Initial integrated source: `15e95fed`.
  The final combined run also exposed the court's existing deferred fade
  receiving a freed card on immediate close. `audience_modal.gd` now queues
  an instance helper and verifies the card before fading; the existing
  diplomatic journey test drains that close frame. Source `8a2e2d29`.
- Model worker: new `scripts/hud/great_work_model.gd`,
  `scripts/hud/great_work_view.gd` and their tests. Initial worker source
  `2284ad86`, integrated as `d5dd98af`; framing/material follow-up
  `e1a6652d`, integrated as `5ab2554e`; Compatibility-calibrated colors and
  cached soil `ec691b17`, integrated as `72ea607b`.
- Ceremony worker: `scripts/hud/great_work_ceremony.gd`, new ceremony stage
  helper and tests. Initial worker source `580067c0`, integrated as `f1d1cb31`;
  live layout follow-up `d26130cb`, integrated as `00d1ce3e`; elevated framing
  `434a08f5`, integrated as `80c4b1c7`; neutral lighting `5fd87a55`, integrated
  as `d828d831`.
- Acceptance worker: isolated `tests/great_work_3d_acceptance.gd/.tscn` and
  `docs/GREAT_WORK_3D_ACCEPTANCE.md`; initial worker source `43952ad2`,
  integrated as `75a91a55`; real crew/control follow-up `dd2760c7`, integrated
  as `0228dcbd`; final pixel/visual acceptance `496c8d7d`, integrated as
  `374af544`. Atlas layout and completion pause source: `928d999f`.

There are no changes to construction costs, progression rates, completion
odds, outcomes, aggregate population, labor ownership or save schema. The
existing supported Great Work grammar extends through modern tier 5; a year
3000 ceremony does not invent a new construction capability or asset catalog.
The model uses the current 18-form procedural library, not a new catalog of
ornate monuments for every era. Early offerings, later unveilings, ribbons and
capability-gated electric lighting are ceremonial presentation, not invented
resource consumption or ledger rewards.

Models rebuild on changed construction courses (forty bounded steps), status
or material/form; numeric progress updates separately. Inspector viewports are
capped at 1280 x 720 and render once after a change, camera interaction or
resize. The ceremony retains its monument and at most six recorded cast
members, renders during brief acting/camera/ritual sequences, and stops when
idle or hidden. These are bounded presentation contracts, not an FPS guarantee.

## Validation and delivery

Final combined headless regression through runtime `72ea607b`: 69/69 across
inspection, model, view, map geometry, Great Works mechanics, ceremony stage,
diplomatic journey and calendar date suites; report 21, exit 0, clean engine
log, no reported failures, skips or orphans. Evidence:
`artifacts/great-work-delivery-tests.log`. The previous
inspection test caught default ProgressBar quantization, which is corrected.
The eight inspection cases include nested pauses acquired both before and
during live watching, camera retention across stalling, real completion actions
and triangulation of all 18 ruined silhouette forms across seven variants.
Report 19 emitted that deferred court-fade engine diagnostic despite its
passing assertions. The scoped repair then passed 5/5 diplomatic journey
cases with a clean engine log, report 20 and confirmed exit 0.

Final private GPU acceptance passes 252/252 checks across twelve cases and
eighteen captures, with a clean engine log and confirmed process exit 0.
Final evidence is `artifacts/great-work-accepted-gpu/capture.json`, its PNGs,
and `artifacts/great-work-accepted-gpu.log` in the acceptance worktree.
Eight actual pixel checks prove the inspector image stays frozen after an
unrequested scene change, then updates on camera input. Merely reading the
SubViewport's cached requested update mode cannot prove renderer inactivity.
Real crews, material shortages, collapse, daily completion, camera retention,
four supported rituals, actual cast bodies, gifts, naming, pause restoration,
compact controls and dark/light themes are covered.

The first combined capture exposed late-growing ceremony controls. Final
image review also led to elevated full-monument framing and a measured
Compatibility lighting correction. Captures are isolated prepared-record
specimens, never the current player game or a continuous campaign certification.
Reproduction and exact source coverage are in `GREAT_WORK_3D_ACCEPTANCE.md`.

The concurrent Research pace wording change `22e31df1` was merged from both
origin/main and canonical main without conflicts. No Research files are owned
or rewritten by this task. The later calendar wording main `8bd11fdd` is
also merged without conflicts; its date changes remain intact.

The canonical checkout's 4700 existing modified/untracked files have a separate
SHA256 inventory. Delivery checks incoming paths, pushes and freshly verifies
origin/main before the canonical fast-forward, then verifies those existing
bytes. Generated imports, UIDs, captures, reports and isolated userdata remain
local and excluded. The user's game and editor are never stopped or restarted.
