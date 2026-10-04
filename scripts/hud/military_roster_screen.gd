extends CanvasLayer
## The military screen over the real world: forces, recruitment, training and
## supply, as HOI4 shows them. Every figure comes from the one ledger's
## readings. For the army, Forces is the army overview (hud/forces_board.gd:
## one row per army with the army bar's numbers) and Readiness & supply the
## logistics view (hud/readiness_board.gd: the supply model's lines and the
## gear each force lacks); sentences live in their tooltips. Boats and air
## craft keep their service cards (hud/military_force_story.gd). Paper and
## ink, as the court and production screens.
const Art=preload("res://scripts/hud/military_roster_visuals.gd")
const Gauge=preload("res://scripts/hud/military_roster_gauge.gd")
const Story=preload("res://scripts/hud/military_force_story.gd")
const T=preload("res://scripts/hud/hud_tokens.gd")
const EraWords=preload("res://scripts/hud/era_words.gd")
const ForcesBoard=preload("res://scripts/hud/forces_board.gd")
const ReadinessBoard=preload("res://scripts/hud/readiness_board.gd")
const WarLedger=preload("res://scripts/hud/war_ledger_board.gd")
const LeadersBoard=preload("res://scripts/hud/leaders_board.gd")
const WarBoard=preload("res://scripts/hud/war_board.gd")
const WarLedgerModel=preload("res://scripts/hud/war_ledger_model.gd")
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
## The army's Forces board (also the strip over its Training page) and its
## Readiness & supply board, while shown.
var forces_board:VBoxContainer
var readiness_board:VBoxContainer
var army_filter:="all"
## The page buttons' row: hidden for the army, whose one page is the War
## screen (hud/war_board.gd); boats and aircraft keep their pages.
var nav_row:Control

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
		var button:=_button(header,_service_name(domain),func():service=choice;page="war" if choice=="army" else ("forces" if page=="war" else page);selected_row={};roster_filter="all";scroll.scroll_vertical=0;_build_body())
		button.icon=Art.symbol(domain,accent(domain),22)
		button.toggle_mode=true;service_buttons[domain]=button
		# A lone land force needs no service switch; nor does the War screen
		# until the people have boats or wings that fight.
		button.visible=services.size()>1 and _has_crews(services)
	close_button=_button(header,"×",queue_free);close_button.custom_minimum_size=Vector2(40,38);close_button.tooltip_text="Close · Escape or click the map"
	var nav:=HFlowContainer.new();nav.add_theme_constant_override("h_separation",6);column.add_child(nav);nav_row=nav
	for entry:Array in [["leaders","Leaders"],["forces","Forces"],["recruitment","Recruit & deploy"],["training","Training"],["support","Readiness & supply"],["wars",_wars_label()]]:
		var key:=String(entry[0]);var button:=_button(nav,String(entry[1]),func():_show_page(key))
		button.toggle_mode=true;page_buttons[key]=button
	page_buttons.leaders.tooltip_text="Your leaders and the bands under each: put bands under a leader, and they see to supply, gear, organization and pacing."
	page_buttons.wars.tooltip_text="Every feud and war with a people we know: the dead, their strength against ours, how worn each side is, and what would end it."
	roster_button=page_buttons.forces;training_button=page_buttons.training;management_button=page_buttons.recruitment
	var map_button:=_button(nav,"Command on map ↗",_map_command)
	map_button.tooltip_text="Give objectives to this service on the world map. Leaders execute them."
	var rule:=ColorRect.new();rule.color=T.RULE;rule.custom_minimum_size.y=1;column.add_child(rule)
	scroll=ScrollContainer.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;column.add_child(scroll)
	body=VBoxContainer.new();body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;body.add_theme_constant_override("separation",10);scroll.add_child(body)
	_layout();_build_body()
	# The HUD moves its alerts and the army bar for the War screen's strip
	# and column while it is open, and back when it closes.
	tree_exited.connect(_tell_hud)
	_tell_hud.call_deferred()

