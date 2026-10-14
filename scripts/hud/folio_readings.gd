extends HBoxContainer
## The top bar's readings: for each, its mark, what it is, and its number with
## its unit ("FOOD · 29 days"), each as wide as its own words so nothing is cut
## short. A reading turns amber or red with its note; the pointer opens its
## card and a click opens its screen.
## No simulation reads here: the HUD hands over the day's formatted readings
## (command_rail_hud.gd kpi_readings) and drops the least urgent when the bar
## is too narrow for them all (needed_width).
const Tokens = preload("res://scripts/hud/hud_tokens.gd")
const Chip = preload("res://scripts/hud/kpi_detail_chip.gd")
const Folio = preload("res://scripts/hud/reference_folio.gd")
const TopbarInk = preload("res://scripts/hud/topbar_ink.gd")
const NavIcon = preload("res://scripts/hud/hud_chrome_icon.gd")
const WARNING_INK = Color("ffd39b")
const SHORTAGE_INK = Color("ffb6a8")
const CAPTION_SIZE := 10
const VALUE_SIZE := 18
const MARK := 17.0
const MARK_GAP := 5.0
const GAP := 12

signal reading_selected(section: String, sub: int)
signal reading_created(button: Button)

var entries: Dictionary = {}
var _signature := ""

func _ready() -> void:
	name = "TopBarReadings"
	add_theme_constant_override("separation", GAP)

## The width one reading needs: its mark, then the wider of its two lines.
static func reading_width(reading: Dictionary) -> float:
	var caption := Tokens.FONT_UI.get_string_size(String(reading.caption), HORIZONTAL_ALIGNMENT_LEFT, -1, CAPTION_SIZE).x
	var value := Tokens.font("voice").get_string_size(String(reading.value), HORIZONTAL_ALIGNMENT_LEFT, -1, VALUE_SIZE).x
	return ceilf(MARK + MARK_GAP + maxf(caption, value) + 4.0)

## The width the whole row needs to show `readings` in full.
static func needed_width(readings: Array[Dictionary]) -> float:
	var total := 0.0
	for reading: Dictionary in readings: total += reading_width(reading)
	return total + GAP * maxi(0, readings.size() - 1)

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
		entry.button.custom_minimum_size.x = reading_width(reading)
		var value_ink: Color = Folio.RAIL_TEXT
		if reading.note_color == Tokens.text_for(Tokens.RED): value_ink = SHORTAGE_INK
		elif reading.note_color == Tokens.text_for(Tokens.AMBER): value_ink = WARNING_INK
		entry.caption.add_theme_color_override("font_color", Color(Folio.RAIL_TEXT, 0.82))
		entry.value.add_theme_color_override("font_color", value_ink)
		entry.mark.set_icon_color(value_ink)
		entry.button.accessibility_name = "%s: %s. %s" % [reading.caption, reading.value, reading.note]

func _make_reading(reading: Dictionary) -> void:
	var button := Chip.new()
	button.metric_id = String(reading.id)
	button.name = "Reading" + String(reading.id).capitalize()
	button.custom_minimum_size = Vector2(reading_width(reading), 40)
	button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	var focus := Tokens.flat(Color.TRANSPARENT)
	focus.border_color = Folio.GOLD
	focus.border_width_bottom = 1
	button.add_theme_stylebox_override("hover", focus)
	button.add_theme_stylebox_override("focus", focus)
	button.add_theme_stylebox_override("pressed", focus)
	button.pressed.connect(func() -> void: reading_selected.emit(String(reading.section), int(reading.sub)))
	add_child(button)
	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.add_theme_constant_override("separation", int(MARK_GAP))
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(row)
	var mark := NavIcon.new(String(reading.id))
	mark.plain = true
	mark.custom_minimum_size = Vector2(MARK, MARK)
	mark.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mark.set_icon_color(Folio.RAIL_TEXT)
	row.add_child(mark)
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", -3)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(column)
	var caption := Tokens.make_label(String(reading.caption), CAPTION_SIZE, Folio.RAIL_TEXT)
	caption.add_theme_font_size_override("font_size", CAPTION_SIZE)
	var value := Tokens.make_label(String(reading.value), VALUE_SIZE, Folio.RAIL_TEXT)
	value.add_theme_font_override("font", Tokens.font("voice"))
	value.add_theme_font_size_override("font_size", VALUE_SIZE)
	for label: Label in [caption, value]:
		TopbarInk.apply(label)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		column.add_child(label)
	entries[String(reading.id)] = {"button":button, "caption":caption, "value":value, "mark":mark, "note":String(reading.note)}
	reading_created.emit(button)
