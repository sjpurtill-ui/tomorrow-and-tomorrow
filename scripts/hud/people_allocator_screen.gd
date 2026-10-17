extends VBoxContainer
## A retained allocator over the existing guarded workforce API. This reader
## never assigns population or simulates production itself.
const T = preload("res://scripts/hud/hud_tokens.gd")
const Manual = preload("res://scripts/manual_work.gd")
const Impacts = preload("res://scripts/hud/people_work_impacts.gd")
const Portrait = preload("res://scripts/hud/people_town_portrait.gd")
const Words = preload("res://scripts/hud/era_words.gd")
const Icons = preload("res://scripts/resource_icons.gd")
const NAMES = {"Food":"Food grounds", "Survey":"Surveying", "Extraction":"Wood & stone", "Construction":"Building", "Crafting":"Making", "Logistics":"Water & carrying", "Knowledge":"Learning", "Administration":"Keeping & caring", "Defense":"The watch"}
const DOMAINS = ["nutrition", "ecology", "labor", "infrastructure", "production", "logistics", "knowledge", "health", "security"]

var data: Dictionary = {}
var active_role := "Food"
var forecast: Dictionary = {}
var rows: Dictionary = {}
var refs: Dictionary = {}
var _body: BoxContainer
var _margin: MarginContainer
var _content: VBoxContainer
var _art: TextureRect
var _art_path := ""
var _metrics: Array[Dictionary] = []
var _revision: Array = []
var _dirty := false
var _last_read_ms := -3000
var _busy := false
var _comparison := false
var _awaiting_counts: Dictionary = {}
var _awaiting_revision: Array = []
var _changes: Dictionary = {}
var _error := ""
var _last_change := ""
var _last_role := ""
var _requested: Dictionary = {}
var _forecast_day := -1
var _action_feedback := ""

func setup(block: Dictionary) -> void:
	name = "CivilizationPeopleScreen"
	theme = T.control_theme()
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_build()
	resized.connect(_layout)
	get_viewport().size_changed.connect(_layout)
	update_block(block)
	_refresh_current()
	_layout.call_deferred()

func _process(_delta: float) -> void:
	if _dirty and not _busy and not bool(data.get("world_running", false)) and Time.get_ticks_msec() - _last_read_ms >= 2500:
		_refresh_current()

