extends GdUnitTestSuite
## FIELD DEPOTS (scripts/field_depots.gd): a band told to lay a depot builds
## it where it stands, 900 man-days and five days at the least; a standing
## depot feeds the carriers who pass it, so more of each load reaches a band
## beyond it, but they still walk the whole road (it saves food, not
## carriers); we keep two (four with army magazines), counting those being
## laid, and a new one gives up the oldest; a host at war with us whose march
## passes one burns it unless our bands there are half its strength; depots
## survive a save. Fixture land as test_supply_state.gd: open level
## grassland round home.

const Depots:=preload("res://scripts/field_depots.gd")
const Supply:=preload("res://scripts/supply_state.gd")
const March:=preload("res://scripts/march_terrain.gd")
const Orders:=preload("res://scripts/army_orders.gd")

var _processing:Dictionary={}
var home:=Vector2.ZERO
var civ_id:=""

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
	CivilizationSystem.revealed_areas.assign([{"kind":"circle","x":home.x,"z":home.y,"radius":400.0,"day":0}])
	CivilizationSystem.fog_revision+=1
	March.reset_overrides()
	March.ground_override=func(_p:Vector2)->Dictionary: return {"h":0.3,"slope":0.0,"wood":0.0,"wet":0.0,"t":0.55,"rain":0.55}
	March.use_roads_override=true
	March.roads_override=[]
	Supply.reset()
	civ_id=String(CivilizationSystem.civilizations[0].id)
	CivilizationSystem.foreign_formations.clear()

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

func _learn(id:String)->void:
	if not id in GameState.known_discoveries: GameState.known_discoveries.append(id)
	GameState.discovery_adoption[id]=1.0

func _band(id:int,offset:Vector2,troops:int=60)->Dictionary:
	var at:=home+offset
	var band:={"army_id":id,"name":"LEVY BAND %d" % id,"troops":troops,"status":"stationed","location_id":"field","position":{"x":at.x,"z":at.y},
		"formations":[],"supply_level":1.0,"commander":{"name":"Rovik Ashdown","logistics":0.4}}
	MilitaryCampaign.field_armies.append(band)
	return band

func _days(n:int)->void:
	for day in n: MilitaryCampaign.depots.day()

func _at_war(yes:bool)->void:
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	var relation:Dictionary=civ.get("player_relation",{})
	relation["at_war"]=yes
	civ["player_relation"]=relation

func _host_at(at:Vector2,men:int=300)->void:
	CivilizationSystem.foreign_formations.append({"id":"%s_expedition" % civ_id,"civ_id":civ_id,"kind":"expedition","command_position":{"x":at.x,"z":at.y},"strength_share":0.1,"actual_troops":men})


func test_depots_wait_on_the_research_and_need_hands()->void:
	assert_str(MilitaryCampaign.depots.blocked(60)).contains("Forward Supply Depots")
	_learn("forward_supply_depots")
	assert_str(MilitaryCampaign.depots.blocked(60)).is_equal("")
	assert_str(MilitaryCampaign.depots.blocked(10)).contains("at least 20")
	assert_int(MilitaryCampaign.depots.limit()).is_equal(2)
	_learn("army_supply_magazines")
	assert_int(MilitaryCampaign.depots.limit()).is_equal(4)
	# The order screen says the same, and what the depot will do.
	_band(1,Vector2(60,0))
	assert_str(Orders.unavailable(1,"depot")).is_equal("")
	var plan:=Orders.preview(1,"depot",{"type":"spot","x":home.x+60.0,"z":home.y})
	assert_str(" ".join(plan.lines)).contains("about 15 days for 60 hands")
	assert_str(" ".join(plan.lines)).contains("burns it")

func test_a_band_builds_it_in_the_stated_days()->void:
	_learn("forward_supply_depots")
	_band(1,Vector2(60,0),60)
	MilitaryCampaign.depots.assign(1,home+Vector2(60,0))
	assert_int(int(Depots.progress(MilitaryCampaign.field_armies[0]).days_left)).is_equal(15)
	_days(14)
	assert_int(MilitaryCampaign.field_depots.size()).is_equal(0)
	assert_int(int(Depots.progress(MilitaryCampaign.field_armies[0]).days_left)).is_equal(1)
	_days(1)
	assert_int(MilitaryCampaign.field_depots.size()).is_equal(1)
	assert_bool(MilitaryCampaign.field_armies[0].has("depot_site")).is_false()
	assert_str(String(MilitaryCampaign.field_depots[0].name)).contains("60 km")
	# A big band still takes the fewest days.
	_band(2,Vector2(0,60),900)
	MilitaryCampaign.depots.assign(2,home+Vector2(0,60))
	_days(4)
	assert_int(MilitaryCampaign.field_depots.size()).is_equal(1)
	_days(1)
	assert_int(MilitaryCampaign.field_depots.size()).is_equal(2)

