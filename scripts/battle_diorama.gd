class_name BattleDiorama
extends Node3D

signal formation_selected(details: Dictionary)
const FRONT := preload("res://scripts/army_front_visual.gd")
const COLORS := [Color("67b4cf"), Color("de513d")]
var faction_colors: Array = COLORS.duplicate()
var camera: Camera3D
var armies: Array = []
var forces: Array = []
var groups: Array[Dictionary] = []
var generals: Array = [] # No giant commander actors; command remains in reports/conversation.
var clock := 0.0
var round_clock := 0.0
var playback_speed := 1.0
var yaw := 0.28
var elevation := 0.9
var zoom := 100.0
var target := Vector3.ZERO
var outcome := ""
var record: Dictionary = {}
var cinematic := false
var landscape: BattleLandscape
var live_terrain: Node
var city_center := Vector3.ZERO

func local_ground(point: Vector2) -> float:
	var world := to_global(Vector3(point.x,0,point.y))
	world.y = live_terrain._close_surface_height_at(world.x,world.z)
	return to_local(world).y

func _ready() -> void:
	landscape = BattleLandscape.new(); add_child(landscape)
	if live_terrain == null:
		var environment := WorldEnvironment.new()
		var settings := Environment.new(); settings.background_mode = Environment.BG_COLOR
		settings.background_color = Color("a7c9c8"); settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		settings.ambient_light_color = Color("d4dfd8"); settings.ambient_light_energy = 0.6
		environment.environment = settings; add_child(environment)
		var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-42,-28,0); sun.light_energy = 1.2; add_child(sun)
		landscape.build(Vector2(WorldSimulation.state.settlement_founded_at.x,WorldSimulation.state.settlement_founded_at.z),WorldSimulation.world.ground_survey_authority)
	else: landscape.live_height = local_ground
	camera = Camera3D.new(); camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.near = 0.001; camera.far = 1000000; add_child(camera)
	for side in 2:
		var front := FRONT.new(); front.name = "ArmyFront_%d" % side
		add_child(front); armies.append(front)
		front.ground = func(point: Vector2) -> float: return landscape.height_at(point+Vector2(front.position.x,front.position.z))+0.10
		if live_terrain != null:
			front.land = func(point: Vector2) -> bool:
				var world := to_global(Vector3(point.x+front.position.x,0,point.y+front.position.z))
				return live_terrain._settlement_stage_land_at(Vector2(world.x,world.z))
	_camera_update()

func reset(attacker: Dictionary, defender: Dictionary) -> void:
	forces = [attacker.duplicate(true),defender.duplicate(true)]
	record = {}; outcome = ""; clock = 0; round_clock = 0
	for group in groups:
		if is_instance_valid(group.banner): group.banner.free()
	groups.clear()
	var span := 50.0
	for side in 2:
		var front: ArmyFrontVisual = armies[side]
		front.configure(forces[side],faction_colors[side],1.0,0.0,true)
		var depth := 0.0
		for section in front.sections:
			for point in section.polygon:
				depth = maxf(depth,absf(point.y)); span = maxf(span,absf(point.x)*2.0)
		# No cohort positions exist in legacy records. These are opposing schematic
		# deployment bands at the recorded encounter, not invented tactical movement.
		front.position.z = (depth+1.0)*(1.0 if side==1 else -1.0)
		front.redraw()
		for section in front.sections:
			var index := int(section.index)
			var form: Dictionary = forces[side].get("formations",[])[index] if index < forces[side].get("formations",[]).size() else {}
			var banner := Label3D.new(); banner.visible = false; front.add_child(banner)
			groups.append({"side":side,"index":index,"id":UnitVisualCatalog.model(form,"equipment",index),"center":Vector3(section.center.x,0,section.center.y),"remaining":int(section.count),"initial":int(section.count),"banner":banner})
	zoom = maxf(90,span*1.3); target = Vector3.ZERO; _camera_update()