func _build() -> void:
	_margin = MarginContainer.new()
	add_child(_margin)
	_content = _column(_margin, 16)
	var banner := PanelContainer.new()
	banner.name = "WorkforceBanner"
	banner.custom_minimum_size.y = 84
	banner.clip_contents = true
	banner.add_theme_stylebox_override("panel", T.flat(T.ROW_BG))
	_content.add_child(banner)
	_art = TextureRect.new()
	_art.name = "PopulationBackdrop"
	_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.add_child(_art)
	var veil := TextureRect.new()
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0, .55, 1])
	gradient.colors = PackedColorArray([T.PANEL_BG, Color(T.PANEL_BG, .96), Color(T.PANEL_BG, .22)])
	var fade := GradientTexture2D.new()
	fade.gradient = gradient
	veil.texture = fade
	banner.add_child(veil)
	var padding := MarginContainer.new()
	padding.name = "BannerPadding"
	for edge: String in ["left", "right", "top", "bottom"]: padding.add_theme_constant_override("margin_" + edge, 14)
	banner.add_child(padding)
	var heading := _column(padding, 3)
	_label(heading, "total", 27)
	_label(heading, "scope", 14, T.MUTED)
	var toolbar := HFlowContainer.new()
	toolbar.name = "AssignmentToolbar"
	toolbar.add_theme_constant_override("h_separation", 14)
	toolbar.add_theme_constant_override("v_separation", 6)
	_content.add_child(toolbar)
	var mode := _label(toolbar, "mode", 14, T.BODY)
	mode.autowrap_mode = TextServer.AUTOWRAP_OFF
	mode.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	refs.take_control = _button(toolbar, "I will assign", _take_control, "TakeControlWork")
	refs.delegate = _button(toolbar, "Let leaders assign", _delegate, "DelegateWork")
	refs.pause = _button(toolbar, "Pause world", _pause, "PauseToPlan")
	refs.refresh = _button(toolbar, "Update estimates", _refresh_estimates, "RefreshWorkEstimates")
	var explanation := _text(toolbar, "Use −1%, +1% or +5% to move workers", 13, T.MUTED)
	explanation.autowrap_mode = TextServer.AUTOWRAP_OFF
	explanation.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	explanation.tooltip_text = "Increasing one task takes its requested share from the largest other tasks. Actual workers can differ because of whole-worker rounding, military duties and local food protection."
	var feedback := _label(_content, "feedback", 13, T.BODY)
	feedback.custom_minimum_size.y = 38
	feedback.max_lines_visible = 2
	feedback.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_body = BoxContainer.new()
	_body.name = "AllocatorAndConsequences"
	_body.add_theme_constant_override("separation", 22)
	_content.add_child(_body)
	var allocator := _column(_body, 4)
	refs.allocator = allocator
	allocator.name = "AllWorkAreas"
	allocator.size_flags_stretch_ratio = 1.55
	var headings := HBoxContainer.new()
	headings.add_theme_constant_override("separation", 10)
	allocator.add_child(headings)
	var role_heading := _text(headings, "WORK AREA / ESTIMATED EFFECT", 12, T.MUTED)
	role_heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var workers_heading := _text(headings, "WORKERS", 12, T.MUTED)
	workers_heading.custom_minimum_size.x = 72
	workers_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var share_heading := _text(headings, "TARGET", 12, T.MUTED)
	share_heading.custom_minimum_size.x = 64
	share_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var change_heading := _text(headings, "ASSIGN", 12, T.MUTED)
	change_heading.custom_minimum_size.x = 138
	change_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for index in Manual.ROLES.size():
		var role: String = Manual.ROLES[index]
		var panel := PanelContainer.new()
		panel.name = "Allocation_" + role
		panel.custom_minimum_size.y = 50
		allocator.add_child(panel)
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 10)
		panel.add_child(line)
		var identity := _column(line, 1)
		identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var select := _button(identity, NAMES[role], focus_work.bind(role), "Select_" + role)
		select.icon = Icons.domain_texture(DOMAINS[index], T.TEAL)
		select.expand_icon = true
		select.add_theme_constant_override("icon_max_width", 20)
		select.alignment = HORIZONTAL_ALIGNMENT_LEFT
		select.custom_minimum_size.y = 24
		select.clip_text = true
		select.add_theme_font_size_override("font_size", 15)
		for state: String in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
			var plain := T.flat(T.HOVER_BG if state in ["hover", "pressed", "hover_pressed"] else Color.TRANSPARENT)
			plain.set_content_margin_all(0)
			select.add_theme_stylebox_override(state, plain)
		var effect := _text(identity, "Reading current conditions…", 12, T.MUTED)
		effect.autowrap_mode = TextServer.AUTOWRAP_OFF
		effect.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		var count := _text(line, "—", 21)
		count.custom_minimum_size.x = 72
		count.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		count.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		var share := _column(line, 4)
		share.custom_minimum_size.x = 64
		share.size_flags_horizontal = Control.SIZE_FILL
		share.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var percentage := _text(share, "—", 18)
		percentage.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var bar := ProgressBar.new()
		bar.show_percentage = false
		bar.custom_minimum_size.y = 4
		bar.add_theme_stylebox_override("background", T.flat(T.TRACK))
		bar.add_theme_stylebox_override("fill", T.flat(T.TEAL))
		share.add_child(bar)
		var buttons := HBoxContainer.new()
		buttons.add_theme_constant_override("separation", 3)
		buttons.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		line.add_child(buttons)
		var steps: Dictionary = {}
		for amount: int in [-1, 1, 5]:
			var button := _button(buttons, "−1%" if amount < 0 else "+1%" if amount == 1 else "+5%", _step.bind(role, amount), "Step_%s_%d" % [role, amount])
			button.custom_minimum_size = Vector2(44, 34)
			for state: String in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
				var style := button.get_theme_stylebox(state).duplicate() as StyleBoxFlat
				style.content_margin_left = 8; style.content_margin_right = 8
				style.content_margin_top = 5; style.content_margin_bottom = 5
				button.add_theme_stylebox_override(state, style)
			button.tooltip_text = "%s: %s percentage point%s. Applies immediately." % [NAMES[role], str(amount), "s" if absi(amount) != 1 else ""]
			button.accessibility_name = button.tooltip_text
			steps[amount] = button
		rows[role] = {"panel":panel, "select":select, "effect":effect, "count":count, "share":percentage, "bar":bar, "steps":steps}
	_text(allocator, "Targets total 100%. Worker counts include local food protection and military duties.", 13, T.MUTED)
	var sidebar := PanelContainer.new()
	sidebar.name = "AllocationConsequences"
	sidebar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sidebar.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	sidebar.add_theme_stylebox_override("panel", T.flat(T.ROW_BG, T.BORDER_SOFT, 1, 3, 14))
	_body.add_child(sidebar)
	var details := _column(sidebar, 7)
	_label(details, "detail_title", 22)
	var estimate_mode := _label(details, "estimate_mode", 12, T.GOLD_TEXT)
	estimate_mode.custom_minimum_size.y = 38
	estimate_mode.max_lines_visible = 2
	var transfer := _label(details, "transfer", 14)
	transfer.custom_minimum_size.y = 40
	transfer.max_lines_visible = 3
	transfer.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_text(details, "FOOD ACROSS OUR SETTLEMENTS", 12, T.GOLD_TEXT)
	var food := _label(details, "food", 16)
	food.custom_minimum_size.y = 58
	food.max_lines_visible = 3
	food.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_label(details, "stores", 13, T.MUTED)
	var risks := ScrollContainer.new()
	risks.name = "AllocationRisks"
	risks.custom_minimum_size.y = 52
	risks.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	details.add_child(risks)
	var risk_text := _label(risks, "risk", 14, T.AMBER_TEXT)
	risk_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var rule := HSeparator.new()
	details.add_child(rule)
	for index in 3:
		var slot := _column(details, 1)
		slot.custom_minimum_size.y = 42
		var title := _text(slot, "", 13, T.MUTED)
		title.autowrap_mode = TextServer.AUTOWRAP_OFF
		title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		var value := _text(slot, "", 19)
		value.autowrap_mode = TextServer.AUTOWRAP_OFF
		value.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		_metrics.append({"title":title, "value":value, "slot":slot})
	var meaning := _label(details, "meaning", 13, T.BODY)
	meaning.custom_minimum_size.y = 42
	meaning.max_lines_visible = 3
	meaning.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	var assumption := _text(details, "Estimates hold the recorded conditions and workforce; the seasonal food outlook can change.", 12, T.MUTED)
	assumption.tooltip_text = "Food is estimated, not an observed receipt or a promise. Reserves are not shared instantly between towns. Actual named town warnings take precedence over the aggregate food balance."

