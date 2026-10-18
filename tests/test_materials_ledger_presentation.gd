extends GdUnitTestSuite
const Materials=preload("res://scripts/hud/materials_ledger.gd")
const T=preload("res://scripts/hud/hud_tokens.gd")
const Art=preload("res://scripts/hud/materials_art.gd")
const Sheet=preload("res://scripts/hud/econ_sheet.gd")

static func prepared_materials()->Dictionary:
	return {"city":"Ashfire","leader":{"name":"Koki"},"managed":true,"focus":"","can_direct":true,
		"storage":12.0,"capacity":80.0,"hauling":0.7,"land":"Searched land 20 in 100, held there by 2 searching. Cutting and digging ×1.00 today, ×0.75 once the change has settled in 365 days.","cover":0.2,
		"rows":[{"key":"Timber","name":"Timber","stock":12.0,"delivered":0.0,"loss":0.0,"details":["Near woodland: carrying is slow"],"points":[]},
			{"key":"Stone","name":"Stone","stock":7.0,"delivered":3.0,"loss":1.0,"details":["River stones: gathered daily"],"points":[]},
			{"key":"Copper Ore","name":"Copper ore","stock":0.0,"delivered":0.0,"loss":0.0,"details":["Rock face: tools not known"],"points":[],"blocked":true}],
		"selected":"","incoming":[],"on_map":func():pass,"on_focus":func(_focus:String):pass,"on_select":func(_key:String):pass}

func _texts(node:Node)->String:
	var words:PackedStringArray=[]
	for label:Label in node.find_children("*","Label",true,false):
		if _shown_under(label,node):words.append(label.text)
	return "\n".join(words)

func _shown_under(node:Control,root:Node)->bool:
	var current:Node=node
	while current!=root and current!=null:
		if current is Control and not current.visible:return false
		current=current.get_parent()
	return true

func _tile(panel:Control,key:String)->Dictionary:
	for row:Dictionary in panel._rows:
		if String(row.key)==key:return row
	return {}

func test_live_readings_preserve_controls_and_reserve_source_action()->void:
	var panel=auto_free(Materials.new());var data:=prepared_materials();var calls:Array=[]
	data.on_select=func(key:String):calls.append(key)
	panel.setup(data)
	var before:Array=panel.find_children("*","",true,false)
	assert_str(_texts(panel)).contains("7 in store").contains("+3 in · −1 lost a day").not_contains("×1.00")
	assert_str(panel._land.tooltip_text).contains("×1.00").contains("365 days")
	(panel.find_child("Material_Timber",true,false) as Button).pressed.emit()
	assert_array(calls).contains_exactly(["Timber"])
	data.rows[0].stock=17.0
	assert_bool(panel.update_block(data)).is_true()
	assert_array(panel.find_children("*","",true,false)).contains_exactly(before)
	assert_str(String(_tile(panel,"Timber").stock.text)).contains("17")
	data.selected="Timber"
	assert_bool(panel.update_block(data)).is_true()
	assert_array(panel.find_children("*","",true,false)).contains_exactly(before)
	assert_str(_texts(panel)).contains("Timber").contains("17 in store").contains("Near woodland: carrying is slow")

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
	for name:String in ["Clay","Fiber Plants","Iron Ore","Tin Ore","Coal","Salt","Gold Ore","Silver Ore","Crude Oil","Fine Sand","Limestone"]:
		data.rows.append({"key":name,"name":name,"stock":42.0,"delivered":0.0,"loss":0.0,"details":[],"points":[]})
	for index in 12:data.rows[0].details.append("Woodland %d: carrying is slow" % (index+1))
	return data

func test_bounded_inventory_search_pages_and_live_selected_detail()->void:
	var panel=auto_free(Materials.new());var data:=abundant_materials();panel.setup(data)
	var nodes:Array=panel.find_children("*","",true,false)
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
	assert_array(panel.find_children("*","",true,false)).contains_exactly(nodes)
	assert_str(String(data.browse_state.query)).is_equal("limestone")
	assert_int(int(data.browse_state.sources_page)).is_equal(1)

