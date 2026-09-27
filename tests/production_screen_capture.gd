extends Node
## Isolated capture of the Production dock (Military and Civilian tabs).
## Seeds a throwaway world with one timber-starved line and one healthy line;
## never loads or saves a campaign. Run only through
## tools/run_isolated_gpu_probe.ps1 with user args
##   --out=<absolute folder> --tag=<before|after>
## Writes production-<tag>-military.png and production-<tag>-civilian.png.
class CaptureTerrain extends Node:
	var last:Dictionary
	func _report_military_action(result:Dictionary)->void:last=result
class CaptureHud extends Control:
	func request_immediate_dock_refresh()->void:pass
	func open_detail(_provider)->void:pass

const T:=preload("res://scripts/hud/hud_tokens.gd")
const WIDTH:=540

func _ready()->void:
	call_deferred("_run")

func _arg(name:String,fallback:String)->String:
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--"+name+"="):return arg.get_slice("=",1)
	return fallback

static func seed_world()->void:
	WorldSimulation.clear()
	GameState.reset_for_new_world(7511)
	MilitaryCampaign.reset_for_new_world()
	GameState.elapsed_days=400
	GameState.settlement_site_committed=true
	GameState.population_exact=120
	GameState.population_allocations.Crafting=6
	GameState.population_allocations.Logistics=4
	GameState.population_health=1.0
	GameState.simulation_metrics.labor_efficiency=1.0
	GameState.settlement_name="Alder Ford"
	GovernmentPeopleSystem.reset_for_new_world();SettlementModel.reset_for_new_world()
	GameState.initialize_population_model()
	GameState.settlement_completed=["Hearth Circle"];GameState.settlement_founded_at=Vector3(12,0,-8)
	SettlementModel.ensure_founded()
	if GameState.player_settlements.is_empty():GameState.player_settlements.append({"id":"alder","name":"Alder Ford","primary":true,"position":Vector2.ZERO,"population_share":1.0,"founded_day":0})
	for gate:String in ["hafted_weapons","cordage","basketry","clay_shaping"]:
		GameState.known_discoveries.append(gate);GameState.discovery_adoption[gate]=1.0 if gate!="clay_shaping" else .4
	GameState.resource_stockpiles={"Timber":5.08,"Stone":194.0,"Clay":336.0,"Copper Ore":1.0,"Fiber Plants":60.0,"Flint":12.0}
	GameState.civilian_goods=preload("res://scripts/civilian_goods.gd").empty_state()
	var P=preload("res://scripts/persistent_production.gd")
	var specs:=[{"item":"improvised","target":25,"stock":0,"efficiency":.2,"managed":false},{"item":"spear","target":20,"stock":18,"efficiency":.8,"managed":true}]
	var id:=0
	for spec:Dictionary in specs:
		id+=1
		var recipe:Dictionary=P.recipe(MilitaryCampaign,String(spec.item))
		if recipe.has("error"):push_warning(str(recipe));continue
		var job:Dictionary=recipe.duplicate(true)
		job.merge({"id":id,"persistent":true,"target_stock":int(spec.target),"paused":false,"allocation":1.0,"efficiency":float(spec.efficiency),"progress_days":float(recipe.work_per_item)*.3,"completed":0,"count":1,"required_days":recipe.work_per_item,"reserved_materials":{},"last_output":0,"last_consumed":{},"last_work":0.0,"tooling_paid":true,"installed_tooling":recipe.tooling.duplicate(true)})
		if bool(spec.managed):job.planner_managed=true
		MilitaryCampaign.equipment_queue.append(job)
		MilitaryCampaign.military_inventory[String(spec.item)]=int(spec.stock)
	MilitaryCampaign.next_equipment_job_id=id+1
	MilitaryCampaign.damaged_equipment={"improvised":3}
	GovernmentPeopleSystem.initialize()
	print("CAPTURE_PEOPLE ",GovernmentPeopleSystem.people.size())
	for person:Dictionary in GovernmentPeopleSystem.people:
		if String(person.get("status",""))=="active" and person.has("person_id"):
			GameState.leadership_positions["Quartermaster"]={"person_id":int(person.person_id)};break
	MilitaryCampaign.workshop.data.status="Simple levy weapons is under your control; staff have left its order unchanged."
	preload("res://scripts/civilian_goods.gd").advance()
	# The fixture jumps the clock; stop MilitaryCampaign replaying those days.
	MilitaryCampaign.last_processed_day=int(GameState.elapsed_days)

func _run()->void:
	var out:=_arg("out",OS.get_user_data_dir())
	var tag:=_arg("tag","capture")
	seed_world()
	T.set_color_mode("light")
	var terrain:=CaptureTerrain.new();add_child(terrain)
	var hud:=CaptureHud.new();add_child(hud)
	var provider=load("res://scripts/hud/content/dock_content_production.gd").new(terrain,hud)
	print("CAPTURE_OWNER ",MilitaryCampaign.workshop.owner())
	for line:Dictionary in MilitaryCampaign.production_lines_snapshot().lines:
		print("CAPTURE_LINE ",line.item," state=",line.state," rate=",line.get("output_per_day",0)," forecast=",line.get("forecast_output_per_day",0))
	for pair:Array in [[2,"military"],[1,"civilian"]]:
		var viewport:=SubViewport.new();viewport.size=Vector2i(WIDTH+48,2400);viewport.transparent_bg=false
		viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;add_child(viewport)
		var panel:=PanelContainer.new();panel.theme=T.control_theme()
		panel.add_theme_stylebox_override("panel",T.flat(T.DOCK_BG,Color.TRANSPARENT,0,0,24))
		panel.custom_minimum_size.x=WIDTH+48;viewport.add_child(panel)
		var column:=VBoxContainer.new();column.add_theme_constant_override("separation",16);panel.add_child(column)
		var meta:Dictionary=provider.meta()
		var title:=T.make_label(String(meta.title),28,T.INK);title.add_theme_font_override("font",T.font("display"));column.add_child(title)
		var tabs:=HBoxContainer.new();tabs.add_theme_constant_override("separation",18);column.add_child(tabs)
		for index:int in (meta.subtabs as Array).size():
			tabs.add_child(T.make_label(String(meta.subtabs[index]),14,T.GOLD if index==int(pair[0]) else T.MUTED))
		var body:=VBoxContainer.new();body.add_theme_constant_override("separation",16);body.custom_minimum_size.x=WIDTH;column.add_child(body)
		DockBlocks.render(body,provider.tab(int(pair[0])).blocks)
		for i in 8:await get_tree().process_frame
		var height:=int(clampf(panel.get_combined_minimum_size().y+8,200,2400))
		viewport.size=Vector2i(WIDTH+48,height)
		for i in 4:await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var path:=out.path_join("production-%s-%s.png" % [tag,String(pair[1])])
		viewport.get_texture().get_image().save_png(path)
		print("CAPTURE_SAVED ",path," height=",height)
		viewport.queue_free()
	print("PRODUCTION_CAPTURE PASS")
	get_tree().quit(0)
