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

func test_a_later_age_strip_never_covers_the_clock()->void:
	# A later age shows every chip (goods and the day's labour too). The canvas
	# is the window divided by the UI scale (display_preferences.logical_size):
	# a 1600x900 window at the default 1.25 lays out at 1280x720, and 1138x640
	# is the smallest. There the least urgent chips give way; food, lives and
	# the day's labour stay; a wide canvas shows them all again.
	var known:Array[String]=GameState.known_discoveries.duplicate()
	GameState.known_discoveries.append("printing_process")
	var canvas:SubViewport=auto_free(SubViewport.new());canvas.size=Vector2i(1280,720);add_child(canvas)
	var hud:Control=auto_free(BareHud.new());canvas.add_child(hud)
	hud._build_time_pill();hud._build_kpi_strip()
	hud.time_text.text="[b]Year 13 · Summer[/b] · Hot →"
	for size in [Vector2i(1280,720),Vector2i(1138,640)]:
		canvas.size=size
		for i in 3:await get_tree().process_frame
		hud._layout()
		for i in 2:await get_tree().process_frame
		var clock_end:float=hud.time_pill.position.x+hud.time_pill.get_combined_minimum_size().x
		assert_float(hud.kpi_strip.position.x).override_failure_message("strip over the clock at %s" % str(size)).is_greater_equal(clock_end+12.0)
		assert_float(hud.kpi_strip.position.x+hud.kpi_strip.get_combined_minimum_size().x).override_failure_message("strip off the edge at %s" % str(size)).is_less_equal(float(size.x))
		for id in ["food","health","gdp"]:
			assert_bool((hud.kpi_chips[id].chip as Control).visible).override_failure_message("%s must stay at %s" % [id,str(size)]).is_true()
	canvas.size=Vector2i(2400,1000)
	for i in 2:await get_tree().process_frame
	hud._layout()
	for id in hud.kpi_chips:
		assert_bool((hud.kpi_chips[id].chip as Control).visible).override_failure_message(String(id)+" hidden at 2400").is_true()
	GameState.known_discoveries.clear();GameState.known_discoveries.append_array(known)

class RailBare extends "res://scripts/hud/command_rail_hud.gd":
	func _ready()->void:
		_build_rail()
		_build_time_pill()
		_build_decision_queue()
	func _layout()->void:pass
	func _position_toolbar()->void:pass

func _rail()->Control:
	var canvas:SubViewport=auto_free(SubViewport.new());canvas.size=Vector2i(1600,900);add_child(canvas)
	var hud:Control=auto_free(RailBare.new());canvas.add_child(hud)
	return hud

func test_decision_queue_has_one_answer_path_and_a_season_date()->void:
	var hud:=_rail()
	hud._rebuild_queue([{"id":"x1","text":"The stores are low","office":"Steward","advisor":"Hena","day":34844,"severity":"warning"}])
	var texts:Array[String]=[]
	for node in hud.queue_root.find_children("*","Label",true,false):texts.append((node as Label).text)
	var buttons:Array[String]=[]
	for node in hud.queue_root.find_children("*","Button",true,false):buttons.append((node as Button).text)
	assert_array(buttons).contains_exactly_in_any_order(["Answer","Later"])
	var joined:=" | ".join(texts)
	assert_str(joined).contains(hud.EraWords.when(34844))
	assert_str(joined).not_contains("Day 34844")
	assert_str(joined).not_contains("DECISION")

func test_time_controls_are_words_not_glyphs()->void:
	var hud:=_rail()
	hud._style_speed_controls(0)
	assert_str(hud.pause_button.text).is_equal("Resume")
	hud._style_speed_controls(3)
	assert_str(hud.pause_button.text).is_equal("Pause")
	for button:Button in hud.speed_buttons:
		for glyph in ["▶","Ⅱ","½","1d","3d"]:
			assert_str(button.text).not_contains(glyph)
		assert_bool(button.text.length()>=4).is_true()

func test_alerts_in_the_closed_drawer_show_on_the_drawer_button()->void:
	var hud:=_rail()
	hud.drawer_open=false;hud._sync_drawer()
	hud._set_badge("civ","2",Hud.Tokens.RED)
	hud._set_badge("economy","!",Hud.Tokens.RED)
	var badge:Label=hud.rail_badges["drawer"]
	assert_bool(badge.visible).is_true()
	assert_str(badge.text).is_equal("3")
	hud.drawer_open=true;hud._sync_drawer()
	assert_bool(badge.visible).is_false()
	hud._set_badge("civ","",Hud.Tokens.RED);hud._set_badge("economy","",Hud.Tokens.RED)
	hud.drawer_open=false;hud._sync_drawer()
	assert_bool(badge.visible).is_false()

func test_every_rail_hotkey_has_one_owner_and_is_named()->void:
	var seen:={}
	for key in Hud.HOTKEYS:
		var section:=String(Hud.HOTKEYS[key])
		assert_bool(seen.has(section)).override_failure_message("two keys open %s" % section).is_false()
		seen[section]=true
		var named:=false
		for spec:Dictionary in Hud.SECTIONS:
			if String(spec.id)==section or String(spec.get("section",""))==section:
				named=named or String(spec.tooltip).contains(OS.get_keycode_string(key))
		assert_bool(named).override_failure_message("%s key not named on the rail" % section).is_true()
	assert_bool(Hud.HOTKEYS.values().has("chronicle")).is_true()
