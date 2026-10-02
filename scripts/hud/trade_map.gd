extends Node
## THE TRADE MAP: trade between peoples drawn on the map as an inked chart.
## A toggle beside Supply on the map toolbar. When on (the view pulls out to
## the continent):
##   - an inked arc from our home to each people we trade with, one each way,
##     bowed apart: our goods going out in ochre, theirs coming in in teal,
##     its weight by the worth a month (thicker is more), an arrowhead where
##     it arrives, and the mark of the main good at its middle;
##   - an embargo either way as a broken red line with a cross at its middle;
##   - tribute as a dotted gold line toward the people who receives it;
##   - trade between two other peoples whose homes we know, in a thin grey.
## Every line explains itself under the pointer (who, what, how much).
## Positions are only what our people know: a people's reported home, or
## the nearest town of theirs we know. Observe-only: clicks reach the map.

const Ledger:=preload("res://scripts/trade_ledger.gd")
const Stances:=preload("res://scripts/trade_stances.gd")
const Words:=preload("res://scripts/trade_words.gd")
const Icons:=preload("res://scripts/resource_icons.gd")
const Tokens:=preload("res://scripts/hud/hud_tokens.gd")

const NODE_NAME:="TradeMap"
const CONTINENT_LEVEL:=3
const LOOK_EVERY:=0.5
const OUT_INK:=Color("#a8782a")
const IN_INK:=Color("#356f66")
const WAR_INK:=Color("#a8463a")
const TRIBUTE_INK:=Color("#8a6118")
const OTHER_INK:=Color(0.36,0.33,0.29,0.55)

var terrain:Node
var enabled:=false
var layer:CanvasLayer
var chart:Chart
var _look:=LOOK_EVERY
var _key:=-1


static func find(t:Node)->Node:
	return t.get_node_or_null(NODE_NAME) if is_instance_valid(t) else null

static func ensure(t:Node)->Node:
	var node:=find(t)
	if node==null and is_instance_valid(t) and t.is_inside_tree():
		node=load("res://scripts/hud/trade_map.gd").new()
		node.name=NODE_NAME
		node.set("terrain",t)
		t.add_child(node)
	return node

## THE ONE WAY to show or hide the trade map (the toolbar's Trade button follows).
static func set_shown(t:Node,on:=true)->void:
	if not is_instance_valid(t): return
	var hud:Variant=t.get("hud")
	var button:Button=(hud as Node).find_child("ToolbarTrade",true,false) as Button if hud is Node and is_instance_valid(hud) else null
	if button!=null:
		if button.button_pressed!=on: button.button_pressed=on
		return
	var node:=ensure(t)
	if node!=null: node.call("set_enabled",on)

static func is_shown(t:Node)->bool:
	var node:=find(t)
	return node!=null and bool(node.get("enabled"))

## The Trade toggle for the map toolbar (command_rail_hud._build_toolbar).
static func toggle_button(t:Node)->Button:
	var button:=Button.new()
	button.name="ToolbarTrade"
	button.text="Trade"
	button.toggle_mode=true
	button.icon=glyph(Tokens.INK)
	button.add_theme_constant_override("icon_max_width",20)
	button.add_theme_constant_override("h_separation",6)
	button.custom_minimum_size=Vector2(0,32)
	button.add_theme_font_size_override("font_size",16)
	button.add_theme_color_override("font_color",Tokens.BODY)
	button.add_theme_color_override("font_pressed_color",Tokens.GOLD_TEXT)
	button.add_theme_color_override("font_hover_pressed_color",Tokens.GOLD_TEXT)
	button.add_theme_stylebox_override("normal",Tokens.action_button_style(false))
	button.add_theme_stylebox_override("hover",Tokens.action_button_style(false,true))
	button.add_theme_stylebox_override("pressed",Tokens.action_button_style(true))
	button.add_theme_stylebox_override("hover_pressed",Tokens.action_button_style(true,true))
	button.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
	button.tooltip_text="Trade between peoples: our goods out in ochre, theirs in in teal, embargoes broken red."
	button.toggled.connect(func(on:bool)->void:
		var node:=ensure(t)
		if node!=null: node.call("set_enabled",on))
	return button

static var _glyph:Texture2D
## Two arrows passing each other: the toolbar's mark (resource_icons.gd strokes).
static func glyph(ink:Color)->Texture2D:
	if _glyph!=null: return _glyph
	var prims:=[Icons._s(8,20,40,20,4.0,ink),Icons._t(48,20,38,13,38,27,ink),Icons._s(48,36,16,36,4.0,ink),Icons._t(8,36,18,29,18,43,ink)]
	_glyph=ImageTexture.create_from_image(Icons._render(prims,40,false))
	return _glyph


