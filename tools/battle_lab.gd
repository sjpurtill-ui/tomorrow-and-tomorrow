extends Control

const COMBAT_SIMULATOR_SCRIPT := preload("res://scripts/combat_simulator.gd")
const GAME_STATE_SCRIPT := preload("res://scripts/game_state.gd")
const COMMANDER_PORTRAITS := preload("res://assets/ui/commander_portraits.png")
const ATTACKER_COMMANDERS := [
	{"name":"Mara Vale","command":0.76,"tactics":0.68,"logistics":0.54,"resolve":0.82},
	{"name":"Tarek Orin","command":0.61,"tactics":0.65,"logistics":0.48,"resolve":0.66},
	{"name":"Sela Kest","command":0.49,"tactics":0.52,"logistics":0.57,"resolve":0.58}
]
const DEFENDER_COMMANDERS := [
	{"name":"Rovan Merek","command":0.72,"tactics":0.74,"logistics":0.58,"resolve":0.76},
	{"name":"Asha Halden","command":0.56,"tactics":0.57,"logistics":0.49,"resolve":0.61},
	{"name":"Cassian Tor","command":0.45,"tactics":0.46,"logistics":0.42,"resolve":0.52}
]

var simulator: RefCounted
var attacker_troops: SpinBox
var defender_troops: SpinBox
var attacker_spears: SpinBox
var defender_spears: SpinBox
var attacker_archers: SpinBox
var defender_archers: SpinBox
var attacker_attack: SpinBox
var defender_attack: SpinBox
var attacker_morale: SpinBox
var defender_morale: SpinBox
var attacker_readiness: Label
var defender_readiness: Label
var terrain_defense: SpinBox
var seed_input: SpinBox
var outcome_label: Label
var attacker_remaining_bar: ProgressBar
var defender_remaining_bar: ProgressBar
var attacker_summary: Label
var defender_summary: Label
var results: RichTextLabel
var strength_bar: ProgressBar
var strength_label: Label
var run_button: Button
var push_button: Button
var retreat_button: Button
var battle_timer: Timer
var live_attacker: Dictionary = {}
var live_defender: Dictionary = {}
var live_round := 0
var battle_active := false
var push_next_round := false
var round_records: Array[Dictionary] = []
var attacker_cards: Array[Dictionary] = []
var defender_cards: Array[Dictionary] = []
var live_attacker_initial := 1
var live_defender_initial := 1
var attacker_header: Label
var defender_header: Label
var attacker_condition_meter: Dictionary
var defender_condition_meter: Dictionary
var attacker_roster: Array[Dictionary] = []
var defender_roster: Array[Dictionary] = []
var attacker_roster_state: Node
var defender_roster_state: Node
var preparation_day:=0
var preparation_label: Label
var prepare_one_button: Button
var prepare_week_button: Button
var attacker_commander_select: OptionButton
var defender_commander_select: OptionButton
var attacker_commander_portrait: TextureRect
var defender_commander_portrait: TextureRect
var attacker_commander_stats: Label
var defender_commander_stats: Label
var prisoner_decision_row: VBoxContainer
var prisoner_decision_label: Label
var prisoner_action_select: OptionButton
var general_action_select: OptionButton
var spoils_action_select: OptionButton
var pending_prisoner_decision: Dictionary={}


func _ready() -> void:
	simulator = COMBAT_SIMULATOR_SCRIPT.new()
	_build_interface()
	_preview_battle()


