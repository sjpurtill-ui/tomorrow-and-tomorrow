extends GdUnitTestSuite
const Tile=preload("res://scripts/hud/comparison_tile.gd")
const Board=preload("res://scripts/hud/buildings_board.gd")

func test_pair_uses_shared_scale_and_does_not_chart_unknown_or_negative_values()->void:
	var tile=auto_free(Tile.new())
	tile.fill("Food","NEED",100.0,"HAVE",25.0,"rations")
	assert_float(tile.bars[0].max_value).is_equal(100.0)
	assert_float(tile.bars[1].max_value).is_equal(100.0)
	assert_float(tile.bars[1].value).is_equal(25.0)
	tile.fill("Food","NEED",100.0,"HAVE","Unknown","rations")
	assert_bool(tile.bars[1].visible).is_false()
	assert_str(tile.values[1].text).is_equal("Unknown")
	tile.fill("Change","BEFORE",-2.0,"AFTER",3.0)
	assert_bool(tile.bars[0].visible).is_false()

func test_building_categories_are_direct_and_selection_keeps_real_action()->void:
	var clicked:Array=[]
	var state:={}
	var board=auto_free(Board.new())
	board.setup({"view_state":state,"sections":[{"id":"homes","heading":"Homes"},{"id":"stores","heading":"Stores"}],"cards":[
		{"key":"home","section":"homes","name":"Homes","gains":[{"label":"Places","before":"30","after":"50"}]},
		{"key":"store","section":"stores","name":"Dry stores","needs":[{"resource":"Timber","have":2.0,"need":8.0}],"actions":[{"label":"Build","on_press":func():clicked.append("store")}]}]})
	assert_int(board.find_children("*","OptionButton",true,false).size()).is_equal(0)
	(board.category.get_node("Section_stores") as Button).pressed.emit()
	assert_str(String(state.section)).is_equal("stores")
	var need=board.find_child("Need",true,false)
	assert_float(float(need.get_meta("left"))).is_equal(2.0)
	assert_float(float(need.get_meta("right"))).is_equal(8.0)
	(board.find_child("Act_Build",true,false) as Button).pressed.emit()
	assert_array(clicked).contains_exactly(["store"])
