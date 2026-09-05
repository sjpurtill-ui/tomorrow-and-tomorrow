extends Node

const PANEL_SIZE:=Vector2(1160,656)
const INK:=Color("#e8dfc6")
const MUTED:=Color("#9ca9b8")
const GOLD:=Color("#d5ad58")
const RED:=Color("#dc806f")
const BLUE:=Color("#75acd9")
const TAB_SITUATION:=0
const TAB_ARMIES:=1
const TAB_TRAINING:=2
const TAB_SUPPLY:=3
const TAB_ORDERS:=4

var layer:CanvasLayer
var open_button:Button
var modal:PanelContainer
var summary:Label
var condition:ProgressBar
var condition_bands:Dictionary={}
var readiness_meters:Dictionary={}
var readiness_bottleneck:Label
var strategic_overview:Label
var front_control_row:HBoxContainer
var front_choice:OptionButton
var front_stance_choice:OptionButton
var settlement_defense_label:Label
var settlement_defense_button:Button
var formations:Label
var commander_badge:Label
var commander_details:Label
var queues:Label
var inventory:Label
var feedback:Label
var command_tabs:TabContainer
var overview_armies:Label
var overview_front:Label
var primary_action_label:Label
var primary_action_button:Button
var primary_action_mode:=""
var recruit_count:SpinBox
var train_count:SpinBox
var unit_choice:OptionButton
var weapon_choice:OptionButton
var training_program_choice:OptionButton
var training_program_button:Button
var raise_recruits_button:Button
var begin_training_button:Button
var queue_production_button:Button
var produce_count:SpinBox
var equipment_choice:OptionButton
var aftermath_row:HBoxContainer
var aftermath_label:Label
var threat_row:HBoxContainer
var threat_label:Label
var engagement_row:HBoxContainer
var engagement_label:Label
var prisoner_policy:OptionButton
var spoils_policy:OptionButton
var general_policy:OptionButton
var refresh_accumulator:=0.0
var history_dialog:AcceptDialog
var history_text:RichTextLabel
var history_page_label:Label
var history_previous_button:Button
var history_next_button:Button
var history_records:Array=[]
var history_page:=0
const WAR_HISTORY_PAGE_SIZE:=3
var field_army_dialog:AcceptDialog
var field_army_choice:OptionButton
var field_army_destination:OptionButton
var field_army_detail:RichTextLabel
var field_army_create_count:SpinBox
var field_army_feedback:Label
var field_army_form_button:Button
var field_army_move_button:Button
var field_army_return_button:Button
var field_army_disband_button:Button
var field_army_feedback_override:=""
var field_army_feedback_override_error:=false


func _ready()->void:
	_build_interface()
	get_viewport().size_changed.connect(_fit_modal_to_viewport)
	MilitaryCampaign.army_changed.connect(func(_army:Dictionary): _refresh())
	set_process(true)


func _process(delta:float)->void:
	refresh_accumulator+=delta
	if modal.visible and refresh_accumulator>=0.5:
		refresh_accumulator=0.0
		_refresh()


func _campaign_modal_is_open()->bool:
	var scene:=get_tree().current_scene
	if scene==null:
		return false
	var viewport_size:=get_viewport().get_visible_rect().size
	var pending:Array[Node]=[scene]
	while not pending.is_empty():
		var node:Node=pending.pop_back()
		for child in node.get_children():
			pending.append(child)
		if node is Control:
			var control:=node as Control
			if control.is_visible_in_tree() and control.mouse_filter==Control.MOUSE_FILTER_STOP and control.size.x>=viewport_size.x*0.8 and control.size.y>=viewport_size.y*0.8:
				return true
	return false


