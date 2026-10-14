extends GdUnitTestSuite
const Board=preload("res://scripts/hud/deliveries_board.gd")

func _fixture()->Dictionary:
	var data:={"day":100,"capacity":{"ready":true,"range_km":66.0,"speed_km_per_day":12.0},"shipments":[],"history":[]}
	for index in 13:
		data.shipments.append({"source_name":"Reedwater","destination_name":"Place %02d" % index,"resource":"Timber","quantity":float(index+1),"arrival_day":float(101+index)})
	for index in 11:
		data.history.append({"source_name":"Place %02d" % index,"destination_name":"Reedwater","resource":"Stone","delivered":float(index+1),"day":99-index,"status":"delivered"})
	return data

func _board(data:Dictionary)->Control:
	var board:Control=auto_free(Board.new());add_child(board);board.setup({"read":func()->Dictionary:return data});board.set_process(false);return board

func test_shipments_and_arrivals_are_bounded_and_fully_searchable()->void:
	var data:=_fixture();var before:=data.duplicate(true);var board:=_board(data)
	var ships:Node=board.find_child("ShipmentsRows",true,false);var arrivals:Node=board.find_child("ArrivalsRows",true,false)
	assert_int(ships.get_child_count()).is_equal(6)
	assert_int(arrivals.get_child_count()).is_equal(3)
	(board.find_child("NextShipments",true,false) as Button).pressed.emit();assert_int(ships.get_child_count()).is_equal(6)
	(board.find_child("NextShipments",true,false) as Button).pressed.emit();assert_int(ships.get_child_count()).is_equal(1)
	var search:=board.find_child("FindShipments",true,false) as LineEdit;search.text="Place 12";search.text_changed.emit(search.text)
	assert_int(ships.get_child_count()).is_equal(1);assert_str(_text(ships)).contains("13 timber");assert_str(_text(ships)).contains("Place 12")
	(board.find_child("EveryArrival",true,false) as Button).pressed.emit();assert_int(arrivals.get_child_count()).is_equal(6)
	assert_bool((board.find_child("Shipments",true,false) as Control).visible).is_false()
	(board.find_child("NextArrivals",true,false) as Button).pressed.emit();assert_int(arrivals.get_child_count()).is_equal(5)
	var history_search:=board.find_child("FindArrivals",true,false) as LineEdit;history_search.text="Place 10";history_search.text_changed.emit(history_search.text)
	assert_int(arrivals.get_child_count()).is_equal(1);assert_str(_text(arrivals)).contains("11 stone")
	(board.find_child("EveryArrival",true,false) as Button).pressed.emit()
	assert_bool((board.find_child("Shipments",true,false) as Control).visible).is_true()
	assert_int(arrivals.get_child_count()).is_equal(3)
	assert_str(search.text).is_equal("Place 12")
	(board.find_child("EveryArrival",true,false) as Button).pressed.emit()
	assert_str(history_search.text).is_equal("Place 10");assert_int(arrivals.get_child_count()).is_equal(1)
	assert_dict(data).is_equal(before)

func test_refresh_updates_eta_and_amount_without_losing_filter_or_page()->void:
	var data:=_fixture();var board:=_board(data)
	(board.find_child("NextShipments",true,false) as Button).pressed.emit()
	var search:=board.find_child("FindShipments",true,false) as LineEdit
	var ships:Node=board.find_child("ShipmentsRows",true,false);var first:Node=ships.get_child(0)
	board.refresh();assert_object(ships.get_child(0)).is_same(first)
	data.day=101;data.shipments[6].quantity=17.5;board.refresh()
	assert_int(int(board.on_road.page)).is_equal(1)
	assert_object(board.find_child("FindShipments",true,false)).is_same(search)
	assert_str(_text(ships)).contains("18 timber")
	assert_str((board.find_child("TravelCapacity",true,false) as Label).text).contains("66 km")
	assert_str((board.find_child("TravelCapacity",true,false) as Label).text).contains("12 km a day")
	search.text="not found";search.text_changed.emit(search.text)
	data.shipments=data.shipments.slice(0,2);board.refresh()
	assert_bool(search.visible).is_true()
	search.text="";search.text_changed.emit(search.text)
	assert_int(ships.get_child_count()).is_equal(2)

func _text(node:Node)->String:
	var words:=PackedStringArray()
	for child:Label in node.find_children("*","Label",true,false):words.append(child.text)
	return " ".join(words)
