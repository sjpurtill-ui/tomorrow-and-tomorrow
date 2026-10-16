extends VBoxContainer
## Home's retained, illustrated reading. This view consumes snapshots and invokes
## the provider's existing commands; it never calculates or changes game state.
const T = preload("res://scripts/hud/hud_tokens.gd")
const Portraits = preload("res://scripts/hud/people_town_portrait.gd")

var data: Dictionary = {}
var comparison_active := false
var comparison: Dictionary = {}
var _refs: Dictionary = {}
var _buttons: Dictionary = {}
var _hero: BoxContainer
var _society: BoxContainer
var _foundations: BoxContainer
var _portrait: TextureRect
var _picture_frame: AspectRatioContainer
var _drivers: Dictionary = {}
var _risk_dots: RiskDots
var _food_graph: FoodFlow
var _research_bar: ProgressBar
var _adoption_bar: ProgressBar
var _standing_gauges: Dictionary = {}
var _service_gauges: Dictionary = {}
var _works: VBoxContainer
var _work_select: OptionButton
var _priority: OptionButton
var _founding: OptionButton
var _works_open := false
var _work_id := ""
var _art_path := ""
var _scope_id := ""
var _comparison_stamp := 0
var _layout_width := -1.0
var _content: VBoxContainer
var _content_margin: MarginContainer

func setup(block: Dictionary) -> void:
	name = "SettlementOverview"
	theme = T.control_theme()
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 22)
	_build()
	resized.connect(_layout)
	_hero.resized.connect(_layout)
	update_block(block)
	_layout()
	call_deferred("_layout")

func _process(_delta: float) -> void:
	# Containers finish their first sizing after setup; settle against the real
	# content width rather than the zero-width node's provisional orientation.
	if _hero == null: return
	if not is_equal_approx(_layout_width, _hero.size.x): _layout()
	_fit_picture()

