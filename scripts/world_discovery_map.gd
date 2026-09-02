extends Control

signal map_point_selected(civilization_id:String,point_kind:String)

const UNKNOWN:=Color("#050a0b")
const FRAME:=Color("#4f5d58")
const GRID:=Color(0.31,0.39,0.37,0.16)
const CHARTED:=Color(0.31,0.61,0.57,0.20)
const ROUTE:=Color("#79a9a0")
const OLD_ROUTE:=Color(0.40,0.56,0.53,0.48)
const HOME:=Color("#ead08b")
const CONTACT:=Color("#dc9b6e")
const SIGHTING:=Color("#d86e60")

var snapshot:Dictionary={}
var encounter_hits:Array[Dictionary]=[]


func _ready()->void:
	mouse_filter=Control.MOUSE_FILTER_STOP
	clip_contents=true
	resized.connect(queue_redraw)


func set_snapshot(value:Dictionary)->void:
	snapshot=value.duplicate(true)
	queue_redraw()


func _draw()->void:
	var map_rect:=_map_rect()
	draw_rect(Rect2(Vector2.ZERO,size),Color("#081012"),true)
	draw_rect(map_rect,UNKNOWN,true)
	for longitude in range(1,8):
		var x:=map_rect.position.x+map_rect.size.x*float(longitude)/8.0
		draw_line(Vector2(x,map_rect.position.y),Vector2(x,map_rect.end.y),GRID,1.0)
	for latitude in range(1,4):
		var y:=map_rect.position.y+map_rect.size.y*float(latitude)/4.0
		draw_line(Vector2(map_rect.position.x,y),Vector2(map_rect.end.x,y),GRID,1.0)
	draw_rect(map_rect,FRAME,false,1.0)

	for area_variant in snapshot.get("areas",[]):
		var area:Dictionary=area_variant
		var center:=_world_to_map(Vector2(float(area.get("x",0.0)),float(area.get("z",0.0))),map_rect)
		var radius_pixels:=maxf(1.5,float(area.get("radius",1.0))/40075.0*map_rect.size.x)
		draw_circle(center,radius_pixels,CHARTED)

	var reports:Array=snapshot.get("returned_reports",[])
	for report_index in reports.size():
		var report:Dictionary=reports[report_index]
		var route:Array=report.get("route",[])
		if route.size()<2: continue
		var points:=PackedVector2Array()
		for point_variant in route:
			var point:Dictionary=point_variant
			points.append(_world_to_map(Vector2(float(point.get("x",0.0)),float(point.get("z",0.0))),map_rect))
		var route_color:=ROUTE if report_index==0 else OLD_ROUTE
		draw_polyline(points,route_color,2.0 if report_index==0 else 1.0,true)
		for point in points:
			draw_circle(point,2.2 if report_index==0 else 1.4,route_color)

	encounter_hits.clear()
	var encounters:Array=snapshot.get("encounters",[])
	for encounter_variant in encounters:
		var encounter:Dictionary=encounter_variant
		var position:Dictionary=encounter.get("position",{})
		if not position.has("x") or not position.has("z"): continue
		var marker:=_world_to_map(Vector2(float(position.x),float(position.z)),map_rect)
		draw_circle(marker,6.0,Color(CONTACT,0.18))
		draw_arc(marker,5.0,0.0,TAU,20,CONTACT,1.6,true)
		draw_circle(marker,2.0,CONTACT)
		encounter_hits.append({"position":marker,"civilization_id":String(encounter.get("civ_id","")),"name":String(encounter.get("name","CONTACT"))})
		var home:Dictionary=encounter.get("home_position",{}) if bool(encounter.get("home_location_known",false)) else {}
		if home.has("x") and home.has("z"):
			var home_marker:=_world_to_map(Vector2(float(home.x),float(home.z)),map_rect)
			draw_rect(Rect2(home_marker-Vector2(4,4),Vector2(8,8)),HOME,true)
			draw_rect(Rect2(home_marker-Vector2(6,6),Vector2(12,12)),Color(HOME,0.55),false,1.0)
			encounter_hits.append({"position":home_marker,"civilization_id":String(encounter.get("civ_id","")),"name":"%s HOME SETTLEMENT" % String(encounter.get("name","FOREIGN")).to_upper(),"kind":"settlement"})

	for sighting_variant in snapshot.get("visible_formations",[]):
		var sighting:Dictionary=sighting_variant
		var position:Dictionary=sighting.get("position",{})
		if not position.has("x") or not position.has("z"): continue
		var marker:=_world_to_map(Vector2(float(position.x),float(position.z)),map_rect)
		var color:=SIGHTING if bool(sighting.get("hostile",false)) else CONTACT
		var triangle:=PackedVector2Array([marker+Vector2(0,-5),marker+Vector2(5,4),marker+Vector2(-5,4)])
		draw_colored_polygon(triangle,color)

	var origin:Dictionary=snapshot.get("current_origin",{})
	var home:=_world_to_map(Vector2(float(origin.get("x",0.0)),float(origin.get("z",0.0))),map_rect)
	draw_circle(home,7.0,Color(HOME,0.16))
	draw_arc(home,5.0,0.0,TAU,20,HOME,2.0,true)
	draw_circle(home,2.2,HOME)

	var font:=ThemeDB.fallback_font
	var contact_site_count:int=encounters.size()
	var status:="%d RETURNED CHART%s  •  %d CONTACT SITE%s" % [reports.size(),"" if reports.size()==1 else "S",contact_site_count,"" if contact_site_count==1 else "S"]
	draw_string(font,Vector2(map_rect.position.x,map_rect.position.y-7.0),"DISCOVERED WORLD",HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("#c8ad72"))
	draw_string(font,Vector2(map_rect.position.x,map_rect.position.y-7.0),status,HORIZONTAL_ALIGNMENT_RIGHT,map_rect.size.x,10,Color("#8fa19b"))
	draw_string(font,Vector2(map_rect.position.x,map_rect.end.y+16.0),"HOME   •   ROUTE   •   ENCOUNTER   ■ SETTLEMENT   ▲ IN SIGHT",HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("#87958f"))


