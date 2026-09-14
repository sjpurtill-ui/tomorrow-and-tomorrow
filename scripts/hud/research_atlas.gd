extends Control
## People, active investigations and the knowledge frontier, read from the same
## capacity and leadership assignments used by the daily discovery simulation.
const Data=preload("res://scripts/hud/atlas_data.gd")
const Art=preload("res://scripts/hud/research_visuals.gd")
const TreePlot=preload("res://scripts/hud/research_tree_plot.gd")
const T=preload("res://scripts/hud/hud_tokens.gd")
const Gauge=preload("res://scripts/hud/military_roster_gauge.gd")
const CARD_WIDTH:=220.0
const CARD_IMAGE_HEIGHT:=92.0
const CARD_GAP:=10.0
var mode:="inquiry"
var terrain:Node
var hud:Node
var layer:CanvasLayer
var domain:=""
var query:=""
var leader_filter:=""
var view_mode:="active"
var show_locked:=false
var selected_id:=""
var records:Array[Dictionary]=[]
var all_records:Array[Dictionary]=[]
var panel:PanelContainer
var main:BoxContainer
var content:VBoxContainer
var grid:GridContainer
var scroll:ScrollContainer
var plot:Control
var detail_scroll:ScrollContainer
var detail_body:VBoxContainer
var detail:Label
var action:Button
var filter:OptionButton
var leaders:OptionButton
var search:LineEdit
var legend:Label
var stats:Label
var locked_toggle:CheckButton
var tree_controls:HBoxContainer
var tabs:Dictionary={}
var bindings:Dictionary={}
var last_layout:=""
var elapsed:=0.0
var revision:=""
var empty:VBoxContainer
var detail_selected:=""
var leader_options:Array=[]
var detail_revision:=""
var narrow_details:=false
var announcements:OptionButton
var detail_back:Button
func _ready()->void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dismiss:=ColorRect.new();dismiss.color=Color(0,0,0,.25);dismiss.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(dismiss)
	dismiss.gui_input.connect(func(event:InputEvent)->void:if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:_close())
	panel=PanelContainer.new();panel.mouse_filter=Control.MOUSE_FILTER_STOP;panel.add_theme_stylebox_override("panel",T.flat(T.PANEL_BG,T.BORDER,1,8,16));add_child(panel)
	var box:=VBoxContainer.new();box.add_theme_constant_override("separation",10);panel.add_child(box)
	var header:=HBoxContainer.new();header.add_theme_constant_override("separation",10);box.add_child(header)
	Art.label(header,"RESEARCH · PEOPLE & IDEAS",23,T.INK).size_flags_horizontal=Control.SIZE_EXPAND_FILL
	Art.button(header,"Research staffing",_staffing)
	var close:=Art.button(header,"×",_close);close.custom_minimum_size.x=38;close.tooltip_text="Close · Escape or click outside"
	var notification_row:=HBoxContainer.new();box.add_child(notification_row)
	Art.label(notification_row,"Discovery pauses",12,T.TEXT_SOFT)
	announcements=OptionButton.new();notification_row.add_child(announcements)
	for spec:Array in [["milestones","Major milestones"],["all","Every discovery"],["quiet","Digest only"]]:
		announcements.add_item(spec[1]);announcements.set_item_metadata(announcements.item_count-1,spec[0])
		if GameState.research_notification_mode==spec[0]:announcements.select(announcements.item_count-1)
	announcements.item_selected.connect(func(index:int)->void:GameState.research_notification_mode=String(announcements.get_item_metadata(index)))
	var navigation:=HBoxContainer.new();navigation.add_theme_constant_override("separation",8);box.add_child(navigation)
	for spec:Array in [["active","Being researched"],["tree","Knowledge tree"],["known","Established"]]:
		var id:=String(spec[0]);tabs[id]=Art.button(navigation,spec[1],func()->void:set_view(id))
	stats=Art.label(navigation,"",13,T.TEXT_SOFT);stats.size_flags_horizontal=Control.SIZE_EXPAND_FILL;stats.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	var controls:=HBoxContainer.new();controls.add_theme_constant_override("separation",8);box.add_child(controls)
	filter=OptionButton.new();filter.add_item("All fields");filter.custom_minimum_size=Vector2(192,34);filter.add_theme_font_size_override("font_size",13);controls.add_child(filter)
	for id:String in Art.NAMES:filter.add_item(Art.name_for(id));filter.set_item_metadata(filter.item_count-1,id)
	filter.item_selected.connect(func(index:int)->void:domain="" if index==0 else String(filter.get_item_metadata(index));refresh(true))
	leaders=OptionButton.new();leaders.custom_minimum_size=Vector2(176,34);leaders.clip_text=true;leaders.add_theme_font_size_override("font_size",13);controls.add_child(leaders)
	leaders.item_selected.connect(func(index:int)->void:leader_filter="" if index==0 else String(leaders.get_item_metadata(index));refresh(true))
	search=LineEdit.new();search.placeholder_text="Find a subject or leader";search.size_flags_horizontal=Control.SIZE_EXPAND_FILL;search.add_theme_font_size_override("font_size",13);controls.add_child(search)
	search.text_changed.connect(func(value:String)->void:query=value;refresh(true))
	legend=Art.label(box,"",12,T.TEXT_SOFT,true)
	tree_controls=HBoxContainer.new();box.add_child(tree_controls)
	Art.button(tree_controls,"−",func()->void:plot.zoom_at(1/1.15,plot.size*.5));Art.button(tree_controls,"+",func()->void:plot.zoom_at(1.15,plot.size*.5));Art.button(tree_controls,"Fit",func()->void:plot.fit());Art.button(tree_controls,"Find selected",func()->void:plot.center_selected())
	locked_toggle=CheckButton.new();locked_toggle.text="Show unexplored paths";locked_toggle.add_theme_font_size_override("font_size",12);tree_controls.add_child(locked_toggle)
	locked_toggle.toggled.connect(func(on:bool)->void:show_locked=on;refresh(true))
	detail_back=Art.button(box,"← Back to research",func()->void:narrow_details=false;_layout())
	main=BoxContainer.new();main.size_flags_vertical=Control.SIZE_EXPAND_FILL;main.add_theme_constant_override("separation",14);box.add_child(main)
	content=VBoxContainer.new();content.size_flags_horizontal=Control.SIZE_EXPAND_FILL;content.size_flags_vertical=Control.SIZE_EXPAND_FILL;main.add_child(content)
	scroll=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_AUTO;scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;content.add_child(scroll)
	grid=GridContainer.new();grid.columns=3;grid.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN;grid.add_theme_constant_override("h_separation",int(CARD_GAP));grid.add_theme_constant_override("v_separation",10);scroll.add_child(grid)
	plot=TreePlot.new();plot.owner_view=self;plot.size_flags_vertical=Control.SIZE_EXPAND_FILL;plot.custom_minimum_size=Vector2(0,140);content.add_child(plot)
	empty=VBoxContainer.new();content.add_child(empty)
	detail_scroll=ScrollContainer.new();detail_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;detail_scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;main.add_child(detail_scroll)
	detail_body=VBoxContainer.new();detail_body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;detail_body.add_theme_constant_override("separation",9);detail_scroll.add_child(detail_body)
	resized.connect(_layout);_layout();refresh(true)