func apply_snapshot(attacker: Dictionary, defender: Dictionary, round_record: Dictionary = {}, final_outcome: String = "") -> void:
	if forces.is_empty(): reset(attacker,defender)
	forces = [attacker.duplicate(true),defender.duplicate(true)]
	record = round_record.duplicate(true); outcome = final_outcome; round_clock = 0
	for side in 2:
		var force: Dictionary = FRONT.combat_force(forces[side],record.get("termination",{}) if not outcome.is_empty() else {})
		if _routed(side): force["status"] = "retreating"
		armies[side].configure(force,faction_colors[side],1.0,0.0)
	for group in groups:
		group.remaining = 0
		for section in armies[group.side].sections:
			if int(section.index) == int(group.index):
				group.remaining = int(section.count); group.center = Vector3(section.center.x,0,section.center.y)

func _routed(side: int) -> bool:
	var key := "attacker" if side==0 else "defender"
	return outcome in [key+"_retreat","mutual_collapse",("defender_victory" if side==0 else "attacker_victory")]

func _process(delta: float) -> void:
	if forces.is_empty() or playback_speed <= 0: return
	clock += delta*playback_speed; round_clock += delta*playback_speed
	for army in armies: army.advance(delta*playback_speed)

func representative_count() -> int: return 0

func pick(point: Vector2) -> void:
	var closest := 28.0
	var selected: Dictionary = {}
	for group in groups:
		var at: Vector3 = armies[group.side].to_global(group.center)
		var distance := camera.unproject_position(at).distance_to(point)
		if distance < closest: closest = distance; selected = group
	if selected.is_empty(): return
	formation_selected.emit({"name":String(selected.id).replace("_"," ").capitalize(),"role":"formation","count":selected.remaining,"initial":selected.initial,"side":selected.side,"morale":forces[selected.side].get("morale",1),"readiness":forces[selected.side].get("readiness",1)})

func _camera_update() -> void:
	if camera == null: return
	camera.position = target+Vector3(sin(yaw)*cos(elevation),sin(elevation),cos(yaw)*cos(elevation))*maxf(140.0,zoom*1.2)
	camera.look_at(to_global(target)); camera.size = zoom*(.001 if live_terrain!=null else 1.0)

func orbit(amount: float,tilt:float=0.0) -> void:
	cinematic=false
	yaw += amount; elevation=clampf(elevation+tilt,.22,1.35); _camera_update()

func ground_at(point:Vector2)->Vector3:
	var origin:=to_local(camera.project_ray_origin(point))
	var direction:=global_basis.inverse()*camera.project_ray_normal(point)
	if direction.y>=0: return target
	var near:=0.0; var far:=maxf(2000,zoom*4)
	for step in 24:
		var distance:float=(near+far)*.5
		var sample:=origin+direction*distance
		if sample.y>landscape.height_at(Vector2(sample.x,sample.z)): near=distance
		else: far=distance
	return origin+direction*((near+far)*.5)


func pan(from:Vector2,to:Vector2)->void:
	cinematic=false
	target+=ground_at(from)-ground_at(to)
	_camera_update()

func zoom_at(point:Vector2,amount:float)->void:
	cinematic=false
	var anchor:=ground_at(point)
	zoom_by(amount)
	target+=anchor-ground_at(point)
	_camera_update()

func zoom_by(amount: float) -> void:
	zoom = clampf(zoom+amount,12,1000000); _camera_update()