func _build() -> void:
	_content_margin = MarginContainer.new()
	_content_margin.name = "ReadingWidth"
	add_child(_content_margin)
	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 22)
	_content_margin.add_child(_content)
	var population := HFlowContainer.new()
	population.name = "PopulationSummary"
	population.add_theme_constant_override("h_separation", 28)
	population.add_theme_constant_override("v_separation", 8)
	_content.add_child(population)
	var local := _column(population)
	local.custom_minimum_size.x = 155
	_text(local, "Living here", 14, T.MUTED)
	_label(local, "population", 32)
	var change := _column(population)
	change.custom_minimum_size.x = 215
	_text(change, "Population since year start", 14, T.MUTED)
	_label(change, "year", 22)
	var vital := _column(population)
	vital.custom_minimum_size.x = 290
	_text(vital, "Recorded births and deaths", 14, T.MUTED)
	_label(vital, "vitals", 22)
	_label(vital, "vital_period", 14, T.MUTED)
	_hero = BoxContainer.new()
	_hero.name = "LivesHero"
	_hero.add_theme_constant_override("separation", 22)
	_content.add_child(_hero)
	var scene := _column(_hero, 12)
	scene.name = "HomeScene"
	scene.size_flags_stretch_ratio = 1.18
	_label(scene, "town", 32)
	_picture_frame = AspectRatioContainer.new()
	_picture_frame.name = "PortraitFrame"
	_picture_frame.ratio = 1.35
	_picture_frame.stretch_mode = AspectRatioContainer.STRETCH_WIDTH_CONTROLS_HEIGHT
	_picture_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_picture_frame.clip_contents = true
	scene.add_child(_picture_frame)
	_portrait = TextureRect.new()
	_portrait.name = "HomePortrait"
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_picture_frame.add_child(_portrait)
	_label(scene, "housing", 20)
	_label(scene, "housing_detail", 14, T.MUTED)
	_label(scene, "housing_effect", 14, T.BODY)
	var right := _column(_hero, 12)
	right.name = "HumanConsequences"
	_text(right, "The first year of life", 14, T.GOLD_TEXT)
	_text(right, "What shapes a child's chances?", 25)
	var drivers := GridContainer.new()
	drivers.name = "Conditions"
	drivers.columns = 4
	drivers.add_theme_constant_override("h_separation", 14)
	right.add_child(drivers)
	for entry in [["water", "Water", "drinking need"], ["food", "Food", "need eaten"], ["care", "Care", "coverage now"], ["shelter", "Shelter", "places for all"]]:
		var box := _column(drivers, 3)
		var title := _text(box, entry[1], 14, T.BODY)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var value := _text(box, "—", 25)
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var note := _text(box, entry[2], 14, T.MUTED)
		note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var bar := _bar(box)
		_drivers[entry[0]] = {"value": value, "bar": bar, "box": box}
	var outcome := HBoxContainer.new()
	outcome.name = "InfantRisk"
	outcome.add_theme_constant_override("separation", 16)
	right.add_child(outcome)
	_risk_dots = RiskDots.new()
	_risk_dots.custom_minimum_size = Vector2(96, 100)
	outcome.add_child(_risk_dots)
	var risk := _column(outcome, 3)
	_text(risk, "Current estimated risk", 14, T.MUTED)
	var value := _label(risk, "risk", 34, T.AMBER_TEXT)
	value.name = "RiskValue"
	_text(risk, "of dying before age one", 16)
	_label(risk, "risk_note", 14, T.MUTED)
	_label(right, "care", 14, T.BODY)
	var compare := HFlowContainer.new()
	compare.add_theme_constant_override("h_separation", 6)
	compare.add_theme_constant_override("v_separation", 6)
	right.add_child(compare)
	var current := _action(compare, "Current", "", "CareCurrent")
	current.pressed.connect(_show_current)
	var more := _action(compare, "Compare +5 points to care", "", "CareCompare")
	more.tooltip_text = "Preview five percentage points to Keeping & caring across the civilization. Uses the existing donor and food-protection rules. Changes no assignments."
	more.pressed.connect(_compare_care)
	_label(right, "comparison", 14)
	var actions := HFlowContainer.new()
	actions.add_theme_constant_override("h_separation", 8)
	right.add_child(actions)
	_action(actions, "Assign care", "on_assign_care", "AssignCare", true)
	_action(actions, "Health & families", "on_health", "HealthDetail")
	right.move_child(actions, _refs.comparison.get_index())
	_rule()
	var food_band := PanelContainer.new()
	food_band.name = "FoodBand"
	var band_style := T.flat(T.ROW_BG)
	band_style.content_margin_left = 18
	band_style.content_margin_right = 18
	band_style.content_margin_top = 14
	band_style.content_margin_bottom = 14
	food_band.add_theme_stylebox_override("panel", band_style)
	_content.add_child(food_band)
	var food_content := _column(food_band, 10)
	var food_heading := HBoxContainer.new()
	food_content.add_child(food_heading)
	_text(food_heading, "Keeping people fed", 20)
	_link(food_heading, "Food & reserves ↗", "on_food", "FoodDetail")
	var food := BoxContainer.new()
	food.name = "HomeFoodFlow"
	food.add_theme_constant_override("separation", 28)
	food_content.add_child(food)
	_refs.food_box = food
	var flow := _column(food, 4)
	_label(flow, "food_period", 13, T.MUTED)
	_food_graph = FoodFlow.new()
	_food_graph.custom_minimum_size.y = 94
	flow.add_child(_food_graph)
	var reserves := _column(food, 4)
	reserves.size_flags_stretch_ratio = .6
	_text(reserves, "IN RESERVE", 12, T.MUTED)
	_label(reserves, "reserves", 27)
	_label(reserves, "balance", 16)
	_label(reserves, "food_note", 13, T.MUTED)
	var civilization := _column(_content, 9)
	_text(civilization, "ACROSS OUR CIVILIZATION", 12, T.GOLD_TEXT)
	_society = BoxContainer.new()
	_society.name = "HomeSociety"
	_society.add_theme_constant_override("separation", 24)
	civilization.add_child(_society)
	var learning := _column(_society, 6)
	learning.size_flags_stretch_ratio = 1.15
	_link(learning, "Research ↗", "on_research", "ResearchDetail", 19)
	_label(learning, "question", 18)
	var research_meters := HBoxContainer.new()
	research_meters.add_theme_constant_override("separation", 14)
	learning.add_child(research_meters)
	var exploration := _column(research_meters, 4)
	_label(exploration, "research_progress", 13, T.TEAL_TEXT)
	_research_bar = _bar(exploration)
	var adoption := _column(research_meters, 4)
	_label(adoption, "research_adoption", 13, T.GOLD_TEXT)
	_adoption_bar = _bar(adoption)
	_adoption_bar.add_theme_stylebox_override("fill", T.flat(T.GOLD))
	_label(learning, "research_effect", 16)
	_label(learning, "research_usage", 13, T.MUTED)
	_label(learning, "research_counts", 13, T.MUTED)
	var culture := _column(_society, 6)
	_link(culture, "Culture & values ↗", "on_culture", "CultureDetail", 19)
	_label(culture, "course", 18)
	_label(culture, "culture_effect", 16)
	_label(culture, "culture_meaning", 13, T.MUTED)
	var regard := _column(_society, 6)
	regard.size_flags_stretch_ratio = .85
	var regard_title := _text(regard, "How others see us", 19)
	regard_title.custom_minimum_size.y = 32
	regard_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var gauges := HBoxContainer.new()
	gauges.add_theme_constant_override("separation", 18)
	regard.add_child(gauges)
	for key: String in ["awe", "draw"]:
		var item := _column(gauges, 0)
		var gauge := StandingGauge.new()
		gauge.custom_minimum_size = Vector2(100, 73)
		gauge.ink = T.GOLD if key == "awe" else T.TEAL
		item.add_child(gauge)
		_standing_gauges[key] = gauge
		var caption := _label(item, key, 14)
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label(regard, "regard_meaning", 13, T.MUTED)
	_foundations = BoxContainer.new()
	_foundations.name = "EverydayFoundations"
	_foundations.add_theme_constant_override("separation", 24)
	_content.add_child(_foundations)
	var work := _column(_foundations, 6)
	work.size_flags_stretch_ratio = 1.3
	_link(work, "Buildings & works ↗", "on_works", "WorkDetail", 19)
	_label(work, "foundations", 14, T.MUTED)
	var services := HBoxContainer.new()
	services.name = "LocalServiceReadings"
	services.add_theme_constant_override("separation", 20)
	work.add_child(services)
	_refs.service_readings = services
	for entry in [["services", "Services"], ["roads", "Roads"], ["craft", "Builders' craft"]]:
		var item := _column(services, 3)
		_text(item, entry[1], 13, T.MUTED)
		var amount := _text(item, "—", 22)
		var bar := _bar(item)
		_service_gauges[entry[0]] = {"value": amount, "bar": bar}
	_label(work, "work_effects", 14, T.BODY)
	var work_actions := HFlowContainer.new()
	work_actions.add_theme_constant_override("h_separation", 8)
	work.add_child(work_actions)
	var toggle := _link(work_actions, "Water & sanitation ›", "", "WaterWorksToggle")
	toggle.pressed.connect(func() -> void: _works_open = not _works_open; _works.visible = _works_open)
	var watch := _column(_foundations, 6)
	var watch_title := _text(watch, "On watch", 19)
	watch_title.custom_minimum_size.y = 32
	watch_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label(watch, "watch", 22)
	_label(watch, "watch_reason", 14, T.MUTED)
	_works = _column(_content, 8)
	_works.name = "WaterWorks"
	_works.visible = false
	_text(_works, "Water & sanitation", 22)
	_label(_works, "works_progress", 14, T.MUTED)
	_work_select = _selector(_works, "WorkSelector")
	_work_select.item_selected.connect(_select_work)
	_label(_works, "work_sentence", 16)
	_label(_works, "work_cost", 14, T.MUTED)
	var start := _action(_works, "Start", "", "StartSelectedWork", true)
	start.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	start.pressed.connect(_start_work)
	var footer := _column(_content, 6)
	footer.name = "HomeLeadership"
	var leadership_row := BoxContainer.new()
	leadership_row.add_theme_constant_override("separation", 18)
	footer.add_child(leadership_row)
	_refs.leadership_row = leadership_row
	var identity := _column(leadership_row, 3)
	_label(identity, "leader", 18)
	_label(identity, "direction", 13, T.MUTED)
	var leadership := HFlowContainer.new()
	leadership.add_theme_constant_override("h_separation", 8)
	leadership.add_theme_constant_override("v_separation", 6)
	leadership.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	leadership.size_flags_stretch_ratio = 1.3
	leadership_row.add_child(leadership)
	_link(leadership, "Talk priorities", "on_leader", "TalkToLeader")
	_action(leadership, "Assign workers", "on_people", "PeopleDetail", true)
	_link(leadership, "Back to our leaders", "on_leaders", "BackToLeaders")
	_priority = _selector(leadership, "LeaderPriorities")
	_priority.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_priority.item_selected.connect(_select_priority)
	_label(footer, "work_warning", 14, T.AMBER_TEXT)
	var fix := _action(footer, "", "on_food_fix", "FoodFix")
	fix.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	fix.visible = false
	var ending := HFlowContainer.new()
	ending.add_theme_constant_override("h_separation", 20)
	ending.add_theme_constant_override("v_separation", 6)
	footer.add_child(ending)
	_link(ending, "Population & families ↗", "on_population", "PopulationDetail")
	_link(ending, "Visit this place ↗", "on_visit", "VisitVillage")
	_link(ending, "Rename", "on_rename", "RenamePlace")
	_founding = _selector(ending, "NewTownsChoice")
	_founding.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_founding.item_selected.connect(_select_founding)
	_label(footer, "founding", 14, T.MUTED)

