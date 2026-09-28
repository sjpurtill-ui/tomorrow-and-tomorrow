extends Node
## TEST capture only, never a player launch: the Production dock as the player
## sees it (the real DockPanel at the production dock size, over a flat map
## colour) in two throwaway worlds. Never loads or saves a campaign. Run only
## through tools/run_isolated_gpu_probe.ps1 (1600x900 window) with user args
##   --out=<absolute folder> --tag=<before|after> [--state=early|late|all]
## Writes production-<tag>-early.png, production-<tag>-late.png and
## production-<tag>-late-lower.png (the late dock scrolled down).
class CaptureTerrain extends Node:
	var last:Dictionary
	func _report_military_action(result:Dictionary)->void:last=result
class ReportProvider extends RefCounted:
	var report:Dictionary
	func _init(blocks:Dictionary)->void:report=blocks
	func meta()->Dictionary:return {"eyebrow":"Workshop line","title":"Bows","subtabs":[]}
	func tab(_sub:int)->Dictionary:return report
	func signature()->Array:return []
class CaptureHud extends Control:
	signal section_requested(section:String,sub:int)
	var providers:Dictionary={}
	func request_immediate_dock_refresh()->void:pass
	func open_detail(_provider)->void:pass

const T:=preload("res://scripts/hud/hud_tokens.gd")
const DockPanel:=preload("res://scripts/hud/dock_panel.gd")
const P:=preload("res://scripts/persistent_production.gd")
const LOGISTICS_PATH:="res://scripts/equipment_logistics.gd"

func _ready()->void:
	get_window().title="TEST — Production capture"
	call_deferred("_run")

func _arg(name:String,fallback:String)->String:
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--"+name+"="):return arg.get_slice("=",1)
	return fallback

# --- Worlds -------------------------------------------------------------------

static func _base_world(seed:int,population:int,crafting:int)->void:
	WorldSimulation.clear()
	GameState.reset_for_new_world(seed)
	MilitaryCampaign.reset_for_new_world()
	ProgressionSystem.reset_for_new_world()
	GameState.elapsed_days=400
	GameState.settlement_site_committed=true
	GameState.ensure_population_total(population);GameState.housing_capacity=population+100
	GameState.population_health=1.0
	GameState.simulation_metrics.labor_efficiency=1.0
	GameState.settlement_name="Alder Ford"
	GovernmentPeopleSystem.reset_for_new_world();SettlementModel.reset_for_new_world()
	GameState.initialize_population_model()
	GameState.population_allocations.Crafting=crafting
	GameState.population_allocations.Logistics=maxi(4,crafting/2)
	GameState.settlement_completed=["Hearth Circle"];GameState.settlement_founded_at=Vector3(12,0,-8)
	GameState.settlement_plots=[{"land_use":"workshop","worker_capacity":200,"condition":1.0,"status":"active","damage":{}}]
	SettlementModel.ensure_founded()
	if GameState.player_settlements.is_empty():GameState.player_settlements.append({"id":"alder","name":"Alder Ford","primary":true,"position":Vector2.ZERO,"population_share":1.0,"founded_day":0})
	GameState.civilian_goods=preload("res://scripts/civilian_goods.gd").empty_state()
	GovernmentPeopleSystem.initialize()

static func _know(ids:Array)->void:
	for id:String in ids:
		if id not in GameState.known_discoveries:GameState.known_discoveries.append(id)
		GameState.discovery_adoption[id]=1.0

static func _appoint(office:String,given:String,skip:Array=[])->int:
	for person:Dictionary in GovernmentPeopleSystem.people:
		if String(person.get("status",""))!="active" or not person.has("person_id") or int(person.person_id) in skip:continue
		person["name"]=given
		GameState.leadership_positions[office]={"person_id":int(person.person_id)}
		return int(person.person_id)
	return -1

static func _line(id:int,item:String,target:int,stock:int,efficiency:float,managed:bool,progress:float=.3,paused:bool=false)->void:
	var recipe:Dictionary=P.recipe(MilitaryCampaign,item)
	if recipe.has("error"):push_warning("capture line %s: %s" % [item,str(recipe)]);return
	var job:Dictionary=recipe.duplicate(true)
	job.merge({"id":id,"persistent":true,"target_stock":target,"paused":paused,"allocation":1.0,"efficiency":efficiency,"progress_days":float(recipe.work_per_item)*progress,"completed":0,"count":1,"required_days":recipe.work_per_item,"reserved_materials":{},"last_output":0,"last_consumed":{},"last_work":0.0,"tooling_paid":true,"installed_tooling":(recipe.tooling as Dictionary).duplicate(true)})
	if managed:job.planner_managed=true
	MilitaryCampaign.equipment_queue.append(job)
	if String(recipe.job_type)=="consumable":MilitaryCampaign.military_consumables[item]=stock
	elif String(recipe.job_type)=="transport":GameState.resource_stockpiles["Transport Carts"]=float(stock)
	else:MilitaryCampaign.military_inventory[item]=stock
	MilitaryCampaign.next_equipment_job_id=maxi(MilitaryCampaign.next_equipment_job_id,id+1)