func _build_interface()->void:
	layer=CanvasLayer.new()
	layer.layer=2
	add_child(layer)
	open_button=Button.new()
	open_button.name="NavMilitary"
	open_button.text="MILITARY"
	open_button.tooltip_text="Open military command (F6)"
	open_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	# Join the shared five-destination row in local_terrain instead of floating
	# between Actions and Menu as an unrelated global shortcut.
	open_button.position=Vector2(-224,8)
	open_button.size=Vector2(80,30)
	open_button.add_theme_font_size_override("font_size",9)
	open_button.pressed.connect(_toggle)
	# The Command Rail (F6 / ML) is the visible entry point now; the legacy
	# top-bar chip stays as a hidden compatibility target for older probes.
	open_button.visible=false
	layer.add_child(open_button)

	modal=PanelContainer.new()
	modal.name="MilitaryCommandModal"
	modal.size=PANEL_SIZE
	_fit_modal_to_viewport()
	modal.visible=false
	modal.add_theme_stylebox_override("panel",_panel_style(Color("#182029"),GOLD,2,12))
	layer.add_child(modal)

	var outer:=VBoxContainer.new()
	# The landing tab is a decision dashboard. Force composition, training,
	# production and campaign orders remain one click away without competing for
	# attention or turning the primary command surface into a scrolling ledger.
	outer.add_theme_constant_override("separation",5)
	modal.add_child(outer)
	var title_row:=HBoxContainer.new(); outer.add_child(title_row)
	var title:=Label.new(); title.text="MILITARY COMMAND"; title.add_theme_font_size_override("font_size",24); title.add_theme_color_override("font_color",GOLD); title_row.add_child(title)
	var spacer:=Control.new(); spacer.size_flags_horizontal=Control.SIZE_EXPAND_FILL; title_row.add_child(spacer)
	var close:=Button.new(); close.text="RETURN TO MAP"; close.custom_minimum_size=Vector2(142,34); close.tooltip_text="Close Military Command and return to the map (F6)"; close.pressed.connect(func(): modal.hide()); title_row.add_child(close)

	command_tabs=TabContainer.new(); command_tabs.name="MilitaryCommandSections"; command_tabs.size_flags_vertical=Control.SIZE_EXPAND_FILL; outer.add_child(command_tabs)
	var situation_tab:=VBoxContainer.new(); situation_tab.name="SITUATION"; situation_tab.add_theme_constant_override("separation",7); command_tabs.add_child(situation_tab)
	var armies_tab:=VBoxContainer.new(); armies_tab.name="ARMIES"; armies_tab.add_theme_constant_override("separation",7); command_tabs.add_child(armies_tab)
	var training_tab:=VBoxContainer.new(); training_tab.name="TRAINING"; training_tab.add_theme_constant_override("separation",7); command_tabs.add_child(training_tab)
	var supply_tab:=VBoxContainer.new(); supply_tab.name="SUPPLY"; supply_tab.add_theme_constant_override("separation",7); command_tabs.add_child(supply_tab)
	var orders_tab:=VBoxContainer.new(); orders_tab.name="FRONTS & ORDERS"; orders_tab.add_theme_constant_override("separation",7); command_tabs.add_child(orders_tab)
	command_tabs.set_tab_tooltip(TAB_SITUATION,"Current readiness, armies, active front or order, and the recommended next decision.")
	command_tabs.set_tab_tooltip(TAB_ARMIES,"Recruitment, home formations, commanders, field armies, movement, and settlement defense.")
	command_tabs.set_tab_tooltip(TAB_TRAINING,"Train recruits and prepare formations or command through aggregate exercises.")
	command_tabs.set_tab_tooltip(TAB_SUPPLY,"Inspect military stores, queue bounded production, and repair damaged equipment.")
	command_tabs.set_tab_tooltip(TAB_ORDERS,"Set front stances, respond to threats, issue battle orders, resolve aftermath, and inspect war history.")

	var situation_card:=PanelContainer.new(); situation_card.size_flags_vertical=Control.SIZE_EXPAND_FILL; situation_card.add_theme_stylebox_override("panel",_panel_style(Color("#202a35"),BLUE,1,8)); situation_tab.add_child(situation_card)
	var situation_box:=VBoxContainer.new(); situation_box.add_theme_constant_override("separation",6); situation_card.add_child(situation_box)
	var situation_heading:=Label.new(); situation_heading.text="CURRENT MILITARY SITUATION"; situation_heading.add_theme_font_size_override("font_size",17); situation_heading.add_theme_color_override("font_color",BLUE); situation_box.add_child(situation_heading)
	summary=Label.new(); summary.add_theme_font_size_override("font_size",17); summary.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS; situation_box.add_child(summary)
	condition=ProgressBar.new(); condition.custom_minimum_size.y=22; condition.show_percentage=true; situation_box.add_child(condition)
	var condition_strip:=HBoxContainer.new(); condition_strip.custom_minimum_size.y=12; condition_strip.add_theme_constant_override("separation",2); situation_box.add_child(condition_strip)
	var condition_caption:=Label.new(); condition_caption.text="PERSONNEL"; condition_caption.custom_minimum_size.x=68; condition_caption.add_theme_font_size_override("font_size",9); condition_caption.add_theme_color_override("font_color",MUTED); condition_strip.add_child(condition_caption)
	for entry in [["ready",Color("#5f9f73")],["capable",Color("#a4a85c")],["strained",Color("#c68b4f")],["unfit",Color("#a8514d")]]:
		var band:=ColorRect.new(); band.color=entry[1]; band.custom_minimum_size.x=3; band.size_flags_horizontal=Control.SIZE_EXPAND_FILL; condition_strip.add_child(band); condition_bands[String(entry[0])]=band
	var readiness_strip:=HBoxContainer.new(); readiness_strip.add_theme_constant_override("separation",6); situation_box.add_child(readiness_strip)
	for entry in [["manpower","PERS",RED],["equipment","EQ",GOLD],["ammunition","AMMO",Color("#b98ccb")],["condition","COND",Color("#83b77b")],["organization","ORG",BLUE],["supply","SUP",Color("#74b9ae")]]:
		_add_readiness_meter(readiness_strip,String(entry[0]),String(entry[1]),entry[2])
	readiness_bottleneck=Label.new(); readiness_bottleneck.custom_minimum_size.x=126; readiness_bottleneck.vertical_alignment=VERTICAL_ALIGNMENT_CENTER; readiness_bottleneck.add_theme_color_override("font_color",MUTED); readiness_strip.add_child(readiness_bottleneck)
	strategic_overview=Label.new(); strategic_overview.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; strategic_overview.max_lines_visible=2; strategic_overview.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS; strategic_overview.add_theme_font_size_override("font_size",10); strategic_overview.add_theme_color_override("font_color",BLUE); situation_box.add_child(strategic_overview)
	var overview_row:=HBoxContainer.new(); overview_row.add_theme_constant_override("separation",8); situation_box.add_child(overview_row)
	overview_armies=_overview_status_card(overview_row,"ARMIES",RED)
	overview_front=_overview_status_card(overview_row,"FRONT / ORDER",GOLD)
	var primary_card:=PanelContainer.new(); primary_card.add_theme_stylebox_override("panel",_panel_style(Color("#151d25"),GOLD,1,7)); situation_tab.add_child(primary_card)
	var primary_row:=HBoxContainer.new(); primary_row.add_theme_constant_override("separation",10); primary_card.add_child(primary_row)
	primary_action_label=Label.new(); primary_action_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL; primary_action_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; primary_action_label.max_lines_visible=3; primary_action_label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS; primary_action_label.add_theme_color_override("font_color",INK); primary_row.add_child(primary_action_label)
	primary_action_button=Button.new(); primary_action_button.custom_minimum_size=Vector2(248,48); primary_action_button.add_theme_font_size_override("font_size",13); primary_action_button.pressed.connect(_activate_primary_action); primary_row.add_child(primary_action_button)

	var armies_top_row:=HBoxContainer.new(); armies_top_row.add_theme_constant_override("separation",8); armies_tab.add_child(armies_top_row)
	var armies_button:=Button.new(); armies_button.text="FORM OR MOVE FIELD ARMIES"; armies_button.tooltip_text="Assemble trained formations into bounded maneuver armies, inspect them, and issue movement orders"; armies_button.pressed.connect(_open_field_armies); armies_top_row.add_child(armies_button)
	settlement_defense_label=Label.new(); settlement_defense_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL; settlement_defense_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT; settlement_defense_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; settlement_defense_label.max_lines_visible=2; settlement_defense_label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS; settlement_defense_label.add_theme_font_size_override("font_size",10); settlement_defense_label.add_theme_color_override("font_color",BLUE); armies_top_row.add_child(settlement_defense_label)
	settlement_defense_button=Button.new(); settlement_defense_button.custom_minimum_size=Vector2(190,36); settlement_defense_button.pressed.connect(_start_settlement_defense_upgrade); armies_top_row.add_child(settlement_defense_button)
	var army_columns:=HBoxContainer.new(); army_columns.size_flags_vertical=Control.SIZE_EXPAND_FILL; armies_tab.add_child(army_columns)
	var army_box:=_section(army_columns,"HOME FORCE & FORMATIONS",RED)
	var commander_row:=HBoxContainer.new(); commander_row.add_theme_constant_override("separation",8); army_box.add_child(commander_row)
	commander_badge=Label.new(); commander_badge.custom_minimum_size=Vector2(48,46); commander_badge.text="CMD"; commander_badge.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; commander_badge.vertical_alignment=VERTICAL_ALIGNMENT_CENTER; commander_badge.add_theme_font_size_override("font_size",14); commander_badge.add_theme_color_override("font_color",GOLD); commander_badge.add_theme_stylebox_override("normal",_panel_style(Color("#202a35"),GOLD,1,5)); commander_row.add_child(commander_badge)
	commander_details=Label.new(); commander_details.size_flags_horizontal=Control.SIZE_EXPAND_FILL; commander_details.vertical_alignment=VERTICAL_ALIGNMENT_CENTER; commander_details.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS; commander_row.add_child(commander_details)
	formations=_body_label(army_box); formations.add_theme_font_size_override("font_size",14)
	var recruit_row:=HBoxContainer.new(); army_box.add_child(recruit_row)
	recruit_count=_counter(recruit_row,1,1_000_000_000,10)
	recruit_count.tooltip_text="Numeric people to withhold from civilian functions and place in the untrained recruit reserve."
	raise_recruits_button=_action_button(recruit_row,"RAISE RECRUITS",_raise_recruits)
	var stand_row:=HBoxContainer.new(); army_box.add_child(stand_row)
	_action_button(stand_row,"REINFORCE WEAKEST FORMATION",_reinforce_weakest)
	_action_button(stand_row,"DEMOBILIZE SELECTED AMOUNT",func(): _report(MilitaryCampaign.demobilize(int(recruit_count.value))))

	var training_columns:=HBoxContainer.new(); training_columns.size_flags_vertical=Control.SIZE_EXPAND_FILL; training_tab.add_child(training_columns)
	var training_box:=_section(training_columns,"TRAINING & EXERCISES",GOLD)
	queues=_body_label(training_box)
	var recruit_choices:=HBoxContainer.new(); recruit_choices.add_theme_constant_override("separation",5); training_box.add_child(recruit_choices)
	unit_choice=OptionButton.new(); unit_choice.fit_to_longest_item=false; unit_choice.custom_minimum_size.x=220; unit_choice.size_flags_horizontal=Control.SIZE_EXPAND_FILL; recruit_choices.add_child(unit_choice); unit_choice.item_selected.connect(func(_index:int): _populate_training_weapons())
	weapon_choice=OptionButton.new(); weapon_choice.fit_to_longest_item=false; weapon_choice.custom_minimum_size.x=220; weapon_choice.size_flags_horizontal=Control.SIZE_EXPAND_FILL; recruit_choices.add_child(weapon_choice)
	var train_row:=HBoxContainer.new(); training_box.add_child(train_row)
	train_count=_counter(train_row,1,1_000_000_000,10)
	train_count.tooltip_text="Recruits assigned to this training order. Training consumes time; issued equipment must physically exist."
	begin_training_button=_action_button(train_row,"TRAIN SELECTED COHORT",_start_training)
	var program_row:=HBoxContainer.new(); program_row.add_theme_constant_override("separation",5); training_box.add_child(program_row)
	training_program_choice=OptionButton.new(); training_program_choice.fit_to_longest_item=false; training_program_choice.custom_minimum_size.x=280; training_program_choice.size_flags_horizontal=Control.SIZE_EXPAND_FILL; program_row.add_child(training_program_choice); training_program_choice.item_selected.connect(func(_index:int): _update_training_program_choice())
	training_program_button=Button.new(); training_program_button.custom_minimum_size.x=180; training_program_button.pressed.connect(_training_program_action); program_row.add_child(training_program_button)

	var supply_columns:=HBoxContainer.new(); supply_columns.size_flags_vertical=Control.SIZE_EXPAND_FILL; supply_tab.add_child(supply_columns)
	var supply_box:=_section(supply_columns,"ARSENAL, SUPPLY & PRODUCTION",BLUE)
	inventory=_body_label(supply_box)
	equipment_choice=OptionButton.new(); supply_box.add_child(equipment_choice)
	var production_row:=HBoxContainer.new(); supply_box.add_child(production_row)
	produce_count=_counter(production_row,1,1_000_000_000,10)
	produce_count.tooltip_text="Aggregate quantity placed on one bounded military production line. Materials are reserved when the order begins."
	queue_production_button=_action_button(production_row,"BUILD SELECTED SUPPLY",_queue_production)
	_action_button(production_row,"REPAIR DAMAGED EQUIPMENT",_queue_repair)

	front_control_row=HBoxContainer.new(); front_control_row.add_theme_constant_override("separation",6); front_control_row.visible=false; orders_tab.add_child(front_control_row)
	var front_caption:=Label.new(); front_caption.text="ACTIVE FRONT"; front_caption.add_theme_font_size_override("font_size",10); front_caption.add_theme_color_override("font_color",GOLD); front_control_row.add_child(front_caption)
	front_choice=OptionButton.new(); front_choice.fit_to_longest_item=false; front_choice.custom_minimum_size.x=330; front_choice.size_flags_horizontal=Control.SIZE_EXPAND_FILL; front_control_row.add_child(front_choice)
	front_stance_choice=OptionButton.new(); front_stance_choice.custom_minimum_size.x=150; front_control_row.add_child(front_stance_choice)
	for stance in ["cautious","balanced","offensive"]:
		front_stance_choice.add_item(String(stance).to_upper()); front_stance_choice.set_item_metadata(front_stance_choice.item_count-1,stance)
	var apply_front_stance:=Button.new(); apply_front_stance.text="APPLY FRONT STANCE"; apply_front_stance.tooltip_text="Cautious preserves personnel, balanced holds normal risk, and offensive accepts greater losses for greater pressure."; apply_front_stance.pressed.connect(_apply_front_stance); front_control_row.add_child(apply_front_stance)
	var history_row:=HBoxContainer.new(); orders_tab.add_child(history_row)
	var history_explanation:=Label.new(); history_explanation.text="Named wars, battles, territorial changes, and military and civilian losses are retained in the war record."; history_explanation.size_flags_horizontal=Control.SIZE_EXPAND_FILL; history_explanation.add_theme_color_override("font_color",MUTED); history_row.add_child(history_explanation)
	var history_button:=Button.new(); history_button.text="OPEN WAR RECORD"; history_button.tooltip_text="Review named wars, battles, territorial changes, and real military and civilian losses"; history_button.pressed.connect(_open_war_history); history_row.add_child(history_button)
	threat_row=HBoxContainer.new(); threat_row.add_theme_constant_override("separation",8); orders_tab.add_child(threat_row)
	threat_label=Label.new(); threat_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL; threat_label.add_theme_color_override("font_color",RED); threat_row.add_child(threat_label)
	_action_button(threat_row,"DEFEND SETTLEMENT",func(): _report(MilitaryCampaign.respond_to_threat("defend")))
	_action_button(threat_row,"PAY TRIBUTE",func(): _report(MilitaryCampaign.respond_to_threat("tribute")))
	_action_button(threat_row,"WITHDRAW",func(): _report(MilitaryCampaign.respond_to_threat("withdraw")))
	engagement_row=HBoxContainer.new(); engagement_row.add_theme_constant_override("separation",8); orders_tab.add_child(engagement_row)
	engagement_label=Label.new(); engagement_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL; engagement_label.add_theme_color_override("font_color",GOLD); engagement_label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS; engagement_row.add_child(engagement_label)
	_action_button(engagement_row,"HOLD THIS ROUND",func(): _report(MilitaryCampaign.advance_engagement("hold")))
	_action_button(engagement_row,"PRESS THE ATTACK",func(): _report(MilitaryCampaign.advance_engagement("push")))
	_action_button(engagement_row,"ORDER RETREAT",func(): _report(MilitaryCampaign.advance_engagement("retreat")))

	aftermath_row=HBoxContainer.new(); aftermath_row.add_theme_constant_override("separation",8); orders_tab.add_child(aftermath_row)
	aftermath_label=Label.new(); aftermath_label.text="BATTLE DECISION"; aftermath_label.add_theme_color_override("font_color",GOLD); aftermath_row.add_child(aftermath_label)
	prisoner_policy=_policy_choice(aftermath_row,["hold","release","exchange","parole","ransom","execute","enslave"],"Prisoners")
	spoils_policy=_policy_choice(aftermath_row,["army stores","reward troops","state treasury","return property","unrestricted plunder"],"Spoils")
	general_policy=_policy_choice(aftermath_row,["hold","release","ransom","execute"],"Enemy command staff")
	_action_button(aftermath_row,"APPLY AFTERMATH POLICY",_resolve_aftermath_or_captives)

	feedback=Label.new(); feedback.text="Time continues while Military Command is open. F6 returns to the map."; feedback.custom_minimum_size.x=800; feedback.add_theme_color_override("font_color",MUTED); feedback.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS; outer.add_child(feedback)
	_build_history_dialog()
	_build_field_army_dialog()
	_populate_choices()
	_refresh()


