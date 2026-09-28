extends GdUnitTestSuite
## THE ONE SUPPLY MODEL (scripts/supply_state.gd): the same numbers the day's
## rations use (military_campaign.record_daily_provisions, field_rations.gd),
## worse farther out, over rough ground and off the roads; a held town feeds
## its garrison and serves as a depot; the map's grid is the same function at
## its nodes; unknown land is never tinted.
##
## Fixture land (km from home): open level grassland everywhere, except a
## band of wooded hills west of x=-20. Roads and the known land are set per
## test. Home is Seanstone at the world origin.

const Supply:=preload("res://scripts/supply_state.gd")
const Rations:=preload("res://scripts/field_rations.gd")
const March:=preload("res://scripts/march_terrain.gd")

var _processing:Dictionary={}
var home:=Vector2.ZERO
var civ_id:=""
var town_id:=""
var town_at:=Vector2.ZERO
var warmth:=0.55

func before_test()->void:
	if _processing.is_empty():
		for node:Node in [GameState,CivilizationSystem,MilitaryCampaign]: _processing[node]=node.is_processing()
	WorldSimulation.clear()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	GameState.reset_for_new_world(5151);GameState.civic_api_enabled=false
	DiscoverySystem.reset_for_new_world();DiscoverySystem.initialize()
	FoodSystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world();CivilizationSystem.reset_for_new_world()
	GameState.ensure_population_total(157);GameState.housing_capacity=200
	GameState.settlement_site_committed=true;GameState.convoy_traveling=false;GameState.resource_settlement_id=""
	GameState.settlement_name="Seanstone"
	GameState.population_allocations.Logistics=14
	GameState.food_stocks={FoodSystem.FRESH:400.0,FoodSystem.STORED:30000.0}
	GameState.simulation_metrics["food_intake_ratio"]=1.0
	GameState.elapsed_days=400
	MilitaryCampaign.home_army=MilitaryCampaign._empty_home_army()
	home=CivilizationSystem.player_world_origin
	_know(260.0)
	March.reset_overrides()
	March.ground_override=Callable(self,"_ground")
	March.use_roads_override=true
	March.roads_override=[]
	warmth=0.55
	Supply.reset()
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	civ_id=String(civ.id)
	var region:Dictionary=civ.strategic_regions[CivilizationSystem._frontline_region_index(civ)]
	region["name"]="Tsaren";region["population"]=300.0
	town_id=String(region.id)

func after_test()->void:
	March.reset_overrides()
	Supply.reset()
	MilitaryCampaign.reset_for_new_world()
	CivilizationSystem.reset_for_new_world()
	FoodSystem.reset_for_new_world()
	DiscoverySystem.reset_for_new_world()
	GameState.reset_for_new_world(5151)
	WorldSimulation.clear()
	for node:Node in _processing: node.set_process(bool(_processing[node]))

## Open level grassland; wooded hills west of x=-20 (km from home).
func _ground(p:Vector2)->Dictionary:
	var u:=p-home
	if u.x<=-20.0: return {"h":1.2,"slope":0.22,"wood":0.8,"wet":0.0,"t":warmth,"rain":0.6}
	return {"h":0.3,"slope":0.0,"wood":0.0,"wet":0.0,"t":warmth,"rain":0.55}

func _know(radius:float)->void:
	CivilizationSystem.revealed_areas.assign([{"kind":"circle","x":home.x,"z":home.y,"radius":radius,"day":0}])
	CivilizationSystem.fog_revision+=1

func _band(id:int,offset:Vector2,troops:int=30)->Dictionary:
	var at:=home+offset
	return {"army_id":id,"name":"LEVY BAND %d" % id,"troops":troops,"status":"stationed","location_id":"field","position":{"x":at.x,"z":at.y},
		"formations":[],"supply_level":1.0,"commander":{"name":"Rovik Ashdown","logistics":0.4}}

func _hold_tsaren(offset:Vector2,troops:int=17,resistance:float=0.3)->void:
	town_at=home+offset
	var day:=int(GameState.elapsed_days)
	CivilizationSystem.city_intelligence.publish("player",CivilizationSystem.city_intelligence.capture("player",town_id,.8,day,"field campaign report","capture"),day)
	CivilizationSystem.city_intelligence.records.player[town_id]["position"]={"x":town_at.x,"z":town_at.y}
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	var ri:=CivilizationSystem._region_index(civ,town_id)
	civ.strategic_regions[ri]["controller"]="player"
	civ.strategic_regions[ri]["resistance"]=resistance
	MilitaryCampaign.occupation_forces.assign([{"civ_id":civ_id,"region_id":town_id,"region_name":"Tsaren","troops":troops,"formations":[],"supply_level":1.0,"commander":{"name":"Rovik Ashdown"}}])

