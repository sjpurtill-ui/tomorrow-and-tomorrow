extends "res://tests/home_lives_journey_probe.gd"
## Native actual-HUD acceptance, never a player launch or prepared-provider swap.
## Run only through tools/run_isolated_gpu_probe.ps1 with isolated Test userdata.
## Required args: --out=<absolute artifact directory> --mode=dark|light
## Optional: --case=early|mature --prefix=<filename prefix>
## The fixture runs real food rules before auditing. Reading/refresh/navigation
## must then leave all audited ledgers, RNG state and scoped bindings unchanged.
const FoodPanel = preload("res://scripts/hud/food_folio.gd")
const Sheet = preload("res://scripts/hud/econ_sheet.gd")
const SOURCE_NODES := {"Wild gathering":"Gathering", "Hunting":"Hunting", "Fishing":"Fishing", "Cultivation":"Cultivation"}
var output_directory := ""
var _captures := 0

func _ready() -> void:
	case_name = "early"
	capture_prefix = "food-pantry"
	if not "Test" in OS.get_user_data_dir():
		push_error("Food pantry acceptance requires isolated Test userdata")
		get_tree().quit(2)
		return
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--case="): case_name = argument.trim_prefix("--case=")
		elif argument.begins_with("--mode="): mode = argument.trim_prefix("--mode=")
		elif argument.begins_with("--prefix="): capture_prefix = argument.trim_prefix("--prefix=")
		elif argument.begins_with("--out="): output_directory = argument.trim_prefix("--out=").replace("\\", "/")
	if not output_directory.is_absolute_path() or not mode in ["dark", "light"] or not case_name in ["early", "mature"]:
		push_error("Supply --out=<absolute directory>, --mode=dark|light and --case=early|mature")
		get_tree().quit(2)
		return
	get_tree().create_timer(240.0).timeout.connect(func(): get_tree().quit(3))
	var config := ConfigFile.new()
	config.set_value("display", "visual_system", 1)
	config.set_value("display", "color_theme", mode)
	config.save("user://display.cfg")
	_world("late" if case_name == "mature" else "early")
	GameState.civic_api_enabled = false
	GameState.select_founding_focus("provision")
	PeopleDirection.choose("makers")
	DiscoverySystem.initialize()
	get_window().size = Vector2i(1600, 1000)
	get_window().content_scale_size = Vector2i(1600, 1000)
	audit_terrain = load("res://local_terrain.tscn").instantiate()
	audit_terrain.set("suppress_naming_prompt", true)
	add_child(audit_terrain)
	await _frames(50)
	audit_terrain.call("_set_game_speed", 0)
	for system_name: String in WorldSimulation.OWNED_SYSTEMS:
		var system: Node = WorldSimulation.system(system_name)
		system.set_process(false)
	for director: Node in get_tree().get_nodes_in_group("court_director"): director.set_process(false)
	if is_instance_valid(PeopleDirection.panel): PeopleDirection.panel.queue_free()
	if is_instance_valid(audit_terrain.get("settlement_naming_panel")): audit_terrain.get("settlement_naming_panel").queue_free()
	await _frames(10)
	# This explicit fixture step produces the displayed source/stock/forecast
	# receipts through FoodSystem; no numbers are injected into the provider.
	_sample_actual_food_day()
	var hud: Control = audit_terrain.get("hud")
	var provider: Object = hud.providers.economy
	_expect(provider.get_script().resource_path == "res://scripts/hud/content/dock_content_economy.gd", "Uses the actual Economy provider")
	# Allow established lazy readers to prepare their caches before the ledger
	# check. Neither this tab read nor any test callback applies an assignment.
	provider.tab(0)
	var before := _ledger()
	hud.section_requested.emit("economy", 0)
	hud.force_dock_layout()
	await _frames(16)
	var board: Control = hud.dock.find_child("ProvisionsLedger", true, false)
	_expect(board != null, "Actual Economy Food tab creates the pantry")
	if board == null: get_tree().quit(1); return
	_expect(board.get_script() == FoodPanel, "Active renderer is food_folio.gd")
	_expect(_ledger() == before, "Opening pantry preserves ledgers, RNG and scope bindings")
	var first_id := board.get_instance_id()
	var first_count := board.find_children("*", "", true, false).size()
	var source_ids := _source_ids(board)
	_check_receipts(board)
	await _check_same_day_stock_refresh(hud, provider, board)
	before = _ledger()
	for canvas: Vector2i in [Vector2i(1600,1000), Vector2i(1024,720), Vector2i(2869,1337)]:
		get_window().size = canvas
		get_window().content_scale_size = canvas
		hud.force_dock_layout()
		await _frames(14)
		hud.dock.body_scroll.scroll_vertical = 0
		await _frames(4)
		_check_layout(board, str(canvas.x))
		_expect(_ledger() == before, "Resize and painting remain read-only at " + str(canvas.x))
		await _capture("overview-" + str(canvas.x))
		var details: Button = board.find_child("PantryDetails", true, false)
		_expect(details != null, "Exact pantry evidence is reachable")
		if details == null: continue
		hud.dock.body_scroll.ensure_control_visible(details)
		await _frames(3)
		await _click(details.get_global_rect().get_center())
		await _frames(5)
		_expect(bool(board._refs.details.visible), "Native click opens exact evidence at " + str(canvas.x))
		_expect(_ledger() == before, "Opening exact evidence does not change stores or assignments")
		_check_layout(board, str(canvas.x) + " details")
		hud.dock.body_scroll.scroll_vertical = 100000
		await _frames(3)
		await _capture("details-" + str(canvas.x))
		hud.dock.body_scroll.ensure_control_visible(details)
		await _frames(3)
		# Keyboard operates the same retained disclosure without a model action.
		details.grab_focus()
		await _key(KEY_SPACE)
		await _frames(3)
		_expect(not bool(board._refs.details.visible), "Keyboard closes exact evidence at " + str(canvas.x))
		_expect(_ledger() == before, "Keyboard disclosure remains read-only")
	# Generate a genuinely new receipt, then test the production refresh path.
	GameState.elapsed_days += 1
	_sample_actual_food_day()
	before = _ledger()
	hud.live_refresh_dock()
	await _frames(10)
	board = hud.dock.find_child("ProvisionsLedger", true, false)
	_expect(board != null and board.get_instance_id() == first_id, "Live receipt refresh retains the actual pantry node")
	if board == null: get_tree().quit(1); return
	_expect(_source_ids(board) == source_ids, "Live receipt refresh retains all four source annotations")
	_expect(board.find_children("*", "", true, false).size() <= first_count + 4, "Live updates do not append another set of pantry controls")
	_expect(_ledger() == before, "Refreshing a changed day performs no extra food step or RNG roll")
	_check_receipts(board)
	get_window().size = Vector2i(1024, 720)
	get_window().content_scale_size = Vector2i(1024, 720)
	hud.force_dock_layout()
	await _frames(12)
	hud.dock.body_scroll.scroll_vertical = 0
	await _frames(3)
	await _capture("live-update-1024")
	# Navigation follows existing callbacks. Opening the allocator must not
	# reallocate workers; the player still must use its explicit +/- actions.
	for target: Array in [["AssignFoodWorkers", "Food"], ["AssignWaterCarriers", "Logistics"]]:
		var button: Button = board.find_child(String(target[0]), true, false)
		_expect(button != null and button.is_visible_in_tree(), "Existing assignment route is visible: " + String(target[1]))
		if button == null: continue
		hud.dock.body_scroll.ensure_control_visible(button)
		await _frames(3)
		before = _ledger()
		await _click(button.get_global_rect().get_center())
		await _frames(16)
		var allocation: Control = hud.dock.find_child("CivilizationPeopleScreen", true, false)
		_expect(allocation != null, "Assignment route opens actual People allocator")
		if allocation != null:
			_expect(allocation.get_script().resource_path.ends_with("people_allocator_screen.gd"), "Assignment destination uses the active allocator")
			_expect(String(allocation.active_role) == String(target[1]), "Assignment destination focuses " + String(target[1]))
		_expect(_ledger() == before, "Opening " + String(target[1]) + " assignment does not issue a command")
		hud.section_requested.emit("economy", 0)
		hud.force_dock_layout()
		await _frames(12)
		board = hud.dock.find_child("ProvisionsLedger", true, false)
		_expect(board != null, "Food remains reachable after assignment navigation")
		if board == null: break
	print("FOOD_PANTRY_ACCEPTANCE ", checks, " checks; ", _captures, " captures; failures: ", failures)
	PlanetEnvironment.set_macro_bake_enabled(false)
	audit_terrain.queue_free()
	await _frames(2)
	get_tree().quit(0 if failures.is_empty() else 1)

