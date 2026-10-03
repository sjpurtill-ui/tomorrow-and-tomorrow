extends Node3D
## The court's set: a modelled place for the people to stand before their god,
## made in Blender by tools/blender/court_set.py (assets/court_sets/), lit by
## the sky, the sun and the fire, with smoke and sparks rising and dust in the
## light. The court grows with the people: a ring of logs about a fire under
## the open sky for the earliest bands, a long timber hall once they have
## chiefs, and on (kind_for maps the court's civic stage and era to a set;
## a set not built yet falls back to the nearest one that is).
##   CourtSet.build(era_id, facts) -> this node, with
##     marks      Marker3D under "Marks": throne_gaze (where the god's
##                presence is), petitioner, officials_*, crowd_*, envoy_*,
##                fire, door, door_out, animal_*. A mark's +Z faces the way a
##                person there faces (the figures' front is +Z); sit marks
##                carry meta "seat" (the seat's height; the figure's own stool
##                is not needed there).
##     camera     a CourtCamera (court_camera.gd) framed for this set
##     lights     the sun (the one shadowed light), the fire (flickering),
##                a warm bounce from the ground, the door's daylight in a hall
##     props      shown from the facts: food in the baskets and on the rack
##                with the real stores, spears racked (more in war)
##     animals    a dog in every age; herd animals and fowl once the people
##                keep them (court_animal_3d.gd)
## Facts (all optional): food 0..1 (how full the stores are), war (bool or
## 0..1), tier (the era's tier 0..4), herds (animals tamed), fowl (yard fowl
## kept), dread 0..1, dyes (the people's three cloth colours, hex), seed.
## Presentation only: nothing here reads or changes the game's state except
## facts_from_game(), which only reads. Nothing is allocated per frame; the
## set stops processing when it is hidden (set_active).

const DIR:="res://assets/court_sets/"
const MANIFEST:=DIR+"court_sets.json"
const CourtCamera:=preload("res://scripts/hud/court_camera.gd")
const Animal:=preload("res://scripts/hud/court_animal_3d.gd")
const TOON:=preload("res://assets/court_sets/shaders/court_set_toon.gdshader")
const GROUND:=preload("res://assets/court_sets/shaders/court_set_ground.gdshader")
const INK:=preload("res://assets/court_sets/shaders/court_set_ink.gdshader")
const FLAME:=preload("res://assets/court_sets/shaders/court_flame.gdshader")
const SMOKE:=preload("res://assets/court_sets/shaders/court_smoke.gdshader")
const EMBER:=preload("res://assets/court_sets/shaders/court_ember.gdshader")
const MOTE:=preload("res://assets/court_sets/shaders/court_mote.gdshader")
const SHAFT:=preload("res://assets/court_sets/shaders/court_shaft.gdshader")
const CONTACT:=preload("res://assets/court_sets/shaders/court_contact.gdshader")
const SKY:=preload("res://assets/court_sets/shaders/court_sky.gdshader")
const PAPER:=preload("res://assets/court_sets/shaders/court_paper.gdshader")

## The court's civic stage (data/civic/civic_stages.json: its id or its scene)
## to the set it stands in. Early bands in the open; a shelter once the
## people settle; the chief's long hall; then halls of brick and stone.
const KIND_BY_STAGE:={
	"hearth_council":"fire_ring","fire_circle":"fire_ring",
	"elders_circle":"shelter","elders_ring":"shelter",
	"chiefs_hall":"longhouse",
	"temple_palace":"mudbrick_hall","palace_bureaucracy":"mudbrick_hall","palace_hall":"mudbrick_hall",
	"citizen_assembly":"grand_hall","assembly_tiers":"grand_hall","imperial_court":"grand_hall","imperial_hall":"grand_hall",
	"senate_house":"grand_hall","council_house":"grand_hall","late_antique_hall":"grand_hall","basilica":"grand_hall",
	"feudal_hall":"grand_hall","great_hall":"grand_hall","chancery_court":"grand_hall","chancery":"grand_hall",
	"chartered_commune":"grand_hall","commune_hall":"grand_hall","estates_assembly":"grand_hall","estates_hall":"grand_hall",
}
## When a set is not built yet, the one that stands in for it.
const STAND_IN:={"shelter":"fire_ring","mudbrick_hall":"longhouse","grand_hall":"mudbrick_hall"}
## The era tiers (court_backdrop.gd's) where no civic stage says otherwise.
const KIND_BY_TIER:=["fire_ring","longhouse","mudbrick_hall","grand_hall","grand_hall"]

