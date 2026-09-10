extends Node
const Screen=preload("res://scripts/city_intelligence_screen.gd")
var failures:Array[String]=[]

func check(ok:bool,message:String)->void:
	if not ok:failures.append(message);push_error(message)

func _ready()->void:
	if not OS.get_user_data_dir().contains("TomorrowCityReportTests"):
		push_error("Private test userdata required");get_tree().quit(2);return
	for child in get_tree().root.get_children():
		if child!=self:child.set_process(false);child.set_physics_process(false)
	GameState.reset_for_new_world(424242)
	SettlementModel.reset_for_new_world();GovernmentPeopleSystem.reset_for_new_world()
	CivilizationSystem.reset_for_new_world();CivilizationSystem.initialize()
	MilitaryCampaign.reset_for_new_world();ForeignDiplomacy.reset_for_new_world()
	CivilizationSystem.set_scout_geography_authority(func(_p:Vector2)->bool:return true)
	FoodSystem.reset_for_new_world();FoodSystem.initialize();FoodSystem.receive_external_food(10000)
	var civ:Dictionary=CivilizationSystem.civilizations[0];civ.name="Havora";civ.player_relation.contact_level=2
	var intel=CivilizationSystem.city_intelligence
	civ.strategic_regions[0].position=CivilizationSystem.player_world_origin+Vector2(60,0)
	var id:=String(civ.strategic_regions[0].id)
	var record:Dictionary=intel.capture("player",id,.8,5197,"physical reconnaissance","scout:12")
	record.name="Flintwick";record.erase("observation_days")
	var values:Dictionary={"population":Vector2(46,70),"garrison":Vector2(3,8),"supply":Vector2(30,45),"fortification":Vector2(.05,.20),"production":Vector2(.25,.4),"logistics":Vector2(.10,.3),"damage":Vector2(0,.05)}
	for key:String in values:
		record.fields[key]={"low":values[key].x,"high":values[key].y,"observed_day":5197,"quality":.8,"source":"physical reconnaissance","reference":"scout:12"}
	intel.publish("player",record,5287);GameState.elapsed_days=5557
	DirAccess.make_dir_recursive_absolute("res://artifacts/city-report")
	FileAccess.open("res://artifacts/city-report/.gdignore",FileAccess.WRITE).close()
	for shape:Vector2i in [Vector2i(960,720),Vector2i(800,600),Vector2i(640,520),Vector2i(340,640)]:
		var viewport:=SubViewport.new();viewport.size=shape;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;add_child(viewport)
		var layer:=CanvasLayer.new();viewport.add_child(layer)
		var screen:=Screen.new();screen.city_id=id;layer.add_child(screen)
		for i in 6:await get_tree().process_frame
		check(screen.cards.population.value.text=="46–70 residents","Observed population must match map")
		check(screen.projection.text=="Unverified now: 35–81","Population projection is explicitly separate")
		check(Rect2(Vector2.ZERO,shape).encloses(screen.panel.get_global_rect()),"Panel within viewport at "+str(shape))
		check(screen.panel.get_global_rect().encloses(screen.selector.get_global_rect()),"Selector contained")
		check(screen.grid.columns==(1 if shape.x<366 else 2),"Responsive metric columns")
		if shape.y>=720:
			var scroll:ScrollContainer=screen.tabs.get_child(0)
			check(scroll.get_global_rect().encloses(screen.cards.damage.card.get_global_rect()),"All seven metrics visible at 720p")
		if DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw
			var rendered:=viewport.get_texture().get_image()
			rendered.save_png("res://artifacts/city-report/overview-%dx%d.png" % [shape.x,shape.y])
			if shape==Vector2i(960,720):rendered.get_region(Rect2i(screen.panel.get_global_rect())).save_png("res://artifacts/city-report/compact-city-report.png")
		for tab in [1,2]:
			screen.tabs.current_tab=tab
			if tab==1:screen.duration.select(1);screen.refresh()
			for i in 4:await get_tree().process_frame
			check(screen.panel.get_global_rect().encloses(screen.send.get_global_rect()) if tab==1 else screen.panel.get_global_rect().encloses(screen.attack.get_global_rect()),"Tab action contained at "+str(shape))
			if DisplayServer.get_name()!="headless" and shape==Vector2i(960,720):
				await RenderingServer.frame_post_draw
				viewport.get_texture().get_image().save_png("res://artifacts/city-report/tab-%d.png" % tab)
		# These are actual GUI events, not direct calls to the close handler.
		if shape.x>448:
			var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=true;event.position=Vector2(80,240)
			viewport.push_input(event,true)
		else:
			var event:=InputEventKey.new();event.keycode=KEY_ESCAPE;event.pressed=true;viewport.push_input(event,true)
		for i in 3:await get_tree().process_frame
		check(not is_instance_valid(screen),"Map click / Escape dismisses the sheet")
		viewport.queue_free();await get_tree().process_frame
	# Location-only and long-name reports remain useful without invented values.
	record.name="The extraordinarily long name of a distant reported settlement"
	record.fields={};record.controller="";record.civ_id="";record.observed_day=-1
	intel.records.player[id]=record
	var viewport:=SubViewport.new();viewport.size=Vector2i(800,600);viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;add_child(viewport)
	var layer:=CanvasLayer.new();viewport.add_child(layer)
	var screen:=Screen.new();screen.city_id=id;layer.add_child(screen)
	for i in 6:await get_tree().process_frame
	check(screen.cards.population.value.text=="Unknown","Location only is not a fabricated zero")
	check(screen.panel.get_global_rect().encloses(screen.selector.get_global_rect()),"Long name must fit")
	check(Rect2(Vector2.ZERO,viewport.size).encloses(screen.panel.get_global_rect()),"Long name cannot widen panel past viewport")
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		viewport.get_texture().get_image().save_png("res://artifacts/city-report/unknown.png")
	await policy_and_recruitment_views()
	print("CITY_REPORT_LAYOUT: ", "PASS" if failures.is_empty() else failures)
	get_tree().quit(0 if failures.is_empty() else 1)

