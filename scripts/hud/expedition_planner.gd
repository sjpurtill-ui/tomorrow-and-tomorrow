extends Node
## SENDING AN EXPEDITION (expedition.gd), on the map. A paper card at the
## map's right holds the choices: on foot or by sea (when the boats allow),
## a direction, how far to push and how many go. The map shows the push
## itself: the route the party would take inked from home, its far point
## marked, and rings at each distance it could push lettered with how many
## in 100 come home from there, so the odds falling with distance are read
## off the chart. The card gives the engine's numbers: days away, food,
## the chance of coming home, what a homecoming brings and what a loss
## costs. "Send them" commits it; the game waits while the god decides.

const Expedition:=preload("res://scripts/expedition.gd")
const Kit:=preload("res://scripts/hud/paper_kit.gd")
const T:=preload("res://scripts/hud/hud_tokens.gd")
const Icons:=preload("res://scripts/resource_icons.gd")

const NODE_NAME:="ExpeditionPlanner"
const INK:=Color("#2b2118")
const PAPER:=Color("#efe3c2")
const SEA_INK:=Color("#2f5d73")
const COMPASS:=[["northwest","NW"],["north","N"],["northeast","NE"],["west","W"],["",""],["east","E"],["southwest","SW"],["south","S"],["southeast","SE"]]

var terrain:Node
var card:PanelContainer
var chart:Control
var _layers:Array[CanvasLayer]=[]
var heading:="north"
var by_sea:=false
var reach_km:=600.0
var party:=Expedition.PARTY_DEFAULT
var current:Dictionary={}
var _previous_speed:=-1.0
## Set when the quote waits a frame (a land push can take a moment to plan).
var _pending:=false

## Opens the planner on `t` (local_terrain.gd), or brings it back.
static func open(t:Node)->Node:
	if not is_instance_valid(t):return null
	var node:Node=t.get_node_or_null(NODE_NAME)
	if node==null:
		node=load("res://scripts/hud/expedition_planner.gd").new()
		node.name=NODE_NAME
		node.set("terrain",t)
		t.add_child(node)
	return node

func _ready()->void:
	var ink_layer:=CanvasLayer.new(); ink_layer.name="ExpeditionInk"; ink_layer.layer=1; add_child(ink_layer)
	chart=PushChart.new(); chart.set("planner",self); ink_layer.add_child(chart)
	var card_layer:=CanvasLayer.new(); card_layer.name="ExpeditionCard"; card_layer.layer=4; add_child(card_layer)
	card=Kit.panel(T.GOLD,16); card.name="ExpeditionCard"; card_layer.add_child(card)
	_layers=[ink_layer,card_layer]
	if terrain.has_method("_set_game_speed"):
		_previous_speed=float(terrain.get("game_speed"))
		terrain.call("_set_game_speed",0.0)
	var last:Array=Expedition.history()
	if not last.is_empty():heading=String((last[-1] as Dictionary).get("heading",heading))
	if not bool(Expedition.sea_ready().ok):by_sea=false
	requote()

func close()->void:
	if _previous_speed>=0.0 and is_instance_valid(terrain) and terrain.has_method("_set_game_speed"):terrain.call("_set_game_speed",_previous_speed)
	queue_free()

func _unhandled_input(event:InputEvent)->void:
	if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:
		close(); get_viewport().set_input_as_handled()

func _process(_delta:float)->void:
	if is_instance_valid(card):
		card.size=card.get_combined_minimum_size()
		var view:=get_viewport().get_visible_rect().size
		card.position=Vector2(view.x-card.size.x-24.0,clampf((view.y-card.size.y)*0.5,T.CONTENT_TOP+8.0,maxf(T.CONTENT_TOP+8.0,view.y-card.size.y-130.0)))
	if _pending:
		_pending=false
		current=Expedition.quote(heading,reach_km,by_sea,party)
		_frame_the_push()
		_rebuild()
		if is_instance_valid(chart):chart.queue_redraw()