## A day's rations for everyone out, with full stores (food_system's call).
func _ration_day(need:float)->void:
	var credit:Dictionary=MilitaryCampaign.draw_delivered_field_rations(need)
	var accessible:=(need-float(credit.total))*MilitaryCampaign.field_provision_delivery_ratio(need,credit)
	MilitaryCampaign.record_daily_provisions(need,accessible,credit)


# --------------------------------------------------------------------------
# The same numbers as the day's rations
# --------------------------------------------------------------------------

func test_a_band_reads_the_engines_own_rations_and_the_projection_agrees()->void:
	MilitaryCampaign.field_armies.assign([_band(7,Vector2(25,0)),_band(8,Vector2(150,0))])
	_ration_day(60.0)
	for army:Dictionary in MilitaryCampaign.field_armies:
		var report:=Supply.of_force(army)
		# The report is the engine's day: ratio, carried and foraged shares.
		assert_float(float(report.ratio)).is_equal_approx(float(army.provision_ratio),0.0001)
		var need:=float(army.provisions_required_today)
		assert_float(float(report.carried)).is_equal_approx(float(army.provisions_delivered_today)/need,0.0001)
		assert_float(float(report.foraged)).is_equal_approx(float(army.provisions_foraged_today)/need,0.0001)
		assert_float(float(report.carried)+float(report.foraged)).is_equal_approx(float(report.ratio),0.0001)
		# And the model's own reckoning at that place is what the engine did.
		var projected:=Supply.at_point(Supply.force_pos(army),int(army.troops))
		assert_float(float(projected.ratio)).is_equal_approx(float(army.provision_ratio),0.0001)
		assert_float(float(projected.carried)).is_equal_approx(float(report.carried),0.0001)
	# Within a day's haul the carriers lose nothing; far out they eat part of it.
	var near:Dictionary=MilitaryCampaign.field_armies[0]
	var far:Dictionary=MilitaryCampaign.field_armies[1]
	assert_float(Supply.haul_for(near)).is_equal(1.0)
	assert_float(Supply.haul_for(far)).is_less(0.8)
	assert_float(float(far.provisions_delivered_today)).is_less(float(near.provisions_delivered_today))

func test_forage_share_is_the_models_and_the_country_matters()->void:
	var band:=_band(7,Vector2(60,0))
	var share:=Rations.forage_share(band)
	assert_float(share).is_equal_approx(minf(Supply.FORAGE_SHARE_MAX,Rations.FORAGE_STATIONED*Supply.forage_factor(band)),0.00001)
	# A host strips the country a small band lives off.
	var host:=_band(8,Vector2(60,0),900)
	assert_float(Rations.forage_share(host)).is_less(share)
	# Wooded hills feed a forager better than the open grass (game and cover).
	assert_float(Rations.forage_share(_band(9,Vector2(-60,0)))).is_greater(share)
	# Hard winter leaves little to find.
	warmth=0.22
	Supply.reset()
	var winter_day:=_coldest_day(home+Vector2(60,0))
	GameState.elapsed_days=winter_day
	assert_float(Supply.cold(winter_day,home+Vector2(60,0),warmth,Supply.NEUTRAL_SWING)).is_greater(0.5)
	assert_float(Rations.forage_share(band)).is_less(share)

func _coldest_day(at:Vector2)->int:
	var best:=400; var coldest:=-1.0
	for d in range(400,765):
		var c:=Supply.cold(d,at,warmth,Supply.NEUTRAL_SWING)
		if c>coldest: coldest=c; best=d
	return best


# --------------------------------------------------------------------------
# Farther, rougher, off the road: worse
# --------------------------------------------------------------------------

func test_farther_out_is_worse()->void:
	var ratios:Array=[]
	var carried:Array=[]
	for km in [30.0,90.0,160.0,230.0]:
		var r:=Supply.at_point(home+Vector2(km,0),30)
		ratios.append(float(r.ratio)); carried.append(float(r.carried))
		assert_str(String(r.hub)).is_equal("Seanstone")
	for k in range(1,ratios.size()):
		assert_float(float(carried[k])).is_less(float(carried[k-1]))
		assert_float(float(ratios[k])).is_less(float(ratios[k-1]))
	# The days of hauling grow with the distance (20 km a day on the level).
	var r160:=Supply.at_point(home+Vector2(160,0),30)
	assert_float(float(r160.days)).is_between(7.0,9.0)
	assert_str(String(r160.words)).contains("days from Seanstone")

