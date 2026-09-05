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


func _find_coastal_audit_position(renderer:Node3D,origin:Vector3)->Vector3:
	# Find a true land/water edge without changing the authored terrain. The coarse
	# march ignores narrow rivers; the open-water checks favor an ocean or large lake.
	for bearing_index in 24:
		var direction:=Vector2.from_angle(TAU*float(bearing_index)/24.0)
		var side:=Vector2(-direction.y,direction.x)
		var last_land:=Vector2(origin.x,origin.z)
		for distance_index in 160:
			var distance:=50.0*float(distance_index+1)
			var sample:=Vector2(origin.x,origin.z)+direction*distance
			if renderer._height_at(sample.x,sample.y)>renderer.SEA_LEVEL+0.015:
				last_land=sample
				continue
			var broad_water:bool=renderer._height_at((sample+direction*12.0+side*6.0).x,(sample+direction*12.0+side*6.0).y)<=renderer.SEA_LEVEL+0.015 and renderer._height_at((sample+direction*12.0-side*6.0).x,(sample+direction*12.0-side*6.0).y)<=renderer.SEA_LEVEL+0.015
			if not broad_water: continue
			var land_edge:=last_land
			var water_edge:=sample
			for unused in 12:
				var midpoint:=land_edge.lerp(water_edge,0.5)
				if renderer._height_at(midpoint.x,midpoint.y)>renderer.SEA_LEVEL+0.015: land_edge=midpoint
				else: water_edge=midpoint
			var inland:=land_edge-direction*0.45
			return Vector3(inland.x,renderer._height_at(inland.x,inland.y),inland.y)
	return origin


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


