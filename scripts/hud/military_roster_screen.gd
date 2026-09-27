extends CanvasLayer
## The military screen over the real world: forces, recruitment, training and
## supply. Every figure comes from the existing reports; the Forces page says in
## plain words what each force is, what it lacks, who is fixing it and what the
## ruler can do next (hud/military_force_story.gd). Paper and ink, as the court
## and production screens.
const Art=preload("res://scripts/hud/military_roster_visuals.gd")
const Gauge=preload("res://scripts/hud/military_roster_gauge.gd")
const Story=preload("res://scripts/hud/military_force_story.gd")
const T=preload("res://scripts/hud/hud_tokens.gd")
const EraWords=preload("res://scripts/hud/era_words.gd")
var TEXT:=T.INK
var MUTED:=T.INK_MUTED
var GOOD:=T.GREEN
var WARNING:=T.AMBER
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
var notice:=""
var notice_label:Label
var stories:Dictionary={}

func accent(domain:String="")->Color:
	return {"army":T.GOLD,"navy":T.TEAL,"air":T.BLUE}.get(service if domain.is_empty() else domain,T.GOLD)

func _ready()->void:
	layer=87;portraits=Art.new();add_child(portraits)
	panel=PanelContainer.new();add_child(panel)
	var sheet:=T.paper_panel_style(false,T.RADIUS_CARD,24);sheet.border_color=T.RULE_STRONG
	sheet.shadow_color=Color(0,0,0,.18 if T.is_light() else .45);sheet.shadow_size=18;sheet.shadow_offset=Vector2(0,6)
	panel.add_theme_stylebox_override("panel",sheet)
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",12);panel.add_child(column)
	var header:=HBoxContainer.new();header.add_theme_constant_override("separation",8);column.add_child(header)
	heading=Label.new();T.text(heading,"title",TEXT);heading.size_flags_horizontal=Control.SIZE_EXPAND_FILL;header.add_child(heading)
	# No fleet before boats, no air service before flight: a service the people
	# cannot yet field is not offered as a tab.
	var services:Array[String]=["army"]
	if EraWords.has_boats():services.append("navy")
	if EraWords.has_flight():services.append("air")
	if service not in services:service="army"
	for domain:String in services:
		var choice:=domain
		var button:=_button(header,_service_name(domain),func():service=choice;selected_row={};roster_filter="all";scroll.scroll_vertical=0;_build_body())
		button.icon=Art.symbol(domain,accent(domain),22)
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
	var rule:=ColorRect.new();rule.color=T.RULE;rule.custom_minimum_size.y=1;column.add_child(rule)
	scroll=ScrollContainer.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;column.add_child(scroll)
	body=VBoxContainer.new();body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;body.add_theme_constant_override("separation",10);scroll.add_child(body)
	_layout();_build_body()

func _service_name(domain:String)->String:
	if domain=="navy":return "Boats" if EraWords.hearth() else "Fleet"
	return {"army":"Army","air":"Air force"}.get(domain,"Army")

func _skin(bg:Color,border:Color=Color.TRANSPARENT,margin:int=10)->StyleBoxFlat:
	var style:=StyleBoxFlat.new();style.bg_color=bg;style.border_color=border;style.set_border_width_all(1 if border.a>0 else 0)
	style.set_corner_radius_all(T.RADIUS_CARD);style.set_content_margin_all(margin);return style

func _layout()->void:
	var view:=get_viewport().get_visible_rect().size
	if view!=layout_size:
		layout_size=view
		var inset:=maxf(16,view.x*.045)
		panel.position=Vector2(inset,64);panel.size=Vector2(view.x-inset*2,view.y-100)
	if is_instance_valid(body):
		var column:VBoxContainer=panel.get_child(0)
		var content_height:=48.0+column.get_theme_constant("separation")*(column.get_child_count()-1)+body.get_combined_minimum_size().y
		for child:Control in column.get_children():
			if child!=scroll:content_height+=child.get_combined_minimum_size().y
		panel.size.y=clampf(content_height+2,300,maxf(300,view.y-100))
	if is_instance_valid(policy_grid):policy_grid.columns=4 if panel.size.x>=920 else 2

func _production()->void:
	var scene:=get_tree().current_scene
	if scene!=null and "hud" in scene and scene.hud:scene.hud.open_dock("production",2)

