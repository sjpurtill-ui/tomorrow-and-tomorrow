extends GdUnitTestSuite
const Needs:=preload("res://scripts/needs_driven_trade.gd")
const Ledger:=preload("res://scripts/trade_ledger.gd")
const Stores:=preload("res://scripts/storage_works.gd")
const Goods:=preload("res://scripts/civilian_goods.gd")
var seller:String

func before_test()->void:
	WorldSimulation.clear();GameState.reset_for_new_world(31337);ForeignDiplomacy.reset_for_new_world();CivilizationSystem.reset_for_new_world()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	CivilizationSystem.civilizations.assign(CivilizationSystem.civilizations.slice(0,1))
	CivilizationSystem.scout_land_authority=func(_at:Vector2)->bool:return true
	WorldSimulation.context_provider=func(_origin:Vector2)->Dictionary:return {"environment_profile":PlanetEnvironment.profile_at(Vector2.ZERO),"surface_water_distance_km":.1,"surface_water_recognized":true}
	WorldSimulation.start_world()
	seller=String(CivilizationSystem.civilizations[0].id)
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	civ.world_position=Vector2(24,0);civ.position=Vector2(24.0/CivilizationSystem.CIVILIZATION_WORLD_RADIUS_X_KM,0)
	for region:Dictionary in civ.get("strategic_regions",[]):
		if region.get("role","")=="capital":region.position=Vector2(24,0)
	civ.alive=true;civ.player_relation.contact_level=2;civ.player_relation.home_location_known=true;civ.player_relation.opinion=.2
	CivilizationSystem.player_world_origin=Vector2.ZERO
	for owner:String in ["player",seller]:
		WorldSimulation.scoped(owner,func():
			var st=WorldSimulation.state
			st.ensure_population_total(120);st.settlement_site_committed=true;st.convoy_traveling=false
			st.settlement_completed.assign(["Hearth Circle","Lean-to Shelters","Storage Pits","Open Work Area","Gathering Yard"])
			st.resource_stockpiles={"Timber":0.0,"Fiber Plants":0.0,"Clay":0.0,"Stone":0.0}
			st.food_stocks={"Fresh food":0.0,"Stored food":1000.0 if owner==seller else 5000.0}
			st.founding_manifest.food_storage_rations=10000.0
			st.storage_works={}
			for item:String in ["Food","Timber","Fiber Plants"]:st.economy_known_goods[item]=true
			Stores.queue("dry")
		)
	WorldSimulation.scoped(seller,func():WorldSimulation.state.resource_stockpiles.Timber=80.0)
	Ledger._discover_pairs(0)

func after_test()->void:
	WorldSimulation.clear();WorldSimulation.context_provider=Callable();CivilizationSystem.scout_land_authority=Callable();ForeignDiplomacy.reset_for_new_world()
	GameState.set_process(true);CivilizationSystem.set_process(true);MilitaryCampaign.set_process(true)

func held(owner:String,item:String)->float:
	return WorldSimulation.scoped(owner,func():return Ledger._held_in_scope(item))

func quote()->Dictionary:return Needs.terms("player",seller,"Timber","Food",8.0)

func test_early_barter_reserves_real_supplies_and_delivers_once_after_journey()->void:
	var t:=quote()
	assert_bool(bool(t.ok)).override_failure_message(str(t)).is_true()
	if not t.ok:return
	var our_food:=held("player","Food");var their_food:=held(seller,"Food")
	var their_wood:=held(seller,"Timber");var our_wood:=held("player","Timber")
	var result:=Needs.send(t)
	assert_bool(result.has("ok")).is_true()
	assert_float(held("player","Food")).is_equal_approx(our_food-float(t.payment),.001)
	assert_float(held(seller,"Timber")).is_equal_approx(their_wood-float(t.count),.001)
	assert_float(held("player","Timber")).is_equal(our_wood)
	Needs.advance(int(t.days)-1)
	assert_float(held("player","Timber")).is_equal(our_wood)
	Needs.advance(int(t.days));Needs.advance(int(t.days)+1)
	assert_float(held("player","Timber")).is_equal_approx(our_wood+float(t.count),.001)
	assert_float(held(seller,"Food")).is_equal_approx(their_food+float(t.payment),.001)
	assert_str(String(Ledger.peek().barter_shipments[0].status)).is_equal("delivered")

