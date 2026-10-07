extends Node3D
## The court's set: a modelled place for the people to stand before their god,
## made in Blender by tools/blender/court_set.py (assets/court_sets/), lit by
## the sky, the sun and the fire, with smoke and sparks rising and dust in the
## light. The court grows with the people:
##   fire_ring      logs about a fire under the open sky (the earliest bands)
##   shelter        a reed roof on posts over the fire once they settle
##   longhouse      the chief's long timber hall
##   mudbrick_hall  plastered mudbrick, a light well, a stepped dais
##   grand_hall     dressed stone, columns, high windows, a canopied seat
## kind_for maps the court's civic stage (data/civic/civic_stages.json) and
## era tier to a set.
##   CourtSet.build(era_id, facts) -> this node, with
##     marks      Node3D (Marker3D) children of "Marks": throne_gaze (where the
##                god's presence is), petitioner, officials_*, crowd_*, envoy_*,
##                fire, door, door_out, animal_*. A mark's -Z is the way a
##                person there faces (docs/COURT_STAGE_3D.md); place() turns a
##                figure (whose front is +Z) to match. Sit marks carry meta
##                "sit" and "seat" (the seat's height; hide the figure's stool).
##     camera     a CourtCamera (court_camera.gd, a Camera3D): the set's lens
##                and its rig (rig is the same object); attach() lets it
##                drive a stage's own camera instead
##     lights     the sun (the one shadowed light), the fire (flickering), a
##                warm bounce, the door's daylight in a hall, braziers
##     props      shown from the facts: food in the baskets, on the rack and
##                the board with the real stores; spears racked (all in war);
##                pots, looms, hangings, tablets, bread and lamps only once
##                the people know how to make them (their era tags)
##     animals    a dog in every age; herd animals and fowl once kept
## Facts, in the stage's words (CourtStage.facts / CourtDirector.facts_now):
## food_days or stores_days, hungry, war (a Dictionary or a bool) or at_war,
## era_tier, era_tags, season; or the set's own: food 0..1, war, tier, herds,
## fowl, dyes (the people's three cloth colours, hex), seed.
## The season (spring, summer, autumn, winter) shows: snow lying and breath
## in the cold, dry grass and flies about the food in summer, fallen leaves in
## autumn, flowers in the grass in spring.
## Ink: "screen" (one pass over the whole stage, from depth: the figures and
## the set need no inked shells, half their drawing) or "hull" (each piece
## carries its own inked shell, as before; the fallback). CourtSet.ink.
## Quality: "high", "low" or "auto" (CourtSet.quality). Low drops the heat
## shimmer, thins the smoke and sparks, the dust and the snow, inks only the
## set's main pieces, shortens the shadows and the far blur. Auto starts high
## and drops to low, once, if the frames come slow while the court is open.
## The god's presence, made visible: god_light(body, tone) lets a light fall
## on the one the god addresses: "speaks" (soft gold from above, the room a
## touch dimmer, dust glittering in the beam, the fire leaning and dipping),
## "wrath" (cold and harsh, the shadows sharp and long toward them, the fire
## guttering, a gust in the hides driving the smoke sideways), "favour" (warm
## gold, the fire brightening, motes rising), "off" (all eased back). Under the
## open sky it falls from the sky; in a hall through the smoke hole or the
## window. One unshadowed spot and a small diffuse face return, the shaft
## effect and one small dust emitter.
## Presentation only: nothing here reads or changes the game's state except
## facts_from_game(), which only reads. Nothing is allocated per frame; the
## set stops processing when it is hidden (set_active).

const DIR:="res://assets/court_sets/"
const MANIFEST:=DIR+"court_sets.json"
const CHAPTER_MANIFEST:=DIR+"court_chapters.json"
const Chapters:=preload("res://scripts/hud/court_chapters.gd")
const CourtCamera:=preload("res://scripts/hud/court_camera.gd")
const Daylight:=preload("res://scripts/hud/court_daylight.gd")
const Motion:=preload("res://scripts/hud/motion.gd")
const Animal:=preload("res://scripts/hud/court_animal_3d.gd")
const TOON:=preload("res://assets/court_sets/shaders/court_set_toon.gdshader")
const GROUND:=preload("res://assets/court_sets/shaders/court_set_ground.gdshader")
const INK:=preload("res://assets/court_sets/shaders/court_set_ink.gdshader")
const WASH:=preload("res://assets/court_sets/shaders/court_wash.gdshader")
const FLAME:=preload("res://assets/court_sets/shaders/court_flame.gdshader")
const SHIMMER:=preload("res://assets/court_sets/shaders/court_shimmer.gdshader")
const SMOKE:=preload("res://assets/court_sets/shaders/court_smoke.gdshader")
const EMBER:=preload("res://assets/court_sets/shaders/court_ember.gdshader")
const MOTE:=preload("res://assets/court_sets/shaders/court_mote.gdshader")
const SHAFT:=preload("res://assets/court_sets/shaders/court_shaft.gdshader")
const CONTACT:=preload("res://assets/court_sets/shaders/court_contact.gdshader")
const SKY:=preload("res://assets/court_sets/shaders/court_sky.gdshader")
const PAPER:=preload("res://assets/court_sets/shaders/court_paper.gdshader")
const POOL:=preload("res://assets/court_sets/shaders/court_pool.gdshader")
const Blood:=preload("res://scripts/hud/court_blood.gd")
const BOIL:=preload("res://assets/court_sets/shaders/court_boil.gdshader")
const ExecProps:=preload("res://scripts/hud/court_exec_props.gd")
const INK_POST:=preload("res://assets/court_sets/shaders/court_ink_post.gdshader")

const KIND_BY_STAGE:={
	"hearth_council":"fire_ring","fire_circle":"fire_ring",
	"elders_circle":"shelter","elders_ring":"shelter",
	"chiefs_hall":"longhouse",
	"temple_palace":"mudbrick_hall","palace_bureaucracy":"mudbrick_hall","palace_hall":"mudbrick_hall",
	"citizen_assembly":"grand_hall","assembly_tiers":"grand_hall","imperial_court":"grand_hall","imperial_hall":"grand_hall",
	"senate_house":"grand_hall","council_house":"grand_hall","late_antique_hall":"grand_hall","basilica":"grand_hall",
	"feudal_hall":"grand_hall","great_hall":"grand_hall","chancery_court":"grand_hall","chancery":"grand_hall",
	"chartered_commune":"grand_hall","commune_hall":"grand_hall","estates_assembly":"grand_hall","estates_hall":"grand_hall",
	"privy_state_council":"grand_hall","parliamentary_council":"grand_hall","ministerial_cabinet":"grand_hall","executive_council":"grand_hall",
}
const STAND_IN:={"shelter":"fire_ring","mudbrick_hall":"longhouse","grand_hall":"mudbrick_hall"}
const KIND_BY_TIER:=["fire_ring","longhouse","mudbrick_hall","grand_hall","grand_hall"]

## Each slot's paint: [colour, worn colour, accent a, accent b]; its pattern
## (court_set_toon.gdshader) and motif. "dye0".."dye2" take the people's dyes.
const PALETTE:={
	"BARK":["4a3829","5a4634"],"WOOD":["7a5c40","957452"],"WOOD_END":["a38a66","b09572"],
	"CHAR":["110d0a","18120e"],"ASH":["7d776f","8e877d"],"EMBER":["6a2a12","6a2a12"],
	"STONE":["7a7266","867d70"],"STONE_LICHEN":["8a8478","968f82"],"STONE_DARK":["4c4640","56504a"],"STONE_BLOCK":["a39a88","aea590"],"FLAGS":["8e877a","a19886"],
	"HIDE":["8c6744","9c7752"],"HIDE_DARK":["5c4230","6a4e3a"],"HIDE_PALE":["9e8462","ab9170"],
	"CORD":["4e3a29","4e3a29"],"REED":["94804f","a38e5c"],"THATCH":["6e5838","7a6340"],
	"CLAY":["985a37","a66a45"],"MUD":["86704f","6c573d"],"PLANK":["6b5039","7f6249"],
	"PLASTER":["cdbf9f","b9a985","","a07650"],"BRICK":["9a7650","a6825c"],"TABLET":["a58a66","a58a66"],
	"FOOD_ROOT":["8a5e38","8a5e38"],"FOOD_GRAIN":["b99a58","b99a58"],"MEAT":["5c2a1f","5c2a1f"],
	"FISH":["948a74","948a74"],"BONE":["cfc3a6","cfc3a6"],"OCHRE":["7a3220","7a3220"],
	"FLINT":["45424a","514e55"],"BRONZE":["8c6430","a07a40"],"GOLD":["b08a3a","c49c48"],
	"LEAF":["3b4628","485332"],"GRASS":["5b6634","70714a"],"BERRY":["4a2224","4a2224"],"SOOT":["4a443e","56504a"],
	"ONION":["b89a6a","b89a6a"],"BREAD":["a8743c","b8844a"],
	"BROTH":["7a5634","7a5634"],"BLOOD_DRY":["5a1410","5a1410"],"SOCKET":["1c1410","1c1410"],
	"SKULL":["e2d7bd","e2d7bd"],"FLETCH":["d9d0bc","d9d0bc"],"IRON":["45464a","55565a"],"MELT":["ffb040","ffd070"],"BRONZE_CAST":["c08a42","dcae62"],"WICKER":["a8894f","b8995c"],
	"BLANKET":["dye0","dye0"],
	"WEAVE_A":["dye0","dye0","dye1","e3d4b0"],"WEAVE_B":["dye1","dye1","dye2","e3d4b0"],"WEAVE_C":["d8c8a4","d8c8a4","dye0","dye2"],
	"CARPET":["dye0","dye0","dye1","d8c4a0"],
	"PAPER":["e5ddc7","eee7d6"],"GLASS":["9aacac","bbc8c4"],
	"WINDOW_GLASS":["9bb6bd","b9cbd0"],
	"METAL":["666b6c","8a9090"],"LEATHER":["443c35","5d5147"],
	"SCREEN":["303f46","3f5259"],"CERAMIC":["d8d5c9","ece8dc"],
	"SHIELD_A":["9c7a52","9c7a52","dye0","e3d4b0"],"SHIELD_B":["e0d0ac","e0d0ac","dye1","2a2018"],"SHIELD_C":["7a5a3a","7a5a3a","b08a3a","e3d4b0"],
}
## slot: [pattern, motif, scale]
const PATTERN:={
	"BARK":[1,0,1.0],"WOOD":[1,0,0.6],"WOOD_END":[2,0,1.0],"HIDE":[3,0,1.0],"HIDE_DARK":[3,0,1.0],"HIDE_PALE":[3,0,1.0],
	"SHIELD_A":[4,0,1.0],"SHIELD_B":[4,1,1.0],"SHIELD_C":[4,2,1.0],
	"WEAVE_A":[5,0,1.0],"WEAVE_B":[5,0,1.0],"WEAVE_C":[5,0,1.0],"BLANKET":[5,0,1.0],"CARPET":[6,0,1.0],
	"THATCH":[7,0,1.0],"REED":[8,0,1.0],"PLANK":[9,0,1.0],"PLASTER":[10,0,1.0],"BRICK":[11,0,1.0],"MUD":[11,0,1.0],
	"STONE_BLOCK":[12,0,1.0],"FLAGS":[13,0,1.0],"CHAR":[14,0,1.0],"STONE_LICHEN":[15,0,1.0],
}
const DEFAULT_DYES:=["8e3b2e","3f5f6f","c39a3c"]
## How each kind of set is lit and aired, and its distance in three washes.
const LOOK:={
	"fire_ring":{"ambient":"7f8fa6","ambient_energy":0.5,"sun":"ffd9aa","fog":"b4c0c2","fog_density":0.002,
		"grass":"5c6a36","grass_dry":"7c784a","earth":"7a634a","earth_dark":"574535","straw":0.0,"exposure":0.95,
		"sky_top":"86a6c2","sky_horizon":"efe0bd","haze":"aebfc6",
		"far":[["4f5a3a","3a4430",0.05],["6f7c66","4a5446",0.35],["93a3ad","66727c",0.55]]},
	"shelter":{"ambient":"7f8fa6","ambient_energy":0.5,"sun":"ffd9aa","fog":"b4c0c2","fog_density":0.002,
		"grass":"5e6b36","grass_dry":"7f7a4a","earth":"7a634a","earth_dark":"574535","straw":0.1,"exposure":0.95,
		"sky_top":"86a6c2","sky_horizon":"efe0bd","haze":"aebfc6",
		"far":[["4f5a3a","3a4430",0.05],["6f7c66","4a5446",0.35],["93a3ad","66727c",0.55]]},
	"longhouse":{"ambient":"6e5c4c","ambient_energy":0.3,"sun":"ffe2b8","fog":"4e4034","fog_density":0.012,
		"grass":"5c6a36","grass_dry":"7c784a","earth":"6c5640","earth_dark":"4b3b2c","straw":0.22,"exposure":1.0,
		"sky_top":"86a6c2","sky_horizon":"efe0bd","haze":"aebfc6",
		"far":[["5a6440","3a4430",0.1],["7a8670","4a5446",0.4],["9aaab2","66727c",0.6]]},
	"mudbrick_hall":{"ambient":"7a6a58","ambient_energy":0.34,"sun":"ffe6c0","fog":"6a5a48","fog_density":0.01,
		"grass":"6e6a3c","grass_dry":"8c8050","earth":"8a7456","earth_dark":"64523c","straw":0.12,"exposure":1.0,
		"sky_top":"86a6c2","sky_horizon":"efe0bd","haze":"c2c6c0",
		"far":[["7a7650","4a4630",0.15],["948c70","5a5444",0.45],["b0b0aa","7a7c7c",0.6]]},
	"grand_hall":{"ambient":"6e6a66","ambient_energy":0.32,"sun":"fff0d8","fog":"5c5650","fog_density":0.008,
		"grass":"5c6a36","grass_dry":"7c784a","earth":"7a6a58","earth_dark":"5a4c3e","straw":0.0,"exposure":1.0,
		"sky_top":"86a6c2","sky_horizon":"efe0bd","haze":"c2c6c0",
		"far":[["5a6440","3a4430",0.1],["7a8670","4a5446",0.4],["9aaab2","66727c",0.6]]},
}

static var enabled:=true
## "high", "low" or "auto" (start high, drop to low if the frames come slow).
static var quality:="auto"
## "screen" or "hull" (see above). The stage asks uses_screen_ink() before it
## dresses its figures: with screen ink they need no shells of their own.
static var ink:="screen"
## Auto drops to low when the frames average slower than this (seconds).
const SLOW_FRAME:=1.0/45.0
## Seasons, as the stage's facts name them.
const SEASONS:=["spring","summer","autumn","winter"]
static var _manifest:Dictionary={}
static var _scenes:Dictionary={}
static var _materials:Dictionary={}
static var _ink_material:ShaderMaterial
static var _contact_material:ShaderMaterial
static var _contact_mesh:PlaneMesh

