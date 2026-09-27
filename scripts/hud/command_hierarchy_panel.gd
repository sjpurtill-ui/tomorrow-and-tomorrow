extends CanvasLayer
## One service at a time, over the same terrain and camera as the game.
##
## Army: pick who goes, pick what they do in a plain verb, pick where by
## clicking the map (a town, one of their hosts, or open ground) or from a
## short list, read what it costs, and give the order once. The order goes
## through the court's war core (scripts/army_orders.gd -> court_war_orders),
## so the war leader objects, refuses or obeys exactly as in court.
## Drawn battle zones, small detachments and the commander's brief stay in
## their own tab for the orders that really need a drawn area.
## Navy and air: their zones are drawn (that is how those services work).
const Overlay=preload("res://scripts/hud/service_world_overlay.gd")
const CommandTree=preload("res://scripts/hud/command_tree.gd")
const OrderBrief=preload("res://scripts/hud/command_order_brief.gd")
const Preparation=preload("res://scripts/hud/command_preparation.gd")
const Orders=preload("res://scripts/army_orders.gd")
const T=preload("res://scripts/hud/hud_tokens.gd")
const PICK_RADIUS_PX:=26.0
var domain:="army"
var terrain:Node
var command:RefCounted
var map:Control
var panel:PanelContainer
var tabs:TabContainer
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
var preparation_box:VBoxContainer
var preparation_meters:Dictionary={}
var preparation_values:Dictionary={}
var preparation_fuel:Label
var preparation_note:Label
var zone_tab:Control
# --- the plain army flow ---
var force_id:=-1
var verb_id:=""
var target:Dictionary={}
var flow_scroll:ScrollContainer
var force_box:VBoxContainer
var force_cards:Dictionary={}
var force_signature:=""
var verb_buttons:Dictionary={}
var where_title:Label
var where_note:Label
var place_box:VBoxContainer
var place_signature:=""
var plan_box:VBoxContainer
var plan_title:Label
var answer_box:PanelContainer
var answer_label:Label
var answer_outcome:Label
var insist_button:Button
var give_button:Button
var talk_button:Button
var last_answer:Dictionary={}
var ink:Control

func _ready()->void:
	layer=82;command=MilitaryCampaign.command_hierarchy
	if domain=="army":command.land.refresh_claims()
	map=Overlay.new();map.domain=domain;map.terrain=terrain;add_child(map)
	map.region_selected.connect(_region);map.boundary_feedback.connect(_report)
	map.order_region.connect(func(region:Dictionary):_region(region);_assign())
	map.force_selected.connect(_select_force)
	if domain=="army":
		ink=TargetInk.new();ink.owner_panel=self;add_child(ink)
	panel=PanelContainer.new();add_child(panel);panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	panel.offset_top=16;panel.offset_right=-16;panel.offset_left=-536
	var skin:=T.flat(T.DOCK_BG,T.BORDER,1,8,14);panel.add_theme_stylebox_override("panel",skin);panel.add_theme_font_size_override("font_size",15)
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",8);panel.add_child(column)
	var heading:=_row(column)
	var heading_copy:=VBoxContainer.new();heading_copy.size_flags_horizontal=Control.SIZE_EXPAND_FILL;heading_copy.add_theme_constant_override("separation",2);heading.add_child(heading_copy)
	var title:=_label(heading_copy,"Army command" if domain=="army" else "Fleet command" if domain=="navy" else "Air force command",24)
	title.autowrap_mode=TextServer.AUTOWRAP_OFF;title.clip_text=true;title.tooltip_text=title.text
	var subtitle:=_label(heading_copy,_subtitle(),14);subtitle.add_theme_color_override("font_color",T.TEXT_DIM);subtitle.autowrap_mode=TextServer.AUTOWRAP_OFF;subtitle.clip_text=true;subtitle.tooltip_text=subtitle.text
	var close:=_button(heading,"×",queue_free);close.custom_minimum_size=Vector2(42,42);close.size_flags_horizontal=Control.SIZE_SHRINK_END;close.size_flags_vertical=Control.SIZE_SHRINK_BEGIN;close.tooltip_text="Close"
	tabs=TabContainer.new();tabs.size_flags_vertical=Control.SIZE_EXPAND_FILL;column.add_child(tabs)
	if domain=="army":
		var plain:=VBoxContainer.new();plain.name="Orders";plain.add_theme_constant_override("separation",8);tabs.add_child(plain)
		_build_plain_orders(plain)
		var zones:=VBoxContainer.new();zones.name="Drawn zones";zones.add_theme_constant_override("separation",8);tabs.add_child(zones)
		var why:=_label(zones,"Only for orders that need a drawn area. Most orders don't.",14);why.add_theme_color_override("font_color",T.TEXT_DIM);why.autowrap_mode=TextServer.AUTOWRAP_OFF;why.clip_text=true
		why.tooltip_text="Hold a stretch of border, encircle a host, send a small part of a band, or give a band a written brief."
		_build_zone_orders(zones)
		zone_tab=zones
	else:
		var orders:=VBoxContainer.new();orders.name="Orders";orders.add_theme_constant_override("separation",8);tabs.add_child(orders)
		_build_zone_orders(orders)
		zone_tab=orders
	feedback=_label(column,"");feedback.max_lines_visible=2;feedback.hide()
	_build_organization()
	_install_command_theme()
	_refresh_targets()
	if domain=="army":_refresh_flow(true)

func _subtitle()->String:
	if domain!="army":return "Draw where they work and choose their task. The %s decide how." % ("captains" if domain=="navy" else "wing leaders")
	var leader:=Orders.war_leader_name()
	return "Choose who goes, what they do and where. %s handles the rest." % (leader if leader!="" else "The war leader")