## The HUD shell (hud/command_rail_hud.gd), when this screen stands over the game.
func _hud()->Node:
	var tree:=Engine.get_main_loop() as SceneTree
	var scene:=tree.current_scene if tree!=null else null
	if scene==null or not ("hud" in scene):return null
	var hud:Variant=scene.get("hud")
	return hud if hud is Node and is_instance_valid(hud) else null

func _tell_hud()->void:
	var hud:=_hud()
	if hud==null:return
	if hud.has_method("_layout"):hud.call_deferred("_layout")
	var bar:Variant=hud.get("army_bar")
	if bar is Node and is_instance_valid(bar) and (bar as Node).has_method("refresh"):(bar as Node).call_deferred("refresh")

## The War screen's column: the right edge, from under the top bar down to
## what stands at the bottom right (the council's queue, your orders).
func _layout_war(view:Vector2)->void:
	layout_size=Vector2.ZERO
	var width:=float(WarBoard.COLUMN_WIDTH)
	var top:=T.CONTENT_TOP
	var bottom:=view.y-T.EDGE_MARGIN
	var hud:=_hud()
	if hud!=null and hud.has_method("right_stack_top"):bottom=minf(bottom,float(hud.call("right_stack_top")))
	bottom-=4.0
	panel.position=Vector2(view.x-T.EDGE_MARGIN-width,top)
	var column:VBoxContainer=panel.get_child(0)
	var content:=30.0+body.get_combined_minimum_size().y
	var shown:=0
	for child:Control in column.get_children():
		if not child.visible:continue
		shown+=1
		if child!=scroll:content+=child.get_combined_minimum_size().y
	content+=column.get_theme_constant("separation")*maxi(0,shown-1)
	panel.size=Vector2(width,clampf(content,160.0,maxf(160.0,bottom-top)))

## The panel's paper and heading: the War screen's narrow column, or the
## large sheet boats and aircraft keep.
func _skin_panel()->void:
	var war:=war_mode()
	var sheet:=T.paper_panel_style(false,T.RADIUS_CARD,14 if war else 24);sheet.border_color=T.RULE_STRONG
	sheet.shadow_color=Color(0,0,0,.18 if T.is_light() else .45);sheet.shadow_size=10 if war else 18;sheet.shadow_offset=Vector2(0,4 if war else 6)
	panel.add_theme_stylebox_override("panel",sheet)
	T.text(heading,"title",TEXT)
	if war:heading.add_theme_font_size_override("font_size",22)
	close_button.custom_minimum_size=Vector2(32,30) if war else Vector2(40,38)
	(panel.get_child(0) as VBoxContainer).add_theme_constant_override("separation",8 if war else 12)

## Whether any boat or air crews of ours are raised (joint_operations forces).
func _has_crews(services:Array[String])->bool:
	for force:Dictionary in MilitaryCampaign.joint_operations.state.get("forces",[]):
		if String(force.get("owner",""))=="player" and String(force.get("domain","")) in services:return true
	return service!="army"

func _service_name(domain:String)->String:
	if domain=="navy":return "Boats" if EraWords.hearth() else "Fleet"
	return {"army":"Army","air":"Air force"}.get(domain,"Army")

func _skin(bg:Color,border:Color=Color.TRANSPARENT,margin:int=10)->StyleBoxFlat:
	var style:=StyleBoxFlat.new();style.bg_color=bg;style.border_color=border;style.set_border_width_all(1 if border.a>0 else 0)
	style.set_corner_radius_all(T.RADIUS_CARD);style.set_content_margin_all(margin);return style

## The War screen (the army's one page) keeps the map as the screen, as HOI4
## does: this panel is the narrow column at the right edge, the strip of
## numbers stands under the clock (war_board.gd) and the army bar along the
## bottom (army_bar.gd war_cards). Boats and aircraft keep the large panel.
func war_mode()->bool:
	return service=="army" and page=="war"

