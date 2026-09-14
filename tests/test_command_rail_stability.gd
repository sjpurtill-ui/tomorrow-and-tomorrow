extends GdUnitTestSuite

const Hud:=preload("res://scripts/hud/command_rail_hud.gd")
class BareHud extends "res://scripts/hud/command_rail_hud.gd":
	func _ready()->void:pass

func test_food_shortage_copy_cannot_resize_or_drop_the_kpi_strip()->void:
	var canvas:SubViewport=auto_free(SubViewport.new());canvas.size=Vector2i(1138,640);add_child(canvas)
	var hud:Control=auto_free(BareHud.new());canvas.add_child(hud)
	hud._build_time_pill();hud._build_kpi_strip()
	for i in 3:await get_tree().process_frame
	var food:Dictionary=hud.kpi_chips.food
	var reserved_width:float=float((food.chip as Control).custom_minimum_size.x)
	hud._update_kpi("food","12.0 d","▲",Hud.Tokens.GREEN,"positive")
	for i in 2:await get_tree().process_frame
	assert_float(food.value.size.x).is_greater(20.0)
	assert_float(food.delta.size.x).is_greater_equal(52.0)
	hud._layout();var positive_y:float=float(hud.kpi_strip.position.y)
	assert_float(hud.kpi_strip.position.x).is_greater_equal(hud.time_pill.position.x+hud.time_pill.size.x+12.0)
	hud._update_kpi("food","0.0 d","▼ shortage -99999d",Hud.Tokens.RED,"negative")
	hud._layout()
	assert_float(food.chip.custom_minimum_size.x).is_equal(reserved_width)
	assert_float(hud.kpi_strip.position.y).is_equal(positive_y)
	assert_float(hud.kpi_strip.get_combined_minimum_size().x).is_less_equal(800.0)
