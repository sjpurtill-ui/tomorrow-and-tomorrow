extends "res://tests/audience_modal_probe.gd"
## Private GPU presentation probe. The existing court_execution_clip and command
## tests cover adjudication; this probe deliberately calls the actual stage API.
## --tier=0|1 --fps=8. Images remain in RAM until both performances have ended.
const Backdrop := preload("res://scripts/hud/court_backdrop.gd")
const Executions := preload("res://scripts/hud/court_executions.gd")
const Fixture := preload("res://tests/court_eval/fixtures.gd")

var tier := 0
var fps := 8.0
var images: Array[Image] = []
var samples: Array[Dictionary] = []
var keyframes: Dictionary = {}
var report: Dictionary = {}
var director: Node

func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--tier="): tier = int(arg.trim_prefix("--tier="))
		if arg.begins_with("--fps="): fps = clampf(float(arg.trim_prefix("--fps=")), 1.0, 12.0)
	if DisplayServer.get_name() == "headless" or tier not in [0, 1]:
		_fail("requires a private GPU desktop and tier 0 or 1")
		get_tree().quit(1)
		return
	Backdrop.tier_override = tier
	Fixture.new(self).base(false)
	Executions.gore = "full" # In-process review setting; no preferences are saved.
	var terrain := TerrainDouble.new()
	add_child(terrain)
	director = Director.new()
	director.terrain = terrain
	add_child(director)
	director.voice.force_offline = true
	get_window().size = Vector2i(1280, 720)
	get_window().content_scale_size = Vector2i(1280, 720)
	await _frames(3)
	var modal: Control = await _open_court()
	if modal != null:
		report["natural"] = await _record(modal.court_stage, false)
		modal.queue_free()
		await _frames(3)
		modal = await _open_court()
		if modal != null:
			report["skip"] = await _record(modal.court_stage, true)
			modal.queue_free()
			await _frames(3)
	for mode: String in ["natural", "skip"]:
		if not (report.get(mode) is Dictionary) or (report.get(mode) as Dictionary).is_empty():
			_fail(mode + ": recording did not return a complete audit")
	_write_artifacts()
	print("COURT_DOGS_PREVIEW tier=", tier, " frames=", images.size(), " PASS" if failures.is_empty() else " FAIL")
	get_tree().quit(0 if failures.is_empty() else 1)

func _open_court() -> Control:
	var marshal: Dictionary = GovernmentPeopleSystem.officeholder("Marshal")
	var target: Dictionary = {"person_id": int(marshal.get("person_id", 0))}
	if marshal.is_empty():
		var choices: Array = Hall.summonable()
		if choices.is_empty():
			_fail("fixture has no summonable adult")
			return null
		target = choices[0].target
	var audience: Dictionary = Hall.summon(target)
	if audience.is_empty():
		_fail("could not summon fixture adult")
		return null
	var modal: Control = director.open_audience(String(audience.id))
	await _frames(8)
	modal.skip_reveal()
	modal.court_stage.settle()
	await get_tree().create_timer(0.8).timeout
	return modal

