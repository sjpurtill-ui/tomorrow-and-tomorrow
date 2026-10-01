extends Control
## People, active investigations and the knowledge frontier, read from the same
## capacity and leadership assignments used by the daily discovery simulation.
const Data=preload("res://scripts/hud/atlas_data.gd")
const Art=preload("res://scripts/hud/research_visuals.gd")
const TreePlot=preload("res://scripts/hud/research_tree_plot.gd")
const T=preload("res://scripts/hud/hud_tokens.gd")
const Indicators:=preload("res://scripts/civilization_indicators.gd")
const Gauge=preload("res://scripts/hud/military_roster_gauge.gd")
const Motion=preload("res://scripts/hud/motion.gd")
const Portrait=preload("res://scripts/hud/person_portrait.gd")
const EraWords=preload("res://scripts/hud/era_words.gd")
const Words=preload("res://scripts/hud/home_plain.gd")
const Plain=preload("res://scripts/hud/production_plain.gd")
const Explainer=preload("res://scripts/effect_explainer.gd")
const Ledger=preload("res://scripts/hud/impact_ledger.gd")
# The painting leads each card, full width; text below always wraps.
const CARD_WIDTH:=236.0
## About 2:1, between the wide banner paintings (about 2.7:1) and the older
## 3:2 and square plates, so every kind keeps most of its picture in a card.
const CARD_IMAGE_HEIGHT:=120.0
const CARD_GAP:=12.0
var mode:="inquiry"
var terrain:Node
var hud:Node
var layer:CanvasLayer
var domain:=""
var query:=""
var leader_filter:=""
var view_mode:="active"
var show_locked:=true
var tree_scope:="frontier"
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
## Field chips (domain id -> Button; "" is every field), view-scope chips and
## the notification chips. Plain text toggles; the chosen one is underlined.
var field_chips:Dictionary={}
var scope_chips:Dictionary={}
var notify_chips:Dictionary={}
var fields_row:HFlowContainer
var search:LineEdit
var legend:Label
var stats:Label
var locked_toggle:Button
var tree_controls:HFlowContainer
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
var detail_back:Button
## Effect rows opened in the detail pane's impact ledger (impact_ledger.gd).
var effect_state:Dictionary={}
func _ready()->void:
	# This overlay lives under a CanvasLayer, outside the dock theme hierarchy.
	theme=T.control_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dismiss:=ColorRect.new();dismiss.color=T.SCRIM;dismiss.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(dismiss)
	dismiss.gui_input.connect(func(event:InputEvent)->void:if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:_close())
	panel=PanelContainer.new();panel.mouse_filter=Control.MOUSE_FILTER_STOP;panel.add_theme_stylebox_override("panel",T.paper_panel_style(false,T.RADIUS_CARD,16));add_child(panel)
	var box:=VBoxContainer.new();box.add_theme_constant_override("separation",12);panel.add_child(box)
	var header:=HBoxContainer.new();header.add_theme_constant_override("separation",12);box.add_child(header)
	var titles:=VBoxContainer.new();titles.size_flags_horizontal=Control.SIZE_EXPAND_FILL;titles.add_theme_constant_override("separation",2);header.add_child(titles)
	Art.label(titles,"THE PEOPLE & THEIR IDEAS",12,T.MUTED)
	var heading:=Art.label(titles,"What the people are learning" if EraWords.hearth() else "Research",28,T.INK,true)
	heading.add_theme_font_override("font",Art.display_font())
	stats=Art.label(titles,"",14,T.TEXT_SOFT,true)
	Art.button(header,"Who does the work",_staffing).tooltip_text="Who works on each question, and how much attention each field gets"
	var close:=Art.button(header,"Close",_close);close.tooltip_text="Close · Escape or click outside"
	# One quiet row: the three views as text tabs, then a search box. Fields are
	# a row of plain chips below; nothing hides behind a dropdown.
	var navigation:=HBoxContainer.new();navigation.add_theme_constant_override("separation",4);box.add_child(navigation)
	for spec:Array in [["active","Being learned"],["tree","What could come next" if EraWords.hearth() else "Knowledge tree"],["known","What we know"]]:
		var id:=String(spec[0]);tabs[id]=Art.button(navigation,spec[1],func()->void:set_view(id));tabs[id].flat=true
	var spacer:=Control.new();spacer.size_flags_horizontal=Control.SIZE_EXPAND_FILL;navigation.add_child(spacer)
	search=LineEdit.new();search.placeholder_text="Find a discovery or a person";search.custom_minimum_size=Vector2(240,30);search.flat=true;search.add_theme_font_size_override("font_size",14)
	search.add_theme_stylebox_override("normal",_hairline());search.add_theme_stylebox_override("focus",_hairline(T.GOLD));navigation.add_child(search)
	search.text_changed.connect(func(value:String)->void:query=value;refresh(true))
	fields_row=HFlowContainer.new();fields_row.name="FieldChips";fields_row.add_theme_constant_override("h_separation",2);fields_row.add_theme_constant_override("v_separation",2);box.add_child(fields_row)
	for id:String in [""]+Art.NAMES.keys():
		var field:=id
		field_chips[id]=_chip(fields_row,"Every field" if id.is_empty() else Art.name_for(id),func()->void:domain=field;refresh(true))
	var rule:=ColorRect.new();rule.color=T.BORDER;rule.custom_minimum_size.y=1;rule.mouse_filter=Control.MOUSE_FILTER_IGNORE;box.add_child(rule)
	legend=Art.label(box,"",13,T.TEXT_SOFT,true)
	tree_controls=HFlowContainer.new();tree_controls.add_theme_constant_override("h_separation",6);box.add_child(tree_controls)
	Art.button(tree_controls,"Zoom out",func()->void:plot.zoom_at(1/1.15,plot.size*.5));Art.button(tree_controls,"Zoom in",func()->void:plot.zoom_at(1.15,plot.size*.5));Art.button(tree_controls,"Fit to window",func()->void:plot.fit());Art.button(tree_controls,"Show the chosen one",func()->void:plot.center_selected())
	var gap:=Control.new();gap.custom_minimum_size.x=12;tree_controls.add_child(gap)
	scope_chips["frontier"]=_chip(tree_controls,"Near what we are learning",func()->void:tree_scope="frontier";refresh(true))
	scope_chips["all"]=_chip(tree_controls,"Everything we could learn",func()->void:tree_scope="all";refresh(true))
	locked_toggle=_chip(tree_controls,"Show questions not yet open",func()->void:show_locked=not show_locked;refresh(true))
	detail_back=Art.button(box,"← Back to research",func()->void:narrow_details=false;_layout())
	main=BoxContainer.new();main.size_flags_vertical=Control.SIZE_EXPAND_FILL;main.add_theme_constant_override("separation",14);box.add_child(main)
	content=VBoxContainer.new();content.size_flags_horizontal=Control.SIZE_EXPAND_FILL;content.size_flags_vertical=Control.SIZE_EXPAND_FILL;main.add_child(content)
	scroll=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_AUTO;scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;content.add_child(scroll)
	grid=GridContainer.new();grid.columns=3;grid.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN;grid.add_theme_constant_override("h_separation",int(CARD_GAP));grid.add_theme_constant_override("v_separation",10);scroll.add_child(grid)
	plot=TreePlot.new();plot.owner_view=self;plot.size_flags_vertical=Control.SIZE_EXPAND_FILL;plot.custom_minimum_size=Vector2(0,140);content.add_child(plot)
	empty=VBoxContainer.new();content.add_child(empty)
	detail_scroll=ScrollContainer.new();detail_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;detail_scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;main.add_child(detail_scroll)
	detail_body=VBoxContainer.new();detail_body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;detail_body.add_theme_constant_override("separation",9);detail_scroll.add_child(detail_body)
	var notify:=HFlowContainer.new();notify.name="NotifyChips";notify.add_theme_constant_override("h_separation",2);box.add_child(notify)
	var notify_label:=T.make_label("Tell me about new discoveries:",13,T.TEXT_SOFT);notify_label.size_flags_vertical=Control.SIZE_SHRINK_CENTER;notify.add_child(notify_label)
	for spec:Array in [["milestones","Only the big ones"],["all","Every one"],["quiet","Only in the season's digest"]]:
		var mode_id:=String(spec[0])
		notify_chips[mode_id]=_chip(notify,spec[1],func()->void:GameState.research_notification_mode=mode_id;_update_chips())
	panel.minimum_size_changed.connect(_layout.call_deferred)
	resized.connect(_layout);_layout();refresh(true)
	# The sheet fades in over the scrim and rises 8 px into place (SLOW).
	Motion.fade_in(self);Motion.rise_in.call_deferred(panel)
