extends GdUnitTestSuite
const Board:=preload("res://scripts/hud/purse_board.gd")
const Fixtures:=preload("res://tests/court_eval/fixtures.gd")
const Standing:=preload("res://scripts/standing.gd")
var fixture:Fixtures

func before_test()->void:
	fixture=Fixtures.new(self)
	fixture.base(false)
	GameState.realm_purse={}
	GameState.economy_stage="subsistence"
	GameState.resource_stockpiles["Civilian Goods"]=100.0
	GameState.market_prices={"Civilian Goods":4.0,"Food":1.0,"Timber":2.0,"Stone":3.0,"Fiber Plants":1.0}
	GameState.economy_metrics["price_observations"]=1

func after_test()->void:
	WorldSimulation.clear()
	WorldSimulation.context_provider=Callable()

func _board()->Control:
	var board:Control=auto_free(Board.new())
	add_child(board)
	board.setup({"mode":"wealth","on_open":func(_section:String,_sub:int):pass})
	return board

func test_graphical_readings_use_real_goods_and_equal_household_groups()->void:
	var board:=_board()
	var held:=Standing.wealth_held()
	var ring:Control=board.find_child("GoodsAvailability",true,false)
	assert_float(float(ring.values[1])).is_equal(float(held.goods))
	assert_float(float(ring.values[0])).is_between(0.0,float(held.goods))
	var fifths:Control=board.find_child("Fifths",true,false)
	assert_array(fifths.values).is_equal(Array(GameState.wealth_shares))
	assert_str((board.find_child("GoodsValue",true,false) as Label).text).is_equal("Worth 400 rations")
	# The common store is on Wealth, counted in goods.
	assert_str((board.find_child("StoreAnswer",true,false) as Label).text).ends_with(" goods")

func test_material_price_change_refreshes_buying_power_without_rebuilding_neighbors()->void:
	var board:=_board()
	var making_id:=board.find_child("GoodsMade",true,false).get_instance_id()
	var buy:Label=board.find_child("GoodsBuy",true,false)
	assert_str(buy.tooltip_text).contains("200 timber")
	GameState.market_prices["Timber"]=4.0
	board.refresh()
	assert_str((board.find_child("GoodsBuy",true,false) as Label).tooltip_text).contains("100 timber")
	assert_str((board.find_child("GoodsValue",true,false) as Label).text).is_equal("Worth 400 rations")
	assert_int(board.find_child("GoodsMade",true,false).get_instance_id()).is_equal(making_id)
	await await_idle_frame()

func test_unchanged_refresh_retains_visual_nodes_and_navigation_works()->void:
	var destinations:Array=[]
	var board:=_board()
	board.on_open=func(section:String,sub:int):destinations.append([section,sub])
	var ids:Array=[]
	for key:String in ["GoodsHeld","GoodsAvailability","Fifths","MakingIllustration"]:ids.append(board.find_child(key,true,false).get_instance_id())
	for i in 5:board.refresh()
	for i in ids.size():assert_int(board.find_child(["GoodsHeld","GoodsAvailability","Fifths","MakingIllustration"][i],true,false).get_instance_id()).is_equal(ids[i])
	GameState.resource_stockpiles["Timber"]+=10.0
	board.refresh()
	assert_int(board.find_child("GoodsHeld",true,false).get_instance_id()).is_equal(ids[0])
	assert_int(board.find_child("GoodsAvailability",true,false).get_instance_id()).is_equal(ids[1])
	for key:String in ["SeeArms","SeeMaterials","SeeTrade"]:(board.find_child(key,true,false) as Button).emit_signal("pressed")
	assert_array(destinations).is_equal([["production",2],["economy",1],["economy",3]])
	# The common store is on Wealth itself, in goods: no link away to Food & water.
	assert_object(board.find_child("SeeStore",true,false)).is_null()
	assert_object(board.find_child("Balance",true,false)).is_not_null()

func test_scroll_width_reflows_existing_cards_without_stale_wide_minimum()->void:
	var scroll:ScrollContainer=auto_free(ScrollContainer.new())
	scroll.size=Vector2(1100,700);add_child(scroll)
	var board:=Board.new();scroll.add_child(board);board.setup({})
	board.size.x=1000;board._responsive()
	var cards:GridContainer=board.find_child("WealthCards",true,false)
	assert_int(cards.columns).is_equal(3)
	scroll.size.x=420;board._responsive()
	assert_int(cards.columns).is_equal(1)
	assert_int((board.find_child("GoodsOverview",true,false) as GridContainer).columns).is_equal(1)
	assert_int((board.find_child("WealthSociety",true,false) as GridContainer).columns).is_equal(1)
