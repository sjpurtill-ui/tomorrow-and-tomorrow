extends Node
## TEST CAPTURE HARNESS, not the game: renders one home dock on a settled test
## world and saves it, for UX review. Run it only through
## tools/run_isolated_gpu_probe.ps1 with user arguments
##   --dock=<section>/<sub> --out=res://artifacts/<name>.png
## and, for the Settlement dock's "New towns" switch, --auto-found=off.
const DockPanel:=preload("res://scripts/hud/dock_panel.gd")
const T:=preload("res://scripts/hud/hud_tokens.gd")
const PROVIDERS:={
	"economy":"res://scripts/hud/content/dock_content_economy.gd",
	"settlement":"res://scripts/hud/content/dock_content_settlement.gd",
	"government":"res://scripts/hud/content/dock_content_government.gd",
	"civ":"res://scripts/hud/content/dock_content_civilization.gd",
	"inquiry":"res://scripts/hud/content/dock_content_inquiry.gd",
	"health":"res://scripts/hud/content/dock_detail_health.gd",
}

class CaptureHud extends Control:
	signal section_requested(section:String,sub:int)
	var dock:Node
	func request_immediate_dock_refresh()->void:pass
	func open_detail(_provider:Object)->void:pass

## Stands in for the map so providers can bind their map actions.
class StubTerrain extends Node:
	func _toggle_resource_view()->void:pass
	func _settlement_display_name()->String:return "Ashford"
	func _open_settlement_naming_panel(_id:String="")->void:pass
	func _change_research_domain_allocation(_id:String,_delta:int)->void:pass
	func _discovery_context()->Dictionary:return {}
	func _report_military_action(_r:Dictionary)->void:pass
	func _able_population()->int:return 80
	func _dynamic_definition(_d:String)->String:return ""
	func _open_war_planning()->void:pass
	func _cancel_pending_pronouncement(_a:String,_b:String)->void:pass
	func _on_settlement_action_pressed()->void:pass

func _ready()->void:
	var section:="economy";var sub:=0;var out:="res://artifacts/ux-c/dock.png"
	for argument:String in OS.get_cmdline_user_args():
		if argument.begins_with("--dock="):
			var parts:=argument.trim_prefix("--dock=").split("/")
			section=parts[0];sub=int(parts[1]) if parts.size()>1 else 0
		elif argument.begins_with("--out="):out=argument.trim_prefix("--out=")
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	GameState.reset_for_new_world(515151)
	ResourceSystem.reset_for_new_world();FoodSystem.reset_for_new_world();SettlementModel.reset_for_new_world();GovernmentPeopleSystem.reset_for_new_world()
	GameState.initialize_population_model();GameState.ensure_population_total(140)
	GameState.settlement_completed=["Hearth Circle"];GameState.settlement_site_committed=true;GameState.settlement_name="Ashford"
	SettlementModel.ensure_founded();GovernmentPeopleSystem.initialize()
	GameState.resource_stockpiles.merge({"Timber":38.0,"Stone":12.0,"Clay":6.0},true)
	GameState.food_stocks.merge({"Fresh food":1800.0,"Stored food":1420.0},true)
	GameState.simulation_metrics["food_stocks"]=GameState.food_stocks.duplicate();GameState.simulation_metrics["food_spoilage_by_type"]={"Fresh food":2.6,"Stored food":0.4}
	# A plausible day's readings so every number has something to say.
	GameState.elapsed_days=400
	GameState.simulation_metrics.merge({"food_days":46.0,"food_production":62.0,"food_eaten":70.0,"food_spoilage":3.0,"food_net":-11.0,"food_weather_factor":0.9,"housing_ratio":0.85,"labor_efficiency":0.74,"cohesion":0.8,"food_forecast_90":{"first_shortage_day":38}},true)
	GameState.water_metrics={"required_today":140.0,"collected_today":126.0,"intake_ratio":0.9,"stored":60.0,"days":0.4}
	GameState.material_metrics.merge({"storage_capacity":80.0,"flow_ratio":0.55},true)
	PeopleDirection.reset_for_new_world();PeopleDirection.ensure()
	if "--auto-found=off" in OS.get_cmdline_user_args():preload("res://scripts/auto_founding.gd").set_on(false)
	var backdrop:=ColorRect.new();backdrop.color=T.PAPER;backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(backdrop)
	var hud:=CaptureHud.new();hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(hud)
	var panel=DockPanel.new();hud.add_child(panel);hud.dock=panel
	panel.position=Vector2(40,20);panel.size=Vector2(1100,860)
	var terrain:=StubTerrain.new();add_child(terrain)
	if section=="atlas":
		# The research atlas overlay, in the view named by the sub part.
		DiscoverySystem.initialize();DiscoverySystem._refresh_active_investigations()
		var view=preload("res://scripts/hud/research_atlas.gd").new();view.hud=hud;view.terrain=terrain;add_child(view)
		view.set_view(["active","tree","known"][clampi(sub,0,2)])
		for frame in 12:await get_tree().process_frame
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out.get_base_dir()))
		get_viewport().get_texture().get_image().save_png(out)
		print("UX_C_CAPTURE atlas ",sub," -> ",out)
		get_tree().quit();return
	var provider=load(PROVIDERS.get(section,PROVIDERS.economy)).new(terrain,hud)
	panel.present(provider,sub)
	for frame in 10:await get_tree().process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out.get_base_dir()))
	get_viewport().get_texture().get_image().save_png(out)
	print("UX_C_CAPTURE ",section,"/",sub," -> ",out)
	get_tree().quit()