## A chip: a plain text toggle. The chosen one carries a gold rule beneath it.
func _chip(parent:Node,text:String,callback:Callable)->Button:
	var chip:=Button.new();chip.text=text;chip.focus_mode=Control.FOCUS_NONE
	chip.add_theme_font_size_override("font_size",13);chip.custom_minimum_size.y=30
	chip.pressed.connect(callback);parent.add_child(chip);_style_chip(chip,false);return chip
func _style_chip(chip:Button,on:bool)->void:
	var mark:=StyleBoxFlat.new();mark.bg_color=T.ACTIVE_BG if on else Color(0,0,0,0);mark.border_color=T.GOLD if on else Color(0,0,0,0);mark.border_width_bottom=2
	mark.content_margin_left=8;mark.content_margin_right=8;mark.content_margin_top=3;mark.content_margin_bottom=4
	for state:String in ["normal","hover","pressed","focus"]:chip.add_theme_stylebox_override(state,mark)
	chip.add_theme_color_override("font_color",T.INK if on else T.BODY);chip.add_theme_color_override("font_hover_color",T.INK)
func _update_chips()->void:
	for id:String in field_chips:_style_chip(field_chips[id],id==domain)
	for id:String in scope_chips:_style_chip(scope_chips[id],id==tree_scope)
	for id:String in notify_chips:_style_chip(notify_chips[id],id==String(GameState.research_notification_mode))
	if is_instance_valid(locked_toggle):
		_style_chip(locked_toggle,show_locked)
		locked_toggle.text="Hide questions not yet open" if show_locked else "Show questions not yet open"
