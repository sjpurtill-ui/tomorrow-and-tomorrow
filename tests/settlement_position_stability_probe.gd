extends "res://tests/people_grown_land_capture.gd"
## Read-only save copy; controlled presentation snapshots never advance time.
## --position-stability [--metadata-only | --after-only]
## Default comparison needs ignored baseline/settlement_country_{plan,visual}.gd
## exported with git show a83a0a7f:scripts/<filename>. Rewrite only the baseline
## visual's PLAN preload to its sibling under artifacts/settlement-position-stability.
## --after-only explicitly omits historical comparison; current checks still apply.
const STABILITY_OUTPUT := "res://artifacts/settlement-position-stability/controlled-replay.json"
const STABILITY_BASELINE := "res://artifacts/settlement-position-stability/baseline/"

func _run() -> void:
	if "--position-stability" not in OS.get_cmdline_user_args() or not ProjectSettings.globalize_path("user://").contains("TomorrowPeopleGrownLandQA"):
		_setup_error("Requires --position-stability and private TomorrowPeopleGrownLandQA userdata."); return
	var versions: Array[String] = ["after"] if "--after-only" in OS.get_cmdline_user_args() else ["before", "after"]
	if "--metadata-only" not in OS.get_cmdline_user_args() and "before" in versions:
		for filename: String in ["settlement_country_plan.gd", "settlement_country_visual.gd"]:
			if not FileAccess.file_exists(STABILITY_BASELINE + filename):
				_setup_error("Missing baseline file: " + STABILITY_BASELINE + filename + ". Export both country scripts from git revision a83a0a7f and rewrite the baseline visual's PLAN preload to its sibling; or pass --after-only."); return
	var source := _arg("save", "res://artifacts/settlement-position-stability/current.save")
	if not FileAccess.file_exists(source):
		_setup_error("Missing isolated save copy: " + source); return
	var saves := Snapshot.new(); saves.source = source; add_child(saves)
	var payload: Dictionary = saves._read_payload("copy")
	if payload.is_empty(): _setup_error("Could not read copied save: " + source); return
	var state: Dictionary = payload.get("reflected_GameState", {})
	var world: Dictionary = payload.get("curated_WorldSimulation", {})
	var plots: Array = state.get("settlement_plots", [])
	var saved_sites := 0
	var forms: Dictionary = {}
	for plot: Dictionary in plots:
		saved_sites += (plot.get("visual_building_sites", []) as Array).size()
		var form := String(plot.get("form", "")); forms[form] = int(forms.get(form, 0)) + 1
	report = {"source": source, "source_sha256": FileAccess.get_sha256(source), "metadata": payload.get("metadata", {}), "population_exact": state.get("population_exact", 0), "plots": plots.size(), "routes": (state.get("settlement_routes", []) as Array).size(), "saved_building_sites": saved_sites, "forms": forms, "morphology_revision": state.get("morphology_revision", 0), "last_morphology_day": state.get("last_morphology_day", -1), "origin": str(state.get("settlement_founded_at", Vector3.ZERO)), "player_settlements": (state.get("player_settlements", []) as Array).size(), "world_enabled": world.get("enabled", false), "world_keys": world.keys()}
	_write("res://artifacts/settlement-position-stability/save-metadata.json", report)
	print("POSITION_STABILITY_METADATA ", JSON.stringify(report))
	if "--metadata-only" in OS.get_cmdline_user_args(): get_tree().quit(0); return
	payload.clear()
	for node in get_tree().root.get_children():
		if node != self: node.set_process(false); node.set_physics_process(false)
	var restored: Dictionary = saves.load_game("copy")
	if restored.has("error"): _setup_error(str(restored)); return
	GameState.civic_api_enabled = false
	terrain = load("res://local_terrain.tscn").instantiate(); add_child(terrain)
	terrain._set_game_speed(0); terrain.set_process(false); terrain.set_physics_process(false)
	for node in get_tree().root.get_children():
		if node != self: node.set_process(false); node.set_physics_process(false)
	print("POSITION_STABILITY_SOURCE_LOADED")
	var actual_population := float(GameState.population_exact)
	var actual_day := float(GameState.elapsed_days)
	var results: Array = []
	for version: String in versions:
		results.append(_controlled_replay(version))
		await get_tree().process_frame
	report["scope"] = "Controlled visual-snapshot population replay using the real save's root geometry, crafts and physical terrain; no simulated days or population ledger edits"
	report["fixed_camera_target"] = str(GameState.settlement_founded_at)
	report["replays"] = results
	report["baseline_included"] = "before" in versions
	report["population_unchanged"] = GameState.population_exact == actual_population
	report["day_unchanged"] = GameState.elapsed_days == actual_day
	report["checks"] = _comparison_checks(results)
	report.checks["population_unchanged"] = report.population_unchanged
	report.checks["day_unchanged"] = report.day_unchanged
	var failures: Array[String] = []
	for check: String in report.checks:
		if not bool(report.checks[check]): failures.append(check)
	report["failures"] = failures
	report["passed"] = failures.is_empty()
	_write(STABILITY_OUTPUT, report)
	print("POSITION_STABILITY_REPLAY_DONE ", JSON.stringify({"passed": report.passed, "checks": report.checks, "failures": failures}))
	if not failures.is_empty(): push_error("Position stability checks failed: " + ", ".join(failures))
	terrain.queue_free(); await get_tree().process_frame
	get_tree().quit(0 if failures.is_empty() else 1)

