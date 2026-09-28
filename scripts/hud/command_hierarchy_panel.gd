extends CanvasLayer
## ARMY COMMAND, one army at a time, as HOI4 does it.
##
## Army: pick the army (the army bar along the bottom, a click on its mark,
## or the list at the top), pick one order by its icon, and point at the
## target on the map: hovering a town or the ground shows the road the
## general would take and how many days it is (the one march estimate,
## MilitaryCampaign.march_days through march_terrain.gd). One line says
## what happens in numbers ("24 men · 3 days · arrive 12 Spring"); the full
## reckoning is in its tooltip. The order goes through the court's war core
## (scripts/army_orders.gd -> court_war_orders), so the war leader objects,
## refuses or obeys exactly as in court, and "Talk it over" opens the court.
## A drawn front line or an offensive arrow (the HOI4 battle plan) becomes
## the same objectives: the line a defended zone along it, the arrow an
## attack on the town or host it points at, or an advance to the ground.
## Drawn zones and the organization of commands keep their own tabs.
## Navy and air: their zones are drawn (that is how those services work).
const Overlay=preload("res://scripts/hud/service_world_overlay.gd")
const CommandTree=preload("res://scripts/hud/command_tree.gd")
const OrderBrief=preload("res://scripts/hud/command_order_brief.gd")
const Preparation=preload("res://scripts/hud/command_preparation.gd")
const Orders=preload("res://scripts/army_orders.gd")
const T=preload("res://scripts/hud/hud_tokens.gd")
const Icons=preload("res://scripts/resource_icons.gd")
const BarModel=preload("res://scripts/hud/army_bar_model.gd")
const Portrait=preload("res://scripts/hud/person_portrait.gd")
const BattleMarks=preload("res://scripts/hud/battle_marks.gd")
const EraWords=preload("res://scripts/hud/era_words.gd")
const Board=preload("res://scripts/hud/recruit_deploy_board.gd")
const PICK_RADIUS_PX:=26.0
const PANEL_WIDTH:=452.0
const PANEL_TOP:=64.0
## The orders as the grid shows them: the verb, its icon and a short label.
const VERB_FACES:=[["attack","attack","Attack"],["siege","besiege","Besiege"],["raid","raid","Raid"],["defend","defend","Defend"],["guard","guard","Guard"],
	["goto","goto","Go to"],["recall","recall","Come home"],["front","front","Front line"],["arrow","arrow","Arrow"]]
const PLAN_HINTS:={"front":"Draw the line they hold: click along it on the map, then right-click to finish.",
	"arrow":"Draw where they strike: click the town, host or ground they drive at."}
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
# --- the army's orders ---
var force_id:=-1
var verb_id:=""
var target:Dictionary={}
var force_pick:OptionButton
var force_signature:=""
var force_face:TextureRect
var force_state:Control
var force_doing:Label
var force_meters:Array=[]
var verb_buttons:Dictionary={}
var target_row:HBoxContainer
var target_icon:TextureRect
var target_label:Label
var town_pick:OptionButton
var town_signature:=""
var happens_label:Label
var plan:Dictionary={}
var answer_box:PanelContainer
var answer_label:Label
var answer_outcome:Label
var insist_button:Button
var give_button:Button
var talk_button:Button
var last_answer:Dictionary={}
var ink:Control
## A battle plan being drawn: "front" or "arrow" while the map takes its points.
var plan_mode:=""
var plan_points:Array[Vector2]=[]
## What the pointer is over while a target is wanted: {key, target, plan, at}.
var hover:Dictionary={}

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
	panel.offset_top=PANEL_TOP;panel.offset_right=-16;panel.offset_left=-PANEL_WIDTH-16
	var skin:=T.flat(T.DOCK_BG,T.BORDER,1,T.RADIUS_CARD,12);skin.shadow_color=Color(0,0,0,.18 if T.is_light() else .45);skin.shadow_size=14;skin.shadow_offset=Vector2(0,5)
	panel.add_theme_stylebox_override("panel",skin);panel.add_theme_font_size_override("font_size",15)
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",8);panel.add_child(column)
	var heading:=_row(column)
	var title:=_label(heading,"Army command" if domain=="army" else "Fleet command" if domain=="navy" else "Air force command",22)
	title.add_theme_font_override("font",T.font("ui_strong"))
	title.autowrap_mode=TextServer.AUTOWRAP_OFF;title.clip_text=true;title.tooltip_text=_subtitle();title.mouse_filter=Control.MOUSE_FILTER_PASS
	var close:=_button(heading,"×",queue_free);close.custom_minimum_size=Vector2(36,36);close.size_flags_horizontal=Control.SIZE_SHRINK_END;close.size_flags_vertical=Control.SIZE_SHRINK_BEGIN;close.tooltip_text="Close · Escape"
	tabs=TabContainer.new();tabs.size_flags_vertical=Control.SIZE_EXPAND_FILL;column.add_child(tabs)
	if domain=="army":
		var plain:=VBoxContainer.new();plain.name="Orders";plain.add_theme_constant_override("separation",8);tabs.add_child(plain)
		_build_plain_orders(plain)
		var zones:=VBoxContainer.new();zones.name="Drawn zones";zones.add_theme_constant_override("separation",6);tabs.add_child(zones)
		zones.tooltip_text="Hold a stretch of border, encircle a host, send a small part of a band, or give a band a written brief."
		_build_zone_orders(zones)
		zone_tab=zones
	else:
		var orders:=VBoxContainer.new();orders.name="Orders";orders.add_theme_constant_override("separation",6);tabs.add_child(orders)
		_build_zone_orders(orders)
		zone_tab=orders
	feedback=_label(column,"",14);feedback.max_lines_visible=2;feedback.hide()
	_build_organization()
	_install_command_theme()
	_refresh_targets()
	if domain=="army":_refresh_flow(true)

func _subtitle()->String:
	if domain!="army":return "Draw where they work and choose their task. The %s decide how." % ("captains" if domain=="navy" else "wing leaders")
	var leader:=Orders.war_leader_name()
	return "Choose who goes, what they do and where. %s handles the rest." % (leader if leader!="" else "The war leader")

# --------------------------------------------------------------------------
# The army's orders
# --------------------------------------------------------------------------

