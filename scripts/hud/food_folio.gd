extends "res://scripts/hud/provisions_panel.gd"
## Compact local food report. Reuses the owning provider and live readings.
var summary: GridContainer
var daily_values: Dictionary = {}

func setup(block: Dictionary) -> void:
	theme = T.control_theme()
	data = block
	name = "ProvisionsLedger"
	add_theme_constant_override("separation", 12)
	_shape = shape_of(block)
	_refs = {"rows":[]}
	var head := HBoxContainer.new()
	add_child(head)
	_refs.owner = _line(head, "", 13, T.MUTED)
	_refs.city = _line(head, "", 13, T.BODY)
	_refs.city.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	summary = GridContainer.new()
	summary.columns = 2
	summary.add_theme_constant_override("h_separation", 28)
	add_child(summary)
	for kind: String in ["food", "water"]:
		var card := VBoxContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.add_theme_constant_override("separation", 6)
		summary.add_child(card)
		card.add_child(FoodArt.picture(0 if kind == "food" else 4, 160, 105))
		_refs[kind] = _reading(card, "", "", "", "")
		_refs[kind].name = "FoodReading" if kind == "food" else "WaterReading"
	_refs.flow = _line(self, "", 13, T.BODY)
	_refs.flow.name = "FlowSentence"
	_refs.lean = _line(self, "", 13, T.BODY)
	if not String(data.get("food_plan", "")).is_empty(): _refs.plan = _line(self, "", 13, T.BODY)
	_rule(self)
	_line(self, "TODAY · RATIONS", 11, T.MUTED)
	var daily := GridContainer.new()
	daily.columns = 4
	daily.add_theme_constant_override("h_separation", 16)
	add_child(daily)
	for pair: Array in [["Produced", "Brought in"], ["Eaten", "Eaten"], ["Spoiled", "Spoiled"], ["Net", "Change"]]:
		var cell := VBoxContainer.new()
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		daily.add_child(cell)
		var value := _voice("", 27)
		cell.add_child(value)
		daily_values[pair[0]] = value
		_line(cell, pair[1], 12, T.MUTED)
	_refs.missions = _line(self, "", 12, T.MUTED)
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
		_button(row, "Close" if opened else "Care", func(): data.on_select.call(String(item.name)), "Storage, carrying and spoilage").size_flags_vertical = Control.SIZE_SHRINK_CENTER
		if opened: refs.detail = _line(self, "", 13, T.MUTED)
		_refs.rows.append(refs)
	_rule(self)
	_refs.forecast = _line(self, "", 13, T.BODY)
	_refs.forecast.name = "Forecast"
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
	for key: String in daily_values:
		var amount := float(data.flow.get(key, 0))
		var words := Plain.number(amount)
		if key == "Net" and amount > 0: words = "+" + words
		_put(daily_values[key], words, tone_color("bad" if amount < 0 else "good") if key == "Net" else T.INK)
		daily_values[key].tooltip_text = String(_refs.flow.text) + "\n" + String(_refs.flow.tooltip_text)
	var sent := float(data.flow.get("Missions", 0))
	_refs.missions.visible = sent > 0.05
	_put(_refs.missions, "%s rations sent with departing parties today." % Plain.number(sent))
	# A small gain on a large stock can be called steady by the legacy reading.
	# The compact report instead states the exact recorded daily change.
	var net := float(data.flow.get("Net", 0))
	if float(data.food_days) >= 0:
		_put(_refs.food.get_child(1), "No change to stores today" if absf(net) < 0.05 else "%s rations %s today, after losses and departures" % [Plain.number(absf(net)), "added" if net >= 0 else "used from stores"])
	for index in data.rows.size():
		var item: Dictionary = data.rows[index]
		var refs: Dictionary = _refs.rows[index]
		_put(refs.stock, "%s rations" % preload("res://scripts/realm_purse.gd").number(float(item.stock)))
		_put(refs.line, "%s spoiled today" % Plain.number(float(item.lost)), T.MUTED)
