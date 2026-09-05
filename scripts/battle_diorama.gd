class_name BattleDiorama
extends Node3D

signal formation_selected(details: Dictionary)
const FIGURES := preload("res://scripts/army_figure_formation.gd")
const MAX_PER_SIDE := 96
const COLORS := [Color("5ec7cc"), Color("dc7863")]
var camera: Camera3D
var armies: Array = []
var forces: Array = []
var initial_counts: Array = []
var groups: Array[Dictionary] = []
var missiles: Array[MeshInstance3D] = []
var clock := 0.0
var round_clock := 10.0
var playback_speed := 1.0
var yaw := 0.28
var zoom := 85.0
var target := Vector3(0,1,0)
var outcome := ""
var record: Dictionary = {}
var last_phase := ""
var cinematic := false

func _ready() -> void:
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("182a31")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("d4dfd8")
	settings.ambient_light_energy = 0.65
	environment.environment = settings; add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-42,-28,0); sun.light_color = Color("ffe4b2")
	sun.light_energy = 1.25; sun.shadow_enabled = true; add_child(sun)
	var floor_mesh := PlaneMesh.new(); floor_mesh.size = Vector2(600,600)
	var ground := MeshInstance3D.new(); ground.mesh = floor_mesh
	var mat := StandardMaterial3D.new(); mat.albedo_color = Color("536348"); mat.roughness = 1
	ground.material_override = mat; ground.position.y = -0.025; add_child(ground)
	# Sparse perimeter dressing never implies tactical cover or changes the terrain modifier.
	for i in 36:
		var rock := MeshInstance3D.new(); var stone := SphereMesh.new()
		stone.radial_segments = 5; stone.rings = 2; stone.radius = 0.45 + (i%4)*0.2; stone.height = stone.radius
		rock.mesh = stone
		var stone_mat := StandardMaterial3D.new(); stone_mat.albedo_color = Color("777863")
		rock.material_override = stone_mat
		rock.position = Vector3(sin(i*2.4)*100,0,cos(i*2.4)*75); add_child(rock)
	camera = Camera3D.new(); camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.far = 1000; add_child(camera); _camera_update()
	for side in 2:
		var army := FIGURES.new(); army.figure_limit = MAX_PER_SIDE
		army.rotation.y = PI if side == 1 else 0.0; army.position.z = 8 if side == 1 else -8
		add_child(army); armies.append(army)
		for i in 8:
			var missile := MeshInstance3D.new(); var ball := SphereMesh.new()
			ball.radius = .10; ball.height = .20; ball.radial_segments = 5; ball.rings = 2
			missile.mesh = ball; var projectile_mat := StandardMaterial3D.new()
			projectile_mat.albedo_color = COLORS[side].lightened(.3); missile.material_override = projectile_mat
			missile.visible = false; add_child(missile); missiles.append(missile)

func reset(attacker: Dictionary, defender: Dictionary) -> void:
	forces = [attacker.duplicate(true),defender.duplicate(true)]
	initial_counts = [UnitVisualCatalog.counts(attacker),UnitVisualCatalog.counts(defender)]
	groups.clear(); outcome = ""; record = {}; clock = 0; round_clock = 10; last_phase = ""
	for side in 2:
		var army: Node3D = armies[side]
		for child in army.get_children():
			if child is Label3D: child.free()
		army.configure(initial_counts[side],COLORS[side],2.0)
		var width := 0.0
		for id in army.batches:
			var batch: MultiMeshInstance3D = army.batches[id]
			var count := batch.multimesh.instance_count
			var role := UnitVisualCatalog.role(id)
			var spacing := 1.7 if role in ["melee","ranged"] else (3.4 if role == "mobile" else 5.0)
			if id == "counterweight_trebuchet": spacing = 8.0
			var columns := maxi(1,ceili(sqrt(float(count)*1.4)))
			var group_width := columns*spacing
			var depth := 0.0 if role == "melee" else (12.0 if role in ["mobile","ranged"] else 25.0)
			var transforms: Array[Transform3D] = []
			for i in count:
				var transform := Transform3D(Basis.IDENTITY,Vector3(width+(i%columns)*spacing,0,-depth-float(i/columns)*spacing))
				transforms.append(transform)
			var flags: Array[bool] = []; flags.resize(count); flags.fill(false)
			groups.append({"side":side,"id":id,"role":role,"batch":batch,"poses":transforms,"dead":flags,"initial":int(initial_counts[side][id]),"remaining":int(initial_counts[side][id]),"center":Vector3(width+group_width*.5,0,-depth)})
			width += group_width+4.0
		for group in groups:
			if group.side != side: continue
			group.center.x -= width*.5
			for i in group.poses.size():
				group.poses[i].origin.x -= width*.5
				(group.batch as MultiMeshInstance3D).multimesh.set_instance_transform(i,group.poses[i])
			var banner := Label3D.new(); banner.text = String(group.id).replace("_"," ").to_upper()
			banner.font_size = 24; banner.pixel_size = .008; banner.modulate = COLORS[side].lightened(.3)
			banner.billboard = BaseMaterial3D.BILLBOARD_ENABLED; banner.position = group.center+Vector3(0,4,0)
			army.add_child(banner)
	zoom = maxf(65, minf(150, float(groups.size())*10))
	_camera_update()

