extends Node3D

const OrganicTownVisual := preload("res://scripts/organic_town_visual.gd")
const EarlySettlementVisual := preload("res://scripts/early_settlement_visual.gd")
const EarlySettlementGround = preload("res://scripts/early_settlement_ground.gd")
## Early-town layouts by town centre: [saved-fabric bytes, plan]. Each town
## keeps its own, so redrawing one town never discards another's layout.
var organic_town_plans: Dictionary = {}


const ArmyFrontVisualScript := preload("res://scripts/army_front_visual.gd")
const MAX_CLOSE_ARMY_FORMATIONS:=6
var close_army_figures:Dictionary={}

const FIT_CONTENT_PANEL:=preload("res://scripts/viewport_fit_panel.gd")
const COAST_SHAPE:=preload("res://scripts/coast_shape.gd")
const FoodSystemScript := preload("res://scripts/food_system.gd")
const SettlementModelScript:=preload("res://scripts/settlement_model.gd")
const FoundingSiteAdvice:=preload("res://scripts/founding_site_advice.gd")
const FoundingSiteGuide:=preload("res://scripts/hud/founding_site_guide.gd")
const HudT:=preload("res://scripts/hud/hud_tokens.gd")
var founding_site_advisor:RefCounted
var founding_site_guide:Control
const SocietalValuesModel:=preload("res://scripts/societal_values_model.gd")
const LandscapeCover=preload("res://scripts/landscape_cover.gd")
const WorldDiscoveryMapScript:=preload("res://scripts/world_discovery_map.gd")
const WarfareMapPresentation:=preload("res://scripts/warfare_map_presentation.gd")
const EraWordsMap:=preload("res://scripts/hud/era_words.gd")
const SCORE_TRACKS:=[
	preload("res://assets/audio/Tomorrow.mp3"),
	preload("res://assets/audio/War.mp3"),
]
var score_track_index:=0

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
const SURFACE_STONE_RADIUS_KM:=Vector2(0.0015,0.0045)
const CONVOY_KM_PER_DAY := 16.0
const CaravanLeader:=preload("res://scripts/caravan_leader.gd")
const CaravanSystem:=preload("res://scripts/caravan_system.gd")
const CivilizationTravel:=preload("res://scripts/civilization_travel.gd")
const CaravanPanel:=preload("res://scripts/hud/caravan_panel.gd")
const GroundLens:=preload("res://scripts/hud/ground_lens.gd")
const MapTickerWords:=preload("res://scripts/hud/map_ticker_words.gd")
const MapNotes:=preload("res://scripts/hud/map_notes.gd")
const PaperKit:=preload("res://scripts/hud/paper_kit.gd")
const MAIN_RIVER_WATER_HALF_WIDTH_KM := 0.125
const TRIBUTARY_WATER_HALF_WIDTH_KM := 0.035
const MAIN_RIVER_SETTLEMENT_CLEARANCE_KM := 0.25
const TRIBUTARY_SETTLEMENT_CLEARANCE_KM := 0.10
const SPEED_HOURS_PER_REAL_SECOND := {1:0.5,2:2.0,3:8.0,4:24.0,5:72.0}
## A new people's story starts at one day per second: the first real hour is
## about the first ten years, with a real turning point every few minutes.
const DEFAULT_PLAY_SPEED := 4.0
# Per-frame microseconds for a world day in progress (see _day_step_budget_usec).
const DAY_STEP_BUDGET_USEC := 8000
const DAY_STEP_BUDGET_FAST_USEC := 14000
const DAY_STEP_BUDGET_NAVIGATING_USEC := 4000
const SETTLEMENT_DETAIL_SCALE := 0.002
const SETTLEMENT_FABRIC_MAX_ZOOM := 28.0
const SETTLEMENT_DISTRICT_DETAIL_MAX_ZOOM := 2.4
const SETTLEMENT_INSPECTION_ZOOM := 0.42
const SETTLEMENT_AGGREGATE_DENSITY_BUDGET := 192
const SETTLEMENT_DISTRICT_CLIPMAP_BUDGET := 128
const SETTLEMENT_DISTRICT_CONDITIONS := ["great","okay","fine","normal","bad","poor","damaged","destroyed"]
const SETTLEMENT_CONDITION_SAMPLE_KM := 0.80
const SETTLEMENT_DAMAGE_INFLUENCE_KM := 0.72
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
var mountain_relief := preload("res://scripts/terrain_mountain_relief.gd").new()
var moisture_noise := FastNoiseLite.new()
var camera: Camera3D
var camera_target := Vector3.ZERO
var camera_yaw := -0.72
var camera_pitch := -0.98
var camera_distance := 92.0
# Agreed four-distance design, recovered from “Set Up Godot Project”.
# Altitudes use a fixed 50-degree horizontal field of view, looking down.
const CAMERA_DISTANCE_LEVELS:=[{"name":"10,000 ft","width_km":2.842611486},{"name":"50,000 ft","width_km":14.21305743},{"name":"Region","width_km":150.0},{"name":"Continent","width_km":3000.0}]
var distance_input_msec:=-1000
var distance_gesture_steps:=0.0
var zoom_preset_active:=false
var zoom_target_size:float=-1.0
## codex/map-motion: camera glide and coasting state (scripts/map_motion.gd).
var zoom_log_velocity:=0.0
var pan_coast_velocity:=Vector3.ZERO
var drag_velocity:=Vector3.ZERO
var drag_motion_usec:=0
var key_pan_velocity:=Vector2.ZERO
var zoom_pointer:=Vector2.ZERO
var north_reset_active:=false
var camera_input_msec:int=0
var terrain_patch_job:RefCounted
var terrain_patch_cache:Array[Dictionary]=[]
var terrain_patch_sample_source:Dictionary={}
var terrain_patch_last_reused_vertices:=0
var terrain_patch_last_sampled_vertices:=0
var regional_patch_resolution:=0
var terrain_patch_cancellations:=0
var terrain_patch_last_slice_usec:int=0
var terrain_patch_last_commit_usec:int=0
var terrain_visual_sample_position:=Vector3(INF,INF,INF)
var terrain_visual_sample_climate:Dictionary={}
const TERRAIN_PATCH_BUILDER:=preload("res://scripts/terrain_patch_builder.gd")
const TERRAIN_MACRO_RENDER:=preload("res://scripts/terrain_macro_render.gd") # codex/terrain-bake
var macro_render:=TERRAIN_MACRO_RENDER.new() # codex/terrain-bake: visual-only planet rasters
const SURFACE_PRECISION:=preload("res://scripts/surface_precision.gd")
const TERRAIN_LOD:=preload("res://scripts/terrain_lod.gd")
const TERRAIN_PATCH_MOVING_BUDGET_USEC:=1400
const TERRAIN_PATCH_IDLE_BUDGET_USEC:=3000
var dragging := false
var rotating_camera := false
var grid_x := 80
var grid_z := 80
var world_width := 100.0
var world_depth := 100.0
var settler_marker: Area3D
var terrain_body: StaticBody3D
var province_terrain_mesh: MeshInstance3D
var regional_terrain_patch: MeshInstance3D
var regional_patch_center := Vector2.INF
var regional_patch_span := 420.0
var world_start_position := Vector3.ZERO
var resource_sites: Array[Dictionary] = []
var leader_candidates: Array[Dictionary] = []
var placement_building := ""
var placement_preview: MeshInstance3D
var placement_valid := false
var construction_projects: Array[Dictionary] = []
var hearth_established := false
var interface_layer: CanvasLayer
var hud: Control  # CommandRailHud shell: rail, time pill, KPI strip, queue, toolbar.
var last_discovery_day := 0
const KNOWLEDGE_RECORD_PAGE_SIZE:=5
var pending_pronouncement_inputs: Dictionary={}
var travel_status_label: Label
var route_mesh: MeshInstance3D
var river_course := PackedFloat32Array()
var world_tributary_courses: Array[Array] = []
var river_terrain_height_texture:ImageTexture
## The patch heights with box-filtered mip levels (map_chart.gdshaderinc).
var chart_relief_texture:ImageTexture
## The patch's land cover and land/water mask, likewise (map_chart).
var chart_cover_texture:ImageTexture
var river_terrain_grid:=Vector4.ZERO
var coastal_water_material:ShaderMaterial
var ocean_surface:MeshInstance3D
var coastal_water_surface:MeshInstance3D
var rendered_regional_heights:=PackedFloat32Array()
var detail_surface_center:=Vector2.ZERO
var woodland_harvest_surface_key:=""
const RENDERED_SURFACE:=preload("res://scripts/rendered_surface_height.gd")
var river_overlays: Array[MeshInstance3D] = []
var lens_panel: PanelContainer
var lens_body: RichTextLabel
var lens_survey: ScrollContainer
var lens_location_label: Label
var lens_ring: MeshInstance3D
var lens_world_position := Vector3.ZERO
var lens_requested_visible:=false
var map_selection_marker:MeshInstance3D
var map_selection_generation:=0
var settlement_visual_root: Node3D
var detail_terrain_patch: MeshInstance3D
var coast_mask_rasters:Array=[null,null]
var close_terrain_job:RefCounted
var close_terrain_last_slice_usec:=0
var close_terrain_last_finish_usec:=0
var close_vegetation_root: Node3D
var close_vegetation_revision := -1
var close_vegetation_surface_signature:=""
var close_vegetation_center:=Vector2(INF,INF)
var close_vegetation_seed:=0
var close_vegetation_fade:=-1.0
var convoy_map_icon: Node3D
var convoy_banner_sprite: Sprite3D
var convoy_map_label: Label3D
var convoy_detail_root: Node3D
var settler_map_ring: MeshInstance3D
var settler_click_shape: CollisionShape3D
var discovered_resource_overlays: Dictionary = {}
var resource_overlay_root:Node3D
var rendered_resource_overlay_zoom_key:=""
var resource_view_enabled:=true
const RESOURCE_OVERLAY_MAX_CLUSTERS:=256
const RESOURCE_OVERLAY_MAX_LABELS:=18
const ResourceIcons:=preload("res://scripts/resource_icons.gd")
var settlement_blip: MeshInstance3D
var settlement_map_label:Label3D
var settlement_border_root:Node3D
var settlement_network_marker_root:Node3D
var settlement_network_fabric_root:Node3D
var rendered_settlement_network_signature:=""
## Hash of what the network meshes draw; see _settlement_network_geometry_key.
var rendered_settlement_network_geometry_key:=0
## Border/claim mesh rebuilds since load (probes read it; never saved).
var settlement_border_rebuilds:=0
var undertaking_visual_root:Node3D
var undertaking_visual_signature:String=""
var sampled_settlement_territory_signature:=""
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
var settlement_convoy_name_input:LineEdit
var settlement_convoy_pending_destination:=Vector3.ZERO
var settlement_convoy_pending_route:Dictionary={}
var settlement_convoy_pending_quote:Dictionary={}
var settlement_convoy_confirmation_previous_speed:=0.0
var caravan_formation:Dictionary={}
var settlement_fabric_shader:Shader
var settlement_wall_shader:Shader
var vegetation_surface_shader:Shader
var settlement_land_use_root: Node3D
var footprint_population := -1
var rendered_morphology_revision := -1
var rendered_settlement_lod := -1
var rendered_architecture_signature := ""
var rendered_settlement_view_signature := ""
var rendered_morphology_visual_signature := ""
## Visual signatures per city (keyed by resource settlement id), so drawing
## several towns in one pass does not recompute each town's plot hash.
var cached_morphology_visual_signatures:Dictionary={}
var active_architecture_profile:Dictionary={}
var rendered_settlement_aerial_lod:=-1.0
var rendered_settlement_stage_radius:=0.0
var settlement_naming_panel: Control
var settlement_name_input: LineEdit
var settlement_name_confirm: Button
var naming_previous_speed := 0.0
var settlement_naming_target_id:=""
var suppress_naming_prompt := false
var map_help_button:Button
var map_help_panel:PanelContainer
var map_help_title:Label
var map_help_body:Label
# Map help remains available on demand, but never opens over a new campaign.
var map_help_dismissed:=true
var travel_council_notice: Button
var travel_council_notice_until_msec := 0
var foreign_alert_panel:PanelContainer
var foreign_alert_title:Label
var foreign_alert_body:Label
var foreign_alert_world_button:Button
var foreign_alert_queue:Array[Dictionary]=[]
var active_foreign_alert:Dictionary={}
var scout_dispatch_panel:Control
## Scout target and heading chosen from other screens (the rumor map sets them).
var pending_scout_target_id:="open_world"
var pending_scout_heading:=""
## Scout target and heading chosen from other screens (the rumor map sets them).
var scout_dispatch_status:Label
var scout_dispatch_previous_speed:=0.0
var travel_reported_milestones: Dictionary = {}
var travel_active := false
var travel_start := Vector3.ZERO
var travel_target := Vector3.ZERO
var travel_days_total := 0.0
var travel_days_elapsed := 0.0
var game_speed := 0.0
var simulation_clock:=preload("res://scripts/simulation_clock.gd").new()
# Calendar target and frame advance of the day running in bounded steps.
var scheduled_world_elapsed:=0.0
## Calendar time that arrived while a day was still computing, beyond its end.
var calendar_bank_days:=0.0
const CALENDAR_BANK_DAYS:=1.0
var scheduled_world_days:=0.0
# False restores whole days inside one frame (diagnostics and fallback).
var scheduled_world_days_enabled:=true
var world_menu_panel: Control
var world_seed_input: LineEdit
var world_seed_status: Label
var world_menu_previous_speed:=0.0
var founding_focus_panel:Control
var selected_civilization_region_id:=""
var civilization_feedback_text:=""
var capture_render_active:=false
var discovery_mask_texture:ImageTexture
var seasonal_materials:Array[WeakRef]=[]
var last_seasonal_day:=INF
var seasonal_motion:=-1.0
var seasonal_snow:=0.0
const LANDSCAPE_VISUALS:=preload("res://scripts/landscape_resource_visuals.gd")
const WORLD_BEAUTY:=preload("res://scripts/world_beauty.gd")
var woodland_visual_areas:=PackedVector4Array()
var woodland_visual_key:=""
var woodland_harvest_detail:MultiMeshInstance3D
var vegetation_fog_materials=preload("res://scripts/fog_material_registry.gd").new()
var woodland_visual_materials:Array[WeakRef]=[]
var terrain_fog_materials=preload("res://scripts/fog_material_registry.gd").new()
var rendered_fog_revision:=-1
var foreign_formation_markers:Dictionary={}
var contact_encounter_markers:Dictionary={}
var player_field_army_markers:Dictionary={}
## Map-selected field army (HoI4-style: click a marker to select, right-click
## charted land to order the march). -1 = nothing selected.
var selected_army_id:=-1
var player_field_army_paths:Dictionary={}
## Planned corridors for currently deployed scout parties. These show the
## player's order, not supernatural live tracking or discoveries in the fog.
var player_scout_route_markers:Dictionary={}
var warfare_front_markers:Dictionary={}
var war_map_overlay:Control
var rendered_observation_revision:=-1
const LIVE_REPORT_REFRESH_INTERVAL_SECONDS:=0.75
var live_report_refresh_elapsed:=0.0
# Visual-audit override only. Gameplay leaves this at -1 and derives one of the eight
# aggregate neighborhood conditions from authoritative civilization/settlement state.
var district_condition_visual_override:=-1

var display_preferences:Node
var quit_dialog:ConfirmationDialog
var map_snapshot_elapsed:=0.1
var scale_lod_elapsed:=0.1
var time_interface_day:=-2
## A dock section to open at the next frame's HUD pass.
var pending_hud_section:=""
var time_interface_between_days:=false
var time_interface_msec:=0
var scale_lod_view:=Vector4.INF
var map_snapshot_refreshes:=0
# Settlement network rebuilds run on the same 10 Hz cadence, half a period
# later, so its border meshes and the marker refreshes never share a frame.
var map_network_elapsed:=0.05
var rendered_resource_overlay_signature:=""
var civilization_geography_cache:Dictionary={}
var civilization_surface_cache:Dictionary={}
var military_attention_dialog:ConfirmationDialog
var military_attention_seen:Dictionary={}

func _ready() -> void:
	display_preferences=preload("res://scripts/display_preferences.gd").new()
	add_child(display_preferences)
	get_tree().auto_accept_quit=false
	get_window().close_requested.connect(_request_quit)
	var release_version:=String(ProjectSettings.get_setting("application/config/version","development"))
	get_window().title="Tomorrow and Tomorrow · "+release_version
	print("GAME_RELEASE: ",release_version)
	if "--resume-saved" in OS.get_cmdline_user_args() and not get_tree().root.has_meta("saved_campaign_resumed"):
		var restored:Dictionary=SaveSystem.load_game()
		if restored.has("error"):
			push_error("Saved campaign could not be reopened: "+String(restored.error))
			for detail in restored.get("details",[]):push_error("Save validation: "+String(detail))
			get_tree().quit(1)
			return
		get_tree().root.set_meta("saved_campaign_resumed",true)
		print("SAVED_CAMPAIGN_RESUMED: ",String(restored.message),"; settlement=",GameState.settlement_name,"; seed=",GameState.world_seed)
	if not MilitaryCampaign.threat_changed.is_connected(_on_military_threat_attention): MilitaryCampaign.threat_changed.connect(_on_military_threat_attention)
	if not MilitaryCampaign.battle_started.is_connected(_on_city_battle_started):MilitaryCampaign.battle_started.connect(_on_city_battle_started)
	if not MilitaryCampaign.aftermath_required.is_connected(_on_city_aftermath):MilitaryCampaign.aftermath_required.connect(_on_city_aftermath)
	if not MilitaryCampaign.battle_resolved.is_connected(_on_battle_attention): MilitaryCampaign.battle_resolved.connect(_on_battle_attention)
	_restore_military_attention.call_deferred()
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
	# Network requests do not survive a process/scene restart. Recover any saved
	# in-flight civic turn as an explicit interrupted conversation instead of
	# leaving the composer permanently locked on INTERPRETING.
	PronouncementInterpreter.reset_for_new_world()
	AdvisorSystem.recover_interrupted_civic_directives()
	if not CivilizationSystem.diplomatic_event.is_connected(_on_diplomatic_event):
		CivilizationSystem.diplomatic_event.connect(_on_diplomatic_event)
	_configure_shape()
	_configure_noise()
	_prepare_river_course()
	macro_render.bind(self,SEAMLESS_WORLD) # codex/terrain-bake
	CivilizationSystem.set_scout_geography_authority(Callable(self,"_scout_land_at"))
	CivilizationSystem.set_ground_survey_authority(Callable(self,"_survey_ground_at"))
	MilitaryCampaign.recovery.surface_assessor=Callable(self,"_settlement_surface_assessment")
	if not CivilizationSystem.scout_report_returned.is_connected(_on_scout_report_returned):
		CivilizationSystem.scout_report_returned.connect(_on_scout_report_returned)
	world_start_position = _opening_world_position()
	# province_terrain is retained for legacy reports, but in the seamless world it
	# now describes the actual founding ground instead of declaring every planet to
	# be Plains. Simulation systems consume the richer environment profile directly.
	var founding_biome:=_biome_at(world_start_position.x,world_start_position.z,world_start_position.y)
	GameState.province_terrain=String(founding_biome.get("label","unknown terrain")).capitalize()
	CivilizationSystem.register_player_origin(Vector2(world_start_position.x,world_start_position.z))
	WorldSimulation.water_provider=Callable(self,"_surface_water_site_near")
	WorldSimulation.context_provider=Callable(self,"_civilization_geography")
	WorldSimulation.surface_material_provider=Callable(self,"_civilization_surface_materials")
	WorldSimulation.start_provider=Callable(self,"_civilization_start")
	WorldSimulation.route_provider=Callable(self,"_analyze_convoy_route")
	CaravanLeader.geography_provider=Callable(self,"_caravan_geography_at")
	CaravanLeader.forage_provider=Callable(self,"_caravan_forage_at")
	WorldSimulation.start_world()
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
	preload("res://scripts/living_map.gd").open_on_people(self)
	_settlement_model().ensure_founded()
	_build_interface()
	_present_next_foreign_alert()
	if GameState.founding_focus=="": _open_founding_focus_panel.call_deferred()
	_refresh_settlement_network(true)
	_refresh_settlement_convoy_marker()
	_trace_load("settlement and interface")
	GeneralCampaign.bind_world.call_deferred(self)
	_capture_preview_if_requested.call_deferred()

func _exit_tree()->void:
	macro_render.cancel() # codex/terrain-bake: no raster band may outlive this node

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
	var capture_dock := ""
	var capture_naming_panel := false
	var capture_world_menu := false
	var capture_military_panel := false
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
		elif argument.begins_with("--capture-dock="):
			capture_dock = argument.trim_prefix("--capture-dock=")
		elif argument == "--capture-naming":
			capture_naming_panel = true
		elif argument == "--capture-world-menu":
			capture_world_menu = true
		elif argument == "--capture-military":
			capture_military_panel = true
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
	if "--capture-scout-chart" in OS.get_cmdline_user_args():
		_seed_capture_scout_chart()
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
			SettlementModel.with_local_population(func()->void:EconomySystem.process_day(daily_context))
			_evaluate_travel_survival()
			_process_settlement_day()
			_process_other_city_resources()
			_refresh_discovered_resource_overlays()
			_update_time_interface()
			if capture_travel and not travel_active:
				break
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
	if capture_naming_panel:
		_open_settlement_naming_panel()
		capture_audit_root=settlement_naming_panel
	if capture_world_menu:
		_open_world_menu()
		capture_audit_root=world_menu_panel
	if capture_military_panel:
		if not MilitaryCommandUI.modal.visible:
			MilitaryCommandUI._toggle()
		capture_audit_root=MilitaryCommandUI.modal
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
		capture_audit_root=_open_diplomat_dispatch_panel(String(capture_civ.id),"open_trade")
	if capture_zoom > 0.0:
		camera_target = settler_marker.position
		camera.size = capture_zoom
		if is_finite(capture_pitch_degrees): camera_pitch=clampf(deg_to_rad(capture_pitch_degrees),-1.50,-0.32)
		if is_finite(capture_yaw_degrees): camera_yaw=wrapf(deg_to_rad(capture_yaw_degrees),-PI,PI)
		_update_camera()
		_update_scale_lod()
	# Scene construction is synchronous, but camera/world registration and canvas
	# updates settle at frame boundaries. Capturing in the same deferred call can
	# save an empty map and stale HUD. Give the renderer real frames first.
	for capture_frame in 3:
		await get_tree().process_frame
	# Regional terrain is streamed in slices. Finish the initial patch, then the
	# requested camera's patch before taking an audit image of either surface.
	for capture_stream_pass in 2:
		while terrain_patch_job!=null:
			_advance_terrain_patch()
			await get_tree().process_frame
		_update_world_streaming()
	_update_scale_lod()
	await get_tree().process_frame
	if capture_dock!="":
		# The dock is populated in this same deferred call; give the container
		# layout and canvas one real frame before the capture draw.
		await get_tree().process_frame
		await get_tree().process_frame
	var capture_arguments:=OS.get_cmdline_user_args()
	if "--capture-wait-macro" in capture_arguments:
		# Terrain audits: let the per-seed macro rasters (and the shared coast
		# mask built from them) land before the image, bounded to three minutes.
		var macro_deadline:=Time.get_ticks_msec()+180000
		while not macro_render.ready() and Time.get_ticks_msec()<macro_deadline:
			await get_tree().process_frame
		_sync_coast_mask()
		print("CAPTURE MACRO READY: ",macro_render.ready())
	for argument in capture_arguments:
		if argument.begins_with("--capture-zoom-out="):
			# Reproduce a zoom-out mid-stream: the finished patch is now smaller than
			# the view while the wider patch is still being sampled.
			camera.size=float(argument.trim_prefix("--capture-zoom-out="))
			_update_camera()
			_update_world_streaming()
			for stream_frame in 4:
				_advance_terrain_patch()
				await get_tree().process_frame
			_update_scale_lod()
			print("CAPTURE MID-STREAM: patch_span=",regional_patch_span," pending=",terrain_patch_job!=null)
	if "--capture-hide-ui" in capture_arguments:
		# Terrain audits: hide every 2D layer (HUD, modals) so the map is visible.
		for layer in get_tree().root.find_children("*","CanvasLayer",true,false):(layer as CanvasLayer).visible=false
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
	var trace=preload("res://scripts/performance_trace.gd")
	var stamp:int=trace.start()
	_advance_physical_army_fronts(delta)
	_advance_close_terrain_job()
	_refresh_discovery_mask()
	_refresh_woodland_visuals()
	_refresh_seasonal_visuals()
	stamp=trace.mark("frame_masks_and_vegetation",stamp)
	_process_camera_navigation(delta)
	_process_smooth_camera(delta)
	var calendar_days:=simulation_clock.take_days(Time.get_ticks_usec(),_speed_hours_per_second()/24.0 if game_speed>0.0 and not GeneralCampaign.active else 0.0,_camera_in_motion())
	stamp=trace.mark("frame_camera",stamp)
	_update_world_streaming()
	stamp=trace.mark("frame_world_streaming",stamp)
	macro_render.tick(delta) # codex/terrain-bake: start/assemble off-thread rasters
	_sync_coast_mask()
	_advance_terrain_patch()
	stamp=trace.mark("frame_terrain_patch",stamp)
	# Scale visibility follows the camera every frame it moves; otherwise only
	# state changes matter, which ten checks a second keep up with.
	scale_lod_elapsed+=maxf(0.0,delta)
	var lod_origin:Vector3=(camera.global_position if camera.is_inside_tree() else camera.position) if camera else Vector3.ZERO
	var lod_view:=Vector4(camera.size if camera else 0.0,lod_origin.x,lod_origin.y,lod_origin.z)
	if lod_view!=scale_lod_view or scale_lod_elapsed>=0.1:
		scale_lod_elapsed=0.0;scale_lod_view=lod_view
		_update_scale_lod()
	stamp=trace.mark("frame_scale_lod",stamp)
	_update_convoy_marker_animation()
	# These rebuild report dictionaries, sort marker snapshots and inspect
	# settlement morphology. Ten updates/second keep them responsive without
	# tying that CPU work to Retina refresh rate; camera motion stays per-frame.
	map_snapshot_elapsed+=maxf(0.0,delta)
	if map_snapshot_elapsed>=0.1:
		map_snapshot_elapsed=fmod(map_snapshot_elapsed,0.1)
		map_snapshot_refreshes+=1
		_refresh_contact_encounter_markers()
		stamp=trace.mark("frame_map_contacts",stamp)
		_refresh_foreign_formation_markers()
		stamp=trace.mark("frame_map_formations",stamp)
		_refresh_player_field_army_markers()
		stamp=trace.mark("frame_map_field_armies",stamp)
		_refresh_player_scout_route_markers()
		stamp=trace.mark("frame_map_scout_routes",stamp)
	map_network_elapsed+=maxf(0.0,delta)
	if map_network_elapsed>=0.1:
		map_network_elapsed=fmod(map_network_elapsed,0.1)
		_refresh_settlement_network()
		_refresh_settlement_roads()
		if not pending_city_designs.is_empty():_advance_pending_city_designs()
		stamp=trace.mark("frame_map_settlement_network",stamp)
		_refresh_settlement_convoy_marker()
	stamp=trace.mark("frame_map_snapshots",stamp)
	if travel_council_notice and travel_council_notice.visible and Time.get_ticks_msec()>travel_council_notice_until_msec:
		travel_council_notice.visible=false
	if travel_status_label:
		# The status strip never sits under the road notice or a moment card.
		var card:Variant=hud.get_meta("chronicle_card") if hud and hud.has_meta("chronicle_card") else null
		travel_status_label.visible=not ((travel_council_notice!=null and travel_council_notice.visible) or (is_instance_valid(card) and bool(card.showing)))
		if travel_status_label.visible:preload("res://scripts/hud/map_ticker_style.gd").fit(travel_status_label,get_viewport().get_visible_rect().size.x)
	_arbitrate_notification_overlays()
	_process_live_report_refresh(delta)
	if not pending_hud_section.is_empty():
		var section:=pending_hud_section
		pending_hud_section=""
		if hud:_on_hud_section_requested(section,0)
		stamp=trace.mark("found_hud",stamp)
	stamp=trace.mark("frame_hud",stamp)
	# A started day always finishes, even if paused, before the century choice
	# or campaign logic reads its results. Its work is spread across frames.
	if WorldSimulation.day_in_progress():
		WorldSimulation.pump_day(_day_step_budget_usec())
		stamp=trace.mark("frame_world_day",stamp)
	if GameState.founding_focus!="" and PeopleDirection.needs_century_choice():
		if game_speed>0.0: _set_game_speed(0.0)
		if not is_instance_valid(PeopleDirection.panel): PeopleDirection.open_direction()
		return
	if GeneralCampaign.active:
		var committed:=GeneralCampaign.consume_time(delta)
		if committed>0:advance_world_time(committed)
		GeneralCampaign.after_world_time()
		return
	if game_speed <= 0.0:
		return
	if calendar_days>0.0:
		_schedule_world_time(calendar_days)
		trace.mark("frame_schedule",stamp)

## Frame budget for the day in progress. Steps are atomic, so one step can
## exceed it; the budget bounds how many run back to back.
func _day_step_budget_usec()->int:
	if _camera_in_motion():return DAY_STEP_BUDGET_NAVIGATING_USEC
	return DAY_STEP_BUDGET_FAST_USEC if _speed_hours_per_second()>=24.0 else DAY_STEP_BUDGET_USEC

## The frame-loop calendar. Owned worlds run each day as bounded steps across
## frames; legacy worlds and campaign intervals keep the synchronous path.
func _schedule_world_time(days_advanced:float)->void:
	if not scheduled_world_days_enabled or not WorldSimulation.enabled or GeneralCampaign.active:
		advance_world_time(days_advanced)
		return
	var century:=float(PeopleDirection.next_century_day())
	if WorldSimulation.day_in_progress():
		# Calendar time accrues while the day computes, so computing and waiting
		# overlap. Up to CALENDAR_BANK_DAYS past the next boundary is kept, so a
		# quick day can make up a slow one. The shown date holds at the day start.
		var running:=WorldSimulation.day_in_progress_number()
		var accrued:=minf(scheduled_world_elapsed+days_advanced,minf(float(running+1)+CALENDAR_BANK_DAYS,century))
		scheduled_world_days+=accrued-scheduled_world_elapsed
		scheduled_world_elapsed=accrued
		return
	GameState.elapsed_days=minf(GameState.elapsed_days+days_advanced+calendar_bank_days,century)
	calendar_bank_days=0.0
	scheduled_world_elapsed=GameState.elapsed_days
	if last_discovery_day>=int(floor(scheduled_world_elapsed)) or game_speed<=0.0:
		var after_stamp:int=preload("res://scripts/performance_trace.gd").start()
		_after_world_time(days_advanced)
		preload("res://scripts/performance_trace.gd").mark("schedule_idle_after",after_stamp)
		return
	var day:=last_discovery_day+1
	scheduled_world_days=days_advanced
	GameState.elapsed_days=float(day)
	GameState.convoy_traveling=bool(GameState.founding_journey.get("active",false))
	var daily_context:=_discovery_context()
	for city in GameState.player_settlements:
		if not bool(city.get("primary",false)):_initialize_city_resource_sites(String(city.id))
	var begin_stamp:int=preload("res://scripts/performance_trace.gd").start()
	WorldSimulation.begin_day(day,daily_context,_process_local_settlement_day,_finish_scheduled_day.bind(day))
	begin_stamp=preload("res://scripts/performance_trace.gd").mark("schedule_begin_day",begin_stamp)
	WorldSimulation.pump_day(_day_step_budget_usec())
	preload("res://scripts/performance_trace.gd").mark("schedule_first_pump",begin_stamp)

func _finish_scheduled_day(day_result:Dictionary,day:int)->void:
	var trace=preload("res://scripts/performance_trace.gd")
	var stamp:int=trace.start()
	last_discovery_day=day
	_commit_world_day(day_result)
	stamp=trace.mark("day_commit",stamp)
	# An attention pause during the day stops the calendar at that day.
	# The shown date never passes the computed day; banked time waits apart.
	GameState.elapsed_days=minf(scheduled_world_elapsed,float(day+1)) if game_speed>0.0 else float(day)
	calendar_bank_days=maxf(0.0,scheduled_world_elapsed-float(day+1)) if game_speed>0.0 else 0.0
	_after_world_time(scheduled_world_days if game_speed>0.0 else 0.0)
	trace.mark("day_after_world_time",stamp)

## The simulated date, including a day whose steps are still running.
func _simulated_day()->int:
	return WorldSimulation.day_in_progress_number() if WorldSimulation.day_in_progress() else last_discovery_day

func advance_world_time(days_advanced:float)->void:
	# Synchronous callers (campaign intervals, tests) first commit any day in progress.
	WorldSimulation.flush_day()
	# Stop at the calendar boundary; never simulate part of an unchosen century.
	GameState.elapsed_days = minf(GameState.elapsed_days+days_advanced,float(PeopleDirection.next_century_day()))
	var requested_world_day:=GameState.elapsed_days
	var current_discovery_day := int(floor(requested_world_day))
	while last_discovery_day < current_discovery_day and (game_speed>0.0 or GeneralCampaign.active):
		last_discovery_day += 1
		GameState.elapsed_days=float(last_discovery_day)
		GameState.convoy_traveling=bool(GameState.founding_journey.get("active",false)) if WorldSimulation.enabled else travel_active
		if not WorldSimulation.enabled:CivilizationSystem.advance_to_day(last_discovery_day)
		if not WorldSimulation.enabled and MilitaryCampaign.recovery.home_unavailable():
			MilitaryCampaign.recovery.advance(last_discovery_day)
			_process_other_city_resources()
			continue
		var daily_context := _discovery_context()
		for city in GameState.player_settlements:
			if not bool(city.get("primary",false)):_initialize_city_resource_sites(String(city.id))
		var day_result:=WorldSimulation.advance_day(last_discovery_day,daily_context,_process_local_settlement_day) if WorldSimulation.enabled else preload("res://scripts/civilization_day.gd").advance(last_discovery_day,daily_context,_process_local_settlement_day)
		_commit_world_day(day_result)
	if last_discovery_day<current_discovery_day:
		days_advanced=maxf(0.0,days_advanced-(requested_world_day-float(last_discovery_day)))
		requested_world_day=float(last_discovery_day)
	GameState.elapsed_days=requested_world_day
	_after_world_time(days_advanced)

## Presents one committed simulation day: reports, advisors, overlays.
func _commit_world_day(day_result:Dictionary)->void:
	var discoveries:Array[Dictionary]=day_result.discoveries
	# The Chronicle grades the day first; its moments replace research popups.
	preload("res://scripts/chronicle.gd").ingest_day(day_result)
	if not discoveries.is_empty():preload("res://scripts/hud/research_announcements.gd").announce(self,hud,discoveries)
	var resource_events:Array[Dictionary]=day_result.resources
	var simulation_events:Array[Dictionary]=day_result.events
	var progression_events:Array[Dictionary]=day_result.progression
	if not (day_result.get("arrival",{}) as Dictionary).is_empty():_show_convoy_arrival(day_result.arrival)
	if not discoveries.is_empty() or not resource_events.is_empty():footprint_population=-1
	AdvisorSystem.refresh_pronouncement_statuses()
	_refresh_population_allocations()
	for consequence in simulation_events:
		if String(consequence.get("severity","")) in ["danger","critical","warning"]:
			AdvisorSystem.generate_consequence_item(consequence)
	for resource_event in resource_events:
		if String(resource_event.get("title","")) in ["Resource Flow Constrained","Material Losses","Resource Accessible"]:
			AdvisorSystem.generate_consequence_item({"description":String(resource_event.get("description","")),"domain":"materials","severity":"warning" if String(resource_event.get("title",""))!="Resource Accessible" else "notice"})
	preload("res://scripts/strategic_history.gd").sample()
	_refresh_discovered_resource_overlays()
	_refresh_settlement_footprint()
	preload("res://scripts/rite_marks.gd").refresh(self)
	preload("res://scripts/living_map.gd").refresh(self)
	if travel_status_label:
		var news:=MapTickerWords.day_news(progression_events,discoveries,resource_events,simulation_events)
		if news!="":travel_status_label.text=news
	_evaluate_travel_survival()
	if hud:preload("res://scripts/hud/chronicle_card.gd").flush(self,hud)

## Calendar-time presentation after whole days are committed.
func _after_world_time(days_advanced:float)->void:
	if not GameState.founding_journey.is_empty():
		var journey:=GameState.founding_journey
		travel_days_elapsed=float(journey.get("elapsed",0.0))
		travel_days_total=maxf(0.001,float(journey.get("duration_days",0.001)))
		var progress:=clampf(travel_days_elapsed/travel_days_total,0,1)
		var point:=CivilizationTravel.journey_position(journey)
		settler_marker.position=Vector3(point.x,_height_at(point.x,point.y)+.002,point.y)
		var was_traveling:=travel_active
		travel_active=bool(journey.get("active",false))
		var led:=not (journey.get("caravan",{}) as Dictionary).is_empty()
		if not led:_check_travel_milestone_reports(progress)
		if was_traveling and not travel_active:
			travel_reported_milestones.erase("forage_ready")
			# A caravan leader explains its own camps and arrival (below).
			if not led:
				if route_mesh:route_mesh.visible=false
				_issue_travel_council_report("arrival" if progress>=1 else "halt",progress,GameState.convoy_emergency_halt_reason)
	_process_settlement_convoy()
	_present_caravan_reports()
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
	time_interface_between_days=true
	_update_time_interface()
	time_interface_between_days=false


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


func _live_report_global_interaction_active()->bool:
	for overlay in [settlement_naming_panel,settlement_convoy_confirm_panel,scout_dispatch_panel,founding_focus_panel,world_menu_panel]:
		if overlay and is_instance_valid(overlay) and overlay.is_visible_in_tree(): return true
	return false


func _cached_civilization_geography(origin:Vector2)->Dictionary:
	# Authored potential only; extraction and regrowth stay in live ledgers.
	var key:=[GameState.world_seed,origin]
	if not civilization_geography_cache.has(key):
		if civilization_geography_cache.size()>=512:civilization_geography_cache.erase(civilization_geography_cache.keys()[0])
		civilization_geography_cache[key]=_sample_civilization_geography(origin)
	return civilization_geography_cache[key]

func _civilization_geography(origin:Vector2)->Dictionary:
	return _cached_civilization_geography(origin).duplicate(true)

func _cached_civilization_surface_materials(origin:Vector2)->Dictionary:
	# Catchment potential is authored geography, independent of current stocks.
	# Search points must not build water-source and climate reports as a side effect.
	var key:=[GameState.world_seed,origin]
	if not civilization_surface_cache.has(key):
		if civilization_surface_cache.size()>=512:civilization_surface_cache.erase(civilization_surface_cache.keys()[0])
		civilization_surface_cache[key]=_surface_material_catchments(Vector3(origin.x,0,origin.y))
	return civilization_surface_cache[key]

func _civilization_surface_materials(origin:Vector2)->Dictionary:
	return _cached_civilization_surface_materials(origin).duplicate(true)

func _sample_civilization_geography(origin:Vector2)->Dictionary:
	var ground:=_survey_ground_at(origin)
	var water_distance:=_river_distance_at(origin.x,origin.y)*KM_PER_WORLD_UNIT
	var catchments:=_cached_civilization_surface_materials(origin)
	var water_sources:=_water_conveyance_sources(Vector3(origin.x,_height_at(origin.x,origin.y),origin.y))
	return {"water_conveyance_sources":water_sources,"environment_profile":PlanetEnvironment.profile_at(origin,ground),"surface_water_distance_km":water_distance,"surface_water_recognized":water_distance<=72.0,"surface_material_catchments":catchments,"woodland_catchment":catchments.Timber,"terrain_height_at":Callable(self,"_height_at"),"buildable_land_at":func(x:float,z:float)->bool:return _height_at(x,z)>SEA_LEVEL+.012,"river_distance_at":Callable(self,"_river_distance_at"),"drainage_tangent_at":Callable(self,"_drainage_tangent_at"),"moisture_at":Callable(self,"_land_moisture_at")}

func _discovery_context()->Dictionary:
	if WorldSimulation.enabled:
		var point:=Vector2(GameState.settlement_founded_at.x,GameState.settlement_founded_at.z) if GameState.settlement_site_committed else CivilizationSystem.player_world_origin
		return preload("res://scripts/civilization_day.gd").context(point,GameState.convoy_traveling)
	var origin:=GameState.settlement_founded_at if GameState.settlement_site_committed else (settler_marker.position if settler_marker else world_start_position)
	var context:=preload("res://scripts/civilization_day.gd").context(Vector2(origin.x,origin.z),travel_active)
	context["travel_days_remaining"]=maxf(0.0,travel_days_total-travel_days_elapsed) if travel_active else 0.0
	context["travel_distance_remaining_km"]=Vector2(origin.x,origin.z).distance_to(Vector2(travel_target.x,travel_target.z))*KM_PER_WORLD_UNIT if travel_active else 0.0
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
	mountain_relief.configure(GameState.world_seed)
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
	# One shared coastline (CoastShape): roughened near sea level, continuous
	# across it, with land relief growing in from the shore.
	land_signal=COAST_SHAPE.roughen(land_signal,x,z,terrain_noise,detail_noise)
	if land_signal<=0.0:
		return COAST_SHAPE.sea_height(land_signal)
	var shore_relief:=COAST_SHAPE.relief_weight(land_signal)
	var rolling := terrain_noise.get_noise_2d(x,z)
	var local_detail := detail_noise.get_noise_2d(x,z)
	var hill_signal:=maxf(0.0,terrain_noise.get_noise_2d(x+820.0,z-460.0)+0.10)
	var ridge := 1.0-absf(mountain_noise.get_noise_2d(x,z))
	ridge = pow(clampf((ridge-0.34)/0.66,0.0,1.0),2.35)
	var belt := clampf((mountain_noise.get_noise_2d(x*0.41+9200.0,z*0.41-3800.0)+0.18)*1.55,0.0,1.0)
	var height := COAST_SHAPE.land_base(land_signal)+(rolling*1.42+local_detail*0.56+pow(hill_signal,2.0)*2.05+ridge*belt*8.4)*shore_relief
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
	height+=range_band*(0.65+range_teeth*6.8)*shore_relief
	height+=mountain_relief.height_at(x,z,(ridge*belt*8.4+range_band*(0.65+range_teeth*6.8))*shore_relief)*smoothstep(.2,.8,height)
	var local_drainage_distance:=_local_drainage_distance_at(x,z)
	if local_drainage_distance<0.11:
		var swale:=pow(1.0-local_drainage_distance/0.11,1.72)
		# Four to nine metres of relief is enough to create a real drainage floor at
		# settlement scale without turning every intermittent reach into a canyon.
		# Faded out at the shore: parallel reaches must not cut below sea level
		# into straight flooded strips across a low coastal plain.
		height-=swale*(0.0045+0.0045*swale)*smoothstep(0.004,0.03,height)
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
	var channel_x:=_local_drainage_channel_x(channel_index,z)
	var activation_raw:=0.50+sin(z*1.11+float(channel_index)*1.73+phase*31.0)*0.31+sin(z*0.37-float(channel_index)*2.41+phase*67.0)*0.19
	var activation:=smoothstep(0.29,0.72,activation_raw)
	if activation<0.28: return INF
	# Weak reaches report a larger effective distance, naturally fading their
	# influence on siting and cultivation without binary on/off seams.
	return absf(x-channel_x)+lerpf(0.075,0.0,activation)

func _local_drainage_channel_x(channel_index:int,z:float)->float:
	var phase:=float(posmod(GameState.world_seed,10007))/10007.0
	return float(channel_index)*2.4+(phase-.5)*2.4+sin(z*1.34+float(channel_index)*2.17+phase*TAU)*.22+sin(z*3.71-float(channel_index)*.83+phase*17.0)*.055

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
	# Beyond the chart's edge: the dark leather of the map table.
	settings.background_color = Color("#1c1812")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	# Low warm key light (docs/ART_DIRECTION.md): a painted landscape in the
	# first hours of the day. The sky fill is cooler and dimmer than the key so
	# the shadowed side of every slope and crown reads as form, not flat green.
	# The fill is the open sky: a little cooler than the key, so shade reads
	# blue-grey against warm sunlit ground (world_beauty.gdshaderinc).
	settings.ambient_light_color = Color("#97a3ab")
	# Raised in round two (codex/beauty-2): shaded slopes and cast shadows at
	# close and valley views read as cool shade, not dark blots.
	settings.ambient_light_energy = 0.46 if SEAMLESS_WORLD else 0.36
	settings.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.environment = settings
	add_child(environment)

	var sun := DirectionalLight3D.new()
	# From the north-west, the cartographer's convention: north is up, so the
	# light falls from the upper left and relief reads as raised, never sunken.
	# The chart hillshade and canopy edges in the ground shader use the same sun.
	sun.rotation_degrees = Vector3(-31, -138, 0)
	sun.light_color = Color("#f4e4cc")
	sun.light_energy = 1.12 if SEAMLESS_WORLD else 0.88
	sun.shadow_enabled = bool(display_preferences.shadows) if display_preferences else true
	# Oblique satellite views amplify one-pixel cascade stair-steps into bright
	# kilometre-long bands on ridge crests. A modest penumbra preserves the relief
	# while removing the low-poly-looking shadow edge.
	sun.shadow_blur=2.4
	# Painted shade is never black: hill shadows keep some sky light, so a cast
	# shadow reads as cool shade across the land rather than a hole in it.
	sun.shadow_opacity=0.52
	sun.directional_shadow_max_distance = 900.0 if SEAMLESS_WORLD else 180.0
	add_child(sun)

	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_PERSPECTIVE if SEAMLESS_WORLD else Camera3D.PROJECTION_ORTHOGONAL
	camera.fov = 35.0
	camera.size = _distance_camera_size(0) if SEAMLESS_WORLD else 108.0
	camera.near = 0.05
	camera.far = 100000.0
	camera.current = true
	add_child(camera)
	if SEAMLESS_WORLD:
		set_camera_distance_level(0)
		camera.size=zoom_target_size
		zoom_target_size=-1.0
		zoom_preset_active=false
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
	if SEAMLESS_WORLD:(mesh_instance.material_override as ShaderMaterial).set_shader_parameter("far_layer",true)
	add_child(mesh_instance)
	if not SEAMLESS_WORLD:
		mesh_instance.create_trimesh_collision()
		terrain_body = mesh_instance.get_child(0) as StaticBody3D
		if terrain_body:
			terrain_body.name = "TerrainBody"

func _rebuild_regional_terrain_patch(center:Vector2,span:float)->void:
	if not SEAMLESS_WORLD: return
	# Stable geometric buckets avoid rebuilding for each interpolated zoom frame.
	span=TERRAIN_LOD.bucket(span)
	var snapped:=TERRAIN_LOD.center_for(center,span)
	var resolution:=TERRAIN_LOD.resolution_for(span)
	# Hold a requested center inside its overscan margin. Pointer-anchored zoom
	# moves the target every frame; snapping alone still repeatedly cancelled work.
	if terrain_patch_job!=null and is_equal_approx(terrain_patch_job.span,span):
		var drift:Vector2=(center-terrain_patch_job.center).abs()
		if maxf(drift.x,drift.y)<=span/12.0:return
	if regional_terrain_patch and is_equal_approx(regional_patch_span,span) and _regional_patch_covers_camera():
		snapped=regional_patch_center
	if terrain_patch_job!=null:
		if terrain_patch_job.center==snapped and is_equal_approx(terrain_patch_job.span,span): return
		# Latest view wins. Do not finish/upload a mesh for a camera already gone.
		terrain_patch_job=null
		terrain_patch_cancellations+=1
	if regional_terrain_patch and regional_patch_center==snapped and is_equal_approx(regional_patch_span,span) and regional_patch_resolution==resolution: return
	for cached in terrain_patch_cache:
		if cached.center==snapped and is_equal_approx(cached.span,span) and int(cached.resolution)==resolution:
			_install_regional_patch(cached)
			return
	# A geographic low-density pass fills the current view first. It uses the same
	# height/color authorities and is replaced by the final full-density mesh.
	var same_patch:=regional_terrain_patch!=null and regional_patch_center==snapped and is_equal_approx(regional_patch_span,span)
	var next_resolution:=TERRAIN_LOD.next_resolution(span,regional_patch_resolution if same_patch else 0)
	# Never replace established detailed ground/water with a coarse preview.
	# Retain the old pair until the next full-detail pair is ready to swap.
	if regional_terrain_patch!=null and regional_patch_resolution==TERRAIN_LOD.resolution_for(regional_patch_span):
		next_resolution=resolution
	var prior:=_overlapping_terrain_samples(snapped,span,next_resolution)
	terrain_patch_job=TERRAIN_PATCH_BUILDER.new(next_resolution,span,snapped,_height_at,_terrain_color_at,_terrain_surface_fields_at,_terrain_seasonality_at,prior)
	# codex/terrain-bake: planet-scale patches read the per-seed raster (null = noise).
	terrain_patch_job.macro_raster=macro_render.raster_for(snapped,span,next_resolution)

func _regional_patch_covers_camera()->bool:
	if camera==null or regional_terrain_patch==null:return false
	return _patch_covers_camera(regional_patch_center,regional_patch_span)

func _patch_covers_camera(center:Vector2,span:float)->bool:
	if camera==null:return false
	var size:=get_viewport().get_visible_rect().size
	for corner:Vector2 in [Vector2.ZERO,Vector2(size.x,0),size,Vector2(0,size.y)]:
		var direction:=camera.project_ray_normal(corner)
		if direction.y>=-0.001:return false
		var origin:=camera.project_ray_origin(corner)
		var hit:=origin+direction*((camera_target.y-origin.y)/direction.y)
		# Conservative margin for relief projecting beyond the target-height plane.
		if absf(hit.x-center.x)>span*0.46 or absf(hit.z-center.y)>span*0.46:return false
	return true

func _overlapping_terrain_samples(center:Vector2,span:float,resolution:int)->Dictionary:
	var best:Dictionary={};var best_score:=0.0
	var candidates:=terrain_patch_cache.duplicate()
	if not terrain_patch_sample_source.is_empty():candidates.append(terrain_patch_sample_source)
	for candidate:Dictionary in candidates:
		if not candidate.has("samples"):continue
		if int(candidate.get("sample_seed",0))!=GameState.world_seed or int(candidate.get("sample_province",-1))!=GameState.active_province:continue
		# Different spans are not assumed to share a lattice. Zoom refinement and
		# neighbouring pan requests at one span can share exact completed samples.
		if float(candidate.span)!=span:continue
		var delta:Vector2=(center-Vector2(candidate.center)).abs()
		var area:=maxf(0.0,span-delta.x)*maxf(0.0,span-delta.y)/(span*span)
		var density:=minf(1.0,pow(float(int(candidate.resolution)-1)/float(resolution-1),2.0))
		var score:=area*density
		if score>best_score:best_score=score;best=candidate.samples
	return best

func _advance_terrain_patch()->void:
	if terrain_patch_job==null: return
	# A useful low-density patch is already visible while refinement runs. Keep
	# sampling below one tenth of a 60 Hz frame during navigation and below one
	# fifth while idle; the former 2.5/5 ms slices compounded with rendering into
	# obvious hitches even though the final terrain arrived sooner.
	if not terrain_patch_job.advance(TERRAIN_PATCH_MOVING_BUDGET_USEC if _camera_in_motion() else TERRAIN_PATCH_IDLE_BUDGET_USEC): return
	var started:=Time.get_ticks_usec()
	var completed:Dictionary={"mesh":terrain_patch_job.commit(),"center":terrain_patch_job.center,"span":terrain_patch_job.span,"resolution":terrain_patch_job.resolution,"heights":terrain_patch_job.heights,"cover":terrain_patch_job.cover,"samples":terrain_patch_job.completed_samples(),"sample_seed":GameState.world_seed,"sample_province":GameState.active_province}
	terrain_patch_last_slice_usec=terrain_patch_job.max_slice_usec
	terrain_patch_last_reused_vertices=terrain_patch_job.reused_vertices
	terrain_patch_last_sampled_vertices=terrain_patch_job.sampled_vertices
	terrain_patch_job=null
	_install_regional_patch(completed)
	TERRAIN_LOD.retain(terrain_patch_cache,completed)
	terrain_patch_last_commit_usec=Time.get_ticks_usec()-started

func _install_regional_patch(completed:Dictionary)->void:
	# A cached close view can be ready before the zoom reaches it. Keep the
	# wider terrain until the close patch covers the frame, avoiding a detail box.
	if camera!=null and zoom_target_size>0.0 and regional_terrain_patch!=null and float(completed.span)<regional_patch_span and not _patch_covers_camera(completed.center,float(completed.span)):return
	terrain_patch_sample_source=completed if completed.has("samples") else {}
	var replacement:=MeshInstance3D.new()
	replacement.name="RegionalTerrainLOD"
	replacement.mesh=completed.mesh
	replacement.material_override=regional_terrain_patch.material_override if regional_terrain_patch else _create_terrain_material()
	# Soft outer edge (coast_mask.gdshaderinc): the patch dissolves into the planet layer.
	replacement.set_instance_shader_parameter("patch_feather",Vector4(completed.center.x,completed.center.y,float(completed.span),1.0))
	add_child(replacement)
	var previous:=regional_terrain_patch
	regional_terrain_patch=replacement
	regional_patch_center=completed.center
	regional_patch_span=completed.span
	regional_patch_resolution=int(completed.resolution)
	var height_image:=Image.create_from_data(regional_patch_resolution,regional_patch_resolution,false,Image.FORMAT_RF,completed.heights.to_byte_array())
	rendered_regional_heights=completed.heights
	river_terrain_height_texture=ImageTexture.create_from_image(height_image)
	# The same heights box-filtered level by level, for the chart's
	# generalised landform (map_chart.gdshaderinc).
	height_image.generate_mipmaps()
	chart_relief_texture=ImageTexture.create_from_image(height_image)
	# Its land cover and land/water mask, likewise (the chart's woods, marsh
	# and water-lines); patches built elsewhere without it keep the last off.
	var cover:PackedByteArray=completed.get("cover",PackedByteArray())
	chart_cover_texture=null
	if cover.size()==regional_patch_resolution*regional_patch_resolution*4:
		var cover_image:=Image.create_from_data(regional_patch_resolution,regional_patch_resolution,false,Image.FORMAT_RGBA8,cover)
		cover_image.generate_mipmaps()
		chart_cover_texture=ImageTexture.create_from_image(cover_image)
	river_terrain_grid=Vector4(regional_patch_center.x,regional_patch_center.y,regional_patch_span,float(regional_patch_resolution))
	for river in river_overlays: _bind_river_terrain(river.material_override)
	# The patch's land draws its shoreline from the same heights (map_coast).
	_bind_river_terrain(replacement.material_override)
	_refresh_coastal_water_patch()
	if previous:
		previous.visible=false
		previous.queue_free()


func _sync_coast_mask()->void:
	## Upload each macro raster's exact heights once, when it lands or changes, so
	## the planet mesh and planet ocean share one per-pixel shoreline with the
	## streamed patches (coast_mask.gdshaderinc). Until then they fall back to
	## their own geometry.
	for index in 2:
		var raster:RefCounted=macro_render.levels[index]
		if raster==coast_mask_rasters[index]:continue
		coast_mask_rasters[index]=raster
		var texture:Texture2D=null
		var color_texture:Texture2D=null
		var fields_texture:Texture2D=null
		var grid:=Vector4.ZERO
		if raster!=null:
			var columns:=int(raster.get("columns"));var rows:=int(raster.get("rows"))
			var heights:PackedFloat32Array=raster.get("heights")
			var colors:PackedInt32Array=raster.get("colors")
			var fields:PackedInt32Array=raster.get("fields")
			var nodes:=columns*rows
			if columns>1 and rows>1 and heights.size()==nodes and colors.size()==nodes and fields.size()==nodes:
				var image:=Image.create_from_data(columns,rows,false,Image.FORMAT_RF,heights.to_byte_array())
				# Half floats filter linearly on every GPU; metre precision near sea level.
				image.convert(Image.FORMAT_RH)
				texture=ImageTexture.create_from_image(image)
				color_texture=ImageTexture.create_from_image(Image.create_from_data(columns,rows,false,Image.FORMAT_RGBA8,colors.to_byte_array()))
				fields_texture=ImageTexture.create_from_image(Image.create_from_data(columns,rows,false,Image.FORMAT_RGBA8,fields.to_byte_array()))
				var origin:Vector2=raster.get("origin");var cell:Vector2=raster.get("cell")
				grid=Vector4(origin.x,origin.y,cell.x,cell.y)
		for material:ShaderMaterial in [province_terrain_mesh.material_override if province_terrain_mesh else null,ocean_surface.material_override if ocean_surface else null,coastal_water_material]:
			if material==null:continue
			material.set_shader_parameter("coast_level%d" % index,texture)
			material.set_shader_parameter("coast_grid%d" % index,grid)
		if province_terrain_mesh and province_terrain_mesh.material_override is ShaderMaterial:
			var far:=province_terrain_mesh.material_override as ShaderMaterial
			far.set_shader_parameter("coast_color%d" % index,color_texture)
			far.set_shader_parameter("coast_fields%d" % index,fields_texture)

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
		# A pixel inside the corridor must be within padding of a segment point
		# on this row. Clip that segment's parameter range before scanning x;
		# long diagonals otherwise test their entire bounding rectangle.
		var left:=minf(a.x,b.x)
		var right:=maxf(a.x,b.x)
		var dy:=float(b.y)-float(a.y)
		if absf(dy)>0.000001:
			var t0:=(float(pixel_y)-padding-float(a.y))/dy
			var t1:=(float(pixel_y)+padding-float(a.y))/dy
			var low:=clampf(minf(t0,t1),0.0,1.0)
			var high:=clampf(maxf(t0,t1),0.0,1.0)
			var x0:=lerpf(float(a.x),float(b.x),low)
			var x1:=lerpf(float(a.x),float(b.x),high)
			left=minf(x0,x1)
			right=maxf(x0,x1)
		# One conservative guard pixel covers floating-point endpoint rounding.
		var first_x:=maxi(maxi(0,floori(minf(a.x,b.x)-padding)),floori(left-padding)-1)
		var end_x:=mini(mini(width,ceili(maxf(a.x,b.x)+padding)+1),ceili(right+padding)+2)
		for pixel_x in range(first_x,end_x):
			var pixel:=Vector2(float(pixel_x),float(pixel_y))
			var distance:=pixel.distance_to(Geometry2D.get_closest_point_to_segment(pixel,a,b))/radius_pixels
			if distance>1.25: continue
			var reveal:=1.0-smoothstep(0.82,1.25,distance)
			if reveal>image.get_pixel(pixel_x,pixel_y).r: image.set_pixel(pixel_x,pixel_y,Color(reveal,reveal,reveal))


func _refresh_discovery_mask(force:bool=false)->void:
	var revision:=CivilizationSystem.fog_revision
	var origin:Vector2=CivilizationSystem.player_world_origin
	terrain_fog_materials.update(discovery_mask_texture,origin,force)
	vegetation_fog_materials.update(discovery_mask_texture,origin,force)
	if not force and revision==rendered_fog_revision:return
	var width:=1024
	var height:=512
	# The charted ground only grows: a new record is appended, or the latest
	# trail is extended. Paint just those onto the mask already drawn (a mature
	# world holds hundreds of records, and repainting them all cost ~10 ms each
	# time a scout's day revealed ground). Anything else repaints from scratch.
	var areas:Array=CivilizationSystem.revealed_areas
	var first_new:=0
	var image:=discovery_mask_image
	var repainted:=image==null
	if not force and image!=null and discovery_mask_painted>0 and areas.size()>=discovery_mask_painted \
			and _discovery_area_key(areas[0])==discovery_mask_first_key \
			and _discovery_area_key(areas[discovery_mask_painted-1])==discovery_mask_last_key:
		first_new=discovery_mask_painted-1
	else:
		image=Image.create(width,height,false,Image.FORMAT_L8)
		image.fill(Color.BLACK)
		repainted=true
	for area_index in range(first_new,areas.size()):
		var area:Dictionary=areas[area_index]
		var radius:=maxf(1.0,float(area.get("radius",1.0)))
		var points:Array=area.get("points",[])
		if String(area.get("kind","circle"))=="trail" and points.size()>=2:
			for point_index in points.size()-1:
				var a:Dictionary=points[point_index]; var b:Dictionary=points[point_index+1]
				_paint_discovery_segment(image,Vector2(float(a.get("x",0.0)),float(a.get("z",0.0))),Vector2(float(b.get("x",0.0)),float(b.get("z",0.0))),radius,width,height)
		else:
			_paint_discovery_disc(image,Vector2(float(area.get("x",0.0)),float(area.get("z",0.0))),radius,width,height)
	discovery_mask_image=image
	discovery_mask_painted=areas.size()
	discovery_mask_first_key=_discovery_area_key(areas[0]) if not areas.is_empty() else ""
	discovery_mask_last_key=_discovery_area_key(areas[-1]) if not areas.is_empty() else ""
	# codex/map-motion: newly charted ground inks in over about a second.
	var reveal:=preload("res://scripts/discovery_reveal.gd")
	if discovery_mask_texture==null:
		discovery_mask_texture=ImageTexture.create_from_image(image)
		reveal.present(self,discovery_mask_texture,image,Rect2i(),true)
	else:
		var changed:=Rect2i() if repainted else reveal.areas_rect(areas.slice(first_new),_discovery_mask_pixel,Vector2i(width,height),maxf(float(width)/world_width,float(height)/world_depth)*1.25)
		if not reveal.present(self,discovery_mask_texture,image,changed,force or repainted):discovery_mask_texture.update(image)
	rendered_fog_revision=revision
	terrain_fog_materials.update(discovery_mask_texture,origin)
	vegetation_fog_materials.update(discovery_mask_texture,origin)


## The painted discovery mask and which revealed records it already holds.
var discovery_mask_image:Image
var discovery_mask_painted:=0
var discovery_mask_first_key:=""
var discovery_mask_last_key:=""

## Identifies a revealed record apart from later extension of its trail.
func _discovery_area_key(area_variant:Variant)->String:
	var area:Dictionary=area_variant if area_variant is Dictionary else {}
	return "%s|%s|%.4f|%.4f|%.3f|%d" % [String(area.get("kind","")),String(area.get("source","")),float(area.get("x",0.0)),float(area.get("z",0.0)),float(area.get("radius",0.0)),int(area.get("day",0))]

func _fog_shader_parameters(material:ShaderMaterial)->void:
	terrain_fog_materials.register(material,discovery_mask_texture,Vector2(world_width,world_depth),CivilizationSystem.player_world_origin)

func _world_position_is_revealed(position:Vector3)->bool:
	return CivilizationSystem._position_is_revealed(Vector2(position.x,position.z))

func _create_terrain_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode diffuse_burley, specular_disabled;

uniform sampler2D ground_albedo : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D semiarid_ground_albedo : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D forest_albedo : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D regional_ground_albedo : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D discovery_mask : source_color, filter_linear;
uniform vec2 fog_world_size = vec2(40075.0, 20004.0);
uniform vec2 fog_current_origin = vec2(0.0);
uniform float drainage_phase = 0.0;
uniform float land_resources = 0.0;
uniform bool woodland_channel = true;
// The live wind (scripts/map_ambience.gd), reduced-motion switch and fresh
// snow near home from the weather sky (world_beauty.gd), all visual only.
uniform vec4 map_wind = vec4(1.0, 0.0, 0.0, 0.0);
uniform float map_wind_clock = 0.0;
uniform float wb_motion = 1.0;
uniform float weather_snow = 0.0;

varying vec3 world_position;
uniform vec4 streamed_cutout = vec4(0.0);
// Planet mesh only: land/sea from the macro rasters instead of its own triangles.
uniform bool far_layer = false;
// Streamed patches: centre.xy, span, enabled. Drives the soft outer edge.
instance uniform vec4 patch_feather = vec4(0.0);
varying vec3 world_normal;
varying vec3 relative_position;
varying vec2 surface_position;
varying float seasonal_amplitude;

float hash21(vec2 p) {
	// Integer cell hashing avoids loss of fractional precision near the far
	// sides of a 40,075 km world. Floating multiply/fract made distant soil band.
	uvec2 cell=uvec2(ivec2(p));
	uint h=(cell.x*1597334677u)^(cell.y*3812015801u);
	h=(h^(h>>16u))*2246822519u;
	h=(h^(h>>13u))*3266489917u;
	return float(h^(h>>16u))/4294967295.0;
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

#include "res://scripts/surface_precision.gdshaderinc"
#include "res://scripts/ground_surface.gdshaderinc"
#include "res://scripts/seasonal_surface.gdshaderinc"
#include "res://scripts/coast_mask.gdshaderinc"
#include "res://scripts/map_palette.gdshaderinc"
#include "res://scripts/map_coast.gdshaderinc"
#include "res://scripts/world_beauty.gdshaderinc"
#include "res://scripts/map_chart.gdshaderinc"
#include "res://scripts/map_cloud.gdshaderinc"
#include "res://scripts/settlement_ground.gdshaderinc"

// Charted ground: the discovery mask, plus the ground around the people now.
float charted_at(vec2 xz) {
	vec2 fog_uv=clamp(xz/fog_world_size+vec2(0.5),vec2(0.0),vec2(1.0));
	return max(texture(discovery_mask,fog_uv).r,1.0-smoothstep(30.0,38.0,distance(xz,fog_current_origin)));
}

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
	relative_position = world_position-CAMERA_POSITION_WORLD;
	surface_position = world_position.xz-floor(CAMERA_POSITION_WORLD.xz/64.0)*64.0;
	seasonal_amplitude = CUSTOM0.x;
	// Slide the coarse planet a few percent further along each view ray: same
	// pixels, but any streamed patch drawn over it always wins the depth test,
	// so the planet only shows where the patch has dissolved or is absent.
	// (A shader that writes POSITION must write it on every path.)
	vec4 view_position = MODELVIEW_MATRIX*vec4(VERTEX,1.0);
	if (far_layer && coast_mask_ready()) { view_position.xyz *= 1.04; }
	POSITION = PROJECTION_MATRIX*view_position;
}

void fragment() {
	// Interpolate the small camera-relative value. Differencing absolute
	// 20,000 km positions quantized a sub-metre footprint into alternating bands.
	// Taken before any discard: derivatives are undefined once quads diverge,
	// which lit a one-pixel seam along every cut and dissolve edge.
	float pixel_world = max(length(dFdx(relative_position.xz)), length(dFdy(relative_position.xz)));
	// Screen-space rate of height, for the inked coastline (also pre-discard).
	float height_px = fwidth(world_position.y);
	// Over the regional patch the shore is the smooth contour it shares with
	// the coastal water (map_coast.gdshaderinc), not its triangles' chords.
	// It is decided where this pixel's view ray meets sea level, the very
	// point the water at this pixel tests, so land and water can never both
	// give way (a hole) in a tilted view. Only ground near sea level takes
	// part: a coastal hill must not vanish because there is sea behind it.
	bool coast_smooth = !far_layer && coast_patch_ready() && patch_feather.w>0.5
		&& abs(patch_feather.z-terrain_grid.z)<terrain_grid.z*0.001
		&& coast_patch_contains(world_position.xz-terrain_grid.xy)
		&& coast_patch_cell_px(pixel_world)>=1.0;
	float coast_height = world_position.y;
	if (coast_smooth) {
		float own_spread;
		coast_patch_triangle(world_position.xz-terrain_grid.xy, own_spread);
		vec3 view_ray = world_position-CAMERA_POSITION_WORLD;
		vec2 sea_rel = CAMERA_POSITION_WORLD.xz+view_ray.xz*(CAMERA_POSITION_WORLD.y/max(-view_ray.y,0.000001))-terrain_grid.xy;
		float own_weight = smoothstep(own_spread*3.0+0.0015, own_spread*4.0+0.002, world_position.y);
		coast_smooth = own_weight < 1.0 && coast_patch_contains(sea_rel);
		if (coast_smooth) { coast_height = mix(coast_patch_ground(sea_rel, pixel_world, 0.0), world_position.y, own_weight); }
	}
	float coast_height_px = fwidth(coast_height);
	// A continental patch can straddle the finite planet map. Never extrapolate
	// procedural land beyond the playable geography. Legacy custom meshes lack UV fields.
	if (UV.x>=0.999 && (abs(world_position.x)>fog_world_size.x*0.5 || abs(world_position.z)>fog_world_size.y*0.5)) { discard; }
	// The coarse planet yields to the streamed patch only inside the patch core;
	// over the patch's dissolving margin both layers draw, so there is no gap.
	if (streamed_cutout.w > 0.5 && coast_patch_edge(world_position.xz,streamed_cutout) < COAST_CUTOUT_CORE) { discard; }
	if (coast_patch_yields(world_position.xz,patch_feather)) { discard; }
	if (coast_smooth && coast_height < 0.0) { discard; }
	// ~83 km triangles cannot draw a coastline. Let the raster decide, and let
	// the ocean plane (which yields over raster land) show through here. The
	// planet keeps a little of the shelf: it sits behind the ocean there, and
	// parallax between the two surfaces can then never open a dark seam.
	if (far_layer && coast_mask_ready() && coast_mask_height(world_position.xz) < -0.08) { discard; }
	// The planet mesh reads colour and climate fields from the macro rasters
	// (~7-21 km) rather than its ~83 km vertices, so where it shows beside a
	// streamed patch both layers carry the same land cover.
	vec4 surface_color=COLOR;
	vec2 surface_uv=UV;
	vec2 surface_uv2=UV2;
	if (far_layer && coast_mask_ready()) { coast_far_surface(world_position.xz,surface_color,surface_uv,surface_uv2); }
	float discovered=charted_at(world_position.xz);
	// Uncharted ground is blank vellum (map_palette.gdshaderinc), with the
	// frontier of the known world inked where the chart ends.
	vec3 unknown_ground=map_chart_paper(world_position.xz,CAMERA_POSITION_WORLD.y,pixel_world,fog_current_origin,SCREEN_UV);
	float reveal=smoothstep(0.06,0.62,discovered);
	// Screen pixels inland from the frontier ink (world_beauty's wash).
	float wb_frontier_px=1000000.0;
	if (discovered>0.02 && discovered<0.75) {
		// One mask texel is ~39 km; the mask is linear inside it, so a forward
		// difference over half a texel gives its exact local slope.
		float step_km=fog_world_size.x/2048.0;
		vec2 slope_per_km=vec2(charted_at(world_position.xz+vec2(step_km,0.0))-discovered,charted_at(world_position.xz+vec2(0.0,step_km))-discovered)/step_km;
		vec3 frontier=map_frontier(discovered,1.0/max(length(slope_per_km)*pixel_world,0.00001));
		wb_frontier_px=(discovered-0.30)/max(length(slope_per_km)*pixel_world,0.00001);
		float frontier_scale=smoothstep(0.015,0.20,pixel_world);
		unknown_ground=mix(unknown_ground,MAP_SEPIA,frontier.y*frontier_scale*0.38);
		unknown_ground=mix(unknown_ground,MAP_INK,frontier.x*frontier_scale*0.85);
		reveal=mix(reveal,frontier.z,frontier_scale)*(1.0-frontier.x*frontier_scale*0.85);
	}
	// From the regional view outward the known land is a hand-coloured chart
	// (map_chart.gdshaderinc), crossfaded in by view scale; at full weight the
	// painted path below is skipped altogether.
	float mc_design=mc_design_km(relative_position,PROJECTION_MATRIX);
	float mc_w=mc_chart_weight(mc_design);
	vec3 mc_ground=vec3(0.0);
	vec3 mc_normal=vec3(0.0,1.0,0.0);
	if (mc_w>0.0 && reveal>0.0) {
		vec3 mc_f=mc_fields(surface_color,surface_uv,pixel_world,woodland_channel,world_position.y);
		float mc_wood=mc_f.z;
		if (!far_layer && patch_feather.w>0.5 && coast_mask_ready()) {
			float mc_seam=smoothstep(0.60,0.82,coast_patch_edge(world_position.xz,patch_feather));
			if (mc_seam>0.0) {
				vec4 mc_far_color=surface_color; vec2 mc_far_uv=surface_uv; vec2 mc_far_uv2=surface_uv2;
				coast_far_surface(world_position.xz,mc_far_color,mc_far_uv,mc_far_uv2);
				mc_wood=mix(mc_wood,clamp(mc_far_color.a,0.0,1.0),mc_seam);
			}
		}
		mc_wood*=woodland_retained(world_position.xz);
		float mc_slope=1.0-clamp(normalize(world_normal).y,0.0,1.0);
		float mc_prominence;
		vec2 mc_land=mc_landform(world_position.xz,world_position.y,pixel_world,mc_design,!far_layer,mc_normal,mc_prominence);
		float mc_temperature=surface_uv.x>=0.999?landscape_temperature(mc_f.y,seasonal_amplitude,world_position.z):15.0;
		float mc_sheltered=1.0-smoothstep(0.18,0.58,mc_slope);
		float mc_snow=(1.0-smoothstep(-1.5,3.5,mc_temperature))*smoothstep(0.045,0.38,mc_f.x)*mc_sheltered*0.78;
		mc_snow=max(mc_snow,(1.0-smoothstep(-12.0,-2.0,mc_temperature))*mc_sheltered*0.30);
		mc_snow=max(mc_snow,weather_snow*(1.0-smoothstep(2.0,7.0,mc_temperature))*(1.0-smoothstep(0.25,0.62,mc_slope))*0.8);
		mc_ground=mc_chart_ground(world_position,mc_land,mc_normal,mc_prominence,pixel_world,mc_design,mc_f.x,mc_f.y,mc_wood,mc_slope,mc_temperature,mc_snow,
			coast_height,coast_height_px,wb_frontier_px,CAMERA_POSITION_WORLD.y,land_resources,!far_layer,mc_screen_up(INV_VIEW_MATRIX));
	}
	// Fully hidden ground needs only the existing unlit veil. Avoid all
	// texture and procedural surface work until there is visible ground.
	if (reveal<=0.0) {
		ALBEDO=vec3(0.0); EMISSION=unknown_ground; ROUGHNESS=0.96;
	} else if (mc_w>=0.999) {
		ALBEDO=vec3(0.0); EMISSION=mc_ground*reveal+unknown_ground*(1.0-reveal); ROUGHNESS=0.96;
	} else {
	vec2 surface_origin=floor(CAMERA_POSITION_WORLD.xz/64.0)*64.0;
	float broad = organic_noise(world_position.xz * 0.052);
	float slope = 1.0 - clamp(dot(normalize(world_normal), vec3(0.0, 1.0, 0.0)), 0.0, 1.0);
	// The material is a scale hierarchy, not one photograph enlarged forever.
	// World units are kilometres.  Country and regional imagery only enters once
	// the projected pixel footprint can actually resolve it; this also prevents
	// visible texture repetition in continental and low-oblique views.
	float country_detail = 1.0 - smoothstep(0.55, 4.50, pixel_world);
	float regional_detail = 1.0 - smoothstep(0.050, 0.55, pixel_world);
	float local_detail = 1.0 - smoothstep(0.008, 0.075, pixel_world);
	float close_detail = 1.0 - smoothstep(0.0009, 0.008, pixel_world);
	// The ~6 km field aliases into evenly spaced dark coins once a pixel spans
	// several kilometres. At continental scale its correct filtered value is its
	// mean; skipping fifteen value-noise evaluations also lowers fragment cost.
	float regional = 0.5;
	if (country_detail>0.08) {
		regional = organic_noise(world_position.xz * 0.17 + vec2(17.0, -9.0));
	}
	// Neutral ground/forest tiles bridge regional and close views without baked
	// mountains or a photographic coastline that contradicts the terrain mesh.
	vec2 local_ground_uv = periodic_surface_uv(surface_position,surface_origin,52,100,false,vec2(0.0));
	vec2 local_ground_uv_rotated = periodic_surface_uv(surface_position,surface_origin,4524,10000,true,vec2(0.29,-0.41));
	vec2 local_forest_uv = periodic_surface_uv(surface_position,surface_origin,23,100,false,vec2(0.0));
	vec2 local_forest_uv_rotated = periodic_surface_uv(surface_position,surface_origin,1817,10000,true,vec2(-0.17,0.36));
	vec2 regional_ground_uv = periodic_surface_uv(surface_position,surface_origin,1,40,false,vec2(0.0));
	vec2 regional_ground_uv_rotated = periodic_surface_uv(surface_position,surface_origin,23,1000,true,vec2(0.37,-0.23));
	// The source albedo contains its own broad photographic mottling. At x18 it
	// repeated as 55 m rugs; x68 places that content at a believable 10–20 m aerial
	// scale, while the biome FBM above remains responsible for large land-cover mass.
	vec2 close_uv = periodic_surface_uv(surface_position,surface_origin,68,1,false,vec2(0.0));
	vec2 close_uv_rotated = periodic_surface_uv(surface_position,surface_origin,5644,100,true,vec2(0.19,-0.27));
	float precipitation=surface_uv.x>=0.999?clamp(surface_uv.x-1.0,0.0,1.0):clamp((surface_color.g-surface_color.r)*4.0+0.48,0.0,1.0);
	float climate_woodland_mean=clamp(surface_color.a,0.0,1.0);
	vec3 filtered_vertex_color=surface_color.rgb;
	if (woodland_channel && surface_uv.x>=0.999) {
		climate_woodland_mean=clamp((precipitation-0.40)*2.6,0.0,1.0)
			*clamp((surface_uv.y-0.16)*3.4,0.0,1.0);
		if (world_position.y>3.2) {
			climate_woodland_mean*=1.0-clamp((world_position.y-3.2)/5.2,0.0,0.74);
		}
		climate_woodland_mean*=0.61;
		// Rebuild the same climate tint without the unresolved sub-kilometre
		// woodland draw embedded in a coarse vertex sample.
		vec3 climate_vertex=mix(vec3(0.478,0.424,0.298),vec3(0.373,0.416,0.271),clamp((precipitation-0.18)*3.2,0.0,1.0));
		float climate_dryness=1.0-smoothstep(0.30,0.49,precipitation);
		climate_vertex=mix(climate_vertex,vec3(0.643,0.541,0.349),climate_dryness*0.92);
		climate_vertex=mix(climate_vertex,vec3(0.173,0.290,0.204),climate_woodland_mean*0.90);
		filtered_vertex_color=mix(climate_vertex,filtered_vertex_color,country_detail);
	}
	float biome_patch = organic_noise(world_position.xz * 0.011 + vec2(-5.0, 11.0));
	float soil_patch = organic_noise(world_position.xz * 0.062 + vec2(23.0, -17.0));
	vec3 vertex_tint = mix(vec3(dot(filtered_vertex_color, vec3(0.28,0.57,0.15))), filtered_vertex_color, 0.78);
	vec3 climate_ground = mix(vec3(0.31,0.275,0.165), vec3(0.245,0.345,0.205), clamp(biome_patch*0.58+broad*0.42,0.0,1.0));
	climate_ground = mix(climate_ground, vertex_tint, 0.72);
	climate_ground *= 0.91 + (organic_noise(world_position.xz*0.0024)-0.5)*0.15;
	vec3 procedural_ground = mix(climate_ground, mix(vec3(0.255,0.245,0.165), vec3(0.405,0.385,0.245), broad * 0.62 + biome_patch * 0.38), country_detail*0.38);
	procedural_ground *= 0.92 + (soil_patch - 0.5) * mix(0.04,0.17,country_detail);
	// Ground textures carry grain, while the generated climate owns color and
	// mesh normals own landform. A satellite photo containing other mountains
	// must not draw nonexistent ridges over this planet's actual geometry.
	vec3 biome_hue = vertex_tint / max(dot(vertex_tint, vec3(0.28, 0.57, 0.15)), 0.05);
	vec3 ground_map = procedural_ground;
	vec3 procedural_forest = mix(vec3(0.055,0.105,0.070), vec3(0.155,0.205,0.125), biome_patch * 0.62 + regional * 0.38);
	vec3 forest_map = procedural_forest;
	float semiarid_weight=1.0-smoothstep(0.24,0.52,precipitation);
	// A dedicated 40 km orthophoto supplies the drainage and mineral structure
	// that a metre-scale ground tile correctly loses to mipmapping at altitude.
	// Its two rotated samples replace four inappropriate local samples in the
	// regional-only view and disappear before close inspection.
	float regional_photo_detail=regional_detail*(1.0-smoothstep(0.35,0.85,local_detail));
	if (regional_photo_detail>0.0) {
		vec3 regional_photo=mix(texture(regional_ground_albedo,regional_ground_uv).rgb,
			texture(regional_ground_albedo,regional_ground_uv_rotated).rgb,0.18);
		float regional_luma=dot(regional_photo,vec3(0.28,0.57,0.15));
		// Preserve the orthophoto's resolved escarpments, drainage fans and cover
		// boundaries instead of reducing them to a faint grey wash. This is an
		// albedo cue only; the actual normal and height still come from this world.
		// Calmer toward chart zoom, where its mottling only made the sheet busy.
		float regional_tone=clamp(1.0+(regional_luma/0.49-1.0)*mix(1.68,0.95,smoothstep(0.012,0.06,pixel_world)),0.50,1.50);
		ground_map*=mix(1.0,regional_tone,regional_photo_detail*0.96);
		forest_map*=mix(1.0,regional_tone,regional_photo_detail*0.72);
		// Retain a little source chroma so mineral ground, dry cover and darker
		// vegetation separate as they do in satellite imagery. Tight clamps and a
		// low weight keep the simulated climate in control of the biome colour.
		vec3 regional_chroma=clamp(regional_photo/max(regional_luma,0.08),vec3(0.82),vec3(1.18));
		ground_map*=mix(vec3(1.0),regional_chroma,regional_photo_detail*0.20);
	}
	// Sampling an unresolved local layer only burns texture bandwidth and lets
	// mip-averaged tiles muddy the regional and continental image.
	if (local_detail>0.0) {
		vec3 local_ground_a;
		vec3 local_ground_b;
		if (semiarid_weight>0.98) {
			local_ground_a=texture(semiarid_ground_albedo,local_ground_uv).rgb;
			local_ground_b=texture(semiarid_ground_albedo,local_ground_uv_rotated).rgb;
		} else if (semiarid_weight<0.02) {
			local_ground_a=texture(ground_albedo,local_ground_uv).rgb;
			local_ground_b=texture(ground_albedo,local_ground_uv_rotated).rgb;
		} else {
			local_ground_a=mix(texture(ground_albedo,local_ground_uv).rgb,texture(semiarid_ground_albedo,local_ground_uv).rgb,semiarid_weight);
			local_ground_b=mix(texture(ground_albedo,local_ground_uv_rotated).rgb,texture(semiarid_ground_albedo,local_ground_uv_rotated).rgb,semiarid_weight);
		}
		ground_map = mix(ground_map, mix(local_ground_a, local_ground_b, 0.22), local_detail*0.72);
		vec3 local_forest_a = texture(forest_albedo, local_forest_uv).rgb;
		vec3 local_forest_b = texture(forest_albedo, local_forest_uv_rotated).rgb;
		forest_map = mix(forest_map, mix(local_forest_a, local_forest_b, 0.18), local_detail*0.76);
	}
	vec3 ground_close = ground_map;
	// The existing tile contains dozens of crowns across its width. A 500 m
	// repeat puts them at roughly 10–20 m, visible from 10,000 ft. The former
	// 20 m repeat shrank entire forests into grain while the 4 km layer looked
	// like giant color clouds. Keep one crown scale as the camera approaches;
	// mipmaps and the physical pixel footprint resolve it into distant cover.
	float crown_detail = 1.0-smoothstep(0.003,0.014,pixel_world);
	vec3 forest_crowns = forest_map;
	if (max(close_detail,crown_detail)>0.0) {
		vec3 close_a;
		vec3 close_b;
		// This source covers a scrubland neighbourhood, not a grass surface.
		// A 500 m footprint preserves shrubs and washes which the 15 m tile lost.
		vec2 scrub_warp=(vec2(soil_patch,regional)-vec2(0.5))*0.27;
		vec2 scrub_uv=periodic_surface_uv(surface_position,surface_origin,2,1,false,vec2(0.0))+scrub_warp;
		vec2 scrub_uv_rotated=periodic_surface_uv(surface_position,surface_origin,166,100,true,vec2(0.19,-0.27))+vec2(-scrub_warp.y,scrub_warp.x)*0.71;
		if (semiarid_weight>0.98) {
			close_a=texture(semiarid_ground_albedo,scrub_uv).rgb;
			close_b=texture(semiarid_ground_albedo,scrub_uv_rotated).rgb;
		} else if (semiarid_weight<0.02) {
			close_a=texture(ground_albedo,close_uv).rgb;
			close_b=texture(ground_albedo,close_uv_rotated).rgb;
		} else {
			close_a=mix(texture(ground_albedo,close_uv).rgb,texture(semiarid_ground_albedo,scrub_uv).rgb,semiarid_weight);
			close_b=mix(texture(ground_albedo,close_uv_rotated).rgb,texture(semiarid_ground_albedo,scrub_uv_rotated).rgb,semiarid_weight);
		}
		ground_close=mix(close_a,close_b,0.32);
		// Bend both photograph coordinates with broad, already-computed world
		// fields. Repetition no longer lands at the same phase every 500 m, yet the
		// warp remains continuous across tile edges and costs no extra texture read.
		vec2 canopy_warp=(vec2(soil_patch,regional)-vec2(0.5))*0.34;
		vec2 crown_uv_a=periodic_surface_uv(surface_position,surface_origin,2,1,false,vec2(0.0))+canopy_warp;
		vec2 crown_uv_b=periodic_surface_uv(surface_position,surface_origin,158,100,true,vec2(0.1216,-0.1728))+vec2(-canopy_warp.y,canopy_warp.x)*0.71;
		vec3 crown_photo_a=texture(forest_albedo,crown_uv_a).rgb;
		vec3 crown_photo_b=texture(forest_albedo,crown_uv_b).rgb;
		forest_crowns=mix(crown_photo_a,crown_photo_b,0.20);
	}
	// Scrub crowns resolve at the same aerial footprint as woodland crowns.
	// Waiting for the metre-scale grass threshold hid this layer at 10,000 ft.
	float ground_neighbourhood_weight=mix(close_detail*0.66,crown_detail*0.80,semiarid_weight);
	vec3 ground_sample = mix(ground_map, ground_close, ground_neighbourhood_weight);
	vec3 forest_sample = mix(forest_map, forest_crowns, crown_detail * 0.90);
	float photo_resolved=max(local_detail,close_detail);
	float raw_ground_luma = dot(ground_sample, vec3(0.28, 0.57, 0.15));
	float photo_pivot=mix(0.31,0.41,semiarid_weight);
	float photo_contrast=mix(1.0,mix(1.28,1.50,semiarid_weight),photo_resolved);
	float ground_luma=clamp(photo_pivot+(raw_ground_luma-photo_pivot)*photo_contrast,0.04,0.92);
	ground_sample*=ground_luma/max(raw_ground_luma,0.04);
	float forest_luma = dot(forest_sample, vec3(0.28, 0.57, 0.15));
	// Texture supplies light/dark detail; the surveyed biome supplies the hue.
	// Tint multiplication alone left green photographs green in dry climates.
	// Both tiles are physically grounded aerial photographs. Preserve their
	// within-biome colour variation when the camera can resolve it; the previous
	// tint pass discarded most scrub, bare-soil and moisture contrast and turned
	// an information-rich orthophoto into a nearly uniform beige/green sheet.
	// Climate still chooses the source and owns the broad hue, so this cannot make
	// wet grass into desert or dry scrub into woodland.
	float native_ground_colour=mix(0.08,mix(0.24,0.70,semiarid_weight),photo_resolved);
	vec3 ground_surface = mix(vec3(ground_luma) * biome_hue, ground_sample, native_ground_colour);
	ground_surface = mix(vertex_tint * 0.70, ground_surface, mix(0.79,0.91,photo_resolved));
	vec3 forest_surface = mix(vec3(forest_luma), forest_sample, 0.76);
	forest_surface = mix(vec3(0.058, 0.108, 0.069), forest_surface, 0.77);
	// Preserve the light crown tops and shaded gaps that distinguish canopy
	// from grass. The biome blend otherwise fills those gaps with flat green.
	// Linear-space aerial forest values are dark by design. The former x38 lift
	// drove almost every resolved texel into its 2.0 ceiling, turning woodland
	// into luminous green carpet and erasing the photographic canopy hierarchy.
	float crown_light = clamp(0.62+dot(forest_crowns,vec3(0.28,0.57,0.15))*13.0,0.58,1.38);
	forest_surface *= mix(1.0,crown_light,crown_detail);
	// Alpha carries woodland density from the same biome samples used by
	// resource access and inspection. Green grass no longer implies forest.
	float filtered_woodland=clamp(surface_color.a,0.0,1.0);
	if (woodland_channel && surface_uv.x>=0.999) {
		// surface_color.a contains exact sub-kilometre woodland density. A continental
		// mesh samples it every ~20 km, where those values alias into a vertex
		// lattice. Reconstruct the climate-owned mean until that field resolves.
		filtered_woodland=mix(climate_woodland_mean,filtered_woodland,country_detail);
	}
	// Across a streamed patch's outer margin its woodland eases to the planet
	// layer's value beside it, so no wood ends in a straight line at the seam.
	if (!far_layer && patch_feather.w>0.5 && coast_mask_ready()) {
		float wb_seam=smoothstep(0.60,0.82,coast_patch_edge(world_position.xz,patch_feather));
		if (wb_seam>0.0) {
			vec4 wb_far_color=surface_color; vec2 wb_far_uv=surface_uv; vec2 wb_far_uv2=surface_uv2;
			coast_far_surface(world_position.xz,wb_far_color,wb_far_uv,wb_far_uv2);
			filtered_woodland=mix(filtered_woodland,clamp(wb_far_color.a,0.0,1.0),wb_seam);
		}
	}
	float forest_mask=woodland_channel?filtered_woodland:smoothstep(0.025,0.105,surface_color.g-max(surface_color.r,surface_color.b*0.82));
	forest_mask*=1.0-smoothstep(0.42,0.82,slope);
	// surface_color.a is the authoritative woodland density. Resolve that density into
	// irregular stands instead of rendering it as one airbrushed green wash.
	// Zero density remains zero, while dense forest retains connected mass.
	float stand_pattern=smoothstep(0.31,0.69,regional*0.62+soil_patch*0.38);
	forest_mask*=mix(1.0,mix(0.58,1.22,stand_pattern),country_detail);
	// Satellite-scale cover has recognizable stand boundaries rather than a
	// kilometre-wide translucent green wash. Reconstruct a firmer visual edge
	// from the same authoritative continuous density, fading the treatment back
	// out where close photography and physical crowns resolve individual cover.
	float forest_stand_edge=smoothstep(0.18,0.72,forest_mask);
	float forest_edge_weight=country_detail*(1.0-close_detail*0.68)*0.56;
	forest_mask=mix(forest_mask,forest_stand_edge,forest_edge_weight);
	float retained_woodland=woodland_retained(world_position.xz);
	forest_mask*=retained_woodland;
	float crown_shade=0.5;
	if (local_detail>0.0) {
		crown_shade=precise_surface_noise(surface_position,surface_origin,90,1,vec2(0.0));
	}
	forest_surface*=mix(1.0,0.86+crown_shade*0.25,local_detail);
	// On the chart scale woodland is a muted green wash, not near-black stains.
	// From the regional view outward the land is drawn as a chart: even washes
	// of colour with relief shading, not photographic cloud mottling.
	float chart_scale=smoothstep(0.02,0.30,pixel_world);
	forest_surface=mix(forest_surface,vec3(0.18,0.22,0.12),smoothstep(0.01,0.20,pixel_world)*0.70);
	vec3 earth = mix(ground_surface, forest_surface, clamp(forest_mask, 0.0, 0.96));
	earth = mix(earth, vertex_tint, mix(0.30, 0.10, max(regional_detail,local_detail)));
	float climate_green=smoothstep(-0.018,0.065,surface_color.g-surface_color.r);
	// Seeded intermittent swales bridge the visual scale between a continental
	// river and local soil mottling. Once one pixel covers their entire riparian
	// shoulder, evaluating four trigonometric meanders only produces striped
	// aliasing. Fade the physical-width feature before that point and skip its
	// construction entirely at regional and continental satellite scales.
	float drainage_resolved=1.0-smoothstep(0.025,0.11,pixel_world);
	if (drainage_resolved>0.0) {
		float drainage_spacing=2.40;
		float drainage_offset=(drainage_phase-0.5)*drainage_spacing;
		float drainage_index=floor((world_position.x-drainage_offset)/drainage_spacing+0.5);
		float drainage_x=drainage_index*drainage_spacing+drainage_offset;
		drainage_x+=sin(world_position.z*1.34+drainage_index*2.17+drainage_phase*6.2831853)*0.22;
		drainage_x+=sin(world_position.z*3.71-drainage_index*0.83+drainage_phase*17.0)*0.055;
		float drainage_raw=0.50+sin(world_position.z*1.11+drainage_index*1.73+drainage_phase*31.0)*0.31+sin(world_position.z*0.37-drainage_index*2.41+drainage_phase*67.0)*0.19;
		float drainage_active=smoothstep(0.29,0.72,drainage_raw);
		float drainage_distance=abs(world_position.x-drainage_x)+mix(0.075,0.0,drainage_active);
		float riparian=(1.0-smoothstep(0.025,0.115,drainage_distance))*drainage_active*drainage_resolved;
		float swale_floor=(1.0-smoothstep(0.006,0.026,drainage_distance))*drainage_active*drainage_resolved;
		earth=mix(earth,vec3(0.17,0.275,0.155),riparian*(0.06+climate_green*(0.14+local_detail*0.12)));
		earth=mix(earth,vec3(0.225,0.245,0.165),swale_floor*climate_green*(0.20+close_detail*0.16));
		// In dry country the same drainage network reads as pale alluvium, darker
		// incised floors, and sparse greener shoulders—not invisible green rivers.
		float dry_climate=1.0-climate_green;
		earth=mix(earth,vec3(0.39,0.335,0.225),riparian*dry_climate*(0.10+local_detail*0.08));
		earth=mix(earth,vec3(0.30,0.265,0.19),swale_floor*dry_climate*close_detail*0.06);
	}
	float open_meadow = smoothstep(0.58,0.78,soil_patch) * (1.0-forest_mask) * (1.0-close_detail*0.45);
	float dryland_mass = smoothstep(0.60,0.80,organic_noise(world_position.xz*0.022+vec2(61.0,-47.0))) * (1.0-forest_mask);
	earth = mix(earth, vec3(0.34,0.37,0.205), open_meadow*0.30*climate_green);
	earth = mix(earth, vec3(0.43,0.37,0.235), dryland_mass*0.26);
	// These terms have exactly zero weight once their scale is unresolved.
	if (close_detail>0.0) {
	float dry_patch = smoothstep(0.63, 0.84, precise_surface_noise(surface_position,surface_origin,17,10,vec2(-31.0,22.0))) * close_detail;
	float worn_patch = smoothstep(0.70, 0.91, precise_surface_noise(surface_position,surface_origin,75,10,vec2(8.0,-14.0))) * close_detail;
	earth = mix(earth, vec3(0.36, 0.315, 0.21), dry_patch * 0.28);
	earth = mix(earth, vec3(0.25, 0.245, 0.18), worn_patch * 0.12);
	// At settlement scale introduce coherent tens-of-metres aerial variation.
	// This is the missing layer between a regional satellite image and centimetre
	// grass grain: exposed soil, moisture pockets and irregular open ground.
	float close_soil_mass = smoothstep(0.43,0.72,organic_noise(world_position.xz*46.0+vec2(-53.0,19.0))) * close_detail * (1.0-forest_mask);
	float close_lush_mass = smoothstep(0.47,0.75,organic_noise(world_position.xz*32.0+vec2(37.0,-61.0))) * close_detail * (1.0-slope);
	float close_clearings = smoothstep(0.62,0.86,organic_noise(world_position.xz*70.0+vec2(11.0,47.0))) * close_detail * (1.0-forest_mask);
	earth = mix(earth,vec3(0.39,0.335,0.225),close_soil_mass*0.43);
	earth = mix(earth,vec3(0.19,0.285,0.145),close_lush_mass*0.27*climate_green);
	earth = mix(earth,vec3(0.31,0.295,0.205),close_clearings*0.16);
	}
	float modulation = 0.94 + ((broad - 0.5) * 0.11 + (regional - 0.5) * 0.06*country_detail)*(1.0-chart_scale*0.6);
	earth *= modulation;
	// Reused regional fields provide a cheap aerial-photo contrast hierarchy:
	// broad climate still owns the colour, while soil/cover boundaries remain
	// legible instead of dissolving into uniformly soft brown or green blobs.
	float cover_structure=smoothstep(0.30,0.72,regional*0.58+soil_patch*0.42);
	float structure_contrast=(cover_structure-0.5)*0.24*max(country_detail,max(regional_detail,local_detail))*(1.0-chart_scale*0.6);
	earth*=1.0+structure_contrast;
	vec3 exposed_rock = mix(vec3(0.25,0.245,0.225), vertex_tint * 0.78, 0.35);
	if (surface_uv.x>=0.999) { exposed_rock=geological_rock(surface_position,surface_origin,world_position.y,pixel_world,surface_uv2); }
	// Rock exposure follows steepness, including low coastal cliffs. The old
	// altitude multiplier disguised steep lowland faces as grassy ground.
	// Crags on genuinely steep faces, broken into outcrops rather than a
	// smooth pale smear along every ridge line.
	float rock_mask = smoothstep(0.22,0.55,slope+(soil_patch-0.5)*0.16+(broad-0.5)*0.10);
	earth = apply_climate_surface(earth,surface_position,surface_origin,pixel_world,forest_mask,vec4(surface_uv,surface_uv2));
	// Repaint with the biome palette (world_beauty.gdshaderinc): the detail
	// above stays, its hue comes from the climate.
	float wb_warmth=surface_uv.x>=0.999?surface_uv.y:0.55;
	// Local relief against the broad land (the macro height raster): hollows
	// hold water and stay lush, crests and knolls dry to straw. Also shades
	// the valleys below. Fades out once a pixel spans kilometres.
	float wb_hollow=0.0;
	if (coast_mask_ready() && world_position.y>0.0) {
		wb_hollow=(coast_mask_height(world_position.xz)-world_position.y)*(1.0-smoothstep(0.35,2.5,pixel_world));
	}
	float wb_topo_wet=smoothstep(0.0,0.10,wb_hollow)-smoothstep(0.0,0.12,-wb_hollow)*0.6;
	float wb_rain=clamp(precipitation+wb_topo_wet*0.16,0.0,1.0);
	float wb_dry=1.0-smoothstep(0.26,0.50,wb_rain);
	float wb_reference=mix(mix(0.180,0.250,wb_dry),0.085,clamp(forest_mask,0.0,1.0));
	// Open ground under thin woodland is only a little darker and greener:
	// the trees themselves are painted by wb_woodland where stands grow.
	// (Painting all woodland density as wood colour left dark stains.)
	vec3 wb_palette=wb_biome_palette(wb_rain,wb_warmth,forest_mask*0.45,world_position.y,smoothstep(0.25,0.75,biome_patch*0.55+soil_patch*0.45));
	earth = wb_paint(earth,wb_palette,wb_reference,0.85);
	earth = wb_brushwork(earth,wb_brush(world_position.xz,CAMERA_POSITION_WORLD.y),1.0);
	// Woodland as stands of crowns (world_beauty.gdshaderinc), from the same
	// woodland density and clearing as resource access. The stand edge facing
	// the low sun catches warm light; the far edge falls into shade that
	// spills a little onto the open ground beside it.
	float wb_wood_density=clamp(filtered_woodland,0.0,1.0)*retained_woodland*(1.0-smoothstep(0.42,0.82,slope));
	// A lived-in place stands in its own clearing: the settlement's painted
	// ground (settlement_ground.gdshaderinc) opens the painted wood round it.
	vec2 sg_local;
	int sg_slot=settlement_ground_slot(surface_position,surface_origin,sg_local);
	wb_wood_density*=1.0-settlement_clearing(sg_slot,sg_local,pixel_world*1000.0);
	// The worked land round each place (codex/beauty-5) is cleared of wood.
	float sg_orchard=0.0;
	vec4 sg_halo=settlement_halo(surface_position,surface_origin,pixel_world*1000.0,sg_orchard);
	wb_wood_density*=1.0-sg_halo.w*0.85;
	// A natural margin (round two): the edge wanders on screen-sized noise, a
	// fringe of scrub stands outside it, trees stop short of the tide line,
	// and a pale strand runs along the shore.
	float wb_rag=wb_ragged(world_position.xz,pixel_world);
	// Horizontal distance (km) inland from the waterline, from the height's
	// own screen-space rate: a steep shore is a few metres, a flat one wide.
	// The rate is floored at a gentle 3% grade: on flat, low ground the
	// per-quad rate is noise, and its steps would print the mesh grid.
	float wb_shore_km=coast_height/max(coast_height_px/max(pixel_world,0.0000001),0.03);
	wb_wood_density*=smoothstep(0.00005,0.0005,coast_height+wb_rag*0.0004);
	vec2 wb_edge=wb_stand_edge(wb_wood_density,regional,soil_patch,wb_rag,pixel_world);
	float wb_stand_cover=wb_edge.x*(1.0-rock_mask*0.8);
	vec3 wb_wood_colour=wb_biome_palette(wb_rain,wb_warmth,1.0,world_position.y,0.5);
	earth = wb_strand(earth,wb_shore_km,wb_rag,pixel_world);
	earth = wb_fringe(earth,wb_edge.y*(1.0-rock_mask),wb_wood_colour,world_position.xz,pixel_world);
	earth = wb_woodland(earth,wb_stand_cover,wb_wood_colour,world_position.xz,pixel_world);
	earth = wb_canopy_edges(earth,wb_stand_cover,relative_position.xz,pixel_world);
	// Close meadow, then the worn ground of the settlement under the camera
	// (settlement_ground.gdshaderinc, scripts/settlement_grounds.gd).
	earth = settlement_meadow(earth,surface_position,surface_origin,pixel_world*1000.0,(1.0-wb_stand_cover)*(1.0-rock_mask),wb_palette);
	earth = settlement_halo_paint(earth,sg_halo,sg_orchard,surface_position,pixel_world*1000.0,(1.0-wb_stand_cover)*(1.0-rock_mask));
	float sg_trodden=0.0;
	earth = settlement_fields_paint(earth,sg_slot,sg_local,pixel_world*1000.0);
	earth = settlement_ground_paint(earth,sg_slot,sg_local,pixel_world*1000.0,sg_trodden);
	// Gusts rolling through the grass, a fainter shimmer over the canopy.
	float wb_gust=wb_wind_waves(world_position.xz,pixel_world,map_wind,map_wind_clock,wb_motion);
	earth*=1.0+wb_gust*mix(0.038,0.020,wb_stand_cover);
	earth=mix(earth,earth*vec3(1.05,1.05,0.96),max(wb_gust,0.0)*(1.0-wb_stand_cover)*0.5);
	earth = mix(earth, exposed_rock, rock_mask * 0.78);
	// Resource mode reads as land cover, without floating pins or rings.
	earth=mix(earth,earth*vec3(0.72,1.24,0.80),land_resources*forest_mask*0.70);
	earth=mix(earth,vec3(0.43,0.405,0.35),land_resources*rock_mask*0.46);
	float productive_open=(1.0-forest_mask)*(1.0-rock_mask)*smoothstep(0.0,0.04,surface_color.g-surface_color.r);
	earth=mix(earth,earth*vec3(1.18,1.08,0.76),land_resources*productive_open*0.40);
	float highland = smoothstep(5.8, 12.0, world_position.y) * (0.35 + slope * 0.65);
	earth = mix(earth, vec3(0.40,0.39,0.36), highland * 0.36);
	// Snow and hard frost sit above the final soil/rock material. Their extent is
	// governed by the same temperature, rainfall and calendar used by the game,
	// with existing regional fields breaking up the edge like satellite imagery.
	if (surface_uv.x>=0.999 && world_position.y>0.0) {
		float cryosphere_pattern=regional*0.62+soil_patch*0.38;
		vec3 sg_unfrozen=earth;
		earth=seasonal_terrain(earth,surface_uv.y,surface_uv.x-1.0,seasonal_amplitude,world_position.z,forest_mask,slope,cryosphere_pattern);
		// Fresh snow from the weather sky lies wherever the ground is cold
		// enough today, heaviest on sheltered open ground.
		if (weather_snow>0.0) {
			float wb_ground_c=landscape_temperature(surface_uv.y,seasonal_amplitude,world_position.z);
			float wb_fresh=weather_snow*(1.0-smoothstep(2.0,7.0,wb_ground_c))*(1.0-smoothstep(0.25,0.62,slope))
				*smoothstep(0.25,0.60,cryosphere_pattern*0.6+0.4);
			earth=mix(earth,vec3(0.86,0.88,0.90),clamp(wb_fresh*mix(0.85,0.45,wb_stand_cover),0.0,0.9));
		}
		// Trodden paths stay open through snow and frost (settlement_ground).
		earth=settlement_winter_paths(sg_unfrozen,earth,sg_trodden,sg_local,pixel_world*1000.0);
	}
	// A fixed north-west sun gives the orthographic world the same readable relief
	// cues as satellite hillshade. Keep the effect restrained at close range where
	// the scene lights and metre-scale texture already carry the form.
	// At chart zoom the light follows the broad landform (the macro height
	// raster) more than the mesh's small wrinkles: hills and valleys keep
	// their form, the sheet stops crawling (world_beauty wb_macro_normal).
	vec3 wb_light_normal=normalize(world_normal);
	float wb_calm=0.0;
	if (coast_mask_ready()) {
		wb_calm=smoothstep(0.008,0.06,pixel_world)*0.78;
		if (wb_calm>0.0) {
			float wb_step=max(coast_grid1.z>0.0?coast_grid1.z:coast_grid0.z,pixel_world*18.0);
			wb_light_normal=normalize(mix(wb_light_normal,wb_macro_normal(world_position.xz,wb_step),wb_calm));
		}
	}
	// Toward the chart the painting's light settles onto the chart's own
	// generalised landform, so no mesh facet shows through the crossfade.
	if (mc_w>0.0) { wb_calm=max(wb_calm,0.001); wb_light_normal=normalize(mix(wb_light_normal,mc_normal,smoothstep(0.0,0.6,mc_w))); }
	float hill_light = dot(wb_light_normal, normalize(vec3(-0.46, 0.78, -0.42)));
	vec3 horizontal_sun = normalize(vec3(-0.46, 0.0, -0.42));
	float directional_slope = dot(wb_light_normal, horizontal_sun);
	float hillshade = clamp(1.0 + directional_slope * 2.80 - slope * 0.12, 0.74, 1.20);
	// The scene sun already shades resolvable terrain. Applying this cartographic
	// hillshade at the same time doubled broad shadows into soft dark blobs at the
	// 50,000-foot tier. Fade the map-only cue in once pixels cover country-scale
	// ground, where geometric lighting alone no longer communicates the relief.
	// Begin the cartographic cue at regional satellite scale, where smoothed mesh
	// lighting alone makes mountains read like broad stains in oblique views. It
	// remains exactly absent at settlement scale and reaches the existing full
	// strength only once individual landforms are genuinely unresolved.
	// The regional view (tens of metres per pixel) needs it too: without it
	// the valley reads as soft green blotches with no landform at all.
	float map_relief = smoothstep(0.008,0.16,pixel_world);
	earth *= mix(1.0, hillshade, map_relief * 0.90);
	// Painted light at every zoom (world_beauty.gdshaderinc): the sunward
	// side of each slope warms, the far side takes the cool sky, and ground
	// lying below the broad land around it (valleys, river bottoms) is shaded.
	float wb_valley=smoothstep(0.004,0.14,wb_hollow)*0.35;
	earth = wb_light(earth,directional_slope*4.5,wb_valley,mix(0.62,0.32,map_relief));
	// Actual elevation remains meaningful after fine texture has filtered away.
	// A broad, non-banded upland exposure separates low basins, plateaus and the
	// alpine shoulder in regional/continental imagery. It is exactly absent from
	// close inspection and never changes the terrain height or simulated biome.
	float mapped_upland=smoothstep(0.65,5.60,world_position.y)*map_relief;
	float mapped_alpine=smoothstep(3.20,8.20,world_position.y)*map_relief;
	vec3 upland_surface=mix(earth*vec3(1.10,1.03,0.84),vec3(0.42,0.41,0.38),mapped_alpine);
	earth=mix(earth,upland_surface,mapped_upland*0.36);
	float ridge_glint = smoothstep(0.12, 0.62, slope) * smoothstep(0.25, 0.82, hill_light) * map_relief;
	earth = mix(earth, vec3(0.48,0.46,0.40), ridge_glint * 0.10);
	// Close aerial imagery needs a different exposure than the shaded regional
	// relief map. Without this lift the settlement-scale ground fell nearly black.
	earth *= mix(1.0, 1.16, close_detail);
	earth = mix(earth, max(earth, vec3(0.105,0.112,0.072)), close_detail * 0.72);
	// Thin aerial perspective replaces expensive volumetric fog. At country and
	// continental footprints it gently compresses saturation like a real column
	// of atmosphere; oblique rays accumulate a little more haze than nadir rays.
	// Grade to the map palette first, then haze toward parchment: mild at
	// valley height, stronger at regional and continental footprints, and a
	// little more along oblique rays, like the margin of a painted map.
	// Engraved contours over the painted relief at chart zoom.
	float wb_contour=wb_contours(world_position.y,height_px,pixel_world)*smoothstep(0.012,0.05,pixel_world);
	earth=mix(earth,MAP_SEPIA*1.15,wb_contour*0.20);
	earth=wb_grade(earth);
	// Cloud shadows lie on the land itself, following its relief.
	earth*=map_cloud_shadow(world_position.xz,world_position.y,map_cloud,map_cloud_scale);
	// Log-scaled with footprint: none at the camp, a veil at 50,000 ft, and
	// most of the way to parchment by the continental view.
	float altitude_haze=clamp(log(max(pixel_world,0.004)/0.004)/log(250.0),0.0,1.0)*0.36;
	float view_slant=length(relative_position.xz)/max(abs(relative_position.y),0.001);
	float slant_haze=smoothstep(0.15,1.2,view_slant)*smoothstep(0.002,0.35,pixel_world);
	float atmospheric_weight=clamp(altitude_haze*0.62+slant_haze*0.14,0.0,0.30);
	earth=wb_air(earth,atmospheric_weight);
	// Unexplored land and water share one unlit veil. Normals must not reveal
	// unseen mountain ranges or coastlines as geometric detail improves.
	// The coast is inked, one to two pixels wide, where the ground rises out
	// of the sea: the smooth shared shoreline over the regional patch, this
	// surface's own triangles elsewhere (streamed patches only: the planet mesh
	// takes its shoreline from the macro raster instead).
	if (!far_layer) {
		float shore_px=coast_height/max(coast_height_px,0.0000001);
		float coast_ink=(1.0-smoothstep(0.9,1.9,shore_px))*step(0.0,coast_height);
		earth=mix(earth,MAP_INK*1.4,coast_ink*smoothstep(0.004,0.04,pixel_world)*0.75);
	}
	earth = wb_frontier_wash(earth,wb_frontier_px,world_position.xz,pixel_world,smoothstep(0.015,0.20,pixel_world));
	ALBEDO = earth*reveal;
	EMISSION = unknown_ground*(1.0-reveal);
	// Sky fill (round two): slopes turned from the low sun keep a cool share
	// of their colour, so shade reads as shade and never as a dark blot.
	EMISSION += earth*reveal*wb_sky_fill(wb_light_normal);
	ROUGHNESS = 0.96;
	if (wb_calm>0.0) { NORMAL = normalize((VIEW_MATRIX*vec4(wb_light_normal,0.0)).xyz); }
	// The painting gives way to its chart as the view widens.
	if (mc_w>0.0) {
		ALBEDO *= 1.0-mc_w;
		EMISSION = mix(EMISSION,mc_ground*reveal+unknown_ground*(1.0-reveal),mc_w);
	}
	}
}
"""
	shader.code=shader.code.replace("varying vec3 world_position;",LANDSCAPE_VISUALS.CUTTING_SHADER+"\nvarying vec3 world_position;")
	var material := ShaderMaterial.new()
	material.shader = shader
	_register_woodland_material(material)
	var ground_texture: Texture2D = load("res://assets/terrain/temperate_ground_albedo_v1.png")
	var forest_texture: Texture2D = load("res://assets/terrain/temperate_forest_albedo_v1.png")
	var semiarid_texture: Texture2D = load("res://assets/terrain/semiarid_ground_albedo_v1.png")
	var regional_ground_texture: Texture2D = load("res://assets/terrain/regional_ground_albedo_v1.png")
	material.set_shader_parameter("ground_albedo",ground_texture)
	material.set_shader_parameter("forest_albedo",forest_texture)
	material.set_shader_parameter("semiarid_ground_albedo",semiarid_texture)
	material.set_shader_parameter("regional_ground_albedo",regional_ground_texture)
	material.set_shader_parameter("land_resources",1.0 if resource_view_enabled else 0.0)
	material.set_shader_parameter("woodland_channel",SEAMLESS_WORLD)
	material.set_shader_parameter("drainage_phase",float(posmod(GameState.world_seed,10007))/10007.0)
	_fog_shader_parameters(material)
	_register_seasonal_material(material)
	return material

func _add_terrain_vertex(surface: SurfaceTool, grid_x: int, grid_z: int) -> void:
	var x := (float(grid_x) / (self.grid_x - 1) - 0.5) * world_width
	var z := (float(grid_z) / (self.grid_z - 1) - 0.5) * world_depth
	var height := _height_at(x, z)
	surface.set_custom_format(0,SurfaceTool.CUSTOM_R_FLOAT)
	surface.set_custom(0,Color(_terrain_seasonality_at(x,z,height),0,0,0))
	surface.set_color(_terrain_color_at(x, z, height))
	var fields:=_terrain_surface_fields_at(x,z,height)
	surface.set_uv(Vector2(fields.x,fields.y))
	surface.set_uv2(Vector2(fields.z,fields.w))
	surface.add_vertex(Vector3(x, height, z))

func _terrain_seasonality_at(x:float,z:float,_height:float)->float:
	return PlanetEnvironment.seasonality_at(Vector2(x,z)) if SEAMLESS_WORLD else 0.0

func _register_seasonal_material(material:ShaderMaterial)->void:
	seasonal_materials.append(weakref(material))
	# The worn ground of the home settlement (settlement_grounds.gd).
	preload("res://scripts/settlement_grounds.gd").bind(material)
	material.set_shader_parameter("season_phase",PlanetEnvironment.season_wave({},GameState.elapsed_days))
	material.set_shader_parameter("weather_snow",seasonal_snow)
	if seasonal_motion>=0.0:material.set_shader_parameter("wb_motion",seasonal_motion)

func _refresh_seasonal_visuals()->void:
	# Reduced motion stills the wind sway and grass waves at once.
	var motion:=0.0 if preload("res://scripts/hud/motion.gd").reduced() else 1.0
	if motion!=seasonal_motion:
		seasonal_motion=motion
		for reference in seasonal_materials:
			var material:=reference.get_ref() as ShaderMaterial
			if material:material.set_shader_parameter("wb_motion",motion)
	# Simulation time only. Pausing freezes the season; no mesh/crown rebuild.
	var day:=GameState.elapsed_days
	if is_finite(last_seasonal_day) and absf(day-last_seasonal_day)<0.1:return
	last_seasonal_day=day
	var phase:=PlanetEnvironment.season_wave({},day)
	# Fresh snow near home from the same sky the map's weather draws.
	var snow:=0.0
	var home:Vector3=GameState.settlement_founded_at if GameState.settlement_site_committed else (settler_marker.position if settler_marker else Vector3.ZERO)
	if SEAMLESS_WORLD and PlanetEnvironment.has_method("profile_at"):
		snow=WORLD_BEAUTY.lying_snow(int(GameState.world_seed),day,PlanetEnvironment.profile_at(Vector2(home.x,home.z)))
	var living:Array[WeakRef]=[]
	for reference in seasonal_materials:
		var material:=reference.get_ref() as ShaderMaterial
		if material==null:continue
		living.append(reference)
		material.set_shader_parameter("season_phase",phase)
		material.set_shader_parameter("weather_snow",snow)
	seasonal_materials=living
	seasonal_snow=snow

func _vegetation_climate(position:Vector3)->Color:
	var biome:=_biome_at(position.x,position.z)
	if not biome.has("temperature"):return Color(0,0,0,0)
	return Color(float(biome.temperature),float(biome.precipitation),_terrain_seasonality_at(position.x,position.z,position.y),0.0)

func _terrain_surface_fields_at(x:float,z:float,height:float)->Vector4:
	if not SEAMLESS_WORLD:return Vector4.ZERO
	# Patch construction asks for colour immediately before these fields. Reuse
	# that exact climate sample: a 513-square refinement previously evaluated the
	# same multi-noise climate twice for every vertex.
	var position:=Vector3(x,height,z)
	var climate:Dictionary
	if position==terrain_visual_sample_position:
		climate=terrain_visual_sample_climate
	else:
		climate=_climate_at(x,z,height)
		terrain_visual_sample_position=position
		terrain_visual_sample_climate=climate
	var geology:=PlanetEnvironment.surface_geology_at(Vector2(x,z),height)
	var total:=maxf(.001,float(geology.sedimentary)+float(geology.igneous)+float(geology.metamorphic))
	# UV.x >= 1 identifies physical samples; custom/legacy meshes with no fields
	# keep their existing appearance. COLOR alpha remains woodland density.
	return Vector4(1.0+clampf(float(climate.precipitation),0,1),clampf(float(climate.temperature),0,1),float(geology.sedimentary)/total,float(geology.igneous)/total)

func _climate_at(x:float,z:float,height:float)->Dictionary:
	## Earth-logic climate: latitude and altitude set temperature; the moisture
	## field, continental interior dryness, and the river corridor's humidity
	## set precipitation. Every biome below EMERGES from these two numbers.
	var latitude_warmth:=1.0-clampf(absf(z)/(world_depth*0.5),0.0,1.0)
	# Adiabatic lapse: high ground is cold ground, at any latitude.
	var temperature:=clampf(latitude_warmth-maxf(0.0,height)*0.055,0.0,1.0)
	# Rainfall has structure at two scales: the continental moisture belt and
	# regional weather country (~30–300 km), so a starting region genuinely
	# contains different lands rather than one endless climate.
	var moisture:=moisture_noise.get_noise_2d(x,z)
	var regional_weather:=terrain_noise.get_noise_2d(x+1700.0,z-2300.0)
	# Deep continental interiors are drier than coasts and basins.
	var interior:=clampf((continent_noise.get_noise_2d(x,z)-0.05)*1.2,0.0,0.5)
	var precipitation:=clampf(0.48+moisture*0.52+regional_weather*0.34-interior*0.55,0.0,1.0)
	# Contrast-stretch so wet and dry country both genuinely occur; a world of
	# nothing but average rainfall is a world of one biome.
	precipitation=clampf(0.5+(precipitation-0.5)*1.9,0.0,1.0)
	var river_x:=_world_river_x(z)
	var river_distance:=absf(x-river_x) if river_x!=INF else INF
	# The river corridor is humid ground regardless of regional climate.
	if river_distance<16.0: precipitation=maxf(precipitation,precipitation+((1.0-river_distance/16.0)*0.28))
	return {"temperature":temperature,"precipitation":clampf(precipitation,0.0,1.0),"river_distance":river_distance}


func site_temperature_c(day:float=-1.0)->float:
	## Same mean/amplitude/hemisphere as food's ambient-temperature model.
	if day<0.0:day=GameState.elapsed_days
	var anchor:Vector3=GameState.settlement_founded_at if GameState.settlement_site_committed else (settler_marker.position if settler_marker else Vector3.ZERO)
	var climate:=_climate_at(anchor.x,anchor.z,_height_at(anchor.x,anchor.z))
	return PlanetEnvironment.ambient_temperature_c({"position":Vector2(anchor.x,anchor.z),"mean_temperature_c":lerpf(-6.0,28.0,float(climate.temperature)),"seasonality_c":_terrain_seasonality_at(anchor.x,anchor.z,anchor.y)},day)


func _biome_at(x:float,z:float,height:float=NAN)->Dictionary:
	## The single authority for what the land IS. Renderer, resource placement,
	## scouting reports, and woodland density all read this one field.
	if is_nan(height): height=_height_at(x,z)
	if height<SEA_LEVEL:
		return {"id":"water","label":"open water","woodland":0.0,"fertility":0.0,"forage":0.0,"game":0.0,"stone":0.0,"color":Color("#21363a")}
	return _biome_from_climate(x,z,height,_climate_at(x,z,height))

func _biome_from_climate(x:float,z:float,height:float,climate:Dictionary)->Dictionary:
	var temperature:=float(climate.temperature)
	var precipitation:=float(climate.precipitation)
	var river_distance:=float(climate.river_distance)
	# Woodland needs both warmth and rain (treeline and aridity limits).
	var woodland:=clampf((precipitation-0.40)*2.6,0.0,1.0)*clampf((temperature-0.16)*3.4,0.0,1.0)
	if height>3.2: woodland*=1.0-clampf((height-3.2)/5.2,0.0,0.74)
	woodland*=0.22+0.78*smoothstep(-0.30,0.30,detail_noise.get_noise_2d(x*1.8+7.0,z*1.8-29.0))
	var id:="grassland"
	var label:="open grassland"
	if temperature<0.16:
		id="tundra"; label="cold barrens"
	elif height>6.0:
		id="upland"; label="bare upland"
	elif river_distance<3.2 and height<3.0:
		id="floodplain"; label="river floodplain"
	elif precipitation>0.70 and height<0.9 and river_distance<18.0:
		id="wetland"; label="wet meadows"
	elif woodland>0.42:
		id="woodland"; label="dense woodland"
	elif precipitation<0.36:
		id="steppe"; label="dry steppe" if temperature<0.62 else "sun-scoured drylands"
	# Earth's soil logic: alluvium and deep grassland soils feed people;
	# forest soils are middling, steppe and thin upland soils are poor.
	var fertility:=0.0
	match id:
		"floodplain": fertility=0.95
		"grassland": fertility=0.55+precipitation*0.25
		"wetland": fertility=0.60
		"woodland": fertility=0.34
		"steppe": fertility=0.14
		_: fertility=0.05
	var forage:=clampf(precipitation*0.6+woodland*0.3+(0.25 if id=="wetland" else 0.0),0.0,1.0)
	var game:=clampf(woodland*(1.6-woodland)+ (0.2 if id in ["grassland","floodplain"] else 0.0),0.0,1.0)
	var stone:=clampf((height/6.0)*(1.0-woodland),0.0,1.0)+(0.3 if id=="upland" else 0.0)
	# Color: continuous blends so biome borders read as transitions, not tiles.
	var color:=Color("#7a6c4c").lerp(Color("#5f6a45"),clampf((precipitation-0.18)*3.2,0.0,1.0))
	var dryness:=1.0-smoothstep(0.30,0.49,precipitation)
	color=color.lerp(Color("#a48a59"),dryness*0.92)
	color=color.lerp(Color("#2c4a34"),woodland*0.9)
	if id=="wetland": color=color.lerp(Color("#3a5348"),0.62)
	if id=="floodplain": color=color.lerp(Color("#33553c"),0.70)
	elif river_distance<14.0: color=color.lerp(Color("#365443"),pow(1.0-river_distance/14.0,1.35)*0.38)
	if precipitation<0.18: color=color.lerp(Color("#8b7550"),0.5)
	if height>3.2: color=color.lerp(Color("#77766f"),clampf((height-3.2)/5.2,0.0,0.74))
	if temperature<0.22: color=color.lerp(Color("#bcbfb1"),clampf((0.22-temperature)*4.5,0.0,0.86))
	return {"id":id,"label":label,"woodland":woodland,"fertility":fertility,"forage":forage,"game":game,"stone":stone,"color":color,"temperature":temperature,"precipitation":precipitation,"river_distance":river_distance}


func _terrain_color_at(x: float, z: float, height: float) -> Color:
	if SEAMLESS_WORLD:
		var biome:Dictionary
		if height<SEA_LEVEL:
			biome=_biome_at(x,z,height)
		else:
			var climate:=_climate_at(x,z,height)
			terrain_visual_sample_position=Vector3(x,height,z)
			terrain_visual_sample_climate=climate
			biome=_biome_from_climate(x,z,height,climate)
		var color:Color=biome.color
		color.a=float(biome.woodland)
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
#include "res://scripts/map_palette.gdshaderinc"
varying vec3 world_position;
void vertex(){ world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
void fragment(){
	vec2 uv=clamp(world_position.xz/fog_world_size+vec2(0.5),vec2(0.0),vec2(1.0));
	float current_visibility=1.0-smoothstep(30.0,38.0,distance(world_position.xz,fog_current_origin));
	float discovered=smoothstep(0.12,0.62,max(texture(discovery_mask,uv).r,current_visibility));
	ALBEDO=COLOR.rgb*discovered;
	EMISSION=MAP_VELLUM*(1.0-discovered);
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
	water.name = "OceanSurface"
	ocean_surface = water
	var plane := PlaneMesh.new()
	plane.size = Vector2(world_width * 4.0, world_depth * 4.0)
	# Planet-spanning triangles lose depth precision over inland valleys in GL.
	# Bounded sections keep water at sea level across regional camera ranges.
	plane.subdivide_width = 255
	plane.subdivide_depth = 255
	water.mesh = plane
	# World units are kilometres: the old +0.012 flooded twelve metres of dry
	# coastal ground. Color/detail must never raise the physical water surface.
	water.position.y = SEA_LEVEL if SEAMLESS_WORLD else -5.28
	var material:=ShaderMaterial.new()
	material.shader=preload("res://scripts/coastal_water.gdshader")
	material.set_shader_parameter("sea_level",water.position.y)
	_fog_shader_parameters(material)
	water.material_override = material
	add_child(water)
	coastal_water_material=material.duplicate() as ShaderMaterial
	coastal_water_material.set_shader_parameter("regional_surface",true)
	_fog_shader_parameters(coastal_water_material)
	_refresh_coastal_water_patch()

func _refresh_coastal_water_patch()->void:
	if ocean_surface==null or river_terrain_height_texture==null: return
	# A local mesh avoids the precision loss from projecting planet-sized ocean
	# triangles into a coastal view. The far surface has a matching cutout.
	if coastal_water_surface==null:
		coastal_water_surface=MeshInstance3D.new()
		coastal_water_surface.name="CoastalWaterLOD"
		coastal_water_surface.material_override=coastal_water_material
		ocean_surface.add_child(coastal_water_surface)
	var plane:=PlaneMesh.new()
	plane.size=Vector2.ONE*regional_patch_span
	plane.subdivide_width=clampi(regional_patch_resolution-2,0,63)
	plane.subdivide_depth=clampi(regional_patch_resolution-2,0,63)
	coastal_water_surface.mesh=plane
	coastal_water_surface.position=Vector3(regional_patch_center.x,0,regional_patch_center.y)
	_bind_river_terrain(coastal_water_material)
	_bind_river_terrain(ocean_surface.material_override)
	SURFACE_PRECISION.configure_water(coastal_water_material,regional_patch_center)
	SURFACE_PRECISION.configure_water(ocean_surface.material_override,regional_patch_center)

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

func _river_width_factor(point:Vector3)->float:
	# World coordinates keep width stable when tessellation changes.
	return clampf(
		0.91
		+sin(point.z*0.17+float(GameState.world_seed%211))*0.10
		+sin(point.z*0.71+point.x*0.11)*0.075
		+sin(point.z*2.30+point.x*0.37)*0.065,
		0.68,1.18)

func _add_river_ribbon(surface: SurfaceTool, points: Array[Vector3], width: float, color: Color, headwater:bool=false, downstream:=PackedFloat32Array(), trunk:=false, scale_role:=0.0) -> void:
	var taper:=preload("res://scripts/river_geometry.gd").headwater_factors(points) if headwater else PackedFloat32Array()
	# CUSTOM0 (format set at begin): how far downstream each point lies, trunk
	# or tributary (the chart ink swells with both), and the scales the reach is
	# drawn at: 0 all, 1 close up only, 2 chart scale only (map_river.gdshader).
	for i in points.size() - 1:
		var a := points[i]
		var b := points[i + 1]
		var before := points[maxi(0,i-1)]
		var after := points[mini(points.size()-1,i+2)]
		var tangent_a := Vector2(b.x-before.x,b.z-before.z).normalized()
		var tangent_b := Vector2(after.x-a.x,after.z-a.z).normalized()
		# Signed local curvature places pale sediment on the inside of bends.
		var incoming:=Vector2(a.x-before.x,a.z-before.z).normalized()
		var outgoing:=Vector2(b.x-a.x,b.z-a.z).normalized()
		var following:=Vector2(after.x-b.x,after.z-b.z).normalized()
		var bend_a:=clampf(incoming.cross(outgoing)/maxf(a.distance_to(before),0.001)*8.0,-1.0,1.0)
		var bend_b:=clampf(outgoing.cross(following)/maxf(b.distance_to(a),0.001)*8.0,-1.0,1.0)
		var width_a:=width*_river_width_factor(a)*(taper[i] if headwater else 1.0)
		var width_b:=width*_river_width_factor(b)*(taper[i+1] if headwater else 1.0)
		var side_a := Vector3(-tangent_a.y,0.0,tangent_a.x)*width_a
		var side_b := Vector3(-tangent_b.y,0.0,tangent_b.x)*width_b
		var corners: Array[Vector3] = [a-side_a,b-side_b,b+side_b,a-side_a,b+side_b,a+side_a]
		var reach_tint:=0.97+sin(a.z*0.08+2.4)*0.025
		# Each corner carries its outward side (NORMAL) and half width (UV.y), so
		# the shader can find the centre line and hold a chart-scale ink width.
		var half_widths:=[width_a,width_b,width_b,width_a,width_b,width_a]
		var outward:=[-side_a,-side_b,side_b,-side_a,side_b,side_a]
		for corner_index in corners.size():
			var point:=corners[corner_index]
			surface.set_normal((outward[corner_index] as Vector3).normalized())
			surface.set_uv(Vector2([0.0,0.0,1.0,0.0,1.0,1.0][corner_index],float(half_widths[corner_index])))
			var endpoint:=i if corner_index in [0,3,5] else i+1
			var source_opacity:=smoothstep(0.12,0.15,taper[endpoint]) if headwater else 1.0
			surface.set_uv2(Vector2(bend_a if corner_index in [0,3,5] else bend_b,source_opacity))
			surface.set_custom(0,Color(downstream[endpoint] if endpoint<downstream.size() else 1.0,1.0 if trunk else 0.0,scale_role,0.0))
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

func _bind_river_terrain(material:ShaderMaterial)->void:
	if river_terrain_height_texture==null: return
	material.set_shader_parameter("terrain_heights",river_terrain_height_texture)
	material.set_shader_parameter("terrain_grid",river_terrain_grid)
	if chart_relief_texture:material.set_shader_parameter("chart_relief",chart_relief_texture)
	material.set_shader_parameter("chart_cover",chart_cover_texture)

func _build_river_network() -> void:
	var banks := SurfaceTool.new()
	var water_surface := SurfaceTool.new()
	# Tributaries at chart scale: a smoothed copy of each course, kept in its own
	# meshes so battle grounds (which copy RiverWater) never see it.
	var chart_banks:=SurfaceTool.new()
	var chart_water:=SurfaceTool.new()
	for river_surface in [banks,water_surface,chart_banks,chart_water]:
		(river_surface as SurfaceTool).begin(Mesh.PRIMITIVE_TRIANGLES)
		(river_surface as SurfaceTool).set_custom_format(0,SurfaceTool.CUSTOM_RGBA_FLOAT)
	var points: Array[Vector3] = []
	if SEAMLESS_WORLD:
		# Sample the authoritative river over its actual 1,520 km reach. Sampling
		# the whole planet first reduced the visible curve to multi-km chords.
		for i in 6081:
			var z:=-760.0+float(i)*0.25
			var x:=_world_river_x(z)
			points.append(Vector3(x,_height_at(x,z),z))
	else:
		for i in 196:
			var current:=_river_point(lerpf(0.025,0.975,float(i)/195.0))
			if current!=Vector3.INF: points.append(current)
	if points.size() >= 2:
		_trace_load("river points=%d from=%s to=%s" % [points.size(),points.front(),points.back()])
		var trunk_flow:=preload("res://scripts/river_geometry.gd").downstream_fractions(points,SEA_LEVEL)
		_add_river_ribbon(banks,points,0.22 if SEAMLESS_WORLD else 1.12,Color(0.15,0.205,0.17,0.64),false,trunk_flow,true)
		_add_river_ribbon(water_surface,points,0.105 if SEAMLESS_WORLD else 0.68,Color(0.055,0.17,0.205,0.92),false,trunk_flow,true)
	if SEAMLESS_WORLD:
		world_tributary_courses = _seeded_world_tributaries()
		for tributary in world_tributary_courses:
			var original_course:Array[Vector3]=tributary
			var tributary_points:=preload("res://scripts/river_geometry.gd").drape_course(original_course,_height_at)
			var gathering:=preload("res://scripts/river_geometry.gd").course_fractions(tributary_points)
			_add_river_ribbon(banks, tributary_points, 0.072, Color(0.14,0.20,0.17,0.58),true,gathering,false,1.0)
			_add_river_ribbon(water_surface, tributary_points, 0.029, Color(0.052,0.155,0.185,0.86),true,gathering,false,1.0)
			# The surveyed course kinks every few kilometres; an ink line at chart
			# scale follows its smoothed line instead (the course itself is unchanged).
			var chart_points:=preload("res://scripts/river_geometry.gd").drape_course(preload("res://scripts/river_geometry.gd").smoothed_course(original_course),_height_at)
			var chart_gathering:=preload("res://scripts/river_geometry.gd").course_fractions(chart_points)
			_add_river_ribbon(chart_banks, chart_points, 0.072, Color(0.14,0.20,0.17,0.58),true,chart_gathering,false,2.0)
			_add_river_ribbon(chart_water, chart_points, 0.029, Color(0.052,0.155,0.185,0.86),true,chart_gathering,false,2.0)
	var river_entries:=[{"mesh": banks.commit(), "name": "RiverBanks", "rough": 1.0}, {"mesh": water_surface.commit(), "name": "RiverWater", "rough": 0.34}]
	if SEAMLESS_WORLD and not world_tributary_courses.is_empty():
		river_entries.append_array([{"mesh": chart_banks.commit(), "name": "TributaryChartBanks", "rough": 1.0}, {"mesh": chart_water.commit(), "name": "TributaryChartWater", "rough": 0.34}])
	for entry in river_entries:
		if entry.mesh == null:
			continue
		var river := MeshInstance3D.new()
		river.name = entry.name
		river.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		river.mesh = entry.mesh
		var material:=ShaderMaterial.new()
		material.shader=preload("res://scripts/map_river.gdshader")
		_bind_river_terrain(material)
		var water_mesh:=String(entry.name).ends_with("Water")
		material.set_shader_parameter("river_water",water_mesh)
		# Chart scale (map_river.gdshader): a 4 px blue-slate ink line that swells
		# downstream, in a soft water tint reaching 6 px beyond it.
		material.set_shader_parameter("chart_half_px",2.0)
		material.set_shader_parameter("chart_tint_px",0.0 if water_mesh else 6.0)
		material.set_shader_parameter("chart_reference_half",0.105 if water_mesh else 0.22)
		material.render_priority=-5 if water_mesh else -6
		_fog_shader_parameters(material)
		material.set_shader_parameter("resource_emphasis",1.0 if resource_view_enabled and water_mesh else 0.0)
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
		var biome:=_biome_at(x,z,height)
		var woodland:=LandscapeCover.canopy_density(biome)
		if woodland<=0.0:continue
		var forest_noise := moisture_noise.get_noise_2d(x,z) if SEAMLESS_WORLD else terrain_noise.get_noise_2d(x * 1.35 + 1300.0, z * 1.35 - 800.0)
		var threshold := -0.03 if SEAMLESS_WORLD else (-0.16 if GameState.province_terrain == "Forest" else 0.03)
		if (not SEAMLESS_WORLD and forest_noise<threshold) or rng.randf()>woodland*.78:
			continue
		var scale := rng.randf_range(0.48, 1.06)
		var basis := Basis().scaled(Vector3(scale * rng.randf_range(0.75, 1.05), scale * rng.randf_range(1.6, 2.45), scale))
		transforms.append(Transform3D(basis, Vector3(x, height + scale * 0.014, z)))
		colors.append(LandscapeCover.canopy_tint(biome,rng.randf()))
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
	multi.use_custom_data = true
	multi.mesh = canopy_mesh
	multi.instance_count = transforms.size()
	for i in transforms.size():
		multi.set_instance_transform(i, transforms[i])
		multi.set_instance_color(i, colors[i])
		multi.set_instance_custom_data(i,_vegetation_climate(transforms[i].origin))
	var forest := MultiMeshInstance3D.new()
	forest.name = "WoodlandCanopy"
	forest.multimesh = multi
	forest.material_override = _vegetation_surface_material(0)
	add_child(forest)

func _survey_ground_at(position:Vector2)->Dictionary:
	## Ground truth handed to the civilization layer so returned scout reports
	## describe the terrain the renderer actually draws at that point. Slope,
	## relief, and coastal adjacency let landmark naming derive from what the
	## ground actually looks like instead of inventing fiction.
	var biome:=_biome_at(position.x,position.y)
	var height:=_height_at(position.x,position.y)
	var sample_km:=0.75
	var steepest:=0.0
	for offset in [Vector2(sample_km,0.0),Vector2(-sample_km,0.0),Vector2(0.0,sample_km),Vector2(0.0,-sample_km)]:
		steepest=maxf(steepest,absf(_height_at(position.x+offset.x,position.y+offset.y)-height))
	# Relief reads basin-vs-crest at valley scale, wider than the slope probe.
	var neighbor_average:=0.0
	for offset in [Vector2(2.5,0.0),Vector2(-2.5,0.0),Vector2(0.0,2.5),Vector2(0.0,-2.5)]:
		neighbor_average+=_height_at(position.x+offset.x,position.y+offset.y)*0.25
	var coastal:=false
	if height>=SEA_LEVEL:
		for offset in [Vector2(3.0,0.0),Vector2(-3.0,0.0),Vector2(0.0,3.0),Vector2(0.0,-3.0)]:
			if _height_at(position.x+offset.x,position.y+offset.y)<SEA_LEVEL:
				coastal=true
				break
	var actual_water_distance:=_river_distance_at(position.x,position.y)*KM_PER_WORLD_UNIT
	return {
		"biome":String(biome.id),
		"label":String(biome.label),
		"woodland":float(biome.woodland),
		"fertility":float(biome.fertility),
		"forage":float(biome.get("forage",0.0)),
		"game":float(biome.get("game",0.0)),
		"stone":float(biome.get("stone",0.0)),
		"river_distance_km":actual_water_distance,
		"height":height,
		"slope":steepest/sample_km,
		"relief":height-neighbor_average,
		"coastal":coastal,
		"temperature":float(biome.get("temperature",0.5)),
		"precipitation":float(biome.get("precipitation",0.5)),
	}


func _register_woodland_material(material:ShaderMaterial)->void:
	woodland_visual_materials.append(weakref(material))
	material.set_shader_parameter("woodland_area_count",woodland_visual_areas.size())
	var padded:=woodland_visual_areas.duplicate()
	padded.resize(LANDSCAPE_VISUALS.MAX_AREAS)
	material.set_shader_parameter("woodland_areas",padded)

func _refresh_woodland_visuals(force:bool=false)->void:
	var key:="%d:%d:%d" % [int(GameState.elapsed_days),floori(camera_target.x/8.0),floori(camera_target.z/8.0)]
	if not force and key==woodland_visual_key:
		_refresh_woodland_harvest_detail(false)
		return
	woodland_visual_key=key
	var ledgers:Array=[GameState.resource_deposits]
	for city in GameState.player_settlements:
		if bool(city.get("primary",false)): continue
		ledgers.append(city.get("local_resources",{}).get("resource_deposits",[]))
	woodland_visual_areas=LANDSCAPE_VISUALS.areas_from_ledgers(ledgers,Vector2(camera_target.x,camera_target.z))
	var padded:=woodland_visual_areas.duplicate()
	padded.resize(LANDSCAPE_VISUALS.MAX_AREAS)
	var living:Array[WeakRef]=[]
	for reference in woodland_visual_materials:
		var material:=reference.get_ref() as ShaderMaterial
		if material==null: continue
		living.append(reference)
		material.set_shader_parameter("woodland_area_count",woodland_visual_areas.size())
		material.set_shader_parameter("woodland_areas",padded)
	woodland_visual_materials=living
	_refresh_woodland_harvest_detail(true)

## The ground as the regional patch draws it (cheap: a lookup in its heights),
## or the planet height beyond it. For draping map ink, not for simulation.
func _rendered_ground_height_at(point:Vector2)->float:
	if not rendered_regional_heights.is_empty() and RENDERED_SURFACE.contains(point,river_terrain_grid):
		return RENDERED_SURFACE.sample(point,river_terrain_grid,func(cell:Vector2i)->float: return rendered_regional_heights[cell.y*int(river_terrain_grid.w)+cell.x])
	return _height_at(point.x,point.y)

func _harvest_ground_height_at(point:Vector2)->float:
	var result:=_height_at(point.x,point.y)
	if RENDERED_SURFACE.contains(point,river_terrain_grid) and not rendered_regional_heights.is_empty():
		result=RENDERED_SURFACE.sample(point,river_terrain_grid,func(cell:Vector2i)->float: return rendered_regional_heights[cell.y*int(river_terrain_grid.w)+cell.x])
	var detail_grid:=Vector4(detail_surface_center.x,detail_surface_center.y,0.42,112.0)
	if detail_terrain_patch and detail_terrain_patch.visible and RENDERED_SURFACE.contains(point,detail_grid):
		var detail_height:=RENDERED_SURFACE.sample(point,detail_grid,func(cell:Vector2i)->float:
			var vertex:=detail_surface_center+(Vector2(cell)/111.0-Vector2(0.5,0.5))*0.42
			return _close_surface_height_at(vertex.x,vertex.y)+0.00045,false)
		result=maxf(result,detail_height)
	return result

func _refresh_woodland_harvest_detail(force:bool=false)->void:
	if camera==null: return
	var surface_key:="%s:%s:%s" % [river_terrain_grid,detail_surface_center,detail_terrain_patch!=null and detail_terrain_patch.visible]
	force=force or surface_key!=woodland_harvest_surface_key
	woodland_harvest_surface_key=surface_key
	if woodland_harvest_detail==null:
		woodland_harvest_detail=preload("res://scripts/woodland_harvest_detail.gd").new()
		woodland_harvest_detail.name="HarvestedWoodlandDetail"
		add_child(woodland_harvest_detail)
	woodland_harvest_detail.refresh(Vector2(camera_target.x,camera_target.z),camera.size,woodland_visual_areas,GameState.world_seed,int(GameState.elapsed_days),
		func(point:Vector2)->float: return float(_biome_at(point.x,point.y).woodland) if _height_at(point.x,point.y)>SEA_LEVEL+0.015 else 0.0,
		func(point:Vector2)->bool: return _world_position_is_revealed(Vector3(point.x,0,point.y)),
		func(point:Vector2)->float: return _harvest_ground_height_at(point),force)

func _woodland_density_at(x:float,z:float)->float:
	return float(_biome_at(x,z).woodland)*LANDSCAPE_VISUALS.retained_at(Vector2(x,z),woodland_visual_areas)


func _best_site_for(type:String,rng:RandomNumberGenerator)->Vector3:
	## Resource sites sit where the biome field says they belong: timber in
	## dense woodland, game on woodland edges and open grass, stone on bare
	## high ground, fertile soil on floodplain alluvium and deep grassland
	## soils. Fertile candidates are biased close to home first — if the
	## settlement stands on good ground, its fertile land is beside it.
	var best:=Vector3.ZERO
	var best_score:=-INF
	for attempt in 30:
		var candidate:Vector3
		if type in ["Fertile","Fiber Plants"] and attempt<14:
			var offset:=Vector2(rng.randf_range(-16.0,16.0),rng.randf_range(-16.0,16.0))
			candidate=Vector3(world_start_position.x+offset.x,0.0,world_start_position.z+offset.y)
			candidate.y=_height_at(candidate.x,candidate.z)
			if candidate.y<=0.04 or candidate.y>=7.0: continue
		else:
			candidate=_random_valid_site(rng)
		if candidate==Vector3.ZERO: continue
		var biome:=_biome_at(candidate.x,candidate.z,candidate.y)
		var score:=0.0
		match type:
			"Timber": score=float(biome.woodland)
			"Game": score=float(biome.game)
			"Stone": score=float(biome.stone)
			"Fiber Plants":
				# Plant fiber is not a rare strategic deposit. Reeds, tough grasses,
				# nettles, and workable bark occur across most inhabited biomes;
				# wet ground and productive vegetation merely improve the source.
				score=float(biome.forage)+clampf(1.0-float(biome.river_distance)/18.0,0.0,1.0)*0.35
			"Fertile":
				score=float(biome.fertility)
				# Prefer the closer of two equally good grounds.
				score+=clampf(1.0-Vector2(candidate.x,candidate.z).distance_to(Vector2(world_start_position.x,world_start_position.z))/72.0,0.0,1.0)*0.25
			_: score=rng.randf()
		if score>best_score:
			best_score=score
			best=candidate
	return best


func _scatter_trees() -> void:
	if WorldSimulation.enabled:
		_scatter_owned_resources()
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = terrain_noise.seed ^ 0x27d4eb2d
	resource_sites.clear()
	var start_2d:=Vector2(world_start_position.x,world_start_position.z)
	var environment_profile:=PlanetEnvironment.profile_at(start_2d,_survey_ground_at(start_2d))
	var potentials:Dictionary=environment_profile.get("resource_potentials",{})
	# Founders see what is actually common in this watershed. Basic materials have
	# substitutes, so a treeless plain, stony upland and wooded basin begin differently
	# without creating an impossible no-expansion start.
	var site_types:Array[String]=[]
	if float(potentials.get("Timber",0.0))>=0.18: site_types.append("Timber")
	if float(potentials.get("Timber",0.0))>=0.62: site_types.append("Timber")
	if float(potentials.get("Stone",0.0))>=0.16: site_types.append("Stone")
	if float(potentials.get("Stone",0.0))>=0.58: site_types.append("Stone")
	if float(potentials.get("Fertile Soil",0.0))>=0.24: site_types.append("Fertile")
	if float(potentials.get("Game",0.0))>=0.18: site_types.append("Game")
	if float(potentials.get("Fiber Plants",0.0))>=0.14: site_types.append("Fiber Plants")
	if float(environment_profile.get("river_distance_km",INF))<=72.0: site_types.append("Freshwater")
	if not ("Timber" in site_types or "Stone" in site_types or "Fiber Plants" in site_types):
		var substitute:="Timber"
		if float(potentials.get("Stone",0.0))>float(potentials.get(substitute,0.0)): substitute="Stone"
		if float(potentials.get("Fiber Plants",0.0))>float(potentials.get(substitute,0.0)): substitute="Fiber Plants"
		site_types.append(substitute)
	for type in site_types:
		# Surface water is a continuous authored river system, not a random deposit.
		# Keep one aggregate occurrence for simulation/progression gates, anchored on
		# the actual channel nearest the founding watershed, and draw no fake dot.
		var center := _surface_water_site_near(world_start_position) if type=="Freshwater" else _best_site_for(type,rng)
		if center == Vector3.ZERO:
			continue
		var canonical_name:="Fertile Soil" if type=="Fertile" else type
		resource_sites.append({"type":type,"position":center,"range":13.0,"potential":float(potentials.get(canonical_name,0.5)),"initially_observed":_world_position_is_revealed(center)})
		if type == "Timber":
			_create_forest_patch(center, rng)
		elif type == "Stone":
			_create_stone_patch(center, rng)
		elif type!="Freshwater":
			_create_resource_marker(type, center)
	ResourceSystem.register_local_occurrences(resource_sites, GameState.province_terrain,environment_profile)


func _surface_water_site_near(origin:Vector3)->Vector3:
	var origin_2d:=Vector2(origin.x,origin.z)
	if _river_distance_at(origin.x,origin.z)<=0.14:
		return Vector3(origin.x,_height_at(origin.x,origin.z)+0.004,origin.z)
	# Search outward in physical distance order. The first hit may be a main river,
	# tributary, or intermittent drainage; all are authored by _river_distance_at and
	# therefore agree with water collection and the rendered blue line.
	for ring in 145:
		var radius:=0.5+float(ring)*0.5
		for spoke in 40:
			var point:=origin_2d+Vector2.from_angle(TAU*float(spoke)/40.0)*radius
			if _height_at(point.x,point.y)<=SEA_LEVEL: continue
			if _river_distance_at(point.x,point.y)<=0.14:
				return Vector3(point.x,_height_at(point.x,point.y)+0.004,point.y)
	return Vector3.ZERO

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
	# A timber occurrence shows as a few copses of real-sized crowns (codex/
	# beauty-4), drawn like every other tree (atlas crowns, seasons, wind, ink
	# edge), one batch. It used to be forty-two lone spheres twenty metres
	# across, each with its own material: dark specks on the grass.
	var transforms:Array[Transform3D]=[]
	var colors:Array[Color]=[]
	for copse in 4:
		var angle := rng.randf() * TAU
		var distance := sqrt(rng.randf()) * 7.8
		var middle := Vector2(center.x + cos(angle) * distance, center.z + sin(angle) * distance)
		for k in rng.randi_range(5, 9):
			var point := middle + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(0.0, 0.012)
			if not _inside_province(point.x / world_width + 0.5, point.y / world_depth + 0.5):
				continue
			var y := _height_at(point.x, point.y)
			var biome:=_biome_at(point.x,point.y,y)
			if y<=SEA_LEVEL or LandscapeCover.canopy_density(biome)<=0:continue
			var scale := rng.randf_range(0.85, 1.45)
			var basis := Basis().rotated(Vector3.UP, rng.randf() * TAU).scaled(Vector3(scale * rng.randf_range(0.8, 1.1), scale * rng.randf_range(0.8, 1.2), scale))
			transforms.append(Transform3D(basis, Vector3(point.x, y + 0.00125 * scale, point.y)))
			var tint:Color=LandscapeCover.canopy_tint(biome,rng.randf())
			tint.a=float(LandscapeCover.CROWN_ATLAS_CELLS[LandscapeCover.crown_variant(transforms[-1].origin)])/15.0
			colors.append(tint)
	if not transforms.is_empty():
		var multi:=MultiMesh.new()
		multi.transform_format=MultiMesh.TRANSFORM_3D
		multi.use_colors=true
		multi.use_custom_data=true
		multi.mesh=_create_irregular_canopy_mesh(0.0037,0.00235)
		multi.instance_count=transforms.size()
		for i in transforms.size():
			multi.set_instance_transform(i,transforms[i])
			multi.set_instance_color(i,colors[i])
			multi.set_instance_custom_data(i,_vegetation_climate(transforms[i].origin))
		var copses:=MultiMeshInstance3D.new()
		copses.name="TimberCopses"
		copses.multimesh=multi
		copses.material_override=_vegetation_surface_material(0,-2)
		copses.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(copses)
	_create_resource_marker("Timber", center)

func _create_stone_patch(center: Vector3, rng: RandomNumberGenerator) -> void:
	# Boulders drawn in the settlement's ink (settlement_ink.gd): warm on the
	# sunward side, cool in shade, one clean outline, a soft shadow; a few
	# grouped where the rock breaks the turf. One batch.
	var transforms:Array[Transform3D]=[]
	var colors:Array[Color]=[]
	for i in 9:
		var radius := rng.randf_range(SURFACE_STONE_RADIUS_KM.x,SURFACE_STONE_RADIUS_KM.y)*0.55
		var at := center + Vector3(rng.randf_range(-1.6, 1.6), 0.0, rng.randf_range(-1.6, 1.6))
		for k in rng.randi_range(1, 3):
			var point := at + Vector3(rng.randf_range(-0.004, 0.004), 0.0, rng.randf_range(-0.004, 0.004))
			point.y = _height_at(point.x, point.z)
			var r := radius * rng.randf_range(0.45, 1.0)
			var basis := Basis().rotated(Vector3.UP, rng.randf() * TAU).scaled(Vector3(r * rng.randf_range(0.9, 1.4), r * rng.randf_range(0.45, 0.75), r * rng.randf_range(0.8, 1.2)))
			transforms.append(Transform3D(basis, point + Vector3(0, r * 0.2, 0)))
			colors.append(Color(0.58, 0.56, 0.51).darkened(rng.randf_range(0.0, 0.18)))
	var mesh := SphereMesh.new()
	mesh.radius = 1.0; mesh.height = 2.0; mesh.radial_segments = 7; mesh.rings = 4
	var multi:=MultiMesh.new()
	multi.transform_format=MultiMesh.TRANSFORM_3D
	multi.use_colors=true
	multi.mesh=mesh
	multi.instance_count=transforms.size()
	for i in transforms.size():
		multi.set_instance_transform(i,transforms[i])
		multi.set_instance_color(i,colors[i])
	var stones:=MultiMeshInstance3D.new()
	stones.name="SurfaceStones"
	stones.multimesh=multi
	stones.material_override=preload("res://scripts/settlement_ink.gd").material()
	stones.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(stones)
	var in_metres:Array[Transform3D]=[]
	for placed in transforms:in_metres.append(Transform3D(placed.basis.scaled(Vector3.ONE*0.001),placed.origin))
	preload("res://scripts/settlement_ink.gd").add_ground_shadows(self,"SurfaceStoneShadows",in_metres,AABB(Vector3(-1000,-1000,-1000),Vector3(2000,2000,2000)))
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
	convoy_banner_sprite.name="FoundingCrest"
	convoy_banner_sprite.texture=_founding_banner_texture(GameState.founding_banner_index)
	convoy_banner_sprite.pixel_size=0.01
	convoy_banner_sprite.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	convoy_banner_sprite.no_depth_test=true
	convoy_banner_sprite.render_priority=12
	convoy_banner_sprite.position=Vector3(0.0,2.56,0.0)
	convoy_map_icon.add_child(convoy_banner_sprite)
	convoy_map_label=Label3D.new()
	convoy_map_label.name="PeopleMapLabel"
	convoy_map_label.text="Founding convoy  •  %s" % _compact_population(GameState.population_total)
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
	convoy_map_label.set_meta("city_map_id","__founding_convoy__")
	convoy_map_label.set_meta("map_annotation_kind","founding_convoy")
	convoy_map_label.set_meta("city_civilization_id","player")
	_update_city_flag(convoy_map_label)
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
	banner.name="SettlementConvoyCrest"
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
		settlement_convoy_label.text="Settlers, %s · %d%% of the way" % [_compact_population(int(convoy.get("population",0))),roundi(float(convoy.get("progress",0.0))*100.0)]

func _update_scale_lod() -> void:
	if camera == null:
		return
	var close_view := camera.size <= SETTLEMENT_DISTRICT_DETAIL_MAX_ZOOM
	var settlement_fabric_view:=camera.size<=SETTLEMENT_FABRIC_MAX_ZOOM
	if settler_map_ring:
		settler_map_ring.visible=not GameState.settlement_site_committed
	if convoy_map_icon:
		convoy_map_icon.visible = false # The shared screen-space card owns the flag.
		convoy_map_icon.scale = Vector3.ONE * maxf(0.045, camera.size / 28.0)
	if convoy_map_label:
		convoy_map_label.visible=_founding_camp_marker_active()
		convoy_map_label.position.y=-camera.size*0.035
	if convoy_detail_root:
		convoy_detail_root.visible = close_view and _founding_camp_marker_active()
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
		settlement_visual_root.visible = settlement_fabric_view and not _organic_town_enabled()
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
				if String(morphology_child.name)=="PersistentDistrictClipmap": morphology_child.visible=camera.size<=SETTLEMENT_DISTRICT_DETAIL_MAX_ZOOM+0.001
	if settlement_border_root:
		settlement_border_root.visible=camera.size>=0.34 and camera.size<=2600.0
	if settlement_network_marker_root:
		# Physical fabric and claim detail retire before true world view; the bounded
		# civic-symbol layer remains so a civilization never disappears from its planet.
		settlement_network_marker_root.visible=camera.size>=0.82 and camera.size<=18000.0
		_update_secondary_settlement_blips()
	if settlement_network_fabric_root:
		settlement_network_fabric_root.visible=camera.size<=2600.0
	_update_settlement_surface_lod_materials()
	_update_settlement_claim_opacity()
	# The settlement's ink outline is held at about one screen pixel.
	preload("res://scripts/settlement_ink.gd").set_pixel(camera.size/maxf(1.0,get_viewport().get_visible_rect().size.y))
	if settlement_roads:settlement_roads.update_view(camera.size,camera.size/maxf(1.0,get_viewport().get_visible_rect().size.y))
	if settlement_blip:
		# Never lay a bright game token over visible physical settlement fabric. The
		# locator exists only after roofs and occupied ground have collapsed below the
		# strategic map's useful detail threshold.
		var blip_profile:=_settlement_expansion_visual_profile({"classification":_settlement_model().classification(),"population":roundi(_settlement_model().primary_population_exact())})
		# A camp or hamlet has no fabric to see until very close, so its mark
		# stays until then, fading in rather than appearing at one zoom.
		var home_mark_zoom:=_home_mark_zoom(blip_profile)
		settlement_blip.visible = "Hearth Circle" in GameState.settlement_completed and camera.size>home_mark_zoom
		settlement_blip.scale = Vector3.ONE * maxf(0.010, camera.size * 0.0048)*float(blip_profile.marker_scale)
		settlement_blip.set_instance_shader_parameter("mark_alpha",smoothstep(home_mark_zoom,home_mark_zoom*1.6,camera.size))
		if int(settlement_blip.get_meta("glyph_stage",-1))!=int(blip_profile.stage):
			settlement_blip.set_meta("glyph_stage",int(blip_profile.stage))
			settlement_blip.set_instance_shader_parameter("glyph_index",float(blip_profile.stage))
			var ring:=RESOURCE_ICONS.settlement_glyph_extent(int(blip_profile.stage))+0.07
			settlement_blip.set_instance_shader_parameter("home_ring_radius",minf(ring,0.485))
			if settlement_map_label:settlement_map_label.set_meta("glyph_clearance",minf(ring,0.485)*40.0+3.0)
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
	if detail_visible and detail_terrain_patch==null and settler_marker and not _camera_in_motion():
		_request_close_terrain_job(settler_marker.position)
	if detail_terrain_patch:
		detail_terrain_patch.visible = detail_visible
	var foliage_fade:=_close_vegetation_lod_strength()
	if foliage_fade>0.001 and settler_marker and not _camera_in_motion():
		_rebuild_close_vegetation(GameState.settlement_founded_at if "Hearth Circle" in GameState.settlement_completed else settler_marker.position)
	# The worn ground of other towns and seen foreign cities, painted once the
	# camera settles near them (settlement_grounds.gd; one at most per frame).
	if camera.size<=4.0 and not _camera_in_motion():
		preload("res://scripts/settlement_grounds.gd").serve(Vector2(camera_target.x,camera_target.z),maxf(camera.size*1.2,0.6))
	if close_vegetation_root:
		close_vegetation_root.visible=foliage_fade>0.001
		if not is_equal_approx(foliage_fade,close_vegetation_fade):
			close_vegetation_fade=foliage_fade
			# Crowns, scrub and forest floor are one detail layer. Leaving either
			# of the latter opaque exposed the square sampling boundary on zoom.
			for child:Node in close_vegetation_root.get_children():
				if child is GeometryInstance3D and child.material_override is ShaderMaterial:
					child.material_override.set_shader_parameter("lod_fade",foliage_fade)
				# Bush shadows go with the bushes as they fade.
				elif String(child.name)=="SettlementGroundShadows":(child as Node3D).visible=foliage_fade>0.6
	if province_terrain_mesh:
		# The streamed regional mesh is the same planet at higher sampling density.
		# Rendering both layers together causes kilometre-scale diagonal z seams.
		# Keep geographic coverage outside the streamed mesh during pan/zoom. The
		# coarse shader cuts out only the installed patch to avoid coplanar seams.
		province_terrain_mesh.visible = true
		var cutout:=Vector4(regional_patch_center.x,regional_patch_center.y,regional_patch_span,1.0) if regional_terrain_patch!=null else Vector4.ZERO
		(province_terrain_mesh.material_override as ShaderMaterial).set_shader_parameter("streamed_cutout",cutout)
	if regional_terrain_patch:
		regional_terrain_patch.visible = true
	# Rivers are the chart's ink out to the continent view: the river shader
	# drapes its line on the streamed patch and lifts it by screen pixels
	# (map_river.gdshader), so no coarse mesh can swallow it. Past a
	# continent the patch no longer covers the view.
	for river_overlay in river_overlays:
		if is_instance_valid(river_overlay): river_overlay.visible=camera.size<=4000.0
	if lens_panel:
		lens_panel.visible=lens_requested_visible and camera.size<=1600.0
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
	if settler_marker and "Hearth Circle" in GameState.settlement_completed and not _camera_in_motion():
		_refresh_settlement_footprint()

	_normalize_aerial_labels()

var city_banner_identity:Dictionary={}
var city_labels:Control

## Map labels found once and re-found only when a Label3D enters the tree.
## Walking the whole scene every frame the camera moved cost more the larger
## the civilization grew.
var aerial_labels:Array[Node]=[]
var aerial_labels_dirty:=true

func _on_aerial_label_added(node:Node)->void:
	if node is Label3D and is_ancestor_of(node): aerial_labels_dirty=true

func _normalize_aerial_labels()->void:
	if camera==null or camera.projection!=Camera3D.PROJECTION_PERSPECTIVE: return
	if is_inside_tree() and not get_tree().node_added.is_connected(_on_aerial_label_added):
		get_tree().node_added.connect(_on_aerial_label_added)
		aerial_labels_dirty=true
	if aerial_labels_dirty or not is_inside_tree():
		aerial_labels=find_children("*","Label3D",true,false)
		aerial_labels_dirty=not is_inside_tree()
	for node in aerial_labels:
		if not is_instance_valid(node) or not is_ancestor_of(node): continue
		var label:=node as Label3D
		if not label.fixed_size or String(label.name) in ["ArmyLabel","FormationLabel","StrengthLabel"]: continue
		if not label.has_meta("aerial_font_size"):
			label.set_meta("aerial_font_size",label.font_size)
			label.set_meta("aerial_pixel_size",label.pixel_size)
		label.font_size=int(label.get_meta("aerial_font_size"))*4
		label.pixel_size=float(label.get_meta("aerial_pixel_size"))/16.0
		if label.has_meta("city_civilization_id"):_update_city_flag(label)

func _update_city_flag(label:Label3D)->void:
	var civ_id:=String(label.get_meta("city_civilization_id",""))
	var identity:Dictionary
	if civ_id=="player":
		if city_banner_identity.get("index",-999)!=GameState.founding_banner_index:
			var texture:=_founding_banner_texture(GameState.founding_banner_index)
			city_banner_identity={"index":GameState.founding_banner_index,"texture":texture,"color":preload("res://scripts/city_map_identity.gd").banner_color(texture)}
		identity=city_banner_identity
	else:identity=preload("res://scripts/city_map_identity.gd").foreign(civ_id)
	label.modulate=identity.color
	var flag:=label.get_node_or_null("CivilizationFlag") as Sprite3D
	if flag==null:
		flag=Sprite3D.new();flag.name="CivilizationFlag";flag.billboard=BaseMaterial3D.BILLBOARD_ENABLED
		flag.fixed_size=true;flag.no_depth_test=true;flag.render_priority=12
		label.add_child(flag)
	flag.texture=identity.texture
	if flag.texture==null:return
	# Measuring the name is the costly part; redo it only when it can change.
	var flag_key:=[label.text,label.font_size,label.pixel_size,label.font,flag.texture]
	if flag.get_meta("layout_key",[])==flag_key:
		_register_city_card(label)
		return
	flag.set_meta("layout_key",flag_key)
	var font:Font=label.font if label.font!=null else ThemeDB.fallback_font
	var width:=font.get_string_size(label.text,HORIZONTAL_ALIGNMENT_LEFT,-1,label.font_size).x
	var ratio:=float(label.font_size)*1.2/float(flag.texture.get_height())
	flag.pixel_size=label.pixel_size*ratio
	flag.offset=Vector2(-(width*.5+float(label.font_size)*.35)/ratio-float(flag.texture.get_width())*.5,0)
	_register_city_card(label)

func _register_city_card(label:Label3D)->void:
	var id:=String(label.get_meta("city_map_id",""))
	var foreign:=bool(label.get_meta("city_map_foreign",false))
	var anchor:Vector3=label.get_meta("city_map_anchor",label.global_position)
	if label==convoy_map_label and is_instance_valid(settler_marker):
		anchor=settler_marker.global_position
	elif label==settlement_map_label:
		for city:Dictionary in GameState.player_settlements:
			if bool(city.get("primary",false)):id=String(city.id);break
		if is_instance_valid(settlement_blip):anchor=settlement_blip.global_position
	elif foreign:
		var pin:=label.get_parent().get_node_or_null("RegionalCityPin") as Label3D
		if pin:anchor=pin.global_position
	if id.is_empty():return
	if not is_instance_valid(city_labels):
		var layer:=CanvasLayer.new();layer.name="CityLabels";layer.layer=0;add_child(layer)
		city_labels=preload("res://scripts/hud/city_labels.gd").new();city_labels.terrain=self;layer.add_child(city_labels)
	city_labels.register_label(label,id,foreign,anchor)

func _city_map_label(city_name:String,population:int=-1,estimate:Dictionary={})->String:
	var count:="Population unknown"
	if not estimate.is_empty():
		count="est. %s–%s" % [_compact_population(roundi(float(estimate.get("low",0)))),_compact_population(roundi(float(estimate.get("high",0))))]
	elif population>=0: count=_compact_population(population)
	return "%s  •  %s" % [city_name,count]

func _settlement_map_label_text(_zoom:float)->String:
	return _city_map_label(_settlement_display_name(),roundi(_settlement_model().primary_population_exact()))

func _update_resource_overlay_lod()->void:
	if resource_overlay_root and is_instance_valid(resource_overlay_root):
		resource_overlay_root.visible=resource_view_enabled
	if not resource_view_enabled or camera==null: return
	var view_key:=_resource_overlay_view_key()
	if view_key!=rendered_resource_overlay_zoom_key and not _camera_in_motion():
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
	# The aggregate regional city layer must not cover the camera-local physical
	# district clipmap. It now becomes dominant only after the 2.4 km clipmap horizon;
	# close inspection keeps just the shader's faint continuity floor beneath roofs.
	var aerial_lod:=smoothstep(0.72,3.20,camera.size)
	if absf(aerial_lod-rendered_settlement_aerial_lod)<0.012: return
	rendered_settlement_aerial_lod=aerial_lod
	var detail_lod_alpha:=1.0-smoothstep(1.62,SETTLEMENT_DISTRICT_DETAIL_MAX_ZOOM,camera.size)
	_update_settlement_lod_shader_node(settlement_land_use_root,aerial_lod,detail_lod_alpha)


func _update_settlement_lod_shader_node(node:Node,aerial_lod:float,detail_lod_alpha:float)->void:
	# District atlases live one level below the stage root, while aggregate land-cover
	# meshes live directly on it. Walking the small, fixed renderer tree lets both sides
	# of the Google-Earth crossover respond continuously without rebuilding geometry.
	if node is GeometryInstance3D:
		var geometry:=node as GeometryInstance3D
		if geometry.material_override is ShaderMaterial:
			var shader_material:=geometry.material_override as ShaderMaterial
			var shader_code:=shader_material.shader.code if shader_material.shader else ""
			if "uniform float aerial_lod" in shader_code:
				shader_material.set_shader_parameter("aerial_lod",aerial_lod)
			if "uniform float detail_lod_alpha" in shader_code:
				shader_material.set_shader_parameter("detail_lod_alpha",detail_lod_alpha)
	for child in node.get_children():
		_update_settlement_lod_shader_node(child,aerial_lod,detail_lod_alpha)

func _founding_banner_texture(index: int) -> Texture2D:
	return preload("res://scripts/city_map_identity.gd").player_crest(index)

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
	if not SEAMLESS_WORLD or camera==null:
		return
	# An oblique orthographic frustum covers much more ground in its forward axis
	# than camera.size alone suggests. Expand the streamed patch with tilt so the
	# high-resolution terrain never ends inside the visible frame.
	var view_size:=get_viewport().get_visible_rect().size
	# Build for the zoom destination, not every intermediate animation size.
	# While zooming inward the existing wider terrain supplies coverage.
	var requested_size:=zoom_target_size if zoom_target_size>0.0 else camera.size
	var desired_span:=TERRAIN_LOD.view_span(requested_size,view_size.x/maxf(1.0,view_size.y),camera_pitch)
	_rebuild_regional_terrain_patch(Vector2(camera_target.x,camera_target.z),desired_span)

func _process_camera_navigation(delta: float) -> void:
	if not SEAMLESS_WORLD or camera==null:
		return
	if is_instance_valid(world_menu_panel) or is_instance_valid(world_globe):
		key_pan_velocity=Vector2.ZERO;return
	var focus:=get_viewport().gui_get_focus_owner()
	if focus is LineEdit or focus is TextEdit:
		key_pan_velocity=Vector2.ZERO;return
	var turn:=(1.0 if Input.is_physical_key_pressed(KEY_Q) else 0.0)-(1.0 if Input.is_physical_key_pressed(KEY_E) else 0.0)
	if turn!=0.0:
		north_reset_active=false
		camera_input_msec=Time.get_ticks_msec()
		camera_yaw=wrapf(camera_yaw+turn*0.8*delta,-PI,PI)
		_update_camera()
	# Up/Down belong to camera distance. Never poll them as movement as well.
	var input:=Vector2(Input.get_axis("ui_left","ui_right"),0.0)
	# WASD still moves along both screen axes.
	var wasd:=Vector2(
		(1.0 if Input.is_physical_key_pressed(KEY_D) else 0.0)-(1.0 if Input.is_physical_key_pressed(KEY_A) else 0.0),
		(1.0 if Input.is_physical_key_pressed(KEY_S) else 0.0)-(1.0 if Input.is_physical_key_pressed(KEY_W) else 0.0)
	)
	if wasd.length_squared()>input.length_squared(): input=wasd.normalized() if wasd.length()>1.0 else wasd
	# Held keys ease the camera up to speed and let it settle when released.
	key_pan_velocity=preload("res://scripts/map_motion.gd").key_pan_step(key_pan_velocity,input,delta)
	if key_pan_velocity.length_squared()<0.0001:
		key_pan_velocity=Vector2.ZERO
		return
	if input.length_squared()>=0.001:pan_coast_velocity=Vector3.ZERO
	var screen_right:=_camera_ground_screen_right()
	var screen_up:=_camera_ground_screen_up()
	var movement:=_camera_keyboard_movement(key_pan_velocity,screen_right,screen_up,camera.size*0.28*delta)
	camera_input_msec=Time.get_ticks_msec()
	_set_camera_target(camera_target+movement)


func _camera_keyboard_movement(input:Vector2,screen_right:Vector3,screen_up:Vector3,distance:float)->Vector3:
	# Screen-space input reports up as negative Y. Express navigation in the
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

func _pan_camera_gesture(delta:Vector2)->void:
	if camera==null or not delta.is_finite() or delta.is_zero_approx():return
	# Native pan deltas use scroll direction, opposite to grab-and-drag.
	# Preserve fractional movement in both axes and scale it to this view.
	var speed:=float(display_preferences.map_scroll_speed) if is_instance_valid(display_preferences) else preload("res://scripts/display_preferences.gd").DEFAULT_MAP_SCROLL_SPEED
	var units_per_pixel:=camera.size*speed/maxf(1.0,get_viewport().get_visible_rect().size.y)
	var movement:=_camera_keyboard_movement(delta,_camera_ground_screen_right(),_camera_ground_screen_up(),units_per_pixel)
	camera_input_msec=Time.get_ticks_msec()
	_set_camera_target(camera_target+movement)

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

func _request_close_terrain_job(center:Vector3)->void:
	var point:=Vector2(center.x,center.z)
	if close_terrain_job!=null and close_terrain_job.center==point: return
	close_terrain_job=preload("res://scripts/close_terrain_job.gd").new(112,0.42,point,func(x:float,z:float)->Array:
		var height:=_close_surface_height_at(x,z)+0.00045
		var step:=0.02
		var dx:=(_height_at(x+step,z)-_height_at(x-step,z))/(step*2.0)
		var dz:=(_height_at(x,z+step)-_height_at(x,z-step))/(step*2.0)
		return [height,Vector3(-dx,1.0,-dz).normalized(),_terrain_color_at(x,z,height)],_terrain_surface_fields_at,_terrain_seasonality_at)

func _advance_close_terrain_job()->void:
	if close_terrain_job==null: return
	if camera==null or camera.size>1.8 or settler_marker==null:
		close_terrain_job=null
		return
	if Vector2(settler_marker.position.x,settler_marker.position.z)!=close_terrain_job.center:
		close_terrain_job=null
		return
	if _camera_in_motion(): return
	if not close_terrain_job.advance(2500): return
	close_terrain_last_slice_usec=close_terrain_job.max_slice_usec
	var started:=Time.get_ticks_usec()
	var center:Vector3=settler_marker.position
	var mesh:ArrayMesh=close_terrain_job.commit()
	close_terrain_job=null
	_install_close_terrain_mesh(mesh,center)
	close_terrain_last_finish_usec=Time.get_ticks_usec()-started

func _install_close_terrain_mesh(mesh:ArrayMesh,center:Vector3)->void:
	detail_surface_center=Vector2(center.x,center.z)
	if detail_terrain_patch: detail_terrain_patch.queue_free()
	detail_terrain_patch=MeshInstance3D.new()
	detail_terrain_patch.name="SettlementGroundDetail"
	detail_terrain_patch.mesh=mesh
	# Both layers use the same world-space uniforms. Reuse the registered
	# material rather than retaining another shader in the fog material list.
	detail_terrain_patch.material_override=regional_terrain_patch.material_override if regional_terrain_patch and regional_terrain_patch.material_override else _create_terrain_material()
	detail_terrain_patch.visible=camera!=null and camera.size<=1.8
	# 0.42 km: its edge dissolves into the regional patch instead of a hard square.
	detail_terrain_patch.set_instance_shader_parameter("patch_feather",Vector4(center.x,center.z,0.42,1.0))
	add_child(detail_terrain_patch)
	_rebuild_close_vegetation(center)

func _build_detail_terrain_patch(center: Vector3) -> void:
	close_terrain_job=null
	detail_surface_center=Vector2(center.x,center.z)
	var resolution := 112
	var span := 0.42
	var vertices:=PackedVector3Array()
	var normals:=PackedVector3Array()
	var colors:=PackedColorArray()
	var climate_uv:=PackedVector2Array()
	var geology_uv:=PackedVector2Array()
	var seasonal_amplitudes:=PackedFloat32Array()
	vertices.resize(resolution*resolution)
	normals.resize(vertices.size())
	colors.resize(vertices.size())
	climate_uv.resize(vertices.size());geology_uv.resize(vertices.size());seasonal_amplitudes.resize(vertices.size())
	for z in resolution:
		for x in resolution:
			var world_x:=center.x+(float(x)/(resolution-1)-0.5)*span
			var world_z:=center.z+(float(z)/(resolution-1)-0.5)*span
			var height:=_close_surface_height_at(world_x,world_z)+0.00045
			var normal_step:=0.02
			var dx:=(_height_at(world_x+normal_step,world_z)-_height_at(world_x-normal_step,world_z))/(normal_step*2.0)
			var dz:=(_height_at(world_x,world_z+normal_step)-_height_at(world_x,world_z-normal_step))/(normal_step*2.0)
			var index:=z*resolution+x
			vertices[index]=Vector3(world_x,height,world_z)
			normals[index]=Vector3(-dx,1.0,-dz).normalized()
			colors[index]=_terrain_color_at(world_x,world_z,height)
			var fields:=_terrain_surface_fields_at(world_x,world_z,height)
			climate_uv[index]=Vector2(fields.x,fields.y);geology_uv[index]=Vector2(fields.z,fields.w)
			seasonal_amplitudes[index]=_terrain_seasonality_at(world_x,world_z,height)
	var mesh:=preload("res://scripts/close_terrain_mesh.gd").build(resolution,vertices,normals,colors,climate_uv,geology_uv,seasonal_amplitudes)
	_install_close_terrain_mesh(mesh,center)

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

func _close_vegetation_lod_strength()->float:
	if camera==null:return 1.0
	var viewport_size:=get_viewport().get_visible_rect().size
	return LandscapeCover.detail_strength(camera.size,viewport_size.x/maxf(1.0,viewport_size.y))

func _rebuild_close_vegetation(center: Vector3) -> void:
	# Use the actual foliage handoff, including viewport shape, for both drawing
	# and deferred construction. Hidden monthly updates must not rebuild plants.
	# The LOD transition checks again before the layer becomes visible.
	if _close_vegetation_lod_strength()<=0.001:return
	if is_instance_valid(close_vegetation_root) and not close_vegetation_root.is_queued_for_deletion() and close_vegetation_revision == GameState.morphology_revision and close_vegetation_center==Vector2(center.x,center.z) and close_vegetation_seed==GameState.world_seed:
		return
	var surface_fields:Array=[]
	for plot:Dictionary in GameState.settlement_plots:
		surface_fields.append([plot.get("polygon",PackedVector2Array()),plot.get("centroid",Vector2.ZERO),plot.get("land_use",""),plot.get("status","active"),plot.get("reclamation",0.0),plot.get("fabric_generation",0),plot.get("roof_coverage",0.0)])
	for route:Dictionary in GameState.settlement_routes:
		surface_fields.append([route.get("active",true),route.get("points",PackedVector2Array()),route.get("hierarchy",route.get("kind","path")),route.get("surface_tier",0),route.get("width_m",1.2)])
	var surface_signature:=str(hash(surface_fields))
	if is_instance_valid(close_vegetation_root) and not close_vegetation_root.is_queued_for_deletion() and close_vegetation_surface_signature==surface_signature and close_vegetation_center==Vector2(center.x,center.z) and close_vegetation_seed==GameState.world_seed:
		close_vegetation_revision=GameState.morphology_revision
		return
	close_vegetation_surface_signature=surface_signature
	if is_instance_valid(close_vegetation_root):
		close_vegetation_root.queue_free()
	close_vegetation_root = Node3D.new()
	close_vegetation_root.name = "CloseLandscapeVegetation"
	add_child(close_vegetation_root)
	close_vegetation_revision = GameState.morphology_revision
	close_vegetation_center=Vector2(center.x,center.z)
	close_vegetation_seed=GameState.world_seed
	close_vegetation_fade=-1.0
	var rng := RandomNumberGenerator.new()
	var canopy_transforms: Array[Transform3D] = []
	var canopy_colors: Array[Color] = []
	var scrub_transforms: Array[Transform3D] = []
	var scrub_colors: Array[Color] = []
	var understory_patches:Array[Dictionary]=[]
	for candidate:Dictionary in LandscapeCover.candidates(Vector2(center.x,center.z),LandscapeCover.PATCH_RADIUS_KM,.008,GameState.world_seed):
		rng.seed=int(candidate.seed)
		var point:Vector2=candidate.point
		var local_point:=point-Vector2(center.x,center.z)
		var world_x:=point.x
		var world_z:=point.y
		if _height_at(world_x, world_z) <= SEA_LEVEL or _near_persistent_settlement_surface(local_point):
			continue
		var biome:=_biome_at(world_x,world_z)
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
		woodland_chance*=clampf(LandscapeCover.canopy_density(biome)*2.0,0.0,1.0)
		var is_canopy := rng.randf() < woodland_chance
		var scrub_chance:=LandscapeCover.scrub_density(biome)*clampf(.65+maxf(0.0,woodland_field),.5,1.4)
		# Brush near a settlement is cut for kindling and grazed down: fewer
		# bushes close in, thickening toward the wild (codex/beauty-4).
		if "Hearth Circle" in GameState.settlement_completed:
			scrub_chance*=lerpf(0.35,1.0,smoothstep(0.08,0.40,local_point.length()))
		if not is_canopy and rng.randf() > scrub_chance:
			continue
		var height := _close_surface_height_at(world_x, world_z)
		if is_canopy:
			var scale := rng.randf_range(0.74, 1.34)
			var basis := Basis().rotated(Vector3.UP, rng.randf() * TAU).scaled(Vector3(scale * rng.randf_range(0.72, 1.10), scale * rng.randf_range(0.72, 1.22), scale))
			canopy_transforms.append(Transform3D(basis, Vector3(world_x, height + 0.00125 * scale, world_z)))
			canopy_colors.append(LandscapeCover.canopy_tint(biome,rng.randf()))
			# Woodland reads from altitude as connected crowns and edge belts, not a
			# scatter of identical dots. Seed a few overlapping neighbours in strong
			# moisture/noise pockets while preserving cleared plots and routes.
			if woodland_field>0.13:
				if rng.randf()<clampf(0.22+woodland_field*0.48,0.20,0.58):
					understory_patches.append({"center":local_point,"radius":rng.randf_range(0.020,0.046)*(0.86+maxf(0.0,woodland_mass)*0.62),"seed":rng.randi()})
				for cluster_member in rng.randi_range(2,6):
					rng.seed=int(candidate.seed)^(cluster_member*7919+104729)
					var neighbour_world:=point+Vector2.from_angle(rng.randf()*TAU)*rng.randf_range(0.0035,0.011)
					var neighbour_local:=neighbour_world-Vector2(center.x,center.z)
					if _near_persistent_settlement_surface(neighbour_local): continue
					var neighbour_x:=neighbour_world.x
					var neighbour_z:=neighbour_world.y
					if _height_at(neighbour_x,neighbour_z)<=SEA_LEVEL: continue
					var neighbour_biome:=_biome_at(neighbour_x,neighbour_z)
					if LandscapeCover.canopy_density(neighbour_biome)<=0:continue
					var neighbour_scale:=scale*rng.randf_range(0.58,0.96)
					var neighbour_basis:=Basis().rotated(Vector3.UP,rng.randf()*TAU).scaled(Vector3(neighbour_scale*rng.randf_range(0.78,1.16),neighbour_scale*rng.randf_range(0.72,1.08),neighbour_scale))
					var neighbour_height:=_close_surface_height_at(neighbour_x,neighbour_z)
					canopy_transforms.append(Transform3D(neighbour_basis,Vector3(neighbour_x,neighbour_height+0.00125*neighbour_scale,neighbour_z)))
					canopy_colors.append(LandscapeCover.canopy_tint(neighbour_biome,rng.randf()))
		else:
			var scale := rng.randf_range(0.42, 1.25)
			var basis := Basis().rotated(Vector3.UP, rng.randf() * TAU).scaled(Vector3(scale * rng.randf_range(0.70, 1.45), scale * rng.randf_range(0.42, 0.82), scale))
			scrub_transforms.append(Transform3D(basis, Vector3(world_x, height + 0.0007 * scale, world_z)))
			scrub_colors.append(LandscapeCover.scrub_tint(biome,rng.randf()))
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
	var material:=_vegetation_surface_material(2)
	material.set_shader_parameter("fallback_climate",_vegetation_climate(center))
	_set_close_vegetation_boundary(material)
	material.render_priority=1
	instance.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
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
				if LandscapeCover.crown_variant(transforms[index].origin)!=variant: continue
				variant_transforms.append(transforms[index])
				variant_colors.append(colors[index])
			_spawn_vegetation_multimesh("%s_%d" % [node_name,variant],mesh,variant_transforms,variant_colors,0,LandscapeCover.CROWN_ATLAS_CELLS[variant])
		return
	_spawn_vegetation_multimesh(node_name,mesh,transforms,colors,1,-1)
	# Each bush sits on its own soft shadow (settlement_ink.gd), one batch.
	if node_name=="ShrubAndGrassPatches" and close_vegetation_root!=null:
		# (The shadow batch works in metres, as the settlement kits are built.)
		var in_metres:Array[Transform3D]=[]
		for placed in transforms:
			# Only where the bushes stand at full strength: past the patch's
			# inner radius they feather out, and a shadow must not outlive them.
			if Vector2(placed.origin.x,placed.origin.z).distance_to(close_vegetation_center)>LandscapeCover.PATCH_INNER_KM:continue
			in_metres.append(Transform3D(placed.basis.scaled(Vector3.ONE*0.001),placed.origin))
		var bounds:=mesh.get_aabb()
		preload("res://scripts/settlement_ink.gd").add_ground_shadows(close_vegetation_root,"ShrubShadows",in_metres,AABB(bounds.position*1000.0,bounds.size*1000.0))

func _spawn_vegetation_multimesh(node_name:String,mesh:Mesh,transforms:Array[Transform3D],colors:Array[Color],kind:int,atlas_variant:int)->void:
	if transforms.is_empty(): return
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.use_colors = true
	multi.use_custom_data = true
	multi.mesh = mesh
	multi.instance_count = transforms.size()
	for index in transforms.size():
		multi.set_instance_transform(index, transforms[index])
		multi.set_instance_color(index, colors[index])
		multi.set_instance_custom_data(index,_vegetation_climate(transforms[index].origin))
	var instance := MultiMeshInstance3D.new()
	instance.name = node_name
	instance.multimesh = multi
	instance.material_override=_vegetation_surface_material(kind,atlas_variant)
	_set_close_vegetation_boundary(instance.material_override)
	# The canopy atlas already contains crown-scale occlusion. Kilometre-world
	# directional shadows collapsed small crowns into near-black map speckles.
	instance.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	close_vegetation_root.add_child(instance)

func _set_close_vegetation_boundary(material:ShaderMaterial)->void:
	# The sampling budget stays fixed. A continuous circular feather hides its
	# rectangular edge without moving any surviving plant or adding geometry.
	material.set_shader_parameter("close_patch",Vector4(close_vegetation_center.x,close_vegetation_center.y,LandscapeCover.PATCH_INNER_KM,LandscapeCover.PATCH_RADIUS_KM))

func _vegetation_surface_material(kind:int,atlas_variant:=-1)->ShaderMaterial:
	if vegetation_surface_shader==null:
		vegetation_surface_shader=Shader.new()
		vegetation_surface_shader.code="""
shader_type spatial;
render_mode blend_mix, depth_prepass_alpha, cull_disabled, diffuse_burley, specular_disabled;
uniform sampler2D discovery_mask : source_color, filter_linear;
uniform vec2 fog_world_size=vec2(40075.0,20004.0);
uniform vec2 fog_current_origin=vec2(0.0);
uniform int vegetation_kind = 0;
uniform vec4 fallback_climate=vec4(0.0);
varying vec4 plant_climate;
#include "res://scripts/seasonal_surface.gdshaderinc"
#include "res://scripts/map_palette.gdshaderinc"
#include "res://scripts/map_cloud.gdshaderinc"
uniform vec4 canopy_tint : source_color = vec4(1.0);
uniform int atlas_variant = -1;
uniform float lod_fade = 1.0;
uniform vec4 close_patch = vec4(0.0);
uniform sampler2D canopy_atlas : source_color, filter_linear_mipmap, repeat_disable;
// The live wind (scripts/map_ambience.gd): crowns and scrub sway downwind,
// tops more than bases, each plant on its own phase. wb_motion is 0 under
// reduced motion.
uniform vec4 map_wind = vec4(1.0, 0.0, 0.0, 0.0);
uniform float map_wind_clock = 0.0;
uniform float wb_motion = 1.0;
varying float tree_keep;
varying vec3 world_position;
varying vec2 patch_position;
varying vec3 plant_normal;
float vh(vec2 p) {
	p=fract(p*vec2(123.34,456.21));
	p+=dot(p,p+45.32);
	return fract(p.x*p.y);
}
float vn(vec2 p) {
	vec2 i=floor(p); vec2 f=fract(p); f=f*f*(3.0-2.0*f);
	return mix(mix(vh(i),vh(i+vec2(1,0)),f.x),mix(vh(i+vec2(0,1)),vh(i+vec2(1,1)),f.x),f.y);
}
// Stop sub-pixel procedural leaves from becoming unstable dark/light speckles.
float filtered_vn(vec2 point) {
	float footprint=max(length(dFdx(point)),length(dFdy(point)));
	return mix(vn(point),0.5,smoothstep(0.35,1.1,footprint));
}
void vertex() {
	if (vegetation_kind!=2 && wb_motion>0.0 && map_wind.z>0.01) {
		// Up to about half a metre at a crown's top in a gale.
		vec2 root=MODEL_MATRIX[3].xz;
		float phase=dot(root,vec2(913.7,677.3));
		float lean=0.55+0.45*sin(map_wind_clock*1.9+phase)*(0.6+0.4*map_wind.w);
		float reach=clamp(VERTEX.y/0.0024,0.0,1.0);
		vec2 dir=length(map_wind.xy)>0.001?normalize(map_wind.xy):vec2(1.0,0.0);
		vec3 push=vec3(dir.x,0.0,dir.y)*0.00045*map_wind.z*lean*reach*reach*wb_motion;
		VERTEX+=inverse(mat3(MODEL_MATRIX))*push;
	}
	plant_normal=normalize((MODEL_MATRIX*vec4(NORMAL,0.0)).xyz);
	plant_climate=INSTANCE_CUSTOM.b>0.0?INSTANCE_CUSTOM:fallback_climate; world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; patch_position=world_position.xz-close_patch.xy; tree_keep=step(vh(MODEL_MATRIX[3].xz*120.0),woodland_retained(MODEL_MATRIX[3].xz)); }
void fragment() {
	vec2 fog_uv=clamp(world_position.xz/fog_world_size+vec2(0.5),vec2(0.0),vec2(1.0));
	float revealed=max(texture(discovery_mask,fog_uv).r,1.0-smoothstep(30.0,38.0,distance(world_position.xz,fog_current_origin)));
	if(revealed<0.06) discard;
	if(vegetation_kind==0 && tree_keep<0.5) discard;
	float boundary=close_patch.w>0.0?1.0-smoothstep(close_patch.z,close_patch.w,length(patch_position)):1.0;
	ALPHA=1.0;
	float crown=filtered_vn(world_position.xz*410.0+vec2(17.0,-31.0));
	float leaf=filtered_vn(world_position.xz*1350.0+vec2(-73.0,29.0));
	float gap=smoothstep(0.68,0.92,filtered_vn(world_position.xz*780.0+vec2(91.0,7.0)));
	vec3 base=COLOR.rgb*canopy_tint.rgb*(0.70+crown*0.38+(leaf-0.5)*0.15);
	if (vegetation_kind==0) {
		// -2: each crown names its atlas cell in its colour's alpha
		// (scripts/close_woods.gd streams crowns this way, one draw per chunk).
		int crown_cell=atlas_variant==-2?int(COLOR.a*15.0+0.5):atlas_variant;
		if (crown_cell>=0) {
			vec2 cell=vec2(float(crown_cell%4),float(crown_cell/4));
			vec2 atlas_uv=(cell+vec2(0.018)+UV*0.964)/4.0;
			vec4 canopy=texture(canopy_atlas,atlas_uv);
			// Preserve shaded crown interiors without letting the darkest source
			// variants become black map dots against the continuous forest albedo.
			float source_luma=dot(canopy.rgb,vec3(0.299,0.587,0.114));
			// Lift the atlas' crushed photographic blacks into the surrounding
			// woodland range. Preserve source hue separately, so this is exposure
			// recovery rather than a flat green tint painted over every crown.
			float canopy_luma=0.18+source_luma*0.70;
			float tint_luma=max(dot(COLOR.rgb,vec3(0.299,0.587,0.114)),0.12);
			// The source atlas has valid alpha but some saturated RGB at crown
			// margins. Suppress that chroma as coverage falls so mipmaps cannot
			// create green/yellow halos around otherwise natural foliage.
			float edge_colour=smoothstep(0.08,0.60,canopy.a);
			vec3 source_chroma=clamp(canopy.rgb/max(source_luma,0.035),vec3(0.45),vec3(1.75));
			vec3 restrained_canopy=canopy_luma*mix(vec3(1.0),source_chroma,mix(0.08,0.38,edge_colour))*vec3(0.78,0.84,0.72);
			// Take most of the hue from the crown's own tint (the biome's canopy
			// greens), so round crowns agree with the painted woodland beneath
			// instead of reading as grey-brown tufts (codex/beauty-2).
			base=restrained_canopy*mix(vec3(1.0),COLOR.rgb/tint_luma,0.55)*1.08;
			base*=0.82+crown*0.16;
			// Keep texture coverage separate from the distance fade. Scissoring
			// an already faded alpha left opaque black pinpricks at aerial scale.
			ALPHA=canopy.a;
		}
		base=mix(base,base*vec3(0.64,0.78,0.61),gap*0.42);
		base=mix(base,base*vec3(1.08,1.12,0.78),smoothstep(0.76,0.94,leaf)*0.18);
	} else {
		// A bush drawn as one (codex/beauty-4): leafy lumps a hand across, lit
		// warm on the side toward the low north-west sun and cool in its own
		// shade, closed by one crisp ink line at the silhouette. It used to read
		// as a dark round speck on the grass.
		vec3 bush_n=normalize(plant_normal);
		float sun=dot(bush_n,vec3(-0.573,0.515,-0.637));
		float lumps=filtered_vn(world_position.xz*2400.0+vec2(5.0,-9.0));
		base=COLOR.rgb*0.92*mix(0.72,1.12,smoothstep(-0.35,0.75,sun+(lumps-0.5)*0.6));
		base=mix(base*vec3(0.82,0.90,1.02),base*vec3(1.05,1.02,0.92),smoothstep(-0.2,0.5,sun));
		base=mix(base,base*vec3(1.10,1.04,0.80),gap*0.20);
	}
	if(vegetation_kind==2) { base=COLOR.rgb; ALPHA=COLOR.a*woodland_retained(world_position.xz)*smoothstep(0.06,0.62,revealed); }
	// Crowns are drawn with a soft ink edge where they turn away from the eye,
	// like the painted canopy's outlined trees (codex/beauty-2); bushes with a
	// thinner, crisper line.
	if(vegetation_kind==0) { float turned=1.0-abs(dot(NORMAL,VIEW)); base=mix(base,base*vec3(0.46,0.48,0.42),smoothstep(0.62,0.95,turned)*0.55); }
	if(vegetation_kind==1) { float turned=1.0-abs(dot(NORMAL,VIEW)); base=mix(base,MAP_INK*1.4,smoothstep(0.80,0.94,turned)*0.75); }
	ALPHA*=lod_fade*boundary;
	if(ALPHA<0.001) discard;
	base=seasonal_ground(base,plant_climate.r,plant_climate.g,plant_climate.b,world_position.z,vegetation_kind==1?0.0:1.0);
	// Same map palette as the ground: olive and slate canopy, not neon blobs.
	base=map_palette_grade(base);
	// The same drifting cloud shadows as the ground beneath (map_cloud).
	base*=map_cloud_shadow(world_position.xz,world_position.y,map_cloud,map_cloud_scale);
	ALBEDO=base*smoothstep(0.06,0.62,revealed);
	EMISSION=MAP_VELLUM*(1.0-smoothstep(0.06,0.62,revealed));
	// Bushes keep a cool sky fill on their shaded side, never a black blot.
	if(vegetation_kind==1) { EMISSION+=base*vec3(0.72,0.82,1.0)*0.12*smoothstep(0.06,0.62,revealed); }
	ROUGHNESS=1.0;
	AO=0.84+crown*0.14;
}
"""
	var material:=ShaderMaterial.new()
	vegetation_surface_shader.code=vegetation_surface_shader.code if "woodland_area_count" in vegetation_surface_shader.code else vegetation_surface_shader.code.replace("varying vec3 world_position;",LANDSCAPE_VISUALS.CUTTING_SHADER+"\nvarying vec3 world_position;")
	material.shader=vegetation_surface_shader
	_register_woodland_material(material)
	_register_seasonal_material(material)
	material.set_shader_parameter("vegetation_kind",kind)
	material.set_shader_parameter("atlas_variant",atlas_variant)
	var canopy_texture:=load("res://assets/textures/vegetation_canopy_atlas.png")
	if canopy_texture: material.set_shader_parameter("canopy_atlas",canopy_texture)
	vegetation_fog_materials.register(material,discovery_mask_texture,Vector2(world_width,world_depth),CivilizationSystem.player_world_origin)
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
	var events:Array[Dictionary] = SettlementModel.with_local_population(func()->Array[Dictionary]:return ConsequenceEngine.process_day(context),true)
	events.append_array(CivicImplementationSystem.process_day(int(GameState.elapsed_days)))
	AdvisorSystem.refresh_pronouncement_statuses()
	_refresh_population_allocations()
	return events

func _refresh_settlement_footprint(force := false) -> void:
	if settler_marker == null:
		return
	if settlement_blip == null:
		settlement_blip = MeshInstance3D.new()
		settlement_blip.name = "PopulationBlip"
		# The chart mark for the people's own place: an inked settlement glyph
		# (resource_icons.settlement_atlas) held at a steady size on screen.
		var blip_mesh := QuadMesh.new()
		settlement_blip.mesh = blip_mesh
		settlement_blip.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		settlement_blip.material_override = _map_glyph_material(false,0.0,true)
		add_child(settlement_blip)
		settlement_map_label=Label3D.new()
		settlement_map_label.name="SettlementMapLabel"
		settlement_map_label.set_meta("city_civilization_id","player")
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
		settlement_map_label.text=_settlement_map_label_text(camera.size if camera!=null else 0.0)
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
	# A changed layout is computed now and drawn at the next refresh (the next
	# day at the latest), so the two never share a frame.
	if not force and settlement_land_use_root!=null and _prime_organic_town_plan(center):
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
	var expansion_profile:=_settlement_expansion_visual_profile({
		"classification":settlement_classification,
		"population":footprint_population,
		"stage_progress":stage_progress
	})
	var render_routes:Array[Dictionary]=GameState.settlement_routes
	if morphology_lod==0: render_routes=_settlement_routes_in_current_detail_view(render_routes,center)
	_create_persistent_settlement_routes(center, render_routes, settlement_land_use_root)
	var render_plots:Array[Dictionary]=_settlement_model().plots_for_lod(morphology_lod)
	if morphology_lod==0: render_plots=_settlement_plots_in_current_detail_view(render_plots,center)
	_create_plot_fabric(center, render_plots, morphology_lod, settlement_land_use_root)
	# The worn ground of a lived place, painted into the land (settlement_grounds.gd).
	_paint_settlement_grounds(center)
	# Plot fabric supplies the remembered street-by-street settlement. Mature urban
	# systems also need a bounded, stage-specific silhouette that remains legible
	# after billions of residents have collapsed into aggregate simulation records.
	_create_settlement_stage_landscape(center,expansion_profile,GameState.settlement_plots,morphology_lod,settlement_land_use_root,defense_snapshot)
	# Resource accessibility is logistical data, not evidence of a built road.
	# Recorded settlement routes above own the visible path network.

func _refresh_undertaking_visuals(force:bool=false)->void:
	var visual=preload("res://scripts/undertaking_map_visual.gd")
	var signature:String=visual.signature(GameState.player_settlements)
	if not force and is_instance_valid(undertaking_visual_root) and signature==undertaking_visual_signature:return
	undertaking_visual_signature=signature
	if is_instance_valid(undertaking_visual_root):undertaking_visual_root.queue_free()
	undertaking_visual_root=Node3D.new();undertaking_visual_root.name="GreatUndertakings";add_child(undertaking_visual_root)
	visual.render(GameState.player_settlements,undertaking_visual_root,_close_surface_height_at)

## Roads between the places (codex/beauty-5, scripts/settlement_roads.gd):
## routed a little at a time on the network tick, drawn in one mesh.
var settlement_roads:Node3D

func _refresh_settlement_roads()->void:
	if "Hearth Circle" not in GameState.settlement_completed or camera==null:return
	if settlement_roads==null:
		settlement_roads=preload("res://scripts/settlement_roads.gd").new()
		settlement_roads.setup(self)
		add_child(settlement_roads)
	settlement_roads.refresh()
	settlement_roads.update_view(camera.size,camera.size/maxf(1.0,get_viewport().get_visible_rect().size.y))

func _refresh_settlement_network(force:=false)->void:
	var undertaking_stamp:int=preload("res://scripts/performance_trace.gd").start()
	_refresh_undertaking_visuals(force)
	preload("res://scripts/performance_trace.gd").mark("network_undertakings",undertaking_stamp)
	if "Hearth Circle" not in GameState.settlement_completed:
		if settlement_border_root: settlement_border_root.visible=false
		if settlement_network_marker_root: settlement_network_marker_root.visible=false
		if settlement_network_fabric_root: settlement_network_fabric_root.visible=false
		return
	_settlement_model().ensure_founded()
	# Coast, slope and river context come from static authored geography. Sampling 120
	# bearings for every settlement on every rendered frame was bounded by settlement
	# count but still ruinously wasteful at planetary scale. Re-sample only when a
	# settlement's identity or position changes (or when a new world seed is loaded).
	var territory_signature:=_settlement_territory_sample_signature()
	if territory_signature!=sampled_settlement_territory_signature:
		_sync_settlement_territory_contexts()
		sampled_settlement_territory_signature=territory_signature
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
	var snapshot_stamp:int=preload("res://scripts/performance_trace.gd").start()
	var network:Dictionary=_settlement_model().settlement_network_snapshot()
	preload("res://scripts/performance_trace.gd").mark("network_snapshot",snapshot_stamp)
	# The coarse signature above also moves for records that draw nothing (daily
	# labour allocations, monthly drift). Rebuild meshes only when what is drawn
	# changed; secondary town designs still get their own per-town check.
	var key_stamp:int=preload("res://scripts/performance_trace.gd").start()
	var geometry_key:=_settlement_network_geometry_key(network,_settlement_network_visibility_key(network))
	preload("res://scripts/performance_trace.gd").mark("network_geometry_key",key_stamp)
	# A forced refresh (a convoy leaving or returning) still skips the meshes when
	# nothing they draw has changed: the key covers every input they read.
	if geometry_key==rendered_settlement_network_geometry_key and is_instance_valid(settlement_border_root):
		var unchanged_secondary:Array[Dictionary]=[]
		for settlement in network.settlements:
			if not bool(settlement.get("primary",false)) and _settlement_marker_in_current_view(settlement): unchanged_secondary.append(settlement)
		_create_secondary_settlement_footprints(unchanged_secondary,force)
		_refresh_secondary_settlement_label_counts(network)
		return
	rendered_settlement_network_geometry_key=geometry_key
	settlement_border_rebuilds+=1
	if settlement_border_root: settlement_border_root.queue_free()
	if settlement_network_marker_root: settlement_network_marker_root.queue_free()

	settlement_border_root=Node3D.new()
	settlement_border_root.name="SettlementTerritoryBorders"
	add_child(settlement_border_root)
	settlement_network_marker_root=Node3D.new()
	settlement_network_marker_root.name="SettlementNetworkMarkers"
	add_child(settlement_network_marker_root)
	if not is_instance_valid(settlement_network_fabric_root):
		settlement_network_fabric_root=Node3D.new()
		settlement_network_fabric_root.name="SettlementNetworkPhysicalFabric"
		add_child(settlement_network_fabric_root)
	settlement_network_fabric_root.visible=true
	var border_surface:=TERRITORY_BAND.Arrays.new()
	var border_halo_surface:=TERRITORY_BAND.Arrays.new()
	var ownership_surface:=SurfaceTool.new()
	ownership_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segment_count:=0
	var halo_segment_count:=0
	var ownership_triangle_count:=0
	var visible_secondary_settlements:Array[Dictionary]=[]
	# One exact height sample set serves fills and both border ribbons.
	var borders_stamp:int=preload("res://scripts/performance_trace.gd").start()
	var samples:=_territory_height_samples()
	for settlement in network.settlements:
		if not bool(settlement.get("primary",false)) and _settlement_marker_in_current_view(settlement): visible_secondary_settlements.append(settlement)
		if not _settlement_boundary_in_current_view(settlement): continue
		var boundary:PackedVector2Array=settlement.get("boundary",PackedVector2Array())
		var radius:=float(settlement.get("claim_radius_km",0.4))
		var visual_profile:=_settlement_expansion_visual_profile(settlement)
		var color:Color=visual_profile.color
		if not bool(settlement.get("primary",false)): color=color.lerp(Color("#8d9165"),0.28)
		color.a=float(visual_profile.border_alpha)*(1.0 if bool(settlement.get("primary",false)) else 0.82)
		# Territory reads as a hand-coloured map: a soft painted wash that pools
		# a little darker just inside the edge, and one fine ink hairline. Both
		# widths follow the zoom bucket (about one and eight screen pixels), so
		# the edge never becomes a heavy 3D ring; they only change on a rebuild.
		var ink_pixel:=_territory_ink_pixel_km()
		var primary:=bool(settlement.get("primary",false))
		var core_width:=ink_pixel*lerpf(0.65,0.95,clampf(float(visual_profile.border_scale)-0.72,0.0,1.0))
		var wash_color:Color=TERRITORY_WASH.lerp(color,0.25)
		var ownership_color:Color=wash_color
		# Store base opacity in geometry; the camera fade is updated live in material.
		ownership_color.a=float(visual_profile.fill_alpha)*1.6*(1.0 if primary else 0.72)
		ownership_triangle_count+=_append_settlement_claim_fill(ownership_surface,boundary,ownership_color,0.0032,samples)
		var edge_wash:=wash_color
		edge_wash.a=0.15 if primary else 0.10
		# Mitred bands (territory_border_band.gd): the wash pools at the ink line
		# and fades inward; the hairline takes its heights from the boundary.
		var wash_band:=ink_pixel*2.5
		var subdivisions:=_border_ribbon_subdivisions()
		var inner_wash:=TERRITORY_BAND.offset(boundary,-wash_band*2.0)
		var faded_wash:=edge_wash;faded_wash.a=0.0
		edge_wash.a*=1.5
		# The wash's inner edge takes the boundary's cached heights, raised by what
		# a 25% slope could climb across the band; it is transparent there, so
		# no zoom step has to sample the planet height field afresh.
		halo_segment_count+=TERRITORY_BAND.append(border_halo_surface,boundary,inner_wash,boundary,boundary,edge_wash,faded_wash,0.0045,samples,subdivisions,wash_band*2.0*0.25)
		var ink:=TERRITORY_INK
		ink.a=(0.85 if primary else 0.62)*clampf(float(visual_profile.border_alpha)/0.7,0.8,1.2)
		segment_count+=TERRITORY_BAND.append(border_surface,TERRITORY_BAND.offset(boundary,core_width),TERRITORY_BAND.offset(boundary,-core_width),boundary,boundary,ink,ink,0.0065,samples,subdivisions)
	var trace=preload("res://scripts/performance_trace.gd")
	var stamp:int=trace.mark("network_borders",borders_stamp)
	_create_secondary_settlement_markers(visible_secondary_settlements)
	stamp=trace.mark("network_markers",stamp)
	_create_secondary_settlement_footprints(visible_secondary_settlements,force)
	stamp=trace.mark("network_footprints",stamp)
	if ownership_triangle_count>0:
		var ownership_mesh:=ownership_surface.commit()
		var ownership_instance:=MeshInstance3D.new()
		ownership_instance.name="ControlledGroundWash"
		ownership_instance.mesh=ownership_mesh
		var ownership_material:=StandardMaterial3D.new()
		ownership_material.vertex_color_use_as_albedo=true
		ownership_material.albedo_color=Color(1,1,1,_settlement_claim_fill_alpha(1.0))
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
	stamp=trace.mark("network_meshes",stamp)
	_update_scale_lod()
	trace.mark("network_scale_lod",stamp)


## Everything the border, claim-wash and marker meshes read, and nothing else.
## Claim outlines drift a few metres a day with population; they are keyed at
## about one screen pixel of the current view, so a sub-pixel drift redraws
## nothing and a zoom (a new view key) redraws the exact outline.
func _settlement_network_geometry_key(network:Dictionary,view_inputs:Array)->int:
	var parts:Array=[view_inputs]
	var pixel:=maxf(0.00001,(camera.size if camera else 1.0)/900.0)
	for settlement:Dictionary in network.settlements:
		var profile:=_settlement_expansion_visual_profile(settlement)
		# An outline is its shape (fixed by site and access axes) scaled by the
		# claim radius; key the shape exactly and the radius in screen pixels.
		var radius:=maxf(0.000001,float(settlement.get("claim_radius_km",0.0)))
		var position_value:Variant=settlement.get("position",Vector2.ZERO)
		var center:Vector2=position_value if position_value is Vector2 else Vector2.ZERO
		var shape:=PackedInt32Array()
		for point:Vector2 in settlement.get("boundary",PackedVector2Array()):
			var unit:=(point-center)/radius
			shape.append(roundi(unit.x*200.0));shape.append(roundi(unit.y*200.0))
		parts.append([String(settlement.get("id","")),bool(settlement.get("primary",false)),position_value,
			hash(shape),roundi(radius*1.3/pixel),
			str(profile),String(settlement.get("name","")),String(settlement.get("occupied_by",""))])
	# Label counts are refreshed in place; only which towns carry labels is keyed.
	var ranked:Array=network.settlements.filter(func(settlement:Dictionary)->bool:return not bool(settlement.get("primary",false)))
	ranked.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
		var a_stage:=int(_settlement_expansion_visual_profile(a).get("stage",0))
		var b_stage:=int(_settlement_expansion_visual_profile(b).get("stage",0))
		if a_stage!=b_stage: return a_stage>b_stage
		return int(a.get("population",0))>int(b.get("population",0)))
	parts.append(ranked.slice(0,24).map(func(settlement:Dictionary)->String:return String(settlement.get("id",""))))
	return hash(parts)

## Secondary town labels show a live count; retext them without a mesh rebuild.
func _refresh_secondary_settlement_label_counts(network:Dictionary)->void:
	if not is_instance_valid(settlement_network_marker_root): return
	var by_id:Dictionary={}
	for settlement:Dictionary in network.settlements: by_id[String(settlement.get("id",""))]=settlement
	for child in settlement_network_marker_root.get_children():
		if not child is Label3D or not child.has_meta("city_map_id"): continue
		var settlement:Dictionary=by_id.get(String(child.get_meta("city_map_id")),{})
		if settlement.is_empty(): continue
		var text:=_city_map_label(String(settlement.get("name","Settlement")),int(settlement.get("population",0)))
		if (child as Label3D).text!=text: (child as Label3D).text=text

## Per-settlement geography sample keys (seed and position); see
## _sync_settlement_territory_contexts.
var sampled_settlement_territory_keys:Dictionary={}

func _settlement_territory_sample_signature()->String:
	var parts:=PackedStringArray([str(GameState.world_seed)])
	for settlement_variant in GameState.player_settlements:
		var settlement:Dictionary=settlement_variant
		var position_value:Variant=settlement.get("position",Vector2.ZERO)
		var position_2d:Vector2=position_value if position_value is Vector2 else Vector2.ZERO
		parts.append("%s:%d:%d" % [
			String(settlement.get("id","")),roundi(position_2d.x*1000.0),roundi(position_2d.y*1000.0)
		])
	return "|".join(parts)

func _sync_settlement_territory_contexts()->void:
	for settlement_variant in GameState.player_settlements:
		var settlement:Dictionary=settlement_variant
		var settlement_id:=String(settlement.get("id",""))
		var position_value:Variant=settlement.get("position",Vector2.ZERO)
		var center:Vector2=position_value if position_value is Vector2 else Vector2.ZERO
		if settlement_id=="": continue
		# Geography is static: re-sample only a settlement that is new or moved
		# (founding a town must not re-survey every existing one).
		var sample_key:="%d:%d:%d" % [GameState.world_seed,roundi(center.x*1000.0),roundi(center.y*1000.0)]
		if String(sampled_settlement_territory_keys.get(settlement_id,""))==sample_key and settlement.has("territory_context"): continue
		sampled_settlement_territory_keys[settlement_id]=sample_key
		var sample:=0.25
		var east_west:=absf(_height_at(center.x+sample,center.y)-_height_at(center.x-sample,center.y))/(sample*2.0)
		var north_south:=absf(_height_at(center.x,center.y+sample)-_height_at(center.x,center.y-sample))/(sample*2.0)
		var terrain_permeability:=clampf(1.0-maxf(east_west,north_south)*2.8,0.24,0.96)
		var water_distance:=_river_distance_at(center.x,center.y)*KM_PER_WORLD_UNIT
		var water_access:=clampf(1.0-water_distance/12.0,0.0,1.0) if water_distance<INF else 0.0
		var coastal_context:=_settlement_coastal_context(center,terrain_permeability)
		var observed_environment:=_survey_ground_at(center)
		observed_environment.merge(coastal_context,true)
		observed_environment["coastal"]=float(coastal_context.get("shoreline_access",0.0))>0.05
		var environment_profile:Dictionary=PlanetEnvironment.profile_at(center,observed_environment)
		var axes:Array[Dictionary]=[]
		if water_access>0.0:
			axes.append({"kind":"river","direction":_drainage_tangent_at(center.x,center.y),"influence":water_access})
		var territory_context:={"terrain_permeability":terrain_permeability,"water_access":water_access,"travel_access":clampf(float(GameState.simulation_metrics.get("logistics",0.16)),0.0,1.0),"access_axes":axes}
		territory_context.merge(coastal_context,true)
		_settlement_model().set_settlement_territory_context(settlement_id,territory_context)
		_settlement_model().set_settlement_environment_profile(settlement_id,environment_profile)
		if not bool(settlement.get("primary",false)):
			ResourceSystem.register_settlement_occurrences(settlement_id,_environment_resource_candidates(center,environment_profile,settlement_id),environment_profile)


func _environment_resource_candidates(center:Vector2,environment_profile:Dictionary,settlement_id:String)->Array[Dictionary]:
	## Generate bounded candidate sites from the actual local ground. ResourceSystem
	## decides which potentials become deposits; this layer only guarantees that any
	## resulting position is land and fits the same biome the player can inspect.
	var result:Array[Dictionary]=[]
	var potentials:Dictionary=environment_profile.get("resource_potentials",{})
	var rng:=RandomNumberGenerator.new()
	rng.seed=hash("%d:%s:environment" % [GameState.world_seed,settlement_id])
	for resource_variant in potentials.keys():
		var resource_name:=String(resource_variant)
		if resource_name=="Freshwater" or float(potentials.get(resource_name,0.0))<0.16: continue
		var best_position:=Vector3.ZERO
		var best_potential:=-1.0
		for attempt in 16:
			var angle:=rng.randf_range(-PI,PI)
			var distance:=lerpf(2.0,46.0,sqrt(rng.randf()))
			var point:=center+Vector2.from_angle(angle)*distance
			var height:=_height_at(point.x,point.y)
			if height<=SEA_LEVEL+0.015: continue
			var local_profile:=PlanetEnvironment.profile_at(point,_survey_ground_at(point))
			var potential:=float((local_profile.get("resource_potentials",{}) as Dictionary).get(resource_name,0.0))
			if potential>best_potential:
				best_potential=potential
				best_position=Vector3(point.x,height,point.y)
		if best_potential>=0.0:
			result.append({"type":resource_name,"position":best_position,"potential":best_potential,"initially_observed":_world_position_is_revealed(best_position)})
	return result


func _settlement_coastal_context(center:Vector2,terrain_permeability:float)->Dictionary:
	# Five rings × twenty-four bearings is a fixed 120 height samples per settlement,
	# independent of population. The authored ocean/land field is the only authority.
	# Keep the sample count fixed while resolving an actual adjacent shore. Starting at
	# 1.5 km treated a beachside founding site as merely "somewhere near water" and
	# made waterfront art drift inland. The outer rings still measure open-ocean scale.
	var distances:=[0.25,1.0,3.0,8.0,24.0]
	var nearest_water:=INF
	var nearest_water_direction:=Vector2.ZERO
	var weighted_water_direction:=Vector2.ZERO
	var open_water_samples:=0
	var outer_samples:=0
	for bearing_index in 24:
		var direction:=Vector2.from_angle(TAU*float(bearing_index)/24.0)
		for distance in distances:
			var sample_point:=center+direction*float(distance)
			var is_water:=_height_at(sample_point.x,sample_point.y)<=SEA_LEVEL+0.015
			if is_water:
				if float(distance)<nearest_water:
					nearest_water=float(distance)
					nearest_water_direction=direction
				# Nearby samples matter most, while the wider water body stabilizes the
				# bearing so a port does not jump between adjacent compass samples.
				weighted_water_direction+=direction/(float(distance)*float(distance))
			if float(distance)>=8.0:
				outer_samples+=1
				if is_water: open_water_samples+=1
	var shoreline_access:=0.0 if nearest_water==INF else clampf(1.0-nearest_water/16.0,0.0,1.0)
	var open_water:=float(open_water_samples)/maxf(1.0,float(outer_samples))
	var marine:=shoreline_access*smoothstep(0.05,0.55,open_water)
	var low_coast:=terrain_permeability
	var coast_direction:=weighted_water_direction.normalized() if weighted_water_direction.length_squared()>0.000001 else nearest_water_direction
	return {
		"shoreline_access":shoreline_access,"marine_opportunity":marine,
		"salt_opportunity":shoreline_access*(0.42+open_water*0.48),
		"storm_exposure":shoreline_access*open_water*(0.36+low_coast*0.22),
		"erosion_exposure":shoreline_access*(0.18+low_coast*0.48)*lerpf(0.55,1.0,open_water),
		"open_water_exposure":open_water*shoreline_access,
		"coast_direction":coast_direction,"nearest_open_water_km":nearest_water
	}


func _settlement_coastal_visual_profile(center:Vector2)->Dictionary:
	# Visual state is derived from the same geographic sample and gated capability as
	# the simulation. It creates no harbor merely because a port tile exists in an atlas.
	var record:Dictionary={}
	for settlement_variant in GameState.player_settlements:
		var candidate:Dictionary=settlement_variant
		if bool(candidate.get("primary",false)):
			record=candidate
			break
	var context:Dictionary=record.get("territory_context",{}) if not record.is_empty() else {}
	if not context.has("coast_direction") or not context.has("nearest_open_water_km"):
		var sample:=0.25
		var east_west:=absf(_height_at(center.x+sample,center.y)-_height_at(center.x-sample,center.y))/(sample*2.0)
		var north_south:=absf(_height_at(center.x,center.y+sample)-_height_at(center.x,center.y-sample))/(sample*2.0)
		var terrain_permeability:=clampf(1.0-maxf(east_west,north_south)*2.8,0.24,0.96)
		context=_settlement_coastal_context(center,terrain_permeability)
	var owns_settlement_model:=not is_inside_tree()
	var settlement_model_node:Node=_settlement_model() if not owns_settlement_model else SettlementModelScript.new()
	var profile:Dictionary=settlement_model_node.coastal_site_profile({"territory_context":context})
	if owns_settlement_model: settlement_model_node.free()
	profile["coast_direction"]=Vector2(context.get("coast_direction",Vector2.ZERO))
	profile["nearest_open_water_km"]=float(context.get("nearest_open_water_km",INF))
	# Immediate shoreline subsistence is intrinsic to a real coastal site. Engineered
	# harbors, blue-water movement and trade remain gated by discovered capabilities.
	profile["shore_visual_ready"]=bool(profile.get("coastal",false)) and float(profile.get("shoreline_access",0.0))>0.05
	profile["maritime_visual_ready"]=maxf(float(profile.get("maritime_movement_factor",0.0)),float(profile.get("maritime_trade_factor",0.0)))>0.02
	return profile

func _settlement_network_lod_band()->int:
	if camera==null: return 0
	if camera.size<=2.4: return 0
	if camera.size<=80.0: return 1
	if camera.size<=600.0: return 2
	if camera.size<=2600.0: return 3
	return 4

## Territory outlines sample the fixed planet height field. The same boundary
## points recur on every rebuild (pan culling, zoom buckets, daily claim ticks),
## so their heights are kept for this world instead of resampled each time.
var territory_height_cache:RefCounted
var territory_height_cache_world:=""

func _territory_height_samples()->RefCounted:
	var world:="%d:%d" % [GameState.world_seed,GameState.active_province]
	if territory_height_cache==null or territory_height_cache_world!=world or int(territory_height_cache.misses)>40000:
		territory_height_cache=preload("res://scripts/settlement_surface_samples.gd").new(_height_at,func(_point:Vector2)->bool:return true)
		territory_height_cache_world=world
	return territory_height_cache

## Render tessellation per boundary edge, chosen by view scale only.
func _border_ribbon_subdivisions()->int:
	if camera==null: return 8
	return 10 if camera.size<4.0 else (6 if camera.size<180.0 else (3 if camera.size<2600.0 else 1))

## What the network meshes depend on from the view: which settlements are culled
## in, and the zoom-driven widths and tessellation. The pan position itself is
## not keyed, so panning over unchanged territory never rebuilds a mesh.
func _settlement_network_visibility_key(network:Dictionary)->Array:
	var borders:=PackedStringArray()
	var markers:=PackedStringArray()
	for settlement:Dictionary in network.settlements:
		var id:=String(settlement.get("id",""))
		if _settlement_boundary_in_current_view(settlement): borders.append(id)
		if not bool(settlement.get("primary",false)) and _settlement_marker_in_current_view(settlement): markers.append(id)
	var zoom_bucket:=roundi(log(maxf(0.10,camera.size))/log(1.8)) if camera else 0
	return [_settlement_network_lod_band(),zoom_bucket,camera.size<=3.0 if camera else false,_border_ribbon_subdivisions(),borders,markers]

func _settlement_network_view_key()->String:
	if camera==null: return "0:0:0"
	var band:=_settlement_network_lod_band()
	# Rebuild only after the camera crosses a sizeable view bucket or a zoom band.
	# This enables spatial culling without turning an ordinary pan into a mesh rebuild
	# every frame.
	var zoom_bucket:=roundi(log(maxf(0.10,camera.size))/log(1.8))
	var bucket_span:=maxf(0.25,pow(1.8,float(zoom_bucket))*0.70)
	return "%d:%d:%d:%d:%s" % [band,zoom_bucket,floori(camera_target.x/bucket_span),floori(camera_target.z/bucket_span),camera.size<=3.0]

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
	elif "camp" in classification or "outpost" in classification or "founding settlement" in classification: stage=0
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


## The people's own place: a camp or hamlet keeps its mark almost to the
## ground, since it has no roofs to show before then; larger places as others.
func _home_mark_zoom(profile:Dictionary)->float:
	return float([2.5,5.0][int(profile.get("stage",0))]) if int(profile.get("stage",0))<=1 else _settlement_stage_marker_zoom(profile)

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


func _settlement_stage_strategic_surface_at(point:Vector2)->bool:
	# Strategic mesh continuity is allowed across steep but dry terrain; density below
	# handles how much of that ground is actually occupied. Rejecting a whole coarse
	# triangle for one steep corner created kilometre-wide geometric holes in cities.
	if not _scout_land_at(point): return false
	if _main_river_distance_at(point.x,point.y)<=MAIN_RIVER_WATER_HALF_WIDTH_KM*1.04: return false
	if _nearest_tributary_distance_at(point)<=TRIBUTARY_WATER_HALF_WIDTH_KM*1.04: return false
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


func _settlement_strategic_density_at(local_point:Vector2,radius:float,cores:Array[Vector2],satellites:Array[Vector2],layout_seed:int,stage:=4)->float:
	var radial_t:=local_point.length()/maxf(0.001,radius)
	if radial_t>=1.04: return 0.0
	# The broad radial term is inherited continuous urban land. Polycentric nuclei and
	# their connective corridors pull that field outward; deterministic low-frequency
	# variation creates organic fringe loss without introducing more scene objects.
	# A megalopolis is a linked system of urban centres, not a uniformly inhabited
	# circle. The inherited central field fills only the inner region; outer growth
	# must be earned by actual satellite nuclei and their connecting corridors.
	# `radius` is already derived from population at the stage's aggregate density.
	# Occupying only its innermost quarter made a five-million-person metropolis look
	# like a few glowing streets in wilderness.  A broad inherited field now carries
	# the continuously inhabited city; low-frequency erosion and satellite centres
	# still keep its fringe irregular and its late form polycentric.
	# City land is broadly continuous. Metropolitan growth becomes progressively
	# polycentric: the inherited city remains, while new population enlarges named
	# nuclei and the inhabited corridors between them instead of filling a perfect disc.
	var radial_reach:float=0.90 if stage<=4 else (0.84 if stage==5 else 0.74)
	var radial_weight:float=0.68 if stage<=4 else (0.57 if stage==5 else 0.39)
	var density:=pow(maxf(0.0,1.0-radial_t/radial_reach),1.42)*radial_weight
	for core in cores:
		density=maxf(density,1.0-clampf(local_point.distance_to(core)/maxf(0.08,radius*0.25),0.0,1.0))
	for satellite_index in satellites.size():
		var satellite:Vector2=satellites[satellite_index]
		density=maxf(density,(1.0-clampf(local_point.distance_to(satellite)/maxf(0.08,radius*0.17),0.0,1.0))*0.84)
		if not cores.is_empty():
			var core:Vector2=cores[satellite_index%cores.size()]
			var nearest:=Geometry2D.get_closest_point_to_segment(local_point,core,satellite)
			var connector:=1.0-clampf(local_point.distance_to(nearest)/maxf(0.06,radius*0.052),0.0,1.0)
			density=maxf(density,connector*0.64)
	var normalized:=local_point/maxf(0.001,radius)
	var seed_phase:=float(posmod(layout_seed,997))/997.0*TAU
	var organic_noise:=sin(normalized.x*17.0+seed_phase)*sin(normalized.y*13.0-seed_phase*0.73)*0.055
	organic_noise+=sin((normalized.x+normalized.y)*29.0+seed_phase*1.91)*0.032
	# Noise may erode or thicken an inhabited fringe, but may never invent detached
	# urban fog across empty territory.
	var occupied_influence:=smoothstep(0.010,0.22,density)
	return clampf(density+organic_noise*occupied_influence,0.0,1.0)


func _append_settlement_strategic_density_field(surface:SurfaceTool,center:Vector3,radius:float,cores:Array[Vector2],satellites:Array[Vector2],layout_seed:int,palette:Dictionary,damage_ratio:float,stage:int,architecture:Dictionary,plots:Array[Dictionary],coastal_profile:Dictionary={})->int:
	# One fixed terrain-draped grid replaces dozens of mutually overdrawn translucent
	# polygons at metropolitan/world scale. Vertex alpha is a continuous density sample;
	# the shared urban shader supplies block/avenue grain inside that bounded footprint.
	# Enough vertices to follow terrain and density without exposing the two triangles
	# of a coarse strategic quad. This remains one fixed mesh: population changes its
	# physical extent, never this bounded resolution or the scene-node count.
	var steps:=26 if stage==3 else (30 if stage==4 else (34 if stage==5 else 38))
	var extent:=radius*0.96
	var spacing:=extent*2.0/float(steps)
	var axis:=_settlement_civic_axis()
	var visual:=_settlement_visual_architecture_profile(architecture)
	var district_family:=0
	if float(visual.get("axiality",0.5))>=0.68: district_family=1
	elif float(visual.get("civic_space",0.5))>=0.66: district_family=2
	elif float(visual.get("defensive_depth",0.5))>=0.66: district_family=3
	# UV2.x preserves the planning axis. The integer portion of UV2.y identifies
	# the civilization's bounded neighborhood family; its fractional portion remains
	# the deterministic settlement seed used by the shader.
	var uv2_axis:=fposmod(axis,TAU)/TAU
	var uv2_seed:=float(posmod(layout_seed,997))/997.0
	var coast_direction:=Vector2(coastal_profile.get("coast_direction",Vector2.ZERO))
	if coast_direction.length_squared()>0.000001: coast_direction=coast_direction.normalized()
	var coast_side:=Vector2(-coast_direction.y,coast_direction.x)
	var coast_distance:=maxf(0.0,float(coastal_profile.get("nearest_open_water_km",INF)))
	var maritime_ready:=bool(coastal_profile.get("maritime_visual_ready",false)) and coast_direction.length_squared()>0.000001 and coast_distance<=radius*1.10+spacing*2.0
	var appended:=0
	for z_index in steps:
		for x_index in steps:
			var cell_center:=Vector2(-extent+(float(x_index)+0.5)*spacing,-extent+(float(z_index)+0.5)*spacing)
			var condition_candidate:Dictionary={
				"cell":Vector2i(x_index,z_index),
				"point":Vector2(center.x+cell_center.x,center.z+cell_center.y),
				"cell_size":spacing
			}
			var condition_index:=_settlement_district_spatial_condition(condition_candidate,damage_ratio,center,plots)
			var coast_projection:=cell_center.dot(coast_direction)
			var coast_cross:=absf(cell_center.dot(coast_side))
			# Only a few real shore-facing cells receive the maritime atlas family. This
			# stays a fixed aggregate district budget: no docks, ships or buildings are
			# spawned with population, and an inland settlement can never enter this path.
			var waterfront_cell:=maritime_ready and absf(coast_projection-coast_distance)<=spacing*1.45 and coast_cross<=radius*0.34 and posmod(x_index+z_index*3+layout_seed,4)==0
			var encoded_family:=district_family+(4 if waterfront_cell else 0)
			# Eight plus the family marks this as the packed strategic-field format.
			# The fractional channel carries condition and then seed without adding a
			# vertex stream or another material/draw call.
			var encoded_uv2:=Vector2(uv2_axis,8.0+float(encoded_family)+(float(condition_index)+uv2_seed)/16.0)
			var local_corners:Array[Vector2]=[
				Vector2(-extent+float(x_index)*spacing,-extent+float(z_index)*spacing),
				Vector2(-extent+float(x_index+1)*spacing,-extent+float(z_index)*spacing),
				Vector2(-extent+float(x_index+1)*spacing,-extent+float(z_index+1)*spacing),
				Vector2(-extent+float(x_index)*spacing,-extent+float(z_index+1)*spacing)
			]
			var densities:Array[float]=[]
			var surface_masks:Array[float]=[]
			var maximum_density:=0.0
			for local_corner in local_corners:
				var world_corner:=Vector2(center.x+local_corner.x,center.z+local_corner.y)
				var value:=_settlement_strategic_density_at(local_corner,radius,cores,satellites,layout_seed,stage)
				# Ridges stay legible as less-developed corridors without punching polygonal
				# holes through the mesh. Actual water is carried by the shoreline mask below.
				var slope_pressure:=smoothstep(0.50,1.28,_terrain_slope_at(world_corner.x,world_corner.y,0.22))
				value*=lerpf(1.0,0.62,slope_pressure)
				densities.append(value)
				surface_masks.append(1.0 if _settlement_stage_strategic_surface_at(world_corner) else 0.0)
				maximum_density=maxf(maximum_density,value)
			# Retain one nearly transparent halo of cells around the actual urban
			# footprint. The shader/vertex alpha can then feather the edge instead of
			# ending on a visible half-kilometre stair step.
			if maximum_density<0.012: continue
			for triangle in [[0,1,2],[0,2,3]]:
				# Keep mixed shoreline triangles and fade only their invalid vertices.
				# Dropping the whole coarse triangle produced kilometre-wide geometric
				# holes at metropolis scale whenever a single corner touched water.
				var triangle_surface:float=maxf(surface_masks[int(triangle[0])],maxf(surface_masks[int(triangle[1])],surface_masks[int(triangle[2])]))
				if triangle_surface<=0.0: continue
				for corner_index in triangle:
					var index:=int(corner_index)
					var local_corner:Vector2=local_corners[index]
					var density:=densities[index]
					# At Google-Earth scale built land inherits the colour of its terrain,
					# materials and vegetation. A single neutral-grey wash made a whole
					# megalopolis look like poured concrete. Broad deterministic zoning
					# now supplies park-rich, earthen, residential and industrial tones;
					# it changes colour only, never the population or number of objects.
					var normalized_corner:=local_corner/maxf(0.001,radius)
					var zoning_phase:=float(posmod(layout_seed,1543))/1543.0*TAU
					var zoning:=0.5+0.28*sin(normalized_corner.x*8.7+zoning_phase)*sin(normalized_corner.y*6.3-zoning_phase*0.61)
					zoning+=0.14*sin((normalized_corner.x-normalized_corner.y)*14.0+zoning_phase*1.37)
					zoning=clampf(zoning,0.0,1.0)
					# Real built land at regional scale is a lower-saturation interruption in
					# vegetation, not a pale translucent glow.  Keep the civilization's material
					# history, but compress it into roof/yard values before terrain blending.
					var terrain_edge:=Color(palette.periphery).lerp(Color("#4f5541"),0.38).darkened(0.10)
					var inhabited:=Color(palette.base).lerp(Color("#5a554b"),0.28).darkened(0.07)
					var urban_color:=terrain_edge.lerp(inhabited,smoothstep(0.10,0.58,density))
					urban_color=urban_color.lerp(Color(palette.dense).darkened(0.055),smoothstep(0.64,0.97,density)*0.68)
					urban_color=urban_color.lerp(Color("#536048"),smoothstep(0.60,0.92,zoning)*(1.0-density)*0.34)
					urban_color=urban_color.lerp(Color(palette.industrial),smoothstep(0.0,0.22,0.28-zoning)*smoothstep(0.34,0.78,density)*0.20)
					urban_color=urban_color.lerp(Color("#423e3a"),damage_ratio*0.58)
					urban_color=urban_color.darkened(0.035+float(stage-5)*0.020)
					# Keep the occupied footprint present through every state. The shader carries
					# upkeep, road failure and structural loss; compounding a second heavy fade
					# here made BAD/POOR look abandoned and DESTROYED disappear altogether.
					var condition_exposure:float=float([1.04,1.02,1.00,0.98,0.96,0.94,0.92,0.90][condition_index])
					urban_color.r*=condition_exposure
					urban_color.g*=condition_exposure
					urban_color.b*=condition_exposure
					if condition_index>=4: urban_color=urban_color.lerp(Color("#4f493d"),0.12+float(condition_index-4)*0.12)
					if condition_index>=6: urban_color=urban_color.lerp(Color("#342f2b"),0.24+float(condition_index-6)*0.20)
					# At map scale the ground is still the ground. Development changes its tone
					# progressively instead of laying a grey card over the landscape; roofs and
					# street patterns in the shader carry the remaining urban information.
					var world_x:=center.x+local_corner.x
					var world_z:=center.z+local_corner.y
					var terrain_color:=_terrain_color_at(world_x,world_z,_height_at(world_x,world_z))
					# Regional settlement cover must remain unmistakable without becoming a
					# strategy-game tint. Dense land now carries enough built-surface contrast
					# to survive aerial haze; the fringe still inherits most of the real terrain.
					urban_color=terrain_color.lerp(urban_color,clampf(0.62+density*0.32,0.62,0.94))
					# Spatial shader output is linear while these authored aerial palette values
					# are chosen by eye.  Without an explicit exposure compression the regional
					# mesh displayed as luminous white mist over the terrain.  Built surfaces
					# should be a darker, lower-chroma land-cover interruption at this altitude.
					var aerial_exposure:=lerpf(0.90,0.82,smoothstep(0.18,0.90,density))
					urban_color.r*=aerial_exposure
					urban_color.g*=aerial_exposure
					urban_color.b*=aerial_exposure
					# The outer city should alter the terrain rather than replace it. Dense
					# cores become unmistakably urban; the fringe still exposes vegetation,
					# fields and relief through one non-overlapping bounded surface.
					var occupied_coverage:=smoothstep(0.035,0.22,density)
					urban_color.a=occupied_coverage*lerpf(0.72,0.995,smoothstep(0.14,0.84,density))*surface_masks[index]
					var world_point:=Vector3(center.x+local_corner.x,0.0,center.z+local_corner.y)
					world_point.y=_close_surface_height_at(world_point.x,world_point.z)+0.00220
					surface.set_color(urban_color)
					surface.set_uv(_atlas_uv(Vector2i(1,0),Vector2(0.5,0.5)))
					surface.set_uv2(encoded_uv2)
					surface.add_vertex(world_point)
				appended+=1
	return appended


func _append_settlement_field_mosaic(surface:SurfaceTool,center:Vector3,field_offset:Vector2,field_radius:float,alignment:float,base_color:Color,field_seed:int)->int:
	# One simulated field can represent a broad cultivated district at strategic zoom,
	# but it should still read as worked land rather than another translucent suburb.
	# Four unequal strips provide bounded tenure/crop variation without creating farms,
	# workers, or population-dependent draw calls. Invalid strips are simply omitted so
	# the aggregate mosaic never paints across rivers, ocean, or cliff-scale terrain.
	var rng:=RandomNumberGenerator.new()
	rng.seed=field_seed
	var forward:=Vector2.from_angle(alignment)
	var right:=Vector2(-forward.y,forward.x)
	var total_half_width:=field_radius*0.78
	var nominal_half_length:=field_radius*1.62
	var strip_count:=4
	var appended:=0
	for strip_index in strip_count:
		var strip_half_width:=total_half_width/float(strip_count)*rng.randf_range(0.68,0.86)
		var lateral:=lerpf(-total_half_width,total_half_width,(float(strip_index)+0.5)/float(strip_count))
		var strip_half_length:=nominal_half_length*rng.randf_range(0.72,1.02)
		var longitudinal_shift:=nominal_half_length*rng.randf_range(-0.13,0.13)
		var strip_center:=field_offset+right*lateral+forward*longitudinal_shift
		var strip_right:=right*strip_half_width
		var strip_forward:=forward*strip_half_length
		var valid:=true
		for corner in [strip_center-strip_right-strip_forward,strip_center+strip_right-strip_forward,strip_center+strip_right+strip_forward,strip_center-strip_right+strip_forward]:
			if not _settlement_stage_land_at(Vector2(center.x,center.z)+Vector2(corner)):
				valid=false
				break
		if not valid: continue
		var strip_tone:=base_color
		if strip_index%3==0: strip_tone=strip_tone.lightened(0.075)
		elif strip_index%3==1: strip_tone=strip_tone.darkened(0.070)
		else: strip_tone=strip_tone.lerp(Color("#756a3f"),0.17)
		strip_tone.a=0.43+rng.randf_range(-0.035,0.035)
		_append_flat_quad(surface,center,strip_center,strip_right,strip_forward,strip_tone,0.00228,Vector2i(1,2),field_seed+strip_index*31)
		appended+=1
	return appended


## `samples` optionally shares exact terrain height/land results within one build.
func _append_settlement_system_ribbon(surface:SurfaceTool,center:Vector3,points:PackedVector2Array,half_width:float,color:Color,lift:float,subdivision_budget:=48,damage_ratio:=0.0,damage_seed:=0,samples:RefCounted=null)->int:
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
			if damage_ratio>0.04:
				var break_sample:=float(absi(hash("%d:%d:%d:road_break" % [damage_seed,index,subdivision]))%1000)/999.0
				if break_sample<pow(clampf(float(damage_ratio),0.0,1.0),1.12)*0.72: continue
			var start:=source_start.lerp(source_finish,float(subdivision)/float(subdivisions))
			var finish:=source_start.lerp(source_finish,float(subdivision+1)/float(subdivisions))
			var direction:=finish-start
			if direction.length_squared()<0.0000001: continue
			var side:=Vector2(-direction.y,direction.x).normalized()*half_width
			var world_middle:=Vector2(center.x,center.z)+(start+finish)*0.5
			if samples:
				if not samples.land_at(world_middle) or not samples.land_at(world_middle+side) or not samples.land_at(world_middle-side): continue
			elif not _settlement_stage_land_at(world_middle) or not _settlement_stage_land_at(world_middle+side) or not _settlement_stage_land_at(world_middle-side): continue
			var corners:=[start-side,finish-side,finish+side,start+side]
			var uvs:=[Vector2(0.0,0.0),Vector2(1.0,0.0),Vector2(1.0,1.0),Vector2(0.0,1.0)]
			for corner_index in [0,1,2,0,2,3]:
				var local_point:Vector2=corners[corner_index]
				var world_point:=Vector3(center.x+local_point.x,0.0,center.z+local_point.y)
				world_point.y=(samples.height_at(world_point.x,world_point.z) if samples else _close_surface_height_at(world_point.x,world_point.z))+lift
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


func _append_settlement_system_ring(surface:SurfaceTool,center:Vector3,radius:float,axis:float,ring_index:int,half_width:float,color:Color,layout_seed:int,damage_ratio:=0.0)->int:
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
		appended+=_append_settlement_system_ribbon(surface,center,PackedVector2Array([point_a,point_b]),half_width,color,0.00285,2,damage_ratio,layout_seed+ring_index*101+index*7)
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


func _append_settlement_civic_signature(flat_surface:SurfaceTool,mass_surface:SurfaceTool,center:Vector3,local_center:Vector2,layout_axis:float,radius:float,stage:int,architecture:Dictionary,palette:Dictionary,damage_ratio:float)->Dictionary:
	# A civilization's civic centre is the most durable visual statement of how it
	# organizes collective life. This is a fixed aggregate precinct, never a building
	# ledger: axial societies inherit a long ceremonial spine, open societies a broad
	# commons, and monumental societies a taller institutional crown. The same handful
	# of triangles serves a town or a billion-person megaregion.
	if stage<3: return {"flat":0,"mass":0}
	var axiality:=clampf(float(architecture.get("axiality",0.5)),0.0,1.0)
	var monumentality:=clampf(float(architecture.get("monumentality",0.5)),0.0,1.0)
	var civic_space:=clampf(float(architecture.get("civic_space",0.5)),0.0,1.0)
	var permeability:=clampf(float(architecture.get("permeability",0.5)),0.0,1.0)
	var right_direction:=Vector2.from_angle(layout_axis)
	var forward_direction:=Vector2(-right_direction.y,right_direction.x)
	var precinct_half_length:=clampf(radius*lerpf(0.030,0.052,axiality),0.030,4.8)
	var precinct_half_width:=clampf(radius*lerpf(0.034,0.016,axiality)*lerpf(0.86,1.22,civic_space),0.022,3.4)
	var civic_ground:Color=Color(palette.get("civic",Color("#92836b"))).lerp(Color("#b49b68"),0.24+civic_space*0.18)
	civic_ground=civic_ground.lerp(Color("#45413d"),damage_ratio*0.52)
	civic_ground.a=0.64+monumentality*0.12
	_append_flat_quad(flat_surface,center,local_center,right_direction*precinct_half_length,forward_direction*precinct_half_width,civic_ground,0.00264,Vector2i(3,2),7719+stage*101)
	var flat_count:=1
	# Permeable cultures express cross-access through the precinct. Closed, axial
	# cultures instead retain one dominant processional space.
	if permeability>0.42:
		var crossing_tone:=civic_ground.darkened(0.12)
		crossing_tone.a*=0.82
		_append_flat_quad(flat_surface,center,local_center,right_direction*precinct_half_width*0.58,forward_direction*precinct_half_length*0.72,crossing_tone,0.00271,Vector2i(3,2),8811+stage*113)
		flat_count+=1
	var capability:=clampf(float(stage-2)/4.0,0.16,1.0)
	var crown_height:=clampf(radius*(0.0028+monumentality*0.0048)*capability,0.014,0.42)*lerpf(1.0,0.56,damage_ratio)
	var crown_width:=clampf(radius*(0.0025+monumentality*0.0018),0.009,0.18)
	var crown_tone:Color=Color(palette.get("civic",Color("#92836b"))).lightened(0.10+monumentality*0.08).lerp(Color("#4b4743"),damage_ratio*0.48)
	_append_settlement_urban_mass(mass_surface,center,local_center,crown_width,crown_width*lerpf(1.0,0.58,axiality),crown_height,layout_axis,crown_tone)
	var mass_count:=1
	if monumentality>0.42 and stage>=4:
		# Paired flanking masses turn ceremonial monumentalism into a skyline
		# silhouette, while retaining a strict three-mass maximum.
		var flank_offset:=forward_direction*precinct_half_width*0.72
		for sign_value in [-1.0,1.0]:
			_append_settlement_urban_mass(mass_surface,center,local_center+flank_offset*sign_value,crown_width*0.68,crown_width*0.52,crown_height*0.58,layout_axis,crown_tone.darkened(0.045))
			mass_count+=1
	return {"flat":flat_count,"mass":mass_count}


func _settlement_stage_damage_ratio(plots:Array[Dictionary])->float:
	var weighted_damage:=0.0
	var total_weight:=0.0
	for plot in plots:
		if String(plot.get("status","active"))=="reclaimed": continue
		var weight:=maxf(0.01,float(plot.get("area_ha",0.01)))
		var status:=String(plot.get("status","active"))
		# Maintenance condition drives great/okay/fine/normal/bad/poor. It is not battle
		# damage and must never scatter destroyed sectors through an otherwise functioning
		# city. Only explicit physical harm or a damaged/ruin state enters this channel.
		var recorded_damage:Dictionary=plot.get("damage",{})
		var damage:=maxf(
			maxf(float(recorded_damage.get("structural",0.0)),float(recorded_damage.get("fire",0.0))),
			maxf(float(recorded_damage.get("contamination",0.0)),float(recorded_damage.get("looting",0.0)))
		)
		if status=="damaged": damage=maxf(damage,maxf(0.48,(1.0-clampf(float(plot.get("condition",1.0)),0.0,1.0))*0.72))
		elif status=="ruin": damage=maxf(damage,0.92)
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


## A palisade drawn as what it is (codex/beauty-3): a close row of sharpened
## stakes standing on the ground, each a little different in height and tone.
func _append_settlement_palisade_segment(surface:SurfaceTool,center:Vector3,local_a:Vector2,local_b:Vector2,height:float,color:Color)->int:
	var direction:=local_b-local_a
	var length:=direction.length()
	if length<0.0003: return 0
	var along:=direction/length
	var side:=Vector2(-along.y,along.x)
	var half:=0.00019
	var count:=clampi(ceili(length/0.00042),1,160)
	for k in count:
		var at:=local_a+along*(float(k)+0.5)*length/float(count)
		var jitter:=float(absi(hash(Vector2i(roundi(at.x*1e5),roundi(at.y*1e5))))%1000)/1000.0
		var tall:=height*(0.86+0.22*jitter)
		var tone:=color.lerp(Color("#9a8260"),0.3*jitter).darkened(0.1*float(k%2))
		var world:=Vector3(center.x+at.x,0.0,center.z+at.y)
		world.y=_close_surface_height_at(world.x,world.z)+0.0001
		var corners:Array[Vector3]=[]
		for c in [Vector2(-1,-1),Vector2(1,-1),Vector2(1,1),Vector2(-1,1)]:
			var offset:Vector2=(along*c.x+side*c.y)*half
			corners.append(world+Vector3(offset.x,0.0,offset.y))
		var tip:=world+Vector3.UP*(tall+half*2.6)
		for i in 4:
			var p0:=corners[i];var p1:=corners[(i+1)%4]
			var shade:=tone.darkened(0.05*float(i))
			for v:Vector3 in [p0,p1,p1+Vector3.UP*tall,p0,p1+Vector3.UP*tall,p0+Vector3.UP*tall]:
				surface.set_color(shade);surface.add_vertex(v)
			for v:Vector3 in [p0+Vector3.UP*tall,p1+Vector3.UP*tall,tip]:
				surface.set_color(shade.lightened(0.08));surface.add_vertex(v)
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


func _append_settlement_defense_ring(flat_surface:SurfaceTool,mass_surface:SurfaceTool,center:Vector3,local_origin:Vector2,radius:float,axis:float,defense_stage:int,integrity:float,completion:float,constructing:bool,color:Color,layout_seed:int,segments:int,gate_angles:Array[float]=[],angular_form:=false,envelope:=PackedFloat32Array())->Dictionary:
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
		if envelope.size()==segments:
			# The wall follows the real edge of the built town (codex/beauty-4),
			# wandering a little as a line of stakes set by hand does.
			var jitter_a:=1.0+0.018*sin(local_angle_a*7.0+seed_phase)
			var jitter_b:=1.0+0.018*sin(local_angle_b*7.0+seed_phase)
			point_a=local_origin+Vector2.from_angle(axis+local_angle_a)*envelope[index]*jitter_a
			point_b=local_origin+Vector2.from_angle(axis+local_angle_b)*envelope[(index+1)%segments]*jitter_b
		var world_middle:=Vector2(center.x,center.z)+(point_a+point_b)*0.5
		if not _settlement_stage_land_at(world_middle): continue
		if defense_stage<=2:
			# Early ditches and berms are visible landscape works, not a selection ring.
			# Keep them subordinate to the inhabited footprint at Google-Earth scale.
			var earthwork_width:=clampf(radius*0.010,0.0016,0.022)
			# A dark cut and narrower sunlit berm read as moved earth. One bright line did
			# not communicate the physical depth or direction of an earthwork.
			var ditch_color:=color.darkened(0.38)
			ditch_color.a=0.72
			flat_count+=_append_settlement_system_ribbon(flat_surface,center,PackedVector2Array([point_a,point_b]),earthwork_width*1.25,ditch_color,0.00265,1)
			var berm_color:=color
			berm_color.a=0.82
			flat_count+=_append_settlement_system_ribbon(flat_surface,center,PackedVector2Array([point_a,point_b]),earthwork_width*0.54,berm_color,0.00342,1)
		else:
			# A palisade is a line of stakes a few metres high, not a rampart.
			var wall_width:=clampf(radius*0.0082,0.0018,0.020) if defense_stage>3 else clampf(radius*0.0020,0.00045,0.0008)
			var wall_height:=clampf((0.0032 if defense_stage==3 else (0.014 if defense_stage==4 else 0.020))*lerpf(0.78,1.0,integrity),0.003,0.028)
			if defense_stage==3:mass_count+=_append_settlement_palisade_segment(mass_surface,center,point_a,point_b,wall_height,color)
			else:mass_count+=_append_settlement_defense_wall_segment(mass_surface,center,point_a,point_b,wall_width,wall_height,color)
	return {"flat":flat_count,"mass":mass_count}


## The built town's edge, as a radius (settlement km) at each of `segments`
## bearings from the settlement's centre (local angles after `axis`): the
## ground most of its houses, yards and stores stand within, smoothed as a
## wall line would run, a few metres beyond the last eaves. Empty when the
## fabric is too thin to trace.
func _settlement_wall_envelope(plots:Array[Dictionary],segments:int,axis:float,fallback:float)->PackedFloat32Array:
	var buckets:Array=[]
	for k in segments:buckets.append([])
	var built:=0
	for plot in plots:
		var use:=String(plot.get("land_use",""))
		if use in ["","field","pasture","water","waste","vacant","temporary_encampment","woodland"]:continue
		if String(plot.get("status","active")) in ["vacant","reclaimed","ruin"]:continue
		var c:Variant=plot.get("centroid",Vector2.ZERO)
		if not c is Vector2:continue
		var at:Vector2=c
		var reach:=sqrt(maxf(float(plot.get("area_ha",0.01)),0.0001)/100.0/PI)
		var d:=at.length()+reach*0.8
		if d>fallback*2.2:continue
		var k:=int(fposmod(at.angle()-axis,TAU)/TAU*float(segments))%segments
		(buckets[k] as Array).append(d)
		built+=1
	if built<6:return PackedFloat32Array()
	var sector:=PackedFloat32Array();sector.resize(segments)
	for k in segments:
		var list:Array=buckets[k]
		if list.is_empty():
			sector[k]=-1.0
			continue
		list.sort()
		# The outer houses of the sector, not a lone outlier down the road.
		sector[k]=float(list[mini(list.size()-1,int(float(list.size())*0.8))])
	# Fill bearings with nothing built from their neighbours.
	for k in segments:
		if sector[k]>=0.0:continue
		var left:=-1.0;var right:=-1.0;var dl:=0;var dr:=0
		for step in range(1,segments):
			if left<0.0 and sector[(k-step+segments)%segments]>=0.0:
				left=sector[(k-step+segments)%segments];dl=step
			if right<0.0 and sector[(k+step)%segments]>=0.0:
				right=sector[(k+step)%segments];dr=step
			if left>=0.0 and right>=0.0:break
		sector[k]=lerpf(left,right,float(dl)/float(dl+dr)) if left>=0.0 and right>=0.0 else maxf(left,right)
	var raw:=sector.duplicate()
	for pass_index in 8:
		var next:=sector.duplicate()
		for k in segments:
			next[k]=(sector[(k-1+segments)%segments]+sector[k]*2.0+sector[(k+1)%segments])*0.25
		sector=next
	var out:=PackedFloat32Array();out.resize(segments)
	for k in segments:
		# Vertex k lies between sectors k-1 and k; the wall never cuts a house.
		var r:=maxf((sector[(k-1+segments)%segments]+sector[k])*0.5,maxf(raw[(k-1+segments)%segments],raw[k])*0.84)
		out[k]=clampf(r+0.011,0.035,maxf(fallback*1.8,0.05))
	# The line never runs through a house: where one straddles it, the stakes
	# go round the outside of its yard.
	for plot in plots:
		var use:=String(plot.get("land_use",""))
		if use in ["","field","pasture","water","waste","vacant","temporary_encampment","woodland"]:continue
		if String(plot.get("status","active")) in ["vacant","reclaimed","ruin"]:continue
		var c:Variant=plot.get("centroid",Vector2.ZERO)
		if not c is Vector2:continue
		var at:Vector2=c
		var reach:=sqrt(maxf(float(plot.get("area_ha",0.01)),0.0001)/100.0/PI)
		var bearing:=fposmod(at.angle()-axis,TAU)/TAU*float(segments)
		var k0:=int(bearing)%segments
		var k1:=(k0+1)%segments
		var line:=lerpf(out[k0],out[k1],bearing-floorf(bearing))
		if at.length()-reach<line+0.004 and at.length()+reach>line-0.004:
			var clear:=minf(at.length()+reach+0.007,maxf(fallback*1.8,0.05))
			out[k0]=maxf(out[k0],clear);out[k1]=maxf(out[k1],clear)
	return _settlement_wall_hull(out,axis)

## A defensive line is laid out to be held (codex/beauty-5): it runs straight
## across the pockets between a cross-shaped town's arms instead of doubling
## back into them, so the traced line is pulled most of the way out to its
## convex hull and then eased into gentle bends. It only ever moves outward,
## so it still clears every house the trace cleared.
func _settlement_wall_hull(envelope:PackedFloat32Array,axis:float)->PackedFloat32Array:
	var segments:=envelope.size()
	if segments<6:return envelope
	var points:=PackedVector2Array()
	for k in segments:points.append(Vector2.from_angle(axis+TAU*float(k)/float(segments))*envelope[k])
	var hull:=Geometry2D.convex_hull(points)
	if hull.size()<4:return envelope
	var out:=envelope.duplicate()
	for k in segments:
		var direction:=Vector2.from_angle(axis+TAU*float(k)/float(segments))
		var reach:=envelope[k]
		for i in hull.size()-1:
			var hit:Variant=Geometry2D.segment_intersects_segment(Vector2.ZERO,direction*envelope[k]*4.0,hull[i],hull[i+1])
			if hit is Vector2:reach=maxf(reach,(hit as Vector2).length())
		# Most of the way to the hull: a held line, a little give left in it.
		out[k]=lerpf(envelope[k],reach,0.82)
	for pass_index in 3:
		var next:=out.duplicate()
		for k in segments:
			next[k]=maxf(envelope[k],(out[(k-1+segments)%segments]+out[k]*2.0+out[(k+1)%segments])*0.25)
		out=next
	return out

## Gate bearings (world angles) where the main streets cross the traced wall.
func _settlement_wall_gates(envelope:PackedFloat32Array,axis:float)->Array[float]:
	var gates:Array[float]=[]
	var segments:=envelope.size()
	for route in GameState.settlement_routes:
		if not bool(route.get("active",true)):continue
		var major:=String(route.get("hierarchy","")) in ["main_approach","lane","street"] or int(route.get("surface_tier",0))>=2 or float(route.get("width_m",0.0))>=2.5
		if not major:continue
		var raw:Variant=route.get("points",PackedVector2Array())
		var points:=PackedVector2Array()
		if raw is PackedVector2Array:points=raw
		elif raw is Array:
			for p in raw:
				if p is Vector2:points.append(p)
		for i in range(1,points.size()):
			var a:Vector2=points[i-1];var b:Vector2=points[i]
			var ra:=envelope[int(fposmod(a.angle()-axis,TAU)/TAU*float(segments))%segments]
			var rb:=envelope[int(fposmod(b.angle()-axis,TAU)/TAU*float(segments))%segments]
			var da:=a.length()-ra;var db:=b.length()-rb
			if signf(da)==signf(db) or is_zero_approx(da-db):continue
			var crossing:=a.lerp(b,da/(da-db))
			var bearing:=crossing.angle()
			var near:=false
			for g in gates:
				if absf(wrapf(g-bearing,-PI,PI))<0.35:
					near=true
					break
			if not near:gates.append(bearing)
			if gates.size()>=6:return gates
	return gates

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
	# Weathered timber for a palisade and pale dressed stone for walls, in the
	# settlement's painted palette rather than near-black slabs (codex/beauty-3).
	var colors:=[Color("#000000"),Color("#55472f"),Color("#675138"),Color("#806a4c"),Color("#8e897d"),Color("#85857d")]
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
	# Ditches and palisades enclose the built town as it really lies: the
	# wall runs just outside its houses, yards and stores, and its gates open
	# where the main streets leave (codex/beauty-4). The legacy circle stays
	# for fabric too thin to trace.
	var traced:=PackedFloat32Array()
	if defense_stage in [2,3]:
		traced=_settlement_wall_envelope(plots,30 if defense_stage==2 else 36,float(layout.axis),primary_radius)
		if not traced.is_empty():
			var street_gates:=_settlement_wall_gates(traced,float(layout.axis))
			if not street_gates.is_empty():gate_angles=street_gates
			primary_radius=0.0
			for r in traced:primary_radius=maxf(primary_radius,r)
	match defense_stage:
		2: ring_specs.append({"origin":Vector2.ZERO,"radius":primary_radius*0.90,"segments":30,"gates":gate_angles,"angular":false,"envelope":traced})
		3: ring_specs.append({"origin":Vector2.ZERO,"radius":primary_radius,"segments":36 if not traced.is_empty() else 24,"gates":gate_angles,"angular":false,"envelope":traced})
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
		var ring_envelope:PackedFloat32Array=spec.get("envelope",PackedFloat32Array())
		var counts:=_append_settlement_defense_ring(flat_surface,mass_surface,center,Vector2(spec.origin),float(spec.radius),axis+(float(ring_index)*0.07 if ring_envelope.is_empty() else 0.0),defense_stage,integrity,completion,constructing,color,layout_seed+ring_index*131,int(spec.segments),spec.get("gates",[]),bool(spec.get("angular",false)),ring_envelope)
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
		if not traced.is_empty():
			var local_angle:=fposmod(angle-float(layout.axis),TAU)
			post_radius=traced[int(local_angle/TAU*float(traced.size()))%traced.size()]*(0.97 if defense_stage<=2 else 1.0)
		var post_offset:=_settlement_stage_resolve_land_offset(center,Vector2.from_angle(angle)*post_radius)
		if post_offset==Vector2.ZERO and not _settlement_stage_land_at(Vector2(center.x,center.z)): continue
		var post_width:=clampf(primary_radius*0.014,0.0022,0.014)
		# A palisade's gate towers are timber platforms, not keeps.
		var post_height:float=[0.0,0.010,0.011,0.0065,0.022,0.031][defense_stage]*lerpf(0.76,1.0,integrity)
		_append_settlement_urban_mass(mass_surface,center,post_offset,post_width,post_width*(1.0 if defense_stage<5 else 1.35),post_height,angle,color)
		mass_count+=1
	return {"flat":flat_count,"mass":mass_count}


func _settlement_district_clipmap_candidates(center:Vector3,layout:Dictionary,stage:int,architecture:Dictionary)->Array[Dictionary]:
	# The simulation stores bounded aggregate plots. Close inspection of a mature city
	# still needs visible block-scale evidence outside that historical sample, so this
	# builds a deterministic camera-local clipmap. Population alters the occupied radius;
	# it never increases the fixed close-view district budget.
	if camera==null or camera.size>SETTLEMENT_DISTRICT_DETAIL_MAX_ZOOM+0.001: return []
	var radius:=float(layout.get("radius",0.0))
	if radius<=0.0: return []
	var local_target:=Vector2(camera_target.x-center.x,camera_target.z-center.z)
	if local_target.length()>radius*1.10+camera.size*1.8: return []
	var visual_architecture:=_settlement_visual_architecture_profile(architecture)
	var axiality:=clampf(float(visual_architecture.get("axiality",0.5)),0.0,1.0)
	var permeability:=clampf(float(visual_architecture.get("permeability",0.5)),0.0,1.0)
	var civic_space:=clampf(float(visual_architecture.get("civic_space",0.5)),0.0,1.0)
	var terrain_conformity:=clampf(float(visual_architecture.get("terrain_conformity",0.5)),0.0,1.0)
	var productive_order:=clampf(float(visual_architecture.get("productive_order",0.5)),0.0,1.0)
	var lineage_clustering:=clampf(float(visual_architecture.get("lineage_clustering",0.5)),0.0,1.0)
	var inquiry_openness:=clampf(float(visual_architecture.get("inquiry_openness",0.5)),0.0,1.0)
	var industrial_intensity:=clampf(float(visual_architecture.get("industrial_intensity",0.5)),0.0,1.0)
	var exchange_network:=clampf(float(visual_architecture.get("exchange_network",0.5)),0.0,1.0)
	var axis:=float(layout.get("axis",0.0))
	# A clipmap cell is an aggregate compound, not one house. A coarser stable lattice
	# covers the whole visible district before the fixed budget fills; the former 22x
	# density exhausted all 384 instances nearest the camera target and produced an
	# artificial circular island of roofs at every zoom.
	# One cell is an aggregate neighborhood footprint at Google-Earth scale. It is
	# intentionally much larger than a building and the complete visible kit is capped.
	# Neighborhood geography belongs to the settlement, not the camera. Fixed stage-
	# scale cells prevent a district from moving, changing condition, or acquiring new
	# damage merely because the player zoomed. Later stages summarize larger ground.
	# The units grow with the organizational scale represented by the stage: a founding
	# cell is a compound, while a city cell is an entire quarter-kilometre neighborhood.
	# The footprints deliberately become large. At city scale the player reads a few
	# dozen complete neighborhoods with roads between them, not a carpet of miniature
	# buildings; later population expands the geographic radius outside the viewport.
	# Early cells are whole settlements; later cells are map-scale districts. Mature
	# districts must be large enough to read as authored plans, but small enough that a
	# close city is a connected mixture of many plans rather than three photographic
	# cards. Regional population growth remains the job of the bounded strategic field.
	var cell_size:float=[0.120,0.220,0.320,0.140,0.200,0.300,0.440][clampi(stage,0,6)]
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
			# A mature neighborhood belongs to a shared street lattice. Large per-cell
			# jitter made even excellent atlas plans read as photographs scattered on
			# grass, because their edges could not meet the streets between them. Early
			# compounds retain organic placement; town-and-later grids move only enough
			# to follow less formal, terrain-conforming practice without losing frontage.
			var jitter_scale:=0.10 if stage<=2 else (0.012+terrain_conformity*0.018+permeability*0.008)
			var jitter:=Vector2(float((seed>>4)%1000)/999.0-0.5,float((seed>>15)%1000)/999.0-0.5)*cell_size*jitter_scale
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
			# Occupied cells are aggregate neighborhoods, not individual buildings. Mature
			# places must therefore read as continuous urban fabric with occasional commons,
			# not as a random scatter of self-contained roof icons. Early settlements retain
			# more ground between compounds; towns and cities progressively close the grid.
			var stage_density:float=[0.58,0.67,0.76,0.92,1.0,1.0,1.0][clampi(stage,0,6)]
			var occupancy:=clampf(0.97-radial_t*0.30+centre_influence*0.25+corridor_influence*0.14+(0.5-permeability)*0.10,0.32,0.995)*stage_density
			if stage>=3:
				# Parks, yards and courts already live inside the aggregate atlas designs.
				# Randomly deleting central town cells only makes the city look unfinished;
				# vacancy belongs mainly at the organic fringe of the occupied footprint.
				occupancy=clampf(1.08-radial_t*0.34+centre_influence*0.10+corridor_influence*0.08,0.50,1.0)
			# High-civic-space cultures preserve recurring commons; permeability creates
			# finer gaps and passages without changing the bounded number of candidates.
			var open_space_sample:=float((seed>>7)%1000)/999.0
			var external_open_space:=0.025+civic_space*0.105+permeability*0.030 if stage<=2 else (0.018 if stage==3 else 0.0)
			if open_space_sample<external_open_space: continue
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
			var civic_threshold:=clampf(0.05+civic_space*0.10+inquiry_openness*0.14+lineage_clustering*0.05,0.08,0.38)
			var productive_threshold:=clampf(0.18+productive_order*0.12+industrial_intensity*0.30+exchange_network*0.10,0.24,0.62)
			if centre_influence>0.28 and land_use_sample<civic_threshold:
				land_use=1
			elif corridor_influence>0.30 and radial_t>0.16 and land_use_sample<productive_threshold:
				land_use=2
			# Alignment belongs to the street grid; the compound kit does not. Mixing eight
			# deterministic footprints inside that shared grid creates dozens of visible
			# combinations once proportions, roof material and age tone are applied.
			candidates.append({"cell":cell,"point":world_point,"angle":alignment,"half_width":half_width,"half_depth":half_depth,"cell_size":cell_size,"seed":seed,"distance":local_point.distance_to(local_target),"radial_t":radial_t,"centre_influence":centre_influence,"corridor_influence":corridor_influence,"land_use":land_use,"shape_variant":seed%8})
	# Town growth must not erase the settlement the player watched become a village.
	# Preserve one authored historical centre and let the new street lattice grow around
	# it. This remains one aggregate atlas instance; it is not a building simulation.
	if stage in [3,4] and not candidates.is_empty() and local_target.length()<=view_radius*1.48:
		var historic_index:=-1
		var historic_distance:=INF
		for candidate_index in candidates.size():
			var candidate_distance:=Vector2(candidates[candidate_index].point).distance_to(Vector2(center.x,center.z))
			if candidate_distance<historic_distance:
				historic_distance=candidate_distance
				historic_index=candidate_index
		if historic_index>=0:
			var historic_candidate:Dictionary=candidates[historic_index]
			# The old centre occupies several later aggregate blocks. Letting it shrink to
			# one town cell made the inherited place look marooned inside a green crater.
			var historic_size:=maxf(0.44,cell_size*2.80)
			var historic_seed:=absi(hash("%d:%d:%d:inherited_historic_core" % [GameState.world_seed,roundi(center.x*1000.0),roundi(center.z*1000.0)]))
			var early_options:Array=_settlement_district_tile_options(false,2,0,architecture)
			var early_tile:=int(early_options[posmod(historic_seed,early_options.size())]) if not early_options.is_empty() else 8
			historic_candidate["point"]=Vector2(center.x,center.z)
			historic_candidate["angle"]=axis
			historic_candidate["distance"]=local_target.length()
			historic_candidate["radial_t"]=0.0
			historic_candidate["centre_influence"]=1.0
			historic_candidate["land_use"]=0
			historic_candidate["historic_core"]=true
			historic_candidate["historic_footprint_size"]=historic_size
			historic_candidate["historic_tile"]=48+early_tile
			# Do not excavate a square vacancy around the inherited plan. The later grid
			# remains beneath its irregular transparent edge, exactly as a real old town
			# is enclosed and absorbed by later neighborhoods. The slightly higher core
			# drape owns the visible overlap without another node or draw call.
			candidates[historic_index]=historic_candidate
	candidates.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
		# Early settlements are one stable place, not a camera-local cloud of camp
		# tokens. Keep their oldest central footprints first. Mature metropolitan
		# clipmaps may prioritize the inspected neighborhood inside a vast radius.
		if stage<=2:
			if not is_equal_approx(float(a.radial_t),float(b.radial_t)): return float(a.radial_t)<float(b.radial_t)
			return int(a.seed)<int(b.seed)
		var a_historic:=bool(a.get("historic_core",false))
		var b_historic:=bool(b.get("historic_core",false))
		if a_historic!=b_historic: return a_historic
		var a_distance_bucket:=floori(float(a.distance)/maxf(0.001,cell_size*1.5))
		var b_distance_bucket:=floori(float(b.distance)/maxf(0.001,cell_size*1.5))
		if a_distance_bucket!=b_distance_bucket: return a_distance_bucket<b_distance_bucket
		return int(a.seed)<int(b.seed)
	)
	if stage<=2 and not candidates.is_empty():
		# The early atlas cell is the whole named settlement, so anchor it to the
		# authoritative settlement coordinate. A world lattice is useful only once
		# one city contains many neighborhood plates.
		candidates[0]["point"]=Vector2(center.x,center.z)
		candidates[0]["angle"]=axis
		candidates[0]["radial_t"]=0.0
	# One early atlas plate is already a complete settlement. It changes plan and
	# expands physically through camp, hamlet and village instead of multiplying
	# into a swarm of unrelated icons. Towns introduce the 25–50-neighborhood kit.
	# The clipmap is one MultiMesh, so its cost is a bounded number of aggregate
	# neighborhoods rather than a node per building or resident.  The old 36-52 cell
	# cap was too small to cover the viewport near the strategic crossover: zooming out
	# exposed an artificial grass moat, then the regional field suddenly replaced it
	# with a full city.  Budget enough cells for the current orthographic footprint and
	# cap by stage.  Later stages use physically larger cells, so they need fewer
	# instances to cover the same screen while still representing vastly more people.
	var stage_floor:int=[1,1,1,54,64,56,48][clampi(stage,0,6)]
	var stage_cap:int=[1,1,1,384,256,144,96][clampi(stage,0,6)]
	var visible_cell_budget:=ceili(pow(camera.size/maxf(0.001,cell_size),2.0)*1.70)
	var stage_budget:=clampi(visible_cell_budget,stage_floor,stage_cap)
	if candidates.size()>stage_budget: candidates.resize(stage_budget)
	return candidates


func _append_clipmap_prism(surface:SurfaceTool,local_center:Vector3,local_size:Vector3)->void:
	# One clipmap instance represents a complete urban block. Building several fixed
	# prisms into that shared block mesh gives it courts, wings and service gaps without
	# increasing the number of MultiMesh instances or draw calls at any population.
	var half:=local_size*0.5
	var corners:=[
		local_center+Vector3(-half.x,-half.y,-half.z),local_center+Vector3(half.x,-half.y,-half.z),
		local_center+Vector3(half.x,-half.y,half.z),local_center+Vector3(-half.x,-half.y,half.z),
		local_center+Vector3(-half.x,half.y,-half.z),local_center+Vector3(half.x,half.y,-half.z),
		local_center+Vector3(half.x,half.y,half.z),local_center+Vector3(-half.x,half.y,half.z)
	]
	var faces:=[
		[4,7,6,5],[0,1,2,3],
		[0,4,5,1],[1,5,6,2],
		[2,6,7,3],[3,7,4,0]
	]
	var face_uvs:=[Vector2(0.0,0.0),Vector2(1.0,0.0),Vector2(1.0,1.0),Vector2(0.0,1.0)]
	for face in faces:
		for vertex_index in [0,1,2,0,2,3]:
			surface.set_uv(face_uvs[vertex_index])
			surface.add_vertex(corners[int(face[vertex_index])])


func _settlement_clipmap_block_mesh(land_use:int,architecture:Dictionary,shape_variant:=0)->ArrayMesh:
	# These are civilization-level construction practices, not randomized props.
	# The same culture therefore leaves a consistent silhouette across every camera-
	# local block while land use still distinguishes quarters, precincts and industry.
	var axiality:=clampf(float(architecture.get("axiality",0.5)),0.0,1.0)
	var monumentality:=clampf(float(architecture.get("monumentality",0.5)),0.0,1.0)
	var permeability:=clampf(float(architecture.get("permeability",0.5)),0.0,1.0)
	var defensive_depth:=clampf(float(architecture.get("defensive_depth",0.5)),0.0,1.0)
	var civic_space:=clampf(float(architecture.get("civic_space",0.5)),0.0,1.0)
	var surface:=SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	if land_use==1:
		# A recognizable civic ensemble: one public crown and two lower wings framing
		# a forecourt. Monumental societies enlarge the crown; civic societies pull the
		# wings apart to preserve more shared ground.
		var crown_height:=lerpf(0.92,1.42,monumentality)
		var crown_depth:=lerpf(0.46,0.62,axiality)
		_append_clipmap_prism(surface,Vector3(0.0,-0.5+crown_height*0.5,-0.12),Vector3(lerpf(0.34,0.52,monumentality),crown_height,crown_depth))
		var wing_offset:=lerpf(0.29,0.39,civic_space)
		var wing_height:=lerpf(0.46,0.66,monumentality)
		for side in [-1.0,1.0]:
			_append_clipmap_prism(surface,Vector3(wing_offset*side,-0.5+wing_height*0.5,0.16),Vector3(0.25,wing_height,0.52))
	elif land_use==2:
		# Productive districts read as sheds around a service court, plus one compact
		# utility mass. This remains legible from an oblique camera without individual
		# factories, vehicles or workers.
		var shed_height:=lerpf(0.42,0.60,axiality)
		_append_clipmap_prism(surface,Vector3(0.0,-0.5+shed_height*0.5,-0.29),Vector3(0.94,shed_height,0.28))
		_append_clipmap_prism(surface,Vector3(-0.08,-0.5+shed_height*0.43,0.25),Vector3(0.76,shed_height*0.86,0.25))
		var utility_height:=lerpf(0.72,1.05,monumentality)
		_append_clipmap_prism(surface,Vector3(0.34,-0.5+utility_height*0.5,0.25),Vector3(0.20,utility_height,0.20))
	else:
		# From the map camera a building must read as a solid roof mass first. Open U/L
		# outlines looked like insects, so the bounded kit uses eight chunky footprints
		# with only closely attached wings. Roads and open ground remain the gaps between
		# these masses rather than being drawn into each individual building symbol.
		var variant:=posmod(shape_variant,8)
		var main_height:=lerpf(0.54,0.82,monumentality)
		var low_height:=main_height*lerpf(0.72,0.88,permeability)
		match variant:
			0:
				_append_clipmap_prism(surface,Vector3(0.0,-0.5+main_height*0.5,0.0),Vector3(0.76,main_height,0.68))
			1:
				_append_clipmap_prism(surface,Vector3(-0.05,-0.5+main_height*0.5,0.0),Vector3(0.88,main_height,0.46))
				_append_clipmap_prism(surface,Vector3(0.30,-0.5+low_height*0.5,0.25),Vector3(0.24,low_height,0.30))
			2:
				_append_clipmap_prism(surface,Vector3(0.0,-0.5+main_height*0.5,-0.02),Vector3(0.48,main_height,0.86))
				_append_clipmap_prism(surface,Vector3(-0.25,-0.5+low_height*0.5,0.22),Vector3(0.30,low_height,0.28))
			3:
				_append_clipmap_prism(surface,Vector3(0.0,-0.5+main_height*0.5,0.0),Vector3(0.70,main_height,0.70))
			4:
				_append_clipmap_prism(surface,Vector3(-0.14,-0.5+main_height*0.5,-0.02),Vector3(0.54,main_height,0.68))
				_append_clipmap_prism(surface,Vector3(0.25,-0.5+low_height*0.5,0.08),Vector3(0.40,low_height,0.50))
			5:
				var hall_height:=main_height*lerpf(0.94,1.08,defensive_depth)
				_append_clipmap_prism(surface,Vector3(0.0,-0.5+hall_height*0.5,-0.04),Vector3(0.86,hall_height,0.58))
				_append_clipmap_prism(surface,Vector3(-0.24,-0.5+low_height*0.42,0.30),Vector3(0.32,low_height*0.84,0.20))
			6:
				_append_clipmap_prism(surface,Vector3(-0.08,-0.5+main_height*0.5,0.0),Vector3(0.60,main_height,0.82))
				_append_clipmap_prism(surface,Vector3(0.29,-0.5+low_height*0.5,-0.12),Vector3(0.22,low_height,0.46))
			7:
				_append_clipmap_prism(surface,Vector3(0.0,-0.5+main_height*0.5,-0.13),Vector3(0.82,main_height,0.38))
				_append_clipmap_prism(surface,Vector3(0.0,-0.5+low_height*0.5,0.18),Vector3(0.42,low_height,0.46))
	surface.generate_normals()
	return surface.commit()


func _settlement_district_condition(candidate:Dictionary,damage_ratio:float,context:Dictionary={})->int:
	# Conditions describe the aggregate neighborhood, never individual households.
	# Peace-time quality comes from actual society-wide capacities with restrained local
	# variation. Siege damage operates on coarse 3x3 sectors so ruins form contiguous
	# scars rather than evenly sprinkling every tile with the same damage tint.
	if district_condition_visual_override>=0:
		return clampi(district_condition_visual_override,0,7)
	var health:=clampf(float(context.get("health",GameState.population_health)),0.0,1.0)
	var food:=clampf(float(context.get("food",GameState.food_security)),0.0,1.0)
	var cohesion:=clampf(float(context.get("cohesion",GameState.simulation_metrics.get("cohesion",0.58))),0.0,1.0)
	var material_capacity:=clampf(float(context.get("material_capacity",GameState.simulation_metrics.get("material_capacity",0.12))),0.0,1.0)
	var legitimacy:=clampf(float(context.get("legitimacy",GameState.simulation_metrics.get("legitimacy",0.62))),0.0,1.0)
	var cell:=Vector2i(candidate.get("cell",Vector2i.ZERO))
	# Grid IDs change with LOD; geography does not. Sample the same fixed world-space
	# sector at every zoom so ordinary upkeep cannot flip merely because the camera did.
	var sample_point:=Vector2(candidate.get("point",Vector2(float(cell.x),float(cell.y))*SETTLEMENT_CONDITION_SAMPLE_KM))
	var neighborhood_sector:=Vector2i(floori(sample_point.x/SETTLEMENT_CONDITION_SAMPLE_KM),floori(sample_point.y/SETTLEMENT_CONDITION_SAMPLE_KM))
	var local_seed:=absi(hash("%d:%d:%d:district_condition" % [GameState.world_seed,neighborhood_sector.x,neighborhood_sector.y]))
	var local_variation:=(float((local_seed>>8)%1000)/999.0-0.5)*0.085
	var social_quality:=health*0.30+food*0.25+cohesion*0.20+material_capacity*0.15+legitimacy*0.10
	var condition_score:=social_quality
	if context.has("physical_quality"):
		condition_score=lerpf(social_quality,clampf(float(context.get("physical_quality",social_quality)),0.0,1.0),0.64)
	condition_score=clampf(condition_score+local_variation,0.0,1.0)
	var condition:=0 if condition_score>=0.84 else (1 if condition_score>=0.72 else (2 if condition_score>=0.60 else (3 if condition_score>=0.48 else (4 if condition_score>=0.36 else 5))))
	var recorded_damage_state:=clampi(int(context.get("recorded_damage_state",0)),0,7)
	if recorded_damage_state>=7 or damage_ratio>=0.98:
		condition=7
	elif recorded_damage_state==6:
		condition=maxi(condition,6)
	elif damage_ratio>0.01:
		var sector:=neighborhood_sector
		var sector_seed:=absi(hash("%d:%d:%d:district_damage" % [GameState.world_seed,sector.x,sector.y]))
		var sector_sample:=float(sector_seed%1000)/999.0
		if sector_sample<damage_ratio*0.48: condition=7
		elif sector_sample<damage_ratio*1.35: condition=maxi(condition,6)
	return condition


func _settlement_district_plot_context(candidate:Dictionary,center:Vector3,plots:Array[Dictionary])->Dictionary:
	# The simulation keeps only a bounded plot ledger. Each visual neighborhood inherits
	# the nearest real aggregate plot's upkeep rather than inventing people or buildings.
	# That makes prosperity and neglect spatial while preserving a fixed render budget.
	if plots.is_empty(): return {}
	var world_point:=Vector2(candidate.get("point",Vector2(center.x,center.z)))
	var local_point:=world_point-Vector2(center.x,center.z)
	var nearest_plot:Dictionary={}
	var nearest_distance:=INF
	for plot in plots:
		if String(plot.get("status","active"))=="reclaimed": continue
		var centroid:=Vector2(plot.get("centroid",Vector2.ZERO))
		var distance:=local_point.distance_to(centroid)
		if distance<nearest_distance:
			nearest_distance=distance
			nearest_plot=plot
	if nearest_plot.is_empty(): return {}
	var physical_quality:=clampf(
		clampf(float(nearest_plot.get("condition",0.62)),0.0,1.0)*0.36+
		clampf(float(nearest_plot.get("prosperity",0.40)),0.0,1.0)*0.26+
		clampf(float(nearest_plot.get("service_access",0.35)),0.0,1.0)*0.20+
		(1.0-clampf(float(nearest_plot.get("maintenance_debt",0.18)),0.0,1.0))*0.18,
		0.0,1.0
	)
	var recorded_damage_state:=0
	# Damage belongs to a physical place, not an LOD cell. Include the represented
	# aggregate plot's area, but keep one stable world-space minimum and bounded reach.
	var plot_radius_km:=sqrt(maxf(0.0,float(nearest_plot.get("area_ha",0.0)))/100.0/PI)
	var damage_reach:=maxf(SETTLEMENT_DAMAGE_INFLUENCE_KM,minf(1.50,plot_radius_km*1.5))
	if nearest_distance<=damage_reach:
		var status:=String(nearest_plot.get("status","active"))
		var damage_record:Dictionary=nearest_plot.get("damage",{})
		var physical_damage:=maxf(
			maxf(float(damage_record.get("structural",0.0)),float(damage_record.get("fire",0.0))),
			maxf(float(damage_record.get("contamination",0.0)),float(damage_record.get("looting",0.0)))
		)
		if status=="ruin" or physical_damage>=0.90: recorded_damage_state=7
		elif status=="damaged" or physical_damage>0.04: recorded_damage_state=6
	return {"physical_quality":physical_quality,"recorded_damage_state":recorded_damage_state}


func _settlement_district_spatial_condition(candidate:Dictionary,damage_ratio:float,center:Vector3,plots:Array[Dictionary])->int:
	# One grid has one condition at every zoom. When an aggregate plot ledger exists,
	# its spatial condition and recorded damage are authoritative; the city-wide ratio
	# must not sprinkle unrelated damage onto otherwise intact neighborhoods. The ratio
	# remains a bounded fallback for old or remote settlements with no plot record.
	var context:Dictionary=_settlement_district_plot_context(candidate,center,plots) if not plots.is_empty() else {}
	return _settlement_district_condition(candidate,0.0 if not plots.is_empty() else damage_ratio,context)


func _settlement_district_atlas_mesh()->ArrayMesh:
	var surface:=SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var vertices:=[Vector3(-0.5,0.0,-0.5),Vector3(0.5,0.0,-0.5),Vector3(0.5,0.0,0.5),Vector3(-0.5,0.0,0.5)]
	var uvs:=[Vector2(0.0,0.0),Vector2(1.0,0.0),Vector2(1.0,1.0),Vector2(0.0,1.0)]
	for vertex_index in [0,1,2,0,2,3]:
		surface.set_uv(uvs[vertex_index])
		surface.add_vertex(vertices[vertex_index])
	surface.generate_normals()
	return surface.commit()


func _settlement_district_draped_atlas_mesh(point:Vector2,angle:float,footprint_size:float,lift:=0.0036)->ArrayMesh:
	# Camps, hamlets and villages use one complete aggregate plan rather than hundreds
	# of little buildings. That plan may span kilometres at the current world scale, so
	# a single tilted quad will inevitably cut into rolling terrain. This fixed 16x16
	# patch follows the actual land while remaining one mesh, one instance and one draw.
	const SUBDIVISIONS:=16
	var surface:=SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var x_direction:=Vector2(cos(angle),-sin(angle))
	var z_direction:=Vector2(sin(angle),cos(angle))
	for z_index in SUBDIVISIONS+1:
		var v:=float(z_index)/float(SUBDIVISIONS)
		for x_index in SUBDIVISIONS+1:
			var u:=float(x_index)/float(SUBDIVISIONS)
			var offset:=x_direction*((u-0.5)*footprint_size)+z_direction*((v-0.5)*footprint_size)
			var sample_point:=point+offset
			surface.set_uv(Vector2(u,v))
			surface.add_vertex(Vector3(sample_point.x,_close_surface_height_at(sample_point.x,sample_point.y)+lift,sample_point.y))
	var row_width:=SUBDIVISIONS+1
	for z_index in SUBDIVISIONS:
		for x_index in SUBDIVISIONS:
			var top_left:=z_index*row_width+x_index
			var top_right:=top_left+1
			var bottom_left:=top_left+row_width
			var bottom_right:=bottom_left+1
			# Counter-clockwise when viewed from above.
			for vertex_index in [top_left,bottom_left,top_right,top_right,bottom_left,bottom_right]:
				surface.add_index(vertex_index)
	surface.generate_normals()
	return surface.commit()


func _settlement_district_surface_basis(point:Vector2,angle:float,footprint_size:float)->Basis:
	# A large atlas instance spans a whole neighborhood and cannot assume the terrain is
	# flat. Align its plane to the local grade so hills do not cut triangular holes through
	# the district footprint; a small lift below handles only metre-scale terrain noise.
	var sample:=clampf(footprint_size*0.36,0.006,0.095)
	var east_west:=(_close_surface_height_at(point.x+sample,point.y)-_close_surface_height_at(point.x-sample,point.y))/(sample*2.0)
	var north_south:=(_close_surface_height_at(point.x,point.y+sample)-_close_surface_height_at(point.x,point.y-sample))/(sample*2.0)
	var surface_normal:=Vector3(-east_west,1.0,-north_south).normalized()
	var nominal_x:=Vector3(cos(angle),0.0,-sin(angle))
	var x_axis:=(nominal_x-surface_normal*nominal_x.dot(surface_normal)).normalized()
	var z_axis:=x_axis.cross(surface_normal).normalized()
	return Basis(x_axis*footprint_size,surface_normal,z_axis*footprint_size)


func _settlement_district_atlas_material(atlas:Texture2D,stage:int,modern:bool,companion_atlas:Texture2D=null,vernacular_atlas:Texture2D=null,palette:Dictionary={},site_ground_color:=Color("#48563e"),inherited_early_atlas:Texture2D=null)->ShaderMaterial:
	var material:=ShaderMaterial.new()
	var shader:=Shader.new()
	shader.code="""
shader_type spatial;
render_mode blend_mix, depth_prepass_alpha, cull_disabled, unshaded;
uniform sampler2D atlas_texture : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D companion_atlas_texture : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D vernacular_atlas_texture : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D inherited_early_atlas_texture : source_color, filter_linear_mipmap_anisotropic;
uniform float occupied_ground_alpha = 0.22;
uniform vec3 occupied_ground_color = vec3(0.48,0.44,0.34);
uniform float aerial_atlas_exposure = 0.84;
uniform float aerial_atlas_saturation = 0.66;
uniform bool preserve_atlas_open_ground = false;
uniform float atlas_safe_inset = 0.018;
uniform vec3 site_ground_color = vec3(0.28,0.34,0.24);
uniform float detail_lod_alpha = 1.0;
varying flat vec4 district_data;

void vertex(){
	district_data=INSTANCE_CUSTOM;
}

float hash21(vec2 point){
	return fract(sin(dot(point,vec2(127.1,311.7)))*43758.5453);
}

float value_noise(vec2 point){
	vec2 cell=floor(point);
	vec2 local=fract(point);
	local=local*local*(3.0-2.0*local);
	float a=hash21(cell);
	float b=hash21(cell+vec2(1.0,0.0));
	float c=hash21(cell+vec2(0.0,1.0));
	float d=hash21(cell+vec2(1.0,1.0));
	return mix(mix(a,b,local.x),mix(c,d,local.x),local.y);
}

void fragment(){
	float tile=floor(district_data.r*63.0+0.5);
	float local_tile=mod(tile,16.0);
	vec2 atlas_cell=vec2(mod(local_tile,4.0),floor(local_tile/4.0));
	// Keep filtering and mip footprints inside the selected atlas cell. Sampling the
	// exact border pulled slivers from an adjacent settlement into open terrain.
	vec2 safe_uv=mix(vec2(atlas_safe_inset),vec2(1.0-atlas_safe_inset),UV);
	vec4 sample_color=texture(atlas_texture,(safe_uv+atlas_cell)/4.0);
	if(tile>=48.0) sample_color=texture(inherited_early_atlas_texture,(safe_uv+atlas_cell)/4.0);
	else if(tile>=32.0) sample_color=texture(vernacular_atlas_texture,(safe_uv+atlas_cell)/4.0);
	else if(tile>=16.0) sample_color=texture(companion_atlas_texture,(safe_uv+atlas_cell)/4.0);
	float source_luma=dot(sample_color.rgb,vec3(0.2126,0.7152,0.0722));
	float condition=floor(district_data.g*7.0+0.5);
	float wear=condition/7.0;
	vec2 identity=vec2(district_data.b,district_data.a)*97.0;
	// Image-generation cleanup left a few nearly pure red/yellow matte pixels around
	// some silhouettes. The former broad "red" test also classified sunlit ochre roofs
	// as matte and erased them, leaving only their dark beams and shadows: the ghost-grid
	// artifact. Only near-primary cleanup colors are rejected here.
	bool red_fringe=sample_color.r>0.76 && sample_color.g<0.24 && sample_color.b<0.20;
	bool yellow_fringe=sample_color.r>0.82 && sample_color.g>0.58 && sample_color.g<0.84 && sample_color.b<0.16;
	// Key the soft magenta halo left by the generated early atlas without treating
	// ordinary ochre roofs as matte. This removes the pink sticker outline visible
	// around otherwise convincing camp and village silhouettes.
	bool magenta_fringe=sample_color.r>0.48 && sample_color.b>sample_color.g*0.92 && sample_color.r>sample_color.g*1.20;
	bool fringe=red_fringe || yellow_fringe || magenta_fringe;
	// Soft drop shadows generated outside the actual neighborhood footprint become
	// giant dark circles over green terrain. Preserve dark timber/roof pixels, but drop
	// only the near-black translucent matte surrounding the historical cluster.
	bool shadow_matte=source_luma<0.115 && sample_color.a<0.86;
	if(condition>=7.0){
		// DESTROYED is still the same district, not a replacement square decal. Keep
		// foundations and rubble inside the authored plan's former structural footprint.
		// Source luminance recovers the old streets/roof masses; open yards do not become
		// black craters or a translucent green sheet.
		float former_structure=(sample_color.a>=0.10 && !fringe && !shadow_matte) ? 1.0 : 0.0;
		float scar_noise=value_noise(UV*7.0+identity*0.043);
		float rubble_noise=value_noise(UV*21.0+identity*0.119);
		float built_trace=former_structure*smoothstep(0.20,0.50,source_luma);
		float foundation=built_trace*(0.30+0.70*smoothstep(0.28,0.58,scar_noise));
		float rubble=former_structure*smoothstep(0.56,0.80,rubble_noise)*(0.34+0.66*built_trace);
		float ash=former_structure*(1.0-built_trace)*smoothstep(0.64,0.88,scar_noise);
		float ruin_presence=max(max(foundation,rubble),ash*0.52);
		if(ruin_presence<0.055) discard;
		vec3 scar_earth=mix(vec3(0.30,0.275,0.245),vec3(0.185,0.18,0.17),scar_noise);
		vec3 foundation_tone=mix(vec3(0.31,0.29,0.265),vec3(0.46,0.415,0.35),clamp(source_luma*1.65,0.0,1.0));
		vec3 ruin_tone=mix(scar_earth,foundation_tone,foundation*0.82);
		ruin_tone=mix(ruin_tone,vec3(0.58,0.505,0.405),rubble*0.72);
		ALBEDO=max(ruin_tone,vec3(0.11));
		ROUGHNESS=1.0;
		ALPHA=clamp(0.08+foundation*0.40+rubble*0.46+ash*0.12,0.0,0.82);
	}else{
		bool open_yard=sample_color.a<0.10 || fringe || shadow_matte;
		if(open_yard){
			if(preserve_atlas_open_ground) discard;
			// The transparent part of each historical atlas tile is occupied aggregate
			// ground: courts, lanes, work yards and kitchen plots. Retaining a restrained
			// earth pad joins the roofs into one neighborhood design instead of scattering
			// self-contained building stickers across untouched green terrain.
			vec2 centered=abs(UV-vec2(0.5));
			float boundary=max(centered.x,centered.y);
			float edge_noise=(value_noise(UV*5.0+identity*0.029)-0.5)*0.07;
			if(boundary>0.45+edge_noise) discard;
			float distress=condition/6.0;
			float yard_noise=value_noise(UV*8.0+identity*0.061);
			// This is a terrain-blended neighborhood floor, not a square decal: worn
			// courts, lanes, gardens and service yards visually join the roof plans to
			// the shared roads while retaining fine, non-uniform ground variation.
			float court_noise=value_noise(UV*17.0+identity*0.037);
			float garden_patch=smoothstep(0.67,0.88,value_noise(UV*9.0+identity*0.093));
			vec3 maintained_yard=mix(occupied_ground_color,occupied_ground_color*0.72,distress);
			vec3 yard_tone=mix(maintained_yard,maintained_yard*vec3(0.82,0.88,0.72),garden_patch*(0.18+0.18*(1.0-distress)));
			yard_tone*=0.91+court_noise*0.17;
			yard_tone=mix(yard_tone,vec3(0.26,0.31,0.23),distress*yard_noise*0.38);
			ALBEDO=max(yard_tone,vec3(0.12));
			ROUGHNESS=1.0;
			ALPHA=mix(occupied_ground_alpha,occupied_ground_alpha*0.58,distress)*(0.84+yard_noise*0.16);
		}else{
		float fine_breakup=hash21(floor(UV*17.0)+identity);
		float sector_breakup=value_noise(UV*5.2+identity*0.037)*0.72+value_noise(UV*11.0+identity*0.071)*0.28;
		// Peace-time decline never turns an inhabited neighborhood into a black UI
		// glyph. Bad and poor fabric stays occupied; damage removes contiguous pieces.
		// Poverty is inhabited deprivation, not blast damage. Bad/poor districts use
		// maintenance tone and patching; only recorded damage removes broad structures.
		// BAD and POOR are inhabited. They weather and patch; they do not acquire
		// bomb-shaped holes. Only the explicit DAMAGED state loses contiguous fabric.
		bool lost_piece=condition==6.0 && sector_breakup<0.40;
		// The whole ladder must remain readable after roofs collapse to aerial texture.
		// Strong neighborhoods are maintained and sunlit; struggling ones are duller and
		// visibly patched before the separate damaged/destroyed grammar takes over.
		float upkeep=1.24;
		if(condition==1.0) upkeep=1.12;
		else if(condition==2.0) upkeep=1.01;
		else if(condition==3.0) upkeep=0.91;
		else if(condition==4.0) upkeep=0.84;
		else if(condition==5.0) upkeep=0.73;
		else if(condition==6.0) upkeep=0.62;
		vec3 maintained=sample_color.rgb*upkeep;
		float neglect=smoothstep(2.0,6.0,condition);
		vec3 final_tone=mix(maintained,mix(sample_color.rgb,vec3(0.38,0.34,0.29),0.46),neglect*0.62);
		float final_alpha=sample_color.a;
		if(lost_piece){
			final_tone=mix(vec3(0.38,0.33,0.27),final_tone,0.10);
			final_alpha*=0.42;
		}
		if(condition==4.0) final_tone=mix(final_tone,vec3(0.45,0.41,0.34),0.10+fine_breakup*0.08);
		else if(condition==5.0) final_tone=mix(final_tone,vec3(0.39,0.36,0.31),0.20+fine_breakup*0.10);
		if(condition>=6.0 && sector_breakup<0.17){
			final_tone=mix(final_tone,vec3(0.25,0.20,0.16),0.38);
		}
		// Generated source plates deliberately contain enough contrast to survive
		// mipmapping. Compress that contrast here so a district reads as material on
		// the terrain rather than a bright sticker, while preserving its roof pattern.
		float final_luma=dot(final_tone,vec3(0.299,0.587,0.114));
		final_tone=mix(vec3(final_luma),final_tone,aerial_atlas_saturation)*aerial_atlas_exposure;
		// Companion plates carry ordinary whole-neighborhood fabric and intentionally
		// stronger source contrast than the older landmark sheet. Lift only their crushed
		// shadows and compress their chroma so they sit inside the landscape instead of
		// reading as black stickers pasted on top of it.
		if(tile>=16.0 && tile<48.0){
			float companion_luma=dot(final_tone,vec3(0.299,0.587,0.114));
			final_tone+=vec3(0.88,0.84,0.73)*max(0.0,0.30-companion_luma)*0.62;
			float companion_balanced_luma=dot(final_tone,vec3(0.299,0.587,0.114));
			final_tone=mix(vec3(companion_balanced_luma),final_tone,0.74);
		}
		float ground_luma=max(dot(occupied_ground_color,vec3(0.299,0.587,0.114)),0.08);
		final_tone*=mix(vec3(1.0),occupied_ground_color/ground_luma,0.12);
		// Authored aerial sources span very different exposure ranges. Softly bound
		// only their darkest mats and brightest glare so adjoining grids share one
		// city atmosphere without flattening roofs, streets, gardens or materials.
		float composited_luma=max(dot(final_tone,vec3(0.299,0.587,0.114)),0.03);
		float bounded_luma=mix(composited_luma,clamp(composited_luma,0.16,0.68),0.36);
		final_tone*=bounded_luma/composited_luma;
		ALBEDO=max(final_tone,vec3(0.12));
		ROUGHNESS=mix(0.80,1.0,wear);
		ALPHA=final_alpha;
		}
	}
	// The atlas source is a neighborhood plan, not a square decal. Early complete-
	// settlement plans inherit the local terrain atmosphere at their irregular edge;
	// mature cells use the shared road reserve and occupied-ground field instead.
	float tile_edge=min(min(UV.x,1.0-UV.x),min(UV.y,1.0-UV.y));
	if(preserve_atlas_open_ground || tile>=48.0){
		// A complete early settlement includes a trampled clearing, but the clearing
		// must inherit the actual site instead of ending as a pale photographic island.
		// The centre preserves the authored historical plan; the broad outer third picks
		// up local soil/vegetation colour and dissolves gradually into generated terrain.
		float edge_context=smoothstep(0.045,0.34,tile_edge);
		float source_value=clamp(dot(ALBEDO,vec3(0.2126,0.7152,0.0722))/0.43,0.72,1.20);
		vec3 inherited_site=site_ground_color*source_value;
		ALBEDO=mix(inherited_site,ALBEDO,0.24+edge_context*0.76);
		ALPHA*=smoothstep(0.010,0.13,tile_edge);
	}else{
		ALPHA*=smoothstep(0.008,0.035,tile_edge);
	}
	ALPHA*=detail_lod_alpha;
}
"""
	material.shader=shader
	material.set_shader_parameter("atlas_texture",atlas)
	material.set_shader_parameter("companion_atlas_texture",companion_atlas if companion_atlas!=null else atlas)
	material.set_shader_parameter("vernacular_atlas_texture",vernacular_atlas if vernacular_atlas!=null else (companion_atlas if companion_atlas!=null else atlas))
	material.set_shader_parameter("inherited_early_atlas_texture",inherited_early_atlas if inherited_early_atlas!=null else atlas)
	# At settlement scale the ground around compounds stays mostly vegetated. Towns
	# and cities have continuous courts, yards and hard-packed block interiors, which
	# must remain visible after the roofs collapse into aerial texture.
	material.set_shader_parameter("occupied_ground_alpha",0.18 if stage<=2 else (0.70 if stage==3 else (0.62 if modern else 0.66)))
	var inherited_ground:=Color(palette.get("periphery",Color("#6f694f"))).lerp(Color(palette.get("base",Color("#736a52"))),0.42).darkened(0.10)
	if modern: inherited_ground=inherited_ground.lerp(Color("#555750"),0.46)
	material.set_shader_parameter("occupied_ground_color",inherited_ground)
	material.set_shader_parameter("aerial_atlas_exposure",0.90 if stage<=2 else (0.78 if modern else 0.84))
	material.set_shader_parameter("aerial_atlas_saturation",0.76 if stage<=2 else (0.56 if modern else 0.67))
	material.set_shader_parameter("site_ground_color",site_ground_color)
	material.set_shader_parameter("detail_lod_alpha",1.0-smoothstep(1.62,SETTLEMENT_DISTRICT_DETAIL_MAX_ZOOM,camera.size) if camera!=null and stage>=3 else 1.0)
	# Generated early plates reach closer to their 256px cell boundaries. A 7.7px
	# sampling gutter prevents an adjacent row's settlement fragments entering the
	# selected village under mip filtering; mature atlases need only the smaller inset.
	material.set_shader_parameter("atlas_safe_inset",0.030 if stage<=2 else 0.018)
	# Transparent atlas space is the real terrain between aggregate footprints. The
	# generated plate already contains its own streets, courts and trees; filling its
	# bounding square produced the dark pasted-on cards seen in close city views.
	# A camp is one irregular object in the landscape, so its transparent exterior is
	# real terrain. Mature atlas cells are aggregate neighborhoods: their transparent
	# areas are the courts, gardens and work yards that make adjacent plans read as one
	# continuous town. The shader feathers that occupied floor before the road reserve.
	material.set_shader_parameter("preserve_atlas_open_ground",stage<=2)
	return material


func _settlement_district_tile_options(modern:bool,stage:int,land_use:int,architecture:Dictionary)->Array[int]:
	# Early v2 cells are complete settlement footprints. Water-bearing plates
	# (1, 6 and 7) are reserved for a verified shoreline candidate below.
	if stage==0: return [0]
	# Camps grow into open longhouse, courtyard and farmstead plans. Complete
	# palisades/cliff strongholds are excluded here because the separate defense
	# renderer is authoritative; an undefended village must not look fortified.
	if stage in [1,2]:
		# River-bearing cell 14 is also excluded from generic land. As with the
		# coastal cells, visible water may only come from verified geography. Early
		# values bias the dry historical plan—farm lane, lineage hearth, longhouse or
		# crossroads—without inventing walls or an individual-building simulation.
		if not architecture.is_empty() and stage==2:
			match _settlement_dominant_architecture_family(architecture):
				# One aggregate early footprint is visible at a time, so each family gets
				# a distinct dry historical plan: fields, hearth ring, assembly green,
				# work halls, controlled lane, or exchange crossroads.
				"productive": return [13]
				"lineage": return [11]
				"inquiry": return [8]
				"defense": return [9]
				"industry": return [2]
				"exchange": return [10]
		if not architecture.is_empty():
			match _settlement_dominant_architecture_family(architecture):
				"productive": return [9,13,2]
				"lineage": return [11,8,0]
				"inquiry": return [10,8,9]
				"defense": return [11,2,8]
				"industry": return [2,10,9]
				"exchange": return [10,9,8]
		return [0,2,8,9,11] if stage==1 else [2,8,9,11]
	var visual:=_settlement_visual_architecture_profile(architecture)
	var axiality:=clampf(float(visual.get("axiality",0.5)),0.0,1.0)
	var civic_space:=clampf(float(visual.get("civic_space",0.5)),0.0,1.0)
	var defensive_depth:=clampf(float(visual.get("defensive_depth",0.5)),0.0,1.0)
	if modern:
		if land_use==1: return [3,6,8,9,13,15]
		# Tile 14 contains open harbor water and is reserved for verified coasts.
		if land_use==2: return [4,5]
		# A civilization's planning practice controls the family of neighborhoods it
		# repeats. The seed varies members inside that family; it does not randomize the
		# culture into every architectural language in the atlas.
		if axiality>=0.68: return [1,2,3,7,9,10,11,13]
		if civic_space>=0.66: return [0,4,6,8,9,13,15]
		if defensive_depth>=0.66: return [0,1,8,11,12,15]
		return [0,1,2,6,7,9,10,11,12,13,15]
	if land_use==1: return [1,4,7,11,12]
	# Mature-primary tiles 5 and 13 contain canals/harbor water. Productive
	# inland districts use dry workshop/market plates instead.
	if land_use==2: return [4,9,10,14]
	# Mature city cells represent ordinary urban quarters. Fortresses, monasteries
	# and palace compounds are accents; repeating them as the dominant fabric made a
	# large preindustrial city look like a field of identical hives.
	if axiality>=0.68: return [0,3,6,9,10,11,14]
	if civic_space>=0.66: return [0,3,4,6,9,11,14]
	if defensive_depth>=0.66: return [0,6,7,9,12,14]
	return [0,2,3,6,9,11,14]


func _settlement_waterfront_candidate_index(candidates:Array[Dictionary],center:Vector3,radius:float,coastal_profile:Dictionary,shore_only:=false)->int:
	# The early atlas contains painted water, not geometry sampled from this world's
	# coastline. Using it for camps and villages can therefore put a blue inlet under
	# an inland footprint. Keep early settlement plates dry; their coastal livelihood
	# is shown by real shoreline accents and simulation bonuses instead. Mature ports
	# remain eligible only when their aggregate footprint physically reaches the shore.
	if shore_only: return -1
	var visual_gate:=bool(coastal_profile.get("maritime_visual_ready",false))
	if candidates.is_empty() or not visual_gate: return -1
	var coast_direction:=Vector2(coastal_profile.get("coast_direction",Vector2.ZERO))
	if coast_direction.length_squared()<0.000001: return -1
	coast_direction=coast_direction.normalized()
	var coast_side:=Vector2(-coast_direction.y,coast_direction.x)
	var coast_distance:=maxf(0.0,float(coastal_profile.get("nearest_open_water_km",INF)))
	# A port must physically reach the mapped shore. A city several kilometres inland
	# may benefit from a coastal region, but it does not paint a canal through dry land.
	if coast_distance>radius*1.12+0.20: return -1
	var best_index:=-1
	var best_score:=INF
	for index in candidates.size():
		var candidate:Dictionary=candidates[index]
		var relative:=Vector2(candidate.get("point",Vector2(center.x,center.z)))-Vector2(center.x,center.z)
		var shore_error:=absf(relative.dot(coast_direction)-coast_distance)
		var lateral_error:=absf(relative.dot(coast_side))*0.34
		var productive_bonus:=float(candidate.get("cell_size",0.0))*0.28 if int(candidate.get("land_use",0))==2 else 0.0
		var score:=shore_error+lateral_error-productive_bonus
		if relative.dot(coast_direction)<-float(candidate.get("cell_size",0.1)): continue
		if score<best_score:
			best_score=score
			best_index=index
	return best_index


func _settlement_district_companion_tile_options(modern:bool,land_use:int,architecture:Dictionary)->Array[int]:
	# The companion sheet is intentionally ordinary urban fabric. Architectural values
	# choose recurring street/block families while still yielding dozens of combinations
	# after rotation, scale, material weathering and condition are applied.
	if modern:
		if land_use==1: return [5,8,11,13,15]
		if land_use==2: return [3,6,12,14]
	else:
		if land_use==1: return [1,4,5,8,10,11,14]
		if land_use==2: return [3,7,9,13,15]
	var visual:=_settlement_visual_architecture_profile(architecture)
	if modern:
		# Culture biases the mix without reducing a metropolitan region to four
		# repeated stamps. Across both sheets and eight bearings, a close city now
		# exposes dozens of authored neighborhood plans while retaining its grammar.
		if float(visual.get("axiality",0.5))>=0.68: return [0,1,4,5,7,8,9,12,14]
		if float(visual.get("civic_space",0.5))>=0.66: return [1,2,5,7,8,9,10,11,13,15]
		if float(visual.get("defensive_depth",0.5))>=0.66: return [1,3,8,11,12,14,15]
	else:
		if float(visual.get("axiality",0.5))>=0.68: return [1,3,7,9,13,15]
		if float(visual.get("civic_space",0.5))>=0.66: return [1,4,5,8,10,11,14]
		if float(visual.get("defensive_depth",0.5))>=0.66: return [0,2,6,8,10,12]
	return [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15]


func _settlement_district_vernacular_tile_options(land_use:int,architecture:Dictionary,palette:Dictionary)->Array[int]:
	# A civilization's accumulated materials and social form select a recurring family
	# from the global vernacular sheet. This yields adobe, timber, terraced, defensive,
	# riverine and planned urban languages without inventing a building simulation.
	# Cells 3, 10 and 11 contain visible open water. They are never ordinary inland
	# fabric: only the verified waterfront branch below may place them.
	if land_use==1: return [0,6,7,13]
	if land_use==2: return [1,2,5,9,14,15]
	var visual:=_settlement_visual_architecture_profile(architecture)
	if float(visual.get("defensive_depth",0.5))>=0.66: return [8,12,5]
	if float(visual.get("terrain_conformity",0.5))>=0.66: return [4,12,14,2]
	if float(visual.get("axiality",0.5))>=0.68: return [7,13,0,6]
	if float(visual.get("permeability",0.5))>=0.66: return [1,5,9,14,15]
	var organic_share:=float(palette.get("organic_share",0.34))
	var earth_share:=float(palette.get("earth_share",0.33))
	var stone_share:=float(palette.get("stone_share",0.33))
	if earth_share>=maxf(organic_share,stone_share): return [0,1,6,13]
	if organic_share>=stone_share: return [2,4,14,15]
	return [5,7,8,12,13]


func _settlement_architecture_family_scores(architecture:Dictionary)->Dictionary:
	# Six continuous cultural practices compete to shape a bounded share of the city.
	# No founding-focus label is consulted: these weights follow current lived values,
	# and can therefore converge, split or reverse over centuries of play.
	var visual:=_settlement_visual_architecture_profile(architecture)
	var axiality:=float(visual.get("axiality",0.5))
	var permeability:=float(visual.get("permeability",0.5))
	var terrain:=float(visual.get("terrain_conformity",0.5))
	var productive:=float(visual.get("productive_order",0.5))
	var lineage:=float(visual.get("lineage_clustering",0.5))
	var inquiry:=float(visual.get("inquiry_openness",0.5))
	var defense:=float(visual.get("defensive_depth",0.5))
	var industry:=float(visual.get("industrial_intensity",0.5))
	var exchange:=float(visual.get("exchange_network",0.5))
	return {
		"productive":clampf(0.50+0.74*(productive-0.5)+0.16*(terrain-0.5)-0.18*(lineage-0.5),0.0,1.0),
		"lineage":clampf(0.50+0.74*(lineage-0.5)+0.18*(terrain-0.5)-0.16*(productive-0.5)-0.10*(industry-0.5),0.0,1.0),
		"inquiry":clampf(0.50+0.72*(inquiry-0.5)+0.18*(permeability-0.5)-0.14*(exchange-0.5)-0.10*(industry-0.5),0.0,1.0),
		"defense":clampf(0.50+0.72*(defense-0.5)+0.18*(axiality-0.5)-0.16*(permeability-0.5),0.0,1.0),
		"industry":clampf(0.50+0.72*(industry-0.5)+0.18*(axiality-0.5)-0.18*(terrain-0.5)-0.12*(inquiry-0.5),0.0,1.0),
		"exchange":clampf(0.50+0.72*(exchange-0.5)+0.18*(permeability-0.5)-0.14*(inquiry-0.5)-0.12*(defense-0.5),0.0,1.0)
	}


func _settlement_architecture_family_weights(architecture:Dictionary)->Dictionary:
	var scores:=_settlement_architecture_family_scores(architecture)
	var weights:Dictionary={}
	var total:=0.0
	for family in ["productive","lineage","inquiry","industry","exchange","defense"]:
		var weight:=exp(5.0*(float(scores.get(family,0.5))-0.5))
		weights[family]=weight
		total+=weight
	for family in weights: weights[family]=float(weights[family])/maxf(0.0001,total)
	return weights


func _settlement_district_road_grammar(architecture:Dictionary)->Dictionary:
	# Road appearance blends every live cultural motive on the existing fixed edge set.
	# It changes retention, hierarchy and width, never the candidate or surface budget.
	var visual:=_settlement_visual_architecture_profile(architecture)
	var weights:=_settlement_architecture_family_weights(architecture)
	var productive:=float(weights.productive)
	var lineage:=float(weights.lineage)
	var inquiry:=float(weights.inquiry)
	var defense:=float(weights.defense)
	var industry:=float(weights.industry)
	var exchange:=float(weights.exchange)
	var terrain:=float(visual.get("terrain_conformity",0.5))
	var axiality:=float(visual.get("axiality",0.5))
	var permeability:=float(visual.get("permeability",0.5))
	var reach:=productive*0.78+lineage*0.60+inquiry*0.76+defense*0.70+industry*0.88+exchange*0.96
	var bend:=(productive*0.72+lineage*1.20+inquiry*0.78+defense*0.30+industry*0.24+exchange*0.58)*lerpf(0.75,1.28,terrain)*lerpf(1.0,0.72,axiality)
	var mesh:=productive*0.46+lineage*0.34+inquiry*0.92+defense*0.18+industry*0.52+exchange*0.82
	var through:=productive*0.55+lineage*0.24+inquiry*0.70+defense*0.44+industry*0.82+exchange*0.96
	return {
		"reach":reach,"bend":bend,"mesh":mesh,"through":through,
		"hierarchy_ratio":productive*1.22+lineage*1.08+inquiry*1.12+defense*1.72+industry*1.62+exchange*1.38,
		"primary_width":productive*1.08+lineage*0.90+inquiry*0.96+defense*1.28+industry*1.32+exchange*1.18,
		"secondary_width":productive*1.00+lineage*0.90+inquiry*1.04+defense*0.70+industry*0.86+exchange*1.02,
		"keep_scale":clampf(0.86+0.16*float(visual.get("inquiry_openness",0.5))+0.14*float(visual.get("exchange_network",0.5))+0.10*float(visual.get("productive_order",0.5))-0.14*float(visual.get("defensive_depth",0.5)),0.72,1.22),
		"width_scale":clampf(0.82+0.22*float(visual.get("industrial_intensity",0.5))+0.14*float(visual.get("exchange_network",0.5))+0.10*float(visual.get("defensive_depth",0.5)),0.76,1.26),
		"crosslink_scale":clampf(0.72+0.22*mesh+0.14*permeability-0.10*lineage,0.62,1.12)
	}


func _settlement_dominant_architecture_family(architecture:Dictionary)->String:
	var scores:=_settlement_architecture_family_scores(architecture)
	var best_family:="productive"
	var best_score:=-1.0
	for family in ["productive","lineage","inquiry","industry","exchange","defense"]:
		var score:=float(scores.get(family,0.0))
		if score>best_score:
			best_score=score
			best_family=family
	return best_family


func _settlement_architecture_district_family(architecture:Dictionary,seed:int,land_use:=0)->String:
	var scores:=_settlement_architecture_family_scores(architecture)
	var ranked:Array[String]=["productive","lineage","inquiry","industry","exchange","defense"]
	ranked.sort_custom(func(a:String,b:String)->bool: return float(scores.get(a,0.0))>float(scores.get(b,0.0)))
	var primary:=ranked[0]
	var secondary:=ranked[1]
	# Roughly a third to a half of districts carry an unmistakable cultural signature;
	# the remainder preserve mixed ordinary fabric. Functional precincts strengthen a
	# compatible signature without erasing residential, civic and productive variety.
	var signature_percent:=26+roundi(float(scores.get(primary,0.0))*20.0)
	if land_use==2 and primary in ["productive","industry","exchange"]: signature_percent+=10
	elif land_use==1 and primary in ["lineage","inquiry","defense"]: signature_percent+=7
	var roll:=posmod(seed>>3,100)
	if roll<signature_percent: return primary
	if roll<mini(64,signature_percent+10): return secondary
	return "mixed"


func _settlement_district_cultural_tile_options(modern:bool,family:String,land_use:=-1)->Array[int]:
	# Indices are flattened across the primary (0-15), companion (16-31), and
	# historical vernacular (32-47) atlases. Every inland pool excludes authored
	# shore, canal and harbor plates; those remain available only to verified coasts.
	var options:Array[int]=[]
	if modern:
		match family:
			"productive": options=[9,12,17,24,26,29,30]
			"lineage": options=[0,1,2,8,12,17,23,30]
			"inquiry": options=[3,6,8,13,21,27,31]
			"defense": options=[0,1,7,8,12,17,23,24,30,31]
			"industry": options=[4,5,7,19,22,28]
			"exchange": options=[1,4,5,7,10,11,16,19,20,22,25,28]
	else:
		match family:
			"productive": options=[2,15,18,21,24,28,30,34,36,46]
			"lineage": options=[1,8,17,22,26,33,37,45]
			"inquiry": options=[0,9,14,27,39]
			"defense": options=[7,19,25,31,40,44]
			"industry": options=[10,19,23,25,31,33,37]
			"exchange": options=[3,16,20,29,41,47]
	if int(land_use)<0: return options
	# Monumental, industrial and market plates are valuable because they are rare.
	# They may express a cultural value strongly, but only in a compatible functional
	# district. Ordinary residential grids draw from the broad, mid-value urban fabric.
	var allowed:Array[int]
	if modern:
		# The strategic civic-signature renderer already owns true monuments. Close
		# aggregate civic grids therefore use ordinary campus/park/institutional fabric;
		# otherwise every administrative quarter becomes another pasted palace.
		if int(land_use)==1: allowed=[21,24,25,27,29,31]
		elif int(land_use)==2: allowed=[4,5,7,10,11,19,20,22,25,28]
		else: allowed=[0,1,2,10,11,12,16,17,19,20,21,22,23,24,25,26,27,28,29,30,31]
	else:
		if int(land_use)==1: allowed=[0,1,3,6,7,8,9,11,12,14,15,16,22,23,26,27,29,31,32,38,39,45]
		elif int(land_use)==2: allowed=[4,9,10,14,19,23,25,29,31,33,34,37,41,46,47]
		else: allowed=[16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,36,37,38,39,40,41,44,45,46,47]
	var compatible:Array[int]=[]
	for tile in options:
		if tile in allowed: compatible.append(tile)
	# A culture with no specialized plate in this functional class uses the class's
	# ordinary pool; it does not import a palace or factory into a household quarter.
	return compatible if not compatible.is_empty() else allowed


func _settlement_district_balanced_tile_options(modern:bool,stage:int,land_use:int,architecture:Dictionary,seed:int,palette:Dictionary={})->Array[int]:
	# One city may contain dozens of aggregate grids, but it should not repeat one
	# authored plate until it looks stamped. Preserve the civilization's cultural
	# family first, then widen into compatible functional and ordinary fabric. The
	# pool is still finite and deterministic: population never creates more assets.
	var options:Array[int]=[]
	if stage>=3:
		var family:=_settlement_architecture_district_family(architecture,seed,land_use)
		if family!="mixed":
			for tile in _settlement_district_cultural_tile_options(modern,family,land_use):
				if tile not in options: options.append(tile)
		for companion_tile in _settlement_district_companion_tile_options(modern,land_use,architecture):
			var flattened_companion:=16+int(companion_tile)
			if flattened_companion not in options: options.append(flattened_companion)
		if not modern:
			for vernacular_tile in _settlement_district_vernacular_tile_options(land_use,architecture,palette):
				var flattened_vernacular:=32+int(vernacular_tile)
				if flattened_vernacular not in options: options.append(flattened_vernacular)
		for primary_tile in _settlement_district_tile_options(modern,stage,land_use,architecture):
			if primary_tile not in options: options.append(primary_tile)
	else:
		for tile in _settlement_district_tile_options(modern,stage,land_use,architecture):
			options.append(int(tile))
	# Water painted into an atlas plate can only appear in the separately verified
	# waterfront slot. These exclusions also protect future balancing changes.
	var water_tiles:Array=[14,18] if modern else [5,13,35,42,43]
	for index in range(options.size()-1,-1,-1):
		if options[index] in water_tiles: options.remove_at(index)
	return options


func _settlement_district_balanced_tile_index(preferred:int,options:Array[int],usage:Dictionary,seed:int)->int:
	if options.is_empty(): return preferred
	var selected:=preferred if preferred in options else int(options[posmod(seed>>5,options.size())])
	var selected_usage:=int(usage.get(selected,0))
	# Allow the visual motif to repeat once; after that, choose the least-used
	# compatible plan. Seeded traversal prevents every city from filling in the same
	# atlas order while guaranteeing that no single plate dominates the view.
	if selected_usage>=2:
		var start:=posmod(seed>>5,options.size())
		for offset in options.size():
			var candidate:=int(options[(start+offset)%options.size()])
			var candidate_usage:=int(usage.get(candidate,0))
			if candidate_usage<selected_usage:
				selected=candidate
				selected_usage=candidate_usage
				if selected_usage==0: break
	return selected


func _settlement_district_tile_index(modern:bool,stage:int,land_use:int,architecture:Dictionary,seed:int,waterfront:=false,palette:Dictionary={})->int:
	# Open-water coasts use shore and fishing plates. The stilt-wetland plate needs a
	# distinct marsh/shallows geography signal and therefore cannot be a generic coast.
	if waterfront and stage<=2: return [1,7][posmod(seed,2)]
	# Historical waterfronts use the three water-bearing vernacular plates. Their
	# flattened indices are deliberately unreachable from every inland pool above.
	if waterfront and stage>=3: return 14 if modern else 32+[3,10,11][posmod(seed,3)]
	if stage==2:
		# Dense adobe/pueblo plates are a real early architectural branch, not the
		# universal image for every village. They enter only when earth is the dominant
		# accumulated material and the culture favors compact, less-permeable fabric.
		var visual:=_settlement_visual_architecture_profile(architecture)
		var earth_share:=float(palette.get("earth_share",0.0))
		var other_share:=maxf(float(palette.get("organic_share",0.0)),float(palette.get("stone_share",0.0)))
		if earth_share>=other_share+0.10 and float(visual.get("permeability",0.5))<=0.58:
			# Tile 15 is already a dense, multi-storey kasbah and belongs after village
			# scale; an early compact-earth settlement uses low adobe/courtyard forms.
			var compact_earth_options:Array[int]=[5,8,11]
			return compact_earth_options[posmod(seed,compact_earth_options.size())]
	if stage>=3:
		# Culture gets first claim on a bounded signature quota. The rest of the city
		# continues through era, land-use and material selection below, keeping both a
		# recognizable civilization and the 25-50-plan urban variety expected at scale.
		var cultural_family:=_settlement_architecture_district_family(architecture,seed,land_use)
		if cultural_family!="mixed":
			var cultural_options:=_settlement_district_cultural_tile_options(modern,cultural_family,land_use)
			if not cultural_options.is_empty(): return cultural_options[posmod(seed,cultural_options.size())]
		if not modern:
			var visual:=_settlement_visual_architecture_profile(architecture)
			var non_stone_share:=float(palette.get("organic_share",0.34))+float(palette.get("earth_share",0.33))
			var vernacular_preferred:=non_stone_share>=float(palette.get("stone_share",0.33))*0.92 or float(visual.get("terrain_conformity",0.5))>=0.60 or float(visual.get("permeability",0.5))>=0.68
			var family_roll:=posmod(seed,10)
			if vernacular_preferred and family_roll<6:
				var vernacular_options:=_settlement_district_vernacular_tile_options(land_use,architecture,palette)
				return 32+vernacular_options[posmod(seed,vernacular_options.size())]
			if family_roll>=9:
				var historical_options:=_settlement_district_tile_options(false,stage,land_use,architecture)
				return historical_options[posmod(seed,historical_options.size())]
		var companion_options:=_settlement_district_companion_tile_options(modern,land_use,architecture)
		# The primary sheets contain palaces, citadels and other landmarks. They belong
		# in actual civic/productive precincts, not every fifth residential grid. The
		# ordinary companion/vernacular sheets still provide 25–50+ visible plans after
		# cultural selection and shared-grid bearings, while landmarks stay meaningful.
		if land_use>0 and posmod(seed,4)==0:
			var primary_options:=_settlement_district_tile_options(modern,stage,land_use,architecture)
			return primary_options[posmod(seed,primary_options.size())]
		return 16+companion_options[posmod(seed,companion_options.size())]
	# Conditional historical pools are intentionally plain Arrays in GDScript; keep the
	# receiver untyped so the six value-derived early plans remain valid at runtime.
	var tile_options:Array=_settlement_district_tile_options(modern,stage,land_use,architecture)
	return tile_options[posmod(seed,tile_options.size())]


func _create_settlement_district_atlas_clipmap(candidates:Array[Dictionary],damage_ratio:float,parent:Node3D,stage:int,architecture:Dictionary,center:=Vector3.ZERO,radius:=0.0,coastal_profile:Dictionary={},palette:Dictionary={})->bool:
	var modernization_tier:=maxi(clampi(int(ProgressionSystem.domain_tier("infrastructure")),0,8),clampi(int(ProgressionSystem.domain_tier("production")),0,8))
	var modern:=stage>=3 and modernization_tier>=4 and preload("res://scripts/settlement_architecture_knowledge.gd").ceiling()>=11
	var atlas_path:="res://assets/textures/settlement_district_atlas_early_v2.png" if stage<=2 else ("res://assets/textures/settlement_district_atlas_modern_v1.png" if modern else "res://assets/textures/settlement_district_atlas_mature_v1.png")
	var atlas:Texture2D=load(atlas_path)
	if atlas==null: return false
	var companion_path:="res://assets/textures/settlement_district_atlas_modern_v2.png" if modern else "res://assets/textures/settlement_district_atlas_mature_v2.png"
	var companion_atlas:Texture2D=load(companion_path) if stage>=3 else null
	var vernacular_atlas:Texture2D=load("res://assets/textures/settlement_district_atlas_mature_v1.png" if modern else "res://assets/textures/settlement_district_atlas_vernacular_v1.png") if stage>=3 else null
	var inherited_early_atlas:Texture2D=load("res://assets/textures/settlement_district_atlas_early_v2.png") if stage>=3 else null
	var multi:=MultiMesh.new()
	multi.transform_format=MultiMesh.TRANSFORM_3D
	multi.use_custom_data=true
	multi.instance_count=candidates.size()
	multi.mesh=_settlement_district_atlas_mesh()
	var waterfront_index:=_settlement_waterfront_candidate_index(candidates,center,radius,coastal_profile,stage<=2) if stage>=1 else -1
	var tile_usage:Dictionary={}
	for index in candidates.size():
		var candidate:Dictionary=candidates[index]
		var point:=Vector2(candidate.point)
		var seed:=int(candidate.seed)
		var land_use:=clampi(int(candidate.get("land_use",0)),0,2)
		var is_waterfront:=index==waterfront_index
		var is_historic_core:=bool(candidate.get("historic_core",false))
		var tile_index:=int(candidate.get("historic_tile",-1)) if is_historic_core else _settlement_district_tile_index(modern,stage,land_use,architecture,seed,is_waterfront,palette)
		if not is_waterfront and not is_historic_core:
			var balanced_options:=_settlement_district_balanced_tile_options(modern,stage,land_use,architecture,seed,palette)
			tile_index=_settlement_district_balanced_tile_index(tile_index,balanced_options,tile_usage,seed)
		tile_usage[tile_index]=int(tile_usage.get(tile_index,0))+1
		var condition:=clampi(int(candidate.get("condition",_settlement_district_condition(candidate,damage_ratio))),0,7)
		# Condition changes the life inside a grid, never the grid's identity or parcel
		# extent. Roads, roofs, rubble and surface wear carry the eight-state ladder while
		# the same aggregate footprint remains geographically stable from GREAT to DESTROYED.
		if modern and not is_historic_core and not is_waterfront:
			var inherited_generation:=12
			var nearest:=INF
			for plot:Dictionary in GameState.settlement_plots:
				var distance:=Vector2(plot.get("centroid",Vector2.ZERO)).distance_squared_to(point-Vector2(center.x,center.z))
				if distance<nearest:
					nearest=distance;inherited_generation=int(plot.get("fabric_generation",0))
			if inherited_generation<11:
				var historic_options:=_settlement_district_tile_options(false,stage,land_use,architecture)
				tile_index=32+historic_options[posmod(seed,historic_options.size())]
		var condition_scale:=1.0
		# Mature plates nearly meet their cell edges; the transparent gutter and actual
		# street ribbons provide separation. A smaller fill left a green moat around every
		# authored district and made the city look like scattered cards.
		var footprint_fill:float=lerpf(0.86,0.95,float((seed>>11)%1000)/999.0) if stage<=2 else lerpf(0.955,0.985,float((seed>>11)%1000)/999.0)
		var footprint_size:=float(candidate.get("cell_size",0.20))*footprint_fill
		if is_historic_core: footprint_size=float(candidate.get("historic_footprint_size",footprint_size))
		if stage<=2:
			# The early plate is the entire settlement, not one neighborhood. Its
			# physical footprint grows continuously with aggregate occupied radius,
			# capped at twice the authored cell scale before town districts take over.
			footprint_size=minf(maxf(footprint_size,radius*0.48),float(candidate.get("cell_size",0.20))*2.0)
		footprint_size*=condition_scale
		var atlas_angle:=float(candidate.angle)
		if stage>=3 and not is_historic_core:
			# Neighborhood art occupies square grid cells. Arbitrary rotation made those
			# squares overlap as diamonds while the streets remained on the grid, creating
			# clipped card corners and dead road wedges. Quarter-turn variation preserves
			# many plans without breaking the shared city fabric.
			atlas_angle=float(posmod(seed>>7,4))*PI*0.5
		if stage<=2 and candidates.size()==1:
			# The early plan is large enough that a planar quad reads as a floating plate on
			# one side and a row of insect-like slivers where terrain pierces the other.
			# Drape the same aggregate plan over the land; its identity and size do not change.
			multi.mesh=_settlement_district_draped_atlas_mesh(point,atlas_angle,footprint_size)
			multi.set_instance_transform(index,Transform3D.IDENTITY)
		else:
			var basis:=_settlement_district_surface_basis(point,atlas_angle,footprint_size)
			var origin:=Vector3(point.x,_close_surface_height_at(point.x,point.y)+0.0036+footprint_size*0.006,point.y)
			multi.set_instance_transform(index,Transform3D(basis,origin))
		multi.set_instance_custom_data(index,Color(float(tile_index)/63.0,float(condition)/7.0,float((seed>>17)%1000)/999.0,float(land_use)/2.0))
	var instance:=MultiMeshInstance3D.new()
	instance.name="AggregateNeighborhoodFootprints"
	instance.multimesh=multi
	var site_ground_color:=_terrain_color_at(center.x,center.z,_height_at(center.x,center.z))
	instance.material_override=_settlement_district_atlas_material(atlas,stage,modern,companion_atlas,vernacular_atlas,palette,site_ground_color,inherited_early_atlas)
	parent.add_child(instance)
	return true


func _create_settlement_district_clipmap(center:Vector3,layout:Dictionary,stage:int,architecture:Dictionary,damage_ratio:float,palette:Dictionary,parent:Node3D,plots:Array[Dictionary]=[],coastal_profile:Dictionary={})->void:
	var candidates:=_settlement_district_clipmap_candidates(center,layout,stage,architecture)
	if candidates.is_empty(): return
	# Cache the eight-state condition once. The atlas, its footprint and the road fabric
	# therefore express the same aggregate neighborhood state without extra simulation.
	for candidate in candidates:
		candidate["condition"]=_settlement_district_spatial_condition(candidate,damage_ratio,center,plots)
	var visual_architecture:=_settlement_visual_architecture_profile(architecture)
	var monumentality:=clampf(float(visual_architecture.get("monumentality",0.5)),0.0,1.0)
	var infrastructure_tier:=clampi(int(ProgressionSystem.domain_tier("infrastructure")),0,8)
	var height_capability:=clampf(0.24+float(infrastructure_tier)*0.11,0.24,1.0)
	var clipmap_root:=Node3D.new()
	clipmap_root.name="PersistentDistrictClipmap"
	parent.add_child(clipmap_root)
	# Google-Earth inspection always uses one atlas instance per aggregate neighborhood.
	# Era selects the atlas family; it must never switch back to building-like glyphs.
	var uses_atlas:=_create_settlement_district_atlas_clipmap(candidates,damage_ratio,clipmap_root,stage,architecture,center,float(layout.get("radius",0.0)),coastal_profile,palette)
	# Eight mixed-block silhouettes produce many visible combinations after deterministic
	# proportion and roof variation. Civic and productive blocks retain their own batch,
	# for ten fixed draws at any population.
	const MIXED_VARIANT_COUNT:=8
	var groups:Array=[]
	for unused_index in MIXED_VARIANT_COUNT+2: groups.append([])
	for candidate in candidates:
		var candidate_use:=clampi(int(candidate.get("land_use",0)),0,2)
		var group_index:=posmod(int(candidate.get("shape_variant",0)),MIXED_VARIANT_COUNT) if candidate_use==0 else (MIXED_VARIANT_COUNT if candidate_use==1 else MIXED_VARIANT_COUNT+1)
		groups[group_index].append(candidate)
	var organic_share:=float(palette.get("organic_share",0.0))
	var earth_share:=float(palette.get("earth_share",0.0))
	var stone_share:=float(palette.get("stone_share",0.0))
	var atlas:Texture2D=load("res://assets/textures/settlement_roof_material_atlas_late_v1.png") if infrastructure_tier>=4 else load("res://assets/textures/settlement_roof_material_atlas_v1.png")
	# A single bounded dirt-road surface occupies selected shared edges between
	# neighborhoods. Most small lanes are simply terrain gaps in the atlas; only a sparse
	# inherited grid is drawn, avoiding a box around every footprint.
	var occupied_cells:Dictionary={}
	for road_candidate in candidates:
		var road_cell:=Vector2i(road_candidate.cell)
		occupied_cells["%d:%d" % [road_cell.x,road_cell.y]]=true
	var road_surface:=SurfaceTool.new()
	road_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var road_segment_count:=0
	var road_color:Color=(Color("#53514b") if infrastructure_tier>=4 else Color("#625744")).lerp(Color(palette.base),0.16).darkened(0.10)
	road_color.a=1.0
	var road_grammar:=_settlement_district_road_grammar(architecture)
	var through_interval:=clampi(roundi(lerpf(5.0,2.0,float(road_grammar.through))),2,5)
	for road_candidate in candidates:
		var road_cell:=Vector2i(road_candidate.cell)
		var road_cell_size:=float(road_candidate.cell_size)
		var road_condition:=clampi(int(road_candidate.get("condition",3)),0,7)
		var lane_seed:=absi(hash("%d:%d:%d:district_lane" % [GameState.world_seed,road_cell.x,road_cell.y]))
		var early_upkeep_light:float=[0.14,0.085,0.035,0.0,0.0,0.0,0.0,0.0][road_condition]
		var road_tone:=road_color.lightened(early_upkeep_light).darkened(0.035*float(maxi(0,road_condition-3)))
		road_tone.a=1.0 if road_condition<=5 else (0.62 if road_condition==6 else 0.24)
		var east_key:="%d:%d" % [road_cell.x+1,road_cell.y]
		# These are streets between aggregate urban blocks. Healthy districts retain a
		# nearly complete inherited street network; decline progressively loses minor
		# connections, and battle damage breaks the remaining corridors into sections.
		# The atlas plates already contain their internal streets. This surface is only
		# the sparse inherited network between districts, not a border around every tile.
		var stage_road_factor:float=[0.0,0.20,0.36,0.95,1.0,1.0,1.0][clampi(stage,0,6)]
		var road_keep_percent:int=clampi(roundi(float([100,92,84,74,68,56,38,22][road_condition])*stage_road_factor*float(road_grammar.keep_scale)*float(road_grammar.crosslink_scale)),4,98)
		if stage>=3 and road_condition<=3:
			# Maintained towns and cities need a legible connected network. Cultural
			# permeability still changes lanes and hierarchy, but cannot turn healthy
			# neighborhoods back into isolated atlas stamps.
			road_keep_percent=maxi(road_keep_percent,74 if stage==3 else 80)
		var stage_road_width:float=[0.38,0.48,0.68,0.86,1.0,1.0,1.0][clampi(stage,0,6)]
		var road_width_factor:float=float([0.034,0.033,0.032,0.030,0.026,0.022,0.016,0.010][road_condition])*stage_road_width*float(road_grammar.width_scale)
		# Broad through-streets recur every third aggregate row/column; the hashed
		# remainder supplies smaller irregular connections. This makes the atlas cells
		# read as neighborhoods joined by roads instead of unrelated stickers.
		var east_collector:=road_condition<=5 and posmod(road_cell.y,through_interval)==0
		var draw_east:=lane_seed%100<road_keep_percent or east_collector
		if occupied_cells.has(east_key) and draw_east and not (road_condition>=6 and lane_seed%3==0):
			var east_x:=float(road_cell.x+1)*road_cell_size
			var east_start:=Vector2(east_x,float(road_cell.y)*road_cell_size)-Vector2(center.x,center.z)
			var east_finish:=Vector2(east_x,float(road_cell.y+1)*road_cell_size)-Vector2(center.x,center.z)
			if road_condition>=6:
				var east_full_start:=east_start
				var east_full_finish:=east_finish
				var east_kept:=0.70 if road_condition==6 else 0.34
				var east_mid:=lerpf(0.34,0.66,float((lane_seed>>9)%1000)/999.0)
				east_start=east_full_start.lerp(east_full_finish,clampf(east_mid-east_kept*0.5,0.04,0.90))
				east_finish=east_full_start.lerp(east_full_finish,clampf(east_mid+east_kept*0.5,0.10,0.96))
			var east_path:=PackedVector2Array([east_start,east_finish])
			var east_tone:=road_tone.lightened(0.055) if east_collector else road_tone
			road_segment_count+=_append_settlement_system_ribbon(road_surface,center,east_path,road_cell_size*road_width_factor*(1.58 if east_collector else 1.0),east_tone,0.00274,1)
		var south_key:="%d:%d" % [road_cell.x,road_cell.y+1]
		var south_collector:=road_condition<=5 and posmod(road_cell.x,through_interval)==0
		var draw_south:=(lane_seed>>8)%100<road_keep_percent or south_collector
		if occupied_cells.has(south_key) and draw_south and not (road_condition>=6 and lane_seed%4==0):
			var south_z:=float(road_cell.y+1)*road_cell_size
			var south_start:=Vector2(float(road_cell.x)*road_cell_size,south_z)-Vector2(center.x,center.z)
			var south_finish:=Vector2(float(road_cell.x+1)*road_cell_size,south_z)-Vector2(center.x,center.z)
			if road_condition>=6:
				var south_full_start:=south_start
				var south_full_finish:=south_finish
				var south_kept:=0.68 if road_condition==6 else 0.32
				var south_mid:=lerpf(0.34,0.66,float((lane_seed>>14)%1000)/999.0)
				south_start=south_full_start.lerp(south_full_finish,clampf(south_mid-south_kept*0.5,0.04,0.90))
				south_finish=south_full_start.lerp(south_full_finish,clampf(south_mid+south_kept*0.5,0.10,0.96))
			var south_path:=PackedVector2Array([south_start,south_finish])
			var south_tone:=road_tone.lightened(0.055) if south_collector else road_tone
			road_segment_count+=_append_settlement_system_ribbon(road_surface,center,south_path,road_cell_size*road_width_factor*(1.58 if south_collector else 1.0),south_tone,0.00274,1)
	if road_segment_count>0:
		var road_mesh_instance:=MeshInstance3D.new()
		road_mesh_instance.name="DistrictRoadGrid"
		road_mesh_instance.mesh=road_surface.commit()
		var road_material:=ShaderMaterial.new()
		var road_shader:=Shader.new()
		road_shader.code="""
shader_type spatial;
render_mode blend_mix, depth_prepass_alpha, cull_disabled, unshaded;
uniform float detail_lod_alpha = 1.0;
void fragment(){
	ALBEDO=COLOR.rgb;
	ROUGHNESS=1.0;
	ALPHA=COLOR.a*detail_lod_alpha;
}
"""
		road_material.shader=road_shader
		road_material.set_shader_parameter("detail_lod_alpha",1.0-smoothstep(1.62,SETTLEMENT_DISTRICT_DETAIL_MAX_ZOOM,camera.size) if camera!=null else 1.0)
		road_mesh_instance.material_override=road_material
		clipmap_root.add_child(road_mesh_instance)
	if uses_atlas: return
	for group_index in groups.size():
		var group:Array=groups[group_index]
		if group.is_empty(): continue
		var land_use:=0 if group_index<MIXED_VARIANT_COUNT else (1 if group_index==MIXED_VARIANT_COUNT else 2)
		var shape_variant:=group_index if land_use==0 else 0
		var multi:=MultiMesh.new()
		multi.transform_format=MultiMesh.TRANSFORM_3D
		multi.use_colors=true
		multi.instance_count=group.size()
		multi.mesh=_settlement_clipmap_block_mesh(land_use,visual_architecture,shape_variant)
		for index in group.size():
			var candidate:Dictionary=group[index]
			var seed:=int(candidate.seed)
			var point:=Vector2(candidate.point)
			var height_noise:=float((seed>>6)%1000)/999.0
			var radial_t:=float(candidate.radial_t)
			var centre_influence:=float(candidate.get("centre_influence",0.0))
			var width:=float(candidate.half_width)*2.0
			var depth:=float(candidate.half_depth)*2.0
			# Neighborhood identity now comes from the shared compound mesh. Keep only
			# restrained block-size variation so the street wall remains coherent.
			width*=lerpf(0.88,1.06,float((seed>>9)%1000)/999.0)
			depth*=lerpf(0.88,1.06,float((seed>>17)%1000)/999.0)
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
			elif land_use==2: tone=palette.industrial.lerp(tone,0.22).darkened(0.10)
			tone=tone.lerp(Color("#777774"),0.20+height_noise*0.18).lerp(Color("#34312f"),damage_ratio*0.58)
			# The roof photograph supplies joints, tile, sheet or masonry; vertex color
			# provides civilization material, district purpose and war condition.
			tone=tone.lerp(Color.WHITE,0.20)
			tone.a=1.0
			multi.set_instance_color(index,tone)
		var instance:=MultiMeshInstance3D.new()
		instance.name=("MixedQuarters%d" % (shape_variant+1)) if land_use==0 else (["","CivicCenters","ProductiveBands"][land_use])
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
		material.cull_mode=BaseMaterial3D.CULL_DISABLED
		instance.material_override=material
		clipmap_root.add_child(instance)


func _create_settlement_stage_landscape(center:Vector3,profile:Dictionary,plots:Array[Dictionary],lod:int,parent:Node3D,defense_snapshot:Dictionary={})->void:
	rendered_settlement_stage_radius=0.0
	var stage:=clampi(int(profile.get("stage",0)),0,6)
	if defense_snapshot.is_empty(): defense_snapshot=MilitaryCampaign.settlement_defense_snapshot()
	var defense_profile:=_settlement_defense_visual_profile(defense_snapshot)
	# Founding camps and hamlets now use the same aggregate historical-compound grammar
	# as later settlements, at smaller fixed budgets. They no longer fall back to tiny
	# per-plot roof marks simply because their stage predates the old landscape layer.
	var population:=maxi(1,footprint_population if footprint_population>=0 else GameState.population_total)
	var layout:=_settlement_stage_visual_layout(profile,population,plots)
	var radius:=float(layout.radius)
	rendered_settlement_stage_radius = radius
	if _organic_town_enabled():
		var flat := SurfaceTool.new()
		var mass := SurfaceTool.new()
		flat.begin(Mesh.PRIMITIVE_TRIANGLES)
		mass.begin(Mesh.PRIMITIVE_TRIANGLES)
		var counts := _append_settlement_defense_visuals(flat, mass, center, layout, population, int(defense_profile.stage), float(defense_profile.integrity), 1.0, false, plots)
		if int(defense_profile.project_stage) > int(defense_profile.stage) and float(defense_profile.project_progress) > 0.0:
			var construction := _append_settlement_defense_visuals(flat, mass, center, layout, population, int(defense_profile.project_stage), 1.0, float(defense_profile.project_progress), true, plots)
			counts.flat += construction.flat
			counts.mass += construction.mass
		if int(counts.flat) > 0: _commit_settlement_surface(flat, "PersistentSettlementDefenseGround", parent, true)
		if int(counts.mass) > 0: _commit_settlement_surface(mass, "PersistentSettlementDefenseMassing", parent, false)
		return
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
	var road_grammar:=_settlement_district_road_grammar(architecture)
	var infrastructure_tier:=clampi(int(ProgressionSystem.domain_tier("infrastructure")),0,8)
	var production_tier:=clampi(int(ProgressionSystem.domain_tier("production")),0,8)
	var vertical_capability:=clampf(0.16+float(infrastructure_tier)*0.15,0.16,1.0)
	var urban_surface:=SurfaceTool.new()
	urban_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var strategic_density_surface:=SurfaceTool.new()
	strategic_density_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var mobility_surface:=SurfaceTool.new()
	mobility_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var open_space_surface:=SurfaceTool.new()
	open_space_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var mass_surface:=SurfaceTool.new()
	mass_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Fortifications must survive close inspection even when the legacy strategic civic
	# massing retires beneath the aggregate neighborhood atlas. Keeping defense in its
	# own two bounded surfaces prevents old white/tan proxy blocks from leaking through.
	var defense_flat_surface:=SurfaceTool.new()
	defense_flat_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var defense_mass_surface:=SurfaceTool.new()
	defense_mass_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var urban_count:=0
	var strategic_density_count:=0
	var mobility_count:=0
	var open_space_count:=0
	var mass_count:=0
	var defense_flat_count:=0
	var defense_mass_count:=0
	var damage_ratio:=_settlement_stage_damage_ratio(plots)
	var palette:=_settlement_stage_material_palette(plots,stage,architecture)
	var coastal_visual_profile:=_settlement_coastal_visual_profile(Vector2(center.x,center.z))
	# A town is already a coherent area of occupied land at map scale. Keeping stage 3
	# on the legacy overlapping-patch path made it a pile of translucent polygons while
	# cities used the scalable Google-Earth density field.
	# Mature close inspection and strategic zoom overlap through one bounded crossfade:
	# the atlas neighborhoods fade out while this terrain-draped field fades in. Keeping
	# both geometries through the transition removes the hard 2.4 km identity swap.
	var use_unified_density_field:=stage>=3
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
	# Strategic urbanization is land cover, not a translucent analytics overlay. Towns
	# retain some terrain; metropolitan cores become substantially opaque so overlapping
	# bounded patches merge into one city instead of stacking as gray paper polygons.
	urban_tone.a=float([0.42,0.48,0.58,0.70,0.80,0.87,0.91][stage])
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
			var dense_tone:Color=palette.dense.darkened(0.11+late_urban_maturity*0.055)
			dense_tone=dense_tone.lerp(Color("#45413e"),damage_ratio*0.48)
			dense_tone.a=minf(0.96,urban_tone.a+0.06)*(1.0 if index==0 else 0.92)*core_reveal
			urban_count+=_append_settlement_stage_patch(urban_surface,world_center,maxf(0.022,core_radius*0.64),dense_tone,0.00231,Vector2i(1,0),layout_seed+37+index*101,6,1.30,0.86,float(layout.axis)+float(index%2)*PI*0.5)
		# Seven high-intensity knots are enough to read the complete megaregional
		# hierarchy; the eighth core keeps its dense contour while preserving the
		# strict sub-5,000-vertex unengineered world-city budget.
		if stage>=4 and index<7:
			var center_tone:Color=palette.center.darkened(0.060+late_urban_maturity*0.030)
			center_tone=center_tone.lerp(Color("#484442"),damage_ratio*0.52)
			center_tone.a=minf(0.98,urban_tone.a+0.08)*(1.0 if index==0 else 0.88)*core_reveal
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
		urban_count+=_append_settlement_stage_patch(urban_surface,Vector3(center.x+local_center.x,0.0,center.z+local_center.y),maxf(0.008,satellite_radius),satellite_tone,0.00212,Vector2i(1,0),layout_seed+700+index*83,14,1.64,0.70,float(layout.axis)+float(index%2)*PI*0.5)
	if use_unified_density_field:
		strategic_density_count=_append_settlement_strategic_density_field(strategic_density_surface,center,radius,render_cores,render_satellites,layout_seed,palette,damage_ratio,stage,visual_architecture,plots,coastal_visual_profile)
	var corridor_angles:Array=layout.corridor_angles
	# Polycentric urban regions need inhabited connective tissue, not islands of gray
	# mist joined only by hairline roads. Each satellite receives one broad, bent,
	# fixed-budget development corridor to an inherited core. Population widens and
	# lengthens these aggregate ribbons; it never increases their count.
	if stage>=4 and not render_satellites.is_empty():
		for connector_index in render_satellites.size():
			var connector_start:Vector2=render_cores[connector_index%render_cores.size()]
			var connector_finish:Vector2=render_satellites[connector_index]
			var connector_delta:=connector_finish-connector_start
			if connector_delta.length_squared()<0.00001: continue
			var connector_side:=Vector2(-connector_delta.y,connector_delta.x).normalized()
			var connector_bend:=connector_side*connector_delta.length()*rng.randf_range(-0.105,0.105)*lerpf(1.18,0.42,axiality)*lerpf(0.78,1.24,terrain_conformity)*lerpf(0.76,1.24,clampf(float(road_grammar.bend),0.0,1.0))
			var connector_points:=PackedVector2Array([connector_start,connector_start.lerp(connector_finish,0.34)+connector_bend,connector_start.lerp(connector_finish,0.68)-connector_bend*0.44,connector_finish])
			var connector_tone:Color=urban_tone.lerp(periphery_tone,0.44)
			connector_tone.a=0.48+float(stage)*0.035
			var connector_width:=clampf(radius*(0.020+permeability*0.007)*float(road_grammar.secondary_width),0.075,6.5)
			urban_count+=_append_settlement_fabric_ribbon(urban_surface,center,connector_points,connector_width,connector_tone,0.00216,3)
	# Bounded neighborhood lobes grow around inherited cores and satellite towns.
	# Earlier versions placed them on corridor bearings, making the whole metropolis
	# a diagrammatic star. The centres now define the urban region; transport merely
	# stitches it together. These remain aggregate land-cover samples, never houses.
	# Villages are still completely represented by their persistent plot ledger.
	# Regional district abstraction begins with towns, after the bounded historical
	# plot sample can no longer cover the whole population-derived footprint.
	var district_patch_count:=0 if stage<3 and not plots.is_empty() else int(layout.district_patches)
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
		var patch_radius_min:float=float([0.0,0.0,0.18,0.115,0.10,0.085,0.070][stage])
		var patch_radius_max:float=float([0.0,0.0,0.29,0.185,0.165,0.145,0.125][stage])
		var patch_radius:=radius*rng.randf_range(patch_radius_min,patch_radius_max)*lerpf(1.08,0.88,radial_t)*lerpf(0.30,1.0,patch_reveal)
		var patch_tone:Color=urban_tone.lerp(periphery_tone,radial_t*0.66)
		# Roof age, function and local material practice create visible neighborhood
		# variation without inventing more plots or buildings.
		var neighborhood_variant:=float(absi(hash("%d:%d:district_tone" % [layout_seed,patch_index]))%1000)/999.0
		if neighborhood_variant<0.34: patch_tone=patch_tone.darkened(0.035+neighborhood_variant*0.08)
		elif neighborhood_variant>0.70: patch_tone=patch_tone.lightened((neighborhood_variant-0.70)*0.16)
		if patch_index%7==0: patch_tone=patch_tone.lerp(Color(palette.get("industrial",patch_tone)),0.18)
		elif patch_index%5==0: patch_tone=patch_tone.lerp(Color(palette.get("civic",patch_tone)),0.12)
		patch_tone.a*=lerpf(0.99,0.86,radial_t)*patch_reveal
		var organic_alignment:=patch_angle+0.63*sin(float(layout_seed%97)+float(patch_index)*1.37)
		var formal_alignment:=float(layout.axis)+float((patch_index+anchor_index)%2)*PI*0.5
		var formal_weight:=lerpf(0.04,0.94,axiality)*lerpf(1.0,0.68,terrain_conformity)
		var district_alignment:=_lerp_undirected_angle(organic_alignment,formal_alignment,formal_weight)
		var district_elongation:=lerpf(2.04,1.48,axiality)*lerpf(1.0,1.16,terrain_conformity)
		# Silhouette complexity decreases as each patch summarizes more territory. Shader
		# grain supplies the sub-district edge at world-city scale, keeping a billion-person
		# megalopolis under the strict 5,000-vertex strategic budget.
		var district_segments:=13 if stage<=4 else (10 if stage==5 else 6)
		urban_count+=_append_settlement_stage_patch(urban_surface,Vector3(center.x+patch_offset.x,0.0,center.z+patch_offset.y),maxf(0.025,patch_radius),patch_tone,0.00218,Vector2i(1,0),layout_seed+2400+patch_index*109,district_segments,district_elongation,0.59,district_alignment)
		# Town and city neighborhoods grow out from inherited lanes rather than appearing
		# as disconnected gray islands. At later polycentric stages the satellite-to-core
		# corridors above take over, so this fixed set exists only for stages three/four.
		if stage in [3,4] and anchor.distance_to(patch_offset)>0.025:
			var district_delta:=patch_offset-anchor
			var district_side:=Vector2(-district_delta.y,district_delta.x).normalized()
			var district_bend:=district_side*district_delta.length()*0.11*sin(float(layout_seed%127)+float(patch_index)*1.73)*lerpf(1.18,0.38,axiality)
			var district_path:=PackedVector2Array([anchor,anchor.lerp(patch_offset,0.48)+district_bend,patch_offset])
			var district_connector_tone:=patch_tone
			district_connector_tone.a=(0.16+float(stage)*0.016)*patch_reveal
			urban_count+=_append_settlement_fabric_ribbon(urban_surface,center,district_path,clampf(patch_radius*0.14,0.014,0.34),district_connector_tone,0.00217,3)
		# Mature districts do not have one uniform built intensity. A fixed subset earns
		# a smaller inner fabric inherited at later stages, producing visible town-centre,
		# station-quarter and neighborhood hierarchy without adding simulated buildings.
		if stage>=3 and patch_index%3==0 and patch_index<15:
			var district_core_tone:Color=palette.dense.darkened(0.18+late_urban_maturity*0.08).lerp(patch_tone,radial_t*0.28)
			district_core_tone.a=minf(0.97,urban_tone.a+0.05)*lerpf(1.0,0.88,radial_t)*patch_reveal
			urban_count+=_append_settlement_stage_patch(urban_surface,Vector3(center.x+patch_offset.x,0.0,center.z+patch_offset.y),maxf(0.016,patch_radius*rng.randf_range(0.40,0.56)),district_core_tone,0.00234,Vector2i(3,2),layout_seed+6200+patch_index*137,7,1.48,0.84,district_alignment)
	# A town does not sit inside untouched wilderness. If the authoritative ledger has
	# active cultivated land, a fixed six/eight-patch belt summarizes its broader food
	# landscape. This is aggregate land cover: population changes extent, never count.
	# Metropolitan stages omit it here because their food systems are no longer safely
	# inferred from the founding settlement's bounded local field sample.
	var field_plots:Array[Dictionary]=[]
	for plot in plots:
		if String(plot.get("land_use",""))=="field" and String(plot.get("status","active")) not in ["ruin","reclaimed","vacant"]: field_plots.append(plot)
	if stage in [3,4] and not field_plots.is_empty():
		var agricultural_count:=6 if stage==3 else 8
		for field_index in agricultural_count:
			var source_field:Dictionary=field_plots[field_index%field_plots.size()]
			var organic_angle:=float(layout.axis)+2.39996323*float(field_index+1)+rng.randf_range(-0.16,0.16)
			var formal_angle:=float(layout.axis)+float(field_index%4)*PI*0.5+float(field_index/4)*PI*0.25
			var field_alignment:=_lerp_undirected_angle(organic_angle,formal_angle,axiality*0.58)
			field_alignment=_lerp_undirected_angle(field_alignment,_terrain_contour_angle(Vector2(center.x,center.z)+Vector2.from_angle(organic_angle)*radius*0.74,field_alignment),terrain_conformity*0.78)
			var field_distance:=radius*lerpf(0.60,0.91,float(field_index+1)/float(agricultural_count))*rng.randf_range(0.88,1.08)
			var field_offset:=_settlement_stage_resolve_land_offset(center,Vector2.from_angle(organic_angle)*field_distance)
			var field_color:=_settlement_plot_color(source_field).lerp(Color("#556343"),0.18+civic_space*0.08)
			field_color.a=0.29 if stage==3 else 0.24
			var field_radius:=radius*rng.randf_range(0.050,0.085)*(0.92 if stage==4 else 1.0)
			open_space_count+=_append_settlement_stage_patch(open_space_surface,Vector3(center.x+field_offset.x,0.0,center.z+field_offset.y),field_radius,field_color,0.00212,Vector2i(1,2),layout_seed+8100+field_index*149,8,lerpf(2.30,1.72,axiality),0.36,field_alignment)
			open_space_count+=_append_settlement_field_mosaic(open_space_surface,center,field_offset,field_radius,field_alignment,field_color,layout_seed+9100+field_index*173)
	# The oldest civic nucleus carries the civilization's value-derived architectural
	# signature at every later scale. It is committed into the existing two batches.
	if not render_cores.is_empty():
		var civic_signature:=_append_settlement_civic_signature(urban_surface,mass_surface,center,render_cores[0],float(layout.axis),radius,stage,visual_architecture,palette,damage_ratio)
		urban_count+=int(civic_signature.flat)
		mass_count+=int(civic_signature.mass)
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
		if index>=primary_approach_count and render_satellites.is_empty(): continue
		var corridor_reveal:=clampf(float(corridor_reveals[index]) if index<corridor_reveals.size() else 1.0,0.0,1.0)
		var angle:float=corridor_angles[index]
		var direction:=Vector2.from_angle(angle)
		if index%2==1: direction=-direction
		var side:=Vector2(-direction.y,direction.x)
		var bend_strength:=lerpf(1.30,0.26,axiality)*lerpf(0.78,1.34,terrain_conformity)*lerpf(0.76,1.24,clampf(float(road_grammar.bend),0.0,1.0))
		var bend:=side*radius*rng.randf_range(-0.055,0.055)*bend_strength
		var points:=PackedVector2Array()
		var district_connector:=index>=primary_approach_count and not render_satellites.is_empty()
		if district_connector:
			# Later corridors stitch satellite centres into the inherited cores. They
			# must not become more giant spokes through the same central pixel.
			var connector_index:=index-primary_approach_count
			if render_satellites.size()>=2 and connector_index>=render_satellites.size()-1: continue
			if render_satellites.size()==1 and connector_index>0: continue
			var satellite:Vector2=render_satellites[connector_index]
			var destination:Vector2=render_satellites[connector_index+1] if render_satellites.size()>=2 else render_cores[(connector_index+1)%render_cores.size()]
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
		occupied_arm_color.a=(0.30+float(stage)*0.025)*corridor_reveal
		var grammar_width:=float(road_grammar.secondary_width if district_connector else road_grammar.primary_width)
		var occupied_half_width:=radius*((0.016 if district_connector else 0.019)+float(stage)*0.0024)*grammar_width*lerpf(0.32,1.0,corridor_reveal)
		urban_count+=_append_settlement_fabric_ribbon(urban_surface,center,points,clampf(occupied_half_width,0.014,1.35),occupied_arm_color,0.00222,6)
		var corridor_width:=clampf(radius*(0.0024+float(stage)*0.00042)*grammar_width,0.0022,0.115)
		var corridor_color:=urban_tone.lerp(Color("#655e53"),0.62).lightened(axiality*0.035)
		corridor_color=corridor_color.lerp(Color("#514b47"),damage_ratio*0.48)
		corridor_color.a=(0.155+float(stage)*0.007+permeability*0.028)*corridor_reveal
		mobility_count+=_append_settlement_system_ribbon(mobility_surface,center,points,corridor_width,corridor_color,0.0030,48,damage_ratio,layout_seed+index*131)
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
		mobility_count+=_append_settlement_system_ring(mobility_surface,center,ring_radius,float(layout.axis),ring_index,ring_width,ring_color,layout_seed,damage_ratio)
	var wedge_reveals:Array=layout.get("wedge_reveals",[])
	for wedge_index in int(layout.green_wedges):
		var wedge_reveal:=clampf(float(wedge_reveals[wedge_index]) if wedge_index<wedge_reveals.size() else 1.0,0.0,1.0)
		var wedge_angle:=float(layout.axis)+TAU*(float(wedge_index)+0.63)/maxf(1.0,float(layout.green_wedges))+rng.randf_range(-0.16,0.16)
		var direction:=Vector2.from_angle(wedge_angle)
		var green_color:=Color("#294d39").lerp(Color("#3f5b3d"),civic_space*0.28)
		green_color.a=(0.30+civic_space*0.12)*wedge_reveal
		var green_offset:=direction*radius*rng.randf_range(0.30,0.67)
		green_offset=_settlement_stage_resolve_land_offset(center,green_offset)
		open_space_count+=_append_settlement_stage_patch(open_space_surface,Vector3(center.x+green_offset.x,0.0,center.z+green_offset.y),radius*rng.randf_range(0.060,0.115)*lerpf(0.82,1.18,civic_space)*lerpf(0.28,1.0,wedge_reveal),green_color,0.00245,Vector2i(2,0),layout_seed+4700+wedge_index*127,12,2.18,0.62,wedge_angle)
		# A mature green wedge continues inward as a park, drainage or ceremonial
		# corridor. It breaks the gray mass into terrain-responsive districts while
		# remaining a fixed number of triangles.
		if stage>=4 and not render_cores.is_empty():
			var green_start:Vector2=render_cores[wedge_index%render_cores.size()]
			var green_side:=Vector2(-direction.y,direction.x)
			var green_path:=PackedVector2Array([green_start,green_start.lerp(green_offset,0.52)+green_side*radius*rng.randf_range(-0.035,0.035),green_offset])
			open_space_count+=_append_settlement_fabric_ribbon(open_space_surface,center,green_path,clampf(radius*(0.010+civic_space*0.008),0.032,2.8),green_color,0.00249,3)
	if stage>=4:
		# Large workshop roofs remain plot-derived. A separate logistics/industrial
		# belt only appears once aggregate production has genuinely industrialized.
		var industrial_count:=mini(stage-2,maxi(0,production_tier-2))
		for index in industrial_count:
			var industrial_angle:=float(layout.axis)+PI*0.5+TAU*float(index)/float(industrial_count)+rng.randf_range(-0.20,0.20)
			var local_center:=Vector2.from_angle(industrial_angle)*radius*rng.randf_range(0.54,0.78)
			local_center=_settlement_stage_resolve_land_offset(center,local_center)
			var industrial_color:Color=palette.industrial
			industrial_color.a=0.72
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
	# Defense is authoritative at every settlement stage. Early camps and villages use
	# the same bounded defense surfaces at close zoom; an atlas tile never invents walls.
	var close_physical_defense:=lod==0
	var defense_flat_target:=defense_flat_surface if close_physical_defense else urban_surface
	var defense_mass_target:=defense_mass_surface if close_physical_defense else mass_surface
	var defense_counts:=_append_settlement_defense_visuals(defense_flat_target,defense_mass_target,center,layout,population,int(defense_profile.stage),float(defense_profile.integrity),1.0,false,plots)
	if close_physical_defense:
		defense_flat_count+=int(defense_counts.flat)
		defense_mass_count+=int(defense_counts.mass)
	else:
		urban_count+=int(defense_counts.flat)
		mass_count+=int(defense_counts.mass)
	if int(defense_profile.project_stage)>int(defense_profile.stage) and float(defense_profile.project_progress)>0.0:
		var construction_counts:=_append_settlement_defense_visuals(defense_flat_target,defense_mass_target,center,layout,population,int(defense_profile.project_stage),1.0,float(defense_profile.project_progress),true,plots)
		if close_physical_defense:
			defense_flat_count+=int(construction_counts.flat)
			defense_mass_count+=int(construction_counts.mass)
		else:
			urban_count+=int(construction_counts.flat)
			mass_count+=int(construction_counts.mass)
	# Close inspection uses actual terrain, route/plot geometry and the compound clipmap.
	# Strategic land-cover patches at this scale become translucent polygons over roofs,
	# so they retire completely before the close kit appears.
	if use_unified_density_field and strategic_density_count>0:
		_commit_settlement_surface(strategic_density_surface,"PersistentUrbanSystems",parent,true)
	elif urban_count>0 and lod>0:
		_commit_settlement_surface(urban_surface,"PersistentUrbanSystems",parent,true)
	if mobility_count>0 and lod>0: _commit_settlement_surface(mobility_surface,"PersistentMetropolitanMobility",parent,true)
	# The unified field already contains bounded canopy/open-ground variation. Overlaying
	# the old polygon wedges recreated the translucent-paper artifact it replaces.
	if open_space_count>0 and lod>0 and not use_unified_density_field: _commit_settlement_surface(open_space_surface,"PersistentUrbanOpenSpace",parent,true)
	if mass_count>0 and lod>0: _commit_settlement_surface(mass_surface,"PersistentUrbanMassing",parent,false)
	if defense_flat_count>0: _commit_settlement_surface(defense_flat_surface,"PersistentSettlementDefenseGround",parent,true)
	if defense_mass_count>0: _commit_settlement_surface(defense_mass_surface,"PersistentSettlementDefenseMassing",parent,false)
	# Do not replace the continuous aerial settlement with authored photo tiles at
	# close zoom.  The atlas clipmap produced a conspicuous ring of rectangular,
	# historically incompatible neighbourhood photographs.  The strategic density
	# field now remains the source of truth through the closest settlement view.

func _settlement_claim_fill_alpha(base_alpha:float)->float:
	if camera==null: return base_alpha
	# Close inspection leaves relief, roofs and fields dominant. Strategic zoom
	# strengthens the same restrained wash enough to make ownership legible.
	if camera.size<=SETTLEMENT_DISTRICT_DETAIL_MAX_ZOOM: return 0.0
	var close_reveal:=smoothstep(SETTLEMENT_DISTRICT_DETAIL_MAX_ZOOM,4.4,camera.size)
	return base_alpha*close_reveal*lerpf(0.30,1.0,smoothstep(SETTLEMENT_DISTRICT_DETAIL_MAX_ZOOM,180.0,camera.size))

func _update_settlement_claim_opacity()->void:
	if settlement_border_root==null: return
	var wash:=settlement_border_root.get_node_or_null("ControlledGroundWash") as MeshInstance3D
	if wash==null: return
	var material:=wash.material_override as StandardMaterial3D
	if material==null: return
	material.albedo_color=Color(1,1,1,_settlement_claim_fill_alpha(1.0))

const TERRITORY_WASH:=Color("#A8782A")
const TERRITORY_BAND:=preload("res://scripts/territory_border_band.gd")
const RESOURCE_ICONS:=preload("res://scripts/resource_icons.gd")
const TERRITORY_INK:=Color("#1E150D")

## One screen pixel in kilometres at the current zoom bucket (the same bucket
## as the network view key), so ink widths are stable between rebuilds.
func _territory_ink_pixel_km()->float:
	if camera==null: return 0.002
	var zoom_bucket:=roundi(log(maxf(0.10,camera.size))/log(1.8))
	return pow(1.8,float(zoom_bucket))/900.0

## The boundary pulled toward its centre by a fixed distance: the painted edge
## band sits inside the territory instead of straddling the border.
func _inset_boundary(boundary:PackedVector2Array,distance:float)->PackedVector2Array:
	if boundary.size()<3: return boundary
	var center:=Vector2.ZERO
	for point in boundary: center+=point
	center/=float(boundary.size())
	var inset:=PackedVector2Array()
	for point in boundary:
		var to_center:=center-point
		var reach:=to_center.length()
		inset.append(point+to_center/reach*minf(distance,reach*0.5) if reach>0.000001 else point)
	return inset

func _append_settlement_claim_fill(surface:SurfaceTool,boundary:PackedVector2Array,color:Color,lift:=0.0032,samples:RefCounted=null)->int:
	if boundary.size()<3: return 0
	var center:=Vector2.ZERO
	for point in boundary: center+=point
	center/=float(boundary.size())
	for index in boundary.size():
		for point in [center,boundary[index],boundary[(index+1)%boundary.size()]]:
			surface.set_color(color)
			surface.add_vertex(Vector3(point.x,(samples.height_at(point.x,point.y) if samples else _height_at(point.x,point.y))+lift,point.y))
	return boundary.size()

func _append_settlement_boundary_ribbon(surface:SurfaceTool,boundary:PackedVector2Array,half_width:float,color:Color,lift:=0.006,samples:RefCounted=null)->int:
	if boundary.size()<3: return 0
	for index in boundary.size():
		var a:=boundary[index]
		var b:=boundary[(index+1)%boundary.size()]
		# Render-only tessellation follows intervening relief while the authoritative
		# border remains the fixed 32-point aggregate polygon. Subdivision is selected by
		# view scale, never claim radius or population: a billion-person civilization must
		# not allocate more border vertices simply because its territory is physically vast.
		var subdivisions:=_border_ribbon_subdivisions()
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
				surface.add_vertex(Vector3(point.x,(samples.height_at(point.x,point.y) if samples else _height_at(point.x,point.y))+lift,point.y))
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
	# Each place's stage selects its inked chart glyph (map_glyph.gdshader).
	multi.use_custom_data=true
	multi.instance_count=marker_set.size()
	multi.mesh=QuadMesh.new()
	# Preserve an almost fixed screen-space weight through regional, continental and
	# planetary zoom. The former 3 km cap reduced every world city below one pixel.
	var marker_radius:=clampf(camera.size*0.0032,0.055,64.0) if camera!=null else 0.055
	var marker_profiles:Array[Dictionary]=[]
	for index in marker_set.size():
		var settlement:Dictionary=marker_set[index]
		var visual_profile:=_settlement_expansion_visual_profile(settlement)
		var position_value:Variant=settlement.get("position",Vector2.ZERO)
		var position_2d:Vector2=position_value if position_value is Vector2 else Vector2.ZERO
		var origin:=Vector3(position_2d.x,_height_at(position_2d.x,position_2d.y)+0.004,position_2d.y)
		multi.set_instance_transform(index,Transform3D(Basis().scaled(Vector3.ONE*marker_radius*float(visual_profile.marker_scale)),origin))
		multi.set_instance_custom_data(index,Color(float(visual_profile.stage),0.0,0.0,0.0))
		marker_profiles.append(visual_profile)
	var blips:=MultiMeshInstance3D.new()
	blips.name="SecondarySettlementBlips"
	blips.multimesh=multi
	blips.set_meta("marker_profiles",marker_profiles)
	blips.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	blips.material_override=_map_glyph_material(true)
	settlement_network_marker_root.add_child(blips)
	_update_secondary_settlement_blips()
	var label_limit:=_secondary_settlement_label_limit()
	if prioritized.size()>label_limit: prioritized.resize(label_limit)
	for index in prioritized.size():
		var settlement:Dictionary=prioritized[index]
		var position_value:Variant=settlement.get("position",Vector2.ZERO)
		var position_2d:Vector2=position_value if position_value is Vector2 else Vector2.ZERO
		var label:=Label3D.new()
		label.name="SecondarySettlementLabel_%d" % index
		var controller:=String(settlement.get("occupied_by",""))
		label.set_meta("city_civilization_id",controller if controller!="" else "player")
		label.set_meta("city_map_id",String(settlement.id))
		label.set_meta("city_map_anchor",Vector3(position_2d.x,_height_at(position_2d.x,position_2d.y)+.004,position_2d.y))
		label.text=_city_map_label(String(settlement.get("name","Settlement")),int(settlement.get("population",0)))
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
		_update_city_flag(label)


func _update_secondary_settlement_blips()->void:
	if camera==null or settlement_network_marker_root==null:return
	var blips:=settlement_network_marker_root.get_node_or_null("SecondarySettlementBlips") as MultiMeshInstance3D
	if blips==null or blips.multimesh==null:return
	var profiles:Array=blips.get_meta("marker_profiles",[])
	var any_visible:=false
	var radius:=clampf(camera.size*0.0032,0.055,64.0)
	# Names remain visible independently. Each city's locator retires at the same
	# threshold as the primary city's, leaving physical buildings unobscured.
	# Update on camera motion, not only when the settlement network rebuilds.
	for index in mini(profiles.size(),blips.multimesh.instance_count):
		var profile:Dictionary=profiles[index]
		var size:=radius*float(profile.marker_scale) if camera.size>_settlement_stage_marker_zoom(profile) else 0.0
		any_visible=any_visible or size>0.0
		var placement:=blips.multimesh.get_instance_transform(index)
		placement.basis=Basis().scaled(Vector3.ONE*size)
		blips.multimesh.set_instance_transform(index,placement)
	blips.visible=any_visible


## Shared materials for the inked settlement glyphs (map_glyph.gdshader).
var map_glyph_materials:Dictionary={}
func _map_glyph_material(per_instance:bool,fixed_px:float=0.0,home:=false)->ShaderMaterial:
	var key:="%s:%s:%s" % [per_instance,fixed_px,home]
	if map_glyph_materials.has(key):return map_glyph_materials[key]
	var material:=ShaderMaterial.new()
	material.shader=preload("res://scripts/map_glyph.gdshader")
	material.set_shader_parameter("glyphs",RESOURCE_ICONS.settlement_atlas())
	material.set_shader_parameter("glyph_count",float(RESOURCE_ICONS.SETTLEMENT_GLYPH_COUNT))
	material.set_shader_parameter("use_instance_glyph",per_instance)
	material.set_shader_parameter("fixed_diameter_px",fixed_px)
	if home:
		# The people's own place is always findable: never smaller than a
		# glance-sized mark, and circled in one fine gold ring (the sacred colour).
		material.set_shader_parameter("min_diameter_px",40.0)
		material.set_shader_parameter("max_diameter_px",56.0)
		material.set_shader_parameter("home_ring",true)
	# Above route and border ink (up to 18), below army counters and labels.
	material.render_priority=19
	map_glyph_materials[key]=material
	return material


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


func _create_secondary_city_design(settlement:Dictionary,parent:Node3D,force:=false)->bool:
	var record:Dictionary=SettlementModel.settlement_record(String(settlement.get("id","")))
	if record.is_empty() or bool(record.get("primary",false)): return false
	SettlementModel._ensure_city_resources(record)
	var point:Vector2=record.position
	var center:=Vector3(point.x,0,point.y)
	# Lambdas capture locals by value, so outcomes travel in a dictionary.
	var outcome:={"rebuilt":true,"primed":false}
	# A city ledger changes daily. Its buildings only need new meshes when
	# their actual appearance or the camera's detail requirements change.
	var trace=preload("res://scripts/performance_trace.gd")
	SettlementModel.with_city_resources(String(record.id),func()->void:
		var stamp:int=trace.start()
		var lod:=_settlement_morphology_lod()
		var signature:=str([center,lod,_settlement_morphology_view_signature(lod),_settlement_morphology_visual_signature(),_settlement_architecture_signature(_settlement_architecture_profile())])
		stamp=trace.mark("city_design_signature",stamp)
		var fabric:Node3D=null
		for child in parent.get_children():
			if String(child.get_meta("city_id",""))==String(record.id):fabric=child;break
		if not force and fabric!=null and String(fabric.get_meta("visual_signature",""))==signature:
			outcome.rebuilt=false
			return
		# The layout and the meshes land in separate map ticks; any old drawing
		# stays up meanwhile.
		if _prime_organic_town_plan(center):
			outcome.primed=true
			return
		if fabric!=null:parent.remove_child(fabric);fabric.queue_free()
		fabric=Node3D.new();fabric.name="CityDesign_"+String(record.id)
		fabric.set_meta("city_id",String(record.id));fabric.set_meta("visual_signature",signature)
		parent.add_child(fabric)
		var plots:Array[Dictionary]=SettlementModel.plots_for_lod(lod)
		stamp=trace.mark("city_design_plots_for_lod",stamp)
		_create_plot_fabric(center,plots,lod,fabric)
		stamp=trace.mark("city_design_plot_fabric",stamp)
		_create_persistent_settlement_routes(center,GameState.settlement_routes,fabric)
		trace.mark("city_design_routes",stamp)
	)
	if outcome.primed:pending_city_designs.push_front([settlement,force])
	return bool(outcome.rebuilt)

func _create_secondary_settlement_footprints(settlements:Array[Dictionary],force:=false)->void:
	var parent:Node3D=settlement_network_fabric_root if settlement_network_fabric_root!=null else settlement_network_marker_root
	if parent==null:return
	var visible_ids:Dictionary={}
	pending_city_designs.clear()
	for settlement in settlements:
		var profile:=_settlement_expansion_visual_profile(settlement)
		if camera!=null and camera.size>_settlement_stage_landscape_max_zoom(profile):continue
		visible_ids[String(settlement.id)]=true
		pending_city_designs.append([settlement,force])
	# Towns whose buildings changed are redrawn one per map tick, so a monthly
	# change to several towns never lands in a single frame.
	_advance_pending_city_designs()
	for child in parent.get_children():
		if child.has_meta("city_id") and not visible_ids.has(String(child.get_meta("city_id",""))):
			parent.remove_child(child);child.queue_free()

## Secondary towns still to check or redraw; see _advance_pending_city_designs.
var pending_city_designs:Array=[]

## Redraws at most one changed town; towns whose drawing is current cost only
## a signature check. Runs with each map network tick until the queue is empty.
func _advance_pending_city_designs()->void:
	var parent:Node3D=settlement_network_fabric_root if settlement_network_fabric_root!=null else settlement_network_marker_root
	if parent==null:pending_city_designs.clear();return
	while not pending_city_designs.is_empty():
		var entry:Array=pending_city_designs.pop_front()
		if _create_secondary_city_design(entry[0],parent,bool(entry[1])):return

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

func _retain_small_settlement_fabric()->bool:
	# Small towns fit in one bounded batch; camera motion cannot change them.
	# Large/dispersed settlements retain the existing culling and LOD budgets.
	if GameState.settlement_plots.is_empty() or GameState.settlement_plots.size()>96 or GameState.settlement_routes.size()>128:return false
	for plot:Dictionary in GameState.settlement_plots:
		if Vector2(plot.get("centroid",Vector2.ZERO)).length_squared()>1.0:return false
	for route:Dictionary in GameState.settlement_routes:
		for point:Vector2 in route.get("points",PackedVector2Array()):
			if point.length_squared()>4.0:return false
	return true

func _settlement_morphology_lod() -> int:
	if _retain_small_settlement_fabric():return 1
	if camera == null:
		return 1
	# Camera3D stores `size` as a 32-bit value, so an authored 2.40 can arrive a
	# few millionths above the crossover. Keep the two render systems touching at
	# the boundary instead of briefly dropping the aggregate district fabric.
	if camera.size <= SETTLEMENT_DISTRICT_DETAIL_MAX_ZOOM + 0.001:
		return 0 # bounded aggregate neighborhoods, nearby routes, yards and scars
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
	if lod<0: return false
	if String(plot.get("status","active")) not in ["active","stressed","damaged","under_construction"]: return false
	if String(plot.get("land_use","")) in ["field","pasture","water","waste","temporary_encampment","vacant","ruin"]: return false
	var budget:=384 if lod<=1 else SETTLEMENT_AGGREGATE_DENSITY_BUDGET
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
	# Architecture is a compact civilization-level style field. It never creates
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
	# Cultural practices start close together and drift gradually. A tighter visual
	# response lets their district and road grammar read from the air without altering
	# any simulation outcome or requiring one object per building.
	for key in ["productive_order","lineage_clustering","inquiry_openness","industrial_intensity","exchange_network"]:
		visual[key]=smoothstep(0.40,0.60,clampf(float(profile.get(key,0.5)),0.0,1.0))
	return visual

func _settlement_architecture_signature(profile:Dictionary)->String:
	# Quantization lets slow cultural drift become visible without rebuilding batched
	# settlement meshes for imperceptible floating-point changes every simulation day.
	var parts:Array[String]=[]
	for key in ["axiality","monumentality","civic_space","permeability","defensive_depth","terrain_conformity","productive_order","lineage_clustering","inquiry_openness","industrial_intensity","exchange_network"]:
		parts.append(str(roundi(clampf(float(profile.get(key,0.5)),0.0,1.0)*20.0)))
	return ":".join(parts)


func _settlement_morphology_visual_signature()->String:
	# Simulation records legitimately change more often than their aerial appearance.
	# Hash only visible categories and coarse tone buckets so high time speeds do not
	# rebuild every mesh because prosperity moved by a thousandth. The authoritative
	# state remains continuous; this signature controls presentation work only.
	var social_condition_key:="%d:%d:%d:%d:%d" % [
		roundi(clampf(GameState.population_health,0.0,1.0)*5.0),
		roundi(clampf(GameState.food_security,0.0,1.0)*5.0),
		roundi(clampf(float(GameState.simulation_metrics.get("cohesion",0.58)),0.0,1.0)*5.0),
		roundi(clampf(float(GameState.simulation_metrics.get("material_capacity",0.12)),0.0,1.0)*5.0),
		roundi(clampf(float(GameState.simulation_metrics.get("legitimacy",0.62)),0.0,1.0)*5.0)
	]
	var cache_key:="%s:%d:%d:%s" % [GameState.resource_settlement_id,GameState.morphology_revision,int(GameState.elapsed_days/365.0),social_condition_key]
	var cached:Array=cached_morphology_visual_signatures.get(GameState.resource_settlement_id,[])
	if not cached.is_empty() and cached[0]==cache_key: return cached[1]
	var plot_hash:=0
	for plot in GameState.settlement_plots:
		var centroid:=Vector2(plot.get("centroid",Vector2.ZERO))
		var visual_record:="%d|%s|%s|%s|%s|%s|%s|%d|%d|%d|%d|%d|%d|%d|%d|%d" % [
			int(plot.get("id",0)),String(plot.get("land_use","")),String(plot.get("form","")),
			String(plot.get("material_family","")),String(plot.get("roof_plan","")),String(plot.get("status","")),
			String(plot.get("cultivation_phase","")),int(plot.get("fabric_generation",0)),int(plot.get("storeys",1)),
			# Five tone steps: monthly drift of a few percent must not rebuild a town.
			roundi(clampf(float(plot.get("condition",1.0)),0.0,1.0)*5.0),
			roundi(clampf(float(plot.get("prosperity",0.4)),0.0,1.0)*5.0),
			roundi(clampf(float(plot.get("service_access",0.35)),0.0,1.0)*5.0),
			roundi(clampf(float(plot.get("maintenance_debt",0.0)),0.0,1.0)*5.0),
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
	var signature:="%d:%d:%d:%d:%d:%d:%s" % [GameState.settlement_plots.size(),GameState.settlement_routes.size(),GameState.settlement_nuclei.size(),plot_hash,route_hash,nuclei_hash,social_condition_key]
	cached_morphology_visual_signatures[GameState.resource_settlement_id]=[cache_key,signature]
	return signature

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
		color = Color("#756d54") if String(plot.get("form",""))=="carried_water_point" else Color("#586f6b")
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
		if cultivation_phase=="growing":
			# Crop-family palettes describe the mature canopy. New growth is greener;
			# grain must not look harvest-gold immediately after it starts growing.
			color=color.lerp(Color("#38603c"),0.62)
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
	var mix:Dictionary=plot.get("visual_material_mix",plot.get("material_mix",{})) if not plot.get("building_materials",{}).is_empty() else plot.get("material_mix",{})
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
		elif node_name=="PersistentDesirePaths": fabric_kind=8
		elif node_name=="PersistentYardVariation": fabric_kind=2
		material=_settlement_fabric_material(fabric_kind,0.74 if fabric_kind==1 else (0.62 if fabric_kind==3 else 0.48))
		if fabric_kind==1: material.set_shader_parameter("cultivation_rows",node_name=="PersistentCultivationRows")
	elif node_name=="PersistentWallFabric":
		material=_settlement_wall_material()
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
	if node_name=="PersistentUrbanOpenSpace": material.render_priority=3
	elif node_name in ["PersistentUrbanSystems","SecondaryUrbanSystems"]: material.render_priority=2
	elif node_name=="PersistentMetropolitanMobility": material.render_priority=4
	else: material.render_priority = 2 if "Ground" in node_name else (4 if "Roof" in node_name else 3)
	instance.material_override = material
	parent.add_child(instance)

func _settlement_wall_material()->ShaderMaterial:
	var material:=ShaderMaterial.new()
	if settlement_wall_shader==null:
		settlement_wall_shader=Shader.new()
		settlement_wall_shader.code="""
shader_type spatial;
render_mode blend_mix,cull_disabled;
varying vec3 wall_world_position;
void vertex(){ wall_world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
void fragment(){
	// Camera-independent mesh colors; pixel coverage controls the aerial fade.
	float pixel_span=max(length(dFdx(wall_world_position)),length(dFdy(wall_world_position)));
	float aerial_wall=smoothstep(0.00030,0.0015,pixel_span);
	ALBEDO=mix(COLOR.rgb,vec3(0.408,0.392,0.353),aerial_wall*0.34);
	ALPHA=COLOR.a*mix(1.0,0.46,aerial_wall);
	ROUGHNESS=0.96;
}
"""
	material.shader=settlement_wall_shader
	return material

func _settlement_fabric_material(fabric_kind:int,grain_strength:float)->ShaderMaterial:
	if settlement_fabric_shader==null:
		settlement_fabric_shader=Shader.new()
		settlement_fabric_shader.code="""
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, diffuse_burley, specular_disabled, depth_test_disabled;
uniform float grain_strength = 0.5;
uniform int fabric_kind = 0;
uniform bool cultivation_rows = false;
uniform float aerial_lod = 0.0;
uniform sampler2D material_atlas : source_color, filter_linear_mipmap, repeat_disable;
uniform sampler2D roof_material_atlas : source_color, filter_linear_mipmap, repeat_disable;
uniform sampler2D late_roof_material_atlas : source_color, filter_linear_mipmap, repeat_disable;
uniform sampler2D strategic_district_atlas : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform sampler2D strategic_district_companion_atlas : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform sampler2D strategic_district_vernacular_atlas : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform int strategic_district_modern = 1;
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
float strategic_district_tile(float roll,float family) {
	// One deterministic cultural field selects from every era-appropriate sheet.
	// The previous implementation used only one 16-cell atlas at strategic zoom,
	// creating obvious repeated stamps and bypassing the richer close-view language.
	float sheet_roll=fract(roll*5.371+family*0.197);
	float variant_roll=fract(roll*13.731+family*0.113);
	float tile=0.0;
	if(strategic_district_modern>0){
		if(sheet_roll<0.38){
			// Fifteen dry primary plates; 14 is the authored harbor and stays coast-only.
			tile=floor(variant_roll*15.0);
			if(tile>=14.0) tile+=1.0;
			return tile;
		}
		return 16.0+floor(variant_roll*16.0);
	}
	if(sheet_roll<0.28){
		// Fourteen dry mature-primary plates; 5 and 13 visibly contain water.
		tile=floor(variant_roll*14.0);
		if(tile>=5.0) tile+=1.0;
		if(tile>=13.0) tile+=1.0;
		return tile;
	}
	if(sheet_roll<0.72) return 16.0+floor(variant_roll*16.0);
	// Thirteen dry vernacular plates; 3, 10 and 11 are real waterfront scenes.
	tile=floor(variant_roll*13.0);
	if(tile>=3.0) tile+=1.0;
	if(tile>=10.0) tile+=2.0;
	return 32.0+tile;
}
vec4 sample_strategic_district(float tile,vec2 local_uv) {
	float local_tile=mod(tile,16.0);
	vec2 atlas_cell=vec2(mod(local_tile,4.0),floor(local_tile/4.0));
	vec2 safe_uv=mix(vec2(0.018),vec2(0.982),local_uv);
	vec4 result=texture(strategic_district_atlas,(atlas_cell+safe_uv)/4.0);
	if(tile>=16.0) result=texture(strategic_district_companion_atlas,(atlas_cell+safe_uv)/4.0);
	if(tile>=32.0) result=texture(strategic_district_vernacular_atlas,(atlas_cell+safe_uv)/4.0);
	return result;
}
vec2 vary_strategic_district_uv(vec2 local_uv,vec2 cell,float seed) {
	// One authored plate yields eight map-safe bearings through quarter turns and
	// reflection. Combined with sixteen ordinary plates this prevents visible stamped
	// repetition without adding textures, instances, simulation records or draw calls.
	float variant=floor(hash21(cell+vec2(seed*157.0,seed*211.0))*8.0);
	vec2 point=local_uv-vec2(0.5);
	if(mod(variant,2.0)>0.5) point.x=-point.x;
	float turn=floor(variant*0.5);
	if(turn>0.5 && turn<1.5) point=vec2(-point.y,point.x);
	else if(turn>1.5 && turn<2.5) point=-point;
	else if(turn>2.5) point=vec2(point.y,-point.x);
	return point+vec2(0.5);
}
float strategic_structure_survival(float condition,vec2 local_point,vec2 cell) {
	// Decline is not destruction. Bad districts remain substantially occupied;
	// damaged and destroyed districts lose contiguous sectors of their aggregate
	// roof image while their land cover and inherited street pattern remain.
	float breakup=value_noise(cell*0.37+floor(local_point*vec2(5.0,4.0))*0.71+vec2(17.0,-23.0));
	// GREAT through POOR are all inhabited; maintenance and roads distinguish them.
	// Only recorded physical damage removes roof sectors, and surviving sectors retain
	// full visual strength instead of being multiplied into haze.
	if(condition<6.0) return 1.0;
	if(condition<7.0) return step(0.45,breakup);
	return step(0.84,breakup);
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
	float urban_roof_coverage=0.0;
	if ((fabric_kind==0 || fabric_kind==1 || fabric_kind==2 || fabric_kind==3 || fabric_kind==7 || fabric_kind==8) && UV.x>=0.0 && UV.y>=0.0) {
		// World units are kilometres. Material detail repeats in metres rather
		// than stretching once from one parcel corner to the other. Fields retain
		// their simulated row geometry above this base grain; roofs retain their
		// individual course/repair overlays.
		// Roof cells cover roughly a 3.8 m span. The former 1.6 m repetition forced
		// mipmapping to average reed bindings and board joints into a flat colour.
		float physical_frequency=fabric_kind==3 ? 260.0 : (fabric_kind==1 ? 165.0 : ((fabric_kind==2 || fabric_kind==7 || fabric_kind==8) ? 230.0 : 120.0));
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
		} else if (fabric_kind==1) {
			// Crop and cultivation phase already choose the vertex palette. Keep
			// that signal; the dirt photograph supplies surface variation, not a
			// replacement crop color shared by every field in every season.
			float field_surface_value=clamp(source_luma/0.50,0.74,1.24);
			fabric=COLOR.rgb*field_surface_value;
		} else if (fabric_kind==8) {
			// A saved lane's surface tier supplies its earth/stone/paving color.
			// Reuse grain, not the dirt photograph's hue, on every road era.
			float road_surface_value=clamp(source_luma/0.50,0.80,1.18);
			fabric=COLOR.rgb*road_surface_value;
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
		// Built land should interrupt green terrain as roofs, paving and worked yards,
		// not sit above it as pale atmospheric haze. Keep the close crossover readable,
		// then compress exposure harder as blocks merge into regional land cover.
		vec3 close_fabric=COLOR.rgb*(0.56+block*0.18+infill*0.08);
		vec3 strategic_fabric=COLOR.rgb*(0.43+metropolitan_grain*0.14+regional_grain*0.07);
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
		// District roads are meaningful around city zoom, but must integrate into
		// land cover at continental scale. Otherwise one 1-2 km grid becomes a
		// screen-wide sheet of graph paper when the camera pulls back.
		float neighborhood_visibility=1.0-smoothstep(0.018,0.065,pixel_span);
		float regional_visibility=smoothstep(0.025,0.065,pixel_span)*(1.0-smoothstep(0.11,0.30,pixel_span));
		float raw_family=floor(UV2.y+0.001);
		bool packed_strategic_field=raw_family>=8.0;
		float packed_state=fract(UV2.y)*16.0;
		float district_condition=packed_strategic_field ? floor(packed_state+0.001) : 3.0;
		float encoded_family=packed_strategic_field ? raw_family-8.0 : 0.0;
		bool maritime_district=encoded_family>=4.0 && encoded_family<8.0;
		float district_family=maritime_district ? encoded_family-4.0 : encoded_family;
		float district_seed=packed_strategic_field ? fract(packed_state) : fract(UV2.y);
		float road_survival=1.0;
		if(district_condition>0.5) road_survival=0.97;
		if(district_condition>1.5) road_survival=0.94;
		if(district_condition>2.5) road_survival=0.90;
		if(district_condition>3.5) road_survival=0.78;
		if(district_condition>4.5) road_survival=0.57;
		if(district_condition>5.5) road_survival=0.35;
		if(district_condition>6.5) road_survival=0.18;
		// The eight neighborhood conditions remain legible after individual roofs
		// collapse into aerial land cover. Great-to-normal is maintenance and canopy;
		// bad/poor is inhabited weathering; only damaged/destroyed receives scars.
		float condition_upkeep=1.12;
		if(district_condition>0.5) condition_upkeep=1.07;
		if(district_condition>1.5) condition_upkeep=1.02;
		if(district_condition>2.5) condition_upkeep=0.97;
		if(district_condition>3.5) condition_upkeep=0.90;
		if(district_condition>4.5) condition_upkeep=0.82;
		if(district_condition>5.5) condition_upkeep=0.94;
		if(district_condition>6.5) condition_upkeep=0.92;
		fabric*=condition_upkeep;
		if(district_condition>=4.0){
			float service_wear=value_noise(urban_point*vec2(0.66,0.58)+vec2(district_seed*41.0,-17.0));
			float neglect=smoothstep(3.0,5.0,district_condition);
			vec3 worn_ground=mix(COLOR.rgb*0.72,vec3(0.31,0.30,0.25),service_wear*0.46);
			// BAD and POOR retain every occupied roof sector, so deferred maintenance
			// has to read through irregular resurfacing, service wear and canopy loss.
			fabric=mix(fabric,worn_ground,neglect*(0.30+service_wear*0.22));
		}
		if(district_condition>=6.0){
			// Physical damage leaves a broad, contiguous record even where roofs are gone:
			// burned/cleared sectors plus the inherited foundations and street geometry.
			// This layer covers the existing bounded city mesh and adds no objects or draws.
			float scar_sample=value_noise(urban_point*vec2(0.31,0.27)+vec2(83.0,district_seed*59.0));
			// DAMAGED needs a plainly readable but still irregular affected sector at
			// ordinary city zoom. DESTROYED uses a narrower, harsher burn field and the
			// persistent ruin record below instead of making the entire footprint uniform.
			float scar_field=district_condition<7.0 ? smoothstep(0.23,0.62,scar_sample) : smoothstep(0.29,0.70,scar_sample);
			// Foundations survive, but not as an infinite clean lattice. Coarse destroyed
			// sectors shift and interrupt the inherited street trace; the trace itself
			// retires above regional LOD while the broad irregular scar remains.
			vec2 foundation_sector=floor(urban_point*vec2(0.43,0.39)+vec2(district_seed*3.0,district_seed*5.0));
			vec2 foundation_warp=vec2(value_noise(foundation_sector*0.71+vec2(19.0,47.0)),value_noise(foundation_sector*0.67+vec2(-31.0,13.0)))-vec2(0.5);
			vec2 foundation_cell=abs(fract((urban_point+foundation_warp*0.46)*vec2(0.36,0.31)+vec2(district_seed*7.0,district_seed*11.0))-0.5);
			float foundation_patch=smoothstep(0.47,0.68,value_noise(foundation_sector*0.83+vec2(71.0,district_seed*37.0)));
			float foundation_lod=max(neighborhood_visibility,regional_visibility*0.46);
			float foundation_trace=(1.0-smoothstep(0.028,0.080,min(foundation_cell.x,foundation_cell.y)))*foundation_patch*foundation_lod;
			float ruin_level=district_condition<7.0 ? 0.54 : 0.72;
			vec3 scar_tone=mix(vec3(0.29,0.275,0.245),COLOR.rgb*0.46,0.30);
			fabric=mix(fabric,scar_tone,ruin_level*(0.22+scar_field*0.28));
			fabric=mix(fabric,vec3(0.48,0.43,0.36),foundation_trace*ruin_level*(district_condition<7.0 ? 0.08 : 0.12));
		}
		// Close settlement texture is generated from the same continuous field as the
		// distant city.  These are aggregate blocks and courtyards, not individual
		// buildings and never pasted aerial photographs.
		vec2 neighborhood_point=urban_point*vec2(3.55,3.18);
		// Inherited streets bend locally; strongly axial cultures retain straighter
		// alignments. The field stays world anchored as the camera moves.
		vec2 street_warp=vec2(value_noise(urban_point*1.7+vec2(29.0,11.0)),value_noise(urban_point*1.9+vec2(-17.0,43.0)))-vec2(0.5);
		neighborhood_point+=street_warp*(district_family==1.0 ? 0.035 : 0.24);
		vec2 neighborhood_local=fract(neighborhood_point);
		vec2 neighborhood_cell=floor(neighborhood_point);
		vec2 neighborhood_edge=min(neighborhood_local,vec2(1.0)-neighborhood_local);
		float neighborhood_break=value_noise(neighborhood_cell*0.73+vec2(district_seed*53.0,19.0));
		float lane_aa=max(fwidth(neighborhood_point.x),fwidth(neighborhood_point.y))*0.5;
		float local_lane=1.0-smoothstep(0.007,0.016+lane_aa,min(neighborhood_edge.x,neighborhood_edge.y));
		float occupied_block=step(0.08+neighborhood_break*0.20,hash21(neighborhood_cell+vec2(31.0,district_seed*67.0)));
		float neighborhood_survival=strategic_structure_survival(district_condition,neighborhood_local,neighborhood_cell);
		float block_tone=0.72+neighborhood_break*0.30;
		vec3 neighborhood_detail=COLOR.rgb*block_tone;
		fabric=mix(fabric,neighborhood_detail,occupied_block*neighborhood_survival*neighborhood_visibility*0.46);
		// Forty-eight deterministic layout variants combine courts, parallel rows,
		// detached compounds and dense infill. These are flat aerial roof coverage,
		// not modern building photos or new per-resident scene objects.
		float layout_variant=floor(hash21(neighborhood_cell+vec2(district_seed*173.0,59.0))*48.0);
		float layout_form=mod(layout_variant,6.0);
		vec2 plot_frequency=vec2(12.0,10.0);
		if(layout_form==1.0) plot_frequency=vec2(8.0,15.0);
		if(layout_form==2.0) plot_frequency=vec2(15.0,8.0);
		if(layout_form==3.0) plot_frequency=vec2(9.0,9.0);
		vec2 parcel_local=vary_strategic_district_uv(neighborhood_local,neighborhood_cell,district_seed+0.17);
		vec2 roof_point=parcel_local*plot_frequency;
		vec2 roof_cell=floor(roof_point);
		vec2 roof_local=fract(roof_point);
		float roof_roll=hash21(roof_cell+neighborhood_cell*19.0+vec2(layout_variant,73.0));
		float roof_cross_roll=hash21(roof_cell+neighborhood_cell*23.0+vec2(41.0,layout_variant));
		vec2 roof_center=vec2(0.5)+(vec2(roof_roll,roof_cross_roll)-vec2(0.5))*0.20;
		vec2 roof_extent=mix(vec2(0.27,0.24),vec2(0.43,0.40),vec2(roof_cross_roll,roof_roll));
		vec2 roof_edge=roof_extent-abs(roof_local-roof_center);
		float roof_aa=max(fwidth(roof_point.x),fwidth(roof_point.y))*0.55;
		float roof_mask=smoothstep(-roof_aa,roof_aa,min(roof_edge.x,roof_edge.y));
		if(layout_form==3.0 && roof_roll>0.4){
			float court_distance=max(abs(roof_local.x-roof_center.x),abs(roof_local.y-roof_center.y));
			roof_mask*=smoothstep(0.13-roof_aa,0.13+roof_aa,court_distance);
		}
		roof_mask*=step(layout_form==5.0 ? 0.30 : 0.12,roof_roll)*(1.0-local_lane);
		float roof_resolved=1.0-smoothstep(0.006,0.025,pixel_span);
		vec2 shadow_edge=roof_extent-abs(roof_local-roof_center-vec2(0.055,0.075));
		float roof_shadow=smoothstep(-roof_aa,roof_aa,min(shadow_edge.x,shadow_edge.y))*(1.0-roof_mask);
		fabric=mix(fabric,COLOR.rgb*0.38,roof_shadow*occupied_block*neighborhood_survival*roof_resolved*0.38);
		float roof_color_roll=mix(neighborhood_break,roof_roll,roof_resolved);
		vec3 roof_tone=COLOR.rgb*mix(0.82,1.28,roof_color_roll);
		roof_tone=mix(roof_tone,vec3(0.48,0.43,0.34),0.22);
		float roof_plane=smoothstep(-roof_aa,roof_aa,roof_local.x-roof_center.x);
		roof_plane=mix(0.5,roof_plane,roof_resolved);
		float roof_weather=value_noise(urban_point*370.0+vec2(layout_variant*3.0,roof_roll*19.0));
		roof_weather=mix(0.5,roof_weather,1.0-smoothstep(0.25,0.75,pixel_span*370.0));
		roof_tone*=0.82+roof_plane*0.16+roof_weather*0.08;
		if(district_condition<6.0) roof_tone*=condition_upkeep;
		// Integrate sub-pixel roofs to their mean coverage rather than erasing them.
		// At regional altitude, the 300 m neighborhood is still several pixels wide.
		urban_roof_coverage=mix(0.44,roof_mask,roof_resolved)*occupied_block*neighborhood_survival*neighborhood_visibility;
		fabric=mix(fabric,roof_tone,urban_roof_coverage*0.86);
		if(district_condition>=6.0){
			// Lost roofs leave broken foundations and aggregate rubble, not virgin
			// ground. Reuse their footprint and survival masks; no new structures.
			float lost_structure=occupied_block*(1.0-neighborhood_survival);
			float foundation_edge=1.0-smoothstep(0.025,0.075+roof_aa,min(roof_edge.x,roof_edge.y));
			float debris_break=value_noise(roof_point*vec2(2.7,3.1)+neighborhood_cell*13.0);
			float debris_detail=1.0-smoothstep(0.18,0.55,max(fwidth(roof_point.x),fwidth(roof_point.y))*3.1);
			debris_break=mix(0.5,debris_break,debris_detail);
			float ruin_trace=roof_mask*mix(0.30,0.85,foundation_edge)*smoothstep(0.24,0.65,debris_break);
			vec3 rubble_tone=mix(COLOR.rgb*0.94,vec3(0.56,0.52,0.45),0.35+roof_cross_roll*0.30);
			fabric=mix(fabric,rubble_tone,ruin_trace*lost_structure*roof_resolved*neighborhood_visibility*0.78);
		}
		float garden_interior=smoothstep(0.015,0.18,min(neighborhood_edge.x,neighborhood_edge.y));
		vec3 garden_tone=mix(COLOR.rgb*0.78,vec3(0.22,0.27,0.16),0.38);
		if(district_condition<6.0){
			// Existing unbuilt neighborhood ground is mottled canopy and worn access,
			// not a blank rectangular plate. This adds no simulated park or tree.
			float garden_noise=value_noise(neighborhood_local*vec2(7.0,6.0)+neighborhood_cell*19.0+vec2(district_seed*37.0,61.0));
			float garden_detail=1.0-smoothstep(0.006,0.025,pixel_span);
			garden_noise=mix(0.5,garden_noise,garden_detail);
			float garden_canopy=smoothstep(0.32,0.72,garden_noise);
			vec3 canopy_tone=mix(vec3(0.18,0.26,0.15),vec3(0.36,0.43,0.27),garden_noise);
			float garden_upkeep=mix(0.68,0.38,smoothstep(3.0,5.0,district_condition));
			garden_tone=mix(garden_tone,canopy_tone,(0.35+garden_canopy*0.65)*garden_upkeep);
			float access_center=0.5+0.12*sin(neighborhood_local.y*6.0+district_seed*17.0);
			float garden_access=1.0-smoothstep(0.008,0.019+lane_aa,abs(neighborhood_local.x-access_center));
			garden_access*=step(0.66,hash21(neighborhood_cell+vec2(37.0,district_seed*29.0)))*garden_detail;
			garden_tone=mix(garden_tone,COLOR.rgb*0.92,garden_access*0.35);
		}
		fabric=mix(fabric,garden_tone,(1.0-occupied_block)*garden_interior*neighborhood_visibility*(district_condition<6.0 ? 0.85 : 0.40));
		vec3 lane_tone=mix(COLOR.rgb,vec3(0.40,0.355,0.27),0.42);
		fabric=mix(fabric,lane_tone,local_lane*neighborhood_visibility*road_survival*0.42);
		// Sparse warm concentrations suggest fires, busy yards and denser inhabited
		// centres at Google-Earth scale. They are deliberately aggregate bright spots.
		vec2 activity_delta=neighborhood_local-vec2(0.5);
		float activity_seed=hash21(neighborhood_cell+vec2(109.0,district_seed*137.0));
		float activity_spot=(1.0-smoothstep(0.035,0.16,length(activity_delta)))*step(0.965,activity_seed)*occupied_block;
		activity_spot*=neighborhood_survival;
		vec3 activity_tone=mix(COLOR.rgb,vec3(0.63,0.57,0.45),0.60);
		fabric=mix(fabric,activity_tone,activity_spot*neighborhood_visibility*0.32);
		vec2 regional_point=urban_point*vec2(0.40,0.34);
		vec2 regional_local=fract(regional_point);
		vec2 regional_edge=min(regional_local,vec2(1.0)-regional_local);
		float regional_aa=max(fwidth(regional_edge.x),fwidth(regional_edge.y));
		float avenue=1.0-smoothstep(0.014,0.037+regional_aa*0.34,min(regional_edge.x,regional_edge.y));
		vec2 regional_cell=floor(regional_point);
		regional_local=vary_strategic_district_uv(regional_local,regional_cell,district_seed+0.31);
		float district_age=value_noise(regional_cell*0.31+vec2(71.0,-31.0));
		float district_void=step(0.34,hash21(regional_cell+vec2(-9.0,83.0)));
		fabric*=mix(0.92,1.065,district_age);
		// Large irregular districts remain visible as the city expands. Their muted
		// material families and voids make many shapes without imposing a modern plan.
		float district_roll=hash21(regional_cell+vec2(district_seed*97.0,district_seed*53.0));
		float district_built=step(0.18,district_roll)*strategic_structure_survival(district_condition,regional_local,regional_cell);
		float district_mottle=value_noise(regional_point*2.7+vec2(district_seed*29.0,-43.0));
		vec3 district_detail=COLOR.rgb*(0.67+district_mottle*0.31);
		if(maritime_district) district_detail=mix(district_detail,vec3(0.43,0.46,0.39),0.18);
		fabric=mix(fabric,district_detail,district_built*regional_visibility*0.34);
		fabric=mix(fabric,COLOR.rgb*0.38,avenue*district_void*0.20*regional_visibility*road_survival);
		// At regional/continental altitude, many neighborhood cells combine into one
		// urban zone. Re-sample the same bounded design language at a coarser physical
		// scale and let mipmapping integrate its internal buildings. This is the next
		// Google-Earth LOD—not a second population layer or extra scene geometry.
		float macro_visibility=smoothstep(0.11,0.30,pixel_span)*(1.0-smoothstep(2.2,7.5,pixel_span));
		vec2 macro_point=urban_point*vec2(0.082,0.069);
		vec2 macro_local=fract(macro_point);
		vec2 macro_cell=floor(macro_point);
		macro_local=vary_strategic_district_uv(macro_local,macro_cell,district_seed+0.67);
		float macro_built=step(0.14,hash21(macro_cell+vec2(district_seed*131.0,district_seed*79.0)));
		macro_built*=strategic_structure_survival(district_condition,macro_local,macro_cell);
		float macro_value=value_noise(macro_point*3.1+vec2(-17.0,district_seed*41.0));
		vec3 macro_detail=COLOR.rgb*(0.72+macro_value*0.25);
		fabric=mix(fabric,macro_detail,macro_built*macro_visibility*0.23);
		// Continental altitude gets one final 100–120 km aggregate octave. It carries
		// only luminance/material modulation—not pasted building imagery—so a planetary
		// megalopolis retains internal structure without repeating thousands of tiles.
		float continental_visibility=smoothstep(0.55,0.95,pixel_span)*(1.0-smoothstep(4.2,8.0,pixel_span));
		vec2 continental_point=urban_point*vec2(0.0102,0.0087);
		vec2 continental_local=fract(continental_point);
		vec2 continental_cell=floor(continental_point);
		continental_local=vary_strategic_district_uv(continental_local,continental_cell,district_seed+0.83);
		float continental_built=step(0.12,hash21(continental_cell+vec2(district_seed*181.0,district_seed*103.0)));
		continental_built*=strategic_structure_survival(district_condition,continental_local,continental_cell);
		float continental_value=value_noise(continental_point*3.4+vec2(23.0,district_seed*61.0));
		vec3 continental_detail=COLOR.rgb*(0.78+continental_value*0.19);
		fabric=mix(fabric,continental_detail,continental_built*continental_visibility*0.17);
		// Street and roof grids belong to the fixed-kilometre close neighborhood kit.
		// Reconstructing a second procedural checkerboard immediately after that kit
		// retires made the city visibly change identity at the 2.4 km crossover. Regional
		// cover therefore keeps only broad avenue-scale structure and continuous age grain.
		float canopy=smoothstep(0.64,0.86,value_noise(world_position.xz*13.0+vec2(-101.0,59.0)));
		fabric=mix(fabric,fabric*vec3(0.66,0.79,0.64),canopy*0.22*district_visibility);
		if(district_condition>=6.0 && district_condition<7.0){
			// The atlas LODs above restore readable city texture, but must not paint over
			// the physical evidence that makes DAMAGED categorically different from POOR.
			// Composite one restrained, broad scar after every city-detail octave.
			float final_damage_scar=smoothstep(0.23,0.62,value_noise(urban_point*vec2(0.31,0.27)+vec2(83.0,district_seed*59.0)));
			vec3 final_damage_tone=mix(vec3(0.285,0.265,0.24),COLOR.rgb*0.42,0.28);
			fabric=mix(fabric,final_damage_tone,final_damage_scar*district_visibility*0.22);
		} else if(district_condition>=7.0){
			// Destruction removes usable structures, not the geographical record of an
			// entire city. A continuous foundation/soot field survives every atlas LOD,
			// with irregular intensity rather than a clean shrinking survivor island.
			float final_ruin_noise=value_noise(urban_point*vec2(0.19,0.17)+vec2(127.0,district_seed*73.0));
			float final_foundation_noise=value_noise(urban_point*vec2(0.54,0.47)+vec2(-61.0,district_seed*97.0));
			float ruin_record_visibility=max(district_visibility,max(regional_visibility*0.82,macro_visibility*0.58));
			float final_ruin_record=0.19+smoothstep(0.24,0.76,final_ruin_noise)*0.18+smoothstep(0.47,0.73,final_foundation_noise)*0.10;
			vec3 final_ruin_tone=mix(vec3(0.39,0.365,0.315),COLOR.rgb*0.55,0.34);
			fabric=mix(fabric,final_ruin_tone,final_ruin_record*ruin_record_visibility);
		}
	} else if (fabric_kind==3) {
		// Coarse fibre, bark and patched earthen roofing separate roofs from
		// coloured map rectangles even when a house is only a few pixels wide.
		vec2 roof_cell=floor(clamp(UV,vec2(0.0),vec2(0.9999))*4.0);
		float roof_angle=fract(UV2.x+0.25)*6.2831853;
		vec2 roof_axis=vec2(cos(roof_angle),sin(roof_angle));
		vec2 roof_cross=vec2(-roof_axis.y,roof_axis.x);
		float along=dot(world_position.xz,roof_axis);
		float across=dot(world_position.xz,roof_cross);
		// Analytic roof courses have no texture mipmaps. Fade their contrast once
		// a pixel spans a course; otherwise aerial movement aliases them into sparks.
		float roof_pixel_span=max(length(dFdx(world_position.xz)),length(dFdy(world_position.xz)));
		float fibre=abs(fract(along*1450.0+UV2.y*7.0)-0.5)*2.0;
		fibre=mix(0.5,fibre,1.0-smoothstep(0.25,0.75,roof_pixel_span*1450.0));
		float roof_stain=value_noise(world_position.xz*520.0+vec2(181.0,-63.0));
		roof_stain=mix(0.5,roof_stain,1.0-smoothstep(0.25,0.75,roof_pixel_span*520.0));
		if (roof_cell.x<0.5) {
			float binding=smoothstep(0.38,0.49,abs(fract(across*390.0+UV2.y*11.0)-0.5));
			binding=mix(0.13,binding,1.0-smoothstep(0.25,0.75,roof_pixel_span*390.0));
			fabric*=0.73+fibre*0.20+binding*0.16+roof_stain*0.12;
		} else if (roof_cell.x<1.5) {
			float board=pow(abs(fract(across*920.0+UV2.y*13.0)-0.5)*2.0,5.0);
			board=mix(0.166667,board,1.0-smoothstep(0.25,0.75,roof_pixel_span*920.0));
			fabric*=0.76+board*0.25+roof_stain*0.14;
		} else if (roof_cell.x<2.5) {
			float plaster=value_noise(vec2(along*310.0,across*470.0)+UV2.y*19.0);
			plaster=mix(0.5,plaster,1.0-smoothstep(0.25,0.75,roof_pixel_span*470.0));
			fabric*=0.78+plaster*0.30+roof_stain*0.10;
		} else {
			float joint_a=pow(abs(fract(along*610.0+UV2.y*5.0)-0.5)*2.0,7.0);
			float joint_b=pow(abs(fract(across*740.0+UV2.y*9.0)-0.5)*2.0,7.0);
			float joints=mix(0.222222,max(joint_a,joint_b),1.0-smoothstep(0.25,0.75,roof_pixel_span*740.0));
			fabric*=0.70+joints*0.23+roof_stain*0.18;
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
	if (fabric_kind==4) {
		// Joined courts and worn ground connect inhabited plots at village altitude.
		// Retire continuously before the player resolves individual yard surfaces.
		float ground_pixel_span=max(length(dFdx(world_position.xz)),length(dFdy(world_position.xz)));
		material_alpha*=smoothstep(0.00012,0.00060,ground_pixel_span);
	}
	if (fabric_kind==1) {
		// Metre-scale beds must integrate into crop cover instead of flickering as
		// isolated subpixel scratches. The broad parcel retains its crop palette.
		float field_pixel_span=max(length(dFdx(world_position.xz)),length(dFdy(world_position.xz)));
		float bed_visibility=1.0-smoothstep(0.00035,0.0015,field_pixel_span);
		material_alpha*=cultivation_rows ? bed_visibility : mix(1.0,3.0,1.0-bed_visibility);
	}
	if (fabric_kind==5) {
		// Roofs are occupied surface, not a translucent tint over untouched grass.
		// Preserve the geographic boundary fade while giving resolved roofs presence.
		float roof_alpha=smoothstep(0.02,0.24,COLOR.a)*0.96;
		material_alpha=mix(material_alpha,roof_alpha,urban_roof_coverage);
	}
	if (fabric_kind==3) {
		// Keep occupied roofs legible at village altitude. Fade continuously with
		// the camera, not a vertex color baked during an arbitrary mesh rebuild.
		material_alpha*=mix(1.0,0.55,smoothstep(0.0,0.85,aerial_lod));
	}
	if (fabric_kind==5 || fabric_kind==6) {
		// Aggregate city cover belongs to the aerial/regional LOD. Fade it before
		// plot-level roofs and yards become the player's source of truth, but retain a
		// restrained floor for mature territory beyond the bounded plot sample. Without
		// it, zooming into an outer metropolis made millions of represented residents
		// vanish into untouched wilderness merely because their blocks are aggregate.
		// Camera-local bounded district masses now carry town-and-later physical
		// presence at close zoom. Leave only a faint continuous substrate here so the
		// strategic layer does not double-render as a gray veil beneath real roofs.
		float aggregate_floor=fabric_kind==5 ? 0.78 : 0.16;
		float aggregate_reveal=fabric_kind==5 ? smoothstep(0.34,0.74,aerial_lod) : smoothstep(0.10,0.72,aerial_lod);
		material_alpha*=mix(aggregate_floor,1.0,aggregate_reveal);
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
		material_alpha*=0.93+urban_wear*0.07;
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
	material.set_shader_parameter("aerial_lod",smoothstep(0.72,3.20,camera.size) if camera!=null else 0.0)
	var atlas_texture:=load("res://assets/textures/settlement_material_atlas_v2.png")
	if atlas_texture: material.set_shader_parameter("material_atlas",atlas_texture)
	var roof_atlas_texture:=load("res://assets/textures/settlement_roof_material_atlas_v1.png")
	if roof_atlas_texture: material.set_shader_parameter("roof_material_atlas",roof_atlas_texture)
	var late_roof_atlas_texture:=load("res://assets/textures/settlement_roof_material_atlas_late_v1.png")
	if late_roof_atlas_texture: material.set_shader_parameter("late_roof_material_atlas",late_roof_atlas_texture)
	var modernization_tier:=maxi(clampi(int(ProgressionSystem.domain_tier("infrastructure")),0,8),clampi(int(ProgressionSystem.domain_tier("production")),0,8))
	var strategic_district_path:="res://assets/textures/settlement_district_atlas_modern_v1.png" if modernization_tier>=4 else "res://assets/textures/settlement_district_atlas_mature_v1.png"
	var strategic_district_texture:=load(strategic_district_path)
	if strategic_district_texture: material.set_shader_parameter("strategic_district_atlas",strategic_district_texture)
	var strategic_district_companion_path:="res://assets/textures/settlement_district_atlas_modern_v2.png" if modernization_tier>=4 else "res://assets/textures/settlement_district_atlas_mature_v2.png"
	var strategic_district_companion_texture:=load(strategic_district_companion_path)
	if strategic_district_companion_texture: material.set_shader_parameter("strategic_district_companion_atlas",strategic_district_companion_texture)
	var strategic_district_vernacular_texture:=load("res://assets/textures/settlement_district_atlas_vernacular_v1.png")
	if strategic_district_vernacular_texture: material.set_shader_parameter("strategic_district_vernacular_atlas",strategic_district_vernacular_texture)
	material.set_shader_parameter("strategic_district_modern",1 if modernization_tier>=4 else 0)
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
	if roof_plan=="fired_tile_roof":return Vector2i(2,wear_row)
	if roof_plan in ["masonry_roof","concrete_roof"]:return Vector2i(3,wear_row)
	var mix:Dictionary=plot.get("visual_material_mix",plot.get("material_mix",{})) if not plot.get("building_materials",{}).is_empty() else plot.get("material_mix",{})
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
	var mix:Dictionary=plot.get("visual_material_mix",plot.get("material_mix",{})) if not plot.get("building_materials",{}).is_empty() else plot.get("material_mix",{})
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
			# SurfaceTool follows Godot's clockwise front-face winding. These pitched
			# spans were reversed relative to every polygon roof, lighting their backs.
			for roof_vertex in [face[0],face[2],face[1]]:
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
		# Camera-dependent contrast and opacity belong to the live fabric shader.
		# Baking them here caused a sharp fade at 0.42 km and stale colors on zoom.
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

func _append_plot_boundary(surface:SurfaceTool,plot:Dictionary,center:Vector3,lift:=0.0030)->int:
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
				world_point.y=_close_surface_height_at(world_point.x,world_point.z)+lift
				surface.set_color(edge_color)
				surface.add_vertex(world_point)
			segments+=1
	return segments

func _append_yard_variation(surface:SurfaceTool,plot:Dictionary,center:Vector3,lift:=0.0027)->int:
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
		# A stride of three freezes a three-cell palette on the same material.
		var material_stride:=1 if ground_cells.size()==3 else 3
		var atlas_cell:Vector2i=ground_cells[(absi(int(plot.get("seed",1)))+patch_index*material_stride)%ground_cells.size()]
		var color:=Color.WHITE.lerp(Color("#7d765f"),rng.randf_range(0.04,0.18))
		if use=="dirty_industry": color=color.lerp(Color("#353631"),0.48)
		elif use in ["civic","sacred"]: color=color.lerp(Color("#b3aa96"),0.22)
		color.a=rng.randf_range(0.18,0.36)
		var patch_radius:=rng.randf_range(0.0013,0.0040)
		if fabric_generation>=9 and use in ["workshop","storage","dirty_industry","civic","sacred"]:
			patch_radius*=rng.randf_range(1.35,2.10)
		_append_textured_ground_patch(surface,world_center,patch_radius,color,lift,atlas_cell,int(plot.get("seed",1))^((patch_index+5)*0x45d9f3b))
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
		# Dividers run across the beds, so their lateral basis has opposite winding.
		# Keep their daylight-facing normals consistent with the crop courses.
		for corner_index in [0,2,1,0,3,2]:
			var point_2d:Vector2=corners[corner_index]
			var world_point:=Vector3(center.x+point_2d.x,0.0,center.z+point_2d.y)
			world_point.y=_close_surface_height_at(world_point.x,world_point.z)+0.0029
			surface.set_color(Color(0.24,0.245,0.13,0.34))
			surface.set_uv(Vector2(-1.0,-1.0))
			surface.add_vertex(world_point)

func _organic_town_enabled() -> bool:
	return EarlySettlementVisual.enabled(GameState.settlement_plots)

## The early-town layout for the current city, built against the full saved
## fabric (never a camera-culled subset). Returns {} on a miss when not computing.
func _organic_town_plan(center: Vector3, land: Callable, compute := true) -> Dictionary:
	var state := var_to_bytes([GameState.world_seed, center, GameState.settlement_plots, GameState.settlement_routes])
	var entry: Array = organic_town_plans.get(center, [])
	if not entry.is_empty() and entry[0] == state: return entry[1]
	if not compute: return {}
	var plan := EarlySettlementVisual.layout(GameState.settlement_plots, GameState.settlement_routes, land)
	EarlySettlementVisual.remember_layout(plan, GameState.settlement_plots)
	if organic_town_plans.size() >= 64: organic_town_plans.clear()
	organic_town_plans[center] = [var_to_bytes([GameState.world_seed, center, GameState.settlement_plots, GameState.settlement_routes]), plan]
	return plan

## The home settlement's paths, yards and worn grass, rasterized from the
## real fabric for the terrain shader (settlement_grounds.gd). Cheap when
## nothing changed; visual only.
func _paint_settlement_grounds(center: Vector3) -> void:
	var plan: Dictionary = {}
	if EarlySettlementVisual.has_kit(GameState.settlement_plots):
		plan = _organic_town_plan(center, func(_point: Vector2) -> bool: return true, false)
	preload("res://scripts/settlement_grounds.gd").build_if_home(plan, GameState.settlement_plots, GameState.settlement_routes, center)

## Computes a missing early-town layout on its own, so the redraw that uses it
## can land in a later frame. True when it did the work.
func _prime_organic_town_plan(center: Vector3) -> bool:
	if not EarlySettlementVisual.has_kit(GameState.settlement_plots): return false
	var samples:=preload("res://scripts/settlement_surface_samples.gd").new(_close_surface_height_at,func(point:Vector2)->bool:return _settlement_stage_land_at(point+Vector2(center.x,center.z)))
	if not _organic_town_plan(center, samples.land_at, false).is_empty(): return false
	_organic_town_plan(center, samples.land_at)
	return true

func _create_plot_fabric(center: Vector3, plots: Array[Dictionary], lod: int, parent: Node3D) -> void:
	if plots.is_empty():
		return
	var samples:=preload("res://scripts/settlement_surface_samples.gd").new(_close_surface_height_at,func(point:Vector2)->bool:return _settlement_stage_land_at(point+Vector2(center.x,center.z)))
	var organic_plan: Dictionary = {"buildings": [], "replaced": {}}
	var organic_town := _organic_town_enabled()
	var ptrace=preload("res://scripts/performance_trace.gd")
	var pstamp:int=ptrace.start()
	if EarlySettlementVisual.has_kit(GameState.settlement_plots):
		organic_plan = _organic_town_plan(center, samples.land_at)
		pstamp=ptrace.mark("plot_fabric_layout",pstamp)
		EarlySettlementVisual.render(organic_plan, center, samples.height_at, parent)
		pstamp=ptrace.mark("plot_fabric_kit_render",pstamp)
	if organic_town:
		EarlySettlementGround.render(organic_plan, GameState.settlement_plots, GameState.settlement_routes, center, samples.height_at, samples.land_at, parent)
		pstamp=ptrace.mark("plot_fabric_ground_render",pstamp)
		# Keep genuine cultivated fields and later unsupported forms, but never
		# paint the household/service parcel polygons over the new working ground.
		plots = plots.filter(func(plot: Dictionary) -> bool: return not EarlySettlementGround.handles(plot))
		if plots.is_empty(): return
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
		var uses_kit: bool = organic_plan.replaced.has(int(plot.get("id", -1)))
		var ground_lift := 0.0002 if organic_town or uses_kit else 0.0018
		var plot_has_detail:=_settlement_plot_has_detail(plot,plot_index,plots.size(),lod)
		var plot_color := _settlement_plot_color(plot)
		var status := String(plot.get("status", "active"))
		var land_use := String(plot.get("land_use", "vacant"))
		# Occupied plots remain the source of close aerial fabric. The retired photo
		# atlas must not leave a hole where actual homes and workshops should resolve.
		var ground_inset:=1.0 if land_use in ["field","water","waste"] else 0.76
		if not organic_town and not uses_kit and _settlement_plot_has_aggregate_density(plot,plot_index,plots.size(),lod):
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
			# Pixel coverage, not a mesh rebuild threshold, controls the handover to
			# aerial crop cover in the field shader.
			field_ground_color.a=0.10 if status=="active" else 0.050
			# A strong centre-to-edge alpha gradient made six-sided parcels look like
			# glowing map tokens. Worked ground is a coherent, softly edged land-cover
			# change; rows and inherited boundaries provide its internal hierarchy.
			_append_textured_plot_polygon(field_ground_surface,plot,center,field_ground_color,0.0021,Vector2i(-1,-1),0.24)
			field_ground_count+=1
		elif land_use in ["water","waste"]:
			# Service parcels are worn ground, not hard-edged map tokens.
			_append_textured_plot_polygon(ground_surface,plot,center,plot_color,ground_lift,Vector2i(-1,-1),0.08)
		elif land_use not in ["water","waste","vacant","pasture"] and status!="reclaimed":
			_append_textured_plot_polygon(ground_surface,plot,center,plot_color,ground_lift,_ground_atlas_cell(plot),0.68)
		else:
			_append_plot_polygon(ground_surface, polygon, center, plot_color, ground_inset, ground_lift)
		var form:=String(plot.get("form",""))
		var temporary_camp:=form in ["portable_shelter_cluster","light_shelter_cluster","emergency_open_encampment"]
		var feature_center:=Vector2(plot.get("centroid",Vector2.ZERO))
		var feature_world:=Vector3(center.x+feature_center.x,0.0,center.z+feature_center.y)
		if lod<=1 and not temporary_camp:
			boundary_count+=_append_plot_boundary(boundary_surface,plot,center,0.00035 if organic_town or uses_kit else 0.0030)
			if plot_has_detail and land_use not in ["water","waste","field"]:
				variation_count+=_append_yard_variation(variation_surface,plot,center,0.0003 if organic_town or uses_kit else 0.0027)
		if lod<=1 and not organic_plan.replaced.has(int(plot.get("id", -1))) and not temporary_camp and land_use in ["communal","civic","sacred","market"]:
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
			if form=="carried_water_point":
				_append_textured_ground_patch(feature_surface,feature_world,0.0012,Color(0.23,0.29,0.25,0.55),0.0030,Vector2i(-1,-1),int(plot.get("seed",1))^0x213f)
			else:
				_append_ground_disc(feature_surface,feature_world,0.0027,Color(0.16,0.28,0.27,0.76),0.0030)
			feature_count+=1
		elif lod==0 and land_use=="waste":
			_append_textured_ground_patch(feature_surface,feature_world,0.0022,Color(0.23,0.20,0.13,0.60),0.0030,Vector2i(-1,-1),int(plot.get("seed",1))^0x371b)
			feature_count+=1
		if lod<=1 and plot_has_detail and land_use=="field" and status not in ["ruin","reclaimed"]:
			_append_field_rows(field_surface,plot,center)
			field_count+=1
		var open_ground_form:=form in ["open_hearth_yard","open_work_yard","guarded_cache","carried_water_point","refuse_and_latrine_ground"]
		if lod <= 1 and plot_has_detail and status not in ["vacant", "reclaimed"] and not open_ground_form and land_use not in ["water", "waste", "field", "pasture"]:
			if status == "under_construction" and float(plot.get("construction_progress", 0.0)) < 0.26:
				continue
			var mass_counts: Dictionary = {"roofs": 0, "walls": 0}
			if not EarlySettlementVisual.supports(plot) and not uses_kit:
				mass_counts = _append_satellite_roof_fabric(roof_surface,wall_surface,plot,center,lod)
			roof_count+=int(mass_counts.get("roofs",0))
			wall_count+=int(mass_counts.get("walls",0))
		if lod == 0 and status in ["damaged", "ruin"] and land_use!="temporary_encampment":
			_append_plot_polygon(scar_surface, polygon, center, Color(0.19, 0.17, 0.15, 0.72), 0.34, 0.0044)
			scar_count += 1
	if density_count>0:
		_commit_settlement_surface(density_surface,"PersistentSettlementDensity",parent,true)
	pstamp=ptrace.mark("plot_fabric_plot_loop",pstamp)
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

func _settlement_route_join_offset(points:PackedVector2Array,index:int,width:float)->Vector2:
	var incoming:Vector2=points[index]-points[maxi(0,index-1)]
	var outgoing:Vector2=points[mini(points.size()-1,index+1)]-points[index]
	if incoming.is_zero_approx(): incoming=outgoing
	if outgoing.is_zero_approx(): outgoing=incoming
	var first:=Vector2(-incoming.y,incoming.x).normalized()
	var second:=Vector2(-outgoing.y,outgoing.x).normalized()
	var bisector:=(first+second).normalized()
	if bisector.is_zero_approx(): return first*width
	# Shared, bounded miters join adjacent quads without extra meshes or spikes.
	return bisector*width/maxf(0.5,bisector.dot(first))


func _create_persistent_settlement_routes(center: Vector3, routes: Array[Dictionary], parent: Node3D) -> void:
	var early_town := _organic_town_enabled()
	if early_town: return # The new neighborhood ground owns human-scale routes.
	var inherited_frontages: Dictionary = {}
	for plot in GameState.settlement_plots:
		if int(plot.get("id", 0)) <= OrganicTownVisual.MAX_PLOTS and EarlySettlementVisual.supports(plot): inherited_frontages[int(plot.get("frontage_route_id", -1))] = true
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segment_count := 0
	var architecture:=_settlement_visual_architecture_profile(_settlement_architecture_profile())
	var axiality:=clampf(float(architecture.get("axiality",0.5)),0.0,1.0)
	var civic_space:=clampf(float(architecture.get("civic_space",0.5)),0.0,1.0)
	var permeability:=clampf(float(architecture.get("permeability",0.5)),0.0,1.0)
	for route in routes:
		var route_lift := 0.0004 if early_town or inherited_frontages.has(int(route.get("id", -2))) else 0.0027
		if not bool(route.get("active", true)):
			continue
		var points: PackedVector2Array = route.get("points", PackedVector2Array())
		# Ignore collapsed segments in a local render copy, never in saved routes.
		var distinct_points:=PackedVector2Array()
		for point in points:
			if distinct_points.is_empty() or point.distance_squared_to(distinct_points[-1])>=0.0000001:
				distinct_points.append(point)
		points=distinct_points
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
		elif hierarchy=="main_approach": route_color.a=0.54
		if hierarchy in ["lane","main_approach"]:
			route_color=route_color.lerp(Color("#94866d"),civic_space*0.10)
		if surface_tier>=3 and route_kind!="camp_path":
			# Roads are the organizing skeleton visible in real aerial imagery. Mature
			# drained/paved routes must survive the close-map LOD instead of becoming
			# fainter precisely when their roof fabric appears.
			route_color.a=maxf(route_color.a,0.52+0.07*float(surface_tier-3))
		# The same saved path must retain its contrast regardless of the zoom at
		# mesh creation. Screen-space filtering belongs to the road material.
		if route_kind=="camp_path": route_color.a=maxf(route_color.a,0.22)
		for index in points.size() - 1:
			var start := points[index]
			var finish := points[index + 1]
			var direction := finish - start
			if direction.length_squared() < 0.0000001:
				continue
			var start_side:=_settlement_route_join_offset(points,index,width)
			var finish_side:=_settlement_route_join_offset(points,index+1,width)
			var route_vertices:=[start-start_side,finish-finish_side,finish+finish_side,start-start_side,finish+finish_side,start+start_side]
			var route_uvs:=[Vector2(0.0,0.0),Vector2(1.0,0.0),Vector2(1.0,1.0),Vector2(0.0,0.0),Vector2(1.0,1.0),Vector2(0.0,1.0)]
			for vertex_index in route_vertices.size():
				var point_2d:Vector2=route_vertices[vertex_index]
				var world_point := Vector3(center.x + point_2d.x, 0.0, center.z + point_2d.y)
				world_point.y = _close_surface_height_at(world_point.x, world_point.z) + route_lift
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
	# codex/terrain-bake: exactly min(distance_km) over _surface_water_sources(origin)
	# with no limit, without building every source record. A source only counts
	# when its nearest channel point is above sea level, so each candidate is
	# height-checked in turn; tributary courses whose chunk bounds are no closer
	# than the best valid source are skipped (identical minimum).
	if world_tributary_courses.is_empty():world_tributary_courses=_seeded_world_tributaries()
	if not is_same(tributary_chunk_source,world_tributary_courses):_index_tributary_chunks()
	# Same float32 origin the source records were measured from.
	var origin:=Vector3(x,0,z)
	var point:=Vector2(origin.x,origin.z)
	var best:=INF
	var river_x:=_world_river_x(origin.z)
	if is_finite(river_x) and _height_at(river_x,origin.z)>SEA_LEVEL:best=absf(origin.x-river_x)
	var drainage_distance:=_local_drainage_distance_at(origin.x,origin.z)
	if is_finite(drainage_distance) and drainage_distance<best:
		var phase:=float(posmod(GameState.world_seed,10007))/10007.0
		var channel_x:=_local_drainage_channel_x(roundi((origin.x-(phase-.5)*2.4)/2.4),origin.z)
		if _height_at(channel_x,origin.z)>SEA_LEVEL:best=drainage_distance
	var order:Array[Vector2]=[]
	for course_index in tributary_course_chunk_ranges.size():
		order.append(Vector2(_tributary_bounds_gap(tributary_course_bounds[course_index],point),course_index))
	order.sort()
	for entry in order:
		if entry.x>best+TRIBUTARY_CULL_EPSILON_KM:break
		var nearest:=_nearest_point_on_tributary(int(entry.y),point,best)
		if nearest.z<best and _height_at(nearest.x,nearest.y)>SEA_LEVEL:best=nearest.z
	return best


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
	if not is_same(tributary_chunk_source,world_tributary_courses):_index_tributary_chunks()
	# Chunks farther away than the nearest segment found so far cannot hold a
	# closer one, so skipping them leaves the minimum exactly unchanged.
	var nearest:=INF
	for chunk:Array in tributary_chunks:
		var bounds:Rect2=chunk[0]
		var gap:=Vector2(maxf(0.0,maxf(bounds.position.x-position.x,position.x-bounds.end.x)),maxf(0.0,maxf(bounds.position.y-position.y,position.y-bounds.end.y)))
		if gap.length()>=nearest:continue
		var tributary:Array=world_tributary_courses[int(chunk[1])]
		for point_index in range(int(chunk[2]),int(chunk[3])):
			var start:Vector3=tributary[point_index]
			var finish:Vector3=tributary[point_index+1]
			var closest:=Geometry2D.get_closest_point_to_segment(position,Vector2(start.x,start.z),Vector2(finish.x,finish.z))
			nearest=minf(nearest,position.distance_to(closest))
	return nearest

## Tributary segments grouped in runs of TRIBUTARY_CHUNK_SEGMENTS with bounds:
## [Rect2, tributary index, first point, last segment start + 1].
var tributary_chunks:Array=[]
var tributary_chunk_source:Array=[]
const TRIBUTARY_CHUNK_SEGMENTS:=16
## codex/terrain-bake: per-course [first chunk, end chunk) and whole-course bounds,
## so per-course water queries use the same chunk index. Culling keeps a 10 m
## allowance for float32 bounds, so skipped chunks can never hold a closer point.
var tributary_course_chunk_ranges:Array[Vector2i]=[]
var tributary_course_bounds:Array[Rect2]=[]
const TRIBUTARY_CULL_EPSILON_KM:=0.01

func _index_tributary_chunks()->void:
	tributary_chunk_source=world_tributary_courses
	tributary_chunks.clear()
	tributary_course_chunk_ranges.clear()
	tributary_course_bounds.clear()
	for tributary_index in world_tributary_courses.size():
		var tributary:Array=world_tributary_courses[tributary_index]
		var first:=0
		var first_chunk:=tributary_chunks.size()
		var course_bounds:=Rect2()
		while first<tributary.size()-1:
			var last:=mini(first+TRIBUTARY_CHUNK_SEGMENTS,tributary.size()-1)
			var start:Vector3=tributary[first]
			var bounds:=Rect2(Vector2(start.x,start.z),Vector2.ZERO)
			for point_index in range(first+1,last+1):
				var point:Vector3=tributary[point_index]
				bounds=bounds.expand(Vector2(point.x,point.z))
			course_bounds=bounds if tributary_chunks.size()==first_chunk else course_bounds.merge(bounds)
			tributary_chunks.append([bounds,tributary_index,first,last])
			first=last
		tributary_course_chunk_ranges.append(Vector2i(first_chunk,tributary_chunks.size()))
		tributary_course_bounds.append(course_bounds)

func _tributary_bounds_gap(bounds:Rect2,position:Vector2)->float:
	return Vector2(maxf(0.0,maxf(bounds.position.x-position.x,position.x-bounds.end.x)),maxf(0.0,maxf(bounds.position.y-position.y,position.y-bounds.end.y))).length()

func _nearest_point_on_tributary(course_index:int,point:Vector2,bound:float)->Vector3:
	## First segment point (in course order) strictly closer than every earlier one
	## and than `bound`, as the former full scan chose it: (x, z, distance), or
	## INF distance when none is closer than `bound`.
	var course:Array=world_tributary_courses[course_index]
	var chunk_range:=tributary_course_chunk_ranges[course_index]
	var nearest:=Vector2.INF
	var distance:=INF
	for chunk_index in range(chunk_range.x,chunk_range.y):
		var chunk:Array=tributary_chunks[chunk_index]
		if _tributary_bounds_gap(chunk[0],point)>minf(distance,bound)+TRIBUTARY_CULL_EPSILON_KM:continue
		for i in range(int(chunk[2]),int(chunk[3])):
			var start:Vector3=course[i];var finish:Vector3=course[i+1]
			var sample:=Geometry2D.get_closest_point_to_segment(point,Vector2(start.x,start.z),Vector2(finish.x,finish.z))
			var candidate_distance:=point.distance_to(sample)
			if candidate_distance<minf(distance,bound):
				distance=candidate_distance;nearest=sample
	return Vector3(nearest.x,nearest.y,distance)


func _settlement_surface_assessment(destination:Vector3)->Dictionary:
	var terrain_height:=_height_at(destination.x,destination.z)
	if terrain_height<=SEA_LEVEL+0.02:
		return {"valid":false,"kind":"open_water","reason":"Open water. A settlement needs dry land"}
	var main_distance:=_main_river_distance_at(destination.x,destination.z)
	if main_distance<=MAIN_RIVER_SETTLEMENT_CLEARANCE_KM:
		return {
			"valid":false,"kind":"river","distance_km":main_distance,
			"reason":"River channel. This is in the river or on its bank; choose dry ground at least %.0f m from the middle of the channel" % (MAIN_RIVER_SETTLEMENT_CLEARANCE_KM*1000.0)
		}
	var tributary_distance:=_nearest_tributary_distance_at(Vector2(destination.x,destination.z))
	if tributary_distance<=TRIBUTARY_SETTLEMENT_CLEARANCE_KM:
		return {
			"valid":false,"kind":"river","distance_km":tributary_distance,
			"reason":"Tributary channel. This is in moving water or on its bank; choose dry ground beyond the bank"
		}
	return {"valid":true,"kind":"land","river_distance_km":minf(main_distance,tributary_distance)}

func _founding_advisor()->RefCounted:
	if not is_instance_valid(founding_site_advisor):founding_site_advisor=FoundingSiteAdvice.new(self)
	return founding_site_advisor

func _founding_site_advice(position:Vector3,fresh:bool=false)->Dictionary:
	return _founding_advisor().assess(position,fresh)

func _founding_water_sources(origin:Vector3)->Array[Dictionary]:
	return _surface_water_sources(origin,6.0)

func _surface_water_sources(origin:Vector3,limit:float=INF)->Array[Dictionary]:
	# Project onto the same authored sources used by daily water collection.
	# No point deposits, sea water, hidden wells or invented rivers are substituted.
	var sources:Array[Dictionary]=[]
	var river_x:=_world_river_x(origin.z)
	if is_finite(river_x) and absf(origin.x-river_x)<=limit:
		var height:=_height_at(river_x,origin.z)
		if height>SEA_LEVEL:sources.append({"position":Vector3(river_x,height,origin.z),"distance_km":absf(origin.x-river_x),"kind":"River"})
	if world_tributary_courses.is_empty():world_tributary_courses=_seeded_world_tributaries()
	if not is_same(tributary_chunk_source,world_tributary_courses):_index_tributary_chunks()
	var point:=Vector2(origin.x,origin.z)
	for course_index in world_tributary_courses.size():
		# codex/terrain-bake: chunk-culled scan; same point and distance as before.
		var found:=_nearest_point_on_tributary(course_index,point,limit+.001)
		var nearest:=Vector2(found.x,found.y)
		var distance:=found.z
		if is_finite(distance) and distance<=limit:
			var height:=_height_at(nearest.x,nearest.y)
			if height>SEA_LEVEL:sources.append({"position":Vector3(nearest.x,height,nearest.y),"distance_km":distance,"kind":"Tributary"})
	var drainage_distance:=_local_drainage_distance_at(origin.x,origin.z)
	if is_finite(drainage_distance) and drainage_distance<=limit:
		var phase:=float(posmod(GameState.world_seed,10007))/10007.0
		var index:=roundi((origin.x-(phase-.5)*2.4)/2.4)
		var channel_x:=_local_drainage_channel_x(index,origin.z)
		var height:=_height_at(channel_x,origin.z)
		if height>SEA_LEVEL:
			sources.append({"position":Vector3(channel_x,height,origin.z),"distance_km":drainage_distance,"kind":"Surface drainage"})
	return sources

func _water_conveyance_sources(origin:Vector3)->Array[Dictionary]:
	# Consider upstream intakes on the SAME authored local waterways; the nearest
	# riverbank is often below the town. The local six-kilometre observation bound
	# remains unchanged, and no groundwater/deposit is exposed by this sampling.
	var result:Array[Dictionary]=[]
	var seen:Dictionary={}
	for offset:Vector2 in [Vector2.ZERO,Vector2(0,-1),Vector2(0,1),Vector2(0,-3),Vector2(0,3),Vector2(-3,0),Vector2(3,0)]:
		for source:Dictionary in _surface_water_sources(origin+Vector3(offset.x,0,offset.y),6.0):
			var distance:=Vector2(origin.x,origin.z).distance_to(Vector2(source.position.x,source.position.z))
			if distance>6.0:continue
			var id:="surface:%s:%.5f:%.5f" % [source.kind,source.position.x,source.position.z]
			if seen.has(id):continue
			seen[id]=true;source.id=id;source.revealed=true;source.distance_km=distance
			var route:=preload("res://scripts/water_conveyance_route.gd").survey(source,origin,Callable(self,"_height_at"))
			source.gravity_feasible=bool(route.get("ok",false))
			result.append(source)
	result.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
		if bool(a.gravity_feasible)!=bool(b.gravity_feasible):return bool(a.gravity_feasible)
		return float(a.distance_km)<float(b.distance_km))
	if result.size()>4:result.resize(4)
	return result

func _open_founding_site_guide(position:Vector3,later_city:bool=false)->void:
	if not interface_layer:return
	_close_founding_site_guide()
	if hud:hud.close_dock()
	if lens_panel:lens_panel.visible=false
	if map_help_panel:map_help_panel.visible=false
	founding_site_guide=FoundingSiteGuide.new()
	interface_layer.add_child(founding_site_guide)
	founding_site_guide.setup(self,position,later_city)

func _close_founding_site_guide()->void:
	if is_instance_valid(founding_site_guide):
		founding_site_guide.hide();founding_site_guide.queue_free()
	founding_site_guide=null

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


func _refresh_population_allocations() -> void:
	GameState.synchronize_population_allocations()

func _settlement_definitions() -> Array[Dictionary]:
	return preload("res://scripts/settlement_construction.gd")._settlement_definitions()

func _settlement_project_available(project: Dictionary) -> bool:
	return preload("res://scripts/settlement_construction.gd")._settlement_project_available(project)

func _settlement_project_material_plan(project:Dictionary)->Dictionary:
	return preload("res://scripts/settlement_construction.gd")._settlement_project_material_plan(project)


func _current_settlement_project() -> Dictionary:
	return preload("res://scripts/settlement_construction.gd")._current_settlement_project()

func _process_settlement_day() -> void:
	SettlementModel.with_local_population(_process_local_settlement_day)

func _process_local_settlement_day()->void:
	var completed:=preload("res://scripts/settlement_construction.gd").process_day()
	if GameState.resource_settlement_id!="":return
	for event in completed:
		footprint_population=-1
		if String(event.kind)=="Hearth Circle":
			hearth_established=true
			if settlement_visual_root:settlement_visual_root.position=GameState.settlement_founded_at
		_spawn_settlement_structure(String(event.kind))
		if travel_status_label:travel_status_label.text="The people's work has made %s." % String(event.kind).replace("_"," ").to_lower()


func _spawn_settlement_structure(structure_name: String) -> void:
	# Household shelters are rendered from saved plots, never a second camp ring.
	if structure_name == "Lean-to Shelters": return
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
			travel_status_label.text="%s. The card on the right shows the ground around them." % ("The travellers are here" if not GameState.settlement_site_committed else _settlement_display_name())
		get_viewport().set_input_as_handled()


func _move_settlers_to_screen(screen_position: Vector2) -> void:
	if settler_marker == null:
		return
	var hit:=_terrain_hit(screen_position)
	if hit.is_empty():
		return
	var destination: Vector3 = hit.position + Vector3.UP * 0.002
	_move_settlers_to(destination)

func _move_settlers_to(destination:Vector3)->void:
	if settler_marker==null:return
	var surface_assessment:=_settlement_surface_assessment(destination)
	if not bool(surface_assessment.get("valid",false)):
		_inspect_location(destination)
		if travel_status_label:
			travel_status_label.text=PaperKit.sentence(String(surface_assessment.get("reason","That ground cannot hold a settlement")))+"."
		return
	if GameState.settlement_site_committed or hearth_established or "Hearth Circle" in GameState.settlement_completed:
		if settlement_convoy_targeting:
			_begin_settlement_convoy(destination)
			return
		_inspect_location(destination)
		return
	var accepted:=WorldSimulation.submit("player",{"kind":"move","destination":Vector2(destination.x,destination.z)})
	if accepted.has("error"):
		if travel_status_label:travel_status_label.text=PaperKit.sentence(String(accepted.error))
		if bool(accepted.get("refused",false)):_show_caravan_notice({"leader":String(accepted.get("leader","The caravan leader")),"title":"The caravan leader advises against this","text":String(accepted.error).trim_prefix(String(accepted.get("leader",""))+": "),"severity":"warning"})
		return
	travel_start=settler_marker.position
	travel_target=destination
	travel_days_total=float(accepted.duration_days)
	travel_days_elapsed=0.0
	travel_active=bool(GameState.founding_journey.get("active",true))
	travel_reported_milestones.clear()
	_draw_route(travel_start, travel_target, accepted.get("path",[]))
	_inspect_location(destination)
	_present_caravan_reports()
	_update_time_interface()

func _halt_founding_convoy_to_forage()->void:
	var result:Dictionary=preload("res://scripts/civilization_travel.gd").camp_to_forage()
	if result.has("error"):
		if travel_status_label:travel_status_label.text=PaperKit.sentence(String(result.error))
		return
	travel_active=false
	travel_reported_milestones.erase("forage_ready")
	var point:Vector2=result.get("position",CivilizationSystem.player_world_origin)
	if settler_marker:settler_marker.position=Vector3(point.x,_height_at(point.x,point.y)+.002,point.y)
	if route_mesh:route_mesh.visible=false
	_refresh_discovered_resource_overlays()
	var event:={"id":"convoy_forage_%d" % int(GameState.elapsed_days*24.0),"day":int(GameState.elapsed_days),"title":"Founding Convoy Camps to Forage","description":String(result.message),"domain":"food","severity":"notice"}
	GameState.simulation_events.push_front(event)
	if GameState.simulation_events.size()>80:GameState.simulation_events.resize(80)
	if (GameState.founding_journey.get("caravan",{}) as Dictionary).is_empty():_issue_travel_council_report("halt",float(result.get("progress",0.0)),"the convoy deliberately camped to forage")
	_present_caravan_reports()
	_update_time_interface()

## Caravan overrides from the status card. The leader runs the march; these
## only halt, resume, recall or focus it.
func _on_caravan_override(id:String,action:String)->void:
	var result:Dictionary={}
	if id=="founding":
		match action:
			"focus":
				var point:=CivilizationTravel.journey_position(GameState.founding_journey)
				_set_camera_target(Vector3(point.x,_height_at(point.x,point.y),point.y))
				return
			"hold":
				_halt_founding_convoy_to_forage()
				return
			"resume":
				result=CivilizationTravel.resume()
				if not result.has("error"):
					travel_active=bool(GameState.founding_journey.get("active",false))
					var caravan:Dictionary=GameState.founding_journey.get("caravan",{})
					_draw_route(settler_marker.position,travel_target,caravan.get("path",[]))
	else:
		match action:
			"focus":
				var position_2d:=CaravanSystem._vector(GameState.settlement_convoy.get("position",Vector2.ZERO))
				_set_camera_target(Vector3(position_2d.x,_height_at(position_2d.x,position_2d.y),position_2d.y))
				return
			"hold":result=CaravanSystem.hold_expansion()
			"resume":result=CaravanSystem.resume_expansion()
			"recall":result=CaravanSystem.recall_expansion()
		var record:Dictionary=GameState.settlement_convoy.get("caravan",{})
		if not record.is_empty() and action in ["resume","recall"]:
			var path:Array=record.get("path",[])
			if path.size()>=2:
				var from:Vector2=path[0]
				var to:Vector2=path[-1]
				_draw_route(Vector3(from.x,0,from.y),Vector3(to.x,0,to.y),path)
	if result.has("error") and travel_status_label:travel_status_label.text=PaperKit.sentence(String(result.error))
	_present_caravan_reports()
	_update_time_interface()

## Leader reports reach the ruler as a Travel Council notice and an event; the
## major ones also go to the audience hall when that system is installed.
func _present_caravan_reports()->void:
	for entry_variant:Variant in CaravanSystem.drain_reports():
		var entry:Dictionary=entry_variant
		var event:={"id":"caravan_%s_%d_%d" % [String(entry.get("kind","report")),int(entry.get("day",0)),GameState.simulation_events.size()],"day":int(entry.get("day",GameState.elapsed_days)),"title":"%s: %s" % [String(entry.get("leader","Caravan leader")),String(entry.get("title",""))],"description":String(entry.get("text","")),"domain":"settlement","severity":"critical" if String(entry.get("severity",""))=="danger" else ("major" if bool(entry.get("major",false)) else "notice")}
		GameState.simulation_events.push_front(event)
		if GameState.simulation_events.size()>80:GameState.simulation_events.resize(80)
		if String(entry.get("severity",""))=="danger":AdvisorSystem.generate_consequence_item({"description":String(entry.get("text","")),"domain":"food","severity":"warning"})
		if bool(entry.get("major",false)):CaravanSystem.forward_to_audience(entry)
		_show_caravan_notice(entry)
		if String(entry.get("kind",""))=="arrival" and String(entry.get("caravan",""))=="founding" and route_mesh:route_mesh.visible=false

func _show_caravan_notice(entry:Dictionary)->void:
	if travel_council_notice==null:return
	var danger:=String(entry.get("severity",""))=="danger" or String(entry.get("severity",""))=="warning"
	travel_council_notice.text=MapNotes.caravan_words(entry)
	MapNotes.style_notice(travel_council_notice,danger)
	_place_travel_council_notice()
	travel_council_notice.visible=true
	travel_council_notice_until_msec=Time.get_ticks_msec()+(24000 if danger else 16000)

## Cheap geography for caravan route planning: the same authored surface water
## the daily water ledger uses, and dry-land height.
func _caravan_geography_at(point:Vector2)->Dictionary:
	var main:=_main_river_distance_at(point.x,point.y)
	var tributary:=_nearest_tributary_distance_at(point)
	var drainage:=_local_drainage_distance_at(point.x,point.y)
	var water_km:=minf(main,minf(tributary,drainage))*KM_PER_WORLD_UNIT
	var kind:="river" if main<=minf(tributary,drainage) else ("stream" if tributary<=drainage else "creek")
	return {"water_km":water_km if is_finite(water_km) else 9999.0,"water_kind":kind,"land":_height_at(point.x,point.y)>SEA_LEVEL+0.012}

func _caravan_forage_at(point:Vector2)->Dictionary:
	var profile:=PlanetEnvironment.profile_at(point)
	return {"forage":float(profile.get("forage",0.4)),"game":float(profile.get("game",0.3))}

func _on_settlement_action_pressed()->void:
	if not GameState.settlement_site_committed:
		if settler_marker:_open_founding_site_guide(settler_marker.position)
		return
	if bool(GameState.settlement_convoy.get("active",false)):
		var position_value:Variant=GameState.settlement_convoy.get("position",Vector2.ZERO)
		var position_2d:Vector2=position_value if position_value is Vector2 else Vector2.ZERO
		_set_camera_target(Vector3(position_2d.x,_height_at(position_2d.x,position_2d.y),position_2d.y))
		return
	if settlement_convoy_targeting:
		_cancel_settlement_convoy_targeting()
	else:
		_open_caravan_formation()

## Found a new settlement: pick the land first. The caravan leader chooses
## the party and the rations; one card then shows who goes, the cost and the
## time, with one "Send them".
func _open_caravan_formation()->void:
	caravan_formation={}
	_enter_settlement_convoy_targeting()


## The envoy button's words (toolbar and Known World). Talking happens in the court.
func _diplomat_action_presentation(status:Dictionary,known_destinations:int)->Dictionary:
	if bool(status.get("active",false)):
		var days:=int(status.get("days_remaining",0))
		return {"label":"Envoys away, back in about %d day%s" % [days,"" if days==1 else "s"],"disabled":false,
			"tooltip":"Our envoys are on the road. What they bring back will be heard in the court."}
	if known_destinations<=0:
		return {"label":"Send envoys","disabled":true,
			"tooltip":"We know no other people's home yet. Scouts must find where they live before envoys can go."}
	return {"label":"Send envoys","disabled":false,
		"tooltip":"Envoys walk to a people whose home we know and speak for you there. You choose what they say in the court."}

const CHOOSE_LAND_WORDS:="Move over the map and click known land to see who would go and what it costs. Right-click or Esc stops."

func _enter_settlement_convoy_targeting()->void:
	settlement_convoy_targeting=true
	settlement_convoy_hover_valid=false
	_set_resource_view_enabled(true)
	if lens_panel: lens_panel.visible=false
	if map_help_panel: map_help_panel.visible=false
	_ensure_settlement_convoy_preview()
	if settlement_convoy_instruction_panel: settlement_convoy_instruction_panel.visible=true
	_set_settlement_convoy_feedback(CHOOSE_LAND_WORDS,HudT.INK)
	_open_founding_site_guide(camera_target,true)
	_update_time_interface()

func _cancel_settlement_convoy_targeting()->void:
	_close_founding_site_guide()
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
	if travel_status_label: travel_status_label.text="You stopped choosing land. Nobody has left."

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
		settlement_convoy_instruction_label.text=PaperKit.sentence(message)
		settlement_convoy_instruction_label.add_theme_color_override("font_color",PaperKit.text_color(color))

func _settlement_convoy_site_assessment(destination:Vector3,fresh:bool=false)->Dictionary:
	if not _world_position_is_revealed(destination):
		return {"valid":false,"reason":"Nobody has seen this ground yet; scouts must come back from it before settlers can go"}
	var surface_assessment:=_settlement_surface_assessment(destination)
	if not bool(surface_assessment.get("valid",false)):
		return surface_assessment
	var water:=_founding_site_advice(destination,fresh)
	if not bool(water.valid):return water
	var network:Dictionary=_settlement_model().settlement_network_snapshot()
	var settlements:Array=network.get("settlements",[])
	if settlements.is_empty():
		return {"valid":false,"reason":"Finish the first settlement before founding another"}
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
		return {"valid":false,"reason":"Too close to %s; choose land at least %.1f km from its hearth" % [String(origin.get("name","home")),origin_clearance]}
	for existing_variant in settlements:
		var existing:Dictionary=existing_variant
		var existing_position_value:Variant=existing.get("position",Vector2.ZERO)
		var existing_center:Vector2=existing_position_value if existing_position_value is Vector2 else Vector2.ZERO
		var required_clearance:=maxf(1.2,float(existing.get("claim_radius_km",0.0))+0.55)
		if destination_2d.distance_to(existing_center)<required_clearance:
			return {"valid":false,"reason":"Inside the land of %s; choose ground at least %.1f km from its hearth" % [String(existing.get("name","one of our towns")),required_clearance]}
	return {
		"valid":true,"origin":origin,"distance_km":origin_distance,
		"water":water,"recommended":water.recommended,
		"reason":"%s: %s. Click to see who would go." % [PaperKit.sentence(String(water.title)),String(water.source_text)]
	}

func _update_settlement_convoy_preview(screen_position:Vector2)->void:
	if not settlement_convoy_targeting: return
	_ensure_settlement_convoy_preview()
	var hit:=_terrain_hit(screen_position)
	if hit.is_empty():
		settlement_convoy_hover_valid=false
		settlement_convoy_preview.visible=false
		_set_settlement_convoy_feedback("Move the pointer onto the map.",HudT.RED)
		return
	settlement_convoy_hover_position=hit.position+Vector3.UP*0.006
	var assessment:=_settlement_convoy_site_assessment(settlement_convoy_hover_position)
	if is_instance_valid(founding_site_guide):founding_site_guide.update_site(settlement_convoy_hover_position,false,assessment)
	settlement_convoy_hover_valid=bool(assessment.get("valid",false))
	settlement_convoy_preview.visible=true
	settlement_convoy_preview.position=settlement_convoy_hover_position
	var viewport_height:=maxf(1.0,get_viewport().get_visible_rect().size.y)
	var preview_radius:=clampf(camera.size/viewport_height*24.0,0.28,220.0)
	settlement_convoy_preview.scale=Vector3(preview_radius,1.0,preview_radius)
	var color:=Color(0.30,0.84,0.59,0.52) if settlement_convoy_hover_valid else Color(0.92,0.30,0.23,0.55)
	if settlement_convoy_hover_valid and not bool(assessment.get("recommended",false)):color=Color(.91,.71,.35,.55)
	settlement_convoy_preview_material.albedo_color=color
	_set_settlement_convoy_feedback(String(assessment.get("reason","Choose another point.")),Color(color.r,color.g,color.b))

func _select_settlement_convoy_site(screen_position:Vector2)->void:
	_update_settlement_convoy_preview(screen_position)
	if not settlement_convoy_hover_valid:
		if travel_status_label: travel_status_label.text="That land will not do. The note at the bottom of the map says why."
		return
	_begin_settlement_convoy(settlement_convoy_hover_position)

func _begin_settlement_convoy(destination:Vector3)->void:
	var assessment:=_settlement_convoy_site_assessment(destination,true)
	if not bool(assessment.get("valid",false)):
		_set_settlement_convoy_feedback(String(assessment.get("reason","That ground will not do")),HudT.RED)
		return
	var origin:Dictionary=assessment.get("origin",{})
	var destination_2d:=Vector2(destination.x,destination.z)
	if origin.is_empty():
		_set_settlement_convoy_feedback("Finish the first settlement before founding another.",HudT.RED)
		return
	var origin_2d:Vector2=origin.get("position",Vector2.ZERO)
	var origin_3d:=Vector3(origin_2d.x,_height_at(origin_2d.x,origin_2d.y)+0.002,origin_2d.y)
	var route:=_analyze_convoy_route(origin_3d,destination)
	if not bool(route.get("valid",false)):
		_set_settlement_convoy_feedback(String(route.get("reason","There is no way there")),HudT.RED)
		if settlement_convoy_preview_material: settlement_convoy_preview_material.albedo_color=Color(0.92,0.30,0.23,0.55)
		return
	var duration:=maxf(0.5,float(route.distance_km)/(CONVOY_KM_PER_DAY*float(route.terrain_modifier)))
	# The caravan leader plans the march over water before the quote is shown.
	var formation:=CaravanSystem.formation(origin_2d,destination_2d,float(origin.get("population",GameState.population_total)),caravan_formation)
	if bool(formation.get("ok",false)):duration=maxf(duration,float(formation.travel_days))
	var party:=caravan_formation.duplicate()
	if not party.has("food"):party["food"]=float(formation.suggested_food)
	party["population"]=int(formation.founders)
	var quote:Dictionary=_settlement_model().settlement_convoy_quote(destination_2d,duration,{},party)
	quote["caravan_formation"]=formation
	if not bool(formation.get("ok",false)):
		quote["ok"]=false
		quote["reason"]="%s refuses: %s" % [String((formation.leader as Dictionary).get("name","The caravan leader")),String(formation.advice)]
	_open_settlement_convoy_confirmation(destination,route,quote)

func _founding_material_summary(materials:Dictionary)->String:
	var parts:Array[String]=[]
	for resource_name in ["Timber","Fiber Plants","Clay","Stone"]:
		var amount:=float(materials.get(resource_name,0.0))
		if amount<=0.001: continue
		parts.append("%.1f %s" % [amount,ResourceSystem.display_name(resource_name)])
	return " + ".join(parts) if not parts.is_empty() else "none available"

func _open_settlement_convoy_confirmation(destination:Vector3,route:Dictionary,quote:Dictionary)->void:
	if settlement_convoy_confirm_panel and is_instance_valid(settlement_convoy_confirm_panel): return
	var site_assessment:=_settlement_convoy_site_assessment(destination,true)
	if not bool(site_assessment.get("valid",false)):
		_set_settlement_convoy_feedback(String(site_assessment.get("reason","That ground will not do")),HudT.RED)
		return
	settlement_convoy_pending_destination=destination
	settlement_convoy_pending_route=route.duplicate(true)
	settlement_convoy_pending_quote=quote.duplicate(true)
	settlement_convoy_confirmation_previous_speed=game_speed
	_set_game_speed(0.0)
	var formation:Dictionary=quote.get("caravan_formation",{})
	var leader:Dictionary=formation.get("leader",{})
	var water:Dictionary=site_assessment.water
	var neighbors:Dictionary=water.get("neighbors",{})
	var people:=int(quote.get("population",0))
	var ready:=bool(quote.get("ok",false))
	var facts:={
		"name":String(quote.get("suggested_name",_settlement_model().suggested_settlement_name(Vector2(destination.x,destination.z),String(quote.get("origin_name",""))))),
		"origin_name":String(quote.get("origin_name","home")),
		"leader":String(leader.get("name","A caravan leader")),
		"leader_summary":String(leader.get("summary",CaravanLeader.fit_summary(leader) if not leader.is_empty() else "")),
		"people":people,
		"food_days":float(quote.get("food",0.0))/maxf(1.0,float(people)),
		"journey":MapTickerWords.duration(float(quote.get("duration_days",0.0))),
		"distance_km":float(route.get("distance_km",quote.get("distance_km",0.0))),
		"supplies":_founding_material_summary(quote.get("materials",{})).to_lower(),
		"water_title":PaperKit.sentence(String(water.get("title",""))),
		"water_text":"%s. %s" % [String(water.get("source_text","")),String(water.get("reason",""))],
		"water_color":water.get("color",HudT.TEAL),
		"neighbour_text":String(neighbors.get("text","")) if float(neighbors.get("penalty",0.0))>0 else "",
		"ready":ready,
		"problem":String(quote.get("reason","something they need is missing")),
		"advice":CaravanSystem.rations_comment(formation,people,float(quote.get("food",0.0))) if not formation.is_empty() else "",
	}
	var card:=CaravanPanel.open_settler_card(interface_layer,facts,_confirm_settlement_convoy,_dismiss_settlement_convoy_confirmation)
	settlement_convoy_confirm_panel=card.overlay
	settlement_convoy_name_input=card.name_input
	settlement_convoy_confirm_status=card.status
	settlement_convoy_confirm_button=card.send

func _dismiss_settlement_convoy_confirmation()->void:
	if settlement_convoy_confirm_panel and is_instance_valid(settlement_convoy_confirm_panel): settlement_convoy_confirm_panel.queue_free()
	settlement_convoy_confirm_panel=null
	settlement_convoy_confirm_status=null
	settlement_convoy_confirm_button=null
	settlement_convoy_name_input=null
	settlement_convoy_pending_route={}
	settlement_convoy_pending_quote={}
	_set_game_speed(settlement_convoy_confirmation_previous_speed)
	if settlement_convoy_targeting:
		_set_settlement_convoy_feedback(CHOOSE_LAND_WORDS,HudT.INK)

func _confirm_settlement_convoy()->void:
	var destination:=settlement_convoy_pending_destination
	var site_assessment:=_settlement_convoy_site_assessment(destination,true)
	if not bool(site_assessment.get("valid",false)):
		if settlement_convoy_confirm_status:
			settlement_convoy_confirm_status.text="They cannot leave: %s." % PaperKit.sentence(String(site_assessment.get("reason","that ground will no longer do"))).trim_suffix(".")
			settlement_convoy_confirm_status.add_theme_color_override("font_color",HudT.RED_TEXT)
		if settlement_convoy_confirm_button: settlement_convoy_confirm_button.disabled=true
		return
	var quote:=settlement_convoy_pending_quote.duplicate(true)
	var chosen_name:=settlement_convoy_name_input.text.strip_edges() if settlement_convoy_name_input else String(quote.get("suggested_name",""))
	var party:=caravan_formation.duplicate()
	party["population"]=int(quote.get("population",party.get("population",0)))
	party["food"]=float(quote.get("food",party.get("food",0.0)))
	var formation:Dictionary=quote.get("caravan_formation",{})
	if not formation.is_empty() and int(party.get("leader_person_id",0))==int((formation.leader as Dictionary).get("person_id",-1)):party["plan"]=formation.plan
	var started:Dictionary=_settlement_model().begin_settlement_convoy(Vector2(destination.x,destination.z),float(quote.get("duration_days",0.5)),chosen_name,false,party)
	if not bool(started.get("ok",false)):
		if settlement_convoy_confirm_status:
			settlement_convoy_confirm_status.text="They cannot leave: %s" % String(started.get("reason","the stores have changed."))
			settlement_convoy_confirm_status.add_theme_color_override("font_color",HudT.RED_TEXT)
		if settlement_convoy_confirm_button: settlement_convoy_confirm_button.disabled=true
		return
	var origin_2d:Vector2=started.get("origin",Vector2.ZERO)
	var origin_3d:=Vector3(origin_2d.x,_height_at(origin_2d.x,origin_2d.y)+0.002,origin_2d.y)
	_dismiss_settlement_convoy_confirmation()
	_close_founding_site_guide()
	settlement_convoy_targeting=false
	settlement_convoy_hover_valid=false
	if settlement_convoy_preview:
		settlement_convoy_preview.queue_free()
		settlement_convoy_preview=null
	settlement_convoy_preview_material=null
	if settlement_convoy_instruction_panel: settlement_convoy_instruction_panel.visible=false
	_draw_route(origin_3d,destination,started.get("path",[]))
	caravan_formation={}
	_present_caravan_reports()
	var event:={
		"id":"settlement_convoy_%d" % int(GameState.elapsed_days*24.0),"day":int(GameState.elapsed_days),
		"title":"Settlers set out",
		"description":"%s people left %s for new land %.1f km away, carrying %.0f days' food each and %s for shelter and tools." % [_compact_population(int(started.population)),String(started.origin_name),float(started.distance_km),float(started.food)/maxf(1.0,float(started.population)),_founding_material_summary(started.get("materials",{})).to_lower()],
		"domain":"settlement","severity":"major"
	}
	GameState.simulation_events.push_front(event)
	if GameState.simulation_events.size()>80: GameState.simulation_events.resize(80)
	_refresh_settlement_convoy_marker()
	_refresh_settlement_network(true)
	_update_time_interface()

func _process_settlement_convoy()->void:
	if not bool(GameState.settlement_convoy.get("active",false)): return
	# The caravan leader marches in the calendar's convoy step
	# (civilization_day.advance_convoy -> caravan_system.gd); an older save's
	# convoy gains its leader here. The map marker follows the real position.
	CaravanSystem.ensure(GameState.settlement_convoy)
	_refresh_settlement_convoy_marker()

func _show_convoy_arrival(completed:Dictionary)->void:
	_present_caravan_reports()
	if bool(completed.get("returned",false)):
		if route_mesh: route_mesh.visible=false
		_refresh_settlement_convoy_marker()
		_refresh_settlement_network(true)
		_update_time_interface()
		return
	var destination:Vector2=completed.get("settlement",{}).get("position",Vector2.ZERO)
	var trace=preload("res://scripts/performance_trace.gd")
	var stamp:int=trace.start()
	if route_mesh: route_mesh.visible=false
	_refresh_settlement_convoy_marker()
	# A new town changes the network signature; existing towns keep their
	# drawn buildings and only the new one is built.
	_refresh_settlement_network()
	stamp=trace.mark("found_network",stamp)
	if bool(completed.get("ok",false)):
		var settlement:Dictionary=completed.settlement
		_settlement_model().select_settlement(String(settlement.get("id","")))
		stamp=trace.mark("found_select",stamp)
		GovernmentPeopleSystem.process_day(int(GameState.elapsed_days))
		stamp=trace.mark("found_government",stamp)
		var event:={
			"id":"settlement_founded_%d" % int(GameState.elapsed_days*24.0),"day":int(GameState.elapsed_days),
			"title":"A new settlement",
			"description":"%s settlers arrived and founded %s. Its people and its growth count with the rest of our people." % [_compact_population(int(completed.population)),String(settlement.get("name","the new settlement"))],
			"domain":"settlement","severity":"major"
		}
		GameState.simulation_events.push_front(event)
		if GameState.simulation_events.size()>80: GameState.simulation_events.resize(80)
		_set_camera_target(Vector3(destination.x,_height_at(destination.x,destination.y),destination.y))
		stamp=trace.mark("found_camera",stamp)
		# A new hearth is told in the Chronicle and shown on the map; the dock
		# does not open by itself over it.
	_update_time_interface()

func _start_settlement_here() -> void:
	if GameState.settlement_site_committed or settler_marker == null:
		return
	var site_assessment:=_settlement_surface_assessment(settler_marker.position)
	if not bool(site_assessment.get("valid",false)):
		if travel_status_label:
			travel_status_label.text="Not founded here: %s." % PaperKit.sentence(String(site_assessment.get("reason","choose dry land"))).trim_suffix(".")
		return
	var water:=_founding_site_advice(settler_marker.position,true)
	if not bool(water.valid):
		if travel_status_label:travel_status_label.text="Not founded here. %s" % String(water.reason)
		if is_instance_valid(founding_site_guide):founding_site_guide.update_site(settler_marker.position)
		return
	_close_founding_site_guide()
	var route_progress:=0.0
	if travel_active:
		route_progress=clampf(travel_days_elapsed/maxf(0.001,travel_days_total),0.0,1.0)
	travel_active=false
	GameState.convoy_traveling=false
	GameState.founding_journey.clear()
	GameState.convoy_emergency_halt_reason=""
	GameState.simulation_metrics["traveling"]=false
	GameState.simulation_metrics["travel_speed_factor"]=0.0
	GameState.settlement_site_committed=true
	GameState.settlement_founded_at=settler_marker.position
	CivilizationSystem.settlement_siting.founded("settlement_%03d" % GameState.next_player_settlement_id,_settlement_display_name(),Vector2(settler_marker.position.x,settler_marker.position.z),int(GameState.elapsed_days))
	_retire_founding_expedition_visuals()
	if route_mesh:
		route_mesh.visible=false
	if settlement_visual_root:
		settlement_visual_root.position=GameState.settlement_founded_at
	_refresh_settlement_footprint(true)
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
	# The map stays clear at founding: the dock no longer opens by itself over
	# the new hearth. The People view is one click away on the rail.
	_update_time_interface()
	_open_settlement_naming_panel.call_deferred()

func _founding_camp_marker_active()->bool:
	# The banner and label must persist through the founding camp: the stage-aware
	# settlement blip only exists once the Hearth Circle stands, and a committed
	# site with no marker at all reads as the convoy vanishing.
	return GameState.founding_expedition_active() or (GameState.settlement_site_committed and "Hearth Circle" not in GameState.settlement_completed)


func _retire_founding_expedition_visuals()->void:
	# A committed site is no longer a traveling convoy: retire the site-selection
	# ring immediately. The banner, label, and camp detail stay through the
	# founding camp (see _founding_camp_marker_active) until the Hearth Circle's
	# own stage-aware map symbol replaces them.
	if settler_map_ring: settler_map_ring.visible=false

func _analyze_convoy_route(from: Vector3,to: Vector3) -> Dictionary:
	var distance_km:=Vector2(from.x,from.z).distance_to(Vector2(to.x,to.z))*KM_PER_WORLD_UNIT
	if distance_km<0.25:
		return {"valid":false,"reason":"That is too close; choose a place at least 250 m away"}
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
		return {"valid":false,"reason":"The way crosses %.0f km of open water, and our people have no boats yet" % longest_wet_run}
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
	# A caravan leader owns stopping and going (caravan_leader.gd): it camps only
	# at water, turns aside for water, and reports trouble itself.
	if not (GameState.founding_journey.get("caravan",{}) as Dictionary).is_empty():return
	if not travel_active:
		if not GameState.settlement_site_committed and bool(GameState.founding_journey.get("camped_foraging",false)):
			var camp_advice:Dictionary=preload("res://scripts/civilization_travel.gd").advice()
			if bool(camp_advice.get("ready",false)) and not travel_reported_milestones.has("forage_ready"):
				travel_reported_milestones["forage_ready"]=true
				_issue_travel_council_report("forage_ready",1.0,String(camp_advice.get("reason","")))
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
	travel_council_notice.text=MapNotes.road_words(String(item.get("advisor","")),String(item.get("text","")))
	MapNotes.style_notice(travel_council_notice,urgency>0.7)
	_place_travel_council_notice()
	travel_council_notice.visible=true
	travel_council_notice_until_msec=Time.get_ticks_msec()+(24000 if urgency>0.7 else 16000)

## Sizes the road notice to its words and keeps it clear of the Chronicle's
## moment card (top right): beside the card when there is room, else below it.
func _place_travel_council_notice()->void:
	if travel_council_notice==null:return
	var view:=get_viewport().get_visible_rect().size
	var width:=clampf(view.x-140.0,260.0,390.0)
	var font:Font=travel_council_notice.get_theme_font("font")
	var font_size:=travel_council_notice.get_theme_font_size("font_size")
	var text_height:=font.get_multiline_string_size(travel_council_notice.text,HORIZONTAL_ALIGNMENT_LEFT,width-36.0,font_size).y if font else 120.0
	travel_council_notice.size=Vector2(width,ceilf(text_height)+36.0)
	var card_width:=float(preload("res://scripts/hud/chronicle_card.gd").CARD_WIDTH)
	var x:=view.x-card_width-32.0-width
	var y:=84.0
	if x<110.0:
		x=maxf(110.0,view.x-width-16.0)
		var card:Variant=hud.get_meta("chronicle_card") if hud and hud.has_meta("chronicle_card") else null
		if is_instance_valid(card) and bool(card.showing) and is_instance_valid(card.panel):y=float(card.panel.position.y+card.panel.size.y)+12.0
	travel_council_notice.position=Vector2(roundf(x),y)

func _on_diplomatic_event(event:Dictionary)->void:
	if String(event.get("kind",""))=="diplomatic_return":
		ForeignDiplomacy.open(String(event.get("civ_id","")))
		return
	# Routine formations already have persistent map counters and a World badge.
	# Only the historically meaningful first direct contact interrupts play;
	# threats, war declarations, and battles use their own decision surfaces.
	if String(event.get("kind",""))!="first_contact": return
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
	foreign_alert_title.text=MapNotes.alert_title(first_contact,group_count,int(active_foreign_alert.get("day",0)))
	if group_count<=1:
		var full_description:=String(active_foreign_alert.get("description","Strangers were seen."))
		var heading:=PaperKit.sentence(String(active_foreign_alert.get("title",""))).trim_suffix(".")
		foreign_alert_body.text=("%s. %s" % [heading,_bounded_alert_copy(full_description)]) if heading!="" else _bounded_alert_copy(full_description)
		foreign_alert_body.tooltip_text=full_description
	else:
		var descriptions:Array=active_foreign_alert.get("group_descriptions",[])
		var first_description:=String(descriptions[0]) if not descriptions.is_empty() else String(active_foreign_alert.get("description","Strangers were seen."))
		foreign_alert_body.text="%s\nThe Known World lists every band in sight." % _bounded_alert_copy(first_description,170)
		foreign_alert_body.tooltip_text="\n\n".join(descriptions) if not descriptions.is_empty() else first_description
	MapNotes.style_alert(foreign_alert_panel,first_contact)
	if foreign_alert_world_button:
		var known_people:=String(active_foreign_alert.get("civ_id",""))!=""
		foreign_alert_world_button.visible=known_people or group_count>1
		foreign_alert_world_button.text="Speak with them" if known_people else "Open the Known World"
		foreign_alert_world_button.tooltip_text="Open the court and send word to their people through our envoys." if known_people else "The Known World lists every band in sight."
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
	if not active_foreign_alert.is_empty() and int(GameState.elapsed_days)-int(active_foreign_alert.get("day",0))>7:
		_finish_active_foreign_alert()
	if foreign_alert_panel==null: return
	if _blocking_modal_or_report_open():
		foreign_alert_panel.visible=false
		return
	if not active_foreign_alert.is_empty():
		if not foreign_alert_panel.visible: _render_active_foreign_alert()
		return
	_present_next_foreign_alert()


func _blocking_modal_or_report_open()->bool:
	if is_instance_valid(founding_site_guide) and founding_site_guide.is_visible_in_tree():return true
	for overlay in [settlement_naming_panel,settlement_convoy_confirm_panel,scout_dispatch_panel,founding_focus_panel,world_menu_panel]:
		if overlay and is_instance_valid(overlay) and overlay.is_visible_in_tree(): return true
	if MilitaryCommandUI and MilitaryCommandUI.modal and MilitaryCommandUI.modal.visible: return true
	return false


func _clamp_foreign_alert_to_viewport()->void:
	if foreign_alert_panel==null: return
	var viewport_size:=get_viewport().get_visible_rect().size
	foreign_alert_panel.reset_size()
	foreign_alert_panel.size.x=minf(380.0,maxf(280.0,viewport_size.x-24.0))
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
	## A known people: the court, to send word. Several unnamed bands: the
	## Known World dock, which lists them. Never the old strategy panel.
	var civ_id:=String(active_foreign_alert.get("civ_id",""))
	var grouped:=int(active_foreign_alert.get("group_count",1))>1
	_finish_active_foreign_alert()
	if civ_id!="":
		MapNotes.open_court({"civ_id":civ_id})
	elif grouped and hud:
		_on_hud_section_requested("world",0)


func _dismiss_active_foreign_alert()->void:
	_finish_active_foreign_alert()


func _draw_route(from: Vector3, to: Vector3, path:Array=[]) -> void:
	if route_mesh:
		route_mesh.queue_free()
	var immediate := ImmediateMesh.new()
	immediate.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	if path.size()>=2:
		for index in path.size()-1:
			var a:Vector2=path[index]
			var b:Vector2=path[index+1]
			var pieces:=clampi(ceili(a.distance_to(b)/1.5),1,48)
			for piece in pieces:
				var along:=a.lerp(b,float(piece)/float(pieces))
				if index==0 and piece==0:immediate.surface_add_vertex(Vector3(a.x,_height_at(a.x,a.y)+0.012,a.y))
				immediate.surface_add_vertex(Vector3(along.x,_height_at(along.x,along.y)+0.012,along.y))
	else:
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
	var crest:=Sprite3D.new()
	crest.texture=_founding_banner_texture(GameState.founding_banner_index)
	crest.pixel_size=0.015
	crest.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	crest.position=Vector3(0,4.0,0)
	parent.add_child(crest)

func _opening_world_position() -> Vector3:
	# Seeded placement is only for a new campaign. A resumed settlement may
	# predate placement changes or have been founded after a caravan journey.
	if GameState.settlement_site_committed:
		var home:=GameState.settlement_founded_at
		return Vector3(home.x,_height_at(home.x,home.z)+.002,home.z)
	if GameState.elapsed_days>0.0:
		var origin:=CivilizationSystem.player_world_origin
		return Vector3(origin.x,_height_at(origin.x,origin.y)+.002,origin.y)
	return _find_camp_position()


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

func _civilization_start(origin:Vector2)->Vector2:
	return preload("res://scripts/civilization_start.gd").choose(origin,func(point:Vector2)->Dictionary:
		var sample:=_survey_ground_at(point)
		sample["founding_valid"]=bool(_settlement_surface_assessment(Vector3(point.x,0,point.y)).valid)
		sample["environment_profile"]=PlanetEnvironment.profile_at(point,sample)
		if bool(sample.founding_valid) and float(sample.get("river_distance_km",INF))<=6 and preload("res://scripts/civilization_start.gd").supports_founders(sample.environment_profile):
			sample["surface_material_catchments"]=_civilization_surface_materials(point)
		return sample)

func _find_world_start_position()->Vector3:
	var point:=_civilization_start(preload("res://scripts/civilization_start.gd").candidate(GameState.world_seed,0))
	return Vector3(point.x,_height_at(point.x,point.y)+.002,point.y)

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

func _schedule_modal_screen_contract(node:Node)->void:
	if node is Control: _apply_modal_screen_contract.call_deferred(node as Control)


func _apply_modal_screen_contract(screen:Control)->void:
	if screen==null or not is_instance_valid(screen): return
	if screen.has_meta("responsive_scroll_layout"): return
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
	travel_status_label = Label.new()
	travel_status_label.position = Vector2(viewport_width * 0.5 - 390, 66)
	travel_status_label.size = Vector2(780, 20)
	travel_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# A paper slip under the top bar, legible over any ground (map_ticker_style.gd).
	preload("res://scripts/hud/map_ticker_style.gd").style(travel_status_label)
	layer.add_child(travel_status_label)
	_build_map_help(layer)
	travel_council_notice=Button.new()
	travel_council_notice.position=Vector2(maxf(500.0,viewport_width-890.0),84)
	travel_council_notice.size=Vector2(390,140)
	MapNotes.style_notice(travel_council_notice,false)
	travel_council_notice.tooltip_text="Open the court to answer them."
	travel_council_notice.pressed.connect(func()->void:
		travel_council_notice.visible=false
		MapNotes.open_court())
	travel_council_notice.visible=false
	layer.add_child(travel_council_notice)
	# First contact: a paper card whose talk button opens the court (map_notes.gd).
	var alert:=MapNotes.build_alert(layer,get_viewport().get_visible_rect().size,_center_active_foreign_alert,_open_active_foreign_alert_world,_dismiss_active_foreign_alert)
	foreign_alert_panel=alert.panel
	foreign_alert_title=alert.title
	foreign_alert_body=alert.body
	foreign_alert_world_button=alert.world_button
	settlement_convoy_instruction_panel=PanelContainer.new()
	settlement_convoy_instruction_panel.position=Vector2(viewport_width*0.5-300,get_viewport().get_visible_rect().size.y-176)
	settlement_convoy_instruction_panel.size=Vector2(600,62)
	settlement_convoy_instruction_panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
	settlement_convoy_instruction_panel.add_theme_stylebox_override("panel",PaperKit.card_style(10.0,HudT.GOLD))
	settlement_convoy_instruction_label=Label.new()
	settlement_convoy_instruction_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	settlement_convoy_instruction_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	settlement_convoy_instruction_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	settlement_convoy_instruction_label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	settlement_convoy_instruction_label.add_theme_font_size_override("font_size",15)
	settlement_convoy_instruction_label.add_theme_color_override("font_color",HudT.INK)
	settlement_convoy_instruction_panel.add_child(settlement_convoy_instruction_label)
	settlement_convoy_instruction_panel.visible=false
	layer.add_child(settlement_convoy_instruction_panel)
	_refresh_population_allocations()
	_build_command_rail_hud(layer)
	_update_time_interface()
	_refresh_discovered_resource_overlays()

func _build_command_rail_hud(layer:CanvasLayer)->void:
	hud=preload("res://scripts/hud/command_rail_hud.gd").new()
	hud.terrain=self
	layer.add_child(hud)
	hud.section_requested.connect(_on_hud_section_requested)
	hud.menu_requested.connect(_open_world_menu)
	hud.escape_pressed.connect(_on_hud_escape)
	hud.register_provider("overview",preload("res://scripts/hud/content/dock_content_overview.gd").new(self,hud))
	hud.register_provider("settlement",preload("res://scripts/hud/content/dock_content_settlement.gd").new(self,hud))
	hud.register_provider("construction",preload("res://scripts/hud/content/dock_content_construction.gd").new(self,hud))
	hud.register_provider("production",preload("res://scripts/hud/content/dock_content_production.gd").new(self,hud))
	hud.register_provider("health",preload("res://scripts/hud/content/dock_detail_health.gd").new(self,hud))
	hud.register_provider("economy",preload("res://scripts/hud/content/dock_content_economy.gd").new(self,hud))
	hud.register_provider("government",preload("res://scripts/hud/content/dock_content_government.gd").new(self,hud))
	hud.register_provider("civ",preload("res://scripts/hud/content/dock_content_civilization.gd").new(self,hud))
	hud.register_provider("inquiry",preload("res://scripts/hud/content/dock_content_inquiry.gd").new(self,hud))
	hud.register_provider("world",preload("res://scripts/hud/content/dock_content_world.gd").new(self,hud))
	hud.register_provider("military",preload("res://scripts/hud/content/dock_content_military.gd").new(self,hud))
	hud.register_provider("chronicle",preload("res://scripts/hud/content/dock_content_chronicle.gd").new(self,hud))
	var audience_director:=preload("res://scripts/audience_director.gd").new();audience_director.terrain=self;layer.add_child(audience_director)
	_update_scale_bar()


func _on_city_battle_started(_engagement:Dictionary)->void:
	if bool(_engagement.get("commander_managed",false)):return
	if bool((_engagement.get("threat",{}) as Dictionary).get("routine_raid",false)): return
	# Time stops so the player sees the two sides drawn up; the battle panel
	# lets the fight go on and follows it as the days pass (hud/battle_panel.gd).
	_set_game_speed(0)
	MilitaryCommandUI.call_deferred("open_engagement",String(_engagement.get("id","")))
func _on_city_aftermath(_aftermath:Dictionary)->void:
	_set_game_speed(0)
	_open_war_planning.call_deferred()

func _restore_military_attention()->void:
	if GeneralCampaign.active:return
	# An older save's captives waiting on the ruler: the general settles them
	# now, as he does after every fight; nothing waits and nothing pauses.
	if not MilitaryCampaign.pending_aftermath.is_empty(): MilitaryCampaign.settle_pending_aftermath()
	if not MilitaryCampaign.active_threat.is_empty(): _on_military_threat_attention(MilitaryCampaign.active_threat,false)
	elif not MilitaryCampaign.active_engagement.is_empty() and not bool(MilitaryCampaign.active_engagement.get("commander_managed",false)) and not bool((MilitaryCampaign.active_engagement.get("threat",{}) as Dictionary).get("routine_raid",false)): _pause_for_military_attention("active_battle","A battle is under way","Our people are fighting. War planning shows where, who is in it and what the general is doing.",false)

func _on_military_threat_attention(threat:Dictionary,truncate_batch:bool=true)->void:
	if threat.is_empty(): return
	if bool(threat.get("routine_raid",false)): return
	if String(threat.get("campaign_mode","defensive"))=="offensive": return
	var location:=String(threat.get("target_region_name",GameState.settlement_name))
	if location.is_empty(): location=GameState.settlement_name
	_pause_for_military_attention(String(threat.get("id","threat")),"An attack is coming", "%s is coming toward %s, perhaps %d strong, and could be there by %s. Time is paused. War planning shows what your war leader means to do; if you carry on without a word, the defenders will fight or give way when they arrive." % [String(threat.get("source_name","A band we cannot name")),location,int(threat.get("estimated_strength",0)),EraWordsMap.when(int(threat.get("deadline_day",GameState.elapsed_days))).to_lower()],truncate_batch)

func _on_battle_attention(result:Dictionary)->void:
	if bool((result.get("threat",{}) as Dictionary).get("routine_raid",false)): return
	# The war leader's report card (hud/battle_report_panel.gd) pauses time
	# itself and resumes it on Continue. Opened deferred so the town taken and
	# the garrison left behind are already on the battle's record.
	var event_id:="battle_%s" % str(result.get("seed",GameState.elapsed_days))
	if military_attention_seen.has(event_id): return
	military_attention_seen[event_id]=true
	GameState.elapsed_days=minf(GameState.elapsed_days,float(_simulated_day()))
	Callable(preload("res://scripts/hud/battle_report_panel.gd"),"open").call_deferred(self,int(result.get("seed",0)),result)

func _pause_for_military_attention(event_id:String,title:String,body:String,truncate_batch:bool=true)->void:
	if military_attention_seen.has(event_id): return
	military_attention_seen[event_id]=true
	if military_attention_seen.size()>64: military_attention_seen.erase(military_attention_seen.keys()[0])
	game_speed=0.0
	# Stop a fast-forward batch at this day, not after several hidden battles.
	# Restored notifications have no running batch: preserve the saved fraction.
	if truncate_batch:GameState.elapsed_days=minf(GameState.elapsed_days,float(_simulated_day()))
	_update_time_interface()
	_show_military_attention.call_deferred(title,body)

func _show_military_attention(title:String,body:String)->void:
	if military_attention_dialog and is_instance_valid(military_attention_dialog): military_attention_dialog.queue_free()
	military_attention_dialog=ConfirmationDialog.new()
	military_attention_dialog.theme=HudT.control_theme()
	military_attention_dialog.title=title
	military_attention_dialog.dialog_text=body
	military_attention_dialog.min_size=Vector2i(650,260)
	military_attention_dialog.ok_button_text="Open war planning"
	military_attention_dialog.cancel_button_text="Stay paused"
	military_attention_dialog.get_label().add_theme_font_size_override("font_size",16)
	military_attention_dialog.get_label().add_theme_color_override("font_color",HudT.INK)
	add_child(military_attention_dialog)
	military_attention_dialog.confirmed.connect(_open_war_planning)
	military_attention_dialog.popup_centered()

func _open_war_planning(_tab:int=0)->void:
	if GeneralCampaign.active:GeneralCampaign.open_screen();return
	## Deep military decisions — threats, engagements, aftermath, fronts —
	## open as the war-planning detail dock beside the military section.
	if hud==null: return
	if not hud.dock.visible or hud.active_section!="military":
		_on_hud_section_requested("military",0)
	hud.open_detail(preload("res://scripts/hud/content/dock_detail_war_planning.gd").new(self,hud))

func _select_army_and_focus(army_id:int)->void:
	## Dock row click: select the army and center the camera on where the
	## government believes it is (its last runner report when info lags).
	var snapshot:Dictionary=MilitaryCampaign.field_armies_snapshot()
	var live_reports:=bool(snapshot.get("live_reports",true))
	for army_variant in (snapshot.get("armies",[]) as Array):
		var army:Dictionary=army_variant
		if int(army.get("army_id",0))!=army_id: continue
		selected_army_id=army_id
		if hud:
			hud.close_detail()
			hud.close_dock()
		zoom_target_size=-1.0
		camera.size=18.0
		var report:Dictionary=army.get("last_report",{})
		var position_data:Dictionary=army.get("position",{})
		var at_home:=String(army.get("status","stationed"))=="stationed" and String(army.get("location_id",""))=="player_home"
		if not live_reports and not at_home and report.is_empty():continue
		if not live_reports and not at_home and not report.is_empty():
			position_data=report.get("position",position_data)
		var world_position:=Vector3(float(position_data.get("x",0.0)),0.0,float(position_data.get("z",0.0)))
		world_position.y=_height_at(world_position.x,world_position.z)
		_set_camera_target(world_position)
		_refresh_player_field_army_markers()
		if travel_status_label:
			travel_status_label.text="%s is selected. Its general chooses the road; tell them where to go through the court." % String(army.get("name","The army"))
		break

func _report_military_action(result:Dictionary)->void:
	## Surface a campaign action's outcome in the status ticker and refresh
	## the dock immediately so the change is visible.
	if travel_status_label:
		travel_status_label.text=PaperKit.sentence(String(result.get("message",result.get("error",""))))
	if hud:
		hud.show_action_feedback(String(result.get("message",result.get("error",""))))
		hud.live_refresh_dock()

func _on_hud_section_requested(section:String,sub:int)->void:
	if settlement_convoy_targeting:_cancel_settlement_convoy_targeting()
	else:_close_founding_site_guide()
	# Every section opens in the slide-out dock beside the rail.
	if section=="":
		hud.close_dock()
		_close_primary_destinations_except("none")
		return
	if hud.has_provider(section):
		_close_primary_destinations_except("none")
		hud.open_dock(section,sub)
		return
	hud.close_dock()

func _on_hud_escape()->void:
	_close_primary_destinations_except("none")
	if hud: hud.set_active_section("")


func _build_map_help(layer:CanvasLayer)->void:
	# The help button and its note are built in scripts/hud/map_notes.gd.
	var help:=MapNotes.build_help(layer,get_viewport().get_visible_rect().size,_toggle_map_help,_dismiss_map_help)
	map_help_button=help.button
	map_help_panel=help.panel
	map_help_title=help.title
	map_help_body=help.body
	# The founding-focus screen is deferred until after the interface is built.  Do
	# not flash map controls underneath that mandatory, mouse-stopping modal.
	var available_on_map:=not capture_render_active and GameState.founding_focus!=""
	map_help_button.visible=available_on_map
	map_help_panel.visible=available_on_map and not map_help_dismissed
	_refresh_map_help()


func _map_help_presentation(site_committed:bool,targeting:bool,settlement_convoy_active:bool)->Dictionary:
	return MapNotes.help_words(site_committed,targeting,settlement_convoy_active)


func _refresh_map_help()->void:
	if map_help_title==null or map_help_body==null: return
	var presentation:=_map_help_presentation(GameState.settlement_site_committed,settlement_convoy_targeting,bool(GameState.settlement_convoy.get("active",false)))
	map_help_title.text=String(presentation.title)
	map_help_body.text=String(presentation.body)
	preload("res://scripts/hud/map_legend.gd").attach(map_help_panel,map_help_button,GameState.settlement_site_committed)
	MapNotes.place_help(map_help_panel,get_viewport().get_visible_rect().size)


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
		if hud.scale_label: hud.scale_label.tooltip_text="About %s feet above the land. The scale is measured at the middle of the view." % EraWordsMap.grouped(roundi(aerial_altitude_feet()))

func _camera_scale_band() -> String:
	if camera==null: return "WORLD"
	if camera.size<=0.8: return "SITE"
	if camera.size<=8.0: return "SETTLEMENT"
	if camera.size<=80.0: return "LOCAL"
	if camera.size<=800.0: return "REGION"
	if camera.size<=8000.0: return "CONTINENT"
	return "WORLD"

func _convoy_water_readout()->String:
	if settler_marker==null: return "WATER: UNKNOWN"
	var advice:=_founding_site_advice(settler_marker.position)
	if not bool(advice.valid):
		return "Fresh water unconfirmed · Review site"
	return "Water %.1f km · %s" % [float(advice.distance_km),"Review site" if bool(advice.water_recommended) else "Long carry"]


func _north_screen_arrow() -> String:
	if camera==null: return "↑"
	var center_screen:=camera.unproject_position(camera_target)
	# Compass orientation must not be distorted by the elevation of whatever hill
	# happens to lie north of the camera target. Project two points on one plane.
	var north_point:=camera_target+Vector3(0.0,0.0,-maxf(4.0,camera.size*0.25))
	north_point.y=camera_target.y
	var delta:=camera.unproject_position(north_point)-center_screen
	return _screen_direction_arrow(delta)


func _screen_direction_arrow(delta:Vector2)->String:
	if delta.length_squared()<0.001: return "↑"
	var angle:=atan2(delta.y,delta.x)
	var arrows:=["→","↘","↓","↙","←","↖","↑","↗"]
	return arrows[wrapi(roundi(angle/(PI/4.0)),0,8)]

func _open_settlement_naming_panel(settlement_id:String="") -> void:
	if not GameState.settlement_site_committed:
		if travel_status_label:
			travel_status_label.text="Found the first settlement before you name it."
		return
	if settlement_naming_panel:
		return
	var target:Dictionary=_settlement_model().settlement_by_id(settlement_id if settlement_id!="" else GameState.selected_player_settlement_id)
	if target.is_empty(): target=_settlement_model().selected_settlement_snapshot()
	# The first name is chosen before the Hearth Circle creates the permanent
	# settlement record. Keep that founding flow available, then let every later
	# settlement use its persistent record.
	if target.is_empty() and "Hearth Circle" not in GameState.settlement_completed:
		target={"id":"__founding__","name":GameState.settlement_name}
	if target.is_empty(): return
	settlement_naming_target_id=String(target.get("id",""))
	naming_previous_speed=game_speed
	_set_game_speed(0.0)
	if settlement_naming_target_id=="__founding__":
		# At the first fire the Hearth Chief asks the name, in their own voice.
		var fire:Control=preload("res://scripts/hud/fire_circle_opening.gd").new()
		fire.mode="name"
		settlement_naming_panel=fire
		interface_layer.add_child(fire)
		settlement_name_input=fire.name_input
		settlement_name_input.text=String(target.get("name",""))
		settlement_name_input.text_changed.connect(_on_settlement_name_changed)
		settlement_name_input.text_submitted.connect(_on_settlement_name_submitted)
		settlement_name_confirm=fire.name_confirm
		settlement_name_confirm.disabled=settlement_name_input.text.strip_edges()==""
		settlement_name_confirm.pressed.connect(_commit_settlement_name)
		fire.later_button.pressed.connect(_dismiss_settlement_naming_panel)
		return
	# A paper card over the dimmed map (paper_kit.gd): the name, Not now, Rename.
	var parts:=PaperKit.modal(interface_layer,520.0,HudT.GOLD,"RenameSettlement")
	settlement_naming_panel=parts[0]
	var column:VBoxContainer=parts[1]
	PaperKit.label(column,"Rename","kicker")
	PaperKit.label(column,"A new name for %s" % String(target.get("name","this settlement")),"title")
	PaperKit.label(column,"The name shows on the map, in the Chronicle and in what our people say.","body").custom_minimum_size.x=460
	settlement_name_input=LineEdit.new()
	settlement_name_input.placeholder_text="The new name"
	settlement_name_input.max_length=32
	settlement_name_input.text=String(target.get("name",""))
	settlement_name_input.custom_minimum_size=Vector2(0,44)
	settlement_name_input.add_theme_font_size_override("font_size",18)
	settlement_name_input.text_changed.connect(_on_settlement_name_changed)
	settlement_name_input.text_submitted.connect(_on_settlement_name_submitted)
	column.add_child(settlement_name_input)
	var footer:=HBoxContainer.new()
	footer.alignment=BoxContainer.ALIGNMENT_END
	footer.add_theme_constant_override("separation",10)
	column.add_child(footer)
	PaperKit.button(footer,"Not now",false,_dismiss_settlement_naming_panel)
	settlement_name_confirm=PaperKit.button(footer,"Rename",true,_commit_settlement_name)
	settlement_name_confirm.disabled=settlement_name_input.text.strip_edges()==""
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
	var result:Dictionary
	if settlement_naming_target_id=="__founding__":
		GameState.settlement_name=chosen.substr(0,32)
		result={"ok":true,"name":GameState.settlement_name}
	else:
		result=_settlement_model().rename_settlement(settlement_naming_target_id,chosen)
	if not bool(result.get("ok",false)):
		if travel_status_label: travel_status_label.text=PaperKit.sentence(String(result.get("reason","That name could not be given")))
		return
	var final_name:=String(result.get("name",chosen))
	var description:="The selected settlement is now known as %s." % final_name
	if settlement_naming_panel and settlement_naming_panel.has_method("named_line"):
		description="%s At the first fire the people named their home %s." % [String(settlement_naming_panel.named_line(final_name)),final_name]
	var event:={"day":int(GameState.elapsed_days),"title":"Settlement Named","description":description,"domain":"settlement","severity":"major"}
	GameState.simulation_events.push_front(event)
	if GameState.simulation_events.size()>80: GameState.simulation_events.resize(80)
	if travel_status_label:
		travel_status_label.text="The settlement is now called %s." % final_name
	_update_time_interface()
	_dismiss_settlement_naming_panel()

func _dismiss_settlement_naming_panel() -> void:
	if settlement_naming_panel:
		settlement_naming_panel.queue_free()
		settlement_naming_panel=null
	settlement_name_input=null
	settlement_name_confirm=null
	settlement_naming_target_id=""
	_set_game_speed(naming_previous_speed)

func _toggle_resource_view()->void:
	_set_resource_view_enabled(not resource_view_enabled)


func _set_resource_view_enabled(enabled:bool)->void:
	resource_view_enabled=enabled
	if enabled: rendered_resource_overlay_zoom_key=""
	for material in terrain_fog_materials.live_materials():
		if material.get_shader_parameter("land_resources")!=null:
			material.set_shader_parameter("land_resources",1.0 if enabled else 0.0)
	for river_overlay in river_overlays:
		if not is_instance_valid(river_overlay) or not String(river_overlay.name).ends_with("Water"): continue
		if river_overlay.material_override is ShaderMaterial:
			(river_overlay.material_override as ShaderMaterial).set_shader_parameter("resource_emphasis",1.0 if enabled else 0.0)
	_update_scale_lod()


func _refresh_discovered_resource_overlays() -> void:
	SettlementModel.with_city_resources(GameState.selected_player_settlement_id,_refresh_local_resource_overlays)

func _refresh_local_resource_overlays() -> void:
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
	var visual_fields:Array=[GameState.world_seed,CivilizationSystem.fog_revision,GameState.selected_player_settlement_id]
	for cluster in clusters:
		if String(cluster.resource) in ["Timber","Game","Fertile Soil","Fiber Plants"]:continue
		visual_fields.append([cluster.resource,cluster.position,cluster.visual_stage])
	var signature:=str(hash(visual_fields))
	if resource_overlay_root and is_instance_valid(resource_overlay_root) and signature==rendered_resource_overlay_signature:
		resource_overlay_root.visible=true
		rendered_resource_overlay_zoom_key=_resource_overlay_view_key()
		return
	rendered_resource_overlay_signature=signature
	if resource_overlay_root and is_instance_valid(resource_overlay_root):
		resource_overlay_root.queue_free()
	resource_overlay_root=Node3D.new()
	resource_overlay_root.name="RecognizedResourceOverlayBatches"
	resource_overlay_root.visible=resource_view_enabled
	add_child(resource_overlay_root)
	discovered_resource_overlays.clear()
	for cluster in clusters:
		if String(cluster.resource) in ["Timber","Game","Fertile Soil","Fiber Plants"]: continue
		var patch:=_resource_ground_indication(cluster)
		resource_overlay_root.add_child(patch)
		if resource_overlay_root.get_child_count()>=16: break
	rendered_resource_overlay_zoom_key=_resource_overlay_view_key()

func _resource_ground_indication(cluster:Dictionary)->MeshInstance3D:
	# An indication is an approximate exposed-ground area, not a surveyed ore
	# boundary. It only exists for already recognized local occurrences.
	var center:Vector3=cluster.position
	var style:=LANDSCAPE_VISUALS.surface_style(String(cluster.resource))
	var radius:=0.35 if String(cluster.visual_stage)=="recognized" else 0.65
	var surface:=SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z in 12:
		for x in 12:
			for corner in [Vector2i(0,0),Vector2i(0,1),Vector2i(1,1),Vector2i(0,0),Vector2i(1,1),Vector2i(1,0)]:
				var offset:=Vector2(float(x+corner.x)/12.0*2.0-1.0,float(z+corner.y)/12.0*2.0-1.0)*radius
				var point:=Vector2(center.x,center.z)+offset
				var mottling:=clampf(0.55+detail_noise.get_noise_2d(point.x*8.0,point.y*8.0),0.0,1.0)
				var edge:=1.0-smoothstep(0.25,1.0,offset.length()/radius+mottling*0.20)
				if not _world_position_is_revealed(Vector3(point.x,0.0,point.y)): edge=0.0
				var soil:Color=style.soil
				soil.a=edge*mottling*0.50
				surface.set_color(soil)
				surface.add_vertex(Vector3(point.x,_height_at(point.x,point.y)+0.002,point.y))
	var patch:=MeshInstance3D.new()
	patch.name="RecognizedGround_%s" % String(cluster.resource).replace(" ","")
	patch.mesh=surface.commit()
	patch.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material:=ShaderMaterial.new()
	material.shader=preload("res://scripts/shaders/resource_ground.gdshader")
	material.set_shader_parameter("occurrence_center",Vector2(center.x,center.z))
	material.set_shader_parameter("layered",bool(style.get("layered",false)))
	var sediment_random:=RandomNumberGenerator.new()
	sediment_random.seed=GameState.world_seed^int(center.x*1000.0)^int(center.z*1700.0)
	material.set_shader_parameter("sediment_axis",Vector2.from_angle(sediment_random.randf()*TAU))
	patch.material_override=material
	if bool(style.outcrops): _add_resource_outcrops(patch,center,style)
	return patch

func _add_resource_outcrops(parent:Node3D,center:Vector3,style:Dictionary)->void:
	var surface:=SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var random:=RandomNumberGenerator.new()
	random.seed=GameState.world_seed^int(center.x*1000.0)^int(center.z*1700.0)
	var vertex_count:=0
	var strike:=random.randf()*TAU
	var along:=Vector2.from_angle(strike)
	var across:=Vector2(-along.y,along.x)
	var layered:=bool(style.get("layered",false))
	for rock in 14:
		var ledge:=layered and rock<8
		var offset:=along*(float(rock)-3.5)*0.020+across*random.randf_range(-0.015,0.015) if ledge else Vector2(random.randf_range(-0.075,0.075),random.randf_range(-0.075,0.075))
		var point:=Vector2(center.x,center.z)+offset
		if not _world_position_is_revealed(Vector3(point.x,0.0,point.y)): continue
		var radius:=random.randf_range(0.006,0.013) if ledge else random.randf_range(0.002,0.007)
		var angle:=strike+random.randf_range(-0.13,0.13) if ledge else random.randf()*TAU
		var elongation:=Vector2(random.randf_range(1.6,2.2),random.randf_range(0.48,0.72)) if ledge else Vector2(random.randf_range(0.8,1.3),random.randf_range(0.65,1.0))
		var rise:=radius*(0.28 if ledge else 0.68)
		var rings:Array[Array]=[]
		var radial_variation:Array[float]=[]
		for side in 12: radial_variation.append(random.randf_range(0.82,1.15))
		for level in 3:
			var ring:Array[Vector3]=[]
			var scale:float=[1.0,0.96,0.90][level]
			var height:float=[0.0003,rise*0.35,rise][level]
			for side in 12:
				var radial:=Vector2.from_angle(float(side)*TAU/12.0)
				if ledge: radial/=pow(pow(absf(radial.x),4.0)+pow(absf(radial.y),4.0),0.25)
				radial*=elongation*radius*scale*radial_variation[side]
				var corner:=point+radial.rotated(angle)+across*float(level)*radius*0.06
				ring.append(Vector3(corner.x,_height_at(corner.x,corner.y)+height,corner.y))
			rings.append(ring)
		for level in 2:
			for side in 12:
				var next:=(side+1)%12
				var shade:Color=(style.rock as Color).darkened(random.randf_range(0.02,0.13)+(0.05 if level==0 else 0.0))
				for vertex in [rings[level][side],rings[level+1][side],rings[level+1][next],rings[level][side],rings[level+1][next],rings[level][next]]:
					surface.set_color(shade)
					surface.add_vertex(vertex)
					vertex_count+=1
		var top:=Vector3(point.x,_height_at(point.x,point.y)+rise,point.y)
		for side in 12:
			for vertex in [top,rings[2][(side+1)%12],rings[2][side]]:
				surface.set_color((style.rock as Color).darkened(random.randf_range(0.0,0.06)))
				surface.add_vertex(vertex)
				vertex_count+=1
	if vertex_count==0: return
	surface.generate_normals()
	var rocks:=MeshInstance3D.new()
	rocks.name="ExposedRockFaces"
	rocks.mesh=surface.commit()
	var material:=ShaderMaterial.new()
	material.shader=preload("res://scripts/shaders/resource_outcrop.gdshader")
	material.set_shader_parameter("layered",layered)
	rocks.material_override=material
	parent.add_child(rocks)

func _surface_resource_report(position:Vector3)->String:
	if _main_river_distance_at(position.x,position.z)<0.09:
		return GroundLens.river_channel()
	var biome:=_biome_at(position.x,position.z)
	if String(biome.id)=="water": return ""
	return GroundLens.surface(String(biome.label),_woodland_density_at(position.x,position.z),"plenty" if float(biome.stone)>0.5 else "some" if float(biome.stone)>0.12 else "little","rich" if float(biome.fertility)>0.65 else "fair" if float(biome.fertility)>0.3 else "poor","plenty" if _surface_material_density(biome,"Fiber Plants")>0.4 else "some" if _surface_material_density(biome,"Fiber Plants")>=0.08 else "little")

func _surface_material_density(biome:Dictionary,resource:String)->float:
	if String(biome.id)=="water": return 0.0
	match resource:
		"Timber": return float(biome.woodland)
		"Stone": return clampf(float(biome.stone),0.0,1.0)
		"Fiber Plants": return clampf(float(biome.forage)*0.55+float(biome.woodland)*0.35+(0.25 if String(biome.id)=="wetland" else 0.0),0.0,1.0)
	return 0.0

func _surface_material_catchments(origin:Vector3)->Dictionary:
	var totals:={"Timber":0.0,"Stone":0.0,"Fiber Plants":0.0}
	var positions:={"Timber":Vector2.ZERO,"Stone":Vector2.ZERO,"Fiber Plants":Vector2.ZERO}
	for z in [-1.0,0.0,1.0]:
		for x in [-1.0,0.0,1.0]:
			var point:=Vector2(origin.x+x,origin.z+z)
			var biome:=_biome_at(point.x,point.y)
			for resource in totals:
				var value:=_surface_material_density(biome,resource)
				totals[resource]+=value
				positions[resource]+=point*value
	var result:Dictionary={}
	for resource in totals:
		var density:=float(totals[resource])
		if density<=0.001:
			result[resource]={"density":0.0}
			continue
		var center:Vector2=positions[resource]/density
		result[resource]={"density":density/9.0,"area_km2":9.0,"position":Vector3(center.x,_height_at(center.x,center.y),center.y)}
	return result

func _woodland_catchment(origin:Vector3)->Dictionary:
	return _surface_material_catchments(origin).Timber


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
		# Cheapest test first: most known occurrences lie outside the view.
		var position_value:Variant=deposit.get("position",Vector3.ZERO)
		if not position_value is Vector3: continue
		var position:=position_value as Vector3
		var planar:=Vector2(position.x,position.z)
		var distance_squared:=planar.distance_squared_to(view_center)
		if distance_squared>view_radius*view_radius: continue
		var resource_name:=String(deposit.get("resource","Resource"))
		if resource_name=="Freshwater" or String(deposit.get("landscape_source","")).ends_with("_catchment"): continue
		var stage:=String(deposit.get("stage","recognized"))
		var strategic:=stage in ["accessible","developed"]
		if zoom>240.0 and not strategic: continue
		# The reveal test walks the charted areas; ask it only of occurrences in view.
		if reveal_filter.is_valid() and not bool(reveal_filter.call(position)): continue
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
	var confirmed:Array[Dictionary]=[]
	var view_center:=Vector2(camera.global_position.x,camera.global_position.z) if camera!=null else Vector2.ZERO
	var view_radius:float=camera.size*1.5+100.0 if camera!=null else INF
	for city:Dictionary in CivilizationSystem.city_intelligence.known_cities("player","",false,view_center,view_radius):
		var location:Dictionary=city.position
		confirmed.append({"detailed":camera!=null and camera.size<=2.0,"city_id":city.city_id,"civ_id":city.civ_id,"name":city.name,"x":float(location.x),"z":float(location.z),"report":city})
	if camera!=null:
		confirmed.sort_custom(func(a:Dictionary,b:Dictionary)->bool: return Vector2(a.x,a.z).distance_squared_to(Vector2(camera.global_position.x,camera.global_position.z))<Vector2(b.x,b.z).distance_squared_to(Vector2(camera.global_position.x,camera.global_position.z)))
	# Keep the mesh budget separate from known names: labels survive at every distance.
	for index in range(64,confirmed.size()):confirmed[index].detailed=false
	var visible_ids:Dictionary={}
	for site:Dictionary in confirmed:visible_ids[String(site.city_id)]=true
	for city_id in contact_encounter_markers.keys():
		if visible_ids.has(city_id):continue
		var stale:Node3D=contact_encounter_markers[city_id]
		if is_instance_valid(stale):stale.hide();stale.queue_free()
		contact_encounter_markers.erase(city_id)
	for site:Dictionary in confirmed:
		# Report dates, stores, confidence and other cities do not change this mesh.
		var previous:Node3D=contact_encounter_markers.get(String(site.city_id))
		var prior_population:=int(previous.get_meta("visual_population",-1)) if is_instance_valid(previous) else -1
		var population:=preload("res://scripts/foreign_settlement_visual.gd").stable_population(site.report,prior_population)
		var appearance:Array=[site.detailed,site.civ_id,site.name,site.x,site.z,population if site.detailed else -1,not site.report.get("fields",{}).is_empty()]
		if is_instance_valid(previous):
			var existing_label:=previous.get_node_or_null("SettlementLabel") as Label3D
			if existing_label:
				existing_label.text=_city_map_label(String(site.name),-1,site.report.get("fields",{}).get("population",{}))
			if previous.get_meta("appearance",[])==appearance:
				_apply_city_ownership(previous,site.report)
				continue
			# queue_free is deferred; hide the old mesh now to avoid an overlapping frame.
			previous.hide();previous.queue_free()
		var marker:=Node3D.new()
		marker.set_meta("appearance",appearance)
		marker.set_meta("visual_population",population)
		marker.name="ConfirmedForeignSettlement_%s" % String(site.city_id)
		marker.set_meta("civilization_id",String(site.civ_id)); marker.set_meta("city_id",String(site.city_id))
		marker.set_meta("settlement_name",String(site.name))
		marker.position=Vector3(float(site.x),_height_at(float(site.x),float(site.z))+0.05,float(site.z))
		# Close view is actual terrain-aligned settlement fabric, not kilometre-scale boxes.
		marker.position.y=0
		var footprint_radius:=.065
		if bool(site.detailed):
			var fabric:=preload("res://scripts/foreign_settlement_visual.gd").new()
			var visual_report:Dictionary=site.report.duplicate(true)
			if population>=0:visual_report.fields.population.low=population;visual_report.fields.population.high=population
			fabric.build(visual_report,_close_surface_height_at)
			fabric.position.x=0;fabric.position.z=0;marker.add_child(fabric)
			footprint_radius=fabric.footprint_radius
		var label:=Label3D.new();label.name="SettlementLabel";label.text=_city_map_label(String(site.name),-1,site.report.get("fields",{}).get("population",{}))
		label.set_meta("city_map_id",String(site.city_id));label.set_meta("city_map_foreign",true)
		label.font_size=11;label.outline_size=5;label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
		label.fixed_size=true;label.no_depth_test=true;label.modulate=Color("#e4d7b4")
		label.outline_modulate=Color(0.018,0.026,0.028,0.97);label.render_priority=11
		marker.set_meta("footprint_radius",footprint_radius)
		label.position=Vector3(0,_height_at(site.x,site.z)+.015,-footprint_radius*1.15)
		marker.add_child(label)
		var pin:=Label3D.new();pin.name="RegionalCityPin";pin.text="◆";pin.font_size=15;pin.outline_size=5
		pin.billboard=BaseMaterial3D.BILLBOARD_ENABLED;pin.fixed_size=true;pin.no_depth_test=true
		pin.modulate=Color("d9cba3",0.0);pin.outline_modulate=Color(0,0,0,0);pin.position=Vector3(0,_height_at(site.x,site.z)+.015,0);marker.add_child(pin)
		# The pin stays the (invisible) anchor and click target; the chart shows
		# a stranger's town as an open inked diamond.
		var glyph:=MeshInstance3D.new();glyph.name="RegionalCityGlyph";glyph.mesh=QuadMesh.new()
		glyph.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		glyph.material_override=_map_glyph_material(false,16.0)
		glyph.set_instance_shader_parameter("glyph_index",float(RESOURCE_ICONS.SETTLEMENT_GLYPH_FOREIGN))
		glyph.position=pin.position;marker.add_child(glyph)
		_apply_city_ownership(marker,site.report)

		add_child(marker)
		contact_encounter_markers[String(site.city_id)]=marker
	for marker_variant in contact_encounter_markers.values():
		var marker:Node3D=marker_variant
		if marker==null or not is_instance_valid(marker): continue
		marker.visible=camera!=null # A reported city location is known even when surrounding terrain is not surveyed.
		_update_foreign_city_annotation(marker)

## Who holds a known town decides its card's emblem, its mark on the chart and
## the words beside it (scripts/map_ownership.gd). Checked with every map
## snapshot, so a town that falls changes on the chart at once.
func _apply_city_ownership(marker:Node3D,report:Dictionary)->void:
	var ownership:=preload("res://scripts/map_ownership.gd").status(report)
	var label:=marker.get_node_or_null("SettlementLabel") as Label3D
	if label:
		label.set_meta("city_civilization_id",String(ownership.emblem))
		label.set_meta("map_ownership",ownership)
		# Name tags keep clear of the (larger) mark.
		label.set_meta("glyph_clearance",float(ownership.mark_px)*0.32+2.0)
	var glyph:=marker.get_node_or_null("RegionalCityGlyph") as GeometryInstance3D
	if glyph==null:return
	if int(glyph.get_meta("glyph",-1))!=int(ownership.glyph):
		glyph.set_meta("glyph",int(ownership.glyph))
		glyph.set_instance_shader_parameter("glyph_index",float(ownership.glyph))
		glyph.material_override=_map_glyph_material(false,float(ownership.mark_px))
	var accent:Color=ownership.accent
	if glyph.get_meta("accent",Color(0,0,0,0))!=accent:
		glyph.set_meta("accent",accent)
		var linear:=accent.srgb_to_linear()
		glyph.set_instance_shader_parameter("accent",Vector4(linear.r,linear.g,linear.b,accent.a))

func _update_foreign_city_annotation(marker:Node3D)->void:
	var label:=marker.get_node_or_null("SettlementLabel") as Label3D
	if label:
		label.visible=camera!=null
		if camera!=null:
			var close:=camera.size<=2.4
			var base_font_size:=10 if close or camera.size>1600.0 else 12
			if label.has_meta("aerial_font_size"):
				label.set_meta("aerial_font_size",base_font_size)
				label.font_size=base_font_size*4
			else:label.font_size=base_font_size
			label.outline_size=3 if close else 4
			var screen_up:=Vector2(camera.global_basis.y.x,camera.global_basis.y.z)
			if screen_up.length_squared()<.0001:screen_up=Vector2(0,-1)
			var radius:=float(marker.get_meta("footprint_radius",.065))
			var offset:=minf(camera.size*.28,maxf(.095,radius*.12)) if close else maxf(camera.size*.030,minf(radius*.36,camera.size*.18))
			var ground:=Vector2(marker.position.x,marker.position.z)+screen_up.normalized()*offset
			label.position=Vector3(ground.x-marker.position.x,_height_at(ground.x,ground.y)+.13,ground.y-marker.position.z)
		_update_city_flag(label)
	var pin:=marker.get_node_or_null("RegionalCityPin") as Label3D
	if pin:
		pin.visible=camera!=null and camera.size>2.0
		if label:pin.modulate=Color(label.modulate,0.0)
		var glyph:=marker.get_node_or_null("RegionalCityGlyph") as Node3D
		if glyph:glyph.visible=pin.visible


func _refresh_foreign_formation_markers()->void:
	var observation:Dictionary=CivilizationSystem.local_observation_snapshot()
	rendered_observation_revision=int(observation.get("revision",0))
	# Use the same bounded snapshot pass as player armies so foreign stacks receive
	# collision spacing and label budgets before nodes are placed on the terrain.
	var presentation:Dictionary=WarfareMapPresentation.build_snapshot(camera.size if camera else 190.0,[],observation.get("visible",[]),[],[],{},0,EraWordsMap.stage())
	var visible_ids:Dictionary={}
	for view_variant in presentation.get("foreign",[]):
		var view:Dictionary=view_variant
		var sighting_id:=String(view.get("id","")); visible_ids[sighting_id]=true
		var position_data:Dictionary=view.get("position",{})
		var world_position:=Vector3(float(position_data.get("x",0.0)),0.0,float(position_data.get("z",0.0)))
		var display_offset:Dictionary=view.get("display_offset",{})
		world_position.x+=float(display_offset.get("x",0.0))
		world_position.z+=float(display_offset.get("z",0.0))
		world_position.y=_height_at(world_position.x,world_position.z)+WarfareMapPresentation.marker_ground_clearance(camera.size if camera else 190.0)
		var marker:Node3D=foreign_formation_markers.get(sighting_id,null)
		if marker==null or not is_instance_valid(marker):
			marker=_create_warfare_formation_marker("Observed_%s" % sighting_id,false)
			add_child(marker); foreign_formation_markers[sighting_id]=marker
		marker.position=world_position
		_apply_warfare_formation_view(marker,view)
		marker.visible=bool(view.get("visible",false)) and _world_position_is_revealed(marker.global_position) and not EraWordsMap.hearth()
	for sighting_id in foreign_formation_markers.keys():
		if visible_ids.has(String(sighting_id)): continue
		var stale:Node3D=foreign_formation_markers[sighting_id]
		if stale and is_instance_valid(stale): stale.queue_free()
		foreign_formation_markers.erase(sighting_id)


func _refresh_player_field_army_markers()->void:
	var state:Dictionary=MilitaryCampaign.field_armies_snapshot()
	var marker_selected_id:=selected_army_id
	if marker_selected_id<=0 and MilitaryCommandUI!=null and MilitaryCommandUI.has_method("selected_field_army_id"): marker_selected_id=MilitaryCommandUI.selected_field_army_id()
	var front_state:Dictionary=CivilizationSystem.military_fronts_snapshot()
	# Until signal-era development, the map shows each away army where its most
	# recent RUNNER reported it — not where it physically is right now.
	var reported_armies:Array=[]
	var live_reports:=bool(state.get("live_reports",true))
	for army_variant in (state.get("armies",[]) as Array):
		var army:Dictionary=(army_variant as Dictionary).duplicate(true)
		var at_home:=String(army.get("status","stationed"))=="stationed" and String(army.get("location_id",""))=="player_home"
		var report:Dictionary=army.get("last_report",{})
		if not live_reports and not at_home and report.is_empty():continue
		if not live_reports and not at_home and not report.is_empty():
			army["position"]=(report.get("position",army.get("position",{})) as Dictionary).duplicate(true)
			army["status"]=String(report.get("status",army.get("status","stationed")))
			army["troops"]=int(report.get("troops",army.get("troops",0)))
			army["supply_level"]=float(report.get("supply_level",army.get("supply_level",1.0)))
			army["readiness"]=float(report.get("readiness",army.get("readiness",0.0)))
			army["distance_remaining_km"]=float(report.get("distance_remaining_km",army.get("distance_remaining_km",0.0)))
			army["remaining_troops"]=int(army.troops)
			army["formations"]=[] # Report gives aggregate strength, not live hidden cohort equipment.
			army["report_age_days"]=maxi(0,int(GameState.elapsed_days)-int(report.get("day",GameState.elapsed_days)))
		if int(army.get("troops",0))<=0:
			if selected_army_id==int(army.get("army_id",0)):_clear_army_selection()
			continue
		reported_armies.append(army)
	var presentation:Dictionary=WarfareMapPresentation.build_snapshot(camera.size if camera else 190.0,reported_armies,[],front_state.get("fronts",[]),state.get("destinations",[]),MilitaryCampaign.engagement_snapshot(),marker_selected_id,EraWordsMap.stage())
	var visible_ids:Dictionary={}
	for view_variant in presentation.get("player",[]):
		var view:Dictionary=view_variant
		var army_id:=String(view.get("id","")); visible_ids[army_id]=true
		var position_data:Dictionary=view.get("position",{})
		var world_position:=Vector3(float(position_data.get("x",0.0)),0.0,float(position_data.get("z",0.0)))
		var display_offset:Dictionary=view.get("display_offset",{})
		world_position.x+=float(display_offset.get("x",0.0))
		world_position.z+=float(display_offset.get("z",0.0))
		world_position.y=_height_at(world_position.x,world_position.z)+WarfareMapPresentation.marker_ground_clearance(camera.size if camera else 190.0)
		var marker:Node3D=player_field_army_markers.get(army_id,null)
		if marker==null or not is_instance_valid(marker):
			marker=_create_warfare_formation_marker("PlayerFieldArmy_%s" % army_id,true)
			add_child(marker); player_field_army_markers[army_id]=marker
		marker.position=world_position
		_apply_warfare_formation_view(marker,view)
		# Own armies are known reports; marker visibility must not depend on
		# unsurveyed ground beneath a cosmetic stack offset.
		marker.visible=bool(view.get("visible",false)) and int(get_meta("city_encounter_army",-1))!=int(army_id)
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
	# Ground representatives must agree with the same runner report and selection
	# as the counter. Zooming in must not reveal an away army's live coordinates.
	for occupation:Dictionary in MilitaryCampaign.occupation_forces:
		# No dated occupation-strength report exists before live communications.
		if not live_reports:continue
		if int(occupation.get("troops",0))<=0:continue
		var report:Dictionary=CivilizationSystem.city_intelligence.known("player",String(occupation.get("region_id","")))
		if report.is_empty():continue
		var display:=occupation.duplicate(true);display["army_id"]=-1-absi(String(occupation.region_id).hash());display["position"]=report.position;display["status"]="stationed";display["garrison_visual"]=true
		reported_armies.append(display)
	_refresh_close_army_figures(reported_armies,marker_selected_id)


func _on_scout_report_returned(report:Dictionary)->void:
	if not ScoutArchive.newsworthy(report):return
	# The simulation owns report delivery and storage. Arrival is told by the
	# Chronicle's card (chronicle.gd), never a pause or a second toast.
	if travel_status_label:
		travel_status_label.text="The scouts are home. Their tale is in the Chronicle."


func _open_foreign_formation_from_screen(screen_position:Vector2)->bool:
	## Foreign counters are first-class map targets. Clicking one opens the
	## complete next-action card; no report screen or hidden menu is required.
	if camera==null: return false
	var best:Dictionary={}
	var best_distance:=42.0
	# Above the close view the war chart draws the marks: its hit test decides.
	var war_mark:=_war_mark_at(screen_position)
	var charted:=_war_chart_draws_marks()
	for sighting_variant in CivilizationSystem.local_observation_snapshot().get("visible",[]):
		var sighting:Dictionary=sighting_variant
		if charted:
			if String(war_mark.get("kind",""))=="sighting" and String(war_mark.get("enemy_id",""))==String(sighting.get("id","")): best=sighting
			continue
		var marker:Node3D=foreign_formation_markers.get(String(sighting.get("id","")),null)
		if marker==null or not is_instance_valid(marker) or not marker.visible: continue
		if camera.is_position_behind(marker.global_position): continue
		var distance:=screen_position.distance_to(camera.unproject_position(marker.global_position))
		if distance<best_distance:
			best_distance=distance
			best=sighting
	if best.is_empty(): return false
	if hud:
		_on_hud_section_requested("military",0)
		hud.open_detail(preload("res://scripts/hud/content/dock_detail_map_contact.gd").new(self,hud,String(best.get("id",""))))
	if travel_status_label:
		travel_status_label.text="Strangers in sight. The card on the left says what we see and who to ask."
	return true


func _select_field_army_from_screen(screen_position:Vector2)->bool:
	## Nearest army marker within a small screen radius becomes the selection.
	if camera==null: return false
	var best_id:=-1
	var best_distance:=34.0
	# Above the close view the war chart draws the marks: its hit test decides.
	var war_mark:=_war_mark_at(screen_position)
	if String(war_mark.get("kind",""))=="army": best_id=int(war_mark.get("army_id",-1))
	for army_id in ({} if _war_chart_draws_marks() else player_field_army_markers):
		var marker:Node3D=player_field_army_markers[army_id]
		if marker==null or not is_instance_valid(marker) or not marker.visible: continue
		if camera.is_position_behind(marker.global_position): continue
		var marker_screen:=camera.unproject_position(marker.global_position)
		var distance:=screen_position.distance_to(marker_screen)
		if distance<best_distance:
			best_distance=distance
			best_id=int(String(army_id))
	if best_id<0:
		if selected_army_id!=-1:
			_clear_army_selection()
		return false
	selected_army_id=best_id
	var snapshot:Dictionary=MilitaryCampaign.field_armies_snapshot()
	for army_variant in (snapshot.get("armies",[]) as Array):
		var army:Dictionary=army_variant
		if int(army.get("army_id",0))!=best_id: continue
		if travel_status_label:
			travel_status_label.text="%s is selected. Its general chooses the road; tell them where to go through the court." % String(army.get("name","The army"))
		break
	return true


## The force mark the war chart drew under a screen point, if any.
func _war_mark_at(screen_position:Vector2)->Dictionary:
	var chart:=get_node_or_null("WarMapMarks/WarFrontOverlay")
	return chart.mark_at(screen_position) if chart!=null and chart.has_method("mark_at") else {}


## Whether the war chart, not the close view, is drawing the force marks.
func _war_chart_draws_marks()->bool:
	return get_node_or_null("WarMapMarks/WarFrontOverlay")!=null and camera!=null and WarfareMapPresentation.scale_band(camera.size) not in ["ground","world"]


func _clear_army_selection()->void:
	selected_army_id=-1
	if travel_status_label and "is selected" in travel_status_label.text:
		travel_status_label.text=""


func _order_selected_army_to_screen(screen_position:Vector2)->void:
	if selected_army_id<0: return
	var hit:Dictionary=_terrain_hit(screen_position)
	if hit.is_empty() or not hit.get("position") is Vector3:
		_report_military_action({"error":"No ground under the order. Right-click land on the map."})
		return
	var hit_position:Vector3=hit.position
	var target:=Vector2(hit_position.x,hit_position.z)
	var city_target:=_contact_encounter_at(hit_position,0.15)
	if city_target.has("city_id"):
		var city_order:=MilitaryCampaign.move_field_army(selected_army_id,String(city_target.city_id))
		_report_military_action(city_order)
		return
	if not CivilizationSystem._position_is_revealed(target):
		_report_military_action({"error":"Uncharted ground. Send scouts first; armies march where returned reports have charted land."})
		return
	if not _world_surface_is_land(hit_position):
		_report_military_action({"error":"Open water. Choose a charted land destination."})
		return
	var result:Dictionary=MilitaryCampaign.move_field_army_to_position(selected_army_id,target.x,target.y,"MARKED GROUND")
	_report_military_action(result)


func _world_surface_is_land(position:Vector3)->bool:
	return CivilizationSystem._scout_land_at(Vector2(position.x,position.z))


func _warfare_arrowhead_mesh(radius:float,height:float,forward:=Vector2.RIGHT)->ArrayMesh:
	# CylinderMesh clamps radial_segments to at least four: use a real triangle.
	var direction:=forward.normalized()
	var side:=Vector2(-direction.y,direction.x)
	var points:=[-direction*radius*0.5-side*radius*0.8660254,direction*radius,-direction*radius*0.5+side*radius*0.8660254]
	var surface:=SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_smooth_group(-1)
	for face in [[0,1,2],[2,1,0]]:
		var y:=height*0.5 if face[0]==0 else -height*0.5
		for index in face:
			var point:Vector2=points[index]
			surface.add_vertex(Vector3(point.x,y,point.y))
	for index in 3:
		var a:Vector2=points[index]
		var b:Vector2=points[(index+1)%3]
		for vertex in [Vector3(a.x,height*0.5,a.y),Vector3(a.x,-height*0.5,a.y),Vector3(b.x,-height*0.5,b.y),Vector3(a.x,height*0.5,a.y),Vector3(b.x,-height*0.5,b.y),Vector3(b.x,height*0.5,b.y)]:
			surface.add_vertex(vertex)
	surface.generate_normals()
	return surface.commit()


func _create_warfare_formation_marker(marker_name:String,player_owned:bool)->Node3D:
	# The marker is where a force stands (and, up close, its occupied ground).
	# Its inked mark, paper card and selection ring are drawn by the war chart
	# (hud/war_front_overlay.gd with hud/army_marks.gd); only the close-view
	# label stays a world-space label.
	var marker:=Node3D.new()
	marker.name=marker_name
	var label:=Label3D.new(); label.name="ArmyLabel" if player_owned else "FormationLabel"; label.font_size=8; label.outline_size=3; label.billboard=BaseMaterial3D.BILLBOARD_ENABLED; label.fixed_size=true; label.no_depth_test=true; label.position=Vector3(0,7.6 if player_owned else 7.0,-4.8); label.modulate=Color("#efe3c2"); label.outline_modulate=Color("#2b2118"); label.visible=false; marker.add_child(label)
	_configure_warfare_overlay_layers(marker)
	return marker


func _configure_warfare_overlay_layers(marker:Node3D,base_priority:int=20)->void:
	# Depth-free map counters must share the transparent pass above settlement drapes.
	# Raising an opaque glyph's priority alone cannot put it after transparent roofs.
	for counter_part in marker.get_children():
		if counter_part is Label3D:
			counter_part.render_priority=base_priority+12
		elif counter_part is GeometryInstance3D:
			var counter_material:=counter_part.material_override as StandardMaterial3D
			if counter_material:
				counter_material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
				if not counter_material.has_meta("overlay_relative_priority"):
					counter_material.set_meta("overlay_relative_priority",counter_material.render_priority)
				counter_material.render_priority=base_priority+int(counter_material.get_meta("overlay_relative_priority"))


func _warfare_marker_material(color:Color)->StandardMaterial3D:
	var material:=StandardMaterial3D.new(); material.albedo_color=color; material.emission_enabled=true; material.emission=color.darkened(0.28); material.emission_energy_multiplier=0.38; material.roughness=0.85; material.no_depth_test=true
	if color.a<0.999: material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	return material


func _set_warfare_part_color(part:MeshInstance3D,color:Color)->void:
	var material:=part.material_override as StandardMaterial3D
	if material==null:
		material=_warfare_marker_material(color); part.material_override=material
	material.albedo_color=color; material.emission=color.darkened(0.24)


func _apply_warfare_formation_view(marker:Node3D,view:Dictionary)->void:
	var marker_scale:=maxf(0.0005,float(view.get("scale",1.0)))
	marker.scale=Vector3.ONE*marker_scale
	marker.rotation.y=0.0
	var label:=marker.get_node_or_null("ArmyLabel") as Label3D
	if label==null: label=marker.get_node_or_null("FormationLabel") as Label3D
	if label:
		# Label3D.fixed_size does not cancel an inherited Node3D scale.
		label.scale=Vector3.ONE/marker_scale
		if camera and camera.projection==Camera3D.PROJECTION_PERSPECTIVE:
			label.font_size=32
			label.outline_size=8
			label.pixel_size=0.0003125
		# Only up close, where the war chart stands aside for the formation
		# itself, does the force keep a label in the world (plain words).
		var close:=camera!=null and WarfareMapPresentation.scale_band(camera.size)=="ground"
		label.text=String(view.get("label",""))
		# The war chart letters every force as a small paper card at every
		# zoom, clear of the town cards; the old world label drew large
		# outlined words over them.
		label.visible=false
		label.position=marker.global_basis.inverse()*(camera.global_basis.y*camera.size*.18) if close and view.has("troops") and camera.size<0.35 else Vector3(0,7.6 if view.has("troops") else 7.0,-4.8)
	_apply_physical_army_front(marker, view)

func _apply_physical_army_front(marker: Node3D, view: Dictionary) -> void:
	var front: ArmyFrontVisual = marker.get_node_or_null("OccupiedArmyGround")
	if front == null:
		front = ArmyFrontVisualScript.new(); front.name = "OccupiedArmyGround"; marker.add_child(front)
	var at: Dictionary = view.get("position", {})
	if not at.has_all(["x","z"]):
		front.hide(); return
	var origin := Vector3(float(at.get("x",0)),0,float(at.get("z",0)))
	front.visible = bool(view.get("visible",true)) and (camera == null or (camera.size <= 80.0 and Vector2(origin.x-camera_target.x,origin.z-camera_target.z).length() <= maxf(1.0,camera.size*2.0))) and _world_position_is_revealed(origin)
	if not front.visible:return
	origin.y = _close_surface_height_at(origin.x,origin.z)
	var marker_scale := maxf(0.000001,marker.scale.x)
	front.position = (origin-marker.position)/marker_scale
	front.scale = Vector3.ONE*0.001/marker_scale
	front.ground = func(point: Vector2) -> float: return (_close_surface_height_at(origin.x+point.x*0.001,origin.z+point.y*0.001)-origin.y)*1000.0+0.10
	front.land = func(point: Vector2) -> bool:
		var world:=origin+Vector3(point.x,0,point.y)*0.001
		return _world_position_is_revealed(world) and _settlement_stage_land_at(Vector2(world.x,world.z))
	front.configure(view.get("front_force",{}),Color(String(view.get("color",WarfareMapPresentation.PLAYER_COLOR))),0.0 if bool(view.get("moving",false)) else 1.0,float(view.get("heading",0)))
	var close := camera != null and camera.size <= 8.0
	# Screen-sized informational symbols remain separate from occupied terrain.
	for child in marker.get_children():
		if child is GeometryInstance3D and not child is Label3D and child.name != "SelectedRing":
			child.set_meta("front_symbol_visible",child.visible)
			if close:child.hide()

func _advance_physical_army_fronts(delta: float) -> void:
	for markers in [player_field_army_markers,foreign_formation_markers,close_army_figures]:
		for marker in markers.values():
			if not is_instance_valid(marker): continue
			var front: ArmyFrontVisual = marker.get_node_or_null("OccupiedArmyGround")
			if front != null and front.is_visible_in_tree(): front.advance(delta,game_speed <= 0.0)

func _warfare_label_has_clear_space(label:Label3D)->bool:
	if camera==null: return true
	if camera.is_position_behind(label.global_position): return false
	var viewport_rect:=get_viewport().get_visible_rect()
	var font:Font=label.font if label.font else ThemeDB.fallback_font
	var signature:="%s/%d/%d" % [label.text,label.font_size,font.get_instance_id()]
	if String(label.get_meta("layout_signature",""))!=signature:
		var width:=0.0
		var lines:=label.text.split("\n")
		for line in lines: width=maxf(width,font.get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,label.font_size).x)
		label.set_meta("layout_size",Vector2(width,float(lines.size()*label.font_size)*1.4))
		label.set_meta("layout_signature",signature)
	# Fixed-size labels scale with viewport height, not distance. Use a small
	# conservative margin so the outline also clears the existing HUD panels.
	var pixel_factor:=label.pixel_size*viewport_rect.size.y
	if camera.projection==Camera3D.PROJECTION_PERSPECTIVE:
		pixel_factor*=0.5/tan(deg_to_rad(camera.fov)*0.5)
	var size:Vector2=Vector2(label.get_meta("layout_size"))*pixel_factor+Vector2(12,10)
	var center:=camera.unproject_position(label.global_position)
	var obstacles:Array=[]
	if hud:
		for property in ["rail_panel","time_pill","kpi_strip","toolbar","queue_root","dock","detail_dock"]:
			var panel:=hud.get(property) as Control
			if panel and panel.is_visible_in_tree() and panel.size.x>0.0 and panel.size.y>0.0:
				obstacles.append(panel.get_global_rect())
	return WarfareMapPresentation.label_rect_is_clear(Rect2(center-size*0.5,size),viewport_rect,obstacles)


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
	var visual_zoom:=maxf(0.035,camera.size if camera else 190.0)
	var zoom_bucket:=floori(log(visual_zoom)/log(1.08))
	var signature:="%.1f:%.1f:%.1f:%.1f:%s:%s:%d" % [current.x,current.z,destination.x,destination.z,band,str(bool(view.get("selected",false))),zoom_bucket]
	if existing==null or not is_instance_valid(existing) or String(existing.get_meta("signature",""))!=signature:
		if existing and is_instance_valid(existing): existing.queue_free()
		existing=_create_player_field_army_path(view,current,destination,band)
		existing.set_meta("signature",signature); add_child(existing); player_field_army_paths[army_id]=existing
	existing.visible=true
	var objective:=existing.get_node_or_null("MovementObjective") as Node3D
	if objective:
		var objective_scale:=maxf(0.001,float(view.get("scale",1.0))*0.90)
		objective.scale=Vector3.ONE*objective_scale
		objective.position=Vector3(destination.x,_close_surface_height_at(destination.x,destination.z)+WarfareMapPresentation.marker_ground_clearance(visual_zoom),destination.z)
		var objective_label:=objective.get_node_or_null("ObjectiveLabel") as Label3D
		if objective_label: objective_label.scale=Vector3.ONE/objective_scale


func _seed_capture_scout_chart()->void:
	## Capture scenario: several returned scout charts and one party still out,
	## wandering around the settlement, so the chart styling can be judged.
	## Like real land parties, every seeded leg stays on dry ground: a heading
	## that meets the sea bends along the shore or stops there.
	# The century direction is already chosen so no screen covers the map.
	if WorldSimulation.direction.needs_century_choice(): WorldSimulation.direction.choose(String(PeopleDirection.AMBITIONS.keys()[0]))
	var home:=Vector2(settler_marker.position.x,settler_marker.position.z)
	var rng:=RandomNumberGenerator.new(); rng.seed=90417
	var today:=int(GameState.elapsed_days)
	var reports:Array[Dictionary]=[]
	for index in 8:
		var heading:=float(index)*TAU/8.0+rng.randf_range(-0.3,0.3)
		var route:=_seed_capture_land_walk(home,heading,rng.randf_range(34.0,70.0),rng)
		if route.size()<2: continue
		var last:Dictionary=route[route.size()-1]
		var report:={"mission_id":900+index,"day":today-index*9,"duration_days":24,"route":route,"target_label":"Open exploration","discoveries":[{"kind":"knowledge","title":"A river ford to the %s" % ["north","east","south","west"][index%4]}] if index%2==0 else [],"contact_records":[{"name":"Reed People","position":{"x":lerpf(home.x,float(last.x),0.7),"z":lerpf(home.y,float(last.z),0.7)},"day":today-index*9}] if index==1 else []}
		reports.append(report)
	CivilizationSystem.scout_reports.assign(reports)
	var active_route:=_seed_capture_land_walk(home,-0.9,54.0,rng)
	if active_route.size()<2: active_route=[{"x":home.x,"z":home.y},{"x":home.x+1.0,"z":home.y}]
	CivilizationSystem.scout_missions.assign([{"mission_id":990,"start_day":today-8,"return_day":today+22,"duration_days":30,"route":active_route,"ordered_heading":"northeast","planned_heading":"northeast"}])


func _seed_capture_land_walk(home:Vector2,heading:float,reach:float,rng:RandomNumberGenerator)->Array:
	var route:Array=[{"x":home.x,"z":home.y}]
	var at:=home; var bearing:=heading
	var leg_length:=reach/6.0
	for leg in 6:
		var stepped:=false
		for attempt in 7:
			var turn:=float((attempt+1)/2)*0.45*(1.0 if attempt%2==1 else -1.0)
			var candidate_bearing:=bearing+rng.randf_range(-0.25,0.25)+turn
			var candidate:=at+Vector2.from_angle(candidate_bearing)*leg_length
			var dry:=true
			for k in range(1,9):
				if not _scout_land_at(at.lerp(candidate,float(k)/8.0)): dry=false; break
			if dry:
				at=candidate; bearing=candidate_bearing; stepped=true
				route.append({"x":at.x,"z":at.y})
				break
		if not stepped: break
	return route


const SCOUT_CHART_RETURNED_LIMIT:=6
const ScoutChartStroke:=preload("res://scripts/scout_chart_stroke.gd")

func _refresh_player_scout_route_markers()->void:
	# Scout routes read as an explorer's chart: parties still out are issued
	# plans in solid ink; the last few returned charts are dotted, fading with
	# age. The walker stands at the plan's reckoned position, never the party's
	# true one. Geometry rebuilds only when a route or the zoom step changes.
	var visual_zoom:=maxf(0.035,camera.size if camera else 190.0)
	var band:=WarfareMapPresentation.scale_band(visual_zoom)
	# Stroke widths follow the zoom in the ink shader (scout_chart_ink.gdshader);
	# a route is resampled only when the view has changed by a whole octave.
	var zoom_octave:=floori(log(visual_zoom)/log(2.0))
	var wanted:Array=[]
	for mission_variant in CivilizationSystem.scout_missions:
		var mission:Dictionary=mission_variant
		var mission_id:=str(mission.get("mission_id",""))
		var route:Array=mission.get("route",[])
		if mission_id=="" or route.size()<2: continue
		wanted.append({"key":mission_id,"mission":mission,"route":route,"rank":-1,"content":"%s:%s:%d:%d:%d" % [mission_id,String(mission.get("ordered_heading","")),route.size(),int(mission.get("return_day",0)),int(mission.get("start_day",0))],"scale":"%s:%d" % [band,zoom_octave]})
	var rank:=0
	for report_variant in CivilizationSystem.scout_reports:
		if rank>=SCOUT_CHART_RETURNED_LIMIT: break
		var report:Dictionary=report_variant
		var route:Array=report.get("route",[])
		if route.size()<2: continue
		var key:="report:%d" % int(report.get("mission_id",0))
		wanted.append({"key":key,"mission":report,"route":route,"rank":rank,"content":"%s:%d:%d:%d" % [key,rank,route.size(),int(report.get("day",0))],"scale":"%s:%d" % [band,zoom_octave]})
		rank+=1
	var active_ids:Dictionary={}
	# New or changed routes are drawn at once; routes that only need resampling
	# for a new zoom octave are redrawn one per refresh, so a long zoom never
	# rebuilds every chart in the same frame.
	var rescaled:=false
	for entry_variant in wanted:
		var entry:Dictionary=entry_variant
		var key:String=entry.key
		active_ids[key]=true
		var marker:Node3D=player_scout_route_markers.get(key,null)
		var stale:=marker==null or not is_instance_valid(marker) or String(marker.get_meta("content",""))!=String(entry.content)
		var rescale:=not stale and String(marker.get_meta("scale",""))!=String(entry.scale)
		if stale or (rescale and not rescaled):
			rescaled=rescaled or rescale
			if marker and is_instance_valid(marker): marker.queue_free()
			marker=_create_player_scout_route_marker(entry.mission,entry.route,band,int(entry.rank))
			marker.set_meta("content",entry.content)
			marker.set_meta("scale",entry.scale)
			add_child(marker)
			player_scout_route_markers[key]=marker
		marker.visible=true
	for mission_id in player_scout_route_markers.keys():
		if active_ids.has(String(mission_id)): continue
		var stale:Node3D=player_scout_route_markers[mission_id]
		if stale and is_instance_valid(stale): stale.queue_free()
		player_scout_route_markers.erase(mission_id)


func _scout_route_visual_profile(camera_size:float)->Dictionary:
	# Every size is a fixed fraction of the view, so the ink stays the same
	# number of screen pixels at every zoom (rebuilt per 8% zoom step).
	var zoom:=maxf(0.035,camera_size)
	return {"width":zoom*0.0013,"halo":zoom*0.0028,"tick":zoom*0.010,"mark":zoom*0.022,"dot":zoom*0.0075,"clearance":WarfareMapPresentation.marker_ground_clearance(zoom)}


## Scout chart ink: holds its on-screen width at any zoom (see ScoutChartStroke.Ink).
## Priorities sit in the route band above settlement drapes and below counters.
func _scout_chart_material(priority:int)->ShaderMaterial:
	var material:=ShaderMaterial.new(); material.shader=preload("res://scripts/scout_chart_ink.gdshader"); material.render_priority=10+priority
	return material


func _scout_chart_mark(kind:String,ink:Color,position_2d:Vector2,lift:float,world_size:float)->Sprite3D:
	var mark:=Sprite3D.new(); mark.name="ScoutChartMark_%s" % kind
	mark.texture=preload("res://scripts/resource_icons.gd").chart_texture(kind,Color(ink,1.0))
	mark.billboard=BaseMaterial3D.BILLBOARD_ENABLED; mark.no_depth_test=true; mark.shaded=false; mark.double_sided=true
	mark.alpha_cut=SpriteBase3D.ALPHA_CUT_DISABLED; mark.render_priority=18; mark.modulate=Color(1,1,1,clampf(ink.a*1.15,0.3,1.0))
	# Held at a constant size on screen (the size `world_size` has at this zoom),
	# so a zoom needs no rebuild to keep the marks legible and small.
	var view_height:=maxf(camera.size if camera else 190.0,0.000001)
	mark.fixed_size=true
	mark.pixel_size=world_size/view_height*2.0*tan(deg_to_rad(camera.fov if camera else 35.0)*0.5)/float(mark.texture.get_width())
	mark.position=Vector3(position_2d.x,_close_surface_height_at(position_2d.x,position_2d.y)+lift,position_2d.y)
	return mark


func _create_player_scout_route_marker(mission:Dictionary,route:Array,band:String,rank:int=-1)->Node3D:
	var root:=Node3D.new()
	var active:=rank<0
	root.name=("ScoutOrder_%s" if active else "ScoutChart_%s") % str(mission.get("mission_id",""))
	var route_points:=PackedVector2Array()
	for point_variant in route:
		var point:Dictionary=point_variant
		route_points.append(Vector2(float(point.get("x",0.0)),float(point.get("z",0.0))))
	var visual_zoom:=camera.size if camera else (40.0 if band=="local" else (320.0 if band=="regional" else 3000.0))
	var profile:=_scout_route_visual_profile(visual_zoom)
	var route_width:=float(profile.width)
	var clearance:=float(profile.clearance)
	root.set_meta("visual_zoom",visual_zoom)
	root.set_meta("route_width",route_width)
	# Ink darkens with recency; older charts fade toward the map.
	# Iron-gall ink throughout: the party still out and the freshest charts at
	# full strength, older charts fading in opacity but never turning grey.
	var freshness:=1.0 if active else lerpf(1.0,0.42,float(rank)/float(maxi(1,SCOUT_CHART_RETURNED_LIMIT-1)))
	var ink:=Color("#2b2118"); ink.a=0.88*freshness
	var paper:=Color("#efe3c2"); paper.a=(0.22 if active else 0.16)*freshness
	# Simplify at ~3 screen pixels before fitting the curve (the view is ~900 px).
	var chart:=ScoutChartStroke.smooth(route_points,float(profile.dot),visual_zoom*0.0035)
	var heights:=PackedFloat32Array()
	var raw_heights:=PackedFloat32Array()
	for p in chart: raw_heights.append(_rendered_ground_height_at(p))
	# Drape on a smoothed ground line: raw samples jitter between terrain
	# patches and would saw the fine ink stroke in a tilted view.
	for i in raw_heights.size():
		var total:=0.0; var count:=0
		for j in range(maxi(0,i-8),mini(raw_heights.size(),i+9)): total+=raw_heights[j]; count+=1
		heights.append(total/float(count)+clearance)
	root.set_meta("chart_points",chart.size())
	var halo_ink:=ScoutChartStroke.Ink.new(visual_zoom)
	ScoutChartStroke.ribbon(halo_ink,chart,heights,float(profile.halo),paper,0.0,float(profile.tick)*2.0)
	var halo:=MeshInstance3D.new(); halo.name="ScoutCorridorBacking"; halo.mesh=halo_ink.commit(); halo.material_override=_scout_chart_material(3); root.add_child(halo)
	var line_ink:=ScoutChartStroke.Ink.new(visual_zoom)
	# The party still out is one unbroken stroke; a returned chart is a fine
	# track of round ink dots (scout_chart_ink.gdshader), set in a slightly
	# wider band so the dots keep their full round shape.
	ScoutChartStroke.ribbon(line_ink,chart,heights,route_width if active else route_width*1.25,ink,0.35 if active else 1.0,float(profile.tick)*2.2)
	var path_material:=_scout_chart_material(4)
	if not active:
		path_material.set_shader_parameter("dot_period",0.0062)
		path_material.set_shader_parameter("dot_radius",0.00125)
	var path:=MeshInstance3D.new(); path.name="ScoutCorridor"; path.mesh=line_ink.commit(); path.material_override=path_material; root.add_child(path)
	# Small, sparse open ticks show direction; only the freshest charts carry them.
	var tick_fractions:Array=[0.3,0.55,0.8] if active else ([0.45] if rank<2 else [])
	var tick_ink:=ScoutChartStroke.Ink.new(visual_zoom)
	var tick_count:=ScoutChartStroke.ticks(tick_ink,chart,heights,tick_fractions,float(profile.tick),route_width*0.8,ink)
	root.set_meta("tick_count",tick_count)
	if tick_count>0:
		var ticks:=MeshInstance3D.new(); ticks.name="ScoutDirectionTicks"; ticks.mesh=tick_ink.commit(); ticks.material_override=_scout_chart_material(5); root.add_child(ticks)
	var endpoint:=route_points[route_points.size()-1]
	var ordered:=String(mission.get("ordered_heading","")).to_upper()
	var planned:=String(mission.get("planned_heading","")).to_upper()
	var first_line:="SCOUT ORDER · %s" % ordered if ordered!="" else "SCOUTS · PARTY CHOSE %s" % planned
	var label:=Label3D.new(); label.name="ScoutOrderLabel"
	label.text="%s\nPLANNED CORRIDOR · DUE DAY %d" % [first_line,int(mission.get("return_day",0))]
	label.font_size=10; label.outline_size=5; label.billboard=BaseMaterial3D.BILLBOARD_ENABLED; label.fixed_size=true; label.no_depth_test=true; label.render_priority=10; label.modulate=Color(ink,1.0); label.outline_modulate=Color(paper,0.95)
	label.visible=false # Route details belong to hover, not permanent map clutter.
	label.position=Vector3(endpoint.x,_close_surface_height_at(endpoint.x,endpoint.y)+minf(1.2,maxf(0.001,visual_zoom*0.016)),endpoint.y); root.add_child(label)
	# Inked marks: camps along the way, a find or the turning point at the far
	# end, sightings where people were met. Each carries its own hover line.
	var marks_root:=Node3D.new(); marks_root.name="ScoutChartMarks"; root.add_child(marks_root)
	var hover_marks:Array=[]
	var mark_size:=float(profile.mark)*(1.0 if active or rank<3 else 0.8)
	var duration:=maxi(1,int(mission.get("duration_days",maxi(1,int(mission.get("return_day",0))-int(mission.get("start_day",0))))))
	var placed:Array=[]
	if active or rank<3:
		for fraction in [0.34,0.68]:
			var camp:=_scout_chart_mark("camp",ink,ScoutChartStroke.point_at(chart,fraction),clearance*1.2,mark_size)
			marks_root.add_child(camp)
			placed.append([camp,"Camp · about day %d of %d" % [maxi(1,roundi(float(duration)*0.5*fraction)),duration]])
	var discoveries:Array=mission.get("discoveries",[])
	var end_caption:="Turning point · %s" % String(mission.get("target_label","planned")).capitalize() if active else "Turned for home here"
	if not discoveries.is_empty(): end_caption="Find · %s" % String((discoveries[0] as Dictionary).get("title","Something worth reporting"))
	# A party that came home ends its chart at the hearth: its find or turning
	# point belongs where it turned, not on top of the fire (codex/beauty-4).
	var end_at:Vector2=chart[chart.size()-1]
	if end_at.distance_to(chart[0])<0.08:
		var reach:=-1.0
		for point:Vector2 in chart:
			if point.distance_to(chart[0])>reach:reach=point.distance_to(chart[0]);end_at=point
	var end_mark:=_scout_chart_mark("find" if not discoveries.is_empty() else "camp",ink,end_at,clearance*1.2,mark_size)
	marks_root.add_child(end_mark)
	placed.append([end_mark,end_caption])
	for contact_variant in mission.get("contact_records",[]):
		var contact:Dictionary=contact_variant
		var where:Dictionary=contact.get("position",{})
		var sighting:=_scout_chart_mark("sighting",ink,Vector2(float(where.get("x",0.0)),float(where.get("z",0.0))),clearance*1.2,mark_size)
		marks_root.add_child(sighting)
		placed.append([sighting,"Sighting · met the %s, day %d" % [String(contact.get("name","strangers")),int(contact.get("day",0))]])
	for entry in placed: hover_marks.append({"position":(entry[0] as Node3D).position,"caption":entry[1]})
	if active:
		var walker:=_scout_chart_mark("walker",ink,chart[0],clearance*1.4,mark_size*1.2)
		walker.name="ScoutChartWalker"
		var base_pixel_size:=walker.pixel_size
		walker.set_script(preload("res://scripts/scout_chart_walker.gd"))
		walker.set("chart",chart); walker.set("heights",heights); walker.set("arcs",ScoutChartStroke.arc_lengths(chart)); walker.set("lift",clearance*0.4)
		walker.set("start_day",float(mission.get("start_day",GameState.elapsed_days))); walker.set("return_day",float(mission.get("return_day",GameState.elapsed_days+1.0))); walker.set("base_pixel_size",base_pixel_size)
		marks_root.add_child(walker)
	var hover_layer:=CanvasLayer.new()
	hover_layer.layer=0
	root.add_child(hover_layer)
	var hover:=preload("res://scripts/hud/scout_route_overlay.gd").new()
	hover.name="ScoutRouteOverlay"
	hover.camera=camera
	var hover_stride:=maxi(1,chart.size()/48)
	for index in range(0,chart.size(),hover_stride):
		hover.points.append(Vector3(chart[index].x,heights[index],chart[index].y))
	hover.points.append(Vector3(chart[chart.size()-1].x,heights[heights.size()-1],chart[chart.size()-1].y))
	hover.marks=hover_marks
	if active:
		hover.caption="%s · planned route · due day %d · the walker marks the reckoned position" % [first_line.capitalize(),int(mission.get("return_day",0))]
	else:
		hover.caption="Returned chart · day %d · %s" % [int(mission.get("day",0)),String(mission.get("target_label","open exploration")).capitalize()]
	hover_layer.add_child(hover)
	_configure_warfare_overlay_layers(root,10)
	return root


func _create_player_field_army_path(view:Dictionary,current:Vector3,destination:Vector3,band:String)->Node3D:
	var root:=Node3D.new(); root.name="ArmyMovement_%s" % String(view.get("id",""))
	var color:=Color(String(view.get("color",WarfareMapPresentation.PLAYER_COLOR))); color.a=0.92
	# An army order is an aggregate corridor, not a one-pixel debug line. Two bounded
	# terrain-draped ribbons keep it readable over forest, water and cities at every
	# strategic scale; personnel never changes their geometry.
	var route_points:=PackedVector2Array([Vector2(current.x,current.z),Vector2(destination.x,destination.z)])
	var route_scale:=maxf(0.0005,float(view.get("scale",1.0)))
	var visual_zoom:=camera.size if camera else route_scale/0.016
	var clearance:=WarfareMapPresentation.marker_ground_clearance(visual_zoom)
	root.set_meta("route_scale",route_scale)
	var backing_surface:=SurfaceTool.new(); backing_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var backing_color:=Color("#101718"); backing_color.a=0.72
	_append_settlement_system_ribbon(backing_surface,Vector3.ZERO,route_points,route_scale*0.19,backing_color,clearance,18)
	var backing:=MeshInstance3D.new(); backing.name="MovementPathBacking"; backing.mesh=backing_surface.commit()
	var backing_material:=StandardMaterial3D.new(); backing_material.vertex_color_use_as_albedo=true; backing_material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED; backing_material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA; backing_material.no_depth_test=true; backing_material.render_priority=1; backing.material_override=backing_material; root.add_child(backing)
	var path_surface:=SurfaceTool.new(); path_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	_append_settlement_system_ribbon(path_surface,Vector3.ZERO,route_points,route_scale*0.075,color,clearance*1.1,18)
	var line:=MeshInstance3D.new(); line.name="MovementPath"; line.mesh=path_surface.commit()
	var path_material:=StandardMaterial3D.new(); path_material.vertex_color_use_as_albedo=true; path_material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED; path_material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA; path_material.no_depth_test=true; path_material.render_priority=2; line.material_override=path_material; root.add_child(line)
	# Fixed-count march chevrons make direction readable even when the thin dashed
	# path crosses mottled terrain. The count depends only on zoom band, never troops.
	var chevron_count:=5 if band=="local" else (4 if band=="regional" else 3)
	var chevron_mesh:=_warfare_arrowhead_mesh(0.78,0.13,Vector2.UP)
	var chevrons:=MultiMesh.new()
	chevrons.transform_format=MultiMesh.TRANSFORM_3D
	chevrons.instance_count=chevron_count
	chevrons.mesh=chevron_mesh
	var march_direction:=Vector2(destination.x-current.x,destination.z-current.z)
	var march_heading:=-march_direction.angle()-PI*0.5 if march_direction.length_squared()>0.000001 else 0.0
	var chevron_scale:=clampf(float(view.get("scale",1.0))*0.86,0.0005,5.4)
	for chevron_index in chevron_count:
		var travel_progress:=(float(chevron_index)+1.0)/float(chevron_count+1)
		var chevron_position:=current.lerp(destination,travel_progress)
		chevron_position.y=_close_surface_height_at(chevron_position.x,chevron_position.z)+clearance*1.2
		var chevron_basis:=Basis(Vector3.UP,march_heading).scaled(Vector3(chevron_scale,1.0,chevron_scale))
		chevrons.set_instance_transform(chevron_index,Transform3D(chevron_basis,chevron_position))
	var chevron_instance:=MultiMeshInstance3D.new()
	chevron_instance.name="MarchChevrons"
	chevron_instance.multimesh=chevrons
	chevron_instance.material_override=_warfare_marker_material(color.lightened(0.16))
	chevron_instance.material_override.render_priority=5
	root.add_child(chevron_instance)
	var objective:=Node3D.new(); objective.name="MovementObjective"
	var objective_scale:=maxf(0.001,float(view.get("scale",1.0))*0.90)
	objective.scale=Vector3.ONE*objective_scale
	objective.position=Vector3(destination.x,_close_surface_height_at(destination.x,destination.z)+clearance,destination.z)
	root.add_child(objective)
	var ring:=MeshInstance3D.new(); ring.name="ObjectiveRing"
	var ring_mesh:=TorusMesh.new(); ring_mesh.inner_radius=2.9; ring_mesh.outer_radius=3.5; ring_mesh.rings=28; ring_mesh.ring_segments=8; ring.mesh=ring_mesh; ring.material_override=_warfare_marker_material(color); objective.add_child(ring)
	var arrow:=MeshInstance3D.new(); arrow.name="ObjectiveArrow"
	var arrow_mesh:=CylinderMesh.new(); arrow_mesh.top_radius=0.12; arrow_mesh.bottom_radius=0.82; arrow_mesh.height=1.6; arrow_mesh.radial_segments=4; arrow.mesh=arrow_mesh; arrow.position.y=0.80; arrow.material_override=_warfare_marker_material(color); objective.add_child(arrow)
	arrow.material_override.render_priority=1
	var label:=Label3D.new(); label.name="ObjectiveLabel"; label.text="MARCH TO %s\n%.0f KM • DAY %d" % [String(view.get("destination_name","DESTINATION")).to_upper(),float(view.get("distance_remaining_km",0.0)),int(view.get("arrival_day",0))]; label.font_size=9; label.outline_size=4; label.billboard=BaseMaterial3D.BILLBOARD_ENABLED; label.fixed_size=true; label.no_depth_test=true; label.position=Vector3(0,6.0,-4.0); label.scale=Vector3.ONE/objective_scale; label.modulate=color.lightened(0.25); label.outline_modulate=Color(0.02,0.025,0.027,0.98); label.visible=bool(view.get("show_objective_label",false)); objective.add_child(label)
	# Routes clear terrain drapes, but remain below the counter's 17+ layer band.
	_configure_warfare_overlay_layers(root,10)
	_configure_warfare_overlay_layers(objective,14)
	return root


func _ensure_war_map_overlay()->void:
	## Wars and feuds are drawn by the war map overlay: a small mark near the
	## contested border, a short tag and plain words on hover.
	if is_instance_valid(war_map_overlay) or not is_inside_tree(): return
	# Beneath the city cards (layer 0): war ink never covers a town's name.
	var layer:=CanvasLayer.new(); layer.name="WarMapMarks"; layer.layer=-1; add_child(layer)
	# Fronts, the generals' arrows, clashes and zones are inked beneath the marks.
	var fronts:=preload("res://scripts/hud/war_front_overlay.gd").new(); fronts.name="WarFrontOverlay"; fronts.terrain=self; layer.add_child(fronts)
	war_map_overlay=preload("res://scripts/hud/war_map_overlay.gd").new(); war_map_overlay.name="WarMapOverlay"; war_map_overlay.terrain=self; layer.add_child(war_map_overlay)


func _refresh_warfare_front_markers(front_views:Array)->void:
	_ensure_war_map_overlay()
	var visible_ids:Dictionary={}
	for view_variant in front_views:
		var view:Dictionary=view_variant; var front_id:=String(view.get("id","")); visible_ids[front_id]=true
		var position_data:Dictionary=view.get("position",{}); var position:=Vector3(float(position_data.get("x",0.0)),0.0,float(position_data.get("z",0.0))); position.y=_height_at(position.x,position.z)+WarfareMapPresentation.marker_ground_clearance(camera.size if camera else 190.0)
		var marker:Node3D=warfare_front_markers.get(front_id,null)
		if marker==null or not is_instance_valid(marker):
			marker=_create_warfare_front_marker(front_id); add_child(marker); warfare_front_markers[front_id]=marker
		var marker_scale:=maxf(0.001,float(view.get("scale",1.0)))
		marker.position=position; marker.scale=Vector3.ONE*marker_scale; marker.visible=bool(view.get("visible",false)) and _world_position_is_revealed(position)
		var color:=Color(String(view.get("color",WarfareMapPresentation.FRONT_COLOR)))
		for decorative in ["FrontPlate","ContactLine","AttackerWing","DefenderWing"]:
			var part := marker.get_node_or_null(decorative)
			if part != null: part.hide()
		var front_core:=marker.get_node("FrontCore") as MeshInstance3D; _set_warfare_part_color(front_core,color)
		var front_plate:=marker.get_node("FrontPlate") as MeshInstance3D
		var front_plate_color:=Color("#202526").lerp(color.darkened(0.35),0.34); front_plate_color.a=0.92; _set_warfare_part_color(front_plate,front_plate_color)
		var contact_line:=marker.get_node_or_null("ContactLine") as MeshInstance3D
		if contact_line: _set_warfare_part_color(contact_line,color.lightened(0.25))
		var attacker_wing:=marker.get_node_or_null("AttackerWing") as MeshInstance3D
		var defender_wing:=marker.get_node_or_null("DefenderWing") as MeshInstance3D
		if attacker_wing: _set_warfare_part_color(attacker_wing,Color(String(view.get("attacker_color",WarfareMapPresentation.PLAYER_COLOR))).lightened(0.10))
		if defender_wing: _set_warfare_part_color(defender_wing,Color(String(view.get("defender_color",WarfareMapPresentation.HOSTILE_COLOR))).lightened(0.06))
		var pip:=marker.get_node("ReadinessPip") as MeshInstance3D; _set_warfare_part_color(pip,Color(String(view.get("readiness_color","#d5ad58"))))
		var progress_bar:=marker.get_node("ObjectiveProgress") as MeshInstance3D
		var progress:=clampf(float(view.get("progress",0.0)),0.0,1.0)
		progress_bar.scale=Vector3(maxf(0.04,progress),1.0,1.0)
		progress_bar.position.x=-2.45+2.45*progress
		_set_warfare_part_color(progress_bar,color.lightened(0.24))
		var selected:=String(view.get("target_region_id",""))!="" and String(view.get("target_region_id",""))==selected_civilization_region_id
		(marker.get_node("SelectedRing") as MeshInstance3D).visible=selected
		var label:=marker.get_node("FrontLabel") as Label3D; label.scale=Vector3.ONE/marker_scale; label.text=String(view.get("label","")); label.visible=bool(view.get("show_label",false)); label.modulate=color.lightened(0.24)
		# The old front token (diamond core, objective bar, readiness dot and a
		# paragraph of percentages over the target city) is not drawn: the war map
		# overlay owns how a war appears.
		marker.visible=false
	for front_id in warfare_front_markers.keys():
		if visible_ids.has(String(front_id)): continue
		var stale:Node3D=warfare_front_markers[front_id]
		if stale and is_instance_valid(stale): stale.queue_free()
		warfare_front_markers.erase(front_id)


func _create_warfare_front_marker(front_id:String)->Node3D:
	var marker:=Node3D.new(); marker.name="WarfareFront_%s" % front_id
	var plate:=MeshInstance3D.new(); plate.name="FrontPlate"
	var plate_mesh:=CylinderMesh.new(); plate_mesh.top_radius=3.28; plate_mesh.bottom_radius=3.28; plate_mesh.height=0.18; plate_mesh.radial_segments=8; plate.mesh=plate_mesh; plate.position.y=0.09
	var plate_color:=Color("#202526").lerp(Color(WarfareMapPresentation.FRONT_COLOR).darkened(0.35),0.34); plate_color.a=0.92
	var front_plate_material:=_warfare_marker_material(plate_color); front_plate_material.render_priority=-3; plate.material_override=front_plate_material; marker.add_child(plate)
	var core:=MeshInstance3D.new(); core.name="FrontCore"
	var core_mesh:=CylinderMesh.new(); core_mesh.top_radius=0.78; core_mesh.bottom_radius=0.78; core_mesh.height=0.22; core_mesh.radial_segments=4; core.mesh=core_mesh; core.position.y=0.34; core.rotation.y=PI*0.25
	var core_material:=_warfare_marker_material(Color(WarfareMapPresentation.FRONT_COLOR)); core_material.render_priority=3; core.material_override=core_material; marker.add_child(core)
	# A narrow contact line and opposing arrowheads communicate contested ground and
	# pressure direction. The old stacked hex/cone read as a giant settlement token.
	var contact_line:=MeshInstance3D.new(); contact_line.name="ContactLine"
	var contact_mesh:=BoxMesh.new(); contact_mesh.size=Vector3(0.24,0.18,4.25); contact_line.mesh=contact_mesh; contact_line.position.y=0.30
	var contact_material:=_warfare_marker_material(Color(WarfareMapPresentation.FRONT_COLOR).lightened(0.25)); contact_material.render_priority=2; contact_line.material_override=contact_material; marker.add_child(contact_line)
	for wing_record in [{"name":"AttackerWing","x":-1.58,"angle":0.0,"lighten":0.12},{"name":"DefenderWing","x":1.58,"angle":PI,"lighten":-0.12}]:
		var wing:=MeshInstance3D.new()
		wing.name=String(wing_record.name)
		var wing_mesh:=_warfare_arrowhead_mesh(1.08,0.20)
		wing.mesh=wing_mesh
		wing.position=Vector3(float(wing_record.x),0.31,0.0)
		wing.rotation.y=float(wing_record.angle)
		var wing_color:=Color(WarfareMapPresentation.FRONT_COLOR)
		wing_color=wing_color.lightened(float(wing_record.lighten)) if float(wing_record.lighten)>=0.0 else wing_color.darkened(-float(wing_record.lighten))
		var wing_material:=_warfare_marker_material(wing_color); wing_material.render_priority=1; wing.material_override=wing_material
		marker.add_child(wing)
	var progress:=MeshInstance3D.new(); progress.name="ObjectiveProgress"
	var progress_mesh:=BoxMesh.new(); progress_mesh.size=Vector3(4.9,0.18,0.56); progress.mesh=progress_mesh; progress.position=Vector3(0.0,0.27,2.65)
	var progress_material:=_warfare_marker_material(Color(WarfareMapPresentation.FRONT_COLOR).lightened(0.24)); progress_material.render_priority=4; progress.material_override=progress_material; marker.add_child(progress)
	var pip:=MeshInstance3D.new(); pip.name="ReadinessPip"
	var pip_mesh:=SphereMesh.new(); pip_mesh.radius=0.48; pip_mesh.height=0.96; pip.mesh=pip_mesh; pip.position=Vector3(3.6,0.62,0)
	var pip_material:=_warfare_marker_material(Color("#d5ad58")); pip_material.render_priority=5; pip.material_override=pip_material; marker.add_child(pip)
	var selected_ring:=MeshInstance3D.new(); selected_ring.name="SelectedRing"
	var selected_mesh:=TorusMesh.new(); selected_mesh.inner_radius=4.18; selected_mesh.outer_radius=4.54; selected_mesh.rings=28; selected_mesh.ring_segments=7; selected_ring.mesh=selected_mesh; selected_ring.material_override=_warfare_marker_material(Color(WarfareMapPresentation.PLAYER_SELECTED_COLOR)); selected_ring.visible=false; marker.add_child(selected_ring)
	var label:=Label3D.new(); label.name="FrontLabel"; label.font_size=9; label.outline_size=4; label.billboard=BaseMaterial3D.BILLBOARD_ENABLED; label.fixed_size=true; label.no_depth_test=true; label.position=Vector3(0,7.4,-4.6); label.outline_modulate=Color(0.02,0.025,0.027,0.98); marker.add_child(label)
	selected_ring.material_override.render_priority=6
	_configure_warfare_overlay_layers(marker)
	return marker

func _build_lens(layer: CanvasLayer) -> void:
	# The ground survey card lives in scripts/hud/ground_lens.gd.
	var card:=GroundLens.new()
	card.place(get_viewport().get_visible_rect().size)
	card.closed.connect(_close_lens)
	layer.add_child(card)
	lens_panel=card
	lens_body=card.body
	lens_survey=card.survey
	lens_location_label=card.location_label

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
	GameState.ensure_building_ledger()
	var consumed:Dictionary={}
	var lifecycle_events:=0
	for row_variant in GameState.building_ledger:
		var row:Dictionary=row_variant
		if int(row.get("plot_id",-2))!=int(plot.get("id",-1)): continue
		lifecycle_events+=1
		if not bool(row.get("counts_materials",false)): continue
		for material_name in (row.get("materials",{}) as Dictionary):
			consumed[String(material_name)]=float(consumed.get(String(material_name),0.0))+float((row.get("materials",{}) as Dictionary)[material_name])
	return GroundLens.plot(plot,consumed,lifecycle_events,preload("res://scripts/building_material_operations.gd").describe(plot))

func _show_city_intel_summary(city_id:String)->void:
	if hud==null or CivilizationSystem.city_intelligence.known("player",city_id).is_empty():return
	hud.close_detail()
	hud.close_dock()
	hud.open_detail(preload("res://scripts/hud/content/dock_detail_foreign_city.gd").new(self,hud,city_id))

func _city_from_screen(point:Vector2)->Dictionary:
	if camera==null:return {}
	if is_instance_valid(city_labels):
		var card:Dictionary=city_labels.city_at(point)
		if not card.is_empty():return CivilizationSystem.city_intelligence.known("player",String(card.id)) if card.foreign else {}
	# Names and locator pins are clickable even when physical buildings are
	# subpixel at regional or continental distance.
	var picked_id:=""
	var best_distance:=INF
	for id in contact_encounter_markers:
		var marker:Node3D=contact_encounter_markers[id]
		if not is_instance_valid(marker) or not marker.visible:continue
		for node_name in ["SettlementLabel","RegionalCityPin"]:
			var label:=marker.get_node_or_null(node_name) as Label3D
			if label==null or not label.visible or camera.is_position_behind(label.global_position):continue
			if label.layers==0:continue # The screen-space card owns its relocated hit target.
			var center:=camera.unproject_position(label.global_position)
			var font:Font=label.font if label.font!=null else ThemeDB.fallback_font
			var glyph_size:=font.get_string_size(label.text,HORIZONTAL_ALIGNMENT_LEFT,-1,label.font_size)
			var projection_scale:=get_viewport().get_visible_rect().size.y/(2.0*tan(deg_to_rad(camera.fov)*.5))
			var size:=Vector2(glyph_size.x,float(label.font_size)*1.5)*label.pixel_size*projection_scale
			size=size.max(Vector2(24,24))+Vector2(12,8)
			var bounds:=Rect2(center-size*.5,size)
			if label.has_meta("city_civilization_id"):
				var extra:=float(label.font_size)*2.4*label.pixel_size*projection_scale
				bounds.position.x-=extra;bounds.size.x+=extra
			if bounds.has_point(point) and point.distance_squared_to(center)<best_distance:
				picked_id=String(id);best_distance=point.distance_squared_to(center)
	if picked_id!="":return CivilizationSystem.city_intelligence.known("player",picked_id)
	var origin:=camera.project_ray_origin(point);var direction:=camera.project_ray_normal(point)
	for id in contact_encounter_markers:
		var marker:Node3D=contact_encounter_markers[id]
		if not is_instance_valid(marker) or not marker.visible:continue
		for mesh:MeshInstance3D in marker.find_children("*","MeshInstance3D",true,false):
			if mesh.name not in ["PitchedRoofs","WallsAndTimber","EarthAndLanes"]:continue
			var inverse:=mesh.global_transform.affine_inverse()
			var local_origin:Vector3=inverse*origin;var local_direction:Vector3=inverse.basis*direction
			if mesh.get_aabb().intersects_ray(local_origin,local_direction)==null:continue
			var arrays:=mesh.mesh.surface_get_arrays(0)
			var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
			var indices:PackedInt32Array=arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX]!=null else PackedInt32Array()
			var count:=indices.size() if not indices.is_empty() else vertices.size()
			for i in range(0,count-2,3):
				var a:=indices[i] if not indices.is_empty() else i;var b:=indices[i+1] if not indices.is_empty() else i+1;var c:=indices[i+2] if not indices.is_empty() else i+2
				if Geometry3D.ray_intersects_triangle(local_origin,local_direction,vertices[a],vertices[b],vertices[c])!=null:
					return CivilizationSystem.city_intelligence.known("player",String(id))
	return {}

func _contact_encounter_at(position:Vector3,radius_km:float=5.0)->Dictionary:
	var ground:=Vector2(position.x,position.z)
	var nearest:Dictionary={}; var distance:=radius_km
	for city:Dictionary in CivilizationSystem.city_intelligence.known_cities():
		var delta:=ground.distance_to(Vector2(float(city.position.x),float(city.position.z)))
		if delta<=distance:
			distance=delta; nearest=city.duplicate(true); nearest["point_kind"]="settlement"
	if not nearest.is_empty(): return nearest
	for encounter:Dictionary in CivilizationSystem.contact_encounters_snapshot():
		var point:Dictionary=encounter.get("position",{})
		if point.has_all(["x","z"]) and ground.distance_to(Vector2(float(point.x),float(point.z)))<=radius_km:
			var result:=encounter.duplicate(true); result["point_kind"]="encounter"; return result
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
	# A fine ink keyline just outside the gold ring keeps it legible on pale
	# chart paper and bright ground alike.
	var keyline:=MeshInstance3D.new()
	keyline.name="InkKeyline"
	var key_ring:=TorusMesh.new()
	key_ring.inner_radius=1.0
	key_ring.outer_radius=1.07
	key_ring.rings=40
	key_ring.ring_segments=5
	keyline.mesh=key_ring
	var key_material:=StandardMaterial3D.new()
	key_material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	key_material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	key_material.no_depth_test=true
	key_material.render_priority=11
	key_material.albedo_color=Color(TERRITORY_INK,0.80)
	keyline.material_override=key_material
	map_selection_marker.add_child(keyline)
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
	# The ring settles onto the spot, so the click reads as answered at once.
	map_selection_marker.scale=Vector3.ONE*radius*1.45
	var settle:=create_tween()
	settle.tween_property(map_selection_marker,"scale",Vector3.ONE*radius,0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	get_tree().create_timer(2.5).timeout.connect(_hide_map_selection.bind(generation))


func _hide_map_selection(generation:int)->void:
	if generation!=map_selection_generation: return
	if map_selection_marker and is_instance_valid(map_selection_marker): map_selection_marker.visible=false


func _map_inspection_summary(position:Vector3)->String:
	if not _world_position_is_revealed(position):
		return MapTickerWords.inspection("uncharted",{})
	var surface_assessment:=_settlement_surface_assessment(position)
	if not bool(surface_assessment.get("valid",false)):
		return MapTickerWords.inspection("blocked",{"reason":String(surface_assessment.get("reason",""))})
	var contact:=_contact_encounter_at(position)
	if not contact.is_empty():
		if String(contact.get("point_kind","encounter"))=="settlement":
			return MapTickerWords.inspection("foreign_settlement",{"name":String(contact.get("name","Strangers"))})
		return MapTickerWords.inspection("encounter",{"name":String(contact.get("name","strangers")),"home_known":bool(contact.get("home_location_known",false))})
	if GameState.settlement_site_committed and "Hearth Circle" in GameState.settlement_completed:
		var settlement:Dictionary=_settlement_model().settlement_at_world(Vector2(position.x,position.z))
		if not settlement.is_empty() and bool(settlement.get("inside_border",false)):
			return MapTickerWords.inspection("inside",{"name":String(settlement.get("name","our town")),"km":float(settlement.get("distance_from_center_km",0.0))})
	return MapTickerWords.inspection("open",{"ground":String(_biome_at(position.x,position.z).label),"site_committed":GameState.settlement_site_committed and "Hearth Circle" in GameState.settlement_completed})


func _open_owned_settlement_at(position:Vector3)->bool:
	if hud==null or not GameState.settlement_site_committed or not _world_position_is_revealed(position):
		return false
	var settlement:Dictionary=_settlement_model().settlement_at_world(Vector2(position.x,position.z))
	if not bool(settlement.get("inside_border",false)): return false
	var selected:Dictionary=_settlement_model().select_settlement(String(settlement.get("id","")))
	if not bool(selected.get("ok",false)): return false
	_close_lens()
	_on_hud_section_requested("settlement",0)
	if travel_status_label:
		travel_status_label.text="%s: its people, stores and works are on the left." % String(settlement.get("name","Our settlement"))
	return true

func _inspect_location(position: Vector3) -> void:
	# Select the clicked city before entering a temporary city-resource scope.
	# Ground inside an owned boundary uses the same overview as its name card.
	if _open_owned_settlement_at(position): return
	SettlementModel.with_city_resources(GameState.selected_player_settlement_id,func()->void: _inspect_location_local(position))

func _inspect_location_local(position: Vector3) -> void:
	var city_report:=_contact_encounter_at(position)
	if city_report.has("city_id"):
		_show_city_intel_summary(String(city_report.city_id)); return
	if lens_panel==null and interface_layer: _build_lens(interface_layer)
	_show_map_selection(position)
	if travel_status_label: travel_status_label.text=_map_inspection_summary(position)
	if lens_panel == null or lens_body == null:
		return
	lens_requested_visible=true
	lens_world_position = position
	var card:=lens_panel as GroundLens
	var revealed:=_world_position_is_revealed(position)
	var settlement_context:Dictionary={}
	if GameState.settlement_site_committed and "Hearth Circle" in GameState.settlement_completed:
		settlement_context=_settlement_model().settlement_at_world(Vector2(position.x,position.z))
	var contact_context:=_contact_encounter_at(position) if revealed else {}
	var inside:=not settlement_context.is_empty() and bool(settlement_context.get("inside_border",false))
	# Where this is, in one short phrase.
	var where:={}
	if not revealed:where={"kind":"uncharted"}
	elif not contact_context.is_empty():where={"kind":"foreign_settlement" if String(contact_context.get("point_kind","encounter"))=="settlement" else "encounter","name":String(contact_context.get("name","strangers"))}
	elif inside:where={"kind":"inside","name":String(settlement_context.get("name","our town")),"km":float(settlement_context.get("distance_from_center_km",0.0))}
	elif not settlement_context.is_empty():where={"kind":"beyond_border","name":String(settlement_context.get("name","our town")),"km":float(settlement_context.get("distance_from_border_km",0.0))}
	elif bool(GameState.settlement_convoy.get("active",false)):
		var convoy_position:Vector2=GameState.settlement_convoy.get("position",Vector2.ZERO)
		var convoy_distance:=convoy_position.distance_to(Vector2(position.x,position.z))*KM_PER_WORLD_UNIT
		where={"kind":"convoy"} if convoy_distance<0.15 else {"kind":"from_convoy","km":convoy_distance}
	elif settler_marker:
		var founding_distance:=Vector2(settler_marker.position.x,settler_marker.position.z).distance_to(Vector2(position.x,position.z))*KM_PER_WORLD_UNIT
		if GameState.founding_expedition_active():where={"kind":"convoy"} if founding_distance<0.15 else {"kind":"from_convoy","km":founding_distance}
		else:where={"kind":"site"} if founding_distance<0.15 else {"kind":"from_site","km":founding_distance}
	var where_text:=GroundLens.where_words(where)
	var entries: Array[Dictionary] = []
	if revealed:
		entries = ResourceSystem.lens_entries(position, 18.0, KM_PER_WORLD_UNIT)
	var settlement_plot:=_settlement_plot_at(position) if revealed else {}
	if not revealed:
		card.show_account("Unknown ground",where_text,GroundLens.uncharted(GameState.settlement_site_committed))
		return
	if not contact_context.is_empty():
		if String(contact_context.get("point_kind","encounter"))=="settlement":
			card.show_account("A foreign settlement",where_text,GroundLens.foreign_settlement(String(contact_context.get("name","A foreign people")),String(contact_context.get("home_location_source","")),maxi(0,int(contact_context.get("last_observed_day",0)))))
		else:
			card.show_account("Where we met strangers",where_text,GroundLens.encounter(String(contact_context.get("name","A foreign people")),maxi(0,int(contact_context.get("day",0))),String(contact_context.get("source_description",""))))
		return
	if not settlement_plot.is_empty():
		var report:=_settlement_plot_lens_report(settlement_plot)
		if not entries.is_empty():report+="\n\n[b]Known nearby[/b]\n\n"+GroundLens.resources(entries)
		card.show_account("In the town",where_text,HudT.readable_report(report))
		return
	if inside and entries.is_empty():
		card.show_account("Our own ground",where_text,_surface_resource_report(position)+GroundLens.inside_border(String(settlement_context.get("name","the settlement")),float(settlement_context.get("controlled_area_km2",0.0)),_compact_population(int(settlement_context.get("population",0)))))
		return
	var survey_advice:Dictionary={}
	if not inside:survey_advice=_founding_site_advice(position)
	# Written account kept in step with the card for probes and old readers.
	lens_body.text=_surface_resource_report(position)+(GroundLens.water_advice(survey_advice) if not survey_advice.is_empty() else "")+(GroundLens.resources(entries) if not entries.is_empty() else GroundLens.unsurveyed())
	var biome:=_biome_at(position.x,position.z)
	var surface:={"id":biome.id,"label":biome.label,"tree_cover":_woodland_density_at(position.x,position.z),"stone":"abundant" if float(biome.stone)>0.5 else "scattered" if float(biome.stone)>0.12 else "limited","soil":"high" if float(biome.fertility)>0.65 else "moderate" if float(biome.fertility)>0.3 else "low","fiber":"plentiful" if _surface_material_density(biome,"Fiber Plants")>0.4 else "scattered" if _surface_material_density(biome,"Fiber Plants")>=0.08 else "limited"}
	card.show_ground("Ground survey",where_text,entries,surface,survey_advice)


# Only one primary destination may own the interaction layer. Detail screens
# stay inside their destination; switching destinations retires the old tree
# before the new one is shown, so notifications and dashboards cannot stack.
func _close_primary_destinations_except(destination:String)->void:
	if destination!="military" and MilitaryCommandUI and MilitaryCommandUI.modal and MilitaryCommandUI.modal.visible:
		MilitaryCommandUI.modal.hide()


func _change_research_domain_allocation(dynamic_id:String,change:int)->void:
	PeopleDirection.auto_research=false
	var current:=maxi(0,int(GameState.research_allocations.get(dynamic_id,0)))
	DiscoverySystem.set_domain_research_priority(dynamic_id,current+change)
	_refresh_research_allocations()
	if hud: hud.request_immediate_dock_refresh()


func _refresh_research_allocations() -> void:
	## Broad research emphasis is the sum of its automatic lines.
	for dynamic_id in GameState.research_subcategory_allocations:
		var dynamic_total:=0
		var subcategories:Dictionary=GameState.research_subcategory_allocations[dynamic_id]
		for subcategory in subcategories:dynamic_total+=int(subcategories[subcategory])
		GameState.research_allocations[dynamic_id]=dynamic_total

func _civic_settlement()->Dictionary:
	var settlement:Dictionary=_settlement_model().selected_settlement_snapshot()
	if not settlement.is_empty(): return settlement
	for settlement_variant in GameState.player_settlements:
		var candidate:Dictionary=settlement_variant
		if bool(candidate.get("primary",false)): return candidate
	return GameState.player_settlements[0] if not GameState.player_settlements.is_empty() else {}


func _perform_civic_leader_removal(settlement_id:String,action:String,player_text:String="")->Dictionary:
	var former:=GovernmentPeopleSystem.settlement_leader(settlement_id)
	if player_text.strip_edges().is_empty():
		player_text="Arrest %s." % String(former.get("name","the settlement leader")) if action=="arrest" else "Dismiss %s." % String(former.get("name","the settlement leader"))
	var result:=GovernmentPeopleSystem.remove_settlement_leader(settlement_id,action)
	AdvisorSystem.record_civic_leadership_change(settlement_id,player_text,result)
	var message:=String(result.get("message",result.get("reason","Leadership did not change.")))
	if travel_status_label: travel_status_label.text=PaperKit.sentence(message)
	if hud:
		hud._queue_signature="__stale__"
		hud.refresh()
		hud.request_immediate_dock_refresh()
	return result


## Issues a civic directive from text (e.g. a petitioner's suggested decree
## accepted in the Audience Hall) through the ordinary freeform pipeline.
func issue_civic_directive_text(text:String)->void:
	var input:=LineEdit.new();input.text=text
	_issue_freeform_order(input)
	input.free()

func _issue_freeform_order(input: LineEdit) -> void:
	if not input.editable: return
	var text := input.text.strip_edges()
	if text.is_empty():
		return
	GovernmentPeopleSystem.initialize()
	var settlement:Dictionary=_civic_settlement()
	var settlement_id:=String(settlement.get("id",""))
	var leader:=GovernmentPeopleSystem.settlement_leader(settlement_id)
	if settlement.is_empty() or leader.is_empty():
		return
	var leadership_action:=AdvisorSystem.civic_leadership_action(text,String(leader.get("name","")))
	if not leadership_action.is_empty():
		input.text=""
		_perform_civic_leader_removal(settlement_id,leadership_action,text)
		return
	var conversation_action:=AdvisorSystem.civic_conversation_action(text,settlement_id,int(leader.get("person_id",0)))
	text=AdvisorSystem.civic_retry_text(text,settlement_id)
	if conversation_action=="withdraw":
		input.text=""
		var withdrawn:=AdvisorSystem.withdraw_pending_civic_directive(settlement_id,int(leader.get("person_id",0)),text)
		var withdrawal_message:=String(withdrawn.get("message",withdrawn.get("reason","There is no unresolved directive to withdraw.")))
		if travel_status_label: travel_status_label.text=PaperKit.sentence(withdrawal_message.split("\n")[0])
		if hud:
			hud._queue_signature="__stale__"
			hud.refresh()
			hud.request_immediate_dock_refresh()
		return
	input.editable=false
	var active_context:Array[Dictionary]=[]
	for policy in ConsequenceEngine.active_policies(): active_context.append({"id":String(policy.get("id","")),"remaining_days":ceili(float(policy.get("remaining_days",0.0)))})
	var context:={
		"day":int(GameState.elapsed_days),"population":GameState.population_total,
		"food_days":float(GameState.simulation_metrics.get("food_days",0.0)),"health":GameState.population_health,
		"water_days":float(GameState.water_metrics.get("days",0.0)),"water_intake":float(GameState.water_metrics.get("intake_ratio",0.0)),
		"housing":float(GameState.simulation_metrics.get("housing_ratio",1.0)),"labor_efficiency":float(GameState.simulation_metrics.get("labor_efficiency",0.0)),
		"security":float(GameState.simulation_metrics.get("security",0.0)),"cohesion":float(GameState.simulation_metrics.get("cohesion",0.0)),
		"institutions":float(GameState.society_capacities.get("institutions",0.0)),
		"known_offices":GameState.leadership_positions.keys(),"active_policies":active_context,
		"settlement":{"id":settlement_id,"name":String(settlement.get("name","the settlement")),"population":int(settlement.get("population",GameState.population_total)),"classification":String(settlement.get("classification","settlement"))},
		"leader":{"name":String(leader.get("name","the appointed leader")),"title":String(leader.get("title","local leader")),"background":String(leader.get("background","")),"traits":(leader.get("traits",[]) as Array).duplicate()},
		"conversation":AdvisorSystem.civic_dialogue_history(settlement_id,24),
		"decisions":AdvisorSystem.civic_decision_context(settlement_id),
	}
	var local_snapshot:=SettlementModel.city_resource_snapshot(settlement_id)
	if not local_snapshot.is_empty():
		var local_metrics:Dictionary=local_snapshot.metrics
		var local_water:Dictionary=local_snapshot.water
		context.population=int(local_snapshot.population)
		context.food_days=float(local_metrics.get("food_days",0.0))
		context.water_days=float(local_water.get("days",0.0))
		context.water_intake=float(local_water.get("intake_ratio",0.0))
		context.housing=float(local_metrics.get("housing_ratio",1.0))
		context.labor_efficiency=float(local_metrics.get("labor_efficiency",0.72))
	if not PronouncementInterpreter.interpretation_completed.is_connected(_on_pronouncement_interpreted): PronouncementInterpreter.interpretation_completed.connect(_on_pronouncement_interpreted)
	if not PronouncementInterpreter.interpretation_progress.is_connected(_on_pronouncement_progress): PronouncementInterpreter.interpretation_progress.connect(_on_pronouncement_progress)
	var pending_order:=AdvisorSystem.begin_civic_directive(text,settlement_id,leader)
	var request_id:=PronouncementInterpreter.interpret(text,context)
	pending_order["request_id"]=request_id
	# The dock is rebuilt immediately below, which destroys its LineEdit. Pending
	# network state must therefore contain data only, never a transient UI node.
	pending_pronouncement_inputs[request_id]=_pending_civic_request_record(text,pending_order,settlement_id,int(leader.get("person_id",0)))
	if travel_status_label: travel_status_label.text="%s is thinking over what you said." % String(leader.get("name","The leader"))
	var initial_progress:=PronouncementInterpreter.request_progress(request_id)
	if not initial_progress.is_empty(): _on_pronouncement_progress(request_id,initial_progress)
	_refresh_council_dock()

func _pending_civic_request_record(text:String,order:Dictionary,settlement_id:String,leader_person_id:int)->Dictionary:
	return {
		"text":text,
		"submitted_day":int(GameState.elapsed_days),
		"order":order,
		"settlement_id":settlement_id,
		"leader_person_id":leader_person_id,
	}

func _on_pronouncement_progress(_request_id:String,_status:Dictionary)->void:
	## Progress of a spoken directive is shown in the court conversation.
	pass

func _on_pronouncement_interpreted(request_id:String,result:Dictionary)->void:
	var pending:Dictionary=pending_pronouncement_inputs.get(request_id,{})
	pending_pronouncement_inputs.erase(request_id)
	var text:=String(pending.get("text","Sovereign pronouncement"))
	var order:=AdvisorSystem.resolve_civic_directive(text,result,pending.get("order",{}),String(pending.get("settlement_id","")),int(pending.get("leader_person_id",0)))
	order["submitted_day"]=int(pending.get("submitted_day",order.get("issued_day",GameState.elapsed_days)))
	var interpretation:Dictionary=order.get("parameters",{}).get("interpretation",{})
	var policies:Array=interpretation.get("policies",[])
	var ripples:Array[String]=[]
	for policy_variant in policies:
		var policy:Dictionary=policy_variant
		ripples.append(String(policy.ripple))
	var message:=String(order.get("leader_reply",""))
	if message.is_empty(): message="  ".join(ripples)
	if message.is_empty(): message=String(result.get("unresolved","The pronouncement was recorded without an executable simulation effect."))
	if travel_status_label: travel_status_label.text=PaperKit.sentence(message)
	_refresh_council_dock.call_deferred()

func _cancel_pending_pronouncement(order_id:String,request_id:String)->void:
	if not PronouncementInterpreter.cancel(request_id):
		_refresh_council_dock.call_deferred()
		return
	var pending:Dictionary=pending_pronouncement_inputs.get(request_id,{})
	pending_pronouncement_inputs.erase(request_id)
	for order_variant in GameState.sovereign_orders:
		var order:Dictionary=order_variant
		if String(order.get("id",""))!=order_id: continue
		order["status"]="cancelled"
		order["cancelled_day"]=int(GameState.elapsed_days)
		order["parameters"]={"text":String(order.get("parameters",{}).get("text","Sovereign pronouncement")),"interpretation":{"source":"cancelled","source_detail":"Cancelled by Sovereign","summary":"The pronouncement was withdrawn before interpretation.","policies":[],"unresolved":"No standing policy was applied."}}
		break
	_refresh_council_dock.call_deferred()

func _refresh_council_dock()->void:
	## Rebuilds the council view after a pronouncement state change when the
	## dock is showing it.
	if hud and hud.active_section=="civ":
		# An explicit conversational turn must redraw even while the pointer or
		# keyboard focus remains inside the dock. Passive simulation refreshes keep
		# their interaction guard; this action path deliberately bypasses it.
		hud.request_immediate_dock_refresh()


func _generate_leader_candidates(office:String) -> void:
	leader_candidates.clear()
	GovernmentPeopleSystem.initialize()
	for person in GovernmentPeopleSystem.candidates_for_office(office,"",6,false):
		leader_candidates.append(person)
	AdvisorSystem.register_advisors(leader_candidates)


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


func _open_scout_dispatch_panel()->void:
	if is_instance_valid(scout_dispatch_panel):scout_dispatch_panel.queue_free()
	scout_dispatch_previous_speed=game_speed;_set_game_speed(0.0)
	scout_dispatch_panel=preload("res://scripts/hud/scouting_policy_panel.gd").new()
	scout_dispatch_panel.name="ScoutingPolicy";scout_dispatch_panel.z_index=70
	scout_dispatch_panel.close_requested.connect(_close_scout_dispatch_panel)
	interface_layer.add_child(scout_dispatch_panel)


func _close_scout_dispatch_panel()->void:
	if scout_dispatch_panel and is_instance_valid(scout_dispatch_panel): scout_dispatch_panel.queue_free()
	scout_dispatch_panel=null
	scout_dispatch_status=null
	_set_game_speed(scout_dispatch_previous_speed)


func _open_diplomat_dispatch_panel(civ_id:String="",purpose:String="")->Control:
	## Word to another people is sent from the court, in the conversation with
	## their ruler (one-court-screen). Every envoy button lands here.
	var target:=civ_id
	if target=="":
		for civ:Dictionary in CivilizationSystem.civilizations:
			if not ForeignDiplomacy.leader(String(civ.get("id",""))).is_empty():
				if target=="":target=String(civ.id)
				if bool((civ.get("player_relation",{}) as Dictionary).get("home_location_known",false)):target=String(civ.id);break
	var focus:={}
	if target!="":
		focus["civ_id"]=target
		if purpose!="":focus["purpose"]=purpose
	var director:Node=get_tree().get_first_node_in_group("court_director")
	if director==null or not director.has_method("open_court"):return null
	return director.call("open_court",focus)


func _focus_known_world_point(civ_id:String,point_kind:String)->void:
	for encounter_variant in CivilizationSystem.contact_encounters_snapshot():
		var encounter:Dictionary=encounter_variant
		if String(encounter.get("civ_id",""))!=civ_id: continue
		var use_settlement:=point_kind=="settlement" and bool(encounter.get("home_location_known",false))
		var position_data:Dictionary=encounter.get("home_position",{}) if use_settlement else encounter.get("position",{})
		if not position_data.has("x") or not position_data.has("z"): return
		var target:=Vector3(float(position_data.x),0.0,float(position_data.z))
		zoom_target_size=-1.0
		if camera:
			var report:=CivilizationSystem.city_intelligence.known("player",CivilizationSystem.city_intelligence.primary_id(civ_id))
			camera.size=preload("res://scripts/foreign_settlement_visual.gd").framing_size(report) if use_settlement else minf(camera.size,58.0)
		_set_camera_target(target)
		if travel_status_label:
			var notice:="Where %s live." % String(encounter.get("name","the strangers")) if use_settlement else "Where we met %s. Where they live is still unknown." % String(encounter.get("name","the strangers"))
			travel_status_label.text=notice
			get_tree().create_timer(8.0).timeout.connect(_clear_transient_world_notice.bind(notice))
		return


func _clear_transient_world_notice(expected_text:String)->void:
	if travel_status_label and travel_status_label.text==expected_text: travel_status_label.text=""


func _update_time_interface() -> void:
	# The clock reads every frame. Everything else reads simulation state that
	# only changes when a day completes, so between days it refreshes at 10 Hz.
	var now_msec:=Time.get_ticks_msec()
	var sim_day:=last_discovery_day
	var full:=not time_interface_between_days or sim_day!=time_interface_day or now_msec-time_interface_msec>=100
	if full:
		time_interface_day=sim_day;time_interface_msec=now_msec
		if hud:
			hud.refresh()
			CaravanPanel.sync(self,hud)
	if interface_layer == null:
		return
	if not full:
		return
	if convoy_map_label:
		var title:="Founding convoy" if not GameState.settlement_site_committed else (GameState.settlement_name.strip_edges() if not GameState.settlement_name.strip_edges().is_empty() else "Founding site")
		convoy_map_label.text=_city_map_label(title,GameState.population_total)
		convoy_map_label.set_meta("map_status",_convoy_water_readout() if not GameState.settlement_site_committed else "Establishing home · View progress")
		_update_city_flag(convoy_map_label)
	if travel_status_label:
		# One calm sentence for the journey and the founding (map_ticker_words.gd).
		var journey_line:=MapTickerWords.journey(travel_active,maxf(0.0,travel_days_total-travel_days_elapsed),GameState.settlement_convoy,GameState.convoy_emergency_halt_reason,GameState.settlement_site_committed,bool(GameState.founding_journey.get("camped_foraging",false)),"Hearth Circle" in GameState.settlement_completed,settlement_convoy_targeting,placement_building!="",GameState.settlement_founded_day if GameState.settlement_site_committed else -1,GameState.elapsed_days)
		if journey_line!="" or placement_building=="":travel_status_label.text=journey_line
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
	if speed>0 and preload("res://scripts/hud/simulation_pause.gd").blocks(self):return
	if GeneralCampaign.active and speed<=0:GeneralCampaign.pause_to_speak()
	if speed<=0.0:calendar_bank_days=0.0
	if GeneralCampaign.active and speed>0:
		GeneralCampaign.resume()
		return
	if speed>0.0 and GameState.founding_focus=="":
		game_speed=0.0
		if not founding_focus_panel or not is_instance_valid(founding_focus_panel): _open_founding_focus_panel()
		_update_time_interface()
		return
	game_speed=clampf(speed,0.0,5.0)
	simulation_clock.reset(Time.get_ticks_usec())
	_update_time_interface()

func _speed_hours_per_second() -> float:
	return float(SPEED_HOURS_PER_REAL_SECOND.get(int(game_speed),0.0))


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


func _open_founding_focus_panel()->void:
	if GameState.founding_focus!="" or is_instance_valid(founding_focus_panel): return
	game_speed=0.0
	if map_help_panel: map_help_panel.visible=false
	if map_help_button: map_help_button.visible=false
	if not is_instance_valid(PeopleDirection.panel): PeopleDirection.open_direction()
	founding_focus_panel=PeopleDirection.panel
	founding_focus_panel.tree_exited.connect(func():
		founding_focus_panel=null
		if GameState.founding_focus!="":
			if convoy_banner_sprite: convoy_banner_sprite.texture=_founding_banner_texture(GameState.founding_banner_index)
			_set_game_speed(DEFAULT_PLAY_SPEED)
			_sync_map_help_overlay_visibility())


func _open_world_menu()->void:
	if world_menu_panel and is_instance_valid(world_menu_panel): return
	world_menu_previous_speed=game_speed
	_set_game_speed(0.0)
	# The menu's words and layout live in scripts/hud/game_menu.gd.
	world_menu_panel=preload("res://scripts/hud/game_menu.gd").open(self,interface_layer)
	if not get_viewport().size_changed.is_connected(_fit_world_menu): get_viewport().size_changed.connect(_fit_world_menu)
	_fit_world_menu.call_deferred()

func _fit_world_menu()->void:
	if not is_instance_valid(world_menu_panel):return
	var modal:=world_menu_panel.get_node("PauseMenuBody") as Control
	var view:=get_viewport().get_visible_rect().size
	modal.size=Vector2(minf(680,view.x-32),minf(820,view.y-32))
	modal.position=(view-modal.size)*0.5

func _request_quit()->void:
	_open_world_menu()
	if is_instance_valid(quit_dialog):
		quit_dialog.dialog_text="Save your current progress before quitting?"
		quit_dialog.popup_centered()
		return
	quit_dialog=ConfirmationDialog.new()
	quit_dialog.theme=HudT.control_theme()
	quit_dialog.title="Quit Tomorrow and Tomorrow?"
	quit_dialog.dialog_text="Save your current progress before quitting?"
	quit_dialog.ok_button_text="Save and quit"
	quit_dialog.cancel_button_text="Keep playing"
	quit_dialog.add_button("Quit without saving",false,"discard")
	quit_dialog.confirmed.connect(_save_and_quit)
	quit_dialog.custom_action.connect(func(action:String):
		if action=="discard":_finish_quit())
	quit_dialog.canceled.connect(_close_world_menu)
	quit_dialog.unresizable=true
	add_child(quit_dialog)
	quit_dialog.popup_centered(Vector2i(520,180))

func _save_and_quit()->void:
	var result:Dictionary=_save_before_quit()
	if result.has("error"):
		quit_dialog.dialog_text="The game could not be saved, so it is still open.\n"+String(result.error)
		quit_dialog.popup_centered()
		return
	_finish_quit()

func _save_before_quit()->Dictionary:
	return SaveSystem.save_game()

func _finish_quit()->void:
	get_tree().quit()

func _close_world_menu()->void:
	if world_menu_panel and is_instance_valid(world_menu_panel): world_menu_panel.queue_free()
	world_menu_panel=null
	world_seed_input=null
	world_seed_status=null
	_set_game_speed(world_menu_previous_speed)


func _restart_with_entered_seed()->void:
	if not world_seed_input or not world_seed_input.text.strip_edges().is_valid_int():
		if world_seed_status:
			world_seed_status.text="Type a whole number, such as 184271."
			world_seed_status.add_theme_color_override("font_color",HudT.RED_TEXT)
		return
	var selected:=int(world_seed_input.text.strip_edges())
	selected=clampi(selected,-2147483647,2147483647)
	if selected==0: selected=1
	_restart_world(selected)

func _load_saved_world()->String:
	## Restores the quicksave into the autoload layer, then rebuilds the
	## rendered world from it — the same scene-reload path a restart uses.
	## Returns the player-facing problem, or "" when the world reloads.
	var result:Dictionary=SaveSystem.load_game()
	if result.has("error"):
		return String(result.error)
	pending_pronouncement_inputs.clear()
	get_tree().reload_current_scene()
	return ""

func _restart_world(selected_seed:int)->void:
	GameState.reset_for_new_world(selected_seed)
	DiscoverySystem.reset_for_new_world()
	ProgressionSystem.reset_for_new_world()
	PlanetEnvironment.reset_for_new_world()
	ResourceSystem.reset_for_new_world()
	EconomySystem.reset_for_new_world()
	_settlement_model().reset_for_new_world()
	GovernmentPeopleSystem.reset_for_new_world()
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
	if is_instance_valid(GeneralCampaign.screen) and GeneralCampaign.screen.visible:GeneralCampaign.screen.hide();return true
	if MilitaryCommandUI and MilitaryCommandUI.modal and MilitaryCommandUI.modal.visible:
		MilitaryCommandUI.modal.hide()
		return true
	return false


func _input(event: InputEvent) -> void:
	if _dismiss_report_backdrop(event):
		get_viewport().set_input_as_handled();return
	if is_instance_valid(MilitaryCampaign.joint_operations.screen):
		if MilitaryCampaign.joint_operations.screen.handle_early_input(event):
			get_viewport().set_input_as_handled();return
		# Let text controls receive typing without activating map/speed shortcuts.
		if event is InputEventKey and get_viewport().gui_get_focus_owner() is LineEdit:return
	if event is InputEventKey and event.pressed and not event.echo and event.meta_pressed and event.keycode==KEY_Q:
		_request_quit()
		get_viewport().set_input_as_handled()
		return
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
			if is_instance_valid(founding_site_guide) and not settlement_convoy_targeting:
				_close_founding_site_guide()
				get_viewport().set_input_as_handled();return
			if selected_army_id!=-1:
				_clear_army_selection()
				get_viewport().set_input_as_handled()
				return
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
			if world_menu_panel and is_instance_valid(world_menu_panel):
				_close_world_menu()
				get_viewport().set_input_as_handled()
				return
			_open_world_menu()
			get_viewport().set_input_as_handled()
			return
		if world_menu_panel and is_instance_valid(world_menu_panel): return
		# A toolbar button may retain focus after a click. Reserve Up/Down on
		# bare map before GUI focus navigation; controls under the pointer keep it.
		if event.keycode in [KEY_UP,KEY_DOWN] and _handle_camera_zoom_key(event):
			get_viewport().set_input_as_handled();return
		if event.keycode >= KEY_0 and event.keycode <= KEY_5:
			_set_game_speed(float(event.keycode - KEY_0))
	elif event is InputEventPanGesture:
		if not _pointer_over_ui():
			_pan_camera_gesture(event.delta)
			get_viewport().set_input_as_handled()
	elif event is InputEventMagnifyGesture:
		# A small finger spread during a pan must not change altitude.
		if not _pointer_over_ui():
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			var was_dragging:=dragging
			dragging = event.pressed and not _pointer_over_ui()
			rotating_camera = event.shift_pressed
			if dragging:
				pan_coast_velocity=Vector3.ZERO;drag_velocity=Vector3.ZERO
			elif was_dragging and not rotating_camera and Time.get_ticks_usec()-drag_motion_usec<70000:
				# A released grab coasts briefly, as a map slid across a table.
				pan_coast_velocity=preload("res://scripts/map_motion.gd").release_velocity(drag_velocity,camera.size)
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed and not _pointer_over_ui():
			_queue_camera_zoom(event.position,-maxf(0.05,event.factor)) if event.shift_pressed else _step_camera_distance(event.position,-1.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed and not _pointer_over_ui():
			_queue_camera_zoom(event.position,maxf(0.05,event.factor)) if event.shift_pressed else _step_camera_distance(event.position,1.0)
	elif event is InputEventMouseMotion and dragging:
		if rotating_camera:
			north_reset_active=false
			camera_input_msec=Time.get_ticks_msec()
			camera_yaw -= event.relative.x * 0.006
			camera_pitch = clampf(camera_pitch - event.relative.y * 0.004, -1.50, -0.40)
			_update_camera()
		else:
			var units_per_pixel:=camera.size/maxf(1.0,float(get_viewport().get_visible_rect().size.y))
			var screen_right:=_camera_ground_screen_right()
			var screen_up:=_camera_ground_screen_up()
			var movement:=_camera_grab_movement(event.relative,screen_right,screen_up,units_per_pixel)
			var now_usec:=Time.get_ticks_usec()
			var step_seconds:=clampf(float(now_usec-drag_motion_usec)/1000000.0,1.0/240.0,0.1)
			drag_velocity=drag_velocity.lerp(movement/step_seconds,0.5) if now_usec-drag_motion_usec<100000 else movement/step_seconds
			drag_motion_usec=now_usec
			_set_camera_target(camera_target+movement)

func _dismiss_map_panels()->bool:
	# Called after GUI handling: controls keep their clicks; bare map dismisses.
	var dismissed:=false
	if is_instance_valid(founding_site_guide) and not settlement_convoy_targeting:
		_close_founding_site_guide();dismissed=true
	if map_help_panel and map_help_panel.visible:
		_dismiss_map_help();dismissed=true
	if hud and ((hud.dock and hud.dock.visible) or (hud.detail_dock and hud.detail_dock.visible)):
		hud.close_dock();dismissed=true
	return dismissed

func _outside_report_body(panel:Control,point:Vector2)->bool:
	if not is_instance_valid(panel) or not panel.is_visible_in_tree():return false
	# Full-screen dimmers are not content. A click beside the actual report
	# should dismiss it even when that dimmer stops ordinary GUI propagation.
	for child:Node in panel.get_children():
		if child is PanelContainer and child.is_visible_in_tree():
			return not child.get_global_rect().has_point(point)
	return false

func _dismiss_report_backdrop(event:InputEvent)->bool:
	if not (event is InputEventMouseButton) or not event.pressed or event.button_index!=MOUSE_BUTTON_LEFT:return false
	# Decision dialogs keep their explicit confirm/cancel controls.
	if is_instance_valid(founding_focus_panel) or is_instance_valid(settlement_convoy_confirm_panel):return false
	if _outside_report_body(world_menu_panel,event.position):_close_world_menu();return true
	if _outside_report_body(scout_dispatch_panel,event.position):_close_scout_dispatch_panel();return true
	return false

func _pointer_over_ui()->bool:
	# Scrolling a dock must not also move the map beneath it. A hovered control
	# counts as UI only when it or an ancestor actually stops mouse events;
	# full-rect pass-through shells over bare terrain do not.
	var hovered:=get_viewport().gui_get_hovered_control()
	var node:Node=hovered
	while node is Control:
		if (node as Control).mouse_filter==Control.MOUSE_FILTER_STOP: return true
		node=node.get_parent()
	return false


func _handle_camera_zoom_key(event:InputEventKey)->bool:
	if not event.pressed or event.alt_pressed or event.ctrl_pressed or event.meta_pressed:return false
	if is_instance_valid(world_menu_panel):return false
	var focused:=get_viewport().gui_get_focus_owner()
	if focused is LineEdit or focused is TextEdit:return false
	var arrow:=event.keycode in [KEY_UP,KEY_DOWN]
	if arrow and _pointer_over_ui():return false
	var zoom_step:=0.0
	if event.keycode in [KEY_UP,KEY_PLUS,KEY_EQUAL,KEY_KP_ADD]:zoom_step=-1.0
	elif event.keycode in [KEY_DOWN,KEY_MINUS,KEY_KP_SUBTRACT]:zoom_step=1.0
	if zoom_step==0.0:return false
	# One intentional arrow press selects one distance; OS repeat cannot race
	# across the levels. Shift does not change the arrow-key distance contract.
	if arrow and event.echo:return true
	var center:=get_viewport().get_visible_rect().size*0.5
	if event.shift_pressed and not arrow:_queue_camera_zoom(center,zoom_step)
	else:_step_camera_distance(center,zoom_step)
	return true


func _unhandled_input(event: InputEvent) -> void:
	if is_instance_valid(MilitaryCampaign.joint_operations.screen):
		if MilitaryCampaign.joint_operations.screen.handle_map_input(event):
			get_viewport().set_input_as_handled();return
		if event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_LEFT,MOUSE_BUTTON_RIGHT]:
			if event.button_index==MOUSE_BUTTON_LEFT:
				MilitaryCampaign.joint_operations.screen.queue_free();_dismiss_map_panels()
			get_viewport().set_input_as_handled();return
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT and _dismiss_map_panels():
		get_viewport().set_input_as_handled();return
	if event is InputEventKey and _handle_camera_zoom_key(event):
		get_viewport().set_input_as_handled();return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_N:
		_reset_camera_north()
		get_viewport().set_input_as_handled()
		return
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
		if is_instance_valid(city_labels):
			var card:Dictionary=city_labels.city_at(event.position)
			if not card.is_empty():
				if String(card.get("kind",""))=="founding_convoy":_on_settlement_action_pressed()
				elif card.foreign:_show_city_intel_summary(String(card.id))
				else:_focus_settlement_from_screen(event.position,event.double_click,String(card.id))
				get_viewport().set_input_as_handled();return
		if String(_war_mark_at(event.position).get("kind",""))=="army":
			_select_field_army_from_screen(event.position);get_viewport().set_input_as_handled();return
		for marker:Node3D in ({} if _war_chart_draws_marks() else player_field_army_markers).values():
			if is_instance_valid(marker) and marker.visible and event.position.distance_to(camera.unproject_position(marker.global_position))<=10.0:
				_select_field_army_from_screen(event.position);get_viewport().set_input_as_handled();return
		# Pick the actual rendered city geometry, independent of scout counter hit radii.
		var clicked_city:=_city_from_screen(event.position)
		if not clicked_city.is_empty():
			_show_city_intel_summary(String(clicked_city.city_id));get_viewport().set_input_as_handled();return
		# Target counters win hit-testing when formations overlap. Otherwise the
		# player can see a scout or enemy but can only select their own army under
		# it — precisely the opposite of the action they are trying to take.
		if _open_foreign_formation_from_screen(event.position):
			get_viewport().set_input_as_handled()
			return
		# HoI4-style army control: left-click selects an army marker (or clears
		# the selection when clicking empty ground).
		if _select_field_army_from_screen(event.position):
			get_viewport().set_input_as_handled()
			return
		if not settlement_convoy_targeting and _focus_settlement_from_screen(event.position, event.double_click):
			get_viewport().set_input_as_handled()
			return
		if _handle_map_ground_button(MOUSE_BUTTON_LEFT,event.position):get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if _handle_map_ground_button(MOUSE_BUTTON_RIGHT,event.position):get_viewport().set_input_as_handled()


func _handle_map_ground_button(button_index:int,screen_position:Vector2)->bool:
	if button_index==MOUSE_BUTTON_LEFT:
		_inspect_land_from_screen(screen_position)
		return true
	if button_index!=MOUSE_BUTTON_RIGHT:return false
	if selected_army_id!=-1:
		_order_selected_army_to_screen(screen_position)
		return true
	if not GameState.settlement_site_committed:
		_move_settlers_to_screen(screen_position)
		return true
	return false


func _inspect_land_from_screen(screen_position:Vector2)->void:
	var hit:Dictionary=_terrain_hit(screen_position)
	if hit.is_empty() or not hit.get("position") is Vector3:return
	_inspect_location(hit.position)

func _focus_settlement_from_screen(screen_position: Vector2, close_inspection: bool, city_id:String="") -> bool:
	if camera==null or not ("Hearth Circle" in GameState.settlement_completed):
		return false
	var selected:Dictionary={}
	var selected_screen_distance:=INF
	if city_id.is_empty() and is_instance_valid(city_labels):
		var card:Dictionary=city_labels.city_at(screen_position)
		if not card.is_empty():
			if card.foreign:return false
			city_id=String(card.id)
	for settlement in _settlement_model().settlement_network_snapshot().settlements:
		if not city_id.is_empty() and String(settlement.get("id",""))!=city_id:continue
		var center_2d:Vector2=settlement.get("position",Vector2.ZERO)
		var candidate_center:=Vector3(center_2d.x,_height_at(center_2d.x,center_2d.y),center_2d.y)
		if camera.is_position_behind(candidate_center): continue
		var distance:=screen_position.distance_to(camera.unproject_position(candidate_center))
		if not city_id.is_empty():distance=0.0
		if bool(settlement.get("primary",false)) and settlement_map_label and settlement_map_label.visible and settlement_map_label.layers!=0:
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
	_settlement_model().select_settlement(String(selected.get("id","")))
	var selected_center_2d:Vector2=selected.get("position",Vector2.ZERO)
	var center:=Vector3(selected_center_2d.x,_height_at(selected_center_2d.x,selected_center_2d.y),selected_center_2d.y)
	_set_camera_target(center)
	if close_inspection:
		# A double-click advances one legible scale instead of teleporting from a
		# regional map directly into a parcel. Repeated input can still reach the
		# site view while every intermediate landscape remains understandable.
		set_camera_distance_level(camera_distance_level()-1)
	_update_camera()
	_update_scale_lod()
	_inspect_location(center)
	# A marker is an entry into that named place's management context. Double-click
	# still means geographic zoom; a single click opens the existing dock rather
	# than introducing another permanent map panel.
	if hud and not close_inspection: _on_hud_section_requested("settlement",0)
	if travel_status_label:
		travel_status_label.text="%s: its people, stores and works are on the left. Double-click to move closer." % String(selected.get("name","Our settlement"))
	return true

func _update_camera() -> void:
	# camera.size remains the visible height at the focus plane for LOD and input.
	# Perspective gives the aerial view depth; distance follows its physical field
	# of view. The near plane expands at continental scale to preserve depth precision.
	var effective_distance:=camera.size/(2.0*tan(deg_to_rad(camera.fov)*0.5)) if SEAMLESS_WORLD else camera_distance
	if SEAMLESS_WORLD:
		camera.near=maxf(0.00005,effective_distance*lerpf(0.001,0.20,smoothstep(30.0,1200.0,camera.size)))
		camera.far=maxf(240.0,effective_distance*4.0+camera.size*4.0)
	# Continental footprints become progressively more nadir-facing. A strongly
	# oblique camera only a few dozen kilometres above a 20,000 km plane exposed its
	# horizon and left half the screen empty; real globe viewers also relax toward a
	# top-down map as the footprint approaches continental scale.
	var continental_nadir:=smoothstep(1300.0,6200.0,camera.size)
	var display_pitch:=lerpf(camera_pitch,-1.555,continental_nadir) if camera_pitch> -1.56 else camera_pitch
	var horizontal := cos(display_pitch) * effective_distance
	camera.position = camera_target + Vector3(cos(camera_yaw) * horizontal, -sin(display_pitch) * effective_distance, sin(camera_yaw) * horizontal)
	# Build orientation from the requested angles, before large world positions
	# round away the tiny horizontal offset in a near-vertical aerial view.
	# Subtracting target from position made look_at lose yaw near the map edges.
	var backward:=Vector3(cos(camera_yaw)*cos(display_pitch),-sin(display_pitch),sin(camera_yaw)*cos(display_pitch)).normalized()
	var right:=Vector3(sin(camera_yaw),0.0,-cos(camera_yaw))
	camera.basis=Basis(right,backward.cross(right).normalized(),backward)

func _queue_camera_zoom(pointer:Vector2,steps:float,fast:bool=false)->void:
	if camera==null: return
	# Fine zoom well past the far lands eases into the world view.
	if steps>0.0 and SEAMLESS_WORLD and camera.size>=_distance_camera_size(CAMERA_DISTANCE_LEVELS.size()-1)*WORLD_VIEW_ZOOM_RATIO and open_world_globe(true):return
	var start:=zoom_target_size if zoom_target_size>0.0 and not zoom_preset_active else camera.size
	zoom_preset_active=false
	# Keep rapid wheel/gesture bursts from banking a large invisible zoom jump.
	var requested:=start*pow(1.22 if fast else 1.12,clampf(steps,-2.0,2.0))
	zoom_target_size=clampf(requested,maxf(.035,camera.size/1.6),minf(camera.size*1.6,18000.0 if SEAMLESS_WORLD else 128.0))
	zoom_pointer=pointer
	camera_input_msec=Time.get_ticks_msec()

func _distance_camera_size(index:int)->float:
	var viewport_size:=get_viewport().get_visible_rect().size if is_inside_tree() else Vector2(1280,720)
	return float(CAMERA_DISTANCE_LEVELS[clampi(index,0,3)].width_km)/maxf(.1,viewport_size.x/maxf(1.0,viewport_size.y))

func set_camera_distance_level(index:int)->void:
	if camera==null: return
	var viewport_size:=get_viewport().get_visible_rect().size if is_inside_tree() else Vector2(1280,720)
	var aspect:=viewport_size.x/maxf(1.0,viewport_size.y)
	camera.keep_aspect=Camera3D.KEEP_HEIGHT
	camera.fov=rad_to_deg(2.0*atan(tan(deg_to_rad(25.0))/aspect))
	camera_pitch=-PI*.5+.0001
	zoom_target_size=clampf(_distance_camera_size(index),.035,18000.0 if SEAMLESS_WORLD else 128.0)
	zoom_preset_active=true
	zoom_pointer=viewport_size*.5
	camera_input_msec=Time.get_ticks_msec()

func camera_distance_level()->int:
	if camera==null:return 0
	var distance:=zoom_target_size if zoom_preset_active and zoom_target_size>0 else camera.size
	var best:=0
	for index in range(1,CAMERA_DISTANCE_LEVELS.size()):
		if absf(log(distance/_distance_camera_size(index)))<absf(log(distance/_distance_camera_size(best))):best=index
	return best

func _step_camera_distance(pointer:Vector2,steps:float,precise:bool=false)->void:
	if camera==null:return
	var now:=Time.get_ticks_msec()
	# A wheel burst or one trackpad gesture advances only one distance. No queue
	# of unseen steps can carry the player all the way across the map.
	if now-distance_input_msec<650:return
	if precise:
		distance_gesture_steps+=steps
		if absf(distance_gesture_steps)<.8:return
		steps=distance_gesture_steps
	distance_gesture_steps=0.0
	# One step out past the far lands eases into the world view.
	if steps>0.0 and SEAMLESS_WORLD and camera_distance_level()>=CAMERA_DISTANCE_LEVELS.size()-1 and open_world_globe(true):
		distance_input_msec=now
		return
	var next:=clampi(camera_distance_level()+(1 if steps>0.0 else -1),0,3)
	set_camera_distance_level(next)
	zoom_pointer=pointer
	distance_input_msec=now

## The world view (hud/world_globe.gd): the whole world as a turning globe,
## and how much of it our people know. Opened by the toolbar's World button
## or by zooming out past the far lands; it hands the map back itself.
const WORLD_VIEW_ZOOM_RATIO:=2.0
var world_globe:Control

func open_world_globe(from_zoom:bool=false)->bool:
	if is_instance_valid(world_globe):return true
	world_globe=preload("res://scripts/hud/world_globe.gd").open(self,hud,from_zoom)
	return world_globe!=null

## The world view hands the map back over a place at the far-lands distance;
## it then eases in to a nearer distance itself.
func _world_view_arrive(position:Vector2)->void:
	if camera==null:return
	set_camera_distance_level(CAMERA_DISTANCE_LEVELS.size()-1)
	camera.size=zoom_target_size
	zoom_target_size=-1.0
	zoom_preset_active=false
	zoom_log_velocity=0.0
	pan_coast_velocity=Vector3.ZERO
	_set_camera_target(Vector3(position.x,0.0,position.y))
	_update_scale_lod()

func _reset_camera_north()->void:
	north_reset_active=true
	camera_input_msec=Time.get_ticks_msec()

func _camera_in_motion()->bool:
	return zoom_target_size>0.0 or north_reset_active or dragging or pan_coast_velocity!=Vector3.ZERO or key_pan_velocity!=Vector2.ZERO or Time.get_ticks_msec()-camera_input_msec<100

func _process_smooth_camera(delta:float)->void:
	if camera==null: return
	var blend:=1.0-exp(-8.0*maxf(0.0,delta))
	var map_motion:=preload("res://scripts/map_motion.gd")
	if zoom_target_size>0.0:
		# A critically damped glide in log(size): eases in, eases out, never overshoots.
		var glide:=map_motion.zoom_step(camera.size,zoom_log_velocity,zoom_target_size,maxf(0.0,delta))
		var next:=glide.x
		zoom_log_velocity=glide.y
		if glide.z>0.5:
			next=zoom_target_size
			zoom_target_size=-1.0
			zoom_preset_active=false
			zoom_log_velocity=0.0
		_zoom_camera_at_screen(zoom_pointer,next,false)
	else:
		zoom_log_velocity=0.0
	if pan_coast_velocity!=Vector3.ZERO:
		if dragging:pan_coast_velocity=Vector3.ZERO
		else:
			_set_camera_target(camera_target+pan_coast_velocity*maxf(0.0,delta))
			pan_coast_velocity=map_motion.coast_step(pan_coast_velocity,maxf(0.0,delta),camera.size)
	if north_reset_active:
		camera_yaw=lerp_angle(camera_yaw,PI*0.5,blend)
		if absf(wrapf(camera_yaw-PI*0.5,-PI,PI))<0.001:
			camera_yaw=PI*0.5
			north_reset_active=false
		_update_camera()


func aerial_altitude_feet()->float:
	if camera==null: return 0.0
	return maxf(0.0,camera.position.y-_height_at(camera.position.x,camera.position.z))*3280.839895

func _inspect_aerial_altitude(feet:float=10000.0)->void:
	if camera==null: return
	zoom_target_size=-1.0
	camera_pitch=deg_to_rad(-50.0)
	var wanted:=maxf(0.05,feet/3280.839895)
	var lower:=0.05
	var upper:=maxf(20.0,wanted*4.0)
	for iteration in 24:
		var distance:=(lower+upper)*0.5
		camera.size=distance*2.0*tan(deg_to_rad(camera.fov)*0.5)
		_update_camera()
		if aerial_altitude_feet()/3280.839895<wanted: lower=distance
		else: upper=distance
	_update_scale_lod()


func _zoom_camera_at_screen(screen_position:Vector2,requested_size:float,refresh_lod:bool=true)->void:
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
	if refresh_lod: _update_scale_lod()


func _on_score_interval_timeout()->void:
	# Score cadence is wall-clock based: simulation speed and pausing the world do
	# not turn a ten-minute musical cue into a stutter or a rapid replay. Tracks
	# rotate in score order; a cue never cuts off a piece that is still playing.
	var score_player:=get_node_or_null("Score") as AudioStreamPlayer
	if score_player==null or score_player.playing: return
	score_track_index=(score_track_index+1)%SCORE_TRACKS.size()
	score_player.stream=SCORE_TRACKS[score_track_index]
	score_player.play()

func _initialize_city_resource_sites(settlement_id:String)->void:
	if WorldSimulation.enabled:
		var record:=SettlementModel.settlement_record(settlement_id)
		if not record.is_empty():SettlementModel.with_city_resources(settlement_id,func()->void:preload("res://scripts/civilization_resources.gd").initialize(record.position))
		return
	var model:=_settlement_model()
	var city:Dictionary=model.settlement_record(settlement_id)
	if city.is_empty() or bool(city.get("primary",false)) : return
	model.city_resource_snapshot(settlement_id)
	var point:Vector2=city.position
	var local_deposits:Array[Dictionary]=[]
	local_deposits.assign(city.local_resources.resource_deposits)
	var retained:Array[Dictionary]=[]
	# Transfer nearby physical occurrences, preserving depletion and knowledge;
	# never duplicate a deposit or the first city's delivered inventory.
	for deposit in GameState.resource_deposits:
		var location:=Vector2(deposit.position.x,deposit.position.z)
		var nearest_id:=settlement_id
		var distance:=point.distance_to(location)
		for other in GameState.player_settlements:
			var other_distance:float=(other.position as Vector2).distance_to(location)
			if other_distance<distance:
				distance=other_distance
				nearest_id=String(other.id)
		if (String(deposit.get("source_settlement_id",""))==settlement_id or (nearest_id==settlement_id and distance<=6.0 and String(deposit.get("source_settlement_id",""))=="")) and (deposit.get("shipments",[]) as Array).is_empty():
			local_deposits.append(deposit)
		else: retained.append(deposit)
	GameState.resource_deposits=retained
	city.local_resources.resource_deposits=local_deposits
	city["resource_sites_initialized"]=true

func _process_other_city_resources()->void:
	for city in GameState.player_settlements:
		if bool(city.get("primary",false)): continue
		var city_id:=String(city.id)
		_initialize_city_resource_sites(city_id)
		var point:Vector2=city.position
		var context:={"origin":Vector3(point.x,0.0,point.y),"traveling":false,"settled":true,"surface_water_distance_km":_river_distance_at(point.x,point.y)*KM_PER_WORLD_UNIT,"tools":ConsequenceEngine.tools_factor()}
		context["surface_material_catchments"]=_surface_material_catchments(Vector3(point.x,0.0,point.y))
		context["woodland_catchment"]=context.surface_material_catchments.Timber
		context["settlement_origin"]=Vector3(point.x,0,point.y)
		context["terrain_height_at"]=_height_at
		context["terrain_land_at"]=func(offset:Vector2)->bool:return _settlement_stage_land_at(point+offset)
		_settlement_model().process_city_resources(city_id,context,_process_settlement_day)
	_settlement_model().process_city_trade(_city_trade_route_assessment)

func _city_trade_route_assessment(source:Dictionary,destination:Dictionary)->Dictionary:
	var start:Vector2=source.position
	var finish:Vector2=destination.position
	return _analyze_convoy_route(Vector3(start.x,0.0,start.y),Vector3(finish.x,0.0,finish.y))


var settlement_camera_tween:Tween
func _select_city(settlement_id:String)->void:
	if not bool(SettlementModel.select_settlement(settlement_id).get("ok",false)): return
	_initialize_city_resource_sites(settlement_id)
	var city:=SettlementModel.settlement_record(settlement_id)
	var point:Vector2=city.position
	var destination:=Vector3(point.x,_height_at(point.x,point.y),point.y)
	if settlement_camera_tween and settlement_camera_tween.is_running(): settlement_camera_tween.kill()
	var start:=camera_target
	set_camera_distance_level(0)
	settlement_camera_tween=create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	settlement_camera_tween.tween_method(func(weight:float)->void:
		_set_camera_target(start.lerp(destination,weight))
		_update_camera()
		_update_scale_lod()
	,0.0,1.0,0.65)
	if hud:
		hud.refresh()
		hud.close_detail()
		if hud.dock and hud.dock.visible: hud.dock.rebuild()
	_refresh_discovered_resource_overlays()

func _refresh_close_army_figures(armies:Array,_selected_army_id:int)->void:
	# Field armies now have physical fronts on their main marker. Only occupation
	# garrisons need a separate bounded ground representation here.
	var keep: Dictionary = {}
	for army: Dictionary in armies:
		if not bool(army.get("garrison_visual",false)) or keep.size() >= MAX_CLOSE_ARMY_FORMATIONS: continue
		var id := str(army.get("army_id",0)); keep[id] = true
		var root: Node3D = close_army_figures.get(id)
		if root == null:
			root = Node3D.new(); root.name = "GarrisonFront_"+id; add_child(root); close_army_figures[id] = root
		_apply_physical_army_front(root,{"position":army.get("position",{}),"front_force":army,"color":WarfareMapPresentation.PLAYER_COLOR})
	for id in close_army_figures.keys():
		if keep.has(id): continue
		close_army_figures[id].queue_free(); close_army_figures.erase(id)

func _focus_known_city(city_id:String)->void:
	var report:=CivilizationSystem.city_intelligence.known("player",city_id)
	if report.is_empty():return
	if hud:hud.close_detail();hud.close_dock()
	if is_instance_valid(CivilizationSystem.city_intelligence.screen_layer):CivilizationSystem.city_intelligence.screen_layer.queue_free()
	zoom_target_size=-1
	set_camera_distance_level(0)
	_set_camera_target(Vector3(float(report.position.x),0,float(report.position.z)))
	_refresh_contact_encounter_markers()

func _scatter_owned_resources()->void:
	var origin:=Vector2(world_start_position.x,world_start_position.z)
	preload("res://scripts/civilization_resources.gd").initialize(origin)
	resource_sites.clear()
	var rng:=RandomNumberGenerator.new();rng.seed=GameState.world_seed
	for deposit in GameState.resource_deposits:
		if String(deposit.resource) not in ResourceSystem.FOUNDING_SURFACE_RESOURCES:continue
		var type:=String(deposit.resource)
		if type=="Fertile Soil":type="Fertile"
		var center:Vector3=deposit.position;center.y=_height_at(center.x,center.z)
		resource_sites.append({"type":type,"position":center,"range":13.0,"potential":float(deposit.environment_potential),"initially_observed":_world_position_is_revealed(center)})
		if type=="Timber":_create_forest_patch(center,rng)
		elif type=="Stone":_create_stone_patch(center,rng)
		else:_create_resource_marker(type,center)
