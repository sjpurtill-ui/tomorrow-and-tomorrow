extends Control
signal close_requested
const T = preload("res://scripts/hud/hud_tokens.gd")
const Art = preload("res://scripts/hud/scouting_window_art.gd")
const E = preload("res://scripts/society_exchange.gd")
var panel: PanelContainer
var slider: HSlider
var allocation: Label
var staffing: Label
var status: Label
var cost: Label
var reception: Label
var review: Label
var parties: VBoxContainer
var focus_buttons: Dictionary = {}
var presets: GridContainer
var timer := 0.0
var rendered := ""
var expanded: Dictionary = {}
var mission_rows: Dictionary = {}
var body: VBoxContainer
var columns: BoxContainer
var hero: Control
var title: Label
var scroll: ScrollContainer
var reception_card: PanelContainer
var reception_heading: Label
var reception_toggle: Button
var latest_card: PanelContainer
var latest_name: Label
var latest_detail: Label
var latest_image: TextureRect
var collection_button: Button
var party_heading: Label
var detail_toggle: Button
var detail_body: VBoxContainer
var focus_hint: Label
var close_button: Button
var done_button: Button
var origin_selector: OptionButton
var ancient := true

func label(parent: Node, text: String, font_size := 14, color: Color = Art.INK) -> Label:
	var node := T.make_label(text, font_size, color)
	node.add_theme_font_override("font", Art.BODY)
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.size_flags_horizontal = SIZE_EXPAND_FILL
	parent.add_child(node)
	return node

func button(parent: Node, text: String, action: Callable, primary := false) -> Button:
	var node := Button.new()
	node.text = text; node.custom_minimum_size.y = 36
	node.size_flags_horizontal = SIZE_EXPAND_FILL
	Art.style_button(node, primary)
	node.pressed.connect(action); parent.add_child(node)
	return node

func _stack(parent: Node, gap := 8) -> VBoxContainer:
	var node := VBoxContainer.new()
	node.size_flags_horizontal = SIZE_EXPAND_FILL
	node.add_theme_constant_override("separation", gap); parent.add_child(node)
	return node

func _card(parent: Node) -> PanelContainer:
	var node := PanelContainer.new()
	node.add_theme_stylebox_override("panel", Art.flat(Art.TILE, Art.BORDER, 1, 4, 12))
	node.size_flags_horizontal = SIZE_EXPAND_FILL; parent.add_child(node)
	return node