func _hairline(ink:Color=T.BORDER)->StyleBoxFlat:
	var line:=StyleBoxFlat.new();line.bg_color=Color(0,0,0,0);line.border_color=ink;line.border_width_bottom=1
	line.content_margin_left=6;line.content_margin_right=6;line.content_margin_top=4;line.content_margin_bottom=4;return line
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
	plot.queue_redraw()
func _update_grid_columns()->void:
	if not is_instance_valid(scroll) or not is_instance_valid(grid):return
	grid.columns=maxi(1,floori((scroll.size.x+CARD_GAP)/(CARD_WIDTH+CARD_GAP)))
func set_view(value:String)->void:
	var changed:=value!=view_mode
	view_mode=value;narrow_details=false;_layout();refresh(true)
	# Tabs cross-fade (BASE) rather than snapping.
	if changed:Motion.cross_fade(main)
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
	# Not looked at (hidden behind another screen): no daily rebuild work.
	if not is_visible_in_tree():return
	elapsed+=delta
	if elapsed<.75:return
	elapsed=0
	var next:=str(hash([int(GameState.elapsed_days),GameState.discovery_progress,GameState.active_investigations,GameState.known_discoveries,GameState.research_subcategory_allocations,GameState.population_allocations,GameState.leadership_positions,GameState.food_security,GameState.society_capacities]))
	if next!=revision:revision=next;refresh(false)
