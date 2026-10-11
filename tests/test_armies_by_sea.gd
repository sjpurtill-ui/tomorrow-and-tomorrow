extends GdUnitTestSuite
## Armies by sea (army_sea_road.gd): with no land road and boats fit for the
## sea, an army walks to the shore, sails, lands and marches on; the crossing
## drowns its stated share when it comes ashore; without such boats, or over
## too much water, no march is ordered.

const SeaRoad:=preload("res://scripts/army_sea_road.gd")
const Route:=preload("res://scripts/army_land_route.gd")
const Expedition:=preload("res://scripts/expedition.gd")
const War:=preload("res://scripts/war_loop.gd")
const COAST_BOATS:=["river_craft","hide_covered_boats","plank_extended_dugouts","sail_panel_cutting","sail_seaming","wayfinding_stars"]

var home:=Vector2.ZERO
var _processing:Dictionary={}

## Home country within 60 km of home; another land from 200 km east of it.
func _land(p:Vector2)->bool:
	return p.distance_to(home)<60.0 or (p.x>home.x+200.0 and p.x<home.x+900.0 and absf(p.y-home.y)<400.0)

func before_test()->void:
	if _processing.is_empty():
		for node:Node in [GameState,CivilizationSystem,MilitaryCampaign,ProgressionSystem]: _processing[node]=node.is_processing()
	WorldSimulation.clear()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	GameState.reset_for_new_world(74017);GameState.civic_api_enabled=false
	DiscoverySystem.reset_for_new_world();FoodSystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world();CivilizationSystem.reset_for_new_world()
	ForeignDiplomacy.reset_for_new_world();ForeignDiplomacy.ensure();GovernmentPeopleSystem.reset_for_new_world()
	GameState.ensure_population_total(900);GameState.housing_capacity=1000
	GameState.settlement_site_committed=true;GameState.settlement_completed=["Hearth Circle"];SettlementModel.ensure_founded()
	GameState.select_founding_focus("provision")
	GovernmentPeopleSystem.initialize()
	GameState.resource_stockpiles["Food"]=1000000.0
	GameState.elapsed_days=88*365
	Route.clear_cache()
	home=CivilizationSystem.player_world_origin
	CivilizationSystem.set_scout_geography_authority(Callable(self,"_land"))
	CivilizationSystem.revealed_areas=[{"x":home.x,"z":home.y,"radius":100000.0}]

func after_test()->void:
	CivilizationSystem.set_scout_geography_authority(Callable())
	Route.clear_cache()
	GameState.elapsed_days=0
	MilitaryCampaign.reset_for_new_world()
	GovernmentPeopleSystem.reset_for_new_world()
	ForeignDiplomacy.reset_for_new_world()
	CivilizationSystem.reset_for_new_world()
	FoodSystem.reset_for_new_world()
	DiscoverySystem.reset_for_new_world()
	GameState.reset_for_new_world(74017)
	ProgressionSystem.reset_for_new_world()
	WorldSimulation.clear()
	for node:Node in _processing: node.set_process(bool(_processing[node]))

func _boats()->void:
	for id:String in COAST_BOATS:
		if not id in GameState.known_discoveries:GameState.known_discoveries.append(id)
		GameState.discovery_adoption[id]=1.0

func _band(count:int)->int:
	MilitaryCampaign.military_inventory["improvised"]=int(MilitaryCampaign.military_inventory.get("improvised",0))+count
	MilitaryCampaign.raise_recruits(count)
	MilitaryCampaign.start_training("levy","improvised",count)
	MilitaryCampaign._complete_training(MilitaryCampaign.training_queue[0].duplicate(true))
	MilitaryCampaign.training_queue.clear()
	var made:Dictionary=MilitaryCampaign.create_field_army(count,"Sea band")
	return int(made.get("army_id",made.get("army",{}).get("army_id",0)))

func test_the_sea_road_walks_sails_and_walks_and_states_who_drowns()->void:
	var craft:={"ok":true,"sail_km_per_day":40.0,"endurance_km":400.0,"label":"test boats"}
	var road:Dictionary=SeaRoad.find(home,home+Vector2(300,0),Callable(self,"_land"),{"foot":1.0},20.0,craft)
	assert_bool(bool(road.get("ok",false))).override_failure_message(str(road)).is_true()
	var sea:Dictionary=road.sea
	# About 140 km of water between the two shores.
	assert_float(float(sea.sea_km)).is_between(130.0,156.0)
	assert_float(float(sea.drown)).is_equal_approx(SeaRoad.drown_share(float(sea.open_km),float(sea.coast_km),400.0),0.0001)
	assert_float(float(sea.drown)).is_between(0.05,0.25)
	# Under sail at twice the army's pace: half the effort of the same km on foot.
	assert_float(float(sea.to_e)-float(sea.from_e)).is_equal_approx(float(sea.sea_km)*20.0/40.0,0.5)
	assert_bool(_land(road.points[-1])).is_true()
	assert_bool((road.points[-1] as Vector2).distance_to(home+Vector2(300,0))<1.0).is_true()
	assert_str(String(road.ground_words)).contains("by sea")
	# River boats: no sea road at all. Too much water: refused with the count.
	assert_bool(SeaRoad.find(home,home+Vector2(300,0),Callable(self,"_land"),{"foot":1.0},20.0,{"ok":false}).is_empty()).is_true()
	var far:Dictionary=SeaRoad.find(home,home+Vector2(300,0),Callable(self,"_land"),{"foot":1.0},20.0,{"ok":true,"sail_km_per_day":40.0,"endurance_km":30.0})
	assert_str(String(far.get("reason",""))).is_equal("sea_too_far")
	assert_str(String(far.error)).contains("in 100")