func _map_rect()->Rect2:
	var outer:=Rect2(Vector2(12,22),Vector2(maxf(1.0,size.x-24.0),maxf(1.0,size.y-44.0)))
	var world_aspect:=40075.0/20004.0
	var target_size:=outer.size
	if target_size.x/target_size.y>world_aspect:
		target_size.x=target_size.y*world_aspect
	else:
		target_size.y=target_size.x/world_aspect
	return Rect2(outer.position+(outer.size-target_size)*0.5,target_size)


func _world_to_map(world_position:Vector2,map_rect:Rect2)->Vector2:
	var world_size:Dictionary=snapshot.get("world_size",{"x":40075.0,"z":20004.0})
	var width:=maxf(1.0,float(world_size.get("x",40075.0)))
	var depth:=maxf(1.0,float(world_size.get("z",20004.0)))
	var normalized:=Vector2(clampf(world_position.x/width+0.5,0.0,1.0),clampf(world_position.y/depth+0.5,0.0,1.0))
	return map_rect.position+normalized*map_rect.size


func _gui_input(event:InputEvent)->void:
	if event is InputEventMouseMotion:
		tooltip_text=""
		for hit in encounter_hits:
			if (hit.position as Vector2).distance_to(event.position)<=9.0:
				tooltip_text="%s — open this confirmed settlement on the main map" % String(hit.name) if String(hit.get("kind","encounter"))=="settlement" else "%s — open the encounter site on the main map" % String(hit.name)
				break
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
		for hit in encounter_hits:
			if (hit.position as Vector2).distance_to(event.position)<=10.0:
				map_point_selected.emit(String(hit.civilization_id),String(hit.get("kind","encounter")))
				accept_event()
				return
