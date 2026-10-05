extends Control
## A bounded, presentation-only gathering at the recorded work. The ordinary
## court supplies identity, dress, bodies and acting; dedication stays in its
## existing engine ledger. No material stock or person is created here.
const Court=preload("res://scripts/hud/court_stage.gd")
const Figure=preload("res://scripts/hud/court_figure_3d.gd")
const Acting=preload("res://scripts/hud/court_acting.gd")
const Presentation=preload("res://scripts/hud/court_presentation.gd")
const Stages=preload("res://scripts/civic_stages.gd")
const Voice=preload("res://scripts/character_voice.gd")
const Tokens=preload("res://scripts/hud/hud_tokens.gd")
const MODEL_PATH:="res://scripts/hud/great_work_model.gd"
const MAX_CAST:=6
static var _earth:StandardMaterial3D
var view:SubViewport
var world:Node3D
var lens:Camera3D
var image:TextureRect
var model:Node3D
var cast:Array[Dictionary]=[]
var bodies:Dictionary={}
var mode:="offering"
var committed:=false
var build_count:=0
var _bounds:=AABB(Vector3(-3,0,-3),Vector3(6,6,6))
var _front:=6.0
var _remaining:=0.0
var _moving:Tween
var _ritual:Tween
var _props:Node3D
var _opening:Array[Node3D]=[]
var _offering:Node3D
var _light:OmniLight3D
var _work:Dictionary={}
var _context:Dictionary={}
var _opening_started:=false
var _caption:Label
var _shot_kind:="gathering"

static func make(work:Dictionary,context:Dictionary,height:float=330.0)->Control:
	var made=load("res://scripts/hud/great_work_ceremony_stage.gd").new()
	made._work=work.duplicate(true);made._context=context.duplicate(true)
	made.custom_minimum_size=Vector2(240,height)
	return made

## Dates do not grant technology. A late, less-developed society still uses
## its own ritual and clothing; advanced lighting needs a known practice.
static func ritual_spec(known:Array,profile:Dictionary)->Dictionary:
	var period:=String(profile.get("period","early"))
	if period=="modern" and ("solid_state_lighting" in known or "electric_street_lighting" in known or "filament_lamp_works" in known):
		return {"mode":"illumination","label":"The opening light","action":"The people mark the opening with light."}
	if period in ["industrial","modern"] and String(profile.get("outfit","hide"))!="hide":
		return {"mode":"ribbon","label":"The ceremonial opening","action":"A ribbon marks the opening of the work."}
	if period in ["medieval","early_modern"] and String(profile.get("outfit","hide"))!="hide":
		return {"mode":"unveiling","label":"The unveiling","action":"A ceremonial cloth waits to be drawn aside."}
	return {"mode":"offering","label":"An offering before the gods","action":"Flowers and a stone wait beside the offering place."}

## Saved architects remain credited, but a recorded dead architect does not
## walk into the ceremony. Envoys are bounded representatives of attendees
## already in the ceremony ledger, using the same persona key as its voice.
static func cast_for(context:Dictionary)->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	var architect:Dictionary=context.get("architect",{})
	if not String(architect.get("name","")).is_empty():
		var actual:Dictionary=HistoricalFigures.by_id(String(architect.get("id","")))
		if actual.is_empty() or (String(actual.get("status","living"))!="dead" and int(actual.get("death_day",-1))<0):
			var person:=actual.duplicate(true) if not actual.is_empty() else architect.duplicate(true)
			person["civilization_id"]="player";person["title"]="Master Builder"
			if person.has("gender"):person["sex"]="female" if person.gender=="woman" else "male"
			if person.has("born"):person["age"]=maxi(0,(int(GameState.elapsed_days)-int(person.born))/365)
			result.append({"key":"architect","role":"architect","person":person})
	var official:Dictionary=context.get("official",{})
	if not official.is_empty():result.append({"key":"official","role":"official","person":official.duplicate(true)})
	var index:=0
	for attendee:Dictionary in context.get("attendees",[]):
		if index>=4:break
		var owner:=String(attendee.get("civ_id",""))
		if owner.is_empty():continue
		var persona:=Voice.for_envoy(owner,"dedication:%s:%d" % [String(context.get("key","")),index])
		var person:={"name":String(persona.name),"title":"Envoy of "+String(attendee.get("name","")),"civilization_id":owner,"appearance_civ_id":owner}
		result.append({"key":"envoy_%d" % index,"role":"envoy","civ_id":owner,"person":person})
		index+=1
	return result.slice(0,MAX_CAST)

