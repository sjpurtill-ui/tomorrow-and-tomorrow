class_name CityEncounterWorld
extends RefCounted

static func terrain(node:Node)->Node:
	if node.has_method("_focus_known_city"):return node
	for child in node.get_children():
		var found:=terrain(child)
		if found!=null:return found
	return null

static func focus(world:Node,region:String)->void:
	if world==null:return
	if not region.is_empty() and not CivilizationSystem.city_intelligence.known("player",region).is_empty():
		world._focus_known_city(region)
	else:
		world._set_camera_target(GameState.settlement_founded_at)
		world.camera.size=.28
	world._set_game_speed(0)

static func cloth_mask(color:Color)->float:
	# Authored material colors, never skin, wood, metal, horses or weapons.
	for swatch in [Color(.34,.24,.16),Color(.24,.29,.33),Color(.18,.32,.22),Color(.15,.24,.40),Color(.23,.35,.16),Color(.62,.37,.12),Color(.12,.24,.36),Color(.18,.29,.14),Color(.46,.095,.055)]:
		if Vector3(color.r-swatch.r,color.g-swatch.g,color.b-swatch.b).length()<.008:return .92
	return 0.0

static func standard(parent:Node3D,color:Color)->Node3D:
	var root:=Node3D.new();root.name="AllegianceStandard";parent.add_child(root)
	var friendly:=color.b>color.r
	for part in 4:
		var mesh:=MeshInstance3D.new();var box:=BoxMesh.new();mesh.mesh=box;root.add_child(mesh)
		var material:=StandardMaterial3D.new();material.albedo_color=color if part==1 else Color("eee8cd");material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;mesh.material_override=material
		if part==0:box.size=Vector3(.06,4,.06);mesh.position.y=2
		elif part==1:box.size=Vector3(1.6,1,.06);mesh.position=Vector3(.75,3.3,0)
		else:
			box.size=Vector3(.85,.14,.09);mesh.position=Vector3(.75,3.3,.02)
			mesh.rotation.z=(0.0 if part==2 else PI*.5) if friendly else (PI*.25 if part==2 else -PI*.25)
	return root