func refresh(refit:bool)->void:
	all_records=Data.inquiry()
	_update_chips()
	var active:=0;var staffed:=0;var known:=0;var people:Dictionary={}
	for item:Dictionary in all_records:
		if item.known:known+=1
		var assignment:Dictionary=item.assignment
		if assignment.get("active",false):active+=1;staffed+=1 if Art.team(item)>0 else 0
		var lead:=Art.lead(item)
		if not lead.is_empty():people[lead]=true
	# Leaders are found through the search box; a leader filter set in code
	# (tests, links) is dropped once that leader no longer leads anything.
	if leader_filter!="" and not people.has(leader_filter):leader_filter=""
	var science:=Indicators.science()
	var era_words:GDScript=preload("res://scripts/hud/era_words.gd")
	if bool(era_words.call("reckoned")):stats.text="About %s people work at learning, and about %d in 10 of what they learn is kept and taught. %d of %d questions have people on them." % [Plain.number(float(science.minds)),roundi(float(science.education)*10.0),staffed,active]
	else:stats.text="%d keeping the lore, taught %s. %s of %s questions have hands on them." % [roundi(float(science.minds)),String(era_words.call("teaching",float(science.education))),String(era_words.call("count_word",staffed)).capitalize(),String(era_words.call("count_word",active))]
	tabs.active.text="Being learned · %d" % active;tabs.known.text="What we know · %d" % known
	for id:String in tabs:
		var tab:Button=tabs[id]
		tab.modulate=Color.WHITE
		# Text tabs: the chosen one carries a 2 px gold rule beneath it.
		var mark:=StyleBoxFlat.new();mark.bg_color=Color(0,0,0,0);mark.border_color=T.GOLD if id==view_mode else Color(0,0,0,0);mark.border_width_bottom=2
		mark.content_margin_left=8;mark.content_margin_right=8;mark.content_margin_top=4;mark.content_margin_bottom=6
		for state:String in ["normal","hover","pressed","focus"]:tab.add_theme_stylebox_override(state,mark)
		tab.add_theme_font_size_override("font_size",15)
		tab.add_theme_color_override("font_color",T.INK if id==view_mode else T.TEXT_SOFT);tab.add_theme_color_override("font_hover_color",T.INK)
	records.clear()
	var hidden:=0
	for item:Dictionary in all_records:
		if domain!="" and item.domain!=domain:continue
		if leader_filter!="" and Art.lead(item)!=leader_filter:continue
		if query!="" and not (String(item.name)+" "+Art.lead(item)+" "+Art.name_for(item.domain)).to_lower().contains(query.to_lower()):continue
		if view_mode=="active" and not item.assignment.get("active",false):continue
		if view_mode=="known" and not item.known:continue
		# Only the next reachable questions are drawn; deeper ones become a count.
		if view_mode=="tree" and not item.exposed and (not show_locked or item.get("beyond",false)):hidden+=1;continue
		records.append(item)
	if view_mode=="tree" and tree_scope=="frontier" and query.is_empty():records=_frontier_records(records)
	if view_mode=="active":records.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return Art.lead(a)+String(a.name)<Art.lead(b)+String(b.name))
	legend.text="Each question has a leader and a few helpers. Pick a card to see who works on it and how far they have come." if view_mode=="active" else _tree_legend(hidden) if view_mode=="tree" else "What your people already know. Pick a card to see what it changed."
	tree_controls.visible=view_mode=="tree";plot.visible=view_mode=="tree" and not records.is_empty();scroll.visible=view_mode!="tree" and not records.is_empty();empty.visible=records.is_empty()
	if records.is_empty():
		for child in empty.get_children():empty.remove_child(child);child.queue_free()
		Art.paint(empty,domain if domain!="" else "knowledge",125)
		Art.label(empty,"No matching investigations" if query!="" or domain!="" or leader_filter!="" else "No active investigation yet" if view_mode=="active" else "No discoveries in this view",20,T.INK,true)
		Art.label(empty,"Pick \"Every field\" or clear the search. The knowledge tree shows the questions your people could take up next.",13,T.TEXT_SOFT,true)
		if view_mode=="active":Art.button(empty,"Explore the knowledge tree",func()->void:set_view("tree"))
	var ids:Array=[]
	for item:Dictionary in records:ids.append(item.id)
	var layout_key:=view_mode+str(ids)
	if layout_key!=last_layout:
		last_layout=layout_key;plot.arrange();_build_cards()
		if refit and view_mode=="tree":plot.call_deferred("fit")
	elif refit and view_mode=="tree":plot.call_deferred("fit")
	if selected_id not in ids:selected_id=String(ids[0]) if not ids.is_empty() else ""
	_update_cards();select(selected_id)
