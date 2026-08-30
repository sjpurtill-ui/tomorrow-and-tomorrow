extends Node3D

const FoodSystemScript := preload("res://scripts/food_system.gd")

func _settlement_model() -> Node:
	return get_node("/root/SettlementModel")

func _food_system() -> Node:
	return get_node("/root/FoodSystem")

const GRID_LONG_AXIS := 180
const SEAMLESS_WORLD := true
const PLANET_WIDTH_KM := 40075.0
const PLANET_DEPTH_KM := 20004.0
const GLOBAL_GRID_X := 481
const GLOBAL_GRID_Z := 241
const SEA_LEVEL := 0.0
const KM_PER_WORLD_UNIT := 1.0
const CONVOY_KM_PER_DAY := 16.0
const SPEED_HOURS_PER_REAL_SECOND := {1:0.5,2:2.0,3:8.0,4:24.0,5:72.0}
const SETTLEMENT_DETAIL_SCALE := 0.002
const CONVOY_DETAIL_SCALE := 0.0012
const SOCIETY_DYNAMICS := ["demography","nutrition","health","labor","knowledge","production","infrastructure","logistics","ecology","institutions","security","culture"]
const OFFICE_DYNAMICS := {
	"Steward":["demography","health","labor","institutions"],
	"Quartermaster":["nutrition","production","logistics","ecology"],
	"Scholar":["knowledge","culture","institutions","ecology"],
	"Marshal":["security","logistics","labor","institutions"],
	"Envoy":["culture","institutions","logistics","knowledge"]
}
const SOCIETY_SUBCATEGORY_NAMES := {
	"demography":["Fertility conditions","Maternal safety","Child survival","Shelter capacity"],
	"nutrition":["Daily supply","Diet quality","Stored reserve","Land productivity"],
	"health":["General health","Water & sanitation","Disease control","Injury safety"],
	"labor":["Able workforce","Work efficiency","Coordination","Workload balance"],
	"knowledge":["Observers","Directed attention","Preserved knowledge","Communication"],
	"production":["Material supply","Tool quality","Craft capacity","Standardization"],
	"infrastructure":["Housing","Construction","Public works","Resilience"],
	"logistics":["Carrying capacity","Route quality","Storage system","Trade reach"],
	"ecology":["Land health","Natural recovery","Pollution control","Resource sustainability"],
	"institutions":["Administration","Legitimacy","State capacity","Institutional flexibility"],
	"security":["Public safety","Organized defense","Military readiness","Crisis resilience"],
	"culture":["Social cohesion","Shared legitimacy","Inquiry breadth","Collective memory"]
}

var terrain_noise := FastNoiseLite.new()
var detail_noise := FastNoiseLite.new()
var continent_noise := FastNoiseLite.new()
var mountain_noise := FastNoiseLite.new()
var moisture_noise := FastNoiseLite.new()
var camera: Camera3D
var camera_target := Vector3.ZERO
var camera_yaw := -0.72
var camera_pitch := -0.98
var camera_distance := 92.0
var dragging := false
var rotating_camera := false
var grid_x := 80
var grid_z := 80
var world_width := 100.0
var world_depth := 100.0
var settler_panel: Control
var choice_status: Label
var settler_marker: Area3D
var terrain_body: StaticBody3D
var province_terrain_mesh: MeshInstance3D
var regional_terrain_patch: MeshInstance3D
var regional_patch_center := Vector2.INF
var regional_patch_span := 420.0
var world_start_position := Vector3.ZERO
var resource_sites: Array[Dictionary] = []
var nearby_resources_label: Label
var resource_action_button: Button
var building_buttons: Dictionary = {}
var nearest_resource_type := ""
var leader_panel: Control
var leader_dossier: VBoxContainer
var leader_candidate_list: VBoxContainer
var leader_explanation: Label
var leader_candidates: Array[Dictionary] = []
var inspected_leader := 0
var appoint_button: Button
var placement_building := ""
var placement_preview: MeshInstance3D
var placement_valid := false
var construction_projects: Array[Dictionary] = []
var hearth_established := false
var interface_layer: CanvasLayer
var government_panel: Control
var portrait_sheet: Texture2D
var leader_heading: Label
var pending_advisor_office := ""
var last_discovery_day := 0
var knowledge_panel: Control
var knowledge_record_container:VBoxContainer
var knowledge_record_signature:=""
var knowledge_investigation_widgets:Dictionary={}
var allocation_value_labels: Dictionary = {}
var population_value_labels: Dictionary = {}
var research_total_label: Label
var council_panel: Control
var mandate_panel: Control
var date_label: Label
var time_speed_buttons: Dictionary = {}
var travel_status_label: Label
var route_mesh: MeshInstance3D
var river_course := PackedFloat32Array()
var river_overlays: Array[MeshInstance3D] = []
var lens_panel: PanelContainer
var lens_body: RichTextLabel
var lens_location_label: Label
var lens_ring: MeshInstance3D
var lens_world_position := Vector3.ZERO
var lens_requested_visible:=false
var settlement_visual_root: Node3D
var detail_terrain_patch: MeshInstance3D
var close_vegetation_root: Node3D
var close_vegetation_revision := -1
var convoy_map_icon: Node3D
var convoy_banner_sprite: Sprite3D
var convoy_map_label: Label3D
var convoy_detail_root: Node3D
var settler_map_ring: MeshInstance3D
var settler_click_shape: CollisionShape3D
var settlement_progress_label: Label
var discovered_resource_overlays: Dictionary = {}
var settlement_footprint: MeshInstance3D
var settlement_blip: MeshInstance3D
var settlement_map_label:Label3D
var settlement_fabric_shader:Shader
var settlement_land_use_root: Node3D
var footprint_population := -1
var rendered_morphology_revision := -1
var rendered_settlement_lod := -1
var population_summary_label: Button
var provisions_button: Button
var provisions_panel: Control
var materials_button: Button
var materials_panel: Control
var people_summary_label: Label
var people_panel_title: Label
var age_distribution_bar: HBoxContainer
var age_distribution_title: Label
var age_distribution_summary: Label
var age_distribution_segments: Array[ColorRect]=[]
var age_distribution_segment_labels: Array[Label]=[]
var settlement_name_button: Button
var event_report_button: Button
var population_ledger_panel: Control
var settlement_naming_panel: Control
var settlement_name_input: LineEdit
var settlement_name_confirm: Button
var naming_previous_speed := 0.0
var suppress_naming_prompt := false
var scale_bar_root: Control
var scale_bar_line: ColorRect
var scale_bar_right_tick: ColorRect
var scale_bar_label: Label
var travel_council_notice: Button
var travel_council_notice_until_msec := 0
var start_settlement_button: Button
var travel_reported_milestones: Dictionary = {}
var travel_active := false
var travel_start := Vector3.ZERO
var travel_target := Vector3.ZERO
var travel_days_total := 0.0
var travel_days_elapsed := 0.0
var game_speed := 0.0
var world_menu_panel: Control
var world_seed_input: LineEdit
var world_seed_status: Label
var world_menu_previous_speed:=0.0
var society_panel:Control
var capture_render_active:=false

func _ready() -> void:
	_trace_load("ready")
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture="):
			capture_render_active=true
			break
	if SEAMLESS_WORLD:
		_configure_seamless_world()
	elif GameState.province_mask == null or GameState.province_mask.is_empty():
		_configure_preview_province()
	if GameState.founding_banner_index<0:
		GameState.founding_banner_index=abs(GameState.world_seed)%10
	last_discovery_day = int(floor(GameState.elapsed_days))
	DiscoverySystem.initialize()
	ConsequenceEngine.initialize()
	_configure_shape()
	_configure_noise()
	_prepare_river_course()
	world_start_position = _find_camp_position()
	_trace_load("world configured start=%s river_x=%.1f height=%.2f" % [world_start_position,_world_river_x(world_start_position.z),world_start_position.y])
	if SEAMLESS_WORLD:
		var view_direction:=Vector3(cos(camera_yaw),0.0,sin(camera_yaw))
		var view_right:=Vector3(-view_direction.z,0.0,view_direction.x)
		camera_target=world_start_position-view_right*30.0
		camera_target.y=_height_at(camera_target.x,camera_target.z)
	else:
		camera_target = world_start_position
	_build_environment()
	_build_terrain()
	_trace_load("global terrain")
	if not SEAMLESS_WORLD:
		_build_province_skirt()
	else:
		_rebuild_regional_terrain_patch(Vector2(world_start_position.x,world_start_position.z),620.0)
	_trace_load("regional terrain")
	_build_water()
	_build_river_network()
	_trace_load("water and rivers")
	_scatter_landscape_vegetation()
	_scatter_trees()
	_trace_load("landscape and resources")
	_place_settlers()
	_settlement_model().ensure_founded()
	_build_interface()
	_trace_load("settlement and interface")
	if not GenerativeDirector.campaign_goal_ready.is_connected(_on_campaign_goal_ready):
		GenerativeDirector.campaign_goal_ready.connect(_on_campaign_goal_ready)
	GenerativeDirector.request_campaign_goal(_campaign_public_context())
	_capture_preview_if_requested.call_deferred()

func _trace_load(stage: String) -> void:
	if "--trace-load" in OS.get_cmdline_user_args():
		print("LOAD STAGE ",stage)

func _configure_seamless_world() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--world-seed="):
			GameState.world_seed=int(argument.trim_prefix("--world-seed="))
	if GameState.world_seed == 0:
		GameState.world_seed = int(Time.get_unix_time_from_system()) ^ int(Time.get_ticks_usec())
	if GameState.founding_banner_index<0:
		GameState.founding_banner_index=abs(GameState.world_seed)%10
	var cradle_angle:=float(abs(GameState.world_seed)%6283)*0.001
	# Present the seeded home range toward the top of the regional view so the
	# first screen immediately reads as a watershed rather than a texture sample.
	camera_yaw=wrapf(PI-cradle_angle,-PI,PI)
	GameState.active_province = 0
	GameState.province_name = "The Known World"
	GameState.province_terrain = "Plains"
	GameState.province_aspect = PLANET_WIDTH_KM / PLANET_DEPTH_KM
	GameState.province_mask = null

func _capture_preview_if_requested() -> void:
	var capture_path := ""
	var capture_days := 0
	var capture_people_panel := false
	var capture_mandate_panel := false
	var capture_population_ledger := false
	var capture_naming_panel := false
	var capture_knowledge_panel := false
	var capture_world_menu := false
	var capture_society_panel := false
	var capture_travel := false
	var capture_settled := false
	var capture_growth_years := 0
	var capture_plot_lens := false
	var capture_zoom := -1.0
	var capture_pitch_degrees:=INF
	var capture_yaw_degrees:=INF
	var capture_population := -1
	var capture_allocations: Dictionary = {}
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture="):
			capture_path = argument.trim_prefix("--capture=")
		elif argument.begins_with("--capture-days="):
			capture_days = maxi(0, int(argument.trim_prefix("--capture-days=")))
		elif argument == "--capture-people":
			capture_people_panel = true
		elif argument == "--capture-mandate":
			capture_mandate_panel = true
		elif argument == "--capture-ledger":
			capture_population_ledger = true
		elif argument == "--capture-naming":
			capture_naming_panel = true
		elif argument == "--capture-knowledge":
			capture_knowledge_panel = true
		elif argument == "--capture-world-menu":
			capture_world_menu = true
		elif argument == "--capture-society":
			capture_society_panel = true
		elif argument == "--capture-travel":
			capture_travel = true
		elif argument == "--capture-settled":
			capture_settled = true
		elif argument.begins_with("--capture-growth-years="):
			capture_growth_years = maxi(0, int(argument.trim_prefix("--capture-growth-years=")))
		elif argument == "--capture-plot-lens":
			capture_plot_lens = true
		elif argument.begins_with("--capture-zoom="):
			capture_zoom = float(argument.trim_prefix("--capture-zoom="))
		elif argument.begins_with("--capture-pitch-deg="):
			capture_pitch_degrees=float(argument.trim_prefix("--capture-pitch-deg="))
		elif argument.begins_with("--capture-yaw-deg="):
			capture_yaw_degrees=float(argument.trim_prefix("--capture-yaw-deg="))
		elif argument.begins_with("--capture-population="):
			capture_population = maxi(1, int(argument.trim_prefix("--capture-population=")))
		elif argument.begins_with("--capture-allocation="):
			for assignment in argument.trim_prefix("--capture-allocation=").split(","):
				var pair:=assignment.split(":")
				if pair.size()==2 and GameState.population_allocations.has(pair[0]):
					capture_allocations[pair[0]]=maxi(0,int(pair[1]))
	if capture_path == "":
		return
	suppress_naming_prompt=capture_days>0 and not capture_naming_panel
	for role in capture_allocations:
		GameState.population_allocations[role]=capture_allocations[role]
	if not capture_allocations.is_empty():
		var capture_assigned:=0
		for role in GameState.POPULATION_ROLES:
			capture_assigned+=maxi(0,int(GameState.population_allocations.get(role,0)))
		if capture_assigned>0:
			for role in GameState.POPULATION_ROLES:
				GameState.population_allocation_percentages[role]=float(GameState.population_allocations.get(role,0))/float(capture_assigned)*100.0
		GameState.synchronize_population_allocations()
	if capture_settled and settler_marker:
		GameState.settlement_site_committed = true
		GameState.settlement_founded_at = settler_marker.position
		GameState.settlement_founded_day = int(floor(GameState.elapsed_days))
		if "Hearth Circle" not in GameState.settlement_completed:
			GameState.settlement_completed.append("Hearth Circle")
		_settlement_model().ensure_founded()
	if capture_travel:
		travel_start=settler_marker.position
		travel_target=travel_start+Vector3(3200.0,0.0,0.0)
		travel_target.y=_height_at(travel_target.x,travel_target.z)+0.002
		travel_days_total=maxf(240.0,float(capture_days))
		travel_days_elapsed=0.0
		travel_active=true
		GameState.convoy_traveling=true
		game_speed=1.0
		travel_reported_milestones.clear()
		_issue_travel_council_report("departure",0.0)
	if capture_days > 0:
		for day in capture_days:
			GameState.elapsed_days += 1.0
			var daily_context := _discovery_context()
			DiscoverySystem.process_day(daily_context)
			ResourceSystem.process_day(daily_context)
			_process_population_day(daily_context)
			_evaluate_travel_survival()
			_process_settlement_day()
			_refresh_discovered_resource_overlays()
			_update_time_interface()
			if capture_travel and not travel_active:
				break
		_refresh_event_report()
	if capture_population > 0:
		GameState.ensure_living_population(capture_population)
		GameState.housing_capacity = maxi(GameState.housing_capacity,capture_population + capture_population / 5)
		if capture_population >= 180 and "seed_selection" not in GameState.known_discoveries:
			GameState.known_discoveries.append("seed_selection")
		footprint_population = -1
	if capture_growth_years > 0 and "Hearth Circle" in GameState.settlement_completed:
		for work_name in ["Lean-to Shelters","Storage Pits","Open Work Area","Gathering Yard"]:
			if work_name not in GameState.settlement_completed: GameState.settlement_completed.append(work_name)
		GameState.population_allocations["Construction"] = 10
		GameState.population_allocations["Crafting"] = 12
		GameState.population_allocations["Logistics"] = 10
		GameState.simulation_metrics["labor_efficiency"] = 0.78
		GameState.resource_stockpiles["Timber"] = 80.0
		GameState.resource_stockpiles["Fiber Plants"] = 80.0
		if "seed_selection" not in GameState.known_discoveries: GameState.known_discoveries.append("seed_selection")
		GameState.resource_deposits.append({"id":"capture_fertile_ground","resource":"Fertile Soil","stage":"surveyed","position":GameState.settlement_founded_at+Vector3(2.0,0.0,0.8),"quality":0.92,"remaining":2600.0,"initial_amount":2600.0,"blockers":["cultivation access is still being organized"],"access":0.42,"route":0.18,"development":0.0})
		for growth_month in range(1,capture_growth_years*12+1):
			if growth_month%3==0:
				GameState.population_total+=1
				GameState.population_exact=float(GameState.population_total)
			GameState.resource_stockpiles["Timber"]=maxf(80.0,float(GameState.resource_stockpiles.get("Timber",0.0)))
			GameState.resource_stockpiles["Fiber Plants"]=maxf(80.0,float(GameState.resource_stockpiles.get("Fiber Plants",0.0)))
			GameState.elapsed_days=float(growth_month*30)
			_settlement_model().process_month(_settlement_spatial_context())
	_refresh_settlement_footprint(true)
	# Captures are state audits, not staged mockups. Refresh the HUD after synthetic
	# progression so year, population, food, label, and founding controls describe
	# the same authoritative state as the rendered settlement.
	_update_time_interface()
	if capture_plot_lens and not GameState.settlement_plots.is_empty():
		var inspected_plot:Dictionary=GameState.settlement_plots[0]
		for candidate_plot in GameState.settlement_plots:
			if String(candidate_plot.get("land_use",""))=="field": inspected_plot=candidate_plot; break
		var inspected_centroid:=Vector2(inspected_plot.get("centroid",Vector2.ZERO))
		var inspected_position:=Vector3(GameState.settlement_founded_at.x+inspected_centroid.x,0.0,GameState.settlement_founded_at.z+inspected_centroid.y)
		inspected_position.y=_height_at(inspected_position.x,inspected_position.z)
		_inspect_location(inspected_position)
	if capture_people_panel:
		if mandate_panel:
			mandate_panel.queue_free()
			mandate_panel=null
		settler_panel.visible = true
		lens_panel.visible = false
		_refresh_population_allocations()
	if capture_mandate_panel:
		_open_mandate_panel()
	elif capture_days>0 and mandate_panel:
		mandate_panel.queue_free()
		mandate_panel=null
	if capture_population_ledger:
		if mandate_panel:
			mandate_panel.queue_free()
			mandate_panel=null
		_open_population_ledger()
	if capture_naming_panel:
		if mandate_panel:
			mandate_panel.queue_free()
			mandate_panel=null
		_open_settlement_naming_panel()
	if capture_knowledge_panel:
		if mandate_panel:
			mandate_panel.queue_free()
			mandate_panel=null
		_open_knowledge_panel()
	if capture_world_menu:
		if mandate_panel:
			mandate_panel.queue_free()
			mandate_panel=null
		_open_world_menu()
	if capture_society_panel:
		if mandate_panel:
			mandate_panel.queue_free()
			mandate_panel=null
		_open_society_panel()
	if capture_zoom > 0.0:
		camera_target = settler_marker.position
		camera.size = capture_zoom
		if is_finite(capture_pitch_degrees): camera_pitch=clampf(deg_to_rad(capture_pitch_degrees),-1.50,-0.32)
		if is_finite(capture_yaw_degrees): camera_yaw=wrapf(deg_to_rad(capture_yaw_degrees),-PI,PI)
		_update_camera()
		_update_scale_lod()
	for frame in 18:
		await get_tree().process_frame
	if DisplayServer.get_name()!="headless":
		var image := get_viewport().get_texture().get_image()
		if image:
			image.save_png(ProjectSettings.globalize_path(capture_path))
	var route_hierarchy_counts:Dictionary={}
	for route in GameState.settlement_routes:
		var hierarchy:=String(route.get("hierarchy",route.get("kind","unclassified")))
		route_hierarchy_counts[hierarchy]=int(route_hierarchy_counts.get(hierarchy,0))+1
	var morphology_debug:Dictionary={"plots":GameState.settlement_plots.size(),"routes":GameState.settlement_routes.size(),"route_hierarchy":route_hierarchy_counts,"revision":GameState.morphology_revision,"founded_at":GameState.settlement_founded_at,"camera_target":camera_target,"lod":rendered_settlement_lod,"meshes":[]}
	if settlement_land_use_root:
		for child in settlement_land_use_root.get_children():
			if child is MeshInstance3D and (child as MeshInstance3D).mesh:
				morphology_debug.meshes.append({"name":child.name,"aabb":str((child as MeshInstance3D).mesh.get_aabb())})
	print("MORPHOLOGY RENDER ",JSON.stringify(morphology_debug))
	print("SIMULATION SNAPSHOT ",JSON.stringify({"day":GameState.elapsed_days,"population":GameState.population_total,"births":GameState.lifetime_births,"deaths":GameState.lifetime_deaths,"traveling":travel_active,"halt_reason":GameState.convoy_emergency_halt_reason,"allocations":GameState.population_allocations,"allocation_percentages":GameState.population_allocation_percentages,"metrics":GameState.simulation_metrics,"works":GameState.settlement_completed,"discoveries":GameState.known_discoveries,"goal":GameState.campaign_goal.get("title","")}))
	get_tree().quit()

func _configure_preview_province() -> void:
	GameState.world_seed = 184271
	GameState.active_province = 0
	GameState.province_name = "The Vale of Orra"
	GameState.province_terrain = "Hills"
	GameState.province_aspect = 1.38
	var width := 276
	var height := 200
	var mask := Image.create_empty(width, height, false, Image.FORMAT_RF)
	mask.fill(Color.BLACK)
	for py in height:
		for px in width:
			var nx := (float(px) / (width - 1) - 0.5) / 0.47
			var ny := (float(py) / (height - 1) - 0.5) / 0.43
			var angle := atan2(ny, nx)
			var radius := sqrt(nx * nx + ny * ny)
			var edge := 1.0 + sin(angle * 3.0 + 0.4) * 0.075 + sin(angle * 7.0 - 1.1) * 0.045 + sin(angle * 13.0) * 0.025
			if radius < edge:
				mask.set_pixel(px, py, Color.WHITE)
	GameState.province_mask = mask

func _process(delta: float) -> void:
	_process_camera_navigation(delta)
	_update_world_streaming()
	_update_scale_lod()
	_update_convoy_marker_animation()
	if travel_council_notice and travel_council_notice.visible and Time.get_ticks_msec()>travel_council_notice_until_msec:
		travel_council_notice.visible=false
	if game_speed <= 0.0:
		return
	var days_advanced := delta * _speed_hours_per_second()/24.0
	GameState.elapsed_days += days_advanced
	var current_discovery_day := int(floor(GameState.elapsed_days))
	while last_discovery_day < current_discovery_day:
		last_discovery_day += 1
		GameState.convoy_traveling=travel_active
		var daily_context := _discovery_context()
		var discoveries := DiscoverySystem.process_day(daily_context)
		var resource_events := ResourceSystem.process_day(daily_context)
		if not discoveries.is_empty() or not resource_events.is_empty():
			footprint_population = -1
		var simulation_events := _process_population_day(daily_context)
		_refresh_event_report()
		for consequence in simulation_events:
			if String(consequence.get("severity","")) in ["danger","critical","warning"]:
				AdvisorSystem.generate_consequence_item(consequence)
		for resource_event in resource_events:
			if String(resource_event.get("title","")) in ["Resource Flow Constrained","Material Losses","Resource Accessible"]:
				AdvisorSystem.generate_consequence_item({"description":String(resource_event.get("description","")),"domain":"materials","severity":"warning" if String(resource_event.get("title",""))!="Resource Accessible" else "notice"})
		_process_settlement_day()
		_settlement_model().process_month(_settlement_spatial_context(daily_context))
		_refresh_discovered_resource_overlays()
		_refresh_settlement_footprint()
		if not discoveries.is_empty() and travel_status_label:
			travel_status_label.text = "DISCOVERY: %s" % discoveries[0].name.to_upper()
		elif not resource_events.is_empty() and travel_status_label:
			travel_status_label.text = "%s: %s" % [resource_events[0].title.to_upper(), resource_events[0].description]
		elif not simulation_events.is_empty() and travel_status_label:
			travel_status_label.text = "%s: %s" % [simulation_events[0].title.to_upper(), simulation_events[0].description]
		_evaluate_travel_survival()
	if travel_active:
		var travel_speed_factor:=clampf(float(GameState.simulation_metrics.get("travel_speed_factor",1.0)),0.12,1.0)
		travel_days_elapsed += days_advanced*travel_speed_factor
		var progress := clampf(travel_days_elapsed / travel_days_total, 0.0, 1.0)
		var position := travel_start.lerp(travel_target, progress)
		position.y = _height_at(position.x, position.z) + 0.002
		settler_marker.position = position
		_check_travel_milestone_reports(progress)
		if progress >= 1.0:
			travel_active = false
			GameState.convoy_traveling=false
			GameState.convoy_emergency_halt_reason=""
			settler_marker.position = travel_target
			if route_mesh:
				route_mesh.visible = false
			_update_resource_proximity()
			_issue_travel_council_report("arrival",1.0)
	for project in construction_projects:
		if project.complete:
			continue
		project.remaining = maxf(0.0, project.remaining - days_advanced)
		var project_label: Label3D = project.label
		project_label.text = "%s\n%.1f days" % [project.name.to_upper(), project.remaining]
		if project.remaining <= 0.0:
			project.complete = true
			project_label.text = project.name.to_upper()
			if project.name == "Communal Hearth":
				hearth_established = true
			_update_building_buttons()
	_update_time_interface()

func _discovery_context() -> Dictionary:
	var context := {"foraging":0.78 if travel_active else 1.0, "food":1.0, "exploration":0.8 if travel_active else 0.5, "travel":1.0 if travel_active else 0.1, "fiber":0.5, "fire":0.6, "administration":0.5, "defense":0.3}
	context["traveling"]=travel_active
	context["travel_days_remaining"]=maxf(0.0,travel_days_total-travel_days_elapsed) if travel_active else 0.0
	context["travel_distance_remaining_km"]=Vector2(settler_marker.position.x,settler_marker.position.z).distance_to(Vector2(travel_target.x,travel_target.z))*KM_PER_WORLD_UNIT if travel_active and settler_marker else 0.0
	context["tools"] = ConsequenceEngine.tools_factor()
	context["insight"] = ConsequenceEngine.discovery_multiplier()
	if settler_marker:
		context["origin"] = GameState.settlement_founded_at if GameState.settlement_site_committed else settler_marker.position
	context["settled"] = GameState.settlement_site_committed
	if hearth_established:
		context["construction"] = 1.0
		context["storage"] = 0.8
		context["timber"] = 0.7
	for site in resource_sites:
		var type: String = site.type
		if type == "Timber": context["timber"] = 1.0
		elif type == "Stone": context["stone"] = 1.0
		elif type == "Fertile": context["food"] = 1.3
		elif type == "Freshwater": context["freshwater"] = 1.0
	return context

func _settlement_spatial_context(base:Dictionary={}) -> Dictionary:
	var context:=base.duplicate(false)
	context["terrain_height_at"]=Callable(self,"_height_at")
	context["river_distance_at"]=Callable(self,"_river_distance_at")
	context["moisture_at"]=Callable(self,"_land_moisture_at")
	context["settlement_origin"]=GameState.settlement_founded_at
	return context

func _land_moisture_at(x:float,z:float)->float:
	return moisture_noise.get_noise_2d(x,z)

func _campaign_public_context() -> Dictionary:
	return {
		"world_seed":GameState.world_seed,
		"province":GameState.province_name,
		"terrain":GameState.province_terrain,
		"population":GameState.population_total,
		"starting_food_days":roundi(float(GameState.simulation_metrics.get("food_days",30.0))),
		"known_resources":[],
		"known_discoveries":GameState.known_discoveries.duplicate()
	}

func _on_campaign_goal_ready(_goal: Dictionary) -> void:
	_update_time_interface()
	if capture_render_active:
		return
	if mandate_panel:
		_open_mandate_panel()
	elif GameState.elapsed_days<0.01:
		_open_mandate_panel()

func _configure_shape() -> void:
	if SEAMLESS_WORLD:
		grid_x = GLOBAL_GRID_X
		grid_z = GLOBAL_GRID_Z
		world_width = PLANET_WIDTH_KM
		world_depth = PLANET_DEPTH_KM
		return
	var aspect: float = clampf(GameState.province_aspect, 0.45, 2.2)
	if aspect >= 1.0:
		grid_x = GRID_LONG_AXIS
		grid_z = maxi(48, roundi(GRID_LONG_AXIS / aspect))
		world_width = 112.0
		world_depth = world_width / aspect
	else:
		grid_z = GRID_LONG_AXIS
		grid_x = maxi(48, roundi(GRID_LONG_AXIS * aspect))
		world_depth = 112.0
		world_width = world_depth * aspect

func _configure_noise() -> void:
	var local_seed: int = GameState.world_seed ^ ((GameState.active_province + 1) * 104729)
	if SEAMLESS_WORLD:
		continent_noise.seed = GameState.world_seed
		continent_noise.frequency = 0.000105
		continent_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
		continent_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
		continent_noise.fractal_octaves = 5
		continent_noise.fractal_lacunarity = 2.05
		continent_noise.fractal_gain = 0.52
		mountain_noise.seed = GameState.world_seed ^ 0x2c9277b5
		mountain_noise.frequency = 0.00072
		mountain_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
		mountain_noise.fractal_type = FastNoiseLite.FRACTAL_RIDGED
		mountain_noise.fractal_octaves = 5
		terrain_noise.seed = local_seed
		terrain_noise.frequency = 0.0032
		terrain_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
		terrain_noise.fractal_octaves = 5
		detail_noise.seed = local_seed ^ 0x45d9f3b
		detail_noise.frequency = 0.028
		detail_noise.fractal_octaves = 4
		moisture_noise.seed = GameState.world_seed ^ 0x71a94c31
		moisture_noise.frequency = 0.00048
		moisture_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
		moisture_noise.fractal_octaves = 4
		return
	terrain_noise.seed = local_seed
	terrain_noise.frequency = 0.028
	terrain_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	terrain_noise.fractal_octaves = 5
	detail_noise.seed = local_seed ^ 0x45d9f3b
	detail_noise.frequency = 0.085
	detail_noise.fractal_octaves = 3

func _height_at(x: float, z: float) -> float:
	if SEAMLESS_WORLD:
		return _world_height_at(x,z)
	var broad := terrain_noise.get_noise_2d(x, z)
	var detail := detail_noise.get_noise_2d(x, z)
	var scale := 2.7
	if GameState.province_terrain == "Hills": scale = 3.8
	elif GameState.province_terrain == "Mountains": scale = 8.5
	elif GameState.province_terrain == "Marsh": scale = 1.6
	var ridge: float = 1.0 - absf(terrain_noise.get_noise_2d(x * 0.61 + 410.0, z * 0.61 - 270.0))
	ridge = pow(maxf(0.0, ridge - 0.48) / 0.52, 3.4)
	var ridge_region: float = clampf((terrain_noise.get_noise_2d(x * 0.28 - 810.0, z * 0.28 + 620.0) + 0.08) * 2.8, 0.0, 1.0)
	var ridge_scale := 3.5
	if GameState.province_terrain == "Hills": ridge_scale = 4.8
	elif GameState.province_terrain == "Mountains": ridge_scale = 12.5
	elif GameState.province_terrain == "Marsh": ridge_scale = 1.2
	var ridge_height: float = ridge * ridge_region * ridge_scale
	var edge_factor := _province_edge_factor(x, z)
	var height := (broad * scale + detail * 0.58 + ridge_height) * edge_factor
	if not river_course.is_empty():
		var v := z / world_depth + 0.5
		var river_u := _river_u_at_v(v)
		if river_u >= 0.0:
			var river_x := (river_u - 0.5) * world_width
			var distance := absf(x - river_x)
			var floodplain_width := 13.0 if GameState.province_terrain == "Mountains" else 19.0
			if distance < floodplain_width:
				var floodplain := pow(1.0-distance/floodplain_width,1.65)
				var plain_target := broad*0.82+detail*0.10-0.34+distance*0.025
				height=lerpf(height,minf(height,plain_target),floodplain*0.88)
			if distance < 5.2:
				var valley := pow(1.0 - distance / 5.2, 2.0)
				var river_target := broad * 1.15 + detail * 0.12 - 0.72
				height = lerpf(height, minf(height, river_target), valley * 0.92)
				if distance < 1.15:
					height -= pow(1.0 - distance / 1.15, 2.0) * 0.42
	return height

func _close_surface_height_at(x: float, z: float) -> float:
	# World units are kilometres. These two terms add roughly metre-scale undulation
	# only to the close terrain skin; they never deform the authoritative planet.
	var broad_micro := detail_noise.get_noise_2d(x * 720.0 + 117.0, z * 720.0 - 83.0) * 0.00072
	var fine_micro := detail_noise.get_noise_2d(x * 2600.0 - 311.0, z * 2600.0 + 197.0) * 0.00017
	return _height_at(x, z) + broad_micro + fine_micro

func _world_height_at(x: float,z: float) -> float:
	# World coordinates are kilometres. The same function is sampled by the
	# planetary mesh and by the close regional patches, so zoom never swaps maps.
	var latitude := clampf(absf(z)/(world_depth*0.5),0.0,1.0)
	var continental := continent_noise.get_noise_2d(x,z)*0.78
	continental += continent_noise.get_noise_2d(x*0.47+7813.0,z*0.47-4197.0)*0.34
	var cradle := exp(-pow(x/1150.0,2.0)-pow(z/880.0,2.0))*1.05
	var land_signal := continental+cradle-0.075-pow(latitude,3.2)*0.72
	if land_signal<=0.0:
		return -0.06-pow(-land_signal,1.22)*6.8
	var rolling := terrain_noise.get_noise_2d(x,z)
	var local_detail := detail_noise.get_noise_2d(x,z)
	var hill_signal:=maxf(0.0,terrain_noise.get_noise_2d(x+820.0,z-460.0)+0.10)
	var ridge := 1.0-absf(mountain_noise.get_noise_2d(x,z))
	ridge = pow(clampf((ridge-0.34)/0.66,0.0,1.0),2.35)
	var belt := clampf((mountain_noise.get_noise_2d(x*0.41+9200.0,z*0.41-3800.0)+0.18)*1.55,0.0,1.0)
	var height := 0.06+land_signal*1.48+rolling*1.42+local_detail*0.56+pow(hill_signal,2.0)*2.05+ridge*belt*8.4
	# Continental noise establishes mountain belts, but it cannot by itself make a
	# six-kilometre camera footprint read as terrain. Add seeded kilometre-scale
	# hills and low ridges to the authoritative height field so visuals, travel and
	# settlement siting all agree about the same landforms.
	var regional_roll:=detail_noise.get_noise_2d(x*7.5+1640.0,z*7.5-930.0)*0.055
	var regional_ridge_signal:=1.0-absf(detail_noise.get_noise_2d(x*4.2-2710.0,z*4.2+1850.0))
	var regional_ridge:=pow(clampf((regional_ridge_signal-0.48)/0.52,0.0,1.0),2.2)*0.075
	var regional_weight:=smoothstep(0.04,0.28,land_signal)
	height+=(regional_roll+regional_ridge)*regional_weight
	# Every founding watershed has legible regional structure. Its orientation is
	# seeded, while the individual peaks still come from the planetary noise field.
	var cradle_angle:=float(abs(GameState.world_seed)%6283)*0.001
	var cradle_x:=x*cos(cradle_angle)-z*sin(cradle_angle)
	var cradle_z:=x*sin(cradle_angle)+z*cos(cradle_angle)
	var range_band:=exp(-pow((cradle_x-55.0)/25.0,2.0))*exp(-pow(cradle_z/510.0,4.0))
	var range_teeth:=pow(clampf((1.0-absf(detail_noise.get_noise_2d(x*0.72+330.0,z*0.72-710.0))-0.20)/0.80,0.0,1.0),1.55)
	height+=range_band*(0.65+range_teeth*6.8)
	var river_x := _world_river_x(z)
	if river_x!=INF:
		var distance:=absf(x-river_x)
		if distance<4.8:
			var floodplain:=pow(1.0-distance/4.8,1.65)
			height=lerpf(height,minf(height,0.22+rolling*0.08),floodplain*0.90)
		if distance<0.34:
			height-=pow(1.0-distance/0.34,2.0)*0.0065
	return height

func _world_river_x(z: float) -> float:
	if absf(z)>760.0:
		return INF
	return -18.0+sin(z/128.0+float(GameState.world_seed%97)*0.031)*32.0+sin(z/57.0-0.8)*14.0+sin(z/21.0+1.7)*4.5

func _prepare_river_course() -> void:
	river_course.clear()
	if SEAMLESS_WORLD:
		for i in 3201:
			var v:=float(i)/3200.0
			var z:=(v-0.5)*world_depth
			var river_x:=_world_river_x(z)
			river_course.append(-1.0 if river_x==INF else river_x/world_width+0.5)
		return
	var phase := float(abs(terrain_noise.seed) % 997) * 0.013
	for i in 241:
		var v := float(i) / 240.0
		var span := _province_span_at_v(v)
		if span.x < 0.0 or span.y - span.x < 0.08:
			river_course.append(-1.0)
			continue
		# A river is a regional spine, not a trace of every pixel-scale change in the
		# province silhouette. Keep its wavelength long and then relax it inside the mask.
		var center := (span.x + span.y) * 0.5
		var long_meander := sin(v * TAU * 1.12 + phase) * 0.078
		long_meander += sin(v * TAU * 2.35 + phase * 0.43) * 0.026
		var target := lerpf(0.5 + long_meander, center, 0.24)
		river_course.append(clampf(target, span.x + 0.035, span.y - 0.035))
	# Repeated relaxation removes kinks introduced where an irregular province narrows.
	for pass_index in 14:
		var relaxed: Array[float] = []
		relaxed.resize(river_course.size())
		for i in river_course.size():
			var current: float = river_course[i]
			if current < 0.0 or i == 0 or i == river_course.size() - 1:
				relaxed[i] = current
				continue
			var previous: float = river_course[i - 1]
			var following: float = river_course[i + 1]
			if previous < 0.0 or following < 0.0:
				relaxed[i] = current
				continue
			var v := float(i) / float(river_course.size() - 1)
			var span := _province_span_at_v(v)
			var smoothed := previous * 0.24 + current * 0.52 + following * 0.24
			relaxed[i] = clampf(smoothed, span.x + 0.035, span.y - 0.035)
		river_course = relaxed

func _river_u_at_v(v: float) -> float:
	if river_course.is_empty() or v < 0.0 or v > 1.0:
		return -1.0
	var position := v * float(river_course.size() - 1)
	var lower := clampi(floori(position), 0, river_course.size() - 1)
	var upper := clampi(lower + 1, 0, river_course.size() - 1)
	if river_course[lower] < 0.0 or river_course[upper] < 0.0:
		return -1.0
	return lerpf(river_course[lower], river_course[upper], position - lower)

func _province_edge_factor(x: float, z: float) -> float:
	if GameState.province_mask == null or GameState.province_mask.is_empty():
		return 1.0
	var u := x / world_width + 0.5
	var v := z / world_depth + 0.5
	var factor := 1.0
	for sample in [{"r": 0.018, "f": 0.35}, {"r": 0.040, "f": 0.62}, {"r": 0.068, "f": 0.82}]:
		for direction in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN, Vector2(-0.707, -0.707), Vector2(0.707, -0.707), Vector2(-0.707, 0.707), Vector2(0.707, 0.707)]:
			var check: Vector2 = Vector2(u, v) + direction * float(sample.r)
			if not _inside_province(check.x, check.y):
				factor = minf(factor, float(sample.f))
	return factor

func _build_environment() -> void:
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("#0b1417")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("#b8b6a9")
	settings.ambient_light_energy = 0.29 if SEAMLESS_WORLD else 0.36
	settings.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.environment = settings
	add_child(environment)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -38, 0)
	sun.light_color = Color("#dfd1b5")
	sun.light_energy = 0.82 if SEAMLESS_WORLD else 0.66
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 900.0 if SEAMLESS_WORLD else 180.0
	add_child(sun)

	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 190.0 if SEAMLESS_WORLD else 108.0
	camera.near = 0.05
	camera.far = 100000.0
	camera.current = true
	add_child(camera)
	_update_camera()

func _build_terrain() -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	if SEAMLESS_WORLD:
		for z in grid_z:
			for x in grid_x:
				_add_terrain_vertex(surface,x,z)
		for z in grid_z-1:
			for x in grid_x-1:
				var a:=z*grid_x+x
				var b:=a+1
				var d:=(z+1)*grid_x+x
				var c:=d+1
				for index in [a,b,c,a,c,d]:
					surface.add_index(index)
	else:
		for z in grid_z - 1:
			for x in grid_x - 1:
				if _inside_province(float(x + 0.5) / (grid_x - 1), float(z + 0.5) / (grid_z - 1)):
					_add_terrain_vertex(surface, x, z)
					_add_terrain_vertex(surface, x + 1, z)
					_add_terrain_vertex(surface, x + 1, z + 1)
					_add_terrain_vertex(surface, x, z)
					_add_terrain_vertex(surface, x + 1, z + 1)
					_add_terrain_vertex(surface, x, z + 1)
		surface.index()
	surface.generate_normals()
	var mesh_instance := MeshInstance3D.new()
	province_terrain_mesh = mesh_instance
	mesh_instance.mesh = surface.commit()
	mesh_instance.material_override = _create_terrain_material()
	add_child(mesh_instance)
	if not SEAMLESS_WORLD:
		mesh_instance.create_trimesh_collision()
		terrain_body = mesh_instance.get_child(0) as StaticBody3D
		if terrain_body:
			terrain_body.name = "TerrainBody"

func _rebuild_regional_terrain_patch(center: Vector2,span: float) -> void:
	if not SEAMLESS_WORLD:
		return
	# Stream the same procedural planet down to settlement scale. The previous
	# 80 km floor left only one terrain vertex per ~500 m when the player was
	# looking at a village, producing a flat, blurred plate beneath detailed plots.
	span=clampf(span,0.9,920.0)
	var snap_step:=maxf(0.04,span/12.0)
	var snapped:=Vector2(round(center.x/snap_step)*snap_step,round(center.y/snap_step)*snap_step)
	if regional_terrain_patch and regional_patch_center.distance_to(snapped)<snap_step*0.72 and absf(regional_patch_span-span)<maxf(14.0,span*0.12):
		return
	regional_patch_center=snapped
	regional_patch_span=span
	if regional_terrain_patch:
		regional_terrain_patch.queue_free()
	var resolution:=161
	var surface:=SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z_index in resolution:
		for x_index in resolution:
			var x:=snapped.x+(float(x_index)/(resolution-1)-0.5)*span
			var z:=snapped.y+(float(z_index)/(resolution-1)-0.5)*span
			var height:=_height_at(x,z)+0.0006
			surface.set_color(_terrain_color_at(x,z,height))
			surface.add_vertex(Vector3(x,height,z))
	for z_index in resolution-1:
		for x_index in resolution-1:
			var a:=z_index*resolution+x_index
			var b:=a+1
			var d:=(z_index+1)*resolution+x_index
			var c:=d+1
			for index in [a,b,c,a,c,d]:
				surface.add_index(index)
	surface.generate_normals()
	regional_terrain_patch=MeshInstance3D.new()
	regional_terrain_patch.name="RegionalTerrainLOD"
	regional_terrain_patch.mesh=surface.commit()
	regional_terrain_patch.material_override=_create_terrain_material()
	add_child(regional_terrain_patch)

func _create_terrain_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode diffuse_burley, specular_disabled;

uniform sampler2D ground_albedo : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D forest_albedo : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D regional_albedo : source_color, repeat_enable, filter_linear_mipmap_anisotropic;

varying vec3 world_position;
varying vec3 world_normal;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 345.45));
	p += dot(p, p + 34.345);
	return fract(p.x * p.y);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash21(i), hash21(i + vec2(1.0, 0.0)), f.x),
		mix(hash21(i + vec2(0.0, 1.0)), hash21(i + vec2(1.0, 1.0)), f.x), f.y);
}

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}

void fragment() {
	float broad = value_noise(world_position.xz * 0.075);
	float regional = value_noise(world_position.xz * 0.24 + vec2(17.0, -9.0));
	float slope = 1.0 - clamp(dot(normalize(world_normal), vec3(0.0, 1.0, 0.0)), 0.0, 1.0);
	float pixel_world = max(length(dFdx(world_position.xz)), length(dFdy(world_position.xz)));
	// The material is a scale hierarchy, not one photograph enlarged forever.
	// World units are kilometres.  Country and regional imagery only enters once
	// the projected pixel footprint can actually resolve it; this also prevents
	// visible texture repetition in continental and low-oblique views.
	float country_detail = 1.0 - smoothstep(0.55, 4.50, pixel_world);
	float regional_detail = 1.0 - smoothstep(0.028, 0.42, pixel_world);
	float close_detail = 1.0 - smoothstep(0.004, 0.032, pixel_world);
	vec2 country_uv = world_position.xz * 0.00072;
	vec2 country_uv_rotated = vec2(-country_uv.y, country_uv.x) * 1.19 + vec2(0.317, 0.681);
	vec2 map_uv = world_position.xz * 0.0068;
	vec2 map_uv_rotated = vec2(-map_uv.y, map_uv.x) * 1.31 + vec2(0.317, 0.681);
	vec2 close_uv = world_position.xz * 18.0;
	vec2 close_uv_rotated = vec2(-close_uv.y, close_uv.x) * 0.83 + vec2(0.19, -0.27);
	float biome_patch = value_noise(world_position.xz * 0.018 + vec2(-5.0, 11.0));
	float soil_patch = value_noise(world_position.xz * 0.085 + vec2(23.0, -17.0));
	vec3 vertex_tint = mix(vec3(dot(COLOR.rgb, vec3(0.28,0.57,0.15))), COLOR.rgb, 0.78);
	vec3 climate_ground = mix(vec3(0.31,0.275,0.165), vec3(0.245,0.345,0.205), clamp(biome_patch*0.58+broad*0.42,0.0,1.0));
	climate_ground = mix(climate_ground, vertex_tint, 0.72);
	climate_ground *= 0.91 + (value_noise(world_position.xz*0.0032)-0.5)*0.15;
	vec3 procedural_ground = mix(climate_ground, mix(vec3(0.255,0.245,0.165), vec3(0.405,0.385,0.245), broad * 0.62 + biome_patch * 0.38), country_detail*0.38);
	procedural_ground *= 0.92 + (soil_patch - 0.5) * mix(0.04,0.17,country_detail);
	vec3 country_a = texture(regional_albedo, country_uv).rgb;
	vec3 country_b = texture(regional_albedo, country_uv_rotated).rgb;
	vec3 country_map = mix(country_a, country_b, 0.16);
	vec3 satellite_a = texture(regional_albedo, map_uv).rgb;
	vec3 satellite_b = texture(regional_albedo, map_uv_rotated * 0.79 + vec2(0.41, 0.13)).rgb;
	vec3 satellite_map = mix(satellite_a, satellite_b, 0.08);
	vec3 ground_map = mix(procedural_ground, country_map, country_detail * 0.72);
	ground_map = mix(ground_map, satellite_map, regional_detail * 0.84);
	vec3 procedural_forest = mix(vec3(0.055,0.105,0.070), vec3(0.155,0.205,0.125), biome_patch * 0.62 + regional * 0.38);
	vec3 forest_map = mix(procedural_forest, country_map * vec3(0.68,0.84,0.67), country_detail * 0.68);
	forest_map = mix(forest_map, satellite_map * vec3(0.68,0.84,0.67), regional_detail * 0.80);
	vec3 ground_close = mix(texture(ground_albedo, close_uv).rgb, texture(ground_albedo, close_uv_rotated).rgb, 0.32);
	vec3 forest_close = mix(texture(forest_albedo, close_uv * 0.72).rgb, texture(forest_albedo, close_uv_rotated * 0.64).rgb, 0.28);
	vec3 ground_sample = mix(ground_map, ground_close, close_detail * 0.66);
	vec3 forest_sample = mix(forest_map, forest_close, close_detail * 0.60);
	float ground_luma = dot(ground_sample, vec3(0.28, 0.57, 0.15));
	float forest_luma = dot(forest_sample, vec3(0.28, 0.57, 0.15));
	vec3 ground_surface = mix(vec3(ground_luma), ground_sample, 0.88);
	ground_surface = mix(vec3(0.29, 0.30, 0.22), ground_surface, 0.79);
	vec3 forest_surface = mix(vec3(forest_luma), forest_sample, 0.76);
	forest_surface = mix(vec3(0.058, 0.108, 0.069), forest_surface, 0.77);
	float green_bias = COLOR.g - max(COLOR.r, COLOR.b * 0.82);
	float forest_mask = smoothstep(0.025, 0.105, green_bias) * (1.0 - smoothstep(0.30, 0.72, slope));
	float woodland_mass = smoothstep(0.36, 0.76, biome_patch + (regional - 0.5) * 0.20);
	forest_mask = max(forest_mask, woodland_mass * 0.46 * (1.0 - smoothstep(0.34, 0.76, slope)));
	forest_mask *= 0.80 + broad * 0.28;
	vec3 earth = mix(ground_surface, forest_surface, clamp(forest_mask, 0.0, 0.96));
	earth = mix(earth, vertex_tint, mix(0.30, 0.12, regional_detail));
	float open_meadow = smoothstep(0.58,0.78,soil_patch) * (1.0-forest_mask) * (1.0-close_detail*0.45);
	float dryland_mass = smoothstep(0.64,0.82,value_noise(world_position.xz*0.029+vec2(61.0,-47.0))) * (1.0-forest_mask);
	earth = mix(earth, vec3(0.34,0.37,0.205), open_meadow*0.30);
	earth = mix(earth, vec3(0.43,0.37,0.235), dryland_mass*0.26);
	float dry_patch = smoothstep(0.63, 0.84, value_noise(world_position.xz * 1.7 + vec2(-31.0, 22.0))) * close_detail;
	float worn_patch = smoothstep(0.70, 0.91, value_noise(world_position.xz * 7.5 + vec2(8.0, -14.0))) * close_detail;
	earth = mix(earth, vec3(0.36, 0.315, 0.21), dry_patch * 0.28);
	earth = mix(earth, vec3(0.25, 0.245, 0.18), worn_patch * 0.12);
	// At settlement scale introduce coherent tens-of-metres aerial variation.
	// This is the missing layer between a regional satellite image and centimetre
	// grass grain: exposed soil, moisture pockets and irregular open ground.
	float close_soil_mass = smoothstep(0.43,0.72,value_noise(world_position.xz*24.0+vec2(-53.0,19.0))) * close_detail * (1.0-forest_mask);
	float close_lush_mass = smoothstep(0.47,0.75,value_noise(world_position.xz*15.0+vec2(37.0,-61.0))) * close_detail * (1.0-slope);
	float close_clearings = smoothstep(0.62,0.86,value_noise(world_position.xz*36.0+vec2(11.0,47.0))) * close_detail * (1.0-forest_mask);
	earth = mix(earth,vec3(0.39,0.335,0.225),close_soil_mass*0.43);
	earth = mix(earth,vec3(0.19,0.285,0.145),close_lush_mass*0.27);
	earth = mix(earth,vec3(0.31,0.295,0.205),close_clearings*0.16);
	float modulation = 0.94 + (broad - 0.5) * 0.11 + (regional - 0.5) * 0.06;
	earth *= modulation;
	vec3 exposed_rock = mix(vec3(0.25,0.245,0.225), vertex_tint * 0.78, 0.35);
	float rock_mask = smoothstep(0.16, 0.56, slope) * smoothstep(-0.8, 4.8, world_position.y);
	earth = mix(earth, exposed_rock, rock_mask * 0.78);
	float highland = smoothstep(5.8, 12.0, world_position.y) * (0.35 + slope * 0.65);
	earth = mix(earth, vec3(0.40,0.39,0.36), highland * 0.36);
	// A fixed north-west sun gives the orthographic world the same readable relief
	// cues as satellite hillshade. Keep the effect restrained at close range where
	// the scene lights and metre-scale texture already carry the form.
	float hill_light = dot(normalize(world_normal), normalize(vec3(-0.46, 0.78, -0.42)));
	vec3 horizontal_sun = normalize(vec3(-0.46, 0.0, -0.42));
	float directional_slope = dot(normalize(world_normal), horizontal_sun);
	float hillshade = clamp(1.0 + directional_slope * 5.8 - slope * 0.16, 0.70, 1.22);
	float regional_relief = 1.0 - close_detail * 0.62;
	earth *= mix(1.0, hillshade, regional_relief * 0.72);
	float ridge_glint = smoothstep(0.12, 0.62, slope) * smoothstep(0.25, 0.82, hill_light) * regional_relief;
	earth = mix(earth, vec3(0.48,0.46,0.40), ridge_glint * 0.20);
	// Close aerial imagery needs a different exposure than the shaded regional
	// relief map. Without this lift the settlement-scale ground fell nearly black.
	earth *= mix(1.0, 1.32, close_detail);
	earth = mix(earth, max(earth, vec3(0.105,0.112,0.072)), close_detail * 0.72);
	ALBEDO = earth;
	ROUGHNESS = 0.96;
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	var ground_texture: Texture2D = load("res://assets/terrain/temperate_ground_albedo_v1.png")
	var forest_texture: Texture2D = load("res://assets/terrain/temperate_forest_albedo_v1.png")
	var regional_texture: Texture2D = load("res://assets/terrain/temperate_regional_satellite_v2.png")
	material.set_shader_parameter("ground_albedo",ground_texture)
	material.set_shader_parameter("forest_albedo",forest_texture)
	material.set_shader_parameter("regional_albedo",regional_texture)
	return material

func _add_terrain_vertex(surface: SurfaceTool, grid_x: int, grid_z: int) -> void:
	var x := (float(grid_x) / (self.grid_x - 1) - 0.5) * world_width
	var z := (float(grid_z) / (self.grid_z - 1) - 0.5) * world_depth
	var height := _height_at(x, z)
	surface.set_color(_terrain_color_at(x, z, height))
	surface.add_vertex(Vector3(x, height, z))

func _terrain_color_at(x: float, z: float, height: float) -> Color:
	if SEAMLESS_WORLD:
		var moisture:=moisture_noise.get_noise_2d(x,z)+terrain_noise.get_noise_2d(x+1700.0,z-2300.0)*0.36
		var warmth:=1.0-clampf(absf(z)/(world_depth*0.5),0.0,1.0)
		if height<SEA_LEVEL:
			return Color("#21363a")
		var color:=Color("#676a50")
		if moisture>-0.12:
			color=color.lerp(Color("#304b36"),clampf((moisture+0.24)*1.45,0.12,0.78))
		elif moisture<-0.38:
			color=color.lerp(Color("#8b744f"),clampf((-moisture-0.30)*1.25,0.0,0.45))
		if warmth<0.20:
			color=color.lerp(Color("#c4c6bd"),clampf((0.20-warmth)*4.0,0.0,0.84))
		if height>3.2:
			color=color.lerp(Color("#77766f"),clampf((height-3.2)/5.2,0.0,0.74))
		var river_x:=_world_river_x(z)
		if river_x!=INF:
			var river_distance:=absf(x-river_x)
			if river_distance<14.0:
				var valley:=pow(1.0-river_distance/14.0,1.35)
				color=color.lerp(Color("#365443"),valley*0.38)
				if river_distance<3.8: color=color.lerp(Color("#29473a"),pow(1.0-river_distance/3.8,1.7)*0.44)
		return color
	var moisture := detail_noise.get_noise_2d(x + 900.0, z - 700.0)
	var dry_noise := terrain_noise.get_noise_2d(x - 640.0, z + 510.0)
	var woodland_noise := terrain_noise.get_noise_2d(x * 1.35 + 1300.0, z * 1.35 - 800.0)
	var color := Color("#66654c")
	if GameState.province_terrain == "Forest": color = Color("#455540")
	elif GameState.province_terrain == "Mountains": color = Color("#5b5b52")
	elif GameState.province_terrain == "Marsh": color = Color("#4b5d54")
	if moisture > 0.08:
		color = color.lerp(Color("#445b3f"), clampf((moisture - 0.08) * 0.82, 0.0, 0.42))
	elif dry_noise > 0.22:
		color = color.lerp(Color("#81785a"), clampf((dry_noise - 0.22) * 0.50, 0.0, 0.24))
	if height > 6.5:
		color = color.lerp(Color("#aaa798"), clampf((height - 6.5) / 18.0, 0.0, 0.58))
	if height < -2.0:
		color = color.lerp(Color("#536553"), 0.22)
	var woodland_threshold := -0.16 if GameState.province_terrain == "Forest" else 0.03
	if woodland_noise > woodland_threshold and height < 8.5:
		var woodland_strength := clampf((woodland_noise - woodland_threshold) * 1.9 + 0.18, 0.0, 0.62)
		color = color.lerp(Color("#203b2d"), woodland_strength)
	return color

func _cell_inside(x: int, z: int) -> bool:
	if x < 0 or z < 0 or x >= grid_x - 1 or z >= grid_z - 1:
		return false
	return _inside_province(float(x + 0.5) / (grid_x - 1), float(z + 0.5) / (grid_z - 1))

func _grid_world(x: int, z: int) -> Vector3:
	var world_x := (float(x) / (grid_x - 1) - 0.5) * world_width
	var world_z := (float(z) / (grid_z - 1) - 0.5) * world_depth
	return Vector3(world_x, _height_at(world_x, world_z), world_z)

func _add_skirt_quad(surface: SurfaceTool, a: Vector3, b: Vector3, base_y: float) -> void:
	var top_color := Color("#514b3d")
	var base_color := Color("#25241f")
	var a_bottom := Vector3(a.x, base_y, a.z)
	var b_bottom := Vector3(b.x, base_y, b.z)
	surface.set_color(top_color)
	surface.add_vertex(a)
	surface.set_color(top_color)
	surface.add_vertex(b)
	surface.set_color(base_color)
	surface.add_vertex(b_bottom)
	surface.set_color(top_color)
	surface.add_vertex(a)
	surface.set_color(base_color)
	surface.add_vertex(b_bottom)
	surface.set_color(base_color)
	surface.add_vertex(a_bottom)

func _build_province_skirt() -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var base_y := -5.4
	for z in grid_z - 1:
		for x in grid_x - 1:
			if not _cell_inside(x, z):
				continue
			if not _cell_inside(x - 1, z):
				_add_skirt_quad(surface, _grid_world(x, z + 1), _grid_world(x, z), base_y)
			if not _cell_inside(x + 1, z):
				_add_skirt_quad(surface, _grid_world(x + 1, z), _grid_world(x + 1, z + 1), base_y)
			if not _cell_inside(x, z - 1):
				_add_skirt_quad(surface, _grid_world(x, z), _grid_world(x + 1, z), base_y)
			if not _cell_inside(x, z + 1):
				_add_skirt_quad(surface, _grid_world(x + 1, z + 1), _grid_world(x, z + 1), base_y)
	var skirt_mesh := surface.commit()
	if skirt_mesh == null:
		return
	var skirt := MeshInstance3D.new()
	skirt.name = "ProvinceCutaway"
	skirt.mesh = skirt_mesh
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = 1.0
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	skirt.material_override = material
	add_child(skirt)

func _inside_province(u: float, v: float) -> bool:
	if GameState.province_mask == null or GameState.province_mask.is_empty():
		return true
	var x := clampi(roundi(u * (GameState.province_mask.get_width() - 1)), 0, GameState.province_mask.get_width() - 1)
	var y := clampi(roundi(v * (GameState.province_mask.get_height() - 1)), 0, GameState.province_mask.get_height() - 1)
	return GameState.province_mask.get_pixel(x, y).r > 0.5

func _build_water() -> void:
	var water := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(world_width * 4.0, world_depth * 4.0)
	water.mesh = plane
	water.position.y = SEA_LEVEL+0.012 if SEAMLESS_WORLD else -5.28
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("#102a34") if SEAMLESS_WORLD else Color("#102126")
	material.metallic = 0.04
	material.roughness = 0.40 if SEAMLESS_WORLD else 0.72
	water.material_override = material
	add_child(water)

func _province_span_at_v(v: float) -> Vector2:
	var first := -1.0
	var last := -1.0
	for step in 121:
		var u := float(step) / 120.0
		if _inside_province(u, v):
			if first < 0.0:
				first = u
			last = u
	return Vector2(first, last)

func _river_point(v: float, phase: float = 0.0) -> Vector3:
	var u := _river_u_at_v(v)
	if u < 0.0:
		return Vector3.INF
	var x := (u - 0.5) * world_width
	var z := (v - 0.5) * world_depth
	return Vector3(x, _height_at(x, z) + 0.16, z)

func _add_river_segment(surface: SurfaceTool, a: Vector3, b: Vector3, width: float, color: Color) -> void:
	var tangent := Vector2(b.x - a.x, b.z - a.z).normalized()
	var side := Vector3(-tangent.y, 0.0, tangent.x) * width
	var a_left := a - side
	var a_right := a + side
	var b_left := b - side
	var b_right := b + side
	var points: Array[Vector3] = [a_left, b_left, b_right, a_left, b_right, a_right]
	var center_height := (_height_at(a.x, a.z) + _height_at(b.x, b.z)) * 0.5
	for point in points:
		# Keep each short reach level across its banks. Sampling every corner produced
		# the bright stepped ribbon that looked like a staircase from orbit.
		var surface_height := _height_at(point.x, point.z)
		point.y = maxf(center_height + (0.20 if width < 0.8 else 0.14), surface_height + (0.10 if width < 0.8 else 0.07))
		surface.set_color(color)
		surface.add_vertex(point)

func _add_river_ribbon(surface: SurfaceTool, points: Array[Vector3], width: float, color: Color) -> void:
	for i in points.size() - 1:
		var a := points[i]
		var b := points[i + 1]
		var before := points[maxi(0,i-1)]
		var after := points[mini(points.size()-1,i+2)]
		var tangent_a := Vector2(b.x-before.x,b.z-before.z).normalized()
		var tangent_b := Vector2(after.x-a.x,after.z-a.z).normalized()
		var width_a:=width*clampf(0.88+sin(float(i)*0.023+float(GameState.world_seed%211))*0.14+sin(float(i)*0.0061+1.7)*0.08,0.68,1.18)
		var width_b:=width*clampf(0.88+sin(float(i+1)*0.023+float(GameState.world_seed%211))*0.14+sin(float(i+1)*0.0061+1.7)*0.08,0.68,1.18)
		var side_a := Vector3(-tangent_a.y,0.0,tangent_a.x)*width_a
		var side_b := Vector3(-tangent_b.y,0.0,tangent_b.x)*width_b
		var corners: Array[Vector3] = [a-side_a,b-side_b,b+side_b,a-side_a,b+side_b,a+side_a]
		var reach_tint:=0.91+sin(float(i)*0.017+2.4)*0.06
		for point in corners:
			var seamless_lift := 0.0037 if width < 0.15 else 0.0021
			point.y=_height_at(point.x,point.z)+(seamless_lift if SEAMLESS_WORLD else (0.105 if width<0.8 else 0.072))
			surface.set_color(Color(color.r*reach_tint,color.g*reach_tint,color.b*reach_tint,color.a))
			surface.add_vertex(point)

func _seeded_world_tributaries() -> Array[Array]:
	var tributaries: Array[Array] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = GameState.world_seed ^ 0x63d83595
	for tributary_index in 9:
		var join_z := -640.0 + float(tributary_index) * 160.0 + rng.randf_range(-38.0, 38.0)
		var join_x := _world_river_x(join_z)
		if join_x == INF:
			continue
		var side := -1.0 if tributary_index % 2 == 0 else 1.0
		var reach := rng.randf_range(54.0, 148.0)
		var source := Vector2(join_x + side * reach, join_z + rng.randf_range(-120.0, 120.0))
		var finish := Vector2(join_x, join_z)
		var control := source.lerp(finish, 0.52) + Vector2(side * rng.randf_range(-12.0, 24.0), rng.randf_range(-32.0, 32.0))
		var points: Array[Vector3] = []
		for sample_index in 49:
			var t := float(sample_index) / 48.0
			var point_2d := source * pow(1.0 - t, 2.0) + control * 2.0 * (1.0 - t) * t + finish * t * t
			var meander := sin(t * TAU * rng.randf_range(1.3, 2.4) + float(tributary_index)) * (1.0 - t) * rng.randf_range(1.2, 3.8)
			var tangent := (finish - source).normalized()
			point_2d += Vector2(-tangent.y, tangent.x) * meander
			points.append(Vector3(point_2d.x, _height_at(point_2d.x, point_2d.y), point_2d.y))
		tributaries.append(points)
	return tributaries

func _build_river_network() -> void:
	var banks := SurfaceTool.new()
	var water_surface := SurfaceTool.new()
	banks.begin(Mesh.PRIMITIVE_TRIANGLES)
	water_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var points: Array[Vector3] = []
	var river_samples:=3201 if SEAMLESS_WORLD else 196
	for i in river_samples:
		var v := lerpf(0.025, 0.975, float(i) / float(river_samples-1))
		var current := _river_point(v, float(terrain_noise.seed % 19))
		if current != Vector3.INF:
			points.append(current)
	if points.size() >= 2:
		_trace_load("river points=%d from=%s to=%s" % [points.size(),points.front(),points.back()])
		_add_river_ribbon(banks,points,0.22 if SEAMLESS_WORLD else 1.12,Color(0.15,0.205,0.17,0.64))
		_add_river_ribbon(water_surface,points,0.105 if SEAMLESS_WORLD else 0.68,Color(0.055,0.17,0.205,0.92))
	if SEAMLESS_WORLD:
		for tributary in _seeded_world_tributaries():
			var tributary_points: Array[Vector3] = tributary
			_add_river_ribbon(banks, tributary_points, 0.072, Color(0.14,0.20,0.17,0.58))
			_add_river_ribbon(water_surface, tributary_points, 0.029, Color(0.052,0.155,0.185,0.86))
	banks.generate_normals()
	water_surface.generate_normals()
	for entry in [{"mesh": banks.commit(), "name": "RiverBanks", "rough": 1.0}, {"mesh": water_surface.commit(), "name": "RiverWater", "rough": 0.34}]:
		if entry.mesh == null:
			continue
		var river := MeshInstance3D.new()
		river.name = entry.name
		river.mesh = entry.mesh
		var material := StandardMaterial3D.new()
		material.vertex_color_use_as_albedo = true
		material.roughness = entry.rough
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		if SEAMLESS_WORLD:
			material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			material.no_depth_test = true
			material.render_priority = -6 if entry.name == "RiverBanks" else -5
		if entry.name=="RiverWater" and SEAMLESS_WORLD:
			material.metallic = 0.04
			material.roughness = 0.26
		river.material_override = material
		add_child(river)
		river_overlays.append(river)

func _scatter_landscape_vegetation() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = terrain_noise.seed ^ 0x6d2b79f5
	var transforms: Array[Transform3D] = []
	var colors: Array[Color] = []
	var density := 9200 if SEAMLESS_WORLD else (7200 if GameState.province_terrain == "Forest" else 6200)
	for attempt in density:
		var x := rng.randf_range(world_start_position.x-230.0,world_start_position.x+230.0) if SEAMLESS_WORLD else rng.randf_range(-world_width * 0.48, world_width * 0.48)
		var z := rng.randf_range(world_start_position.z-230.0,world_start_position.z+230.0) if SEAMLESS_WORLD else rng.randf_range(-world_depth * 0.48, world_depth * 0.48)
		if not _inside_province(x / world_width + 0.5, z / world_depth + 0.5):
			continue
		var height := _height_at(x, z)
		if height < (0.03 if SEAMLESS_WORLD else -1.6) or height > 13.5:
			continue
		var forest_noise := moisture_noise.get_noise_2d(x,z) if SEAMLESS_WORLD else terrain_noise.get_noise_2d(x * 1.35 + 1300.0, z * 1.35 - 800.0)
		var threshold := -0.03 if SEAMLESS_WORLD else (-0.16 if GameState.province_terrain == "Forest" else 0.03)
		if forest_noise < threshold or rng.randf() > 0.78:
			continue
		var scale := rng.randf_range(0.48, 1.06)
		var basis := Basis().scaled(Vector3(scale * rng.randf_range(0.75, 1.05), scale * rng.randf_range(1.6, 2.45), scale))
		transforms.append(Transform3D(basis, Vector3(x, height + scale * 0.014, z)))
		colors.append(Color("#344836").lerp(Color("#5e6743"), rng.randf_range(0.0, 0.42)))
	if transforms.is_empty():
		return
	var canopy_mesh := SphereMesh.new()
	canopy_mesh.radius = 0.009
	canopy_mesh.height = 0.030
	canopy_mesh.radial_segments = 7
	canopy_mesh.rings = 4
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.use_colors = true
	multi.mesh = canopy_mesh
	multi.instance_count = transforms.size()
	for i in transforms.size():
		multi.set_instance_transform(i, transforms[i])
		multi.set_instance_color(i, colors[i])
	var forest := MultiMeshInstance3D.new()
	forest.name = "WoodlandCanopy"
	forest.multimesh = multi
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = 1.0
	forest.material_override = material
	add_child(forest)

func _scatter_trees() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = terrain_noise.seed ^ 0x27d4eb2d
	resource_sites.clear()
	var site_types := ["Timber", "Stone", "Fertile", "Freshwater", "Timber", "Stone"]
	for type in site_types:
		var center := _random_valid_site(rng)
		if center == Vector3.ZERO:
			continue
		resource_sites.append({"type": type, "position": center, "range": 13.0})
		if type == "Timber":
			_create_forest_patch(center, rng)
		elif type == "Stone":
			_create_stone_patch(center, rng)
		else:
			_create_resource_marker(type, center)
	ResourceSystem.register_local_occurrences(resource_sites, GameState.province_terrain)

func _random_valid_site(rng: RandomNumberGenerator) -> Vector3:
	for attempt in 80:
		var x := rng.randf_range(world_start_position.x-72.0,world_start_position.x+72.0) if SEAMLESS_WORLD else rng.randf_range(-world_width * 0.42, world_width * 0.42)
		var z := rng.randf_range(world_start_position.z-72.0,world_start_position.z+72.0) if SEAMLESS_WORLD else rng.randf_range(-world_depth * 0.42, world_depth * 0.42)
		if not _inside_province(x / world_width + 0.5, z / world_depth + 0.5):
			continue
		var y := _height_at(x, z)
		if y > (0.04 if SEAMLESS_WORLD else -1.5) and y < 7.0:
			return Vector3(x, y, z)
	return Vector3.ZERO

func _create_forest_patch(center: Vector3, rng: RandomNumberGenerator) -> void:
	var shared_crown := SphereMesh.new()
	shared_crown.radius = 0.011
	shared_crown.height = 0.036
	shared_crown.radial_segments = 6
	shared_crown.rings = 3
	for i in 42:
		var angle := rng.randf() * TAU
		var distance := sqrt(rng.randf()) * 7.8
		var x := center.x + cos(angle) * distance
		var z := center.z + sin(angle) * distance
		if not _inside_province(x / world_width + 0.5, z / world_depth + 0.5):
			continue
		var y := _height_at(x, z)
		var tree := MeshInstance3D.new()
		tree.mesh = shared_crown
		var scale := rng.randf_range(0.72, 1.45)
		tree.scale = Vector3(scale * rng.randf_range(0.78, 1.08), scale * rng.randf_range(1.35, 2.0), scale)
		tree.position = Vector3(x, y + 0.014 * scale, z)
		var material := StandardMaterial3D.new()
		material.albedo_color = Color("#304535").lerp(Color("#586044"), rng.randf_range(0.0, 0.44))
		material.roughness = 1.0
		tree.material_override = material
		add_child(tree)
	_create_resource_marker("Timber", center)

func _create_stone_patch(center: Vector3, rng: RandomNumberGenerator) -> void:
	for i in 9:
		var rock := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		mesh.radius = rng.randf_range(0.035, 0.11)
		mesh.height = mesh.radius * 1.5
		rock.mesh = mesh
		rock.scale = Vector3(1.3, 0.75, 1.0)
		rock.position = center + Vector3(rng.randf_range(-1.6, 1.6), mesh.radius * 0.45, rng.randf_range(-1.6, 1.6))
		var material := StandardMaterial3D.new()
		material.albedo_color = Color("#686762")
		rock.material_override = material
		add_child(rock)
	_create_resource_marker("Stone", center)

func _create_resource_marker(type: String, position: Vector3) -> void:
	# The occurrence exists in the landscape, but its identity is not revealed
	# until the population has produced enough observations to recognize it.
	pass

func _place_settlers() -> void:
	var camp_position := world_start_position if SEAMLESS_WORLD else _find_camp_position()
	var marker_root := Area3D.new()
	marker_root.name = "SettlerMarker"
	marker_root.position = camp_position
	marker_root.input_ray_pickable = true
	marker_root.input_event.connect(_on_settler_clicked)
	add_child(marker_root)
	settler_marker = marker_root
	var selection := MeshInstance3D.new()
	var selection_mesh := TorusMesh.new()
	selection_mesh.inner_radius = 3.95
	selection_mesh.outer_radius = 4.16
	selection_mesh.rings = 48
	selection_mesh.ring_segments = 7
	selection.mesh = selection_mesh
	selection.position.y = 0.006
	var selection_material := StandardMaterial3D.new()
	selection_material.albedo_color = Color(0.76, 0.61, 0.32, 0.46)
	selection_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	selection_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	selection_material.no_depth_test = true
	selection.material_override = selection_material
	marker_root.add_child(selection)
	settler_map_ring = selection
	convoy_map_icon = Node3D.new()
	convoy_map_icon.name = "ConvoyMapIcon"
	marker_root.add_child(convoy_map_icon)
	convoy_banner_sprite=Sprite3D.new()
	convoy_banner_sprite.name="FoundingBanner"
	convoy_banner_sprite.texture=_founding_banner_texture(GameState.founding_banner_index)
	convoy_banner_sprite.pixel_size=0.01
	convoy_banner_sprite.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	convoy_banner_sprite.no_depth_test=true
	convoy_banner_sprite.render_priority=12
	convoy_banner_sprite.position=Vector3(0.0,2.56,0.0)
	convoy_map_icon.add_child(convoy_banner_sprite)
	convoy_map_label=Label3D.new()
	convoy_map_label.name="PeopleMapLabel"
	convoy_map_label.text="FOUNDING CONVOY  •  %s" % _compact_population(GameState.population_total)
	convoy_map_label.font_size=13
	convoy_map_label.outline_size=5
	convoy_map_label.modulate=Color("#ead9ad")
	convoy_map_label.outline_modulate=Color(0.025,0.034,0.036,0.96)
	convoy_map_label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	convoy_map_label.fixed_size=true
	convoy_map_label.no_depth_test=true
	convoy_map_label.render_priority=10
	convoy_map_label.position=Vector3(0,0.32,0)
	marker_root.add_child(convoy_map_label)
	convoy_detail_root = Node3D.new()
	convoy_detail_root.name = "ConvoyPhysicalDetail"
	convoy_detail_root.scale = Vector3.ONE * CONVOY_DETAIL_SCALE
	marker_root.add_child(convoy_detail_root)
	_create_wagon(convoy_detail_root, Vector3(-1.8, 0.0, 0.8), 0.08)
	_create_wagon(convoy_detail_root, Vector3(1.7, 0.0, -0.7), -0.10)
	_create_wagon(convoy_detail_root, Vector3(0.0, 0.0, 2.6), 0.02)
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 1.0
	shape.shape = sphere
	shape.position.y = 0.01
	marker_root.add_child(shape)
	settler_click_shape=shape
	settlement_visual_root = Node3D.new()
	settlement_visual_root.name = "EmergentSettlement"
	settlement_visual_root.position = GameState.settlement_founded_at if GameState.settlement_founded_at != Vector3.ZERO else camp_position
	settlement_visual_root.scale = Vector3.ONE * SETTLEMENT_DETAIL_SCALE
	add_child(settlement_visual_root)
	for structure_name in GameState.settlement_completed:
		_spawn_settlement_structure(structure_name)
	if not SEAMLESS_WORLD:
		_build_detail_terrain_patch(camp_position)
	_refresh_settlement_footprint(true)
	_update_scale_lod()

func _update_scale_lod() -> void:
	if camera == null:
		return
	var close_view := camera.size <= 2.4
	if convoy_map_icon:
		convoy_map_icon.visible = not close_view and GameState.settlement_completed.is_empty()
		convoy_map_icon.scale = Vector3.ONE * maxf(0.045, camera.size / 28.0)
	if convoy_map_label:
		convoy_map_label.visible=not close_view and GameState.settlement_completed.is_empty()
		convoy_map_label.position.y=-camera.size*0.035
	if convoy_detail_root:
		convoy_detail_root.visible = close_view and GameState.settlement_completed.is_empty()
	if settlement_visual_root:
		settlement_visual_root.visible = close_view
	if settlement_blip:
		settlement_blip.visible = not close_view
		settlement_blip.scale = Vector3.ONE * maxf(0.004, camera.size * 0.0048)
	if settlement_map_label:
		settlement_map_label.visible=not close_view and camera.size<=1600.0
	var detail_visible:=camera.size<=1.8
	if detail_visible and detail_terrain_patch==null and settler_marker:
		_build_detail_terrain_patch(settler_marker.position)
	if detail_terrain_patch:
		detail_terrain_patch.visible = detail_visible
	if close_vegetation_root:
		close_vegetation_root.visible = detail_visible
	if province_terrain_mesh:
		# The streamed regional mesh is the same planet at higher sampling density.
		# Rendering both layers together causes kilometre-scale diagonal z seams.
		province_terrain_mesh.visible = camera.size>280.0 or regional_terrain_patch==null
	if regional_terrain_patch:
		regional_terrain_patch.visible = camera.size<=820.0
	# At country and continental footprints the coarse world mesh cannot drape a
	# hundred-metre ribbon without gaps or z artifacts. Drainage remains in the
	# albedo and relief; explicit water geometry enters with the regional mesh.
	for river_overlay in river_overlays:
		if is_instance_valid(river_overlay): river_overlay.visible=camera.size<=420.0
	if lens_panel:
		lens_panel.visible=lens_requested_visible and camera.size<=1600.0 and (settler_panel==null or not settler_panel.visible)
	if settler_map_ring:
		settler_map_ring.visible = not close_view and GameState.settlement_completed.is_empty()
		settler_map_ring.scale = Vector3.ONE * maxf(0.006, camera.size * 0.0058)
	if settler_click_shape:
		# Match the visible selection ring at every orthographic zoom. The old
		# four-world-unit sphere covered several kilometres of apparently empty map.
		var click_radius:=clampf(camera.size*0.021,0.004,2.35)
		settler_click_shape.scale=Vector3.ONE*click_radius
	if lens_ring:
		lens_ring.visible=lens_requested_visible and camera.size<=1600.0
		lens_ring.scale = Vector3.ONE * maxf(0.006, camera.size / 160.0)
	for marker in discovered_resource_overlays.values():
		if marker is Node3D:
			var resource_marker:=marker as Node3D
			var stage:=String(resource_marker.get_meta("resource_stage","recognized"))
			var strategic_node:=stage in ["accessible","developed"]
			# Recognition is local knowledge, not a world-map icon. Only operating
			# resource nodes survive into the regional overview.
			resource_marker.visible=camera.size<=(72.0 if strategic_node else 18.0)
			resource_marker.scale = Vector3.ONE * maxf(0.008, camera.size / 96.0)
			var marker_label:=resource_marker.get_node_or_null("ResourceLabel") as Label3D
			if marker_label: marker_label.visible=camera.size<=5.5
	_update_scale_bar()
	if settler_marker and "Hearth Circle" in GameState.settlement_completed:
		_refresh_settlement_footprint()

func _founding_banner_texture(index: int) -> Texture2D:
	var sheet_texture:=load("res://assets/ui/founding_convoy_banners.png") as Texture2D
	if sheet_texture==null:
		return null
	var sheet:=sheet_texture.get_image()
	if sheet==null or sheet.is_empty():
		return sheet_texture
	sheet.convert(Image.FORMAT_RGBA8)
	var columns:=5
	var rows:=2
	var cell_width:=sheet.get_width()/columns
	var cell_height:=sheet.get_height()/rows
	var selected:=clampi(index,0,columns*rows-1)
	var icon:=Image.create_empty(cell_width,cell_height,false,Image.FORMAT_RGBA8)
	icon.blit_rect(sheet,Rect2i((selected%columns)*cell_width,(selected/columns)*cell_height,cell_width,cell_height),Vector2i.ZERO)
	# The supplied reference includes a checkerboard baked into RGB. Remove only
	# bright neutral pixels; the flags' warm cloth and dark linework remain intact.
	for y in cell_height:
		for x in cell_width:
			var color:=icon.get_pixel(x,y)
			var high:=maxf(color.r,maxf(color.g,color.b))
			var low:=minf(color.r,minf(color.g,color.b))
			var chroma:=high-low
			var luminance:=color.r*0.299+color.g*0.587+color.b*0.114
			if chroma<0.035 and luminance>0.84:
				color.a=0.0
			elif chroma<0.060 and luminance>0.80:
				color.a*=clampf((chroma-0.018)/0.042+(0.88-luminance)*3.2,0.0,1.0)
			icon.set_pixel(x,y,color)
	icon.generate_mipmaps()
	return ImageTexture.create_from_image(icon)

func _update_convoy_marker_animation() -> void:
	if convoy_map_icon==null or camera==null:
		return
	var moving:=travel_active and game_speed>0.0
	var wave:=(sin(float(Time.get_ticks_msec())*0.006)+1.0)*0.5 if moving else 0.0
	var pulse:=1.0+wave*0.13
	convoy_map_icon.scale=Vector3.ONE*maxf(0.045,camera.size/28.0)*pulse
	if convoy_banner_sprite:
		convoy_banner_sprite.modulate=Color.WHITE.lerp(Color("#ffe5a0"),wave*0.34)
	if settler_map_ring:
		settler_map_ring.scale*=1.0+wave*0.07

func _update_world_streaming() -> void:
	if not SEAMLESS_WORLD or camera==null or camera.size>760.0:
		return
	# An oblique orthographic frustum covers much more ground in its forward axis
	# than camera.size alone suggests. Expand the streamed patch with tilt so the
	# high-resolution terrain never ends inside the visible frame.
	var tilt_coverage:=1.0/clampf(sin(absf(camera_pitch)),0.42,1.0)
	var desired_span:=clampf(camera.size*2.9*tilt_coverage,1.2,920.0)
	_rebuild_regional_terrain_patch(Vector2(camera_target.x,camera_target.z),desired_span)

func _process_camera_navigation(delta: float) -> void:
	if not SEAMLESS_WORLD or camera==null:
		return
	var input:=Input.get_vector("ui_left","ui_right","ui_up","ui_down")
	if input.length_squared()<0.001:
		return
	var direction_from_target:=Vector3(cos(camera_yaw),0.0,sin(camera_yaw))
	var screen_right:=Vector3(-direction_from_target.z,0.0,direction_from_target.x)
	var movement:=(screen_right*input.x-direction_from_target*input.y)*camera.size*0.72*delta
	_set_camera_target(camera_target+movement)

func _set_camera_target(target: Vector3) -> void:
	if SEAMLESS_WORLD:
		target.x=clampf(target.x,-world_width*0.5+1.0,world_width*0.5-1.0)
		target.z=clampf(target.z,-world_depth*0.5+1.0,world_depth*0.5-1.0)
		target.y=_height_at(target.x,target.z)
	camera_target=target
	_update_camera()

func _build_detail_terrain_patch(center: Vector3) -> void:
	var resolution := 112
	var span := 0.42
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z in resolution - 1:
		for x in resolution - 1:
			for corner in [Vector2i(x,z), Vector2i(x + 1,z), Vector2i(x + 1,z + 1), Vector2i(x,z), Vector2i(x + 1,z + 1), Vector2i(x,z + 1)]:
				var world_x := center.x + (float(corner.x) / (resolution - 1) - 0.5) * span
				var world_z := center.z + (float(corner.y) / (resolution - 1) - 0.5) * span
				var height := _close_surface_height_at(world_x, world_z) + 0.00045
				surface.set_color(_terrain_color_at(world_x, world_z, height))
				surface.add_vertex(Vector3(world_x, height, world_z))
	surface.index()
	surface.generate_normals()
	detail_terrain_patch = MeshInstance3D.new()
	detail_terrain_patch.name = "SettlementGroundDetail"
	detail_terrain_patch.mesh = surface.commit()
	detail_terrain_patch.material_override = _create_terrain_material()
	detail_terrain_patch.visible = false
	add_child(detail_terrain_patch)
	_rebuild_close_vegetation(center)

func _near_persistent_settlement_surface(local_point: Vector2) -> bool:
	for plot in GameState.settlement_plots:
		var polygon: PackedVector2Array = plot.get("polygon", PackedVector2Array())
		var centroid := Vector2(plot.get("centroid", Vector2.ZERO))
		if polygon.size() >= 3 and Geometry2D.is_point_in_polygon(local_point, polygon):
			var use:=String(plot.get("land_use",""))
			# Fields, gardens and household compounds retain trees. Only their working
			# centres and roof clusters are cleared, matching real aerial settlement
			# where canopy threads through inhabited land instead of stopping at a ring.
			if use in ["field","pasture","vacant"]:
				continue
			if use in ["residential_compound","mixed_household"] and local_point.distance_to(centroid)>0.0065:
				continue
			return true
		if local_point.distance_to(centroid) < (0.0065 if String(plot.get("land_use","")) in ["residential_compound","mixed_household"] else 0.010): return true
	for route in GameState.settlement_routes:
		var points: PackedVector2Array = route.get("points", PackedVector2Array())
		for index in points.size() - 1:
			if Geometry2D.get_closest_point_to_segment(local_point, points[index], points[index + 1]).distance_to(local_point) < 0.0032:
				return true
	return false

func _rebuild_close_vegetation(center: Vector3) -> void:
	if close_vegetation_root and close_vegetation_revision == GameState.morphology_revision:
		return
	if close_vegetation_root:
		close_vegetation_root.queue_free()
	close_vegetation_root = Node3D.new()
	close_vegetation_root.name = "CloseLandscapeVegetation"
	add_child(close_vegetation_root)
	close_vegetation_revision = GameState.morphology_revision
	var rng := RandomNumberGenerator.new()
	rng.seed = GameState.world_seed ^ int(round(center.x * 100.0)) ^ (int(round(center.z * 100.0)) << 11) ^ 0x31f2a7
	var canopy_transforms: Array[Transform3D] = []
	var canopy_colors: Array[Color] = []
	var scrub_transforms: Array[Transform3D] = []
	var scrub_colors: Array[Color] = []
	for attempt in 3400:
		var local_point := Vector2(rng.randf_range(-0.235, 0.235), rng.randf_range(-0.235, 0.235))
		var world_x := center.x + local_point.x
		var world_z := center.z + local_point.y
		if _height_at(world_x, world_z) <= SEA_LEVEL or _near_persistent_settlement_surface(local_point):
			continue
		var moisture := moisture_noise.get_noise_2d(world_x, world_z)
		var cluster := detail_noise.get_noise_2d(world_x * 940.0 + 71.0, world_z * 940.0 - 39.0)
		var woodland_field := cluster + moisture * 0.42
		var woodland_chance := 0.004
		if woodland_field > 0.10:
			woodland_chance = clampf((woodland_field - 0.10) * 0.92, 0.015, 0.48)
		var is_canopy := rng.randf() < woodland_chance
		var scrub_chance := clampf(0.07 + maxf(0.0, woodland_field) * 0.26, 0.05, 0.24)
		if not is_canopy and rng.randf() > scrub_chance:
			continue
		var height := _close_surface_height_at(world_x, world_z)
		if is_canopy:
			var scale := rng.randf_range(0.74, 1.34)
			var basis := Basis().rotated(Vector3.UP, rng.randf() * TAU).scaled(Vector3(scale * rng.randf_range(0.72, 1.10), scale * rng.randf_range(0.72, 1.22), scale))
			canopy_transforms.append(Transform3D(basis, Vector3(world_x, height + 0.0024 * scale, world_z)))
			canopy_colors.append(Color("#2d422f").lerp(Color("#66704a"), rng.randf_range(0.04, 0.48)))
			# Woodland reads from altitude as connected crowns and edge belts, not a
			# scatter of identical dots. Seed a few overlapping neighbours in strong
			# moisture/noise pockets while preserving cleared plots and routes.
			if woodland_field>0.18:
				for cluster_member in rng.randi_range(2,6):
					var neighbour_local:=local_point+Vector2.from_angle(rng.randf()*TAU)*rng.randf_range(0.0035,0.011)
					if _near_persistent_settlement_surface(neighbour_local): continue
					var neighbour_x:=center.x+neighbour_local.x
					var neighbour_z:=center.z+neighbour_local.y
					if _height_at(neighbour_x,neighbour_z)<=SEA_LEVEL: continue
					var neighbour_scale:=scale*rng.randf_range(0.58,0.96)
					var neighbour_basis:=Basis().rotated(Vector3.UP,rng.randf()*TAU).scaled(Vector3(neighbour_scale*rng.randf_range(0.78,1.16),neighbour_scale*rng.randf_range(0.72,1.08),neighbour_scale))
					var neighbour_height:=_close_surface_height_at(neighbour_x,neighbour_z)
					canopy_transforms.append(Transform3D(neighbour_basis,Vector3(neighbour_x,neighbour_height+0.0024*neighbour_scale,neighbour_z)))
					canopy_colors.append(Color("#273d2b").lerp(Color("#626e47"),rng.randf_range(0.06,0.44)))
		else:
			var scale := rng.randf_range(0.42, 1.25)
			var basis := Basis().rotated(Vector3.UP, rng.randf() * TAU).scaled(Vector3(scale * rng.randf_range(0.70, 1.45), scale * rng.randf_range(0.42, 0.82), scale))
			scrub_transforms.append(Transform3D(basis, Vector3(world_x, height + 0.0007 * scale, world_z)))
			scrub_colors.append(Color("#4c5937").lerp(Color("#83764d"), rng.randf_range(0.0, 0.48)))
	_create_close_vegetation_multimesh("TreeCanopies", canopy_transforms, canopy_colors, 0.0035, 0.0046)
	_create_close_vegetation_multimesh("ShrubAndGrassPatches", scrub_transforms, scrub_colors, 0.0011, 0.0018)

func _create_close_vegetation_multimesh(node_name: String, transforms: Array[Transform3D], colors: Array[Color], radius: float, height: float) -> void:
	if transforms.is_empty() or close_vegetation_root == null:
		return
	var mesh:Mesh
	if node_name=="TreeCanopies":
		mesh=_create_irregular_canopy_mesh(radius,height)
	else:
		var patch_mesh:=SphereMesh.new()
		patch_mesh.radius=radius
		patch_mesh.height=height
		patch_mesh.radial_segments=7
		patch_mesh.rings=4
		mesh=patch_mesh
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.use_colors = true
	multi.mesh = mesh
	multi.instance_count = transforms.size()
	for index in transforms.size():
		multi.set_instance_transform(index, transforms[index])
		multi.set_instance_color(index, colors[index])
	var instance := MultiMeshInstance3D.new()
	instance.name = node_name
	instance.multimesh = multi
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = 1.0
	material.cull_mode=BaseMaterial3D.CULL_DISABLED
	instance.material_override = material
	close_vegetation_root.add_child(instance)

func _create_irregular_canopy_mesh(radius:float,height:float)->ArrayMesh:
	# One batched crown is a shallow, uneven dome rather than a vertical sphere.
	# Seeded instance rotation and non-uniform scale then turn overlapping crowns
	# into the broken canopy masses visible in aerial photography.
	var surface:=SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segments:=14
	var inner_radius:=radius*0.52
	var inner_height:=height*0.76
	var center_height:=height*0.94
	for index in segments:
		var angle_a:=TAU*float(index)/float(segments)
		var angle_b:=TAU*float(index+1)/float(segments)
		var outer_radius_a:=radius*(0.82+0.13*sin(angle_a*3.0+0.7)+0.08*sin(angle_a*5.0-0.4))
		var outer_radius_b:=radius*(0.82+0.13*sin(angle_b*3.0+0.7)+0.08*sin(angle_b*5.0-0.4))
		var inner_a:=Vector3(cos(angle_a)*inner_radius,inner_height+height*0.055*sin(angle_a*2.0),sin(angle_a)*inner_radius)
		var inner_b:=Vector3(cos(angle_b)*inner_radius,inner_height+height*0.055*sin(angle_b*2.0),sin(angle_b)*inner_radius)
		var outer_a:=Vector3(cos(angle_a)*outer_radius_a,height*(0.30+0.09*sin(angle_a*4.0)),sin(angle_a)*outer_radius_a)
		var outer_b:=Vector3(cos(angle_b)*outer_radius_b,height*(0.30+0.09*sin(angle_b*4.0)),sin(angle_b)*outer_radius_b)
		for vertex in [Vector3(0.0,center_height,0.0),inner_a,inner_b,inner_a,outer_a,outer_b,inner_a,outer_b,inner_b]:
			surface.add_vertex(vertex)
	surface.generate_normals()
	return surface.commit()

func _able_population() -> int:
	return GameState.able_population()

func _process_population_day(context := {}) -> Array[Dictionary]:
	GameState.synchronize_population_allocations()
	var events := ConsequenceEngine.process_day(context)
	if "Lean-to Shelters" in GameState.settlement_completed and GameState.population_total > int(GameState.housing_capacity * 0.80):
		var builders := float(GameState.population_allocations.get("Construction", 0))
		GameState.housing_progress += builders / 8.0*float(GameState.simulation_metrics.get("labor_efficiency",0.72))
		if GameState.housing_progress >= 28.0:
			GameState.housing_progress -= 28.0
			GameState.housing_capacity += maxi(24, roundi(GameState.population_total * 0.12))
	_refresh_population_allocations()
	return events

func _refresh_settlement_footprint(force := false) -> void:
	if settler_marker == null:
		return
	if settlement_blip == null:
		settlement_blip = MeshInstance3D.new()
		settlement_blip.name = "PopulationBlip"
		var blip_mesh := CylinderMesh.new()
		blip_mesh.top_radius = 1.0
		blip_mesh.bottom_radius = 1.0
		blip_mesh.height = 0.10
		blip_mesh.radial_segments = 24
		settlement_blip.mesh = blip_mesh
		var blip_material := StandardMaterial3D.new()
		blip_material.albedo_color = Color("#e0c67f")
		blip_material.emission_enabled = true
		blip_material.emission = Color("#8e7139")
		blip_material.emission_energy_multiplier = 0.65
		blip_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		settlement_blip.material_override = blip_material
		add_child(settlement_blip)
		settlement_map_label=Label3D.new()
		settlement_map_label.name="SettlementMapLabel"
		settlement_map_label.font_size=16
		settlement_map_label.outline_size=6
		settlement_map_label.modulate=Color("#e4d7b4")
		settlement_map_label.outline_modulate=Color(0.018,0.026,0.028,0.97)
		settlement_map_label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
		settlement_map_label.fixed_size=true
		settlement_map_label.no_depth_test=true
		settlement_map_label.render_priority=11
		add_child(settlement_map_label)
	var founded := "Hearth Circle" in GameState.settlement_completed
	var center := GameState.settlement_founded_at if founded else settler_marker.position
	settlement_blip.position = Vector3(center.x, _height_at(center.x, center.z) + 0.004, center.z)
	if not founded:
		return
	if settlement_map_label:
		settlement_map_label.text="%s  •  %s" % [_settlement_display_name().to_upper(),_compact_population(GameState.population_total)]
		settlement_map_label.position=Vector3(center.x,_height_at(center.x,center.z)+0.055,center.z)
	_settlement_model().ensure_founded()
	var morphology_lod := _settlement_morphology_lod()
	if not force and rendered_morphology_revision == GameState.morphology_revision and rendered_settlement_lod == morphology_lod:
		return
	rendered_morphology_revision = GameState.morphology_revision
	rendered_settlement_lod = morphology_lod
	footprint_population = GameState.population_total
	if settlement_land_use_root:
		settlement_land_use_root.queue_free()
	settlement_land_use_root = Node3D.new()
	settlement_land_use_root.name = "PersistentSettlementMorphology"
	add_child(settlement_land_use_root)
	_rebuild_close_vegetation(center)
	_create_persistent_settlement_routes(center, GameState.settlement_routes, settlement_land_use_root)
	_create_plot_fabric(center, _settlement_model().plots_for_lod(morphology_lod), morphology_lod, settlement_land_use_root)
	_create_known_resource_routes(center, settlement_land_use_root)

func _settlement_morphology_lod() -> int:
	if camera == null:
		return 1
	if camera.size <= 0.42:
		return 0 # individual roofs, yards, scars and paths
	if camera.size <= 4.5:
		return 1 # complete plot fabric
	return 2 # distant land-use trace; the map blip remains the primary marker

func _settlement_plot_color(plot: Dictionary) -> Color:
	var land_use := String(plot.get("land_use", "vacant"))
	var material_family := String(plot.get("material_family", "organic"))
	var color := Color("#786f51")
	if land_use in ["residential_compound", "mixed_household"]:
		color = Color("#817457")
	elif land_use in ["communal", "civic", "sacred", "market"]:
		color = Color("#93835f")
	elif land_use in ["workshop", "dirty_industry", "storage"]:
		color = Color("#665e4c")
	elif land_use == "water":
		color = Color("#586f6b")
	elif land_use == "waste":
		color = Color("#5f5943")
	elif land_use == "field":
		var field_phase:=float(absi(int(plot.get("seed",1)))%1000)/999.0
		var field_pattern:=String(plot.get("field_pattern","smallholder_mosaic"))
		var crop_family:=String(plot.get("crop_family",["mixed_staples","grain","pulses","roots","fibre_crop"][absi(int(plot.get("seed",1)))%5]))
		var cultivation_phase:=String(plot.get("cultivation_phase","prepared"))
		var phase_palettes:Dictionary={
			"prepared":[Color("#59452f"),Color("#76583b"),Color("#684d34")],
			"growing":[Color("#315534"),Color("#4d713e"),Color("#3e6337")],
			"mature":[Color("#71804a"),Color("#958548"),Color("#627542")],
			"harvested":[Color("#7f6745"),Color("#9a7c52"),Color("#66583f")],
			"fallow":[Color("#51583d"),Color("#6a6545"),Color("#4b563b")],
			"stressed":[Color("#6c5b42"),Color("#756344"),Color("#57513d")]
		}
		var field_palette:Array=phase_palettes.get(cultivation_phase,phase_palettes.prepared)
		if field_pattern=="irrigated_beds" and cultivation_phase in ["growing","mature"]:
			field_palette=[Color("#31594b"),Color("#4d7457"),Color("#3d6751")]
		if cultivation_phase in ["growing","mature"]:
			var crop_palettes:Dictionary={
				"mixed_staples":[Color("#55703f"),Color("#75814b"),Color("#485f39")],
				"grain":[Color("#71814b"),Color("#9a8f50"),Color("#667541")],
				"pulses":[Color("#34573c"),Color("#496745"),Color("#2f4d35")],
				"roots":[Color("#5b6843"),Color("#77714a"),Color("#4d5e3d")],
				"fibre_crop":[Color("#54745c"),Color("#6d8062"),Color("#456550")],
				"garden_beds":[Color("#3c7351"),Color("#78804a"),Color("#466b43")]
			}
			field_palette=crop_palettes.get(crop_family,field_palette)
		var palette_index:=absi(int(plot.get("id",0))*7)%field_palette.size()
		color=field_palette[palette_index].lerp(field_palette[(palette_index+1)%field_palette.size()],0.12+0.10*sin(field_phase*31.0))
	elif land_use in ["vacant", "pasture"]:
		color = Color("#68704d")
	elif land_use == "ruin":
		color = Color("#615d55")
	if material_family == "earth":
		color = color.lerp(Color("#8a6848"), 0.08 if land_use=="field" else 0.22)
	elif material_family == "stone":
		color = color.lerp(Color("#858177"), 0.28)
	var condition := clampf(float(plot.get("condition", 1.0)), 0.0, 1.0)
	var prosperity := clampf(float(plot.get("prosperity", 0.4)), 0.0, 1.0)
	color = color.darkened((1.0 - condition) * 0.24).lightened(prosperity * 0.055)
	var status := String(plot.get("status", "active"))
	if status == "vacant":
		color = color.lerp(Color("#596344"), 0.58)
	elif status == "damaged":
		color = color.lerp(Color("#4e4238"), 0.46)
	elif status == "ruin":
		color = color.lerp(Color("#4f4d48"), 0.70)
	var reclamation := clampf(float(plot.get("reclamation", 0.0)), 0.0, 1.0)
	color = color.lerp(Color("#48573a"), reclamation * 0.74)
	if status=="active":
		# These are landscape surfaces seen from an aerial camera, not UI tints.
		# Low alpha made an occupied settlement disappear into the terrain at the
		# exact 100-500 m footprints where its morphology should become legible.
		# Let the satellite ground remain the dominant image. Plot fill is only the
		# accumulated landscape stain (clearing, trampling, cultivation), while roofs,
		# boundaries and lanes carry the readable settlement structure above it.
		var temporary_ground:=String(plot.get("form","")) in ["portable_shelter_cluster","light_shelter_cluster"]
		color.a=0.12 if temporary_ground else (0.28 if land_use in ["residential_compound","mixed_household"] else (0.018 if land_use=="field" else 0.42))
	else:
		color.a=0.58
	return color

func _settlement_roof_color(plot: Dictionary) -> Color:
	var family := String(plot.get("material_family", "organic"))
	var mix:Dictionary=plot.get("material_mix",{})
	var seed_variant:=absi(int(plot.get("seed",1)))%5
	var organic_palette:=[Color("#9a875d"),Color("#756342"),Color("#b09a68"),Color("#67583f"),Color("#88704a")]
	var earth_palette:=[Color("#8c6243"),Color("#684836"),Color("#9b7351"),Color("#75553d"),Color("#a17c59")]
	var stone_palette:=[Color("#77736b"),Color("#5f625f"),Color("#89837a"),Color("#69645b"),Color("#7c786e")]
	var color:Color=organic_palette[seed_variant]
	if family == "earth": color=earth_palette[seed_variant]
	elif family == "stone": color=stone_palette[seed_variant]
	# The dominant delivered material changes what is visible from above. Fibre is
	# pale and fibrous, timber dark and linear, clay warm, stone cool and mottled.
	var fibre_share:=float(mix.get("Fiber Plants",0.0))
	var timber_share:=float(mix.get("Timber",0.0))
	var clay_share:=float(mix.get("Clay",0.0))
	if fibre_share>0.24: color=color.lerp(Color("#b7a574"),clampf(fibre_share*0.42,0.08,0.30))
	if timber_share>0.44: color=color.lerp(Color("#574a38"),clampf(timber_share*0.24,0.06,0.20))
	if clay_share>0.42: color=color.lerp(Color("#9a6748"),clampf(clay_share*0.30,0.08,0.24))
	var condition := clampf(float(plot.get("condition", 1.0)), 0.0, 1.0)
	color = color.darkened((1.0 - condition) * 0.34)
	if String(plot.get("status", "active")) == "ruin":
		color = Color("#4a4843")
	return color

func _append_plot_polygon(surface: SurfaceTool, polygon: PackedVector2Array, center: Vector3, color: Color, inset := 1.0, lift := 0.0015) -> void:
	if polygon.size() < 3:
		return
	var centroid := Vector2.ZERO
	for point in polygon:
		centroid += point
	centroid /= float(polygon.size())
	for index in range(1, polygon.size() - 1):
		for source_point in [polygon[0], polygon[index], polygon[index + 1]]:
			var point_2d: Vector2 = centroid + (source_point - centroid) * inset
			var world_point := Vector3(center.x + point_2d.x, 0.0, center.z + point_2d.y)
			world_point.y = _close_surface_height_at(world_point.x, world_point.z) + lift
			surface.set_color(color)
			surface.set_uv(Vector2(-1.0,-1.0))
			surface.add_vertex(world_point)

func _ground_atlas_cell(plot:Dictionary)->Vector2i:
	var use:=String(plot.get("land_use",""))
	var family:=String(plot.get("material_family","organic"))
	if String(plot.get("status","active")) in ["damaged","ruin"]: return Vector2i(2,3) if family=="earth" else Vector2i(3,3)
	if use in ["workshop","dirty_industry","waste"]: return Vector2i(0,0)
	if use=="storage": return Vector2i(1,0)
	if family=="stone": return Vector2i(3,3)
	return Vector2i(3,2)

func _append_textured_plot_polygon(surface:SurfaceTool,plot:Dictionary,center:Vector3,color:Color,lift:=0.0021,atlas_cell_override:=Vector2i(-1,-1),margin_ratio:=0.20)->void:
	var polygon:PackedVector2Array=plot.get("polygon",PackedVector2Array())
	if polygon.size()<3: return
	var minimum:=Vector2(INF,INF)
	var maximum:=Vector2(-INF,-INF)
	for point in polygon:
		minimum.x=minf(minimum.x,point.x); minimum.y=minf(minimum.y,point.y)
		maximum.x=maxf(maximum.x,point.x); maximum.y=maxf(maximum.y,point.y)
	var span:=maximum-minimum
	span.x=maxf(span.x,0.0001); span.y=maxf(span.y,0.0001)
	var atlas_cell:=_field_atlas_cell(plot) if atlas_cell_override.x<0 else atlas_cell_override
	var centroid:=Vector2(plot.get("centroid",Vector2.ZERO))
	var center_color:=color
	var margin_color:=color
	margin_color.a*=margin_ratio
	for index in polygon.size():
		for vertex_index in 3:
			var source_point:Vector2=centroid if vertex_index==0 else polygon[index if vertex_index==1 else (index+1)%polygon.size()]
			var point_2d:Vector2=source_point
			var world_point:=Vector3(center.x+point_2d.x,0.0,center.z+point_2d.y)
			world_point.y=_close_surface_height_at(world_point.x,world_point.z)+lift
			var local_uv:=Vector2((point_2d.x-minimum.x)/span.x,(point_2d.y-minimum.y)/span.y)
			surface.set_color(center_color if vertex_index==0 else margin_color)
			surface.set_uv(_atlas_uv(atlas_cell,local_uv))
			surface.add_vertex(world_point)

func _commit_settlement_surface(surface: SurfaceTool, node_name: String, parent: Node3D, transparent := false) -> void:
	surface.generate_normals()
	var mesh := surface.commit()
	if mesh == null:
		return
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	var physical_fabric:=transparent and node_name in ["PersistentPlotGround","PersistentFieldGround","PersistentCultivationRows","PersistentYardVariation","PersistentRoofFabric","PersistentDesirePaths"]
	var material:Material
	if physical_fabric:
		var fabric_kind:=1 if node_name in ["PersistentFieldGround","PersistentCultivationRows"] else (3 if node_name=="PersistentRoofFabric" else (2 if node_name in ["PersistentYardVariation","PersistentDesirePaths"] else 0))
		material=_settlement_fabric_material(fabric_kind,0.74 if fabric_kind==1 else (0.62 if fabric_kind==3 else 0.48))
	else:
		var standard:=StandardMaterial3D.new()
		standard.vertex_color_use_as_albedo = true
		standard.roughness = 0.96
		standard.cull_mode = BaseMaterial3D.CULL_DISABLED
		standard.no_depth_test = true
		if transparent:
			standard.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			if node_name in ["PersistentDesirePaths","PersistentPlotBoundaries"]:
				standard.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material=standard
	# Settlement fabric is an aerial cartographic surface draped over terrain. The
	# regional terrain mesh changes resolution with zoom, so ordinary depth testing
	# lets coarse interpolation bury metre-scale parcels and lanes. Drawing the
	# drape after terrain preserves the simulated polygon geometry and makes it
	# stable across LOD transitions.
	material.render_priority = 2 if "Ground" in node_name else (4 if "Roof" in node_name else 3)
	instance.material_override = material
	parent.add_child(instance)

func _settlement_fabric_material(fabric_kind:int,grain_strength:float)->ShaderMaterial:
	if settlement_fabric_shader==null:
		settlement_fabric_shader=Shader.new()
		settlement_fabric_shader.code="""
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, diffuse_burley, specular_disabled, depth_test_disabled;
uniform float grain_strength = 0.5;
uniform int fabric_kind = 0;
uniform sampler2D material_atlas : source_color, filter_linear_mipmap, repeat_disable;
varying vec3 world_position;
float hash21(vec2 p) {
	p=fract(p*vec2(123.34,345.45));
	p+=dot(p,p+34.345);
	return fract(p.x*p.y);
}
float value_noise(vec2 p) {
	vec2 i=floor(p);
	vec2 f=fract(p);
	f=f*f*(3.0-2.0*f);
	return mix(mix(hash21(i),hash21(i+vec2(1.0,0.0)),f.x),mix(hash21(i+vec2(0.0,1.0)),hash21(i+vec2(1.0,1.0)),f.x),f.y);
}
void vertex() {
	world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
}
void fragment() {
	float broad=value_noise(world_position.xz*34.0+vec2(13.0,-29.0));
	float fine=value_noise(world_position.xz*215.0+vec2(-47.0,71.0));
	float dry=smoothstep(0.64,0.88,value_noise(world_position.xz*73.0+vec2(91.0,17.0)));
	vec3 fabric=COLOR.rgb*(0.82+broad*0.23+(fine-0.5)*0.18*grain_strength);
	if ((fabric_kind==0 || fabric_kind==1 || fabric_kind==2 || fabric_kind==3) && UV.x>=0.0 && UV.y>=0.0) {
		vec3 photographic=texture(material_atlas,UV).rgb;
		float source_luma=max(dot(photographic,vec3(0.299,0.587,0.114)),0.12);
		float tint_luma=max(dot(COLOR.rgb,vec3(0.299,0.587,0.114)),0.12);
		vec3 tint=COLOR.rgb/tint_luma;
		photographic*=mix(vec3(1.0),tint,0.27);
		fabric=mix(fabric,photographic,0.82);
	}
	if (fabric_kind==1) {
		// Vegetation is clumpy at metre scale and interrupted by exposed earth;
		// it must never read as a uniformly dyed polygon from an aerial camera.
		float crop_clump=value_noise(world_position.xz*420.0+vec2(7.0,113.0));
		float leaf=value_noise(world_position.xz*980.0+vec2(-31.0,19.0));
		fabric*=0.72+crop_clump*0.34+leaf*0.08;
		fabric=mix(fabric,fabric*vec3(0.72,0.82,0.57),smoothstep(0.58,0.82,crop_clump)*0.26);
	} else if (fabric_kind==3) {
		// Coarse fibre, bark and patched earthen roofing separate roofs from
		// coloured map rectangles even when a house is only a few pixels wide.
		float fibre=abs(fract((world_position.x+world_position.z*0.37)*1850.0)-0.5)*2.0;
		float roof_stain=value_noise(world_position.xz*520.0+vec2(181.0,-63.0));
		fabric*=0.78+fibre*0.17+roof_stain*0.18;
		fabric=mix(fabric,fabric*vec3(0.72,0.67,0.56),smoothstep(0.72,0.90,roof_stain)*0.32);
	} else {
		float earth_mottle=value_noise(world_position.xz*135.0+vec2(-9.0,44.0));
		fabric*=0.90+earth_mottle*0.16;
	}
	fabric=mix(fabric,fabric*vec3(1.10,1.035,0.86),dry*0.14*grain_strength);
	ALBEDO=fabric;
	ALPHA=COLOR.a;
	ROUGHNESS=0.98;
}
"""
	var material:=ShaderMaterial.new()
	material.shader=settlement_fabric_shader
	material.set_shader_parameter("grain_strength",grain_strength)
	material.set_shader_parameter("fabric_kind",fabric_kind)
	var atlas_texture:=load("res://assets/textures/settlement_material_atlas.png")
	if atlas_texture: material.set_shader_parameter("material_atlas",atlas_texture)
	return material

func _append_shelter_roof(surface: SurfaceTool, plot: Dictionary, center: Vector3, shelter_index: int, shelter_count: int) -> void:
	var polygon: PackedVector2Array = plot.get("polygon", PackedVector2Array())
	if polygon.size() < 3:
		return
	var plot_center := Vector2(plot.get("centroid", Vector2.ZERO))
	var rng := RandomNumberGenerator.new()
	rng.seed = int(plot.get("seed", 1)) ^ (shelter_index + 1) * 0x45d9f3b
	# Household orientation follows local habit and terrain rather than radiating
	# toward an abstract settlement centre. This removes the planned-wheel look.
	var base_angle := rng.randf_range(0.0,TAU)
	var spread_angle := base_angle + PI * 0.5
	var spread := (float(shelter_index) - float(shelter_count - 1) * 0.5) * rng.randf_range(0.0054, 0.0072)
	var roof_center := plot_center + Vector2.from_angle(spread_angle) * spread
	var half_width := rng.randf_range(0.00145, 0.00205)
	var half_depth := rng.randf_range(0.0023, 0.0033)
	var land_use:=String(plot.get("land_use","residential_compound"))
	if land_use=="workshop":
		half_width*=1.42
		half_depth*=1.34
	elif land_use=="storage":
		half_width*=1.14
		half_depth*=0.88
	if String(plot.get("status", "active")) == "under_construction":
		var construction_scale := lerpf(0.44, 1.0, clampf(float(plot.get("construction_progress", 0.0)), 0.0, 1.0))
		half_width *= construction_scale
		half_depth *= construction_scale
	var right := Vector2.from_angle(base_angle) * half_width
	var forward := Vector2(-right.y, right.x).normalized() * half_depth
	var left_back := roof_center - right - forward
	var right_back := roof_center + right - forward
	var right_front := roof_center + right + forward
	var left_front := roof_center - right + forward
	var ridge_back := roof_center - forward
	var ridge_front := roof_center + forward
	var base_color := _settlement_roof_color(plot)
	var first_side := base_color.lightened(rng.randf_range(0.015, 0.075))
	var second_side := base_color.darkened(rng.randf_range(0.035, 0.11))
	var roof_vertices := [
		[left_back, 0.0035, first_side], [ridge_back, 0.0049, first_side], [ridge_front, 0.0049, first_side],
		[left_back, 0.0035, first_side], [ridge_front, 0.0049, first_side], [left_front, 0.0035, first_side],
		[ridge_back, 0.0049, second_side], [right_back, 0.0035, second_side], [right_front, 0.0035, second_side],
		[ridge_back, 0.0049, second_side], [right_front, 0.0035, second_side], [ridge_front, 0.0049, second_side]
	]
	var roof_ground_height := _close_surface_height_at(center.x + roof_center.x, center.z + roof_center.y)
	for roof_vertex in roof_vertices:
		var point_2d: Vector2 = roof_vertex[0]
		var world_point := Vector3(center.x + point_2d.x, 0.0, center.z + point_2d.y)
		world_point.y = roof_ground_height + float(roof_vertex[1])
		surface.set_color(roof_vertex[2])
		surface.add_vertex(world_point)
	var wall_color:=base_color.darkened(0.34)
	var wall_top:=0.00345
	var wall_bottom:=0.00035
	var wall_faces:=[
		[left_back,right_back],[right_back,right_front],
		[right_front,left_front],[left_front,left_back]
	]
	for face in wall_faces:
		var a:Vector2=face[0]
		var b:Vector2=face[1]
		for wall_vertex in [[a,wall_bottom],[b,wall_bottom],[b,wall_top],[a,wall_bottom],[b,wall_top],[a,wall_top]]:
			var point_2d:Vector2=wall_vertex[0]
			var world_point:=Vector3(center.x+point_2d.x,roof_ground_height+float(wall_vertex[1]),center.z+point_2d.y)
			surface.set_color(wall_color)
			surface.add_vertex(world_point)

func _append_ground_disc(surface:SurfaceTool,world_center:Vector3,radius:float,color:Color,lift:float)->void:
	var segments:=18
	for index in segments:
		var angle_a:=TAU*float(index)/float(segments)
		var angle_b:=TAU*float(index+1)/float(segments)
		for offset in [Vector2.ZERO,Vector2.from_angle(angle_a)*radius,Vector2.from_angle(angle_b)*radius]:
			var point:=Vector3(world_center.x+offset.x,0.0,world_center.z+offset.y)
			point.y=_close_surface_height_at(point.x,point.z)+lift
			surface.set_color(color)
			surface.add_vertex(point)

func _atlas_uv(cell:Vector2i,local_uv:Vector2)->Vector2:
	if cell.x<0 or cell.y<0: return Vector2(-1.0,-1.0)
	# Stay inside each generated cell so mip filtering never pulls a neighboring
	# material across the atlas boundary.
	var inset:=0.012
	return Vector2((float(cell.x)+inset+local_uv.x*(1.0-inset*2.0))/4.0,(float(cell.y)+inset+local_uv.y*(1.0-inset*2.0))/4.0)

func _field_atlas_cell(plot:Dictionary)->Vector2i:
	var phase:=String(plot.get("cultivation_phase","prepared"))
	if phase=="prepared": return Vector2i(2,0)
	if phase=="harvested": return Vector2i(3,0)
	if phase in ["fallow","stressed"]: return Vector2i(2,2)
	var crop:=String(plot.get("crop_family","mixed_staples"))
	if crop=="grain": return Vector2i(1 if phase=="mature" else 0,1)
	if crop=="pulses": return Vector2i(2,1)
	if crop=="roots": return Vector2i(3,1)
	if crop=="fibre_crop": return Vector2i(0,2)
	if crop=="garden_beds": return Vector2i(1,2)
	return Vector2i(0 if absi(int(plot.get("seed",1)))%2==0 else 2,1)

func _roof_atlas_cell(plot:Dictionary,temporary_camp:bool)->Vector2i:
	if temporary_camp: return Vector2i(0,3)
	var family:=String(plot.get("material_family","organic"))
	if family=="earth": return Vector2i(2,3)
	if family=="stone": return Vector2i(3,3)
	var mix:Dictionary=plot.get("material_mix",{})
	return Vector2i(0,3) if float(mix.get("Fiber Plants",0.0))>=float(mix.get("Timber",0.0)) else Vector2i(1,3)

func _append_flat_quad(surface:SurfaceTool,center:Vector3,local_center:Vector2,right:Vector2,forward:Vector2,color:Color,lift:float,atlas_cell:=Vector2i(-1,-1))->void:
	var corners:=[local_center-right-forward,local_center+right-forward,local_center+right+forward,local_center-right+forward]
	var corner_uvs:=[Vector2(0.0,0.0),Vector2(1.0,0.0),Vector2(1.0,1.0),Vector2(0.0,1.0)]
	for corner_index in [0,1,2,0,2,3]:
		var point_2d:Vector2=corners[corner_index]
		var world_point:=Vector3(center.x+point_2d.x,0.0,center.z+point_2d.y)
		world_point.y=_close_surface_height_at(world_point.x,world_point.z)+lift
		surface.set_color(color)
		surface.set_uv(_atlas_uv(atlas_cell,corner_uvs[corner_index]))
		surface.add_vertex(world_point)

func _append_satellite_roof_fabric(surface:SurfaceTool,plot:Dictionary,center:Vector3)->int:
	var polygon:PackedVector2Array=plot.get("polygon",PackedVector2Array())
	if polygon.size()<3: return 0
	var plot_center:=Vector2(plot.get("centroid",Vector2.ZERO))
	var coverage:=clampf(float(plot.get("roof_coverage",0.18)),0.04,0.72)
	var residents:=maxi(0,int(plot.get("resident_count",0)))
	var use:=String(plot.get("land_use",""))
	var temporary_camp:=String(plot.get("form","")) in ["portable_shelter_cluster","light_shelter_cluster"]
	var rng:=RandomNumberGenerator.new()
	rng.seed=int(plot.get("seed",1))^0x6d2b79f5
	var base_angle:=rng.randf_range(0.0,TAU)
	var route_id:=int(plot.get("frontage_route_id",-1))
	var route_maturity:=0.0
	for route in GameState.settlement_routes:
		if int(route.get("id",-2))!=route_id: continue
		var points:PackedVector2Array=route.get("points",PackedVector2Array())
		if points.size()>=2:
			var route_span:=points[1]-points[0]
			if route_span.length_squared()>0.0000001: base_angle=route_span.angle()
		route_maturity=clampf(float(route.get("traffic",0.0))*0.62+float(route.get("condition",0.0))*0.38,0.0,1.0)
		break
	var occupied_pressure:=clampf(float(residents)/34.0,0.0,1.0)
	var density_bonus:=roundi(route_maturity*occupied_pressure*2.2)
	var household_variation:=rng.randi_range(-1,2)
	var mass_count:=clampi(ceili(coverage*3.2)+ceili(float(residents)/22.0)+density_bonus+household_variation,1,6)
	if temporary_camp: mass_count=1
	if use in ["communal","civic","sacred","market","workshop","storage"]: mass_count=clampi(1+roundi(coverage*3.0)+roundi(route_maturity),1,4)
	var appended:=0
	for mass_index in mass_count:
		var turn_across_courtyard:=mass_count>=3 and mass_index%3==2
		var mass_angle:=base_angle+(PI*0.5 if turn_across_courtyard else rng.randf_range(-0.11,0.11))
		var side_axis:=Vector2.from_angle(mass_angle)
		var depth_axis:=Vector2(-side_axis.y,side_axis.x)
		var rank:=float(mass_index)-float(mass_count-1)*0.5
		var row_offset:=rank*rng.randf_range(0.0032,0.0051)
		var courtyard_depth:=(0.0032 if mass_index%2==0 else -0.0022) if mass_count>=4 else rng.randf_range(-0.0022,0.0022)
		var local_center:=plot_center+Vector2.from_angle(base_angle)*row_offset+Vector2.from_angle(base_angle+PI*0.5)*courtyard_depth
		if not Geometry2D.is_point_in_polygon(local_center,polygon): local_center=plot_center.lerp(local_center,0.42)
		var density_scale:=lerpf(1.0,0.82,clampf(float(mass_count-3)/3.0,0.0,1.0))
		var half_width:=rng.randf_range(0.0012,0.0025)*density_scale
		var half_depth:=rng.randf_range(0.0017,0.0035)*density_scale
		if temporary_camp:
			half_width=rng.randf_range(0.00055,0.0010)
			half_depth=rng.randf_range(0.00075,0.00135)
		if use in ["communal","civic","market","workshop","storage"]:
			half_width*=rng.randf_range(1.25,1.65)
			half_depth*=rng.randf_range(1.10,1.42)
		# A sub-metre offset shadow gives the aerial fabric terrain-readable relief
		# without promoting every roof into a chunky authored 3D building.
		var shadow_center:=local_center+Vector2(0.00042,0.00055)
		var shadow_alpha:=0.18 if temporary_camp else 0.34
		_append_flat_quad(surface,center,shadow_center,side_axis*half_width*1.04,depth_axis*half_depth*1.04,Color(0.08,0.075,0.055,shadow_alpha),0.00325)
		var weather_palette:=[Color("#8c714b"),Color("#706047"),Color("#9a8058"),Color("#68665a"),Color("#79563f")]
		var family:=String(plot.get("material_family","organic"))
		if family=="earth": weather_palette=[Color("#a16a48"),Color("#76503b"),Color("#b07c57"),Color("#68483b"),Color("#8c5c43")]
		elif family=="stone": weather_palette=[Color("#858178"),Color("#646862"),Color("#989187"),Color("#595e5a"),Color("#777269")]
		if temporary_camp: weather_palette=[Color("#cbbd8d"),Color("#918162"),Color("#ded09d"),Color("#726c5b"),Color("#ac925f")]
		var weather_tone:Color=weather_palette[(absi(int(plot.get("seed",1)))+mass_index*3)%weather_palette.size()]
		var tone:=_settlement_roof_color(plot).lerp(weather_tone,rng.randf_range(0.38,0.68))
		tone=tone.lightened(rng.randf_range(-0.05,0.055))
		# At this LOD these are density flecks, not individually modelled houses.
		tone.a=rng.randf_range(0.76,0.90) if temporary_camp else rng.randf_range(0.70,0.84)
		var roof_atlas_cell:=_roof_atlas_cell(plot,temporary_camp)
		_append_flat_quad(surface,center,local_center,side_axis*half_width,depth_axis*half_depth,tone,0.0036,roof_atlas_cell)
		# Roof-scale fibre courses, boards and repairs survive as texture at the
		# playable aerial zoom. They share the physical footprint; no giant prop is
		# introduced just to make a building readable.
		var course_count:=rng.randi_range(3,6)
		for course_index in course_count:
			var course_t:=(float(course_index)+0.5)/float(course_count)-0.5
			var course_center:=local_center+side_axis*(course_t*half_width*1.72)
			var course_color:=tone.lightened(rng.randf_range(-0.12,0.14))
			course_color.a=0.26 if family=="organic" else 0.18
			_append_flat_quad(surface,center,course_center,side_axis*(half_width/float(course_count)*0.24),depth_axis*half_depth*0.91,course_color,0.00363,roof_atlas_cell)
		if not temporary_camp and rng.randf()<0.68:
			var patch_center:=local_center+side_axis*rng.randf_range(-half_width*0.42,half_width*0.42)+depth_axis*rng.randf_range(-half_depth*0.38,half_depth*0.38)
			var patch_color:=tone.lerp(Color("#4d4637"),rng.randf_range(0.18,0.42))
			patch_color.a=0.34
			_append_flat_quad(surface,center,patch_center,side_axis*half_width*rng.randf_range(0.16,0.34),depth_axis*half_depth*rng.randf_range(0.14,0.31),patch_color,0.00366,roof_atlas_cell)
		appended+=1
	return appended

func _append_plot_boundary(surface:SurfaceTool,plot:Dictionary,center:Vector3)->int:
	var polygon:PackedVector2Array=plot.get("polygon",PackedVector2Array())
	if polygon.size()<3: return 0
	var use:=String(plot.get("land_use",""))
	var status:=String(plot.get("status","active"))
	var width:=0.00025 if use in ["field","pasture"] else 0.00010
	var color:=Color(0.24,0.25,0.14,0.27) if use in ["field","pasture"] else Color(0.29,0.25,0.17,0.18)
	if status in ["vacant","ruin","reclaimed"]: color=color.lerp(Color(0.24,0.31,0.18,0.42),0.62)
	var segments:=0
	for edge_index in polygon.size():
		# Inherited field margins are broken by gates, erosion and shared access.
		# Omitting deterministic stretches avoids outlining every field like a UI card.
		if use in ["field","pasture"] and (absi(int(plot.get("seed",1)))+edge_index*11)%5<=1: continue
		var start:=polygon[edge_index]
		var finish:=polygon[(edge_index+1)%polygon.size()]
		var direction:=finish-start
		if direction.length_squared()<0.0000001: continue
		var edge_width:=width
		var edge_color:=color
		if use in ["field","pasture"] and (absi(int(plot.get("seed",1)))+edge_index*7)%5==0:
			edge_width=0.00052
			edge_color=Color(0.16,0.23,0.105,0.54)
		var side:=Vector2(-direction.y,direction.x).normalized()*edge_width
		for point_2d in [start-side,finish-side,finish+side,start-side,finish+side,start+side]:
			var world_point:=Vector3(center.x+point_2d.x,0.0,center.z+point_2d.y)
			world_point.y=_close_surface_height_at(world_point.x,world_point.z)+0.0030
			surface.set_color(edge_color)
			surface.add_vertex(world_point)
		segments+=1
	return segments

func _append_yard_variation(surface:SurfaceTool,plot:Dictionary,center:Vector3)->int:
	var polygon:PackedVector2Array=plot.get("polygon",PackedVector2Array())
	if polygon.size()<3: return 0
	var plot_center:=Vector2(plot.get("centroid",Vector2.ZERO))
	var rng:=RandomNumberGenerator.new()
	rng.seed=int(plot.get("seed",1))^0x31f2a7
	var patch_count:=rng.randi_range(3,7)
	var appended:=0
	for patch_index in patch_count:
		var local_center:=plot_center+Vector2.from_angle(rng.randf()*TAU)*rng.randf_range(0.0015,0.0065)
		if not Geometry2D.is_point_in_polygon(local_center,polygon): continue
		var world_center:=Vector3(center.x+local_center.x,0.0,center.z+local_center.y)
		var color:=Color("#7d6a4b").lerp(Color("#40563b"),rng.randf_range(0.12,0.78))
		color.a=rng.randf_range(0.10,0.23)
		_append_ground_disc(surface,world_center,rng.randf_range(0.0010,0.0031),color,0.0027)
		appended+=1
	return appended

func _append_field_rows(surface: SurfaceTool, plot: Dictionary, center: Vector3) -> void:
	var polygon:PackedVector2Array=plot.get("polygon",PackedVector2Array())
	if polygon.size()<3: return
	var field_center:=Vector2(plot.get("centroid",Vector2.ZERO))
	var field_pattern:=String(plot.get("field_pattern","smallholder_mosaic"))
	var crop_cover:=clampf(float(plot.get("crop_cover",0.46)),0.0,1.0)
	var field_atlas_cell:=_field_atlas_cell(plot)
	var longest:=Vector2.RIGHT
	var longest_length:=0.0
	for first_index in polygon.size():
		for second_index in range(first_index+1,polygon.size()):
			var span:=polygon[second_index]-polygon[first_index]
			if span.length_squared()>longest_length:
				longest=span.normalized()
				longest_length=span.length_squared()
	var right:=longest
	var forward:=Vector2(-right.y,right.x)
	var lateral_extent:=0.0
	var longitudinal_extent:=0.0
	for point in polygon:
		lateral_extent=maxf(lateral_extent,absf((point-field_center).dot(forward)))
		longitudinal_extent=maxf(longitudinal_extent,absf((point-field_center).dot(right)))
	if lateral_extent<=0.002: return
	var row_count:=13 if field_pattern=="irrigated_beds" else (8 if field_pattern=="smallholder_mosaic" else 5)
	for row_index in row_count:
		var offset:=(float(row_index)/float(row_count-1)-0.5)*lateral_extent*1.62
		var intersections:Array[float]=[]
		for edge_index in polygon.size():
			var a:=polygon[edge_index]-field_center
			var b:=polygon[(edge_index+1)%polygon.size()]-field_center
			var a_side:=a.dot(forward)-offset
			var b_side:=b.dot(forward)-offset
			if (a_side<=0.0 and b_side>=0.0) or (a_side>=0.0 and b_side<=0.0):
				var denominator:=a_side-b_side
				if absf(denominator)>0.000001:
					var edge_t:=a_side/denominator
					intersections.append(a.lerp(b,edge_t).dot(right))
		if intersections.size()<2: continue
		intersections.sort()
		var start_t:=float(intersections.front())+0.0010
		var finish_t:=float(intersections.back())-0.0010
		if finish_t<=start_t: continue
		var row_start:=field_center+forward*offset+right*start_t
		var row_finish:=field_center+forward*offset+right*finish_t
		var band_spacing:=lateral_extent*1.62/float(row_count-1)
		var half_width:=band_spacing*(0.31 if field_pattern=="irrigated_beds" else (0.25 if field_pattern=="smallholder_mosaic" else 0.21))
		var segment_count:=5 if field_pattern=="irrigated_beds" else (4 if field_pattern=="smallholder_mosaic" else 3)
		for segment_index in segment_count:
			var segment_rng:=RandomNumberGenerator.new()
			segment_rng.seed=int(plot.get("seed",1))^((row_index+1)*0x45d9f3b)^((segment_index+3)*0x119de1f3)
			# Missing and shortened cells expose fallow ground and foot access. The
			# authoritative field remains one labor unit, but its visible tenure is a
			# mosaic of household-scale beds rather than one translucent rectangle.
			if field_pattern!="irrigated_beds" and segment_rng.randf()<(0.07+(1.0-crop_cover)*0.30): continue
			var jitter_limit:=0.055/float(segment_count)
			var segment_start_t:=float(segment_index)/float(segment_count)+segment_rng.randf_range(0.0,jitter_limit)
			var segment_finish_t:=float(segment_index+1)/float(segment_count)-segment_rng.randf_range(0.0,jitter_limit)
			var gap:=minf(segment_rng.randf_range(0.00075,0.00145),(row_finish-row_start).length()/float(segment_count)*0.14)
			var segment_start:=row_start.lerp(row_finish,segment_start_t)+right*gap
			var segment_finish:=row_start.lerp(row_finish,segment_finish_t)-right*gap
			if segment_finish.distance_to(segment_start)<0.0004: continue
			var local_half_width:=half_width*segment_rng.randf_range(0.72,1.08)
			var row_phase:=fmod(float(absi(int(plot.get("seed",1)))%997)/997.0+float(row_index)*0.173+float(segment_index)*0.117,1.0)
			var row_color:=_settlement_plot_color(plot)
			row_color.a=1.0
			row_color=row_color.lerp(Color("#b19a6c") if row_phase>0.56 else Color("#32472d"),0.18+absf(row_phase-0.5)*0.24)
			row_color=row_color.lightened(segment_rng.randf_range(-0.10,0.11))
			row_color.a=(0.15+crop_cover*0.34)*(0.82 if field_pattern=="dryland_patchwork" else 1.0)
			# A worked bed is not a filled rectangle. Build it from separated crop or
			# furrow courses so soil remains visible between them, then vary individual
			# courses by household practice and crop condition.
			var micro_count:=7 if field_pattern=="irrigated_beds" else (5 if field_pattern=="smallholder_mosaic" else 4)
			for micro_index in micro_count:
				if segment_rng.randf()<(0.03+(1.0-crop_cover)*0.12): continue
				var micro_t:=(float(micro_index)+0.5)/float(micro_count)-0.5
				var micro_center_offset:=micro_t*local_half_width*1.82
				var micro_half_width:=local_half_width/float(micro_count)*segment_rng.randf_range(0.36,0.62)
				var micro_start:=segment_start+forward*micro_center_offset+right*segment_rng.randf_range(0.0,0.00038)
				var micro_finish:=segment_finish+forward*micro_center_offset-right*segment_rng.randf_range(0.0,0.00038)
				if micro_finish.distance_to(micro_start)<0.00035: continue
				var micro_color:=row_color.lightened(segment_rng.randf_range(-0.09,0.10))
				if String(plot.get("cultivation_phase","prepared")) in ["prepared","harvested","fallow"]:
					micro_color=micro_color.lerp(Color("#4d3929"),segment_rng.randf_range(0.18,0.42))
					micro_color.a*=0.72
				var corners:=[micro_start-forward*micro_half_width,micro_finish-forward*micro_half_width,micro_finish+forward*micro_half_width,micro_start+forward*micro_half_width]
				var corner_uvs:=[Vector2(0.0,0.0),Vector2(1.0,0.0),Vector2(1.0,1.0),Vector2(0.0,1.0)]
				for corner_index in [0,1,2,0,2,3]:
					var point_2d:Vector2=corners[corner_index]
					var world_point:=Vector3(center.x+point_2d.x,0.0,center.z+point_2d.y)
					world_point.y=_close_surface_height_at(world_point.x,world_point.z)+0.0028
					surface.set_color(micro_color)
					surface.set_uv(_atlas_uv(field_atlas_cell,corner_uvs[corner_index]))
					surface.add_vertex(world_point)
	# Aggregate simulation fields contain many household beds and inherited strips.
	# Cross-dividers make that internal tenure legible without creating more plots.
	var target_divider_width:=0.0065 if field_pattern in ["irrigated_beds","smallholder_mosaic"] else 0.020
	var divider_count:=clampi(floori(longitudinal_extent*2.0/target_divider_width),2,14 if field_pattern!="dryland_patchwork" else 6)
	for divider_index in range(1,divider_count):
		var offset:=(float(divider_index)/float(divider_count)-0.5)*longitudinal_extent*1.84
		var intersections:Array[float]=[]
		for edge_index in polygon.size():
			var a:=polygon[edge_index]-field_center
			var b:=polygon[(edge_index+1)%polygon.size()]-field_center
			var a_side:=a.dot(right)-offset
			var b_side:=b.dot(right)-offset
			if (a_side<=0.0 and b_side>=0.0) or (a_side>=0.0 and b_side<=0.0):
				var denominator:=a_side-b_side
				if absf(denominator)>0.000001:
					var edge_t:=a_side/denominator
					intersections.append(a.lerp(b,edge_t).dot(forward))
		if intersections.size()<2: continue
		intersections.sort()
		var divider_start:=field_center+right*offset+forward*(float(intersections.front())+0.0007)
		var divider_finish:=field_center+right*offset+forward*(float(intersections.back())-0.0007)
		var half_width:=0.00017
		var corners:=[divider_start-right*half_width,divider_finish-right*half_width,divider_finish+right*half_width,divider_start+right*half_width]
		for corner_index in [0,1,2,0,2,3]:
			var point_2d:Vector2=corners[corner_index]
			var world_point:=Vector3(center.x+point_2d.x,0.0,center.z+point_2d.y)
			world_point.y=_close_surface_height_at(world_point.x,world_point.z)+0.0029
			surface.set_color(Color(0.24,0.245,0.13,0.34))
			surface.set_uv(Vector2(-1.0,-1.0))
			surface.add_vertex(world_point)

func _create_plot_fabric(center: Vector3, plots: Array[Dictionary], lod: int, parent: Node3D) -> void:
	if plots.is_empty():
		return
	var ground_surface := SurfaceTool.new()
	ground_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var field_ground_surface:=SurfaceTool.new()
	field_ground_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var roof_surface := SurfaceTool.new()
	roof_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var scar_surface := SurfaceTool.new()
	scar_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var field_surface := SurfaceTool.new()
	field_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var feature_surface:=SurfaceTool.new()
	feature_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var boundary_surface:=SurfaceTool.new()
	boundary_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var variation_surface:=SurfaceTool.new()
	variation_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var roof_count := 0
	var scar_count := 0
	var field_count := 0
	var feature_count:=0
	var boundary_count:=0
	var variation_count:=0
	for plot in plots:
		var polygon: PackedVector2Array = plot.get("polygon", PackedVector2Array())
		if polygon.size() < 3:
			continue
		var plot_color := _settlement_plot_color(plot)
		var status := String(plot.get("status", "active"))
		var land_use := String(plot.get("land_use", "vacant"))
		var ground_inset:=1.0 if land_use in ["field","water","waste"] else 0.76
		if land_use=="field" and status not in ["ruin","reclaimed"]:
			var field_ground_color:=plot_color
			field_ground_color.a=0.60 if status=="active" else 0.34
			_append_textured_plot_polygon(field_ground_surface,plot,center,field_ground_color,0.0021)
		elif land_use not in ["water","waste","vacant","pasture"] and status!="reclaimed":
			_append_textured_plot_polygon(ground_surface,plot,center,plot_color,0.0018,_ground_atlas_cell(plot),0.46)
		else:
			_append_plot_polygon(ground_surface, polygon, center, plot_color, ground_inset, 0.0018)
		var form:=String(plot.get("form",""))
		var temporary_camp:=form in ["portable_shelter_cluster","light_shelter_cluster"]
		var feature_center:=Vector2(plot.get("centroid",Vector2.ZERO))
		var feature_world:=Vector3(center.x+feature_center.x,0.0,center.z+feature_center.y)
		if lod<=1 and not temporary_camp:
			boundary_count+=_append_plot_boundary(boundary_surface,plot,center)
			if land_use not in ["water","waste","field"]:
				variation_count+=_append_yard_variation(variation_surface,plot,center)
		if lod==0 and land_use=="communal":
			_append_ground_disc(feature_surface,feature_world,0.0046,Color(0.27,0.225,0.14,0.72),0.0030)
			_append_ground_disc(feature_surface,feature_world,0.0010,Color(0.78,0.37,0.10,0.92),0.0037)
			feature_count+=1
		elif lod==0 and land_use=="water":
			_append_ground_disc(feature_surface,feature_world,0.0027,Color(0.16,0.28,0.27,0.76),0.0030)
			feature_count+=1
		elif lod==0 and land_use=="waste":
			_append_ground_disc(feature_surface,feature_world,0.0022,Color(0.23,0.20,0.13,0.60),0.0030)
			feature_count+=1
		if lod<=1 and land_use=="field" and status not in ["ruin","reclaimed"]:
			_append_field_rows(field_surface,plot,center)
			field_count+=1
		var open_ground_form:=form in ["open_hearth_yard","open_work_yard","guarded_cache","carried_water_point","refuse_and_latrine_ground"]
		if lod <= 1 and status not in ["vacant", "reclaimed"] and not open_ground_form and land_use not in ["water", "waste", "field", "pasture"]:
			if status == "under_construction" and float(plot.get("construction_progress", 0.0)) < 0.26:
				continue
			roof_count+=_append_satellite_roof_fabric(roof_surface,plot,center)
		if lod == 0 and status in ["damaged", "ruin"]:
			_append_plot_polygon(scar_surface, polygon, center, Color(0.19, 0.17, 0.15, 0.72), 0.34, 0.0044)
			scar_count += 1
	_commit_settlement_surface(ground_surface, "PersistentPlotGround", parent, true)
	if field_count>0:
		_commit_settlement_surface(field_ground_surface,"PersistentFieldGround",parent,true)
	if roof_count > 0:
		_commit_settlement_surface(roof_surface, "PersistentRoofFabric", parent, lod>=1)
	if scar_count > 0:
		_commit_settlement_surface(scar_surface, "PersistentDamageScars", parent, true)
	if field_count > 0:
		_commit_settlement_surface(field_surface, "PersistentCultivationRows", parent, true)
	if feature_count>0:
		_commit_settlement_surface(feature_surface,"PersistentGroundFeatures",parent,true)
	if boundary_count>0:
		_commit_settlement_surface(boundary_surface,"PersistentPlotBoundaries",parent,true)
	if variation_count>0:
		_commit_settlement_surface(variation_surface,"PersistentYardVariation",parent,true)

func _create_persistent_settlement_routes(center: Vector3, routes: Array[Dictionary], parent: Node3D) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segment_count := 0
	for route in routes:
		if not bool(route.get("active", true)):
			continue
		var points: PackedVector2Array = route.get("points", PackedVector2Array())
		if points.size() < 2:
			continue
		var route_kind:=String(route.get("kind","desire_path"))
		var hierarchy:=String(route.get("hierarchy","field_track" if route_kind=="field_track" else "path"))
		# Agricultural access is a faint inherited track; inhabited lanes remain
		# readable but no longer turn every outlying field into a map-diagram spoke.
		var minimum_half_width:=0.00034 if route_kind=="field_track" else 0.00058
		if hierarchy=="farm_lane": minimum_half_width=0.00058
		elif hierarchy=="lane": minimum_half_width=0.00082
		elif hierarchy=="main_approach": minimum_half_width=0.00128
		var width := maxf(minimum_half_width, float(route.get("width_m", 1.2)) / 2000.0)
		var condition := clampf(float(route.get("condition", 0.5)), 0.0, 1.0)
		var route_color := (Color("#41402e") if route_kind=="field_track" else Color("#6f6248")).lerp(Color("#897654"), condition * 0.24)
		route_color.a = 0.12 if route_kind=="field_track" else 0.18
		if hierarchy=="farm_lane": route_color.a=0.22
		elif hierarchy=="lane": route_color.a=0.34
		elif hierarchy=="main_approach": route_color=Color("#756347"); route_color.a=0.54
		if camera!=null and camera.size<=0.42: route_color.a*=0.76
		for index in points.size() - 1:
			var start := points[index]
			var finish := points[index + 1]
			var direction := finish - start
			if direction.length_squared() < 0.0000001:
				continue
			var side := Vector2(-direction.y, direction.x).normalized() * width
			var route_vertices:=[start-side,finish-side,finish+side,start-side,finish+side,start+side]
			var route_uvs:=[Vector2(0.0,0.0),Vector2(1.0,0.0),Vector2(1.0,1.0),Vector2(0.0,0.0),Vector2(1.0,1.0),Vector2(0.0,1.0)]
			for vertex_index in route_vertices.size():
				var point_2d:Vector2=route_vertices[vertex_index]
				var world_point := Vector3(center.x + point_2d.x, 0.0, center.z + point_2d.y)
				world_point.y = _close_surface_height_at(world_point.x, world_point.z) + 0.0027
				surface.set_color(route_color)
				surface.set_uv(_atlas_uv(Vector2i(3,2),route_uvs[vertex_index]))
				surface.add_vertex(world_point)
			segment_count += 1
	if segment_count > 0:
		_commit_settlement_surface(surface, "PersistentDesirePaths", parent, true)

func _create_land_patch(center: Vector3, radius: float, color: Color, segments: int, irregularity: float, parent: Node3D) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var radial_steps := 12
	for ring in radial_steps:
		var inner_t := float(ring) / radial_steps
		var outer_t := float(ring + 1) / radial_steps
		for i in segments:
			var angle_a := float(i) / segments * TAU
			var angle_b := float(i + 1) / segments * TAU
			var edge_a := 1.0 + sin(angle_a * 3.0 + terrain_noise.seed) * irregularity + sin(angle_a * 7.0) * irregularity * 0.35
			var edge_b := 1.0 + sin(angle_b * 3.0 + terrain_noise.seed) * irregularity + sin(angle_b * 7.0) * irregularity * 0.35
			var points: Array[Vector3] = []
			for entry in [[angle_a,inner_t,edge_a],[angle_b,inner_t,edge_b],[angle_b,outer_t,edge_b],[angle_a,outer_t,edge_a]]:
				var angle: float = entry[0]
				var radial_t: float = entry[1]
				var edge: float = entry[2]
				var point_radius := radius * radial_t * lerpf(1.0,edge,radial_t)
				var point := Vector3(center.x+cos(angle)*point_radius,0.0,center.z+sin(angle)*point_radius)
				point.y = _height_at(point.x,point.z)+0.050
				points.append(point)
			var cell_variation := 0.86 + fmod(float(i * 17 + ring * 31),11.0) / 42.0
			var cell_color := Color(color.r*cell_variation,color.g*cell_variation,color.b*cell_variation,color.a*lerpf(1.0,0.52,outer_t))
			for index in [0,1,2,0,2,3]:
				surface.set_color(cell_color)
				surface.add_vertex(points[index])
	var patch := MeshInstance3D.new()
	patch.mesh = surface.commit()
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.roughness = 1.0
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	patch.material_override = material
	parent.add_child(patch)

func _river_distance_at(x: float, z: float) -> float:
	var v := z / world_depth + 0.5
	var river_u := _river_u_at_v(v)
	if river_u < 0.0:
		return INF
	return absf(x - (river_u - 0.5) * world_width)

func _terrain_slope_at(x: float, z: float, sample_radius := 0.45) -> float:
	var east_west := absf(_height_at(x + sample_radius, z) - _height_at(x - sample_radius, z))
	var north_south := absf(_height_at(x, z + sample_radius) - _height_at(x, z - sample_radius))
	return maxf(east_west, north_south) / (sample_radius * 2.0)

func _create_urban_fabric(center: Vector3, urban_radius: float, population: int, parent: Node3D) -> void:
	if population < 420:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = terrain_noise.seed ^ population ^ 0x6f41d9
	var block_count := clampi(population / 85, 4, 1800)
	var block_span := clampf(urban_radius / sqrt(float(block_count)) * 0.92, 0.032, 0.14)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var placed := 0
	for attempt in block_count * 3:
		if placed >= block_count:
			break
		# Multiple overlapping centers make the edge break into neighborhoods instead
		# of forming a perfect game-token circle.
		var district_angle := float((attempt / 31) % 7) / 7.0 * TAU + rng.randf_range(-0.22, 0.22)
		var district_offset := Vector2(cos(district_angle), sin(district_angle)) * urban_radius * rng.randf_range(0.0, 0.54)
		var angle := rng.randf() * TAU
		var radius := urban_radius * pow(rng.randf(), 0.68) * rng.randf_range(0.32, 0.86)
		var position_2d := Vector2(center.x, center.z) + district_offset + Vector2(cos(angle), sin(angle)) * radius
		if not _inside_province(position_2d.x / world_width + 0.5, position_2d.y / world_depth + 0.5):
			continue
		if _river_distance_at(position_2d.x, position_2d.y) < 0.92 or _terrain_slope_at(position_2d.x, position_2d.y) > 0.95:
			continue
		var rotation := rng.randf_range(-0.16, 0.16) + float(rng.randi_range(0, 3)) * PI * 0.5
		var half_width := block_span * rng.randf_range(0.44, 1.22)
		var half_depth := block_span * rng.randf_range(0.32, 0.92)
		var right := Vector2(cos(rotation), sin(rotation)) * half_width
		var forward := Vector2(-sin(rotation), cos(rotation)) * half_depth
		var roof_tone := rng.randf()
		var block_color := Color("#77766d").lerp(Color("#aaa38f"), roof_tone * 0.72)
		for uv in [Vector2(-1,-1),Vector2(1,-1),Vector2(1,1),Vector2(-1,-1),Vector2(1,1),Vector2(-1,1)]:
			var point_2d: Vector2 = position_2d + right * uv.x + forward * uv.y
			var point := Vector3(point_2d.x, _height_at(point_2d.x, point_2d.y) + 0.070, point_2d.y)
			surface.set_color(block_color)
			surface.add_vertex(point)
		placed += 1
	var mesh := surface.commit()
	if mesh == null:
		return
	var fabric := MeshInstance3D.new()
	fabric.name = "UrbanFabric"
	fabric.mesh = mesh
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = 0.92
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	fabric.material_override = material
	parent.add_child(fabric)

func _create_field_system(center: Vector3, urban_radius: float, population: int, parent: Node3D) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = terrain_noise.seed ^ population ^ 0x13ab57
	var agricultural_km := sqrt(float(population) * 0.0065 / PI)
	var agricultural_radius := maxf(urban_radius * 2.5, agricultural_km / KM_PER_WORLD_UNIT)
	var parcel_count := clampi(population / 72, 8, 520)
	var parcel_step := clampf(agricultural_radius / sqrt(float(parcel_count)) * 1.42, 0.28, 1.05)
	var grid_span := ceili(agricultural_radius / parcel_step)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var placed := 0
	for grid_z_index in range(-grid_span, grid_span + 1):
		for grid_x_index in range(-grid_span, grid_span + 1):
			if placed >= parcel_count:
				break
			var parcel_center := Vector2(center.x + grid_x_index * parcel_step, center.z + grid_z_index * parcel_step)
			parcel_center += Vector2(rng.randf_range(-0.18,0.18),rng.randf_range(-0.18,0.18))*parcel_step
			var distance := parcel_center.distance_to(Vector2(center.x,center.z))
			if distance < urban_radius * 1.16 or distance > agricultural_radius or rng.randf() < 0.10:
				continue
			# Agriculture follows accessible, watered lowlands. On another biome this same
			# filter becomes coast terraces or an irrigated green corridor.
			var river_distance := _river_distance_at(parcel_center.x, parcel_center.y)
			var valley_limit := minf(agricultural_radius * 0.82, 11.5)
			if river_distance > valley_limit or river_distance < 1.15:
				continue
			if not _inside_province(parcel_center.x / world_width + 0.5, parcel_center.y / world_depth + 0.5):
				continue
			var center_height := _height_at(parcel_center.x,parcel_center.y)
			if center_height > 5.8 or _terrain_slope_at(parcel_center.x,parcel_center.y) > 0.82:
				continue
			var parcel_width := parcel_step * rng.randf_range(0.37,0.47)
			var parcel_depth := parcel_step * rng.randf_range(0.32,0.46)
			var local_river_u := _river_u_at_v(parcel_center.y / world_depth + 0.5)
			var rotation := rng.randf_range(-0.14,0.14)
			if local_river_u >= 0.0:
				var ahead_u := _river_u_at_v(clampf(parcel_center.y / world_depth + 0.505,0.0,1.0))
				rotation += atan2(0.005 * world_depth,(ahead_u-local_river_u)*world_width)
			var right := Vector2(cos(rotation),sin(rotation)) * parcel_width
			var forward := Vector2(-sin(rotation),cos(rotation)) * parcel_depth
			var field_color := Color("#766c43").lerp(Color("#405c3d"),rng.randf_range(0.0,0.72))
			var subdivisions := 2
			for cell_z in subdivisions:
				for cell_x in subdivisions:
					var u0 := float(cell_x)/subdivisions*2.0-1.0
					var u1 := float(cell_x+1)/subdivisions*2.0-1.0
					var v0 := float(cell_z)/subdivisions*2.0-1.0
					var v1 := float(cell_z+1)/subdivisions*2.0-1.0
					for uv in [Vector2(u0,v0),Vector2(u1,v0),Vector2(u1,v1),Vector2(u0,v0),Vector2(u1,v1),Vector2(u0,v1)]:
						var point_2d: Vector2 = parcel_center+right*uv.x+forward*uv.y
						var point := Vector3(point_2d.x,_height_at(point_2d.x,point_2d.y)+0.065,point_2d.y)
						surface.set_color(field_color)
						surface.add_vertex(point)
			placed += 1
	var field_mesh := surface.commit()
	if field_mesh == null:
		return
	var fields := MeshInstance3D.new()
	fields.name = "FloodplainFields"
	fields.mesh = field_mesh
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = 1.0
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	fields.material_override = material
	parent.add_child(fields)

func _create_satellite_hamlets(center: Vector3, urban_radius: float, population: int, parent: Node3D) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = terrain_noise.seed ^ population ^ 0x51f2a9
	var count := clampi(population / 5500 + 1, 2, 9)
	for i in count:
		var hamlet := Vector3.INF
		for attempt in 18:
			var angle := rng.randf() * TAU
			var distance := urban_radius * rng.randf_range(2.8, 6.6)
			var candidate := Vector3(center.x + cos(angle)*distance,0.0,center.z + sin(angle)*distance)
			if not _inside_province(candidate.x/world_width+0.5,candidate.z/world_depth+0.5):
				continue
			if _height_at(candidate.x,candidate.z) > 5.5 or _terrain_slope_at(candidate.x,candidate.z) > 0.70 or _river_distance_at(candidate.x,candidate.z) < 0.85:
				continue
			hamlet = candidate
			break
		if hamlet == Vector3.INF:
			continue
		var hamlet_radius := urban_radius*rng.randf_range(0.13,0.25)
		_create_land_patch(hamlet,hamlet_radius,Color(0.43,0.40,0.34,0.56),36,0.22,parent)
		_create_urban_fabric(hamlet,hamlet_radius,maxi(450,population/(count*10)),parent)
		_create_land_route(center,hamlet,0.035,Color(0.36,0.34,0.30,0.82),parent)

func _create_valley_trunk(center: Vector3, urban_radius: float, population: int, parent: Node3D) -> void:
	var extent := minf(24.0,maxf(6.0,urban_radius*(5.0+log(float(population))/4.0)))
	var bank_side := -1.0 if ((terrain_noise.seed >> 3) & 1) == 0 else 1.0
	var previous := Vector3.INF
	for i in 19:
		var z := center.z + lerpf(-extent,extent,float(i)/18.0)
		var v := z/world_depth+0.5
		var river_u := _river_u_at_v(v)
		if river_u < 0.0:
			previous=Vector3.INF
			continue
		var x := (river_u-0.5)*world_width+bank_side*1.55
		var point := Vector3(x,0.0,z)
		if not _inside_province(x/world_width+0.5,v) or _terrain_slope_at(x,z)>0.95:
			previous=Vector3.INF
			continue
		if previous != Vector3.INF:
			_create_land_route(previous,point,0.031 if population<40000 else 0.046,Color(0.31,0.30,0.27,0.90),parent)
		previous=point

func _create_regional_transport(center: Vector3, urban_radius: float, population: int, parent: Node3D) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = terrain_noise.seed ^ population ^ 0x7d34c1
	_create_valley_trunk(center,urban_radius,population,parent)
	var route_count := clampi(population/26000+2,2,8)
	for i in route_count:
		var angle := rng.randf()*TAU
		var distance := urban_radius*rng.randf_range(3.8,7.8)
		var destination := Vector3(center.x+cos(angle)*distance,0.0,center.z+sin(angle)*distance)
		if not _inside_province(destination.x/world_width+0.5,destination.z/world_depth+0.5):
			continue
		if _height_at(destination.x,destination.z)>6.2 or _terrain_slope_at(destination.x,destination.z)>0.90:
			continue
		_create_land_route(center,destination,0.038 if population<80000 else 0.052,Color(0.34,0.33,0.30,0.90),parent)
	if population>=120000:
		_create_ring_route(center,urban_radius*1.82,0.045,Color(0.35,0.34,0.31,0.88),parent)
	if population>=420000:
		_create_ring_route(center,urban_radius*3.15,0.060,Color(0.38,0.37,0.34,0.90),parent)

func _create_ring_route(center: Vector3, radius: float, width: float, color: Color, parent: Node3D) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segments := 120
	for i in segments:
		var a0 := float(i)/segments*TAU
		var a1 := float(i+1)/segments*TAU
		var r0 := radius*(1.0+sin(a0*5.0+terrain_noise.seed)*0.045)
		var r1 := radius*(1.0+sin(a1*5.0+terrain_noise.seed)*0.045)
		for entry in [[a0,r0-width],[a1,r1-width],[a1,r1+width],[a0,r0-width],[a1,r1+width],[a0,r0+width]]:
			var angle: float = entry[0]
			var radial: float = entry[1]
			var point := Vector3(center.x+cos(angle)*radial,0.0,center.z+sin(angle)*radial)
			point.y=_height_at(point.x,point.z)+0.085
			surface.set_color(color)
			surface.add_vertex(point)
	var ring := MeshInstance3D.new()
	ring.mesh=surface.commit()
	var material:=StandardMaterial3D.new()
	material.vertex_color_use_as_albedo=true
	material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	material.roughness=1.0
	material.cull_mode=BaseMaterial3D.CULL_DISABLED
	ring.material_override=material
	parent.add_child(ring)

func _create_known_resource_routes(center: Vector3, parent: Node3D) -> void:
	for deposit in ResourceSystem.visible_deposits():
		if float(deposit.get("route",0.0)) < 0.08 and String(deposit.stage) != "accessible" and String(deposit.stage) != "developed":
			continue
		var destination: Vector3 = deposit.position
		var width := 0.00045 if String(deposit.stage) == "surveyed" else 0.0010
		_create_land_route(center,destination,width,Color(0.43,0.37,0.27,0.38),parent)

func _create_land_route(start: Vector3, finish: Vector3, width: float, color: Color, parent: Node3D) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var direction := Vector2(finish.x-start.x,finish.z-start.z)
	if direction.length() < 0.01:
		return
	var side_2d := Vector2(-direction.y,direction.x).normalized()*width
	var meander_scale:=maxf(width*1.8,minf(direction.length()*0.012,0.025))
	for i in 79:
		var a_progress := float(i)/79.0
		var b_progress := float(i+1)/79.0
		var a_2d := Vector2(start.x,start.z).lerp(Vector2(finish.x,finish.z),a_progress)
		var b_2d := Vector2(start.x,start.z).lerp(Vector2(finish.x,finish.z),b_progress)
		var meander_a := (sin(a_progress*TAU*1.7+terrain_noise.seed)+sin(a_progress*TAU*4.1+1.4)*0.28)*meander_scale
		var meander_b := (sin(b_progress*TAU*1.7+terrain_noise.seed)+sin(b_progress*TAU*4.1+1.4)*0.28)*meander_scale
		a_2d += side_2d.normalized()*meander_a
		b_2d += side_2d.normalized()*meander_b
		for point_2d in [a_2d-side_2d,b_2d-side_2d,b_2d+side_2d,a_2d-side_2d,b_2d+side_2d,a_2d+side_2d]:
			var point := Vector3(point_2d.x,_height_at(point_2d.x,point_2d.y)+0.0032,point_2d.y)
			surface.set_color(color)
			surface.add_vertex(point)
	var route := MeshInstance3D.new()
	route.mesh = surface.commit()
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.roughness = 1.0
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	route.material_override = material
	parent.add_child(route)

func _change_population_allocation(role: String, change: int) -> void:
	GameState.adjust_population_role_percentage(role,float(change))
	_refresh_population_allocations()
	if research_total_label:
		_refresh_research_allocations()

func _refresh_population_allocations() -> void:
	GameState.synchronize_population_allocations()
	_refresh_age_distribution_meter()
	var assigned := 0
	for role in GameState.population_allocations:
		var amount: int = int(GameState.population_allocations[role])
		assigned += amount
		if population_value_labels.has(role):
			population_value_labels[role].text = "%.1f%%  •  %s" % [float(GameState.population_allocation_percentages.get(role,0.0)),_compact_population(amount)]
	if choice_status and not travel_active:
		_update_settlement_progress_text()
	if nearby_resources_label:
		nearby_resources_label.text = "AUTO  •  %d of %d able people assigned" % [assigned,_able_population()]

func _refresh_age_distribution_meter() -> void:
	if age_distribution_bar==null or age_distribution_summary==null: return
	var profile:=GameState.population_age_profile()
	var bands:Array=profile.bands
	for index in mini(age_distribution_segments.size(),bands.size()):
		var segment:=age_distribution_segments[index]
		var band:Dictionary=bands[index]
		var count:=int(band.count)
		var share:=float(band.share)
		segment.tooltip_text="%s • ages %s\n%d people • %.1f%% of the living population" % [String(band.label).capitalize(),String(band.range),count,share*100.0]
		segment.color.a=lerpf(0.50,1.0,clampf(share/0.25,0.0,1.0))
		if index<age_distribution_segment_labels.size():
			age_distribution_segment_labels[index].text="%s\n%d" % [String(band.range),count]
			age_distribution_segment_labels[index].tooltip_text=segment.tooltip_text
	if age_distribution_title:
		age_distribution_title.text="AGE PROFILE   •   LIFE EXPECTANCY %.1f YEARS" % float(profile.projected_life_expectancy)
		var observed_note:=""
		if int(profile.recorded_deaths)>0:
			observed_note="\nObserved mean age at death: %.1f years across %d recorded deaths." % [float(profile.observed_age_at_death),int(profile.recorded_deaths)]
		age_distribution_title.tooltip_text="Projected at birth under current health, nutrition, shelter, and mortality conditions.%s" % observed_note
	age_distribution_summary.text="MEDIAN AGE %.1f   •   DEPENDENCY %d PER 100 WORKERS" % [float(profile.median_age),roundi(float(profile.dependents_per_100_workers))]
	age_distribution_summary.tooltip_text="Dependency counts children under 14 and elders 60 or older against every 100 working-age people."

func _settlement_definitions() -> Array[Dictionary]:
	return [
		{"name":"Hearth Circle", "days":6.0, "requires":[], "minimum":{"Construction":3},"effect":"anchors the camp and makes communal work possible"},
		{"name":"Lean-to Shelters", "days":9.0, "requires":["Hearth Circle"], "minimum":{"Construction":5},"effect":"protects health and expands shelter"},
		{"name":"Storage Pits", "days":7.0, "requires":["Hearth Circle"], "minimum":{"Construction":4, "Logistics":4},"effect":"slows spoilage and expands food storage"},
		{"name":"Open Work Area", "days":12.0, "requires":["Hearth Circle"], "minimum":{"Construction":6, "Crafting":4},"effect":"improves tools and material work"},
		{"name":"Gathering Yard", "days":10.0, "requires":["Hearth Circle"], "minimum":{"Construction":4, "Extraction":4}, "known_resource":true,"effect":"organizes extraction from known deposits"}
	]

func _settlement_project_available(project: Dictionary) -> bool:
	if String(project.name) in GameState.settlement_completed:
		return false
	for required in project.requires:
		if String(required) not in GameState.settlement_completed:
			return false
	for role in project.minimum:
		if int(GameState.population_allocations.get(role, 0)) < int(project.minimum[role]):
			return false
	if bool(project.get("known_resource", false)) and ResourceSystem.visible_deposits().is_empty():
		return false
	return true

func _current_settlement_project() -> Dictionary:
	var available: Array[Dictionary] = []
	for project in _settlement_definitions():
		if _settlement_project_available(project): available.append(project)
	if available.is_empty(): return {}
	if GameState.settlement_completed.is_empty():
		for project in available:
			if String(project.name)=="Hearth Circle": return project
	var best: Dictionary = available[0]
	var best_score := -INF
	for project in available:
		var score := float(GameState.settlement_projects.get(project.name,0.0))*0.08
		match String(project.name):
			"Lean-to Shelters": score+=(1.0-clampf(float(GameState.housing_capacity)/maxf(1.0,GameState.population_exact),0.0,1.0))*4.0+1.1
			"Storage Pits": score+=(1.0-clampf(float(GameState.simulation_metrics.get("food_days",30.0))/45.0,0.0,1.0))*3.4+float(GameState.population_allocations.get("Logistics",0))/10.0
			"Open Work Area": score+=float(GameState.population_allocations.get("Crafting",0))/5.0+float(GameState.population_allocations.get("Construction",0))/12.0
			"Gathering Yard": score+=float(GameState.population_allocations.get("Extraction",0))/4.0+float(ResourceSystem.visible_deposits().size())*0.5
		if score>best_score:
			best_score=score
			best=project
	return best

func _process_settlement_day() -> void:
	if travel_active or not GameState.settlement_site_committed or settler_marker == null:
		return
	var project := _current_settlement_project()
	if project.is_empty():
		_update_settlement_progress_text()
		return
	var project_name: String = project.name
	var builders := float(GameState.population_allocations.get("Construction", 0))
	var carriers := float(GameState.population_allocations.get("Logistics", 0))
	var makers := float(GameState.population_allocations.get("Crafting", 0))
	var daily_work := (builders / 8.0) * (0.82 + carriers / 30.0 + makers / 50.0)*float(GameState.simulation_metrics.get("labor_efficiency",0.72))*(1.0+DiscoverySystem.effect("construction_rate"))
	GameState.settlement_projects[project_name] = float(GameState.settlement_projects.get(project_name, 0.0)) + daily_work
	if float(GameState.settlement_projects[project_name]) >= float(project.days):
		GameState.settlement_completed.append(project_name)
		footprint_population = -1
		if project_name == "Hearth Circle":
			GameState.settlement_founded_at = settler_marker.position
			GameState.settlement_founded_day=int(floor(GameState.elapsed_days))
			hearth_established = true
			_settlement_model().ensure_founded()
			if settlement_visual_root:
				settlement_visual_root.position = GameState.settlement_founded_at
		elif project_name=="Lean-to Shelters":
			GameState.housing_capacity+=roundi(90.0*(1.0+DiscoverySystem.effect("housing_output")))
		_spawn_settlement_structure(project_name)
		if travel_status_label:
			travel_status_label.text = "%s EMERGED FROM THE PEOPLE'S WORK" % project_name.to_upper()
	_update_settlement_progress_text()

func _update_settlement_progress_text() -> void:
	if choice_status == null:
		return
	if not GameState.settlement_site_committed:
		choice_status.text = "NOMADIC ERA\nChoose START SETTLEMENT before lasting work can emerge."
		return
	var project := _current_settlement_project()
	if project.is_empty():
		if GameState.settlement_completed.is_empty():
			choice_status.text = "NOMADIC ERA\nNo lasting work can emerge from the present allocation."
		else:
			choice_status.text = "THE CAMP ENDURES\nNew forms will emerge as knowledge, labor, and materials change."
		return
	var progress := float(GameState.settlement_projects.get(project.name, 0.0))
	var percent := clampi(roundi(progress / float(project.days) * 100.0), 0, 100)
	var builders := float(GameState.population_allocations.get("Construction",0))
	var carriers := float(GameState.population_allocations.get("Logistics",0))
	var makers := float(GameState.population_allocations.get("Crafting",0))
	var work_rate := (builders/8.0)*(0.82+carriers/30.0+makers/50.0)*float(GameState.simulation_metrics.get("labor_efficiency",0.72))
	var days_left := (float(project.days)-progress)/maxf(0.01,work_rate)
	choice_status.text = "EMERGING FROM PRESENT LABOR\n%s  •  %d%%  •  ~%.0f days\n%s" % [String(project.name).to_upper(),percent,days_left,String(project.get("effect",""))]

func _spawn_settlement_structure(structure_name: String) -> void:
	if settlement_visual_root == null:
		return
	if settlement_visual_root.has_node(structure_name.to_snake_case()):
		return
	var root := Node3D.new()
	root.name = structure_name.to_snake_case()
	var origin := GameState.settlement_founded_at
	if origin == Vector3.ZERO and settler_marker:
		origin = settler_marker.position
	if settlement_visual_root.position == Vector3.ZERO:
		settlement_visual_root.position = origin
	root.position = Vector3.ZERO
	settlement_visual_root.add_child(root)
	if structure_name == "Hearth Circle":
		for i in 12:
			var stone := MeshInstance3D.new()
			var stone_mesh := SphereMesh.new()
			stone_mesh.radius = 0.18
			stone_mesh.height = 0.28
			stone.mesh = stone_mesh
			var angle := float(i) / 12.0 * TAU
			stone.position = Vector3(cos(angle) * 1.05, 0.13, sin(angle) * 1.05)
			var stone_material := StandardMaterial3D.new()
			stone_material.albedo_color = Color("#686257")
			stone.material_override = stone_material
			root.add_child(stone)
		var fire := MeshInstance3D.new()
		var fire_mesh := CylinderMesh.new()
		fire_mesh.top_radius = 0.02
		fire_mesh.bottom_radius = 0.34
		fire_mesh.height = 0.92
		fire_mesh.radial_segments = 8
		fire.mesh = fire_mesh
		fire.position.y = 0.52
		var fire_material := StandardMaterial3D.new()
		fire_material.albedo_color = Color("#d67d35")
		fire_material.emission_enabled = true
		fire_material.emission = Color("#c96d29")
		fire_material.emission_energy_multiplier = 1.4
		fire.material_override = fire_material
		root.add_child(fire)
	elif structure_name == "Lean-to Shelters":
		for entry in [[Vector3(-4.6,0,-2.8),Color("#887657")], [Vector3(4.8,0,-2.4),Color("#75664e")], [Vector3(-3.8,0,3.8),Color("#96805b")], [Vector3(3.9,0,4.2),Color("#806d50")], [Vector3(7.0,0,1.7),Color("#8c7855")]]:
			var shelter_offset := _settlement_surface_offset(root, entry[0] as Vector3)
			_create_settlement_path(root, shelter_offset)
			_create_tent(root, shelter_offset, entry[1] as Color)
	elif structure_name == "Storage Pits":
		var storage_center := _settlement_surface_offset(root, Vector3(-6.2,0,5.6))
		_create_settlement_path(root, storage_center)
		for i in 4:
			var store := MeshInstance3D.new()
			var store_mesh := CylinderMesh.new()
			store_mesh.top_radius = 0.48
			store_mesh.bottom_radius = 0.55
			store_mesh.height = 0.58
			store_mesh.radial_segments = 12
			store.mesh = store_mesh
			store.position = storage_center + Vector3(-1.7 + i * 1.1, 0.18, 0.0)
			var store_material := StandardMaterial3D.new()
			store_material.albedo_color = Color("#5d4b38")
			store.material_override = store_material
			root.add_child(store)
	elif structure_name == "Open Work Area":
		var work_center := _settlement_surface_offset(root, Vector3(7.0,0,-6.4))
		_create_settlement_path(root, work_center)
		_create_field(root, work_center, Vector2(6.8,4.8))
		_create_open_shed(root, work_center)
	elif structure_name == "Gathering Yard":
		var yard_center := _settlement_surface_offset(root, Vector3(-7.5,0,-6.0))
		_create_settlement_path(root, yard_center)
		_create_field(root, yard_center, Vector2(6.2,4.6))
		for i in 7:
			var bundle := MeshInstance3D.new()
			var bundle_mesh := CylinderMesh.new()
			bundle_mesh.top_radius = 0.18
			bundle_mesh.bottom_radius = 0.22
			bundle_mesh.height = 2.0
			bundle.mesh = bundle_mesh
			bundle.rotation.z = PI * 0.5
			bundle.position = yard_center + Vector3(-1.35 + float(i % 4) * 0.82, 0.30 + float(i / 4) * 0.42, 0.0)
			var bundle_material := StandardMaterial3D.new()
			bundle_material.albedo_color = Color("#684b32")
			bundle.material_override = bundle_material
			root.add_child(bundle)

func _settlement_surface_offset(root: Node3D, flat_offset: Vector3) -> Vector3:
	var origin := settlement_visual_root.position
	var world_x := origin.x + flat_offset.x * SETTLEMENT_DETAIL_SCALE
	var world_z := origin.z + flat_offset.z * SETTLEMENT_DETAIL_SCALE
	var local_height := (_height_at(world_x, world_z) - origin.y) / SETTLEMENT_DETAIL_SCALE
	return Vector3(flat_offset.x, local_height + 0.10, flat_offset.z)

func _create_settlement_path(root: Node3D, target: Vector3) -> void:
	var horizontal_target := Vector2(target.x, target.z)
	var length := horizontal_target.length()
	if length < 1.0:
		return
	var steps := maxi(2, ceili(length / 1.15))
	var angle := atan2(target.x, target.z)
	var path_material := StandardMaterial3D.new()
	path_material.albedo_color = Color("#887856")
	path_material.roughness = 1.0
	for i in steps:
		var progress := (float(i) + 0.5) / float(steps)
		var flat := Vector3(target.x * progress, 0.0, target.z * progress)
		var point := _settlement_surface_offset(root, flat)
		var path_piece := MeshInstance3D.new()
		var path_mesh := BoxMesh.new()
		path_mesh.size = Vector3(0.78, 0.065, minf(1.28, length / steps + 0.18))
		path_piece.mesh = path_mesh
		path_piece.position = point
		path_piece.rotation.y = angle
		path_piece.material_override = path_material
		root.add_child(path_piece)

func _create_open_shed(root: Node3D, center: Vector3) -> void:
	var timber_material := StandardMaterial3D.new()
	timber_material.albedo_color = Color("#5f4631")
	timber_material.roughness = 0.96
	for offset in [Vector3(-2.2,0,-1.4), Vector3(2.2,0,-1.4), Vector3(-2.2,0,1.4), Vector3(2.2,0,1.4)]:
		var post := MeshInstance3D.new()
		var post_mesh := CylinderMesh.new()
		post_mesh.top_radius = 0.12
		post_mesh.bottom_radius = 0.15
		post_mesh.height = 2.6
		post_mesh.radial_segments = 8
		post.mesh = post_mesh
		post.position = center + offset + Vector3.UP * 1.32
		post.material_override = timber_material
		root.add_child(post)
	var roof := MeshInstance3D.new()
	var roof_mesh := BoxMesh.new()
	roof_mesh.size = Vector3(5.4, 0.24, 3.8)
	roof.mesh = roof_mesh
	roof.position = center + Vector3.UP * 2.68
	roof.rotation.z = 0.08
	var roof_material := StandardMaterial3D.new()
	roof_material.albedo_color = Color("#7a6244")
	roof_material.roughness = 1.0
	roof.material_override = roof_material
	root.add_child(roof)

func _create_wagon(parent: Node3D, offset: Vector3, yaw: float) -> void:
	var wagon := Node3D.new()
	wagon.name = "ConvoyWagon"
	wagon.position = offset
	wagon.rotation.y = yaw
	parent.add_child(wagon)
	var bed := MeshInstance3D.new()
	var bed_mesh := BoxMesh.new()
	bed_mesh.size = Vector3(2.35, 0.55, 1.25)
	bed.mesh = bed_mesh
	bed.position.y = 0.72
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color("#765137")
	wood.roughness = 0.95
	bed.material_override = wood
	wagon.add_child(bed)
	var cover := MeshInstance3D.new()
	var cover_mesh := CapsuleMesh.new()
	cover_mesh.radius = 0.68
	cover_mesh.height = 2.15
	cover.mesh = cover_mesh
	cover.rotation.z = PI * 0.5
	cover.position.y = 1.45
	cover.scale = Vector3(1.0, 1.0, 0.72)
	var canvas := StandardMaterial3D.new()
	canvas.albedo_color = Color("#d8c9a5")
	canvas.roughness = 1.0
	cover.material_override = canvas
	wagon.add_child(cover)
	for side in [-1.0, 1.0]:
		for front in [-0.72, 0.72]:
			var wheel := MeshInstance3D.new()
			var wheel_mesh := CylinderMesh.new()
			wheel_mesh.top_radius = 0.36
			wheel_mesh.bottom_radius = 0.36
			wheel_mesh.height = 0.15
			wheel_mesh.radial_segments = 12
			wheel.mesh = wheel_mesh
			wheel.rotation.z = PI * 0.5
			wheel.position = Vector3(front, 0.42, side * 0.68)
			var wheel_material := StandardMaterial3D.new()
			wheel_material.albedo_color = Color("#322b25")
			wheel.material_override = wheel_material
			wagon.add_child(wheel)

func _on_settler_clicked(_camera: Node, event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		camera_target = settler_marker.position
		if event.double_click:
			camera.size = 0.18
			_update_camera()
		_inspect_location(settler_marker.position)
		if travel_status_label:
			travel_status_label.text="%s SELECTED  •  Open POPULATION in the top bar to manage roles" % _settlement_display_name()
		get_viewport().set_input_as_handled()

func _toggle_people_panel() -> void:
	if settler_panel and settler_panel.visible:
		_close_people_panel()
	else:
		_open_people_panel()

func _open_people_panel() -> void:
	if settler_panel==null:
		return
	settler_panel.visible=true
	if lens_panel:
		lens_panel.visible=false
	_refresh_population_allocations()
	_update_resource_proximity()

func _close_people_panel() -> void:
	if settler_panel:
		settler_panel.visible=false
	if lens_panel:
		lens_panel.visible=lens_requested_visible

func _move_settlers_to_screen(screen_position: Vector2) -> void:
	if settler_marker == null:
		return
	var hit:=_terrain_hit(screen_position)
	if hit.is_empty():
		return
	var destination: Vector3 = hit.position + Vector3.UP * 0.002
	if SEAMLESS_WORLD and destination.y<=SEA_LEVEL+0.02:
		_inspect_location(destination)
		if travel_status_label:
			travel_status_label.text="OPEN WATER  •  the founding convoy cannot travel here"
		return
	if GameState.settlement_site_committed or hearth_established or "Hearth Circle" in GameState.settlement_completed:
		settler_panel.visible = false
		_inspect_location(destination)
		if travel_status_label:
			travel_status_label.text="SETTLEMENT SITE COMMITTED  •  the people are establishing a permanent home here"
		return
	travel_start = settler_marker.position
	travel_target = destination
	var route:=_analyze_convoy_route(travel_start,travel_target)
	if not bool(route.get("valid",false)):
		_inspect_location(destination)
		if travel_status_label:
			travel_status_label.text=String(route.get("reason","ROUTE BLOCKED"))
		return
	var distance_km:=float(route.distance_km)
	var terrain_modifier:=float(route.terrain_modifier)
	travel_days_total = maxf(0.5, distance_km / (CONVOY_KM_PER_DAY * terrain_modifier))
	var endurance:=_estimated_convoy_endurance_days()
	if travel_days_total>endurance:
		_inspect_location(destination)
		if travel_status_label:
			travel_status_label.text="ROUTE UNSUSTAINABLE  •  %.0f km / %.0f days  •  provisions + forage sustain about %.0f days  •  stage the journey" % [distance_km,travel_days_total,endurance]
		return
	if float(GameState.simulation_metrics.get("food_days",30.0))<2.0 and float(GameState.simulation_metrics.get("food_balance",-1.0))<0.0:
		if travel_status_label:
			travel_status_label.text="NO MARCHING RESERVE  •  increase FOOD work and rebuild at least 2 days of provisions"
		return
	travel_days_elapsed = 0.0
	travel_active = true
	GameState.convoy_traveling=true
	GameState.convoy_emergency_halt_reason=""
	travel_reported_milestones.clear()
	_draw_route(travel_start, travel_target)
	settler_panel.visible = false
	_inspect_location(destination)
	_update_time_interface()
	_issue_travel_council_report("departure",0.0)

func _start_settlement_here() -> void:
	if GameState.settlement_site_committed or settler_marker == null:
		return
	var route_progress:=0.0
	if travel_active:
		route_progress=clampf(travel_days_elapsed/maxf(0.001,travel_days_total),0.0,1.0)
	travel_active=false
	GameState.convoy_traveling=false
	GameState.convoy_emergency_halt_reason=""
	GameState.simulation_metrics["traveling"]=false
	GameState.simulation_metrics["travel_speed_factor"]=0.0
	GameState.settlement_site_committed=true
	GameState.settlement_founded_at=settler_marker.position
	if route_mesh:
		route_mesh.visible=false
	if settlement_visual_root:
		settlement_visual_root.position=GameState.settlement_founded_at
	_update_resource_proximity()
	_refresh_settlement_footprint(true)
	_update_settlement_progress_text()
	var absolute_hour:=int(floor(GameState.elapsed_days*24.0))
	var event:={
		"id":"settlement_site_%d" % absolute_hour,
		"day":int(GameState.elapsed_days),
		"hour":absolute_hour%24,
		"title":"Settlement Site Chosen",
		"description":"At %02d:00, the sovereign ordered the convoy to halt in %s and establish a permanent home. The first Hearth Circle must still emerge from the people's assigned work." % [absolute_hour%24,GameState.province_name],
		"domain":"settlement",
		"severity":"major",
		"location":GameState.province_name
	}
	GameState.simulation_events.push_front(event)
	if GameState.simulation_events.size()>80:
		GameState.simulation_events.resize(80)
	_issue_travel_council_report("settlement",route_progress)
	_open_people_panel()
	_update_time_interface()
	_open_settlement_naming_panel.call_deferred()

func _analyze_convoy_route(from: Vector3,to: Vector3) -> Dictionary:
	var distance_km:=Vector2(from.x,from.z).distance_to(Vector2(to.x,to.z))*KM_PER_WORLD_UNIT
	if distance_km<0.25:
		return {"valid":false,"reason":"DESTINATION TOO CLOSE  •  choose a point at least 250 m away"}
	var samples:=clampi(ceili(distance_km/1.5),12,640)
	var step_km:=distance_km/float(samples)
	var wet_run:=0.0
	var longest_wet_run:=0.0
	var elevation_total:=0.0
	var elevation_change:=0.0
	var previous_height:=_height_at(from.x,from.z)
	for i in range(1,samples+1):
		var progress:=float(i)/float(samples)
		var point:=from.lerp(to,progress)
		var height:=_height_at(point.x,point.z)
		elevation_total+=maxf(0.0,height)
		elevation_change+=absf(height-previous_height)
		previous_height=height
		if height<=SEA_LEVEL+0.015:
			wet_run+=step_km
			longest_wet_run=maxf(longest_wet_run,wet_run)
		else:
			wet_run=0.0
	if longest_wet_run>4.0:
		return {"valid":false,"reason":"ROUTE CROSSES %.0f km OF OPEN WATER  •  boats and navigation have not been discovered" % longest_wet_run}
	var mean_relief:=elevation_total/maxf(1.0,float(samples))
	var terrain_modifier:=clampf(1.02-mean_relief*0.045-elevation_change/maxf(1.0,distance_km)*0.12,0.42,1.0)
	if longest_wet_run>0.0: terrain_modifier*=0.84
	return {"valid":true,"distance_km":distance_km,"terrain_modifier":terrain_modifier,"water_crossing_km":longest_wet_run}

func _estimated_convoy_endurance_days() -> float:
	var population:=maxf(1.0,GameState.population_exact)
	var food_days:=float(GameState.resource_stockpiles.get("Food",population*30.0))/population
	var workers:=float(GameState.population_allocations.get("Food",0))
	var settled_production:=float(GameState.simulation_metrics.get("food_production",workers*2.40))
	var settled_need:=maxf(1.0,float(GameState.simulation_metrics.get("food_consumption",population)))
	var logistics_share:=clampf(float(GameState.population_allocations.get("Logistics",0))/maxf(1.0,population*0.08),0.0,1.0)
	var moving_ratio:=(settled_production/settled_need)*(0.38+logistics_share*0.10)/1.14
	if moving_ratio>=0.98:
		return 3650.0
	return maxf(2.0,food_days/maxf(0.08,1.0-moving_ratio)*0.92)

func _evaluate_travel_survival() -> void:
	if not travel_active:
		return
	var food_days:=float(GameState.simulation_metrics.get("food_days",0.0))
	var production_ratio:=float(GameState.simulation_metrics.get("food_balance",-1.0))+1.0
	var shortage_days:=float(GameState.simulation_metrics.get("food_shortage_days",0.0))
	var health:=float(GameState.simulation_metrics.get("health",GameState.population_health))
	if food_days<3.0 and not travel_reported_milestones.has("provisions_low"):
		travel_reported_milestones["provisions_low"]=true
		_issue_travel_council_report("provisions_low",clampf(travel_days_elapsed/maxf(0.001,travel_days_total),0.0,1.0))
	if not ((food_days<=0.001 and production_ratio<0.76 and shortage_days>=6.0) or health<0.30):
		return
	var reason:="no provisions; route foraging supplies only %d%% of daily need" % roundi(production_ratio*100.0)
	if health<0.30:
		reason="population health fell to %d%%" % roundi(health*100.0)
	travel_active=false
	GameState.convoy_traveling=false
	GameState.convoy_emergency_halt_reason=reason
	GameState.simulation_metrics["traveling"]=false
	GameState.simulation_metrics["travel_speed_factor"]=0.0
	game_speed=0.0
	if route_mesh: route_mesh.visible=false
	var event:={
		"id":"convoy_halt_%d" % int(GameState.elapsed_days),"day":int(GameState.elapsed_days),
		"title":"Convoy Forced to Halt","description":"The journey stopped because %s. Reassign people to Food and rebuild a marching reserve before ordering another leg." % reason,
		"domain":"food","severity":"critical"
	}
	GameState.simulation_events.push_front(event)
	if GameState.simulation_events.size()>80: GameState.simulation_events.resize(80)
	AdvisorSystem.generate_consequence_item(event)
	_issue_travel_council_report("halt",clampf(travel_days_elapsed/maxf(0.001,travel_days_total),0.0,1.0),reason)
	_update_time_interface()

func _check_travel_milestone_reports(progress: float) -> void:
	for entry in [["quarter",0.25],["half",0.50],["three_quarters",0.75]]:
		var key:=String(entry[0])
		var threshold:=float(entry[1])
		if progress>=threshold and not travel_reported_milestones.has(key):
			travel_reported_milestones[key]=true
			_issue_travel_council_report(key,progress)

func _issue_travel_council_report(stage: String,progress: float,reason:="") -> void:
	var population:=maxf(1.0,GameState.population_exact)
	var food_days:=float(GameState.resource_stockpiles.get("Food",0.0))/population
	var supply_ratio:=float(GameState.simulation_metrics.get("food_balance",0.0))+1.0
	var data:={
		"distance_km":Vector2(travel_start.x,travel_start.z).distance_to(Vector2(travel_target.x,travel_target.z))*KM_PER_WORLD_UNIT,
		"duration_days":travel_days_total,"food_days":food_days,"supply_ratio":supply_ratio,
		"progress":progress,"reason":reason,
		"terrain":GameState.province_terrain,
		"known_resources":ResourceSystem.visible_deposits().size()
	}
	var item:=AdvisorSystem.generate_travel_item(stage,data)
	if item.is_empty() or travel_council_notice==null:
		return
	var urgency:=float(item.get("urgency",0.4))
	var accent:=Color("#b46452") if urgency>0.7 else Color("#b59b5d")
	travel_council_notice.text="TRAVEL COUNCIL  •  %s\n%s\nOPEN COUNCIL" % [String(item.get("advisor","Council")),String(item.get("text",""))]
	travel_council_notice.add_theme_stylebox_override("normal",_population_report_style(accent))
	travel_council_notice.add_theme_stylebox_override("hover",_population_report_style(accent,true))
	travel_council_notice.add_theme_stylebox_override("pressed",_population_report_style(accent,true))
	travel_council_notice.visible=true
	travel_council_notice_until_msec=Time.get_ticks_msec()+(13000 if urgency>0.7 else 8500)

func _draw_route(from: Vector3, to: Vector3) -> void:
	if route_mesh:
		route_mesh.queue_free()
	var immediate := ImmediateMesh.new()
	immediate.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for i in 25:
		var progress := float(i) / 24.0
		var point := from.lerp(to, progress)
		point.y = _height_at(point.x, point.z) + 0.012
		immediate.surface_add_vertex(point)
	immediate.surface_end()
	route_mesh = MeshInstance3D.new()
	route_mesh.mesh = immediate
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color("#f1d47a")
	material.no_depth_test = true
	route_mesh.material_override = material
	add_child(route_mesh)

func _create_camp_banner(parent: Node3D) -> void:
	var pole := MeshInstance3D.new()
	var pole_mesh := CylinderMesh.new()
	pole_mesh.top_radius = 0.07
	pole_mesh.bottom_radius = 0.09
	pole_mesh.height = 4.6
	pole.mesh = pole_mesh
	pole.position = Vector3(0, 2.35, 0)
	var pole_material := StandardMaterial3D.new()
	pole_material.albedo_color = Color("#43392d")
	pole.material_override = pole_material
	parent.add_child(pole)
	var flag := MeshInstance3D.new()
	var flag_mesh := QuadMesh.new()
	flag_mesh.size = Vector2(2.2, 1.15)
	flag.mesh = flag_mesh
	flag.position = Vector3(1.1, 4.0, 0)
	flag.rotation.y = PI * 0.5
	var flag_material := StandardMaterial3D.new()
	flag_material.albedo_color = Color("#3f6d88")
	flag_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	flag.material_override = flag_material
	parent.add_child(flag)

func _find_camp_position() -> Vector3:
	if SEAMLESS_WORLD:
		return _find_world_start_position()
	var best := Vector3.ZERO
	var best_score := INF
	for z_step in 37:
		for x_step in 37:
			var u := float(x_step) / 36.0
			var v := float(z_step) / 36.0
			if u < 0.18 or u > 0.82 or v < 0.16 or v > 0.84:
				continue
			if not _inside_province(u, v):
				continue
			var x: float = (u - 0.5) * world_width
			var z: float = (v - 0.5) * world_depth
			var height: float = _height_at(x, z)
			if height < -1.5 or height > 5.5:
				continue
			var nearby_heights := [
				_height_at(x - 2.5, z), _height_at(x + 2.5, z),
				_height_at(x, z - 2.5), _height_at(x, z + 2.5),
				_height_at(x - 4.8, z), _height_at(x + 4.8, z),
				_height_at(x, z - 4.8), _height_at(x, z + 4.8),
				_height_at(x - 3.4, z - 3.4), _height_at(x + 3.4, z + 3.4),
				_height_at(x - 3.4, z + 3.4), _height_at(x + 3.4, z - 3.4)
			]
			var local_min := height
			var local_max := height
			for sample_height in nearby_heights:
				local_min = minf(local_min, float(sample_height))
				local_max = maxf(local_max, float(sample_height))
			var roughness := local_max - local_min
			var river_u := _river_u_at_v(v)
			var river_clearance := INF if river_u < 0.0 else absf(x - (river_u - 0.5) * world_width)
			var channel_penalty := 40.0 if river_clearance < 0.75 else absf(river_clearance - 2.4) * 1.7
			var score: float = Vector2(x, z).length() * 0.20 + absf(height) * 0.45 + roughness * 29.0 + channel_penalty
			if score < best_score:
				best_score = score
				best = Vector3(x, height + 0.002, z)
	return best

func _find_world_start_position() -> Vector3:
	var best:=Vector3.ZERO
	var best_score:=INF
	# The seed defines the planet, but the founding convoy begins in a viable
	# temperate watershed instead of being dropped arbitrarily into ocean or ice.
	for z_step in 61:
		for x_step in 61:
			var x:=(float(x_step)-30.0)*5.0
			var z:=(float(z_step)-30.0)*5.0
			var height:=_height_at(x,z)
			if height<0.08 or height>4.8:
				continue
			var slope:=_terrain_slope_at(x,z,1.2)
			if slope>0.48:
				continue
			var river_x:=_world_river_x(z)
			var river_distance:=absf(x-river_x) if river_x!=INF else 9999.0
			if river_distance<1.2 or river_distance>18.0:
				continue
			var moisture:=moisture_noise.get_noise_2d(x,z)
			var score:=Vector2(x,z).length()*0.012+absf(river_distance-5.5)*1.8+slope*38.0+absf(height-0.55)*1.2-maxf(0.0,moisture)*3.0
			if score<best_score:
				best_score=score
				best=Vector3(x,height+0.002,z)
	if best_score==INF:
		var fallback_height:=_height_at(0.0,0.0)
		return Vector3(0.0,maxf(0.05,fallback_height)+0.002,0.0)
	return best

func _create_building(parent: Node3D, offset: Vector3, size: Vector3, color: Color) -> void:
	var building := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	building.mesh = mesh
	building.position = offset + Vector3(0, size.y * 0.5, 0)
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.95
	building.material_override = material
	parent.add_child(building)
	var roof := MeshInstance3D.new()
	var roof_mesh := CylinderMesh.new()
	roof_mesh.top_radius = 0.0
	roof_mesh.bottom_radius = max(size.x, size.z) * 0.66
	roof_mesh.height = 1.15
	roof_mesh.radial_segments = 4
	roof.mesh = roof_mesh
	roof.position = offset + Vector3(0, size.y + 0.57, 0)
	roof.rotation.y = PI * 0.25
	var roof_material := StandardMaterial3D.new()
	roof_material.albedo_color = Color("#493d32")
	roof.material_override = roof_material
	parent.add_child(roof)

func _create_field(parent: Node3D, offset: Vector3, size: Vector2) -> void:
	var field := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(size.x, 0.08, size.y)
	field.mesh = mesh
	field.position = offset + Vector3(0, 0.05, 0)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("#887b42")
	material.roughness = 1.0
	field.material_override = material
	parent.add_child(field)

func _create_tent(parent: Node3D, offset: Vector3, color: Color) -> void:
	var tent := MeshInstance3D.new()
	var mesh := PrismMesh.new()
	mesh.size = Vector3(2.8, 1.72, 2.35)
	tent.mesh = mesh
	tent.position = offset + Vector3(0, 0.86, 0)
	tent.rotation.y = PI * 0.08
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.95
	tent.material_override = material
	parent.add_child(tent)

func _build_interface() -> void:
	var layer := CanvasLayer.new()
	interface_layer = layer
	add_child(layer)
	var viewport_width := get_viewport().get_visible_rect().size.x
	var top_bar := ColorRect.new()
	top_bar.position = Vector2.ZERO
	top_bar.size = Vector2(viewport_width, 94)
	top_bar.color = Color("#0a1114f5")
	layer.add_child(top_bar)
	var top_rule := ColorRect.new()
	top_rule.position = Vector2(0, 93)
	top_rule.size = Vector2(viewport_width, 1)
	top_rule.color = Color("#70664f")
	layer.add_child(top_rule)
	var label := Label.new()
	label.position = Vector2(18, 9)
	label.size = Vector2(238, 40)
	label.text = "%s\n%s" % [GameState.province_name.to_upper(),"FOUNDING EXPEDITION" if not GameState.settlement_site_committed else _settlement_display_name()]
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color("#ded6c4"))
	layer.add_child(label)
	population_summary_label = Button.new()
	population_summary_label.position = Vector2(18, 53)
	population_summary_label.size = Vector2(180, 32)
	population_summary_label.alignment = HORIZONTAL_ALIGNMENT_LEFT
	population_summary_label.flat = false
	population_summary_label.tooltip_text = "Open People management and set standing role percentages."
	population_summary_label.pressed.connect(_toggle_people_panel)
	population_summary_label.add_theme_font_size_override("font_size", 12)
	population_summary_label.add_theme_color_override("font_color", Color("#aaa99f"))
	layer.add_child(population_summary_label)
	event_report_button=Button.new()
	event_report_button.position=Vector2(18,105)
	event_report_button.size=Vector2(430,76)
	event_report_button.alignment=HORIZONTAL_ALIGNMENT_LEFT
	event_report_button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	event_report_button.add_theme_font_size_override("font_size",12)
	event_report_button.add_theme_color_override("font_color",Color("#eadfca"))
	event_report_button.tooltip_text="Open the full population and consequence ledger."
	event_report_button.pressed.connect(_open_population_ledger)
	event_report_button.visible=false
	layer.add_child(event_report_button)
	date_label = Label.new()
	date_label.position = Vector2(viewport_width * 0.5 - 310, 9)
	date_label.size = Vector2(300, 32)
	date_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	date_label.add_theme_font_size_override("font_size", 17)
	date_label.add_theme_color_override("font_color", Color("#f0e6d1"))
	layer.add_child(date_label)
	var speed_row:=HBoxContainer.new()
	speed_row.position=Vector2(viewport_width*0.5+2,9)
	speed_row.size=Vector2(188,34)
	speed_row.add_theme_constant_override("separation",4)
	layer.add_child(speed_row)
	for speed_entry in [[0,"Ⅱ","Pause"],[1,"1","0.5 hour per second"],[2,"2","2 hours per second"],[3,"3","8 hours per second"],[4,"4","1 day per second"],[5,"5","3 days per second"]]:
		var speed_button:=Button.new()
		speed_button.text=speed_entry[1]
		speed_button.tooltip_text=speed_entry[2]
		speed_button.toggle_mode=true
		speed_button.custom_minimum_size=Vector2(28,32)
		speed_button.add_theme_font_size_override("font_size",11)
		speed_button.pressed.connect(_set_game_speed.bind(float(speed_entry[0])))
		speed_row.add_child(speed_button)
		time_speed_buttons[int(speed_entry[0])]=speed_button
	travel_status_label = Label.new()
	travel_status_label.position = Vector2(viewport_width * 0.5 - 390, 96)
	travel_status_label.size = Vector2(780, 26)
	travel_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	travel_status_label.add_theme_font_size_override("font_size", 11)
	travel_status_label.add_theme_color_override("font_color", Color("#ead078"))
	layer.add_child(travel_status_label)
	var menu_button:=Button.new()
	menu_button.position=Vector2(viewport_width-116,9)
	menu_button.size=Vector2(98,34)
	menu_button.text="MENU"
	menu_button.tooltip_text="Pause, view controls, restart, or begin a new world."
	menu_button.add_theme_font_size_override("font_size",11)
	menu_button.pressed.connect(_open_world_menu)
	layer.add_child(menu_button)
	_build_scale_bar(layer)
	var society_button:=Button.new()
	society_button.position=Vector2(viewport_width-650,53)
	society_button.size=Vector2(94,32)
	society_button.text="SOCIETY"
	society_button.tooltip_text="Open the twelve systems that describe the civilization and their current drivers."
	society_button.add_theme_font_size_override("font_size",11)
	society_button.pressed.connect(_open_society_panel)
	layer.add_child(society_button)
	var mandate_button := Button.new()
	mandate_button.position = Vector2(viewport_width - 548, 53)
	mandate_button.size = Vector2(94, 32)
	mandate_button.text = "MANDATE"
	mandate_button.add_theme_font_size_override("font_size", 12)
	mandate_button.pressed.connect(_open_mandate_panel)
	layer.add_child(mandate_button)
	var leadership_button := Button.new()
	leadership_button.position = Vector2(viewport_width - 446, 53)
	leadership_button.size = Vector2(94, 32)
	leadership_button.text = "COURT"
	leadership_button.add_theme_font_size_override("font_size", 12)
	leadership_button.pressed.connect(_open_government_panel)
	layer.add_child(leadership_button)
	var knowledge_button := Button.new()
	knowledge_button.position = Vector2(viewport_width - 344, 53)
	knowledge_button.size = Vector2(94, 32)
	knowledge_button.text = "INQUIRY"
	knowledge_button.add_theme_font_size_override("font_size", 12)
	knowledge_button.pressed.connect(_open_knowledge_panel)
	layer.add_child(knowledge_button)
	var council_button := Button.new()
	council_button.position = Vector2(viewport_width - 242, 53)
	council_button.size = Vector2(94, 32)
	council_button.text = "COUNCIL"
	council_button.add_theme_font_size_override("font_size", 12)
	council_button.pressed.connect(_open_council_panel)
	layer.add_child(council_button)
	travel_council_notice=Button.new()
	travel_council_notice.position=Vector2(maxf(500.0,viewport_width-890.0),84)
	travel_council_notice.size=Vector2(390,140)
	travel_council_notice.alignment=HORIZONTAL_ALIGNMENT_LEFT
	travel_council_notice.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	travel_council_notice.add_theme_font_size_override("font_size",12)
	travel_council_notice.add_theme_color_override("font_color",Color("#eadfc8"))
	travel_council_notice.tooltip_text="Open the full council record."
	travel_council_notice.pressed.connect(_open_council_panel)
	travel_council_notice.visible=false
	layer.add_child(travel_council_notice)
	start_settlement_button=Button.new()
	start_settlement_button.position=Vector2(viewport_width*0.5-165,get_viewport().get_visible_rect().size.y-112)
	start_settlement_button.size=Vector2(330,64)
	start_settlement_button.text="START SETTLEMENT\nFound at the convoy's current location"
	start_settlement_button.tooltip_text="Halt the convoy at its exact current location and begin founding a permanent settlement."
	start_settlement_button.add_theme_font_size_override("font_size",14)
	start_settlement_button.add_theme_color_override("font_color",Color("#f1e4c8"))
	start_settlement_button.add_theme_color_override("font_hover_color",Color("#fff1cb"))
	start_settlement_button.add_theme_stylebox_override("normal",_population_report_style(Color("#b99b5d")))
	start_settlement_button.add_theme_stylebox_override("hover",_population_report_style(Color("#d2b56e"),true))
	start_settlement_button.add_theme_stylebox_override("pressed",_population_report_style(Color("#ead078"),true))
	start_settlement_button.pressed.connect(_start_settlement_here)
	layer.add_child(start_settlement_button)
	provisions_button=Button.new()
	provisions_button.position=Vector2(206,53)
	provisions_button.size=Vector2(200,32)
	provisions_button.alignment=HORIZONTAL_ALIGNMENT_LEFT
	provisions_button.tooltip_text="Open the full provision ledger: sources, diet, losses, demand, reserves, and forecast."
	provisions_button.add_theme_font_size_override("font_size",10)
	provisions_button.add_theme_color_override("font_color",Color("#eadfc8"))
	provisions_button.add_theme_stylebox_override("normal",_population_report_style(Color("#79906a")))
	provisions_button.add_theme_stylebox_override("hover",_population_report_style(Color("#aab778"),true))
	provisions_button.pressed.connect(_open_provisions_panel)
	layer.add_child(provisions_button)
	materials_button=Button.new()
	materials_button.position=Vector2(414,53)
	materials_button.size=Vector2(200,32)
	materials_button.alignment=HORIZONTAL_ALIGNMENT_LEFT
	materials_button.tooltip_text="Open the material ledger: knowledge, extraction, hauling, stores, losses, and constraints."
	materials_button.add_theme_font_size_override("font_size",10)
	materials_button.add_theme_color_override("font_color",Color("#eadfc8"))
	materials_button.add_theme_stylebox_override("normal",_population_report_style(Color("#8a7658")))
	materials_button.add_theme_stylebox_override("hover",_population_report_style(Color("#b69b68"),true))
	materials_button.pressed.connect(_open_materials_panel)
	layer.add_child(materials_button)
	settler_panel = Control.new()
	settler_panel.visible = false
	layer.add_child(settler_panel)
	_refresh_event_report()
	var choice_panel := ColorRect.new()
	choice_panel.position = Vector2(viewport_width - 376, 72)
	choice_panel.size = Vector2(358, 600)
	choice_panel.color = Color(0.055, 0.07, 0.075, 0.96)
	settler_panel.add_child(choice_panel)
	people_panel_title = Label.new()
	people_panel_title.position = choice_panel.position + Vector2(22, 18)
	people_panel_title.size=Vector2(138,34)
	people_panel_title.clip_text=true
	people_panel_title.text = "FOUNDING CONVOY"
	people_panel_title.add_theme_font_size_override("font_size", 14)
	people_panel_title.add_theme_color_override("font_color", Color("#eadfca"))
	settler_panel.add_child(people_panel_title)
	settlement_name_button=Button.new()
	settlement_name_button.position=choice_panel.position+Vector2(164,12)
	settlement_name_button.size=Vector2(48,34)
	settlement_name_button.text="NAME"
	settlement_name_button.tooltip_text="Name the permanent settlement site."
	settlement_name_button.add_theme_font_size_override("font_size",10)
	settlement_name_button.pressed.connect(_open_settlement_naming_panel)
	settler_panel.add_child(settlement_name_button)
	var ledger_button:=Button.new()
	ledger_button.position=choice_panel.position+Vector2(216,12)
	ledger_button.size=Vector2(84,34)
	ledger_button.text="LEDGER"
	ledger_button.tooltip_text="Every birth, death, cause, location, and wider consequence."
	ledger_button.add_theme_font_size_override("font_size",11)
	ledger_button.pressed.connect(_open_population_ledger)
	settler_panel.add_child(ledger_button)
	var people_close:=Button.new()
	people_close.position=choice_panel.position+Vector2(306,12)
	people_close.size=Vector2(32,34)
	people_close.text="×"
	people_close.tooltip_text="Close People management"
	people_close.pressed.connect(_close_people_panel)
	settler_panel.add_child(people_close)
	people_summary_label = Label.new()
	people_summary_label.position = choice_panel.position + Vector2(22, 58)
	people_summary_label.size = Vector2(314, 70)
	people_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	people_summary_label.add_theme_font_size_override("font_size", 13)
	people_summary_label.add_theme_color_override("font_color", Color("#cfc8b9"))
	settler_panel.add_child(people_summary_label)
	age_distribution_title=Label.new()
	age_distribution_title.position=choice_panel.position+Vector2(22,122)
	age_distribution_title.size=Vector2(314,18)
	age_distribution_title.add_theme_font_size_override("font_size",10)
	age_distribution_title.add_theme_color_override("font_color",Color("#d2b870"))
	settler_panel.add_child(age_distribution_title)
	age_distribution_bar=HBoxContainer.new()
	age_distribution_bar.position=choice_panel.position+Vector2(22,142)
	age_distribution_bar.size=Vector2(314,34)
	age_distribution_bar.add_theme_constant_override("separation",2)
	settler_panel.add_child(age_distribution_bar)
	var cohort_colors:=[Color("#d99c68"),Color("#d6bd62"),Color("#84ad72"),Color("#5d9c8c"),Color("#66869c"),Color("#786f91")]
	for cohort_color in cohort_colors:
		var segment:=ColorRect.new()
		segment.custom_minimum_size=Vector2(40,34)
		segment.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		segment.size_flags_stretch_ratio=1.0
		segment.color=cohort_color
		segment.mouse_filter=Control.MOUSE_FILTER_STOP
		age_distribution_bar.add_child(segment)
		age_distribution_segments.append(segment)
		var segment_label:=Label.new()
		segment_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		segment_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		segment_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
		segment_label.add_theme_font_size_override("font_size",9)
		segment_label.add_theme_color_override("font_color",Color("#101716"))
		segment_label.mouse_filter=Control.MOUSE_FILTER_PASS
		segment.add_child(segment_label)
		age_distribution_segment_labels.append(segment_label)
	age_distribution_summary=Label.new()
	age_distribution_summary.position=choice_panel.position+Vector2(22,178)
	age_distribution_summary.size=Vector2(314,18)
	age_distribution_summary.add_theme_font_size_override("font_size",10)
	age_distribution_summary.add_theme_color_override("font_color",Color("#aeb5ae"))
	settler_panel.add_child(age_distribution_summary)
	var allocation_title := Label.new()
	allocation_title.position = choice_panel.position + Vector2(22, 202)
	allocation_title.text = "STANDING AUTO-ALLOCATION"
	allocation_title.add_theme_font_size_override("font_size", 12)
	allocation_title.add_theme_color_override("font_color", Color("#bda870"))
	settler_panel.add_child(allocation_title)
	var auto_note:=Label.new()
	auto_note.position=choice_panel.position+Vector2(22,220)
	auto_note.size=Vector2(314,22)
	auto_note.text="Percentages persist as the population changes."
	auto_note.add_theme_font_size_override("font_size",11)
	auto_note.add_theme_color_override("font_color",Color("#96988f"))
	settler_panel.add_child(auto_note)
	var roles := [
		["Food", "SUSTENANCE","Produces food immediately. Heavy local gathering can exhaust the surrounding ecology."],
		["Survey", "SURVEY PARTIES","Creates clues, recognizes deposits, and measures their quality. Survey speed depends on health and knowledge."],
		["Extraction", "GATHERERS","Works accessible timber, stone, clay, fiber, and later deposits. Extraction pressure changes ecology."],
		["Construction", "BUILDERS","Causes needed communal works and access routes to emerge. Output falls with illness and low cohesion."],
		["Crafting", "MAKERS","Improves tools and material capacity, accelerating extraction, construction, and later production."],
		["Logistics", "CARRIERS","Moves food and materials, supports storage, and determines whether distant resources are truly usable."],
		["Knowledge", "OBSERVERS","Provides real investigators for broad inquiry directions. Too many directions dilute their attention."],
		["Administration", "STEWARDS","Coordinates labor and stores while strengthening cohesion and legitimacy."],
		["Defense", "WATCH","Raises security and readiness, but every watcher is absent from food and construction work."]
	]
	for i in roles.size():
		var role_key: String = roles[i][0]
		var role_name := Label.new()
		role_name.position = choice_panel.position + Vector2(22, 244 + i * 28)
		role_name.size = Vector2(142, 27)
		role_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		role_name.text = roles[i][1]
		role_name.tooltip_text=roles[i][2]
		role_name.add_theme_font_size_override("font_size", 13)
		settler_panel.add_child(role_name)
		var minus := Button.new()
		minus.position = choice_panel.position + Vector2(168, 244 + i * 28)
		minus.size = Vector2(34, 27)
		minus.text = "−"
		minus.tooltip_text=roles[i][2]
		minus.pressed.connect(_change_population_allocation.bind(role_key, -2))
		settler_panel.add_child(minus)
		var amount := Label.new()
		amount.position = choice_panel.position + Vector2(205, 244 + i * 28)
		amount.size = Vector2(75, 27)
		amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		amount.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		amount.add_theme_font_size_override("font_size", 12)
		settler_panel.add_child(amount)
		population_value_labels[role_key] = amount
		var plus := Button.new()
		plus.position = choice_panel.position + Vector2(284, 244 + i * 28)
		plus.size = Vector2(34, 27)
		plus.text = "+"
		plus.tooltip_text=roles[i][2]
		plus.pressed.connect(_change_population_allocation.bind(role_key, 2))
		settler_panel.add_child(plus)
	nearby_resources_label = Label.new()
	nearby_resources_label.position = choice_panel.position + Vector2(22, 558)
	nearby_resources_label.size = Vector2(314, 26)
	nearby_resources_label.add_theme_font_size_override("font_size", 13)
	nearby_resources_label.add_theme_color_override("font_color", Color("#cfc8b9"))
	settler_panel.add_child(nearby_resources_label)
	choice_status = Label.new()
	choice_status.position = choice_panel.position + Vector2(22, 500)
	choice_status.size = Vector2(314, 54)
	choice_status.text = "NOMADIC ERA\nNo permanent works have emerged."
	choice_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	choice_status.add_theme_font_size_override("font_size", 13)
	choice_status.add_theme_color_override("font_color", Color("#aaa99f"))
	settler_panel.add_child(choice_status)
	_refresh_population_allocations()
	_update_resource_proximity()
	_update_time_interface()
	_build_lens(layer)
	_inspect_location(settler_marker.position)
	_close_lens()
	_refresh_discovered_resource_overlays()
	_build_leader_selection(layer)

func _build_scale_bar(layer: CanvasLayer) -> void:
	var viewport_size:=get_viewport().get_visible_rect().size
	scale_bar_root=Control.new()
	scale_bar_root.position=Vector2(24,viewport_size.y-92)
	scale_bar_root.size=Vector2(200,42)
	scale_bar_root.mouse_filter=Control.MOUSE_FILTER_IGNORE
	layer.add_child(scale_bar_root)
	var backing:=ColorRect.new()
	backing.size=Vector2(196,40)
	backing.color=Color(0.025,0.034,0.036,0.78)
	scale_bar_root.add_child(backing)
	scale_bar_label=Label.new()
	scale_bar_label.position=Vector2(10,2)
	scale_bar_label.size=Vector2(178,18)
	scale_bar_label.add_theme_font_size_override("font_size",11)
	scale_bar_label.add_theme_color_override("font_color",Color("#d7d0bf"))
	scale_bar_root.add_child(scale_bar_label)
	scale_bar_line=ColorRect.new()
	scale_bar_line.position=Vector2(10,27)
	scale_bar_line.size=Vector2(120,2)
	scale_bar_line.color=Color("#d7d0bf")
	scale_bar_root.add_child(scale_bar_line)
	var left_tick:=ColorRect.new()
	left_tick.position=Vector2(10,22)
	left_tick.size=Vector2(2,12)
	left_tick.color=Color("#d7d0bf")
	scale_bar_root.add_child(left_tick)
	scale_bar_right_tick=ColorRect.new()
	scale_bar_right_tick.position=Vector2(128,22)
	scale_bar_right_tick.size=Vector2(2,12)
	scale_bar_right_tick.color=Color("#d7d0bf")
	scale_bar_root.add_child(scale_bar_right_tick)
	_update_scale_bar()

func _update_scale_bar() -> void:
	if scale_bar_root==null or camera==null:
		return
	var viewport_height:=maxf(1.0,get_viewport().get_visible_rect().size.y)
	var km_per_pixel:=camera.size/viewport_height*KM_PER_WORLD_UNIT
	var target_km:=maxf(0.00001,km_per_pixel*125.0)
	var magnitude:=pow(10.0,floor(log(target_km)/log(10.0)))
	var normalized:=target_km/magnitude
	var step:=1.0
	if normalized<1.5: step=1.0
	elif normalized<3.5: step=2.0
	elif normalized<7.5: step=5.0
	else: step=10.0
	var distance_km:=step*magnitude
	var pixel_width:=clampf(distance_km/km_per_pixel,72.0,174.0)
	scale_bar_line.size.x=pixel_width
	scale_bar_right_tick.position.x=10.0+pixel_width-2.0
	if distance_km<1.0:
		scale_bar_label.text="%d M" % roundi(distance_km*1000.0)
	elif distance_km<10.0:
		scale_bar_label.text="%.1f KM" % distance_km
	else:
		scale_bar_label.text="%d KM" % roundi(distance_km)

func _open_settlement_naming_panel() -> void:
	if not GameState.settlement_site_committed:
		if travel_status_label:
			travel_status_label.text="Choose START SETTLEMENT before naming a permanent home"
		return
	if settlement_naming_panel:
		return
	naming_previous_speed=game_speed
	_set_game_speed(0.0)
	settlement_naming_panel=Control.new()
	settlement_naming_panel.size=get_viewport().get_visible_rect().size
	settlement_naming_panel.mouse_filter=Control.MOUSE_FILTER_STOP
	interface_layer.add_child(settlement_naming_panel)
	var dimmer:=ColorRect.new()
	dimmer.size=settlement_naming_panel.size
	dimmer.color=Color(0.008,0.013,0.015,0.88)
	settlement_naming_panel.add_child(dimmer)
	var modal:=PanelContainer.new()
	modal.size=Vector2(620,330)
	modal.position=(settlement_naming_panel.size-modal.size)*0.5
	var style:=StyleBoxFlat.new()
	style.bg_color=Color(0.04,0.052,0.055,0.995)
	style.border_color=Color("#85734e")
	style.set_border_width_all(1)
	style.set_content_margin_all(26)
	modal.add_theme_stylebox_override("panel",style)
	settlement_naming_panel.add_child(modal)
	var root:=VBoxContainer.new()
	root.add_theme_constant_override("separation",12)
	modal.add_child(root)
	var heading:=Label.new()
	heading.text="NAME THE FIRST SETTLEMENT" if GameState.settlement_name=="" else "RENAME THE SETTLEMENT"
	heading.add_theme_font_size_override("font_size",24)
	heading.add_theme_color_override("font_color",Color("#ecdfc4"))
	root.add_child(heading)
	var context:=Label.new()
	if "Hearth Circle" in GameState.settlement_completed:
		context.text="The Hearth Circle has anchored a permanent home in %s. Give this place the name that will enter its history." % GameState.province_name
	else:
		context.text="The convoy has committed to permanent ground in %s. The Hearth Circle is still emerging from the people's work. Give this place the name that will enter its history." % GameState.province_name
	context.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	context.custom_minimum_size=Vector2(0,52)
	context.add_theme_font_size_override("font_size",15)
	context.add_theme_color_override("font_color",Color("#b9b8af"))
	root.add_child(context)
	settlement_name_input=LineEdit.new()
	settlement_name_input.placeholder_text="Settlement name"
	settlement_name_input.max_length=32
	settlement_name_input.text=GameState.settlement_name
	settlement_name_input.custom_minimum_size=Vector2(0,48)
	settlement_name_input.add_theme_font_size_override("font_size",18)
	settlement_name_input.text_changed.connect(_on_settlement_name_changed)
	settlement_name_input.text_submitted.connect(_on_settlement_name_submitted)
	root.add_child(settlement_name_input)
	var note:=Label.new()
	note.text="The name can be changed later from the Population panel."
	note.add_theme_font_size_override("font_size",12)
	note.add_theme_color_override("font_color",Color("#8f928d"))
	root.add_child(note)
	var footer:=HBoxContainer.new()
	footer.alignment=BoxContainer.ALIGNMENT_END
	footer.add_theme_constant_override("separation",10)
	root.add_child(footer)
	var later:=Button.new()
	later.text="NOT YET"
	later.custom_minimum_size=Vector2(130,42)
	later.pressed.connect(_dismiss_settlement_naming_panel)
	footer.add_child(later)
	settlement_name_confirm=Button.new()
	settlement_name_confirm.text="NAME SETTLEMENT"
	settlement_name_confirm.custom_minimum_size=Vector2(190,42)
	settlement_name_confirm.disabled=settlement_name_input.text.strip_edges()==""
	settlement_name_confirm.pressed.connect(_commit_settlement_name)
	footer.add_child(settlement_name_confirm)
	settlement_name_input.grab_focus.call_deferred()

func _on_settlement_name_changed(value: String) -> void:
	if settlement_name_confirm:
		settlement_name_confirm.disabled=value.strip_edges()==""

func _on_settlement_name_submitted(_value: String) -> void:
	_commit_settlement_name()

func _commit_settlement_name() -> void:
	if settlement_name_input==null:
		return
	var chosen:=settlement_name_input.text.strip_edges()
	if chosen=="":
		return
	GameState.settlement_name=chosen.substr(0,32)
	var event:={"day":int(GameState.elapsed_days),"title":"Settlement Named","description":"The first settlement is now known as %s." % GameState.settlement_name,"domain":"settlement","severity":"major"}
	GameState.simulation_events.push_front(event)
	if GameState.simulation_events.size()>80: GameState.simulation_events.resize(80)
	if travel_status_label:
		travel_status_label.text="%s HAS BEEN NAMED" % GameState.settlement_name.to_upper()
	_update_time_interface()
	_dismiss_settlement_naming_panel()

func _dismiss_settlement_naming_panel() -> void:
	if settlement_naming_panel:
		settlement_naming_panel.queue_free()
		settlement_naming_panel=null
	settlement_name_input=null
	settlement_name_confirm=null
	_set_game_speed(naming_previous_speed)

func _refresh_discovered_resource_overlays() -> void:
	for deposit in ResourceSystem.visible_deposits():
		var deposit_id: String = deposit.id
		var stage: String = deposit.stage
		var color := Color("#b48b4f")
		if stage == "surveyed":
			color = Color("#8ea3a0")
		elif stage == "accessible" or stage == "developed":
			color = Color("#80a878")
		if not discovered_resource_overlays.has(deposit_id):
			var marker := Node3D.new()
			marker.name = "known_%s" % deposit_id
			marker.set_meta("resource_stage",stage)
			marker.set_meta("resource_name",String(deposit.get("resource","Resource")))
			var deposit_position: Vector3 = deposit.position
			marker.position = Vector3(deposit_position.x, _height_at(deposit_position.x, deposit_position.z) + 0.006, deposit_position.z)
			var ring := MeshInstance3D.new()
			ring.name = "AccessRing"
			var ring_mesh := TorusMesh.new()
			ring_mesh.inner_radius = 0.85
			ring_mesh.outer_radius = 1.04
			ring_mesh.rings = 28
			ring_mesh.ring_segments = 6
			ring.mesh = ring_mesh
			marker.add_child(ring)
			for i in 3:
				var sign := MeshInstance3D.new()
				var sign_mesh := SphereMesh.new()
				sign_mesh.radius = 0.20 + i * 0.04
				sign_mesh.height = 0.36 + i * 0.05
				sign_mesh.radial_segments = 6
				sign_mesh.rings = 3
				sign.mesh = sign_mesh
				sign.position = Vector3(-0.38 + i * 0.36, 0.17 + i * 0.06, (i % 2) * 0.22)
				ring.add_child(sign)
			var material := StandardMaterial3D.new()
			material.albedo_color = color
			material.emission_enabled = true
			material.emission = color.darkened(0.28)
			material.emission_energy_multiplier = 0.48
			material.roughness = 0.86
			ring.material_override = material
			var label:=Label3D.new()
			label.name="ResourceLabel"
			label.text=String(deposit.get("resource","Resource")).to_upper()
			label.font_size=12
			label.outline_size=5
			label.modulate=Color("#ddd2b4")
			label.outline_modulate=Color(0.025,0.034,0.036,0.96)
			label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
			label.fixed_size=true
			label.no_depth_test=true
			label.position=Vector3(0.0,0.78,0.0)
			label.visible=camera!=null and camera.size<=5.5
			marker.add_child(label)
			marker.visible=camera==null or camera.size<=(72.0 if stage in ["accessible","developed"] else 18.0)
			add_child(marker)
			discovered_resource_overlays[deposit_id] = marker
		else:
			var existing: Node3D = discovered_resource_overlays[deposit_id]
			existing.set_meta("resource_stage",stage)
			var existing_ring := existing.get_node_or_null("AccessRing") as MeshInstance3D
			if existing_ring and existing_ring.material_override is StandardMaterial3D:
				var existing_material := existing_ring.material_override as StandardMaterial3D
				existing_material.albedo_color = color
				existing_material.emission = color.darkened(0.28)
	if lens_panel and lens_panel.visible:
		_inspect_location(lens_world_position)

func _build_lens(layer: CanvasLayer) -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	lens_panel = PanelContainer.new()
	lens_panel.position = Vector2(viewport_size.x - 344.0, 108.0)
	lens_panel.size = Vector2(320.0, 342.0)
	lens_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("#101719ee")
	panel_style.border_color = Color("#75694f")
	panel_style.set_border_width_all(1)
	panel_style.corner_radius_top_left = 2
	panel_style.corner_radius_top_right = 2
	panel_style.corner_radius_bottom_left = 2
	panel_style.corner_radius_bottom_right = 2
	panel_style.set_content_margin_all(20)
	lens_panel.add_theme_stylebox_override("panel", panel_style)
	layer.add_child(lens_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	lens_panel.add_child(column)
	var lens_header:=HBoxContainer.new()
	column.add_child(lens_header)
	var title := Label.new()
	title.text = "LENS"
	title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color("#dfd0aa"))
	lens_header.add_child(title)
	var close_lens:=Button.new()
	close_lens.text="×"
	close_lens.tooltip_text="Close the map lens"
	close_lens.custom_minimum_size=Vector2(32,28)
	close_lens.flat=true
	close_lens.pressed.connect(_close_lens)
	lens_header.add_child(close_lens)
	lens_location_label = Label.new()
	lens_location_label.add_theme_font_size_override("font_size", 12)
	lens_location_label.add_theme_color_override("font_color", Color("#938c7a"))
	column.add_child(lens_location_label)
	var rule := HSeparator.new()
	rule.add_theme_color_override("separator", Color("#75694f"))
	column.add_child(rule)
	var found_title := Label.new()
	found_title.text = "RECOGNIZED HERE"
	found_title.add_theme_font_size_override("font_size", 13)
	found_title.add_theme_color_override("font_color", Color("#c5b992"))
	column.add_child(found_title)
	lens_body = RichTextLabel.new()
	lens_body.bbcode_enabled = true
	lens_body.fit_content = false
	lens_body.scroll_active = true
	lens_body.custom_minimum_size = Vector2(0, 220)
	lens_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lens_body.add_theme_font_size_override("normal_font_size", 14)
	lens_body.add_theme_color_override("default_color", Color("#c7c2b4"))
	column.add_child(lens_body)
	lens_panel.visible=false

func _close_lens()->void:
	lens_requested_visible=false
	if lens_panel: lens_panel.visible=false
	if lens_ring: lens_ring.visible=false

func _settlement_plot_at(position:Vector3)->Dictionary:
	if GameState.settlement_plots.is_empty() or "Hearth Circle" not in GameState.settlement_completed: return {}
	var local_point:=Vector2(position.x-GameState.settlement_founded_at.x,position.z-GameState.settlement_founded_at.z)
	var nearest:Dictionary={}
	var nearest_distance:=INF
	for plot in GameState.settlement_plots:
		var polygon:PackedVector2Array=plot.get("polygon",PackedVector2Array())
		if polygon.size()>=3 and Geometry2D.is_point_in_polygon(local_point,polygon): return plot
		var distance:=local_point.distance_to(Vector2(plot.get("centroid",Vector2.ZERO)))
		if distance<nearest_distance:
			nearest_distance=distance
			nearest=plot
	return nearest if nearest_distance<=0.008 else {}

func _settlement_plot_lens_report(plot:Dictionary)->String:
	var use_name:=String(plot.get("land_use","unknown")).replace("_"," ").to_upper()
	var form_name:=String(plot.get("form","unknown form")).replace("_"," ").capitalize()
	var status_name:=String(plot.get("status","unknown")).replace("_"," ").to_upper()
	var status_color:="#8fb08a"
	if status_name in ["DAMAGED","STRESSED","UNDER CONSTRUCTION"]: status_color="#d1a45f"
	elif status_name in ["RUIN","VACANT"]: status_color="#c27f6c"
	var report:="[font_size=18][color=#e1d5b8]%s[/color][/font_size]\n" % use_name
	report+="[color=%s]%s[/color]  •  %s\n" % [status_color,status_name,form_name]
	report+="Condition: [color=#ddd2b8]%d%%[/color]\n" % roundi(float(plot.get("condition",0.0))*100.0)
	var residents:=int(plot.get("resident_count",0))
	var workers:=int(plot.get("worker_count",0))
	if residents>0: report+="Residents: [color=#ddd2b8]%d / %d[/color]\n" % [residents,int(plot.get("resident_capacity",0))]
	if int(plot.get("worker_capacity",0))>0: report+="Workers: [color=#ddd2b8]%d / %d[/color]\n" % [workers,int(plot.get("worker_capacity",0))]
	report+="Materials: [color=#ddd2b8]%s[/color]\n" % String(plot.get("material_family","unknown")).capitalize()
	if String(plot.get("status",""))=="under_construction": report+="Construction: [color=#d1a45f]%d%%[/color]\n" % roundi(float(plot.get("construction_progress",0.0))*100.0)
	if String(plot.get("status",""))=="vacant": report+="Reclaimed by vegetation: [color=#8fb08a]%d%%[/color]\n" % roundi(float(plot.get("reclamation",0.0))*100.0)
	report+="Established: [color=#999b91]YEAR %d • DAY %d[/color]\n" % [int(plot.get("created_day",0))/365+1,int(plot.get("created_day",0))%365+1]
	var cause:=String(plot.get("growth_cause",plot.get("construction_recipe",""))).replace("_"," ")
	if cause!="": report+="\n[color=#c4aa70]Why it exists[/color]\n%s\n" % cause.capitalize()
	return report

func _inspect_location(position: Vector3) -> void:
	if lens_panel == null or lens_body == null:
		return
	lens_requested_visible=true
	lens_panel.visible = true
	lens_world_position = position
	var distance_km := 0.0
	if settler_marker:
		distance_km = Vector2(settler_marker.position.x, settler_marker.position.z).distance_to(Vector2(position.x, position.z)) * KM_PER_WORLD_UNIT
	lens_location_label.text = "CONVOY POSITION" if distance_km < 0.15 else "%.1f KM FROM THE CONVOY" % distance_km
	var entries := ResourceSystem.lens_entries(position, 18.0, KM_PER_WORLD_UNIT)
	var settlement_plot:=_settlement_plot_at(position)
	if entries.is_empty() and settlement_plot.is_empty():
		lens_body.text = "[color=#8f918a][font_size=16]Nothing has been recognized.[/font_size][/color]\n\nThe landscape may contain useful materials, but the population has not produced reliable knowledge of them.\n\n[color=#c4aa70]Assign people to Survey and direct inquiry toward Nature or Materials.[/color]"
	else:
		var report := _settlement_plot_lens_report(settlement_plot) if not settlement_plot.is_empty() else ""
		if not settlement_plot.is_empty() and not entries.is_empty(): report+="\n[color=#75694f]RECOGNIZED RESOURCES NEARBY[/color]\n\n"
		for entry in entries:
			var access_color := "#8fb08a" if entry.retrievable else "#c27f6c"
			var access_title := "RETRIEVABLE" if entry.retrievable else "NOT RETRIEVABLE"
			report += "[font_size=18][color=#e1d5b8]%s[/color][/font_size]\n" % String(entry.resource).to_upper()
			report += "[color=#96988f]%s  •  %.1f KM[/color]\n" % [String(entry.knowledge).to_upper(), float(entry.distance_km)]
			report += "Abundance: [color=#ddd2b8]%s[/color]\n" % String(entry.abundance).capitalize()
			report += "Quality: [color=#ddd2b8]%s[/color]\n" % String(entry.quality).capitalize()
			report += "[color=%s]%s[/color]\n" % [access_color, access_title]
			for blocker in entry.blockers:
				report += "  • %s\n" % String(blocker).capitalize()
			report += "\n"
		lens_body.text = report
	if lens_ring == null:
		lens_ring = MeshInstance3D.new()
		lens_ring.name = "LensSelection"
		var ring_mesh := TorusMesh.new()
		ring_mesh.inner_radius = 3.85
		ring_mesh.outer_radius = 4.08
		ring_mesh.rings = 48
		ring_mesh.ring_segments = 8
		lens_ring.mesh = ring_mesh
		var ring_material := StandardMaterial3D.new()
		ring_material.albedo_color = Color(0.83, 0.73, 0.52, 0.82)
		ring_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		ring_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		ring_material.no_depth_test = true
		lens_ring.material_override = ring_material
		add_child(lens_ring)
	lens_ring.visible=true
	lens_ring.position = Vector3(position.x, _height_at(position.x, position.z) + 0.0035, position.z)

func _open_mandate_panel() -> void:
	if mandate_panel:
		mandate_panel.queue_free()
	mandate_panel=Control.new()
	mandate_panel.size=get_viewport().get_visible_rect().size
	mandate_panel.mouse_filter=Control.MOUSE_FILTER_STOP
	interface_layer.add_child(mandate_panel)
	var dimmer:=ColorRect.new()
	dimmer.size=mandate_panel.size
	dimmer.color=Color(0.008,0.014,0.017,0.88)
	mandate_panel.add_child(dimmer)
	var modal:=PanelContainer.new()
	modal.position=Vector2(48,32)
	modal.size=mandate_panel.size-Vector2(96,64)
	var style:=StyleBoxFlat.new()
	style.bg_color=Color(0.04,0.055,0.06,0.995)
	style.border_color=Color("#76684a")
	style.set_border_width_all(1)
	style.set_content_margin_all(22)
	modal.add_theme_stylebox_override("panel",style)
	mandate_panel.add_child(modal)
	var root:=VBoxContainer.new()
	root.add_theme_constant_override("separation",10)
	modal.add_child(root)
	var heading:=Label.new()
	heading.text="THE FOUNDING MANDATE"
	heading.add_theme_font_size_override("font_size",24)
	heading.add_theme_color_override("font_color",Color("#ecdfc4"))
	root.add_child(heading)
	var source:=Label.new()
	source.text="Campaign variation: %s  •  Numerical effects are bounded by the simulation" % (GameState.campaign_goal_source if GameState.campaign_goal_source!="" else "preparing mandate")
	source.add_theme_font_size_override("font_size",12)
	source.add_theme_color_override("font_color",Color("#96988f"))
	root.add_child(source)
	root.add_child(HSeparator.new())
	var scroll:=ScrollContainer.new()
	scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	var columns:=HBoxContainer.new()
	columns.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation",28)
	scroll.add_child(columns)
	var mandate:=VBoxContainer.new()
	mandate.custom_minimum_size=Vector2(560,0)
	mandate.add_theme_constant_override("separation",9)
	columns.add_child(mandate)
	if GameState.campaign_goal.is_empty():
		var waiting:=Label.new()
		waiting.text="The founding mandate is being composed…"
		waiting.add_theme_font_size_override("font_size",18)
		mandate.add_child(waiting)
	else:
		var goal_title:=Label.new()
		goal_title.text=String(GameState.campaign_goal.get("title","A Civilization Must Be Made")).to_upper()
		goal_title.add_theme_font_size_override("font_size",22)
		goal_title.add_theme_color_override("font_color",Color("#d6bc78"))
		mandate.add_child(goal_title)
		var premise:=Label.new()
		premise.text=String(GameState.campaign_goal.get("premise",""))
		premise.custom_minimum_size=Vector2(540,70)
		premise.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		premise.add_theme_font_size_override("font_size",15)
		mandate.add_child(premise)
		var values:=Label.new()
		values.text="FOUNDING VALUES  •  %s" % "  •  ".join(PackedStringArray(GameState.campaign_goal.get("values",[])))
		values.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		values.add_theme_color_override("font_color",Color("#b8a778"))
		mandate.add_child(values)
		var horizon:=Label.new()
		horizon.text="HORIZON  YEAR %d  •  STATUS  %s" % [roundi(float(GameState.campaign_goal.get("horizon_years",80.0))),GameState.campaign_goal_status.to_upper()]
		horizon.add_theme_font_size_override("font_size",13)
		mandate.add_child(horizon)
		mandate.add_child(HSeparator.new())
		var promise_title:=Label.new()
		promise_title.text="PROMISES THAT DEFINE SUCCESS"
		promise_title.add_theme_font_size_override("font_size",16)
		mandate.add_child(promise_title)
		var progress_entries:=ConsequenceEngine.goal_progress()
		var conditions:Array=GameState.campaign_goal.get("conditions",[])
		for i in conditions.size():
			var condition:Dictionary=conditions[i]
			var progress:Dictionary=progress_entries[i] if i<progress_entries.size() else {}
			var line:=Label.new()
			var reached:="FULFILLED" if bool(progress.get("achieved",false)) else "%s / %s" % [_format_goal_value(String(condition.metric),float(progress.get("current",0.0))),_format_goal_value(String(condition.metric),float(condition.target))]
			line.text="%s\n%s" % [String(condition.get("label",condition.metric)),reached]
			line.add_theme_color_override("font_color",Color("#d2cec3"))
			line.add_theme_font_size_override("font_size",14)
			mandate.add_child(line)
			var bar:=ProgressBar.new()
			bar.custom_minimum_size=Vector2(0,8)
			bar.show_percentage=false
			bar.value=float(progress.get("progress",0.0))*100.0
			mandate.add_child(bar)
		if not GameState.campaign_goal.get("pressures",[]).is_empty():
			mandate.add_child(HSeparator.new())
			var pressure_title:=Label.new()
			pressure_title.text="FOUNDING PRESSURES"
			pressure_title.add_theme_font_size_override("font_size",16)
			mandate.add_child(pressure_title)
			for pressure in GameState.campaign_goal.get("pressures",[]):
				var pressure_line:=Label.new()
				pressure_line.text="• %s" % String(pressure.get("description","An uncertain beginning."))
				pressure_line.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
				mandate.add_child(pressure_line)
		var counsel:=Label.new()
		counsel.text="OPENING COUNSEL\n%s" % String(GameState.campaign_goal.get("opening_counsel",""))
		counsel.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		counsel.add_theme_color_override("font_color",Color("#c8c2b4"))
		mandate.add_child(counsel)
	var state:=VBoxContainer.new()
	state.custom_minimum_size=Vector2(500,0)
	state.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	state.add_theme_constant_override("separation",7)
	columns.add_child(state)
	var state_title:=Label.new()
	state_title.text="RIPPLING STATE"
	state_title.add_theme_font_size_override("font_size",18)
	state.add_child(state_title)
	var metric_rows:=[
		["food_days","PROVISION",120.0],["health","HEALTH",1.0],["labor_efficiency","EFFECTIVE LABOR",1.0],
		["cohesion","COHESION",1.0],["knowledge","KNOWLEDGE",1.0],["material_capacity","MATERIAL CAPACITY",1.0],
		["logistics","LOGISTICS",1.0],["security","SECURITY",1.0],["ecology","ECOLOGY",1.0],["legitimacy","LEGITIMACY",1.0]
	]
	for metric_entry in metric_rows:
		var metric_key:String=metric_entry[0]
		var metric_value:=float(GameState.simulation_metrics.get(metric_key,0.0))
		var metric_line:=Label.new()
		var trend:=float(GameState.simulation_trends.get(metric_key,0.0))
		var arrow:="▲" if trend>0.00005 else ("▼" if trend< -0.00005 else "—")
		metric_line.text="%s   %s   %s" % [metric_entry[1],_format_goal_value(metric_key,metric_value),arrow]
		metric_line.add_theme_font_size_override("font_size",13)
		state.add_child(metric_line)
		var metric_bar:=ProgressBar.new()
		metric_bar.custom_minimum_size=Vector2(0,7)
		metric_bar.show_percentage=false
		metric_bar.value=clampf(metric_value/float(metric_entry[2]),0.0,1.0)*100.0
		state.add_child(metric_bar)
	var active_orders:Array[Dictionary]=[]
	for modifier in GameState.active_modifiers:
		if GameState.elapsed_days<=float(modifier.get("until_day",INF)): active_orders.append(modifier)
	if not active_orders.is_empty():
		state.add_child(HSeparator.new())
		var orders_title:=Label.new()
		orders_title.text="ACTIVE PRESSURES & ORDERS"
		orders_title.add_theme_font_size_override("font_size",16)
		state.add_child(orders_title)
		for modifier in active_orders:
			var order_line:=Label.new()
			var days_remaining:=maxf(0.0,float(modifier.get("until_day",GameState.elapsed_days))-GameState.elapsed_days)
			order_line.text="%s  •  %.0f days remain" % [String(modifier.get("description",String(modifier.get("id","pressure")).replace("_"," ").capitalize())),days_remaining]
			order_line.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
			order_line.add_theme_font_size_override("font_size",12)
			order_line.add_theme_color_override("font_color",Color("#b5aa8d"))
			state.add_child(order_line)
	state.add_child(HSeparator.new())
	var events_title:=Label.new()
	events_title.text="RECENT CONSEQUENCES"
	events_title.add_theme_font_size_override("font_size",16)
	state.add_child(events_title)
	if GameState.simulation_events.is_empty():
		var quiet:=Label.new()
		quiet.text="No major consequence has yet crossed the council's threshold."
		quiet.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		quiet.add_theme_color_override("font_color",Color("#96988f"))
		state.add_child(quiet)
	else:
		for i in mini(6,GameState.simulation_events.size()):
			var event:Dictionary=GameState.simulation_events[i]
			var event_line:=Label.new()
			event_line.text="DAY %d  •  %s\n%s" % [int(event.day)+1,String(event.title).to_upper(),String(event.description)]
			event_line.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
			event_line.add_theme_font_size_override("font_size",13)
			state.add_child(event_line)
	var footer:=HBoxContainer.new()
	footer.alignment=BoxContainer.ALIGNMENT_END
	root.add_child(footer)
	var close:=Button.new()
	close.text="CLOSE"
	close.custom_minimum_size=Vector2(130,42)
	close.pressed.connect(func(): mandate_panel.queue_free(); mandate_panel=null)
	footer.add_child(close)
	var begin:=Button.new()
	begin.text="BEGIN  •  1×"
	begin.custom_minimum_size=Vector2(190,42)
	begin.tooltip_text="Close the mandate and start the calendar at normal speed."
	begin.pressed.connect(func(): _set_game_speed(1.0); mandate_panel.queue_free(); mandate_panel=null)
	footer.add_child(begin)

func _format_goal_value(metric: String,value: float) -> String:
	if metric in ["population","discoveries","resource_access","completed_works"]: return "%d" % roundi(value)
	if metric=="food_days": return "%.0f days" % value
	return "%d%%" % roundi(value*100.0)

func _open_provisions_panel() -> void:
	if provisions_panel:
		provisions_panel.queue_free()
	provisions_panel=Control.new()
	provisions_panel.size=get_viewport().get_visible_rect().size
	provisions_panel.mouse_filter=Control.MOUSE_FILTER_STOP
	interface_layer.add_child(provisions_panel)
	var dimmer:=ColorRect.new()
	dimmer.size=provisions_panel.size
	dimmer.color=Color(0.006,0.011,0.012,0.91)
	provisions_panel.add_child(dimmer)
	var modal:=PanelContainer.new()
	modal.position=Vector2(24,20)
	modal.size=provisions_panel.size-Vector2(48,40)
	var frame:=StyleBoxFlat.new()
	frame.bg_color=Color("#0a1213")
	frame.border_color=Color("#7f7452")
	frame.set_border_width_all(1)
	frame.set_content_margin_all(18)
	modal.add_theme_stylebox_override("panel",frame)
	provisions_panel.add_child(modal)
	var root:=VBoxContainer.new()
	root.add_theme_constant_override("separation",8)
	modal.add_child(root)
	var header:=HBoxContainer.new()
	header.custom_minimum_size=Vector2(0,68)
	header.add_theme_constant_override("separation",10)
	root.add_child(header)
	var title_box:=VBoxContainer.new()
	title_box.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	header.add_child(title_box)
	var eyebrow:=Label.new()
	eyebrow.text="SURVIVAL, STORAGE & THE LAND"
	eyebrow.add_theme_font_size_override("font_size",11)
	eyebrow.add_theme_color_override("font_color",Color("#b9a66c"))
	title_box.add_child(eyebrow)
	var title:=Label.new()
	title.text="PROVISIONS"
	title.add_theme_font_size_override("font_size",27)
	title.add_theme_color_override("font_color",Color("#f0e4cd"))
	title_box.add_child(title)
	var subtitle:=Label.new()
	subtitle.text="What was found, what was lost, who needs it, and how long the stores will truly last."
	subtitle.add_theme_font_size_override("font_size",12)
	subtitle.add_theme_color_override("font_color",Color("#9ca39d"))
	title_box.add_child(subtitle)
	var metrics:=GameState.simulation_metrics
	var produced:=float(metrics.get("food_production",0.0))
	var required:=float(metrics.get("food_consumption",maxf(1.0,GameState.population_exact)))
	var eaten:=float(metrics.get("food_eaten",required))
	var spoiled:=float(metrics.get("food_spoilage",0.0))
	var net:=float(metrics.get("food_net",produced-eaten-spoiled))
	var days:=float(metrics.get("food_days",0.0))
	var projected:=float(metrics.get("food_projected_days",days))
	var forecast_30:Dictionary=metrics.get("food_forecast_30",{})
	var forecast_90:Dictionary=metrics.get("food_forecast_90",{})
	var shortage_90:=int(forecast_90.get("first_shortage_day",-1))
	var outlook_text:="shortage %dd" % shortage_90 if shortage_90>0 else ("30d %.0f • 90d %.0f" % [float(forecast_30.get("ending_days",days)),float(forecast_90.get("ending_days",days))] if not forecast_90.is_empty() else ("stable" if projected>=999.0 else "%.0f days" % projected))
	_make_provision_stat(header,"STORES","%.1f days" % days,Color("#d0b46f"))
	_make_provision_stat(header,"TODAY'S NET","%+.1f rations" % net,Color("#78a77d") if net>=0.0 else Color("#c67462"))
	_make_provision_stat(header,"INTAKE","%d%%" % roundi(float(metrics.get("food_intake_ratio",1.0))*100.0),Color("#83a6a0"))
	_make_provision_stat(header,"SEASONAL OUTLOOK",outlook_text,Color("#c67661") if shortage_90>0 else Color("#b99369"))
	root.add_child(HSeparator.new())
	var scroll:=ScrollContainer.new()
	scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	var columns:=HBoxContainer.new()
	columns.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation",12)
	scroll.add_child(columns)
	var stores:=VBoxContainer.new()
	stores.custom_minimum_size=Vector2(350,0)
	stores.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	stores.add_theme_constant_override("separation",7)
	columns.add_child(stores)
	_add_provision_section_title(stores,"STORES BY KIND","Each stock has its own shelf life; perishables are eaten first.")
	var stock_data:Dictionary=metrics.get("food_stocks",GameState.food_stocks)
	var spoilage_data:Dictionary=metrics.get("food_spoilage_by_type",{})
	var stored_total:=maxf(0.01,float(GameState.resource_stockpiles.get("Food",0.0)))
	for food_type in FoodSystemScript.FOOD_TYPES:
		var amount:=float(stock_data.get(food_type,0.0))
		var daily_loss:=float(spoilage_data.get(food_type,0.0))
		var note:="%.0f rations  •  %.1f days  •  %.1f lost today" % [amount,amount/maxf(0.01,required),daily_loss]
		_add_provision_bar(stores,String(food_type).to_upper(),note,amount/stored_total,_food_color(String(food_type)))
	stores.add_child(HSeparator.new())
	_add_provision_section_title(stores,"30-DAY MOVEMENT","Daily net after consumption and spoilage.")
	_add_food_trend_chart(stores)
	var sources:=VBoxContainer.new()
	sources.custom_minimum_size=Vector2(350,0)
	sources.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	sources.add_theme_constant_override("separation",7)
	columns.add_child(sources)
	_add_provision_section_title(sources,"TODAY'S SUPPLY","Food appears only through actual methods and accessible resources.")
	var source_entries:Array=metrics.get("food_sources",[])
	if source_entries.is_empty():
		var empty_sources:=Label.new()
		empty_sources.text="The first daily provision report will appear when the clock advances."
		empty_sources.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		empty_sources.add_theme_color_override("font_color",Color("#929992"))
		sources.add_child(empty_sources)
	for source_variant in source_entries:
		var source:Dictionary=source_variant
		var output:=float(source.get("produced",0.0))
		var access:=String(source.get("access","unknown"))
		var health:=float(source.get("source_health",0.0))
		var status_color:=Color("#88a97d") if access=="retrievable" or access=="available" else Color("#aa7468")
		_add_provision_bar(sources,String(source.get("name","Source")).to_upper(),"%.1f rations  •  %s  •  source health %d%%" % [output,access,roundi(health*100.0)],output/maxf(1.0,produced),status_color)
	sources.add_child(HSeparator.new())
	_add_provision_section_title(sources,"WHY SUPPLY CHANGES","Production is not a flat worker multiplier.")
	var explanation:=Label.new()
	explanation.text="Season and terrain shape gathering. Game and fresh water must be discovered and made retrievable. Work health, ecological depletion, travel, logistics, practices, and daily variation change the yield. Cultivation remains unavailable until it is learned and the convoy settles."
	explanation.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	explanation.add_theme_font_size_override("font_size",12)
	explanation.add_theme_color_override("font_color",Color("#b6b8ad"))
	sources.add_child(explanation)
	var balance:=VBoxContainer.new()
	balance.custom_minimum_size=Vector2(350,0)
	balance.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	balance.add_theme_constant_override("separation",7)
	columns.add_child(balance)
	_add_provision_section_title(balance,"TODAY'S BALANCE","Adult-equivalent ration = approximately 2,400 kcal.")
	_add_provision_bar(balance,"PRODUCED","%.1f rations  •  %s kcal" % [produced,_compact_food_number(produced*FoodSystemScript.KCAL_PER_RATION)],produced/maxf(required,produced),Color("#729b6e"))
	_add_provision_bar(balance,"REQUIRED","%.1f rations  •  %s kcal" % [required,_compact_food_number(required*FoodSystemScript.KCAL_PER_RATION)],required/maxf(required,produced),Color("#b99f64"))
	_add_provision_bar(balance,"EATEN","%.1f rations" % eaten,eaten/maxf(0.01,required),Color("#779ca0"))
	_add_provision_bar(balance,"SPOILED","%.1f rations" % spoiled,spoiled/maxf(1.0,required),Color("#a56e5f"))
	balance.add_child(HSeparator.new())
	_add_provision_section_title(balance,"WHO NEEDS IT","Demand comes from the named population, not a head-count shortcut.")
	var demand:Dictionary=metrics.get("food_demand_breakdown",{})
	for demand_entry in [["Base metabolism & growth","base"],["Physical work","labor"],["Pregnancy","pregnancy"],["Lactation","lactation"],["Travel","travel"],["Cold season","climate"]]:
		var demand_amount:=float(demand.get(demand_entry[1],0.0))
		var demand_line:=Label.new()
		demand_line.text="%-28s  %5.1f" % [demand_entry[0],demand_amount]
		demand_line.add_theme_font_size_override("font_size",12)
		demand_line.add_theme_color_override("font_color",Color("#c7c3b6") if demand_amount>0.0 else Color("#696f6b"))
		balance.add_child(demand_line)
	var rationing:=float(demand.get("rationing",0.0))
	if rationing>0.0:
		var ration_line:=Label.new()
		ration_line.text="Rationing withheld  %.1f" % rationing
		ration_line.add_theme_color_override("font_color",Color("#c47662"))
		balance.add_child(ration_line)
	balance.add_child(HSeparator.new())
	_add_provision_section_title(balance,"NUTRITIONAL CONDITION","Shortage now depletes reserves before it becomes mass mortality.")
	_add_provision_bar(balance,"DIET QUALITY","%d%%" % roundi(float(metrics.get("food_diet_quality",0.0))*100.0),float(metrics.get("food_diet_quality",0.0)),Color("#879d72"))
	_add_provision_bar(balance,"BODY RESERVES","%d%%" % roundi(GameState.nutrition_reserve*100.0),GameState.nutrition_reserve,Color("#aa9165"))
	_add_provision_bar(balance,"MALNUTRITION","%d%% burden" % roundi(GameState.malnutrition_burden*100.0),GameState.malnutrition_burden,Color("#b76458"))
	var footer:=HBoxContainer.new()
	footer.alignment=BoxContainer.ALIGNMENT_END
	root.add_child(footer)
	var close:=Button.new()
	close.text="CLOSE"
	close.custom_minimum_size=Vector2(150,40)
	close.pressed.connect(func(): provisions_panel.queue_free(); provisions_panel=null)
	footer.add_child(close)

func _open_materials_panel() -> void:
	if materials_panel: materials_panel.queue_free()
	materials_panel=Control.new()
	materials_panel.size=get_viewport().get_visible_rect().size
	materials_panel.mouse_filter=Control.MOUSE_FILTER_STOP
	interface_layer.add_child(materials_panel)
	var dimmer:=ColorRect.new()
	dimmer.size=materials_panel.size
	dimmer.color=Color(0.006,0.009,0.010,0.92)
	materials_panel.add_child(dimmer)
	var modal:=PanelContainer.new()
	modal.position=Vector2(24,20)
	modal.size=materials_panel.size-Vector2(48,40)
	modal.add_theme_stylebox_override("panel",_knowledge_style(Color("#0b1112"),Color("#806c4c"),1,3,18))
	materials_panel.add_child(modal)
	var root:=VBoxContainer.new()
	root.add_theme_constant_override("separation",8)
	modal.add_child(root)
	var header:=HBoxContainer.new()
	header.custom_minimum_size=Vector2(0,70)
	header.add_theme_constant_override("separation",9)
	root.add_child(header)
	var heading:=VBoxContainer.new()
	heading.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	header.add_child(heading)
	var eyebrow:=Label.new()
	eyebrow.text="KNOWLEDGE, LABOR & PHYSICAL FLOW"
	eyebrow.add_theme_font_size_override("font_size",10)
	eyebrow.add_theme_color_override("font_color",Color("#baa164"))
	heading.add_child(eyebrow)
	var title:=Label.new()
	title.text="MATERIALS & ACCESS"
	title.add_theme_font_size_override("font_size",26)
	title.add_theme_color_override("font_color",Color("#eee1c9"))
	heading.add_child(title)
	var subtitle:=Label.new()
	subtitle.text="A deposit is not a stockpile. It must be recognized, understood, reached, worked, carried, and kept."
	subtitle.add_theme_font_size_override("font_size",12)
	subtitle.add_theme_color_override("font_color",Color("#9ca29d"))
	heading.add_child(subtitle)
	var metrics:=GameState.material_metrics
	_make_provision_stat(header,"EXTRACTED","%.1f today" % float(metrics.get("extracted_today",0.0)),Color("#b68d56"))
	_make_provision_stat(header,"DELIVERED","%.1f today" % float(metrics.get("delivered_today",0.0)),Color("#78977f"))
	_make_provision_stat(header,"IN TRANSIT","%.1f units" % float(metrics.get("in_transit",0.0)),Color("#718d99"))
	var live_capacity:=float(metrics.get("storage_capacity",0.0))
	if live_capacity<=0.0:
		for capacity in ResourceSystem.storage_capacities().values(): live_capacity+=float(capacity)
	var live_stored:=ResourceSystem.stored_bulk()
	_make_provision_stat(header,"STORAGE","%.0f / %.0f bulk" % [live_stored,live_capacity],Color("#a58b67"))
	root.add_child(HSeparator.new())
	var scroll:=ScrollContainer.new()
	scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	var columns:=HBoxContainer.new()
	columns.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation",12)
	scroll.add_child(columns)
	var deposits_column:=VBoxContainer.new()
	deposits_column.custom_minimum_size=Vector2(390,0)
	deposits_column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	deposits_column.add_theme_constant_override("separation",7)
	columns.add_child(deposits_column)
	_add_provision_section_title(deposits_column,"KNOWN OCCURRENCES","Confidence and access grow through observation and repeated work.")
	var visible:=ResourceSystem.visible_deposits()
	if visible.is_empty():
		_make_knowledge_empty_state(deposits_column,"Nothing has been recognized yet. Surveyors, local work, and directed inquiry create evidence; the map will not reveal what the people do not know.")
	for deposit_variant in visible:
		var deposit:Dictionary=deposit_variant
		var card:=PanelContainer.new()
		card.add_theme_stylebox_override("panel",_knowledge_style(Color("#12191a"),_material_stage_color(String(deposit.stage)).darkened(0.32),1,3,9))
		deposits_column.add_child(card)
		var content:=VBoxContainer.new()
		content.add_theme_constant_override("separation",3)
		card.add_child(content)
		var top:=HBoxContainer.new()
		content.add_child(top)
		var name:=Label.new()
		name.text=String(deposit.resource).to_upper()
		name.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		name.add_theme_font_size_override("font_size",14)
		name.add_theme_color_override("font_color",Color("#e7dcc8"))
		top.add_child(name)
		var stage:=Label.new()
		stage.text=String(deposit.stage).to_upper()
		stage.add_theme_font_size_override("font_size",10)
		stage.add_theme_color_override("font_color",_material_stage_color(String(deposit.stage)))
		top.add_child(stage)
		var knowledge:=Label.new()
		knowledge.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		knowledge.add_theme_font_size_override("font_size",11)
		knowledge.add_theme_color_override("font_color",Color("#a8afa8"))
		knowledge.text=_material_knowledge_text(deposit)
		content.add_child(knowledge)
		if String(deposit.stage) in ["accessible","developed"] and ResourceSystem.material_profile(String(deposit.resource)).size()>0 and String(deposit.resource) not in ["Freshwater","Fertile Soil","Game","Medicinal Plants"]:
			var flow:=Label.new()
			flow.text="%.1f km  •  %d workers  •  %.1f extracted  •  %.1f awaiting carriers  •  %.1f moving" % [float(deposit.get("distance_km",0.0)),int(deposit.get("workers",0)),float(deposit.get("extracted_today",0.0)),float(deposit.get("stock_at_source",0.0)),ResourceSystem.in_transit_for(deposit)]
			flow.add_theme_font_size_override("font_size",10)
			flow.add_theme_color_override("font_color",Color("#8fa39f"))
			content.add_child(flow)
			var bottom:=HBoxContainer.new()
			content.add_child(bottom)
			var bottleneck:=Label.new()
			bottleneck.text="STATUS  •  %s" % String(deposit.get("bottleneck","Awaiting first work"))
			bottleneck.size_flags_horizontal=Control.SIZE_EXPAND_FILL
			bottleneck.add_theme_font_size_override("font_size",9)
			bottleneck.add_theme_color_override("font_color",Color("#c18469") if String(deposit.get("bottleneck",""))!="Flowing" else Color("#7fa27c"))
			bottom.add_child(bottleneck)
			var priority:=Button.new()
			var priority_value:=float(GameState.resource_priorities.get(String(deposit.resource),1.0))
			priority.text="%s PRIORITY" % ("LOW" if priority_value<0.8 else ("HIGH" if priority_value>1.2 else "NORMAL"))
			priority.custom_minimum_size=Vector2(112,25)
			priority.tooltip_text="Changes where extractors and carriers concentrate. It does not create labor or material."
			priority.pressed.connect(_cycle_material_priority.bind(String(deposit.resource)))
			bottom.add_child(priority)
	var flow_column:=VBoxContainer.new()
	flow_column.custom_minimum_size=Vector2(330,0)
	flow_column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	flow_column.add_theme_constant_override("separation",7)
	columns.add_child(flow_column)
	_add_provision_section_title(flow_column,"TODAY'S MATERIAL CHAIN","Every break in the chain leaves a visible backlog.")
	var extracted:=float(metrics.get("extracted_today",0.0))
	var at_source:=float(metrics.get("at_source",0.0))
	var moving:=float(metrics.get("in_transit",0.0))
	var delivered:=float(metrics.get("delivered_today",0.0))
	var lost:=float(metrics.get("lost_today",0.0))
	var scale:=maxf(1.0,maxf(extracted,maxf(at_source,maxf(moving,delivered))))
	_add_provision_bar(flow_column,"1  EXTRACTED","%.1f units today" % extracted,extracted/scale,Color("#b88d55"))
	_add_provision_bar(flow_column,"2  AT SOURCE","%.1f waiting for carriers" % at_source,at_source/scale,Color("#b86f59"))
	_add_provision_bar(flow_column,"3  IN TRANSIT","%.1f physically moving" % moving,moving/scale,Color("#6f919e"))
	_add_provision_bar(flow_column,"4  DELIVERED","%.1f reached stores today" % delivered,delivered/scale,Color("#719a78"))
	_add_provision_bar(flow_column,"5  LOST","%.1f exposure / damage / overflow" % lost,lost/scale,Color("#a75e52"))
	flow_column.add_child(HSeparator.new())
	_add_provision_section_title(flow_column,"PEOPLE BEHIND THE FLOW","Automatic allocation divides them by priority, scarcity, quality, and distance.")
	_add_provision_bar(flow_column,"EXTRACTORS","%d people" % int(GameState.population_allocations.get("Extraction",0)),float(GameState.population_allocations.get("Extraction",0))/maxf(1.0,GameState.population_exact),Color("#b18a5d"))
	_add_provision_bar(flow_column,"CARRIERS","%d people" % int(GameState.population_allocations.get("Logistics",0)),float(GameState.population_allocations.get("Logistics",0))/maxf(1.0,GameState.population_exact),Color("#718f94"))
	var doctrine:=Label.new()
	doctrine.text="Practical knowledge compounds: experienced workers recognize related materials faster, lose less usable material, and teach later generations. New practices can improve food preservation, health, building, trade, administration, or war—but some also bring pollution and danger."
	doctrine.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	doctrine.add_theme_font_size_override("font_size",11)
	doctrine.add_theme_color_override("font_color",Color("#adb1a8"))
	flow_column.add_child(doctrine)
	var stores_column:=VBoxContainer.new()
	stores_column.custom_minimum_size=Vector2(340,0)
	stores_column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	stores_column.add_theme_constant_override("separation",7)
	columns.add_child(stores_column)
	_add_provision_section_title(stores_column,"SETTLEMENT STORES","Different materials need different physical storage.")
	var capacities:Dictionary=metrics.get("capacities",ResourceSystem.storage_capacities())
	var used_by_store:={"yard":0.0,"dry":0.0,"covered":0.0,"sealed":0.0,"secure":0.0}
	for resource_name_variant in GameState.resource_stockpiles:
		var resource_name:=String(resource_name_variant)
		if resource_name=="Food" or resource_name in ["Freshwater","Fertile Soil","Game","Medicinal Plants"]: continue
		var amount:=float(GameState.resource_stockpiles[resource_name])
		if amount<=0.005: continue
		var profile:=ResourceSystem.material_profile(resource_name)
		var store:=String(profile.store)
		used_by_store[store]=float(used_by_store[store])+amount*float(profile.bulk)
		var line:=Label.new()
		line.text="%s  •  %.1f units  •  %s" % [resource_name.to_upper(),amount,store.replace("_"," ")]
		line.add_theme_font_size_override("font_size",11)
		line.add_theme_color_override("font_color",Color("#c8c1b1"))
		stores_column.add_child(line)
	for store_name in capacities:
		_add_provision_bar(stores_column,String(store_name).replace("_"," ").to_upper(),"%.0f / %.0f bulk used" % [float(used_by_store.get(store_name,0.0)),float(capacities[store_name])],float(used_by_store.get(store_name,0.0))/maxf(1.0,float(capacities[store_name])),Color("#9a825e"))
	stores_column.add_child(HSeparator.new())
	_add_provision_section_title(stores_column,"RECENT MATERIAL INSIGHT","Only discoveries that survived testing enter the record.")
	var shown:=0
	for event_variant in GameState.discovery_log:
		var event:Dictionary=event_variant
		var effects:Dictionary=event.get("effects",{})
		if effects.is_empty(): continue
		var insight:=Label.new()
		insight.text="%s\n%s" % [String(event.get("name","Discovery")).to_upper(),_effect_ripple_text(effects)]
		insight.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		insight.add_theme_font_size_override("font_size",10)
		insight.add_theme_color_override("font_color",Color("#bca873"))
		stores_column.add_child(insight)
		shown+=1
		if shown>=4: break
	if shown==0: _make_knowledge_empty_state(stores_column,"No material practice has yet become dependable collective knowledge.")
	var footer:=HBoxContainer.new()
	root.add_child(footer)
	var note:=Label.new()
	note.text="The hidden possibility graph remains invisible. This ledger shows only what your civilization currently knows, attempts, moves, and loses."
	note.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	note.add_theme_font_size_override("font_size",10)
	note.add_theme_color_override("font_color",Color("#888f89"))
	footer.add_child(note)
	var close:=Button.new()
	close.text="CLOSE"
	close.custom_minimum_size=Vector2(150,38)
	close.pressed.connect(func(): materials_panel.queue_free(); materials_panel=null)
	footer.add_child(close)

func _material_stage_color(stage:String)->Color:
	return {"recognized":Color("#9a835b"),"surveyed":Color("#7c9291"),"accessible":Color("#789a78"),"developed":Color("#c2a15e")}.get(stage,Color("#777d79"))

func _material_knowledge_text(deposit:Dictionary)->String:
	match String(deposit.get("stage","unknown")):
		"recognized": return "INDICATED  •  identity plausible; quality, extent, and retrieval remain unknown"
		"surveyed": return "%s quality  •  %s  •  access work and practical knowledge still determine retrieval" % [ResourceSystem._quality_label(float(deposit.get("quality",0.0))),ResourceSystem._abundance_label(deposit)]
		"accessible": return "%s quality  •  retrievable, but no dependable production history yet" % ResourceSystem._quality_label(float(deposit.get("quality",0.0)))
		"developed": return "%s quality  •  repeated work is accumulating practical knowledge" % ResourceSystem._quality_label(float(deposit.get("quality",0.0)))
	return "Unknown"

func _cycle_material_priority(resource_name:String)->void:
	var current:=float(GameState.resource_priorities.get(resource_name,1.0))
	GameState.resource_priorities[resource_name]=1.0 if current>1.2 else (2.0 if current>=0.8 else 1.0)
	if current>=0.8 and current<=1.2: GameState.resource_priorities[resource_name]=2.0
	elif current>1.2: GameState.resource_priorities[resource_name]=0.5
	else: GameState.resource_priorities[resource_name]=1.0
	_open_materials_panel.call_deferred()

func _effect_ripple_text(effects:Dictionary)->String:
	var names={"tool_quality":"tool quality","construction_rate":"construction","food_output":"food output","foraging_yield":"foraging","hunting_yield":"hunting","cultivation_yield":"cultivation","food_spoilage":"spoilage","food_storage":"food stores","nutrition_quality":"diet quality","soil_productivity":"soil fertility","health_protection":"health","water_safety":"water safety","disease_exposure":"disease exposure","maternal_safety":"maternal safety","neonatal_survival":"newborn survival","conception_support":"birth conditions","injury_risk":"injury risk","labor_efficiency":"labor efficiency","labor_demand":"labor burden","task_coordination":"coordination","haul_capacity":"carrying","route_speed":"travel","trade_capacity":"trade","state_capacity":"governance","legitimacy":"legitimacy","cohesion":"cohesion","warfare_readiness":"military power","security_efficiency":"security","knowledge_rate":"discovery","knowledge_preservation":"memory","observation_rate":"observation","adoption_rate":"spread of practice","ecology_recovery":"land recovery","ecological_pressure":"land pressure","pollution":"pollution","disaster_risk":"accident risk","mine_safety":"mine safety","craft_output":"workshops","housing_output":"housing","repair_capacity":"repair","standardization":"standards","fuel_efficiency":"fuel efficiency","metal_yield":"metal output","timber_yield":"timber output","stone_yield":"stone output"}
	var ripples:Array[String]=[]
	for effect_name in effects:
		if not names.has(effect_name): continue
		var amount:=float(effects[effect_name])
		var harmful:bool=effect_name in ["pollution","disaster_risk","disease_exposure","injury_risk","labor_demand","ecological_pressure","health_risk","fatigue","institutional_rigidity","food_spoilage"]
		var favorable:bool=(amount<0.0) if harmful else (amount>0.0)
		ripples.append("%s %s %d%%" % ["▲" if favorable else "▼",String(names[effect_name]),roundi(absf(amount)*100.0)])
		if ripples.size()>=4: break
	return "  •  ".join(ripples) if not ripples.is_empty() else "Practical consequences are still being measured"

func _make_provision_stat(parent: Container,label_text: String,value_text: String,accent: Color) -> void:
	var card:=PanelContainer.new()
	card.custom_minimum_size=Vector2(128,56)
	var style:=StyleBoxFlat.new()
	style.bg_color=Color("#101a1b")
	style.border_color=accent.darkened(0.24)
	style.border_width_bottom=2
	style.set_content_margin_all(8)
	card.add_theme_stylebox_override("panel",style)
	parent.add_child(card)
	var stack:=VBoxContainer.new()
	card.add_child(stack)
	var label:=Label.new()
	label.text=label_text
	label.add_theme_font_size_override("font_size",10)
	label.add_theme_color_override("font_color",Color("#89928d"))
	stack.add_child(label)
	var value:=Label.new()
	value.text=value_text
	value.add_theme_font_size_override("font_size",16)
	value.add_theme_color_override("font_color",accent)
	stack.add_child(value)

func _add_provision_section_title(parent: Container,title_text: String,note_text: String) -> void:
	var title:=Label.new()
	title.text=title_text
	title.add_theme_font_size_override("font_size",15)
	title.add_theme_color_override("font_color",Color("#e3d7bd"))
	parent.add_child(title)
	var note:=Label.new()
	note.text=note_text
	note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_font_size_override("font_size",11)
	note.add_theme_color_override("font_color",Color("#8f9691"))
	parent.add_child(note)

func _add_provision_bar(parent: Container,title_text: String,note_text: String,ratio: float,color: Color) -> void:
	var row:=VBoxContainer.new()
	row.add_theme_constant_override("separation",2)
	parent.add_child(row)
	var line:=Label.new()
	line.text="%s\n%s" % [title_text,note_text]
	line.add_theme_font_size_override("font_size",11)
	line.add_theme_color_override("font_color",Color("#d3cdbf"))
	row.add_child(line)
	var bar:=ProgressBar.new()
	bar.custom_minimum_size=Vector2(0,7)
	bar.show_percentage=false
	bar.value=clampf(ratio,0.0,1.0)*100.0
	var background:=StyleBoxFlat.new()
	background.bg_color=Color("#1b2525")
	bar.add_theme_stylebox_override("background",background)
	var fill:=StyleBoxFlat.new()
	fill.bg_color=color
	bar.add_theme_stylebox_override("fill",fill)
	row.add_child(bar)

func _add_food_trend_chart(parent: Container) -> void:
	var chart:=Control.new()
	chart.custom_minimum_size=Vector2(0,88)
	parent.add_child(chart)
	var history:Array=GameState.food_history
	if history.size()<2:
		var waiting:=Label.new()
		waiting.text="Advance the clock to build a daily history."
		waiting.position=Vector2(0,24)
		waiting.add_theme_color_override("font_color",Color("#777f7a"))
		chart.add_child(waiting)
		return
	var count:=mini(30,history.size())
	var values:Array[float]=[]
	var max_abs:=1.0
	for index in range(history.size()-count,history.size()):
		var value:=float((history[index] as Dictionary).get("net",0.0))
		values.append(value)
		max_abs=maxf(max_abs,absf(value))
	var zero:=ColorRect.new()
	zero.position=Vector2(0,43)
	zero.size=Vector2(330,1)
	zero.color=Color("#4c5550")
	chart.add_child(zero)
	var line:=Line2D.new()
	line.width=2.0
	line.default_color=Color("#a9bc7b") if values[values.size()-1]>=0.0 else Color("#bd6d5d")
	for i in values.size():
		line.add_point(Vector2(float(i)/maxf(1.0,float(values.size()-1))*330.0,43.0-values[i]/max_abs*35.0))
	chart.add_child(line)

func _food_color(food_type: String) -> Color:
	return {
		"Fresh plants":Color("#7f9e67"),"Fresh meat":Color("#a75f54"),"Fish":Color("#648b98"),
		"Dry staples":Color("#b79958"),"Preserved food":Color("#8f7661")
	}.get(food_type,Color("#888888"))

func _compact_food_number(value: float) -> String:
	if value>=1000000.0: return "%.2f M" % (value/1000000.0)
	if value>=1000.0: return "%.1f K" % (value/1000.0)
	return "%.0f" % value

func _open_knowledge_panel() -> void:
	if knowledge_panel:
		knowledge_panel.queue_free()
	allocation_value_labels.clear()
	knowledge_panel = Control.new()
	knowledge_panel.size = get_viewport().get_visible_rect().size
	knowledge_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	interface_layer.add_child(knowledge_panel)
	var dimmer := ColorRect.new()
	dimmer.size = knowledge_panel.size
	dimmer.color = Color(0.008,0.012,0.014,0.90)
	knowledge_panel.add_child(dimmer)
	var modal := PanelContainer.new()
	modal.position = Vector2(24,20)
	modal.size = knowledge_panel.size-Vector2(48,40)
	modal.add_theme_stylebox_override("panel",_knowledge_style(Color("#0b1215"),Color("#817353"),1,3,18))
	knowledge_panel.add_child(modal)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation",8)
	modal.add_child(root)
	var header:=HBoxContainer.new()
	header.custom_minimum_size=Vector2(0,72)
	header.add_theme_constant_override("separation",18)
	root.add_child(header)
	var heading:=VBoxContainer.new()
	heading.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	heading.add_theme_constant_override("separation",3)
	header.add_child(heading)
	var eyebrow:=Label.new()
	eyebrow.text="THE COLLECTIVE MIND"
	eyebrow.add_theme_font_size_override("font_size",11)
	eyebrow.add_theme_color_override("font_color",Color("#b9a56c"))
	heading.add_child(eyebrow)
	var title := Label.new()
	title.text = "KNOWLEDGE & INQUIRY"
	title.add_theme_font_size_override("font_size",26)
	title.add_theme_color_override("font_color",Color("#f0e5cf"))
	heading.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "Shape attention, not answers. Discovery remains uncertain, situated, and organic."
	subtitle.add_theme_font_size_override("font_size",13)
	subtitle.add_theme_color_override("font_color",Color("#9fa7a2"))
	heading.add_child(subtitle)
	var header_stats:=HBoxContainer.new()
	header_stats.alignment=BoxContainer.ALIGNMENT_END
	header_stats.add_theme_constant_override("separation",8)
	header.add_child(header_stats)
	var assigned:=_research_allocation_total()
	var observers:=int(GameState.population_allocations.get("Knowledge",0))
	_make_knowledge_stat(header_stats,"OBSERVERS",str(observers),Color("#78a9b2"))
	_make_knowledge_stat(header_stats,"COMMITTED",str(assigned),Color("#c8a862"))
	_make_knowledge_stat(header_stats,"ESTABLISHED",str(GameState.discovery_log.size()),Color("#7fa47c"))
	_make_knowledge_stat(header_stats,"COMBINED MIND","%d%%" % roundi(GameState.combined_intelligence*100.0),Color("#9a82b8"))
	root.add_child(HSeparator.new())
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation",14)
	root.add_child(body)
	var directions_frame:=PanelContainer.new()
	directions_frame.custom_minimum_size=Vector2(590,0)
	directions_frame.add_theme_stylebox_override("panel",_knowledge_style(Color("#0e171a"),Color("#283539"),1,3,14))
	body.add_child(directions_frame)
	var directions_column:=VBoxContainer.new()
	directions_column.add_theme_constant_override("separation",7)
	directions_frame.add_child(directions_column)
	var directions_title:=Label.new()
	directions_title.text="DIRECT THE SEARCH"
	directions_title.add_theme_font_size_override("font_size",17)
	directions_title.add_theme_color_override("font_color",Color("#e4dbc8"))
	directions_column.add_child(directions_title)
	research_total_label = Label.new()
	research_total_label.add_theme_font_size_override("font_size",12)
	research_total_label.add_theme_color_override("font_color",Color("#96a9ad"))
	directions_column.add_child(research_total_label)
	var attention_meter:=ProgressBar.new()
	attention_meter.name="AttentionMeter"
	attention_meter.max_value=maxi(1,observers)
	attention_meter.value=mini(assigned,observers)
	attention_meter.show_percentage=false
	attention_meter.custom_minimum_size=Vector2(0,7)
	attention_meter.add_theme_stylebox_override("background",_knowledge_style(Color("#182226"),Color.TRANSPARENT,0,3,0))
	attention_meter.add_theme_stylebox_override("fill",_knowledge_style(Color("#b99c58"),Color.TRANSPARENT,0,3,0))
	directions_column.add_child(attention_meter)
	var direction_scroll:=ScrollContainer.new()
	direction_scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	direction_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	directions_column.add_child(direction_scroll)
	var grid:=GridContainer.new()
	grid.columns=2
	grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation",8)
	grid.add_theme_constant_override("v_separation",8)
	direction_scroll.add_child(grid)
	for dynamic_id in SOCIETY_DYNAMICS:
		var accent:=_knowledge_direction_color(dynamic_id)
		var card:=PanelContainer.new()
		card.custom_minimum_size=Vector2(284,164)
		card.tooltip_text=_dynamic_definition(dynamic_id)
		card.add_theme_stylebox_override("panel",_knowledge_style(Color("#121c1f"),accent.darkened(0.38),1,3,9))
		grid.add_child(card)
		var card_content:=VBoxContainer.new()
		card_content.add_theme_constant_override("separation",4)
		card.add_child(card_content)
		var card_header:=HBoxContainer.new()
		card_header.add_theme_constant_override("separation",7)
		card_content.add_child(card_header)
		var icon_badge:=PanelContainer.new()
		icon_badge.custom_minimum_size=Vector2(28,25)
		icon_badge.add_theme_stylebox_override("panel",_knowledge_style(accent.darkened(0.52),accent,1,3,0))
		card_header.add_child(icon_badge)
		var icon:=Label.new()
		icon.text=_knowledge_direction_icon(dynamic_id)
		icon.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		icon.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
		icon.add_theme_font_size_override("font_size",11)
		icon.add_theme_color_override("font_color",accent.lightened(0.25))
		icon_badge.add_child(icon)
		var name_label:=Label.new()
		name_label.text=String(dynamic_id).to_upper()
		name_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		name_label.add_theme_font_size_override("font_size",12)
		name_label.add_theme_color_override("font_color",Color("#ddd8ca"))
		card_header.add_child(name_label)
		var value:=Label.new()
		value.custom_minimum_size=Vector2(24,0)
		value.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		value.add_theme_font_size_override("font_size",18)
		value.add_theme_color_override("font_color",accent.lightened(0.28))
		card_header.add_child(value)
		allocation_value_labels["dynamic::"+dynamic_id]={"value":value,"card":card,"accent":accent}
		var bar:=ProgressBar.new()
		bar.max_value=maxi(1,observers)
		bar.show_percentage=false
		bar.custom_minimum_size=Vector2(0,6)
		bar.add_theme_stylebox_override("background",_knowledge_style(Color("#1a2528"),Color.TRANSPARENT,0,3,0))
		bar.add_theme_stylebox_override("fill",_knowledge_style(accent,Color.TRANSPARENT,0,3,0))
		card_content.add_child(bar)
		allocation_value_labels["dynamic::"+dynamic_id]["bar"]=bar
		var subcategories:Dictionary=GameState.research_subcategory_allocations.get(dynamic_id,{})
		for subcategory in subcategories:
			var controls:=HBoxContainer.new()
			controls.tooltip_text=_subcategory_definition(dynamic_id,String(subcategory))
			card_content.add_child(controls)
			var consequence:=Label.new()
			consequence.text=String(subcategory)
			consequence.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
			consequence.size_flags_horizontal=Control.SIZE_EXPAND_FILL
			consequence.add_theme_font_size_override("font_size",9)
			consequence.add_theme_color_override("font_color",Color("#9aa5a0"))
			controls.add_child(consequence)
			var subvalue:=Label.new(); subvalue.custom_minimum_size=Vector2(16,0); subvalue.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; subvalue.add_theme_font_size_override("font_size",10); controls.add_child(subvalue)
			var minus:=Button.new(); minus.text="−"; minus.custom_minimum_size=Vector2(24,20); minus.tooltip_text="Release one observer from %s" % subcategory; minus.pressed.connect(_change_research_allocation.bind(dynamic_id,String(subcategory),-1)); controls.add_child(minus)
			var plus:=Button.new(); plus.text="+"; plus.custom_minimum_size=Vector2(24,20); plus.tooltip_text="Commit one observer to %s" % subcategory; plus.pressed.connect(_change_research_allocation.bind(dynamic_id,String(subcategory),1)); controls.add_child(plus)
			allocation_value_labels["%s::%s" % [dynamic_id,subcategory]]={"value":subvalue,"card":card,"accent":accent}
	var reports_frame:=PanelContainer.new()
	reports_frame.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	reports_frame.add_theme_stylebox_override("panel",_knowledge_style(Color("#0d1518"),Color("#283539"),1,3,14))
	body.add_child(reports_frame)
	var reports := VBoxContainer.new()
	reports.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reports.add_theme_constant_override("separation",6)
	reports_frame.add_child(reports)
	var report_title := Label.new()
	report_title.text = "THE LIVING RECORD"
	report_title.add_theme_font_size_override("font_size",17)
	report_title.add_theme_color_override("font_color",Color("#e4dbc8"))
	reports.add_child(report_title)
	var report_subtitle:=Label.new()
	report_subtitle.text="Evidence becomes knowledge only when experience survives memory."
	report_subtitle.add_theme_font_size_override("font_size",11)
	report_subtitle.add_theme_color_override("font_color",Color("#87938f"))
	reports.add_child(report_subtitle)
	var report_scroll := ScrollContainer.new()
	report_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	report_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	reports.add_child(report_scroll)
	knowledge_record_container=VBoxContainer.new()
	knowledge_record_container.custom_minimum_size=Vector2(0,0)
	knowledge_record_container.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	knowledge_record_container.add_theme_constant_override("separation",8)
	report_scroll.add_child(knowledge_record_container)
	knowledge_record_signature=""
	_refresh_knowledge_record()
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation",12)
	root.add_child(footer)
	var footer_note:=Label.new()
	footer_note.text="Each staffed subcondition pursues one viable question. The initial phase spans 200 years; later mature inquiries remain active across millennia."
	footer_note.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	footer_note.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	footer_note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	footer_note.add_theme_font_size_override("font_size",11)
	footer_note.add_theme_color_override("font_color",Color("#8d948f"))
	footer.add_child(footer_note)
	var close := Button.new()
	close.text = "CLOSE"
	close.custom_minimum_size=Vector2(130,38)
	close.pressed.connect(func(): knowledge_panel.queue_free(); knowledge_panel=null; knowledge_record_container=null; knowledge_investigation_widgets.clear())
	footer.add_child(close)
	_refresh_research_allocations()

func _knowledge_style(background: Color,border: Color,border_width: int,radius: int,padding: int) -> StyleBoxFlat:
	var style:=StyleBoxFlat.new()
	style.bg_color=background
	style.border_color=border
	style.border_width_left=border_width
	style.border_width_top=border_width
	style.border_width_right=border_width
	style.border_width_bottom=border_width
	style.corner_radius_top_left=radius
	style.corner_radius_top_right=radius
	style.corner_radius_bottom_left=radius
	style.corner_radius_bottom_right=radius
	style.set_content_margin_all(padding)
	return style

func _knowledge_direction_color(direction: String) -> Color:
	return _dynamic_accent(direction.to_lower())

func _knowledge_direction_icon(direction: String) -> String:
	return {"demography":"DE","nutrition":"NU","health":"HE","labor":"LA","knowledge":"KN","production":"PR","infrastructure":"IN","logistics":"LO","ecology":"EC","institutions":"IS","security":"SE","culture":"CU"}.get(direction.to_lower(),"?")

func _knowledge_consequence_text(direction: String) -> String:
	return _dynamic_definition(direction.to_lower()).get_slice("\n",0)

func _make_knowledge_stat(parent: Container,label_text: String,value_text: String,accent: Color) -> void:
	var panel:=PanelContainer.new()
	panel.custom_minimum_size=Vector2(82,52)
	panel.add_theme_stylebox_override("panel",_knowledge_style(Color("#111a1d"),accent.darkened(0.40),1,3,7))
	parent.add_child(panel)
	var content:=VBoxContainer.new()
	content.add_theme_constant_override("separation",0)
	panel.add_child(content)
	var value:=Label.new()
	value.text=value_text
	value.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	value.add_theme_font_size_override("font_size",20)
	value.add_theme_color_override("font_color",accent.lightened(0.18))
	content.add_child(value)
	var label:=Label.new()
	label.text=label_text
	label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size",9)
	label.add_theme_color_override("font_color",Color("#929b97"))
	content.add_child(label)

func _knowledge_section_heading(title_text: String,count_text: String,accent: Color) -> Control:
	var row:=HBoxContainer.new()
	row.custom_minimum_size=Vector2(0,27)
	var marker:=ColorRect.new()
	marker.color=accent
	marker.custom_minimum_size=Vector2(4,18)
	row.add_child(marker)
	var title:=Label.new()
	title.text=title_text
	title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size",12)
	title.add_theme_color_override("font_color",Color("#ddd6c8"))
	row.add_child(title)
	var count:=Label.new()
	count.text=count_text
	count.add_theme_font_size_override("font_size",12)
	count.add_theme_color_override("font_color",accent.lightened(0.22))
	row.add_child(count)
	return row

func _make_observation_card(parent: Container,investigation: Dictionary) -> void:
	var investigation_id:=String(investigation.get("id",""))
	var direction:=String(investigation.get("dynamic",investigation.get("direction","knowledge")))
	var subcategory:=String(investigation.get("subcategory","Directed attention"))
	var observation:=String(investigation.get("observation","No observation recorded."))
	var progress:=clampf(float(investigation.get("progress",0.0)),0.0,1.0)
	var accent:=_knowledge_direction_color(direction)
	var panel:=PanelContainer.new()
	panel.add_theme_stylebox_override("panel",_knowledge_style(Color("#111b1e"),accent.darkened(0.50),1,3,10))
	parent.add_child(panel)
	var row:=HBoxContainer.new()
	row.add_theme_constant_override("separation",10)
	panel.add_child(row)
	var signal_column:=VBoxContainer.new()
	signal_column.custom_minimum_size=Vector2(46,0)
	row.add_child(signal_column)
	var glyph:=Label.new()
	glyph.text=_knowledge_direction_icon(direction)
	glyph.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	glyph.add_theme_font_size_override("font_size",16)
	glyph.add_theme_color_override("font_color",accent.lightened(0.20))
	signal_column.add_child(glyph)
	var pulse:=ProgressBar.new()
	pulse.max_value=1.0
	pulse.value=progress
	pulse.show_percentage=false
	pulse.custom_minimum_size=Vector2(40,5)
	pulse.add_theme_stylebox_override("background",_knowledge_style(Color("#1c282b"),Color.TRANSPARENT,0,2,0))
	pulse.add_theme_stylebox_override("fill",_knowledge_style(accent,Color.TRANSPARENT,0,2,0))
	signal_column.add_child(pulse)
	var text_column:=VBoxContainer.new()
	text_column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	row.add_child(text_column)
	var meta:=Label.new()
	meta.text="%s  /  %s  •  EVIDENCE %d%%" % [direction.to_upper(),subcategory.to_upper(),roundi(progress*100.0)]
	meta.add_theme_font_size_override("font_size",9)
	meta.add_theme_color_override("font_color",accent.lightened(0.15))
	text_column.add_child(meta)
	knowledge_investigation_widgets[investigation_id]={"progress":pulse,"meta":meta}
	var question:=Label.new()
	question.text=String(investigation.get("name","Unresolved question")).to_upper()
	question.add_theme_font_size_override("font_size",13)
	question.add_theme_color_override("font_color",Color("#eee3cd"))
	text_column.add_child(question)
	var text:=Label.new()
	text.text=observation
	text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	text.add_theme_font_size_override("font_size",13)
	text.add_theme_color_override("font_color",Color("#d4d2c9"))
	text_column.add_child(text)

func _refresh_knowledge_record()->void:
	if knowledge_record_container==null or not is_instance_valid(knowledge_record_container): return
	var active_investigations:=DiscoverySystem.active_investigation_records()
	var active_ids:Array[String]=[]
	for investigation in active_investigations: active_ids.append(String(investigation.get("id","")))
	var signature:="%s|%d" % [",".join(active_ids),GameState.discovery_log.size()]
	if signature!=knowledge_record_signature:
		knowledge_record_signature=signature
		knowledge_investigation_widgets.clear()
		for child in knowledge_record_container.get_children():
			knowledge_record_container.remove_child(child)
			child.queue_free()
		knowledge_record_container.add_child(_knowledge_section_heading("CURRENT INVESTIGATIONS",str(active_investigations.size()),Color("#77a6ae")))
		if active_investigations.is_empty():
			_make_knowledge_empty_state(knowledge_record_container,"No viable question currently has both committed observers and the evidence required to investigate it. Assign observers or encounter new resources.")
		else:
			for investigation in active_investigations: _make_observation_card(knowledge_record_container,investigation)
		knowledge_record_container.add_child(_knowledge_section_heading("ESTABLISHED KNOWLEDGE",str(GameState.discovery_log.size()),Color("#c2a45e")))
		if GameState.discovery_log.is_empty():
			_make_knowledge_empty_state(knowledge_record_container,"No discovery has yet survived testing, use, and collective memory.")
		else:
			for event in GameState.discovery_log: _make_discovery_card(knowledge_record_container,event)
	else:
		for investigation in active_investigations:
			var id:=String(investigation.get("id",""))
			if not knowledge_investigation_widgets.has(id): continue
			var progress:=clampf(float(investigation.get("progress",0.0)),0.0,1.0)
			var widgets:Dictionary=knowledge_investigation_widgets[id]
			(widgets.progress as ProgressBar).value=progress
			(widgets.meta as Label).text="%s  /  %s  •  EVIDENCE %d%%" % [String(investigation.get("dynamic",investigation.get("direction","knowledge"))).to_upper(),String(investigation.get("subcategory","Directed attention")).to_upper(),roundi(progress*100.0)]

func _make_discovery_card(parent: Container,event: Dictionary) -> void:
	var direction:=String(event.get("dynamic",event.get("direction","knowledge")))
	var accent:=_knowledge_direction_color(direction)
	var row:=HBoxContainer.new()
	row.add_theme_constant_override("separation",9)
	parent.add_child(row)
	var timeline:=VBoxContainer.new()
	timeline.custom_minimum_size=Vector2(38,0)
	row.add_child(timeline)
	var dot:=PanelContainer.new()
	dot.custom_minimum_size=Vector2(30,30)
	dot.add_theme_stylebox_override("panel",_knowledge_style(accent.darkened(0.48),accent,1,15,0))
	timeline.add_child(dot)
	var icon:=Label.new()
	icon.text=_knowledge_direction_icon(direction)
	icon.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	icon.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	icon.add_theme_font_size_override("font_size",9)
	icon.add_theme_color_override("font_color",accent.lightened(0.28))
	dot.add_child(icon)
	var line:=ColorRect.new()
	line.color=accent.darkened(0.55)
	line.custom_minimum_size=Vector2(2,48)
	line.size_flags_horizontal=Control.SIZE_SHRINK_CENTER
	timeline.add_child(line)
	var card:=PanelContainer.new()
	card.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel",_knowledge_style(Color("#141d20"),accent.darkened(0.42),1,3,10))
	row.add_child(card)
	var content:=VBoxContainer.new()
	content.add_theme_constant_override("separation",3)
	card.add_child(content)
	var meta:=Label.new()
	var event_day:=int(event.get("day",0))+1
	var year:=event_day/365+1
	var day_of_year:=(event_day-1)%365+1
	meta.text="YEAR %d  •  DAY %d  •  %s  /  %s" % [year,day_of_year,direction.to_upper(),String(event.get("subcategory","Established practice")).to_upper()]
	meta.add_theme_font_size_override("font_size",9)
	meta.add_theme_color_override("font_color",accent.lightened(0.18))
	content.add_child(meta)
	var name:=Label.new()
	name.text=String(event.get("name","Unnamed discovery")).to_upper()
	name.add_theme_font_size_override("font_size",15)
	name.add_theme_color_override("font_color",Color("#eee3cd"))
	content.add_child(name)
	var description:=Label.new()
	description.text=String(event.get("description",""))
	description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	description.add_theme_font_size_override("font_size",12)
	description.add_theme_color_override("font_color",Color("#bdc2ba"))
	content.add_child(description)
	var discovery_id:=String(event.get("id",""))
	var adoption:=DiscoverySystem.adoption(discovery_id)
	var adoption_row:=HBoxContainer.new()
	adoption_row.add_theme_constant_override("separation",8)
	content.add_child(adoption_row)
	var adoption_label:=Label.new()
	adoption_label.text="USED BY SOCIETY  %d%%" % roundi(adoption*100.0)
	adoption_label.custom_minimum_size=Vector2(132,0)
	adoption_label.add_theme_font_size_override("font_size",9)
	adoption_label.add_theme_color_override("font_color",accent.lightened(0.18))
	adoption_row.add_child(adoption_label)
	var adoption_bar:=ProgressBar.new()
	adoption_bar.max_value=1.0
	adoption_bar.value=adoption
	adoption_bar.show_percentage=false
	adoption_bar.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	adoption_bar.custom_minimum_size=Vector2(0,6)
	adoption_bar.add_theme_stylebox_override("background",_knowledge_style(Color("#202a2c"),Color.TRANSPARENT,0,3,0))
	adoption_bar.add_theme_stylebox_override("fill",_knowledge_style(accent,Color.TRANSPARENT,0,3,0))
	adoption_row.add_child(adoption_bar)
	var consequence:=Label.new()
	var effects:Dictionary=event.get("effects",{})
	if effects.is_empty(): effects=DiscoverySystem.discovery_definition(discovery_id).get("effects",{})
	consequence.text=_effect_ripple_text(effects).to_upper()
	consequence.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	consequence.add_theme_font_size_override("font_size",9)
	consequence.add_theme_color_override("font_color",Color("#8f9a95"))
	content.add_child(consequence)

func _make_knowledge_empty_state(parent: Container,message: String) -> void:
	var panel:=PanelContainer.new()
	panel.add_theme_stylebox_override("panel",_knowledge_style(Color("#10181b"),Color("#273236"),1,3,14))
	parent.add_child(panel)
	var label:=Label.new()
	label.text=message
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size",12)
	label.add_theme_color_override("font_color",Color("#8d9793"))
	panel.add_child(label)

func _direction_for_observation(observation: String) -> String:
	for event in GameState.discovery_log:
		if String(event.get("description",""))==observation:
			return String(event.get("direction","Information"))
	var lower:=observation.to_lower()
	if "plant" in lower or "animal" in lower or "soil" in lower: return "Nature"
	if "stone" in lower or "fiber" in lower or "container" in lower: return "Materials"
	if "wound" in lower or "illness" in lower or "water" in lower: return "Health"
	if "work" in lower or "founder" in lower: return "Society"
	return "Information"

func _research_allocation_total() -> int:
	var total:=0
	for dynamic_id in GameState.research_subcategory_allocations:
		for value in (GameState.research_subcategory_allocations[dynamic_id] as Dictionary).values(): total+=int(value)
	return total

func _change_research_allocation(dynamic_id:String,subcategory:String,change:int)->void:
	var subcategories:Dictionary=GameState.research_subcategory_allocations.get(dynamic_id,{})
	var current:=int(subcategories.get(subcategory,0))
	var total:=_research_allocation_total()
	var observers := int(GameState.population_allocations.get("Knowledge",0))
	if change>0 and total>=observers: return
	subcategories[subcategory]=maxi(0,current+change)
	GameState.research_subcategory_allocations[dynamic_id]=subcategories
	var dynamic_total:=0
	for value in subcategories.values(): dynamic_total+=int(value)
	GameState.research_allocations[dynamic_id]=dynamic_total
	DiscoverySystem.refresh_investigations()
	_refresh_research_allocations()
	_refresh_knowledge_record()

func _refresh_research_allocations() -> void:
	var total:=_research_allocation_total()
	var observers:=int(GameState.population_allocations.get("Knowledge",0))
	for dynamic_id in GameState.research_subcategory_allocations:
		var dynamic_total:=0
		var subcategories:Dictionary=GameState.research_subcategory_allocations[dynamic_id]
		for subcategory in subcategories:
			var subvalue:=int(subcategories[subcategory]); dynamic_total+=subvalue
			var channel:="%s::%s" % [dynamic_id,subcategory]
			if allocation_value_labels.has(channel):
				var sublabel:=allocation_value_labels[channel].value as Label
				var active_id:=String(GameState.active_investigations.get(channel,""))
				sublabel.text=("%d !" % subvalue) if subvalue>0 and active_id=="" else str(subvalue)
				sublabel.add_theme_color_override("font_color",Color("#d0a965") if subvalue>0 and active_id=="" else Color("#d5d2c8"))
				sublabel.tooltip_text="Observer committed, but no question is currently supported by encountered resources, prerequisite knowledge, and lived evidence." if subvalue>0 and active_id=="" else "An active investigation is accumulating evidence." if active_id!="" else "No observer committed."
		GameState.research_allocations[dynamic_id]=dynamic_total
		var dynamic_key:="dynamic::"+String(dynamic_id)
		if allocation_value_labels.has(dynamic_key):
			var widgets:Dictionary=allocation_value_labels[dynamic_key]
			(widgets.value as Label).text=str(dynamic_total)
			(widgets.bar as ProgressBar).max_value=maxi(1,observers)
			(widgets.bar as ProgressBar).value=dynamic_total
			(widgets.card as PanelContainer).modulate=Color.WHITE if dynamic_total>0 else Color(0.68,0.71,0.70,1.0)
	if research_total_label:
		var available:=maxi(0,observers-total)
		var warning:="  •  ATTENTION OVERCOMMITTED" if total>observers else ("  •  %d UNCOMMITTED" % available if available>0 else "  •  ALL ATTENTION COMMITTED")
		research_total_label.text="%d commitments across %d observers%s" % [total,observers,warning]
		var meter:=knowledge_panel.find_child("AttentionMeter",true,false) as ProgressBar if knowledge_panel else null
		if meter:
			meter.max_value=maxi(1,observers)
			meter.value=mini(total,observers)

func _open_council_panel() -> void:
	if council_panel:
		council_panel.queue_free()
	council_panel = Control.new()
	council_panel.size = get_viewport().get_visible_rect().size
	council_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	interface_layer.add_child(council_panel)
	var dimmer := ColorRect.new()
	dimmer.size = council_panel.size
	dimmer.color = Color(0.01,0.015,0.018,0.86)
	council_panel.add_child(dimmer)
	var modal := PanelContainer.new()
	modal.position = Vector2(70,45)
	modal.size = council_panel.size - Vector2(140,90)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.045,0.06,0.065,0.99)
	style.set_content_margin_all(22)
	modal.add_theme_stylebox_override("panel",style)
	council_panel.add_child(modal)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation",10)
	modal.add_child(root)
	var title := Label.new()
	title.text = "SOVEREIGN COUNCIL"
	title.add_theme_font_size_override("font_size",25)
	root.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "Advisors interpret the world and seek your orders. Their reports may be incomplete, mistaken, or self-serving."
	subtitle.add_theme_color_override("font_color",Color("#aaa99f"))
	root.add_child(subtitle)
	root.add_child(HSeparator.new())
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	var reports := VBoxContainer.new()
	reports.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reports.add_theme_constant_override("separation",12)
	scroll.add_child(reports)
	if GameState.council_inbox.is_empty():
		var empty := Label.new()
		empty.text = "No advisor currently seeks an audience. Appoint officials through Leadership to form your council."
		empty.add_theme_font_size_override("font_size",16)
		reports.add_child(empty)
	else:
		for item in GameState.council_inbox:
			var card := PanelContainer.new()
			card.custom_minimum_size = Vector2(0,120)
			reports.add_child(card)
			var row := VBoxContainer.new()
			card.add_child(row)
			var report := Label.new()
			var answered_text := "\nORDERED: %s" % String(item.get("response","")) if String(item.get("status",""))=="answered" else ""
			var report_hour:=int(item.get("hour",0))
			var report_day:=int(item.get("day",0))+1
			report.text = "DAY %d  •  %02d:00  •  %s  •  %s\n%s%s" % [report_day,report_hour,item.office.to_upper(),item.advisor,item.text,answered_text]
			report.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			report.add_theme_font_size_override("font_size",15)
			row.add_child(report)
			var actions := HBoxContainer.new()
			row.add_child(actions)
			var response_options:Array=item.get("responses",[])
			if response_options.is_empty():
				response_options=[{"label":"Approve"},{"label":"Reject"},{"label":"Demand evidence"},{"label":"Issue discretion"}]
			for option in response_options:
				var button := Button.new()
				var response:=String(option.get("label","Acknowledge"))
				button.text = response.to_upper()
				button.tooltip_text=String(option.get("ripple",""))
				button.disabled=String(item.get("status",""))=="answered"
				button.pressed.connect(_answer_council.bind(item.id,response))
				actions.add_child(button)
				if option.has("ripple"):
					var ripple:=Label.new()
					ripple.text="↳ %s" % String(option.ripple)
					ripple.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
					ripple.add_theme_font_size_override("font_size",12)
					ripple.add_theme_color_override("font_color",Color("#a8a596"))
					row.add_child(ripple)
	var order_row := HBoxContainer.new()
	root.add_child(order_row)
	var order_input := LineEdit.new()
	order_input.placeholder_text = "Issue a sovereign order to the council…"
	order_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	order_row.add_child(order_input)
	var send := Button.new()
	send.text = "ISSUE ORDER"
	send.pressed.connect(_issue_freeform_order.bind(order_input))
	order_row.add_child(send)
	var close := Button.new()
	close.text = "CLOSE"
	close.pressed.connect(func(): council_panel.queue_free())
	order_row.add_child(close)

func _answer_council(item_id: String, response: String) -> void:
	AdvisorSystem.respond_to_council_item(item_id,response)
	_open_council_panel()

func _issue_freeform_order(input: LineEdit) -> void:
	var text := input.text.strip_edges()
	if text.is_empty():
		return
	AdvisorSystem.issue_order("directive","civilization",{"text":text},"")
	var normalized:=text.to_lower()
	var effect:=""
	var ripple:="The council records the order, but no office can yet translate it into a standing simulation policy."
	if "ration" in normalized:
		effect="rationing"; ripple="Rationing extends food stores but strains cohesion."
	elif "forag" in normalized or "gather food" in normalized or "hunt" in normalized:
		effect="foraging_drive"; ripple="Emergency gathering raises food yield while increasing pressure on the land."
	elif "conserv" in normalized or "protect the land" in normalized:
		effect="conservation_order"; ripple="Gathering is restricted so the landscape can recover."
	elif "heal" in normalized or "care" in normalized or "sick" in normalized:
		effect="care_rotation"; ripple="Care rotations improve health while reducing labor efficiency."
	elif "watch" in normalized or "guard" in normalized or "defen" in normalized:
		effect="expanded_watch"; ripple="The expanded watch raises security while claiming scarce labor."
	elif "assembly" in normalized or "explain" in normalized or "council" in normalized:
		effect="public_assembly"; ripple="Public deliberation strengthens legitimacy and cohesion."
	elif "build" in normalized or "shelter" in normalized:
		effect="emergency_building"; ripple="Urgent construction improves material momentum but distorts other work."
	if effect!="": ConsequenceEngine.apply_policy(effect,0.16,120.0,ripple)
	input.text=""
	if travel_status_label: travel_status_label.text="ORDER RECORDED  •  %s" % ripple
	input.text = ""

func _build_leader_selection(layer: CanvasLayer) -> void:
	_generate_leader_candidates("Steward")
	portrait_sheet = load("res://assets/portraits/founding_leaders.png")
	leader_panel = Control.new()
	leader_panel.size = get_viewport().get_visible_rect().size
	leader_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	leader_panel.visible = false
	layer.add_child(leader_panel)
	var viewport_size := get_viewport().get_visible_rect().size
	var dimmer := ColorRect.new()
	dimmer.size = viewport_size
	dimmer.color = Color(0.01, 0.015, 0.018, 0.82)
	leader_panel.add_child(dimmer)
	var modal := PanelContainer.new()
	modal.position = Vector2(28, 24)
	modal.size = viewport_size - Vector2(56, 48)
	var modal_style := StyleBoxFlat.new()
	modal_style.bg_color = Color(0.045, 0.06, 0.065, 0.99)
	modal_style.border_color = Color("#35434a")
	modal_style.set_border_width_all(1)
	modal_style.set_content_margin_all(22)
	modal.add_theme_stylebox_override("panel", modal_style)
	leader_panel.add_child(modal)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	modal.add_child(root)
	leader_heading = Label.new()
	leader_heading.text = "SELECT AN ADVISOR"
	leader_heading.add_theme_font_size_override("font_size", 24)
	leader_heading.add_theme_color_override("font_color", Color("#ede2cd"))
	root.add_child(leader_heading)
	leader_explanation = Label.new()
	leader_explanation.text = "Five people are proposed from the living population. Their influence is measured through the civilization's twelve real dynamics."
	leader_explanation.add_theme_font_size_override("font_size", 14)
	leader_explanation.add_theme_color_override("font_color", Color("#aaa99f"))
	root.add_child(leader_explanation)
	var divider := HSeparator.new()
	root.add_child(divider)
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 18)
	root.add_child(body)
	var candidate_scroll := ScrollContainer.new()
	candidate_scroll.custom_minimum_size = Vector2(340, 0)
	candidate_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(candidate_scroll)
	leader_candidate_list = VBoxContainer.new()
	leader_candidate_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	leader_candidate_list.add_theme_constant_override("separation", 10)
	candidate_scroll.add_child(leader_candidate_list)
	_rebuild_leader_candidate_list()
	var dossier_scroll := ScrollContainer.new()
	dossier_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dossier_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dossier_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(dossier_scroll)
	leader_dossier = VBoxContainer.new()
	leader_dossier.custom_minimum_size = Vector2(610, 700)
	leader_dossier.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	leader_dossier.add_theme_constant_override("separation",8)
	dossier_scroll.add_child(leader_dossier)
	var footer_divider := HSeparator.new()
	root.add_child(footer_divider)
	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_END
	footer.add_theme_constant_override("separation", 12)
	root.add_child(footer)
	var close_button := Button.new()
	close_button.custom_minimum_size = Vector2(150, 44)
	close_button.text = "CLOSE"
	close_button.pressed.connect(_close_leadership_panel)
	footer.add_child(close_button)
	appoint_button = Button.new()
	appoint_button.custom_minimum_size = Vector2(310, 44)
	appoint_button.text = "APPOINT ADVISOR"
	appoint_button.add_theme_font_size_override("font_size", 15)
	appoint_button.pressed.connect(_appoint_leader)
	footer.add_child(appoint_button)
	_inspect_leader(0)

func _rebuild_leader_candidate_list() -> void:
	if leader_candidate_list==null: return
	for child in leader_candidate_list.get_children(): child.queue_free()
	for i in leader_candidates.size():
		var candidate:Dictionary=leader_candidates[i]
		var button:=Button.new()
		button.custom_minimum_size=Vector2(320,92)
		button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		var focus:Array=OFFICE_DYNAMICS.get(pending_advisor_office,["institutions","culture"])
		var strongest:=String(focus[0])
		for dynamic_id in focus:
			if float(candidate.dynamic_profile.get(dynamic_id,0.0))>float(candidate.dynamic_profile.get(strongest,0.0)): strongest=String(dynamic_id)
		button.text="%s, %d\n%s\n%s • strongest in %s" % [candidate.name,candidate.age,candidate.background,"  /  ".join(candidate.traits),strongest.capitalize()]
		button.icon=_leader_portrait(i)
		button.add_theme_constant_override("icon_max_width",72)
		button.expand_icon=true
		button.alignment=HORIZONTAL_ALIGNMENT_LEFT
		button.add_theme_font_size_override("font_size",13)
		button.tooltip_text="A living member of the population. Open the dossier to compare system-wide consequences."
		button.pressed.connect(_inspect_leader.bind(i))
		leader_candidate_list.add_child(button)

func _leader_portrait(index: int) -> AtlasTexture:
	var portrait := AtlasTexture.new()
	portrait.atlas = portrait_sheet
	var panel_width := portrait_sheet.get_width() / 5.0
	portrait.region = Rect2(panel_width * (index % 5), 0, panel_width, portrait_sheet.get_height())
	return portrait

func _generate_leader_candidates(office:String) -> void:
	leader_candidates.clear()
	GameState.initialize_citizen_registry()
	var serving_elsewhere:Dictionary={}
	for occupied_office in GameState.leadership_positions:
		if String(occupied_office)==office: continue
		var office_holder:Dictionary=GameState.leadership_positions[occupied_office]
		serving_elsewhere[int(office_holder.get("citizen_id",-1))]=true
	var eligible:Array[Dictionary]=[]
	for person in GameState.living_citizens():
		var age:=GameState.citizen_age_years(person)
		if age<18 or age>72: continue
		if serving_elsewhere.has(int(person.get("id",-1))): continue
		var candidate:=_candidate_from_citizen(person,office)
		eligible.append(candidate)
	eligible.sort_custom(func(a:Dictionary,b:Dictionary)->bool: return float(a.office_fit)>float(b.office_fit))
	for i in mini(5,eligible.size()): leader_candidates.append(eligible[i])
	AdvisorSystem.register_advisors(leader_candidates)

func _candidate_from_citizen(person:Dictionary,office:String)->Dictionary:
	var traits_pool:=["Visionary","Pragmatic","Patient","Ambitious","Compassionate","Ruthless","Meticulous","Charismatic","Cautious","Inventive","Traditionalist","Resolute"]
	# Aptitudes belong to the person. The office changes who is shortlisted,
	# never the candidate's underlying capabilities.
	var seed:=int(person.get("aptitude_seed",0))
	var rng:=RandomNumberGenerator.new()
	rng.seed=seed
	var profile:Dictionary={}
	var subcategory_profile:Dictionary={}
	for dynamic_id in SOCIETY_DYNAMICS:
		var life_bonus:=0.05 if String(person.get("role",""))==_role_for_dynamic(dynamic_id) else 0.0
		profile[dynamic_id]=clampf(rng.randf_range(0.28,0.82)+life_bonus,0.18,0.94)
		var subs:Dictionary={}
		for subcategory in SOCIETY_SUBCATEGORY_NAMES[dynamic_id]:
			subs[subcategory]=clampf(float(profile[dynamic_id])+rng.randf_range(-0.15,0.15),0.12,0.97)
		subcategory_profile[dynamic_id]=subs
	var focus:Array=OFFICE_DYNAMICS.get(office,["institutions","culture"])
	var fit:=0.0
	for dynamic_id in focus: fit+=float(profile.get(dynamic_id,0.0))
	fit/=maxf(1.0,float(focus.size()))
	var trait_a:=String(traits_pool[posmod(seed,traits_pool.size())])
	var trait_b:=String(traits_pool[posmod(seed/17+5,traits_pool.size())])
	if trait_b==trait_a: trait_b=String(traits_pool[(traits_pool.find(trait_a)+3)%traits_pool.size()])
	var background:=_background_for_citizen(person)
	var skills:=_legacy_skills_from_dynamics(profile)
	var current_culture:=float(GameState.society_capacities.get("culture",0.5))
	var support:=roundi(clampf(0.22+float(profile.culture)*0.34+float(profile.institutions)*0.24+current_culture*0.20,0.18,0.88)*100.0)
	return {"citizen_id":int(person.get("id",-1)),"name":String(person.get("name","Unnamed")),"age":GameState.citizen_age_years(person),
		"background":background,"population_role":String(person.get("role","Unassigned")),"traits":[trait_a,trait_b],
		"dynamic_profile":profile,"subcategory_profile":subcategory_profile,"skills":skills,"support":support,"office_fit":fit}

func _role_for_dynamic(dynamic_id:String)->String:
	return {"demography":"Care","nutrition":"Food","health":"Care","labor":"Construction","knowledge":"Knowledge","production":"Crafting","infrastructure":"Construction","logistics":"Hauling","ecology":"Survey","institutions":"Administration","security":"Defense","culture":"Administration"}.get(dynamic_id,"Unassigned")

func _background_for_citizen(person:Dictionary)->String:
	return {"Food":"Provisioner","Extraction":"Resource Worker","Construction":"Builder","Hauling":"Caravan Organizer","Crafting":"Maker","Knowledge":"Observer and Teacher","Care":"Healer","Administration":"Household Speaker","Defense":"Watch Keeper","Survey":"Pathfinder"}.get(String(person.get("role","")),"Household Representative")

func _legacy_skills_from_dynamics(profile:Dictionary)->Dictionary:
	var map:={"Administration":"institutions","Law":"institutions","Public Order":"security","Crisis Management":"security","Agriculture":"nutrition","Construction":"infrastructure","Manufacturing":"production","Trade":"logistics","Logistics":"logistics","Research":"knowledge","Engineering":"infrastructure","Medicine":"health","Education":"knowledge","Natural Science":"ecology","Strategy":"security","Tactics":"security","Fortification":"infrastructure","Intelligence":"knowledge","Oratory":"culture","Diplomacy":"culture","Negotiation":"institutions","Empathy":"demography","Coalition Building":"culture","Judgment":"institutions","Creativity":"knowledge","Discipline":"labor","Delegation":"labor","Stress Tolerance":"health"}
	var result:Dictionary={}
	for skill in map: result[skill]=roundi(float(profile.get(map[skill],0.4))*100.0)
	return result

func _inspect_leader(index: int) -> void:
	if leader_candidates.is_empty() or leader_dossier==null: return
	inspected_leader = index
	for child in leader_dossier.get_children(): child.queue_free()
	var candidate:Dictionary=leader_candidates[index]
	var identity:=Label.new()
	identity.text="%s\n%s, age %d  •  currently %s\n%s  /  %s" % [String(candidate.name).to_upper(),candidate.background,candidate.age,candidate.population_role,candidate.traits[0],candidate.traits[1]]
	identity.add_theme_font_size_override("font_size",16)
	identity.add_theme_color_override("font_color",Color("#eee2ca"))
	leader_dossier.add_child(identity)
	var support_bar:=ProgressBar.new()
	support_bar.max_value=100.0; support_bar.value=float(candidate.support); support_bar.show_percentage=false
	support_bar.custom_minimum_size=Vector2(0,9)
	support_bar.tooltip_text="Political support reflects Culture and Institutions—not a separate arbitrary stat."
	support_bar.add_theme_stylebox_override("fill",_knowledge_style(Color("#b89a5d"),Color.TRANSPARENT,0,3,0))
	leader_dossier.add_child(support_bar)
	var support_label:=Label.new()
	support_label.text="POLITICAL BASE  •  %s" % _capacity_band(float(candidate.support)/100.0)
	support_label.add_theme_font_size_override("font_size",10)
	support_label.add_theme_color_override("font_color",Color("#b7ad98"))
	leader_dossier.add_child(support_label)
	var intro:=Label.new()
	intro.text="PROJECTED INFLUENCE ON THE 12 SOCIETY DYNAMICS"
	intro.add_theme_font_size_override("font_size",12)
	intro.add_theme_color_override("font_color",Color("#9fb7c3"))
	leader_dossier.add_child(intro)
	var grid:=GridContainer.new(); grid.columns=2; grid.add_theme_constant_override("h_separation",8); grid.add_theme_constant_override("v_separation",7)
	leader_dossier.add_child(grid)
	for dynamic_id in SOCIETY_DYNAMICS: _make_candidate_dynamic_card(grid,candidate,dynamic_id)

func _make_candidate_dynamic_card(parent:Container,candidate:Dictionary,dynamic_id:String)->void:
	var value:=clampf(float(candidate.dynamic_profile.get(dynamic_id,0.0)),0.0,1.0)
	var accent:=_dynamic_accent(dynamic_id)
	var panel:=PanelContainer.new()
	panel.custom_minimum_size=Vector2(286,58)
	panel.add_theme_stylebox_override("panel",_knowledge_style(Color("#121a1c"),accent.darkened(0.45),1,3,7))
	parent.add_child(panel)
	var column:=VBoxContainer.new(); column.add_theme_constant_override("separation",2); panel.add_child(column)
	var line:=HBoxContainer.new(); column.add_child(line)
	var title:=Label.new(); title.text=dynamic_id.to_upper(); title.size_flags_horizontal=Control.SIZE_EXPAND_FILL; title.add_theme_font_size_override("font_size",10); title.add_theme_color_override("font_color",Color("#ddd5c6")); line.add_child(title)
	var band:=Label.new(); band.text=_capacity_band(value).to_upper(); band.add_theme_font_size_override("font_size",9); band.add_theme_color_override("font_color",accent.lightened(0.18)); line.add_child(band)
	var bar:=ProgressBar.new(); bar.max_value=1.0; bar.value=value; bar.show_percentage=false; bar.custom_minimum_size=Vector2(0,6)
	bar.add_theme_stylebox_override("background",_knowledge_style(Color("#20292b"),Color.TRANSPARENT,0,3,0)); bar.add_theme_stylebox_override("fill",_knowledge_style(accent,Color.TRANSPARENT,0,3,0)); column.add_child(bar)
	var breakdown:Dictionary=candidate.get("subcategory_profile",{}).get(dynamic_id,{})
	var strongest:=""; var weakest:=""
	for key in breakdown:
		if strongest=="" or float(breakdown[key])>float(breakdown[strongest]): strongest=String(key)
		if weakest=="" or float(breakdown[key])<float(breakdown[weakest]): weakest=String(key)
	var detail:=Label.new(); detail.text="Strength: %s  •  Risk: %s" % [strongest,weakest]; detail.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS; detail.add_theme_font_size_override("font_size",8); detail.add_theme_color_override("font_color",Color("#7f8b87")); detail.tooltip_text=_dynamic_definition(dynamic_id); column.add_child(detail)

func _capacity_band(value:float)->String:
	if value>=0.78: return "Exceptional"
	if value>=0.64: return "Strong"
	if value>=0.48: return "Capable"
	if value>=0.34: return "Limited"
	return "Weak"

func _appoint_leader() -> void:
	if pending_advisor_office == "":
		return
	var candidate: Dictionary = leader_candidates[inspected_leader]
	AdvisorSystem.appoint(candidate.name,pending_advisor_office)
	var topics := {"Steward":"population","Quartermaster":"food","Scholar":"knowledge","Marshal":"security","Envoy":"resources"}
	AdvisorSystem.generate_council_item(pending_advisor_office,topics.get(pending_advisor_office,"construction"),0.58)
	leader_panel.visible = false
	choice_status.text = "%s appointed as %s." % [candidate.name,pending_advisor_office]
	pending_advisor_office = ""
	_open_government_panel()

func _open_leadership_panel() -> void:
	leader_panel.visible = true
	settler_panel.visible = false
	if not GameState.founding_leader.is_empty():
		for i in leader_candidates.size():
			if leader_candidates[i].name == GameState.founding_leader.name:
				_inspect_leader(i)
				break
		appoint_button.text = "CURRENT FOUNDING LEADER"
		appoint_button.disabled = true

func _open_government_panel() -> void:
	if government_panel:
		government_panel.queue_free()
	government_panel = Control.new()
	government_panel.size = get_viewport().get_visible_rect().size
	government_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	interface_layer.add_child(government_panel)
	var dimmer := ColorRect.new()
	dimmer.size = government_panel.size
	dimmer.color = Color(0.01, 0.015, 0.018, 0.86)
	government_panel.add_child(dimmer)
	var modal := PanelContainer.new()
	modal.position = Vector2(34, 28)
	modal.size = government_panel.size - Vector2(68, 56)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.045, 0.06, 0.065, 0.99)
	style.border_color = Color("#35434a")
	style.set_border_width_all(1)
	style.set_content_margin_all(22)
	modal.add_theme_stylebox_override("panel", style)
	government_panel.add_child(modal)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	modal.add_child(root)
	var heading := Label.new()
	heading.text = "LEADERSHIP"
	heading.add_theme_font_size_override("font_size", 27)
	heading.add_theme_color_override("font_color", Color("#ede2cd"))
	root.add_child(heading)
	var subtitle := Label.new()
	subtitle.text = "Offices, authority, political support, and the people responsible for executing policy"
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", Color("#aaa99f"))
	root.add_child(subtitle)
	root.add_child(HSeparator.new())
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	scroll.add_child(grid)
	var offices := [
		["Sovereign", "The player: final authority over every civilizational order"],
		["Steward", "Administration, population, and construction"],
		["Quartermaster", "Supply, stockpiles, and logistics"],
		["Scholar", "Research, education, and knowledge"],
		["Marshal", "Defense, training, and military command"],
		["Envoy", "Diplomacy, trade, and foreign relations"]
	]
	for i in offices.size():
		_create_office_card(grid, offices[i][0], offices[i][1], i)
	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_END
	root.add_child(footer)
	var close := Button.new()
	close.custom_minimum_size = Vector2(170, 44)
	close.text = "CLOSE"
	close.pressed.connect(func(): government_panel.queue_free())
	footer.add_child(close)

func _create_office_card(parent: Control, office: String, responsibility: String, portrait_index: int) -> void:
	var focus:Array=OFFICE_DYNAMICS.get(office,["institutions"])
	var accent:=_dynamic_accent(String(focus[0])) if office!="Sovereign" else Color("#c2a45e")
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(350, 252)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#111719")
	style.border_color = accent.darkened(0.35)
	style.set_border_width_all(1)
	style.set_content_margin_all(14)
	card.add_theme_stylebox_override("panel", style)
	parent.add_child(card)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 7)
	card.add_child(column)
	var office_label := Label.new()
	office_label.text = office.to_upper()
	office_label.add_theme_font_size_override("font_size", 17)
	office_label.add_theme_color_override("font_color", accent.lightened(0.18))
	column.add_child(office_label)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	column.add_child(row)
	var occupied := office == "Sovereign" or GameState.leadership_positions.has(office)
	if occupied:
		var portrait := TextureRect.new()
		portrait.custom_minimum_size = Vector2(96, 116)
		portrait.texture = _leader_portrait(portrait_index) if office != "Sovereign" else _leader_portrait(0)
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		row.add_child(portrait)
	else:
		var vacancy := ColorRect.new()
		vacancy.custom_minimum_size = Vector2(96, 116)
		vacancy.color = Color("#20282b")
		row.add_child(vacancy)
	var details := Label.new()
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if occupied:
		if office == "Sovereign":
			details.text = "YOU\nEssential Sovereign\n\nIssues final orders and receives all counsel. Cannot be replaced or overruled."
		else:
			var leader: Dictionary = GameState.leadership_positions[office]
			details.text = "%s\n%s\n\n%s • %s\nPolitical base: %s" % [leader.name, leader.background, leader.traits[0], leader.traits[1],_capacity_band(float(leader.support)/100.0)]
	else:
		details.text = "VACANT\n\n%s\n\nNo one is executing this portfolio." % responsibility
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.add_theme_font_size_override("font_size", 14)
	row.add_child(details)
	if office!="Sovereign":
		var mandate:=Label.new()
		mandate.text="INFLUENCES  •  "+"  /  ".join(focus).to_upper()
		mandate.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
		mandate.add_theme_font_size_override("font_size",9)
		mandate.add_theme_color_override("font_color",accent.lightened(0.08))
		mandate.tooltip_text="This office directly modifies these canonical society dynamics and their subcategories."
		column.add_child(mandate)
		var appoint := Button.new()
		appoint.text = "REVIEW 5 CANDIDATES" if occupied else "VIEW 5 PROPOSED CANDIDATES"
		appoint.tooltip_text = "Compare five eligible living citizens using the twelve society dynamics."
		appoint.pressed.connect(_open_advisor_candidates.bind(office))
		column.add_child(appoint)

func _open_advisor_candidates(office: String) -> void:
	pending_advisor_office = office
	if GameState.society_subcategories.is_empty():
		GameState.society_subcategories=DiscoverySystem.society_model.evaluate_subcategories(_discovery_context())
	_generate_leader_candidates(office)
	_rebuild_leader_candidate_list()
	leader_heading.text = "APPOINT %s" % office.to_upper()
	leader_explanation.text="Five eligible people are proposed from the living population for %s. Bars show projected influence on the same dynamics that govern the civilization." % office
	appoint_button.text = "APPOINT AS %s" % office.to_upper()
	appoint_button.disabled = false
	_inspect_leader(0)
	leader_panel.visible = true
	if government_panel:
		government_panel.queue_free()

func _close_leadership_panel() -> void:
	leader_panel.visible = false

func _on_building_choice(building: String) -> void:
	placement_building = building
	settler_panel.visible = false
	if placement_preview:
		placement_preview.queue_free()
	placement_preview = MeshInstance3D.new()
	var preview_mesh := CylinderMesh.new()
	preview_mesh.top_radius = 3.2
	preview_mesh.bottom_radius = 3.2
	preview_mesh.height = 0.18
	preview_mesh.radial_segments = 32
	placement_preview.mesh = preview_mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.25, 0.72, 0.88, 0.48)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	placement_preview.material_override = material
	placement_preview.visible = false
	add_child(placement_preview)
	travel_status_label.text = "PLACING %s  •  Left-click valid terrain  •  Right-click cancels" % building.to_upper()

func _terrain_hit(screen_position: Vector2) -> Dictionary:
	if SEAMLESS_WORLD:
		var origin:=camera.project_ray_origin(screen_position)
		var direction:=camera.project_ray_normal(screen_position)
		if absf(direction.y)<0.00001:
			return {}
		var distance:=(SEA_LEVEL-origin.y)/direction.y
		if distance<0.0:
			return {}
		var point:=origin+direction*distance
		for refinement in 3:
			var height:=_height_at(point.x,point.z)
			distance=(height-origin.y)/direction.y
			point=origin+direction*distance
		if absf(point.x)>world_width*0.5 or absf(point.z)>world_depth*0.5:
			return {}
		return {"position":Vector3(point.x,_height_at(point.x,point.z),point.z),"normal":Vector3.UP}
	var origin := camera.project_ray_origin(screen_position)
	var end := origin + camera.project_ray_normal(screen_position) * 500.0
	var query := PhysicsRayQueryParameters3D.create(origin, end)
	if settler_marker:
		query.exclude = [settler_marker.get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty() or hit.collider != terrain_body:
		return {}
	return hit

func _update_placement_preview(screen_position: Vector2) -> void:
	if placement_building == "" or placement_preview == null:
		return
	var hit := _terrain_hit(screen_position)
	placement_valid = not hit.is_empty()
	placement_preview.visible = placement_valid
	if placement_valid:
		placement_preview.position = hit.position + Vector3.UP * 0.12

func _confirm_building_placement() -> void:
	if not placement_valid or placement_preview == null:
		return
	var position := placement_preview.position
	var name := placement_building
	placement_preview.queue_free()
	placement_preview = null
	placement_building = ""
	var site := Node3D.new()
	site.position = position
	add_child(site)
	var foundation := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 2.8
	mesh.bottom_radius = 2.8
	mesh.height = 0.22
	mesh.radial_segments = 24
	foundation.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("#79664c")
	foundation.material_override = material
	site.add_child(foundation)
	var label := Label3D.new()
	label.position = Vector3(0, 2.2, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.font_size = 30
	label.outline_size = 9
	site.add_child(label)
	var durations := {"Communal Hearth": 6.0, "Lean-to Shelters": 8.0, "Storage Pit": 5.0, "Gathering Site": 7.0, "Open Work Area": 10.0}
	var duration: float = durations.get(name, 8.0)
	construction_projects.append({"name": name, "remaining": duration, "total": duration, "label": label, "complete": false})
	travel_status_label.text = "%s construction started  •  %.0f days" % [name.to_upper(), duration]

func _cancel_placement() -> void:
	placement_building = ""
	placement_valid = false
	if placement_preview:
		placement_preview.queue_free()
		placement_preview = null
	travel_status_label.text = ""

func _update_resource_proximity() -> void:
	if nearby_resources_label == null or settler_marker == null:
		return
	var nearest_type := ""
	var nearest_distance := INF
	for site in ResourceSystem.visible_deposits():
		var site_position: Vector3 = site.position
		var distance := Vector2(settler_marker.position.x, settler_marker.position.z).distance_to(Vector2(site_position.x, site_position.z))
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_type = site.resource
	if nearest_type == "":
		nearby_resources_label.text = "Known nearby resources: none"
		nearest_resource_type = ""
		_update_building_buttons()
		return
	nearby_resources_label.text = "Nearest known: %s  •  %.1f km" % [nearest_type, nearest_distance * KM_PER_WORLD_UNIT]
	var in_range := nearest_distance <= 13.0
	nearest_resource_type = nearest_type if in_range else ""
	_update_building_buttons()

func _update_building_buttons() -> void:
	for building in building_buttons:
		var entry: Dictionary = building_buttons[building]
		var button: Button = entry.button
		var requirement: String = entry.requirement
		if requirement == "Foundation":
			button.disabled = hearth_established
		elif requirement == "Resource":
			button.disabled = not hearth_established or nearest_resource_type == ""
		else:
			button.disabled = not hearth_established

func _population_report_style(accent: Color,hover := false) -> StyleBoxFlat:
	var style:=StyleBoxFlat.new()
	style.bg_color=Color(0.045,0.058,0.060,0.97) if not hover else Color(0.075,0.086,0.084,0.99)
	style.border_color=accent
	style.border_width_left=3
	style.border_width_top=1
	style.border_width_right=1
	style.border_width_bottom=1
	style.corner_radius_top_left=3
	style.corner_radius_top_right=3
	style.corner_radius_bottom_left=3
	style.corner_radius_bottom_right=3
	style.content_margin_left=14
	style.content_margin_right=12
	style.content_margin_top=8
	style.content_margin_bottom=8
	return style

func _refresh_event_report() -> void:
	if event_report_button==null:
		return
	if GameState.demographic_ledger.is_empty():
		event_report_button.visible=false
		return
	var record:Dictionary=GameState.demographic_ledger[0]
	var kind:=String(record.get("kind","death"))
	var count:=int(record.get("count",1))
	var start_day:=int(record.get("start_day",record.get("day",0)))+1
	var end_day:=int(record.get("end_day",record.get("day",0)))+1
	var period:="DAY %d" % end_day if start_day==end_day else "DAYS %d–%d" % [start_day,end_day]
	var noun:="BIRTH" if kind=="birth" else "DEATH"
	var recorded_cause:=String(record.get("cause","Unknown"))
	var cause_label:="SUPPORTED BY CURRENT CONDITIONS" if kind=="birth" and recorded_cause=="Births" else recorded_cause.to_upper()
	var accent:=Color("#b8a36d") if kind=="birth" else Color("#a95f52")
	var condition:="Health %d%%  •  Stores %.1f days  •  Daily supply %d%%  •  Shelter %d%%" % [roundi(float(record.get("health",0.0))*100.0),float(record.get("food_days",0.0)),roundi(float(record.get("production_ratio",0.0))*100.0),roundi(float(record.get("housing_ratio",0.0))*100.0)]
	event_report_button.text="POPULATION REPORT  •  %s\n%d %s%s — %s  •  %s\n%s" % [period,count,noun,"" if count==1 else "S",cause_label,String(record.get("location","Unknown location")),condition]
	event_report_button.add_theme_stylebox_override("normal",_population_report_style(accent))
	event_report_button.add_theme_stylebox_override("hover",_population_report_style(accent,true))
	event_report_button.add_theme_stylebox_override("pressed",_population_report_style(accent,true))
	event_report_button.tooltip_text=String(record.get("description","Open the population ledger."))
	event_report_button.visible=true

func _open_population_ledger() -> void:
	if population_ledger_panel:
		population_ledger_panel.queue_free()
	population_ledger_panel=Control.new()
	population_ledger_panel.size=get_viewport().get_visible_rect().size
	population_ledger_panel.mouse_filter=Control.MOUSE_FILTER_STOP
	interface_layer.add_child(population_ledger_panel)
	var dimmer:=ColorRect.new()
	dimmer.size=population_ledger_panel.size
	dimmer.color=Color(0.008,0.013,0.015,0.90)
	population_ledger_panel.add_child(dimmer)
	var modal:=PanelContainer.new()
	modal.position=Vector2(56,34)
	modal.size=population_ledger_panel.size-Vector2(112,68)
	var modal_style:=StyleBoxFlat.new()
	modal_style.bg_color=Color(0.035,0.048,0.052,0.995)
	modal_style.border_color=Color("#75684d")
	modal_style.set_border_width_all(1)
	modal_style.set_content_margin_all(22)
	modal.add_theme_stylebox_override("panel",modal_style)
	population_ledger_panel.add_child(modal)
	var root:=VBoxContainer.new()
	root.add_theme_constant_override("separation",10)
	modal.add_child(root)
	var heading:=Label.new()
	heading.text="POPULATION & CONSEQUENCE LEDGER"
	heading.add_theme_font_size_override("font_size",24)
	heading.add_theme_color_override("font_color",Color("#ecdfc4"))
	root.add_child(heading)
	var summary:=Label.new()
	var pregnancy_summary:=GameState.pregnancy_summary()
	summary.text="POPULATION  %s     PREGNANCIES  %d     BIRTHS  %d     DEATHS  %d\nLIFE EXPECTANCY  %.1f YEARS     EXPECTED LIVE BIRTHS, NEXT 12 MONTHS  %.1f     HEALTH  %d%%     STORES  %.1f DAYS\nPREGNANCY LOSSES  %d     STILLBIRTHS  %d     MATERNAL DEATHS  %d     NEONATAL DEATHS  %d" % [_compact_population(GameState.population_total),int(pregnancy_summary.active),GameState.lifetime_births,GameState.lifetime_deaths,GameState.projected_life_expectancy(),float(GameState.simulation_metrics.get("births_expected_next_year",pregnancy_summary.due_within_year)),roundi(GameState.population_health*100.0),float(GameState.simulation_metrics.get("food_days",0.0)),GameState.lifetime_pregnancy_losses,GameState.lifetime_stillbirths,GameState.lifetime_maternal_deaths,GameState.lifetime_neonatal_deaths]
	summary.add_theme_font_size_override("font_size",15)
	summary.add_theme_color_override("font_color",Color("#cfbd8c"))
	root.add_child(summary)
	var model:=Label.new()
	model.text="HOW POPULATION CHANGES   Conceptions arise from the ages, partnerships, health, workload, nourishment, shelter, and movement of named citizens. Pregnancy, loss, gestation, delivery, postpartum recovery, parentage, and maternal or neonatal danger are tracked separately."
	model.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	model.add_theme_font_size_override("font_size",13)
	model.add_theme_color_override("font_color",Color("#aeb0a8"))
	root.add_child(model)
	root.add_child(HSeparator.new())
	var scroll:=ScrollContainer.new()
	scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	var entries:=VBoxContainer.new()
	entries.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	entries.add_theme_constant_override("separation",9)
	scroll.add_child(entries)
	var pregnancies:=GameState.active_pregnancies()
	if not pregnancies.is_empty():
		var pregnancy_title:=Label.new()
		pregnancy_title.text="CURRENT PREGNANCIES"
		pregnancy_title.add_theme_font_size_override("font_size",17)
		pregnancy_title.add_theme_color_override("font_color",Color("#cfbd8c"))
		entries.add_child(pregnancy_title)
		for pregnancy_variant in pregnancies:
			var pregnancy:Dictionary=pregnancy_variant
			var mother:=GameState.citizen_by_id(int(pregnancy.get("mother_id",-1)))
			var father:=GameState.citizen_by_id(int(pregnancy.get("father_id",-1)))
			var remaining_days:=maxi(0,int(pregnancy.get("due_day",int(GameState.elapsed_days)))-int(GameState.elapsed_days))
			var gestation_days:=maxi(0,int(GameState.elapsed_days)-int(pregnancy.get("conception_day",int(GameState.elapsed_days))))
			var trimester:="FIRST TRIMESTER" if gestation_days<91 else ("SECOND TRIMESTER" if gestation_days<182 else "THIRD TRIMESTER")
			var pregnancy_card:=PanelContainer.new()
			pregnancy_card.add_theme_stylebox_override("panel",_population_report_style(Color("#8fa28e")))
			entries.add_child(pregnancy_card)
			var pregnancy_body:=Label.new()
			pregnancy_body.text="%s, AGE %d   •   %s   •   DUE IN %d DAYS\nPartner: %s   •   Household %d   •   Current role: %s" % [String(mother.get("name","Unknown")).to_upper(),GameState.citizen_age_years(mother),trimester,remaining_days,String(father.get("name","Unrecorded")),int(mother.get("household_id",-1)),String(mother.get("role","Unassigned"))]
			pregnancy_body.add_theme_font_size_override("font_size",13)
			pregnancy_body.add_theme_color_override("font_color",Color("#d8ddcf"))
			pregnancy_card.add_child(pregnancy_body)
		entries.add_child(HSeparator.new())
	if GameState.demographic_ledger.is_empty():
		var quiet:=Label.new()
		quiet.text="No births or deaths have occurred. Pregnancies and mortality risks continue to develop person by person."
		quiet.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		quiet.add_theme_color_override("font_color",Color("#9b9e98"))
		entries.add_child(quiet)
	else:
		for record_variant in GameState.demographic_ledger:
			var record:Dictionary=record_variant
			var kind:=String(record.get("kind","death"))
			var count:=int(record.get("count",1))
			var cause:=String(record.get("cause","Unknown"))
			var start_day:=int(record.get("start_day",record.get("day",0)))+1
			var end_day:=int(record.get("end_day",record.get("day",0)))+1
			var period:="DAY %d" % end_day if start_day==end_day else "DAYS %d–%d" % [start_day,end_day]
			var accent:=Color("#b8a36d") if kind=="birth" else Color("#a95f52")
			var card:=PanelContainer.new()
			card.size_flags_horizontal=Control.SIZE_EXPAND_FILL
			card.add_theme_stylebox_override("panel",_population_report_style(accent))
			entries.add_child(card)
			var body:=VBoxContainer.new()
			body.add_theme_constant_override("separation",4)
			card.add_child(body)
			var title:=Label.new()
			var noun:="BIRTH" if kind=="birth" else "DEATH"
			var cause_label:="SUPPORTED BY CURRENT CONDITIONS" if kind=="birth" and cause=="Births" else cause.to_upper()
			title.text="%s   •   %d %s%s   •   %s" % [period,count,noun,"" if count==1 else "S",cause_label]
			title.add_theme_font_size_override("font_size",16)
			title.add_theme_color_override("font_color",Color("#eee2cb"))
			body.add_child(title)
			var where:=Label.new()
			where.text="WHERE  %s     •     POPULATION AFTER  %s" % [String(record.get("location","Unknown location")),_compact_population(int(record.get("population_after",GameState.population_total)))]
			where.add_theme_font_size_override("font_size",13)
			where.add_theme_color_override("font_color",Color("#c5b98f"))
			body.add_child(where)
			var why:=Label.new()
			why.text="WHY  %s" % String(record.get("description","No causal record was preserved."))
			why.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
			why.add_theme_font_size_override("font_size",13)
			body.add_child(why)
			var conditions:=Label.new()
			conditions.text="CONDITIONS  Stores %.1f days  •  Daily supply %d%% of need  •  Health %d%%  •  Shelter %d%%" % [float(record.get("food_days",0.0)),roundi(float(record.get("production_ratio",0.0))*100.0),roundi(float(record.get("health",0.0))*100.0),roundi(float(record.get("housing_ratio",0.0))*100.0)]
			conditions.add_theme_font_size_override("font_size",12)
			conditions.add_theme_color_override("font_color",Color("#a7aaa2"))
			body.add_child(conditions)
	var wider_events:Array[Dictionary]=[]
	for event_variant in GameState.simulation_events:
		var event:Dictionary=event_variant
		if String(event.get("domain",""))!="population":
			wider_events.append(event)
		if wider_events.size()>=12:
			break
	if not wider_events.is_empty():
		entries.add_child(HSeparator.new())
		var chronicle_title:=Label.new()
		chronicle_title.text="WIDER CONSEQUENCE CHRONICLE"
		chronicle_title.add_theme_font_size_override("font_size",17)
		chronicle_title.add_theme_color_override("font_color",Color("#cfbd8c"))
		entries.add_child(chronicle_title)
		for event in wider_events:
			var event_line:=Label.new()
			event_line.text="DAY %d  •  %s\n%s" % [int(event.get("day",0))+1,String(event.get("title","Event")).to_upper(),String(event.get("description",""))]
			event_line.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
			event_line.add_theme_font_size_override("font_size",13)
			event_line.add_theme_color_override("font_color",Color("#c7c7bf"))
			entries.add_child(event_line)
	var footer:=HBoxContainer.new()
	footer.alignment=BoxContainer.ALIGNMENT_END
	root.add_child(footer)
	var close:=Button.new()
	close.text="CLOSE"
	close.custom_minimum_size=Vector2(150,40)
	close.pressed.connect(func(): population_ledger_panel.queue_free(); population_ledger_panel=null)
	footer.add_child(close)

func _update_time_interface() -> void:
	if date_label == null:
		return
	var absolute_hour:=int(floor(GameState.elapsed_days*24.0))
	var absolute_day:=absolute_hour/24
	var year := absolute_day / 365 + 1
	var day_of_year := absolute_day % 365 + 1
	var hour_of_day:=absolute_hour%24
	date_label.text = "YEAR %d  •  DAY %d  •  %02d:00" % [year, day_of_year,hour_of_day]
	_refresh_knowledge_record()
	for speed_key in time_speed_buttons:
		var speed_button:Button=time_speed_buttons[speed_key]
		speed_button.button_pressed=int(game_speed)==int(speed_key)
	if population_summary_label:
		var balance := float(GameState.simulation_metrics.get("food_balance",-1.0))
		var balance_mark := "▲" if balance>=0.0 else "▼"
		population_summary_label.text = "POP %s  •  HEALTH %d%%  •  LIFE %.0fY" % [_compact_population(GameState.population_total),roundi(GameState.population_health*100.0),GameState.projected_life_expectancy()]
		if provisions_button:
			var net:=float(GameState.simulation_metrics.get("food_net",0.0))
			provisions_button.text="FOOD  %.1f DAYS %s  •  %+.1f TODAY" % [float(GameState.simulation_metrics.get("food_days",30.0)),balance_mark,net]
		if materials_button:
			var material_metrics:=GameState.material_metrics
			var known_count:=ResourceSystem.visible_deposits().size()
			materials_button.text="MATERIALS  %d KNOWN  •  %.1f STORED" % [known_count,float(material_metrics.get("stored_bulk",0.0))]
	if convoy_map_label:
		var settlement_classification:String = String(_settlement_model().classification()).to_upper() if "Hearth Circle" in GameState.settlement_completed else ""
		convoy_map_label.text="%s  •  %s  •  %s" % [_settlement_display_name(),settlement_classification,_compact_population(GameState.population_total)] if settlement_classification!="" else "%s  •  %s" % [_settlement_display_name(),_compact_population(GameState.population_total)]
	if people_panel_title:
		people_panel_title.text=_settlement_display_name()
	if people_summary_label:
		var settlement_status := "Traveling convoy" if travel_active else ("Founding settlement" if GameState.settlement_site_committed and GameState.settlement_completed.is_empty() else ("Halted convoy" if GameState.settlement_completed.is_empty() else "Growing settlement"))
		var produced := float(GameState.simulation_metrics.get("food_production",0.0))
		var consumed := float(GameState.simulation_metrics.get("food_consumption",GameState.population_total))
		var pregnancy_summary:=GameState.pregnancy_summary()
		people_summary_label.text = "%s souls  •  %s able  •  %s\nPregnancies %d  •  Expected births %.1f / 12m\nFood %.0f / %.0f  •  Labor %d%%" % [_compact_population(GameState.population_total), _compact_population(_able_population()), settlement_status,int(pregnancy_summary.active),float(GameState.simulation_metrics.get("births_expected_next_year",pregnancy_summary.due_within_year)),produced,consumed,roundi(float(GameState.simulation_metrics.get("labor_efficiency",0.72))*100.0)]
	if travel_active:
		var remaining := maxf(0.0, travel_days_total - travel_days_elapsed)
		var speed_factor:=roundi(float(GameState.simulation_metrics.get("travel_speed_factor",1.0))*100.0)
		travel_status_label.text = "CONVOY MOVING  •  %s remaining  •  pace %d%%  •  stores %.1f days" % [_format_game_duration(remaining),speed_factor,float(GameState.simulation_metrics.get("food_days",0.0))]
	elif GameState.convoy_emergency_halt_reason!="":
		travel_status_label.text="CONVOY HALTED  •  %s  •  PAUSED" % GameState.convoy_emergency_halt_reason
	elif GameState.settlement_site_committed and "Hearth Circle" not in GameState.settlement_completed:
		travel_status_label.text="SETTLEMENT FOUNDING  •  HEARTH CIRCLE EMERGING FROM CURRENT ROLES"
	elif placement_building == "":
		travel_status_label.text = ""
	if start_settlement_button:
		start_settlement_button.visible=not GameState.settlement_site_committed and settler_marker!=null
		if travel_active:
			start_settlement_button.text="START SETTLEMENT\nHalt the moving convoy here and begin"
		else:
			start_settlement_button.text="START SETTLEMENT\nFound at the convoy's current location"

func _settlement_display_name() -> String:
	if GameState.settlement_name.strip_edges()!="":
		return GameState.settlement_name.strip_edges().to_upper()
	if "Hearth Circle" in GameState.settlement_completed:
		return _settlement_model().classification().to_upper()
	if GameState.settlement_site_committed:
		return "FOUNDING SITE"
	return "FOUNDING CONVOY"

func _set_game_speed(speed: float) -> void:
	game_speed=clampf(speed,0.0,5.0)
	_update_time_interface()

func _speed_hours_per_second() -> float:
	return float(SPEED_HOURS_PER_REAL_SECOND.get(int(game_speed),0.0))

func _format_game_duration(days: float) -> String:
	var total_hours:=maxi(0,ceili(days*24.0))
	if total_hours<48:
		return "%d hours" % total_hours
	var whole_days:=total_hours/24
	var hours:=total_hours%24
	return "%d days %d hours" % [whole_days,hours]

func _compact_population(value: int) -> String:
	if value >= 1000000:
		return "%.1fM" % (float(value) / 1000000.0)
	if value >= 10000:
		return "%.1fK" % (float(value) / 1000.0)
	return str(value)

func _open_society_panel()->void:
	if society_panel and is_instance_valid(society_panel): society_panel.queue_free()
	if GameState.society_subcategories.is_empty():
		GameState.society_subcategories=DiscoverySystem.society_model.evaluate_subcategories(_discovery_context())
	society_panel=Control.new()
	society_panel.size=get_viewport().get_visible_rect().size
	society_panel.mouse_filter=Control.MOUSE_FILTER_STOP
	interface_layer.add_child(society_panel)
	var dimmer:=ColorRect.new()
	dimmer.size=society_panel.size
	dimmer.color=Color(0.006,0.009,0.011,0.91)
	society_panel.add_child(dimmer)
	var modal:=PanelContainer.new()
	modal.position=Vector2(18,14)
	modal.size=society_panel.size-Vector2(36,28)
	modal.add_theme_stylebox_override("panel",_knowledge_style(Color("#0b1215"),Color("#75694f"),1,4,14))
	society_panel.add_child(modal)
	var root:=VBoxContainer.new()
	root.add_theme_constant_override("separation",8)
	modal.add_child(root)
	var header:=HBoxContainer.new()
	header.custom_minimum_size=Vector2(0,58)
	root.add_child(header)
	var heading:=VBoxContainer.new()
	heading.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	header.add_child(heading)
	var eyebrow:=Label.new()
	eyebrow.text="THE STATE OF THE CIVILIZATION"
	eyebrow.add_theme_font_size_override("font_size",10)
	eyebrow.add_theme_color_override("font_color",Color("#b9a56c"))
	heading.add_child(eyebrow)
	var title:=Label.new()
	title.text="SOCIETY DYNAMICS"
	title.add_theme_font_size_override("font_size",24)
	title.add_theme_color_override("font_color",Color("#f0e5cf"))
	heading.add_child(title)
	var subtitle:=Label.new()
	subtitle.text="Every score is an outcome of people, resources, institutions, environment, and adopted knowledge."
	subtitle.add_theme_font_size_override("font_size",11)
	subtitle.add_theme_color_override("font_color",Color("#929d98"))
	heading.add_child(subtitle)
	var average:=0.0
	for dynamic_id in GameState.society_capacities: average+=float(GameState.society_capacities[dynamic_id])
	average/=maxf(1.0,float(GameState.society_capacities.size()))
	var overall:=VBoxContainer.new()
	overall.custom_minimum_size=Vector2(170,0)
	header.add_child(overall)
	var overall_label:=Label.new()
	overall_label.text="SYSTEMIC CAPACITY"
	overall_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	overall_label.add_theme_font_size_override("font_size",10)
	overall_label.add_theme_color_override("font_color",Color("#8f9994"))
	overall.add_child(overall_label)
	var overall_value:=Label.new()
	overall_value.text="%d%%" % roundi(average*100.0)
	overall_value.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	overall_value.add_theme_font_size_override("font_size",24)
	overall_value.add_theme_color_override("font_color",_dynamic_score_color(average))
	overall.add_child(overall_value)
	root.add_child(HSeparator.new())
	var scroll:=ScrollContainer.new()
	scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	var grid:=GridContainer.new()
	grid.columns=4
	grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation",8)
	grid.add_theme_constant_override("v_separation",8)
	scroll.add_child(grid)
	for dynamic_id in ["demography","nutrition","health","labor","knowledge","production","infrastructure","logistics","ecology","institutions","security","culture"]:
		_make_dynamic_card(grid,dynamic_id)
	var footer:=HBoxContainer.new()
	root.add_child(footer)
	var note:=Label.new()
	note.text="▲ improving  •  ▼ declining  •  Hover any ? for its definition, drivers, and consequences."
	note.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	note.add_theme_font_size_override("font_size",10)
	note.add_theme_color_override("font_color",Color("#87918c"))
	footer.add_child(note)
	var close:=Button.new()
	close.text="CLOSE"
	close.custom_minimum_size=Vector2(150,36)
	close.pressed.connect(func(): society_panel.queue_free(); society_panel=null)
	footer.add_child(close)

func _make_dynamic_card(parent:Container,dynamic_id:String)->void:
	var score:=clampf(float(GameState.society_capacities.get(dynamic_id,0.0)),0.0,1.0)
	var accent:=_dynamic_accent(dynamic_id)
	var card:=PanelContainer.new()
	card.custom_minimum_size=Vector2(276,184)
	card.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel",_knowledge_style(Color("#111a1d"),accent.darkened(0.42),1,3,9))
	card.tooltip_text=_dynamic_definition(dynamic_id)
	parent.add_child(card)
	var content:=VBoxContainer.new()
	content.add_theme_constant_override("separation",3)
	card.add_child(content)
	var heading:=HBoxContainer.new()
	content.add_child(heading)
	var name:=Label.new()
	name.text=dynamic_id.to_upper()+"  ?"
	name.tooltip_text=_dynamic_definition(dynamic_id)
	name.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	name.add_theme_font_size_override("font_size",12)
	name.add_theme_color_override("font_color",Color("#e4dccb"))
	heading.add_child(name)
	var trend:=float(GameState.simulation_trends.get("society_"+dynamic_id,0.0))
	var trend_label:=Label.new()
	trend_label.text=("▲ " if trend>0.0005 else ("▼ " if trend<-0.0005 else ""))+"%d%%" % roundi(score*100.0)
	trend_label.add_theme_font_size_override("font_size",14)
	trend_label.add_theme_color_override("font_color",_dynamic_score_color(score))
	heading.add_child(trend_label)
	var definition:=Label.new()
	definition.text=_dynamic_definition(dynamic_id).get_slice("\n",0)
	definition.custom_minimum_size=Vector2(0,26)
	definition.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	definition.add_theme_font_size_override("font_size",9)
	definition.add_theme_color_override("font_color",Color("#84908b"))
	definition.tooltip_text=_dynamic_definition(dynamic_id)
	content.add_child(definition)
	var main_bar:=ProgressBar.new()
	main_bar.max_value=1.0
	main_bar.value=score
	main_bar.show_percentage=false
	main_bar.custom_minimum_size=Vector2(0,7)
	main_bar.add_theme_stylebox_override("background",_knowledge_style(Color("#202a2c"),Color.TRANSPARENT,0,3,0))
	main_bar.add_theme_stylebox_override("fill",_knowledge_style(accent,Color.TRANSPARENT,0,3,0))
	content.add_child(main_bar)
	var breakdown:Dictionary=GameState.society_subcategories.get(dynamic_id,{})
	for subcategory in breakdown:
		var sub_score:=clampf(float(breakdown[subcategory]),0.0,1.0)
		var sub_definition:=_subcategory_definition(dynamic_id,String(subcategory))
		var subcategory_display:="Resource sustainability" if dynamic_id=="ecology" and String(subcategory)=="Resource pressure" else String(subcategory)
		var row:=HBoxContainer.new()
		row.add_theme_constant_override("separation",6)
		row.tooltip_text=sub_definition
		content.add_child(row)
		var sub_name:=Label.new()
		sub_name.text=subcategory_display+"  ?"
		sub_name.tooltip_text=sub_definition
		sub_name.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		sub_name.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
		sub_name.add_theme_font_size_override("font_size",9)
		sub_name.add_theme_color_override("font_color",Color("#9ba39e"))
		row.add_child(sub_name)
		var sub_bar:=ProgressBar.new()
		sub_bar.max_value=1.0
		sub_bar.value=sub_score
		sub_bar.show_percentage=false
		sub_bar.tooltip_text=sub_definition
		sub_bar.custom_minimum_size=Vector2(70,4)
		sub_bar.add_theme_stylebox_override("background",_knowledge_style(Color("#20292b"),Color.TRANSPARENT,0,2,0))
		sub_bar.add_theme_stylebox_override("fill",_knowledge_style(accent.darkened(0.12),Color.TRANSPARENT,0,2,0))
		row.add_child(sub_bar)
		var sub_value:=Label.new()
		sub_value.text="%d" % roundi(sub_score*100.0)
		sub_value.tooltip_text=sub_definition
		sub_value.custom_minimum_size=Vector2(24,0)
		sub_value.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
		sub_value.add_theme_font_size_override("font_size",9)
		sub_value.add_theme_color_override("font_color",Color("#c5c8bd"))
		row.add_child(sub_value)

func _dynamic_accent(dynamic_id:String)->Color:
	return {"demography":Color("#bd8b72"),"nutrition":Color("#a7a75f"),"health":Color("#70a58d"),"labor":Color("#b58b61"),"knowledge":Color("#719eae"),"production":Color("#ae855f"),"infrastructure":Color("#9a8d78"),"logistics":Color("#7b969d"),"ecology":Color("#719269"),"institutions":Color("#9a82a6"),"security":Color("#a66f67"),"culture":Color("#b19a6f")}.get(dynamic_id,Color("#8c9691"))

func _dynamic_score_color(score:float)->Color:
	if score<0.30: return Color("#d87867")
	if score<0.55: return Color("#d2ae68")
	return Color("#83ad82")

func _dynamic_definition(dynamic_id:String)->String:
	return {
		"demography":"Whether the population can renew itself safely across generations.\nDriven by fertility conditions, safe pregnancy, child survival, and shelter. It shapes births, deaths, age structure, and future labor.",
		"nutrition":"Whether people receive enough varied food reliably.\nDriven by daily supply, diet quality, reserves, and productive land. It shapes health, fertility, labor, and resilience to shortages.",
		"health":"The population’s physical survival and freedom from preventable harm.\nDriven by general condition, clean water, disease control, and injury safety. It shapes mortality, life expectancy, labor, and discovery.",
		"labor":"How much useful human effort society can sustain.\nDriven by the working-age share, efficiency, coordination, and workload. It powers every physical activity while competing for limited people.",
		"knowledge":"The ability to observe, retain, connect, and spread understanding.\nDriven by observers, focused inquiry, preserved learning, and communication. It governs discovery chances and adoption of new practices.",
		"production":"The ability to transform resources into useful goods consistently.\nDriven by materials, tools, skilled craft, and standards. It raises output and unlocks more complex resource and building chains.",
		"infrastructure":"The durable physical systems supporting settlement life.\nDriven by housing, construction, public works, and resilience. It expands capacity and protects society from distance, weather, and disaster.",
		"logistics":"The ability to move and preserve people, food, information, and materials.\nDriven by carrying, routes, storage, and trade reach. It determines whether distant resources are actually usable.",
		"ecology":"How safely society fits within the living landscape.\nDriven by land health, recovery, pollution control, and sustainable extraction. It governs long-term food and resource yields.",
		"institutions":"The ability to coordinate collective decisions and make them endure.\nDriven by administration, legitimacy, state capacity, and flexibility. It shapes order, allocation, reform, and crisis response.",
		"security":"Protection from violence, disorder, accident, and sudden crisis.\nDriven by public safety, defense organization, military readiness, and resilience. It shapes mortality, stability, and survival under threat.",
		"culture":"The shared identity and memory that make collective action possible.\nDriven by cohesion, accepted authority, intellectual breadth, and memory. It shapes legitimacy, cooperation, and the directions society pursues."
	}.get(dynamic_id,"A major capacity produced by the interacting population, environment, resources, institutions, and knowledge systems.")

func _subcategory_definition(dynamic_id:String,subcategory:String)->String:
	var definitions:Dictionary={
		"demography":{
			"Fertility conditions":"Readiness for family formation and conception. Raised by secure food, adequate shelter, good health, and supportive discoveries. It changes conception frequency and future population growth.",
			"Maternal safety":"Protection during pregnancy and childbirth. Raised by health and learned maternal practices. It lowers pregnancy loss and maternal death.",
			"Child survival":"A newborn or child’s chance of reaching working age. Raised by health, nutrition, shelter, and neonatal knowledge. It changes mortality and the future workforce.",
			"Shelter capacity":"Housing spaces compared with the living population. Shortfalls increase exposure and suppress health and fertility; surplus allows safe growth."
		},
		"nutrition":{
			"Daily supply":"The share of current food needs being met each day. Labor, accessible food sources, season, travel, and ecology alter it. Deficits consume reserves and cause malnutrition.",
			"Diet quality":"The nutritional variety and value of what people eat, beyond raw calories. Diverse sources and food knowledge raise it; poor diets reduce health and pregnancy outcomes.",
			"Stored reserve":"How long preserved food can absorb a production failure. Storage capacity and preservation raise it; consumption, spoilage, and travel drain it.",
			"Land productivity":"The landscape’s ability to keep yielding food. Ecology, soil, season, and cultivation knowledge raise it; overuse and degradation lower it."
		},
		"health":{
			"General health":"The population-wide physical condition produced by food, shelter, disease, exposure, and care. It affects mortality, fertility, work, travel, and life expectancy.",
			"Water & sanitation":"Safety of drinking water and waste handling. Water and sanitation discoveries raise it; contamination lowers it. It strongly changes disease and child survival.",
			"Disease control":"Capacity to prevent and contain infection. Health practices and sanitation raise it; crowding and exposure undermine it. It reduces illness mortality and labor loss.",
			"Injury safety":"Protection from work, travel, building, and extraction accidents. Safer techniques and tools raise it; hazardous industry lowers it."
		},
		"labor":{
			"Able workforce":"The share of living people aged 14–59 who can hold assigned roles. Children and elders remain population but are not included in allocatable labor.",
			"Work efficiency":"Useful output from each assigned worker. Health, food, housing, tools, and cohesion raise it; illness, hunger, and exhaustion lower it.",
			"Coordination":"How effectively separate workers combine their effort. Cohesion, administration, communication, and task knowledge raise it.",
			"Workload balance":"Whether labor demands remain sustainable. A high score means duties are manageable; excessive construction, extraction, or fatigue lowers it."
		},
		"knowledge":{
			"Observers":"People assigned to inquiry compared with the population needed to sustain investigation. More observers create more discovery opportunities but leave other roles understaffed.",
			"Directed attention":"How much observer capacity supports each active inquiry direction. Too many simultaneous directions dilute it and make specific discoveries slower.",
			"Preserved knowledge":"How reliably learning survives individuals and generations. Records, teaching, memory practices, and existing knowledge raise it; loss slows adoption and later discovery.",
			"Communication":"How quickly information moves and becomes shared practice. Routes, standards, institutions, and communication discoveries raise it."
		},
		"production":{
			"Material supply":"The usable timber, stone, clay, fibers, metals, and other inputs reaching workers. Discovery, access, extraction, and delivery all matter.",
			"Tool quality":"The effectiveness and durability of working implements. Better tools multiply extraction, construction, farming, and craft output.",
			"Craft capacity":"The society’s ability to turn raw materials into useful goods. It requires makers, materials, tools, knowledge, and work space.",
			"Standardization":"Consistency of measurements, parts, and methods. It reduces waste and coordination errors while enabling increasingly complex production."
		},
		"infrastructure":{
			"Housing":"Permanent shelter compared with population need. It supports health, fertility, storage, and resilience while unchecked growth can create shortages.",
			"Construction":"Current capacity to complete durable works. Builders, labor efficiency, materials, tools, and construction knowledge determine it.",
			"Public works":"The breadth of completed shared facilities such as storage, gathering yards, roads, water works, and civic spaces.",
			"Resilience":"How well buildings and systems withstand weather, fire, flood, failure, and disaster. Robust design and redundancy raise it."
		},
		"logistics":{
			"Carrying capacity":"How much can be transported by available people, containers, animals, vehicles, and handling systems. It limits resource throughput.",
			"Route quality":"The speed and reliability of movement across known paths. Terrain, roads, bridges, navigation, and maintenance determine it.",
			"Storage system":"Capacity to preserve and account for food and materials. A high score means greater capacity and lower loss to spoilage, weather, and theft.",
			"Trade reach":"The distance and volume over which regular exchange can operate. Routes, transport, security, surplus, and institutions expand it."
		},
		"ecology":{
			"Land health":"The present condition of soil, vegetation, water, and wildlife. Extraction, settlement, pollution, and recovery continually change it.",
			"Natural recovery":"How quickly used ecosystems replenish themselves. Healthy land and ecological knowledge raise it; repeated intensive use can exceed it.",
			"Pollution control":"Ability to prevent or contain harmful waste in land, air, and water. A high score means lower exposure and ecological damage.",
			"Resource sustainability":"The safety margin between extraction and natural renewal. A high score means current use is sustainable; overharvest lowers it."
		},
		"institutions":{
			"Administration":"Steward staffing relative to the population’s coordination burden. It improves allocation, records, stores, and implementation of orders.",
			"Legitimacy":"How broadly people accept the society’s authority and decisions. Food, health, security, cohesion, fairness, and outcomes alter it.",
			"State capacity":"The ability to turn collective decisions into consistent action across people and territory. Organization and administrative discoveries raise it.",
			"Institutional flexibility":"Ability to adapt rules and offices when conditions change. A high score supports reform; rigidity can preserve order but obstruct adaptation."
		},
		"security":{
			"Public safety":"Everyday protection from violence, disorder, and predation. Watch staffing, legitimacy, cohesion, and institutions support it.",
			"Organized defense":"Ability to coordinate defenders, fortifications, supplies, and command beyond individual readiness.",
			"Military readiness":"Preparedness to mobilize for organized conflict. Training, weapons, intelligence, logistics, and relevant discoveries raise it.",
			"Crisis resilience":"Ability to maintain order and essential functions through disaster or attack. Cohesion, resilient infrastructure, reserves, and planning raise it."
		},
		"culture":{
			"Social cohesion":"Trust and willingness to cooperate across the population. Security, shared success, manageable hardship, and institutions shape it.",
			"Shared legitimacy":"Cultural acceptance of common authority and collective decisions. It converts formal institutions into willing cooperation.",
			"Inquiry breadth":"How many broad questions receive attention. Breadth creates diverse possibilities, but spreading limited observers too widely reduces directed attention.",
			"Collective memory":"The society’s ability to retain stories, techniques, decisions, and identity across generations. Teaching and preservation raise it."
		}
	}
	var display_name:="Resource sustainability" if dynamic_id=="ecology" and subcategory=="Resource pressure" else subcategory
	var dynamic_definitions:Dictionary=definitions.get(dynamic_id,{})
	return String(dynamic_definitions.get(display_name,"A contributing measure inside %s. Higher values represent greater social capacity or safety." % dynamic_id.capitalize()))

func _open_world_menu()->void:
	if world_menu_panel and is_instance_valid(world_menu_panel): return
	world_menu_previous_speed=game_speed
	_set_game_speed(0.0)
	world_menu_panel=Control.new()
	world_menu_panel.size=get_viewport().get_visible_rect().size
	world_menu_panel.mouse_filter=Control.MOUSE_FILTER_STOP
	interface_layer.add_child(world_menu_panel)
	var dimmer:=ColorRect.new()
	dimmer.size=world_menu_panel.size
	dimmer.color=Color(0.006,0.009,0.011,0.88)
	world_menu_panel.add_child(dimmer)
	var modal:=PanelContainer.new()
	modal.size=Vector2(590,610)
	modal.position=(world_menu_panel.size-modal.size)*0.5
	modal.add_theme_stylebox_override("panel",_knowledge_style(Color("#0b1215"),Color("#817353"),1,4,22))
	world_menu_panel.add_child(modal)
	var content:=VBoxContainer.new()
	content.add_theme_constant_override("separation",8)
	modal.add_child(content)
	var eyebrow:=Label.new()
	eyebrow.text="GAME MENU"
	eyebrow.add_theme_font_size_override("font_size",11)
	eyebrow.add_theme_color_override("font_color",Color("#b9a56c"))
	content.add_child(eyebrow)
	var title:=Label.new()
	title.text="PAUSED"
	title.add_theme_font_size_override("font_size",26)
	title.add_theme_color_override("font_color",Color("#f0e5cf"))
	content.add_child(title)
	var explanation:=Label.new()
	explanation.text="%s • Year %d, Day %d • Population %d" % [_settlement_display_name(),int(GameState.elapsed_days/365.0)+1,int(GameState.elapsed_days)%365+1,GameState.population_total]
	explanation.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	explanation.add_theme_font_size_override("font_size",12)
	explanation.add_theme_color_override("font_color",Color("#a6ada8"))
	content.add_child(explanation)
	content.add_child(HSeparator.new())
	var seed_label:=Label.new()
	seed_label.text="NEW GAME  •  WORLD SEED"
	seed_label.add_theme_font_size_override("font_size",11)
	seed_label.add_theme_color_override("font_color",Color("#c8b77e"))
	content.add_child(seed_label)
	world_seed_input=LineEdit.new()
	world_seed_input.text=str(GameState.world_seed)
	world_seed_input.placeholder_text="Enter a whole number"
	world_seed_input.custom_minimum_size=Vector2(0,38)
	world_seed_input.add_theme_font_size_override("font_size",15)
	content.add_child(world_seed_input)
	world_seed_status=Label.new()
	world_seed_status.text="Seed %d defines terrain, resources, founders, and historical possibilities. Starting again permanently erases this civilization." % GameState.world_seed
	world_seed_status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	world_seed_status.add_theme_font_size_override("font_size",11)
	world_seed_status.add_theme_color_override("font_color",Color("#8f9994"))
	content.add_child(world_seed_status)
	var same_seed:=Button.new()
	same_seed.text="RESTART THIS WORLD"
	same_seed.custom_minimum_size=Vector2(0,38)
	same_seed.tooltip_text="Erase this civilization and recreate Day 1 with the current seed."
	same_seed.pressed.connect(_restart_world.bind(GameState.world_seed))
	content.add_child(same_seed)
	var selected_seed:=Button.new()
	selected_seed.text="START WITH ENTERED SEED"
	selected_seed.custom_minimum_size=Vector2(0,38)
	selected_seed.pressed.connect(_restart_with_entered_seed)
	content.add_child(selected_seed)
	var random_seed:=Button.new()
	random_seed.text="GENERATE A NEW WORLD"
	random_seed.custom_minimum_size=Vector2(0,40)
	random_seed.add_theme_color_override("font_color",Color("#f0d78f"))
	random_seed.pressed.connect(_restart_random_world)
	content.add_child(random_seed)
	content.add_child(HSeparator.new())
	var controls_title:=Label.new()
	controls_title.text="CONTROLS"
	controls_title.add_theme_font_size_override("font_size",11)
	controls_title.add_theme_color_override("font_color",Color("#c8b77e"))
	content.add_child(controls_title)
	var controls:=Label.new()
	controls.text="Left-click terrain  •  Order the convoy / inspect land\nMiddle-drag or arrows  •  Move the map    Shift+middle  •  Rotate\nMouse wheel  •  Zoom    0–5  •  Pause and hourly time speeds    Esc  •  Menu"
	controls.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	controls.add_theme_font_size_override("font_size",11)
	controls.add_theme_color_override("font_color",Color("#9fa7a2"))
	content.add_child(controls)
	var cancel:=Button.new()
	cancel.text="RESUME GAME"
	cancel.custom_minimum_size=Vector2(0,42)
	cancel.pressed.connect(_close_world_menu)
	content.add_child(cancel)
	world_seed_input.grab_focus()
	world_seed_input.select_all()

func _close_world_menu()->void:
	if world_menu_panel and is_instance_valid(world_menu_panel): world_menu_panel.queue_free()
	world_menu_panel=null
	world_seed_input=null
	world_seed_status=null
	_set_game_speed(world_menu_previous_speed)

func _restart_with_entered_seed()->void:
	if not world_seed_input or not world_seed_input.text.strip_edges().is_valid_int():
		world_seed_status.text="Enter a valid whole-number seed."
		world_seed_status.add_theme_color_override("font_color",Color("#d48672"))
		return
	var selected:=int(world_seed_input.text.strip_edges())
	selected=clampi(selected,-2147483647,2147483647)
	if selected==0: selected=1
	_restart_world(selected)

func _restart_world(selected_seed:int)->void:
	GameState.reset_for_new_world(selected_seed)
	DiscoverySystem.reset_for_new_world()
	ResourceSystem.reset_for_new_world()
	_settlement_model().reset_for_new_world()
	AdvisorSystem.reset_for_new_world()
	_food_system().reset_for_new_world()
	ConsequenceEngine.reset_for_new_world()
	WorldFacts.reset_for_new_world()
	GenerativeDirector.reset_for_new_world()
	get_tree().reload_current_scene()

func _restart_random_world()->void:
	var next_seed:int=abs(hash("%d:%d:%d" % [Time.get_unix_time_from_system(),Time.get_ticks_usec(),GameState.world_seed]))%2147483646+1
	if next_seed==GameState.world_seed: next_seed=(GameState.world_seed+104729)%2147483646+1
	_restart_world(next_seed)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			if society_panel and is_instance_valid(society_panel):
				society_panel.queue_free()
				society_panel=null
				get_viewport().set_input_as_handled()
				return
			if world_menu_panel and is_instance_valid(world_menu_panel):
				_close_world_menu()
				get_viewport().set_input_as_handled()
				return
			_open_world_menu()
			get_viewport().set_input_as_handled()
			return
		if world_menu_panel and is_instance_valid(world_menu_panel): return
		if event.keycode >= KEY_0 and event.keycode <= KEY_5:
			_set_game_speed(float(event.keycode - KEY_0))
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			dragging = event.pressed
			rotating_camera = event.shift_pressed
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_focus_camera_toward_screen(event.position, 0.26)
			camera.size = max(0.035, camera.size / 1.22)
			_update_camera()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			camera.size = min(18000.0 if SEAMLESS_WORLD else 128.0, camera.size * 1.22)
			_update_camera()
	elif event is InputEventMouseMotion and dragging:
		if rotating_camera:
			camera_yaw -= event.relative.x * 0.006
			camera_pitch = clampf(camera_pitch - event.relative.y * 0.004, -1.18, -0.48)
			_update_camera()
		else:
			var units_per_pixel:=camera.size/maxf(1.0,float(get_viewport().get_visible_rect().size.y))
			var direction_from_target:=Vector3(cos(camera_yaw),0.0,sin(camera_yaw))
			var screen_right:=Vector3(-direction_from_target.z,0.0,direction_from_target.x)
			var movement:Vector3=-screen_right*event.relative.x*units_per_pixel-direction_from_target*event.relative.y*units_per_pixel
			_set_camera_target(camera_target+movement)

func _unhandled_input(event: InputEvent) -> void:
	if placement_building != "":
		if event is InputEventMouseMotion:
			_update_placement_preview(event.position)
		elif event is InputEventMouseButton and event.pressed:
			if event.button_index == MOUSE_BUTTON_LEFT:
				_update_placement_preview(event.position)
				_confirm_building_placement()
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				_cancel_placement()
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_move_settlers_to_screen(event.position)

func _update_camera() -> void:
	# Orthographic scale and camera altitude are independent. Keeping the camera at
	# the old 92 km overview altitude while showing a 100 m footprint collapsed all
	# metre-scale landscape layers into the terrain depth buffer. Follow the visible
	# footprint down toward the ground, Google-Earth style, while retaining the same
	# orthographic framing and a high ceiling for planetary views.
	var effective_distance:=clampf(camera.size*1.85+0.8,1.8,50000.0) if SEAMLESS_WORLD else camera_distance
	if SEAMLESS_WORLD:
		camera.near=0.015 if camera.size<=6.0 else 0.10
		camera.far=maxf(240.0,effective_distance*4.0+camera.size*4.0)
	# Continental footprints become progressively more nadir-facing. A strongly
	# oblique camera only a few dozen kilometres above a 20,000 km plane exposed its
	# horizon and left half the screen empty; real globe viewers also relax toward a
	# top-down map as the footprint approaches continental scale.
	var continental_nadir:=smoothstep(1300.0,6200.0,camera.size)
	var display_pitch:=lerpf(camera_pitch,-1.555,continental_nadir)
	var horizontal := cos(display_pitch) * effective_distance
	camera.position = camera_target + Vector3(cos(camera_yaw) * horizontal, -sin(display_pitch) * effective_distance, sin(camera_yaw) * horizontal)
	camera.look_at(camera_target, Vector3.UP)

func _focus_camera_toward_screen(screen_position: Vector2, strength: float) -> void:
	if camera == null:
		return
	var hit:=_terrain_hit(screen_position)
	if hit.is_empty():
		return
	var focus: Vector3 = hit.position
	_set_camera_target(camera_target.lerp(focus,strength))
