# Court executions: handoff to Astra

Date: 2026-10-03. From: the Claude orchestrator session and its builders (J figures, K acting, L stage integration, M set/props/animals/blood, N sound).

## 1. What the user asked for

> "I want the execution graphics to be hilariously gory in the court section. Come up with the animations for 25 different horrific acts you can think up."

- Executions are cartoon-gory comic set pieces in the 3D court: Monty Python and slapstick, bright red, over the top.
- The whole room reacts with good comic timing.
- This overrides the court's earlier rule that executions stay sober. Exile and being led away still stay sober.

## 2. Hard rules (game pillars)

- **The engine decides who dies.** An execution plays only after the engine has put the person to death: court orders, divine wrath that kills, envoy acts, or the captured-agent fates now on main (#133).
  - The stage never kills anyone the ledger didn't. See `docs/ADJUDICATION.md`.
- **The method.**
  - If the god's own typed words name a method ("behead him", "throw her to the pigs"), use it, provided the people can do it in their era.
  - Otherwise pick an era-available method, seeded by person and day, and never the same one twice in a row.
  - The narrator caption names the method, so the words match the picture.
  - The method has no mechanical effect unless the engine models one.
- **Era-gated.** A method appears only when the people know what it needs (bows, bronze, oxen, herds, pigs, pottery, siege engines, gunpowder...). No anachronisms.
- **Adults only.** Gore is never shown on a child; a child's execution cuts to the old sober exit.
- **No sexual content.** No real people or places (alternative-history naming).
- **Gore setting:** Full (the default), Mild (a cutaway at the blow with sounds and room reactions), or Off (the old sober kneel-and-sink). It lives next to "Court sounds".
- **Performance.** The court already runs at about 2 ms GPU for 8 people. Keep blood, particles and decals pooled. Nothing may run per frame when idle.
- **The hall remembers.** Trophies follow the real execution count: skulls on stakes, the bronze statues, and floor stains that fade.

## 3. The 25 acts and their status

Legend:
- **REAL**: full K acting plan, J body split, M props, blood and animals, and N sound track, all wired by L.
- **STAGED**: an L director scene using L's own stand-in props and moves (`court_exec_stage.gd`). N's track for these acts is **not yet synced**: the scene has no `"blow"` exec beat, so `_exec_in_step` leaves the track out and the scene's own one-off sound names play (most are silent). Add a `blow` beat at the impact and the track plays in step. M's real props for these acts exist but are not wired in yet.
- **PARTS**: M's props and animals plus N's track exist, but nothing is staged or acted yet.

| # | Act | Needs (era) | Status |
|---|---|---|---|
| 1 | Boulder drop: SPLAT, a hand waves, peeled off the floor like a rug and carried out | any | STAGED |
| 2 | Club home run: the head into the cooking pot, the cook puts the lid on | any | REAL |
| 3 | Into the fire: a charred figure walks two steps, coughs a smoke ring, crumbles; the elder warms his hands | any | STAGED (J's char and crumble used) |
| 4 | Dog dinner: dragged behind the windbreak, crunching, the bone at the god's feet | dog | REAL |
| 5 | Spear pincushion: the child's spear hits the wall, the body topples like a tree | any | STAGED |
| 6 | Stoned by the court: a cairn with one finger raised | any | STAGED |
| 7 | Buried to the neck: the goat eats the hair, then an ox: POP | digging, herds | PARTS |
| 8 | Trampled by the herd: hoofprints, a goat chews the sleeve | herds | PARTS |
| 9 | Pig pen: a skeleton stands, shrugs, collapses | pigs | PARTS |
| 10 | Three-swing beheading: the axe sticks, CLANG, the victim glares and sighs; the third swing lands and the head rolls round and blinks | bronze axe | REAL |
| 11 | Neck-stretch hanging: BOING, the head pops off and keeps swinging in the noose | rope, beam | PARTS |
| 12 | Quartered by oxen: one ox drags an arm out the door | oxen/plough | PARTS |
| 13 | Sawn in half: the halves blink at each other | saws | PARTS |
| 14 | Boiled in the pot: herbs, salt, a skull bobs up; a hungry onlooker only when stores are low | pottery | STAGED |
| 15 | The stake: slides down to eye level with the scribe, who keeps writing | longhouse+ | STAGED |
| 16 | Volley of arrows: a porcupine, the last arrow knocks the hat off | bows | STAGED |
| 17 | Bear pit: swallowed whole, a burp, a sandal spat out | beast pit | PARTS |
| 18 | Elephant foot: POP | war elephants | PARTS. No discovery in the data, so it can never be chosen. Add one or drop it. |
| 19 | The wheel: rolled out the door, crunching away, a shoe rolls back | wheels | PARTS |
| 20 | Molten bronze: a statue frozen mid-scream that stays by the door | bronze casting | PARTS (J's bronze look; M's statue trophy) |
| 21 | Catapult: a whistle, a distant splat, a tooth falls back in | siege engines | PARTS |
| 22 | Under the great stone: the architect checks it's level | a great work underway | PARTS |
| 23 | Falling blade: the dog fetches the head like a ball | a later age | PARTS |
| 24 | Firing squad: the first volley hits only the hat, the body jigs, cymbal | firearms | PARTS |
| 25 | Cannon mouth: red mist paints the hall, the scribe wipes the tablet, a lone clap | gunpowder | PARTS |

**The room, every time:**
- before the act: a drum roll;
- during and after:
  - the front row is splattered and wipes its faces;
  - someone faints, someone vomits into a pot;
  - the child covers their eyes and peeks;
  - the flatterer applauds alone, the scribe keeps writing;
  - the dog steals a part, the envoy's guard gulps;
- at dread 0.7 or above the room stays silent: a swallow and knocking knees only;
- each act runs 6–12 s, and a click skips it.

## 4. Branches (all on origin; none merged to main)

| Branch | Hash | Owner | Contents |
|---|---|---|---|
| `codex/court-executions` | the hash L reports with this doc (it contains every tip below) | L | **The integration branch; start here.** Method parser, era gating, "Put to death ▾" submenu, gore setting, caption, child and off cutaways, skip, the 10 directed scenes, and the wiring of J, K, M and N. |
| `codex/court-exec-acting` | 40372bd7 | K | EXEC_PLANS for acts 2, 10 and 4; room reaction clips; the faint fix; the pose and cloth audit tool |
| `codex/court-exec-set` | 0c46e85e | M | every prop and beast, blood VFX, trophies, statues |
| `codex/court-exec-sound` | 6a1cf013 | N | all 25 act sound tracks, per-person room reactions |
| `codex/court-exec-figures` | fd33296c | J | gore body variants |
| `codex/court-skirt-fix` | eaadfb50 | K, for J | partial cloth fix (tunic and hide follow the legs). Not merged; J owns the clothing fix. |
| `codex/court-robe-fix` | 841f93ff | K | superseded WIP; ignore |

`codex/court-executions` contains 40372bd7, 0c46e85e, fd33296c and 6a1cf013 (checked with `git merge-base --is-ancestor`). It was branched from main aac82927 and also carries M's merge of later main (through #132); merge current main in a worktree before a PR.

Your own `codex/court-motion` (turning, walk speed and foot sync, walk-cancel) overlaps `scripts/hud/court_stage.gd`, `court_figure_3d.gd` and `court_acting.gd`. Merge it into the executions work in a worktree and resolve conflicts there.

## 5. APIs

**Stage and modal (L)**
- `audience_modal.show_execution(words:String, result:={}) -> bool`
  - `words`: the god's own words.
  - `result`: the engine's death result. Pass `{}` only if the engine already killed the victim.
  - Returns false for a child, gore off, or no modelled hall; the sober exit then plays.
- `court_stage.execute(method_id, victim_key="main", ex_key="", name="", how="")`
- `scripts/hud/court_executions.gd` (`Executions`): `pick(words, facts, seed, last)`, `parse`, `available`, `caption`, `menu`, `style`, plus static `gore` and `last_used`.
- The modal routes every engine death of the one before the god through `show_execution` (`_after_command`, `divine`, `act_on_envoy`; P's prisoner fates call it with `{}`). It waits 1.4 s so the order's acknowledgement plays first.
- While an execution plays, narrator lines are held (`_stage_line`); the engine's own outcome line, with "put to death" renamed to the method (`_named_death`), becomes the end caption (`court_stage.exec_caption_override`).
- `court_stage.gd`: `execute()`, `executing()`, `skip_execution()` (a click on the stage), `exec_method`, `exec_done`; `_exec_in_step()` starts N's `play_act` so its t=0 lands on the scene's `blow` beat and drops the scene's own sounds; shot `"frame"` (whole figures and things via M's `frame_points`) and two-shots become frames while executing.
- `scripts/hud/court_exec_stage.gd` (one node per execution, freed at the end) plays the director's `exec` beats: `prop`, `unprop`, `approach`, `twist`, `lean`, `lunge`, `stick`, `retrieve`, `behead` (J's `gore_split`, else a stand-in head), `fall`, `spray`, `pool`, `drag`, `dogs`, `fetch`, `throw`, `char`/`crumble` (J's), `drop`, `vanish`, `caption`, `blow`, `end`; and the plan ops `plan` (K's EXEC_PLANS: places, props via M's `ExecProps.hold`, clips, the victim's `cue` → split and M's blood, the cook's `lid` cue → `ExecProps.seat`), `pack_come`/`pack_crunch`/`pack_fetch` (M's `dog_pack`, `drag_route`, `drag_off`, `fetch`).
- `court_director.gd`: `_execution()`; `_exec_planned()` for acts with a K plan (`PLAN_OF`: club, behead, dogs), timed to the plan's cues; `_exec_club/_behead/_dogs` (older stand-in versions, now unused) and `_exec_fire/_spears/_stoning/_boulder/_boil/_arrows/_stake`; `_exec_after()` (the room); `_exec_mild()` (cut to a face at the blow, no split or blood, the victim vanishes off screen).
- `Executions.staged` lists the methods the director may choose and the menu offers (the 10 above); add an id there once its scene is real.
- Tests: `tests/test_court_executions.gd` (9: parser, gating, choice, captions, child/off, menu, every staged scene, mild, the club plan's order), `tests/test_court_exec_stage.gd` (3: the club plan in the modelled hall, skip, mild, never a child or under off).
- Debug: `tests/court_exec_frame_probe.tscn -- --method=club|behead|dogs` (headless) prints each person's and thing's place on screen through the act and every clip cue.

**Acting (K, `scripts/hud/court_acting.gd`)**
- `EXEC_PLANS[act]` gives, in the victim's frame and scaled by the victim's height:
  - roles with their place and facing;
  - props held in each hand;
  - fixed props (block, pot);
  - the flying or rolling head, moved with `part_at()`;
  - room cue times with suggested reactions;
  - a suggested camera.
- `Acting.hold(fig, node, "R")` puts a prop in the right fist.
- A `cue` signal fires on clip events: `impact`, `split`, `spray`, `geyser`, `thunk`, `clang`, `plop`, `crunch`, `lid`, and so on.
- Room reaction acts: `flinch_splash`, `wipe_face`, `vomit`, `cover_eyes_peek` (with a child version), `applaud_alone`, `wince_crunch`, plus the existing faint and gulp.
- The execution clips are built by `tools/blender/court_anims_exec.py`. None exist on the child body (tested).
- **Audit:** `tools/court_acting_audit.gd` plays every clip on all 7 bodies, about 25 s headless. It flags bones beyond their limits, knees or elbows bent backwards, mesh stretch, and bare skin under cloth. A third argument points it at a folder of figure files, to check a build before import. **Run it before pushing any clip.**
- Capture: `tools/court_acting_capture.gd` has an "exec" mode that stages acts using only these hooks; use it as a reference.

**Figures (J, documented in `docs/COURT_STAGE_3D.md`)**
- Variants are built in Godot from each person's own merged figure, so skin, hair, clothes and face carry over:
  - beheaded, where the loose head can blink;
  - quartered;
  - sawn in half;
  - skeleton, which can stand, shrug and collapse;
  - charred, which crumbles to ash;
  - rug, which rolls up from the feet;
  - bronze statue.
- `gore_split("head")` and its siblings swap meshes at the cue. Pieces freeze at the blow and cost nothing per frame.
- Children: every call returns empty (tested).

**Set, props, animals and blood (M)**
- `scripts/hud/court_exec_props.gd` (`ExecProps`): `exec_prop(name)`, `hold`, `seat`, `release`, `throw()` (stones tumble, spears fly tip-first), `stick()` (rides the nearest bone and quivers).
  - The prop picks its era: a hide bag on a tripod before pottery, a clay pot after; a bronze axe only with metal.
- Props:
  - club, block, axe;
  - pot or bag and lid, paddle;
  - thighbone, skull, skull on stake;
  - boulder and ledge;
  - fire_flare and ash pile;
  - spears and stones;
  - cauldron with `boil()` and `small_fire()`;
  - stake, bow and arrows;
  - gallows with a stretchable noose;
  - `wheel_solid` (named so because Godot drops any node ending in `_wheel`);
  - catapult and arm, cannon and barrel;
  - falling-blade frame and basket;
  - crucible and hoist, monolith and rig;
  - beast-pit gate.
- `scripts/hud/court_blood.gd` via `court_set.blood()`:
  - `geyser(at, dir, seconds, power)` (fire it at J's neck stump), `spray`, pools, splats, blood on people, the cannon's red mist, lasting stains, `clear()`;
  - with gore mild or off, never call `blood()`.
- Animals:
  - `beasts(species, n, coats)` for pigs, cattle, oxen, a bear and an elephant, with `perform(clip)`, `feed_at()` and `stampede_to()`;
  - `dog_pack(n)`, and dogs can `carry`, `fetch` and `drag_off(route)`;
  - `drag_route()`, plus a `behind_windbreak` mark in every set.
- Trophies and statues:
  - `GameState.executions_total` (saved) counts every "Executed…" death, and trophies read it so they never vanish;
  - `CourtSet.remember_statue(look, clip, at)` stores statues in `GameState.court_statues` (saved, at most 6);
  - pass `executions=0` to keep trophies out when gore is off.
- Captures: `tests/court_exec_capture.tscn --only=<tag>` (also `--only=execclip` and `--only=execperf`).
- Measured blood cost mid-geyser: about 1.5–2.4 ms GPU, 0.5 ms CPU, about 10 draws.

**Sound (N)**
- `scripts/hud/court_gore_foley.gd`: about 75 named sounds with variants. The full table is in `L_execution_sound_hooks.txt` in the scratchpad: `C:/Users/sjpur/AppData/Local/Temp/claude/C--Users-sjpur-TomorrowandTomorrow/48492b06-fdc8-45eb-84d3-95f177a925a4/scratchpad/court_night/n/`.
- `court_sound.gd` `play_act(act_name_or_number, roles, {gore})`:
  - queues the whole track and returns the seconds until the blow, so t=0 can be lined up with the impact;
  - the punchline instrument depends on era: hands on a log, then a drum, then cymbals;
  - at dread 0.7 or above the room is silent;
  - some lines are gated by hunger (act 14's stomach growl).
- Room reactions come from the people actually present, in their own voices and by temper, seeded per act. `last_reactions` lists who reacted when, so faces can match.
- Tracks for 2, 4 and 10 are retimed to K's clips (6a1cf013).
- Samples: `scratchpad/court_night/n/exec_samples_r2/` and `exec_samples_r3/`.

## 6. Known issues

1. **Clothing.** Skin shows bare under skirts when knees come up (kneel, sit, crouch, half-catch, stride), skirts stretch between striding legs, and the robe sleeve leaves a gap when the arm is raised.
   - K's audit counts 2,297 failing samples across 113 clips.
   - J is fixing this for all bodies on its own branch: the general court, not executions.
   - K's `codex/court-skirt-fix` is a partial approach. It made the robe worse, so the robe needs another approach.
2. **The faint** used to tear the skirt. It's fixed on `court-exec-acting` (7f47f48f/40372bd7); a separate PR to main is also going in for the live court.
3. **Elephant (#18)** needs a discovery, or should be removed.
4. **Acting.** Acts 1, 3, 5, 6, 14, 15 and 16 need real acting plans (and a `blow` beat so N's track plays). Acts 7–9, 11–13 and 17–25 need staging and acting.
4a. **Framing (the biggest visible problem).** In the recorded fire-circle clips the act often sits at the left edge or partly out of frame: M's `wide`/`frame_points` fit from the hall's base yaw and pitch, and the floor action (block, rolled head, pot) and the head's arc are not kept in view. K's plans carry a suggested god's-view camera (`camera: {from, at}` in the victim's frame) that is not used yet; setting the camera to it for the act is the likely fix.
5. **Walk cancels.** The acting layer may cut special walks short (your finding). Check it against K's layer.
6. **Pacing.** Keep each act 6–12 s. The current dog dinner runs about 12 s.

## 7. Working rules (from AGENTS.md; please follow)

- **Canonical checkout:** `C:/Users/sjpur/TomorrowandTomorrow` is the player's live game. Never edit it, never merge in it, and never touch the running game process.
- **Worktrees:** work in a worktree on a `codex/<task>` branch.
  - Copy `.godot/global_script_class_cache.cfg` and `uid_cache.bin` from canonical.
  - Junction `.godot/imported` to canonical's.
  - Copy canonical's ignored and untracked `*.import` files.
  - **Unlink the junction (`cmd /c rmdir`) before removing any worktree**, or the removal deletes the game's art cache.
- **Godot:** run one process at a time, each run under about 2 minutes. Take the shared lock dir `C:/Users/sjpur/tt-court-lock-godot` (Blender: `tt-court-lock-blender`) with mkdir, write your name in `owner.txt`, and remove only your own lock.
- **Godot console exe:** `C:/Users/sjpur/leviathan/tools/godot/Godot_v4.7-stable_mono_win64/Godot_v4.7-stable_mono_win64_console.exe`.
  - Headless tests: `--headless --path <wt> -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests/<suite>.gd -c --ignoreHeadlessMode`.
- **Blender 5.2:** `"C:/Program Files/Blender Foundation/Blender 5.2/blender.exe" --background --python <script>`.
- **Git:** never `git stash`; use WIP commits. Never commit `.import`, `override.cfg`, saves or caches. Push the branch, open a PR, and verify with `git ls-remote`.
- **Delivery:**
  - main must equal origin/main;
  - the integrator merges a PR, then fast-forwards canonical (`git merge --ff-only origin/main`);
  - the user approves visual work after seeing captures.
- **Captures:** 1536×864 with sound; `clip_avi.py` from N muxes frames plus `f.wav` into an AVI.
  - The execution clip scene: `tests/court_execution_clip.tscn -- --only=<method> --tier=0|1` (fire circle or longhouse). It opens a real petition, gives the order from the "Put to death" words, lets the engine decide, and records about 23 s. For the review reel it adds `bronze_alloying` to the test world when `--only=behead`.
  - Godot's movie writer only records at 1536×864 if a **temporary** `override.cfg` in the worktree sets `[display] window/size/viewport_width=1536`, `viewport_height=864`, `window_width_override=1536` and `window_height_override=864`. Delete it afterwards and never commit it.
  - Run it windowed on a private desktop with `--write-movie <dir>/f.png --fixed-fps 12` (a copy of `tools/run_isolated_gpu_probe.ps1` that passes engine arguments), then `python tools/audio/clip_avi.py <dir> <dir> --fps 12 --gain auto --scale 0.75`.
  - The last recordings of acts 2, 10 and 4 in the fire circle (before the framing fix above) are in L's worktree, `C:/Users/sjpur/tt-court-director/reports/court_clips/exec_{club,behead,dogs}_fire.avi` with `.webp` and `_sheet.jpg` (git-ignored).
  - The disk was nearly full during the night (1 GB free at worst); thin the PNG frames after making the AVI.

## Addendum (after the handoff, 2026-10-03)

- **`codex/court-exec-acting` moved on to `1dd5fe5b`.** It is not yet merged into this branch.
  - `84afb096` holds K's unfinished acting for acts 3, 5, 6, 1, 14, 16 and 15 (`tools/blender/court_anims_exec2.py`). It is timed to N's tracks and sized to M's props. It is not built, previewed, audited or tested, has no `EXEC_PLANS` entries, and is not hooked into the build.
  - `1dd5fe5b` merges main's faint and walk fix into it, so merging it later won't conflict on the clip libraries.
- **Main now has the faint and walk fix** (#136, main `f9c6f398`):
  - Special walks (storm off, led away, sober walk, back out bowing) are no longer cut off by the acting layer after 0.3 s. Clips of kind walk, exit and exec run until they finish or the stage stops them.
  - The faint drops to the knees and keels over, so it no longer pulls the thighs out from under skirts.
  - `tools/court_acting_audit.gd` (pose and cloth audit) is on main.
  - Merge main into this branch before continuing.
- **K's notes for whoever continues:**
  - M's ladle has its bowl on the opposite side of the grip from the club's head. Either act 2's stirring cook holds it bowl-up, or M's ladle needs flipping.
  - K's stake act assumes a 1.85 m stake top; M's stake is 2.68 m. Match one to the other.
  - L's plan staging casts only victim, executioner and cook. Acts with more people (throwers, hoisters, the scribe) need more roles cast.
  - Act 16 (arrows) has a fall at +5.0 s that would want an extra thump in N's track if kept.

## Addendum 2: clothing fix in progress (handed to Astra)

The user has put all court animation, figure and clothing work with Astra. J's unfinished clothing fix is pushed, unmerged, on `codex/court-clothes-fix` at `58a0912a`, based on main with K's skirt fix (eaadfb50) merged in.

- **Done:**
  - The tunic and hide skirt fronts follow the legs.
  - The robe is slit from the hem to above the knee, and its front follows the legs.
  - The sleeve-to-body weights blend over about a hand's width, so the shoulder doesn't tear when an arm goes up.
  - Skin under cloth is hidden only where the cloth moves with it or lies tight. Where a skirt or strap stays behind, a leg or arm shows instead of a hole.
  - `build_all.sh` takes `OUT=...`, so K's audit can check a build before it goes into the game.
  - All seven bodies are rebuilt and committed.
- **Audit counts:** main has 2,297 clothing failures across all bodies, and female_old alone has 421. On female_old, this branch's settings bring that down to 167, mostly the robe and hide stretching when sitting on the floor or kneeling. The final seven-body build has not been audited yet.
- **Needs a visual check:** the audit can't detect skin poking through cloth. The cover change trades holes for that risk, so check kneeling, sitting and striding by eye.