func _build_cards()->void:
	for child in grid.get_children():grid.remove_child(child);child.queue_free()
	bindings.clear()
	if view_mode=="tree":return
	for item:Dictionary in records:
		var frame:=PanelContainer.new();frame.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN;frame.custom_minimum_size.x=CARD_WIDTH;grid.add_child(frame)
		var box:=VBoxContainer.new();box.add_theme_constant_override("separation",0);frame.add_child(box)
		var painting:=Art.paint_discovery(box,item,CARD_IMAGE_HEIGHT,scroll)
		var margin:=MarginContainer.new()
		for edge:String in ["left","right"]:margin.add_theme_constant_override("margin_"+edge,14)
		margin.add_theme_constant_override("margin_top",10);margin.add_theme_constant_override("margin_bottom",14)
		box.add_child(margin)
		var body:=VBoxContainer.new();body.add_theme_constant_override("separation",4);margin.add_child(body)
		var status:=Art.label(body,"",12,Art.text_color(item.domain),true)
		var name:=Art.label(body,String(item.name),20,T.INK,true);name.add_theme_font_override("font",Art.voice_font())
		var date:=Art.label(body,"",12,T.GOLD_TEXT,true)
		var lead:=Art.label(body,"",14,T.BODY,true)
		var team:=Art.label(body,"",14,T.TEXT_SOFT,true)
		var meter:ProgressBar=Gauge.new();meter.ink=Art.color(item.domain);body.add_child(meter)
		var note:=Art.label(body,"",12,T.TEXT_SOFT,true)
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
		# Selection: a 1 px gold edge with a gold tab on top, never a heavy outline.
		var chosen:bool=item.id==selected_id
		var face:=T.flat(T.PAPER_RAISED,T.GOLD if chosen else T.BORDER,1,4,0)
		if chosen:face.border_width_top=3
		card.frame.add_theme_stylebox_override("panel",face)
		card.status.text=Art.name_for(item.domain).to_upper()
		card.date.text=_discovery_date(item)
		card.date.visible=bool(item.known)
		var active:bool=item.assignment.get("active",false)
		# One era sentence: who leads, and how many hands help them.
		card.lead.text=Art.team_sentence(item) if active else (Art.lead(item) if not Art.lead(item).is_empty() else String(item.subcategory).capitalize())
		card.team.text=Art.evidence_sentence(item)+(" "+Art.phase(item)+"." if not Art.phase(item).is_empty() else "")
		card.team.visible=active;card.meter.visible=active;card.meter.value=clampf(float(item.progress),0,1)*100
		card.note.text=Art.status(item) if not active and not bool(item.known) else ""
		card.note.visible=not card.note.text.is_empty()