func _build_plain_orders(parent:VBoxContainer)->void:
	# Who goes: the army's face, name, men and three bars (as its card on
	# the army bar), with the list of every force as its title.
	var card:=PanelContainer.new();card.name="Army";card.add_theme_stylebox_override("panel",T.flat(T.PAPER_RAISED,T.RULE,1,T.RADIUS_CARD,8));parent.add_child(card)
	var body:=HBoxContainer.new();body.add_theme_constant_override("separation",10);card.add_child(body)
	var frame:=PanelContainer.new();frame.clip_contents=true;frame.custom_minimum_size=Vector2(46,56);frame.add_theme_stylebox_override("panel",T.flat(T.PAPER_SUNK));frame.size_flags_vertical=Control.SIZE_SHRINK_BEGIN;body.add_child(frame)
	force_face=TextureRect.new();force_face.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;force_face.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED;frame.add_child(force_face)
	var words:=VBoxContainer.new();words.size_flags_horizontal=Control.SIZE_EXPAND_FILL;words.add_theme_constant_override("separation",3);body.add_child(words)
	var top:=_row(words)
	force_pick=OptionButton.new();force_pick.name="WhoGoes";force_pick.fit_to_longest_item=false;force_pick.clip_text=true;force_pick.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	force_pick.tooltip_text="Who goes. Pick a band here, on the army bar, or click its mark on the map."
	force_pick.item_selected.connect(func(index:int):choose_force(force_pick.get_item_id(index)))
	top.add_child(force_pick)
	force_state=StateGlyph.new();top.add_child(force_state)
	force_doing=_label(words,"",13);force_doing.add_theme_color_override("font_color",T.INK_MUTED);force_doing.autowrap_mode=TextServer.AUTOWRAP_OFF;force_doing.clip_text=true;force_doing.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	var meters:=_row(words);meters.add_theme_constant_override("separation",8)
	for kind:String in ["gear","will","supply"]:
		var meter:Control=Board.Meter.new();meter.kind=kind;meter.name=kind.capitalize();meter.size_flags_horizontal=Control.SIZE_EXPAND_FILL;meter.custom_minimum_size=Vector2(96,22);meters.add_child(meter);force_meters.append(meter)
	force_meters[0].clicked.connect(_open_production)
	# What: the orders by their icons.
	var grid:=GridContainer.new();grid.name="Verbs";grid.columns=5;grid.add_theme_constant_override("h_separation",5);grid.add_theme_constant_override("v_separation",5);parent.add_child(grid)
	for face:Array in VERB_FACES:
		var id:=String(face[0])
		var button:=_button(grid,String(face[2]),func():choose_verb(id))
		button.toggle_mode=true;button.icon=Icons.command_texture(String(face[1]),T.INK,48);button.expand_icon=false
		button.add_theme_constant_override("icon_max_width",22);button.icon_alignment=HORIZONTAL_ALIGNMENT_CENTER;button.vertical_icon_alignment=VERTICAL_ALIGNMENT_TOP
		button.custom_minimum_size=Vector2(80,56);button.add_theme_font_size_override("font_size",13)
		var hint:=String(PLAN_HINTS.get(id,String(Orders.verb(id).get("hint",""))))
		button.tooltip_text=hint
		verb_buttons[id]=button
	# Where: picked on the map; a short list for towns off the screen.
	target_row=_row(parent)
	target_icon=TextureRect.new();target_icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;target_icon.custom_minimum_size=Vector2(20,20);target_icon.size_flags_vertical=Control.SIZE_SHRINK_CENTER;target_row.add_child(target_icon)
	target_label=_label(target_row,"",15);target_label.autowrap_mode=TextServer.AUTOWRAP_OFF;target_label.clip_text=true;target_label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	town_pick=OptionButton.new();town_pick.name="PickTown";town_pick.fit_to_longest_item=false;town_pick.clip_text=true;town_pick.custom_minimum_size=Vector2(138,32);town_pick.size_flags_horizontal=Control.SIZE_SHRINK_END
	town_pick.tooltip_text="A town off the map's edge, or a host they saw."
	town_pick.item_selected.connect(_town_picked);target_row.add_child(town_pick)
	# What happens: one line in numbers; the reckoning in its tooltip.
	var happens:=_row(parent)
	var mark:=TextureRect.new();mark.texture=Icons.command_texture("date",T.INK_MUTED,40);mark.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;mark.custom_minimum_size=Vector2(20,20);mark.size_flags_vertical=Control.SIZE_SHRINK_CENTER;happens.add_child(mark)
	happens_label=_label(happens,"",15);happens_label.name="WhatHappens";happens_label.add_theme_font_override("font",T.font("ui_strong"))
	happens_label.autowrap_mode=TextServer.AUTOWRAP_OFF;happens_label.clip_text=true;happens_label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;happens_label.mouse_filter=Control.MOUSE_FILTER_PASS
	answer_box=PanelContainer.new();answer_box.add_theme_stylebox_override("panel",T.flat(T.PAPER_RAISED,T.GOLD,1,4,10));parent.add_child(answer_box);answer_box.hide()
	var answer_column:=VBoxContainer.new();answer_column.add_theme_constant_override("separation",6);answer_box.add_child(answer_column)
	answer_label=_label(answer_column,"",15);answer_label.max_lines_visible=3;answer_label.mouse_filter=Control.MOUSE_FILTER_PASS
	answer_outcome=_label(answer_column,"",13);answer_outcome.add_theme_color_override("font_color",T.BODY_2);answer_outcome.max_lines_visible=2
	var answer_row:=_row(answer_column)
	insist_button=_button(answer_row,"Insist",func():_give(true));insist_button.hide()
	insist_button.tooltip_text="Give the order again. They will go, whatever they think of it."
	var action:=_row(parent)
	give_button=_button(action,"Give the order",func():_give(false))
	give_button.add_theme_stylebox_override("normal",T.gold_outline_style());give_button.add_theme_color_override("font_color",T.GOLD_BRIGHT);give_button.custom_minimum_size.y=42
	talk_button=_button(action,"Talk it over",_talk);talk_button.custom_minimum_size.y=42
	talk_button.tooltip_text="Open the court and speak with the war leader about it."

func _section(parent:Node,text:String)->Label:
	var label:=_label(parent,text,15)
	label.add_theme_font_override("font",T.font("ui_strong"));label.add_theme_color_override("font_color",T.INK)
	label.autowrap_mode=TextServer.AUTOWRAP_OFF
	return label

func choose_force(id:int)->void:
	if force_id!=id:last_answer={}
	force_id=id
	if id>0 and is_instance_valid(map):map.selected_force=id
	_refresh_flow()

func choose_verb(id:String)->void:
	if id in ["front","arrow"]:begin_plan(id);return
	_end_plan_mode()
	if verb_id!=id:last_answer={}
	# A town chosen for Attack stays chosen for Besiege or Raid.
	var kind:=Orders.needs(id)
	if kind!=Orders.needs(verb_id) or (kind=="place" and String(target.get("type",""))=="host" and id!="attack") or verb_id in ["front","arrow"]:target={}
	verb_id=id
	hover={}
	_refresh_flow()

func choose_place(city_id:String)->void:
	var p:=Orders.place(city_id)
	if p.is_empty():return
	_end_plan_mode()
	last_answer={}
	if Orders.needs(verb_id)!="place":verb_id="attack"
	target={"type":"place","place":p}
	hover={}
	_refresh_flow()