func update_block(block: Dictionary) -> bool:
	if _refs.is_empty(): return false
	var lives: Dictionary = block.get("lives", {})
	var id := String(lives.get("scope", {}).get("id", ""))
	# A displayed comparison belongs to its captured state, not a later day or town.
	if id != _scope_id or (comparison_active and hash(lives) != _comparison_stamp):
		comparison_active = false
		comparison = {}
	_scope_id = id
	data = block
	_fill()
	return true

func _fill() -> void:
	var lives: Dictionary = data.get("lives", {})
	if not bool(lives.get("ok", false)):
		for key: String in _refs:
			if _refs[key] is Label: _set_text(key, "")
		_set_text("population", String(lives.get("reason", "Condition readings are not available yet.")))
		_set_text("risk", "Not measured")
		for key: String in _drivers: _driver(key, -1, false, "Not measured")
		_food_graph.reading = {}
		_food_graph.queue_redraw()
		for key: String in _standing_gauges:
			var gauge: StandingGauge = _standing_gauges[key]
			gauge.value = -1
			gauge.tooltip_text = "Not recorded"
			gauge.accessibility_name = "%s: not recorded" % key.capitalize()
			gauge.queue_redraw()
		_refs.service_readings.visible = false
		_research_bar.visible = false
		_adoption_bar.visible = false
		_risk_dots.risk = -1
		_risk_dots.queue_redraw()
		_fill_actions()
		_fill_works()
		return
	var population: Dictionary = lives.get("population", {})
	var conditions: Dictionary = lives.get("conditions", {})
	var scope: Dictionary = lives.get("scope", {})
	var count := int(population.get("current", scope.get("population", 0)))
	_set_text("population", "%s people" % _num(count))
	_set_text("town", String(scope.get("name", data.get("town_name", "This settlement"))))
	_set_text("year", "%s people" % _signed(float(population.get("year_delta", 0))) if bool(population.get("year_start_known", false)) else "No dated baseline")
	var vital: Dictionary = population.get("vitals", {})
	_set_text("vitals", "%s born · %s died" % [_num(vital.get("births", 0)), _num(vital.get("deaths", 0))] if bool(vital.get("known", false)) else "No dated reports yet")
	_set_text("vital_period", "Days %d–%d · natural change %s" % [int(vital.get("from_day", 0)), int(vital.get("to_day", 0)), _signed(vital.get("natural_change", 0))] if bool(vital.get("known", false)) else "Recorded totals will appear as days pass.")
	_refs.vital_period.tooltip_text = String(vital.get("note", "Births minus deaths is natural change; it does not explain migration or the whole population change."))
	_update_art(count)
	var housing: Dictionary = conditions.get("housing", {})
	var cap := int(housing.get("capacity", 0))
	_set_text("housing", "Shelter places for everyone" if cap >= count else "%s people without a shelter place" % _num(maxi(0, count - cap)))
	_set_text("housing_detail", "%s people · %s places · %s spare\nHome quality %s/100 · upkeep %s%%" % [_num(count), _num(cap), _num(housing.get("spare", 0)), _num(float(housing.get("quality", 0)) * 100), _num(float(housing.get("upkeep", 0)) * 100)])
	var illness := (1.0 - float(housing.get("illness_factor", 1))) * 100.0
	_set_text("housing_effect", "Home quality reduces illness deaths by %s%% in the current calculation." % _num(illness) if illness > .01 else "Shelter capacity and home quality are separate needs.")
	var water: Dictionary = conditions.get("water", {})
	var food: Dictionary = conditions.get("food", {})
	var care: Dictionary = conditions.get("care", {})
	_driver("water", float(water.get("intake_ratio", -1)), bool(water.get("known", false)), "Latest measured drinking intake / need")
	_driver("food", float(food.get("intake_ratio", -1)), bool(food.get("known", false)), "Latest recorded food eaten / daily need")
	_driver("care", float(care.get("current", -1)), bool(care.get("known", false)), "Current care coverage; it changes gradually toward the target")
	_driver("shelter", float(housing.get("coverage", -1)), not housing.is_empty(), "Shelter places / population; this is not a building count")
	var risk: Dictionary = conditions.get("infant_risk", {})
	var known := bool(risk.get("known", false))
	_set_text("risk", "%s in 100" % _num(risk.get("per_100", 0)) if known else "Not measured")
	_set_text("risk_note", String(risk.get("note", "Projected risk, not recorded deaths.")))
	_risk_dots.risk = float(risk.get("per_100", -1)) if known else -1
	_risk_dots.queue_redraw()
	var assigned := float(care.get("assigned", 0))
	var allocation := "%s assigned to keeping & caring" % _num(assigned)
	if not is_equal_approx(assigned, roundf(assigned)):
		allocation = "Care allocation: %s worker-equivalents" % _num(assigned)
	_set_text("care", "Care %s%% now; target %s%%. Coverage changes gradually.\n%s; effective effort %s worker-equivalents." % [_num(float(care.get("current", 0)) * 100), _num(float(care.get("target", 0)) * 100), allocation, _num(care.get("workers", 0))] if bool(care.get("known", false)) else "Care coverage is not measured yet.")
	_refs.care.tooltip_text = "Coverage moves 1/%d of the remaining gap toward its target each day.\n%s" % [int(care.get("settle_days", 60)), str(care.get("practices", []))]
	_fill_comparison()
	_fill_food(food)
	_fill_society(lives)
	_fill_foundations(lives.get("foundations", {}))
	_fill_actions()
	_fill_works()

