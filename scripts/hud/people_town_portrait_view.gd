extends Control
## Read-only, aspect-preserving navigation over one illustrated town portrait.
## Work allocation remains owned by the existing provider and task engine.
signal role_anchors_changed(anchors:Dictionary)
signal role_selected(role:String)
signal focus_changed(role:String)

const DATA_PATH="res://scripts/hud/people_town_portrait.gd"
const Cast=preload("res://scripts/hud/people_workforce_cast.gd")
const MIN_ZOOM:=1.0
const MAX_ZOOM:=3.0
var focused_role:=""
var visual_people_count:=0
var texture:Texture2D
var _areas:Dictionary={}
var _counts:Dictionary={}
var _percentages:Dictionary={}
var _texture_path:=""
var _portrait_stage:Dictionary={}
var _center:=Vector2(.5,.5)
var _desired_center:=Vector2(.5,.5)
var _zoom:=1.0
var _desired_zoom:=1.0
var _manual_navigation:=false
var _drag_button:=0
var _drag_origin:=Vector2.ZERO
var _dragged:=false
var _hover_role:=""

func _ready()->void:
	clip_contents=true;focus_mode=Control.FOCUS_ALL;mouse_filter=Control.MOUSE_FILTER_STOP
	texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	gui_input.connect(_input_view);resized.connect(_resize_view)
	mouse_exited.connect(func():_hover_role="";queue_redraw())
	focus_entered.connect(queue_redraw);focus_exited.connect(queue_redraw)
	_resize_view()

func configure(context:Dictionary)->void:update_state(context)

func update_state(context:Dictionary)->void:
	var data:Script=load(DATA_PATH) if ResourceLoader.exists(DATA_PATH) else null
	var next_areas:Dictionary=context.get("portrait_areas",data.call("areas",context) if data!=null else {})
	_areas=next_areas.duplicate(true)
	_portrait_stage=context.get("portrait_stage",data.call("stage",context) if data!=null and data.has_method("stage") else {}).duplicate(true)
	if context.get("portrait_texture") is Texture2D:
		texture=context.portrait_texture;_texture_path=""
	else:
		var path:=String(context.get("portrait_texture",data.call("texture_path",context) if data!=null else ""))
		if path!=_texture_path or texture==null:
			_texture_path=path;texture=_load_texture(path)
	if context.has("allocations"):set_workforce(context.allocations,false)
	if not focused_role.is_empty() and not _areas.has(focused_role):focused_role=""
	_resize_view()

func _load_texture(path:String)->Texture2D:
	if path.is_empty():return null
	if ResourceLoader.exists(path):return load(path) as Texture2D
	if not FileAccess.file_exists(path):return null
	var image:=Image.load_from_file(path)
	if image==null or image.is_empty():return null
	image.generate_mipmaps();return ImageTexture.create_from_image(image)

func set_workforce(weights:Dictionary,_preview:bool=false)->void:
	_counts=weights.duplicate(true);_percentages=Cast.apportion(weights)

func workforce_counts()->Dictionary:return _counts.duplicate(true)
func workforce_percentages()->Dictionary:return _percentages.duplicate(true)
func workforce_people()->Array[Dictionary]:return []
func portrait_stage()->Dictionary:return _portrait_stage.duplicate(true)

func _base_size()->Vector2:
	if texture==null or texture.get_width()<=0 or texture.get_height()<=0:return Vector2.ZERO
	var native:=Vector2(texture.get_width(),texture.get_height())
	return native*minf(size.x/native.x,size.y/native.y)

func _rect(center:Vector2,zoom:float)->Rect2:
	var dimensions:=_base_size()*zoom
	return Rect2(size*.5-center*dimensions,dimensions)

func image_screen_rect()->Rect2:return _rect(_center,_zoom)
func portrait_rect()->Rect2:return image_screen_rect()
func visible_image_rect()->Rect2:return image_screen_rect().intersection(Rect2(Vector2.ZERO,size))

func _bounded_center(center:Vector2,zoom:float)->Vector2:
	var dimensions:=_base_size()*zoom;var result:=center
	for axis in 2:
		if dimensions[axis]<=size[axis] or dimensions[axis]<=0:result[axis]=.5
		else:
			var half:=size[axis]*.5/dimensions[axis]
			result[axis]=clampf(result[axis],half,1.0-half)
	return result

