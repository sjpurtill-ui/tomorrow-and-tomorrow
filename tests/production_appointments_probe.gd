extends Node
const Board=preload("res://scripts/hud/production_board.gd")
const Blocks=preload("res://scripts/hud/dock_blocks.gd")
var failures:Array[String]=[]
class Terrain extends "res://scripts/local_terrain.gd":
	var report:Dictionary={}
	func _ready()->void:pass
	func _process(_delta:float)->void:pass
	func _report_military_action(result:Dictionary)->void:report=result
class Hud extends Control:
	var refreshed:=false
	func request_immediate_dock_refresh()->void:refreshed=true
func check(ok:bool,message:String)->void:
	if not ok:failures.append(message);push_error(message)
func settle()->void:
	for frame:int in 5:await get_tree().process_frame
func click(viewport:SubViewport,control:Control)->void:
	for pressed:bool in [true,false]:
		var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed;event.position=control.get_global_rect().get_center()
		viewport.push_input(event,true)
	await settle()
func _ready()->void:
	if not OS.get_user_data_dir().ends_with("TomorrowCanopyTransitionTests"):get_tree().quit(2);return
	for node:Node in get_tree().root.get_children():
		if node!=self:node.set_process(false);node.set_physics_process(false)
	GameState.reset_for_new_world(7751);MilitaryCampaign.reset_for_new_world();GovernmentPeopleSystem.reset_for_new_world()
	GameState.initialize_population_model();GameState.ensure_population_total(12000);GameState.society_capacities.institutions=.74
	GameState.settlement_name="Test";GameState.settlement_completed=["Hearth Circle"];GameState.settlement_site_committed=true;GameState.settlement_founded_at=Vector3(12,0,-8)
	SettlementModel.ensure_founded();GovernmentPeopleSystem.initialize()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts/production-appointments"))
	for width:int in [540,400]:
		var viewport:=SubViewport.new();viewport.size=Vector2i(width,850);viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;add_child(viewport)
		var backdrop:=ColorRect.new();backdrop.color=Color("#090f11");backdrop.size=viewport.size;viewport.add_child(backdrop)
		var scroll:=ScrollContainer.new();scroll.position=Vector2(14,14);scroll.size=viewport.size-Vector2i(28,28);scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;viewport.add_child(scroll)
		var column:=VBoxContainer.new();column.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(column)
		var selected:=[-1]
		var data:={"view_state":{"mode":0},"day":44,"on_open":func(id:int):selected[0]=id,"lines":[
			{"id":1,"item":"improvised","job_type":"production","persistent":true,"planner_managed":true,"state":"Working","stock":18,"target_stock":25,"progress_days":.6,"work_per_item":1.0,"forecast_output_per_day":1.8},
			{"id":2,"item":"handmade_paper","job_type":"civilian","persistent":true,"planner_managed":true,"state":"Missing Paper Pulp","stock":2,"target_stock":10,"progress_days":.2,"work_per_item":1.0},
			{"id":3,"item":"transport_cart","job_type":"transport","persistent":true,"state":"Target met","stock":5,"target_stock":5},
			{"id":4,"item":"arrows","job_type":"consumable","persistent":true,"state":"Paused","stock":32},
			{"id":5,"item":"metallographic_nitric_acid","job_type":"civilian","persistent":true,"state":"Missing Laboratory Glassware and Pressure Vessels; workshop setup cannot proceed","stock":0,"target_stock":12}],
			"receipts":[{"day":44,"item":"improvised","resource":"improvised","kind":"production","quantity":18.0},{"day":43,"item":"handmade_paper","resource":"Paper","kind":"civilian","quantity":4.0}]}
		Blocks.render(column,[{"type":"text","heading":"SHARED WORKSHOPS · 4 / 6 LINES","text":"MANAGED · Emma Webb · Quartermaster\nSupplying the requested levy band and study materials."},{"type":"production_board"}.merged(data)])
		await settle()
		var board:VBoxContainer=column.find_children("*","VBoxContainer",true,false).filter(func(n:Node):return n.get_script()==Board)[0]
		var buttons:=board.find_children("*","Button",true,false)
		check(scroll.get_global_rect().encloses(board.get_global_rect()),"Board fits at %d" % width)
		for label:Node in board.find_children("*","Label",true,false):check(board.get_global_rect().encloses(label.get_global_rect()),"Text fits board: "+label.text)
		await click(viewport,buttons[3]);check(selected[0]==1,"Production row receives mouse click")
		await capture(viewport,"production-%d" % width)
		await click(viewport,buttons[1]);check(int(data.view_state.mode)==1,"Finished tab persists selection")
		await capture(viewport,"finished-%d" % width)
		board.setup({"type":"production_board"}.merged(data));await settle();check(board.mode==1,"Refresh retains finished tab")
		for child:Node in column.get_children():column.remove_child(child);child.queue_free()
		var terrain:=Terrain.new();var hud:=Hud.new();viewport.add_child(hud)
		var opened:=[false]
		Blocks.render(column,[{"type":"rows","items":[{"name":"Quartermaster","sub":"Vacant · appoint someone","value":"APPOINT","on_click":func():opened[0]=true}]}])
		await settle()
		var office:PanelContainer=column.find_children("*","PanelContainer",true,false)[0]
		await click(viewport,office);check(opened[0],"Vacant office receives actual click through its child text")
		for child:Node in column.get_children():column.remove_child(child);child.queue_free()
		var provider:=preload("res://scripts/hud/content/dock_detail_appointments.gd").new(terrain,hud,"Quartermaster")
		Blocks.render(column,provider.tab(0).blocks);await settle()
		var appoint:Button=null
		for candidate:Node in column.find_children("*","Button",true,false):
			if not candidate.disabled:appoint=candidate;break
		check(appoint!=null,"Candidate is appointable")
		if appoint!=null:
			scroll.ensure_control_visible(appoint);await settle();await click(viewport,appoint)
			check(bool(terrain.report.get("ok",false)) and hud.refreshed,"APPOINT commits person and requests visible feedback")
		terrain.free();viewport.queue_free();await settle()
	print("PRODUCTION_APPOINTMENTS_CAPTURE PASS" if failures.is_empty() else str(failures))
	get_tree().quit(0 if failures.is_empty() else 1)
func capture(viewport:SubViewport,name:String)->void:
	await RenderingServer.frame_post_draw
	viewport.get_texture().get_image().save_png("res://artifacts/production-appointments/"+name+".png")