## Each slot's paint: [colour, worn colour]. The figures' dyes tint blankets.
const PALETTE:={
	"BARK":["4a3829","5a4634"],"WOOD":["7a5c40","957452"],"WOOD_END":["a38a66","b09572"],
	"CHAR":["1e1712","2a2019"],"ASH":["7d776f","8e877d"],"EMBER":["6a2a12","6a2a12"],
	"STONE":["6c655b","7a7266"],"HIDE":["8c6744","9c7752"],"HIDE_DARK":["5c4230","6a4e3a"],
	"CORD":["4e3a29","4e3a29"],"REED":["94804f","a38e5c"],"THATCH":["6e5838","7a6340"],
	"CLAY":["985a37","a66a45"],"MUD":["86704f","6c573d"],"PLANK":["6b5039","7f6249"],
	"FOOD_ROOT":["8a5e38","8a5e38"],"FOOD_GRAIN":["b99a58","b99a58"],"MEAT":["5c2a1f","5c2a1f"],
	"FISH":["948a74","948a74"],"BONE":["cfc3a6","cfc3a6"],"OCHRE":["9a4428","9a4428"],
	"FLINT":["45424a","514e55"],"LEAF":["3b4628","485332"],"GRASS":["5b6634","70714a"],
	"HILL_NEAR":["6d7656","6d7656"],"HILL_FAR":["8d9897","8d9897"],"BERRY":["4a2224","4a2224"],"SOOT":["4a443e","56504a"],
	"BLANKET":["7e4230","7e4230"],
}
## How each kind of set is lit and aired.
const LOOK:={
	"fire_ring":{"ambient":"7f8fa6","ambient_energy":0.5,"sun":"ffd9aa","fog":"b4c0c2","fog_density":0.002,
		"grass":"5c6a36","grass_dry":"7c784a","earth":"7a634a","earth_dark":"574535","straw":0.0,"exposure":0.95,
		"sky_top":"6f8eaa","sky_horizon":"e6dcc0","haze":"aebfc6"},
	"longhouse":{"ambient":"6e5c4c","ambient_energy":0.3,"sun":"ffe2b8","fog":"4e4034","fog_density":0.012,
		"grass":"5c6a36","grass_dry":"7c784a","earth":"6c5640","earth_dark":"4b3b2c","straw":0.22,"exposure":1.0,
		"sky_top":"6f8eaa","sky_horizon":"d9d2bd","haze":"b9c0bd"},
}

static var enabled:=true
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
var camera:Camera3D
var sun:DirectionalLight3D
var fire_light:OmniLight3D
var fire_light_b:OmniLight3D
var bounce:OmniLight3D
var door_light:SpotLight3D
var world_env:WorldEnvironment
var model:Node3D
var animals:Array=[]
var props:Dictionary={}
var particles:Array[GPUParticles3D]=[]
var active:=true
var _noise:=FastNoiseLite.new()
var _clock:=0.0
var _fire_energy:=2.0
var _fire_at:=Vector3.ZERO
var _fire_b_at:=Vector3.ZERO
var _shaft_top:=Vector3.ZERO
var _shaft_dir:=Vector3.DOWN
var _shaft_radius:=0.0

# --- Building ---------------------------------------------------------------------

static func manifest()->Dictionary:
	if _manifest.is_empty():
		var text:=FileAccess.get_file_as_string(MANIFEST)
		var parsed:Variant=JSON.parse_string(text) if not text.is_empty() else null
		_manifest=parsed if parsed is Dictionary else {"sets":{}}
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
static func kind_for(era_id_in:String,tier:=-1)->String:
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

