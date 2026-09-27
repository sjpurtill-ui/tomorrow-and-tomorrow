extends Control
const Art=preload("res://scripts/hud/research_visuals.gd")
const T=preload("res://scripts/hud/hud_tokens.gd")
const UI_FONT:=preload("res://assets/fonts/battle/Barlow-Medium.ttf")
# Illustrated nodes show the visible frontier; unknown outcomes stay unnamed.
const CARD:=Vector2(280,232)
## The painting band across the top of a node: 3:1, close to the wide banner
## paintings, so they lose little; older plates are cropped around their focus.
const IMAGE:=Vector2(252,84)
const IMAGE_SHIFT:=IMAGE.y-72.0
var owner_view:Control
var boxes:Dictionary={}
var center:=Vector2.ZERO
var zoom_level:=1.0
var dragging:=false
var press:=Vector2.ZERO
var moved:=false
func _ready()->void:
	clip_contents=true;mouse_default_cursor_shape=Control.CURSOR_DRAG;focus_mode=Control.FOCUS_ALL
	resized.connect(fit)
func arrange()->void:
	boxes.clear();var depths:Dictionary={};var rows:Dictionary={}
	for item:Dictionary in owner_view.records:depths[item.id]=0
	for iteration in 24:
		var changed:=false
		for item:Dictionary in owner_view.records:
			var depth:=0
			for req:String in owner_view._tree_parents(item):
				if depths.has(req):depth=maxi(depth,mini(24,int(depths[req])+1))
			if depths[item.id]!=depth:depths[item.id]=depth;changed=true
		if not changed:break
	for item:Dictionary in owner_view.records:
		var col:=int(depths[item.id]);var row:=int(rows.get(col,0));rows[col]=row+1
		boxes[item.id]=Rect2(Vector2(col*344,row*258),CARD)
	queue_redraw()
func fit()->void:
	if boxes.is_empty():return
	var bounds:Rect2=boxes.values()[0]
	for rect:Rect2 in boxes.values():bounds=bounds.merge(rect)
	zoom_level=clampf(minf(size.x/(bounds.size.x+60),size.y/(bounds.size.y+60)),.85,1.2)
	center=bounds.get_center()
	# Keep the beginning visible when a readable graph is taller than its pane.
	if bounds.size.y*zoom_level>size.y-48:center.y=bounds.position.y+size.y/(2*zoom_level)-24/zoom_level
	if bounds.size.x*zoom_level>size.x-48:center.x=bounds.position.x+size.x/(2*zoom_level)-24/zoom_level
	queue_redraw()
func at(point:Vector2)->Vector2:return (point-center)*zoom_level+size*.5
func zoom_at(factor:float,anchor:Vector2)->void:
	var world:Vector2=(anchor-size*.5)/zoom_level+center;zoom_level=clampf(zoom_level*factor,.35,1.65);center=world-(anchor-size*.5)/zoom_level;queue_redraw()
func center_selected()->void:
	if boxes.has(owner_view.selected_id):center=boxes[owner_view.selected_id].get_center();zoom_level=maxf(.85,zoom_level);queue_redraw()
func _gui_input(event:InputEvent)->void:
	if event is InputEventPanGesture:center+=event.delta*24/zoom_level;queue_redraw();accept_event()
	elif event is InputEventMagnifyGesture:zoom_at(event.factor,event.position);accept_event()
	elif event is InputEventMouseButton:
		if event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN] and event.pressed:zoom_at(1.1 if event.button_index==MOUSE_BUTTON_WHEEL_UP else 1/1.1,event.position);accept_event()
		elif event.button_index==MOUSE_BUTTON_LEFT:
			if event.pressed:dragging=true;press=event.position;moved=false;grab_focus()
			else:
				dragging=false
				if not moved:
					var world:Vector2=(event.position-size*.5)/zoom_level+center
					for id:String in boxes:
						if boxes[id].has_point(world):owner_view.select(id,true);break
			accept_event()
	elif event is InputEventMouseMotion and dragging:center-=event.relative/zoom_level;moved=moved or event.position.distance_to(press)>4;queue_redraw();accept_event()
	elif event is InputEventKey and event.pressed and event.keycode in [KEY_RIGHT,KEY_LEFT]:owner_view.step(1 if event.keycode==KEY_RIGHT else -1);accept_event()