func select(id:String,open_detail:bool=false)->void:
	if open_detail and main.vertical:narrow_details=true;_layout()
	selected_id=id;plot.queue_redraw();_update_cards()
	var selected_record:Dictionary={}
	for item:Dictionary in records:
		if item.id==id:selected_record=item;break
	var signature:=str(hash([id,selected_record,main.vertical,GameState.discovery_adoption.get(id,0.0)]))
	if signature==detail_revision:return
	detail_revision=signature
	var view:Dictionary=preload("res://scripts/hud/view_state.gd").capture(detail_scroll) if detail_selected==id else {};detail_selected=id
	for child in detail_body.get_children():detail_body.remove_child(child);child.queue_free()
	for item:Dictionary in records:
		if item.id!=id:continue
		Art.paint_hero(detail_body,item,100,200 if not main.vertical else 180)
		Art.label(detail_body,Art.name_for(item.domain).to_upper(),12,Art.text_color(item.domain),true)
		Art.label(detail_body,item.name,26,T.INK,true).add_theme_font_override("font",Art.voice_font())
		Art.label(detail_body,Art.status(item),14,Art.text_color(item.domain),true)
		if item.known:Art.label(detail_body,_discovery_sentence(item),12,T.GOLD_TEXT,true)
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
			if not definition.get("preservation_profile",{}).is_empty() or not definition.get("training_profile",{}).is_empty() or not definition.get("prospecting_profile",{}).is_empty() or not String(definition.get("medical_method","")).is_empty() or not definition.get("agronomy_profile",{}).is_empty():Art.label(detail_body,WorldSimulation.discovery._discovery_effect_summary(definition),12,T.TEXT_SOFT,true)
		var assignment:Dictionary=item.assignment
		if not assignment.is_empty():
			var leader:Dictionary=assignment.leader
			var row:=HBoxContainer.new();row.add_theme_constant_override("separation",10);detail_body.add_child(row)
			if not bool(leader.vacant):
				# The leader's own painted portrait, never initials.
				var person:Dictionary={}
				if int(leader.get("person_id",0))>0:person=GovernmentPeopleSystem.person_snapshot(int(leader.person_id))
				if person.is_empty():person={"name":String(leader.name),"person_id":int(leader.get("person_id",0))}
				var face_frame:=PanelContainer.new();face_frame.add_theme_stylebox_override("panel",T.flat(T.PAPER_SUNK,T.BORDER,1,2,2));row.add_child(face_frame)
				face_frame.add_child(Portrait.picture(person,64,76))
			var who:=VBoxContainer.new();who.size_flags_horizontal=Control.SIZE_EXPAND_FILL;who.alignment=BoxContainer.ALIGNMENT_CENTER;row.add_child(who)
			Art.label(who,"WHO LEADS IT",12,T.MUTED);Art.label(who,leader.name,18,T.INK,true).add_theme_font_override("font",Art.voice_font())
			Art.label(who,String(leader.office)+(" · acting for "+String(leader.requested_office) if leader.acting else ""),12,T.TEXT_SOFT,true)
			Art.label(detail_body,_leader_line(leader),12,T.TEXT_SOFT,true)
			if assignment.active:
				Art.label(detail_body,Art.team_sentence(item),18,T.INK,true).add_theme_font_override("font",Art.voice_font())
				Art.label(detail_body,"About %d in every 100 hours our people spend on learning go to this." % maxi(1,roundi(float(assignment.capacity.workforce_share)*100)),12,T.MUTED,true)
				var bar:ProgressBar=Gauge.new();bar.ink=Art.color(item.domain);detail_body.add_child(bar);bar.value=clampf(float(item.progress),0,1)*100
				Art.label(detail_body,_first_upper(Words.evidence(float(item.progress)))+("; "+Art.phase(item).to_lower() if not Art.phase(item).is_empty() else "")+".",13,T.BODY,true)
				Art.label(detail_body,Art.plain_bottleneck(String(assignment.bottleneck)),12,T.TEXT_SOFT,true)
				Art.label(detail_body,assignment.method,12,T.TEXT_SOFT,true)
			else:
				Art.label(detail_body,"If you choose it: "+Words.researchers(float(assignment.capacity.researchers)).to_lower()+" would work on it.",13,T.BODY,true)
				var current_id:=String(assignment.current_target)
				for current:Dictionary in all_records:
					if current.id==current_id and current.exposed:Art.label(detail_body,"This team is currently investigating "+String(current.name)+". Focusing here redirects that team's attention.",12,T.TEXT_SOFT,true)
		detail=Art.label(detail_body,item.description,13,T.BODY,true)
		if not String(item.get("operating_summary","")).is_empty():Art.label(detail_body,String(item.operating_summary),12,T.TEXT_SOFT,true)
		Art.label(detail_body,String(item.get("pathway_description","")),13,T.TEAL,true)
		for route:Dictionary in item.get("pathways",[]):
			Art.label(detail_body,String(route.label)+(" (open now)" if bool(route.ready) else " (not yet open)"),12,T.GREEN_TEXT if bool(route.ready) else T.MUTED,true)
			var requirements:Array[String]=[]
			for req:String in route.get("requires_all",route.requires):requirements.append(_foundation_name(req))
			for group:Array in route.get("requires_any",[]):
				var choices:Array[String]=[]
				for req:String in group:choices.append(_foundation_name(req))
				requirements.append("("+" or ".join(choices)+")")
			if not requirements.is_empty():Art.label(detail_body,"Needs "+" and ".join(requirements),12,T.TEXT_SOFT,true)
			var pace:=float(route.get("progress_multiplier",1.0))
			if not is_equal_approx(pace,1.0):Art.label(detail_body,"This way is about %d%% %s." % [roundi(absf(pace-1.0)*100),"faster" if pace>1.0 else "slower"],12,T.TEXT_SOFT,true)
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
			# Help from abroad is asked for in the court, never through a form here.
			var abroad:VBoxContainer=preload("res://scripts/hud/research_purchase_panel.gd").new()
			abroad.subject=String(item.id);detail_body.add_child(abroad)
		if not (item.effects as Dictionary).is_empty():
			# Each effect: its size, what it adds now (or would at full use), and
			# a click away, everywhere the engine reads it.
			Art.label(detail_body,"WHAT IT DOES" if item.known else "WHAT IT WOULD DO",12,T.GOLD_TEXT)
			var ledger:VBoxContainer=Ledger.new();detail_body.add_child(ledger)
			ledger.setup({"state":effect_state,"rows":Explainer.discovery_rows(String(item.id),bool(item.known)),
				"intro":"Open an effect to see everywhere it acts." if item.known else "At full use. A new practice starts with about 3 in 100 households and spreads over years. Open an effect to see everywhere it would act."})
		if not item.requires.is_empty():
			Art.label(detail_body,"BUILDS ON",12,T.MUTED)
			for req:String in item.requires:
				var title:="Unexplored prerequisite"
				for previous:Dictionary in all_records:
					if previous.id==req and previous.exposed:title=String(previous.name)
				Art.label(detail_body,title+(" (known)" if req in GameState.known_discoveries else " (not yet known)"),12,T.TEXT_SOFT,true)
		for group:Array in item.get("requires_any",[]):
			var options:Array[String]=[]
			for req:String in group:
				var title:="Unexplored prerequisite"
				for previous:Dictionary in all_records:
					if previous.id==req and previous.exposed:title=String(previous.name)
				options.append(title+(" (known)" if req in GameState.known_discoveries else ""))
			Art.label(detail_body,"And any one of: "+" or ".join(options),12,T.TEXT_SOFT,true)
		var possibilities:=_branching_possibilities(item)
		if not possibilities.is_empty():
			Art.label(detail_body,"WHAT IT CAN LEAD TO",12,T.GOLD_TEXT)
			for possibility:Dictionary in possibilities:
				Art.label(detail_body,String(possibility.name)+": "+String(possibility.relation),12,T.text_for(possibility.color),true)
		if not item.missing.is_empty():Art.label(detail_body,"Still needed: "+", ".join(item.missing),12,T.AMBER_TEXT,true)
		action=Art.button(detail_body,"Being worked on now" if assignment.get("active",false) else "Already known" if item.known else "Put this team on it" if item.ready else "Not open yet: more is needed first",_act)
		action.disabled=not item.ready or assignment.get("active",false)
		Art.button(detail_body,"Who does the work",_staffing)
		# Re-applied until the rebuilt detail has laid out; a single deferred
		# assignment is clamped to the empty pane and snaps to the top.
		preload("res://scripts/hud/view_state.gd").restore(detail_scroll,view);return
	detail=Art.label(detail_body,"Pick a card to see who works on it and what it would bring.",14,T.TEXT_SOFT,true)
	action=null

