extends GdUnitTestSuite
## Records a save carries are kept to what the screens and rules read
## (economy_system.gd slim_history_entry, resource_system.gd
## normalize_shipments, save_trim.gd on load).
const Economy:=preload("res://scripts/economy_system.gd")
const Resources:=preload("res://scripts/resource_system.gd")

func _entry(day:int)->Dictionary:
	return {"day":day,"stage":"currency","price_index":1.0+day*0.001,"treasury":10.0+day,"currency_hoards":2.0,"metal_circulation":0.0,
		"output_per_capita":1.5,"inflation":0.01,"prices":{"Timber":1.0,"Stone":2.0},"fiscal_status":"balanced"}

func test_an_old_economy_entry_keeps_only_what_is_charted()->void:
	var slim:=Economy.slim_history_entry(_entry(5))
	assert_array(slim.keys()).contains_exactly_in_any_order(["day","stage","price_index","treasury","currency_hoards","metal_circulation","output_per_capita"])
	assert_float(float(slim.treasury)).is_equal(15.0)
	# Already slim: the same entry back.
	assert_dict(Economy.slim_history_entry(slim)).is_equal(slim)

func test_the_last_entries_the_rules_read_stay_whole()->void:
	var history:Array=[]
	for day in 200:history.append(_entry(day))
	Economy.slim_history(history)
	assert_int(history.size()).is_equal(200)
	for index in 200:
		var whole:=index>=200-Economy.HISTORY_DETAIL_ENTRIES
		assert_bool((history[index] as Dictionary).has("prices")).is_equal(whole)
		assert_int(int(history[index].day)).is_equal(index)
	# The rules read 30 entries back at most (market volatility and trends).
	assert_int(Economy.HISTORY_DETAIL_ENTRIES).is_greater_equal(30)

func test_older_loads_become_compact_in_order_of_arrival()->void:
	var deposit:={"shipments":[{"quantity":1.0,"departure_day":1,"arrival_day":9},{"quantity":2.0,"departure_day":2,"arrival_day":7},{"quantity":3.0,"departure_day":3,"arrival_day":9},{"quantity":4.0,"departure_day":4,"arrival_day":8}]}
	Resources.normalize_shipments(deposit)
	# By arrival; loads due the same day keep the order they were sent.
	assert_array(deposit.shipments).is_equal([[7,2.0],[8,4.0],[9,1.0],[9,3.0]])
	assert_float(float(deposit.in_transit)).is_equal(10.0)
	# The total of what is on the road reads the same either way.
	assert_float(ResourceSystem.in_transit_for(deposit)).is_equal(10.0)