func update_block(block: Dictionary) -> bool:
	data = block
	var counts := _counts()
	var next_revision: Array = data.get("workforce_revision", [])
	if not _awaiting_counts.is_empty() and counts == _awaiting_counts and next_revision == _awaiting_revision:
		_awaiting_counts = {}
		_awaiting_revision = []
		_revision = next_revision.duplicate(true)
	elif next_revision != _revision and not _busy:
		_awaiting_counts = {}
		_awaiting_revision = []
		_dirty = true
		_comparison = false
		_changes = {}
		_last_change = ""
	_requested = _task_shares()
	_fill_header()
	_fill_rows()
	_fill_consequences()
	return true

func _api(method: String, arguments: Array = []) -> Variant:
	var callback: Variant = data.get("workforce", {}).get(method)
	return callback.callv(arguments) if callback is Callable and callback.is_valid() else null

func _counts() -> Dictionary:
	var counts: Dictionary = {}
	for role: String in Manual.ROLES: counts[role] = 0
	for task: Dictionary in data.get("labor", {}).get("tasks", []):
		if counts.has(String(task.get("id", ""))): counts[task.id] = maxi(0, int(task.get("count", 0)))
	return counts

func _task_shares() -> Dictionary:
	var shares: Dictionary = {}
	for task: Dictionary in data.get("labor", {}).get("tasks", []): shares[String(task.id)] = int(task.get("share", 0))
	return shares