func _build(era_id_in:String,facts_in:Dictionary)->void:
	era_id=era_id_in
	facts=facts_in.duplicate()
	kind=kind_for(era_id,int(facts.get("tier",-1)))
	name="CourtSet_"+kind
	info=(manifest().get("sets",{}) as Dictionary).get(kind,{})
	_noise.seed=int(facts.get("seed",11));_noise.frequency=1.0
	var packed:=scene_for(kind)
	if packed!=null:
		model=packed.instantiate() as Node3D
		model.name="Model"
		add_child(model)
		_dress(model)
		_collect_props(model)
	_make_marks()
	_make_environment()
	_make_lights()
	_make_fire()
	_make_air()
	camera=CourtCamera.new()
	add_child(camera)
	camera.configure(info.get("camera",{}))
	camera.current=true
	_make_paper()
	apply_facts(facts)
	_place_animals()
	visibility_changed.connect(func()->void:set_active(is_visible_in_tree()))

# --- Materials ----------------------------------------------------------------------

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
		var far:=part in ["Hills","HillsFar","Trees","Shrubs"]
		mesh_node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if part in ["Ground","Grass","Hills","HillsFar","Trees","Debris"] else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		if mesh_node.mesh==null:continue
		for surface in mesh_node.mesh.get_surface_count():
			var source:=mesh_node.mesh.surface_get_material(surface)
			var slot:=source.resource_name if source!=null else "WOOD"
			if part=="Ground":
				mesh_node.set_surface_override_material(surface,_ground_material())
			else:
				mesh_node.set_surface_override_material(surface,_material(slot,inked and not far))

func _material(slot:String,inked:bool)->ShaderMaterial:
	var key:="%s|%s|%s|%s" % [kind,slot,inked,_dye_key()]
	if _materials.has(key):return _materials[key]
	var look:Dictionary=LOOK.get(kind,LOOK.fire_ring)
	var paint:Array=PALETTE.get(slot,["8a7a66","8a7a66"])
	var made:=ShaderMaterial.new();made.shader=TOON
	var base:=Color(String(paint[0]));var worn:=Color(String(paint[1]))
	if slot=="BLANKET" and facts.has("dyes") and (facts.dyes as Array).size()>0:
		base=Color(String((facts.dyes as Array)[0])).lerp(base,0.35);worn=base
	made.set_shader_parameter("albedo",base)
	made.set_shader_parameter("albedo_worn",worn)
	made.set_shader_parameter("haze_color",Color(String(look.get("haze","cdd2cf"))))
	match slot:
		"EMBER":
			made.set_shader_parameter("emission_amount",2.4);made.set_shader_parameter("emission_flicker",0.6)
		"GRASS","LEAF":
			made.set_shader_parameter("wrap",0.35);made.set_shader_parameter("mottle",0.18);made.set_shader_parameter("variation",0.2)
			made.set_shader_parameter("haze_max",0.6);made.set_shader_parameter("haze_start",14.0);made.set_shader_parameter("haze_end",90.0)
		"HILL_NEAR":
			made.set_shader_parameter("haze_max",0.55);made.set_shader_parameter("haze_start",30.0);made.set_shader_parameter("haze_end",110.0)
			made.set_shader_parameter("mottle",0.14);made.set_shader_parameter("mottle_scale",0.05)
		"HILL_FAR":
			made.set_shader_parameter("haze_max",0.8);made.set_shader_parameter("haze_start",60.0);made.set_shader_parameter("haze_end",200.0)
			made.set_shader_parameter("mottle",0.1);made.set_shader_parameter("mottle_scale",0.03)
		"HIDE","HIDE_DARK","BLANKET":
			made.set_shader_parameter("wrap",0.2);made.set_shader_parameter("mottle",0.16);made.set_shader_parameter("variation",0.22)
		"THATCH","MUD","PLANK":
			made.set_shader_parameter("mottle",0.16)
	if slot in ["BARK","WOOD","STONE","HIDE","HIDE_DARK","REED","CLAY","PLANK","THATCH"]:
		made.set_shader_parameter("haze_max",0.5);made.set_shader_parameter("haze_start",22.0);made.set_shader_parameter("haze_end",80.0)
	if inked:made.next_pass=_ink()
	_materials[key]=made
	return made