func _layout()->void:
	if panel==null:return
	var size:=get_viewport_rect().size
	panel.position=Vector2(22,24);panel.size=Vector2(maxf(620,size.x-44),maxf(470,size.y-48))
	var narrow:=size.x<1120
	main.vertical=narrow
	content.visible=not (narrow and narrow_details)
	detail_back.visible=narrow and narrow_details
	detail_scroll.visible=not narrow or narrow_details
	detail_scroll.custom_minimum_size=Vector2(0,0) if narrow else Vector2(300,0)
	detail_scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	detail_scroll.size_flags_horizontal=Control.SIZE_EXPAND_FILL if narrow else Control.SIZE_FILL
	grid.columns=maxi(1,floori((size.x-(90 if narrow else 416))/(CARD_WIDTH+CARD_GAP)))
	_update_grid_columns.call_deferred()
	if size.x<900:stats.hide();filter.custom_minimum_size.x=170;leaders.custom_minimum_size.x=145
	else:stats.show();filter.custom_minimum_size.x=192;leaders.custom_minimum_size.x=176
	plot.queue_redraw()
func _update_grid_columns()->void:
	if not is_instance_valid(scroll) or not is_instance_valid(grid):return
	grid.columns=maxi(1,floori((scroll.size.x+CARD_GAP)/(CARD_WIDTH+CARD_GAP)))
