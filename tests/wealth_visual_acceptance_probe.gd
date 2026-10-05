extends Node
## Prepared in-memory economy records shown through the real economy dock.
## Use isolated userdata and the private-desktop runner. No campaign is loaded.
const T = preload("res://scripts/hud/hud_tokens.gd")
const Economy = preload("res://scripts/hud/content/dock_content_economy.gd")
const Purse = preload("res://scripts/realm_purse.gd")
const Goods = preload("res://scripts/civilian_goods.gd")
const Standing = preload("res://scripts/standing.gd")
const Business = preload("res://scripts/enterprise.gd")
const Words = preload("res://scripts/hud/era_words.gd")
const Artifacts = preload("res://scripts/artifact_collection.gd")
const ArtifactArt = preload("res://scripts/hud/artifact_visuals.gd")
const Exchange = preload("res://scripts/society_exchange.gd")
const Production = preload("res://scripts/hud/content/dock_content_production.gd")
const SEED := 551188

class WealthHud extends "res://scripts/hud/command_rail_hud.gd":
	func _make_court_button() -> Button:
		var button := super._make_court_button()
		# A Wealth-only fixture has no court. Cancel its unrelated delayed asset
		# warmup before mounting: the rail's 4-second timer would outlive a case.
		for connection in button.tree_entered.get_connections():
			button.tree_entered.disconnect(connection.callable)
		return button

	func _ready() -> void:
		name = "WealthAcceptanceHud"
		theme = Tokens.control_theme()
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		_build_frame()
		_build_rail()
		_build_time_pill()
		_build_kpi_strip()
		_build_dock()
		get_viewport().size_changed.connect(_layout)
		_layout()
		set_process(false)

