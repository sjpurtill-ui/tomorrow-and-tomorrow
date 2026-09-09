extends CanvasLayer
## One service at a time, over the same terrain and camera as the game.
const Overlay=preload("res://scripts/hud/service_world_overlay.gd")
const CommandTree=preload("res://scripts/hud/command_tree.gd")
const OrderBrief=preload("res://scripts/hud/command_order_brief.gd")
var domain:="army"
var terrain:Node
var command:RefCounted
var map:Control
var panel:PanelContainer
var tree:Tree
var selected:Dictionary={}
var selected_label:Label
var current_order_label:Label
var edit_order_button:Button
var mission:OptionButton
var mission_hint:Label
var mission_reasons:Dictionary={}
var cities:OptionButton
var area_name:LineEdit
var vision:LineEdit
var feedback:Label
var region_label:Label
var status:Label
var group_level:OptionButton
var group_name:LineEdit
var tick:=0.0
var orders_scroll:ScrollContainer
var apply_button:Button
var details:VBoxContainer
var details_toggle:Button
var finish_button:Button
var cancel_boundary_button:Button
func _ready()->void:
	layer=82;command=MilitaryCampaign.command_hierarchy
	if domain=="army":command.land.refresh_claims()
	map=Overlay.new();map.domain=domain;map.terrain=terrain;add_child(map)
	map.region_selected.connect(_region);map.boundary_feedback.connect(_report)
	map.order_region.connect(func(region:Dictionary):_region(region);_assign())
	map.force_selected.connect(_select_force)
	panel=PanelContainer.new();add_child(panel);panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	panel.offset_top=76;panel.offset_right=-12;panel.offset_left=-472
	var skin:=StyleBoxFlat.new();skin.bg_color=Color("101e29");skin.border_color=Color("637b86");skin.set_border_width_all(1);skin.set_content_margin_all(12);panel.add_theme_stylebox_override("panel",skin);panel.add_theme_font_size_override("font_size",14)
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",9);panel.add_child(column)
	var heading:=_row(column);var title:=_label(heading,"ARMY COMMAND" if domain=="army" else "FLEET COMMAND" if domain=="navy" else "AIR FORCE COMMAND",21)
	title.autowrap_mode=TextServer.AUTOWRAP_OFF;title.clip_text=true;title.tooltip_text=title.text
	_button(heading,"Close ×",queue_free)
	var tabs:=TabContainer.new();tabs.size_flags_vertical=Control.SIZE_EXPAND_FILL;column.add_child(tabs)
	var orders:=VBoxContainer.new();orders.name="Orders";orders.add_theme_constant_override("separation",8);tabs.add_child(orders)
	tree=CommandTree.new();tree.service=domain;orders.add_child(tree);tree.custom_minimum_size.y=200;tree.size_flags_stretch_ratio=2;tree.command_selected.connect(_selected)
	var scroll:=ScrollContainer.new();orders_scroll=scroll;scroll.custom_minimum_size.y=100;scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;orders.add_child(scroll)
	var controls:=VBoxContainer.new();controls.size_flags_horizontal=Control.SIZE_EXPAND_FILL;controls.add_theme_constant_override("separation",8);scroll.add_child(controls)
	selected_label=_label(controls,"Select a command in the hierarchy",16)
	selected_label.autowrap_mode=TextServer.AUTOWRAP_OFF;selected_label.clip_text=true
	var current_row:=_row(controls)
	current_order_label=_label(current_row,"Now: no command selected",14)
	current_order_label.autowrap_mode=TextServer.AUTOWRAP_OFF;current_order_label.clip_text=true
	edit_order_button=_button(current_row,"Edit",_edit_current_order);edit_order_button.custom_minimum_size.y=22;edit_order_button.size_flags_horizontal=Control.SIZE_SHRINK_END;edit_order_button.disabled=true
	mission=OptionButton.new();mission.clip_text=true;controls.add_child(mission)
	mission.tooltip_text="Next objective. Selecting or editing this draft does not issue an order; use Give objective or right-click a zone on the map."
	var catalog:Dictionary=command.LAND_MISSIONS if domain=="army" else MilitaryCampaign.joint_operations.MISSIONS[domain]
	for id:String in catalog:
		if id=="transport":continue
		mission.add_item("Next: "+String(catalog[id]));mission.set_item_metadata(mission.item_count-1,id)
	mission.item_selected.connect(func(_index:int):_refresh_targets())
	mission_hint=_label(controls,"");mission_hint.max_lines_visible=2;mission_hint.modulate=Color("efa092");mission_hint.hide()
	cities=OptionButton.new();cities.clip_text=true;controls.add_child(cities)
	region_label=_label(controls,"Zone: select on map or draw below")
	region_label.max_lines_visible=1
	var drawing:=_row(controls);_button(drawing,"Draw zone · D",_draw_zone)
	finish_button=_button(drawing,"Finish",func():map.finish_boundary(area_name.text))
	cancel_boundary_button=_button(drawing,"Cancel drawing",func():map.cancel_boundary())
	finish_button.hide();cancel_boundary_button.hide()
	details_toggle=_button(controls,"Names & brief ▸",func():details.visible=not details.visible;details_toggle.text="Names & brief ▾" if details.visible else "Names & brief ▸")
	details=VBoxContainer.new();details.add_theme_constant_override("separation",6);controls.add_child(details);details.hide()
	area_name=LineEdit.new();area_name.placeholder_text="New battle zone name (optional)" if domain=="army" else "New operating area name (optional)";details.add_child(area_name)
	vision=LineEdit.new();vision.placeholder_text="Commander's brief (optional)";vision.tooltip_text="A note attached to the supported objective selected above. It does not create additional mechanics.";details.add_child(vision)
	status=_label(controls,"");status.max_lines_visible=2;status.hide()
	# The primary action stays outside the scrolling details, at every scroll
	# position and regardless of optional text or the selected city objective.
	var action:=_row(orders);apply_button=_button(action,"Give objective",_assign)
	var cancel_orders:=_button(action,"Cancel orders",_cancel_orders)
	cancel_orders.tooltip_text="Cancel only the selected command. A subdivision must be able to assemble before it can detach; other commands keep their objectives."
	feedback=_label(column,"");feedback.max_lines_visible=2;feedback.hide()
	var organization:=VBoxContainer.new();organization.name="Organization";organization.add_theme_constant_override("separation",10);tabs.add_child(organization)
	_label(organization,"Build the chain of command",19)
	_label(organization,"Use Command-click to select multiple commands in Orders. Choose a higher headquarters below; its orders will include every subordinate.")
	group_level=OptionButton.new();organization.add_child(group_level)
	for index in command.LEVELS[domain].size():group_level.add_item(String(command.LEVELS[domain][index][0]));group_level.set_item_metadata(index,index)
	group_level.select(command.LEVELS[domain].size()-1)
	group_name=LineEdit.new();group_name.placeholder_text="Headquarters name (optional)";organization.add_child(group_name)
	_button(organization,"Group selected commands",_group)
	_label(organization,"Expand any force down to teams, ships or air elements. A smaller formation is physically detached when you give it an order. No extra troops or equipment are created.")
	_button(organization,"Delete selected zone",func():_report(command.remove_region(String(map.selected.get("id",""))) if domain=="army" else MilitaryCampaign.joint_operations.remove_region(String(map.selected.get("id","")))))
	var links:=_row(column)
	_button(links,"Forces & training",func():queue_free();MilitaryCampaign.open_roster(domain))
	_button(links,"Army builds" if domain=="army" else "Ports & ships" if domain=="navy" else "Airbases & aircraft",_management)
	_refresh_targets()