## Quotes again on the next frame (the card first shows it is reckoning).
func requote()->void:
	_pending=true
	_rebuild(true)

func choose(what:String,value:Variant)->void:
	match what:
		"heading":heading=String(value)
		"sea":by_sea=bool(value)
		"reach":reach_km=float(value)
		"party":party=clampi(int(value),Expedition.PARTY_MIN,Expedition.PARTY_MAX)
	requote()

func send()->void:
	var sent:=Expedition.send(heading,reach_km,by_sea,party)
	if sent.has("error"):
		current["blocker"]=String(sent.error);_rebuild();return
	if is_instance_valid(terrain) and terrain.has_method("_refresh_player_scout_route_markers"):terrain.call("_refresh_player_scout_route_markers")
	close()

## Pulls the view out to show home and the far point together.
func _frame_the_push()->void:
	if not is_instance_valid(terrain) or not current.has("route_plan"):return
	var plan:Dictionary=current.route_plan
	if not bool(plan.get("ok",false)):return
	var home:Vector2=current.origin
	var far:=home
	for p:Dictionary in plan.route:
		var at:=Vector2(float(p.x),float(p.z))
		if at.distance_to(home)>far.distance_to(home):far=at
	var middle:=(home+far)*0.5
	# The card covers the map's right; the push sits in the clear part left of it.
	var span:=clampf(maxf(home.distance_to(far),reach_km)*2.4,260.0,9000.0)
	if terrain.has_method("_set_camera_target"):terrain.call("_set_camera_target",Vector3(middle.x+span*0.22,0.0,middle.y))
	terrain.set("zoom_target_size",span)
	terrain.set("zoom_pointer",get_viewport().get_visible_rect().size*0.5)
	terrain.set("zoom_preset_active",true)


# --- The card --------------------------------------------------------------------

