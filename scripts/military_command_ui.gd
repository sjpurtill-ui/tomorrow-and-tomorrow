extends Node

const PANEL_SIZE:=Vector2(1160,640)
const INK:=Color("#e8dfc6")
const MUTED:=Color("#9ca9b8")
const GOLD:=Color("#d5ad58")
const RED:=Color("#dc806f")
const BLUE:=Color("#75acd9")

var layer:CanvasLayer
var modal:PanelContainer
var summary:Label
var condition:ProgressBar
var formations:Label
var queues:Label
var inventory:Label
var feedback:Label
var recruit_count:SpinBox
var train_count:SpinBox
var unit_choice:OptionButton
var weapon_choice:OptionButton
var produce_count:SpinBox
var equipment_choice:OptionButton
var refresh_accumulator:=0.0


func _ready()->void:
	_build_interface()
	MilitaryCampaign.army_changed.connect(func(_army:Dictionary): _refresh())
	set_process(true)


func _process(delta:float)->void:
	refresh_accumulator+=delta
	if modal.visible and refresh_accumulator>=0.5:
		refresh_accumulator=0.0
		_refresh()


func _unhandled_key_input(event:InputEvent)->void:
	if event.pressed and not event.echo and event.keycode==KEY_F6:
		_toggle()
		get_viewport().set_input_as_handled()


func _build_interface()->void:
	layer=CanvasLayer.new()
	layer.layer=90
	add_child(layer)
	var open_button:=Button.new()
	open_button.text="⚔  MILITARY"
	open_button.tooltip_text="Open military command (F6)"
	open_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	open_button.position=Vector2(-150,14)
	open_button.size=Vector2(136,38)
	open_button.pressed.connect(_toggle)
	layer.add_child(open_button)

	modal=PanelContainer.new()
	modal.name="MilitaryCommandModal"
	modal.set_anchors_preset(Control.PRESET_CENTER)
	modal.position=-PANEL_SIZE*0.5
	modal.size=PANEL_SIZE
	modal.visible=false
	modal.add_theme_stylebox_override("panel",_panel_style(Color("#182029"),GOLD,2,12))
	layer.add_child(modal)

	var outer:=VBoxContainer.new()
	outer.add_theme_constant_override("separation",10)
	modal.add_child(outer)
	var title_row:=HBoxContainer.new(); outer.add_child(title_row)
	var title:=Label.new(); title.text="MILITARY COMMAND"; title.add_theme_font_size_override("font_size",24); title.add_theme_color_override("font_color",GOLD); title_row.add_child(title)
	var spacer:=Control.new(); spacer.size_flags_horizontal=Control.SIZE_EXPAND_FILL; title_row.add_child(spacer)
	var close:=Button.new(); close.text="✕"; close.pressed.connect(func(): modal.hide()); title_row.add_child(close)
	summary=Label.new(); summary.add_theme_font_size_override("font_size",17); outer.add_child(summary)
	condition=ProgressBar.new(); condition.custom_minimum_size.y=22; condition.show_percentage=true; outer.add_child(condition)

	var columns:=HBoxContainer.new(); columns.size_flags_vertical=Control.SIZE_EXPAND_FILL; columns.add_theme_constant_override("separation",10); outer.add_child(columns)
	var army_box:=_section(columns,"ARMY",RED)
	formations=_body_label(army_box)
	var recruit_row:=HBoxContainer.new(); army_box.add_child(recruit_row)
	recruit_count=_counter(recruit_row,1,100,10)
	_action_button(recruit_row,"Raise recruits",_raise_recruits)
	var stand_row:=HBoxContainer.new(); army_box.add_child(stand_row)
	_action_button(stand_row,"Stand down 5",func(): _report(MilitaryCampaign.stand_down(5)))

	var training_box:=_section(columns,"TRAINING",GOLD)
	queues=_body_label(training_box)
	unit_choice=OptionButton.new(); training_box.add_child(unit_choice)
	weapon_choice=OptionButton.new(); training_box.add_child(weapon_choice)
	var train_row:=HBoxContainer.new(); training_box.add_child(train_row)
	train_count=_counter(train_row,1,100,10)
	_action_button(train_row,"Begin training",_start_training)

	var supply_box:=_section(columns,"ARSENAL & SUPPLY",BLUE)
	inventory=_body_label(supply_box)
	equipment_choice=OptionButton.new(); supply_box.add_child(equipment_choice)
	var production_row:=HBoxContainer.new(); supply_box.add_child(production_row)
	produce_count=_counter(production_row,1,100,10)
	_action_button(production_row,"Queue production",_queue_production)

	feedback=Label.new(); feedback.text="F6 closes this panel. Time continues while it is open."; feedback.custom_minimum_size.x=800; feedback.add_theme_color_override("font_color",MUTED); feedback.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; outer.add_child(feedback)
	_populate_choices()
	_refresh()


