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
	var food := BoxContainer.new()
	food.name = "HomeFoodFlow"
	food.add_theme_constant_override("separation", 24)
	_content.add_child(food)
	_refs.food_box = food
	var flow := _column(food, 7)
	_text(flow, "Keeping people fed", 22)
	_label(flow, "food_period", 14, T.MUTED)
	_food_graph = FoodFlow.new()
	_food_graph.custom_minimum_size.y = 112
	flow.add_child(_food_graph)
	var reserves := _column(food, 6)
	reserves.size_flags_stretch_ratio = .65
	_text(reserves, "Current reserves", 14, T.MUTED)
	_label(reserves, "reserves", 28)
	_label(reserves, "balance", 18)
	_label(reserves, "food_note", 14, T.MUTED)
	_action(reserves, "Food & reserves", "on_food", "FoodDetail")
	_rule()
	_text(_content, "Across our civilization", 14, T.GOLD_TEXT)
	_society = BoxContainer.new()
	_society.name = "HomeSociety"
	_society.add_theme_constant_override("separation", 24)
	_content.add_child(_society)
	var learning := _column(_society, 8)
	_text(learning, "Knowledge into practice", 22)
	_label(learning, "question", 20)
	_label(learning, "research_progress", 14, T.MUTED)
	_research_bar = _bar(learning)
	_label(learning, "research_effect", 16)
	_label(learning, "research_usage", 14, T.MUTED)
	_label(learning, "research_counts", 14, T.MUTED)
	_action(learning, "Research", "on_research", "ResearchDetail")
	var culture := _column(_society, 8)
	_text(culture, "Values people live by", 22)
	_label(culture, "course", 20)
	_label(culture, "culture_effect", 16)
	_label(culture, "culture_meaning", 14, T.MUTED)
	_action(culture, "Culture & values", "on_culture", "CultureDetail")
	var regard := _column(_society, 8)
	_text(regard, "How others see us", 22)
	_label(regard, "awe", 24)
	_label(regard, "draw", 24)
	_label(regard, "regard_meaning", 14, T.MUTED)
	_rule()
	_foundations = BoxContainer.new()
	_foundations.name = "EverydayFoundations"
	_foundations.add_theme_constant_override("separation", 24)
	_content.add_child(_foundations)
	var work := _column(_foundations, 7)
	_text(work, "The support behind daily work", 22)
	_label(work, "foundations", 18)
	_label(work, "work_effects", 14, T.MUTED)
	var work_actions := HFlowContainer.new()
	work_actions.add_theme_constant_override("h_separation", 8)
	work.add_child(work_actions)
	_action(work_actions, "Buildings & works", "on_works", "WorkDetail")
	var toggle := _action(work_actions, "Water & sanitation", "", "WaterWorksToggle")
	toggle.pressed.connect(func() -> void: _works_open = not _works_open; _works.visible = _works_open)
	var watch := _column(_foundations, 7)
	_text(watch, "Who protects these lives?", 22)
	_label(watch, "watch", 20)
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
	start.pressed.connect(_start_work)
	_rule()
	var footer := _column(_content, 10)
	footer.name = "HomeLeadership"
	_label(footer, "leader", 20)
	_label(footer, "direction", 14, T.MUTED)
	var leadership := HFlowContainer.new()
	leadership.add_theme_constant_override("h_separation", 8)
	leadership.add_theme_constant_override("v_separation", 6)
	footer.add_child(leadership)
	_action(leadership, "Talk through our priorities", "on_leader", "TalkToLeader")
	_action(leadership, "Assign workers", "on_people", "PeopleDetail")
	_action(leadership, "Back to our leaders", "on_leaders", "BackToLeaders")
	_priority = _selector(leadership, "LeaderPriorities")
	_priority.item_selected.connect(_select_priority)
	_label(footer, "work_warning", 14, T.AMBER_TEXT)
	var fix := _action(footer, "", "on_food_fix", "FoodFix")
	fix.visible = false
	var ending := HFlowContainer.new()
	ending.add_theme_constant_override("h_separation", 8)
	ending.add_theme_constant_override("v_separation", 6)
	footer.add_child(ending)
	_action(ending, "Population & families", "on_population", "PopulationDetail")
	_action(ending, "Visit this place", "on_visit", "VisitVillage")
	_action(ending, "Rename", "on_rename", "RenamePlace")
	_founding = _selector(ending, "NewTownsChoice")
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
	_set_text("care", "Care %s%% now; target %s%%. Coverage changes gradually.\n%s assigned to keeping & caring; %s effective worker-equivalents." % [_num(float(care.get("current", 0)) * 100), _num(float(care.get("target", 0)) * 100), _num(care.get("assigned", 0)), _num(care.get("workers", 0))] if bool(care.get("known", false)) else "Care coverage is not measured yet.")
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
	_set_text("food_note", "%s rations held. Reserves ÷ daily need, not a starvation countdown." % _num(food.get("stock", 0)))
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
	_set_text("research_progress", "%s%% explored · %s%% recorded adoption / trial use" % [_num(progress * 100), _num(float(question.get("adoption", 0)) * 100)] if not question.is_empty() else "")
	_research_bar.visible = not question.is_empty()
	_research_bar.value = progress * 100
	var effects: Array[String] = []
	for row: Dictionary in question.get("effects", []):
		if bool(row.get("inert", false)): continue
		effects.append("%s %s" % [String(row.get("label", "")), String(row.get("amount", ""))])
	_set_text("research_effect", "At full use: " + " · ".join(effects.slice(0, 2)) if not effects.is_empty() else "")
	_refs.research_effect.tooltip_text = "\n".join(effects)
	_set_text("research_usage", String(question.get("usage", "")))
	_set_text("research_counts", "%d active inquiries · %d discoveries\n%d methods with recorded adoption" % [int(research.get("active_count", 0)), int(research.get("known_count", 0)), int(research.get("adopted_count", 0))])
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
	_set_text("awe", "Awe · %s/100" % _num(float(regard.get("awe", 0)) * 100) if measured else "Awe & draw not recorded")
	_set_text("draw", "Draw · %s/100" % _num(float(regard.get("draw", 0)) * 100) if measured else "")
	var date := int(regard.get("day", -1))
	_set_text("regard_meaning", "Awe reflects might, works and learning. Draw also reflects culture, plenty, order and diplomacy.\nAge-relative readings%s." % (" · recorded day %d" % date if date >= 0 else "") if measured else "Civilization-wide standing will appear after it is measured.")
	_refs.regard_meaning.tooltip_text = String(regard.get("note", ""))

