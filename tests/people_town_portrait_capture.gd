extends Control
## Native input/painting proof on a private desktop, never the player window.
const View=preload("res://scripts/hud/people_town_portrait_view.gd")
const Cast=preload("res://scripts/hud/people_workforce_cast.gd")
const OUTPUT="res://artifacts/people-town-portrait"
var portrait:Control
var selected:Array[String]=[]
var failures:Array[String]=[]

func _ready()->void:
	if "test" not in OS.get_user_data_dir().to_lower():get_tree().quit(2);return
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	var before:=var_to_bytes([GameState.population_allocations,GameState.population_total,GameState.settlement_plots])
	portrait=View.new();add_child(portrait);portrait.position=Vector2(20,40);portrait.size=Vector2(1108,740)
	portrait.configure({"population":150,"allocations":{"Food":43,"Knowledge":57}})
	if portrait.texture==null or portrait.role_screen_positions().size()!=9:
		push_error("Root portrait asset and all9 area mappings are required");get_tree().quit(2);return
	portrait.role_selected.connect(func(role:String):selected.append(role);portrait.focus_role(role))
	for dimensions:Vector2i in [Vector2i(1600,1000),Vector2i(1024,720)]:
		get_window().size=dimensions;get_window().content_scale_size=dimensions
		portrait.size=Vector2(1108,740) if dimensions.x==1600 else Vector2(588,480)
		portrait.reset_view();await _settle();_check_aspect()
		await _capture("hearth-overview-"+str(dimensions.x))
		for role:String in Cast.ROLES:
			portrait.reset_view();await _settle();selected.clear()
			var point:Vector2=portrait.position+portrait.role_screen_positions()[role]
			await _button(point,MOUSE_BUTTON_LEFT,true);await _button(point,MOUSE_BUTTON_LEFT,false);await _settle()
			_expect(selected==[role],"Native image click selects "+role)
			_expect(portrait.focused_role==role,"Native image click focuses "+role)
			_check_aspect()
			if role in ["Food","Knowledge","Crafting"]:await _capture(role.to_lower()+"-focus-"+str(dimensions.x))
		# Actual pointer movement must pan without reinterpreting release as a
		# click. Neither drag nor zoom changes the painting's proportions.
		selected.clear();var point:Vector2=portrait.position+portrait.size*.5
		await _button(point,MOUSE_BUTTON_LEFT,true)
		var motion:=InputEventMouseMotion.new();motion.position=point+Vector2(48,24);motion.global_position=motion.position;motion.relative=Vector2(48,24);motion.button_mask=MOUSE_BUTTON_MASK_LEFT
		Input.parse_input_event(motion);await get_tree().process_frame
		await _button(motion.position,MOUSE_BUTTON_LEFT,false)
		_expect(selected.is_empty(),"Native drag never selects an area")
		var initial_zoom:float=portrait.navigation_state().desired_zoom
		await _button(point,MOUSE_BUTTON_WHEEL_DOWN,true);await _settle()
		_expect(float(portrait.navigation_state().desired_zoom)<initial_zoom,"Native wheel zooms out")
		var remembered:Dictionary=portrait.navigation_state()
		portrait.set_workforce({"Food":40,"Knowledge":60});portrait.focus_role("Defense")
		_expect(portrait.navigation_state()==remembered,"Allocation leaves the selected photo framing unchanged")
		portrait.update_state({"population":400,"allocations":{"Food":40,"Knowledge":60}})
		_expect(portrait.navigation_state()==remembered,"Population stage changes the picture without a camera jump")
		_expect(String(portrait.portrait_stage().id)=="village","Population selects Village artwork")
		portrait.reset_view();await _settle();await _capture("village-overview-"+str(dimensions.x))
		portrait.update_state({"population":150});portrait.reset_view();await _settle()
	get_window().size=Vector2i(1600,1000);get_window().content_scale_size=Vector2i(1600,1000);portrait.size=Vector2(1108,740)
	for population:int in [93,150,400,1500,6000]:
		portrait.update_state({"population":population});portrait.reset_view();await _settle()
		_expect(portrait.texture!=null,"Population portrait exists: "+str(population))
		_check_aspect();await _capture("stage-"+String(portrait.portrait_stage().id))
	_expect(before==var_to_bytes([GameState.population_allocations,GameState.population_total,GameState.settlement_plots]),"Viewer never writes simulation records")
	print("PORTRAIT_NATIVE_INPUT ",failures)
	get_tree().quit(0 if failures.is_empty() else 1)

func _check_aspect()->void:
	var image:Rect2=portrait.image_screen_rect()
	_expect(is_equal_approx(image.size.x/image.size.y,float(portrait.texture.get_width())/portrait.texture.get_height()),"Photo aspect remains exact")
	_expect(Rect2(Vector2.ZERO,portrait.size).encloses(portrait.visible_image_rect()),"Visible photograph is clipped to its own pane")

func _button(point:Vector2,button:int,pressed:bool)->void:
	var event:=InputEventMouseButton.new();event.position=point;event.global_position=point;event.button_index=button;event.pressed=pressed
	Input.parse_input_event(event);await get_tree().process_frame

func _settle()->void:
	portrait._process(3)
	for frame in 6:await get_tree().process_frame

func _capture(label:String)->void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUTPUT+"/"+label+".png")

func _expect(condition:bool,label:String)->void:
	if not condition:failures.append(label)