func _fit_modal_to_viewport()->void:
	if modal==null:
		return
	var viewport_size:=get_viewport().get_visible_rect().size
	modal.size=PANEL_SIZE
	modal.position=(viewport_size-PANEL_SIZE)*0.5
	if history_dialog!=null: history_dialog.position=Vector2i((viewport_size-Vector2(880,600))*0.5); history_dialog.size=Vector2i(880,600)
	if field_army_dialog!=null: field_army_dialog.position=Vector2i((viewport_size-Vector2(820,560))*0.5); field_army_dialog.size=Vector2i(820,560)


func _build_history_dialog()->void:
	history_dialog=AcceptDialog.new()
	history_dialog.title="WAR HISTORY"
	history_dialog.ok_button_text="RETURN TO MILITARY COMMAND"
	history_dialog.exclusive=true
	var history_root:=VBoxContainer.new(); history_root.custom_minimum_size=Vector2(840,520); history_root.add_theme_constant_override("separation",6); history_dialog.add_child(history_root)
	var navigation:=HBoxContainer.new(); navigation.add_theme_constant_override("separation",6); history_root.add_child(navigation)
	history_page_label=Label.new(); history_page_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL; history_page_label.add_theme_color_override("font_color",MUTED); navigation.add_child(history_page_label)
	history_previous_button=Button.new(); history_previous_button.text="PREVIOUS WARS"; history_previous_button.pressed.connect(_change_war_history_page.bind(-1)); navigation.add_child(history_previous_button)
	history_next_button=Button.new(); history_next_button.text="NEXT WARS"; history_next_button.pressed.connect(_change_war_history_page.bind(1)); navigation.add_child(history_next_button)
	history_text=RichTextLabel.new()
	history_text.custom_minimum_size=Vector2(840,480)
	history_text.bbcode_enabled=true
	history_text.fit_content=false
	history_text.scroll_active=false
	history_root.add_child(history_text)
	layer.add_child(history_dialog)


func _build_field_army_dialog()->void:
	field_army_dialog=AcceptDialog.new()
	field_army_dialog.title="FIELD ARMIES — ASSEMBLY AND MOVEMENT"
	field_army_dialog.ok_button_text="RETURN TO MILITARY COMMAND"
	field_army_dialog.exclusive=true
	var outer:=VBoxContainer.new(); outer.custom_minimum_size=Vector2(780,480); outer.add_theme_constant_override("separation",8); field_army_dialog.add_child(outer)
	var explanation:=Label.new(); explanation.text="A field army is one bounded aggregate command record. Personnel, equipment, ammunition, training, and losses remain real numeric totals; no individual soldier objects are created."; explanation.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; explanation.add_theme_color_override("font_color",MUTED); outer.add_child(explanation)
	var create_row:=HBoxContainer.new(); create_row.add_theme_constant_override("separation",6); outer.add_child(create_row)
	var create_caption:=Label.new(); create_caption.text="TAKE TRAINED PERSONNEL"; create_caption.add_theme_color_override("font_color",GOLD); create_row.add_child(create_caption)
	field_army_create_count=_counter(create_row,1,1_000_000_000,100)
	field_army_create_count.tooltip_text="Trained home personnel transferred into one maneuver-army command. They leave the home reserve but remain part of the population."
	field_army_form_button=_action_button(create_row,"FORM MANEUVER ARMY",_create_field_army)
	var select_row:=HBoxContainer.new(); select_row.add_theme_constant_override("separation",6); outer.add_child(select_row)
	field_army_choice=OptionButton.new(); field_army_choice.fit_to_longest_item=false; field_army_choice.custom_minimum_size.x=350; field_army_choice.size_flags_horizontal=Control.SIZE_EXPAND_FILL; field_army_choice.item_selected.connect(func(_index:int): field_army_feedback_override=""; _refresh_field_army_detail()); select_row.add_child(field_army_choice)
	field_army_destination=OptionButton.new(); field_army_destination.fit_to_longest_item=false; field_army_destination.custom_minimum_size.x=350; field_army_destination.size_flags_horizontal=Control.SIZE_EXPAND_FILL; select_row.add_child(field_army_destination)
	field_army_destination.item_selected.connect(func(_index:int): field_army_feedback_override=""; _refresh_field_army_dialog())
	field_army_detail=RichTextLabel.new(); field_army_detail.bbcode_enabled=true; field_army_detail.fit_content=false; field_army_detail.scroll_active=false; field_army_detail.size_flags_vertical=Control.SIZE_EXPAND_FILL; field_army_detail.custom_minimum_size.y=300; outer.add_child(field_army_detail)
	var order_row:=HBoxContainer.new(); order_row.add_theme_constant_override("separation",6); outer.add_child(order_row)
	field_army_move_button=_action_button(order_row,"MOVE ARMY",_move_selected_field_army)
	field_army_return_button=_action_button(order_row,"RETURN ARMY HOME",_return_selected_field_army)
	field_army_disband_button=_action_button(order_row,"RELEASE ARMY AT HOME",_disband_selected_field_army)
	field_army_feedback=Label.new(); field_army_feedback.text="Form an army, choose a known destination, then MOVE."; field_army_feedback.add_theme_color_override("font_color",MUTED); field_army_feedback.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS; outer.add_child(field_army_feedback)
	layer.add_child(field_army_dialog)


func _section(parent:HBoxContainer,title_text:String,color:Color)->VBoxContainer:
	var panel:=PanelContainer.new(); panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL; panel.add_theme_stylebox_override("panel",_panel_style(Color("#202a35"),color,1,8)); parent.add_child(panel)
	var box:=VBoxContainer.new(); box.add_theme_constant_override("separation",5); panel.add_child(box)
	var heading:=Label.new(); heading.text=title_text; heading.add_theme_font_size_override("font_size",18); heading.add_theme_color_override("font_color",color); box.add_child(heading)
	return box


func _overview_status_card(parent:HBoxContainer,title_text:String,color:Color)->Label:
	var panel:=PanelContainer.new(); panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL; panel.add_theme_stylebox_override("panel",_panel_style(Color("#151d25"),color,1,6)); parent.add_child(panel)
	var box:=VBoxContainer.new(); box.add_theme_constant_override("separation",3); panel.add_child(box)
	var heading:=Label.new(); heading.text=title_text; heading.add_theme_font_size_override("font_size",11); heading.add_theme_color_override("font_color",color); box.add_child(heading)
	var status:=Label.new(); status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; status.max_lines_visible=3; status.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS; status.add_theme_font_size_override("font_size",13); status.add_theme_color_override("font_color",INK); box.add_child(status)
	return status


func _body_label(parent:VBoxContainer)->Label:
	var label:=Label.new(); label.custom_minimum_size.x=200; label.size_flags_vertical=Control.SIZE_EXPAND_FILL; label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; label.max_lines_visible=9; label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS; label.add_theme_color_override("font_color",INK); parent.add_child(label); return label


func _counter(parent:HBoxContainer,minimum:int,maximum:int,value:int)->SpinBox:
	var spin:=SpinBox.new(); spin.min_value=minimum; spin.max_value=maximum; spin.value=value; spin.custom_minimum_size.x=82; parent.add_child(spin); return spin


func _add_readiness_meter(parent:HBoxContainer,key:String,caption:String,color:Color)->void:
	var box:=VBoxContainer.new(); box.size_flags_horizontal=Control.SIZE_EXPAND_FILL; parent.add_child(box)
	var label:=Label.new(); label.text=caption; label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; label.add_theme_font_size_override("font_size",10); label.add_theme_color_override("font_color",MUTED); box.add_child(label)
	var meter:=ProgressBar.new(); meter.custom_minimum_size=Vector2(70,12); meter.show_percentage=false
	var fill:=StyleBoxFlat.new(); fill.bg_color=color; fill.set_corner_radius_all(2); meter.add_theme_stylebox_override("fill",fill); box.add_child(meter); readiness_meters[key]=meter


func _policy_choice(parent:HBoxContainer,items:Array[String],tooltip:String)->OptionButton:
	var choice:=OptionButton.new(); choice.tooltip_text=tooltip; choice.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	for item in items:
		choice.add_item(item.capitalize()); choice.set_item_metadata(choice.item_count-1,item)
	parent.add_child(choice)
	return choice


func _action_button(parent:HBoxContainer,text_value:String,action:Callable)->Button:
	var button:=Button.new(); button.text=text_value; button.size_flags_horizontal=Control.SIZE_EXPAND_FILL; button.pressed.connect(action); parent.add_child(button)
	return button


func _choice_is_available(choice:OptionButton)->bool:
	return choice!=null and choice.selected>=0 and choice.selected<choice.item_count and not choice.is_item_disabled(choice.selected)


func _panel_style(color:Color,border:Color,width:int,radius:int)->StyleBoxFlat:
	var style:=StyleBoxFlat.new(); style.bg_color=color; style.border_color=border
	style.set_border_width_all(width); style.set_corner_radius_all(radius); style.content_margin_left=16; style.content_margin_right=16; style.content_margin_top=8; style.content_margin_bottom=8
	return style


func _bar_style(color:Color)->StyleBoxFlat:
	var style:=StyleBoxFlat.new(); style.bg_color=color; style.set_corner_radius_all(3); return style


func _toggle()->void:
	if not modal.visible and _campaign_modal_is_open():
		return
	modal.visible=not modal.visible
	if modal.visible:
		_populate_choices()
		_refresh()


func _populate_choices()->void:
	# Rebuilding capability catalogs must not throw away the player's current
	# unit, weapon, production or exercise choice when the panel is reopened.
	var selected_unit:=_selected_choice_id(unit_choice)
	var selected_weapon:=_selected_choice_id(weapon_choice)
	var selected_equipment:=_selected_choice_id(equipment_choice)
	var selected_program:=_selected_choice_id(training_program_choice)
	unit_choice.clear(); weapon_choice.clear(); equipment_choice.clear(); training_program_choice.clear()
	var capabilities:Dictionary=MilitaryCampaign.military_capabilities()
	for unit in (capabilities.get("units",{}) as Dictionary):
		_add_choice(unit_choice,String(unit),capabilities.units[unit])
	_restore_choice_id(unit_choice,selected_unit)
	_populate_training_weapons()
	_restore_choice_id(weapon_choice,selected_weapon)
	for item in (capabilities.get("equipment",{}) as Dictionary):
		_add_choice(equipment_choice,String(item),capabilities.equipment[item])
	var development:Dictionary=capabilities.get("development",{})
	var military_tier:=int(development.get("tier",0))
	var consumables:Dictionary={"arrows":{"unlocked":MilitaryCampaign._adoption("bow_craft")>=0.08,"reason":"Requires Bow Craft adoption."},"artillery_rounds":{"unlocked":MilitaryCampaign._adoption("powder_artillery")>=0.08,"reason":"Requires Powder Artillery adoption."},"small_arms_ammunition":{"unlocked":military_tier>=5,"reason":"Requires industrial military development from security research supported by production, logistics, and institutions."},"heavy_shells":{"unlocked":military_tier>=6,"reason":"Requires national military development and its supporting industrial-logistics system."},"transport_cart":capabilities.transport_carts}
	for item in consumables: _add_choice(equipment_choice,String(item),consumables[item])
	_restore_choice_id(equipment_choice,selected_equipment)
	for program_id in (capabilities.get("training_programs",{}) as Dictionary):
		var program:Dictionary=capabilities.training_programs[program_id]
		training_program_choice.add_item(("✓ " if bool(program.get("unlocked",false)) else "🔒 ")+String(program.get("label",program_id)).capitalize())
		var program_index:=training_program_choice.item_count-1
		training_program_choice.set_item_metadata(program_index,String(program_id))
		training_program_choice.set_item_disabled(program_index,not bool(program.get("unlocked",false)))
		training_program_choice.set_item_tooltip(program_index,_training_program_tooltip(program))
	_restore_choice_id(training_program_choice,selected_program)
	_update_training_program_choice()


