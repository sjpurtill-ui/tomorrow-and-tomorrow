extends CanvasLayer
## Visual service roster over the real world. All figures come from the existing reports.
const Art=preload("res://scripts/hud/military_roster_visuals.gd")
const Gauge=preload("res://scripts/hud/military_roster_gauge.gd")
const TEXT:=Color("e9ede6")
const MUTED:=Color("9eafb4")
const GOOD:=Color("83bea1")
const WARNING:=Color("e2a078")
var service:String="army"
var training_view:=false
var panel:PanelContainer
var body:VBoxContainer
var policy_status:Label
var policy_buttons:Dictionary={}
var policy_cards:Dictionary={}
var service_buttons:Dictionary={}
var service_indicators:Dictionary={}
var bindings:Array[Dictionary]=[]
var rows_signature:=""
var timer:=0.0
var scroll:ScrollContainer
var selected_row:Dictionary={}
var heading:Label
var close_button:Button
var management_button:Button
var portraits:Node
var hero_values:Dictionary={}
var policy_shortcut:Button
var policy_grid:GridContainer
var roster_filter:="all"
var summary_costs:Dictionary={}
var layout_size:=Vector2.ZERO
var roster_button:Button
var training_button:Button
var inspection_labels:Dictionary={}
var page:String="forces"
var page_buttons:Dictionary={}
var support_labels:Dictionary={}
var editor_id:int=-1

func _ready()->void:
	layer=87;portraits=Art.new();add_child(portraits)
	panel=PanelContainer.new();add_child(panel)
	panel.add_theme_stylebox_override("panel",_skin(Color("0e1b22"),Color("3d545a"),18))
	panel.add_theme_font_size_override("font_size",15)
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",10);panel.add_child(column)
	var header:=HBoxContainer.new();header.add_theme_constant_override("separation",7);column.add_child(header)
	heading=_label(header,"FORCES",22);heading.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	# No fleet before boats, no air service before flight: a service the people
	# cannot yet field is not offered as a tab.
	var era_words:GDScript=preload("res://scripts/hud/era_words.gd")
	var services:Array[String]=["army"]
	if bool(era_words.call("has_boats")):services.append("navy")
	if bool(era_words.call("has_flight")):services.append("air")
	if service not in services:service="army"
	for domain:String in services:
		var choice:=domain
		var button:=_button(header,{"army":"Army","navy":"Navy","air":"Air Force"}[domain],func():service=choice;selected_row={};roster_filter="all";scroll.scroll_vertical=0;_build_body())
		button.icon=Art.symbol(domain,Art.COLORS[domain],22)
		button.toggle_mode=true;service_buttons[domain]=button
		# A lone land force needs no service switch.
		button.visible=services.size()>1
	close_button=_button(header,"×",queue_free);close_button.custom_minimum_size=Vector2(40,38);close_button.tooltip_text="Close · Escape or click the map"
	var nav:=HFlowContainer.new();nav.add_theme_constant_override("h_separation",6);column.add_child(nav)
	for entry:Array in [["forces","Forces"],["recruitment","Recruit & deploy"],["training","Training"],["support","Readiness & supply"]]:
		var key:=String(entry[0]);var button:=_button(nav,String(entry[1]),func():_show_page(key))
		button.toggle_mode=true;page_buttons[key]=button
	roster_button=page_buttons.forces;training_button=page_buttons.training;management_button=page_buttons.recruitment
	var map_button:=_button(nav,"Command on map ↗",_map_command)
	map_button.tooltip_text="Give objectives to this service on the world map. Leaders execute them."
	scroll=ScrollContainer.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;column.add_child(scroll)
	body=VBoxContainer.new();body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;body.add_theme_constant_override("separation",8);scroll.add_child(body)
	_layout();_build_body()

func _skin(bg:Color,border:Color=Color.TRANSPARENT,margin:int=10)->StyleBoxFlat:
	var style:=StyleBoxFlat.new();style.bg_color=bg;style.border_color=border;style.set_border_width_all(1)
	style.set_corner_radius_all(7);style.set_content_margin_all(margin);return style

func _layout()->void:
	var view:=get_viewport().get_visible_rect().size
	if view!=layout_size:
		layout_size=view
		var inset:=maxf(16,view.x*.045)
		panel.position=Vector2(inset,64);panel.size=Vector2(view.x-inset*2,view.y-100)
	if is_instance_valid(body):
		var column:VBoxContainer=panel.get_child(0)
		var content_height:=36.0+column.get_theme_constant("separation")*(column.get_child_count()-1)+body.get_combined_minimum_size().y
		for child:Control in column.get_children():
			if child!=scroll:content_height+=child.get_combined_minimum_size().y
		panel.size.y=clampf(content_height+2,300,maxf(300,view.y-100))
	if is_instance_valid(policy_grid):policy_grid.columns=4 if panel.size.x>=920 else 2

func _production()->void:
	var scene:=get_tree().current_scene
	if scene!=null and "hud" in scene and scene.hud:scene.hud.open_dock("production",2)

