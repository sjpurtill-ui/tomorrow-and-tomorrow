extends GdUnitTestSuite
## WHO CARRIES THE SUPPLY (scripts/carriers.gd): porters 16 loads, carts 250
## (700 as horse wagons), lorries 2,000, each driven by a Logistics worker;
## distance ties up carriers for the round trip; the day's transport share is
## what they move against what the bands away ask.

const Carriers:=preload("res://scripts/carriers.gd")
const Supply:=preload("res://scripts/supply_state.gd")
const P:=preload("res://scripts/persistent_production.gd")

func before_test()->void:
	WorldSimulation.clear();GameState.reset_for_new_world(515);MilitaryCampaign.reset_for_new_world()
	GameState.settlement_site_committed=true;GameState.settlement_founded_at=Vector3.ZERO
	MilitaryCampaign.home_army=MilitaryCampaign._empty_home_army()
	GameState.population_allocations["Logistics"]=0
	GameState.resource_stockpiles["Transport Carts"]=0.0
	GameState.resource_stockpiles["Supply Lorries"]=0.0

func after_test()->void:
	WorldSimulation.clear()

func _none(_id:String)->float: return 0.0

func _band(id:int,unit:String,weapon:String,men:int,x:float)->Dictionary:
	var sim=MilitaryCampaign.simulator
	var sets:int=sim.equipment_required_for_weapon(weapon,men)
	var force:Dictionary=sim.create_formation_force("Band",[{"id":id,"unit":unit,"weapon":weapon,"count":men,"authorized_count":men,"equipment":sets,"equipment_required":sets,"training":0.7}],1.0,1.0)
	force.merge({"army_id":id,"status":"stationed","location_id":"field","position":{"x":x,"z":0.0}},true)
	return force

func test_the_fleet_is_drivers_with_what_they_drive()->void:
	GameState.population_allocations["Logistics"]=10
	GameState.resource_stockpiles["Transport Carts"]=3.0
	var fleet:=Carriers.fleet(GameState,_none)
	assert_int(int(fleet.carts)).is_equal(3)
	assert_int(int(fleet.porters)).is_equal(7)
	assert_float(float(fleet.loads)).is_equal(3*250.0+7*16.0)
	# Lorries take the drivers first; carts with no driver stand idle.
	GameState.population_allocations["Logistics"]=5
	GameState.resource_stockpiles["Supply Lorries"]=10.0
	fleet=Carriers.fleet(GameState,_none)
	assert_int(int(fleet.lorries)).is_equal(5)
	assert_int(int(fleet.carts)).is_equal(0)
	assert_float(float(fleet.loads)).is_equal(5*2000.0)
	# Horse freight wagons carry 700 loads.
	GameState.resource_stockpiles["Supply Lorries"]=0.0
	fleet=Carriers.fleet(GameState,func(id:String)->float:return 1.0 if id=="horse_freight_wagons" else 0.0)
	assert_float(float(fleet.cart_load)).is_equal(700.0)

func test_distance_ties_up_carriers_and_rail_shortens_the_trip()->void:
	assert_float(Carriers.round_trip(2.0,0.0)).is_equal(4.0)
	assert_float(Carriers.round_trip(0.1,0.0)).is_equal(Carriers.MIN_ROUND_TRIP)
	assert_float(Carriers.round_trip(2.0,1.0)).is_equal_approx(4.0*(1.0-Carriers.RAIL_SHARE),0.0001)
	assert_bool(is_inf(Carriers.round_trip(INF,0.0))).is_true()

func test_porters_alone_cannot_feed_a_distant_band_but_carts_can()->void:
	var band:=_band(1,"spearman","spear",100,60.0)
	MilitaryCampaign.field_armies.assign([band])
	var days:=Supply.haul_days_for(band)
	assert_float(days).is_greater(1.0)
	GameState.population_allocations["Logistics"]=10
	var porters_only:=float(Carriers.reading(MilitaryCampaign).ratio)
	var need:=100*Carriers.RATION*Carriers.round_trip(days,0.0)
	assert_float(porters_only).is_less(1.0)
	assert_float(porters_only).is_equal_approx(minf(1.0,10*16.0*float(Carriers.reading(MilitaryCampaign).efficiency)/need),0.001)
	GameState.resource_stockpiles["Transport Carts"]=3.0
	assert_float(float(Carriers.reading(MilitaryCampaign).ratio)).is_equal(1.0)

func test_a_tank_band_asks_far_more_than_a_spear_band_of_the_same_men()->void:
	var spears:=_band(1,"spearman","spear",100,60.0)
	var tanks:=_band(2,"armored_formation","armored_vehicle",100,60.0)
	assert_float(Carriers.daily_loads(tanks)).is_greater(Carriers.daily_loads(spears)*10.0)

func test_no_band_away_needs_no_carriers()->void:
	MilitaryCampaign.field_armies.clear()
	assert_float(MilitaryCampaign._field_transport_delivery_ratio()).is_equal(1.0)
	var home:=_band(1,"spearman","spear",100,0.0);home.location_id="player_home"
	MilitaryCampaign.field_armies.assign([home])
	assert_float(float(Carriers.reading(MilitaryCampaign).demand)).is_equal(0.0)

func test_the_staff_want_carts_only_as_many_as_there_are_drivers()->void:
	var band:=_band(1,"spearman","spear",2000,60.0)
	MilitaryCampaign.field_armies.assign([band])
	GameState.population_allocations["Logistics"]=12
	var want:=Carriers.wanted(MilitaryCampaign,"transport_cart")
	assert_int(want).is_greater(0)
	assert_int(want).is_less_equal(12)

func test_lorries_set_the_pace_and_are_made_on_a_line()->void:
	assert_str(Supply.carrier()).is_not_equal("motor")
	GameState.resource_stockpiles["Supply Lorries"]=1.0
	assert_str(Supply.carrier()).is_equal("motor")
	assert_str(P.transport_stock("supply_lorry")).is_equal("Supply Lorries")
	assert_bool(P.recipe(MilitaryCampaign,"supply_lorry").has("error")).is_true()
	GameState.known_discoveries.append("motor_freight_lorries");GameState.discovery_adoption["motor_freight_lorries"]=1.0
	var recipe:=P.recipe(MilitaryCampaign,"supply_lorry")
	assert_str(String(recipe.get("job_type",""))).is_equal("transport")
