class_name ArmyFigureFormation
extends Node3D

## Purely visual aggregate. Instance count is capped, never one per soldier.
const MAX_FIGURES := 256
const LIVE_UNIT_IDS := ["levy", "line_infantry", "skirmisher", "cavalry", "siege_engineer", "field_artillery", "rifle_infantry", "machine_gun_company", "motorized_infantry"]
const HISTORICAL_IDS := ["slinger", "javelin_skirmisher", "crossbow_infantry", "chariot_archer", "horse_archer", "camel_cavalry"]
const CLASSICAL_IDS := ["pike_phalanx", "legionary_infantry", "war_elephant", "battering_ram", "siege_tower"]
const MEDIEVAL_IDS := ["armored_foot", "pavise_crossbowman", "longbowman", "counterweight_trebuchet", "hand_cannon_team", "bombard"]
const UNIT_IDS := LIVE_UNIT_IDS + HISTORICAL_IDS + CLASSICAL_IDS + MEDIEVAL_IDS
const RANK_ORDER := ["field_artillery", "siege_engineer", "machine_gun_company", "skirmisher", "slinger", "crossbow_infantry", "javelin_skirmisher", "levy", "line_infantry", "legionary_infantry", "pike_phalanx", "rifle_infantry", "cavalry", "horse_archer", "camel_cavalry", "chariot_archer", "motorized_infantry", "war_elephant", "battering_ram", "siege_tower", "longbowman", "pavise_crossbowman", "hand_cannon_team", "armored_foot", "bombard", "counterweight_trebuchet"]
const SHADER := preload("res://assets/models/basic_units/crowds/crowd_animation.gdshader")
static var shared_assets: Dictionary = {}
var batches: Dictionary = {}
var materials: Array[ShaderMaterial] = []
var figure_count := 0
var represented_troops := 0
var signature := ""
var clip := "idle"
var clock := 0.0
var animation_speed := 1.0
var figure_limit := MAX_FIGURES

static func figure_budget(troops: int) -> int:
	if troops <= 0: return 0
	# More ranks, not bigger people. 100 -> 16, 1K -> 40, 10K -> 100.
	return mini(troops, clampi(roundi(16.0 * pow(float(troops) / 100.0, 0.4)), 1, MAX_FIGURES))

static func composition(army: Dictionary) -> Dictionary:
	var counts := {}
	for id in UNIT_IDS: counts[id] = 0
	counts.merge(UnitVisualCatalog.counts(army), true)
	return counts

static func _asset(id: String) -> Dictionary:
	if shared_assets.has(id): return shared_assets[id]
	var prefix := "res://assets/models/basic_units/crowds/" + id
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(prefix + ".json"))
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var uv := PackedVector2Array()
	var lookup := PackedVector2Array()
	for i in int(data.vertex_count):
		vertices.append(Vector3(data.positions[i*3], data.positions[i*3+1], data.positions[i*3+2]))
		normals.append(Vector3(data.normals[i*3], data.normals[i*3+1], data.normals[i*3+2]))
		colors.append(Color(data.colors[i*4], data.colors[i*4+1], data.colors[i*4+2]))
		uv.append(Vector2(float(data.team[i]), 0))
		lookup.append(Vector2((float(i % int(data.width)) + 0.5) / float(data.width), floorf(float(i) / float(data.width)) + 0.5))
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_TEX_UV] = uv
	arrays[Mesh.ARRAY_TEX_UV2] = lookup
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	# Includes the released arrow and the full backwards collapse.
	mesh.custom_aabb = AABB(Vector3(-20, -3, -20), Vector3(40, 22, 40))
	var result := {"mesh": mesh, "positions": load(prefix + "_positions.exr"), "normals": load(prefix + "_normals.exr"), "data": data}
	shared_assets[id] = result
	return result