func _layout()->void:
	var view:=get_viewport().get_visible_rect().size
	if war_mode():
		_layout_war(view)
		return
	if view!=layout_size:
		layout_size=view
		var inset:=maxf(16,view.x*.045)
		panel.position=Vector2(inset,T.CONTENT_TOP);panel.size=Vector2(view.x-inset*2,view.y-100)
		for board:Node in [forces_board,readiness_board]:
			if is_instance_valid(board):board.call("set_available_width",_body_width())
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
	var heading:=_label(body,Story.sentence_name(String(template.name)));T.text(heading,"voice",TEXT)
	heading.tooltip_text="Who is in this kind of band. Changing it raises nobody; press Train for that."
	heading.mouse_filter=Control.MOUSE_FILTER_PASS
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

## Boats and air craft: one card each with its condition, crews and task.
func _support_data()->Array:
	var items:Array=[]
	for force:Dictionary in _rows():
		items.append({"id":String(force.id),"label":String(force.name).to_upper(),"value":"%.0f%% condition" % (float(force.get("condition",0))*100),"note":String(force.get("equipment_note",""))+" · "+String(force.get("activity",""))})
	if items.is_empty():items.append({"id":"empty","label":"SERVICE READINESS","value":"No forces in service","note":"Their condition and crews show here."})
	return items

## "Feuds · 2" (or "Wars & feuds" once a war is fought): the page's tab, with
## how many are open.
func _wars_label()->String:
	var entries:=WarLedgerModel.entries()
	var open:=entries.filter(func(e:Dictionary)->bool: return String(e.kind)!="ended")
	var word:="Wars & feuds" if open.any(func(e:Dictionary)->bool: return String(e.kind)=="war") else "Feuds"
	return "%s · %d" % [word,open.size()] if not open.is_empty() else word

## The War screen: the army's one page (hud/war_board.gd).
func _war()->void:
	var board:=WarBoard.new();body.add_child(board)
	board.setup({})
	board.close_wanted.connect(queue_free)

## The Military Leaders screen: commands by leader (hud/leaders_board.gd).
func _leaders()->void:
	var board:=LeadersBoard.new();body.add_child(board)
	board.setup({})
	board.close_wanted.connect(queue_free)

## Feuds and wars, as HOI4's war overview (hud/war_ledger_board.gd).
func _wars()->void:
	var board:=WarLedger.new();body.add_child(board)
	board.setup({})

## Readiness & supply. The army: HOI4's logistics view (hud/readiness_board.gd).
func _support()->void:
	if service=="army":
		readiness_board=ReadinessBoard.new();body.add_child(readiness_board)
		readiness_board.setup({"width":_body_width()})
		readiness_board.close_wanted.connect(queue_free)
		support_labels=readiness_board.chips
		return
	var grid:=GridContainer.new();grid.columns=2 if panel.size.x>=760 else 1;grid.add_theme_constant_override("h_separation",12);grid.add_theme_constant_override("v_separation",12);body.add_child(grid)
	for item:Dictionary in _support_data():
		var card:=PanelContainer.new();card.size_flags_horizontal=Control.SIZE_EXPAND_FILL;card.add_theme_stylebox_override("panel",_skin(T.PAPER_RAISED,T.RULE,16));grid.add_child(card)
		var column:=VBoxContainer.new();column.add_theme_constant_override("separation",6);card.add_child(column)
		_kicker(column,String(item.label))
		var value:=_label(column,String(item.value));T.text(value,"value",TEXT)
		var note:=_label(column,String(item.note),14,MUTED);note.clip_text=true;note.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;note.tooltip_text=String(item.note);note.mouse_filter=Control.MOUSE_FILTER_PASS
		support_labels[item.id]={"value":value,"note":note}
	_button(body,"Military production ↗",_production)

## The width the boards have to lay out in (the panel less its margins and
## the scroll bar).
func _body_width()->float:
	return maxf(0.0,panel.size.x-72.0)

func _update_support()->void:
	var items:=_support_data()
	if items.size()!=support_labels.size():_build_body();return
	for item:Dictionary in items:
		if not support_labels.has(item.id):_build_body();return
		support_labels[item.id].value.text=String(item.value)
		support_labels[item.id].note.text=String(item.note);support_labels[item.id].note.tooltip_text=String(item.note)

