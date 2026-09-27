extends CanvasLayer
const C=preload("res://scripts/joint_force_catalog.gd")
const Map=preload("res://scripts/hud/service_world_overlay.gd")
const T=preload("res://scripts/hud/hud_tokens.gd")
const P=preload("res://scripts/hud/paper_sheet.gd")
const EraWords=preload("res://scripts/hud/era_words.gd")
## Food a transport can carry: plain choices instead of a number field.
const FOOD_LOADS:=[[0.0,"No food"],[100.0,"Some food"],[500.0,"A full hold"]]
var op:RefCounted
var map:Control
var domain:String="navy"
var force_picker:OptionButton
var base_picker:OptionButton
var type_picker:OptionButton
var city_picker:OptionButton
var destination_picker:OptionButton
var army_picker:OptionButton
var mission_picker:OptionButton
var quantity:SpinBox
var food_amount:=0.0
var food_buttons:Array[Button]=[]
var status:Label
var region_label:Label
var recipe:Label
var feedback:Label
var reports:Label
var replacement:CheckBox
var tick:=0.0
var selected_id:=0
var displayed_force_id:=-1
var refresh_key:=""
var panel:PanelContainer

var terrain:Node
var area_name:LineEdit
var pages:TabContainer
var readiness_label:Label
var assign_button:Button
var commission_button:Button
var commission_status:Label
var base_status:Label
var mission_controls:VBoxContainer
var setup_button:Button

func _ready()->void:
	layer=82;op=MilitaryCampaign.joint_operations
	map=Map.new();map.terrain=terrain;map.domain=domain;add_child(map)
	map.region_selected.connect(_region)
	map.force_selected.connect(func(id:int):selected_id=id;_refresh_choices();_select_force(true))
	map.base_selected.connect(func(id:int):
		for i in base_picker.item_count:
			if int(base_picker.get_item_metadata(i))==id:base_picker.select(i)
		_refresh_status())
	map.order_region.connect(func(region:Dictionary):_region(region);_assign())
	map.boundary_feedback.connect(_report)
	panel=PanelContainer.new();add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	panel.offset_top=76;panel.offset_right=-16;panel.offset_left=-376
	panel.add_theme_stylebox_override("panel",P.sheet_style(14));panel.theme=T.control_theme()
	var root:=VBoxContainer.new();root.add_theme_constant_override("separation",8);panel.add_child(root)
	var heading:=_row(root);var titles:=VBoxContainer.new();titles.size_flags_horizontal=Control.SIZE_EXPAND_FILL;heading.add_child(titles)
	P.kicker(titles,"Our ships" if domain=="navy" else "Our flyers")
	P.label(titles,"The navy" if domain=="navy" else "The air service","title",T.INK)
	var close:=_button(heading,"Close",queue_free);close.size_flags_horizontal=Control.SIZE_SHRINK_END;close.custom_minimum_size.x=88;close.tooltip_text="Close (Esc)"
	var leader:=P.war_leader()
	var talk:=P.button(root,P.talk_label(leader,"Talk to our war leader"),func():queue_free();P.summon(leader.get("target",{})),true);talk.name="TalkLeader"
	talk.tooltip_text="Our commanders decide how the ships and flyers fight in each area. Tell them in court what you want."
	pages=TabContainer.new();pages.size_flags_vertical=Control.SIZE_EXPAND_FILL;root.add_child(pages)
	T.text(pages,"small",T.INK)
	pages.add_theme_stylebox_override("panel",T.flat(T.PAPER_RAISED,T.RULE,1,T.RADIUS_CARD,10))
	for state in ["tab_selected","tab_unselected","tab_hovered","tab_focus"]:
		var tab:=T.flat(T.PAPER_RAISED if state=="tab_selected" else T.PAPER if state!="tab_hovered" else T.HOVER_BG,T.RULE,1,2)
		tab.content_margin_left=12;tab.content_margin_right=12;tab.content_margin_top=6;tab.content_margin_bottom=6
		if state=="tab_selected":tab.border_color=T.GOLD;tab.border_width_top=2
		pages.add_theme_stylebox_override(state,tab)
	for color in ["font_selected_color","font_hovered_color","font_focus_color"]:pages.add_theme_color_override(color,T.INK)
	pages.add_theme_color_override("font_unselected_color",T.BODY)
	_build_service()
	_button(root,"All our forces",func():MilitaryCampaign.open_roster(domain,true))
	feedback=_label(root,"",13)
	_refresh_choices();_select_force()