func _record(stage: Control, interrupt: bool) -> Dictionary:
	var mode := "skip" if interrupt else "natural"
	var result: Dictionary = {"mode": mode, "api": "stage.execute('dogs', 'main')", "adjudication": false}
	if not bool(stage.execute("dogs", "main")):
		_fail(mode + ": stage refused execution")
		return result
	var started := Time.get_ticks_usec()
	var next_frame := 0.0
	var max_contacts := 0
	var max_gap := 0.0
	var gap_samples := 0
	var saw_approach := false
	var saw_aftermath := false
	var max_tugs := 0
	var max_traces := 0
	var first_contact := -1.0
	var last_contact := -1.0
	var skipped := false
	var resident: Node3D
	var home := Transform3D.IDENTITY
	var pack: Array = []
	var helper_ref: Node
	var follow_ref: Tween
	var aftermath_ref: Tween
	var first_body := Vector3.ZERO
	var body_seen := false
	var max_body_travel := 0.0
	while float(Time.get_ticks_usec() - started) / 1000000.0 < 21.0:
		await get_tree().process_frame
		var seconds := float(Time.get_ticks_usec() - started) / 1000000.0
		if seconds < next_frame: continue
		await RenderingServer.frame_post_draw
		seconds = float(Time.get_ticks_usec() - started) / 1000000.0
		next_frame = maxf(next_frame + 1.0 / fps, seconds)
		var current: Node = stage.get_node_or_null("Execution")
		var row: Dictionary = {"mode": mode, "seconds": seconds, "execution": current != null, "done": bool(stage.exec_done), "dogs": []}
		var state := "ended"
		if current != null:
			var helper: Node = current.get_node_or_null("DogAttack")
			state = String(current.get_meta("dog_attack_state", "waiting"))
			if helper != null:
				helper_ref = helper
				state = String(helper.get_meta("attack_state", ""))
				var contacts := int(helper.get_meta("contact_count", 0))
				max_contacts = maxi(max_contacts, contacts)
				max_tugs = maxi(max_tugs, int(helper.get_meta("tug_samples", 0)))
				max_traces = maxi(max_traces, int(helper.get_meta("trace_count", 0)))
				row["contacts"] = contacts
				row["tugs"] = int(helper.get_meta("tug_samples", 0))
				row["traces"] = int(helper.get_meta("trace_count", 0))
				row["aftermath_seconds"] = float(helper.get_meta("aftermath_seconds", 0.0))
				saw_approach = saw_approach or state == "approach"
				saw_aftermath = saw_aftermath or state == "aftermath"
				if pack.is_empty():
					pack = (current.get("_pack") as Array).duplicate()
					resident = current.get("_court_dog") as Node3D
					home = current.get("_dog_home")
				follow_ref = current.get("_pack_follow") as Tween
				aftermath_ref = current.get("_pack_aftermath") as Tween
				var body: Node3D = helper.get("body") as Node3D
				if body != null:
					row["body"] = _xyz(body.global_position)
					if not body_seen: first_body = body.global_position; body_seen = true
					max_body_travel = maxf(max_body_travel, body.global_position.distance_to(first_body))
				for dog: Node3D in pack:
					if not is_instance_valid(dog): continue
					var contact := bool(dog.get_meta("execution_contact", false)) and state == "tug"
					var gap := float(dog.get_meta("execution_contact_gap", -1.0))
					var dog_row: Dictionary = {"name": String(dog.name), "contact": contact, "gap_m": gap, "position": _xyz(dog.global_position), "has_rendered_mouth": dog.has_meta("execution_mouth_world")}
					if dog.has_meta("execution_mouth_world"): dog_row["mouth"] = _xyz(dog.get_meta("execution_mouth_world"))
					if dog.has_meta("execution_bite_target"): dog_row["target"] = _xyz(dog.get_meta("execution_bite_target"))
					(row["dogs"] as Array).append(dog_row)
					if contact and gap >= 0.0:
						gap_samples += 1
						max_gap = maxf(max_gap, gap)
					if contact:
						if first_contact < 0.0: first_contact = seconds
						last_contact = seconds
		row["state"] = state
		var index := images.size()
		images.append(get_viewport().get_texture().get_image())
		samples.append(row)
		if not keyframes.has(mode + "_start"): keyframes[mode + "_start"] = index
		if int(row.get("contacts", 0)) == 3 and not keyframes.has(mode + "_contact"): keyframes[mode + "_contact"] = index
		if state == "tug" and seconds >= 7.3 and not keyframes.has(mode + "_drag"): keyframes[mode + "_drag"] = index
		if state == "aftermath" and not keyframes.has(mode + "_aftermath"): keyframes[mode + "_aftermath"] = index
		if interrupt and not skipped and max_contacts == 3 and seconds >= 4.8:
			keyframes["skip_before"] = index
			stage.skip_execution()
			skipped = true
		if bool(stage.exec_done):
			keyframes[mode + "_end"] = index
			break
	await _frames(3)
	await RenderingServer.frame_post_draw
	keyframes[mode + "_end"] = images.size()
	images.append(get_viewport().get_texture().get_image())
	samples.append({"mode": mode, "seconds": float(Time.get_ticks_usec() - started) / 1000000.0, "state": "after_cleanup", "done": bool(stage.exec_done), "dogs": []})
	var extras_remaining := 0
	for dog in pack:
		if is_instance_valid(dog) and dog != resident: extras_remaining += 1
	var resident_restored := is_instance_valid(resident) and bool(resident.get_meta("execution_restored", false))
	var home_error := resident.transform.origin.distance_to(home.origin) if is_instance_valid(resident) else -1.0
	var cleanup := stage.get_node_or_null("Execution") == null and not is_instance_valid(helper_ref) and extras_remaining == 0
	var tweens_stopped := (not is_instance_valid(follow_ref) or not follow_ref.is_valid()) and (not is_instance_valid(aftermath_ref) or not aftermath_ref.is_valid())
	result.merge({"elapsed_seconds": float(Time.get_ticks_usec() - started) / 1000000.0, "max_contacts": max_contacts, "max_rendered_contact_gap_m": max_gap, "rendered_contact_samples": gap_samples, "first_contact_seconds": first_contact, "last_contact_seconds": last_contact, "saw_approach": saw_approach, "saw_aftermath": saw_aftermath, "max_tug_samples": max_tugs, "max_trace_count": max_traces, "max_body_travel_m": max_body_travel, "skipped": skipped, "done": bool(stage.exec_done), "cleanup": cleanup, "resident_restored": resident_restored, "resident_home_error_m": home_error, "extras_remaining": extras_remaining, "tweens_stopped": tweens_stopped})
	if max_contacts != 3: _fail(mode + ": never observed all three dog contacts")
	if gap_samples == 0 or max_gap > 0.06: _fail(mode + ": rendered jaw contact missing or farther than 6 cm")
	if max_tugs == 0: _fail(mode + ": no tug samples")
	if not interrupt and not saw_aftermath: _fail("natural: no aftermath")
	if not interrupt and max_body_travel < 0.4: _fail("natural: victim did not visibly travel")
	if not bool(stage.exec_done) or not cleanup or not tweens_stopped: _fail(mode + ": execution did not fully clean up")
	if not resident_restored or home_error > 0.05: _fail(mode + ": resident dog was not restored")
	print("DOGS_", mode.to_upper(), " ", JSON.stringify(result))
	return result

func _xyz(value: Vector3) -> Array:
	return [value.x, value.y, value.z]

func _write_artifacts() -> void:
	var folder := ProjectSettings.globalize_path("res://artifacts/dog-execution/%d/" % tier)
	DirAccess.make_dir_recursive_absolute(folder)
	for label: String in keyframes:
		images[int(keyframes[label])].save_png(folder + label + ".png")
	for i in images.size():
		var error := images[i].save_png(folder + "frame_%04d.png" % i)
		if error != OK: _fail("could not encode frame %d" % i)
	report.merge({"tier": tier, "scope": "actual court renderer, direct stage API; no engine adjudication claim", "requested_fps": fps, "image_size": [1280, 720], "frame_count": images.size(), "buffered_before_encoding": true, "keyframes": keyframes, "samples": samples, "failures": failures, "passed": failures.is_empty()})
	var file := FileAccess.open(folder + "audit.json", FileAccess.WRITE)
	if file != null: file.store_string(JSON.stringify(report, "\t"))
	else: _fail("could not write audit.json")