func _selected_choice_id(choice:OptionButton)->String:
	if choice==null or choice.selected<0 or choice.selected>=choice.item_count: return ""
	return String(choice.get_item_metadata(choice.selected))


func _restore_choice_id(choice:OptionButton,choice_id:String)->void:
	if choice==null or choice.item_count<=0: return
	if choice_id!="":
		for index in choice.item_count:
			if String(choice.get_item_metadata(index))==choice_id:
				choice.select(index)
				return
	choice.select(0)


func _populate_training_weapons()->void:
	if weapon_choice==null: return
	weapon_choice.clear()
	if unit_choice.selected<0: return
	var unit:=String(unit_choice.get_item_metadata(unit_choice.selected))
	var capabilities:Dictionary=MilitaryCampaign.military_capabilities()
	for item in (capabilities.get("unit_equipment",{}) as Dictionary).get(unit,[]):
		_add_choice(weapon_choice,String(item),(capabilities.get("equipment",{}) as Dictionary).get(item,{"unlocked":false,"reason":"Equipment definition missing."}))


func _training_program_tooltip(program:Dictionary)->String:
	var gains:Array[String]=[]
	for skill in program.get("command_gain",{}): gains.append("%s +%.1f" % [String(skill).capitalize(),float(program.command_gain[skill])*100.0])
	return "%s\n%d attending at home; %.0f effective days; %.3f extra ration/person/day.\nShared skills: %s. Formation training +%.1f points.\nReserve and assembled armies at home attend; marching and distant armies do not. Shared command skills benefit all unit types.\n%s" % [String(program.get("description","")),MilitaryCampaign._training_program_participants(program),float(program.get("duration_days",0.0)),float(program.get("food_per_participant",0.0)),", ".join(gains),float(program.get("training_gain",0.0))*100.0,String(program.get("reason",""))]


func _update_training_program_choice()->void:
	if training_program_choice==null or training_program_button==null or training_program_choice.selected<0: return
	var active:Dictionary=(MilitaryCampaign.training_program_snapshot().get("active",{}) as Dictionary)
	if not active.is_empty():
		training_program_button.text="CANCEL EXERCISE"
		training_program_button.disabled=false
		training_program_button.tooltip_text="Cancel the active program. Earned preparation remains, but spent food and equipment wear are not recovered."
		return
	var program_id:=String(training_program_choice.get_item_metadata(training_program_choice.selected))
	var catalog:Dictionary=MilitaryCampaign.training_program_catalog()
	var program:Dictionary=catalog.get(program_id,{})
	training_program_button.text="START PROGRAM"
	training_program_button.disabled=not bool(program.get("unlocked",false))
	training_program_button.tooltip_text=_training_program_tooltip(program)


func _add_choice(choice:OptionButton,id:String,gate:Dictionary)->void:
	var unlocked:=bool(gate.get("unlocked",false))
	choice.add_item(("✓ " if unlocked else "🔒 ")+id.replace("_"," ").capitalize())
	var index:=choice.item_count-1; choice.set_item_metadata(index,id); choice.set_item_disabled(index,not unlocked); choice.set_item_tooltip(index,String(gate.get("reason","Available")))