func set_landscape(engagement:Dictionary)->void:
	if live_terrain!=null:
		var at:=BattleLandscape.encounter_position(engagement)
		scale=Vector3.ONE*.001
		rotation.y=-PI*.5
		position=Vector3(at.x,live_terrain._close_surface_height_at(at.x,at.y),at.y)
		if String(engagement.get("home_side",""))=="attacker":
			for army:Dictionary in WorldSimulation.military.field_armies:
				if int(army.get("army_id",0))!=int(engagement.get("home_force_id",-1)):continue
				var point:Dictionary=army.get("position",{})
				var actual:=Vector2(float(point.get("x",at.x)),float(point.get("z",at.y)))
				var approach:=at-actual
				if approach.length()>.015 and approach.length()<.4:
					var forward:=approach.normalized();var anchor:=actual+forward*.008
					position=Vector3(anchor.x,live_terrain._close_surface_height_at(anchor.x,anchor.y),anchor.y)
					rotation.y=atan2(forward.x,forward.y)
		city_center=to_local(Vector3(at.x,live_terrain._close_surface_height_at(at.x,at.y),at.y))
		landscape.live_height=local_ground
	else:landscape.build(BattleLandscape.encounter_position(engagement),WorldSimulation.world.ground_survey_authority)


## Field works a side fought from, drawn in front of its line: a ditch with
## an earth bank and a row of sharpened stakes (battle_tactics.gd
## "fortified_camp", in the hearth age "a ditch and stakes"), or dug
## trenches. Presentation only; the record owns every number.
var works: Node3D

func set_works(plan: Dictionary, _home_index: int = 0) -> void:
	if is_instance_valid(works): works.queue_free()
	works = Node3D.new(); works.name = "FieldWorks"; add_child(works)
	for side in 2:
		var key := "attacker" if side == 0 else "defender"
		var id := String((plan.get(key, {}) as Dictionary).get("id", ""))
		if id in ["fortified_camp", "entrenched_defence"] and side < armies.size():
			_build_ditch(side, id == "fortified_camp")

func _build_ditch(side: int, stakes: bool) -> void:
	var front: ArmyFrontVisual = armies[side]
	var depth := 0.0; var span := 12.0
	for section in front.sections:
		for point in section.polygon:
			depth = maxf(depth, absf(point.y)); span = maxf(span, absf(point.x) * 2.0)
	var toward := -1.0 if side == 1 else 1.0
	var holder := Node3D.new(); holder.name = "Works_%d" % side; front.add_child(holder)
	var earth := StandardMaterial3D.new(); earth.albedo_color = Color("3d3024"); earth.roughness = 1.0
	var bank := StandardMaterial3D.new(); bank.albedo_color = Color("7a6446"); bank.roughness = 1.0
	var wood := StandardMaterial3D.new(); wood.albedo_color = Color("5b4630"); wood.roughness = 0.9
	var pieces := maxi(4, int(span / 1.5))
	var width := span * 0.95 / float(pieces)
	for index in pieces:
		var x := -span * 0.475 + width * (float(index) + 0.5)
		for part in [[depth + 0.55, 0.7, 0.16, earth, -0.1], [depth + 0.1, 0.35, 0.28, bank, 0.05]]:
			var z: float = toward * float(part[0])
			var box := MeshInstance3D.new(); var mesh := BoxMesh.new()
			mesh.size = Vector3(width * 1.02, float(part[2]), float(part[1])); box.mesh = mesh
			box.material_override = part[3]
			box.position = Vector3(x, float(front.ground.call(Vector2(x, z))) + float(part[4]), z)
			holder.add_child(box)
	if not stakes: return
	var spacing := 0.7
	var count := maxi(6, int(span * 0.9 / spacing))
	for index in count:
		var x := -span * 0.45 + span * 0.9 * float(index) / float(maxi(1, count - 1))
		var z := toward * (depth + 1.05)
		var stake := MeshInstance3D.new(); var mesh := CylinderMesh.new()
		mesh.top_radius = 0.01; mesh.bottom_radius = 0.05; mesh.height = 1.1; mesh.radial_segments = 5
		stake.mesh = mesh; stake.material_override = wood
		stake.position = Vector3(x, float(front.ground.call(Vector2(x, z))) + 0.35, z)
		# Leaning out toward the enemy.
		stake.rotation = Vector3(deg_to_rad(-38.0) * -toward, 0.0, 0.0)
		holder.add_child(stake)