func _resize_view()->void:
	_center=_bounded_center(_center,_zoom);_desired_center=_bounded_center(_desired_center,_desired_zoom)
	_project_anchors();queue_redraw()

func _process(delta:float)->void:
	if _center.is_equal_approx(_desired_center) and is_equal_approx(_zoom,_desired_zoom):return
	var amount:=1.0-exp(-delta*10.0)
	_zoom=lerpf(_zoom,_desired_zoom,amount)
	_center=_bounded_center(_center.lerp(_desired_center,amount),_zoom)
	_project_anchors();queue_redraw()

func focus_role(role:String,force:bool=false)->void:
	if not _areas.has(role) or (role==focused_role and not force):return
	focused_role=role;_manual_navigation=false
	var focus:Rect2=_areas[role].get("focus",Rect2(Vector2(_areas[role].get("anchor",Vector2(.5,.5)))-Vector2(.15,.15),Vector2(.3,.3)))
	var base:=_base_size()
	if base.x>0 and base.y>0:
		_desired_zoom=clampf(minf(size.x/maxf(1,base.x*focus.size.x),size.y/maxf(1,base.y*focus.size.y))*.88,MIN_ZOOM,MAX_ZOOM)
	_desired_center=_bounded_center(focus.get_center(),_desired_zoom)
	focus_changed.emit(role);_project_anchors();queue_redraw()

func reset_view()->void:
	focused_role="";_manual_navigation=false;_desired_center=Vector2(.5,.5);_desired_zoom=1.0
	focus_changed.emit("");queue_redraw()

func reset_navigation()->void:
	if focused_role.is_empty():reset_view()
	else:focus_role(focused_role,true)

func pan_view(pixels:Vector2)->void:
	var dimensions:=_base_size()*_desired_zoom
	if dimensions.x<=0 or dimensions.y<=0:return
	_manual_navigation=true
	_desired_center=_bounded_center(_desired_center-pixels/dimensions,_desired_zoom)
	_center=_desired_center;_zoom=_desired_zoom;_project_anchors();queue_redraw()

func zoom_view(factor:float,at:Vector2=Vector2(-1,-1))->void:
	if not is_finite(factor) or factor<=0:return
	var before:=_rect(_desired_center,_desired_zoom)
	if before.size.x<=0 or before.size.y<=0:return
	if at.x<0 or at.y<0:at=size*.5
	var image_at:Vector2=(at-before.position)/before.size
	_desired_zoom=clampf(_desired_zoom/factor,MIN_ZOOM,MAX_ZOOM)
	_desired_center=_bounded_center(image_at-(at-size*.5)/(_base_size()*_desired_zoom),_desired_zoom)
	_manual_navigation=true;queue_redraw()

func navigation_state()->Dictionary:
	return {"role":focused_role,"center":_center,"desired_center":_desired_center,"zoom":_zoom,"desired_zoom":_desired_zoom,"manual":_manual_navigation}

func restore_navigation_state(saved:Dictionary)->void:
	var role:=String(saved.get("role",""))
	if not role.is_empty() and not _areas.has(role):return
	var center:Vector2=saved.get("center",Vector2(.5,.5));var desired:Vector2=saved.get("desired_center",center)
	var zoom:=float(saved.get("zoom",1.0));var desired_zoom:=float(saved.get("desired_zoom",zoom))
	if not center.is_finite() or not desired.is_finite() or not is_finite(zoom) or not is_finite(desired_zoom):return
	focused_role=role;_zoom=clampf(zoom,MIN_ZOOM,MAX_ZOOM);_desired_zoom=clampf(desired_zoom,MIN_ZOOM,MAX_ZOOM)
	_center=_bounded_center(center,_zoom);_desired_center=_bounded_center(desired,_desired_zoom)
	_manual_navigation=bool(saved.get("manual",false));_project_anchors();queue_redraw()