func _ready()->void:
	name="WorkPlate";clip_contents=true;mouse_filter=Control.MOUSE_FILTER_IGNORE
	var profile:=Presentation.for_owner()
	mode=String(ritual_spec(Stages.known_for(),profile).mode)
	cast=cast_for(_context)
	view=SubViewport.new();view.name="Dedication3D";view.own_world_3d=true;view.msaa_3d=Viewport.MSAA_2X
	view.render_target_update_mode=SubViewport.UPDATE_DISABLED;add_child(view)
	world=Node3D.new();world.name="CeremonyWorld";view.add_child(world)
	image=TextureRect.new();image.texture=view.get_texture();image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image.stretch_mode=TextureRect.STRETCH_SCALE;image.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(image);image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_scene(profile)
	var caption_frame:=PanelContainer.new();caption_frame.name="CeremonyCaption";caption_frame.mouse_filter=Control.MOUSE_FILTER_IGNORE;caption_frame.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE);caption_frame.grow_vertical=Control.GROW_DIRECTION_BEGIN;caption_frame.add_theme_stylebox_override("panel",Tokens.paper_panel_style(true,0,10));add_child(caption_frame)
	_caption=Tokens.make_label(String(ritual_spec(Stages.known_for(),profile).action),16,Tokens.INK);_caption.add_theme_font_override("font",Tokens.voice_font());_caption.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;_caption.max_lines_visible=4;_caption.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;caption_frame.add_child(_caption)
	var whole:=Button.new();whole.name="SeeWholeWork";whole.text="See the whole work";whole.theme=Tokens.control_theme();whole.position=Vector2(8,8);whole.custom_minimum_size=Vector2(145,30);whole.add_theme_stylebox_override("normal",Tokens.paper_panel_style(true,2,6));whole.pressed.connect(show_work);add_child(whole)
	resized.connect(_resize_view);visibility_changed.connect(_visibility);_resize_view();_wake(7.0)

func _build_scene(profile:Dictionary)->void:
	build_count+=1
	if ResourceLoader.exists(MODEL_PATH):
		var product:Dictionary=load(MODEL_PATH).build(_work,{"plan":false,"workers":false,"ground":false})
		model=product.get("root") as Node3D
		if model!=null:
			model.name="CompletedMonument";world.add_child(model)
			_bounds=product.get("bounds",_bounds)
	# The model keeps its physical metres. The lens, forecourt and gathering
	# adapt to its bounds rather than shrinking a monument to person scale.
	_front=_bounds.end.z+3.0
	var ground_size:=maxf(maxf(_bounds.size.x,_bounds.size.z)+18.0,26.0)
	# One retained plane continues below both close and overview shots. Its
	# quiet grain gives the work a setting without inventing nearby buildings.
	var ground:=_box(world,"Forecourt",Vector3(ground_size*8.0,.15,ground_size*8.0),Vector3(_bounds.get_center().x,-.14,_bounds.get_center().z+3),Color.WHITE)
	ground.material_override=_earth_material()
	var earth:StandardMaterial3D=ground.material_override.duplicate();earth.uv1_scale=Vector3.ONE*(ground_size*8.0/10.0);ground.material_override=earth
	var env:=WorldEnvironment.new();var atmosphere:=Environment.new();atmosphere.background_mode=Environment.BG_COLOR;atmosphere.background_color=Color("aaa18e")
	atmosphere.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;atmosphere.ambient_light_color=Color("c3cbd0");atmosphere.ambient_light_energy=.30
	atmosphere.tonemap_mode=Environment.TONE_MAPPER_FILMIC;env.environment=atmosphere;world.add_child(env)
	var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-42,-35,0);sun.light_color=Color("fff1dc");sun.light_energy=.80;sun.shadow_enabled=true;world.add_child(sun)
	var registry:Dictionary={}
	for index in cast.size():
		var entry:Dictionary=cast[index];var person:Dictionary=entry.person
		var owner:=String(person.get("appearance_civ_id",person.get("civilization_id","player")))
		var look:=Court.figure_look(person,registry,profile if owner=="player" else Presentation.for_owner(owner))
		look["stance"]="stand";look["lit"]=true
		var body:=Figure.new();body.name="Guest_"+String(entry.key);world.add_child(body)
		if not body.setup(look):body.queue_free();continue
		var side:=-1.0 if index%2==0 else 1.0
		body.position=Vector3(side*(1.3+float(index/2)*1.05),0,_front+float(index/2)*.6)
		body.rotation_degrees.y=-side*18.0
		body.set_meta("ceremony_person",person.duplicate(true));bodies[entry.key]=body
		Acting.idle(body,"stand")
	_props=Node3D.new();_props.name="DedicationRitual";world.add_child(_props)
	_build_ritual()
	lens=Camera3D.new();lens.name="DedicationCamera";lens.fov=43;world.add_child(lens);lens.current=true
	_gathering()