func _recruitment()->void:
	if service!="army":
		_wrapped(body,"Crews and craft are organized through command. New craft are made in Production.")
		var row:=HFlowContainer.new();row.add_theme_constant_override("h_separation",8);body.add_child(row)
		_button(row,"Service command",_map_command)
		_button(row,"Military production ↗",_production)
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
	if template.is_empty():_wrapped(body,"This design no longer exists.");return
	T.text(_label(body,Story.sentence_name(String(template.name))),"voice",TEXT)
	_wrapped(body,"A formation design sets how many people and which weapons to recruit. Changing it does not create troops.")
	for entry:Dictionary in template.entries:
		var unit:=String(entry.unit);var weapon:=String(entry.weapon)
		var row:=HBoxContainer.new();body.add_child(row)
		var name_label:=_label(row,"%s · %s" % [unit.replace("_"," ").capitalize(),MilitaryCampaign.PersistentProduction.product_name(weapon)])
		name_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		_label(row,str(entry.count))
		for amount:int in [-10,-1,1,10]:
			var change:=amount
			_button(row,"%+d" % change,func():MilitaryCampaign.adjust_template_entry(editor_id,unit,weapon,change);_build_body())
	_kicker(body,"ADD TO THIS FORMATION")
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
		{"id":"food","label":"FOOD EACH DAY","value":_amount(float(army.get("provisions_required_today",0))),"note":"Rations the fighting people eat each day"},
		{"id":"delivery","label":"FOOD REACHING THE FIELD","value":"%.0f%%" % (MilitaryCampaign.field_provision_delivery_ratio()*100) if deployed else "No one in the field","note":"Share of the field army's rations that arrive"},
		{"id":"gear","label":"WEAPONS AT HOME","value":"%d of %d" % [equipped,required],"note":"%d still missing · %d spare in stores" % [maxi(0,required-equipped),spare]},
		{"id":"repair","label":"WEAPONS BEING MENDED","value":str(damaged),"note":"Nothing broken is waiting" if repairs.is_empty() else "\n".join(repairs)}]

func _amount(value:float)->String:
	return "none" if value<.05 else ("%.1f" % value if value<10 else Story.number(roundi(value)))

func _support()->void:
	T.text(_label(body,"Readiness and supply"),"voice",TEXT)
	_wrapped(body,"Staff hand out weapons and arrange repairs. Shortages and delays show here; making things belongs in Production.")
	var grid:=GridContainer.new();grid.columns=2 if panel.size.x>=760 else 1;grid.add_theme_constant_override("h_separation",12);grid.add_theme_constant_override("v_separation",12);body.add_child(grid)
	for item:Dictionary in _support_data():
		var card:=PanelContainer.new();card.size_flags_horizontal=Control.SIZE_EXPAND_FILL;card.add_theme_stylebox_override("panel",_skin(T.PAPER_RAISED,T.RULE,16));grid.add_child(card)
		var column:=VBoxContainer.new();column.add_theme_constant_override("separation",6);card.add_child(column)
		_kicker(column,String(item.label))
		var value:=_label(column,String(item.value));T.text(value,"value",TEXT)
		support_labels[item.id]={"value":value,"note":_wrapped(column,String(item.note))}
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
	timer=0;stories.clear()
	if page=="support":_update_support();return
	if page=="recruitment":return # The embedded recruitment board owns live updates.
	if training_view:_update_policy();return
	var rows:=_rows();_update_hero(rows)
	var visible:=_filtered(rows)
	if _signature(visible)!=rows_signature:_build_body();return
	for i in mini(visible.size(),bindings.size()):_update_row(bindings[i],visible[i])
	for row:Dictionary in rows:
		if row.id==selected_row.get("id",""):selected_row=row;_update_inspection();break

func _label(parent:Node,text:String,size:int=16,color:Color=TEXT)->Label:
	var node:=Label.new();node.text=text;node.add_theme_font_override("font",T.font("ui"));node.add_theme_font_size_override("font_size",maxi(T.MIN_FONT_SIZE,size));node.add_theme_color_override("font_color",color);parent.add_child(node);return node
func _wrapped(parent:Node,text:String,size:int=14,color:Color=MUTED)->Label:
	var node:=_label(parent,text,size,color);node.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;return node
func _kicker(parent:Node,text:String,color:Color=MUTED)->Label:
	var node:=_label(parent,text.to_upper(),12,color);node.add_theme_font_override("font",T.font("ui_strong"));return node
func _button(parent:Node,text:String,callback:Callable,primary:bool=false)->Button:
	var node:=Button.new();node.text=text;node.custom_minimum_size.y=34;node.add_theme_font_override("font",T.font("ui"));node.add_theme_font_size_override("font_size",14)
	for state:String in ["font_color","font_hover_color","font_focus_color"]:node.add_theme_color_override(state,TEXT)
	node.add_theme_color_override("font_pressed_color",T.INK);node.add_theme_color_override("font_disabled_color",T.DISABLED)
	node.add_theme_stylebox_override("normal",T.action_button_style(primary))
	node.add_theme_stylebox_override("hover",T.action_button_style(primary,true))
	node.add_theme_stylebox_override("pressed",T.button_pressed_style())
	node.add_theme_stylebox_override("disabled",T.button_disabled_style())
	node.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
	node.pressed.connect(callback);parent.add_child(node);return node
func _bar(parent:Node,color:Color,mode:String="segments")->ProgressBar:
	var bar:ProgressBar=Gauge.new();bar.ink=color;bar.mode=mode;bar.track=T.TRACK;bar.ground=T.PAPER_SUNK;bar.size_flags_horizontal=Control.SIZE_EXPAND_FILL;parent.add_child(bar);return bar