func choose_host(host:Dictionary)->void:
	_end_plan_mode()
	last_answer={}
	verb_id="attack"
	target={"type":"host","formation_id":String(host.formation_id),"civ_id":String(host.civ_id),"label":String(host.label),"position":host.position}
	hover={}
	_refresh_flow()

func choose_spot(x:float,z:float)->void:
	_end_plan_mode()
	last_answer={}
	if Orders.needs(verb_id)!="spot":verb_id="goto"
	target={"type":"spot","x":x,"z":z}
	hover={}
	_refresh_flow()

# --- Battle plans: a front line or an offensive arrow ------------------------

func begin_plan(kind:String)->void:
	## The map takes the plan's points until it is finished (right-click,
	## Enter) or stopped (Escape).
	last_answer={}
	verb_id=kind;target={};plan_points.clear();hover={}
	plan_mode=kind
	_refresh_flow()

func plan_point(at:Vector2)->void:
	if plan_mode=="arrow":
		var aim:=_arrow_aim(at,Vector2.INF)
		target={"type":"arrow","to":{"x":at.x,"z":at.y},"aim":aim}
		plan_mode="";hover={}
		_refresh_flow();return
	if plan_mode!="front":return
	if not plan_points.is_empty() and plan_points[-1].distance_to(at)<0.1:return
	if plan_points.size()>=24:return
	plan_points.append(at)
	_refresh_flow()

func finish_plan()->void:
	if plan_mode!="front":return
	plan_mode=""
	if plan_points.size()>=2:
		var packed:Array=[]
		for p:Vector2 in plan_points:packed.append({"x":p.x,"z":p.y})
		target={"type":"front","points":packed}
	else:
		target={}
	hover={}
	_refresh_flow()

func cancel_plan()->void:
	plan_mode="";plan_points.clear();hover={}
	if verb_id in ["front","arrow"] and target.is_empty():verb_id=""
	_refresh_flow()

func _end_plan_mode()->void:
	plan_mode="";plan_points.clear()

func _plan_request()->Dictionary:
	## The drawn plan in the shape Orders.plan_preview and give_plan read.
	match verb_id:
		"front":
			var points:Array=target.get("points",[])
			if points.is_empty():
				for p:Vector2 in plan_points:points.append({"x":p.x,"z":p.y})
			return {"kind":"front","points":points}
		"arrow":
			var aim:Dictionary=target.get("aim",{})
			if aim.is_empty():return {"kind":"arrow"}
			return {"kind":"arrow","to":target.get("to",{}),"verb":String(aim.verb),"target":aim.target}
	return {}

func _arrow_aim(at:Vector2,screen:Vector2)->Dictionary:
	## What an arrow ending here strikes: the town or host under the pointer
	## (on screen), else what Orders.arrow_target finds near the ground.
	if screen.is_finite():
		var picked:=_place_or_host_at(screen)
		if not picked.is_empty():return {"verb":"attack","target":picked}
	return Orders.arrow_target(at)

# --- Refresh ------------------------------------------------------------------

func _default_force()->int:
	var cards:=Orders.forces()
	if cards.is_empty():return Orders.HOME
	# The biggest band ready at home, else the levy at home.
	var best:=int(cards[0].id);var most:=int(cards[0].troops)
	for card:Dictionary in cards:
		if int(card.id)!=Orders.HOME and bool(card.at_home) and int(card.troops)>=most:best=int(card.id);most=int(card.troops)
	return best

func _refresh_flow(first:=false)->void:
	if domain!="army" or not is_instance_valid(force_pick):return
	var cards:=Orders.forces()
	var ids:Array=[]
	for card:Dictionary in cards:ids.append(int(card.id))
	if first or not force_id in ids:force_id=_default_force()
	var signature:=str(cards.map(func(c:Dictionary)->Array:return [c.id,c.title]))
	if signature!=force_signature:
		force_signature=signature
		force_pick.clear()
		for card:Dictionary in cards:
			force_pick.add_item(String(card.title),int(card.id))
			force_pick.set_item_tooltip(force_pick.item_count-1,String(card.detail))
	force_pick.select(maxi(0,force_pick.get_item_index(force_id)))
	_refresh_force_card()
	for id:String in verb_buttons:
		var button:Button=verb_buttons[id]
		var reason:=Orders.unavailable(force_id,"guard" if id=="front" else ("attack" if id=="arrow" else id))
		button.disabled=reason!=""
		button.tooltip_text=reason if reason!="" else String(PLAN_HINTS.get(id,String(Orders.verb(id).get("hint",""))))
		button.set_pressed_no_signal(id==verb_id)
	if verb_id!="" and not verb_id in ["front","arrow"] and Orders.unavailable(force_id,verb_id)!="":
		verb_id=""
		for id:String in verb_buttons:(verb_buttons[id] as Button).set_pressed_no_signal(false)
	_refresh_where()
	_refresh_plan()

func _force_card()->Dictionary:
	if force_id==Orders.HOME:
		var home:=BarModel._home_card(MilitaryCampaign)
		if not home.is_empty():return home
		return {"kind":"home","title":"The levy at home","men":0,"full":0,"gear":1.0,"gear_detail":{},"will":0.6,"supply":1.0,"supply_state":"well","supply_words":"","state":"holding","doing":"nobody trained yet","general":{}}
	var record:=Orders.army(force_id)
	return {} if record.is_empty() else BarModel.army_card(MilitaryCampaign,record)

func _refresh_force_card()->void:
	var card:=_force_card()
	if card.is_empty():return
	var general:Dictionary=card.get("general",{})
	if String(card.kind)=="home" or general.is_empty():
		force_face.texture=Icons.command_texture("home" if String(card.kind)=="home" else "will",T.INK,64);force_face.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	else:
		force_face.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
		force_face.texture=Portrait.texture({"name":String(general.get("full_name",general.get("name",""))),"person_id":absi(String(general.get("figure_id",general.get("name",""))).hash())%997+1})
	var state_words:=BattleMarks.state_words(String(card.get("state","holding")))
	(force_state as StateGlyph).state=String(card.get("state","holding"));force_state.tooltip_text=state_words.substr(0,1).to_upper()+state_words.substr(1);force_state.queue_redraw()
	var doing:=String(card.get("doing",""))
	force_doing.text="%s men · %s" % [EraWords.grouped(int(card.get("men",0))),doing] if doing!="" else "%s men" % EraWords.grouped(int(card.get("men",0)))
	force_doing.tooltip_text=BarModel.tooltip(card).get_slice("\nClick",0)
	var gear:Dictionary=card.get("gear_detail",{})
	force_meters[0].clickable=not (gear.get("missing",{}) as Dictionary).is_empty()
	force_meters[0].set_reading(float(card.get("gear",1.0)),"%d%%" % roundi(float(card.get("gear",1.0))*100),BarModel.gear_color(float(card.get("gear",1.0))),BarModel.gear_words(gear))
	force_meters[1].set_reading(float(card.get("will",0.6)),"%d%%" % roundi(float(card.get("will",0.6))*100),BarModel.will_color(float(card.get("will",0.6))),BarModel.will_words(float(card.get("will",0.6)))+"\nBelow a quarter they break.")
	force_meters[2].set_reading(float(card.get("supply",1.0)),"%d%%" % roundi(float(card.get("supply",1.0))*100),BarModel.supply_color(String(card.get("supply_state","well"))),BarModel.supply_line(card))