func test_without_boats_for_the_sea_no_march_is_ordered()->void:
	var id:=_band(40)
	var refused:Dictionary=MilitaryCampaign.move_field_army_to_position(id,home.x+300.0,home.y,"THE FAR SHORE")
	assert_str(String(refused.get("error",""))).contains("no boats that can carry an army")

func test_an_army_crosses_lands_fewer_and_arrives()->void:
	_boats()
	var id:=_band(40)
	var index:int=MilitaryCampaign._field_army_index(id)
	var troops:=int(MilitaryCampaign.field_armies[index].troops)
	var ordered:Dictionary=MilitaryCampaign.move_field_army_to_position(id,home.x+300.0,home.y,"THE FAR SHORE")
	assert_bool(bool(ordered.get("ok",false))).override_failure_message(str(ordered)).is_true()
	assert_str(String(ordered.message)).contains("by sea").contains("will drown").contains("days ashore")
	# The stated march counts the boats' stores: not a hungry road.
	var stated:Dictionary=MilitaryCampaign.march_supply(MilitaryCampaign.field_armies[index],MilitaryCampaign.field_route(home,home+Vector2(300,0),MilitaryCampaign.field_armies[index]))
	assert_float(float(stated.fed_there)).is_equal(1.0)
	var army:Dictionary=MilitaryCampaign.field_armies[index]
	assert_bool(army.get("march_sea") is Dictionary).is_true()
	var share:=float(army.march_sea.drown)
	var wet_days:=0
	GameState.simulation_events=[]
	for day in 200:
		GameState.elapsed_days+=1
		MilitaryCampaign._process_field_army_movement_day()
		army=MilitaryCampaign.field_armies[MilitaryCampaign._field_army_index(id)]
		var at:=Vector2(float(army.position.x),float(army.position.z))
		if not _land(at):wet_days+=1
		if String(army.status)!="moving":break
	assert_str(String(army.status)).override_failure_message(String(army.get("movement_block_reason",""))).is_equal("stationed")
	assert_int(wet_days).is_greater(0)
	assert_bool(Vector2(float(army.position.x),float(army.position.z)).distance_to(home+Vector2(300,0))<1.0).is_true()
	assert_int(int(army.troops)).is_less(troops)
	assert_int(troops-int(army.troops)).is_between(maxi(1,floori(float(troops)*share)),ceili(float(troops)*share)+2)
	assert_bool(army.has("march_sea")).is_false()
	# It eats from its boats for forty days after landing.
	assert_int(int(army.sea_stores_until)).is_between(int(GameState.elapsed_days)-30,int(GameState.elapsed_days)+SeaRoad.STORES_ASHORE_DAYS)
	assert_float(MilitaryCampaign._force_provision_access(army)).is_equal(1.0)
	assert_bool(SeaRoad.on_ship_stores(army,int(army.sea_stores_until)+1)).is_false()
	assert_int(GameState.simulation_events.filter(func(e:Dictionary)->bool:return String(e.get("title",""))=="THE CROSSING").size()).is_equal(1)

func test_boats_carry_war_farther_than_feet()->void:
	assert_float(War.war_margin_km()).is_equal(War.NEIGHBOUR_MARGIN_KM)
	_boats()
	GameState.elapsed_days+=1
	assert_float(War.war_margin_km()).is_equal_approx(Expedition.endurance_km(true)*SeaRoad.WAR_ENDURANCES,0.01)
	assert_float(War.war_margin_km()).is_greater(War.NEIGHBOUR_MARGIN_KM)

func test_raiders_who_cannot_march_a_real_band_come_only_on_foot()->void:
	_boats()
	GameState.elapsed_days+=1
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	var ours:Dictionary=preload("res://scripts/realm_reach.gd").ours()
	var theirs:Dictionary=preload("res://scripts/realm_reach.gd").of(civ)
	# Their country set beyond a month's march but within our boats' reach.
	var gap:=float(ours.reach)+float(theirs.get("reach",0.0))+War.NEIGHBOUR_MARGIN_KM+200.0
	assert_float(gap-float(ours.reach)-float(theirs.get("reach",0.0))).is_less(War.war_margin_km())
	var at:Vector2=(ours.center as Vector2)+Vector2(gap,0.0)
	civ.position=Vector2(at.x/CivilizationSystem.CIVILIZATION_WORLD_RADIUS_X_KM,at.y/CivilizationSystem.CIVILIZATION_WORLD_RADIUS_Z_KM)
	civ.erase("strategic_regions")
	if (preload("res://scripts/realm_reach.gd").of(civ).get("center",at) as Vector2).distance_to(at)>50.0:return
	assert_bool(War.near_us(String(civ.id))).is_true()
	assert_bool(War.near_us(String(civ.id),true)).is_false()
