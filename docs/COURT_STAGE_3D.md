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
- **Expressions: present, 0..1.** `smile, frown, brows_up, brows_down, brows_worried, eyes_wide, eyes_narrow, blink, jaw_open, lips_pressed, sneer, cheeks_puff`.
- **Visemes: present, 0..1.** `v_aa, v_ee, v_oo, v_mm, v_fv`.
- **Gaze: present on `Eyes`, 0..1.** `eyes_left, eyes_right, eyes_up, eyes_down` (the figure's own left is +X). The iris, pupil and catch of light are whole discs that slide inside the white: the white's material writes stencil 1 and theirs read it, drawn after everything solid, so the lids always cut them, however far they roll and however far the lids close (K's eye-bone scale or `blink`). Eyes are not eyeballs on bones: the paint stays on the face, and only what shows through the white moves.
- **Without K's acting:** call `CourtFigure3D.set_expression({name: value})`. It drives whatever keys exist and maps missing ones onto the nearest present key:
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

| `carry("bundle" or "cord", on)` | A carried prop (`prop_bundle`, a hide sack of food; `prop_cord`, a knotted cord to fidget with) rides between the hands each frame, whatever the clip does, until `set_down()` leaves it on the floor where it is. The acting calls it when a clip or stance needs the thing in hand. |
| `drop_held(empty_stance)` | The held bowl (or staff) falls from the hand to the floor and stays there; the figure takes an empty-handed stance. Returns the fallen node. |

**Members:** `skeleton`, `player`, `model`, `stance`, `mood`, `body_height`, `clip`, `seat_height` (a seat the set gives: no stool).

**Each person's own shade** (`scripts/hud/court_figure_look.gd`, figures): `setup()` passes every look through `FigureLook.vary(look)` once (a varied look carries `varied`). Within the people's profile it spreads hair (fair children darken as they grow, near-black runs blue-black to dark brown, the old stay grey), skin (a few percent), dress (fresh or worn and faded), build (`average/stocky/lanky/round/slight`, drawn as the model's scale about the feet) and height (±4.5%), and moves most of those the polite clasp falls to into a stance of their own. Keys the stage's accessor should add (figure_look): `years` (else read from the body and face; a child is under 13 and gets the `child` body, no beard), `seed` (else read from the face), and `keep_stance: true` for anyone whose stance the stage sets on purpose (the one before the god). For a hard cap of one clasp a room, the stage calls `FigureLook.room_stance(look, taken)` with one `taken` Dictionary per room.

**Bodies:** the six grown ones (`VARIANTS`) and `child` (1.24 m, `BODIES`); a missing child body falls back to `female_young`. Clips are exported at 30 frames a second (the walk's 1.18 m/s and 0.92 m/s at 1.72 m match the feet).

**Hair:** cropped and balding hair lie in tufts; a bun is a coil high on the back of the head with its knot. Where hair and beards meet the skin they break into strokes over it (vertex colour G, baked by `court_figures.py`, read by the `stipple` uniform of all three figure shaders; UV is the rest position so the strokes keep still); stubble is strokes all over. No ink is drawn round those strokes.

**One person, few pieces (performance):** in a lit court (`look.lit`) `_dress()` merges the visible parts (`court_figure_merge.gd`) into `Merged/Body` (skin, brows, mouth, beard, lid line; the morphs that move), `Merged/Rest` (outfit), `Merged/Hair` (hair and cards; no shadow) and `Merged/Eyes` (whites writing the stencil, iris/pupil/catch of light reading it), with the person's `face_*` baked into the vertices and one material a figure (`court_figure_uber.gdshader`; each vertex's slot in CUSTOM0.r). Godot skins and morphs every skinned surface in its own pass every frame, so the number of surfaces, not triangles, was the court's cost: eight people with the set went from about 7.5 ms GPU / 5.9 ms CPU a frame to about 2.4 ms / 1.7 ms on the RTX 4090 (`tests/court_perf_probe.tscn`). Props stay separate. Merged meshes are cached by look. K's acting finds its morphs on `Body` and `Eyes` by name as before. Without a set (the studio, the flat stage) the parts stay as they are. A person should come to about 10-12 thousand triangles (`BUDGET` in `court_figures.py`).

**The painted face:** the Body's UV is face space (on a 0.282 m head, from the chin) and UV2 (forward-facing, head-or-neck), written by `court_figures.py`; `court_figure_face.gdshaderinc` paints eye sockets, the nose's sides and nostrils, cheeks, lips of their own colour with dark corners, the jaw's shade, and with years the folds from nose to mouth, crow's feet and lines on the brow; freckles, a mole, a shaved man's shadow of beard. Per person: `face_a` (years, freckles, beard shadow, seed) and `face_b` (blush) instance uniforms on the Body. Skin takes light by its depth: fair skin warms under the light at the edge of the shade and has a pink undertone; deep skin keeps its depth (the fire's orange is tamed on it) and has a cool soft highlight. Note glTF stores V flipped: the shaders read `1 - v`.

**Hair cards:** strips of painted strands laid along each hair shell (`HAIR_CARD`, point attribute `is_card`), walked along the hair's own surface so they never stand out from the head; their strands thin toward their ends.

**Looks in a set:** `look.lit = true` dresses the figure with `court_figure_lit.gdshader` (the set's sun, fire and bounce light it in two soft tones, the shade side keeping a warm tint; both sides drawn, so an open cape or sleeve shows its inside; the sun's shadows fall on a person at 60%) and turns its shadows on. This is the one lit figure shader: M's `court_set_3d.light_figures()` (swapping every shared material to M's twin) must not be called, as it would undo the stencilled eyes (never for the paint on the skin). Without a set, `court_figure_toon.gdshader` paints its own light. Hair has strands and a sheen in both; beards have no inked edge; the darkest hair keeps a little tone (`readable_hair`).

**Rules:**
- Nothing runs per frame in this node except while it carries something between its hands; LookAt and AnimationPlayer do the work.
- **K's acting owns the face and the head turn once bound.** `CourtActing` (a `SkeletonModifier3D` on the skeleton, meta `court_acting` on the figure) switches off this node's two `LookAtModifier3D`s and follows `gaze` (the point `look_at_point` sets) itself, reads `mood`, and writes face morphs directly by cached index (no per-frame Dictionary). While it is bound, `set_mood()` only records the mood and `set_expression()` does nothing: route faces through the acting (`mood` beats).
- Hidden figures must stop their player (`player.stop()`) and set `process_mode = DISABLED`.

## 5. How the stage hosts a set, a camera and directed beats

`CourtStage` (`scripts/hud/court_stage.gd`) is the one stage. It has one `SubViewport` (`view3d`, MSAA 2×) behind the name plates and bubbles. The figures, the set and the camera all live in that viewport.

**The hooks** are static, so the stage stays one file and each builder's code is optional. While a hook is null, the current built-in behaviour stays as the fallback.

```gdscript
CourtStage.set_builder   # M: Object with build(era_id:String, facts:Dictionary) -> Node3D (marks as children, see below)
CourtStage.camera_rig    # M: Object with attach(stage, camera:Camera3D, set_root:Node3D) and shot(name:String, args:Dictionary)
CourtStage.acting        # K: Object with play/look_at/set_mood/speak/idle (the PLAN's API); receives CourtFigure3D nodes
CourtStage.director      # L: Object with beats(event, cast, facts, seed) / ambient(cast, facts, seed) / asides(event, facts, cast, seed)
```

**Without a set** (tests, or a machine without the set models; `CourtStage.use_sets = false`), the viewport is transparent over the painted backdrop, the stage maps its own pixels onto the hall with an orthographic camera, and `layout()` decides where people stand.

**With a set** (`court_set_3d.gd`, M), the Court calls `stage.use_set(Backdrop.current_stage(), facts)` before anyone is added (`audience_modal._new_stage`); the painted backdrop is hidden and kept as the fallback. The stage then:
- puts `CourtSet.build(era, facts)` in `view3d` (not transparent) and uses its `CourtCamera`;
- gives each person a `Spot` on a mark (placed from the mark's own transform, so it works before the stage is in the tree): the one before the god on `petitioner` (an envoy on `envoy_0`), their company on `envoy_1/2`, officials on `officials_*` then the standing `crowd_*` marks, onlookers on `crowd_*` (on a log mark they sit, on the set's seat: `seat_height`, no stool);
- turns officials about half way and onlookers a little toward the one before the god (`rest_yaw`), and takes the light where each stands (`light_at`);
- frames everyone standing (not the seated onlookers) with `camera.wide(spots)`, inset for the button strip (`top_inset`), the plates and the offered object's plinth (`right_reserve`); `view_changed` re-tracks every figure's control and re-places the bubbles;
- walks people in from `door` and out by `door_out` along a way that bends round the fire (`Figure._route`, `stroll` 0 on the mark, 1 at the door);
- answers the god: wrath (`WRATH_ACTS`) shakes the frame and sends the dog cowering; favour sets it wagging; the god's voice makes it look up;
- shows name plates only for the one before the god and whoever is speaking (and under the pointer), so the hall is not a crowd of labels.

Name plates and bubbles always project from 3D through whichever camera is current (`world_to_stage`), so they follow any shot. Marks are `Marker3D` children of the set's `Marks` node named `throne_gaze`, `petitioner`, `officials_<i>`, `crowd_<i>`, `envoy_<i>`, `fire`, `door`, `door_out` and `animal_<i>`; each mark's +Z axis is the way the person faces (the figures' front is +Z); sit marks carry meta `sit` and `seat`.

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
- **With a director installed:** the stage's own acting (below) still runs first, and the director's beats then layer on top. `beats = director.beats(event, cast, facts, seed)`. Each beat is `{t, who, act, args}` (lowered by `director.lower`). The stage runs a beat set on one Tween, sending each beat to:
  - the acting, by the act's name: `acting.call(act, body, args, stage)` for `play`, `look_at`, `mood`, `gesture` and anything else the acting has a method for (K resolves `args.beat` to its clip, gesture or face; an act it has no clip for falls back to the figure's own clip in `args.fallback`, else to its mood and look);
  - the set's camera: `shot` (`wide`, `two_shot` a/b, `push_in` target, `reaction` target, `shake` strength);
  - the room: `hush` stills everyone's idle business (`acting.hush(body, true)`, released after its seconds) and pauses the room's own loops;
  - the set's animals: a beat for the director's `dog` or `goat` plays on the set's beast (`perk_up`, `whimper`, `hide_under`, `sniff`, `tail_wag`, `lie_down`, `scratch`, `bark`);
  - its own bubble: `aside`, whose text must come from `director.asides`.
- **Props follow the acts:** `drop_bowl` drops the held bowl to the floor (they stand clasped after); `struggle_bundle`, `lift_bundle` put the bundle between the hands; `set_down_bundle` leaves it on the floor. In a food gift the envoy's first attendant carries the bundle in.
- **Words:** `say()` also calls `acting.speak(body, text, reveal_time(text))`, so the mouth shapes the words as the bubble reveals them.
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
- **Clips.** `tests/court_morning_clip.tscn` (`--only=wrath|gift --tier=0|1`) runs the real Court with the director, the acting and the set, under Godot's movie writer at a fixed 12 frames a second; `tools/court_clip_gif.py` makes the GIF.
- **Machine etiquette.** Follow PLAN.md:
  - take the shared lock only when nobody holds it (`mkdir C:/Users/sjpur/tt-court-lock` fails if it exists: wait, never write into it), write your owner line, and remove it right after, only if the owner line is still yours; `tools/blender/build_all.sh` takes it once for a whole build;
  - one process at a time;
  - never touch the user's game;
  - no `git stash`;
  - never commit `.import` files or `__pycache__`.
