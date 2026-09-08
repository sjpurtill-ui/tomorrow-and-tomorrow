extends Control
const R=preload("res://scripts/joint_regions.gd")
const G=preload("res://scripts/joint_geography.gd")
const Identity=preload("res://scripts/city_map_identity.gd")
signal boundary_feedback(result:Dictionary)
signal region_selected(region:Dictionary)
signal force_selected(id:int)
signal order_region(region:Dictionary)
var domain:String="navy"
var center:=Vector2.ZERO
var spans:Array[float]=[500,1000,4000,16000]
var zoom_level:=1
var selected:Dictionary={}
var selected_force:=0
var terrain:ImageTexture
var terrain_key:=""
var drawing:=false
var draft:Array=[]
var drag:=false
var moved:=false
var op:RefCounted

func _ready()->void:
	op=MilitaryCampaign.joint_operations
	mouse_filter=Control.MOUSE_FILTER_STOP;clip_contents=true
	custom_minimum_size=Vector2(280,280)
func bounds()->Rect2:
	var span:=spans[zoom_level]
	return Rect2(center-Vector2(span,span*size.y/maxf(1,size.x))*.5,Vector2(span,span*size.y/maxf(1,size.x)))
func to_screen(point:Vector2)->Vector2:return (point-bounds().position)/bounds().size*size
func from_screen(point:Vector2)->Vector2:return bounds().position+point/size*bounds().size
func zoom(direction:int)->void:
	zoom_level=clampi(zoom_level+direction,0,spans.size()-1);queue_redraw()
func _gui_input(event:InputEvent)->void:
	if event is InputEventMouseButton:
		if event.button_index==MOUSE_BUTTON_MIDDLE:drag=event.pressed;moved=false;accept_event()
		elif event.button_index==MOUSE_BUTTON_WHEEL_UP and event.pressed:zoom(-1);accept_event()
		elif event.button_index==MOUSE_BUTTON_WHEEL_DOWN and event.pressed:zoom(1);accept_event()
		elif event.pressed and event.button_index in [MOUSE_BUTTON_LEFT,MOUSE_BUTTON_RIGHT]:
			var location:=from_screen(event.position)
			if event.button_index==MOUSE_BUTTON_LEFT and not drawing:
				for force:Dictionary in op.state.forces:
					if force.owner=="player" and force.domain==domain and to_screen(_display_position(force)).distance_to(event.position)<16:
						selected_force=int(force.id);force_selected.emit(selected_force);queue_redraw();accept_event();return
			if drawing:
				if event.button_index==MOUSE_BUTTON_LEFT and draft.size()<R.MAX_VERTICES:draft.append(G.pack(location))
				elif event.button_index==MOUSE_BUTTON_RIGHT and not draft.is_empty():draft.pop_back()
			else:
				for region:Dictionary in op.known_regions(domain):
					if not R.contains(region,location):continue
					selected=region
					if event.button_index==MOUSE_BUTTON_RIGHT:order_region.emit(selected)
					else:region_selected.emit(selected)
					break
			queue_redraw();accept_event()
	elif event is InputEventMouseMotion and drag:
		center-=event.relative/size*bounds().size;moved=true;queue_redraw();accept_event()

func _display_position(force:Dictionary)->Vector2:
	if force.domain=="air" and float(force.efficiency)>0 and not force.region.is_empty():return op.point(force.region)
	return op.force_position(force)