func _frontier_records(source:Array[Dictionary])->Array[Dictionary]:
	# A useful default map follows work happening now. If there is no active
	# investigation, show a bounded selection of questions that can be started.
	var anchors:Array[String]=[]
	for item:Dictionary in source:
		if item.get("assignment",{}).get("active",false):anchors.append(String(item.id))
	if anchors.is_empty():
		for item:Dictionary in source:
			if bool(item.get("ready",false)) and not bool(item.get("known",false)):
				anchors.append(String(item.id))
				if anchors.size()>=12:break
	if anchors.is_empty() and not source.is_empty():anchors.append(String(source[-1].id))
	var included:Dictionary={}
	for id:String in anchors:included[id]=true
	for item:Dictionary in source:
		if String(item.id) not in anchors:continue
		for parent:String in _tree_parents(item):included[parent]=true
	# The next nodes make the consequence of choosing an active line visible.
	# Bound each fan-out so one highly reused foundation cannot recreate the mess.
	for anchor:String in anchors:
		var shown:=0
		for item:Dictionary in source:
			if anchor in _tree_parents(item):included[String(item.id)]=true;shown+=1
			if shown>=4:break
	var result:Array[Dictionary]=[]
	for item:Dictionary in source:
		if included.has(String(item.id)):result.append(item)
	return result

func _tree_parents(item:Dictionary)->Array[String]:
	var result:Array[String]=[]
	for id:String in item.get("requires",[]):if id not in result:result.append(id)
	for group:Array in item.get("requires_any",[]):
		for id:String in group:if id not in result:result.append(id)
	for route:Dictionary in item.get("pathways",[]):
		for id:String in preload("res://scripts/technology_requirements.gd").parents(route):if id not in result:result.append(id)
	return result