func _refresh()->void:
	var army:Dictionary=MilitaryCampaign.campaign_army_snapshot()
	var capabilities:Dictionary=MilitaryCampaign.military_capabilities()
	var engagement:Dictionary=MilitaryCampaign.engagement_snapshot()
	var threat:Dictionary=MilitaryCampaign.threat_snapshot()
	var home_side:=String(engagement.get("home_side","attacker"))
	var enemy_side:="defender" if home_side=="attacker" else "attacker"
	var display_force:Dictionary=(engagement.get(home_side,{}) as Dictionary) if not engagement.is_empty() else army
	var display_opponent:Dictionary=(engagement.get(enemy_side,{}) as Dictionary) if not engagement.is_empty() else ((threat.get("enemy_force",{}) as Dictionary) if not threat.is_empty() else {})
	var combat:Dictionary=MilitaryCampaign.combat_summary(display_force,display_opponent,1.0)
	var settlement_defense:Dictionary=MilitaryCampaign.settlement_defense_snapshot()
	var construction:Dictionary=settlement_defense.get("construction",{})
	var defense_position:Dictionary=MilitaryCampaign.defensive_position()
	settlement_defense_label.text="HOME: %s  •  %d%% INTEGRITY  •  GROUND ×%.2f\n%d/%d DEFENDERS  •  LOOKOUT %.0f KM%s" % [String(settlement_defense.short).to_upper(),roundi(float(settlement_defense.integrity)*100.0),float(defense_position.modifier),int(settlement_defense.garrison_personnel),int(settlement_defense.garrison_required),float(settlement_defense.observation_radius_km),("  •  BUILD %d%%" % roundi(float(construction.get("progress",0.0))*100.0)) if not construction.is_empty() else ""]
	settlement_defense_label.tooltip_text="%s\nTerrain ×%.2f + fieldworks %.2f + permanent defenses %.2f. The existing aggregate home army is the garrison; no soldier records are created." % [String(settlement_defense.description),float(defense_position.terrain_base),float(defense_position.fieldworks_bonus),float(defense_position.settlement_bonus)]
	var upgrade:Dictionary=settlement_defense.get("next",{})
	settlement_defense_button.disabled=not bool(upgrade.get("available",false))
	settlement_defense_button.text=("BUILDING  %d%%" % roundi(float(construction.get("progress",0.0))*100.0)) if not construction.is_empty() else ("FOUND SETTLEMENT FIRST" if not GameState.settlement_site_committed else ("BUILD  %s" % String((upgrade.get("stage",{}) as Dictionary).get("short","DEFENSE")).to_upper() if not bool(upgrade.get("complete",false)) else "MAXIMUM DEFENSE"))
	settlement_defense_button.tooltip_text=String(upgrade.get("reason","Defense progression unavailable."))
	var troops:=int(army.get("troops",0)); var ready:=float(combat.get("readiness",army.get("readiness",0.0))); var capacity:=int(capabilities.get("recruitment_capacity",0))
	var development:Dictionary=capabilities.get("development",{})
	var organization:Dictionary=capabilities.get("organization",{})
	var line_state:Dictionary=capabilities.get("production_lines",{})
	var army_state:Dictionary=capabilities.get("field_armies",{})
	var front_state:Dictionary=capabilities.get("fronts",{})
	_refresh_primary_action_guidance(army,line_state,capacity)
	strategic_overview.text="%s  •  %s-scale formations (%d aggregate records)  •  COMMAND: %s  •  ARMIES %d/%d  •  PRODUCTION LINES %d/%d  •  FRONTS %d" % [String(development.get("label","FOUNDING DEFENSE")),String(development.get("formation","war band")).to_upper(),int(organization.get("record_count",0)),String(development.get("command","one field host")).to_upper(),int(army_state.get("active",0)),int(army_state.get("capacity",1)),int(line_state.get("active",0)),int(line_state.get("capacity",1)),int(front_state.get("active",0))]
	strategic_overview.tooltip_text="%s\nThis band is not a hand-authored technology unlock. It emerges from adopted security discoveries and is capped by supporting production, logistics, and institutions. %s" % [String(development.get("description","")),String(development.get("next_requirement",""))]
	_refresh_front_controls(front_state)
	if display_opponent.is_empty():
		summary.text="DAY %d     %d HOME RESERVE     ⚔ %.1f ATTACK     🛡 %.1f DEFENSE     %d / %d MOBILIZED" % [int(GameState.elapsed_days),int(combat.get("troops",troops)),float(combat.get("attack_strength",0.0)),float(combat.get("defense_strength",0.0)),MilitaryCampaign._mobilized_count(),capacity]
		condition.value=ready*100.0
		condition.add_theme_stylebox_override("fill",_bar_style(Color("#5f9f73"))); condition.add_theme_stylebox_override("background",_bar_style(Color("#101820")))
		condition.tooltip_text="Aggregate readiness %d%%: personnel condition, training, equipment, ammunition, supply, morale, and leadership." % roundi(ready*100.0)
	else:
		var position:Dictionary=MilitaryCampaign.defensive_position()
		var terrain_defense:=float(engagement.get("terrain_defense",position.modifier)) if not engagement.is_empty() else float(position.modifier)
		var opponent_combat:Dictionary=MilitaryCampaign.combat_summary(display_opponent,display_force,terrain_defense)
		var own_strength:=maxf(0.0,float(combat.get("effective_strength",0.0)))
		var enemy_strength:=maxf(0.0,float(opponent_combat.get("effective_strength",0.0)))
		var relative_share:=own_strength/maxf(0.001,own_strength+enemy_strength)
		summary.text="DAY %d   ⚔ %.1f  🛡 %.1f     %s %d%%  —  RELATIVE STRENGTH  —  %d%% %s" % [int(GameState.elapsed_days),float(combat.get("attack_strength",0.0)),float(combat.get("defense_strength",0.0)),String(display_force.get("name","Our host")).to_upper(),roundi(relative_share*100.0),roundi((1.0-relative_share)*100.0),String(display_opponent.get("name","Enemy")).to_upper()]
		condition.value=relative_share*100.0
		condition.add_theme_stylebox_override("fill",_bar_style(RED)); condition.add_theme_stylebox_override("background",_bar_style(BLUE))
		condition.tooltip_text="%s %.1f effective (readiness %d%%, morale %d%%) vs %s %.1f (readiness %d%%, morale %d%%). Defender ground ×%.2f: %s ×%.2f, fieldworks +%.2f at %d%% adoption. Matchups, equipment, condition, and leadership are included." % [String(display_force.get("name","Our host")),own_strength,roundi(float(combat.get("readiness",0.0))*100.0),roundi(float(combat.get("morale",0.0))*100.0),String(display_opponent.get("name","Enemy")),enemy_strength,roundi(float(opponent_combat.get("readiness",0.0))*100.0),roundi(float(opponent_combat.get("morale",0.0))*100.0),terrain_defense,String(position.terrain),float(position.terrain_base),float(position.fieldworks_bonus),roundi(float(position.fieldworks_adoption)*100.0)]
	var readiness_components:Dictionary=combat.get("readiness_components",{})
	var personnel_profile:Dictionary=MilitaryCampaign.force_condition_profile(display_force)
	for band_data in personnel_profile.get("bands",[]):
		var band_id:=String(band_data.get("id",""))
		if not condition_bands.has(band_id): continue
		var band:ColorRect=condition_bands[band_id]
		var band_count:=int(band_data.get("count",0))
		band.visible=band_count>0
		band.size_flags_stretch_ratio=maxf(0.001,float(band_data.get("share",0.0)))
		band.tooltip_text="%s: %d personnel (%d%%)" % [String(band_data.get("label",band_id.capitalize())),band_count,roundi(float(band_data.get("share",0.0))*100.0)]
	var weakest_key:=""; var weakest_value:=2.0
	for key in readiness_meters:
		var value:=clampf(float(readiness_components.get(key,1.0)),0.0,1.0); (readiness_meters[key] as ProgressBar).value=value*100.0; (readiness_meters[key] as ProgressBar).tooltip_text="%s: %d%%" % [String(key).capitalize(),roundi(value*100.0)]
		if value<weakest_value: weakest_value=value; weakest_key=String(key)
	readiness_bottleneck.text="▼ %s %d%%" % [weakest_key.to_upper(),roundi(weakest_value*100.0)]
	readiness_bottleneck.tooltip_text="The weakest readiness component is the immediate constraint on field performance."
	var formation_lines:Array[String]=[]
	var formation_combat:=MilitaryCampaign.formation_combat_summaries(display_force,display_opponent,1.0)
	var displayed_formations:Array=display_force.get("formations",[])
	var formation_cards:Array[Dictionary]=[]
	for formation_index in displayed_formations.size(): formation_cards.append({"formation":displayed_formations[formation_index],"stats":formation_combat[formation_index] if formation_index<formation_combat.size() else {}})
	formation_cards.sort_custom(func(a:Dictionary,b:Dictionary)->bool: return int((a.formation as Dictionary).get("count",0))>int((b.formation as Dictionary).get("count",0)))
	for formation_index in mini(3,formation_cards.size()):
		var formation:Dictionary=formation_cards[formation_index].formation
		var formation_stats:Dictionary=formation_cards[formation_index].stats
		formation_lines.append("%s  %s  %s/%s personnel  •  %s %s/%s\n  ⚔ %.1f   🛡 %.1f   RDY %d%%   COND %d%%" % [_unit_icon(String(formation.get("unit",""))),String(formation.get("unit","unit")).replace("_"," ").capitalize(),_compact_count(int(formation.get("count",0))),_compact_count(int(formation.get("authorized_count",formation.get("count",0)))),String(formation.get("weapon","gear")).replace("_"," "),_compact_count(int(formation.get("equipment",0))),_compact_count(int(formation.get("equipment_required",formation.get("count",0)))),float(formation_stats.get("attack_strength",0.0)),float(formation_stats.get("defense_strength",0.0)),roundi(float(formation_stats.get("readiness",ready))*100.0),roundi(float(formation_stats.get("condition",1.0))*100.0)])
	if formation_cards.size()>3: formation_lines.append("+ %d more cohorts in the field" % (formation_cards.size()-3))
	var missing:Dictionary=MilitaryCampaign.home_captive_snapshot()
	var custody_line:="\n\nPOW %d  •  COMMAND GROUPS %d  •  OUR CAPTIVES %d" % [int(army.get("foreign_prisoners",0)),(army.get("held_generals",[]) as Array).size(),int(missing.get("count",0))]
	formations.text=("No field formations. Raise a recruit cohort, then train it." if formation_lines.is_empty() else "\n".join(formation_lines))+custody_line
	var captive_tooltip:="The captive population cohort may return through exchange or daily group-level resolution. Current average return chance: %.2f%%/day; captivity duration: %d days." % [float(missing.get("average_daily_return_chance",0.0))*100.0,int(missing.get("oldest_days",0))]
	var held_commander_lines:Array[String]=[]
	for held_general in (army.get("held_generals",[]) as Array).slice(0,3):
		held_commander_lines.append("%s — CMD %d  TAC %d  LOG %d  RES %d" % [String(held_general.get("name","Captured command staff")),roundi(float(held_general.get("command",0.5))*100.0),roundi(float(held_general.get("tactics",0.5))*100.0),roundi(float(held_general.get("logistics",0.5))*100.0),roundi(float(held_general.get("resolve",0.5))*100.0)])
	if not held_commander_lines.is_empty(): captive_tooltip+="\nHeld command groups:\n"+"\n".join(held_commander_lines)
	formations.tooltip_text=captive_tooltip
	var commander:Dictionary=combat.get("commander",{})
	var program_state:Dictionary=army.get("training_program",{})
	var command_growth:Dictionary=program_state.get("command_development",{})
	commander_details.text="%s%s\nCMD %d+%d  TAC %d+%d  LOG %d+%d  RES %d+%d" % [String(commander.get("name","No field command institution")),"  •  ACTING" if bool(commander.get("acting",false)) else "",roundi(float(commander.get("command",0.0))*100.0),roundi(float(command_growth.get("command",0.0))*100.0),roundi(float(commander.get("tactics",0.0))*100.0),roundi(float(command_growth.get("tactics",0.0))*100.0),roundi(float(commander.get("logistics",0.0))*100.0),roundi(float(command_growth.get("logistics",0.0))*100.0),roundi(float(commander.get("resolve",0.0))*100.0),roundi(float(command_growth.get("resolve",0.0))*100.0)]
	commander_details.tooltip_text="The number after each + is persistent development earned by command and army exercises. It improves the current Marshal or acting command institution without creating officer rosters."
	queues.text="Training rate %.1f/day  •  capacity %s\nProduction %d/%d lines  •  %.0f work/day\n\n%s" % [float(capabilities.get("training_rate",0.0)),_compact_count(int(capabilities.get("training_capacity",0))),int(line_state.get("active",0)),int(line_state.get("capacity",1)),float(line_state.get("total_daily_work",0.0)),_queue_summary(army)]
	queues.tooltip_text="Recruit training accident risk: %d%% of the untreated baseline. Army programs consume extra rations while active; field exercises and war games also cause fatigue and equipment wear. Exercise preparation decays when it is not maintained." % roundi(float(capabilities.get("training_injury_multiplier",1.0))*100.0)
	_update_training_program_choice()
	var burden:Dictionary=army.get("economic_burden",{})
	var reputation:Dictionary=MilitaryCampaign.war_reputation_snapshot()
	inventory.text=_inventory_summary(army)+"\n\nLogistics %d%%  •  Field supply %d%%\nLabor withheld %d  •  Occupation %d in %d regions\nUpkeep %.2f/day  •  Reputation M%d F%d G%d" % [roundi(float(capabilities.get("logistics_practice",0.0))*100.0),roundi(MilitaryCampaign.field_provision_delivery_ratio()*100.0),int(burden.get("mobilized_population",0)),int(burden.get("occupation_personnel",0)),int(burden.get("occupation_regions",0)),float(burden.get("currency_upkeep_units",0.0)),roundi(float(reputation.get("mercy",0.0))*100.0),roundi(float(reputation.get("fear",0.0))*100.0),roundi(float(reputation.get("grievance",0.0))*100.0)]
	inventory.tooltip_text="Daily convoy capacity %.1f load; %.1f used today and %.1f banked. Carts add capacity but require logistics workers. Load examples: spear %.1f, siege kit %.1f, field gun %.1f, arrows %.2f each." % [float(capabilities.get("delivery_load_capacity",0.0)),float(army.get("delivery_load_used_today",0.0)),float(army.get("delivery_load_bank",0.0)),MilitaryCampaign._equipment_delivery_load("spear"),MilitaryCampaign._equipment_delivery_load("siege_kit"),MilitaryCampaign._equipment_delivery_load("field_gun"),MilitaryCampaign._ammunition_delivery_load("arrows")]
	var has_pending_aftermath:=not MilitaryCampaign.pending_aftermath.is_empty()
	var has_held_captives:=int(army.get("foreign_prisoners",0))>0 or not (army.get("held_generals",[]) as Array).is_empty()
	var can_manage_held_captives:=has_held_captives and threat.is_empty() and engagement.is_empty()
	aftermath_row.visible=has_pending_aftermath or can_manage_held_captives
	aftermath_label.text="BATTLE DECISION" if has_pending_aftermath else "HELD CAPTIVES"
	spoils_policy.visible=has_pending_aftermath
	threat_row.visible=not threat.is_empty()
	if not threat.is_empty():
		var protection:Dictionary=MilitaryCampaign.store_protection()
		var protection_percent:=roundi(float(protection.seizure_reduction)*100.0)
		threat_label.text="⚠  %s — about %d fighters — due day %d  •  STORES %s" % [String(threat.get("title","Threat approaching")),int(threat.get("estimated_strength",0)),int(threat.get("deadline_day",0)),("%d%% SHIELDED" % protection_percent) if protection_percent>0 else "EXPOSED"]
		threat_label.tooltip_text="Fortified Stores adoption %d%%; reduces seizure of threatened reserves by %d%%." % [roundi(float(protection.adoption)*100.0),protection_percent]
	engagement_row.visible=not engagement.is_empty()
	if not engagement.is_empty():
		var home_force:Dictionary=engagement.get(home_side,{}); var enemy_force:Dictionary=engagement.get(enemy_side,{})
		var round_records:Array=engagement.get("rounds",[])
		var last_round:Dictionary=round_records[-1] if not round_records.is_empty() else {}
		var round_report:=""
		if not last_round.is_empty(): round_report="  •  LOSSES %d / %d  •  %s" % [int(last_round.get("%s_losses" % home_side,0)),int(last_round.get("%s_losses" % enemy_side,0)),String(last_round.get("intensity","contact")).to_upper()]
		engagement_label.text="ROUND %02d   %s %d  —  %d %s   Last: %s%s" % [int(engagement.get("round",0))+1,String(home_force.get("name","Army")),int(home_force.get("troops",0)),int(enemy_force.get("troops",0)),String(enemy_force.get("name","Enemy")),String(engagement.get("last_order","ready")).capitalize(),round_report]
		engagement_label.tooltip_text=String(last_round.get("event","Choose whether to hold, press the attack, or withdraw."))
	if field_army_dialog!=null and field_army_dialog.visible: _refresh_field_army_dialog()
	_refresh_overview_status(army,combat,capacity,army_state,front_state,threat,engagement,line_state)
	_fit_modal_to_viewport()