func _row(parent:Node)->HBoxContainer:
	var result:=HBoxContainer.new();result.add_theme_constant_override("separation",6);parent.add_child(result);return result
func _label(parent:Node,text:String,size:int=14)->Label:
	var result:=Label.new();result.text=text;result.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;result.size_flags_horizontal=Control.SIZE_EXPAND_FILL;result.add_theme_font_size_override("font_size",size);parent.add_child(result);return result
func _button(parent:Node,text:String,callback:Callable)->Button:
	var result:=Button.new();result.text=text;result.custom_minimum_size.y=34;result.pressed.connect(callback);result.size_flags_horizontal=Control.SIZE_EXPAND_FILL;parent.add_child(result);return result
func _selected(entry:Dictionary)->void:
	selected=entry
	_update_current_order()
	_refresh_mission_availability()
	if entry.is_empty():
		selected_label.text="Select a command in the hierarchy";selected_label.tooltip_text=""
		map.selected_force=0;status.text="";status.hide();return
	selected_label.text="%s · %d %s" % [entry.name,int(entry.count),"personnel" if domain=="army" else "ships" if domain=="navy" else "aircraft"]
	selected_label.tooltip_text=selected_label.text+"\n"+String(entry.leader)
	map.selected_force=int(command.node(String(entry.id)).get("force_id",0))
	_update_status()
func _select_force(id:int)->void:
	command.sync()
	for entry:Dictionary in command.data.nodes.values():
		if entry.service==domain and int(entry.force_id)==id:tree.rebuild(String(entry.id));return