func _build_ritual()->void:
	var at:=Vector3(0,0,_front+.8)
	match mode:
		"offering":
			_cylinder(_props,"OfferingStone",.58,.42,at+Vector3(0,.21,0),Color("777267"))
			_offering=Node3D.new();_offering.name="FlowersAndStone";_props.add_child(_offering);_offering.position=at+Vector3(0,.49,0)
			for i in 7:
				var angle:=float(i)*TAU/7.0
				_sphere(_offering,"Flower",.065,Vector3(cos(angle)*.2,.02,sin(angle)*.15),Color("e0c99f") if i%2==0 else Color("a47873"))
			_sphere(_offering,"DedicationStone",.11,Vector3(0,.03,0),Color("bbb3a0"))
			_offering.visible=false
			for i in 9:
				var a:=float(i)*TAU/9.0
				_sphere(_props,"HearthStone",.14,at+Vector3(-1.2+cos(a)*.38,.08,-.7+sin(a)*.38),Color("706c60"))
			var fire:=_sphere(_props,"HearthEmber",.2,at+Vector3(-1.2,.13,-.7),Color("e5a34f"));_emission(fire,Color("e59944"),.8)
		"ribbon","unveiling":
			for side in [-1.0,1.0]:
				_cylinder(_props,"CeremonyPost",.07,1.15,at+Vector3(side*1.1,.575,0),Color("775941"))
				var hinge:=Node3D.new();hinge.position=at+Vector3(side*1.1,1.02,0);_props.add_child(hinge)
				_box(hinge,"Ribbon" if mode=="ribbon" else "UnveilingCloth",Vector3(1.1,.12 if mode=="ribbon" else .9,.025),Vector3(-side*.55,-.05 if mode=="ribbon" else -.36,0),Color("954c40"))
				_opening.append(hinge)
			if mode=="ribbon":
				# The tool is a ceremonial prop, never credited as a produced good.
				var scissors:=Node3D.new();scissors.name="OpeningShears";scissors.position=at+Vector3(0,1.07,.06);_props.add_child(scissors)
				for angle in [-.3,.3]:
					var blade:=_box(scissors,"Blade",Vector3(.025,.28,.018),Vector3(0,.05,0),Color("c3c9c8"));blade.rotation.z=angle
		"illumination":
			for side in [-1.0,1.0]:
				var lamp:=_box(_props,"OpeningLight",Vector3(.08,1.1,.08),at+Vector3(side*1.4,.55,0),Color("687e81"));_emission(lamp,Color("95d6d4"),.15);_opening.append(lamp)
			_box(_props,"OpeningLectern",Vector3(.55,.85,.35),at+Vector3(0,.425,.4),Color("495759"))
	_light=OmniLight3D.new();_light.name="DedicationLight";_light.position=at+Vector3(0,1.3,-1);_light.omni_range=12;_light.light_color=Color("eab86d") if mode=="offering" else Color("a8dad9");_light.light_energy=.4 if mode=="offering" else .0;_props.add_child(_light)