func _sample_actual_food_day() -> void:
	var context: Dictionary = audit_terrain.call("_discovery_context")
	context["traveling"] = false
	SettlementModel.with_city_resources(GameState.selected_player_settlement_id, func() -> void:
		var efficiency := float(GameState.simulation_metrics.get("labor_efficiency", 1.0))
		var ecology := float(GameState.simulation_metrics.get("ecology", 0.8))
		var receipt: Dictionary = FoodSystem.process_day(context, efficiency, ecology)
		GameState.simulation_metrics.merge(receipt, true))

func _ledger() -> PackedByteArray:
	return var_to_bytes([super._ledger(), GameState.simulation_metrics, GameState.water_metrics,
		GameState.food_history, GameState.food_source_health, GameState.fire_practice,
		GameState.nutrition_reserve, GameState.malnutrition_burden,
		GameState.city_trade_shipments, GameState.city_trade_history])

func _source_ids(board: Control) -> Dictionary:
	var out: Dictionary = {}
	for source: String in SOURCE_NODES:
		var node := board.find_child("Source_" + String(SOURCE_NODES[source]), true, false)
		_expect(node != null, "Every food source has an annotation: " + source)
		if node != null: out[source] = node.get_instance_id()
	return out

func _check_receipts(board: Control) -> void:
	var actual: Dictionary = SettlementModel.with_city_resources(GameState.selected_player_settlement_id, func() -> Dictionary:
		return {"metrics":GameState.simulation_metrics.duplicate(true), "water":GameState.water_metrics.duplicate(true), "stocks":GameState.food_stocks.duplicate(true)})
	var shown: Dictionary = board.data
	var metrics: Dictionary = actual.metrics
	_expect((metrics.get("food_sources", []) as Array).size() == 4, "Real daily calculation reports all four sources")
	_expect(shown.get("sources", []) == metrics.get("food_sources", []), "Pantry sources come directly from the selected town's real receipt")
	_expect(shown.get("forecast90", {}) == metrics.get("food_forecast_90", {}), "Outlook is the actual food forecast")
	_expect(shown.get("water", {}) == actual.water, "Water is the selected town's recorded drinking state")
	for pair: Array in [["Produced","food_production"],["Eaten","food_eaten"],["Spoiled","food_spoilage"],["Net","food_net"]]:
		_expect(is_equal_approx(float(shown.flow[pair[0]]), float(metrics[pair[1]])), "Daily flow retains engine term " + String(pair[0]))
	for source: Dictionary in metrics.get("food_sources", []):
		var refs: Dictionary = board._refs.source_labels[String(source.name)]
		_expect(String(refs.value.text).begins_with(Sheet.n(float(source.produced)) + " "), "Visible output matches actual " + String(source.name) + " receipt")
	for row: Dictionary in shown.get("rows", []):
		_expect(is_equal_approx(float(row.stock), float(actual.stocks.get(String(row.name), 0))), "Stock is current " + String(row.name) + ", not an old receipt")
	var total := 0.0
	for amount: Variant in actual.stocks.values(): total += float(amount)
	var need := float(metrics.get("food_consumption", 0.0))
	_expect(need > 0 and is_equal_approx(float(shown.food_days), total / need), "Reserve cover uses current stock and measured daily need")
	_expect(board._refs.reserve_value.text == Sheet.n(float(shown.food_days)), "Reserve number follows actual days held")