func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	# Advanced societies retain neutral expedition art until their distinct skin is ready.
	# The threshold uses established capability, never elapsed years or population alone.
	ancient = ProgressionSystem.domain_tier("production") < 5 and ProgressionSystem.domain_tier("knowledge") < 5
	var dim := ColorRect.new(); dim.name = "MapDismiss"
	dim.color = Color(.02,.018,.015,.64); dim.set_anchors_and_offsets_preset(PRESET_FULL_RECT); add_child(dim)
	dim.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			dim.accept_event(); close_requested.emit())
	panel = PanelContainer.new(); panel.name = "ScoutDispatchCard"
	panel.set_meta("viewport_fit_hosted", true); add_child(panel)
	var frame := Art.flat(Art.CLAY if ancient else Color("152329"), Art.BORDER, 1, 7, 1)
	frame.shadow_color = Color(0,0,0,.5); frame.shadow_size = 14
	panel.add_theme_stylebox_override("panel", frame)
	var texture := TextureRect.new(); texture.texture = Art.SURFACE
	texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; texture.stretch_mode = TextureRect.STRETCH_SCALE
	texture.mouse_filter = MOUSE_FILTER_IGNORE; texture.modulate.a = .10 if ancient else .04; panel.add_child(texture)
	var shell := _stack(panel, 0)
	hero = Control.new(); hero.name = "ExpeditionArtwork"; hero.custom_minimum_size.y = 155; hero.clip_contents = true; shell.add_child(hero)
	var paper_hero:=ancient and preload("res://scripts/hud/early_civ_art.gd").active()
	if paper_hero:
		var paper:=ColorRect.new();paper.color=Color("ece7dc");paper.mouse_filter=MOUSE_FILTER_IGNORE;hero.add_child(paper);paper.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var image := TextureRect.new(); image.texture = Art.HERO if ancient else preload("res://assets/textures/expeditions/chronicle-mountains.png")
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	if paper_hero:
		image.texture=load("res://assets/ui/early-paper/scouting-v1.png")
		image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.mouse_filter = MOUSE_FILTER_IGNORE; hero.add_child(image); image.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	var gradient := Gradient.new(); gradient.set_color(0, Color(.06,.05,.035,.68)); gradient.set_color(1, Color(.06,.05,.035,.02))
	var wash := GradientTexture2D.new(); wash.gradient = gradient
	var shade := TextureRect.new(); shade.texture = wash; shade.mouse_filter = MOUSE_FILTER_IGNORE
	hero.add_child(shade); shade.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	shade.visible=not paper_hero
	var heading := MarginContainer.new(); hero.add_child(heading); heading.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	for side: String in ["left","right","top","bottom"]: heading.add_theme_constant_override("margin_"+side, 20)
	var top := HBoxContainer.new(); heading.add_child(top)
	var words := _stack(top, 1); words.size_flags_vertical = SIZE_SHRINK_CENTER
	label(words, "BEYOND OUR BORDERS", 10, Color("73521e") if paper_hero else Art.GOLD)
	title = label(words, "Scouting", 35,Color("292d29") if paper_hero else Art.INK); title.add_theme_font_override("font", Art.TITLE)
	label(words, "Choose the commitment.\nYour people find the way.", 13, Color("3f483f") if paper_hero else Art.INK)
	close_button = button(top, "×", func(): close_requested.emit()); close_button.name = "CloseScouting"
	close_button.size_flags_horizontal = SIZE_SHRINK_END; close_button.size_flags_vertical = SIZE_SHRINK_BEGIN
	close_button.custom_minimum_size = Vector2(36,36); close_button.tooltip_text = "Close · Escape or click the map"
	var margins := MarginContainer.new(); margins.size_flags_vertical = SIZE_EXPAND_FILL; shell.add_child(margins)
	for side: String in ["left","right","top","bottom"]: margins.add_theme_constant_override("margin_"+side, 16)
	var content := _stack(margins, 10)
	scroll = ScrollContainer.new(); scroll.size_flags_vertical = SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; content.add_child(scroll)
	body = _stack(scroll, 8)
	body.minimum_size_changed.connect(func(): _layout.call_deferred())
	columns = BoxContainer.new(); columns.size_flags_horizontal = SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 18); body.add_child(columns)
	var commitment := _stack(columns, 6)
	label(commitment, "HOW MUCH SHOULD WE SCOUT?", 11, Art.GOLD)
	var numbers := HBoxContainer.new(); commitment.add_child(numbers)
	allocation = label(numbers, "", 38); allocation.size_flags_horizontal = SIZE_SHRINK_BEGIN; allocation.custom_minimum_size.x = 94
	staffing = label(numbers, "", 14, Art.SOFT); staffing.size_flags_vertical = SIZE_SHRINK_CENTER
	slider = HSlider.new(); slider.name = "PopulationAllocation"; slider.min_value = 0; slider.max_value = 10; slider.step = .5
	slider.custom_minimum_size.y = 26; slider.value = float(CivilizationSystem.scouting_staff.data.share)*100
	slider.tooltip_text = "Share of the departure settlement’s population reserved for scouting. Parties already away finish their journeys if you reduce it."
	Art.style_slider(slider); commitment.add_child(slider)
	slider.value_changed.connect(func(value: float):
		CivilizationSystem.scouting_staff.set_policy(value/100, String(CivilizationSystem.scouting_staff.data.focus)); refresh())
	presets = GridContainer.new(); presets.columns = 4; presets.add_theme_constant_override("h_separation",4); commitment.add_child(presets)
	for preset: Array in [["Off",0.0],["Little",2.0],["Regular",5.0],["A lot",10.0]]:
		var preset_button := button(presets, preset[0], func(): slider.value = preset[1])
		preset_button.add_theme_font_size_override("font_size",12); preset_button.custom_minimum_size.y=28
		preset_button.tooltip_text = "%.0f%% of this settlement’s population" % float(preset[1])
	var focuses := _stack(columns, 6)
	label(focuses, "WHAT SHOULD THEY SEEK?", 11, Art.GOLD)
	for key: String in ["exploration","recruitment","prospecting"]:
		var caption := "Explore & discover" if key == "exploration" else "Seek nomadic tribes" if key=="recruitment" else "Prospect rare resources"
		var choice := button(focuses, caption, func():
			CivilizationSystem.scouting_staff.set_policy(slider.value/100,key); refresh())
		choice.icon = Art.icon(key); choice.expand_icon = true; choice.add_theme_constant_override("icon_max_width",28)
		choice.alignment = HORIZONTAL_ALIGNMENT_LEFT; choice.toggle_mode = true; choice.custom_minimum_size.y = 40
		focus_buttons[key] = choice
		choice.tooltip_text = "New ground, resources, specimens and knowledge." if key=="exploration" else "Search for scarce independent wandering bands; foreign-city recruitment is a separate hostile order." if key=="recruitment" else "Survey actual terrain for recognized rare mineral and fuel occurrences. No resource reaches stores until a deposit is developed."
	label(focuses, "WHERE SHOULD THEY LEAVE FROM?", 11, Art.GOLD)
	origin_selector = OptionButton.new(); origin_selector.name="ScoutOrigin"; origin_selector.custom_minimum_size.y=36
	origin_selector.size_flags_horizontal=SIZE_EXPAND_FILL; focuses.add_child(origin_selector)
	Art.style_button(origin_selector)
	var origin_popup:=origin_selector.get_popup()
	origin_popup.add_theme_stylebox_override("panel",Art.flat(Art.TILE,Art.BORDER,1,4,8))
	origin_popup.add_theme_stylebox_override("hover",Art.flat(Color("483925"),Art.GOLD,1,3,4))
	for key:String in ["font_color","font_hover_color"]:origin_popup.add_theme_color_override(key,Art.INK)
	_refresh_origin_options()
	origin_selector.item_selected.connect(func(index:int):
		CivilizationSystem.scouting_staff.set_origin(String(origin_selector.get_item_metadata(index))); refresh())
	focus_hint = label(focuses, "", 12, Art.SOFT)
	var summary_card := _card(body); var summary_body := _stack(summary_card, 5)
	var summary_top := HBoxContainer.new(); summary_body.add_child(summary_top)
	party_heading = label(summary_top,"",16,Art.INK)
	detail_toggle = button(summary_top,"Details",func():
		detail_body.visible = not detail_body.visible; detail_toggle.text = "Less" if detail_body.visible else "Details"
		if detail_body.visible: _reveal.call_deferred(detail_body))
	detail_toggle.custom_minimum_size.y = 28; detail_toggle.size_flags_horizontal = SIZE_SHRINK_END
	status = label(summary_body,"",13,Art.SOFT)
	detail_body = _stack(summary_body,4); detail_body.visible = false
	review = label(detail_body,"",12,Art.SOFT); cost = label(detail_body,"",12,Art.SOFT)
	button(detail_body,"City intelligence",func(): close_requested.emit(); CivilizationSystem.city_intelligence.open())
	label(detail_body,"People away cannot work at home. Staff choose routes and organize repeat departures; maps and discoveries change only through their actual travels.",12,Art.SOFT)
	reception_card = _card(body); var reception_body := _stack(reception_card, 4)
	var reception_top := HBoxContainer.new(); reception_body.add_child(reception_top)
	reception_heading = label(reception_top,"",14,Art.GOLD)
	reception_toggle = button(reception_top,"Why?",func():
		reception.visible = not reception.visible
		if reception.visible: _reveal.call_deferred(reception))
	reception_toggle.size_flags_horizontal = SIZE_SHRINK_END; reception_toggle.custom_minimum_size.y = 28
	reception = label(reception_body,"",13,Art.SOFT); reception.visible = false
	parties = _stack(body,6)
	latest_card = _card(body); var latest_row := HBoxContainer.new(); latest_row.add_theme_constant_override("separation",12); latest_card.add_child(latest_row)
	latest_image = TextureRect.new(); latest_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	latest_image.custom_minimum_size = Vector2(76,65); latest_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	latest_image.mouse_filter = MOUSE_FILTER_IGNORE; latest_row.add_child(latest_image)
	var latest_text := _stack(latest_row,2); label(latest_text,"LATEST RETURNED FIND",10,Art.GOLD)
	latest_name = label(latest_text,"",17); latest_detail = label(latest_text,"",12,Art.SOFT)
	var footer := HBoxContainer.new(); footer.add_theme_constant_override("separation",8); content.add_child(footer)
	collection_button = button(footer,"Brought home",func(): preload("res://scripts/hud/exchange_collection_panel.gd").open())
	collection_button.tooltip_text = "Objects, knowledge and culture carried home by your people"
	done_button = button(footer,"Done",func(): close_requested.emit(),true); done_button.size_flags_horizontal=SIZE_SHRINK_END; done_button.custom_minimum_size.x=78
	resized.connect(_layout); panel.minimum_size_changed.connect(func(): _layout.call_deferred())
	_layout(); refresh(); _layout.call_deferred()

