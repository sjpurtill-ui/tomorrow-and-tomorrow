extends Node
var failures:=0
func check(ok:bool,message:String)->void:
	if not ok:failures+=1;push_error(message)
func _ready()->void:
	GameState.reset_for_new_world(424242)
	CivilizationSystem.reset_for_new_world();CivilizationSystem.initialize()
	GameState.civic_api_enabled=false
	var intel=CivilizationSystem.city_intelligence
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	var id:=String(civ.strategic_regions[0].id)
	intel.publish("player",intel.capture("player",id,.8,20,"returned scout expedition","party 12"),45)
	GameState.elapsed_days=75
	var before:Dictionary=intel.records.duplicate(true)
	for population in [-1,100,1000000000]:
		var report:Dictionary=intel.known("player",id).duplicate(true)
		report.fields={} if population<0 else {"population":{"low":population,"high":population}}
		var snapshots:Array=[]
		for repetition in 2:
			var visual:=preload("res://scripts/foreign_settlement_visual.gd").new()
			visual.build(report,func(_x:float,_z:float)->float:return .1)
			var count:=0;var transforms:Array=[]
			for child in visual.get_children():
				check(child.name not in ["WallsAndTimber","PitchedRoofs"],"legacy house geometry")
				if child is MultiMeshInstance3D:
					count+=child.multimesh.instance_count
					for i in child.multimesh.instance_count:
						var transform:Transform3D=child.get_meta("source_transforms")[i]
						check(is_equal_approx(transform.basis.get_scale().x,.001),"asset scale")
						transforms.append(transform)
			check(count==visual.building_count and count<=128,"bounded complete household batches")
			snapshots.append(transforms);visual.free()
		check(snapshots[0]==snapshots[1],"stable report geometry")
	for dimensions in [Vector2i(1024,576),Vector2i(1280,720),Vector2i(1000,820)]:
		get_window().size=dimensions;get_window().content_scale_size=dimensions
		intel.open(id,String(civ.id))
		for frame in 5:await get_tree().process_frame
		var screen=intel.screen_layer.get_child(0)
		var tabs:TabContainer=screen.find_children("*","TabContainer",true,false)[0]
		check(tabs.current_tab==0,"report opens first")
		check(get_viewport().get_visible_rect().encloses(tabs.get_global_rect()),"tabs inside viewport")
		for page in tabs.get_tab_count():
			tabs.current_tab=page
			for frame in 4:await get_tree().process_frame
			var scroll:ScrollContainer=tabs.get_child(page)
			check(scroll.get_child(0).size.x<=scroll.size.x,"page has no horizontal overflow")
			var target:Control=screen.cards.damage.note if page==0 else (screen.send if page==1 else screen.siege)
			scroll.ensure_control_visible(target)
			for frame in 3:await get_tree().process_frame
			check(scroll.get_global_rect().encloses(target.get_global_rect()),"last action/report is reachable")
		check(get_viewport().get_visible_rect().encloses(screen.feedback.get_global_rect()),"feedback inside viewport")
		screen._close();await get_tree().process_frame
	check(intel.records==before,"rendering does not mutate evidence")
	print("FOREIGN_REFRESH_PROBE failures=",failures)
	get_tree().quit(1 if failures else 0)