func _refresh_where()->void:
	var kind:=Orders.needs(verb_id)
	var shown:=kind!="" or verb_id in ["front","arrow"]
	target_row.visible=shown
	town_pick.visible=kind=="place" or verb_id=="arrow"
	if not shown:return
	var chosen:=not target.is_empty()
	var icon:="goto"
	var words:=""
	match verb_id:
		"front":
			icon="front"
			if plan_mode=="front":words="Click along the line · right-click to finish" if plan_points.size()<2 else "%d points · right-click to finish" % plan_points.size()
			elif chosen:words="A line of %s km" % EraWords.grouped(maxi(1,roundi(Orders.line_km(target.get("points",[])))))
			else:words="Click along the line on the map"
		"arrow":
			icon="arrow"
			if chosen:words=_target_words((target.aim as Dictionary).target) if not (target.get("aim",{}) as Dictionary).is_empty() else "The marked ground"
			else:words="Click where they strike"
		_:
			if kind=="place":icon="attack"
			if chosen:words=_target_words(target)
			else:words="Click a town on the map" if kind=="place" else "Click the ground on the map"
	target_icon.texture=Icons.command_texture(icon,T.INK if chosen else T.INK_MUTED,40)
	target_label.text=words
	target_label.add_theme_color_override("font_color",T.INK if chosen else T.INK_MUTED)
	target_label.tooltip_text=words
	if town_pick.visible:_fill_town_pick()

func _target_words(chosen:Dictionary)->String:
	match String(chosen.get("type","")):
		"place":
			var p:Dictionary=chosen.place
			return "%s · %s" % [Orders.place_name(p),Orders.distance_words(Orders._v2(p.position))]
		"host":return "%s · %s" % [String(chosen.get("label","their host")),Orders.distance_words(Orders._v2(chosen.position))]
		"spot":
			var at:=Vector2(float(chosen.x),float(chosen.z))
			var words:=Orders.spot_words(at).trim_prefix("the ").trim_prefix("marked ground, ")
			return words.substr(0,1).to_upper()+words.substr(1)
	return ""

func _fill_town_pick()->void:
	var towns:=Orders.places().slice(0,8)
	var seen:=Orders.hosts().slice(0,4)
	var signature:=str([towns.map(func(p:Dictionary)->String:return String(p.city_id)),seen.map(func(h:Dictionary)->String:return String(h.formation_id)),target.get("type",""),(target.get("place",{}) as Dictionary).get("city_id",""),target.get("formation_id","")])
	if signature==town_signature:return
	town_signature=signature
	town_pick.clear()
	town_pick.add_item("Pick a town",0);town_pick.set_item_metadata(0,{})
	for p:Dictionary in towns:
		town_pick.add_item("%s · %s" % [Orders.place_name(p),Orders.distance_words(Orders._v2(p.position))])
		town_pick.set_item_metadata(town_pick.item_count-1,{"type":"place","city_id":String(p.city_id)})
		if String((target.get("place",{}) as Dictionary).get("city_id",""))==String(p.city_id):town_pick.select(town_pick.item_count-1)
	for host:Dictionary in seen:
		town_pick.add_item("%s · seen" % String(host.label))
		town_pick.set_item_metadata(town_pick.item_count-1,{"type":"host","host":host})
		if String(target.get("formation_id",""))==String(host.formation_id):town_pick.select(town_pick.item_count-1)
	town_pick.disabled=towns.is_empty() and seen.is_empty()
	if town_pick.disabled:town_pick.set_item_text(0,"No town known yet");town_pick.tooltip_text="No town of theirs is on our charts yet. Send scouts first."

func _town_picked(index:int)->void:
	var meta:Variant=town_pick.get_item_metadata(index)
	if not meta is Dictionary or (meta as Dictionary).is_empty():return
	if verb_id=="arrow":
		var aim:Dictionary={}
		var at:=Vector2.INF
		if String(meta.type)=="place":
			var p:=Orders.place(String(meta.city_id));aim={"verb":"attack","target":{"type":"place","place":p}};at=Orders._v2(p.position)
		else:
			var host:Dictionary=meta.host;aim={"verb":"attack","target":{"type":"host","formation_id":String(host.formation_id),"civ_id":String(host.civ_id),"label":String(host.label),"position":host.position}};at=Orders._v2(host.position)
		plan_mode="";target={"type":"arrow","to":{"x":at.x,"z":at.y},"aim":aim};_refresh_flow();return
	if String(meta.type)=="place":choose_place(String(meta.city_id))
	else:choose_host(meta.host)

func _refresh_plan()->void:
	var reading:Dictionary
	if verb_id in ["front","arrow"]:reading=Orders.plan_preview(force_id,_plan_request())
	elif verb_id!="":reading=Orders.preview(force_id,verb_id,target)
	else:reading={"lines":[],"ready":false,"likely":""}
	plan=reading
	var line:=Orders.summary(reading)
	if verb_id=="":line="Choose an order, then its target."
	elif plan_mode!="":line=String(PLAN_HINTS.get(plan_mode,"")).get_slice(":",0)
	elif not bool(reading.get("ready",false)) and String(reading.get("likely",""))!="impossible":line=""
	happens_label.text=line
	happens_label.get_parent().visible=line!=""
	var likely:=String(reading.get("likely",""))
	happens_label.add_theme_color_override("font_color",T.RED_TEXT if likely=="impossible" else (T.AMBER_TEXT if likely=="object" else T.INK))
	happens_label.tooltip_text="\n".join(reading.get("lines",[])) if not (reading.get("lines",[]) as Array).is_empty() else line
	give_button.disabled=not bool(reading.get("ready",false)) or likely=="impossible" or plan_mode!=""
	give_button.tooltip_text="Choose who goes, what they do and where first." if not bool(reading.get("ready",false)) else ("This cannot be done now." if likely=="impossible" else "The war leader hears the order and answers.")
	var leader:=Orders.war_leader_name()
	talk_button.text="Talk it over with %s" % leader if leader!="" else "Talk it over at court"
	if is_instance_valid(ink):ink.road=reading.get("road",[]);ink.queue_redraw()
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
	answer_label.tooltip_text=answer_label.text
	var outcome:=String(last_answer.get("outcome","")).strip_edges()
	answer_outcome.text=outcome if String(last_answer.verdict)=="act" and outcome!=says else ""
	answer_outcome.visible=answer_outcome.text!=""
	var tone:Color=T.GREEN if String(last_answer.verdict)=="act" else (T.AMBER if String(last_answer.verdict)=="object" else T.RED)
	answer_box.add_theme_stylebox_override("panel",T.flat(T.PAPER_RAISED,tone,1,4,10))