func _rebuild(reckoning:=false)->void:
	if not is_instance_valid(card):return
	for child in card.get_children():child.queue_free()
	var column:=VBoxContainer.new(); column.add_theme_constant_override("separation",8); column.custom_minimum_size=Vector2(430,0); card.add_child(column)
	var head:=HBoxContainer.new(); column.add_child(head)
	var titles:=VBoxContainer.new(); titles.size_flags_horizontal=Control.SIZE_EXPAND_FILL; titles.add_theme_constant_override("separation",0); head.add_child(titles)
	Kit.label(titles,"An expedition","kicker")
	Kit.label(titles,"Push into the unknown","title")
	var shut:=Kit.quiet_button(head,"×",close,"Close · Escape"); shut.custom_minimum_size=Vector2(36,36)
	# On foot or by sea.
	var sea:=Expedition.sea_ready()
	var ways:=_row(column,"How")
	_choice(ways,"On foot",not by_sea,func()->void:choose("sea",false))
	var boat:=_choice(ways,"By sea" if not bool(sea.ok) else "By sea · %s" % String(sea.label),by_sea,func()->void:choose("sea",true))
	if not bool(sea.ok):boat.disabled=true;boat.tooltip_text=String(sea.reason)
	# Which way.
	var way:=_row(column,"Which way")
	var grid:=GridContainer.new(); grid.columns=3; grid.add_theme_constant_override("h_separation",4); grid.add_theme_constant_override("v_separation",4); way.add_child(grid)
	for c:Array in COMPASS:
		if String(c[0])=="":
			var mid:=TextureRect.new(); mid.texture=Icons.chart_texture("walker" if not by_sea else "find",INK,40); mid.custom_minimum_size=Vector2(44,32); mid.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; mid.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED; grid.add_child(mid); continue
		var id:=String(c[0])
		var b:=_choice(grid,String(c[1]),heading==id,func()->void:choose("heading",id))
		b.custom_minimum_size=Vector2(48,30); b.tooltip_text=id.capitalize()
	# How far.
	var far:=_row(column,"How far, km")
	var reaches:=HBoxContainer.new(); reaches.add_theme_constant_override("h_separation",4); reaches.add_theme_constant_override("v_separation",4); reaches.size_flags_horizontal=Control.SIZE_EXPAND_FILL; far.add_child(reaches)
	for km:int in Expedition.REACHES:
		var b:=_choice(reaches,_thousands(km),is_equal_approx(reach_km,float(km)),func()->void:choose("reach",km))
		b.tooltip_text="About %d in 100 of such parties come home from %s km out." % [roundi(Expedition.return_chance(float(km),by_sea)*100.0),_thousands(km)]
	# How many.
	var many:=_row(column,"How many")
	var minus:=Kit.button(many,"−",false,func()->void:choose("party",party-(10 if party>30 else 4)))
	minus.custom_minimum_size=Vector2(36,32)
	var count:=Kit.label(many,"%d people" % party,"value",Color(0,0,0,0),false); count.custom_minimum_size=Vector2(96,0); count.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	var plus:=Kit.button(many,"+",false,func()->void:choose("party",party+(10 if party>=30 else 4)))
	plus.custom_minimum_size=Vector2(36,32)
	# What it comes to.
	var facts:=Kit.section(column,12)
	if reckoning or current.is_empty():
		Kit.label(facts,"Reckoning the way…","note")
	elif current.has("km"):
		var chance:=float(current.chance)
		Kit.label(facts,"They push %s km %s%s · about %d days away" % [_thousands(roundi(float(current.km))),String(current.heading),(" (%s)" % String(current.route_plan.get("stopped",""))) if String(current.route_plan.get("stopped",""))!="" and float(current.km)<reach_km*0.8 else "",int(current.days)],"body")
		var odds:=HBoxContainer.new(); odds.add_theme_constant_override("separation",10); facts.add_child(odds)
		var words:=Kit.label(odds,"%d in 100 come home" % roundi(chance*100.0),"heading",_odds_ink(chance),false); words.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
		var bar:=OddsBar.new(); bar.share=chance; bar.ink=_odds_ink(chance); bar.custom_minimum_size=Vector2(120,8); bar.size_flags_horizontal=Control.SIZE_EXPAND_FILL; bar.size_flags_vertical=Control.SIZE_SHRINK_CENTER; odds.add_child(bar)
		if by_sea and float(current.km)<reach_km*0.3:Kit.label(facts,"Our ships find no far shore %s within their range out of sight of land; they would follow our own coast instead." % heading,"note",T.AMBER)
		Kit.label(facts,"Half of such parties come home from %s km out; every %s km more halves it again. Food: %s from our stores." % [_thousands(roundi(float(current.endurance_km))),_thousands(roundi(float(current.endurance_km))),_thousands(ceili(float(current.provisions)))],"note")
		Kit.label(facts,"Home again: country %d km each side of their track is charted and every people they pass is met; about %d of them may die on the way." % [roundi(Expedition.REVEAL_KM),roundi(float(party)*(1.0-chance)*Expedition.ROAD_TOLL)],"note",T.GREEN)
		Kit.label(facts,"Lost: all %d die, and nothing they saw comes back." % party,"note",T.RED)
	if String(current.get("blocker",""))!="":Kit.label(column,String(current.blocker),"body",T.RED)
	var buttons:=HBoxContainer.new(); buttons.add_theme_constant_override("separation",8); column.add_child(buttons)
	var go:=Kit.button(buttons,"Send them",true,send,"Commit the expedition: the food is issued now and they are away until they come home or are given up.")
	go.disabled=reckoning or not bool(current.get("ok",false))
	go.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	Kit.quiet_button(buttons,"Not now",close)
	_away(column)