func _layout() -> void:
	if not is_instance_valid(panel): return
	var narrow := size.x < 620
	columns.vertical = narrow
	hero.custom_minimum_size.y = 126 if narrow else 155
	title.add_theme_font_size_override("font_size",28 if narrow else 35)
	var desired_height := hero.custom_minimum_size.y + 78 + body.get_combined_minimum_size().y
	panel.size = Vector2(minf(800,size.x-24), minf(maxf(430,desired_height),minf(790,size.y-24)))
	panel.position = (size-panel.size)*.5

func _refresh_origin_options(selected_id:String="") -> void:
	if not is_instance_valid(origin_selector):return
	var options:=CivilizationSystem.scout_origin_options()
	var signature_parts:Array[String]=[]
	for option:Dictionary in options:signature_parts.append("%s:%s" % [String(option.id),String(option.label)])
	var signature:="|".join(signature_parts)
	if String(origin_selector.get_meta("signature",""))!=signature:
		origin_selector.clear()
		for option:Dictionary in options:
			origin_selector.add_item(String(option.label).capitalize())
			origin_selector.set_item_metadata(origin_selector.item_count-1,String(option.id))
		origin_selector.set_meta("signature",signature)
	for index in origin_selector.item_count:
		if String(origin_selector.get_item_metadata(index))==selected_id:
			origin_selector.select(index)
			return
	if origin_selector.item_count>0:origin_selector.select(0)

