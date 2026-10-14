extends "res://scripts/hud/provisions_panel.gd"
## Compact local food report. Reuses the owning provider and live readings.
var summary: GridContainer
var daily_values: Dictionary = {}
var flow_bar: FlowBar
## The day's figures in order: [flow key, caption, the bar's ink (null: not a
## part of the bar)]. "Kept" is the engine's own change in the stores,
## counted from the stores themselves (food_system.gd food_net); the engine
## keeps no named tally of what else moved them, so none is invented here.
const FLOW_CELLS := [["Produced", "Brought in", null], ["Eaten", "Eaten", Color("8a6118")], ["Spoiled", "Spoiled", Color("a34435")],
	["Missions", "Sent out", Color("4d6389")], ["Net", "Kept", Color("5d6f34")]]

func setup(block: Dictionary) -> void:
	theme = T.control_theme()
	data = block
	name = "ProvisionsLedger"
	add_theme_constant_override("separation", 10)
	_shape = shape_of(block)
	_refs = {"rows":[]}
	# Who decides the work and which town are the page's own (the title and
	# the choices below say them); kept for the shared fill, not shown.
	var head := HBoxContainer.new()
	head.visible = false
	add_child(head)
	_refs.owner = _line(head, "", 13, T.MUTED)
	_refs.city = _line(head, "", 13, T.BODY)
	# The two headlines, each with a small picture beside it.
	summary = GridContainer.new()
	summary.columns = 2
	summary.add_theme_constant_override("h_separation", 28)
	add_child(summary)
	for kind: String in ["food", "water"]:
		var card := HBoxContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.add_theme_constant_override("separation", 10)
		summary.add_child(card)
		var picture := TextureRect.new()
		picture.texture = preload("res://scripts/resource_icons.gd").texture_for("Food" if kind == "food" else "Freshwater")
		picture.custom_minimum_size = Vector2(34, 34)
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		picture.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(picture)
		_refs[kind] = _reading(card, "", "", "", "")
		_refs[kind].name = "FoodReading" if kind == "food" else "WaterReading"
	# The one control, beside the figures it changes.
	if bool(data.can_direct):
		var who := String(data.get("leader_name", ""))
		if who.is_empty(): who = "the leader"
		var focus := String(data.get("focus", ""))
		var current := "" if bool(data.managed) else (focus if focus in ["provisions", "water"] else "other")
		_choices(self, "Ask %s for more hands on" % who, [
			{"id":"provisions", "label":"Food", "tip":"More food work; other work slows", "on_press":func(): data.on_focus.call("provisions")},
			{"id":"water", "label":"Water", "tip":"More water carriers; other work slows", "on_press":func(): data.on_focus.call("water")},
			{"id":"", "label":"Let %s decide" % who, "tip":"The leader balances the work", "on_press":func(): data.on_focus.call("")},
		], current)
	_refs.flow = _line(self, "", 13, T.BODY)
	_refs.flow.name = "FlowSentence"
	_refs.lean = _line(self, "", 13, T.BODY)
	if not String(data.get("food_plan", "")).is_empty(): _refs.plan = _line(self, "", 13, T.BODY)
	_rule(self)
	_line(self, "TODAY · RATIONS", 11, T.MUTED)
	# Where the day's food went, as one bar: eaten, spoiled, sent out, kept.
	flow_bar = FlowBar.new()
	flow_bar.name = "FlowBar"
	flow_bar.custom_minimum_size = Vector2(0, 14)
	add_child(flow_bar)
	var daily := GridContainer.new()
	daily.name = "Daily"
	daily.columns = FLOW_CELLS.size()
	daily.add_theme_constant_override("h_separation", 10)
	add_child(daily)
	for pair: Array in FLOW_CELLS:
		var cell := VBoxContainer.new()
		cell.name = "Cell_" + String(pair[0])
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.add_theme_constant_override("separation", 0)
		daily.add_child(cell)
		var value := _voice("", 22)
		cell.add_child(value)
		daily_values[pair[0]] = value
		var caption := HBoxContainer.new()
		caption.add_theme_constant_override("separation", 4)
		cell.add_child(caption)
		if pair[2] != null:
			var swatch := ColorRect.new()
			swatch.color = pair[2]
			swatch.custom_minimum_size = Vector2(8, 8)
			swatch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			caption.add_child(swatch)
		_line(caption, pair[1], 12, T.MUTED)
	_rule(self)
	_line(self, "TOWN STORES", 11, T.MUTED)
	for item: Dictionary in data.rows:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		add_child(row)
		var title := _voice(String(item.name), 20)
		title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(title)
		var numbers := VBoxContainer.new()
		numbers.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(numbers)
		var refs := {"line":_line(numbers, "", 13), "detail":null, "stock":_voice("", 23)}
		numbers.add_child(refs.stock)
		numbers.move_child(refs.stock, 0)
		var opened: bool = data.selected == item.name
		_button(row, "Hide" if opened else "How it keeps", func(): data.on_select.call(String(item.name)), "Who carries and keeps this store, and what spoils").size_flags_vertical = Control.SIZE_SHRINK_CENTER
		if opened: refs.detail = _line(self, "", 13, T.MUTED)
		_refs.rows.append(refs)
	_rule(self)
	_refs.forecast = _line(self, "", 13, T.BODY)
	_refs.forecast.name = "Forecast"
	var links := HFlowContainer.new()
	links.add_theme_constant_override("h_separation", 8)
	add_child(links)
	_button(links, "Gathering & preparation", data.on_sources, "Food sources, fire, cooking and preservation")
	_button(links, "Water access", data.on_water, "Known water sources and carrying")
	_button(links, "Past seasons", data.on_history, "The history of the town's food stores")
	if bool(data.get("has_deliveries", false)):
		_button(links, "Deliveries", data.on_trade, "Food and goods travelling between settlements")
	resized.connect(_layout_food)
	_fill()
	_layout_food()