func _fill_food(food: Dictionary) -> void:
	var shown := food
	var compared := comparison_active and bool(comparison.get("ok", false))
	if compared:
		shown = comparison.get("after", {}).get("food", food)
	_set_text("food_period", "Compared assignment · same captured conditions" if compared else String(food.get("period", "Latest recorded daily flow")))
	_food_graph.reading = shown if bool(food.get("known", false)) or compared else {}
	_food_graph.queue_redraw()
	var days := float(food.get("stored_days", -1))
	_set_text("reserves", "%s days of meals" % _num(days) if days >= 0 else "Not measured")
	_set_text("balance", "Stores %s rations / day" % _signed(float(shown.get("net", 0))) if bool(food.get("known", false)) or compared else "No daily balance recorded")
	_set_text("food_note", "%s rations held · at current daily need" % _num(food.get("stock", 0)) if bool(food.get("known", false)) else "Reserves have not been measured.")
	_refs.reserves.tooltip_text = "Current stored food divided by daily need. This is not a starvation countdown: production, intake and losses continue to change."
	_refs.balance.add_theme_color_override("font_color", T.AMBER_TEXT if float(shown.get("net", 0)) < 0 else T.GREEN_TEXT)

func _fill_comparison() -> void:
	var text := "Care builds gradually. Compare the allocation's care target and food balance before choosing who does the work."
	if comparison_active:
		if bool(comparison.get("ok", false)):
			var before: Dictionary = comparison.get("before", {})
			var after: Dictionary = comparison.get("after", {})
			var changes: Array[String] = []
			for row: Dictionary in comparison.get("actual_transfers", []):
				var role := String(row.get("role", ""))
				changes.append("%s %s" % ["Keeping & caring" if role == "Administration" else role, _signed(row.get("delta", 0))])
			text = "This settlement: care target %s%% → %s%%; food balance %s → %s rations/day.\nAll towns: %s\n%s" % [_num(float(before.get("care", {}).get("target", 0)) * 100), _num(float(after.get("care", {}).get("target", 0)) * 100), _signed(before.get("food", {}).get("net", 0)), _signed(after.get("food", {}).get("net", 0)), "; ".join(changes), String(comparison.get("risk_note", "Current infant risk is unchanged here; no future risk forecast is available."))]
			var warnings: Array = comparison.get("warnings", []).duplicate()
			warnings.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return _warning_rank(a) < _warning_rank(b))
			if not warnings.is_empty():
				text += "\n" + String(warnings[0].get("text", ""))
				if warnings.size() > 1: text += " (+%d more conditions; see tooltip)" % (warnings.size() - 1)
			_refs.comparison.tooltip_text = "%s\n%s\n%s" % [String(comparison.get("scope", "")), str(comparison.get("warnings", [])), str(comparison.get("assumptions", []))]
		else: text = String(comparison.get("reason", "A comparison is not available yet."))
	_set_text("comparison", text)
	var compare: Button = _buttons.CareCompare
	compare.disabled = not _valid(data.get("compare_care"))
	_mark_comparison(_buttons.CareCurrent, not comparison_active)
	_mark_comparison(compare, comparison_active)