func _page(title:String)->VBoxContainer:
	var scroll:=ScrollContainer.new();scroll.name=title;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;pages.add_child(scroll)
	var column:=VBoxContainer.new();column.size_flags_horizontal=Control.SIZE_EXPAND_FILL;column.add_theme_constant_override("separation",8);scroll.add_child(column);return column

func _build_service()->void:
	pass

func _force_summary(force:Dictionary)->String:
	return String(force.get("status",""))

func _region_tools(column:Node)->void:
	region_label=_label(column,"Pick an area on the map, or draw a new one.",14)
	area_name=LineEdit.new();area_name.placeholder_text="Sea area name" if domain=="navy" else "Air region name";column.add_child(area_name)
	var row:=_row(column)
	_button(row,"Draw an area (D)",func():map.begin_boundary();feedback.text="Click the corners of the area on the map. Enter finishes, Backspace takes back the last corner, Esc cancels.")
	_button(row,"Finish",func():map.finish_boundary(area_name.text))
	_button(row,"Cancel",func():map.cancel_boundary())
	_button(column,"Remove this area",func():
		var result:Dictionary=op.remove_region(String(map.selected.get("id","")))
		if not result.has("error"):map.selected={};region_label.text="Area removed."
		_report(result))

func _force_controls(column:Node,stand_down:String)->void:
	_button(column,"Who commands what",func():op.open_hierarchy(domain))
	force_picker=_option(column);force_picker.item_selected.connect(func(_index:int):selected_id=int(_selected(force_picker));_select_force(true))
	status=_label(column,"",14)
	setup_button=_button(column,"Go to ports" if domain=="navy" else "Go to airfields",func():pages.current_tab=1)
	mission_controls=VBoxContainer.new();mission_controls.add_theme_constant_override("separation",7);column.add_child(mission_controls)
	mission_picker=_option(mission_controls)
	assign_button=_button(mission_controls,"Send them to this area",_assign)
	readiness_label=_label(mission_controls,"",13)
	_button(mission_controls,stand_down,func():_report(op.assign(selected_id,{},"hold")))
	replacement=CheckBox.new();replacement.text="Replace losses from our stores";T.text(replacement,"small",T.INK);mission_controls.add_child(replacement)
	replacement.toggled.connect(func(value:bool):if selected_id>0:_report(op.configure(selected_id,value,.6)))
	_region_tools(column)

func _production_controls(column:Node,base_word:String,creation_word:String)->void:
	base_picker=_option(column)
	base_picker.item_selected.connect(func(_index:int):_refresh_status())
	base_status=_label(column,"",13)
	city_picker=_option(column)
	_button(column,"Build a "+base_word+" in this town",func():_report(op.build_base(String(_selected(city_picker)),domain)))
	type_picker=_option(column);type_picker.item_selected.connect(func(_index:int):_refresh_status())
	_label(column,"How many to build",13)
	quantity=SpinBox.new();quantity.min_value=1;quantity.max_value=100;quantity.value=1;column.add_child(quantity);quantity.value_changed.connect(func(_amount:float):_refresh_status())
	recipe=_label(column,"",13)
	_button(column,"Start building them",_produce)
	commission_button=_button(column,creation_word,_commission)
	commission_status=_label(column,"",13)