func _refresh_estimates() -> void:
	_refresh_current(true)

func _refresh_current(for_assignment := false) -> void:
	if _busy: return
	_last_read_ms = Time.get_ticks_msec()
	var captured: Variant = _api("capture", [true]) if for_assignment else _api("capture")
	var next: Dictionary
	if captured is Dictionary and bool(captured.get("ok", false)):
		var result: Variant = _api("evaluate", [captured])
		next = result if result is Dictionary else {}
		_requested = Manual.percents(captured.get("shares", {}))
	else: next = {"ok":false, "reason":String(captured.get("reason", "Current work cannot be estimated.") if captured is Dictionary else "Current work cannot be estimated.")}
	_dirty = not bool(next.get("ok", false))
	# A temporary busy day must not blank a usable estimate on the screen.
	if not _dirty or not bool(forecast.get("ok", false)):
		forecast = next
		if not _dirty: _forecast_day = int(captured.get("day", data.get("day", -1)))
	_comparison = false
	_awaiting_counts = {}
	_awaiting_revision = []
	_changes = {}
	_last_change = ""
	_revision = data.get("workforce_revision", []).duplicate(true)
	_fill_rows()
	_fill_consequences()

func focus_work(role: String) -> void:
	if not NAMES.has(role): return
	active_role = role
	_fill_rows()
	_fill_consequences()

func _step(role: String, points: int) -> void:
	if _busy or not NAMES.has(role) or points == 0: return
	active_role = role
	_busy = true
	_error = ""
	var captured: Variant = _api("capture", [true])
	if not captured is Dictionary or not bool(captured.get("ok", false)):
		_error = String(captured.get("reason", "Wait for the current day to finish.") if captured is Dictionary else "Work is not available.")
		_finish_command(); return
	var proposed: Variant = _api("step", [captured, role, points])
	if not proposed is Dictionary or not bool(proposed.get("has_changes", false)):
		_error = "No further share can move in that direction."
		_finish_command(); return
	var estimate: Variant = _api("evaluate", [proposed])
	if not estimate is Dictionary or not bool(estimate.get("ok", false)) or bool(estimate.get("stale", false)):
		_error = String(estimate.get("reason", "Conditions changed. Try again from the current allocation.") if estimate is Dictionary else "This allocation could not be estimated.")
		_finish_command(); return
	var result: Variant = _api("commit", [proposed, true])
	if not result is Dictionary or not bool(result.get("ok", false)):
		_error = String(result.get("reason", "Conditions changed. Try again from the current allocation.") if result is Dictionary else "The assignment was not applied.")
		_finish_command(); return
	forecast = estimate
	_forecast_day = int(captured.get("day", data.get("day", -1)))
	var counts: Dictionary = result.get("counts", forecast.after.get("counts", {}))
	forecast.after.counts = counts.duplicate(true)
	_requested = Manual.percents(proposed.shares)
	data = data.duplicate(true)
	for task: Dictionary in data.get("labor", {}).get("tasks", []):
		task.count = int(counts.get(String(task.id), 0))
		task.share = int(_requested.get(String(task.id), 0))
	data.labor.manual = true
	_comparison = true
	_dirty = false
	_last_read_ms = Time.get_ticks_msec()
	_revision = data.get("workforce_revision", []).duplicate(true)
	_awaiting_counts = counts.duplicate(true)
	_awaiting_revision = result.get("revision", []).duplicate(true)
	_changes = {}
	var moves: Array[String] = []
	for task: String in Manual.ROLES:
		var delta := int(counts.get(task, 0)) - int(forecast.before.get("counts", {}).get(task, 0))
		if delta != 0:
			_changes[task] = delta
			moves.append("%s %s" % [NAMES[task], _signed(delta)])
	_last_change = " · ".join(moves) if not moves.is_empty() else "Target changed; rounding or food protection kept worker counts unchanged."
	_last_role = role
	_action_feedback = "Applied: " + _last_change
	_finish_command()

