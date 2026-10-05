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
const Rituals=preload("res://scripts/hud/great_work_rituals.gd")
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
var _moving_paused:=false
var _ritual_paused:=false
var _props:Node3D
var _opening:Array[Node3D]=[]
var ritual_profile:Dictionary={}
var _specific:Dictionary={}
var _light:OmniLight3D
var _work:Dictionary={}
var _context:Dictionary={}
var _caption:Label
var _shot_kind:="gathering"
var _whole_button:Button

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
	ritual_profile=Rituals.describe(_work,Stages.known_for(),profile)
	cast=cast_for(_context)
	view=SubViewport.new();view.name="Dedication3D";view.own_world_3d=true;view.msaa_3d=Viewport.MSAA_2X
	view.render_target_update_mode=SubViewport.UPDATE_DISABLED;add_child(view)
	world=Node3D.new();world.name="CeremonyWorld";view.add_child(world)
	image=TextureRect.new();image.texture=view.get_texture();image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image.stretch_mode=TextureRect.STRETCH_SCALE;image.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(image);image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_scene(profile)
	var caption_frame:=PanelContainer.new();caption_frame.name="CeremonyCaption";caption_frame.mouse_filter=Control.MOUSE_FILTER_IGNORE;caption_frame.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE);caption_frame.grow_vertical=Control.GROW_DIRECTION_BEGIN;caption_frame.add_theme_stylebox_override("panel",Tokens.paper_panel_style(true,0,10));add_child(caption_frame)
	_caption=Tokens.make_label(String(ritual_profile.get("before","The dedication waits.")),16,Tokens.INK);_caption.add_theme_font_override("font",Tokens.voice_font());_caption.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;_caption.max_lines_visible=4;_caption.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;caption_frame.add_child(_caption)
	var whole:=Button.new();_whole_button=whole;whole.name="SeeWholeWork";whole.text="See the whole work";whole.theme=Tokens.control_theme();whole.position=Vector2(8,8);whole.custom_minimum_size=Vector2(145,30);whole.add_theme_stylebox_override("normal",Tokens.paper_panel_style(true,2,6));whole.pressed.connect(_toggle_work);add_child(whole)
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
	atmosphere.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;atmosphere.ambient_light_color=Color.WHITE;atmosphere.ambient_light_energy=.16
	atmosphere.tonemap_mode=Environment.TONE_MAPPER_FILMIC;env.environment=atmosphere;world.add_child(env)
	# Measured in Compatibility: restrained neutral energy retains the
	# palette and face detail instead of clipping pale stone into yellow.
	var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-42,-35,0);sun.light_color=Color.WHITE;sun.light_energy=.35;sun.shadow_enabled=true;world.add_child(sun)
	var fill:=DirectionalLight3D.new();fill.rotation_degrees=Vector3(-25,125,0);fill.light_color=Color.WHITE;fill.light_energy=.04;world.add_child(fill)
	var registry:Dictionary={}
	for index in cast.size():
		var entry:Dictionary=cast[index];var person:Dictionary=entry.person
		var owner:=String(person.get("appearance_civ_id",person.get("civilization_id","player")))
		var look:=Court.figure_look(person,registry,profile if owner=="player" else Presentation.for_owner(owner))
		look["stance"]="stand";look["lit"]=true
		var body:=Figure.new();body.name="Guest_"+String(entry.key);world.add_child(body)
		if not body.setup(look):body.queue_free();continue
		body.position=Rituals.guest_position(String(ritual_profile.get("formation","arc")),index,cast.size())+Vector3(0,0,_front)
		if index==0 and String(ritual_profile.get("action",""))=="cross":body.position=Vector3(0,0,_front+3.1) if String(ritual_profile.get("form",""))=="gate" else Vector3(-3.9,0,_front+3.2)
		body.rotation.y=atan2(-body.position.x,(_front+.8)-body.position.z)*.45
		body.set_meta("ceremony_person",person.duplicate(true));bodies[entry.key]=body
		Acting.idle(body,"stand")
	_props=Node3D.new();_props.name="DedicationRitual";world.add_child(_props)
	_build_ritual()
	lens=Camera3D.new();lens.name="DedicationCamera";lens.fov=43;world.add_child(lens);lens.current=true
	_gathering()