## Expeditions away, and the last ones home or lost.
func _away(parent:Node)->void:
	var out:=Expedition.away()
	var past:Array=Expedition.history()
	if out.is_empty() and past.is_empty():return
	var box:=Kit.section(parent,10)
	var day:=int(WorldSimulation.state.elapsed_days)
	for m:Dictionary in out:
		var e:Dictionary=m.expedition
		var due:=int(m.get("return_day",day))-day
		Kit.label(box,"Away: %d %s %s, %s km out · %s" % [int(m.personnel),"by sea" if bool(e.by_sea) else "on foot",String(m.get("ordered_heading","")),_thousands(roundi(float(e.km))),("due in %d days" % due) if due>0 else "overdue"],"note")
	for k in range(past.size()-1,maxi(-1,past.size()-3),-1):
		var p:Dictionary=past[k]
		var home:=String(p.outcome)=="home"
		Kit.label(box,"%s %s, %s km: %s" % [Kit.when(int(p.day)),String(p.heading),_thousands(roundi(float(p.km))),("%d came home" % int(p.count)) if home else ("lost, %d dead" % int(p.count))],"note",T.GREEN if home else T.RED)

func _row(parent:Node,caption:String)->HBoxContainer:
	var row:=HBoxContainer.new(); row.add_theme_constant_override("separation",6); parent.add_child(row)
	var label:=Kit.label(row,caption,"kicker",Color(0,0,0,0),false); label.custom_minimum_size=Vector2(78,0); label.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	return row

func _choice(parent:Node,text:String,on:bool,press:Callable)->Button:
	var b:=Kit.button(parent,text,on,press)
	b.custom_minimum_size=Vector2(0,30)
	if on:
		b.add_theme_color_override("font_color",T.GOLD_TEXT)
		b.add_theme_stylebox_override("normal",T.action_button_style(true))
	return b

static func _odds_ink(chance:float)->Color:
	return T.GREEN if chance>=0.66 else (T.AMBER if chance>=0.33 else T.RED)

static func _thousands(value:int)->String:
	var text:=str(value)
	var out:=""
	while text.length()>3:
		out=","+text.substr(text.length()-3)+out
		text=text.substr(0,text.length()-3)
	return text+out


class OddsBar extends Control:
	const T:=preload("res://scripts/hud/hud_tokens.gd")
	var share:=0.0
	var ink:=Color.BLACK
	func _draw()->void:
		draw_rect(Rect2(Vector2.ZERO,size),T.TRACK)
		draw_rect(Rect2(Vector2.ZERO,Vector2(size.x*clampf(share,0.0,1.0),size.y)),ink)