func test_all_catalogue_art_and_unknown_saved_stock_remain_available()->void:
	var known:Array=[]
	for key:String in ResourceSystem.catalog:
		if key not in Materials.ELSEWHERE:known.append(key)
	assert_int(known.size()).is_equal(34)
	var generic:Texture2D=Art.texture_for("Retained imported specimen")
	assert_object(generic).is_not_null()
	var generic_id:=_art_identity(generic)
	var pictured:Dictionary={}
	for key:String in known:
		var picture:Texture2D=Art.texture_for(key)
		assert_object(picture).is_not_null()
		if picture!=null:
			assert_int(picture.get_width()).is_greater(0)
			assert_int(picture.get_height()).is_greater(0)
			var identity:=_art_identity(picture)
			assert_str(identity).is_not_equal(generic_id)
			assert_bool(pictured.has(identity)).is_false()
			pictured[identity]=key
	var data:=prepared_materials();data.selected="Retained imported specimen"
	data.rows.append({"key":data.selected,"name":data.selected,"stock":4.0,"delivered":0.0,"loss":0.0,"details":[],"points":[]})
	var panel=auto_free(Materials.new());panel.setup(data)
	assert_str(_texts(panel)).contains("Retained imported specimen").contains("4 in store")
	# A held/imported item without a local occurrence is not an undiscovered item.
	assert_str(_texts(panel).to_lower()).not_contains("scouts and surveys find")

func _art_identity(texture:Texture2D)->String:
	if texture==null:return "missing"
	var image:=texture.get_image()
	if image==null:return "unreadable"
	return "%dx%d:%d" % [image.get_width(),image.get_height(),hash(image.get_data())]

func test_catalogue_paging_preserves_exact_keys_and_display_names()->void:
	var data:=prepared_materials();data.rows=[];data.selected="Copper Ore";data.browse_state={}
	for key:String in ResourceSystem.catalog:
		data.rows.append({"key":key,"name":preload("res://scripts/resource_names.gd").label(key,[]),"stock":3.0,"delivered":0.0,"loss":0.0,"details":[],"points":[]})
	for key:String in ["Food","Civilian Goods"]:
		data.rows.append({"key":key,"name":key,"stock":9.0,"delivered":20.0,"loss":1.0,"details":[],"points":[]})
	var panel=auto_free(Materials.new());panel.setup(data)
	var nodes:Array=panel.find_children("*","",true,false)
	var seen:Dictionary={}
	for page in 5:
		assert_int(panel._rows.size()).is_less_equal(8)
		for row:Dictionary in panel._rows:
			assert_bool(String(row.key) in Materials.ELSEWHERE).is_false()
			seen[String(row.key)]=true
			if row.key=="Fiber Plants":assert_str(String(row.label.text)).is_equal("Plant Fiber")
		if page<4:(panel.find_child("NextMaterials",true,false) as Button).pressed.emit()
	assert_int(seen.size()).is_equal(34)
	assert_str(String(panel._selection.name.text)).is_equal("Green-stained Stone")
	assert_array(panel.find_children("*","",true,false)).contains_exactly(nodes)

func test_weighted_storage_gross_arrivals_losses_and_unknown_carry_stay_distinct()->void:
	var data:=prepared_materials();data.storage=23.1;data.capacity=10.0;data.hauling=null
	data.rows[0].stock=10.0;data.rows[0].delivered=7.0;data.rows[0].loss=3.0
	data.rows[1].stock=5.0;data.rows[1].delivered=4.0;data.rows[1].loss=2.0
	data.rows.append({"key":"Food","name":"Food","stock":1000.0,"delivered":999.0,"loss":999.0,"details":[],"points":[]})
	var panel=auto_free(Materials.new());panel.setup(data)
	var readings:Array=Materials.kpi_items(data)
	assert_str(String(readings[0].value)).is_equal(Sheet.n(23.1))
	assert_float(float(readings[0].ratio)).is_equal(1.0)
	assert_str(String(readings[0].sub)).contains("2.3")
	assert_str(String(readings[1].value)).is_equal("+11")
	assert_str(String(readings[1].sub)).contains("5")
	assert_str(String(panel._readings.carry.value.text)).contains("—").not_contains("0%")
	data.hauling=0.0
	assert_bool(panel.update_block(data)).is_true()
	assert_str(String(panel._readings.carry.value.text)).contains("0%")