func _build_interface() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = Color("#171b21")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 6)
	add_child(margin)

	var layout := VBoxContainer.new()
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_theme_constant_override("separation", 4)
	margin.add_child(layout)

	var title := Label.new()
	title.text = "BATTLE LAB"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color("#e8d5a8"))
	layout.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "An isolated combat sandbox — no campaign data is read or changed."
	subtitle.add_theme_font_size_override("font_size", 12)
	subtitle.add_theme_color_override("font_color", Color("#9ca9b7"))
	subtitle.visible = false
	layout.add_child(subtitle)

	var strength_card := VBoxContainer.new()
	strength_card.add_theme_constant_override("separation", 5)
	_add_card(layout, strength_card, Color("#8b7650"))
	strength_label = Label.new()
	strength_label.text = "RELATIVE STRENGTH"
	strength_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	strength_label.add_theme_font_size_override("font_size", 17)
	strength_card.add_child(strength_label)
	strength_bar = ProgressBar.new()
	strength_bar.min_value = 0
	strength_bar.max_value = 100
	strength_bar.value = 50
	strength_bar.show_percentage = false
	strength_bar.custom_minimum_size.y = 18
	var strength_fill := StyleBoxFlat.new()
	strength_fill.bg_color = Color("#d98272")
	strength_bar.add_theme_stylebox_override("fill", strength_fill)
	var strength_back := StyleBoxFlat.new()
	strength_back.bg_color = Color("#72a7d9")
	strength_bar.add_theme_stylebox_override("background", strength_back)
	strength_card.add_child(strength_bar)

	var sides := HBoxContainer.new()
	sides.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sides.add_theme_constant_override("separation", 6)
	sides.clip_contents = true
	layout.add_child(sides)

	var attacker_panel := VBoxContainer.new()
	attacker_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	attacker_panel.size_flags_stretch_ratio = 1.0
	attacker_panel.add_theme_constant_override("separation", 5)
	_add_card(sides, attacker_panel, Color("#d98272"))
	attacker_header = _add_section(attacker_panel, "ATTACKER — River Host", Color("#d98272"), HORIZONTAL_ALIGNMENT_LEFT)
	var attacker_commander_card:=_add_commander_card(attacker_panel,ATTACKER_COMMANDERS,0,Color("#d98272"))
	attacker_commander_select=attacker_commander_card.select
	attacker_commander_portrait=attacker_commander_card.portrait
	attacker_commander_stats=attacker_commander_card.stats
	attacker_condition_meter = _add_condition_meter(attacker_panel)
	attacker_cards.append(_add_unit_input(attacker_panel, "res://assets/ui/combat_levy.svg", "LEVY", "Improvised arms", 50, Color("#d98272"), "levy", "improvised"))
	attacker_cards.append(_add_unit_input(attacker_panel, "res://assets/ui/combat_spear.svg", "LINE INFANTRY", "Spears + shields", 50, Color("#d98272"), "line_infantry", "spear"))
	attacker_cards.append(_add_unit_input(attacker_panel, "res://assets/ui/combat_archer.svg", "SKIRMISHERS", "Bows", 20, Color("#d98272"), "skirmisher", "bow"))
	attacker_troops = attacker_cards[0].input
	attacker_spears = attacker_cards[1].input
	attacker_archers = attacker_cards[2].input
	var attacker_modifiers := HBoxContainer.new()
	attacker_modifiers.add_theme_constant_override("separation", 8)
	attacker_panel.add_child(attacker_modifiers)
	attacker_attack = _add_compact_number(attacker_modifiers, "⚔ ATTACK", 1.0)
	attacker_morale = _add_compact_number(attacker_modifiers, "♥ MORALE", 1.0)
	attacker_readiness = _add_compact_display(attacker_modifiers, "◆ READINESS")

	var battlefield_panel := VBoxContainer.new()
	battlefield_panel.custom_minimum_size.x = 190
	battlefield_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	battlefield_panel.size_flags_stretch_ratio = 0.62
	battlefield_panel.add_theme_constant_override("separation", 5)
	_add_card(sides, battlefield_panel, Color("#d3b46f"))
	_add_section(battlefield_panel, "◆  BATTLEFIELD  ◆", Color("#d3b46f"), HORIZONTAL_ALIGNMENT_CENTER)
	terrain_defense = _add_number(battlefield_panel, "Defender terrain", 1.0, 0.5, 2.0, 0.05)
	seed_input = _add_number(battlefield_panel, "Seed", 42, 0, 2147483647, 1)
	var preparation_row:=HBoxContainer.new()
	preparation_row.add_theme_constant_override("separation",4)
	battlefield_panel.add_child(preparation_row)
	preparation_label=Label.new()
	preparation_label.text="DAY 0 • +6 EQ / +4 MEN / +12 ARW"
	preparation_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	preparation_label.add_theme_font_size_override("font_size",11)
	preparation_label.add_theme_color_override("font_color",Color("#d3b46f"))
	preparation_row.add_child(preparation_label)
	prepare_one_button=Button.new()
	prepare_one_button.text="+1 DAY"
	prepare_one_button.pressed.connect(func()->void: _advance_preparation(1))
	preparation_row.add_child(prepare_one_button)
	prepare_week_button=Button.new()
	prepare_week_button.text="+7"
	prepare_week_button.pressed.connect(func()->void: _advance_preparation(7))
	preparation_row.add_child(prepare_week_button)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 8)
	battlefield_panel.add_child(buttons)
	run_button = Button.new()
	run_button.text = "▶  START BATTLE"
	run_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	run_button.pressed.connect(_toggle_battle)
	buttons.add_child(run_button)
	var new_seed_button := Button.new()
	new_seed_button.text = "⟳"
	new_seed_button.tooltip_text = "Generate a new battle seed"
	new_seed_button.pressed.connect(_new_seed)
	buttons.add_child(new_seed_button)
	push_button = Button.new()
	push_button.text = "⚔  PUSH HARDER"
	push_button.disabled = true
	push_button.tooltip_text = "Boost attack next round, but sacrifice defense."
	push_button.pressed.connect(_push_harder)
	battlefield_panel.add_child(push_button)
	retreat_button = Button.new()
	retreat_button.text = "◀  RETREAT"
	retreat_button.disabled = true
	retreat_button.tooltip_text = "End the battle and preserve the surviving force."
	retreat_button.pressed.connect(_retreat)
	battlefield_panel.add_child(retreat_button)
	prisoner_decision_row=VBoxContainer.new()
	prisoner_decision_row.visible=false
	prisoner_decision_row.add_theme_constant_override("separation",3)
	battlefield_panel.add_child(prisoner_decision_row)
	prisoner_decision_label=Label.new()
	prisoner_decision_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	prisoner_decision_label.add_theme_font_size_override("font_size",11)
	prisoner_decision_label.add_theme_color_override("font_color",Color("#d3b46f"))
	prisoner_decision_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	prisoner_decision_row.add_child(prisoner_decision_label)
	var prisoner_controls:=GridContainer.new()
	prisoner_controls.columns=1
	prisoner_controls.add_theme_constant_override("separation",3)
	prisoner_decision_row.add_child(prisoner_controls)
	prisoner_action_select=OptionButton.new()
	prisoner_action_select.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	for action in ["Hold","Release","Ransom","Exchange","Parole","Recruit volunteers","Enslave","Execute"]:
		prisoner_action_select.add_item(action)
	prisoner_controls.add_child(prisoner_action_select)
	general_action_select=OptionButton.new()
	general_action_select.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	for action in ["Hold general","Release general","Ransom general","Exile general","Execute general"]:
		general_action_select.add_item(action)
	prisoner_controls.add_child(general_action_select)
	spoils_action_select=OptionButton.new()
	spoils_action_select.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	for action in ["Army stores","Reward troops","State treasury","Return property","Unrestricted plunder"]:
		spoils_action_select.add_item(action)
	prisoner_controls.add_child(spoils_action_select)
	var resolve_captives:=Button.new()
	resolve_captives.text="RESOLVE"
	resolve_captives.add_theme_font_size_override("font_size",10)
	resolve_captives.pressed.connect(func()->void: _resolve_prisoners(String(prisoner_action_select.get_item_text(prisoner_action_select.selected)).to_lower(),String(general_action_select.get_item_text(general_action_select.selected)).to_lower(),String(spoils_action_select.get_item_text(spoils_action_select.selected)).to_lower()))
	prisoner_controls.add_child(resolve_captives)

	var defender_panel := VBoxContainer.new()
	defender_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	defender_panel.size_flags_stretch_ratio = 1.0
	defender_panel.add_theme_constant_override("separation", 5)
	_add_card(sides, defender_panel, Color("#72a7d9"))
	defender_header = _add_section(defender_panel, "HILL GUARD — DEFENDER", Color("#72a7d9"), HORIZONTAL_ALIGNMENT_RIGHT)
	var defender_commander_card:=_add_commander_card(defender_panel,DEFENDER_COMMANDERS,3,Color("#72a7d9"))
	defender_commander_select=defender_commander_card.select
	defender_commander_portrait=defender_commander_card.portrait
	defender_commander_stats=defender_commander_card.stats
	_refresh_commander_cards()
	defender_condition_meter = _add_condition_meter(defender_panel)
	defender_cards.append(_add_unit_input(defender_panel, "res://assets/ui/combat_levy.svg", "LEVY", "Improvised arms", 30, Color("#72a7d9"), "levy", "improvised"))
	defender_cards.append(_add_unit_input(defender_panel, "res://assets/ui/combat_spear.svg", "LINE INFANTRY", "Spears + shields", 50, Color("#72a7d9"), "line_infantry", "spear"))
	defender_cards.append(_add_unit_input(defender_panel, "res://assets/ui/combat_archer.svg", "SKIRMISHERS", "Bows", 20, Color("#72a7d9"), "skirmisher", "bow"))
	defender_troops = defender_cards[0].input
	defender_spears = defender_cards[1].input
	defender_archers = defender_cards[2].input
	var defender_modifiers := HBoxContainer.new()
	defender_modifiers.add_theme_constant_override("separation", 8)
	defender_panel.add_child(defender_modifiers)
	defender_attack = _add_compact_number(defender_modifiers, "⚔ ATTACK", 1.0)
	defender_morale = _add_compact_number(defender_modifiers, "♥ MORALE", 1.0)
	defender_readiness = _add_compact_display(defender_modifiers, "◆ READINESS")

	var summary_card := VBoxContainer.new()
	summary_card.add_theme_constant_override("separation", 7)
	_add_card(layout, summary_card, Color("#65717e"))
	outcome_label = Label.new()
	outcome_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	outcome_label.add_theme_font_size_override("font_size", 24)
	outcome_label.add_theme_color_override("font_color", Color("#e8d5a8"))
	summary_card.add_child(outcome_label)
	var summaries := HBoxContainer.new()
	summaries.add_theme_constant_override("separation", 24)
	summary_card.add_child(summaries)
	var attacker_status := VBoxContainer.new()
	attacker_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summaries.add_child(attacker_status)
	attacker_summary = Label.new()
	attacker_summary.add_theme_color_override("font_color", Color("#efaa9d"))
	attacker_status.add_child(attacker_summary)
	attacker_remaining_bar = _make_survivor_bar(Color("#d98272"))
	attacker_status.add_child(attacker_remaining_bar)
	var defender_status := VBoxContainer.new()
	defender_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summaries.add_child(defender_status)
	defender_summary = Label.new()
	defender_summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	defender_summary.add_theme_color_override("font_color", Color("#9dc9ef"))
	defender_status.add_child(defender_summary)
	defender_remaining_bar = _make_survivor_bar(Color("#72a7d9"))
	defender_status.add_child(defender_remaining_bar)

	results = RichTextLabel.new()
	results.bbcode_enabled = true
	results.fit_content = false
	results.scroll_active = false
	results.custom_minimum_size.y = 68
	results.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	results.size_flags_vertical = Control.SIZE_EXPAND_FILL
	results.add_theme_font_size_override("normal_font_size", 12)
	results.add_theme_color_override("default_color", Color("#d6dde5"))
	battlefield_panel.add_child(results)

	battle_timer = Timer.new()
	battle_timer.wait_time = 0.9
	battle_timer.timeout.connect(_advance_round)
	add_child(battle_timer)


func _add_card(parent: Container, content: Control, accent: Color) -> void:
	var card := PanelContainer.new()
	card.size_flags_horizontal = content.size_flags_horizontal
	card.size_flags_vertical = content.size_flags_vertical
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#222831")
	style.border_color = accent.darkened(0.20)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	card.add_theme_stylebox_override("panel", style)
	parent.add_child(card)
	card.add_child(content)