## The push on the chart: rings at each reach lettered with the odds, the
## route inked from home and its far point marked.
class PushChart extends Control:
	const Expedition:=preload("res://scripts/expedition.gd")
	const T:=preload("res://scripts/hud/hud_tokens.gd")
	const Icons:=preload("res://scripts/resource_icons.gd")
	const INK:=Color("#2b2118")
	const PAPER:=Color("#efe3c2")
	const SEA_INK:=Color("#2f5d73")
	var planner:Node
	var _view:=0

	func _ready()->void:
		mouse_filter=Control.MOUSE_FILTER_IGNORE
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	func _camera()->Camera3D:
		var t:Node=planner.get("terrain") if planner!=null else null
		if not is_instance_valid(t):return null
		var c:Variant=t.get("camera")
		return c if is_instance_valid(c) and c is Camera3D else null

	func _process(_delta:float)->void:
		var cam:=_camera()
		if cam==null:return
		var view:=hash([cam.global_transform,cam.size])
		if view!=_view:_view=view;queue_redraw()

	func _screen(p:Vector2)->Vector2:
		var cam:=_camera()
		if cam==null:return Vector2.INF
		var world:=Vector3(p.x,0.0,p.y)
		if cam.is_position_behind(world):return Vector2.INF
		return cam.unproject_position(world)

	func _draw()->void:
		if planner==null:return
		var q:Dictionary=planner.get("current")
		if not q.has("origin"):return
		var home:Vector2=q.origin
		var sea:=bool(planner.get("by_sea"))
		var heading:=String(planner.get("heading"))
		var bearing:=deg_to_rad(float(CivilizationSystem.SCOUT_HEADINGS.get(heading,0.0)))
		var ui:=T.font("ui_strong")
		# The odds rings: an arc a quarter-turn wide about the heading at each reach.
		var taken:Array[Rect2]=[]
		for km:int in Expedition.REACHES:
			var chance:=Expedition.return_chance(float(km),sea)
			var pts:=PackedVector2Array()
			for k in 33:
				var a:=bearing-PI*0.25+PI*0.5*float(k)/32.0
				var s:=_screen(home+Vector2.from_angle(a)*float(km))
				if s.is_finite():pts.append(s)
			if pts.size()<2:continue
			var ink:Color=planner.call("_odds_ink",chance)
			var chosen:=is_equal_approx(float(planner.get("reach_km")),float(km))
			draw_polyline(pts,Color(PAPER,0.6),5.0 if chosen else 3.5,true)
			draw_polyline(pts,Color(ink,0.95 if chosen else 0.6),2.4 if chosen else 1.3,true)
			var tag:="%s km · %d in 100 home" % [planner.call("_thousands",km),roundi(chance*100.0)]
			# Lettered at the arc's end, clear of the route along the heading.
			var at:=pts[0]
			var w:=ui.get_string_size(tag,HORIZONTAL_ALIGNMENT_LEFT,-1,13).x
			var box:=Rect2(at-Vector2(w*0.5+8,24),Vector2(w+16,20))
			# Never over another ring's label: stepped clear of it.
			for guard in 6:
				if not taken.any(func(r:Rect2)->bool:return r.grow(2.0).intersects(box)):break
				box.position.y-=24.0
			taken.append(box)
			draw_style_box(T.flat(Color(PAPER,0.95),Color(ink,0.9),1,3,0),box)
			draw_string(ui,box.position+Vector2(8,14),tag,HORIZONTAL_ALIGNMENT_LEFT,-1,13,T.INK)
		# The route, ink on land and blue at sea, home to the far point.
		var plan:Dictionary=q.get("route_plan",{})
		if not bool(plan.get("ok",false)):return
		var route:Array=plan.route
		var voyage:Dictionary=plan.get("voyage",{})
		var sea_from:=int(voyage.get("sea_start",999)); var sea_to:=int(voyage.get("landing_index",-1))
		var far:=Vector2.INF; var far_km:=-1.0
		for i in range(1,route.size()):
			var a:=Vector2(float(route[i-1].x),float(route[i-1].z)); var b:=Vector2(float(route[i].x),float(route[i].z))
			var sa:=_screen(a); var sb:=_screen(b)
			if not sa.is_finite() or not sb.is_finite():continue
			var wet:=i>sea_from and i<=sea_to
			draw_line(sa,sb,Color(PAPER,0.7),6.0,true)
			_dashed(sa,sb,SEA_INK if wet else INK,2.6)
			if b.distance_to(home)>far_km:far_km=b.distance_to(home);far=b
		var h:=_screen(home)
		if h.is_finite():
			draw_circle(h,7.0,Color(PAPER,0.9));draw_arc(h,7.0,0.0,TAU,24,INK,2.0,true)
		if far.is_finite():
			var sf:=_screen(far)
			if sf.is_finite():
				var glyph:=Icons.chart_texture("find",INK,48)
				draw_texture_rect(glyph,Rect2(sf-Vector2(18,18),Vector2(36,36)),false)

	func _dashed(a:Vector2,b:Vector2,colour:Color,width:float)->void:
		var length:=a.distance_to(b)
		var t:=0.0
		while t<length:
			draw_line(a.lerp(b,t/maxf(length,0.001)),a.lerp(b,minf(t+10.0,length)/maxf(length,0.001)),colour,width,true)
			t+=16.0