func speak(line:Dictionary,animate:=true)->void:
	if _caption!=null:_caption.text=(String(line.get("speaker",""))+": " if not String(line.get("speaker","")).is_empty() else "")+String(line.get("text",""))
	var key:=String(line.get("role",""))
	if key=="envoy":
		for member:Dictionary in cast:
			if String(member.get("civ_id",""))==String(line.get("civ_id","")):key=String(member.key);break
	var body:Node3D=bodies.get(key)
	if body==null:return
	var text:=String(line.get("text",""));var duration:=clampf(float(text.length())*.025,1.8,5.0)
	Acting.speak(body,text,duration)
	for listener:Node3D in bodies.values():
		if listener!=body:Acting.attend(listener,body.global_position+Vector3(0,1.5,0),duration,.5)
	_shot_kind="speaker"
	_shot(body.position+Vector3(0,1.1,0),body.position+Vector3(4.4,2.8,7.8),.85 if animate else 0.0)
	_wake(duration+1.0)

## Only called after GreatWorks.dedicate returned success. Replaying this
## animation cannot receive a gift or append another event to the ledger.
func dedication()->void:
	if committed:return
	committed=true;_opening_started=true
	if _caption!=null:_caption.text="Flowers and a stone are laid before the work." if mode=="offering" else ("The ribbon is cut. The work is dedicated." if mode=="ribbon" else ("The cloth is drawn aside. The work is dedicated." if mode=="unveiling" else "The opening lights rise. The work is dedicated."))
	if _ritual!=null and _ritual.is_valid():_ritual.kill()
	_ritual=create_tween().set_parallel(true)
	if mode=="offering" and _offering!=null:
		_offering.visible=true;var destination:=_offering.position;_offering.position+=Vector3(.45,.65,.45)
		_ritual.tween_property(_offering,"position",destination,1.4).set_trans(Tween.TRANS_SINE)
	elif mode in ["ribbon","unveiling"]:
		for index in _opening.size():_ritual.tween_property(_opening[index],"rotation:z",-.85 if index==0 else .85,1.3).set_trans(Tween.TRANS_SINE)
		var tool:=_props.get_node_or_null("OpeningShears")
		if tool!=null:tool.visible=false
	else:
		for lamp:Node3D in _opening:
			var material:StandardMaterial3D=(lamp as MeshInstance3D).material_override
			_ritual.tween_property(material,"emission_energy_multiplier",2.0,1.6)
	_ritual.tween_property(_light,"light_energy",2.0 if mode=="illumination" else 1.0,1.6)
	for body:Node3D in bodies.values():Acting.play(body,"bow_shallow" if mode=="offering" else "clap_soft")
	_shot_kind="ritual"
	_shot(Vector3(0,1.0,_front+.5),Vector3(6,4,_front+10),1.0)
	_wake(5.0)

func settle()->void:
	if _moving!=null and _moving.is_valid():_moving.custom_step(20.0)
	if _ritual!=null and _ritual.is_valid():_ritual.custom_step(20.0)
	_remaining=0.0;_set_active(false)

func show_work()->void:
	_shot_kind="work";_wide();_wake(1.2)

func _gathering()->void:
	_shot_kind="gathering"
	_shot(Vector3(0,1.8,_front-1.5),Vector3(6.5,4.2,_front+11),0.0)

