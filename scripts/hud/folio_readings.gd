extends HBoxContainer
## Compact top-bar projection of the HUD's already-formatted live readings.
## No simulation reads here: the original strip remains the authority.
const Tokens = preload("res://scripts/hud/hud_tokens.gd")
const Chip = preload("res://scripts/hud/kpi_detail_chip.gd")
const Folio = preload("res://scripts/hud/reference_folio.gd")
const TopbarInk = preload("res://scripts/hud/topbar_ink.gd")
const WARNING_INK = Color("ffd39b")
const SHORTAGE_INK = Color("ffb6a8")

signal reading_selected(section: String, sub: int)
signal reading_created(button: Button)

var entries: Dictionary = {}
var _signature := ""

func _ready() -> void:
	name = "TopBarReadings"
	add_theme_constant_override("separation", 8)

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
		entry.full_value = String(reading.value)
		_fit_value(entry)
		entry.note = String(reading.note)
		var value_ink: Color = TopbarInk.TEXT
		if reading.note_color == Tokens.text_for(Tokens.RED): value_ink = SHORTAGE_INK
		elif reading.note_color == Tokens.text_for(Tokens.AMBER): value_ink = WARNING_INK
		entry.caption.add_theme_color_override("font_color", TopbarInk.TEXT)
		entry.value.add_theme_color_override("font_color", value_ink)
		entry.button.accessibility_name = "%s: %s. %s" % [reading.caption, reading.value, reading.note]

func _make_reading(reading: Dictionary) -> void:
	var button := Chip.new()
	button.metric_id = String(reading.id)
	button.name = "Reading" + String(reading.id).capitalize()
	button.custom_minimum_size = Vector2(56, 40)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	var focus := Tokens.flat(Color.TRANSPARENT)
	focus.border_color = Folio.GOLD
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
	var caption := Tokens.make_label(String(reading.caption), 12, TopbarInk.TEXT)
	caption.add_theme_font_size_override("font_size", 12)
	caption.add_theme_font_override("font", Tokens.font("ui_strong"))
	var value := Tokens.make_label(String(reading.value), 24, TopbarInk.TEXT)
	value.add_theme_font_override("font", Tokens.font("voice_bold"))
	for label: Label in [caption, value]:
		TopbarInk.apply(label)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		column.add_child(label)
	entries[String(reading.id)] = {"button":button, "caption":caption, "value":value, "note":String(reading.note), "full_value":String(reading.value)}
	button.resized.connect(func() -> void: _fit_value(entries[String(reading.id)]))
	reading_created.emit(button)

func _fit_value(entry: Dictionary) -> void:
	var label: Label = entry.value
	var full: String = entry.full_value
	var font := label.get_theme_font("font")
	var size := label.get_theme_font_size("font_size")
	var available: float = entry.button.size.x
	# Keep the full reading in the hover/accessibility account. At compact widths,
	# shorten familiar units before the text would lose its last few letters.
	if available > 0 and font.get_string_size(full, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > available:
		label.text = full.replace(" souls", "").replace(" known", "").replace(" winters", " yr").replace(" days", " d").replace(" years", " yr").replace(" hands", "")
		if font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > available:
			label.text = label.text.replace(" yr", "y").replace(" d", "d")
	else:
		label.text = full