func _finish_command() -> void:
	_busy = false
	_fill_header()
	_fill_rows()
	_fill_consequences()

func _take_control() -> void:
	var callback: Variant = data.get("labor", {}).get("on_ruler")
	if not _has_callback(callback): return
	callback.call()
	data = data.duplicate(true)
	data.labor.manual = true
	_action_feedback = "You now assign workers. Use −1%, +1% or +5% to change a target."
	_error = ""
	_comparison = false
	_changes = {}
	_last_change = ""
	_dirty = true
	_last_read_ms = -3000
	_fill_header()
	_fill_rows()
	_fill_consequences()

func _delegate() -> void:
	var callback: Variant = data.get("labor", {}).get("on_leaders")
	if callback is Callable and callback.is_valid():
		callback.call()
		_comparison = false
		_changes = {}
		_awaiting_counts = {}
		_awaiting_revision = []
		_error = ""
		_last_change = ""
		data.labor.manual = false
		_action_feedback = "Leaders now assign workers."
		_dirty = true
		_last_read_ms = -3000
		_fill_header()
		_fill_consequences()

func _pause() -> void:
	var callback: Variant = data.get("pause_to_plan")
	if callback is Callable and callback.is_valid(): callback.call()

func _fill_header() -> void:
	var total := 0
	for count: int in _counts().values(): total += count
	refs.total.text = "%s people assigned" % Words.grouped(total)
	var population := int(data.get("settlement_view", {}).get("population", 0))
	refs.scope.text = "Across all settlements · %s people in our civilization" % Words.grouped(population)
	refs.total.tooltip_text = "Actual assigned workers, including the watch and serving soldiers. This differs from full population and the top-bar civilian At work count."
	var manual := bool(data.get("labor", {}).get("manual", false))
	refs.mode.text = "You assign workers" if manual else "Leaders assign workers"
	refs.take_control.disabled = manual or not _has_callback(data.get("labor", {}).get("on_ruler"))
	refs.delegate.disabled = not manual or not _has_callback(data.get("labor", {}).get("on_leaders"))
	refs.pause.disabled = not bool(data.get("world_running", false)) or not _has_callback(data.get("pause_to_plan"))
	var path := Portrait.texture_path(data.get("settlement_view", {}))
	if path != _art_path:
		_art_path = path
		if ResourceLoader.exists(path): _art.texture = load(path)
		elif FileAccess.file_exists(path):
			var image := Image.load_from_file(ProjectSettings.globalize_path(path))
			if image != null: _art.texture = ImageTexture.create_from_image(image)

