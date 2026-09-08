extends CanvasLayer
const C=preload("res://scripts/joint_force_catalog.gd")
const P=preload("res://scripts/persistent_production.gd")
const Map=preload("res://scripts/hud/service_world_overlay.gd")
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

var terrain:Node
var area_name:LineEdit
var pages:TabContainer

func _ready()->void:
	layer=82;op=MilitaryCampaign.joint_operations
	map=Map.new();map.terrain=terrain;map.domain=domain;add_child(map)
	map.region_selected.connect(_region)
	map.force_selected.connect(func(id:int):selected_id=id;_refresh_choices();_select_force())
	map.base_selected.connect(func(id:int):
		for i in base_picker.item_count:
			if int(base_picker.get_item_metadata(i))==id:base_picker.select(i)
		_refresh_status())
	map.order_region.connect(func(region:Dictionary):_region(region);_assign())
	map.boundary_feedback.connect(_report)
	panel=PanelContainer.new();add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	panel.offset_top=76;panel.offset_right=-16;panel.offset_left=-376
	var style:=StyleBoxFlat.new();style.bg_color=Color("101e29");style.border_color=Color("527183");style.set_border_width_all(1);style.set_content_margin_all(12);panel.add_theme_stylebox_override("panel",style)
	panel.add_theme_font_size_override("font_size",15)
	var root:=VBoxContainer.new();root.add_theme_constant_override("separation",8);panel.add_child(root)
	var heading:=_row(root);_label(heading,"NAVAL COMMAND" if domain=="navy" else "AIR COMMAND",21);_button(heading,"×",queue_free)
	pages=TabContainer.new();pages.size_flags_vertical=Control.SIZE_EXPAND_FILL;root.add_child(pages)
	_build_service()
	feedback=_label(root,"",13)
	# Hidden selectors are data adapters for shared production/transport helpers,
	# never a second service's controls in the visible interface.
	_refresh_choices();_select_force()

func _page(title:String)->VBoxContainer:
	var scroll:=ScrollContainer.new();scroll.name=title;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;pages.add_child(scroll)
	var column:=VBoxContainer.new();column.size_flags_horizontal=Control.SIZE_EXPAND_FILL;column.add_theme_constant_override("separation",8);scroll.add_child(column);return column

func _build_service()->void:
	pass

func _force_summary(force:Dictionary)->String:
	return String(force.get("status",""))

func _region_tools(column:Node)->void:
	region_label=_label(column,"Select an area on the world map, or draw a new boundary.",14)
	area_name=LineEdit.new();area_name.placeholder_text="Sea area name" if domain=="navy" else "Air region name";column.add_child(area_name)
	var row:=_row(column)
	_button(row,"Draw region",func():map.begin_boundary();feedback.text="Click boundary points on the world map. Enter finishes; Backspace undoes; Escape cancels. Middle-drag and zoom still work.")
	_button(row,"Finish",func():map.finish_boundary(area_name.text))
	_button(row,"Cancel",func():map.cancel_boundary())
	_button(column,"Delete selected region",func():
		var result:Dictionary=op.remove_region(String(map.selected.get("id","")))
		if not result.has("error"):map.selected={};region_label.text="Region removed."
		_report(result))

func _force_controls(column:Node,stand_down:String)->void:
	force_picker=_option(column);force_picker.item_selected.connect(func(_index:int):selected_id=int(_selected(force_picker));_select_force())
	status=_label(column,"",14)
	mission_picker=_option(column)
	_button(column,"Assign mission to selected region",_assign)
	_button(column,stand_down,func():_report(op.assign(selected_id,{},"hold")))
	replacement=CheckBox.new();replacement.text="Reinforce from equipment reserve";column.add_child(replacement)
	replacement.toggled.connect(func(value:bool):if selected_id>0:_report(op.configure(selected_id,value,.6)))
	_region_tools(column)

func _production_controls(column:Node,base_word:String,creation_word:String)->void:
	base_picker=_option(column)
	base_picker.item_selected.connect(func(_index:int):_refresh_status())
	_button(column,"Rebase selected force",func():_report(op.rebase(selected_id,int(_selected(base_picker)))))
	city_picker=_option(column)
	_button(column,"Build "+base_word+" in selected city",func():_report(op.build_base(String(_selected(city_picker)),domain)))
	type_picker=_option(column);type_picker.item_selected.connect(func(_index:int):_refresh_status())
	_label(column,"Equipment reserve target / new craft",13)
	quantity=SpinBox.new();quantity.min_value=1;quantity.max_value=100;quantity.value=1;column.add_child(quantity)
	recipe=_label(column,"",13)
	_button(column,"Start equipment production",_produce)
	_button(column,creation_word,_commission)

func _transport_controls(column:Node,description:String)->void:
	_label(column,description,13)
	destination_picker=_option(column);army_picker=_option(column)
	_label(column,"Food cargo",13);food=SpinBox.new();food.min_value=0;food.max_value=100000;food.step=10;column.add_child(food)
	_button(column,"Dispatch transport",func():_report(op.logistics.start(selected_id,String(_selected(destination_picker)),float(food.value),int(_selected(army_picker)))))
	_button(column,"Recall transport",_recall)

func handle_early_input(event:InputEvent)->bool:
	if event is InputEventKey and event.pressed:
		if event.keycode==KEY_ESCAPE:
			if map.drawing:map.cancel_boundary();feedback.text="Boundary cancelled."
			else:queue_free()
			return true
		var focused:=get_viewport().gui_get_focus_owner()
		if focused is LineEdit or focused is TextEdit:return false
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
	var label:=Label.new();label.text=text;label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;label.add_theme_font_size_override("font_size",font_size);label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;parent.add_child(label);return label
func _button(parent:Node,text:String,callback:Callable)->Button:
	var button:=Button.new();button.text=text;button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;button.custom_minimum_size.y=34;button.size_flags_horizontal=Control.SIZE_EXPAND_FILL;button.pressed.connect(callback);parent.add_child(button);return button
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
		if int(force.id)!=selected_id and (force.domain==domain or (domain=="air" and force.units.has("aircraft_carrier"))):companions.append({"id":force.id,"label":force.name})
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

func _select_force()->void:
	var force:Dictionary=op.force(selected_id);var missions:Array=[]
	for id:String in op.missions_for(force):
		if id!="transport":missions.append({"id":id,"label":op.MISSIONS[domain][id]})
	_fill(mission_picker,missions,String(force.get("mission","hold")))
	replacement.set_pressed_no_signal(bool(force.get("auto_replace",true)))
	map.selected_force=selected_id
	if not force.get("region",{}).is_empty():_region(force.region)
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
		status.text=_force_summary(force)
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