func _give(insist:bool)->void:
	var result:Dictionary
	if verb_id in ["front","arrow"]:result=Orders.give_plan(force_id,_plan_request(),insist)
	else:result=Orders.give(force_id,verb_id,target,insist)
	last_answer=result
	# The answer card carries the reply; the line under the panel stays quiet.
	feedback.text="";feedback.hide()
	if String(result.verdict)=="act":
		var army_id:=int((result.get("objective",{}) as Dictionary).get("army_id",0))
		verb_id="";target={};plan_points.clear()
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

func _open_production()->void:
	if is_instance_valid(terrain) and "hud" in terrain and terrain.hud:
		terrain.hud.open_dock("production",2)

# --- The map ------------------------------------------------------------------

func _place_or_host_at(at:Vector2)->Dictionary:
	## The town or seen host of theirs drawn under a screen point, as a target.
	var mark:Dictionary={}
	if is_instance_valid(terrain) and terrain.has_method("_war_mark_at"):mark=terrain.call("_war_mark_at",at)
	if String(mark.get("kind",""))=="sighting":
		var enemy_id:=String(mark.get("enemy_id",""))
		for host:Dictionary in Orders.hosts():
			if String(host.formation_id)==enemy_id:return {"type":"host","formation_id":String(host.formation_id),"civ_id":String(host.civ_id),"label":String(host.label),"position":host.position}
	var best:={};var best_d:=PICK_RADIUS_PX
	for p:Dictionary in Orders.places():
		var screen:Vector2=map.world_to_screen(Orders._v2(p.position))
		var d:=screen.distance_to(at)
		if screen.is_finite() and d<best_d:best_d=d;best=p
	if not best.is_empty():return {"type":"place","place":best}
	for host:Dictionary in Orders.hosts():
		var screen:Vector2=map.world_to_screen(Orders._v2(host.position))
		if screen.is_finite() and screen.distance_to(at)<PICK_RADIUS_PX:return {"type":"host","formation_id":String(host.formation_id),"civ_id":String(host.civ_id),"label":String(host.label),"position":host.position}
	return {}

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
	if needs!="spot":
		var picked:=_place_or_host_at(at)
		match String(picked.get("type","")):
			"place":choose_place(String((picked.place as Dictionary).city_id));return true
			"host":choose_host(picked);return true
	if needs=="spot" or verb_id=="":
		# Open ground with nothing chosen yet means "go there".
		var hit:Dictionary=map.screen_to_world(at)
		if hit.is_empty() and verb_id=="":return false
		if hit.is_empty():_report({"error":"That is off the chart. Click charted ground."});return true
		choose_spot(float(hit.x),float(hit.z));return true
	if needs=="place":
		_report({"error":"That is not a town of theirs we know. Click a town's name or a host of theirs, or pick one from the list."});return true
	return false

func hover_target(at:Vector2)->void:
	## While an order wants its target, the pointer shows the road there and
	## the days it takes (the same estimate the order will state).
	if domain!="army":return
	var want:=Orders.needs(verb_id)
	var drawing_arrow:=plan_mode=="arrow"
	var drawing_front:=plan_mode=="front"
	if want=="" and not drawing_arrow and not drawing_front:
		if not hover.is_empty():hover={};ink.queue_redraw()
		return
	var candidate:Dictionary={}
	var key:=""
	if drawing_front:
		var hit:Dictionary=map.screen_to_world(at)
		hover={"at":at,"world":Vector2(float(hit.x),float(hit.z)) if not hit.is_empty() else Vector2.INF}
		ink.queue_redraw();return
	if want=="place" or drawing_arrow:
		candidate=_place_or_host_at(at)
		match String(candidate.get("type","")):
			"place":key="place:"+String((candidate.place as Dictionary).city_id)
			"host":key="host:"+String(candidate.formation_id)
	if candidate.is_empty() and (want=="spot" or drawing_arrow):
		var hit:Dictionary=map.screen_to_world(at)
		if not hit.is_empty():
			var ground:=Vector2(float(hit.x),float(hit.z))
			candidate={"type":"spot","x":ground.x,"z":ground.y}
			key="spot:%d:%d" % [roundi(ground.x),roundi(ground.y)]
	if candidate.is_empty():
		if not hover.is_empty():hover={};ink.queue_redraw()
		return
	# The same target (a town, or the same square kilometre of ground), or too
	# soon after the last reckoning: only the pointer moves. The road is worked
	# out at most about eight times a second.
	var now:=Time.get_ticks_msec()
	if key==String(hover.get("key","")):
		hover.at=at;hover.erase("pending");ink.queue_redraw();return
	if not hover.is_empty() and now-int(hover.get("clock",0))<120:
		# Reckoned again once the pointer settles (see _process).
		hover.at=at;hover["pending"]=at;ink.queue_redraw();return
	var reading:Dictionary
	if drawing_arrow:
		var aim:={"verb":"attack","target":candidate} if String(candidate.type)!="spot" else {"verb":"goto","target":candidate}
		reading=Orders.plan_preview(force_id,{"kind":"arrow","verb":aim.verb,"target":aim.target})
	else:
		reading=Orders.preview(force_id,verb_id,candidate)
	var name:=Orders.target_title(candidate) if String(candidate.type)!="spot" else ""
	if name!="":name=name.substr(0,1).to_upper()+name.substr(1)
	var days:=int(reading.get("days",0))
	var words:=("%s · " % name if name!="" else "")+("%d %s" % [days,"day" if days==1 else "days"] if float(reading.get("km",0.0))>=0.5 else "here")
	if String(reading.get("likely",""))=="impossible":words=String(Orders.summary(reading))
	hover={"key":key,"target":candidate,"road":reading.get("road",[]),"words":words,"at":at,"likely":String(reading.get("likely","")),"clock":now}
	ink.queue_redraw()

class StateGlyph extends Control:
	## The army's state, drawn as on its counter (hud/battle_marks.gd).
	var state:="holding"
	func _ready()->void:
		custom_minimum_size=Vector2(22,22);size_flags_vertical=Control.SIZE_SHRINK_CENTER;mouse_filter=Control.MOUSE_FILTER_PASS
	func _draw()->void:
		preload("res://scripts/hud/battle_marks.gd").draw_state(self,size*0.5,state,8.0)

