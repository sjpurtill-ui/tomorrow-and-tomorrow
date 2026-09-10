extends "res://tests/ground_surface_probe.gd"
## Capture-only comparison against an analytical flat-plane pixel footprint.
## Real generated sites below separately verify the production geography path.
const STABLE_FOOTPRINT:="max(length(dFdx(relative_position.xz)),length(dFdy(relative_position.xz)))"
func _ready()->void:
	output="res://artifacts/terrain-precision/"
	get_window().title="TEST — Terrain precision audit";get_window().mode=Window.MODE_MINIMIZED;call_deferred("run")
func shader_variant(material:ShaderMaterial,mode:String,footprint:float)->Shader:
	var source:=material.shader.code.replace("max(length(dFdx(relative_position.xz)), length(dFdy(relative_position.xz)))",STABLE_FOOTPRINT)
	if mode=="before":source=source.replace(STABLE_FOOTPRINT,"max(length(dFdx(world_position.xz)),length(dFdy(world_position.xz)))")
	elif mode=="reference":source=source.replace(STABLE_FOOTPRINT,str(footprint))
	var shader:=Shader.new();shader.code=source;return shader
func difference(a:Image,b:Image)->float:
	var error:=0.0;var count:=0
	for y in range(80,640,2):
		for x in range(80,1000,2):
			var p:=a.get_pixel(x,y);var q:=b.get_pixel(x,y)
			error+=absf(p.r-q.r)+absf(p.g-q.g)+absf(p.b-q.b);count+=3
	return error/float(count)
func run()->void:
	for node:Node in [GameState,MilitaryCampaign,CivilizationSystem]:node.set_process(false)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	for location:Vector2 in [Vector2.ZERO,Vector2(20000,0),Vector2(-20000,0),Vector2(0,-9800)]:
		for surface:String in ["ground","water"]:
			var canvas:=view();var terrain:=setup(873421);canvas.add_child(terrain);terrain.discovery_mask_texture=white_fog()
			var builder:=BUILDER.new(65,2,location,func(_x:float,_z:float)->float:return .2 if surface=="ground" else -.05,func(_x:float,_z:float,_h:float)->Color:return Color(.4,.3,.2,0),func(_x:float,_z:float,_h:float)->Vector4:return Vector4(1.2,.8,.5,.3))
			while not builder.advance(5000):await get_tree().process_frame
			terrain._install_regional_patch({"mesh":builder.commit(),"center":location,"span":2,"resolution":65,"heights":builder.heights});terrain._build_water()
			terrain.coastal_water_material.set_shader_parameter("wave_speed",0.0);terrain.ocean_surface.material_override.set_shader_parameter("wave_speed",0.0)
			var camera:=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=.6;camera.near=.05;camera.far=20;camera.position=Vector3(location.x,10,location.y);canvas.add_child(camera);camera.look_at(Vector3(location.x,0,location.y),Vector3.FORWARD)
			var material:ShaderMaterial=terrain.regional_terrain_patch.material_override if surface=="ground" else terrain.coastal_water_material
			var original:=material.shader;var variants:Dictionary={}
			for mode:String in ["before","after","reference"]:
				material.shader=original
				if mode!="after":material.shader=shader_variant(material,mode,.6/720.0)
				await settle();var picture:=canvas.get_texture().get_image();picture.save_png(output+surface+"-"+str(int(location.x))+"-"+str(int(location.y))+"-"+mode+".png");variants[mode]=picture
			var before:=difference(variants.before,variants.reference);var after:=difference(variants.after,variants.reference)
			print("PRECISION_ERROR ",JSON.stringify({"surface":surface,"point":str(location),"before":before,"after":after}))
			check(after<.0001,"stable "+surface+" filter matches analytical pixel footprint at "+str(location))
			if location!=Vector2.ZERO:check(after<before*.5,"reduced distant "+surface+" filter error at "+str(location))
			material.shader=original
			if surface=="ground":
				var anchor_shader:=Shader.new()
				anchor_shader.code=original.code.replace("floor(CAMERA_POSITION_WORLD.xz/64.0)*64.0","(floor(CAMERA_POSITION_WORLD.xz/64.0)*64.0+vec2(64.0,-64.0))")
				material.shader=anchor_shader
			else:terrain.SURFACE_PRECISION.configure_water(material,location+Vector2(64,-64))
			await settle();var reanchored:=canvas.get_texture().get_image()
			var anchor_error:=difference(variants.after,reanchored)
			print("PRECISION_REANCHOR ",surface," ",location," error=",anchor_error)
			check(anchor_error<.0005,"world "+surface+" pattern stays fixed across coordinate-frame changes at "+str(location))
			canvas.queue_free();await settle()
	await real_sites()
	WorldSimulation.clear();print("TERRAIN_PRECISION_CAPTURE ","PASS" if errors==0 else "FAIL");get_tree().quit(errors)

func real_sites()->void:
	var seeker:=setup(873421);var shore:=Vector2.INF
	for z in range(1000,7000,500):
		for x in range(10000,19000,500):
			var a:=Vector2(x,z);var b:=Vector2(x+500,z)
			if (seeker._height_at(a.x,a.y)>0)==(seeker._height_at(b.x,b.y)>0):continue
			var a_land:=seeker._height_at(a.x,a.y)>0
			for i in 24:
				var mid:=(a+b)*.5
				if (seeker._height_at(mid.x,mid.y)>0)==a_land:a=mid
				else:b=mid
			shore=(a+b)*.5;break
		if shore.is_finite():break
	seeker.free();check(shore.is_finite(),"located an actual far-world coastline from the physical generator")
	var places:={"drylands":Vector2(6600,-3280),"cold_barrens":Vector2(-17400,-7790)}
	if shore.is_finite():places["coast"]=shore
	for label:String in places:
		var point:Vector2=places[label];var canvas:=view();var terrain:=setup(873421);canvas.add_child(terrain);terrain.discovery_mask_texture=white_fog()
		var camera:=Camera3D.new();canvas.add_child(camera);terrain.camera=camera
		terrain.camera_target=Vector3(point.x,terrain._height_at(point.x,point.y),point.y)
		terrain.set_camera_distance_level(0);camera.size=terrain.zoom_target_size;terrain.zoom_target_size=-1;terrain._update_camera()
		var lod=terrain.TERRAIN_LOD;var span:float=lod.bucket(lod.view_span(camera.size,1.5,terrain.camera_pitch));var center:Vector2=lod.center_for(point,span)
		var builder:=BUILDER.new(lod.resolution_for(span),span,center,terrain._height_at,terrain._terrain_color_at,terrain._terrain_surface_fields_at)
		while not builder.advance(5000):await get_tree().process_frame
		terrain._install_regional_patch({"mesh":builder.commit(),"center":center,"span":span,"resolution":builder.resolution,"heights":builder.heights});terrain._build_water()
		await settle();canvas.get_texture().get_image().save_png(output+"real-"+label+".png")
		var h:=terrain._height_at(point.x,point.y);var climate:=terrain._climate_at(point.x,point.y,h)
		print("PRECISION_REAL_SITE ",JSON.stringify({"label":label,"point":str(point),"height_km":h,"rain":climate.precipitation,"warmth":climate.temperature,"altitude_km":camera.position.y-h,"grid":builder.resolution}))
		check(absf(camera.position.y-h-3.048)<.001,label+" uses the actual 10,000 ft camera")
		canvas.queue_free();await settle()
