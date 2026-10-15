extends Control
## Native input and temporal regression for the representative hundred-person view.
## Only run on the isolated GPU desktop with Test userdata.
const View=preload("res://scripts/hud/people_settlement_view.gd")
const World=preload("res://scripts/hud/people_work_world.gd")
const Costumes=preload("res://scripts/hud/people_settlement_costumes.gd")
const Fixture=preload("res://tests/city_evolution_visual_fixture.gd")
const OUTPUT="res://artifacts/people-motion-b"
var town:Control
var failures:Array[String]=[]
var selected:Array[String]=[]
var prefix:="hundred"
var navigation_only:=false
var woven:=false

func _ready()->void:
	if "test" not in OS.get_user_data_dir().to_lower():push_error("Isolated Test user data required");get_tree().quit(2);return
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--prefix="):prefix=arg.trim_prefix("--prefix=")
		if arg=="--navigation-only":navigation_only=true
		if arg=="--woven":woven=true
	get_window().size=Vector2i(1200,940);get_window().content_scale_size=Vector2i(1200,940)
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	town=View.new();town.size=Vector2(1100,800);add_child(town);town.configure(_motion_context());town.set_process(false)
	await _navigation()
	if not navigation_only:await _representative_journey()
	print("PEOPLE_NATIVE_WORKFORCE ",failures)
	get_tree().quit(0 if failures.is_empty() else 1)

func _representative_journey()->void:
	var before:=var_to_bytes([GameState.settlement_plots,GameState.settlement_routes,GameState.population_allocations])
	town.position=Vector2(20,50);town.size=Vector2(1160,850);town.reset_view();await _settle()
	town._cast.set_weights({"Food":60,"Crafting":40},false);town._move_people()
	_verify_cast()
	await _navigation_capture("before-transfer")
	town.set_workforce({"Knowledge":60,"Defense":40},true)
	var velocities:=0
	for step in 80:
		var prior:Array=town.workforce_people()
		town._cast.advance(.05);town._elapsed+=.05;town._move_people()
		for person:Dictionary in town._cast.people:
			var old:Dictionary=prior[int(person.id)]
			if not bool(person.moving) or int(person.segment)!=int(old.segment):continue
			var displacement:Vector2=Vector2(person.position)-Vector2(old.position)
			if displacement.length()<.0000001:continue
			var transform:Transform3D=town._people.multimesh.get_instance_transform(int(person.id))
			var facing:=Vector2(transform.basis.z.x,transform.basis.z.z).normalized()
			if facing.dot(displacement.normalized())<.98:failures.append("Representative faces against actual travel")
			velocities+=1
		if step in [0,20,40,79]:await _navigation_capture("transfer-"+str(step))
	if velocities<100:failures.append("Temporal proof did not observe enough actual movement")
	# Complete the same journeys. Every ID and sex must survive reassignment.
	town._cast.advance(100);town._move_people();_verify_cast()
	if town.workforce_percentages().Knowledge!=60 or town.workforce_percentages().Defense!=40:failures.append("Target percentages changed during movement")
	await _navigation_capture("after-transfer")
	for role:String in World.ROLES:
		town._cast.set_weights({role:100},false);town._move_people();town.focus_role(role);await _settle()
		_verify_cast();await _navigation_capture("all100-"+role.to_lower())
	if before!=var_to_bytes([GameState.settlement_plots,GameState.settlement_routes,GameState.population_allocations]):failures.append("Native proof changed simulation records")

func _verify_cast()->void:
	var people:Array=town.workforce_people();var identities:Dictionary={};var women:=0;var men:=0
	if people.size()!=100 or town._people.multimesh.instance_count!=100:failures.append("Workforce is not exactly100 figures")
	for person:Dictionary in people:
		identities[person.id]=true
		if int(person.sex)==0:women+=1
		else:men+=1
		var custom:Color=town._people.multimesh.get_instance_custom_data(int(person.id))
		var role_index:=World.ROLES.find(String(person.role))
		if roundi(custom.b)!=Costumes.instance_code(maxi(0,role_index),int(person.sex)):failures.append("GPU identity differs from the persistent person")
		if not bool(person.moving) and roundi(custom.g)!=20:failures.append("Stationed person is not performing their role")
	if identities.size()!=100 or women!=50 or men!=50:failures.append("Reassignment replaced identities or lost the mixed cast")

func _motion_context()->Dictionary:
	return {"plots":[],"routes":[],"allocations":{"Food":43,"Survey":6,"Extraction":9,"Construction":10,"Crafting":7,"Logistics":10,"Knowledge":5,"Administration":5,"Defense":5},"clothing_knowledge":["plain_weaving","bone_needle_sewing","garment_pattern_cutting"] if woven else [],"clothing_context":{"coverage":1.0}}