func _shot(target:Vector3,from:Vector3,seconds:float)->void:
	if lens==null:return
	if _moving!=null and _moving.is_valid():_moving.kill()
	var destination:=Transform3D(Basis.looking_at(target-from,Vector3.UP),from)
	if seconds<=0:lens.transform=destination
	else:
		_moving=create_tween();_moving.tween_property(lens,"transform",destination,seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _wide(animate:=true)->void:
	if lens==null:return
	var aspect:=maxf(.7,size.x/maxf(size.y,1.0))
	# Fit all three dimensions from the same elevated three-quarter angle.
	# Using height alone for elevation flattened broad rings into a thin strip.
	var framing:=_bounds.merge(AABB(Vector3(-4,0,_front),Vector3(8,2.1,3)))
	var target:=framing.get_center()
	var outward:=Vector3(.85,.90,1.15).normalized()
	var basis:=Basis.looking_at(-outward,Vector3.UP)
	var tangent:=tan(deg_to_rad(lens.fov)*.5)
	var distance:=4.0
	for corner_index in 8:
		var point:=basis.transposed()*(framing.get_endpoint(corner_index)-target)
		distance=maxf(distance,point.z+maxf(absf(point.x)/(tangent*aspect*.85),absf(point.y)/(tangent*.78)))
	_shot(target,target+outward*distance,1.0 if animate else 0.0)

func _resize_view()->void:
	if view==null:return
	var factor:=minf(1.0,1400.0/maxf(size.x,1.0))
	view.size=Vector2i(maxi(64,roundi(size.x*factor)),maxi(64,roundi(size.y*factor)))
	if _shot_kind=="work":_wide(false)
	elif _shot_kind=="gathering":_gathering()
	_wake(.15)

func _wake(seconds:float)->void:
	_remaining=maxf(_remaining,seconds);_visibility()

func _visibility()->void:
	_set_active(is_visible_in_tree() and _remaining>0.0)

func _set_active(active:bool)->void:
	if view==null:return
	view.render_target_update_mode=SubViewport.UPDATE_ALWAYS if active else (SubViewport.UPDATE_ONCE if is_visible_in_tree() else SubViewport.UPDATE_DISABLED)
	world.process_mode=Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
	if _moving!=null and _moving.is_valid():
		if active:_moving.play()
		else:_moving.pause()
	if _ritual!=null and _ritual.is_valid():
		if active:_ritual.play()
		else:_ritual.pause()
	set_process(active)

func _process(delta:float)->void:
	_remaining=maxf(0.0,_remaining-delta)
	if _remaining<=0.0:_set_active(false)

func diagnostics()->Dictionary:
	return {"mode":mode,"cast_count":cast.size(),"cast_keys":cast.map(func(member:Dictionary)->String:return String(member.key)),"body_count":bodies.size(),"model_node_id":model.get_instance_id() if is_instance_valid(model) else 0,"mesh_count":model.find_children("*","MeshInstance3D",true,false).size() if is_instance_valid(model) else 0,"viewport_active":view!=null and view.render_target_update_mode==SubViewport.UPDATE_ALWAYS,"committed":committed,"build_count":build_count,"camera_shot":_shot_kind}

static func _material(colour:Color)->StandardMaterial3D:
	var material:=StandardMaterial3D.new();material.albedo_color=colour;material.roughness=.9;return material
static func _earth_material()->StandardMaterial3D:
	if _earth==null:
		var noise:=FastNoiseLite.new();noise.seed=71821;noise.frequency=.09;noise.fractal_octaves=3
		var ramp:=Gradient.new();ramp.set_color(0,Color("716b59"));ramp.set_color(1,Color("918775"))
		var grain:=NoiseTexture2D.new();grain.width=128;grain.height=128;grain.seamless=true;grain.noise=noise;grain.color_ramp=ramp
		_earth=_material(Color.WHITE);_earth.albedo_texture=grain
	return _earth
static func _box(parent:Node,label:String,dimensions:Vector3,at:Vector3,colour:Color)->MeshInstance3D:
	var shape:=BoxMesh.new();shape.size=dimensions;return _mesh(parent,label,shape,at,colour)
static func _cylinder(parent:Node,label:String,radius:float,height:float,at:Vector3,colour:Color)->MeshInstance3D:
	var shape:=CylinderMesh.new();shape.top_radius=radius;shape.bottom_radius=radius*1.06;shape.height=height;shape.radial_segments=16;return _mesh(parent,label,shape,at,colour)
static func _sphere(parent:Node,label:String,radius:float,at:Vector3,colour:Color)->MeshInstance3D:
	var shape:=SphereMesh.new();shape.radius=radius;shape.height=radius*2;shape.radial_segments=12;shape.rings=6;return _mesh(parent,label,shape,at,colour)
static func _mesh(parent:Node,label:String,shape:Mesh,at:Vector3,colour:Color)->MeshInstance3D:
	var node:=MeshInstance3D.new();node.name=label;node.mesh=shape;node.material_override=_material(colour);node.position=at;parent.add_child(node);return node
static func _emission(node:MeshInstance3D,colour:Color,energy:float)->void:
	var material:StandardMaterial3D=node.material_override;material.emission_enabled=true;material.emission=colour;material.emission_energy_multiplier=energy
