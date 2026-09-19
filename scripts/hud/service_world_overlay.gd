extends Control
## Transparent military annotation of the actual world; owns no map or camera.
signal region_selected(region:Dictionary)
signal force_selected(id:int)
signal base_selected(id:int)
signal order_region(region:Dictionary)
signal boundary_feedback(result:Dictionary)
const R=preload("res://scripts/joint_regions.gd")
const T=preload("res://scripts/hud/hud_tokens.gd")
var terrain:Node
var domain:="navy"
var selected:Dictionary={}
var selected_force:=0
var drawing:=false
var vertices:Array=[]
var op:RefCounted
var ground_cache:Dictionary={}

func _ready()->void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	clip_contents=true
	op=MilitaryCampaign.joint_operations

func begin_boundary()->void:
	drawing=true;vertices.clear();queue_redraw()
func cancel_boundary()->void:
	drawing=false;vertices.clear();queue_redraw()
func undo_vertex()->void:
	if not vertices.is_empty():vertices.pop_back();queue_redraw()
func finish_boundary(title:String)->void:
	if not drawing:return
	var result:Dictionary=MilitaryCampaign.command_hierarchy.create_region(domain,vertices,title)
	if result.has("ok"):
		selected=result.region;cancel_boundary();region_selected.emit(selected)
	boundary_feedback.emit(result)

func world_to_screen(point:Vector2)->Vector2:
	if not is_instance_valid(terrain) or terrain.camera==null:return Vector2(INF,INF)
	if not ground_cache.has(point):
		if ground_cache.size()>4096:ground_cache.clear()
		ground_cache[point]=terrain._height_at(point.x,point.y)
	var world:=Vector3(point.x,float(ground_cache[point])+0.001,point.y)
	if terrain.camera.is_position_behind(world):return Vector2(INF,INF)
	return terrain.camera.unproject_position(world)

func force_screen_position(force:Dictionary)->Vector2:
	# Deck wings follow their carrier in the simulation; their stored position
	# is only updated during independent travel. Render and picking share this.
	return world_to_screen(op.force_position(force))
func army_report(force:Dictionary)->Dictionary:
	return force if MilitaryCampaign._army_is_home(force) or MilitaryCampaign._live_army_reporting() else force.get("last_report",{})

func screen_to_world(point:Vector2)->Dictionary:
	if not is_instance_valid(terrain):return {}
	var hit:Dictionary=terrain._terrain_hit(point)
	if hit.is_empty():return {}
	return {"x":float(hit.position.x),"z":float(hit.position.z)}

func handle_map_input(event:InputEvent)->bool:
	if not (event is InputEventMouseButton) or not event.pressed:return false
	if event.button_index not in [MOUSE_BUTTON_LEFT,MOUSE_BUTTON_RIGHT]:return false
	# Called only after GUI has refused the event; never steals panel clicks.
	if drawing:
		if event.button_index==MOUSE_BUTTON_RIGHT:undo_vertex();return true
		var vertex:=screen_to_world(event.position)
		if vertex.is_empty():return true
		if vertices.size()>=64:boundary_feedback.emit({"error":"A boundary can contain at most 64 points."});return true
		if vertices.is_empty() or Vector2(vertex.x,vertex.z).distance_to(Vector2(vertices[-1].x,vertices[-1].z))>.001:vertices.append(vertex)
		queue_redraw();return true
	if event.button_index==MOUSE_BUTTON_LEFT:
		if domain=="army":
			for force:Dictionary in MilitaryCampaign.field_armies:
				var shown:=army_report(force)
				if not shown.get("position",{}).is_empty() and world_to_screen(op.point(shown)).distance_to(event.position)<18:
					selected_force=int(force.army_id);force_selected.emit(selected_force);return true
		for force:Dictionary in op.state.forces:
			if force.owner=="player" and force.domain==domain and force_screen_position(force).distance_to(event.position)<18:
				selected_force=int(force.id);force_selected.emit(selected_force);return true
		for base:Dictionary in op.state.bases:
			if base.owner=="player" and base.domain==domain and world_to_screen(op.point(base)).distance_to(event.position)<18:
				base_selected.emit(int(base.id));return true
	var hit:=screen_to_world(event.position)
	if not hit.is_empty():
		for region:Dictionary in MilitaryCampaign.command_hierarchy.known_regions(domain):
			if R.contains(region,Vector2(hit.x,hit.z)):
				selected=region;region_selected.emit(region)
				if event.button_index==MOUSE_BUTTON_RIGHT:order_region.emit(region)
				return true
	# Bare-map clicks are handled by the terrain controller as dismissal.
	return false

func _process(_delta:float)->void:
	queue_redraw()

func _line(points:Array,color:Color,closed:bool=false)->void:
	if points.size()<2:return
	for i in points.size() if closed else points.size()-1:
		var a:=world_to_screen(Vector2(points[i].x,points[i].z))
		var b:=world_to_screen(Vector2(points[(i+1)%points.size()].x,points[(i+1)%points.size()].z))
		if a.is_finite() and b.is_finite():draw_line(a,b,color,2,true)

func _caption(point:Vector2,title:String,color:Color)->void:
	if not point.is_finite() or not Rect2(Vector2.ZERO,size).grow(50).has_point(point):return
	var font:=ThemeDB.fallback_font
	var width:=minf(280,font.get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,14).x)
	draw_style_box(_label_style(),Rect2(point+Vector2(10,-19),Vector2(width+12,23)))
	draw_string(font,point+Vector2(16,-2),title,HORIZONTAL_ALIGNMENT_LEFT,width,14,T.INK)