func _navigation()->void:
	if not town.has_method("pan_view"):return
	town.size=Vector2(1100,800);town.position=Vector2(20,60)
	town.role_selected.connect(func(role:String)->void:selected.append(role))
	town.reset_view();await _settle()
	var basis:Basis=town.camera.global_basis;var origin:Vector3=town._target;var span:float=town._desired_span
	var geometry:int=town.geometry_builds
	var initial_distance:float=town.camera.position.distance_to(town._target)
	for button:int in [MOUSE_BUTTON_LEFT,MOUSE_BUTTON_RIGHT]:
		var before:Vector3=town._desired_target;var point:Vector2=town.position+town.size*.5
		await _mouse_button(point,button,true)
		for step in 4:
			var motion:=InputEventMouseMotion.new();motion.position=point+Vector2(18,10)*(step+1);motion.relative=Vector2(18,10);motion.button_mask=MOUSE_BUTTON_MASK_LEFT if button==MOUSE_BUTTON_LEFT else MOUSE_BUTTON_MASK_RIGHT
			get_viewport().push_input(motion,true);await get_tree().process_frame
		await _mouse_button(point+Vector2(72,40),button,false);await _settle()
		if town._desired_target.distance_to(before)<.00001:failures.append("Native drag did not pan")
		if not selected.is_empty():failures.append("Native drag incorrectly selected a work area")
		if not town.camera.global_basis.is_equal_approx(basis):failures.append("Native drag rotated or tilted painted scene")
	await _navigation_capture("panned")
	await _mouse_button(town.position+town.size*.55,MOUSE_BUTTON_WHEEL_UP,true);await _settle()
	if not town._desired_span<span:failures.append("Native mouse wheel did not zoom in")
	if not town.camera.position.distance_to(town._target)<initial_distance:failures.append("Native wheel changed span but not actual camera distance")
	if not town.camera.global_basis.is_equal_approx(basis):failures.append("Native zoom rotated painted scene")
	await _navigation_capture("zoomed")
	var zoom:float=town._desired_span;town._resize_view()
	if not is_equal_approx(town._desired_span,zoom):failures.append("Resize discarded manual zoom")
	var home:=InputEventKey.new();home.keycode=KEY_HOME;home.pressed=true;get_viewport().push_input(home,true);await _settle()
	if town._target.distance_to(origin)>.00001 or not is_equal_approx(town._desired_span,span):failures.append("Native Home did not restore overview center/scale")
	await _navigation_capture("reset")
	var anchors:Dictionary=town.role_screen_positions();var at:Vector2=town.position+anchors.values()[0]
	await _mouse_button(at,MOUSE_BUTTON_LEFT,true);await _mouse_button(at,MOUSE_BUTTON_LEFT,false)
	if selected.size()!=1:failures.append("Ordinary left click did not select exactly one area")
	if town.geometry_builds!=geometry:failures.append("Navigation rebuilt workforce geometry")
	# A representative work area must be reachable away from its text anchor. Use
	# the native viewport event route, then repeat the gesture as a drag.
	var field:=Fixture.plot(1);field.land_use="field"
	town.configure({"plots":[field],"routes":[],"population":4,"origin":Vector3.ZERO})
	town.focus_role("Food");await _settle();selected.clear()
	var polygon:PackedVector2Array=town.role_anchor_metadata().Food.polygons[0]
	var middle:=Vector2.ZERO
	for vertex:Vector2 in polygon:middle+=vertex/polygon.size()
	var parcel_click:=middle.lerp(polygon[0],.65)
	if parcel_click.distance_to(town.role_screen_positions().Food)<=42:failures.append("Parcel click fixture does not exceed label hit radius")
	await _mouse_button(town.position+parcel_click,MOUSE_BUTTON_LEFT,true)
	await _mouse_button(town.position+parcel_click,MOUSE_BUTTON_LEFT,false)
	if selected!=["Food"]:failures.append("Native work area click outside label radius did not select Food")
	selected.clear();var before_jitter:Vector3=town._desired_target
	await _mouse_button(town.position+parcel_click,MOUSE_BUTTON_LEFT,true)
	var jitter:=InputEventMouseMotion.new();jitter.position=town.position+parcel_click+Vector2(3,1);jitter.relative=Vector2(3,1);jitter.button_mask=MOUSE_BUTTON_MASK_LEFT
	get_viewport().push_input(jitter,true);await get_tree().process_frame
	await _mouse_button(jitter.position,MOUSE_BUTTON_LEFT,false)
	if selected!=["Food"] or town._desired_target!=before_jitter:failures.append("Sub-threshold pointer jitter panned or prevented ordinary selection")
	selected.clear();await _mouse_button(town.position+parcel_click,MOUSE_BUTTON_LEFT,true)
	var drag:=InputEventMouseMotion.new();drag.position=town.position+parcel_click+Vector2(60,20);drag.relative=Vector2(60,20);drag.button_mask=MOUSE_BUTTON_MASK_LEFT
	get_viewport().push_input(drag,true);await get_tree().process_frame
	await _mouse_button(drag.position,MOUSE_BUTTON_LEFT,false)
	if not selected.is_empty():failures.append("Native drag on physical parcel incorrectly selected it")
	town.configure(_motion_context())
	town.position=Vector2.ZERO;town.size=Vector2(384,320);town._resize_view()
	print("PEOPLE_NATIVE_NAVIGATION ",failures)

func _mouse_button(at:Vector2,button:int,pressed:bool)->void:
	var event:=InputEventMouseButton.new();event.position=at;event.button_index=button;event.pressed=pressed
	event.button_mask=(MOUSE_BUTTON_MASK_LEFT if button==MOUSE_BUTTON_LEFT else MOUSE_BUTTON_MASK_RIGHT) if pressed and button in [MOUSE_BUTTON_LEFT,MOUSE_BUTTON_RIGHT] else 0
	get_viewport().push_input(event,true);await get_tree().process_frame

func _settle()->void:
	for i in 40:town._process(.1)
	for i in 3:await get_tree().process_frame

func _navigation_capture(kind:String)->void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUTPUT+"/"+prefix+"-navigation-"+kind+".png")