# --------------------------------------------------------------------------
# The plain flow (army)
# --------------------------------------------------------------------------

func _build_plain_orders(parent:VBoxContainer)->void:
	flow_scroll=ScrollContainer.new();flow_scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;flow_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;parent.add_child(flow_scroll)
	var flow:=VBoxContainer.new();flow.size_flags_horizontal=Control.SIZE_EXPAND_FILL;flow.add_theme_constant_override("separation",8);flow_scroll.add_child(flow)
	_section(flow,"Who goes")
	force_box=VBoxContainer.new();force_box.add_theme_constant_override("separation",6);flow.add_child(force_box)
	_section(flow,"What to do")
	var grid:=GridContainer.new();grid.columns=3;grid.add_theme_constant_override("h_separation",6);grid.add_theme_constant_override("v_separation",6);flow.add_child(grid)
	for entry:Dictionary in Orders.VERBS:
		var id:=String(entry.id)
		var button:=_button(grid,String(entry.label),func():choose_verb(id))
		button.toggle_mode=true;button.tooltip_text=String(entry.hint);button.custom_minimum_size=Vector2(0,40)
		verb_buttons[id]=button
	where_title=_section(flow,"Where")
	where_note=_label(flow,"",15)
	place_box=VBoxContainer.new();place_box.add_theme_constant_override("separation",6);flow.add_child(place_box)
	plan_title=_section(flow,"What happens")
	plan_box=VBoxContainer.new();plan_box.add_theme_constant_override("separation",4);flow.add_child(plan_box)
	answer_box=PanelContainer.new();answer_box.add_theme_stylebox_override("panel",T.flat(T.PAPER_RAISED,T.GOLD,1,4,12));flow.add_child(answer_box);answer_box.hide()
	var answer_column:=VBoxContainer.new();answer_column.add_theme_constant_override("separation",8);answer_box.add_child(answer_column)
	answer_label=_label(answer_column,"",16)
	answer_outcome=_label(answer_column,"",14);answer_outcome.add_theme_color_override("font_color",T.BODY_2)
	var answer_row:=_row(answer_column)
	insist_button=_button(answer_row,"Insist",func():_give(true));insist_button.hide()
	insist_button.tooltip_text="Give the order again. They will go, whatever they think of it."
	# The one action stays below the scrolling choices.
	var action:=_row(parent)
	give_button=_button(action,"Give the order",func():_give(false))
	give_button.add_theme_stylebox_override("normal",T.gold_outline_style());give_button.add_theme_color_override("font_color",T.GOLD_BRIGHT);give_button.custom_minimum_size.y=44
	talk_button=_button(action,"Talk it over",_talk);talk_button.custom_minimum_size.y=44
	talk_button.tooltip_text="Open the court and speak with the war leader about it."

func _section(parent:Node,text:String)->Label:
	var label:=_label(parent,text,15)
	label.add_theme_font_override("font",T.font("ui_strong"));label.add_theme_color_override("font_color",T.INK)
	label.autowrap_mode=TextServer.AUTOWRAP_OFF
	return label

func _card(parent:Node,title:String,detail:String,callback:Callable)->Button:
	## A choice with a title and a plain second line.
	var card:=_button(parent,"",callback);card.toggle_mode=true;card.custom_minimum_size=Vector2(0,56 if detail!="" else 40)
	card.tooltip_text=(title+"\n"+detail).strip_edges()
	var box:=VBoxContainer.new();box.mouse_filter=Control.MOUSE_FILTER_IGNORE;box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);box.offset_left=12;box.offset_right=-12;box.offset_top=6;box.offset_bottom=-6
	box.add_theme_constant_override("separation",1);box.alignment=BoxContainer.ALIGNMENT_CENTER;card.add_child(box)
	var head:=_label(box,title,16);head.autowrap_mode=TextServer.AUTOWRAP_OFF;head.clip_text=true;head.mouse_filter=Control.MOUSE_FILTER_IGNORE;head.name="Title"
	if detail!="":
		var line:=_label(box,detail,14);line.autowrap_mode=TextServer.AUTOWRAP_OFF;line.clip_text=true;line.mouse_filter=Control.MOUSE_FILTER_IGNORE;line.add_theme_color_override("font_color",T.BODY_2);line.name="Detail"
	return card

func choose_force(id:int)->void:
	if force_id!=id:last_answer={}
	force_id=id
	if id>0:map.selected_force=id
	_refresh_flow()

func choose_verb(id:String)->void:
	if verb_id!=id:last_answer={}
	# A town chosen for Attack stays chosen for Besiege or Raid.
	var kind:=Orders.needs(id)
	if kind!=Orders.needs(verb_id) or (kind=="place" and String(target.get("type",""))=="host" and id!="attack"):target={}
	verb_id=id
	_refresh_flow()

func choose_place(city_id:String)->void:
	var p:=Orders.place(city_id)
	if p.is_empty():return
	last_answer={}
	if Orders.needs(verb_id)!="place":verb_id="attack"
	target={"type":"place","place":p}
	_refresh_flow()

func choose_host(host:Dictionary)->void:
	last_answer={}
	verb_id="attack"
	target={"type":"host","formation_id":String(host.formation_id),"civ_id":String(host.civ_id),"label":String(host.label),"position":host.position}
	_refresh_flow()

func choose_spot(x:float,z:float)->void:
	last_answer={}
	if Orders.needs(verb_id)!="spot":verb_id="goto"
	target={"type":"spot","x":x,"z":z}
	_refresh_flow()

