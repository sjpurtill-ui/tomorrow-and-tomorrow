extends GdUnitTestSuite
const Materials=preload("res://scripts/hud/materials_ledger.gd")
const T=preload("res://scripts/hud/hud_tokens.gd")

static func prepared_materials()->Dictionary:
	return {"city":"Ashfire","leader":{"name":"Koki"},"managed":true,"focus":"","can_direct":true,
		"storage":12.0,"capacity":80.0,"hauling":0.7,"land":"Searched land 20 in 100, held there by 2 searching. Cutting and digging ×1.00 today, ×0.75 once the change has settled in 365 days.","cover":0.2,
		"rows":[{"key":"Timber","name":"Timber","stock":12.0,"delivered":0.0,"loss":0.0,"details":["Near woodland: carrying is slow"],"points":[]},
			{"key":"Stone","name":"Stone","stock":7.0,"delivered":3.0,"loss":1.0,"details":["River stones: gathered daily"],"points":[]},
			{"key":"Copper Ore","name":"Copper ore","stock":0.0,"delivered":0.0,"loss":0.0,"details":["Rock face: tools not known"],"points":[],"blocked":true}],
		"selected":"","incoming":[],"on_map":func():pass,"on_focus":func(_focus:String):pass,"on_select":func(_key:String):pass}

func _texts(node:Node)->String:
	var words:PackedStringArray=[]
	for label:Label in node.find_children("*","Label",true,false):words.append(label.text)
	return "\n".join(words)

func test_live_readings_preserve_controls_and_reserve_source_action()->void:
	var panel=auto_free(Materials.new());var data:=prepared_materials();var calls:Array=[]
	data.on_select=func(key:String):calls.append(key)
	panel.setup(data)
	var before:Array=panel.find_children("*","",true,false)
	assert_str(_texts(panel)).contains("Choose a material").contains("7 in store").contains("+3 in · −1 lost a day").not_contains("×1.00")
	assert_str(panel._land.tooltip_text).contains("×1.00").contains("365 days")
	(panel.find_child("Material_Timber",true,false) as Button).pressed.emit()
	assert_array(calls).contains_exactly(["Timber"])
	data.rows[0].stock=17.0
	assert_bool(panel.update_block(data)).is_true()
	assert_array(panel.find_children("*","",true,false)).contains_exactly(before)
	assert_str((panel.find_child("Material_Timber",true,false) as Button).text).contains("17")
	data.selected="Timber"
	assert_bool(panel.update_block(data)).is_false()
	var opened=auto_free(Materials.new());opened.setup(data)
	assert_str(_texts(opened)).contains("Timber").contains("17 in store").contains("Near woodland: carrying is slow")

func test_source_details_and_controls_fit_narrow_in_both_palettes()->void:
	var prior:=T.color_mode
	for palette:String in ["dark","light"]:
		T.set_color_mode(palette)
		var panel=auto_free(Materials.new());var data:=prepared_materials();data.selected="Copper Ore";panel.setup(data);add_child(panel);panel.size=Vector2(320,0)
		for frame in 4:await get_tree().process_frame
		assert_float(panel.get_combined_minimum_size().x).is_less_equal(320.0)
		assert_str(_texts(panel)).contains("Rock face: tools not known")
		var calls:Array=[];data.on_focus=func(key:String):calls.append(key)
		(panel.find_child("Choice_Logistics",true,false) as Button).pressed.emit()
		assert_array(calls).contains_exactly(["logistics"])
	T.set_color_mode(prior)


static func abundant_materials()->Dictionary:
	var data:=prepared_materials();data.selected="Timber";data.browse_state={"query":"","page":0,"sources_page":0}
	for name:String in ["Clay","Fiber Plants","Iron Ore","Tin Ore","Coal","Salt","Gold Ore","Silver Ore","Oil","Sand","Limestone"]:
		data.rows.append({"key":name,"name":name,"stock":42.0,"delivered":0.0,"loss":0.0,"details":[],"points":[]})
	for index in 12:data.rows[0].details.append("Woodland %d: carrying is slow" % (index+1))
	return data

func test_bounded_inventory_search_pages_and_live_selected_detail()->void:
	var panel=auto_free(Materials.new());var data:=abundant_materials();panel.setup(data)
	assert_int(panel._rows.size()).is_equal(8)
	assert_str(_texts(panel)).contains("Near woodland").not_contains("Woodland 12")
	(panel.find_child("NextMaterials",true,false) as Button).pressed.emit()
	assert_int(panel._rows.size()).is_equal(6)
	assert_int(data.browse_state.page).is_equal(1)
	assert_str(_texts(panel)).contains("12 in store")
	var search:=panel.find_child("FindMaterial",true,false) as LineEdit
	search.text="limestone";search.text_changed.emit(search.text)
	assert_int(panel._rows.size()).is_equal(1)
	assert_str(panel._rows[0].key).is_equal("Limestone")
	assert_str(_texts(panel)).contains("12 in store")
	(panel.find_child("WhereItComesFrom",true,false) as Button).pressed.emit()
	assert_int(panel._details.size()).is_equal(8)
	assert_str(_texts(panel)).not_contains("Woodland 12")
	(panel.find_child("NextSources",true,false) as Button).pressed.emit()
	assert_int(panel._details.size()).is_equal(5)
	assert_str(_texts(panel)).contains("Woodland 12")
	data.rows[0].stock=19.0;data.rows[0].details[12]="Last woodland: now carrying freely"
	assert_bool(panel.update_block(data)).is_true()
	assert_str(_texts(panel)).contains("19 in store").contains("Last woodland: now carrying freely")