func _layout_food() -> void:
	if summary: summary.columns = 2 if size.x >= 560 else 1

func update_block(block: Dictionary) -> bool:
	if bool(block.get("has_deliveries", false)) != bool(data.get("has_deliveries", false)): return false
	return super.update_block(block)

func _fill() -> void:
	super._fill()
	_refs.flow.visible = false
	var amounts := flow_amounts(data.flow)
	# Spoiled is the stores' own lines added up, so the page's figures agree.
	var spoiled_rows := 0
	for item: Dictionary in data.rows: spoiled_rows += roundi(float(item.lost))
	if not (data.rows as Array).is_empty(): amounts["Spoiled"] = float(spoiled_rows)
	for key: String in daily_values:
		var amount := float(amounts.get(key, 0))
		var words: String = preload("res://scripts/realm_purse.gd").number(amount)
		if key == "Net" and amount > 0: words = "+" + words
		_put(daily_values[key], words, tone_color("bad" if amount < 0 else "good") if key == "Net" else T.INK)
		daily_values[key].tooltip_text = String(_refs.flow.text) + "\n" + String(_refs.flow.tooltip_text)
	# Nothing sent: that cell stands aside.
	(daily_values.Missions.get_parent() as Control).visible = absf(float(amounts.Missions)) >= 0.5
	(daily_values.Missions.get_parent() as Control).tooltip_text = "Rations sent with parties that left today."
	(daily_values.Net.get_parent() as Control).tooltip_text = "The change in the stores today, counted from the stores themselves. Rations handed out between the day's counts (to parties, envoys, the watch abroad) are tallied apart, so this can differ a little from brought in less eaten, spoiled and sent."
	flow_bar.amounts = amounts
	flow_bar.queue_redraw()
	# The headline carries the top bar's own figure for water in store.
	var wet := Words.water(data.water)
	var water_days := Words.water_days(data.water)
	if water_days >= 0.0:
		_fill_reading(_refs.water, "Water for " + preload("res://scripts/hud/era_words.gd").days_in_words(water_days), "", String(wet.headline), String(wet.tone))
	# Which way the stores went today, from the recorded change (a small gain
	# on a large stock can be called steady by the legacy reading). The amount
	# itself is said once, under Change.
	var net := float(data.flow.get("Net", 0))
	if float(data.food_days) >= 0:
		_put(_refs.food.get_child(1), "No change to stores today" if absf(net) < 0.05 else ("Stores are growing" if net >= 0 else "Stores are shrinking"))
	for index in data.rows.size():
		var item: Dictionary = data.rows[index]
		var refs: Dictionary = _refs.rows[index]
		_put(refs.stock, "%s rations" % preload("res://scripts/realm_purse.gd").number(float(item.stock)))
		_put(refs.line, "%s spoiled today" % Plain.number(float(item.lost)), T.MUTED)


## The day's terms as the engine gives them.
static func flow_amounts(flow: Dictionary) -> Dictionary:
	var out := {}
	for key: String in ["Produced", "Eaten", "Spoiled", "Missions", "Net"]: out[key] = float(flow.get(key, 0))
	return out


## One bar for the day's food: what was eaten, spoiled, sent out, otherwise
## taken, and kept, each a share of everything that left or stayed.
class FlowBar extends Control:
	const T := preload("res://scripts/hud/hud_tokens.gd")
	var amounts: Dictionary = {}

	func _draw() -> void:
		var parts: Array = []
		for pair: Array in FLOW_CELLS:
			if pair[2] == null: continue
			var amount := float(amounts.get(pair[0], 0.0))
			# A day the stores shrank has no "kept" share.
			if String(pair[0]) == "Net": amount = maxf(0.0, amount)
			if amount > 0.0: parts.append([amount, pair[2]])
		draw_rect(Rect2(Vector2.ZERO, size), Color(T.INK, 0.10))
		var total := 0.0
		for part: Array in parts: total += float(part[0])
		if total <= 0.0: return
		var x := 0.0
		for part: Array in parts:
			var width := size.x * float(part[0]) / total
			draw_rect(Rect2(x, 0, maxf(1.0, width - 1.0), size.y), part[1])
			x += width
