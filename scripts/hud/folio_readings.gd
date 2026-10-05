extends HBoxContainer
## Compact top-bar projection of the HUD's already-formatted live readings.
## No simulation reads here: the original strip remains the authority.
const Tokens = preload("res://scripts/hud/hud_tokens.gd")
const Chip = preload("res://scripts/hud/kpi_detail_chip.gd")

signal reading_selected(section: String, sub: int)
signal reading_created(button: Button)

var entries: Dictionary = {}
var _signature := ""

func _ready() -> void:
	name = "TopBarReadings"
	add_theme_constant_override("separation", 10)

func show_readings(readings: Array[Dictionary]) -> void:
	var signature := str(hash(readings)) + Tokens.color_mode
	if signature == _signature: return
	_signature = signature
	var wanted: Array[String] = []
	for reading: Dictionary in readings: wanted.append(String(reading.id))
	for id: String in entries:
		if id not in wanted: entries[id].button.visible = false
	for reading: Dictionary in readings:
		var id := String(reading.id)
		if not entries.has(id): _make_reading(reading)
		var entry: Dictionary = entries[id]
		entry.button.visible = true
		var index := wanted.find(id)
		if entry.button.get_index() != index: move_child(entry.button, index)
		entry.caption.text = String(reading.caption)
		entry.value.text = String(reading.value)
		entry.note = String(reading.note)
		var warning: bool = reading.note_color in [Tokens.text_for(Tokens.RED), Tokens.text_for(Tokens.AMBER)]
		entry.caption.add_theme_color_override("font_color", Tokens.INK_MUTED)
		entry.value.add_theme_color_override("font_color", reading.note_color if warning else Tokens.INK)
		entry.button.accessibility_name = "%s: %s. %s" % [reading.caption, reading.value, reading.note]

func _make_reading(reading: Dictionary) -> void:
	var button := Chip.new()
	button.metric_id = String(reading.id)
	button.name = "Reading" + String(reading.id).capitalize()
	button.custom_minimum_size = Vector2(56, 40)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	var focus := Tokens.flat(Color.TRANSPARENT)
	focus.border_color = Tokens.GOLD
	focus.border_width_bottom = 1
	button.add_theme_stylebox_override("hover", focus)
	button.add_theme_stylebox_override("focus", focus)
	button.add_theme_stylebox_override("pressed", focus)
	button.pressed.connect(func() -> void: reading_selected.emit(String(reading.section), int(reading.sub)))
	add_child(button)
	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", -2)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(column)
	var caption := Tokens.make_label(String(reading.caption), 10, Tokens.INK_MUTED)
	caption.add_theme_font_size_override("font_size", 10)
	var value := Tokens.make_label(String(reading.value), 20, Tokens.INK)
	value.add_theme_font_override("font", Tokens.font("voice"))
	for label: Label in [caption, value]:
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		column.add_child(label)
	entries[String(reading.id)] = {"button":button, "caption":caption, "value":value, "note":String(reading.note)}
	reading_created.emit(button)
