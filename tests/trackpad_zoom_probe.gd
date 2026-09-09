extends Node

# Push real events through map -> GUI -> unhandled input, without terrain/saves.
class MapInput:
	extends "res://scripts/local_terrain.gd"
	func _ready()->void:pass
	func _process(_delta:float)->void:pass
	func _height_at(_x:float,_z:float)->float:return 0.0
	func _terrain_hit(_screen:Vector2)->Dictionary:return {}

class GesturePanel:
	extends Control
	var gestures:=0
	var arrows:=0
	func _gui_input(event:InputEvent)->void:
		if event is InputEventGesture:gestures+=1
		if event is InputEventKey and event.pressed and event.keycode in [KEY_UP,KEY_DOWN]:
			arrows+=1;accept_event()

var map:MapInput
var failures:=0
var checks:=0
@onready var root:Window=get_tree().root

func _ready()->void:call_deferred("_run")
func _check(condition:bool,label:String)->void:
	checks+=1
	if not condition:failures+=1;push_error(label)
func _send(event:InputEvent)->void:root.push_input(event,true)
func _pan(delta:Vector2,position:=Vector2(600,400),shift:=false)->void:
	var event:=InputEventPanGesture.new()
	event.position=position;event.delta=delta;event.shift_pressed=shift;_send(event)
func _pinch(factor:float,position:=Vector2(600,400))->void:
	var event:=InputEventMagnifyGesture.new()
	event.position=position;event.factor=factor;_send(event)
func _key(code:Key,shift:=false,command:=false,echo:=false)->void:
	var event:=InputEventKey.new()
	event.keycode=code;event.pressed=true;event.shift_pressed=shift
	event.meta_pressed=command;event.echo=echo;_send(event)
func _hover(position:Vector2)->void:
	var event:=InputEventMouseMotion.new();event.position=position;_send(event)
func _reset(level:=1)->void:
	map.set_camera_distance_level(level)
	map.camera.size=map.zoom_target_size;map.zoom_target_size=-1.0;map.zoom_preset_active=false
	map.distance_input_msec=-1000
	map.camera_target=Vector3.ZERO;map._update_camera()