func _default_force()->int:
	var cards:=Orders.forces()
	if cards.is_empty():return Orders.HOME
	# The biggest band ready at home, else the levy at home.
	var best:=int(cards[0].id);var most:=int(cards[0].troops)
	for card:Dictionary in cards:
		if int(card.id)!=Orders.HOME and bool(card.at_home) and int(card.troops)>=most:best=int(card.id);most=int(card.troops)
	return best

func _refresh_flow(first:=false)->void:
	if domain!="army" or not is_instance_valid(force_box):return
	var cards:=Orders.forces()
	var ids:Array=[]
	for card:Dictionary in cards:ids.append(int(card.id))
	if first or not force_id in ids:force_id=_default_force()
	var signature:=str(cards)
	if signature!=force_signature:
		force_signature=signature
		for child in force_box.get_children():child.queue_free()
		force_cards.clear()
		for card:Dictionary in cards:
			var id:=int(card.id)
			force_cards[id]=_card(force_box,String(card.title),String(card.detail),func():choose_force(id))
		if cards.size()==1 and int(cards[0].troops)<=0:
			var raise:=_button(force_box,"Raise and drill a levy",func():queue_free();MilitaryCampaign.open_roster("army"))
			raise.tooltip_text="Open Forces & training."
	for id in force_cards:(force_cards[id] as Button).set_pressed_no_signal(int(id)==force_id)
	for id:String in verb_buttons:
		var button:Button=verb_buttons[id]
		var reason:=Orders.unavailable(force_id,id)
		button.disabled=reason!=""
		button.tooltip_text=reason if reason!="" else String(Orders.verb(id).hint)
		button.set_pressed_no_signal(id==verb_id)
	if verb_id!="" and Orders.unavailable(force_id,verb_id)!="":
		verb_id=""
		for id:String in verb_buttons:(verb_buttons[id] as Button).set_pressed_no_signal(false)
	_refresh_where()
	_refresh_plan()

func _refresh_where()->void:
	var kind:=Orders.needs(verb_id)
	where_title.visible=kind!=""
	where_note.visible=true
	place_box.visible=kind=="place"
	match kind:
		"place":
			where_note.text="Click a town or one of their hosts on the map, or pick one here." if target.is_empty() else "Chosen: %s. Click another on the map to change it." % Orders.target_title(target)
		"spot":
			where_note.text="Click the ground on the map where they should go." if target.is_empty() else "Chosen: %s. Click the map to move it." % Orders.target_title(target)
		_:
			where_note.text=""
			where_note.visible=false
	if kind!="place":return
	var towns:=Orders.places().slice(0,6)
	var seen:=Orders.hosts().slice(0,3)
	var signature:=str([towns,seen,target])
	if signature==place_signature:return
	place_signature=signature
	for child in place_box.get_children():child.queue_free()
	for p:Dictionary in towns:
		var at:=Orders._v2(p.position)
		var city_id:=String(p.city_id)
		var card:=_card(place_box,Orders.place_name(p),"%s · %s" % [String(p.civ_name),Orders.distance_words(at)],func():choose_place(city_id))
		card.custom_minimum_size.y=50
		card.set_pressed_no_signal(String(target.get("type",""))=="place" and String((target.get("place",{}) as Dictionary).get("city_id",""))==city_id)
	for host:Dictionary in seen:
		var chosen:=host
		var card:=_card(place_box,String(host.label),"Seen now · %s" % Orders.distance_words(Orders._v2(host.position)),func():choose_host(chosen))
		card.custom_minimum_size.y=50
		card.set_pressed_no_signal(String(target.get("formation_id",""))==String(host.formation_id))
	if towns.is_empty() and seen.is_empty():
		_label(place_box,"No town of theirs is on our charts yet. Send scouts first.",15)

func _refresh_plan()->void:
	for child in plan_box.get_children():child.queue_free()
	var plan:Dictionary=Orders.preview(force_id,verb_id,target) if verb_id!="" else {"lines":["Choose what they should do."],"ready":false,"likely":""}
	if verb_id=="" and not last_answer.is_empty():plan.lines=[]
	plan_title.visible=not (plan.lines as Array).is_empty()
	for line in plan.lines:
		var label:=_label(plan_box,String(line),15)
		if String(plan.likely)=="impossible":label.add_theme_color_override("font_color",T.RED)
	give_button.disabled=not bool(plan.ready) or String(plan.likely)=="impossible"
	give_button.tooltip_text="Choose who goes, what they do and where first." if not bool(plan.ready) else ("This cannot be done now." if String(plan.likely)=="impossible" else "The war leader hears the order and answers.")
	var leader:=Orders.war_leader_name()
	talk_button.text="Talk it over with %s" % leader if leader!="" else "Talk it over at court"
	if is_instance_valid(ink):ink.road=plan.get("road",[]);ink.queue_redraw()
	_show_answer()

func _show_answer()->void:
	answer_box.visible=not last_answer.is_empty()
	insist_button.visible=String(last_answer.get("verdict",""))=="object"
	if last_answer.is_empty():return
	var who:=String(last_answer.get("general","The war leader"))
	var says:=String(last_answer.get("says","")).strip_edges()
	var fix:=String(last_answer.get("fix","")).strip_edges()
	match String(last_answer.verdict):
		"act":answer_label.text="%s: “%s”" % [who,says]
		"object":answer_label.text="%s objects: “%s”%s" % [who,says,("\n"+fix) if fix!="" else ""]
		_:answer_label.text="%s: “%s”%s" % [who,says,("\n"+fix) if fix!="" else ""]
	var outcome:=String(last_answer.get("outcome","")).strip_edges()
	answer_outcome.text=outcome if String(last_answer.verdict)=="act" and outcome!=says else ""
	answer_outcome.visible=answer_outcome.text!=""
	var tone:Color=T.GREEN if String(last_answer.verdict)=="act" else (T.AMBER if String(last_answer.verdict)=="object" else T.RED)
	answer_box.add_theme_stylebox_override("panel",T.flat(T.PAPER_RAISED,tone,1,4,12))