func _fill_society(lives: Dictionary) -> void:
	var research: Dictionary = lives.get("research", {})
	var question: Dictionary = research.get("current", {})
	_set_text("question", String(question.get("name", research.get("empty", "No active question is recorded."))))
	var progress := float(question.get("progress", 0))
	_set_text("research_progress", "Explored · %s%%" % _num(progress * 100) if not question.is_empty() else "")
	_set_text("research_adoption", "Adoption / trial · %s%%" % _num(float(question.get("adoption", 0)) * 100) if not question.is_empty() else "")
	_research_bar.visible = not question.is_empty()
	_research_bar.value = progress * 100
	_research_bar.tooltip_text = "Question explored: %s%%" % _num(progress * 100)
	_adoption_bar.visible = not question.is_empty()
	_adoption_bar.value = float(question.get("adoption", 0)) * 100
	_adoption_bar.tooltip_text = "Recorded adoption / trial use: %s%%" % _num(float(question.get("adoption", 0)) * 100)
	var effects: Array[String] = []
	for row: Dictionary in question.get("effects", []):
		if bool(row.get("inert", false)): continue
		effects.append("%s %s" % [String(row.get("label", "")), String(row.get("amount", ""))])
	_set_text("research_effect", "At full use: " + " · ".join(effects.slice(0, 2)) if not effects.is_empty() else "")
	_refs.research_effect.tooltip_text = "\n".join(effects)
	_set_text("research_usage", "Needs practice & supplies." if not String(question.get("usage", "")).is_empty() else "")
	_refs.research_usage.tooltip_text = String(question.get("usage", ""))
	_set_text("research_counts", "%d inquiries · %d discoveries · %d with adoption" % [int(research.get("active_count", 0)), int(research.get("known_count", 0)), int(research.get("adopted_count", 0))])
	var culture: Dictionary = lives.get("culture", {})
	var course: Dictionary = culture.get("course", {})
	_set_text("course", String(course.get("name", "No course recorded")))
	var values: Array[String] = []
	for row: Dictionary in culture.get("effects", []):
		if absf(float(row.get("amount", 0))) < .01: continue
		var label := String(row.get("label", row.get("id", "")))
		if String(row.get("id", "")) in ["births", "fertility"] or label == "Births": label = "Conception support"
		values.append("%s %s%s" % [label, _signed(row.get("amount", 0)), " pts" if String(row.get("unit", "")) == "points" else "%"])
	_set_text("culture_effect", " · ".join(values.slice(0, 3)) if not values.is_empty() else "No active course or value modifiers recorded.")
	_refs.culture_effect.tooltip_text = "\n".join(values)
	_set_text("culture_meaning", String(course.get("vision", "")))
	var regard: Dictionary = lives.get("regard", {})
	var measured := bool(regard.get("known", false))
	_set_text("awe", "Awe")
	_set_text("draw", "Draw")
	for key: String in _standing_gauges:
		var gauge: StandingGauge = _standing_gauges[key]
		gauge.value = float(regard.get(key, 0)) * 100 if measured else -1
		gauge.tooltip_text = "%s: %s / 100. Age-relative standing." % [key.capitalize(), _num(gauge.value)] if measured else "Not recorded"
		gauge.accessibility_name = "%s: %s out of 100. Age-relative standing." % [key.capitalize(), _num(gauge.value)] if measured else "%s: not recorded" % key.capitalize()
		gauge.queue_redraw()
	var date := int(regard.get("day", -1))
	_set_text("regard_meaning", "Age-relative standing%s" % (" · day %d" % date if date >= 0 else "") if measured else "Standing has not been measured yet.")
	_refs.awe.tooltip_text = "Awe reflects might, works and learning."
	_refs.draw.tooltip_text = "Draw also reflects culture, plenty, order and diplomacy."
	_refs.regard_meaning.tooltip_text = "Awe reflects might, works and learning. Draw also reflects culture, plenty, order and diplomacy.\n" + String(regard.get("note", ""))