func _tree_legend(hidden:int)->String:
	var forks:=0;var approaches:=0
	for item:Dictionary in records:
		forks+=(item.get("requires_any",[]) as Array).size()
		approaches+=maxi(0,(item.get("pathways",[]) as Array).size()-1)
	var scope:="Near what we are learning" if tree_scope=="frontier" and query.is_empty() else "Every matching question"
	var parts:Array[String]=["%s: %d question%s." % [scope,records.size(),"" if records.size()==1 else "s"]]
	parts.append("A solid line means one question needs the other first; a teal dashed line means any one of several will do; a dotted line is another way to the same knowledge.")
	parts.append("Drag to move around; scroll to zoom.")
	if hidden>0:parts.append("%d further questions beyond these open later." % hidden)
	return " ".join(parts)

func _branching_possibilities(item:Dictionary)->Array[Dictionary]:
	var result:Array[Dictionary]=[];var id:=String(item.id)
	for candidate:Dictionary in all_records:
		if candidate.id==id:continue
		var relation:="";var marker:=""
		if id in candidate.get("requires",[]):relation="needs this first";marker="→"
		else:
			for group:Array in candidate.get("requires_any",[]):
				if id in group:relation="this is one of several ways in";marker="◇";break
		if relation.is_empty():
			for route:Dictionary in candidate.get("pathways",[]):
				if id in preload("res://scripts/technology_requirements.gd").parents(route):relation="helps another way to reach it";marker="⋯";break
		if relation.is_empty():continue
		result.append({"name":String(candidate.name),"relation":relation,"marker":marker,"color":T.TEAL if marker=="◇" else T.GREEN if marker=="⋯" else T.TEXT_SOFT,"exposed":bool(candidate.exposed)})
	result.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return ("0" if a.exposed else "1")+String(a.name)<("0" if b.exposed else "1")+String(b.name))
	if result.size()>8:result.resize(8)
	return result

func _discovery_date(item:Dictionary)->String:
	var absolute_day:=int(item.get("discovered_day",-1))
	if absolute_day<0:return "KNOWN SINCE BEFORE WE SET OUT"
	return "LEARNED · "+EraWords.when(absolute_day).to_upper()
static func _first_upper(text:String)->String:
	return text.left(1).to_upper()+text.substr(1)

## The leader's own skills in what this line needs, and how much faster (or
## slower) it goes under them than under an ordinary holder of the office
## (office_levers.research_pace: the engine's own execution).
static func _leader_line(leader:Dictionary)->String:
	var needs:Array=leader.get("skills",[])
	var office:=String(leader.get("office",""))
	if bool(leader.get("vacant",false)):
		var empty:=preload("res://scripts/office_levers.gd").research_pace({},office,needs)
		return "Needs %s. With nobody to lead it, it goes %d%% slower than under an ordinary %s." % [", ".join(PackedStringArray(needs)).to_lower(),roundi(absf(1.0-empty)*100.0),String(leader.get("requested_office",office)).to_lower()]
	var person:Dictionary=GovernmentPeopleSystem.person_snapshot(int(leader.get("person_id",0)))
	if person.is_empty(): return "Needs %s." % ", ".join(PackedStringArray(needs)).to_lower()
	var theirs:PackedStringArray=PackedStringArray()
	for skill in needs: theirs.append("%s %d" % [String(skill).to_lower(),roundi(GovernmentPeopleSystem.skill_value(person,String(skill)))])
	var pace:=preload("res://scripts/office_levers.gd").research_pace(person,office,needs)
	var pct:=roundi(absf(pace-1.0)*100.0)
	var given:=String(person.get("name","")).get_slice(" ",0)
	var speed:="as fast as under an ordinary leader" if pct==0 else "%d%% %s than under an ordinary leader (skills 47)" % [pct,"faster" if pace>=1.0 else "slower"]
	return "%s's %s: this line goes %s." % [given,", ".join(theirs),speed]
func _discovery_sentence(item:Dictionary)->String:
	var absolute_day:=int(item.get("discovered_day",-1))
	if absolute_day<0:return "Known since before we set out."
	return "Learned in %s (%s)." % [EraWords.when(absolute_day),EraWords.ago(absolute_day)]
func _act()->void:
	var result:=DiscoverySystem.select_research_target(selected_id)
	refresh(false)
	if not result.get("ok",false):detail.text=String(result.get("reason","This question cannot be taken up yet."))
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