func _fill_rows() -> void:
	var counts := _counts()
	var total := 0
	for value: int in counts.values(): total += value
	var valid := _has_callback(data.get("workforce", {}).get("commit")) and total > 0
	for role: String in rows:
		var row: Dictionary = rows[role]
		var share := int(_requested.get(role, 0))
		row.count.text = Words.grouped(int(counts[role]))
		row.count.tooltip_text = "%s actually assigned%s" % [row.count.text, " (%s in the last change)" % _signed(_changes[role]) if _changes.has(role) else ""]
		row.share.text = "%d%%" % share
		row.share.tooltip_text = "Requested share. Actual worker counts can differ after rounding, food protection and military duties."
		row.bar.value = share
		row.steps[-1].disabled = _busy or not valid or share <= 0
		row.steps[1].disabled = _busy or not valid or share >= 100
		row.steps[5].disabled = row.steps[1].disabled
		var readings := Impacts.readings(forecast, role, String(data.get("settlement_view", {}).get("settlement_id", "")), false)
		row.effect.text = ("%s · %s" % [readings[0].words, readings[0].label]) if not readings.is_empty() else "Estimate unavailable"
		if role == "Construction" and not readings.is_empty() and String(readings[0].get("unit", "")) == "days":
			row.effect.text += " in " + String(data.get("settlement_view", {}).get("name", "founding settlement"))
		row.effect.tooltip_text = row.effect.text + ("\n" + String(readings[0].get("note", "")) if not readings.is_empty() else "")
		if not bool(forecast.get("ok", false)): row.effect.text = "Estimate pending"
		if role == active_role and not _error.is_empty():
			row.effect.text = "Not applied: " + _error
			row.effect.tooltip_text = row.effect.text
		var selected := role == active_role
		var background := T.ACTIVE_BG if selected else T.ROW_BG
		var border := T.ACTION if selected else T.BORDER_SOFT
		var current := row.panel.get_theme_stylebox("panel") as StyleBoxFlat
		if current == null or not row.panel.has_theme_stylebox_override("panel") or current.bg_color != background or current.border_color != border:
			var style := T.flat(background, border, 1, 3, 4)
			style.border_width_left = 3 if selected else 1
			row.panel.add_theme_stylebox_override("panel", style)
		var ink := T.GOLD_TEXT if _changes.has(role) else T.INK
		if row.count.get_theme_color("font_color") != ink: row.count.add_theme_color_override("font_color", ink)

