extends Control
## Independent temporal proof using the actual private renderer and shader.
## The isolated fixture only supplies routes/time; no production code is changed.
## Run only with tools/run_isolated_gpu_probe.ps1 and isolated Test userdata.
## --woven selects acquired woven attire; --navigation-only runs real GUI events.
## --prefix names evidence. --worker-script supports read-only peer review before
## integration. --review-only preserves failing baseline images (not a pass).
const DefaultView=preload("res://scripts/hud/people_settlement_view.gd")
var View:Script=DefaultView
const Fixture=preload("res://tests/city_evolution_visual_fixture.gd")
const TIMES=[0.0,.30,.60,.90,1.20,1.50]
const OUTPUT="res://artifacts/people-motion-b"
var town:Control
var failures:Array[String]=[]
var records:Array[Dictionary]=[]
var prefix:="current"
var review_only:=false
var navigation_only:=false
var woven:=false
var selected:Array[String]=[]
var last_screen_travel:=Vector2.ZERO

func _ready()->void:
	if "test" not in OS.get_user_data_dir().to_lower():push_error("Isolated Test user data required");get_tree().quit(2);return
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--prefix="):prefix=arg.trim_prefix("--prefix=")
		if arg=="--review-only":review_only=true
		if arg=="--navigation-only":navigation_only=true
		if arg=="--woven":woven=true
		if arg.begins_with("--worker-script="):View=load(arg.trim_prefix("--worker-script="))
	get_window().size=Vector2i(1200,940);get_window().content_scale_size=Vector2i(1200,940)
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	town=View.new();town.size=Vector2(384,320);add_child(town)
	town.configure(_motion_context())
	town.set_process(false)
	await _navigation()
	if navigation_only:
		print("PEOPLE_NATIVE_NAVIGATION ",failures);get_tree().quit(0 if failures.is_empty() else 1);return
	if town.has_method("_worker_sites"):await _workplace_sequences()
	for child:Node in town.model.get_children():
		if child is Node3D and child!=town._people:child.visible=false
	town.view.transparent_bg=true
	for child:Node in town.view.get_children():
		if child is WorldEnvironment:child.environment.background_mode=Environment.BG_CLEAR_COLOR
	# Keep the same actual camera distance as the baseline, independently of the
	# corrected close-zoom minimum, so the native-size comparisons are fair.
	town._target=Vector3.ZERO;town._span=.025/1.3;town._position_camera()
	town._people.multimesh.instance_count=1
	if town.has_method("_worker_sample"):
		if not bool(town._people_paint.get_shader_parameter("walk_atlas_ready")):failures.append("Actual renderer has no validated walking atlas")
		if not bool(town._people_paint.get_shader_parameter("carry_atlas_ready")):failures.append("Actual renderer has no validated carrying atlas")
	var before:=var_to_bytes([GameState.settlement_plots,GameState.settlement_routes,GameState.population_allocations])
	for carrying:bool in [false,true]:
		var sheet:=_sheet("Carried load" if carrying else "Walking")
		var row:=0
		for direction:Vector2 in [Vector2.RIGHT,Vector2.DOWN,Vector2(1,1).normalized(),Vector2(1,-1).normalized()]:
			for returning:bool in [false,true]:
				var route:=PackedVector2Array([-direction*.005,direction*.005])
				var walk:Dictionary={"path":route,"length":.01,"phase":.75 if returning else .25,"speed":.0008}
				var samples:=await _sequence(walk,0,carrying)
				var label:="%s %s\nScreen travel %s"%[str(direction),"return" if returning else "outbound",str(last_screen_travel.snapped(Vector2.ONE))]
				_show_row(sheet,row,label,samples);row+=1
		await _save_sheet(sheet,"carry" if carrying else "walk")
	var sheet:=_sheet("Stationary work: inspect hand/object contact and purpose")
	var row:=0
	for entry:Array in [["Gather",1],["Chop",2],["Watch",7],["Craft",8]]:
		var walk:Dictionary={"path":PackedVector2Array([Vector2(-.005,0),Vector2(.005,0)]),"length":.01,"phase":0.0,"speed":0.0,"stationary":Vector2.ZERO,"target":Vector2(.001,0),"role":entry[0],"source":"temporal pose fixture","pose":entry[1]}
		_show_row(sheet,row,entry[0],await _sequence(walk,int(entry[1]),false));row+=1
	await _save_sheet(sheet,"stationary")
	if town.has_method("_worker_sample"):
		var cycle_times:Array=[.5,2.0,4.5,5.5,7.0,9.5]
		var cycle_sheet:=_sheet("Actual delivery: pickup / loaded travel / drop / empty return",cycle_times)
		for direction:int in [-1,1]:
			var route:=PackedVector2Array([Vector2(-.002*direction,0),Vector2(.002*direction,0)])
			var delivery:Dictionary={"path":route,"length":.004,"speed":.001,"phase":0.0,"pause":1.0,"delivery":true,"pickup_target":route[0]+Vector2(0,.001),"drop_target":route[1]+Vector2(0,.001)}
			_show_row(cycle_sheet,0 if direction<0 else 1,"Native delivery "+str(direction),await _sequence(delivery,0,false,cycle_times))
			for index in cycle_times.size():
				var state:Dictionary=View._worker_sample(delivery,cycle_times[index])
				if bool(state.carrying)!=[false,true,true,true,false,false][index]:failures.append("Delivery load not continuous from pickup to drop")
		await _save_sheet(cycle_sheet,"delivery")
	if before!=var_to_bytes([GameState.settlement_plots,GameState.settlement_routes,GameState.population_allocations]):failures.append("Motion proof changed live model records")
	var report:={"frames":records,"failures":failures,"times":TIMES,"worker_script":View.resource_path,"note":"Rendered at native 384x320 with the normal .001 worker scale; contact sheets retain source pixels. Orientation is checked against actual finite displacement, with image review for face direction, feet and load."}
	var file:=FileAccess.open(OUTPUT+"/"+prefix+"-report.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"\t"));file.close()
	print("PEOPLE_MOTION_SEQUENCE ",failures)
	get_tree().quit(0 if failures.is_empty() or review_only else 1)

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
	if town.geometry_builds!=geometry:failures.append("Navigation rebuilt recorded settlement geometry")
	# A real dedicated parcel must be reachable away from its text anchor. Use
	# the actual viewport event route, then repeat the gesture as a drag.
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
	if selected!=["Food"]:failures.append("Native physical parcel click outside label radius did not select Food")
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

func _sequence(walk:Dictionary,pose:int,carrying:bool,times:Array=TIMES)->Array[Image]:
	town._walks.assign([walk]);town._people.multimesh.set_instance_custom_data(0,Color(0,pose,1 if carrying else 0,.75))
	var result:Array[Image]=[];var transforms:Array[Transform3D]=[];var crop:=Rect2i();var feet_samples:Array[Vector2]=[];var contact_offsets:Array[float]=[]
	for time:float in times:
		town._elapsed=time;town._move_people()
		# The directional carry sheet isolates the actual material on both travel
		# directions. The separate delivery cycle below tests when production code
		# attaches/removes the load; this flag is never confused with a real job.
		if carrying:
			var custom:Color=town._people.multimesh.get_instance_custom_data(0);custom.b=1.0
			town._people.multimesh.set_instance_custom_data(0,custom)
		for index in 3:await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var transform:Transform3D=town._people.multimesh.get_instance_transform(0);transforms.append(transform)
		var feet:Vector2=town.camera.unproject_position(transform.origin)
		feet_samples.append(feet)
		if result.is_empty():crop=Rect2i(Vector2i(feet)-Vector2i(65,100),Vector2i(150,136))
		var image:Image=town.view.get_texture().get_image().get_region(crop)
		result.append(image)
		var bounds:=image.get_used_rect();var contact:=float(bounds.end.y+crop.position.y)-feet.y
		contact_offsets.append(contact)
		records.append({"pose":pose,"carrying":carrying,"returning":float(walk.phase)>.5,"time":time,"feet":feet,"world":transform.origin,"heading":transform.basis.z.normalized(),"pixel_bounds":bounds,"ground_contact_offset_px":contact,"custom":town._people.multimesh.get_instance_custom_data(0)})
	last_screen_travel=feet_samples[-1]-feet_samples[0]
	if contact_offsets.max()-contact_offsets.min()>4.0:failures.append("Painted feet change ground registration by over4px: pose%s carry%s"%[pose,carrying])
	if not walk.has("stationary") and not walk.get("delivery",false):
		for index in range(1,transforms.size()):
			var velocity:=transforms[index].origin-transforms[index-1].origin
			if velocity.length()<.000001:failures.append("Travel did not advance");continue
			if transforms[index].basis.z.normalized().dot(velocity.normalized())<.95:
				var finding:="Model heading opposes actual travel: route%s return=%s carry=%s"%[walk.path,str(float(walk.phase)>.5),str(carrying)]
				if finding not in failures:failures.append(finding)
	elif walk.has("stationary"):
		for transform in transforms:
			if transform.origin.distance_to(transforms[0].origin)>.000001:failures.append("Stationary worker drifted")
	# An unchanged image across a full stride signals a sliding static painting.
	if pose==0 and not walk.get("delivery",false) and result[0].get_data()==result[3].get_data():failures.append("Travel has no temporal image change")
	return result

func _workplace_sequences()->void:
	var shop:=Fixture.plot(5,Vector2(-.018,0));shop.land_use="workshop";shop.form="route_side_workshop";shop.fabric_generation=4
	var frame:=Fixture.plot(9,Vector2(.018,0));frame.form="subdivided_frontage_compound";frame.fabric_generation=4;frame.status="under_construction";frame.construction_progress=.55
	var context:Dictionary={"plots":[shop,frame],"routes":[{"id":1,"active":true,"points":PackedVector2Array([Vector2(-.04,.028),Vector2(.04,.028)])}],"population":93,"origin":Vector3.ZERO,"allocations":{"Crafting":20,"Construction":20,"Logistics":20}}
	var untouched:=var_to_bytes(context)
	town.size=Vector2(1100,800);town.configure(context);town.set_process(false)
	var tasks:Array[Dictionary]=[]
	for walk:Dictionary in town._walks:
		if walk.has("stationary"):tasks.append(walk.duplicate(true))
	for task:Dictionary in tasks:
		if task.source in ["workshop_workbench","recorded_frame"]:failures.append("Synthetic building-edge task is detached from its painted workplace")
		var prop:Node3D=town.model.get_node_or_null("PaintedWorkplace_"+String(task.source))
		if prop==null:prop=town.model.get_node_or_null("Workplace_"+String(task.source))
		if prop==null or not prop.is_visible_in_tree():failures.append("Stationary task lacks its actual visible prop")
		if task.source in ["bench","hide_frame"] and int(task.pose)!=100:failures.append("Worker crouches below a raised work surface")
		town.focus_role(task.role);await _settle()
		var before_transform:Transform3D=town._people.multimesh.get_instance_transform(town._walks.find(task)) if town._walks.find(task)>=0 else Transform3D.IDENTITY
		for time:float in [0.0,.4,.8,1.2]:
			town._elapsed=time;town._move_people();await get_tree().process_frame;await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(OUTPUT+"/"+prefix+"-site-"+task.source+"-"+str(time)+".png")
		var after_transform:Transform3D=town._people.multimesh.get_instance_transform(town._walks.find(task)) if town._walks.find(task)>=0 else Transform3D.IDENTITY
		if before_transform.origin.distance_to(after_transform.origin)>.000001:failures.append("Actual stationary work drifted from its target")
		records.append({"site":task.source,"role":task.role,"at":task.stationary,"target":task.target,"pose":task.pose})
	town.focus_role("Construction");await _settle();await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUTPUT+"/"+prefix+"-construction-no-empty-work.png")
	if untouched!=var_to_bytes(context):failures.append("Worksite rendering modified recorded fixture")
	town.configure(_motion_context())
	town.size=Vector2(384,320);town._resize_view()