class TargetInk extends Control:
	## The chosen target, the road there, the road under the pointer and the
	## battle plan being drawn, inked on the map under the panel.
	var owner_panel:CanvasLayer
	var road:Array=[]
	const T=preload("res://scripts/hud/hud_tokens.gd")
	const BattleMarks=preload("res://scripts/hud/battle_marks.gd")
	func _ready()->void:
		mouse_filter=Control.MOUSE_FILTER_IGNORE;set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	func _process(_delta:float)->void:
		if not road.is_empty() or not (owner_panel.target as Dictionary).is_empty() or not (owner_panel.hover as Dictionary).is_empty() or owner_panel.plan_mode!="":queue_redraw()
	func _screen(map:Control,p:Variant)->Vector2:
		if p is Vector2:return map.world_to_screen(p)
		if p is Dictionary and (p as Dictionary).has_all(["x","z"]):return map.world_to_screen(Vector2(float(p.x),float(p.z)))
		return Vector2.INF
	func _points(map:Control,list:Array)->PackedVector2Array:
		var points:=PackedVector2Array()
		for p in list:
			var at:=_screen(map,p)
			if at.is_finite():points.append(at)
		return points
	func _dashed(points:PackedVector2Array,colour:Color,width:float,halo:float)->void:
		if points.size()<2:return
		draw_polyline(points,Color(BattleMarks.PAPER,0.85),width+halo,true)
		for i in points.size()-1:draw_dashed_line(points[i],points[i+1],colour,width,9.0,true,true)
	func _front(points:PackedVector2Array,colour:Color)->void:
		## A front line with its teeth toward the enemy side (left of travel).
		if points.size()<2:return
		draw_polyline(points,Color(BattleMarks.PAPER,0.9),6.0,true)
		draw_polyline(points,colour,3.0,true)
		for i in points.size()-1:
			var a:=points[i];var b:=points[i+1]
			var length:=a.distance_to(b)
			if length<4.0:continue
			var along:=(b-a)/length;var out:=Vector2(along.y,-along.x)
			var step:=14.0;var t:=step*0.5
			while t<length:
				var base:=a+along*t
				draw_colored_polygon(PackedVector2Array([base-along*4.0,base+along*4.0,base+out*7.0]),colour)
				t+=step
	func _arrow(points:PackedVector2Array,colour:Color)->void:
		## The offensive arrow along the road, broad at the tail.
		if points.size()<2:return
		var total:=0.0
		for i in points.size()-1:total+=points[i].distance_to(points[i+1])
		if total<12.0:return
		var run:=0.0
		for i in points.size()-1:
			var a:=points[i];var b:=points[i+1];var d:=a.distance_to(b)
			var w:=lerpf(11.0,6.0,clampf(run/total,0.0,1.0))
			draw_line(a,b,Color(BattleMarks.PAPER,0.8),w+4.0,true)
			draw_line(a,b,Color(colour,0.82),w,true)
			run+=d
		var tip:=points[-1];var back:=points[-2]
		var along:=(tip-back).normalized();var side:=along.orthogonal()
		var head:=PackedVector2Array([tip+along*6.0,tip-along*14.0+side*11.0,tip-along*14.0-side*11.0])
		draw_colored_polygon(head,Color(colour,0.9))
		draw_polyline(PackedVector2Array([head[0],head[1],head[2],head[0]]),Color(BattleMarks.INK,0.8),1.5,true)
	func _label(at:Vector2,text:String,tone:Color)->void:
		if text=="" or not at.is_finite():return
		var font:=T.font("ui_strong")
		var width:=font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,14).x
		var box:=Rect2(at+Vector2(16,-30),Vector2(width+14,24))
		draw_style_box(T.flat(T.PAPER_RAISED,T.RULE_STRONG,1,3,0),box)
		draw_string(font,box.position+Vector2(7,17),text,HORIZONTAL_ALIGNMENT_LEFT,-1,14,tone)
	func _draw()->void:
		if owner_panel==null or not is_instance_valid(owner_panel.map):return
		var map:Control=owner_panel.map
		var gold:=T.GOLD
		var oxblood:=BattleMarks.OXBLOOD
		var verb:=String(owner_panel.verb_id)
		# The plan being drawn, or drawn.
		if verb=="front":
			var line:Array=(owner_panel.target as Dictionary).get("points",[])
			var points:=_points(map,line if not line.is_empty() else owner_panel.plan_points)
			var hover_world:Vector2=(owner_panel.hover as Dictionary).get("world",Vector2.INF)
			if owner_panel.plan_mode=="front" and hover_world.is_finite():
				var cursor:Vector2=map.world_to_screen(hover_world)
				if cursor.is_finite():points.append(cursor)
			_front(points,oxblood)
			for p in owner_panel.plan_points:
				var at:=_screen(map,p)
				if at.is_finite():draw_circle(at,3.5,oxblood)
		var roads:=PackedVector2Array()
		if not road.is_empty():roads=_points(map,road)
		if verb=="arrow" and not (owner_panel.target as Dictionary).is_empty():_arrow(roads,oxblood)
		elif verb!="front":_dashed(roads,gold,2.4,3.0)
		# The road under the pointer, and its days.
		var hovered:Dictionary=owner_panel.hover
		if not hovered.is_empty() and hovered.has("road"):
			var path:=_points(map,hovered.road)
			if verb=="arrow":_arrow(path,Color(oxblood,0.6))
			else:_dashed(path,Color(BattleMarks.INK,0.75),1.8,2.5)
			_label(hovered.get("at",Vector2.INF),String(hovered.get("words","")),T.RED_TEXT if String(hovered.get("likely",""))=="impossible" else T.INK)
		# The chosen place.
		var chosen:Dictionary=owner_panel.target
		var where:=Vector2.INF
		match String(chosen.get("type","")):
			"place":where=Orders._v2((chosen.place as Dictionary).position)
			"host":where=Orders._v2(chosen.position)
			"spot":where=Vector2(float(chosen.x),float(chosen.z))
			"arrow":where=Orders._v2(chosen.get("to",{}))
		if not where.is_finite():return
		var at:Vector2=map.world_to_screen(where)
		if not at.is_finite():return
		var ring:=oxblood if verb=="arrow" else gold
		draw_arc(at,15.0,0,TAU,40,Color(BattleMarks.PAPER,0.85),6.0,true)
		draw_arc(at,15.0,0,TAU,40,ring,2.4,true)
		draw_arc(at,5.0,0,TAU,20,ring,2.0,true)

# --------------------------------------------------------------------------
# Drawn zones (army: its own tab; navy and air: their orders)
# --------------------------------------------------------------------------