func _fill_consequences() -> void:
	if refs.is_empty(): return
	var manual := bool(data.get("labor", {}).get("manual", false))
	refs.feedback.text = NAMES[active_role] + " selected. Use −1%, +1% or +5% to move workers now." if manual else "Choose I will assign, or use −1%, +1% or +5% to take control and move workers."
	if not _error.is_empty(): refs.feedback.text = "Not applied: " + _error
	elif not _action_feedback.is_empty(): refs.feedback.text = _action_feedback
	elif not bool(forecast.get("ok", false)):
		refs.feedback.text = "Estimates pending: " + String(forecast.get("reason", "Waiting for a current reading."))
	refs.feedback.tooltip_text = refs.feedback.text
	_ink(refs.feedback, T.AMBER_TEXT if not _error.is_empty() or not bool(forecast.get("ok", false)) else T.BODY)
	refs.detail_title.text = NAMES[active_role]
	refs.estimate_mode.text = "LAST CHANGE · " + String(NAMES.get(_last_role, _last_role)).to_upper() if _comparison else "ESTIMATES · DAY %d" % _forecast_day if _forecast_day >= 0 else "ALLOCATION ESTIMATES"
	if _dirty and bool(forecast.get("ok", false)): refs.estimate_mode.text += " · Update estimates"
	refs.estimate_mode.tooltip_text = "Worker counts stay live. Estimates hold the conditions when calculated; update them here or pause the world for automatic updates."
	refs.transfer.text = _error if not _error.is_empty() else _last_change if _comparison else "Select any work area for its effects. Adjustments redistribute the same workforce."
	refs.transfer.tooltip_text = refs.transfer.text
	_ink(refs.transfer, T.AMBER_TEXT if not _error.is_empty() else T.BODY)
	var readings := Impacts.readings(forecast, active_role, String(data.get("settlement_view", {}).get("settlement_id", "")), _comparison)
	if active_role == "Knowledge" and _comparison and not readings.is_empty():
		var effort: Dictionary = readings[0]
		effort.label = "Research effort · " + _transition(effort.before, effort.after, true) + "/day"
		if is_equal_approx(float(effort.before), float(effort.after)):
			effort.words = "Supplied effort unchanged"
		elif float(effort.before) > 0:
			effort.words = "%s%% supplied effort" % _signed((float(effort.after) / float(effort.before) - 1.0) * 100.0)
		else:
			effort.words = "Research can now work"
	if active_role == "Food" and bool(forecast.get("ok", false)):
		for pair: Array in [["eaten", "Food eaten"], ["spoilage", "Food lost to spoilage"]]:
			var before: float = float(forecast.get("before", {}).get("food", {}).get(pair[0], 0))
			var after: float = float(forecast.get("after", {}).get("food", {}).get(pair[0], 0))
			readings.append({"label":pair[1], "words":_transition(before, after, _comparison) + " rations/day", "note":"Estimated daily food flow under the captured conditions."})
	for index in _metrics.size():
		var metric: Dictionary = _metrics[index]
		var reading: Dictionary = readings[index] if index < readings.size() else {}
		metric.title.text = String(reading.get("label", ""))
		if active_role == "Construction" and index == 0 and String(reading.get("unit", "")) == "days":
			metric.title.text += " · " + String(data.get("settlement_view", {}).get("name", "founding settlement"))
		metric.value.text = String(reading.get("words", ""))
		metric.slot.tooltip_text = String(reading.get("note", ""))
		metric.value.tooltip_text = metric.value.text + "\n" + metric.slot.tooltip_text
		if not reading.is_empty() and float(reading.get("need", 0)) > 0:
			metric.title.text += " · %s %s%s" % [String(reading.get("need_label", "need")), _number(reading.need), "%" if String(reading.unit) == "%" else ""]
	refs.meaning.text = "Care gradually approaches its target; it does not improve instantly. Keeping also reduces stored food spoilage." if active_role == "Administration" else Impacts.summary(active_role)
	refs.meaning.tooltip_text = refs.meaning.text
	if not bool(forecast.get("ok", false)):
		_metrics[0].title.text = "Consequences unavailable"
		_metrics[0].value.text = "—"
		refs.food.text = "Food estimate unavailable"
		refs.stores.text = ""
		refs.risk.text = String(forecast.get("reason", "Waiting for a current reading."))
		return
	var food: Dictionary = forecast.get("after", {}).get("food", {})
	var prior: Dictionary = forecast.get("before", {}).get("food", {})
	var net := float(food.get("net", 0))
	var old_net := float(prior.get("net", 0))
	refs.food.text = "Stores %s rations/day" % _transition(old_net, net, _comparison, true)
	if _comparison and not is_equal_approx(net, old_net):
		refs.food.text += "\n%s %s rations %s/day" % [_number(absf(net - old_net)), "fewer" if net < old_net else "more", "added to stores" if net >= 0 and old_net >= 0 else "available"]
		if net <= 0 and old_net <= 0:
			refs.food.text = "Stores %s rations/day\n%s %s rations drawn from stores/day" % [_transition(old_net, net, true, true), _number(absf(net - old_net)), "more" if net < old_net else "fewer"]
	else:
		refs.food.text += "\n" + ("Estimated shortfall draws on reserves." if net < 0 else "Estimated surplus builds reserves." if net > 0 else "Stored food is unchanged in this estimate.")
	refs.stores.text = "%s rations held · 90-day estimate %s" % [Words.grouped(roundi(float(food.get("stock", 0)))), Words.grouped(roundi(float(food.get("forecast90", {}).get("ending_rations", 0))))]
	refs.food.tooltip_text = "Production %s → %s; daily need %s → %s. Net includes spoilage." % [_number(prior.get("production", 0)), _number(food.get("production", 0)), _number(prior.get("required", 0)), _number(food.get("required", 0))]
	var warnings: Array = forecast.get("warnings", []).duplicate()
	warnings.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return _warning_rank(a) < _warning_rank(b))
	var warning_text: Array[String] = []
	for warning: Dictionary in warnings: warning_text.append(String(warning.get("text", "")))
	refs.risk.text = "\n".join(warning_text) if not warning_text.is_empty() else "No food shortage in the current 90-day outlook."
	_ink(refs.risk, T.RED_TEXT if not warnings.is_empty() and _warning_rank(warnings[0]) == 0 else T.AMBER_TEXT if not warning_text.is_empty() else T.MUTED)

