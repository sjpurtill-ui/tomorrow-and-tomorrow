extends Node
## Capture-only climate comparison using the live terrain shader and vegetation.
class Terrain extends "res://scripts/local_terrain.gd":
	var rain:=.82
	var warmth:=.65
	func _ready()->void:pass
	func _process(_delta:float)->void:pass
	func _climate_at(_x:float,_z:float,_height:float)->Dictionary:return {"temperature":warmth,"precipitation":rain,"river_distance":100.0}
	func _height_at(x:float,z:float)->float:return 1.0+sin(x*18)*.005+cos(z*14)*.006
	func _close_surface_height_at(x:float,z:float)->float:return _height_at(x,z)
	func _local_drainage_distance_at(_x:float,_z:float)->float:return .07
func _ready()->void:
	get_window().title="TEST — Landscape cover audit";get_window().mode=Window.MODE_MINIMIZED;call_deferred("run")
func settle()->void:
	for frame in 8:await get_tree().process_frame;RenderingServer.force_draw(false)
func rendered_crowns(terrain:Node)->Dictionary:
	var result:Dictionary={}
	for node:Node in terrain.close_vegetation_root.get_children():
		if node is MultiMeshInstance3D and node.name.begins_with("TreeCanopies"):
			for i in node.multimesh.instance_count:
				var transform:Transform3D=node.multimesh.get_instance_transform(i)
				result[transform.origin]=[transform.basis,node.name,node.multimesh.get_instance_color(i)]
	return result
func run()->void:
	for node:Node in [GameState,MilitaryCampaign,CivilizationSystem]:node.set_process(false)
	GameState.reset_for_new_world(424242)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts/landscape-cover"))
	var errors:=0
	for spec:Array in [["drylands",.17,.86],["grassland",.49,.65],["woodland",.84,.65],["cold-barrens",.50,.08]]:
		var view:=SubViewport.new();view.size=Vector2i(1080,720);view.own_world_3d=true;view.render_target_update_mode=SubViewport.UPDATE_ALWAYS;add_child(view)
		var terrain:=Terrain.new();terrain.rain=spec[1];terrain.warmth=spec[2]
		terrain.terrain_noise=FastNoiseLite.new();terrain.terrain_noise.seed=42
		terrain.moisture_noise=FastNoiseLite.new();terrain.moisture_noise.seed=51;terrain.moisture_noise.frequency=.2
		terrain.detail_noise=FastNoiseLite.new();terrain.detail_noise.seed=73;terrain.detail_noise.frequency=.25
		view.add_child(terrain)
		var material:=terrain._create_terrain_material()
		var fog:=Image.create(2,2,false,Image.FORMAT_RGBA8);fog.fill(Color.WHITE);material.set_shader_parameter("discovery_mask",ImageTexture.create_from_image(fog))
		var surface:=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		for z in 64:
			for x in 64:
				for offset:Vector2 in [Vector2(0,0),Vector2(1,0),Vector2(0,1),Vector2(1,0),Vector2(1,1),Vector2(0,1)]:
					var p:=(Vector2(x,z)+offset)/64*.70-Vector2(.35,.35)
					var h:=terrain._height_at(p.x,p.y);surface.set_color(terrain._terrain_color_at(p.x,p.y,h));surface.add_vertex(Vector3(p.x,h,p.y))
		surface.generate_normals();var mesh:=MeshInstance3D.new();mesh.mesh=surface.commit();mesh.material_override=material;terrain.add_child(mesh)
		terrain._rebuild_close_vegetation(Vector3.ZERO)
		var environment:=WorldEnvironment.new();var env:=Environment.new();env.background_mode=Environment.BG_COLOR;env.background_color=Color("182420");env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color.WHITE;env.ambient_light_energy=.88;environment.environment=env;terrain.add_child(environment)
		var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-55,-30,0);sun.light_energy=.85;terrain.add_child(sun)
		var camera:=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=.48;camera.near=.001;camera.far=10;camera.position=Vector3(0,1.55,.16);terrain.add_child(camera);camera.look_at(Vector3(0,1,0),Vector3.UP)
		var title:=Label.new();title.text=String(spec[0]).to_upper()+" · shared biome data / live vegetation";title.position=Vector2(22,18);title.add_theme_font_size_override("font_size",20);view.add_child(title)
		await settle();view.get_texture().get_image().save_png("res://artifacts/landscape-cover/"+String(spec[0])+".png")
		var canopy_count:=0;var scrub_count:=0
		for node:Node in terrain.close_vegetation_root.get_children():
			if node is MultiMeshInstance3D:
				if node.name.begins_with("TreeCanopies"):canopy_count+=node.multimesh.instance_count
				else:scrub_count+=node.multimesh.instance_count
		print("LANDSCAPE ",spec[0]," canopies=",canopy_count," scrub=",scrub_count)
		if spec[0]=="woodland":
			var before:=rendered_crowns(terrain)
			terrain._rebuild_close_vegetation(Vector3(.04,0,.02));await settle()
			var after:=rendered_crowns(terrain);var checked:=0
			for position:Vector3 in before:
				if absf(position.x)>.15 or absf(position.z)>.15:continue
				checked+=1
				if not after.has(position) or after[position]!=before[position]:errors+=1
			if checked==0:errors+=1
			print("NATIVE_CROWN_STABILITY checked=",checked," errors=",errors)
			# With ground hidden, only known foliage may change the clear background.
			mesh.hide();title.hide()
			var black:=Image.create(2,2,false,Image.FORMAT_RGBA8);black.fill(Color.BLACK)
			for reference:WeakRef in terrain.vegetation_fog_materials:
				var m=reference.get_ref()
				if m:m.set_shader_parameter("discovery_mask",ImageTexture.create_from_image(black));m.set_shader_parameter("fog_current_origin",Vector2(1000,1000))
			await settle();var hidden:=view.get_texture().get_image()
			terrain.close_vegetation_root.hide();await settle();var cleared:=view.get_texture().get_image()
			if hidden.get_data()!=cleared.get_data():errors+=1
			print("NATIVE_FOLIAGE_FOG errors=",errors)
		view.queue_free();await settle()
	WorldSimulation.clear();print("LANDSCAPE_COVER_CAPTURE ","PASS" if errors==0 else "FAIL");get_tree().quit(errors)
