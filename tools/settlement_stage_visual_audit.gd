extends Node

# Lightweight visual-regression harness for the bounded city renderer. It skips the
# planet, UI, vegetation, and civilization bootstrap so a graphics pass can compare
# city/metropolis/megalopolis silhouettes in seconds instead of rebuilding a world.

const RENDERER:=preload("res://scripts/local_terrain.gd")
const VALUES:=preload("res://scripts/societal_values_model.gd")


func _ready()->void:
	call_deferred("_render_stage")


func _argument(prefix:String,fallback:String)->String:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with(prefix): return argument.trim_prefix(prefix)
	return fallback


func _stage_population(stage:String)->int:
	return {
		"founding camp":120,"hamlet":280,"village":1200,"town":24000,
		"city":500000,"metropolis":5000000,"megalopolis":100000000
	}.get(stage,500000)


func _build_ground(renderer:Node3D,center:Vector3,span:float)->MeshInstance3D:
	var resolution:=161
	var surface:=SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z_index in resolution:
		for x_index in resolution:
			var uv:=Vector2(float(x_index)/float(resolution-1),float(z_index)/float(resolution-1))
			var world_x:=center.x+(uv.x-0.5)*span
			var world_z:=center.z+(uv.y-0.5)*span
			var height:float=renderer._height_at(world_x,world_z)
			surface.set_uv(uv)
			surface.set_color(renderer._terrain_color_at(world_x,world_z,height))
			surface.add_vertex(Vector3(world_x,height,world_z))
	for z_index in resolution-1:
		for x_index in resolution-1:
			var a:=z_index*resolution+x_index
			var b:=a+1
			var d:=(z_index+1)*resolution+x_index
			var c:=d+1
			for index in ([a,b,c,a,c,d] if (x_index+z_index)%2==0 else [a,b,d,b,c,d]): surface.add_index(index)
	surface.generate_normals()
	var ground:=MeshInstance3D.new()
	ground.mesh=surface.commit()
	var material:=StandardMaterial3D.new()
	material.albedo_texture=load("res://assets/terrain/temperate_regional_satellite_v2.png")
	material.vertex_color_use_as_albedo=true
	material.roughness=1.0
	ground.material_override=material
	return ground


