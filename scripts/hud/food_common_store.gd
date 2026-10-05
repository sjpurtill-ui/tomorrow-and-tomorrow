extends "res://scripts/hud/purse_board.gd"
## Food keeps a concise reserve summary; its real allocations remain available.
var details: VBoxContainer
var disclosure: Button

func setup(block: Dictionary = {}) -> void:
	super.setup(block)
	var after := head_box.get_index()
	var children := get_children()
	disclosure = Button.new()
	disclosure.name = "ReserveDetails"
	disclosure.text = "Contributions & use"
	disclosure.toggle_mode = true
	disclosure.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	add_child(disclosure)
	details = VBoxContainer.new()
	details.name = "ReserveAllocations"
	details.add_theme_constant_override("separation", 10)
	add_child(details)
	for index in children.size():
		var child: Node = children[index]
		if index > after and child != feedback: child.reparent(details)
	details.hide()
	disclosure.toggled.connect(func(opened: bool): details.visible = opened)

func _build_head(forecast: Dictionary, _season: Dictionary) -> void:
	_clear(head_box)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	head_box.add_child(row)
	var value := _answer(Purse.amount_text(Purse.balance()), 24)
	value.autowrap_mode = TextServer.AUTOWRAP_OFF
	value.add_theme_font_override("font", T.font("voice"))
	value.name = "StoreAnswer"
	row.add_child(value)
	var net := float(forecast.net)
	var change := _line(("+" if net >= 0 else "−") + Purse.number(absf(net)) + " / season", 15, T.GREEN_TEXT if net >= 0 else T.RED_TEXT)
	change.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	change.tooltip_text = "Expected per season: %s in; %s out." % [Purse.amount_text(float(forecast["in"])), Purse.amount_text(float(forecast.out))]
	row.add_child(change)
	head_box.add_child(_line("Set aside for shared spending; separate from town stores.", 13, T.INK_MUTED, true))

func _build_sources(sources: Dictionary) -> void:
	var header := sources_box.get_parent().get_child(sources_box.get_index() - 1) as Label
	var several := (sources.towns as Array).size() > 1 or float(sources.rich) > 0 or float(sources.deposits) > 0 or float(sources.get("charter", 0)) > 0
	if several:
		if header: header.text = "CONTRIBUTIONS"; header.show()
		sources_box.show()
		super._build_sources(sources)
		return
	_clear(sources_box)
	var uncollected := float(sources.evaded)
	var unreached := float(sources.get("unreached", 0))
	var left_with_towns := float(sources.get("short", 0))
	sources_box.visible = maxf(uncollected, maxf(unreached, left_with_towns)) >= 0.5
	if header:
		header.text = "UNCOLLECTED CONTRIBUTIONS"
		header.visible = sources_box.visible
	if uncollected >= 0.5:
		sources_box.add_child(_line("%s kept back by households per season." % Purse.amount_text(uncollected), 13, T.INK_MUTED, true))

	if unreached >= 0.5: sources_box.add_child(_line("%s beyond the keepers' reach per season." % Purse.amount_text(unreached), 13, T.INK_MUTED, true))
	if left_with_towns >= 0.5: sources_box.add_child(_line("%s left with towns that had none to spare." % Purse.amount_text(left_with_towns), 13, T.INK_MUTED, true))

func view_state() -> Dictionary:
	return {"reserve_open":disclosure != null and disclosure.button_pressed}

func restore_view_state(state: Dictionary) -> void:
	if disclosure:
		disclosure.set_pressed_no_signal(bool(state.get("reserve_open", false)))
		details.visible = disclosure.button_pressed
