extends GdUnitTestSuite
## Direct city scouting orders from the scouting window and the docks.
const Orders=preload("res://scripts/hud/city_watch_orders.gd")
const Sheet=preload("res://scripts/hud/scouting_policy_panel.gd")
const ForeignCity=preload("res://scripts/hud/content/dock_detail_foreign_city.gd")
var viewport:SubViewport

func before_test()->void:
	WorldSimulation.clear()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	GameState.reset_for_new_world(424242);ProgressionSystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world();FoodSystem.reset_for_new_world()
	GameState.ensure_population_total(300);GameState.settlement_site_committed=true
	GameState.resource_stockpiles.Food=10000.0;GameState.food_stocks={"Preserved food":10000.0}
	CivilizationSystem.reset_for_new_world();CivilizationSystem.register_player_origin(Vector2.ZERO)
	CivilizationSystem.set_scout_geography_authority(func(_point:Vector2)->bool:return true)
	CivilizationSystem.initialize()
	Orders.remembered.clear();Orders.quote_cache.clear();Orders.last_result.clear()
	CivilizationSystem.city_intelligence.records.player={
		"far":_city("far","Farhold","rival",90.0),
		"near":_city("near","Nearbrook","rival",30.0),
		"ours":_city("ours","Our Town","player",10.0)}

func after_test()->void:
	if is_instance_valid(viewport):viewport.queue_free();await await_idle_frame()
	CivilizationSystem.scout_missions.clear()
	GameState.set_process(true);CivilizationSystem.set_process(true);MilitaryCampaign.set_process(true)

func _city(id:String,name:String,civ:String,x:float)->Dictionary:
	return {"city_id":id,"name":name,"civ_id":civ,"controller":civ,"position":{"x":x,"z":0.0},"observed_day":0,"reported_day":0,"quality":.5,"source":"physical visit","reference":"test","fields":{"population":{"low":120.0,"high":160.0,"observed_day":0,"quality":.5,"source":"physical visit","reference":"test"}}}

func _sheet()->Control:
	viewport=SubViewport.new();viewport.size=Vector2i(960,900);add_child(viewport)
	var sheet:Control=Sheet.new();viewport.add_child(sheet)
	await await_idle_frame();await await_idle_frame()
	return sheet

func test_rival_cities_skip_our_own_and_come_nearest_first()->void:
	var ids:Array=Orders.rival_cities().map(func(city:Dictionary)->String:return String(city.city_id))
	assert_array(ids).is_equal(["near","far"])
	var defaults:=Orders.defaults("near")
	assert_int(int(defaults.personnel)).is_equal(4)
	assert_bool(int(defaults.days) in CivilizationSystem.SCOUT_DURATIONS).is_true()

func test_send_once_uses_dispatch_scouts_with_the_chosen_party()->void:
	var quote:Dictionary=CivilizationSystem.scout_mission_quote(30,"city:near","",5)
	assert_bool(bool(quote.can_dispatch)).is_true()
	var food:=FoodSystem.total_stored()
	var result:=Orders.send_once("near",30,5)
	assert_bool(result.has("ok")).is_true()
	assert_int(CivilizationSystem.scout_missions.size()).is_equal(1)
	var mission:Dictionary=CivilizationSystem.scout_missions[0]
	assert_str(String(mission.target_id)).is_equal("city:near")
	assert_int(int(mission.personnel)).is_equal(5)
	assert_int(int(mission.duration_days)).is_equal(int(quote.duration_days))
	assert_float(FoodSystem.total_stored()).is_less(food)
	# No standing watch is created by a single campaign.
	assert_dict(CivilizationSystem.scouting_staff.city_watch("near")).is_empty()
	assert_str(Orders.status_text("near")).contains("5 scouts away")
	# The next order for this city starts from the same choice.
	assert_int(int(Orders.defaults("near").personnel)).is_equal(5)

func test_keep_and_stop_watching_use_set_city_watch()->void:
	assert_bool(Orders.keep_watching("far",90,6).has("ok")).is_true()
	var watch:=CivilizationSystem.scouting_staff.city_watch("far")
	assert_bool(bool(watch.enabled)).is_true()
	assert_int(int(watch.duration_days)).is_equal(90)
	assert_int(int(watch.personnel)).is_equal(6)
	assert_array(CivilizationSystem.scout_missions).is_empty()
	assert_str(Orders.status_text("far")).starts_with("Watched")
	assert_int(int(Orders.defaults("far").days)).is_equal(90)
	Orders.stop_watching("far")
	assert_dict(CivilizationSystem.scouting_staff.city_watch("far")).is_empty()

