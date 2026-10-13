extends GdUnitTestSuite

const Hud:=preload("res://scripts/hud/command_rail_hud.gd")
class BareHud extends "res://scripts/hud/command_rail_hud.gd":
	func _ready()->void:pass

func test_the_readings_stand_on_the_top_bar_not_in_a_second_strip()->void:
	# The parchment shell keeps the day's readings on the one top bar; the old
	# row of boxed chips under it stays hidden at every window size, so
	# nothing can cover the clock.
	var canvas:SubViewport=auto_free(SubViewport.new());canvas.size=Vector2i(1280,720);add_child(canvas)
	var hud:Control=auto_free(BareHud.new());canvas.add_child(hud)
	hud._build_time_pill();hud._build_kpi_strip()
	for size in [Vector2i(1138,640),Vector2i(1280,720),Vector2i(2400,1000)]:
		canvas.size=size
		for i in 2:await get_tree().process_frame
		hud._layout()
		assert_bool(hud.kpi_strip.visible).override_failure_message("a second strip at %s" % str(size)).is_false()
		assert_float(hud.time_pill.position.x+hud.time_pill.get_combined_minimum_size().x).override_failure_message("clock off the edge at %s" % str(size)).is_less_equal(float(size.x))
	# The chips still take the day's words, for the bar and its hover cards.
	hud._update_kpi("food","0.0 d","▼ shortage -99999d",Hud.Tokens.RED,"negative")
	assert_str((hud.kpi_chips.food.value as Label).text).is_equal("0.0 d")

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

func test_pause_is_one_sign_with_its_words_and_the_paces_are_named()->void:
	# The parchment shell (approved 2026-10-04): pause is the one sign every
	# player reads, with its words on hover; each pace says its name on hover.
	var hud:=_rail()
	hud._style_speed_controls(0)
	assert_str(hud.pause_button.text).is_equal("▶")
	assert_str(hud.pause_button.tooltip_text).contains("Let time run")
	hud._style_speed_controls(3)
	assert_str(hud.pause_button.text).is_equal("Ⅱ")
	assert_str(hud.pause_button.tooltip_text).contains("Stop time")
	assert_int(hud.speed_buttons.size()).is_equal(Hud.SPEED_LABELS.size())
	for speed:int in hud.speed_buttons.size():
		if speed==0:continue
		assert_str(String(hud._speed_card(speed).kicker)).contains(String(Hud.SPEED_LABELS[speed]).to_lower())

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