func _fill_foundations(foundation: Dictionary) -> void:
	_refs.service_readings.visible = bool(foundation.get("known", false))
	if not bool(foundation.get("known", false)):
		_set_text("foundations", "Local services are not measured yet.")
		_set_text("work_effects", "")
		_set_text("watch", "Local protection is not measured yet.")
		_set_text("watch_reason", "")
		return
	_set_text("foundations", "")
	for entry in [["services", float(foundation.get("service_coverage", 0)) * 100, 100.0], ["roads", float(foundation.get("road_quality", 0)) * 100, 100.0], ["craft", float(foundation.get("craft", 0)), float(foundation.get("craft_max", 10))]]:
		var gauge: Dictionary = _service_gauges[entry[0]]
		gauge.value.text = "%s / %s" % [_num(entry[1]), _num(entry[2])]
		gauge.bar.value = float(entry[1]) / maxf(.001, float(entry[2])) * 100
		gauge.value.tooltip_text = "Service and quality measures, not building counts."
	var effects: Array[String] = []
	for pair in [["making_multiplier", "Making"], ["stored_rot_multiplier", "Stored-food decay"], ["haul_multiplier", "Hauling"]]:
		var change := (float(foundation.get(pair[0], 1)) - 1.0) * 100.0
		if absf(change) >= .01: effects.append("%s %s%%" % [pair[1], _signed(change)])
	_set_text("work_effects", " · ".join(effects) if not effects.is_empty() else "No output modifiers from local services yet.")
	_refs.work_effects.tooltip_text = "Service and quality measures, not building counts."
	var watch: Dictionary = foundation.get("watch", {})
	if watch.is_empty():
		_set_text("watch", "Local protection is not measured yet.")
		_set_text("watch_reason", "")
		return
	_set_text("watch", "%s serving · %s could muster" % [_num(watch.get("standing", 0)), _num(watch.get("mobilisable", 0))])
	var blockers: Array[String] = []
	for row: Dictionary in watch.get("blockers", []):
		# The danger threshold describes the people's automatic decision; it is
		# not a material shortage or a suggestion to put more lives in danger.
		if String(row.get("kind", "")) == "danger":
			blockers.append("People see no need yet (danger %d; trigger %d)" % [floori(float(row.get("have", 0)) * 100 + .0001), roundi(float(row.get("need", 0)) * 100)])
		else: blockers.append(String(row.get("text", "")))
	var words := String(watch.get("short", ""))
	var building: Dictionary = watch.get("building", {})
	if not building.is_empty(): words += " · %s %s%% built" % [String(building.get("short", "Works")), _num(float(building.get("progress", 0)) * 100)]
	elif not watch.get("next", {}).is_empty(): words += " · next: %s" % String(watch.next.get("short", "defense works"))
	if not blockers.is_empty(): words += "\n" + "; ".join(blockers.slice(0, 2))
	elif not String(watch.get("reason", "")).is_empty(): words += "\n" + String(watch.reason)
	_set_text("watch_reason", words)
	_refs.watch_reason.tooltip_text = "\n".join(blockers)

func _fill_actions() -> void:
	for button_name: String in _buttons:
		var button: Button = _buttons[button_name]
		var key := String(button.get_meta("callback", ""))
		if not key.is_empty():
			button.disabled = not _valid(data.get(key))
			button.visible = _valid(data.get(key))
	_buttons.BackToLeaders.visible = bool(data.get("ruler_sets_work", false)) and _valid(data.get("on_leaders"))
	var leader: Dictionary = data.get("leader", {})
	_set_text("leader", "%s%s" % [String(leader.get("name", "Our leaders")), " · age %s" % str(leader.age) if leader.has("age") else ""])
	_set_text("direction", String(data.get("direction", "")))
	_refs.direction.tooltip_text = String(data.get("direction_tip", ""))
	var choices: Array = data.get("choices", [])
	_priority.visible = bool(data.get("can_direct", false)) and not bool(data.get("ruler_sets_work", false)) and not choices.is_empty()
	_sync_options(_priority, choices, String(data.get("current", "")), "label")
	var warning: Dictionary = data.get("work_warning", {})
	_set_text("work_warning", String(warning.get("text", "")))
	_buttons.FoodFix.text = String(warning.get("fix_text", ""))
	_buttons.FoodFix.visible = _valid(data.get("on_food_fix")) and not _buttons.FoodFix.text.is_empty()
	var founding: Dictionary = data.get("founding", {})
	var options: Array = founding.get("options", [])
	_founding.visible = not options.is_empty()
	_sync_options(_founding, options, "leaders" if bool(founding.get("on", true)) else "ruler", "label")
	_set_text("founding", String(founding.get("words", "")))

func _fill_works() -> void:
	var works: Dictionary = data.get("works", {})
	var offers: Array = works.get("offers", [])
	_buttons.WaterWorksToggle.visible = not works.is_empty()
	_works.visible = _works_open and not works.is_empty()
	_set_text("works_progress", "\n".join(works.get("progress", [])))
	var found := false
	for offer: Dictionary in offers:
		if String(offer.get("id", "")) == _work_id: found = true
	if not found and not offers.is_empty(): _work_id = String(offers[0].get("id", ""))
	_sync_options(_work_select, offers, _work_id, "title")
	_work_select.visible = not offers.is_empty()
	var selected := _selected_work()
	_set_text("work_sentence", String(selected.get("sentence", "")))
	var blocked := String(selected.get("blocked", ""))
	_set_text("work_cost", String(selected.get("cost", "")) + ("\n" + blocked if not blocked.is_empty() else ""))
	_buttons.StartSelectedWork.text = String(selected.get("action", "Start"))
	_buttons.StartSelectedWork.visible = not selected.is_empty()
	_buttons.StartSelectedWork.disabled = not blocked.is_empty() or not _valid(selected.get("on_press"))

func _selected_work() -> Dictionary:
	for offer: Dictionary in data.get("works", {}).get("offers", []):
		if String(offer.get("id", "")) == _work_id: return offer
	return {}

func _start_work() -> void:
	var offer := _selected_work()
	if String(offer.get("blocked", "")).is_empty() and _valid(offer.get("on_press")): offer.on_press.call()

func _select_work(index: int) -> void:
	_work_id = String(_work_select.get_item_metadata(index))
	_fill_works()

func _select_priority(index: int) -> void:
	var id := String(_priority.get_item_metadata(index))
	for option: Dictionary in data.get("choices", []):
		if String(option.get("id", "")) == id and _valid(option.get("on_press")): option.on_press.call(); return

func _select_founding(index: int) -> void:
	var id := String(_founding.get_item_metadata(index))
	for option: Dictionary in data.get("founding", {}).get("options", []):
		if String(option.get("id", "")) == id and _valid(option.get("on_press")): option.on_press.call(); return