func _transport_controls(column:Node,description:String)->void:
	_label(column,description,13)
	destination_picker=_option(column);army_picker=_option(column)
	_label(column,"Food to carry",13)
	var loads:=_row(column)
	for load:Array in FOOD_LOADS:
		var choice:=_button(loads,String(load[1]),_set_food.bind(float(load[0])));food_buttons.append(choice)
	_set_food(0.0)
	_button(column,"Send the transport",func():_report(op.logistics.start(selected_id,String(_selected(destination_picker)),food_amount,int(_selected(army_picker)))))
	_button(column,"Call the transport back",_recall)

func _set_food(amount:float)->void:
	food_amount=amount
	for i in food_buttons.size():food_buttons[i].add_theme_stylebox_override("normal",T.button_pressed_style() if is_equal_approx(float(FOOD_LOADS[i][0]),amount) else T.action_button_style(false))

func handle_early_input(event:InputEvent)->bool:
	if event is InputEventKey and event.pressed:
		if event.keycode==KEY_ESCAPE:
			if map.drawing:map.cancel_boundary();feedback.text="Boundary cancelled."
			else:queue_free()
			return true
		var focused:=get_viewport().gui_get_focus_owner()
		if focused is LineEdit or focused is TextEdit:return false
		if event.keycode==KEY_D and not event.ctrl_pressed and not event.meta_pressed and not event.alt_pressed:map.begin_boundary();feedback.text="Click the corners of the area on the map. Enter finishes, Esc cancels.";return true
		if map.drawing and event.keycode==KEY_ENTER:map.finish_boundary(area_name.text);return true
		if map.drawing and event.keycode==KEY_BACKSPACE:map.undo_vertex();return true
	return false

func handle_map_input(event:InputEvent)->bool:
	return map.handle_map_input(event)

func _process(delta:float)->void:
	if panel==null:return
	var view_size:=get_viewport().get_visible_rect().size
	panel.offset_bottom=view_size.y-18
	panel.offset_left=-minf(360,view_size.x*.4)-16
	tick+=delta
	if tick<1 or op==null:return
	tick=0
	var key:=str(GameState.known_discoveries.hash())+str(op.state.forces.size())+str(op.state.bases.size())
	if key!=refresh_key:refresh_key=key;_refresh_choices()
	else:_refresh_status()

func _row(parent:Node)->HBoxContainer:
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",7);parent.add_child(row);return row
func _label(parent:Node,text:String,font_size:int)->Label:
	var label:=Label.new();label.text=text;label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;T.text(label,"value" if font_size>=17 else "body" if font_size>=14 else "small",T.INK if font_size>=17 else T.BODY);label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;parent.add_child(label);return label
func _button(parent:Node,text:String,callback:Callable)->Button:
	return P.button(parent,text,callback)
func _option(parent:Node)->OptionButton:
	var option:=OptionButton.new();option.size_flags_horizontal=Control.SIZE_EXPAND_FILL;option.clip_text=true;T.text(option,"small",T.INK);parent.add_child(option);return option
func _selected(option:OptionButton)->Variant:
	return option.get_item_metadata(option.selected) if option.selected>=0 and option.item_count>0 else ""
func _fill(option:OptionButton,entries:Array,selected:Variant=null)->void:
	var retain:Variant=_selected(option) if selected==null else selected
	option.clear()
	for item:Dictionary in entries:
		option.add_item(String(item.label));option.set_item_metadata(option.item_count-1,item.id)
		if typeof(item.id)==typeof(retain) and item.id==retain:option.select(option.item_count-1)
	option.disabled=entries.is_empty()