func _management(sub:int)->void:
	_show_page("support" if sub==3 else "recruitment")

func _show_page(value:String)->void:
	page=value;training_view=page=="training";selected_row={};editor_id=-1
	scroll.scroll_vertical=0;_build_body()

func _map_command()->void:
	MilitaryCampaign.joint_operations.open_hierarchy(service)
	_follow_command()

## While the army command panel is open this screen steps aside, and comes
## back when it closes.
func _follow_command()->void:
	var command=MilitaryCampaign.joint_operations.screen
	if not is_instance_valid(command):return
	panel.hide()
	command.tree_exited.connect(func():
		if not is_queued_for_deletion():panel.show();_build_body())

## A row's Orders opened: the army command panel (this screen steps aside) or
## a held town's own view (this screen closes).
func _command_opened(kind:String)->void:
	if kind=="garrison":queue_free();return
	_follow_command()

func _input(event:InputEvent)->void:
	if not panel.visible:return
	if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:
		get_viewport().set_input_as_handled();queue_free()
	# The War screen keeps the map as the screen: a click on the map finds
	# what is there and never closes it (Escape or × does).
	elif war_mode():return
	elif event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT and not panel.get_global_rect().has_point(event.position):
		get_viewport().set_input_as_handled();queue_free()

func _process(delta:float)->void:
	if not panel.visible:return
	_layout();timer+=delta
	if timer<.5:return
	timer=0;stories.clear()
	# The embedded recruitment, forces and readiness boards own live updates.
	if service=="army" or page in ["recruitment","wars","leaders"]:return
	if page=="support":_update_support();return
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
	if is_instance_valid(forces_board) and not bool(forces_board.strip_only):army_filter=String(forces_board.filter)
	for child in body.get_children():body.remove_child(child);child.queue_free()
	bindings.clear();policy_buttons.clear();policy_cards.clear();service_indicators.clear();hero_values.clear();summary_costs.clear();inspection_labels.clear();support_labels={};policy_grid=null;notice_label=null
	forces_board=null;readiness_board=null

func _build_body()->void:
	var saved_scroll:=scroll.scroll_vertical
	_clear();stories.clear()
	_skin_panel()
	var who:=EraWords.word("rail.military","Military")
	# One title: the people's word for their fighters; the service only when there is a choice.
	heading.text=("War" if service=="army" else who+" · "+_service_name(service)) if service_buttons.size()>=2 or service=="army" else who
	management_button.text={"army":"Recruit & deploy","navy":"Fleet preparation","air":"Air preparation"}[service]
	for domain in service_buttons:
		service_buttons[domain].set_pressed_no_signal(domain==service)
	if training_view:page="training"
	for key:String in page_buttons:page_buttons[key].set_pressed_no_signal(page==key)
	# The army is grand strategy on one page: how many serve, our enemies and
	# what to do about each, and our leaders (hud/war_board.gd). No tabs. Every
	# way in opens it (MilitaryCampaign.open_roster); the older army pages
	# below are reached by nothing in the game.
	var war:=service=="army" and page=="war"
	if is_instance_valid(nav_row):nav_row.visible=not war
	# Boats and wings keep their own pages; the leaders and the wars are the
	# War screen's.
	for key in ["leaders","wars"]:
		if page_buttons.has(key):page_buttons[key].visible=service=="army"
	if war:
		_war();return
	if service!="army" and page in ["leaders","wars"]:page="forces"
	if page=="recruitment":_recruitment();return
	if page=="support":_support();return
	if page=="wars":_wars();return
	if page=="leaders":_leaders();return
	if service=="army":
		# HOI4's army overview; over the Training page only its strip of totals.
		_forces(training_view)
		if training_view:_policy()
		scroll.set_deferred("scroll_vertical",saved_scroll);return
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
		T.text(_label(content,{"navy":"No boats are in service yet","air":"No aircraft are in service yet"}[service]),"voice",TEXT)
		_wrapped(content,{"navy":"Build a base and commission craft through service command.","air":"Build a field and commission aircraft through service command."}[service])
		_button(content,"Service command",_map_command,true)
	elif visible.is_empty():_wrapped(body,"No forces match this filter.")
	for data:Dictionary in visible:
		_unit_card(data)
		if data.id==selected_row.get("id",""):selected_row=data;_inspection()
	scroll.set_deferred("scroll_vertical",saved_scroll)

