extends Node
## TEST fixture on actual saved terrain. The observations, army deployments
## and battles are staged snapshots; this is not a natural campaign replay.
## Real BorderDefense coverage and WarFrontOverlay composition/drawing.
## Run only with tools/run_isolated_gpu_probe.ps1, --capture-dir=<absolute>
## and optional --save=res://artifacts/path/to/copied.save. Never writes saves.
const Defense := preload("res://scripts/border_defense.gd")
const Overlay := preload("res://scripts/hud/war_front_overlay.gd")
const T := preload("res://scripts/hud/hud_tokens.gd")
const Motion := preload("res://scripts/hud/motion.gd")

class Snapshot extends "res://scripts/save_system.gd":
	var source := ""
	func slot_path(_slot:String) -> String: return source

var terrain:Node3D
var overlay:Control
var caption:Label
var capital_label:Label
var directory := ""
var source := "res://artifacts/organic-places/current.save"
var source_hash := ""
var day := 0
var center := Vector2.ZERO
var axis := Vector2.RIGHT
var across := Vector2.DOWN
var captures:Array = []
var failures:Array[String] = []

func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="): directory=arg.trim_prefix("--capture-dir=")
		elif arg.begins_with("--save="): source=arg.trim_prefix("--save=")
	if directory=="": directory=ProjectSettings.globalize_path("res://artifacts/border-defense")
	DirAccess.make_dir_recursive_absolute(directory)
	_run.call_deferred()

func _check(ok:bool,words:String) -> void:
	if not ok: failures.append(words); push_error(words)

func _frames(n:int) -> void:
	for _i in n: await get_tree().process_frame

func _freeze() -> void:
	for node in get_tree().root.get_children():
		if node!=self: node.set_process(false); node.set_physics_process(false)

func _settle() -> void:
	for _pass in 3:
		var guard:=0
		while terrain.get("terrain_patch_job")!=null and guard<2000:
			terrain.call("_advance_terrain_patch"); guard+=1; await get_tree().process_frame
		terrain.call("_update_world_streaming"); await get_tree().process_frame
	terrain.call("_update_scale_lod"); await _frames(6)

