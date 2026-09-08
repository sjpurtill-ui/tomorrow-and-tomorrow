extends CanvasLayer
const C=preload("res://scripts/joint_force_catalog.gd")
const P=preload("res://scripts/persistent_production.gd")
const Map=preload("res://scripts/hud/joint_operations_map.gd")
var op:RefCounted
var map:Control
var domain:String="navy"
var force_picker:OptionButton
var base_picker:OptionButton
var type_picker:OptionButton
var city_picker:OptionButton
var destination_picker:OptionButton
var army_picker:OptionButton
var companion_picker:OptionButton
var mission_picker:OptionButton
var quantity:SpinBox
var food:SpinBox
var status:Label
var region_label:Label
var recipe:Label
var feedback:Label
var reports:Label
var replacement:CheckBox
var tick:=0.0
var selected_id:=0
var refresh_key:=""
var panel:PanelContainer

func _ready()->void:
	layer=82;op=MilitaryCampaign.joint_operations
	panel=PanelContainer.new();panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(panel)
	var style:=StyleBoxFlat.new();style.bg_color=Color("0b151b");style.set_content_margin_all(18);panel.add_theme_stylebox_override("panel",style)
	panel.add_theme_color_override("font_color",Color("dfe8e5"));panel.add_theme_font_size_override("font_size",15)
	var root:=VBoxContainer.new();root.add_theme_constant_override("separation",12);panel.add_child(root)
	var heading:=_row(root);var title:=_label(heading,"NAVAL & AIR COMMAND",24);title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	_button(heading,"Navy",func():_service("navy"));_button(heading,"Air",func():_service("air"));_button(heading,"Return to game",queue_free)
	var body:=HSplitContainer.new();body.size_flags_vertical=Control.SIZE_EXPAND_FILL;root.add_child(body)
	var chart:=VBoxContainer.new();chart.size_flags_horizontal=Control.SIZE_EXPAND_FILL;body.add_child(chart)
	var toolbar:=_row(chart)
	_button(toolbar,"−",func():map.zoom(1));_button(toolbar,"+",func():map.zoom(-1));_button(toolbar,"Home",_home)
	_label(toolbar,"Select an area; right-click assigns the selected mission.",13)
	map=Map.new();map.size_flags_vertical=Control.SIZE_EXPAND_FILL;map.size_flags_horizontal=Control.SIZE_EXPAND_FILL;chart.add_child(map)
	map.region_selected.connect(func(region:Dictionary):_region(region))
	map.force_selected.connect(func(id:int):selected_id=id;_refresh_choices();_select_force())
	map.order_region.connect(func(region:Dictionary):_region(region);_assign())
	map.boundary_feedback.connect(_report)
	var boundary:=_row(chart)
	var area_name:=LineEdit.new();area_name.placeholder_text="Operating area name";area_name.size_flags_horizontal=Control.SIZE_EXPAND_FILL;boundary.add_child(area_name)
	_button(boundary,"Draw area",func():map.begin_boundary())
	_button(boundary,"Finish",func():map.finish_boundary(area_name.text))
	_button(boundary,"Cancel",func():map.cancel_boundary())
	_button(boundary,"Delete",func():
		var result:Dictionary=op.remove_region(String(map.selected.get("id","")))
		_report(result)
		if not result.has("error"):map.selected={};map.queue_redraw())
	region_label=_label(chart,"Draw a sea operating area on the map.",15)
	var scroll:=ScrollContainer.new();scroll.custom_minimum_size.x=350;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;body.add_child(scroll)
	var column:=VBoxContainer.new();column.size_flags_horizontal=Control.SIZE_EXPAND_FILL;column.add_theme_constant_override("separation",9);scroll.add_child(column)
	_label(column,"TASK FORCES & AIR WINGS",18)
	force_picker=_option(column);force_picker.item_selected.connect(func(_index:int):selected_id=int(_selected(force_picker));_select_force())
	status=_label(column,"",14)
	mission_picker=_option(column)
	var actions:=_row(column);_button(actions,"Assign region",_assign);_button(actions,"Return / stand down",func():_report(op.assign(selected_id,{},"hold")))
	replacement=CheckBox.new();replacement.text="Replace losses from reserve automatically";column.add_child(replacement)
	replacement.toggled.connect(func(value:bool):if selected_id>0:_report(op.configure(selected_id,value,.6)))
	_label(column,"BASES & PRODUCTION",18)
	base_picker=_option(column)
	base_picker.item_selected.connect(func(_index:int):_refresh_status())
	_button(column,"Rebase selected force here",func():_report(op.rebase(selected_id,int(_selected(base_picker)))))
	city_picker=_option(column)
	_button(column,"Build base in selected city",func():_report(op.build_base(String(_selected(city_picker)),domain)))
	type_picker=_option(column);type_picker.item_selected.connect(func(_index:int):_refresh_status())
	var amounts:=_row(column);_label(amounts,"Reserve target / craft to commission",13)
	quantity=SpinBox.new();quantity.min_value=1;quantity.max_value=100;quantity.value=1;quantity.custom_minimum_size.x=75;amounts.add_child(quantity)
	recipe=_label(column,"",13)
	var creation:=_row(column);_button(creation,"Start production",_produce);_button(creation,"Commission",_commission)
	_label(column,"ORGANIZATION",18)
	companion_picker=_option(column)
	var organization:=_row(column)
	_button(organization,"Combine at base",func():_report(op.merge_forces(selected_id,int(_selected(companion_picker)))) )
	_button(organization,"Split in half",func():_report(op.split_force(selected_id)))
	_button(column,"Embark selected air wing on this carrier",func():_report(op.attach_carrier(selected_id,int(_selected(companion_picker)))))
	_button(column,"Join companion's fleet",func():_report(op.group_fleet(selected_id,int(_selected(companion_picker)))))
	_label(column,"TRANSPORT & INVASIONS",18)
	_label(column,"Assemble the army at the embarkation base. Transport crews handle loading, the route and return. Invasions require regional control and preparation.",13)
	destination_picker=_option(column);army_picker=_option(column)
	var cargo:=_row(column);_label(cargo,"Food cargo",14);food=SpinBox.new();food.min_value=0;food.max_value=100000;food.value=0;food.step=10;cargo.add_child(food)
	_button(column,"Dispatch transport",func():_report(op.logistics.start(selected_id,String(_selected(destination_picker)),float(food.value),int(_selected(army_picker)))))
	_button(column,"Recall selected force's convoy",_recall)
	_button(column,"Disband selected force at base",func():_report(op.disband(selected_id)))
	feedback=_label(root,"",14)
	reports=_label(chart,"",13)
	_refresh_choices();_select_force();_home()