func set_view(value:String)->void:
	view_mode=value;narrow_details=false;_layout();refresh(true)
func _close()->void:
	if is_instance_valid(layer):layer.queue_free()
	else:queue_free()
func _ledger()->void:
	_close();hud.open_dock("inquiry",1,false)
func _staffing()->void:
	if is_instance_valid(hud):_close();hud.open_dock("inquiry",0)
func _unhandled_key_input(event:InputEvent)->void:
	if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:_close();get_viewport().set_input_as_handled()
func _process(delta:float)->void:
	elapsed+=delta
	if elapsed<.75:return
	elapsed=0
	var next:=str(hash([int(GameState.elapsed_days),GameState.discovery_progress,GameState.active_investigations,GameState.known_discoveries,GameState.research_subcategory_allocations,GameState.population_allocations,GameState.leadership_positions,GameState.food_security,GameState.society_capacities]))
	if next!=revision:revision=next;refresh(false)
func refresh(refit:bool)->void:
	locked_toggle.set_pressed_no_signal(show_locked)
	all_records=Data.inquiry()
	for index in filter.item_count:
		if (index==0 and domain=="") or (index>0 and String(filter.get_item_metadata(index))==domain):filter.select(index)
	var active:=0;var staffed:=0;var known:=0;var people:Dictionary={}
	for item:Dictionary in all_records:
		if item.known:known+=1
		var assignment:Dictionary=item.assignment
		if assignment.get("active",false):active+=1;staffed+=1 if Art.team(item)>0 else 0
		var lead:=Art.lead(item)
		if not lead.is_empty():people[lead]=true
	var chosen:=leader_filter
	var names:=people.keys();names.sort()
	if names!=leader_options:
		leader_options=names.duplicate();leaders.clear();leaders.add_item("All leaders")
		for name:String in names:leaders.add_item(name);leaders.set_item_metadata(leaders.item_count-1,name)
	leader_filter="" if chosen!="" and not people.has(chosen) else chosen
	for index in leaders.item_count:
		if (index==0 and leader_filter=="") or (index>0 and String(leaders.get_item_metadata(index))==leader_filter):leaders.select(index)
	stats.text="%d researchers  ·  %d staffed / %d projects" % [maxi(0,int(GameState.effective_workers("Knowledge"))),staffed,active]
	tabs.active.text="Being researched · %d" % active;tabs.known.text="Established · %d" % known
	for id:String in tabs:tabs[id].modulate=T.GOLD if id==view_mode else Color.WHITE
	records.clear()
	var hidden:=0
	for item:Dictionary in all_records:
		if domain!="" and item.domain!=domain:continue
		if leader_filter!="" and Art.lead(item)!=leader_filter:continue
		if query!="" and not (String(item.name)+" "+Art.lead(item)+" "+Art.name_for(item.domain)).to_lower().contains(query.to_lower()):continue
		if view_mode=="active" and not item.assignment.get("active",false):continue
		if view_mode=="known" and not item.known:continue
		if view_mode=="tree" and not show_locked and not item.exposed:hidden+=1;continue
		records.append(item)
	if view_mode=="active":records.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return Art.lead(a)+String(a.name)<Art.lead(b)+String(b.name))
	legend.text="Named leaders supervise shared teams. Team sizes show equivalent full-time effort; evidence builds as people investigate." if view_mode=="active" else "%d unexplored questions hidden. Solid lines: original foundations. Dashed lines: alternative approaches; drag to pan, wheel to zoom." % hidden if view_mode=="tree" else "Discoveries your civilization has established. Select a card for its effects."
	tree_controls.visible=view_mode=="tree";plot.visible=view_mode=="tree" and not records.is_empty();scroll.visible=view_mode!="tree" and not records.is_empty();empty.visible=records.is_empty()
	if records.is_empty():
		for child in empty.get_children():empty.remove_child(child);child.queue_free()
		Art.paint(empty,domain if domain!="" else "knowledge",125)
		Art.label(empty,"No matching investigations" if query!="" or domain!="" or leader_filter!="" else "No active investigation yet" if view_mode=="active" else "No discoveries in this view",20,T.INK,true)
		Art.label(empty,"Choose a field or clear the filters. The knowledge tree shows questions that can be investigated with current evidence.",13,T.TEXT_SOFT,true)
		if view_mode=="active":Art.button(empty,"Explore the knowledge tree",func()->void:set_view("tree"))
	var ids:Array=[]
	for item:Dictionary in records:ids.append(item.id)
	var layout_key:=view_mode+str(ids)
	if layout_key!=last_layout:
		last_layout=layout_key;plot.arrange();_build_cards()
		if refit and view_mode=="tree":plot.call_deferred("center_selected")
	elif refit and view_mode=="tree":plot.call_deferred("center_selected")
	if selected_id not in ids:selected_id=String(ids[0]) if not ids.is_empty() else ""
	_update_cards();select(selected_id)
