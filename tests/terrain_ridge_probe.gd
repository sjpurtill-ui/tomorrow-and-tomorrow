extends "res://tests/ground_surface_probe.gd"
## Paired current/candidate captures with identical cameras and real materials.
## Baseline disables only the new physical relief contribution.
class NoRelief extends "res://scripts/terrain_mountain_relief.gd":
	func height_at(_x:float,_z:float,_uplift:float)->float:return 0.0
class Baseline extends Terrain:
	func _configure_noise()->void:
		super._configure_noise();mountain_relief=NoRelief.new()

func _ready()->void:
	if not OS.get_user_data_dir().ends_with("TomorrowCanopyTransitionTests") or OS.get_environment("TT_CAPTURE_OWNER")!="canopy-transition":
		push_error("Use the private background capture runner.");get_tree().quit(2);return
	output="res://artifacts/terrain-ridges/detail/"
	call_deferred("run")

func select_site(terrain:Terrain)->Vector2:
	var best:=-INF
	var point:=Vector2.ZERO
	for z in range(-5000,5001,160):
		for x in range(-10000,10001,160):
			if absf(x)<1500:continue
			var h:=terrain._height_at(x,z)
			if h<2:continue
			var belt:=clampf((terrain.mountain_noise.get_noise_2d(x*.41+9200,z*.41-3800)+.18)*1.55,0,1)
			var ridge_value:=terrain.mountain_noise.get_noise_2d(x,z)
			var score:=belt*pow(clampf((1-absf(ridge_value)-.34)/.66,0,1),2.35)
			if score>best:best=score;point=Vector2(x,z)
	return point

func run()->void:
	for node:Node in get_tree().root.get_children():
		if node!=self:node.set_process(false);node.set_physics_process(false)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	for seed_value:int in [873421,424242]:
		GameState.reset_for_new_world(seed_value)
		var original:=Baseline.new();original._configure_seamless_world();original._configure_shape();original._configure_noise()
		var point:=select_site(original)
		var candidate:=setup(seed_value)
		var canvas:=view()
		canvas.add_child(original);canvas.add_child(candidate)
		var camera:=Camera3D.new();canvas.add_child(camera)
		camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.near=.02;camera.far=600
		print("RIDGE_SITE ",seed_value," ",point)
		for width:float in [120.0,12.0,4.0]:
			var baseline_spread:=0.0
			camera.size=width
			var target:=Vector3(point.x,original._height_at(point.x,point.y),point.y)
			camera.position=target+Vector3(0,width*.85,width*.8);camera.look_at(target,Vector3.UP)
			for pair:Array in [["baseline",original],["detailed",candidate]]:
				var terrain:Terrain=pair[1];terrain.discovery_mask_texture=white_fog()
				var began:=Time.get_ticks_usec()
				var build:=BUILDER.new(257,width*2.5,point,terrain._height_at,terrain._terrain_color_at,terrain._terrain_surface_fields_at)
				while not build.advance(3000):await get_tree().process_frame
				print("RIDGE_BUILD ",seed_value," ",pair[0]," width=",width," wall_ms=",(Time.get_ticks_usec()-began)/1000.0)
				terrain._install_regional_patch({"mesh":build.commit(),"center":point,"span":width*2.5,"resolution":257,"heights":build.heights})
				terrain.regional_terrain_patch.material_override=terrain._create_terrain_material()
				terrain.regional_terrain_patch.show()
				var prefix:=output+str(seed_value)+"-"+str(int(width))+"-"+String(pair[0])
				await settle();var textured:=canvas.get_texture().get_image();textured.save_png(prefix+".png")
				var clay:=StandardMaterial3D.new();clay.albedo_color=Color(.48,.46,.42);clay.roughness=1
				terrain.regional_terrain_patch.material_override=clay
				await settle();var plain:=canvas.get_texture().get_image();plain.save_png(prefix+"-clay.png")
				check(plain.get_data()!=textured.get_data(),"textured capture uses actual surface material: "+prefix)
				var spread:=luminance_spread(plain)
				print("RIDGE_PLAIN_SPREAD ",seed_value," ",pair[0]," width=",width," spread=",spread)
				if pair[0]=="baseline":baseline_spread=spread
				elif width<=12:check(spread>baseline_spread*2,"local relief is visible without texture contrast")
				terrain.regional_terrain_patch.hide()
		canvas.queue_free();await settle()
	WorldSimulation.clear();print("TERRAIN_RIDGE_CAPTURE ","PASS" if errors==0 else "FAIL");get_tree().quit(errors)
