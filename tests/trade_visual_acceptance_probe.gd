extends Node
## Prepared records, real Trade dock. Never loads or writes a player campaign.
const T = preload("res://scripts/hud/hud_tokens.gd")
const Economy = preload("res://scripts/hud/content/dock_content_economy.gd")
const Ledger = preload("res://scripts/trade_ledger.gd")
const Stances = preload("res://scripts/trade_stances.gd")
const Words = preload("res://scripts/trade_words.gd")
const Goods = preload("res://scripts/civilian_goods.gd")
const Purse = preload("res://scripts/realm_purse.gd")
const SEED := 661288

class TradeHud extends "res://scripts/hud/command_rail_hud.gd":
	func _make_court_button() -> Button:
		var button := super._make_court_button()
		# This short-lived Trade-only shell has no court to prewarm.
		for connection in button.tree_entered.get_connections():
			button.tree_entered.disconnect(connection.callable)
		return button

	func _ready() -> void:
		name = "TradeAcceptanceHud"
		theme = Tokens.control_theme()
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		_build_frame()
		_build_rail()
		_build_time_pill()
		_build_kpi_strip()
		_build_toolbar()
		_build_dock()
		dock.visibility_changed.connect(_layout)
		detail_dock.visibility_changed.connect(_layout)
		_refresh_city_selector()
		get_viewport().size_changed.connect(_layout)
		_layout()
		set_process(false)