func _row(parent:Node)->HBoxContainer:
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",7);parent.add_child(row);return row
func _label(parent:Node,text:String,font_size:int)->Label:
	var label:=Label.new();label.text=text;label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;label.add_theme_font_size_override("font_size",font_size);label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;parent.add_child(label);return label
func _button(parent:Node,text:String,callback:Callable)->Button:
	var button:=Button.new();button.text=text;button.custom_minimum_size.y=34;button.pressed.connect(callback);parent.add_child(button);return button
func _option(parent:Node)->OptionButton:
	var option:=OptionButton.new();option.size_flags_horizontal=Control.SIZE_EXPAND_FILL;option.clip_text=true;parent.add_child(option);return option
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
	var forces:Array=[];var bases:Array=[];var types:Array=[];var cities:Array=[];var companions:Array=[];var destinations:Array=[];var armies:Array=[{"id":0,"label":"Food cargo only · no army"}]
	for force:Dictionary in op.state.forces:
		if force.owner!="player":continue
		companions.append({"id":force.id,"label":force.name})
		if force.domain==domain:forces.append({"id":force.id,"label":"%s · %d %s" % [force.name,op.hardware(force),"ships" if domain=="navy" else "aircraft"]})
	for base:Dictionary in op.state.bases:
		if base.owner=="player" and base.domain==domain:bases.append({"id":base.id,"label":String(base.name)+( " · ready" if op.base_ready(base) else " · building")})
	for id:String in C.UNITS:
		var unit:Dictionary=C.UNITS[id]
		if unit.domain==domain and bool(MilitaryCampaign._knowledge_gate(String(unit.gate),.1).unlocked):types.append({"id":id,"label":unit.label})
	for city:Dictionary in GameState.player_settlements:
		if String(city.get("occupied_by","")).is_empty():cities.append({"id":city.id,"label":city.name});destinations.append({"id":city.id,"label":city.name})
	for city:Dictionary in CivilizationSystem.city_intelligence.known_cities("player","",false):
		if op._hostile("player",String(city.civ_id)):destinations.append({"id":city.city_id,"label":String(city.name)+" · invasion"})
	for army:Dictionary in MilitaryCampaign.field_armies:
		if int(army.get("troops",0))>0:armies.append({"id":army.army_id,"label":"%s · %d troops" % [army.name,army.troops]})
	_fill(force_picker,forces,selected_id);selected_id=int(_selected(force_picker))
	_fill(base_picker,bases);_fill(type_picker,types);_fill(city_picker,cities);_fill(companion_picker,companions);_fill(destination_picker,destinations);_fill(army_picker,armies)
	_select_force()

func _service(value:String)->void:
	domain=value;map.domain=value;map.selected={};map.selected_force=0;selected_id=0
	map.cancel_boundary();map.selected={}
	_refresh_choices();region_label.text="Draw or select a "+("sea" if domain=="navy" else "air")+" region on the map.";map.queue_redraw()