func _section(parent:HBoxContainer,title_text:String,color:Color)->VBoxContainer:
	var panel:=PanelContainer.new(); panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL; panel.add_theme_stylebox_override("panel",_panel_style(Color("#202a35"),color,1,8)); parent.add_child(panel)
	var box:=VBoxContainer.new(); box.add_theme_constant_override("separation",7); panel.add_child(box)
	var heading:=Label.new(); heading.text=title_text; heading.add_theme_font_size_override("font_size",18); heading.add_theme_color_override("font_color",color); box.add_child(heading)
	return box


func _body_label(parent:VBoxContainer)->Label:
	var label:=Label.new(); label.custom_minimum_size.x=200; label.size_flags_vertical=Control.SIZE_EXPAND_FILL; label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; label.add_theme_color_override("font_color",INK); parent.add_child(label); return label


func _counter(parent:HBoxContainer,minimum:int,maximum:int,value:int)->SpinBox:
	var spin:=SpinBox.new(); spin.min_value=minimum; spin.max_value=maximum; spin.value=value; spin.custom_minimum_size.x=82; parent.add_child(spin); return spin


func _action_button(parent:HBoxContainer,text_value:String,action:Callable)->void:
	var button:=Button.new(); button.text=text_value; button.size_flags_horizontal=Control.SIZE_EXPAND_FILL; button.pressed.connect(action); parent.add_child(button)


func _panel_style(color:Color,border:Color,width:int,radius:int)->StyleBoxFlat:
	var style:=StyleBoxFlat.new(); style.bg_color=color; style.border_color=border
	style.set_border_width_all(width); style.set_corner_radius_all(radius); style.content_margin_left=16; style.content_margin_right=16; style.content_margin_top=12; style.content_margin_bottom=12
	return style


func _toggle()->void:
	modal.visible=not modal.visible
	if modal.visible:
		_populate_choices()
		_refresh()


func _populate_choices()->void:
	unit_choice.clear(); weapon_choice.clear(); equipment_choice.clear()
	var capabilities:Dictionary=MilitaryCampaign.military_capabilities()
	for unit in (capabilities.get("units",{}) as Dictionary):
		_add_choice(unit_choice,String(unit),capabilities.units[unit])
	for item in (capabilities.get("equipment",{}) as Dictionary):
		_add_choice(weapon_choice,String(item),capabilities.equipment[item])
		_add_choice(equipment_choice,String(item),capabilities.equipment[item])
	var consumables:Dictionary={"arrows":{"unlocked":MilitaryCampaign._adoption("bow_craft")>=0.08,"reason":"Requires Bow Craft adoption."},"artillery_rounds":{"unlocked":MilitaryCampaign._adoption("powder_artillery")>=0.08,"reason":"Requires Powder Artillery adoption."},"transport_cart":capabilities.transport_carts}
	for item in consumables: _add_choice(equipment_choice,String(item),consumables[item])


func _add_choice(choice:OptionButton,id:String,gate:Dictionary)->void:
	var unlocked:=bool(gate.get("unlocked",false))
	choice.add_item(("✓ " if unlocked else "🔒 ")+id.replace("_"," ").capitalize())
	var index:=choice.item_count-1; choice.set_item_metadata(index,id); choice.set_item_disabled(index,not unlocked); choice.set_item_tooltip(index,String(gate.get("reason","Available")))


