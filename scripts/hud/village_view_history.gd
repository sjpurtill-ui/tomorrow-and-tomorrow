extends VBoxContainer
const T := preload("res://scripts/hud/hud_tokens.gd")
const Record := preload("res://scripts/hud/village_view_record.gd")
var entries: Array = []
var selected := -1
var picture: TextureRect
var words: Label
var dates: OptionButton

func setup(block: Dictionary) -> void:
	theme = T.control_theme()
	name = "VillageViewHistory"
	add_theme_constant_override("separation", 12)
	entries = Record.views(GameState.settlement_portrait_history, String(block.get("city_id", "")))
	var title := T.make_label("Our home through the years", 28, T.GOLD_TEXT)
	title.add_theme_font_override("font", T.font("voice"))
	add_child(title)
	var note := T.make_label("Views recorded during your visits. Earlier years are not reconstructed.", 14, T.TEXT_SOFT)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(note)
	if entries.is_empty():
		add_child(T.make_label("Open Overview to record the first view of this settlement.", 16, T.TEXT_SOFT))
		return
	picture = TextureRect.new()
	picture.custom_minimum_size = Vector2(280, 360)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	add_child(picture)
	var controls := HBoxContainer.new()
	controls.add_theme_constant_override("separation", 16)
	add_child(controls)
	var earlier := Button.new(); earlier.name = "EarlierView"; earlier.text = "← Earlier"
	earlier.pressed.connect(func() -> void: _show_view(maxi(0, selected - 1)))
	controls.add_child(earlier)
	dates = OptionButton.new(); dates.name = "RecordedDates"
	dates.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for entry: Dictionary in entries: dates.add_item(Record.date(int(entry.day)))
	dates.item_selected.connect(_show_view)
	controls.add_child(dates)
	var later := Button.new(); later.name = "LaterView"; later.text = "Later →"
	later.pressed.connect(func() -> void: _show_view(mini(entries.size() - 1, selected + 1)))
	controls.add_child(later)
	words = T.make_label("", 16, T.BODY)
	words.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(words)
	_show_view(entries.size() - 1)

func _show_view(index: int) -> void:
	if entries.is_empty(): return
	selected = clampi(index, 0, entries.size() - 1)
	var entry: Dictionary = entries[selected]
	var image := Image.new()
	if image.load_webp_from_buffer(entry.get("image", PackedByteArray())) == OK:
		picture.texture = ImageTexture.create_from_image(image)
	else: picture.texture = null
	dates.select(selected)
	words.text = "%s · %d people · %d completed works · %.2f ha of fields" % [String(entry.reason), int(entry.population), int(entry.works), float(entry.field_ha)]
	(find_child("EarlierView", true, false) as Button).disabled = selected == 0
	(find_child("LaterView", true, false) as Button).disabled = selected == entries.size() - 1

func view_state() -> Dictionary:
	return {"day": int((entries[selected] as Dictionary).day) if selected >= 0 else -1}

func restore_view_state(state: Dictionary) -> void:
	for i in entries.size():
		if int((entries[i] as Dictionary).day) == int(state.get("day", -1)):
			_show_view(i); return
