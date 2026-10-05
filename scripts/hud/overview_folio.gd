extends "res://scripts/hud/settlement_overview.gd"
## The same town ledger and callbacks, presented as an illustrated folio.
const Base := preload("res://scripts/hud/settlement_overview.gd")
const TownArt := preload("res://scripts/hud/overview_town_art.gd")
var comparing := false
var leader_spread: BoxContainer

func _sketch(drawing: Dictionary, parent: Node) -> void:
	sketch = PaintedTown.new()
	sketch.name = "TownSketch"
	sketch.data = drawing
	sketch.custom_minimum_size = Vector2(280, 420)
	sketch.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sketch.size_flags_stretch_ratio = 1.4
	parent.add_child(sketch)

func _leader(block: Dictionary, parent: Node) -> void:
	super._leader(block, parent)
	var column := parent.get_child(parent.get_child_count() - 1) as VBoxContainer
	var pieces := column.get_children()
	leader_spread = BoxContainer.new()
	leader_spread.add_theme_constant_override("separation", 26)
	column.add_child(leader_spread)
	var head := pieces[0] as Control
	head.custom_minimum_size.x = 280
	head.reparent(leader_spread)
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.add_theme_constant_override("separation", 8)
	leader_spread.add_child(words)
	for index in range(1, pieces.size()): pieces[index].reparent(words)

func _groups(groups: Array, legend: Array, _own_name: String) -> void:
	_rule(self)
	if not legend.is_empty():
		var compare := Button.new()
		compare.name = "CompareTowns"
		compare.text = "Compare with towns we know +"
		compare.toggle_mode = true
		compare.flat = true
		compare.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		compare.add_theme_font_override("font", T.font("voice"))
		compare.add_theme_font_size_override("font_size", 17)
		add_child(compare)
		compare.toggled.connect(func(open: bool) -> void:
			comparing = open
			compare.text = "Close town comparisons −" if open else "Compare with towns we know +"
			for refs: Dictionary in _page_refs.rows:
				if refs.has("comparison"): refs.comparison.visible = open and not String(refs.comparison.text).is_empty())
	grid = GridContainer.new()
	grid.name = "Figures"
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 32)
	grid.add_theme_constant_override("v_separation", 28)
	add_child(grid)
	for group: Dictionary in groups:
		var column := VBoxContainer.new()
		column.name = "Group_" + String(group.title).to_pascal_case()
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		column.add_theme_constant_override("separation", 6)
		grid.add_child(column)
		var heading := _voice(T.sentence_case(String(group.title)), 25)
		heading.add_theme_color_override("font_color", T.GOLD_TEXT)
		column.add_child(heading)
		_rule(column)
		for row: Dictionary in group.rows: column.add_child(_row(row))

func _row(row: Dictionary) -> Control:
	# Keep the existing focus, mouse, keyboard and owning-page action wiring.
	var panel := super._row(row)
	var refs: Dictionary = _page_refs.rows.back()
	if refs.bar != null:
		var bar: Control = refs.bar
		bar.get_parent().remove_child(bar)
		bar.free()
		refs.bar = null
	var title: Label = refs.name
	title.clip_text = false
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_override("font", T.font("voice"))
	title.add_theme_font_size_override("font_size", 17)
	title.add_theme_color_override("font_color", T.TEXT_SOFT)
	var value: Label = refs.value
	var body := title.get_parent().get_parent() as VBoxContainer
	value.reparent(body)
	body.move_child(value, 1)
	value.add_theme_font_override("font", T.font("voice"))
	value.add_theme_font_size_override("font_size", 25)
	value.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if refs.note != null:
		(refs.note as Label).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		(refs.note as Label).add_theme_font_size_override("font_size", 13)
	var comparison := Label.new()
	comparison.name = "Comparison"
	comparison.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	comparison.add_theme_font_size_override("font_size", 13)
	comparison.add_theme_color_override("font_color", T.TEXT_SOFT)
	comparison.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(comparison)
	refs["comparison"] = comparison
	_fill_row(refs, row)
	return panel

func _fill_row(refs: Dictionary, row: Dictionary) -> void:
	super._fill_row(refs, row)
	if refs.has("comparison"):
		var lines: PackedStringArray = []
		for mark: Dictionary in row.get("marks", []):
			lines.append("%s · %s · seen %s" % [String(mark.name), String(mark.words), String(mark.seen)])
		(refs.comparison as Label).text = "\n".join(lines)
		(refs.comparison as Control).visible = comparing and not lines.is_empty()

func view_state() -> Dictionary:
	return {"comparing": comparing}

func restore_view_state(state: Dictionary) -> void:
	var button := find_child("CompareTowns", true, false) as Button
	if button != null: button.button_pressed = bool(state.get("comparing", false))

func _layout() -> void:
	if spread: spread.vertical = true
	if leader_spread: leader_spread.vertical = size.x < 620
	if sketch: sketch.custom_minimum_size.y = 420 if size.x >= 690 else 310
	if grid: grid.columns = 2 if size.x >= 540 else 1

class PaintedTown extends Base.OwnSketch:
	var painting: TextureRect
	func _ready() -> void:
		painting = TextureRect.new()
		painting.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		painting.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		painting.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(painting)
	func _draw() -> void:
		var art := TownArt.texture(data)
		if painting != null:
			painting.texture = art
			painting.size = Vector2(size.x, size.y - 32)
		var caption := String(data.get("held_caption", ""))
		draw_string(T.font("voice"), Vector2(0, size.y - 8), caption, HORIZONTAL_ALIGNMENT_CENTER, size.x, 16, T.GOLD_TEXT)