func test_work_is_dropped_when_the_band_is_sent_elsewhere()->void:
	_learn("forward_supply_depots")
	var band:=_band(1,Vector2(60,0),60)
	MilitaryCampaign.depots.assign(1,home+Vector2(60,0))
	_days(5)
	band["status"]="moving"
	band["destination_position"]={"x":home.x+200.0,"z":home.y}
	_days(1)
	assert_bool(MilitaryCampaign.field_armies[0].has("depot_site")).is_false()
	assert_int(MilitaryCampaign.field_depots.size()).is_equal(0)

func test_a_new_depot_gives_up_the_oldest_past_the_limit()->void:
	_learn("forward_supply_depots")
	MilitaryCampaign.field_depots.assign([{"id":1,"name":"Depot A","x":home.x+30.0,"z":home.y,"built_day":1,"by":""},{"id":2,"name":"Depot B","x":home.x,"z":home.y+30.0,"built_day":2,"by":""}])
	_band(1,Vector2(-60,0),300)
	MilitaryCampaign.depots.assign(1,home+Vector2(-60,0))
	_days(5)
	assert_int(MilitaryCampaign.field_depots.size()).is_equal(2)
	var ids:=MilitaryCampaign.field_depots.map(func(d:Dictionary)->int: return int(d.id))
	assert_array(ids).contains_exactly([2,3])

func test_a_depot_feeds_the_carriers_but_they_walk_the_whole_road()->void:
	var beyond:=home+Vector2(215,0)
	var band:=_band(1,Vector2(215,0),60)
	var before:=Supply.at_point(beyond,30)
	var haul_before:=Supply.haul_for(band)
	var trip_before:=float(Supply.haul_inputs_for(band).effort)
	MilitaryCampaign.field_depots.assign([{"id":1,"name":"Depot 170 km east","x":home.x+170.0,"z":home.y,"built_day":1,"by":""}])
	assert_bool(Supply.hubs().any(func(h:Dictionary)->bool: return String(h.kind)=="depot")).is_true()
	var after:=Supply.at_point(beyond,30)
	assert_str(String(after.hub_kind)).is_equal("depot")
	# More of each load arrives (they eat at the depot)...
	assert_float(float(after.effort)).is_less(float(before.effort))
	assert_float(Supply.haul_for(band)).is_greater(haul_before)
	# ...but the carriers walk the same road: their round trip is unchanged.
	assert_float(float(Supply.haul_inputs_for(band).effort)).is_equal_approx(trip_before,trip_before*0.05)
	assert_float(float(after.days)).is_equal_approx(float(before.days),float(before.days)*0.05)
	# The line is Seanstone's, and says the carriers eat at the depot.
	assert_str(String(after.hub)).is_equal("Seanstone")
	assert_str(String(after.words)).contains("eating at the depot 170 km east")
	# A siege of home cuts what the rations get along it, as the map shows.
	var full:=Supply.haul_for(band)
	MilitaryCampaign.active_siege={"mode":"defensive","blockade":0.9375}
	assert_float(Supply.haul_for(band)).is_equal_approx(full*0.25,0.0001)
	var f:=Supply.field(true)
	var open:=Supply.terms(f,beyond,400,30,false,1.0,1.0,1.0)
	var cut:=Supply.terms(f,beyond,400,30,false,1.0,1.0,0.25)
	assert_float(float(cut.haul)).is_equal_approx(float(open.haul)*0.25,0.0001)
	MilitaryCampaign.active_siege={}

func test_a_host_at_war_burns_a_depot_too_few_guard()->void:
	MilitaryCampaign.field_depots.assign([{"id":1,"name":"Depot","x":home.x+100.0,"z":home.y,"built_day":1,"by":""}])
	_host_at(home+Vector2(105,0),300)
	# Not at war: it passes by.
	_at_war(false)
	_days(1)
	assert_int(MilitaryCampaign.field_depots.size()).is_equal(1)
	# Our bands there at half its strength keep it.
	_at_war(true)
	_band(1,Vector2(95,0),150)
	_days(1)
	assert_int(MilitaryCampaign.field_depots.size()).is_equal(1)
	# Twenty men do not.
	MilitaryCampaign.field_armies.clear()
	_band(1,Vector2(95,0),20)
	_days(1)
	assert_int(MilitaryCampaign.field_depots.size()).is_equal(0)

func test_a_host_that_marches_past_in_a_day_still_burns_it()->void:
	MilitaryCampaign.field_depots.assign([{"id":1,"name":"Depot","x":home.x+100.0,"z":home.y,"built_day":1,"by":""}])
	_at_war(true)
	# Yesterday 50 km short of it, today 50 km past it.
	var today:=int(GameState.elapsed_days)
	CivilizationSystem.foreign_formations.append({"id":"%s_raiders" % civ_id,"civ_id":civ_id,"kind":"expedition","point_a":home+Vector2(50,0),"point_b":home+Vector2(150,0),"leg_days":1.0,"depart_day":today-1,"strength_share":0.1,"actual_troops":200})
	_days(1)
	assert_int(MilitaryCampaign.field_depots.size()).is_equal(0)