func test_offer_names_the_building_and_protects_both_towns_commitments()->void:
	var offers:=Needs.offers("player",seller)
	assert_array(offers).is_not_empty()
	if offers.is_empty():return
	assert_str(String(offers[0].purpose)).is_equal("Expand dry stores")
	assert_str(String(offers[0].give)).is_equal("Food")
	assert_float(float(offers[0].remaining)).is_greater_equal(GameState.population_exact*30)
	assert_float(held(seller,"Timber")-float(offers[0].count)).is_greater_equal(8.0)

func test_no_generic_currency_before_one_thousand_but_household_crafting_remains()->void:
	assert_float(Goods.ceiling()).is_equal_approx(Goods.target()*1.2+Goods.capital_reserve(),.0001)
	GameState.resource_stockpiles["Civilian Goods"]=1000.0
	var t:=Needs.terms("player",seller,"Timber","Civilian Goods",8.0)
	assert_bool(bool(t.ok)).is_false()
	assert_str(String(t.why)).contains("Small settlements")
	GameState.ensure_population_total(1000)
	assert_float(Goods.ceiling()).is_greater(Goods.target()*1.2+Goods.capital_reserve())

func test_route_closure_returns_both_actual_loads()->void:
	var t:=quote();assert_bool(bool(t.ok)).is_true()
	if not t.ok:return
	var wood:=held(seller,"Timber");var food:=held("player","Food")
	Needs.send(t)
	CivilizationSystem.civilizations[0].player_relation.home_location_known=false
	Needs.advance(int(t.days))
	assert_float(held(seller,"Timber")).is_equal_approx(wood,.001)
	assert_float(held("player","Food")).is_equal_approx(food,.001)
	assert_str(String(Ledger.peek().barter_shipments[0].status)).is_equal("returned")

func test_full_destination_and_in_transit_loads_cannot_overbook_storage()->void:
	var cap:=Stores.capacities()
	GameState.resource_stockpiles.Stone=float(cap.yard)/1.65
	assert_bool(bool(quote().ok)).is_false()
	GameState.resource_stockpiles.Stone=0.0
	var t:=quote();assert_bool(bool(t.ok)).is_true()
	if not t.ok:return
	Needs.send(t)
	assert_float(Needs.incoming("player","Timber")).is_equal(float(t.count))
	assert_float(float(quote().get("count",0))).is_less_equal(maxf(0,8-float(t.count)))

func test_changed_stocks_reject_stale_offer_without_payment()->void:
	var t:=quote();assert_bool(bool(t.ok)).is_true()
	if not t.ok:return
	WorldSimulation.scoped(seller,func():WorldSimulation.state.resource_stockpiles.Timber=0.0)
	var before:=held("player","Food")
	assert_bool(Needs.send(t).has("error")).is_true()
	assert_float(held("player","Food")).is_equal(before)

func test_storage_bill_changes_actual_economic_need_and_save_preserves_cargo()->void:
	assert_float(Needs.desired("Timber",120)).is_greater_equal(8.0)
	var t:=quote();assert_bool(bool(t.ok)).is_true()
	if not t.ok:return
	Needs.send(t)
	var saved:Dictionary=JSON.parse_string(JSON.stringify(Ledger.peek()))
	assert_bool(Ledger.valid_state(saved)).is_true()
	ForeignDiplomacy.audiences.trade=saved
	Needs.advance(int(t.days))
	assert_str(String(Ledger.peek().barter_shipments[0].status)).is_equal("delivered")

func test_invalid_cargo_is_rejected_by_the_save_validator()->void:
	assert_bool(Needs.valid_shipments("cargo")).is_false()
	assert_bool(Needs.valid_shipments([{"id":1}])).is_false()
	var t:=quote()
	assert_bool(bool(t.ok)).is_true()
	if not t.ok:return
	Needs.send(t)
	var saved:Dictionary=JSON.parse_string(JSON.stringify(Ledger.peek()))
	saved.barter_shipments[0].payment=-10
	assert_bool(Ledger.valid_state(saved)).is_false()

func test_early_goods_wallet_is_unavailable_for_material_deals()->void:
	GameState.resource_stockpiles["Civilian Goods"]=1000
	var pair:=Ledger.pair("player",seller);pair.meet=0
	var before:=held("player","Civilian Goods")
	assert_bool(bool(Ledger.deal_terms("player",seller,"Timber",1).ok)).is_false()
	assert_bool(bool(Ledger.goods_deal("player",seller,"Timber",1).ok)).is_false()
	assert_float(held("player","Civilian Goods")).is_equal(before)
