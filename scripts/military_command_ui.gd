extends Node

const PANEL_SIZE:=Vector2(1160,640)
const COMMANDER_PORTRAITS:=preload("res://assets/ui/commander_portraits.png")
const INK:=Color("#e8dfc6")
const MUTED:=Color("#9ca9b8")
const GOLD:=Color("#d5ad58")
const RED:=Color("#dc806f")
const BLUE:=Color("#75acd9")

var layer:CanvasLayer
var modal:PanelContainer
var summary:Label
var condition:ProgressBar
var readiness_meters:Dictionary={}
var readiness_bottleneck:Label
var formations:Label
var commander_portrait:TextureRect
var commander_details:Label
var queues:Label
var inventory:Label
var feedback:Label
var recruit_count:SpinBox
var train_count:SpinBox
var unit_choice:OptionButton
var weapon_choice:OptionButton
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
	outer.add_theme_constant_override("separation",7)
	modal.add_child(outer)
	var title_row:=HBoxContainer.new(); outer.add_child(title_row)
	var title:=Label.new(); title.text="MILITARY COMMAND"; title.add_theme_font_size_override("font_size",24); title.add_theme_color_override("font_color",GOLD); title_row.add_child(title)
	var spacer:=Control.new(); spacer.size_flags_horizontal=Control.SIZE_EXPAND_FILL; title_row.add_child(spacer)
	var close:=Button.new(); close.text="✕"; close.pressed.connect(func(): modal.hide()); title_row.add_child(close)
	summary=Label.new(); summary.add_theme_font_size_override("font_size",17); outer.add_child(summary)
	condition=ProgressBar.new(); condition.custom_minimum_size.y=22; condition.show_percentage=true; outer.add_child(condition)
	var readiness_strip:=HBoxContainer.new(); readiness_strip.add_theme_constant_override("separation",6); outer.add_child(readiness_strip)
	for entry in [["manpower","MEN",RED],["equipment","EQ",GOLD],["ammunition","AMMO",Color("#b98ccb")],["condition","COND",Color("#83b77b")],["organization","ORG",BLUE],["supply","SUP",Color("#74b9ae")]]:
		_add_readiness_meter(readiness_strip,String(entry[0]),String(entry[1]),entry[2])
	readiness_bottleneck=Label.new(); readiness_bottleneck.custom_minimum_size.x=126; readiness_bottleneck.vertical_alignment=VERTICAL_ALIGNMENT_CENTER; readiness_bottleneck.add_theme_color_override("font_color",MUTED); readiness_strip.add_child(readiness_bottleneck)

	var columns:=HBoxContainer.new(); columns.size_flags_vertical=Control.SIZE_EXPAND_FILL; columns.add_theme_constant_override("separation",10); outer.add_child(columns)
	var army_box:=_section(columns,"ARMY",RED)
	var commander_row:=HBoxContainer.new(); commander_row.add_theme_constant_override("separation",8); army_box.add_child(commander_row)
	commander_portrait=TextureRect.new(); commander_portrait.custom_minimum_size=Vector2(54,54); commander_portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; commander_portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED; commander_row.add_child(commander_portrait)
	commander_details=Label.new(); commander_details.size_flags_horizontal=Control.SIZE_EXPAND_FILL; commander_details.vertical_alignment=VERTICAL_ALIGNMENT_CENTER; commander_row.add_child(commander_details)
	formations=_body_label(army_box); formations.add_theme_font_size_override("font_size",14)
	var recruit_row:=HBoxContainer.new(); army_box.add_child(recruit_row)
	recruit_count=_counter(recruit_row,1,100,10)
	_action_button(recruit_row,"Raise recruits",_raise_recruits)
	var stand_row:=HBoxContainer.new(); army_box.add_child(stand_row)
	_action_button(stand_row,"Reinforce weakest",_reinforce_weakest)
	_action_button(stand_row,"Demobilize 5",func(): _report(MilitaryCampaign.demobilize(5)))

	var training_box:=_section(columns,"TRAINING",GOLD)
	queues=_body_label(training_box)
	unit_choice=OptionButton.new(); training_box.add_child(unit_choice); unit_choice.item_selected.connect(func(_index:int): _populate_training_weapons())
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
	_action_button(production_row,"Repair",_queue_repair)

	threat_row=HBoxContainer.new(); threat_row.add_theme_constant_override("separation",8); outer.add_child(threat_row)
	threat_label=Label.new(); threat_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL; threat_label.add_theme_color_override("font_color",RED); threat_row.add_child(threat_label)
	_action_button(threat_row,"Defend",func(): _report(MilitaryCampaign.respond_to_threat("defend")))
	_action_button(threat_row,"Pay tribute",func(): _report(MilitaryCampaign.respond_to_threat("tribute")))
	_action_button(threat_row,"Withdraw",func(): _report(MilitaryCampaign.respond_to_threat("withdraw")))
	engagement_row=HBoxContainer.new(); engagement_row.add_theme_constant_override("separation",8); outer.add_child(engagement_row)
	engagement_label=Label.new(); engagement_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL; engagement_label.add_theme_color_override("font_color",GOLD); engagement_row.add_child(engagement_label)
	_action_button(engagement_row,"Next round",func(): _report(MilitaryCampaign.advance_engagement("hold")))
	_action_button(engagement_row,"⚔ Push harder",func(): _report(MilitaryCampaign.advance_engagement("push")))
	_action_button(engagement_row,"◀ Retreat",func(): _report(MilitaryCampaign.advance_engagement("retreat")))

	aftermath_row=HBoxContainer.new(); aftermath_row.add_theme_constant_override("separation",8); outer.add_child(aftermath_row)
	aftermath_label=Label.new(); aftermath_label.text="BATTLE DECISION"; aftermath_label.add_theme_color_override("font_color",GOLD); aftermath_row.add_child(aftermath_label)
	prisoner_policy=_policy_choice(aftermath_row,["hold","release","exchange","parole","ransom","execute","enslave"],"Prisoners")
	spoils_policy=_policy_choice(aftermath_row,["army stores","reward troops","state treasury","return property","unrestricted plunder"],"Spoils")
	general_policy=_policy_choice(aftermath_row,["hold","release","ransom","execute"],"Enemy general")
	_action_button(aftermath_row,"Resolve decision",_resolve_aftermath_or_captives)

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