func _build_cards()->void:
	for child in grid.get_children():grid.remove_child(child);child.queue_free()
	bindings.clear()
	if view_mode=="tree":return
	for item:Dictionary in records:
		var frame:=PanelContainer.new();frame.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN;frame.custom_minimum_size.x=CARD_WIDTH;grid.add_child(frame)
		var box:=VBoxContainer.new();box.add_theme_constant_override("separation",0);frame.add_child(box)
		var painting:=Art.paint_discovery(box,item,CARD_IMAGE_HEIGHT)
		var margin:=MarginContainer.new()
		for edge:String in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+edge,10)
		box.add_child(margin)
		var body:=VBoxContainer.new();body.add_theme_constant_override("separation",5);margin.add_child(body)
		var name:=Art.label(body,String(item.name),17,T.INK,true)
		var status:=Art.label(body,"",11,Art.color(item.domain))
		var date:=Art.label(body,"",10,T.GOLD)
		var lead:=Art.label(body,"",12,T.BODY,true)
		var team:=Art.label(body,"",13,T.BODY)
		var meter:ProgressBar=Gauge.new();meter.ink=Art.color(item.domain);body.add_child(meter)
		var note:=Art.label(body,"",11,T.TEXT_SOFT,true)
		# PASS preserves card clicks while allowing wheel/trackpad scrolling to
		# bubble to the Established-page ScrollContainer.
		frame.mouse_filter=Control.MOUSE_FILTER_PASS
		var id:=String(item.id)
		frame.gui_input.connect(func(event:InputEvent)->void:if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:select(id,true))
		for node:Node in frame.find_children("*","Control",true,false):node.mouse_filter=Control.MOUSE_FILTER_IGNORE
		frame.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
		bindings[id]={"frame":frame,"name":name,"status":status,"date":date,"lead":lead,"team":team,"meter":meter,"note":note,"painting":painting}