var checks := 0
var failures: Array[String] = []
var report: Dictionary = {"seed": SEED, "cases": [], "checks": []}
var capture := false
var output := "res://artifacts/trade-acceptance"
var selected_case := ""
var preview_mode := false
var hud: Control
var background: ColorRect
var label: Label

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	if not OS.get_cmdline_user_args().has("--trade-acceptance"):
		printerr("Requires --trade-acceptance and isolated userdata.")
		get_tree().quit(2)
		return
	if not bool(ProjectSettings.get_setting("application/config/use_custom_user_dir", false)) or not OS.get_user_data_dir().to_lower().contains("acceptance"):
		printerr("Use an ignored override.cfg with acceptance-specific userdata.")
		get_tree().quit(2)
		return
	capture = OS.get_cmdline_user_args().has("--capture")
	preview_mode = OS.get_cmdline_user_args().has("--preview")
	if preview_mode: capture = true
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): output = arg.trim_prefix("--out=")
		if arg.begins_with("--case="): selected_case = arg.trim_prefix("--case=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	get_viewport().gui_embed_subwindows = true
	for node in get_tree().root.get_children():
		if node != self:
			node.set_process(false)
			node.set_physics_process(false)
	preload("res://scripts/hud/motion.gd").reduce_motion = true
	background = ColorRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	label = Label.new()
	label.position = Vector2(1200, 95)
	label.add_theme_font_size_override("font_size", 16)
	add_child(label)
	if preview_mode:
		await _preview_case()
		if is_instance_valid(hud):
			hud.queue_free()
			await _frames(8)
		cleanup_fixture()
		_finish()
		return
	var cases := [
		{"id":"empty-light", "state":"empty", "palette":"light", "width":980.0},
		{"id":"word-regular", "state":"word", "palette":"light", "width":540.0},
		{"id":"barter-light", "state":"barter", "palette":"light", "width":980.0},
		{"id":"barter-dark", "state":"barter", "palette":"dark", "width":980.0},
		{"id":"coin-light", "state":"coin", "palette":"light", "width":980.0},
		{"id":"barter-regular", "state":"barter", "palette":"light", "width":540.0},
		{"id":"coin-dark-regular", "state":"coin", "palette":"dark", "width":540.0},
		{"id":"barter-compact", "state":"barter", "palette":"light", "width":375.0},
		{"id":"coin-dark-compact", "state":"coin", "palette":"dark", "width":375.0}]
	for spec: Dictionary in cases:
		if selected_case.is_empty() or selected_case == String(spec.id): await _case(spec)
	_check(not report.cases.is_empty(), "At least one named Trade fixture ran")
	if is_instance_valid(hud):
		hud.queue_free()
		await _frames(8)
	cleanup_fixture()
	_finish()

## An actual runtime-page prototype for user approval. This deliberately does
## not run acceptance contracts: those follow approval of the visual direction.
func _preview_case() -> void:
	prepare_fixture("coin" if selected_case.begins_with("coin") else "barter")
	# Prepared daily reports feed the same civilization readings as the game.
	GameState.simulation_metrics={"food_total_stock":7000.0,"food_consumption":120.0,"food_eaten":120.0,"food_production":132.0}
	GameState.water_metrics={"stored":1680.0,"required_today":120.0,"intake_ratio":1.0,"collected_today":126.0}
	SettlementModel._ensure_primary_settlement_record()
	# The layout stress cases retain deliberately long names. This approval
	# example uses ordinary names in the same prepared records.
	for index in CivilizationSystem.civilizations.size():
		CivilizationSystem.civilizations[index].name=["Willow River", "Red Clay Houses", "Distant Cedar People"][index]
	T.set_color_mode("dark" if selected_case.contains("dark") else "light")
	background.color = T.PAPER_SUNK.lerp(T.GREEN, 0.16)
	get_window().size = Vector2i(1536, 1024)
	hud = TradeHud.new()
	add_child(hud)
	hud._refresh_kpis()
	hud.register_provider("economy", Economy.new(null, hud))
	hud.time_text.text = "[b]%s[/b] · Paused" % preload("res://scripts/calendar_date.gd").words(int(GameState.elapsed_days),true)
	hud.drawer_open = true
	hud._sync_drawer()
	hud.open_dock("economy", 3)
	await _frames(24)
	hud.force_dock_layout()
	await _frames(12)
	label.add_theme_font_size_override("font_size", 12)
	label.text = "UI PREVIEW\nPrepared trade records\nNot integrated into the game"
	label.modulate = T.INK
	label.position = Vector2(hud.dock.position.x + hud.dock.size.x + 24, 90)
	move_child(label, get_child_count() - 1)
	var board: Control = hud.dock.find_child("TradeBoard", true, false)
	if board == null:
		_check(false, "Preview could not mount the actual Trade board")
		return
	hud.dock.body_scroll.scroll_vertical = 0
	await _frames(8)
	var row := {"id":"trade-preview","prototype":true,"canvas":"1536x1024","dock_width":hud.dock.size.x,"content_width":board.size.x,"images":[]}
	await _capture("trade-preview", row)
	hud.close_dock()
	await _frames(8)
	await _capture("persistent-bar-page-closed", row)
	report.cases.append(row)

## Shared with the regression suite: real actor stores and actual ledger shape.
## The historic monthly flows are prepared evidence, not a simulated campaign.
static func prepare_fixture(kind: String) -> Array:
	OS.set_environment("OPENAI_API_KEY", "")
	OS.set_environment("LEVIATHAN_AI_API_KEY", "")
	WorldSimulation.clear()
	GameState.reset_for_new_world(SEED)
	DiscoverySystem.reset_for_new_world()
	MilitaryCampaign.reset_for_new_world()
	ForeignDiplomacy.reset_for_new_world()
	CivilizationSystem.reset_for_new_world()
	GameState.civic_api_enabled = false
	GameState.settlement_name = "Reedwater"
	GameState.settlement_site_committed = true
	GameState.settlement_completed.assign(["Hearth Circle"])
	# Actors can only be founded at day zero; advance their prepared records below.
	GameState.elapsed_days = 0.0
	FoodSystem.reset_for_new_world()
	FoodSystem.initialize()
	GameState.civilian_goods = Goods.empty_state()
	GameState.civilian_goods.last_day = 420
	GameState.civilian_goods.report = {"made": 8.4}
	GameState.resource_stockpiles["Civilian Goods"] = 2600.0
	CivilizationSystem.civilizations.assign(CivilizationSystem.civilizations.slice(0, 3 if kind != "empty" else 0))
	CivilizationSystem.scout_land_authority = func(_at: Vector2) -> bool: return true
	CivilizationSystem.player_world_origin = Vector2.ZERO
	WorldSimulation.context_provider = func(_origin: Vector2) -> Dictionary: return {"environment_profile":PlanetEnvironment.profile_at(Vector2.ZERO), "surface_water_distance_km":0.1, "surface_water_recognized":true}
	var ids: Array = []
	for index in CivilizationSystem.civilizations.size():
		var c: Dictionary = CivilizationSystem.civilizations[index]
		ids.append(String(c.id))
		c.name = ["People of the Long Willow River and Western Hills", "Red Clay Houses", "Distant Cedar People"][index]
		c.world_position = Vector2(150.0 * float(index + 1), 0)
		c.alive = true
		c.player_relation.contact_level = 1 if kind == "word" or index == 2 else 2
		c.player_relation.opinion = 0.2
		for other: String in (c.get("relations", {}) as Dictionary): c.relations[other].opinion = 0.2
	WorldSimulation.start_world()
	var owners: Array = ["player"] + ids
	for owner: String in owners:
		WorldSimulation.scoped(owner, func() -> void:
			WorldSimulation.state.elapsed_days = 420.0
			WorldSimulation.state.ensure_population_total(120)
			WorldSimulation.state.economy_stage = "currency" if kind == "coin" else "subsistence"
			WorldSimulation.state.resource_stockpiles.merge({"Civilian Goods":2600.0, "Food":7000.0, "Flint":900.0, "Timber":800.0, "Stone":650.0, "Salt":800.0, "Fiber Plants":500.0}, true)
			WorldSimulation.state.market_prices = {"Civilian Goods":4.0,"Food":1.0,"Flint":2.0,"Timber":1.5,"Stone":1.0,"Salt":3.0,"Fiber Plants":0.6}
			WorldSimulation.state.realm_purse = Purse._fresh()
			var purse := Purse.state()
			purse.migrated = true
			purse.unit = "coin" if kind == "coin" else "ration"
			purse.coin = 1400.0 if kind == "coin" else 0.0
			purse.balance = 1400.0
			for good: String in Ledger.GOODS: WorldSimulation.state.economy_known_goods[good] = true
			if owner != "player":
				for c: Dictionary in WorldSimulation.world.civilizations: c.player_relation.contact_level = 2)
		Ledger._refresh_report(owner, 420)
	if kind in ["empty", "word"]: return ids
	for index in 2:
		var id := String(ids[index])
		var p := Ledger.ensure_pair("player", id)
		p.known = true
		p.meet = 100
		p.form = "coin" if kind == "coin" else "barter"
		var outgoing := "ab" if String(p.a) == "player" else "ba"
		var incoming := "ba" if outgoing == "ab" else "ab"
		p.ema[outgoing] = {"Flint":18.0,"Timber":11.0,"Stone":9.0,"Fiber Plants":8.0}
		p.ema[incoming] = {"Salt":16.0,"Food":60.0,"Clay":12.0,"Copper Ore":3.0}
		p.val[outgoing] = 91.3 + index * 10.0
		p.val[incoming] = 151.4 + index * 20.0
		p.owed = 240.0 if outgoing == "ab" else -240.0
		Ledger.state().reports[id].g["Flint"] = {"s":18.0,"d":90.0,"p":2.0,"m":18.0,"u":30.0,"v":2.0}
		Ledger.state().reports.player.g["Salt"] = {"s":25.0,"d":100.0,"p":2.0,"m":32.0,"u":45.0,"v":3.0}
	var other := Ledger.ensure_pair(String(ids[0]), String(ids[1]))
	other.form = "coin" if kind == "coin" else "barter"
	other.val = {"ab":28.0,"ba":36.0}
	Stances.set_stance("player", String(ids[0]), "toll")
	Stances.set_stance(String(ids[1]), "player", "embargo", "", 0.0, "ai")
	Ledger.state().tributes[Stances.skey(String(ids[0]), "player")] = {"value":36.0,"since":400,"until":2200,"next":480,"paid":36.0,"missed":0}
	Ledger.state().answers[Stances.skey("player", String(ids[1]))] = {"stance":"embargo","kind":"bear","day":405,"odds":{"bear":0.35},"roll":0.92}
	Ledger.revision += 1
	return ids

static func cleanup_fixture() -> void:
	WorldSimulation.clear()
	WorldSimulation.context_provider = Callable()
	CivilizationSystem.scout_land_authority = Callable()

static func economic_fingerprint() -> PackedByteArray:
	var actors: Array = []
	for id: String in WorldSimulation.actors:
		var state: Object = WorldSimulation.actors[id].systems.GameState
		actors.append([id,state.resource_stockpiles,state.population_exact,state.realm_purse])
	return var_to_bytes([GameState.resource_stockpiles,GameState.realm_purse,GameState.order_tracker,Ledger.peek(),actors])

func _case(spec: Dictionary) -> void:
	print("TRADE_CASE_BEGIN ", spec.id)
	if is_instance_valid(hud):
		hud.queue_free()
		await _frames(8)
	var ids := prepare_fixture(String(spec.state))
	T.set_color_mode(String(spec.palette))
	background.color = T.PAPER_SUNK.lerp(T.GREEN, 0.16)
	get_window().size = Vector2i(1920, 1080)
	label.text = "TEST · Trade acceptance\n" + String(spec.id) + "\nPrepared records · simulation paused"
	label.modulate = T.INK
	hud = TradeHud.new()
	add_child(hud)
	hud.register_provider("economy", Economy.new(null, hud))
	hud.time_text.text = "[b]Year 1 · Spring[/b] · Paused"
	hud.drawer_open = true
	hud._sync_drawer()
	hud.open_dock("economy", 3)
	await _frames(16)
	hud.force_dock_layout()
	var board: Control = hud.dock.find_child("TradeBoard", true, false)
	_check(board != null, String(spec.id) + " mounts the actual Trade board")
	if board == null: return
	var requested_width := float(spec.width)
	for pass_index in 4:
		hud.dock.size.x = requested_width
		await _frames(5)
	await _frames(6)
	_check(hud.dock.sub == 3 and hud.dock.title_label.text == "Trade", String(spec.id) + " uses the actual Trade tab")
	var totals := board.find_child("FlowTotals", true, false) as Control
	_check(board.find_child("TradeHero", true, false) != null, String(spec.id) + " presents Wealth-style Trade hero")
	_check(totals != null and totals.size.x > 0 and totals.size.y > 0, String(spec.id) + " displays graphical seasonal flow totals")
	var sent := 0.0
	var received := 0.0
	for partner: Dictionary in Ledger.partners("player"):
		sent += Ledger.flow_value("player", String(partner.id))
		received += Ledger.flow_value(String(partner.id), "player")
	if totals != null:
		_check(Array(totals.values) == [received * 3.0, sent * 3.0], String(spec.id) + " hero converts ledger monthly values once")
	_check(absf(hud.dock.size.x - requested_width) < 1.0, String(spec.id) + " fits requested dock width %.1f (actual %.1f)" % [requested_width, hud.dock.size.x])
	_check(hud.dock.get_combined_minimum_size().x <= requested_width + 1.0, String(spec.id) + " minimum width fits dock")
	_check(Rect2(Vector2.ZERO, Vector2(1920,1080)).encloses(hud.dock.get_global_rect()), String(spec.id) + " dock fits viewport")
	var overflow: Array[String] = []
	horizontal_overflow(board, hud.dock.body_scroll.get_global_rect(), overflow)
	_check(overflow.is_empty(), String(spec.id) + " no horizontal overflow: " + ", ".join(overflow))
	for node in board.find_children("*", "", true, false):
		if not node.has_meta("amount"): continue
		var expected_amount := Words.qty(float(node.get_meta("amount")))
		var found := false
		for child in node.find_children("*", "Label", true, false):
			if child.text == expected_amount:
				found = true
				_check(child.get_line_count() == 1, String(spec.id) + " keeps " + String(node.get_meta("good")) + " amount on one line")
		_check(found, String(spec.id) + " presents exact resource amount " + expected_amount)
	for id: String in ids:
		var people := board.find_child("People_" + id, true, false)
		_check(people != null, String(spec.id) + " contains known people " + id)
		if people == null: continue
		var title := people.find_child("Name", true, false) as Label
		_check(title != null and title.text == Ledger.name_of(id), String(spec.id) + " preserves complete people name " + id)
		var is_word := int(Ledger.civ(id).player_relation.contact_level) < 2
		_check((people.find_child("Stances", true, false) == null) == is_word, String(spec.id) + " contact level gates real stance controls " + id)
		_check((people.find_child("BuyWithGoods", true, false) == null) == is_word, String(spec.id) + " contact level gates real buy menu " + id)
		var flow := people.find_child("Flows", true, false) as Control
		_check((flow == null) == is_word, String(spec.id) + " word-only contact has no measured chart " + id)
		if flow != null:
			var form := String(Ledger.pair("player", id).get("form", "gift"))
			var expected := [Words.per_period(Ledger.flow_value(id, "player"), form), Words.per_period(Ledger.flow_value("player", id), form)]
			_check(Array(flow.values) == expected, String(spec.id) + " partner chart uses its ledger period " + id)
	if not ids.is_empty() and not String(spec.state) in ["empty", "word"]:
		var first := board.find_child("People_" + String(ids[0]), true, false)
		_check(first.find_child("Odds", true, false) != null, String(spec.id) + " exposes stated answer odds")
		_check(not Words.waiting_label("player", String(ids[0])).is_empty(), String(spec.id) + " has an actual awaited answer")
		_check(Ledger.blocked("player", String(ids[1])).begins_with("embargo"), String(spec.id) + " reads actual embargo")
	var before := economic_fingerprint()
	var retained := {"TradeBoard":board.get_instance_id()}
	if totals != null: retained["FlowTotals"] = totals.get_instance_id()
	for id: String in ids:
		retained["People_" + id] = board.find_child("People_" + id, true, false).get_instance_id()
	for pass_index in 3: board.refresh()
	hud.dock.rebuild()
	await _frames(4)
	_check(economic_fingerprint() == before, String(spec.id) + " refresh preserves domain ledgers")
	for name: String in retained:
		var node: Node = hud.dock.find_child(name, true, false)
		_check(node != null and node.get_instance_id() == retained[name], String(spec.id) + " retains " + name)
	board = hud.dock.find_child("TradeBoard", true, false)
	if board == null: return
	var row := {"id":spec.id,"state":spec.state,"palette":spec.palette,"dock_width":hud.dock.size.x,"content_width":board.size.x,"overflow":overflow,"images":[]}
	var scroll: ScrollContainer = hud.dock.body_scroll
	var end := maxi(0, roundi(scroll.get_v_scroll_bar().max_value - scroll.get_v_scroll_bar().page))
	for position in [["top",0],["middle",end / 2],["bottom",end]]:
		scroll.scroll_vertical = int(position[1])
		await _frames(4)
		await _capture(String(spec.id) + "-" + String(position[0]), row)
	if not ids.is_empty() and String(spec.state) in ["barter", "coin"]:
		for menu_name in ["Stance_squeeze", "BuyWithGoods"]:
			var people := board.find_child("People_" + String(ids[0]), true, false)
			var menu := people.find_child(menu_name, true, false) as MenuButton
			_check(menu != null and not menu.disabled and menu.get_popup().item_count > 0, String(spec.id) + " offers " + menu_name)
			if menu == null or menu.disabled: continue
			scroll.ensure_control_visible(menu)
			await _frames(3)
			menu.show_popup()
			await _frames(3)
			_check(menu.get_popup().visible, String(spec.id) + " opens " + menu_name)
			var popup_before := economic_fingerprint()
			board.refresh()
			_check(is_instance_valid(menu) and menu.get_popup().visible, String(spec.id) + " retains opened " + menu_name)
			_check(popup_before == economic_fingerprint(), String(spec.id) + " opening choices preserves state")
			await _capture(String(spec.id) + "-" + menu_name, row)
			menu.get_popup().hide()
			await _frames(3)
	report.cases.append(row)
	print("TRADE_CASE_END ", spec.id)

static func horizontal_overflow(node: Node, bounds: Rect2, found: Array[String]) -> void:
	if node is Control and node.is_visible_in_tree() and node.size.x > 0:
		var rect: Rect2 = node.get_global_rect()
		if rect.position.x < bounds.position.x - 1.0 or rect.end.x > bounds.end.x + 1.0: found.append(String(node.name))
	for child in node.get_children(): horizontal_overflow(child, bounds, found)

func _capture(key: String, row: Dictionary) -> void:
	if capture and DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		var path := output.path_join(key + ".png")
		_check(get_viewport().get_texture().get_image().save_png(path) == OK, "Capture saves " + path.get_file())
		row.images.append(path)

func _frames(count: int) -> void:
	for frame in count: await get_tree().process_frame

func _check(ok: bool, message: String) -> void:
	checks += 1
	report.checks.append({"ok":ok,"message":message})
	if not ok:
		failures.append(message)
		printerr("TRADE_ACCEPTANCE_FAILED ", message)

func _finish() -> void:
	report.passed = checks - failures.size()
	report.total = checks
	report.failures = failures
	report.display = DisplayServer.get_name()
	report.prototype = preview_mode
	var path := output.path_join("prototype.json" if preview_mode else ("capture.json" if capture else "functional.json"))
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file: file.store_string(JSON.stringify(report, "  "))
	print("TRADE_PROTOTYPE_CAPTURE " if preview_mode else "TRADE_VISUAL_ACCEPTANCE ", JSON.stringify({"passed":report.passed,"total":checks,"failures":failures,"report":path}))
	get_tree().quit(0 if failures.is_empty() else 1)
