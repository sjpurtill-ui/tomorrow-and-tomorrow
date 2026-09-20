extends SceneTree
## Isolated populated UI review. Seeds a fixture; never loads or saves a campaign.
## Run explicitly with --script; exits after action checks and screenshot.
## PRODUCTION_REVIEW_OUTPUT optionally selects the PNG path.
class ReviewTerrain extends Node:
	var last:Dictionary
	func _report_military_action(result:Dictionary)->void:last=result
class ReviewHud extends Control:
	func request_immediate_dock_refresh()->void:pass
func _initialize()->void:call_deferred("render")
func render()->void:
	root.title="PRODUCTION REVIEW — SEEDED SIMULATION"
	var state=root.get_node("GameState");var host=root.get_node("MilitaryCampaign")
	state.reset_for_new_world(7511);host.reset_for_new_world()
	state.population_allocations.Crafting=100;state.population_allocations.Logistics=100;state.population_health=1.0;state.simulation_metrics.labor_efficiency=1.0
	state.resource_stockpiles={"Timber":100.0,"Fiber Plants":100.0,"Stone":100.0,"Clay":50.0,"Spun Yarn":100.0,"Loom Weights":100.0}
	state.settlement_plots.clear();state.settlement_plots.append({"land_use":"workshop","worker_capacity":100,"condition":1.0,"status":"active","damage":{}})
	var P=load("res://scripts/persistent_production.gd")
	var lines:Array=[]
	var id:=0
	for item in ["spear","woven_cloth","bow","transport_cart","arrows"]:
		id+=1
		for gate in [String(host.EQUIPMENT_KNOWLEDGE.get(item,"")),"bow_craft","plain_weaving","joinery"]:
			state.known_discoveries.append(gate);state.discovery_adoption[gate]=1.0
		var recipe:Dictionary=P.recipe(host,item)
		if recipe.has("error"):print(recipe);continue
		var job:Dictionary=recipe.duplicate(true)
		job.merge({"id":id,"persistent":true,"target_stock":40,"paused":false,"allocation":1.0,"efficiency":.65,"progress_days":0.0,"completed":0,"count":1,"required_days":recipe.work_per_item,"reserved_materials":{},"last_output":0,"last_consumed":{},"last_work":0.0,"tooling_paid":true,"installed_tooling":recipe.tooling.duplicate(true),"planner_managed":id!=2})
		P.advance(host,job,float(recipe.work_per_item)*2.4)
		host.equipment_queue.append(job)
	for job in host.equipment_queue:lines.append(P.snapshot(host,job,6.0,1.0/host.equipment_queue.size()))
	var world:=ReviewTerrain.new();var hud:=ReviewHud.new()
	var provider=load("res://scripts/hud/content/dock_content_production.gd").new(world,hud)
	var second_before:Dictionary=host.equipment_queue[1].duplicate(true)
	var first_id:=int(host.equipment_queue[0].id)
	provider._action(first_id,"priority",2.0)
	assert(not host.equipment_queue[0].get("planner_managed",false))
	assert(host.equipment_queue[0].allocation==2.0)
	assert(host.equipment_queue[1]==second_before)
	var work_before:=float(host.equipment_queue[0].progress_days)
	provider._action(first_id,"delegate",0)
	assert(host.equipment_queue[0].planner_managed)
	assert(host.equipment_queue[0].progress_days==work_before)
	for line in provider.tab(1).blocks[0].lines:assert(line.job_type=="civilian")
	for line in provider.tab(2).blocks[0].lines:assert(line.job_type!="civilian")
	print("QUEUE_ACTIONS_AND_FILTERS_OK")
	world.free();hud.free()
	var T=load("res://scripts/hud/hud_tokens.gd");T.set_color_mode("light")
	var panel:=PanelContainer.new();panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);panel.add_theme_stylebox_override("panel",T.flat(T.DOCK_BG,Color.TRANSPARENT,0,0,18));root.add_child(panel)
	var box:=VBoxContainer.new();box.add_theme_constant_override("separation",12);panel.add_child(box)
	box.add_child(T.make_label("PRODUCTION",26,T.INK))
	box.add_child(T.make_label("GODOT UI REVIEW · SEEDED SIMULATION, NOT YOUR CAMPAIGN",10,T.MUTED))
	var queue=load("res://scripts/hud/production_queue.gd").new();box.add_child(queue)
	queue.setup({"lines":lines,"total_lines":lines.size(),"capacity":lines.size(),"selected":2,"managed":true,"owner":"Review fixture","stocks":state.resource_stockpiles,"on_select":func(_i):pass,"on_action":func(_i,_a,_v):pass,"on_detail":func(_i):pass,"on_manage":func():pass,"on_add":func():pass,"on_history":func():pass})
	for i in 5:await process_frame
	root.content_scale_size=Vector2i(920,860);root.content_scale_factor=1.0;root.size=Vector2i(920,860)
	for i in 5:await process_frame
	assert(queue.get_combined_minimum_size().x<=684)
	await RenderingServer.frame_post_draw
	var output:=OS.get_environment("PRODUCTION_REVIEW_OUTPUT")
	if output.is_empty():output=OS.get_user_data_dir()+"/production-queue-review.png"
	root.get_texture().get_image().save_png(output)
	print("QUEUE_RENDER_OK lines=",lines.size())
	quit()