func _recruitment()->void:
	if service!="army":
		_wrapped(body,"Review crews and service organization through command. Manufacturing belongs in Production.")
		_button(body,"Service command",_map_command)
		_button(body,"Military production ↗",_production)
		return
	if editor_id>=0:_template_editor();return
	var board:=preload("res://scripts/hud/recruit_deploy_board.gd").new()
	body.add_child(board)
	board.setup({"edit_template":func(id:int):editor_id=id;_build_body()})

func _template_editor()->void:
	var template:Dictionary={}
	for candidate:Dictionary in MilitaryCampaign.army_template_snapshot().templates:
		if int(candidate.template_id)==editor_id:template=candidate;break
	_button(body,"← Recruitment queue",func():editor_id=-1;_build_body())
	if template.is_empty():_wrapped(body,"This template no longer exists.");return
	_label(body,String(template.name),21)
	_wrapped(body,"A formation design sets the soldiers and equipment to recruit. Changing it does not create troops.")
	for entry:Dictionary in template.entries:
		var unit:=String(entry.unit);var weapon:=String(entry.weapon)
		var row:=HBoxContainer.new();body.add_child(row)
		var name_label:=_label(row,"%s · %s" % [unit.replace("_"," ").capitalize(),MilitaryCampaign.PersistentProduction.product_name(weapon)])
		name_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		_label(row,str(entry.count))
		for amount:int in [-10,-1,1,10]:
			var change:=amount
			_button(row,"%+d" % change,func():MilitaryCampaign.adjust_template_entry(editor_id,unit,weapon,change);_build_body())
	_label(body,"ADD TO THIS FORMATION",12,Art.COLORS[service])
	var choices:=HFlowContainer.new();body.add_child(choices)
	var available:Dictionary=MilitaryCampaign.military_capabilities().get("unit_equipment",{})
	for unit:String in available:
		for weapon:String in available[unit]:
			var kind:=unit;var equipment:=weapon
			_button(choices,"+10 %s · %s" % [unit.replace("_"," ").capitalize(),MilitaryCampaign.PersistentProduction.product_name(weapon)],func():MilitaryCampaign.adjust_template_entry(editor_id,kind,equipment,10);_build_body())
	_button(body,"Delete this design",func():MilitaryCampaign.delete_army_template(editor_id);editor_id=-1;_build_body())

func _support_data()->Array:
	if service!="army":
		var items:Array=[]
		for force:Dictionary in _rows():
			items.append({"id":String(force.id),"label":String(force.name).to_upper(),"value":"%.0f%% condition" % (float(force.get("condition",0))*100),"note":String(force.get("equipment_note",""))+" · "+String(force.get("activity",""))})
		if items.is_empty():items.append({"id":"empty","label":"SERVICE READINESS","value":"No forces in service","note":"Force condition and crew readiness will appear here."})
		return items
	var army:Dictionary=MilitaryCampaign.campaign_army_snapshot()
	var damaged:=0;var spare:=0;var equipped:=0;var required:=0
	for count in army.get("damaged_equipment",{}).values():damaged+=int(count)
	for count in army.get("military_inventory",{}).values():spare+=int(count)
	for formation:Dictionary in army.get("formations",[]):
		equipped+=int(formation.get("equipment",0));required+=int(formation.get("equipment_required",0))
	var deployed:=MilitaryCampaign.field_army_active_personnel()>0
	var repairs:Array[String]=[]
	var upkeep=preload("res://scripts/routine_military_upkeep.gd")
	var repair_items:Array=army.get("damaged_equipment",{}).keys()
	for job:Dictionary in MilitaryCampaign.equipment_queue:
		if (job.get("job_type","")=="repair" or job.has("repair_pending")) and job.get("item","") not in repair_items:repair_items.append(job.item)
	for item:String in repair_items:
		var underway:int=upkeep.pending(MilitaryCampaign,item);damaged+=underway
		if int(army.get("damaged_equipment",{}).get(item,0))+underway>0:repairs.append("%s: %s" % [MilitaryCampaign.PersistentProduction.product_name(item),upkeep.status(MilitaryCampaign,item)])
	return [
		{"id":"food","label":"DAILY RATIONS","value":"%.1f" % float(army.get("provisions_required_today",0)),"note":"Military provisions required each day"},
		{"id":"delivery","label":"FIELD SUPPLY","value":"%.0f%%" % (MilitaryCampaign.field_provision_delivery_ratio()*100) if deployed else "No field army","note":"Share of field ration requirements delivered"},
		{"id":"gear","label":"HOME FORCE EQUIPMENT","value":"%d / %d" % [equipped,required],"note":"%d missing sets · %d spare sets" % [maxi(0,required-equipped),spare]},
		{"id":"repair","label":"STAFF-MANAGED REPAIRS","value":str(damaged),"note":"No damaged equipment waiting" if repairs.is_empty() else "\n".join(repairs)}]

func _support()->void:
	_label(body,"READINESS & SUPPLY · "+{"army":"ARMY","navy":"NAVY","air":"AIR FORCE"}[service],18)
	_wrapped(body,"Staff issue equipment and arrange repairs. Shortages and delays appear here; manufacturing stays in Production.")
	for item:Dictionary in _support_data():
		var card:=PanelContainer.new();card.add_theme_stylebox_override("panel",_skin(Color("17272d"),Color("354951"),14));body.add_child(card)
		var column:=VBoxContainer.new();column.add_theme_constant_override("separation",5);card.add_child(column)
		_label(column,String(item.label),11,MUTED)
		support_labels[item.id]={"value":_label(column,String(item.value),23),"note":_wrapped(column,String(item.note))}
	_button(body,"Military production ↗",_production)