func _check_same_day_stock_refresh(hud: Control, provider: Object, board: Control) -> void:
	var before := _ledger()
	var identity := board.get_instance_id()
	var original_sources := _source_ids(board)
	var original_day := float(GameState.elapsed_days)
	var original_signature: Array = provider.signature().duplicate(true)
	var original_flow: Dictionary = board.data.flow.duplicate(true)
	var original_forecast: Dictionary = board.data.forecast90.duplicate(true)
	var stocks: Dictionary = SettlementModel.with_city_resources(GameState.selected_player_settlement_id, func() -> Dictionary:
		return GameState.food_stocks.duplicate(true))
	var selected_stock := "Stored food" if float(stocks.get("Stored food", 0)) > 0 else "Fresh food"
	var withdrawal := minf(7.0, float(stocks.get(selected_stock, 0)) * 0.1)
	_expect(withdrawal > 0, "Real fixture contains reserves for the same-day withdrawal regression")
	if withdrawal <= 0: return
	SettlementModel.with_city_resources(GameState.selected_player_settlement_id, func() -> void:
		GameState.food_stocks[selected_stock] = float(GameState.food_stocks[selected_stock]) - withdrawal)
	var after_withdrawal := _ledger()
	_expect(float(GameState.elapsed_days) == original_day, "Withdrawal fixture does not advance the day")
	_expect(provider.signature() != original_signature, "Current-stock withdrawal invalidates same-day provider signature")
	hud.live_refresh_dock()
	await _frames(8)
	var current: Control = hud.dock.find_child("ProvisionsLedger", true, false)
	_expect(current != null and current.get_instance_id() == identity, "Same-day stock refresh retains pantry identity")
	if current != null:
		_expect(_source_ids(current) == original_sources, "Same-day stock refresh retains all source nodes")
		_expect(current.data.flow == original_flow, "Stock withdrawal does not rewrite the previous daily flow receipt")
		_expect(current.data.forecast90 == original_forecast, "Stock refresh retains the actual dated forecast receipt")
		_check_receipts(current)
	_expect(_ledger() == after_withdrawal, "Same-day refresh neither repeats the withdrawal nor changes ledgers")
	SettlementModel.with_city_resources(GameState.selected_player_settlement_id, func() -> void:
		GameState.food_stocks.clear()
		GameState.food_stocks.merge(stocks, true))
	_expect(_ledger() == before, "Same-day withdrawal fixture restores every audited state value")
	_expect(provider.signature() == original_signature, "Restored reserves restore the provider signature")
	hud.live_refresh_dock()
	await _frames(6)
	_expect(_ledger() == before, "Refreshing restored reserves stays read-only")