func _run()->void:
	root.size=Vector2i(1000,700)
	map=MapInput.new();map.camera=Camera3D.new();map.add_child(map.camera)
	map.camera.projection=Camera3D.PROJECTION_PERSPECTIVE
	root.add_child(map)
	await get_tree().process_frame
	_hover(Vector2(600,400))
	for yaw in [-2.0,0.0,1.5]:
		map.camera_yaw=yaw
		_reset()
		var right:=map._camera_ground_screen_right()
		var up:=map._camera_ground_screen_up()
		var original_size:=map.camera.size
		_pan(Vector2(.25,0))
		_check(map.camera_target.dot(right)>0.0,"fractional horizontal pan follows rotated screen axis")
		_check(absf(map.camera_target.dot(up))<.00001,"horizontal pan has no vertical drift")
		var first:=map.camera_target
		_pan(Vector2(.25,0))
		_check(map.camera_target.is_equal_approx(first*2.0),"successive pan deltas retain fractional movement")
		_pan(Vector2(-.5,.25))
		_check(absf(map.camera_target.dot(right))<.00001 and map.camera_target.dot(up)<0.0,"vertical pan and reverse horizontal pan use both axes")
		_check(map.camera.size==original_size and map.zoom_target_size==-1.0,"panning never changes distance")
	_reset();_pan(Vector2(3,2),Vector2(600,400),true)
	_check(map.camera_target.length()>0 and map.zoom_target_size==-1,"Shift gesture still pans")
	var previous:=map.camera_target
	_pan(Vector2(INF,1));_pan(Vector2(1,NAN));_pan(Vector2.ZERO)
	_check(map.camera_target==previous,"invalid/neutral pan cannot corrupt camera")
	for factor in [1.25,.8,0.0,-1.0,1.0]:_pinch(factor)
	_check(map.zoom_target_size==-1,"finger spread during pan cannot trigger zoom")
	for level in range(4):
		_reset(level);_pan(Vector2(20,10))
		var fraction:=map.camera_target.length()/map.camera.size
		_check(is_equal_approx(fraction,Vector2(20,10).length()/root.get_visible_rect().size.y),"pan has consistent screen speed at distance "+str(level))
	_reset();_key(KEY_UP)
	_check(map.camera_distance_level()==0,"Up zooms in one distance")
	_check(map.zoom_pointer==root.get_visible_rect().size*.5,"arrow zoom centers on view")
	_check(map.camera_target==Vector3.ZERO,"Up does not pan at the same time")
	_reset();_key(KEY_DOWN)
	_check(map.camera_distance_level()==2,"Down zooms out one distance")
	map.distance_input_msec=-1000;_key(KEY_DOWN,false,false,true)
	_check(map.camera_distance_level()==2,"held arrow cannot race through further distances even after cooldown")
	map.distance_input_msec=-1000;_key(KEY_DOWN)
	_check(map.camera_distance_level()==3,"new press reaches next distance")
	map.distance_input_msec=-1000;_key(KEY_DOWN)
	_check(map.camera_distance_level()==3,"Down clamps at Continent")
	_reset(0);_key(KEY_UP)
	_check(map.camera_distance_level()==0,"Up clamps at 10000 ft")
	_reset();_key(KEY_DOWN,true)
	_check(map.camera_distance_level()==2 and map.zoom_preset_active,"Shift arrow still selects a distance")
	_reset()
	for action in ["ui_up","ui_down"]:
		Input.action_press(action);map._process_camera_navigation(.2);Input.action_release(action)
	_check(map.camera_target==Vector3.ZERO,"held Up/Down UI actions cannot pan in per-frame movement")
	for code in [KEY_EQUAL,KEY_PLUS,KEY_KP_ADD]:
		_reset();_key(code);_check(map.camera_distance_level()==0,"existing zoom-in alias "+str(code))
	for code in [KEY_MINUS,KEY_KP_SUBTRACT]:
		_reset();_key(code);_check(map.camera_distance_level()==2,"existing zoom-out alias "+str(code))
	_reset();_key(KEY_UP,false,true)
	_check(map.zoom_target_size==-1,"Command shortcut does not zoom")
	var panel:=GesturePanel.new();panel.size=Vector2(250,250)
	panel.mouse_filter=Control.MOUSE_FILTER_STOP;panel.focus_mode=Control.FOCUS_ALL;root.add_child(panel)
	await get_tree().process_frame
	_hover(Vector2(100,100));_reset()
	_pan(Vector2(0,-1),Vector2(100,100));_pinch(1.25,Vector2(100,100))
	_check(map.zoom_target_size==-1 and map.camera_target==Vector3.ZERO,"panel gestures leave map still")
	_check(panel.gestures==2,"panel receives gestures for its own scrolling")
	panel.grab_focus();_key(KEY_UP);_key(KEY_DOWN)
	_check(panel.arrows==2 and map.zoom_target_size==-1,"panel keeps arrow navigation")
	panel.release_focus()
	var button:=Button.new();button.text="Map toolbar";button.size=Vector2(200,40)
	root.add_child(button);button.grab_focus();_hover(Vector2(600,400));_reset();_key(KEY_UP)
	_check(map.camera_distance_level()==0,"toolbar focus cannot swallow map zoom")
	button.release_focus();button.free()
	for entry:Control in [LineEdit.new(),TextEdit.new()]:
		entry.position=Vector2(10,270);entry.size=Vector2(200,80);root.add_child(entry);entry.grab_focus()
		_reset();_key(KEY_UP);_key(KEY_DOWN);_key(KEY_EQUAL)
		_check(map.zoom_target_size==-1,"text entry retains keys with pointer over map")
		entry.release_focus();entry.free()
	for modal in ["founding_focus_panel","scout_dispatch_panel","settlement_convoy_confirm_panel"]:
		map.set(modal,panel);_reset();_key(KEY_DOWN);_pan(Vector2(0,-1));_pinch(1.25)
		_check(map.zoom_target_size==-1 and map.camera_target==Vector3.ZERO,"decision modal blocks map input: "+modal)
		map.set(modal,null)
	map.world_menu_panel=panel;_reset();_key(KEY_DOWN)
	_check(map.zoom_target_size==-1,"world menu blocks arrow zoom")
	map.world_menu_panel=null;panel.free();_hover(Vector2(600,400));_reset()
	var wheel:=InputEventMouseButton.new()
	wheel.position=Vector2(600,400);wheel.button_index=MOUSE_BUTTON_WHEEL_UP;wheel.pressed=true;_send(wheel)
	_check(map.camera_distance_level()==0,"ordinary mouse wheel remains available")
	map.free()
	print("TRACKPAD_NAVIGATION_CHECKS: ",checks,"; FAILURES: ",failures)
	get_tree().quit(1 if failures else 0)