func _give(insist:bool)->void:
	var result:=Orders.give(force_id,verb_id,target,insist)
	last_answer=result
	# The answer card carries the reply; the line under the panel stays quiet.
	feedback.text="";feedback.hide()
	if String(result.verdict)=="act":
		var army_id:=int((result.get("objective",{}) as Dictionary).get("army_id",0))
		verb_id="";target={}
		force_signature=""
		if army_id>0:force_id=army_id
	_refresh_flow()
	if is_instance_valid(tree):tree.refresh()

func _talk()->void:
	var leader:=Orders.WO.war_leader()
	var director:=preload("res://scripts/audience_director.gd").court_node()
	var opened:=false
	if director!=null and not leader.is_empty():
		var who:Dictionary={"person_id":int(leader.person_id)} if int(leader.get("person_id",0))>0 else {"figure_id":String(leader.get("figure_id",""))}
		opened=director.call("summon",who)!=null
	if not opened:preload("res://scripts/audience_director.gd").open_court_for({})
	queue_free()

func _pick_from_map(at:Vector2)->bool:
	## A click on the map: one of our marks picks who goes; a town or their
	## host picks where; open ground is the place for Guard or Go to.
	var mark:Dictionary={}
	if is_instance_valid(terrain) and terrain.has_method("_war_mark_at"):mark=terrain.call("_war_mark_at",at)
	if String(mark.get("kind",""))=="army" and not Orders.army(int(mark.get("army_id",0))).is_empty():
		choose_force(int(mark.army_id));return true
	for actual:Dictionary in MilitaryCampaign.field_armies:
		var shown:Dictionary=map.army_report(actual)
		if not shown.get("position",{}).is_empty() and map.world_to_screen(Orders._v2(shown.position)).distance_to(at)<18:
			choose_force(int(actual.army_id));return true
	var needs:=Orders.needs(verb_id)
	if String(mark.get("kind",""))=="sighting" and needs!="spot":
		var enemy_id:=String(mark.get("enemy_id",""))
		for host:Dictionary in Orders.hosts():
			if String(host.formation_id)==enemy_id:choose_host(host);return true
	if needs!="spot":
		var best:={};var best_d:=PICK_RADIUS_PX
		for p:Dictionary in Orders.places():
			var screen:Vector2=map.world_to_screen(Orders._v2(p.position))
			var d:=screen.distance_to(at)
			if screen.is_finite() and d<best_d:best_d=d;best=p
		if not best.is_empty():choose_place(String(best.city_id));return true
		for host:Dictionary in Orders.hosts():
			var screen:Vector2=map.world_to_screen(Orders._v2(host.position))
			if screen.is_finite() and screen.distance_to(at)<PICK_RADIUS_PX:choose_host(host);return true
	if needs=="spot" or verb_id=="":
		# Open ground with nothing chosen yet means "go there".
		var hit:Dictionary=map.screen_to_world(at)
		if hit.is_empty() and verb_id=="":return false
		if hit.is_empty():_report({"error":"That is off the chart. Click charted ground."});return true
		choose_spot(float(hit.x),float(hit.z));return true
	if needs=="place":
		_report({"error":"That is not a town of theirs we know. Click a town's name or a host of theirs, or pick one from the list."});return true
	return false

class TargetInk extends Control:
	## The chosen place and the road there, inked on the map under the panel.
	var owner_panel:CanvasLayer
	var road:Array=[]
	func _ready()->void:
		mouse_filter=Control.MOUSE_FILTER_IGNORE;set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	func _process(_delta:float)->void:
		if not road.is_empty() or not (owner_panel.target as Dictionary).is_empty():queue_redraw()
	func _draw()->void:
		if owner_panel==null or not is_instance_valid(owner_panel.map):return
		var map:Control=owner_panel.map
		var halo:=Color(T.PAPER,0.85);var gold:=T.GOLD
		var points:=PackedVector2Array()
		for p in road:
			var at:Vector2=map.world_to_screen(p as Vector2) if p is Vector2 else map.world_to_screen(Orders._v2(p))
			if at.is_finite():points.append(at)
		if points.size()>=2:
			draw_polyline(points,halo,5.0,true)
			for i in points.size()-1:draw_dashed_line(points[i],points[i+1],gold,2.2,9.0,true,true)
		var chosen:Dictionary=owner_panel.target
		if chosen.is_empty():return
		var where:=Vector2.INF
		match String(chosen.get("type","")):
			"place":where=Orders._v2((chosen.place as Dictionary).position)
			"host":where=Orders._v2(chosen.position)
			"spot":where=Vector2(float(chosen.x),float(chosen.z))
		if not where.is_finite():return
		var at:Vector2=map.world_to_screen(where)
		if not at.is_finite():return
		draw_arc(at,17.0,0,TAU,40,halo,6.0,true)
		draw_arc(at,17.0,0,TAU,40,gold,2.4,true)
		draw_arc(at,6.0,0,TAU,20,gold,2.0,true)

# --------------------------------------------------------------------------
# Drawn zones (army: its own tab; navy and air: their orders)
# --------------------------------------------------------------------------