func test_limits_give_plain_reasons()->void:
	assert_int(Orders.clamp_party(1)).is_equal(2)
	assert_int(Orders.clamp_party(12)).is_equal(8)
	assert_str(Orders.watch_block_reason("nowhere")).contains("reported city")
	for index in 6:
		var id:="extra%d" % index
		CivilizationSystem.city_intelligence.records.player[id]=_city(id,"Extra %d" % index,"rival",40.0+index)
		assert_bool(Orders.keep_watching(id,30,4).has("ok")).is_true()
	assert_str(Orders.watch_block_reason("near")).contains("Six cities")
	assert_str(Orders.watch_block_reason("extra0")).is_empty()
	var blocked:=Orders.row(Orders.world().city_intelligence.known("player","near"),30,4)
	assert_str(String(blocked.watch_blocked)).contains("Six cities")
	# A party too small for the stores, or a trip too short for the distance, is refused with the reason.
	GameState.resource_stockpiles.Food=1.0;GameState.food_stocks={"Preserved food":1.0}
	Orders.quote_cache.clear()
	var hungry:=Orders.row(Orders.world().city_intelligence.known("player","near"),30,4)
	assert_str(String(hungry.once_blocked)).contains("Food")

func test_a_city_beyond_reach_disables_both_orders_with_the_reason()->void:
	CivilizationSystem.city_intelligence.records.player["remote"]=_city("remote","Remote","rival",20000.0)
	var model:=Orders.row(Orders.world().city_intelligence.known("player","remote"),365,4)
	assert_str(String(model.once_blocked)).contains("Out of reach")
	assert_str(String(model.watch_blocked)).is_equal(String(model.once_blocked))
	var items:=Orders.dock_items("remote")
	assert_bool(bool(items[0].disabled)).is_true()
	assert_bool(bool(items[1].disabled)).is_true()

func test_scouting_window_lists_cities_and_orders_from_the_row()->void:
	var sheet:Control=await _sheet()
	assert_bool(sheet.city_rows.has("near")).is_true()
	assert_bool(sheet.city_rows.has("far")).is_true()
	assert_bool(sheet.city_rows.has("ours")).is_false()
	var row:Dictionary=sheet.city_rows.near
	assert_str(row.name.text).is_equal("Nearbrook")
	assert_str(row.meta.text).contains("120–160 people")
	assert_str(row.count.text).is_equal("4 scouts")
	row.plus.pressed.emit()
	assert_str(row.count.text).is_equal("5 scouts")
	row.days[90].pressed.emit()
	assert_bool(row.days[90].button_pressed).is_true()
	assert_str(row.cost.text).contains("5 scouts away for")
	assert_str(row.risk.text).contains("Road danger")
	row.keep.pressed.emit()
	var watch:=CivilizationSystem.scouting_staff.city_watch("near")
	assert_int(int(watch.personnel)).is_equal(5)
	assert_int(int(watch.duration_days)).is_equal(90)
	assert_str(row.status.text).is_equal("Watched")
	assert_bool(row.stop.visible).is_true()
	assert_bool(row.keep.visible).is_false()
	assert_str(sheet.cities_note.text).contains("1 of 6 watched")
	row.stop.pressed.emit()
	assert_dict(CivilizationSystem.scouting_staff.city_watch("near")).is_empty()
	sheet.city_rows.far.once.pressed.emit()
	assert_int(CivilizationSystem.scout_missions.size()).is_equal(1)
	assert_str(String(CivilizationSystem.scout_missions[0].target_id)).is_equal("city:far")
	assert_str(sheet.city_rows.far.status.text).is_equal("Party away")

func test_scouting_window_shows_disabled_reasons()->void:
	for index in 6:
		var id:="extra%d" % index
		CivilizationSystem.city_intelligence.records.player[id]=_city(id,"Extra %d" % index,"rival",40.0+index)
		Orders.keep_watching(id,30,4)
	var sheet:Control=await _sheet()
	var row:Dictionary=sheet.city_rows.near
	assert_bool(row.keep.disabled).is_true()
	assert_str(row.note.text).contains("Six cities")
	for i in 8:row.minus.pressed.emit()
	assert_str(row.count.text).is_equal("2 scouts")
	assert_bool(row.minus.disabled).is_true()

func test_empty_window_explains_where_cities_come_from()->void:
	CivilizationSystem.city_intelligence.records.player={}
	var sheet:Control=await _sheet()
	assert_bool(sheet.cities_empty.visible).is_true()
	assert_int(sheet.city_rows.size()).is_equal(0)

func test_foreign_city_dock_offers_both_orders()->void:
	var provider=ForeignCity.new(null,null,"near")
	var blocks:Array=provider.tab(0).blocks
	var scouting:Dictionary={}
	for block:Dictionary in blocks:
		if String(block.get("heading",""))=="SCOUT THIS CITY":scouting=block
	assert_dict(scouting).is_not_empty()
	var labels:Array=scouting.items.map(func(item:Dictionary)->String:return String(item.label))
	assert_array(labels).is_equal(["Send scouts once","Keep watching"])
	(scouting.items[1].on_press as Callable).call()
	assert_bool(bool(CivilizationSystem.scouting_staff.city_watch("near").enabled)).is_true()
	blocks=provider.tab(0).blocks
	for block:Dictionary in blocks:
		if String(block.get("heading",""))=="SCOUT THIS CITY":scouting=block
	assert_str(String(scouting.items[1].label)).is_equal("Stop watching")
	(scouting.items[0].on_press as Callable).call()
	assert_int(CivilizationSystem.scout_missions.size()).is_equal(1)
	assert_array(Orders.dock_items("ours")).is_empty()