func _action_button(parent:HBoxContainer,text_value:String,action:Callable)->void:
	var button:=Button.new(); button.text=text_value; button.size_flags_horizontal=Control.SIZE_EXPAND_FILL; button.pressed.connect(action); parent.add_child(button)


func _panel_style(color:Color,border:Color,width:int,radius:int)->StyleBoxFlat:
	var style:=StyleBoxFlat.new(); style.bg_color=color; style.border_color=border
	style.set_border_width_all(width); style.set_corner_radius_all(radius); style.content_margin_left=16; style.content_margin_right=16; style.content_margin_top=8; style.content_margin_bottom=8
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
	_populate_training_weapons()
	for item in (capabilities.get("equipment",{}) as Dictionary):
		_add_choice(equipment_choice,String(item),capabilities.equipment[item])
	var consumables:Dictionary={"arrows":{"unlocked":MilitaryCampaign._adoption("bow_craft")>=0.08,"reason":"Requires Bow Craft adoption."},"artillery_rounds":{"unlocked":MilitaryCampaign._adoption("powder_artillery")>=0.08,"reason":"Requires Powder Artillery adoption."},"transport_cart":capabilities.transport_carts}
	for item in consumables: _add_choice(equipment_choice,String(item),consumables[item])


func _populate_training_weapons()->void:
	if weapon_choice==null: return
	weapon_choice.clear()
	if unit_choice.selected<0: return
	var unit:=String(unit_choice.get_item_metadata(unit_choice.selected))
	var capabilities:Dictionary=MilitaryCampaign.military_capabilities()
	for item in (capabilities.get("unit_equipment",{}) as Dictionary).get(unit,[]):
		_add_choice(weapon_choice,String(item),(capabilities.get("equipment",{}) as Dictionary).get(item,{"unlocked":false,"reason":"Equipment definition missing."}))


func _add_choice(choice:OptionButton,id:String,gate:Dictionary)->void:
	var unlocked:=bool(gate.get("unlocked",false))
	choice.add_item(("✓ " if unlocked else "🔒 ")+id.replace("_"," ").capitalize())
	var index:=choice.item_count-1; choice.set_item_metadata(index,id); choice.set_item_disabled(index,not unlocked); choice.set_item_tooltip(index,String(gate.get("reason","Available")))