func _run() -> void:
	var path:=ProjectSettings.globalize_path(source).replace("\\","/").simplify_path()
	var allowed:=ProjectSettings.globalize_path("res://artifacts/").replace("\\","/").simplify_path().trim_suffix("/")+"/"
	if not path.begins_with(allowed) or not FileAccess.file_exists(source):
		push_error("Copy the source save into this worktree's ignored artifacts directory first.")
		get_tree().quit(2); return
	source_hash=FileAccess.get_sha256(source)
	_freeze()
	var snapshot:=Snapshot.new(); snapshot.source=source; add_child(snapshot)
	var loaded:Dictionary=snapshot.load_game("copy")
	if loaded.has("error"): push_error(str(loaded)); get_tree().quit(2); return
	GameState.civic_api_enabled=false
	if PeopleDirection.needs_century_choice(): PeopleDirection.choose(String(PeopleDirection.AMBITIONS.keys()[0]))
	_freeze(); day=int(GameState.elapsed_days)
	Motion.reduce_motion=false
	terrain=load("res://local_terrain.tscn").instantiate(); add_child(terrain)
	terrain.call("_set_game_speed",0)
	get_window().title="TEST · Border defense on copied terrain"
	get_window().size=Vector2i(1600,900); get_window().content_scale_size=Vector2i(1600,900)
	await _frames(15)
	terrain.call("_ensure_war_map_overlay")
	overlay=terrain.get_node("WarMapMarks/WarFrontOverlay")
	overlay.set_process(false)
	var labels:=CanvasLayer.new(); labels.layer=100; add_child(labels)
	var panel:=PanelContainer.new(); panel.position=Vector2(24,24); panel.custom_minimum_size=Vector2(1020,64); panel.mouse_filter=Control.MOUSE_FILTER_IGNORE; labels.add_child(panel)
	var paper:=StyleBoxFlat.new(); paper.bg_color=Color("f4eddc"); paper.border_color=Color("8f8066"); paper.set_border_width_all(1); paper.content_margin_left=14; paper.content_margin_right=14; paper.content_margin_top=8; paper.content_margin_bottom=8
	panel.add_theme_stylebox_override("panel",paper)
	caption=Label.new(); caption.add_theme_font_override("font",T.font("ui")); caption.add_theme_font_size_override("font_size",17); caption.add_theme_color_override("font_color",Color("302c23")); panel.add_child(caption)
	capital_label=Label.new(); capital_label.text="TSAREN · CAPITAL\nFixture objective · still defended"; capital_label.add_theme_font_override("font",T.voice_font(false)); capital_label.add_theme_font_size_override("font_size",17); capital_label.add_theme_color_override("font_color",Color("f6efdf")); capital_label.add_theme_color_override("font_shadow_color",Color("302c23")); capital_label.add_theme_constant_override("shadow_offset_x",1); capital_label.add_theme_constant_override("shadow_offset_y",2); labels.add_child(capital_label)
	if not _choose_ground():
		push_error("No sufficiently dry fixture area near the copied campaign home."); get_tree().quit(2); return
	var views:=[
		["held","Staffed fronts hold the approach · the capital lies beyond",0.9],
		["gap","A thin detachment leaves a real opening in its assigned line",0.9],
		["contact_a","Contact at the border · two armies fight for the crossing",0.7],
		["contact_b","The same fight, a later animation phase · no simulation tick",2.1],
		["inland","After a breakthrough · the fighting line follows the armies inland",1.1],
		["inland_far","The inland battle at regional scale · capital objective retained",1.1]]
	for view in views: await _capture(String(view[0]),String(view[1]),float(view[2]))
	_check(int(GameState.elapsed_days)==day,"Captures advance no simulation day")
	_check(FileAccess.get_sha256(source)==source_hash,"Copied source save unchanged")
	var file:=FileAccess.open(directory.path_join("audit.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"scope":"TEST staged observations and battles, actual copied-save terrain, actual defense coverage and overlay; frozen simulation","passed":failures.is_empty(),"failures":failures,"captures":captures,"day":day,"source_sha256":source_hash},"\t"))
	print("BORDER_DEFENSE_CAPTURE ","PASS" if failures.is_empty() else "FAIL"," captures=",captures.size()," directory=",directory)
	var render:Variant=terrain.get("macro_render")
	var deadline:=Time.get_ticks_msec()+10000
	while render!=null and render.has_method("ready") and not render.ready() and Time.get_ticks_msec()<deadline: await get_tree().process_frame
	get_tree().quit(0 if failures.is_empty() else 1)

func _choose_ground() -> bool:
	var home:Vector2=CivilizationSystem.player_world_origin
	# Keep authored battles away from the actual town label at the save's home.
	for ring in range(3,10):
		for direction in 8:
			var candidate:=home+Vector2.from_angle(float(direction)*TAU/8.0)*float(ring)*8.0
			for heading in 8:
				var forward:=Vector2.from_angle(float(heading)*TAU/8.0)
				var side:=forward.orthogonal()
				var dry:=true
				for x in [-12.0,-6.0,0.0,6.0,12.0,18.0]:
					for y in [-7.0,0.0,7.0]:
						if not CivilizationSystem._scout_land_at(candidate+forward*x+side*y): dry=false; break
					if not dry: break
				if dry: center=candidate; axis=forward; across=side; return true
	return false

func _at(x:float,y:float=0) -> Vector2: return center+axis*x+across*y
static func _pack(at:Vector2) -> Dictionary: return {"x":at.x,"z":at.y}

func _force(id:String,x:float,men:int,ours:bool) -> Dictionary:
	var at:=_at(x)
	return {"id":id,"owner":"player" if ours else "fixture-rival","civ_id":"player" if ours else "fixture-rival","position":_pack(at),"troops":men,"readiness":1.0,"morale":0.8,"provision_ratio":1.0,"supply_level":1.0,"status":"stationed",
		"formations":[{"count":men,"equipment":men,"training":0.8,"personnel_condition":1.0}],
		"border_sector":{"owner":"player" if ours else "fixture-rival","civ_id":"fixture-rival" if ours else "player","anchor":_pack(at),"points":[_pack(_at(x,-6)),_pack(_at(x,6))],"assigned_troops":men,"day":day,"organization":4.0}}

func _entry(force:Dictionary,ours:bool) -> Dictionary:
	var at:Dictionary=force.position
	var points:Array=[]
	for point in Defense.coverage(force): points.append(_pack(point))
	var entry:={"id":String(force.id),"pos":Vector2(float(at.x),float(at.z)),"strength":float(force.troops),"full":int(force.troops),"morale":float(force.morale),"era":2,"branch":"foot","age_days":0,"seen_day":day,"observed":true,"defense_points":points,
		"border_front":{"id":String(force.id),"points":points,"troops":int(force.troops),"day":day},"doing_context":{"status":"stationed","command_status":"Holding the approach"}}
	if ours:
		entry.army_id=701; entry.general="Hena Vall"; entry.name="River Army"; entry.objective=_at(18); entry.offensive=true; entry.road=PackedVector2Array([entry.pos,_at(18)])
	else:
		entry.owner="Esurai"; entry.low=int(force.troops*0.9); entry.high=int(force.troops*1.1)
	return entry

func _inputs(key:String) -> Dictionary:
	var contact:=key.begins_with("contact")
	var inland:=key.begins_with("inland")
	var x:=8.0 if inland else 0.0
	var ours:=_entry(_force("river-army",x-0.6 if contact or inland else -5.0,3200,true),true)
	var theirs:=_entry(_force("esurai-front",x+0.6 if contact or inland else 5.0,35 if key=="gap" else 3000,false),false)
	var battle_at:=_at(x)
	var battles:Array=[]
	var engagements:Array=[]
	if contact or inland:
		battles.append({"id":"fixture-contact","kind":"battle","pos":battle_at,"x":battle_at.x,"z":battle_at.y,"ours":true,"army_id":701,"seed":741,"progress":0.22 if inland else -0.1,"day":3 if inland else 1,"place_name":"Inland approach" if inland else "Border crossing","status":"fighting","age_days":0,"skirmish":false,
			"sides":{"a":{"civ_id":"player","name":"Seanstone","colour":Color("4f9bb8"),"troops":3200,"initial":3400},"b":{"civ_id":"fixture-rival","name":"Esurai","colour":Color("b5503c"),"troops":3000,"initial":3500}}})
		engagements.append({"pos":battle_at,"axis":axis,"ours":"flank_attack","theirs":"dense_line","rounds":3,"army_id":701,"phase_ours":"closing","phase_theirs":"hold","our_troops":3200,"their_troops":3000})
	return {"mode":"front","stage":"reckoned","home":_at(-12),"today":day,"friendly":[ours],"enemy":[theirs],"battles":battles,"engagements":engagements,"garrisons":[],
		"borders":[{"civ":"fixture-rival","points":PackedVector2Array([_at(0,-9),_at(0,9)]),"ours_at":[_at(-12)],"theirs_at":[_at(18)],"our_towns":[],"their_towns":[]}]}

func _capture(key:String,description:String,clock:float) -> void:
	caption.text="TEST · "+description+"\nStaged armies and observations · actual copied terrain · frozen day"
	var view_at:=_at(4 if key.begins_with("inland") else 0)
	terrain.camera_target=Vector3(view_at.x,terrain.call("_height_at",view_at.x,view_at.y),view_at.y)
	terrain.camera.size=90.0 if key.ends_with("far") else 38.0
	terrain.call("_update_camera"); await _settle()
	var inputs:=_inputs(key)
	var started:=Time.get_ticks_usec()
	var scene:Dictionary=Overlay.compose(inputs)
	var compose_us:=Time.get_ticks_usec()-started
	overlay.set_scene(scene,true); overlay.anim_clock=clock; overlay.band_override="regional" if key.ends_with("far") else "local"; overlay.queue_redraw()
	capital_label.position=(overlay.call("_screen",_at(18)) as Vector2)+(Vector2(24,-140) if key.ends_with("far") else Vector2(12,-72))
	await _frames(4)
	# The frozen chart rebuilds its hot-cache first. Repaint the separate
	# pulse canvas explicitly so each authored clock reaches the image.
	var pulse:Control=overlay.get("pulse_layer")
	pulse.queue_redraw(); await _frames(2)
	if key.begins_with("contact") or key.begins_with("inland"):
		_check((overlay.get("hot_cache") as Array).size()==2,"Both facing lines have battle heat in "+key)
	_check((scene.get("fronts",[]) as Array).size()>0,"Fronts present in "+key)
	if key.begins_with("contact") or key.begins_with("inland"): _check((scene.get("battles",[]) as Array).size()==1,"One live battle in "+key)
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		_check(get_viewport().get_texture().get_image().save_png(directory.path_join(key+".png"))==OK,"Saved "+key)
	captures.append({"key":key,"description":description,"compose_us":compose_us,"fronts":(scene.get("fronts",[]) as Array).size(),"battles":(scene.get("battles",[]) as Array).size(),"phase":clock,"front_center":_pack(_at(8 if key.begins_with("inland") else 0))})
	print("BORDER_DEFENSE_PLATE ",key," fronts=",(scene.get("fronts",[]) as Array).size()," battles=",(scene.get("battles",[]) as Array).size())