func _refresh_overview_status(army:Dictionary,combat:Dictionary,mobilization_capacity:int,army_state:Dictionary,front_state:Dictionary,threat:Dictionary,engagement:Dictionary,line_state:Dictionary)->void:
	if overview_armies==null or overview_front==null or primary_action_button==null: return
	var field_armies:Array=army_state.get("armies",[])
	var field_personnel:=0
	var moving_armies:=0
	for field_army_variant in field_armies:
		var field_army:Dictionary=field_army_variant
		field_personnel+=maxi(0,int(field_army.get("troops",0)))
		if String(field_army.get("status","stationed"))=="moving": moving_armies+=1
	var home_personnel:=maxi(0,int(army.get("troops",0)))
	overview_armies.text="%d/%d FIELD ARMIES  •  %s MANEUVER PERSONNEL\n%s HOME  •  %d MOVING  •  %s/%s MOBILIZED" % [int(army_state.get("active",field_armies.size())),int(army_state.get("capacity",1)),_compact_count(field_personnel),_compact_count(home_personnel),moving_armies,_compact_count(MilitaryCampaign._mobilized_count()),_compact_count(mobilization_capacity)]
	overview_armies.tooltip_text="Field armies are bounded aggregate commands. Personnel remain part of the population and consume real training, equipment, provisions, and upkeep."
	var fronts:Array=front_state.get("fronts",[])
	if not MilitaryCampaign.pending_aftermath.is_empty():
		overview_front.text="BATTLE ENDED  •  AFTERMATH POLICY REQUIRED\nPrisoners, command staff, and spoils remain unresolved."
		overview_front.add_theme_color_override("font_color",GOLD)
	elif not engagement.is_empty():
		overview_front.text="BATTLE ROUND %d  •  ORDER REQUIRED\n%s" % [int(engagement.get("round",0))+1,String(engagement.get("last_order","No order issued")).capitalize()]
		overview_front.add_theme_color_override("font_color",RED)
	elif not threat.is_empty():
		overview_front.text="THREAT DUE DAY %d  •  RESPONSE REQUIRED\n%s  •  ESTIMATED %s" % [int(threat.get("deadline_day",0)),String(threat.get("title","Approaching force")).to_upper(),_compact_count(int(threat.get("estimated_strength",0)))]
		overview_front.add_theme_color_override("font_color",RED)
	elif not fronts.is_empty():
		var front:Dictionary=fronts[0]
		overview_front.text="%s\n%s  •  %s STANCE  •  SCORE %+.0f" % [String(front.get("war_name","ACTIVE WAR")).to_upper(),String(front.get("target","ACTIVE FRONT")).to_upper(),String(front.get("stance","balanced")).to_upper(),float(front.get("war_score",0.0))]
		overview_front.add_theme_color_override("font_color",INK)
	else:
		overview_front.text="NO ACTIVE FRONT OR BATTLE ORDER\nObserved threats and declared wars will appear here."
		overview_front.add_theme_color_override("font_color",MUTED)
	overview_front.tooltip_text="Front information is limited to returned reports, direct observation, and confirmed military intelligence."

	primary_action_button.disabled=false
	if not MilitaryCampaign.pending_aftermath.is_empty():
		primary_action_mode="orders"
		primary_action_label.text="NEXT DECISION  Resolve the battle aftermath. The selected policy changes prisoners, spoils, reputation, and later resistance."
		primary_action_button.text="RESOLVE BATTLE AFTERMATH"
	elif not engagement.is_empty():
		primary_action_mode="orders"
		primary_action_label.text="NEXT DECISION  Issue this round's battle order. Holding, pressing, or retreating changes exposure, losses, and campaign position."
		primary_action_button.text="ISSUE BATTLE ORDER"
	elif not threat.is_empty():
		primary_action_mode="orders"
		primary_action_label.text="NEXT DECISION  Answer the approaching threat before its deadline. Defense, tribute, and withdrawal carry different losses and political costs."
		primary_action_button.text="CHOOSE THREAT RESPONSE"
	elif not fronts.is_empty():
		primary_action_mode="orders"
		primary_action_label.text="NEXT DECISION  Review the active front and confirm its stance. Cautious preserves people; offensive accepts greater losses for pressure."
		primary_action_button.text="REVIEW FRONT ORDERS"
	elif not field_armies.is_empty():
		primary_action_mode="field_armies"
		primary_action_label.text="NEXT DECISION  Inspect your maneuver armies and issue movement orders to known strategic destinations."
		primary_action_button.text="MOVE OR INSPECT ARMIES"
	elif int(army.get("recruits",0))>0:
		primary_action_mode="training"
		primary_action_label.text="NEXT DECISION  Recruits are waiting. Choose a formation and compatible equipment; training consumes time and capacity."
		primary_action_button.text="TRAIN WAITING RECRUITS"
	elif not (army.get("formations",[]) as Array).is_empty():
		primary_action_mode="field_armies"
		primary_action_label.text="NEXT DECISION  Trained home formations can be assembled into one bounded maneuver army without creating individual soldier records."
		primary_action_button.text="FORM A FIELD ARMY"
	elif float((combat.get("readiness_components",{}) as Dictionary).get("equipment",1.0))<0.45 and int(line_state.get("active",0))<int(line_state.get("capacity",1)):
		primary_action_mode="supply"
		primary_action_label.text="NEXT DECISION  Equipment is the immediate readiness bottleneck. Queue a bounded production order using real materials and workshop capacity."
		primary_action_button.text="OPEN MILITARY PRODUCTION"
	else:
		primary_action_mode="armies"
		primary_action_label.text="NEXT DECISION  Build the first force. Raise a numeric recruit cohort from available mobilization capacity, then train it."
		primary_action_button.text="PLAN FORCE BUILDUP"
	primary_action_button.tooltip_text="Open the relevant command section without issuing an irreversible order. Costs and blockers are shown at the decision control."


func _activate_primary_action()->void:
	match primary_action_mode:
		"orders": command_tabs.current_tab=TAB_ORDERS
		"armies": command_tabs.current_tab=TAB_ARMIES
		"training": command_tabs.current_tab=TAB_TRAINING
		"supply": command_tabs.current_tab=TAB_SUPPLY
		"field_armies": _open_field_armies()
		_: command_tabs.current_tab=TAB_SITUATION


func _refresh_primary_action_guidance(army:Dictionary,line_state:Dictionary,mobilization_capacity:int)->void:
	var mobilized:=MilitaryCampaign._mobilized_count()
	var recruit_room:=maxi(0,mobilization_capacity-mobilized)
	if raise_recruits_button!=null:
		raise_recruits_button.disabled=recruit_room<=0
		raise_recruits_button.tooltip_text=(
			"CURRENT  %s / %s mobilized.\nACTION  Move up to %s people from civilian functions into the untrained reserve.\nCOST  Their civilian labor is unavailable until demobilized."
			% [_compact_count(mobilized),_compact_count(mobilization_capacity),_compact_count(mini(recruit_room,int(recruit_count.value)))]
		) if recruit_room>0 else "BLOCKED  Mobilization capacity is full.\nNEXT  Demobilize personnel, expand the working-age population, or improve institutions and security capacity."
	var recruits:=maxi(0,int(army.get("recruits",0)))
	if begin_training_button!=null:
		var training_selection_ready:=_choice_is_available(unit_choice) and _choice_is_available(weapon_choice)
		begin_training_button.disabled=recruits<=0 or not training_selection_ready
		begin_training_button.tooltip_text=(
			"CURRENT  %s recruits await training.\nACTION  Train up to %s as the selected formation.\nCOST  Time, training capacity, and physically issued equipment; personnel remain withheld from civilian labor."
			% [_compact_count(recruits),_compact_count(mini(recruits,int(train_count.value)))]
		) if recruits>0 else "BLOCKED  No recruits await training.\nNEXT  Use RAISE RECRUITS, then return here and choose an unlocked unit and compatible equipment."
	if queue_production_button!=null:
		var active_lines:=int(line_state.get("active",0)); var line_capacity:=int(line_state.get("capacity",1))
		var lines_full:=active_lines>=line_capacity
		queue_production_button.disabled=lines_full or not _choice_is_available(equipment_choice)
		queue_production_button.tooltip_text=(
			"CURRENT  %d / %d production lines assigned.\nACTION  Reserve materials and build %s of the selected item.\nCONSEQUENCE  Output enters aggregate military stores as work completes."
			% [active_lines,line_capacity,_compact_count(int(produce_count.value))]
		) if not lines_full else "BLOCKED  Every military production line is assigned.\nNEXT  Wait for a line to finish, cancel or reallocate one, or improve security, production, logistics, and institutions to expand capacity."
	if settlement_defense_button!=null and settlement_defense_button.disabled:
		var blocker:=settlement_defense_button.tooltip_text
		settlement_defense_button.tooltip_text="BLOCKED  %s\nNEXT  Satisfy the listed settlement, material, and Defense-labor requirement; this button will unlock automatically." % blocker


func _unit_icon(unit:String)->String:
	return String({"levy":"🪓","line_infantry":"🛡","skirmisher":"🏹","cavalry":"🐎","siege_engineer":"🛠","field_artillery":"💥","rifle_infantry":"◆","machine_gun_company":"▰","motorized_infantry":"▸","armored_formation":"▣","modern_artillery":"✦"}.get(unit,"⚑"))


func _refresh_front_controls(front_state:Dictionary)->void:
	var fronts:Array=front_state.get("fronts",[])
	front_control_row.visible=not fronts.is_empty()
	if fronts.is_empty(): return
	var previous_opponent:=""
	if front_choice.selected>=0 and front_choice.selected<front_choice.item_count:
		previous_opponent=String(front_choice.get_item_metadata(front_choice.selected))
	front_choice.clear()
	var selected_index:=0
	for index in fronts.size():
		var front:Dictionary=fronts[index]
		var opponent_id:=String(front.get("opponent_id",""))
		front_choice.add_item("%s — %s  •  SUPPLY %d%%  •  SCORE %+.0f" % [String(front.get("war_name","ACTIVE WAR")).to_upper(),String(front.get("target","FRONT")),roundi(float(front.get("supply",0.0))*100.0),float(front.get("war_score",0.0))])
		front_choice.set_item_metadata(index,opponent_id)
		front_choice.set_item_tooltip(index,"%s\nField %s • reserve %s • estimated enemy %s\nOur exhaustion %d%% • enemy exhaustion %d%%" % [String(front.get("objective","Active front")),_compact_count(int(front.get("field_personnel",0))),_compact_count(int(front.get("reserve_personnel",0))),_compact_count(roundi(float(front.get("enemy_personnel",0.0)))),roundi(float(front.get("our_exhaustion",0.0))*100.0),roundi(float(front.get("enemy_exhaustion",0.0))*100.0)])
		if opponent_id==previous_opponent: selected_index=index
	front_choice.select(selected_index)
	var current_front:Dictionary=fronts[selected_index]
	var stance:=String(current_front.get("stance","balanced"))
	for index in front_stance_choice.item_count:
		if String(front_stance_choice.get_item_metadata(index))==stance:
			front_stance_choice.select(index)
			break


