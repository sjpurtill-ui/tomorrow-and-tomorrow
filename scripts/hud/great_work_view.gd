extends VBoxContainer
## Retained 3D inspection of one recorded site. Rendering is requested by
## changed geometry, camera input or size; there is no frame/timer process.
const Model:=preload("res://scripts/hud/great_work_model.gd")
const T:=preload("res://scripts/hud/hud_tokens.gd")
const DEFAULT_YAW:=-.62
const DEFAULT_PITCH:=.56
var viewport:SubViewport
var camera:Camera3D
var model_root:Node3D
var model_rebuilds:=0
var current_signature:=""
var yaw:=DEFAULT_YAW
var pitch:=DEFAULT_PITCH
var zoom:=1.0
var plan_visible:=false
var scaffolds_visible:=true
var _description:Dictionary={}
var _bounds:=AABB(Vector3(-30,0,-30),Vector3(60,25,60))
var _worker_count:=0
var _image:TextureRect
var _reading:Label
var _plan_button:Button
var _scaffold_button:Button
var _dirty:=true
var _render_pending:=false
var _viewport_updates:=0

func _init()->void:
	name="GreatWorkView"

static func make(work:Dictionary,height:float=320.0)->Control:
	var view:Control=load("res://scripts/hud/great_work_view.gd").new()
	view.custom_minimum_size=Vector2(240,maxf(220,height))
	view.configure(work)
	return view

func configure(work:Dictionary)->void:
	_description=Model.describe(work)
	if viewport==null:return
	var next:=Model.signature(_description)
	if next!=current_signature:
		var built:=Model.build(_description,{"plan":true,"scaffolds":true,"workers":true,"ground":true})
		if is_instance_valid(model_root):viewport.remove_child(model_root);model_root.queue_free()
		model_root=built.root;viewport.add_child(model_root);_bounds=built.bounds;_worker_count=int(built.worker_count)
		current_signature=next;model_rebuilds+=1
		_apply_options();_camera_changed()
	_update_reading()

func _ready()->void:
	size_flags_horizontal=Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation",8)
	_image=TextureRect.new();_image.name="Diorama";_image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;_image.stretch_mode=TextureRect.STRETCH_SCALE
	_image.custom_minimum_size=Vector2(0,maxf(160,custom_minimum_size.y-74));_image.size_flags_vertical=Control.SIZE_EXPAND_FILL
	_image.mouse_filter=Control.MOUSE_FILTER_STOP;_image.tooltip_text="Drag to turn. Use the wheel to zoom."
	add_child(_image);_image.gui_input.connect(_camera_input);_image.resized.connect(_resize_view)
	viewport=SubViewport.new();viewport.name="WorkViewport";viewport.own_world_3d=true;viewport.size=Vector2i(640,300)
	viewport.msaa_3d=Viewport.MSAA_2X;viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED;viewport.gui_disable_input=true
	add_child(viewport);_image.texture=viewport.get_texture()
	camera=Camera3D.new();camera.name="Camera";camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.current=true;viewport.add_child(camera)
	var world:=WorldEnvironment.new();world.environment=Environment.new()
	world.environment.background_mode=Environment.BG_COLOR;world.environment.background_color=Color("ded5bf")
	world.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;world.environment.ambient_light_color=Color("c1cde0");world.environment.ambient_light_energy=.65
	viewport.add_child(world)
	var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-52,-35,0);sun.light_color=Color("ffe4bb");sun.light_energy=1.15;sun.shadow_enabled=true
	sun.directional_shadow_max_distance=300;viewport.add_child(sun)
	var fill:=DirectionalLight3D.new();fill.rotation_degrees=Vector3(-25,125,0);fill.light_color=Color("b7c5d5");fill.light_energy=.32;viewport.add_child(fill)
	var controls:=HFlowContainer.new();controls.add_theme_constant_override("h_separation",8);add_child(controls)
	_button(controls,"Reset view",reset_view)
	_plan_button=_button(controls,"Unbuilt plan",func()->void:set_plan_visible(not plan_visible));_plan_button.toggle_mode=true
	_scaffold_button=_button(controls,"Scaffolds",func()->void:set_scaffolds_visible(not scaffolds_visible));_scaffold_button.toggle_mode=true
	_reading=T.make_label("",13,T.INK_MUTED);_reading.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;add_child(_reading)
	visibility_changed.connect(_visibility_changed)
	_bind_scroll.call_deferred();configure(_description);_resize_view()

func _button(parent:Node,text:String,callback:Callable)->Button:
	var button:=Button.new();button.text=text;button.custom_minimum_size.y=30;button.add_theme_font_size_override("font_size",13)
	button.pressed.connect(callback);parent.add_child(button)
	return button

func _bind_scroll()->void:
	var ancestor:=get_parent()
	while ancestor!=null:
		if ancestor is ScrollContainer:
			ancestor.get_v_scroll_bar().value_changed.connect(func(_value:float)->void:_visibility_changed())
			ancestor.get_h_scroll_bar().value_changed.connect(func(_value:float)->void:_visibility_changed())
			break
		ancestor=ancestor.get_parent()