func _region(region:Dictionary)->void:
	map.selected=region;region_label.text="Zone: "+String(region.get("name","select on map or draw below"));region_label.tooltip_text=region_label.text;_refresh_targets()

func _update_current_order()->void:
	# Existing live panels may not contain this strip until they are reopened.
	if not is_instance_valid(current_order_label):return
	var brief:Dictionary=OrderBrief.snapshot(command,selected)
	current_order_label.text="Now: "+String(brief.summary);current_order_label.tooltip_text=String(brief.tooltip)
	current_order_label.modulate=Color("e9c277") if brief.mixed or int(brief.overrides)>0 else Color("acd8c5") if not brief.order.is_empty() else Color("afbbc3")
	edit_order_button.disabled=not bool(brief.editable)
	edit_order_button.tooltip_text="Copy this issued order into the next-objective draft and highlight its zone on the main map. Give objective commits changes." if brief.editable else String(brief.tooltip)

func _edit_current_order()->void:
	command.sync()
	var brief:Dictionary=OrderBrief.snapshot(command,selected)
	if not bool(brief.editable):_update_current_order();return
	var issued:Dictionary=brief.order
	for index in mission.item_count:
		if mission.get_item_metadata(index)==issued.mission:mission.select(index);break
	_region(brief.region)
	for index in cities.item_count:
		if cities.get_item_metadata(index)==issued.get("target",""):cities.select(index);break
	vision.text=String(issued.get("vision",""))
	_update_current_order()
	_report({"message":"Current order loaded for editing. Give objective applies changes."})
func _draw_zone()->void:
	map.begin_boundary();_report({"message":"Click boundary points on the main map. Enter finishes; right-click undoes; Escape cancels."})
func _mission()->String:return String(mission.get_item_metadata(mission.selected))
func _refresh_mission_availability()->void:
	if not is_instance_valid(mission) or not is_instance_valid(apply_button) or not is_instance_valid(mission_hint):return
	mission_reasons.clear()
	var current:Dictionary={} if selected.is_empty() else command.preview(String(selected.id),selected.get("path",[]))
	var selection_error:=""
	if current.is_empty() or int(current.get("count",0))<=0:selection_error="Select an available command in the hierarchy."
	elif not selected.get("path",[]).is_empty() and int(current.count)!=int(selected.count):selection_error="This formation's strength changed. Select it again before ordering it."
	var capabilities:Array[Dictionary]=[]
	if selection_error=="" and domain!="army":
		for leaf:Dictionary in command.leaves(String(selected.id)):
			capabilities.append({"name":String(leaf.name),"missions":MilitaryCampaign.joint_operations.missions_for(command.force(leaf))})
	for index in mission.item_count:
		var id:=String(mission.get_item_metadata(index));var reason:=selection_error
		var unsupported:Array[String]=[]
		for capability:Dictionary in capabilities:
			if id not in capability.missions:unsupported.append(String(capability.name))
		if not unsupported.is_empty():
			reason="%d %s %s the required %s for this objective." % [unsupported.size(),"command" if unsupported.size()==1 else "commands","lacks" if unsupported.size()==1 else "lack","ships" if domain=="navy" else "aircraft"]
			var examples:="\n".join(unsupported.slice(0,3))
			if unsupported.size()>3:examples+="\n+ %d other commands" % (unsupported.size()-3)
			reason+="\n"+examples+"\nSelect a compatible subordinate or choose another objective."
		mission_reasons[id]=reason
		mission.set_item_disabled(index,reason!="")
		mission.get_popup().set_item_tooltip(index,reason)
	var blocked:=String(mission_reasons.get(_mission(),""))
	apply_button.disabled=blocked!="";apply_button.tooltip_text=blocked if blocked!="" else "Give this objective to the selected command. Staff report preparation and supply delays."
	mission_hint.text=blocked.get_slice("\n",0);mission_hint.tooltip_text=blocked
	mission_hint.visible=blocked!="" and not selected.is_empty()
	# Never replace a player's draft when selection or equipment changes.
	# A retained but unavailable draft is explained and cannot be submitted.
func _refresh_targets()->void:
	if cities==null:return
	var retain:Variant=cities.get_item_metadata(cities.selected) if cities.item_count>0 else ""
	cities.clear()
	cities.visible=domain=="army" and _mission() in ["capture","occupy","raze"]
	for city:Dictionary in CivilizationSystem.city_intelligence.known_cities():
		if command.R.contains(map.selected,command.G.unpack(city.position)):
			cities.add_item(String(city.name));cities.set_item_metadata(cities.item_count-1,String(city.city_id))
			if retain==city.city_id:cities.select(cities.item_count-1)
	if cities.item_count==0:cities.add_item("No reported cities in this zone");cities.set_item_metadata(0,"");cities.disabled=true
	else:cities.disabled=false
	_refresh_mission_availability()
