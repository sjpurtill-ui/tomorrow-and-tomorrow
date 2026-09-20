extends SceneTree
## Isolated seeded construction UI; never reads or writes campaign saves.
class ReviewTerrain extends Node:
	func _report_military_action(_result:Dictionary)->void:pass
	func _on_settlement_action_pressed()->void:pass
class ReviewHud extends Control:
	func request_immediate_dock_refresh()->void:pass
func _initialize()->void:call_deferred("render")
func render()->void:
	assert(load("res://scripts/hud/command_rail_hud.gd").can_instantiate())
	assert(load("res://scripts/hud/dock_blocks.gd").can_instantiate())
	root.title="CONSTRUCTION REVIEW — SEEDED SIMULATION"
	var state=root.get_node("GameState")
	state.reset_for_new_world(7511)
	state.settlement_site_committed=true;state.convoy_traveling=false
	state.settlement_completed.append("Hearth Circle")
	state.settlement_projects={"Lean-to Shelters":4.5,"Storage Pits":1.5}
	state.population_allocations={"Construction":12,"Logistics":8,"Crafting":6,"Extraction":5}
	state.resource_stockpiles={"Timber":20.0,"Stone":30.0,"Clay":15.0,"Fiber Plants":8.0}
	state.water_metrics={"source_accessible":true}
	state.known_discoveries.append("public_stores");state.discovery_adoption["public_stores"]=1.0
	state.player_settlements.append({"id":"review_city","name":"Riverbend","primary":true})
	state.resource_settlement_id="review_city";state.selected_player_settlement_id="review_city"
	var world:=ReviewTerrain.new();var hud:=ReviewHud.new()
	var provider=load("res://scripts/hud/content/dock_content_construction.gd").new(world,hud)
	provider.selected_project="Open Work Area"
	var data:Dictionary=provider._local_tab(0).blocks[0]
	assert(data.projects.size()==5)
	for project in data.projects:
		assert(not project.done)
		if project.name=="Lean-to Shelters":assert(is_equal_approx(project.progress,.5))
	var completed:Dictionary=provider._local_tab(1).blocks[0]
	assert(completed.projects.size()==1 and completed.projects[0].done)
	var C=load("res://scripts/settlement_construction.gd")
	for definition in C._settlement_definitions():
		var row:Dictionary=provider._project(definition,C._current_settlement_project(),false)
		var plan:Dictionary=C._settlement_project_material_plan(definition)
		if not plan.is_empty():
			for input in row.inputs:assert(input.stored>=input.required)
	var progress_before:Dictionary=state.settlement_projects.duplicate(true)
	provider._priority("Storage Pits")
	assert(C._current_settlement_project().name=="Storage Pits")
	provider._priority("Public Stores")
	assert(C._current_settlement_project().name!="Public Stores")
	provider._priority("")
	assert(state.player_settlements[0].construction_priority=="")
	assert(state.settlement_projects==progress_before)
	print("CONSTRUCTION_PROGRESS_FILTERS_MATERIALS_PRIORITY_OK")
	var T=load("res://scripts/hud/hud_tokens.gd");T.set_color_mode("light")
	var panel:=PanelContainer.new();panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);panel.add_theme_stylebox_override("panel",T.flat(T.DOCK_BG,Color.TRANSPARENT,0,0,18));root.add_child(panel)
	var box:=VBoxContainer.new();box.add_theme_constant_override("separation",12);panel.add_child(box)
	box.add_child(T.make_label("Construction",26,T.INK))
	box.add_child(T.make_label("GODOT UI REVIEW · SEEDED SIMULATION, NOT YOUR CAMPAIGN",10,T.MUTED))
	box.add_child(T.make_label("PROJECTS                         COMPLETED",12,T.GOLD))
	var queue=load("res://scripts/hud/construction_queue.gd").new();box.add_child(queue);queue.setup(data)
	for i in 5:await process_frame
	root.content_scale_size=Vector2i(920,860);root.content_scale_factor=1.0;root.size=Vector2i(920,860)
	for i in 5:await process_frame
	assert(queue.get_combined_minimum_size().x<=684)
	await RenderingServer.frame_post_draw
	var output:=OS.get_environment("CONSTRUCTION_REVIEW_OUTPUT")
	if output.is_empty():output=OS.get_user_data_dir()+"/construction-queue-review.png"
	root.get_texture().get_image().save_png(output)
	print("CONSTRUCTION_RENDER_OK")
	world.free();hud.free();quit()