func test_rough_ground_is_worse_than_open_ground_at_the_same_distance()->void:
	var open:=Supply.at_point(home+Vector2(120,0),30)
	var rough:=Supply.at_point(home+Vector2(-120,0),30)
	assert_float(float(rough.days)).is_greater(float(open.days)*1.3)
	assert_float(float(rough.carried)).is_less(float(open.carried))

func test_a_road_carries_farther()->void:
	var bare:=Supply.at_point(home+Vector2(180,0),30)
	March.roads_override=[{"a":home,"b":home+Vector2(200,0),"tier":2}]
	GameState.resource_stockpiles["Transport Carts"]=12.0
	var carts_bare:=Supply.at_point(home+Vector2(180,0),30)
	var road:=Supply.at_point(home+Vector2(180,0),30)
	March.roads_override=[]
	var carts_no_road:=Supply.at_point(home+Vector2(180,0),30)
	March.roads_override=[{"a":home,"b":home+Vector2(200,0),"tier":2}]
	var carts_road:=Supply.at_point(home+Vector2(180,0),30)
	assert_float(float(carts_road.days)).is_less(float(carts_no_road.days))
	assert_float(float(carts_road.haul)).is_greater(float(carts_no_road.haul))
	assert_str(String(carts_road.road)).is_equal("made road")
	assert_str(String(carts_road.words)).contains("by made road")
	assert_str(String(carts_no_road.road)).is_equal("")
	# Carts haul farther than porters on the same ground.
	assert_float(float(carts_no_road.haul)).is_greater(float(bare.haul))
	assert_str(String(carts_bare.carrier)).is_equal("wheeled")
	assert_float(float(road.days)).is_equal_approx(float(carts_road.days),0.0001)


# --------------------------------------------------------------------------
# Held towns
# --------------------------------------------------------------------------

func test_a_held_town_feeds_its_garrison_and_is_a_depot()->void:
	var beyond:=home+Vector2(215,0)
	var before:=Supply.at_point(beyond,30)
	_hold_tsaren(Vector2(170,0))
	var hubs:=Supply.hubs()
	assert_bool(hubs.any(func(h:Dictionary)->bool: return String(h.kind)=="held" and String(h.name)=="Tsaren")).is_true()
	# The garrison eats from the town first; nothing from home even at all.
	var credit:Dictionary=MilitaryCampaign.draw_delivered_field_rations(20.0)
	MilitaryCampaign.record_daily_provisions(20.0,0.0,credit)
	var garrison:Dictionary=MilitaryCampaign.occupation_forces[0]
	var report:=Supply.of_force(garrison)
	assert_str(String(report.force_kind)).is_equal("garrison")
	assert_float(float(report.ratio)).is_equal_approx(float(garrison.provision_ratio),0.0001)
	assert_float(float(report.local)).is_greater_equal(Rations.HUNGRY_BELOW)
	assert_float(float(report.local)).is_equal_approx(float(garrison.provisions_local_today)/float(garrison.provisions_required_today),0.0001)
	assert_str(String(report.words)).contains("from Tsaren")
	assert_str(String(report.state)).is_equal("well")
	# Beyond the town, the line runs from the depot: better than before.
	var after:=Supply.at_point(beyond,30)
	assert_float(float(after.carried)).is_greater(float(before.carried))
	assert_str(String(after.hub_kind)).is_equal("held")
	assert_str(String(after.words)).contains("depot at Tsaren")


# --------------------------------------------------------------------------
# The map's grid
# --------------------------------------------------------------------------

func test_the_map_grid_is_the_model_at_its_nodes_and_unknown_land_is_not_tinted()->void:
	_know(120.0)
	MilitaryCampaign.field_armies.assign([_band(7,Vector2(90,20),45)])
	var field:=Supply.field(true)
	assert_bool(field.is_empty()).is_false()
	var known:=Supply.known_mask(field)
	var inputs:=Supply.day_inputs()
	var grid:=Supply.grid(field,45,inputs,known)
	var ratio:PackedFloat32Array=grid.ratio
	var checked:=0
	var unknown:=0
	var n:=int(field.nx)*int(field.ny)
	for i in range(0,n,maxi(1,n/97)):
		var p:=Supply.node_pos(field,i)
		if known[i]==0:
			# Not known to us: never tinted, whatever its supply.
			assert_float(ratio[i]).is_equal(-1.0)
			assert_bool(CivilizationSystem._position_is_revealed(p)).is_false()
			unknown+=1
			continue
		var r:=Supply.at_point(p,45)
		assert_float(ratio[i]).is_equal_approx(float(r.ratio),0.0001)
		checked+=1
	assert_int(checked).is_greater(10)
	assert_int(unknown).is_greater(10)
	# The band stands in the known land; its own reading is the grid's there.
	var at:=home+Vector2(90,20)
	assert_bool(CivilizationSystem._position_is_revealed(at)).is_true()