func _update_support()->void:
	var items:=_support_data()
	if items.size()!=support_labels.size():_build_body();return
	for item:Dictionary in items:
		if not support_labels.has(item.id):_build_body();return
		support_labels[item.id].value.text=String(item.value)
		support_labels[item.id].note.text=String(item.note)

func _management(sub:int)->void:
	_show_page("support" if sub==3 else "recruitment")

func _show_page(value:String)->void:
	page=value;training_view=page=="training";selected_row={};editor_id=-1
	scroll.scroll_vertical=0;_build_body()

func _map_command()->void:
	MilitaryCampaign.joint_operations.open_hierarchy(service)
	var command=MilitaryCampaign.joint_operations.screen
	if not is_instance_valid(command):return
	panel.hide()
	command.tree_exited.connect(func():
		if not is_queued_for_deletion():panel.show();_build_body())

func _input(event:InputEvent)->void:
	if not panel.visible:return
	if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:
		get_viewport().set_input_as_handled();queue_free()
	elif event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT and not panel.get_global_rect().has_point(event.position):
		get_viewport().set_input_as_handled();queue_free()

func _process(delta:float)->void:
	if not panel.visible:return
	_layout();timer+=delta
	if timer<.5:return
	timer=0
	if page=="support":_update_support();return
	if page=="recruitment":return # The embedded recruitment board owns live updates.
	if training_view:_update_policy();return
	var rows:=_rows();_update_hero(rows)
	var visible:=_filtered(rows)
	if _signature(visible)!=rows_signature:_build_body();return
	for i in mini(visible.size(),bindings.size()):_update_row(bindings[i],visible[i])
	for row:Dictionary in rows:
		if row.id==selected_row.get("id",""):selected_row=row;_update_inspection();break

func _label(parent:Node,text:String,size:int=15,color:Color=TEXT)->Label:
	var node:=Label.new();node.text=text;node.add_theme_font_size_override("font_size",size);node.add_theme_color_override("font_color",color);parent.add_child(node);return node
func _wrapped(parent:Node,text:String,size:int=14,color:Color=MUTED)->Label:
	var node:=_label(parent,text,size,color);node.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;return node
func _button(parent:Node,text:String,callback:Callable)->Button:
	var node:=Button.new();node.text=text;node.custom_minimum_size.y=34;node.add_theme_font_size_override("font_size",14)
	node.add_theme_color_override("font_color",TEXT);node.add_theme_color_override("font_pressed_color",Art.COLORS[service])
	node.add_theme_stylebox_override("normal",_skin(Color("182a33"),Color("2b434c"),9))
	node.add_theme_stylebox_override("hover",_skin(Color("28404a"),Color("708b8d"),9))
	node.add_theme_stylebox_override("pressed",_skin(Color("293936"),Art.COLORS[service],9))
	node.add_theme_stylebox_override("focus",_skin(Color.TRANSPARENT,Art.COLORS[service],9))
	node.pressed.connect(callback);parent.add_child(node);return node
func _bar(parent:Node,color:Color,mode:String="segments")->ProgressBar:
	var bar:ProgressBar=Gauge.new();bar.ink=color;bar.mode=mode;bar.size_flags_horizontal=Control.SIZE_EXPAND_FILL;parent.add_child(bar);return bar
func _clear()->void:
	for child in body.get_children():body.remove_child(child);child.queue_free()
	bindings.clear();policy_buttons.clear();policy_cards.clear();service_indicators.clear();hero_values.clear();summary_costs.clear();inspection_labels.clear();support_labels.clear();policy_grid=null

func _build_body()->void:
	var saved_scroll:=scroll.scroll_vertical
	_clear();heading.text="MILITARY · "+{"army":"ARMY","navy":"FLEET","air":"AIR FORCE"}[service]
	management_button.text={"army":"Recruit & deploy","navy":"Fleet preparation","air":"Air preparation"}[service]
	for domain in service_buttons:
		service_buttons[domain].set_pressed_no_signal(domain==service)
		service_buttons[domain].add_theme_color_override("font_pressed_color",Art.COLORS[domain])
		service_buttons[domain].add_theme_stylebox_override("pressed",_skin(Color("293936"),Art.COLORS[domain],9))
	for button:Button in page_buttons.values():
		button.add_theme_color_override("font_pressed_color",Art.COLORS[service])
		button.add_theme_stylebox_override("pressed",_skin(Color("293936"),Art.COLORS[service],9))
	if training_view:page="training"
	for key:String in page_buttons:page_buttons[key].set_pressed_no_signal(page==key)
	if page=="recruitment":_recruitment();return
	if page=="support":_support();return
	var rows:=_rows();_hero(rows)
	if training_view:_policy();scroll.set_deferred("scroll_vertical",saved_scroll);return
	var filters:=HBoxContainer.new();filters.add_theme_constant_override("separation",6);body.add_child(filters)
	for definition:Array in [["all","All forces"],["attention","Needs attention"],["training","In training"]]:
		var choice:=String(definition[0]);var button:=_button(filters,String(definition[1]),func():roster_filter=choice;_build_body())
		button.toggle_mode=true;button.set_pressed_no_signal(roster_filter==choice)
	var visible:=_filtered(rows);rows_signature=_signature(visible)
	if rows.is_empty():
		var empty:=PanelContainer.new();empty.add_theme_stylebox_override("panel",_skin(Color("14252d")));body.add_child(empty)
		var content:=VBoxContainer.new();content.add_theme_constant_override("separation",10);empty.add_child(content)
		_label(content,{"army":"Build your first formation","navy":"Your fleet starts here","air":"Prepare your first air wing"}[service],21)
		_wrapped(content,"Choose a training commitment now. Staff will prepare eligible units as they enter service.")
		_button(content,"Set training strategy",func():training_view=true;_build_body())
	elif visible.is_empty():_wrapped(body,"No forces match this filter.")
	for data:Dictionary in visible:
		_unit_card(data)
		if data.id==selected_row.get("id",""):selected_row=data;_inspection()
	scroll.set_deferred("scroll_vertical",saved_scroll)