func role_screen_positions()->Dictionary:
	var result:Dictionary={};var image:=image_screen_rect()
	for role:String in _areas:result[role]=image.position+Vector2(_areas[role].get("anchor",Vector2(.5,.5)))*image.size
	return result

func role_anchor_metadata()->Dictionary:
	var result:Dictionary={};var anchors:=role_screen_positions();var visible:=visible_image_rect()
	for role:String in _areas:
		var polygon:=_screen_polygon(role);var bounds:=Rect2()
		if not polygon.is_empty():
			bounds=Rect2(polygon[0],Vector2.ZERO)
			for point:Vector2 in polygon:bounds=bounds.expand(point)
		result[role]={"position":anchors[role],"polygons":[polygon],"visible":visible.has_point(anchors[role]),"physical":true,"source":"Illustrated work area","plot_ids":[],"activity_bounds":bounds.intersection(visible)}
	return result

func annotation_obstacles()->Array[Rect2]:return []
func _project_anchors()->void:role_anchors_changed.emit(role_screen_positions())

func _screen_polygon(role:String)->PackedVector2Array:
	var result:=PackedVector2Array();var image:=image_screen_rect()
	for point:Vector2 in _areas.get(role,{}).get("polygon",PackedVector2Array()):result.append(image.position+point*image.size)
	return result

func role_at(at:Vector2)->String:
	if not visible_image_rect().has_point(at):return ""
	for role:String in Cast.ROLES:
		if Geometry2D.is_point_in_polygon(at,_screen_polygon(role)):return role
	return ""

func _draw()->void:
	if texture!=null:draw_texture_rect(texture,image_screen_rect(),false)
	var role:=_hover_role if not _hover_role.is_empty() else focused_role
	var polygon:=_screen_polygon(role)
	if polygon.size()>2:
		polygon.append(polygon[0]);draw_polyline(polygon,Color(1.0,.88,.63,.68),1.5,true)
	if has_focus():draw_rect(Rect2(Vector2.ONE,size-Vector2.ONE*2),Color(1.0,.88,.63,.9),false,2)

func _input_view(event:InputEvent)->void:
	if event is InputEventMouseMotion:
		if _drag_button!=0:
			var mask:=MOUSE_BUTTON_MASK_LEFT if _drag_button==MOUSE_BUTTON_LEFT else MOUSE_BUTTON_MASK_RIGHT
			if not event.button_mask&mask:_drag_button=0;return
			if event.position.distance_to(_drag_origin)>5:_dragged=true
			if _dragged:pan_view(event.relative)
			accept_event()
		else:
			_hover_role=role_at(event.position);mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND if not _hover_role.is_empty() else Control.CURSOR_ARROW;queue_redraw()
	elif event is InputEventMouseButton:
		if event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
			zoom_view(.88 if event.button_index==MOUSE_BUTTON_WHEEL_UP else 1.0/.88,event.position);accept_event()
		elif event.button_index in [MOUSE_BUTTON_LEFT,MOUSE_BUTTON_RIGHT]:
			if event.pressed:_drag_button=event.button_index;_drag_origin=event.position;_dragged=false;grab_focus()
			else:
				var select:=_drag_button==MOUSE_BUTTON_LEFT and not _dragged;_drag_button=0
				if select:
					var role:=role_at(event.position)
					if not role.is_empty():role_selected.emit(role)
			accept_event()
	elif event is InputEventPanGesture:pan_view(-event.delta*20);accept_event()
	elif event is InputEventMagnifyGesture:zoom_view(1.0/maxf(.1,event.factor),event.position);accept_event()
	elif event is InputEventKey and event.pressed:
		var shifts:={KEY_LEFT:Vector2(60,0),KEY_RIGHT:Vector2(-60,0),KEY_UP:Vector2(0,60),KEY_DOWN:Vector2(0,-60)}
		if shifts.has(event.keycode):pan_view(shifts[event.keycode]);accept_event()
		elif event.keycode in [KEY_PLUS,KEY_EQUAL,KEY_KP_ADD]:zoom_view(.88);accept_event()
		elif event.keycode in [KEY_MINUS,KEY_KP_SUBTRACT]:zoom_view(1.0/.88);accept_event()
		elif event.keycode==KEY_HOME:reset_navigation();accept_event()
