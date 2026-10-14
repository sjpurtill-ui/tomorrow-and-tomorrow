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

func test_strip_reads_real_goods_and_equal_household_groups()->void:
	var board:=_board()
	var held:=Standing.wealth_held()
	var strip:Array=Board.kpis()
	assert_str(String(strip[0].value)).is_equal(preload("res://scripts/hud/era_words.gd").grouped(roundi(float(held.goods))))
	var spare:=float(String(strip[1].value).replace(",",""))
	assert_float(spare).is_between(0.0,float(held.goods))
	var fifths:Control=board.find_child("Fifths",true,false)
	assert_array(fifths.values).is_equal(Array(GameState.wealth_shares))
	assert_str(String(strip[0].delta)).is_equal("Worth 400 rations")
	# The common store is on Wealth, counted in goods; its figure is said once.
	assert_str((board.find_child("StoreAnswer",true,false) as Label).text).ends_with(" goods")

func test_material_price_change_refreshes_buying_power_without_rebuilding_neighbors()->void:
	var board:=_board()
	var making_id:=board.find_child("Fifths",true,false).get_instance_id()
	var buy:Label=board.find_child("GoodsBuy",true,false)
	assert_str(buy.tooltip_text).contains("200 timber")
	GameState.market_prices["Timber"]=4.0
	board.refresh()
	assert_str((board.find_child("GoodsBuy",true,false) as Label).tooltip_text).contains("100 timber")
	assert_str(String(Board.kpis()[0].delta)).is_equal("Worth 400 rations")
	assert_int(board.find_child("Fifths",true,false).get_instance_id()).is_equal(making_id)
	await await_idle_frame()

func test_unchanged_refresh_retains_the_strip_and_no_box_opens_another_screen()->void:
	var board:=_board()
	var ids:Array=[]
	for key:String in ["GoodsBuy","Fifths","StoreAnswer"]:ids.append(board.find_child(key,true,false).get_instance_id())
	for i in 5:board.refresh()
	for i in ids.size():assert_int(board.find_child(["GoodsBuy","Fifths","StoreAnswer"][i],true,false).get_instance_id()).is_equal(ids[i])
	# Arms, materials and trade have their own tabs: no box leads away to them.
	for key:String in ["SeeArms","SeeMaterials","SeeTrade","SeeStore"]:assert_object(board.find_child(key,true,false)).is_null()
	assert_object(board.find_child("Balance",true,false)).is_not_null()

func test_scroll_width_reflows_the_columns_and_the_strip()->void:
	var scroll:ScrollContainer=auto_free(ScrollContainer.new())
	scroll.size=Vector2(1100,700);add_child(scroll)
	var board:=Board.new();scroll.add_child(board);board.setup({})
	board.size.x=1000;board._responsive()
	var columns:GridContainer=board.find_child("WealthColumns",true,false)
	assert_int(columns.columns).is_equal(2)
	scroll.size.x=420;board._responsive()
	assert_int(columns.columns).is_equal(1)