func _show_current() -> void:
	comparison_active = false
	comparison = {}
	_fill()

func _compare_care() -> void:
	if not _valid(data.get("compare_care")): return
	comparison = data.compare_care.call()
	comparison_active = true
	_comparison_stamp = hash(data.get("lives", {}))
	_fill()

func capture_view_state() -> Dictionary:
	return {"works_open": _works_open, "work_id": _work_id}

func restore_view_state(state: Dictionary) -> void:
	_works_open = bool(state.get("works_open", false))
	_work_id = String(state.get("work_id", ""))
	_fill_works()

func _update_art(population: int) -> void:
	var path := "res://assets/ui/home/lives-hearth.png" if population >= 150 and population < 400 else Portraits.texture_path({"population": population})
	if path == _art_path: return
	var texture: Texture2D
	if ResourceLoader.exists(path): texture = load(path) as Texture2D
	elif FileAccess.file_exists(path):
		var image := Image.load_from_file(ProjectSettings.globalize_path(path))
		if image != null and not image.is_empty(): texture = ImageTexture.create_from_image(image)
	if texture == null:
		var fallback := Portraits.texture_path({"population": population})
		if ResourceLoader.exists(fallback): texture = load(fallback) as Texture2D
	if texture != null:
		_portrait.texture = texture
		_picture_frame.ratio = float(texture.get_width()) / maxf(1, texture.get_height())
		_art_path = path

func _layout() -> void:
	if _hero == null: return
	var margin := maxi(0, floori((size.x - 1320.0) * .5))
	if _content_margin.get_theme_constant("margin_left") != margin:
		_content_margin.add_theme_constant_override("margin_left", margin)
		_content_margin.add_theme_constant_override("margin_right", margin)
	_layout_width = _hero.size.x
	var available := _hero.size.x if _hero.size.x > 0 else size.x
	var narrow := available < 620
	_hero.vertical = narrow
	_society.vertical = available < 880
	_foundations.vertical = narrow
	(_refs.food_box as BoxContainer).vertical = narrow
	(_refs.leadership_row as BoxContainer).vertical = available < 800
	for child: Control in _hero.get_children(): child.custom_minimum_size.x = 0
	_fit_picture()

func _fit_picture() -> void:
	if _picture_frame == null or _picture_frame.size.x <= 0: return
	var height := ceilf(_picture_frame.size.x / maxf(.1, _picture_frame.ratio))
	if not is_equal_approx(_picture_frame.custom_minimum_size.y, height):
		_picture_frame.custom_minimum_size.y = height