var kind:=""
var era_id:=""
var info:Dictionary={}
var facts:Dictionary={}
var marks:Dictionary={}
var rig:Node
var camera:Camera3D
var sun:DirectionalLight3D
var fire_light:OmniLight3D
var bounce:OmniLight3D
var door_light:SpotLight3D
var flame_lights:Array[OmniLight3D]=[]
var _flame_energies:Array[float]=[]
var world_env:WorldEnvironment
var model:Node3D
var animals:Array=[]
var props:Dictionary={}
var gates:Dictionary={}
var technology_gates:Dictionary={}
var institution_gates:Dictionary={}
var particles:Array[GPUParticles3D]=[]
var active:=true
var _noise:=FastNoiseLite.new()
var _clock:=0.0
var _fire_energy:=2.0
## The god's light: its parts (made on first use) and where it stands.
const GOD_KEYS:=["energy","angle","shaft","dim","fire","fire_h","lean","gust","sharp","sat","sun_turn","rise"]
const GOD_NEUTRAL:=[0.0,15.0,0.0,0.0,1.0,1.0,0.0,0.0,0.0,0.0,0.0,0.0]
const GOD_TONES:={
	"speaks":{"colour":Color(1.0,0.86,0.58),"p":[7.0,15.0,0.55,0.22,0.78,0.85,0.22,0.0,0.0,0.0,0.0,0.15]},
	"wrath":{"colour":Color(0.84,0.89,1.0),"p":[2.4,12.0,0.4,0.55,0.32,0.42,0.6,1.0,1.0,-0.2,1.0,0.0]},
	"favour":{"colour":Color(1.0,0.76,0.42),"p":[6.0,21.0,0.5,0.1,1.35,1.25,0.0,0.0,0.0,0.06,0.0,1.0]},
}
var god_tone:="off"
var god_spot:SpotLight3D
var god_return:OmniLight3D
var god_shaft:MeshInstance3D
var god_dust:GPUParticles3D
var _god_shaft_mat:ShaderMaterial
var god_pool:MeshInstance3D
var _god_pool_mat:ShaderMaterial
## The hall's own sun shafts (dimmed while the god's light owns the opening).
var _sun_shaft_mats:Array[ShaderMaterial]=[]
var _sun_shaft_strength:Array[float]=[]
var _window_daylight:Array[MeshInstance3D]=[]
var _god_out:=-1.0
var _god_dust_mat:ShaderMaterial
var _god_dust_pm:ParticleProcessMaterial
var _god_cur:=PackedFloat32Array(GOD_NEUTRAL)
var _god_from:=PackedFloat32Array(GOD_NEUTRAL)
var _god_to:=PackedFloat32Array(GOD_NEUTRAL)
var _god_col_from:=Color(1,1,1)
var _god_col_to:=Color(1,1,1)
var _god_col:=Color(1,1,1)
var _god_tween:Tween
var _god_base:={}
var _god_target:=Vector3.ZERO
var _god_target_ref:WeakRef
var _god_origin:=Vector3.ZERO
var _god_beam_basis:=Basis.IDENTITY
var _god_reduced:=false
var _god_wind:=Vector3(1.0,0.1,0.35)
var _sun_wrath:=Quaternion.IDENTITY
var _fire_mul:=1.0
## The god's own fire settings (god_light) and the hearth's flare on top (fire_flare).
var _fire_now:=1.0
var _fire_h_now:=1.0
var _flare:=0.0
var _flame_mats:Array[ShaderMaterial]=[]
var _gust_mats:Array[ShaderMaterial]=[]
var _smoke_pm:ParticleProcessMaterial
var _smoke_gravity:=Vector3.ZERO
var _fire_at:=Vector3.ZERO
var _flame_at:Array[Vector3]=[]
var _shaft_top:=Vector3.ZERO
var _shaft_dir:=Vector3.DOWN
var _shaft_radius:=0.0
var _dyes:Array=[]
var _rack_at:=Vector3.ZERO
## The quality in force now ("high" or "low"), and why.
var level:="high"
var level_reason:=""
var season:=""
var shimmer:MeshInstance3D
var ink_pass:MeshInstance3D
## The ink in force for this set: "screen" or "hull".
var ink_mode:="screen"
var flies:Array[GPUParticles3D]=[]
var snowfall:GPUParticles3D
var breaths:Array[GPUParticles3D]=[]
var fill_lights:Array[OmniLight3D]=[]
var _dressing:Array=[]
var _frames_seen:=0
var _slow_time:=0.0

# --- Building ---------------------------------------------------------------------

static func manifest()->Dictionary:
	if _manifest.is_empty():
		var text:=FileAccess.get_file_as_string(MANIFEST)
		var parsed:Variant=JSON.parse_string(text) if not text.is_empty() else null
		_manifest=parsed if parsed is Dictionary else {"sets":{}}
		if FileAccess.file_exists(CHAPTER_MANIFEST):
			var chapters:Variant=JSON.parse_string(FileAccess.get_file_as_string(CHAPTER_MANIFEST))
			if chapters is Dictionary:
				(_manifest["sets"] as Dictionary).merge((chapters as Dictionary).get("sets",{}),true)
	return _manifest

static func scene_for(set_kind:String)->PackedScene:
	if not _scenes.has(set_kind):
		var entry:Dictionary=(manifest().get("sets",{}) as Dictionary).get(set_kind,{})
		var path:=DIR+String(entry.get("glb","court_set_%s.glb" % set_kind))
		_scenes[set_kind]=load(path) as PackedScene if ResourceLoader.exists(path) else null
	return _scenes[set_kind]

## Whether a modelled set can be shown at all (else the painted backdrop stays).
static func available()->bool:
	return enabled and scene_for("fire_ring")!=null

## The set for a court: era_id is the civic stage (its id or scene), a set's
## own kind, or "tier_N"; tier picks among stages that share a set.
static func kind_for(era_id_in:String,tier:=-1,chapter:Dictionary={})->String:
	var chapter_kind:=String(chapter.get("set_kind",""))
	if not chapter_kind.is_empty() and (manifest().get("sets",{}) as Dictionary).has(chapter_kind):return chapter_kind
	var wanted:=""
	if KIND_BY_STAGE.has(era_id_in):wanted=String(KIND_BY_STAGE[era_id_in])
	elif (manifest().get("sets",{}) as Dictionary).has(era_id_in) or STAND_IN.has(era_id_in):wanted=era_id_in
	elif era_id_in.begins_with("tier_"):wanted=String(KIND_BY_TIER[clampi(int(era_id_in.trim_prefix("tier_")),0,KIND_BY_TIER.size()-1)])
	elif tier>=0:wanted=String(KIND_BY_TIER[clampi(tier,0,KIND_BY_TIER.size()-1)])
	else:wanted="fire_ring"
	# a settled people's fire circle is roofed over
	if wanted=="fire_ring" and tier>=1:wanted="shelter"
	var sets:Dictionary=manifest().get("sets",{})
	var guard:=0
	while not sets.has(wanted) and STAND_IN.has(wanted) and guard<6:
		wanted=String(STAND_IN[wanted]);guard+=1
	return wanted if sets.has(wanted) else "fire_ring"

## The set for this court, its marks, lights, camera and animals, dressed by the facts.
static func build(era_id_in:String,facts_in:Dictionary={})->Node3D:
	var made:Node3D=(load("res://scripts/hud/court_set_3d.gd") as GDScript).new()
	made.call("_build",era_id_in,facts_in)
	return made

## The stage's facts in the set's own words: food 0..1, war 0..1, tier, era
## tags, herds, fowl. Missing facts stay missing (the set's defaults stand).
static func normal_facts(raw:Dictionary)->Dictionary:
	var out:=raw.duplicate()
	if not out.has("food"):
		var days:Variant=raw.get("food_days",raw.get("stores_days",null))
		if days is int or days is float:out["food"]=clampf((float(days)-2.0)/45.0,0.0,1.0)
	if bool(raw.get("hungry",false)):out["food"]=minf(float(out.get("food",0.15)),0.15)
	var war:Variant=raw.get("war",raw.get("at_war",null))
	if war is Dictionary:out["war"]=1.0 if not (war as Dictionary).is_empty() else 0.0
	elif war is bool:out["war"]=1.0 if war else 0.0
	elif war is int or war is float:out["war"]=clampf(float(war),0.0,1.0)
	if not out.has("tier") and raw.has("era_tier"):out["tier"]=int(raw.era_tier)
	var tags:Variant=raw.get("era_tags",null)
	if tags is Array or tags is PackedStringArray:
		out["era_tags"]=Array(tags)
		if not out.has("herds"):out["herds"]=(Array(tags)).has("dairy")
	return out

func _build(era_id_in:String,facts_in:Dictionary)->void:
	era_id=era_id_in
	ink_mode="hull" if ink=="hull" else "screen"
	Animal.hull_ink=ink_mode=="hull"
	facts=normal_facts(facts_in)
	kind=kind_for(era_id,int(facts.get("tier",-1)),facts.get("chapter",{}))
	name="CourtSet_"+kind
	info=((manifest().get("sets",{}) as Dictionary).get(kind,{}) as Dictionary).duplicate(true)
	_noise.seed=int(facts.get("seed",11));_noise.frequency=1.0
	_dyes=facts.get("dyes",DEFAULT_DYES) if facts.get("dyes",[]) is Array and (facts.get("dyes",[]) as Array).size()>=3 else DEFAULT_DYES
	var packed:=scene_for(kind)
	if packed!=null:
		model=packed.instantiate() as Node3D
		model.name="Model"
		add_child(model)
		_apply_renewal()
		_dress(model)
		_collect_props(model)
	_make_marks()
	_make_environment()
	_make_lights()
	_make_fires()
	_make_air()
	# the set's camera is its own rig: shots by name (wide, push_in, reaction,
	# two_shot, shake), view_changed while it moves, attach() to drive a stage's
	camera=CourtCamera.new();camera.name="Lens"
	add_child(camera)
	rig=camera
	rig.call("configure",info.get("camera",{}))
	camera.current=true
	_make_paper()
	_make_season_fx()
	apply_facts(facts)
	_place_animals()
	set_quality(quality if quality!="auto" else "high","asked" if quality!="auto" else "start")
	visibility_changed.connect(_on_visibility)
	# a cheap far blur: the court is the only place that asks for it
	RenderingServer.camera_attributes_set_dof_blur_quality(RenderingServer.DOF_BLUR_QUALITY_LOW,false)

func _on_visibility()->void:
	set_active(is_visible_in_tree())

# --- Materials ----------------------------------------------------------------------

func _look()->Dictionary:
	var base:=String(info.get("look_base",kind))
	var out:Dictionary=(LOOK.get(base,LOOK.grand_hall) as Dictionary).duplicate()
	out.merge(info.get("look",{}),true)
	return out

func has_hearth()->bool:
	return bool(info.get("has_hearth",(info.get("fx",{}) as Dictionary).has("fire")))

func indoors()->bool:
	return bool(info.get("indoor",not bool((info.get("light",{}) as Dictionary).get("open_sky",true))))

## A people whose building knowledge lags behind the calendar renovates its
## available building. Alternate the entrance/service side and room width,
## moving the authored furniture and its marks together, never the people alone.
func _apply_renewal()->void:
	var chapter:Dictionary=facts.get("chapter",{})
	if not bool(chapter.get("limited",false)) or not kind.begins_with("chapter_"):return
	var index:=int(chapter.get("renewal",0))
	var width:float=[0.96,1.0,1.04][index%3]
	var x_scale:=width*(-1.0 if index%2==1 else 1.0)
	model.scale.x=x_scale
	for entry:Dictionary in (info.get("marks",{}) as Dictionary).values():
		for field:String in ["pos","seat_exit","seat_approach"]:
			if entry.get(field) is Array:(entry[field] as Array)[0]=float(entry[field][0])*x_scale
		if entry.get("face") is Array:(entry.face as Array)[0]=float(entry.face[0])*x_scale
	var fx:Dictionary=info.get("fx",{})
	for field:String in ["fire","dust"]:
		if fx.get(field) is Dictionary and (fx[field] as Dictionary).has("pos"):
			(fx[field].pos as Array)[0]=float(fx[field].pos[0])*x_scale
	for field:String in ["flames","shafts"]:
		for entry:Dictionary in fx.get(field,[]):
			for point:String in ["pos","top","dir"]:
				if entry.has(point):(entry[point] as Array)[0]=float(entry[point][0])*x_scale
	for point:Array in fx.get("fill",[]):point[0]=float(point[0])*x_scale
	if fx.has("door_light"):(fx.door_light as Array)[0]=float(fx.door_light[0])*x_scale

func _dress(root:Node)->void:
	var ink_prefixes:Array=info.get("ink",[])
	var shadow_only:Array=info.get("shadow_only",[])
	for node in root.find_children("*","MeshInstance3D",true,false):
		var mesh_node:=node as MeshInstance3D
		var part:=String(mesh_node.name)
		if part in shadow_only:
			mesh_node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
			continue
		var inked:=false
		for prefix:String in ink_prefixes:
			if part.begins_with(prefix):inked=true;break
		var far:=part.begins_with("Far")
		mesh_node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if far or part in ["Ground","Grass","Debris","Floor","Carpet","Mats"] else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		if mesh_node.mesh==null:continue
		for surface in mesh_node.mesh.get_surface_count():
			var source:=mesh_node.mesh.surface_get_material(surface)
			var slot:=source.resource_name if source!=null else "WOOD"
			if part=="Ground":
				mesh_node.set_surface_override_material(surface,_ground_material())
			elif far:
				mesh_node.set_surface_override_material(surface,_wash_material(int(part.trim_prefix("Far"))))
			else:
				var made_mat:=_material(slot,inked)
				mesh_node.set_surface_override_material(surface,made_mat)
				_dressing.append([mesh_node,surface,slot,inked,part])
				if slot in ["HIDE","HIDE_DARK","HIDE_PALE"] and not made_mat in _gust_mats:_gust_mats.append(made_mat)

func _colour(code:String,fallback:Color)->Color:
	if code.is_empty():return fallback
	if code.begins_with("dye"):return Color(String(_dyes[clampi(int(code.trim_prefix("dye")),0,_dyes.size()-1)]))
	return Color(code)