func _dye_key()->String:
	return String((facts.get("dyes",[""]) as Array)[0]) if facts.get("dyes",[]) is Array and not (facts.get("dyes",[]) as Array).is_empty() else ""

static func _ink()->ShaderMaterial:
	if _ink_material==null:
		_ink_material=ShaderMaterial.new();_ink_material.shader=INK
	return _ink_material

func _ground_material()->ShaderMaterial:
	var key:="%s|GROUND" % kind
	if _materials.has(key):return _materials[key]
	var look:Dictionary=LOOK.get(kind,LOOK.fire_ring)
	var made:=ShaderMaterial.new();made.shader=GROUND
	made.set_shader_parameter("grass",Color(String(look.grass)))
	made.set_shader_parameter("grass_dry",Color(String(look.grass_dry)))
	made.set_shader_parameter("earth",Color(String(look.earth)))
	made.set_shader_parameter("earth_dark",Color(String(look.earth_dark)))
	made.set_shader_parameter("straw",float(look.straw))
	made.set_shader_parameter("haze_color",Color(String(look.haze)))
	var fx:Dictionary=info.get("fx",{})
	var fire:Dictionary=fx.get("fire",{})
	var long:=float(fire.get("long",0.0))
	made.set_shader_parameter("hearth_radius",0.95 if long<=0.0 else 1.0)
	made.set_shader_parameter("hearth_scale",Vector2(maxf(1.0,long*0.62),0.75 if long>0.0 else 1.0))
	_materials[key]=made
	return made

# --- Marks --------------------------------------------------------------------------

func _make_marks()->void:
	var holder:=Node3D.new();holder.name="Marks";add_child(holder)
	var raw:Dictionary=info.get("marks",{})
	var throne:=_vec(raw.get("throne_gaze",{}).get("pos",[0,2,6]))
	var fire:=_vec(raw.get("fire",{}).get("pos",[0,0,0]))
	var names:Array=raw.keys();names.sort()
	for mark_name:String in names:
		var entry:Dictionary=raw[mark_name]
		var at:=_vec(entry.get("pos",[0,0,0]))
		var target:=throne
		var face:Variant=entry.get("face","throne")
		if face is String:
			match String(face):
				"fire":target=fire
				"door":target=_vec(raw.get("door",{}).get("pos",[0,0,0]))
				_:target=throne
		elif face is Array and (face as Array).size()>=2:target=Vector3(float(face[0]),0.0,float(face[1]))
		var m:=Marker3D.new();m.name=mark_name
		var dir:=Vector3(target.x-at.x,0.0,target.z-at.z)
		var basis:=Basis.IDENTITY
		if dir.length()>0.01:basis=Basis.looking_at(-dir.normalized(),Vector3.UP)
		m.transform=Transform3D(basis,at)
		m.set_meta("sit",bool(entry.get("sit",false)))
		m.set_meta("seat",float(entry.get("seat",0.0)))
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

## Stand someone (or something) on a mark, facing the way the mark faces.
func place(node:Node3D,mark_name:String)->void:
	var m:=mark(mark_name)
	if m==null or node==null:return
	node.global_transform=Transform3D(m.global_transform.basis.orthonormalized()*Basis.from_scale(node.global_transform.basis.get_scale()),m.global_position)

## Where the god's presence is (people look up to it).
func god_point()->Vector3:
	var m:=mark("throne_gaze")
	return m.global_position if m!=null else Vector3(0.0,2.3,5.5)

# --- Light and air ------------------------------------------------------------------

func _make_environment()->void:
	var look:Dictionary=LOOK.get(kind,LOOK.fire_ring)
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
	env.fog_light_color=Color(String(look.fog))
	env.fog_density=float(light.get("fog",look.fog_density))
	env.fog_sky_affect=0.0
	env.fog_sun_scatter=0.0
	env.adjustment_enabled=true
	env.adjustment_saturation=0.94
	env.adjustment_contrast=1.04
	world_env=WorldEnvironment.new();world_env.name="Air";world_env.environment=env
	add_child(world_env)