func _label_style()->StyleBoxFlat:
	return T.flat(T.MAP_LABEL_BG,T.BORDER_SOFT,1,3,2)

func _draw()->void:
	if op==null or not is_instance_valid(terrain) or terrain.camera==null:return
	var color:=Color("ddbc78") if domain=="army" else Color("64bcd9") if domain=="navy" else Color("b8d68c")
	for region:Dictionary in MilitaryCampaign.command_hierarchy.known_regions(domain):
		var active:bool=String(region.id)==String(selected.get("id",""))
		var fill:=PackedVector2Array()
		for vertex:Dictionary in region.vertices:
			var projected:=world_to_screen(Vector2(vertex.x,vertex.z))
			if not projected.is_finite():fill.clear();break
			fill.append(projected)
		if fill.size()>=3 and not Geometry2D.triangulate_polygon(fill).is_empty():draw_colored_polygon(fill,Color(Color("ffd477") if active else color,.10 if active else .025))
		_line(region.vertices,Color("ffd477") if active else color,true)
		_caption(world_to_screen(op.point(region)),String(region.name),Color("ffd477") if active else color)
	if drawing:
		_line(vertices,Color("ffd477"))
		for point:Dictionary in vertices:
			var projected:=world_to_screen(Vector2(point.x,point.z))
			if projected.is_finite():draw_circle(projected,4,Color("ffd477"))
		if not vertices.is_empty():
			var a:=world_to_screen(Vector2(vertices[-1].x,vertices[-1].z))
			if a.is_finite():draw_line(a,get_local_mouse_position(),Color(1,.83,.46,.55),1,true)
	if domain=="army":_draw_land();return
	for base:Dictionary in op.state.bases:
		if base.owner!="player" or base.domain!=domain:continue
		var at:=world_to_screen(op.point(base))
		if not at.is_finite():continue
		draw_rect(Rect2(at-Vector2(6,6),Vector2(12,12)),color,false,2)
		_caption(at+Vector2(0,20),String(base.name),color)
	for force:Dictionary in op.state.forces:
		if force.owner!="player" or force.domain!=domain:continue
		var at:=force_screen_position(force)
		if not at.is_finite():continue
		var chosen:bool=int(force.id)==selected_force
		draw_circle(at,8 if chosen else 5,Color("ffd477") if chosen else color)
		_caption(at,String(force.name)+" · "+str(op.hardware(force)),color)
		if chosen:
			var location:Vector2=op.force_position(force)
			var route:Array=[{"x":location.x,"z":location.y}];route.append_array(force.get("route",[]));_line(route,color)
			if domain=="air":
				var origin:Dictionary=op.force(int(force.get("carrier_id",0)))
				if origin.is_empty():origin=op.base(int(force.base_id))
				var center:Vector2=op.point(origin)
				var reach:float=op.range_km(force)
				var ring:Array=[]
				for i in 64:
					var point:=center+Vector2.from_angle(TAU*i/64.0)*reach
					ring.append({"x":point.x,"z":point.y})
				_line(ring,Color(color,.35),true)
				if not force.get("region",{}).is_empty():_line([origin.position,force.region.position],color)
	for contact:Dictionary in op.state.contacts.values():
		if contact.get("domain","")!=domain or contact.get("observer","")!="player":continue
		var at:=world_to_screen(op.point(contact))
		if at.is_finite():
			draw_circle(at,6,Color("ed927d"),false,2)
			_caption(at,"Last sighting · "+String(contact.get("name","Contact")),Color("ed927d"))

func _draw_land()->void:
	var command=MilitaryCampaign.command_hierarchy
	for claim:Dictionary in command.land.claims:
		if claim.owner!="player" and CivilizationSystem.city_intelligence.known("player",String(claim.city_id)).is_empty():continue
		var boundary:Array=[]
		for vertex:Vector2 in claim.boundary:boundary.append({"x":vertex.x,"z":vertex.y})
		_line(boundary,Color("849e82") if claim.owner=="player" else Color("a77971") if command.land.hostile(String(claim.owner)) else Color("888b90"),true)
	for front:Dictionary in command.data.fronts:
		_line(front.points,Color("ed806e"))
		if front.zone_id==selected.get("id",""):
			_caption(world_to_screen(op.point({"position":front.points[1]})),"Front · %d%% escape routes covered" % roundi(float(front.encirclement)*100),Color("ed806e"))
	for actual:Dictionary in MilitaryCampaign.field_armies:
		if int(actual.get("troops",0))<=0:continue
		var shown:=army_report(actual)
		if shown.get("position",{}).is_empty():continue
		var at:=world_to_screen(op.point(shown))
		if not at.is_finite():continue
		var chosen:bool=int(actual.army_id)==selected_force
		var color:=Color("ffd477") if chosen else Color("b9cba0")
		draw_rect(Rect2(at-Vector2(9,6),Vector2(18,12)),Color("0f211e"));draw_rect(Rect2(at-Vector2(9,6),Vector2(18,12)),color,false,2)
		_caption(at,String(actual.name)+" · "+str(shown.get("troops",0)),color)
		if chosen:
			var route:Array=[shown.position];route.append_array(shown.get("command_route",[]));_line(route,Color(color,.65))