func _check_layout(board: Control, label: String) -> void:
	var bounds := board.get_global_rect()
	var viewport := get_viewport().get_visible_rect()
	_expect(board.get_combined_minimum_size().x <= board.size.x + 1, "No minimum-width overflow at " + label)
	_expect(bounds.position.x >= -1 and bounds.end.x <= viewport.end.x + 1, "Pantry fits viewport horizontally at " + label)
	for control: Control in board.find_children("*", "Control", true, false):
		if not control.is_visible_in_tree() or control.size.x < 1: continue
		var rect := control.get_global_rect()
		_expect(rect.position.x >= bounds.position.x - 2 and rect.end.x <= bounds.end.x + 2, "Visible child fits pantry: " + String(control.name) + " at " + label)
	var scene: Control = board.find_child("PantryPainting", true, false)
	_expect(scene != null and scene.size.x > 300 and scene.size.y >= 250, "Illustration remains substantial at " + label)
	if scene != null:
		for source: String in SOURCE_NODES:
			var node: Control = board.find_child("Source_" + String(SOURCE_NODES[source]), true, false)
			_expect(node != null and node.is_visible_in_tree(), "Source remains visible: " + source + " at " + label)
			if node != null: _expect(scene.get_global_rect().grow(2).encloses(node.get_global_rect()), "Source stays on illustration: " + source + " at " + label)

func _capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	var path := output_directory.path_join("%s-%s-%s-%s.png" % [capture_prefix, case_name, mode, label])
	DirAccess.make_dir_recursive_absolute(output_directory)
	var error := get_viewport().get_texture().get_image().save_png(path)
	_expect(error == OK, "Capture written: " + label)
	_captures += 1
	print("FOOD_PANTRY_CAPTURE ", path)