func _make_lights()->void:
	var look:Dictionary=LOOK.get(kind,LOOK.fire_ring)
	var light:Dictionary=info.get("light",{})
	var fx:Dictionary=info.get("fx",{})
	sun=DirectionalLight3D.new();sun.name="Sun"
	var dir:=_vec(light.get("sun_dir",[-0.45,-0.62,-0.64])).normalized()
	sun.transform=Transform3D(Basis.looking_at(dir,Vector3.UP if absf(dir.y)<0.98 else Vector3.FORWARD),Vector3.ZERO)
	sun.light_color=Color(String(look.sun))
	sun.light_energy=float(light.get("sun_energy",1.3))
	sun.shadow_enabled=true
	sun.directional_shadow_mode=DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sun.directional_shadow_max_distance=30.0
	sun.directional_shadow_blend_splits=true
	sun.shadow_bias=0.04
	sun.shadow_normal_bias=1.2
	sun.shadow_blur=1.4
	sun.light_angular_distance=1.2
	add_child(sun)
	var fire:Dictionary=fx.get("fire",{})
	_fire_at=_vec(fire.get("pos",[0,0,0]))+Vector3(0.0,0.85,0.0)
	_fire_energy=float(light.get("fire_energy",2.2))
	var long:=float(fire.get("long",0.0))
	fire_light=_omni("Fire",Color(1.0,0.58,0.30),_fire_energy,float(light.get("fire_range",7.0)),1.5)
	if long>0.0:
		_fire_b_at=_fire_at+Vector3(long*0.3,0.0,0.0);_fire_at-=Vector3(long*0.3,0.0,0.0)
		fire_light_b=_omni("FireB",Color(1.0,0.58,0.30),_fire_energy*0.8,float(light.get("fire_range",7.0)),1.5)
		fire_light_b.position=_fire_b_at
	fire_light.position=_fire_at
	bounce=_omni("Bounce",Color(1.0,0.72,0.48),0.45,4.8,1.0)
	bounce.position=_vec(fire.get("pos",[0,0,0]))+Vector3(0.0,0.12,0.9)
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

## The fire's flames (cards turned to the camera, drawn by a shader), its
## smoke and its sparks.
func _make_fire()->void:
	var fx:Dictionary=info.get("fx",{})
	var fire:Dictionary=fx.get("fire",{})
	var at:=_vec(fire.get("pos",[0,0.05,0]))
	var size:=float(fire.get("size",1.0))
	var long:=float(fire.get("long",0.0))
	var holder:=Node3D.new();holder.name="Fire";add_child(holder);holder.position=at
	var spots:Array[Vector3]=[Vector3.ZERO]
	if long>0.0:spots=[Vector3(-long*0.32,0,0.02),Vector3(-long*0.05,0,-0.05),Vector3(long*0.22,0,0.04)]
	var index:=0
	for spot in spots:
		for k in 3:
			var card:=MeshInstance3D.new();card.name="Flame%d" % index
			var quad:=QuadMesh.new();quad.size=Vector2(1.0,1.0);card.mesh=quad
			var mat:=ShaderMaterial.new();mat.shader=FLAME
			mat.set_shader_parameter("seed",float(index)*1.37)
			mat.set_shader_parameter("speed",0.9+0.15*k)
			mat.set_shader_parameter("strength",1.0 if k==0 else 0.75)
			card.material_override=mat
			card.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			var h:=(1.05-0.22*k)*size*(0.8 if long>0.0 else 1.0)
			var w:=(0.62-0.1*k)*size
			card.scale=Vector3(w,h,1.0)
			card.position=spot+Vector3((k-1)*0.09*size,h*0.5+0.02,(k%2)*0.06-0.03)
			holder.add_child(card)
			index+=1
	var top:=float(fx.get("smoke_top",8.0))-at.y
	# smoke
	var smoke:=GPUParticles3D.new();smoke.name="Smoke"
	smoke.amount=26 if long<=0.0 else 34
	smoke.lifetime=7.0 if long<=0.0 else 6.0
	smoke.preprocess=6.0
	smoke.randomness=0.4
	var sm:=ParticleProcessMaterial.new()
	sm.emission_shape=ParticleProcessMaterial.EMISSION_SHAPE_BOX
	sm.emission_box_extents=Vector3(maxf(0.2,long*0.4),0.1,0.18)
	sm.direction=Vector3(0,1,0);sm.spread=10.0
	sm.initial_velocity_min=0.35;sm.initial_velocity_max=0.6
	sm.gravity=Vector3(0.06,0.10,-0.04) if long<=0.0 else Vector3(0.0,0.06,-0.08)
	sm.damping_min=0.05;sm.damping_max=0.15
	sm.scale_min=0.55;sm.scale_max=0.9
	var curve:=Curve.new();curve.add_point(Vector2(0.0,0.35));curve.add_point(Vector2(1.0,2.8 if long<=0.0 else 2.2))
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
	var puff:=QuadMesh.new();puff.size=Vector2(1.0,1.0)
	var smoke_mat:=ShaderMaterial.new();smoke_mat.shader=SMOKE
	smoke_mat.set_shader_parameter("fire_y",at.y)
	smoke_mat.set_shader_parameter("opacity",0.2 if long<=0.0 else 0.17)
	puff.material=smoke_mat
	smoke.draw_pass_1=puff
	smoke.position=Vector3(0,0.75,0)
	smoke.visibility_aabb=AABB(Vector3(-4,-1,-4),Vector3(8,maxf(top,4.0)+2.0,8))
	smoke.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	holder.add_child(smoke);particles.append(smoke)
	# sparks
	var sparks:=GPUParticles3D.new();sparks.name="Embers"
	sparks.amount=18;sparks.lifetime=2.4;sparks.preprocess=3.0;sparks.randomness=0.6
	var em:=ParticleProcessMaterial.new()
	em.emission_shape=ParticleProcessMaterial.EMISSION_SHAPE_BOX
	em.emission_box_extents=Vector3(maxf(0.2,long*0.4),0.05,0.2)
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

