extends "res://scripts/hud/town_works_board.gd"
## Presentation only. All readings and actions arrive from the construction provider.
const Art := preload("res://scripts/hud/construction_art.gd")
var disclosures: Dictionary = {}
var grid: GridContainer
var hero_rows: Array[BoxContainer] = []

func setup(block: Dictionary) -> void:
	data = block
	name = "BuildersTownFolio"
	theme = _theme()
	add_theme_constant_override("separation", 16)
	resized.connect(_fit)
	if bool(block.get("readings", false)):
		grid = GridContainer.new()
		grid.columns = 3
		grid.add_theme_constant_override("h_separation", 24)
		grid.add_theme_constant_override("v_separation", 18)
		add_child(grid)
		for card: Dictionary in block.get("cards", []): grid.add_child(_reading(card))
	else:
		for card: Dictionary in block.get("cards", []): add_child(_card(card))
	_fit.call_deferred()

func _fit() -> void:
	if grid != null: grid.columns = 3 if size.x >= 710 else 2 if size.x >= 470 else 1
	for row: BoxContainer in hero_rows: row.vertical = size.x < 620

func view_state() -> Dictionary:
	var result := {}
	for key: String in disclosures: result[key] = (disclosures[key] as Control).visible
	return result

func restore_view_state(state: Dictionary) -> void:
	for key: String in disclosures:
		var body: Control = disclosures[key]
		body.visible = bool(state.get(key, false))
		var button := body.get_meta("button") as Button
		button.set_pressed_no_signal(body.visible)
		button.text = "Close details −" if body.visible else "Details +"

func _rule(parent: Node) -> void:
	var rule := HSeparator.new()
	var style := StyleBoxLine.new()
	style.color = Color(T.RULE_STRONG, 0.55)
	style.thickness = 1
	rule.add_theme_stylebox_override("separator", style)
	parent.add_child(rule)

func _serif(text: String, size: int = 24, color: Color = T.INK) -> Label:
	var label := _label(text, size, color)
	label.add_theme_font_override("font", T.font("voice"))
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label

func _words(text: String, size: int = 15) -> Label:
	var label := _label(text, size, T.TEXT_SOFT)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label

func _reading(card: Dictionary) -> Control:
	var column := VBoxContainer.new()
	column.name = "Reading_" + String(card.get("key", "work"))
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 5)
	_rule(column)
	column.add_child(_serif(String(card.name), 19, T.TEXT_SOFT))
	column.add_child(_serif(String(card.get("value", "")), 29, T.legible(card.get("value_color", T.INK), T.PAPER)))
	column.add_child(_words(String(card.get("sub", "")), 14))
	if not (card.get("blockers", []) as Array).is_empty(): column.add_child(_chips(card.blockers, []))
	_details(column, card)
	return column

func _card(card: Dictionary) -> Control:
	var column := VBoxContainer.new()
	column.name = "Card_" + String(card.get("key", "work"))
	column.add_theme_constant_override("separation", 10)
	var hero := String(card.get("key", "")) == "work"
	var row := BoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	column.add_child(row)
	if hero:
		hero_rows.append(row)
		var art := Art.for_title(String(card.name), 265, 225)
		art.name = "BuildingIllustration"
		var material := ShaderMaterial.new()
		material.shader = preload("res://scripts/hud/trade_paper_art.gdshader")
		art.material = material
		row.add_child(art)
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.add_theme_constant_override("separation", 8)
	row.add_child(words)
	if hero:
		var caption := "Works completed" if String(card.get("state", "")) == "done" else "Next to build" if String(card.get("state", "")) == "waiting" else "The work in hand"
		words.add_child(_serif(caption, 17, T.GOLD_TEXT))
	var head := HBoxContainer.new()
	words.add_child(head)
	var title := _serif(String(card.name), 32 if hero else 22)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	if card.has("stamp"):
		var stamp := Stamp.new()
		stamp.text = String(card.stamp.get("text", "Built"))
		stamp.tooltip_text = String(card.stamp.get("tip", ""))
		head.add_child(stamp)
	if String(card.get("value", "")) != "": words.add_child(_serif(String(card.value), 28 if hero else 22, T.legible(card.get("value_color", T.INK), T.PAPER)))
	words.add_child(_words(String(card.get("sub", ""))))
	if card.get("progress") is Dictionary: words.add_child(_bar_line(card.progress, "Progress"))
	if not (card.get("gains", []) as Array).is_empty(): words.add_child(_gains(card.gains))
	if not (card.get("effects", []) as Array).is_empty(): words.add_child(_effects(card.effects))
	if not (card.get("needs", []) as Array).is_empty(): words.add_child(_needs(card.needs))
	if not (card.get("blockers", []) as Array).is_empty(): words.add_child(_chips(card.blockers, []))
	if card.get("choice") is Dictionary: column.add_child(_choice(card.choice))
	if not (card.get("actions", []) as Array).is_empty(): column.add_child(_actions(card.actions))
	_details(column, card)
	_rule(column)
	return column

func _needs(needs: Array) -> Control:
	var flow := HFlowContainer.new()
	flow.name = "Needs"
	flow.add_theme_constant_override("h_separation", 16)
	flow.add_theme_constant_override("v_separation", 6)
	for need: Dictionary in needs:
		var have := float(need.get("have", 0.0))
		var wanted := float(need.get("need", 0.0))
		var resource := String(need.get("resource", ""))
		var title := preload("res://scripts/resource_names.gd").label(resource) if resource != "" else String(need.get("label", ""))
		var label := _label("%s %s / %s" % [title, _n(have), _n(wanted)], 14, T.RED_TEXT if have + 0.0001 < wanted else T.TEXT_SOFT)
		label.tooltip_text = String(need.get("tip", "%s in store / needed" % title))
		label.mouse_filter = Control.MOUSE_FILTER_STOP
		flow.add_child(label)
	return flow

func _details(parent: VBoxContainer, card: Dictionary) -> void:
	var button := Button.new()
	button.name = "Details_" + String(card.get("key", "work"))
	button.text = "Details +"
	button.toggle_mode = true
	button.flat = true
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	button.add_theme_font_override("font", T.font("voice"))
	button.add_theme_font_size_override("font_size", 16)
	button.custom_minimum_size.y = 28
	parent.add_child(button)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 8)
	body.visible = false
	body.set_meta("button", button)
	parent.add_child(body)
	disclosures[String(card.get("key", "work"))] = body
	body.add_child(_words(String(card.get("detail", "")), 14))
	if card.get("meter") is Dictionary: body.add_child(_bar_line(card.meter, "Meter"))
	if bool(data.get("readings", false)):
		if card.get("progress") is Dictionary: body.add_child(_bar_line(card.progress, "Progress"))
		if not (card.get("gains", []) as Array).is_empty(): body.add_child(_gains(card.gains))
		if not (card.get("effects", []) as Array).is_empty(): body.add_child(_effects(card.effects))
		if not (card.get("needs", []) as Array).is_empty(): body.add_child(_needs(card.needs))
		if card.get("choice") is Dictionary: body.add_child(_choice(card.choice))
		if not (card.get("actions", []) as Array).is_empty(): body.add_child(_actions(card.actions))
	if not (card.get("notes", []) as Array).is_empty(): body.add_child(_chips([], card.notes))
	button.toggled.connect(func(open: bool) -> void:
		body.visible = open
		button.text = "Close details −" if open else "Details +")