func _refresh()->void:
	var army:Dictionary=MilitaryCampaign.campaign_army_snapshot()
	var capabilities:Dictionary=MilitaryCampaign.military_capabilities()
	var troops:=int(army.get("troops",0)); var ready:=float(army.get("readiness",0.0)); var capacity:=int(capabilities.get("recruitment_capacity",0))
	summary.text="DAY %d     %d FIELD SOLDIERS     %d RECRUITS     %d / %d MOBILIZED" % [int(GameState.elapsed_days),troops,int(army.get("recruits",0)),MilitaryCampaign._mobilized_count(),capacity]
	condition.value=ready*100.0
	condition.tooltip_text="Aggregate readiness: personnel condition, training, equipment, ammunition, supply, morale, and leadership."
	var formation_lines:Array[String]=[]
	for formation in (army.get("formations",[]) as Array):
		formation_lines.append("%s  %d/%d men\n  %s %d/%d  •  readiness %d%%" % [String(formation.get("unit","unit")).replace("_"," ").capitalize(),int(formation.get("count",0)),int(formation.get("authorized_count",formation.get("count",0))),String(formation.get("weapon","gear")).replace("_"," "),int(formation.get("equipment",0)),int(formation.get("equipment_required",formation.get("count",0))),roundi(float(formation.get("readiness",ready))*100.0)])
	formations.text="No field formations. Raise citizens, then train them." if formation_lines.is_empty() else "\n\n".join(formation_lines)
	queues.text="Training rate %.1f/day  •  capacity %d\nWorkshop %.0f%% utilized\n\n%s" % [float(capabilities.get("training_rate",0.0)),int(capabilities.get("training_capacity",0)),float(capabilities.get("workshop_utilization",0.0))*100.0,_queue_summary(army)]
	inventory.text=_inventory_summary(army)+"\n\nLogistics practice %d%%\nField supply access %d%%" % [roundi(float(capabilities.get("logistics_practice",0.0))*100.0),roundi(MilitaryCampaign.field_provision_delivery_ratio()*100.0)]


func _queue_summary(army:Dictionary)->String:
	var lines:Array[String]=[]
	for order in (army.get("training_queue",[]) as Array): lines.append("TRAIN  %d %s  %d/%d days" % [int(order.get("count",0)),String(order.get("unit","unit")).replace("_"," "),roundi(float(order.get("progress_days",0.0))),roundi(float(order.get("required_days",1.0)))])
	for job in (army.get("equipment_queue",[]) as Array): lines.append("MAKE   %d %s  %d%%" % [int(job.get("count",0)),String(job.get("item","item")).replace("_"," "),roundi(100.0*float(job.get("progress_days",0.0))/maxf(0.01,float(job.get("required_days",1.0))))])
	return "No active training or production." if lines.is_empty() else "\n".join(lines.slice(0,6))


func _inventory_summary(army:Dictionary)->String:
	var lines:Array[String]=[]
	for item in (army.get("military_inventory",{}) as Dictionary):
		var amount:=int(army.military_inventory[item]); var damaged:=int((army.get("damaged_equipment",{}) as Dictionary).get(item,0))
		if amount>0 or damaged>0: lines.append("%s  %d ready%s" % [String(item).replace("_"," ").capitalize(),amount,"  •  %d damaged" % damaged if damaged>0 else ""])
	for item in (army.get("military_consumables",{}) as Dictionary):
		var amount:=int(army.military_consumables[item]); if amount>0: lines.append("%s  %d" % [String(item).replace("_"," ").capitalize(),amount])
	lines.append("Transport carts  %d" % int(GameState.resource_stockpiles.get("Transport Carts",0)))
	return "\n".join(lines)


func _raise_recruits()->void: _report(MilitaryCampaign.raise_recruits(int(recruit_count.value)))


func _start_training()->void:
	if unit_choice.selected<0 or weapon_choice.selected<0: return
	_report(MilitaryCampaign.start_training(String(unit_choice.get_item_metadata(unit_choice.selected)),String(weapon_choice.get_item_metadata(weapon_choice.selected)),int(train_count.value)))


func _queue_production()->void:
	if equipment_choice.selected<0: return
	var item:=String(equipment_choice.get_item_metadata(equipment_choice.selected)); var count:=int(produce_count.value); var result:Dictionary
	if item=="transport_cart": result=MilitaryCampaign.queue_transport_cart_production(count)
	elif item in ["arrows","artillery_rounds"]: result=MilitaryCampaign.queue_consumable_production(item,count)
	else: result=MilitaryCampaign.queue_equipment_production(item,count)
	_report(result)


func _report(result:Dictionary)->void:
	feedback.text=String(result.get("error",JSON.stringify(result)))
	feedback.add_theme_color_override("font_color",RED if result.has("error") else Color("#8fc58d"))
	_refresh()