## Dust in the light, and in a hall the sun's shaft through the smoke hole.
func _make_air()->void:
	var fx:Dictionary=info.get("fx",{})
	var light:Dictionary=info.get("light",{})
	if fx.has("smoke_hole"):
		_shaft_top=_vec(fx.smoke_hole)
		_shaft_dir=_vec(light.get("sun_dir",[0,-1,0])).normalized()
		_shaft_radius=0.62
		var length:=(_shaft_top.y-0.0)/maxf(0.2,-_shaft_dir.y)
		var shaft:=MeshInstance3D.new();shaft.name="SunShaft"
		var cyl:=CylinderMesh.new();cyl.top_radius=_shaft_radius*0.9;cyl.bottom_radius=_shaft_radius*1.15;cyl.height=1.0
		cyl.radial_segments=20;cyl.rings=1;cyl.cap_top=false;cyl.cap_bottom=false
		shaft.mesh=cyl
		var mat:=ShaderMaterial.new();mat.shader=SHAFT
		shaft.material_override=mat
		shaft.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		# the cylinder's y runs along the shaft, top at the hole
		var y_axis:=-_shaft_dir
		var x_axis:=y_axis.cross(Vector3.FORWARD).normalized()
		var z_axis:=x_axis.cross(y_axis).normalized()
		shaft.transform=Transform3D(Basis(x_axis,y_axis*length,z_axis),_shaft_top+_shaft_dir*length*0.5)
		add_child(shaft)
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

# --- Props from the facts -----------------------------------------------------------

func _collect_props(root:Node)->void:
	var groups:Dictionary=info.get("props",{})
	for group:String in ["food","rack","spears"]:
		var list:Array[Node3D]=[]
		for prop_name:String in groups.get(group,[]):
			var found:=root.find_child(prop_name,true,false) as Node3D
			if found!=null:list.append(found)
		props[group]=list

