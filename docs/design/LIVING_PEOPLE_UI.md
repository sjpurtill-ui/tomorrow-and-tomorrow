# Living People controls — integration foundation

This checkpoint is the functional UI foundation, not final visual acceptance of
illustrated civilization art. The first actual scene review rejected the distant
camera and repetitive scenery. The scene owner is refining that separately.

The actual Home → People provider now renders CivilizationPeopleScreen over the
private PeopleSettlementView. All nine existing work roles have an on-scene
count and Assign action. Selecting one focuses the existing renderer camera.
The scene depicts the primary town; the caption explicitly identifies allocation
counts as realm-wide. Other assignment entry points call focus_work(role).

Each interaction edits one detached WorkforcePreview draft. The focused area
shows requested heads and donor transfers, current/proposed food production,
exact demand and daily store change, and existing 30/90-day food forecasts.
Research compares effort at current supplies and actual team count. Active home
building shows the actual batch capacity and estimated remaining days. Water
shows estimated demand coverage only when measured inputs exist. Other roles
show effective crew changes and the existing TaskImpact purpose; material yields
are not invented from headcount alone.

Apply validates the current captured state and requires an explicit takeover
button when leaders currently assign labor. A stale Apply refreshes/replays the
intentions and returns for another explicit Apply. A valid commit calls the
original Manual.set_manual/move_share functions, then requests one HUD refresh.
No-op, invalid, unconfirmed and stale drafts do not change live assignments.
Pause to plan uses the existing HUD speed command only when clicked; leaving
this view never resumes or pauses time automatically.

Normal live refresh keeps the scene, camera and draft. Dock navigation memory
stores only role, commands and token, never the detached simulation snapshot.
Restoring a draft recaptures current inputs and visibly flags a changed preview.
Escape first returns to overview; a further Escape discards unapplied changes.
Named people/Summon, city actions, vitals and records remain available below the
scene using the existing People renderer's callbacks.

Validation: five isolated UI interaction cases, three actual provider commit
cases, six overview cases and six live-dock persistence cases passed in focused
runs. Actual private GPU process 13448 exited 0 with nine captures across 2869,
1600 and 1024 widths, no allocation mutation during previews, and scene/panel
bounds checks. Artifacts stay local under artifacts/people-living-b. Additional
safeguard/shortage visual proofs and the renderer's art revision remain pending.
No save schema or simulation formula changed.

Follow-up validation: eight isolated UI cases now cover stable scene height while
scrolling, unchanged stale-preview refresh without takeover, and the original
whole-percent bounds for fractional starting shares. An unchanged zoom shows
single current readings; comparisons appear only after a draft change. Detailed
shortage warnings remain in tooltips with concise on-scene risk statements.
Extraction and Crafting explicitly state why numerical output is not forecast.

The real shortage fixture uses empty stores and food grounds at the engine's
0.12 health floor, then requests fewer food workers. The existing safeguard
redirects workers toward food, yet the actual representative-day calculation
still reports a current shortage. Private GPU processes 64128 and 53472 both
exited 0 across 1024, 1600 and 2869 widths; the latter also checked all nine
marker bounds and overlap. The combined closer-camera process 54032 exited 0
with nine normal-state captures and the same containment/no-mutation checks.
The final combined risk process 13644 exited 0 with twelve captures, including
unchanged readings before making a request, through the same isolated actual
HUD/provider/preview path. All marker overlap, containment and preview
no-mutation checks passed. A foreground tree can obscure the selected food
area in this fixture; that camera/scene sightline finding is owned by the
renderer and is separate from this UI checkpoint.
