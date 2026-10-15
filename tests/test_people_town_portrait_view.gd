extends GdUnitTestSuite
const View=preload("res://scripts/hud/people_town_portrait_view.gd")
const Cast=preload("res://scripts/hud/people_workforce_cast.gd")

static func fixture_texture()->Texture2D:
	var image:=Image.create(1400,900,false,Image.FORMAT_RGBA8)
	image.fill(Color("b7c69b"));return ImageTexture.create_from_image(image)

static func fixture_areas()->Dictionary:
	var areas:Dictionary={}
	for index in Cast.ROLES.size():
		var at:=Vector2(.08+(index%3)*.30,.08+floorf(float(index)/3)*.30)
		var polygon:=PackedVector2Array([at,at+Vector2(.24,0),at+Vector2(.24,.24),at+Vector2(0,.24)])
		areas[Cast.ROLES[index]]={"polygon":polygon,"anchor":at+Vector2(.12,.12),"focus":Rect2(at-Vector2(.02,.02),Vector2(.28,.28))}
	return areas

func _portrait()->Control:
	var portrait:Control=auto_free(View.new());add_child(portrait);portrait.size=Vector2(1000,600)
	portrait.configure({"portrait_texture":fixture_texture(),"portrait_areas":fixture_areas(),"allocations":{"Food":43,"Crafting":57}})
	return portrait

func _button(portrait:Control,point:Vector2,pressed:bool)->void:
	var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.position=point;event.pressed=pressed;portrait._input_view(event)

func test_portrait_fits_without_stretch_and_all_nine_areas_hit_the_picture()->void:
	var portrait:=_portrait();var image:Rect2=portrait.image_screen_rect()
	assert_float(image.size.x/image.size.y).is_equal_approx(1400.0/900.0,.00001)
	assert_bool(Rect2(Vector2.ZERO,portrait.size).encloses(image)).is_true()
	assert_str(portrait.role_at(Vector2(1,1))).is_empty()
	for role:String in Cast.ROLES:
		assert_str(portrait.role_at(portrait.role_screen_positions()[role])).is_equal(role)
		assert_bool(portrait.role_anchor_metadata()[role].visible).is_true()

func test_click_selects_a_role_but_drag_does_not_select()->void:
	var portrait:=_portrait();var selected:Array[String]=[]
	portrait.role_selected.connect(func(role:String):selected.append(role))
	var at:Vector2=portrait.role_screen_positions().Food
	_button(portrait,at,true);_button(portrait,at,false)
	assert_array(selected).is_equal(["Food"]);selected.clear()
	portrait.focus_role("Food");portrait._process(3)
	at=portrait.role_screen_positions().Food
	_button(portrait,at,true)
	var motion:=InputEventMouseMotion.new();motion.position=at+Vector2(60,20);motion.relative=Vector2(60,20);motion.button_mask=MOUSE_BUTTON_MASK_LEFT
	portrait._input_view(motion);_button(portrait,motion.position,false)
	assert_array(selected).is_empty()
	assert_bool(portrait.navigation_state().manual).is_true()

func test_zoom_pan_bounds_and_center_keep_every_visible_pixel_inside_image()->void:
	var portrait:=_portrait();portrait.zoom_view(.001);portrait._process(3)
	assert_float(portrait.navigation_state().zoom).is_equal_approx(3,.00001)
	portrait.pan_view(Vector2(100000,-100000))
	var image:Rect2=portrait.image_screen_rect()
	assert_bool(image.encloses(Rect2(Vector2.ZERO,portrait.size))).is_true()
	assert_float(image.size.x/image.size.y).is_equal_approx(1400.0/900.0,.00001)
	portrait.zoom_view(1000);portrait._process(3)
	assert_float(portrait.navigation_state().zoom).is_equal_approx(1,.00001)
	assert_that(portrait.image_screen_rect().get_center()).is_equal(portrait.size*.5)

func test_allocation_and_population_portrait_change_preserve_navigation_and_state()->void:
	var portrait:=_portrait();portrait.focus_role("Knowledge");portrait._process(3)
	portrait.pan_view(Vector2(25,-15));portrait.zoom_view(.9);portrait._process(3)
	var saved:Dictionary=portrait.navigation_state();var simulation:=var_to_bytes([GameState.population_allocations,GameState.population_total])
	portrait.set_workforce({"Food":50,"Knowledge":50},false);portrait.focus_role("Knowledge")
	assert_dict(portrait.navigation_state()).is_equal(saved)
	portrait.update_state({"portrait_texture":fixture_texture(),"portrait_areas":fixture_areas(),"portrait_stage":{"id":"town","title":"Town"},"allocations":{"Food":50,"Knowledge":50}})
	assert_dict(portrait.navigation_state()).is_equal(saved)
	assert_str(portrait.portrait_stage().id).is_equal("town")
	assert_int(portrait.workforce_counts().Knowledge).is_equal(50)
	assert_int(portrait.workforce_percentages().Knowledge).is_equal(50)
	assert_array(portrait.workforce_people()).is_empty()
	assert_that(var_to_bytes([GameState.population_allocations,GameState.population_total])).is_equal(simulation)
	var restored:=_portrait();restored.restore_navigation_state(saved)
	assert_dict(restored.navigation_state()).is_equal(saved)
	portrait.reset_navigation();assert_bool(portrait.navigation_state()!=saved).is_true()

func test_resize_preserves_bounded_zoom_and_invalid_state_is_ignored()->void:
	var portrait:=_portrait();portrait.focus_role("Crafting");portrait._process(3)
	var zoom:float=portrait.navigation_state().zoom
	portrait.size=Vector2(560,480);portrait._resize_view()
	assert_float(portrait.navigation_state().zoom).is_equal(zoom)
	assert_float(portrait.image_screen_rect().size.x/portrait.image_screen_rect().size.y).is_equal_approx(1400.0/900.0,.00001)
	var before:Dictionary=portrait.navigation_state()
	portrait.restore_navigation_state({"zoom":NAN,"center":Vector2(INF,0)})
	assert_dict(portrait.navigation_state()).is_equal(before)