func _build_zone_orders(orders:VBoxContainer)->void:
	var noun:="band" if domain=="army" else "fleet" if domain=="navy" else "wing"
	_heading(orders,"Choose a %s" % noun,"Pick a whole force, or open it to pick a smaller part.")
	tree=CommandTree.new();tree.service=domain;orders.add_child(tree);tree.custom_minimum_size.y=180;tree.size_flags_vertical=Control.SIZE_SHRINK_BEGIN;tree.command_selected.connect(_selected)
	var scroll:=ScrollContainer.new();orders_scroll=scroll;scroll.custom_minimum_size.y=100;scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;orders.add_child(scroll)
	var controls:=VBoxContainer.new();controls.size_flags_horizontal=Control.SIZE_EXPAND_FILL;controls.add_theme_constant_override("separation",7);scroll.add_child(controls)
	_heading(controls,"Choose its task","Nothing changes until you give the order below.")
	var selection_card:=_zone_card(controls)
	selected_label=_label(selection_card,"No command selected",17)
	selected_label.autowrap_mode=TextServer.AUTOWRAP_OFF;selected_label.clip_text=true
	var current_row:=_row(selection_card)
	current_order_label=_label(current_row,"Now: No command selected",14)
	current_order_label.autowrap_mode=TextServer.AUTOWRAP_OFF;current_order_label.clip_text=true
	edit_order_button=_button(current_row,"Change it",_edit_current_order);edit_order_button.custom_minimum_size=Vector2(96,30);edit_order_button.size_flags_horizontal=Control.SIZE_SHRINK_END;edit_order_button.disabled=true
	mission=OptionButton.new();mission.clip_text=true;controls.add_child(mission)
	mission.tooltip_text="Choosing a task does not give the order. Use Give the order, or right-click an area on the map."
	mission.custom_minimum_size.y=42;mission.add_theme_stylebox_override("normal",T.gold_outline_style())
	var catalog:Dictionary=command.LAND_MISSIONS if domain=="army" else MilitaryCampaign.joint_operations.MISSIONS[domain]
	for id:String in catalog:
		if id=="transport":continue
		mission.add_item("Task: "+String(catalog[id]));mission.set_item_metadata(mission.item_count-1,id)
	mission.item_selected.connect(func(_index:int):_refresh_targets())
	mission_hint=_label(controls,"");mission_hint.max_lines_visible=2;mission_hint.add_theme_color_override("font_color",T.RED);mission_hint.hide()
	cities=OptionButton.new();cities.clip_text=true;controls.add_child(cities)
	_heading(controls,"Draw its area","Click corners on the map; right-click or Enter closes the shape.")
	var zone_card:=_zone_card(controls)
	region_label=_label(zone_card,"No area chosen",15)
	region_label.max_lines_visible=1
	_build_preparation(controls)
	var drawing:=_row(controls);_button(drawing,"Draw an area",_draw_zone).tooltip_text="Shortcut: D"
	finish_button=_button(drawing,"Finish",func():map.finish_boundary(area_name.text))
	cancel_boundary_button=_button(drawing,"Cancel drawing",func():map.cancel_boundary())
	finish_button.hide();cancel_boundary_button.hide()
	details_toggle=_button(controls,"Add a name or a brief ▸",func():details.visible=not details.visible;details_toggle.text="Hide name and brief ▾" if details.visible else "Add a name or a brief ▸")
	details=VBoxContainer.new();details.add_theme_constant_override("separation",6);controls.add_child(details);details.hide()
	area_name=LineEdit.new();area_name.placeholder_text="Name for the area (optional)";details.add_child(area_name)
	vision=LineEdit.new();vision.placeholder_text="A brief for the commander (optional)";vision.tooltip_text="A note the commander keeps with this order. It does not change what they can do.";details.add_child(vision)
	status=_label(controls,"");status.max_lines_visible=2;status.hide()
	# The action stays outside the scrolling details, at every scroll position.
	var action:=_row(orders);apply_button=_button(action,"Give the order",_assign);apply_button.add_theme_stylebox_override("normal",T.gold_outline_style());apply_button.add_theme_color_override("font_color",T.GOLD_BRIGHT)
	var cancel_orders:=_button(action,"Cancel orders",_cancel_orders)
	cancel_orders.tooltip_text="Cancel only the chosen command's orders. Others keep theirs."

func show_zone_orders()->void:
	if is_instance_valid(tabs) and is_instance_valid(zone_tab):tabs.current_tab=zone_tab.get_index()

func _build_organization()->void:
	var organization:=VBoxContainer.new();organization.name="Organization";organization.add_theme_constant_override("separation",10);tabs.add_child(organization)
	_label(organization,"Put commands under one leader",19)
	_label(organization,"In the list on the %s tab, hold Ctrl and click to choose several commands. Then choose the size of the new command here. Orders to it go to everyone under it." % ("Drawn zones" if domain=="army" else "Orders"),15)
	group_level=OptionButton.new();organization.add_child(group_level)
	for index in command.LEVELS[domain].size():group_level.add_item(String(command.LEVELS[domain][index][0]));group_level.set_item_metadata(index,index)
	group_level.select(command.LEVELS[domain].size()-1)
	group_name=LineEdit.new();group_name.placeholder_text="Name (optional)";organization.add_child(group_name)
	_button(organization,"Put chosen commands together",_group)
	_label(organization,"Opening a force in the list shows its smaller parts. A part only leaves its force when you give it an order; nobody new is raised.",15).add_theme_color_override("font_color",T.TEXT_DIM)
	_button(organization,"Delete the chosen area",func():_report(command.remove_region(String(map.selected.get("id",""))) if domain=="army" else MilitaryCampaign.joint_operations.remove_region(String(map.selected.get("id","")))))
	var links:=_row(organization)
	_button(links,"Forces & training",func():queue_free();MilitaryCampaign.open_roster(domain))
	_button(links,"Army builds" if domain=="army" else "Ports & ships" if domain=="navy" else "Airbases & aircraft",_management)