func _select_force()->void:
	var force:Dictionary=op.force(selected_id);var missions:Array=[]
	for id:String in op.missions_for(force):
		if id!="transport":missions.append({"id":id,"label":op.MISSIONS[domain][id]})
	_fill(mission_picker,missions,String(force.get("mission","hold")))
	replacement.set_pressed_no_signal(bool(force.get("auto_replace",true)))
	map.selected_force=selected_id
	_refresh_status()
func _region(region:Dictionary)->void:
	map.selected=region
	region_label.text=String(region.name)+" · control %d%%" % roundi(float(op.effects.control("player",region))*100)
func _assign()->void:
	_report(op.assign(selected_id,map.selected,String(_selected(mission_picker))))
func _produce()->void:
	var id:=String(_selected(type_picker))
	if not C.UNITS.has(id):_report({"error":"Research an available hull or aircraft type first."});return
	_report(MilitaryCampaign.start_production_line(String(C.UNITS[id].equipment),int(quantity.value)))
func _commission()->void:
	_report(op.commission(int(_selected(base_picker)),String(_selected(type_picker)),int(quantity.value)))
func _recall()->void:
	for convoy:Dictionary in op.state.convoys:
		if int(convoy.force_id)==selected_id and convoy.status in ["preparing","outbound"]:_report(op.logistics.recall(int(convoy.id)));return
	_report({"error":"This force has no outbound convoy to recall."})
func _report(result:Dictionary)->void:
	feedback.text=String(result.get("error",result.get("message","Order updated.")))
	feedback.modulate=Color("f1a298") if result.has("error") else Color("a5d5c5")
	if result.has("id") and op.force(int(result.id)).get("owner","")=="player":selected_id=int(result.id)
	_refresh_choices();map.queue_redraw()
func _refresh_status()->void:
	var force:Dictionary=op.force(selected_id)
	if force.is_empty():status.text="No force selected. Produce equipment, then commission crews at a ready base."
	else:
		status.text="%s\n%d crew · %d craft · training %d%% · condition %d%%\n%s\nFuel: %d/day · reserve %d · fleet %d" % [force.name,op.crew(force),op.hardware(force),roundi(float(force.training)*100),roundi(float(force.condition)*100),force.status,op.fuel_cost(force),int(MilitaryCampaign.military_consumables.get("fuel",0)),int(force.get("fleet_id",force.id))]
	var type_id:=String(_selected(type_picker))
	if C.UNITS.has(type_id):
		var unit:Dictionary=C.UNITS[type_id];var materials:Array[String]=[]
		for resource:String in unit.materials:materials.append("%.1f %s" % [unit.materials[resource],ResourceSystem.display_name(resource)])
		recipe.text="Reserve: %d · %d crew per craft\nPer craft: %s\n%.0f work-days · %d km range" % [int(MilitaryCampaign.military_inventory.get(unit.equipment,0)),unit.crew,", ".join(materials),unit.work_days,unit.range_km]
	else:recipe.text="No researched designs for this service yet. The Units & Equipment Map shows the full progression chain."
	var lines:Array[String]=[]
	for job:Dictionary in MilitaryCampaign.production_lines_snapshot().get("lines",[]):
		if String(job.get("item",""))==String(C.UNITS.get(type_id,{}).get("equipment","")):lines.append(String(job.get("state","")))
	if not lines.is_empty():recipe.text+="\nProduction: "+", ".join(lines)
	var latest:Array[String]=[]
	for event:Dictionary in op.state.events.slice(0,3):latest.append("Day %d · %s" % [event.day,event.text])
	for convoy:Dictionary in op.state.convoys:
		if convoy.status in ["preparing","outbound","returning"]:latest.append("Convoy %d · %s · %.0f food remaining" % [convoy.id,convoy.status,convoy.food])
	reports.text="\n".join(latest.slice(0,6))
func _home()->void:
	var base:Dictionary=op.base(int(_selected(base_picker)))
	if not base.is_empty():map.center=op.point(base)
	elif not GameState.player_settlements.is_empty():map.center=Vector2(GameState.player_settlements[0].get("position",Vector2.ZERO))
	map.queue_redraw()
func _process(delta:float)->void:
	tick+=delta
	if tick<1 or op==null:return
	tick=0
	var key:=str(GameState.known_discoveries.hash())+str(op.state.forces.size())+str(op.state.bases.size())
	if key!=refresh_key:refresh_key=key;_refresh_choices()
	else:_refresh_status()
	map.queue_redraw()
func _unhandled_input(event:InputEvent)->void:
	if event.is_action_pressed("ui_cancel"):get_viewport().set_input_as_handled();queue_free()
