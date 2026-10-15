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
	var focus_only:="--focus-only" in OS.get_cmdline_user_args()
	var sightline:="--food-sightline" in OS.get_cmdline_user_args()
	if sightline:
		get_window().size=Vector2i(1024,768);get_window().content_scale_size=Vector2i(1024,768)
		town.position=Vector2(60,130);town.size=Vector2(904,537)
	for year in ([0] if sightline else ([1800] if focus_only else [0,1800])):
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
		var painted:=0
		for child in town.model.get_children():
			if child.has_meta("plot_id"):painted+=1
		print("PAINTED_BUILDINGS ",painted," / ",town._building_plan.buildings.size())
		for record:Dictionary in town._building_plan.buildings:
			if preload("res://scripts/hud/people_settlement_art.gd").building_style(record).is_empty():
				var plot:Dictionary=record.plot
				print("ART_FALLBACK ",plot.get("id")," ",plot.get("form")," ",plot.get("land_use")," ",plot.get("material_family")," roof=",plot.get("roof_plan")," floors=",plot.get("storeys")," state=",plot.get("status")," damage=",plot.get("damage",{}))
		assert(painted==town._building_plan.buildings.size(),"Representative recorded fabric has an unsupported painted form")
		print("PEOPLE_SCENE ",year," origin=",GameState.settlement_founded_at," kinds=",kinds," meshes=",town.model.get_child_count()," ground=",town._bounds)
		assert(before==var_to_bytes([GameState.settlement_plots,GameState.settlement_routes]),"Renderer wrote simulation records")
		for index in 30:await get_tree().process_frame
		# Dummy rendering cannot read back MultiMesh instance transforms.
		if DisplayServer.get_name()!="headless":
			var frames:=town.model.get_node_or_null("EarlyCommunalObjects/Prop_frame") as Node3D
			if frames!=null:assert(not frames.visible,"Painted construction retains a duplicate frame")
			if is_instance_valid(town._painted_yards):
				for prop:Node3D in town._painted_yards.get_children():
					var local:Vector3=town.model.to_local(prop.global_position)
					assert(absf(local.y-town._height(Vector2(local.x,local.z))-.00006)<.000001,"Painted yard prop lost its terrain contact")
		if sightline:
			var foliage:Array[Node3D]=[];var tree_data:Array[Transform3D]=[]
			for child:Node in town.model.get_children():
				if child is Node3D and bool(child.get_meta("foliage",false)):
					foliage.append(child);tree_data.append(child.transform)
			assert(not foliage.is_empty(),"Actual seeded foliage absent")
			var builds:int=town.geometry_builds
			town.focus_role("Food");await get_tree().create_timer(1.0).timeout
			assert(not town._foliage_materials.is_empty())
			assert(float(town._foliage_materials[0].get_shader_parameter("focus_cutaway"))>.98)
			await _capture("early-food-sightline")
			town.reset_view();await get_tree().create_timer(1.0).timeout
			assert(float(town._foliage_materials[0].get_shader_parameter("focus_cutaway"))<.02)
			for index in foliage.size():assert(tree_data[index]==foliage[index].transform,"Focus moved recorded tree positions")
			assert(town.geometry_builds==builds,"Focus rebuilt settlement geometry")
			await _capture("early-food-reset");break
		if focus_only:
			town.focus_role("Construction");await get_tree().create_timer(.8).timeout
			await _capture("mature-construction-outline");break
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