func _install_command_theme()->void:
	var theme:=Theme.new()
	theme.default_font=T.FONT_UI;theme.default_font_size=15
	for type:String in ["Label","Button","OptionButton","LineEdit","Tree","TabBar","TabContainer","PopupMenu"]:
		for state:String in ["font_color","font_hover_color","font_pressed_color","font_hover_pressed_color","font_focus_color","font_selected_color","font_unselected_color","font_hovered_color"]:theme.set_color(state,type,T.INK)
		theme.set_color("font_disabled_color",type,T.DISABLED)
	# Placeholders and hints are ink too, only quieter; never Godot's pale default.
	theme.set_color("font_placeholder_color","LineEdit",T.MUTED)
	theme.set_color("caret_color","LineEdit",T.INK)
	theme.set_color("selection_color","LineEdit",T.ACTIVE_BG)
	theme.set_color("font_uneditable_color","LineEdit",T.TEXT_DIM)
	theme.set_color("font_separator_color","PopupMenu",T.TEXT_DIM)
	for type:String in ["Button","OptionButton"]:
		theme.set_stylebox("normal",type,T.action_button_style(false))
		theme.set_stylebox("hover",type,T.action_button_style(false,true))
		theme.set_stylebox("pressed",type,T.button_pressed_style())
		theme.set_stylebox("hover_pressed",type,T.button_pressed_style())
		theme.set_stylebox("disabled",type,T.button_disabled_style())
		theme.set_stylebox("focus",type,T.gold_outline_style())
	for state:String in ["normal","read_only"]:theme.set_stylebox(state,"LineEdit",T.flat(T.FIELD_BG,T.BORDER,1,3,8))
	theme.set_stylebox("focus","LineEdit",T.flat(T.FIELD_BG,T.GOLD,1,3,8))
	for type:String in ["TabContainer","TabBar"]:
		theme.set_stylebox("panel",type,T.flat(T.DOCK_BG,Color.TRANSPARENT,0,0,6))
		for state:String in ["tab_selected","tab_unselected","tab_hovered"]:theme.set_stylebox(state,type,T.flat(T.ACTIVE_BG if state=="tab_selected" else T.ROW_BG,T.GOLD if state=="tab_selected" else T.BORDER_SOFT,1,4,10))
	for state:String in ["title_button_normal","title_button_hover","title_button_pressed"]:theme.set_stylebox(state,"Tree",T.flat(T.TILE_BG,T.BORDER_SOFT,1,2,6))
	theme.set_color("title_button_color","Tree",T.INK)
	theme.set_stylebox("panel","PopupMenu",T.flat(T.DOCK_BG,T.BORDER,1,4,8))
	theme.set_stylebox("hover","PopupMenu",T.flat(T.HOVER_BG))
	T.add_tooltip_style(theme)
	panel.theme=theme

func _row(parent:Node)->HBoxContainer:
	var result:=HBoxContainer.new();result.add_theme_constant_override("separation",6);parent.add_child(result);return result

func _heading(parent:Node,title:String,explanation:String)->VBoxContainer:
	var copy:=VBoxContainer.new();copy.size_flags_horizontal=Control.SIZE_EXPAND_FILL;copy.add_theme_constant_override("separation",0);parent.add_child(copy)
	# One line: the title, then the hint in quieter ink beside it.
	var line:=_row(copy)
	var head:=_section(line,title);head.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN;head.tooltip_text=explanation;head.mouse_filter=Control.MOUSE_FILTER_PASS
	var note:=_label(line,explanation,13);note.add_theme_color_override("font_color",T.TEXT_DIM);note.tooltip_text=explanation;note.autowrap_mode=TextServer.AUTOWRAP_OFF;note.clip_text=true;note.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	return copy

func _zone_card(parent:Node)->VBoxContainer:
	var frame:=PanelContainer.new();var style:=T.flat(T.ROW_BG,T.BORDER_SOFT,1,5,10);style.content_margin_top=6;style.content_margin_bottom=6;frame.add_theme_stylebox_override("panel",style);frame.size_flags_horizontal=Control.SIZE_EXPAND_FILL;parent.add_child(frame)
	var content:=VBoxContainer.new();content.add_theme_constant_override("separation",5);frame.add_child(content)
	return content

func _build_preparation(parent:Node)->void:
	preparation_box=VBoxContainer.new();preparation_box.add_theme_constant_override("separation",4);parent.add_child(preparation_box);preparation_box.hide()
	var row:=_row(preparation_box)
	for entry:Array in [["training","Training",T.BLUE],["condition","Condition",T.TEAL],["coverage","Coverage",T.AMBER]]:
		var column:=VBoxContainer.new();column.size_flags_horizontal=Control.SIZE_EXPAND_FILL;column.add_theme_constant_override("separation",3);row.add_child(column)
		var label:=_label(column,String(entry[1]),13);label.autowrap_mode=TextServer.AUTOWRAP_OFF;preparation_values[entry[0]]=label
		var meter:=ProgressBar.new();meter.show_percentage=false;meter.custom_minimum_size.y=6
		var fill:=StyleBoxFlat.new();fill.bg_color=entry[2];fill.set_corner_radius_all(2);meter.add_theme_stylebox_override("fill",fill)
		var background:=StyleBoxFlat.new();background.bg_color=T.TRACK;background.set_corner_radius_all(2);meter.add_theme_stylebox_override("background",background)
		column.add_child(meter);preparation_meters[entry[0]]=meter
	preparation_fuel=_label(preparation_box,"",13)
	preparation_note=_label(preparation_box,"",13);preparation_note.max_lines_visible=2

