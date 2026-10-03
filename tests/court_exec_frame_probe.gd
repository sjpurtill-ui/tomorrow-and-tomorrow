extends "res://tests/audience_modal_probe.gd"
## Where the camera looks during an execution (debug): prints each person's
## place on the screen at a few moments. Headless is enough (the camera's
## maths need no drawing).
const Backdrop:=preload("res://scripts/hud/court_backdrop.gd")

var method:="club"
func _ready()->void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--method="):method=arg.trim_prefix("--method=")
	Backdrop.tier_override=0
	_setup_world()
	if method=="behead" and not GameState.known_discoveries.has("bronze_alloying"):GameState.known_discoveries.append("bronze_alloying")
	var terrain:=TerrainDouble.new();terrain.name="TerrainDouble";add_child(terrain)
	var director:=Director.new();director.terrain=terrain;add_child(director)
	if "force_offline" in director.voice:director.voice.force_offline=true
	get_window().size=Vector2i(1536,864)
	await _frames(3)
	var audience:=Hall.debug_force("petition")
	var id:=String(audience.id)
	var modal:Control=director.open_audience(id)
	await _wait_scene(modal,id,1)
	await get_tree().create_timer(3.0).timeout
	var stage:Control=modal.court_stage
	stage.settle()
	_report(stage,"before")
	stage.execute(method,"main","","Heha")
	var exec:Node=stage.get_node_or_null("Execution")
	var victim:Node3D=stage.figure("main").body3d
	var acting:Node=preload("res://scripts/hud/court_acting.gd").of(victim)
	if acting!=null:acting.cue.connect(func(_f:Node3D,e:Dictionary)->void:print("CUE ",e.get("name","")," t=",e.get("t","")))
	var last:=0.0
	for t in [1.4,3.0,6.0,9.0,10.5,12.0]:
		await get_tree().create_timer(t-last).timeout
		last=t
		stage.rig.call("settle")
		_report(stage,"t%.1f" % t)
	get_tree().quit(0)

func _report(stage:Control,label:String)->void:
	var cam:Camera3D=stage.camera
	var view:Vector2=Vector2(stage.view3d.size)
	print("FRAME %s cam=%s rot=%s view=%s shot=%s" % [label,cam.global_position,cam.global_rotation_degrees,view,stage.get("_shot_name")])
	for key in stage.cast_order:
		var f:Variant=stage.figure(key)
		if f==null or f.body3d==null:continue
		var head:Vector3=f.body3d.global_position+Vector3(0,1.5,0)
		var px:=cam.unproject_position(head)
		var inside:=Rect2(Vector2.ZERO,view).has_point(px) and not cam.is_position_behind(head)
		print("  %s role=%s mark=%s at=%s screen=%s inside=%s vis=%s nudge=%s" % [key,f.role,f.mark_name,f.body3d.global_position.snapped(Vector3(0.01,0.01,0.01)),px.round(),inside,f.body3d.visible,f.nudge.snapped(Vector3(0.01,0.01,0.01))])
	var exec:Node=stage.get_node_or_null("Execution")
	if exec!=null:
		for name in exec._things:
			var n:Variant=exec._things[name]
			if n is Node3D and is_instance_valid(n):print("  thing %s at=%s screen=%s" % [name,(n as Node3D).global_position.snapped(Vector3(0.01,0.01,0.01)),cam.unproject_position((n as Node3D).global_position).round()])