func test_the_field_is_kept_until_the_world_changes()->void:
	var first:=Supply.field(true)
	var builds:=Supply.builds
	assert_int(int(Supply.field(true).get("key",0))).is_equal(int(first.key))
	assert_int(Supply.builds).is_equal(builds)
	# A new road is a new field.
	March.roads_override=[{"a":home,"b":home+Vector2(80,0),"tier":1}]
	assert_int(int(Supply.field(true).key)).is_not_equal(int(first.key))
	assert_int(Supply.builds).is_equal(builds+1)


func test_the_rations_read_one_field_a_day_and_a_change_arrives_two_days_on()->void:
	var band:=_band(7,Vector2(170,0))
	MilitaryCampaign.field_armies.assign([band])
	GameState.resource_stockpiles["Transport Carts"]=12.0
	var day1:=Supply.haul_for(band)
	# A made road appears the same day: today's rations are already set.
	March.roads_override=[{"a":home,"b":home+Vector2(200,0),"tier":2}]
	assert_float(Supply.haul_for(band)).is_equal(day1)
	# Next day: the rations still read the world as it was at yesterday's first ask.
	GameState.elapsed_days+=1
	assert_float(Supply.haul_for(band)).is_equal_approx(day1,0.02)
	# The day after, the road carries the food.
	GameState.elapsed_days+=1
	assert_float(Supply.haul_for(band)).is_greater(day1+0.05)
	# The screens show what the rations read today.
	assert_int(int(Supply.field().get("key",0))).is_equal(int(Supply.rations_field().get("key",0)))

## Another world's ground (a new game, a new terrain).
func _other_ground(_p:Vector2)->Dictionary:
	return {"h":0.5,"slope":0.05,"wood":0.3,"wet":0.0,"t":warmth,"rain":0.5}

func test_a_worker_build_stops_when_asked_and_another_worlds_is_never_read()->void:
	var s:=Supply.spec().duplicate()
	s["async"]=true
	Supply._start(s)
	assert_bool(Supply.building()).is_true()
	Supply.shutdown()
	assert_bool(Supply.building()).is_false()
	# A build of this world finishes after the world has changed: dropped.
	Supply._start(Supply.spec().duplicate())
	var task:int=Supply._job.task
	var waited:=0
	while not WorkerThreadPool.is_task_completed(task) and waited<20000:
		OS.delay_msec(5); waited+=5
	var old_world:=int(Supply._job.spec.world)
	March.ground_override=Callable(self,"_other_ground")
	var now:=Supply.field()
	assert_bool(Supply.building()).is_false()
	assert_int(int(now.get("world",0))).is_not_equal(old_world)
	assert_int(int(now.get("world",0))).is_equal(int(Supply.spec().world))


# --------------------------------------------------------------------------
# Words
# --------------------------------------------------------------------------

func test_plain_words_add_up()->void:
	assert_array(Supply.percents(0.6,[0.354,0.246])).is_equal([35,25])
	assert_array(Supply.percents(0.598,[0.244,0.354])).is_equal([24,36])
	var sum:=0
	for p in Supply.percents(0.6,[0.3333,0.2667]): sum+=int(p)
	assert_int(sum).is_equal(60)
	MilitaryCampaign.field_armies.assign([_band(7,Vector2(140,0))])
	_ration_day(30.0)
	var report:=Supply.of_force(MilitaryCampaign.field_armies[0])
	var text:=String(report.words)
	assert_str(text).starts_with("Gets %d%% of its food: " % roundi(float(report.ratio)*100.0))
	assert_str(text).contains("% foraged")
	assert_str(text).contains("% carried")
	assert_str(text).contains("days from Seanstone across open country")
	assert_str(Supply.state_of(0.8)).is_equal("well")
	assert_str(Supply.state_of(0.6)).is_equal("strained")
	assert_str(Supply.state_of(0.3)).is_equal("starving")
	var at_home:=Supply.of_force(MilitaryCampaign.home_army)
	assert_str(String(at_home.words)).starts_with("At home")