func _build_zone_orders(orders:VBoxContainer)->void:
	var noun:="band" if domain=="army" else "fleet" if domain=="navy" else "wing"
	_heading(orders,"Choose a %s" % noun,"Pick a whole force, or open it to pick a smaller part.")
	tree=CommandTree.new();tree.service=domain;orders.add_child(tree);tree.custom_minimum_size.y=180;tree.size_flags_vertical=Control.SIZE_SHRINK_BEGIN;tree.command_selected.connect(_selected)
	var scroll:=ScrollContainer.new();orders_scroll=scroll;scroll.custom_minimum_size.y=100;scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;orders.add_child(scroll)
	var controls:=VBoxContainer.new();controls.size_flags_horizontal=Control.SIZE_EXPAND_FILL;controls.add_theme_constant_override("separation",6);scroll.add_child(controls)
	var selection_card:=_zone_card(controls)
	selected_label=_label(selection_card,"No command selected",16)
	selected_label.autowrap_mode=TextServer.AUTOWRAP_OFF;selected_label.clip_text=true
	var current_row:=_row(selection_card)
	current_order_label=_label(current_row,"Now: No command selected",14)
	current_order_label.autowrap_mode=TextServer.AUTOWRAP_OFF;current_order_label.clip_text=true
	edit_order_button=_button(current_row,"Change it",_edit_current_order);edit_order_button.custom_minimum_size=Vector2(96,30);edit_order_button.size_flags_horizontal=Control.SIZE_SHRINK_END;edit_order_button.disabled=true
	mission=OptionButton.new();mission.clip_text=true;controls.add_child(mission)
	mission.tooltip_text="Choosing a task does not give the order. Use Give the order, or right-click an area on the map."
	mission.custom_minimum_size.y=38;mission.add_theme_stylebox_override("normal",T.gold_outline_style())
	var catalog:Dictionary=command.LAND_MISSIONS if domain=="army" else MilitaryCampaign.joint_operations.MISSIONS[domain]
	for id:String in catalog:
		if id=="transport":continue
		mission.add_item("Task: "+String(catalog[id]));mission.set_item_metadata(mission.item_count-1,id)
	mission.item_selected.connect(func(_index:int):_refresh_targets())
	mission_hint=_label(controls,"",14);mission_hint.max_lines_visible=2;mission_hint.add_theme_color_override("font_color",T.RED_TEXT);mission_hint.hide()
	cities=OptionButton.new();cities.clip_text=true;controls.add_child(cities)
	var zone_card:=_zone_card(controls)
	var area_row:=_row(zone_card)
	region_label=_label(area_row,"No area chosen",15)
	region_label.max_lines_visible=1;region_label.tooltip_text="Click corners on the map; right-click or Enter closes the shape."
	var draw:=_button(area_row,"Draw an area",_draw_zone);draw.tooltip_text="Click corners on the map; right-click or Enter closes the shape. Shortcut: D";draw.size_flags_horizontal=Control.SIZE_SHRINK_END
	_build_preparation(controls)
	var drawing:=_row(controls)
	finish_button=_button(drawing,"Finish",func():map.finish_boundary(area_name.text))
	cancel_boundary_button=_button(drawing,"Cancel drawing",func():map.cancel_boundary())
	finish_button.hide();cancel_boundary_button.hide()
	details_toggle=_button(controls,"Add a name or a brief ▸",func():details.visible=not details.visible;details_toggle.text="Hide name and brief ▾" if details.visible else "Add a name or a brief ▸")
	details=VBoxContainer.new();details.add_theme_constant_override("separation",6);controls.add_child(details);details.hide()
	area_name=LineEdit.new();area_name.placeholder_text="Name for the area (optional)";details.add_child(area_name)
	vision=LineEdit.new();vision.placeholder_text="A brief for the commander (optional)";vision.tooltip_text="A note the commander keeps with this order. It does not change what they can do.";details.add_child(vision)
	status=_label(controls,"",14);status.max_lines_visible=2;status.hide()
	# The action stays outside the scrolling details, at every scroll position.
	var action:=_row(orders);apply_button=_button(action,"Give the order",_assign);apply_button.add_theme_stylebox_override("normal",T.gold_outline_style());apply_button.add_theme_color_override("font_color",T.GOLD_BRIGHT)
	var cancel_orders:=_button(action,"Cancel orders",_cancel_orders)
	cancel_orders.tooltip_text="Cancel only the chosen command's orders. Others keep theirs."

func show_zone_orders()->void:
	if is_instance_valid(tabs) and is_instance_valid(zone_tab):tabs.current_tab=zone_tab.get_index()

func _build_organization()->void:
	var organization:=VBoxContainer.new();organization.name="Organization";organization.add_theme_constant_override("separation",8);tabs.add_child(organization)
	var head:=_section(organization,"Put commands under one leader")
	head.tooltip_text="In the list on the %s tab, hold Ctrl and click to choose several commands. Then choose the size of the new command here. Orders to it go to everyone under it." % ("Drawn zones" if domain=="army" else "Orders")
	head.mouse_filter=Control.MOUSE_FILTER_PASS
	var choose:=_row(organization)
	group_level=OptionButton.new();group_level.size_flags_horizontal=Control.SIZE_EXPAND_FILL;choose.add_child(group_level)
	for index in command.LEVELS[domain].size():group_level.add_item(String(command.LEVELS[domain][index][0]));group_level.set_item_metadata(index,index)
	group_level.select(command.LEVELS[domain].size()-1)
	group_name=LineEdit.new();group_name.placeholder_text="Name (optional)";group_name.size_flags_horizontal=Control.SIZE_EXPAND_FILL;choose.add_child(group_name)
	var together:=_button(organization,"Put chosen commands together",_group)
	together.tooltip_text="Opening a force in the list shows its smaller parts. A part only leaves its force when you give it an order; nobody new is raised."
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
		for state:String in ["tab_selected","tab_unselected","tab_hovered"]:
			var tab:=T.flat(T.DOCK_BG if state=="tab_selected" else Color.TRANSPARENT,T.GOLD if state=="tab_selected" else T.BORDER_SOFT,0,0,10)
			tab.content_margin_top=6;tab.content_margin_bottom=6
			if state=="tab_selected":tab.border_width_bottom=2;tab.border_color=T.GOLD
			theme.set_stylebox(state,type,tab)
	for state:String in ["title_button_normal","title_button_hover","title_button_pressed"]:theme.set_stylebox(state,"Tree",T.flat(T.TILE_BG,T.BORDER_SOFT,1,2,6))
	theme.set_color("title_button_color","Tree",T.INK)
	theme.set_stylebox("panel","PopupMenu",T.flat(T.DOCK_BG,T.BORDER,1,4,8))
	theme.set_stylebox("hover","PopupMenu",T.flat(T.HOVER_BG))
	T.add_tooltip_style(theme)
	panel.theme=theme

func _row(parent:Node)->HBoxContainer:
	var result:=HBoxContainer.new();result.add_theme_constant_override("separation",6);parent.add_child(result);return result