func _material(slot:String,inked:bool)->ShaderMaterial:
	inked=inked and ink_mode=="hull"
	var key:="%s|%s|%s|%s" % [kind,slot,inked,",".join(PackedStringArray(_dyes))]
	if _materials.has(key):return _materials[key]
	var look:Dictionary=_look()
	var paint:Array=PALETTE.get(slot,["8a7a66","8a7a66"])
	var made:=ShaderMaterial.new();made.shader=TOON
	var base:=_colour(String(paint[0]),Color("8a7a66"))
	var worn:=_colour(String(paint[1]),base)
	made.set_shader_parameter("albedo",base)
	made.set_shader_parameter("albedo_worn",worn)
	if paint.size()>2:made.set_shader_parameter("accent_a",_colour(String(paint[2]),base.darkened(0.3)))
	if paint.size()>3:made.set_shader_parameter("accent_b",_colour(String(paint[3]),base.lightened(0.3)))
	made.set_shader_parameter("haze_color",_air())
	if PATTERN.has(slot):
		var p:Array=PATTERN[slot]
		made.set_shader_parameter("pattern",int(p[0]));made.set_shader_parameter("motif",int(p[1]));made.set_shader_parameter("pattern_scale",float(p[2]))
	match slot:
		"EMBER":
			made.set_shader_parameter("emission_amount",2.4);made.set_shader_parameter("emission_flicker",0.6)
		"CHAR":
			made.set_shader_parameter("emission_amount",2.2);made.set_shader_parameter("emission_flicker",0.5)
		"MELT":
			made.set_shader_parameter("emission_amount",3.2);made.set_shader_parameter("emission_flicker",0.35)
		"IRON":
			made.set_shader_parameter("rim_amount",0.3)
		"GRASS","LEAF":
			made.set_shader_parameter("wrap",0.35);made.set_shader_parameter("mottle",0.18);made.set_shader_parameter("variation",0.2)
			made.set_shader_parameter("haze_max",0.55);made.set_shader_parameter("haze_start",14.0);made.set_shader_parameter("haze_end",60.0)
		"HIDE","HIDE_DARK","HIDE_PALE","BLANKET":
			made.set_shader_parameter("wrap",0.2);made.set_shader_parameter("mottle",0.12);made.set_shader_parameter("variation",0.22)
		"THATCH","MUD","PLANK","PLASTER":
			made.set_shader_parameter("mottle",0.12)
		"WEAVE_A","WEAVE_B","WEAVE_C","CARPET":
			made.set_shader_parameter("wrap",0.25);made.set_shader_parameter("mottle",0.05);made.set_shader_parameter("variation",0.04)
		"GOLD","BRONZE":
			made.set_shader_parameter("rim_amount",0.35)
		"BRONZE_CAST":
			# the statue gleams: a hard rim of light, a little glow of its own
			made.set_shader_parameter("rim_amount",0.7);made.set_shader_parameter("emission_amount",0.12)
	# A finish belongs to its material. Glazed windows and metal no longer
	# receive the same chalk-matte response as plaster, paper and rough stone.
	if slot in ["WINDOW_GLASS","GLASS"]:
		made.set_shader_parameter("glazing",.42 if slot=="WINDOW_GLASS" else .18)
		made.set_shader_parameter("sheen_amount",.22)
		made.set_shader_parameter("sheen_power",72.0)
	elif slot in ["IRON","METAL","BRONZE","GOLD","BRONZE_CAST"]:
		made.set_shader_parameter("sheen_amount",.28)
		made.set_shader_parameter("sheen_power",40.0)
	elif slot=="CERAMIC":
		made.set_shader_parameter("sheen_amount",.12)
		made.set_shader_parameter("sheen_power",48.0)
	if slot in ["BARK","WOOD","STONE","HIDE","HIDE_DARK","REED","CLAY","PLANK","THATCH"]:
		made.set_shader_parameter("haze_max",0.45);made.set_shader_parameter("haze_start",22.0);made.set_shader_parameter("haze_end",80.0)
	# Authored chapter finishes keep offices maintained and their upholstery
	# restrained while older halls retain their weathering and woven borders.
	var finish:Dictionary=(info.get("material_overrides",{}) as Dictionary).get(slot,{})
	for parameter:String in finish:
		var value:Variant=finish[parameter]
		if parameter in ["albedo","albedo_worn","accent_a","accent_b"]:value=_colour(String(value),base)
		made.set_shader_parameter(parameter,value)
	if inked:made.next_pass=_ink()
	_materials[key]=made
	return made

static func _ink()->ShaderMaterial:
	if _ink_material==null:
		_ink_material=ShaderMaterial.new();_ink_material.shader=INK
	return _ink_material

func _wash_material(layer:int)->ShaderMaterial:
	var key:="%s|FAR%d" % [kind,layer]
	if _materials.has(key):return _materials[key]
	var look:Dictionary=_look()
	var spec:Array=(look.get("far",[]) as Array)[clampi(layer,0,2)] if (look.get("far",[]) as Array).size()>2 else ["6f7c66","4a5446",0.3]
	var made:=ShaderMaterial.new();made.shader=WASH
	made.set_shader_parameter("wash",Color(String(spec[0])))
	made.set_shader_parameter("ink",Color(String(spec[1])))
	made.set_shader_parameter("airiness",float(spec[2]))
	made.set_shader_parameter("air",_air())
	made.set_shader_parameter("foot_from",[2.5,5.0,9.0][clampi(layer,0,2)])
	made.set_shader_parameter("foot_to",[7.5,15.0,26.0][clampi(layer,0,2)])
	made.set_shader_parameter("ink_width",[0.22,0.45,0.9][clampi(layer,0,2)])
	made.set_shader_parameter("ink_amount",[0.7,0.5,0.32][clampi(layer,0,2)])
	made.set_shader_parameter("bleed",[2.0,4.5,9.0][clampi(layer,0,2)])
	made.set_shader_parameter("trunks",0.3 if layer==0 else 0.0)
	made.render_priority=-1-layer
	_materials[key]=made
	return made

func _ground_material()->ShaderMaterial:
	var key:="%s|GROUND" % kind
	if _materials.has(key):return _materials[key]
	var look:Dictionary=_look()
	var made:=ShaderMaterial.new();made.shader=GROUND
	made.set_shader_parameter("grass",Color(String(look.grass)))
	made.set_shader_parameter("grass_dry",Color(String(look.grass_dry)))
	made.set_shader_parameter("earth",Color(String(look.earth)))
	made.set_shader_parameter("earth_dark",Color(String(look.earth_dark)))
	made.set_shader_parameter("straw",float(look.straw))
	made.set_shader_parameter("haze_color",_air())
	made.set_shader_parameter("haze_start",24.0)
	made.set_shader_parameter("haze_end",60.0)
	made.set_shader_parameter("haze_max",0.85)
	made.set_shader_parameter("hearth_radius",(0.95 if kind!="longhouse" else 1.0) if has_hearth() else 0.0)
	made.set_shader_parameter("hearth_scale",Vector2(2.1,0.75) if kind=="longhouse" else Vector2(1.0,1.0))
	_materials[key]=made
	return made

# --- Marks --------------------------------------------------------------------------

func _make_marks()->void:
	var holder:=Node3D.new();holder.name="Marks";add_child(holder)
	var raw:Dictionary=info.get("marks",{})
	var throne:=_vec((raw.get("throne_gaze",{}) as Dictionary).get("pos",[0,2,6]))
	var fire:=_vec((raw.get("fire",raw.get("focus",{})) as Dictionary).get("pos",[0,0,0]))
	var focus:=_vec((raw.get("focus",raw.get("petitioner",{})) as Dictionary).get("pos",[0,0,0]))
	var names:Array=raw.keys();names.sort()
	for mark_name:String in names:
		var entry:Dictionary=raw[mark_name]
		var at:=_vec(entry.get("pos",[0,0,0]))
		var target:=throne
		var face:Variant=entry.get("face","throne")
		if face is String:
			match String(face):
				"fire":target=fire
				"focus":target=focus
				"door":target=_vec((raw.get("door",{}) as Dictionary).get("pos",[0,0,0]))
				_:target=throne
		elif face is Array and (face as Array).size()>=2:
			target=Vector3(float(face[0]),0.0,float(face[2] if (face as Array).size()>=3 else face[1]))
		var m:=Marker3D.new();m.name=mark_name
		var dir:=Vector3(target.x-at.x,0.0,target.z-at.z)
		var basis:=Basis.IDENTITY
		# a mark's -Z is the way a person there faces (Godot's own forward)
		if dir.length()>0.01:basis=Basis.looking_at(dir.normalized(),Vector3.UP)
		m.transform=Transform3D(basis,at)
		m.set_meta("sit",bool(entry.get("sit",false)))
		m.set_meta("seat",float(entry.get("seat",0.0)))
		for field:String in ["external_seat","seat_exit","seat_approach"]:
			if entry.has(field):m.set_meta(field,entry[field])
		holder.add_child(m)
		marks[mark_name]=m

static func _vec(a:Variant)->Vector3:
	if a is Array and (a as Array).size()>=3:return Vector3(float(a[0]),float(a[1]),float(a[2]))
	return Vector3.ZERO

func mark(mark_name:String)->Marker3D:
	return marks.get(mark_name) as Marker3D

func has_mark(mark_name:String)->bool:
	return marks.has(mark_name)

## The marks whose names begin with a prefix ("officials_", "crowd_"), in order.
func marks_for(prefix:String)->Array[Marker3D]:
	var names:Array=[]
	for key:String in marks.keys():
		if key.begins_with(prefix):names.append(key)
	names.sort_custom(func(a:String,b:String)->bool:return int(a.get_slice("_",a.get_slice_count("_")-1))<int(b.get_slice("_",b.get_slice_count("_")-1)))
	var out:Array[Marker3D]=[]
	for n:String in names:out.append(marks[n])
	return out

## Stand someone (or something whose front is +Z) on a mark, facing the way
## the mark faces; on a sit mark a figure is raised to the seat.
func place(node:Node3D,mark_name:String)->void:
	var m:=mark(mark_name)
	if m==null or node==null:return
	var turned:=m.global_transform.basis.orthonormalized().rotated(Vector3.UP,PI)
	var at:=m.global_position
	if bool(m.get_meta("sit",false)) and float(m.get_meta("seat",0.0))>0.0 and String(node.get("stance") if node.get("stance")!=null else "")=="sit":
		at.y+=float(m.get_meta("seat",0.0))-0.47*node.global_transform.basis.get_scale().y
	node.global_transform=Transform3D(turned*Basis.from_scale(node.global_transform.basis.get_scale()),at)

## Which mark each of the stage's cast stands on. entries: [{key, role
## ("main", "court", "attendant"), stance}] in the stage's order; layout_kind
## "home" or "envoy". The one before the god takes the petitioner's mark (an
## envoy envoy_0, their company envoy_1..); officials fill officials_* in
## order, those who sit taking the seats among crowd_*; the rest stand in the
## crowd. Returns {key: mark name}; nobody shares a mark.
func assign_marks(entries:Array,layout_kind:="home")->Dictionary:
	var out:={}
	var used:={}
	var officials:Array[Marker3D]=marks_for("officials_")
	var crowd:Array[Marker3D]=marks_for("crowd_")
	var seats:Array[Marker3D]=[]
	var standing:Array[Marker3D]=[]
	for m in crowd:
		if bool(m.get_meta("sit",false)):seats.append(m)
		else:standing.append(m)
	var envoys:=0
	for entry:Dictionary in entries:
		var key:=String(entry.get("key",""))
		var role:=String(entry.get("role","court"))
		var name_out:=""
		if role=="main":
			name_out="envoy_0" if layout_kind=="envoy" else "petitioner"
		elif role=="attendant":
			envoys+=1
			name_out="envoy_%d" % envoys
		if name_out.is_empty() or not marks.has(name_out) or used.has(name_out):
			name_out=""
			var pools:Array=[seats,officials,standing] if String(entry.get("stance",""))=="sit" else [officials,standing,seats]
			if role=="crowd":pools=[seats,standing] if String(entry.get("stance",""))=="sit" else [standing,seats]
			for pool:Array in pools:
				for m:Marker3D in pool:
					if not used.has(String(m.name)):
						name_out=String(m.name);break
				if not name_out.is_empty():break
		if name_out.is_empty():continue
		used[name_out]=true
		out[key]=name_out
	return out

## Where people come in and go out (the door, and beyond it).
func door_points()->Array[Vector3]:
	var a:=mark("door");var b:=mark("door_out")
	return [a.global_position if a!=null else Vector3(-6,0,0.5),b.global_position if b!=null else Vector3(-9,0,0.5)]

## Where the god's presence is (people look up to it).
func god_point()->Vector3:
	var m:=mark("throne_gaze")
	return m.global_position if m!=null else Vector3(0.0,2.3,5.5)

# --- Light and air ------------------------------------------------------------------

func _make_environment()->void:
	var look:Dictionary=_look()
	var light:Dictionary=info.get("light",{})
	var env:=Environment.new()
	var sky:=Sky.new()
	var sky_mat:=ShaderMaterial.new();sky_mat.shader=SKY
	sky_mat.set_shader_parameter("top",Color(String(look.sky_top)))
	sky_mat.set_shader_parameter("horizon",Color(String(look.sky_horizon)))
	sky.sky_material=sky_mat
	sky.radiance_size=Sky.RADIANCE_SIZE_32
	sky.process_mode=Sky.PROCESS_MODE_QUALITY
	env.sky=sky
	env.background_mode=Environment.BG_SKY
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color=Color(String(look.ambient))
	env.ambient_light_energy=float(look.ambient_energy)
	env.reflected_light_source=Environment.REFLECTION_SOURCE_DISABLED
	env.tonemap_mode=Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure=float(look.get("exposure",1.0))
	env.tonemap_white=6.0
	env.glow_enabled=true
	env.glow_intensity=0.4
	env.glow_strength=0.9
	env.glow_bloom=0.0
	env.glow_hdr_threshold=1.25
	env.glow_blend_mode=Environment.GLOW_BLEND_MODE_SOFTLIGHT
	env.fog_enabled=true
	env.fog_mode=Environment.FOG_MODE_EXPONENTIAL
	env.fog_light_color=Color(String(look.fog)) if not bool((info.get("light",{}) as Dictionary).get("open_sky",true)) else _air()
	env.fog_density=float(light.get("fog",look.fog_density))
	env.fog_sky_affect=0.0
	env.fog_sun_scatter=0.0
	env.adjustment_enabled=true
	env.adjustment_saturation=0.94
	env.adjustment_contrast=1.04
	world_env=WorldEnvironment.new();world_env.name="Air";world_env.environment=env
	add_child(world_env)