## The army's Forces page, HOI4's army overview (hud/forces_board.gd); over
## the Training page only its strip of totals.
func _forces(strip_only:bool=false)->void:
	forces_board=ForcesBoard.new();body.add_child(forces_board)
	forces_board.setup({"width":_body_width(),"strip_only":strip_only,"filter":army_filter})
	forces_board.page_wanted.connect(_show_page)
	forces_board.close_wanted.connect(queue_free)
	forces_board.command_opened.connect(_command_opened)

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

## One next step per boat or air force, always through an existing flow.
func _act(binding:Dictionary)->void:
	var data:Dictionary=binding.get("row",{});var story:Dictionary=binding.get("story",{})
	match String(story.get("action",{}).get("id","")):
		"production":_production()
		"recruitment":_show_page("recruitment")
		"training":training_view=true;page="training";_build_body()
		"map":_map_command()
		_:_talk_to_captain(data)

func _talk_to_captain(data:Dictionary)->void:
	var captain:Dictionary=Story.captain_for(data,MilitaryCampaign)
	var director:Node=preload("res://scripts/audience_director.gd").court_node()
	if director==null:
		notice="The court cannot be opened just now.";_build_body();return
	if not captain.is_empty() and director.has_method("summon"):director.call("summon",captain.target)
	else:director.call("open_court",{})
	queue_free()

## The service cards' rows: boats and air craft. The army reads its forces
## from the army bar's cards (hud/forces_model.gd).
func _rows()->Array[Dictionary]:
	return _raw_rows()