func _refresh_choices()->void:
	var forces:Array=[];var bases:Array=[];var types:Array=[];var cities:Array=[];var destinations:Array=[];var armies:Array=[{"id":0,"label":"Only food, no soldiers"}]
	for force:Dictionary in op.state.forces:
		if force.owner!="player":continue
		if force.domain==domain:forces.append({"id":force.id,"label":"%s, %d %s" % [force.name,op.hardware(force),"ships" if domain=="navy" else "aircraft"]})
	for base:Dictionary in op.state.bases:
		if base.owner=="player" and base.domain==domain:bases.append({"id":base.id,"label":String(base.name)+( " (ready)" if op.base_ready(base) else " (being built)")})
	for id:String in C.UNITS:
		var unit:Dictionary=C.UNITS[id]
		if unit.domain==domain and bool(MilitaryCampaign._knowledge_gate(String(unit.gate),.1).unlocked):types.append({"id":id,"label":unit.label})
	for city:Dictionary in GameState.player_settlements:
		if String(city.get("occupied_by","")).is_empty():cities.append({"id":city.id,"label":city.name});destinations.append({"id":city.id,"label":city.name})
	for city:Dictionary in CivilizationSystem.city_intelligence.known_cities("player","",false):
		if op._hostile("player",String(city.civ_id)):destinations.append({"id":city.city_id,"label":"Land soldiers at "+String(city.name)})
	for army:Dictionary in MilitaryCampaign.field_armies:
		if int(army.get("troops",0))>0:armies.append({"id":army.army_id,"label":"%s, %d soldiers" % [army.name,army.troops]})
	_fill(force_picker,forces,selected_id);selected_id=int(_selected(force_picker))
	_fill(base_picker,bases);_fill(type_picker,types);_fill(city_picker,cities);_fill(destination_picker,destinations);_fill(army_picker,armies)
	_select_force()

func _select_force(follow_assignment:bool=false)->void:
	var changed:=selected_id!=displayed_force_id or follow_assignment
	displayed_force_id=selected_id
	var force:Dictionary=op.force(selected_id);var missions:Array=[]
	for id:String in op.missions_for(force):
		if id!="transport":missions.append({"id":id,"label":op.MISSIONS[domain][id]})
	_fill(mission_picker,missions,String(force.get("mission","hold")) if changed else _selected(mission_picker))
	replacement.set_pressed_no_signal(bool(force.get("auto_replace",true)))
	map.selected_force=selected_id
	if changed:
		map.selected=force.get("region",{}).duplicate(true)
	_refresh_status()
func _region(region:Dictionary)->void:
	map.selected=region
	_refresh_status()
func _assign()->void:
	_report(op.assign(selected_id,map.selected,String(_selected(mission_picker))))
func _produce()->void:
	var id:=String(_selected(type_picker))
	if not C.UNITS.has(id):_report({"error":"Our people do not yet know how to build any."});return
	_report(MilitaryCampaign.start_production_line(String(C.UNITS[id].equipment),int(quantity.value)))
func _commission()->void:
	_report(op.commission(int(_selected(base_picker)),String(_selected(type_picker)),int(quantity.value)))
func _recall()->void:
	for convoy:Dictionary in op.state.convoys:
		if int(convoy.force_id)==selected_id and convoy.status in ["preparing","outbound"]:_report(op.logistics.recall(int(convoy.id)));return
	_report({"error":"No transport of theirs is on its way out."})
func _report(result:Dictionary)->void:
	feedback.text=String(result.get("error",result.get("message","Done.")))
	feedback.add_theme_color_override("font_color",T.RED_TEXT if result.has("error") else T.BODY)
	if result.has("id") and op.force(int(result.id)).get("owner","")=="player":selected_id=int(result.id)
	_refresh_choices();map.queue_redraw()