func _multimesh_audit(node:Node)->Dictionary:
	var instance_count:=0
	var batch_count:=0
	var mesh_vertices:=0
	for child in node.get_children():
		if child is MultiMeshInstance3D:
			var instance:=child as MultiMeshInstance3D
			if instance.multimesh:
				batch_count+=1
				instance_count+=instance.multimesh.instance_count
				if instance.multimesh.mesh:
					for surface_index in instance.multimesh.mesh.get_surface_count():
						var arrays:=instance.multimesh.mesh.surface_get_arrays(surface_index)
						if not arrays.is_empty(): mesh_vertices+=(arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
		var nested:=_multimesh_audit(child)
		instance_count+=int(nested.instances)
		batch_count+=int(nested.batches)
		mesh_vertices+=int(nested.template_vertices)
	return {"instances":instance_count,"batches":batch_count,"template_vertices":mesh_vertices}


func _render_stage()->void:
	var stage:=_argument("--stage=","city").strip_edges().to_lower().replace("_"," ")
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
	var audit_agriculture:=_argument("--agriculture=","0")=="1"
	var fabric_lod:=clampi(int(_argument("--fabric-lod=","0" if stage in ["founding camp","hamlet","village"] else "1")),0,2)
	var aerial_lod_argument:=_argument("--aerial-lod=","auto").strip_edges().to_lower()
	var oblique_view:=_argument("--view=","aerial").strip_edges().to_lower()=="oblique"
	var district_condition:=clampi(int(_argument("--district-condition=","-1")),-1,7)
	var default_technology_tier:int=int({"founding camp":0,"hamlet":1,"village":2,"town":3,"city":4,"metropolis":6,"megalopolis":8}.get(stage,4))
	var technology_tier:=clampi(int(_argument("--technology-tier=",str(default_technology_tier))),0,8)
	var coastal_audit:=_argument("--coastal=","0")=="1"
	var surface_filter:=_argument("--surface-filter=","").strip_edges()

	GameState.reset_for_new_world(741991)
	GameState.select_founding_focus(focus)
	GameState.societal_values=VALUES.initial_state(focus,GameState.world_seed,"player")
	GameState.settlement_name="Visual Audit"
	GameState.ensure_population_total(population)
	ProgressionSystem.domain_levels["infrastructure"]=technology_tier
	ProgressionSystem.domain_levels["production"]=technology_tier
	ProgressionSystem.domain_levels["logistics"]=technology_tier
	ProgressionSystem.domain_levels["knowledge"]=technology_tier

	var renderer:=RENDERER.new()
	renderer._configure_seamless_world()
	renderer._configure_shape()
	renderer._configure_noise()
	renderer._prepare_river_course()
	var center:Vector3=renderer._find_camp_position()
	if coastal_audit: center=_find_coastal_audit_position(renderer,center)
	renderer.world_start_position=center
	GameState.settlement_founded_at=center
	GameState.settlement_site_committed=true
	GameState.settlement_completed.append("Hearth Circle")
	SettlementModel.ensure_founded()
	if coastal_audit and not GameState.player_settlements.is_empty():
		var coast_context:Dictionary=renderer._settlement_coastal_context(Vector2(center.x,center.z),0.78)
		SettlementModel.set_settlement_territory_context(String(GameState.player_settlements[0].get("id","")),coast_context)
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
	if audit_agriculture:
		var converted_fields:=0
		for plot_index in GameState.settlement_plots.size():
			if converted_fields>=6: break
			var plot:Dictionary=GameState.settlement_plots[plot_index]
			if String(plot.get("land_use","")) in ["water","waste","communal","civic","sacred"]: continue
			plot["land_use"]="field"
			plot["field_pattern"]="smallholder_mosaic"
			plot["cultivation_phase"]="mature" if plot_index%2==0 else "growing"
			plot["crop_family"]=["grain","pulses","roots"][plot_index%3]
			converted_fields+=1
	if route_tier>0:
		for route_index in engineered_routes:
			GameState.settlement_routes.append({
				"id":99001+route_index,"kind":"engineered_audit_route","active":true,
				"surface_tier":route_tier,"hierarchy":"regional_engineered"
			})
	# Monthly setup may legitimately re-evaluate progression. Restore the explicitly
	# requested audit tier immediately before rendering so the screenshot compares the
	# intended era instead of whichever bootstrap state completed last.
	for domain in ["infrastructure","production","logistics","knowledge"]:
		ProgressionSystem.domain_levels[domain]=technology_tier

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
	var audit_aerial_lod:=smoothstep(0.72,3.20,camera.size) if aerial_lod_argument=="auto" else clampf(float(aerial_lod_argument),0.0,1.0)
	# Near-overhead Google-Earth inspection: enough obliquity to reveal massing and
	# relief, but not enough for mountain elevation to collapse the footprint to a
	# horizon strip.
	camera.position=center+(Vector3(camera.size*0.34,camera.size*0.76,camera.size*0.46) if oblique_view else Vector3(camera.size*0.08,camera.size*1.25,camera.size*0.12))
	camera.current=true
	add_child(camera)
	camera.look_at(center,Vector3.UP)
	camera.make_current()
	renderer.camera=camera
	renderer.camera_target=center
	renderer.district_condition_visual_override=district_condition
	add_child(_build_ground(renderer,center,audit_extent*1.35))
	var physical:=Node3D.new()
	physical.name="AuditedUrbanSystem"
	add_child(physical)
	renderer.footprint_population=population
	var defense:Dictionary={"stage":defense_stage,"integrity":defense_integrity,"construction":{}}
	if include_plots:
		renderer._create_persistent_settlement_routes(center,GameState.settlement_routes,physical)
		renderer._create_plot_fabric(center,GameState.settlement_plots,fabric_lod,physical,fabric_lod==0)
	renderer._create_settlement_stage_landscape(center,profile,GameState.settlement_plots,fabric_lod,physical,defense)
	if not surface_filter.is_empty():
		for child in physical.get_children():
			child.visible=String(child.name)==surface_filter
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
		var multimesh_audit:=_multimesh_audit(physical)
		var coastal_profile:Dictionary=renderer._settlement_coastal_visual_profile(Vector2(center.x,center.z))
		var vertex_total:=0
		var surface_vertices:Dictionary={}
		for child in physical.get_children():
			if child is MeshInstance3D and (child as MeshInstance3D).mesh:
				var child_mesh:Mesh=(child as MeshInstance3D).mesh
				var child_vertices:=0
				for surface_index in child_mesh.get_surface_count(): child_vertices+=child_mesh.surface_get_array_len(surface_index)
				vertex_total+=child_vertices
				surface_vertices[String(child.name)]=child_vertices
		print("SETTLEMENT VISUAL AUDIT ",JSON.stringify({
			"stage":stage,"population":population,"radius_km":layout.radius,
			"damage":damage,"defense":defense_stage,"route_tier":route_tier,"technology_tier":technology_tier,"coastal":coastal_audit,
			"engineered_routes":engineered_routes,"include_plots":include_plots,"agriculture":audit_agriculture,
			"fabric_lod":fabric_lod,"aerial_lod":audit_aerial_lod,"view":"oblique" if oblique_view else "aerial","plots":GameState.settlement_plots.size(),"vertices":vertex_total,"surface_vertices":surface_vertices,
			"shoreline_access":coastal_profile.get("shoreline_access",0.0),"open_water_km":coastal_profile.get("nearest_open_water_km",INF),"maritime_visual_ready":coastal_profile.get("maritime_visual_ready",false),
			"multimesh_instances":multimesh_audit.instances,"multimesh_batches":multimesh_audit.batches,"multimesh_template_vertices":multimesh_audit.template_vertices,
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