func _clear()->void:
	for child in body.get_children():body.remove_child(child);child.queue_free()
	bindings.clear();policy_buttons.clear();policy_cards.clear();service_indicators.clear();hero_values.clear();summary_costs.clear();inspection_labels.clear();support_labels.clear();policy_grid=null;notice_label=null

func _build_body()->void:
	var saved_scroll:=scroll.scroll_vertical
	_clear();stories.clear()
	var who:=EraWords.word("rail.military","Military")
	# One title: the people's word for their fighters; the service only when there is a choice.
	heading.text=who if service_buttons.size()<2 or service=="army" else who+" · "+_service_name(service)
	management_button.text={"army":"Recruit & deploy","navy":"Fleet preparation","air":"Air preparation"}[service]
	for domain in service_buttons:
		service_buttons[domain].set_pressed_no_signal(domain==service)
	if training_view:page="training"
	for key:String in page_buttons:page_buttons[key].set_pressed_no_signal(page==key)
	if page=="recruitment":_recruitment();return
	if page=="support":_support();return
	var rows:=_rows();_hero(rows)
	if training_view:_policy();scroll.set_deferred("scroll_vertical",saved_scroll);return
	var filters:=HBoxContainer.new();filters.add_theme_constant_override("separation",6);body.add_child(filters)
	for definition:Array in [["all","All forces"],["attention","Need your attention"],["training","In training"]]:
		var choice:=String(definition[0]);var button:=_button(filters,String(definition[1]),func():roster_filter=choice;_build_body())
		button.toggle_mode=true;button.set_pressed_no_signal(roster_filter==choice)
	notice_label=_wrapped(body,notice,14,T.GOLD);notice_label.visible=not notice.is_empty()
	var visible:=_filtered(rows);rows_signature=_signature(visible)
	if rows.is_empty():
		var empty:=PanelContainer.new();empty.add_theme_stylebox_override("panel",_skin(T.PAPER_RAISED,T.RULE,24));body.add_child(empty)
		var content:=VBoxContainer.new();content.add_theme_constant_override("separation",10);empty.add_child(content)
		T.text(_label(content,{"army":"No one is under arms yet","navy":"No boats are in service yet","air":"No aircraft are in service yet"}[service]),"voice",TEXT)
		_wrapped(content,{"army":"Recruit a band in Recruit & deploy, or set people to Defense and the watch drills them by itself.","navy":"Build a base and commission craft through service command.","air":"Build a field and commission aircraft through service command."}[service])
		_button(content,"Recruit & deploy" if service=="army" else "Service command",func():_show_page("recruitment") if service=="army" else _map_command(),true)
	elif visible.is_empty():_wrapped(body,"No forces match this filter.")
	for data:Dictionary in visible:
		_unit_card(data)
		if data.id==selected_row.get("id",""):selected_row=data;_inspection()
	scroll.set_deferred("scroll_vertical",saved_scroll)

func _hero(rows:Array[Dictionary])->void:
	var hero:=PanelContainer.new();hero.custom_minimum_size.y=128;hero.clip_contents=true
	hero.add_theme_stylebox_override("panel",_skin(T.PAPER_SUNK,T.RULE,0));body.add_child(hero)
	var layout:=HBoxContainer.new();layout.add_theme_constant_override("separation",16);hero.add_child(layout)
	var margin:=MarginContainer.new();margin.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	for edge:String in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+edge,16)
	layout.add_child(margin)
	var words:=VBoxContainer.new();words.add_theme_constant_override("separation",4);words.size_flags_vertical=Control.SIZE_SHRINK_CENTER;margin.add_child(words)
	_kicker(words,"Your "+{"army":"forces","navy":"craft","air":"air service"}[service])
	var counts:=HBoxContainer.new();counts.add_theme_constant_override("separation",10);words.add_child(counts)
	hero_values.formations=_label(counts,"");T.text(hero_values.formations,"voice",TEXT)
	var dot:=_label(counts,"·");T.text(dot,"voice",MUTED)
	hero_values.strength=_label(counts,"");T.text(hero_values.strength,"voice",TEXT)
	hero_values.strength.tooltip_text="Counts include dated field reports; unreported strength is not guessed."
	hero_values.strength.mouse_filter=Control.MOUSE_FILTER_PASS
	hero_values.attention=_wrapped(words,"",14,TEXT)
	var controls:=HBoxContainer.new();controls.add_theme_constant_override("separation",8);words.add_child(controls)
	policy_shortcut=_button(controls,"",func():training_view=true;page="training";_build_body())
	policy_shortcut.tooltip_text="How much your forces drill, and what it costs"
	var image:=TextureRect.new();image.texture=Art.artwork(service);image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED;image.mouse_filter=Control.MOUSE_FILTER_IGNORE
	image.custom_minimum_size=Vector2(minf(300,panel.size.x*.26),128);layout.add_child(image)
	if Art.Early.active():image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_update_hero(rows)