func _make_lights()->void:
	var look:Dictionary=_look()
	var light:Dictionary=info.get("light",{})
	var fx:Dictionary=info.get("fx",{})
	sun=DirectionalLight3D.new();sun.name="Sun"
	var dir:=_vec(light.get("sun_dir",[-0.45,-0.62,-0.64])).normalized()
	sun.transform=Transform3D(Basis.looking_at(dir,Vector3.UP if absf(dir.y)<0.98 else Vector3.FORWARD),Vector3.ZERO)
	sun.light_color=Color(String(look.sun))
	sun.light_energy=float(light.get("sun_energy",1.3))
	sun.shadow_enabled=true
	sun.directional_shadow_mode=DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sun.directional_shadow_max_distance=30.0
	# The old 3m near split put the wall behind a speaker in the coarse 30m
	# cascade. Give close, room and distant geometry separate shadow texels.
	sun.directional_shadow_split_1=0.12
	sun.directional_shadow_split_2=0.28
	sun.directional_shadow_split_3=0.52
	sun.directional_shadow_blend_splits=false
	sun.shadow_bias=0.04
	sun.shadow_normal_bias=1.2
	sun.shadow_blur=1.4
	# Compatibility expands the shadow frustum for angular size but cannot
	# apply PCSS. Avoid wasting its texels on an unsupported soft-shadow halo.
	sun.light_angular_distance=0.0 if RenderingServer.get_current_rendering_method()=="gl_compatibility" else 1.2
	add_child(sun)
	var fire:Dictionary=fx.get("fire",{})
	_fire_energy=float(light.get("fire_energy",1.3)) if has_hearth() else 0.0
	if has_hearth():
		_fire_at=_vec(fire.get("pos",[0,0,0]))+Vector3(0.0,0.85,0.0)
		fire_light=_omni("Fire",Color(1.0,0.58,0.30),_fire_energy,float(light.get("fire_range",7.0)),1.5)
		fire_light.position=_fire_at
		bounce=_omni("Bounce",Color(1.0,0.72,0.48),0.45,4.8,1.0)
		bounce.position=_vec(fire.get("pos",[0,0,0]))+Vector3(0.0,0.12,0.9)
	for spot:Dictionary in fx.get("flames",[]):
		var size:=float(spot.get("size",0.4))
		var small:=size<0.2
		var lamp:=_omni("Brazier",Color(1.0,0.6,0.32),float(light.get("brazier_energy",_fire_energy*0.6))*(0.35 if small else 1.0),float(light.get("brazier_range",4.5))*(0.5 if small else 1.0),1.4)
		lamp.position=_vec(spot.get("pos",[0,1,0]))+Vector3(0.0,0.3 if not small else 0.12,0.0)
		flame_lights.append(lamp)
		_flame_energies.append(lamp.light_energy)
	# soft warm fills where a hall's back would fall into darkness
	for spec:Array in fx.get("fill",[]):
		var fill:=_omni("Fill",Color(String(light.get("fill_colour","c9d2d4" if not has_hearth() else "ffc78c"))),float(spec[3]),float(spec[4]),0.8)
		fill.position=Vector3(float(spec[0]),float(spec[1]),float(spec[2]))
		fill_lights.append(fill)
	if kind.begins_with("chapter_") and indoors():
		# Light returned from the unseen front of an enclosed room keeps faces
		# readable against rear windows. One broad, diffuse-only bounce keeps
		# the window shadows and distant wall contrast intact.
		var returned:=_omni("RoomReturn",Color("e4ded1"),.90,10.5,0.8)
		returned.position=Vector3(1.6,2.6,4.2)
		fill_lights.append(returned)
	if fx.has("door_light"):
		door_light=SpotLight3D.new();door_light.name="DoorLight"
		var at:=_vec(fx.door_light)
		door_light.transform=Transform3D(Basis.looking_at(Vector3(1.0,-0.25,0.05).normalized(),Vector3.UP),at)
		door_light.light_color=Color(0.93,0.95,1.0);door_light.light_energy=3.2
		door_light.spot_range=9.0;door_light.spot_angle=52.0;door_light.spot_attenuation=1.1
		door_light.light_specular=0.0
		add_child(door_light)

func _omni(light_name:String,colour:Color,energy:float,reach:float,falloff:float)->OmniLight3D:
	var made:=OmniLight3D.new();made.name=light_name
	made.light_color=colour;made.light_energy=energy;made.omni_range=reach;made.omni_attenuation=falloff
	made.light_specular=0.0;made.shadow_enabled=false
	add_child(made)
	return made

## The hearth fire: two layers of tongues and a hot heart, the air shaking
## above it, smoke and sparks; and the small flames of braziers and lamps.
func _make_fires()->void:
	var fx:Dictionary=info.get("fx",{})
	if has_hearth():
		var fire:Dictionary=fx.get("fire",{})
		var at:=_vec(fire.get("pos",[0,0.05,0]))
		var size:=float(fire.get("size",1.0))
		var holder:=_flame(at,size,"Fire",3)
		shimmer=MeshInstance3D.new();shimmer.name="HeatShimmer"
		var quad:=QuadMesh.new();quad.size=Vector2(1.0,1.0);shimmer.mesh=quad
		var smat:=ShaderMaterial.new();smat.shader=SHIMMER;smat.render_priority=-2
		shimmer.material_override=smat
		shimmer.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		shimmer.scale=Vector3(0.9*size,1.6*size,1.0)
		shimmer.position=Vector3(0.0,1.35*size,0.0)
		holder.add_child(shimmer)
		if bool(fx.get("smoke",true)):
			var top:=float(fx.get("smoke_top",8.0))-at.y
			var smoke:=GPUParticles3D.new();smoke.name="Smoke"
			smoke.amount=26;smoke.lifetime=7.0 if top>6.0 else 4.5;smoke.preprocess=6.0;smoke.randomness=0.4
			var sm:=ParticleProcessMaterial.new()
			sm.emission_shape=ParticleProcessMaterial.EMISSION_SHAPE_BOX
			sm.emission_box_extents=Vector3(0.25*size,0.1,0.18)
			sm.direction=Vector3(0,1,0);sm.spread=10.0
			sm.initial_velocity_min=0.35;sm.initial_velocity_max=0.6
			sm.gravity=Vector3(0.06,0.10,-0.04)
			sm.damping_min=0.05;sm.damping_max=0.15
			sm.scale_min=0.55;sm.scale_max=0.9
			var curve:=Curve.new();curve.add_point(Vector2(0.0,0.35));curve.add_point(Vector2(1.0,2.6))
			var curve_tex:=CurveTexture.new();curve_tex.curve=curve;sm.scale_curve=curve_tex
			var ramp:=Gradient.new()
			ramp.set_offset(0,0.0);ramp.set_color(0,Color(1,1,1,0.0))
			ramp.set_offset(1,1.0);ramp.set_color(1,Color(1,1,1,0.0))
			ramp.add_point(0.12,Color(1,1,1,1.0));ramp.add_point(0.6,Color(1,1,1,0.65))
			var ramp_tex:=GradientTexture1D.new();ramp_tex.gradient=ramp;sm.color_ramp=ramp_tex
			var seeds:=Gradient.new();seeds.set_color(0,Color(1,1,0,1));seeds.set_color(1,Color(1,1,1,1))
			var seeds_tex:=GradientTexture1D.new();seeds_tex.gradient=seeds;sm.color_initial_ramp=seeds_tex
			sm.turbulence_enabled=true;sm.turbulence_noise_strength=0.35;sm.turbulence_noise_scale=3.0;sm.turbulence_noise_speed_random=0.2
			smoke.process_material=sm
			_smoke_pm=sm;_smoke_gravity=sm.gravity
			var puff:=QuadMesh.new();puff.size=Vector2(1.0,1.0)
			var smoke_mat:=ShaderMaterial.new();smoke_mat.shader=SMOKE
			smoke_mat.set_shader_parameter("fire_y",at.y)
			smoke_mat.set_shader_parameter("opacity",0.18)
			puff.material=smoke_mat
			smoke.draw_pass_1=puff
			smoke.position=Vector3(0,0.9*size,0)
			smoke.visibility_aabb=AABB(Vector3(-4,-1,-4),Vector3(8,maxf(top,4.0)+2.0,8))
			smoke.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			holder.add_child(smoke);particles.append(smoke)
			var sparks:=GPUParticles3D.new();sparks.name="Embers"
			sparks.amount=18;sparks.lifetime=2.4;sparks.preprocess=3.0;sparks.randomness=0.6
			var em:=ParticleProcessMaterial.new()
			em.emission_shape=ParticleProcessMaterial.EMISSION_SHAPE_BOX
			em.emission_box_extents=Vector3(0.25,0.05,0.2)
			em.direction=Vector3(0,1,0);em.spread=22.0
			em.initial_velocity_min=0.6;em.initial_velocity_max=1.4
			em.gravity=Vector3(0.0,0.25,0.0)
			em.damping_min=0.2;em.damping_max=0.6
			em.scale_min=0.6;em.scale_max=1.2
			var life:=Gradient.new();life.set_color(0,Color(1,1,1,1));life.set_color(1,Color(1,1,1,0))
			var life_tex:=GradientTexture1D.new();life_tex.gradient=life;em.color_ramp=life_tex
			em.turbulence_enabled=true;em.turbulence_noise_strength=1.2;em.turbulence_noise_scale=1.6
			sparks.process_material=em
			var spark:=QuadMesh.new();spark.size=Vector2(0.035,0.035)
			var spark_mat:=ShaderMaterial.new();spark_mat.shader=EMBER;spark.material=spark_mat
			sparks.draw_pass_1=spark
			sparks.position=Vector3(0,0.35,0)
			sparks.visibility_aabb=AABB(Vector3(-3,-1,-3),Vector3(6,8,6))
			sparks.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			holder.add_child(sparks);particles.append(sparks)
	var index:=0
	for spot:Dictionary in fx.get("flames",[]):
		var p:=_vec(spot.get("pos",[0,1,0]))
		_flame(p,float(spot.get("size",0.4)),"Flame%d" % index,2)
		_flame_at.append(p)
		index+=1

func _flame(at:Vector3,size:float,flame_name:String,cards:int)->Node3D:
	var holder:=Node3D.new();holder.name=flame_name;add_child(holder);holder.position=at
	for k in cards:
		var card:=MeshInstance3D.new();card.name="Tongues%d" % k
		var quad:=QuadMesh.new();quad.size=Vector2(1.0,1.0);card.mesh=quad
		var mat:=ShaderMaterial.new();mat.shader=FLAME;mat.render_priority=1
		mat.set_shader_parameter("seed",float(k)*2.37+at.x)
		mat.set_shader_parameter("speed",0.85+0.2*k)
		mat.set_shader_parameter("strength",[1.0,0.7,0.9][k%3])
		mat.set_shader_parameter("tongues",[5,4,2][k%3])
		_flame_mats.append(mat)
		card.material_override=mat
		card.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var h:float=float([1.25,1.05,0.6][k%3])*size
		var w:float=float([0.95,1.15,0.45][k%3])*size
		card.scale=Vector3(w,h,1.0)
		card.position=Vector3([0.0,0.05,-0.02][k%3]*size,h*0.5-0.02,[0.0,-0.12,0.08][k%3]*size)
		holder.add_child(card)
	return holder

## Dust in the light, and in a hall the sun's shafts through the openings.
func _make_air()->void:
	var fx:Dictionary=info.get("fx",{})
	var light:Dictionary=info.get("light",{})
	var sun_dir:=_vec(light.get("sun_dir",[0,-1,0])).normalized()
	var first:=true
	for spec:Dictionary in fx.get("shafts",[]):
		var top:=_vec(spec.get("top",[0,5,0]))
		var dir:=_vec(spec.get("dir",[sun_dir.x,sun_dir.y,sun_dir.z])).normalized()
		var radius:=float(spec.get("radius",0.6))
		var length:=(top.y-0.0)/maxf(0.2,-dir.y)
		var shaft:=MeshInstance3D.new();shaft.name="SunShaft"
		var cyl:=CylinderMesh.new();cyl.top_radius=radius*0.9;cyl.bottom_radius=radius*1.15;cyl.height=1.0
		cyl.radial_segments=20;cyl.rings=1;cyl.cap_top=false;cyl.cap_bottom=false
		shaft.mesh=cyl
		var mat:=ShaderMaterial.new();mat.shader=SHAFT
		mat.set_shader_parameter("strength",float(spec.get("strength",0.22)))
		_sun_shaft_mats.append(mat);_sun_shaft_strength.append(float(spec.get("strength",0.22)))
		mat.set_shader_parameter("soft",float(spec.get("soft",0.0)))
		shaft.material_override=mat
		shaft.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var y_axis:=-dir
		var x_axis:=y_axis.cross(Vector3.FORWARD if absf(y_axis.z)<0.9 else Vector3.RIGHT).normalized()
		var z_axis:=x_axis.cross(y_axis).normalized()
		shaft.transform=Transform3D(Basis(x_axis,y_axis*length,z_axis),top+dir*length*0.5)
		add_child(shaft)
		if first:
			_shaft_top=top;_shaft_dir=dir;_shaft_radius=radius;first=false
	if indoors() and not (info.get("apertures",[]) as Array).is_empty():
		_window_daylight=Daylight.build(info.apertures,sun_dir,Color(String(_look().sun)),float(light.get("daylight_strength",0.0)),float(light.get("aperture_z",-3.78)),model.scale.x if model!=null else 1.0)
		for ray in _window_daylight:
			add_child(ray)
			var ray_material:=ray.material_override as ShaderMaterial
			_sun_shaft_mats.append(ray_material)
			_sun_shaft_strength.append(float(ray_material.get_shader_parameter("strength")))
	var dust:Dictionary=fx.get("dust",{})
	if dust.is_empty():return
	var motes:=GPUParticles3D.new();motes.name="Dust"
	motes.amount=60;motes.lifetime=14.0;motes.preprocess=14.0;motes.randomness=0.5
	var pm:=ParticleProcessMaterial.new()
	pm.emission_shape=ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents=_vec(dust.get("extent",[4,1.4,3]))
	pm.direction=Vector3(0.3,0.2,0.1);pm.spread=180.0
	pm.initial_velocity_min=0.01;pm.initial_velocity_max=0.05
	pm.gravity=Vector3(0.0,-0.004,0.0)
	pm.scale_min=0.6;pm.scale_max=1.3
	var ramp:=Gradient.new()
	ramp.set_color(0,Color(1,1,1,0));ramp.set_color(1,Color(1,1,1,0))
	ramp.add_point(0.2,Color(1,1,1,1));ramp.add_point(0.8,Color(1,1,1,1))
	var ramp_tex:=GradientTexture1D.new();ramp_tex.gradient=ramp;pm.color_ramp=ramp_tex
	pm.turbulence_enabled=true;pm.turbulence_noise_strength=0.25;pm.turbulence_noise_scale=4.0;pm.turbulence_noise_speed=Vector3(0.02,0.01,0.0)
	motes.process_material=pm
	var dot:=QuadMesh.new();dot.size=Vector2(0.016,0.016)
	var mat2:=ShaderMaterial.new();mat2.shader=MOTE
	mat2.set_shader_parameter("brightness",0.9 if _shaft_radius>0.0 else 0.35)
	mat2.set_shader_parameter("shaft_top",_shaft_top);mat2.set_shader_parameter("shaft_dir",_shaft_dir)
	mat2.set_shader_parameter("shaft_radius",_shaft_radius)
	dot.material=mat2
	motes.draw_pass_1=dot
	motes.position=_vec(dust.get("pos",[0,1.4,1]))
	motes.visibility_aabb=AABB(Vector3(-6,-3,-5),Vector3(12,6,10))
	motes.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(motes);particles.append(motes)

## The paper the court is painted on: a soft vignette and a fixed grain,
## laid over the view nearest the lens (one quad, drawn last).
func _make_paper()->void:
	var quad:=MeshInstance3D.new();quad.name="Paper"
	var mesh:=QuadMesh.new();mesh.size=Vector2(1.0,1.0);quad.mesh=mesh
	var mat:=ShaderMaterial.new();mat.shader=PAPER;mat.render_priority=100
	quad.material_override=mat
	quad.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	quad.extra_cull_margin=16384.0
	quad.position=Vector3(0.0,0.0,-0.5)
	camera.add_child(quad)
	if ink_mode=="screen":_make_ink()

## The colour of the air at the horizon: the sky's own, so the land, the
## far woods and the fog all fade into the same haze.
func _air()->Color:
	var look:Dictionary=_look()
	return Color(String(look.get("sky_horizon","e2ddcb"))).lerp(Color(String(look.get("haze","b9c0bd"))),0.25)