func apply_snapshot(attacker: Dictionary, defender: Dictionary, round_record: Dictionary = {}, final_outcome: String = "") -> void:
	if forces.is_empty(): reset(attacker,defender)
	forces = [attacker.duplicate(true),defender.duplicate(true)]
	record = round_record.duplicate(true); outcome = final_outcome
	round_clock = 0.0 if not record.is_empty() or not outcome.is_empty() else 10.0
	last_phase = ""
	for group in groups:
		var current := UnitVisualCatalog.counts(forces[group.side])
		group.remaining = int(current.get(group.id,0))
		var amount: int = group.poses.size()
		var alive := clampi(ceili(amount*float(group.remaining)/maxf(1,group.initial)),0,amount)
		for i in range(alive,amount):
			if group.dead[i]: continue
			group.dead[i] = true
			var custom := Color(float(i%13)/13.0,clock,1,1)
			(group.batch as MultiMeshInstance3D).multimesh.set_instance_custom_data(i,custom)

func _routed(side: int) -> bool:
	var key := "attacker" if side == 0 else "defender"
	return outcome == key+"_retreat" or outcome == "mutual_collapse" or (outcome == ("defender_victory" if side == 0 else "attacker_victory")) or float(forces[side].get("morale",1)) <= .15

func _process(delta: float) -> void:
	if forces.is_empty(): return
	clock += delta*playback_speed; round_clock += delta*playback_speed
	var phase := "walk" if round_clock < .45 else ("attack" if round_clock < 2.3 and not record.is_empty() else "idle")
	if phase != last_phase:
		for side in 2: armies[side].set_animation("walk" if _routed(side) else phase,true)
		last_phase = phase
	for side in 2:
		armies[side].animation_speed = playback_speed
		for material in armies[side].materials: material.set_shader_parameter("casualty_clock",clock)
	for group in groups:
		var batch: MultiMeshInstance3D = group.batch
		var routed := _routed(group.side)
		for i in group.poses.size():
			if group.dead[i]: continue
			var pose: Transform3D = group.poses[i]
			if routed:
				pose.basis = Basis(Vector3.UP,PI)
				pose.origin.z -= minf(20,round_clock*3.0)
			elif phase != "idle" and group.role in ["melee","mobile"]:
				pose.origin.z += minf(5,round_clock*9.0)
			# Disorganization is bounded by recorded morale, not random troop counts.
			var morale := float(forces[group.side].get("morale",1))
			pose.origin.x += sin(i*2.3)*maxf(0,.65-morale)*2.5
			batch.multimesh.set_instance_transform(i,pose)
	for side in 2:
		var fired := 0
		for used in record.get(("attacker" if side == 0 else "defender")+"_cohort_ammunition_used",[]): fired += int(used)
		for i in 8:
			var missile := missiles[side*8+i]
			var t := (round_clock-.95-i*.025)/.65
			missile.visible = fired > 0 and t > 0 and t < 1 and not _routed(side)
			if missile.visible:
				var z := lerpf(-20,10,t)*(1 if side == 0 else -1)
				missile.position = Vector3((i-3.5)*2.2,2+sin(PI*t)*8,z)
	if cinematic:
		yaw += delta*playback_speed*.06; _camera_update()

func _camera_update() -> void:
	if camera == null: return
	camera.position = target+Vector3(sin(yaw)*110,85,cos(yaw)*110)
	camera.look_at(target); camera.size = zoom

func orbit(amount: float) -> void:
	yaw += amount; _camera_update()

func zoom_by(amount: float) -> void:
	zoom = clampf(zoom+amount,12,220); _camera_update()

func pick(point: Vector2) -> void:
	var best := 70.0; var selected: Dictionary = {}
	for group in groups:
		var world: Vector3 = armies[group.side].to_global(group.center)
		var distance := camera.unproject_position(world).distance_to(point)
		if distance < best: best = distance; selected = group
	if selected.is_empty(): return
	formation_selected.emit({"name":String(selected.id).replace("_"," ").capitalize(),"role":selected.role,"count":selected.remaining,"initial":selected.initial,"side":selected.side,"morale":forces[selected.side].get("morale",1),"readiness":forces[selected.side].get("readiness",1)})

func representative_count() -> int:
	var total := 0
	for group in groups: total += group.poses.size()
	return total