func _raw_rows()->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	if service=="army":return result
	var campaign=MilitaryCampaign
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
	## How hard to drill, as HOI4 shows a policy: four cards, each two bars
	## (how many drill at a time, the skill they aim for) and its cost; the
	## explanations are in the tooltips.
	var Icons:=preload("res://scripts/resource_icons.gd")
	policy_grid=GridContainer.new();policy_grid.columns=4 if panel.size.x>=920 else 2
	policy_grid.add_theme_constant_override("h_separation",10);policy_grid.add_theme_constant_override("v_separation",10);body.add_child(policy_grid)
	for id:String in MilitaryCampaign.training_staff.POLICIES:
		var definition:Dictionary=MilitaryCampaign.training_staff.POLICIES[id]
		var outer:=PanelContainer.new();outer.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		outer.add_theme_stylebox_override("panel",_skin(T.PAPER_RAISED,T.RULE,10));policy_grid.add_child(outer);policy_cards[id]=outer
		outer.tooltip_text=String(definition.description)
		var card:=VBoxContainer.new();card.add_theme_constant_override("separation",6);outer.add_child(card)
		var choice:=id
		var button:=_button(card,String(definition.label),func():MilitaryCampaign.training_staff.set_policy(service,choice);_update_policy())
		button.toggle_mode=true;button.custom_minimum_size.y=36;policy_buttons[id]=button;button.tooltip_text=String(definition.description)
		for meter:Array in [["drilling",float(definition.share),"%d%% drill at a time" % roundi(float(definition.share)*100)],["drill",float(definition.target),"Aim for %d%% skill" % roundi(float(definition.target)*100)]]:
			var line:=HBoxContainer.new();line.add_theme_constant_override("separation",6);line.tooltip_text=String(meter[2]);line.mouse_filter=Control.MOUSE_FILTER_PASS;card.add_child(line)
			var mark:=TextureRect.new();mark.texture=Icons.command_texture(String(meter[0]),T.INK_MUTED,32);mark.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;mark.custom_minimum_size=Vector2(16,16);mark.size_flags_vertical=Control.SIZE_SHRINK_CENTER;mark.mouse_filter=Control.MOUSE_FILTER_IGNORE;line.add_child(mark)
			var bar:ProgressBar=_bar(line,accent(),"segments");bar.marks=10;bar.value=float(meter[1])*100;bar.custom_minimum_size=Vector2(70,18);bar.mouse_filter=Control.MOUSE_FILTER_IGNORE
			var value:=_label(line,"%d%%" % roundi(float(meter[1])*100),14,TEXT);value.add_theme_font_override("font",T.font("ui_strong"));value.mouse_filter=Control.MOUSE_FILTER_IGNORE
		var effort:=_kicker(card,{"suspended":"Saves stores","maintain":"Light cost","regular":"Steady cost","intensive":"Heavy cost"}[id])
		effort.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	if service!="army":
		var overview:=GridContainer.new();overview.columns=4;overview.add_theme_constant_override("h_separation",10);body.add_child(overview)
		for definition:Array in [["training","In training",T.GREEN],["assigned","On missions",T.BLUE],["target","Drilled enough",T.GOLD],["paused","Paused",T.RED]]:
			var card:=VBoxContainer.new();card.size_flags_horizontal=Control.SIZE_EXPAND_FILL;overview.add_child(card)
			var value:=_label(card,"0",24,T.text_for(definition[2]));_kicker(card,String(definition[1]))
			var bar:=_bar(card,definition[2]);service_indicators[definition[0]]={"value":value,"bar":bar,"card":card}
	policy_status=_label(body,"",14,TEXT);policy_status.clip_text=true;policy_status.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	policy_status.mouse_filter=Control.MOUSE_FILTER_PASS
	var investment:=HFlowContainer.new();investment.add_theme_constant_override("h_separation",24);body.add_child(investment)
	for definition:Array in [["food","supply","extra food eaten","Food eaten by drill beyond ordinary rations. Staff always keep seven days of food for everyone else."],["materials","gear","materials used","Materials worn out in drill."],["time","date","first drill","First drill counts only days with food and gear to practise with; shortages pause it. Longer exercises take 72 to 252 such days."]]:
		var chip:=HBoxContainer.new();chip.add_theme_constant_override("separation",8);chip.tooltip_text=String(definition[3]);chip.mouse_filter=Control.MOUSE_FILTER_PASS;investment.add_child(chip)
		var icon:=TextureRect.new();icon.texture=Icons.command_texture(String(definition[1]),T.INK,48);icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.custom_minimum_size=Vector2(22,22);icon.size_flags_vertical=Control.SIZE_SHRINK_CENTER;icon.mouse_filter=Control.MOUSE_FILTER_IGNORE;chip.add_child(icon)
		summary_costs[definition[0]]=_label(chip,"",20);summary_costs[definition[0]].add_theme_font_override("font",T.font("ui_strong"));summary_costs[definition[0]].mouse_filter=Control.MOUSE_FILTER_IGNORE
		var word:=_label(chip,String(definition[2]),13,MUTED);word.size_flags_vertical=Control.SIZE_SHRINK_CENTER;word.mouse_filter=Control.MOUSE_FILTER_IGNORE
	_update_policy()
func _update_policy()->void:
	var state:Dictionary=MilitaryCampaign.training_staff.snapshot(service)
	if service!="army":_update_hero(_rows())
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
	policy_status.text=String(state.status).get_slice("\n",0)
	if service=="army" and not state.active.is_empty():policy_status.text="%s · %.0f of %.0f days" % [state.active.label,state.active.progress_days,state.active.duration_days]
	policy_status.tooltip_text=String(state.status)
	# Whole measures, grouped: a running tally, not a reading to the tenth.
	summary_costs.food.text=EraWords.grouped(roundi(float(state.food_spent))) if float(state.food_spent)>=0.5 else "none"
	summary_costs.materials.text=EraWords.grouped(roundi(float(state.materials_spent))) if float(state.materials_spent)>=0.5 else "none"
	summary_costs.time.text="45+ days" if service=="army" else "90+ days"