func _update_preparation()->void:
	if not is_instance_valid(preparation_box):return
	if domain=="army" or selected.is_empty() or _mission()=="hold":preparation_box.hide();return
	var prepared:Dictionary=Preparation.snapshot(command,selected,map.selected)
	preparation_box.visible=bool(prepared.visible)
	if not preparation_box.visible:return
	for key:String in preparation_meters:
		preparation_meters[key].value=clampf(float(prepared[key])*100,0,100)
		preparation_values[key].text="%s %d%%" % [key.capitalize(),roundi(float(prepared[key])*100)]
		preparation_meters[key].tooltip_text=String(prepared.tooltip)
	preparation_fuel.text="Full missions: %d fuel/day · shared reserve %d" % [int(prepared.fuel),int(prepared.reserve)]
	preparation_fuel.add_theme_color_override("font_color",T.RED if int(prepared.shortage)>0 else T.TEXT_DIM)
	preparation_note.text=String(prepared.summary);preparation_note.tooltip_text=String(prepared.tooltip)
	preparation_note.add_theme_color_override("font_color",T.AMBER if prepared.warning else T.GREEN)
	var unavailable:=String(mission_reasons.get(_mission(),""))
	if unavailable!="":
		preparation_note.text="This command cannot perform the selected objective."
		preparation_note.tooltip_text=unavailable+"\n\n"+String(prepared.tooltip);preparation_note.add_theme_color_override("font_color",T.RED)
	preparation_box.tooltip_text=String(prepared.tooltip)
func _label(parent:Node,text:String,size:int=15)->Label:
	var result:=Label.new();result.text=text;result.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;result.size_flags_horizontal=Control.SIZE_EXPAND_FILL;result.add_theme_font_size_override("font_size",maxi(T.MIN_FONT_SIZE,size));result.add_theme_color_override("font_color",T.INK);parent.add_child(result);return result
func _button(parent:Node,text:String,callback:Callable)->Button:
	var result:=Button.new();result.text=text;result.custom_minimum_size.y=36;result.pressed.connect(callback);result.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	result.add_theme_stylebox_override("normal",T.action_button_style(false));result.add_theme_stylebox_override("hover",T.action_button_style(false,true));result.add_theme_stylebox_override("pressed",T.button_pressed_style());result.add_theme_stylebox_override("hover_pressed",T.button_pressed_style());result.add_theme_stylebox_override("disabled",T.button_disabled_style())
	for state:String in ["font_color","font_hover_color","font_pressed_color","font_hover_pressed_color","font_focus_color"]:result.add_theme_color_override(state,T.INK)
	result.add_theme_color_override("font_disabled_color",T.DISABLED)
	parent.add_child(result);return result
func _selected(entry:Dictionary)->void:
	selected=entry
	_update_current_order()
	_refresh_mission_availability()
	if entry.is_empty():
		selected_label.text="No command selected";selected_label.tooltip_text="Choose a row above. Choosing the whole army gives every part of it the same order."
		map.selected_force=0;status.text="";status.hide();return
	selected_label.text="%s · %d %s" % [entry.name,int(entry.count),"people" if domain=="army" else "ships" if domain=="navy" else "aircraft"]
	selected_label.tooltip_text=_selection_tooltip(entry)
	map.selected_force=int(command.node(String(entry.id)).get("force_id",0))
	_update_status()
func _selection_tooltip(entry:Dictionary)->String:
	if entry.is_empty():return ""
	var result:="%s · %d %s\n%s" % [entry.name,int(entry.count),"people" if domain=="army" else "ships" if domain=="navy" else "aircraft",entry.leader]
	for type_id:String in entry.get("units",{}):
		var count:=int(entry.units[type_id])
		if count>0:result+="\n%d × %s" % [count,String(MilitaryCampaign.joint_operations.C.UNITS[type_id].label)]
	return result
func _select_force(id:int)->void:
	if domain=="army" and is_instance_valid(force_box):choose_force(id)
	command.sync()
	for entry:Dictionary in command.data.nodes.values():
		if entry.service==domain and int(entry.force_id)==id:tree.rebuild(String(entry.id));return
func _region(region:Dictionary)->void:
	map.selected=region;region_label.text="Area: "+String(region.get("name","No area chosen")) if not region.is_empty() else "No area chosen";region_label.tooltip_text=region_label.text;_refresh_targets()

func _update_current_order()->void:
	# Existing live panels may not contain this strip until they are reopened.
	if not is_instance_valid(current_order_label):return
	var brief:Dictionary=OrderBrief.snapshot(command,selected)
	current_order_label.text="Now: "+String(brief.summary);current_order_label.tooltip_text=String(brief.tooltip)
	current_order_label.add_theme_color_override("font_color",T.AMBER if brief.mixed or int(brief.overrides)>0 else T.GREEN if not brief.order.is_empty() else T.TEXT_DIM)
	edit_order_button.disabled=not bool(brief.editable)
	edit_order_button.tooltip_text="Put this order back in the form to change it. Nothing changes until you give the order again." if brief.editable else String(brief.tooltip)

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
	_report({"message":"The current order is back in the form. Give the order again to apply changes."})
func _draw_zone()->void:
	map.boundary_title=area_name.text;map.begin_boundary();_report({"message":"Click the corners on the map. Right-click or Enter closes the shape; Backspace removes the last corner; Escape stops."})
