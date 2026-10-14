extends "res://scripts/hud/settlement_overview.gd"
## HOME › OVERVIEW, compact: the six tiles under the tabs carry the headline
## figures (dock_content_settlement.gd _glance_tiles) and the top bar the
## people's own; this page is the rest, each fact one line (its mark, its
## name, its value at the right), flowing into two or three columns as the
## page widens. A row's note and how the towns our scouts have seen compare
## are in its pointer. The leader is one row with the controls that change
## the town's work beside them. No figure here repeats a tile or the top bar.

func _groups(groups: Array, _legend: Array, _own_name: String) -> void:
	_rule(self)
	grid = GridContainer.new()
	grid.name = "Figures"
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 0)
	add_child(grid)
	for group: Dictionary in groups:
		for row: Dictionary in group.rows: grid.add_child(_row(row))

## One fact, one line; a click opens the page that owns it.
func _row(row: Dictionary) -> Control:
	var key := String(row.key)
	var panel := PanelContainer.new()
	panel.name = "Row_" + key
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var idle := T.flat(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, 3)
	idle.content_margin_left = 4; idle.content_margin_right = 4; idle.content_margin_top = 5; idle.content_margin_bottom = 5
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
	var label := T.make_label("", 13, T.BODY); label.name = "Name"; label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.clip_text = true; label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS; label.mouse_filter = Control.MOUSE_FILTER_IGNORE; line.add_child(label)
	var value := T.make_label("", 13, T.INK); value.name = "Value"; value.add_theme_font_override("font", T.font("ui_strong"))
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
	if grid: grid.columns = 3 if size.x >= 1050 else (2 if size.x >= 520 else 1)