func _apply_front_stance()->void:
	if front_choice.selected<0 or front_stance_choice.selected<0: return
	var opponent_id:=String(front_choice.get_item_metadata(front_choice.selected))
	var stance:=String(front_stance_choice.get_item_metadata(front_stance_choice.selected))
	_report(CivilizationSystem.set_front_stance(opponent_id,stance))


func _compact_count(value:int)->String:
	var amount:=float(maxi(0,value))
	if amount>=1_000_000_000.0: return "%.2fB" % (amount/1_000_000_000.0)
	if amount>=1_000_000.0: return "%.2fM" % (amount/1_000_000.0)
	if amount>=1_000.0: return "%.1fK" % (amount/1_000.0)
	return str(value)


func _queue_summary(army:Dictionary)->String:
	var lines:Array[String]=[]
	lines.append("RESERVE  %s recruits  •  %s recovering" % [_compact_count(int(army.get("recruits",0))),_compact_count(int(army.get("training_injuries",0)))])
	var program_state:Dictionary=army.get("training_program",{})
	var active_program:Dictionary=program_state.get("active",{})
	if not active_program.is_empty():
		var paused:=String(active_program.get("paused_reason",""))
		lines.append("EXERCISE  %s  %.1f/%.0f days  •  %d%%%s" % [String(active_program.get("label","PROGRAM")).capitalize(),float(active_program.get("progress_days",0.0)),float(active_program.get("duration_days",1.0)),roundi(float(active_program.get("last_efficiency",0.0))*100.0),("  •  PAUSED" if paused!="" else "")])
	elif not (program_state.get("last_completed",{}) as Dictionary).is_empty():
		var last_program:Dictionary=program_state.last_completed
		lines.append("LAST EXERCISE  %s  •  readiness reserve %d%%" % [String(last_program.get("label","PROGRAM")).capitalize(),roundi(float(program_state.get("readiness_bonus",0.0))*100.0)])
	for order in (army.get("training_queue",[]) as Array): lines.append("TRAIN  %s %s  %d/%d days" % [_compact_count(int(order.get("count",0))),String(order.get("unit","unit")).replace("_"," "),roundi(float(order.get("progress_days",0.0))),roundi(float(order.get("required_days",1.0)))])
	for job in (army.get("equipment_queue",[]) as Array): lines.append("LINE %d  %s %s  %d%%  •  EFF %d%%" % [int(job.get("id",0)),_compact_count(int(job.get("count",0))),String(job.get("item","item")).replace("_"," "),roundi(100.0*float(job.get("progress_days",0.0))/maxf(0.01,float(job.get("required_days",1.0)))),roundi(float(job.get("efficiency",0.20))*100.0)])
	return "\n".join(lines.slice(0,6))


func _inventory_summary(army:Dictionary)->String:
	var lines:Array[String]=[]
	for item in (army.get("military_inventory",{}) as Dictionary):
		var amount:=int(army.military_inventory[item]); var damaged:=int((army.get("damaged_equipment",{}) as Dictionary).get(item,0))
		if amount>0 or damaged>0: lines.append("%s  %s ready%s" % [String(item).replace("_"," ").capitalize(),_compact_count(amount),"  •  %s damaged" % _compact_count(damaged) if damaged>0 else ""])
	for item in (army.get("military_consumables",{}) as Dictionary):
		var amount:=int(army.military_consumables[item]); if amount>0: lines.append("%s  %s" % [String(item).replace("_"," ").capitalize(),_compact_count(amount)])
	lines.append("Transport carts  %s" % _compact_count(int(GameState.resource_stockpiles.get("Transport Carts",0))))
	return "\n".join(lines)


func _raise_recruits()->void: _report(MilitaryCampaign.raise_recruits(int(recruit_count.value)))


func _reinforce_weakest()->void:
	var army:Dictionary=MilitaryCampaign.campaign_army_snapshot(); var target:Dictionary={}; var largest_gap:=0
	for formation in (army.get("formations",[]) as Array):
		var gap:=maxi(0,int(formation.get("authorized_count",formation.get("count",0)))-int(formation.get("count",0)))
		if gap>largest_gap: largest_gap=gap; target=formation
	if target.is_empty():
		_report({"error":"No depleted formation currently needs reinforcement."})
		return
	_report(MilitaryCampaign.reinforce_formation(int(target.id),mini(largest_gap,int(recruit_count.value))))


func _start_training()->void:
	if unit_choice.selected<0 or weapon_choice.selected<0: return
	_report(MilitaryCampaign.start_training(String(unit_choice.get_item_metadata(unit_choice.selected)),String(weapon_choice.get_item_metadata(weapon_choice.selected)),int(train_count.value)))


func _training_program_action()->void:
	var active:Dictionary=(MilitaryCampaign.training_program_snapshot().get("active",{}) as Dictionary)
	if not active.is_empty():
		_report(MilitaryCampaign.cancel_training_program())
		return
	if training_program_choice.selected<0: return
	_report(MilitaryCampaign.start_training_program(String(training_program_choice.get_item_metadata(training_program_choice.selected))))


func _queue_production()->void:
	if equipment_choice.selected<0: return
	var item:=String(equipment_choice.get_item_metadata(equipment_choice.selected)); var count:=int(produce_count.value); var result:Dictionary
	if item=="transport_cart": result=MilitaryCampaign.queue_transport_cart_production(count)
	elif item in ["arrows","artillery_rounds","small_arms_ammunition","heavy_shells"]: result=MilitaryCampaign.queue_consumable_production(item,count)
	else: result=MilitaryCampaign.queue_equipment_production(item,count)
	_report(result)


func _queue_repair()->void:
	if equipment_choice.selected<0: return
	var item:=String(equipment_choice.get_item_metadata(equipment_choice.selected))
	if item in ["transport_cart","arrows","artillery_rounds","small_arms_ammunition","heavy_shells"]:
		_report({"error":"%s is replaced through production, not equipment repair." % item.replace("_"," ").capitalize()})
		return
	_report(MilitaryCampaign.queue_equipment_repair(item,int(produce_count.value)))


func _start_settlement_defense_upgrade()->void:
	_report(MilitaryCampaign.start_settlement_defense_upgrade())


func _resolve_aftermath_or_captives()->void:
	var selected_prisoner_policy:=String(prisoner_policy.get_item_metadata(prisoner_policy.selected))
	var selected_general_policy:=String(general_policy.get_item_metadata(general_policy.selected))
	if not MilitaryCampaign.pending_aftermath.is_empty():
		_report(MilitaryCampaign.resolve_aftermath(selected_prisoner_policy,String(spoils_policy.get_item_metadata(spoils_policy.selected)),selected_general_policy))
	else:
		_report(MilitaryCampaign.resolve_held_captives(selected_prisoner_policy,selected_general_policy))


func _report(result:Dictionary)->void:
	feedback.text=String(result.get("error",result.get("message","Orders accepted; campaign state updated.")))
	feedback.tooltip_text=feedback.text
	feedback.add_theme_color_override("font_color",RED if result.has("error") else Color("#8fc58d"))
	_refresh()


func _open_field_armies()->void:
	field_army_feedback_override=""
	_refresh_field_army_dialog()
	field_army_dialog.popup_centered(Vector2i(820,560))


func _refresh_field_army_dialog()->void:
	var state:Dictionary=MilitaryCampaign.field_armies_snapshot()
	var previous_army_id:=_selected_field_army_id()
	var previous_destination:=""
	if field_army_destination.selected>=0 and field_army_destination.selected<field_army_destination.item_count: previous_destination=String(field_army_destination.get_item_metadata(field_army_destination.selected))
	field_army_choice.clear()
	var armies:Array=state.get("armies",[])
	var army_selection:=0
	for index in armies.size():
		var army:Dictionary=armies[index]
		var status:=String(army.get("status","stationed")).to_upper()
		var location:=String(army.get("destination_name",army.get("location_name","HOME"))) if status=="MOVING" else String(army.get("location_name","HOME"))
		field_army_choice.add_item("%s  •  %s  •  %s @ %s" % [String(army.get("name","FIELD ARMY")).to_upper(),_compact_count(int(army.get("troops",0))),status,location])
		field_army_choice.set_item_metadata(index,int(army.get("army_id",0)))
		if int(army.get("army_id",0))==previous_army_id: army_selection=index
	if not armies.is_empty(): field_army_choice.select(army_selection)
	field_army_destination.clear()
	var destinations:Array=state.get("destinations",[])
	var destination_selection:=0
	for index in destinations.size():
		var destination:Dictionary=destinations[index]
		field_army_destination.add_item(("⌂ " if String(destination.get("kind",""))=="home" else "➤ ")+String(destination.get("label","KNOWN DESTINATION")))
		field_army_destination.set_item_metadata(index,String(destination.get("id","")))
		field_army_destination.set_item_tooltip(index,"Known through returned geography and location intelligence. MOVE spends travel time and field supply; an offensive requires the army stationed at the selected strategic objective." if String(destination.get("kind",""))!="home" else "Home settlement. An army must return here before its personnel can be released back into the unassigned trained reserve.")
		if String(destination.get("id",""))==previous_destination: destination_selection=index
	if not destinations.is_empty(): field_army_destination.select(destination_selection)
	_refresh_field_army_detail()
	_refresh_field_army_actions(state,armies,destinations)


