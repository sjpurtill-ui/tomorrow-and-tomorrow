extends Node3D
## Kit shape preview: every coded early building (settlement_kit_shapes.gd) in
## a row on plain ground, in the settlement ink, under the map's own low
## north-west sun, seen from the map's near-overhead camera. For quick
## before/after looks at the dwellings without loading a world.
##   -- --out=<absolute png> [--size=0.05] [--no-shadows] [--pitch=-1.45]
## Windowed only; run it through tools/run_isolated_gpu_probe.ps1.
const SHAPES:=preload("res://scripts/settlement_kit_shapes.gd")
const EARLY:=preload("res://scripts/early_settlement_visual.gd")
const TOWN:=preload("res://scripts/organic_town_visual.gd")
const INK:=preload("res://scripts/settlement_ink.gd")

func _ready()->void:
	AudioServer.set_bus_mute(0,true)
	var out:="user://kit_shape_preview.png"
	var size:=0.05
	var pitch:=-1.45
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--out="):out=argument.trim_prefix("--out=")
		elif argument.begins_with("--size="):size=float(argument.trim_prefix("--size="))
		elif argument.begins_with("--pitch="):pitch=float(argument.trim_prefix("--pitch="))
	var environment:=WorldEnvironment.new();var settings:=Environment.new()
	settings.background_mode=Environment.BG_COLOR;settings.background_color=Color("#1c1812")
	settings.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color=Color("#97a3ab");settings.ambient_light_energy=0.46
	settings.tonemap_mode=Environment.TONE_MAPPER_FILMIC
	environment.environment=settings;add_child(environment)
	var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-31,-138,0)
	sun.light_color=Color("#f4e4cc");sun.light_energy=1.12
	sun.shadow_enabled="--no-shadows" not in OS.get_cmdline_user_args()
	sun.shadow_blur=2.4;sun.shadow_opacity=0.52;sun.directional_shadow_max_distance=2.0
	add_child(sun)
	var ground:=MeshInstance3D.new();var plane:=PlaneMesh.new();plane.size=Vector2(1,1);ground.mesh=plane
	var grass:=StandardMaterial3D.new();grass.albedo_color=Color("#7d8a45");grass.roughness=1.0;ground.material_override=grass
	add_child(ground)
	var names:=["round_household","carried_round","carried_ridge","rooted_lean_to","raised_store","covered_workshop","earthen_household"]
	var x:=-0.018
	for name in names:
		_place(EARLY.kit_mesh(name),Vector3(x,0,-0.006),0.0)
		_place(EARLY.kit_mesh(name),Vector3(x,0,0.006),2.4)
		x+=0.006
	var props:=["dugout","coracle","weir","jetty","quay"]
	for i in props.size():
		var mesh:=SHAPES.prop(props[i])
		if mesh:_place(mesh,Vector3(-0.018+float(i)*0.008,0,-0.017),0.3)
	for variant in [0,1,2,3,5]:
		_place(TOWN.kit_mesh(variant),Vector3(-0.018+float([0,1,2,3,5].find(variant))*0.008,0,0.017),0.6)
	var camera:=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=size
	camera.near=0.001;camera.far=10.0
	var yaw:=-0.72
	var backward:=Vector3(cos(yaw)*cos(pitch),-sin(pitch),sin(yaw)*cos(pitch)).normalized()
	camera.position=backward*1.0
	var right:=Vector3.UP.cross(backward).normalized()
	camera.basis=Basis(right,backward.cross(right).normalized(),backward)
	add_child(camera);camera.current=true
	INK.set_pixel(size/900.0)
	for i in 30:await get_tree().process_frame
	RenderingServer.force_sync();RenderingServer.force_draw(true,0.0)
	var image:=get_viewport().get_texture().get_image()
	if image:image.save_png(ProjectSettings.globalize_path(out) if out.begins_with("user://") else out)
	print("KIT_SHAPE_PREVIEW: ",out)
	get_tree().quit(0)

func _place(mesh:Mesh,at:Vector3,angle:float)->void:
	var batch:=MultiMesh.new();batch.transform_format=MultiMesh.TRANSFORM_3D;batch.use_colors=true
	batch.mesh=mesh;batch.instance_count=1
	var transform:=Transform3D(SHAPES.lived_basis(angle,hash(at)),at)
	batch.set_instance_transform(0,transform);batch.set_instance_color(0,Color.WHITE)
	var node:=MultiMeshInstance3D.new();node.multimesh=batch;node.material_override=INK.material();add_child(node)
	var list:Array[Transform3D]=[transform]
	INK.add_ground_shadows(self,"Shadow%d" % get_child_count(),list,mesh.get_aabb())
