extends Control
const View=preload("res://scripts/hud/people_settlement_view.gd")
const Fixture=preload("res://tests/city_evolution_visual_fixture.gd")
var town:Control
const TownFixture=preload("res://tests/own_town_capture.gd")
class AuditTerrain extends "res://scripts/local_terrain.gd":
	func _ready()->void:pass
func _ready()->void:
	get_window().content_scale_size=get_window().size
	var maker:=TownFixture.new()
	var terrain:=AuditTerrain.new();add_child(terrain);terrain.set_process(false)
	var canvas:=ColorRect.new();canvas.color=Color("111e28");canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(canvas)
	town=View.new();town.position=Vector2(30,45);town.size=Vector2(1540,800);add_child(town)
	DirAccess.make_dir_recursive_absolute("res://artifacts/popup-modern-c/people-living")
	for year in [0,1800]:
		maker._world("early" if year==0 else "late")
		terrain._configure_seamless_world();terrain._configure_shape();terrain._configure_noise();terrain._prepare_river_course()
		GameState.settlement_founded_at=terrain._find_world_start_position()
		var data:Dictionary={"plots":GameState.settlement_plots,"routes":GameState.settlement_routes}
		if year>0:
			GameState.known_discoveries.append_array(["clay_shaping","stone_selection"])
			for plot:Dictionary in data.plots:
				if String(plot.get("land_use","")) not in ["residential_compound","mixed_household","workshop","storage","civic"]:continue
				for generation in range(1,5):
					var events:Array[Dictionary]=[]
					SettlementModel._apply_fabric_upgrade({"plot":plot,"next_tier":generation,"cost":SettlementModel._fabric_upgrade_cost(plot,generation)},1800*365,events)
		# A real in-progress conversion and damaged inherited home exercise the
		# original renderer, alongside the fixture's completed recorded upgrades.
		if year>0:
			data.plots[2].status="under_construction";data.plots[2].construction_progress=.58
			data.plots[3].condition=.35;data.plots[3].damage={"fire":.4}
		var before:=var_to_bytes([GameState.settlement_plots,GameState.settlement_routes])
		town.configure({"plots":data.plots,"routes":data.routes,"population":93 if year==0 else 1800,"terrain":terrain})
		var kinds:Dictionary={}
		for plot:Dictionary in data.plots:
			var kind:=String(plot.get("form",""));kinds[kind]=int(kinds.get(kind,0))+1
		print("PEOPLE_SCENE ",year," origin=",GameState.settlement_founded_at," kinds=",kinds," meshes=",town.model.get_child_count()," ground=",town._bounds)
		assert(before==var_to_bytes([GameState.settlement_plots,GameState.settlement_routes]),"Renderer wrote simulation records")
		for index in 30:await get_tree().process_frame
		await _capture("early-overview" if year==0 else "mature-overview")
		if year>0:
			for role:String in ["Crafting","Construction","Administration"]:
				town.focus_role(role)
				await get_tree().create_timer(.8).timeout
				await _capture("mature-"+role.to_lower())
			town.reset_view();await get_tree().create_timer(.8).timeout
			get_window().size=Vector2i(1024,720);get_window().content_scale_size=Vector2i(1024,720);town.position=Vector2(20,30);town.size=Vector2(984,650)
			await get_tree().create_timer(.4).timeout;await _capture("mature-overview-1024")
	print("PEOPLE_SETTLEMENT_CAPTURE PASS")
	maker.free()
	get_tree().quit()

func _capture(file:String)->void:
	if DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://artifacts/popup-modern-c/people-living/"+file+".png")