func refresh() -> void:
	if not is_instance_valid(slider): return
	var view: Dictionary = CivilizationSystem.scouting_staff.snapshot()
	_refresh_origin_options(String(view.get("origin_city_id","")))
	# Changes made elsewhere update the controls without issuing another order.
	slider.set_value_no_signal(float(view.share)*100)
	allocation.text = ("%d%%" % roundi(slider.value)) if is_equal_approx(slider.value,roundf(slider.value)) else "%.1f%%" % slider.value
	staffing.text = "of this settlement\nUp to %d scouts · %d away" % [int(view.target),int(view.away)]
	for key: String in focus_buttons: focus_buttons[key].set_pressed_no_signal(key==view.focus)
	var hint:="New ground, samples & new knowledge."
	if view.focus=="recruitment":hint="Search for scarce, independent wandering bands. Foreign-city recruitment is a separate hostile order."
	elif view.focus=="prospecting":hint=String(view.get("prospecting",{}).get("message","Survey real terrain for rare resources."))
	focus_hint.text = hint+" New parties depart from %s." % String(view.get("origin_label","home"))
	party_heading.text = "%d %s in the field" % [int(view.parties),"party" if int(view.parties)==1 else "parties"] if int(view.parties)>0 else "No parties away"
	status.text = String(view.status)
	review.text = "Staff review in %d days" % int(view.review_in) if float(view.share)>0 and int(view.review_in)>0 else "Staff review on the next game day" if float(view.share)>0 else "No new departures. Existing parties will return."
	cost.text = "Parties carry %.1f food per day in total. Seven days of civilian food stay at home." % float(view.daily_food)
	reception_card.visible = view.focus=="recruitment"
	if reception_card.visible:
		var capacity := int(view.reception.capacity)
		var recruitment:Dictionary=view.get("recruitment",{})
		var nomads:Dictionary=recruitment.get("nomads",{})
		if capacity<2:
			reception_heading.text = "Nomad search paused · no reception room"
			reception.text = "INVITATIONS ON HOLD\n"+String(view.reception.message)
		elif not bool(nomads.get("available",true)):
			reception_heading.text = "The nomadic recruitment era is over"
			reception.text = String(nomads.get("message","Independent wandering bands are no longer available."))
		else:
			reception_heading.text = "Rare, finite, and moving"
			reception.text = "Room for %d newcomers · %d wandering bands previously encountered\n%s" % [capacity,int(nomads.get("known_bands",0)),String(nomads.get("message","Encounters are uncertain."))]
	var keys: Array = [int(GameState.elapsed_days)]
	for mission: Dictionary in CivilizationSystem.scout_missions:
		keys.append([mission.get("mission_id",0),mission.get("personnel",0),mission.get("return_day",0),mission.get("route_status","")])
	var signature := str(keys)
	if signature != rendered:
		rendered = signature
		_update_parties()
	_update_latest_find()