func _assign()->void:
	if selected.is_empty():_report({"error":"Select a command in the hierarchy first."});return
	_refresh_mission_availability()
	var blocked:=String(mission_reasons.get(_mission(),""))
	if blocked!="":_report({"error":blocked});return
	var current:Dictionary=command.preview(String(selected.id),selected.path)
	if current.is_empty() or (not selected.path.is_empty() and int(current.count)!=int(selected.count)):_report({"error":"This formation's strength changed. Select it again before detaching or ordering it."});tree.rebuild();return
	var result:Dictionary=command.assign(String(selected.id),selected.path,map.selected,_mission(),String(cities.get_item_metadata(cities.selected)),vision.text)
	_report(result)
	if not result.has("error"):tree.rebuild(String(result.id))
func _group()->void:
	var ids:Array=[]
	for entry:Dictionary in tree.selections():
		if not entry.path.is_empty():_report({"error":"Group existing commands; detach a smaller formation by assigning it first."});return
		ids.append(String(entry.id))
	var result:Dictionary=command.organize(ids,group_level.selected,group_name.text)
	_report(result)
	if not result.has("error"):tree.rebuild(String(result.id))
func _cancel_orders()->void:
	if selected.is_empty():_report({"error":"Select a command in the hierarchy first."});return
	var result:Dictionary=command.cancel(String(selected.id),selected.get("path",[]),int(selected.get("count",-1)))
	_report(result)
	if not result.has("error"):
		tree.rebuild(String(result.id),result.get("path",[]))
		_update_status()
func _report(result:Dictionary)->void:
	feedback.text=String(result.get("error",result.get("message","Order updated.")))
	feedback.tooltip_text=feedback.text;feedback.visible=feedback.text!=""
	feedback.modulate=Color("efa092") if result.has("error") else Color("a7d8c2")
	map.queue_redraw()
func _management()->void:
	if domain=="army":
		if is_instance_valid(terrain) and terrain.hud:terrain.hud.open_dock("military",1,false)
		queue_free()
	else:
		MilitaryCampaign.joint_operations.screen=null;queue_free();MilitaryCampaign.joint_operations.open_service(domain)
func _update_status()->void:
	if status==null or selected.is_empty():return
	var lines:Array[String]=[]
	for leaf:Dictionary in command.leaves(String(selected.id)):
		var actual:Dictionary=command.force(leaf)
		if actual.is_empty():continue
		if domain=="army":
			var report:Dictionary=actual if MilitaryCampaign._army_is_home(actual) or MilitaryCampaign._live_army_reporting() else actual.get("last_report",{})
			lines.append("%s: %s" % [leaf.name,report.get("command_status","Awaiting commander's report")])
		else:lines.append("%s: %s" % [leaf.name,actual.get("status","Awaiting staff report")])
	status.text="\n".join(lines.slice(0,2));status.tooltip_text="\n".join(lines);status.visible=not lines.is_empty()
func _process(delta:float)->void:
	if panel==null:return
	var view:=get_viewport().get_visible_rect().size
	panel.offset_left=-minf(460,view.x*.48)-12;panel.offset_bottom=view.y-16
	# An editor hot reload can leave an older, already-open panel without these
	# new controls. It remains usable until the player closes and reopens it.
	if is_instance_valid(finish_button):finish_button.visible=map.drawing
	if is_instance_valid(cancel_boundary_button):cancel_boundary_button.visible=map.drawing
	tick+=delta
	if tick>=1:tick=0;tree.refresh();_update_status();_update_current_order();_refresh_mission_availability()
func handle_early_input(event:InputEvent)->bool:
	if not event is InputEventKey or not event.pressed:return false
	if event.keycode==KEY_ESCAPE:
		if map.drawing:map.cancel_boundary();feedback.text="Boundary cancelled."
		else:queue_free()
		return true
	var focused:=get_viewport().gui_get_focus_owner()
	if focused is LineEdit or focused is TextEdit:return false
	if event.keycode==KEY_D and not event.ctrl_pressed and not event.meta_pressed:_draw_zone();return true
	if map.drawing and event.keycode==KEY_ENTER:map.finish_boundary(area_name.text);return true
	if map.drawing and event.keycode==KEY_BACKSPACE:map.undo_vertex();return true
	return false
func handle_map_input(event:InputEvent)->bool:return map.handle_map_input(event)