func _motion_context()->Dictionary:
	return {"plots":[],"routes":[{"id":1,"points":PackedVector2Array([Vector2(-.005,0),Vector2(.005,0)]),"active":true}],"population":4,"allocations":{},"origin":Vector3.ZERO,"clothing_knowledge":["plain_weaving","bone_needle_sewing","garment_pattern_cutting"] if woven else [],"clothing_context":{"coverage":1.0}}

func _sheet(title:String,times:Array=TIMES)->Control:
	var sheet:=ColorRect.new();sheet.color=Color("303b36");sheet.size=Vector2(1200,940);add_child(sheet)
	var heading:=Label.new();heading.text="PRIVATE TEST · "+title;heading.position=Vector2(18,10);heading.add_theme_font_size_override("font_size",20);sheet.add_child(heading)
	for i in times.size():
		var label:=Label.new();label.text="%.2fs"%times[i];label.position=Vector2(230+i*155,42);sheet.add_child(label)
	return sheet

func _show_row(sheet:Control,row:int,caption:String,frames:Array[Image])->void:
	var label:=Label.new();label.text=caption;label.position=Vector2(16,78+row*104);label.size=Vector2(202,92);label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;sheet.add_child(label)
	for i in frames.size():
		var picture:=TextureRect.new();picture.texture=ImageTexture.create_from_image(frames[i]);picture.position=Vector2(220+i*155,60+row*104);picture.size=Vector2(150,136);sheet.add_child(picture)

func _save_sheet(sheet:Control,kind:String)->void:
	for i in 3:await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUTPUT+"/"+prefix+"-"+kind+".png")
	sheet.queue_free();await get_tree().process_frame