func _heading(parent:Node,title:String,explanation:String)->Label:
	## A heading in ink; what it means is in its tooltip.
	var head:=_section(parent,title);head.tooltip_text=explanation;head.mouse_filter=Control.MOUSE_FILTER_PASS
	return head

func _zone_card(parent:Node)->VBoxContainer:
	var frame:=PanelContainer.new();var style:=T.flat(T.ROW_BG,T.BORDER_SOFT,1,4,8);style.content_margin_top=5;style.content_margin_bottom=5;frame.add_theme_stylebox_override("panel",style);frame.size_flags_horizontal=Control.SIZE_EXPAND_FILL;parent.add_child(frame)
	var content:=VBoxContainer.new();content.add_theme_constant_override("separation",4);frame.add_child(content)
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
	preparation_fuel.add_theme_color_override("font_color",T.RED_TEXT if int(prepared.shortage)>0 else T.TEXT_DIM)
	preparation_note.text=String(prepared.summary);preparation_note.tooltip_text=String(prepared.tooltip)
	preparation_note.add_theme_color_override("font_color",T.AMBER_TEXT if prepared.warning else T.GREEN_TEXT)
	var unavailable:=String(mission_reasons.get(_mission(),""))
	if unavailable!="":
		preparation_note.text="This command cannot perform the selected objective."
		preparation_note.tooltip_text=unavailable+"\n\n"+String(prepared.tooltip);preparation_note.add_theme_color_override("font_color",T.RED_TEXT)
	preparation_box.tooltip_text=String(prepared.tooltip)
func _label(parent:Node,text:String,size:int=15)->Label:
	var result:=Label.new();result.text=text;result.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;result.size_flags_horizontal=Control.SIZE_EXPAND_FILL;result.add_theme_font_size_override("font_size",maxi(T.MIN_FONT_SIZE,size));result.add_theme_color_override("font_color",T.INK);parent.add_child(result);return result
func _button(parent:Node,text:String,callback:Callable)->Button:
	var result:=Button.new();result.text=text;result.custom_minimum_size.y=34;result.pressed.connect(callback);result.size_flags_horizontal=Control.SIZE_EXPAND_FILL;result.focus_mode=Control.FOCUS_NONE
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
	if domain=="army" and is_instance_valid(force_pick):choose_force(id)
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
	current_order_label.add_theme_color_override("font_color",T.AMBER_TEXT if brief.mixed or int(brief.overrides)>0 else T.GREEN_TEXT if not brief.order.is_empty() else T.TEXT_DIM)
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
	feedback.add_theme_color_override("font_color",T.RED_TEXT if result.has("error") else T.GREEN_TEXT)
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
	panel.offset_left=-minf(PANEL_WIDTH,view.x*.54)-16
	# The orders fit their content; the drawn zones use the height they need.
	var room:=maxf(240.0,view.y-PANEL_TOP-16.0)
	var want:=panel.get_combined_minimum_size().y
	if is_instance_valid(tabs) and is_instance_valid(zone_tab) and tabs.current_tab==zone_tab.get_index():want=maxf(want,minf(640.0,room))
	panel.offset_top=PANEL_TOP;panel.offset_bottom=PANEL_TOP+minf(want,room)
	# An editor hot reload can leave an older, already-open panel without these
	# new controls. It remains usable until the player closes and reopens it.
	if is_instance_valid(finish_button):finish_button.visible=map.drawing
	if is_instance_valid(cancel_boundary_button):cancel_boundary_button.visible=map.drawing
	if hover.has("pending") and Time.get_ticks_msec()-int(hover.get("clock",0))>=120:
		var settled:Vector2=hover.pending
		hover.erase("pending");hover.clock=0
		hover_target(settled)
	tick+=delta
	if tick>=1:
		tick=0;tree.refresh();_update_status();_update_current_order();_refresh_mission_availability()
		if domain=="army":_refresh_flow()
func handle_early_input(event:InputEvent)->bool:
	if not event is InputEventKey or not event.pressed:return false
	if event.keycode==KEY_ESCAPE:
		if plan_mode!="":cancel_plan();_report({"message":"Drawing stopped."})
		elif map.drawing:map.cancel_boundary();_report({"message":"Drawing stopped."})
		else:queue_free()
		return true
	var focused:=get_viewport().gui_get_focus_owner()
	if focused is LineEdit or focused is TextEdit:return false
	if plan_mode=="front" and event.keycode in [KEY_ENTER,KEY_KP_ENTER]:finish_plan();return true
	if plan_mode=="front" and event.keycode==KEY_BACKSPACE:
		if not plan_points.is_empty():plan_points.pop_back();_refresh_flow()
		return true
	if event.keycode==KEY_D and not event.ctrl_pressed and not event.meta_pressed:show_zone_orders();_draw_zone();return true
	if map.drawing and event.keycode==KEY_ENTER:map.finish_boundary(area_name.text);return true
	if map.drawing and event.keycode==KEY_BACKSPACE:map.undo_vertex();return true
	return false
func handle_map_input(event:InputEvent)->bool:
	if domain=="army" and not map.drawing:
		var on_zones:=is_instance_valid(tabs) and is_instance_valid(zone_tab) and tabs.current_tab==zone_tab.get_index()
		if event is InputEventMouseMotion and not on_zones:
			hover_target(event.position)
			return false
		if not on_zones and plan_mode!="" and event is InputEventMouseButton and event.pressed:
			if event.button_index==MOUSE_BUTTON_RIGHT:
				if plan_mode=="front":finish_plan()
				else:cancel_plan()
				return true
			if event.button_index==MOUSE_BUTTON_LEFT:
				if plan_mode=="arrow":
					var aim:=_place_or_host_at(event.position)
					var hit:Dictionary=map.screen_to_world(event.position)
					var at:=Vector2(float(hit.x),float(hit.z)) if not hit.is_empty() else Vector2.INF
					if not aim.is_empty():
						var aim_at:=Orders._v2((aim.place as Dictionary).position) if String(aim.type)=="place" else Orders._v2(aim.position)
						target={"type":"arrow","to":{"x":aim_at.x,"z":aim_at.y},"aim":{"verb":"attack","target":aim}};plan_mode="";hover={};_refresh_flow();return true
					if not at.is_finite():_report({"error":"That is off the chart. Click charted ground."});return true
					plan_point(at);return true
				var hit:Dictionary=map.screen_to_world(event.position)
				if hit.is_empty():_report({"error":"That is off the chart. Click charted ground."});return true
				if event.double_click and plan_points.size()>=2:finish_plan();return true
				plan_point(Vector2(float(hit.x),float(hit.z)));return true
		if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
			if not on_zones and _pick_from_map(event.position):return true
	return map.handle_map_input(event)