func _mark_comparison(button: Button, selected: bool) -> void:
	# Selection changes ink only: identical typography and margins keep both
	# targets fixed while a real comparison replaces its explanatory text.
	var style: StyleBoxFlat = T.action_button_style(false).duplicate()
	if selected:
		style.bg_color = T.ACTION
		style.border_color = T.ACTION
	button.add_theme_stylebox_override("normal", style)
	var hover: StyleBoxFlat = T.action_button_style(false, true).duplicate()
	if selected:
		hover.bg_color = T.ACTION.lightened(.06)
		hover.border_color = T.ACTION
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_stylebox_override("hover_pressed", hover)
	button.add_theme_font_override("font", T.FONT_UI)
	button.add_theme_font_size_override("font_size", 14)
	for key in ["font_color", "font_focus_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
		button.add_theme_color_override(key, T.ACTION_INK if selected else T.INK)

func _driver(key: String, ratio: float, known: bool, tip: String) -> void:
	var refs: Dictionary = _drivers[key]
	refs.value.text = "%s%%" % _num(ratio * 100) if known and ratio >= 0 else "—"
	refs.bar.visible = known and ratio >= 0
	refs.bar.value = ratio * 100 if known else 0
	refs.box.tooltip_text = tip

func _set_text(key: String, text: String) -> void:
	var label: Label = _refs[key]
	if label.text != text: label.text = text
	label.visible = not text.is_empty()

func _column(parent: Node, gap: int = 4) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", gap)
	parent.add_child(box)
	return box

func _text(parent: Node, text: String, size: int = 16, color: Color = T.INK) -> Label:
	var label := T.make_label(text, size, color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(label)
	return label

func _label(parent: Node, key: String, size: int = 16, color: Color = T.INK) -> Label:
	var label := _text(parent, "", size, color)
	_refs[key] = label
	return label

func _action(parent: Node, title: String, key: String, node_name: String, primary: bool = false) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = title
	button.add_theme_font_size_override("font_size", 14)
	button.set_meta("callback", key)
	T.apply_button_style(button, primary)
	parent.add_child(button)
	_buttons[node_name] = button
	if not key.is_empty(): button.pressed.connect(func() -> void: if _valid(data.get(key)): data[key].call())
	return button

func _selector(parent: Node, node_name: String) -> OptionButton:
	var select := OptionButton.new()
	select.name = node_name
	select.fit_to_longest_item = false
	select.custom_minimum_size = Vector2(200, 40)
	select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	select.add_theme_font_size_override("font_size", 14)
	select.get_popup().max_size.y = 320
	T.apply_button_style(select)
	parent.add_child(select)
	return select

func _link(parent: Node, title: String, key: String, node_name: String, font_size: int = 14) -> Button:
	var button := _action(parent, title, key, node_name)
	button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	button.custom_minimum_size.y = 32
	button.add_theme_font_size_override("font_size", font_size)
	var normal := T.flat(Color.TRANSPARENT)
	normal.content_margin_top = 5
	normal.content_margin_bottom = 5
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = T.HOVER_BG
	hover.border_color = T.TEAL
	hover.border_width_bottom = 1
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_stylebox_override("hover_pressed", hover)
	button.add_theme_stylebox_override("disabled", normal)
	for key_name: String in ["font_color", "font_focus_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
		button.add_theme_color_override(key_name, T.TEAL_TEXT)
	return button

func _sync_options(select: OptionButton, items: Array, active: String, label_key: String) -> void:
	var stamp := ""
	for item: Dictionary in items: stamp += String(item.get("id", "")) + ":" + String(item.get(label_key, "")) + "|"
	if String(select.get_meta("stamp", "")) != stamp:
		select.clear()
		for item: Dictionary in items:
			select.add_item(String(item.get(label_key, "")))
			select.set_item_metadata(select.item_count - 1, String(item.get("id", "")))
			select.set_item_tooltip(select.item_count - 1, String(item.get("tip", "")))
		select.set_meta("stamp", stamp)
	for index in select.item_count:
		if String(select.get_item_metadata(index)) == active: select.select(index); break

func _bar(parent: Node) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size.y = 5
	bar.add_theme_stylebox_override("background", T.flat(T.TRACK))
	bar.add_theme_stylebox_override("fill", T.flat(T.TEAL))
	parent.add_child(bar)
	return bar

func _rule() -> void:
	var rule := HSeparator.new()
	rule.add_theme_stylebox_override("separator", T.flat(T.BORDER_SOFT))
	_content.add_child(rule)

static func _valid(callback: Variant) -> bool:
	return callback is Callable and (callback as Callable).is_valid()

static func _warning_rank(warning: Dictionary) -> int:
	return {"starvation": 0, "food_shortage": 1, "water": 2, "safeguard": 3}.get(String(warning.get("kind", "")), 4)

static func _num(value: Variant, precision: int = 1) -> String:
	var number := float(value)
	if absf(number - roundf(number)) < .001: return str(roundi(number))
	return ("%.*f" % [precision, number]).trim_suffix("0").trim_suffix(".")

static func _signed(value: Variant) -> String:
	return ("+" if float(value) > 0 else "−" if float(value) < 0 else "") + _num(absf(float(value)))

class RiskDots extends Control:
	var risk := -1.0
	func _draw() -> void:
		var step := 9.0
		for index in 100:
			var at := Vector2(5 + (index % 10) * step, 6 + int(index / 10) * step)
			var color: Color = T.TRACK if risk < 0 else (T.AMBER if index < roundi(risk) else T.TEAL.darkened(.25))
			draw_circle(at, 3.0, color)

class FoodFlow extends Control:
	var reading: Dictionary = {}
	func _draw() -> void:
		var font := T.font("ui")
		if reading.is_empty():
			draw_string(font, Vector2(0, 35), "Daily food flow is not recorded yet.", HORIZONTAL_ALIGNMENT_LEFT, size.x, 16, T.MUTED)
			return
		var production := maxf(0, float(reading.get("production", 0)))
		var eaten := maxf(0, float(reading.get("eaten", 0)))
		var loss := maxf(0, float(reading.get("spoilage", 0)))
		var required := maxf(0, float(reading.get("required", 0)))
		var maximum := maxf(1, maxf(maxf(production, required), eaten + loss))
		var width := size.x - 2
		draw_string(font, Vector2(0, 16), "Brought in  %s" % HomeLivesNumber(production), HORIZONTAL_ALIGNMENT_LEFT, width, 16, T.BODY)
		draw_rect(Rect2(0, 23, width, 6), T.TRACK)
		draw_rect(Rect2(0, 23, width * production / maximum, 6), T.TEAL)
		draw_string(font, Vector2(0, 49), "Eaten  %s   ·   Lost  %s" % [HomeLivesNumber(eaten), HomeLivesNumber(loss)], HORIZONTAL_ALIGNMENT_LEFT, width, 16, T.BODY)
		draw_rect(Rect2(0, 56, width, 6), T.TRACK)
		draw_rect(Rect2(0, 56, width * eaten / maximum, 6), T.AMBER)
		draw_rect(Rect2(width * eaten / maximum, 56, width * loss / maximum, 6), T.RED)
		var need_x := width * required / maximum
		for y: float in [23.0, 56.0]: draw_line(Vector2(need_x, y - 3), Vector2(need_x, y + 9), T.INK, 1)
		var note := "Rations / day · marker: daily need %s" % HomeLivesNumber(required)
		draw_string(font, Vector2(0, 86), note, HORIZONTAL_ALIGNMENT_LEFT, size.x, 13, T.MUTED)
	static func HomeLivesNumber(value: float) -> String:
		return str(roundi(value)) if absf(value - roundf(value)) < .01 else "%.1f" % value

class StandingGauge extends Control:
	var value := -1.0
	var ink := Color.WHITE
	func _draw() -> void:
		var at := Vector2(size.x * .5, 52)
		var radius := 43.0
		draw_arc(at, radius, PI, TAU, 48, T.TRACK, 4, true)
		if value >= 0: draw_arc(at, radius, PI, PI + PI * clampf(value / 100, 0, 1), 48, ink, 4, true)
		var font := T.font("ui")
		var amount := "—" if value < 0 else FoodFlow.HomeLivesNumber(value)
		draw_string(font, Vector2(0, 47), amount, HORIZONTAL_ALIGNMENT_CENTER, size.x, 27, T.INK)
		draw_string(font, Vector2(0, 67), "/ 100" if value >= 0 else "unrecorded", HORIZONTAL_ALIGNMENT_CENTER, size.x, 12, T.MUTED)