static func _formation(unit:String,weapon:String,count:int,equipment:int,ammunition:int=-1)->Dictionary:
	var required:int=MilitaryCampaign._equipment_required_for(unit,count)
	var rounds:int=MilitaryCampaign._ammunition_required_for(weapon,required)
	return {"id":MilitaryCampaign.next_formation_id,"unit":unit,"weapon":weapon,"count":count,"authorized_count":count,"equipment":equipment,"equipment_required":required,"ammunition":rounds if ammunition<0 else ammunition,"ammunition_required":rounds,"training":.6,"experience":0.0,"personnel_condition":1.0}

static func _home(formations:Array)->void:
	for formation:Dictionary in formations:MilitaryCampaign.next_formation_id+=1
	var commander:Dictionary=MilitaryCampaign._marshal_commander()
	MilitaryCampaign.home_army=MilitaryCampaign.simulator.create_formation_force("Alder Ford Host",formations,.8,.7)
	MilitaryCampaign.home_army["commander"]=commander

static func _stores_a_week_ago(stocks:Dictionary)->void:
	## The trend in the header compares with a week ago; seed that week.
	if not ResourceLoader.exists(LOGISTICS_PATH):return
	var logistics=load(LOGISTICS_PATH)
	logistics.note_stores(stocks,int(GameState.elapsed_days)-7)

static func seed_early()->void:
	## Year 1: two lines, a timber-starved levy line the player runs and a
	## spear line the Quartermaster runs; Rovik's levy lacks eight clubs.
	_base_world(7511,120,6)
	_know(["hafted_weapons","cordage","basketry"])
	for domain:String in ["security","production","logistics","institutions"]:ProgressionSystem.domain_levels[domain]=1
	GameState.resource_stockpiles={"Timber":5.08,"Stone":194.0,"Clay":336.0,"Copper Ore":1.0,"Fiber Plants":60.0,"Flint":12.0}
	# In the first years the Steward keeps the workshops and leads the levy.
	_appoint("Steward","Rovik of the Ford")
	_line(1,"improvised",25,0,.2,false)
	_line(2,"spear",20,18,.8,true)
	MilitaryCampaign.damaged_equipment={"improvised":3}
	_home([_formation("levy","improvised",20,12)])
	MilitaryCampaign.training_queue=[{"id":1,"mode":"new","unit":"spearman","weapon":"spear","count":6,"initial_count":6,"progress_days":2.0,"required_days":14.0,"experience":0.0,"injury_accumulator":0.0,"reserved_equipment":0}]
	MilitaryCampaign.next_training_order_id=2
	MilitaryCampaign.workshop.data.status="Simple levy weapons is under your control; staff have left its order unchanged."
	_stores_a_week_ago({"Timber":9.5,"Stone":190.0,"Clay":330.0,"Copper Ore":1.0,"Fiber Plants":57.0,"Flint":12.0})
	preload("res://scripts/civilian_goods.gd").advance()
	MilitaryCampaign.last_processed_day=int(GameState.elapsed_days)

static func seed_late()->void:
	## Many lines and real deficits: copper runs out, fibre is short, a band in
	## the field lacks bows and arrows, a war canoe is on the slip.
	_base_world(9120,900,40)
	_know(["hafted_weapons","cordage","basketry","bow_craft","bronze_weaponry","woven_carriers","joinery","river_craft","domesticated_mounts","siege_engineering","workshop_standards"])
	for domain:String in ["security","production","logistics","institutions"]:ProgressionSystem.domain_levels[domain]=6
	GameState.resource_stockpiles={"Timber":142.0,"Stone":61.0,"Clay":212.0,"Fiber Plants":3.2,"Copper Ore":0.0,"Tin Ore":2.4,"Flint":30.0,"Civilian Goods":40.0}
	# By now the council has a Quartermaster for the workshops and a Marshal
	# for the bands.
	var quartermaster:=_appoint("Quartermaster","Mahun of the High Camp")
	var marshal:=_appoint("Marshal","Rovik of the Ford",[quartermaster])
	MilitaryCampaign.joint_operations.state.bases.append({"id":1,"owner":"player","city_id":String(GameState.player_settlements[0].id),"name":"Alder Ford Landing","domain":"navy","position":{"x":0.0,"z":0.0},"capacity":20,"condition":1.0,"construction_work":30.0,"required_work":30.0})
	MilitaryCampaign.joint_operations.state.next_id=2
	_line(1,"spear",60,31,.92,true,.5)
	_line(2,"bow",40,6,.55,false,.2)
	_line(3,"arrows",600,120,.7,false,.6)
	_line(4,"sword_shield",12,2,.35,false,.1)
	_line(5,"sling",20,20,1.0,true,.0)
	_line(6,"transport_cart",8,3,.4,false,.45)
	_line(7,"javelin",30,11,.3,false,.2,true)
	_line(8,"war_canoe_equipment",0,1,.25,false,.35)
	MilitaryCampaign.damaged_equipment={"spear":5,"bow":2}
	_home([_formation("spearman","spear",60,40),_formation("levy","improvised",30,30)])
	var band:=_formation("archer","bow",50,30,200)
	MilitaryCampaign.next_formation_id+=1
	var army:Dictionary=MilitaryCampaign.simulator.create_formation_force("First Band",[band],.8,.7)
	army.merge({"army_id":1,"name":"First Band","status":"stationed","location_id":"field","position":{"x":14.0,"z":-9.0},"commander":{"name":"Tarn Reedwater"}})
	MilitaryCampaign.field_armies=[army];MilitaryCampaign.next_field_army_id=2
	MilitaryCampaign.training_queue=[{"id":1,"mode":"new","unit":"heavy_swordsman","weapon":"sword_shield","count":12,"initial_count":12,"progress_days":4.0,"required_days":30.0,"experience":0.0,"injury_accumulator":0.0,"reserved_equipment":0}]
	MilitaryCampaign.next_training_order_id=2
	MilitaryCampaign.workshop.data.status="Adjusted Spears to current demand: 60 in stores."
	_stores_a_week_ago({"Timber":131.0,"Stone":64.0,"Clay":205.0,"Fiber Plants":9.8,"Copper Ore":4.1,"Tin Ore":2.4,"Flint":30.0,"Civilian Goods":42.0})
	preload("res://scripts/civilian_goods.gd").advance()
	MilitaryCampaign.last_processed_day=int(GameState.elapsed_days)
	print("CAPTURE_MARSHAL ",marshal)