func _build_ritual()->void:
	var at:=Vector3(0,0,_front+.8)
	if not ritual_profile.is_empty():
		_specific=Rituals.build(ritual_profile)
		var specific_root:Node3D=_specific.root;_props.add_child(specific_root);specific_root.position=at
	match mode:
		"offering":
			for i in 9:
				var a:=float(i)*TAU/9.0
				_sphere(_props,"HearthStone",.14,at+Vector3(-1.9+cos(a)*.32,.08,-.7+sin(a)*.32),Color("706c60"))
			var fire:=_sphere(_props,"HearthEmber",.16,at+Vector3(-1.9,.13,-.7),Color("ac6938"));_emission(fire,Color("a45b30"),.25)
		"ribbon","unveiling":
			for side in [-1.0,1.0]:
				_cylinder(_props,"CeremonyPost",.055,1.15,at+Vector3(side*1.55,.575,1.0),Color("775941"))
				var hinge:=Node3D.new();hinge.position=at+Vector3(side*1.55,1.02,1.0);_props.add_child(hinge)
				_box(hinge,"Ribbon" if mode=="ribbon" else "UnveilingCloth",Vector3(1.55,.09 if mode=="ribbon" else .45,.025),Vector3(-side*.775,-.05 if mode=="ribbon" else -.18,0),ritual_profile.get("accent",Color("954c40")))
				_opening.append(hinge)
			if mode=="ribbon":
				# The tool is a ceremonial prop, never credited as a produced good.
				var scissors:=Node3D.new();scissors.name="OpeningShears";scissors.position=at+Vector3(0,1.07,1.06);_props.add_child(scissors)
				for angle in [-.3,.3]:
					var blade:=_box(scissors,"Blade",Vector3(.025,.28,.018),Vector3(0,.05,0),Color("c3c9c8"));blade.rotation.z=angle
		"illumination":
			for side in [-1.0,1.0]:
				var lamp:=_box(_props,"OpeningLight",Vector3(.06,1.1,.06),at+Vector3(side*1.7,.55,.2),Color("687e81"));_emission(lamp,Color("95d6d4"),.10);_opening.append(lamp)
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
	committed=true
	if _caption!=null:_caption.text=String(ritual_profile.get("after","The work is dedicated."))+" "+String(ritual_profile.get("purpose_caption",""))
	if _ritual!=null and _ritual.is_valid():_ritual.kill()
	_ritual=create_tween().set_parallel(true)
	_ritual_paused=false
	if not _specific.is_empty():
		(_specific.after as Node3D).visible=true
		for motion:Dictionary in _specific.motions:
			_ritual.tween_property(motion.node,NodePath(motion.property),motion.to,1.8).set_delay(.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if mode in ["ribbon","unveiling"]:
		for index in _opening.size():_ritual.tween_property(_opening[index],"rotation:z",-.85 if index==0 else .85,1.3).set_trans(Tween.TRANS_SINE)
		var tool:=_props.get_node_or_null("OpeningShears")
		if tool!=null:tool.visible=false
	elif mode=="illumination":
		for lamp:Node3D in _opening:
			var material:StandardMaterial3D=(lamp as MeshInstance3D).material_override
			_ritual.tween_property(material,"emission_energy_multiplier",2.0,1.6)
	_ritual.tween_property(_light,"light_energy",2.0 if mode=="illumination" else 1.0,1.6)
	var index:=0
	for body:Node3D in bodies.values():
		Acting.play(body,String(ritual_profile.get("gesture","nod_slow")) if index==0 else String(ritual_profile.get("purpose_gesture","clap_soft")))
		index+=1
	var active_seconds:=7.0
	if String(ritual_profile.get("action",""))=="cross" and not bodies.is_empty():
		var leader:Node3D=bodies.values()[0]
		# The bridge procession passes in front of all three guest rows.
		var travel:=Vector3(0,0,-3.8) if String(ritual_profile.get("form",""))=="gate" else Vector3(7.8,0,0)
		leader.rotation.y=atan2(travel.x,travel.z);leader.play("walk_in");leader.set_locomotion_rate(1.0)
		var walk:=_ritual.tween_property(leader,"position",leader.position+travel,travel.length()/1.18).set_delay(.6)
		walk.finished.connect(_finish_walk.bind(leader))
		active_seconds=maxf(active_seconds,travel.length()/1.18+1.5)
	_shot_kind="ritual"
	var focus:=Vector3(0,.85,_front+.8)
	_shot(focus,focus+Rituals.camera_offset(ritual_profile),1.0)
	_wake(active_seconds)

func _finish_walk(body:Node3D)->void:
	if not is_instance_valid(body):return
	body.face(atan2(-body.position.x,(_front+.8)-body.position.z)*180.0/PI,.3)
	Acting.idle(body,"stand");Acting.play(body,"nod_proud")

func settle()->void:
	if _moving!=null and _moving.is_valid():_moving.custom_step(20.0);_moving.kill()
	if _ritual!=null and _ritual.is_valid():_ritual.custom_step(20.0);_ritual.kill()
	_moving=null;_ritual=null;_moving_paused=false;_ritual_paused=false
	_remaining=0.0;_set_active(false)

func show_work()->void:
	_shot_kind="work";_wide();_wake(1.2)

func _toggle_work()->void:
	if _shot_kind=="work":_gathering();_wake(1.2)
	else:show_work()

func _gathering()->void:
	_shot_kind="gathering"
	var focus:=Vector3(0,1.0,_front+.55)
	_shot(focus,focus+Rituals.camera_offset(ritual_profile),0.0)

func _shot(target:Vector3,from:Vector3,seconds:float)->void:
	if lens==null:return
	if _whole_button!=null:_whole_button.text="Return to the assembly" if _shot_kind=="work" else "See the whole work"
	if _moving!=null and _moving.is_valid():_moving.kill()
	_moving=null;_moving_paused=false
	var destination:=Transform3D(Basis.looking_at(target-from,Vector3.UP),from)
	if seconds<=0:lens.transform=destination
	else:
		_moving=create_tween();_moving.tween_property(lens,"transform",destination,seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _wide(animate:=true)->void:
	if lens==null:return
	var aspect:=maxf(.7,size.x/maxf(size.y,1.0))
	# Fit all three dimensions from the same elevated three-quarter angle.
	# Using height alone for elevation flattened broad rings into a thin strip.
	var framing:=_bounds.merge(AABB(Vector3(-5,0,_front-.4),Vector3(10,3,5)))
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
		if active and _moving_paused:_moving.play();_moving_paused=false
		elif not active and _moving.is_running():_moving.pause();_moving_paused=true
	if _ritual!=null and _ritual.is_valid():
		if active and _ritual_paused:_ritual.play();_ritual_paused=false
		elif not active and _ritual.is_running():_ritual.pause();_ritual_paused=true
	set_process(active)

func _process(delta:float)->void:
	_remaining=maxf(0.0,_remaining-delta)
	if _remaining<=0.0:_set_active(false)

func diagnostics()->Dictionary:
	return {"mode":mode,"cast_count":cast.size(),"cast_keys":cast.map(func(member:Dictionary)->String:return String(member.key)),"body_count":bodies.size(),"model_node_id":model.get_instance_id() if is_instance_valid(model) else 0,"mesh_count":model.find_children("*","MeshInstance3D",true,false).size() if is_instance_valid(model) else 0,"viewport_active":view!=null and view.render_target_update_mode==SubViewport.UPDATE_ALWAYS,"committed":committed,"build_count":build_count,"camera_shot":_shot_kind,
		"design_id":ritual_profile.get("design_id",""),"ritual_id":ritual_profile.get("ritual_id",""),"purpose":ritual_profile.get("purpose",""),"prop":ritual_profile.get("prop",""),"action":ritual_profile.get("action",""),"formation":ritual_profile.get("formation",""),"ritual_node_id":(_specific.root as Node3D).get_instance_id() if not _specific.is_empty() else 0,"ritual_mesh_count":(_specific.root as Node3D).find_children("*","MeshInstance3D",true,false).size() if not _specific.is_empty() else 0}

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
