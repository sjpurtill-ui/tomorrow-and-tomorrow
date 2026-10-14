extends Node
## WORLD › EXPEDITIONS ON THE MAP: while the Expeditions tab is open, the map
## itself shows where our scouts have been and are: the routes of the latest
## tellings inked from home (gold while unread, red where some were lost),
## each party away along its road with a dot where it should be by now, and
## the finds that have a place, marked with the chart's glyphs. Only what
## came home is drawn (returned routes, returned finds); a party's dot is the
## planned journey's share, never live knowledge.
##
## The overlay lives on the terrain (one node) and hides itself whenever the
## tab is not the one showing. The first time the tab opens, the view pulls
## out to frame home and the routes in the clear part of the map.

const T:=preload("res://scripts/hud/hud_tokens.gd")
const Icons:=preload("res://scripts/resource_icons.gd")
const Archive:=preload("res://scripts/scout_archive.gd")
const NODE_NAME:="ExpeditionRoutes"
const ROUTES:=14
const FINDS:=24

var terrain:Node
var hud:Node
var layer:CanvasLayer
var ink:Control
var _shown:=false
var _framed:=false

## The overlay on `t` (local_terrain.gd), made once.
static func ensure(t:Node,h:Node)->Node:
	if not is_instance_valid(t):return null
	var node:Node=t.get_node_or_null(NODE_NAME)
	if node==null:
		node=load("res://scripts/hud/expedition_routes_overlay.gd").new()
		node.name=NODE_NAME
		node.set("terrain",t);node.set("hud",h)
		t.add_child(node)
	return node

func _ready()->void:
	layer=CanvasLayer.new();layer.name="ExpeditionRoutesInk";layer.layer=1;add_child(layer)
	ink=Ink.new();ink.set("overlay",self);layer.add_child(ink)
	layer.visible=false

## Whether World › Expeditions is the page on show.
func tab_open()->bool:
	if not is_instance_valid(hud):return false
	var dock:Variant=hud.get("dock")
	if not dock is Control or not (dock as Control).visible:return false
	var provider:Variant=(dock as Control).get("provider")
	if provider==null or not provider is Object:return false
	var script:Variant=(provider as Object).get_script()
	if script==null or not String((script as Script).resource_path).ends_with("dock_content_world.gd"):return false
	return int((dock as Control).get("sub"))==1

func _process(_delta:float)->void:
	var open:=tab_open()
	if open!=_shown:
		_shown=open
		layer.visible=open
		if open and not _framed:
			_framed=true
			frame()
	if open:ink.queue_redraw()
	elif _framed and not is_instance_valid(hud):queue_free()

## Pulls the view out to show home and the routes beside the open page.
func frame()->void:
	if not is_instance_valid(terrain):return
	var home:Vector2=CivilizationSystem.player_world_origin
	var reach:=0.0
	for route:Array in routes():
		for p:Vector2 in route[0]:reach=maxf(reach,p.distance_to(home))
	if reach<=0.0:return
	var span:=clampf(reach*2.6,260.0,9000.0)
	var right:Vector3=terrain.call("_camera_ground_screen_right") if terrain.has_method("_camera_ground_screen_right") else Vector3.RIGHT
	# The page covers the map's left; home sits in the middle of what is left.
	var at:=Vector3(home.x,0.0,home.y)-right*span*0.28
	if terrain.has_method("_set_camera_target"):terrain.call("_set_camera_target",at)
	terrain.set("zoom_target_size",span)

## The routes drawn: [[points, return points, tone]] newest first.
func routes()->Array:
	var out:Array=[]
	var World:=preload("res://scripts/hud/content/dock_content_world.gd")
	for report:Dictionary in CivilizationSystem.scout_reports.slice(0,ROUTES):
		var line:=World.points(report.get("route",[]))
		if line.size()<2:continue
		var tone:="read"
		if int(report.get("lost_personnel",0))>0:tone="lost"
		elif report.has("archive_reviewed") and not bool(report.archive_reviewed):tone="unread"
		out.append([line,World.points(report.get("return_route",[])),tone])
	return out

## Returned finds that have a place: [[point, glyph, title]].
func finds()->Array:
	var out:Array=[]
	for report:Dictionary in CivilizationSystem.scout_reports:
		for card:Dictionary in Archive.significant_findings(report):
			var at:=preload("res://scripts/hud/content/dock_content_world.gd").vec(card.get("position",{}))
			if at==Vector2.INF:continue
			out.append([at,"sighting" if String(card.get("kind",""))=="intelligence" else "find",String(card.get("title",""))])
			if out.size()>=FINDS:return out
	return out

