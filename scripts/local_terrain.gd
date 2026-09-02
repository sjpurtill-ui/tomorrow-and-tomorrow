extends Node3D

const FIT_CONTENT_PANEL:=preload("res://scripts/viewport_fit_panel.gd")
const FoodSystemScript := preload("res://scripts/food_system.gd")
const SocietalValuesModel:=preload("res://scripts/societal_values_model.gd")
const WorldDiscoveryMapScript:=preload("res://scripts/world_discovery_map.gd")
const WarfareMapPresentation:=preload("res://scripts/warfare_map_presentation.gd")

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
const MAIN_RIVER_WATER_HALF_WIDTH_KM := 0.125
const TRIBUTARY_WATER_HALF_WIDTH_KM := 0.035
const MAIN_RIVER_SETTLEMENT_CLEARANCE_KM := 0.25
const TRIBUTARY_SETTLEMENT_CLEARANCE_KM := 0.10
const SPEED_HOURS_PER_REAL_SECOND := {1:0.5,2:2.0,3:8.0,4:24.0,5:72.0}
const SETTLEMENT_DETAIL_SCALE := 0.002
const SETTLEMENT_FABRIC_MAX_ZOOM := 28.0
const SETTLEMENT_INSPECTION_ZOOM := 0.42
const SETTLEMENT_AGGREGATE_DENSITY_BUDGET := 192
const SETTLEMENT_DISTRICT_CLIPMAP_BUDGET := 384
const SECONDARY_SETTLEMENT_FOOTPRINT_PATCH_BUDGET := 512
const SECONDARY_SETTLEMENT_CORRIDOR_BUDGET := 128
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
var hud: Control  # CommandRailHud shell: rail, time pill, KPI strip, queue, toolbar.
var government_panel: Control
var leader_heading: Label
var pending_advisor_office := ""
var last_discovery_day := 0
var knowledge_panel: Control
var knowledge_record_container:VBoxContainer
var knowledge_record_signature:=""
var knowledge_investigation_widgets:Dictionary={}
var knowledge_discovery_widgets:Dictionary={}
var knowledge_record_mode:="discoveries"
var knowledge_record_category:="all"
var knowledge_record_page:=0
var knowledge_mode_buttons:Dictionary={}
var knowledge_category_selector:OptionButton
const KNOWLEDGE_RECORD_PAGE_SIZE:=5
var allocation_value_labels: Dictionary = {}
var population_value_labels: Dictionary = {}
var research_total_label: Label
var council_panel: Control
var pending_pronouncement_inputs: Dictionary={}
var pronouncement_status_label: Label
var date_label: Label
var world_header_label:Label
var time_speed_buttons: Dictionary = {}
var travel_status_label: Label
var route_mesh: MeshInstance3D
var river_course := PackedFloat32Array()
var world_tributary_courses: Array[Array] = []
var river_overlays: Array[MeshInstance3D] = []
var lens_panel: PanelContainer
var lens_body: RichTextLabel
var lens_location_label: Label
var lens_ring: MeshInstance3D
var lens_world_position := Vector3.ZERO
var lens_requested_visible:=false
var map_selection_marker:MeshInstance3D
var map_selection_generation:=0
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
var resource_overlay_root:Node3D
var rendered_resource_overlay_zoom_key:=""
var resource_view_enabled:=true
var resource_view_toggle:Button
const RESOURCE_OVERLAY_MAX_CLUSTERS:=256
const RESOURCE_OVERLAY_MAX_LABELS:=18
var settlement_footprint: MeshInstance3D
var settlement_blip: MeshInstance3D
var settlement_map_label:Label3D
var settlement_border_root:Node3D
var settlement_network_marker_root:Node3D
var settlement_network_fabric_root:Node3D
var rendered_settlement_network_signature:=""
var settlement_convoy_marker:Node3D
var settlement_convoy_icon:Node3D
var settlement_convoy_detail:Node3D
var settlement_convoy_label:Label3D
var settlement_convoy_targeting:=false
var settlement_convoy_preview:MeshInstance3D
var settlement_convoy_preview_material:StandardMaterial3D
var settlement_convoy_hover_valid:=false
var settlement_convoy_hover_position:=Vector3.ZERO
var settlement_convoy_instruction_panel:PanelContainer
var settlement_convoy_instruction_label:Label
var settlement_convoy_confirm_panel:Control
var settlement_convoy_confirm_status:Label
var settlement_convoy_confirm_button:Button
var settlement_convoy_pending_destination:=Vector3.ZERO
var settlement_convoy_pending_route:Dictionary={}
var settlement_convoy_pending_quote:Dictionary={}
var settlement_convoy_confirmation_previous_speed:=0.0
var settlement_fabric_shader:Shader
var vegetation_surface_shader:Shader
var settlement_land_use_root: Node3D
var footprint_population := -1
var rendered_morphology_revision := -1
var rendered_settlement_lod := -1
var rendered_architecture_signature := ""
var rendered_settlement_view_signature := ""
var rendered_morphology_visual_signature := ""
var cached_morphology_visual_signature := ""
var cached_morphology_visual_signature_key := ""
var active_architecture_profile:Dictionary={}
var rendered_settlement_aerial_lod:=-1.0
var rendered_settlement_stage_radius:=0.0
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
var event_report_signature:=""
var event_report_visible_until_msec:=0
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
var scale_compass_label: Label
var map_help_button:Button
var map_help_panel:PanelContainer
var map_help_title:Label
var map_help_body:Label
var map_help_dismissed:=false
var travel_council_notice: Button
var travel_council_notice_until_msec := 0
var foreign_alert_panel:PanelContainer
var foreign_alert_title:Label
var foreign_alert_body:Label
var foreign_alert_world_button:Button
var foreign_alert_queue:Array[Dictionary]=[]
var active_foreign_alert:Dictionary={}
var start_settlement_button: Button
var actions_menu_button:Button
var actions_menu_panel:PanelContainer
var actions_menu_status:Label
var actions_menu_settlement_button:Button
var actions_menu_scout_button:Button
var actions_menu_diplomat_button:Button
var scout_dispatch_panel:Control
var scout_dispatch_status:Label
var scout_dispatch_previous_speed:=0.0
var pending_scout_target_id:="open_world"
var diplomat_dispatch_panel:Control
var diplomat_dispatch_status:Label
var diplomat_dispatch_previous_speed:=0.0
var pending_diplomat_civ_id:=""
var pending_diplomat_action:="goodwill"
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
var founding_focus_panel:Control
var founding_focus_selection:=""
var founding_focus_detail:Label
var founding_focus_confirm:Button
var founding_focus_buttons:Dictionary={}
var settlement_dashboard_panel:Control
var systems_hub_panel:Control
var society_panel:Control
var progression_panel:Control
var civilizations_panel:Control
var civilization_report_panel:Control
var civilization_detail_root:VBoxContainer
var selected_civilization_id:=""
var selected_civilization_region_id:=""
var civilization_feedback_text:=""
var world_competition_button:Button
var capture_render_active:=false
var discovery_mask_texture:ImageTexture
var terrain_fog_materials:Array[ShaderMaterial]=[]
var rendered_fog_revision:=-1
var foreign_formation_markers:Dictionary={}
var contact_encounter_markers:Dictionary={}
var rendered_contact_encounter_signature:=""
var player_field_army_markers:Dictionary={}
var player_field_army_paths:Dictionary={}
var warfare_front_markers:Dictionary={}
var rendered_observation_revision:=-1
const LIVE_REPORT_REFRESH_INTERVAL_SECONDS:=0.75
var live_report_refresh_elapsed:=0.0
var live_report_refresh_signatures:Dictionary={}
var live_report_refresh_in_progress:=false
var live_report_pending_replacements:Dictionary={}
var society_panel_mode:="overview"
var active_progression_domain:="demography"

func _ready() -> void:
	_trace_load("ready")
	var requested_founding_focus:=""
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture="):
			capture_render_active=true
		elif argument.begins_with("--founding-focus="):
			requested_founding_focus=argument.trim_prefix("--founding-focus=").strip_edges().to_lower()
	if GameState.founding_focus=="" and (capture_render_active or requested_founding_focus!=""):
		if requested_founding_focus not in GameState.FOUNDING_FOCUS_ORDER: requested_founding_focus="provision"
		GameState.select_founding_focus(requested_founding_focus)
	if SEAMLESS_WORLD:
		_configure_seamless_world()
	elif GameState.province_mask == null or GameState.province_mask.is_empty():
		_configure_preview_province()
	if GameState.founding_banner_index<0:
		GameState.founding_banner_index=abs(GameState.world_seed)%10
	last_discovery_day = int(floor(GameState.elapsed_days))
	DiscoverySystem.initialize()
	ProgressionSystem.process_day(last_discovery_day)
	ConsequenceEngine.initialize()
	if not CivilizationSystem.diplomatic_event.is_connected(_on_diplomatic_event):
		CivilizationSystem.diplomatic_event.connect(_on_diplomatic_event)
	_configure_shape()
	_configure_noise()
	_prepare_river_course()
	CivilizationSystem.set_scout_geography_authority(Callable(self,"_scout_land_at"))
	world_start_position = _find_camp_position()
	CivilizationSystem.register_player_origin(Vector2(world_start_position.x,world_start_position.z))
	_refresh_discovery_mask(true)
	_trace_load("world configured start=%s river_x=%.1f height=%.2f" % [world_start_position,_world_river_x(world_start_position.z),world_start_position.y])
	if SEAMLESS_WORLD:
		# The opening map must be spatially honest: center the camera on the
		# convoy and its known ground. An old cinematic offset placed the convoy
		# on the edge of the fog circle and made movement feel reversed.
		camera_target=world_start_position
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
	_present_next_foreign_alert()
	if GameState.founding_focus=="": _open_founding_focus_panel.call_deferred()
	_refresh_settlement_network(true)
	_refresh_settlement_convoy_marker()
	_trace_load("settlement and interface")
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
	var capture_dock := ""
	var capture_population_ledger := false
	var capture_naming_panel := false
	var capture_knowledge_panel := false
	var capture_world_menu := false
	var capture_society_panel := false
	var capture_military_panel := false
	var capture_provisions_panel := false
	var capture_materials_panel := false
	var capture_council_panel := false
	var capture_government_panel := false
	var capture_candidates_panel := false
	var capture_civilizations_panel := false
	var capture_diplomat_panel := false
	var capture_audit_root:Control
	var capture_travel := false
	var capture_settled := false
	var capture_growth_years := 0
	var capture_plot_lens := false
	var capture_zoom := -1.0
	var capture_pitch_degrees:=INF
	var capture_yaw_degrees:=INF
	var capture_population := -1
	var capture_development_tier := 0
	var capture_era_year := 0
	var capture_stage_override := ""
	var capture_allocations: Dictionary = {}
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture="):
			capture_path = argument.trim_prefix("--capture=")
		elif argument.begins_with("--capture-days="):
			capture_days = maxi(0, int(argument.trim_prefix("--capture-days=")))
		elif argument == "--capture-people":
			capture_people_panel = true
		elif argument.begins_with("--capture-dock="):
			capture_dock = argument.trim_prefix("--capture-dock=")
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
		elif argument == "--capture-military":
			capture_military_panel = true
		elif argument == "--capture-provisions":
			capture_provisions_panel = true
		elif argument == "--capture-materials":
			capture_materials_panel = true
		elif argument == "--capture-council":
			capture_council_panel = true
		elif argument == "--capture-government":
			capture_government_panel = true
		elif argument == "--capture-candidates":
			capture_candidates_panel = true
		elif argument == "--capture-civilizations":
			capture_civilizations_panel = true
		elif argument == "--capture-diplomats":
			capture_diplomat_panel = true
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
		elif argument.begins_with("--capture-development-tier="):
			capture_development_tier=clampi(int(argument.trim_prefix("--capture-development-tier=")),0,12)
		elif argument.begins_with("--capture-era-year="):
			capture_era_year=maxi(0,int(argument.trim_prefix("--capture-era-year=")))
		elif argument.begins_with("--capture-stage="):
			var requested_stage:=argument.trim_prefix("--capture-stage=").strip_edges().to_lower()
			if requested_stage in ["founding camp","hamlet","village","town","city","metropolis","megalopolis"]: capture_stage_override=requested_stage
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
			CivilizationSystem.advance_to_day(int(GameState.elapsed_days))
			var daily_context := _discovery_context()
			DiscoverySystem.process_day(daily_context)
			ResourceSystem.process_day(daily_context)
			_process_population_day(daily_context)
			EconomySystem.process_day(daily_context)
			_evaluate_travel_survival()
			_process_settlement_day()
			_refresh_discovered_resource_overlays()
			_update_time_interface()
			if capture_travel and not travel_active:
				break
		_refresh_event_report()
	if capture_population > 0:
		GameState.ensure_population_total(capture_population)
		GameState.housing_capacity = maxi(GameState.housing_capacity,capture_population + capture_population / 5)
		if capture_population >= 180 and "seed_selection" not in GameState.known_discoveries:
			GameState.known_discoveries.append("seed_selection")
		footprint_population = -1
	if capture_growth_years > 0 and "Hearth Circle" in GameState.settlement_completed:
		for work_name in ["Lean-to Shelters","Storage Pits","Open Work Area","Gathering Yard"]:
			if work_name not in GameState.settlement_completed: GameState.settlement_completed.append(work_name)
		# Explicit capture allocations describe the audited society and must not be
		# replaced by tiny fixture defaults. Defaults only fill omitted roles.
		if not capture_allocations.has("Construction"): GameState.population_allocations["Construction"] = 10
		if not capture_allocations.has("Crafting"): GameState.population_allocations["Crafting"] = 12
		if not capture_allocations.has("Logistics"): GameState.population_allocations["Logistics"] = 10
		GameState.simulation_metrics["labor_efficiency"] = 0.78
		if capture_development_tier>0:
			# Visual audits may stage a coherent capable society, but the morphology
			# model still pays every conversion and obeys the requested elapsed age.
			# This is capture-only fixture state, never a campaign-era unlock.
			GameState.simulation_metrics["logistics"]=clampf(0.18+float(capture_development_tier)*0.085,0.0,0.94)
			var audit_discoveries:=[
				{"tier":1,"id":"cordage"},{"tier":2,"id":"joinery"},{"tier":2,"id":"clay_shaping"},
				{"tier":3,"id":"well_siting"},{"tier":3,"id":"stone_selection"},{"tier":4,"id":"pit_firing"},{"tier":4,"id":"tallies"},
				{"tier":4,"id":"route_memory"},{"tier":5,"id":"labor_rotations"},{"tier":5,"id":"standard_measures"},
				{"tier":6,"id":"framed_construction"},{"tier":6,"id":"material_accounting"},{"tier":7,"id":"graded_roads"},
				{"tier":7,"id":"geometric_survey"},{"tier":8,"id":"workshop_standards"},{"tier":8,"id":"census_rolls"},
				{"tier":9,"id":"public_levies"},{"tier":9,"id":"regional_maps"},{"tier":10,"id":"property_registers"},
				{"tier":10,"id":"craft_guilds"},{"tier":10,"id":"urban_street_plans"},{"tier":11,"id":"precision_machinery"},
				{"tier":11,"id":"public_credit"},{"tier":11,"id":"blast_furnace"},{"tier":12,"id":"professional_service"},
				{"tier":12,"id":"statistical_inference"},{"tier":12,"id":"covered_sewers"}
			]
			for audit_discovery in audit_discoveries:
				if int(audit_discovery.tier)>capture_development_tier: continue
				var discovery_id:String=audit_discovery.id
				if discovery_id not in GameState.known_discoveries: GameState.known_discoveries.append(discovery_id)
				GameState.discovery_adoption[discovery_id]=1.0
			# Rebuild the causal effect totals now. Merely putting a name in the
			# known list must never be enough to unlock later fabric.
			DiscoverySystem.process_day(_discovery_context())
		GameState.resource_stockpiles["Timber"] = 80.0
		GameState.resource_stockpiles["Fiber Plants"] = 80.0
		if capture_development_tier>=3:
			GameState.resource_stockpiles["Clay"]=120.0
			GameState.resource_stockpiles["Stone"]=120.0
		if "seed_selection" not in GameState.known_discoveries: GameState.known_discoveries.append("seed_selection")
		GameState.resource_deposits.append({"id":"capture_fertile_ground","resource":"Fertile Soil","stage":"surveyed","position":GameState.settlement_founded_at+Vector3(2.0,0.0,0.8),"quality":0.92,"remaining":2600.0,"initial_amount":2600.0,"blockers":["cultivation access is still being organized"],"access":0.42,"route":0.18,"development":0.0})
		for growth_month in range(1,capture_growth_years*12+1):
			if growth_month%3==0:
				GameState.ensure_population_total(GameState.population_total+1)
			GameState.resource_stockpiles["Timber"]=maxf(80.0,float(GameState.resource_stockpiles.get("Timber",0.0)))
			GameState.resource_stockpiles["Fiber Plants"]=maxf(80.0,float(GameState.resource_stockpiles.get("Fiber Plants",0.0)))
			if capture_development_tier>=3:
				GameState.resource_stockpiles["Clay"]=maxf(120.0,float(GameState.resource_stockpiles.get("Clay",0.0)))
				GameState.resource_stockpiles["Stone"]=maxf(120.0,float(GameState.resource_stockpiles.get("Stone",0.0)))
			GameState.elapsed_days=float(growth_month*30)
			_settlement_model().process_month(_settlement_spatial_context())
	if capture_era_year>capture_growth_years and capture_development_tier>0 and "Hearth Circle" in GameState.settlement_completed:
		# Advance the inherited fabric audit without simulating every intervening day.
		# Each bounded quarterly pass still uses the same capability gates, consumes
		# real fixture stock, records history and preserves every parcel polygon.
		var era_target_day:=floori(float(capture_era_year*365)/90.0)*90
		GameState.elapsed_days=float(era_target_day)
		# Later generations require repeated replacement of the same inherited
		# parcels. Scale the audit budget by both settlement size and requested
		# depth while retaining an upper bound for automated visual regression.
		var audit_passes:=clampi(GameState.settlement_plots.size()*capture_development_tier/8,40,720)
		for audit_pass in audit_passes:
			for resource_name in ["Timber","Fiber Plants","Clay","Stone"]:
				GameState.resource_stockpiles[resource_name]=maxf(240.0,float(GameState.resource_stockpiles.get(resource_name,0.0)))
			var audit_events:Array[Dictionary]=[]
			_settlement_model()._evolve_inherited_fabric(era_target_day,audit_events)
			if audit_events.is_empty(): break
	if capture_stage_override!="" and "Hearth Circle" in GameState.settlement_completed:
		# Visual-regression captures sometimes need to isolate one silhouette without
		# manufacturing centuries of unrelated market, food-import and institution
		# history. This override exists only behind an explicit capture argument; normal
		# play still receives its class exclusively from the functional model.
		var staged_summary:Dictionary=GameState.settlement_morphology.duplicate(true)
		staged_summary["classification"]=capture_stage_override
		staged_summary["resident_population"]=GameState.population_total
		staged_summary["service_population"]=GameState.population_total
		for key in ["permanence","diversity","exchange","specialization","connectivity","institutions","infrastructure","food_import_share"]: staged_summary[key]=0.0
		staged_summary["district_count"]=1
		GameState.settlement_morphology=staged_summary
	_refresh_settlement_footprint(true)
	# Captures are state audits, not staged mockups. Refresh the HUD after synthetic
	# progression so year, population, food, label, and founding controls describe
	# the same authoritative state as the rendered settlement.
	_update_time_interface()
	if capture_plot_lens and not GameState.settlement_plots.is_empty():
		# The retired Lens is retained only for the explicit visual-regression
		# capture that audits plot metadata; it is never constructed in play.
		if lens_panel==null:
			_build_lens(interface_layer)
		var inspected_plot:Dictionary=GameState.settlement_plots[0]
		for candidate_plot in GameState.settlement_plots:
			if String(candidate_plot.get("land_use",""))=="field": inspected_plot=candidate_plot; break
		var inspected_centroid:=Vector2(inspected_plot.get("centroid",Vector2.ZERO))
		var inspected_position:=Vector3(GameState.settlement_founded_at.x+inspected_centroid.x,0.0,GameState.settlement_founded_at.z+inspected_centroid.y)
		inspected_position.y=_height_at(inspected_position.x,inspected_position.z)
		_inspect_location(inspected_position)
	if capture_dock!="" and hud:
		var dock_parts:=capture_dock.split("/")
		_on_hud_section_requested(dock_parts[0],int(dock_parts[1]) if dock_parts.size()>1 else 0)
		if "--capture-detail-ledger" in OS.get_cmdline_user_args():
			hud.open_detail(preload("res://scripts/hud/content/dock_detail_population_ledger.gd").new(self,hud))
		# Captures draw synchronously before the deferred container sort runs;
		# force the dock's layout so its content is arranged in the screenshot.
		hud.force_dock_layout()
	if capture_people_panel:
		settler_panel.visible = true
		if lens_panel: lens_panel.visible = false
		_refresh_population_allocations()
		capture_audit_root=settler_panel
	if capture_population_ledger:
		_open_population_ledger()
		capture_audit_root=population_ledger_panel
	if capture_naming_panel:
		_open_settlement_naming_panel()
		capture_audit_root=settlement_naming_panel
	if capture_knowledge_panel:
		_open_knowledge_panel()
		capture_audit_root=knowledge_panel
	if capture_world_menu:
		_open_world_menu()
		capture_audit_root=world_menu_panel
	if capture_society_panel:
		_open_society_panel()
		capture_audit_root=society_panel
	if capture_military_panel:
		if not MilitaryCommandUI.modal.visible:
			MilitaryCommandUI._toggle()
		capture_audit_root=MilitaryCommandUI.modal
	if capture_provisions_panel:
		# Exercise the worst-case provision view: an active long scout commitment
		# plus its immediate stock withdrawal and recent-issue audit row.
		if not bool(CivilizationSystem.exploration_status().get("active",false)):
			CivilizationSystem.dispatch_scouts(365)
		_open_provisions_panel()
		capture_audit_root=provisions_panel
	if capture_materials_panel:
		_open_materials_panel()
		capture_audit_root=materials_panel
	if capture_council_panel:
		_open_council_panel()
		capture_audit_root=council_panel
	if capture_government_panel:
		_open_government_panel()
		capture_audit_root=government_panel
	if capture_candidates_panel:
		_open_advisor_candidates("Steward")
		_inspect_leader(0)
		capture_audit_root=leader_panel
	if capture_civilizations_panel:
		_open_civilizations_panel()
		capture_audit_root=civilizations_panel
	if capture_diplomat_panel and not CivilizationSystem.civilizations.is_empty():
		var capture_civ:Dictionary=CivilizationSystem.civilizations[0]
		var capture_relation:Dictionary=capture_civ.get("player_relation",{})
		var capture_origin:Vector2=CivilizationSystem.player_world_origin
		capture_relation["contact_level"]=2
		capture_relation["contact_intelligence"]=0.35
		capture_relation["met_day"]=0
		capture_relation["contact_source"]="returned_scout_report"
		capture_relation["encounter_position"]={"x":capture_origin.x+34.0,"z":capture_origin.y}
		capture_relation["home_location_known"]=true
		capture_relation["home_position"]={"x":capture_origin.x+68.0,"z":capture_origin.y+12.0}
		capture_relation["home_location_source"]="capture fixture returned report"
		capture_relation["opinion"]=0.35
		capture_civ["player_relation"]=capture_relation
		CivilizationSystem.civilizations[0]=capture_civ
		CivilizationSystem._rebuild_competition()
		_open_diplomat_dispatch_panel(String(capture_civ.id),"open_trade")
		capture_audit_root=diplomat_dispatch_panel
	if capture_zoom > 0.0:
		camera_target = settler_marker.position
		camera.size = capture_zoom
		if is_finite(capture_pitch_degrees): camera_pitch=clampf(deg_to_rad(capture_pitch_degrees),-1.50,-0.32)
		if is_finite(capture_yaw_degrees): camera_yaw=wrapf(deg_to_rad(capture_yaw_degrees),-PI,PI)
		_update_camera()
		_update_scale_lod()
	# This scene and its UI layout are constructed synchronously. Force the renderer
	# to flush them instead of awaiting ordinary frames: hidden visual-regression
	# windows inherit the OS background throttle, where even two awaited frames can
	# take minutes and make actual graphics iteration impractical.
	if capture_dock!="":
		# The dock is populated in this same deferred call; give the container
		# layout and canvas one real frame before the capture draw.
		await get_tree().process_frame
		await get_tree().process_frame
	RenderingServer.force_sync()
	RenderingServer.force_draw(true,0.0)
	if capture_audit_root:
		var audit_failures:=_capture_ui_bounds_failures(capture_audit_root)
		if not audit_failures.is_empty():
			for failure in audit_failures:
				push_error(failure)
			get_tree().quit(1)
			return
	if DisplayServer.get_name()!="headless":
		var image := get_viewport().get_texture().get_image()
		if image:
			image.save_png(ProjectSettings.globalize_path(capture_path))
	var route_hierarchy_counts:Dictionary={}
	for route in GameState.settlement_routes:
		var hierarchy:=String(route.get("hierarchy",route.get("kind","unclassified")))
		route_hierarchy_counts[hierarchy]=int(route_hierarchy_counts.get(hierarchy,0))+1
	var fabric_generations:Dictionary={}
	var morphology_eras:Dictionary={}
	var land_use_counts:Dictionary={}
	var status_counts:Dictionary={}
	var largest_plots:Array[Dictionary]=[]
	for plot in GameState.settlement_plots:
		var generation_key:=str(int(plot.get("fabric_generation",0)))
		var era_key:=String(plot.get("morphology_era","founding"))
		fabric_generations[generation_key]=int(fabric_generations.get(generation_key,0))+1
		morphology_eras[era_key]=int(morphology_eras.get(era_key,0))+1
		var use_key:=String(plot.get("land_use","unclassified"))
		var status_key:=String(plot.get("status","unclassified"))
		land_use_counts[use_key]=int(land_use_counts.get(use_key,0))+1
		status_counts[status_key]=int(status_counts.get(status_key,0))+1
		largest_plots.append({"id":int(plot.get("id",-1)),"use":use_key,"status":status_key,"area_ha":float(plot.get("area_ha",0.0))})
	largest_plots.sort_custom(func(a:Dictionary,b:Dictionary)->bool: return float(a.area_ha)>float(b.area_ha))
	if largest_plots.size()>8: largest_plots.resize(8)
	var morphology_debug:Dictionary={"plots":GameState.settlement_plots.size(),"routes":GameState.settlement_routes.size(),"route_hierarchy":route_hierarchy_counts,"fabric_generations":fabric_generations,"morphology_eras":morphology_eras,"land_uses":land_use_counts,"statuses":status_counts,"largest_plots":largest_plots,"nuclei":GameState.settlement_nuclei,"revision":GameState.morphology_revision,"founded_at":GameState.settlement_founded_at,"camera_target":camera_target,"lod":rendered_settlement_lod,"architecture":_settlement_architecture_profile(),"architecture_signature":rendered_architecture_signature,"meshes":[]}
	if settlement_land_use_root:
		for child in settlement_land_use_root.get_children():
			if child is MeshInstance3D and (child as MeshInstance3D).mesh:
				morphology_debug.meshes.append({"name":child.name,"aabb":str((child as MeshInstance3D).mesh.get_aabb())})
	print("MORPHOLOGY RENDER ",JSON.stringify(morphology_debug))
	print("SIMULATION SNAPSHOT ",JSON.stringify({"day":GameState.elapsed_days,"population":GameState.population_total,"births":GameState.lifetime_births,"deaths":GameState.lifetime_deaths,"traveling":travel_active,"halt_reason":GameState.convoy_emergency_halt_reason,"allocations":GameState.population_allocations,"allocation_percentages":GameState.population_allocation_percentages,"age_cohorts":GameState.population_cohorts,"metrics":GameState.simulation_metrics,"works":GameState.settlement_completed,"discoveries":GameState.known_discoveries}))
	get_tree().quit()


func _capture_ui_bounds_failures(root:Control)->Array[String]:
	var failures:Array[String]=[]
	var viewport_rect:=get_viewport().get_visible_rect()
	var pending:Array[Node]=[root]
	while not pending.is_empty():
		var node:Node=pending.pop_back()
		for child in node.get_children(): pending.append(child)
		if not node is Button or not (node as Button).is_visible_in_tree(): continue
		var button:=node as Button
		var inside_scroll:=false
		var ancestor:=button.get_parent()
		while ancestor and ancestor!=root:
			if ancestor is ScrollContainer:
				inside_scroll=true
				break
			ancestor=ancestor.get_parent()
		if inside_scroll: continue
		var rect:=button.get_global_rect()
		if rect.position.x<viewport_rect.position.x-1.0 or rect.position.y<viewport_rect.position.y-1.0 or rect.end.x>viewport_rect.end.x+1.0 or rect.end.y>viewport_rect.end.y+1.0:
			failures.append("UI button '%s' leaves the viewport: %s within %s" % [button.text,rect,viewport_rect])
	return failures

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
	_refresh_discovery_mask()
	_process_camera_navigation(delta)
	_update_world_streaming()
	_update_scale_lod()
	_update_convoy_marker_animation()
	_refresh_contact_encounter_markers()
	_refresh_foreign_formation_markers()
	_refresh_player_field_army_markers()
	_refresh_settlement_network()
	_refresh_settlement_convoy_marker()
	if travel_council_notice and travel_council_notice.visible and Time.get_ticks_msec()>travel_council_notice_until_msec:
		travel_council_notice.visible=false
	if event_report_button and event_report_button.visible and Time.get_ticks_msec()>event_report_visible_until_msec:
		event_report_button.visible=false
	_arbitrate_notification_overlays()
	_process_live_report_refresh(delta)
	if game_speed <= 0.0:
		return
	var days_advanced := delta * _speed_hours_per_second()/24.0
	GameState.elapsed_days += days_advanced
	var current_discovery_day := int(floor(GameState.elapsed_days))
	while last_discovery_day < current_discovery_day:
		last_discovery_day += 1
		GameState.convoy_traveling=travel_active
		CivilizationSystem.advance_to_day(last_discovery_day)
		var daily_context := _discovery_context()
		var discoveries := DiscoverySystem.process_day(daily_context)
		var resource_events := ResourceSystem.process_day(daily_context)
		if not discoveries.is_empty() or not resource_events.is_empty():
			footprint_population = -1
		var simulation_events := _process_population_day(daily_context)
		var economy_events := EconomySystem.process_day(daily_context)
		simulation_events.append_array(economy_events)
		_refresh_event_report()
		for consequence in simulation_events:
			if String(consequence.get("severity","")) in ["danger","critical","warning"]:
				AdvisorSystem.generate_consequence_item(consequence)
		for resource_event in resource_events:
			if String(resource_event.get("title","")) in ["Resource Flow Constrained","Material Losses","Resource Accessible"]:
				AdvisorSystem.generate_consequence_item({"description":String(resource_event.get("description","")),"domain":"materials","severity":"warning" if String(resource_event.get("title",""))!="Resource Accessible" else "notice"})
		_process_settlement_day()
		_settlement_model().process_month(_settlement_spatial_context(daily_context))
		var progression_events:=ProgressionSystem.process_day(last_discovery_day)
		_refresh_discovered_resource_overlays()
		_refresh_settlement_footprint()
		if not progression_events.is_empty() and travel_status_label:
			travel_status_label.text="CIVILIZATION MILESTONE: %s" % String(progression_events[0].name).to_upper()
		elif not discoveries.is_empty() and travel_status_label:
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
		CivilizationSystem.record_player_travel(Vector2(position.x,position.z))
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
	_process_settlement_convoy()
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


# Informational reports remain open while the simulation runs. Their visible
# roots are long-lived: a bounded signature check stages fresh contents for one
# layout pass, then atomically adopts them into the existing root. The root is never hidden,
# queued for deletion, or left empty for a rendered frame, which prevents the
# full-screen dimmer from strobing as simulation values change.
func _process_live_report_refresh(delta:float)->void:
	live_report_refresh_elapsed+=maxf(0.0,delta)
	if live_report_refresh_elapsed<LIVE_REPORT_REFRESH_INTERVAL_SECONDS: return
	live_report_refresh_elapsed=fmod(live_report_refresh_elapsed,LIVE_REPORT_REFRESH_INTERVAL_SECONDS)
	if hud and not _live_report_global_interaction_active():
		hud.live_refresh_dock()
	_refresh_live_reports()


func _refresh_live_reports()->void:
	if live_report_refresh_in_progress or _live_report_global_interaction_active(): return
	var kinds:Array[String]=["provisions","materials","research","council","population","society","progression"]
	if civilization_report_panel and is_instance_valid(civilization_report_panel): kinds.append("civilization_report")
	else: kinds.append("civilizations")
	for kind in kinds:
		var panel:=_live_report_panel(kind)
		if panel==null or not is_instance_valid(panel) or not panel.is_visible_in_tree(): continue
		var signature:=_live_report_signature(kind)
		if not live_report_refresh_signatures.has(kind):
			live_report_refresh_signatures[kind]=signature
			continue
		if String(live_report_refresh_signatures[kind])==signature: continue
		if _live_report_interaction_active(kind,panel): continue
		if live_report_pending_replacements.has(kind): continue
		var view_state:=_capture_live_report_view_state(panel)
		live_report_refresh_in_progress=true
		_rebuild_live_report(kind,view_state,signature)
		live_report_refresh_in_progress=false


func _live_report_signature(kind:String)->String:
	var parts:Array=[int(floor(GameState.elapsed_days)),GameState.population_total,GameState.known_discoveries.size(),GameState.discovery_log.size()]
	match kind:
		"provisions":
			parts.append_array([roundi(float(GameState.resource_stockpiles.get("Food",0.0))*10.0),roundi(float(GameState.simulation_metrics.get("food_net",0.0))*10.0),roundi(float(GameState.water_metrics.get("stored",0.0))*10.0),GameState.food_issue_history.size()])
		"materials":
			parts.append_array([GameState.resource_deposits.size(),GameState.resource_stockpiles.size(),GameState.material_history.size(),hash(GameState.resource_priorities)])
		"research":
			parts.append_array([GameState.active_investigations.size(),hash(GameState.research_subcategory_allocations)])
		"council":
			parts.append_array([GameState.council_inbox.size(),GameState.sovereign_orders.size(),ConsequenceEngine.active_policies().size()])
			for order_index in mini(6,GameState.sovereign_orders.size()):
				var order:Dictionary=GameState.sovereign_orders[order_index]
				parts.append("%s:%s" % [String(order.get("id","")),String(order.get("status",""))])
		"civilizations","civilization_report":
			parts.append_array([CivilizationSystem.observation_revision,CivilizationSystem.fog_revision,CivilizationSystem.scout_reports.size(),CivilizationSystem.diplomatic_history.size(),selected_civilization_id,selected_civilization_region_id])
		"population":
			parts.append_array([GameState.lifetime_births,GameState.lifetime_deaths,roundi(GameState.population_health*1000.0),GameState.demographic_ledger.size()])
		"society":
			parts.append_array([society_panel_mode,hash(GameState.society_capacities),hash(GameState.societal_values)])
		"progression":
			parts.append_array([active_progression_domain,hash(GameState.society_capacities)])
	return str(hash(parts))


func _live_report_panel(kind:String)->Control:
	match kind:
		"provisions": return provisions_panel
		"materials": return materials_panel
		"research": return knowledge_panel
		"council": return council_panel
		"civilizations": return civilizations_panel
		"civilization_report": return civilization_report_panel
		"population": return population_ledger_panel
		"society": return society_panel
		"progression": return progression_panel
	return null


func _live_report_global_interaction_active()->bool:
	for overlay in [settlement_naming_panel,settlement_convoy_confirm_panel,scout_dispatch_panel,diplomat_dispatch_panel,founding_focus_panel,world_menu_panel,settlement_dashboard_panel,systems_hub_panel]:
		if overlay and is_instance_valid(overlay) and overlay.is_visible_in_tree(): return true
	return false


func _live_report_interaction_active(kind:String,panel:Control)->bool:
	if kind=="research" and panel.find_child("InvestigationDetailOverlay",true,false): return true
	if kind=="provisions" and panel.find_child("ProvisionsDetailOverlay",true,false): return true
	if kind=="materials" and panel.find_child("MaterialsDetailOverlay",true,false): return true
	for editor_variant in panel.find_children("*","LineEdit",true,false):
		var editor:=editor_variant as LineEdit
		if editor and (editor.has_focus() or not editor.text.strip_edges().is_empty()): return true
	for editor_variant in panel.find_children("*","TextEdit",true,false):
		var editor:=editor_variant as TextEdit
		if editor and (editor.has_focus() or not editor.text.strip_edges().is_empty()): return true
	for selector_variant in panel.find_children("*","OptionButton",true,false):
		var selector:=selector_variant as OptionButton
		if selector and (selector.has_focus() or selector.get_popup().visible): return true
	return false


func _capture_live_report_view_state(panel:Control)->Dictionary:
	var state:Dictionary={"scrolls":[]}
	for scroll_variant in panel.find_children("*","ScrollContainer",true,false):
		var scroll:=scroll_variant as ScrollContainer
		(state.scrolls as Array).append({"horizontal":scroll.scroll_horizontal,"vertical":scroll.scroll_vertical})
	var focus:=get_viewport().gui_get_focus_owner()
	if focus and panel.is_ancestor_of(focus):
		state["focus_path"]=panel.get_path_to(focus)
		state["focus_index_path"]=_live_report_child_index_path(panel,focus)
	return state


func _restore_live_report_view_state(kind:String,state:Dictionary)->void:
	var panel:=_live_report_panel(kind)
	if panel==null or not is_instance_valid(panel): return
	var prior_scrolls:Array=state.get("scrolls",[])
	var scrolls:=panel.find_children("*","ScrollContainer",true,false)
	for index in mini(prior_scrolls.size(),scrolls.size()):
		var scroll:=scrolls[index] as ScrollContainer
		var prior:Dictionary=prior_scrolls[index]
		scroll.scroll_horizontal=int(prior.get("horizontal",0))
		scroll.scroll_vertical=int(prior.get("vertical",0))
	var focus_path:NodePath=state.get("focus_path",NodePath(""))
	var replacement:Control=null
	if not focus_path.is_empty():
		replacement=panel.get_node_or_null(focus_path) as Control
	if replacement==null:
		replacement=_live_report_node_at_index_path(panel,state.get("focus_index_path",[])) as Control
	if replacement and replacement.focus_mode!=Control.FOCUS_NONE: replacement.grab_focus()


func _live_report_child_index_path(root:Node,target:Node)->Array[int]:
	var result:Array[int]=[]
	var cursor:=target
	while cursor and cursor!=root:
		# Tabs, option menus, and other compound controls may focus an internal
		# child. Preserve that path explicitly instead of asking Godot for the
		# public-child index of an internal node (which emits every refresh).
		result.push_front(cursor.get_index(true))
		cursor=cursor.get_parent()
	return result if cursor==root else []


func _live_report_node_at_index_path(root:Node,index_path:Array)->Node:
	var cursor:=root
	for index_variant in index_path:
		var index:=int(index_variant)
		if index<0 or index>=cursor.get_child_count(true): return null
		cursor=cursor.get_child(index,true)
	return cursor


func _set_live_report_panel(kind:String,panel:Control)->void:
	match kind:
		"provisions": provisions_panel=panel
		"materials": materials_panel=panel
		"research": knowledge_panel=panel
		"council": council_panel=panel
		"civilizations": civilizations_panel=panel
		"civilization_report": civilization_report_panel=panel
		"population": population_ledger_panel=panel
		"society": society_panel=panel
		"progression": progression_panel=panel


func _build_live_report_replacement(kind:String)->Control:
	match kind:
		"provisions": _open_provisions_panel()
		"materials": _open_materials_panel()
		"research":
			knowledge_record_container=null
			knowledge_investigation_widgets.clear()
			knowledge_discovery_widgets.clear()
			knowledge_mode_buttons.clear()
			knowledge_category_selector=null
			_open_knowledge_panel()
		"council": _open_council_panel()
		"civilizations": _open_civilizations_panel()
		"civilization_report": _open_civilization_report(selected_civilization_id)
		"population": _open_population_ledger()
		"society":
			if society_panel_mode=="values": _open_values_panel()
			else: _open_society_panel()
		"progression": _open_progression_panel(active_progression_domain)
	return _live_report_panel(kind)


func _adopt_live_report_contents(stable_root:Control,replacement_root:Control)->void:
	# The replacement has already completed one offscreen layout pass. Detaching the
	# old children and adopting the new children happens at a frame boundary, so the
	# visible root is never empty in a rendered frame.
	stable_root.size=replacement_root.size
	var retired_children:=stable_root.get_children()
	for child in retired_children: stable_root.remove_child(child)
	var incoming_children:=replacement_root.get_children()
	for child in incoming_children:
		replacement_root.remove_child(child)
		stable_root.add_child(child)
	for child in retired_children: child.free()
	replacement_root.free()
	_apply_modal_screen_contract.call_deferred(stable_root)


func _rebuild_live_report(kind:String,view_state:Dictionary={},signature:String="")->void:
	if live_report_pending_replacements.has(kind): return
	var stable_root:=_live_report_panel(kind)
	if stable_root==null or not is_instance_valid(stable_root): return
	var was_visible:=stable_root.visible
	var root_id:=stable_root.get_instance_id()
	# Builders still own report composition. Temporarily clearing only the
	# reference prevents their legacy open guards from deleting the mounted root.
	_set_live_report_panel(kind,null)
	var replacement_root:=_build_live_report_replacement(kind)
	if replacement_root==null or replacement_root==stable_root:
		_set_live_report_panel(kind,stable_root)
		return
	# Keep the fully composed replacement in-tree for layout but far outside the
	# viewport. The mounted report remains the only visible/interactable root.
	replacement_root.position=Vector2(-maxf(4096.0,replacement_root.size.x*4.0),-maxf(4096.0,replacement_root.size.y*4.0))
	replacement_root.mouse_filter=Control.MOUSE_FILTER_IGNORE
	_set_live_report_panel(kind,stable_root)
	live_report_pending_replacements[kind]={"stable":stable_root,"replacement":replacement_root,"view_state":view_state,"was_visible":was_visible,"root_id":root_id,"signature":signature}
	var commit:=Callable(self,"_commit_live_report_replacements")
	if not get_tree().process_frame.is_connected(commit):
		get_tree().process_frame.connect(commit,CONNECT_ONE_SHOT)


func _commit_live_report_replacements()->void:
	var pending:=live_report_pending_replacements.duplicate(false)
	live_report_pending_replacements.clear()
	for kind_variant in pending:
		var kind:=String(kind_variant)
		var record:Dictionary=pending[kind_variant]
		# A player can close a report during the one-frame offscreen composition pass.
		# Validate the untyped object before casting it; casting an already-freed Godot
		# object itself raises an error and was responsible for repeated modal flashes.
		var replacement_value:Variant=record.get("replacement")
		if not is_instance_valid(replacement_value): continue
		var replacement_root:=replacement_value as Control
		if replacement_root==null: continue
		var stable_value:Variant=record.get("stable")
		if not is_instance_valid(stable_value):
			replacement_root.free()
			continue
		var stable_root:=stable_value as Control
		if stable_root==null or stable_root.is_queued_for_deletion():
			replacement_root.free()
			continue
		_adopt_live_report_contents(stable_root,replacement_root)
		_set_live_report_panel(kind,stable_root)
		stable_root.visible=bool(record.get("was_visible",true))
		_restore_live_report_view_state(kind,record.get("view_state",{}))
		call_deferred("_restore_live_report_view_state",kind,record.get("view_state",{}))
		live_report_refresh_signatures[kind]=String(record.get("signature",_live_report_signature(kind)))
		assert(stable_root.get_instance_id()==int(record.get("root_id",0)))


func _discovery_context() -> Dictionary:
	var context := {"foraging":0.78 if travel_active else 1.0, "food":1.0, "exploration":0.8 if travel_active else 0.5, "travel":1.0 if travel_active else 0.1, "fiber":0.5, "fire":0.6, "administration":0.5, "defense":0.3}
	context["traveling"]=travel_active
	context["travel_days_remaining"]=maxf(0.0,travel_days_total-travel_days_elapsed) if travel_active else 0.0
	context["travel_distance_remaining_km"]=Vector2(settler_marker.position.x,settler_marker.position.z).distance_to(Vector2(travel_target.x,travel_target.z))*KM_PER_WORLD_UNIT if travel_active and settler_marker else 0.0
	context["tools"] = ConsequenceEngine.tools_factor()
	context["insight"] = ConsequenceEngine.discovery_multiplier()
	if settler_marker:
		var origin:Vector3=GameState.settlement_founded_at if GameState.settlement_site_committed else settler_marker.position
		context["origin"] = origin
		# The rendered drainage is authoritative geography. A settlement visibly on
		# a riverbank must not depend on whether a separate random resource marker was
		# successfully scattered elsewhere in the region.
		var surface_water_distance_km:=_river_distance_at(origin.x,origin.z)*KM_PER_WORLD_UNIT
		context["surface_water_distance_km"]=surface_water_distance_km
		context["surface_water_recognized"]=surface_water_distance_km<=72.0
		if surface_water_distance_km<=6.0: context["freshwater"]=1.0
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
	context["buildable_land_at"]=func(x:float,z:float)->bool: return _height_at(x,z)>SEA_LEVEL+0.012
	context["river_distance_at"]=Callable(self,"_river_distance_at")
	context["drainage_tangent_at"]=Callable(self,"_drainage_tangent_at")
	context["moisture_at"]=Callable(self,"_land_moisture_at")
	context["settlement_origin"]=GameState.settlement_founded_at
	return context

func _land_moisture_at(x:float,z:float)->float:
	return moisture_noise.get_noise_2d(x,z)

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


func _scout_land_at(position:Vector2)->bool:
	# One authoritative predicate serves the terrain mesh, coast, settlement
	# blocker, and civilization travel planner. Fog never participates here.
	if absf(position.x)>world_width*0.5 or absf(position.y)>world_depth*0.5: return false
	return _height_at(position.x,position.y)>SEA_LEVEL+0.015

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
	var local_drainage_distance:=_local_drainage_distance_at(x,z)
	if local_drainage_distance<0.11:
		var swale:=pow(1.0-local_drainage_distance/0.11,1.72)
		# Four to nine metres of relief is enough to create a real drainage floor at
		# settlement scale without turning every intermittent reach into a canyon.
		height-=swale*(0.0045+0.0045*swale)
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

func _local_drainage_distance_at(x:float,z:float)->float:
	# Intermittent swales fill the enormous gap between the continental river and
	# metre-scale soil noise. Parallel indices are only a construction device: two
	# incommensurate meanders and a broad activation field make visible reaches
	# discontinuous, irregular and seed-specific across the planet.
	var phase:=float(posmod(GameState.world_seed,10007))/10007.0
	var spacing:=2.40
	var offset:=(phase-0.5)*spacing
	var channel_index:=roundi((x-offset)/spacing)
	var channel_x:=float(channel_index)*spacing+offset
	channel_x+=sin(z*1.34+float(channel_index)*2.17+phase*TAU)*0.22
	channel_x+=sin(z*3.71-float(channel_index)*0.83+phase*17.0)*0.055
	var activation_raw:=0.50+sin(z*1.11+float(channel_index)*1.73+phase*31.0)*0.31+sin(z*0.37-float(channel_index)*2.41+phase*67.0)*0.19
	var activation:=smoothstep(0.29,0.72,activation_raw)
	if activation<0.28: return INF
	# Weak reaches report a larger effective distance, naturally fading their
	# influence on siting and cultivation without binary on/off seams.
	return absf(x-channel_x)+lerpf(0.075,0.0,activation)

func _drainage_tangent_at(x:float,z:float)->Vector2:
	# Return the along-water direction in world X/Z space. Fields, tracks and
	# riparian growth can then respond to the same authored watershed instead of
	# each inventing an unrelated visual bearing.
	var main_x:=_world_river_x(z)
	var main_distance:=INF if main_x==INF else absf(x-main_x)
	var phase:=float(posmod(GameState.world_seed,10007))/10007.0
	var spacing:=2.40
	var offset:=(phase-0.5)*spacing
	var channel_index:=roundi((x-offset)/spacing)
	var channel_x:=float(channel_index)*spacing+offset
	channel_x+=sin(z*1.34+float(channel_index)*2.17+phase*TAU)*0.22
	channel_x+=sin(z*3.71-float(channel_index)*0.83+phase*17.0)*0.055
	var local_distance:=_local_drainage_distance_at(x,z)
	if local_distance<main_distance:
		var local_dx_dz:=cos(z*1.34+float(channel_index)*2.17+phase*TAU)*0.22*1.34
		local_dx_dz+=cos(z*3.71-float(channel_index)*0.83+phase*17.0)*0.055*3.71
		return Vector2(local_dx_dz,1.0).normalized()
	if main_x!=INF:
		var main_dx_dz:=cos(z/128.0+float(GameState.world_seed%97)*0.031)*32.0/128.0
		main_dx_dz+=cos(z/57.0-0.8)*14.0/57.0+cos(z/21.0+1.7)*4.5/21.0
		return Vector2(main_dx_dz,1.0).normalized()
	return Vector2.UP

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
	# Oblique satellite views amplify one-pixel cascade stair-steps into bright
	# kilometre-long bands on ridge crests. A modest penumbra preserves the relief
	# while removing the low-poly-looking shadow edge.
	sun.shadow_blur=2.4
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
	# Settlement and country views need enough samples that ridges read as landforms,
	# not a triangulated strategy-game board. Keep the continental patch bounded,
	# then spend vertices only as the streamed footprint contracts around the camera.
	var resolution:=385 if span<=14.0 else (257 if span<=32.0 else (201 if span<=110.0 else 161))
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
			# Alternate the diagonal. A single global split direction produces long
			# staircase bands across slopes even at otherwise adequate resolution.
			var indices:=[a,b,c,a,c,d] if (x_index+z_index)%2==0 else [a,b,d,b,c,d]
			for index in indices:
				surface.add_index(index)
	surface.generate_normals()
	regional_terrain_patch=MeshInstance3D.new()
	regional_terrain_patch.name="RegionalTerrainLOD"
	regional_terrain_patch.mesh=surface.commit()
	regional_terrain_patch.material_override=_create_terrain_material()
	add_child(regional_terrain_patch)


func _discovery_mask_pixel(position:Vector2,width:int,height:int)->Vector2:
	return Vector2((position.x/world_width+0.5)*float(width-1),(position.y/world_depth+0.5)*float(height-1))


func _paint_discovery_disc(image:Image,position:Vector2,radius_km:float,width:int,height:int)->void:
	var center:=_discovery_mask_pixel(position,width,height)
	var radius_x:=maxf(1.0,radius_km/world_width*float(width))
	var radius_y:=maxf(1.0,radius_km/world_depth*float(height))
	for pixel_y in range(maxi(0,floori(center.y-radius_y*1.25)),mini(height,ceili(center.y+radius_y*1.25)+1)):
		for pixel_x in range(maxi(0,floori(center.x-radius_x*1.25)),mini(width,ceili(center.x+radius_x*1.25)+1)):
			var dx:=(float(pixel_x)-center.x)/radius_x
			var dy:=(float(pixel_y)-center.y)/radius_y
			var distance:=sqrt(dx*dx+dy*dy)
			if distance>1.25: continue
			var reveal:=1.0-smoothstep(0.82,1.25,distance)
			if reveal>image.get_pixel(pixel_x,pixel_y).r: image.set_pixel(pixel_x,pixel_y,Color(reveal,reveal,reveal))


func _paint_discovery_segment(image:Image,start:Vector2,finish:Vector2,radius_km:float,width:int,height:int)->void:
	var a:=_discovery_mask_pixel(start,width,height)
	var b:=_discovery_mask_pixel(finish,width,height)
	var radius_pixels:=maxf(1.0,(radius_km/world_width*float(width)+radius_km/world_depth*float(height))*0.5)
	var padding:=radius_pixels*1.25
	for pixel_y in range(maxi(0,floori(minf(a.y,b.y)-padding)),mini(height,ceili(maxf(a.y,b.y)+padding)+1)):
		for pixel_x in range(maxi(0,floori(minf(a.x,b.x)-padding)),mini(width,ceili(maxf(a.x,b.x)+padding)+1)):
			var pixel:=Vector2(float(pixel_x),float(pixel_y))
			var distance:=pixel.distance_to(Geometry2D.get_closest_point_to_segment(pixel,a,b))/radius_pixels
			if distance>1.25: continue
			var reveal:=1.0-smoothstep(0.82,1.25,distance)
			if reveal>image.get_pixel(pixel_x,pixel_y).r: image.set_pixel(pixel_x,pixel_y,Color(reveal,reveal,reveal))


func _refresh_discovery_mask(force:bool=false)->void:
	var snapshot:Dictionary=CivilizationSystem.fog_snapshot()
	var revision:=int(snapshot.get("revision",0))
	var current_origin:Dictionary=snapshot.get("current_origin",{})
	for material in terrain_fog_materials:
		if material==null or not is_instance_valid(material): continue
		material.set_shader_parameter("fog_current_origin",Vector2(float(current_origin.get("x",0.0)),float(current_origin.get("z",0.0))))
	if not force and revision==rendered_fog_revision: return
	var width:=1024
	var height:=512
	var image:=Image.create(width,height,false,Image.FORMAT_L8)
	image.fill(Color.BLACK)
	for area_variant in snapshot.get("areas",[]):
		var area:Dictionary=area_variant
		var radius:=maxf(1.0,float(area.get("radius",1.0)))
		var points:Array=area.get("points",[])
		if String(area.get("kind","circle"))=="trail" and points.size()>=2:
			for point_index in points.size()-1:
				var a:Dictionary=points[point_index]; var b:Dictionary=points[point_index+1]
				_paint_discovery_segment(image,Vector2(float(a.get("x",0.0)),float(a.get("z",0.0))),Vector2(float(b.get("x",0.0)),float(b.get("z",0.0))),radius,width,height)
		else:
			_paint_discovery_disc(image,Vector2(float(area.get("x",0.0)),float(area.get("z",0.0))),radius,width,height)
	if discovery_mask_texture==null:
		discovery_mask_texture=ImageTexture.create_from_image(image)
	else:
		discovery_mask_texture.update(image)
	rendered_fog_revision=revision
	var valid_materials:Array[ShaderMaterial]=[]
	for material in terrain_fog_materials:
		if material==null or not is_instance_valid(material): continue
		material.set_shader_parameter("discovery_mask",discovery_mask_texture)
		material.set_shader_parameter("fog_current_origin",Vector2(float(current_origin.get("x",0.0)),float(current_origin.get("z",0.0))))
		valid_materials.append(material)
	terrain_fog_materials=valid_materials


func _fog_shader_parameters(material:ShaderMaterial)->void:
	material.set_shader_parameter("discovery_mask",discovery_mask_texture)
	material.set_shader_parameter("fog_world_size",Vector2(world_width,world_depth))
	material.set_shader_parameter("fog_current_origin",CivilizationSystem.player_world_origin)
	terrain_fog_materials.append(material)


func _world_position_is_revealed(position:Vector3)->bool:
	return CivilizationSystem._position_is_revealed(Vector2(position.x,position.z))

func _create_terrain_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode diffuse_burley, specular_disabled;

uniform sampler2D ground_albedo : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D forest_albedo : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D regional_albedo : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D discovery_mask : source_color, filter_linear;
uniform vec2 fog_world_size = vec2(40075.0, 20004.0);
uniform vec2 fog_current_origin = vec2(0.0);
uniform float drainage_phase = 0.0;

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

float fbm(vec2 p) {
	float value = 0.0;
	float amplitude = 0.52;
	for (int octave = 0; octave < 5; octave++) {
		value += value_noise(p) * amplitude;
		p = vec2(p.x * 1.73 - p.y * 1.11, p.x * 1.11 + p.y * 1.73) + vec2(19.7, -13.1);
		amplitude *= 0.48;
	}
	return value;
}

float organic_noise(vec2 p) {
	vec2 warp = vec2(fbm(p * 0.53 + vec2(17.0, -31.0)), fbm(p * 0.47 + vec2(-43.0, 11.0)));
	return fbm(p + (warp - vec2(0.5)) * 2.15);
}

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}

void fragment() {
	float broad = organic_noise(world_position.xz * 0.052);
	float regional = organic_noise(world_position.xz * 0.17 + vec2(17.0, -9.0));
	float slope = 1.0 - clamp(dot(normalize(world_normal), vec3(0.0, 1.0, 0.0)), 0.0, 1.0);
	float pixel_world = max(length(dFdx(world_position.xz)), length(dFdy(world_position.xz)));
	// The material is a scale hierarchy, not one photograph enlarged forever.
	// World units are kilometres.  Country and regional imagery only enters once
	// the projected pixel footprint can actually resolve it; this also prevents
	// visible texture repetition in continental and low-oblique views.
	float country_detail = 1.0 - smoothstep(0.55, 4.50, pixel_world);
	float regional_detail = 1.0 - smoothstep(0.050, 0.55, pixel_world);
	float local_detail = 1.0 - smoothstep(0.008, 0.075, pixel_world);
	float close_detail = 1.0 - smoothstep(0.0009, 0.008, pixel_world);
	vec2 country_uv = world_position.xz * 0.00072;
	vec2 country_uv_rotated = vec2(-country_uv.y, country_uv.x) * 1.19 + vec2(0.317, 0.681);
	vec2 map_uv = world_position.xz * 0.0068;
	vec2 map_uv_rotated = vec2(-map_uv.y, map_uv.x) * 1.31 + vec2(0.317, 0.681);
	// The relief-bearing satellite source is useful at country scale, but magnifying
	// it into a five-kilometre view duplicates mountains that do not match the
	// generated height field. Neutral aerial ground/forest tiles bridge that band.
	vec2 local_ground_uv = world_position.xz * 0.52;
	vec2 local_ground_uv_rotated = vec2(-local_ground_uv.y, local_ground_uv.x) * 0.87 + vec2(0.29, -0.41);
	vec2 local_forest_uv = world_position.xz * 0.23;
	vec2 local_forest_uv_rotated = vec2(-local_forest_uv.y, local_forest_uv.x) * 0.79 + vec2(-0.17, 0.36);
	// The source albedo contains its own broad photographic mottling. At x18 it
	// repeated as 55 m rugs; x68 places that content at a believable 10–20 m aerial
	// scale, while the biome FBM above remains responsible for large land-cover mass.
	vec2 close_uv = world_position.xz * 68.0;
	vec2 close_uv_rotated = vec2(-close_uv.y, close_uv.x) * 0.83 + vec2(0.19, -0.27);
	float biome_patch = organic_noise(world_position.xz * 0.011 + vec2(-5.0, 11.0));
	float soil_patch = organic_noise(world_position.xz * 0.062 + vec2(23.0, -17.0));
	vec3 vertex_tint = mix(vec3(dot(COLOR.rgb, vec3(0.28,0.57,0.15))), COLOR.rgb, 0.78);
	vec3 climate_ground = mix(vec3(0.31,0.275,0.165), vec3(0.245,0.345,0.205), clamp(biome_patch*0.58+broad*0.42,0.0,1.0));
	climate_ground = mix(climate_ground, vertex_tint, 0.72);
	climate_ground *= 0.91 + (organic_noise(world_position.xz*0.0024)-0.5)*0.15;
	vec3 procedural_ground = mix(climate_ground, mix(vec3(0.255,0.245,0.165), vec3(0.405,0.385,0.245), broad * 0.62 + biome_patch * 0.38), country_detail*0.38);
	procedural_ground *= 0.92 + (soil_patch - 0.5) * mix(0.04,0.17,country_detail);
	vec3 country_a = texture(regional_albedo, country_uv).rgb;
	vec3 country_b = texture(regional_albedo, country_uv_rotated).rgb;
	vec3 country_map = mix(country_a, country_b, 0.16);
	vec3 satellite_a = texture(regional_albedo, map_uv).rgb;
	vec3 satellite_b = texture(regional_albedo, map_uv_rotated * 0.79 + vec2(0.41, 0.13)).rgb;
	vec3 satellite_map = mix(satellite_a, satellite_b, 0.08);
	vec3 local_ground_a = texture(ground_albedo, local_ground_uv).rgb;
	vec3 local_ground_b = texture(ground_albedo, local_ground_uv_rotated).rgb;
	vec3 local_ground_map = mix(local_ground_a, local_ground_b, 0.22);
	vec3 local_forest_a = texture(forest_albedo, local_forest_uv).rgb;
	vec3 local_forest_b = texture(forest_albedo, local_forest_uv_rotated).rgb;
	vec3 local_forest_map = mix(local_forest_a, local_forest_b, 0.18);
	vec3 ground_map = mix(procedural_ground, country_map, country_detail * 0.72);
	ground_map = mix(ground_map, satellite_map, regional_detail * (1.0-local_detail) * 0.72);
	ground_map = mix(ground_map, local_ground_map, local_detail * 0.72);
	vec3 procedural_forest = mix(vec3(0.055,0.105,0.070), vec3(0.155,0.205,0.125), biome_patch * 0.62 + regional * 0.38);
	vec3 forest_map = mix(procedural_forest, country_map * vec3(0.68,0.84,0.67), country_detail * 0.68);
	forest_map = mix(forest_map, satellite_map * vec3(0.68,0.84,0.67), regional_detail * (1.0-local_detail) * 0.68);
	forest_map = mix(forest_map, local_forest_map, local_detail * 0.76);
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
	earth = mix(earth, vertex_tint, mix(0.30, 0.10, max(regional_detail,local_detail)));
	// Seeded intermittent swales bridge the visual scale between a continental
	// river and local soil mottling. Their broad riparian shoulder remains green;
	// the narrow floor exposes damp earth. Geometry uses the same centreline.
	float drainage_spacing=2.40;
	float drainage_offset=(drainage_phase-0.5)*drainage_spacing;
	float drainage_index=floor((world_position.x-drainage_offset)/drainage_spacing+0.5);
	float drainage_x=drainage_index*drainage_spacing+drainage_offset;
	drainage_x+=sin(world_position.z*1.34+drainage_index*2.17+drainage_phase*6.2831853)*0.22;
	drainage_x+=sin(world_position.z*3.71-drainage_index*0.83+drainage_phase*17.0)*0.055;
	float drainage_raw=0.50+sin(world_position.z*1.11+drainage_index*1.73+drainage_phase*31.0)*0.31+sin(world_position.z*0.37-drainage_index*2.41+drainage_phase*67.0)*0.19;
	float drainage_active=smoothstep(0.29,0.72,drainage_raw);
	float drainage_distance=abs(world_position.x-drainage_x)+mix(0.075,0.0,drainage_active);
	float riparian=(1.0-smoothstep(0.025,0.115,drainage_distance))*drainage_active;
	float swale_floor=(1.0-smoothstep(0.006,0.026,drainage_distance))*drainage_active;
	earth=mix(earth,vec3(0.17,0.275,0.155),riparian*(0.20+local_detail*0.12));
	earth=mix(earth,vec3(0.225,0.245,0.165),swale_floor*(0.26+close_detail*0.18));
	float open_meadow = smoothstep(0.58,0.78,soil_patch) * (1.0-forest_mask) * (1.0-close_detail*0.45);
	float dryland_mass = smoothstep(0.60,0.80,organic_noise(world_position.xz*0.022+vec2(61.0,-47.0))) * (1.0-forest_mask);
	earth = mix(earth, vec3(0.34,0.37,0.205), open_meadow*0.30);
	earth = mix(earth, vec3(0.43,0.37,0.235), dryland_mass*0.26);
	float dry_patch = smoothstep(0.63, 0.84, value_noise(world_position.xz * 1.7 + vec2(-31.0, 22.0))) * close_detail;
	float worn_patch = smoothstep(0.70, 0.91, value_noise(world_position.xz * 7.5 + vec2(8.0, -14.0))) * close_detail;
	earth = mix(earth, vec3(0.36, 0.315, 0.21), dry_patch * 0.28);
	earth = mix(earth, vec3(0.25, 0.245, 0.18), worn_patch * 0.12);
	// At settlement scale introduce coherent tens-of-metres aerial variation.
	// This is the missing layer between a regional satellite image and centimetre
	// grass grain: exposed soil, moisture pockets and irregular open ground.
	float close_soil_mass = smoothstep(0.43,0.72,organic_noise(world_position.xz*46.0+vec2(-53.0,19.0))) * close_detail * (1.0-forest_mask);
	float close_lush_mass = smoothstep(0.47,0.75,organic_noise(world_position.xz*32.0+vec2(37.0,-61.0))) * close_detail * (1.0-slope);
	float close_clearings = smoothstep(0.62,0.86,organic_noise(world_position.xz*70.0+vec2(11.0,47.0))) * close_detail * (1.0-forest_mask);
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
	// Close aerial views still need landform. Suppressing most hillshade at the
	// exact settlement scale turned real 10–50 m relief into flat colour patches.
	// Texture supplies surface detail; directional normal shading supplies shape.
	float regional_relief = 1.0 - close_detail * 0.38;
	earth *= mix(1.0, hillshade, regional_relief * 0.82);
	float ridge_glint = smoothstep(0.12, 0.62, slope) * smoothstep(0.25, 0.82, hill_light) * regional_relief;
	earth = mix(earth, vec3(0.48,0.46,0.40), ridge_glint * 0.20);
	// Close aerial imagery needs a different exposure than the shaded regional
	// relief map. Without this lift the settlement-scale ground fell nearly black.
	earth *= mix(1.0, 1.32, close_detail);
	earth = mix(earth, max(earth, vec3(0.105,0.112,0.072)), close_detail * 0.72);
	vec2 fog_uv=clamp(world_position.xz/fog_world_size+vec2(0.5),vec2(0.0),vec2(1.0));
	float current_visibility=1.0-smoothstep(30.0,38.0,distance(world_position.xz,fog_current_origin));
	float discovered=max(texture(discovery_mask,fog_uv).r,current_visibility);
	vec3 unknown_ground=vec3(0.006,0.012,0.014);
	earth=mix(unknown_ground,earth,smoothstep(0.06,0.62,discovered));
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
	material.set_shader_parameter("drainage_phase",float(posmod(GameState.world_seed,10007))/10007.0)
	_fog_shader_parameters(material)
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
	var forest_shader:=Shader.new()
	forest_shader.code="""
shader_type spatial;
render_mode diffuse_burley, specular_disabled;
uniform sampler2D discovery_mask : source_color, filter_linear;
uniform vec2 fog_world_size=vec2(40075.0,20004.0);
uniform vec2 fog_current_origin=vec2(0.0);
varying vec3 world_position;
void vertex(){ world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
void fragment(){
	vec2 uv=clamp(world_position.xz/fog_world_size+vec2(0.5),vec2(0.0),vec2(1.0));
	float current_visibility=1.0-smoothstep(30.0,38.0,distance(world_position.xz,fog_current_origin));
	float discovered=smoothstep(0.12,0.62,max(texture(discovery_mask,uv).r,current_visibility));
	ALBEDO=mix(vec3(0.004,0.009,0.010),COLOR.rgb,discovered);
	ROUGHNESS=1.0;
}
"""
	var material:=ShaderMaterial.new()
	material.shader=forest_shader
	_fog_shader_parameters(material)
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
	var shader:=Shader.new()
	shader.code="""
shader_type spatial;
render_mode diffuse_burley, specular_disabled;
uniform sampler2D discovery_mask : source_color, filter_linear;
uniform vec2 fog_world_size=vec2(40075.0,20004.0);
uniform vec2 fog_current_origin=vec2(0.0);
varying vec3 world_position;
void vertex(){ world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
void fragment(){
	vec2 uv=clamp(world_position.xz/fog_world_size+vec2(0.5),vec2(0.0),vec2(1.0));
	float current_visibility=1.0-smoothstep(30.0,38.0,distance(world_position.xz,fog_current_origin));
	float discovered=max(texture(discovery_mask,uv).r,current_visibility);
	ALBEDO=mix(vec3(0.004,0.010,0.013),vec3(0.063,0.165,0.204),smoothstep(0.06,0.62,discovered));
	ROUGHNESS=0.40;
}
"""
	var material:=ShaderMaterial.new()
	material.shader=shader
	_fog_shader_parameters(material)
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
		world_tributary_courses = _seeded_world_tributaries()
		for tributary in world_tributary_courses:
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
		var river_shader:=Shader.new()
		river_shader.code="""
shader_type spatial;
render_mode unshaded, specular_disabled, blend_mix, cull_disabled, depth_test_disabled;
uniform sampler2D discovery_mask : source_color, filter_linear;
uniform vec2 fog_world_size=vec2(40075.0,20004.0);
uniform vec2 fog_current_origin=vec2(0.0);
uniform float resource_emphasis=0.0;
varying vec3 world_position;
void vertex(){ world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
void fragment(){
	vec2 uv=clamp(world_position.xz/fog_world_size+vec2(0.5),vec2(0.0),vec2(1.0));
	float current_visibility=1.0-smoothstep(30.0,38.0,distance(world_position.xz,fog_current_origin));
	float discovered=smoothstep(0.08,0.58,max(texture(discovery_mask,uv).r,current_visibility));
	ALBEDO=mix(COLOR.rgb,vec3(0.12,0.48,0.62),resource_emphasis*0.72);
	ALPHA=COLOR.a*discovered;
	ROUGHNESS=0.72;
}
"""
		var material:=ShaderMaterial.new()
		material.shader=river_shader
		material.render_priority=-6 if entry.name=="RiverBanks" else -5
		_fog_shader_parameters(material)
		material.set_shader_parameter("resource_emphasis",1.0 if resource_view_enabled and entry.name=="RiverWater" else 0.0)
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
		# Surface water is a continuous authored river system, not a random deposit.
		# Keep one aggregate occurrence for simulation/progression gates, anchored on
		# the actual channel nearest the founding watershed, and draw no fake dot.
		var center := _surface_water_site_near(world_start_position) if type=="Freshwater" else _random_valid_site(rng)
		if center == Vector3.ZERO:
			continue
		resource_sites.append({"type":type,"position":center,"range":13.0,"initially_observed":_world_position_is_revealed(center)})
		if type == "Timber":
			_create_forest_patch(center, rng)
		elif type == "Stone":
			_create_stone_patch(center, rng)
		elif type!="Freshwater":
			_create_resource_marker(type, center)
	ResourceSystem.register_local_occurrences(resource_sites, GameState.province_terrain)


func _surface_water_site_near(origin:Vector3)->Vector3:
	var river_z:=clampf(origin.z,-755.0,755.0)
	var river_x:=_world_river_x(river_z)
	if river_x==INF: return Vector3.ZERO
	return Vector3(river_x,_height_at(river_x,river_z)+0.004,river_z)

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
	selection_mesh.inner_radius = 0.45
	selection_mesh.outer_radius = 0.52
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
	_ensure_settlement_convoy_marker()
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

func _ensure_settlement_convoy_marker()->void:
	if settlement_convoy_marker and is_instance_valid(settlement_convoy_marker): return
	settlement_convoy_marker=Node3D.new()
	settlement_convoy_marker.name="SettlementFoundingConvoy"
	settlement_convoy_marker.visible=false
	add_child(settlement_convoy_marker)
	settlement_convoy_icon=Node3D.new()
	settlement_convoy_icon.name="SettlementConvoyMapIcon"
	settlement_convoy_marker.add_child(settlement_convoy_icon)
	var banner:=Sprite3D.new()
	banner.name="SettlementConvoyBanner"
	banner.texture=_founding_banner_texture(GameState.founding_banner_index)
	banner.pixel_size=0.009
	banner.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	banner.no_depth_test=true
	banner.render_priority=13
	banner.position=Vector3(0.0,2.4,0.0)
	settlement_convoy_icon.add_child(banner)
	settlement_convoy_label=Label3D.new()
	settlement_convoy_label.name="SettlementConvoyLabel"
	settlement_convoy_label.font_size=12
	settlement_convoy_label.outline_size=4
	settlement_convoy_label.modulate=Color("#f0d484")
	settlement_convoy_label.outline_modulate=Color(0.018,0.026,0.028,0.97)
	settlement_convoy_label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	settlement_convoy_label.fixed_size=true
	settlement_convoy_label.no_depth_test=true
	settlement_convoy_label.render_priority=12
	settlement_convoy_marker.add_child(settlement_convoy_label)
	settlement_convoy_detail=Node3D.new()
	settlement_convoy_detail.name="SettlementConvoyPhysicalDetail"
	settlement_convoy_detail.scale=Vector3.ONE*CONVOY_DETAIL_SCALE
	settlement_convoy_marker.add_child(settlement_convoy_detail)
	_create_wagon(settlement_convoy_detail,Vector3(-1.3,0.0,0.7),0.07)
	_create_wagon(settlement_convoy_detail,Vector3(1.2,0.0,-0.6),-0.08)

func _refresh_settlement_convoy_marker()->void:
	_ensure_settlement_convoy_marker()
	var convoy:Dictionary=GameState.settlement_convoy
	var active:=bool(convoy.get("active",false))
	settlement_convoy_marker.visible=active
	if not active: return
	var position_value:Variant=convoy.get("position",Vector2.ZERO)
	var position_2d:=Vector2.ZERO
	if position_value is Vector2:
		position_2d=position_value
	elif position_value is Dictionary:
		position_2d=Vector2(float(position_value.get("x",0.0)),float(position_value.get("z",position_value.get("y",0.0))))
	settlement_convoy_marker.position=Vector3(position_2d.x,_height_at(position_2d.x,position_2d.y)+0.002,position_2d.y)
	if settlement_convoy_label:
		settlement_convoy_label.text="SETTLEMENT CONVOY  •  %s  •  %d%%" % [_compact_population(int(convoy.get("population",0))),roundi(float(convoy.get("progress",0.0))*100.0)]

func _update_scale_lod() -> void:
	if camera == null:
		return
	var close_view := camera.size <= 2.4
	var settlement_fabric_view:=camera.size<=SETTLEMENT_FABRIC_MAX_ZOOM
	if settler_map_ring:
		settler_map_ring.visible=not GameState.settlement_site_committed
	if convoy_map_icon:
		convoy_map_icon.visible = not close_view and GameState.founding_expedition_active()
		convoy_map_icon.scale = Vector3.ONE * maxf(0.045, camera.size / 28.0)
	if convoy_map_label:
		convoy_map_label.visible=not close_view and GameState.founding_expedition_active()
		convoy_map_label.position.y=-camera.size*0.035
	if convoy_detail_root:
		convoy_detail_root.visible = close_view and GameState.founding_expedition_active()
	if settlement_convoy_icon:
		settlement_convoy_icon.visible=bool(GameState.settlement_convoy.get("active",false)) and not close_view
		settlement_convoy_icon.scale=Vector3.ONE*maxf(0.045,camera.size/28.0)
	if settlement_convoy_detail:
		settlement_convoy_detail.visible=bool(GameState.settlement_convoy.get("active",false)) and close_view
	if settlement_convoy_label:
		settlement_convoy_label.visible=bool(GameState.settlement_convoy.get("active",false)) and camera.size>=0.82
		settlement_convoy_label.position.y=-camera.size*0.070
	if lens_ring:
		lens_ring.scale=Vector3.ONE*clampf(camera.size*0.10,1.0,24.0)
	if settlement_visual_root:
		settlement_visual_root.visible = settlement_fabric_view
	if settlement_land_use_root:
		# Roofs and plots cull at regional scale, but a physical megalopolis can span
		# hundreds of kilometres and must not disappear at the same threshold as one
		# village parcel. Only the four bounded stage-system surfaces survive farther.
		var stage_profile:=_settlement_expansion_visual_profile({"classification":_settlement_model().classification(),"population":roundi(_settlement_model().primary_population_exact())})
		var stage_max_zoom:=_settlement_stage_landscape_max_zoom(stage_profile)
		settlement_land_use_root.visible=camera.size<=stage_max_zoom
		if settlement_land_use_root.visible:
			for morphology_child in settlement_land_use_root.get_children():
				var is_stage_surface:=String(morphology_child.name) in ["PersistentUrbanSystems","PersistentMetropolitanMobility","PersistentUrbanOpenSpace","PersistentUrbanMassing"]
				# Below this scale authoritative plots, roofs, yards and scars take over.
				# The aggregate strategic mesh crossfades in shader and its route/massing
				# proxies retire completely before they can cover close inspection.
				morphology_child.visible=(camera.size>=0.28 and camera.size<=stage_max_zoom) if is_stage_surface else camera.size<=820.0
				if String(morphology_child.name)=="PersistentUrbanMassing": morphology_child.visible=morphology_child.visible and camera.size<=80.0
				if String(morphology_child.name)=="PersistentDistrictClipmap": morphology_child.visible=camera.size<=2.4
	if settlement_border_root:
		settlement_border_root.visible=camera.size>=0.34 and camera.size<=2600.0
	if settlement_network_marker_root:
		# Physical fabric and claim detail retire before true world view; the bounded
		# civic-symbol layer remains so a civilization never disappears from its planet.
		settlement_network_marker_root.visible=camera.size>=0.82 and camera.size<=18000.0
	if settlement_network_fabric_root:
		settlement_network_fabric_root.visible=camera.size<=2600.0
	_update_settlement_surface_lod_materials()
	if settlement_blip:
		# Never lay a bright game token over visible physical settlement fabric. The
		# locator exists only after roofs and occupied ground have collapsed below the
		# strategic map's useful detail threshold.
		var blip_profile:=_settlement_expansion_visual_profile({"classification":_settlement_model().classification(),"population":roundi(_settlement_model().primary_population_exact())})
		settlement_blip.visible = "Hearth Circle" in GameState.settlement_completed and camera.size>_settlement_stage_marker_zoom(blip_profile)
		settlement_blip.scale = Vector3.ONE * maxf(0.010, camera.size * 0.0048)*float(blip_profile.marker_scale)
	if settlement_map_label:
		# Google-Earth-like readability requires a name before the physical fabric
		# becomes a tiny unlabeled fleck. The strategic blip still waits for the wider
		# threshold; only the label overlaps the intermediate morphology LOD.
		settlement_map_label.visible=camera.size>=0.82 and camera.size<=18000.0
		if settlement_map_label.visible and "Hearth Circle" in GameState.settlement_completed:
			var label_center:=GameState.settlement_founded_at
			var inspection_label:=camera.size<=2.4
			var world_orientation:=camera.size>1600.0
			settlement_map_label.font_size=10 if inspection_label or world_orientation else 12
			settlement_map_label.outline_size=3 if inspection_label else 4
			settlement_map_label.text=_settlement_map_label_text(camera.size)
			if inspection_label:
				# Project the camera's screen-up axis onto the ground and move the label
				# beyond the central roof fabric. It remains anchored geographically, but
				# no longer masks the very morphology the player zoomed in to inspect.
				var screen_up_xz:=Vector2(camera.global_basis.y.x,camera.global_basis.y.z)
				if screen_up_xz.length_squared()<0.0001: screen_up_xz=Vector2(0.0,-1.0)
				var inspection_offset:=minf(camera.size*0.28,maxf(0.095,rendered_settlement_stage_radius*0.12))
				var label_ground:=Vector2(label_center.x,label_center.z)+screen_up_xz.normalized()*inspection_offset
				settlement_map_label.position=Vector3(label_ground.x,_height_at(label_ground.x,label_ground.y)+0.10,label_ground.y)
			else:
				# Keep the annotation one fixed screen-space step above the locator. The
				# previous centered label completely covered both blip and settlement.
				var screen_up_xz:=Vector2(camera.global_basis.y.x,camera.global_basis.y.z)
				if screen_up_xz.length_squared()<0.0001: screen_up_xz=Vector2(0.0,-1.0)
				var regional_offset:=maxf(camera.size*0.030,minf(rendered_settlement_stage_radius*0.36,camera.size*0.18))
				var label_ground:=Vector2(label_center.x,label_center.z)+screen_up_xz.normalized()*regional_offset
				settlement_map_label.position=Vector3(label_ground.x,_height_at(label_ground.x,label_ground.y)+0.13,label_ground.y)

	var detail_visible:=camera.size<=1.8
	if detail_visible and detail_terrain_patch==null and settler_marker:
		_build_detail_terrain_patch(settler_marker.position)
	if detail_terrain_patch:
		detail_terrain_patch.visible = detail_visible
	if close_vegetation_root:
		close_vegetation_root.visible = detail_visible
		var canopy_lod_fade:=clampf((0.76-camera.size)/0.56,0.18,1.0)
		for vegetation_child in close_vegetation_root.get_children():
			if not String(vegetation_child.name).begins_with("TreeCanopies_"): continue
			var canopy_instance:=vegetation_child as MultiMeshInstance3D
			if canopy_instance and canopy_instance.material_override is ShaderMaterial:
				(canopy_instance.material_override as ShaderMaterial).set_shader_parameter("lod_fade",canopy_lod_fade)
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
		settler_map_ring.visible = not close_view and GameState.founding_expedition_active()
		settler_map_ring.scale = Vector3.ONE * maxf(0.006, camera.size * 0.0058)
	if settler_click_shape:
		# Match the visible selection ring at every orthographic zoom. The old
		# four-world-unit sphere covered several kilometres of apparently empty map.
		var click_radius:=clampf(camera.size*0.021,0.004,2.35)
		settler_click_shape.scale=Vector3.ONE*click_radius
	if lens_ring:
		lens_ring.visible=lens_requested_visible and camera.size<=1600.0
		lens_ring.scale = Vector3.ONE * maxf(0.006, camera.size / 160.0)
	if map_selection_marker and map_selection_marker.visible:
		var selection_radius:=_map_selection_radius(camera.size,get_viewport().get_visible_rect().size.y)
		map_selection_marker.scale=Vector3.ONE*selection_radius
	_update_resource_overlay_lod()
	_update_scale_bar()
	if settler_marker and "Hearth Circle" in GameState.settlement_completed:
		_refresh_settlement_footprint()

func _settlement_map_label_text(zoom:float)->String:
	var name:=_settlement_display_name().to_upper()
	if zoom>1600.0: return "HOME  •  %s" % name
	var classification:String=String(_settlement_model().classification()).to_upper()
	if zoom<=2.4: return "%s  •  %s" % [name,classification]
	return "%s  •  %s  •  %s" % [name,classification,_compact_population(roundi(_settlement_model().primary_population_exact()))]

func _update_resource_overlay_lod()->void:
	if resource_overlay_root and is_instance_valid(resource_overlay_root):
		resource_overlay_root.visible=resource_view_enabled
	if not resource_view_enabled or camera==null: return
	var view_key:=_resource_overlay_view_key()
	if view_key!=rendered_resource_overlay_zoom_key:
		_refresh_discovered_resource_overlays()


func _resource_overlay_view_key()->String:
	if camera==null: return "no-camera"
	# Mouse-wheel zoom changes by ~1.18×, so one key band tracks one visible zoom
	# step even in the close map where logarithms are negative.
	var zoom_band:=roundi(log(maxf(0.02,camera.size))/log(1.18))
	var pan_quantum:=maxf(0.08,camera.size*0.28)
	return "%d:%d:%d:%d" % [
		zoom_band,
		floori(camera_target.x/pan_quantum),
		floori(camera_target.z/pan_quantum),
		ResourceSystem.visible_deposits().size()
	]

func _update_settlement_surface_lod_materials()->void:
	if settlement_land_use_root==null: return
	# Shader contrast should move continuously with the camera. Rebuilding geometry
	# inside a broad LOD band made roofs remain in whichever close/distant state was
	# active when the band was first entered.
	# Roofs begin sub-pixel integration before the old 1.25 km threshold. Earlier
	# tonal compression keeps a dense close-map settlement readable without making
	# true ground inspection look like a diagram.
	var aerial_lod:=smoothstep(0.18,0.78,camera.size)
	if absf(aerial_lod-rendered_settlement_aerial_lod)<0.012: return
	rendered_settlement_aerial_lod=aerial_lod
	for child in settlement_land_use_root.get_children():
		if not child is MeshInstance3D: continue
		var instance:=child as MeshInstance3D
		if instance.material_override is ShaderMaterial:
			(instance.material_override as ShaderMaterial).set_shader_parameter("aerial_lod",aerial_lod)

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
	# Godot's built-in UI actions reliably cover the arrow keys. Add physical
	# WASD here so the map also follows the strategy-game convention without
	# changing focus/navigation behavior for buttons and modal controls.
	var wasd:=Vector2(
		(1.0 if Input.is_physical_key_pressed(KEY_D) else 0.0)-(1.0 if Input.is_physical_key_pressed(KEY_A) else 0.0),
		(1.0 if Input.is_physical_key_pressed(KEY_S) else 0.0)-(1.0 if Input.is_physical_key_pressed(KEY_W) else 0.0)
	)
	if wasd.length_squared()>input.length_squared(): input=wasd.normalized() if wasd.length()>1.0 else wasd
	if input.length_squared()<0.001:
		return
	var screen_right:=_camera_ground_screen_right()
	var screen_up:=_camera_ground_screen_up()
	var movement:=_camera_keyboard_movement(input,screen_right,screen_up,camera.size*0.72*delta)
	_set_camera_target(camera_target+movement)


func _camera_keyboard_movement(input:Vector2,screen_right:Vector3,screen_up:Vector3,distance:float)->Vector3:
	# Input.get_vector reports up as negative Y. Express navigation in the
	# camera's real screen axes so right/up stay right/up after camera rotation.
	return (screen_right*input.x-screen_up*input.y)*distance


func _camera_grab_movement(relative:Vector2,screen_right:Vector3,screen_up:Vector3,units_per_pixel:float)->Vector3:
	# Grab-and-drag means the ground follows the pointer: dragging right moves
	# the target left, and dragging down moves the target toward screen-up.
	return (-screen_right*relative.x+screen_up*relative.y)*units_per_pixel

func _camera_ground_screen_right() -> Vector3:
	var axis:=camera.global_transform.basis.x
	axis.y=0.0
	return axis.normalized() if axis.length_squared()>0.000001 else Vector3.RIGHT

func _camera_ground_screen_up() -> Vector3:
	var axis:=camera.global_transform.basis.y
	axis.y=0.0
	if axis.length_squared()>0.000001:
		return axis.normalized()
	var forward:=-camera.global_transform.basis.z
	forward.y=0.0
	return -forward.normalized() if forward.length_squared()>0.000001 else Vector3.FORWARD

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
	var consolidated_clearance:=0.0
	for plot in GameState.settlement_plots:
		var polygon: PackedVector2Array = plot.get("polygon", PackedVector2Array())
		var centroid := Vector2(plot.get("centroid", Vector2.ZERO))
		var use:=String(plot.get("land_use",""))
		var status:=String(plot.get("status","active"))
		var reclamation:=clampf(float(plot.get("reclamation",0.0)),0.0,1.0)
		var generation:=clampi(int(plot.get("fabric_generation",0)),0,12)
		if status in ["active","stressed","damaged"] and generation>=6 and use not in ["field","pasture","water","waste","temporary_encampment"]:
			var mature_distance:=local_point.distance_to(centroid)
			if mature_distance<0.030:
				consolidated_clearance+=(1.0-mature_distance/0.030)*(0.40+float(generation)/20.0)
		if polygon.size() >= 3 and Geometry2D.is_point_in_polygon(local_point, polygon):
			# Abandoned and ruined land regrows from its margins. The authoritative
			# parcel remains visible, but it no longer projects a permanent sterile mask.
			if status in ["vacant","ruin","reclaimed"] and reclamation>=0.18:
				var remnant_radius:=0.0025+0.0045*(1.0-reclamation)
				if local_point.distance_to(centroid)>remnant_radius: continue
			if use=="pasture": continue
			if use=="field":
				# Cropped plots exclude random canopy; hedges and orchard systems are drawn
				# from field morphology rather than accidental woodland sampling.
				return status in ["active","stressed","damaged"]
			if use=="temporary_encampment":
				if status!="active": continue
				return local_point.distance_to(centroid)<=0.0052
			if use in ["residential_compound","mixed_household"]:
				# Founding compounds retain shade trees and garden edges. Dense inherited
				# frontage progressively clears the full occupied parcel.
				if generation>=7: return true
				var occupied_clearance:=0.0055+float(generation)*0.00125+clampf(float(plot.get("roof_coverage",0.0)),0.0,0.7)*0.006
				return local_point.distance_to(centroid)<=occupied_clearance
			return status not in ["reclaimed"]
		var fallback_radius:=0.0045 if use in ["residential_compound","mixed_household","temporary_encampment"] else 0.008
		if status in ["active","stressed","damaged"] and local_point.distance_to(centroid)<fallback_radius: return true
	# Several mature occupied parcels jointly clear their courts, alleys and fire
	# gaps. This is derived from persistent fabric, not a population-sized circle;
	# isolated plots and abandoned districts therefore keep their vegetation.
	if consolidated_clearance>=1.15: return true
	for route in GameState.settlement_routes:
		if not bool(route.get("active",true)): continue
		var points: PackedVector2Array = route.get("points", PackedVector2Array())
		var hierarchy:=String(route.get("hierarchy",route.get("kind","path")))
		var surface_tier:=clampi(int(route.get("surface_tier",0)),0,5)
		var half_width:=maxf(0.00035,float(route.get("width_m",1.2))/2000.0)
		var shoulder:=0.00075 if hierarchy in ["field_track","camp_path"] else (0.00125 if hierarchy in ["path","farm_lane"] else 0.0020)
		if surface_tier>=3: shoulder+=0.00045*float(surface_tier-2)
		for index in points.size() - 1:
			if Geometry2D.get_closest_point_to_segment(local_point, points[index], points[index + 1]).distance_to(local_point)<half_width+shoulder:
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
	var understory_patches:Array[Dictionary]=[]
	for attempt in 3400:
		var local_point := Vector2(rng.randf_range(-0.235, 0.235), rng.randf_range(-0.235, 0.235))
		var world_x := center.x + local_point.x
		var world_z := center.z + local_point.y
		if _height_at(world_x, world_z) <= SEA_LEVEL or _near_persistent_settlement_surface(local_point):
			continue
		var moisture := moisture_noise.get_noise_2d(world_x, world_z)
		# Woodland is nested land cover, not independent tree noise. The previous
		# x940 sample produced a new decision every ~40 m and peppered every camera
		# view with equally sized dots. Kilometre masses establish forest/open country;
		# neighbourhood fields cut margins and clearings; fine noise roughens the edge.
		var woodland_mass:=detail_noise.get_noise_2d(world_x*16.0+71.0,world_z*16.0-39.0)
		var woodland_neighbourhood:=detail_noise.get_noise_2d(world_x*92.0-143.0,world_z*92.0+211.0)
		var woodland_edge:=detail_noise.get_noise_2d(world_x*430.0+317.0,world_z*430.0-173.0)
		var woodland_field:=woodland_mass*0.62+woodland_neighbourhood*0.31+woodland_edge*0.13+moisture*0.38
		var drainage_distance:=_local_drainage_distance_at(world_x,world_z)
		if drainage_distance<0.16:
			# Gallery woodland and brush expose the watershed from altitude. It is
			# strongest beside the damp floor but remains probabilistic, so occupied
			# floodplains still contain openings and cultivation clearings.
			var riparian_weight:=pow(1.0-drainage_distance/0.16,1.35)
			woodland_field+=riparian_weight*(0.28+maxf(0.0,moisture)*0.18)
		var woodland_chance := 0.002
		if woodland_field > 0.015:
			woodland_chance = clampf((woodland_field - 0.015) * 1.08, 0.012, 0.54)
		var is_canopy := rng.randf() < woodland_chance
		var scrub_chance := clampf(0.07 + maxf(0.0, woodland_field) * 0.26, 0.05, 0.24)
		if not is_canopy and rng.randf() > scrub_chance:
			continue
		var height := _close_surface_height_at(world_x, world_z)
		if is_canopy:
			var scale := rng.randf_range(0.74, 1.34)
			var basis := Basis().rotated(Vector3.UP, rng.randf() * TAU).scaled(Vector3(scale * rng.randf_range(0.72, 1.10), scale * rng.randf_range(0.72, 1.22), scale))
			canopy_transforms.append(Transform3D(basis, Vector3(world_x, height + 0.00125 * scale, world_z)))
			canopy_colors.append(Color("#3b5137").lerp(Color("#78815a"), rng.randf_range(0.05, 0.58)))
			# Woodland reads from altitude as connected crowns and edge belts, not a
			# scatter of identical dots. Seed a few overlapping neighbours in strong
			# moisture/noise pockets while preserving cleared plots and routes.
			if woodland_field>0.13:
				if rng.randf()<clampf(0.22+woodland_field*0.48,0.20,0.58):
					understory_patches.append({"center":local_point,"radius":rng.randf_range(0.020,0.046)*(0.86+maxf(0.0,woodland_mass)*0.62),"seed":rng.randi()})
				for cluster_member in rng.randi_range(2,6):
					var neighbour_local:=local_point+Vector2.from_angle(rng.randf()*TAU)*rng.randf_range(0.0035,0.011)
					if _near_persistent_settlement_surface(neighbour_local): continue
					var neighbour_x:=center.x+neighbour_local.x
					var neighbour_z:=center.z+neighbour_local.y
					if _height_at(neighbour_x,neighbour_z)<=SEA_LEVEL: continue
					var neighbour_scale:=scale*rng.randf_range(0.58,0.96)
					var neighbour_basis:=Basis().rotated(Vector3.UP,rng.randf()*TAU).scaled(Vector3(neighbour_scale*rng.randf_range(0.78,1.16),neighbour_scale*rng.randf_range(0.72,1.08),neighbour_scale))
					var neighbour_height:=_close_surface_height_at(neighbour_x,neighbour_z)
					canopy_transforms.append(Transform3D(neighbour_basis,Vector3(neighbour_x,neighbour_height+0.00125*neighbour_scale,neighbour_z)))
					canopy_colors.append(Color("#354b33").lerp(Color("#727d55"),rng.randf_range(0.06,0.54)))
		else:
			var scale := rng.randf_range(0.42, 1.25)
			var basis := Basis().rotated(Vector3.UP, rng.randf() * TAU).scaled(Vector3(scale * rng.randf_range(0.70, 1.45), scale * rng.randf_range(0.42, 0.82), scale))
			scrub_transforms.append(Transform3D(basis, Vector3(world_x, height + 0.0007 * scale, world_z)))
			scrub_colors.append(Color("#4c5937").lerp(Color("#83764d"), rng.randf_range(0.0, 0.48)))
	_create_close_vegetation_multimesh("TreeCanopies", canopy_transforms, canopy_colors, 0.0037, 0.00235)
	_create_close_vegetation_multimesh("ShrubAndGrassPatches", scrub_transforms, scrub_colors, 0.0011, 0.00125)
	_create_woodland_understory(center,understory_patches)

func _create_woodland_understory(center:Vector3,patches:Array[Dictionary])->void:
	if patches.is_empty() or close_vegetation_root==null: return
	var surface:=SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for patch in patches:
		var local_center:Vector2=patch.center
		var radius:=float(patch.radius)
		var patch_seed:=int(patch.seed)
		# Dense crowns share a dark, irregular forest floor at aerial scale. The
		# feathered edge keeps the mass organic; overlap, not a hard polygon, creates
		# the continuous canopy value seen in satellite imagery.
		var center_color:=Color(0.115,0.205,0.105,0.24)
		var edge_color:=Color(0.20,0.285,0.145,0.026)
		var segments:=14
		for index in segments:
			var angle_a:=TAU*float(index)/float(segments)
			var angle_b:=TAU*float(index+1)/float(segments)
			var radius_a:=radius*(0.74+0.19*sin(angle_a*3.0+float(patch_seed%997)*0.017)+0.09*sin(angle_a*7.0))
			var radius_b:=radius*(0.74+0.19*sin(angle_b*3.0+float(patch_seed%997)*0.017)+0.09*sin(angle_b*7.0))
			for entry in [[local_center,center_color],[local_center+Vector2.from_angle(angle_a)*radius_a,edge_color],[local_center+Vector2.from_angle(angle_b)*radius_b,edge_color]]:
				var point_2d:Vector2=entry[0]
				var world_point:=Vector3(center.x+point_2d.x,0.0,center.z+point_2d.y)
				world_point.y=_close_surface_height_at(world_point.x,world_point.z)+0.00105
				surface.set_color(entry[1])
				surface.add_vertex(world_point)
	var mesh:=surface.commit()
	if mesh==null: return
	var instance:=MeshInstance3D.new()
	instance.name="WoodlandUnderstory"
	instance.mesh=mesh
	var material:=StandardMaterial3D.new()
	material.vertex_color_use_as_albedo=true
	material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	material.roughness=1.0
	material.cull_mode=BaseMaterial3D.CULL_DISABLED
	material.no_depth_test=true
	material.render_priority=1
	instance.material_override=material
	close_vegetation_root.add_child(instance)

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
	if node_name=="TreeCanopies":
		for variant in 8:
			var variant_transforms:Array[Transform3D]=[]
			var variant_colors:Array[Color]=[]
			for index in transforms.size():
				if index%8!=variant: continue
				variant_transforms.append(transforms[index])
				variant_colors.append(colors[index])
			_spawn_vegetation_multimesh("%s_%d" % [node_name,variant],mesh,variant_transforms,variant_colors,0,variant)
		return
	_spawn_vegetation_multimesh(node_name,mesh,transforms,colors,1,-1)

func _spawn_vegetation_multimesh(node_name:String,mesh:Mesh,transforms:Array[Transform3D],colors:Array[Color],kind:int,atlas_variant:int)->void:
	if transforms.is_empty(): return
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
	instance.material_override=_vegetation_surface_material(kind,atlas_variant)
	# The canopy atlas already contains crown-scale occlusion. Kilometre-world
	# directional shadows collapsed small crowns into near-black map speckles.
	instance.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	close_vegetation_root.add_child(instance)

func _vegetation_surface_material(kind:int,atlas_variant:=-1)->ShaderMaterial:
	if vegetation_surface_shader==null:
		vegetation_surface_shader=Shader.new()
		vegetation_surface_shader.code="""
shader_type spatial;
render_mode blend_mix, depth_prepass_alpha, cull_disabled, diffuse_burley, specular_disabled;
uniform int vegetation_kind = 0;
uniform int atlas_variant = -1;
uniform float lod_fade = 1.0;
uniform sampler2D canopy_atlas : source_color, filter_linear_mipmap, repeat_disable;
varying vec3 world_position;
float vh(vec2 p) {
	p=fract(p*vec2(123.34,456.21));
	p+=dot(p,p+45.32);
	return fract(p.x*p.y);
}
float vn(vec2 p) {
	vec2 i=floor(p); vec2 f=fract(p); f=f*f*(3.0-2.0*f);
	return mix(mix(vh(i),vh(i+vec2(1,0)),f.x),mix(vh(i+vec2(0,1)),vh(i+vec2(1,1)),f.x),f.y);
}
void vertex() { world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
void fragment() {
	float crown=vn(world_position.xz*410.0+vec2(17.0,-31.0));
	float leaf=vn(world_position.xz*1350.0+vec2(-73.0,29.0));
	float gap=smoothstep(0.68,0.92,vn(world_position.xz*780.0+vec2(91.0,7.0)));
	vec3 base=COLOR.rgb*(0.70+crown*0.38+(leaf-0.5)*0.15);
	if (vegetation_kind==0) {
		if (atlas_variant>=0) {
			vec2 cell=vec2(float(atlas_variant%4),float(atlas_variant/4));
			vec2 atlas_uv=(cell+vec2(0.018)+UV*0.964)/4.0;
			vec4 canopy=texture(canopy_atlas,atlas_uv);
			float canopy_luma=max(dot(canopy.rgb,vec3(0.299,0.587,0.114)),0.12);
			float tint_luma=max(dot(COLOR.rgb,vec3(0.299,0.587,0.114)),0.12);
			vec3 restrained_canopy=mix(vec3(canopy_luma),canopy.rgb,0.42)*vec3(0.72,0.77,0.66);
			base=restrained_canopy*mix(vec3(1.0),COLOR.rgb/tint_luma,0.16);
			base*=0.82+crown*0.16;
			ALPHA=canopy.a*lod_fade;
			ALPHA_SCISSOR_THRESHOLD=0.16;
		}
		base=mix(base,base*vec3(0.64,0.78,0.61),gap*0.42);
		base=mix(base,base*vec3(1.08,1.12,0.78),smoothstep(0.76,0.94,leaf)*0.18);
	} else {
		base=mix(base,base*vec3(1.12,1.02,0.69),gap*0.36);
	}
	ALBEDO=base;
	ROUGHNESS=1.0;
	AO=0.84+crown*0.14;
}
"""
	var material:=ShaderMaterial.new()
	material.shader=vegetation_surface_shader
	material.set_shader_parameter("vegetation_kind",kind)
	material.set_shader_parameter("atlas_variant",atlas_variant)
	var canopy_texture:=load("res://assets/textures/vegetation_canopy_atlas.png")
	if canopy_texture: material.set_shader_parameter("canopy_atlas",canopy_texture)
	return material

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
			surface.set_uv(Vector2(vertex.x/(radius*2.0)+0.5,vertex.z/(radius*2.0)+0.5))
			surface.add_vertex(vertex)
	surface.generate_normals()
	return surface.commit()

func _able_population() -> int:
	return GameState.able_population()

func _process_population_day(context := {}) -> Array[Dictionary]:
	GameState.synchronize_population_allocations()
	var events := ConsequenceEngine.process_day(context)
	AdvisorSystem.refresh_pronouncement_statuses()
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
		# A filled civic seal cannot be mistaken for the hollow selection/resource rings
		# used elsewhere on the map. Six sides stay crisp from town to planetary scale.
		var blip_mesh := CylinderMesh.new()
		blip_mesh.top_radius=0.68
		blip_mesh.bottom_radius=1.0
		blip_mesh.height=0.16
		blip_mesh.radial_segments=6
		settlement_blip.mesh = blip_mesh
		var blip_material := StandardMaterial3D.new()
		blip_material.albedo_color = Color(0.86,0.73,0.38,0.72)
		blip_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		blip_material.emission_enabled = true
		blip_material.emission = Color("#6f5b31")
		blip_material.emission_energy_multiplier = 0.55
		blip_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		blip_material.no_depth_test = true
		settlement_blip.material_override = blip_material
		add_child(settlement_blip)
		settlement_map_label=Label3D.new()
		settlement_map_label.name="SettlementMapLabel"
		settlement_map_label.font_size=12
		settlement_map_label.outline_size=4
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
		settlement_map_label.text="%s  •  %s" % [_settlement_display_name().to_upper(),_compact_population(roundi(_settlement_model().primary_population_exact()))]
		# `_update_scale_lod` owns the screen-aware offset. Re-centering here used to
		# cover the locator again every time simulation state refreshed the fabric.
	_settlement_model().ensure_founded()
	var morphology_lod := _settlement_morphology_lod()
	active_architecture_profile=SocietalValuesModel.architecture_snapshot(GameState.societal_values)
	var architecture_signature:=_settlement_architecture_signature(active_architecture_profile)
	var defense_snapshot:Dictionary=MilitaryCampaign.settlement_defense_snapshot()
	var settlement_classification:String=String(_settlement_model().classification())
	var stage_progress:float=_settlement_visual_stage_progress(GameState.settlement_morphology,settlement_classification)
	var view_signature:="%s:%s:%d" % [_settlement_morphology_view_signature(morphology_lod),_settlement_defense_visual_signature(defense_snapshot),roundi(stage_progress*8.0)]
	var morphology_visual_signature:=_settlement_morphology_visual_signature()
	if not force and rendered_morphology_visual_signature==morphology_visual_signature and rendered_settlement_lod == morphology_lod and rendered_architecture_signature==architecture_signature and rendered_settlement_view_signature==view_signature:
		return
	rendered_morphology_revision = GameState.morphology_revision
	rendered_morphology_visual_signature=morphology_visual_signature
	rendered_settlement_lod = morphology_lod
	rendered_architecture_signature=architecture_signature
	rendered_settlement_view_signature=view_signature
	footprint_population = roundi(_settlement_model().primary_population_exact())
	if settlement_land_use_root:
		settlement_land_use_root.queue_free()
	settlement_land_use_root = Node3D.new()
	settlement_land_use_root.name = "PersistentSettlementMorphology"
	add_child(settlement_land_use_root)
	_rebuild_close_vegetation(center)
	var render_routes:Array[Dictionary]=GameState.settlement_routes
	if morphology_lod==0: render_routes=_settlement_routes_in_current_detail_view(render_routes,center)
	_create_persistent_settlement_routes(center, render_routes, settlement_land_use_root)
	var render_plots:Array[Dictionary]=_settlement_model().plots_for_lod(morphology_lod)
	if morphology_lod==0: render_plots=_settlement_plots_in_current_detail_view(render_plots,center)
	_create_plot_fabric(center, render_plots, morphology_lod, settlement_land_use_root)
	var expansion_profile:=_settlement_expansion_visual_profile({
		"classification":settlement_classification,
		"population":footprint_population,
		"stage_progress":stage_progress
	})
	# Plot fabric supplies the remembered street-by-street settlement. Mature urban
	# systems also need a bounded, stage-specific silhouette that remains legible
	# after billions of residents have collapsed into aggregate simulation records.
	_create_settlement_stage_landscape(center,expansion_profile,GameState.settlement_plots,morphology_lod,settlement_land_use_root,defense_snapshot)
	_create_known_resource_routes(center, settlement_land_use_root)

func _refresh_settlement_network(force:=false)->void:
	if "Hearth Circle" not in GameState.settlement_completed:
		if settlement_border_root: settlement_border_root.visible=false
		if settlement_network_marker_root: settlement_network_marker_root.visible=false
		if settlement_network_fabric_root: settlement_network_fabric_root.visible=false
		return
	_settlement_model().ensure_founded()
	_sync_settlement_territory_contexts()
	var defense_stage:=int(MilitaryCampaign.settlement_defense_snapshot().get("stage",0))
	var architecture_signature:=_settlement_architecture_signature(_settlement_architecture_profile())
	var network_view_key:=_settlement_network_view_key()
	var morphology_visual_signature:=_settlement_morphology_visual_signature()
	# A one-person change cannot alter a continent-scale pixel. Quantizing population
	# prevents birth/death ticks from rebuilding every border, marker and network mesh.
	var population_visual_bucket:=roundi(log(maxf(1.0,float(GameState.population_total)))/log(1.045))
	var signature:="%d:%s:%d:%d:%d:%d:%s:%s" % [GameState.settlement_network_revision,morphology_visual_signature,population_visual_bucket,GameState.player_settlements.size(),int(GameState.elapsed_days/30.0),defense_stage,architecture_signature,network_view_key]
	if not force and signature==rendered_settlement_network_signature: return
	rendered_settlement_network_signature=signature
	var network:Dictionary=_settlement_model().settlement_network_snapshot()
	if settlement_border_root: settlement_border_root.queue_free()
	if settlement_network_marker_root: settlement_network_marker_root.queue_free()
	if settlement_network_fabric_root: settlement_network_fabric_root.queue_free()
	settlement_border_root=Node3D.new()
	settlement_border_root.name="SettlementTerritoryBorders"
	add_child(settlement_border_root)
	settlement_network_marker_root=Node3D.new()
	settlement_network_marker_root.name="SettlementNetworkMarkers"
	add_child(settlement_network_marker_root)
	settlement_network_fabric_root=Node3D.new()
	settlement_network_fabric_root.name="SettlementNetworkPhysicalFabric"
	add_child(settlement_network_fabric_root)
	var border_surface:=SurfaceTool.new()
	border_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var border_halo_surface:=SurfaceTool.new()
	border_halo_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var ownership_surface:=SurfaceTool.new()
	ownership_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segment_count:=0
	var halo_segment_count:=0
	var ownership_triangle_count:=0
	var visible_secondary_settlements:Array[Dictionary]=[]
	for settlement in network.settlements:
		if not bool(settlement.get("primary",false)) and _settlement_marker_in_current_view(settlement): visible_secondary_settlements.append(settlement)
		if not _settlement_boundary_in_current_view(settlement): continue
		var boundary:PackedVector2Array=settlement.get("boundary",PackedVector2Array())
		var radius:=float(settlement.get("claim_radius_km",0.4))
		var visual_profile:=_settlement_expansion_visual_profile(settlement)
		var color:Color=visual_profile.color
		if not bool(settlement.get("primary",false)): color=color.lerp(Color("#8d9165"),0.28)
		color.a=float(visual_profile.border_alpha)*(1.0 if bool(settlement.get("primary",false)) else 0.82)
		var core_width:=clampf(radius*0.009*float(visual_profile.border_scale),0.005,0.095)
		var ownership_color:Color=color
		ownership_color.a=_settlement_claim_fill_alpha(float(visual_profile.fill_alpha))*(1.0 if bool(settlement.get("primary",false)) else 0.72)
		ownership_triangle_count+=_append_settlement_claim_fill(ownership_surface,boundary,ownership_color,0.0032)
		var halo_color:=Color("#121817")
		halo_color.a=0.32 if bool(settlement.get("primary",false)) else 0.24
		halo_segment_count+=_append_settlement_boundary_ribbon(border_halo_surface,boundary,core_width*2.8,halo_color,0.0045)
		segment_count+=_append_settlement_boundary_ribbon(border_surface,boundary,core_width,color,0.0065)
	_create_secondary_settlement_markers(visible_secondary_settlements)
	_create_secondary_settlement_footprints(visible_secondary_settlements)
	if ownership_triangle_count>0:
		var ownership_mesh:=ownership_surface.commit()
		var ownership_instance:=MeshInstance3D.new()
		ownership_instance.name="ControlledGroundWash"
		ownership_instance.mesh=ownership_mesh
		var ownership_material:=StandardMaterial3D.new()
		ownership_material.vertex_color_use_as_albedo=true
		ownership_material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
		ownership_material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
		ownership_material.cull_mode=BaseMaterial3D.CULL_DISABLED
		ownership_material.roughness=1.0
		ownership_material.depth_draw_mode=BaseMaterial3D.DEPTH_DRAW_OPAQUE_ONLY
		ownership_instance.material_override=ownership_material
		ownership_instance.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		settlement_border_root.add_child(ownership_instance)
	if halo_segment_count>0:
		var halo_mesh:=border_halo_surface.commit()
		var halo_instance:=MeshInstance3D.new()
		halo_instance.name="ControlledGroundBoundaryContrast"
		halo_instance.mesh=halo_mesh
		var halo_material:=StandardMaterial3D.new()
		halo_material.vertex_color_use_as_albedo=true
		halo_material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
		halo_material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
		halo_material.cull_mode=BaseMaterial3D.CULL_DISABLED
		halo_material.roughness=1.0
		halo_instance.material_override=halo_material
		settlement_border_root.add_child(halo_instance)
	if segment_count>0:
		var border_mesh:=border_surface.commit()
		var border_instance:=MeshInstance3D.new()
		border_instance.name="ControlledGroundBoundaries"
		border_instance.mesh=border_mesh
		var material:=StandardMaterial3D.new()
		material.vertex_color_use_as_albedo=true
		material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
		material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
		material.cull_mode=BaseMaterial3D.CULL_DISABLED
		material.roughness=1.0
		border_instance.material_override=material
		settlement_border_root.add_child(border_instance)
	_update_scale_lod()

func _sync_settlement_territory_contexts()->void:
	for settlement_variant in GameState.player_settlements:
		var settlement:Dictionary=settlement_variant
		var settlement_id:=String(settlement.get("id",""))
		var position_value:Variant=settlement.get("position",Vector2.ZERO)
		var center:Vector2=position_value if position_value is Vector2 else Vector2.ZERO
		if settlement_id=="": continue
		var sample:=0.25
		var east_west:=absf(_height_at(center.x+sample,center.y)-_height_at(center.x-sample,center.y))/(sample*2.0)
		var north_south:=absf(_height_at(center.x,center.y+sample)-_height_at(center.x,center.y-sample))/(sample*2.0)
		var terrain_permeability:=clampf(1.0-maxf(east_west,north_south)*2.8,0.24,0.96)
		var water_distance:=_river_distance_at(center.x,center.y)*KM_PER_WORLD_UNIT
		var water_access:=clampf(1.0-water_distance/12.0,0.0,1.0) if water_distance<INF else 0.0
		var axes:Array[Dictionary]=[]
		if water_access>0.0:
			axes.append({"kind":"river","direction":_drainage_tangent_at(center.x,center.y),"influence":water_access})
		_settlement_model().set_settlement_territory_context(settlement_id,{"terrain_permeability":terrain_permeability,"water_access":water_access,"travel_access":clampf(float(GameState.simulation_metrics.get("logistics",0.16)),0.0,1.0),"access_axes":axes})

func _settlement_network_lod_band()->int:
	if camera==null: return 0
	if camera.size<=2.4: return 0
	if camera.size<=80.0: return 1
	if camera.size<=600.0: return 2
	if camera.size<=2600.0: return 3
	return 4

func _settlement_network_view_key()->String:
	if camera==null: return "0:0:0"
	var band:=_settlement_network_lod_band()
	# Rebuild only after the camera crosses a sizeable view bucket or a zoom band.
	# This enables spatial culling without turning an ordinary pan into a mesh rebuild
	# every frame.
	var zoom_bucket:=roundi(log(maxf(0.10,camera.size))/log(1.8))
	var bucket_span:=maxf(0.25,pow(1.8,float(zoom_bucket))*0.70)
	return "%d:%d:%d:%d" % [band,zoom_bucket,floori(camera_target.x/bucket_span),floori(camera_target.z/bucket_span)]

func _settlement_boundary_in_current_view(settlement:Dictionary)->bool:
	if camera==null: return true
	if _settlement_network_lod_band()>=4: return false
	var position_value:Variant=settlement.get("position",Vector2.ZERO)
	var position_2d:Vector2=position_value if position_value is Vector2 else Vector2.ZERO
	var radius:=maxf(0.0,float(settlement.get("claim_radius_km",0.0)))
	var target_2d:=Vector2(camera_target.x,camera_target.z)
	# The generous factor covers an oblique orthographic frustum and its corners.
	# Off-screen settlements retain simulation state but contribute zero vertices.
	return position_2d.distance_to(target_2d)<=camera.size*2.8+radius


func _settlement_marker_in_current_view(settlement:Dictionary)->bool:
	if camera==null: return true
	var position_value:Variant=settlement.get("position",Vector2.ZERO)
	var position_2d:Vector2=position_value if position_value is Vector2 else Vector2.ZERO
	var target_2d:=Vector2(camera_target.x,camera_target.z)
	# The icon layer uses a cheaper frustum approximation than terrain-following
	# borders. A generous diagonal margin avoids pop-in during oblique world views.
	return position_2d.distance_to(target_2d)<=camera.size*2.25

func _settlement_visual_stage_progress(summary:Dictionary,classification:String)->float:
	# A place should visibly lean toward its next form before a label changes. These
	# are the same functional ideas used by classification: permanence, exchange,
	# institutions, food reach, connectivity, specialization and multiple districts.
	if summary.is_empty(): return 0.0
	var resident:=maxf(1.0,float(summary.get("resident_population",1.0)))
	var service_ratio:=float(summary.get("service_population",resident))/resident
	var ratios:Array[float]=[]
	match classification.to_lower():
		"founding camp", "founding outpost":
			ratios=[float(summary.get("permanence",0.0))/0.35]
		"hamlet":
			ratios=[float(summary.get("permanence",0.0))/0.50,float(summary.get("diversity",0.0))/0.17]
		"village":
			ratios=[float(summary.get("exchange",0.0))/0.35,float(summary.get("specialization",0.0))/0.30,float(summary.get("connectivity",0.0))/0.30,service_ratio/1.05]
		"town":
			ratios=[float(summary.get("exchange",0.0))/0.55,float(summary.get("institutions",0.0))/0.50,float(summary.get("infrastructure",0.0))/0.50,float(summary.get("food_import_share",0.0))/0.15,float(summary.get("district_count",1))/3.0,service_ratio/1.50]
		"city":
			ratios=[resident/1000000.0,float(summary.get("connectivity",0.0))/0.55,float(summary.get("infrastructure",0.0))/0.64,float(summary.get("specialization",0.0))/0.45,float(summary.get("district_count",1))/4.0]
		"metropolis":
			ratios=[resident/10000000.0,float(summary.get("connectivity",0.0))/0.68,float(summary.get("infrastructure",0.0))/0.75,float(summary.get("specialization",0.0))/0.55,float(summary.get("district_count",1))/6.0]
		_:
			return 1.0 if classification.to_lower() in ["megalopolis","megaregion"] else 0.0
	var weakest:=1.0
	for ratio in ratios: weakest=minf(weakest,clampf(ratio,0.0,1.0))
	# The lower half still reads clearly as the current stage. The final half blends
	# toward the next grammar as the last limiting requirement is actually solved.
	return smoothstep(0.48,1.0,weakest)


func _settlement_feature_reveals(base_count:int,next_count:int,transition:float)->Array[float]:
	# Counts remain strictly bounded, but a newly earned feature no longer pops into
	# existence at one snapped threshold. Its reveal value drives footprint and opacity
	# while every inherited feature stays at full weight.
	var target:=lerpf(float(base_count),float(next_count),clampf(transition,0.0,1.0))
	var visible_count:=clampi(ceili(target-0.00001),base_count,maxi(base_count,next_count))
	var reveals:Array[float]=[]
	for index in visible_count: reveals.append(clampf(target-float(index),0.0,1.0))
	return reveals


func _settlement_expansion_visual_profile(settlement:Dictionary)->Dictionary:
	# One bounded visual grammar communicates settlement maturity without creating
	# more scene nodes as population grows. Classification text, line weight and
	# marker scale reinforce the palette, so ownership is never color-only.
	var classification:=String(settlement.get("classification","founding outpost")).to_lower()
	var population:=maxi(0,int(settlement.get("population",0)))
	var stage:=-1
	if "megalopolis" in classification or "megaregion" in classification: stage=6
	elif "metropolis" in classification: stage=5
	elif "city" in classification: stage=4
	elif "town" in classification: stage=3
	elif "village" in classification: stage=2
	elif "hamlet" in classification: stage=1
	elif "camp" in classification or "outpost" in classification: stage=0
	# Population is only a fallback for legacy/foreign records that genuinely have no
	# functional classification. A crowded expedition does not become a town graphic
	# before it has built the permanent functions that make a town.
	if stage<0:
		if population>=10000000: stage=6
		elif population>=1000000: stage=5
		elif population>=18000: stage=4
		elif population>=2500: stage=3
		elif population>=400: stage=2
		elif population>=80: stage=1
		else: stage=0
	var ids:=["camp","hamlet","village","town","city","metropolis","megalopolis"]
	var labels:=["FOUNDING CAMP","HAMLET","VILLAGE","TOWN","CITY","METROPOLIS","MEGALOPOLIS"]
	var colors:=[Color("#aa9660"),Color("#b8a565"),Color("#c4b16b"),Color("#d2bd70"),Color("#e1ca7b"),Color("#e6c77b"),Color("#edd58c")]
	var transition:=clampf(float(settlement.get("stage_progress",0.0)),0.0,1.0) if stage<6 else 0.0
	var next_stage:=mini(6,stage+1)
	var core_counts:=[1,1,1,1,2,5,8]
	var corridor_counts:=[0,0,1,2,4,6,8]
	var ring_counts:=[0,0,0,0,1,2,3]
	var satellite_counts:=[0,0,0,1,2,5,8]
	var skyline_counts:=[0,0,0,0,2,5,8]
	var mass_counts:=[0,0,0,0,5,7,8]
	var wedge_counts:=[0,0,0,0,1,3,4]
	var district_patch_counts:=[0,1,3,7,12,18,24]
	var core_reveals:=_settlement_feature_reveals(core_counts[stage],core_counts[next_stage],transition)
	var corridor_reveals:=_settlement_feature_reveals(corridor_counts[stage],corridor_counts[next_stage],transition)
	var ring_reveals:=_settlement_feature_reveals(ring_counts[stage],ring_counts[next_stage],transition)
	var satellite_reveals:=_settlement_feature_reveals(satellite_counts[stage],satellite_counts[next_stage],transition)
	var skyline_reveals:=_settlement_feature_reveals(skyline_counts[stage],skyline_counts[next_stage],transition)
	var mass_reveals:=_settlement_feature_reveals(mass_counts[stage],mass_counts[next_stage],transition)
	var wedge_reveals:=_settlement_feature_reveals(wedge_counts[stage],wedge_counts[next_stage],transition)
	var district_reveals:=_settlement_feature_reveals(district_patch_counts[stage],district_patch_counts[next_stage],transition)
	return {
		"stage":stage,"id":ids[stage],"label":labels[stage],"transition":transition,"color":colors[stage].lerp(colors[next_stage],transition),
		"border_scale":lerpf(float([0.72,0.84,1.0,1.18,1.38,1.58,1.78][stage]),float([0.72,0.84,1.0,1.18,1.38,1.58,1.78][next_stage]),transition),
		"border_alpha":lerpf(float([0.54,0.62,0.70,0.78,0.86,0.90,0.94][stage]),float([0.54,0.62,0.70,0.78,0.86,0.90,0.94][next_stage]),transition),
		"fill_alpha":lerpf(float([0.030,0.038,0.047,0.058,0.072,0.082,0.092][stage]),float([0.030,0.038,0.047,0.058,0.072,0.082,0.092][next_stage]),transition),
		"marker_scale":lerpf(float([0.72,0.86,1.0,1.18,1.42,1.72,2.06][stage]),float([0.72,0.86,1.0,1.18,1.42,1.72,2.06][next_stage]),transition),
		# These are strict visual budgets, not counts derived from population. A city
		# and a billion-person megalopolis differ in composition and geographic extent
		# while retaining a small, predictable number of batched surfaces.
		"core_count":core_reveals.size(),"core_reveals":core_reveals,
		"corridor_count":corridor_reveals.size(),"corridor_reveals":corridor_reveals,
		"ring_count":ring_reveals.size(),"ring_reveals":ring_reveals,
		"satellite_count":satellite_reveals.size(),"satellite_reveals":satellite_reveals,
		"skyline_clusters":skyline_reveals.size(),"skyline_reveals":skyline_reveals,
		"masses_per_cluster":mass_reveals.size(),"mass_reveals":mass_reveals,
		"green_wedges":wedge_reveals.size(),"wedge_reveals":wedge_reveals,
		"district_patches":district_reveals.size(),"district_reveals":district_reveals
	}


func _settlement_stage_landscape_max_zoom(profile:Dictionary)->float:
	# Individual fabric always stops at 820 km of view width. Only aggregate urban
	# systems earn wider persistence, and even a megalopolis culls before world view.
	return float([820.0,820.0,820.0,820.0,1100.0,1800.0,2600.0][clampi(int(profile.get("stage",0)),0,6)])


func _settlement_stage_marker_zoom(profile:Dictionary)->float:
	# Small places need a locator soon after roofs collapse. A vast city remains its
	# own locator much longer, avoiding a bright symbol larger than the urban region.
	return float([28.0,36.0,80.0,220.0,700.0,1300.0,2200.0][clampi(int(profile.get("stage",0)),0,6)])


func _settlement_stage_visual_layout(profile:Dictionary,population:int,plots:Array[Dictionary])->Dictionary:
	# The extent is physical aggregate land cover, not one object per resident. Plot
	# geometry wins when it has spread farther; population supplies a stable fallback
	# for late-game abstraction where plot records are intentionally bounded.
	var stage:=clampi(int(profile.get("stage",0)),0,6)
	var density_people_km2:float=float([350.0,500.0,750.0,1050.0,2200.0,3600.0,4600.0][stage])
	var population_radius:=sqrt(maxf(1.0,float(population))/(PI*density_people_km2))
	var plot_radius:=0.0
	for plot in plots:
		var polygon:PackedVector2Array=plot.get("polygon",PackedVector2Array())
		for point in polygon: plot_radius=maxf(plot_radius,point.length())
	var radius:=clampf(maxf(plot_radius*1.05,population_radius),0.12,340.0)
	# Visual fallback centres use one shared density reference at every stage. A
	# classification change can add new centres, but it never teleports the old ones.
	var polycentric_radius:=clampf(maxf(plot_radius*1.05,sqrt(maxf(1.0,float(population))/(PI*4600.0))),0.12,340.0)
	var layout_seed:=absi(hash("%d:%s:urban_system" % [GameState.world_seed,GameState.settlement_name]))
	var axis:=_settlement_civic_axis()
	var architecture:=_settlement_visual_architecture_profile(_settlement_architecture_profile())
	var axiality:=clampf(float(architecture.get("axiality",0.5)),0.0,1.0)
	var terrain_conformity:=clampf(float(architecture.get("terrain_conformity",0.5)),0.0,1.0)
	var formal_weight:=lerpf(0.04,0.94,axiality)*lerpf(1.0,0.68,terrain_conformity)
	var core_budget:=maxi(1,int(profile.get("core_count",1)))
	var cores:Array[Vector2]=[]
	var authoritative_nuclei:Array[Dictionary]=[]
	for nucleus_variant in GameState.settlement_nuclei:
		var nucleus:Dictionary=nucleus_variant
		if bool(nucleus.get("active",true)): authoritative_nuclei.append(nucleus)
	authoritative_nuclei.sort_custom(func(a:Dictionary,b:Dictionary)->bool: return int(a.get("id",0))<int(b.get("id",0)))
	for nucleus in authoritative_nuclei:
		if cores.size()>=core_budget: break
		cores.append(Vector2(nucleus.get("position",Vector2.ZERO)))
	if cores.is_empty(): cores.append(Vector2.ZERO)
	var core_rng:=RandomNumberGenerator.new()
	core_rng.seed=layout_seed^0x2f61c4
	for index in maxi(0,core_budget-1):
		# Golden-angle insertion creates a nested sequence: the first two city cores
		# remain the first two cores of the later metropolis instead of teleporting.
		var organic_angle:=axis+2.39996323*float(index+1)+core_rng.randf_range(-0.20,0.20)
		var formal_angle:=axis+PI*0.5*float(index+1)+PI*0.25*float(index/4)
		var angle:=lerp_angle(organic_angle,formal_angle,formal_weight)
		# Fallback cores spread with the real urban extent. The old fixed 0.72 km
		# sequence compressed every late centre into one bright dot even when the
		# aggregate city covered tens or hundreds of kilometres.
		var distance:=minf(polycentric_radius*0.58,maxf(0.72*pow(1.62,float(index)),polycentric_radius*(0.12+0.055*float(index))))
		if cores.size()<core_budget: cores.append(Vector2.from_angle(angle)*distance)
	var satellites:Array[Vector2]=[]
	var satellite_rng:=RandomNumberGenerator.new()
	satellite_rng.seed=layout_seed^0x71d953
	for index in int(profile.get("satellite_count",0)):
		var organic_angle:=axis+2.39996323*(float(index)+0.43)+satellite_rng.randf_range(-0.14,0.14)
		var formal_angle:=axis+PI*0.25*float(index)+PI*0.125*float(index/8)
		var angle:=lerp_angle(organic_angle,formal_angle,formal_weight*0.72)
		# Satellite centres occupy the middle and outer fabric rather than orbiting
		# immediately beside the old core. Their golden-angle order remains nested.
		var distance:=minf(polycentric_radius*0.86,maxf(1.40*pow(1.52,float(index)),polycentric_radius*(0.36+0.095*float(index))))
		satellites.append(Vector2.from_angle(angle)*distance)
	var corridor_angles:Array[float]=[]
	var corridor_rng:=RandomNumberGenerator.new()
	corridor_rng.seed=layout_seed^0x45a2bd
	var formal_corridor_offsets:=[0.0,PI*0.5,PI*0.25,-PI*0.25,PI*0.125,-PI*0.125,PI*0.375,-PI*0.375]
	for index in int(profile.get("corridor_count",0)):
		var organic_angle:=axis+fposmod(1.94161104*float(index),PI)+corridor_rng.randf_range(-0.08,0.08)
		var formal_angle:float=axis+float(formal_corridor_offsets[index%formal_corridor_offsets.size()])
		corridor_angles.append(_lerp_undirected_angle(organic_angle,formal_angle,formal_weight))
	return {
		"radius":radius,"axis":axis,"cores":cores,"satellites":satellites,
		"core_reveals":(profile.get("core_reveals",[]) as Array).duplicate(),
		"satellite_reveals":(profile.get("satellite_reveals",[]) as Array).duplicate(),
		"corridor_angles":corridor_angles,"corridor_reveals":(profile.get("corridor_reveals",[]) as Array).duplicate(),
		"ring_count":int(profile.get("ring_count",0)),"ring_reveals":(profile.get("ring_reveals",[]) as Array).duplicate(),
		"skyline_clusters":int(profile.get("skyline_clusters",0)),"skyline_reveals":(profile.get("skyline_reveals",[]) as Array).duplicate(),
		"masses_per_cluster":int(profile.get("masses_per_cluster",0)),"mass_reveals":(profile.get("mass_reveals",[]) as Array).duplicate(),
		"green_wedges":int(profile.get("green_wedges",0)),"wedge_reveals":(profile.get("wedge_reveals",[]) as Array).duplicate(),
		"district_patches":int(profile.get("district_patches",0)),"district_reveals":(profile.get("district_reveals",[]) as Array).duplicate(),"seed":layout_seed
	}


func _settlement_stage_land_at(point:Vector2)->bool:
	if not _scout_land_at(point): return false
	if _main_river_distance_at(point.x,point.y)<=MAIN_RIVER_WATER_HALF_WIDTH_KM*1.04: return false
	if _nearest_tributary_distance_at(point)<=TRIBUTARY_WATER_HALF_WIDTH_KM*1.04: return false
	# Strategic urban cover follows buildable relief. Rejecting cliff-scale gradients
	# makes large cities settle valleys and terraces instead of painting over peaks.
	if _terrain_slope_at(point.x,point.y,0.22)>0.92: return false
	return true


func _settlement_stage_resolve_land_offset(center:Vector3,offset:Vector2)->Vector2:
	var world_point:=Vector2(center.x+offset.x,center.z+offset.y)
	if _settlement_stage_land_at(world_point): return offset
	# Rotate around the authoritative settlement centre at the same distance. The
	# bounded search preserves scale and seed while avoiding oceans and channels.
	for index in 12:
		var turn:=0.22*float(index/2+1)*(1.0 if index%2==0 else -1.0)
		var candidate:=offset.rotated(turn)
		if _settlement_stage_land_at(Vector2(center.x+candidate.x,center.z+candidate.y)): return candidate
	return Vector2.ZERO


func _append_settlement_stage_patch(surface:SurfaceTool,world_center:Vector3,radius:float,color:Color,lift:float,atlas_cell:Vector2i,patch_seed:int,segments:=16,elongation:=1.24,edge_alpha_factor:=0.40,alignment_angle:=INF)->int:
	var rng:=RandomNumberGenerator.new()
	rng.seed=patch_seed
	segments=clampi(segments,6,20)
	var angle_offset:=rng.randf()*TAU
	var stretch_axis:=Vector2.from_angle((alignment_angle+rng.randf_range(-0.12,0.12)) if is_finite(alignment_angle) else rng.randf()*TAU)
	var edge_points:Array[Vector2]=[]
	for index in segments:
		var angle:=angle_offset+TAU*float(index)/float(segments)+rng.randf_range(-0.08,0.08)
		var direction:=Vector2.from_angle(angle)
		var stretch:=lerpf(0.74,maxf(1.0,float(elongation)),absf(direction.dot(stretch_axis)))
		edge_points.append(direction*radius*rng.randf_range(0.68,1.14)*stretch)
	var appended:=0
	var edge_color:=color
	# Preserve a readable occupied interior. A near-zero perimeter alpha turned every
	# district into a radial glow; a restrained feather keeps an organic boundary
	# without making the strategic footprint look like a light source.
	edge_color.a*=clampf(edge_alpha_factor,0.0,1.0)
	var texture_coordinates:=Vector2(fposmod(stretch_axis.angle(),TAU)/TAU,float(absi(patch_seed)%997)/997.0)
	var center_2d:=Vector2(world_center.x,world_center.z)
	for index in segments:
		var a:=center_2d+edge_points[index]
		var b:=center_2d+edge_points[(index+1)%segments]
		if not _settlement_stage_land_at(center_2d) or not _settlement_stage_land_at(a) or not _settlement_stage_land_at(b) or not _settlement_stage_land_at(a.lerp(b,0.5)): continue
		for vertex_index in 3:
			var point_2d:=center_2d if vertex_index==0 else (a if vertex_index==1 else b)
			var point:=Vector3(point_2d.x,0.0,point_2d.y)
			point.y=_close_surface_height_at(point.x,point.z)+lift
			surface.set_color(color if vertex_index==0 else edge_color)
			surface.set_uv(_atlas_uv(atlas_cell,Vector2(0.5,0.5)))
			surface.set_uv2(texture_coordinates)
			surface.add_vertex(point)
		appended+=1
	return appended


func _append_settlement_system_ribbon(surface:SurfaceTool,center:Vector3,points:PackedVector2Array,half_width:float,color:Color,lift:float,subdivision_budget:=48)->int:
	if points.size()<2: return 0
	var appended:=0
	var total_length:=0.0
	for length_index in points.size()-1: total_length+=points[length_index].distance_to(points[length_index+1])
	for index in points.size()-1:
		var source_start:=points[index]
		var source_finish:=points[index+1]
		var source_length:=source_start.distance_to(source_finish)
		var subdivisions:=clampi(roundi(float(subdivision_budget)*source_length/maxf(0.0001,total_length)),1,maxi(1,int(subdivision_budget)))
		for subdivision in subdivisions:
			var start:=source_start.lerp(source_finish,float(subdivision)/float(subdivisions))
			var finish:=source_start.lerp(source_finish,float(subdivision+1)/float(subdivisions))
			var direction:=finish-start
			if direction.length_squared()<0.0000001: continue
			var side:=Vector2(-direction.y,direction.x).normalized()*half_width
			var world_middle:=Vector2(center.x,center.z)+(start+finish)*0.5
			if not _settlement_stage_land_at(world_middle) or not _settlement_stage_land_at(world_middle+side) or not _settlement_stage_land_at(world_middle-side): continue
			var corners:=[start-side,finish-side,finish+side,start+side]
			var uvs:=[Vector2(0.0,0.0),Vector2(1.0,0.0),Vector2(1.0,1.0),Vector2(0.0,1.0)]
			for corner_index in [0,1,2,0,2,3]:
				var local_point:Vector2=corners[corner_index]
				var world_point:=Vector3(center.x+local_point.x,0.0,center.z+local_point.y)
				world_point.y=_close_surface_height_at(world_point.x,world_point.z)+lift
				surface.set_color(color)
				surface.set_uv(_atlas_uv(Vector2i(3,2),uvs[corner_index]))
				surface.set_uv2(Vector2(fposmod(direction.angle(),TAU)/TAU,0.37))
				surface.add_vertex(world_point)
			appended+=1
	return appended


func _append_settlement_fabric_ribbon(surface:SurfaceTool,center:Vector3,points:PackedVector2Array,half_width:float,color:Color,lift:float,subdivision_budget:=12)->int:
	# Developed land along a route is a soft settlement gradient, not a road slab.
	# Three lateral bands share each segment: an occupied centre and transparent
	# feather edges. It stays one surface/draw call and has a strict subdivision cap.
	if points.size()<2: return 0
	var appended:=0
	var total_length:=0.0
	for length_index in points.size()-1: total_length+=points[length_index].distance_to(points[length_index+1])
	for index in points.size()-1:
		var source_start:=points[index]
		var source_finish:=points[index+1]
		var source_length:=source_start.distance_to(source_finish)
		var subdivisions:=clampi(roundi(float(subdivision_budget)*source_length/maxf(0.0001,total_length)),1,maxi(1,int(subdivision_budget)))
		for subdivision in subdivisions:
			var start:=source_start.lerp(source_finish,float(subdivision)/float(subdivisions))
			var finish:=source_start.lerp(source_finish,float(subdivision+1)/float(subdivisions))
			var direction:=finish-start
			if direction.length_squared()<0.0000001: continue
			var side:=Vector2(-direction.y,direction.x).normalized()
			var widths:=[-half_width,-half_width*0.38,half_width*0.38,half_width]
			var edge_color:=color
			edge_color.a*=0.025
			var colors:=[edge_color,color,color,edge_color]
			var world_middle:=Vector2(center.x,center.z)+(start+finish)*0.5
			if not _settlement_stage_land_at(world_middle) or not _settlement_stage_land_at(world_middle+side*half_width) or not _settlement_stage_land_at(world_middle-side*half_width): continue
			for band_index in 3:
				var corners:=[
					start+side*float(widths[band_index]),
					finish+side*float(widths[band_index]),
					finish+side*float(widths[band_index+1]),
					start+side*float(widths[band_index+1])
				]
				var corner_colors:=[colors[band_index],colors[band_index],colors[band_index+1],colors[band_index+1]]
				for corner_index in [0,1,2,0,2,3]:
					var local_point:Vector2=corners[corner_index]
					var world_point:=Vector3(center.x+local_point.x,0.0,center.z+local_point.y)
					world_point.y=_close_surface_height_at(world_point.x,world_point.z)+lift
					surface.set_color(corner_colors[corner_index])
					surface.set_uv(_atlas_uv(Vector2i(1,0),Vector2(0.5,0.5)))
					surface.set_uv2(Vector2(fposmod(direction.angle(),TAU)/TAU,0.61))
					surface.add_vertex(world_point)
			appended+=1
	return appended


func _append_settlement_system_ring(surface:SurfaceTool,center:Vector3,radius:float,axis:float,ring_index:int,half_width:float,color:Color,layout_seed:int)->int:
	# Long missing sectors, unequal axes and a low-frequency wobble make this an
	# incomplete bypass/belt system rather than a board-game orbit. Each belt is
	# still just 32 bounded segments.
	var segments:=32
	var appended:=0
	var ellipse:=0.70+0.045*float((absi(layout_seed)+ring_index*13)%4)
	var gap_phase:=float((absi(layout_seed)+ring_index*29)%101)*0.061
	for index in segments:
		var angle_a:=TAU*float(index)/float(segments)
		var angle_b:=TAU*float(index+1)/float(segments)
		# Alternating long arcs establish discontinuous metropolitan bypasses. A
		# second seeded cut prevents the retained arcs from becoming too regular.
		if sin(angle_a*2.0+gap_phase)<-0.08: continue
		if (index*7+ring_index*11+absi(layout_seed))%23 in [0,1,2]: continue
		var wobble_a:=1.0+0.085*sin(angle_a*3.0+float(layout_seed%97)*0.07)+0.035*sin(angle_a*7.0+float(ring_index))
		var wobble_b:=1.0+0.085*sin(angle_b*3.0+float(layout_seed%97)*0.07)+0.035*sin(angle_b*7.0+float(ring_index))
		var point_a:=Vector2(cos(angle_a)*radius*wobble_a,sin(angle_a)*radius*ellipse*wobble_a).rotated(axis)
		var point_b:=Vector2(cos(angle_b)*radius*wobble_b,sin(angle_b)*radius*ellipse*wobble_b).rotated(axis)
		appended+=_append_settlement_system_ribbon(surface,center,PackedVector2Array([point_a,point_b]),half_width,color,0.00285,2)
	return appended


func _settlement_supported_ring_count(layout:Dictionary,stage:int,infrastructure_tier:int,routes:Array)->int:
	# A belt is evidence of a network, never a reward for owning one upgraded road.
	# Three engineered routes support one incomplete bypass; even a mature world-city
	# is capped at two so transport cannot become an orbital visual grammar.
	var route_surface_tier:=0
	var engineered_route_count:=0
	for route_variant in routes:
		var route:Dictionary=route_variant
		if not bool(route.get("active",true)): continue
		var route_tier:=int(route.get("surface_tier",0))
		route_surface_tier=maxi(route_surface_tier,route_tier)
		if route_tier>=3: engineered_route_count+=1
	var network_supported_rings:=engineered_route_count/3
	var stage_ring_cap:=2 if stage>=6 else 1
	return mini(mini(mini(int(layout.get("ring_count",0)),stage_ring_cap),network_supported_rings),maxi(0,mini(route_surface_tier-2,infrastructure_tier-3)))


func _append_settlement_urban_mass(surface:SurfaceTool,center:Vector3,local_center:Vector2,half_width:float,half_depth:float,height:float,angle:float,color:Color)->void:
	# One prism is a skyline sample for an aggregate cluster, never a simulated
	# individual building. All prisms share one surface and therefore one draw call.
	var right:=Vector2.from_angle(angle)*half_width
	var forward:=Vector2(-right.y,right.x).normalized()*half_depth
	var corners:=[local_center-right-forward,local_center+right-forward,local_center+right+forward,local_center-right+forward]
	var base_height:=_close_surface_height_at(center.x+local_center.x,center.z+local_center.y)+0.0015
	var top_color:=color.lightened(0.09)
	for corner_index in [0,1,2,0,2,3]:
		var point_2d:Vector2=corners[corner_index]
		surface.set_color(top_color)
		surface.add_vertex(Vector3(center.x+point_2d.x,base_height+height,center.z+point_2d.y))
	for edge_index in 4:
		var a:Vector2=corners[edge_index]
		var b:Vector2=corners[(edge_index+1)%4]
		var wall_color:=color.darkened(0.08+float(edge_index%2)*0.10)
		for vertex in [[a,0.0],[b,0.0],[b,height],[a,0.0],[b,height],[a,height]]:
			var point_2d:Vector2=vertex[0]
			surface.set_color(wall_color)
			surface.add_vertex(Vector3(center.x+point_2d.x,base_height+float(vertex[1]),center.z+point_2d.y))


func _settlement_stage_damage_ratio(plots:Array[Dictionary])->float:
	var weighted_damage:=0.0
	var total_weight:=0.0
	for plot in plots:
		if String(plot.get("status","active"))=="reclaimed": continue
		var weight:=maxf(0.01,float(plot.get("area_ha",0.01)))
		var status:=String(plot.get("status","active"))
		var damage:=1.0-clampf(float(plot.get("condition",1.0)),0.0,1.0)
		if status=="damaged": damage=maxf(damage,0.48)
		elif status=="ruin": damage=maxf(damage,0.92)
		elif status=="vacant": damage=maxf(damage,0.18)
		weighted_damage+=damage*weight
		total_weight+=weight
	return clampf(weighted_damage/maxf(0.01,total_weight),0.0,1.0)


func _settlement_stage_material_palette(plots:Array[Dictionary],stage:int,architecture:Dictionary)->Dictionary:
	# A city inherits the material history of the civilization that built it. These
	# are aggregate aerial tones, not a second material simulation: the plot ledger
	# remains authoritative and supplies the weights. This keeps every culture's
	# metropolis from collapsing into the same generic grey decal.
	var family_weights:Dictionary={"organic":0.0,"earth":0.0,"stone":0.0}
	for plot in plots:
		if String(plot.get("status","active")) in ["reclaimed","vacant"]: continue
		var family:=String(plot.get("material_family","organic"))
		if not family_weights.has(family): family="organic"
		var area_weight:=maxf(0.01,float(plot.get("area_ha",0.01)))
		if String(plot.get("status","active")) in ["damaged","ruin"]: area_weight*=0.42
		family_weights[family]=float(family_weights.get(family,0.0))+area_weight
	var total_weight:=float(family_weights.get("organic",0.0))+float(family_weights.get("earth",0.0))+float(family_weights.get("stone",0.0))
	if total_weight<=0.0:
		family_weights={"organic":1.0,"earth":0.0,"stone":0.0}
		total_weight=1.0
	var organic_share:=float(family_weights.get("organic",0.0))/total_weight
	var earth_share:=float(family_weights.get("earth",0.0))/total_weight
	var stone_share:=float(family_weights.get("stone",0.0))/total_weight
	var base:Color=Color("#65593d")*organic_share+Color("#765a42")*earth_share+Color("#5e6160")*stone_share
	var monumentality:=clampf(float(architecture.get("monumentality",0.5)),0.0,1.0)
	var civic_space:=clampf(float(architecture.get("civic_space",0.5)),0.0,1.0)
	var late_maturity:=float(clampi(stage,0,6))/6.0
	base=base.lerp(Color("#77736d"),late_maturity*(0.06+stone_share*0.11))
	base=base.lerp(Color("#88775f"),monumentality*0.040)
	var dense:=base.lightened(0.072+monumentality*0.040).lerp(Color("#60625f"),late_maturity*0.10)
	var center:=dense.lightened(0.052+monumentality*0.042)
	var periphery:=base.lerp(Color("#6d7352"),0.12+civic_space*0.07).darkened(0.025)
	var civic:=base.lightened(0.20+monumentality*0.08)
	var industrial:=base.lerp(Color("#4e504e"),0.46+late_maturity*0.14)
	return {
		"base":base,"dense":dense,"center":center,"periphery":periphery,
		"civic":civic,"industrial":industrial,
		"organic_share":organic_share,"earth_share":earth_share,"stone_share":stone_share
	}


func _settlement_stage_function_anchors(plots:Array[Dictionary],land_uses:Array,limit:int)->Array[Vector2]:
	var candidates:Array[Dictionary]=[]
	for plot in plots:
		if String(plot.get("land_use","")) not in land_uses: continue
		if String(plot.get("status","active")) in ["ruin","reclaimed","vacant"]: continue
		candidates.append(plot)
	candidates.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
		var a_score:=float(a.get("service_access",0.0))+float(a.get("prosperity",0.0))*0.35+float(a.get("area_ha",0.0))*0.02
		var b_score:=float(b.get("service_access",0.0))+float(b.get("prosperity",0.0))*0.35+float(b.get("area_ha",0.0))*0.02
		return a_score>b_score
	)
	var anchors:Array[Vector2]=[]
	for candidate in candidates:
		var point:=Vector2(candidate.get("centroid",Vector2.ZERO))
		var separated:=true
		for existing in anchors:
			if existing.distance_to(point)<0.018:
				separated=false
				break
		if separated: anchors.append(point)
		if anchors.size()>=maxi(0,limit): break
	return anchors


func _settlement_defense_visual_profile(snapshot:Dictionary)->Dictionary:
	var construction:Dictionary=snapshot.get("construction",{})
	return {
		"stage":clampi(int(snapshot.get("stage",0)),0,5),
		"integrity":clampf(float(snapshot.get("integrity",1.0)),0.0,1.0),
		"project_stage":clampi(int(construction.get("stage",-1)),-1,5) if bool(construction.get("active",false)) else -1,
		"project_progress":clampf(float(construction.get("progress",0.0)),0.0,1.0) if bool(construction.get("active",false)) else 0.0
	}


func _settlement_defense_visual_signature(snapshot:Dictionary)->String:
	# Five-percent buckets make construction and siege damage visibly advance without
	# rebuilding the city mesh for imperceptible daily fractional changes.
	var profile:=_settlement_defense_visual_profile(snapshot)
	return "%d:%d:%d:%d" % [
		int(profile.stage),roundi(float(profile.integrity)*20.0),
		int(profile.project_stage),roundi(float(profile.project_progress)*20.0)
	]


func _append_settlement_defense_wall_segment(surface:SurfaceTool,center:Vector3,local_a:Vector2,local_b:Vector2,half_width:float,height:float,color:Color)->int:
	var direction:=local_b-local_a
	if direction.length_squared()<0.0000001: return 0
	var side:=Vector2(-direction.y,direction.x).normalized()*half_width
	var local_corners:=[local_a-side,local_b-side,local_b+side,local_a+side]
	var base_points:Array[Vector3]=[]
	var top_points:Array[Vector3]=[]
	for local_point:Vector2 in local_corners:
		var world_point:=Vector3(center.x+local_point.x,0.0,center.z+local_point.y)
		world_point.y=_close_surface_height_at(world_point.x,world_point.z)+0.0028
		base_points.append(world_point)
		top_points.append(world_point+Vector3.UP*height)
	var top_color:=color.lightened(0.055)
	for index in [0,1,2,0,2,3]:
		surface.set_color(top_color)
		surface.add_vertex(top_points[index])
	for side_pair in [[0,1],[2,3]]:
		var a:int=side_pair[0]
		var b:int=side_pair[1]
		var wall_color:=color.darkened(0.08 if a==0 else 0.16)
		for vertex:Vector3 in [base_points[a],base_points[b],top_points[b],base_points[a],top_points[b],top_points[a]]:
			surface.set_color(wall_color)
			surface.add_vertex(vertex)
	return 1


func _settlement_defense_gate_angles(layout:Dictionary,limit:=4)->Array[float]:
	# Gates inherit the actual strategic approaches. A through-road produces opposed
	# openings; later roads add distinct entries instead of another decorative spoke.
	var gates:Array[float]=[]
	var corridors:Array=layout.get("corridor_angles",[])
	for corridor_index in corridors.size():
		if gates.size()>=limit: break
		var angle:=float(corridors[corridor_index])
		gates.append(angle)
		if corridor_index==0 and gates.size()<limit: gates.append(angle+PI)
	if gates.is_empty():
		var axis:=float(layout.get("axis",0.0))
		gates=[axis,axis+PI]
	return gates


func _settlement_defense_angle_near_gate(angle:float,gate_angles:Array[float],half_gap:float)->bool:
	for gate_angle in gate_angles:
		if absf(wrapf(angle-float(gate_angle),-PI,PI))<=half_gap: return true
	return false


func _settlement_defense_segment_breached(index:int,segments:int,integrity:float,layout_seed:int)->bool:
	# Siege damage removes a few contiguous sectors. Independent random omissions made
	# damaged fortifications resemble a dotted selection ring rather than actual breaches.
	var loss:=1.0-clampf(integrity,0.0,1.0)
	if loss<0.055: return false
	var breach_count:=clampi(ceili(loss*3.4),1,3)
	var half_span:=maxi(1,ceili(float(segments)*(0.018+loss*0.070)))
	for breach_index in breach_count:
		var center_index:=absi(hash("%d:%d:breach" % [layout_seed,breach_index]))%segments
		var distance:=absi(index-center_index)
		distance=mini(distance,segments-distance)
		if distance<=half_span: return true
	return false


func _append_settlement_defense_ring(flat_surface:SurfaceTool,mass_surface:SurfaceTool,center:Vector3,local_origin:Vector2,radius:float,axis:float,defense_stage:int,integrity:float,completion:float,constructing:bool,color:Color,layout_seed:int,segments:int,gate_angles:Array[float]=[],angular_form:=false)->Dictionary:
	var flat_count:=0
	var mass_count:=0
	var ellipse:=0.76+0.045*float((absi(layout_seed)+defense_stage*7)%4)
	var build_front_span:=maxi(1,ceili(float(segments)/3.0))
	var built_per_front:=clampi(ceili(float(build_front_span)*completion),0,build_front_span)
	var gate_half_gap:=TAU/float(maxi(6,segments))*(0.48 if defense_stage==3 else 0.54)
	for index in segments:
		# Three coherent work fronts lengthen from separate approaches. Construction no
		# longer manifests as unrelated pieces appearing around the entire perimeter.
		if constructing and index%build_front_span>=built_per_front: continue
		if not constructing and _settlement_defense_segment_breached(index,segments,integrity,layout_seed): continue
		var local_angle_a:=TAU*float(index)/float(segments)
		var local_angle_b:=TAU*float(index+1)/float(segments)
		var middle_world_angle:=axis+(local_angle_a+local_angle_b)*0.5
		if _settlement_defense_angle_near_gate(middle_world_angle,gate_angles,gate_half_gap): continue
		var seed_phase:=float(layout_seed%91)*0.05
		var wobble_a:=1.0+0.092*sin(local_angle_a*3.0+seed_phase)+0.041*sin(local_angle_a*5.0-seed_phase*0.63)
		var wobble_b:=1.0+0.092*sin(local_angle_b*3.0+seed_phase)+0.041*sin(local_angle_b*5.0-seed_phase*0.63)
		if angular_form:
			# Fewer sides and restrained alternating depth give masonry districts a built,
			# surveyed perimeter rather than the smooth geometry of a map-range marker.
			wobble_a*=1.0+(0.045 if index%2==0 else -0.025)
			wobble_b*=1.0+(0.045 if (index+1)%2==0 else -0.025)
		var point_a:=local_origin+Vector2(cos(local_angle_a)*radius*wobble_a,sin(local_angle_a)*radius*ellipse*wobble_a).rotated(axis)
		var point_b:=local_origin+Vector2(cos(local_angle_b)*radius*wobble_b,sin(local_angle_b)*radius*ellipse*wobble_b).rotated(axis)
		var world_middle:=Vector2(center.x,center.z)+(point_a+point_b)*0.5
		if not _settlement_stage_land_at(world_middle): continue
		if defense_stage<=2:
			var earthwork_width:=clampf(radius*0.022,0.0032,0.042)
			# A dark cut and narrower sunlit berm read as moved earth. One bright line did
			# not communicate the physical depth or direction of an earthwork.
			var ditch_color:=color.darkened(0.38)
			ditch_color.a=0.72
			flat_count+=_append_settlement_system_ribbon(flat_surface,center,PackedVector2Array([point_a,point_b]),earthwork_width*1.55,ditch_color,0.00265,1)
			var berm_color:=color
			berm_color.a=0.82
			flat_count+=_append_settlement_system_ribbon(flat_surface,center,PackedVector2Array([point_a,point_b]),earthwork_width*0.72,berm_color,0.00342,1)
		else:
			var wall_width:=clampf(radius*(0.0060 if defense_stage==3 else 0.0082),0.0018,0.020)
			var wall_height:=clampf((0.007 if defense_stage==3 else (0.014 if defense_stage==4 else 0.020))*lerpf(0.78,1.0,integrity),0.004,0.028)
			mass_count+=_append_settlement_defense_wall_segment(mass_surface,center,point_a,point_b,wall_width,wall_height,color)
	return {"flat":flat_count,"mass":mass_count}


func _append_settlement_modern_defense_network(flat_surface:SurfaceTool,mass_surface:SurfaceTool,center:Vector3,layout:Dictionary,network_radius:float,integrity:float,completion:float,constructing:bool,color:Color,layout_seed:int)->Dictionary:
	# A late defensive network protects approaches and strategic nodes. It is neither a
	# medieval city wall nor one perimeter wide enough to encircle a modern metropolis.
	var flat_count:=0
	var mass_count:=0
	var axis:=float(layout.get("axis",0.0))
	var sector_budget:=6
	var visible_sectors:=clampi(ceili(float(sector_budget)*completion),0,sector_budget)
	for sector_index in visible_sectors:
		var disabled_sample:=float(absi(hash("%d:%d:modern_damage" % [layout_seed,sector_index]))%1000)/1000.0
		if not constructing and disabled_sample>integrity: continue
		var angle:=axis+TAU*(float(sector_index)+0.17)/float(sector_budget)+0.13*sin(float(sector_index)*2.31+float(layout_seed%37))
		var radial:=Vector2.from_angle(angle)
		var tangent:=Vector2(-radial.y,radial.x)
		var anchor:=_settlement_stage_resolve_land_offset(center,radial*network_radius)
		if anchor==Vector2.ZERO and not _settlement_stage_land_at(Vector2(center.x,center.z)): continue
		var arm:=clampf(network_radius*0.075,0.040,0.26)
		var depth:=clampf(network_radius*0.035,0.020,0.13)
		var left:=anchor-tangent*arm+radial*depth
		var salient:=anchor-radial*depth
		var right:=anchor+tangent*arm+radial*depth
		var obstacle_color:=color.darkened(0.18)
		obstacle_color.a=0.66
		flat_count+=_append_settlement_system_ribbon(flat_surface,center,PackedVector2Array([left,salient,right]),clampf(network_radius*0.006,0.004,0.032),obstacle_color,0.00315,4)
		var bunker_width:=clampf(network_radius*0.008,0.0040,0.025)
		var bunker_height:=clampf(network_radius*0.0038,0.006,0.020)*lerpf(0.72,1.0,integrity)
		_append_settlement_urban_mass(mass_surface,center,salient,bunker_width,bunker_width*1.65,bunker_height,angle+PI*0.5,color.darkened(0.08))
		mass_count+=1
	return {"flat":flat_count,"mass":mass_count}


func _append_settlement_defense_visuals(flat_surface:SurfaceTool,mass_surface:SurfaceTool,center:Vector3,layout:Dictionary,population:int,defense_stage:int,integrity:float,completion:float,constructing:bool,plots:Array[Dictionary]=[])->Dictionary:
	if defense_stage<=0 or completion<=0.0: return {"flat":0,"mass":0}
	var radius:=float(layout.radius)
	var axis:=float(layout.axis)
	var layout_seed:=int(layout.seed)^0x5de71
	var cores:Array=layout.cores
	var flat_count:=0
	var mass_count:=0
	var colors:=[Color("#000000"),Color("#55472f"),Color("#675138"),Color("#33271d"),Color("#4b4a46"),Color("#50534f")]
	var color:Color=colors[defense_stage]
	if constructing: color=color.lightened(0.12)
	else: color=color.lerp(Color("#363331"),1.0-integrity)
	# Early perimeter technologies defend the historical inhabited core, not every
	# suburb represented by the population-derived strategic footprint.
	var population_order:=log(maxf(10.0,float(population)))/log(10.0)
	var primary_radius:=minf(radius*0.22,0.10+population_order*0.14)
	primary_radius=maxf(0.09,primary_radius)
	var gate_angles:=_settlement_defense_gate_angles(layout,3)
	var ring_specs:Array[Dictionary]=[]
	match defense_stage:
		2: ring_specs.append({"origin":Vector2.ZERO,"radius":primary_radius*0.90,"segments":30,"gates":gate_angles,"angular":false})
		3: ring_specs.append({"origin":Vector2.ZERO,"radius":primary_radius,"segments":24,"gates":gate_angles,"angular":false})
		4:
			var district_anchors:=_settlement_stage_function_anchors(plots,["communal","civic","sacred","market","storage"],3)
			if district_anchors.is_empty():
				for core in cores: district_anchors.append(Vector2(core))
			var district_count:=mini(3,district_anchors.size())
			for core_index in district_count:
				ring_specs.append({"origin":Vector2(district_anchors[core_index]),"radius":maxf(0.065,minf(primary_radius*0.32,radius*0.075)),"segments":10,"gates":gate_angles,"angular":true})
		5:
			var infrastructure_tier:=clampi(int(ProgressionSystem.domain_tier("infrastructure")),0,8)
			var security_tier:=clampi(int(ProgressionSystem.domain_tier("security")),0,8)
			if maxi(infrastructure_tier,security_tier)>=5:
				var network_counts:=_append_settlement_modern_defense_network(flat_surface,mass_surface,center,layout,minf(radius*0.52,maxf(primary_radius*1.7,0.38)),integrity,completion,constructing,color,layout_seed)
				flat_count+=int(network_counts.flat)
				mass_count+=int(network_counts.mass)
			else:
				# Premodern bastions form one compact angular stronghold with detached
				# district redoubts. The metropolitan footprint remains visibly outside it.
				ring_specs.append({"origin":Vector2.ZERO,"radius":primary_radius,"segments":12,"gates":gate_angles,"angular":true})
				var district_count:=mini(2,cores.size())
				for core_index in district_count:
					ring_specs.append({"origin":Vector2(cores[core_index]),"radius":maxf(0.075,minf(primary_radius*0.27,radius*0.065)),"segments":8,"gates":gate_angles,"angular":true})
	for ring_index in ring_specs.size():
		var spec:Dictionary=ring_specs[ring_index]
		var counts:=_append_settlement_defense_ring(flat_surface,mass_surface,center,Vector2(spec.origin),float(spec.radius),axis+float(ring_index)*0.07,defense_stage,integrity,completion,constructing,color,layout_seed+ring_index*131,int(spec.segments),spec.get("gates",[]),bool(spec.get("angular",false)))
		flat_count+=int(counts.flat)
		mass_count+=int(counts.mass)
	# Watch posts, gate towers and bastions are strategic proxies, never one object
	# per soldier. Their fixed cap makes the strongest world-city defense inexpensive.
	var post_budget:int=[0,5,6,6,7,0][defense_stage]
	var visible_posts:=clampi(roundi(float(post_budget)*completion),0,post_budget)
	for post_index in visible_posts:
		# Start with road-facing entries, then fill remaining lookout sectors using the
		# golden angle. Uniform compass dots were indistinguishable from UI handles.
		var angle:float
		if post_index<gate_angles.size(): angle=float(gate_angles[post_index])
		else: angle=axis+2.39996323*float(post_index)+0.17*sin(float(layout_seed%41)+float(post_index))
		var post_radius:=primary_radius*(0.78 if defense_stage<=2 else 1.01)
		var post_offset:=_settlement_stage_resolve_land_offset(center,Vector2.from_angle(angle)*post_radius)
		if post_offset==Vector2.ZERO and not _settlement_stage_land_at(Vector2(center.x,center.z)): continue
		var post_width:=clampf(primary_radius*0.014,0.0022,0.014)
		var post_height:float=[0.0,0.010,0.011,0.014,0.022,0.031][defense_stage]*lerpf(0.76,1.0,integrity)
		_append_settlement_urban_mass(mass_surface,center,post_offset,post_width,post_width*(1.0 if defense_stage<5 else 1.35),post_height,angle,color)
		mass_count+=1
	return {"flat":flat_count,"mass":mass_count}


func _settlement_district_clipmap_candidates(center:Vector3,layout:Dictionary,stage:int,architecture:Dictionary)->Array[Dictionary]:
	# The simulation stores bounded aggregate plots. Close inspection of a mature city
	# still needs visible block-scale evidence outside that historical sample, so this
	# builds a deterministic camera-local clipmap. Population alters the occupied radius;
	# it never increases the 384-instance draw budget.
	if camera==null or stage<3 or camera.size>2.4: return []
	var radius:=float(layout.get("radius",0.0))
	if radius<=0.0: return []
	var local_target:=Vector2(camera_target.x-center.x,camera_target.z-center.z)
	if local_target.length()>radius*1.10+camera.size*1.8: return []
	var visual_architecture:=_settlement_visual_architecture_profile(architecture)
	var axiality:=clampf(float(visual_architecture.get("axiality",0.5)),0.0,1.0)
	var permeability:=clampf(float(visual_architecture.get("permeability",0.5)),0.0,1.0)
	var civic_space:=clampf(float(visual_architecture.get("civic_space",0.5)),0.0,1.0)
	var terrain_conformity:=clampf(float(visual_architecture.get("terrain_conformity",0.5)),0.0,1.0)
	var axis:=float(layout.get("axis",0.0))
	var cell_size:=clampf(camera.size/22.0,0.009,0.11)
	var view_radius:=maxf(camera.size*0.92,cell_size*8.0)
	var half_steps:=clampi(ceili(view_radius/cell_size),8,28)
	var base_cell:=Vector2i(floori((center.x+local_target.x)/cell_size),floori((center.z+local_target.y)/cell_size))
	var cores:Array=layout.get("cores",[])
	var satellites:Array=layout.get("satellites",[])
	var corridors:Array=layout.get("corridor_angles",[])
	var candidates:Array[Dictionary]=[]
	var district_bearings:Dictionary={}
	for z_step in range(-half_steps,half_steps+1):
		for x_step in range(-half_steps,half_steps+1):
			var cell:=base_cell+Vector2i(x_step,z_step)
			var seed:=absi(hash("%d:%d:%d:district_clipmap" % [GameState.world_seed,cell.x,cell.y]))
			var jitter:=Vector2(float((seed>>4)%1000)/999.0-0.5,float((seed>>15)%1000)/999.0-0.5)*cell_size*0.10
			var world_point:=Vector2((float(cell.x)+0.5)*cell_size,(float(cell.y)+0.5)*cell_size)+jitter
			var local_point:=world_point-Vector2(center.x,center.z)
			if local_point.distance_to(local_target)>view_radius*1.42: continue
			var radial_t:=local_point.length()/maxf(0.001,radius)
			if radial_t>0.88 or not _settlement_stage_land_at(world_point): continue
			var centre_influence:=0.0
			for core in cores:
				centre_influence=maxf(centre_influence,1.0-clampf(local_point.distance_to(Vector2(core))/maxf(0.12,radius*0.20),0.0,1.0))
			for satellite in satellites:
				centre_influence=maxf(centre_influence,(1.0-clampf(local_point.distance_to(Vector2(satellite))/maxf(0.10,radius*0.15),0.0,1.0))*0.82)
			var corridor_influence:=0.0
			for corridor_angle in corridors:
				var direction:=Vector2.from_angle(float(corridor_angle))
				var side:=Vector2(-direction.y,direction.x)
				corridor_influence=maxf(corridor_influence,1.0-clampf(absf(local_point.dot(side))/maxf(0.08,radius*0.075),0.0,1.0))
			var occupancy:=clampf(0.80-radial_t*0.48+centre_influence*0.34+corridor_influence*0.18+(0.5-permeability)*0.14,0.14,0.96)
			# High-civic-space cultures preserve recurring commons; permeability creates
			# finer gaps and passages without changing the bounded number of candidates.
			var open_space_sample:=float((seed>>7)%1000)/999.0
			if open_space_sample<0.025+civic_space*0.105+permeability*0.030: continue
			var occupancy_sample:=float((seed>>21)%1000)/999.0
			if occupancy_sample>occupancy: continue
			# Neighboring blocks inherit one district bearing. Per-cell random rotation
			# produced scattered confetti; local alignment produces streets and quarters,
			# while the district bearing itself can still follow terrain in organic cultures.
			var district_span:=clampi(roundi(lerpf(4.0,8.0,axiality)),4,8)
			var district_cell:=Vector2i(floori(float(cell.x)/float(district_span)),floori(float(cell.y)/float(district_span)))
			var district_seed:=absi(hash("%d:%d:%d:district_bearing" % [GameState.world_seed,district_cell.x,district_cell.y]))
			var bearing_key:="%d:%d" % [district_cell.x,district_cell.y]
			var alignment:float
			if district_bearings.has(bearing_key):
				alignment=float(district_bearings[bearing_key])
			else:
				var organic_angle:=float(district_seed%6283)/1000.0
				var district_center:=Vector2((float(district_cell.x)+0.5)*float(district_span)*cell_size,(float(district_cell.y)+0.5)*float(district_span)*cell_size)
				organic_angle=_lerp_undirected_angle(organic_angle,_terrain_contour_angle(district_center,organic_angle),terrain_conformity*0.86)
				var formal_angle:=axis+(PI*0.5 if district_seed%2==0 else 0.0)
				var formal_weight:=lerpf(0.05,0.95,axiality)*lerpf(1.0,0.70,terrain_conformity)
				alignment=_lerp_undirected_angle(organic_angle,formal_angle,formal_weight)
				district_bearings[bearing_key]=alignment
			var half_width:=cell_size*lerpf(0.30,0.48,1.0-permeability)*lerpf(0.90,1.08,float((seed>>10)%1000)/999.0)
			var half_depth:=cell_size*lerpf(0.29,0.47,1.0-permeability)*lerpf(0.88,1.10,float((seed>>18)%1000)/999.0)
			# Land use creates readable district hierarchy from the same bounded block
			# budget. Civic roofs cluster around inherited centres; productive roofs
			# favor transport corridors and the middle belt. Everything else remains
			# residential/mixed fabric. These are visual aggregate classes, not agents.
			var land_use:=0
			# A district shares its dominant roof economy. Per-building classification
			# scattered pale and metal roofs like confetti; five-by-five clustering makes
			# civic precincts and productive bands legible from an aerial camera.
			var land_use_sample:=float(absi(hash("%d:district_land_use" % district_seed))%1000)/999.0
			if centre_influence>0.28 and land_use_sample<0.10+civic_space*0.18:
				land_use=1
			elif corridor_influence>0.30 and radial_t>0.16 and land_use_sample<0.42:
				land_use=2
			candidates.append({"point":world_point,"angle":alignment,"half_width":half_width,"half_depth":half_depth,"seed":seed,"distance":local_point.distance_to(local_target),"radial_t":radial_t,"centre_influence":centre_influence,"corridor_influence":corridor_influence,"land_use":land_use})
	candidates.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
		var a_distance_bucket:=floori(float(a.distance)/maxf(0.001,cell_size*1.5))
		var b_distance_bucket:=floori(float(b.distance)/maxf(0.001,cell_size*1.5))
		if a_distance_bucket!=b_distance_bucket: return a_distance_bucket<b_distance_bucket
		return int(a.seed)<int(b.seed)
	)
	if candidates.size()>SETTLEMENT_DISTRICT_CLIPMAP_BUDGET: candidates.resize(SETTLEMENT_DISTRICT_CLIPMAP_BUDGET)
	return candidates


func _create_settlement_district_clipmap(center:Vector3,layout:Dictionary,stage:int,architecture:Dictionary,damage_ratio:float,palette:Dictionary,parent:Node3D)->void:
	var candidates:=_settlement_district_clipmap_candidates(center,layout,stage,architecture)
	if candidates.is_empty(): return
	var visual_architecture:=_settlement_visual_architecture_profile(architecture)
	var monumentality:=clampf(float(visual_architecture.get("monumentality",0.5)),0.0,1.0)
	var infrastructure_tier:=clampi(int(ProgressionSystem.domain_tier("infrastructure")),0,8)
	var height_capability:=clampf(0.24+float(infrastructure_tier)*0.11,0.24,1.0)
	var clipmap_root:=Node3D.new()
	clipmap_root.name="PersistentDistrictClipmap"
	parent.add_child(clipmap_root)
	var groups:Array=[[],[],[]]
	for candidate in candidates:
		groups[clampi(int(candidate.get("land_use",0)),0,2)].append(candidate)
	var organic_share:=float(palette.get("organic_share",0.0))
	var earth_share:=float(palette.get("earth_share",0.0))
	var stone_share:=float(palette.get("stone_share",0.0))
	var atlas:Texture2D=load("res://assets/textures/settlement_roof_material_atlas_late_v1.png") if infrastructure_tier>=4 else load("res://assets/textures/settlement_roof_material_atlas_v1.png")
	for land_use in 3:
		var group:Array=groups[land_use]
		if group.is_empty(): continue
		var multi:=MultiMesh.new()
		multi.transform_format=MultiMesh.TRANSFORM_3D
		multi.use_colors=true
		multi.instance_count=group.size()
		var mesh:=BoxMesh.new()
		mesh.size=Vector3.ONE
		multi.mesh=mesh
		for index in group.size():
			var candidate:Dictionary=group[index]
			var seed:=int(candidate.seed)
			var point:=Vector2(candidate.point)
			var height_noise:=float((seed>>6)%1000)/999.0
			var radial_t:=float(candidate.radial_t)
			var centre_influence:=float(candidate.get("centre_influence",0.0))
			var width:=float(candidate.half_width)*2.0
			var depth:=float(candidate.half_depth)*2.0
			match seed%6:
				0: width*=0.58
				1: depth*=0.58
				2: width*=0.72; depth*=0.88
			if land_use==1:
				width*=lerpf(0.78,1.12,monumentality)
				depth*=lerpf(0.78,1.12,monumentality)
			elif land_use==2:
				width*=1.34
				depth*=0.72
			var height:float=float([0.0,0.0,0.0,0.006,0.010,0.024,0.048][stage])*height_capability*lerpf(0.42,1.0,pow(height_noise,1.65))*(0.76+monumentality*0.52)*lerpf(1.0,0.58,radial_t)
			if land_use==1: height*=1.18+centre_influence*0.72
			elif land_use==2: height*=0.54
			height=maxf(0.0025,height*lerpf(1.0,0.50,damage_ratio))
			var basis:=Basis(Vector3.UP,float(candidate.angle)).scaled(Vector3(width,height,depth))
			var origin:=Vector3(point.x,_close_surface_height_at(point.x,point.y)+height*0.5+0.0022,point.y)
			multi.set_instance_transform(index,Transform3D(basis,origin))
			var tone:Color=palette.dense.lerp(palette.periphery,radial_t*0.62)
			if land_use==1: tone=palette.civic.lerp(tone,0.28)
			elif land_use==2: tone=palette.productive.lerp(tone,0.22).darkened(0.10)
			tone=tone.lerp(Color("#777774"),0.20+height_noise*0.18).lerp(Color("#34312f"),damage_ratio*0.58)
			# The roof photograph supplies joints, tile, sheet or masonry; vertex color
			# provides civilization material, district purpose and war condition.
			tone=tone.lerp(Color.WHITE,0.44)
			tone.a=1.0
			multi.set_instance_color(index,tone)
		var instance:=MultiMeshInstance3D.new()
		instance.name=["MixedQuarters","CivicCenters","ProductiveBands"][land_use]
		instance.multimesh=multi
		var material:=StandardMaterial3D.new()
		material.vertex_color_use_as_albedo=true
		material.albedo_texture=atlas
		var atlas_column:int
		if infrastructure_tier>=4:
			atlas_column=[1 if stone_share>=maxf(organic_share,earth_share) else 0,3,2][land_use]
		else:
			atlas_column=[3 if stone_share>=maxf(organic_share,earth_share) else (2 if earth_share>=organic_share else 1),3,1][land_use]
		var atlas_row:=absi(hash("%s:%d:%d:district_roof" % [GameState.settlement_name,stage,land_use]))%4
		material.uv1_scale=Vector3(0.25,0.25,1.0)
		material.uv1_offset=Vector3(float(atlas_column)*0.25,float(atlas_row)*0.25,0.0)
		material.roughness=0.91
		material.metallic=0.08 if infrastructure_tier>=5 and land_use==2 else 0.0
		instance.material_override=material
		clipmap_root.add_child(instance)


func _create_settlement_stage_landscape(center:Vector3,profile:Dictionary,plots:Array[Dictionary],lod:int,parent:Node3D,defense_snapshot:Dictionary={})->void:
	rendered_settlement_stage_radius=0.0
	var stage:=clampi(int(profile.get("stage",0)),0,6)
	if defense_snapshot.is_empty(): defense_snapshot=MilitaryCampaign.settlement_defense_snapshot()
	var defense_profile:=_settlement_defense_visual_profile(defense_snapshot)
	if stage<2 and int(defense_profile.stage)<=0 and int(defense_profile.project_stage)<=0: return
	var population:=maxi(1,footprint_population if footprint_population>=0 else GameState.population_total)
	var layout:=_settlement_stage_visual_layout(profile,population,plots)
	var radius:=float(layout.radius)
	rendered_settlement_stage_radius=radius
	var layout_seed:=int(layout.seed)
	var rng:=RandomNumberGenerator.new()
	rng.seed=layout_seed
	var architecture:=_settlement_architecture_profile()
	var visual_architecture:=_settlement_visual_architecture_profile(architecture)
	var axiality:=clampf(float(visual_architecture.get("axiality",0.5)),0.0,1.0)
	var monumentality:=clampf(float(visual_architecture.get("monumentality",0.5)),0.0,1.0)
	var civic_space:=clampf(float(visual_architecture.get("civic_space",0.5)),0.0,1.0)
	var permeability:=clampf(float(visual_architecture.get("permeability",0.5)),0.0,1.0)
	var terrain_conformity:=clampf(float(visual_architecture.get("terrain_conformity",0.5)),0.0,1.0)
	var infrastructure_tier:=clampi(int(ProgressionSystem.domain_tier("infrastructure")),0,8)
	var production_tier:=clampi(int(ProgressionSystem.domain_tier("production")),0,8)
	var vertical_capability:=clampf(0.16+float(infrastructure_tier)*0.15,0.16,1.0)
	var urban_surface:=SurfaceTool.new()
	urban_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var mobility_surface:=SurfaceTool.new()
	mobility_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var open_space_surface:=SurfaceTool.new()
	open_space_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var mass_surface:=SurfaceTool.new()
	mass_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var urban_count:=0
	var mobility_count:=0
	var open_space_count:=0
	var mass_count:=0
	var damage_ratio:=_settlement_stage_damage_ratio(plots)
	var palette:=_settlement_stage_material_palette(plots,stage,architecture)
	var late_urban_maturity:=float(stage)/6.0
	# Built land is generally darker and less saturated than surrounding vegetation at
	# aerial scale. Neutral mid-grey overdraw looked like smoke; a material-tinted,
	# charcoal base instead reads as roofs, yards and paved ground accumulated together.
	# Roof fields should be darker than open ground, but not charcoal. Excessive
	# darkening made mature places resemble burned clouds and erased the material
	# history already encoded by the palette.
	var urban_tone:Color=palette.base.lerp(Color("#77736d"),0.12+late_urban_maturity*0.10).darkened(0.055+late_urban_maturity*0.030)
	urban_tone=urban_tone.lerp(Color("#433e3a"),damage_ratio*0.62)
	# This is the strategic aerial silhouette. The prior ~0.19 alpha disappeared
	# into sunlit grass at precisely the 2-10 km views where a town should dominate.
	# Late urban regions must read as inhabited ground before their transport lines.
	# The old low-opacity fabric vanished against detailed satellite terrain, leaving
	# only pale roads and hot centres visible at continental zoom.
	# Strategic settlement cover is physical occupied land, not a translucent heatmap.
	# Keep the terrain present at the edge, but give town-and-later fabric enough optical
	# weight to read as roofs, yards and streets instead of smoke over satellite imagery.
	urban_tone.a=0.340+float(stage)*0.030
	var periphery_tone:Color=palette.periphery.lerp(Color("#716d64"),0.10).darkened(0.045+late_urban_maturity*0.025)
	periphery_tone.a=urban_tone.a
	var cores:Array=layout.cores
	var core_reveals:Array=layout.get("core_reveals",[])
	var render_cores:Array[Vector2]=[]
	for index in cores.size():
		var core_reveal:=clampf(float(core_reveals[index]) if index<core_reveals.size() else 1.0,0.0,1.0)
		var local_center:=_settlement_stage_resolve_land_offset(center,Vector2(cores[index]))
		render_cores.append(local_center)
		var late_core_gain:=float(maxi(0,stage-4))*0.012
		var core_radius:=radius*(0.088+0.0105*float(stage)+late_core_gain+rng.randf_range(-0.010,0.014))*lerpf(0.28,1.0,smoothstep(0.0,1.0,core_reveal))
		var world_center:=Vector3(center.x+local_center.x,0.0,center.z+local_center.y)
		var core_tone:=urban_tone
		core_tone.a*=core_reveal
		urban_count+=_append_settlement_stage_patch(urban_surface,world_center,maxf(0.010,core_radius),core_tone,0.00215,Vector2i(1,0),layout_seed+index*101,16,1.42,0.74,float(layout.axis)+float(index%2)*PI*0.5)
		# Nested density contours make the centre legible from altitude without adding
		# individual buildings. They are deterministic layers in the same one surface.
		if stage>=2:
			var dense_tone:Color=palette.dense.darkened(0.075+late_urban_maturity*0.035)
			dense_tone=dense_tone.lerp(Color("#45413e"),damage_ratio*0.48)
			dense_tone.a=(0.31+float(stage)*0.022)*(1.0 if index==0 else 0.88)*core_reveal
			urban_count+=_append_settlement_stage_patch(urban_surface,world_center,maxf(0.022,core_radius*0.64),dense_tone,0.00231,Vector2i(1,0),layout_seed+37+index*101,6,1.30,0.84,float(layout.axis)+float(index%2)*PI*0.5)
		# Seven high-intensity knots are enough to read the complete megaregional
		# hierarchy; the eighth core keeps its dense contour while preserving the
		# strict sub-5,000-vertex unengineered world-city budget.
		if stage>=4 and index<7:
			var center_tone:Color=palette.center.darkened(0.060+late_urban_maturity*0.030)
			center_tone=center_tone.lerp(Color("#484442"),damage_ratio*0.52)
			center_tone.a=(0.33+float(stage)*0.015)*(1.0 if index==0 else 0.76)*core_reveal
			urban_count+=_append_settlement_stage_patch(urban_surface,world_center,maxf(0.014,core_radius*(0.29 if index==0 else 0.24)),center_tone,0.00243,Vector2i(3,2),layout_seed+59+index*101,6,1.22,0.92,float(layout.axis)+float(index%2)*PI*0.5)
	# Strategic zoom retains a few aggregate scars rather than drawing every ruined
	# structure. The cap is fixed and their location is deterministic.
	var scar_count:=mini(4,ceili(damage_ratio*4.0))
	for index in scar_count:
		var core_center:Vector2=render_cores[index%render_cores.size()]
		var scar_angle:=rng.randf()*TAU
		var scar_center:=core_center+Vector2.from_angle(scar_angle)*radius*rng.randf_range(0.018,0.065)
		var scar_color:=Color("#352f2b")
		scar_color.a=0.16+damage_ratio*0.24
		urban_count+=_append_settlement_stage_patch(urban_surface,Vector3(center.x+scar_center.x,0.0,center.z+scar_center.y),maxf(0.018,radius*rng.randf_range(0.018,0.045)),scar_color,0.00238,Vector2i(2,3),layout_seed+1900+index*97)
	var satellites:Array=layout.satellites
	var satellite_reveals:Array=layout.get("satellite_reveals",[])
	var render_satellites:Array[Vector2]=[]
	for index in satellites.size():
		var satellite_reveal:=clampf(float(satellite_reveals[index]) if index<satellite_reveals.size() else 1.0,0.0,1.0)
		var local_center:=_settlement_stage_resolve_land_offset(center,Vector2(satellites[index]))
		render_satellites.append(local_center)
		var satellite_radius:=radius*rng.randf_range(0.052,0.092)*lerpf(0.24,1.0,satellite_reveal)
		var satellite_tone:Color=periphery_tone
		satellite_tone=satellite_tone.lerp(Color("#433e3a"),damage_ratio*0.52)
		satellite_tone.a=urban_tone.a*0.86*satellite_reveal
		urban_count+=_append_settlement_stage_patch(urban_surface,Vector3(center.x+local_center.x,0.0,center.z+local_center.y),maxf(0.008,satellite_radius),satellite_tone,0.00212,Vector2i(1,0),layout_seed+700+index*83,14,1.52,0.68,float(layout.axis)+float(index%2)*PI*0.5)
	var corridor_angles:Array=layout.corridor_angles
	# Bounded neighborhood lobes grow around inherited cores and satellite towns.
	# Earlier versions placed them on corridor bearings, making the whole metropolis
	# a diagrammatic star. The centres now define the urban region; transport merely
	# stitches it together. These remain aggregate land-cover samples, never houses.
	var district_patch_count:=int(layout.district_patches)
	var district_reveals:Array=layout.get("district_reveals",[])
	var fabric_anchors:Array[Vector2]=[]
	for core_center in render_cores: fabric_anchors.append(core_center)
	for satellite_center in render_satellites: fabric_anchors.append(satellite_center)
	if fabric_anchors.is_empty(): fabric_anchors.append(Vector2.ZERO)
	for patch_index in district_patch_count:
		var patch_reveal:=clampf(float(district_reveals[patch_index]) if patch_index<district_reveals.size() else 1.0,0.0,1.0)
		var anchor_index:=patch_index%fabric_anchors.size()
		var orbit_index:=patch_index/fabric_anchors.size()
		var anchor:Vector2=fabric_anchors[anchor_index]
		var patch_angle:=float(layout.axis)+2.39996323*float(patch_index+1)+float(anchor_index)*0.19
		# Distribute the bounded sample across the actual population-derived footprint.
		# The old fixed 4-12% offsets left a 24,000-person town compressed into a tiny
		# founding dot even though its calculated physical radius was several kilometres.
		# Outer satellite anchors receive a tighter neighborhood; the historical core
		# grows broad inherited lobes, keeping the whole system within its real extent.
		var patches_for_anchor:=maxi(1,ceili(float(district_patch_count)/float(fabric_anchors.size())))
		var distribution_t:=sqrt((float(orbit_index)+0.60)/float(patches_for_anchor))
		var available_reach:=maxf(radius*0.105,radius*0.72-anchor.length())
		var local_reach:=available_reach*lerpf(0.22,0.90,clampf(distribution_t,0.0,1.0))*rng.randf_range(0.84,1.12)
		var patch_offset:=anchor+Vector2.from_angle(patch_angle)*local_reach
		patch_offset=_settlement_stage_resolve_land_offset(center,patch_offset)
		var radial_t:=clampf(patch_offset.length()/maxf(0.001,radius),0.0,1.0)
		# Each patch summarizes a developed neighborhood system, not one block. Coverage
		# ratios deliberately fall as cities become polycentric, but remain large enough
		# that the population-derived footprint reads as inhabited land rather than a few
		# decorative dots inside an otherwise empty mathematical radius.
		var patch_radius_min:float=float([0.0,0.0,0.18,0.15,0.12,0.10,0.09][stage])
		var patch_radius_max:float=float([0.0,0.0,0.29,0.23,0.19,0.17,0.15][stage])
		var patch_radius:=radius*rng.randf_range(patch_radius_min,patch_radius_max)*lerpf(1.08,0.88,radial_t)*lerpf(0.30,1.0,patch_reveal)
		var patch_tone:Color=urban_tone.lerp(periphery_tone,radial_t*0.66)
		patch_tone.a*=lerpf(0.96,0.74,radial_t)*patch_reveal
		var organic_alignment:=patch_angle+0.63*sin(float(layout_seed%97)+float(patch_index)*1.37)
		var formal_alignment:=float(layout.axis)+float((patch_index+anchor_index)%2)*PI*0.5
		var formal_weight:=lerpf(0.04,0.94,axiality)*lerpf(1.0,0.68,terrain_conformity)
		var district_alignment:=_lerp_undirected_angle(organic_alignment,formal_alignment,formal_weight)
		var district_elongation:=lerpf(1.78,1.38,axiality)*lerpf(1.0,1.16,terrain_conformity)
		urban_count+=_append_settlement_stage_patch(urban_surface,Vector3(center.x+patch_offset.x,0.0,center.z+patch_offset.y),maxf(0.025,patch_radius),patch_tone,0.00218,Vector2i(1,0),layout_seed+2400+patch_index*109,9,district_elongation,0.62,district_alignment)
		# Mature districts do not have one uniform built intensity. A fixed subset earns
		# a smaller inner fabric inherited at later stages, producing visible town-centre,
		# station-quarter and neighborhood hierarchy without adding simulated buildings.
		if stage>=3 and patch_index%3==0 and patch_index<15:
			var district_core_tone:Color=palette.dense.darkened(0.18+late_urban_maturity*0.08).lerp(patch_tone,radial_t*0.28)
			district_core_tone.a=(0.34+float(stage)*0.019)*lerpf(1.0,0.80,radial_t)*patch_reveal
			urban_count+=_append_settlement_stage_patch(urban_surface,Vector3(center.x+patch_offset.x,0.0,center.z+patch_offset.y),maxf(0.016,patch_radius*rng.randf_range(0.40,0.56)),district_core_tone,0.00234,Vector2i(3,2),layout_seed+6200+patch_index*137,7,1.48,0.84,district_alignment)
	# Actual civic and productive plots remain visible as strategic anchors after
	# individual parcels cull. These accents are derived from simulated land use.
	var civic_anchors:=_settlement_stage_function_anchors(plots,["communal","civic","sacred","market"],3)
	for civic_index in civic_anchors.size():
		var civic_anchor:Vector2=civic_anchors[civic_index]
		var civic_angle:=float(layout.axis)+float(civic_index)*PI*0.5
		var civic_right:=Vector2.from_angle(civic_angle)*clampf(radius*0.011,0.010,0.075)
		var civic_forward:=Vector2(-civic_right.y,civic_right.x).normalized()*clampf(radius*0.008,0.008,0.055)
		var civic_ground:Color=palette.civic
		civic_ground.a=0.46
		_append_flat_quad(urban_surface,center,civic_anchor,civic_right,civic_forward,civic_ground,0.00252,Vector2i(3,2),layout_seed+3100+civic_index*73)
		urban_count+=1
		if lod<=1:
			var landmark_width:=clampf(radius*0.0034,0.0030,0.026)
			var landmark_height:float=float([0.0,0.004,0.006,0.011,0.019,0.030,0.043][stage])*vertical_capability*(0.72+monumentality*0.58)
			if landmark_height>0.001:
				_append_settlement_urban_mass(mass_surface,center,civic_anchor,landmark_width,landmark_width*0.72,landmark_height,civic_angle,Color("#9b8a6c"))
				mass_count+=1
	var productive_anchors:=_settlement_stage_function_anchors(plots,["workshop","storage","dirty_industry"],3)
	for productive_index in productive_anchors.size():
		var productive_tone:Color=palette.industrial
		productive_tone.a=0.29
		var productive_anchor:Vector2=productive_anchors[productive_index]
		urban_count+=_append_settlement_stage_patch(urban_surface,Vector3(center.x+productive_anchor.x,0.0,center.z+productive_anchor.y),clampf(radius*0.013,0.014,0.085),productive_tone,0.00244,Vector2i(0,0),layout_seed+3500+productive_index*79,8,1.58,0.88,float(layout.axis)+PI*0.5)
	var primary_approach_count:=mini(2,corridor_angles.size())
	var corridor_reveals:Array=layout.get("corridor_reveals",[])
	for index in corridor_angles.size():
		var corridor_reveal:=clampf(float(corridor_reveals[index]) if index<corridor_reveals.size() else 1.0,0.0,1.0)
		var angle:float=corridor_angles[index]
		var direction:=Vector2.from_angle(angle)
		if index%2==1: direction=-direction
		var side:=Vector2(-direction.y,direction.x)
		var bend_strength:=lerpf(1.30,0.26,axiality)*lerpf(0.78,1.34,terrain_conformity)
		var bend:=side*radius*rng.randf_range(-0.055,0.055)*bend_strength
		var points:=PackedVector2Array()
		var district_connector:=index>=primary_approach_count and not render_satellites.is_empty()
		if district_connector:
			# Later corridors stitch satellite centres into the inherited cores. They
			# must not become more giant spokes through the same central pixel.
			var satellite:Vector2=render_satellites[(index-primary_approach_count)%render_satellites.size()]
			var destination:Vector2=render_cores[(index-primary_approach_count+1)%render_cores.size()]
			var connector_delta:=destination-satellite
			if connector_delta.length_squared()<0.000001: continue
			direction=connector_delta.normalized()
			side=Vector2(-direction.y,direction.x)
			var connector_bend:=side*connector_delta.length()*rng.randf_range(-0.16,0.16)*bend_strength
			points=PackedVector2Array([
				satellite,
				satellite.lerp(destination,0.34)+connector_bend,
				satellite.lerp(destination,0.70)-connector_bend*0.52,
				destination
			])
		else:
			# At most two actual approaches enter the primary fabric. Opposed flow can
			# still emerge from their directions without drawing a luminous asterisk.
			# Regional approaches terminate at different edge gates and distributors. They
			# must never all pierce the historical hearth, which made an otherwise organic
			# settlement read as a radial transit diagram from every strategic altitude.
			var gate_sign:=1.0 if index%2==0 else -1.0
			var origin:Vector2=render_cores[index%render_cores.size()]+side*radius*(0.040+0.012*float(stage))*gate_sign
			origin=_settlement_stage_resolve_land_offset(center,origin)
			var outward_factor:=rng.randf_range(0.72,0.92)
			if index==0:
				# The oldest strategic road is a through-route bent around the inherited
				# centre, not a one-ended spoke. Later approaches branch into this fabric.
				points=PackedVector2Array([
					origin-direction*radius*outward_factor,
					origin-direction*radius*0.38+bend*0.62,
					origin,
					origin+direction*radius*0.43-bend*0.48,
					origin+direction*radius*rng.randf_range(0.72,0.91)
				])
			else:
				points=PackedVector2Array([
					origin,
					origin+direction*radius*0.18+bend,
					origin+direction*radius*0.48-bend*0.55,
					origin+direction*radius*outward_factor
				])
		# A new corridor grows outward from its middle instead of appearing at full
		# metropolitan length on the frame where the next capability is approached.
		if corridor_reveal<0.999 and not points.is_empty():
			var reveal_anchor:Vector2=points[points.size()/2]
			var reveal_extent:=lerpf(0.12,1.0,smoothstep(0.0,1.0,corridor_reveal))
			for point_index in points.size(): points[point_index]=reveal_anchor+(points[point_index]-reveal_anchor)*reveal_extent
		var occupied_arm_color:=urban_tone.darkened(0.025)
		occupied_arm_color.a=(0.10+float(stage)*0.011)*corridor_reveal
		var occupied_half_width:=radius*((0.016 if district_connector else 0.019)+float(stage)*0.0024)*lerpf(0.32,1.0,corridor_reveal)
		urban_count+=_append_settlement_fabric_ribbon(urban_surface,center,points,clampf(occupied_half_width,0.014,1.35),occupied_arm_color,0.00222,6)
		var corridor_width:=clampf(radius*(0.0024+float(stage)*0.00042),0.0022,0.115)
		var corridor_color:=Color("#989184").lerp(Color("#b0aa9f"),axiality*0.22)
		corridor_color=corridor_color.lerp(Color("#514b47"),damage_ratio*0.48)
		corridor_color.a=(0.225+float(stage)*0.014+permeability*0.065)*corridor_reveal
		mobility_count+=_append_settlement_system_ribbon(mobility_surface,center,points,corridor_width,corridor_color,0.0030)
	# Circumferential connectors are capability evidence, not a population decal.
	# They appear only after engineered routes or advanced urban infrastructure exist.
	# A capability can support a belt, but only an actually engineered route may draw
	# one. Infrastructure tier alone previously painted an unexplained orbital ring.
	var supported_ring_count:=_settlement_supported_ring_count(layout,stage,infrastructure_tier,GameState.settlement_routes)
	var ring_reveals:Array=layout.get("ring_reveals",[])
	for ring_index in supported_ring_count:
		var ring_reveal:=clampf(float(ring_reveals[ring_index]) if ring_index<ring_reveals.size() else 1.0,0.0,1.0)
		var ring_radius:float=radius*float([0.38,0.61,0.81][ring_index])
		var ring_width:=clampf(radius*(0.0020+float(stage)*0.00030)*lerpf(0.36,1.0,ring_reveal),0.0012,0.090)
		var ring_color:=Color("#858178")
		ring_color.a=(0.26+float(ring_index)*0.035)*ring_reveal
		mobility_count+=_append_settlement_system_ring(mobility_surface,center,ring_radius,float(layout.axis),ring_index,ring_width,ring_color,layout_seed)
	var wedge_reveals:Array=layout.get("wedge_reveals",[])
	for wedge_index in int(layout.green_wedges):
		var wedge_reveal:=clampf(float(wedge_reveals[wedge_index]) if wedge_index<wedge_reveals.size() else 1.0,0.0,1.0)
		var wedge_angle:=float(layout.axis)+TAU*(float(wedge_index)+0.63)/maxf(1.0,float(layout.green_wedges))+rng.randf_range(-0.16,0.16)
		var direction:=Vector2.from_angle(wedge_angle)
		var green_color:=Color("#29493a")
		green_color.a=(0.17+civic_space*0.08)*wedge_reveal
		var green_offset:=direction*radius*rng.randf_range(0.30,0.67)
		green_offset=_settlement_stage_resolve_land_offset(center,green_offset)
		open_space_count+=_append_settlement_stage_patch(open_space_surface,Vector3(center.x+green_offset.x,0.0,center.z+green_offset.y),radius*rng.randf_range(0.060,0.115)*lerpf(0.82,1.18,civic_space)*lerpf(0.28,1.0,wedge_reveal),green_color,0.00245,Vector2i(2,0),layout_seed+4700+wedge_index*127,12)
	if stage>=4:
		# Large workshop roofs remain plot-derived. A separate logistics/industrial
		# belt only appears once aggregate production has genuinely industrialized.
		var industrial_count:=mini(stage-2,maxi(0,production_tier-2))
		for index in industrial_count:
			var industrial_angle:=float(layout.axis)+PI*0.5+TAU*float(index)/float(industrial_count)+rng.randf_range(-0.20,0.20)
			var local_center:=Vector2.from_angle(industrial_angle)*radius*rng.randf_range(0.54,0.78)
			local_center=_settlement_stage_resolve_land_offset(center,local_center)
			var industrial_color:Color=palette.industrial
			industrial_color.a=0.30
			urban_count+=_append_settlement_stage_patch(urban_surface,Vector3(center.x+local_center.x,0.0,center.z+local_center.y),radius*rng.randf_range(0.052,0.082),industrial_color,0.00235,Vector2i(0,0),layout_seed+1400+index*61,6,1.95,0.90,float(layout.axis)+PI*0.5)
	if lod<=1 and stage>=4:
		var skyline_clusters:=mini(int(layout.skyline_clusters),render_cores.size())
		var skyline_reveals:Array=layout.get("skyline_reveals",[])
		var masses_per_cluster:=int(layout.masses_per_cluster)
		var mass_reveals:Array=layout.get("mass_reveals",[])
		for cluster_index in skyline_clusters:
			var cluster_reveal:=clampf(float(skyline_reveals[cluster_index]) if cluster_index<skyline_reveals.size() else 1.0,0.0,1.0)
			var cluster_center:Vector2=render_cores[cluster_index]
			var cluster_radius:=maxf(0.006,radius*(0.018+float(stage)*0.0025)*lerpf(0.25,1.0,cluster_reveal))
			for mass_index in masses_per_cluster:
				var mass_reveal:=clampf(float(mass_reveals[mass_index]) if mass_index<mass_reveals.size() else 1.0,0.0,1.0)*cluster_reveal
				var mass_angle:=rng.randf()*TAU
				var mass_center:=cluster_center+Vector2.from_angle(mass_angle)*cluster_radius*sqrt(rng.randf())
				var half_width:float=float([0.0,0.0,0.0,0.0,0.0042,0.0068,0.0092][stage])*rng.randf_range(0.62,1.28)*lerpf(0.18,1.0,mass_reveal)
				var half_depth:float=half_width*rng.randf_range(0.58,1.42)
				var height:float=float([0.0,0.0,0.0,0.0,0.018,0.046,0.082][stage])*vertical_capability*rng.randf_range(0.42,1.0)*(0.72+monumentality*0.48)*lerpf(1.0,0.54,damage_ratio)*lerpf(0.10,1.0,mass_reveal)
				var mass_color:Color=palette.dense
				mass_color=mass_color.lerp(Color("#7b7d7c"),0.54).lerp(Color("#a29d93"),monumentality*0.16).lerp(Color("#464342"),damage_ratio*0.58)
				var alignment_jitter:=lerpf(0.34,0.07,axiality)
				_append_settlement_urban_mass(mass_surface,center,mass_center,half_width,half_depth,height,float(layout.axis)+rng.randf_range(-alignment_jitter,alignment_jitter),mass_color)
				mass_count+=1
	var defense_counts:=_append_settlement_defense_visuals(urban_surface,mass_surface,center,layout,population,int(defense_profile.stage),float(defense_profile.integrity),1.0,false,plots)
	urban_count+=int(defense_counts.flat)
	mass_count+=int(defense_counts.mass)
	if int(defense_profile.project_stage)>int(defense_profile.stage) and float(defense_profile.project_progress)>0.0:
		var construction_counts:=_append_settlement_defense_visuals(urban_surface,mass_surface,center,layout,population,int(defense_profile.project_stage),1.0,float(defense_profile.project_progress),true,plots)
		urban_count+=int(construction_counts.flat)
		mass_count+=int(construction_counts.mass)
	if urban_count>0: _commit_settlement_surface(urban_surface,"PersistentUrbanSystems",parent,true)
	if mobility_count>0: _commit_settlement_surface(mobility_surface,"PersistentMetropolitanMobility",parent,true)
	if open_space_count>0: _commit_settlement_surface(open_space_surface,"PersistentUrbanOpenSpace",parent,true)
	if mass_count>0: _commit_settlement_surface(mass_surface,"PersistentUrbanMassing",parent,false)
	if lod==0 and stage>=3: _create_settlement_district_clipmap(center,layout,stage,architecture,damage_ratio,palette,parent)

func _settlement_claim_fill_alpha(base_alpha:float)->float:
	if camera==null: return base_alpha
	# Close inspection leaves relief, roofs and fields dominant. Strategic zoom
	# strengthens the same restrained wash enough to make ownership legible.
	if camera.size<=2.4: return 0.0
	return base_alpha*lerpf(0.30,1.0,smoothstep(2.4,180.0,camera.size))

func _append_settlement_claim_fill(surface:SurfaceTool,boundary:PackedVector2Array,color:Color,lift:=0.0032)->int:
	if boundary.size()<3: return 0
	var center:=Vector2.ZERO
	for point in boundary: center+=point
	center/=float(boundary.size())
	for index in boundary.size():
		for point in [center,boundary[index],boundary[(index+1)%boundary.size()]]:
			surface.set_color(color)
			surface.add_vertex(Vector3(point.x,_height_at(point.x,point.y)+lift,point.y))
	return boundary.size()

func _append_settlement_boundary_ribbon(surface:SurfaceTool,boundary:PackedVector2Array,half_width:float,color:Color,lift:=0.006)->int:
	if boundary.size()<3: return 0
	for index in boundary.size():
		var a:=boundary[index]
		var b:=boundary[(index+1)%boundary.size()]
		# Render-only tessellation follows intervening relief while the authoritative
		# border remains the fixed 32-point aggregate polygon.
		var relief_step:=0.045 if camera==null else clampf(camera.size*0.004,0.045,6.0)
		var subdivisions:=clampi(ceili(a.distance_to(b)/relief_step),1,48)
		for subdivision in subdivisions:
			var segment_a:=a.lerp(b,float(subdivision)/float(subdivisions))
			var segment_b:=a.lerp(b,float(subdivision+1)/float(subdivisions))
			var direction:=(segment_b-segment_a).normalized()
			if direction.length_squared()<0.000001: continue
			var side:=Vector2(-direction.y,direction.x)*half_width
			var corners:=[segment_a-side,segment_b-side,segment_b+side,segment_a+side]
			for corner_index in [0,1,2,0,2,3]:
				var point:Vector2=corners[corner_index]
				surface.set_color(color)
				surface.add_vertex(Vector3(point.x,_height_at(point.x,point.y)+lift,point.y))
	return boundary.size()

func _create_secondary_settlement_markers(settlements:Array[Dictionary])->void:
	if settlements.is_empty(): return
	# One MultiMesh draw represents every visible secondary settlement. Labels are
	# deliberately capped and prioritized; owning ten thousand places must not create
	# ten thousand scene nodes merely because the camera is over a continent.
	var prioritized:=settlements.duplicate(true)
	prioritized.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
		var a_stage:=int(_settlement_expansion_visual_profile(a).get("stage",0))
		var b_stage:=int(_settlement_expansion_visual_profile(b).get("stage",0))
		if a_stage!=b_stage: return a_stage>b_stage
		return int(a.get("population",0))>int(b.get("population",0))
	)
	# One civilization may own hundreds of simulated settlements. At true world scale
	# the 64 largest visible places convey the urban system without turning it into noise.
	var marker_set:Array[Dictionary]=prioritized
	if camera!=null and camera.size>2600.0 and marker_set.size()>64: marker_set.resize(64)
	var multi:=MultiMesh.new()
	multi.transform_format=MultiMesh.TRANSFORM_3D
	multi.use_colors=true
	multi.instance_count=marker_set.size()
	var mesh:=CylinderMesh.new()
	mesh.top_radius=0.72
	mesh.bottom_radius=1.0
	mesh.height=0.18
	mesh.radial_segments=16
	multi.mesh=mesh
	# Preserve an almost fixed screen-space weight through regional, continental and
	# planetary zoom. The former 3 km cap reduced every world city below one pixel.
	var marker_radius:=clampf(camera.size*0.0032,0.055,64.0) if camera!=null else 0.055
	for index in marker_set.size():
		var settlement:Dictionary=marker_set[index]
		var visual_profile:=_settlement_expansion_visual_profile(settlement)
		var position_value:Variant=settlement.get("position",Vector2.ZERO)
		var position_2d:Vector2=position_value if position_value is Vector2 else Vector2.ZERO
		var origin:=Vector3(position_2d.x,_height_at(position_2d.x,position_2d.y)+0.004,position_2d.y)
		multi.set_instance_transform(index,Transform3D(Basis().scaled(Vector3.ONE*marker_radius*float(visual_profile.marker_scale)),origin))
		multi.set_instance_color(index,visual_profile.color)
	var blips:=MultiMeshInstance3D.new()
	blips.name="SecondarySettlementBlips"
	blips.multimesh=multi
	var material:=StandardMaterial3D.new()
	material.albedo_color=Color.WHITE
	material.vertex_color_use_as_albedo=true
	material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	blips.material_override=material
	settlement_network_marker_root.add_child(blips)
	var label_limit:=_secondary_settlement_label_limit()
	if prioritized.size()>label_limit: prioritized.resize(label_limit)
	for index in prioritized.size():
		var settlement:Dictionary=prioritized[index]
		var position_value:Variant=settlement.get("position",Vector2.ZERO)
		var position_2d:Vector2=position_value if position_value is Vector2 else Vector2.ZERO
		var label:=Label3D.new()
		label.name="SecondarySettlementLabel_%d" % index
		label.text=("%s  •  %s" % [String(settlement.get("name","SETTLEMENT")),String(settlement.get("classification","outpost")).to_upper()]) if camera!=null and camera.size>2600.0 else ("%s  •  %s  •  %s" % [String(settlement.get("name","SETTLEMENT")),String(settlement.get("classification","outpost")).to_upper(),_compact_population(int(settlement.get("population",0)))])
		label.font_size=9 if camera!=null and camera.size>2600.0 else 11
		label.outline_size=4
		label.modulate=Color("#e3d5a9")
		label.outline_modulate=Color(0.018,0.026,0.028,0.97)
		label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
		label.fixed_size=true
		label.no_depth_test=true
		label.render_priority=11
		label.position=Vector3(position_2d.x,_height_at(position_2d.x,position_2d.y)+marker_radius*2.2,position_2d.y)
		settlement_network_marker_root.add_child(label)


func _secondary_settlement_urban_radius(settlement:Dictionary)->float:
	# Urban cover is deliberately separate from the much larger controlled claim.
	# Population changes geographic extent, while classification changes its density
	# and visual grammar. No resident or building becomes a runtime object.
	var profile:=_settlement_expansion_visual_profile(settlement)
	var stage:=clampi(int(profile.get("stage",0)),0,6)
	var population:=maxf(1.0,float(settlement.get("population",1)))
	var density_people_km2:float=float([350.0,500.0,750.0,1050.0,2200.0,3600.0,4600.0][stage])
	var radius:=sqrt(population/(PI*density_people_km2))
	var claim_radius:=maxf(0.0,float(settlement.get("claim_radius_km",0.0)))
	if claim_radius>0.0: radius=minf(radius,claim_radius*0.82)
	return clampf(radius,0.055,340.0)


func _secondary_settlement_footprint_patch_allocations(settlements:Array[Dictionary])->PackedInt32Array:
	# Every visible place receives a core before larger places receive extra lobes.
	# Round-robin distribution prevents one megalopolis from consuming the whole
	# strategic mesh and fixes the complete network at 512 patches in the worst case.
	var allocations:=PackedInt32Array()
	allocations.resize(settlements.size())
	if settlements.is_empty(): return allocations
	var priority_indices:Array[int]=[]
	for index in settlements.size():
		allocations[index]=1
		priority_indices.append(index)
	priority_indices.sort_custom(func(a:int,b:int)->bool:
		var a_record:Dictionary=settlements[a]
		var b_record:Dictionary=settlements[b]
		var a_stage:=int(_settlement_expansion_visual_profile(a_record).get("stage",0))
		var b_stage:=int(_settlement_expansion_visual_profile(b_record).get("stage",0))
		if a_stage!=b_stage: return a_stage>b_stage
		var a_population:=int(a_record.get("population",0))
		var b_population:=int(b_record.get("population",0))
		if a_population!=b_population: return a_population>b_population
		return String(a_record.get("id",a))<String(b_record.get("id",b))
	)
	var remaining:=maxi(0,SECONDARY_SETTLEMENT_FOOTPRINT_PATCH_BUDGET-settlements.size())
	var desired_by_stage:=[1,2,3,5,8,12,16]
	while remaining>0:
		var distributed:=false
		for index in priority_indices:
			var stage:=clampi(int(_settlement_expansion_visual_profile(settlements[index]).get("stage",0)),0,6)
			if allocations[index]>=int(desired_by_stage[stage]): continue
			allocations[index]+=1
			remaining-=1
			distributed=true
			if remaining<=0: break
		if not distributed: break
	return allocations


func _create_secondary_settlement_footprints(settlements:Array[Dictionary])->void:
	var footprint_parent:Node3D=settlement_network_fabric_root if settlement_network_fabric_root!=null else settlement_network_marker_root
	if settlements.is_empty() or footprint_parent==null: return
	# Cull physical fabric by the same stage-aware horizon as the primary place. At
	# wider views the single marker batch takes over; cities never become screen-sized
	# glowing tokens merely because their detailed fabric has culled.
	var visible:Array[Dictionary]=[]
	for settlement in settlements:
		var profile:=_settlement_expansion_visual_profile(settlement)
		if camera!=null and camera.size>_settlement_stage_landscape_max_zoom(profile): continue
		visible.append(settlement)
	if visible.is_empty(): return
	var allocations:=_secondary_settlement_footprint_patch_allocations(visible)
	var surface:=SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var appended:=0
	var architecture:=_settlement_architecture_profile()
	var visual_architecture:=_settlement_visual_architecture_profile(architecture)
	var axiality:=clampf(float(visual_architecture.get("axiality",0.5)),0.0,1.0)
	var terrain_conformity:=clampf(float(visual_architecture.get("terrain_conformity",0.5)),0.0,1.0)
	var formal_weight:=lerpf(0.04,0.94,axiality)*lerpf(1.0,0.68,terrain_conformity)
	# Every place in this player network shares an inherited construction culture.
	# Compute its aggregate palette once; never rescan up to 2,048 plots per marker.
	var network_palette:=_settlement_stage_material_palette(GameState.settlement_plots,5,architecture)
	var network_base:Color=network_palette.periphery
	for settlement_index in visible.size():
		var settlement:Dictionary=visible[settlement_index]
		var profile:=_settlement_expansion_visual_profile(settlement)
		var stage:=clampi(int(profile.get("stage",0)),0,6)
		var position_value:Variant=settlement.get("position",Vector2.ZERO)
		var position_2d:Vector2=position_value if position_value is Vector2 else Vector2.ZERO
		var center:=Vector3(position_2d.x,0.0,position_2d.y)
		var radius:=_secondary_settlement_urban_radius(settlement)
		var settlement_seed:=absi(hash("%d:%s:secondary_urban_system" % [GameState.world_seed,String(settlement.get("id",settlement_index))]))
		var rng:=RandomNumberGenerator.new()
		rng.seed=settlement_seed
		var cultural_axis:=_settlement_civic_axis()
		var organic_axis:=cultural_axis+rng.randf_range(-1.1,1.1)
		var formal_axis:=cultural_axis+PI*0.25*float(settlement_index%4)
		var axis:=lerp_angle(organic_axis,formal_axis,formal_weight)
		var tone:Color=network_base.lerp(Color(profile.color),0.08+float(stage)*0.012)
		tone.a=0.23+float(stage)*0.022
		var patch_count:=allocations[settlement_index]
		for patch_index in patch_count:
			var local_center:=Vector2.ZERO
			var patch_radius:=radius*float([0.38,0.36,0.34,0.32,0.29,0.27,0.25][stage])
			if patch_index>0:
				var radial_t:=sqrt(float(patch_index)/maxf(1.0,float(patch_count-1)))
				var organic_angle:=axis+2.39996323*float(patch_index)+rng.randf_range(-0.16,0.16)
				var formal_angle:=axis+PI*0.25*float(patch_index%8)
				var angle:=lerp_angle(organic_angle,formal_angle,formal_weight*0.74)
				local_center=Vector2.from_angle(angle)*radius*lerpf(0.22,0.78,radial_t)*rng.randf_range(0.88,1.08)
				local_center=_settlement_stage_resolve_land_offset(center,local_center)
				patch_radius=radius*rng.randf_range(0.095,0.17)*lerpf(1.10,0.78,radial_t)
			elif not _settlement_stage_land_at(position_2d):
				continue
			var patch_tone:Color=tone.lerp(Color("#95836c"),float(patch_index)/maxf(1.0,float(patch_count))*0.09)
			patch_tone.a*=lerpf(1.0,0.70,float(patch_index)/maxf(1.0,float(patch_count)))
			appended+=_append_settlement_stage_patch(surface,Vector3(center.x+local_center.x,0.0,center.z+local_center.y),maxf(0.025,patch_radius),patch_tone,0.00230,Vector2i(1,0),settlement_seed+patch_index*109,8)
	# Only real route/river/work access axes earn a strategic corridor. They share the
	# same surface and are globally capped, so this evidence cannot become road spam.
	var corridor_candidates:=visible.duplicate(true)
	corridor_candidates.sort_custom(func(a:Dictionary,b:Dictionary)->bool: return int(a.get("population",0))>int(b.get("population",0)))
	var corridor_count:=0
	for settlement in corridor_candidates:
		if corridor_count>=SECONDARY_SETTLEMENT_CORRIDOR_BUDGET: break
		var profile:=_settlement_expansion_visual_profile(settlement)
		if int(profile.get("stage",0))<2: continue
		var drivers:Dictionary=settlement.get("territory_drivers",{})
		var axes:Array=drivers.get("access_axes",[])
		if axes.is_empty(): continue
		var direction_value:Variant=(axes[0] as Dictionary).get("direction",Vector2.ZERO)
		var direction:Vector2=direction_value if direction_value is Vector2 else Vector2.ZERO
		if direction.length_squared()<0.000001: continue
		direction=direction.normalized()
		var position_value:Variant=settlement.get("position",Vector2.ZERO)
		var position_2d:Vector2=position_value if position_value is Vector2 else Vector2.ZERO
		var radius:=_secondary_settlement_urban_radius(settlement)
		var corridor_color:=Color("#928b7d")
		corridor_color.a=0.34
		appended+=_append_settlement_system_ribbon(surface,Vector3(position_2d.x,0.0,position_2d.y),PackedVector2Array([-direction*radius*0.34,Vector2.ZERO,direction*radius*0.74]),clampf(radius*0.006,0.0022,0.085),corridor_color,0.00272,6)
		corridor_count+=1
	if appended>0: _commit_settlement_surface(surface,"SecondaryUrbanSystems",footprint_parent,true)


func _secondary_settlement_label_limit()->int:
	if camera==null: return 24
	# Fixed-size names consume screen space, not world space. Fewer of them should
	# survive as the footprint widens; the old increasing budget produced the
	# busiest annotation field exactly at continental scale. Every settlement still
	# remains in the single MultiMesh blip batch and in the authoritative register.
	match _settlement_network_lod_band():
		0,1: return 24
		2: return 16
		3: return 8
		_: return 3

func _settlement_morphology_lod() -> int:
	if camera == null:
		return 1
	if camera.size <= 0.24:
		return 0 # individual roofs, yards, scars and paths
	if camera.size <= SETTLEMENT_FABRIC_MAX_ZOOM:
		return 1 # complete plot fabric
	return 2 # distant land-use trace; the map blip remains the primary marker

func _settlement_morphology_view_signature(lod:int)->String:
	if camera==null or lod>0: return str(lod)
	# Close inspection renders only the view and a large safety margin. Quantized
	# buckets let a player pan across a metropolis without retaining every off-screen
	# roof or rebuilding on every pixel of movement.
	var bucket_span:=maxf(0.08,camera.size*0.72)
	return "%d:%d:%d" % [lod,floori(camera_target.x/bucket_span),floori(camera_target.z/bucket_span)]

func _settlement_plots_in_current_detail_view(plots:Array[Dictionary],settlement_center:Vector3)->Array[Dictionary]:
	if camera==null: return plots
	var local_target:=Vector2(camera_target.x-settlement_center.x,camera_target.z-settlement_center.z)
	var view_radius:=maxf(0.24,camera.size*2.8)
	var visible:Array[Dictionary]=[]
	for plot in plots:
		var centroid:=Vector2(plot.get("centroid",Vector2.ZERO))
		var plot_radius:=sqrt(maxf(0.000001,float(plot.get("area_ha",0.01))/100.0)/PI)
		if centroid.distance_to(local_target)<=view_radius+plot_radius: visible.append(plot)
	return visible

func _settlement_routes_in_current_detail_view(routes:Array[Dictionary],settlement_center:Vector3)->Array[Dictionary]:
	if camera==null: return routes
	var local_target:=Vector2(camera_target.x-settlement_center.x,camera_target.z-settlement_center.z)
	var view_radius:=maxf(0.24,camera.size*3.0)
	var visible:Array[Dictionary]=[]
	for route in routes:
		var points:PackedVector2Array=route.get("points",PackedVector2Array())
		if points.size()<2: continue
		var intersects:=false
		for point_index in points.size()-1:
			var nearest:=Geometry2D.get_closest_point_to_segment(local_target,points[point_index],points[point_index+1])
			if nearest.distance_to(local_target)<=view_radius:
				intersects=true
				break
		if intersects: visible.append(route)
	return visible

func _settlement_detail_plot_budget(lod:int)->int:
	if lod<=0: return 2048
	if lod>=2: return 0
	if camera==null or camera.size<=1.5: return 768
	if camera.size<=6.0: return 512
	return 320

func _settlement_plot_has_detail(plot:Dictionary,plot_index:int,total_plots:int,lod:int)->bool:
	var budget:=_settlement_detail_plot_budget(lod)
	if budget<=0: return false
	if total_plots<=budget: return true
	var stride:=maxi(1,ceili(float(total_plots)/float(budget)))
	# Plot IDs are persistent and dense enough that modulo sampling remains stable
	# when the renderer rebuilds; no visible roof twinkles into another plot.
	return absi(int(plot.get("id",plot_index+1)))%stride==0

func _settlement_plot_has_aggregate_density(plot:Dictionary,plot_index:int,total_plots:int,lod:int)->bool:
	if lod<1: return false
	if String(plot.get("status","active")) not in ["active","stressed","damaged","under_construction"]: return false
	if String(plot.get("land_use","")) in ["field","pasture","water","waste","temporary_encampment","vacant","ruin"]: return false
	var budget:=384 if lod==1 else SETTLEMENT_AGGREGATE_DENSITY_BUDGET
	if total_plots<=budget: return true
	var stride:=maxi(1,ceili(float(total_plots)/float(budget)))
	# Persistent plot ids make this thinning deterministic across rebuilds and camera
	# movement; strategic urban mass never sparkles or changes because population rose.
	return absi(int(plot.get("id",plot_index+1))*17+5)%stride==0


func _settlement_aggregate_density_color(plot:Dictionary,lod:int)->Color:
	var density_generation:=clampi(int(plot.get("fabric_generation",0)),0,12)
	var created_day:=float(plot.get("created_day",GameState.elapsed_days))
	var age_years:=maxf(0.0,(float(GameState.elapsed_days)-created_day)/365.0)
	var inherited_age:=clampf(age_years/90.0,0.0,1.0)
	# Fresh margins retain exposed soil and vegetation. Old cores accumulate paving,
	# ash, repair, joined courts and soot, producing a cooler, consolidated aerial tone.
	var density_color:=Color("#857c63").lerp(Color("#666662"),inherited_age*0.46)
	density_color=density_color.lerp(Color("#686b68"),clampf(float(density_generation-7)/5.0,0.0,1.0)*0.28)
	var status:=String(plot.get("status","active"))
	if status=="damaged": density_color=density_color.lerp(Color("#4c423b"),0.46)
	elif status=="ruin": density_color=density_color.lerp(Color("#3f3c39"),0.72)
	density_color.a=(0.24 if lod>=2 else 0.205)+float(density_generation)*(0.009 if lod>=2 else 0.0115)
	return density_color

func _settlement_architecture_profile()->Dictionary:
	# Architecture is a six-number civilization-level style field. It never creates
	# one record per person or building; every visible roof in a batch reads the same
	# bounded profile and combines it with its authoritative plot and material history.
	if active_architecture_profile.is_empty():
		active_architecture_profile=SocietalValuesModel.architecture_snapshot(GameState.societal_values)
	return active_architecture_profile


func _settlement_visual_architecture_profile(profile:Dictionary)->Dictionary:
	# Lived values deliberately drift in small increments, but aerial morphology needs
	# enough contrast to be read without a statistics panel. This response curve changes
	# presentation only: it creates no simulation bonus and never adds population-sized
	# geometry. Values around the cultural middle remain nuanced; established leanings
	# become unmistakable in street order, compound closure, commons and skyline massing.
	var visual:Dictionary={}
	for key in ["axiality","monumentality","civic_space","permeability","defensive_depth","terrain_conformity"]:
		visual[key]=smoothstep(0.34,0.66,clampf(float(profile.get(key,0.5)),0.0,1.0))
	return visual

func _settlement_architecture_signature(profile:Dictionary)->String:
	# Quantization lets slow cultural drift become visible without rebuilding batched
	# settlement meshes for imperceptible floating-point changes every simulation day.
	var parts:Array[String]=[]
	for key in ["axiality","monumentality","civic_space","permeability","defensive_depth","terrain_conformity"]:
		parts.append(str(roundi(clampf(float(profile.get(key,0.5)),0.0,1.0)*20.0)))
	return ":".join(parts)


func _settlement_morphology_visual_signature()->String:
	# Simulation records legitimately change more often than their aerial appearance.
	# Hash only visible categories and coarse tone buckets so high time speeds do not
	# rebuild every mesh because prosperity moved by a thousandth. The authoritative
	# state remains continuous; this signature controls presentation work only.
	var cache_key:="%d:%d" % [GameState.morphology_revision,int(GameState.elapsed_days/365.0)]
	if cache_key==cached_morphology_visual_signature_key: return cached_morphology_visual_signature
	var plot_hash:=0
	for plot in GameState.settlement_plots:
		var centroid:=Vector2(plot.get("centroid",Vector2.ZERO))
		var visual_record:="%d|%s|%s|%s|%s|%s|%s|%d|%d|%d|%d|%d|%d|%d" % [
			int(plot.get("id",0)),String(plot.get("land_use","")),String(plot.get("form","")),
			String(plot.get("material_family","")),String(plot.get("roof_plan","")),String(plot.get("status","")),
			String(plot.get("cultivation_phase","")),int(plot.get("fabric_generation",0)),int(plot.get("storeys",1)),
			roundi(clampf(float(plot.get("condition",1.0)),0.0,1.0)*20.0),
			roundi(clampf(float(plot.get("prosperity",0.4)),0.0,1.0)*20.0),
			roundi(clampf(float(plot.get("reclamation",0.0)),0.0,1.0)*10.0),
			roundi(centroid.x*1000.0),roundi(centroid.y*1000.0)
		]
		plot_hash=plot_hash^hash(visual_record)
	var route_hash:=0
	for route in GameState.settlement_routes:
		var points:PackedVector2Array=route.get("points",PackedVector2Array())
		var point_hash:=0
		for point in points: point_hash=point_hash^hash("%d:%d" % [roundi(point.x*1000.0),roundi(point.y*1000.0)])
		# Early routes use descriptive hierarchy strings (for example
		# `irregular_flat`), while engineered network records may use numeric tiers.
		# Both are visible categories; hashing them as text handles the full ledger.
		route_hash=route_hash^hash("%s|%s|%s|%s|%d|%d" % [str(route.get("id","")),str(route.get("kind","")),str(route.get("status","")),str(route.get("hierarchy",route.get("kind",""))),int(route.get("surface_tier",0)),point_hash])
	var nuclei_hash:=0
	for nucleus in GameState.settlement_nuclei:
		var position:=Vector2(nucleus.get("position",Vector2.ZERO))
		nuclei_hash=nuclei_hash^hash("%d|%s|%d|%d|%d" % [int(nucleus.get("id",0)),String(nucleus.get("kind","")),int(bool(nucleus.get("active",true))),roundi(position.x*1000.0),roundi(position.y*1000.0)])
	cached_morphology_visual_signature="%d:%d:%d:%d:%d:%d" % [GameState.settlement_plots.size(),GameState.settlement_routes.size(),GameState.settlement_nuclei.size(),plot_hash,route_hash,nuclei_hash]
	cached_morphology_visual_signature_key=cache_key
	return cached_morphology_visual_signature

func _settlement_civic_axis()->float:
	# A civilization carries a persistent planning axis derived from its world seed.
	# It is visual grammar, not another simulated road or saved building property.
	var axis_seed:=absi(hash("%d:%s:civic_axis" % [GameState.world_seed,GameState.founding_focus]))
	return float(axis_seed%100000)/100000.0*PI

func _lerp_undirected_angle(from_angle:float,to_angle:float,weight:float)->float:
	# Roof axes have no forward direction, so 0° and 180° are equivalent. Interpolate
	# across the shortest half-turn to prevent neighboring roofs from suddenly flipping.
	var delta:=wrapf(to_angle-from_angle,-PI*0.5,PI*0.5)
	return from_angle+delta*clampf(weight,0.0,1.0)

func _terrain_contour_angle(world_center:Vector2,fallback:float)->float:
	var sample:=0.010
	var east_west:=_close_surface_height_at(world_center.x+sample,world_center.y)-_close_surface_height_at(world_center.x-sample,world_center.y)
	var north_south:=_close_surface_height_at(world_center.x,world_center.y+sample)-_close_surface_height_at(world_center.x,world_center.y-sample)
	var gradient:=Vector2(east_west,north_south)
	if gradient.length_squared()<0.00000001: return fallback
	return Vector2(-gradient.y,gradient.x).angle()

func _architecture_roof_tone(source:Color,use:String)->Color:
	var architecture:=_settlement_visual_architecture_profile(_settlement_architecture_profile())
	var axiality:=clampf(float(architecture.get("axiality",0.5)),0.0,1.0)
	var monumentality:=clampf(float(architecture.get("monumentality",0.5)),0.0,1.0)
	var permeability:=clampf(float(architecture.get("permeability",0.5)),0.0,1.0)
	var civic_space:=clampf(float(architecture.get("civic_space",0.5)),0.0,1.0)
	var result:=source
	# Centralized cultures produce a tighter aerial material register; open cultures
	# retain more visible repair and household variation. The atlas still supplies the
	# actual clay, fibre, timber, stone, metal and weathering information.
	var coherent_tone:=Color("#777269")
	result=result.lerp(coherent_tone,axiality*(1.0-permeability)*0.16)
	if use in ["civic","sacred","communal"]:
		result=result.lerp(Color("#aaa293"),monumentality*0.20+civic_space*0.08)
	elif use in ["market","hospitality"]:
		result=result.lerp(Color("#8d806b"),permeability*0.10)
	return result

func _architecture_expression_text(profile:Dictionary)->String:
	var axiality:=clampf(float(profile.get("axiality",0.5)),0.0,1.0)
	var monumentality:=clampf(float(profile.get("monumentality",0.5)),0.0,1.0)
	var civic_space:=clampf(float(profile.get("civic_space",0.5)),0.0,1.0)
	var permeability:=clampf(float(profile.get("permeability",0.5)),0.0,1.0)
	var defensive_depth:=clampf(float(profile.get("defensive_depth",0.5)),0.0,1.0)
	var terrain_conformity:=clampf(float(profile.get("terrain_conformity",0.5)),0.0,1.0)
	var order_phrase:="formal civic axes" if axiality>=0.64 else ("terrain-following fabric" if terrain_conformity>=0.64 else "inherited local alignments")
	var public_phrase:="monumental public masses" if monumentality>=0.66 else ("generous shared courts" if civic_space>=0.64 else "small mixed civic yards")
	var edge_phrase:="open lanes and frequent gateways" if permeability>=0.64 else ("layered enclosed compounds" if defensive_depth>=0.64 else "selective lanes and compound edges")
	return "%s  •  %s  •  %s" % [order_phrase,public_phrase,edge_phrase]

func _settlement_plot_color(plot: Dictionary) -> Color:
	var land_use := String(plot.get("land_use", "vacant"))
	var material_family := String(plot.get("material_family", "organic"))
	var color := Color("#786f51")
	if land_use in ["residential_compound", "mixed_household"]:
		color = Color("#817457")
	elif land_use=="temporary_encampment":
		color=Color("#746a4d")
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
	var fabric_generation:=clampi(int(plot.get("fabric_generation",0)),0,12)
	if fabric_generation>=6 and land_use not in ["field","pasture","water","waste"]:
		# Dense habitation replaces vegetation with joined courts, swept soil,
		# rubble, paving and drainage incrementally inside inherited parcels.
		color=color.lerp(Color("#716b5d"),clampf(0.10+float(fabric_generation-6)*0.045,0.10,0.38))
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
		var temporary_ground:=String(plot.get("form","")) in ["portable_shelter_cluster","light_shelter_cluster","emergency_open_encampment"]
		if temporary_ground:
			color.a=0.29 if land_use=="temporary_encampment" else 0.24
		elif land_use in ["residential_compound","mixed_household"]:
			color.a=0.33+clampf(float(fabric_generation-5)*0.026,0.0,0.19)
		elif land_use=="field":
			color.a=0.18
		else:
			color.a=0.37+clampf(float(fabric_generation-5)*0.020,0.0,0.16)
	elif status=="vacant":
		# A departed canvas/fibre camp leaves trampled soil and a remembered claim,
		# not a durable bright parcel. Permanent compounds retain more aerial evidence.
		color.a=0.045 if land_use=="temporary_encampment" else 0.20
	elif status=="damaged":
		color.a=0.34
	elif status=="ruin":
		color.a=0.30
	else:
		color.a=0.16
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
	var variant:=absi(int(plot.get("seed",1)))%7
	var fabric_generation:=clampi(int(plot.get("fabric_generation",0)),0,12)
	if String(plot.get("status","active")) in ["damaged","ruin"]: return Vector2i(2,3) if family=="earth" else Vector2i(3,3)
	if use in ["workshop","dirty_industry","waste"]: return Vector2i(0,0) if variant%3 else Vector2i(3,2)
	if use=="storage": return Vector2i(1,0) if variant%2 else Vector2i(3,2)
	if use in ["communal","civic","sacred","market"]: return Vector2i(1,0) if variant%3 else Vector2i(3,2)
	if fabric_generation>=9: return Vector2i(1,0) if variant%3!=0 else Vector2i(3,2)
	if fabric_generation>=6: return [Vector2i(3,2),Vector2i(1,0),Vector2i(0,0)][variant%3]
	# A compound's open ground is not its wall material. Stone-built households
	# still stand in worn earth, weeds, ash and kitchen-garden spill. Selecting
	# among real ground surfaces keeps the plot from becoming one stone/mud rug.
	return [Vector2i(3,2),Vector2i(1,0),Vector2i(2,2),Vector2i(0,0)][variant%4]

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
	var texture_angle:=float(plot.get("field_rotation",float(absi(int(plot.get("seed",1)))%6283)/1000.0))
	var texture_phase:=float(absi(int(plot.get("seed",1)))%997)/997.0
	for index in polygon.size():
		for vertex_index in 3:
			var source_point:Vector2=centroid if vertex_index==0 else polygon[index if vertex_index==1 else (index+1)%polygon.size()]
			var point_2d:Vector2=source_point
			var world_point:=Vector3(center.x+point_2d.x,0.0,center.z+point_2d.y)
			world_point.y=_close_surface_height_at(world_point.x,world_point.z)+lift
			var local_uv:=Vector2((point_2d.x-minimum.x)/span.x,(point_2d.y-minimum.y)/span.y)
			surface.set_color(center_color if vertex_index==0 else margin_color)
			surface.set_uv(_atlas_uv(atlas_cell,local_uv))
			surface.set_uv2(Vector2(fposmod(texture_angle,TAU)/TAU,texture_phase))
			surface.add_vertex(world_point)

func _commit_settlement_surface(surface: SurfaceTool, node_name: String, parent: Node3D, transparent := false) -> void:
	surface.generate_normals()
	var mesh := surface.commit()
	if mesh == null:
		return
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	# Roofs use their material atlas at every LOD. The old `transparent` gate sent
	# close roofs through a plain vertex-colour material, which is exactly why they
	# appeared as identical coloured boxes while distant roofs happened to texture.
	var physical_fabric:=node_name=="PersistentRoofFabric" or (transparent and node_name in ["PersistentSettlementDensity","PersistentPlotGround","PersistentFieldGround","PersistentCultivationRows","PersistentYardVariation","PersistentDesirePaths","PersistentUrbanSystems","SecondaryUrbanSystems","PersistentMetropolitanMobility","PersistentUrbanOpenSpace"])
	var material:Material
	if physical_fabric:
		# Density is a land-cover signal, not another sampled dirt parcel. Keeping it
		# on its own shader branch lets late settlements acquire a continuous aerial
		# tone while individual plots retain their real material atlas beneath it.
		# Aggregate urban regions need their simulated material palette to survive.
		# Feeding them through ordinary parcel photography bleached every civilization
		# into the same pale atlas sample. Kinds 5/6 are bounded procedural aerial
		# fabrics for urban cover and preserved open space respectively.
		var fabric_kind:=0
		if node_name=="PersistentSettlementDensity": fabric_kind=4
		elif node_name=="PersistentUrbanOpenSpace": fabric_kind=6
		elif node_name in ["PersistentUrbanSystems","SecondaryUrbanSystems"]: fabric_kind=5
		elif node_name=="PersistentMetropolitanMobility": fabric_kind=7
		elif node_name in ["PersistentFieldGround","PersistentCultivationRows"]: fabric_kind=1
		elif node_name=="PersistentRoofFabric": fabric_kind=3
		elif node_name in ["PersistentYardVariation","PersistentDesirePaths"]: fabric_kind=2
		material=_settlement_fabric_material(fabric_kind,0.74 if fabric_kind==1 else (0.62 if fabric_kind==3 else 0.48))
	else:
		var standard:=StandardMaterial3D.new()
		standard.vertex_color_use_as_albedo = true
		standard.roughness = 0.96
		standard.cull_mode = BaseMaterial3D.CULL_DISABLED
		# Wall skirts are real oblique geometry and should be occluded normally.
		# Terrain drapes retain depth bypass to avoid LOD interpolation burying them.
		standard.no_depth_test = node_name not in ["PersistentWallFabric","PersistentUrbanMassing"]
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
	if node_name=="PersistentUrbanOpenSpace": material.render_priority=1
	elif node_name in ["PersistentUrbanSystems","SecondaryUrbanSystems"]: material.render_priority=2
	elif node_name=="PersistentMetropolitanMobility": material.render_priority=4
	else: material.render_priority = 2 if "Ground" in node_name else (4 if "Roof" in node_name else 3)
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
uniform float aerial_lod = 0.0;
uniform sampler2D material_atlas : source_color, filter_linear_mipmap, repeat_disable;
uniform sampler2D roof_material_atlas : source_color, filter_linear, repeat_disable;
uniform sampler2D late_roof_material_atlas : source_color, filter_linear_mipmap, repeat_disable;
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
vec2 mirrored_repeat(vec2 p) {
	// Triangle-wave repetition avoids a hard jump where a generated texture tile
	// meets itself. The atlas cell remains clamped; only its internal material
	// grain repeats at a physical scale.
	vec2 f=fract(p*0.5)*2.0;
	return 1.0-abs(f-1.0);
}
vec3 sample_material_cell(vec2 source_uv,vec2 metre_position,float frequency,float orientation,float phase) {
	vec2 cell=floor(clamp(source_uv,vec2(0.0),vec2(0.9999))*4.0);
	float angle=orientation*6.2831853;
	mat2 turn=mat2(vec2(cos(angle),sin(angle)),vec2(-sin(angle),cos(angle)));
	vec2 local_uv=mirrored_repeat(turn*metre_position*frequency+vec2(phase*19.7,phase*31.3));
	local_uv=mix(vec2(0.025),vec2(0.975),local_uv);
	vec2 atlas_uv=(cell+local_uv)/4.0;
	return (fabric_kind==3 ? texture(roof_material_atlas,atlas_uv) : texture(material_atlas,atlas_uv)).rgb;
}
void vertex() {
	world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
}
void fragment() {
	float broad=value_noise(world_position.xz*34.0+vec2(13.0,-29.0));
	float fine=value_noise(world_position.xz*215.0+vec2(-47.0,71.0));
	float dry=smoothstep(0.64,0.88,value_noise(world_position.xz*73.0+vec2(91.0,17.0)));
	vec3 fabric=COLOR.rgb*(0.82+broad*0.23+(fine-0.5)*0.18*grain_strength);
	if ((fabric_kind==0 || fabric_kind==1 || fabric_kind==2 || fabric_kind==3 || fabric_kind==7) && UV.x>=0.0 && UV.y>=0.0) {
		// World units are kilometres. Material detail repeats in metres rather
		// than stretching once from one parcel corner to the other. Fields retain
		// their simulated row geometry above this base grain; roofs retain their
		// individual course/repair overlays.
		// Roof cells cover roughly a 3.8 m span. The former 1.6 m repetition forced
		// mipmapping to average reed bindings and board joints into a flat colour.
		float physical_frequency=fabric_kind==3 ? 260.0 : (fabric_kind==1 ? 165.0 : ((fabric_kind==2 || fabric_kind==7) ? 230.0 : 120.0));
		float material_phase=fract(UV2.y+hash21(floor(UV*4.0)+vec2(17.0,43.0)));
		float material_orientation=fabric_kind==3 ? 0.0 : fract(UV2.x+0.25);
		// Roof meshes carry a true ridge-aligned 0..1 UV footprint. Ground fabrics
		// remain world-scaled so adjoining parcels do not visibly restart a tile.
		vec2 sampling_position=fabric_kind==3 ? fract(UV*4.0)/physical_frequency : world_position.xz;
		vec3 photographic;
		if (fabric_kind==3) {
			if (UV2.y>=1.0) {
				vec2 late_cell=floor(clamp(UV,vec2(0.0),vec2(0.9999))*4.0);
				float late_angle=UV2.x*6.2831853;
				mat2 late_turn=mat2(vec2(cos(late_angle),sin(late_angle)),vec2(-sin(late_angle),cos(late_angle)));
				// One generated roof mass may summarize several joined structures.
				// Repeat courses at a physical ~2.2 m scale instead of stretching one
				// texture cell over the entire block.
				vec2 late_local=mirrored_repeat(late_turn*world_position.xz*455.0+vec2(fract(UV2.y)*17.0,fract(UV2.y)*29.0));
				late_local=mix(vec2(0.025),vec2(0.975),late_local);
				photographic=texture(late_roof_material_atlas,(late_cell+late_local)/4.0).rgb;
			} else photographic=texture(roof_material_atlas,UV).rgb;
		} else photographic=sample_material_cell(UV,sampling_position,physical_frequency,material_orientation,material_phase);
		vec3 secondary=fabric_kind==3 ? photographic : sample_material_cell(UV,sampling_position,physical_frequency*0.47,fract(material_orientation+0.071),fract(material_phase+0.37));
		photographic=mix(photographic,secondary,fabric_kind==3 ? 0.0 : (0.16+0.12*broad));
		if (fabric_kind==3) photographic=clamp((photographic-vec3(0.5))*1.20+vec3(0.5),vec3(0.0),vec3(1.0));
		if (fabric_kind==3 && UV2.y>=1.0) {
			photographic*=0.80;
			// Slate, oxidized sheet and wet repairs remain dark, but aerial haze keeps
			// them from collapsing into featureless black map tokens.
			float late_luma=dot(photographic,vec3(0.299,0.587,0.114));
			photographic+=vec3(max(0.0,0.18-late_luma)*0.66);
		}
		float source_luma=max(dot(photographic,vec3(0.299,0.587,0.114)),0.12);
		float tint_luma=max(dot(COLOR.rgb,vec3(0.299,0.587,0.114)),0.12);
		vec3 tint=COLOR.rgb/tint_luma;
		if (fabric_kind==3) {
			// Keep photographic weave/boards/joints as surface information, but let
			// simulated material, age and condition weather the source rather than
			// replacing it. Multiplying every source by the vertex hue reduced rich
			// clay, timber and masonry to uniformly orange or grey map rectangles.
			vec3 normalized_detail=clamp(photographic/source_luma,vec3(0.48),vec3(1.58));
			float source_value=clamp(source_luma/0.62,0.94,1.06);
			vec2 detail_cell=floor(clamp(UV,vec2(0.0),vec2(0.9999))*4.0);
			// Reed bindings are broad source-photo features. At aerial scale their
			// full contrast looked like evenly spaced rivets; the procedural fibre
			// pass below retains fine material direction without that rug-like repeat.
			float photographic_detail=detail_cell.x<0.5 ? 0.31 : 0.46;
			vec3 weather_tint=mix(vec3(1.0),tint,0.38);
			// The atlas is deliberately high-contrast source photography, but direct
			// display at map scale made sunlit clay and straw into orange confetti.
			// Aerial haze, dust and roof age compress saturation before the simulated
			// material tint is applied; texture structure remains intact.
			float aerial_luma=dot(photographic,vec3(0.299,0.587,0.114));
			vec3 aerial_photographic=mix(vec3(aerial_luma),photographic,0.50)*0.86;
			vec3 source_surface=aerial_photographic*weather_tint;
			vec3 simulated_surface=COLOR.rgb*mix(vec3(1.0),normalized_detail,photographic_detail);
			fabric=mix(source_surface,simulated_surface,0.42)*source_value*0.92;
		} else {
			photographic*=mix(vec3(1.0),tint,0.08);
			fabric=mix(fabric,photographic,0.94);
		}
	}
	if (fabric_kind==1 || fabric_kind==6) {
		// Vegetation is clumpy at metre scale and interrupted by exposed earth;
		// it must never read as a uniformly dyed polygon from an aerial camera.
		float crop_clump=value_noise(world_position.xz*420.0+vec2(7.0,113.0));
		float leaf=value_noise(world_position.xz*980.0+vec2(-31.0,19.0));
		fabric*=0.72+crop_clump*0.34+leaf*0.08;
		fabric=mix(fabric,fabric*vec3(0.72,0.82,0.57),smoothstep(0.58,0.82,crop_clump)*0.26);
	} else if (fabric_kind==5) {
		// Strategic urban cover is mottled by block age, roof mix and canopy. This
		// preserves the palette while avoiding a flat board-game territory wash.
		float pixel_span=max(length(dFdx(world_position.xz)),length(dFdy(world_position.xz)));
		float micro_visibility=1.0-smoothstep(0.018,0.095,pixel_span);
		float district_visibility=1.0-smoothstep(0.20,0.72,pixel_span);
		float block=value_noise(world_position.xz*21.0+vec2(37.0,-11.0));
		float infill=value_noise(world_position.xz*96.0+vec2(-73.0,41.0));
		float metropolitan_grain=value_noise(world_position.xz*0.72+vec2(-13.0,7.0));
		float regional_grain=value_noise(world_position.xz*0.18+vec2(29.0,-41.0));
		vec3 close_fabric=COLOR.rgb*(0.67+block*0.21+infill*0.09);
		vec3 strategic_fabric=COLOR.rgb*(0.66+metropolitan_grain*0.15+regional_grain*0.08);
		fabric=mix(strategic_fabric,close_fabric,micro_visibility);
		fabric=mix(fabric,fabric*vec3(1.05,1.00,0.91),0.14);
		// A bounded world-space block grain survives zoom without spawning roads or
		// buildings. UV2 carries each district's inherited orientation, so formal
		// cultures align more strongly while organic districts retain local variation.
		float urban_angle=UV2.x*6.2831853;
		mat2 urban_turn=mat2(vec2(cos(urban_angle),sin(urban_angle)),vec2(-sin(urban_angle),cos(urban_angle)));
		vec2 urban_point=urban_turn*world_position.xz;
		// When ordinary blocks have dropped below a pixel, kilometer-scale avenues,
		// industrial parcels and district joins remain visible in real aerial imagery.
		// This hierarchy prevents a megaregion from becoming one soft neutral cloud.
		float regional_visibility=1.0-smoothstep(0.48,1.80,pixel_span);
		vec2 regional_point=urban_point*vec2(0.64,0.55);
		vec2 regional_local=fract(regional_point);
		vec2 regional_edge=min(regional_local,vec2(1.0)-regional_local);
		float regional_aa=max(fwidth(regional_edge.x),fwidth(regional_edge.y));
		float avenue=1.0-smoothstep(0.018,0.048+regional_aa*0.42,min(regional_edge.x,regional_edge.y));
		vec2 regional_cell=floor(regional_point);
		float district_age=hash21(regional_cell+vec2(71.0,-31.0));
		float district_void=step(0.15,hash21(regional_cell+vec2(-9.0,83.0)));
		fabric*=mix(0.84,1.08,district_age);
		fabric=mix(fabric,COLOR.rgb*0.36,avenue*district_void*0.58*regional_visibility);
		vec2 local_block=fract(urban_point*vec2(5.8,4.9));
		vec2 block_edge=min(local_block,vec2(1.0)-local_block);
		float block_aa=max(fwidth(block_edge.x),fwidth(block_edge.y));
		float street=1.0-smoothstep(0.020,0.052+block_aa,min(block_edge.x,block_edge.y));
		vec2 district_cell=floor(urban_point*vec2(1.35,1.12));
		float interrupted=step(0.20,hash21(district_cell+vec2(19.0,-7.0)));
		street*=interrupted*micro_visibility;
		// Finer roof-block grain makes a developed region look constructed instead of
		// merely desaturated. It is entirely shader-side and therefore costs the same
		// whether the aggregate polygon represents ten thousand or ten million roofs.
		vec2 fine_point=urban_point*vec2(12.2,10.6);
		vec2 fine_local=fract(fine_point);
		vec2 fine_edge=min(fine_local,vec2(1.0)-fine_local);
		float fine_aa=max(fwidth(fine_edge.x),fwidth(fine_edge.y));
		float fine_street=1.0-smoothstep(0.014,0.034+fine_aa,min(fine_edge.x,fine_edge.y));
		vec2 roof_cell=floor(fine_point);
		float roof_age=hash21(roof_cell+vec2(5.0,67.0));
		float roof_interrupt=step(0.16,hash21(roof_cell+vec2(-23.0,11.0)));
		fabric*=mix(1.0,mix(0.88,1.10,roof_age),micro_visibility);
		fabric*=1.0-fine_street*roof_interrupt*0.11*micro_visibility;
		float canopy=smoothstep(0.64,0.86,value_noise(world_position.xz*13.0+vec2(-101.0,59.0)));
		fabric*=1.0-street*0.24;
		fabric=mix(fabric,fabric*vec3(0.66,0.79,0.64),canopy*0.22*district_visibility);
	} else if (fabric_kind==3) {
		// Coarse fibre, bark and patched earthen roofing separate roofs from
		// coloured map rectangles even when a house is only a few pixels wide.
		vec2 roof_cell=floor(clamp(UV,vec2(0.0),vec2(0.9999))*4.0);
		float roof_angle=fract(UV2.x+0.25)*6.2831853;
		vec2 roof_axis=vec2(cos(roof_angle),sin(roof_angle));
		vec2 roof_cross=vec2(-roof_axis.y,roof_axis.x);
		float along=dot(world_position.xz,roof_axis);
		float across=dot(world_position.xz,roof_cross);
		float fibre=abs(fract(along*1450.0+UV2.y*7.0)-0.5)*2.0;
		float roof_stain=value_noise(world_position.xz*520.0+vec2(181.0,-63.0));
		if (roof_cell.x<0.5) {
			float binding=smoothstep(0.38,0.49,abs(fract(across*390.0+UV2.y*11.0)-0.5));
			fabric*=0.73+fibre*0.20+binding*0.16+roof_stain*0.12;
		} else if (roof_cell.x<1.5) {
			float board=pow(abs(fract(across*920.0+UV2.y*13.0)-0.5)*2.0,5.0);
			fabric*=0.76+board*0.25+roof_stain*0.14;
		} else if (roof_cell.x<2.5) {
			float plaster=value_noise(vec2(along*310.0,across*470.0)+UV2.y*19.0);
			fabric*=0.78+plaster*0.30+roof_stain*0.10;
		} else {
			float joint_a=pow(abs(fract(along*610.0+UV2.y*5.0)-0.5)*2.0,7.0);
			float joint_b=pow(abs(fract(across*740.0+UV2.y*9.0)-0.5)*2.0,7.0);
			fabric*=0.70+max(joint_a,joint_b)*0.23+roof_stain*0.18;
		}
		fabric=mix(fabric,fabric*vec3(0.72,0.67,0.56),smoothstep(0.72,0.90,roof_stain)*0.32);
	} else {
		float earth_mottle=value_noise(world_position.xz*135.0+vec2(-9.0,44.0));
		fabric*=0.90+earth_mottle*0.16;
	}
	if (fabric_kind==3 && aerial_lod>0.0) {
		// At settlement-map scale a roof is often below a pixel. Preserve atlas
		// variation, but compress its photographic shadow range the way atmospheric
		// scatter and pixel integration do in real aerial imagery. Without this,
		// timber joints and slate shadows average into identical near-black dots.
		float aerial_value=dot(fabric,vec3(0.299,0.587,0.114));
		float missing_value=max(0.0,0.285-aerial_value);
		vec3 lifted=fabric+vec3(1.00,0.93,0.80)*missing_value*0.76;
		float lifted_value=dot(lifted,vec3(0.299,0.587,0.114));
		lifted=mix(vec3(lifted_value),lifted,0.76);
		fabric=mix(fabric,lifted,clamp(aerial_lod,0.0,1.0));
	}
	fabric=mix(fabric,fabric*vec3(1.10,1.035,0.86),dry*0.14*grain_strength);
	ALBEDO=fabric;
	float material_alpha=COLOR.a;
	if (fabric_kind==5 || fabric_kind==6) {
		// Aggregate city cover belongs to the aerial/regional LOD. Fade it before
		// plot-level roofs and yards become the player's source of truth, but retain a
		// restrained floor for mature territory beyond the bounded plot sample. Without
		// it, zooming into an outer metropolis made millions of represented residents
		// vanish into untouched wilderness merely because their blocks are aggregate.
		// Camera-local bounded district masses now carry town-and-later physical
		// presence at close zoom. Leave only a faint continuous substrate here so the
		// strategic layer does not double-render as a gray veil beneath real roofs.
		float aggregate_floor=fabric_kind==5 ? 0.10 : 0.16;
		material_alpha*=mix(aggregate_floor,1.0,smoothstep(0.10,0.72,aerial_lod));
	}
	if (fabric_kind==7) {
		// Kilometer-scale transport ribbons are a strategic representation. Real saved
		// lanes and paths already exist at close zoom, so the aggregate layer must retire
		// completely before it becomes a hundred-metre slab across the player's view.
		material_alpha*=smoothstep(0.16,0.66,aerial_lod);
	}
	if (fabric_kind==1 || fabric_kind==6) {
		// Cultivation changes the existing terrain unevenly. Broken crop cover and
		// worked soil prevent even a rectangular authoritative parcel from reading
		// as a translucent map card.
		float cover=value_noise(world_position.xz*92.0+vec2(61.0,-37.0));
		material_alpha*=0.62+cover*0.38;
	} else if (fabric_kind==5) {
		float alpha_pixel_span=max(length(dFdx(world_position.xz)),length(dFdy(world_position.xz)));
		float alpha_micro_visibility=1.0-smoothstep(0.018,0.095,alpha_pixel_span);
		float micro_wear=value_noise(world_position.xz*138.0+vec2(-27.0,83.0));
		float macro_wear=value_noise(world_position.xz*0.55+vec2(43.0,-17.0));
		float urban_wear=mix(macro_wear,micro_wear,alpha_micro_visibility);
		material_alpha*=0.68+urban_wear*0.32;
	} else if (fabric_kind==0 || fabric_kind==2 || fabric_kind==7) {
		float wear=value_noise(world_position.xz*138.0+vec2(-27.0,83.0));
		material_alpha*=0.70+wear*0.30;
	}
	ALPHA=material_alpha;
	ROUGHNESS=0.98;
}
"""
	var material:=ShaderMaterial.new()
	material.shader=settlement_fabric_shader
	material.set_shader_parameter("grain_strength",grain_strength)
	material.set_shader_parameter("fabric_kind",fabric_kind)
	material.set_shader_parameter("aerial_lod",smoothstep(0.18,0.78,camera.size) if camera!=null else 0.0)
	var atlas_texture:=load("res://assets/textures/settlement_material_atlas_v2.png")
	if atlas_texture: material.set_shader_parameter("material_atlas",atlas_texture)
	var roof_atlas_texture:=load("res://assets/textures/settlement_roof_material_atlas_v1.png")
	if roof_atlas_texture: material.set_shader_parameter("roof_material_atlas",roof_atlas_texture)
	var late_roof_atlas_texture:=load("res://assets/textures/settlement_roof_material_atlas_late_v1.png")
	if late_roof_atlas_texture: material.set_shader_parameter("late_roof_material_atlas",late_roof_atlas_texture)
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

func _append_ground_disc(surface:SurfaceTool,world_center:Vector3,radius:float,color:Color,lift:float,atlas_cell:=Vector2i(-1,-1))->void:
	var segments:=18
	for index in segments:
		var angle_a:=TAU*float(index)/float(segments)
		var angle_b:=TAU*float(index+1)/float(segments)
		for offset in [Vector2.ZERO,Vector2.from_angle(angle_a)*radius,Vector2.from_angle(angle_b)*radius]:
			var point:=Vector3(world_center.x+offset.x,0.0,world_center.z+offset.y)
			point.y=_close_surface_height_at(point.x,point.z)+lift
			surface.set_color(color)
			surface.set_uv(_atlas_uv(atlas_cell,Vector2(0.5,0.5)))
			surface.add_vertex(point)

func _append_textured_ground_patch(surface:SurfaceTool,world_center:Vector3,radius:float,color:Color,lift:float,atlas_cell:Vector2i,patch_seed:int)->void:
	# Human traffic does not produce circular decals. Build an asymmetric patch
	# from deterministic radial samples and feather its material into the terrain.
	var rng:=RandomNumberGenerator.new()
	rng.seed=patch_seed
	var segments:=rng.randi_range(9,14)
	var angle_offset:=rng.randf()*TAU
	var stretch_axis:=Vector2.from_angle(rng.randf()*TAU)
	var edge_points:Array[Vector2]=[]
	for index in segments:
		var angle:=angle_offset+TAU*float(index)/float(segments)+rng.randf_range(-0.11,0.11)
		var radial:=radius*rng.randf_range(0.58,1.18)
		var direction:=Vector2.from_angle(angle)
		var stretch:=lerpf(0.72,1.26,absf(direction.dot(stretch_axis)))
		edge_points.append(direction*radial*stretch)
	var center_color:=color
	var edge_color:=color
	edge_color.a*=0.04
	var texture_coordinates:=Vector2(fposmod(stretch_axis.angle(),TAU)/TAU,float(absi(patch_seed)%997)/997.0)
	for index in segments:
		for vertex_index in 3:
			var offset:=Vector2.ZERO if vertex_index==0 else edge_points[index if vertex_index==1 else (index+1)%segments]
			var point:=Vector3(world_center.x+offset.x,0.0,world_center.z+offset.y)
			point.y=_close_surface_height_at(point.x,point.z)+lift
			surface.set_color(center_color if vertex_index==0 else edge_color)
			surface.set_uv(_atlas_uv(atlas_cell,Vector2(0.5,0.5)))
			surface.set_uv2(texture_coordinates)
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

func _roof_atlas_cell(plot:Dictionary,temporary_camp:bool,roof_variant:=0)->Vector2i:
	var seed_value:=absi(int(plot.get("seed",1))+roof_variant*37)
	var condition:=clampf(float(plot.get("condition",0.72)),0.0,1.0)
	var age_years:=maxf(0.0,(float(GameState.elapsed_days)-float(plot.get("created_day",GameState.elapsed_days)))/365.0)
	var wear_row:=0
	if condition<0.34 or age_years>22.0: wear_row=3
	elif condition<0.58 or age_years>11.0: wear_row=2
	elif age_years>3.0: wear_row=1
	# Adjacent household masses are repaired at different times; deterministic
	# variation prevents an entire district aging as one cloned roof sheet.
	if roof_variant>0 and seed_value%5==0: wear_row=mini(3,wear_row+1)
	if temporary_camp: return Vector2i(0,mini(2,wear_row))
	var family:=String(plot.get("material_family","organic"))
	var roof_plan:=String(plot.get("roof_plan",""))
	var mix:Dictionary=plot.get("material_mix",{})
	var fibre:=float(mix.get("Fiber Plants",0.0))
	var timber:=float(mix.get("Timber",0.0))
	var clay:=float(mix.get("Clay",0.0))
	var stone:=float(mix.get("Stone",0.0))
	# Wall/foundation family does not automatically determine the roof. Early
	# earth and rubble structures overwhelmingly retain fibre or timber spans.
	# Secondary roof masses may show a real delivered substitute or repair, which
	# makes material history legible without cosmetic random colours.
	# The recorded roof plan is the first-order visual fact. Previously a compound
	# with enough fibre forced every mass back to the same thatch cell, even when
	# its generated plan called for timber, clay or rubble. That made the atlas look
	# like one recoloured rug instead of a material history.
	if roof_plan in ["timber_ridge","timber_span_on_rubble"] and timber>0.08: return Vector2i(1,wear_row)
	if roof_plan in ["irregular_flat","courtyard_flat","mixed_earthen_span"] and clay>0.12: return Vector2i(2,wear_row)
	if roof_plan=="rubble_slab" and stone>0.18: return Vector2i(3,wear_row)
	if roof_variant%5==4 and timber>0.12: return Vector2i(1,wear_row)
	if roof_variant%6==5 and fibre>0.10: return Vector2i(0,wear_row)
	if fibre>=0.15 and fibre>=timber*0.72: return Vector2i(0,wear_row)
	if timber>=0.16: return Vector2i(1,wear_row)
	if family=="stone" and stone>=0.46: return Vector2i(3,wear_row)
	if family=="earth" and clay>=0.40: return Vector2i(2,wear_row)
	return Vector2i(0,wear_row) if seed_value%2==0 else Vector2i(1,wear_row)

func _late_roof_atlas_cell(plot:Dictionary,roof_variant:int)->Vector2i:
	var condition:=clampf(float(plot.get("condition",0.72)),0.0,1.0)
	var age_years:=maxf(0.0,(float(GameState.elapsed_days)-float(plot.get("converted_day",plot.get("created_day",GameState.elapsed_days))))/365.0)
	var wear_row:=0
	if condition<0.34 or age_years>38.0: wear_row=3
	elif condition<0.58 or age_years>18.0: wear_row=2
	elif age_years>6.0: wear_row=1
	if roof_variant>0 and (absi(int(plot.get("seed",1)))+roof_variant*13)%6==0: wear_row=mini(3,wear_row+1)
	var use:=String(plot.get("land_use",""))
	var family:=String(plot.get("material_family","organic"))
	if use in ["dirty_industry","workshop","storage"] and "blast_furnace" in GameState.known_discoveries:
		return Vector2i(2,wear_row)
	if use in ["civic","market","hospitality"] and "covered_sewers" in GameState.known_discoveries:
		return Vector2i(3,wear_row)
	if family=="stone": return Vector2i(1,wear_row)
	return Vector2i(0,wear_row)

func _roof_repair_atlas_cell(plot:Dictionary,base_cell:Vector2i,roof_variant:int)->Vector2i:
	var mix:Dictionary=plot.get("material_mix",{})
	var candidates:Array[Vector2i]=[]
	if float(mix.get("Fiber Plants",0.0))>0.035: candidates.append(Vector2i(0,3))
	if float(mix.get("Timber",0.0))>0.035: candidates.append(Vector2i(1,3))
	if float(mix.get("Clay",0.0))>0.055: candidates.append(Vector2i(2,3))
	if float(mix.get("Stone",0.0))>0.070: candidates.append(Vector2i(3,3))
	if candidates.size()<=1: return base_cell
	var start:=absi(int(plot.get("seed",1))+roof_variant*17)%candidates.size()
	for offset in candidates.size():
		var candidate:Vector2i=candidates[(start+offset)%candidates.size()]
		if candidate!=base_cell: return candidate
	return base_cell

func _roof_material_tone(cell:Vector2i,seed_value:int)->Color:
	var palettes:Dictionary={
		0:[Color("#b5a06d"),Color("#8f7c51"),Color("#c2ae79"),Color("#665e49")],
		1:[Color("#6f5e48"),Color("#4f4d45"),Color("#7a6850"),Color("#55534d")],
		2:[Color("#9a684d"),Color("#7c513f"),Color("#b68762"),Color("#715245")],
		3:[Color("#777872"),Color("#6d6256"),Color("#92908a"),Color("#555c57")]
	}
	var palette:Array=palettes.get(cell.x,palettes[0])
	var tone:Color=palette[absi(seed_value)%palette.size()]
	if cell.y==1: tone=tone.darkened(0.025)
	elif cell.y==2: tone=tone.darkened(0.055).lerp(Color("#66705c"),0.07)
	elif cell.y==3: tone=tone.darkened(0.07)
	return tone

func _late_roof_material_tone(cell:Vector2i,seed_value:int)->Color:
	var palettes:Dictionary={
		0:[Color("#88614b"),Color("#75594a"),Color("#9a765b"),Color("#66534a")],
		1:[Color("#555a5a"),Color("#454c4e"),Color("#656867"),Color("#3f4547")],
		2:[Color("#697071"),Color("#5b6262"),Color("#77736a"),Color("#555a5b")],
		3:[Color("#8b8981"),Color("#74756f"),Color("#99958a"),Color("#686b68")]
	}
	var palette:Array=palettes.get(cell.x,palettes[3])
	var tone:Color=palette[absi(seed_value)%palette.size()]
	if cell.y==1: tone=tone.darkened(0.035)
	elif cell.y==2: tone=tone.darkened(0.075).lerp(Color("#64685c"),0.08)
	elif cell.y==3: tone=tone.darkened(0.12)
	return tone

func _append_flat_quad(surface:SurfaceTool,center:Vector3,local_center:Vector2,right:Vector2,forward:Vector2,color:Color,lift:float,atlas_cell:=Vector2i(-1,-1),texture_seed:=0)->void:
	var corners:=[local_center-right-forward,local_center+right-forward,local_center+right+forward,local_center-right+forward]
	var corner_uvs:=[Vector2(0.0,0.0),Vector2(1.0,0.0),Vector2(1.0,1.0),Vector2(0.0,1.0)]
	var texture_coordinates:=Vector2(fposmod(forward.angle(),TAU)/TAU,float(absi(texture_seed)%997)/997.0)
	for corner_index in [0,1,2,0,2,3]:
		var point_2d:Vector2=corners[corner_index]
		var world_point:=Vector3(center.x+point_2d.x,0.0,center.z+point_2d.y)
		world_point.y=_close_surface_height_at(world_point.x,world_point.z)+lift
		surface.set_color(color)
		surface.set_uv(_atlas_uv(atlas_cell,corner_uvs[corner_index]))
		surface.set_uv2(texture_coordinates)
		surface.add_vertex(world_point)

func _roof_local_uv(point:Vector2,local_center:Vector2,right:Vector2,forward:Vector2)->Vector2:
	var offset:=point-local_center
	var horizontal:=0.5+0.5*offset.dot(right)/maxf(right.length_squared(),0.00000001)
	var vertical:=0.5+0.5*offset.dot(forward)/maxf(forward.length_squared(),0.00000001)
	return Vector2(clampf(horizontal,0.0,1.0),clampf(vertical,0.0,1.0))

func _append_irregular_roof_patch(surface:SurfaceTool,center:Vector3,local_center:Vector2,right:Vector2,forward:Vector2,color:Color,lift:float,atlas_cell:Vector2i,texture_seed:int,late_atlas:=false)->void:
	var rng:=RandomNumberGenerator.new()
	rng.seed=texture_seed
	var points:Array[Vector2]=[]
	var segments:=rng.randi_range(6,8)
	var angle_offset:=rng.randf()*TAU
	for index in segments:
		var angle:=angle_offset+TAU*float(index)/float(segments)+rng.randf_range(-0.13,0.13)
		var direction:=Vector2(cos(angle),sin(angle))
		points.append(local_center+right*direction.x*rng.randf_range(0.62,1.10)+forward*direction.y*rng.randf_range(0.58,1.08))
	var texture_coordinates:=Vector2(fposmod(forward.angle(),TAU)/TAU,float(absi(texture_seed)%997)/997.0+(2.0 if late_atlas else 0.0))
	for index in segments:
		for point_2d in [local_center,points[index],points[(index+1)%segments]]:
			var world_point:=Vector3(center.x+point_2d.x,0.0,center.z+point_2d.y)
			world_point.y=_close_surface_height_at(world_point.x,world_point.z)+lift
			surface.set_color(color)
			surface.set_uv(_atlas_uv(atlas_cell,_roof_local_uv(point_2d,local_center,right,forward)))
			surface.set_uv2(texture_coordinates)
			surface.add_vertex(world_point)

func _append_roof_footprint(surface:SurfaceTool,center:Vector3,local_center:Vector2,right:Vector2,forward:Vector2,color:Color,lift:float,atlas_cell:Vector2i,variant:int,roof_plan:String,texture_seed:=0,late_atlas:=false)->void:
	var points:Array[Vector2]=[]
	var texture_coordinates:=Vector2(fposmod(forward.angle(),TAU)/TAU,float(absi(texture_seed+variant*43)%997)/997.0+(2.0 if late_atlas else 0.0))
	if late_atlas:
		# Later roofing is laid in standardized courses or sheets. Small seeded skew
		# keeps inherited blocks from becoming a perfect CAD grid without pretending
		# corrugated iron is a tapered thatch bundle merely because both use column 0.
		var skew:=right*(0.035 if variant%2==0 else -0.03)
		points=[local_center-right-forward+skew,local_center+right-forward,local_center+right+forward-skew,local_center-right+forward]
	elif roof_plan in ["round_thatch","round_light_shelter"]:
		var radial_segments:=10
		var round_radius:=sqrt(maxf(0.0000001,right.length()*forward.length()))*0.91
		var round_right:=right.normalized()*round_radius
		var round_forward:=forward.normalized()*round_radius
		for radial_index in radial_segments:
			var angle:=TAU*float(radial_index)/float(radial_segments)
			points.append(local_center+round_right*cos(angle)+round_forward*sin(angle))
	elif atlas_cell.x==0 or roof_plan in ["tapered_thatch","tapered_light_shelter","long_thatch"]:
		# Fibre roofs taper at the ridge ends and read as bundled thatch rather than
		# mass-produced rectangular tiles.
		var hand:=0.06 if variant%2==0 else -0.05
		points=[local_center-right*(0.68+hand)-forward,local_center+right*(0.74-hand)-forward*0.96,local_center+right+forward*0.52,local_center+right*0.57+forward,local_center-right*(0.62-hand)+forward*0.94,local_center-right+forward*(0.61+hand)]
	elif atlas_cell.x==1 or roof_plan in ["timber_ridge","ridge_light_shelter"]:
		# Hand-split boards and bark shingles produce stepped eaves, not four exact
		# corners. The asymmetry is deliberately sub-metre at world scale.
		var step:=0.08 if variant%2==0 else -0.07
		points=[local_center-right*(0.90+step)-forward,local_center+right*(0.83-step)-forward,local_center+right+forward*0.38,local_center+right*(0.91-step)+forward,local_center-right*(0.79+step)+forward,local_center-right-forward*0.22]
	elif atlas_cell.x==2 or roof_plan in ["irregular_flat","courtyard_flat","mixed_earthen_span"]:
		# Hand-smoothed mud roofs keep visibly imperfect corners.
		var skew:=right*(0.10 if variant%2==0 else -0.08)
		points=[local_center-right-forward+skew,local_center+right*0.92-forward,local_center+right+forward*0.87,local_center-right*0.86+forward]
	elif atlas_cell.x==3 or roof_plan in ["rubble_slab","timber_span_on_rubble"]:
		# Rubble/slab coverings form an uneven heavy footprint.
		points=[local_center-right*0.82-forward,local_center+right*0.72-forward*0.94,local_center+right+forward*0.26,local_center+right*0.78+forward,local_center-right*0.64+forward*0.91,local_center-right-forward*0.08]
	else:
		points=[local_center-right-forward,local_center+right-forward,local_center+right+forward,local_center-right+forward]
	if points.size()<3: return
	if late_atlas and atlas_cell.x in [0,1,2]:
		# Tile, slate and sheet-metal spans need a shallow ridge in an oblique aerial
		# view. The rise remains sub-metre and is part of the aggregate roof surface,
		# not a separate miniature building asset.
		var ridge_rise:=0.00042 if atlas_cell.x==2 else 0.00072
		var left_back:=local_center-right-forward
		var left_front:=local_center-right+forward
		var right_back:=local_center+right-forward
		var right_front:=local_center+right+forward
		var ridge_back:=local_center-forward
		var ridge_front:=local_center+forward
		var left_color:=color.lightened(0.045)
		var right_color:=color.darkened(0.075)
		var roof_faces:=[
			[[left_back,0.0,left_color],[left_front,0.0,left_color],[ridge_front,ridge_rise,left_color]],
			[[left_back,0.0,left_color],[ridge_front,ridge_rise,left_color],[ridge_back,ridge_rise,left_color]],
			[[ridge_back,ridge_rise,right_color],[ridge_front,ridge_rise,right_color],[right_front,0.0,right_color]],
			[[ridge_back,ridge_rise,right_color],[right_front,0.0,right_color],[right_back,0.0,right_color]]
		]
		for face in roof_faces:
			for roof_vertex in face:
				var point_2d:Vector2=roof_vertex[0]
				var world_point:=Vector3(center.x+point_2d.x,0.0,center.z+point_2d.y)
				world_point.y=_close_surface_height_at(world_point.x,world_point.z)+lift+float(roof_vertex[1])
				surface.set_color(roof_vertex[2])
				surface.set_uv(_atlas_uv(atlas_cell,_roof_local_uv(point_2d,local_center,right,forward)))
				surface.set_uv2(texture_coordinates)
				surface.add_vertex(world_point)
		return
	if roof_plan in ["round_thatch","round_light_shelter"] and atlas_cell.x>=0:
		# A centre-to-eave value gradient is the aerial cue for a shallow conical
		# thatch roof. It remains only centimetres above the terrain drape and does
		# not become an oversized 3D prop.
		var crown_color:=color.lightened(0.10)
		for point_index in points.size():
			var next_index:=(point_index+1)%points.size()
			var rim_direction:=(points[point_index]-local_center).normalized()
			var directional_shade:=0.075+0.065*(0.5+0.5*rim_direction.dot(Vector2(0.62,0.78)))
			var rim_color:=color.darkened(directional_shade)
			for roof_vertex in [[local_center,lift+0.00014,crown_color],[points[point_index],lift,rim_color],[points[next_index],lift,color.darkened(directional_shade*0.82)]]:
				var point_2d:Vector2=roof_vertex[0]
				var world_point:=Vector3(center.x+point_2d.x,0.0,center.z+point_2d.y)
				world_point.y=_close_surface_height_at(world_point.x,world_point.z)+float(roof_vertex[1])
				surface.set_color(roof_vertex[2])
				surface.set_uv(_atlas_uv(atlas_cell,_roof_local_uv(point_2d,local_center,right,forward)))
				surface.set_uv2(texture_coordinates)
				surface.add_vertex(world_point)
		return
	if atlas_cell.x in [0,1] and roof_plan not in ["irregular_flat","courtyard_flat","mixed_earthen_span","rubble_slab"]:
		# A shallow visual ridge is enough to read as a roof from above. Geometry
		# remains terrain-scale; value and a few centimetres of crown replace the
		# previous flat, box-like card.
		var crown_color:=color.lightened(0.12)
		for point_index in points.size():
			var next_index:=(point_index+1)%points.size()
			for roof_vertex in [[local_center,lift+0.00010,crown_color],[points[point_index],lift,color.darkened(0.13)],[points[next_index],lift,color.darkened(0.09)]]:
				var point_2d:Vector2=roof_vertex[0]
				var world_point:=Vector3(center.x+point_2d.x,0.0,center.z+point_2d.y)
				world_point.y=_close_surface_height_at(world_point.x,world_point.z)+float(roof_vertex[1])
				surface.set_color(roof_vertex[2])
				surface.set_uv(_atlas_uv(atlas_cell,_roof_local_uv(point_2d,local_center,right,forward)))
				surface.set_uv2(texture_coordinates)
				surface.add_vertex(world_point)
		return
	for point_index in range(1,points.size()-1):
		for point_2d in [points[0],points[point_index],points[point_index+1]]:
			var world_point:=Vector3(center.x+point_2d.x,0.0,center.z+point_2d.y)
			world_point.y=_close_surface_height_at(world_point.x,world_point.z)+lift
			surface.set_color(color)
			surface.set_uv(_atlas_uv(atlas_cell,_roof_local_uv(point_2d,local_center,right,forward)))
			surface.set_uv2(texture_coordinates)
			surface.add_vertex(world_point)

func _append_roof_wall_skirt(surface:SurfaceTool,center:Vector3,local_center:Vector2,right:Vector2,forward:Vector2,plot:Dictionary,roof_lift:float)->int:
	var family:=String(plot.get("material_family","organic"))
	var use:=String(plot.get("land_use",""))
	var condition:=clampf(float(plot.get("condition",0.72)),0.0,1.0)
	var wall_color:=Color("#695c47")
	if family=="earth": wall_color=Color("#84654f")
	elif family=="stone": wall_color=Color("#77766f")
	if use=="dirty_industry": wall_color=wall_color.lerp(Color("#454844"),0.58)
	elif use in ["civic","sacred"]: wall_color=wall_color.lerp(Color("#aaa398"),0.34)
	wall_color=wall_color.darkened((1.0-condition)*0.22)
	wall_color.a=0.46
	var corners:=[local_center-right-forward,local_center+right-forward,local_center+right+forward,local_center-right+forward]
	var sides:=0
	for side_index in 4:
		var first:Vector2=corners[side_index]
		var second:Vector2=corners[(side_index+1)%4]
		var side_shade:=0.06+float(side_index%3)*0.055
		var side_color:=wall_color.darkened(side_shade)
		var first_ground:=_close_surface_height_at(center.x+first.x,center.z+first.y)
		var second_ground:=_close_surface_height_at(center.x+second.x,center.z+second.y)
		var vertices:=[
			Vector3(center.x+first.x,first_ground+0.0016,center.z+first.y),
			Vector3(center.x+second.x,second_ground+0.0016,center.z+second.y),
			Vector3(center.x+second.x,second_ground+roof_lift-0.00008,center.z+second.y),
			Vector3(center.x+first.x,first_ground+roof_lift-0.00008,center.z+first.y)
		]
		for vertex_index in [0,1,2,0,2,3]:
			surface.set_color(side_color)
			surface.add_vertex(vertices[vertex_index])
		sides+=1
	return sides

func _append_satellite_roof_fabric(surface:SurfaceTool,wall_surface:SurfaceTool,plot:Dictionary,center:Vector3,lod:int=0)->Dictionary:
	var polygon:PackedVector2Array=plot.get("polygon",PackedVector2Array())
	if polygon.size()<3: return {"roofs":0,"walls":0}
	var plot_center:=Vector2(plot.get("centroid",Vector2.ZERO))
	var coverage:=clampf(float(plot.get("roof_coverage",0.18)),0.04,0.72)
	var residents:=maxi(0,int(plot.get("resident_count",0)))
	var use:=String(plot.get("land_use",""))
	var emergency_camp:=String(plot.get("form",""))=="emergency_open_encampment"
	var temporary_camp:=String(plot.get("form","")) in ["portable_shelter_cluster","light_shelter_cluster","emergency_open_encampment"]
	var roof_plan:=String(plot.get("roof_plan",["round_thatch","tapered_thatch","timber_ridge","long_thatch"][absi(int(plot.get("seed",1)))%4]))
	var rng:=RandomNumberGenerator.new()
	rng.seed=int(plot.get("seed",1))^0x6d2b79f5
	var base_angle:=rng.randf_range(0.0,TAU)
	var architecture:=_settlement_visual_architecture_profile(_settlement_architecture_profile())
	var axiality:=clampf(float(architecture.get("axiality",0.5)),0.0,1.0)
	var monumentality:=clampf(float(architecture.get("monumentality",0.5)),0.0,1.0)
	var civic_space:=clampf(float(architecture.get("civic_space",0.5)),0.0,1.0)
	var permeability:=clampf(float(architecture.get("permeability",0.5)),0.0,1.0)
	var defensive_depth:=clampf(float(architecture.get("defensive_depth",0.5)),0.0,1.0)
	var terrain_conformity:=clampf(float(architecture.get("terrain_conformity",0.5)),0.0,1.0)
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
	var plot_world_center:=Vector2(center.x+plot_center.x,center.z+plot_center.y)
	var contour_angle:=_terrain_contour_angle(plot_world_center,base_angle)
	# Ecologically restrained settlements bend along relief; centralized and
	# hierarchical societies increasingly align construction to one civic axis. Both
	# operations only change the batched representation of the authoritative plots.
	base_angle=_lerp_undirected_angle(base_angle,contour_angle,terrain_conformity*0.72)
	base_angle=_lerp_undirected_angle(base_angle,_settlement_civic_axis(),axiality*axiality*0.82)
	var occupied_pressure:=clampf(float(residents)/34.0,0.0,1.0)
	var fabric_generation:=clampi(int(plot.get("fabric_generation",0)),0,12)
	var storeys:=clampi(int(plot.get("storeys",1)),1,5)
	var density_bonus:=roundi(route_maturity*occupied_pressure*2.2)+int(plot.get("infill_units",0))+floori(float(fabric_generation)*0.72)+maxi(0,storeys-1)*2
	var household_variation:=rng.randi_range(-1,2)
	var mass_count:=clampi(ceili(coverage*3.2)+ceili(float(residents)/22.0)+density_bonus+household_variation,1,14)
	var plot_radius:=sqrt(maxf(0.0000001,float(plot.get("area_ha",0.02))/100.0)/PI)
	if emergency_camp: mass_count=clampi(ceili(float(residents)/11.0),4,14)
	elif temporary_camp:
		# A founding plot is a household cluster, not one implausibly tiny tent.
		# Derive its visible covers from actual residents while keeping the number
		# bounded enough to read as an organic camp from aerial inspection height.
		mass_count=clampi(ceili(float(maxi(residents,1))/3.2),1,4)
	if use in ["communal","civic","sacred","market","workshop","storage","hospitality","dirty_industry"]: mass_count=clampi(1+roundi(coverage*3.0)+roundi(route_maturity)+floori(float(fabric_generation)*0.48),1,8)
	if use in ["communal","civic","sacred","market"] and civic_space>0.52:
		# Public life appears as actual breathing room rather than another icon: fewer,
		# larger aggregate masses preserve a readable court inside the same plot.
		mass_count=maxi(1,mass_count-roundi((civic_space-0.52)*3.2))
	if fabric_generation>=10 and not temporary_camp:
		# Later parcels consolidate into a few connected roof masses and courts.
		# Fourteen tiny huts inside a metropolitan lot is physically wrong and
		# becomes visual noise at the playable aerial camera height.
		mass_count=clampi(2+storeys+(1 if use in ["civic","market","workshop","storage"] else 0),2,6)
	var source_mass_count:=mass_count
	if lod>=1:
		# Intermediate aerial views need occupied roof coverage, not every represented
		# household mass and repair. Collapse them into at most four larger masses while
		# retaining the same authoritative plot, material, age, use, and population.
		mass_count=clampi(ceili(sqrt(float(mass_count))),1,4)
	var lod_coverage_scale:=clampf(sqrt(float(source_mass_count)/float(maxi(1,mass_count)))*0.86,1.0,2.35) if lod>=1 else 1.0
	var appended:=0
	var walls_appended:=0
	for mass_index in mass_count:
		var mass_roof_plan:=roof_plan
		if emergency_camp:
			mass_roof_plan=["round_light_shelter","tapered_light_shelter","ridge_light_shelter"][(absi(int(plot.get("seed",1)))+mass_index*5)%3]
		elif roof_plan in ["round_thatch","round_light_shelter"] and mass_index>0:
			mass_roof_plan="tapered_light_shelter" if temporary_camp else ("tapered_thatch" if mass_index%2==1 else "timber_ridge")
		var turn_across_courtyard:=mass_count>=3 and mass_index%3==2
		if fabric_generation>=6 and mass_count>=6:
			# Mature inherited plots read as perimeter/courtyard fabric rather than a
			# longer line of detached huts. The persistent polygon remains unchanged.
			turn_across_courtyard=mass_index%4 in [2,3]
		var orientation_jitter:=lerpf(0.18,0.022,axiality)
		var mass_angle:=rng.randf()*TAU if emergency_camp else base_angle+(PI*0.5 if turn_across_courtyard else rng.randf_range(-orientation_jitter,orientation_jitter))
		var side_axis:=Vector2.from_angle(mass_angle)
		var depth_axis:=Vector2(-side_axis.y,side_axis.x)
		var rank:=float(mass_index)-float(mass_count-1)*0.5
		var row_spacing:=rng.randf_range(0.0032,0.0051)*lerpf(0.84,1.20,permeability)
		var row_offset:=rank*row_spacing
		var court_scale:=lerpf(0.72,1.42,civic_space)*lerpf(0.92,1.12,permeability)
		var courtyard_depth:=((0.0032 if mass_index%2==0 else -0.0022)*court_scale) if mass_count>=4 else rng.randf_range(-0.0022,0.0022)*court_scale
		var local_center:=plot_center+Vector2.from_angle(base_angle)*row_offset+Vector2.from_angle(base_angle+PI*0.5)*courtyard_depth
		if fabric_generation>=4 and not temporary_camp:
			# Mature fabric occupies inherited parcel edges and leaves an irregular
			# internal court. From altitude this becomes a connected town texture,
			# while the plot polygon and old frontage still determine its exact form.
			var perimeter_t:=float(mass_index)/float(maxi(1,mass_count))
			var perimeter_angle:=base_angle+perimeter_t*TAU+rng.randf_range(-0.09,0.09)
			var perimeter_pressure:=maxf(defensive_depth,civic_space if use in ["communal","civic","sacred","market"] else 0.0)
			var outer_ring:=lerpf(0.36,0.54,perimeter_pressure)
			var inner_ring:=lerpf(0.18,0.29,civic_space)
			var ring_radius:=plot_radius*(outer_ring if mass_index%4!=0 else inner_ring)
			local_center=plot_center+Vector2.from_angle(perimeter_angle)*ring_radius
		if emergency_camp:
			local_center=plot_center+Vector2.from_angle(rng.randf()*TAU)*sqrt(rng.randf())*plot_radius*rng.randf_range(0.30,0.78)
		if not Geometry2D.is_point_in_polygon(local_center,polygon): local_center=plot_center.lerp(local_center,0.42)
		var density_scale:=lerpf(1.0,0.72,clampf(float(mass_count-3)/9.0,0.0,1.0))
		var half_width:=rng.randf_range(0.0012,0.0025)*density_scale
		var half_depth:=rng.randf_range(0.0017,0.0035)*density_scale
		if fabric_generation>=10 and not temporary_camp:
			# At strategic scale one mature mass represents joined rooms, party walls
			# and rear structures, not a single miniature house.  Filling the recorded
			# parcel more honestly makes a city read as continuous fabric.
			half_width=rng.randf_range(0.00235,0.00425)
			half_depth=rng.randf_range(0.00285,0.00510)
		if temporary_camp:
			half_width=rng.randf_range(0.00110,0.00175)
			half_depth=rng.randf_range(0.00145,0.00225)
		if emergency_camp:
			half_width=rng.randf_range(0.00042,0.00086)
			half_depth=rng.randf_range(0.00056,0.00108)
		if use in ["communal","civic","market","workshop","storage","hospitality","dirty_industry"]:
			half_width*=rng.randf_range(1.25,1.65)
			half_depth*=rng.randf_range(1.10,1.42)
		if use in ["communal","civic","sacred"]:
			var civic_mass_scale:=lerpf(0.92,1.38,monumentality)
			half_width*=civic_mass_scale
			half_depth*=lerpf(0.96,1.22,monumentality)
		half_width*=lod_coverage_scale
		half_depth*=lod_coverage_scale
		if fabric_generation>=11 and use in ["workshop","storage","dirty_industry"]:
			# Powered production and bulk logistics replace collections of little sheds
			# with a smaller number of legible long-span roofs.  The authoritative plot
			# is unchanged; this is the roof coverage its late form already records.
			half_width*=rng.randf_range(1.38,1.72)
			half_depth*=rng.randf_range(1.18,1.48)
		elif fabric_generation>=10 and use in ["civic","sacred"]:
			half_width*=rng.randf_range(1.18,1.38)
			half_depth*=rng.randf_range(1.08,1.24)
		# Portable covers remain a terrain-draped symbol. Durable fabric receives a
		# real wall skirt below the roof, so oblique aerial views communicate storeys
		# and density without spawning one authored building node per household.
		# The map renders aggregate roof coverage, not literal authored buildings.
		# A shallow parallax skirt communicates vertical development without turning
		# every parcel proxy into a full-height block at this camera scale.
		var roof_lift:=0.0031 if temporary_camp else (0.00055+float(storeys)*0.00055)
		if not temporary_camp and use in ["communal","civic","sacred"]:
			roof_lift*=lerpf(0.92,1.72,monumentality)
		if temporary_camp:
			var shadow_center:=local_center+Vector2(0.00034,0.00044)
			_append_roof_footprint(surface,center,shadow_center,side_axis*half_width*1.025,depth_axis*half_depth*1.025,Color(0.08,0.075,0.055,0.055),0.00295,Vector2i(-1,-1),mass_index,mass_roof_plan,int(plot.get("seed",1)))
		var weather_palette:=[Color("#8c714b"),Color("#706047"),Color("#9a8058"),Color("#68665a"),Color("#79563f")]
		var family:=String(plot.get("material_family","organic"))
		if family=="earth": weather_palette=[Color("#a16a48"),Color("#76503b"),Color("#b07c57"),Color("#68483b"),Color("#8c5c43")]
		elif family=="stone": weather_palette=[Color("#858178"),Color("#646862"),Color("#989187"),Color("#595e5a"),Color("#777269")]
		if temporary_camp: weather_palette=[Color("#a89770"),Color("#776c56"),Color("#b3a27a"),Color("#666256"),Color("#8f7854")]
		if emergency_camp: weather_palette=[Color("#87785b"),Color("#6c654f"),Color("#9a8762"),Color("#5c6252"),Color("#806449")]
		if fabric_generation>=10 and not temporary_camp:
			weather_palette=[Color("#686964"),Color("#858077"),Color("#9b866d"),Color("#595d5c"),Color("#786d61"),Color("#a29683")]
		if use=="dirty_industry": weather_palette=[Color("#454744"),Color("#655b4e"),Color("#3e4443"),Color("#765443"),Color("#55524b")]
		elif use in ["civic","sacred"] and fabric_generation>=7: weather_palette=[Color("#aaa59a"),Color("#8d8b84"),Color("#b8ae9c"),Color("#777a77")]
		var supports_late_roof:=fabric_generation>=9 and not temporary_camp and (
			("blast_furnace" in GameState.known_discoveries and use in ["dirty_industry","workshop","storage"])
			or ("covered_sewers" in GameState.known_discoveries and use in ["civic","market","hospitality"])
			or ("stone_selection" in GameState.known_discoveries and family=="stone")
			or ("pit_firing" in GameState.known_discoveries and family=="earth")
		)
		var roof_atlas_cell:=_late_roof_atlas_cell(plot,mass_index) if supports_late_roof else _roof_atlas_cell(plot,temporary_camp,mass_index)
		var weather_tone:Color=weather_palette[(absi(int(plot.get("seed",1)))+mass_index*3)%weather_palette.size()]
		var material_tone:=_late_roof_material_tone(roof_atlas_cell,int(plot.get("seed",1))+mass_index*29) if supports_late_roof else _roof_material_tone(roof_atlas_cell,int(plot.get("seed",1))+mass_index*29)
		var tone:=material_tone.lerp(weather_tone,rng.randf_range(0.12,0.30))
		tone=_architecture_roof_tone(tone,use)
		if fabric_generation>=5:
			# Later fabric is visually heterogeneous but no longer a spray of saturated
			# hut colors. Dust, soot, repair and closely spaced roofs compress its aerial
			# palette into a coherent urban mass.
			tone=tone.lerp(Color("#716957"),clampf(0.16+float(fabric_generation-5)*0.055,0.0,0.38))
		var roof_age_years:=maxf(0.0,(float(GameState.elapsed_days)-float(plot.get("created_day",GameState.elapsed_days)))/365.0)
		var roof_condition:=clampf(float(plot.get("condition",0.72)),0.0,1.0)
		var exposure:=clampf(roof_age_years/18.0+(1.0-roof_condition)*0.7,0.0,1.0)
		tone=tone.lerp(Color("#625f4d"),exposure*0.10)
		tone=tone.lightened(rng.randf_range(-0.05,0.055))
		# At this LOD these are density flecks, not individually modelled houses.
		tone.a=rng.randf_range(0.58,0.76) if emergency_camp else (rng.randf_range(0.80,0.93) if temporary_camp else rng.randf_range(0.91,0.99))
		if camera!=null and camera.size>0.42:
			# At settlement LOD the plot-derived density stain carries the inhabited
			# extent; roofs remain material detail instead of becoming black confetti.
			# Aerial scattering compresses contrast and opacity at this scale,
			# especially for weathered timber and slate source photographs.
			tone=tone.lerp(Color("#a0957f"),0.31)
			tone.a*=0.34
		if not temporary_camp:
			walls_appended+=_append_roof_wall_skirt(wall_surface,center,local_center,side_axis*half_width,depth_axis*half_depth,plot,roof_lift)
		_append_roof_footprint(surface,center,local_center,side_axis*half_width,depth_axis*half_depth,tone,roof_lift,roof_atlas_cell,mass_index,mass_roof_plan,int(plot.get("seed",1)),supports_late_roof)
		# Roof-scale fibre courses, boards and repairs survive as texture at the
		# playable aerial zoom. They share the physical footprint; no giant prop is
		# introduced just to make a building readable.
		# The photographic atlas now carries real bindings, boards and joints. The old
		# stack of translucent quads only reintroduced the coloured-box look.
		var course_count:=0
		for course_index in course_count:
			var course_t:=(float(course_index)+0.5)/float(course_count)-0.5
			var course_center:=local_center+side_axis*(course_t*half_width*1.72)
			var course_color:=tone.lightened(rng.randf_range(-0.12,0.14))
			course_color.a=0.26 if family=="organic" else 0.18
			_append_flat_quad(surface,center,course_center,side_axis*(half_width/float(course_count)*0.24),depth_axis*half_depth*0.91,course_color,0.00363,roof_atlas_cell,int(plot.get("seed",1))+mass_index*53+course_index)
		if lod==0 and not temporary_camp and rng.randf()<0.68:
			var patch_center:=local_center+side_axis*rng.randf_range(-half_width*0.42,half_width*0.42)+depth_axis*rng.randf_range(-half_depth*0.38,half_depth*0.38)
			var repair_cell:=Vector2i(roof_atlas_cell.x,3) if supports_late_roof else _roof_repair_atlas_cell(plot,roof_atlas_cell,mass_index)
			var patch_color:Color=(_late_roof_material_tone(repair_cell,int(plot.get("seed",1))+mass_index*47+11) if supports_late_roof else _roof_material_tone(repair_cell,int(plot.get("seed",1))+mass_index*47+11)).lerp(Color("#4d4637"),rng.randf_range(0.05,0.20))
			patch_color.a=0.44 if repair_cell!=roof_atlas_cell else 0.28
			_append_irregular_roof_patch(surface,center,patch_center,side_axis*half_width*rng.randf_range(0.16,0.34),depth_axis*half_depth*rng.randf_range(0.14,0.31),patch_color,roof_lift+0.00006,repair_cell,int(plot.get("seed",1))+mass_index*71+19,supports_late_roof)
		appended+=1
	return {"roofs":appended,"walls":walls_appended}

func _append_plot_boundary(surface:SurfaceTool,plot:Dictionary,center:Vector3)->int:
	var polygon:PackedVector2Array=plot.get("polygon",PackedVector2Array())
	if polygon.size()<3: return 0
	var use:=String(plot.get("land_use",""))
	var status:=String(plot.get("status","active"))
	var architecture:=_settlement_visual_architecture_profile(_settlement_architecture_profile())
	var permeability:=clampf(float(architecture.get("permeability",0.5)),0.0,1.0)
	var defensive_depth:=clampf(float(architecture.get("defensive_depth",0.5)),0.0,1.0)
	var width:=0.00025 if use in ["field","pasture"] else 0.00010
	var color:=Color(0.24,0.25,0.14,0.27) if use in ["field","pasture"] else Color(0.29,0.25,0.17,0.18)
	if use not in ["field","pasture"]:
		var enclosure_strength:=clampf(0.72+defensive_depth*0.45-permeability*0.20,0.52,1.18)
		width*=enclosure_strength
		color.a*=enclosure_strength
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
		var spans:Array=[Vector2(0.0,1.0)]
		if use not in ["field","pasture"]:
			var gate_roll:=float(absi(int(plot.get("seed",1))*31+edge_index*137)%1000)/999.0
			var gate_probability:=clampf(0.05+permeability*0.44-defensive_depth*0.12,0.02,0.48)
			if gate_roll<gate_probability and direction.length()>0.0035:
				var gate_center:=0.38+float(absi(int(plot.get("seed",1))+edge_index*43)%250)/1000.0
				var gate_half:=lerpf(0.055,0.13,permeability)
				spans=[Vector2(0.0,gate_center-gate_half),Vector2(gate_center+gate_half,1.0)]
		for span_variant in spans:
			var span:Vector2=span_variant
			var span_start:=start.lerp(finish,span.x)
			var span_finish:=start.lerp(finish,span.y)
			if span_start.distance_to(span_finish)<0.00025: continue
			var side:=Vector2(-direction.y,direction.x).normalized()*edge_width
			for point_2d in [span_start-side,span_finish-side,span_finish+side,span_start-side,span_finish+side,span_start+side]:
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
	var use:=String(plot.get("land_use",""))
	var fabric_generation:=clampi(int(plot.get("fabric_generation",0)),0,12)
	var patch_count:=rng.randi_range(4,8)
	if fabric_generation>=9 and use in ["workshop","storage","dirty_industry"]: patch_count=rng.randi_range(2,4)
	elif fabric_generation>=8 and use in ["civic","sacred","market"]: patch_count=rng.randi_range(2,5)
	var appended:=0
	for patch_index in patch_count:
		var local_center:=plot_center+Vector2.from_angle(rng.randf()*TAU)*rng.randf_range(0.0010,0.0074)
		if not Geometry2D.is_point_in_polygon(local_center,polygon): continue
		var world_center:=Vector3(center.x+local_center.x,0.0,center.z+local_center.y)
		var ground_cells:=[Vector2i(3,2),Vector2i(1,0),Vector2i(2,2),Vector2i(0,0)]
		if use=="dirty_industry": ground_cells=[Vector2i(0,0),Vector2i(3,2),Vector2i(2,3)]
		elif use=="storage": ground_cells=[Vector2i(1,0),Vector2i(3,2),Vector2i(0,0)]
		elif use in ["civic","sacred"]: ground_cells=[Vector2i(3,2),Vector2i(1,0),Vector2i(3,3)]
		var atlas_cell:Vector2i=ground_cells[(absi(int(plot.get("seed",1)))+patch_index*3)%ground_cells.size()]
		var color:=Color.WHITE.lerp(Color("#7d765f"),rng.randf_range(0.04,0.18))
		if use=="dirty_industry": color=color.lerp(Color("#353631"),0.48)
		elif use in ["civic","sacred"]: color=color.lerp(Color("#b3aa96"),0.22)
		color.a=rng.randf_range(0.18,0.36)
		var patch_radius:=rng.randf_range(0.0013,0.0040)
		if fabric_generation>=9 and use in ["workshop","storage","dirty_industry","civic","sacred"]:
			patch_radius*=rng.randf_range(1.35,2.10)
		_append_textured_ground_patch(surface,world_center,patch_radius,color,0.0027,atlas_cell,int(plot.get("seed",1))^((patch_index+5)*0x45d9f3b))
		appended+=1
	return appended

func _append_field_rows(surface: SurfaceTool, plot: Dictionary, center: Vector3) -> void:
	var polygon:PackedVector2Array=plot.get("polygon",PackedVector2Array())
	if polygon.size()<3: return
	var field_center:=Vector2(plot.get("centroid",Vector2.ZERO))
	var field_pattern:=String(plot.get("field_pattern","smallholder_mosaic"))
	var fabric_generation:=clampi(int(plot.get("fabric_generation",0)),0,12)
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
	if fabric_generation>=10: row_count=6 if field_pattern!="irrigated_beds" else 9
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
			# The internal tenure strips carry cultivation; the full plot underneath is
			# only a faint soil disturbance. Keeping the strips materially readable is
			# what separates grain, pulses, roots and garden beds at map scale.
			row_color.a=(0.26+crop_cover*0.46)*(0.84 if field_pattern=="dryland_patchwork" else 1.0)
			# A worked bed is not a filled rectangle. Build it from separated crop or
			# furrow courses so soil remains visible between them, then vary individual
			# courses by household practice and crop condition.
			var micro_count:=7 if field_pattern=="irrigated_beds" else (5 if field_pattern=="smallholder_mosaic" else 4)
			if fabric_generation>=10: micro_count=3 if field_pattern!="irrigated_beds" else 5
			for micro_index in micro_count:
				if segment_rng.randf()<(0.03+(1.0-crop_cover)*0.12): continue
				var micro_t:=(float(micro_index)+0.5)/float(micro_count)-0.5
				var micro_center_offset:=micro_t*local_half_width*1.82
				var micro_half_width:=local_half_width/float(micro_count)*segment_rng.randf_range(0.36,0.62)
				var micro_start:=segment_start+forward*micro_center_offset+right*segment_rng.randf_range(0.0,0.00038)
				var micro_finish:=segment_finish+forward*micro_center_offset-right*segment_rng.randf_range(0.0,0.00038)
				if micro_finish.distance_to(micro_start)<0.00035: continue
				var micro_color:=row_color.lightened(segment_rng.randf_range(-0.09,0.10))
				var micro_atlas_cell:=field_atlas_cell
				var tenure_variant:=absi(int(plot.get("seed",1))+row_index*19+segment_index*31+micro_index*7)%13
				if field_pattern=="smallholder_mosaic" and tenure_variant in [0,5]:
					micro_atlas_cell=Vector2i(1,2) # mixed garden practice within staple fields
				elif tenure_variant==8:
					micro_atlas_cell=Vector2i(2,2) # fallow/weed interruption
				elif String(plot.get("cultivation_phase","prepared")) in ["prepared","harvested"] and tenure_variant%4==0:
					micro_atlas_cell=Vector2i(2,0) if tenure_variant%2==0 else Vector2i(3,0)
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
					surface.set_uv(_atlas_uv(micro_atlas_cell,corner_uvs[corner_index]))
					surface.set_uv2(Vector2(fposmod(right.angle(),TAU)/TAU,float(absi(int(plot.get("seed",1))+row_index*41+segment_index*17+micro_index)%997)/997.0))
					surface.add_vertex(world_point)
	# Aggregate simulation fields contain many household beds and inherited strips.
	# Cross-dividers make that internal tenure legible without creating more plots.
	var target_divider_width:=0.0065 if field_pattern in ["irrigated_beds","smallholder_mosaic"] else 0.020
	var divider_count:=clampi(floori(longitudinal_extent*2.0/target_divider_width),2,14 if field_pattern!="dryland_patchwork" else 6)
	if fabric_generation>=10: divider_count=clampi(divider_count,2,5)
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
	var density_surface:=SurfaceTool.new()
	density_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var field_ground_surface:=SurfaceTool.new()
	field_ground_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var roof_surface := SurfaceTool.new()
	roof_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var wall_surface := SurfaceTool.new()
	wall_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
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
	var wall_count := 0
	var scar_count := 0
	var field_count := 0
	var field_ground_count:=0
	var feature_count:=0
	var boundary_count:=0
	var variation_count:=0
	var density_count:=0
	for plot_index in plots.size():
		var plot:Dictionary=plots[plot_index]
		var polygon: PackedVector2Array = plot.get("polygon", PackedVector2Array())
		if polygon.size() < 3:
			continue
		var plot_has_detail:=_settlement_plot_has_detail(plot,plot_index,plots.size(),lod)
		var plot_color := _settlement_plot_color(plot)
		var status := String(plot.get("status", "active"))
		var land_use := String(plot.get("land_use", "vacant"))
		var ground_inset:=1.0 if land_use in ["field","water","waste"] else 0.76
		if _settlement_plot_has_aggregate_density(plot,plot_index,plots.size(),lod):
			# Middle zoom needs a coherent inhabited footprint, not one dark pixel per
			# roof. Feathered stains are centred on authoritative occupied plots and
			# overlap only where the persistent fabric is actually dense.
			var plot_area_km2:=maxf(0.000001,float(plot.get("area_ha",0.01))/100.0)
			# Compacted courts, kitchen gardens, ash, animal traffic and shared work
			# ground merge into a continuous aerial footprint before individual roofs
			# resolve. These patches still derive from authoritative occupied plots.
			var density_radius:=clampf(sqrt(plot_area_km2/PI)*(3.85 if lod>=2 else 3.05),0.020,0.061 if lod>=2 else 0.047)
			var density_center:=Vector2(plot.get("centroid",Vector2.ZERO))
			var density_world:=Vector3(center.x+density_center.x,0.0,center.z+density_center.y)
			var density_color:=_settlement_aggregate_density_color(plot,lod)
			# Centuries of compacted yards, joined walls, service courts and surfaced
			# access alter land cover continuously. This is deliberately plot-derived:
			# dense late fabric becomes a satellite-readable urban tone without drawing
			# an arbitrary circular city decal beneath it.
			_append_textured_ground_patch(density_surface,density_world,density_radius,density_color,0.00165,Vector2i(1,0),int(plot.get("seed",1))^0x512f9a)
			density_count+=1
		if land_use=="field" and status not in ["ruin","reclaimed"]:
			var field_ground_color:=plot_color
			# From close range the worked rows carry most of the detail; from the
			# regional camera the parcel itself must survive as a coherent change in
			# land cover. A nearly transparent perimeter made real fields collapse into
			# isolated scratches instead of the satellite-like patchwork they occupy.
			field_ground_color=field_ground_color.darkened(0.08)
			# Close aerial views should read the underlying soil and relief through the
			# cultivated parcel.  Rows, hedges and drainage lines supply the identity;
			# an opaque base turns even an organic cadastral polygon into a board-game mat.
			field_ground_color.a=(0.09 if lod>=1 else 0.035) if status=="active" else 0.050
			# A strong centre-to-edge alpha gradient made six-sided parcels look like
			# glowing map tokens. Worked ground is a coherent, softly edged land-cover
			# change; rows and inherited boundaries provide its internal hierarchy.
			_append_textured_plot_polygon(field_ground_surface,plot,center,field_ground_color,0.0021,Vector2i(-1,-1),0.24)
			field_ground_count+=1
		elif land_use not in ["water","waste","vacant","pasture"] and status!="reclaimed":
			_append_textured_plot_polygon(ground_surface,plot,center,plot_color,0.0018,_ground_atlas_cell(plot),0.68)
		else:
			_append_plot_polygon(ground_surface, polygon, center, plot_color, ground_inset, 0.0018)
		var form:=String(plot.get("form",""))
		var temporary_camp:=form in ["portable_shelter_cluster","light_shelter_cluster","emergency_open_encampment"]
		var feature_center:=Vector2(plot.get("centroid",Vector2.ZERO))
		var feature_world:=Vector3(center.x+feature_center.x,0.0,center.z+feature_center.y)
		if lod<=1 and not temporary_camp:
			boundary_count+=_append_plot_boundary(boundary_surface,plot,center)
			if plot_has_detail and land_use not in ["water","waste","field"]:
				variation_count+=_append_yard_variation(variation_surface,plot,center)
		if lod<=1 and not temporary_camp and land_use in ["communal","civic","sacred","market"]:
			var architecture:=_settlement_visual_architecture_profile(_settlement_architecture_profile())
			var civic_space:=clampf(float(architecture.get("civic_space",0.5)),0.0,1.0)
			var monumentality:=clampf(float(architecture.get("monumentality",0.5)),0.0,1.0)
			var public_radius:=lerpf(0.0028,0.0072,civic_space)
			var public_color:=Color("#87785c")
			if land_use=="market": public_color=Color("#806b4d")
			elif land_use=="sacred": public_color=Color("#a69c87").lerp(Color("#c0b59c"),monumentality*0.24)
			elif land_use=="civic": public_color=Color("#918875").lerp(Color("#b2aa9d"),monumentality*0.22)
			public_color.a=0.24+civic_space*0.22
			_append_textured_ground_patch(feature_surface,feature_world,public_radius,public_color,0.0030,Vector2i(3,2),int(plot.get("seed",1))^0x7a2d31)
			feature_count+=1
			if lod==0 and land_use=="communal":
				# The hearth is close-range evidence inside an irregular shared yard, not
				# a permanent map icon or a settlement-sized glowing dot.
				_append_ground_disc(feature_surface,feature_world,0.00062,Color(0.78,0.37,0.10,0.76),0.0037)
		if lod==0 and land_use=="water":
			_append_ground_disc(feature_surface,feature_world,0.0027,Color(0.16,0.28,0.27,0.76),0.0030)
			feature_count+=1
		elif lod==0 and land_use=="waste":
			_append_ground_disc(feature_surface,feature_world,0.0022,Color(0.23,0.20,0.13,0.60),0.0030)
			feature_count+=1
		if lod<=1 and plot_has_detail and land_use=="field" and status not in ["ruin","reclaimed"]:
			_append_field_rows(field_surface,plot,center)
			field_count+=1
		var open_ground_form:=form in ["open_hearth_yard","open_work_yard","guarded_cache","carried_water_point","refuse_and_latrine_ground"]
		if lod <= 1 and plot_has_detail and status not in ["vacant", "reclaimed"] and not open_ground_form and land_use not in ["water", "waste", "field", "pasture"]:
			if status == "under_construction" and float(plot.get("construction_progress", 0.0)) < 0.26:
				continue
			var mass_counts:=_append_satellite_roof_fabric(roof_surface,wall_surface,plot,center,lod)
			roof_count+=int(mass_counts.get("roofs",0))
			wall_count+=int(mass_counts.get("walls",0))
		if lod == 0 and status in ["damaged", "ruin"] and land_use!="temporary_encampment":
			_append_plot_polygon(scar_surface, polygon, center, Color(0.19, 0.17, 0.15, 0.72), 0.34, 0.0044)
			scar_count += 1
	if density_count>0:
		_commit_settlement_surface(density_surface,"PersistentSettlementDensity",parent,true)
	_commit_settlement_surface(ground_surface, "PersistentPlotGround", parent, true)
	if field_ground_count>0:
		_commit_settlement_surface(field_ground_surface,"PersistentFieldGround",parent,true)
	if roof_count > 0:
		_commit_settlement_surface(roof_surface, "PersistentRoofFabric", parent, lod>=1)
	if wall_count > 0:
		_commit_settlement_surface(wall_surface,"PersistentWallFabric",parent,true)
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
	var architecture:=_settlement_visual_architecture_profile(_settlement_architecture_profile())
	var axiality:=clampf(float(architecture.get("axiality",0.5)),0.0,1.0)
	var civic_space:=clampf(float(architecture.get("civic_space",0.5)),0.0,1.0)
	var permeability:=clampf(float(architecture.get("permeability",0.5)),0.0,1.0)
	for route in routes:
		if not bool(route.get("active", true)):
			continue
		var points: PackedVector2Array = route.get("points", PackedVector2Array())
		if points.size() < 2:
			continue
		var route_kind:=String(route.get("kind","desire_path"))
		var hierarchy:=String(route.get("hierarchy","field_track" if route_kind=="field_track" else ("camp_path" if route_kind=="camp_path" else "path")))
		# Agricultural access is a faint inherited track; inhabited lanes remain
		# readable but no longer turn every outlying field into a map-diagram spoke.
		var minimum_half_width:=0.00034 if route_kind=="field_track" else (0.00014 if route_kind=="camp_path" else 0.00058)
		if hierarchy=="farm_lane": minimum_half_width=0.00058
		elif hierarchy=="lane": minimum_half_width=0.00082
		elif hierarchy=="main_approach": minimum_half_width=0.00128
		var width := maxf(minimum_half_width, float(route.get("width_m", 1.2)) / 2000.0)
		var condition := clampf(float(route.get("condition", 0.5)), 0.0, 1.0)
		var route_color := (Color("#41402e") if route_kind=="field_track" else (Color("#5e5948") if route_kind=="camp_path" else Color("#6f6248"))).lerp(Color("#897654"), condition * 0.24)
		var surface_tier:=clampi(int(route.get("surface_tier",0)),0,5)
		if route_kind!="camp_path" and surface_tier>=3:
			# Drained, paved and engineered roads occupy real width. Keeping a
			# metropolitan route at the founding 1.2 m made a mature network vanish.
			width=maxf(width,[0.0,0.0,0.0,0.00165,0.00235,0.00320][surface_tier])
			if hierarchy=="main_approach": width*=1.34
		if route_kind not in ["camp_path","field_track"]:
			width*=lerpf(0.94,1.08,permeability)
			if hierarchy=="main_approach": width*=lerpf(0.96,1.10,axiality)
		var surface_palette:=[Color("#5f5540"),Color("#746044"),Color("#806b4c"),Color("#766952"),Color("#817d72"),Color("#707477")]
		if route_kind!="camp_path":
			route_color=route_color.lerp(surface_palette[surface_tier],clampf(float(surface_tier)*0.14,0.0,0.66))
		route_color.a = 0.12 if route_kind=="field_track" else (0.19 if route_kind=="camp_path" else 0.18)
		if hierarchy=="farm_lane": route_color.a=0.22
		elif hierarchy=="lane": route_color.a=0.34
		elif hierarchy=="main_approach": route_color=Color("#756347"); route_color.a=0.54
		if hierarchy in ["lane","main_approach"]:
			route_color=route_color.lerp(Color("#94866d"),civic_space*0.10)
		if surface_tier>=3 and route_kind!="camp_path":
			# Roads are the organizing skeleton visible in real aerial imagery. Mature
			# drained/paved routes must survive the close-map LOD instead of becoming
			# fainter precisely when their roof fabric appears.
			route_color.a=maxf(route_color.a,0.52+0.07*float(surface_tier-3))
		if camera!=null and camera.size<=0.42 and route_kind=="camp_path": route_color.a=maxf(route_color.a,0.22)
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
	var nearest:=_local_drainage_distance_at(x,z) if SEAMLESS_WORLD else INF
	var v := z / world_depth + 0.5
	var river_u := _river_u_at_v(v)
	if river_u < 0.0:
		return nearest
	return minf(nearest,absf(x - (river_u - 0.5) * world_width))


func _main_river_distance_at(x:float,z:float)->float:
	if SEAMLESS_WORLD:
		var river_x:=_world_river_x(z)
		return INF if river_x==INF else absf(x-river_x)
	var v:=z/world_depth+0.5
	var river_u:=_river_u_at_v(v)
	return INF if river_u<0.0 else absf(x-(river_u-0.5)*world_width)


func _nearest_tributary_distance_at(position:Vector2)->float:
	if not SEAMLESS_WORLD:
		return INF
	if world_tributary_courses.is_empty():
		world_tributary_courses=_seeded_world_tributaries()
	var nearest:=INF
	for tributary_variant in world_tributary_courses:
		var tributary:Array=tributary_variant
		for point_index in tributary.size()-1:
			var start:Vector3=tributary[point_index]
			var finish:Vector3=tributary[point_index+1]
			var closest:=Geometry2D.get_closest_point_to_segment(position,Vector2(start.x,start.z),Vector2(finish.x,finish.z))
			nearest=minf(nearest,position.distance_to(closest))
	return nearest


func _settlement_surface_assessment(destination:Vector3)->Dictionary:
	var terrain_height:=_height_at(destination.x,destination.z)
	if terrain_height<=SEA_LEVEL+0.02:
		return {"valid":false,"kind":"open_water","reason":"OPEN WATER  •  settlements require dry land"}
	var main_distance:=_main_river_distance_at(destination.x,destination.z)
	if main_distance<=MAIN_RIVER_SETTLEMENT_CLEARANCE_KM:
		return {
			"valid":false,"kind":"river","distance_km":main_distance,
			"reason":"RIVER CHANNEL  •  this point is in the river or its immediate bank  •  choose dry ground at least %.0f m from the channel centre" % (MAIN_RIVER_SETTLEMENT_CLEARANCE_KM*1000.0)
		}
	var tributary_distance:=_nearest_tributary_distance_at(Vector2(destination.x,destination.z))
	if tributary_distance<=TRIBUTARY_SETTLEMENT_CLEARANCE_KM:
		return {
			"valid":false,"kind":"river","distance_km":tributary_distance,
			"reason":"TRIBUTARY CHANNEL  •  this point is in moving water or its immediate bank  •  choose dry ground beyond the bank"
		}
	return {"valid":true,"kind":"land","river_distance_km":minf(main_distance,tributary_distance)}

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
		nearby_resources_label.text = "AUTO  •  %s of %s labor assigned" % [_compact_population(assigned),_compact_population(_able_population())]

func _refresh_age_distribution_meter() -> void:
	if age_distribution_bar==null or age_distribution_summary==null: return
	var profile:=GameState.population_age_profile()
	var bands:Array=profile.bands
	var productive_colors:=[Color("#9b7252"),Color("#779a67"),Color("#5e9d70"),Color("#4f916d"),Color("#6f8f65"),Color("#766d72")]
	for index in mini(age_distribution_segments.size(),bands.size()):
		var segment:=age_distribution_segments[index]
		var band:Dictionary=bands[index]
		var count:=int(band.count)
		var share:=float(band.share)
		var is_working_age:=index>=1 and index<=4
		var labor_status:="PRODUCTIVE-AGE COHORT\nCounts toward the civilization's available labor." if is_working_age else "DEPENDENT COHORT\nSupported by the civilization's available labor."
		segment.tooltip_text="%s • ages %s\n%s\n%d people • %.1f%% of the living population" % [String(band.label).capitalize(),String(band.range),labor_status,count,share*100.0]
		segment.color=productive_colors[index]
		segment.color.a=lerpf(0.78,1.0,clampf(share/0.25,0.0,1.0))
		if index<age_distribution_segment_labels.size():
			age_distribution_segment_labels[index].text="%s\n%s" % [String(band.range),_compact_population(count)]
			age_distribution_segment_labels[index].tooltip_text=segment.tooltip_text
	if age_distribution_title:
		age_distribution_title.text="AGE PROFILE   •   LIFE EXPECTANCY %.1f YEARS" % float(profile.projected_life_expectancy)
		var observed_note:=""
		if int(profile.recorded_deaths)>0:
			observed_note="\nObserved mean age at death: %.1f years across %d recorded deaths." % [float(profile.observed_age_at_death),int(profile.recorded_deaths)]
		age_distribution_title.tooltip_text="Projected at birth under current health, nutrition, shelter, and mortality conditions.%s" % observed_note
	var working_share:=100.0*float(profile.working_age)/maxf(1.0,float(profile.total))
	age_distribution_summary.text="GREEN PRODUCTIVE-AGE %.0f%%   •   DEPENDENCY %d / 100" % [working_share,roundi(float(profile.dependents_per_100_workers))]
	age_distribution_summary.tooltip_text="Green bands are productive-age cohorts (14–59). Warm and grey bands are dependents: children under 14 and elders 60 or older. Median age is %.1f." % float(profile.median_age)

func _settlement_definitions() -> Array[Dictionary]:
	return [
		{"name":"Hearth Circle", "days":6.0, "requires":[], "minimum":{"Construction":3},"materials":{"Timber":6.0,"Fiber Plants":6.0},"requires_water":true,"effect":"anchors the camp and makes communal work possible"},
		{"name":"Lean-to Shelters", "days":9.0, "requires":["Hearth Circle"], "minimum":{"Construction":5},"materials":{"Timber":18.0,"Fiber Plants":12.0},"effect":"protects health and expands shelter"},
		{"name":"Storage Pits", "days":7.0, "requires":["Hearth Circle"], "minimum":{"Construction":4, "Logistics":4},"materials":{"Timber":4.0,"Fiber Plants":3.0},"effect":"slows spoilage and expands food storage"},
		{"name":"Open Work Area", "days":12.0, "requires":["Hearth Circle"], "minimum":{"Construction":6, "Crafting":4},"materials":{"Timber":12.0,"Fiber Plants":5.0},"effect":"improves tools and material work"},
		{"name":"Gathering Yard", "days":10.0, "requires":["Hearth Circle"], "minimum":{"Construction":4, "Extraction":4},"materials":{"Timber":10.0,"Fiber Plants":4.0}, "known_resource":true,"effect":"organizes extraction from known deposits"}
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
	if bool(project.get("requires_water",false)) and not bool(GameState.water_metrics.get("source_accessible",false)):
		return false
	for resource_name in (project.get("materials",{}) as Dictionary):
		if float(GameState.resource_stockpiles.get(resource_name,0.0))<float((project.materials as Dictionary)[resource_name]): return false
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
	var daily_work := (builders / 8.0) * (0.82 + carriers / 30.0 + makers / 50.0)*float(GameState.simulation_metrics.get("labor_efficiency",0.72))*(1.0+DiscoverySystem.effect("construction_rate")+ProgressionSystem.effect("construction_rate"))
	GameState.settlement_projects[project_name] = float(GameState.settlement_projects.get(project_name, 0.0)) + daily_work
	if float(GameState.settlement_projects[project_name]) >= float(project.days):
		for resource_name in (project.get("materials",{}) as Dictionary):
			GameState.resource_stockpiles[resource_name]=maxf(0.0,float(GameState.resource_stockpiles.get(resource_name,0.0))-float((project.materials as Dictionary)[resource_name]))
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
			GameState.housing_capacity+=roundi(90.0*(1.0+DiscoverySystem.effect("housing_output")+ProgressionSystem.effect("housing_output")))
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
	var surface_assessment:=_settlement_surface_assessment(destination)
	if not bool(surface_assessment.get("valid",false)):
		_inspect_location(destination)
		if travel_status_label:
			travel_status_label.text=String(surface_assessment.get("reason","SETTLEMENT SITE BLOCKED"))
		return
	if GameState.settlement_site_committed or hearth_established or "Hearth Circle" in GameState.settlement_completed:
		if settlement_convoy_targeting:
			_begin_settlement_convoy(destination)
			return
		settler_panel.visible = false
		_inspect_location(destination)
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

func _on_settlement_action_pressed()->void:
	if not GameState.settlement_site_committed:
		_start_settlement_here()
		return
	if bool(GameState.settlement_convoy.get("active",false)):
		var position_value:Variant=GameState.settlement_convoy.get("position",Vector2.ZERO)
		var position_2d:Vector2=position_value if position_value is Vector2 else Vector2.ZERO
		_set_camera_target(Vector3(position_2d.x,_height_at(position_2d.x,position_2d.y),position_2d.y))
		return
	if settlement_convoy_targeting:
		_cancel_settlement_convoy_targeting()
	else:
		_enter_settlement_convoy_targeting()

func _toggle_actions_menu()->void:
	if actions_menu_panel==null:
		return
	actions_menu_panel.visible=not actions_menu_panel.visible
	if actions_menu_panel.visible:
		_refresh_actions_menu()

func _close_actions_menu()->void:
	if actions_menu_panel:
		actions_menu_panel.visible=false

func _on_actions_settlement_pressed()->void:
	_close_actions_menu()
	_on_settlement_action_pressed()


func _on_actions_scout_pressed()->void:
	_close_actions_menu()
	_open_scout_dispatch_panel()


func _on_actions_diplomat_pressed()->void:
	_close_actions_menu()
	_open_diplomat_dispatch_panel()


func _refresh_actions_menu()->void:
	if actions_menu_settlement_button==null or actions_menu_status==null:
		return
	actions_menu_settlement_button.disabled=false
	if not GameState.settlement_site_committed:
		var site_assessment:=_settlement_surface_assessment(settler_marker.position) if settler_marker else {"valid":false,"reason":"FOUNDING CONVOY UNAVAILABLE"}
		if bool(site_assessment.get("valid",false)):
			actions_menu_status.text="NEXT  Inspect the current land, then establish the first permanent settlement when ready."
			actions_menu_settlement_button.text="START SETTLEMENT HERE"
			actions_menu_settlement_button.tooltip_text="Halt the founding convoy at its exact current location and establish the first settlement."
		else:
			actions_menu_status.text="BLOCKED  %s" % String(site_assessment.get("reason","Choose dry land."))
			actions_menu_settlement_button.text="CANNOT SETTLE IN WATER"
			actions_menu_settlement_button.tooltip_text="Move the founding convoy onto dry land beyond the visible river bank."
			actions_menu_settlement_button.disabled=true
	elif bool(GameState.settlement_convoy.get("active",false)):
		actions_menu_status.text="IN PROGRESS  A paid founding convoy is physically traveling to its selected site."
		actions_menu_settlement_button.text="FOCUS SETTLEMENT CONVOY"
		actions_menu_settlement_button.tooltip_text="Move the camera to the active settlement convoy."
	elif settlement_convoy_targeting:
		actions_menu_status.text="SITE SELECTION  No people or cargo are committed until you approve the route and cost."
		actions_menu_settlement_button.text="CANCEL SITE SELECTION"
		actions_menu_settlement_button.tooltip_text="Leave destination-selection mode without paying any cost."
	elif "Hearth Circle" not in GameState.settlement_completed:
		actions_menu_status.text="FOUNDING UNDERWAY  Assigned roles are creating the Hearth Circle; the site is already permanent."
		actions_menu_settlement_button.text="FOUNDING SITE COMMITTED"
		actions_menu_settlement_button.disabled=true
		actions_menu_settlement_button.tooltip_text="The first settlement is already committed here. Complete the Hearth Circle before organizing another founding convoy."
	else:
		actions_menu_status.text="Choose one physical map command. New ground, observations, and replies arrive only when people return."
		actions_menu_settlement_button.text="FOUND NEW SETTLEMENT"
		actions_menu_settlement_button.tooltip_text="Enter temporary destination-selection mode. Route and cost are reviewed before anything is committed."
		actions_menu_settlement_button.disabled=false
	if actions_menu_scout_button:
		var exploration:=CivilizationSystem.exploration_status()
		var scout_quote:=CivilizationSystem.scout_mission_quote(30,"open_world") if not bool(exploration.get("active",false)) else {}
		var scout_presentation:=_scout_action_presentation(exploration,scout_quote)
		actions_menu_scout_button.text=String(scout_presentation.label)
		actions_menu_scout_button.disabled=bool(scout_presentation.disabled)
		actions_menu_scout_button.tooltip_text=String(scout_presentation.tooltip)
	if actions_menu_diplomat_button:
		var diplomatic_status:=CivilizationSystem.diplomatic_mission_status()
		var known_destinations:=0
		for encounter_variant in CivilizationSystem.contact_encounters_snapshot():
			if bool((encounter_variant as Dictionary).get("home_location_known",false)): known_destinations+=1
		var diplomatic_presentation:=_diplomat_action_presentation(diplomatic_status,known_destinations)
		actions_menu_diplomat_button.text=String(diplomatic_presentation.label)
		actions_menu_diplomat_button.disabled=bool(diplomatic_presentation.disabled)
		actions_menu_diplomat_button.tooltip_text=String(diplomatic_presentation.tooltip)
	if actions_menu_button:
		var active_count:=int(bool(GameState.settlement_convoy.get("active",false)))+int(bool(CivilizationSystem.exploration_status().get("active",false)))+int(bool(CivilizationSystem.diplomatic_mission_status().get("active",false)))
		actions_menu_button.text="ACTIONS • NEXT" if not GameState.settlement_site_committed else ("ACTIONS • %d" % active_count if active_count>0 else "ACTIONS")
		actions_menu_button.tooltip_text="Open the next founding action." if not GameState.settlement_site_committed else ("Open map actions and review %d active mission%s." % [active_count,"" if active_count==1 else "s"] if active_count>0 else "Open settlement founding, scouting, and diplomatic map actions.")


func _scout_action_presentation(exploration:Dictionary,quote:Dictionary)->Dictionary:
	if bool(exploration.get("active",false)):
		return {
			"label":"REVIEW SCOUT PARTY  •  %d DAYS" % int(exploration.get("days_remaining",0)),
			"disabled":false,
			"tooltip":"IN PROGRESS  The party is away.\nWHY  Its observations remain physically with it.\nNEXT  Review personnel, issued provisions, risk, and return time."
		}
	if bool(quote.get("can_dispatch",false)):
		return {
			"label":"SEND SCOUT PARTY",
			"disabled":false,
			"tooltip":"ACTION  Choose a 30, 90, 180, or 365-day aggregate scouting mission.\nRESULT  Charted ground and encounters become knowledge only if the party returns."
		}
	var blocker:=String(quote.get("blocker",quote.get("error","No viable scout mission is available.")))
	var next:="Open FOOD and rebuild the minimum travel issue." if "Food" in blocker or "stored" in blocker else ("Increase the available population before dispatching a party." if "population" in blocker else "Review the scout mission to choose a reachable target or longer duration.")
	var short_reason:="NEEDS FOOD" if "Food" in blocker or "stored" in blocker else ("NEEDS AVAILABLE PEOPLE" if "population" in blocker else ("TARGET OUT OF RANGE" if "reach" in blocker or "away" in blocker else "REQUIREMENTS NOT MET"))
	return {
		"label":"SEND SCOUT PARTY  •  BLOCKED\n%s" % short_reason,
		"disabled":true,
		"tooltip":"BLOCKED  %s\nNEXT  %s" % [blocker,next]
	}


func _diplomat_action_presentation(status:Dictionary,known_destinations:int)->Dictionary:
	if bool(status.get("active",false)):
		return {
			"label":"REVIEW DIPLOMATS  •  %d DAYS" % int(status.get("days_remaining",0)),
			"disabled":false,
			"tooltip":"IN PROGRESS  Envoys are physically away.\nWHY  Their response and observations travel with them.\nNEXT  Review the destination, cargo, stage, and return time."
		}
	if known_destinations<=0:
		return {
			"label":"SEND DIPLOMATS  •  BLOCKED\nLOCATE A FOREIGN SETTLEMENT FIRST",
			"disabled":true,
			"tooltip":"BLOCKED  No foreign settlement has been physically located.\nWHY  An encounter site is not a diplomatic destination.\nNEXT  Send scouts to investigate a returned contact site."
		}
	return {
		"label":"SEND DIPLOMATS",
		"disabled":false,
		"tooltip":"ACTION  Send a physical delegation to one confirmed foreign settlement.\nRESULT  Its proposal, response, route, and observations travel at the speed of the envoys."
	}

func _enter_settlement_convoy_targeting()->void:
	settlement_convoy_targeting=true
	settlement_convoy_hover_valid=false
	_set_resource_view_enabled(true)
	if lens_panel: lens_panel.visible=false
	if map_help_panel: map_help_panel.visible=false
	_ensure_settlement_convoy_preview()
	if settlement_convoy_instruction_panel: settlement_convoy_instruction_panel.visible=true
	_set_settlement_convoy_feedback("MOVE OVER THE MAP  •  LEFT-CLICK CHARTED LAND TO REVIEW ROUTE + COST  •  RIGHT-CLICK OR ESC CANCELS",Color("#ead078"))
	_update_time_interface()

func _cancel_settlement_convoy_targeting()->void:
	settlement_convoy_targeting=false
	settlement_convoy_hover_valid=false
	if settlement_convoy_preview:
		settlement_convoy_preview.queue_free()
		settlement_convoy_preview=null
	settlement_convoy_preview_material=null
	if settlement_convoy_instruction_panel: settlement_convoy_instruction_panel.visible=false
	if lens_panel: lens_panel.visible=lens_requested_visible
	if map_help_panel and not map_help_dismissed and not capture_render_active: map_help_panel.visible=true
	_refresh_map_help()
	_update_time_interface()
	if travel_status_label: travel_status_label.text="NEW-SETTLEMENT SITE SELECTION CANCELLED  •  no people or cargo were committed"

func _ensure_settlement_convoy_preview()->void:
	if settlement_convoy_preview and is_instance_valid(settlement_convoy_preview): return
	settlement_convoy_preview=MeshInstance3D.new()
	settlement_convoy_preview.name="SettlementConvoySitePreview"
	var mesh:=CylinderMesh.new()
	mesh.top_radius=1.0
	mesh.bottom_radius=1.0
	mesh.height=0.06
	mesh.radial_segments=48
	settlement_convoy_preview.mesh=mesh
	settlement_convoy_preview_material=StandardMaterial3D.new()
	settlement_convoy_preview_material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	settlement_convoy_preview_material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	settlement_convoy_preview_material.no_depth_test=true
	settlement_convoy_preview_material.albedo_color=Color(0.32,0.82,0.62,0.48)
	settlement_convoy_preview.material_override=settlement_convoy_preview_material
	settlement_convoy_preview.visible=false
	add_child(settlement_convoy_preview)

func _set_settlement_convoy_feedback(message:String,color:Color)->void:
	if settlement_convoy_instruction_label:
		settlement_convoy_instruction_label.text=message
		settlement_convoy_instruction_label.add_theme_color_override("font_color",color)

func _settlement_convoy_site_assessment(destination:Vector3)->Dictionary:
	var surface_assessment:=_settlement_surface_assessment(destination)
	if not bool(surface_assessment.get("valid",false)):
		return surface_assessment
	if not _world_position_is_revealed(destination):
		return {"valid":false,"reason":"UNCHARTED LAND  •  a scout must return with this ground before a convoy can use it"}
	var network:Dictionary=_settlement_model().settlement_network_snapshot()
	var settlements:Array=network.get("settlements",[])
	if settlements.is_empty():
		return {"valid":false,"reason":"NO ESTABLISHED ORIGIN  •  complete the first settlement before founding another"}
	var destination_2d:=Vector2(destination.x,destination.z)
	var origin:Dictionary={}
	var origin_distance:=INF
	for settlement_variant in settlements:
		var settlement:Dictionary=settlement_variant
		var position_value:Variant=settlement.get("position",Vector2.ZERO)
		var center:Vector2=position_value if position_value is Vector2 else Vector2.ZERO
		var distance:=center.distance_to(destination_2d)
		if distance<origin_distance:
			origin_distance=distance
			origin=settlement
	var origin_clearance:=maxf(2.0,float(origin.get("claim_radius_km",0.0))+0.75)
	if origin_distance<origin_clearance:
		return {"valid":false,"reason":"TOO CLOSE TO %s  •  choose land at least %.1f km from its centre" % [String(origin.get("name","THE ORIGIN")).to_upper(),origin_clearance]}
	for existing_variant in settlements:
		var existing:Dictionary=existing_variant
		var existing_position_value:Variant=existing.get("position",Vector2.ZERO)
		var existing_center:Vector2=existing_position_value if existing_position_value is Vector2 else Vector2.ZERO
		var required_clearance:=maxf(1.2,float(existing.get("claim_radius_km",0.0))+0.55)
		if destination_2d.distance_to(existing_center)<required_clearance:
			return {"valid":false,"reason":"INSIDE %s'S PRESENT TERRITORY  •  choose land at least %.1f km from its centre" % [String(existing.get("name","A SETTLEMENT")).to_upper(),required_clearance]}
	return {
		"valid":true,"origin":origin,"distance_km":origin_distance,
		"reason":"CHARTED LAND  •  %.1f km from %s  •  LEFT-CLICK TO REVIEW ROUTE + COST" % [origin_distance,String(origin.get("name","THE NEAREST SETTLEMENT")).to_upper()]
	}

func _update_settlement_convoy_preview(screen_position:Vector2)->void:
	if not settlement_convoy_targeting: return
	_ensure_settlement_convoy_preview()
	var hit:=_terrain_hit(screen_position)
	if hit.is_empty():
		settlement_convoy_hover_valid=false
		settlement_convoy_preview.visible=false
		_set_settlement_convoy_feedback("POINTER IS OFF THE MAP  •  move onto visible terrain",Color("#d48672"))
		return
	settlement_convoy_hover_position=hit.position+Vector3.UP*0.006
	var assessment:=_settlement_convoy_site_assessment(settlement_convoy_hover_position)
	settlement_convoy_hover_valid=bool(assessment.get("valid",false))
	settlement_convoy_preview.visible=true
	settlement_convoy_preview.position=settlement_convoy_hover_position
	var viewport_height:=maxf(1.0,get_viewport().get_visible_rect().size.y)
	var preview_radius:=clampf(camera.size/viewport_height*24.0,0.28,220.0)
	settlement_convoy_preview.scale=Vector3(preview_radius,1.0,preview_radius)
	var color:=Color(0.30,0.84,0.59,0.52) if settlement_convoy_hover_valid else Color(0.92,0.30,0.23,0.55)
	settlement_convoy_preview_material.albedo_color=color
	_set_settlement_convoy_feedback(String(assessment.get("reason","Choose another point.")),Color("#b9dda7") if settlement_convoy_hover_valid else Color("#e08b77"))

func _select_settlement_convoy_site(screen_position:Vector2)->void:
	_update_settlement_convoy_preview(screen_position)
	if not settlement_convoy_hover_valid:
		if travel_status_label: travel_status_label.text="SITE NOT SELECTED  •  read the reason above the placement button"
		return
	_begin_settlement_convoy(settlement_convoy_hover_position)

func _begin_settlement_convoy(destination:Vector3)->void:
	var assessment:=_settlement_convoy_site_assessment(destination)
	if not bool(assessment.get("valid",false)):
		_set_settlement_convoy_feedback(String(assessment.get("reason","SITE NOT VALID")),Color("#e08b77"))
		return
	var origin:Dictionary=assessment.get("origin",{})
	var destination_2d:=Vector2(destination.x,destination.z)
	if origin.is_empty():
		_set_settlement_convoy_feedback("NO ESTABLISHED ORIGIN  •  the first settlement must be completed",Color("#e08b77"))
		return
	var origin_2d:Vector2=origin.get("position",Vector2.ZERO)
	var origin_3d:=Vector3(origin_2d.x,_height_at(origin_2d.x,origin_2d.y)+0.002,origin_2d.y)
	var route:=_analyze_convoy_route(origin_3d,destination)
	if not bool(route.get("valid",false)):
		_set_settlement_convoy_feedback(String(route.get("reason","ROUTE BLOCKED")),Color("#e08b77"))
		if settlement_convoy_preview_material: settlement_convoy_preview_material.albedo_color=Color(0.92,0.30,0.23,0.55)
		return
	var duration:=maxf(0.5,float(route.distance_km)/(CONVOY_KM_PER_DAY*float(route.terrain_modifier)))
	var quote:Dictionary=_settlement_model().settlement_convoy_quote(destination_2d,duration)
	_open_settlement_convoy_confirmation(destination,route,quote)

func _open_settlement_convoy_confirmation(destination:Vector3,route:Dictionary,quote:Dictionary)->void:
	if settlement_convoy_confirm_panel and is_instance_valid(settlement_convoy_confirm_panel): return
	var site_assessment:=_settlement_convoy_site_assessment(destination)
	if not bool(site_assessment.get("valid",false)):
		_set_settlement_convoy_feedback(String(site_assessment.get("reason","SITE NOT VALID")),Color("#e08b77"))
		return
	settlement_convoy_pending_destination=destination
	settlement_convoy_pending_route=route.duplicate(true)
	settlement_convoy_pending_quote=quote.duplicate(true)
	settlement_convoy_confirmation_previous_speed=game_speed
	_set_game_speed(0.0)
	settlement_convoy_confirm_panel=Control.new()
	settlement_convoy_confirm_panel.name="SettlementConvoyConfirmation"
	settlement_convoy_confirm_panel.size=get_viewport().get_visible_rect().size
	settlement_convoy_confirm_panel.mouse_filter=Control.MOUSE_FILTER_STOP
	interface_layer.add_child(settlement_convoy_confirm_panel)
	var dimmer:=ColorRect.new()
	dimmer.size=settlement_convoy_confirm_panel.size
	dimmer.color=Color(0.006,0.010,0.011,0.90)
	settlement_convoy_confirm_panel.add_child(dimmer)
	var modal:=PanelContainer.new()
	modal.size=Vector2(minf(650.0,settlement_convoy_confirm_panel.size.x-48.0),minf(470.0,settlement_convoy_confirm_panel.size.y-48.0))
	modal.position=(settlement_convoy_confirm_panel.size-modal.size)*0.5
	modal.add_theme_stylebox_override("panel",_knowledge_style(Color("#0a1213"),Color("#a58b55"),1,4,24))
	settlement_convoy_confirm_panel.add_child(modal)
	var root:=VBoxContainer.new()
	root.add_theme_constant_override("separation",10)
	modal.add_child(root)
	var eyebrow:=Label.new()
	eyebrow.text="NEW SETTLEMENT • CONVOY QUOTE"
	eyebrow.add_theme_font_size_override("font_size",11)
	eyebrow.add_theme_color_override("font_color",Color("#c8af6c"))
	root.add_child(eyebrow)
	var title:=Label.new()
	title.text="Review before anyone leaves"
	title.add_theme_font_size_override("font_size",24)
	title.add_theme_color_override("font_color",Color("#eee2cc"))
	root.add_child(title)
	var explanation:=Label.new()
	explanation.text="Nothing has been spent. Sending commits one aggregate founding party and its stores; people are never created as individual runtime entities."
	explanation.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	explanation.add_theme_font_size_override("font_size",12)
	explanation.add_theme_color_override("font_color",Color("#aeb4ae"))
	explanation.custom_minimum_size=Vector2(0,42)
	root.add_child(explanation)
	root.add_child(HSeparator.new())
	var origin_name:=String(quote.get("origin_name","NEAREST SETTLEMENT")).to_upper()
	var distance_km:=float(route.get("distance_km",quote.get("distance_km",0.0)))
	var duration_days:=float(quote.get("duration_days",0.0))
	var details:=Label.new()
	details.text="FROM  %s\nDESTINATION  CHARTED LAND • %.1f km away\nTRAVEL  %s\nFOUNDING PARTY  %s aggregate residents\nTRAVEL RATIONS  %s\nMATERIALS  %.1f Timber • %.1f Fiber Plants" % [origin_name,distance_km,_format_game_duration(duration_days),_compact_population(int(quote.get("population",0))),_compact_population(roundi(float(quote.get("food",0.0)))),float(quote.get("timber",0.0)),float(quote.get("fiber",0.0))]
	details.add_theme_font_size_override("font_size",14)
	details.add_theme_color_override("font_color",Color("#ded5c0"))
	details.custom_minimum_size=Vector2(0,150)
	root.add_child(details)
	settlement_convoy_confirm_status=Label.new()
	var ready:=bool(quote.get("ok",false))
	settlement_convoy_confirm_status.text="READY  •  route and provisions can support this convoy" if ready else "CANNOT SEND  •  %s" % String(quote.get("reason","requirements are not met"))
	settlement_convoy_confirm_status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	settlement_convoy_confirm_status.add_theme_font_size_override("font_size",12)
	settlement_convoy_confirm_status.add_theme_color_override("font_color",Color("#9dcc94") if ready else Color("#e08b77"))
	settlement_convoy_confirm_status.custom_minimum_size=Vector2(0,38)
	root.add_child(settlement_convoy_confirm_status)
	var footer:=HBoxContainer.new()
	footer.alignment=BoxContainer.ALIGNMENT_END
	footer.add_theme_constant_override("separation",10)
	root.add_child(footer)
	var choose_again:=Button.new()
	choose_again.text="CHOOSE DIFFERENT LAND"
	choose_again.custom_minimum_size=Vector2(210,42)
	choose_again.pressed.connect(_dismiss_settlement_convoy_confirmation)
	footer.add_child(choose_again)
	settlement_convoy_confirm_button=Button.new()
	settlement_convoy_confirm_button.text="SEND FOUNDING CONVOY"
	settlement_convoy_confirm_button.custom_minimum_size=Vector2(210,42)
	settlement_convoy_confirm_button.disabled=not ready
	settlement_convoy_confirm_button.pressed.connect(_confirm_settlement_convoy)
	footer.add_child(settlement_convoy_confirm_button)

func _dismiss_settlement_convoy_confirmation()->void:
	if settlement_convoy_confirm_panel and is_instance_valid(settlement_convoy_confirm_panel): settlement_convoy_confirm_panel.queue_free()
	settlement_convoy_confirm_panel=null
	settlement_convoy_confirm_status=null
	settlement_convoy_confirm_button=null
	settlement_convoy_pending_route={}
	settlement_convoy_pending_quote={}
	_set_game_speed(settlement_convoy_confirmation_previous_speed)
	if settlement_convoy_targeting:
		_set_settlement_convoy_feedback("MOVE OVER THE MAP  •  LEFT-CLICK CHARTED LAND TO REVIEW ROUTE + COST  •  RIGHT-CLICK OR ESC CANCELS",Color("#ead078"))

func _confirm_settlement_convoy()->void:
	var destination:=settlement_convoy_pending_destination
	var site_assessment:=_settlement_convoy_site_assessment(destination)
	if not bool(site_assessment.get("valid",false)):
		if settlement_convoy_confirm_status:
			settlement_convoy_confirm_status.text="CANNOT SEND  •  %s" % String(site_assessment.get("reason","the destination is no longer viable"))
			settlement_convoy_confirm_status.add_theme_color_override("font_color",Color("#e08b77"))
		if settlement_convoy_confirm_button: settlement_convoy_confirm_button.disabled=true
		return
	var quote:=settlement_convoy_pending_quote.duplicate(true)
	var started:Dictionary=_settlement_model().begin_settlement_convoy(Vector2(destination.x,destination.z),float(quote.get("duration_days",0.5)))
	if not bool(started.get("ok",false)):
		if settlement_convoy_confirm_status:
			settlement_convoy_confirm_status.text="CANNOT SEND  •  %s" % String(started.get("reason","the available provisions changed"))
			settlement_convoy_confirm_status.add_theme_color_override("font_color",Color("#e08b77"))
		if settlement_convoy_confirm_button: settlement_convoy_confirm_button.disabled=true
		return
	var origin_2d:Vector2=started.get("origin",Vector2.ZERO)
	var origin_3d:=Vector3(origin_2d.x,_height_at(origin_2d.x,origin_2d.y)+0.002,origin_2d.y)
	_dismiss_settlement_convoy_confirmation()
	settlement_convoy_targeting=false
	settlement_convoy_hover_valid=false
	if settlement_convoy_preview:
		settlement_convoy_preview.queue_free()
		settlement_convoy_preview=null
	settlement_convoy_preview_material=null
	if settlement_convoy_instruction_panel: settlement_convoy_instruction_panel.visible=false
	_draw_route(origin_3d,destination)
	var event:={
		"id":"settlement_convoy_%d" % int(GameState.elapsed_days*24.0),"day":int(GameState.elapsed_days),
		"title":"New Settlement Convoy Departed",
		"description":"%s people left %s with %.0f travel rations, %.1f Timber, and %.1f Fiber Plants for a %.1f km journey. The population remains aggregate; one convoy record represents the entire mission." % [_compact_population(int(started.population)),String(started.origin_name),float(started.food),float(started.timber),float(started.fiber),float(started.distance_km)],
		"domain":"settlement","severity":"major"
	}
	GameState.simulation_events.push_front(event)
	if GameState.simulation_events.size()>80: GameState.simulation_events.resize(80)
	_refresh_settlement_convoy_marker()
	_refresh_settlement_network(true)
	_update_time_interface()

func _process_settlement_convoy()->void:
	if not bool(GameState.settlement_convoy.get("active",false)): return
	var convoy:Dictionary=GameState.settlement_convoy
	# The route origin remains fixed while the aggregate convoy position advances.
	var origin:Vector2=convoy.get("origin",convoy.get("position",Vector2.ZERO))
	var destination:Vector2=convoy.get("destination",origin)
	var duration:=maxf(0.5,float(convoy.get("duration_days",0.5)))
	var progress:=clampf((GameState.elapsed_days-float(convoy.get("depart_day",GameState.elapsed_days)))/duration,0.0,1.0)
	var position:=origin.lerp(destination,progress)
	_settlement_model().update_settlement_convoy(position,progress)
	_refresh_settlement_convoy_marker()
	if progress<1.0: return
	var completed:Dictionary=_settlement_model().complete_settlement_convoy(destination)
	if route_mesh: route_mesh.visible=false
	_refresh_settlement_convoy_marker()
	_refresh_settlement_network(true)
	if bool(completed.get("ok",false)):
		var settlement:Dictionary=completed.settlement
		var event:={
			"id":"settlement_founded_%d" % int(GameState.elapsed_days*24.0),"day":int(GameState.elapsed_days),
			"title":"New Settlement Seeded",
			"description":"%s arrived and established %s. Its aggregate population, territory, and future growth now remain part of the same civilization totals." % [_compact_population(int(completed.population)),String(settlement.get("name","the new settlement"))],
			"domain":"settlement","severity":"major"
		}
		GameState.simulation_events.push_front(event)
		if GameState.simulation_events.size()>80: GameState.simulation_events.resize(80)
		_set_camera_target(Vector3(destination.x,_height_at(destination.x,destination.y),destination.y))
	_update_time_interface()

func _start_settlement_here() -> void:
	if GameState.settlement_site_committed or settler_marker == null:
		return
	var site_assessment:=_settlement_surface_assessment(settler_marker.position)
	if not bool(site_assessment.get("valid",false)):
		if travel_status_label:
			travel_status_label.text="SETTLEMENT NOT STARTED  •  %s" % String(site_assessment.get("reason","choose dry land"))
		_refresh_actions_menu()
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
	_retire_founding_expedition_visuals()
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

func _retire_founding_expedition_visuals()->void:
	# A committed site is no longer a convoy. Retire every expedition-only primitive
	# immediately instead of waiting for the next camera LOD tick; the persistent
	# settlement fabric and stage-aware map symbol replace them as they emerge.
	if settler_map_ring: settler_map_ring.visible=false
	if convoy_map_icon: convoy_map_icon.visible=false
	if convoy_map_label: convoy_map_label.visible=false
	if convoy_detail_root: convoy_detail_root.visible=false

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

func _on_diplomatic_event(event:Dictionary)->void:
	if String(event.get("kind","")) not in ["unit_sighting","first_contact"]: return
	var event_key:="%s::%s::%d" % [String(event.get("kind","")),String(event.get("formation_id",event.get("civ_id",""))),int(event.get("day",0))]
	if String(active_foreign_alert.get("alert_key",""))==event_key: return
	for queued in foreign_alert_queue:
		if String(queued.get("alert_key",""))==event_key: return
	var alert:=event.duplicate(true)
	alert["alert_key"]=event_key
	alert["group_count"]=1
	if String(alert.get("kind",""))=="unit_sighting":
		if not active_foreign_alert.is_empty() and String(active_foreign_alert.get("kind",""))=="unit_sighting" and int(active_foreign_alert.get("day",-1))==int(alert.get("day",-2)):
			active_foreign_alert=_merge_foreign_sighting_alert(active_foreign_alert,alert)
			_render_active_foreign_alert()
			return
		for queued_index in foreign_alert_queue.size():
			var queued_alert:Dictionary=foreign_alert_queue[queued_index]
			if String(queued_alert.get("kind",""))=="unit_sighting" and int(queued_alert.get("day",-1))==int(alert.get("day",-2)):
				foreign_alert_queue[queued_index]=_merge_foreign_sighting_alert(queued_alert,alert)
				return
	foreign_alert_queue.append(alert)
	if foreign_alert_queue.size()>4: foreign_alert_queue.pop_front()
	_present_next_foreign_alert()


func _merge_foreign_sighting_alert(existing:Dictionary,incoming:Dictionary)->Dictionary:
	var merged:=existing.duplicate(true)
	merged["group_count"]=int(merged.get("group_count",1))+1
	var descriptions:Array=merged.get("group_descriptions",[])
	if descriptions.is_empty(): descriptions.append(String(existing.get("description","A foreign formation was observed.")))
	if descriptions.size()<3: descriptions.append(String(incoming.get("description","Another foreign formation was observed.")))
	merged["group_descriptions"]=descriptions
	return merged


func _render_active_foreign_alert()->void:
	if foreign_alert_panel==null or active_foreign_alert.is_empty(): return
	var first_contact:=String(active_foreign_alert.get("kind",""))=="first_contact"
	var group_count:=int(active_foreign_alert.get("group_count",1))
	foreign_alert_title.text=(("FIRST CONTACT" if first_contact else "FOREIGN UNIT SIGHTED") if group_count<=1 else "%d FOREIGN UNITS SIGHTED" % group_count)+"  •  DAY %d" % (int(active_foreign_alert.get("day",0))+1)
	if group_count<=1:
		var full_description:=String(active_foreign_alert.get("description","A foreign formation was observed."))
		foreign_alert_body.text="%s\n%s" % [String(active_foreign_alert.get("title","Foreign observation")).to_upper(),_bounded_alert_copy(full_description)]
		foreign_alert_body.tooltip_text=full_description
	else:
		var descriptions:Array=active_foreign_alert.get("group_descriptions",[])
		var first_description:=String(descriptions[0]) if not descriptions.is_empty() else String(active_foreign_alert.get("description","Foreign formations were observed."))
		foreign_alert_body.text="MULTIPLE LOCAL OBSERVATIONS\n%s\n%d formations share this alert; open World for the sighting list." % [_bounded_alert_copy(first_description,170),group_count]
		foreign_alert_body.tooltip_text="\n\n".join(descriptions) if not descriptions.is_empty() else first_description
	foreign_alert_panel.add_theme_stylebox_override("panel",_population_report_style(Color("#d5a54f") if first_contact else Color("#c77a56")))
	if foreign_alert_world_button:
		foreign_alert_world_button.visible=String(active_foreign_alert.get("civ_id",""))!="" or group_count>1
	foreign_alert_world_button.tooltip_text="Open the known world report and bounded local sighting list. Unidentified formations remain unnamed." if group_count>1 else "Open the known diplomatic record for this identified civilization."
	_clamp_foreign_alert_to_viewport()
	foreign_alert_panel.visible=not _blocking_modal_or_report_open()


func _bounded_alert_copy(value:String,limit:int=260)->String:
	var compact:=" ".join(value.replace("\r"," ").replace("\n"," ").split(" ",false))
	if compact.length()<=limit: return compact
	return compact.left(maxi(1,limit-1)).strip_edges()+"…"


func _present_next_foreign_alert()->void:
	if foreign_alert_panel==null or _blocking_modal_or_report_open() or (not active_foreign_alert.is_empty()) or foreign_alert_queue.is_empty(): return
	active_foreign_alert=foreign_alert_queue.pop_front()
	_render_active_foreign_alert()


func _arbitrate_notification_overlays()->void:
	_sync_map_help_overlay_visibility()
	if foreign_alert_panel==null: return
	if _blocking_modal_or_report_open():
		foreign_alert_panel.visible=false
		return
	if not active_foreign_alert.is_empty():
		if not foreign_alert_panel.visible: _render_active_foreign_alert()
		return
	_present_next_foreign_alert()


func _blocking_modal_or_report_open()->bool:
	for overlay in [settlement_naming_panel,settlement_convoy_confirm_panel,scout_dispatch_panel,diplomat_dispatch_panel,founding_focus_panel,world_menu_panel,settlement_dashboard_panel,systems_hub_panel,provisions_panel,materials_panel,knowledge_panel,council_panel,government_panel,population_ledger_panel,society_panel,progression_panel,civilizations_panel]:
		if overlay and is_instance_valid(overlay) and overlay.is_visible_in_tree(): return true
	if leader_panel and is_instance_valid(leader_panel) and leader_panel.visible: return true
	if MilitaryCommandUI and MilitaryCommandUI.modal and MilitaryCommandUI.modal.visible: return true
	return false


func _clamp_foreign_alert_to_viewport()->void:
	if foreign_alert_panel==null: return
	var viewport_size:=get_viewport().get_visible_rect().size
	foreign_alert_panel.size=Vector2(minf(362.0,maxf(280.0,viewport_size.x-24.0)),minf(188.0,maxf(150.0,viewport_size.y-24.0)))
	foreign_alert_panel.position=Vector2(clampf(viewport_size.x-foreign_alert_panel.size.x-16.0,12.0,maxf(12.0,viewport_size.x-foreign_alert_panel.size.x-12.0)),clampf(84.0,12.0,maxf(12.0,viewport_size.y-foreign_alert_panel.size.y-12.0)))


func _finish_active_foreign_alert()->void:
	active_foreign_alert={}
	if foreign_alert_panel: foreign_alert_panel.visible=false
	_present_next_foreign_alert.call_deferred()


func _center_active_foreign_alert()->void:
	var position_data:Variant=active_foreign_alert.get("position",{})
	if position_data is Dictionary and position_data.has("x") and position_data.has("z"):
		var target:=Vector3(float(position_data.x),0.0,float(position_data.z))
		if camera: camera.size=minf(camera.size,58.0)
		_set_camera_target(target)
		_inspect_location(target)
	_finish_active_foreign_alert()


func _open_active_foreign_alert_world()->void:
	var civ_id:=String(active_foreign_alert.get("civ_id",""))
	var grouped:=int(active_foreign_alert.get("group_count",1))>1
	_finish_active_foreign_alert()
	if civ_id!="": selected_civilization_id=civ_id
	elif not grouped: return
	selected_civilization_region_id=""
	_open_civilizations_panel()


func _dismiss_active_foreign_alert()->void:
	_finish_active_foreign_alert()


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

func _schedule_modal_screen_contract(node:Node)->void:
	if node is Control: _apply_modal_screen_contract.call_deferred(node as Control)


func _apply_modal_screen_contract(screen:Control)->void:
	if screen==null or not is_instance_valid(screen): return
	# This contract is also exercised on detached screens by the presentation
	# tests, so do not assume either the renderer or the candidate has entered a
	# SceneTree yet.
	var viewport:=get_viewport()
	var viewport_size:=viewport.get_visible_rect().size if viewport!=null else screen.size
	if viewport_size.x<=0.0 or viewport_size.y<=0.0:
		viewport_size=Vector2(1920,1080)
	# Ignore the map HUD. Blocking reports cover almost the complete viewport.
	if screen.size.x<viewport_size.x*0.72 or screen.size.y<viewport_size.y*0.72: return
	if not screen.has_meta("modal_screen_contract"):
		var compact_theme:=Theme.new()
		compact_theme.default_font_size=11
		screen.theme=compact_theme
		screen.set_meta("modal_screen_contract",true)
	_compact_modal_descendants(screen)
	# Direct modal frames always retain a safe clickable margin even when the OS
	# reports a smaller work area than the project's reference viewport.
	for child in screen.get_children():
		if not child is PanelContainer: continue
		var modal:=child as PanelContainer
		_ensure_modal_fit_host(modal)
		_fit_modal_frame_to_viewport.call_deferred(modal,viewport_size)


func _fit_modal_frame_to_viewport(modal:PanelContainer,viewport_size:Vector2)->void:
	if modal==null or not is_instance_valid(modal): return
	var maximum:=viewport_size-Vector2(24,24)
	modal.size=Vector2(minf(modal.size.x,maximum.x),minf(modal.size.y,maximum.y))
	modal.position=(viewport_size-modal.size)*0.5


func _ensure_modal_fit_host(modal:PanelContainer)->void:
	if modal.has_meta("viewport_fit_hosted") or modal.get_child_count()!=1: return
	var content:=modal.get_child(0) as Control
	if content==null or content.get_script()==FIT_CONTENT_PANEL: return
	modal.remove_child(content)
	var fit_host:=FIT_CONTENT_PANEL.new()
	fit_host.name="ViewportFitHost"
	# The outer frame preserves the screen hierarchy. Long inner lists paginate
	# themselves; the header, primary action, and close button never become pages.
	fit_host.allow_pagination=false
	fit_host.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	fit_host.size_flags_vertical=Control.SIZE_EXPAND_FILL
	modal.add_child(fit_host)
	fit_host.add_child(content)
	modal.set_meta("viewport_fit_hosted",true)


func _compact_modal_descendants(root:Node)->void:
	for child in root.get_children():
		if child is Control:
			var control:=child as Control
			var cap:=22 if child is Label else 12
			var current:=control.get_theme_font_size("font_size")
			if current>cap: control.add_theme_font_size_override("font_size",cap)
		_compact_modal_descendants(child)


func _build_interface() -> void:
	var layer := CanvasLayer.new()
	interface_layer = layer
	add_child(layer)
	# Every full-screen destination added to this layer receives the same compact
	# viewport contract. Builders may still choose their own visual hierarchy, but
	# none may silently grow past 1280×720 or fall back to page scrolling.
	layer.child_entered_tree.connect(_schedule_modal_screen_contract)
	var viewport_width := get_viewport().get_visible_rect().size.x
	# The Command Rail shell replaces the legacy 46px top bar: navigation now
	# lives in the left rail, time/speed in the top-center pill, and status
	# numbers in the top-right KPI strip.
	event_report_button=Button.new()
	event_report_button.position=Vector2(18,105)
	event_report_button.size=Vector2(400,58)
	event_report_button.alignment=HORIZONTAL_ALIGNMENT_LEFT
	event_report_button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	event_report_button.add_theme_font_size_override("font_size",11)
	event_report_button.add_theme_color_override("font_color",Color("#eadfca"))
	event_report_button.tooltip_text="Open the full population and consequence ledger."
	event_report_button.pressed.connect(func()->void:
		if hud: hud.open_detail(preload("res://scripts/hud/content/dock_detail_population_ledger.gd").new(self,hud)))
	event_report_button.visible=false
	layer.add_child(event_report_button)
	travel_status_label = Label.new()
	travel_status_label.position = Vector2(viewport_width * 0.5 - 390, 66)
	travel_status_label.size = Vector2(780, 20)
	travel_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	travel_status_label.add_theme_font_size_override("font_size", 10)
	travel_status_label.add_theme_color_override("font_color", Color("#ead078"))
	layer.add_child(travel_status_label)
	_build_map_help(layer)
	travel_council_notice=Button.new()
	travel_council_notice.position=Vector2(maxf(500.0,viewport_width-890.0),84)
	travel_council_notice.size=Vector2(390,140)
	travel_council_notice.alignment=HORIZONTAL_ALIGNMENT_LEFT
	travel_council_notice.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	travel_council_notice.add_theme_font_size_override("font_size",12)
	travel_council_notice.add_theme_color_override("font_color",Color("#eadfc8"))
	travel_council_notice.tooltip_text="Open the full council record."
	travel_council_notice.pressed.connect(func()->void: _on_hud_section_requested("civ",2))
	travel_council_notice.visible=false
	layer.add_child(travel_council_notice)
	foreign_alert_panel=PanelContainer.new()
	foreign_alert_panel.name="ForeignObservationAlert"
	foreign_alert_panel.position=Vector2(maxf(12.0,viewport_width-378.0),84)
	foreign_alert_panel.size=Vector2(362,188)
	foreign_alert_panel.custom_minimum_size=Vector2.ZERO
	foreign_alert_panel.clip_contents=true
	foreign_alert_panel.z_index=80
	foreign_alert_panel.add_theme_stylebox_override("panel",_population_report_style(Color("#c77a56")))
	var alert_root:=VBoxContainer.new()
	alert_root.add_theme_constant_override("separation",7)
	foreign_alert_panel.add_child(alert_root)
	foreign_alert_title=Label.new()
	foreign_alert_title.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	foreign_alert_title.add_theme_font_size_override("font_size",15)
	foreign_alert_title.add_theme_color_override("font_color",Color("#f0d49d"))
	alert_root.add_child(foreign_alert_title)
	foreign_alert_body=Label.new()
	foreign_alert_body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	foreign_alert_body.custom_minimum_size=Vector2(0,64)
	foreign_alert_body.size_flags_vertical=Control.SIZE_EXPAND_FILL
	foreign_alert_body.max_lines_visible=5
	foreign_alert_body.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	foreign_alert_body.clip_text=true
	foreign_alert_body.add_theme_font_size_override("font_size",11)
	foreign_alert_body.add_theme_color_override("font_color",Color("#ddd4c3"))
	alert_root.add_child(foreign_alert_body)
	var alert_actions:=HBoxContainer.new()
	alert_actions.add_theme_constant_override("separation",5)
	alert_root.add_child(alert_actions)
	var center_alert:=Button.new()
	center_alert.text="SHOW MAP"
	center_alert.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	center_alert.add_theme_font_size_override("font_size",9)
	center_alert.tooltip_text="Move the camera to the exact observed or reported encounter position."
	center_alert.pressed.connect(_center_active_foreign_alert)
	alert_actions.add_child(center_alert)
	foreign_alert_world_button=Button.new()
	foreign_alert_world_button.text="OPEN WORLD"
	foreign_alert_world_button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	foreign_alert_world_button.add_theme_font_size_override("font_size",9)
	foreign_alert_world_button.tooltip_text="Open the known diplomatic record for an identified civilization."
	foreign_alert_world_button.pressed.connect(_open_active_foreign_alert_world)
	alert_actions.add_child(foreign_alert_world_button)
	var dismiss_alert:=Button.new()
	dismiss_alert.text="DISMISS"
	dismiss_alert.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	dismiss_alert.add_theme_font_size_override("font_size",9)
	dismiss_alert.pressed.connect(_dismiss_active_foreign_alert)
	alert_actions.add_child(dismiss_alert)
	foreign_alert_panel.visible=false
	layer.add_child(foreign_alert_panel)
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
	start_settlement_button.pressed.connect(_on_settlement_action_pressed)
	# Founding is a map command, not persistent chrome. Keep the legacy control as
	# a compatibility target for older saves/captures, but the actual command is
	# exposed through ACTIONS alongside scouts, diplomats, and later convoys.
	start_settlement_button.visible=false
	layer.add_child(start_settlement_button)
	settlement_convoy_instruction_panel=PanelContainer.new()
	settlement_convoy_instruction_panel.position=Vector2(viewport_width*0.5-300,get_viewport().get_visible_rect().size.y-176)
	settlement_convoy_instruction_panel.size=Vector2(600,56)
	settlement_convoy_instruction_panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var convoy_instruction_style:=StyleBoxFlat.new()
	convoy_instruction_style.bg_color=Color(0.025,0.038,0.040,0.96)
	convoy_instruction_style.border_color=Color("#b99b5d")
	convoy_instruction_style.set_border_width_all(1)
	convoy_instruction_style.set_corner_radius_all(4)
	convoy_instruction_style.set_content_margin_all(8)
	settlement_convoy_instruction_panel.add_theme_stylebox_override("panel",convoy_instruction_style)
	settlement_convoy_instruction_label=Label.new()
	settlement_convoy_instruction_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	settlement_convoy_instruction_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	settlement_convoy_instruction_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	settlement_convoy_instruction_label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	settlement_convoy_instruction_label.add_theme_font_size_override("font_size",11)
	settlement_convoy_instruction_panel.add_child(settlement_convoy_instruction_label)
	settlement_convoy_instruction_panel.visible=false
	layer.add_child(settlement_convoy_instruction_panel)
	layer.move_child(start_settlement_button,layer.get_child_count()-1)
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
	people_close.tooltip_text="Close population management"
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
	# Green is reserved for cohorts that contribute to productive labor;
	# warm/grey bands are dependents supported by that labor.
	var cohort_colors:=[Color("#9b7252"),Color("#779a67"),Color("#5e9d70"),Color("#4f916d"),Color("#6f8f65"),Color("#766d72")]
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
		["Knowledge", "RESEARCHERS","The aggregate research workforce. Its distribution across inquiry fields determines the civilization's path; broader programs divide that capacity."],
		["Administration", "STEWARDS","Coordinates labor and material reserves while strengthening cohesion and legitimacy."],
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
	_build_command_rail_hud(layer)
	_update_time_interface()
	_refresh_discovered_resource_overlays()
	_build_leader_selection(layer)

func _build_command_rail_hud(layer:CanvasLayer)->void:
	hud=preload("res://scripts/hud/command_rail_hud.gd").new()
	hud.terrain=self
	layer.add_child(hud)
	hud.section_requested.connect(_on_hud_section_requested)
	hud.menu_requested.connect(_open_world_menu)
	hud.escape_pressed.connect(_on_hud_escape)
	hud.register_provider("settlement",preload("res://scripts/hud/content/dock_content_settlement.gd").new(self,hud))
	hud.register_provider("economy",preload("res://scripts/hud/content/dock_content_economy.gd").new(self,hud))
	hud.register_provider("civ",preload("res://scripts/hud/content/dock_content_civilization.gd").new(self,hud))
	hud.register_provider("inquiry",preload("res://scripts/hud/content/dock_content_inquiry.gd").new(self,hud))
	hud.register_provider("world",preload("res://scripts/hud/content/dock_content_world.gd").new(self,hud))
	hud.register_provider("military",preload("res://scripts/hud/content/dock_content_military.gd").new(self,hud))
	_update_scale_bar()

func _open_war_planning(tab:int=4)->void:
	## Deep military detail: fronts, orders, engagements, and the full supply
	## ledger live in the war-planning view.
	var military:=get_node_or_null("/root/MilitaryCommandUI")
	if military==null: return
	if not military.modal.visible: military._toggle()
	if military.modal.visible and military.command_tabs:
		military.command_tabs.current_tab=clampi(tab,0,military.command_tabs.get_tab_count()-1)

func _on_hud_section_requested(section:String,sub:int)->void:
	# Sections with a dock provider open in the slide-out dock beside the rail;
	# the rest still route to their legacy destinations until they migrate.
	if section=="":
		hud.close_dock()
		_close_primary_destinations_except("none")
		return
	if hud.has_provider(section):
		_close_primary_destinations_except("none")
		hud.open_dock(section,sub)
		return
	hud.close_dock()
	match section:
		"civ":
			if sub==2: _open_council_panel()
			else: _open_systems_hub()
		"inquiry": _open_knowledge_panel()
		"world": _open_civilizations_panel()
		"military":
			var military:=get_node_or_null("/root/MilitaryCommandUI")
			if military: military._toggle()

func _on_hud_escape()->void:
	_close_primary_destinations_except("none")
	if hud: hud.set_active_section("")

func _build_scale_bar(layer: CanvasLayer) -> void:
	var viewport_size:=get_viewport().get_visible_rect().size
	scale_bar_root=Control.new()
	scale_bar_root.position=Vector2(24,viewport_size.y-92)
	scale_bar_root.size=Vector2(200,42)
	scale_bar_root.mouse_filter=Control.MOUSE_FILTER_PASS
	scale_bar_root.tooltip_text="Current map scale and the distance represented by the line. The north arrow rotates with the view so orientation remains explicit."
	layer.add_child(scale_bar_root)
	var backing:=ColorRect.new()
	backing.size=Vector2(196,40)
	backing.color=Color(0.025,0.034,0.036,0.78)
	backing.mouse_filter=Control.MOUSE_FILTER_IGNORE
	scale_bar_root.add_child(backing)
	scale_bar_label=Label.new()
	scale_bar_label.position=Vector2(10,2)
	scale_bar_label.size=Vector2(178,18)
	scale_bar_label.add_theme_font_size_override("font_size",11)
	scale_bar_label.add_theme_color_override("font_color",Color("#d7d0bf"))
	scale_bar_label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	scale_bar_root.add_child(scale_bar_label)
	scale_compass_label=Label.new()
	scale_compass_label.position=Vector2(148,2)
	scale_compass_label.size=Vector2(40,18)
	scale_compass_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	scale_compass_label.add_theme_font_size_override("font_size",11)
	scale_compass_label.add_theme_color_override("font_color",Color("#d7d0bf"))
	scale_compass_label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	scale_bar_root.add_child(scale_compass_label)
	scale_bar_line=ColorRect.new()
	scale_bar_line.position=Vector2(10,27)
	scale_bar_line.size=Vector2(120,2)
	scale_bar_line.color=Color("#d7d0bf")
	scale_bar_line.mouse_filter=Control.MOUSE_FILTER_IGNORE
	scale_bar_root.add_child(scale_bar_line)
	var left_tick:=ColorRect.new()
	left_tick.position=Vector2(10,22)
	left_tick.size=Vector2(2,12)
	left_tick.color=Color("#d7d0bf")
	left_tick.mouse_filter=Control.MOUSE_FILTER_IGNORE
	scale_bar_root.add_child(left_tick)
	scale_bar_right_tick=ColorRect.new()
	scale_bar_right_tick.position=Vector2(128,22)
	scale_bar_right_tick.size=Vector2(2,12)
	scale_bar_right_tick.color=Color("#d7d0bf")
	scale_bar_right_tick.mouse_filter=Control.MOUSE_FILTER_IGNORE
	scale_bar_root.add_child(scale_bar_right_tick)
	_update_scale_bar()


func _build_map_help(layer:CanvasLayer)->void:
	var viewport_size:=get_viewport().get_visible_rect().size
	map_help_button=Button.new()
	map_help_button.name="MapHelpButton"
	map_help_button.position=Vector2(24,viewport_size.y-130)
	map_help_button.size=Vector2(112,30)
	map_help_button.text="MAP HELP  •  ?"
	map_help_button.tooltip_text="Show map movement, inspection, scale, and the next contextual action."
	map_help_button.add_theme_font_size_override("font_size",10)
	map_help_button.pressed.connect(_toggle_map_help)
	layer.add_child(map_help_button)
	map_help_panel=PanelContainer.new()
	map_help_panel.name="MapFirstUseHelp"
	map_help_panel.position=Vector2(24,viewport_size.y-234)
	map_help_panel.size=Vector2(390,96)
	map_help_panel.z_index=45
	map_help_panel.add_theme_stylebox_override("panel",_population_report_style(Color("#7ca39d")))
	var root:=VBoxContainer.new()
	root.add_theme_constant_override("separation",5)
	map_help_panel.add_child(root)
	var heading_row:=HBoxContainer.new()
	root.add_child(heading_row)
	map_help_title=Label.new()
	map_help_title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	map_help_title.add_theme_font_size_override("font_size",13)
	map_help_title.add_theme_color_override("font_color",Color("#e7d8b8"))
	heading_row.add_child(map_help_title)
	var hide:=Button.new()
	hide.text="GOT IT"
	hide.tooltip_text="Dismiss this tip. Reopen it at any time with MAP HELP."
	hide.custom_minimum_size=Vector2(72,30)
	hide.add_theme_font_size_override("font_size",9)
	hide.pressed.connect(_dismiss_map_help)
	heading_row.add_child(hide)
	map_help_body=Label.new()
	map_help_body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	map_help_body.size_flags_vertical=Control.SIZE_EXPAND_FILL
	map_help_body.add_theme_font_size_override("font_size",11)
	map_help_body.add_theme_color_override("font_color",Color("#c5cbc5"))
	map_help_body.tooltip_text="Camera: pan with WASD or arrow keys; zoom with the mouse wheel; rotate with Shift + middle-drag."
	root.add_child(map_help_body)
	# The founding-focus screen is deferred until after the interface is built.  Do
	# not flash map controls underneath that mandatory, mouse-stopping modal.
	var available_on_map:=not capture_render_active and GameState.founding_focus!=""
	map_help_button.visible=available_on_map
	map_help_panel.visible=available_on_map
	layer.add_child(map_help_panel)
	_refresh_map_help()


func _map_help_presentation(site_committed:bool,targeting:bool,settlement_convoy_active:bool)->Dictionary:
	if targeting:
		return {
			"title":"CHOOSE DRY LAND",
			"body":"Move over land. Green can be settled; red cannot.\nClick to review the trip. Right-click to cancel."
		}
	if not site_committed:
		return {
			"title":"FIND A HOME",
			"body":"Click land to move the convoy.\nWhen you like the location, press FOUND SETTLEMENT on the toolbar below."
		}
	if settlement_convoy_active:
		return {
			"title":"CONVOY IN MOTION",
			"body":"The settlement convoy is traveling.\nPress FOCUS CONVOY on the toolbar below to follow it."
		}
	return {
		"title":"USE THE MAP",
		"body":"Click a known place to inspect it. Double-click to move closer.\nThe toolbar below scouts, settles, and negotiates; the left rail opens every system."
	}


func _refresh_map_help()->void:
	if map_help_title==null or map_help_body==null: return
	var presentation:=_map_help_presentation(GameState.settlement_site_committed,settlement_convoy_targeting,bool(GameState.settlement_convoy.get("active",false)))
	map_help_title.text=String(presentation.title)
	map_help_body.text=String(presentation.body)


func _map_help_available_on_map()->bool:
	return not capture_render_active and GameState.founding_focus!="" and not settlement_convoy_targeting and not _blocking_modal_or_report_open()


func _sync_map_help_overlay_visibility()->void:
	if map_help_panel==null and map_help_button==null: return
	var available:=_map_help_available_on_map()
	if map_help_button: map_help_button.visible=available
	if map_help_panel: map_help_panel.visible=available and not map_help_dismissed


func _toggle_map_help()->void:
	if map_help_panel==null: return
	if not _map_help_available_on_map():
		map_help_panel.visible=false
		if map_help_button: map_help_button.visible=false
		return
	map_help_panel.visible=not map_help_panel.visible
	if map_help_panel.visible:
		map_help_dismissed=false
		_refresh_map_help()


func _dismiss_map_help()->void:
	map_help_dismissed=true
	if map_help_panel: map_help_panel.visible=false

func _update_scale_bar() -> void:
	if camera==null:
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
	var distance_text:=""
	if distance_km<1.0:
		distance_text="%d M" % roundi(distance_km*1000.0)
	elif distance_km<10.0:
		distance_text="%.1f KM" % distance_km
	else:
		distance_text="%d KM" % roundi(distance_km)
	if hud:
		hud.update_scale(pixel_width,distance_text,_camera_scale_band(),_north_screen_arrow())
	if scale_bar_root and scale_bar_line:
		scale_bar_line.size.x=pixel_width
		scale_bar_right_tick.position.x=10.0+pixel_width-2.0
		scale_bar_label.text="%s  •  %s" % [_camera_scale_band(),distance_text]
		if scale_compass_label:
			scale_compass_label.text="N %s" % _north_screen_arrow()

func _camera_scale_band() -> String:
	if camera==null: return "WORLD"
	if camera.size<=0.8: return "SITE"
	if camera.size<=8.0: return "SETTLEMENT"
	if camera.size<=80.0: return "LOCAL"
	if camera.size<=800.0: return "REGION"
	if camera.size<=8000.0: return "CONTINENT"
	return "WORLD"

func _north_screen_arrow() -> String:
	if camera==null: return "↑"
	var center_screen:=camera.unproject_position(camera_target)
	var north_point:=camera_target+Vector3(0.0,0.0,-maxf(1.0,camera.size*0.02))
	north_point.y=_height_at(north_point.x,north_point.z)
	var delta:=camera.unproject_position(north_point)-center_screen
	if delta.length_squared()<0.001: return "↑"
	var angle:=atan2(delta.y,delta.x)
	var arrows:=["→","↘","↓","↙","←","↖","↑","↗"]
	return arrows[wrapi(roundi(angle/(PI/4.0)),0,8)]

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
	GameState.settlement_network_revision+=1
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

func _toggle_resource_view()->void:
	_set_resource_view_enabled(not resource_view_enabled)


func _set_resource_view_enabled(enabled:bool)->void:
	resource_view_enabled=enabled
	if enabled: rendered_resource_overlay_zoom_key=""
	for river_overlay in river_overlays:
		if not is_instance_valid(river_overlay) or String(river_overlay.name)!="RiverWater": continue
		if river_overlay.material_override is ShaderMaterial:
			(river_overlay.material_override as ShaderMaterial).set_shader_parameter("resource_emphasis",1.0 if enabled else 0.0)
	_update_resource_view_toggle()
	_update_scale_lod()


func _update_resource_view_toggle()->void:
	if resource_view_toggle==null: return
	var known_types:Dictionary={}
	for deposit_variant in ResourceSystem.visible_deposits():
		var deposit:Dictionary=deposit_variant
		known_types[String(deposit.get("resource","RESOURCE"))]=true
	resource_view_toggle.text="RESOURCES  •  %s" % ("ON" if resource_view_enabled else "OFF")
	var water_note:=""
	if settler_marker:
		var water_distance:=_river_distance_at(settler_marker.position.x,settler_marker.position.z)*KM_PER_WORLD_UNIT
		water_note="\nNearest visible river or drainage: %.1f km. Within 6 km it directly supports water collection." % water_distance if water_distance<INF else "\nNo recognized surface water is currently within the charted area."
	resource_view_toggle.tooltip_text="Toggle recognized resource geography. Your civilization currently recognizes %d local resource types; unknown deposits remain invisible. Rivers are continuous water sources, not deposit dots; blue emphasis follows their actual channels.%s" % [known_types.size(),water_note]
	var accent:=Color("#79a47c") if resource_view_enabled else Color("#65706b")
	resource_view_toggle.add_theme_stylebox_override("normal",_hud_chip_style(accent))
	resource_view_toggle.add_theme_stylebox_override("hover",_hud_chip_style(accent.lightened(0.12),true))
	resource_view_toggle.add_theme_color_override("font_color",Color("#e9e1ce") if resource_view_enabled else Color("#aab0ac"))


func _refresh_discovered_resource_overlays() -> void:
	if camera==null: return
	if not resource_view_enabled:
		if resource_overlay_root and is_instance_valid(resource_overlay_root): resource_overlay_root.visible=false
		return
	var clusters:=_bounded_resource_overlay_selection(
		ResourceSystem.visible_deposits(),
		Vector2(camera_target.x,camera_target.z),
		camera.size,
		func(position:Vector3)->bool: return _world_position_is_revealed(position)
	)
	if resource_overlay_root and is_instance_valid(resource_overlay_root):
		resource_overlay_root.queue_free()
	resource_overlay_root=Node3D.new()
	resource_overlay_root.name="RecognizedResourceOverlayBatches"
	resource_overlay_root.visible=resource_view_enabled
	add_child(resource_overlay_root)
	discovered_resource_overlays.clear()
	var by_stage:Dictionary={"recognized":[],"surveyed":[],"active":[]}
	for cluster_variant in clusters:
		var cluster:Dictionary=cluster_variant
		(by_stage[String(cluster.get("visual_stage","recognized"))] as Array).append(cluster)
	for stage_variant in by_stage:
		var stage:=String(stage_variant)
		var stage_clusters:Array=by_stage[stage]
		if stage_clusters.is_empty(): continue
		var batch:=_create_resource_overlay_batch(stage,stage_clusters,camera.size)
		resource_overlay_root.add_child(batch)
		discovered_resource_overlays[stage]=batch
	# Labels are bounded and fixed-size, so the opening regional resource view can
	# identify what each marker means without requiring a site-scale zoom.
	if camera.size<=240.0:
		var label_index:=0
		for cluster_variant in clusters:
			if label_index>=RESOURCE_OVERLAY_MAX_LABELS: break
			var cluster:Dictionary=cluster_variant
			var position:Vector3=cluster.position
			# Settlement identity wins when a fixed-size resource name would cover its
			# symbol or classification. The resource ring remains visible and the label
			# returns naturally after the player pans or zooms closer.
			if _resource_label_conflicts_with_settlement(position): continue
			var label:=Label3D.new()
			label.name="ResourceLabel_%02d" % label_index
			var cluster_count:=int(cluster.get("count",1))
			label.text="%s%s" % [String(cluster.get("resource","RESOURCE")).to_upper(),"  ×%d" % cluster_count if cluster_count>1 else ""]
			label.font_size=12
			label.outline_size=5
			label.modulate=Color("#ddd2b4")
			label.outline_modulate=Color(0.025,0.034,0.036,0.96)
			label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
			label.fixed_size=true
			label.no_depth_test=true
			label.position=Vector3(position.x,_height_at(position.x,position.z)+camera.size*0.018,position.z)
			resource_overlay_root.add_child(label)
			label_index+=1
	rendered_resource_overlay_zoom_key=_resource_overlay_view_key()

func _resource_label_conflicts_with_settlement(position:Vector3)->bool:
	if camera==null: return false
	var clearance:=maxf(0.08,camera.size*0.085)
	var point:=Vector2(position.x,position.z)
	for settlement_variant in GameState.player_settlements:
		var settlement:Dictionary=settlement_variant
		var value:Variant=settlement.get("position",Vector2.ZERO)
		var settlement_position:Vector2=value if value is Vector2 else Vector2.ZERO
		if point.distance_to(settlement_position)<=clearance: return true
	if GameState.player_settlements.is_empty() and GameState.settlement_site_committed:
		return point.distance_to(Vector2(GameState.settlement_founded_at.x,GameState.settlement_founded_at.z))<=clearance
	return false


func _bounded_resource_overlay_selection(deposits:Array,view_center:Vector2,zoom:float,reveal_filter:Callable=Callable())->Array[Dictionary]:
	# Resource knowledge may eventually cover a planet. Rendering one scene tree
	# per occurrence would make the map cost grow with total historical knowledge.
	# Instead, only the current view is sampled, nearby occurrences share a stable
	# cell, and the returned draw list has a hard ceiling independent of population.
	# Resource view is useful on the opening regional map as well as at site scale.
	# Planetary zooms still collapse it, while the fixed cluster ceiling keeps the
	# draw cost independent of total known occurrences.
	if zoom>420.0: return []
	var view_radius:=maxf(0.12,zoom*0.92)
	var cell_size:=maxf(0.04,zoom/(72.0 if zoom<=5.5 else 26.0))
	var cells:Dictionary={}
	for deposit_variant in deposits:
		var deposit:Dictionary=deposit_variant
		var resource_name:=String(deposit.get("resource","Resource"))
		if resource_name=="Freshwater": continue
		var stage:=String(deposit.get("stage","recognized"))
		var strategic:=stage in ["accessible","developed"]
		if zoom>240.0 and not strategic: continue
		var position_value:Variant=deposit.get("position",Vector3.ZERO)
		if not position_value is Vector3: continue
		var position:=position_value as Vector3
		if reveal_filter.is_valid() and not bool(reveal_filter.call(position)): continue
		var planar:=Vector2(position.x,position.z)
		var distance_squared:=planar.distance_squared_to(view_center)
		if distance_squared>view_radius*view_radius: continue
		var visual_stage:="active" if strategic else ("surveyed" if stage=="surveyed" else "recognized")
		var cell_key:="%s:%s:%d:%d" % [resource_name,visual_stage,floori(position.x/cell_size),floori(position.z/cell_size)]
		if not cells.has(cell_key):
			cells[cell_key]={"resource":resource_name,"visual_stage":visual_stage,"position":position,"count":1,"distance_squared":distance_squared}
		else:
			var cell:Dictionary=cells[cell_key]
			cell.count=int(cell.count)+1
			if distance_squared<float(cell.distance_squared):
				cell.position=position
				cell.distance_squared=distance_squared
			cells[cell_key]=cell
	var selected:Array[Dictionary]=[]
	for cell_variant in cells.values(): selected.append(cell_variant)
	selected.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
		var a_active:=String(a.visual_stage)=="active"
		var b_active:=String(b.visual_stage)=="active"
		if a_active!=b_active: return a_active
		if not is_equal_approx(float(a.distance_squared),float(b.distance_squared)): return float(a.distance_squared)<float(b.distance_squared)
		return String(a.resource)<String(b.resource)
	)
	if selected.size()>RESOURCE_OVERLAY_MAX_CLUSTERS:
		selected.resize(RESOURCE_OVERLAY_MAX_CLUSTERS)
	return selected


func _create_resource_overlay_batch(stage:String,clusters:Array,zoom:float)->MultiMeshInstance3D:
	var ring_mesh:=TorusMesh.new()
	ring_mesh.inner_radius=0.85
	ring_mesh.outer_radius=1.04
	ring_mesh.rings=20
	ring_mesh.ring_segments=5
	var multimesh:=MultiMesh.new()
	multimesh.transform_format=MultiMesh.TRANSFORM_3D
	multimesh.mesh=ring_mesh
	multimesh.instance_count=clusters.size()
	var scale_value:=maxf(0.008,zoom/96.0)
	for index in clusters.size():
		var position:Vector3=(clusters[index] as Dictionary).position
		var world_position:=Vector3(position.x,_height_at(position.x,position.z)+0.006,position.z)
		multimesh.set_instance_transform(index,Transform3D(Basis.IDENTITY.scaled(Vector3.ONE*scale_value),world_position))
	var batch:=MultiMeshInstance3D.new()
	batch.name="ResourceBatch_%s" % stage.capitalize()
	batch.multimesh=multimesh
	var color:=Color("#b48b4f")
	if stage=="surveyed": color=Color("#8ea3a0")
	elif stage=="active": color=Color("#80a878")
	var material:=StandardMaterial3D.new()
	material.albedo_color=color
	material.emission_enabled=true
	material.emission=color.darkened(0.28)
	material.emission_energy_multiplier=0.48
	material.roughness=0.86
	batch.material_override=material
	return batch
func _refresh_contact_encounter_markers()->void:
	# Historical encounter labels stay in the discovery map. A settlement is
	# different: once a returned report confirms its home, the physical place
	# must become visible on the terrain. Each polity gets one bounded aggregate
	# footprint rather than thousands of buildings or a permanent screen label.
	var confirmed:Array[Dictionary]=[]
	for encounter_variant in CivilizationSystem.contact_encounters_snapshot():
		var encounter:Dictionary=encounter_variant
		if not bool(encounter.get("home_location_known",false)): continue
		var home:Dictionary=encounter.get("home_position",{})
		if not home.has("x") or not home.has("z"): continue
		confirmed.append({"civ_id":String(encounter.get("civ_id","")),"name":String(encounter.get("name","FOREIGN SETTLEMENT")),"x":float(home.x),"z":float(home.z),"observed":int(encounter.get("last_observed_day",-1))})
	var signature:=JSON.stringify(confirmed)
	if signature!=rendered_contact_encounter_signature:
		for civ_id in contact_encounter_markers.keys():
			var stale:Node3D=contact_encounter_markers[civ_id]
			if stale and is_instance_valid(stale): stale.queue_free()
		contact_encounter_markers.clear()
		for site in confirmed:
			var marker:=Node3D.new()
			marker.name="ConfirmedForeignSettlement_%s" % String(site.civ_id)
			marker.set_meta("civilization_id",String(site.civ_id))
			marker.set_meta("settlement_name",String(site.name))
			marker.position=Vector3(float(site.x),_height_at(float(site.x),float(site.z))+0.05,float(site.z))
			var accent:=Color.from_hsv(float(abs(String(site.civ_id).hash())%1000)/1000.0,0.34,0.82)
			var material:=StandardMaterial3D.new(); material.albedo_color=accent.darkened(0.28); material.emission_enabled=true; material.emission=accent.darkened(0.58); material.emission_energy_multiplier=0.42; material.roughness=0.88
			var boundary:=MeshInstance3D.new(); boundary.name="ObservedFootprint"
			var ring:=TorusMesh.new(); ring.inner_radius=5.4; ring.outer_radius=6.0; ring.rings=32; ring.ring_segments=8; boundary.mesh=ring; boundary.material_override=material; marker.add_child(boundary)
			var rng:=RandomNumberGenerator.new(); rng.seed=GameState.world_seed^String(site.civ_id).hash()
			for cluster_index in 12:
				var structure:=MeshInstance3D.new()
				var structure_mesh:=BoxMesh.new(); structure_mesh.size=Vector3(rng.randf_range(0.8,1.8),rng.randf_range(0.45,1.25),rng.randf_range(0.8,1.8)); structure.mesh=structure_mesh; structure.material_override=material
				var radial:=Vector2.RIGHT.rotated(rng.randf_range(0.0,TAU))*rng.randf_range(0.8,4.8)
				structure.position=Vector3(radial.x,float(structure_mesh.size.y)*0.5,radial.y); structure.rotation.y=rng.randf_range(0.0,TAU); marker.add_child(structure)
			var label:=Label3D.new(); label.name="SettlementLabel"; label.text="%s\nCONFIRMED FOREIGN SETTLEMENT" % String(site.name).to_upper(); label.font_size=13; label.outline_size=6; label.billboard=BaseMaterial3D.BILLBOARD_ENABLED; label.fixed_size=true; label.no_depth_test=true; label.position=Vector3(0.0,3.4,0.0); label.modulate=accent.lightened(0.22); label.outline_modulate=Color(0.02,0.025,0.027,0.98); marker.add_child(label)
			add_child(marker)
			contact_encounter_markers[String(site.civ_id)]=marker
		rendered_contact_encounter_signature=signature
	for marker_variant in contact_encounter_markers.values():
		var marker:Node3D=marker_variant
		if marker==null or not is_instance_valid(marker): continue
		marker.visible=camera!=null and camera.size<=1800.0 and _world_position_is_revealed(marker.global_position)
		var label:=marker.get_node_or_null("SettlementLabel") as Label3D
		# The discovery map preserves distant locations. A terrain label is useful
		# only when the player has zoomed into the observed place; keeping fixed-size
		# names visible at regional scale recreates the giant persistent annotations
		# the compact world map was introduced to replace.
		if label: label.visible=camera!=null and camera.size<=24.0


func _refresh_foreign_formation_markers()->void:
	var observation:Dictionary=CivilizationSystem.local_observation_snapshot()
	rendered_observation_revision=int(observation.get("revision",0))
	var visible_ids:Dictionary={}
	for sighting_variant in observation.get("visible",[]):
		var sighting:Dictionary=sighting_variant
		var sighting_id:=String(sighting.get("id","")); visible_ids[sighting_id]=true
		var view:Dictionary=WarfareMapPresentation.foreign_marker(sighting,camera.size if camera else 190.0)
		var position_data:Dictionary=sighting.get("position",{})
		var world_position:=Vector3(float(position_data.get("x",0.0)),0.0,float(position_data.get("z",0.0)))
		world_position.y=_height_at(world_position.x,world_position.z)+0.15
		var marker:Node3D=foreign_formation_markers.get(sighting_id,null)
		if marker==null or not is_instance_valid(marker):
			marker=_create_warfare_formation_marker("Observed_%s" % sighting_id,false)
			add_child(marker); foreign_formation_markers[sighting_id]=marker
		marker.position=world_position
		_apply_warfare_formation_view(marker,view)
		marker.visible=bool(view.get("visible",false)) and _world_position_is_revealed(marker.global_position)
	for sighting_id in foreign_formation_markers.keys():
		if visible_ids.has(String(sighting_id)): continue
		var stale:Node3D=foreign_formation_markers[sighting_id]
		if stale and is_instance_valid(stale): stale.queue_free()
		foreign_formation_markers.erase(sighting_id)


func _refresh_player_field_army_markers()->void:
	var state:Dictionary=MilitaryCampaign.field_armies_snapshot()
	var selected_army_id:=MilitaryCommandUI.selected_field_army_id() if MilitaryCommandUI!=null and MilitaryCommandUI.has_method("selected_field_army_id") else 0
	var front_state:Dictionary=CivilizationSystem.military_fronts_snapshot()
	var presentation:Dictionary=WarfareMapPresentation.build_snapshot(camera.size if camera else 190.0,state.get("armies",[]),[],front_state.get("fronts",[]),state.get("destinations",[]),MilitaryCampaign.engagement_snapshot(),selected_army_id)
	var visible_ids:Dictionary={}
	for view_variant in presentation.get("player",[]):
		var view:Dictionary=view_variant
		var army_id:=String(view.get("id","")); visible_ids[army_id]=true
		var position_data:Dictionary=view.get("position",{})
		var world_position:=Vector3(float(position_data.get("x",0.0)),0.0,float(position_data.get("z",0.0)))
		world_position.y=_height_at(world_position.x,world_position.z)+0.18
		var marker:Node3D=player_field_army_markers.get(army_id,null)
		if marker==null or not is_instance_valid(marker):
			marker=_create_warfare_formation_marker("PlayerFieldArmy_%s" % army_id,true)
			add_child(marker); player_field_army_markers[army_id]=marker
		marker.position=world_position
		_apply_warfare_formation_view(marker,view)
		marker.visible=bool(view.get("visible",false)) and _world_position_is_revealed(marker.global_position)
		_refresh_player_field_army_path(view)
	for army_id in player_field_army_markers.keys():
		if visible_ids.has(String(army_id)): continue
		var stale:Node3D=player_field_army_markers[army_id]
		if stale and is_instance_valid(stale): stale.queue_free()
		player_field_army_markers.erase(army_id)
	for army_id in player_field_army_paths.keys():
		if visible_ids.has(String(army_id)): continue
		var stale_path:Node3D=player_field_army_paths[army_id]
		if stale_path and is_instance_valid(stale_path): stale_path.queue_free()
		player_field_army_paths.erase(army_id)
	_refresh_warfare_front_markers(presentation.get("fronts",[]))


func _create_warfare_formation_marker(marker_name:String,player_owned:bool)->Node3D:
	var marker:=Node3D.new()
	marker.name=marker_name
	# A formation is a filled military counter, not a target ring. Player counters are
	# rectangular command plates; uncertain foreign observations remain diamonds.
	var plate:=MeshInstance3D.new()
	plate.name="ArmyPlate" if player_owned else "ObservationPlate"
	if player_owned:
		var plate_mesh:=BoxMesh.new()
		plate_mesh.size=Vector3(6.4,0.26,4.1)
		plate.mesh=plate_mesh
		plate.position.y=0.13
	else:
		var plate_mesh:=CylinderMesh.new()
		plate_mesh.top_radius=2.55
		plate_mesh.bottom_radius=2.55
		plate_mesh.height=0.24
		plate_mesh.radial_segments=4
		plate.mesh=plate_mesh
		plate.position.y=0.12
	var owner_color:=Color(WarfareMapPresentation.PLAYER_COLOR if player_owned else WarfareMapPresentation.FOREIGN_COLOR)
	var plate_color:=owner_color.darkened(0.47)
	plate_color.a=0.94
	plate.material_override=_warfare_marker_material(plate_color)
	marker.add_child(plate)
	# The tapered standard gives direction and remains visible above terrain relief.
	var standard:=MeshInstance3D.new()
	standard.name="ArmyStandard" if player_owned else "FormationFlag"
	var standard_mesh:=CylinderMesh.new()
	standard_mesh.top_radius=0.20 if player_owned else 0.16
	standard_mesh.bottom_radius=0.78 if player_owned else 0.65
	standard_mesh.height=2.35 if player_owned else 1.90
	standard_mesh.radial_segments=4
	standard.mesh=standard_mesh
	standard.position=Vector3(-1.85,float(standard_mesh.height)*0.5,0.0)
	standard.material_override=_warfare_marker_material(owner_color)
	marker.add_child(standard)
	var pip:=MeshInstance3D.new()
	pip.name="ReadinessPip"
	var pip_mesh:=CylinderMesh.new()
	pip_mesh.top_radius=0.46
	pip_mesh.bottom_radius=0.46
	pip_mesh.height=0.22
	pip_mesh.radial_segments=10
	pip.mesh=pip_mesh
	pip.position=Vector3(2.35,0.25,-1.25)
	pip.material_override=_warfare_marker_material(Color("#d5ad58"))
	marker.add_child(pip)
	var supply:=MeshInstance3D.new()
	supply.name="SupplyStripe"
	var supply_mesh:=BoxMesh.new()
	supply_mesh.size=Vector3(3.7,0.16,0.48)
	supply.mesh=supply_mesh
	supply.position=Vector3(0.30,0.25,1.42)
	supply.material_override=_warfare_marker_material(Color("#76b99a"))
	marker.add_child(supply)
	var selected_ring:=MeshInstance3D.new(); selected_ring.name="SelectedRing"
	var selected_mesh:=TorusMesh.new(); selected_mesh.inner_radius=3.75; selected_mesh.outer_radius=4.10; selected_mesh.rings=24; selected_mesh.ring_segments=6; selected_ring.mesh=selected_mesh; selected_ring.material_override=_warfare_marker_material(Color(WarfareMapPresentation.PLAYER_SELECTED_COLOR)); selected_ring.visible=false; marker.add_child(selected_ring)
	var label:=Label3D.new(); label.name="ArmyLabel" if player_owned else "FormationLabel"; label.font_size=11 if player_owned else 10; label.outline_size=5; label.billboard=BaseMaterial3D.BILLBOARD_ENABLED; label.fixed_size=true; label.no_depth_test=true; label.position=Vector3(0,6.4 if player_owned else 5.8,0); label.outline_modulate=Color(0.02,0.025,0.027,0.98); marker.add_child(label)
	return marker


func _warfare_marker_material(color:Color)->StandardMaterial3D:
	var material:=StandardMaterial3D.new(); material.albedo_color=color; material.emission_enabled=true; material.emission=color.darkened(0.28); material.emission_energy_multiplier=0.78; material.roughness=0.70; material.no_depth_test=true
	if color.a<0.999: material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	return material


func _set_warfare_part_color(part:MeshInstance3D,color:Color)->void:
	var material:=part.material_override as StandardMaterial3D
	if material==null:
		material=_warfare_marker_material(color); part.material_override=material
	material.albedo_color=color; material.emission=color.darkened(0.24)


func _apply_warfare_formation_view(marker:Node3D,view:Dictionary)->void:
	var marker_scale:=maxf(0.001,float(view.get("scale",1.0)))
	marker.scale=Vector3.ONE*marker_scale
	var color:=Color(String(view.get("color",WarfareMapPresentation.FOREIGN_COLOR)))
	for part_name in ["ArmyStandard","FormationFlag"]:
		var part:=marker.get_node_or_null(part_name) as MeshInstance3D
		if part: _set_warfare_part_color(part,color)
	var plate:=marker.get_node_or_null("ArmyPlate") as MeshInstance3D
	if plate==null: plate=marker.get_node_or_null("ObservationPlate") as MeshInstance3D
	if plate:
		var plate_color:=color.darkened(0.47); plate_color.a=0.94
		_set_warfare_part_color(plate,plate_color)
	var pip:=marker.get_node_or_null("ReadinessPip") as MeshInstance3D
	if pip: _set_warfare_part_color(pip,Color(String(view.get("readiness_color","#d5ad58"))))
	var supply:=marker.get_node_or_null("SupplyStripe") as MeshInstance3D
	if supply:
		var supply_color:=Color(String(view.get("supply_color","#7d8790"))) if view.has("supply") else color.darkened(0.12)
		_set_warfare_part_color(supply,supply_color)
	var selected_ring:=marker.get_node_or_null("SelectedRing") as MeshInstance3D
	if selected_ring: selected_ring.visible=bool(view.get("selected",false))
	var label:=marker.get_node_or_null("ArmyLabel") as Label3D
	if label==null: label=marker.get_node_or_null("FormationLabel") as Label3D
	if label:
		# Label3D.fixed_size does not cancel an inherited Node3D scale. Keep the
		# glyphs at a stable screen size while the tactical marker grows with zoom.
		label.scale=Vector3.ONE/marker_scale
		label.text=String(view.get("label","")); label.visible=bool(view.get("show_label",false)); label.modulate=color.lightened(0.28)


func _refresh_player_field_army_path(view:Dictionary)->void:
	var army_id:=String(view.get("id",""))
	var existing:Node3D=player_field_army_paths.get(army_id,null)
	if not bool(view.get("show_path",false)):
		if existing and is_instance_valid(existing): existing.visible=false
		return
	var position_data:Dictionary=view.get("position",{}); var destination_data:Dictionary=view.get("destination_position",{})
	if not destination_data.has("x") or not destination_data.has("z"): return
	var current:=Vector3(float(position_data.get("x",0.0)),0.0,float(position_data.get("z",0.0)))
	var destination:=Vector3(float(destination_data.get("x",0.0)),0.0,float(destination_data.get("z",0.0)))
	var band:=WarfareMapPresentation.scale_band(camera.size if camera else 190.0)
	var signature:="%.1f:%.1f:%.1f:%.1f:%s:%s" % [current.x,current.z,destination.x,destination.z,band,str(bool(view.get("selected",false)))]
	if existing==null or not is_instance_valid(existing) or String(existing.get_meta("signature",""))!=signature:
		if existing and is_instance_valid(existing): existing.queue_free()
		existing=_create_player_field_army_path(view,current,destination,band)
		existing.set_meta("signature",signature); add_child(existing); player_field_army_paths[army_id]=existing
	existing.visible=true
	var objective:=existing.get_node_or_null("MovementObjective") as Node3D
	if objective:
		var objective_scale:=maxf(0.001,float(view.get("scale",1.0))*0.90)
		objective.scale=Vector3.ONE*objective_scale
		objective.position=Vector3(destination.x,_height_at(destination.x,destination.z)+0.10,destination.z)
		var objective_label:=objective.get_node_or_null("ObjectiveLabel") as Label3D
		if objective_label: objective_label.scale=Vector3.ONE/objective_scale


func _create_player_field_army_path(view:Dictionary,current:Vector3,destination:Vector3,band:String)->Node3D:
	var root:=Node3D.new(); root.name="ArmyMovement_%s" % String(view.get("id",""))
	var immediate:=ImmediateMesh.new(); immediate.surface_begin(Mesh.PRIMITIVE_LINES)
	var segments:=18 if band=="local" else (12 if band=="regional" else 8)
	for segment in segments:
		if segment%2==1: continue
		for point_index in [segment,segment+1]:
			var progress:=float(point_index)/float(segments)
			var point:=current.lerp(destination,progress); point.y=_height_at(point.x,point.z)+0.22
			immediate.surface_add_vertex(point)
	immediate.surface_end()
	var line:=MeshInstance3D.new(); line.name="MovementPath"; line.mesh=immediate
	var color:=Color(String(view.get("color",WarfareMapPresentation.PLAYER_COLOR))); color.a=0.90
	var material:=_warfare_marker_material(color); material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA; line.material_override=material; root.add_child(line)
	var objective:=Node3D.new(); objective.name="MovementObjective"; root.add_child(objective)
	var ring:=MeshInstance3D.new(); ring.name="ObjectiveRing"
	var ring_mesh:=TorusMesh.new(); ring_mesh.inner_radius=2.9; ring_mesh.outer_radius=3.5; ring_mesh.rings=28; ring_mesh.ring_segments=8; ring.mesh=ring_mesh; ring.material_override=_warfare_marker_material(color); objective.add_child(ring)
	var arrow:=MeshInstance3D.new(); arrow.name="ObjectiveArrow"
	var arrow_mesh:=CylinderMesh.new(); arrow_mesh.top_radius=0.12; arrow_mesh.bottom_radius=0.82; arrow_mesh.height=1.6; arrow_mesh.radial_segments=4; arrow.mesh=arrow_mesh; arrow.position.y=0.80; arrow.material_override=_warfare_marker_material(color); objective.add_child(arrow)
	var label:=Label3D.new(); label.name="ObjectiveLabel"; label.text="MOVE OBJECTIVE\n%s • %.0f KM • ETA DAY %d" % [String(view.get("destination_name","DESTINATION")).to_upper(),float(view.get("distance_remaining_km",0.0)),int(view.get("arrival_day",0))]; label.font_size=12; label.outline_size=5; label.billboard=BaseMaterial3D.BILLBOARD_ENABLED; label.fixed_size=true; label.no_depth_test=true; label.position=Vector3(0,3.6,0); label.modulate=color.lightened(0.25); label.outline_modulate=Color(0.02,0.025,0.027,0.98); label.visible=band in ["local","regional"] or bool(view.get("selected",false)); objective.add_child(label)
	return root


func _refresh_warfare_front_markers(front_views:Array)->void:
	var visible_ids:Dictionary={}
	for view_variant in front_views:
		var view:Dictionary=view_variant; var front_id:=String(view.get("id","")); visible_ids[front_id]=true
		var position_data:Dictionary=view.get("position",{}); var position:=Vector3(float(position_data.get("x",0.0)),0.0,float(position_data.get("z",0.0))); position.y=_height_at(position.x,position.z)+0.20
		var marker:Node3D=warfare_front_markers.get(front_id,null)
		if marker==null or not is_instance_valid(marker):
			marker=_create_warfare_front_marker(front_id); add_child(marker); warfare_front_markers[front_id]=marker
		var marker_scale:=maxf(0.001,float(view.get("scale",1.0)))
		marker.position=position; marker.scale=Vector3.ONE*marker_scale; marker.visible=bool(view.get("visible",false)) and _world_position_is_revealed(position)
		var color:=Color(String(view.get("color",WarfareMapPresentation.FRONT_COLOR)))
		var front_core:=marker.get_node("FrontCore") as MeshInstance3D; _set_warfare_part_color(front_core,color)
		var front_plate:=marker.get_node("FrontPlate") as MeshInstance3D
		var front_plate_color:=color.darkened(0.50); front_plate_color.a=0.94; _set_warfare_part_color(front_plate,front_plate_color)
		var pip:=marker.get_node("ReadinessPip") as MeshInstance3D; _set_warfare_part_color(pip,Color(String(view.get("readiness_color","#d5ad58"))))
		var progress_bar:=marker.get_node("ObjectiveProgress") as MeshInstance3D
		var progress:=clampf(float(view.get("progress",0.0)),0.0,1.0)
		progress_bar.scale=Vector3(maxf(0.04,progress),1.0,1.0)
		progress_bar.position.x=-2.45+2.45*progress
		_set_warfare_part_color(progress_bar,color.lightened(0.24))
		var selected:=String(view.get("target_region_id",""))!="" and String(view.get("target_region_id",""))==selected_civilization_region_id
		(marker.get_node("SelectedRing") as MeshInstance3D).visible=selected
		var label:=marker.get_node("FrontLabel") as Label3D; label.scale=Vector3.ONE/marker_scale; label.text=String(view.get("label","")); label.visible=bool(view.get("show_label",false)); label.modulate=color.lightened(0.24)
	for front_id in warfare_front_markers.keys():
		if visible_ids.has(String(front_id)): continue
		var stale:Node3D=warfare_front_markers[front_id]
		if stale and is_instance_valid(stale): stale.queue_free()
		warfare_front_markers.erase(front_id)


func _create_warfare_front_marker(front_id:String)->Node3D:
	var marker:=Node3D.new(); marker.name="WarfareFront_%s" % front_id
	var plate:=MeshInstance3D.new(); plate.name="FrontPlate"
	var plate_mesh:=CylinderMesh.new(); plate_mesh.top_radius=4.85; plate_mesh.bottom_radius=4.85; plate_mesh.height=0.24; plate_mesh.radial_segments=6; plate.mesh=plate_mesh; plate.position.y=0.12
	var plate_color:=Color(WarfareMapPresentation.FRONT_COLOR).darkened(0.50); plate_color.a=0.94; plate.material_override=_warfare_marker_material(plate_color); marker.add_child(plate)
	var core:=MeshInstance3D.new(); core.name="FrontCore"
	var core_mesh:=CylinderMesh.new(); core_mesh.top_radius=0.30; core_mesh.bottom_radius=1.05; core_mesh.height=2.1; core_mesh.radial_segments=4; core.mesh=core_mesh; core.position.y=1.05; core.material_override=_warfare_marker_material(Color(WarfareMapPresentation.FRONT_COLOR)); marker.add_child(core)
	var progress:=MeshInstance3D.new(); progress.name="ObjectiveProgress"
	var progress_mesh:=BoxMesh.new(); progress_mesh.size=Vector3(4.9,0.18,0.56); progress.mesh=progress_mesh; progress.position=Vector3(0.0,0.27,2.65); progress.material_override=_warfare_marker_material(Color(WarfareMapPresentation.FRONT_COLOR).lightened(0.24)); marker.add_child(progress)
	var pip:=MeshInstance3D.new(); pip.name="ReadinessPip"
	var pip_mesh:=SphereMesh.new(); pip_mesh.radius=0.48; pip_mesh.height=0.96; pip.mesh=pip_mesh; pip.position=Vector3(3.6,0.62,0); pip.material_override=_warfare_marker_material(Color("#d5ad58")); marker.add_child(pip)
	var selected_ring:=MeshInstance3D.new(); selected_ring.name="SelectedRing"
	var selected_mesh:=TorusMesh.new(); selected_mesh.inner_radius=6.0; selected_mesh.outer_radius=6.45; selected_mesh.rings=32; selected_mesh.ring_segments=7; selected_ring.mesh=selected_mesh; selected_ring.material_override=_warfare_marker_material(Color(WarfareMapPresentation.PLAYER_SELECTED_COLOR)); selected_ring.visible=false; marker.add_child(selected_ring)
	var label:=Label3D.new(); label.name="FrontLabel"; label.font_size=11; label.outline_size=5; label.billboard=BaseMaterial3D.BILLBOARD_ENABLED; label.fixed_size=true; label.no_depth_test=true; label.position=Vector3(0,7.0,0); label.outline_modulate=Color(0.02,0.025,0.027,0.98); marker.add_child(label)
	return marker

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
	lens_body.scroll_active=false
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
	var morphology_era:=String(plot.get("morphology_era","founding")).replace("_"," ").capitalize()
	var fabric_generation:=int(plot.get("fabric_generation",0))
	report+="Inherited fabric: [color=#ddd2b8]%s[/color]  •  generation %d\n" % [morphology_era,fabric_generation]
	if int(plot.get("storeys",1))>1: report+="Built height: [color=#ddd2b8]%d storeys[/color]\n" % int(plot.get("storeys",1))
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

func _contact_encounter_at(position:Vector3,radius_km:float=5.0)->Dictionary:
	var ground_position:=Vector2(position.x,position.z)
	for encounter_variant in CivilizationSystem.contact_encounters_snapshot():
		var encounter:Dictionary=encounter_variant
		var home:Dictionary=encounter.get("home_position",{}) if bool(encounter.get("home_location_known",false)) else {}
		if home.has("x") and home.has("z") and ground_position.distance_to(Vector2(float(home.x),float(home.z)))<=radius_km:
			var settlement:=encounter.duplicate(true)
			settlement["point_kind"]="settlement"
			return settlement
		var encounter_position:Dictionary=encounter.get("position",{})
		if not encounter_position.has("x") or not encounter_position.has("z"): continue
		if ground_position.distance_to(Vector2(float(encounter_position.x),float(encounter_position.z)))<=radius_km:
			var contact_site:=encounter.duplicate(true)
			contact_site["point_kind"]="encounter"
			return contact_site
	return {}


func _map_selection_radius(camera_size:float,viewport_height:float)->float:
	# Roughly 18 screen pixels at any altitude, with only hard safety bounds.
	# The marker therefore remains legible without becoming a giant world label.
	return clampf(camera_size/maxf(1.0,viewport_height)*18.0,0.004,220.0)


func _ensure_map_selection_marker()->void:
	if map_selection_marker and is_instance_valid(map_selection_marker): return
	map_selection_marker=MeshInstance3D.new()
	map_selection_marker.name="MapSelectionMarker"
	var ring:=TorusMesh.new()
	ring.inner_radius=0.88
	ring.outer_radius=1.0
	ring.rings=40
	ring.ring_segments=5
	map_selection_marker.mesh=ring
	var material:=StandardMaterial3D.new()
	material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	material.no_depth_test=true
	material.render_priority=12
	material.albedo_color=Color(0.88,0.75,0.39,0.90)
	map_selection_marker.material_override=material
	map_selection_marker.visible=false
	add_child(map_selection_marker)


func _show_map_selection(position:Vector3)->void:
	_ensure_map_selection_marker()
	map_selection_generation+=1
	var generation:=map_selection_generation
	map_selection_marker.position=Vector3(position.x,_height_at(position.x,position.z)+0.006,position.z)
	var viewport_height:=get_viewport().get_visible_rect().size.y
	var radius:=_map_selection_radius(camera.size if camera else 12.0,viewport_height)
	# Uniform scale is essential: keeping Y at 1 turned the temporary ground ring
	# into the giant upright yellow capsule seen during normal map inspection.
	map_selection_marker.scale=Vector3.ONE*radius
	var surface_assessment:=_settlement_surface_assessment(position)
	var color:=Color(0.88,0.75,0.39,0.90) if _world_position_is_revealed(position) else Color(0.48,0.54,0.54,0.72)
	if not bool(surface_assessment.get("valid",false)): color=Color(0.92,0.30,0.23,0.90)
	(map_selection_marker.material_override as StandardMaterial3D).albedo_color=color
	map_selection_marker.visible=true
	get_tree().create_timer(2.5).timeout.connect(_hide_map_selection.bind(generation))


func _hide_map_selection(generation:int)->void:
	if generation!=map_selection_generation: return
	if map_selection_marker and is_instance_valid(map_selection_marker): map_selection_marker.visible=false


func _map_inspection_summary(position:Vector3)->String:
	if not _world_position_is_revealed(position):
		return "UNCHARTED LAND SELECTED  •  no returned report describes this ground  •  NEXT: ACTIONS → SEND SCOUT PARTY"
	var surface_assessment:=_settlement_surface_assessment(position)
	if not bool(surface_assessment.get("valid",false)):
		return "%s  •  SETTLEMENT BLOCKED  •  NEXT: choose dry ground beyond the visible bank" % String(surface_assessment.get("reason","WATER SELECTED"))
	var contact:=_contact_encounter_at(position)
	if not contact.is_empty():
		if String(contact.get("point_kind","encounter"))=="settlement":
			return "%s SETTLEMENT SELECTED  •  location confirmed, current conditions require another returned report  •  NEXT: open WORLD" % String(contact.get("name","FOREIGN")).to_upper()
		var home_note:="home settlement known" if bool(contact.get("home_location_known",false)) else "home settlement still unlocated"
		return "%s ENCOUNTER SITE SELECTED  •  %s  •  NEXT: ACTIONS → SEND SCOUT PARTY" % [String(contact.get("name","FOREIGN")).to_upper(),home_note]
	if GameState.settlement_site_committed and "Hearth Circle" in GameState.settlement_completed:
		var settlement:Dictionary=_settlement_model().settlement_at_world(Vector2(position.x,position.z))
		if not settlement.is_empty() and bool(settlement.get("inside_border",false)):
			return "%s GROUND SELECTED  •  %.1f KM FROM CENTRE  •  double-click the settlement marker to move one scale closer" % [String(settlement.get("name","SETTLEMENT")).to_upper(),float(settlement.get("distance_from_center_km",0.0))]
	var resources:=ResourceSystem.lens_entries(position,18.0,KM_PER_WORLD_UNIT)
	var names:Array[String]=[]
	for entry_variant in resources:
		var entry:Dictionary=entry_variant
		var resource_name:=String(entry.get("resource",""))
		if resource_name!="" and resource_name not in names: names.append(resource_name)
		if names.size()>=3: break
	var resource_note:="recognized nearby: %s" % ", ".join(names) if not names.is_empty() else "no resource recognized at this point"
	return "CHARTED LAND SELECTED  •  %s  •  NEXT: ACTIONS → FOUND NEW SETTLEMENT" % resource_note


func _inspect_location(position: Vector3) -> void:
	_show_map_selection(position)
	if travel_status_label: travel_status_label.text=_map_inspection_summary(position)
	if lens_panel == null or lens_body == null:
		return
	lens_requested_visible=true
	lens_panel.visible = true
	lens_world_position = position
	var revealed:=_world_position_is_revealed(position)
	var settlement_context:Dictionary={}
	if GameState.settlement_site_committed and "Hearth Circle" in GameState.settlement_completed:
		settlement_context=_settlement_model().settlement_at_world(Vector2(position.x,position.z))
	var contact_context:=_contact_encounter_at(position) if revealed else {}
	if not revealed:
		lens_location_label.text="BEYOND RETURNED MAP KNOWLEDGE"
	elif not contact_context.is_empty():
		lens_location_label.text=("CONFIRMED SETTLEMENT  •  %s" if String(contact_context.get("point_kind","encounter"))=="settlement" else "FIRST CONTACT SITE  •  %s") % String(contact_context.get("name","FOREIGN POLITY")).to_upper()
	elif bool(GameState.settlement_convoy.get("active",false)):
		var convoy_position:Vector2=GameState.settlement_convoy.get("position",Vector2.ZERO)
		var convoy_distance:=convoy_position.distance_to(Vector2(position.x,position.z))*KM_PER_WORLD_UNIT
		if convoy_distance<0.15:
			lens_location_label.text="SETTLEMENT CONVOY POSITION"
		elif not settlement_context.is_empty() and bool(settlement_context.get("inside_border",false)):
			lens_location_label.text="WITHIN %s  •  %.1f KM FROM CENTRE" % [String(settlement_context.get("name","SETTLEMENT")).to_upper(),float(settlement_context.get("distance_from_center_km",0.0))]
		else:
			lens_location_label.text="%.1f KM FROM THE SETTLEMENT CONVOY" % convoy_distance
	elif not settlement_context.is_empty():
		if bool(settlement_context.get("inside_border",false)):
			lens_location_label.text="WITHIN %s  •  %.1f KM FROM CENTRE" % [String(settlement_context.get("name","SETTLEMENT")).to_upper(),float(settlement_context.get("distance_from_center_km",0.0))]
		else:
			lens_location_label.text="%.1f KM BEYOND %s'S BORDER" % [float(settlement_context.get("distance_from_border_km",0.0)),String(settlement_context.get("name","SETTLEMENT")).to_upper()]
	else:
		var founding_distance:=Vector2(settler_marker.position.x,settler_marker.position.z).distance_to(Vector2(position.x,position.z))*KM_PER_WORLD_UNIT if settler_marker else 0.0
		if GameState.founding_expedition_active():
			lens_location_label.text="FOUNDING CONVOY POSITION" if founding_distance<0.15 else "%.1f KM FROM THE FOUNDING CONVOY" % founding_distance
		else:
			lens_location_label.text="FOUNDING SITE" if founding_distance<0.15 else "%.1f KM FROM THE FOUNDING SITE" % founding_distance
	var entries: Array[Dictionary] = []
	if revealed:
		entries = ResourceSystem.lens_entries(position, 18.0, KM_PER_WORLD_UNIT)
	var settlement_plot:=_settlement_plot_at(position) if revealed else {}
	if not revealed:
		var unknown_action:="Dispatch a timed scout party and wait for its return before planning settlement here." if GameState.settlement_site_committed else "Travel here with the founding convoy or dispatch a timed scout party and wait for its return."
		lens_body.text="[color=#777f7c][font_size=18]UNCHARTED[/font_size][/color]\n\nNo returned traveler or scout report describes this ground. Terrain, water, resources, settlements, and foreign activity remain unknown.\n\n[color=#c4aa70]%s[/color]" % unknown_action
	elif not contact_context.is_empty():
		if String(contact_context.get("point_kind","encounter"))=="settlement":
			var observed_day:=maxi(0,int(contact_context.get("last_observed_day",0)))
			lens_body.text="[font_size=18][color=#e1d08d]CONFIRMED FOREIGN SETTLEMENT[/color][/font_size]\n\n[color=#e1d5b8]%s[/color]\nLocation confirmed by %s. Last physically observed in Year %d, Day %d.\n\nThis aggregate footprint represents the observed occupied place without simulating every structure or inhabitant. Dispatch an observation mission for current population, activity, and defenses." % [String(contact_context.get("name","A foreign polity")),String(contact_context.get("home_location_source","a returned report")),observed_day/365+1,observed_day%365+1]
		else:
			var met_day:=maxi(0,int(contact_context.get("day",0)))
			var met_year:=met_day/365+1
			var met_day_of_year:=met_day%365+1
			lens_body.text="[font_size=18][color=#bde0d7]RECORDED ENCOUNTER[/color][/font_size]\n\n[color=#e1d5b8]%s[/color] was first identified here in Year %d, Day %d.\n\n[color=#c4aa70]HOW CONTACT HAPPENED[/color]\n%s.\n\n[color=#c27f6c]Their homeland is not known from this encounter.[/color] This marker records where contact occurred—not permanent global tracking and not a guessed capital." % [String(contact_context.get("name","A foreign polity")),met_year,met_day_of_year,String(contact_context.get("source_description","The surviving record does not say"))]
	elif entries.is_empty() and settlement_plot.is_empty():
		if not settlement_context.is_empty() and bool(settlement_context.get("inside_border",false)):
			lens_body.text="[font_size=18][color=#dfd0aa]CONTROLLED SETTLEMENT GROUND[/color][/font_size]\n\nWithin [color=#e1d5b8]%s[/color]'s present border. The boundary covers approximately [color=#ddd2b8]%.1f km²[/color] and supports an aggregate population of [color=#ddd2b8]%s[/color].\n\nBorders expand when population, occupied fabric, routes, survey work, administration, logistics, and defense can sustain a wider claim.\n\n[color=#c4aa70]No specific resource has yet been recognized at this point.[/color]" % [String(settlement_context.get("name","the settlement")),float(settlement_context.get("controlled_area_km2",0.0)),_compact_population(int(settlement_context.get("population",0)))]
		else:
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
		ring_mesh.inner_radius = 0.055
		ring_mesh.outer_radius = 0.072
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


func _retire_primary_screen(panel)->void:
	if panel!=null and is_instance_valid(panel):
		panel.visible=false
		panel.queue_free()


# Only one primary destination may own the interaction layer. Detail screens
# stay inside their destination; switching destinations retires the old tree
# before the new one is shown, so notifications and dashboards cannot stack.
func _close_primary_destinations_except(destination:String)->void:
	if actions_menu_panel and actions_menu_panel.visible: _close_actions_menu()
	if destination!="settlement":
		_retire_primary_screen(settlement_dashboard_panel); settlement_dashboard_panel=null
	_retire_primary_screen(population_ledger_panel); population_ledger_panel=null
	if destination!="economy":
		_retire_primary_screen(provisions_panel); provisions_panel=null
		_retire_primary_screen(materials_panel); materials_panel=null
	if destination=="civilization":
		_retire_primary_screen(knowledge_panel); knowledge_panel=null
		_retire_primary_screen(council_panel); council_panel=null
		_retire_primary_screen(government_panel); government_panel=null
		_retire_primary_screen(society_panel); society_panel=null
		_retire_primary_screen(progression_panel); progression_panel=null
	else:
		_retire_primary_screen(systems_hub_panel); systems_hub_panel=null
		_retire_primary_screen(knowledge_panel); knowledge_panel=null
		_retire_primary_screen(council_panel); council_panel=null
		_retire_primary_screen(government_panel); government_panel=null
		_retire_primary_screen(society_panel); society_panel=null
		_retire_primary_screen(progression_panel); progression_panel=null
	if destination=="world":
		_retire_primary_screen(civilization_report_panel); civilization_report_panel=null
	else:
		_retire_primary_screen(civilization_report_panel); civilization_report_panel=null
		_retire_primary_screen(civilizations_panel); civilizations_panel=null
		civilization_detail_root=null
	if destination!="military" and MilitaryCommandUI and MilitaryCommandUI.modal and MilitaryCommandUI.modal.visible:
		MilitaryCommandUI.modal.hide()


func _open_provisions_panel() -> void:
	_close_primary_destinations_except("economy")
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
	title.text="ECONOMY — PROVISIONS & WATER"
	title.add_theme_font_size_override("font_size",27)
	title.add_theme_color_override("font_color",Color("#f0e4cd"))
	title_box.add_child(title)
	var subtitle:=Label.new()
	subtitle.text="Who eats each day, what missions took at departure, and why the stored total changed."
	subtitle.add_theme_font_size_override("font_size",12)
	subtitle.add_theme_color_override("font_color",Color("#9ca39d"))
	title_box.add_child(subtitle)
	var metrics:=GameState.simulation_metrics
	var produced:=float(metrics.get("food_production",0.0))
	var required:=float(metrics.get("food_consumption",maxf(1.0,GameState.population_exact)))
	var eaten:=float(metrics.get("food_eaten",required))
	var spoiled:=float(metrics.get("food_spoilage",0.0))
	var net:=float(metrics.get("food_net",produced-eaten-spoiled))
	var issued_today:=FoodSystem.issued_on_day(int(GameState.elapsed_days))
	var stock_change:=net-issued_today
	var days:=float(metrics.get("food_days",0.0))
	var projected:=float(metrics.get("food_projected_days",days))
	var forecast_30:Dictionary=metrics.get("food_forecast_30",{})
	var forecast_90:Dictionary=metrics.get("food_forecast_90",{})
	var shortage_90:=int(forecast_90.get("first_shortage_day",-1))
	var water:=GameState.water_metrics
	var outlook_text:="shortage %dd" % shortage_90 if shortage_90>0 else ("30d %.0f • 90d %.0f" % [float(forecast_30.get("ending_days",days)),float(forecast_90.get("ending_days",days))] if not forecast_90.is_empty() else ("stable" if projected>=999.0 else "%.0f days" % projected))
	_make_provision_stat(header,"FOOD RESERVE","%.1f days" % days,Color("#d0b46f"))
	_make_provision_stat(header,"STOCK CHANGE","%+.1f today" % stock_change,Color("#78a77d") if stock_change>=0.0 else Color("#c67462"))
	_make_provision_stat(header,"INTAKE","%d%%" % roundi(float(metrics.get("food_intake_ratio",1.0))*100.0),Color("#83a6a0"))
	_make_provision_stat(header,"DRINKING WATER","%.1f days • %d%%" % [float(water.get("days",0.0)),roundi(float(water.get("intake_ratio",0.0))*100.0)],Color("#6f9eaa") if float(water.get("intake_ratio",0.0))>=0.98 else Color("#c67462"))
	_make_provision_stat(header,"SEASONAL OUTLOOK",outlook_text,Color("#c67661") if shortage_90>0 else Color("#b99369"))
	root.add_child(HSeparator.new())
	_add_modal_action_brief(root,_provisions_decision_brief(metrics,water,issued_today),Color("#b99369"))
	var columns:=HBoxContainer.new()
	columns.name="ProvisionDashboardColumns"
	columns.size_flags_vertical=Control.SIZE_EXPAND_FILL
	columns.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation",12)
	root.add_child(columns)
	var stores:=_make_provision_dashboard_column(columns,"RESERVES NOW","Immediate food reserves and bodily condition")
	_add_provision_bar(stores,"FOOD RESERVE","%.1f days  •  %.1f rations" % [days,float(GameState.resource_stockpiles.get("Food",0.0))],clampf(days/90.0,0.0,1.0),Color("#d0b46f"))
	_add_provision_bar(stores,"DRINKING WATER","%.1f days  •  %d%% of today’s need" % [float(water.get("days",0.0)),roundi(float(water.get("intake_ratio",0.0))*100.0)],float(water.get("stored",0.0))/maxf(0.01,float(water.get("capacity",1.0))),Color("#6f9eaa"))
	var stock_data:Dictionary=metrics.get("food_stocks",GameState.food_stocks)
	var spoilage_data:Dictionary=metrics.get("food_spoilage_by_type",{})
	var stock_lines:Array[String]=[]
	for food_type in FoodSystemScript.FOOD_TYPES:
		var amount:=float(stock_data.get(food_type,0.0))
		var daily_loss:=float(spoilage_data.get(food_type,0.0))
		stock_lines.append("%s  %.1f  •  %.1f lost" % [String(food_type).capitalize(),amount,daily_loss])
	_add_compact_provision_text(stores,"BY KIND","\n".join(stock_lines),Color("#aaa897"))
	stores.add_child(HSeparator.new())
	_add_compact_provision_text(stores,"NUTRITION","Diet %d%%  •  Body reserve %d%%  •  Malnutrition %d%%" % [roundi(float(metrics.get("food_diet_quality",0.0))*100.0),roundi(GameState.nutrition_reserve*100.0),roundi(GameState.malnutrition_burden*100.0)],Color("#a99a75"))
	var flow:=_make_provision_dashboard_column(columns,"TODAY'S FLOW","Adult-equivalent rations; issued missions leave the reserve once")
	_add_provision_bar(flow,"PRODUCED","%+.1f" % produced,produced/maxf(required,produced),Color("#729b6e"))
	_add_provision_bar(flow,"MEALS EATEN","−%.1f of %.1f required" % [eaten,required],eaten/maxf(0.01,required),Color("#779ca0"))
	_add_provision_bar(flow,"SPOILAGE","−%.1f" % spoiled,spoiled/maxf(1.0,required),Color("#a56e5f"))
	_add_provision_bar(flow,"MISSIONS / EXTERNAL","−%.1f issued today" % issued_today,issued_today/maxf(1.0,required),Color("#c48462"))
	_add_provision_bar(flow,"NET STORE CHANGE","%+.1f" % stock_change,absf(stock_change)/maxf(1.0,required),Color("#789c72") if stock_change>=0.0 else Color("#c46f60"))
	flow.add_child(HSeparator.new())
	_add_compact_provision_text(flow,"MAIN SOURCES",_provisions_source_summary(metrics),Color("#9daa91"))
	var consumers:=_make_provision_dashboard_column(columns,"WHO USES FOOD","Daily consumers plus prepaid parties currently away")
	_add_compact_provision_text(consumers,"DAILY MEALS",_provisions_consumer_summary(metrics,required),Color("#c6c1af"))
	consumers.add_child(HSeparator.new())
	_add_compact_provision_text(consumers,"MISSIONS & CONVOYS",_provisions_commitment_summary(),Color("#c09a70"))
	var footer:=HBoxContainer.new()
	footer.alignment=BoxContainer.ALIGNMENT_END
	root.add_child(footer)
	var detail_button:=Button.new()
	detail_button.text="OPEN DETAILS & HISTORY"
	detail_button.custom_minimum_size=Vector2(210,38)
	detail_button.tooltip_text="Open perishable stock detail, the 30-day trend, active mission issues, and the recent withdrawal ledger."
	detail_button.pressed.connect(_open_provisions_detail_overlay)
	footer.add_child(detail_button)
	var materials_view:=Button.new()
	materials_view.text="MATERIAL FLOW"
	materials_view.custom_minimum_size=Vector2(160,38)
	materials_view.tooltip_text="Open recognized material sources, extraction, hauling, losses, and storage."
	materials_view.pressed.connect(_switch_economy_to_materials)
	footer.add_child(materials_view)
	var close:=Button.new()
	close.text="RETURN TO MAP"
	close.custom_minimum_size=Vector2(150,40)
	close.pressed.connect(func(): provisions_panel.queue_free(); provisions_panel=null)
	footer.add_child(close)

func _open_materials_panel() -> void:
	_close_primary_destinations_except("economy")
	if materials_panel: materials_panel.queue_free()
	materials_panel=Control.new()
	materials_panel.size=get_viewport().get_visible_rect().size
	materials_panel.mouse_filter=Control.MOUSE_FILTER_STOP
	interface_layer.add_child(materials_panel)
	var dimmer:=ColorRect.new(); dimmer.size=materials_panel.size; dimmer.color=Color(0.006,0.009,0.010,0.92); materials_panel.add_child(dimmer)
	var modal:=PanelContainer.new(); modal.size=Vector2(minf(1080.0,materials_panel.size.x-64.0),minf(640.0,materials_panel.size.y-48.0)); modal.position=(materials_panel.size-modal.size)*0.5; modal.add_theme_stylebox_override("panel",_knowledge_style(Color("#0b1112"),Color("#806c4c"),1,3,18)); materials_panel.add_child(modal)
	var root:=VBoxContainer.new(); root.add_theme_constant_override("separation",9); modal.add_child(root)
	var header:=HBoxContainer.new(); header.add_theme_constant_override("separation",10); root.add_child(header)
	var heading:=VBoxContainer.new(); heading.size_flags_horizontal=Control.SIZE_EXPAND_FILL; header.add_child(heading)
	var title:=Label.new(); title.text="ECONOMY — MATERIAL FLOW"; title.add_theme_font_size_override("font_size",24); title.add_theme_color_override("font_color",Color("#eee1c9")); heading.add_child(title)
	var visible:=ResourceSystem.visible_deposits()
	var material_sources:Array=[]
	for source_variant in visible:
		var source:Dictionary=source_variant
		if String(source.get("resource",""))!="Freshwater": material_sources.append(source)
	var water_access:Dictionary=ResourceSystem.water_access_snapshot(_discovery_context())
	var max_distance:=0.0
	var accessible_count:=0
	var developed_count:=0
	for deposit_variant in material_sources:
		var deposit:Dictionary=deposit_variant
		max_distance=maxf(max_distance,float(deposit.get("distance_km",0.0)))
		if String(deposit.get("stage","")) in ["accessible","developed"]: accessible_count+=1
		if String(deposit.get("stage",""))=="developed": developed_count+=1
	var scale_label:="SETTLEMENT" if max_distance<80.0 else ("REGIONAL" if max_distance<500.0 else ("CONTINENTAL" if max_distance<3500.0 else "INTERCONTINENTAL"))
	var subtitle:=Label.new(); subtitle.text="%s REACH  •  %d known material sources%s  •  See what is moving and what to fix next" % [scale_label,material_sources.size()," + mapped water" if bool(water_access.get("recognized",false)) else ""]; subtitle.add_theme_font_size_override("font_size",11); subtitle.add_theme_color_override("font_color",Color("#9ca29d")); heading.add_child(subtitle)
	var metrics:=GameState.material_metrics
	_make_provision_stat(header,"REACH","%s km" % _compact_population(roundi(max_distance)),Color("#8b9f98"))
	_make_provision_stat(header,"WORKING","%d / %d sites" % [accessible_count,material_sources.size()],Color("#78977f"))
	_make_provision_stat(header,"DELIVERED TODAY","%.1f bulk" % float(metrics.get("delivered_today",0.0)),Color("#78977f"))
	var live_capacity:=float(metrics.get("storage_capacity",0.0))
	if live_capacity<=0.0:
		for capacity in ResourceSystem.storage_capacities().values(): live_capacity+=float(capacity)
	_make_provision_stat(header,"STORAGE","%.0f / %.0f bulk" % [ResourceSystem.stored_bulk(),live_capacity],Color("#a58b67"))
	root.add_child(HSeparator.new())
	_add_modal_action_brief(root,_material_constraint_brief(metrics,accessible_count,live_capacity,ResourceSystem.stored_bulk()),Color("#a58b67"))
	var source_list:=VBoxContainer.new(); source_list.name="MaterialFlowTable"; source_list.size_flags_vertical=Control.SIZE_EXPAND_FILL; source_list.add_theme_constant_override("separation",4); root.add_child(source_list)
	var rows:Array[Dictionary]=_material_flow_rows(material_sources)
	if bool(water_access.get("recognized",false)):
		var collection_workers:=float(water_access.get("collection_workers",0.0))
		if collection_workers<=0.0:
			collection_workers=float(GameState.population_allocations.get("Logistics",0))+float(GameState.population_allocations.get("Food",0))*0.22
		var required_water:=float(water_access.get("required_today",0.0))
		var water_flow_text:="Collection begins when time starts" if required_water<=0.0 else "%.1f collected / %.1f needed  •  %d%% met" % [float(water_access.get("collected_today",0.0)),required_water,roundi(float(water_access.get("intake_ratio",0.0))*100.0)]
		rows.push_front({
			"material":"Fresh Water","occurrences":1,"reachable":1 if bool(water_access.get("accessible",false)) else 0,"developed":0,
			"workers":roundi(collection_workers),"extracted":0.0,"at_source":0.0,"moving":0.0,"distance":maxf(0.0,float(water_access.get("distance_km",0.0))),
			"bottlenecks":{},"status":"REACHABLE" if bool(water_access.get("accessible",false)) else "MAPPED","status_detail":"Visible river / drainage","attention_rank":-1,
			"flow_text":water_flow_text,"is_surface_water":true
		})
	if rows.is_empty():
		_make_knowledge_empty_state(source_list,"No material occurrence has been recognized. Surveying and returned travel reports can add regions to this network.")
	else:
		_add_material_flow_header(source_list)
		var visible_row_count:=mini(9,rows.size())
		for row_index in visible_row_count: _add_material_flow_row(source_list,rows[row_index])
		if rows.size()>visible_row_count:
			var grouped:=Label.new(); grouped.text="+ %d additional material systems grouped in Details" % (rows.size()-visible_row_count); grouped.add_theme_font_size_override("font_size",10); grouped.add_theme_color_override("font_color",Color("#858e88")); source_list.add_child(grouped)
	var footer:=HBoxContainer.new(); root.add_child(footer)
	var note:=Label.new(); note.text="%d known resource systems  •  %d point occurrences%s  •  attention-needed rows first" % [rows.size(),material_sources.size()," + continuous water" if bool(water_access.get("recognized",false)) else ""]; note.size_flags_horizontal=Control.SIZE_EXPAND_FILL; note.add_theme_font_size_override("font_size",10); note.add_theme_color_override("font_color",Color("#888f89")); footer.add_child(note)
	var provisions_view:=Button.new(); provisions_view.text="PROVISIONS & WATER"; provisions_view.custom_minimum_size=Vector2(170,38); provisions_view.tooltip_text="Open food reserves, water, consumption, missions, and the seasonal outlook."; provisions_view.pressed.connect(_switch_economy_to_provisions); footer.add_child(provisions_view)
	var details_button:=Button.new(); details_button.text="SOURCE DETAILS"; details_button.custom_minimum_size=Vector2(150,38); details_button.pressed.connect(_open_materials_detail_overlay.bind(rows,water_access)); footer.add_child(details_button)
	var map_button:=Button.new(); map_button.text="SHOW RESOURCE MAP"; map_button.custom_minimum_size=Vector2(170,38); map_button.tooltip_text="Close this report and enable the map layer for resources your civilization can actually recognize."; map_button.pressed.connect(_open_resource_map_from_materials); footer.add_child(map_button)
	var close:=Button.new(); close.text="RETURN TO MAP"; close.custom_minimum_size=Vector2(140,38); close.pressed.connect(func(): materials_panel.queue_free(); materials_panel=null); footer.add_child(close)
	_constrain_modal_labels(root)


func _switch_economy_to_materials()->void:
	if provisions_panel and is_instance_valid(provisions_panel): provisions_panel.queue_free()
	provisions_panel=null
	call_deferred("_open_materials_panel")


func _switch_economy_to_provisions()->void:
	if materials_panel and is_instance_valid(materials_panel): materials_panel.queue_free()
	materials_panel=null
	call_deferred("_open_provisions_panel")


func _open_resource_map_from_materials()->void:
	if materials_panel and is_instance_valid(materials_panel): materials_panel.queue_free()
	materials_panel=null
	_set_resource_view_enabled(true)
	if travel_status_label: travel_status_label.text="RESOURCE VIEW ON  •  ONLY RECOGNIZED OCCURRENCES ARE SHOWN"


func _material_flow_rows(material_sources:Array)->Array[Dictionary]:
	var groups:Dictionary={}
	for deposit_variant in material_sources:
		var deposit:Dictionary=deposit_variant
		var resource_name:=String(deposit.get("resource","Unknown"))
		var group:Dictionary=groups.get(resource_name,{"material":resource_name,"occurrences":0,"reachable":0,"developed":0,"workers":0,"extracted":0.0,"at_source":0.0,"moving":0.0,"distance":0.0,"bottlenecks":{}})
		group.occurrences=int(group.occurrences)+1
		if String(deposit.get("stage","")) in ["accessible","developed"]: group.reachable=int(group.reachable)+1
		if String(deposit.get("stage",""))=="developed": group.developed=int(group.developed)+1
		group.workers=int(group.workers)+int(deposit.get("workers",0))
		group.extracted=float(group.extracted)+float(deposit.get("extracted_today",0.0))
		group.at_source=float(group.at_source)+float(deposit.get("stock_at_source",0.0))
		group.moving=float(group.moving)+ResourceSystem.in_transit_for(deposit)
		group.distance=maxf(float(group.distance),maxf(0.0,float(deposit.get("distance_km",0.0))))
		var bottleneck:=String(deposit.get("bottleneck",""))
		if bottleneck!="" and bottleneck!="Flowing": (group.bottlenecks as Dictionary)[bottleneck]=int((group.bottlenecks as Dictionary).get(bottleneck,0))+1
		groups[resource_name]=group
	var rows:Array[Dictionary]=[]
	for resource_name_variant in groups:
		var row:Dictionary=groups[resource_name_variant]
		var bottlenecks:Dictionary=row.bottlenecks
		if not bottlenecks.is_empty():
			row["status"]="BLOCKED"
			row["status_detail"]=String(bottlenecks.keys()[0])
			row["attention_rank"]=0
		elif int(row.reachable)<=0 or int(row.workers)<=0:
			row["status"]="UNORGANIZED"
			row["status_detail"]="No staffed reachable source"
			row["attention_rank"]=1
		else:
			row["status"]="FLOWING"
			row["status_detail"]="Material is entering the network"
			row["attention_rank"]=2
		rows.append(row)
	rows.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
		if int(a.attention_rank)!=int(b.attention_rank): return int(a.attention_rank)<int(b.attention_rank)
		return String(a.material)<String(b.material))
	return rows


func _add_material_flow_header(parent:Container)->void:
	var header:=HBoxContainer.new(); header.add_theme_constant_override("separation",6); parent.add_child(header)
	for definition in [["RESOURCE",145],["STATUS",170],["REACH",120],["WORKERS",70],["ACTUAL FLOW",220],["ACTION",105]]:
		var label:=Label.new(); label.text=String(definition[0]); label.custom_minimum_size=Vector2(float(definition[1]),22); label.add_theme_font_size_override("font_size",9); label.add_theme_color_override("font_color",Color("#9d9275")); header.add_child(label)


func _add_material_flow_row(parent:Container,row_data:Dictionary)->void:
	var panel:=PanelContainer.new()
	var status:=String(row_data.get("status","UNORGANIZED"))
	var accent:=Color("#78977f") if status in ["FLOWING","REACHABLE"] else Color("#6e939d") if status=="MAPPED" else Color("#b77761") if status=="BLOCKED" else Color("#a58b67")
	panel.add_theme_stylebox_override("panel",_knowledge_style(Color("#11191a"),accent.darkened(0.32),1,2,5))
	parent.add_child(panel)
	var row:=HBoxContainer.new(); row.add_theme_constant_override("separation",6); panel.add_child(row)
	_add_material_flow_cell(row,String(row_data.get("material","Unknown")).to_upper(),145,Color("#d4cfbf"))
	_add_material_flow_cell(row,"%s  •  %s" % [status,String(row_data.get("status_detail",""))],170,accent)
	var distance:=float(row_data.get("distance",0.0))
	var reach_text:="LOCAL  •  %d reachable" % int(row_data.get("reachable",0)) if distance<0.05 else "%s km  •  %d reachable" % [_compact_population(roundi(distance)),int(row_data.get("reachable",0))]
	_add_material_flow_cell(row,reach_text,120,Color("#9ba7a1"))
	_add_material_flow_cell(row,_compact_population(int(row_data.get("workers",0))),70,Color("#c2b58d"))
	var flow_parts:Array[String]=[]
	if float(row_data.get("extracted",0.0))>0.001: flow_parts.append("%.1f extracted" % float(row_data.extracted))
	if float(row_data.get("at_source",0.0))>0.001: flow_parts.append("%.1f waiting" % float(row_data.at_source))
	if float(row_data.get("moving",0.0))>0.001: flow_parts.append("%.1f moving" % float(row_data.moving))
	var flow_text:=String(row_data.get("flow_text","  •  ".join(flow_parts) if not flow_parts.is_empty() else "No material moving"))
	_add_material_flow_cell(row,flow_text,220,Color("#aeb3aa") if not flow_parts.is_empty() or bool(row_data.get("is_surface_water",false)) else Color("#777f7a"))
	var resource_name:=String(row_data.get("material",""))
	if bool(row_data.get("is_surface_water",false)):
		var show_river:=Button.new(); show_river.text="SHOW RIVER"; show_river.custom_minimum_size=Vector2(105,30); show_river.add_theme_font_size_override("font_size",9); show_river.tooltip_text="Return to the map with recognized river and drainage channels emphasized."; show_river.pressed.connect(_open_resource_map_from_materials); row.add_child(show_river)
	elif ResourceSystem.material_profile(resource_name).size()>0 and resource_name not in ["Freshwater","Fertile Soil","Game","Medicinal Plants"]:
		var priority:=Button.new(); var priority_value:=float(GameState.resource_priorities.get(resource_name,1.0)); priority.text="SET %s" % ("LOW" if priority_value>1.2 else ("NORMAL" if priority_value<0.8 else "HIGH")); priority.custom_minimum_size=Vector2(105,30); priority.add_theme_font_size_override("font_size",9); priority.tooltip_text="Cycle this material's aggregate extraction and carrier priority."; priority.pressed.connect(_cycle_material_priority.bind(resource_name)); row.add_child(priority)
	else:
		_add_material_flow_cell(row,"No priority",105,Color("#6f7772"))


func _add_material_flow_cell(parent:Container,text_value:String,width:float,color:Color)->Label:
	var label:=Label.new(); label.text=text_value; label.custom_minimum_size=Vector2(width,30); label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS; label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER; label.add_theme_font_size_override("font_size",9); label.add_theme_color_override("font_color",color); parent.add_child(label); return label


func _open_materials_detail_overlay(rows:Array[Dictionary],water_access:Dictionary)->void:
	if materials_panel==null or not is_instance_valid(materials_panel) or materials_panel.find_child("MaterialsDetailOverlay",true,false): return
	var overlay:=Control.new(); overlay.name="MaterialsDetailOverlay"; overlay.size=materials_panel.size; overlay.mouse_filter=Control.MOUSE_FILTER_STOP; overlay.z_index=8; materials_panel.add_child(overlay)
	var dimmer:=ColorRect.new(); dimmer.size=overlay.size; dimmer.color=Color(0.003,0.006,0.007,0.94); overlay.add_child(dimmer)
	var modal:=PanelContainer.new(); modal.size=Vector2(minf(900.0,overlay.size.x-56.0),minf(600.0,overlay.size.y-44.0)); modal.position=(overlay.size-modal.size)*0.5; modal.add_theme_stylebox_override("panel",_knowledge_style(Color("#0b1112"),Color("#806c4c"),1,4,16)); overlay.add_child(modal)
	var root:=VBoxContainer.new(); root.add_theme_constant_override("separation",7); modal.add_child(root)
	var heading_row:=HBoxContainer.new(); root.add_child(heading_row)
	var heading:=Label.new(); heading.text="SOURCE & STORAGE DETAILS"; heading.size_flags_horizontal=Control.SIZE_EXPAND_FILL; heading.add_theme_font_size_override("font_size",21); heading_row.add_child(heading)
	var close:=Button.new(); close.text="BACK TO FLOW"; close.custom_minimum_size=Vector2(150,36); close.pressed.connect(overlay.queue_free); heading_row.add_child(close)
	var scroll:=FIT_CONTENT_PANEL.new(); scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL; root.add_child(scroll)
	var detail:=VBoxContainer.new(); detail.size_flags_horizontal=Control.SIZE_EXPAND_FILL; detail.add_theme_constant_override("separation",7); scroll.add_child(detail)
	if bool(water_access.get("recognized",false)): _add_compact_provision_text(detail,"CONTINUOUS SURFACE WATER","Mapped river/drainage access is tracked separately from deposits. %.1f collected / %.1f needed today." % [float(water_access.get("collected_today",0.0)),float(water_access.get("required_today",0.0))],Color("#8fb2b6"))
	for row_data in rows:
		var text:="%d known occurrences  •  %d reachable  •  %d developed\n%d workers  •  %.1f extracted  •  %.1f waiting  •  %.1f moving\n%s" % [int(row_data.occurrences),int(row_data.reachable),int(row_data.developed),int(row_data.workers),float(row_data.extracted),float(row_data.at_source),float(row_data.moving),String(row_data.status_detail)]
		_add_compact_provision_text(detail,String(row_data.material).to_upper()+"  •  "+String(row_data.status),text,Color("#b8bab0"))
	detail.add_child(HSeparator.new())
	_add_provision_section_title(detail,"STORAGE BY SYSTEM","Bulk capacity is aggregated across every player settlement.")
	var capacities:=ResourceSystem.storage_capacities()
	for store_name in capacities: _add_compact_provision_text(detail,String(store_name).replace("_"," ").to_upper(),"%.0f bulk capacity" % float(capacities[store_name]),Color("#a58b67"))


func _open_materials_panel_legacy() -> void:
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
	var economy_row:=HBoxContainer.new()
	economy_row.add_theme_constant_override("separation",9)
	root.add_child(economy_row)
	var economy_metrics:=GameState.economy_metrics
	_make_provision_stat(economy_row,"ALLOCATION",String(economy_metrics.get("stage_name","Direct allocation & reciprocity")),Color("#c1a56b"))
	_make_provision_stat(economy_row,"DISTRIBUTION REACH","%d%%" % roundi(float(economy_metrics.get("distribution_reach",economy_metrics.get("market_access",0.0)))*100.0),Color("#7f9b91"))
	var observed_index:=float(economy_metrics.get("price_index",0.0))
	_make_provision_stat(economy_row,"RECORDED COMPARISONS",("%.2f  %+.1f%%" % [observed_index,float(economy_metrics.get("inflation",0.0))*100.0]) if observed_index>0.0 else "No shared value record",Color("#aa8c68"))
	_make_provision_stat(economy_row,"RECIPROCAL SURPLUS","%.1f today" % float(economy_metrics.get("reciprocal_surplus",economy_metrics.get("trade_volume",0.0))),Color("#75939c"))
	if GameState.economy_stage==EconomySystem.STAGE_CURRENCY:
		_make_provision_stat(economy_row,"TREASURY","%.1f / %.1f supply" % [GameState.public_treasury,GameState.currency_supply],Color("#c5b36f"))
		_make_provision_stat(economy_row,"CREDIT","%.1f  •  %d%% GINI" % [GameState.credit_outstanding,roundi(float(economy_metrics.get("inequality",0.0))*100.0)],Color("#9c7f91"))
	else:
		_make_provision_stat(economy_row,"SETTLEMENT",EconomySystem.settlement_medium(),Color("#968a72"))
	root.add_child(HSeparator.new())
	var scroll:=FIT_CONTENT_PANEL.new()
	scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
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
	_add_provision_bar(flow_column,"4  DELIVERED","%.1f reached storage today" % delivered,delivered/scale,Color("#719a78"))
	_add_provision_bar(flow_column,"5  LOST","%.1f exposure / damage / overflow" % lost,lost/scale,Color("#a75e52"))
	flow_column.add_child(HSeparator.new())
	_add_provision_section_title(flow_column,"LABOR BEHIND THE FLOW","Automatic allocation divides numeric labor cohorts by priority, scarcity, quality, and distance.")
	_add_provision_bar(flow_column,"EXTRACTORS","%d people" % int(GameState.population_allocations.get("Extraction",0)),float(GameState.population_allocations.get("Extraction",0))/maxf(1.0,GameState.population_exact),Color("#b18a5d"))
	_add_provision_bar(flow_column,"CARRIERS","%d people" % int(GameState.population_allocations.get("Logistics",0)),float(GameState.population_allocations.get("Logistics",0))/maxf(1.0,GameState.population_exact),Color("#718f94"))
	var doctrine:=Label.new()
	doctrine.text="Practical knowledge compounds: experienced workers recognize related materials faster, lose less usable material, and teach later generations. New practices can improve food preservation, health, building, trade, administration, or war—but some also bring pollution and danger."
	doctrine.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	doctrine.add_theme_font_size_override("font_size",11)
	doctrine.add_theme_color_override("font_color",Color("#adb1a8"))
	flow_column.add_child(doctrine)
	flow_column.add_child(HSeparator.new())
	_add_provision_section_title(flow_column,"ALLOCATION & VALUE","Internal distribution is not foreign trade. Comparable values appear only after repeated exchange can be recorded.")
	var exchange_metrics:=GameState.economy_metrics
	var exchange_summary:=Label.new()
	exchange_summary.text="%s\n%s\nInternal distribution %d%%  •  Monetized %d%%  •  Shortage pressure %d%%" % [String(exchange_metrics.get("stage_name","Direct allocation & reciprocity")).to_upper(),EconomySystem.settlement_medium(),roundi(float(exchange_metrics.get("distribution_reach",exchange_metrics.get("market_access",0.0)))*100.0),roundi(float(exchange_metrics.get("monetization",0.0))*100.0),roundi(float(exchange_metrics.get("shortage_pressure",0.0))*100.0)]
	exchange_summary.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	exchange_summary.add_theme_font_size_override("font_size",10)
	exchange_summary.add_theme_color_override("font_color",Color("#c9b889"))
	flow_column.add_child(exchange_summary)
	var real_economy:Dictionary=exchange_metrics.get("real_economy",{})
	if not real_economy.is_empty():
		var real_label:=Label.new()
		real_label.text="ESSENTIAL COVERAGE %d%%  •  FOOD %d%%  •  MATERIALS %d%%  •  COLLECTIVE LABOR %d%%\nEXCHANGEABLE SURPLUS %.1f value  •  REAL OUTPUT %.2f / person  •  LABOR RETURN %.2f× basket%s" % [roundi(float(real_economy.get("essential_coverage",0.0))*100.0),roundi(float(real_economy.get("food_coverage",0.0))*100.0),roundi(float(real_economy.get("material_coverage",0.0))*100.0),roundi(float(real_economy.get("collective_labor_share",0.0))*100.0),float(real_economy.get("exchangeable_surplus_value",0.0)),float(real_economy.get("output_per_capita",0.0)),float(real_economy.get("labor_return_index",0.0)),"  •  PRIVATE LIQUIDITY %.1f days" % float(real_economy.get("private_liquidity_days",0.0)) if GameState.economy_stage==EconomySystem.STAGE_CURRENCY else ""]
		real_label.tooltip_text="Physical adequacy and labor burden remain decisive in every exchange stage. These are observational accounts; the economy does not consume food or materials a second time."
		real_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		real_label.add_theme_font_size_override("font_size",9)
		real_label.add_theme_color_override("font_color",Color("#9eab8c"))
		flow_column.add_child(real_label)
	var public_obligations:Dictionary=exchange_metrics.get("public_obligations",{})
	if not public_obligations.is_empty():
		var obligation_label:=Label.new()
		obligation_label.text="PUBLIC DUES  %s  •  ASSESSED REACH %d%%  •  IN-KIND SHARE %d%%\nLABOR %.1f / %.1f rendered  •  %d%% covered  •  %.1f days carried\nMATERIAL %.1f / %.1f value rendered  •  %d%% covered  •  %.1f value carried" % [String(public_obligations.get("regime","customary obligations")).to_upper(),roundi(float(public_obligations.get("assessment_reach",0.0))*100.0),roundi(float(public_obligations.get("in_kind_share",1.0))*100.0),float(public_obligations.get("labor_fulfilled",0.0)),float(public_obligations.get("labor_outstanding",0.0)),roundi(float(public_obligations.get("labor_coverage",0.0))*100.0),float(public_obligations.get("labor_arrears",0.0)),float(public_obligations.get("material_fulfilled",0.0)),float(public_obligations.get("material_outstanding",0.0)),roundi(float(public_obligations.get("material_coverage",0.0))*100.0),float(public_obligations.get("material_arrears",0.0))]
		obligation_label.tooltip_text="Collective labor and material deliveries can satisfy public obligations. These accounts classify work and goods already handled by their owning systems; they never consume a second unit. Scheduled levies preserve unpaid claims, while currency commutes most dues into the exchange levy."
		obligation_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		obligation_label.add_theme_font_size_override("font_size",9)
		obligation_label.add_theme_color_override("font_color",Color("#aa9675"))
		flow_column.add_child(obligation_label)
	var reserve_summary:=Label.new()
	reserve_summary.text="AVAILABLE METAL %.1f  •  WEIGHED EXCHANGE %.1f  •  TODAY'S METAL TURNOVER %.1f  •  COMMITTED RESERVE %.1f  •  RESERVE RATIO %d%%" % [float(exchange_metrics.get("metal_available",EconomySystem._available_metal_value())),GameState.weighed_metal_circulation,float(exchange_metrics.get("metal_trade_turnover",0.0)),float(exchange_metrics.get("metal_reserve",EconomySystem._monetary_reserve_value())),roundi(float(exchange_metrics.get("reserve_ratio",0.0))*100.0)]
	reserve_summary.tooltip_text="Available metal remains in ordinary stores. Weighed exchange metal is physical standardized metal held in circulation. Committed reserve is sequestered backing. One unit cannot occupy more than one account."
	reserve_summary.add_theme_font_size_override("font_size",9)
	reserve_summary.add_theme_color_override("font_color",Color("#a9976f"))
	flow_column.add_child(reserve_summary)
	var reserve_composition:Dictionary=exchange_metrics.get("reserve_composition",GameState.monetary_reserve_metals)
	if not reserve_composition.is_empty():
		var reserve_parts:Array[String]=[]
		for reserve_material in reserve_composition:
			reserve_parts.append("%s %.1f" % [String(reserve_material),float(reserve_composition[reserve_material])])
		reserve_parts.sort()
		var composition_label:=Label.new()
		composition_label.text="Backing: "+"  •  ".join(reserve_parts)
		composition_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		composition_label.add_theme_font_size_override("font_size",9)
		composition_label.add_theme_color_override("font_color",Color("#8e8778"))
		flow_column.add_child(composition_label)
	var exchange_metal_composition:Dictionary=exchange_metrics.get("weighed_metal_composition",GameState.weighed_metal_composition)
	if not exchange_metal_composition.is_empty():
		var exchange_metal_parts:Array[String]=[]
		for exchange_material in exchange_metal_composition:
			exchange_metal_parts.append("%s %.1f" % [String(exchange_material),float(exchange_metal_composition[exchange_material])])
		exchange_metal_parts.sort()
		var exchange_metal_label:=Label.new()
		exchange_metal_label.text="Weighed circulation: %s  •  cumulative wear %.2f" % ["  •  ".join(exchange_metal_parts),GameState.weighed_metal_losses]
		exchange_metal_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		exchange_metal_label.add_theme_font_size_override("font_size",9)
		exchange_metal_label.add_theme_color_override("font_color",Color("#a58f70"))
		flow_column.add_child(exchange_metal_label)
	if GameState.economy_stage!=EconomySystem.STAGE_SUBSISTENCE:
		var metal_policy_row:=HBoxContainer.new()
		metal_policy_row.add_theme_constant_override("separation",4)
		flow_column.add_child(metal_policy_row)
		for metal_policy_variant in [["METAL TO TRADE",maxf(1.0,GameState.population_exact*0.04)],["WITHDRAW TRADE METAL",maxf(1.0,GameState.population_exact*0.04)]]:
			var metal_policy:Array=metal_policy_variant
			var metal_policy_button:=Button.new()
			metal_policy_button.text=String(metal_policy[0])
			metal_policy_button.tooltip_text=_economy_policy_preview_text(String(metal_policy[0]),float(metal_policy[1]))
			metal_policy_button.pressed.connect(_apply_economy_policy.bind(String(metal_policy[0]),float(metal_policy[1])))
			metal_policy_row.add_child(metal_policy_button)
	var accounting_audit:Dictionary=exchange_metrics.get("accounting_audit",{})
	if not accounting_audit.is_empty():
		var audit_label:=Label.new()
		audit_label.text="ACCOUNTS VERIFIED" if bool(accounting_audit.get("ok",false)) else "ACCOUNT WARNING  "+"; ".join(accounting_audit.get("violations",[]))
		audit_label.add_theme_font_size_override("font_size",9)
		audit_label.add_theme_color_override("font_color",Color("#71977d") if bool(accounting_audit.get("ok",false)) else Color("#bd6558"))
		flow_column.add_child(audit_label)
	if GameState.economy_stage!=EconomySystem.STAGE_SUBSISTENCE and EconomySystem.active_external_trade_partner_count()>0:
		var external_trade:Dictionary=exchange_metrics.get("external_trade",{})
		var trade_label:=Label.new()
		trade_label.text="FOREIGN CONTRACTS %d  •  %s  •  CLAIMS %.1f / %.1f limit  •  TODAY +%.1f exports / −%.1f imports\nCUMULATIVE %.1f export claims / %.1f import spending / %.1f losses  •  FOOD IMPORT DEPENDENCE %d%%" % [EconomySystem.active_external_trade_partner_count(),GameState.external_trade_policy.replace("_"," ").to_upper(),GameState.external_trade_credit,float(external_trade.get("claim_limit",0.0)),float(external_trade.get("exports",0.0)),float(external_trade.get("imports",0.0)),GameState.external_trade_exports,GameState.external_trade_imports,GameState.external_trade_losses,roundi(float(GameState.simulation_metrics.get("food_import_share",0.0))*100.0)]
		trade_label.tooltip_text="Regional imports must be funded by prior or same-day exports. Trade friction reduces export proceeds; domestic currency is not assumed to be foreign money."
		trade_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		trade_label.add_theme_font_size_override("font_size",9)
		trade_label.add_theme_color_override("font_color",Color("#829da1"))
		flow_column.add_child(trade_label)
		var trade_policy_button:=Button.new()
		trade_policy_button.text="TRADE: "+GameState.external_trade_policy.replace("_"," ").to_upper()
		trade_policy_button.tooltip_text=_economy_policy_preview_text("TRADE",0.0)
		trade_policy_button.pressed.connect(_apply_economy_policy.bind("TRADE",0.0))
		flow_column.add_child(trade_policy_button)
	var exchange_mix:Dictionary=exchange_metrics.get("exchange_mix",{})
	if not exchange_mix.is_empty():
		var mix_parts:Array[String]=[]
		for channel in ["public_allocation","reciprocity","barter","weighed_metal","recorded_credit","currency"]:
			var share:=float(exchange_mix.get(channel,0.0))
			if share<0.005: continue
			mix_parts.append("%s %d%%" % [String(channel).replace("_"," ").capitalize(),roundi(share*100.0)])
		var mix_label:=Label.new()
		mix_label.text="  •  ".join(mix_parts)
		mix_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		mix_label.add_theme_font_size_override("font_size",9)
		mix_label.add_theme_color_override("font_color",Color("#8fa19c"))
		flow_column.add_child(mix_label)
	for quote_variant in EconomySystem.known_market_snapshot():
		var market_quote:Dictionary=quote_variant
		var price_change:=(float(market_quote.unit_value)/maxf(0.001,float(market_quote.base_value))-1.0)*100.0
		var price_line:=Label.new()
		price_line.text="%s  •  %.2f / unit  •  %+.0f%% vs reference  •  %+.1f%% / 30d  •  %.1f stored" % [String(market_quote.resource).to_upper(),float(market_quote.unit_value),price_change,float(market_quote.get("trend_30d",0.0))*100.0,float(market_quote.stock)]
		price_line.add_theme_font_size_override("font_size",10)
		price_line.add_theme_color_override("font_color",Color("#b9b4a7"))
		flow_column.add_child(price_line)
	var benchmark:=EconomySystem.benchmark_status()
	_add_provision_section_title(flow_column,"NEXT BENCHMARK",String(benchmark.next_stage))
	for requirement_variant in benchmark.requirements:
		var requirement:Dictionary=requirement_variant
		var met:=float(requirement.value)>=float(requirement.target)
		var requirement_line:=Label.new()
		requirement_line.text="%s  %s  %.2f / %.2f" % ["✓" if met else "○",String(requirement.name),float(requirement.value),float(requirement.target)]
		requirement_line.add_theme_font_size_override("font_size",10)
		requirement_line.add_theme_color_override("font_color",Color("#7fa27c") if met else Color("#a39a89"))
		flow_column.add_child(requirement_line)
	if GameState.economy_stage==EconomySystem.STAGE_CURRENCY:
		var military_upkeep:=float(exchange_metrics.get("military_upkeep_due",0.0))
		var currency_liquidity:Dictionary=exchange_metrics.get("currency_liquidity",{})
		var liquidity_label:=Label.new()
		liquidity_label.text="CURRENCY CONFIDENCE %d%%  •  ACTIVE HOUSEHOLD %.1f / %.1f issued (%d%%)\nTREASURY %.1f  •  HOARDS %.1f (%d%%)  •  MUTUAL AID %.1f  •  TODAY +%.2f hoarded / −%.2f released" % [roundi(float(currency_liquidity.get("confidence",0.0))*100.0),float(exchange_metrics.get("transactional_money",GameState.private_currency)),GameState.currency_supply,roundi(float(currency_liquidity.get("transactional_share",0.0))*100.0),GameState.public_treasury,GameState.currency_hoards,roundi(float(currency_liquidity.get("hoard_share",0.0))*100.0),GameState.mutual_aid_reserve,float(currency_liquidity.get("hoarded_today",0.0)),float(currency_liquidity.get("released_today",0.0))]
		liquidity_label.tooltip_text="Only active household currency currently funds purchases, taxes, and private lending. Treasury balances enter circulation when spent; hoards return when confidence improves; mutual-aid reserves return through relief. All four accounts remain part of conserved supply."
		liquidity_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		liquidity_label.add_theme_font_size_override("font_size",9)
		liquidity_label.add_theme_color_override("font_color",Color("#a68d72"))
		flow_column.add_child(liquidity_label)
		var credit_label:=Label.new()
		credit_label.text="PRIVATE CREDIT %.2f / %.2f capacity  •  DEFAULT RATE %.2f%%  •  WEALTH GINI %d%%" % [GameState.credit_outstanding,float(exchange_metrics.get("credit_limit",0.0)),float(exchange_metrics.get("default_rate",0.0))*100.0,roundi(float(exchange_metrics.get("inequality",0.0))*100.0)]
		credit_label.add_theme_font_size_override("font_size",9)
		credit_label.add_theme_color_override("font_color",Color("#9c879b"))
		flow_column.add_child(credit_label)
		var mutual_aid:Dictionary=exchange_metrics.get("mutual_aid",{})
		if bool(mutual_aid.get("active",false)):
			var aid_label:=Label.new()
			aid_label.text="MUTUAL AID %.2f / %.2f capacity  •  +%.2f contributions  •  −%.2f relief" % [GameState.mutual_aid_reserve,float(mutual_aid.get("capacity",0.0)),float(mutual_aid.get("contribution",0.0)),float(mutual_aid.get("payout",0.0))]
			aid_label.add_theme_font_size_override("font_size",9)
			aid_label.add_theme_color_override("font_color",Color("#839f8b"))
			flow_column.add_child(aid_label)
		var fiscal_outlook:Dictionary=exchange_metrics.get("fiscal_outlook",{})
		var fiscal_label:=Label.new()
		fiscal_label.text="LEVY %.0f%%  •  EFFECTIVE %.1f%%  •  COMPLIANCE %d%%  •  REVENUE %.2f  •  COLLECTION GAP %.2f\nCIVIL DUE %.2f  •  MILITARY DUE %.2f  •  ARREARS %.2f  •  BALANCE %+.2f\nPUBLIC DEBT %.2f / %.2f capacity  •  BORROWED %.2f  •  DEBT SERVICE %.2f\nFISCAL %s  •  PRIORITY %s  •  30-DAY COVER %d%%  •  CIV/MIL %d%%/%d%%\nFREE HEADROOM %.2f  •  14-DAY BUFFER %.2f  •  RUNWAY %.0f days" % [GameState.tax_rate*100.0,float(exchange_metrics.get("effective_tax_rate",0.0))*100.0,roundi(float(exchange_metrics.get("tax_compliance",0.0))*100.0),float(exchange_metrics.get("tax_revenue",0.0)),float(exchange_metrics.get("tax_noncompliance_gap",0.0))+float(exchange_metrics.get("tax_liquidity_gap",0.0)),float(exchange_metrics.get("civil_upkeep_due",0.0)),military_upkeep,float(exchange_metrics.get("public_arrears",0.0)),float(exchange_metrics.get("fiscal_balance",0.0)),GameState.public_debt,float(exchange_metrics.get("debt_capacity",0.0)),float(exchange_metrics.get("public_borrowing",0.0)),float(exchange_metrics.get("debt_service",0.0)),String(fiscal_outlook.get("status","unmeasured")).to_upper(),String(fiscal_outlook.get("spending_priority",GameState.public_spending_priority)).replace("_"," ").to_upper(),roundi(float(fiscal_outlook.get("coverage_ratio",0.0))*100.0),roundi(float(fiscal_outlook.get("civil_coverage",1.0))*100.0),roundi(float(fiscal_outlook.get("military_coverage",1.0))*100.0),float(fiscal_outlook.get("discretionary_headroom",0.0)),float(fiscal_outlook.get("protected_buffer",0.0)),float(fiscal_outlook.get("runway_days",0.0))]
		fiscal_label.tooltip_text="Statutory levy is filtered through administrative reach, legitimacy, institutions, records, inequality, arrears, high-rate resistance, and available household currency. The fiscal outlook then projects visible receipts and obligations. The protected buffer is fourteen days of gross obligations; it is guidance, not money removed from the treasury.\n%s" % String(fiscal_outlook.get("warning","No forecast is available yet."))
		fiscal_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		fiscal_label.add_theme_font_size_override("font_size",9)
		fiscal_label.add_theme_color_override("font_color",Color("#b6a978"))
		flow_column.add_child(fiscal_label)
		var policy_row:=HBoxContainer.new()
		policy_row.add_theme_constant_override("separation",4)
		flow_column.add_child(policy_row)
		for policy_variant in [["LEVY −",-0.01],["LEVY +",0.01],["SPENDING",0.0],["BACK METAL",maxf(1.0,GameState.population_exact*0.05)],["RELEASE METAL",maxf(1.0,GameState.population_exact*0.05)],["ISSUE",maxf(1.0,GameState.population_exact*0.10)],["RETIRE",-maxf(1.0,GameState.population_exact*0.05)]]:
			var policy:Array=policy_variant
			var policy_button:=Button.new()
			policy_button.text=String(policy[0])
			policy_button.tooltip_text=_economy_policy_preview_text(String(policy[0]),float(policy[1]))
			policy_button.pressed.connect(_apply_economy_policy.bind(String(policy[0]),float(policy[1])))
			policy_row.add_child(policy_button)
	var stores_column:=VBoxContainer.new()
	stores_column.custom_minimum_size=Vector2(340,0)
	stores_column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	stores_column.add_theme_constant_override("separation",7)
	columns.add_child(stores_column)
	_add_provision_section_title(stores_column,"MATERIAL STORAGE CAPACITY","Different materials need different physical storage.")
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
	_constrain_modal_labels(root)


func _constrain_modal_labels(root:Node)->void:
	# Long live-data strings must wrap inside their assigned column instead of
	# increasing the container's minimum width and pushing controls off-screen.
	for child in root.get_children():
		if child is Label:
			var label:=child as Label
			label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
			label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		_constrain_modal_labels(child)

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

func _apply_economy_policy(action:String,amount:float)->void:
	if action.begins_with("LEVY"):
		EconomySystem.set_tax_rate(GameState.tax_rate+amount)
	elif action=="ISSUE":
		EconomySystem.issue_currency(amount,"Sovereign issue")
	elif action=="RETIRE":
		EconomySystem.retire_currency(absf(amount),"Sovereign retirement")
	elif action=="BACK METAL":
		EconomySystem.commit_metal_to_reserve(amount,"Sovereign reserve commitment")
	elif action=="RELEASE METAL":
		EconomySystem.release_surplus_reserve(amount,"Sovereign surplus reserve release")
	elif action=="METAL TO TRADE":
		EconomySystem.place_weighed_metal_in_circulation(amount,"Sovereign weighed-metal placement")
	elif action=="WITHDRAW TRADE METAL":
		EconomySystem.withdraw_weighed_metal(amount,"Sovereign weighed-metal withdrawal")
	elif action=="SPENDING":
		EconomySystem.cycle_public_spending_priority()
	elif action=="TRADE":
		EconomySystem.cycle_external_trade_policy()
	_open_materials_panel.call_deferred()

func _economy_policy_preview_text(action:String,amount:float)->String:
	var preview:Dictionary=EconomySystem.preview_policy(action,amount)
	var after:Dictionary=preview.get("after",{})
	var fiscal_outlook:Dictionary=after.get("fiscal_outlook",{})
	return "%s\nAccepted now: %.1f. After action — uncommitted metal %.1f value; weighed exchange %.1f; reserve %.1f (%.1f issue ceiling); supply %.1f; active household %.1f (%d%%); treasury %.1f; levy %.0f%%; trade %s.\nFiscal %s, %s priority: %.1f free above the 14-day buffer; %d%% total coverage; civil %d%% / military %d%%; %d%% tax compliance and %.1f%% effective levy.\n%s" % [
		String(preview.get("reason","No forecast available.")),
		float(preview.get("accepted",0.0)),
		float(after.get("available_metal",0.0)),
		float(after.get("circulating_metal",0.0)),
		float(after.get("reserve",0.0)),
		float(after.get("issue_ceiling",0.0)),
		float(after.get("money_supply",0.0)),
		float(after.get("transactional_money",0.0)),
		roundi(float(after.get("transactional_share",0.0))*100.0),
		float(after.get("treasury",0.0)),
		float(after.get("tax_rate",0.0))*100.0,
		String(after.get("trade_policy",GameState.external_trade_policy)).replace("_"," "),
		String(fiscal_outlook.get("status","unmeasured")),
		String(fiscal_outlook.get("spending_priority",GameState.public_spending_priority)).replace("_"," "),
		float(fiscal_outlook.get("discretionary_headroom",0.0)),
		roundi(float(fiscal_outlook.get("coverage_ratio",0.0))*100.0),
		roundi(float(fiscal_outlook.get("civil_coverage",1.0))*100.0),
		roundi(float(fiscal_outlook.get("military_coverage",1.0))*100.0),
		roundi(float(fiscal_outlook.get("tax_compliance",0.0))*100.0),
		float(fiscal_outlook.get("effective_tax_rate",0.0))*100.0,
		String(preview.get("warning",""))
	]

func _effect_ripple_text(effects:Dictionary,realization:float=1.0)->String:
	var names={"tool_quality":"tool quality","construction_rate":"construction","food_output":"food output","foraging_yield":"foraging","hunting_yield":"hunting","cultivation_yield":"cultivation","food_spoilage":"spoilage","food_storage":"food stores","nutrition_quality":"diet quality","soil_productivity":"soil fertility","health_protection":"health","water_safety":"water safety","disease_exposure":"disease exposure","maternal_safety":"maternal safety","neonatal_survival":"newborn survival","conception_support":"birth conditions","injury_risk":"injury risk","labor_efficiency":"labor efficiency","labor_demand":"labor burden","task_coordination":"coordination","haul_capacity":"carrying","route_speed":"travel","trade_capacity":"trade","state_capacity":"governance","legitimacy":"legitimacy","cohesion":"cohesion","warfare_readiness":"military power","security_efficiency":"security","knowledge_rate":"discovery","knowledge_preservation":"memory","observation_rate":"observation","adoption_rate":"spread of practice","ecology_recovery":"land recovery","ecological_pressure":"land pressure","pollution":"pollution","disaster_risk":"accident risk","mine_safety":"mine safety","craft_output":"workshops","housing_output":"housing","repair_capacity":"repair","standardization":"standards","fuel_efficiency":"fuel efficiency","metal_yield":"metal output","timber_yield":"timber output","stone_yield":"stone output"}
	var ripples:Array[String]=[]
	for effect_name in effects:
		if not names.has(effect_name): continue
		var amount:=float(effects[effect_name])*clampf(realization,0.0,1.0)
		var percent:=absf(amount)*100.0
		var percent_text:=("<0.1%" if percent<0.05 and percent>0.0 else ("%.1f%%" % percent if percent<9.95 else "%d%%" % roundi(percent)))
		# The sign describes the actual quantity. The old good/bad triangle displayed a
		# reduction in land pressure as an upward arrow, then rounded 0.18% to 0%, making
		# a useful discovery look both backwards and inert.
		var sign_text:="+" if amount>0.0 else ("−" if amount<0.0 else "±")
		ripples.append("%s%s %s" % [sign_text,percent_text,String(names[effect_name])])
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


func _make_provision_dashboard_column(parent:Container,title_text:String,note_text:String)->VBoxContainer:
	var panel:=PanelContainer.new()
	panel.custom_minimum_size=Vector2(280,0)
	panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical=Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel",_knowledge_style(Color("#0e1718"),Color("#2f3b37"),1,3,10))
	parent.add_child(panel)
	var column:=VBoxContainer.new()
	column.add_theme_constant_override("separation",5)
	panel.add_child(column)
	_add_provision_section_title(column,title_text,note_text)
	return column


func _add_compact_provision_text(parent:Container,title_text:String,body_text:String,color:Color)->Label:
	var title:=Label.new()
	title.text=title_text
	title.add_theme_font_size_override("font_size",10)
	title.add_theme_color_override("font_color",Color("#d8c99f"))
	parent.add_child(title)
	var body:=Label.new()
	body.text=body_text
	body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	body.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	body.add_theme_font_size_override("font_size",10)
	body.add_theme_color_override("font_color",color)
	parent.add_child(body)
	return body


func _provisions_source_summary(metrics:Dictionary)->String:
	var lines:Array[String]=[]
	for source_variant in (metrics.get("food_sources",[]) as Array):
		var source:Dictionary=source_variant
		lines.append("%s  +%.1f  •  %s" % [String(source.get("name","Source")).capitalize(),float(source.get("produced",0.0)),String(source.get("access","unknown"))])
		if lines.size()>=4: break
	return "\n".join(lines) if not lines.is_empty() else "No production report yet — advance the clock."


func _provisions_consumer_summary(metrics:Dictionary,required:float)->String:
	var demand:Dictionary=metrics.get("food_demand_breakdown",{})
	var entries:Array[Array]=[
		["Children",float(demand.get("children",0.0))],
		["Adults",float(demand.get("adults",0.0))],
		["Elders",float(demand.get("elders",0.0))],
		["Physical work",float(demand.get("labor",0.0))],
		["Pregnancy & infant care",float(demand.get("pregnancy",0.0))+float(demand.get("lactation",0.0))],
		["Founding convoy",float(demand.get("travel",0.0))],
		["Field armies",float(demand.get("army_field",metrics.get("army_provisions_required",0.0)))],
		["Prisoners / occupied relief",float(demand.get("prisoner_custody",0.0))+float(demand.get("occupation_relief",0.0))],
		["Cold-season need",float(demand.get("climate",0.0))]
	]
	var lines:Array[String]=[]
	for entry in entries:
		var amount:=float(entry[1])
		if amount<=0.001 and String(entry[0]) not in ["Children","Adults","Elders"]: continue
		lines.append("%s  %.1f  •  %d%%" % [String(entry[0]),amount,roundi(amount/maxf(0.01,required)*100.0)])
	return "\n".join(lines)


func _provisions_commitment_summary()->String:
	var account:Dictionary=FoodSystem.food_account_snapshot(365)
	var active:Array=account.get("active_mission_provisions",[])
	if active.is_empty(): return "No prepaid scout, diplomat, army, or settlement-convoy provisions are currently away."
	var lines:Array[String]=[]
	for issue_variant in active:
		var issue:Dictionary=issue_variant
		var days_remaining:=maxi(0,int(issue.get("end_day",GameState.elapsed_days))-int(GameState.elapsed_days))
		lines.append("%s  %.1f  •  %d people  •  %dd left" % [String(issue.get("label","Mission")).capitalize(),float(issue.get("amount",0.0)),maxi(0,int(issue.get("personnel",0))),days_remaining])
		if lines.size()>=5: break
	if active.size()>lines.size(): lines.append("+ %d more prepaid commitments" % (active.size()-lines.size()))
	return "\n".join(lines)+"\nWithdrawn once at departure; not charged again daily."


func _open_provisions_detail_overlay()->void:
	if provisions_panel==null or not is_instance_valid(provisions_panel): return
	if provisions_panel.find_child("ProvisionsDetailOverlay",true,false): return
	var overlay:=Control.new()
	overlay.name="ProvisionsDetailOverlay"
	overlay.size=provisions_panel.size
	overlay.mouse_filter=Control.MOUSE_FILTER_STOP
	overlay.z_index=8
	provisions_panel.add_child(overlay)
	var dimmer:=ColorRect.new()
	dimmer.size=overlay.size
	dimmer.color=Color(0.003,0.007,0.008,0.94)
	overlay.add_child(dimmer)
	var modal:=PanelContainer.new()
	modal.size=Vector2(minf(980.0,overlay.size.x-56.0),minf(610.0,overlay.size.y-44.0))
	modal.position=(overlay.size-modal.size)*0.5
	modal.add_theme_stylebox_override("panel",_knowledge_style(Color("#0a1213"),Color("#7f7452"),1,4,16))
	overlay.add_child(modal)
	var root:=VBoxContainer.new()
	root.add_theme_constant_override("separation",7)
	modal.add_child(root)
	var heading_row:=HBoxContainer.new()
	root.add_child(heading_row)
	var heading:=Label.new()
	heading.text="PROVISION DETAILS & HISTORY"
	heading.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	heading.add_theme_font_size_override("font_size",21)
	heading.add_theme_color_override("font_color",Color("#f0e4cd"))
	heading_row.add_child(heading)
	var close:=Button.new()
	close.text="BACK TO DASHBOARD"
	close.custom_minimum_size=Vector2(180,36)
	close.pressed.connect(overlay.queue_free)
	heading_row.add_child(close)
	var scroll:=FIT_CONTENT_PANEL.new()
	scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	var details:=VBoxContainer.new()
	details.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	details.add_theme_constant_override("separation",7)
	scroll.add_child(details)
	var metrics:=GameState.simulation_metrics
	var required:=maxf(0.01,float(metrics.get("food_consumption",GameState.population_exact)))
	_add_provision_section_title(details,"FOOD RESERVES BY KIND","Shelf life and current spoilage; perishables are consumed first.")
	var stock_data:Dictionary=metrics.get("food_stocks",GameState.food_stocks)
	var spoilage_data:Dictionary=metrics.get("food_spoilage_by_type",{})
	var stored_total:=maxf(0.01,float(GameState.resource_stockpiles.get("Food",0.0)))
	for food_type in FoodSystemScript.FOOD_TYPES:
		var amount:=float(stock_data.get(food_type,0.0))
		_add_provision_bar(details,String(food_type).to_upper(),"%.1f rations  •  %.1f days  •  %.1f lost today" % [amount,amount/required,float(spoilage_data.get(food_type,0.0))],amount/stored_total,_food_color(String(food_type)))
	details.add_child(HSeparator.new())
	_add_provision_section_title(details,"30-DAY MOVEMENT","Daily net after meals and spoilage; departure issues are separately identified below.")
	_add_food_trend_chart(details)
	details.add_child(HSeparator.new())
	_add_provision_section_title(details,"ACTIVE PREPAID MISSIONS","These rations left the reserve once at departure.")
	_add_active_food_commitments(details,required)
	details.add_child(HSeparator.new())
	_add_provision_section_title(details,"RECENT WITHDRAWALS","Mission, convoy, diplomatic, military, tribute, and trade issues.")
	var issue_history:Array=GameState.food_issue_history
	if issue_history.is_empty():
		_add_compact_provision_text(details,"NO WITHDRAWALS","No external food issue has been recorded yet.",Color("#777f7a"))
	else:
		var first_issue:=maxi(0,issue_history.size()-12)
		for issue_index in range(issue_history.size()-1,first_issue-1,-1):
			var issue:Dictionary=issue_history[issue_index]
			_add_food_consumer_row(details,String(issue.get("label","External issue")),float(issue.get("amount",0.0)),required,"DAY %d  •  reserve %.1f → %.1f" % [int(issue.get("day",0))+1,float(issue.get("stock_before",0.0)),float(issue.get("stock_after",0.0))])

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


# Every major ledger begins with the same three-line reading order: current
# state, the evidence behind it, and the next useful action. Detail remains in
# the body below instead of competing with the decision at the top.
func _add_modal_action_brief(parent:Container,brief:Dictionary,accent:Color)->Label:
	var panel:=PanelContainer.new()
	panel.add_theme_stylebox_override("panel",_knowledge_style(Color("#10191b"),accent.darkened(0.25),1,3,8))
	parent.add_child(panel)
	var label:=Label.new()
	label.name="ModalActionBrief"
	label.text="STATUS  •  %s\nWHY  •  %s\nNEXT  •  %s" % [String(brief.get("status","No urgent change")),String(brief.get("why","Current records show no dominant pressure.")),String(brief.get("next","No immediate order is required."))]
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size",10)
	label.add_theme_color_override("font_color",Color("#c9c6b8"))
	panel.add_child(label)
	return label


func _provisions_decision_brief(metrics:Dictionary,water:Dictionary,issued_today:float=0.0)->Dictionary:
	var intake:=clampf(float(metrics.get("food_intake_ratio",1.0)),0.0,1.2)
	var water_intake:=clampf(float(water.get("intake_ratio",1.0)),0.0,1.2)
	var stock_change:=float(metrics.get("food_net",0.0))-maxf(0.0,issued_today)
	var forecast:Dictionary=metrics.get("food_forecast_90",{})
	var shortage_day:=int(forecast.get("first_shortage_day",-1))
	if water_intake<0.98:
		return {"status":"DRINKING WATER SHORTFALL","why":"Collection met only %d%% of today’s need." % roundi(water_intake*100.0),"next":"Assign more water collection or secure a recognized river, spring, or stored supply."}
	if intake<0.98:
		return {"status":"FOOD INTAKE SHORTFALL","why":"People received only %d%% of today’s ration need." % roundi(intake*100.0),"next":"Raise food production, reduce external issues, or enact rationing before body reserves fail."}
	if shortage_day>0:
		return {"status":"SHORTAGE FORECAST IN %d DAYS" % shortage_day,"why":"Seasonal production and current use are projected to exhaust the food reserve.","next":"Increase supply or reduce demand now; the forecast worsens before the reserve reaches zero."}
	if stock_change<-0.05:
		var issue_note:=" including %.1f issued for missions or obligations" % issued_today if issued_today>0.0 else ""
		return {"status":"FOOD RESERVE FELL TODAY","why":"The reserve fell by %.1f rations%s." % [absf(stock_change),issue_note],"next":"Check Today’s Supply and Mission Issues below to identify the largest draw."}
	return {"status":"PROVISIONS STABLE","why":"Food and water needs are met and no shortage appears in the 90-day forecast.","next":"No immediate order is required; watch seasonal supply and mission departures."}


func _material_constraint_brief(metrics:Dictionary,accessible_count:int,capacity:float,stored_bulk:float)->Dictionary:
	var extracted:=float(metrics.get("extracted_today",0.0))
	var waiting:=float(metrics.get("at_source",0.0))
	var delivered:=float(metrics.get("delivered_today",0.0))
	if waiting>maxf(5.0,delivered*1.5):
		return {"status":"CARRYING IS THE BOTTLENECK","why":"%.1f bulk waits at sources while only %.1f arrived today." % [waiting,delivered],"next":"Increase Logistics labor, route capacity, or material carriers before adding extraction."}
	if capacity>0.0 and stored_bulk/capacity>0.82:
		return {"status":"STORAGE IS NEAR CAPACITY","why":"%.0f of %.0f aggregate bulk capacity is occupied." % [stored_bulk,capacity],"next":"Build the required storage system or lower extraction priorities until space exists."}
	if accessible_count>0 and extracted<0.1:
		return {"status":"REACHABLE SOURCES ARE IDLE","why":"Known reachable sites produced almost nothing today.","next":"Assign Extraction labor or raise the priority of the material you need."}
	if accessible_count<=0:
		return {"status":"NO SOURCE CAN BE WORKED YET","why":"Known occurrences are not yet reachable or understood well enough to extract.","next":"Survey recognized sources and improve access before assigning extraction labor."}
	return {"status":"MATERIAL FLOW BALANCED","why":"No single extraction, transport, or storage constraint currently dominates.","next":"Set material priorities only when a construction or production need changes."}


func _add_food_consumer_row(parent:Container,label_text:String,amount:float,daily_total:float,note_text:String="")->void:
	var row:=HBoxContainer.new()
	row.add_theme_constant_override("separation",8)
	parent.add_child(row)
	var identity:=Label.new()
	identity.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	identity.text=label_text if note_text=="" else "%s  •  %s" % [label_text,note_text]
	identity.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	identity.add_theme_font_size_override("font_size",11)
	identity.add_theme_color_override("font_color",Color("#c7c3b6") if absf(amount)>0.0001 else Color("#686f6b"))
	row.add_child(identity)
	var value:=Label.new()
	value.custom_minimum_size=Vector2(112,0)
	value.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	value.text="%+.1f  •  %d%%" % [amount,roundi(absf(amount)/maxf(0.01,daily_total)*100.0)] if amount<0.0 else "%.1f  •  %d%%" % [amount,roundi(amount/maxf(0.01,daily_total)*100.0)]
	value.tooltip_text="Adult-equivalent rations • share of one current settlement day"
	value.add_theme_font_size_override("font_size",11)
	value.add_theme_color_override("font_color",Color("#c47662") if amount<0.0 else (Color("#d0b46f") if amount>0.0001 else Color("#686f6b")))
	row.add_child(value)


func _add_active_food_commitments(parent:Container,daily_total:float)->void:
	# Read the same one-time issue ledger that removed the food. This includes
	# scout rations, every envoy's travel provisions regardless of gift type,
	# settlement convoys, and any later aggregate mission category without a
	# second hand-maintained UI path.
	var account:Dictionary=FoodSystem.food_account_snapshot(365)
	var active:Array=account.get("active_mission_provisions",[])
	for issue_variant in active:
		var issue:Dictionary=issue_variant
		var personnel:=maxi(0,int(issue.get("personnel",0)))
		var end_day:=int(issue.get("end_day",GameState.elapsed_days))
		var days_remaining:=maxi(0,end_day-int(GameState.elapsed_days))
		var note_parts:Array[String]=[]
		if personnel>0: note_parts.append("%s people" % _compact_population(personnel))
		note_parts.append("%d days remain" % days_remaining)
		note_parts.append("withdrawn once at departure")
		_add_food_consumer_row(parent,String(issue.get("label","ACTIVE FOOD-BEARING MISSION")).to_upper(),float(issue.get("amount",0.0)),daily_total," • ".join(note_parts))
	if active.is_empty():
		var none:=Label.new()
		none.text="No prepaid food-bearing mission is currently away."
		none.add_theme_font_size_override("font_size",11)
		none.add_theme_color_override("font_color",Color("#777f7a"))
		parent.add_child(none)


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
		var history_entry:Dictionary=history[index]
		var value:=float(history_entry.get("net",0.0))-FoodSystem.issued_on_day(int(history_entry.get("day",-1)))
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
	knowledge_record_mode="discoveries" if not GameState.discovery_log.is_empty() else "active"
	knowledge_record_category="all"
	knowledge_record_page=0
	knowledge_mode_buttons.clear()
	knowledge_discovery_widgets.clear()
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
	eyebrow.text="CHOOSE BROAD PROBLEMS  •  PROJECTS RUN AUTOMATICALLY"
	eyebrow.add_theme_font_size_override("font_size",11)
	eyebrow.add_theme_color_override("font_color",Color("#b9a56c"))
	heading.add_child(eyebrow)
	var title := Label.new()
	title.text = "RESEARCH PRIORITIES"
	title.add_theme_font_size_override("font_size",26)
	title.add_theme_color_override("font_color",Color("#f0e5cf"))
	heading.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "Use + and − to divide the aggregate research workforce. You choose the emphasis; evidence, place, prior findings, and chance determine the discovery."
	subtitle.add_theme_font_size_override("font_size",13)
	subtitle.add_theme_color_override("font_color",Color("#9fa7a2"))
	heading.add_child(subtitle)
	var header_stats:=HBoxContainer.new()
	header_stats.alignment=BoxContainer.ALIGNMENT_END
	header_stats.add_theme_constant_override("separation",8)
	header.add_child(header_stats)
	var assigned:=_research_allocation_total()
	var program_summary:Dictionary=DiscoverySystem.research_program_summary()
	var observers:=int(program_summary.get("researchers",0))
	allocation_value_labels["__observers_stat"]=_make_knowledge_stat(header_stats,"RESEARCHERS",_knowledge_workforce_text(float(observers)),Color("#78a9b2"))
	allocation_value_labels["__committed_stat"]=_make_knowledge_stat(header_stats,"ACTIVE LINES",str(int(program_summary.get("active_lines",0))),Color("#c8a862"))
	allocation_value_labels["__established_stat"]=_make_knowledge_stat(header_stats,"ESTABLISHED",str(GameState.discovery_log.size()),Color("#7fa47c"))
	allocation_value_labels["__mind_stat"]=_make_knowledge_stat(header_stats,"RESEARCH SPEED","%.1f×" % float(program_summary.get("average_line_capacity",0.0)),Color("#9a82b8"))
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
	directions_title.text="SET RESEARCH PRIORITIES"
	directions_title.add_theme_font_size_override("font_size",17)
	directions_title.add_theme_color_override("font_color",Color("#e4dbc8"))
	directions_column.add_child(directions_title)
	research_total_label = Label.new()
	research_total_label.add_theme_font_size_override("font_size",12)
	research_total_label.add_theme_color_override("font_color",Color("#96a9ad"))
	directions_column.add_child(research_total_label)
	var attention_meter:=ProgressBar.new()
	attention_meter.name="AttentionMeter"
	attention_meter.max_value=48
	attention_meter.value=int(program_summary.get("active_lines",0))
	attention_meter.show_percentage=false
	attention_meter.custom_minimum_size=Vector2(0,7)
	attention_meter.add_theme_stylebox_override("background",_knowledge_style(Color("#182226"),Color.TRANSPARENT,0,3,0))
	attention_meter.add_theme_stylebox_override("fill",_knowledge_style(Color("#b99c58"),Color.TRANSPARENT,0,3,0))
	directions_column.add_child(attention_meter)
	var direction_scroll:=FIT_CONTENT_PANEL.new()
	direction_scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	directions_column.add_child(direction_scroll)
	var grid:=GridContainer.new()
	grid.columns=3
	grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation",8)
	grid.add_theme_constant_override("v_separation",8)
	direction_scroll.add_child(grid)
	for dynamic_id in SOCIETY_DYNAMICS:
		var accent:=_knowledge_direction_color(dynamic_id)
		var card:=PanelContainer.new()
		card.custom_minimum_size=Vector2(186,88)
		card.tooltip_text=_dynamic_definition(dynamic_id)
		card.add_theme_stylebox_override("panel",_knowledge_style(Color("#121c1f"),accent.darkened(0.38),1,3,9))
		grid.add_child(card)
		var card_content:=VBoxContainer.new()
		card_content.add_theme_constant_override("separation",2)
		card.add_child(card_content)
		var card_header:=HBoxContainer.new()
		card_header.add_theme_constant_override("separation",3)
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
		name_label.add_theme_font_size_override("font_size",9)
		name_label.add_theme_color_override("font_color",Color("#ddd8ca"))
		card_header.add_child(name_label)
		var value:=Label.new()
		value.custom_minimum_size=Vector2(28,0)
		value.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		value.add_theme_font_size_override("font_size",13)
		value.add_theme_color_override("font_color",accent.lightened(0.28))
		card_header.add_child(value)
		var domain_minus:=Button.new()
		domain_minus.text="−"
		domain_minus.custom_minimum_size=Vector2(28,25)
		domain_minus.tooltip_text="Reduce this broad research emphasis"
		domain_minus.pressed.connect(_change_research_domain_allocation.bind(dynamic_id,-1))
		card_header.add_child(domain_minus)
		var domain_plus:=Button.new()
		domain_plus.text="+"
		domain_plus.custom_minimum_size=Vector2(28,25)
		domain_plus.tooltip_text="Increase this broad research emphasis; programs allocate researchers automatically"
		domain_plus.pressed.connect(_change_research_domain_allocation.bind(dynamic_id,1))
		card_header.add_child(domain_plus)
		var bar:=ProgressBar.new()
		bar.max_value=maxi(1,assigned)
		bar.show_percentage=false
		bar.custom_minimum_size=Vector2(0,6)
		bar.add_theme_stylebox_override("background",_knowledge_style(Color("#1a2528"),Color.TRANSPARENT,0,3,0))
		bar.add_theme_stylebox_override("fill",_knowledge_style(accent,Color.TRANSPARENT,0,3,0))
		card_content.add_child(bar)
		var auto_summary:=Label.new()
		auto_summary.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		auto_summary.max_lines_visible=1
		auto_summary.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
		auto_summary.add_theme_font_size_override("font_size",8)
		auto_summary.add_theme_color_override("font_color",Color("#9aa5a0"))
		card_content.add_child(auto_summary)
		allocation_value_labels["dynamic::"+dynamic_id]={"value":value,"card":card,"accent":accent,"bar":bar,"auto_summary":auto_summary}
		var subcategories:Dictionary=GameState.research_subcategory_allocations.get(dynamic_id,{})
		auto_summary.tooltip_text="Programs automatically choose among: %s" % ", ".join(PackedStringArray(subcategories.keys()))
	var reports_frame:=PanelContainer.new()
	reports_frame.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	reports_frame.add_theme_stylebox_override("panel",_knowledge_style(Color("#0d1518"),Color("#283539"),1,3,14))
	body.add_child(reports_frame)
	var reports := VBoxContainer.new()
	reports.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reports.add_theme_constant_override("separation",6)
	reports_frame.add_child(reports)
	var report_title := Label.new()
	report_title.text = "RESEARCH LIBRARY"
	report_title.add_theme_font_size_override("font_size",17)
	report_title.add_theme_color_override("font_color",Color("#e4dbc8"))
	reports.add_child(report_title)
	var report_subtitle:=Label.new()
	report_subtitle.text="Browse current work or proven discoveries. The list stays compact; open one record only when you want its evidence and full explanation."
	report_subtitle.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	report_subtitle.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	report_subtitle.add_theme_font_size_override("font_size",11)
	report_subtitle.add_theme_color_override("font_color",Color("#87938f"))
	reports.add_child(report_subtitle)
	var mode_row:=HBoxContainer.new()
	mode_row.add_theme_constant_override("separation",6)
	reports.add_child(mode_row)
	var active_mode:=Button.new()
	active_mode.custom_minimum_size=Vector2(150,32)
	active_mode.pressed.connect(_set_knowledge_record_mode.bind("active"))
	mode_row.add_child(active_mode)
	knowledge_mode_buttons["active"]=active_mode
	var discovery_mode:=Button.new()
	discovery_mode.custom_minimum_size=Vector2(170,32)
	discovery_mode.pressed.connect(_set_knowledge_record_mode.bind("discoveries"))
	mode_row.add_child(discovery_mode)
	knowledge_mode_buttons["discoveries"]=discovery_mode
	var category_label:=Label.new()
	category_label.text="FIELD"
	category_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	category_label.add_theme_font_size_override("font_size",10)
	category_label.add_theme_color_override("font_color",Color("#8d9893"))
	mode_row.add_child(category_label)
	knowledge_category_selector=OptionButton.new()
	knowledge_category_selector.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	knowledge_category_selector.custom_minimum_size=Vector2(180,32)
	_populate_knowledge_category_selector()
	knowledge_category_selector.item_selected.connect(_select_knowledge_record_category)
	mode_row.add_child(knowledge_category_selector)
	_update_knowledge_mode_buttons()
	var report_scroll := FIT_CONTENT_PANEL.new()
	report_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
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
	footer_note.text="NO DISCOVERY MICROMANAGEMENT  •  Programs choose viable projects and continue on their own. Change only the broad priority weights when you want a different path."
	footer_note.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	footer_note.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	footer_note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	footer_note.add_theme_font_size_override("font_size",11)
	footer_note.add_theme_color_override("font_color",Color("#8d948f"))
	footer.add_child(footer_note)
	var close := Button.new()
	close.text = "BACK TO CIVILIZATION"
	close.custom_minimum_size=Vector2(130,38)
	close.pressed.connect(_back_to_civilization_from_research)
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

func _make_knowledge_stat(parent: Container,label_text: String,value_text: String,accent: Color) -> Label:
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
	return value


func _knowledge_workforce_text(value:float)->String:
	if value>=1_000_000_000.0: return "%.2fB" % (value/1_000_000_000.0)
	if value>=1_000_000.0: return "%.2fM" % (value/1_000_000.0)
	if value>=10_000.0: return "%.1fK" % (value/1_000.0)
	if value>=100.0: return "%d" % roundi(value)
	if value>=10.0: return "%.1f" % value
	return "%.2f" % value if value<1.0 else "%.1f" % value

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
	var progress:=clampf(float(investigation.get("progress",0.0)),0.0,1.0)
	var emphasis:=int(investigation.get("observer_allocation",0))
	var research_workforce:=float(investigation.get("research_workforce",0.0))
	var accent:=_knowledge_direction_color(direction)
	var panel:=PanelContainer.new()
	panel.add_theme_stylebox_override("panel",_knowledge_style(Color("#111b1e"),accent.darkened(0.50),1,3,10))
	panel.tooltip_text="METHOD  •  %s\n\nON SUCCESS  •  %s" % [String(investigation.get("project_method","Observers compare repeated cases.")),String(investigation.get("unlock_summary","Unlocks a practical method."))]
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
	meta.text="%s  /  %s  •  EVIDENCE %d%%  •  WEIGHT %d  •  ~%s RESEARCHERS" % [direction.to_upper(),subcategory.to_upper(),roundi(progress*100.0),emphasis,_knowledge_workforce_text(research_workforce)]
	meta.clip_text=true
	meta.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	meta.add_theme_font_size_override("font_size",9)
	meta.add_theme_color_override("font_color",accent.lightened(0.15))
	text_column.add_child(meta)
	knowledge_investigation_widgets[investigation_id]={"progress":pulse,"meta":meta}
	var question:=Label.new()
	question.text=String(investigation.get("name","Unresolved question")).to_upper()
	question.clip_text=true
	question.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	question.add_theme_font_size_override("font_size",13)
	question.add_theme_color_override("font_color",Color("#eee3cd"))
	text_column.add_child(question)
	var goal:=Label.new()
	goal.text="QUESTION  •  "+String(investigation.get("project_goal","What practical result can repeated evidence establish?"))
	goal.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	goal.add_theme_font_size_override("font_size",11)
	goal.add_theme_color_override("font_color",Color("#d8d5ca"))
	text_column.add_child(goal)
	var unlock:=Label.new()
	unlock.text="IF PROVEN  •  "+String(investigation.get("unlock_summary","A concrete practice is not known until the evidence holds."))
	unlock.clip_text=true
	unlock.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	unlock.add_theme_font_size_override("font_size",10)
	unlock.add_theme_color_override("font_color",accent.lightened(0.22))
	text_column.add_child(unlock)
	var controls:=HBoxContainer.new()
	controls.add_theme_constant_override("separation",6)
	text_column.add_child(controls)
	var bottleneck:=Label.new()
	var estimated_days:=maxi(1,int(investigation.get("estimated_days",1)))
	var horizon:="%d DAYS" % estimated_days if estimated_days<365 else ("%.1f YEARS" % (float(estimated_days)/365.0) if estimated_days<36500 else "MULTI-GENERATIONAL")
	bottleneck.text="WAITING ON  •  %s  •  ESTIMATED HORIZON %s" % [String(investigation.get("bottleneck","EVIDENCE")),horizon]
	bottleneck.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	bottleneck.clip_text=true
	bottleneck.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	bottleneck.add_theme_font_size_override("font_size",9)
	bottleneck.add_theme_color_override("font_color",Color("#c4ad79"))
	controls.add_child(bottleneck)
	var details:=Button.new()
	details.text="DETAILS"
	details.custom_minimum_size=Vector2(68,24)
	details.add_theme_font_size_override("font_size",9)
	details.tooltip_text="Open the question, method, likely result, current limit, and horizon."
	details.pressed.connect(_open_knowledge_investigation_detail.bind(investigation))
	controls.add_child(details)
	var less:=Button.new()
	less.text="− 1"
	less.disabled=emphasis<=0
	less.custom_minimum_size=Vector2(48,24)
	less.add_theme_font_size_override("font_size",9)
	less.tooltip_text="Reduce this line's priority weight. At zero, it pauses but keeps its validation progress."
	less.pressed.connect(_change_research_allocation.bind(direction,subcategory,-1))
	controls.add_child(less)
	var more:=Button.new()
	more.text="+ 1"
	more.custom_minimum_size=Vector2(48,24)
	more.add_theme_font_size_override("font_size",9)
	more.tooltip_text="Increase this line's priority weight and its share of the civilization's aggregate research workforce."
	more.pressed.connect(_change_research_allocation.bind(direction,subcategory,1))
	controls.add_child(more)

func _open_knowledge_investigation_detail(investigation:Dictionary)->void:
	if knowledge_panel==null or not is_instance_valid(knowledge_panel): return
	var existing:=knowledge_panel.find_child("InvestigationDetailOverlay",false,false)
	if existing: existing.queue_free()
	var overlay:=Control.new()
	overlay.name="InvestigationDetailOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter=Control.MOUSE_FILTER_STOP
	knowledge_panel.add_child(overlay)
	var dimmer:=ColorRect.new()
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.color=Color(0.004,0.007,0.009,0.78)
	dimmer.mouse_filter=Control.MOUSE_FILTER_STOP
	overlay.add_child(dimmer)
	var direction:=String(investigation.get("dynamic",investigation.get("direction","knowledge")))
	var accent:=_knowledge_direction_color(direction)
	var view_size:=get_viewport().get_visible_rect().size
	var modal:=PanelContainer.new()
	modal.size=Vector2(minf(760.0,view_size.x-120.0),minf(520.0,view_size.y-90.0))
	modal.position=(view_size-modal.size)*0.5
	modal.add_theme_stylebox_override("panel",_knowledge_style(Color("#0d1518"),accent.darkened(0.18),1,4,20))
	overlay.add_child(modal)
	var root:=VBoxContainer.new()
	root.add_theme_constant_override("separation",9)
	modal.add_child(root)
	var heading_row:=HBoxContainer.new()
	root.add_child(heading_row)
	var heading:=VBoxContainer.new()
	heading.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	heading_row.add_child(heading)
	var eyebrow:=Label.new()
	eyebrow.text="%s  /  %s" % [direction.to_upper(),String(investigation.get("subcategory","Directed attention")).to_upper()]
	eyebrow.add_theme_font_size_override("font_size",10)
	eyebrow.add_theme_color_override("font_color",accent.lightened(0.18))
	heading.add_child(eyebrow)
	var title:=Label.new()
	title.text=String(investigation.get("name","Unresolved question")).to_upper()
	title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size",21)
	title.add_theme_color_override("font_color",Color("#efe3cc"))
	heading.add_child(title)
	var close_x:=Button.new()
	close_x.text="×"
	close_x.custom_minimum_size=Vector2(38,34)
	close_x.pressed.connect(overlay.queue_free)
	heading_row.add_child(close_x)
	root.add_child(HSeparator.new())
	_add_knowledge_detail_section(root,"QUESTION",String(investigation.get("project_goal","What practical result can repeated evidence establish?")),Color("#d8d5ca"))
	_add_knowledge_detail_section(root,"HOW THEY ARE TESTING IT",String(investigation.get("project_method","Observers compare repeated cases.")),Color("#aeb8b3"))
	_add_knowledge_detail_section(root,"WHAT THIS LINE MAY YIELD",String(investigation.get("unlock_summary","A concrete practice is not known until the evidence holds.")),accent.lightened(0.22))
	var progress:=clampf(float(investigation.get("progress",0.0)),0.0,1.0)
	var emphasis:=int(investigation.get("observer_allocation",0))
	var research_workforce:=float(investigation.get("research_workforce",0.0))
	var estimated_days:=maxi(1,int(investigation.get("estimated_days",1)))
	var horizon:="%d days" % estimated_days if estimated_days<365 else ("%.1f years" % (float(estimated_days)/365.0) if estimated_days<36500 else "multi-generational")
	var status:=Label.new()
	status.text="EVIDENCE %d%%  •  WEIGHT %d  •  ~%s RESEARCHERS  •  %.1f× SPEED  •  WAITING ON %s  •  %s" % [roundi(progress*100.0),emphasis,_knowledge_workforce_text(research_workforce),float(investigation.get("research_capacity_multiplier",0.0)),String(investigation.get("bottleneck","EVIDENCE")),horizon.to_upper()]
	status.add_theme_font_size_override("font_size",11)
	status.add_theme_color_override("font_color",Color("#c4ad79"))
	root.add_child(status)
	var progress_bar:=ProgressBar.new()
	progress_bar.max_value=1.0
	progress_bar.value=progress
	progress_bar.show_percentage=false
	progress_bar.custom_minimum_size=Vector2(0,9)
	progress_bar.add_theme_stylebox_override("background",_knowledge_style(Color("#1b272a"),Color.TRANSPARENT,0,4,0))
	progress_bar.add_theme_stylebox_override("fill",_knowledge_style(accent,Color.TRANSPARENT,0,4,0))
	root.add_child(progress_bar)
	var autonomy_note:=Label.new()
	autonomy_note.text="This project advances automatically. Population and support set its research scale; your priority weight determines its share of that capacity."
	autonomy_note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	autonomy_note.add_theme_font_size_override("font_size",11)
	autonomy_note.add_theme_color_override("font_color",Color("#87938f"))
	root.add_child(autonomy_note)
	var close:=Button.new()
	close.text="RETURN TO THE PROGRAM"
	close.custom_minimum_size=Vector2(210,36)
	close.size_flags_horizontal=Control.SIZE_SHRINK_END
	close.pressed.connect(overlay.queue_free)
	root.add_child(close)

func _add_knowledge_detail_section(parent:Container,heading_text:String,body_text:String,color:Color)->void:
	var heading:=Label.new()
	heading.text=heading_text
	heading.add_theme_font_size_override("font_size",10)
	heading.add_theme_color_override("font_color",Color("#b9a56c"))
	parent.add_child(heading)
	var body:=Label.new()
	body.text=body_text
	body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size",12)
	body.add_theme_color_override("font_color",color)
	parent.add_child(body)


func _knowledge_record_direction(record:Dictionary)->String:
	return String(record.get("dynamic",record.get("direction","knowledge"))).to_lower()


func _knowledge_records_for_mode(mode:String,category:String)->Array[Dictionary]:
	var source:Array=DiscoverySystem.active_investigation_records() if mode=="active" else GameState.discovery_log
	var records:Array[Dictionary]=[]
	for record_variant in source:
		if not record_variant is Dictionary: continue
		var record:Dictionary=record_variant
		if category!="all" and _knowledge_record_direction(record)!=category: continue
		records.append(record)
	return records


func _populate_knowledge_category_selector()->void:
	if knowledge_category_selector==null or not is_instance_valid(knowledge_category_selector): return
	knowledge_category_selector.clear()
	var source:Array=DiscoverySystem.active_investigation_records() if knowledge_record_mode=="active" else GameState.discovery_log
	var counts:Dictionary={}
	for record_variant in source:
		if not record_variant is Dictionary: continue
		var direction:=_knowledge_record_direction(record_variant)
		counts[direction]=int(counts.get(direction,0))+1
	knowledge_category_selector.add_item("ALL FIELDS  •  %d" % source.size())
	knowledge_category_selector.set_item_metadata(0,"all")
	var selected_index:=0
	for dynamic_id in SOCIETY_DYNAMICS:
		var count:=int(counts.get(dynamic_id,0))
		if count<=0: continue
		var index:=knowledge_category_selector.item_count
		knowledge_category_selector.add_item("%s  %s  •  %d" % [_knowledge_direction_icon(dynamic_id),String(dynamic_id).to_upper(),count])
		knowledge_category_selector.set_item_metadata(index,dynamic_id)
		if knowledge_record_category==dynamic_id: selected_index=index
	if knowledge_record_category!="all" and selected_index==0: knowledge_record_category="all"
	knowledge_category_selector.select(selected_index)


func _update_knowledge_mode_buttons()->void:
	if knowledge_mode_buttons.has("active") and is_instance_valid(knowledge_mode_buttons.active):
		(knowledge_mode_buttons.active as Button).text=("●  " if knowledge_record_mode=="active" else "")+"ACTIVE  •  %d" % DiscoverySystem.active_investigation_records().size()
	if knowledge_mode_buttons.has("discoveries") and is_instance_valid(knowledge_mode_buttons.discoveries):
		(knowledge_mode_buttons.discoveries as Button).text=("●  " if knowledge_record_mode=="discoveries" else "")+"DISCOVERIES  •  %d" % GameState.discovery_log.size()


func _set_knowledge_record_mode(mode:String)->void:
	if mode not in ["active","discoveries"]: return
	knowledge_record_mode=mode
	knowledge_record_category="all"
	knowledge_record_page=0
	knowledge_record_signature=""
	_update_knowledge_mode_buttons()
	_populate_knowledge_category_selector()
	_refresh_knowledge_record()


func _select_knowledge_record_category(index:int)->void:
	if knowledge_category_selector==null or index<0 or index>=knowledge_category_selector.item_count: return
	knowledge_record_category=String(knowledge_category_selector.get_item_metadata(index))
	knowledge_record_page=0
	knowledge_record_signature=""
	_refresh_knowledge_record()


func _change_knowledge_record_page(delta:int)->void:
	var count:=_knowledge_records_for_mode(knowledge_record_mode,knowledge_record_category).size()
	var max_page:=maxi(0,ceili(float(count)/float(KNOWLEDGE_RECORD_PAGE_SIZE))-1)
	knowledge_record_page=clampi(knowledge_record_page+delta,0,max_page)
	knowledge_record_signature=""
	_refresh_knowledge_record()


func _add_knowledge_record_pager(parent:Container,total:int)->void:
	if total<=KNOWLEDGE_RECORD_PAGE_SIZE: return
	var max_page:=maxi(0,ceili(float(total)/float(KNOWLEDGE_RECORD_PAGE_SIZE))-1)
	knowledge_record_page=clampi(knowledge_record_page,0,max_page)
	var start:=knowledge_record_page*KNOWLEDGE_RECORD_PAGE_SIZE
	var finish:=mini(total,start+KNOWLEDGE_RECORD_PAGE_SIZE)
	var row:=HBoxContainer.new()
	row.add_theme_constant_override("separation",8)
	parent.add_child(row)
	var status:=Label.new()
	status.text="SHOWING %d–%d OF %d  •  PAGE %d/%d" % [start+1,finish,total,knowledge_record_page+1,max_page+1]
	status.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	status.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	status.add_theme_font_size_override("font_size",10)
	status.add_theme_color_override("font_color",Color("#8e9994"))
	row.add_child(status)
	var previous:=Button.new(); previous.text="PREVIOUS"; previous.disabled=knowledge_record_page<=0; previous.pressed.connect(_change_knowledge_record_page.bind(-1)); row.add_child(previous)
	var next:=Button.new(); next.text="NEXT"; next.disabled=knowledge_record_page>=max_page; next.pressed.connect(_change_knowledge_record_page.bind(1)); row.add_child(next)

func _refresh_knowledge_record()->void:
	if knowledge_record_container==null or not is_instance_valid(knowledge_record_container): return
	var active_investigations:=DiscoverySystem.active_investigation_records()
	var active_ids:Array[String]=[]
	for investigation in active_investigations: active_ids.append(String(investigation.get("id","")))
	var filtered_records:=_knowledge_records_for_mode(knowledge_record_mode,knowledge_record_category)
	var max_page:=maxi(0,ceili(float(filtered_records.size())/float(KNOWLEDGE_RECORD_PAGE_SIZE))-1)
	knowledge_record_page=clampi(knowledge_record_page,0,max_page)
	var signature:="%s|%d|%s|%s|%s|%d|%d" % [",".join(active_ids),GameState.discovery_log.size(),JSON.stringify(GameState.research_subcategory_allocations),knowledge_record_mode,knowledge_record_category,knowledge_record_page,filtered_records.size()]
	if signature!=knowledge_record_signature:
		knowledge_record_signature=signature
		# Keep the compact navigation truthful while research continues behind an
		# open report. This updates counts and available fields without rebuilding
		# the surrounding modal or disturbing the player's selected mode.
		_update_knowledge_mode_buttons()
		_populate_knowledge_category_selector()
		knowledge_investigation_widgets.clear()
		knowledge_discovery_widgets.clear()
		for child in knowledge_record_container.get_children():
			knowledge_record_container.remove_child(child)
			child.queue_free()
		var heading_text:="ACTIVE PROJECTS" if knowledge_record_mode=="active" else "PROVEN DISCOVERIES"
		var heading_color:=Color("#77a6ae") if knowledge_record_mode=="active" else Color("#c2a45e")
		knowledge_record_container.add_child(_knowledge_section_heading(heading_text,str(filtered_records.size()),heading_color))
		if filtered_records.is_empty():
			var empty_text:="No active project matches this field. Set a broad priority or choose ALL FIELDS; viable programs begin and continue automatically." if knowledge_record_mode=="active" else "No proven discovery matches this field yet. Research continues from broad priorities; completed concrete findings appear here automatically."
			_make_knowledge_empty_state(knowledge_record_container,empty_text)
		else:
			var start:=knowledge_record_page*KNOWLEDGE_RECORD_PAGE_SIZE
			var finish:=mini(filtered_records.size(),start+KNOWLEDGE_RECORD_PAGE_SIZE)
			for record_index in range(start,finish):
				if knowledge_record_mode=="active": _make_observation_card(knowledge_record_container,filtered_records[record_index])
				else: _make_discovery_card(knowledge_record_container,filtered_records[record_index])
			_add_knowledge_record_pager(knowledge_record_container,filtered_records.size())
	else:
		if knowledge_record_mode=="active":
			for investigation in active_investigations:
				var id:=String(investigation.get("id",""))
				if not knowledge_investigation_widgets.has(id): continue
				var progress:=clampf(float(investigation.get("progress",0.0)),0.0,1.0)
				var widgets:Dictionary=knowledge_investigation_widgets[id]
				(widgets.progress as ProgressBar).value=progress
				var emphasis:=int(investigation.get("observer_allocation",0))
				var research_workforce:=float(investigation.get("research_workforce",0.0))
				(widgets.meta as Label).text="%s  /  %s  •  EVIDENCE %d%%  •  WEIGHT %d  •  ~%s RESEARCHERS" % [String(investigation.get("dynamic",investigation.get("direction","knowledge"))).to_upper(),String(investigation.get("subcategory","Directed attention")).to_upper(),roundi(progress*100.0),emphasis,_knowledge_workforce_text(research_workforce)]
		else:
			for event in filtered_records:
				var id:=String(event.get("id",""))
				if not knowledge_discovery_widgets.has(id): continue
				var adoption:=DiscoverySystem.adoption(id)
				var widgets:Dictionary=knowledge_discovery_widgets[id]
				(widgets.adoption as Label).text="ADOPTION %d%%" % roundi(adoption*100.0)
				(widgets.bar as ProgressBar).value=adoption
				(widgets.effect as Label).text=_compact_discovery_effect_text(event,adoption)

func _make_discovery_card(parent: Container,event: Dictionary) -> void:
	var direction:=String(event.get("dynamic",event.get("direction","knowledge")))
	var accent:=_knowledge_direction_color(direction)
	var card:=PanelContainer.new()
	card.custom_minimum_size=Vector2(0,78)
	card.add_theme_stylebox_override("panel",_knowledge_style(Color("#141d20"),accent.darkened(0.42),1,3,9))
	parent.add_child(card)
	var row:=HBoxContainer.new()
	row.add_theme_constant_override("separation",10)
	card.add_child(row)
	var dot:=PanelContainer.new()
	dot.custom_minimum_size=Vector2(36,36)
	dot.add_theme_stylebox_override("panel",_knowledge_style(accent.darkened(0.48),accent,1,18,0))
	row.add_child(dot)
	var icon:=Label.new()
	icon.text=_knowledge_direction_icon(direction)
	icon.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	icon.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	icon.add_theme_font_size_override("font_size",10)
	icon.add_theme_color_override("font_color",accent.lightened(0.28))
	dot.add_child(icon)
	var content:=VBoxContainer.new()
	content.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation",2)
	row.add_child(content)
	var meta:=Label.new()
	var event_day:=int(event.get("day",0))+1
	var year:=event_day/365+1
	var day_of_year:=(event_day-1)%365+1
	meta.text="%s  /  %s  •  YEAR %d, DAY %d" % [direction.to_upper(),String(event.get("subcategory","Established practice")).to_upper(),year,day_of_year]
	meta.add_theme_font_size_override("font_size",9)
	meta.add_theme_color_override("font_color",accent.lightened(0.18))
	content.add_child(meta)
	var name:=Label.new()
	name.text=String(event.get("name","Unnamed discovery")).to_upper()
	name.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	name.add_theme_font_size_override("font_size",14)
	name.add_theme_color_override("font_color",Color("#eee3cd"))
	content.add_child(name)
	var discovery_id:=String(event.get("id",""))
	var adoption:=DiscoverySystem.adoption(discovery_id)
	var consequence:=Label.new()
	consequence.text=_compact_discovery_effect_text(event,adoption)
	consequence.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	consequence.add_theme_font_size_override("font_size",10)
	consequence.add_theme_color_override("font_color",Color("#aeb7b1"))
	content.add_child(consequence)
	var status:=VBoxContainer.new()
	status.custom_minimum_size=Vector2(118,0)
	status.add_theme_constant_override("separation",4)
	row.add_child(status)
	var adoption_label:=Label.new()
	adoption_label.text="ADOPTION %d%%" % roundi(adoption*100.0)
	adoption_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	adoption_label.add_theme_font_size_override("font_size",9)
	adoption_label.add_theme_color_override("font_color",accent.lightened(0.18))
	status.add_child(adoption_label)
	var adoption_bar:=ProgressBar.new()
	adoption_bar.max_value=1.0
	adoption_bar.value=adoption
	adoption_bar.show_percentage=false
	adoption_bar.custom_minimum_size=Vector2(0,6)
	adoption_bar.add_theme_stylebox_override("background",_knowledge_style(Color("#202a2c"),Color.TRANSPARENT,0,3,0))
	adoption_bar.add_theme_stylebox_override("fill",_knowledge_style(accent,Color.TRANSPARENT,0,3,0))
	status.add_child(adoption_bar)
	var details:=Button.new()
	details.text="DETAILS"
	details.custom_minimum_size=Vector2(92,28)
	details.tooltip_text="Open the evidence, mechanism, and social consequence for this discovery."
	details.pressed.connect(_open_discovery_detail.bind(event.duplicate(true)))
	status.add_child(details)
	if discovery_id!="": knowledge_discovery_widgets[discovery_id]={"adoption":adoption_label,"bar":adoption_bar,"effect":consequence}


func _compact_discovery_effect_text(event:Dictionary,adoption:float)->String:
	var discovery_id:=String(event.get("id",""))
	var effects:Dictionary=event.get("effects",{})
	if effects.is_empty() and discovery_id!="": effects=DiscoverySystem.discovery_definition(discovery_id).get("effects",{})
	if effects.is_empty(): return "RECORDED PRACTICE  •  NO DIRECT CAPACITY MODIFIER"
	return "NOW  •  %s" % _effect_ripple_text(effects,adoption).to_upper()


func _open_discovery_detail(event:Dictionary)->void:
	if knowledge_panel==null or not is_instance_valid(knowledge_panel): return
	var direction:=_knowledge_record_direction(event)
	var accent:=_knowledge_direction_color(direction)
	var overlay:=Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter=Control.MOUSE_FILTER_STOP
	overlay.z_index=12
	knowledge_panel.add_child(overlay)
	var dimmer:=ColorRect.new(); dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); dimmer.color=Color(0.003,0.008,0.010,0.88); dimmer.mouse_filter=Control.MOUSE_FILTER_STOP; overlay.add_child(dimmer)
	var view_size:=get_viewport().get_visible_rect().size
	var modal:=PanelContainer.new()
	modal.size=Vector2(minf(850.0,view_size.x-100.0),minf(650.0,view_size.y-80.0))
	modal.position=(view_size-modal.size)*0.5
	modal.add_theme_stylebox_override("panel",_knowledge_style(Color("#0d1518"),accent.darkened(0.18),1,4,20))
	overlay.add_child(modal)
	var root:=VBoxContainer.new(); root.add_theme_constant_override("separation",8); modal.add_child(root)
	var heading_row:=HBoxContainer.new(); root.add_child(heading_row)
	var heading:=VBoxContainer.new(); heading.size_flags_horizontal=Control.SIZE_EXPAND_FILL; heading_row.add_child(heading)
	var eyebrow:=Label.new(); eyebrow.text="%s  /  %s" % [direction.to_upper(),String(event.get("subcategory","ESTABLISHED PRACTICE")).to_upper()]; eyebrow.add_theme_font_size_override("font_size",10); eyebrow.add_theme_color_override("font_color",accent.lightened(0.18)); heading.add_child(eyebrow)
	var title:=Label.new(); title.text=String(event.get("name","UNNAMED DISCOVERY")).to_upper(); title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; title.add_theme_font_size_override("font_size",21); title.add_theme_color_override("font_color",Color("#efe3cc")); heading.add_child(title)
	var close_x:=Button.new(); close_x.text="×"; close_x.custom_minimum_size=Vector2(38,34); close_x.pressed.connect(overlay.queue_free); heading_row.add_child(close_x)
	root.add_child(HSeparator.new())
	var discovery_id:=String(event.get("id",""))
	var definition:Dictionary=DiscoverySystem.discovery_definition(discovery_id) if discovery_id!="" else {}
	var adoption:=DiscoverySystem.adoption(discovery_id)
	_add_knowledge_detail_section(root,"WHAT IT CHANGES NOW",_compact_discovery_effect_text(event,adoption).trim_prefix("NOW  •  "),accent.lightened(0.22))
	_add_knowledge_detail_section(root,"WHAT WAS DISCOVERED",String(event.get("causal_mechanism",definition.get("causal_mechanism",event.get("description",definition.get("observation","A repeatable practical relationship was established."))))),Color("#d8d5ca"))
	var evidence:=String(event.get("evidence_method",definition.get("evidence_method","Repeated observations established the result."))).strip_edges()
	if evidence!="": _add_knowledge_detail_section(root,"HOW THEY KNOW",evidence,Color("#aeb8b3"))
	var ability:=String(event.get("ability_reason",definition.get("ability_reason",event.get("operating_capability",definition.get("operating_capability",""))))).strip_edges()
	if ability!="": _add_knowledge_detail_section(root,"WHY THIS IMPROVES CAPABILITY",ability,Color("#bdc4bb"))
	var social:=String(event.get("social_consequence",definition.get("social_consequence",""))).strip_edges()
	if social!="": _add_knowledge_detail_section(root,"SOCIAL CONSEQUENCE",social,Color("#bba77d"))
	var adoption_row:=HBoxContainer.new(); adoption_row.add_theme_constant_override("separation",10); root.add_child(adoption_row)
	var adoption_text:=Label.new(); adoption_text.text="ADOPTION  %d%%" % roundi(adoption*100.0); adoption_text.custom_minimum_size=Vector2(120,0); adoption_text.add_theme_color_override("font_color",accent.lightened(0.20)); adoption_row.add_child(adoption_text)
	var adoption_bar:=ProgressBar.new(); adoption_bar.max_value=1.0; adoption_bar.value=adoption; adoption_bar.show_percentage=false; adoption_bar.size_flags_horizontal=Control.SIZE_EXPAND_FILL; adoption_bar.custom_minimum_size=Vector2(0,8); adoption_bar.add_theme_stylebox_override("background",_knowledge_style(Color("#202a2c"),Color.TRANSPARENT,0,3,0)); adoption_bar.add_theme_stylebox_override("fill",_knowledge_style(accent,Color.TRANSPARENT,0,3,0)); adoption_row.add_child(adoption_bar)
	var close:=Button.new(); close.text="BACK TO LIBRARY"; close.custom_minimum_size=Vector2(170,36); close.size_flags_horizontal=Control.SIZE_SHRINK_END; close.pressed.connect(overlay.queue_free); root.add_child(close)


func _discovery_cause_summary(event:Dictionary)->String:
	var discovery_id:=String(event.get("id",""))
	var definition:Dictionary=DiscoverySystem.discovery_definition(discovery_id) if discovery_id!="" else {}
	var mechanism:=String(event.get("causal_mechanism",definition.get("causal_mechanism",""))).strip_edges()
	var evidence:=String(event.get("evidence_method",definition.get("evidence_method",""))).strip_edges()
	var capability:=String(event.get("operating_capability",definition.get("operating_capability",""))).strip_edges()
	var ability_reason:=String(event.get("ability_reason",definition.get("ability_reason",""))).strip_edges()
	var social_consequence:=String(event.get("social_consequence",definition.get("social_consequence",""))).strip_edges()
	if mechanism=="": mechanism=String(event.get("description",definition.get("observation","A repeatable practical relationship was established."))).strip_edges()
	var lines:Array[String]=["FOUND  •  %s" % mechanism]
	if evidence!="": lines.append("EVIDENCE  •  %s" % evidence)
	if ability_reason!="": lines.append("WHY CAPACITY CHANGED  •  %s" % ability_reason)
	elif capability!="": lines.append("NEW CAPABILITY  •  %s" % capability)
	if social_consequence!="": lines.append("SOCIAL EFFECT  •  %s" % social_consequence)
	return "\n".join(lines)

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

func _change_research_domain_allocation(dynamic_id:String,change:int)->void:
	var current:=maxi(0,int(GameState.research_allocations.get(dynamic_id,0)))
	DiscoverySystem.set_domain_research_priority(dynamic_id,current+change)
	_refresh_research_allocations()
	_refresh_knowledge_record()

func _change_research_allocation(dynamic_id:String,subcategory:String,change:int)->void:
	# Legacy save/test adapter. The playable UI exposes only macro domains; changing a
	# domain immediately lets the automatic program redistribute its researchers.
	var subcategories:Dictionary=GameState.research_subcategory_allocations.get(dynamic_id,{})
	var current:=int(subcategories.get(subcategory,0))
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
	var program_summary:Dictionary=DiscoverySystem.research_program_summary()
	var observers:=int(program_summary.get("researchers",0))
	if allocation_value_labels.has("__observers_stat"):
		(allocation_value_labels["__observers_stat"] as Label).text=_knowledge_workforce_text(float(observers))
	if allocation_value_labels.has("__committed_stat"):
		(allocation_value_labels["__committed_stat"] as Label).text=str(int(program_summary.get("active_lines",0)))
	if allocation_value_labels.has("__established_stat"):
		(allocation_value_labels["__established_stat"] as Label).text=str(GameState.discovery_log.size())
	if allocation_value_labels.has("__mind_stat"):
		(allocation_value_labels["__mind_stat"] as Label).text="%.1f×" % float(program_summary.get("average_line_capacity",0.0))
	for dynamic_id in GameState.research_subcategory_allocations:
		var dynamic_total:=0
		var subcategories:Dictionary=GameState.research_subcategory_allocations[dynamic_id]
		var automatic_lines:Array[String]=[]
		for subcategory in subcategories:
			var subvalue:=int(subcategories[subcategory]); dynamic_total+=subvalue
			if subvalue>0: automatic_lines.append("%s%s" % [String(subcategory)," ×%d" % subvalue if subvalue>1 else ""])
			var channel:="%s::%s" % [dynamic_id,subcategory]
			if allocation_value_labels.has(channel):
				var sublabel:=allocation_value_labels[channel].value as Label
				var active_id:=String(GameState.active_investigations.get(channel,""))
				sublabel.text=str(subvalue)
				sublabel.add_theme_color_override("font_color",Color("#9fa8a4") if subvalue>0 and active_id=="" else Color("#d5d2c8"))
				sublabel.tooltip_text="This research priority is waiting through a genuine evidence drought and will redirect automatically when a supported line appears." if subvalue>0 and active_id=="" else "An automatically selected investigation is accumulating evidence." if active_id!="" else "No research capacity is currently emphasizing this subcondition."
		GameState.research_allocations[dynamic_id]=dynamic_total
		var dynamic_key:="dynamic::"+String(dynamic_id)
		if allocation_value_labels.has(dynamic_key):
			var widgets:Dictionary=allocation_value_labels[dynamic_key]
			(widgets.value as Label).text=str(dynamic_total)
			(widgets.bar as ProgressBar).max_value=maxi(1,total)
			(widgets.bar as ProgressBar).value=dynamic_total
			(widgets.auto_summary as Label).text=("AUTO • %s" % "  •  ".join(automatic_lines)) if not automatic_lines.is_empty() else "AUTO • Not emphasized"
			(widgets.card as PanelContainer).modulate=Color.WHITE if dynamic_total>0 else Color(0.68,0.71,0.70,1.0)
	if research_total_label:
		var active_lines:=int(program_summary.get("active_lines",0))
		research_total_label.text="%s aggregate researchers  •  %d automatic programs  •  %d broad emphasis points  •  %.1f× average program capacity" % [_knowledge_workforce_text(float(observers)),active_lines,total,float(program_summary.get("average_line_capacity",0.0))]
		var meter:=knowledge_panel.find_child("AttentionMeter",true,false) as ProgressBar if knowledge_panel else null
		if meter:
			meter.max_value=48
			meter.value=active_lines

func _open_council_panel() -> void:
	AdvisorSystem.refresh_pronouncement_statuses()
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
	title.text = "COUNCIL DIRECTIVES & DECISIONS"
	title.add_theme_font_size_override("font_size",25)
	root.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "Make consequential choices and issue standing policies. Routine updates stay in their population, economy, military, and world records."
	subtitle.add_theme_color_override("font_color",Color("#aaa99f"))
	root.add_child(subtitle)
	var interpreter_config:=PronouncementInterpreter.configuration_status()
	var interpreter_config_label:=Label.new()
	interpreter_config_label.name="InterpreterConfigLabel"
	if bool(interpreter_config.get("configured",false)):
		interpreter_config_label.text="POLICY INTERPRETATION  •  ASSISTED"
		interpreter_config_label.add_theme_color_override("font_color",Color("#82a69a"))
	else:
		interpreter_config_label.text="POLICY INTERPRETATION  •  LOCAL RULES"
		interpreter_config_label.add_theme_color_override("font_color",Color("#a89a7e"))
	interpreter_config_label.tooltip_text="%s interpretation is active. Every freeform directive remains bounded by simulated institutions and known policy effects. Credentials are never displayed or stored in a directive." % ("Assisted" if bool(interpreter_config.get("configured",false)) else "Local deterministic")
	interpreter_config_label.add_theme_font_size_override("font_size",10)
	root.add_child(interpreter_config_label)
	root.add_child(HSeparator.new())
	var scroll := FIT_CONTENT_PANEL.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	var reports := VBoxContainer.new()
	reports.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reports.add_theme_constant_override("separation",12)
	scroll.add_child(reports)
	var decision_items:Array[Dictionary]=AdvisorSystem.council_decision_items()
	var routine_count:=AdvisorSystem.routine_report_count()
	_add_council_decisions_section(reports,decision_items,routine_count)
	reports.add_child(HSeparator.new())
	var active_heading:=Label.new()
	active_heading.text="POLICIES IN FORCE"
	active_heading.add_theme_font_size_override("font_size",13)
	active_heading.add_theme_color_override("font_color",Color("#c8ad72"))
	reports.add_child(active_heading)
	var governance_metrics:Dictionary=ConsequenceEngine.governance_metrics()
	var governance_line:=Label.new()
	governance_line.text="ADMINISTRATION USED %d%%  •  RECENT POLICY CHANGES %d%%  •  COUNCIL SUPPORT %d%%  •  %d IN FORCE" % [roundi(float(governance_metrics.administrative_load)*100.0),roundi(float(governance_metrics.policy_churn)*100.0),roundi(float(governance_metrics.council_support)*100.0),int(governance_metrics.active_policy_count)]
	governance_line.tooltip_text="Each standing policy occupies administrative capacity. Replacing or rescinding policy early creates churn. Council institutions react from their established priorities; institutional trust, respect, and resentment shape council support and future office execution."
	governance_line.add_theme_font_size_override("font_size",11)
	governance_line.add_theme_color_override("font_color",Color("#9da49c") if float(governance_metrics.policy_churn)<=0.0 else Color("#d19b75"))
	reports.add_child(governance_line)
	var active_policies:Array[Dictionary]=ConsequenceEngine.active_policies()
	if active_policies.is_empty():
		var no_policy:=Label.new()
		no_policy.text="No standing policy is in force because none has been issued or earlier policies have expired. Describe a policy in the field at the bottom to enact one."
		no_policy.add_theme_font_size_override("font_size",13)
		no_policy.add_theme_color_override("font_color",Color("#858c87"))
		reports.add_child(no_policy)
	else:
		for active_policy in active_policies:
			var policy_card:=PanelContainer.new()
			policy_card.add_theme_stylebox_override("panel",_knowledge_style(Color("#10191a"),Color("#31403d"),1,3,10))
			reports.add_child(policy_card)
			var policy_label:=Label.new()
			var observation:=ConsequenceEngine.policy_observation(active_policy)
			var policy_copy:=_council_active_policy_copy(active_policy,observation)
			policy_label.text=String(policy_copy.visible)
			policy_label.tooltip_text=String(policy_copy.details)
			policy_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
			policy_label.add_theme_font_size_override("font_size",12)
			policy_label.add_theme_color_override("font_color",Color("#c7c4b9"))
			policy_card.add_child(policy_label)
	reports.add_child(HSeparator.new())
	var pronouncement_count:=0
	for order_variant in GameState.sovereign_orders:
		var order:Dictionary=order_variant
		if String(order.get("type",""))!="pronouncement": continue
		if pronouncement_count==0:
			var record_heading:=Label.new()
			record_heading.text="RECENT POLICY DIRECTIVES"
			record_heading.add_theme_font_size_override("font_size",13)
			record_heading.add_theme_color_override("font_color",Color("#c8ad72"))
			reports.add_child(record_heading)
		var record:=Label.new()
		var record_copy:Dictionary=_council_pronouncement_copy(order)
		record.text=String(record_copy.visible)
		record.tooltip_text=String(record_copy.details)
		record.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		record.add_theme_font_size_override("font_size",13)
		record.add_theme_color_override("font_color",Color("#c7c4b9"))
		reports.add_child(record)
		if String(order.get("status",""))=="interpreting":
			var cancel_pending:=Button.new()
			cancel_pending.text="WITHDRAW PENDING POLICY"
			cancel_pending.tooltip_text="Withdraw this pronouncement before interpretation applies any standing policy."
			cancel_pending.pressed.connect(_cancel_pending_pronouncement.bind(String(order.get("id","")),String(order.get("request_id",""))))
			reports.add_child(cancel_pending)
		pronouncement_count+=1
		if pronouncement_count>=3: break
	if pronouncement_count>0: reports.add_child(HSeparator.new())
	pronouncement_status_label=Label.new()
	pronouncement_status_label.text="Describe a policy in plain language. The Council will show what changed, how long it lasts, and the first observed result."
	pronouncement_status_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	pronouncement_status_label.add_theme_font_size_override("font_size",11)
	pronouncement_status_label.add_theme_color_override("font_color",Color("#9fa59d"))
	root.add_child(pronouncement_status_label)
	for pending_request_id in pending_pronouncement_inputs:
		var pending_progress:=PronouncementInterpreter.request_progress(String(pending_request_id))
		if not pending_progress.is_empty(): _on_pronouncement_progress(String(pending_request_id),pending_progress)
		break
	var order_row := HBoxContainer.new()
	root.add_child(order_row)
	var order_input := LineEdit.new()
	order_input.placeholder_text = "Describe a policy to enact, change, or end…"
	order_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	order_row.add_child(order_input)
	var send := Button.new()
	send.text = "INTERPRET & ISSUE POLICY"
	send.pressed.connect(_issue_freeform_order.bind(order_input))
	order_input.text_submitted.connect(func(_submitted:String): _issue_freeform_order(order_input))
	order_row.add_child(send)
	var close := Button.new()
	close.text = "BACK TO CIVILIZATION"
	close.pressed.connect(_back_to_civilization_from_council)
	order_row.add_child(close)


func _add_council_decisions_section(parent:Container,decision_items:Array[Dictionary],routine_count:int)->void:
	var heading:=Label.new()
	heading.text="DECIDE NOW  •  %d" % decision_items.size() if not decision_items.is_empty() else "NO DECISION REQUIRED"
	heading.add_theme_font_size_override("font_size",15)
	heading.add_theme_color_override("font_color",Color("#d6b66f") if not decision_items.is_empty() else Color("#8da095"))
	parent.add_child(heading)
	if decision_items.is_empty():
		var empty:=Label.new()
		var routine_suffix:="; %d routine update%s %s already logged there" % [routine_count,"" if routine_count==1 else "s","is" if routine_count==1 else "are"] if routine_count>0 else ""
		empty.text="Nothing here needs a directive because the Council has no consequential choice to offer. Conditions continue in their system records%s. Issue a standing policy below only if you want to change them." % routine_suffix
		empty.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		empty.add_theme_font_size_override("font_size",12)
		empty.add_theme_color_override("font_color",Color("#9ca49e"))
		parent.add_child(empty)
		return
	for item in decision_items:
		var card:=PanelContainer.new()
		card.custom_minimum_size=Vector2(0,92)
		card.add_theme_stylebox_override("panel",_knowledge_style(Color("#121a1c"),Color("#7c6849"),1,3,10))
		parent.add_child(card)
		var content:=VBoxContainer.new()
		content.add_theme_constant_override("separation",5)
		card.add_child(content)
		var is_answered:=String(item.get("status",""))=="answered"
		var recurrence:="  •  UPDATED %d TIMES" % int(item.get("occurrences",1)) if int(item.get("occurrences",1))>1 else ""
		var report:=Label.new()
		report.text="%s  •  %s%s\n%s" % [String(item.get("office","Council")).to_upper(),String(item.get("advisor","Council office")),recurrence,String(item.get("text","A decision is required."))]
		report.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		report.add_theme_font_size_override("font_size",13)
		report.add_theme_color_override("font_color",Color("#d8d3c5"))
		content.add_child(report)
		var response_options:Array=item.get("responses",[])
		if not is_answered:
			var actions:=HBoxContainer.new()
			actions.add_theme_constant_override("separation",6)
			content.add_child(actions)
			for option_variant in response_options:
				var option:Dictionary=option_variant
				var response:=String(option.get("label","Record no policy change"))
				var button:=Button.new()
				button.text="RECORD NO POLICY CHANGE" if response.to_lower() in ["acknowledge","acknowledge the report"] else response.to_upper()
				button.tooltip_text="WHAT CHANGES  •  %s" % String(option.get("ripple","The decision is recorded without a standing policy change."))
				button.pressed.connect(_answer_council.bind(String(item.get("id","")),response))
				actions.add_child(button)
		else:
			var recorded:=Label.new()
			recorded.text="DECISION RECORDED  •  %s" % String(item.get("response",""))
			recorded.add_theme_font_size_override("font_size",11)
			recorded.add_theme_color_override("font_color",Color("#8fa88e"))
			content.add_child(recorded)


func _council_active_policy_copy(policy:Dictionary,observation:Dictionary)->Dictionary:
	var remaining:=maxi(0,ceili(float(policy.get("remaining_days",0.0))))
	var execution:=roundi(float(policy.get("execution_factor",1.0))*100.0)
	var effect_text:=GovernmentPolicyCatalog.formatted_effects(policy.get("effects",{}),float(policy.get("magnitude",0.0)))
	var name:=String(policy.get("id","policy")).replace("_"," ").to_upper()
	var visible:="%s  •  %d DAY%s LEFT  •  %d%% EFFECTIVE\nCHANGES  •  %s\nLATEST OBSERVED  •  %s" % [name,remaining,"" if remaining==1 else "S",execution,effect_text,String(observation.get("summary","A baseline is still being established."))]
	var details:Array[String]=[
		"OFFICE  •  %s" % String(policy.get("office","Council")),
		"EXECUTION  •  %s" % String(policy.get("executor","Council execution")),
		"STRENGTH  •  %d%%" % roundi(float(policy.get("magnitude",0.0))*100.0),
		"ACTION SOURCE  •  %s" % String(policy.get("action_source","deterministic enact reading")),
		"TERMS  •  %s" % String(policy.get("parameter_basis","catalog defaults"))
	]
	if not String(policy.get("interpretation_basis","")).is_empty():
		details.append("GROUNDED READING  •  %d%%  •  “%s”" % [roundi(float(policy.get("interpretation_confidence",1.0))*100.0),String(policy.get("interpretation_basis",""))])
	if not String(policy.get("description","")).is_empty(): details.append("WHY  •  %s" % String(policy.description))
	details.append(String(observation.get("disclaimer","Observed movement is not an isolated causal estimate.")))
	return {"visible":visible,"details":"\n".join(details)}


func _council_pronouncement_copy(order:Dictionary)->Dictionary:
	var parameters:Dictionary=order.get("parameters",{})
	var interpretation:Dictionary=parameters.get("interpretation",{})
	var policies:Array=interpretation.get("policies",[])
	var visible_results:Array[String]=[]
	var detail_lines:Array[String]=[]
	for policy_index in policies.size():
		var policy:Dictionary=policies[policy_index]
		var action:=String(policy.get("action","enact")).to_upper()
		var policy_name:=String(policy.get("id","policy")).replace("_"," ").to_upper()
		var changes:=GovernmentPolicyCatalog.formatted_effects(policy.get("effects",{}),float(policy.get("magnitude",0.0))) if action=="ENACT" else "standing effects end"
		var observation:Dictionary=policy.get("observation",{})
		if policy_index<2:
			var observed:="  •  %s" % String(observation.get("summary","")) if not observation.is_empty() else ""
			visible_results.append("%s %s  •  %s%s" % [action,policy_name,changes,observed])
		detail_lines.append("%s  •  %s  •  %d DAYS  •  %d%% EFFECTIVE" % [action,policy_name,roundi(float(policy.get("days",0.0))),roundi(float(policy.get("execution_factor",1.0))*100.0)])
		detail_lines.append("VARIABLES  •  %s" % changes)
		detail_lines.append("ACTION SOURCE  •  %s" % String(policy.get("action_source","deterministic player-clause reading")))
		detail_lines.append("TERMS  •  %s" % String(policy.get("parameter_basis","catalog defaults")))
		if not String(policy.get("basis","")).is_empty(): detail_lines.append("GROUNDED READING  •  %d%%  •  “%s”" % [roundi(float(policy.get("confidence",1.0))*100.0),String(policy.basis)])
		if not String(policy.get("ripple","")).is_empty(): detail_lines.append("WHY  •  %s" % String(policy.ripple))
	if policies.size()>2: visible_results.append("+%d further policy changes; hover for details" % (policies.size()-2))
	var reactions:Array=order.get("political_reactions",interpretation.get("political_reactions",[]))
	if not reactions.is_empty():
		visible_results.append("COUNCIL RESPONSE  •  %s" % String((reactions[0] as Dictionary).get("summary","Council response recorded.")))
	for reaction_variant in reactions:
		var reaction:Dictionary=reaction_variant
		detail_lines.append("COUNCIL  •  %s  •  trust %+.1f  respect %+.1f  resentment %+.1f" % [String(reaction.get("summary","Response recorded.")),float(reaction.get("trust_delta",0.0))*100.0,float(reaction.get("respect_delta",0.0))*100.0,float(reaction.get("resentment_delta",0.0))*100.0])
	var unresolved:=String(interpretation.get("unresolved",""))
	if not unresolved.is_empty():
		var origin:="PROVIDER INTERPRETATION — NO DIRECT EFFECT" if String(interpretation.get("source",""))=="generative API" else "BOUNDED LOCAL INTERPRETATION"
		visible_results.append("UNRESOLVED  •  %s" % unresolved)
		detail_lines.append("UNRESOLVED  •  %s  •  %s" % [origin,unresolved])
	if visible_results.is_empty() and String(order.get("status",""))=="interpreting":
		var progress:=PronouncementInterpreter.request_progress(String(order.get("request_id","")))
		visible_results.append("RETRY SCHEDULED  •  No policy has been applied yet." if bool(progress.get("retry_scheduled",false)) else "AWAITING BOUNDED INTERPRETATION…")
	var source_text:=String(interpretation.get("source","recorded")).to_upper()
	if String(interpretation.get("source_detail","")).strip_edges()!="": source_text+="  •  "+String(interpretation.source_detail).to_upper()
	detail_lines.push_front("INTERPRETATION  •  %s" % source_text)
	var visible:="DAY %d  •  %s\n“%s”\n%s" % [int(order.get("issued_day",0))+1,String(order.get("status","recorded")).replace("_"," ").to_upper(),String(parameters.get("text","")),"\n".join(visible_results)]
	return {"visible":visible,"details":"\n".join(detail_lines)}


func _answer_council(item_id: String, response: String) -> void:
	AdvisorSystem.respond_to_council_item(item_id,response)
	_open_council_panel()

func _issue_freeform_order(input: LineEdit) -> void:
	if not input.editable: return
	var text := input.text.strip_edges()
	if text.is_empty():
		return
	input.editable=false
	var active_context:Array[Dictionary]=[]
	for policy in ConsequenceEngine.active_policies(): active_context.append({"id":String(policy.get("id","")),"remaining_days":ceili(float(policy.get("remaining_days",0.0)))})
	var context:={"day":int(GameState.elapsed_days),"population":GameState.population_total,"food_days":float(GameState.simulation_metrics.get("food_days",0.0)),"health":GameState.population_health,"known_offices":GameState.leadership_positions.keys(),"active_policies":active_context}
	if not PronouncementInterpreter.interpretation_completed.is_connected(_on_pronouncement_interpreted): PronouncementInterpreter.interpretation_completed.connect(_on_pronouncement_interpreted)
	if not PronouncementInterpreter.interpretation_progress.is_connected(_on_pronouncement_progress): PronouncementInterpreter.interpretation_progress.connect(_on_pronouncement_progress)
	var pending_order:=AdvisorSystem.begin_pronouncement(text)
	var request_id:=PronouncementInterpreter.interpret(text,context)
	pending_order["request_id"]=request_id
	pending_pronouncement_inputs[request_id]={"input":input,"text":text,"submitted_day":int(GameState.elapsed_days),"order":pending_order}
	if travel_status_label: travel_status_label.text="COUNCIL INTERPRETING PRONOUNCEMENT…"
	if pronouncement_status_label: pronouncement_status_label.text="INTERPRETING • The council is translating language into bounded policy…"
	var initial_progress:=PronouncementInterpreter.request_progress(request_id)
	if not initial_progress.is_empty(): _on_pronouncement_progress(request_id,initial_progress)

func _on_pronouncement_progress(request_id:String,status:Dictionary)->void:
	if not pending_pronouncement_inputs.has(request_id): return
	if not pronouncement_status_label or not is_instance_valid(pronouncement_status_label): return
	var stage:=String(status.get("stage","interpreting"))
	match stage:
		"requesting":
			pronouncement_status_label.text="INTERPRETING POLICY  •  attempt %d of %d" % [int(status.get("attempt",1)),int(status.get("max_attempts",2))]
		"retrying":
			pronouncement_status_label.text="INTERPRETATION RETRY  •  attempt %d did not complete  •  trying %d of %d" % [int(status.get("attempt",1)),int(status.get("next_attempt",2)),int(status.get("max_attempts",2))]
		"offline": pronouncement_status_label.text="USING LOCAL RULES  •  No online interpreter is configured; a bounded local reading is in progress."
		"fallback": pronouncement_status_label.text="USING LOCAL RULES  •  The assisted reading failed safely; only the bounded local result can apply."
		"accepted": pronouncement_status_label.text="POLICY UNDERSTOOD  •  validating the bounded effects before they apply…"
		"cancelled": pronouncement_status_label.text="CANCELLED • No standing policy was applied."
		_: pronouncement_status_label.text="INTERPRETING • The council is translating language into bounded policy…"
	pronouncement_status_label.add_theme_color_override("font_color",Color("#c8ad72") if stage in ["accepted","requesting"] else Color("#bca47d") if stage in ["retrying","fallback"] else Color("#9fa59d"))

func _on_pronouncement_interpreted(request_id:String,result:Dictionary)->void:
	var pending:Dictionary=pending_pronouncement_inputs.get(request_id,{})
	var input:LineEdit=pending.get("input")
	pending_pronouncement_inputs.erase(request_id)
	var text:=String(pending.get("text","Sovereign pronouncement"))
	if input and is_instance_valid(input): input.text=""; input.editable=true
	var order:=AdvisorSystem.execute_pronouncement(text,result,pending.get("order",{}))
	order["submitted_day"]=int(pending.get("submitted_day",order.get("issued_day",GameState.elapsed_days)))
	var interpretation:Dictionary=order.get("parameters",{}).get("interpretation",{})
	var policies:Array=interpretation.get("policies",[])
	var ripples:Array[String]=[]
	for policy_variant in policies:
		var policy:Dictionary=policy_variant
		var execution_suffix:=" (execution %d%%)" % roundi(float(policy.get("execution_factor",1.0))*100.0) if String(policy.get("action","enact"))=="enact" else ""
		ripples.append(String(policy.ripple)+execution_suffix)
	var message:="  ".join(ripples)
	if message.is_empty(): message=String(result.get("unresolved","The pronouncement was recorded without an executable simulation effect."))
	if travel_status_label: travel_status_label.text="PRONOUNCEMENT INTERPRETED  •  %s" % message
	if pronouncement_status_label:
		pronouncement_status_label.text="INTERPRETED VIA %s • %s" % [String(interpretation.get("source","interpreter")).to_upper(),message]
		pronouncement_status_label.add_theme_color_override("font_color",Color("#c8ad72"))

func _cancel_pending_pronouncement(order_id:String,request_id:String)->void:
	if not PronouncementInterpreter.cancel(request_id):
		_refresh_council_dock.call_deferred()
		return
	var pending:Dictionary=pending_pronouncement_inputs.get(request_id,{})
	pending_pronouncement_inputs.erase(request_id)
	var input:LineEdit=pending.get("input")
	if input and is_instance_valid(input): input.editable=true
	for order_variant in GameState.sovereign_orders:
		var order:Dictionary=order_variant
		if String(order.get("id",""))!=order_id: continue
		order["status"]="cancelled"
		order["cancelled_day"]=int(GameState.elapsed_days)
		order["parameters"]={"text":String(order.get("parameters",{}).get("text","Sovereign pronouncement")),"interpretation":{"source":"cancelled","source_detail":"Cancelled by Sovereign","summary":"The pronouncement was withdrawn before interpretation.","policies":[],"unresolved":"No standing policy was applied."}}
		break
	if pronouncement_status_label:
		pronouncement_status_label.text="CANCELLED • No standing policy was applied."
		pronouncement_status_label.add_theme_color_override("font_color",Color("#b78c72"))
	_refresh_council_dock.call_deferred()

func _refresh_council_dock()->void:
	## Rebuilds the council view after a pronouncement state change when the
	## dock is showing it.
	if hud and hud.active_section=="civ":
		hud.live_refresh_dock()

func _build_leader_selection(layer: CanvasLayer) -> void:
	_generate_leader_candidates("Steward")
	# Leadership is represented by institutions and delegations, not portraits or
	# simulated office-holding individuals.
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
	leader_heading.text = "SELECT AN INSTITUTIONAL SLATE"
	leader_heading.add_theme_font_size_override("font_size", 24)
	leader_heading.add_theme_color_override("font_color", Color("#ede2cd"))
	root.add_child(leader_heading)
	leader_explanation = Label.new()
	leader_explanation.text = "Five governing arrangements are available. Their influence is measured through the civilization's twelve real dynamics."
	leader_explanation.add_theme_font_size_override("font_size", 14)
	leader_explanation.add_theme_color_override("font_color", Color("#aaa99f"))
	root.add_child(leader_explanation)
	var divider := HSeparator.new()
	root.add_child(divider)
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 18)
	root.add_child(body)
	var candidate_scroll := FIT_CONTENT_PANEL.new()
	candidate_scroll.custom_minimum_size = Vector2(340, 0)
	body.add_child(candidate_scroll)
	leader_candidate_list = VBoxContainer.new()
	leader_candidate_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	leader_candidate_list.add_theme_constant_override("separation", 10)
	candidate_scroll.add_child(leader_candidate_list)
	_rebuild_leader_candidate_list()
	var dossier_scroll := FIT_CONTENT_PANEL.new()
	dossier_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dossier_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
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
	appoint_button.text = "COMMISSION THIS SLATE"
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
		button.text="%s\n%s\n%s • strongest in %s" % [candidate.name,candidate.background,"  /  ".join(candidate.traits),strongest.capitalize()]
		button.alignment=HORIZONTAL_ALIGNMENT_LEFT
		button.add_theme_font_size_override("font_size",13)
		button.tooltip_text="An aggregate governing arrangement. Open the dossier to compare system-wide consequences."
		button.pressed.connect(_inspect_leader.bind(i))
		leader_candidate_list.add_child(button)

func _generate_leader_candidates(office:String) -> void:
	leader_candidates.clear()
	for slate in _institutional_slates_for_office(office):
		leader_candidates.append(_candidate_from_institution(String(slate[0]),String(slate[1]),office))
	AdvisorSystem.register_advisors(leader_candidates)

func _institutional_slates_for_office(office:String)->Array:
	var slates:Dictionary={
		"Steward":[["CIVIC SECRETARIAT","Central administrative service"],["DISTRICT ASSEMBLIES","Federated local administration"],["CENSUS AND WORKS BOARD","Measured population and public works"],["ROTATING CIVIC COUNCIL","Representative rotating authority"],["PROVINCIAL STEWARDSHIP","Territorial administrative network"]],
		"Quartermaster":[["CENTRAL STOREHOUSE BOARD","Centralized provisioning authority"],["DISTRIBUTION GUILDS","Federated supply organizations"],["LOGISTICS DIRECTORATE","Route and inventory administration"],["PROVISIONING COUNCIL","Representative allocation authority"],["REGIONAL DEPOT NETWORK","Distributed material coordination"]],
		"Scholar":[["INQUIRY COLLEGIUM","Expert research institution"],["PUBLIC LEARNING COUNCIL","Distributed education authority"],["ARCHIVE AND SURVEY OFFICE","Evidence and records administration"],["PRACTICAL ARTS ACADEMY","Production-linked knowledge network"],["OBSERVATORIES LEAGUE","Federated scientific institutions"]],
		"Marshal":[["GENERAL STAFF","Central strategic command"],["DEFENSE COUNCIL","Civil-military oversight body"],["REGIONAL COMMANDS","Distributed territorial defense"],["READINESS DIRECTORATE","Training and logistics command"],["CIVIC DEFENSE BOARD","Representative mobilization authority"]],
		"Envoy":[["FOREIGN OFFICE","Central diplomatic service"],["TREATY COUNCIL","Representative negotiation authority"],["EXCHANGE MISSIONS","Trade-linked diplomatic network"],["BORDER COMMISSIONS","Regional external-relations bodies"],["CIVIC DELEGATION","Broad public diplomatic mandate"]]
	}
	return slates.get(office,[["CIVIC COUNCIL","General administrative institution"],["PUBLIC SECRETARIAT","Professional administrative service"],["REGIONAL ASSEMBLIES","Federated representative authority"],["SPECIALIST BOARD","Expert governing body"],["ROTATING DELEGATION","Temporary collective authority"]])

func _candidate_from_institution(institution_name:String,structure:String,office:String)->Dictionary:
	var traits_pool:=["Centralized","Distributed","Representative","Expert-led","Transparent","Disciplined","Adaptive","Localist","Consensus-driven","Directive"]
	var seed:=hash("%d:%s:%s" % [GameState.world_seed,office,institution_name])
	var rng:=RandomNumberGenerator.new()
	rng.seed=seed
	var profile:Dictionary={}
	var subcategory_profile:Dictionary={}
	for dynamic_id in SOCIETY_DYNAMICS:
		var current_capacity:=float(GameState.society_capacities.get(dynamic_id,0.5))
		profile[dynamic_id]=clampf(rng.randf_range(0.30,0.78)+current_capacity*0.08,0.18,0.94)
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
	var skills:=_legacy_skills_from_dynamics(profile)
	var current_culture:=float(GameState.society_capacities.get("culture",0.5))
	var support:=roundi(clampf(0.22+float(profile.culture)*0.34+float(profile.institutions)*0.24+current_culture*0.20,0.18,0.88)*100.0)
	return {"institution_id":"%s:%s" % [office.to_lower(),institution_name.to_lower().replace(" ","_")],"name":institution_name,
		"background":structure,"institutional":true,"traits":[trait_a,trait_b],
		"dynamic_profile":profile,"subcategory_profile":subcategory_profile,"skills":skills,"support":support,"office_fit":fit}

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
	identity.text="%s\n%s\n%s  /  %s" % [String(candidate.name).to_upper(),candidate.background,candidate.traits[0],candidate.traits[1]]
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
	choice_status.text = "%s commissioned for the %s portfolio." % [candidate.name,pending_advisor_office]
	pending_advisor_office = ""
	_open_government_panel()

func _open_leadership_panel() -> void:
	leader_panel.visible = true
	settler_panel.visible = false

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
	subtitle.text = "Offices, authority, political support, and the institutions responsible for executing policy"
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", Color("#aaa99f"))
	root.add_child(subtitle)
	root.add_child(HSeparator.new())
	var scroll := FIT_CONTENT_PANEL.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
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
	close.text = "BACK TO CIVILIZATION"
	close.pressed.connect(_back_to_civilization_from_government)
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
	var seal:=PanelContainer.new()
	seal.custom_minimum_size=Vector2(96,116)
	seal.add_theme_stylebox_override("panel",_knowledge_style(Color("#20282b"),accent.darkened(0.22),1,4,8))
	row.add_child(seal)
	var seal_label:=Label.new()
	seal_label.text=("YOU" if office=="Sovereign" else office.left(3).to_upper()) if occupied else "—"
	seal_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	seal_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	seal_label.add_theme_font_size_override("font_size",20)
	seal_label.add_theme_color_override("font_color",accent.lightened(0.18) if occupied else Color("#626d70"))
	seal.add_child(seal_label)
	var details := Label.new()
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if occupied:
		if office == "Sovereign":
			details.text = "YOU\nEssential Sovereign\n\nIssues final orders and receives all counsel. Cannot be replaced or overruled."
		else:
			var leader: Dictionary = GameState.leadership_positions[office]
			details.text = "%s\n%s\n\n%s • %s\nPolitical base: %s" % [leader.name, leader.background, leader.traits[0], leader.traits[1],_capacity_band(float(leader.support)/100.0)]
	else:
		details.text = "VACANT\n\n%s\n\nNo institution is executing this portfolio." % responsibility
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
		appoint.text = "REVIEW 5 SLATES" if occupied else "VIEW 5 INSTITUTIONAL SLATES"
		appoint.tooltip_text = "Compare five governing arrangements using the twelve society dynamics."
		appoint.pressed.connect(_open_advisor_candidates.bind(office))
		column.add_child(appoint)

func _open_advisor_candidates(office: String) -> void:
	pending_advisor_office = office
	if GameState.society_subcategories.is_empty():
		GameState.society_subcategories=DiscoverySystem.society_model.evaluate_subcategories(_discovery_context())
	_generate_leader_candidates(office)
	_rebuild_leader_candidate_list()
	leader_heading.text = "COMMISSION %s INSTITUTION" % office.to_upper()
	leader_explanation.text="Five institutional arrangements are available for the %s portfolio. Bars show projected influence on the same dynamics that govern the civilization." % office
	appoint_button.text = "COMMISSION FOR %s" % office.to_upper()
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
	var nearest_distance:=_river_distance_at(settler_marker.position.x,settler_marker.position.z)
	var nearest_type:="River water" if nearest_distance<INF else ""
	for site in ResourceSystem.visible_deposits():
		if String(site.get("resource",""))=="Freshwater": continue
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


func _hud_chip_style(accent:Color,hover:=false)->StyleBoxFlat:
	var style:=StyleBoxFlat.new()
	style.bg_color=Color(0.035,0.047,0.050,0.98) if not hover else Color(0.070,0.082,0.080,0.99)
	style.border_color=accent
	style.border_width_left=2
	style.border_width_top=1
	style.border_width_right=1
	style.border_width_bottom=1
	style.corner_radius_top_left=3
	style.corner_radius_top_right=3
	style.corner_radius_bottom_left=3
	style.corner_radius_bottom_right=3
	style.content_margin_left=8
	style.content_margin_right=6
	style.content_margin_top=4
	style.content_margin_bottom=4
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
	var raw_end_day:=int(record.get("end_day",record.get("day",0)))
	if not _demographic_notice_is_current(record,int(floor(GameState.elapsed_days))):
		event_report_button.visible=false
		return
	var start_day:=int(record.get("start_day",record.get("day",0)))+1
	var end_day:=raw_end_day+1
	var period:="DAY %d" % end_day if start_day==end_day else "DAYS %d–%d" % [start_day,end_day]
	var noun:="BIRTH" if kind=="birth" else "DEATH"
	var recorded_cause:=String(record.get("cause","Unknown"))
	var cause_label:="SUPPORTED BY CURRENT CONDITIONS" if kind=="birth" and recorded_cause=="Births" else recorded_cause.to_upper()
	var accent:=Color("#b8a36d") if kind=="birth" else Color("#a95f52")
	var condition:=_demographic_notice_condition_text(record)
	event_report_button.text="POPULATION  •  %s  •  %d %s%s\n%s  •  %s" % [period,count,noun,"" if count==1 else "S",cause_label,condition]
	event_report_button.add_theme_stylebox_override("normal",_population_report_style(accent))
	event_report_button.add_theme_stylebox_override("hover",_population_report_style(accent,true))
	event_report_button.add_theme_stylebox_override("pressed",_population_report_style(accent,true))
	event_report_button.tooltip_text=String(record.get("description","Open the population ledger."))
	var signature:="%s:%d:%d:%d" % [kind,start_day,end_day,count]
	if signature!=event_report_signature:
		event_report_signature=signature
		event_report_visible_until_msec=Time.get_ticks_msec()+_demographic_notice_duration_msec(kind)
	event_report_button.visible=Time.get_ticks_msec()<=event_report_visible_until_msec

func _demographic_notice_is_current(record:Dictionary,current_day:int)->bool:
	var record_day:=int(record.get("end_day",record.get("day",0)))
	return current_day-record_day<=1

func _demographic_notice_duration_msec(kind:String)->int:
	return 18000 if kind=="death" else 12000

func _demographic_notice_condition_text(record:Dictionary)->String:
	return "HEALTH %d%%  •  WATER %d%%  •  SHELTER %d%%" % [roundi(float(record.get("health",0.0))*100.0),roundi(float(record.get("water_intake_ratio",0.0))*100.0),roundi(float(record.get("housing_ratio",0.0))*100.0)]

func _open_civilizations_panel()->void:
	_close_primary_destinations_except("world")
	if civilizations_panel and is_instance_valid(civilizations_panel): return
	CivilizationSystem.initialize()
	var competition:Dictionary=CivilizationSystem.known_competition_snapshot()
	var strategic_knowledge:Dictionary=competition.get("strategic_knowledge",CivilizationSystem.strategic_knowledge_snapshot())
	var observation:Dictionary=CivilizationSystem.local_observation_snapshot()
	civilizations_panel=Control.new()
	civilizations_panel.size=get_viewport().get_visible_rect().size
	civilizations_panel.mouse_filter=Control.MOUSE_FILTER_STOP
	interface_layer.add_child(civilizations_panel)
	var dimmer:=ColorRect.new()
	dimmer.size=civilizations_panel.size
	dimmer.color=Color(0.004,0.008,0.010,0.90)
	civilizations_panel.add_child(dimmer)
	var modal:=PanelContainer.new()
	modal.size=Vector2(minf(1160.0,civilizations_panel.size.x-64.0),minf(650.0,civilizations_panel.size.y-48.0))
	modal.position=(civilizations_panel.size-modal.size)*0.5
	modal.add_theme_stylebox_override("panel",_knowledge_style(Color("#091113"),Color("#8c7951"),1,4,20))
	civilizations_panel.add_child(modal)
	var root:=VBoxContainer.new()
	root.add_theme_constant_override("separation",9)
	modal.add_child(root)
	var heading_row:=HBoxContainer.new()
	root.add_child(heading_row)
	var heading:=Label.new()
	heading.text="WORLD STRATEGY"
	heading.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	heading.add_theme_font_size_override("font_size",24)
	heading.add_theme_color_override("font_color",Color("#efe1c3"))
	heading_row.add_child(heading)
	var standing:=Label.new()
	standing.text="%d CONTACTS  •  %d FORMATIONS IN SIGHT" % [int(competition.get("contacted_count",0)),int(observation.get("visible_count",0))] if bool(competition.get("global_rank_hidden",false)) else "KNOWN RANK %d / %d  •  %d IN SIGHT" % [int(competition.player_rank),int(competition.contender_count),int(observation.get("visible_count",0))]
	standing.add_theme_font_size_override("font_size",14)
	standing.add_theme_color_override("font_color",Color("#cfb66f"))
	heading_row.add_child(standing)
	var knowledge_stage:=int(strategic_knowledge.get("stage",0))
	var contract:=Label.new()
	contract.text="What your people can currently verify from direct sight, contact, and returned reports."
	contract.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	contract.add_theme_font_size_override("font_size",12)
	contract.add_theme_color_override("font_color",Color("#9ea7a2"))
	root.add_child(contract)
	root.add_child(HSeparator.new())
	var body:=HBoxContainer.new()
	body.size_flags_vertical=Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation",14)
	root.add_child(body)
	var rivals_frame:=PanelContainer.new(); rivals_frame.custom_minimum_size=Vector2(330,0); rivals_frame.size_flags_vertical=Control.SIZE_EXPAND_FILL; rivals_frame.add_theme_stylebox_override("panel",_knowledge_style(Color("#0c1517"),Color("#293b3b"),1,4,10)); body.add_child(rivals_frame)
	var rivals:=VBoxContainer.new()
	rivals.custom_minimum_size=Vector2(308,0)
	rivals.add_theme_constant_override("separation",6)
	rivals_frame.add_child(rivals)
	var discovery_map:=WorldDiscoveryMapScript.new()
	discovery_map.custom_minimum_size=Vector2(314,166)
	discovery_map.set_snapshot(CivilizationSystem.discovery_map_snapshot())
	discovery_map.map_point_selected.connect(_focus_known_world_point)
	rivals.add_child(discovery_map)
	var observation_heading:=Label.new()
	observation_heading.text="NEARBY  •  %.0f KM" % float(observation.get("radius_km",0.0))
	observation_heading.add_theme_font_size_override("font_size",12); observation_heading.add_theme_color_override("font_color",Color("#d19b6f")); rivals.add_child(observation_heading)
	var visible_sightings:Array=observation.get("visible",[])
	if visible_sightings.is_empty():
		var quiet:=Label.new(); quiet.text="Nothing foreign is in local sight. This only means the lookout range is clear—not that the surrounding world is empty."; quiet.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; quiet.add_theme_font_size_override("font_size",11); quiet.add_theme_color_override("font_color",Color("#9ea7a2")); rivals.add_child(quiet)
	else:
		for sighting_variant in visible_sightings.slice(0,2):
			var sighting:Dictionary=sighting_variant
			var scout_suffix:="\nFAST • CONCEALED • CARRYING OBSERVATIONS HOME" if bool(sighting.get("carries_report",false)) else ""
			var sighting_card:=Label.new(); sighting_card.text="%s\n~%s–%s PERSONNEL  •  %.0f KM AWAY%s%s" % [String(sighting.get("label","UNIDENTIFIED FOREIGN FORMATION")),_compact_population(int(sighting.get("strength_estimate_low",0))),_compact_population(int(sighting.get("strength_estimate_high",0))),float(sighting.get("distance_km",0.0)),"  •  HOSTILE" if bool(sighting.get("hostile",false)) else "",scout_suffix]; sighting_card.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; sighting_card.add_theme_font_size_override("font_size",11); sighting_card.add_theme_color_override("font_color",Color("#dc806f") if bool(sighting.get("hostile",false)) else Color("#d0b17b")); rivals.add_child(sighting_card)
			if bool(sighting.get("carries_report",false)):
				var interception:Dictionary=sighting.get("interception",{})
				var intercept_actions:=HBoxContainer.new(); intercept_actions.add_theme_constant_override("separation",4); rivals.add_child(intercept_actions)
				var capture_scouts:=Button.new(); capture_scouts.text="SEIZE & QUESTION • %d%%" % roundi(float(interception.get("capture",0.0))*100.0); capture_scouts.tooltip_text="ACTION  Attempt to catch this fast, concealed scout cohort before it leaves sight.\nCONSEQUENCE  Success denies its returning report and creates one aggregate captive cohort for questioning; failure lets it continue home."; capture_scouts.pressed.connect(_intercept_foreign_scout.bind(String(sighting.get("id","")),"capture")); intercept_actions.add_child(capture_scouts)
				var destroy_scouts:=Button.new(); destroy_scouts.text="ATTACK • %d%%" % roundi(float(interception.get("destroy",0.0))*100.0); destroy_scouts.tooltip_text="ACTION  Pursue and attack this scout cohort before it leaves sight.\nCONSEQUENCE  Success kills the party and destroys its report, yields no prisoners or intelligence, and sharply raises foreign grievance."; destroy_scouts.pressed.connect(_intercept_foreign_scout.bind(String(sighting.get("id","")),"destroy")); intercept_actions.add_child(destroy_scouts)
	var captive_scouts:Array=CivilizationSystem.captured_scouts_snapshot()
	if not captive_scouts.is_empty():
		var captive_heading:=Label.new(); captive_heading.text="CAPTURED SCOUT COHORTS  •  INFORMATION DEGRADES"; captive_heading.add_theme_font_size_override("font_size",12); captive_heading.add_theme_color_override("font_color",Color("#d19b6f")); rivals.add_child(captive_heading)
		for cohort_variant in captive_scouts.slice(0,1):
			var cohort:Dictionary=cohort_variant
			var captive_status:=Label.new(); captive_status.text="%s  •  %d HELD  •  KNOWLEDGE REMAINING %d%%" % [String(cohort.get("source_name","FOREIGN POLITY")),int(cohort.get("count",0)),roundi(float(cohort.get("information_remaining",0.0))*100.0)]; captive_status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; captive_status.add_theme_font_size_override("font_size",11); captive_status.add_theme_color_override("font_color",Color("#c9b48a")); rivals.add_child(captive_status)
			var methods:=HBoxContainer.new(); methods.add_theme_constant_override("separation",3); rivals.add_child(methods)
			for method in ["question","coerce","torture"]:
				var interrogation:=Button.new(); interrogation.text={"question":"QUESTION","coerce":"COERCE","torture":"TORTURE"}[method]; interrogation.disabled=not bool(cohort.get("can_interrogate",false)); interrogation.tooltip_text=("BLOCKED  This captive cohort has no usable information remaining.\nNEXT  Intercept another returning scout cohort while it is still inside local lookout range." if interrogation.disabled else {"question":"ACTION  Question the cohort without coercion.\nCONSEQUENCE  Slow and comparatively reliable, with little diplomatic or domestic harm.","coerce":"ACTION  Coerce a statement.\nCONSEQUENCE  More likely to produce a statement but less reliable; raises grievance and harms legitimacy.","torture":"ACTION  Torture the captive cohort.\nCONSEQUENCE  Only 42% reliable; may kill prisoners, contaminate intelligence, inflame grievance, and damage legitimacy and cohesion."}[method]); interrogation.pressed.connect(_interrogate_captured_scouts.bind(String(cohort.get("civ_id","")),method)); methods.add_child(interrogation)
	rivals.add_child(HSeparator.new())
	var rival_heading:=Label.new()
	rival_heading.text="KNOWN CONTACTS  •  %d" % int(competition.get("contacted_count",0))
	rival_heading.add_theme_font_size_override("font_size",12)
	rival_heading.add_theme_color_override("font_color",Color("#c8ad72"))
	rivals.add_child(rival_heading)
	var first_rival_id:=""
	var contact_selector:=OptionButton.new()
	contact_selector.name="KnownContactSelector"
	contact_selector.fit_to_longest_item=false
	contact_selector.custom_minimum_size=Vector2(0,42)
	contact_selector.tooltip_text="Choose one directly known civilization. Unknown civilizations do not appear."
	var selected_contact_index:=0
	for profile_variant in competition.leaders:
		var profile:Dictionary=profile_variant
		if String(profile.id)=="player": continue
		if first_rival_id=="": first_rival_id=String(profile.id)
		var relation:Dictionary=profile.player_relation
		var intel:=clampf(float(profile.get("intel_confidence",0.0)),0.0,1.0)
		var threat_report:=String(profile.get("threat_level","UNCERTAIN")) if intel>=0.32 else "THREAT UNASSESSED"
		contact_selector.add_item("%s  •  %s  •  %s  •  INTEL %d%%" % [String(profile.name),_foreign_relation_label(relation),threat_report,roundi(intel*100.0)])
		var contact_index:=contact_selector.item_count-1
		contact_selector.set_item_metadata(contact_index,String(profile.id))
		contact_selector.set_item_tooltip(contact_index,"Identity and relationship are confirmed by contact. Other facts remain bounded by returned reports and current intelligence confidence.")
		if String(profile.id)==selected_civilization_id: selected_contact_index=contact_index
	if contact_selector.item_count>0:
		contact_selector.select(selected_contact_index)
		contact_selector.item_selected.connect(_select_civilization_from_option.bind(contact_selector))
		rivals.add_child(contact_selector)
	else:
		var no_contacts:=Label.new(); no_contacts.text="None. Contact exists only after direct sight or a returned report."; no_contacts.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; no_contacts.add_theme_font_size_override("font_size",11); no_contacts.add_theme_color_override("font_color",Color("#929a95")); rivals.add_child(no_contacts)
	var scouting_heading:=Label.new()
	scouting_heading.text="SCOUT REPORTS"
	scouting_heading.add_theme_font_size_override("font_size",12)
	scouting_heading.add_theme_color_override("font_color",Color("#c8ad72"))
	rivals.add_child(scouting_heading)
	var exploration:Dictionary=competition.get("exploration",CivilizationSystem.exploration_status())
	var scouting_status:=Label.new()
	scouting_status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	scouting_status.add_theme_font_size_override("font_size",11)
	scouting_status.add_theme_color_override("font_color",Color("#aeb4ae"))
	if bool(exploration.get("active",false)):
		scouting_status.text="Party away  •  %d people  •  returns in %d days\nReport sealed until they return." % [int(exploration.get("personnel",0)),int(exploration.get("days_remaining",0))]
	else:
		var latest:Dictionary=exploration.get("latest_report",{})
		scouting_status.text="No party currently away."
		if not latest.is_empty():
			var contact_names:Array=latest.get("contacts",[])
			var recruit_suffix:="  •  +%d ARRIVALS" % int(latest.get("recruits",0)) if int(latest.get("recruits",0))>0 else ""
			scouting_status.text+="\nLast report  •  %s km%s%s" % [_compact_population(int(latest.get("distance_km",0))),"  •  "+", ".join(contact_names) if not contact_names.is_empty() else "",recruit_suffix]
	rivals.add_child(scouting_status)
	if not bool(exploration.get("active",false)):
		var action_hint:=Label.new()
		action_hint.text="Send a party from ACTIONS."
		action_hint.add_theme_font_size_override("font_size",11)
		action_hint.add_theme_color_override("font_color",Color("#c8ad72"))
		rivals.add_child(action_hint)
	if selected_civilization_id=="" or CivilizationSystem.known_civilization_snapshot(selected_civilization_id).is_empty(): selected_civilization_id=first_rival_id
	var detail_frame:=PanelContainer.new()
	detail_frame.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	detail_frame.size_flags_vertical=Control.SIZE_EXPAND_FILL
	detail_frame.add_theme_stylebox_override("panel",_knowledge_style(Color("#0b1416"),Color("#334846"),1,4,14))
	body.add_child(detail_frame)
	civilization_detail_root=VBoxContainer.new()
	civilization_detail_root.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	civilization_detail_root.size_flags_vertical=Control.SIZE_EXPAND_FILL
	civilization_detail_root.add_theme_constant_override("separation",5)
	detail_frame.add_child(civilization_detail_root)
	var selected_profile:=CivilizationSystem.known_civilization_snapshot(selected_civilization_id)
	if selected_profile.is_empty():
		var unknown:=Label.new()
		unknown.text="THE WORLD BEYOND RETURNED REPORTS IS UNKNOWN\n\nSend a scout party and let time pass. The terrain it crossed, the route it survived, and any polity it directly encountered become available only after its return."
		unknown.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		unknown.add_theme_font_size_override("font_size",16)
		unknown.add_theme_color_override("font_color",Color("#b9b19d"))
		civilization_detail_root.add_child(unknown)
	else:
		_populate_civilization_detail(selected_profile,competition)
	var footer:=HBoxContainer.new()
	root.add_child(footer)
	var rule:=Label.new()
	rule.text="Unknown civilizations and unreturned journeys remain absent from this view."
	rule.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	rule.add_theme_font_size_override("font_size",11)
	rule.add_theme_color_override("font_color",Color("#929a95"))
	footer.add_child(rule)
	var close:=Button.new()
	close.text="RETURN TO MAP"
	close.custom_minimum_size=Vector2(145,38)
	close.pressed.connect(_close_civilizations_panel)
	footer.add_child(close)


func _populate_civilization_detail(profile:Dictionary,competition:Dictionary)->void:
	if profile.is_empty(): return
	var relation:Dictionary=profile.get("player_relation",{})
	var intel:=clampf(float(profile.get("intel_confidence",0.0)),0.0,1.0)
	var title_row:=HBoxContainer.new()
	title_row.add_theme_constant_override("separation",12)
	civilization_detail_root.add_child(title_row)
	var title:=Label.new()
	title.text=String(profile.get("name","UNKNOWN CONTACT"))
	title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size",22)
	title.add_theme_color_override("font_color",Color("#e2cf9d"))
	title_row.add_child(title)
	var relation_badge:=Label.new()
	relation_badge.text=_foreign_relation_label(relation)
	relation_badge.add_theme_font_size_override("font_size",13)
	relation_badge.add_theme_color_override("font_color",Color("#d77d6f") if bool(relation.get("at_war",false)) else Color("#9fc3b2"))
	title_row.add_child(relation_badge)

	var contact_encounter:Dictionary={}
	for encounter_variant in CivilizationSystem.contact_encounters_snapshot():
		var encounter:Dictionary=encounter_variant
		if String(encounter.get("civ_id",""))==String(profile.get("id","")):
			contact_encounter=encounter
			break
	var contact_summary:=Label.new()
	contact_summary.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	contact_summary.add_theme_font_size_override("font_size",12)
	contact_summary.add_theme_color_override("font_color",Color("#9ebdb6"))
	if contact_encounter.is_empty():
		contact_summary.text="CONTACT ORIGIN UNKNOWN\nNo defensible encounter location survives in your records."
	else:
		var met_day:=maxi(0,int(contact_encounter.get("day",0)))
		var location_status:="Home settlement confirmed" if bool(relation.get("home_location_known",false)) else "Their homeland is still unlocated"
		contact_summary.text="MET YEAR %d, DAY %d\n%s. %s." % [met_day/365+1,met_day%365+1,String(contact_encounter.get("source_description","Contact source unknown")),location_status]
	civilization_detail_root.add_child(contact_summary)
	_add_modal_action_brief(civilization_detail_root,_world_strategy_next_step(profile),Color("#8c7951"))

	var facts:=PanelContainer.new()
	facts.add_theme_stylebox_override("panel",_knowledge_style(Color("#0c1517"),Color("#334846"),1,4,12))
	civilization_detail_root.add_child(facts)
	var fact_text:=Label.new()
	var population_report:="Population unknown"
	if intel>=0.20:
		population_report="Population %s–%s" % [_compact_population(roundi(float(profile.get("population_estimate_low",1.0)))),_compact_population(roundi(float(profile.get("population_estimate_high",1.0))))]
	var armed_report:="Armed strength unknown"
	if intel>=0.32:
		armed_report="Armed %s–%s" % [_compact_population(roundi(float(profile.get("military_estimate_low",0.0)))),_compact_population(roundi(float(profile.get("military_estimate_high",0.0))))]
	var territory_report:="Homeland unlocated"
	if intel>=0.55:
		territory_report="Home regions mapped %d/%d" % [int(profile.get("home_regions_controlled",0)),int(profile.get("home_regions_total",0))]
	var assessment:="Too little evidence to judge intent."
	if intel>=0.32:
		assessment="%s threat  •  %s" % [String(profile.get("threat_level","UNCERTAIN")).capitalize(),String(profile.get("rival_intent","Intent uncertain"))]
	fact_text.text="REPORT CONFIDENCE %d%%\n%s  •  %s\n%s\n\n%s" % [roundi(intel*100.0),population_report,armed_report,territory_report,assessment]
	fact_text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	fact_text.add_theme_font_size_override("font_size",13)
	fact_text.add_theme_color_override("font_color",Color("#c8c7b7"))
	facts.add_child(fact_text)

	var report_actions:=HBoxContainer.new()
	report_actions.add_theme_constant_override("separation",8)
	civilization_detail_root.add_child(report_actions)
	if not contact_encounter.is_empty():
		var show_contact:=Button.new()
		show_contact.text="LOCATE ENCOUNTER"
		show_contact.tooltip_text="Center the map on where contact occurred. This is not necessarily their homeland."
		show_contact.pressed.connect(_focus_contact_encounter.bind(String(profile.get("id",""))))
		report_actions.add_child(show_contact)
		if bool(contact_encounter.get("home_location_known",false)):
			var show_home:=Button.new()
			show_home.text="LOCATE SETTLEMENT"
			show_home.tooltip_text="Center the terrain on the home settlement confirmed by a returned report."
			show_home.pressed.connect(_focus_known_world_point.bind(String(profile.get("id","")),"settlement"))
			report_actions.add_child(show_home)
	var send_diplomat:=Button.new()
	send_diplomat.text="SEND DIPLOMATS"
	var home_known:=bool(relation.get("home_location_known",false))
	send_diplomat.tooltip_text="Send a physical delegation to the confirmed settlement. Proposals, replies, route knowledge, and observations move only as fast as its people can travel." if home_known else "Their settlement is still unlocated. Send scouts to investigate the returned contact site before diplomats can depart."
	send_diplomat.disabled=bool(CivilizationSystem.diplomatic_mission_status().get("active",false)) or not home_known
	send_diplomat.pressed.connect(_open_diplomat_for_civ.bind(String(profile.get("id",""))))
	report_actions.add_child(send_diplomat)
	var full_report:=Button.new()
	full_report.text="PLAN DIPLOMACY OR WAR"
	full_report.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	full_report.tooltip_text="Open the full report, campaign map, and every available foreign-policy action."
	full_report.pressed.connect(_open_civilization_report.bind(String(profile.get("id",""))))
	report_actions.add_child(full_report)

	if civilization_feedback_text!="":
		var feedback:=Label.new()
		feedback.text=civilization_feedback_text
		feedback.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		feedback.add_theme_font_size_override("font_size",11)
		feedback.add_theme_color_override("font_color",Color("#d0a879"))
		civilization_detail_root.add_child(feedback)


func _world_strategy_next_step(profile:Dictionary)->Dictionary:
	if profile.is_empty():
		return {"status":"NO FOREIGN CIVILIZATION IS KNOWN","why":"No direct encounter or returned scout report has identified one.","next":"Open Actions, send scouts, and wait for the party to return with its report."}
	var relation:Dictionary=profile.get("player_relation",{})
	var confidence:=clampf(float(profile.get("intel_confidence",0.0)),0.0,1.0)
	if bool(relation.get("at_war",false)):
		return {"status":"AT WAR WITH %s" % String(profile.get("name","THIS CIVILIZATION")).to_upper(),"why":"Military orders and campaign regions now determine territory and casualties.","next":"Open Plan Diplomacy or War to select the current front, objective, and army order."}
	if not bool(relation.get("home_location_known",false)):
		return {"status":"CONTACT KNOWN; SETTLEMENT UNLOCATED","why":"A meeting identified this civilization, but no returned report confirms a diplomatic destination.","next":"Open Actions and send scouts to investigate the recorded contact area. Diplomats cannot depart until a settlement is located."}
	if bool(CivilizationSystem.diplomatic_mission_status().get("active",false)):
		return {"status":"A DIPLOMATIC PARTY IS ALREADY AWAY","why":"Its proposal, observations, and reply are still traveling with the envoys.","next":"Wait for the party to return; no new diplomatic mission can leave meanwhile."}
	if confidence<0.55:
		return {"status":"CONTACT ESTABLISHED; REPORTS STILL THIN","why":"Confidence is %d%%, so strength, intent, and territory remain estimates or unknown." % roundi(confidence*100.0),"next":"Send scouts to observe the known settlement or use diplomacy to bring back better information."}
	return {"status":"CONTACT READY FOR A STRATEGIC CHOICE","why":"A physical destination is known and report confidence is %d%%." % roundi(confidence*100.0),"next":"Send diplomats for trade or non-aggression, or open Plan Diplomacy or War for the full report."}


func _add_compact_civilization_action(container:GridContainer,profile:Dictionary,action_id:String,label_text:String)->void:
	var action_button:=Button.new()
	action_button.text=label_text
	action_button.custom_minimum_size=Vector2(0,38)
	action_button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var availability:=CivilizationSystem.player_action_availability(String(profile.get("id","")),action_id)
	if action_id in CivilizationSystem.CARRIED_DIPLOMATIC_ACTIONS and not bool((profile.get("player_relation",{}) as Dictionary).get("home_location_known",false)):
		availability={"error":"Settlement unlocated. A returned scout report must confirm a physical destination first."}
	action_button.disabled=availability.has("error")
	action_button.tooltip_text=String(availability.get("error","Issue this order."))
	action_button.pressed.connect(_conduct_civilization_action.bind(String(profile.get("id","")),action_id))
	container.add_child(action_button)


func _open_civilization_report(civ_id:String)->void:
	if not civilizations_panel or not is_instance_valid(civilizations_panel): return
	if civilization_report_panel and is_instance_valid(civilization_report_panel): return
	var profile:=CivilizationSystem.known_civilization_snapshot(civ_id)
	if profile.is_empty(): return
	var competition:=CivilizationSystem.known_competition_snapshot()
	civilization_report_panel=Control.new()
	civilization_report_panel.size=civilizations_panel.size
	civilization_report_panel.mouse_filter=Control.MOUSE_FILTER_STOP
	civilization_report_panel.z_index=8
	civilizations_panel.add_child(civilization_report_panel)
	var dimmer:=ColorRect.new()
	dimmer.size=civilization_report_panel.size
	dimmer.color=Color(0.003,0.007,0.009,0.92)
	civilization_report_panel.add_child(dimmer)
	var modal:=PanelContainer.new()
	modal.size=Vector2(minf(960.0,civilization_report_panel.size.x-96.0),minf(610.0,civilization_report_panel.size.y-64.0))
	modal.position=(civilization_report_panel.size-modal.size)*0.5
	modal.add_theme_stylebox_override("panel",_knowledge_style(Color("#091113"),Color("#8c7951"),1,4,18))
	civilization_report_panel.add_child(modal)
	var root:=VBoxContainer.new()
	root.add_theme_constant_override("separation",8)
	modal.add_child(root)
	var heading_row:=HBoxContainer.new()
	root.add_child(heading_row)
	var heading:=Label.new()
	heading.text="INTELLIGENCE & POLICY"
	heading.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	heading.add_theme_font_size_override("font_size",21)
	heading.add_theme_color_override("font_color",Color("#efe1c3"))
	heading_row.add_child(heading)
	var close_report:=Button.new()
	close_report.text="CLOSE"
	close_report.custom_minimum_size=Vector2(92,34)
	close_report.pressed.connect(_close_civilization_report)
	heading_row.add_child(close_report)
	root.add_child(HSeparator.new())
	var report_scroll:=FIT_CONTENT_PANEL.new()
	report_scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	root.add_child(report_scroll)
	civilization_detail_root=VBoxContainer.new()
	civilization_detail_root.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	civilization_detail_root.add_theme_constant_override("separation",6)
	report_scroll.add_child(civilization_detail_root)
	_populate_civilization_full_report(profile,competition)


func _close_civilization_report()->void:
	if civilization_report_panel and is_instance_valid(civilization_report_panel): civilization_report_panel.queue_free()
	civilization_report_panel=null


func _populate_civilization_full_report(profile:Dictionary,competition:Dictionary)->void:
	if profile.is_empty(): return
	var relation:Dictionary=profile.player_relation
	var strategic_knowledge:Dictionary=competition.get("strategic_knowledge",CivilizationSystem.strategic_knowledge_snapshot())
	var knowledge_stage:=int(strategic_knowledge.get("stage",0))
	var title:=Label.new()
	title.text=String(profile.name)
	title.add_theme_font_size_override("font_size",20)
	title.add_theme_color_override("font_color",Color("#e2cf9d"))
	civilization_detail_root.add_child(title)
	var contact_encounter:Dictionary={}
	for encounter_variant in CivilizationSystem.contact_encounters_snapshot():
		var encounter:Dictionary=encounter_variant
		if String(encounter.get("civ_id",""))==String(profile.id): contact_encounter=encounter; break
	var contact_record:=Label.new()
	contact_record.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	contact_record.add_theme_font_size_override("font_size",12)
	contact_record.add_theme_color_override("font_color",Color("#acd1c8"))
	if contact_encounter.is_empty():
		contact_record.text="FIRST CONTACT RECORD  •  ORIGIN NOT PRESERVED\nThis older contact has no defensible encounter location. The game will not invent a homeland or map position."
	else:
		var met_day:=maxi(0,int(contact_encounter.get("day",0)))
		var home_status:="HOME SETTLEMENT CONFIRMED" if bool(relation.get("home_location_known",false)) else "HOME TERRITORY STILL UNLOCATED"
		contact_record.text="FIRST CONTACT  •  YEAR %d, DAY %d\n%s.\nENCOUNTER SITE CHARTED  •  %s" % [met_day/365+1,met_day%365+1,String(contact_encounter.get("source_description","Contact source unknown")),home_status]
	civilization_detail_root.add_child(contact_record)
	if not contact_encounter.is_empty():
		var show_contact:=Button.new()
		show_contact.text="SHOW FIRST-CONTACT SITE ON MAP"
		show_contact.tooltip_text="Close this report and center the map on the actual encounter location. This is not necessarily their homeland."
		show_contact.pressed.connect(_focus_contact_encounter.bind(String(profile.id)))
		civilization_detail_root.add_child(show_contact)
		if bool(contact_encounter.get("home_location_known",false)):
			var show_home:=Button.new()
			show_home.text="SHOW CONFIRMED SETTLEMENT ON MAP"
			show_home.tooltip_text="Center the terrain on the settlement location physically confirmed by a returned report."
			show_home.pressed.connect(_focus_known_world_point.bind(String(profile.id),"settlement"))
			civilization_detail_root.add_child(show_home)
	var intel:=clampf(float(profile.get("intel_confidence",0.0)),0.0,1.0)
	var partners_text:="UNKNOWN" if int(profile.get("diplomatic_partners",-1))<0 else str(int(profile.diplomatic_partners))
	var rivals_text:="UNKNOWN" if int(profile.get("diplomatic_rivals",-1))<0 else str(int(profile.diplomatic_rivals))
	var summary:=Label.new()
	var summary_lines:Array[String]=[]
	var contact_line:="DIRECT CONTACT  •  %s  •  INTELLIGENCE %d%%" % [_foreign_relation_label(relation),roundi(intel*100.0)]
	if knowledge_stage>=4 and profile.has("score") and profile.has("known_rank"):
		var score_error:=lerpf(0.24,0.04,intel)
		contact_line="KNOWN-WORLD STANDING #%d  •  SCORE EST. %.0f–%.0f  •  %s  •  INTEL %d%%" % [int(profile.known_rank),float(profile.score)*(1.0-score_error),float(profile.score)*(1.0+score_error),_foreign_relation_label(relation),roundi(intel*100.0)]
	summary_lines.append(contact_line)
	var population_report:="POPULATION ESTIMATE UNAVAILABLE"
	if intel>=0.20: population_report="POP EST. %s–%s" % [_compact_population(roundi(float(profile.get("population_estimate_low",1.0)))),_compact_population(roundi(float(profile.get("population_estimate_high",1.0))))]
	var armed_report:="ARMED CAPACITY UNKNOWN"
	if intel>=0.32: armed_report="ARMED EST. %s–%s" % [_compact_population(roundi(float(profile.get("military_estimate_low",0.0)))),_compact_population(roundi(float(profile.get("military_estimate_high",0.0))))]
	var regions_report:="HOME TERRITORY UNMAPPED"
	if intel>=0.55: regions_report="KNOWN HOME REGIONS %d/%d" % [int(profile.get("home_regions_controlled",0)),int(profile.get("home_regions_total",0))]
	summary_lines.append("%s  •  %s  •  %s" % [population_report,armed_report,regions_report])
	if intel>=0.48:
		summary_lines.append("APPARENT PRIORITY %s  •  FOOD ROUGHLY %.0f DAYS  •  PARTNERS %s  •  RIVALS %s  •  KNOWN WARS %d" % [String(profile.get("strategy","uncertain")).to_upper(),float(profile.get("food_days",0.0)),partners_text,rivals_text,int(profile.get("wars",0))])
	else:
		summary_lines.append("PRIORITIES, RESERVES, AND FOREIGN NETWORKS REMAIN UNVERIFIED")
	if intel>=0.58:
		var founding_definition:=GameState.founding_focus_definition(String(profile.get("founding_focus","")))
		if not founding_definition.is_empty(): summary_lines.append("INFERRED FOUNDING FOCUS  %s  •  %s" % [String(founding_definition.name),String(founding_definition.strengths)])
		summary_lines.append("OBSERVED TRAINING %s  •  COMMAND READINESS %s" % [String(profile.get("training_focus","unknown")).replace("_"," ").to_upper(),_qualitative_foreign_capacity(float(profile.get("command_readiness",0.0)),intel)])
	summary.text="\n".join(summary_lines)
	summary.add_theme_font_size_override("font_size",13)
	summary.add_theme_color_override("font_color",Color("#d1c4a6"))
	civilization_detail_root.add_child(summary)
	var intent:=Label.new()
	intent.text="INTELLIGENCE ASSESSMENT  •  THREAT %s  •  INTENT: %s" % [String(profile.get("threat_level","UNCERTAIN")),String(profile.get("rival_intent","Insufficient returned intelligence")).to_upper()] if intel>=0.32 else "INTELLIGENCE ASSESSMENT  •  Too little evidence to infer threat or intent."
	intent.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	intent.add_theme_font_size_override("font_size",11)
	intent.add_theme_color_override("font_color",Color("#e1bd72") if String(profile.get("threat_level","")) in ["HIGH","CRITICAL","WAR"] else Color("#9fb9ad"))
	civilization_detail_root.add_child(intent)
	var meters:=GridContainer.new()
	meters.columns=3
	meters.add_theme_constant_override("h_separation",12)
	meters.add_theme_constant_override("v_separation",4)
	civilization_detail_root.add_child(meters)
	for metric in [["HEALTH","health"],["COHESION","cohesion"],["KNOWLEDGE","knowledge"],["PRODUCTION","production"],["LOGISTICS","logistics"],["MILITARY READINESS","military_readiness"]]:
		var metric_label:=Label.new()
		metric_label.text="%s  %s" % [String(metric[0]),_qualitative_foreign_capacity(float(profile.get(String(metric[1]),0.0)),intel)]
		metric_label.custom_minimum_size=Vector2(168,20)
		metric_label.add_theme_font_size_override("font_size",11)
		metric_label.add_theme_color_override("font_color",Color("#b9c0b9"))
		meters.add_child(metric_label)
	var rival_score_rule:=Label.new()
	if knowledge_stage<3:
		rival_score_rule.text="NO GENERAL SCORE EXISTS IN YOUR CIVILIZATION'S KNOWLEDGE. These observations are reports, not universal domains or victory points."
	elif knowledge_stage==3:
		rival_score_rule.text="A SEVEN-DOMAIN COMPARATIVE MODEL HAS EMERGED, but your methods cannot yet defend exact scores, ranks, or victory thresholds."
	elif intel>=0.70 and profile.has("score_breakdown"):
		var domain_parts:Array[String]=[]
		for domain in CivilizationSystem.SCORE_DOMAINS:
			domain_parts.append("%s %d" % [String(domain).to_upper(),roundi(float((profile.get("score_breakdown",{}) as Dictionary).get(domain,0.0)))])
		var victory:Dictionary=profile.get("victory_requirements",{})
		var sustainable:Dictionary=victory.get("sustainability",{})
		rival_score_rule.text="SAME SCORE PILLARS  •  %s\nSAME VICTORY CHECK  BASICS %d/4  •  KNOWN DOMAINS %d/4  •  STREAK %d/12" % ["  ·  ".join(domain_parts),int(sustainable.get("met_count",0)),int(profile.get("domains_led",0)),int(profile.get("dominance_turns",0))]
	else:
		rival_score_rule.text="THE FORMAL COMPARISON METHOD IS KNOWN, but this civilization's breakdown remains too poorly observed for a defensible estimate."
	rival_score_rule.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	rival_score_rule.add_theme_font_size_override("font_size",10)
	rival_score_rule.add_theme_color_override("font_color",Color("#9eaa9f"))
	civilization_detail_root.add_child(rival_score_rule)
	var relation_text:=Label.new()
	if bool(relation.get("at_war",false)):
		var objective:=CivilizationSystem.war_objective_status(String(profile.id))
		relation_text.text="ACTIVE WAR  •  SCORE %+d  •  OUR EXHAUSTION %d%%  •  THEIR EXHAUSTION %d%%\nOBJECTIVE  %s  •  PROGRESS %d%%" % [roundi(float(relation.get("war_score",0.0))),roundi(float(relation.get("player_war_exhaustion",0.0))*100.0),roundi(float(relation.get("rival_war_exhaustion",0.0))*100.0),String(objective.get("description","DEFEND THE REALM")),roundi(float(objective.get("progress",0.0))*100.0)]
	else:
		var truce_days:=maxi(0,int(relation.get("truce_until_day",0))-int(GameState.elapsed_days))
		relation_text.text="RELATION  %s  •  BORDER TENSION %s  •  STANCE %s%s" % [_foreign_relation_label(relation),_qualitative_tension(float(relation.get("border_tension",0.0))),String(relation.get("stance","watchful")).to_upper(),"  •  TRUCE %d DAYS" % truce_days if truce_days>0 else ""]
	relation_text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	relation_text.add_theme_font_size_override("font_size",12)
	relation_text.add_theme_color_override("font_color",Color("#c6b98e"))
	civilization_detail_root.add_child(relation_text)
	var regions:Array=profile.get("strategic_regions",[])
	if intel<0.55:
		var frontier_unknown:=Label.new()
		frontier_unknown.text="STRATEGIC FRONT UNKNOWN  •  Maintain contact, trade, or reconnaissance to identify campaign regions and defensive estimates."
		frontier_unknown.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		frontier_unknown.add_theme_font_size_override("font_size",11)
		frontier_unknown.add_theme_color_override("font_color",Color("#a99672"))
		civilization_detail_root.add_child(frontier_unknown)
	if intel>=0.55 and not regions.is_empty():
		var selected_exists:=false
		for region_variant in regions:
			if String((region_variant as Dictionary).get("id",""))==selected_civilization_region_id: selected_exists=true
		if not selected_exists:
			selected_civilization_region_id=""
			for region_variant in regions:
				var region:Dictionary=region_variant
				if bool(region.get("available",false)): selected_civilization_region_id=String(region.id); break
			if selected_civilization_region_id=="": selected_civilization_region_id=String((regions[0] as Dictionary).id)
		var region_heading:=Label.new()
		region_heading.text="CAMPAIGN ROUTE  •  ADVANCE FROM LEFT TO RIGHT"
		region_heading.add_theme_font_size_override("font_size",11)
		region_heading.add_theme_color_override("font_color",Color("#d3b66d"))
		civilization_detail_root.add_child(region_heading)
		var front_grid:=GridContainer.new()
		front_grid.columns=mini(5,regions.size())
		front_grid.add_theme_constant_override("h_separation",4)
		front_grid.add_theme_constant_override("v_separation",4)
		civilization_detail_root.add_child(front_grid)
		var selected_region_index:=0
		for region_index in regions.size():
			var region:Dictionary=regions[region_index]
			var held_by_player:=String(region.get("controller",""))=="player"
			var state:="YOU CONTROL IT" if held_by_player else ("LIBERATE IT" if bool(region.get("foreign_holding",false)) else ("NEXT TARGET" if bool(region.get("available",false)) else "TAKE REGION %d FIRST" % region_index))
			var region_button:=Button.new()
			var selected_marker:="▶ " if String(region.id)==selected_civilization_region_id else ""
			region_button.text="%s%d  %s\n%s" % [selected_marker,region_index+1,_campaign_region_label(String(region.get("role","region"))),state]
			region_button.custom_minimum_size=Vector2(112,50)
			region_button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
			region_button.add_theme_font_size_override("font_size",9)
			var region_accent:=Color("#79a994") if held_by_player else (Color("#79a8c4") if bool(region.get("foreign_holding",false)) else (Color("#c8a95c") if bool(region.get("available",false)) else Color("#4b5755")))
			if String(region.id)==selected_civilization_region_id: region_accent=region_accent.lightened(0.22)
			region_button.add_theme_stylebox_override("normal",_knowledge_style(Color("#0c1517"),region_accent.darkened(0.25),1,3,4))
			region_button.add_theme_stylebox_override("hover",_knowledge_style(Color("#152226"),region_accent,1,3,4))
			region_button.tooltip_text="%s\n%s\nThese five cards are the route through this civilization, not buildings or technologies." % [String(region.get("name","Strategic region")),String(region.get("availability_reason",""))]
			region_button.pressed.connect(_select_campaign_region_button.bind(String(profile.id),String(region.id)))
			front_grid.add_child(region_button)
			if String(region.id)==selected_civilization_region_id: selected_region_index=region_index
		var selected_region:Dictionary=regions[selected_region_index]
		var occupation_force:Dictionary=MilitaryCampaign.occupation_force_for_region(String(profile.id),String(selected_region.id))
		var region_detail:=Label.new()
		var control_label:=String(selected_region.get("controller_label",profile.name))
		var force_status:="GARRISON %s / %s" % [_compact_population(int(occupation_force.get("troops",0))),_compact_population(roundi(float(selected_region.get("occupation_required",0.0))))] if String(selected_region.get("controller",""))=="player" else "OCCUPATION NEED %s" % _compact_population(roundi(float(selected_region.get("occupation_required",0.0))))
		region_detail.text="%s — %s\nACCESS: %s\nPopulation %s  •  Controlled by %s  •  Defenses %d%%  •  War damage %d%%  •  %s" % [String(selected_region.name),_campaign_region_label(String(selected_region.get("role","region"))),String(selected_region.get("availability_reason","")),_compact_population(roundi(float(selected_region.get("population",0.0)))),control_label,roundi(float(selected_region.get("fortification",0.0))*100.0),roundi(float(selected_region.get("damage",0.0))*100.0),force_status]
		region_detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		region_detail.add_theme_font_size_override("font_size",10)
		region_detail.add_theme_color_override("font_color",Color("#acb5ae"))
		civilization_detail_root.add_child(region_detail)
		var planning_row:=HBoxContainer.new()
		planning_row.add_theme_constant_override("separation",8)
		civilization_detail_root.add_child(planning_row)
		var goal_heading:=Label.new()
		goal_heading.text="WAR OBJECTIVE"
		goal_heading.custom_minimum_size=Vector2(105,0)
		goal_heading.add_theme_font_size_override("font_size",10)
		goal_heading.add_theme_color_override("font_color",Color("#d3b66d"))
		planning_row.add_child(goal_heading)
		var goal_selector:=OptionButton.new()
		goal_selector.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		goal_selector.add_theme_font_size_override("font_size",10)
		goal_selector.disabled=bool(relation.get("at_war",false))
		var goal_index:=0
		var goal_options:Array=[]
		if bool(relation.get("at_war",false)):
			goal_options=[{"id":String(relation.get("war_goal","defend")),"label":String(CivilizationSystem.WAR_GOAL_LABELS.get(String(relation.get("war_goal","defend")),"ACTIVE OBJECTIVE")),"available":true,"description":"This objective is locked until the war ends."}]
		else:
			goal_options=CivilizationSystem.war_goal_options(String(profile.id),String(selected_region.id))
		for option_index in goal_options.size():
			var option:Dictionary=goal_options[option_index]
			goal_selector.add_item(String(option.label))
			goal_selector.set_item_metadata(option_index,String(option.id))
			goal_selector.set_item_disabled(option_index,not bool(option.available))
			goal_selector.set_item_tooltip(option_index,String(option.description))
			if String(option.id)==String(relation.get("war_goal","limited")): goal_index=option_index
		goal_selector.select(goal_index)
		goal_selector.item_selected.connect(_select_war_goal.bind(goal_selector,String(profile.id)))
		planning_row.add_child(goal_selector)
		var assessment:=CivilizationSystem.strategic_assessment(String(profile.id),String(selected_region.id))
		var operation:=PanelContainer.new()
		var outlook_color:=Color("#83b39b") if String(assessment.get("outlook","")) in ["DECISIVE ADVANTAGE","FAVORABLE"] else (Color("#d1b66f") if String(assessment.get("outlook",""))=="CONTESTED" else Color("#ce806f"))
		operation.add_theme_stylebox_override("panel",_knowledge_style(Color("#0d1719"),outlook_color.darkened(0.25),1,3,6))
		civilization_detail_root.add_child(operation)
		var operation_text:=Label.new()
		operation_text.text="OPERATIONAL FORECAST  %s  •  CASUALTY RISK %s  •  SUPPLY %s\nFIELD %s  •  DEFENDER EST. %s–%s  •  INTEL %d%%  •  READINESS %d%%\nWHY IT MATTERS  %s" % [String(assessment.get("outlook","UNKNOWN")),String(assessment.get("casualty_risk","UNKNOWN")),String(assessment.get("supply_label","UNKNOWN")),_compact_population(int(assessment.get("fielded",0))),_compact_population(int(assessment.get("enemy_estimate_low",0))),_compact_population(int(assessment.get("enemy_estimate_high",0))),roundi(float(assessment.get("intel_confidence",0.0))*100.0),roundi(float(assessment.get("player_readiness",0.0))*100.0),String(assessment.get("region_value",""))]
		operation_text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		operation_text.add_theme_font_size_override("font_size",10)
		operation_text.add_theme_color_override("font_color",outlook_color.lightened(0.12))
		operation.add_child(operation_text)
		if bool(relation.get("at_war",false)):
			var peace:=CivilizationSystem.peace_forecast(String(profile.id))
			var peace_text:=Label.new()
			peace_text.text="PEACE FORECAST  %s  •  leverage %d%%  •  objective %s" % [String(peace.get("label","WILL REFUSE")),roundi(float(peace.get("strategic_leverage",0.0))*100.0),"COMPLETE" if bool((peace.get("objective",{}) as Dictionary).get("complete",false)) else "INCOMPLETE"]
			peace_text.add_theme_font_size_override("font_size",10)
			peace_text.add_theme_color_override("font_color",Color("#bfc7bc"))
			civilization_detail_root.add_child(peace_text)
	var feedback:=Label.new()
	feedback.text=civilization_feedback_text if civilization_feedback_text!="" else "Choose a standing action. Every action changes the relation and therefore trade access, security pressure, knowledge exchange, or war risk."
	feedback.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	feedback.add_theme_font_size_override("font_size",11)
	feedback.add_theme_color_override("font_color",Color("#d0a879") if civilization_feedback_text!="" else Color("#949d98"))
	civilization_detail_root.add_child(feedback)
	var actions:=GridContainer.new()
	actions.columns=3
	actions.size_flags_vertical=Control.SIZE_EXPAND_FILL
	actions.add_theme_constant_override("h_separation",6)
	actions.add_theme_constant_override("v_separation",6)
	civilization_detail_root.add_child(actions)
	var action_descriptions:={"open_trade":"Send a trade proposal. It can begin only after envoys reach them and carry acceptance home.","non_aggression":"Send a non-aggression proposal. No compact exists until the physical round trip is complete.","send_aid":"Send envoys carrying physical food aid; both travel rations and aid leave your reserve at departure.","contain":"End the current compact and adopt a hostile peacetime containment posture.","seek_peace":"Send peace envoys. Any response remains unknown until the delegation returns.","declare_war":"Send a physical declaration. War begins only when the message reaches them.","launch_campaign":"Commit the existing aggregate field formation against this rival's simulated garrison.","reinforce_occupation":"Move trained field personnel into the selected occupation force. Coverage suppresses rebellion and supports integration.","evacuate_occupation":"Withdraw the selected occupation force into the recruit reserve, returning its issued equipment but leaving control exposed to uprising or recapture."}
	var action_recoveries:={"open_trade":"Locate their settlement with a returned scout report, restore envoy rations, and finish any active diplomatic mission.","non_aggression":"Locate their settlement with a returned scout report, restore envoy rations, and finish any active diplomatic mission.","send_aid":"Locate their settlement, restore the required physical Food, and finish any active diplomatic mission.","contain":"Resolve the current war or incompatible treaty state, then choose containment again.","seek_peace":"Enter a war, then send peace envoys after locating the opponent's settlement.","declare_war":"Locate their settlement, choose a war objective, and finish any active diplomatic mission before sending the declaration.","launch_campaign":"Raise and train personnel, form a maneuver army, move it to this selected objective, and resolve any active battle.","reinforce_occupation":"Train unassigned home personnel, then select a region you already control.","evacuate_occupation":"Select a controlled region with an occupation force still stationed there."}
	var action_consequences:={"open_trade":"No trade begins until acceptance physically returns.","non_aggression":"No compact begins until acceptance physically returns.","send_aid":"Travel rations and the aid cargo leave physical stores at departure.","contain":"Trade and diplomatic access end immediately and tension rises.","seek_peace":"The war continues until an accepted response returns.","declare_war":"War begins when the declaration reaches them, not when it departs.","launch_campaign":"The stationed army fights; military and civilian losses, damage, and control changes enter permanent history.","reinforce_occupation":"Field personnel leave the reserve to suppress resistance and support integration.","evacuate_occupation":"Personnel and equipment return, but resistance or recapture may end control."}
	for action_entry in [["PROPOSE TRADE","open_trade"],["PROPOSE NON-AGGRESSION","non_aggression"],["SEND FOOD AID","send_aid"],["CONTAIN","contain"],["SEND PEACE ENVOYS","seek_peace"],["SEND WAR DECLARATION","declare_war"],["LAUNCH CAMPAIGN","launch_campaign"],["REINFORCE OCCUPATION","reinforce_occupation"],["EVACUATE OCCUPATION","evacuate_occupation"]]:
		var action_button:=Button.new()
		action_button.text=String(action_entry[0])
		action_button.custom_minimum_size=Vector2(0,36)
		action_button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		action_button.add_theme_font_size_override("font_size",10)
		var action_id:=String(action_entry[1])
		var availability:Dictionary
		if action_id=="launch_campaign": availability=MilitaryCampaign.offensive_campaign_availability(String(profile.id),selected_civilization_region_id)
		elif action_id in ["reinforce_occupation","evacuate_occupation"]: availability=MilitaryCampaign.occupation_action_availability(String(profile.id),selected_civilization_region_id,action_id)
		else: availability=CivilizationSystem.player_action_availability(String(profile.id),action_id)
		if action_id in CivilizationSystem.CARRIED_DIPLOMATIC_ACTIONS and not bool(relation.get("home_location_known",false)):
			availability={"error":"Settlement unlocated. Investigate the known contact site and return with its position before sending diplomats."}
		action_button.disabled=availability.has("error")
		if availability.has("error"):
			action_button.tooltip_text="BLOCKED  %s\nNEXT  %s" % [String(availability.error),String(action_recoveries.get(action_id,"Resolve the listed blocker, then return to this action."))]
		else:
			action_button.tooltip_text="ACTION  %s\nCONSEQUENCE  %s" % [String(action_descriptions.get(action_id,"Carry out this action.")),String(action_consequences.get(action_id,"The relationship and strategic state will change."))]
			if availability.has("amount"): action_button.tooltip_text+="\nCOST  Transfer %.1f Food from physical stores; it cannot reappear after departure." % float(availability.amount)
			if availability.has("incident"): action_button.tooltip_text+="\nCURRENT  Estimated aggregate garrison %s." % _compact_population(int((availability.incident as Dictionary).get("strength",0)))
		action_button.pressed.connect(_conduct_civilization_action.bind(String(profile.id),String(action_entry[1])))
		actions.add_child(action_button)


func _foreign_relation_label(relation:Dictionary)->String:
	if bool(relation.get("at_war",false)): return "AT WAR"
	var treaty:=String(relation.get("treaty","none"))
	if treaty!="none": return treaty.replace("_"," ").to_upper()
	var opinion:=float(relation.get("opinion",0.0))
	if opinion>=0.30: return "FRIENDLY"
	if opinion>=-0.12: return "WATCHFUL"
	if opinion>=-0.40: return "RIVAL"
	return "HOSTILE"


func _qualitative_foreign_capacity(value:float,intelligence:float)->String:
	if intelligence<0.48: return "UNKNOWN"
	if value<0.22: return "FRAGILE"
	if value<0.40: return "LIMITED"
	if value<0.60: return "DEVELOPING"
	if value<0.78: return "STRONG"
	return "FORMIDABLE"


func _qualitative_tension(value:float)->String:
	if value<0.18: return "LOW"
	if value<0.42: return "GUARDED"
	if value<0.68: return "HIGH"
	return "SEVERE"


func _campaign_region_label(role:String)->String:
	return String({"frontier":"BORDER REGION","granary":"FOOD REGION","market":"TRADE HUB","works":"INDUSTRIAL REGION","capital":"CAPITAL"}.get(role,"STRATEGIC REGION"))


func _intercept_foreign_scout(formation_id:String,action:String)->void:
	var result:Dictionary=CivilizationSystem.resolve_foreign_scout_interception(formation_id,action)
	civilization_feedback_text=String(result.get("error",result.get("message","Interception resolved.")))
	selected_civilization_id=String(result.get("civilization_id",selected_civilization_id))
	_close_civilizations_panel()
	_open_civilizations_panel()
	_update_time_interface()


func _interrogate_captured_scouts(civ_id:String,method:String)->void:
	var result:Dictionary=CivilizationSystem.interrogate_captured_scouts(civ_id,method)
	civilization_feedback_text=String(result.get("error",result.get("message","Interrogation resolved.")))
	selected_civilization_id=civ_id
	_close_civilizations_panel()
	_open_civilizations_panel()
	_update_time_interface()


func _open_scout_dispatch_panel()->void:
	if scout_dispatch_panel and is_instance_valid(scout_dispatch_panel): scout_dispatch_panel.queue_free()
	scout_dispatch_previous_speed=game_speed
	_set_game_speed(0.0)
	scout_dispatch_panel=Control.new()
	scout_dispatch_panel.name="ScoutDispatchModal"
	scout_dispatch_panel.size=get_viewport().get_visible_rect().size
	scout_dispatch_panel.mouse_filter=Control.MOUSE_FILTER_STOP
	scout_dispatch_panel.z_index=70
	interface_layer.add_child(scout_dispatch_panel)
	var dimmer:=ColorRect.new(); dimmer.size=scout_dispatch_panel.size; dimmer.color=Color(0.005,0.010,0.012,0.84); dimmer.mouse_filter=Control.MOUSE_FILTER_STOP; scout_dispatch_panel.add_child(dimmer)
	var modal:=PanelContainer.new(); modal.position=scout_dispatch_panel.size*0.5-Vector2(330,235); modal.size=Vector2(660,470); modal.add_theme_stylebox_override("panel",_population_report_style(Color("#7ca39d"))); scout_dispatch_panel.add_child(modal)
	var root:=VBoxContainer.new(); root.add_theme_constant_override("separation",9); modal.add_child(root)
	var heading:=Label.new(); heading.text="DISPATCH SCOUT PARTY"; heading.add_theme_font_size_override("font_size",22); heading.add_theme_color_override("font_color",Color("#d9c99e")); root.add_child(heading)
	var explanation:=Label.new(); explanation.text="Choose how long one fast aggregate party may remain away. The route, terrain, sightings, and contacts remain physically with the scouts and reveal nothing until they return. On a planetary map, short missions are local reconnaissance—not automatic contact."; explanation.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; explanation.add_theme_font_size_override("font_size",12); explanation.add_theme_color_override("font_color",Color("#b7bfba")); root.add_child(explanation)
	var exploration:=CivilizationSystem.exploration_status()
	if bool(exploration.get("active",false)):
		var active_status:=Label.new(); active_status.text="PARTY AWAY  •  %d PEOPLE  •  RETURNS IN %d DAYS\n%s\n%.1f FOOD ISSUED  •  NO REPORT YET\n\n%s" % [int(exploration.get("personnel",0)),int(exploration.get("days_remaining",0)),String(exploration.get("target_label","OPEN EXPLORATION")),float(exploration.get("provisions",0.0)),String(exploration.get("message",""))]; active_status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; active_status.size_flags_vertical=Control.SIZE_EXPAND_FILL; active_status.add_theme_font_size_override("font_size",15); active_status.add_theme_color_override("font_color",Color("#d5bd82")); root.add_child(active_status)
	else:
		var target_options:=CivilizationSystem.scout_target_options()
		var target_selector:=OptionButton.new(); target_selector.custom_minimum_size=Vector2(0,38); target_selector.tooltip_text="Choose open exploration, a known encounter site, or a confirmed foreign settlement."; root.add_child(target_selector)
		var selected_target_index:=0
		for target_index in target_options.size():
			var target:Dictionary=target_options[target_index]
			target_selector.add_item(String(target.label))
			target_selector.set_item_metadata(target_index,String(target.id))
			target_selector.set_item_tooltip(target_index,String(target.description))
			if String(target.id)==pending_scout_target_id: selected_target_index=target_index
		target_selector.select(selected_target_index)
		pending_scout_target_id=String(target_selector.get_item_metadata(selected_target_index))
		var duration_grid:=GridContainer.new(); duration_grid.columns=2; duration_grid.size_flags_vertical=Control.SIZE_EXPAND_FILL; duration_grid.add_theme_constant_override("h_separation",8); duration_grid.add_theme_constant_override("v_separation",8); root.add_child(duration_grid)
		_populate_scout_duration_buttons(duration_grid,pending_scout_target_id)
		target_selector.item_selected.connect(_select_scout_target.bind(target_selector,duration_grid))
	scout_dispatch_status=Label.new(); scout_dispatch_status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; scout_dispatch_status.add_theme_font_size_override("font_size",11); scout_dispatch_status.add_theme_color_override("font_color",Color("#aeb6b2")); root.add_child(scout_dispatch_status)
	var footer:=HBoxContainer.new(); footer.alignment=BoxContainer.ALIGNMENT_END; root.add_child(footer)
	var close:=Button.new(); close.text="CLOSE"; close.custom_minimum_size=Vector2(140,38); close.pressed.connect(_close_scout_dispatch_panel); footer.add_child(close)


func _close_scout_dispatch_panel()->void:
	if scout_dispatch_panel and is_instance_valid(scout_dispatch_panel): scout_dispatch_panel.queue_free()
	scout_dispatch_panel=null
	scout_dispatch_status=null
	_set_game_speed(scout_dispatch_previous_speed)


func _select_scout_target(index:int,selector:OptionButton,duration_grid:GridContainer)->void:
	pending_scout_target_id=String(selector.get_item_metadata(index))
	for child in duration_grid.get_children(): child.queue_free()
	_populate_scout_duration_buttons(duration_grid,pending_scout_target_id)


func _populate_scout_duration_buttons(duration_grid:GridContainer,target_id:String)->void:
	for duration in CivilizationSystem.SCOUT_DURATIONS:
		var quote:=CivilizationSystem.scout_mission_quote(int(duration),target_id)
		var mission:=Button.new(); mission.custom_minimum_size=Vector2(0,106); mission.size_flags_horizontal=Control.SIZE_EXPAND_FILL; mission.alignment=HORIZONTAL_ALIGNMENT_LEFT; mission.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; mission.add_theme_font_size_override("font_size",11)
		mission.text=_scout_mission_card_text(int(duration),quote)
		mission.disabled=not bool(quote.get("can_dispatch",false))
		mission.tooltip_text=("BLOCKED  %s\nNEXT  Restore the listed people or food, finish the active party, then choose this duration again." % String(quote.get("blocker","This mission cannot depart."))) if mission.disabled else "ACTION  Dispatch %d fast scouts for %d days toward this target.\nCOST  %.1f Food and %d absent people are committed at departure.\nCONSEQUENCE  No terrain, contact, recruits, or sightings become known unless the party physically returns." % [int(quote.get("personnel",0)),int(duration),float(quote.get("provisions",0.0)),int(quote.get("personnel",0))]
		mission.pressed.connect(_dispatch_scout_from_actions.bind(int(duration),target_id)); duration_grid.add_child(mission)


func _scout_mission_card_text(duration:int,quote:Dictionary)->String:
	var text:="SEND FOR %d DAYS\n%d PEOPLE  •  %.1f FOOD\nREACH ~%s KM  •  RISK %s" % [duration,int(quote.get("personnel",0)),float(quote.get("provisions",0.0)),_compact_population(roundi(float(quote.get("one_way_range_km",0.0)))),String((quote.get("risk",{}) as Dictionary).get("label","UNKNOWN"))]
	if not bool(quote.get("can_dispatch",false)):
		var blocker:=String(quote.get("blocker",quote.get("error","Mission unavailable."))).replace("\n"," ")
		text+="\nBLOCKED  •  %s" % blocker.left(72)
	return text


func _dispatch_scout_from_actions(duration_days:int,target_id:String="open_world")->void:
	var result:=CivilizationSystem.dispatch_scouts(duration_days,target_id)
	if result.has("error"):
		if scout_dispatch_status:
			scout_dispatch_status.text=String(result.error)
			scout_dispatch_status.add_theme_color_override("font_color",Color("#d77a68"))
		return
	if travel_status_label: travel_status_label.text="SCOUT PARTY DEPARTED  •  %d DAYS  •  REPORT DUE ONLY ON RETURN" % duration_days
	_close_scout_dispatch_panel()
	_update_time_interface()


func _open_diplomat_dispatch_panel(civ_id:String="",purpose:String="goodwill")->void:
	if diplomat_dispatch_panel and is_instance_valid(diplomat_dispatch_panel): diplomat_dispatch_panel.queue_free()
	if civ_id!="": pending_diplomat_civ_id=civ_id
	pending_diplomat_action=purpose.strip_edges().to_lower().replace(" ","_")
	if pending_diplomat_action!="goodwill" and pending_diplomat_action not in CivilizationSystem.CARRIED_DIPLOMATIC_ACTIONS: pending_diplomat_action="goodwill"
	diplomat_dispatch_previous_speed=game_speed
	_set_game_speed(0.0)
	diplomat_dispatch_panel=Control.new()
	diplomat_dispatch_panel.name="DiplomatDispatchModal"
	diplomat_dispatch_panel.size=get_viewport().get_visible_rect().size
	diplomat_dispatch_panel.mouse_filter=Control.MOUSE_FILTER_STOP
	diplomat_dispatch_panel.z_index=72
	interface_layer.add_child(diplomat_dispatch_panel)
	var dimmer:=ColorRect.new(); dimmer.size=diplomat_dispatch_panel.size; dimmer.color=Color(0.005,0.010,0.012,0.88); dimmer.mouse_filter=Control.MOUSE_FILTER_STOP; diplomat_dispatch_panel.add_child(dimmer)
	var modal:=PanelContainer.new(); modal.size=Vector2(minf(720.0,diplomat_dispatch_panel.size.x-80.0),minf(530.0,diplomat_dispatch_panel.size.y-64.0)); modal.position=(diplomat_dispatch_panel.size-modal.size)*0.5; modal.add_theme_stylebox_override("panel",_population_report_style(Color("#9b8761"))); diplomat_dispatch_panel.add_child(modal)
	var root:=VBoxContainer.new(); root.add_theme_constant_override("separation",9); modal.add_child(root)
	var purpose_label:=String(CivilizationSystem.DIPLOMATIC_PURPOSE_LABELS.get(pending_diplomat_action,"SEND DIPLOMATS"))
	var heading:=Label.new(); heading.text=purpose_label; heading.add_theme_font_size_override("font_size",22); heading.add_theme_color_override("font_color",Color("#e4d3ac")); root.add_child(heading)
	var explanation:=Label.new(); explanation.text="Diplomats require a settlement physically located by a returned report. They travel at the speed of people: nothing is agreed at departure, and their route, response, and observations become knowledge only when they return."; explanation.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; explanation.add_theme_font_size_override("font_size",12); explanation.add_theme_color_override("font_color",Color("#aeb6b1")); root.add_child(explanation)
	var status:=CivilizationSystem.diplomatic_mission_status()
	if bool(status.get("active",false)):
		var cargo:="NO MATERIAL GIFT" if float(status.get("gift_amount",0.0))<=0.0 else "%.1f %s GIFT" % [float(status.get("gift_amount",0.0)),String(status.get("gift_resource",""))]
		var journey_status:="REACHES DESTINATION IN %d DAYS  •  ANSWER STILL UNKNOWN" % int(status.get("arrival_days_remaining",0)) if String(status.get("stage","outbound"))=="outbound" else "RETURNING WITH THE RESPONSE"
		var active:=Label.new(); active.text="%s  •  %s\n%d ENVOYS  •  %.1f FOOD TRAVEL RATIONS  •  %s\n%s\n%d DAYS UNTIL HOME" % [String(status.get("purpose_label","DIPLOMATIC MISSION")),String(status.get("civilization","FOREIGN POLITY")).to_upper(),int(status.get("personnel",0)),float(status.get("provisions",0.0)),cargo,journey_status,int(status.get("days_remaining",0))]; active.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; active.size_flags_vertical=Control.SIZE_EXPAND_FILL; active.add_theme_font_size_override("font_size",15); active.add_theme_color_override("font_color",Color("#d6bf87")); root.add_child(active)
	else:
		var contacts:Array[Dictionary]=[]
		for profile_variant in CivilizationSystem.known_competition_snapshot().get("leaders",[]):
			var profile:Dictionary=profile_variant
			if String(profile.get("id",""))!="player" and bool((profile.get("player_relation",{}) as Dictionary).get("home_location_known",false)): contacts.append(profile)
		if contacts.is_empty():
			var none:=Label.new(); none.text="NO CONFIRMED DIPLOMATIC DESTINATION\nKnowing a polity exists does not reveal its home. Send scouts to investigate a returned contact site; only their returned location report permits a diplomatic journey."; none.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; none.size_flags_vertical=Control.SIZE_EXPAND_FILL; none.add_theme_font_size_override("font_size",16); none.add_theme_color_override("font_color",Color("#9ea7a2")); root.add_child(none)
		else:
			var latest:Dictionary=status.get("latest",{})
			var latest_observations:Array=latest.get("observations",[])
			if not latest_observations.is_empty():
				var returned_report:=Label.new(); returned_report.text="LAST RETURNED REPORT • %s\n%s" % [String(latest.get("civilization","FOREIGN POLITY")).to_upper(),"  •  ".join(PackedStringArray(latest_observations))]; returned_report.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; returned_report.add_theme_font_size_override("font_size",10); returned_report.add_theme_color_override("font_color",Color("#9fc1b8")); root.add_child(returned_report)
			var selector:=OptionButton.new(); selector.custom_minimum_size=Vector2(0,38); root.add_child(selector)
			var selected_index:=0
			for contact_index in contacts.size():
				var profile:Dictionary=contacts[contact_index]
				selector.add_item(String(profile.get("name","FOREIGN POLITY")))
				selector.set_item_metadata(contact_index,String(profile.get("id","")))
				if String(profile.get("id",""))==pending_diplomat_civ_id: selected_index=contact_index
			selector.select(selected_index)
			pending_diplomat_civ_id=String(selector.get_item_metadata(selected_index))
			var gift_grid:=GridContainer.new(); gift_grid.columns=2; gift_grid.size_flags_vertical=Control.SIZE_EXPAND_FILL; gift_grid.add_theme_constant_override("h_separation",8); gift_grid.add_theme_constant_override("v_separation",8); root.add_child(gift_grid)
			_populate_diplomatic_gift_buttons(gift_grid,pending_diplomat_civ_id,pending_diplomat_action)
			selector.item_selected.connect(_select_diplomat_target.bind(selector,gift_grid,pending_diplomat_action))
	diplomat_dispatch_status=Label.new(); diplomat_dispatch_status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; diplomat_dispatch_status.add_theme_font_size_override("font_size",11); diplomat_dispatch_status.add_theme_color_override("font_color",Color("#aeb6b2")); root.add_child(diplomat_dispatch_status)
	var footer:=HBoxContainer.new(); footer.alignment=BoxContainer.ALIGNMENT_END; root.add_child(footer)
	var close:=Button.new(); close.text="CLOSE"; close.custom_minimum_size=Vector2(140,38); close.pressed.connect(_close_diplomat_dispatch_panel); footer.add_child(close)


func _select_diplomat_target(index:int,selector:OptionButton,gift_grid:GridContainer,purpose:String)->void:
	pending_diplomat_civ_id=String(selector.get_item_metadata(index))
	for child in gift_grid.get_children(): child.queue_free()
	_populate_diplomatic_gift_buttons(gift_grid,pending_diplomat_civ_id,purpose)


func _populate_diplomatic_gift_buttons(gift_grid:GridContainer,civ_id:String,purpose:String="goodwill")->void:
	var choices:Array[Dictionary]=[]
	if purpose in CivilizationSystem.CARRIED_DIPLOMATIC_ACTIONS and purpose!="send_aid":
		choices.append({"resource":"","amount":0.0,"available":0.0,"can_send":true,"label":"NO GIFT","reception":"PROPOSAL ONLY"})
	for gift_variant in CivilizationSystem.diplomatic_gift_options(civ_id):
		var gift:Dictionary=gift_variant
		if purpose=="declare_war": continue
		if purpose=="send_aid" and String(gift.resource)!="Food": continue
		choices.append(gift)
	for gift in choices:
		var gift_resource:=String(gift.get("resource",""))
		var quote:=CivilizationSystem.diplomatic_mission_quote(civ_id,gift_resource,purpose)
		var button:=Button.new(); button.custom_minimum_size=Vector2(0,84); button.size_flags_horizontal=Control.SIZE_EXPAND_FILL; button.alignment=HORIZONTAL_ALIGNMENT_LEFT; button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; button.add_theme_font_size_override("font_size",11)
		var choice_detail:="PROPOSAL ONLY" if gift_resource=="" else "AVAILABLE %.1f  •  %s" % [float(gift.get("available",0.0)),String(gift.get("reception","gift")).to_upper()]
		if quote.has("error"): choice_detail="BLOCKED  •  %s" % String(quote.error).replace("\n"," ").left(76)
		button.text="%s\n%s" % [String(gift.get("label","NO GIFT")).to_upper(),choice_detail]
		button.disabled=quote.has("error")
		button.tooltip_text=("BLOCKED  %s\nNEXT  Restore the missing destination, people, food, or gift stock and finish any active delegation." % String(quote.error)) if button.disabled else "ACTION  Send %d envoys on a %.0f km physical journey.\nCOST  %.1f Food travel rations%s.\nCONSEQUENCE  The proposal, reply, route observations, and settlement intelligence become known only after the %d-day round trip." % [int(quote.get("personnel",0)),float(quote.get("distance_km",0.0)),float(quote.get("provisions",0.0)),(" plus the selected gift" if gift_resource!="" else ""),int(quote.get("total_days",0))]
		button.pressed.connect(_dispatch_diplomat_from_actions.bind(civ_id,gift_resource,purpose)); gift_grid.add_child(button)


func _dispatch_diplomat_from_actions(civ_id:String,gift_resource:String,purpose:String="goodwill")->void:
	var result:=CivilizationSystem.dispatch_diplomat(civ_id,gift_resource,purpose)
	if result.has("error"):
		if diplomat_dispatch_status:
			diplomat_dispatch_status.text=String(result.error)
			diplomat_dispatch_status.add_theme_color_override("font_color",Color("#d77a68"))
		return
	if travel_status_label: travel_status_label.text="DIPLOMATS DEPARTED  •  %s  •  RESPONSE DUE ONLY ON RETURN" % String(CivilizationSystem.DIPLOMATIC_PURPOSE_LABELS.get(purpose,"MISSION"))
	_close_diplomat_dispatch_panel()
	_update_time_interface()


func _open_diplomat_for_civ(civ_id:String,purpose:String="goodwill")->void:
	_close_civilizations_panel()
	_open_diplomat_dispatch_panel(civ_id,purpose)


func _close_diplomat_dispatch_panel()->void:
	if diplomat_dispatch_panel and is_instance_valid(diplomat_dispatch_panel): diplomat_dispatch_panel.queue_free()
	diplomat_dispatch_panel=null
	diplomat_dispatch_status=null
	_set_game_speed(diplomat_dispatch_previous_speed)


func _dispatch_scouts(duration_days:int)->void:
	var result:Dictionary=CivilizationSystem.dispatch_scouts(duration_days)
	civilization_feedback_text=String(result.get("error",result.get("message","Scout party dispatched.")))
	selected_civilization_id=""
	selected_civilization_region_id=""
	_close_civilizations_panel()
	_open_civilizations_panel()
	_update_time_interface()


func _select_civilization(civ_id:String)->void:
	selected_civilization_id=civ_id
	selected_civilization_region_id=""
	civilization_feedback_text=""
	_close_civilizations_panel()
	_open_civilizations_panel()


func _select_civilization_from_option(index:int,selector:OptionButton)->void:
	if selector==null or index<0 or index>=selector.item_count: return
	_select_civilization(String(selector.get_item_metadata(index)))



func _focus_contact_encounter(civ_id:String)->void:
	_focus_known_world_point(civ_id,"encounter")


func _focus_known_world_point(civ_id:String,point_kind:String)->void:
	for encounter_variant in CivilizationSystem.contact_encounters_snapshot():
		var encounter:Dictionary=encounter_variant
		if String(encounter.get("civ_id",""))!=civ_id: continue
		var use_settlement:=point_kind=="settlement" and bool(encounter.get("home_location_known",false))
		var position_data:Dictionary=encounter.get("home_position",{}) if use_settlement else encounter.get("position",{})
		if not position_data.has("x") or not position_data.has("z"): return
		_close_civilizations_panel()
		var target:=Vector3(float(position_data.x),0.0,float(position_data.z))
		if camera: camera.size=minf(camera.size,58.0)
		_set_camera_target(target)
		if travel_status_label:
			var notice:="KNOWN HOME SETTLEMENT  •  %s" % String(encounter.get("name","FOREIGN POLITY")).to_upper() if use_settlement else "ENCOUNTER SITE  •  %s  •  THEIR HOMELAND REMAINS UNLOCATED" % String(encounter.get("name","FOREIGN POLITY")).to_upper()
			travel_status_label.text=notice
			get_tree().create_timer(8.0).timeout.connect(_clear_transient_world_notice.bind(notice))
		return


func _clear_transient_world_notice(expected_text:String)->void:
	if travel_status_label and travel_status_label.text==expected_text: travel_status_label.text=""


func _select_campaign_region(index:int,selector:OptionButton,civ_id:String)->void:
	selected_civilization_id=civ_id
	selected_civilization_region_id=String(selector.get_item_metadata(index))
	civilization_feedback_text=""
	_close_civilizations_panel()
	_open_civilizations_panel()


func _select_campaign_region_button(civ_id:String,region_id:String)->void:
	selected_civilization_id=civ_id
	selected_civilization_region_id=region_id
	civilization_feedback_text=""
	_close_civilizations_panel()
	_open_civilizations_panel()


func _select_war_goal(index:int,selector:OptionButton,civ_id:String)->void:
	var goal:=String(selector.get_item_metadata(index))
	var result:=CivilizationSystem.set_player_war_goal(civ_id,goal,selected_civilization_region_id)
	civilization_feedback_text=String(result.get("error",result.get("message","War objective updated.")))
	selected_civilization_id=civ_id
	_close_civilizations_panel()
	_open_civilizations_panel()


func _conduct_civilization_action(civ_id:String,action:String)->void:
	if action=="launch_campaign":
		var campaign:Dictionary=MilitaryCampaign.launch_offensive(civ_id,selected_civilization_region_id)
		civilization_feedback_text=String(campaign.get("error","Campaign launched; issue round orders through Military Command."))
		selected_civilization_id=civ_id
		if campaign.has("error"):
			_close_civilizations_panel()
			_open_civilizations_panel()
		else:
			_close_civilizations_panel()
			if not MilitaryCommandUI.modal.visible: MilitaryCommandUI._toggle()
			MilitaryCommandUI._refresh()
		return
	if action in ["reinforce_occupation","evacuate_occupation"]:
		var occupation_result:Dictionary=MilitaryCampaign.reinforce_occupation(civ_id,selected_civilization_region_id) if action=="reinforce_occupation" else MilitaryCampaign.evacuate_occupation(civ_id,selected_civilization_region_id)
		civilization_feedback_text=String(occupation_result.get("error",occupation_result.get("message","Occupation order completed.")))
		selected_civilization_id=civ_id
		_close_civilizations_panel()
		_open_civilizations_panel()
		return
	if action in CivilizationSystem.CARRIED_DIPLOMATIC_ACTIONS:
		selected_civilization_id=civ_id
		_close_civilizations_panel()
		_open_diplomat_dispatch_panel(civ_id,action)
		return
	var result:Dictionary=CivilizationSystem.conduct_player_action(civ_id,action)
	civilization_feedback_text=String(result.get("error",result.get("message","Foreign policy updated.")))
	selected_civilization_id=civ_id
	_close_civilizations_panel()
	_open_civilizations_panel()
	_update_time_interface()


func _close_civilizations_panel()->void:
	if civilizations_panel and is_instance_valid(civilizations_panel): civilizations_panel.queue_free()
	civilizations_panel=null
	civilization_report_panel=null
	civilization_detail_root=null


func _open_settlement_dashboard()->void:
	_close_primary_destinations_except("settlement")
	if settlement_dashboard_panel and is_instance_valid(settlement_dashboard_panel): return
	settlement_dashboard_panel=Control.new()
	settlement_dashboard_panel.name="SettlementDashboard"
	settlement_dashboard_panel.size=get_viewport().get_visible_rect().size
	settlement_dashboard_panel.mouse_filter=Control.MOUSE_FILTER_STOP
	interface_layer.add_child(settlement_dashboard_panel)
	var dimmer:=ColorRect.new()
	dimmer.size=settlement_dashboard_panel.size
	dimmer.color=Color(0.006,0.010,0.011,0.90)
	settlement_dashboard_panel.add_child(dimmer)
	var modal:=PanelContainer.new()
	modal.size=Vector2(minf(1060.0,settlement_dashboard_panel.size.x-48.0),minf(620.0,settlement_dashboard_panel.size.y-40.0))
	modal.position=(settlement_dashboard_panel.size-modal.size)*0.5
	modal.add_theme_stylebox_override("panel",_knowledge_style(Color("#0b1213"),Color("#77806b"),1,4,18))
	settlement_dashboard_panel.add_child(modal)
	var root:=VBoxContainer.new()
	root.add_theme_constant_override("separation",9)
	modal.add_child(root)
	var header:=HBoxContainer.new()
	header.custom_minimum_size=Vector2(0,72)
	header.add_theme_constant_override("separation",10)
	root.add_child(header)
	var heading:=VBoxContainer.new()
	heading.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	header.add_child(heading)
	var eyebrow:=Label.new()
	eyebrow.text="SETTLEMENT  •  PEOPLE, WORK & LOCAL CONDITION"
	eyebrow.add_theme_font_size_override("font_size",10)
	eyebrow.add_theme_color_override("font_color",Color("#aeb382"))
	heading.add_child(eyebrow)
	var title:=Label.new()
	title.text=_settlement_display_name().to_upper()
	title.add_theme_font_size_override("font_size",25)
	title.add_theme_color_override("font_color",Color("#eee2cc"))
	heading.add_child(title)
	var classification:=String(_settlement_model().classification()).to_upper() if GameState.settlement_site_committed else "FOUNDING EXPEDITION"
	var subtitle:=Label.new()
	subtitle.text="%s  •  One local dashboard; histories and allocation controls are optional details." % classification
	subtitle.add_theme_font_size_override("font_size",11)
	subtitle.add_theme_color_override("font_color",Color("#98a19c"))
	heading.add_child(subtitle)
	var metrics:=GameState.simulation_metrics
	var function_profile:=CivilizationSystem.player_population_function_profile()
	_make_provision_stat(header,"POPULATION",_compact_population(GameState.population_total),Color("#9caf9a"))
	_make_provision_stat(header,"HEALTH","%d%%" % roundi(GameState.population_health*100.0),Color("#80a394"))
	_make_provision_stat(header,"PRODUCTIVE","%s" % _compact_population(int(function_profile.get("productive",0))),Color("#78a276"))
	_make_provision_stat(header,"HOUSING","%d%%" % roundi(float(metrics.get("housing_ratio",1.0))*100.0),Color("#a9946e"))
	root.add_child(HSeparator.new())
	_add_modal_action_brief(root,_population_attention_brief(function_profile,{"health":GameState.population_health,"housing_ratio":float(metrics.get("housing_ratio",1.0))}),Color("#8fa28e"))
	var cards:=HBoxContainer.new()
	cards.name="SettlementSummaryCards"
	cards.size_flags_vertical=Control.SIZE_EXPAND_FILL
	cards.add_theme_constant_override("separation",10)
	root.add_child(cards)
	var pregnancy:=GameState.pregnancy_summary()
	_settlement_dashboard_card(cards,"PEOPLE",Color("#8fa28e"),"%s productive  •  %s support  •  %s dependents\n%s active pregnancies  •  health %d%%" % [_compact_population(int(function_profile.get("productive",0))),_compact_population(int(function_profile.get("support",0))),_compact_population(int(function_profile.get("dependent",0))),_compact_population(int(pregnancy.get("active",0))),roundi(GameState.population_health*100.0)])
	_settlement_dashboard_card(cards,"WORK & SHELTER",Color("#b39a68"),"Labor efficiency %d%%  •  housing %d%%\nConstruction %s  •  completed works %d" % [roundi(float(metrics.get("labor_efficiency",0.0))*100.0),roundi(float(metrics.get("housing_ratio",1.0))*100.0),_compact_population(int(GameState.population_allocations.get("Construction",0))),GameState.settlement_completed.size()])
	var defense:=MilitaryCampaign.settlement_defense_snapshot()
	_settlement_dashboard_card(cards,"COMMITMENTS & DEFENSE",Color("#8c9bab"),"%s away  •  %s mobilized\n%s  •  integrity %d%%  •  lookout %.0f km" % [_compact_population(int(function_profile.get("absent",0))),_compact_population(int(function_profile.get("mobilized",0))),String(defense.get("short","OPEN GROUND")).to_upper(),roundi(float(defense.get("integrity",0.0))*100.0),float(defense.get("observation_radius_km",0.0))])
	var footer:=HBoxContainer.new()
	footer.alignment=BoxContainer.ALIGNMENT_END
	footer.add_theme_constant_override("separation",8)
	root.add_child(footer)
	var ledger:=Button.new()
	ledger.text="POPULATION HISTORY"
	ledger.custom_minimum_size=Vector2(180,40)
	ledger.tooltip_text="Open aggregate cohorts, births, deaths, and the consequence chronicle."
	ledger.pressed.connect(_open_population_from_settlement_dashboard)
	footer.add_child(ledger)
	var labor:=Button.new()
	labor.text="MANAGE LABOR"
	labor.custom_minimum_size=Vector2(150,40)
	labor.tooltip_text="Return to the map with the compact labor-allocation panel open."
	labor.pressed.connect(_open_people_from_settlement_dashboard)
	footer.add_child(labor)
	var close:=Button.new()
	close.text="RETURN TO MAP"
	close.custom_minimum_size=Vector2(150,40)
	close.pressed.connect(_close_settlement_dashboard)
	footer.add_child(close)


func _settlement_dashboard_card(parent:HBoxContainer,title_text:String,accent:Color,body_text:String)->void:
	var card:=PanelContainer.new()
	card.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	card.size_flags_vertical=Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel",_knowledge_style(Color("#10191a"),accent,1,4,14))
	parent.add_child(card)
	var body:=VBoxContainer.new()
	body.add_theme_constant_override("separation",8)
	card.add_child(body)
	var title:=Label.new()
	title.text=title_text
	title.add_theme_font_size_override("font_size",17)
	title.add_theme_color_override("font_color",accent)
	body.add_child(title)
	var detail:=Label.new()
	detail.text=body_text
	detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	detail.max_lines_visible=7
	detail.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	detail.size_flags_vertical=Control.SIZE_EXPAND_FILL
	detail.add_theme_font_size_override("font_size",13)
	detail.add_theme_color_override("font_color",Color("#d4d3c9"))
	body.add_child(detail)


func _close_settlement_dashboard()->void:
	if settlement_dashboard_panel and is_instance_valid(settlement_dashboard_panel): settlement_dashboard_panel.queue_free()
	settlement_dashboard_panel=null


func _open_population_from_settlement_dashboard()->void:
	_close_settlement_dashboard()
	call_deferred("_open_population_ledger")


func _open_people_from_settlement_dashboard()->void:
	_close_settlement_dashboard()
	call_deferred("_open_people_panel")


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
	heading.text="POPULATION"
	heading.add_theme_font_size_override("font_size",24)
	heading.add_theme_color_override("font_color",Color("#ecdfc4"))
	root.add_child(heading)
	var summary:=Label.new()
	var pregnancy_summary:=GameState.pregnancy_summary()
	summary.text="%s PEOPLE  •  HEALTH %d%%  •  LIFE EXPECTANCY %.1f YEARS\n%s ACTIVE PREGNANCIES  •  ~%s LIVE BIRTHS EXPECTED NEXT 12 MONTHS  •  %s BIRTHS / %s DEATHS RECORDED" % [_compact_population(GameState.population_total),roundi(GameState.population_health*100.0),GameState.projected_life_expectancy(),_compact_population(int(pregnancy_summary.active)),_compact_population(roundi(float(GameState.simulation_metrics.get("births_expected_next_year",pregnancy_summary.due_within_year)))),_compact_population(GameState.lifetime_births),_compact_population(GameState.lifetime_deaths)]
	summary.tooltip_text="Pregnancy losses %s  •  stillbirths %s  •  maternal deaths %s  •  neonatal deaths %s" % [_compact_population(GameState.lifetime_pregnancy_losses),_compact_population(GameState.lifetime_stillbirths),_compact_population(GameState.lifetime_maternal_deaths),_compact_population(GameState.lifetime_neonatal_deaths)]
	summary.add_theme_font_size_override("font_size",15)
	summary.add_theme_color_override("font_color",Color("#cfbd8c"))
	root.add_child(summary)
	var model:=Label.new()
	model.text="Numeric cohorts change through births, deaths, health, shelter, work, travel, policy, and war. No individual people are simulated."
	model.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	model.add_theme_font_size_override("font_size",13)
	model.add_theme_color_override("font_color",Color("#aeb0a8"))
	root.add_child(model)
	var function_profile:=CivilizationSystem.player_population_function_profile()
	var function_title:=Label.new()
	function_title.text="WHERE THE POPULATION IS COMMITTED  •  %s ACCOUNTED FOR" % _compact_population(int(function_profile.get("accounted",0)))
	function_title.tooltip_text="These five mutually exclusive totals always add to the living population. People away on scouts, envoys, or settlement convoys are removed from their former function until they return or arrive."
	function_title.add_theme_font_size_override("font_size",12)
	function_title.add_theme_color_override("font_color",Color("#cfbd8c"))
	root.add_child(function_title)
	var function_row:=HBoxContainer.new()
	function_row.add_theme_constant_override("separation",7)
	root.add_child(function_row)
	for function_variant in _population_function_display(function_profile):
		var function_record:Dictionary=function_variant
		var function_card:=PanelContainer.new()
		function_card.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		function_card.add_theme_stylebox_override("panel",_population_report_style(function_record.color))
		function_card.tooltip_text=String(function_record.note)
		function_row.add_child(function_card)
		var function_body:=VBoxContainer.new()
		function_body.add_theme_constant_override("separation",1)
		function_card.add_child(function_body)
		var function_label:=Label.new()
		function_label.text=String(function_record.label)
		function_label.add_theme_font_size_override("font_size",9)
		function_label.add_theme_color_override("font_color",function_record.color)
		function_body.add_child(function_label)
		var function_value:=Label.new()
		function_value.text=_compact_population(int(function_record.count))
		function_value.add_theme_font_size_override("font_size",16)
		function_value.add_theme_color_override("font_color",Color("#eee2cb"))
		function_body.add_child(function_value)
		var function_share:=Label.new()
		function_share.text="%.1f%%" % (float(function_record.share)*100.0)
		function_share.add_theme_font_size_override("font_size",9)
		function_share.add_theme_color_override("font_color",Color("#9da59f"))
		function_body.add_child(function_share)
	_add_modal_action_brief(root,_population_attention_brief(function_profile,{"health":GameState.population_health,"housing_ratio":float(GameState.simulation_metrics.get("housing_ratio",1.0))}),Color("#8fa28e"))
	root.add_child(HSeparator.new())
	var population_tabs:=TabContainer.new()
	population_tabs.name="PopulationDetailPages"
	population_tabs.size_flags_vertical=Control.SIZE_EXPAND_FILL
	population_tabs.add_theme_font_size_override("font_size",11)
	root.add_child(population_tabs)
	_build_population_detail_pages(population_tabs,pregnancy_summary)
	var footer:=HBoxContainer.new()
	footer.alignment=BoxContainer.ALIGNMENT_END
	root.add_child(footer)
	var close:=Button.new()
	close.text="RETURN TO MAP"
	close.custom_minimum_size=Vector2(150,40)
	close.pressed.connect(func(): population_ledger_panel.queue_free(); population_ledger_panel=null)
	footer.add_child(close)


func _build_population_detail_pages(tabs:TabContainer,pregnancy_summary:Dictionary)->void:
	var cohorts:=VBoxContainer.new()
	cohorts.name="CURRENT COHORTS"
	cohorts.add_theme_constant_override("separation",7)
	tabs.add_child(cohorts)
	var cohort_grid:=GridContainer.new()
	cohort_grid.columns=2
	cohort_grid.add_theme_constant_override("h_separation",8)
	cohort_grid.add_theme_constant_override("v_separation",8)
	cohorts.add_child(cohort_grid)
	for cohort_entry in [["FIRST TRIMESTER","first_trimester"],["SECOND TRIMESTER","second_trimester"],["THIRD TRIMESTER","third_trimester"],["POSTPARTUM / EARLY CARE","postpartum"]]:
		var cohort_card:=PanelContainer.new()
		cohort_card.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		cohort_card.add_theme_stylebox_override("panel",_population_report_style(Color("#8fa28e")))
		cohort_grid.add_child(cohort_card)
		var cohort_body:=Label.new()
		cohort_body.text="%s  •  %s PEOPLE\nShared care demand and risk" % [cohort_entry[0],_compact_population(int(pregnancy_summary.get(cohort_entry[1],0)))]
		cohort_body.add_theme_font_size_override("font_size",11)
		cohort_body.add_theme_color_override("font_color",Color("#d8ddcf"))
		cohort_card.add_child(cohort_body)
	var cohort_note:=Label.new()
	cohort_note.text="Pregnancy, birth, maternal, neonatal, and early-care risk are simulated as numeric cohorts."
	cohort_note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	cohort_note.add_theme_font_size_override("font_size",11)
	cohort_note.add_theme_color_override("font_color",Color("#9b9e98"))
	cohorts.add_child(cohort_note)

	var demographic_page:=VBoxContainer.new()
	demographic_page.name="BIRTHS & DEATHS"
	demographic_page.add_theme_constant_override("separation",6)
	tabs.add_child(demographic_page)
	_build_population_history_page(demographic_page,"demographic")

	var consequence_page:=VBoxContainer.new()
	consequence_page.name="CONSEQUENCES"
	consequence_page.add_theme_constant_override("separation",6)
	tabs.add_child(consequence_page)
	_build_population_history_page(consequence_page,"consequence")
	if not GameState.demographic_ledger.is_empty(): tabs.current_tab=1


func _build_population_history_page(page:VBoxContainer,kind:String)->void:
	var pager:=HBoxContainer.new()
	pager.alignment=BoxContainer.ALIGNMENT_END
	pager.add_theme_constant_override("separation",6)
	page.add_child(pager)
	var previous:=Button.new()
	previous.text="‹ PREVIOUS"
	previous.custom_minimum_size=Vector2(88,28)
	pager.add_child(previous)
	var page_label:=Label.new()
	page_label.custom_minimum_size=Vector2(70,28)
	page_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	page_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	page_label.add_theme_font_size_override("font_size",11)
	pager.add_child(page_label)
	var next:=Button.new()
	next.text="NEXT ›"
	next.custom_minimum_size=Vector2(72,28)
	pager.add_child(next)
	var body:=VBoxContainer.new()
	body.size_flags_vertical=Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation",6)
	body.set_meta("history_page",0)
	page.add_child(body)
	previous.pressed.connect(_change_population_history_page.bind(body,page_label,previous,next,kind,-1))
	next.pressed.connect(_change_population_history_page.bind(body,page_label,previous,next,kind,1))
	_refresh_population_history_page(body,page_label,previous,next,kind)


func _population_history_records(kind:String)->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	if kind=="demographic":
		for record_variant in GameState.demographic_ledger:
			result.append((record_variant as Dictionary).duplicate(true))
	else:
		for event_variant in GameState.simulation_events:
			var event:Dictionary=event_variant
			if String(event.get("domain",""))!="population": result.append(event.duplicate(true))
	return result


func _change_population_history_page(body:VBoxContainer,page_label:Label,previous:Button,next:Button,kind:String,delta:int)->void:
	body.set_meta("history_page",maxi(0,int(body.get_meta("history_page",0))+delta))
	_refresh_population_history_page(body,page_label,previous,next,kind)


func _refresh_population_history_page(body:VBoxContainer,page_label:Label,previous:Button,next:Button,kind:String)->void:
	for child in body.get_children():
		body.remove_child(child)
		child.queue_free()
	var records:=_population_history_records(kind)
	var page_size:=3 if kind=="demographic" else 5
	var page_count:=maxi(1,ceili(float(records.size())/float(page_size)))
	var page:=clampi(int(body.get_meta("history_page",0)),0,page_count-1)
	body.set_meta("history_page",page)
	page_label.text="%d / %d" % [page+1,page_count]
	previous.disabled=page<=0
	next.disabled=page>=page_count-1
	if records.is_empty():
		var quiet:=Label.new()
		quiet.text="No %s have been recorded yet." % ("births or deaths" if kind=="demographic" else "wider consequences")
		quiet.add_theme_font_size_override("font_size",12)
		quiet.add_theme_color_override("font_color",Color("#9b9e98"))
		body.add_child(quiet)
		return
	var start:=page*page_size
	var finish:=mini(records.size(),start+page_size)
	for index in range(start,finish):
		var record:Dictionary=records[index]
		if kind=="demographic": _add_population_demographic_record(body,record)
		else: _add_population_consequence_record(body,record)


func _add_population_demographic_record(parent:VBoxContainer,record:Dictionary)->void:
	var record_kind:=String(record.get("kind","death"))
	var count:=int(record.get("count",1))
	var start_day:=int(record.get("start_day",record.get("day",0)))+1
	var end_day:=int(record.get("end_day",record.get("day",0)))+1
	var period:="DAY %d" % end_day if start_day==end_day else "DAYS %d–%d" % [start_day,end_day]
	var cause:=String(record.get("cause","Unknown"))
	var cause_label:="SUPPORTED BY CURRENT CONDITIONS" if record_kind=="birth" and cause=="Births" else cause.to_upper()
	var card:=PanelContainer.new()
	card.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel",_population_report_style(Color("#b8a36d") if record_kind=="birth" else Color("#a95f52")))
	parent.add_child(card)
	var text:=Label.new()
	text.text="%s  •  %d %s%s  •  %s\n%s  •  POPULATION AFTER %s\n%s  •  WATER %d%%  HEALTH %d%%  SHELTER %d%%" % [period,count,"BIRTH" if record_kind=="birth" else "DEATH","" if count==1 else "S",cause_label,String(record.get("location","Unknown location")),_compact_population(int(record.get("population_after",GameState.population_total))),String(record.get("description","No causal record was preserved.")),roundi(float(record.get("water_intake_ratio",0.0))*100.0),roundi(float(record.get("health",0.0))*100.0),roundi(float(record.get("housing_ratio",0.0))*100.0)]
	text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	text.add_theme_font_size_override("font_size",11)
	text.add_theme_color_override("font_color",Color("#d6d2c7"))
	card.add_child(text)


func _add_population_consequence_record(parent:VBoxContainer,event:Dictionary)->void:
	var card:=PanelContainer.new()
	card.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel",_population_report_style(Color("#82949a")))
	parent.add_child(card)
	var text:=Label.new()
	text.text="DAY %d  •  %s\n%s" % [int(event.get("day",0))+1,String(event.get("title","Event")).to_upper(),String(event.get("description",""))]
	text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	text.add_theme_font_size_override("font_size",11)
	text.add_theme_color_override("font_color",Color("#c7c7bf"))
	card.add_child(text)


# Fixed display metadata for the conserved population-function profile. Keeping
# this separate from age cohorts prevents "working age" from being confused
# with actual availability: a working-age scout is shown as away, a trained
# formation as mobilized, and research/administration as support rather than
# productive extraction. No food figures belong in this view.
func _population_function_display(profile:Dictionary)->Array[Dictionary]:
	var total:=maxi(1,int(profile.get("total",GameState.population_total)))
	var definitions:Array[Dictionary]=[
		{"id":"productive","label":"PRODUCTIVE","color":Color("#72a477"),"note":"Direct production, survey, extraction, construction, craft, and logistics labor currently available to the civilization."},
		{"id":"support","label":"SUPPORT","color":Color("#72a0aa"),"note":"Researchers and administrators building knowledge, coordination, and public capacity."},
		{"id":"mobilized","label":"MOBILIZED","color":Color("#bd7770"),"note":"Population committed to defense, training, field forces, and occupation rather than ordinary civilian work."},
		{"id":"dependent","label":"DEPENDENT","color":Color("#b89b6b"),"note":"Children, elders, and other aggregate cohorts supported by the available workforce."},
		{"id":"absent","label":"AWAY","color":Color("#c57c5f"),"note":"Scouts, envoys, missing parties, and settlement convoys physically absent from owned settlements."}
	]
	var result:Array[Dictionary]=[]
	for definition_variant in definitions:
		var record:Dictionary=definition_variant.duplicate(true)
		record["count"]=maxi(0,int(profile.get(String(record.id),0)))
		record["share"]=float(record.count)/float(total)
		result.append(record)
	return result


func _population_attention_brief(profile:Dictionary,conditions:Dictionary)->Dictionary:
	var total:=maxf(1.0,float(profile.get("total",GameState.population_total)))
	var health:=clampf(float(conditions.get("health",1.0)),0.0,1.0)
	var housing:=maxf(0.0,float(conditions.get("housing_ratio",1.0)))
	var absent_share:=float(profile.get("absent",0))/total
	var mobilized_share:=float(profile.get("mobilized",0))/total
	var productive_share:=float(profile.get("productive",0))/total
	if health<0.70:
		return {"status":"POPULATION HEALTH IS THE MAIN PRESSURE","why":"Average health is %d%%, reducing survival and useful work." % roundi(health*100.0),"next":"Open Provisions & Water, then improve intake, water safety, shelter, or care."}
	if housing<0.95:
		return {"status":"SHELTER IS BELOW POPULATION NEED","why":"Housing covers only %d%% of the living population." % roundi(housing*100.0),"next":"Assign Construction labor and secure the materials required for housing."}
	if absent_share>0.08:
		return {"status":"MANY PEOPLE ARE AWAY","why":"%.1f%% are committed to scouts, envoys, missing parties, or settlement convoys." % (absent_share*100.0),"next":"Review active missions before committing more population away from settlements."}
	if mobilized_share>0.12:
		return {"status":"MILITARY COMMITMENTS ARE DISPLACING CIVILIAN WORK","why":"%.1f%% of the population is mobilized." % (mobilized_share*100.0),"next":"Review armies, garrisons, and occupation needs before expanding mobilization."}
	return {"status":"POPULATION COMMITMENTS ARE SUSTAINABLE","why":"%.1f%% remain in direct productive roles and no dominant demographic pressure is visible." % (productive_share*100.0),"next":"No immediate change is required; watch health, shelter, dependents, and people away."}

func _update_time_interface() -> void:
	if interface_layer == null:
		return
	if hud:
		hud.refresh()
	if date_label:
		var absolute_hour:=int(floor(GameState.elapsed_days*24.0))
		var absolute_day:=absolute_hour/24
		var year := absolute_day / 365 + 1
		var day_of_year := absolute_day % 365 + 1
		var hour_of_day:=absolute_hour%24
		date_label.text = "Y%d  •  D%d  •  %02d:00" % [year, day_of_year,hour_of_day]
	if world_header_label:
		var focus:=GameState.founding_focus_definition()
		world_header_label.text=GameState.province_name.to_upper()
		world_header_label.tooltip_text="%s\n%s\n\nFOUNDING FOCUS  •  %s\n%s\nPermanent strengths: %s\nTradeoff: %s" % [GameState.province_name.to_upper(),_settlement_display_name() if GameState.settlement_site_committed else "FOUNDING EXPEDITION",String(focus.get("name","Not yet chosen")),String(focus.get("creed","Choose before time begins.")),String(focus.get("strengths","")),String(focus.get("tradeoff",""))]
	if world_competition_button:
		var competition:Dictionary=CivilizationSystem.known_competition_snapshot()
		var exploration:Dictionary=competition.get("exploration",{})
		var observation:Dictionary=CivilizationSystem.local_observation_snapshot()
		if int(observation.get("visible_count",0))>0:
			world_competition_button.text="WORLD  •  %d" % int(observation.visible_count)
			world_competition_button.tooltip_text="%d aggregate foreign formation%s currently inside the %.0f km local observation range." % [int(observation.visible_count)," is" if int(observation.visible_count)==1 else "s are",float(observation.radius_km)]
		elif bool(exploration.get("active",false)):
			world_competition_button.text="SCOUT  %dD" % int(exploration.get("days_remaining",0))
			world_competition_button.tooltip_text="Scout party away for %d more days. Its observations remain physically with the party; interception or capture before return destroys the report." % int(exploration.get("days_remaining",0))
		elif bool(competition.get("global_rank_hidden",false)):
			world_competition_button.text="WORLD  •  %d" % int(competition.get("contacted_count",0))
			world_competition_button.tooltip_text="%d known foreign civilization%s. Global standing remains unknown. Open scouting, returned reports, diplomacy, and estimated competition." % [int(competition.get("contacted_count",0)),"" if int(competition.get("contacted_count",0))==1 else "s"]
		else:
			world_competition_button.text="WORLD  #%d" % int(competition.player_rank)
			world_competition_button.tooltip_text="Known competitive standing: rank %d of %d, led by %s." % [int(competition.player_rank),int(competition.contender_count),String((competition.leader as Dictionary).name)]
	_refresh_knowledge_record()
	for speed_key in time_speed_buttons:
		var speed_button:Button=time_speed_buttons[speed_key]
		speed_button.button_pressed=int(game_speed)==int(speed_key)
	if population_summary_label:
		var balance := float(GameState.simulation_metrics.get("food_balance",-1.0))
		var balance_mark := "▲" if balance>=0.0 else "▼"
		population_summary_label.text = "SETTLEMENT"
		population_summary_label.tooltip_text = "Population %s  •  Health %d%%  •  Projected life expectancy %.1f years.\nOpen population, cohorts, births, deaths, health, and labor allocation." % [_compact_population(GameState.population_total),roundi(GameState.population_health*100.0),GameState.projected_life_expectancy()]
		if provisions_button:
			var net:=float(GameState.simulation_metrics.get("food_net",0.0))
			var food_days:=float(GameState.simulation_metrics.get("food_days",30.0))
			provisions_button.text="ECONOMY"
			provisions_button.tooltip_text="Food %.1f days  •  %s  •  %+.1f today.\nOpen provisions, water, material flow, storage, and bottlenecks." % [food_days,balance_mark,net]
		if materials_button:
			var known_count:=ResourceSystem.visible_deposits().size()
			var material_bulk:=ResourceSystem.stored_bulk()
			materials_button.text="MATERIALS %.0f" % material_bulk
			materials_button.tooltip_text="%.1f bulk of carried and settled materials  •  %d recognized occurrences.\nThis is physical inventory, not a market value. Foreign trade does not exist without a returned emissary contract.\nOpen recognized sources, extraction, hauling, losses, and storage." % [material_bulk,known_count]
	if convoy_map_label:
		var settlement_classification:String = String(_settlement_model().classification()).to_upper() if "Hearth Circle" in GameState.settlement_completed else ""
		var defense_name:=String(MilitaryCampaign.settlement_defense_snapshot().get("short","Open ground")).to_upper()
		var primary_population:=roundi(_settlement_model().primary_population_exact()) if "Hearth Circle" in GameState.settlement_completed else GameState.population_total
		convoy_map_label.text="%s  •  %s  •  %s\nDEFENSE: %s" % [_settlement_display_name(),settlement_classification,_compact_population(primary_population),defense_name] if settlement_classification!="" else "%s  •  %s\nDEFENSE: %s" % [_settlement_display_name(),_compact_population(primary_population),defense_name]
	if people_panel_title:
		people_panel_title.text=_settlement_display_name()
	if people_summary_label:
		var settlement_status := "Traveling convoy" if travel_active else ("Founding settlement" if GameState.settlement_site_committed and GameState.settlement_completed.is_empty() else ("Halted convoy" if GameState.settlement_completed.is_empty() else "Growing settlement"))
		var pregnancy_summary:=GameState.pregnancy_summary()
		people_summary_label.text = "POP %s  •  LABOR %s  •  EFF %d%%\n%s\nPREGNANT %s  •  BIRTHS/12M %s" % [_compact_population(GameState.population_total),_compact_population(_able_population()),roundi(float(GameState.simulation_metrics.get("labor_efficiency",0.72))*100.0),settlement_status.to_upper(),_compact_population(int(pregnancy_summary.active)),_compact_population(roundi(float(GameState.simulation_metrics.get("births_expected_next_year",pregnancy_summary.due_within_year))))]
	if travel_active:
		var remaining := maxf(0.0, travel_days_total - travel_days_elapsed)
		var speed_factor:=roundi(float(GameState.simulation_metrics.get("travel_speed_factor",1.0))*100.0)
		travel_status_label.text = "CONVOY MOVING  •  %s remaining  •  pace %d%%  •  food %.1f days" % [_format_game_duration(remaining),speed_factor,float(GameState.simulation_metrics.get("food_days",0.0))]
	elif bool(GameState.settlement_convoy.get("active",false)):
		var colony_convoy:Dictionary=GameState.settlement_convoy
		var colony_remaining:=maxf(0.0,float(colony_convoy.get("arrival_day",GameState.elapsed_days))-GameState.elapsed_days)
		travel_status_label.text="SETTLEMENT CONVOY EN ROUTE  •  %s people  •  %s remaining  •  %d%% complete" % [_compact_population(int(colony_convoy.get("population",0))),_format_game_duration(colony_remaining),roundi(float(colony_convoy.get("progress",0.0))*100.0)]
	elif GameState.convoy_emergency_halt_reason!="":
		travel_status_label.text="CONVOY HALTED  •  %s  •  PAUSED" % GameState.convoy_emergency_halt_reason
	elif GameState.settlement_site_committed and "Hearth Circle" not in GameState.settlement_completed:
		travel_status_label.text="SETTLEMENT FOUNDING  •  HEARTH CIRCLE EMERGING FROM CURRENT ROLES"
	elif settlement_convoy_targeting:
		travel_status_label.text="SELECT KNOWN LAND FOR THE NEW SETTLEMENT  •  click a viable destination or press the button again to cancel"
	elif placement_building == "":
		travel_status_label.text = ("FOUNDING CONVOY READY  •  LEFT-CLICK LAND TO TRAVEL  •  FOUND SETTLEMENT ON THE TOOLBAR BELOW" if not GameState.settlement_site_committed else "RECOGNIZED RESOURCES %s  •  MOUSE WHEEL TO ZOOM  •  TOOLBAR FOR MAP COMMANDS" % ("SHOWN" if resource_view_enabled else "HIDDEN"))
	if start_settlement_button:
		# All map commands now live together under ACTIONS. The contextual status
		# above provides onboarding without a modal-sized permanent map obstruction.
		start_settlement_button.visible=false
		start_settlement_button.disabled=false
		if not GameState.settlement_site_committed and travel_active:
			start_settlement_button.text="START SETTLEMENT\nHalt the moving convoy here and begin"
		else:
			start_settlement_button.text="START SETTLEMENT\nFound at the convoy's current location"
	_update_resource_view_toggle()
	_refresh_actions_menu()
	_refresh_map_help()

func _settlement_display_name() -> String:
	if GameState.settlement_name.strip_edges()!="":
		return GameState.settlement_name.strip_edges().to_upper()
	if "Hearth Circle" in GameState.settlement_completed:
		return _settlement_model().classification().to_upper()
	if GameState.settlement_site_committed:
		return "FOUNDING SITE"
	return "FOUNDING CONVOY"

func _set_game_speed(speed: float) -> void:
	if speed>0.0 and GameState.founding_focus=="":
		game_speed=0.0
		if not founding_focus_panel or not is_instance_valid(founding_focus_panel): _open_founding_focus_panel()
		_update_time_interface()
		return
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
	if value >= 1000000000000:
		return "%.1fT" % (float(value) / 1000000000000.0)
	if value >= 1000000000:
		return "%.1fB" % (float(value) / 1000000000.0)
	if value >= 1000000:
		return "%.1fM" % (float(value) / 1000000.0)
	if value >= 10000:
		return "%.1fK" % (float(value) / 1000.0)
	return str(value)


func _open_systems_hub()->void:
	_close_primary_destinations_except("civilization")
	if systems_hub_panel and is_instance_valid(systems_hub_panel): return
	systems_hub_panel=Control.new()
	systems_hub_panel.name="CivilizationHub"
	systems_hub_panel.size=get_viewport().get_visible_rect().size
	systems_hub_panel.mouse_filter=Control.MOUSE_FILTER_STOP
	interface_layer.add_child(systems_hub_panel)
	var dimmer:=ColorRect.new()
	dimmer.size=systems_hub_panel.size
	dimmer.color=Color(0.006,0.009,0.011,0.88)
	systems_hub_panel.add_child(dimmer)
	var modal:=PanelContainer.new()
	modal.name="CivilizationDashboard"
	modal.size=Vector2(minf(1120.0,systems_hub_panel.size.x-48.0),minf(650.0,systems_hub_panel.size.y-40.0))
	modal.position=(systems_hub_panel.size-modal.size)*0.5
	modal.add_theme_stylebox_override("panel",_knowledge_style(Color("#0b1215"),Color("#817353"),1,4,20))
	systems_hub_panel.add_child(modal)
	var root:=VBoxContainer.new()
	root.add_theme_constant_override("separation",10)
	modal.add_child(root)
	var header:=HBoxContainer.new()
	header.custom_minimum_size=Vector2(0,64)
	root.add_child(header)
	var heading:=VBoxContainer.new()
	heading.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	header.add_child(heading)
	var eyebrow:=Label.new()
	eyebrow.text="CIVILIZATION  •  DEVELOPMENT, SOCIETY & GOVERNMENT"
	eyebrow.add_theme_font_size_override("font_size",10)
	eyebrow.add_theme_color_override("font_color",Color("#c6ad6b"))
	heading.add_child(eyebrow)
	var title:=Label.new()
	title.text="CIVILIZATION OVERVIEW"
	title.add_theme_font_size_override("font_size",24)
	title.add_theme_color_override("font_color",Color("#eee2cc"))
	heading.add_child(title)
	var focus:=GameState.founding_focus_definition()
	var summary:=Label.new()
	summary.text="%s  •  Population %s  •  Founding focus: %s" % [_settlement_display_name(),_compact_population(GameState.population_total),String(focus.get("name","not chosen"))]
	summary.add_theme_font_size_override("font_size",11)
	summary.add_theme_color_override("font_color",Color("#9fa8a3"))
	heading.add_child(summary)
	var return_to_map:=Button.new()
	return_to_map.text="RETURN TO MAP"
	return_to_map.custom_minimum_size=Vector2(150,38)
	return_to_map.pressed.connect(_close_systems_hub)
	header.add_child(return_to_map)
	root.add_child(HSeparator.new())
	_add_modal_action_brief(root,_civilization_overview_brief(),Color("#9b8660"))
	var cards:=HBoxContainer.new()
	cards.name="CivilizationSummaryCards"
	cards.size_flags_vertical=Control.SIZE_EXPAND_FILL
	cards.add_theme_constant_override("separation",10)
	root.add_child(cards)
	var development:=ProgressionSystem.tree_snapshot()
	_civilization_dashboard_card(cards,"DEVELOPMENT",Color("#8798b5"),"%d established  •  %d active lines" % [int(development.get("known_discoveries",GameState.known_discoveries.size())),int(development.get("active_inquiries",GameState.active_investigations.size()))],"Set broad research priorities; evidence, place, prior findings, and chance determine the concrete discoveries that follow.","SET RESEARCH PRIORITIES","_open_knowledge_panel","VIEW ESTABLISHED DEVELOPMENT","_open_progression_panel")
	var identity:=SocietalValuesModel.identity_snapshot(GameState.societal_values)
	var average_capacity:=_civilization_average_capacity()
	_civilization_dashboard_card(cards,"SOCIETY",Color("#70a8a0"),"%s  •  capacity %d%%" % [String(identity.get("name","FORMING ORDER")),roundi(average_capacity*100.0)],"See the twelve capacities the civilization can actually sustain, plus the values and institutions shaping how it organizes itself.","OPEN SOCIETY","_open_society_panel","VALUES & INSTITUTIONS","_open_values_panel")
	var active_policies:=ConsequenceEngine.active_policies().size()
	_civilization_dashboard_card(cards,"GOVERNMENT",Color("#b99b62"),"%d active policies  •  %d directives" % [active_policies,GameState.sovereign_orders.size()],"Offices, administrative reach, standing policy, and directives belong here. Directives change only what the simulation can physically and institutionally carry out.","OPEN GOVERNMENT","_open_government_panel","DIRECTIVES & COUNCIL","_open_council_panel")
	var footer_note:=Label.new()
	footer_note.text="Three systems, one civilization. Open a section only when you need to change or inspect it."
	footer_note.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	footer_note.add_theme_font_size_override("font_size",10)
	footer_note.add_theme_color_override("font_color",Color("#858f8a"))
	root.add_child(footer_note)


func _civilization_average_capacity()->float:
	if GameState.society_capacities.is_empty(): return 0.0
	var total:=0.0
	for value in GameState.society_capacities.values(): total+=float(value)
	return total/float(GameState.society_capacities.size())


func _civilization_overview_brief()->Dictionary:
	if not GameState.council_inbox.is_empty():
		return {"status":"%d COUNCIL REPORTS AWAIT REVIEW" % GameState.council_inbox.size(),"why":"The council has recorded pressures or consequences that may require a directive.","next":"Open Directives & Council if you want to respond; reports do not pause the simulation."}
	var weakest:=""
	var weakest_value:=2.0
	for domain_variant in GameState.society_capacities:
		var domain:=String(domain_variant)
		var value:=float(GameState.society_capacities[domain])
		if value<weakest_value:
			weakest=domain
			weakest_value=value
	if weakest!="" and weakest_value<0.55:
		return {"status":"MAIN CIVILIZATION CONSTRAINT: %s %d%%" % [weakest.to_upper(),roundi(weakest_value*100.0)],"why":"This is the weakest of the twelve aggregate capacities and is limiting what the civilization can sustain.","next":"Open Society for its drivers, then Development or Government only if a specific change is required."}
	return {"status":"NO CIVILIZATION-WIDE DECISION IS URGENT","why":"No unread council pressure or failing systemic capacity currently dominates.","next":"Let time run, or open one of the three sections when you want to change direction."}


func _civilization_dashboard_card(parent:HBoxContainer,title_text:String,accent:Color,status_text:String,description:String,primary_text:String,primary_method:StringName,secondary_text:String,secondary_method:StringName)->void:
	var card:=PanelContainer.new()
	card.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	card.size_flags_vertical=Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel",_knowledge_style(Color("#0d171a"),accent,1,4,14))
	parent.add_child(card)
	var body:=VBoxContainer.new()
	body.add_theme_constant_override("separation",8)
	card.add_child(body)
	var title:=Label.new()
	title.text=title_text
	title.add_theme_font_size_override("font_size",18)
	title.add_theme_color_override("font_color",accent)
	body.add_child(title)
	var status:=Label.new()
	status.text=status_text
	status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	status.max_lines_visible=2
	status.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	status.add_theme_font_size_override("font_size",13)
	status.add_theme_color_override("font_color",Color("#e3ddcf"))
	body.add_child(status)
	var explanation:=Label.new()
	explanation.text=description
	explanation.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	explanation.max_lines_visible=5
	explanation.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	explanation.size_flags_vertical=Control.SIZE_EXPAND_FILL
	explanation.add_theme_font_size_override("font_size",11)
	explanation.add_theme_color_override("font_color",Color("#9fa8a3"))
	body.add_child(explanation)
	var primary:=Button.new()
	primary.text=primary_text
	primary.custom_minimum_size=Vector2(0,42)
	primary.pressed.connect(_open_from_systems_hub.bind(primary_method))
	body.add_child(primary)
	var secondary:=Button.new()
	secondary.text=secondary_text
	secondary.custom_minimum_size=Vector2(0,34)
	secondary.pressed.connect(_open_from_systems_hub.bind(secondary_method))
	body.add_child(secondary)


func _open_from_systems_hub(method_name:StringName)->void:
	_close_systems_hub()
	call_deferred(method_name)


func _close_systems_hub()->void:
	if systems_hub_panel and is_instance_valid(systems_hub_panel): systems_hub_panel.queue_free()
	systems_hub_panel=null


func _back_to_civilization_from_research()->void:
	if knowledge_panel and is_instance_valid(knowledge_panel): knowledge_panel.queue_free()
	knowledge_panel=null
	knowledge_record_container=null
	knowledge_investigation_widgets.clear()
	knowledge_discovery_widgets.clear()
	knowledge_mode_buttons.clear()
	knowledge_category_selector=null
	call_deferred("_open_systems_hub")


func _back_to_civilization_from_council()->void:
	if council_panel and is_instance_valid(council_panel): council_panel.queue_free()
	council_panel=null
	call_deferred("_open_systems_hub")


func _back_to_civilization_from_government()->void:
	if government_panel and is_instance_valid(government_panel): government_panel.queue_free()
	government_panel=null
	call_deferred("_open_systems_hub")


func _back_to_civilization_from_society()->void:
	if society_panel and is_instance_valid(society_panel): society_panel.queue_free()
	society_panel=null
	call_deferred("_open_systems_hub")


func _back_to_civilization_from_progression()->void:
	if progression_panel and is_instance_valid(progression_panel): progression_panel.queue_free()
	progression_panel=null
	call_deferred("_open_systems_hub")


func _open_society_panel()->void:
	society_panel_mode="overview"
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
	title.text="SOCIETY"
	title.add_theme_font_size_override("font_size",24)
	title.add_theme_color_override("font_color",Color("#f0e5cf"))
	heading.add_child(title)
	var subtitle:=Label.new()
	subtitle.text="Values describe what should happen. Institutions describe how power works. Capacities describe what society can do."
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
	var progression_button:=Button.new()
	progression_button.text="OPEN DEVELOPMENT\nPATHS & BLOCKERS"
	progression_button.custom_minimum_size=Vector2(148,50)
	progression_button.tooltip_text="See what this civilization has actually established, where attention is concentrated, and which frontiers are beginning to surface."
	progression_button.pressed.connect(func(): society_panel.queue_free(); society_panel=null; _open_progression_panel())
	header.add_child(progression_button)
	var identity:Dictionary=SocietalValuesModel.identity_snapshot(GameState.societal_values)
	var values_button:=Button.new()
	values_button.text="VIEW VALUES & INSTITUTIONS\n%s" % String(identity.get("name","FORMING SOCIAL ORDER"))
	values_button.custom_minimum_size=Vector2(210,50)
	values_button.tooltip_text="%s\nAlignment %d%% • tension %d%%\nOpen the lived, official, and institutional value system." % [String(identity.get("summary","Values still forming")),roundi(float(identity.get("alignment",1.0))*100.0),roundi(float(identity.get("tension",0.0))*100.0)]
	values_button.pressed.connect(func(): society_panel.queue_free(); society_panel=null; _open_values_panel())
	header.add_child(values_button)
	root.add_child(HSeparator.new())
	_add_modal_action_brief(root,_society_attention_brief(GameState.society_capacities),Color("#70a8a0"))
	var scroll:=FIT_CONTENT_PANEL.new()
	scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
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
	close.text="BACK TO CIVILIZATION"
	close.custom_minimum_size=Vector2(150,36)
	close.pressed.connect(_back_to_civilization_from_society)
	footer.add_child(close)


func _society_attention_brief(capacities:Dictionary)->Dictionary:
	if capacities.is_empty():
		return {"status":"SOCIETY HAS NOT BEEN MEASURED YET","why":"No capacity record exists before the first simulation update.","next":"Advance time once to establish the first twelve-system baseline."}
	var weakest:=""
	var weakest_value:=2.0
	for domain_variant in capacities:
		var domain:=String(domain_variant)
		var value:=clampf(float(capacities[domain]),0.0,1.0)
		if value<weakest_value:
			weakest=domain
			weakest_value=value
	var next_by_domain:Dictionary={
		"nutrition":"Open Provisions & Water to find the supply, reserve, or intake constraint.",
		"health":"Check Population and Provisions & Water for health, water, shelter, and care pressures.",
		"knowledge":"Open Research Priorities and concentrate more of the aggregate research workforce.",
		"production":"Open Material Flow, then assign labor or priorities where supply is blocked.",
		"infrastructure":"Open Development Paths to see the next housing, works, and material blockers.",
		"logistics":"Open Material Flow and improve carrying or routes where goods wait at sources.",
		"security":"Open Military to review training, readiness, garrisons, and field commitments."
	}
	var next_text:=String(next_by_domain.get(weakest,"Open Development Paths to see which evidence, adoption, population, or supporting system is holding this capacity back."))
	if weakest_value>=0.65:
		return {"status":"NO SYSTEM IS IN IMMEDIATE FAILURE","why":"The lowest current capacity is %s at %d%%." % [weakest.capitalize(),roundi(weakest_value*100.0)],"next":"Use Development Paths for long-term blockers or Values & Institutions for social tension."}
	return {"status":"WEAKEST SYSTEM: %s %d%%" % [weakest.to_upper(),roundi(weakest_value*100.0)],"why":_dynamic_definition(weakest).get_slice("\n",0),"next":next_text}


func _open_values_panel()->void:
	society_panel_mode="values"
	if society_panel and is_instance_valid(society_panel): society_panel.queue_free()
	GameState.societal_values=SocietalValuesModel.normalize_state(GameState.societal_values)
	var identity:Dictionary=SocietalValuesModel.identity_snapshot(GameState.societal_values)
	society_panel=Control.new()
	society_panel.name="SocietalValues"
	society_panel.size=get_viewport().get_visible_rect().size
	society_panel.mouse_filter=Control.MOUSE_FILTER_STOP
	interface_layer.add_child(society_panel)
	var dimmer:=ColorRect.new()
	dimmer.size=society_panel.size
	dimmer.color=Color(0.004,0.007,0.009,0.94)
	society_panel.add_child(dimmer)
	var modal:=PanelContainer.new()
	modal.position=Vector2(18,14)
	modal.size=society_panel.size-Vector2(36,28)
	modal.add_theme_stylebox_override("panel",_knowledge_style(Color("#091215"),Color("#8a7548"),1,4,14))
	society_panel.add_child(modal)
	var root:=VBoxContainer.new()
	root.add_theme_constant_override("separation",8)
	modal.add_child(root)
	var header:=HBoxContainer.new()
	header.custom_minimum_size=Vector2(0,70)
	root.add_child(header)
	var heading:=VBoxContainer.new()
	heading.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	header.add_child(heading)
	var eyebrow:=Label.new()
	eyebrow.text="EMERGENT IDENTITY  •  NOT A SELECTED IDEOLOGY"
	eyebrow.add_theme_font_size_override("font_size",10)
	eyebrow.add_theme_color_override("font_color",Color("#c5ad6e"))
	heading.add_child(eyebrow)
	var title:=Label.new()
	title.text=String(identity.get("name","FORMING SOCIAL ORDER"))
	title.add_theme_font_size_override("font_size",24)
	title.add_theme_color_override("font_color",Color("#f0e5cf"))
	heading.add_child(title)
	var subtitle:=Label.new()
	subtitle.text="%s  •  Founding focus: %s" % [String(identity.get("summary","No dominant value yet")),String(GameState.founding_focus_definition().get("name","UNDECIDED"))]
	subtitle.add_theme_font_size_override("font_size",10)
	subtitle.add_theme_color_override("font_color",Color("#929d98"))
	heading.add_child(subtitle)
	var alignment_box:=VBoxContainer.new()
	alignment_box.custom_minimum_size=Vector2(210,0)
	header.add_child(alignment_box)
	var alignment_title:=Label.new()
	alignment_title.text="SOCIAL ALIGNMENT"
	alignment_title.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	alignment_title.add_theme_font_size_override("font_size",10)
	alignment_title.add_theme_color_override("font_color",Color("#8f9994"))
	alignment_box.add_child(alignment_title)
	var alignment_value:=Label.new()
	alignment_value.text="%d%%" % roundi(float(identity.get("alignment",1.0))*100.0)
	alignment_value.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	alignment_value.add_theme_font_size_override("font_size",24)
	alignment_value.add_theme_color_override("font_color",_dynamic_score_color(float(identity.get("alignment",1.0))))
	alignment_value.tooltip_text="Agreement between lived values, official claims, and institutions. Misalignment reduces legitimacy and cohesion and can drive reform or unrest."
	alignment_box.add_child(alignment_value)
	root.add_child(HSeparator.new())
	var built_expression:=Label.new()
	built_expression.text="SETTLEMENT DESIGN  •  %s" % _architecture_expression_text(SocietalValuesModel.architecture_snapshot(GameState.societal_values)).to_upper()
	built_expression.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	built_expression.tooltip_text="This is how the civilization's aggregate values currently influence settlement alignment, public space, massing, lanes, enclosure, and response to terrain. It does not create individual building records."
	built_expression.add_theme_font_size_override("font_size",9)
	built_expression.add_theme_color_override("font_color",Color("#a99c79"))
	root.add_child(built_expression)
	var body:=HBoxContainer.new()
	body.size_flags_vertical=Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation",12)
	root.add_child(body)
	var values_column:=VBoxContainer.new()
	values_column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	body.add_child(values_column)
	var values_title:=Label.new()
	values_title.text="LIVED VALUES  •  OFFICIAL CLAIMS  •  INSTITUTIONAL REALITY"
	values_title.add_theme_font_size_override("font_size",11)
	values_title.add_theme_color_override("font_color",Color("#d8c89e"))
	values_column.add_child(values_title)
	var values_scroll:=FIT_CONTENT_PANEL.new()
	values_scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	values_column.add_child(values_scroll)
	var values_grid:=GridContainer.new()
	values_grid.columns=2
	values_grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	values_grid.add_theme_constant_override("h_separation",8)
	values_grid.add_theme_constant_override("v_separation",8)
	values_scroll.add_child(values_grid)
	for axis in SocietalValuesModel.VALUE_ORDER: _make_societal_value_card(values_grid,axis)
	var institutions_column:=VBoxContainer.new()
	institutions_column.custom_minimum_size=Vector2(395,0)
	body.add_child(institutions_column)
	var institutions_title:=Label.new()
	institutions_title.text="ORGANIZATIONAL FORMS"
	institutions_title.add_theme_font_size_override("font_size",11)
	institutions_title.add_theme_color_override("font_color",Color("#d8c89e"))
	institutions_column.add_child(institutions_title)
	var institutions_note:=Label.new()
	institutions_note.text="Discoveries open possibilities. Existing values determine which form spreads; lived results then change those values."
	institutions_note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	institutions_note.add_theme_font_size_override("font_size",9)
	institutions_note.add_theme_color_override("font_color",Color("#8c9994"))
	institutions_column.add_child(institutions_note)
	var institution_scroll:=FIT_CONTENT_PANEL.new()
	institution_scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	institutions_column.add_child(institution_scroll)
	var institution_list:=VBoxContainer.new()
	institution_list.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	institution_list.add_theme_constant_override("separation",7)
	institution_scroll.add_child(institution_list)
	var institutions:=SocietalValuesModel.active_institutions(GameState.societal_values)
	if institutions.is_empty():
		var empty:=Label.new()
		empty.text="No formal organization has spread yet because the relevant social discoveries are not established or adopted. Set broad research priorities in Inquiry, then allow evidence and social use to develop over time."
		empty.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		empty.add_theme_color_override("font_color",Color("#7f8d88"))
		institution_list.add_child(empty)
	else:
		for institution in institutions: _make_societal_institution_card(institution_list,institution)
	var footer:=HBoxContainer.new()
	root.add_child(footer)
	var note:=Label.new()
	note.text="Values drift from real outcomes over generations. They are not direct bonuses and cannot be switched instantly."
	note.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	note.add_theme_font_size_override("font_size",10)
	note.add_theme_color_override("font_color",Color("#87918c"))
	footer.add_child(note)
	var back:=Button.new()
	back.text="BACK TO SOCIETY"
	back.custom_minimum_size=Vector2(180,36)
	back.pressed.connect(func(): society_panel.queue_free(); society_panel=null; call_deferred("_open_society_panel"))
	footer.add_child(back)
	var close:=Button.new()
	close.text="RETURN TO MAP"
	close.custom_minimum_size=Vector2(130,36)
	close.pressed.connect(func(): society_panel.queue_free(); society_panel=null)
	footer.add_child(close)


func _make_societal_value_card(parent:Container,axis:String)->void:
	var definition:=SocietalValuesModel.value_definition(axis)
	var lived:=clampf(float(GameState.societal_values.lived.get(axis,0.5)),0.0,1.0)
	var official:=clampf(float(GameState.societal_values.official.get(axis,0.5)),0.0,1.0)
	var institutional:=clampf(float(GameState.societal_values.institutional_orientation.get(axis,0.5)),0.0,1.0)
	var card:=PanelContainer.new()
	card.custom_minimum_size=Vector2(305,88)
	card.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel",_knowledge_style(Color("#111a1d"),Color("#536b68"),1,3,8))
	card.tooltip_text=String(definition.get("meaning",""))
	parent.add_child(card)
	var content:=VBoxContainer.new()
	content.add_theme_constant_override("separation",3)
	card.add_child(content)
	var title:=Label.new()
	title.text=String(definition.get("name",axis.to_upper()))
	title.add_theme_font_size_override("font_size",10)
	title.add_theme_color_override("font_color",Color("#e4dccb"))
	content.add_child(title)
	var poles:=Label.new()
	poles.text="%s   ↔   %s" % [String(definition.get("low","LOW")),String(definition.get("high","HIGH"))]
	poles.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	poles.add_theme_font_size_override("font_size",8)
	poles.add_theme_color_override("font_color",Color("#87938e"))
	content.add_child(poles)
	var bar:=ProgressBar.new()
	bar.max_value=1.0
	bar.value=lived
	bar.show_percentage=false
	bar.custom_minimum_size=Vector2(0,7)
	bar.add_theme_stylebox_override("background",_knowledge_style(Color("#202a2c"),Color.TRANSPARENT,0,3,0))
	bar.add_theme_stylebox_override("fill",_knowledge_style(Color("#75a9a1"),Color.TRANSPARENT,0,3,0))
	content.add_child(bar)
	var readings:=Label.new()
	readings.text="LIVED %d  •  OFFICIAL %d  •  INSTITUTIONS %d" % [roundi(lived*100.0),roundi(official*100.0),roundi(institutional*100.0)]
	readings.add_theme_font_size_override("font_size",8)
	readings.add_theme_color_override("font_color",Color("#a9b2ad"))
	content.add_child(readings)


func _make_societal_institution_card(parent:Container,institution:Dictionary)->void:
	var adoption:=clampf(float(institution.get("adoption",0.0)),0.0,1.0)
	var card:=PanelContainer.new()
	card.add_theme_stylebox_override("panel",_knowledge_style(Color("#111a1d"),Color("#75694f"),1,3,8))
	parent.add_child(card)
	var content:=VBoxContainer.new()
	content.add_theme_constant_override("separation",3)
	card.add_child(content)
	var heading:=Label.new()
	heading.text=String(institution.get("name","INSTITUTION"))
	heading.add_theme_font_size_override("font_size",9)
	heading.add_theme_color_override("font_color",Color("#b8a66f"))
	content.add_child(heading)
	var form:=Label.new()
	form.text=String(institution.get("form","Emerging practice")).to_upper()
	form.add_theme_font_size_override("font_size",11)
	form.add_theme_color_override("font_color",Color("#e4dccb"))
	content.add_child(form)
	var spread:=ProgressBar.new()
	spread.max_value=1.0
	spread.value=adoption
	spread.show_percentage=false
	spread.custom_minimum_size=Vector2(0,6)
	content.add_child(spread)
	var status:=Label.new()
	status.text="ADOPTION %d%%  •  ESTABLISHED YEAR %d" % [roundi(adoption*100.0),int(floor(float(institution.get("discovered_day",0))/365.0))+1]
	status.add_theme_font_size_override("font_size",8)
	status.add_theme_color_override("font_color",Color("#89958f"))
	content.add_child(status)


func _open_progression_panel(selected_domain:="demography")->void:
	if selected_domain not in ProgressionSystem.domains(): selected_domain="demography"
	active_progression_domain=selected_domain
	if progression_panel and is_instance_valid(progression_panel): progression_panel.queue_free()
	if society_panel and is_instance_valid(society_panel): society_panel.queue_free(); society_panel=null
	ProgressionSystem.process_day(int(floor(GameState.elapsed_days)))
	var snapshot:Dictionary=ProgressionSystem.tree_snapshot()
	progression_panel=Control.new()
	progression_panel.name="EmergentDevelopment"
	progression_panel.size=get_viewport().get_visible_rect().size
	progression_panel.mouse_filter=Control.MOUSE_FILTER_STOP
	interface_layer.add_child(progression_panel)
	var dimmer:=ColorRect.new()
	dimmer.size=progression_panel.size
	dimmer.color=Color(0.004,0.007,0.009,0.94)
	progression_panel.add_child(dimmer)
	var modal:=PanelContainer.new()
	modal.name="DevelopmentModal"
	modal.position=Vector2(18,14)
	modal.size=progression_panel.size-Vector2(36,28)
	modal.add_theme_stylebox_override("panel",_knowledge_style(Color("#091215"),Color("#8a7548"),1,4,14))
	progression_panel.add_child(modal)
	var root:=VBoxContainer.new()
	root.add_theme_constant_override("separation",7)
	modal.add_child(root)
	var header:=HBoxContainer.new()
	header.custom_minimum_size=Vector2(0,64)
	root.add_child(header)
	var heading:=VBoxContainer.new()
	heading.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	header.add_child(heading)
	var eyebrow:=Label.new()
	eyebrow.text="THOUSANDS OF LATENT POSSIBILITIES  •  NO UNIVERSAL ORDER  •  HISTORY CHOOSES THE PATH"
	eyebrow.add_theme_font_size_override("font_size",10)
	eyebrow.add_theme_color_override("font_color",Color("#c5ad6e"))
	heading.add_child(eyebrow)
	var title:=Label.new()
	title.text="CIVILIZATIONAL DEVELOPMENT"
	title.add_theme_font_size_override("font_size",24)
	title.add_theme_color_override("font_color",Color("#f0e5cf"))
	heading.add_child(title)
	var subtitle:=Label.new()
	subtitle.text="Attention, daily practice, leadership, materials, place, chance, and prior findings determine what becomes discoverable. Unencountered possibilities remain unnamed."
	subtitle.add_theme_font_size_override("font_size",10)
	subtitle.add_theme_color_override("font_color",Color("#929d98"))
	heading.add_child(subtitle)
	var scale_summary:=VBoxContainer.new()
	scale_summary.custom_minimum_size=Vector2(270,0)
	header.add_child(scale_summary)
	var scale_label:=Label.new()
	scale_label.text="%d ESTABLISHED  •  %d ACTIVE" % [int(snapshot.known_discoveries),int(snapshot.active_inquiries)]
	scale_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	scale_label.add_theme_font_size_override("font_size",15)
	scale_label.add_theme_color_override("font_color",Color("#e1c777"))
	scale_summary.add_child(scale_label)
	var population_scale:=Label.new()
	population_scale.text="POP %s  •  WORLD REACH %d%%" % [_compact_population(GameState.population_total),roundi(float(snapshot.world_reach)*100.0)]
	population_scale.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	population_scale.add_theme_font_size_override("font_size",10)
	population_scale.add_theme_color_override("font_color",Color("#9da8a3"))
	scale_summary.add_child(population_scale)
	root.add_child(HSeparator.new())
	var body:=HBoxContainer.new()
	body.size_flags_vertical=Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation",10)
	root.add_child(body)
	var domain_scroll:=FIT_CONTENT_PANEL.new()
	domain_scroll.custom_minimum_size=Vector2(246,0)
	body.add_child(domain_scroll)
	var domain_list:=VBoxContainer.new()
	domain_list.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	domain_list.add_theme_constant_override("separation",5)
	domain_scroll.add_child(domain_list)
	for domain in ProgressionSystem.domains():
		var summary:=ProgressionSystem.domain_summary(domain)
		var domain_button:=Button.new()
		domain_button.name="Development_%s" % domain
		domain_button.text="%s\n%s  •  %d ESTABLISHED" % [domain.to_upper(),String(summary.era),int(summary.known_count)]
		domain_button.alignment=HORIZONTAL_ALIGNMENT_LEFT
		domain_button.custom_minimum_size=Vector2(230,43)
		domain_button.toggle_mode=true
		domain_button.button_pressed=domain==selected_domain
		domain_button.add_theme_font_size_override("font_size",10)
		domain_button.tooltip_text="%s\nCurrent coordinated scale: %s\nOnly established findings are counted." % [String(summary.purpose),String(summary.name)]
		domain_button.pressed.connect(_open_progression_panel.bind(domain))
		domain_list.add_child(domain_button)
	var detail:=VBoxContainer.new()
	detail.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	detail.add_theme_constant_override("separation",6)
	body.add_child(detail)
	var selected_summary:=ProgressionSystem.domain_summary(selected_domain)
	var frontier:Dictionary=selected_summary.frontier
	var domain_header:=HBoxContainer.new()
	detail.add_child(domain_header)
	var domain_heading:=VBoxContainer.new()
	domain_heading.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	domain_header.add_child(domain_heading)
	var domain_title:=Label.new()
	domain_title.text=selected_domain.to_upper()
	domain_title.add_theme_font_size_override("font_size",18)
	domain_title.add_theme_color_override("font_color",_dynamic_accent(selected_domain).lightened(0.24))
	domain_heading.add_child(domain_title)
	var domain_purpose:=Label.new()
	domain_purpose.text="%s\nCurrent coordinated scale: %s • %s" % [String(selected_summary.purpose),String(selected_summary.name),String(selected_summary.era)]
	domain_purpose.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	domain_purpose.add_theme_font_size_override("font_size",10)
	domain_purpose.add_theme_color_override("font_color",Color("#96a19c"))
	domain_heading.add_child(domain_purpose)
	var tier_label:=Label.new()
	tier_label.text="CAPACITY %d%%\n%s FRONTIER" % [roundi(float(GameState.society_capacities.get(selected_domain,0.0))*100.0),String(frontier.opportunity_signal)]
	tier_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	tier_label.add_theme_font_size_override("font_size",11)
	tier_label.add_theme_color_override("font_color",Color("#d8bd72"))
	domain_header.add_child(tier_label)
	var development_scroll:=FIT_CONTENT_PANEL.new()
	development_scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	detail.add_child(development_scroll)
	var development:=VBoxContainer.new()
	development.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	development.add_theme_constant_override("separation",8)
	development_scroll.add_child(development)
	var trajectory:=PanelContainer.new()
	trajectory.add_theme_stylebox_override("panel",_knowledge_style(Color("#111b1e"),_dynamic_accent(selected_domain).darkened(0.35),1,3,9))
	development.add_child(trajectory)
	var trajectory_content:=VBoxContainer.new()
	trajectory_content.add_theme_constant_override("separation",4)
	trajectory.add_child(trajectory_content)
	var trajectory_title:=Label.new()
	trajectory_title.text="CURRENT TRAJECTORY  •  %d FINDINGS  •  DEEPEST PROVEN METHOD %d / 12" % [int(selected_summary.known_count),int(selected_summary.maturity)]
	trajectory_title.tooltip_text="This is the deepest evidence method established in this domain—from first field mapping through replicated practice, standards, prediction, formal disciplines, and integrated science. It is not a count of predetermined technologies."
	trajectory_title.add_theme_font_size_override("font_size",11)
	trajectory_title.add_theme_color_override("font_color",_dynamic_accent(selected_domain).lightened(0.24))
	trajectory_content.add_child(trajectory_title)
	var emphasis_parts:Array[String]=[]
	for emphasis_variant in (frontier.get("emphasis",[]) as Array):
		var emphasis:Dictionary=emphasis_variant
		emphasis_parts.append("%s (%d)" % [String(emphasis.name),int(emphasis.observers)])
	var tradition_parts:Array[String]=[]
	for tradition in (frontier.get("traditions",[]) as Array): tradition_parts.append(String(tradition))
	var trajectory_text:=Label.new()
	trajectory_text.text="RESEARCH PRIORITY  %s\nESTABLISHED TRADITIONS  %s\n\nChanging these weights redistributes the civilization's aggregate researchers and strongly shapes which lines surface. Work performed, materials, leadership, geography, and chance determine the exact result inside that emphasis." % [", ".join(emphasis_parts) if not emphasis_parts.is_empty() else "UNSTAFFED — no directed inquiry in this domain",", ".join(tradition_parts) if not tradition_parts.is_empty() else "None yet"]
	trajectory_text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	trajectory_text.add_theme_font_size_override("font_size",10)
	trajectory_text.add_theme_color_override("font_color",Color("#a9b2ad"))
	trajectory_content.add_child(trajectory_text)
	var active_title:=Label.new()
	active_title.text="LIVE LINES OF INQUIRY"
	active_title.add_theme_font_size_override("font_size",12)
	active_title.add_theme_color_override("font_color",Color("#d8c89e"))
	development.add_child(active_title)
	var active:Array=frontier.get("active",[])
	if active.is_empty():
		var no_active:=Label.new()
		no_active.text="No research capacity is currently directed into this domain. Give one of its subfields a priority weight to make latent possibilities begin to surface."
		no_active.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		no_active.add_theme_color_override("font_color",Color("#7f8d88"))
		development.add_child(no_active)
	else:
		for investigation_variant in active:
			var investigation:Dictionary=investigation_variant
			var card:=PanelContainer.new()
			card.add_theme_stylebox_override("panel",_knowledge_style(Color("#10191c"),Color("#526b70"),1,3,8))
			development.add_child(card)
			var card_content:=VBoxContainer.new()
			card_content.add_theme_constant_override("separation",3)
			card.add_child(card_content)
			var inquiry_heading:=Label.new()
			inquiry_heading.text="%s  •  %s  •  PRIORITY %d  •  ~%s RESEARCHERS" % [String(investigation.subcategory).to_upper(),String(investigation.get("lens","PRACTICAL INQUIRY")).to_upper(),int(investigation.observer_allocation),_knowledge_workforce_text(float(investigation.get("research_workforce",0.0)))]
			inquiry_heading.add_theme_font_size_override("font_size",9)
			inquiry_heading.add_theme_color_override("font_color",Color("#89b3bb"))
			card_content.add_child(inquiry_heading)
			var inquiry_name:=Label.new()
			inquiry_name.text=String(investigation.name).to_upper()
			inquiry_name.add_theme_font_size_override("font_size",11)
			inquiry_name.add_theme_color_override("font_color",Color("#e4dccb"))
			card_content.add_child(inquiry_name)
			var inquiry_goal:=Label.new()
			inquiry_goal.text=String(investigation.project_goal)
			inquiry_goal.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
			inquiry_goal.add_theme_font_size_override("font_size",9)
			inquiry_goal.add_theme_color_override("font_color",Color("#9da8a3"))
			card_content.add_child(inquiry_goal)
			var inquiry_progress:=ProgressBar.new()
			inquiry_progress.max_value=1.0
			inquiry_progress.value=float(investigation.progress)
			inquiry_progress.show_percentage=false
			inquiry_progress.custom_minimum_size=Vector2(0,7)
			card_content.add_child(inquiry_progress)
			var bottleneck:=Label.new()
			bottleneck.text=String(investigation.bottleneck)
			bottleneck.add_theme_font_size_override("font_size",8)
			bottleneck.add_theme_color_override("font_color",Color("#c5a66d"))
			card_content.add_child(bottleneck)
	var recent_title:=Label.new()
	recent_title.text="RECENTLY ESTABLISHED"
	recent_title.add_theme_font_size_override("font_size",12)
	recent_title.add_theme_color_override("font_color",Color("#d8c89e"))
	development.add_child(recent_title)
	var recent:Array=frontier.get("recent",[])
	if recent.is_empty():
		var no_recent:=Label.new()
		no_recent.text="Nothing in this domain has yet survived investigation strongly enough to become established knowledge."
		no_recent.add_theme_color_override("font_color",Color("#7f8d88"))
		development.add_child(no_recent)
	else:
		for event_variant in recent:
			var event:Dictionary=event_variant
			var discovery:=Label.new()
			var causal_summary:=_discovery_cause_summary(event).replace("\n","\n  ")
			discovery.text="• %s\n  %s\n  CAPACITY EFFECT  •  %s" % [String(event.get("name","Established finding")).to_upper(),causal_summary,String(event.get("effect_summary",""))]
			discovery.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
			discovery.add_theme_font_size_override("font_size",9)
			discovery.add_theme_color_override("font_color",Color("#aab4ae"))
			development.add_child(discovery)
	var footer:=HBoxContainer.new()
	root.add_child(footer)
	var note:=Label.new()
	note.text="Broad scale is descriptive, not a shopping list. It rises only when discoveries, adoption, population, material capacity, connected settlements, and supporting systems converge."
	note.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	note.add_theme_font_size_override("font_size",9)
	note.add_theme_color_override("font_color",Color("#87918c"))
	footer.add_child(note)
	var inquiry_button:=Button.new()
	inquiry_button.text="DIRECT EMPHASIS"
	inquiry_button.custom_minimum_size=Vector2(150,36)
	inquiry_button.pressed.connect(func(): progression_panel.queue_free(); progression_panel=null; call_deferred("_open_knowledge_panel"))
	footer.add_child(inquiry_button)
	var capacity_button:=Button.new()
	capacity_button.text="CAPACITY SCORES"
	capacity_button.custom_minimum_size=Vector2(150,36)
	capacity_button.pressed.connect(func(): progression_panel.queue_free(); progression_panel=null; _open_society_panel())
	footer.add_child(capacity_button)
	var close:=Button.new()
	close.text="BACK TO CIVILIZATION"
	close.custom_minimum_size=Vector2(170,36)
	close.pressed.connect(_back_to_civilization_from_progression)
	footer.add_child(close)


func _make_progression_node_card(parent:Container,status:Dictionary,current_tier:int)->void:
	var tier:=int(status.tier)
	var unlocked:=bool(status.unlocked)
	var is_current:=unlocked and tier==current_tier
	var is_next:=not unlocked and tier==current_tier+1
	var accent:=_dynamic_accent(String(status.domain))
	var border:=accent if is_current else (accent.darkened(0.18) if unlocked else (Color("#927c4d") if is_next else Color("#354247")))
	var background:=Color("#162327") if is_current else (Color("#101a1d") if unlocked else Color("#0b1316"))
	var card:=PanelContainer.new()
	card.name=String(status.id)
	card.custom_minimum_size=Vector2(272,142)
	card.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel",_knowledge_style(background,border,2 if is_current or is_next else 1,3,8))
	parent.add_child(card)
	var content:=VBoxContainer.new()
	content.add_theme_constant_override("separation",3)
	card.add_child(content)
	var eyebrow:=Label.new()
	eyebrow.text="%02d  •  %s  •  %s" % [tier+1,String(status.era),"CURRENT" if is_current else ("ESTABLISHED" if unlocked else ("NEXT" if is_next else "LOCKED"))]
	eyebrow.add_theme_font_size_override("font_size",8)
	eyebrow.add_theme_color_override("font_color",border.lightened(0.22))
	content.add_child(eyebrow)
	var title:=Label.new()
	title.text=String(status.name).to_upper()
	title.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	title.add_theme_font_size_override("font_size",11)
	title.add_theme_color_override("font_color",Color("#ece1cc") if unlocked else Color("#aeb5b0"))
	content.add_child(title)
	var outcome:=Label.new()
	outcome.text=String(status.outcome)
	outcome.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	outcome.custom_minimum_size=Vector2(0,43)
	outcome.add_theme_font_size_override("font_size",8)
	outcome.add_theme_color_override("font_color",Color("#9ca7a1"))
	content.add_child(outcome)
	var progress:=ProgressBar.new()
	progress.max_value=1.0
	progress.value=float(status.progress)
	progress.show_percentage=false
	progress.custom_minimum_size=Vector2(0,6)
	progress.add_theme_stylebox_override("background",_knowledge_style(Color("#20292c"),Color.TRANSPARENT,0,2,0))
	progress.add_theme_stylebox_override("fill",_knowledge_style(accent if unlocked else border,Color.TRANSPARENT,0,2,0))
	content.add_child(progress)
	var blockers:Array=status.get("blockers",[])
	var state:=Label.new()
	if unlocked:
		state.text="ACTIVE CIVILIZATION CAPABILITY" if is_current else "FOUNDATION RETAINED"
	elif blockers.is_empty():
		state.text="READY TO ESTABLISH"
	else:
		state.text=String(blockers[0])
	state.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	state.add_theme_font_size_override("font_size",8)
	state.add_theme_color_override("font_color",Color("#8fb28d") if unlocked else (Color("#d0ad65") if is_next else Color("#7f8b87")))
	content.add_child(state)
	var requirement_text:="No remaining blockers." if blockers.is_empty() else "BLOCKERS\n• "+"\n• ".join(PackedStringArray(blockers))
	card.tooltip_text="%s\n\n%s\n\n%s" % [String(status.name),String(status.outcome),requirement_text]


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
	var progression:=ProgressionSystem.domain_summary(dynamic_id)
	var progression_label:=Label.new()
	progression_label.text="%s  •  %s" % [String(progression.era),String(progression.name).to_upper()]
	progression_label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	progression_label.add_theme_font_size_override("font_size",8)
	progression_label.add_theme_color_override("font_color",accent.lightened(0.16))
	progression_label.tooltip_text="Current progression capability. Open PROGRESSION for the complete nine-tier tree and its blockers."
	content.add_child(progression_label)
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
		"knowledge":"The ability to observe, retain, connect, and spread understanding.\nDriven by the aggregate research workforce, its allocation across fields, preserved learning, and communication. It governs discovery and adoption.",
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
			"Observers":"The aggregate population assigned to research. A larger, better-supported research workforce sustains more parallel inquiry and advances each funded line faster without simulating individuals.",
			"Directed attention":"How the research workforce is divided among active inquiry directions. Priority weights determine a line's share; broad programs gain variety while concentrated programs gain speed and depth.",
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
			"Inquiry breadth":"How many broad questions receive research capacity. Breadth creates diverse possibilities, but spreading a finite research workforce too widely reduces each line's share.",
			"Collective memory":"The society’s ability to retain stories, techniques, decisions, and identity across generations. Teaching and preservation raise it."
		}
	}
	var display_name:="Resource sustainability" if dynamic_id=="ecology" and subcategory=="Resource pressure" else subcategory
	var dynamic_definitions:Dictionary=definitions.get(dynamic_id,{})
	return String(dynamic_definitions.get(display_name,"A contributing measure inside %s. Higher values represent greater social capacity or safety." % dynamic_id.capitalize()))


func _open_founding_focus_panel()->void:
	if GameState.founding_focus!="" or (founding_focus_panel and is_instance_valid(founding_focus_panel)): return
	game_speed=0.0
	if map_help_panel: map_help_panel.visible=false
	if map_help_button: map_help_button.visible=false
	founding_focus_selection=""
	founding_focus_buttons.clear()
	founding_focus_panel=Control.new()
	founding_focus_panel.name="FoundingFocusSetup"
	founding_focus_panel.size=get_viewport().get_visible_rect().size
	founding_focus_panel.mouse_filter=Control.MOUSE_FILTER_STOP
	interface_layer.add_child(founding_focus_panel)
	var dimmer:=ColorRect.new()
	dimmer.size=founding_focus_panel.size
	dimmer.color=Color(0.003,0.006,0.008,0.95)
	founding_focus_panel.add_child(dimmer)
	var modal:=PanelContainer.new()
	modal.name="FoundingFocusModal"
	modal.size=Vector2(minf(1160.0,founding_focus_panel.size.x-64.0),minf(660.0,founding_focus_panel.size.y-40.0))
	modal.position=(founding_focus_panel.size-modal.size)*0.5
	modal.add_theme_stylebox_override("panel",_knowledge_style(Color("#091113"),Color("#9b8555"),1,5,20))
	founding_focus_panel.add_child(modal)
	var root:=VBoxContainer.new()
	root.add_theme_constant_override("separation",7)
	modal.add_child(root)
	var eyebrow:=Label.new()
	eyebrow.text="NEW CIVILIZATION  •  ONE PERMANENT FOUNDING CHOICE"
	eyebrow.add_theme_font_size_override("font_size",11)
	eyebrow.add_theme_color_override("font_color",Color("#c7ae70"))
	root.add_child(eyebrow)
	var title:=Label.new()
	title.text="CHOOSE A FOUNDING FOCUS"
	title.add_theme_font_size_override("font_size",26)
	title.add_theme_color_override("font_color",Color("#f2e5cb"))
	root.add_child(title)
	var introduction:=Label.new()
	introduction.text="This is not a scripted objective. It establishes your civilization's initial labor pattern and durable comparative advantages. Every rival civilization chooses automatically under the same rules; its focus remains unknown until you gather enough intelligence."
	introduction.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	introduction.add_theme_font_size_override("font_size",12)
	introduction.add_theme_color_override("font_color",Color("#aeb6b0"))
	root.add_child(introduction)
	root.add_child(HSeparator.new())
	var grid:=GridContainer.new()
	grid.name="FoundingFocusChoices"
	grid.columns=3
	grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation",8)
	grid.add_theme_constant_override("v_separation",8)
	root.add_child(grid)
	for definition_variant in GameState.founding_focus_catalog():
		var definition:Dictionary=definition_variant
		var focus_id:=String(definition.id)
		var card:=Button.new()
		card.name="Focus_%s" % focus_id
		card.custom_minimum_size=Vector2(360,104)
		card.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		card.alignment=HORIZONTAL_ALIGNMENT_LEFT
		card.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		card.text="%s\n%s\nCOST  •  %s" % [String(definition.name),String(definition.strengths),String(definition.tradeoff)]
		card.tooltip_text="%s\n\n%s" % [String(definition.creed),String(definition.description)]
		card.add_theme_font_size_override("font_size",11)
		card.pressed.connect(_select_founding_focus_card.bind(focus_id))
		grid.add_child(card)
		founding_focus_buttons[focus_id]=card
	var detail_panel:=PanelContainer.new()
	detail_panel.custom_minimum_size=Vector2(0,106)
	detail_panel.add_theme_stylebox_override("panel",_knowledge_style(Color("#0c1518"),Color("#44575a"),1,3,12))
	root.add_child(detail_panel)
	founding_focus_detail=Label.new()
	founding_focus_detail.name="FoundingFocusDetail"
	founding_focus_detail.text="Select a focus to see exactly what it changes. You may inspect every option before committing."
	founding_focus_detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	founding_focus_detail.add_theme_font_size_override("font_size",12)
	founding_focus_detail.add_theme_color_override("font_color",Color("#c7cfca"))
	detail_panel.add_child(founding_focus_detail)
	founding_focus_confirm=Button.new()
	founding_focus_confirm.name="ConfirmFoundingFocus"
	founding_focus_confirm.text="SELECT A FOCUS ABOVE"
	founding_focus_confirm.disabled=true
	founding_focus_confirm.custom_minimum_size=Vector2(0,44)
	founding_focus_confirm.add_theme_font_size_override("font_size",14)
	founding_focus_confirm.pressed.connect(_confirm_founding_focus)
	root.add_child(founding_focus_confirm)
	_refresh_founding_focus_cards()


func _select_founding_focus_card(focus_id:String)->void:
	if focus_id not in GameState.FOUNDING_FOCUS_ORDER: return
	founding_focus_selection=focus_id
	var definition:=GameState.founding_focus_definition(focus_id)
	founding_focus_detail.text="%s  •  %s\n%s\n\nSTRENGTHS  %s    TRADEOFF  %s" % [String(definition.name),String(definition.creed),String(definition.description),String(definition.strengths),String(definition.tradeoff)]
	founding_focus_confirm.text="ESTABLISH  •  %s" % String(definition.name)
	founding_focus_confirm.disabled=false
	_refresh_founding_focus_cards()


func _refresh_founding_focus_cards()->void:
	for focus_id in founding_focus_buttons:
		var button:Button=founding_focus_buttons[focus_id]
		var definition:=GameState.founding_focus_definition(String(focus_id))
		var accent:=Color(String(definition.get("color","#8c8064")))
		var selected:=String(focus_id)==founding_focus_selection
		button.add_theme_color_override("font_color",accent.lightened(0.18) if selected else Color("#d4d1c6"))
		button.add_theme_stylebox_override("normal",_knowledge_style(Color("#172226") if selected else Color("#0d1619"),accent if selected else Color("#354448"),2 if selected else 1,3,10))
		button.add_theme_stylebox_override("hover",_knowledge_style(Color("#172226"),accent,1,3,10))
		button.add_theme_stylebox_override("pressed",_knowledge_style(Color("#1c292c"),accent.lightened(0.15),2,3,10))


func _confirm_founding_focus()->void:
	if founding_focus_selection=="": return
	var result:=GameState.select_founding_focus(founding_focus_selection)
	if result.has("error"):
		founding_focus_detail.text=String(result.error)
		founding_focus_detail.add_theme_color_override("font_color",Color("#da8874"))
		return
	if convoy_banner_sprite: convoy_banner_sprite.texture=_founding_banner_texture(GameState.founding_banner_index)
	if founding_focus_panel and is_instance_valid(founding_focus_panel): founding_focus_panel.queue_free()
	founding_focus_panel=null
	founding_focus_detail=null
	founding_focus_confirm=null
	founding_focus_buttons.clear()
	_update_time_interface()
	_sync_map_help_overlay_visibility()


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
	controls.text="Left-click terrain  •  Inspect land / choose a convoy destination\nMiddle-drag or arrows  •  Move the map    Shift+middle  •  Rotate\nMouse wheel  •  Zoom    0–5  •  Pause and hourly time speeds    Esc  •  Menu"
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
	ProgressionSystem.reset_for_new_world()
	ResourceSystem.reset_for_new_world()
	EconomySystem.reset_for_new_world()
	_settlement_model().reset_for_new_world()
	AdvisorSystem.reset_for_new_world()
	_food_system().reset_for_new_world()
	ConsequenceEngine.reset_for_new_world()
	MilitaryCampaign.reset_for_new_world()
	CivilizationSystem.reset_for_new_world()
	WorldFacts.reset_for_new_world()
	PronouncementInterpreter.reset_for_new_world()
	pending_pronouncement_inputs.clear()
	get_tree().reload_current_scene()

func _restart_random_world()->void:
	var next_seed:int=abs(hash("%d:%d:%d" % [Time.get_unix_time_from_system(),Time.get_ticks_usec(),GameState.world_seed]))%2147483646+1
	if next_seed==GameState.world_seed: next_seed=(GameState.world_seed+104729)%2147483646+1
	_restart_world(next_seed)


# Escape always dismisses exactly the topmost game screen. This prevents a
# second dashboard or the pause menu from appearing behind an existing modal.
func _close_topmost_game_screen()->bool:
	for overlay_entry in [
		[knowledge_panel,"InvestigationDetailOverlay"],
		[provisions_panel,"ProvisionsDetailOverlay"],
		[materials_panel,"MaterialsDetailOverlay"]
	]:
		var owner:=overlay_entry[0] as Control
		if owner and is_instance_valid(owner):
			var overlay:=owner.find_child(String(overlay_entry[1]),true,false)
			if overlay:
				overlay.queue_free()
				return true
	if civilization_report_panel and is_instance_valid(civilization_report_panel):
		_close_civilization_report()
		return true
	if settlement_dashboard_panel and is_instance_valid(settlement_dashboard_panel):
		_close_settlement_dashboard()
		return true
	if provisions_panel and is_instance_valid(provisions_panel):
		provisions_panel.queue_free(); provisions_panel=null
		return true
	if materials_panel and is_instance_valid(materials_panel):
		materials_panel.queue_free(); materials_panel=null
		return true
	if population_ledger_panel and is_instance_valid(population_ledger_panel):
		population_ledger_panel.queue_free(); population_ledger_panel=null
		return true
	if knowledge_panel and is_instance_valid(knowledge_panel):
		_back_to_civilization_from_research()
		return true
	if council_panel and is_instance_valid(council_panel):
		_back_to_civilization_from_council()
		return true
	if government_panel and is_instance_valid(government_panel):
		_back_to_civilization_from_government()
		return true
	if society_panel and is_instance_valid(society_panel):
		_back_to_civilization_from_society()
		return true
	if progression_panel and is_instance_valid(progression_panel):
		_back_to_civilization_from_progression()
		return true
	if systems_hub_panel and is_instance_valid(systems_hub_panel):
		_close_systems_hub()
		return true
	if civilizations_panel and is_instance_valid(civilizations_panel):
		_close_civilizations_panel()
		return true
	if MilitaryCommandUI and MilitaryCommandUI.modal and MilitaryCommandUI.modal.visible:
		MilitaryCommandUI.modal.hide()
		return true
	return false


func _input(event: InputEvent) -> void:
	if founding_focus_panel and is_instance_valid(founding_focus_panel):
		# The full-screen modal stops world mouse input itself. Consume keyboard
		# shortcuts here, but leave mouse events available to its choice buttons.
		if event is InputEventKey: get_viewport().set_input_as_handled()
		return
	if scout_dispatch_panel and is_instance_valid(scout_dispatch_panel):
		if event is InputEventKey:
			if event.pressed and event.keycode==KEY_ESCAPE: _close_scout_dispatch_panel()
			get_viewport().set_input_as_handled()
		return
	if settlement_convoy_confirm_panel and is_instance_valid(settlement_convoy_confirm_panel):
		# Keep map navigation and speed shortcuts inert behind the quote while
		# leaving mouse events available to the modal's own buttons.
		if event is InputEventKey:
			if event.pressed and event.keycode==KEY_ESCAPE: _dismiss_settlement_convoy_confirmation()
			get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			if settlement_convoy_targeting:
				_cancel_settlement_convoy_targeting()
				get_viewport().set_input_as_handled()
				return
			if hud and hud.handle_escape():
				get_viewport().set_input_as_handled()
				return
			if _close_topmost_game_screen():
				get_viewport().set_input_as_handled()
				return
			if systems_hub_panel and is_instance_valid(systems_hub_panel):
				_close_systems_hub()
				get_viewport().set_input_as_handled()
				return
			if progression_panel and is_instance_valid(progression_panel):
				progression_panel.queue_free()
				progression_panel=null
				get_viewport().set_input_as_handled()
				return
			if civilizations_panel and is_instance_valid(civilizations_panel):
				_close_civilizations_panel()
				get_viewport().set_input_as_handled()
				return
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
			_zoom_camera_at_screen(event.position,camera.size/1.18)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_zoom_camera_at_screen(event.position,camera.size*1.18)
	elif event is InputEventMouseMotion and dragging:
		if rotating_camera:
			camera_yaw -= event.relative.x * 0.006
			camera_pitch = clampf(camera_pitch - event.relative.y * 0.004, -1.18, -0.48)
			_update_camera()
		else:
			var units_per_pixel:=camera.size/maxf(1.0,float(get_viewport().get_visible_rect().size.y))
			var screen_right:=_camera_ground_screen_right()
			var screen_up:=_camera_ground_screen_up()
			var movement:=_camera_grab_movement(event.relative,screen_right,screen_up,units_per_pixel)
			_set_camera_target(camera_target+movement)

func _unhandled_input(event: InputEvent) -> void:
	if actions_menu_panel and actions_menu_panel.visible and event is InputEventMouseButton and event.pressed:
		_close_actions_menu()
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
	if settlement_convoy_targeting:
		if event is InputEventMouseMotion:
			_update_settlement_convoy_preview(event.position)
		elif event is InputEventMouseButton and event.pressed:
			if event.button_index==MOUSE_BUTTON_LEFT:
				_select_settlement_convoy_site(event.position)
				get_viewport().set_input_as_handled()
			elif event.button_index==MOUSE_BUTTON_RIGHT:
				_cancel_settlement_convoy_targeting()
				get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if not settlement_convoy_targeting and _focus_settlement_from_screen(event.position, event.double_click):
			get_viewport().set_input_as_handled()
			return
		_move_settlers_to_screen(event.position)

func _focus_settlement_from_screen(screen_position: Vector2, close_inspection: bool) -> bool:
	if camera==null or not ("Hearth Circle" in GameState.settlement_completed):
		return false
	var selected:Dictionary={}
	var selected_screen_distance:=INF
	for settlement in _settlement_model().settlement_network_snapshot().settlements:
		var center_2d:Vector2=settlement.get("position",Vector2.ZERO)
		var candidate_center:=Vector3(center_2d.x,_height_at(center_2d.x,center_2d.y),center_2d.y)
		if camera.is_position_behind(candidate_center): continue
		var distance:=screen_position.distance_to(camera.unproject_position(candidate_center))
		if bool(settlement.get("primary",false)) and settlement_map_label and settlement_map_label.visible:
			var label_screen:=camera.unproject_position(settlement_map_label.position)
			if absf(screen_position.x-label_screen.x)<=105.0 and absf(screen_position.y-label_screen.y)<=22.0:
				distance=0.0
				# Clicking the settlement's name card is a jump to its numbers,
				# not just a camera focus.
				if hud and not close_inspection: _on_hud_section_requested("settlement",0)
		if distance<selected_screen_distance:
			selected_screen_distance=distance
			selected=settlement
	if selected.is_empty() or selected_screen_distance>30.0: return false
	var selected_center_2d:Vector2=selected.get("position",Vector2.ZERO)
	var center:=Vector3(selected_center_2d.x,_height_at(selected_center_2d.x,selected_center_2d.y),selected_center_2d.y)
	_set_camera_target(center)
	if close_inspection:
		# A double-click advances one legible scale instead of teleporting from a
		# regional map directly into a parcel. Repeated input can still reach the
		# site view while every intermediate landscape remains understandable.
		camera.size=maxf(0.18,camera.size/4.0)
	_update_camera()
	_update_scale_lod()
	_inspect_location(center)
	if travel_status_label:
		travel_status_label.text="%s SELECTED  •  double-click to move one scale closer  •  wheel zoom remains anchored" % String(selected.get("name","SETTLEMENT")).to_upper()
	return true

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

func _zoom_camera_at_screen(screen_position:Vector2,requested_size:float)->void:
	if camera == null:
		return
	var before:=_terrain_hit(screen_position)
	camera.size=clampf(requested_size,0.035,18000.0 if SEAMLESS_WORLD else 128.0)
	_update_camera()
	if not before.is_empty():
		var after:=_terrain_hit(screen_position)
		if not after.is_empty():
			# Preserve the geographic point under the pointer exactly, as continuous
			# globe viewers do. This prevents the world from sliding during zoom.
			var correction:Vector3=before.position-after.position
			correction.y=0.0
			_set_camera_target(camera_target+correction)
	_update_scale_lod()