func _refresh_field_army_actions(state:Dictionary,armies:Array,destinations:Array)->void:
	var home_available:=maxi(0,int(MilitaryCampaign.home_army.get("troops",0)))
	var capacity:=maxi(1,int(state.get("capacity",1)))
	var formation_blocker:=""
	if not MilitaryCampaign.active_engagement.is_empty() or not MilitaryCampaign.pending_aftermath.is_empty(): formation_blocker="Finish the active battle and aftermath."
	elif armies.size()>=capacity: formation_blocker="Command capacity is full (%d/%d armies). Improve security, logistics, production, and institutions." % [armies.size(),capacity]
	elif home_available<=0: formation_blocker="No unassigned trained personnel are at home. Raise recruits, train them, and wait for training to finish."
	field_army_form_button.disabled=formation_blocker!=""
	field_army_form_button.tooltip_text=("BLOCKED  %s\nNEXT  Complete that recovery step, then form the maneuver army here." % formation_blocker) if formation_blocker!="" else "CURRENT  %s trained personnel are unassigned at home.\nACTION  Transfer %s into one bounded maneuver command.\nCONSEQUENCE  They leave home defense and can receive timed movement orders." % [_compact_count(home_available),_compact_count(mini(home_available,int(field_army_create_count.value)))]
	var selected_id:=_selected_field_army_id(); var selected:Dictionary={}
	for army_variant in armies:
		var candidate:Dictionary=army_variant
		if int(candidate.get("army_id",0))==selected_id: selected=candidate; break
	var no_army:=selected.is_empty()
	var moving:=not no_army and String(selected.get("status","stationed"))=="moving"
	field_army_move_button.disabled=no_army or moving or field_army_destination.selected<0
	field_army_move_button.tooltip_text="BLOCKED  Form and select a maneuver army first.\nNEXT  Take trained home personnel with FORM MANEUVER ARMY." if no_army else ("BLOCKED  This army is already moving to %s.\nNEXT  Wait for arrival before assigning another destination." % String(selected.get("destination_name","its destination")) if moving else "ACTION  March the selected army over known geography.\nCOST  Physical travel time and field supply.\nNEXT  Station it at a known enemy objective before launching an offensive.")
	field_army_return_button.disabled=no_army or (not moving and String(selected.get("location_id",""))=="player_home")
	field_army_return_button.tooltip_text="BLOCKED  Select an army away from home.\nNEXT  Choose a field army that is stationed or moving elsewhere." if field_army_return_button.disabled else "ACTION  Replace the current order with a timed march home.\nCONSEQUENCE  The army remains mobilized until it arrives and is released."
	var releasable:=not no_army and not moving and String(selected.get("location_id",""))=="player_home"
	field_army_disband_button.disabled=not releasable
	field_army_disband_button.tooltip_text="ACTION  Dissolve this command and return its trained formations and equipment to the unassigned home pool." if releasable else "BLOCKED  An army can be released only while stationed at home.\nNEXT  Use RETURN ARMY HOME and wait for its arrival."
	if field_army_feedback_override!="":
		field_army_feedback.text=field_army_feedback_override
		field_army_feedback.add_theme_color_override("font_color",RED if field_army_feedback_override_error else Color("#8fc58d"))
	elif no_army:
		field_army_feedback.text="NEXT  Raise recruits → train a formation → FORM MANEUVER ARMY."
		field_army_feedback.add_theme_color_override("font_color",MUTED)
	elif destinations.size()<=1:
		field_army_feedback.text="NEXT  Return a scout report or locate a foreign settlement to reveal another valid destination."
		field_army_feedback.add_theme_color_override("font_color",MUTED)
	elif moving:
		field_army_feedback.text="IN PROGRESS  %s is marching to %s; time and supply determine arrival." % [String(selected.get("name","The army")),String(selected.get("destination_name","its destination"))]
		field_army_feedback.add_theme_color_override("font_color",MUTED)
	else:
		field_army_feedback.text="NEXT  Choose a known destination and MOVE ARMY. To attack, station it on the selected enemy objective first."
		field_army_feedback.add_theme_color_override("font_color",MUTED)
	field_army_feedback.tooltip_text=field_army_feedback.text


func _refresh_field_army_detail()->void:
	var state:Dictionary=MilitaryCampaign.field_armies_snapshot()
	var selected_id:=_selected_field_army_id()
	var selected:Dictionary={}
	for army_variant in state.get("armies",[]):
		var army:Dictionary=army_variant
		if int(army.get("army_id",0))==selected_id: selected=army; break
	if selected.is_empty():
		field_army_detail.text="[color=#9ca9b8]No maneuver army exists. Form one by taking a numeric share of the trained, unassigned home formations. Capacity: %d aggregate armies.[/color]" % int(state.get("capacity",1))
		return
	var status:=String(selected.get("status","stationed"))
	var movement:="STATIONED AT %s" % String(selected.get("location_name","HOME"))
	if status=="moving": movement="MOVING TO %s  •  %.0f / %.0f KM REMAIN  •  %.1f KM/DAY  •  ETA DAY %d" % [String(selected.get("destination_name","DESTINATION")),float(selected.get("distance_remaining_km",0.0)),float(selected.get("distance_total_km",0.0)),float(selected.get("speed_km_day",0.0)),int(selected.get("arrival_day",0))]
	var commander:Dictionary=selected.get("commander",{})
	var recovery_total:=maxi(0,int(selected.get("wounded_pool",0)))+maxi(0,int(selected.get("scattered_pool",0)))
	var lines:Array[String]=["[font_size=20][color=#d5ad58]%s[/color][/font_size]" % String(selected.get("name","FIELD ARMY")),"%s\nPERSONNEL %s  •  SUPPLY %d%%  •  READINESS %d%%  •  MORALE %d%%" % [movement,_compact_count(int(selected.get("troops",0))),roundi(float(selected.get("supply_level",0.0))*100.0),roundi(float(selected.get("readiness",0.0))*100.0),roundi(float(selected.get("morale",0.0))*100.0)],"COMMAND %s  •  CMD %d  TAC %d  LOG %d  RES %d" % [String(commander.get("name","UNASSIGNED COMMAND")),roundi(float(commander.get("command",0.0))*100.0),roundi(float(commander.get("tactics",0.0))*100.0),roundi(float(commander.get("logistics",0.0))*100.0),roundi(float(commander.get("resolve",0.0))*100.0)],"UNAVAILABLE %s RECOVERING  •  %s CAPTURED  •  %s DEAD RECORDED" % [_compact_count(recovery_total),_compact_count(int(selected.get("captured_pool",0))),_compact_count(int(selected.get("dead",0)))],"\n[color=#75acd9]ASSIGNED AGGREGATE FORMATIONS[/color]"]
	var formation_records:Array=selected.get("formations",[])
	for formation_index in mini(6,formation_records.size()):
		var formation_variant=formation_records[formation_index]
		var formation:Dictionary=formation_variant
		lines.append("  %s %s  •  %s personnel  •  %s %s/%s  •  training %d%%  •  condition %d%%" % [_unit_icon(String(formation.get("unit",""))),String(formation.get("unit","unit")).replace("_"," ").capitalize(),_compact_count(int(formation.get("count",0))),String(formation.get("weapon","equipment")).replace("_"," "),_compact_count(int(formation.get("equipment",0))),_compact_count(int(formation.get("equipment_required",0))),roundi(float(formation.get("training",0.0))*100.0),roundi(float(formation.get("personnel_condition",0.0))*100.0)])
	if formation_records.size()>6: lines.append("  + %d more aggregate formations in this army" % (formation_records.size()-6))
	lines.append("\n[color=#9ca9b8]MOVE is a timed order over known geography. Offensive campaigns require a stationed army at the selected strategic region; soldiers no longer teleport from the home pool.[/color]")
	field_army_detail.text="\n".join(lines)


func _selected_field_army_id()->int:
	if field_army_choice==null or field_army_choice.selected<0 or field_army_choice.selected>=field_army_choice.item_count: return 0
	return int(field_army_choice.get_item_metadata(field_army_choice.selected))


func selected_field_army_id()->int:
	# The terrain map reads this single stable selection so its aggregate marker
	# can mirror the command dialog without duplicating army-selection state.
	return _selected_field_army_id()


func _create_field_army()->void:
	_field_army_report(MilitaryCampaign.create_field_army(int(field_army_create_count.value)))


func _move_selected_field_army()->void:
	if field_army_destination.selected<0: _field_army_report({"error":"No known destination is selected."}); return
	_field_army_report(MilitaryCampaign.move_field_army(_selected_field_army_id(),String(field_army_destination.get_item_metadata(field_army_destination.selected))))


func _return_selected_field_army()->void:
	_field_army_report(MilitaryCampaign.return_field_army(_selected_field_army_id()))


func _disband_selected_field_army()->void:
	_field_army_report(MilitaryCampaign.disband_field_army(_selected_field_army_id()))


func _field_army_report(result:Dictionary)->void:
	field_army_feedback_override=String(result.get("error",result.get("message","Army order accepted.")))
	field_army_feedback_override_error=result.has("error")
	field_army_feedback.text=field_army_feedback_override
	field_army_feedback.tooltip_text=field_army_feedback_override
	field_army_feedback.add_theme_color_override("font_color",RED if field_army_feedback_override_error else Color("#8fc58d"))
	feedback.text=field_army_feedback_override
	_refresh()


func _open_war_history()->void:
	history_records=CivilizationSystem.war_history_snapshot(true)
	history_page=0
	_refresh_war_history_page()
	history_dialog.popup_centered(Vector2i(880,600))


func _change_war_history_page(delta:int)->void:
	var max_page:=maxi(0,ceili(float(history_records.size())/float(WAR_HISTORY_PAGE_SIZE))-1)
	history_page=clampi(history_page+delta,0,max_page)
	_refresh_war_history_page()


func _refresh_war_history_page()->void:
	var records:Array=history_records
	var max_page:=maxi(0,ceili(float(records.size())/float(WAR_HISTORY_PAGE_SIZE))-1)
	history_page=clampi(history_page,0,max_page)
	if history_page_label:
		history_page_label.text="KNOWN WAR RECORDS  •  PAGE %d/%d  •  %d TOTAL" % [history_page+1,max_page+1,records.size()]
	if history_previous_button: history_previous_button.disabled=history_page<=0
	if history_next_button: history_next_button.disabled=history_page>=max_page
	var lines:Array[String]=["[font_size=22][color=#d5ad58]WARS AND THEIR COST[/color][/font_size]","Every number below is an aggregate account tied to actual military strength or population. Unknown foreign wars remain absent until their belligerents are known.\n"]
	if records.is_empty():
		lines.append("[color=#9ca9b8]No known war has yet entered the record.[/color]")
	else:
		var start:=history_page*WAR_HISTORY_PAGE_SIZE
		var finish:=mini(records.size(),start+WAR_HISTORY_PAGE_SIZE)
		for record_index in range(start,finish):
			var record_variant=records[record_index]
			var record:Dictionary=record_variant
			lines.append("[font_size=18][color=#e8dfc6]%s[/color][/font_size]" % String(record.get("name","Unnamed war")))
			var end_text:="PRESENT" if String(record.get("status","active"))=="active" else "DAY %d" % int(record.get("ended_day",0))
			lines.append("DAY %d — %s  •  %s  •  %s" % [int(record.get("started_day",0)),end_text,String(record.get("war_goal","limited")).replace("_"," ").to_upper(),String(record.get("result","ongoing")).to_upper()])
			var casualties:Dictionary=record.get("casualties",{})
			var names:Dictionary=record.get("participant_names",{})
			for participant_id in (record.get("participants",[]) as Array):
				var account:Dictionary=casualties.get(String(participant_id),{})
				lines.append("  %s — military dead %s  •  civilian dead %s  •  wounded %s  •  captured %s  •  displaced %s" % [String(names.get(String(participant_id),participant_id)),_compact_count(int(account.get("military_dead",0))),_compact_count(int(account.get("civilian_dead",0))),_compact_count(int(account.get("wounded",0))),_compact_count(int(account.get("captured",0))),_compact_count(int(account.get("displaced",0)))])
			var battles:Array=record.get("battles",[])
			if not battles.is_empty():
				lines.append("  Battles: %d  •  Latest: %s (day %d)  •  %d recent engagement records retained" % [int(record.get("battle_count",battles.size())),String((battles[-1] as Dictionary).get("name","campaign")),int((battles[-1] as Dictionary).get("day",0)),battles.size()])
			lines.append("")
	history_text.text="\n".join(lines)