func set_enabled(on:bool)->void:
	enabled=on
	if on:
		_build()
		var camera:Variant=terrain.get("camera") if is_instance_valid(terrain) else null
		if is_instance_valid(camera) and terrain.has_method("set_camera_distance_level") and float(camera.size)<1000.0: terrain.set_camera_distance_level(CONTINENT_LEVEL)
		_key=-1
	if is_instance_valid(layer): layer.visible=on
	if is_instance_valid(chart): chart.set_process(on)

func _build()->void:
	if is_instance_valid(layer): return
	layer=CanvasLayer.new(); layer.name="TradeMapLayer"; layer.layer=-1
	add_child(layer)
	chart=Chart.new(); chart.name="TradeChart"; chart.map=self
	layer.add_child(chart)

func _process(delta:float)->void:
	if not enabled or not is_instance_valid(chart): return
	_look+=delta
	if _look<LOOK_EVERY: return
	_look=0.0
	var key:=hash([int(GameState.elapsed_days),preload("res://scripts/hud/trade_board.gd").reading_signature(),CivilizationSystem.observation_revision])
	if key==_key: return
	_key=key
	chart.lines=collect()


## Where our people know a people lives (km), or INF when they do not.
static func known_home(owner:String)->Vector2:
	if owner=="player": return CivilizationSystem.player_world_origin
	var c:=Ledger.civ(owner)
	if c.is_empty(): return Vector2.INF
	var rel:Dictionary=c.get("player_relation",{})
	if bool(rel.get("home_location_known",false)):
		var at:Dictionary=rel.get("home_position",{}) if rel.get("home_position") is Dictionary else {}
		if at.has("x"): return Vector2(float(at.x),float(at.get("z",0.0)))
	var best:=Vector2.INF
	for city:Dictionary in CivilizationSystem.city_intelligence.known_cities():
		if String(city.get("civ_id",""))!=owner: continue
		var at2:Dictionary=city.get("position",{})
		var point:=Vector2(float(at2.get("x",0.0)),float(at2.get("z",0.0)))
		if best==Vector2.INF or point.distance_squared_to(CivilizationSystem.player_world_origin)<best.distance_squared_to(CivilizationSystem.player_world_origin): best=point
	return best

## Every line to draw: {from, to (km), kind (out|in|embargo|tribute|other),
## width, good, tip}.
static func collect()->Array:
	var out:Array=[]
	var s:=Ledger.peek()
	if s.is_empty(): return out
	var top:=0.001
	for p:Dictionary in (s.get("pairs",{}) as Dictionary).values():
		top=maxf(top,maxf(float((p.get("val",{}) as Dictionary).get("ab",0.0)),float((p.get("val",{}) as Dictionary).get("ba",0.0))))
	for p:Dictionary in (s.get("pairs",{}) as Dictionary).values():
		var a:=String(p.get("a","")); var b:=String(p.get("b",""))
		var ours:=a=="player" or b=="player"
		var here:=known_home(a); var there:=known_home(b)
		if here==Vector2.INF or there==Vector2.INF: continue
		var embargo:=Stances.embargo_between(a,b)
		if embargo!="":
			var who:=embargo.get_slice(":",1)
			out.append({"from":here,"to":there,"kind":"embargo","width":2.0,"good":"","tip":"%s embargoes %s: nothing passes." % [Ledger.name_of(who),Ledger.name_of(b if who==a else a)]})
			continue
		for dir:Array in [["ab",a,b,here,there],["ba",b,a,there,here]]:
			var value:=float((p.get("val",{}) as Dictionary).get(String(dir[0]),0.0))
			if value<Ledger.PARTNER_FLOOR*0.5: continue
			var from:=String(dir[1]); var to:=String(dir[2])
			var items:=Words.flow_items(from,to,2)
			var kind:="other"
			if ours: kind="out" if from=="player" else "in"
			out.append({"from":dir[3],"to":dir[4],"kind":kind,"width":1.2+4.8*log(1.0+value)/log(1.0+top),"good":String(items[0][0]) if not items.is_empty() else "",
				"tip":"%s to %s: %s." % [Ledger.name_of(from),Ledger.name_of(to),Words.flow_words(from,to)]})
	for k:String in (s.get("tributes",{}) as Dictionary):
		var payer:=k.get_slice(">",0); var payee:=k.get_slice(">",1)
		var from2:=known_home(payer); var to2:=known_home(payee)
		if from2==Vector2.INF or to2==Vector2.INF: continue
		out.append({"from":from2,"to":to2,"kind":"tribute","width":2.0,"good":"","tip":"%s pays %s tribute worth %s a season." % [Ledger.name_of(payer),Ledger.name_of(payee),Words.qty(float((s.tributes[k] as Dictionary).get("value",0.0)))]})
	return out