func _hero(rows:Array[Dictionary])->void:
	var early_paper:=service in ["army","navy"] and Art.Early.active()
	var hero:=PanelContainer.new();hero.custom_minimum_size.y=76;hero.clip_contents=true
	hero.add_theme_stylebox_override("panel",_skin(Color("17272d"),Color("354951"),0));body.add_child(hero)
	if early_paper:
		hero.custom_minimum_size.y=128
		hero.add_theme_stylebox_override("panel",_skin(Color("eee8da"),Color("b4a78f"),0))
	var image:=TextureRect.new();image.texture=Art.artwork(service);image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED;image.mouse_filter=Control.MOUSE_FILTER_IGNORE;hero.add_child(image)
	if early_paper:image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var margin:=MarginContainer.new()
	for edge:String in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+edge,12)
	hero.add_child(margin)
	var summary:=HBoxContainer.new();summary.add_theme_constant_override("separation",22);margin.add_child(summary)
	for definition:Array in [["formations",{"army":"FORCE GROUPS","navy":"TASK FORCES","air":"AIR WINGS"}[service]],["strength",{"army":"LISTED SOLDIERS","navy":"VESSELS","air":"AIRCRAFT"}[service]],["attention","NEED ATTENTION"]]:
		var box:=VBoxContainer.new();box.add_theme_constant_override("separation",1);summary.add_child(box)
		hero_values[definition[0]]=_label(box,"0",24,Color("292d29") if early_paper else TEXT)
		_label(box,definition[1],10,Color("4d574e") if early_paper else Color("c3ced1"))
	var space:=Control.new();space.size_flags_horizontal=Control.SIZE_EXPAND_FILL;summary.add_child(space)
	policy_shortcut=_button(summary,"",func():training_view=true;_build_body());policy_shortcut.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	_update_hero(rows)
func _update_hero(rows:Array[Dictionary])->void:
	if hero_values.is_empty():return
	var strength:=0;var attention:=0;var unknown:=false
	for row:Dictionary in rows:
		strength+=int(row.count);attention+=int(_attention(row));unknown=unknown or bool(row.get("unknown",false))
	hero_values.formations.text=str(rows.size());hero_values.strength.text=str(strength)+( "+" if unknown else "")
	hero_values.strength.tooltip_text="Includes dated field reports; unreported strength is not guessed."
	hero_values.attention.text=str(attention);hero_values.attention.add_theme_color_override("font_color",WARNING if attention else GOOD)
	if service in ["army","navy"] and Art.Early.active():hero_values.attention.add_theme_color_override("font_color",Color("874522") if attention else Color("3f6041"))
	policy_shortcut.text="Training · %s ›" % MilitaryCampaign.training_staff.policy(service).label

func _training_level(drill:float)->String:
	return ["Untrained","Basic","Trained","Well drilled","Fully drilled"][clampi(floori(drill*5),0,4)]

func _attention_reasons(data:Dictionary)->Array[String]:
	var reasons:Array[String]=[]
	if bool(data.get("unknown",false)):return ["Awaiting field report"]
	var required:=int(data.get("gear_required",data.get("authorized",0)))
	var equipped:=int(data.get("gear",roundi(float(data.get("equipment",1))*required)))
	if equipped<required and (float(data.get("equipment",1))<.8 or bool(data.get("needs_attention",false))):
		reasons.append("Missing gear: %d of %d" % [required-equipped,required])
	if float(data.get("condition",1))<.75:reasons.append("Poor condition: %d%%" % roundi(float(data.condition)*100))
	elif bool(data.get("poor_condition",false)):reasons.append("Some formations in poor condition")
	var shortfall:=int(data.get("authorized",0))-int(data.get("count",0))
	if shortfall>0:reasons.append("Short %d %s" % [shortfall,{"army":"soldiers","navy":"vessels","air":"aircraft"}[service]])
	var activity:=String(data.get("activity",""))
	if "waiting" in activity.to_lower() or "paused" in activity.to_lower():reasons.append(activity)
	return reasons