var checks := 0
var failures: Array[String] = []
var report: Dictionary = {"seed": SEED, "cases": [], "checks": []}
var capture := false
var output := "res://artifacts/wealth-acceptance"
var hud: Control
var background: ColorRect
var label: Label
var last_destination: Array = []
var held_artifact: Dictionary = {}
var selected_case := ""

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	if not OS.get_cmdline_user_args().has("--wealth-acceptance"):
		printerr("Requires --wealth-acceptance and isolated userdata.")
		get_tree().quit(2)
		return
	if not bool(ProjectSettings.get_setting("application/config/use_custom_user_dir", false)) or not OS.get_user_data_dir().to_lower().contains("acceptance"):
		printerr("Use an ignored override.cfg with an acceptance-specific custom user directory.")
		get_tree().quit(2)
		return
	capture = OS.get_cmdline_user_args().has("--capture")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): output = arg.trim_prefix("--out=")
		if arg.begins_with("--case="): selected_case = arg.trim_prefix("--case=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	for node in get_tree().root.get_children():
		if node != self:
			node.set_process(false)
			node.set_physics_process(false)
	WorldSimulation.clear()
	preload("res://scripts/hud/motion.gd").reduce_motion = true
	background = ColorRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	label = Label.new()
	label.position = Vector2(1200, 95)
	label.add_theme_font_size_override("font_size", 16)
	add_child(label)
	var cases := [
		{"id": "opening-light", "state": "opening", "palette": "light", "size": Vector2i(1920,1080)},
		{"id": "poor-light", "state": "poor", "palette": "light", "size": Vector2i(1920,1080)},
		{"id": "coin-light", "state": "coin", "palette": "light", "size": Vector2i(1920,1080)},
		{"id": "opening-dark", "state": "opening", "palette": "dark", "size": Vector2i(1920,1080)},
		{"id": "coin-compact", "state": "coin", "palette": "light", "size": Vector2i(1138,640)},
		{"id": "opening-regular", "state": "opening", "palette": "light", "size": Vector2i(1920,1080), "width": T.DOCK_WIDTH},
		{"id": "coin-regular", "state": "coin", "palette": "light", "size": Vector2i(1920,1080), "width": T.DOCK_WIDTH},
		{"id": "opening-choices", "state": "opening", "palette": "light", "size": Vector2i(1920,1080), "width": T.DOCK_WIDTH, "choices": true},
		{"id": "coin-dark-compact", "state": "coin", "palette": "dark", "size": Vector2i(1138,640)}]
	for spec: Dictionary in cases:
		if selected_case.is_empty() or spec.id == selected_case: await _case(spec)
	_check(not report.cases.is_empty(), "At least one named Wealth fixture ran")
	_finish()

func _fixture(kind: String) -> void:
	GameState.reset_for_new_world(SEED)
	DiscoverySystem.reset_for_new_world()
	GameState.civic_api_enabled = false
	GameState.settlement_name = "Reedwater"
	var coin := kind == "coin"
	var poor := kind == "poor"
	GameState.ensure_population_total(1800 if coin else 96)
	GameState.settlement_site_committed = true
	GameState.settlement_completed.assign(["Hearth Circle", "Lean-to Shelters", "Storage Pits"])
	SettlementModel.ensure_founded()
	GameState.elapsed_days = (640 if coin else 3) * 365.0 + 42.0
	GameState.population_health = .48 if poor else .83
	GameState.population_allocations["Crafting"] = 140 if coin else (0 if poor else 8)
	GameState.population_allocations["Construction"] = 30 if coin else 4
	GameState.population_allocations["Research"] = 16 if coin else 0
	GameState.population_allocations["Logistics"] = 44 if coin else 6
	GameState.known_discoveries.assign(["controlled_flaking", "cordage", "basketry"])
	if coin: GameState.known_discoveries.append_array(["clay_shaping", "pit_firing", "joinery", "craft_guilds", "bills_of_exchange", "printing_process"])
	GameState.discovery_adoption.clear()
	for id in GameState.known_discoveries: GameState.discovery_adoption[id] = 1.0
	DiscoverySystem.refresh_operating_effects()
	GameState.economy_stage = "currency" if coin else "subsistence"
	GameState.resource_stockpiles = {"Food": 45000.0 if coin else (192.0 if poor else 3600.0), "Civilian Goods": 4260.0 if coin else (0.0 if poor else 286.0), "Timber": 1750.0 if coin else (0.0 if poor else 230.0), "Stone": 920.0 if coin else (0.0 if poor else 95.0), "Clay": 740.0 if coin else (0.0 if poor else 120.0), "Fiber Plants": 1280.0 if coin else (0.0 if poor else 180.0)}
	GameState.food_stocks = {"Fresh food": 0.0, "Stored food": float(GameState.resource_stockpiles.Food)}
	GameState.market_prices = {"Food": 1.6 if coin else 1.0, "Civilian Goods": 4.8 if coin else 2.4, "Timber": 1.8, "Stone": 1.2, "Clay": .8, "Fiber Plants": .6}
	GameState.economy_metrics = {"price_observations": 18 if coin else (0 if poor else 6), "goods_traded_days": 200 if coin else (0 if poor else 24), "market_access": .82 if coin else (.0 if poor else .38), "credit_limit": 1600.0 if coin else 0.0, "credit_utilization": .25 if coin else 0.0, "real_economy": {"daily_output_value": 5800.0 if coin else (35.0 if poor else 190.0)}, "social_pressure_parts": {"inequality": .06 if coin else .015}}
	GameState.simulation_metrics["food_days"] = 25.0 if coin else (2.0 if poor else 37.5)
	GameState.simulation_metrics["food_consumption"] = GameState.population_exact
	GameState.simulation_metrics["labor_efficiency"] = .78 if coin else (.3 if poor else .68)
	GameState.civilian_goods = Goods.empty_state()
	GameState.civilian_goods.last_day = int(GameState.elapsed_days)
	GameState.civilian_goods.report = {"made": 94.0 if coin else (0.0 if poor else 5.6), "reason": "No makers or materials to spare" if poor else ""}
	GameState.wealth_shares.assign([.05,.10,.16,.24,.45] if coin else [.13,.16,.19,.23,.29])
	GameState.private_currency = 14600.0 if coin else 0.0
	GameState.currency_hoards = 2300.0 if coin else 0.0
	GameState.mutual_aid_reserve = 480.0 if coin else 0.0
	GameState.public_treasury = 0.0
	GameState.realm_purse = Purse._fresh()
	var purse := Purse.state()
	purse.migrated = true
	purse.unit = "coin" if coin else "ration"
	purse.balance = 8200.0 if coin else (0.0 if poor else 620.0)
	purse.coin = purse.balance if coin else 0.0
	purse.book_price = 1.6 if coin else 1.0
	purse.lines.scholars = coin
	purse.lines.crews = coin
	GameState.enterprise = {}
	var business := Business.state()
	business.share = .082 if coin else (.0 if poor else .015)
	business.stance = "chartered" if coin else "guarded"
	Business._refresh(business)
	held_artifact = {}
	if not poor:
		# Same engine constructor as test_artifact_collection. Choose a real
		# physically recoverable record whose prehistoric painting is approved.
		for index in 2048:
			var item := Artifacts.find_at(777, Vector2(index * 24, 100), 1)
			if ArtifactArt.image_path(item).is_empty(): continue
			held_artifact = item
			Exchange.data().collections[item.id] = item
			break

func _case(spec: Dictionary) -> void:
	print("WEALTH_CASE_BEGIN ", spec.id)
	if is_instance_valid(hud):
		hud.queue_free()
		await _frames(8)
	print("WEALTH_CASE_PREPARE ", spec.id)
	_fixture(String(spec.state))
	T.set_color_mode(String(spec.palette))
	print("WEALTH_CASE_MOUNT ", spec.id)
	background.color = T.PAPER_SUNK.lerp(T.GREEN, .16)
	get_window().size = spec.size
	label.text = "TEST · Wealth acceptance\n" + String(spec.id) + "\nPrepared records · simulation paused"
	label.visible = Vector2i(spec.size).x >= 1600
	label.modulate = T.INK
	hud = WealthHud.new()
	add_child(hud)
	hud.register_provider("economy", Economy.new(null, hud))
	hud.section_requested.connect(func(section: String, sub: int): last_destination = [section, sub])
	hud.time_text.text = "[b]Year %d · Spring[/b] · Paused" % floori(GameState.elapsed_days / 365.0)
	hud.drawer_open = true
	hud._sync_drawer()
	hud.open_dock("economy", 2)
	await _frames(16)
	hud.force_dock_layout()
	# The first shrink can be clamped by the old multi-column minimum. Let
	# the real responsive grid settle, then apply the requested regular width.
	if spec.has("width"):
		for pass_index in 3:
			hud.dock.size.x = float(spec.width)
			await _frames(4)
	await _frames(8)
	print("WEALTH_CASE_CHECKS ", spec.id)
	var board: Control = hud.dock.find_child("PurseBoard", true, false)
	_check(board != null, String(spec.id) + " mounts the actual Wealth board")
	if board == null: return
	if bool(spec.get("choices", false)):
		var toggle := board.find_child("StanceToggle", true, false) as Button
		_check(toggle != null and toggle.is_visible_in_tree(), String(spec.id) + " offers the business stance disclosure")
		if toggle != null: toggle.pressed.emit()
		await _frames(8)
		var choices := board.find_child("StanceChoice", true, false) as Control
		_check(choices != null and choices.is_visible_in_tree(), String(spec.id) + " opens the actual stance choices")
	_check(hud.dock.sub == 2 and hud.dock.title_label.text == "Wealth", String(spec.id) + " uses the actual economy Wealth tab")
	var held := Standing.wealth_held()
	_check(int(held.treasures) == (0 if spec.state == "poor" else 1), String(spec.id) + " counts the real held artifact or empty collection")
	for chart_name in ["GoodsAvailability", "GoodsComparison", "Fifths"]:
		var chart := board.find_child(chart_name, true, false) as Control
		_check(chart != null and chart.is_visible_in_tree() and chart.size.x > 0 and chart.size.y > 0, String(spec.id) + " presents chart " + chart_name)
	var available_width := minf(board.size.x, hud.dock.body_scroll.size.x - 24.0)
	for grid_spec in [["WealthCards",780.0,3], ["WealthSociety",820.0,2]]:
		var grid := board.find_child(String(grid_spec[0]), true, false) as GridContainer
		_check(grid != null and grid.columns == (int(grid_spec[2]) if available_width >= float(grid_spec[1]) else 1), String(spec.id) + " reflows " + String(grid_spec[0]) + " for available width")
	if not held_artifact.is_empty():
		var painting := board.find_child("HeldTreasureIllustration", true, false) as TextureRect
		_check(painting != null and painting.texture != null and painting.texture.resource_path == ArtifactArt.image_path(held_artifact), String(spec.id) + " displays the approved artwork of the actual held artifact")
	for name in ["GoodsHeld", "GoodsBuy", "GoodsAHead", "GoodsSpare", "GoodsMade", "Treasures", "Materials", "Business", "Fifths", "Shares", "Pressure"]:
		_check(board.find_child(name, true, false) != null, String(spec.id) + " preserves data node " + name)
	var goods_label := board.find_child("GoodsHeld", true, false) as Label
	_check(goods_label != null and goods_label.text.contains(Words.grouped(roundi(float(held.goods)))), String(spec.id) + " goods total comes from the engine ledger")
	var made := 0.0
	for card: Dictionary in Production.household_cards(): made += float(card.get("made", 0.0))
	_check(is_equal_approx(made, float(GameState.civilian_goods.report.made)), String(spec.id) + " prepared production is current")
	var made_label := board.find_child("GoodsMade", true, false) as Label
	_check(made_label != null and made_label.text == "%s goods" % board._amount(made), String(spec.id) + " displays the current made goods")
	_check(board.find_child("Balance", true, false) != null if spec.state == "coin" else board.find_child("StorePointer", true, false) != null, String(spec.id) + " places the treasury or food-store link correctly")
	var bounds := Rect2(Vector2.ZERO, Vector2(spec.size))
	_check(bounds.encloses(hud.dock.get_global_rect()), String(spec.id) + " dock fits the viewport")
	var requested_width := float(spec.get("width", minf(hud._work_queue_width(float(Vector2i(spec.size).x)), float(Vector2i(spec.size).x) - T.DOCK_X - 12.0)))
	if absf(hud.dock.size.x - requested_width) >= 1.0:
		var minimums: Array = []
		_width_constraints(hud.dock, requested_width - 64.0, minimums)
		print("WEALTH_WIDTH_CONSTRAINTS ", spec.id, " ", JSON.stringify(minimums))
	_check(absf(hud.dock.size.x - requested_width) < 1.0, String(spec.id) + " respects requested dock width %.1f (actual %.1f)" % [requested_width, hud.dock.size.x])
	_check(hud.dock.get_combined_minimum_size().x <= requested_width + 1.0, String(spec.id) + " minimum width fits the requested dock")
	var overflow: Array[String] = []
	_horizontal_overflow(board, hud.dock.body_scroll.get_global_rect(), overflow)
	_check(overflow.is_empty(), String(spec.id) + " has no horizontal overflow: " + ", ".join(overflow))
	var before := _economic_fingerprint()
	var node_id: int = board.get_instance_id()
	board.refresh()
	hud.dock.rebuild()
	await _frames(3)
	_check(hud.dock.find_child("PurseBoard", true, false).get_instance_id() == node_id, String(spec.id) + " live refresh retains the board")
	_check(before == _economic_fingerprint(), String(spec.id) + " display refresh preserves economy records")
	var row := {"id": spec.id, "state": spec.state, "palette": spec.palette, "canvas": str(spec.size), "dock_rect": str(hud.dock.get_global_rect()), "requested_width": requested_width, "goods_made": made, "held": held, "artifact": held_artifact, "artifact_art": ArtifactArt.image_path(held_artifact), "purse_unit": Purse.unit_word(), "business_rung": Business.rung(), "overflow": overflow, "images": []}
	var scroll: ScrollContainer = hud.dock.body_scroll
	var end := maxi(0, roundi(scroll.get_v_scroll_bar().max_value - scroll.get_v_scroll_bar().page))
	for position in [["top",0], ["middle",end / 2], ["bottom",end]]:
		scroll.scroll_vertical = int(position[1])
		await _frames(3)
		if capture and DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			var path := output.path_join(String(spec.id) + "-" + String(position[0]) + ".png")
			_check(get_viewport().get_texture().get_image().save_png(path) == OK, "Capture saves " + path.get_file())
			row.images.append(path)
	for route in [["SeeArms","production",2], ["SeeMaterials","economy",1], ["SeeStore","economy",0]]:
		var button := board.find_child(String(route[0]), true, false) as Button
		if button == null and route[0] == "SeeStore" and spec.state == "coin": continue
		_check(button != null and not button.disabled, String(spec.id) + " enables " + String(route[0]))
		if button != null:
			last_destination.clear()
			button.pressed.emit()
			_check(last_destination == [route[1], route[2]], String(spec.id) + " routes " + String(route[0]) + " correctly")
	var treasures := board.find_child("SeeTreasures", true, false) as Button
	print("WEALTH_CASE_COLLECTION ", spec.id)
	_check(treasures != null, String(spec.id) + " keeps collection navigation")
	if treasures != null:
		treasures.pressed.emit()
		await _frames(8)
		var collection: Variant = CivilizationSystem.get_meta("exchange_collection_panel", null)
		_check(is_instance_valid(collection), String(spec.id) + " opens the actual collection panel")
		if is_instance_valid(collection): collection.get_child(0).close()
		await _frames(8)
	report.cases.append(row)
	print("WEALTH_CASE_END ", spec.id)

func _economic_fingerprint() -> PackedByteArray:
	return var_to_bytes([GameState.resource_stockpiles, GameState.market_prices, GameState.wealth_shares, GameState.realm_purse, GameState.enterprise, GameState.civilian_goods])

func _horizontal_overflow(node: Node, bounds: Rect2, found: Array[String]) -> void:
	if node is Control and node.is_visible_in_tree() and node.size.x > 0:
		var rect: Rect2 = node.get_global_rect()
		if rect.position.x < bounds.position.x - 1.0 or rect.end.x > bounds.end.x + 1.0: found.append(String(node.name))
	for child in node.get_children(): _horizontal_overflow(child, bounds, found)

func _width_constraints(node: Node, threshold: float, found: Array) -> void:
	if node is Control and node.get_combined_minimum_size().x > threshold:
		found.append({"node": str(hud.dock.get_path_to(node)), "minimum": node.get_combined_minimum_size().x, "size": node.size.x, "visible": node.is_visible_in_tree()})
	for child in node.get_children(): _width_constraints(child, threshold, found)

func _frames(count: int) -> void:
	for frame in count: await get_tree().process_frame

func _check(ok: bool, message: String) -> void:
	checks += 1
	report.checks.append({"ok": ok, "message": message})
	if not ok:
		failures.append(message)
		printerr("WEALTH_ACCEPTANCE_FAILED ", message)

func _finish() -> void:
	report["passed"] = checks - failures.size()
	report["total"] = checks
	report["failures"] = failures
	report["display"] = DisplayServer.get_name()
	var path := output.path_join("capture.json" if capture else "functional.json")
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file: file.store_string(JSON.stringify(report, "  "))
	print("WEALTH_VISUAL_ACCEPTANCE ", JSON.stringify({"passed": report.passed, "total": checks, "failures": failures, "report": path}))
	get_tree().quit(0 if failures.is_empty() else 1)