func test_depots_being_laid_count_against_the_limit()->void:
	_learn("forward_supply_depots")
	MilitaryCampaign.field_depots.assign([{"id":1,"name":"Depot A","x":home.x+30.0,"z":home.y,"built_day":1,"by":""}])
	_band(1,Vector2(-60,0),60)
	MilitaryCampaign.depots.assign(1,home+Vector2(-60,0))
	# One standing and one being laid: a third would give up A.
	assert_str(String(MilitaryCampaign.depots.replaces().get("name",""))).is_equal("Depot A")
	_band(2,Vector2(0,-60),60)
	MilitaryCampaign.depots.assign(2,home+Vector2(0,-60))
	assert_str(MilitaryCampaign.depots.blocked(60)).contains("already laying 2")

func test_the_preview_says_what_a_depot_saves_there()->void:
	_learn("forward_supply_depots")
	_band(1,Vector2(200,0),60)
	var plan:=Orders.preview(1,"depot",{"type":"spot","x":home.x+200.0,"z":home.y})
	var said:=" ".join(plan.lines)
	assert_str(said).contains("of each load would arrive instead of")
	assert_str(said).contains("within 12 km")
	# Beside home a depot saves nothing worth the slot.
	_band(2,Vector2(4,0),60)
	var near:=" ".join(Orders.preview(2,"depot",{"type":"spot","x":home.x+4.0,"z":home.y}).lines)
	assert_str(near).contains("would save little")

func test_depots_and_work_in_hand_survive_a_save()->void:
	_learn("forward_supply_depots")
	MilitaryCampaign.field_depots.assign([{"id":4,"name":"Depot 90 km east","x":home.x+90.0,"z":home.y,"built_day":12,"by":"LEVY BAND 1"}])
	# A band as the campaign makes them (the save checks its formations).
	var sim=MilitaryCampaign.simulator
	var sets:int=sim.equipment_required_for_weapon("spear",60)
	var band:Dictionary=sim.create_formation_force("LEVY BAND 1",[{"id":1,"unit":"spearman","weapon":"spear","count":60,"authorized_count":60,"equipment":sets,"equipment_required":sets,"ammunition":0,"ammunition_required":0,"training":0.7,"experience":0.2,"personnel_condition":1.0}],1.0,1.0)
	var at:=home+Vector2(60,0)
	band.merge({"army_id":1,"status":"stationed","location_id":"field","position":{"x":at.x,"z":at.y},"supply_level":1.0},true)
	MilitaryCampaign.field_armies.assign([band])
	MilitaryCampaign.depots.assign(1,at)
	_days(3)
	var saved:=MilitaryCampaign.export_state()
	MilitaryCampaign.field_depots.clear()
	MilitaryCampaign.field_armies[0].erase("depot_site")
	var loaded:=MilitaryCampaign.import_state(saved)
	assert_str(String(loaded.get("error",""))).is_equal("")
	assert_int(MilitaryCampaign.field_depots.size()).is_equal(1)
	assert_str(String(MilitaryCampaign.field_depots[0].name)).is_equal("Depot 90 km east")
	var work:=Depots.progress(MilitaryCampaign.field_armies[0])
	assert_float(float(work.work)).is_equal_approx(180.0,0.01)
	# A save from before depots loads with none.
	saved.erase("field_depots")
	assert_str(String(MilitaryCampaign.import_state(saved).get("error",""))).is_equal("")
	assert_int(MilitaryCampaign.field_depots.size()).is_equal(0)

func test_a_siege_of_home_cuts_the_line_from_a_depot_too()->void:
	MilitaryCampaign.field_depots.assign([{"id":1,"name":"Depot 170 km east","x":home.x+170.0,"z":home.y,"built_day":1,"by":""}])
	var f:=Supply.field(true)
	var beyond:=home+Vector2(215,0)
	var open:=Supply.terms(f,beyond,400,30,false,1.0,1.0,1.0)
	var ringed:=Supply.terms(f,beyond,400,30,false,1.0,1.0,0.25)
	assert_str(String(open.hub.kind)).is_equal("depot")
	assert_float(float(ringed.haul)).is_equal_approx(float(open.haul)*0.25,0.0001)

func test_the_line_in_deep_winter_is_forecast()->void:
	# Day 400: the coldest day south of the line is day 639, north of it 456.
	assert_int(Supply.coldest_day(Vector2(0,-5),400)).is_equal(639)
	assert_int(Supply.coldest_day(Vector2(0,5),400)).is_equal(456)
	assert_int(Supply.coldest_day(Vector2(0,-5),639)).is_equal(639)
	var band:=_band(1,Vector2(150,0),60)
	var report:=Supply.of_force(band)
	assert_bool(report.has("winter")).is_true()
	var winter:Dictionary=report.winter
	assert_float(float(winter.cold)).is_greater(0.0)
	assert_int(int(winter.in_days)).is_greater(0)
	assert_float(float(winter.ratio)).is_less_equal(float(report.ratio))