func _setup_error(message: String) -> void:
	report = {"passed": false, "checks": {"inputs_ready": false}, "failures": [message]}
	_write(STABILITY_OUTPUT, report)
	push_error(message)
	get_tree().quit(2)

func _comparison_checks(results: Array) -> Dictionary:
	var checks: Dictionary = {"after_present": false, "selected_patch_jobs_complete": true, "all_steps_ledger_unchanged": true}
	var after_rows: Dictionary = {}
	for replay: Dictionary in results:
		if replay.has("error"): checks["selected_patch_jobs_complete"] = false
		for row: Dictionary in replay.get("rows", []):
			checks["selected_patch_jobs_complete"] = bool(checks.selected_patch_jobs_complete) and int(row.pending) == 0 and bool(row.job_empty) and bool(row.target_installed)
			checks["all_steps_ledger_unchanged"] = bool(checks.all_steps_ledger_unchanged) and bool(row.ledger_unchanged)
			if String(replay.version) == "after": after_rows[String(row.label)] = row
	checks["after_present"] = after_rows.size() == 4
	for label: String in ["grow", "dip", "return"]:
		var row: Dictionary = after_rows.get(label, {})
		checks["after_" + label + "_visible"] = bool(row.get("desired", false)) and bool(row.get("visible", false))
		checks["after_" + label + "_history_retained"] = bool(row.get("history_retained", false))
		checks["after_" + label + "_roofs_nonempty"] = int(row.get("roof_count", 0)) > 0
	var grown_roofs: Dictionary = (after_rows.get("grow", {}) as Dictionary).get("roofs", {})
	for label: String in ["dip", "return"]:
		var roofs: Dictionary = (after_rows.get(label, {}) as Dictionary).get("roofs", {})
		checks["after_grow_to_" + label + "_exact"] = not grown_roofs.is_empty() and grown_roofs == roofs
	return checks