func _draw()->void:
	if op==null or size.x<1 or size.y<1:return
	var rectangle:=bounds()
	var key:="%d:%s:%s" % [GameState.world_seed,str(rectangle),str(size)]
	if key!=terrain_key:
		terrain_key=key
		var raster:=Image.create(72,48,false,Image.FORMAT_RGB8)
		for x in 72:
			for y in 48:
				var land:bool=op.geography.is_land(rectangle.position+Vector2(float(x)/71,float(y)/47)*rectangle.size)
				raster.set_pixel(x,y,Color("253b38") if land else Color("112b3c"))
		terrain=ImageTexture.create_from_image(raster)
	draw_texture_rect(terrain,Rect2(Vector2.ZERO,size),false)
	var font:=ThemeDB.fallback_font
	for region:Dictionary in op.known_regions(domain):
		var points:=PackedVector2Array()
		for vertex:Vector2 in R.polygon(region):points.append(to_screen(vertex))
		if points.size()<3:continue
		var share:float=op.effects.control("player",region)
		draw_colored_polygon(points,Color(.2,.7,.55,.08+share*.15))
		points.append(points[0])
		draw_polyline(points,Color("e6be6a") if region.id==selected.get("id","") else Color(.5,.75,.75,.65),2)
		draw_string(font,to_screen(op.point(region)),String(region.name),HORIZONTAL_ALIGNMENT_LEFT,160,13,Color("d8d4aa"))
	if drawing:
		var points:=PackedVector2Array()
		for vertex:Dictionary in draft:
			var position:=to_screen(G.unpack(vertex));points.append(position);draw_circle(position,4,Color("f1c46b"))
		if points.size()>1:draw_polyline(points,Color("f1c46b"),2)
		if points.size()>2:draw_line(points[-1],points[0],Color(.95,.75,.4,.35),1)

	for city:Dictionary in CivilizationSystem.city_intelligence.known_cities("player","",false):
		var position:=to_screen(op.point(city))
		if not Rect2(Vector2.ZERO,size).has_point(position):continue
		var identity:=Identity.foreign(String(city.get("civ_id","")))
		draw_texture_rect(identity.texture,Rect2(position+Vector2(4,-22),Vector2(24,15)),false)
		draw_circle(position,3,identity.color);draw_string(font,position+Vector2(30,-8),String(city.name),HORIZONTAL_ALIGNMENT_LEFT,160,13,identity.color)
	for base:Dictionary in op.state.bases:
		if base.owner!="player" or base.domain!=domain:continue
		var position:=to_screen(op.point(base))
		draw_rect(Rect2(position-Vector2.ONE*4,Vector2.ONE*8),Color("a3d8d0"))
		draw_string(font,position+Vector2(8,14),String(base.name),HORIZONTAL_ALIGNMENT_LEFT,180,13,Color("bde2d8"))
	for force:Dictionary in op.state.forces:
		if force.owner!="player" or force.domain!=domain:continue
		var position:=to_screen(_display_position(force))
		var previous:=position
		for point:Dictionary in force.get("route",[]):
			var next:=to_screen(G.unpack(point));draw_line(previous,next,Color(.8,.75,.45,.6),2);previous=next
		draw_circle(position,7,Color("f1c46b") if int(force.id)==selected_force else Color("70bbb4"))
		draw_string(font,position+Vector2(10,-7),String(force.name),HORIZONTAL_ALIGNMENT_LEFT,190,14,Color("f1e9d4"))
		draw_string(font,position+Vector2(10,10),"%d %s" % [op.hardware(force),"ships" if domain=="navy" else "aircraft"],HORIZONTAL_ALIGNMENT_LEFT,160,12,Color("b9c6c8"))
	for contact:Dictionary in op.state.contacts.values():
		if contact.observer!="player":continue
		var target:Dictionary=op.force(int(contact.target))
		if target.is_empty() or target.domain!=domain or not contact.has("position"):continue
		var position:=to_screen(G.unpack(contact.position))
		draw_circle(position,6,Color("e7837d"));draw_string(font,position+Vector2(9,0),String(contact.name)+" · report %dd old" % (int(op.state.last_day)-int(contact.day)),HORIZONTAL_ALIGNMENT_LEFT,210,12,Color("efa7a0"))
	for convoy:Dictionary in op.state.convoys:
		if convoy.status not in ["outbound","returning"]:continue
		var force:Dictionary=op.force(int(convoy.force_id))
		if force.is_empty() or force.domain!=domain:continue
		var position:=to_screen(G.unpack(convoy.position));draw_rect(Rect2(position-Vector2.ONE*5,Vector2.ONE*10),Color("ecd9a0"),false,2)
	draw_string(font,Vector2(16,size.y-16),"%.0f km across · four map scales · middle-drag to pan" % spans[zoom_level],HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("aabfc7"))

func begin_boundary()->void:
	drawing=true;draft.clear();queue_redraw()
	boundary_feedback.emit({"ok":true,"message":"Click around the boundary. Right-click undoes a point. Finish saves the area; Cancel discards the outline."})
func cancel_boundary()->void:
	drawing=false;draft.clear();queue_redraw()
func finish_boundary(title:String)->void:
	var result:Dictionary=op.create_region(domain,draft,title)
	boundary_feedback.emit(result)
	if result.has("error"):return
	selected=result.region;region_selected.emit(selected);cancel_boundary()
