extends Node
## HUNGER PROBE (diagnostic, not a suite): load a COPY of a save, step days
## exactly as the game's frame loop does (WorldSimulation.begin_day + pump_day),
## and print each town's food every --every days.
##   <godot> --headless --path <worktree> res://tests/hunger_probe.tscn -- --hunger-probe
##       --save=<absolute path to a COPY of a .save> [--days=360] [--every=15]
## Never reads or writes the player's save slots.
class Snapshot extends "res://scripts/save_system.gd":
	var fixture:=""
	func slot_path(slot:String)->String:
		return fixture if slot=="fixture" else "user://hunger_probe_"+slot+".save"
class Terrain extends "res://scripts/local_terrain.gd":
	func _ready()->void:pass
	func _process(_delta:float)->void:pass

func _ready()->void:call_deferred("run")

func _arg(name:String,fallback:String)->String:
	for a:String in OS.get_cmdline_user_args():
		if a.begins_with("--%s=" % name):return a.substr(name.length()+3)
	return fallback

func run()->void:
	if DisplayServer.get_name()!="headless" or "--hunger-probe" not in OS.get_cmdline_user_args():get_tree().quit(2);return
	var saves:=Snapshot.new();saves.fixture=_arg("save","");add_child(saves)
	var loaded:=saves.load_game("fixture")
	if loaded.has("error"):print("HUNGER_LOAD_FAILED ",loaded);get_tree().quit(1);return
	for node in get_tree().root.get_children():node.set_process(false);node.set_physics_process(false)
	GameState.civic_api_enabled=false
	for id in WorldSimulation.actors:WorldSimulation.actors[id].systems.GameState.civic_api_enabled=false
	var terrain:=Terrain.new();add_child(terrain)
	terrain._configure_seamless_world();terrain._configure_shape();terrain._configure_noise()
	terrain._prepare_river_course()
	CivilizationSystem.set_scout_geography_authority(Callable(terrain,"_scout_land_at"))
	CivilizationSystem.set_ground_survey_authority(Callable(terrain,"_survey_ground_at"))
	MilitaryCampaign.recovery.surface_assessor=Callable(terrain,"_settlement_surface_assessment")
	WorldSimulation.water_provider=Callable(terrain,"_surface_water_site_near")
	WorldSimulation.context_provider=terrain._civilization_geography
	WorldSimulation.surface_material_provider=terrain._civilization_surface_materials
	WorldSimulation.bind_geography()
	terrain.camera=Camera3D.new();terrain.add_child(terrain.camera)
	terrain.settler_marker=Area3D.new();terrain.add_child(terrain.settler_marker);terrain.settler_marker.position=GameState.settlement_founded_at
	var direction=WorldSimulation.direction
	print("HUNGER_WORK automatic_work=%s applied=%s floor=%.3f" % [str(direction.automatic_work) if direction!=null else "?",JSON.stringify(preload("res://scripts/manual_work.gd").applied_percentages()),float(WorldSimulation.government.food_floor_share())])
	for city:Dictionary in GameState.player_settlements:
		print("HUNGER_TOWN %s auto=%s food_share=%.1f guard=%s focus=%s share=%.3f" % [String(city.get("name","")),str(city.get("auto_manage",true)),float((city.get("local_allocations",{}) as Dictionary).get("Food",-1.0)),str(city.get("survival_guard_active",false)),String(city.get("management_focus","")),float(city.get("population_share",0.0))])
	var days:=int(_arg("days","360"))
	var every:=maxi(1,int(_arg("every","15")))
	var start_day:=int(GameState.elapsed_days)
	_report(start_day)
	for i in days:
		var day:=start_day+i+1
		WorldSimulation.begin_day(day,terrain._discovery_context(),Callable(),Callable(),{})
		while WorldSimulation.day_in_progress():WorldSimulation.pump_day(0)
		if (i+1)%every==0:_report(day)
	get_tree().quit(0)

func _report(day:int)->void:
	var t:Dictionary=preload("res://scripts/hud/civilization_kpi_model.gd").snapshot()
	var towns:=PackedStringArray()
	for city:Dictionary in t.cities:
		towns.append("%s pop=%d stock=%.0f need=%.1f made=%.1f ate=%.1f net=%.1f" % [String(city.name),int(city.population),float(city.food_stock),float(city.food_need),float(city.food_produced),float(city.food_eaten),float(city.food_net)])
	var m:Dictionary=GameState.simulation_metrics
	print("HUNGER day=%d year=%.2f pop=%d residents=%.0f stock=%.0f need=%.1f made=%.1f ate=%.1f shortages=%d intake=%.2f | %s" % [day,day/365.0,int(t.population),float(t.residents),float(t.food_stock),float(t.food_need),float(t.food_produced),float(t.food_eaten),int(t.food_shortages),float(m.get("food_intake_ratio",-1)),"; ".join(towns)])