## Parties away: [[route points, progress 0..1, late]].
func parties()->Array:
	var out:Array=[]
	var status:Dictionary={}
	for party:Dictionary in CivilizationSystem.exploration_status().get("parties",[]):status[int(party.get("mission_id",0))]=party
	var World:=preload("res://scripts/hud/content/dock_content_world.gd")
	for mission:Dictionary in CivilizationSystem.scout_missions:
		var line:=World.points(mission.get("route",[]))
		if line.size()<2:continue
		var s:Dictionary=status.get(int(mission.get("mission_id",0)),{})
		out.append([line,float(s.get("progress",0.0)),int(s.get("overdue_days",0))>0])
	return out


class Ink extends Control:
	const T:=preload("res://scripts/hud/hud_tokens.gd")
	const Icons:=preload("res://scripts/resource_icons.gd")
	const PAPER:=Color("#efe3c2")
	const INK:=Color("#2b2118")
	var overlay:Node

	func _ready()->void:
		mouse_filter=Control.MOUSE_FILTER_IGNORE
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	func _camera()->Camera3D:
		var t:Node=overlay.get("terrain") if overlay!=null else null
		if not is_instance_valid(t):return null
		var c:Variant=t.get("camera")
		return c if is_instance_valid(c) and c is Camera3D else null

	func _screen(p:Vector2)->Vector2:
		var cam:=_camera()
		if cam==null:return Vector2.INF
		var world:=Vector3(p.x,0.0,p.y)
		if cam.is_position_behind(world):return Vector2.INF
		return cam.unproject_position(world)

	func _polyline(points:PackedVector2Array,colour:Color,width:float,dashed:bool)->void:
		for i in range(1,points.size()):
			var a:=_screen(points[i-1]);var b:=_screen(points[i])
			if not a.is_finite() or not b.is_finite():continue
			draw_line(a,b,Color(PAPER,0.55),width+3.0,true)
			if not dashed:draw_line(a,b,colour,width,true);continue
			var length:=a.distance_to(b);var t:=0.0
			while t<length:
				draw_line(a.lerp(b,t/maxf(length,0.001)),a.lerp(b,minf(t+8.0,length)/maxf(length,0.001)),colour,width,true)
				t+=13.0

	func _draw()->void:
		if overlay==null:return
		for route:Array in overlay.routes():
			var tone:=String(route[2])
			var colour:Color={"unread":T.GOLD,"lost":T.RED}.get(tone,Color(INK,0.55))
			_polyline(route[0],colour,2.2 if tone!="read" else 1.4,false)
			if (route[1] as PackedVector2Array).size()>=2:_polyline(route[1],Color(colour,0.6),1.2,true)
		for party:Array in overlay.parties():
			var line:PackedVector2Array=party[0]
			_polyline(line,T.TEAL,2.4,true)
			var at:=_along(line,float(party[1]))
			var s:=_screen(at)
			if s.is_finite():
				draw_circle(s,7.0,PAPER);draw_circle(s,5.0,T.AMBER if bool(party[2]) else T.TEAL)
		for find:Array in overlay.finds():
			var s:=_screen(find[0])
			if not s.is_finite() or not get_viewport_rect().has_point(s):continue
			var glyph:=Icons.chart_texture(String(find[1]),INK,40)
			draw_texture_rect(glyph,Rect2(s-Vector2(11,11),Vector2(22,22)),false)
		var home:=_screen(CivilizationSystem.player_world_origin)
		if home.is_finite():
			draw_circle(home,8.0,Color(PAPER,0.95));draw_arc(home,8.0,0.0,TAU,24,INK,2.0,true);draw_circle(home,3.0,T.GOLD)

	## The point a share of the way along a line.
	static func _along(line:PackedVector2Array,share:float)->Vector2:
		var total:=0.0
		for i in range(1,line.size()):total+=line[i-1].distance_to(line[i])
		var want:=total*clampf(share,0.0,1.0)
		for i in range(1,line.size()):
			var step:=line[i-1].distance_to(line[i])
			if want<=step:return line[i-1].lerp(line[i],want/maxf(step,0.001))
			want-=step
		return line[line.size()-1]
