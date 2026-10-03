# The 3D court stage: contracts for figures, acting, direction and set

Owner and integrator: **J** (`codex/court-figures`, PR #115). Builders: **K** (acting), **L** (director), **M** (set, light, camera, animals). Read `PLAN.md` (the night plan) for the target and the hard rules. This document defines the names and seams everyone codes against. If you need a change here, ask J through the coordinator; J changes it and pushes.

Presentation only, always. The engine decides, and the stage acts out exactly what it decided. Nothing here changes game state.

## 1. Files and who owns them

| File | Owner |
|---|---|
| `tools/blender/cf_*.py`, `tools/blender/court_figures*.py`, `assets/court_figures/court_figure_*.glb` + `court_figures.json` | J |
| `scripts/hud/court_figure_3d.gd` (one figure), `court_figure_studio.gd` (stills), `scripts/shaders/court_figure_*.gdshader` | J |
| `scripts/hud/court_stage.gd`, `scripts/hud/audience_modal.gd` (integration), `tests/test_court_stage.gd`, `tests/court_*capture*` | J |
| `scripts/hud/court_acting.gd`, `tools/blender/court_anims*.py`, `assets/court_figures/anims/*` | K |
| `scripts/hud/court_director.gd`, `scripts/hud/court_asides.gd` | L |
| `scripts/hud/court_set_3d.gd`, `scripts/hud/court_camera.gd`, `tools/blender/court_set*.py`, `tools/blender/court_animals*.py`, `assets/court_sets/*` | M |

## 2. The rig

The six bodies are `male_adult`, `female_adult`, `male_old`, `female_old`, `male_young` and `female_young`, one `.glb` each. They share one skeleton layout, so every clip plays on every body.

- **Imported scene:** `court_figure_<variant>` (Node3D) → `Figure` → `Skeleton3D`, with an `AnimationPlayer` at the root. Animation tracks address `Figure/Skeleton3D:<bone>`, and the AnimationPlayer's `root_node` is `..`.
- **Bones (33):**
  - Body: `root, hips, spine, chest, neck, head`.
  - Face: `jaw, eye.L, eye.R, brow.L, brow.R`.
  - Arms, each with `.L` and `.R`: `shoulder, upper_arm, forearm, hand, thumb, index, fingers`. `fingers` is the middle, ring and little finger together.
  - Legs, each with `.L` and `.R`: `thigh, shin, foot, toe`.
- **Axes:**
  - Godot is Y-up and the figure faces **+Z**, toward the viewer. Its left hand is at +X.
  - In Blender the figure faces -Y, Z-up.
  - Each bone's local +Y runs along the bone. Local +Z faces the figure's front where it can; on `head`, local +Z is the face's forward direction.
- **Scale:**
  - Metres. The reference body is 1.72 m (`male_adult`); the others range from 1.54 to 1.66 m, and limb lengths differ per body.
  - Author clips as rotations. The only translation track is on `hips`, scaled by height / 1.72. `jaw` and the `eye.*` bones carry scale tracks: jaw scale on the vertical axis opens the painted mouth, and eye scale blinks.
- **Rest pose:** A-pose, arms 24° from vertical (20° on old bodies).
- **Clips in every GLB** (default library `""`). All loop at 30 fps except where marked:
  - Stances: `stand, hip, folded, clasped, belt, staff, bowl, sit, crouch`.
  - Stance talking loops: `<stance>_talk`.
  - Both-hands talking: `talk_both`.
  - Played once, ending on their last frame: `bow, kneel, point, raise_hand`.
  - In place (the stage moves the body): `walk_in, walk_out`.
- **Props, shown only in their stance:** `prop_staff` (rides `hand.R`), `prop_bowl` (rides `hand.R`), `prop_stool` (static).
- **Adding K's clips:** put them in an `AnimationLibrary` (`assets/court_figures/anims/*.res` or `.glb`) and attach it with `CourtFigure3D.add_library(name, library)`. Clip names inside a library are `"<library>/<clip>"`. Use the same track paths. Do not key the face-shape tracks inside clips (§3); drive those through the API.

## 3. Shape keys (morph targets)

They live on `Body`, `Eyes`, `Brows`, `Mouth`, and every `hair_*` and `beard_*` mesh. Each person's values are set on their own `MeshInstance3D` (`set_blend_shape_value`), and no material changes. The clips never key these.

- **Face structure: present now, set per person, kept for life.** Each takes -1..1, and 0 is the body's own face:
  - `face_jaw, face_chin, face_cheek, face_nose, face_bridge, face_nose_wide`
  - `face_brow, face_lips, face_ears, face_long, face_round, face_aged`
  - `CourtStage.figure_look()` mixes a people's family face with each person's own.
- **Mood: present now, on `Mouth` and `Brows`.** `mood_smile, mood_tight, mood_worry, mood_stern`.
- **Expressions: J adds these next, 0..1.** `smile, frown, brows_up, brows_down, brows_worried, eyes_wide, eyes_narrow, blink, jaw_open, lips_pressed, sneer, cheeks_puff`.
- **Visemes: J adds these next, 0..1.** `v_aa, v_ee, v_oo, v_mm, v_fv`.
- **Until they exist:** call `CourtFigure3D.set_expression({name: value})`. It drives whatever keys exist and maps missing ones onto the nearest present key:
  - `smile` → `mood_smile`;
  - `lips_pressed` → `mood_tight`;
  - `brows_worried` → `mood_worry`;
  - `brows_down` → `mood_stern`;
  - `jaw_open` and the visemes → jaw bone scale;
  - `blink` → eye bone scale.

  Code against the names in this section, not against the stand-ins.

## 4. One figure: `scripts/hud/court_figure_3d.gd` (`CourtFigure3D`, preload it)

A look is a Dictionary: `{variant, outfit, hair, beard, skin, hair_colour, cloth:[a,b,c], leather, without:[], stance, face:{shape: -1..1}, mood}`. Looks come from `CourtStage.figure_look(person, registry)`, the one place a person's appearance is read. It draws on the people's appearance profile, sex, age, era, rank and a hash of the person.

**Static functions:**
- `available()`: whether the figures can be shown.
- `material(slot, colour, cover)`: shared materials.
- `set_key_light(dir)`.
- `STANCES`, `FREE_HANDS`, `PROPS`, `FACE_SHAPES`, `MOODS`.

**On a figure:**

| Call | What it does |
|---|---|
| `setup(look) -> bool` | Dress the figure. It re-dresses without rebuilding when the body variant is unchanged. |
| `play(clip, blend=0.25, at=-1)` | Play a clip (any library). Props show only in their stance. |
| `rest_clip()`, `talk_clip(both_hands)` | The person's stance, and their talking loop. |
| `face(yaw_degrees, time)` | Turn the body. 0 faces the viewer; + turns to screen-right. |
| `look_at_point(world_pos or null, time)` | Head and neck attend to a point, through `LookAtModifier3D` on `neck` and `head` after the clip. `null` releases them. |
| `set_mood(name)` | `warm`, `neutral`, `afraid`, `defiant` or `grieved` (mouth, brows, head pitch). |
| `set_light(amount)` | Per-instance light: about 1.06 for a speaker, 0.95 for a listener. |
| `set_expression(dict)` | §3. |
| `add_library(name, lib)` | §2. |
| `head_top() -> Vector3` | Where speech bubbles hang. |

**Members:** `skeleton`, `player`, `model`, `stance`, `mood`, `body_height`, `clip`.

**Rules:**
- Nothing runs per frame in this node; LookAt and AnimationPlayer do the work.
- K's `CourtActing` drives figures **only** through this API and the AnimationPlayer it exposes.
- Hidden figures must stop their player (`player.stop()`) and set `process_mode = DISABLED`.

## 5. How the stage hosts a set, a camera and directed beats

`CourtStage` (`scripts/hud/court_stage.gd`) is the one stage. It has one transparent `SubViewport` (`view3d`, MSAA 2×) behind the name plates and bubbles. The figures, the set and the camera all live in that viewport.

**The hooks** are static, so the stage stays one file and each builder's code is optional. While a hook is null, the current built-in behaviour stays as the fallback.

```gdscript
CourtStage.set_builder   # M: Object with build(era_id:String, facts:Dictionary) -> Node3D (marks as children, see below)
CourtStage.camera_rig    # M: Object with attach(stage, camera:Camera3D, set_root:Node3D) and shot(name:String, args:Dictionary)
CourtStage.acting        # K: Object with play/look_at/set_mood/speak/idle (the PLAN's API); receives CourtFigure3D nodes
CourtStage.director      # L: Object with beats(event, cast, facts, seed) / ambient(cast, facts, seed) / asides(event, facts, cast, seed)
```

**Without a set** (today), the stage maps its own pixels onto the hall with an orthographic camera, and `layout()` decides where people stand.

**With a set**, the stage:
- adds `set_builder.build(era, facts)` to `view3d`;
- stands people on the set's marks: `petitioner` for the one before the god, `officials_0..n`, `envoy_0..n`, `crowd_*`;
- hands the camera to `camera_rig`.

Name plates and bubbles always project from 3D through whichever camera is current (`world_to_stage`), so they follow any shot. Marks are `Node3D` children named exactly `throne_gaze`, `petitioner`, `officials_<i>`, `crowd_<i>`, `envoy_<i>`, `fire`, `door` and `animal_<i>`; each mark's -Z axis is the way the person faces.

**Events.** Every stage event goes through one function, `CourtStage.event(kind:String, data:Dictionary)`. These are the events and their data:

| kind | data |
|---|---|
| `open` | `{layout: "home"/"envoy", era}` |
| `line` | `{who: key, text, seconds, aside}` |
| `god` | `{text, seconds}` |
| `direction` | `{who: key or "", mood: dread/reverence/point/order}` |
| `divine` | `{action, response}`. The engine's response (`defy`, `cower`, `endure`, `relief`, `blessed`) rules. |
| `enter` | `{who}` |
| `exit` | `{who, style: bow/storm/led/fall}` |
| `gift` | `{what}` |
| `decree` | `{accepted: bool}` |
| `close` | `{}` |

- **Cast:** `[{key, role: main/court/attendant, person, figure: CourtFigure3D, mood}]`.
- **Facts:** `CourtStage.facts`, a Dictionary the Court fills from the engine. It holds `era, season, stores_days, hungry, sick, at_war, love, dread, mood, offer`. Show nothing that isn't in it.
- **With a director installed:** the stage's own acting (below) still runs first, and the director's beats then layer on top. `beats = director.beats(event, cast, facts, seed)`. Each beat is `{t, who, act, args}`. The stage runs a beat set on one Tween, sending each beat to:
  - `acting`: `play`, `look_at`, `mood`, `speak`, `gesture`;
  - `camera_rig.shot`: `shot`;
  - its own bubble: `aside`, whose text must come from `director.asides`.
- **Seed:** `hash(audience_id + event index)`, so the same audience plays the same way.
- **Built-in behaviour** (always runs; it is all there is without a director):
  - the speaker talks and the others look at them;
  - the god's words lift every face;
  - directions act on the person they are about, using `about` from the engine, or a name that opens the line;
  - defy stands firm, cower kneels, favour bows.

## 6. Integration (J)

- **Branches.** K, L and M branch from `origin/codex/court-figures`, merge it often, and push their own branch. J merges `origin/codex/court-acting`, `origin/codex/court-director` and `origin/codex/court-set` into `codex/court-figures` at each checkpoint, one at a time, with a test run and captures between merges. Nothing goes to main.
- **Contracts.** A builder's work is integrated through the hooks in §5. J sets the hook in `audience_modal.gd`, for example `CourtStage.director = preload("res://scripts/hud/court_director.gd").new()`, only once that builder's tests pass headless.
- **Tests.**
  - `tests/test_court_stage.gd` must stay green after each merge.
  - Each builder brings their own suite (`test_court_acting.gd`, `test_court_director.gd`, `test_court_set*.gd`), which runs headless with no network and no save writes.
- **Captures.** `tests/court_stage_capture.tscn` on the private desktop (`tools/run_isolated_gpu_probe.ps1`), at 1536×864.
- **Machine etiquette.** Follow PLAN.md:
  - take the shared lock (`mkdir C:/Users/sjpur/tt-court-lock`) before any Godot or Blender run, and remove it right after;
  - one process at a time;
  - never touch the user's game;
  - no `git stash`;
  - never commit `.import` files or `__pycache__`.