## The chart itself: draws the lines over the map, under the town names.
class Chart extends Control:
	const Icons:=preload("res://scripts/resource_icons.gd")
	const Tokens:=preload("res://scripts/hud/hud_tokens.gd")
	var map:Node
	var lines:Array=[]:
		set(value):
			lines=value
			queue_redraw()
	var hover:=-1
	var _screen:Array=[]
	var _view:=-1

	func _ready()->void:
		mouse_filter=Control.MOUSE_FILTER_IGNORE
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	func _camera()->Camera3D:
		var t:Variant=map.get("terrain") if map!=null else null
		if not is_instance_valid(t): return null
		var camera:Variant=(t as Node).get("camera")
		return camera if is_instance_valid(camera) and camera is Camera3D else null

	func _process(_delta:float)->void:
		var camera:=_camera()
		if camera==null: return
		var view:=hash([camera.global_transform,camera.size,get_viewport_rect().size,lines.size(),hover])
		if view==_view: return
		_view=view
		_project(camera)
		queue_redraw()

	func _point(camera:Camera3D,at:Vector2)->Vector2:
		var t:Node=map.get("terrain")
		var height:=float(t.call("_height_at",at.x,at.y)) if t.has_method("_height_at") else 0.0
		return camera.unproject_position(Vector3(at.x,height+0.01,at.y))

	func _project(camera:Camera3D)->void:
		_screen.clear()
		for line:Dictionary in lines:
			var a:=_point(camera,line.from); var b:=_point(camera,line.to)
			var bow:=0.0
			match String(line.kind):
				"out": bow=0.16
				"in": bow=-0.16
				"other": bow=0.10
				"tribute": bow=0.24
			var mid:=(a+b)*0.5
			var normal:=(b-a).orthogonal().normalized()
			var control:=mid+normal*(a.distance_to(b)*bow)
			var points:=PackedVector2Array()
			for i in 25:
				var u:=float(i)/24.0
				points.append(a.lerp(control,u).lerp(control.lerp(b,u),u))
			_screen.append({"line":line,"points":points,"mid":points[12]})

	func _input(event:InputEvent)->void:
		if not is_visible_in_tree() or not (event is InputEventMouseMotion): return
		var best:=-1; var nearest:=12.0
		for i in _screen.size():
			var points:PackedVector2Array=_screen[i].points
			for j in range(0,points.size()-1,2):
				var d:=Geometry2D.get_closest_point_to_segment(event.position,points[j],points[j+1]).distance_to(event.position)
				if d<nearest: nearest=d; best=i
		if best!=hover: hover=best; _view=-1

	func _draw()->void:
		for entry:Dictionary in _screen:
			var line:Dictionary=entry.line
			var points:PackedVector2Array=entry.points
			var kind:=String(line.kind)
			var ink:Color={"out":Color("#a8782a"),"in":Color("#356f66"),"embargo":Color("#a8463a"),"tribute":Color("#8a6118"),"other":Color(0.36,0.33,0.29,0.55)}.get(kind,Color.BLACK)
			var width:=float(line.width)
			# A soft paper halo under every stroke: ink on a chart, not a laser.
			draw_polyline(points,Color(0.95,0.91,0.80,0.55),width+3.0,true)
			match kind:
				"embargo":
					for i in range(0,points.size()-1,2): draw_line(points[i],points[i+1],ink,width,true)
					var m:Vector2=entry.mid
					draw_line(m+Vector2(-6,-6),m+Vector2(6,6),ink,2.5,true); draw_line(m+Vector2(-6,6),m+Vector2(6,-6),ink,2.5,true)
				"tribute":
					for i in range(0,points.size(),2): draw_circle(points[i],width*0.9,ink)
				_:
					draw_polyline(points,ink,width,true)
					var tip:=points[points.size()-1]; var back:=points[points.size()-3]
					var dir:=(tip-back).normalized(); var side:=dir.orthogonal()
					var head:=6.0+width*1.5
					draw_colored_polygon(PackedVector2Array([tip,tip-dir*head+side*head*0.55,tip-dir*head-side*head*0.55]),ink)
			if String(line.get("good",""))!="":
				var mark:=Icons.texture_for(String(line.good))
				draw_texture_rect(mark,Rect2(Vector2(entry.mid)-Vector2(10,10),Vector2(20,20)),false)
		if hover>=0 and hover<_screen.size():
			var text:=String((_screen[hover].line as Dictionary).get("tip",""))
			var font:=ThemeDB.fallback_font
			var size_:=font.get_multiline_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,300,13)+Vector2(20,14)
			var at:Vector2=(_screen[hover].mid as Vector2)+Vector2(14,14)
			at.x=clampf(at.x,8,maxf(8,size.x-size_.x-8)); at.y=clampf(at.y,8,maxf(8,size.y-size_.y-8))
			draw_style_box(Tokens.flat(Tokens.PANEL_BG_SOLID,Color(0.4,0.35,0.28,0.8),1,5,0),Rect2(at,size_))
			draw_multiline_string(font,at+Vector2(10,7+font.get_ascent(13)),text,HORIZONTAL_ALIGNMENT_LEFT,300,13,-1,Tokens.INK)