func _refresh()->void:
	var army:Dictionary=MilitaryCampaign.campaign_army_snapshot()
	var capabilities:Dictionary=MilitaryCampaign.military_capabilities()
	var engagement:Dictionary=MilitaryCampaign.engagement_snapshot()
	var threat:Dictionary=MilitaryCampaign.threat_snapshot()
	var display_force:Dictionary=(engagement.get("attacker",{}) as Dictionary) if not engagement.is_empty() else army
	var display_opponent:Dictionary=(engagement.get("defender",{}) as Dictionary) if not engagement.is_empty() else ((threat.get("enemy_force",{}) as Dictionary) if not threat.is_empty() else {})
	var combat:Dictionary=MilitaryCampaign.combat_summary(display_force,display_opponent,1.0)
	var troops:=int(army.get("troops",0)); var ready:=float(combat.get("readiness",army.get("readiness",0.0))); var capacity:=int(capabilities.get("recruitment_capacity",0))
	if display_opponent.is_empty():
		summary.text="DAY %d     %d FIELD SOLDIERS     ⚔ %.1f ATTACK     🛡 %.1f DEFENSE     %d / %d MOBILIZED" % [int(GameState.elapsed_days),int(combat.get("troops",troops)),float(combat.get("attack_strength",0.0)),float(combat.get("defense_strength",0.0)),MilitaryCampaign._mobilized_count(),capacity]
		condition.value=ready*100.0
		condition.tooltip_text="Aggregate readiness: personnel condition, training, equipment, ammunition, supply, morale, and leadership."
	else:
		var opponent_combat:Dictionary=MilitaryCampaign.combat_summary(display_opponent,display_force,MilitaryCampaign._terrain_defense())
		var own_strength:=maxf(0.0,float(combat.get("effective_strength",0.0)))
		var enemy_strength:=maxf(0.0,float(opponent_combat.get("effective_strength",0.0)))
		var relative_share:=own_strength/maxf(0.001,own_strength+enemy_strength)
		summary.text="DAY %d   ⚔ %.1f  🛡 %.1f     %s %d%%  —  RELATIVE STRENGTH  —  %d%% %s" % [int(GameState.elapsed_days),float(combat.get("attack_strength",0.0)),float(combat.get("defense_strength",0.0)),String(display_force.get("name","Our host")).to_upper(),roundi(relative_share*100.0),roundi((1.0-relative_share)*100.0),String(display_opponent.get("name","Enemy")).to_upper()]
		condition.value=relative_share*100.0
		condition.tooltip_text="Relative effective strength after cohort matchups, terrain, equipment, condition, readiness, and leadership."
	var readiness_components:Dictionary=combat.get("readiness_components",{})
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
		formation_lines.append("%s  %d/%d men  •  %s %d/%d\n  ⚔ %.1f   🛡 %.1f   RDY %d%%   COND %d%%" % [String(formation.get("unit","unit")).replace("_"," ").capitalize(),int(formation.get("count",0)),int(formation.get("authorized_count",formation.get("count",0))),String(formation.get("weapon","gear")).replace("_"," "),int(formation.get("equipment",0)),int(formation.get("equipment_required",formation.get("count",0))),float(formation_stats.get("attack_strength",0.0)),float(formation_stats.get("defense_strength",0.0)),roundi(float(formation_stats.get("readiness",ready))*100.0),roundi(float(formation_stats.get("condition",1.0))*100.0)])
	if formation_cards.size()>3: formation_lines.append("+ %d more cohorts in the field" % (formation_cards.size()-3))
	var custody_line:="\n\nCAPTIVES  %d soldiers  •  %d generals" % [int(army.get("foreign_prisoners",0)),(army.get("held_generals",[]) as Array).size()]
	formations.text=("No field formations. Raise citizens, then train them." if formation_lines.is_empty() else "\n".join(formation_lines))+custody_line
	var commander:Dictionary=combat.get("commander",{})
	var portrait_index:=posmod(hash(String(commander.get("name","commander"))),6)
	commander_portrait.texture=_commander_portrait(portrait_index)
	commander_details.text="%s%s\nCMD %d   TAC %d   LOG %d   RES %d" % [String(commander.get("name","No field commander")),"  •  ACTING" if bool(commander.get("acting",false)) else "",roundi(float(commander.get("command",0.0))*100.0),roundi(float(commander.get("tactics",0.0))*100.0),roundi(float(commander.get("logistics",0.0))*100.0),roundi(float(commander.get("resolve",0.0))*100.0)]
	queues.text="Training rate %.1f/day  •  capacity %d\nWorkshop %.0f%% utilized\n\n%s" % [float(capabilities.get("training_rate",0.0)),int(capabilities.get("training_capacity",0)),float(capabilities.get("workshop_utilization",0.0))*100.0,_queue_summary(army)]
	var burden:Dictionary=army.get("economic_burden",{})
	var reputation:Dictionary=MilitaryCampaign.war_reputation_snapshot()
	inventory.text=_inventory_summary(army)+"\n\nLogistics %d%%  •  Field supply %d%%\nLabor withheld %d  •  Workshop diversion %d%%\nUpkeep %.2f/day  •  Reputation M%d F%d G%d" % [roundi(float(capabilities.get("logistics_practice",0.0))*100.0),roundi(MilitaryCampaign.field_provision_delivery_ratio()*100.0),int(burden.get("mobilized_citizens",0)),roundi(float(burden.get("workshop_diversion",0.0))*100.0),float(burden.get("currency_upkeep_units",0.0)),roundi(float(reputation.get("mercy",0.0))*100.0),roundi(float(reputation.get("fear",0.0))*100.0),roundi(float(reputation.get("grievance",0.0))*100.0)]
	var has_pending_aftermath:=not MilitaryCampaign.pending_aftermath.is_empty()
	var has_held_captives:=int(army.get("foreign_prisoners",0))>0 or not (army.get("held_generals",[]) as Array).is_empty()
	var can_manage_held_captives:=has_held_captives and threat.is_empty() and engagement.is_empty()
	aftermath_row.visible=has_pending_aftermath or can_manage_held_captives
	aftermath_label.text="BATTLE DECISION" if has_pending_aftermath else "HELD CAPTIVES"
	spoils_policy.visible=has_pending_aftermath
	threat_row.visible=not threat.is_empty()
	if not threat.is_empty(): threat_label.text="⚠  %s — about %d fighters — decision due day %d" % [String(threat.get("title","Threat approaching")),int(threat.get("estimated_strength",0)),int(threat.get("deadline_day",0))]
	engagement_row.visible=not engagement.is_empty()
	if not engagement.is_empty():
		var attacker:Dictionary=engagement.get("attacker",{}); var defender:Dictionary=engagement.get("defender",{})
		engagement_label.text="ROUND %02d   %s %d  —  %d %s   Last: %s" % [int(engagement.get("round",0))+1,String(attacker.get("name","Army")),int(attacker.get("troops",0)),int(defender.get("troops",0)),String(defender.get("name","Enemy")),String(engagement.get("last_order","ready")).capitalize()]
	modal.size=PANEL_SIZE
	modal.position=-PANEL_SIZE*0.5


