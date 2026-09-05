extends CanvasLayer
var tabs:TabContainer
var summary:Label
var feedback:Label
var survivors:Label
var occupied:Label
var people:SpinBox
var days:SpinBox
var heading:OptionButton
var city_choice:OptionButton
var poll:float=0
var city_signature:String=""
static func open()->void:
	var root:Node=Engine.get_main_loop().root
	if root.has_meta("recovery_view") and is_instance_valid(root.get_meta("recovery_view")):return
	var view=load("res://scripts/hud/recovery_screen.gd").new();root.set_meta("recovery_view",view);root.add_child.call_deferred(view)
func _ready()->void:
	layer=79
	var bg:=ColorRect.new();bg.color=Color("142029");bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(bg)
	var margin:=MarginContainer.new();margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+side,16)
	bg.add_child(margin);var column:=VBoxContainer.new();column.add_theme_constant_override("separation",12);margin.add_child(column)
	var top:=HBoxContainer.new();column.add_child(top)
	var title:=Label.new();title.text="SURVIVAL & INDEPENDENCE";title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;top.add_child(title)
	_button(top,"RETURN",queue_free)
	summary=_label(column,"")
	tabs=TabContainer.new();tabs.size_flags_vertical=Control.SIZE_EXPAND_FILL;column.add_child(tabs)
	var preparation:=VBoxContainer.new();preparation.name="Escape preparation";tabs.add_child(preparation)
	_label(preparation,"Set aside residents, food and shelter materials while under siege. This reduces work supporting the defenses. Preparation improves the chance of escape, but the group consumes its reserved food every day. Success is uncertain.")
	var choices:=HBoxContainer.new();preparation.add_child(choices)
	_label(choices,"Residents");people=SpinBox.new();people.min_value=2;people.max_value=1000000000;people.value=20;choices.add_child(people)
	_label(choices,"Days of rations");days=SpinBox.new();days.min_value=7;days.max_value=90;days.value=45;choices.add_child(days)
	_button(choices,"PREPARE GROUP",_prepare)
	var travel:=HBoxContainer.new();preparation.add_child(travel)
	heading=OptionButton.new();for direction:String in CivilizationSystem.SCOUT_HEADINGS:heading.add_item(direction.capitalize())
	travel.add_child(heading);_button(travel,"ATTEMPT ESCAPE",_escape);_button(travel,"CANCEL PREPARATION",_cancel)
	var remnant:=VBoxContainer.new();remnant.name="Survivors";tabs.add_child(remnant)
	survivors=_label(remnant,"")
	_label(remnant,"Choose a heading in Escape preparation, then seek a site 32 km farther in that direction. Travel consumes finite supplies. Rebuilding requires fresh water, habitable land and room outside occupied or patrolled territory; a new settlement does not restore lost buildings or stores.")
	_button(remnant,"SEEK REBUILDING SITE",_seek)
	var resistance:=VBoxContainer.new();resistance.name="Occupied cities";tabs.add_child(resistance)
	city_choice=OptionButton.new();city_choice.item_selected.connect(func(_i:int):_refresh());resistance.add_child(city_choice)
	occupied=_label(resistance,"")
	var orders:=GridContainer.new();orders.columns=2;resistance.add_child(orders)
	for order:String in MilitaryCampaign.recovery.ORDERS:_button(orders,MilitaryCampaign.recovery.ORDERS[order],_resistance.bind(order))
	feedback=_label(column,"")
	_refresh()
func _label(parent:Node,text:String)->Label:
	var label:=Label.new();label.text=text;label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;parent.add_child(label);return label
func _button(parent:Node,text:String,action:Callable)->Button:
	var button:=Button.new();button.text=text;button.pressed.connect(action);parent.add_child(button);return button
func _unhandled_input(event:InputEvent)->void:
	if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:queue_free();get_viewport().set_input_as_handled()
func _process(delta:float)->void:
	poll+=delta
	if poll>=.5:poll=0;_refresh()
func _refresh()->void:
	var data:Dictionary=MilitaryCampaign.recovery.snapshot()
	var prepared:Dictionary=data.preparation
	var group:Dictionary=data.remnant
	summary.text="Your people and history continue. Occupation and rebuilding are separate paths back; neither guarantees independence."
	if not prepared.is_empty():summary.text="PREPARED: %d residents • %.0f rations • %.1f Timber • defense support reduced by %d%%" % [int(prepared.people),float(prepared.food),float(prepared.timber),roundi((1-MilitaryCampaign.recovery.defense_factor())*100)]
	survivors.text="No escaped group is traveling." if group.is_empty() else "%d survivors • %s\n%.0f food rations • about %.1f days at current group size\n%.1f km traveled / %.1f km to this destination\nOrigin: %s. People retain their society's knowledge; equipment and buildings left behind remain behind." % [int(group.people),String(group.phase).replace("_"," "),float(group.food),float(group.food)/maxf(1,float(group.people)),float(group.get("traveled",0)),float(group.get("distance",0)),String(group.origin_name)]
	var ids:Array=[]
	for entry:Dictionary in data.occupied:ids.append(String(entry.city_id))
	var signature:=JSON.stringify(ids)
	if signature!=city_signature:
		city_signature=signature;city_choice.clear()
		for id:String in ids:city_choice.add_item(String(SettlementModel.settlement_record(id).get("name",id)))
	if city_choice.selected<0 or city_choice.selected>=data.occupied.size():occupied.text="No cities are under occupation.";return
	var entry:Dictionary=data.occupied[city_choice.selected]
	var gov:Dictionary=entry.region.governance
	occupied.text="%s • Report day %d\nIndependence support %d%% • Suspicion %d%% • Repression %d%%\nWelfare %d%% • Local institutions %d%%\nEach effort takes 30 days and local rations. Messages take time when your government is elsewhere. Failed independence attempts can cause losses and harsher repression." % ["Independence restored" if bool(entry.get("liberated",false)) else "Under occupation",int(entry.last_report_day),roundi(float(gov.support)*100),roundi(float(gov.suspicion)*100),roundi(float(gov.repression)*100),roundi(float(gov.welfare)*100),roundi(float(gov.local_institutions)*100)]
	if not entry.order.is_empty():occupied.text+="\nCurrent effort completes no earlier than day %d; a report may arrive later." % int(entry.order.resolve_day)
func _show(result:Dictionary)->void:feedback.text=String(result.get("error",result.get("message","Order recorded.")));_refresh()
func _prepare()->void:_show(MilitaryCampaign.recovery.prepare(int(people.value),int(days.value)))
func _direction()->String:return String(CivilizationSystem.SCOUT_HEADINGS.keys()[heading.selected])
func _escape()->void:_show(MilitaryCampaign.recovery.escape(_direction()))
func _cancel()->void:_show(MilitaryCampaign.recovery.cancel_preparation())
func _seek()->void:_show(MilitaryCampaign.recovery.seek_site(_direction()))
func _resistance(order:String)->void:
	var entries:Array=MilitaryCampaign.recovery.data.occupied
	if city_choice.selected<0 or city_choice.selected>=entries.size():return
	_show(MilitaryCampaign.recovery.queue_resistance(String(entries[city_choice.selected].city_id),order))
