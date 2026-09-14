extends Control
const Art=preload("res://scripts/hud/research_visuals.gd")
const T=preload("res://scripts/hud/hud_tokens.gd")
const UI_FONT:=preload("res://assets/fonts/battle/Barlow-Medium.ttf")
# The graph is navigation, not a second card gallery. Artwork remains in the
# selected detail pane, leaving compact nodes and legible relationships here.
const CARD:=Vector2(244,138)
var owner_view:Control
var boxes:Dictionary={}
var center:=Vector2.ZERO
var zoom_level:=1.0
var dragging:=false
var press:=Vector2.ZERO
var moved:=false
func _ready()->void:
	clip_contents=true;mouse_default_cursor_shape=Control.CURSOR_DRAG;focus_mode=Control.FOCUS_ALL
	resized.connect(func()->void:queue_redraw())
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
		boxes[item.id]=Rect2(Vector2(col*294,row*158),CARD)
	queue_redraw()
func fit()->void:
	if boxes.is_empty():return
	var bounds:Rect2=boxes.values()[0]
	for rect:Rect2 in boxes.values():bounds=bounds.merge(rect)
	center=bounds.get_center();zoom_level=clampf(minf(size.x/(bounds.size.x+60),size.y/(bounds.size.y+60)),.4,1.0);queue_redraw()
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
func words(text:String,point:Vector2,font:int,color:Color,width:float=CARD.x-22)->void:
	var shown:=text
	while shown.length()>2 and UI_FONT.get_string_size(shown,HORIZONTAL_ALIGNMENT_LEFT,-1,font).x>width:shown=shown.left(-2)
	if shown!=text:shown=shown.trim_suffix(" ")+"…"
	draw_string(UI_FONT,at(point),shown,HORIZONTAL_ALIGNMENT_LEFT,width*zoom_level,maxi(8,roundi(font*zoom_level)),color)
func _draw()->void:
	draw_rect(Rect2(Vector2.ZERO,size),Color("0b181e"))
	# Every required foundation.
	for item:Dictionary in owner_view.records:
		for req in item.requires:
			if not boxes.has(req):continue
			var a:Vector2=boxes[req].position+Vector2(CARD.x,CARD.y*.5);var b:Vector2=boxes[item.id].position+Vector2(0,CARD.y*.5)
			var selected:bool=item.id==owner_view.selected_id or req==owner_view.selected_id
			var color:=T.GOLD if selected else Color("354d58")
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
		draw_style_box(T.flat(Color("182a31"),T.GOLD if item.id==owner_view.selected_id else color.darkened(.25),2 if item.id==owner_view.selected_id else 1,6,0),rect)
		draw_rect(Rect2(at(origin+Vector2(0,0)),Vector2(5,CARD.y)*zoom_level),color)
		words(Art.name_for(String(item.domain)).to_upper(),origin+Vector2(14,20),9,color)
		words(String(item.name),origin+Vector2(14,46),15,T.INK)
		words(Art.status(item),origin+Vector2(14,67),11,color)
		var choice_count:=(item.get("requires_any",[]) as Array).size()
		var route_count:=maxi(0,(item.get("pathways",[]) as Array).size()-1)
		var branch_text:="%d choice fork%s" % [choice_count,"" if choice_count==1 else "s"] if choice_count>0 else "%d alternate approach%s" % [route_count,"" if route_count==1 else "es"] if route_count>0 else String(item.get("subcategory","")).capitalize()
		words(branch_text,origin+Vector2(14,91),11,T.TEAL if choice_count+route_count>0 else T.TEXT_SOFT)
		if active:
			words(Art.workforce(Art.team(item))+" · %d%% evidence" % roundi(float(item.progress)*100),origin+Vector2(14,113),11,T.BODY)
			var bar:=Rect2(at(origin+Vector2(14,122)),Vector2(CARD.x-28,5)*zoom_level);draw_rect(bar,Color("30434a"));bar.size.x*=clampf(float(item.progress),0,1);draw_rect(bar,color)
		else:
			words("Select for findings" if item.known else "Select to direct this team" if item.ready else "Earlier knowledge needed",origin+Vector2(14,117),11,T.MUTED)