func _render_stage()->void:
	var stage:=_argument("--stage=","city").strip_edges().to_lower()
	if stage not in ["founding camp","hamlet","village","town","city","metropolis","megalopolis"]: stage="city"
	var population:=maxi(1,int(_argument("--population=",str(_stage_population(stage)))))
	var output_path:=_argument("--output=","user://settlement_stage_visual_audit.png")
	var material_family:=_argument("--material=","stone").strip_edges().to_lower()
	if material_family not in ["organic","earth","stone"]: material_family="stone"
	var focus:=_argument("--focus=","inquiry").strip_edges().to_lower()
	if focus not in GameState.FOUNDING_FOCUS_ORDER: focus="inquiry"
	var damage:=clampf(float(_argument("--damage=","0.0")),0.0,1.0)
	var defense_stage:=clampi(int(_argument("--defense=","0")),0,5)
	var defense_integrity:=clampf(float(_argument("--defense-integrity=","1.0")),0.0,1.0)
	var route_tier:=clampi(int(_argument("--route-tier=","0")),0,8)
	var engineered_routes:=clampi(int(_argument("--engineered-routes=","1")),0,24)
	var include_plots:=_argument("--include-plots=","1")!="0"
	var fabric_lod:=clampi(int(_argument("--fabric-lod=","0" if stage in ["founding camp","hamlet","village"] else "1")),0,2)
	var audit_aerial_lod:=clampf(float(_argument("--aerial-lod=","1.0")),0.0,1.0)

	GameState.reset_for_new_world(741991)
	GameState.select_founding_focus(focus)
	GameState.societal_values=VALUES.initial_state(focus,GameState.world_seed,"player")
	GameState.settlement_name="Visual Audit"
	GameState.ensure_population_total(population)
	ProgressionSystem.domain_levels["infrastructure"]=8
	ProgressionSystem.domain_levels["production"]=8

	var renderer:=RENDERER.new()
	renderer._configure_seamless_world()
	renderer._configure_shape()
	renderer._configure_noise()
	renderer._prepare_river_course()
	var center:Vector3=renderer._find_camp_position()
	renderer.world_start_position=center
	GameState.settlement_founded_at=center
	GameState.settlement_site_committed=true
	GameState.settlement_completed.append("Hearth Circle")
	SettlementModel.ensure_founded()
	# Give post-camp audits the same persistent-ground conversion that play earns.
	# The city silhouette is still forced for comparison, but the close fabric beneath
	# it remains an actual founding morphology rather than a hand-authored prop.
	if stage!="founding camp":
		for work_name in ["Lean-to Shelters","Storage Pits","Open Work Area","Gathering Yard"]:
			if work_name not in GameState.settlement_completed: GameState.settlement_completed.append(work_name)
		GameState.population_allocations["Construction"]=maxi(10,int(population*0.04))
		GameState.population_allocations["Crafting"]=maxi(8,int(population*0.025))
		GameState.simulation_metrics["labor_efficiency"]=0.78
		GameState.resource_stockpiles["Timber"]=240.0
		GameState.resource_stockpiles["Fiber Plants"]=240.0
		GameState.elapsed_days=30.0
		SettlementModel.process_month()
	for plot_index in GameState.settlement_plots.size():
		var plot:Dictionary=GameState.settlement_plots[plot_index]
		if String(plot.get("land_use",""))=="field": continue
		plot["material_family"]=material_family
		var damaged:=float(plot_index)/maxf(1.0,float(GameState.settlement_plots.size()))<damage
		plot["condition"]=(0.18+float(plot_index%5)*0.06) if damaged else 0.88
		if damaged: plot["status"]="ruin" if plot_index%4==0 else "damaged"
		plot["prosperity"]=0.62
	if route_tier>0:
		for route_index in engineered_routes:
			GameState.settlement_routes.append({
				"id":99001+route_index,"kind":"engineered_audit_route","active":true,
				"surface_tier":route_tier,"hierarchy":"regional_engineered"
			})

	var profile:Dictionary=renderer._settlement_expansion_visual_profile({
		"classification":stage,"population":population,"stage_progress":0.0
	})
	var layout:Dictionary=renderer._settlement_stage_visual_layout(profile,population,GameState.settlement_plots)
	var audit_extent:=maxf(1.0,float(layout.radius)*2.45)
	var camera:=Camera3D.new()
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	# Permit plot-scale audits as well as regional ones. The old 1.2 km floor made a
	# founding camp occupy a few pixels, hiding precisely the roof and yard transition
	# this harness now exists to inspect.
	camera.size=maxf(0.10,float(_argument("--zoom=",str(audit_extent))))
	# Near-overhead Google-Earth inspection: enough obliquity to reveal massing and
	# relief, but not enough for mountain elevation to collapse the footprint to a
	# horizon strip.
	camera.position=center+Vector3(camera.size*0.08,camera.size*1.25,camera.size*0.12)
	camera.current=true
	add_child(camera)
	camera.look_at(center,Vector3.UP)
	camera.make_current()
	renderer.camera=camera
	renderer.camera_target=center
	add_child(_build_ground(renderer,center,audit_extent*1.35))
	var physical:=Node3D.new()
	physical.name="AuditedUrbanSystem"
	add_child(physical)
	renderer.footprint_population=population
	var defense:Dictionary={"stage":defense_stage,"integrity":defense_integrity,"construction":{}}
	if include_plots:
		renderer._create_persistent_settlement_routes(center,GameState.settlement_routes,physical)
		renderer._create_plot_fabric(center,GameState.settlement_plots,fabric_lod,physical)
	renderer._create_settlement_stage_landscape(center,profile,GameState.settlement_plots,fabric_lod,physical,defense)
	# This harness audits the strategic aerial representation directly. In gameplay
	# the same shader crossfades away during plot-level inspection.
	for child in physical.get_children():
		if child is MeshInstance3D and (child as MeshInstance3D).material_override is ShaderMaterial:
			((child as MeshInstance3D).material_override as ShaderMaterial).set_shader_parameter("aerial_lod",audit_aerial_lod)

	var environment:=WorldEnvironment.new()
	var environment_resource:=Environment.new()
	environment_resource.background_mode=Environment.BG_COLOR
	environment_resource.background_color=Color("#101713")
	environment_resource.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	environment_resource.ambient_light_color=Color("#d7d3c3")
	environment_resource.ambient_light_energy=0.82
	environment.environment=environment_resource
	add_child(environment)
	var sun:=DirectionalLight3D.new()
	sun.rotation_degrees=Vector3(-58.0,-32.0,0.0)
	sun.light_energy=0.78
	sun.shadow_enabled=true
	add_child(sun)

	await get_tree().process_frame
	await get_tree().process_frame
	RenderingServer.force_sync()
	RenderingServer.force_draw(true,0.0)
	var image:=get_viewport().get_texture().get_image()
	if image:
		image.save_png(ProjectSettings.globalize_path(output_path))
		print("SETTLEMENT VISUAL AUDIT ",JSON.stringify({
			"stage":stage,"population":population,"radius_km":layout.radius,
			"damage":damage,"defense":defense_stage,"route_tier":route_tier,
			"engineered_routes":engineered_routes,"include_plots":include_plots,
			"fabric_lod":fabric_lod,"aerial_lod":audit_aerial_lod,"plots":GameState.settlement_plots.size(),
			"surfaces":physical.get_child_count(),"output":ProjectSettings.globalize_path(output_path)
		}))
	# Release the off-tree renderer and its shared shader before the audit process
	# exits. This keeps repeated visual-regression runs free of false leak warnings.
	for child in get_children(): child.queue_free()
	await get_tree().process_frame
	renderer.settlement_fabric_shader=null
	renderer.free()
	await get_tree().process_frame
	get_tree().quit()