func _story(row:Dictionary)->Dictionary:
	var key:=String(row.get("id",""))
	if not stories.has(key):stories[key]=Story.describe(row,Story.context(row,service,MilitaryCampaign))
	return stories[key]

func _update_hero(rows:Array[Dictionary])->void:
	if hero_values.is_empty():return
	var told:Array=[]
	for row:Dictionary in rows:told.append(_story(row))
	var summary:=Story.summary(rows,told,service,EraWords.stage())
	hero_values.formations.text=String(summary.forces);hero_values.strength.text=String(summary.fighters)
	hero_values.attention.text=String(summary.attention)
	hero_values.attention.add_theme_color_override("font_color",T.AMBER if int(summary.needing)>0 else T.GREEN)
	policy_shortcut.text="Training: %s ›" % String(MilitaryCampaign.training_staff.policy(service).label).to_lower()

func _training_level(drill:float)->String:
	return Story.drill_word(drill)

func _attention_reasons(data:Dictionary)->Array[String]:
	var reasons:Array[String]=[]
	for reason in _story(data).get("reasons",[]):reasons.append(String(reason))
	return reasons

func _attention(data:Dictionary)->bool:
	return bool(_story(data).get("attention",false))
func _filtered(rows:Array[Dictionary])->Array[Dictionary]:
	if roster_filter=="attention":return rows.filter(_attention)
	if roster_filter=="training":return rows.filter(func(data:Dictionary)->bool:return bool(data.get("in_training",false)))
	return rows
func _signature(rows:Array)->String:
	var keys:Array=[]
	for row:Dictionary in rows:keys.append([row.id,row.get("type_id",""),row.get("unknown",false)])
	return str(keys)

func _place_words(data:Dictionary)->String:
	if bool(data.get("unknown",false)):return "Away · no report yet"
	match String(data.get("kind","formation")):
		"line","basic","instruction":return "In first drill at home"
		"service":return String(data.get("location",""))
	match String(data.get("place","reserve")):
		"reserve":return "At home"
		"home":return "Stationed at home"
		"garrison":return String(data.get("location",""))
		"report":return String(data.get("location","")).replace(" · report "," · report ").replace("d old"," days old")
	return "In the field"