func _make_survivor_bar(color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.min_value = 0
	bar.max_value = 100
	bar.value = 100
	bar.show_percentage = false
	bar.custom_minimum_size.y = 15
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(5)
	bar.add_theme_stylebox_override("fill", fill)
	var background := StyleBoxFlat.new()
	background.bg_color = Color("#11151a")
	background.set_corner_radius_all(5)
	bar.add_theme_stylebox_override("background", background)
	return bar


func _add_condition_meter(parent: VBoxContainer) -> Dictionary:
	var title := Label.new()
	title.text = "ARMY CONDITION"
	title.clip_text = true
	title.add_theme_font_size_override("font_size", 11)
	title.add_theme_color_override("font_color", Color("#9da8b3"))
	parent.add_child(title)
	var bar := HBoxContainer.new()
	bar.custom_minimum_size.y = 12
	bar.add_theme_constant_override("separation", 2)
	parent.add_child(bar)
	var segments: Array[ColorRect] = []
	for color in [Color("#5f9f73"),Color("#a4a85c"),Color("#c68b4f"),Color("#a8514d")]:
		var segment := ColorRect.new()
		segment.color = color
		segment.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		segment.custom_minimum_size.x = 2
		bar.add_child(segment)
		segments.append(segment)
	return {"title":title,"segments":segments}


func _add_unit_input(parent: VBoxContainer, icon_path: String, unit_name: String, weapon_name: String, initial: int, accent: Color, unit_id: String, weapon_id: String) -> Dictionary:
	var card := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#191e25")
	style.border_color = accent.darkened(0.42)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left = 8
	style.content_margin_right = 9
	style.content_margin_top = 3
	style.content_margin_bottom = 3
	card.add_theme_stylebox_override("panel", style)
	parent.add_child(card)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	card.add_child(row)
	var icon := TextureRect.new()
	icon.texture = load(icon_path)
	icon.custom_minimum_size = Vector2(38, 42)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(icon)
	var identity := VBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(identity)
	var name_label := Label.new()
	name_label.text = unit_name
	name_label.clip_text = true
	name_label.add_theme_font_size_override("font_size", 13)
	name_label.add_theme_color_override("font_color", accent.lightened(0.16))
	identity.add_child(name_label)
	var weapon_label := Label.new()
	weapon_label.text = weapon_name
	weapon_label.clip_text = true
	weapon_label.add_theme_font_size_override("font_size", 11)
	weapon_label.add_theme_color_override("font_color", Color("#8d99a6"))
	identity.add_child(weapon_label)
	var stats := Label.new()
	stats.text = "ATK —   DEF —"
	stats.clip_text = true
	stats.add_theme_font_size_override("font_size", 10)
	stats.add_theme_color_override("font_color", Color("#d3b46f"))
	identity.add_child(stats)
	var counts:=HBoxContainer.new()
	counts.add_theme_constant_override("separation",4)
	row.add_child(counts)
	var input:=_add_card_count(counts,"MEN",initial)
	var equipment:=_add_card_count(counts,"EQ",initial)
	var ammunition:SpinBox=null
	if weapon_id=="bow": ammunition=_add_card_count(counts,"ARW",initial*6)
	return {"input":input,"equipment":equipment,"ammunition":ammunition,"stats":stats,"unit":unit_id,"weapon":weapon_id}


func _add_card_count(parent: HBoxContainer,label_text: String,initial: int) -> SpinBox:
	var column:=VBoxContainer.new()
	parent.add_child(column)
	var label:=Label.new()
	label.text=label_text
	label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size",10)
	label.add_theme_color_override("font_color",Color("#82909e"))
	column.add_child(label)
	var input:=SpinBox.new()
	input.custom_minimum_size=Vector2(44,28)
	input.min_value=0
	input.max_value=100000
	input.step=1
	input.value=initial
	input.add_theme_font_size_override("font_size",14)
	column.add_child(input)
	return input


func _add_compact_number(parent: HBoxContainer, label_text: String, initial: float) -> SpinBox:
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(column)
	var label := Label.new()
	label.text = label_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", Color("#82909e"))
	column.add_child(label)
	var input := SpinBox.new()
	input.min_value = 0.1
	input.max_value = 1.5
	input.step = 0.05
	input.value = initial
	input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(input)
	return input


func _add_compact_display(parent: HBoxContainer,label_text: String) -> Label:
	var column:=VBoxContainer.new()
	column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	parent.add_child(column)
	var caption:=Label.new()
	caption.text=label_text
	caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	caption.add_theme_font_size_override("font_size",11)
	caption.add_theme_color_override("font_color",Color("#82909e"))
	column.add_child(caption)
	var value:=Label.new()
	value.text="100%"
	value.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	value.add_theme_font_size_override("font_size",17)
	value.add_theme_color_override("font_color",Color("#d3b46f"))
	column.add_child(value)
	return value


func _add_commander_card(parent: VBoxContainer,commanders: Array,portrait_offset: int,accent: Color) -> Dictionary:
	var panel:=PanelContainer.new()
	var style:=StyleBoxFlat.new()
	style.bg_color=Color("#191e25")
	style.border_color=accent.darkened(0.35)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(5)
	panel.add_theme_stylebox_override("panel",style)
	parent.add_child(panel)
	var row:=HBoxContainer.new()
	row.add_theme_constant_override("separation",8)
	panel.add_child(row)
	var portrait:=TextureRect.new()
	portrait.custom_minimum_size=Vector2(42,44)
	portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(portrait)
	var details:=VBoxContainer.new()
	details.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	details.add_theme_constant_override("separation",1)
	row.add_child(details)
	var select:=OptionButton.new()
	select.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	select.custom_minimum_size.y=25
	for commander in commanders:
		select.add_item(String(commander.name))
	details.add_child(select)
	var stats:=Label.new()
	stats.add_theme_font_size_override("font_size",10)
	stats.add_theme_color_override("font_color",Color("#d3b46f"))
	stats.clip_text=true
	details.add_child(stats)
	select.set_meta("portrait_offset",portrait_offset)
	select.item_selected.connect(func(_index:int)->void: _refresh_commander_cards())
	return {"select":select,"portrait":portrait,"stats":stats}


func _commander_portrait(index: int) -> AtlasTexture:
	var atlas:=AtlasTexture.new()
	atlas.atlas=COMMANDER_PORTRAITS
	atlas.region=Rect2((index%3)*512,(index/3)*512,512,512)
	return atlas


func _refresh_commander_cards() -> void:
	if attacker_commander_select==null or defender_commander_select==null: return
	var attacker:Dictionary=ATTACKER_COMMANDERS[attacker_commander_select.selected]
	var defender:Dictionary=DEFENDER_COMMANDERS[defender_commander_select.selected]
	attacker_commander_stats.text="CMD %02.0f   TAC %02.0f   LOG %02.0f   RES %02.0f" % [attacker.command*100.0,attacker.tactics*100.0,attacker.logistics*100.0,attacker.resolve*100.0]
	defender_commander_stats.text="CMD %02.0f   TAC %02.0f   LOG %02.0f   RES %02.0f" % [defender.command*100.0,defender.tactics*100.0,defender.logistics*100.0,defender.resolve*100.0]
	attacker_commander_portrait.texture=_commander_portrait(attacker_commander_select.selected)
	defender_commander_portrait.texture=_commander_portrait(3+defender_commander_select.selected)
	attacker_commander_select.tooltip_text="Command leads combat power • Tactics exploits counters • Logistics restores equipment • Resolve absorbs morale shock"
	defender_commander_select.tooltip_text=attacker_commander_select.tooltip_text


func _add_section(parent: VBoxContainer, text: String, color := Color("#d3b46f"), alignment := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = alignment
	label.clip_text = true
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", color)
	label.add_theme_constant_override("outline_size", 2)
	parent.add_child(label)
	return label


func _add_number(parent: VBoxContainer, label_text: String, initial: float, minimum: float, maximum: float, step: float) -> SpinBox:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = label_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	var input := SpinBox.new()
	input.custom_minimum_size.x = 86
	input.min_value = minimum
	input.max_value = maximum
	input.step = step
	input.value = initial
	input.allow_greater = false
	input.allow_lesser = false
	row.add_child(input)
	parent.add_child(row)
	return input


func _new_seed() -> void:
	seed_input.value = randi_range(0, 2147483647)
	if not battle_active:
		_preview_battle()


func _make_input_forces() -> Array[Dictionary]:
	var attacker_composition: Array[Dictionary] = [
		{"unit":"levy","weapon":"improvised","count":int(attacker_troops.value),"equipment":int(attacker_cards[0].equipment.value)},
		{"unit":"line_infantry","weapon":"spear","count":int(attacker_spears.value),"equipment":int(attacker_cards[1].equipment.value)},
		{"unit":"skirmisher","weapon":"bow","count":int(attacker_archers.value),"equipment":int(attacker_cards[2].equipment.value),"ammunition":int(attacker_cards[2].ammunition.value),"ammunition_required":int(attacker_archers.value)*6}
	]
	var defender_composition: Array[Dictionary] = [
		{"unit":"levy","weapon":"improvised","count":int(defender_troops.value),"equipment":int(defender_cards[0].equipment.value)},
		{"unit":"line_infantry","weapon":"spear","count":int(defender_spears.value),"equipment":int(defender_cards[1].equipment.value)},
		{"unit":"skirmisher","weapon":"bow","count":int(defender_archers.value),"equipment":int(defender_cards[2].equipment.value),"ammunition":int(defender_cards[2].ammunition.value),"ammunition_required":int(defender_archers.value)*6}
	]
	var attacker: Dictionary = simulator.create_formation_force("River Host", attacker_composition, attacker_morale.value, 1.0)
	var defender: Dictionary = simulator.create_formation_force("Hill Guard", defender_composition, defender_morale.value, 1.0)
	attacker["commander"]=ATTACKER_COMMANDERS[attacker_commander_select.selected].duplicate(true)
	defender["commander"]=DEFENDER_COMMANDERS[defender_commander_select.selected].duplicate(true)
	attacker["attack_modifier"] = attacker_attack.value
	defender["attack_modifier"] = defender_attack.value
	return [attacker, defender]


func _preview_battle() -> void:
	pending_prisoner_decision.clear()
	if prisoner_decision_row!=null: prisoner_decision_row.visible=false
	preparation_day=0
	var forces := _make_input_forces()
	live_attacker = forces[0]
	live_defender = forces[1]
	_seed_citizen_rosters()
	live_attacker_initial = maxi(1, int(live_attacker.troops))
	live_defender_initial = maxi(1, int(live_defender.troops))
	_update_cohort_cards()
	_update_strength()
	outcome_label.text = "Ready to begin"
	attacker_summary.text = "RIVER HOST   %d ready" % live_attacker.troops
	defender_summary.text = "%d ready   HILL GUARD" % live_defender.troops
	attacker_remaining_bar.value = 100
	defender_remaining_bar.value = 100
	results.clear()
	results.append_text("[color=#82909e]Press Start Battle to watch the engagement unfold.[/color]")
	preparation_label.text="DAY 0 • +6 EQ / +4 MEN / +12 ARW"


func _toggle_battle() -> void:
	if not battle_active:
		if live_round>0:
			_preview_battle()
		_start_battle()
	elif battle_timer.paused:
		battle_timer.paused = false
		run_button.text = "Pause"
	else:
		battle_timer.paused = true
		run_button.text = "Resume"


func _start_battle() -> void:
	battle_timer.paused = false
	if preparation_day==0 and live_round==0:
		var forces:=_make_input_forces()
		live_attacker=forces[0]
		live_defender=forces[1]
		_seed_citizen_rosters()
	live_attacker_initial = maxi(1, int(live_attacker.troops))
	live_defender_initial = maxi(1, int(live_defender.troops))
	live_round = 0
	round_records.clear()
	push_next_round = false
	battle_active = true
	run_button.text = "Pause"
	push_button.disabled = false
	retreat_button.disabled = false
	prepare_one_button.disabled=true
	prepare_week_button.disabled=true
	results.clear()
	_update_live_display("Battle joined")
	battle_timer.start()


func _push_harder() -> void:
	if not battle_active:
		return
	push_next_round = true
	push_button.disabled = true
	outcome_label.text = "Orders given: push harder next round"


func _retreat() -> void:
	if not battle_active:
		return
	_finish_live_battle("Attacker retreat", "River Host withdrew with %d troops." % int(live_attacker.troops))


func _advance_round() -> void:
	if not battle_active:
		return
	live_round += 1
	var attacker_for_round := live_attacker.duplicate(true)
	var defender_for_round := live_defender.duplicate(true)
	if push_next_round:
		attacker_for_round.attack_modifier = float(attacker_for_round.get("attack_modifier", 1.0)) * 1.35
		# Closing aggressively creates more opportunities for both sides.
		defender_for_round.attack_modifier = float(defender_for_round.get("attack_modifier", 1.0)) * 1.25
	var old_attacker_formations: Array = live_attacker.formations.duplicate(true)
	var old_defender_formations: Array = live_defender.formations.duplicate(true)
	var result: Dictionary = simulator.simulate(attacker_for_round, defender_for_round, {
		"seed": int(seed_input.value) + live_round * 7919,
		"terrain_defense": terrain_defense.value,
		"max_rounds": 1
	})
	if result.rounds.is_empty():
		var reason:="River Host cannot re-enter combat." if float(live_attacker.morale)<=0.15 else "Hill Guard cannot continue combat."
		_finish_live_battle("Engagement halted",reason)
		return
	var record: Dictionary = result.rounds[0]
	record["termination"]=result.get("termination",{})
	record["pushed"] = push_next_round
	record["round"] = live_round
	round_records.append(record)
	live_attacker.troops = result.attacker.remaining_troops
	live_attacker.morale = result.attacker.morale
	live_attacker.formations = result.attacker.formations
	live_defender.troops = result.defender.remaining_troops
	live_defender.morale = result.defender.morale
	live_defender.formations = result.defender.formations
	for key in ["reserve_manpower","wounded_pool","scattered_pool","dead"]:
		live_attacker[key]=result.attacker.get(key,live_attacker.get(key,0))
		live_defender[key]=result.defender.get(key,live_defender.get(key,0))
	_apply_roster_losses(attacker_roster,old_attacker_formations,live_attacker.formations,record.get("attacker_casualties",{}))
	_apply_roster_losses(defender_roster,old_defender_formations,live_defender.formations,record.get("defender_casualties",{}))
	_apply_battle_fatigue(attacker_roster,0.085 if push_next_round else 0.045)
	_apply_battle_fatigue(defender_roster,0.060 if push_next_round else 0.040)
	push_next_round = false
	push_button.disabled = false
	_update_live_display("Round %d resolved" % live_round)
	if String(result.get("outcome",""))=="mutual_collapse":
		_finish_live_battle("Mutual collapse", "Both armies have lost cohesion.",record.termination)
	elif int(live_attacker.troops) <= 0 or float(live_attacker.morale) <= 0.15:
		_finish_live_battle("Defender victory", "River Host broke under pressure.",record.termination)
	elif int(live_defender.troops) <= 0 or float(live_defender.morale) <= 0.15:
		_finish_live_battle("Attacker victory", "Hill Guard broke under pressure.",record.termination)
	elif live_round >= CombatSimulator.MAX_ROUNDS:
		_finish_live_battle("Inconclusive", "Both forces remain in the field.")


func _finish_live_battle(heading: String, detail: String,termination: Dictionary={}) -> void:
	battle_active = false
	battle_timer.stop()
	battle_timer.paused = false
	run_button.text = "Start New Battle"
	push_button.disabled = true
	retreat_button.disabled = true
	prepare_one_button.disabled=false
	prepare_week_button.disabled=false
	_apply_termination_captures(termination)
	_apply_termination_spoils(termination)
	_update_cohort_cards()
	_update_strength()
	_refresh_force_summaries()
	outcome_label.text = "%s  •  %s" % [heading, detail]
	if not termination.is_empty():
		results.append_text("\n[color=#d3b46f][b]BATTLE AFTERMATH[/b][/color]\n[color=#d6dde5]%s[/color]" % String(termination.get("summary","")))
		var succession:=_apply_command_succession(termination)
		if succession!="":
			results.append_text("\n[color=#d3b46f]%s[/color]" % succession)
		_show_prisoner_decision(termination)


func _apply_command_succession(termination: Dictionary) -> String:
	var fate:=String(termination.get("commander_fate",""))
	if fate!="captured" and fate!="killed": return ""
	var defeated:=String(termination.get("defeated",""))
	var select:OptionButton
	var commanders:Array
	if defeated==String(live_attacker.get("name","River Host")):
		select=attacker_commander_select
		commanders=ATTACKER_COMMANDERS
	else:
		select=defender_commander_select
		commanders=DEFENDER_COMMANDERS
	if select.selected>=commanders.size()-1:
		return "No eligible field successor remains."
	var former_name:=String(commanders[select.selected].name)
	select.select(select.selected+1)
	_refresh_commander_cards()
	var successor:Dictionary=commanders[select.selected]
	if defeated==String(live_attacker.get("name","River Host")):
		live_attacker["commander"]=successor.duplicate(true)
	else:
		live_defender["commander"]=successor.duplicate(true)
	return "%s assumes field command after the loss of %s — with reduced authority and staff effectiveness." % [successor.name,former_name]


func _show_prisoner_decision(termination: Dictionary) -> void:
	var soldiers:=int(termination.get("prisoners",0))
	var general_captured:=bool(termination.get("captured_general",false))
	var spoils:Dictionary=termination.get("spoils",{})
	var weapons_total:=0
	for amount in (spoils.get("weapons",{}) as Dictionary).values(): weapons_total+=int(amount)
	var has_spoils:=weapons_total+int(spoils.get("supplies",0))+int(spoils.get("carts",0))+int(spoils.get("wealth",0))>0
	if soldiers<=0 and not general_captured and not has_spoils: return
	pending_prisoner_decision=termination.duplicate(true)
	prisoner_decision_row.visible=true
	run_button.disabled=true
	prepare_one_button.disabled=true
	prepare_week_button.disabled=true
	prisoner_action_select.visible=soldiers>0
	general_action_select.visible=general_captured
	spoils_action_select.visible=has_spoils
	prisoner_decision_label.text="CAPTIVES: %d soldiers%s\nSPOILS: ⚔ %d gear  ◆ %d supply  ▣ %d carts  ¤ %d wealth" % [soldiers," + captured general" if general_captured else "",weapons_total,int(spoils.get("supplies",0)),int(spoils.get("carts",0)),int(spoils.get("wealth",0))]


func _resolve_prisoners(decision: String,general_decision: String="hold general",spoils_decision: String="army stores") -> void:
	if pending_prisoner_decision.is_empty(): return
	var prisoners:=int(pending_prisoner_decision.get("prisoners",0))
	var defeated_name:=String(pending_prisoner_decision.get("defeated",""))
	var captor_name:=String(pending_prisoner_decision.get("captor",""))
	var defeated:Dictionary=live_attacker if defeated_name==String(live_attacker.get("name","")) else live_defender
	var captor:Dictionary=live_attacker if captor_name==String(live_attacker.get("name","")) else live_defender
	var defeated_roster:Array[Dictionary]=attacker_roster if defeated_name==String(live_attacker.get("name","")) else defender_roster
	var captor_roster:Array[Dictionary]=attacker_roster if captor_name==String(live_attacker.get("name","")) else defender_roster
	var decision_text:="No rank-and-file captives." if prisoners<=0 else ""
	if decision=="release":
		for person in defeated_roster:
			if String(person.get("army_status",""))=="captured": person["army_status"]="reserve"
		defeated["reserve_manpower"]=int(defeated.get("reserve_manpower",0))+prisoners
		defeated["prisoner_pool"]=maxi(0,int(defeated.get("prisoner_pool",0))-prisoners)
		captor["held_prisoners"]=maxi(0,int(captor.get("held_prisoners",0))-prisoners)
		decision_text="%d soldiers are released and return to the defeated reserve pool." % prisoners
	elif decision=="recruit volunteers":
		var recruited:=roundi(float(prisoners)*0.25)
		var moved:=0
		for person in defeated_roster.duplicate():
			if moved>=recruited: break
			if String(person.get("army_status",""))!="captured": continue
			defeated_roster.erase(person)
			person["army_status"]="reserve"
			person["cohort_index"]=moved%maxi(1,(captor.get("formations",[]) as Array).size())
			captor_roster.append(person)
			moved+=1
		captor["reserve_manpower"]=int(captor.get("reserve_manpower",0))+moved
		defeated["prisoner_pool"]=maxi(0,int(defeated.get("prisoner_pool",0))-moved)
		captor["held_prisoners"]=maxi(0,int(captor.get("held_prisoners",0))-moved)
		decision_text="%d prisoners volunteer for the captor's reserve; %d remain held." % [moved,prisoners-moved]
	elif decision=="ransom":
		for person in defeated_roster:
			if String(person.get("army_status",""))=="captured": person["army_status"]="reserve"
		defeated["reserve_manpower"]=int(defeated.get("reserve_manpower",0))+prisoners
		defeated["prisoner_pool"]=maxi(0,int(defeated.get("prisoner_pool",0))-prisoners)
		captor["held_prisoners"]=maxi(0,int(captor.get("held_prisoners",0))-prisoners)
		captor["war_wealth"]=int(captor.get("war_wealth",0))+prisoners*2
		decision_text="The captives return home; ransom adds %d war wealth." % (prisoners*2)
	elif decision=="exchange":
		for person in defeated_roster:
			if String(person.get("army_status",""))=="captured": person["army_status"]="reserve"
		defeated["reserve_manpower"]=int(defeated.get("reserve_manpower",0))+prisoners
		defeated["prisoner_pool"]=maxi(0,int(defeated.get("prisoner_pool",0))-prisoners)
		captor["held_prisoners"]=maxi(0,int(captor.get("held_prisoners",0))-prisoners)
		captor["exchange_credit"]=int(captor.get("exchange_credit",0))+prisoners
		decision_text="The prisoners are exchanged; %d exchange credit is recorded." % prisoners
	elif decision=="parole":
		for person in defeated_roster:
			if String(person.get("army_status",""))=="captured": person["army_status"]="paroled"
		defeated["prisoner_pool"]=maxi(0,int(defeated.get("prisoner_pool",0))-prisoners)
		captor["held_prisoners"]=maxi(0,int(captor.get("held_prisoners",0))-prisoners)
		decision_text="%d prisoners are paroled and barred from returning to this army." % prisoners
	elif decision=="enslave":
		var enslaved:=0
		for person in defeated_roster.duplicate():
			if String(person.get("army_status",""))!="captured": continue
			defeated_roster.erase(person)
			person["army_status"]="forced_labor"
			captor_roster.append(person)
			enslaved+=1
		defeated["prisoner_pool"]=maxi(0,int(defeated.get("prisoner_pool",0))-enslaved)
		captor["held_prisoners"]=maxi(0,int(captor.get("held_prisoners",0))-enslaved)
		captor["forced_laborers"]=int(captor.get("forced_laborers",0))+enslaved
		decision_text="%d captives are transferred into forced labor." % enslaved
	elif decision=="execute":
		var executed:=0
		for person in defeated_roster:
			if String(person.get("army_status",""))!="captured": continue
			person["army_status"]="killed"
			person["alive"]=false
			executed+=1
		defeated["dead"]=int(defeated.get("dead",0))+executed
		defeated["prisoner_pool"]=maxi(0,int(defeated.get("prisoner_pool",0))-executed)
		captor["held_prisoners"]=maxi(0,int(captor.get("held_prisoners",0))-executed)
		decision_text="%d prisoners are executed." % executed
	else:
		decision_text="%d soldiers remain under guard for a later exchange or ransom." % prisoners
	if prisoners<=0: decision_text="No rank-and-file captives."
	if bool(pending_prisoner_decision.get("captured_general",false)):
		var general_name:=String(pending_prisoner_decision.get("commander","The captured general"))
		if general_decision=="release general":
			captor["held_generals"]=maxi(0,int(captor.get("held_generals",0))-1)
			decision_text+=" %s is released." % general_name
		elif general_decision=="ransom general":
			captor["held_generals"]=maxi(0,int(captor.get("held_generals",0))-1)
			captor["war_wealth"]=int(captor.get("war_wealth",0))+50
			decision_text+=" %s is ransomed for 50 war wealth." % general_name
		elif general_decision=="exile general":
			captor["held_generals"]=maxi(0,int(captor.get("held_generals",0))-1)
			decision_text+=" %s is released into permanent exile." % general_name
		elif general_decision=="execute general":
			captor["held_generals"]=maxi(0,int(captor.get("held_generals",0))-1)
			decision_text+=" %s is executed." % general_name
		else:
			decision_text+=" %s remains a high-value captive." % general_name
	var consequence_text:=_apply_captive_consequences(decision if prisoners>0 else "none",general_decision,captor,defeated)
	decision_text+="\n"+consequence_text
	decision_text+="\n"+_resolve_spoils(spoils_decision,pending_prisoner_decision.get("spoils",{}),captor,defeated)
	results.append_text("\n[color=#d3b46f][b]CAPTIVE DECISION[/b][/color]\n[color=#d6dde5]%s[/color]" % decision_text)
	outcome_label.text="Captive decision recorded • %s" % decision.capitalize()
	pending_prisoner_decision.clear()
	prisoner_decision_row.visible=false
	run_button.disabled=false
	prepare_one_button.disabled=false
	prepare_week_button.disabled=false
	_update_cohort_cards()
	_update_strength()
	_refresh_force_summaries()


func _apply_captive_consequences(decision: String,general_decision: String,captor: Dictionary,defeated: Dictionary) -> String:
	var captor_morale_delta:=0.0
	var defeated_morale_delta:=0.0
	var fear_delta:=0.0
	var grievance_delta:=0.0
	var reputation_delta:=0.0
	match decision:
		"none":
			pass
		"release":
			captor_morale_delta=0.03; defeated_morale_delta=0.10; fear_delta=-0.04; grievance_delta=-0.06; reputation_delta=0.12
		"ransom":
			captor_morale_delta=0.03; defeated_morale_delta=0.04; grievance_delta=-0.01
		"exchange":
			captor_morale_delta=0.05; defeated_morale_delta=0.08; grievance_delta=-0.05; reputation_delta=0.06
		"parole":
			captor_morale_delta=0.04; defeated_morale_delta=0.05; fear_delta=-0.02; grievance_delta=-0.04; reputation_delta=0.10
		"recruit volunteers":
			captor_morale_delta=0.02; defeated_morale_delta=-0.03; fear_delta=0.04; grievance_delta=0.08; reputation_delta=-0.03
		"enslave":
			captor_morale_delta=-0.05; defeated_morale_delta=0.07; fear_delta=0.15; grievance_delta=0.28; reputation_delta=-0.30
		"execute":
			captor_morale_delta=-0.08; defeated_morale_delta=0.14; fear_delta=0.24; grievance_delta=0.42; reputation_delta=-0.50
		_:
			defeated_morale_delta=-0.02; fear_delta=0.06; grievance_delta=0.04; reputation_delta=-0.02
	if bool(pending_prisoner_decision.get("captured_general",false)):
		match general_decision:
			"release general":
				captor_morale_delta+=0.02; defeated_morale_delta+=0.06; reputation_delta+=0.08; grievance_delta-=0.04
			"ransom general":
				captor_morale_delta+=0.03; defeated_morale_delta+=0.03
			"exile general":
				defeated_morale_delta-=0.04; fear_delta+=0.08; grievance_delta+=0.05
			"execute general":
				captor_morale_delta-=0.05; defeated_morale_delta+=0.12; fear_delta+=0.15; grievance_delta+=0.25; reputation_delta-=0.25
			_:
				defeated_morale_delta-=0.03; fear_delta+=0.05; grievance_delta+=0.06
	captor["morale"]=clampf(float(captor.get("morale",0.0))+captor_morale_delta,0.0,1.5)
	defeated["morale"]=clampf(float(defeated.get("morale",0.0))+defeated_morale_delta,0.0,1.5)
	captor["fear_reputation"]=clampf(float(captor.get("fear_reputation",0.0))+fear_delta,0.0,1.0)
	captor["war_reputation"]=clampf(float(captor.get("war_reputation",0.0))+reputation_delta,-1.0,1.0)
	defeated["war_grievance"]=clampf(float(defeated.get("war_grievance",0.0))+grievance_delta,0.0,1.0)
	return "Morale: captor %+.0f, defeated %+.0f • Fear %+.0f • Grievance %+.0f • Reputation %+.0f" % [captor_morale_delta*100.0,defeated_morale_delta*100.0,fear_delta*100.0,grievance_delta*100.0,reputation_delta*100.0]


func _advance_preparation(days: int) -> void:
	if battle_active: return
	# A completed Day-0 battle already has persistent casualties and recovery pools.
	# Rebuild only before the first engagement, when card edits are scenario inputs.
	if preparation_day==0 and live_round==0:
		var forces:=_make_input_forces()
		live_attacker=forces[0]
		live_defender=forces[1]
		_seed_citizen_rosters()
		live_attacker_initial=maxi(1,int(live_attacker.troops))
		live_defender_initial=maxi(1,int(live_defender.troops))
	var attacker_delivered:=0
	var defender_delivered:=0
	var attacker_rejoined:=0
	var defender_rejoined:=0
	for day_index in maxi(1,days):
		var attacker_result:Dictionary=simulator.advance_preparation_day(live_attacker,{"equipment_replacements":6,"manpower_replacements":4,"organization_recovery":0.065})
		var defender_result:Dictionary=simulator.advance_preparation_day(live_defender,{"equipment_replacements":6,"manpower_replacements":4,"organization_recovery":0.065})
		live_attacker=attacker_result.force
		live_defender=defender_result.force
		_refill_lab_ammunition(live_attacker,12)
		_refill_lab_ammunition(live_defender,12)
		attacker_delivered+=int(attacker_result.equipment_delivered)
		defender_delivered+=int(defender_result.equipment_delivered)
		attacker_rejoined+=int(attacker_result.manpower_rejoined)
		defender_rejoined+=int(defender_result.manpower_rejoined)
		_sync_roster_to_formations(attacker_roster,live_attacker.formations)
		_sync_roster_to_formations(defender_roster,live_defender.formations)
		_recover_roster_day(attacker_roster)
		_recover_roster_day(defender_roster)
		preparation_day+=1
	live_round=0
	round_records.clear()
	_update_cohort_cards()
	_update_strength()
	_refresh_force_summaries()
	preparation_label.text="DAY %d • +6 EQ / +4 MEN / +12 ARW" % preparation_day
	outcome_label.text="Prepared %d day%s • Rejoined %d/%d • Equipment %d/%d • Arrows resupplied" % [days,"s" if days!=1 else "",attacker_rejoined,defender_rejoined,attacker_delivered,defender_delivered]


func _refill_lab_ammunition(force:Dictionary,capacity:int)->int:
	var remaining:=maxi(0,capacity)
	var delivered:=0
	for formation in force.get("formations",[]):
		if remaining<=0: break
		if String(formation.get("weapon",""))!="bow": continue
		var required:=maxi(0,int(formation.get("ammunition_required",int(formation.get("authorized_count",formation.get("count",0)))*6)))
		var transfer:=mini(remaining,maxi(0,required-int(formation.get("ammunition",0))))
		formation["ammunition"]=int(formation.get("ammunition",0))+transfer
		remaining-=transfer
		delivered+=transfer
	return delivered


func _recover_roster_day(roster: Array[Dictionary]) -> void:
	for person in roster:
		if not bool(person.get("active_in_army",false)): continue
		person["fatigue"]=maxf(0.0,float(person.get("fatigue",0.0))-0.075)
		person["health_condition"]=move_toward(float(person.get("health_condition",0.7)),0.92,0.012)
		person["nutrition_condition"]=move_toward(float(person.get("nutrition_condition",0.7)),0.90,0.016)


func _update_strength() -> void:
	var attacker_totals:=_aggregate_cohort_stats(simulator.evaluate_force(live_attacker,live_defender,1.0))
	var defender_totals:=_aggregate_cohort_stats(simulator.evaluate_force(live_defender,live_attacker,terrain_defense.value))
	var attacker_power := (float(attacker_totals.attack)+float(attacker_totals.defense))*0.5*float(live_attacker.get("readiness",1.0))*float(live_attacker.get("morale",1.0))*float(live_attacker.get("attack_modifier",1.0))
	var defender_power := (float(defender_totals.attack)+float(defender_totals.defense))*0.5*float(live_defender.get("readiness",1.0))*float(live_defender.get("morale",1.0))*float(live_defender.get("attack_modifier",1.0))
	var attacker_share := attacker_power / maxf(0.01, attacker_power + defender_power) * 100.0
	strength_bar.value = attacker_share
	strength_label.text = "RIVER HOST  %.0f%%          RELATIVE STRENGTH          %.0f%%  HILL GUARD" % [attacker_share, 100.0 - attacker_share]


func _update_cohort_cards() -> void:
	_reconcile_force_totals(live_attacker)
	_reconcile_force_totals(live_defender)
	var attacker_condition:=_active_condition_average(attacker_roster_state,attacker_roster)
	var defender_condition:=_active_condition_average(defender_roster_state,defender_roster)
	var attacker_readiness_state:Dictionary=simulator.force_readiness(live_attacker,attacker_condition)
	var defender_readiness_state:Dictionary=simulator.force_readiness(live_defender,defender_condition)
	live_attacker.readiness=attacker_readiness_state.aggregate
	live_defender.readiness=defender_readiness_state.aggregate
	attacker_readiness.text="%.0f%%" % (float(attacker_readiness_state.aggregate)*100.0)
	defender_readiness.text="%.0f%%" % (float(defender_readiness_state.aggregate)*100.0)
	attacker_readiness.tooltip_text="Manpower %.0f%% • Equipment %.0f%% • Ammunition %.0f%% • Condition %.0f%% • Organization %.0f%%" % [attacker_readiness_state.manpower*100.0,attacker_readiness_state.equipment*100.0,attacker_readiness_state.ammunition*100.0,attacker_readiness_state.condition*100.0,attacker_readiness_state.organization*100.0]
	defender_readiness.tooltip_text="Manpower %.0f%% • Equipment %.0f%% • Ammunition %.0f%% • Condition %.0f%% • Organization %.0f%%" % [defender_readiness_state.manpower*100.0,defender_readiness_state.equipment*100.0,defender_readiness_state.ammunition*100.0,defender_readiness_state.condition*100.0,defender_readiness_state.organization*100.0]
	attacker_readiness.tooltip_text+="\nReserve %d • Wounded %d • Scattered %d • Dead %d" % [live_attacker.get("reserve_manpower",0),live_attacker.get("wounded_pool",0),live_attacker.get("scattered_pool",0),live_attacker.get("dead",0)]
	defender_readiness.tooltip_text+="\nReserve %d • Wounded %d • Scattered %d • Dead %d" % [live_defender.get("reserve_manpower",0),live_defender.get("wounded_pool",0),live_defender.get("scattered_pool",0),live_defender.get("dead",0)]
	attacker_readiness.tooltip_text+="\nPOWs held %d • Own soldiers captured %d" % [live_attacker.get("held_prisoners",0),live_attacker.get("prisoner_pool",0)]
	defender_readiness.tooltip_text+="\nPOWs held %d • Own soldiers captured %d" % [live_defender.get("held_prisoners",0),live_defender.get("prisoner_pool",0)]
	attacker_readiness.tooltip_text+="\nFear %.0f • Grievance %.0f • War reputation %+.0f" % [float(live_attacker.get("fear_reputation",0.0))*100.0,float(live_attacker.get("war_grievance",0.0))*100.0,float(live_attacker.get("war_reputation",0.0))*100.0]
	defender_readiness.tooltip_text+="\nFear %.0f • Grievance %.0f • War reputation %+.0f" % [float(live_defender.get("fear_reputation",0.0))*100.0,float(live_defender.get("war_grievance",0.0))*100.0,float(live_defender.get("war_reputation",0.0))*100.0]
	var attacker_evaluation: Array[Dictionary] = simulator.evaluate_force(live_attacker, live_defender, 1.0)
	var defender_evaluation: Array[Dictionary] = simulator.evaluate_force(live_defender, live_attacker, terrain_defense.value)
	var attacker_totals := _aggregate_cohort_stats(attacker_evaluation)
	var defender_totals := _aggregate_cohort_stats(defender_evaluation)
	attacker_header.text = "ATTACKER — RIVER HOST     ⚔ %.0f   🛡 %.0f" % [attacker_totals.attack, attacker_totals.defense]
	defender_header.text = "⚔ %.0f   🛡 %.0f     HILL GUARD — DEFENDER" % [defender_totals.attack, defender_totals.defense]
	_update_card_side(attacker_cards, attacker_evaluation, live_attacker.get("formations", []))
	_update_card_side(defender_cards, defender_evaluation, live_defender.get("formations", []))
	_refresh_condition_meter(attacker_condition_meter,attacker_roster_state,attacker_roster)
	_refresh_condition_meter(defender_condition_meter,defender_roster_state,defender_roster)


func _reconcile_force_totals(force: Dictionary) -> void:
	var formation_total:=0
	for formation in force.get("formations",[]): formation_total+=int(formation.get("count",0))
	force["troops"]=formation_total


func _refresh_force_summaries() -> void:
	attacker_summary.text="RIVER HOST   %d troops   •   Morale %.2f" % [int(live_attacker.get("troops",0)),float(live_attacker.get("morale",0.0))]
	defender_summary.text="Morale %.2f   •   %d troops   HILL GUARD" % [float(live_defender.get("morale",0.0)),int(live_defender.get("troops",0))]
	attacker_remaining_bar.value=clampf(float(live_attacker.get("troops",0))/maxf(1.0,float(live_attacker_initial))*100.0,0.0,100.0)
	defender_remaining_bar.value=clampf(float(live_defender.get("troops",0))/maxf(1.0,float(live_defender_initial))*100.0,0.0,100.0)


func _apply_termination_captures(termination: Dictionary) -> void:
	var prisoners:=int(termination.get("prisoners",0))
	if prisoners<=0: return
	var defeated:=String(termination.get("defeated",""))
	var force:Dictionary=live_attacker if defeated==String(live_attacker.get("name","")) else live_defender
	var captor:Dictionary=live_defender if force==live_attacker else live_attacker
	var roster:Array[Dictionary]=attacker_roster if force==live_attacker else defender_roster
	var formations:Array=force.get("formations",[])
	var remaining:=mini(prisoners,int(force.get("troops",0)))
	while remaining>0:
		var target:=-1
		var largest:=0
		for index in formations.size():
			var count:=int(formations[index].get("count",0))
			if count>largest:
				largest=count
				target=index
		if target<0: break
		formations[target]["count"]=int(formations[target].count)-1
		formations[target]["equipment"]=maxi(0,int(formations[target].get("equipment",0))-1)
		remaining-=1
	force["formations"]=formations
	force["prisoner_pool"]=int(force.get("prisoner_pool",0))+prisoners-remaining
	captor["held_prisoners"]=int(captor.get("held_prisoners",0))+prisoners-remaining
	if bool(termination.get("captured_general",false)):
		captor["held_generals"]=int(captor.get("held_generals",0))+1
	_reconcile_force_totals(force)
	var to_mark:=prisoners-remaining
	for person in roster:
		if to_mark<=0: break
		if bool(person.get("active_in_army",false)):
			person["active_in_army"]=false
			person["army_status"]="captured"
			to_mark-=1


func _apply_termination_spoils(termination: Dictionary) -> void:
	var spoils:Dictionary=termination.get("spoils",{})
	if spoils.is_empty(): return
	var defeated_name:=String(termination.get("defeated",""))
	var defeated:Dictionary=live_attacker if defeated_name==String(live_attacker.get("name","")) else live_defender
	var formations:Array=defeated.get("formations",[])
	for weapon in (spoils.get("weapons",{}) as Dictionary):
		var remaining:=int((spoils.weapons as Dictionary)[weapon])
		for index in formations.size():
			if remaining<=0: break
			if String(formations[index].get("weapon",""))!=String(weapon): continue
			var taken:=mini(remaining,int(formations[index].get("equipment",0)))
			formations[index]["equipment"]=int(formations[index].get("equipment",0))-taken
			remaining-=taken
	defeated["formations"]=formations


func _resolve_spoils(decision: String,spoils: Dictionary,captor: Dictionary,defeated: Dictionary) -> String:
	if spoils.is_empty(): return "No recoverable battlefield spoils."
	var weapons:Dictionary=spoils.get("weapons",{})
	var gear_total:=0
	for amount in weapons.values(): gear_total+=int(amount)
	var supplies:=int(spoils.get("supplies",0))
	var carts:=int(spoils.get("carts",0))
	var wealth:=int(spoils.get("wealth",0))
	if decision=="army stores":
		var stockpile:Dictionary=captor.get("equipment_stockpile",{}).duplicate(true)
		var formations:Array=captor.get("formations",[])
		for weapon in weapons:
			var available:=int(weapons[weapon])
			for index in formations.size():
				if available<=0: break
				if String(formations[index].get("weapon",""))!=String(weapon): continue
				var need:=maxi(0,int(formations[index].get("equipment_required",0))-int(formations[index].get("equipment",0)))
				var issued:=mini(available,need)
				formations[index]["equipment"]=int(formations[index].get("equipment",0))+issued
				available-=issued
			stockpile[weapon]=int(stockpile.get(weapon,0))+available
		captor["formations"]=formations
		captor["equipment_stockpile"]=stockpile
		captor["supplies"]=int(captor.get("supplies",0))+supplies
		captor["transport_carts"]=int(captor.get("transport_carts",0))+carts
		captor["war_wealth"]=int(captor.get("war_wealth",0))+wealth
		return "Spoils enter army stores: %d gear, %d supply, %d carts, and %d wealth." % [gear_total,supplies,carts,wealth]
	if decision=="return property":
		var stockpile:Dictionary=defeated.get("equipment_stockpile",{}).duplicate(true)
		for weapon in weapons: stockpile[weapon]=int(stockpile.get(weapon,0))+int(weapons[weapon])
		defeated["equipment_stockpile"]=stockpile
		defeated["supplies"]=int(defeated.get("supplies",0))+supplies
		defeated["transport_carts"]=int(defeated.get("transport_carts",0))+carts
		defeated["war_wealth"]=int(defeated.get("war_wealth",0))+wealth
		captor["war_reputation"]=clampf(float(captor.get("war_reputation",0.0))+0.16,-1.0,1.0)
		defeated["war_grievance"]=clampf(float(defeated.get("war_grievance",0.0))-0.12,0.0,1.0)
		return "Captured property is returned; reputation +16 and enemy grievance −12."
	if decision=="reward troops":
		captor["morale"]=clampf(float(captor.get("morale",0.0))+0.10,0.0,1.5)
		captor["war_wealth"]=int(captor.get("war_wealth",0))+roundi(float(wealth)*0.25)
		return "Spoils are divided among the ranks; captor morale +10, only 25%% of coin reaches stores."
	if decision=="state treasury":
		captor["war_wealth"]=int(captor.get("war_wealth",0))+wealth+gear_total*2+supplies+carts*5
		captor["morale"]=clampf(float(captor.get("morale",0.0))-0.04,0.0,1.5)
		return "Spoils are liquidated into the treasury; troop morale −4."
	# Unrestricted plunder maximizes immediate proceeds but damages discipline and future resistance.
	captor["war_wealth"]=int(captor.get("war_wealth",0))+roundi(float(wealth+gear_total*2+supplies+carts*5)*1.35)
	captor["morale"]=clampf(float(captor.get("morale",0.0))+0.06,0.0,1.5)
	captor["discipline_penalty"]=clampf(float(captor.get("discipline_penalty",0.0))+0.12,0.0,1.0)
	captor["war_reputation"]=clampf(float(captor.get("war_reputation",0.0))-0.25,-1.0,1.0)
	defeated["war_grievance"]=clampf(float(defeated.get("war_grievance",0.0))+0.20,0.0,1.0)
	return "Unrestricted plunder raises morale +6 and proceeds +35%%, but discipline −12, reputation −25, and grievance +20."


func _active_condition_average(state: Node,roster: Array[Dictionary]) -> float:
	if state==null: return 0.0
	var active:Array[Dictionary]=[]
	for person in roster:
		if bool(person.get("active_in_army",false)): active.append(person)
	return float(state.citizen_condition_profile(active).average_capacity)


func _seed_citizen_rosters() -> void:
	if is_instance_valid(attacker_roster_state): attacker_roster_state.free()
	if is_instance_valid(defender_roster_state): defender_roster_state.free()
	attacker_roster_state = GAME_STATE_SCRIPT.new()
	defender_roster_state = GAME_STATE_SCRIPT.new()
	add_child(attacker_roster_state)
	add_child(defender_roster_state)
	attacker_roster = _create_side_roster(attacker_roster_state,live_attacker.get("formations",[]),int(seed_input.value)^0x4a31,true,int(live_attacker.get("reserve_manpower",0)))
	defender_roster = _create_side_roster(defender_roster_state,live_defender.get("formations",[]),int(seed_input.value)^0x7c19,true,int(live_defender.get("reserve_manpower",0)))
	# Leadership balance-test preset: both forces enter in identical peak condition.
	live_attacker["morale"]=1.0
	live_defender["morale"]=1.0


func _create_side_roster(state: Node,formations: Array,roster_seed: int,fully_ready:=false,reserves:=0) -> Array[Dictionary]:
	state.world_seed=roster_seed
	state.population_health=0.76
	state.food_security=0.80
	var rng:=RandomNumberGenerator.new()
	rng.seed=roster_seed
	var roster: Array[Dictionary]=[]
	for cohort_index in formations.size():
		for soldier_index in int(formations[cohort_index].get("count",0)):
			var person:Dictionary=state._create_citizen(rng,rng.randi_range(18,29) if fully_ready else rng.randi_range(18,55),"Battle Lab")
			if fully_ready:
				person["strength"]=1.0
				person["endurance"]=1.0
				person["agility"]=1.0
				person["health_condition"]=1.0
				person["nutrition_condition"]=1.0
				person["fatigue"]=0.0
			person["cohort_index"]=cohort_index
			person["active_in_army"]=true
			person["army_status"]="active"
			roster.append(person)
	for reserve_index in reserves:
		var person:Dictionary=state._create_citizen(rng,rng.randi_range(18,35),"Battle Lab Reserve")
		person["cohort_index"]=reserve_index%maxi(1,formations.size())
		person["active_in_army"]=false
		person["army_status"]="reserve"
		roster.append(person)
	return roster


func _apply_roster_losses(roster: Array[Dictionary],old_formations: Array,new_formations: Array,breakdown: Dictionary={}) -> void:
	var statuses:Array[String]=[]
	for index in int(breakdown.get("killed",0)): statuses.append("killed")
	for index in int(breakdown.get("wounded",0)): statuses.append("wounded")
	for index in int(breakdown.get("scattered",0)): statuses.append("scattered")
	var status_index:=0
	for cohort_index in mini(old_formations.size(),new_formations.size()):
		var losses:=maxi(0,int(old_formations[cohort_index].count)-int(new_formations[cohort_index].count))
		if losses<=0: continue
		var candidates:Array[Dictionary]=[]
		for person in roster:
			if bool(person.get("active_in_army",false)) and int(person.get("cohort_index",-1))==cohort_index:
				candidates.append(person)
		candidates.sort_custom(func(a:Dictionary,b:Dictionary)->bool: return float(a.get("health_condition",1.0))<float(b.get("health_condition",1.0)))
		for index in mini(losses,candidates.size()):
			candidates[index]["active_in_army"]=false
			candidates[index]["army_status"]=statuses[status_index] if status_index<statuses.size() else "wounded"
			status_index+=1


func _sync_roster_to_formations(roster: Array[Dictionary],formations: Array) -> void:
	for cohort_index in formations.size():
		var target:=int(formations[cohort_index].get("count",0))
		var active:=0
		var candidates:Array[Dictionary]=[]
		for person in roster:
			if int(person.get("cohort_index",-1))!=cohort_index: continue
			if bool(person.get("active_in_army",false)): active+=1
			elif String(person.get("army_status","")) not in ["killed","captured","paroled","forced_labor"]: candidates.append(person)
		# Unassigned reserves can be retrained into a depleted cohort.
		if active+candidates.size()<target:
			for person in roster:
				if bool(person.get("active_in_army",false)): continue
				if person in candidates: continue
				if String(person.get("army_status","")) in ["killed","captured","paroled","forced_labor"]: continue
				candidates.append(person)
		for index in mini(maxi(0,target-active),candidates.size()):
			candidates[index]["active_in_army"]=true
			candidates[index]["army_status"]="active"
			candidates[index]["cohort_index"]=cohort_index


func _apply_battle_fatigue(roster: Array[Dictionary],amount: float) -> void:
	for person in roster:
		if not bool(person.get("active_in_army",false)): continue
		var endurance:=float(person.get("endurance",0.5))
		person["fatigue"]=clampf(float(person.get("fatigue",0.0))+amount*(1.25-endurance*0.5),0.0,1.0)


func _refresh_condition_meter(meter: Dictionary,state: Node,roster: Array[Dictionary]) -> void:
	if state==null: return
	var active:Array[Dictionary]=[]
	for person in roster:
		if bool(person.get("active_in_army",false)): active.append(person)
	var profile:Dictionary=state.citizen_condition_profile(active)
	var descriptions:Array[String]=[]
	for index in mini(4,(profile.bands as Array).size()):
		var band:Dictionary=profile.bands[index]
		var segment:ColorRect=meter.segments[index]
		segment.size_flags_stretch_ratio=maxf(0.001,float(band.share))
		segment.visible=int(band.count)>0
		segment.tooltip_text="%s: %d soldiers (%.0f%%)" % [band.label,band.count,float(band.share)*100.0]
		var short_label:String=String({"Ready":"RDY","Capable":"CAP","Strained":"STR","Unfit":"UNFIT"}.get(String(band.label),String(band.label).to_upper()))
		descriptions.append("%s %d" % [short_label,int(band.count)])
	meter.title.text="ARMY CONDITION  •  %s" % "   ".join(descriptions)


func _aggregate_cohort_stats(evaluation: Array[Dictionary]) -> Dictionary:
	var attack := 0.0
	var defense := 0.0
	for cohort in evaluation:
		attack += float(cohort.count) * float(cohort.attack)
		defense += float(cohort.count) * float(cohort.defense)
	return {"attack": attack, "defense": defense}


func _update_card_side(cards: Array[Dictionary], evaluation: Array[Dictionary], formations: Array) -> void:
	for index in mini(cards.size(), evaluation.size()):
		var cohort: Dictionary = evaluation[index]
		var count := int(formations[index].get("count", cohort.count)) if index < formations.size() else int(cohort.count)
		cards[index].input.value = count
		cards[index].equipment.value=int(formations[index].get("equipment",cohort.get("equipment",count))) if index<formations.size() else int(cohort.get("equipment",count))
		if cards[index].ammunition!=null: cards[index].ammunition.value=int(formations[index].get("ammunition",cohort.get("ammunition",0))) if index<formations.size() else int(cohort.get("ammunition",0))
		var matchup_note := ""
		if float(cohort.matchup) >= 1.12:
			matchup_note = "  ▲ COUNTER"
		elif float(cohort.matchup) <= 0.88:
			matchup_note = "  ▼ EXPOSED"
		var ammunition_note:="  ARW %.0f%%" % (float(cohort.get("ammunition_ratio",1.0))*100.0) if int(cohort.get("ammunition_required",0))>0 else ""
		cards[index].stats.text = "ATK %.2f   DEF %.2f   EQ %.0f%%%s%s" % [cohort.attack,cohort.defense,float(cohort.get("equipment_ratio",1.0))*100.0,ammunition_note,matchup_note]


func _update_live_display(status: String) -> void:
	_update_cohort_cards()
	_update_strength()
	outcome_label.text = "%s  •  Round %d" % [status, live_round]
	attacker_summary.text = "RIVER HOST   %d troops   •   Morale %.2f" % [live_attacker.troops, live_attacker.morale]
	defender_summary.text = "Morale %.2f   •   %d troops   HILL GUARD" % [live_defender.morale, live_defender.troops]
	attacker_remaining_bar.value = float(live_attacker.troops) / float(live_attacker_initial) * 100.0
	defender_remaining_bar.value = float(live_defender.troops) / float(live_defender_initial) * 100.0
	results.clear()
	results.append_text("[font_size=18][color=#d3b46f]LIVE ROUND RECORD[/color][/font_size]\n\n")
	var first_visible:=maxi(0,round_records.size()-2)
	for record in round_records.slice(first_visible):
		var order_text := "  [color=#f2c66d]PUSHED[/color]" if bool(record.pushed) else ""
		results.append_text("[b]ROUND %02d[/b]%s  [color=#d3b46f]%s[/color]   [color=#efaa9d]River −%d[/color] / [color=#9dc9ef]Hill −%d[/color]\n" % [record.round, order_text,record.get("intensity","Combat"),record.attacker_losses,record.defender_losses])
		results.append_text("[color=#9ca9b7]%s[/color]\n" % String(record.get("event","")))


func _show_result(battle: Dictionary) -> void:
	var attacker: Dictionary = battle.attacker
	var defender: Dictionary = battle.defender
	var heading := String(battle.outcome).replace("_", " ").capitalize()
	outcome_label.text = "%s  •  %d rounds" % [heading, battle.round_count]
	attacker_summary.text = "RIVER HOST   %d remaining   •   %d lost" % [attacker.remaining_troops, attacker.casualties]
	defender_summary.text = "%d lost   •   %d remaining   HILL GUARD" % [defender.casualties, defender.remaining_troops]
	attacker_remaining_bar.value = float(attacker.remaining_troops) / maxf(1.0, float(attacker.initial_troops)) * 100.0
	defender_remaining_bar.value = float(defender.remaining_troops) / maxf(1.0, float(defender.initial_troops)) * 100.0
	results.clear()
	results.append_text("[font_size=18][color=#d3b46f]ROUND RECORD[/color][/font_size]    [color=#82909e]Seed %d  •  Terrain ×%.2f[/color]\n\n" % [battle.seed, battle.terrain_defense])
	for round_data in battle.rounds:
		var row_color := "#eef2f5" if int(round_data.round) % 2 == 1 else "#aeb8c2"
		results.append_text("[color=%s][b]ROUND %02d[/b]     [color=#efaa9d]River −%d[/color]   %d left   Morale %.2f      [color=#65717e]│[/color]      [color=#9dc9ef]Hill −%d[/color]   %d left   Morale %.2f[/color]\n" % [
			row_color,
			round_data.round,
			round_data.attacker_losses,
			round_data.attacker_remaining,
			round_data.attacker_morale,
			round_data.defender_losses,
			round_data.defender_remaining,
			round_data.defender_morale
		])
		results.append_text("[color=#82909e]%s • %s[/color]\n" % [round_data.get("intensity","Combat"),round_data.get("event","")])
	var termination:Dictionary=battle.get("termination",{})
	if not termination.is_empty() and String(termination.get("type","continued"))!="continued":
		results.append_text("\n[color=#d3b46f][b]BATTLE AFTERMATH[/b][/color]  %s\n" % String(termination.get("summary","")))
