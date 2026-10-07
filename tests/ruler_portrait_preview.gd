extends Node
## Read-only copied-save capture of the real foreign audience card.
## Private GPU runner only; --prefix=before|after and optional --save=<copy>.
const Court := preload("res://scripts/hud/audience_modal.gd")
const Stage := preload("res://scripts/hud/court_stage.gd")
const Studio := preload("res://scripts/hud/court_figure_studio.gd")
const Rivals := preload("res://scripts/rival_rulers.gd")

class Snapshot extends "res://scripts/save_system.gd":
	var source := ""
	func slot_path(_slot: String) -> String: return source

var failures: Array[String] = []

func _ready() -> void: call_deferred("_run")

func _arg(key: String, fallback: String) -> String:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--" + key + "="): return arg.substr(key.length() + 3)
	return fallback

func _frames(count: int) -> void:
	for i in count: await get_tree().process_frame

func _run() -> void:
	if DisplayServer.get_name() == "headless" or not ProjectSettings.globalize_path("user://").contains("TomorrowPeopleGrownLandQA"):
		push_error("Ruler portrait probe requires private QA userdata and GPU runner")
		get_tree().quit(2)
		return
	print("RULER_PORTRAIT_SOURCE_LOADED")
	var snapshot := Snapshot.new()
	add_child(snapshot)
	snapshot.source = _arg("save", "res://artifacts/ruler-portrait/source.save")
	var loaded: Dictionary = snapshot.load_game("copy")
	if loaded.has("error"):
		push_error(str(loaded))
		get_tree().quit(1)
		return
	for node: Node in get_tree().root.get_children():
		if node != self:
			node.set_process(false)
			node.set_physics_process(false)
	GameState.civic_api_enabled = false
	preload("res://scripts/ai_mode.gd").reset_for_tests("user://__ruler_portrait_missing.cfg")
	preload("res://scripts/ai_mode.gd").set_records_interactions(false, false)
	var civ_id := ""
	var wanted := _arg("ruler", "Zerudajin Chujobat")
	for id: String in ForeignDiplomacy.leaders:
		if String((ForeignDiplomacy.leaders[id] as Dictionary).get("name", "")) == wanted:
			civ_id = id
			break
	if civ_id.is_empty():
		push_error("Copied save does not contain current ruler " + wanted)
		get_tree().quit(1)
		return
	var prefix := _arg("prefix", "before")
	var folder := ProjectSettings.globalize_path("res://artifacts/ruler-portrait/")
	DirAccess.make_dir_recursive_absolute(folder)
	var report: Dictionary = {"source": snapshot.source, "world_seed": GameState.world_seed, "elapsed_days": GameState.elapsed_days, "civ_id": civ_id, "civ_name": ForeignDiplomacy.civilization(civ_id).get("name", ""), "ruler_name": wanted, "ruler_character": Rivals.rival_character(civ_id), "captures": []}
	for dimensions: Vector2i in [Vector2i(1600, 900), Vector2i(1280, 720)]:
		get_window().size = dimensions
		get_window().content_scale_size = dimensions
		await _frames(3)
		var court: Control = Court.new()
		add_child(court)
		await _frames(2)
		if not bool(court.show_foreign(civ_id)):
			failures.append("foreign card refused ruler")
			break
		await _frames(6)
		var deadline := Time.get_ticks_msec() + 12000
		while is_instance_valid(Studio._instance) and (Studio._instance.busy or not Studio._instance.queue.is_empty()) and Time.get_ticks_msec() < deadline:
			await get_tree().process_frame
		await _frames(3)
		await RenderingServer.frame_post_draw
		var picture: TextureRect = court.speaker_frame.find_child("Portrait", true, false) as TextureRect
		if picture == null or picture.texture == null:
			failures.append("ruler picture missing")
			court.queue_free()
			continue
		var image: Image = get_viewport().get_texture().get_image()
		var rect: Rect2 = picture.get_global_rect()
		var crop := Rect2i(Vector2i(rect.position), Vector2i(rect.size))
		var stem := "%s-%dx%d" % [prefix, dimensions.x, dimensions.y]
		image.save_png(folder + stem + ".png")
		image.get_region(crop).save_png(folder + stem + "-portrait.png")
		picture.texture.get_image().save_png(folder + stem + "-texture.png")
		var person: Dictionary = court._foreign_leader_person(civ_id, ForeignDiplomacy.leader(civ_id))
		var look: Dictionary = Stage.figure_look(person, court.scene_portraits)
		var row: Dictionary = {"stem": stem, "window": [dimensions.x, dimensions.y], "display_rect": [rect.position.x, rect.position.y, rect.size.x, rect.size.y], "texture_size": [picture.texture.get_width(), picture.texture.get_height()], "texture_filter": picture.texture_filter, "person": person, "look": look, "figure_slot": picture.get_meta("figure_slot", []), "studio_pending": is_instance_valid(Studio._instance) and (Studio._instance.busy or not Studio._instance.queue.is_empty())}
		(report["captures"] as Array).append(row)
		if bool(row.studio_pending): failures.append("studio did not finish")
		print("RULER_PORTRAIT_CAPTURE ", JSON.stringify(row))
		court.queue_free()
		await _frames(3)
	if "--spotchecks" in OS.get_cmdline_user_args():
		report["technical_specimens"] = await _spotchecks(folder, prefix, civ_id)
	report["failures"] = failures
	report["passed"] = failures.is_empty()
	var file := FileAccess.open(folder + prefix + ".json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	print("RULER_PORTRAIT_PREVIEW ", "PASS" if failures.is_empty() else "FAIL")
	get_tree().quit(0 if failures.is_empty() else 1)

func _spotchecks(folder: String, prefix: String, civ_id: String) -> Array:
	# Deliberately labelled, in-memory appearance specimens; restore the exact
	# diplomatic record afterward. These are not campaign-history evidence.
	var original: Dictionary = (ForeignDiplomacy.leaders[civ_id] as Dictionary).duplicate(true)
	var rows: Array = []
	get_window().size = Vector2i(1600, 900)
	get_window().content_scale_size = Vector2i(1600, 900)
	await _frames(3)
	for specimen: Dictionary in [{"tag": "old-male-seated", "age": 75, "woman": false}, {"tag": "young-female", "age": 19, "woman": true}]:
		var leader := original.duplicate(true)
		leader.character.woman = specimen.woman
		leader.character.born = int(GameState.elapsed_days) - int(specimen.age) * 365
		var court: Control = Court.new()
		add_child(court)
		await _frames(2)
		var look: Dictionary = {}
		for index in 64:
			leader.name = "Technical portrait specimen %s %d" % [specimen.tag, index]
			look = Stage.figure_look(court._foreign_leader_person(civ_id, leader), {})
			if bool(specimen.woman) or String(look.get("stance", "")) == "sit": break
		ForeignDiplomacy.leaders[civ_id] = leader
		court.show_foreign(civ_id)
		await _frames(6)
		var deadline := Time.get_ticks_msec() + 12000
		while is_instance_valid(Studio._instance) and (Studio._instance.busy or not Studio._instance.queue.is_empty()) and Time.get_ticks_msec() < deadline:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var picture: TextureRect = court.speaker_frame.find_child("Portrait", true, false) as TextureRect
		var rect: Rect2 = picture.get_global_rect()
		var image: Image = get_viewport().get_texture().get_image()
		var stem := prefix + "-specimen-" + String(specimen.tag)
		image.get_region(Rect2i(Vector2i(rect.position), Vector2i(rect.size))).save_png(folder + stem + ".png")
		rows.append({"stem": stem, "evidence": "technical appearance specimen, not saved ruler", "look": look, "texture_size": [picture.texture.get_width(), picture.texture.get_height()], "display_size": [rect.size.x, rect.size.y]})
		court.queue_free()
		await _frames(3)
	ForeignDiplomacy.leaders[civ_id] = original
	return rows