## The ink line, once over the whole stage (court_ink_post.gdshader).
func _make_ink()->void:
	ink_pass=MeshInstance3D.new();ink_pass.name="Ink"
	var mesh:=QuadMesh.new();mesh.size=Vector2(1.0,1.0);ink_pass.mesh=mesh
	var mat:=ShaderMaterial.new();mat.shader=INK_POST;mat.render_priority=90
	ink_pass.material_override=mat
	ink_pass.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ink_pass.extra_cull_margin=16384.0
	ink_pass.position=Vector3(0.0,0.0,-0.5)
	camera.add_child(ink_pass)

## Whether the stage's figures should go without their own inked shells.
static func uses_screen_ink()->bool:
	return ink!="hull"

# --- Props from the facts -----------------------------------------------------------

func _collect_props(root:Node)->void:
	var groups:Dictionary=info.get("props",{})
	for group:String in ["food","rack","spears"]:
		var list:Array[Node3D]=[]
		for prop_name:String in groups.get(group,[]):
			var found:=root.find_child(prop_name,true,false) as Node3D
			if found!=null:list.append(found)
		props[group]=list
	var raw_gates:Dictionary=info.get("gates",{})
	for key:String in raw_gates.keys():
		var list2:Array[Node3D]=[]
		for prop_name:String in raw_gates[key]:
			var found2:=root.find_child(prop_name,true,false) as Node3D
			if found2!=null:list2.append(found2)
		gates[key]=list2
	for definition:Array in [["technology_gates",technology_gates],["institution_gates",institution_gates]]:
		var groups_in:Dictionary=info.get(String(definition[0]),{})
		var collected:Dictionary=definition[1]
		for key:String in groups_in:
			var nodes:Array[Node3D]=[]
			for part:String in groups_in[key]:
				var found:=root.find_child(part,true,false) as Node3D
				if found!=null:nodes.append(found)
			collected[key]=nodes

## Dress the set from the facts: the stores' food in the baskets, on the rack
## and the board; the spears racked (a few in peace, all in war); the things
## the people know how to make (era tags), and nothing they do not.
func apply_facts(facts_in:Dictionary)->void:
	var fresh:=normal_facts(facts_in)
	for key in fresh.keys():facts[key]=fresh[key]
	var food:=clampf(float(facts.get("food",0.6)),0.0,1.0)
	var war:=clampf(float(facts.get("war",0.0)),0.0,1.0)
	_show_first(props.get("food",[]),roundi(food*float((props.get("food",[]) as Array).size())))
	_show_first(props.get("rack",[]),roundi(clampf(food*1.25-0.1,0.0,1.0)*float((props.get("rack",[]) as Array).size())))
	var spears:Array=props.get("spears",[])
	var peace:=int((info.get("props",{}) as Dictionary).get("spears_peace",3))
	_show_first(spears,mini(spears.size(),peace+roundi(war*float(maxi(0,spears.size()-peace)))))
	_apply_season(String(facts.get("season","")).to_lower())
	_apply_trophies()
	var tags:Array=facts.get("era_tags",info.get("default_tags",[])) as Array
	for key:String in gates.keys():
		var without:=key.begins_with("no_")
		var tag:=key.trim_prefix("no_")
		var show:=tags.has(tag)!=without
		for node in gates[key]:
			if is_instance_valid(node):(node as Node3D).visible=show
	var chapter:Dictionary=facts.get("chapter",{})
	var capabilities:Dictionary=chapter.get("capabilities",{})
	for key:String in technology_gates:
		var without:=key.begins_with("no_")
		var show:=bool(capabilities.get(key.trim_prefix("no_"),false))!=without
		for node:Node3D in technology_gates[key]:node.visible=show
	var lean:=String(chapter.get("lean","throne"))
	for key:String in institution_gates:
		for node:Node3D in institution_gates[key]:node.visible=key==lean
	if not bool(facts.get("rustic_props",true)):
		for group in ["food","rack","spears"]:_show_first(props.get(group,[]),0)

# --- The season -------------------------------------------------------------------

## Flies over the food and the meat rack, snow falling (open sky only); both
## made once and switched with the season.
func _make_season_fx()->void:
	var spots:Array[Vector3]=[]
	for group in ["rack","food"]:
		var list:Array=[] if indoors() else props.get(group,[])
		if list.is_empty():continue
		var centre:=Vector3.ZERO
		for node in list:centre+=_centre_of(node as Node3D)
		spots.append(centre/float(list.size()))
	_rack_at=spots[0] if not spots.is_empty() else Vector3(0.0,1.0,-3.0)
	for at in spots:
		var swarm:=GPUParticles3D.new();swarm.name="Flies"
		# short, darting lives about the meat: each fly a little dark streak
		# along its flight, so they read as moving, not as dust
		swarm.amount=8;swarm.lifetime=1.6;swarm.preprocess=2.0;swarm.randomness=0.6
		var pm:=ParticleProcessMaterial.new()
		pm.emission_shape=ParticleProcessMaterial.EMISSION_SHAPE_SPHERE;pm.emission_sphere_radius=0.3
		pm.direction=Vector3(0,0.2,1);pm.spread=180.0
		pm.initial_velocity_min=0.9;pm.initial_velocity_max=1.6
		pm.gravity=Vector3.ZERO;pm.damping_min=0.3;pm.damping_max=0.8
		pm.turbulence_enabled=true;pm.turbulence_noise_strength=9.0;pm.turbulence_noise_scale=0.35;pm.turbulence_noise_speed=Vector3(1.2,1.0,1.2)
		pm.turbulence_influence_min=0.7;pm.turbulence_influence_max=1.0
		pm.particle_flag_align_y=true
		var size:=Curve.new();size.add_point(Vector2(0.0,0.0));size.add_point(Vector2(0.12,1.0));size.add_point(Vector2(0.88,1.0));size.add_point(Vector2(1.0,0.0))
		var size_tex:=CurveTexture.new();size_tex.curve=size;pm.scale_curve=size_tex
		swarm.process_material=pm
		var body:=CapsuleMesh.new();body.radius=0.006;body.height=0.034;body.radial_segments=4;body.rings=1
		var mat:=StandardMaterial3D.new();mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color=Color(0.06,0.05,0.045)
		body.material=mat
		swarm.draw_pass_1=body
		swarm.position=at+Vector3(0.0,0.35,0.0)
		swarm.visibility_aabb=AABB(Vector3(-2,-1,-2),Vector3(4,3,4))
		swarm.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		swarm.emitting=false;swarm.visible=false
		add_child(swarm);flies.append(swarm)
	if bool((info.get("light",{}) as Dictionary).get("open_sky",true)):
		snowfall=GPUParticles3D.new();snowfall.name="Snowfall"
		snowfall.amount=140;snowfall.lifetime=9.0;snowfall.preprocess=9.0;snowfall.randomness=0.4
		var sm:=ParticleProcessMaterial.new()
		sm.emission_shape=ParticleProcessMaterial.EMISSION_SHAPE_BOX;sm.emission_box_extents=Vector3(9.0,0.5,7.0)
		sm.direction=Vector3(0.1,-1,0.05);sm.spread=12.0
		sm.initial_velocity_min=0.5;sm.initial_velocity_max=0.9
		sm.gravity=Vector3(0.05,-0.15,0.0)
		sm.turbulence_enabled=true;sm.turbulence_noise_strength=0.5;sm.turbulence_noise_scale=2.0
		sm.scale_min=0.6;sm.scale_max=1.3
		snowfall.process_material=sm
		var flake:=QuadMesh.new();flake.size=Vector2(0.03,0.03)
		var fmat:=ShaderMaterial.new();fmat.shader=MOTE
		fmat.set_shader_parameter("colour",Color(0.95,0.96,1.0));fmat.set_shader_parameter("brightness",0.55)
		flake.material=fmat
		snowfall.draw_pass_1=flake
		snowfall.position=Vector3(0.0,7.5,0.0)
		snowfall.visibility_aabb=AABB(Vector3(-10,-9,-8),Vector3(20,10,16))
		snowfall.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		snowfall.emitting=false;snowfall.visible=false
		add_child(snowfall)

## Where a piece of the set is, in the set's own space (it may not be in the tree yet).
func _centre_of(node:Node3D)->Vector3:
	var mesh_node:=node as MeshInstance3D
	if mesh_node==null or mesh_node.mesh==null:
		for child in node.find_children("*","MeshInstance3D",true,false):
			if (child as MeshInstance3D).mesh!=null:mesh_node=child as MeshInstance3D;break
	if mesh_node==null:return _to_set(node)*Vector3.ZERO
	return _to_set(mesh_node)*mesh_node.get_aabb().get_center()

func _to_set(node:Node3D)->Transform3D:
	var xf:=Transform3D.IDENTITY
	var at:Node=node
	while at!=null and at!=self:
		if at is Node3D:xf=(at as Node3D).transform*xf
		at=at.get_parent()
	return xf

## The season in the set's materials and air.
func _apply_season(name_in:String)->void:
	if not name_in in SEASONS:name_in=""
	season=name_in
	var open:=bool((info.get("light",{}) as Dictionary).get("open_sky",true))
	var snow:=1.0 if season=="winter" else 0.0
	var dry:=1.0 if season=="summer" else 0.0
	var ground:=_ground_material()
	ground.set_shader_parameter("snow",snow*(1.0 if open else 0.0))
	ground.set_shader_parameter("dry",dry)
	ground.set_shader_parameter("leaves",1.0 if season=="autumn" and open else 0.0)
	ground.set_shader_parameter("flowers",1.0 if season=="spring" and open else 0.0)
	for entry:Array in _dressing:
		var mat:=(entry[0] as MeshInstance3D).get_surface_override_material(int(entry[1])) as ShaderMaterial
		if mat==null:continue
		var outdoor:=open or String(entry[4]) in ["Grass","Trees","Shrubs","Stones"]
		mat.set_shader_parameter("snow",snow*(1.0 if outdoor else 0.0))
		mat.set_shader_parameter("fire_pos",_fire_at)
		mat.set_shader_parameter("dry",dry*0.6 if String(entry[2]) in ["GRASS","LEAF","THATCH","REED"] else 0.0)
	for layer in 3:
		var wash:=_wash_material(layer)
		wash.set_shader_parameter("snow",snow)
	# flies about the meat in summer; a cloud of them when the stores are so
	# full the meat is spoiling; a few in a mild autumn with full stores
	var food:=clampf(float(facts.get("food",0.6)),0.0,1.0)
	var count:=0
	if season=="summer":count=22 if food>0.8 else (12 if food>0.5 else 6)
	elif season=="autumn" and food>0.9:count=5
	if indoors() or not bool(facts.get("rustic_props",true)):count=0
	for i in flies.size():
		var swarm:=flies[i]
		var want:=count if i==0 else count/2
		swarm.visible=want>0
		if want>0 and swarm.amount!=want:swarm.amount=want
		swarm.emitting=swarm.visible and active
	if snowfall!=null:
		snowfall.visible=season=="winter" and level=="high";snowfall.emitting=snowfall.visible and active
	for puff in breaths:
		if is_instance_valid(puff):puff.visible=season=="winter" and not indoors();puff.emitting=puff.visible and active
	if world_env!=null:
		var env:=world_env.environment
		env.adjustment_saturation=0.94-0.12*snow+0.04*dry

## Breath on a cold day: a small puff from someone's mouth every few breaths.
## Give it a figure (anything with a "head" bone) or a node to ride; it only
## shows in winter. Returns the emitter (or null on low quality).
func add_breath(body:Node3D)->GPUParticles3D:
	if indoors() or body==null or not is_instance_valid(body):return null
	var parent:Node3D=body
	var skeletons:=body.find_children("*","Skeleton3D",true,false)
	var offset:=Vector3(0.0,0.0,0.11)
	if not skeletons.is_empty():
		var skel:=skeletons[0] as Skeleton3D
		var head:=skel.find_bone("head")
		if head>=0:
			var attach:=BoneAttachment3D.new();attach.name="BreathAt";attach.bone_name="head"
			skel.add_child(attach)
			parent=attach
			offset=Vector3(0.0,0.07,0.1)
	var puff:=GPUParticles3D.new();puff.name="Breath"
	puff.amount=4;puff.lifetime=1.6;puff.explosiveness=0.7;puff.randomness=0.5
	puff.local_coords=false
	var pm:=ParticleProcessMaterial.new()
	pm.direction=Vector3(0,0.3,1);pm.spread=18.0
	pm.initial_velocity_min=0.18;pm.initial_velocity_max=0.3
	pm.gravity=Vector3(0.0,0.05,0.0);pm.damping_min=0.2;pm.damping_max=0.4
	pm.scale_min=0.5;pm.scale_max=0.8
	var curve:=Curve.new();curve.add_point(Vector2(0.0,0.3));curve.add_point(Vector2(1.0,1.6))
	var curve_tex:=CurveTexture.new();curve_tex.curve=curve;pm.scale_curve=curve_tex
	var ramp:=Gradient.new();ramp.set_color(0,Color(1,1,1,0.0));ramp.set_color(1,Color(1,1,1,0.0));ramp.add_point(0.15,Color(1,1,1,0.9))
	var ramp_tex:=GradientTexture1D.new();ramp_tex.gradient=ramp;pm.color_ramp=ramp_tex
	puff.process_material=pm
	var quad:=QuadMesh.new();quad.size=Vector2(0.16,0.16)
	var mat:=ShaderMaterial.new();mat.shader=SMOKE
	mat.set_shader_parameter("warm",Color(0.92,0.93,0.95));mat.set_shader_parameter("cool",Color(0.92,0.93,0.95))
	mat.set_shader_parameter("opacity",0.32)
	quad.material=mat
	puff.draw_pass_1=quad
	puff.position=offset
	puff.visibility_aabb=AABB(Vector3(-1,-1,-1),Vector3(2,2,2))
	puff.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# breaths come at their own pace for each person
	puff.speed_scale=0.8+0.4*float(absi(String(body.name).hash())%100)/100.0
	parent.add_child(puff)
	puff.visible=season=="winter" and not indoors()
	puff.emitting=puff.visible and active
	breaths.append(puff)
	return puff

# --- Quality ------------------------------------------------------------------------

## Set the quality ("high" or "low"); the reason is kept for the report.
func set_quality(to:String,reason:="asked")->void:
	level="low" if to=="low" else "high"
	level_reason=reason
	var low:=level=="low"
	for ray in _window_daylight:ray.visible=not low
	if is_instance_valid(shimmer):shimmer.visible=not low
	for p in particles:
		if not is_instance_valid(p):continue
		match String(p.name):
			"Smoke":p.amount=12 if low else 26
			"Embers":p.amount=8 if low else 18
			"Dust":p.visible=not low
	if snowfall!=null:snowfall.visible=season=="winter" and not low
	for puff in breaths:
		if is_instance_valid(puff):puff.amount=2 if low else 4
	# only the set's main pieces carry the ink line on low
	for entry:Array in _dressing:
		var inked:=bool(entry[3]) and (not low or String(entry[4])=="StaticInked")
		(entry[0] as MeshInstance3D).set_surface_override_material(int(entry[1]),_material(String(entry[2]),inked))
	if sun!=null:
		sun.directional_shadow_mode=DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS if low else DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
		sun.directional_shadow_max_distance=18.0 if low else 30.0
		# Keep a detailed 3.6m near cascade on both levels, including a later
		# automatic downgrade. Low still uses half as many shadow passes.
		sun.directional_shadow_split_1=0.2 if low else 0.12
		sun.directional_shadow_split_2=0.28
		sun.directional_shadow_split_3=0.52
		sun.directional_shadow_blend_splits=false
		sun.shadow_blur=1.0 if low else 1.4
		if not _god_base.is_empty():_god_base.sun_blur=sun.shadow_blur
	if rig!=null:rig.set("far_blur",not low)
	if season!="":_apply_season(season)
	_god_apply()