## Smallest drawn text, whatever the zoom (ART_DIRECTION type floor).
const MIN_TEXT:=12
## Below this zoom a node shows only its name: smaller text would be unreadable.
const DETAIL_ZOOM:=0.85
func words(text:String,point:Vector2,font:int,color:Color,width:float=CARD.x-22)->void:
	# Text is never drawn under 12 px; it is trimmed to the node's drawn width.
	var size:=maxi(MIN_TEXT,roundi(font*zoom_level))
	var room:=width*zoom_level
	var shown:=text
	while shown.length()>2 and UI_FONT.get_string_size(shown,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x>room:shown=shown.left(-2)
	if shown!=text:shown=shown.trim_suffix(" ")+"…"
	draw_string(UI_FONT,at(point),shown,HORIZONTAL_ALIGNMENT_LEFT,room,size,color)
func _draw()->void:
	draw_rect(Rect2(Vector2.ZERO,size),T.FIELD_BG)
	# Every required foundation.
	for item:Dictionary in owner_view.records:
		for req in item.requires:
			if not boxes.has(req):continue
			var a:Vector2=boxes[req].position+Vector2(CARD.x,CARD.y*.5);var b:Vector2=boxes[item.id].position+Vector2(0,CARD.y*.5)
			var selected:bool=item.id==owner_view.selected_id or req==owner_view.selected_id
			var color:=T.GOLD if selected else T.BORDER_2
			var midway:=(a.x+b.x)*.5
			draw_polyline(PackedVector2Array([at(a),at(Vector2(midway,a.y)),at(Vector2(midway,b.y)),at(b)]),color,maxf(1,zoom_level*2),true)
			draw_circle(at(b),3*zoom_level,color)
	# Choice forks: any one member of a group may satisfy this part of the path.
	for item:Dictionary in owner_view.records:
		for group:Array in item.get("requires_any",[]):
			for req:String in group:
				if not boxes.has(req):continue
				var a:Vector2=boxes[req].position+Vector2(CARD.x,CARD.y*.5);var b:Vector2=boxes[item.id].position+Vector2(0,CARD.y*.5)
				var selected:bool=item.id==owner_view.selected_id or req==owner_view.selected_id
				var color:=T.GOLD if selected else T.TEAL
				draw_dashed_line(at(a),at(b),color,maxf(1,zoom_level*1.5),6*zoom_level)
				draw_circle(at(b),4*zoom_level,color,false,maxf(1,zoom_level))
	# Authored alternate inquiry approaches, distinct from prerequisite choices.
	for item:Dictionary in owner_view.records:
		for pathway:Dictionary in item.get("pathways",[]):
			for req:String in preload("res://scripts/technology_requirements.gd").parents(pathway):
				var choice_parent:=false
				for group:Array in item.get("requires_any",[]):
					if req in group:choice_parent=true
				if not boxes.has(req) or req in item.requires or choice_parent:continue
				var a:Vector2=boxes[req].get_center();var b:Vector2=boxes[item.id].get_center()
				draw_dashed_line(at(a),at(b),T.GREEN if bool(pathway.ready) else T.MUTED,maxf(1,zoom_level),3*zoom_level)
	for item:Dictionary in owner_view.records:
		var origin:Vector2=boxes[item.id].position;var rect:=Rect2(at(origin),CARD*zoom_level)
		if not rect.intersects(Rect2(Vector2.ZERO,size)):continue
		var active:bool=item.get("assignment",{}).get("active",false)
		var color:=Art.color(item.domain) if item.get("exposed",false) else T.MUTED
		draw_style_box(T.flat(T.PAPER_RAISED,T.GOLD if item.id==owner_view.selected_id else color.darkened(.25),2 if item.id==owner_view.selected_id else 1,4,0),rect)
		draw_rect(Rect2(at(origin+Vector2(0,0)),Vector2(5,CARD.y)*zoom_level),color)
		var picture:Texture2D=Art.thumbnail_for(item) if bool(item.get("exposed",false)) else null
		var image_rect:=Rect2(at(origin+Vector2(14,10)),IMAGE*zoom_level)
		if picture:
			draw_texture_rect_region(picture,image_rect,Art.crop_region(picture,IMAGE,Art.focus_for(item)))
		else:
			draw_rect(image_rect,T.TILE_BG)
			if zoom_level>=DETAIL_ZOOM:words("No picture yet" if bool(item.get("exposed",false)) else "Not yet imagined",origin+Vector2(24,56),12,T.MUTED)
		origin+=Vector2(0,IMAGE_SHIFT)
		if zoom_level<DETAIL_ZOOM:
			# Zoomed out: the name alone, large enough to read.
			words(String(item.name),origin+Vector2(14,128),17,T.INK)
			continue
		words(Art.name_for(String(item.domain)).to_upper(),origin+Vector2(14,102),12,Art.text_color(item.domain))
		words(String(item.name),origin+Vector2(14,128),17,T.INK)
		words(Art.status(item),origin+Vector2(14,150),12,Art.text_color(item.domain))
		var choice_count:=(item.get("requires_any",[]) as Array).size()
		var route_count:=maxi(0,(item.get("pathways",[]) as Array).size()-1)
		var branch_text:=("Several ways in" if choice_count>0 else "Another way to reach it") if choice_count+route_count>0 else String(item.get("subcategory","")).capitalize()
		words(branch_text,origin+Vector2(14,173),12,T.TEAL_TEXT if choice_count+route_count>0 else T.TEXT_SOFT)
		if active:
			words(preload("res://scripts/hud/home_plain.gd").researchers(Art.team(item))+", "+preload("res://scripts/hud/home_plain.gd").evidence(float(item.progress)),origin+Vector2(14,195),12,T.BODY)
			var bar:=Rect2(at(origin+Vector2(14,206)),Vector2(CARD.x-28,5)*zoom_level);draw_rect(bar,T.TRACK);bar.size.x*=clampf(float(item.progress),0,1);draw_rect(bar,color)
		else:
			words("Pick it to see what it brought" if item.known else "Pick it to put a team on it" if item.ready else "Needs earlier knowledge first",origin+Vector2(14,199),12,T.MUTED)