func _mission()->String:return String(mission.get_item_metadata(mission.selected))
func _refresh_mission_availability()->void:
	if not is_instance_valid(mission) or not is_instance_valid(apply_button) or not is_instance_valid(mission_hint):return
	mission_reasons.clear()
	var current:Dictionary={} if selected.is_empty() else command.preview(String(selected.id),selected.get("path",[]))
	var selection_error:=""
	if current.is_empty() or int(current.get("count",0))<=0:selection_error="Choose a command in the list first."
	elif not selected.get("path",[]).is_empty() and int(current.count)!=int(selected.count):selection_error="This part's strength changed. Choose it again before ordering it."
	var capabilities:Array[Dictionary]=[]
	if selection_error=="" and domain!="army":
		if not current.path.is_empty():
			capabilities.append({"name":String(current.name),"missions":MilitaryCampaign.joint_operations.missions_for({"domain":domain,"units":current.units})})
		else:
			for leaf:Dictionary in command.leaves(String(selected.id)):
				capabilities.append({"name":String(leaf.name),"missions":MilitaryCampaign.joint_operations.missions_for(command.force(leaf))})
	if is_instance_valid(selected_label):selected_label.tooltip_text=_selection_tooltip(current)
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
	apply_button.disabled=blocked!="";apply_button.tooltip_text=blocked if blocked!="" else "Give this task to the chosen command. Its leaders report when they are ready and supplied."
	mission_hint.text=blocked.get_slice("\n",0);mission_hint.tooltip_text=blocked
	mission_hint.visible=blocked!="" and not selected.is_empty()
	_update_preparation()
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
	if cities.item_count==0:cities.add_item("No known town in this area");cities.set_item_metadata(0,"");cities.disabled=true
	else:cities.disabled=false
	_refresh_mission_availability()
func _assign()->void:
	if selected.is_empty():_report({"error":"Select a command in the list first."});return
	_refresh_mission_availability()
	var blocked:=String(mission_reasons.get(_mission(),""))
	if blocked!="":_report({"error":blocked});return
	var current:Dictionary=command.preview(String(selected.id),selected.path)
	if current.is_empty() or (not selected.path.is_empty() and int(current.count)!=int(selected.count)):_report({"error":"This part's strength changed. Choose it again before ordering it."});tree.rebuild();return
	var result:Dictionary=command.assign(String(selected.id),selected.path,map.selected,_mission(),String(cities.get_item_metadata(cities.selected)),vision.text)
	_report(result)
	if not result.has("error"):tree.rebuild(String(result.id))
func _group()->void:
	var ids:Array=[]
	for entry:Dictionary in tree.selections():
		if not entry.path.is_empty():_report({"error":"Put whole commands together. To split off a smaller part, give it an order first."});return
		ids.append(String(entry.id))
	var result:Dictionary=command.organize(ids,group_level.selected,group_name.text)
	_report(result)
	if not result.has("error"):tree.rebuild(String(result.id))
func _cancel_orders()->void:
	if selected.is_empty():_report({"error":"Select a command in the list first."});return
	var result:Dictionary=command.cancel(String(selected.id),selected.get("path",[]),int(selected.get("count",-1)))
	_report(result)
	if not result.has("error"):
		tree.rebuild(String(result.id),result.get("path",[]))
		_update_status()
func _report(result:Dictionary)->void:
	feedback.text=String(result.get("error",result.get("message","Order updated.")))
	feedback.tooltip_text=feedback.text;feedback.visible=feedback.text!=""
	feedback.add_theme_color_override("font_color",T.RED if result.has("error") else T.GREEN)
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
			lines.append("%s: %s" % [leaf.name,report.get("command_status","Waiting for the commander's report")])
		else:lines.append("%s: %s" % [leaf.name,actual.get("status","Waiting for the staff's report")])
	status.text="\n".join(lines.slice(0,2));status.tooltip_text="\n".join(lines);status.visible=not lines.is_empty()
func _process(delta:float)->void:
	if panel==null:return
	var view:=get_viewport().get_visible_rect().size
	panel.offset_left=-minf(520,view.x*.54)-16;panel.offset_bottom=minf(view.y-16,860)
	# An editor hot reload can leave an older, already-open panel without these
	# new controls. It remains usable until the player closes and reopens it.
	if is_instance_valid(finish_button):finish_button.visible=map.drawing
	if is_instance_valid(cancel_boundary_button):cancel_boundary_button.visible=map.drawing
	tick+=delta
	if tick>=1:
		tick=0;tree.refresh();_update_status();_update_current_order();_refresh_mission_availability()
		if domain=="army":_refresh_flow()
func handle_early_input(event:InputEvent)->bool:
	if not event is InputEventKey or not event.pressed:return false
	if event.keycode==KEY_ESCAPE:
		if map.drawing:map.cancel_boundary();_report({"message":"Drawing stopped."})
		else:queue_free()
		return true
	var focused:=get_viewport().gui_get_focus_owner()
	if focused is LineEdit or focused is TextEdit:return false
	if event.keycode==KEY_D and not event.ctrl_pressed and not event.meta_pressed:show_zone_orders();_draw_zone();return true
	if map.drawing and event.keycode==KEY_ENTER:map.finish_boundary(area_name.text);return true
	if map.drawing and event.keycode==KEY_BACKSPACE:map.undo_vertex();return true
	return false
func handle_map_input(event:InputEvent)->bool:
	if domain=="army" and not map.drawing and event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
		var on_zones:=is_instance_valid(tabs) and is_instance_valid(zone_tab) and tabs.current_tab==zone_tab.get_index()
		if not on_zones and _pick_from_map(event.position):return true
	return map.handle_map_input(event)