func _commander_portrait(index:int)->AtlasTexture:
	var texture:=AtlasTexture.new(); texture.atlas=COMMANDER_PORTRAITS; texture.region=Rect2((index%3)*512,(index/3)*512,512,512); return texture


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


func _queue_production()->void:
	if equipment_choice.selected<0: return
	var item:=String(equipment_choice.get_item_metadata(equipment_choice.selected)); var count:=int(produce_count.value); var result:Dictionary
	if item=="transport_cart": result=MilitaryCampaign.queue_transport_cart_production(count)
	elif item in ["arrows","artillery_rounds"]: result=MilitaryCampaign.queue_consumable_production(item,count)
	else: result=MilitaryCampaign.queue_equipment_production(item,count)
	_report(result)


func _queue_repair()->void:
	if equipment_choice.selected<0: return
	var item:=String(equipment_choice.get_item_metadata(equipment_choice.selected))
	if item in ["transport_cart","arrows","artillery_rounds"]:
		_report({"error":"%s is replaced through production, not equipment repair." % item.replace("_"," ").capitalize()})
		return
	_report(MilitaryCampaign.queue_equipment_repair(item,int(produce_count.value)))


func _resolve_aftermath_or_captives()->void:
	var selected_prisoner_policy:=String(prisoner_policy.get_item_metadata(prisoner_policy.selected))
	var selected_general_policy:=String(general_policy.get_item_metadata(general_policy.selected))
	if not MilitaryCampaign.pending_aftermath.is_empty():
		_report(MilitaryCampaign.resolve_aftermath(selected_prisoner_policy,String(spoils_policy.get_item_metadata(spoils_policy.selected)),selected_general_policy))
	else:
		_report(MilitaryCampaign.resolve_held_captives(selected_prisoner_policy,selected_general_policy))


func _report(result:Dictionary)->void:
	feedback.text=String(result.get("error",result.get("message","Orders accepted; campaign state updated.")))
	feedback.add_theme_color_override("font_color",RED if result.has("error") else Color("#8fc58d"))
	_refresh()