func _fill_foundations(foundation: Dictionary) -> void:
	if not bool(foundation.get("known", false)):
		_set_text("foundations", "Local services are not measured yet.")
		_set_text("work_effects", "")
		_set_text("watch", "Local protection is not measured yet.")
		_set_text("watch_reason", "")
		return
	_set_text("foundations", "Service coverage %s/100 · roads %s/100\nBuilders' craft %s/%s" % [_num(float(foundation.get("service_coverage", 0)) * 100), _num(float(foundation.get("road_quality", 0)) * 100), _num(foundation.get("craft", 0)), _num(foundation.get("craft_max", 10))])
	var effects: Array[String] = []
	for pair in [["making_multiplier", "Making"], ["stored_rot_multiplier", "Stored-food decay"], ["haul_multiplier", "Hauling"]]:
		var change := (float(foundation.get(pair[0], 1)) - 1.0) * 100.0
		if absf(change) >= .01: effects.append("%s %s%%" % [pair[1], _signed(change)])
	_set_text("work_effects", (" · ".join(effects) + "\n" if not effects.is_empty() else "") + "Service and quality measures, not building counts.")
	var watch: Dictionary = foundation.get("watch", {})
	if watch.is_empty():
		_set_text("watch", "Local protection is not measured yet.")
		_set_text("watch_reason", "")
		return
	_set_text("watch", "%s serving · %s could muster" % [_num(watch.get("standing", 0)), _num(watch.get("mobilisable", 0))])
	var blockers: Array[String] = []
	for row: Dictionary in watch.get("blockers", []): blockers.append(String(row.get("text", "")))
	var words := String(watch.get("short", ""))
	var building: Dictionary = watch.get("building", {})
	if not building.is_empty(): words += " · %s %s%% built" % [String(building.get("short", "Works")), _num(float(building.get("progress", 0)) * 100)]
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
	_society.vertical = available < 700
	_foundations.vertical = narrow
	(_refs.food_box as BoxContainer).vertical = narrow
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
		var entries := [["production", "Brought in"], ["eaten", "Eaten"], ["spoilage", "Lost"]]
		var maximum := maxf(1, maxf(float(reading.get("production", 0)), float(reading.get("required", 0))))
		var width := size.x / 3.0
		for index in 3:
			var x: float = index * width
			var amount := float(reading.get(entries[index][0], 0))
			draw_string(font, Vector2(x, 22), HomeLivesNumber(amount), HORIZONTAL_ALIGNMENT_LEFT, width - 12, 25, T.INK)
			draw_string(font, Vector2(x, 48), entries[index][1], HORIZONTAL_ALIGNMENT_LEFT, width - 12, 14, T.BODY)
			draw_rect(Rect2(x, 61, width - 20, 5), T.TRACK)
			draw_rect(Rect2(x, 61, (width - 20) * clampf(amount / maximum, 0, 1), 5), T.TEAL if index == 0 else T.AMBER)
		var note := "Rations / day · daily need %s" % HomeLivesNumber(float(reading.get("required", 0)))
		draw_string(font, Vector2(0, 94), note, HORIZONTAL_ALIGNMENT_LEFT, size.x, 14, T.MUTED)
	static func HomeLivesNumber(value: float) -> String:
		return str(roundi(value)) if absf(value - roundf(value)) < .01 else "%.1f" % value