func _update_cards()->void:
	for item:Dictionary in records:
		if not bindings.has(item.id):continue
		var card:Dictionary=bindings[item.id]
		card.frame.add_theme_stylebox_override("panel",T.flat(Color("172830"),T.GOLD if item.id==selected_id else T.BORDER,2 if item.id==selected_id else 1,6,1))
		card.status.text=Art.status(item).to_upper()+" · "+Art.name_for(item.domain)
		card.date.text=_discovery_date(item)
		card.date.visible=bool(item.known)
		card.lead.text="Supervised by "+Art.lead(item) if not Art.lead(item).is_empty() else String(item.subcategory).capitalize()
		card.team.text=Art.workforce(Art.team(item))+" · %d%% evidence" % roundi(float(item.progress)*100)
		card.team.visible=item.assignment.get("active",false);card.meter.visible=card.team.visible;card.meter.value=clampf(float(item.progress),0,1)*100
		card.note.text=Art.phase(item) if card.team.visible else "Select for findings and effects"
func select(id:String,open_detail:bool=false)->void:
	if open_detail and main.vertical:narrow_details=true;_layout()
	selected_id=id;plot.queue_redraw();_update_cards()
	var selected_record:Dictionary={}
	for item:Dictionary in records:
		if item.id==id:selected_record=item;break
	var signature:=str(hash([id,selected_record,main.vertical]))
	if signature==detail_revision:return
	detail_revision=signature
	var old_scroll:=detail_scroll.scroll_vertical if detail_selected==id else 0;detail_selected=id
	for child in detail_body.get_children():detail_body.remove_child(child);child.queue_free()
	for item:Dictionary in records:
		if item.id!=id:continue
		Art.paint_discovery(detail_body,item,116 if not main.vertical else 64)
		Art.label(detail_body,Art.name_for(item.domain).to_upper(),11,Art.color(item.domain))
		Art.label(detail_body,item.name,21,T.INK,true)
		Art.label(detail_body,Art.status(item),13,Art.color(item.domain))
		if item.known:Art.label(detail_body,_discovery_date(item).capitalize(),11,T.GOLD)
		if item.known:
			var operations:VBoxContainer=preload("res://scripts/hud/technology_operations_panel.gd").new()
			operations.subject=String(item.id);detail_body.add_child(operations)
			if preload("res://scripts/clothing_knowledge.gd").METHODS.has(String(item.id)):
				var clothing_panel:VBoxContainer=preload("res://scripts/hud/clothing_panel.gd").new()
				clothing_panel.subject=String(item.id);detail_body.add_child(clothing_panel)
			if preload("res://scripts/hud/microscopy_panel.gd").supports(String(item.id)):
				var lab_panel:VBoxContainer=preload("res://scripts/hud/microscopy_panel.gd").new()
				lab_panel.subject=String(item.id);detail_body.add_child(lab_panel)
			if preload("res://scripts/food_batch_knowledge.gd").METHODS.has(String(item.id)):
				var food_panel:VBoxContainer=preload("res://scripts/hud/food_batches_panel.gd").new()
				food_panel.subject=String(item.id);detail_body.add_child(food_panel)
			if not preload("res://scripts/grain_processing.gd").definition(String(item.id)).is_empty():
				var grain_panel:VBoxContainer=preload("res://scripts/hud/grain_processing_panel.gd").new()
				grain_panel.subject=String(item.id);detail_body.add_child(grain_panel)
		if item.exposed:
			var definition:Dictionary=WorldSimulation.discovery.discovery_definition(String(item.id))
			if not definition.get("preservation_profile",{}).is_empty() or not definition.get("training_profile",{}).is_empty() or not definition.get("prospecting_profile",{}).is_empty() or not String(definition.get("medical_method","")).is_empty() or not definition.get("agronomy_profile",{}).is_empty():Art.label(detail_body,WorldSimulation.discovery._discovery_effect_summary(definition),11,T.TEXT_SOFT,true)
		var assignment:Dictionary=item.assignment
		if not assignment.is_empty():
			var leader:Dictionary=assignment.leader
			var row:=HBoxContainer.new();row.add_theme_constant_override("separation",10);detail_body.add_child(row)
			var badge:=Art.label(row,"—" if leader.vacant else Art.initials(leader.name),20,Art.color(item.domain));badge.custom_minimum_size=Vector2(40,42);badge.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
			var who:=VBoxContainer.new();who.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(who)
			Art.label(who,"SUPERVISING LEADER",9,T.MUTED);Art.label(who,leader.name,16,T.INK,true)
			Art.label(who,String(leader.office)+(" · acting for "+String(leader.requested_office) if leader.acting else ""),11,T.TEXT_SOFT,true)
			Art.label(detail_body,"Relevant skills: "+", ".join(leader.skills),12,T.TEXT_SOFT,true)
			if assignment.active:
				Art.label(detail_body,Art.workforce(Art.team(item)),20,T.INK)
				Art.label(detail_body,"%.1f%% of the civilization’s shared research effort" % (float(assignment.capacity.workforce_share)*100),11,T.MUTED,true)
				var bar:ProgressBar=Gauge.new();bar.ink=Art.color(item.domain);detail_body.add_child(bar);bar.value=clampf(float(item.progress),0,1)*100
				Art.label(detail_body,"%d%% evidence · %s" % [roundi(float(item.progress)*100),Art.phase(item)],13,T.BODY,true)
				Art.label(detail_body,String(assignment.bottleneck).replace(" — ","\n"),12,T.TEXT_SOFT,true)
				Art.label(detail_body,assignment.method,12,T.TEXT_SOFT,true)
			else:
				Art.label(detail_body,"Team if selected: "+Art.workforce(float(assignment.capacity.researchers)),13,T.BODY,true)
				var current_id:=String(assignment.current_target)
				for current:Dictionary in all_records:
					if current.id==current_id and current.exposed:Art.label(detail_body,"This team is currently investigating "+String(current.name)+". Focusing here redirects that team's attention.",12,T.TEXT_SOFT,true)
		detail=Art.label(detail_body,item.description,13,T.BODY,true)
		if not String(item.get("operating_summary","")).is_empty():Art.label(detail_body,String(item.operating_summary),12,T.TEXT_SOFT,true)
		Art.label(detail_body,String(item.get("pathway_description","")),13,T.TEAL,true)
		for route:Dictionary in item.get("pathways",[]):
			Art.label(detail_body,("● " if bool(route.ready) else "○ ")+String(route.label),12,T.GREEN if bool(route.ready) else T.MUTED,true)
			var requirements:Array[String]=[]
			for req:String in route.get("requires_all",route.requires):requirements.append(_foundation_name(req))
			for group:Array in route.get("requires_any",[]):
				var choices:Array[String]=[]
				for req:String in group:choices.append(_foundation_name(req))
				requirements.append("("+" or ".join(choices)+")")
			if not requirements.is_empty():Art.label(detail_body,"Requires "+" + ".join(requirements),11,T.TEXT_SOFT,true)
			if float(route.get("progress_multiplier",1.0))!=1.0:Art.label(detail_body,"Research pace: %.2f× local baseline" % float(route.progress_multiplier),11,T.TEXT_SOFT,true)
		Art.button(detail_body,"Objects, knowledge & culture",func():preload("res://scripts/hud/exchange_collection_panel.gd").open())
		if item.exposed and not item.known and preload("res://scripts/reverse_engineering.gd").available():
			for specimen:String in preload("res://scripts/reverse_engineering.gd").specimens(String(item.id)):
				var subject:=String(item.id)
				var terms:Dictionary=preload("res://scripts/reverse_engineering.gd").quote(subject,specimen)
				var examine:=Button.new();examine.clip_text=true;examine.text="Consume 1 example for study: "+String(preload("res://scripts/research_specimens.gd").definition(specimen).output)
				examine.disabled=terms.has("error");examine.tooltip_text=String(terms.get("message",terms.get("error","")))
				examine.pressed.connect(func()->void:
					var result:Dictionary=preload("res://scripts/reverse_engineering.gd").begin(subject,specimen)
					examine.tooltip_text=String(result.get("message",result.get("error","")));examine.disabled=true
				)
				detail_body.add_child(examine)
		var license_note:=preload("res://scripts/research_licenses.gd").describe(String(item.id))
		if not license_note.is_empty():Art.label(detail_body,license_note,12,T.TEXT_SOFT,true)
		if preload("res://scripts/hud/research_purchase_panel.gd").visible_for(String(item.id), bool(item.exposed), bool(item.known)):
			var purchase:VBoxContainer=preload("res://scripts/hud/research_purchase_panel.gd").new()
			purchase.subject=String(item.id);detail_body.add_child(purchase)
		for effect:String in item.effects:Art.label(detail_body,"%+.1f%%  %s" % [float(item.effects[effect])*100,DiscoverySystem.EFFECT_DISPLAY_NAMES.get(effect,effect.replace("_"," "))],14,T.AMBER if effect in ["labor_demand","fuel_demand","pollution","ecological_pressure","injury_risk","disease_exposure"] and float(item.effects[effect])>0 else T.GREEN,true)
		if not item.requires.is_empty():
			Art.label(detail_body,"BUILDS ON",10,T.MUTED)
			for req:String in item.requires:
				var title:="Unexplored prerequisite"
				for previous:Dictionary in all_records:
					if previous.id==req and previous.exposed:title=String(previous.name)
				Art.label(detail_body,("✓ " if req in GameState.known_discoveries else "○ ")+title,12,T.TEXT_SOFT,true)
		for group:Array in item.get("requires_any",[]):
			var options:Array[String]=[]
			for req:String in group:
				var title:="Unexplored prerequisite"
				for previous:Dictionary in all_records:
					if previous.id==req and previous.exposed:title=String(previous.name)
				options.append(("✓ " if req in GameState.known_discoveries else "○ ")+title)
			Art.label(detail_body,"ONE OF: "+" or ".join(options),12,T.TEXT_SOFT,true)
		if not item.missing.is_empty():Art.label(detail_body,"Needs: "+", ".join(item.missing),12,T.AMBER,true)
		action=Art.button(detail_body,"Team already investigating" if assignment.get("active",false) else "Established knowledge" if item.known else "Focus this team here" if item.ready else "More evidence needed",_act)
		action.disabled=not item.ready or assignment.get("active",false)
		Art.button(detail_body,"Research staffing",_staffing)
		detail_scroll.set_deferred("scroll_vertical",old_scroll);return
	detail=Art.label(detail_body,"Select a discovery to see its team, supervising leader and findings.",14,T.TEXT_SOFT,true)
	action=null

func _discovery_date(item:Dictionary)->String:
	var absolute_day:=int(item.get("discovered_day",-1))
	if absolute_day<0:return "ESTABLISHED · DATE NOT RECORDED"
	return "DISCOVERED · YEAR %d, DAY %d" % [absolute_day/365+1,absolute_day%365+1]
func _act()->void:
	var result:=DiscoverySystem.select_research_target(selected_id)
	refresh(false)
	if not result.get("ok",false):detail.text=String(result.get("reason","This question is not available."))
func step(direction:int)->void:
	if records.is_empty():return
	var index:=0
	for i in records.size():
		if records[i].id==selected_id:index=i;break
	select(String(records[posmod(index+direction,records.size())].id));plot.center_selected()

func _foundation_name(id:String)->String:
	for previous:Dictionary in all_records:
		if previous.id==id and previous.exposed:return String(previous.name)
	return "unexplored foundation"