# --- Capture ------------------------------------------------------------------

func _run()->void:
	for singleton:Node in [GameState,MilitaryCampaign,CivilizationSystem]:singleton.set_process(false)
	var out:=_arg("out",ProjectSettings.globalize_path("user://"))
	var tag:=_arg("tag","capture")
	var wanted:=_arg("state","all")
	T.set_color_mode("light")
	var ok:=true
	for state:String in ["early","late","early-civilian","late-dark","late-narrow"]:
		if wanted!="all" and wanted!=state:continue
		T.set_color_mode("dark" if state.ends_with("dark") else "light")
		if state.begins_with("early"):seed_early()
		else:seed_late()
		ok=await _capture(out,tag,state,1 if state.ends_with("civilian") else 0) and ok
	print("HOI4_PRODUCTION_CAPTURE ","PASS" if ok else "FAIL")
	WorldSimulation.clear()
	get_tree().quit(0 if ok else 1)

func _capture(out:String,tag:String,state:String,sub:int=0)->bool:
	var stage:=Control.new();stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(stage)
	var ground:=ColorRect.new();ground.color=Color("6e7550") if T.is_light() else Color("2a3024");ground.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);stage.add_child(ground)
	var rail:=ColorRect.new();rail.color=T.PAPER;rail.position=Vector2.ZERO;rail.size=Vector2(T.RAIL_WIDTH,1080);stage.add_child(rail)
	var terrain:=CaptureTerrain.new();stage.add_child(terrain)
	var hud:=CaptureHud.new();stage.add_child(hud)
	var provider=load("res://scripts/hud/content/dock_content_production.gd").new(terrain,hud)
	var dock:=DockPanel.new();stage.add_child(dock)
	# The production dock's width at 1920 wide (980), or its narrowest (720).
	var width:=720.0 if state.ends_with("narrow") else clampf(1920*.65,720,980)
	dock.position=Vector2(T.DOCK_X,64);dock.size=Vector2(width,1080-64-T.DOCK_MARGIN_Y)
	dock.present(provider,sub)
	for i in 10:await get_tree().process_frame
	dock.size=Vector2(width,1080-64-T.DOCK_MARGIN_Y)
	for i in 4:await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var ok:=_save(out,"production-%s-%s.png" % [tag,state])
	if state=="late":
		dock.body_scroll.scroll_vertical=int(dock.body_scroll.get_v_scroll_bar().max_value)
		for i in 4:await get_tree().process_frame
		await RenderingServer.frame_post_draw
		ok=_save(out,"production-%s-%s-lower.png" % [tag,state]) and ok
		# The line opened from its name: the detail sheet over the dock.
		var military=load("res://scripts/hud/content/dock_content_military.gd").new(terrain,hud)
		var detail:=DockPanel.new();stage.add_child(detail)
		detail.position=Vector2(T.DOCK_X+width+12,64);detail.size=Vector2(T.DOCK_WIDTH,1080-64-T.DOCK_MARGIN_Y)
		detail.present(ReportProvider.new(military._workshop_job_report(2)),0)
		for i in 8:await get_tree().process_frame
		await RenderingServer.frame_post_draw
		ok=_save(out,"production-%s-line-detail.png" % tag) and ok
	stage.queue_free()
	await get_tree().process_frame
	return ok

func _save(out:String,file:String)->bool:
	var path:=out.path_join(file)
	DirAccess.make_dir_recursive_absolute(out)
	var error:=get_viewport().get_texture().get_image().save_png(path)
	print("CAPTURE_SAVED ",path," ",error)
	return error==OK