func _refresh_status()->void:
	var force:Dictionary=op.force(selected_id)
	if map.selected.is_empty():region_label.text="Pick an area on the map, or draw a new one."
	else:
		var held:=float(op.effects.control("player",map.selected))
		region_label.text="%s: %s" % [String(map.selected.name),"we hold it" if held>=.7 else "we hold part of it" if held>=.3 else "we barely reach it" if held>0.0 else "not ours"]
	if force.is_empty():status.text="No ships yet. Build a port, then build ships and train their crews." if domain=="navy" else "No flyers yet. Build an airfield, then build aircraft and form a wing."
	else:
		status.text=_force_summary(force)+"\nCurrent order: "+String(op.MISSIONS[domain].get(String(force.get("mission","hold")),"Stand by"))
	force_picker.visible=not force.is_empty()
	mission_controls.visible=not force.is_empty()
	setup_button.visible=force.is_empty()
	assign_button.disabled=force.is_empty() or map.selected.is_empty()
	if not force.is_empty():
		var ready:Dictionary=op.readiness(selected_id,map.selected)
		var lines:Array[String]=[]
		for reason:String in ready.blockers:lines.append(reason)
		if lines.is_empty():lines.append("Ready. They would do about %d%% of their best there." % roundi(float(ready.efficiency)*100))
		if domain=="air":lines.append("They reach %d%% of the area; the airfield is %d%% full; the weather allows %d%% of flights." % [roundi(float(ready.coverage)*100),roundi(float(ready.crowding)*100),roundi(float(ready.weather)*100)])
		if int(ready.missing_equipment)>0:lines.append("%d lost craft still need replacing from our stores." % int(ready.missing_equipment))
		readiness_label.text="\n".join(lines)
	else:readiness_label.text=""
	var selected_base:Dictionary=op.base(int(_selected(base_picker)))
	if selected_base.is_empty():base_status.text="No %s yet. Pick a town below to build one." % ("port" if domain=="navy" else "airfield")
	else:
		var stationed:=0
		for other:Dictionary in op.state.forces:
			if int(other.base_id)==int(selected_base.id):stationed+=op.hardware(other)
		var built:=float(selected_base.construction_work)/maxf(1.0,float(selected_base.required_work))
		base_status.text="%s: %d of %d %s in use. %s" % [selected_base.name,stationed,selected_base.capacity,"aircraft places" if domain=="air" else "repair berths","Finished." if built>=1.0 else "About %d%% built." % roundi(built*100)]
	var type_id:=String(_selected(type_picker))
	var quote:Dictionary=op.commission_quote(int(_selected(base_picker)),type_id,int(quantity.value))
	commission_button.disabled=quote.has("error")
	commission_status.text=String(quote.error) if quote.has("error") else "Needs %d crew, who then train for %s." % [quote.crew,preload("res://scripts/hud/report_when.gd").span(int(quote.training_days))]
	if not quote.has("error") and int(quote.training_days)<0:commission_status.text="Needs %d crew. Training is paused by our training rules." % int(quote.crew)
	if C.UNITS.has(type_id):
		var unit:Dictionary=C.UNITS[type_id];var materials:Array[String]=[]
		var bill:=preload("res://scripts/goods_bills.gd").flatten(unit.materials)
		for resource:String in bill:materials.append("%.1f %s" % [bill[resource],ResourceSystem.display_name(resource)])
		recipe.text="%d in our stores. Each needs %d crew and %s, and takes %.0f days of work to build. It can reach %d km." % [int(MilitaryCampaign.military_inventory.get(unit.equipment,0)),unit.crew,", ".join(materials),unit.work_days,unit.range_km]
	else:recipe.text="Our people do not yet know how to build any."
	var lines:Array[String]=[]
	for job:Dictionary in MilitaryCampaign.production_lines_snapshot().get("lines",[]):
		if String(job.get("item",""))==String(C.UNITS.get(type_id,{}).get("equipment","")):lines.append(String(job.get("state","")))
	if not lines.is_empty():recipe.text+="\nBeing built: "+", ".join(lines)
	var latest:Array[String]=[]
	for event:Dictionary in op.state.events:
		if String(event.get("domain","")) in ["",domain]:latest.append("%s: %s" % [EraWords.when(int(event.day)),event.text])
	for convoy:Dictionary in op.state.convoys:
		if String(op.force(int(convoy.force_id)).get("domain",""))==domain and convoy.status in ["preparing","outbound","returning"]:latest.append("A transport is %s with %.0f food left." % [String(convoy.status).replace("_"," "),convoy.food])
	reports.text="\n\n".join(latest.slice(0,12)) if not latest.is_empty() else "Nothing to report yet."
