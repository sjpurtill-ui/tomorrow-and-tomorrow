extends "res://scripts/hud/settlement_overview.gd"
## HOME › OVERVIEW: the leader and work decisions lead. Homes and mood sit
## beside that decision; growth and army readings sit with People and Strength.
## Every reading retains its original source, tooltip, and destination.
## Supporting facts flow into two columns when room permits; comparisons
## with the towns our scouts have seen remain in each fact's tooltip.

var _reading_refs:Dictionary={}

func _leader(block:Dictionary,parent:Node)->void:
	super._leader(block,parent)
	_reading_refs.clear()
	var readings:Array=block.get("readings",[])
	if readings.size()<4:return
	var pair:=HBoxContainer.new();pair.add_theme_constant_override("separation",24);pair.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	parent.get_node("Leader").add_child(pair)
	for index in [1,2]:_home_reading(pair,readings[index])

func _home_reading(parent:Node,reading:Dictionary)->void:
	var fact:={"label":T.sentence_case(String(reading.label)),"value":String(reading.value),"tip":String(reading.get("tip","")),"on_click":reading.get("on_press")}
	if reading.has("meter"):fact["bar"]=reading.meter
	var column:=VBoxContainer.new();column.size_flags_horizontal=Control.SIZE_EXPAND_FILL;column.add_theme_constant_override("separation",4);parent.add_child(column)
	var row:=OwnBlocks._fact(fact);column.add_child(row)
	var note:=T.make_label(String(reading.get("delta","")),14,T.MUTED);note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;column.add_child(note)
	_reading_refs[String(reading.label)]={"row":row,"note":note}

func update_block(block:Dictionary)->bool:
	if not super.update_block(block):return false
	for reading:Dictionary in block.get("readings",[]):
		if not _reading_refs.has(String(reading.label)):continue
		var refs:Dictionary=_reading_refs[String(reading.label)]
		_put(refs.row.find_child("Value",true,false),String(reading.value));_put(refs.note,String(reading.get("delta","")))
		refs.row.tooltip_text=String(reading.get("tip",""))
		var bar:ProgressBar=refs.row.find_child("Bar",true,false) as ProgressBar
		if bar:bar.value=clampf(float(reading.get("meter",0.0)),0.0,1.0)
	return true

func _groups(groups: Array, _legend: Array, _own_name: String) -> void:
	_rule(self)
	grid = GridContainer.new()
	grid.name = "Figures"
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 24)
	add_child(grid)
	for group: Dictionary in groups:
		var section:=VBoxContainer.new();section.size_flags_horizontal=Control.SIZE_EXPAND_FILL;section.add_theme_constant_override("separation",4);grid.add_child(section)
		var title:=T.make_label(String(group.title).capitalize(),24,T.INK);title.add_theme_font_override("font",T.font("ui_strong"));section.add_child(title)
		var readings:Array=data.get("readings",[])
		if readings.size()>=4:
			if String(group.title).to_lower().contains("people"):_home_reading(section,readings[0])
			elif String(group.title).to_lower().contains("strength"):_home_reading(section,readings[3])
		for row: Dictionary in group.rows: section.add_child(_row(row))

## One fact, one line; a click opens the page that owns it.
func _row(row: Dictionary) -> Control:
	var key := String(row.key)
	var panel := PanelContainer.new()
	panel.name = "Row_" + key
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var idle := T.flat(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, 3)
	idle.content_margin_left = 4; idle.content_margin_right = 4; idle.content_margin_top = 10; idle.content_margin_bottom = 10
	idle.border_width_bottom = 1; idle.border_color = Color(T.RULE, 0.45)
	var lit: StyleBoxFlat = idle.duplicate(); lit.bg_color = T.GOLD_WASH
	panel.add_theme_stylebox_override("panel", idle)
	var action: Variant = row.get("on_open")
	if action is Callable and (action as Callable).is_valid():
		panel.focus_mode = Control.FOCUS_ALL
		panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		panel.gui_input.connect(func(event: InputEvent) -> void:
			var mouse := event as InputEventMouseButton
			if mouse and mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
				panel.accept_event(); (action as Callable).call()
			elif event.is_action_pressed("ui_accept"):
				panel.accept_event(); (action as Callable).call())
	panel.mouse_entered.connect(func() -> void: panel.add_theme_stylebox_override("panel", lit))
	panel.mouse_exited.connect(func() -> void: panel.add_theme_stylebox_override("panel", idle))
	var line := HBoxContainer.new(); line.add_theme_constant_override("separation", 8); line.mouse_filter = Control.MOUSE_FILTER_IGNORE; panel.add_child(line)
	var icon := TextureRect.new(); icon.texture = V.tinted(key, V.accent(key)); icon.custom_minimum_size = Vector2(18, 18)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER; icon.mouse_filter = Control.MOUSE_FILTER_IGNORE; line.add_child(icon)
	var label := T.make_label("", 16, T.BODY); label.name = "Name"; label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; label.mouse_filter = Control.MOUSE_FILTER_IGNORE; line.add_child(label)
	var value := T.make_label("", 16, T.INK); value.name = "Value"; value.add_theme_font_override("font", T.font("ui_strong"))
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT; value.mouse_filter = Control.MOUSE_FILTER_IGNORE; line.add_child(value)
	var refs := {"panel": panel, "name": label, "value": value, "bar": null, "note": null}
	_fill_row(refs, row)
	if not _page_refs.is_empty(): (_page_refs.rows as Array).append(refs)
	return panel

## The line's words; its note and the towns compared go in its pointer.
func _fill_row(refs: Dictionary, row: Dictionary) -> void:
	super._fill_row(refs, row)
	var more: PackedStringArray = []
	if String(row.get("note", "")) != "": more.append(String(row.note))
	for mark: Dictionary in row.get("marks", []):
		more.append("%s · %s · seen %s" % [String(mark.name), String(mark.words), String(mark.seen)])
	if not more.is_empty(): (refs.panel as Control).tooltip_text = String(row.get("tip", "")) + "\n" + "\n".join(more)
	var tone := String(row.get("note_tone", ""))
	(refs.value as Label).add_theme_color_override("font_color", tone_color(tone) if tone in ["bad", "warn"] else T.INK)

func _layout() -> void:
	if spread: spread.vertical = false
	if grid: grid.columns = 2 if size.x >= 680 else 1