func _attention(data:Dictionary)->bool:
	return not _attention_reasons(data).is_empty()
func _filtered(rows:Array[Dictionary])->Array[Dictionary]:
	if roster_filter=="attention":return rows.filter(_attention)
	if roster_filter=="training":return rows.filter(func(data:Dictionary)->bool:return bool(data.get("in_training",false)))
	return rows
func _signature(rows:Array)->String:
	var keys:Array=[]
	for row:Dictionary in rows:keys.append([row.id,row.get("type_id",""),row.get("unknown",false)])
	return str(keys)

func _unit_card(data:Dictionary)->void:
	var selected:bool=data.id==selected_row.get("id","")
	var card:=PanelContainer.new();card.add_theme_stylebox_override("panel",_skin(Color("182b32"),Art.COLORS[service] if selected else Color("2b444d"),7));body.add_child(card)
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",12);card.add_child(row)
	var art:=PanelContainer.new();art.custom_minimum_size=Vector2(68,82);art.clip_contents=true
	if Art.Early.active() and Art.EARLY_UNITS.has(String(data.get("type_id",""))) and not bool(data.get("unknown",false)):art.custom_minimum_size=Vector2(112,84)
	art.add_theme_stylebox_override("panel",_skin(Color("0e1d25"),Color("344c55"),0));row.add_child(art)
	var portrait:Control=portraits.portrait(String(data.get("type_id","")),service,bool(data.get("unknown",false)));art.add_child(portrait)
	var names:=VBoxContainer.new();names.custom_minimum_size.x=118;names.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	names.size_flags_vertical=Control.SIZE_SHRINK_CENTER;names.add_theme_constant_override("separation",4);row.add_child(names)
	var title:=_label(names,String(data.name),16);title.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;title.tooltip_text=String(data.name)
	var location:=_label(names,String(data.location),11,MUTED);location.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;location.tooltip_text=String(data.location)
	var binding:Dictionary={"title":title,"location":location,"card":card,"portrait":portrait}
	for key:String in ["personnel","equipment","skill"]:
		var cell:=VBoxContainer.new();cell.custom_minimum_size.x=84;cell.size_flags_horizontal=Control.SIZE_EXPAND_FILL;cell.size_flags_vertical=Control.SIZE_SHRINK_CENTER
		cell.add_theme_constant_override("separation",2);row.add_child(cell)
		var heading_row:=HBoxContainer.new();cell.add_child(heading_row)
		var icon:=TextureRect.new();icon.texture=Art.symbol({"personnel":"people","equipment":"equipment","skill":"skill"}[key],MUTED);icon.custom_minimum_size=Vector2(14,14);icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;heading_row.add_child(icon)
		_label(heading_row,{"personnel":"PERSONNEL" if service=="army" else "STRENGTH","equipment":"GEAR","skill":"TRAINING"}[key],9,MUTED)
		binding[key]=_label(cell,"",16)
		binding[key+"_bar"]=_bar(cell,Art.COLORS[service] if key=="skill" else GOOD,{"personnel":"people","equipment":"segments","skill":"patch"}[key])
		binding[key+"_bar"].marks=5
		if key=="skill":
			binding.skill_bar.custom_minimum_size=Vector2(44,32)
			binding.skill_bar.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
		binding[key+"_note"]=_label(cell,"",10,MUTED);binding[key+"_note"].text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	var activity:=VBoxContainer.new();activity.custom_minimum_size.x=104;activity.size_flags_horizontal=Control.SIZE_EXPAND_FILL;activity.size_flags_vertical=Control.SIZE_SHRINK_CENTER;row.add_child(activity)
	binding.activity=_label(activity,"",12,Art.COLORS[service]);binding.activity.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	binding.activity_bar=_bar(activity,Art.COLORS[service]);binding.activity_bar.custom_minimum_size.x=70
	binding.activity_note=_label(activity,"",10,MUTED);binding.activity_note.visible=false
	var chosen:=data.duplicate(true)
	var select:=func():selected_row={} if selected else chosen;_build_body()
	var details:=_button(row,"⌃" if selected else "›",select);details.custom_minimum_size=Vector2(26,32);details.size_flags_vertical=Control.SIZE_SHRINK_CENTER;details.tooltip_text="Formation details"
	card.mouse_filter=Control.MOUSE_FILTER_STOP
	card.gui_input.connect(func(event:InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:card.accept_event();select.call())
	bindings.append(binding);_update_row(binding,data)

func _update_row(binding:Dictionary,data:Dictionary)->void:
	binding.title.text=String(data.name);binding.location.text=String(data.location)
	if bool(data.get("unknown",false)):
		binding.personnel.text="%d reported" % int(data.count) if int(data.count)>0 else "Unreported"
		binding.equipment.text="Not reported";binding.skill.text="Not reported";binding.activity.text="◌ Awaiting report"
		for key:String in ["personnel","equipment","skill","activity"]:binding[key+"_bar"].visible=false;binding[key+"_note"].text=""
		return
	binding.personnel.text="%d %s" % [data.count,{"army":"soldiers","navy":"vessels","air":"aircraft"}[service]];binding.personnel_bar.value=float(data.count)/maxf(1,data.authorized)*100
	binding.personnel_bar.marks=clampi(int(data.authorized),1,5)
	binding.personnel_note.text="%d planned · Condition %d%%" % [data.authorized,roundi(data.condition*100)]
	binding.personnel_bar.visible=false
	binding.equipment.text="%d%%" % roundi(data.equipment*100);binding.equipment_bar.value=data.equipment*100
	binding.equipment_bar.ink=WARNING if data.equipment<.8 else GOOD;binding.equipment.add_theme_color_override("font_color",WARNING if data.equipment<.8 else TEXT)
	binding.equipment_note.text=String(data.equipment_note);binding.equipment_note.tooltip_text=String(data.equipment_note)
	binding.skill.text=_training_level(float(data.skill));binding.skill_bar.value=data.skill*100
	binding.skill_note.text="Drill %d%% · Experience %d%%" % [roundi(data.skill*100),roundi(data.experience*100)]
	var activity:=String(data.activity)
	if activity=="On duty / reserve":activity="Needs gear" if data.equipment<.8 else "Reserve"
	var reasons:=_attention_reasons(data)
	binding.activity.text="\n".join(reasons) if not reasons.is_empty() else activity;binding.activity_bar.value=data.progress*100
	binding.activity_bar.visible=data.progress>0 and bool(data.get("in_training",false))
	binding.activity_note.text=String(data.training_note);binding.activity.tooltip_text="\n".join(reasons)+"\n"+String(data.training_note)
	binding.activity_note.visible=false
	for key:String in ["personnel","equipment","skill"]:binding[key+"_bar"].queue_redraw()
func _rows()->Array[Dictionary]:
	var raw:=_raw_rows()
	return preload("res://scripts/hud/army_roster_groups.gd").group(raw) if service=="army" else raw

func _raw_rows()->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	var campaign=MilitaryCampaign
	if service=="army":
		var forces:Array=[{"force":campaign.home_army,"location":"Home reserve","key":"home"}]
		var snapshot:Dictionary=campaign.field_armies_snapshot()
		for army:Dictionary in snapshot.get("armies",[]):
			var home:bool=String(army.get("location_id",""))=="player_home" and army.get("status","")=="stationed"
			var report:Dictionary=army.get("last_report",{})
			if not home and not bool(snapshot.get("live_reports",false)):
				if report.get("formations",[]).is_empty():
					result.append({"id":"field:%s" % army.get("army_id",army.get("id",0)),"type_id":"","name":String(army.get("name","Field army")),"glyph":"⚑","location":"Awaiting formation report","count":int(report.get("troops",0)),"unknown":true});continue
				forces.append({"force":report,"key":"field:%s" % army.get("army_id",army.get("id",0)),"location":"%s · report %dd old" % [army.get("name","Field army"),maxi(0,int(GameState.elapsed_days)-int(report.get("day",0)))]})
			else:forces.append({"force":army,"key":"field:%s" % army.get("army_id",army.get("id",0)),"location":army.get("name","Field army")})
		for occupation:Dictionary in campaign.occupation_forces:forces.append({"force":occupation,"key":"garrison:%s:%s" % [occupation.get("civ_id",""),occupation.get("region_id",campaign.occupation_forces.find(occupation))],"location":String(occupation.get("region_name","Occupied settlement"))+" garrison"})
		for group:Dictionary in forces:
			for unit:Dictionary in group.force.get("formations",[]):
				var count:=int(unit.get("count",0));var attending:=int(unit.get("training_attending",0)) if not "report" in String(group.location) else 0
				var type_id:=String(unit.get("unit","levy"))
				var glyph:="♞" if type_id in ["cavalry","horse_archer","mounted_archer"] else "➶" if String(unit.get("weapon",""))=="bow" else "⚔"
				result.append({"id":"%s:%s" % [group.key,unit.get("id",group.force.get("formations",[]).find(unit))],"group_key":group.key,"group_name":"Home reserve" if group.key=="home" else String(group.location),"equipment_count":int(unit.get("equipment",0)),"equipment_required":int(unit.get("equipment_required",count)),"type_id":type_id,"purpose":campaign.UnitCatalog.archetype(type_id).get("purpose",""),"weapon":String(unit.get("weapon","")),"name":campaign.UnitCatalog.archetype(type_id).get("label",type_id),"glyph":glyph,"location":group.location,"count":count,"authorized":int(unit.get("authorized_count",count)),"condition":float(unit.get("personnel_condition",1)),"equipment":float(unit.get("equipment",0))/maxf(1,unit.get("equipment_required",count)),"equipment_note":("Ammo %d / %d" % [unit.get("ammunition",0),unit.get("ammunition_required",0)] if int(unit.get("ammunition_required",0))>0 else "No ammo needed"),"skill":float(unit.get("training",0)),"experience":float(unit.get("experience",0)),"in_training":attending>0,"activity":"Staff training" if attending>0 else "On duty / reserve","progress":float(campaign.training_program.get("progress_days",0))/maxf(1,campaign.training_program.get("duration_days",1)) if attending>0 else 0.0,"training_note":"%d soldiers rotating" % attending if attending>0 else "Policy: "+String(campaign.training_staff.policy(service).label)})
		for trainee:Dictionary in campaign.training_queue:
			var count:=int(trainee.get("count",0));var days:=float(trainee.get("required_days",1));var progress:=float(trainee.get("progress_days",0))
			result.append({"id":"recruit:%s" % trainee.get("id",campaign.training_queue.find(trainee)),"group_key":"recruit:%s" % trainee.get("deployment_line",trainee.get("build_batch","legacy")),"group_name":String(campaign.recruit_deploy.line(int(trainee.deployment_line)).get("name","Recruitment line %s" % trainee.deployment_line)) if trainee.has("deployment_line") else "Initial instruction","type_id":String(trainee.get("unit","levy")),"name":campaign.UnitCatalog.archetype(String(trainee.get("unit","levy"))).get("label","Recruits"),"glyph":"◇","location":"Initial instruction","count":count,"authorized":int(trainee.get("initial_count",count)),"condition":float(trainee.get("personnel_condition",1)),"equipment":float(trainee.get("equipment_access_today",0)),"equipment_note":"Training equipment access","skill":0.0,"experience":float(trainee.get("experience",0)),"in_training":true,"activity":"Initial training","progress":progress/maxf(1,days),"training_note":"%.0f / %.0f instruction days" % [progress,days]})
	else:
		var op=campaign.joint_operations
		for unit:Dictionary in op.state.forces:
			if unit.owner!="player" or unit.domain!=service:continue
			var authorized:=0
			for amount in unit.authorized.values():authorized+=int(amount)
			var staff_status:=String(unit.get("training_status",""))
			var staff_report:Dictionary=campaign.training_staff.service_force_report(unit,maxi(int(op.state.last_day),int(unit.get("staff_training_day",-1))))
			var exercising:bool=staff_report.group=="training" and float(unit.training)>=1.0
			var activity:=staff_status if exercising else String(unit.status)
			var note:=String(unit.status) if exercising else staff_status
			if note==activity or note=="":note="Policy: "+String(campaign.training_staff.policy(service).label)
			var type_id:="";var largest:=0
			for kind:String in unit.units:
				if int(unit.units[kind])>largest:type_id=kind;largest=int(unit.units[kind])
			result.append({"id":"%s:%s" % [service,unit.id],"type_id":type_id,"purpose":String(op.C.UNITS.get(type_id,{}).get("purpose","")),"name":unit.name,"glyph":"⚓" if service=="navy" else "✈","location":op.base(int(unit.base_id)).get("name","Base unavailable"),"count":op.hardware(unit),"authorized":authorized,"condition":float(unit.condition),"equipment":float(op.hardware(unit))/maxf(1,authorized),"equipment_note":"%d crew" % op.crew(unit),"skill":float(unit.get("proficiency",.45 if float(unit.training)>=1 else 0)),"experience":float(unit.experience),"in_training":staff_report.group=="training","activity":activity,"progress":float(unit.training) if float(unit.training)<1.0 else 0.0,"training_note":note})
	return result
func _inspection()->void:
	var panel_detail:=PanelContainer.new();panel_detail.add_theme_stylebox_override("panel",_skin(Color("11242c"),Color("43616a"),16));body.add_child(panel_detail)
	var layout:=VBoxContainer.new();layout.add_theme_constant_override("separation",9);panel_detail.add_child(layout)
	_label(layout,{"army":"FORCE COMPOSITION","navy":"TASK FORCE BRIEF","air":"AIR WING BRIEF"}[service],11,Art.COLORS[service])
	inspection_labels.name=_label(layout,String(selected_row.name),21)
	if bool(selected_row.get("unknown",false)):
		_wrapped(layout,"Awaiting a dated report of this army’s formations and equipment.");return
	inspection_labels.purpose=_wrapped(layout,String(selected_row.get("purpose","Service staff prepare this force under your standing policy.")),15,TEXT)
	inspection_labels.skills=_label(layout,"",14,Art.COLORS[service])
	inspection_labels.composition=_wrapped(layout,"",14,TEXT)
	inspection_labels.activity=_wrapped(layout,"",14)
	var buttons:=HFlowContainer.new();layout.add_child(buttons)
	if service=="army":_button(buttons,"Recruit & deploy",func():_management(1))
	_button(buttons,"Adjust training commitment",func():training_view=true;selected_row={};_build_body())
	_button(buttons,"Command on map ↗",_map_command)
	_update_inspection()
func _update_inspection()->void:
	if inspection_labels.is_empty() or selected_row.is_empty():return
	inspection_labels.name.text=String(selected_row.name)
	if bool(selected_row.get("unknown",false)):return
	inspection_labels.composition.text=String(selected_row.get("composition",""))
	inspection_labels.skills.text="Drill %d%%  ·  Experience %d%%  ·  Condition %d%%" % [roundi(selected_row.skill*100),roundi(selected_row.experience*100),roundi(selected_row.condition*100)]
	inspection_labels.activity.text=" · ".join(_attention_reasons(selected_row))+"\n"+String(selected_row.training_note)

func _policy()->void:
	_label(body,"How much should we train?",23)
	_wrapped(body,"Choose the commitment. Service staff rotate units, run exercises and pause for shortages or emergencies.")
	policy_grid=GridContainer.new();policy_grid.columns=4 if panel.size.x>=920 else 2
	policy_grid.add_theme_constant_override("h_separation",10);policy_grid.add_theme_constant_override("v_separation",10);body.add_child(policy_grid)
	for id:String in MilitaryCampaign.training_staff.POLICIES:
		var definition:Dictionary=MilitaryCampaign.training_staff.POLICIES[id]
		var outer:=PanelContainer.new();outer.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		outer.add_theme_stylebox_override("panel",_skin(Color("172b33"),Color("314950"),12));policy_grid.add_child(outer);policy_cards[id]=outer
		var card:=VBoxContainer.new();card.add_theme_constant_override("separation",9);outer.add_child(card)
		var choice:=id
		var button:=_button(card,String(definition.label),func():MilitaryCampaign.training_staff.set_policy(service,choice);_update_policy())
		button.toggle_mode=true;button.custom_minimum_size.y=38;policy_buttons[id]=button
		var icons:ProgressBar=_bar(card,Art.COLORS[service],"people");icons.marks=20;icons.value=float(definition.share)*100;icons.custom_minimum_size.y=26
		_label(card,"%d%% rotate" % roundi(float(definition.share)*100),23)
		_label(card,"Target drill  %d%%" % roundi(float(definition.target)*100),13,Art.COLORS[service])
		var skill:=_bar(card,Art.COLORS[service],"patch");skill.value=float(definition.target)*100
		skill.custom_minimum_size=Vector2(44,32);skill.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
		var description:=_wrapped(card,String(definition.description),12);description.custom_minimum_size.x=140
		var effort:=_label(card,{"suspended":"CONSERVE STORES","maintain":"LOW COMMITMENT","regular":"SUSTAINED COMMITMENT","intensive":"HIGH COMMITMENT"}[id],10,MUTED)
		effort.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	if service!="army":
		var overview:=GridContainer.new();overview.columns=4;overview.add_theme_constant_override("h_separation",10);body.add_child(overview)
		for definition:Array in [["training","TRAINING","88c5a6"],["assigned","ASSIGNED","88b6ce"],["target","TARGET MET","dfb967"],["paused","PAUSED","dc9a7e"]]:
			var card:=VBoxContainer.new();card.size_flags_horizontal=Control.SIZE_EXPAND_FILL;overview.add_child(card)
			var value:=_label(card,"0",27,Color(definition[2]));_label(card,String(definition[1]),10,MUTED)
			var bar:=_bar(card,Color(definition[2]));service_indicators[definition[0]]={"value":value,"bar":bar,"card":card}
		_wrapped(body,"Counts are task forces or wings. Staff review policy each day.",12)
	policy_status=_wrapped(body,"",14,TEXT)
	var investment:=HFlowContainer.new();investment.add_theme_constant_override("h_separation",16);body.add_child(investment)
	for definition:Array in [["food","EXTRA RATIONS USED","supply"],["materials","TRAINING MATERIALS USED","equipment"],["time","INITIAL INSTRUCTION","calendar"]]:
		var box:=PanelContainer.new();box.add_theme_stylebox_override("panel",_skin(Color("17282f")));box.custom_minimum_size.x=180;investment.add_child(box)
		var content:=HBoxContainer.new();content.add_theme_constant_override("separation",9);box.add_child(content)
		var icon:=TextureRect.new();icon.texture=Art.symbol(definition[2],Art.COLORS[service]);icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.custom_minimum_size=Vector2(30,30);content.add_child(icon)
		var text:=VBoxContainer.new();content.add_child(text);summary_costs[definition[0]]=_label(text,"",21);_label(text,definition[1],10,MUTED)
	_wrapped(body,"Instruction takes effective training days; shortages pause progress. Army exercises take 72–252 effective days. Staff protect seven days of civilian food.",12)
	_update_policy()
func _update_policy()->void:
	var state:Dictionary=MilitaryCampaign.training_staff.snapshot(service)
	_update_hero(_rows())
	for id in policy_buttons:
		policy_buttons[id].set_pressed_no_signal(id==state.id)
		policy_cards[id].add_theme_stylebox_override("panel",_skin(Color("223632") if id==state.id else Color("172b33"),Art.COLORS[service] if id==state.id else Color("314950"),12))
	for group in service_indicators:
		var indicator:Dictionary=service_indicators[group]
		indicator.value.text=str(state.groups[group]);indicator.bar.value=float(state.groups[group])/maxf(1,state.forces)*100
		var tips:Dictionary={"training":"Crews in instruction or training rotations; other qualified crews may still operate.","assigned":"Forces committed to missions or travel without a training rotation.","target":"Crews at home whose proficiency meets the selected target.","paused":String(state.get("pause_details","No paused training."))}
		indicator.card.tooltip_text=tips[group];indicator.value.tooltip_text=tips[group];indicator.bar.tooltip_text=tips[group]
	policy_status.text=String(state.status)
	if service=="army" and not state.active.is_empty():policy_status.text+="\n%s · %.0f / %.0f effective days" % [state.active.label,state.active.progress_days,state.active.duration_days]
	summary_costs.food.text="%.1f" % state.food_spent;summary_costs.materials.text="%.1f" % state.materials_spent
	summary_costs.time.text="45+ days" if service=="army" else "90+ days"
