extends SceneTree

const FIGURES := preload("res://scripts/army_figure_formation.gd")
var failures: Array[String] = []

func _initialize() -> void: call_deferred("_verify")

func _verify() -> void:
	var previous := 0
	for amount in [0,1,10,100,1000,10000,100000,1000000,1000000000]:
		var budget: int = FIGURES.figure_budget(amount)
		if budget < previous or budget > FIGURES.MAX_FIGURES or budget > amount: failures.append("invalid budget " + str(amount))
		previous = budget
	var army := FIGURES.new(); root.add_child(army)
	var label := Label3D.new(); label.name = "Strength"; army.add_child(label)
	for amount in [100,10000,1000000000]:
		army.configure({"levy":amount/2,"line_infantry":amount/4,"skirmisher":amount/4},Color.CYAN)
		if army.get_node_or_null("Strength") != label: failures.append("rebuild destroyed label")
		var rendered := 0
		for batch: MultiMeshInstance3D in army.batches.values():
			rendered += batch.multimesh.instance_count
			# The headless dummy renderer does not retain instance-color buffers.
			if not batch.multimesh.use_colors or (DisplayServer.get_name() != "headless" and batch.multimesh.get_instance_color(0) != Color.WHITE):
				failures.append("instance tint darkens vertex materials")
		if rendered != FIGURES.figure_budget(amount): failures.append("composition lost figure budget")
		if army.get_child_count() != 4: failures.append("node count scales with personnel")
		var first: Node = army.batches.levy
		army.configure({"levy":amount/2,"line_infantry":amount/4,"skirmisher":amount/4},Color.CYAN)
		if army.batches.levy != first: failures.append("unchanged layout rebuilt")
	var mixed := {}
	for id in FIGURES.UNIT_IDS: mixed[id] = 1000
	army.configure(mixed,Color.CYAN)
	if army.batches.size() != FIGURES.UNIT_IDS.size() or army.figure_count != FIGURES.figure_budget(1000*FIGURES.UNIT_IDS.size()):
		failures.append("mixed army lost supported units or exceeded budget")
	var catalog = load("res://scripts/combat_simulator.gd")
	for id in FIGURES.LIVE_UNIT_IDS:
		if not catalog.UNIT_TYPES.has(id): failures.append("asset ID is not in the actual game roster: " + id)
	var historical: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/models/basic_units/historical_manifest.json"))
	var historical_ids: Array = []
	for unit: Dictionary in historical.units: historical_ids.append(unit.id)
	for id in FIGURES.HISTORICAL_IDS:
		if not id in historical_ids: failures.append("historical visual missing from manifest: " + id)
	var classical: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/models/basic_units/classical_manifest.json"))
	var classical_ids: Array = []
	for unit: Dictionary in classical.units:
		if unit.domain == "land": classical_ids.append(unit.id)
	for id in FIGURES.CLASSICAL_IDS:
		if not id in classical_ids: failures.append("classical land visual missing from manifest: " + id)
	if "trireme" in FIGURES.UNIT_IDS: failures.append("naval vessel was added to land crowds")
	var medieval: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/models/basic_units/medieval_manifest.json"))
	var medieval_ids: Array = []
	for unit: Dictionary in medieval.units: medieval_ids.append(unit.id)
	for id in FIGURES.MEDIEVAL_IDS:
		if not id in medieval_ids: failures.append("medieval visual missing from manifest: " + id)
	var known: Dictionary = FIGURES.composition({"formations":[{"unit":"cavalry","count":500},{"unit":"siege_engineer","count":200},{"unit":"field_artillery","count":100}]})
	if int(known.cavalry)+int(known.siege_engineer)+int(known.field_artillery) != 800:
		failures.append("map composition omits reinforcements")
	for id in FIGURES.UNIT_IDS:
		var asset: Dictionary = FIGURES._asset(id)
		var data: Dictionary = asset.data
		var texture := asset.positions as Texture2D
		var image := texture.get_image()
		for index in [0,100,1000]:
			var pixel := image.get_pixel(index % 128, index/128)
			var expected := Vector3(data.positions[index*3],data.positions[index*3+1],data.positions[index*3+2])
			if Vector3(pixel.r,pixel.g,pixel.b).distance_to(expected) > 0.004:
				failures.append(id + " GPU texture differs from base mesh: axis/row/precision error")
		for clip in ["idle","walk","attack","death"]:
			army.set_animation(clip,true)
			if int(data.clips[clip].count) < 2: failures.append(id + " missing baked motion")
	army.free()
	if failures.is_empty(): print("ARMY_FIGURES_VERIFIED budgets, composition, cache, texture coordinates, all clips; 1B capped at 256 figures")
	else:
		for failure in failures: push_error(failure)
	quit(0 if failures.is_empty() else 1)