class ArmyWorld extends Node:
	var selected_army_id:=-1
	var feedback:Dictionary={}
	func _report_military_action(value:Dictionary)->void:feedback=value
class ArmyShell extends Control:
	func request_immediate_dock_refresh()->void:pass
func policy_and_recruitment_views()->void:
	GameState.elapsed_days=0;GameState.ensure_population_total(514);GameState.initialize_population_model()
	GameState.settlement_site_committed=true
	CivilizationSystem.scouting_staff.set_policy(.05,"exploration")
	CivilizationSystem.scouting_staff.advance(0)
	for shape:Vector2i in [Vector2i(960,720),Vector2i(340,640)]:
		var viewport:=SubViewport.new();viewport.size=shape;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;add_child(viewport)
		var screen:=preload("res://scripts/hud/scouting_policy_panel.gd").new();viewport.add_child(screen)
		for i in 6:await get_tree().process_frame
		print("SCOUT_PANEL ",shape," rect=",screen.panel.get_global_rect()," root=",screen.size," minimum=",screen.panel.get_combined_minimum_size())
		check(Rect2(Vector2.ZERO,shape).encloses(screen.panel.get_global_rect()),"Scouting policy fits "+str(shape))
		check(screen.panel.get_global_rect().encloses(screen.slider.get_global_rect()),"Scouting slider contained")
		if DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw
			viewport.get_texture().get_image().save_png("res://artifacts/city-report/scouting-%dx%d.png" % [shape.x,shape.y])
		viewport.queue_free();await get_tree().process_frame
	MilitaryCampaign.reset_for_new_world();GameState.population_allocations.Defense=70
	GameState.known_discoveries.append("public_levies");GameState.discovery_adoption["public_levies"]=1.0
	FoodSystem.receive_external_food(10000)
	MilitaryCampaign.home_army=MilitaryCampaign.simulator.create_formation_force("Home",[{"id":1,"unit":"levy","weapon":"improvised","count":12,"authorized_count":12,"training":.5,"personnel_condition":.9,"equipment":12,"equipment_required":12,"ammunition":0,"ammunition_required":0}],.9,.8)
	MilitaryCampaign.army_templates=[{"template_id":1,"name":"LEVY BAND","entries":[{"unit":"levy","weapon":"improvised","count":50}]}]
	MilitaryCampaign.military_inventory.improvised=100
	var world:=ArmyWorld.new();add_child(world)
	var shell:=ArmyShell.new();add_child(shell)
	var provider:=preload("res://scripts/hud/content/dock_content_military.gd").new(world,shell)
	var content:=preload("res://scripts/hud/content/army_preparation.gd").new(world,shell,provider,1)
	for shape:Vector2i in [Vector2i(960,720),Vector2i(800,600)]:
		var viewport:=SubViewport.new();viewport.size=shape;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;add_child(viewport)
		var dock:=preload("res://scripts/hud/dock_panel.gd").new();dock.position=Vector2(8,8);dock.size=Vector2(540,shape.y-16);viewport.add_child(dock);dock.present(content,1)
		for i in 6:await get_tree().process_frame
		check(Rect2(Vector2.ZERO,shape).encloses(dock.get_global_rect()),"Army preparation fits "+str(shape))
		if DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw
			viewport.get_texture().get_image().save_png("res://artifacts/city-report/recruitment-%dx%d.png" % [shape.x,shape.y])
		var buttons:=find_buttons(dock,"RECRUIT & TRAIN")
		check(buttons.size()==1,"One recruitment action")
		if shape.y==720 and buttons.size()==1:
			var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.position=buttons[0].get_global_rect().get_center();event.pressed=true;viewport.push_input(event,true);event.pressed=false;viewport.push_input(event,true)
			for i in 2:await get_tree().process_frame
			check(MilitaryCampaign._queued_trainees()>0,"Actual recruitment click enrolls a group")
			check(int(MilitaryCampaign.home_army.troops)==12,"Existing soldiers stay at home")
			dock.present(content,1)
			for i in 6:await get_tree().process_frame
			if DisplayServer.get_name()!="headless":
				await RenderingServer.frame_post_draw
				viewport.get_texture().get_image().save_png("res://artifacts/city-report/recruitment-active.png")
		viewport.queue_free();await get_tree().process_frame
	world.queue_free();shell.queue_free()
func find_buttons(node:Node,text:String)->Array[Button]:
	var result:Array[Button]=[]
	if node is Button and node.text==text:result.append(node)
	if node is Label and node.text==text and node.get_parent().get_parent() is Button:result.append(node.get_parent().get_parent())
	for child in node.get_children():result.append_array(find_buttons(child,text))
	return result