## What the auto quality found, for a report.
func quality_report()->Dictionary:
	return {"level":level,"reason":level_reason,"frames":_frames_seen,"mean_frame_ms":(1000.0*_slow_time/maxf(1.0,float(_frames_seen)))}

## Where the meat rack (or the stores) stands: where the flies gather.
func rack_centre()->Vector3:
	return _rack_at

# --- The god's light ----------------------------------------------------------------

## The god turns to someone: a light falls on them. tone: "speaks", "wrath",
## "favour" or "off". target: the body (or a point) addressed; null keeps
## the last. hold: seconds the light stays before easing back by itself (0:
## until "off"). fade: seconds to come in (-1: the tone's own). The camera's
## jolt for wrath is the director's (shot "shake"), not this.
func god_light(target:Variant=null,tone:="speaks",hold:=0.0,fade:=-1.0)->void:
	if not GOD_TONES.has(tone):tone="off"
	if typeof(target)==TYPE_VECTOR3:
		_god_target=target;_god_target_ref=null
	elif typeof(target)==TYPE_OBJECT and is_instance_valid(target) and target is Node3D:
		_god_target=(target as Node3D).global_position;_god_target_ref=weakref(target)
	elif tone!="off" and god_tone=="off" and has_mark("petitioner"):_god_target=mark("petitioner").global_position
	_god_reduced=Motion.reduced()
	if tone!="off":
		_god_make();_god_origin=_god_source();_god_aim()
	if _god_cur[0]==0.0 and tone!="off":_god_baseline()
	# A direct light cue must not inherit a previous spoken line's release.
	_god_out=-1.0
	god_tone=tone
	_god_from=_god_cur.duplicate();_god_col_from=_god_col
	_god_to=PackedFloat32Array(GOD_NEUTRAL) if tone=="off" else PackedFloat32Array((GOD_TONES[tone] as Dictionary).p)
	_god_col_to=_god_col if tone=="off" else Color((GOD_TONES[tone] as Dictionary).colour)
	var time:float=fade if fade>=0.0 else float({"speaks":1.2,"wrath":0.25,"favour":1.0,"off":1.4}[tone])
	if _god_tween and _god_tween.is_valid():_god_tween.kill()
	if time<=0.0 or not is_inside_tree():
		_god_step(1.0)
	else:
		_god_tween=create_tween()
		_god_tween.tween_method(_god_step,0.0,1.0,time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if hold>0.0 and tone!="off":
		if _god_tween==null or not _god_tween.is_valid():_god_tween=create_tween()
		_god_tween.tween_interval(hold)
		_god_tween.tween_callback(_god_ease_out)

## The god's words as one moment, called alongside the sound's god(). The
## attack occupies the beginning of the line, not extra time after it.
## A short visual afterglow lets the room recover after the quieter sound
## tail. Tone "" (awe), "wrath" or "favour".
const GOD_SWELL_IN:=1.2
const GOD_SWELL_HOLD:=0.4
const GOD_SWELL_OUT:=1.4
func god_moment(target:Variant,tone:="",seconds:=2.0)->void:
	var t:="speaks"
	if tone=="wrath":t="wrath"
	elif tone in ["favour","favor"]:t="favour"
	var attack:=.25 if t=="wrath" else minf(GOD_SWELL_IN,maxf(.25,seconds*.35))
	god_light(target,t,maxf(.1,seconds+GOD_SWELL_HOLD-attack),attack)
	_god_out=GOD_SWELL_OUT

func _god_ease_out()->void:
	var out:=_god_out
	_god_out=-1.0
	god_light(null,"off",0.0,out)

## The tone in force and how far in it is (tests, the director).
func god_state()->Dictionary:
	var out:={"tone":god_tone,"colour":_god_col}
	for i in GOD_KEYS.size():out[GOD_KEYS[i]]=_god_cur[i]
	return out

func _god_make()->void:
	if god_spot!=null:return
	god_spot=SpotLight3D.new();god_spot.name="GodLight"
	god_spot.shadow_enabled=false;god_spot.light_specular=0.0
	god_spot.spot_attenuation=0.6;god_spot.spot_angle_attenuation=1.6
	god_spot.light_energy=0.0;god_spot.visible=false
	add_child(god_spot)
	# A small diffuse return from the god's side keeps the addressed face and
	# hands legible under a strong window backlight. No shadows or specular.
	god_return=OmniLight3D.new();god_return.name="GodReturn"
	god_return.shadow_enabled=false;god_return.light_specular=0.0
	god_return.omni_range=3.6;god_return.omni_attenuation=1.0
	god_return.light_energy=0.0;god_return.visible=false
	add_child(god_return)
	god_shaft=MeshInstance3D.new();god_shaft.name="GodShaft"
	var cyl:=CylinderMesh.new();cyl.top_radius=0.42;cyl.bottom_radius=0.78;cyl.height=1.0
	cyl.radial_segments=20;cyl.rings=1;cyl.cap_top=false;cyl.cap_bottom=false
	god_shaft.mesh=cyl
	_god_shaft_mat=ShaderMaterial.new();_god_shaft_mat.shader=SHAFT
	_god_shaft_mat.set_shader_parameter("strength",0.0);_god_shaft_mat.set_shader_parameter("soft",0.6)
	_god_shaft_mat.set_shader_parameter("ribbons",0.48)
	god_shaft.material_override=_god_shaft_mat
	god_shaft.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	god_shaft.visible=false
	add_child(god_shaft)
	god_pool=MeshInstance3D.new();god_pool.name="GodPool"
	var plane:=PlaneMesh.new();plane.size=Vector2(2.4,2.4);god_pool.mesh=plane
	_god_pool_mat=ShaderMaterial.new();_god_pool_mat.shader=POOL
	god_pool.material_override=_god_pool_mat
	god_pool.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	god_pool.visible=false
	add_child(god_pool)
	god_dust=GPUParticles3D.new();god_dust.name="GodDust"
	god_dust.amount=36;god_dust.lifetime=5.0;god_dust.randomness=0.5
	_god_dust_pm=ParticleProcessMaterial.new()
	_god_dust_pm.emission_shape=ParticleProcessMaterial.EMISSION_SHAPE_BOX
	_god_dust_pm.emission_box_extents=Vector3(0.55,1.1,0.55)
	_god_dust_pm.direction=Vector3(0,1,0);_god_dust_pm.spread=180.0
	_god_dust_pm.initial_velocity_min=0.02;_god_dust_pm.initial_velocity_max=0.08
	_god_dust_pm.gravity=Vector3(0,0.02,0)
	_god_dust_pm.scale_min=0.8;_god_dust_pm.scale_max=1.6
	_god_dust_pm.turbulence_enabled=true;_god_dust_pm.turbulence_noise_strength=0.4;_god_dust_pm.turbulence_noise_scale=3.0
	var ramp:=Gradient.new()
	ramp.set_color(0,Color(1,1,1,0));ramp.set_color(1,Color(1,1,1,0))
	ramp.add_point(0.2,Color(1,1,1,1));ramp.add_point(0.75,Color(1,1,1,1))
	var ramp_tex:=GradientTexture1D.new();ramp_tex.gradient=ramp;_god_dust_pm.color_ramp=ramp_tex
	god_dust.process_material=_god_dust_pm
	var dot:=QuadMesh.new();dot.size=Vector2(0.02,0.02)
	_god_dust_mat=ShaderMaterial.new();_god_dust_mat.shader=MOTE
	_god_dust_mat.set_shader_parameter("brightness",1.3)
	dot.material=_god_dust_mat
	god_dust.draw_pass_1=dot
	god_dust.local_coords=false
	god_dust.visibility_aabb=AABB(Vector3(-3,-3,-3),Vector3(6,8,6))
	god_dust.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	god_dust.emitting=false
	add_child(god_dust)

## Where the light comes from: the open sky above (a little from the god's
## side), or the hall's smoke hole or window nearest the one addressed.
func _god_source()->Vector3:
	var open:=bool((info.get("light",{}) as Dictionary).get("open_sky",true))
	var t:=_god_target
	if open:
		var toward:=Vector3(god_point().x-t.x,0.0,god_point().z-t.z)
		if toward.length()>0.01:toward=toward.normalized()
		return t+Vector3(0.0,9.0,0.0)+toward*2.2
	var best:=t+Vector3(0.0,5.0,0.0);var best_d:=INF
	# Chapter rooms have real windows, not the legacy hall's smoke hole.
	# Choose one opening per address; its position stays fixed as the person
	# moves, so the light cannot jump between windows halfway through a line.
	for opening:Array in info.get("apertures",[]):
		if opening.size()<4 or float(opening[3])<=float(opening[2]):continue
		var x:=float(opening[0])*(model.scale.x if model!=null else 1.0)
		var top:=to_global(Vector3(x,lerpf(float(opening[2]),float(opening[3]),.84),float((info.get("light",{}) as Dictionary).get("aperture_z",-3.78))))
		var d:=top.distance_squared_to(t+Vector3.UP)
		if d<best_d:best_d=d;best=top
	if best_d<INF:return best
	for spec:Dictionary in (info.get("fx",{}) as Dictionary).get("shafts",[]):
		var top:=to_global(_vec(spec.get("top",[0,5,0])))
		var d:=Vector2(top.x-t.x,top.z-t.z).length()
		if d<best_d:best_d=d;best=top
	return best

func _god_aim()->void:
	var s:=_god_origin
	var t:=_god_target
	var aim:=t+Vector3(0.0,1.0,0.0)
	# the lamp itself hangs a few metres up the beam, so nobody nearer the
	# hole than the one addressed is burnt white by it
	var from:=aim+(s-aim).normalized()*3.6
	god_spot.global_transform=Transform3D(Basis.looking_at((aim-from).normalized(),Vector3.UP if absf((aim-from).normalized().y)<0.98 else Vector3.FORWARD),from)
	god_spot.spot_range=from.distance_to(t)+2.5
	var window:bool=not (info.get("apertures",[]) as Array).is_empty() and indoors()
	var end:=t+Vector3.UP*1.45 if window else t
	var dir:=(end-s).normalized();var length:=s.distance_to(end)
	var y_axis:=-dir
	var x_axis:=y_axis.cross(Vector3.FORWARD if absf(y_axis.z)<0.9 else Vector3.RIGHT).normalized()
	var z_axis:=x_axis.cross(y_axis).normalized()
	_god_beam_basis=Basis(x_axis,y_axis*length,z_axis)
	god_shaft.global_transform=Transform3D(_god_beam_basis,s+dir*length*0.5)
	# Window light ends before the upper body; an overhead column fades above
	# their head. Neither beam paints a luminous stripe across the face.
	_god_shaft_mat.set_shader_parameter("fade_from",clampf(1.0-(1.4 if window else 3.2)/maxf(length,0.1),0.0,0.95))
	_god_shaft_mat.set_shader_parameter("fade_to",clampf(1.0-(.45 if window else 2.0)/maxf(length,0.1),0.05,1.0))
	god_dust.global_position=t+Vector3(0.0,1.25,0.0)
	god_pool.global_position=Vector3(t.x,t.y+0.03,t.z)
	_god_dust_mat.set_shader_parameter("shaft_top",s)
	_god_dust_mat.set_shader_parameter("shaft_dir",dir)
	_god_dust_mat.set_shader_parameter("shaft_radius",0.7)
	# Stretch the pool along the incoming light, without a new projected
	# texture or light. It remains a soft pool, never a targeting decal.
	god_pool.global_rotation.y=atan2(dir.x,dir.z)
	god_pool.scale=Vector3(1.0,1.0,clampf(1.0/maxf(absf(dir.y),.55),1.0,1.65))
	# the wind comes from the god's side, across the one addressed
	var across:=Vector3(t.x-god_point().x,0.0,t.z-god_point().z)
	_god_wind=(across.normalized() if across.length()>0.01 else Vector3(1,0,0))+Vector3(0.0,0.08,0.0)
	var toward_god:Vector3=-across.normalized() if across.length()>.01 else Vector3.FORWARD
	god_return.global_position=t+Vector3.UP*1.5+toward_god*1.8+Vector3(toward_god.z,0,-toward_god.x)*.5
	if sun!=null:
		# wrath: a low cold sun from the god's side; shadows run long toward them
		var flat:=Vector3(t.x-god_point().x,0.0,t.z-god_point().z)
		if flat.length()<0.01:flat=Vector3(0,0,-1)
		var down:=(flat.normalized()*cos(deg_to_rad(24.0))+Vector3.DOWN*sin(deg_to_rad(24.0))).normalized()
		_sun_wrath=Basis.looking_at(down,Vector3.UP).get_rotation_quaternion()

func _god_baseline()->void:
	var env:=world_env.environment if world_env!=null else null
	_god_base={"ambient":env.ambient_light_energy if env!=null else 0.5,"sat":env.adjustment_saturation if env!=null else 1.0,
		"sun_energy":sun.light_energy if sun!=null else 1.0,"sun_rot":sun.transform.basis.get_rotation_quaternion() if sun!=null else Quaternion.IDENTITY,
		"sun_blur":sun.shadow_blur if sun!=null else 1.0,"sun_colour":sun.light_color if sun!=null else Color.WHITE,"bounce":0.45}
	_god_base["fills"]=[]
	for fill in fill_lights:_god_base.fills.append(fill.light_energy)

## One step of the god's light toward its tone (k 0..1 of the way).
func _god_step(k:float)->void:
	for i in _god_cur.size():_god_cur[i]=lerpf(_god_from[i],_god_to[i],k)
	_god_col=_god_col_from.lerp(_god_col_to,k)
	_god_apply()

func _god_apply()->void:
	var energy:=_god_cur[0];var angle:=_god_cur[1];var shaft_s:=_god_cur[2];var dim:=_god_cur[3]
	var fire:=_god_cur[4];var fire_h:=_god_cur[5];var lean:=_god_cur[6];var gust:=_god_cur[7]
	var sharp:=_god_cur[8];var sat:=_god_cur[9];var sun_turn:=_god_cur[10];var rise:=_god_cur[11]
	if _god_reduced:lean=0.0;gust=0.0;sun_turn=0.0;rise=0.0
	var open_sky:=bool((info.get("light",{}) as Dictionary).get("open_sky",true))
	if god_spot!=null:
		# under the open sky the beam must stand out against daylight
		god_spot.light_energy=energy*(1.3 if open_sky else 0.65);god_spot.spot_angle=angle;god_spot.light_color=_god_col
		var width:=clampf(angle/15.0,.7,1.45)
		god_shaft.global_basis=Basis(_god_beam_basis.x*width,_god_beam_basis.y,_god_beam_basis.z*width)
		_god_shaft_mat.set_shader_parameter("motion",0.0 if _god_reduced else 1.0)
		# the god's column owns the opening (the sun's own shaft fades below)
		_god_shaft_mat.set_shader_parameter("strength",shaft_s*(2.0 if open_sky else 1.1));_god_shaft_mat.set_shader_parameter("colour",_god_col)
		_god_dust_mat.set_shader_parameter("colour",_god_col.lerp(Color(1,1,1),0.3))
		# the pool on the ground: the light reads even where the beam does not
		var peak:=lerpf(7.0,2.4,sharp)
		var share:=clampf(energy/peak,0.0,1.0)
		god_return.light_energy=share*lerpf(.9,.7,sharp)
		god_return.light_color=_god_col
		_god_pool_mat.set_shader_parameter("colour",_god_col)
		_god_pool_mat.set_shader_parameter("strength",share*(0.55 if open_sky else 0.4)*lerpf(1.0,.6,sharp))
		# in a hall the god's light owns the opening: the sun's own shaft fades
		for i in _sun_shaft_mats.size():
			_sun_shaft_mats[i].set_shader_parameter("strength",_sun_shaft_strength[i]*(1.0-0.8*share))
		_god_dust_pm.gravity=Vector3(0.0,0.02+0.3*rise,0.0)+_god_wind*1.6*gust
		_god_visibility()
	if _god_base.is_empty():return
	var env:=world_env.environment if world_env!=null else null
	if env!=null:
		env.ambient_light_energy=float(_god_base.ambient)*(1.0-dim)
		env.adjustment_saturation=float(_god_base.sat)+sat
	if sun!=null:
		var open:=bool((info.get("light",{}) as Dictionary).get("open_sky",true))
		var turn:=sun_turn*(1.0 if open else 0.5)
		# a darker room, not a brighter beam; in a hall the sun's pool fades
		# while the god's light owns the opening
		var owns:=0.0 if open else clampf(energy/2.4,0.0,1.0)
		sun.light_energy=float(_god_base.sun_energy)*(1.0-dim*(1.1 if open else 0.5))*(1.0+0.15*sharp)*(1.0-0.8*owns)
		sun.transform.basis=Basis((_god_base.sun_rot as Quaternion).slerp(_sun_wrath,turn))
		sun.shadow_blur=lerpf(float(_god_base.sun_blur),0.2,sharp)
		sun.light_color=(_god_base.sun_colour as Color).lerp(Color(0.86,0.9,1.0),sharp*0.35)
	if bounce!=null:bounce.light_energy=float(_god_base.bounce)*fire
	# Window bounce follows the room's dramatic change too. Leaving these at
	# full energy washed out the speaker's light in newer, well-lit offices.
	for i in fill_lights.size():
		fill_lights[i].light_energy=float(_god_base.fills[i])*(1.0-dim*.65)*(1.0-(0.0 if open_sky else clampf(energy/2.4,0.0,1.0))*.32)
	_fire_now=fire;_fire_h_now=fire_h
	_fire_mul=fire*(1.0+2.2*_flare)
	for mat in _flame_mats:
		mat.set_shader_parameter("height_mul",fire_h*(1.0+2.6*_flare))
		mat.set_shader_parameter("lean",lean)
	for mat in _gust_mats:
		mat.set_shader_parameter("gust",gust)
		mat.set_shader_parameter("wind",_god_wind)
	if _smoke_pm!=null:_smoke_pm.gravity=_smoke_gravity.lerp(_god_wind*1.4+Vector3(0.0,0.05,0.0),gust)

## Visibility is reconciled immediately on quality and modal changes too;
## holding a light has no Tween callbacks to do that work on our behalf.
func _god_visibility()->void:
	if god_spot==null:return
	var on:=active and _god_cur[0]>.02
	god_spot.visible=on
	god_return.visible=on
	god_shaft.visible=active and _god_cur[2]>.01
	god_pool.visible=on
	god_dust.visible=on and level=="high" and not _god_reduced
	god_dust.emitting=god_dust.visible
	god_dust.speed_scale=1.0 if god_dust.visible else 0.0

# --- Executions: props, blood, the pack, the hall that remembers ----------------------

var blood_node:Node3D
var _execution_fire:Node3D
var _execution_flames:Array[ShaderMaterial]=[]

## An explicit staged act can bring a temporary fire into an otherwise cold
## set. It owns its effects and removes them on finish/skip; no idle hearth.
func execution_fire(at:Vector3,on:bool)->void:
	if is_instance_valid(_execution_fire):
		_execution_fire.queue_free()
		_execution_fire=null
	for mat in _execution_flames:_flame_mats.erase(mat)
	_execution_flames.clear()
	if not on or has_hearth():return
	var before:=_flame_mats.size()
	_execution_fire=_flame(to_local(at),1.0,"ExecutionFire",3)
	for i in range(before,_flame_mats.size()):_execution_flames.append(_flame_mats[i])
	var light:=OmniLight3D.new();light.name="ActFireLight"
	light.light_color=Color(1.0,0.58,0.30);light.light_energy=1.3;light.omni_range=5.0
	light.position.y=0.8;light.shadow_enabled=false
	_execution_fire.add_child(light)

var _trophy_root:Node3D
var _skull_stakes:Array[Node3D]=[]
var _skull_heap:Array[Node3D]=[]
## How many trophies show (tests): skulls on stakes, skulls heaped, stains.
var trophies:={"stakes":0,"heap":0,"stains":0,"statues":0}
var _statues:Array[Node3D]=[]
const STATUES_SHOWN:=4
const FIGURE_PATH:="res://scripts/hud/court_figure_3d.gd"
const SKULL_STAKES:=9
const SKULL_HEAP:=12
const STAIN_DAYS:=5.0

## Dress a prop (or anything modelled in the set's slots) in this set's own
## paint and ink: its meshes' material names are the slots.
func dress(root:Node)->void:
	var nodes:=root.find_children("*","MeshInstance3D",true,false)
	if root is MeshInstance3D:nodes.append(root)
	for node in nodes:
		var mesh_node:=node as MeshInstance3D
		if mesh_node.mesh==null:continue
		mesh_node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		for surface in mesh_node.mesh.get_surface_count():
			var source:=mesh_node.mesh.surface_get_material(surface)
			var slot:=source.resource_name if source!=null else "WOOD"
			mesh_node.set_surface_override_material(surface,_material(slot,true))

## An execution's prop, dressed in this set (court_exec_props.gd), or null.
func exec_prop(prop_name:String)->Node3D:
	return ExecProps.make(prop_name,self)

## The court's blood (court_blood.gd), made on first use.
func blood()->Node3D:
	if blood_node==null:
		blood_node=Blood.new()
		add_child(blood_node)
	return blood_node

## WHOOMPH (act 3): the hearth roars up for a moment, flames three times
## their height and the firelight flaring over the room, then dies back.
func fire_flare(seconds:=1.6,strength:=1.0)->void:
	if not is_inside_tree():
		_set_flare(0.0);return
	var t:=create_tween()
	t.tween_method(_set_flare,0.0,strength,0.12).set_ease(Tween.EASE_OUT)
	t.tween_interval(maxf(seconds-0.9,0.1))
	t.tween_method(_set_flare,strength,0.0,0.8).set_ease(Tween.EASE_IN)

func _set_flare(k:float)->void:
	_flare=k
	_fire_mul=_fire_now*(1.0+2.2*k)
	for mat in _flame_mats:mat.set_shader_parameter("height_mul",_fire_h_now*(1.0+2.6*k))

## A small fire of the hearth's own flames (under a cauldron, on its
## fire_seat): it flares with the hearth. Free it when the act is done.
func small_fire(at:Vector3,size:=0.35)->Node3D:
	return _flame(to_local(at) if is_inside_tree() else at,size,"SmallFire",2)

## The pot or cauldron comes to the boil (act 14): bubbles swell and pop on
## its broth (its "broth" seat), `amount` 0..1. Returns the boil's surface;
## stop_boil(prop) takes it off.
func boil(prop:Node3D,amount:=1.0)->MeshInstance3D:
	if prop==null:return null
	var spec:=ExecProps.info(String(prop.get_meta("prop",prop.name)))
	if not spec.has("broth"):return null
	var surface:=prop.get_node_or_null("Boil") as MeshInstance3D
	if surface==null:
		surface=MeshInstance3D.new();surface.name="Boil"
		var plane:=PlaneMesh.new();plane.size=Vector2(2.0,2.0);surface.mesh=plane
		var mat:=ShaderMaterial.new();mat.shader=BOIL
		mat.set_shader_parameter("broth",_colour(String((PALETTE.get("BROTH",["7a5634"]) as Array)[0]),Color("7a5634")))
		mat.set_shader_parameter("seed",randf()*40.0)
		surface.material_override=mat
		surface.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		prop.add_child(surface)
	var r:=float(spec.get("broth_radius",0.4))*0.98
	var b:Array=spec.broth
	surface.transform=Transform3D(Basis.from_scale(Vector3(r,1.0,r)),Vector3(float(b[0]),float(b[1])+0.006,float(b[2])))
	(surface.material_override as ShaderMaterial).set_shader_parameter("boil",clampf(amount,0.0,1.0))
	surface.visible=true
	return surface

func stop_boil(prop:Node3D)->void:
	if prop!=null and prop.get_node_or_null("Boil")!=null:(prop.get_node("Boil") as Node3D).visible=false

## Where the dogs drag the dead out of sight: in at the door, out past it
## and round behind the windbreak or the end wall (global points).
func drag_route()->Array[Vector3]:
	var out:Array[Vector3]=[]
	for name_ in ["door","behind_windbreak"]:
		var m:=mark(name_)
		if m!=null:out.append(m.global_position if is_inside_tree() else m.position)
	return out

## A herd brought in for an act (the pigs, the cattle or oxen, a bear, an
## elephant): `count` of `species`, each in one of `coats` in turn, in at
## the door, standing. They are held for the director and go with the set.
func beasts(species:String,count:=1,coats:Array=[])->Array:
	var out:Array=[]
	if not Animal.available(species):return out
	var door:=mark("door")
	var at:=door.position if door!=null else Vector3(-5.0,0.0,0.0)
	var fire:=mark("fire").position if has_mark("fire") else Vector3.ZERO
	var inward:=Vector3(fire.x-at.x,0.0,fire.z-at.z).normalized()
	var right:=inward.cross(Vector3.UP).normalized()
	var size:=float(((Animal.manifest().get("species",{}) as Dictionary).get(species,{}) as Dictionary).get("height",0.8))
	for i in count:
		var beast:Node3D=Animal.new()
		var coat_name:=String(coats[i%coats.size()]) if not coats.is_empty() else ""
		if not beast.call("setup",species,self,8000+i*7,coat_name):
			beast.free();continue
		add_child(beast)
		beast.position=at+inward*(0.8+size*0.9*float(i/3))+right*(float(i%3)-1.0)*size*0.9
		beast.rotation.y=atan2(inward.x,inward.z)
		beast.call("play","idle",0.0,float(i)*0.53)
		# it does nothing of its own accord: it waits on the director
		beast.set("herded",true)
		animals.append(beast)
		out.append(beast)
	return out

## Staged animals can enter even when the era omits ambient court pets.
func can_stage_dogs()->bool:
	return Animal.available("dog")

## The camp dogs come running (act 4): the dog of the court and `count`
## more, each its own coat, in at the door. Returns them all (the court's own
## dog first); they are held for the director, and stay until the set goes.
func dog_pack(count:=3)->Array:
	var out:Array=[]
	var own:=animal("dog")
	if own!=null:out.append(own)
	var door:=mark("door")
	var at:=door.global_position if door!=null else Vector3(-5.0,0.0,0.0)
	for i in count:
		if not Animal.available("dog"):break
		var beast:Node3D=Animal.new()
		if not beast.call("setup","dog",self,7000+i,["black","grey","cream","brindle"][i%4]):
			beast.free();continue
		add_child(beast)
		beast.position=at+Vector3(float(i)*0.45-0.45,0.0,float(i%2)*0.5)
		beast.call("start_at","door")
		beast.position=at+Vector3(float(i)*0.45-0.45,0.0,float(i%2)*0.5)
		beast.call("hold",2.0+float(i)*0.6)
		animals.append(beast)
		out.append(beast)
	return out

## The hall remembers (EXECUTIONS.md): skulls on stakes by the door, one for
## each of the dead the ledger holds (the rest heaped at their feet), and
## stains on the floor before the god from the last few days, fading.
## facts: executions (how many), execution_days (days since each, newest first).
func _apply_trophies()->void:
	var count:=maxi(0,int(facts.get("executions",0)))
	var days:Array=facts.get("execution_days",[]) if facts.get("execution_days",[]) is Array else []
	# Lifetime deaths remain in the ledger; a working office is not permanently
	# furnished with the old camp's stake avenue or heaps. Explicit acted effects
	# still belong to the current scene and are cleaned up with it.
	if not bool(info.get("rustic_trophies",true)):count=0;days=[]
	var statues:Array=facts.get("statues",[]) if facts.get("statues",[]) is Array else []
	if count==0 and days.is_empty() and statues.is_empty() and _trophy_root==null:
		trophies={"stakes":0,"heap":0,"stains":0,"statues":0};return
	_trophy_ensure()
	var stakes:=mini(count,SKULL_STAKES)
	for i in _skull_stakes.size():_skull_stakes[i].visible=i<stakes
	var heap:=clampi(count-SKULL_STAKES,0,SKULL_HEAP)
	for i in _skull_heap.size():_skull_heap[i].visible=i<heap
	var shown:=0
	var b:=blood()
	# (set-local: this runs while the set is built, before it is in a tree)
	var centre:=mark("petitioner").position if has_mark("petitioner") else Vector3.ZERO
	var srng:=RandomNumberGenerator.new();srng.seed=4411
	for i in Blood.STAINS:
		var age:=float(days[i]) if i<days.size() else 999.0
		var at:=centre+Vector3(srng.randf_range(-0.9,0.9),0.0,srng.randf_range(-0.6,0.6))
		b.call("stain",i,Vector3(at.x,0.0,at.z),srng.randf_range(0.9,1.5),age,STAIN_DAYS)
		if age<STAIN_DAYS:shown+=1
	var standing:=_apply_statues(statues)
	trophies={"stakes":stakes,"heap":heap,"stains":shown,"statues":standing}

## The bronze statues by the door (act 20's trophy): each one a person in
## the figures' own body, set in the pose they were dipped in and cast whole
## in bronze, on a plinth inside the door. facts.statues: [{look, clip, at}]
## (GameState.court_statues). Returns how many stand.
func _apply_statues(list:Array)->int:
	var want:=mini(list.size(),STATUES_SHOWN)
	while _statues.size()>want:
		var gone:Node3D=_statues.pop_back()
		if is_instance_valid(gone):gone.queue_free()
	if want==0 or _trophy_root==null:return 0
	if not ResourceLoader.exists(FIGURE_PATH):return 0
	var figure_script:=load(FIGURE_PATH) as Script
	var door:=mark("door")
	if door==null or figure_script==null:return 0
	var base:=door.position
	var fire:=mark("fire").position if has_mark("fire") else Vector3.ZERO
	var inward:=Vector3(fire.x-base.x,0.0,fire.z-base.z).normalized()
	var right:=inward.cross(Vector3.UP).normalized()
	for i in want:
		var entry:Dictionary=list[list.size()-want+i] if list[list.size()-want+i] is Dictionary else {}
		if i<_statues.size() and is_instance_valid(_statues[i]) and _statues[i].get_meta("entry",{})==entry:continue
		if i<_statues.size() and is_instance_valid(_statues[i]):_statues[i].queue_free()
		var holder:=Node3D.new();holder.name="Statue%d" % i
		holder.set_meta("entry",entry)
		var side:=1.0 if i%2==0 else -1.0
		holder.position=base+inward*(0.6+1.4*float(i/2))+right*side*1.75
		holder.rotation.y=atan2(-right.x*side,-right.z*side)*0.5+atan2(inward.x,inward.z)*0.5
		_trophy_root.add_child(holder)
		var plinth:=exec_prop("plinth")
		if plinth!=null:holder.add_child(plinth)
		# the figure is made once the hall is up (its rig wants the tree)
		if holder.is_inside_tree():_make_statue(holder,entry,figure_script)
		else:holder.tree_entered.connect(_make_statue.bind(holder,entry,figure_script),CONNECT_ONE_SHOT)
		if i<_statues.size():_statues[i]=holder
		else:_statues.append(holder)
	return want

func _make_statue(holder:Node3D,entry:Dictionary,figure_script:Script)->void:
	if not is_instance_valid(holder) or holder.get_node_or_null("Figure")!=null:return
	var fig:Node3D=figure_script.new();fig.name="Figure"
	holder.add_child(fig)
	var look:Dictionary=(entry.get("look",{}) as Dictionary).duplicate(true)
	if not bool(fig.call("setup",look)):
		fig.queue_free();return
	fig.position=Vector3(0.0,0.66,0.0)
	var clip:=String(entry.get("clip",""))
	if clip.is_empty():clip=String(fig.call("rest_clip"))
	fig.call("play",clip,0.0,float(entry.get("at",0.5)))
	_bronze(fig)

## Cast in bronze: every surface of a figure in the set's own bronze, its
## clip stopped where it was (the statue never moves again).
func _bronze(fig:Node3D)->void:
	var metal:=_material("BRONZE_CAST",true)
	for node in fig.find_children("*","MeshInstance3D",true,false):
		(node as MeshInstance3D).material_override=metal
	for player in fig.find_children("*","AnimationPlayer",true,false):
		var ap:=player as AnimationPlayer
		ap.advance(0.0)
		ap.pause()
	fig.set_process(false)

## Remember someone dipped in bronze (the director, act 20): their look, the
## clip and the moment they were cast in. They stand by the door for good.
static func remember_statue(look:Dictionary,clip:="",at:=0.5)->void:
	var loop:=Engine.get_main_loop() as SceneTree
	var state:Node=loop.root.get_node_or_null("GameState") if loop!=null and loop.root!=null else null
	if state==null:return
	var list:Variant=state.get("court_statues")
	if not list is Array:return
	(list as Array).append({"look":look.duplicate(true),"clip":clip,"at":at})
	var cap:=int(state.get("COURT_STATUES_MAX")) if state.get("COURT_STATUES_MAX")!=null else 6
	while (list as Array).size()>cap:(list as Array).pop_front()

func _trophy_ensure()->void:
	if _trophy_root!=null:return
	_trophy_root=Node3D.new();_trophy_root.name="Trophies"
	add_child(_trophy_root)
	var door:=mark("door")
	if door==null:return
	# an avenue of them, either side of the way in from the door
	var base:=door.position
	var fire:=mark("fire").position if has_mark("fire") else Vector3.ZERO
	var inward:=Vector3(fire.x-base.x,0.0,fire.z-base.z).normalized()
	var right:=inward.cross(Vector3.UP).normalized()
	for i in SKULL_STAKES:
		var side:=1.0 if i%2==0 else -1.0
		var along:=0.55+0.6*float(i/2)
		var stake:=exec_prop("skull_stake")
		if stake==null:return
		stake.position=base+inward*along+right*side*(0.72+0.06*float(i%3))
		# each leans its own way, and the skull looks into the hall
		stake.rotation=Vector3(deg_to_rad(float(i*7%11)-5.0),atan2(inward.x,inward.z)+deg_to_rad(float(i*37%50)-25.0),deg_to_rad(float(i*5%9)-4.0))
		stake.visible=false
		_trophy_root.add_child(stake)
		_skull_stakes.append(stake)
	for i in SKULL_HEAP:
		var sk:=exec_prop("skull")
		if sk==null:return
		var side2:=1.0 if i%2==0 else -1.0
		var along2:=0.35+0.6*float((i/2)%5)
		sk.position=base+inward*(along2+0.12*float(i%3))+right*side2*(0.95+0.12*float(i/10))
		# heaped, but each grinning into the hall
		sk.rotation=Vector3(deg_to_rad(-float(i*7%14)),atan2(inward.x,inward.z)+deg_to_rad(float(i*37%70)-35.0),deg_to_rad(float(i*13%24)-12.0))
		sk.visible=false
		_trophy_root.add_child(sk)
		_skull_heap.append(sk)

## How many of a prop group are showing (tests, the director).
func shown(group:String)->int:
	var count:=0
	for node in props.get(group,[]):
		if (node as Node3D).visible:count+=1
	return count

## Whether the things a tag brings are on show ("pottery", "no_pottery", ...).
func gate_shown(key:String)->bool:
	for node in gates.get(key,[]):
		if is_instance_valid(node) and (node as Node3D).visible:return true
	return false

func _show_first(list:Array,count:int)->void:
	for i in list.size():(list[i] as Node3D).visible=i<count

# --- Animals ------------------------------------------------------------------------

## The animals of the court: a dog in every age; herd animals and fowl only
## once the people keep them (facts herds, fowl).
static func animals_for(facts_in:Dictionary)->Array[String]:
	var out:Array[String]=[]
	if bool(facts_in.get("dogs",true)):out.append("dog")
	if bool(facts_in.get("herds",false)):out.append("goat")
	if bool(facts_in.get("fowl",false)):
		out.append("hen");out.append("hen")
	return out

func _place_animals()->void:
	var spots:=marks_for("animal_")
	var index:=0
	for species:String in animals_for(facts):
		if index>=spots.size():break
		if not Animal.available(species):continue
		var beast:Node3D=Animal.new()
		if not beast.call("setup",species,self,int(facts.get("seed",0))+index):
			beast.free();continue
		add_child(beast)
		beast.call("start_at",String(spots[index].name))
		animals.append(beast)
		# the dog by the fire stays in the room's shot
		if species=="dog" and rig!=null:(rig.get("also_show") as Array).append(beast)
		index+=1

func animal(species:String)->Node3D:
	for beast in animals:
		if is_instance_valid(beast) and String(beast.get("species"))==species:return beast
	return null

# --- Running ------------------------------------------------------------------------

## The court is open (on) or hidden (off): nothing processes or emits while hidden.
func set_active(on:bool)->void:
	active=on
	set_process(on)
	_god_visibility()
	for p in particles:
		if is_instance_valid(p):
			p.emitting=on and p.visible
			p.speed_scale=1.0 if on else 0.0
	for p in flies+breaths:
		if is_instance_valid(p):
			p.emitting=on and p.visible
			p.speed_scale=1.0 if on else 0.0
	if snowfall!=null:
		snowfall.emitting=on and snowfall.visible
		snowfall.speed_scale=1.0 if on else 0.0
	for beast in animals:
		if is_instance_valid(beast):beast.call("set_active",on)

func _ready()->void:
	set_process(active)

func _process(delta:float)->void:
	_clock+=delta
	var reduced:=Motion.reduced()
	if reduced!=_god_reduced:
		_god_reduced=reduced;_god_apply()
	if _god_cur[0]>.02 and _god_target_ref!=null:
		var body:=_god_target_ref.get_ref() as Node3D
		if not is_instance_valid(body) or not body.is_inside_tree() or not body.is_visible_in_tree():
			_god_target_ref=null;god_light(null,"off",0.0,.45)
		elif body.global_position.distance_squared_to(_god_target)>.000001:
			_god_target=body.global_position;_god_aim();_god_apply()
	# auto quality: watch the first seconds the court is open, drop once if slow
	if quality=="auto" and level=="high" and _clock>0.5 and _frames_seen<120:
		_frames_seen+=1;_slow_time+=delta
		if _frames_seen>=90 and _slow_time/float(_frames_seen)>SLOW_FRAME:
			set_quality("low","slow frames (%.1f ms)" % (1000.0*_slow_time/float(_frames_seen)))
	var n:=_noise.get_noise_1d(_clock*6.0)*0.55+_noise.get_noise_1d(_clock*17.0+40.0)*0.3+_noise.get_noise_1d(_clock*1.3+90.0)*0.15
	if fire_light!=null:
		fire_light.light_energy=_fire_energy*_fire_mul*(1.0+0.22*n)
		fire_light.position=_fire_at+Vector3(n*0.05,absf(n)*0.06,_noise.get_noise_1d(_clock*5.0+7.0)*0.05)
	# Keep the room's hush throughout the held beat. Previously the next
	# frame restored full fire bounce and erased the god's lighting envelope.
	if bounce!=null:bounce.light_energy=float(_god_base.get("bounce",.45))*_fire_now*(1.0+0.12*n)
	for i in flame_lights.size():
		flame_lights[i].light_energy=_flame_energies[i]*_fire_mul*(1.0+0.2*_noise.get_noise_1d(_clock*7.0+float(i)*50.0))

## Which way the strongest light comes from (toward it), for figures whose
## shading takes one key light (court_figure_3d.gd set_key_light).
func key_dir()->Vector3:
	if sun==null:return Vector3(-0.35,0.65,0.68)
	var to_sun:=sun.global_transform.basis.z.normalized()
	if bool((info.get("light",{}) as Dictionary).get("open_sky",true)):return to_sun
	return (to_sun*0.6+Vector3(0.0,0.55,0.55)).normalized()

## How much light falls on someone standing here, about 1 (figure dim), for
## figures that do not take the set's lights: the hall is dimmer than the open
## sky, the fire warms those close to it, the sun's shaft lights whoever
## stands in it.
func light_at(point:Vector3)->float:
	var open:=bool((info.get("light",{}) as Dictionary).get("open_sky",true))
	var amount:=1.0 if open else 0.84
	var to_fire:=Vector2(point.x-_fire_at.x,point.z-_fire_at.z).length()
	if not open and has_hearth():amount+=0.10*clampf(1.0-(to_fire-1.0)/3.0,0.0,1.0)
	if _shaft_radius>0.0:
		var rel:=point+Vector3(0.0,1.2,0.0)-_shaft_top
		var along:=rel.dot(_shaft_dir)
		var off:=(rel-_shaft_dir*along).length()
		amount+=0.18*clampf(1.0-(off-_shaft_radius*0.5)/_shaft_radius,0.0,1.0)
	return amount

## Kept for callers of round 2: the figures now carry their own lit shader
## (J's court_figure_lit.gdshader), so this changes no material. It only
## points the figures' painted key light the way this set's light comes from
## (pass the CourtFigure3D script to have it set; anything else is ignored).
static func light_figures(_materials:Variant=null,figure_script:Variant=null,court:Node3D=null)->void:
	if figure_script is Script and court!=null and (figure_script as Script).has_method("set_key_light"):
		(figure_script as Object).call("set_key_light",court.call("key_dir"))

## A soft shade on the ground under someone's feet: it keeps them standing
## ON the ground. Lay it under a figure or an animal (a child at its feet).
static func contact_shadow(width:=0.9,depth:=0.62,strength:=0.55)->MeshInstance3D:
	if _contact_material==null:
		_contact_material=ShaderMaterial.new();_contact_material.shader=CONTACT
		_contact_mesh=PlaneMesh.new();_contact_mesh.size=Vector2(1.0,1.0)
	var made:=MeshInstance3D.new();made.name="ContactShade"
	made.mesh=_contact_mesh;made.material_override=_contact_material
	made.set_instance_shader_parameter("strength",strength)
	made.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	made.scale=Vector3(width,1.0,depth)
	made.position=Vector3(0.0,0.012,0.0)
	return made

## The executions in the ledger's deaths by cause (GameState.death_cause_days,
## [{day, cause, count}], the last 400 days): how many were put to death at the
## god's word, and how many days ago each of the latest was (newest first).
static func executions_from(causes:Array,today:int)->Dictionary:
	var count:=0;var days:Array=[]
	for i in range(causes.size()-1,-1,-1):
		var entry:Variant=causes[i]
		if not entry is Dictionary:continue
		if not String((entry as Dictionary).get("cause","")).begins_with("Executed"):continue
		var n:=maxi(0,int((entry as Dictionary).get("count",0)))
		count+=n
		for k in mini(n,Blood.STAINS-days.size()):days.append(float(maxi(0,today-int((entry as Dictionary).get("day",today)))))
	return {"executions":count,"execution_days":days}

## What the stage can pass in, read from the game (read-only): how full the
## stores are, whether the people are at war, their era's tier and tags,
## which animals they keep, and their dyes.
static func facts_from_game(owner:="player")->Dictionary:
	var out:={"food":0.6,"war":false,"tier":0,"herds":false,"fowl":false,"dogs":true}
	out["chapter"]=Chapters.for_owner(owner)
	var loop:=Engine.get_main_loop() as SceneTree
	if loop==null or loop.root==null:return out
	var state:Node=loop.root.get_node_or_null("GameState")
	if state!=null:
		var security:Variant=state.get("food_security")
		if security!=null:out.food=clampf(float(security),0.0,1.0)
		var known:Variant=state.get("known_discoveries")
		if known is Array:
			out.herds=(known as Array).has("animal_taming")
			out.fowl=(known as Array).has("yard_fowl_eggs")
	if state!=null:
		# the dead the ledger holds as put to death at the god's word
		var causes:Variant=state.get("death_cause_days")
		var today:=floori(float(state.get("elapsed_days"))) if state.get("elapsed_days")!=null else 0
		if causes is Array:
			var dead:=executions_from(causes as Array,today)
			out.executions=dead.executions;out.execution_days=dead.execution_days
		# every execution ever (the window above forgets after 400 days)
		var ever:Variant=state.get("executions_total")
		if ever!=null:out.executions=maxi(int(out.get("executions",0)),int(ever))
		var statues:Variant=state.get("court_statues")
		if statues is Array and not (statues as Array).is_empty():out.statues=(statues as Array).duplicate(true)
	var voice:=load("res://scripts/character_voice.gd")
	if voice!=null and voice.has_method("era_tier"):
		var tags:Variant=voice.call("era_tags",owner)
		out.era_tags=Array(tags) if tags is Array else []
		out.tier=int(voice.call("era_tier",tags))
	return out