func test_blocked_spent_and_empty_arriving_materials_are_not_interchanged()->void:
	var data:=prepared_materials();data.selected="Copper Ore"
	var panel=auto_free(Materials.new());panel.setup(data)
	assert_str(_texts(panel)).contains("tools not known")
	data.rows[2].details=["Rock face: worked out; nothing left to take"]
	data.rows[2].blocked=false
	assert_bool(panel.update_block(data)).is_true()
	assert_str(_texts(panel)).contains("worked out; nothing left to take").not_contains("tools not known")
	data.rows[2].delivered=4.0;data.rows[2].details=["Imported shipment: arrived today"]
	assert_bool(panel.update_block(data)).is_true()
	assert_str(String(panel._selection.stock.text)).contains("0 in store")
	assert_str(String(panel._selection.reading.text)).contains("+4 in")
	assert_bool(Materials.out_of_reach(data.rows[2])).is_false()
	assert_bool(Materials.empty(data.rows[2])).is_true()

func test_live_callback_replacement_and_reading_do_not_issue_actions()->void:
	var calls:Array[String]=[]
	var data:=prepared_materials()
	data.on_assign=func():calls.append("old extraction")
	data.on_assign_carriers=func():calls.append("old carriers")
	data.on_map=func():calls.append("old map")
	data.on_trade=func():calls.append("old deliveries")
	data.on_focus=func(_focus:String):calls.append("old focus")
	data.on_select=func(_key:String):calls.append("old selection")
	var panel=auto_free(Materials.new());panel.setup(data)
	var controls:Array=panel.find_children("*","",true,false)
	assert_array(calls).is_empty()
	var fresh:=data.duplicate(true);fresh.leader={"name":"New keeper"};fresh.managed=false;fresh.focus="logistics"
	fresh.rows.append({"key":"Retained imported specimen","name":"Retained imported specimen","stock":4.0,"delivered":0.0,"loss":0.0,"details":[],"points":[]})
	fresh.on_assign=func():calls.append("extraction")
	fresh.on_assign_carriers=func():calls.append("carriers")
	fresh.on_map=func():calls.append("map")
	fresh.on_trade=func():calls.append("deliveries")
	fresh.on_focus=func(focus:String):calls.append("focus:"+focus)
	fresh.on_select=func(key:String):calls.append("select:"+key)
	var unchanged:=fresh.duplicate(true)
	assert_bool(panel.update_block(fresh)).is_true()
	# Browsing is intentional UI state; the supplied readings are immutable.
	var after:=fresh.duplicate(true);after.erase("browse_state");unchanged.erase("browse_state")
	assert_dict(after).is_equal(unchanged)
	assert_array(panel.find_children("*","",true,false)).contains_exactly(controls)
	assert_array(calls).is_empty()
	for name:String in ["AssignExtractionWorkers","AssignLogisticsWorkers","Choice_Logistics"]:
		(panel.find_child(name,true,false) as Button).pressed.emit()
	for button:Button in panel.find_children("*","Button",true,false):
		if button.text=="Show on map":button.pressed.emit()
	(panel.find_child("Material_Timber",true,false) as Button).pressed.emit()
	(panel.find_child("MaterialDeliveries",true,false) as Button).pressed.emit()
	(panel.find_child("Choice_",true,false) as Button).pressed.emit()
	assert_array(calls).contains_exactly(["extraction","carriers","focus:logistics","map","select:Timber","deliveries","focus:"])

func test_protected_materials_can_exceed_stock_without_negative_free_amount()->void:
	var panel=auto_free(Materials.new());var data:=prepared_materials()
	data.rows[0].protected=20.0;data.selected="Timber"
	panel.setup(data)
	assert_bool(panel._selection.coverage.visible).is_true()
	assert_str(panel._selection.free.text).contains("Free to use: 0").contains("Missing for work: 8")
	var original=panel._selection.coverage
	data.rows[0].stock=30.0;panel.update_block(data)
	assert_object(panel._selection.coverage).is_same(original)
	assert_str(panel._selection.free.text).contains("Free to use: 10").contains("Missing for work: 0")