func view_state() -> Dictionary: return {"focus_work":active_role}

func restore_view_state(saved: Dictionary) -> void:
	var wanted := String(saved.get("focus_work", active_role))
	if wanted != active_role: focus_work(wanted)

func handle_escape() -> bool: return false

func _layout() -> void:
	if _body == null: return
	var margin := maxi(0, floori((size.x - 1420) * .5))
	_margin.add_theme_constant_override("margin_left", margin)
	_margin.add_theme_constant_override("margin_right", margin)
	_body.vertical = size.x - margin * 2 < 850
	# Short windows retain the same type and controls; only decorative space shrinks.
	var compact := get_viewport_rect().size.y < 850
	_content.add_theme_constant_override("separation", 8 if compact else 16)
	refs.allocator.add_theme_constant_override("separation", 3 if compact else 4)
	var banner := find_child("WorkforceBanner", true, false) as Control
	banner.custom_minimum_size.y = 56 if compact else 84
	var padding := find_child("BannerPadding", true, false) as MarginContainer
	for edge: String in ["top", "bottom"]: padding.add_theme_constant_override("margin_" + edge, 5 if compact else 14)
	refs.total.add_theme_font_size_override("font_size", 22 if compact else 27)
	for role: String in rows:
		rows[role].panel.custom_minimum_size.y = 44 if compact else 50
		rows[role].select.custom_minimum_size.y = 20 if compact else 24
	for button: Button in [refs.take_control, refs.delegate, refs.pause, refs.refresh]:
		for state: String in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
			var current := button.get_theme_stylebox(state) as StyleBoxFlat
			var padding_y := 5 if compact else 8
			if current.content_margin_top == padding_y and current.content_margin_bottom == padding_y: continue
			var style := current.duplicate() as StyleBoxFlat
			style.content_margin_top = padding_y
			style.content_margin_bottom = padding_y
			button.add_theme_stylebox_override(state, style)

func _column(parent: Node, gap := 4) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", gap)
	parent.add_child(column)
	return column

func _text(parent: Node, words: String, font_size := 14, ink: Color = T.INK) -> Label:
	var label := T.make_label(words, font_size, ink)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(label)
	return label

func _label(parent: Node, key: String, font_size := 14, ink: Color = T.INK) -> Label:
	var label := _text(parent, "", font_size, ink)
	refs[key] = label
	return label

func _button(parent: Node, words: String, callback: Callable, node_name: String) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = words
	button.add_theme_font_size_override("font_size", 13)
	T.apply_button_style(button)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

static func _ink(label: Label, color: Color) -> void:
	if label.get_theme_color("font_color") != color: label.add_theme_color_override("font_color", color)

static func _has_callback(value: Variant) -> bool: return value is Callable and value.is_valid()
static func _number(value: Variant) -> String: return Impacts._number(float(value))
static func _signed(value: Variant) -> String: return ("+" if float(value) > 0 else "−" if float(value) < 0 else "") + _number(absf(float(value)))
static func _transition(before: Variant, after: Variant, compare: bool, signed := false) -> String:
	var old := _signed(before) if signed else _number(before)
	var next := _signed(after) if signed else _number(after)
	return old + " → " + next if compare and not is_equal_approx(float(before), float(after)) else next
static func _warning_rank(warning: Dictionary) -> int: return int({"starvation":0, "food_shortage":1, "water":2, "safeguard":3}.get(String(warning.get("kind", "")), 4))
