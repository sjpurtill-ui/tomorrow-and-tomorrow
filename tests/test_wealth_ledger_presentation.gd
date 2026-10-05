extends GdUnitTestSuite
const Ledger=preload("res://scripts/hud/wealth_ledger.gd")
const Tokens=preload("res://scripts/hud/hud_tokens.gd")

func _block()->Dictionary:
	return {"stage":"currency","city":"Ashford","leader":{},"managed":true,
		"economy":{"gdp":42.0,"gdp_per_capita":0.4,"productivity":0.8,"effective_workers":52.0},
		"history":[],"conditions":{"health":0.5,"cohesion":0.9,"housing":1.1},
		"accounts":[{"key":"public","name":"Common purse","art":0,"balance":123.0,"points":[{"day":0,"value":100.0},{"day":30,"value":123.0}]}],
		"selected":"","show_work":false,"on_select":func(_key:String):pass,"on_work":func():pass,
		"on_history":func():pass,"on_stores":func():pass,"on_policy":func():pass}

func _texts(node:Node)->String:
	var result:PackedStringArray=[]
	for child in node.find_children("*","Label",true,false):result.append((child as Label).text)
	return "\n".join(result)

func test_daily_refresh_keeps_controls_and_updates_real_measurements()->void:
	var ledger=auto_free(Ledger.new());var block:=_block();ledger.setup(block)
	var before:Array=ledger.find_children("*","",true,false)
	var dial:Control=ledger.find_child("WorkerEffectiveness",true,false)
	assert_float(float(dial.get("measure"))).is_equal(0.8)
	assert_str(_texts(ledger)).contains("Shelter  110%").contains("Health  50%")
	var changed:=block.duplicate(true);changed.economy.productivity=1.3;changed.economy.gdp=67.6;changed.conditions.health=0.95;changed.accounts[0].balance=150.0
	changed.accounts[0].points.append({"day":60,"value":150.0})
	assert_bool(ledger.update_block(changed)).is_true()
	assert_array(ledger.find_children("*","",true,false)).contains_exactly(before)
	assert_float(float(dial.get("measure"))).is_equal(1.3)
	assert_str(_texts(ledger)).contains("Health  95%").contains("Common purse: 150")
	assert_array(ledger._refs.accounts[0].spark.points).contains_exactly(changed.accounts[0].points)

func test_missing_measurements_do_not_invent_health_or_a_trend()->void:
	var block:=_block();block.conditions={};block.economy.erase("productivity")
	var ledger=auto_free(Ledger.new());ledger.setup(block)
	assert_that(ledger.find_child("WorkerEffectiveness",true,false).get("measure")).is_null()
	assert_str(_texts(ledger)).contains("Health  Not measured").contains("Some working conditions have not been measured.").not_contains("Steady:")
	block.history=[{"day":0,"output_per_capita":0.3},{"day":30,"output_per_capita":0.4}]
	assert_bool(ledger.update_block(block)).is_true()
	assert_str(_texts(ledger)).contains("Rising:")

func test_narrow_layout_reflows_in_place_in_both_palettes()->void:
	var original:=Tokens.color_mode
	for mode:String in ["light","dark"]:
		Tokens.set_color_mode(mode)
		var ledger=auto_free(Ledger.new());var block:=_block();block.leader={"name":"Tovan","person_id":17};ledger.setup(block)
		add_child(ledger);ledger.size=Vector2(800,0);ledger._arrange()
		var before:Array=ledger.find_children("*","",true,false)
		assert_bool((ledger.find_child("WorkLayout",true,false) as BoxContainer).vertical).is_false()
		ledger.size=Vector2(320,0);ledger._arrange()
		for frame in 3:await get_tree().process_frame
		assert_bool((ledger.find_child("WorkLayout",true,false) as BoxContainer).vertical).is_true()
		assert_array(ledger.find_children("*","",true,false)).contains_exactly(before)
		assert_float(ledger.get_combined_minimum_size().x).is_less_equal(320.0)
		assert_float((ledger.find_child("Portrait",true,false) as Control).custom_minimum_size.y).is_equal(124.0)
		assert_str(_texts(ledger)).contains("Tovan")
	Tokens.set_color_mode(original)

func test_account_actions_and_open_detail_use_actual_balance()->void:
	var calls:Array=[];var block:=_block();block.selected="public";block.on_select=func(key:String):calls.append(key)
	var ledger=auto_free(Ledger.new());ledger.setup(block)
	assert_str(_texts(ledger)).contains("123 coins held now").contains("Common purse: 100 in every 100")
	for child in ledger.find_children("*","Button",true,false):
		if (child as Button).text=="Hide":(child as Button).pressed.emit()
	assert_array(calls).contains_exactly(["public"])
	var changed:=block.duplicate();changed.stage="weighed_metal"
	assert_bool(ledger.update_block(changed)).is_false()