func configure(counts: Dictionary, faction: Color, spacing: float = 1.25) -> void:
	var total := 0
	for id in UNIT_IDS: total += maxi(0, int(counts.get(id, 0)))
	represented_troops = total
	var desired := mini(figure_budget(total), clampi(figure_limit,1,MAX_FIGURES))
	var key := "%s/%s/%s" % [counts, faction, spacing]
	if signature == key: return
	signature = key
	figure_count = desired
	for child: Node in batches.values():
		remove_child(child)
		child.queue_free()
	batches.clear(); materials.clear()
	if total == 0: return
	# Largest remainder allocation preserves composition and the exact visual budget.
	var allocations := {}
	var remainders: Array[Dictionary] = []
	var assigned := 0
	for id in UNIT_IDS:
		var exact := float(desired) * float(counts.get(id,0)) / float(total)
		allocations[id] = floori(exact); assigned += int(allocations[id])
		remainders.append({"id": id, "remainder": exact - floorf(exact)})
	remainders.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.remainder) > float(b.remainder))
	for i in desired-assigned: allocations[remainders[i].id] += 1
	var columns := maxi(1, ceili(sqrt(float(desired) * 1.6)))
	var rows := ceili(float(desired) / float(columns))
	var has_support := int(counts.get("cavalry",0))+int(counts.get("siege_engineer",0))+int(counts.get("field_artillery",0)) > 0
	var has_vehicle := int(counts.get("motorized_infantry",0))>0
	has_support = has_support or int(counts.get("horse_archer",0))+int(counts.get("camel_cavalry",0))>0
	has_vehicle = has_vehicle or int(counts.get("chariot_archer",0))>0
	var rank_spacing := maxf(spacing,5.0) if has_vehicle else (maxf(spacing,3.2) if has_support else spacing)
	for id in CLASSICAL_IDS:
		if id != "legionary_infantry" and int(counts.get(id,0)) > 0:
			rank_spacing = maxf(rank_spacing,6.0)
	if int(counts.get("bombard",0)) > 0: rank_spacing = maxf(rank_spacing,4.0)
	if int(counts.get("counterweight_trebuchet",0)) > 0: rank_spacing = maxf(rank_spacing,9.0)
	var slot := 0
	for id in RANK_ORDER:
		var amount := int(allocations[id])
		if amount == 0: continue
		var asset := _asset(id)
		var material := ShaderMaterial.new()
		material.shader = SHADER
		material.set_shader_parameter("position_frames", asset.positions)
		material.set_shader_parameter("normal_frames", asset.normals)
		material.set_shader_parameter("texture_height", float(asset.data.height))
		material.set_shader_parameter("rows_per_frame", float(asset.data.rows_per_frame))
		material.set_shader_parameter("faction_color", faction)
		material.set_shader_parameter("death_frame_start", float(asset.data.clips.death.start))
		material.set_shader_parameter("death_frame_count", float(asset.data.clips.death.count))
		var multimesh := MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.use_custom_data = true
		multimesh.use_colors = true
		multimesh.mesh = asset.mesh
		multimesh.instance_count = amount
		for i in amount:
			var x := (float(slot % columns) - float(columns-1)*0.5)*rank_spacing
			var z := (float(slot / columns) - float(rows-1)*0.5)*rank_spacing
			multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY, Vector3(x,0,z)))
			multimesh.set_instance_color(i, Color.WHITE)
			multimesh.set_instance_custom_data(i, Color(float(slot % 13)/13.0,0,0,1))
			slot += 1
		var batch := MultiMeshInstance3D.new()
		batch.name = id
		batch.multimesh = multimesh
		batch.material_override = material
		add_child(batch)
		batches[id] = batch; materials.append(material)
	_set_clip_parameters()

func set_animation(value: String, restart: bool = false) -> void:
	if not value in ["idle", "walk", "attack", "death"]: value = "idle"
	if clip == value and not restart: return
	clip = value; clock = 0
	_set_clip_parameters()

func _set_clip_parameters() -> void:
	for id in batches:
		var material := (batches[id] as MultiMeshInstance3D).material_override as ShaderMaterial
		var definition: Dictionary = _asset(id).data.clips[clip]
		material.set_shader_parameter("frame_start", float(definition.start))
		material.set_shader_parameter("frame_count", float(definition.count))
		material.set_shader_parameter("clip_duration", float(definition.duration))
		material.set_shader_parameter("looping", bool(definition.loop))
		material.set_shader_parameter("animation_clock", clock)

func _process(delta: float) -> void:
	if not is_visible_in_tree(): return
	clock += delta * animation_speed
	for material in materials: material.set_shader_parameter("animation_clock", clock)

func fit_to_ground(height_at: Callable) -> void:
	# Called only after layout, movement, or orientation changes, not per frame.
	for batch: MultiMeshInstance3D in batches.values():
		for i in batch.multimesh.instance_count:
			var transform := batch.multimesh.get_instance_transform(i)
			var world := to_global(transform.origin)
			world.y = float(height_at.call(world.x, world.z)) + 0.0001
			transform.origin = to_local(world)
			batch.multimesh.set_instance_transform(i, transform)
