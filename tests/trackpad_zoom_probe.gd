extends Node

# Exercise the real map input routes without building terrain or loading saves.
class MapInput:
	extends "res://scripts/local_terrain.gd"
	func _ready()->void: pass
	func _process(_delta:float)->void: pass

class GesturePanel:
	extends Control
	var gestures:=0
	func _gui_input(event:InputEvent)->void:
		if event is InputEventGesture: gestures+=1

var map:MapInput
var failures:=0
var checks:=0
@onready var root:Window=get_tree().root

func _ready()->void:
	call_deferred("_run")

func _check(condition:bool,label:String)->void:
	checks+=1
	if not condition:
		failures+=1
		push_error(label)

func _send(event:InputEvent)->void:
	root.push_input(event,true)

func _pan(delta:Vector2,position:=Vector2(600,400),fast:=false)->void:
	var event:=InputEventPanGesture.new()
	event.position=position; event.delta=delta; event.shift_pressed=fast
	_send(event)

func _pinch(factor:float,position:=Vector2(600,400))->void:
	var event:=InputEventMagnifyGesture.new()
	event.position=position; event.factor=factor
	_send(event)

func _key(code:Key,fast:=false,command:=false,echo:=false)->void:
	var event:=InputEventKey.new()
	event.keycode=code; event.pressed=true; event.shift_pressed=fast
	event.meta_pressed=command; event.echo=echo
	_send(event)

func _hover(position:Vector2)->void:
	var event:=InputEventMouseMotion.new()
	event.position=position
	_send(event)

func _reset()->void:
	map.camera.size=100.0
	map.zoom_target_size=-1.0

func _run()->void:
	root.size=Vector2i(1000,700)
	map=MapInput.new()
	map.camera=Camera3D.new()
	map.add_child(map.camera)
	root.add_child(map)
	await get_tree().process_frame
	_hover(Vector2(600,400))
	_reset(); _pan(Vector2(0,-0.25))
	_check(map.zoom_target_size>0 and map.zoom_target_size<100,"fractional pan zooms in")
	var first:=map.zoom_target_size
	_pan(Vector2(0,-0.25))
	_check(map.zoom_target_size<first,"successive pan events accumulate")
	_reset(); _pan(Vector2(0,0.25))
	_check(map.zoom_target_size>100,"opposite pan zooms out")
	_reset(); _pan(Vector2(3,0))
	_check(map.zoom_target_size==-1,"horizontal pan does not zoom")
	_reset(); _pinch(1.25)
	_check(is_equal_approx(map.zoom_target_size,80.0),"spread uses native magnification ratio")
	_check(map.zoom_pointer==Vector2(600,400),"gesture zoom anchors at pointer")
	_pinch(0.8)
	_check(is_equal_approx(map.zoom_target_size,100.0),"inverse pinch restores target")
	_reset(); _pinch(0); _pinch(-1); _pinch(1)
	_check(map.zoom_target_size==-1,"invalid and neutral pinch ignored")
	for code in [KEY_EQUAL,KEY_PLUS,KEY_KP_ADD]:
		_reset(); _key(code)
		_check(map.zoom_target_size>0 and map.zoom_target_size<100,"keyboard zoom in "+str(code))
	for code in [KEY_MINUS,KEY_KP_SUBTRACT]:
		_reset(); _key(code)
		_check(map.zoom_target_size>100,"keyboard zoom out "+str(code))
	_reset(); _key(KEY_EQUAL,true)
	_check(is_equal_approx(map.zoom_target_size,100.0/1.8),"Shift accelerates keyboard zoom")
	_key(KEY_EQUAL,false,false,true)
	_check(map.zoom_target_size<100.0/1.8,"held key repeats")
	_check(map.zoom_pointer==root.get_visible_rect().size*0.5,"keyboard zoom anchors at view center")
	_reset(); _key(KEY_EQUAL,false,true)
	_check(map.zoom_target_size==-1,"Command shortcut does not zoom")
	var panel:=GesturePanel.new()
	panel.size=Vector2(250,250)
	panel.mouse_filter=Control.MOUSE_FILTER_STOP
	root.add_child(panel)
	await get_tree().process_frame
	_hover(Vector2(100,100))
	_check(map._pointer_over_ui(),"STOP panel is recognized as UI")
	_reset(); _pan(Vector2(0,-1),Vector2(100,100)); _pinch(1.25,Vector2(100,100))
	_check(map.zoom_target_size==-1,"gestures over panel do not zoom map")
	_check(panel.gestures==2,"panel receives both gestures")
	var entry:=LineEdit.new()
	entry.position=Vector2(10,270); entry.size=Vector2(200,40)
	root.add_child(entry); entry.grab_focus()
	_reset(); _key(KEY_EQUAL)
	_check(map.zoom_target_size==-1,"text field focus prevents keyboard zoom")
	entry.release_focus()
	map.founding_focus_panel=panel
	_hover(Vector2(600,400))
	_reset(); _key(KEY_EQUAL); _pan(Vector2(0,-1)); _pinch(1.25)
	_check(map.zoom_target_size==-1,"founding modal blocks all zoom routes")
	map.founding_focus_panel=null
	map.world_menu_panel=panel
	_reset(); _key(KEY_EQUAL)
	_check(map.zoom_target_size==-1,"world menu blocks keyboard fallback")
	map.world_menu_panel=null
	panel.free(); entry.free()
	_hover(Vector2(600,400))
	_reset()
	var wheel:=InputEventMouseButton.new()
	wheel.position=Vector2(600,400); wheel.button_index=MOUSE_BUTTON_WHEEL_UP; wheel.pressed=true
	_send(wheel)
	_check(map.zoom_target_size>0 and map.zoom_target_size<100,"mouse wheel still zooms")
	map.free()
	print("TRACKPAD_ZOOM_CHECKS: ",checks,"; FAILURES: ",failures)
	get_tree().quit(1 if failures else 0)