func _update_reading()->void:
	if _reading==null:return
	var state:=String(_description.get("state","plan"));var progress:=float(_description.get("progress",0.0))
	var words:="Planned design · nothing built" if state=="plan" else ("Standing" if state=="standing" else "%s · %s complete" % [String(_description.get("status","building")).capitalize(),preload("res://scripts/undertaking_map_visual.gd").percent_words(progress)])
	if String(_description.get("status",""))=="stalled":words+=" · "+String(_description.get("idle","No work today"))
	if plan_visible or state=="plan":words+=" · outline shows unbuilt design"
	_reading.text=words
	_plan_button.disabled=state in ["standing","ruined"]
	_plan_button.set_pressed_no_signal(plan_visible or state=="plan")
	_scaffold_button.disabled=model_root.get_node_or_null("Scaffolding")==null
	_scaffold_button.set_pressed_no_signal(scaffolds_visible)

func _apply_options()->void:
	if not is_instance_valid(model_root):return
	var plan:=model_root.get_node_or_null("UnbuiltPlan") as Node3D
	if plan!=null:plan.visible=plan_visible or _description.get("state")=="plan"
	var scaffold:=model_root.get_node_or_null("Scaffolding") as Node3D
	if scaffold!=null:scaffold.visible=scaffolds_visible

func set_plan_visible(value:bool)->void:
	if plan_visible==value:return
	plan_visible=value;_apply_options();_update_reading();_request_render()

func set_scaffolds_visible(value:bool)->void:
	if scaffolds_visible==value:return
	scaffolds_visible=value;_apply_options();_update_reading();_request_render()

func orbit_by(delta:Vector2)->void:
	if delta.is_zero_approx():return
	yaw=wrapf(yaw-delta.x*.007,-PI,PI);pitch=clampf(pitch+delta.y*.006,.15,1.3);_camera_changed()

func zoom_by(steps:float)->void:
	var next:=clampf(zoom*exp(-steps*.12),.38,2.4)
	if is_equal_approx(next,zoom):return
	zoom=next;_camera_changed()

func reset_view()->void:
	yaw=DEFAULT_YAW;pitch=DEFAULT_PITCH;zoom=1.0;_camera_changed()

func _camera_input(event:InputEvent)->void:
	if event is InputEventMouseMotion and (event.button_mask&MOUSE_BUTTON_MASK_LEFT or event.button_mask&MOUSE_BUTTON_MASK_RIGHT):
		orbit_by(event.relative);_image.accept_event()
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index==MOUSE_BUTTON_WHEEL_UP:zoom_by(1);_image.accept_event()
		elif event.button_index==MOUSE_BUTTON_WHEEL_DOWN:zoom_by(-1);_image.accept_event()
	elif event is InputEventMagnifyGesture:zoom_by(log(maxf(.01,event.factor))/.12);_image.accept_event()

func _resize_view()->void:
	if viewport==null or _image==null:return
	var extent:=Vector2(maxf(1,_image.size.x),maxf(1,_image.size.y))
	var scale:=minf(1.0,minf(1280.0/extent.x,720.0/extent.y))
	viewport.size=Vector2i(maxi(2,roundi(extent.x*scale)),maxi(2,roundi(extent.y*scale)))
	_camera_changed()

func _camera_changed()->void:
	if camera==null:return
	var target:=_bounds.get_center();var distance:=maxf(30,_bounds.size.length()*2.0)
	camera.position=target+Vector3(sin(yaw)*cos(pitch),sin(pitch),cos(yaw)*cos(pitch))*distance
	camera.look_at(target);camera.near=.05;camera.far=distance*4.0
	var low:=Vector2(INF,INF);var high:=Vector2(-INF,-INF)
	for corner in 8:
		var point:=camera.global_transform.affine_inverse()*_bounds.get_endpoint(corner)
		low=low.min(Vector2(point.x,point.y));high=high.max(Vector2(point.x,point.y))
	var aspect:=float(viewport.size.x)/maxf(1,float(viewport.size.y))
	camera.size=maxf(10,maxf(high.y-low.y,(high.x-low.x)/aspect)*1.32)*zoom
	_request_render()

func _on_screen()->bool:
	if not is_visible_in_tree() or _image==null:return false
	var rect:=_image.get_global_rect();var ancestor:=get_parent()
	while ancestor!=null:
		if ancestor is Control and ancestor.clip_contents and not ancestor.get_global_rect().intersects(rect):return false
		ancestor=ancestor.get_parent()
	return true

func _visibility_changed()->void:
	if viewport==null:return
	if not _on_screen():viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED
	elif _dirty:_request_render()

func _request_render()->void:
	_dirty=true
	if viewport==null or not _on_screen() or _render_pending:return
	_render_pending=true;_render_once.call_deferred()

func _render_once()->void:
	_render_pending=false
	if viewport==null or not _on_screen():return
	_dirty=false;_viewport_updates+=1;viewport.render_target_update_mode=SubViewport.UPDATE_ONCE

func report()->Dictionary:
	return {"builds":model_rebuilds,"signature":current_signature,"progress":_description.get("progress",0.0),"course":_description.get("course",0),
		"worker_count":_worker_count,"yaw":yaw,"pitch":pitch,"zoom":zoom,"viewport_updates":_viewport_updates,"plan":plan_visible,"scaffolds":scaffolds_visible}