func _update_parties() -> void:
	# Retain controls and expansion while days advance, so refresh cannot swallow clicks.
	var active: Dictionary = {}
	for mission: Dictionary in CivilizationSystem.scout_missions:
		var id := int(mission.get("mission_id",0)); active[id] = true
		if not mission_rows.has(id): _make_party(id)
		var entry: Dictionary = mission_rows[id]
		var remaining := int(mission.return_day)-int(GameState.elapsed_days)
		var focus := "Seek nomadic tribes" if mission.get("target_kind","") in ["recruit_people","recruit_nomads"] else "Prospect rare resources" if mission.get("target_kind","")=="prospect_resources" else "Hostile foreign recruitment" if mission.get("target_kind","")=="recruit_people_visit" else "Observe city" if mission.get("target_kind","")=="observe_city" else "Explore & discover"
		entry.title.text = "Party %d · %s" % [id,focus]
		entry.subtitle.text = "%d people · %s" % [int(mission.personnel), "due in ~%dd" % remaining if remaining>=0 else "%dd overdue" % -remaining]
		var duration := maxi(1,int(mission.return_day)-int(mission.get("start_day",0)))
		entry.bar.value = clampf(100.0*(int(GameState.elapsed_days)-int(mission.get("start_day",0)))/duration,0,100)
		entry.bar.tooltip_text = "Time through the planned journey, not live knowledge of their position. Returns may be delayed."
		entry.detail.text = "From %s · %s\n%d food packed · %d days planned\n%s" % [String(mission.get("origin_label","Home settlement")),String(mission.get("target_label","Open exploration")).capitalize(),roundi(float(mission.get("provisions",0))),duration,"Awaiting their return; no new report has arrived." if remaining<0 else "Their account and finds arrive when they return."]
	for id: int in mission_rows.keys():
		if not active.has(id):
			var node: Control = mission_rows[id].card; parties.remove_child(node); node.queue_free(); mission_rows.erase(id); expanded.erase(id)

func _make_party(id: int) -> void:
	var card := _card(parties); var body := _stack(card,4)
	var line := HBoxContainer.new(); body.add_child(line)
	var words := _stack(line,1)
	var caption := label(words,"",15); var subtitle := label(words,"",12,Art.SOFT)
	var toggle := button(line,"+",func():
		expanded[id] = not bool(expanded.get(id,false))
		mission_rows[id].detail.visible=expanded[id]; mission_rows[id].toggle.text="−" if expanded[id] else "+"
		if expanded[id]: _reveal.call_deferred(mission_rows[id].detail))
	toggle.size_flags_horizontal=SIZE_SHRINK_END; toggle.custom_minimum_size=Vector2(32,32); toggle.tooltip_text="Party details"
	var bar := ProgressBar.new(); bar.show_percentage=false; bar.custom_minimum_size.y=3
	bar.add_theme_stylebox_override("background",Art.flat(Color("15120f"),Color.TRANSPARENT,0,2))
	bar.add_theme_stylebox_override("fill",T.flat(Art.GOLD,Color.TRANSPARENT,0,2)); body.add_child(bar)
	var detail := label(body,"",12,Art.SOFT); detail.visible=false
	mission_rows[id]={"card":card,"title":caption,"subtitle":subtitle,"toggle":toggle,"bar":bar,"detail":detail}

func _update_latest_find() -> void:
	# Deliberately reads returned records, never objects still carried by an absent party.
	var collections: Dictionary = E.data().collections
	collection_button.text = "Brought home · %d" % collections.size()
	latest_card.visible = not collections.is_empty()
	if collections.is_empty(): return
	var latest: Dictionary = {}
	for item: Dictionary in collections.values():
		if latest.is_empty() or int(item.returned_day)>int(latest.returned_day): latest=item
	latest_name.text = String(latest.name)
	latest_detail.text = "%s · %s" % [String(latest.source_name),"Studied" if float(latest.study)>=1 else "Being examined · %d%%" % roundi(float(latest.study)*100)]
	latest_image.texture = Art.STONE if Art.stone_find(latest) else Art.icon("recruitment" if latest.kind=="culture" else "find" if latest.kind in ["artifact","specimen"] else "knowledge")
	latest_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED if Art.stone_find(latest) else TextureRect.STRETCH_KEEP_ASPECT_CENTERED

func _reveal(control: Control) -> void:
	await get_tree().process_frame
	if is_instance_valid(control) and control.is_visible_in_tree():
		scroll.ensure_control_visible(control)

func _process(delta: float) -> void:
	timer += delta
	if timer >= 1: timer=0; refresh()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:
		get_viewport().set_input_as_handled(); close_requested.emit()