func _unit_card(data:Dictionary)->void:
	var selected:bool=data.id==selected_row.get("id","")
	var card:=PanelContainer.new();card.add_theme_stylebox_override("panel",_card_style(false,selected));body.add_child(card)
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",16);card.add_child(row)
	var art:=PanelContainer.new();art.custom_minimum_size=Vector2(112,112);art.clip_contents=true;art.size_flags_vertical=Control.SIZE_SHRINK_BEGIN
	art.add_theme_stylebox_override("panel",_skin(T.PAPER_SUNK,T.RULE,0));row.add_child(art)
	var portrait:Control=portraits.portrait(String(data.get("type_id","")),service,bool(data.get("unknown",false)));art.add_child(portrait)
	if "backdrop" in portrait:portrait.backdrop=T.PAPER_SUNK
	if Art.Early.active() and Art.EARLY_UNITS.has(String(data.get("type_id",""))):art.custom_minimum_size=Vector2(128,96)
	var words:=VBoxContainer.new();words.size_flags_horizontal=Control.SIZE_EXPAND_FILL;words.add_theme_constant_override("separation",6);row.add_child(words)
	var top:=HBoxContainer.new();top.add_theme_constant_override("separation",10);words.add_child(top)
	var title:=_label(top,Story.sentence_name(String(data.name)));T.text(title,"value",TEXT)
	var location:=_kicker(top,_place_words(data));location.size_flags_vertical=Control.SIZE_SHRINK_CENTER;location.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	location.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	var headline:=_wrapped(words,"",18,TEXT);T.text(headline,"voice_small",TEXT)
	var binding:Dictionary={"title":title,"location":location,"card":card,"portrait":portrait,"headline":headline}
	var facts:=GridContainer.new();facts.columns=2;facts.add_theme_constant_override("h_separation",12);facts.add_theme_constant_override("v_separation",5);words.add_child(facts)
	for key:String in ["people","arms","drill","condition"]:
		var kicker:=_kicker(facts,{"people":"People","arms":"Weapons","drill":"Drill","condition":"Shape"}[key]);kicker.custom_minimum_size.x=78
		var text:=_wrapped(facts,"",14,T.BODY);text.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		binding[key]=text;binding[key+"_kicker"]=kicker
	binding.condition.add_theme_color_override("font_color",T.RED)
	binding.activity_bar=_bar(words,accent());binding.activity_bar.custom_minimum_size=Vector2(160,18);binding.activity_bar.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN;binding.activity_bar.marks=10
	var side:=VBoxContainer.new();side.add_theme_constant_override("separation",8);side.size_flags_vertical=Control.SIZE_SHRINK_BEGIN;side.custom_minimum_size.x=150;row.add_child(side)
	binding.action=_button(side,"",func():_act(binding),true)
	var chosen:=data.duplicate(true)
	var select:=func():selected_row={} if selected else chosen;_build_body()
	var details:=_button(side,"Hide details" if selected else "Details",select);details.tooltip_text="Who serves in it and how they are equipped"
	binding.details=details
	card.mouse_filter=Control.MOUSE_FILTER_STOP
	card.gui_input.connect(func(event:InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:card.accept_event();select.call())
	bindings.append(binding);_update_row(binding,data)

func _card_style(attention:bool,selected:bool)->StyleBoxFlat:
	var style:=_skin(T.PAPER_RAISED,T.GOLD if selected else T.RULE,16)
	if attention:style.border_width_left=3;style.border_color=T.AMBER if not selected else T.GOLD
	return style

func _update_row(binding:Dictionary,data:Dictionary)->void:
	var story:=_story(data)
	binding.row=data;binding.story=story
	binding.title.text=Story.sentence_name(String(data.name));binding.location.text=_place_words(data).to_upper()
	binding.headline.text=String(story.headline)
	for key:String in ["people","arms","drill","condition"]:
		var text:=String(story.get(key,""))
		binding[key].text=text;binding[key].visible=not text.is_empty();binding[key+"_kicker"].visible=not text.is_empty()
	var training:=String(data.get("kind","")) in ["line","basic","instruction"]
	binding.activity_bar.value=float(data.get("progress",0))*100
	binding.activity_bar.visible=training and bool(data.get("in_training",false)) and not bool(data.get("unknown",false))
	binding.activity_bar.tooltip_text="First drill %d%% done" % roundi(float(data.get("progress",0))*100)
	binding.action.text=String(story.action.label)
	binding.action.disabled=String(story.action.id)=="none"
	binding.card.add_theme_stylebox_override("panel",_card_style(bool(story.attention),data.id==selected_row.get("id","")))
	binding.activity_bar.queue_redraw()

## One next step per force, always through an existing flow.
func _act(binding:Dictionary)->void:
	var data:Dictionary=binding.get("row",{});var story:Dictionary=binding.get("story",{})
	match String(story.get("action",{}).get("id","")):
		"reinforce":notice=_call_up(data);_build_body()
		"production":_production()
		"recruitment":_show_page("recruitment")
		"training":training_view=true;page="training";_build_body()
		"map":_map_command()
		_:_talk_to_captain(data)

func _call_up(data:Dictionary)->String:
	## The war-planning call-up, one force at a time: raise free adults into the
	## recruit reserve, then send them to the empty places (reinforce_formation).
	var sent:=0;var refusal:=""
	for member:Dictionary in data.get("members",[data]):
		var gap:=maxi(0,int(member.get("authorized",0))-int(member.get("count",0)))
		if gap<=0 or not member.has("formation_id"):continue
		if MilitaryCampaign.aggregate_recruits<gap:MilitaryCampaign.raise_recruits(gap-MilitaryCampaign.aggregate_recruits)
		var result:Dictionary=MilitaryCampaign.reinforce_formation(int(member.formation_id),gap)
		if result.has("error"):refusal=String(result.error);continue
		sent+=int(result.get("accepted",0))
	if sent<=0:return refusal if not refusal.is_empty() else "No one could be called up."
	return "%s called up; they drill for a few days, then take the empty places in %s." % [Story.number(sent),Story.sentence_name(String(data.name))]

func _talk_to_captain(data:Dictionary)->void:
	var captain:Dictionary=Story.captain_for(data,MilitaryCampaign)
	var director:Node=preload("res://scripts/audience_director.gd").court_node()
	if director==null:
		notice="The court cannot be opened just now.";_build_body();return
	if not captain.is_empty() and director.has_method("summon"):director.call("summon",captain.target)
	else:director.call("open_court",{})
	queue_free()

func _rows()->Array[Dictionary]:
	var raw:=_raw_rows()
	return preload("res://scripts/hud/army_roster_groups.gd").group(raw) if service=="army" else raw

func _raw_rows()->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	var campaign=MilitaryCampaign
	if service=="army":
		var forces:Array=[{"force":campaign.home_army,"location":"Home reserve","key":"home","place":"reserve"}]
		var snapshot:Dictionary=campaign.field_armies_snapshot()
		for army:Dictionary in snapshot.get("armies",[]):
			var home:bool=String(army.get("location_id",""))=="player_home" and army.get("status","")=="stationed"
			var report:Dictionary=army.get("last_report",{})
			var commander:Dictionary=army.get("commander",{})
			if not home and not bool(snapshot.get("live_reports",false)):
				if report.get("formations",[]).is_empty():
					result.append({"id":"field:%s" % army.get("army_id",army.get("id",0)),"type_id":"","name":String(army.get("name","Field army")),"glyph":"⚑","location":"Awaiting formation report","count":int(report.get("troops",0)),"unknown":true,"commander":commander});continue
				forces.append({"force":report,"key":"field:%s" % army.get("army_id",army.get("id",0)),"place":"report","commander":commander,"location":"%s · report %dd old" % [army.get("name","Field army"),maxi(0,int(GameState.elapsed_days)-int(report.get("day",0)))]})
			else:forces.append({"force":army,"key":"field:%s" % army.get("army_id",army.get("id",0)),"place":"home" if home else "field","commander":commander,"location":army.get("name","Field army")})
		for occupation:Dictionary in campaign.occupation_forces:forces.append({"force":occupation,"place":"garrison","commander":occupation.get("commander",{}),"key":"garrison:%s:%s" % [occupation.get("civ_id",""),occupation.get("region_id",campaign.occupation_forces.find(occupation))],"location":String(occupation.get("region_name","Occupied settlement"))+" garrison"})
		for group:Dictionary in forces:
			for unit:Dictionary in group.force.get("formations",[]):
				var count:=int(unit.get("count",0));var attending:=int(unit.get("training_attending",0)) if not "report" in String(group.location) else 0
				var type_id:=String(unit.get("unit","levy"))
				var glyph:="♞" if type_id in ["cavalry","horse_archer","mounted_archer"] else "➶" if String(unit.get("weapon",""))=="bow" else "⚔"
				var entry:={"id":"%s:%s" % [group.key,unit.get("id",group.force.get("formations",[]).find(unit))],"kind":"formation","place":String(group.place),"commander":group.get("commander",{}),"group_key":group.key,"group_name":"Home reserve" if group.key=="home" else String(group.location),"equipment_count":int(unit.get("equipment",0)),"equipment_required":int(unit.get("equipment_required",count)),"type_id":type_id,"purpose":campaign.UnitCatalog.archetype(type_id).get("purpose",""),"weapon":String(unit.get("weapon","")),"name":campaign.UnitCatalog.archetype(type_id).get("label",type_id),"glyph":glyph,"location":group.location,"count":count,"authorized":int(unit.get("authorized_count",count)),"condition":float(unit.get("personnel_condition",1)),"equipment":float(unit.get("equipment",0))/maxf(1,unit.get("equipment_required",count)),"equipment_note":("Ammo %d / %d" % [unit.get("ammunition",0),unit.get("ammunition_required",0)] if int(unit.get("ammunition_required",0))>0 else "No ammo needed"),"skill":float(unit.get("training",0)),"experience":float(unit.get("experience",0)),"in_training":attending>0,"activity":"Staff training" if attending>0 else "On duty / reserve","progress":float(campaign.training_program.get("progress_days",0))/maxf(1,campaign.training_program.get("duration_days",1)) if attending>0 else 0.0,"training_note":"%d rotating through drill" % attending if attending>0 else "Training: "+String(campaign.training_staff.policy(service).label).to_lower()}
				if group.key=="home" and unit.has("id"):entry.formation_id=int(unit.id)
				result.append(entry)
		for trainee:Dictionary in campaign.training_queue:
			var count:=int(trainee.get("count",0));var days:=float(trainee.get("required_days",1));var progress:=float(trainee.get("progress_days",0))
			var line:=trainee.has("deployment_line")
			var kind:="line" if line else "basic" if bool(trainee.get("automated_basic",false)) else "instruction"
			var unit_type:=String(trainee.get("unit","levy"))
			# A recruitment line's size is its template (target_count). initial_count
			# counts everyone ever enrolled, including recruits hurt and replaced.
			var target:=int(trainee.get("target_count",count)) if line else count
			var required:int=campaign._equipment_required_for(unit_type,count)
			var reserved:=int(trainee.get("reserved_equipment",0))
			var armed:=mini(required,reserved) if line else roundi(float(trainee.get("equipment_access_today",0))*required)
			var access:=clampf(float(reserved)/maxf(1.0,float(required)),0,1)
			var manpower:=clampf(float(count)/maxf(1.0,float(target)),0,1)
			result.append({"id":"recruit:%s" % trainee.get("id",campaign.training_queue.find(trainee)),"kind":kind,"place":"reserve","order_id":int(trainee.get("id",-1)),"line_id":int(trainee.get("deployment_line",-1)),"hurt":maxi(0,int(trainee.get("initial_count",count))-count),"ceiling":minf(manpower,access) if line else 1.0,"ceiling_reason":"gear" if access<manpower else "people","group_key":"recruit:%s" % trainee.get("deployment_line",trainee.get("build_batch","legacy")),"group_name":String(campaign.recruit_deploy.line(int(trainee.deployment_line)).get("name","Recruitment line %s" % trainee.deployment_line)) if line else "New recruits","type_id":unit_type,"weapon":String(trainee.get("weapon","improvised")),"name":campaign.UnitCatalog.archetype(unit_type).get("label","Recruits"),"glyph":"◇","location":"Initial instruction","count":count,"authorized":target,"condition":float(trainee.get("personnel_condition",1)),"equipment_count":armed,"equipment_required":required,"equipment":float(armed)/maxf(1,required),"equipment_note":"Weapons for drill","skill":0.0,"experience":float(trainee.get("experience",0)),"in_training":true,"activity":"Initial training","progress":progress/maxf(1,days),"training_note":"%.0f of %.0f days of first drill" % [progress,days]})
	else:
		var op=campaign.joint_operations
		for unit:Dictionary in op.state.forces:
			if unit.owner!="player" or unit.domain!=service:continue
			var authorized:=0;var missing_equipment:=""
			for kind:String in unit.authorized:
				authorized+=int(unit.authorized[kind])
				if missing_equipment.is_empty() and int(unit.authorized[kind])>int(unit.units.get(kind,0)):missing_equipment=String(op.C.UNITS.get(kind,{}).get("equipment",""))
			var staff_status:=String(unit.get("training_status",""))
			var staff_report:Dictionary=campaign.training_staff.service_force_report(unit,maxi(int(op.state.last_day),int(unit.get("staff_training_day",-1))))
			var exercising:bool=staff_report.group=="training" and float(unit.training)>=1.0
			var activity:=staff_status if exercising else String(unit.status)
			var note:=String(unit.status) if exercising else staff_status
			if note==activity or note=="":note="Training: "+String(campaign.training_staff.policy(service).label).to_lower()
			var type_id:="";var largest:=0
			for kind:String in unit.units:
				if int(unit.units[kind])>largest:type_id=kind;largest=int(unit.units[kind])
			result.append({"id":"%s:%s" % [service,unit.id],"kind":"service","service_equipment":missing_equipment,"auto_replace":bool(unit.get("auto_replace",true)),"crew_short":int(unit.get("crew_shortfall",0)),"type_id":type_id,"purpose":String(op.C.UNITS.get(type_id,{}).get("purpose","")),"name":unit.name,"glyph":"⚓" if service=="navy" else "✈","location":op.base(int(unit.base_id)).get("name","Base unavailable"),"count":op.hardware(unit),"authorized":authorized,"condition":float(unit.condition),"equipment":float(op.hardware(unit))/maxf(1,authorized),"equipment_note":"%d crew" % op.crew(unit),"skill":float(unit.get("proficiency",.45 if float(unit.training)>=1 else 0)),"experience":float(unit.experience),"in_training":staff_report.group=="training","activity":activity,"progress":float(unit.training) if float(unit.training)<1.0 else 0.0,"training_note":note})
	return result

func _inspection()->void:
	var panel_detail:=PanelContainer.new();panel_detail.add_theme_stylebox_override("panel",_skin(T.PAPER,T.RULE_STRONG,16));body.add_child(panel_detail)
	var layout:=VBoxContainer.new();layout.add_theme_constant_override("separation",8);panel_detail.add_child(layout)
	_kicker(layout,{"army":"Who serves in it","navy":"The craft in it","air":"The aircraft in it"}[service])
	inspection_labels.name=_label(layout,Story.sentence_name(String(selected_row.name)));T.text(inspection_labels.name,"voice",TEXT)
	if bool(selected_row.get("unknown",false)):
		_wrapped(layout,"Its makeup is unknown until a dated report arrives.");return
	inspection_labels.purpose=_wrapped(layout,String(selected_row.get("purpose","Service staff prepare this force under your standing policy.")),14,T.BODY)
	inspection_labels.skills=_label(layout,"",14,accent())
	inspection_labels.composition=_wrapped(layout,"",14,TEXT)
	inspection_labels.activity=_wrapped(layout,"",14)
	var buttons:=HFlowContainer.new();buttons.add_theme_constant_override("h_separation",8);layout.add_child(buttons)
	if service=="army":_button(buttons,"Recruit & deploy",func():_management(1))
	_button(buttons,"Training level",func():training_view=true;selected_row={};_build_body())
	_button(buttons,"Command on map ↗",_map_command)
	_update_inspection()
func _update_inspection()->void:
	if inspection_labels.is_empty() or selected_row.is_empty():return
	inspection_labels.name.text=Story.sentence_name(String(selected_row.name))
	if bool(selected_row.get("unknown",false)):return
	inspection_labels.composition.text=String(selected_row.get("composition",""))
	var seen:=Story.experience_words(float(selected_row.experience))
	inspection_labels.skills.text="%s (%d%%) · %s" % [Story.drill_word(float(selected_row.skill)),roundi(float(selected_row.skill)*100),seen.substr(0,1).to_upper()+seen.substr(1)]
	var story:=_story(selected_row)
	inspection_labels.activity.text=String(selected_row.training_note)+("" if String(story.condition).is_empty() else "\n"+String(story.condition))

func _policy()->void:
	T.text(_label(body,"How much should we train?"),"voice",TEXT)
	_wrapped(body,"Choose how hard to drill. Staff rotate people through drill and pause for shortages or emergencies.")
	policy_grid=GridContainer.new();policy_grid.columns=4 if panel.size.x>=920 else 2
	policy_grid.add_theme_constant_override("h_separation",10);policy_grid.add_theme_constant_override("v_separation",10);body.add_child(policy_grid)
	for id:String in MilitaryCampaign.training_staff.POLICIES:
		var definition:Dictionary=MilitaryCampaign.training_staff.POLICIES[id]
		var outer:=PanelContainer.new();outer.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		outer.add_theme_stylebox_override("panel",_skin(T.PAPER_RAISED,T.RULE,12));policy_grid.add_child(outer);policy_cards[id]=outer
		var card:=VBoxContainer.new();card.add_theme_constant_override("separation",8);outer.add_child(card)
		var choice:=id
		var button:=_button(card,String(definition.label),func():MilitaryCampaign.training_staff.set_policy(service,choice);_update_policy())
		button.toggle_mode=true;button.custom_minimum_size.y=38;policy_buttons[id]=button
		var icons:ProgressBar=_bar(card,accent(),"people");icons.marks=20;icons.value=float(definition.share)*100;icons.custom_minimum_size.y=26
		var share:=_label(card,"%d in 100 drill at a time" % roundi(float(definition.share)*100));T.text(share,"value",TEXT)
		_label(card,"Aim: drill %d%%" % roundi(float(definition.target)*100),13,accent())
		var skill:=_bar(card,accent(),"patch");skill.value=float(definition.target)*100
		skill.custom_minimum_size=Vector2(44,32);skill.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
		var description:=_wrapped(card,String(definition.description),13);description.custom_minimum_size.x=140
		var effort:=_kicker(card,{"suspended":"Saves stores","maintain":"Light cost","regular":"Steady cost","intensive":"Heavy cost"}[id])
		effort.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	if service!="army":
		var overview:=GridContainer.new();overview.columns=4;overview.add_theme_constant_override("h_separation",10);body.add_child(overview)
		for definition:Array in [["training","In training",T.GREEN],["assigned","On missions",T.BLUE],["target","Drilled enough",T.GOLD],["paused","Paused",T.RED]]:
			var card:=VBoxContainer.new();card.size_flags_horizontal=Control.SIZE_EXPAND_FILL;overview.add_child(card)
			var value:=_label(card,"0",24,definition[2]);_kicker(card,String(definition[1]))
			var bar:=_bar(card,definition[2]);service_indicators[definition[0]]={"value":value,"bar":bar,"card":card}
		_wrapped(body,"Counts are fleets or wings. Staff review the training level each day.",13)
	policy_status=_wrapped(body,"",14,TEXT)
	var investment:=HFlowContainer.new();investment.add_theme_constant_override("h_separation",16);body.add_child(investment)
	for definition:Array in [["food","Extra food eaten","supply"],["materials","Materials used","equipment"],["time","First drill takes","calendar"]]:
		var box:=PanelContainer.new();box.add_theme_stylebox_override("panel",_skin(T.PAPER_RAISED,T.RULE,12));box.custom_minimum_size.x=180;investment.add_child(box)
		var content:=HBoxContainer.new();content.add_theme_constant_override("separation",9);box.add_child(content)
		var icon:=TextureRect.new();icon.texture=Art.symbol(definition[2],accent());icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.custom_minimum_size=Vector2(30,30);content.add_child(icon)
		var text:=VBoxContainer.new();content.add_child(text);summary_costs[definition[0]]=_label(text,"",20);_kicker(text,String(definition[1]))
	_wrapped(body,"First drill counts only days with food and weapons to practise with; shortages pause it. Longer exercises take 72 to 252 such days. Staff always keep seven days of food for everyone else.",13)
	_update_policy()
func _update_policy()->void:
	var state:Dictionary=MilitaryCampaign.training_staff.snapshot(service)
	_update_hero(_rows())
	for id in policy_buttons:
		policy_buttons[id].set_pressed_no_signal(id==state.id)
		var style:=_skin(T.PAPER_RAISED,T.GOLD if id==state.id else T.RULE,12)
		if id==state.id:style.border_width_top=3
		policy_cards[id].add_theme_stylebox_override("panel",style)
	for group in service_indicators:
		var indicator:Dictionary=service_indicators[group]
		indicator.value.text=str(state.groups[group]);indicator.bar.value=float(state.groups[group])/maxf(1,state.forces)*100
		var tips:Dictionary={"training":"Crews in instruction or training rotations; other qualified crews may still operate.","assigned":"Forces committed to missions or travel without a training rotation.","target":"Crews at home whose proficiency meets the selected target.","paused":String(state.get("pause_details","No paused training."))}
		indicator.card.tooltip_text=tips[group];indicator.value.tooltip_text=tips[group];indicator.bar.tooltip_text=tips[group]
	policy_status.text=String(state.status)
	if service=="army" and not state.active.is_empty():policy_status.text+="\n%s · %.0f of %.0f days done" % [state.active.label,state.active.progress_days,state.active.duration_days]
	summary_costs.food.text="%.1f" % state.food_spent;summary_costs.materials.text="%.1f" % state.materials_spent
	summary_costs.time.text="45+ days" if service=="army" else "90+ days"