func _controlled_replay(version: String) -> Dictionary:
	var plan_script: Script = load(STABILITY_BASELINE + "settlement_country_plan.gd" if version == "before" else "res://scripts/settlement_country_plan.gd")
	var visual_script: Script = load(STABILITY_BASELINE + "settlement_country_visual.gd" if version == "before" else "res://scripts/settlement_country_visual.gd")
	if plan_script == null or visual_script == null or not plan_script.can_instantiate() or not visual_script.can_instantiate():
		return {"version": version, "error": "Country replay scripts failed to load or compile", "rows": []}
	var visual: Node3D = visual_script.new(); add_child(visual)
	visual.call("configure", func(point: Vector2) -> float: return terrain._height_at(point.x, point.y), func(point: Vector2) -> bool: return terrain._settlement_stage_land_at(point))
	visual.set("view_center", Vector2(GameState.settlement_founded_at.x, GameState.settlement_founded_at.z))
	var snapshot: Dictionary = plan_script.call("capture_current")
	var saved_population := float(snapshot.population)
	var ledger_population := float(GameState.population_exact)
	var ledger_day := float(GameState.elapsed_days)
	var seed_id := "seed:player:%d:9" % GameState.world_seed
	var patch_id := "homesteads:" + seed_id
	var rows: Array = []
	var first_roofs: Dictionary = {}
	var seed_center := Vector2.ZERO
	var began := Time.get_ticks_msec()
	for step: Dictionary in [{"label": "saved", "population": saved_population}, {"label": "grow", "population": 11500.0}, {"label": "dip", "population": saved_population}, {"label": "return", "population": 11500.0}]:
		snapshot.population = step.population
		visual.call("request", snapshot)
		for record: Dictionary in (visual.get("plan") as Dictionary).get("homesteads", []):
			if String(record.get("id", "")) == seed_id: seed_center = record.position
		var retained: RefCounted = visual.get("retained")
		var desired: bool = retained.desired.has(patch_id)
		var excluded_jobs: int = retained.pending.size() - (1 if retained.pending.has(patch_id) else 0)
		if desired:
			retained.pending.assign([patch_id])
			var deadline := Time.get_ticks_msec() + 25000
			while (not retained.pending.is_empty() or not (visual.get("_job") as Dictionary).is_empty()) and Time.get_ticks_msec() < deadline:
				visual.call("process_jobs", 50000, 1)
		else: retained.pending.clear()
		var roofs: Dictionary = {}
		var shown := false
		if retained.installed.has(patch_id):
			var node: Node3D = retained.installed[patch_id].node
			shown = node.visible
			roofs = _roof_snapshot(node.get_meta("country_seed_plan", {}), seed_center)
		if String(step.label) == "grow": first_roofs = roofs.duplicate(true)
		var movement := _roof_changes(first_roofs, roofs) if String(step.label) in ["dip", "return"] else {}
		var history: Dictionary = (visual.get("_growth_states") as Dictionary).get(seed_id, {})
		var row: Dictionary = {"label": step.label, "population": step.population, "desired": desired, "visible": shown, "history_retained": not history.is_empty(), "saved_claims": (history.get("plots", []) as Array).size(), "active_seed_ids": _active_seeds(visual.get("plan")), "roof_count": roofs.size(), "roofs": roofs, "return_changes": movement if String(step.label) == "return" else {}, "changes_from_grow": movement, "pending": retained.pending.size(), "job_empty": (visual.get("_job") as Dictionary).is_empty(), "target_installed": not desired or retained.installed.has(patch_id), "excluded_non_target_jobs": excluded_jobs, "ledger_unchanged": GameState.population_exact == ledger_population and GameState.elapsed_days == ledger_day}
		rows.append(row)
		print("POSITION_STABILITY_CASE ", version, " ", JSON.stringify({"label": row.label, "population": row.population, "desired": desired, "visible": shown, "history_retained": row.history_retained, "roof_count": roofs.size(), "return_changes": movement, "pending": row.pending}))
	var result: Dictionary = {"version": version, "seed_id": seed_id, "physical_terrain": true, "milliseconds": Time.get_ticks_msec() - began, "renderer_sha256": FileAccess.get_sha256(visual_script.resource_path), "rows": rows}
	visual.free()
	return result

func _active_seeds(plan: Dictionary) -> Array:
	var ids: Array = []
	for row: Dictionary in plan.get("homesteads", []):
		if row.has("settlement_growth"): ids.append(row.id)
	return ids

func _roof_snapshot(plan: Dictionary, center: Vector2) -> Dictionary:
	var result: Dictionary = {}
	for row: Dictionary in plan.get("buildings", []):
		var point: Vector2 = center + Vector2(row.position)
		result[String(row.id)] = {"local_position": row.position, "world_position": point, "height": terrain._height_at(point.x, point.y), "angle": row.angle, "footprint": row.footprint, "variant": row.get("variant", 0), "form": row.plot.get("form", "")}
	return result

func _roof_changes(before: Dictionary, after: Dictionary) -> Dictionary:
	var moved: Array = []; var removed: Array = []; var added: Array = []
	for id: String in before:
		if not after.has(id): removed.append(id)
		elif before[id] != after[id]: moved.append(id)
	for id: String in after:
		if not before.has(id): added.append(id)
	return {"changed_ids": moved, "removed_ids": removed, "added_ids": added}