## Dress the set from the facts: the stores' food in the baskets and on the
## rack, the spears racked (a few in peace, all of them in war).
func apply_facts(facts_in:Dictionary)->void:
	for key in facts_in.keys():facts[key]=facts_in[key]
	var food:=clampf(float(facts.get("food",0.6)),0.0,1.0)
	var war_raw:Variant=facts.get("war",0.0)
	var war:=1.0 if war_raw is bool and war_raw else (clampf(float(war_raw),0.0,1.0) if not war_raw is bool else 0.0)
	_show_first(props.get("food",[]),roundi(food*float((props.get("food",[]) as Array).size())))
	_show_first(props.get("rack",[]),roundi(clampf(food*1.25-0.1,0.0,1.0)*float((props.get("rack",[]) as Array).size())))
	var spears:Array=props.get("spears",[])
	var peace:=int((info.get("props",{}) as Dictionary).get("spears_peace",3))
	_show_first(spears,mini(spears.size(),peace+roundi(war*float(maxi(0,spears.size()-peace)))))

## How many of a prop group are showing (tests, the director).
func shown(group:String)->int:
	var count:=0
	for node in props.get(group,[]):
		if (node as Node3D).visible:count+=1
	return count

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
	for p in particles:
		if is_instance_valid(p):
			p.emitting=on
			p.speed_scale=1.0 if on else 0.0
	for beast in animals:
		if is_instance_valid(beast):beast.call("set_active",on)

func _ready()->void:
	set_process(active)

func _process(delta:float)->void:
	_clock+=delta
	# the fire breathes: two noises, a quick one and a slow one
	var n:=_noise.get_noise_1d(_clock*6.0)*0.55+_noise.get_noise_1d(_clock*17.0+40.0)*0.3+_noise.get_noise_1d(_clock*1.3+90.0)*0.15
	fire_light.light_energy=_fire_energy*(1.0+0.22*n)
	fire_light.position=_fire_at+Vector3(n*0.05,absf(n)*0.06,_noise.get_noise_1d(_clock*5.0+7.0)*0.05)
	if fire_light_b!=null:
		var m:=_noise.get_noise_1d(_clock*6.5+300.0)
		fire_light_b.light_energy=_fire_energy*0.8*(1.0+0.2*m)
		fire_light_b.position=_fire_b_at+Vector3(m*0.05,absf(m)*0.05,0.0)
	bounce.light_energy=0.45*(1.0+0.12*n)

## Which way the strongest light comes from (toward it), for figures whose
## shading takes one key light (court_figure_3d.gd set_key_light).
func key_dir()->Vector3:
	if sun==null:return Vector3(-0.35,0.65,0.68)
	var to_sun:=sun.global_transform.basis.z.normalized()
	if bool((info.get("light",{}) as Dictionary).get("open_sky",true)):return to_sun
	# in a hall the fire and the shaft share the key: from above, a little forward
	return (to_sun*0.6+Vector3(0.0,0.55,0.55)).normalized()

## How much light falls on someone standing here, about 1 (figure dim): the
## hall is dimmer than the open sky, the fire warms those close to it and the
## sun's shaft lights whoever stands in it.
func light_at(point:Vector3)->float:
	var open:=bool((info.get("light",{}) as Dictionary).get("open_sky",true))
	var amount:=1.0 if open else 0.84
	var to_fire:=Vector2(point.x-_fire_at.x,point.z-_fire_at.z).length()
	if not open:amount+=0.10*clampf(1.0-(to_fire-1.0)/3.0,0.0,1.0)
	if _shaft_radius>0.0:
		var rel:=point+Vector3(0.0,1.2,0.0)-_shaft_top
		var along:=rel.dot(_shaft_dir)
		var off:=(rel-_shaft_dir*along).length()
		amount+=0.18*clampf(1.0-(off-_shaft_radius*0.5)/_shaft_radius,0.0,1.0)
	return amount

## A soft shade on the ground under someone's feet (blend: multiply), to lay
## under a figure or an animal: it keeps them standing ON the ground.
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

## What the stage can pass in, read from the game (read-only): how full the
## stores are, whether the people are at war, their era's tier, and which
## animals they keep.
static func facts_from_game(owner:="player")->Dictionary:
	var out:={"food":0.6,"war":false,"tier":0,"herds":false,"fowl":false,"dogs":true}
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
	var voice:=load("res://scripts/character_voice.gd")
	if voice!=null and voice.has_method("era_tier"):
		out.tier=int(voice.call("era_tier",voice.call("era_tags",owner)))
	return out
