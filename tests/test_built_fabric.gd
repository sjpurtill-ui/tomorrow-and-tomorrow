extends GdUnitTestSuite
## THE BUILT FABRIC (docs/BUILT_FABRIC.md; the user: "Building needs to not
## just be a ridiculous amount of homes ... What is the quality of the homes?
## ... Do they have roads? Are their places beautiful? ... the more stone,
## the more power, the more immovable a place is"). Pins:
## - once housed, builders raise the homes' grade, not their count, within
##   what the people know and their builders' craft;
## - every account costs builder-days and real timber, clay and stone, and
##   upkeep comes first; unkept, homes fall a grade, roads roughen, works
##   decay and fine works weather;
## - craft grows with builder-years and fades with the generations;
## - the effects the engine reads come from the cached readings, and each
##   hook stands in its owner's code (the guards);
## - builders on the walls raise stone stages a watch alone barely moves,
##   and walls and stone count in the defences and in Might;
## - a great work's odds and payoff follow the craft, the crews and the
##   materials, stated in plain words.

const Fabric:=preload("res://scripts/built_fabric.gd")
const Build:=preload("res://scripts/settlement_construction.gd")

var _processing:Dictionary={}


func before_test()->void:
	if _processing.is_empty():
		for node:Node in [GameState,CivilizationSystem,MilitaryCampaign]: _processing[node]=node.is_processing()
	WorldSimulation.clear()
	GameState.reset_for_new_world(8713)
	DiscoverySystem.reset_for_new_world()
	DiscoverySystem.initialize()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	GameState.initialize_population_model()
	GameState.ensure_population_total(200)
	GameState.settlement_site_committed=true
	GameState.settlement_founded_at=Vector3.ZERO
	GameState.settlement_founded_day=0
	GameState.settlement_completed=["Hearth Circle","Lean-to Shelters","Storage Pits","Open Work Area","Gathering Yard"]
	GameState.city_form={"tier":1.0,"condition":1.0}
	GameState.housing_capacity=210
	GameState.elapsed_days=10
	GameState.population_allocations.merge({"Construction":30,"Logistics":10,"Crafting":10,"Administration":6,"Knowledge":4,"Extraction":10},true)
	GameState.simulation_metrics["labor_efficiency"]=1.0
	for item in ["Timber","Clay","Stone","Fiber Plants"]:GameState.resource_stockpiles[item]=5000.0


func after_test()->void:
	WorldSimulation.clear()
	for node:Node in _processing: node.set_process(bool(_processing[node]))


func _know(ids:Array)->void:
	for id in ids:
		if String(id) not in GameState.known_discoveries:GameState.known_discoveries.append(String(id))


func _skill(level:float)->void:
	Fabric.realm_data()
	GameState.fabric_realm["xp"]=level*Fabric.CRAFT_PER_LEVEL*float(GameState.population_exact)
	GameState.fabric_realm["decay_day"]=int(GameState.elapsed_days)


func _reckon(days:int)->void:
	var f:=Fabric.data()
	GameState.elapsed_days=int(GameState.elapsed_days)+days
	Fabric.reckon(f,float(days))
	f.day=int(GameState.elapsed_days)


func test_a_new_town_sleeps_in_lean_tos_and_raises_its_homes_as_it_learns()->void:
	var f:=Fabric.data()
	assert_array(f.homes).is_equal([1.0,0.0,0.0,0.0,0.0])
	assert_float(Fabric.quality()).is_equal(0.0)
	# Nothing known of huts: craft alone raises nothing.
	_skill(4.0)
	_reckon(30)
	assert_float(float(f.homes[0])).is_equal(1.0)
	# Thatch and timber framing known, with the craft for them.
	_know(["thatched_roofing","framed_construction"])
	for i in 30:_reckon(30)
	assert_float(float(f.homes[0])).is_less(0.05)
	assert_float(float(f.homes[2])).is_greater(0.5)
	# Mudbrick needs its own knowing: not one place is mudbrick yet.
	assert_float(float(f.homes[3])).is_equal(0.0)
	assert_float(Fabric.quality()).is_greater(0.4)


func test_the_grade_a_people_may_reach_follows_their_craft()->void:
	_know(["thatched_roofing","framed_construction","mould_made_mudbricks","dry_stone_walls"])
	_skill(0.5)
	var low:=Fabric.grade_caps()
	assert_float(float(low[1])).is_equal_approx(0.5,0.001)
	assert_float(float(low[2])).is_equal(0.0)
	_skill(6.0)
	var high:=Fabric.grade_caps()
	assert_float(float(high[3])).is_equal(1.0)
	# Stone: from craft 3, every place only at 9.
	assert_float(float(high[4])).is_equal_approx((6.0-3.0)/(9.0-3.0),0.001)


func test_better_homes_cost_builders_and_real_materials()->void:
	_know(["thatched_roofing","framed_construction"])
	_skill(4.0)
	var timber:=float(GameState.resource_stockpiles.Timber)
	_reckon(30)
	assert_float(float(GameState.resource_stockpiles.Timber)).is_less(timber)
	assert_float(float(Fabric.data().spent.homes)).is_greater(0.0)
	# No materials beyond the town's reserve: no homes rise, the builders idle.
	var f:=Fabric.data()
	f.homes=[1.0,0.0,0.0,0.0,0.0];f.beauty=0.0;f.roads=0.0;f.works=0.0
	for item in ["Timber","Clay","Stone","Fiber Plants"]:GameState.resource_stockpiles[item]=10.0
	_reckon(30)
	assert_float(float(f.homes[0])).is_equal(1.0)
	assert_float(float(f.idle)).is_greater(0.0)


func test_without_builders_everything_wears_and_homes_fall_a_grade()->void:
	_know(["thatched_roofing","framed_construction"])
	var f:=Fabric.data()
	f.homes=[0.0,0.0,1.0,0.0,0.0];f.roads=1000.0;f.beauty=5000.0;f.works=1000.0
	GameState.population_allocations["Construction"]=0
	_reckon(365)
	assert_float(float(f.homes[2])).is_less(1.0)
	assert_float(float(f.homes[1])).is_greater(0.0)
	assert_float(float(f.roads)).is_less(1000.0)
	assert_float(float(f.beauty)).is_less(5000.0)
	assert_float(float(f.works)).is_less(1000.0)
	assert_float(float(f.paid)).is_equal(0.0)
	assert_array(Array(Fabric.decline_words())).is_not_empty()


## Second review 2: worn walls are said, on the page and at court.
func test_unkept_walls_are_said_to_crumble()->void:
	var mc=WorldSimulation.military
	mc._ensure_settlement_defense()
	mc.settlement_defense["stage"]=5
	mc.settlement_defense["project_stage"]=-1
	var f:=Fabric.data()
	f.homes=[0.0,0.0,1.0,0.0,0.0]
	# Too few builders: past the town's repair crew, too few are left to keep
	# the homes and the bastions.
	GameState.population_allocations["Construction"]=5
	_reckon(30)
	assert_float(float(f.kept.walls)).is_less(1.0)
	assert_str(", ".join(Fabric.decline_words())).contains("walls")
	assert_str(Fabric.court_line()).contains("walls")
	assert_float(Fabric.wall_wear(365.0)).is_greater(0.0)


func test_upkeep_keeps_homes_first()->void:
	var f:=Fabric.data()
	f.homes=[0.0,0.0,1.0,0.0,0.0];f.beauty=900000.0
	# A few builders: after the town's repair crew, enough for the homes'
	# upkeep, not the fine works'.
	GameState.population_allocations["Construction"]=9
	_reckon(30)
	assert_float(float(f.kept.homes)).is_equal(1.0)
	assert_float(float(f.kept.beauty)).is_less(1.0)


func test_craft_grows_with_builder_years_and_fades_with_the_generations()->void:
	Fabric.realm_data()
	GameState.fabric_realm["xp"]=0.0
	for i in 12:_reckon(30)
	var grown:=Fabric.craft()
	assert_float(grown).is_greater(0.0)
	# Where it settles: 30 builders among 200 at full pace.
	assert_float(Fabric.craft_settles()).is_equal_approx(30.0*365.0*Fabric.CRAFT_YEARS/200.0/Fabric.CRAFT_PER_LEVEL,0.05)
	GameState.population_allocations["Construction"]=0
	for i in 36:_reckon(365)
	assert_float(Fabric.craft()).is_less(grown*0.5)


func test_roads_reach_only_as_far_as_the_people_know()->void:
	var f:=Fabric.data()
	f.roads=Fabric.ROAD_FULL*200.0
	Fabric._cache(f)
	assert_float(Fabric.roads()).is_equal_approx(0.35,0.001)
	_know(["graded_roads"])
	Fabric._cache(f)
	assert_float(Fabric.roads()).is_equal_approx(0.7,0.001)
	assert_float(Fabric.haul_factor()).is_equal_approx(1.0+Fabric.ROAD_HAUL*0.7,0.001)


func test_the_engine_reads_the_cached_effects()->void:
	var f:=Fabric.data()
	f.homes=[0.0,0.0,0.0,0.0,1.0];f.works=Fabric.WORKS_FULL*200.0;f.beauty=Fabric.BEAUTY_SCALE*200.0*3.0
	Fabric._cache(f)
	assert_float(Fabric.quality()).is_equal(1.0)
	assert_float(Fabric.health_bonus()).is_equal_approx(Fabric.HOME_HEALTH,0.0001)
	assert_float(Fabric.illness_factor()).is_equal_approx(1.0-Fabric.HOME_ILLNESS,0.0001)
	assert_float(Fabric.civic("cohesion")).is_greater(Fabric.HOME_COHESION)
	assert_float(Fabric.making_factor()).is_equal_approx(1.0+Fabric.WORKSHOP_MAKING,0.0001)
	assert_float(Fabric.granary_factor()).is_equal_approx(1.0-Fabric.GRANARY_ROT,0.0001)
	# Kilns need kiln control known; then they act.
	assert_float(Fabric.works_cover("kilns")).is_equal(0.0)
	_know(["kiln_control"])
	assert_float(Fabric.works_cover("kilns")).is_equal(1.0)
	# The crises read the homes: outbreaks and fires come less often.
	var x:Dictionary=preload("res://scripts/crisis_system.gd").inputs(int(GameState.elapsed_days))
	assert_float(float(x.homes_q)).is_equal(1.0)


func test_every_hook_stands_in_its_owners_code()->void:
	# The guards: each place the engine reads the fabric (docs/BUILT_FABRIC.md).
	var guards:=[["consequence_engine.gd","FABRIC.health_bonus()"],["consequence_engine.gd","FABRIC.weather_bonus("],["consequence_engine.gd","FABRIC.illness_factor()"],
		["settlement_construction.gd","Fabric.crews().civic_if"],["settlement_construction.gd","Fabric.crews().homes_if"],["settlement_model.gd","built_fabric.gd\").repair_share()"],
		["military_campaign.gd","built_fabric.gd\").wall_builders()+maxf(0.0,float(watch_at_home()))*0.20"],["home_defense.gd","settlement_defense_daily_work(stage_index,1.0,false)"],
		["consequence_engine.gd","FABRIC.logistics_bonus()"],["consequence_engine.gd",'FABRIC.civic("cohesion")'],["divine_regard.gd","built_fabric.gd\").devotion()"],
		["crisis_system.gd","HOME_SICKNESS*float(x.get(\"homes_q\",0.0))"],["crisis_system.gd","HOME_FIRE*float(x.get(\"homes_q\",0.0))"],
		["food_system.gd","granary_factor()"],["civilian_goods.gd","making_factor()"],["resource_system.gd","water_factor()"],["resource_system.gd","haul_factor()"],["resource_system.gd","extraction_bonus()"],
		["settlement_model.gd","Fabric.speed_factor()"],["settlement_model.gd","Fabric.reach_factor()"],["trade_ledger.gd","ROAD_REACH"],["caravan_system.gd","speed_factor()"],
		["civilization_combat.gd","rise_factor()"],["settlement_model.gd","built_fabric.gd\").crews().infra"],["settlement_model.gd","float(crew.infra)*labor_efficiency"],
		["military_campaign.gd","Fabric.wall_quality()+Fabric.stone_defense()"],["military_campaign.gd","wall_wear(float(WorldSimulation.span))"],["military_campaign.gd","wall_hands(workers,stage_index,builders)"],
		["civilization_controller.gd","wall_wish()"],["standing.gd","Fabric.FORT_STRENGTH*_walls()"],["standing.gd","Fabric.FORT_MIGHT*walls"],["standing.gd","Fabric.BEAUTY_SPLENDOR"],
		["standing.gd","Fabric.BEAUTY_CULTURE"],["standing.gd","Fabric.BEAUTY_RESPECT"],["discovery_system.gd","BUILT_FABRIC.research_multiplier(direction)"],
		["civilization_day.gd","construction_signal()"],["wonder_concept.gd","Fabric.great_capability(s,d.cost,extra.get(\"record\",{}))"],["undertaking_system.gd","great_payoff(state,gifted)"],
		["settlement_construction.gd","Fabric.process_day()"],["settlement_construction.gd","craft_pace()"],["society_model.gd","homes_quality*0.10+roads*0.08"]]
	for guard:Array in guards:
		var source:=FileAccess.get_file_as_string("res://scripts/"+String(guard[0]))
		assert_bool(source.contains(String(guard[1]))).override_failure_message("%s no longer reads the fabric: %s" % [guard[0],guard[1]]).is_true()


func test_builders_raise_stone_walls_the_watch_alone_barely_moves()->void:
	var stone_stage:=Fabric.STONE_STAGE
	GameState.fabric_realm.clear();Fabric.realm_data()
	var mc=WorldSimulation.military
	mc._ensure_settlement_defense()
	mc.settlement_defense["project_stage"]=stone_stage
	GameState.fabric_realm["wall_builders"]=0.0
	var watch_only:=Fabric.wall_hands(20.0,stone_stage)
	assert_float(watch_only).is_equal_approx(20.0*Fabric.STONE_WATCH,0.001)
	GameState.fabric_realm["wall_builders"]=10.0
	assert_float(Fabric.wall_hands(20.0,stone_stage)).is_greater(watch_only+10.0)
	# An earthwork: the watch works at its full pace.
	assert_float(Fabric.wall_hands(20.0,1,false)).is_equal(20.0)


## Review 2: the council judges the next stage with the builders who would
## go to it, and a watchman's rate stays the watch's own.
func test_the_council_counts_the_builders_who_would_raise_the_next_stage()->void:
	GameState.fabric_realm.clear();Fabric.realm_data()
	var mc=WorldSimulation.military
	mc._ensure_settlement_defense()
	mc.settlement_defense["stage"]=3
	mc.settlement_defense["project_stage"]=-1
	GameState.fabric_realm["wall_builders"]=0.0
	GameState.fabric_realm["wall_ready"]=0.0
	var alone:float=mc.settlement_defense_daily_work(4,5.0)
	var full_alone:int=mc.settlement_defense_full_pace_workers(4)
	# A reckoning records the walls crew the next stage would get.
	_reckon(30)
	assert_float(Fabric.wall_builders_ready()).is_greater(0.0)
	assert_float(Fabric.wall_builders()).is_equal(0.0)
	assert_float(float(mc.settlement_defense_daily_work(4,5.0))).is_greater(alone)
	assert_int(int(mc.settlement_defense_full_pace_workers(4))).is_less(full_alone)
	# A watchman's rate is his own: the builders never count in it.
	var per_hand:float=mc.settlement_defense_daily_work(4,1.0,false)
	var by_builders:float=mc.settlement_defense_daily_work(4,0.0,true)
	assert_float(by_builders).is_greater(0.0)
	var efficiency:=clampf(float(GameState.simulation_metrics.get("labor_efficiency",0.72)),0.15,1.25)
	assert_float(per_hand).is_equal_approx(Fabric.STONE_WATCH*efficiency*mc.DEFENSE_WORK_PER_HAND,0.0001)
	# The builders' work comes off what the watch must give.
	var Home:=preload("res://scripts/home_defense.gd")
	var with_builders:=Home.watch_fix(4)
	GameState.fabric_realm["wall_ready"]=0.0
	assert_int(Home.watch_fix(4)).is_greater_equal(with_builders)


## Review 3: every builder works one job: the crews add up to the builders.
func test_every_builder_works_one_job()->void:
	var mc=WorldSimulation.military
	mc._ensure_settlement_defense()
	mc.settlement_defense["project_stage"]=2
	GameState.city_form={"tier":1.0,"condition":0.6}
	GameState.housing_capacity=int(GameState.population_total)-5
	# A water channel takes its own crew (second review: water, waste and rail).
	GameState.water_conveyance.lines.append({"id":1,"status":"active","condition":1.0})
	var c:=Fabric.crews()
	var total:=float(c.homes)+float(c.civic)+float(c.repair)+float(c.infra)+float(c.walls)+float(c.fabric)
	assert_float(total).is_equal_approx(float(c.builders),0.001)
	# Some sleep without a roof: most builders raise homes, never all, so
	# repair and the walls go on.
	assert_float(float(c.homes)).is_equal_approx(float(c.builders)*Fabric.HOMES_SHORT,0.001)
	assert_float(float(c.repair)+float(c.walls)).is_greater(0.0)
	GameState.housing_capacity=int(GameState.population_total)+20
	c=Fabric.crews()
	total=float(c.homes)+float(c.civic)+float(c.repair)+float(c.infra)+float(c.walls)+float(c.fabric)
	assert_float(total).is_equal_approx(float(c.builders),0.001)
	assert_float(float(c.repair)).is_greater(0.0)
	assert_float(float(c.infra)).is_greater(0.0)
	assert_float(float(c.walls)).is_greater(0.0)
	# The civic work and the homes read only their own crews.
	var labor:=float(GameState.simulation_metrics.get("labor_efficiency",.72))
	assert_float(Build.housing_work_per_day()).is_less(float(c.builders)/8.0*labor)
	# Repair counts only the repair crew.
	assert_float(Fabric.repair_share()).is_equal_approx(clampf(float(c.repair)/(float(GameState.population_total)*Fabric.REPAIR_SHARE),0.0,1.0),0.001)


## Review 4: good homes lift the weather's toll on those who have a roof;
## nothing at all in windbreaks, and nothing taken from those sleeping out.
func test_good_homes_ward_off_the_weather_for_the_housed()->void:
	var f:=Fabric.data()
	f.homes=[1.0,0.0,0.0,0.0,0.0];Fabric._cache(f)
	assert_float(Fabric.weather_bonus(1.0,0.0)).is_equal(0.0)
	f.homes=[0.0,0.0,0.0,0.0,1.0];Fabric._cache(f)
	assert_float(Fabric.weather_bonus(1.0,0.0)).is_equal_approx(Fabric.HOME_WEATHER,0.0001)
	assert_float(Fabric.weather_bonus(0.0,0.0)).is_equal(0.0)
	var source:=FileAccess.get_file_as_string("res://scripts/consequence_engine.gd")
	assert_bool(source.contains('mortality_components["Exposure"]=float(mortality_components["Exposure"])*FABRIC')).is_false()


## Review 5: nothing the player reads names a file or a constant.
func test_no_dev_words_on_the_screens()->void:
	_know(["thatched_roofing","framed_construction","kiln_control"])
	_skill(3.0)
	_reckon(30)
	var said:PackedStringArray=[]
	for line:Dictionary in Fabric.effect_lines()+Fabric.plus_lines(10.0):
		said.append(String(line.label));said.append(String(line.value));said.append(String(line.words))
		assert_str(String(line.get("src",""))).is_not_empty()
	var role:=Fabric.role_line(10.0)
	said.append(String(role.now));said.append(String(role.plus_ten))
	said.append(Fabric.court_line())
	said.append(Fabric.great_words(Fabric.great_capability(GameState,{"Stone":10.0}),1.2,{"collapse":0.1},""))
	var dev:=RegEx.create_from_string("\\.gd\\b|\\b[A-Z]{2,}_[A-Z_]+\\b")
	for text in said:
		assert_object(dev.search(text)).override_failure_message("dev words on screen: "+text).is_null()


## Review 6: an older save keeps the roads its map already drew.
func test_an_older_save_keeps_its_roads_and_its_homes_from_the_first_day()->void:
	GameState.built_fabric={}
	GameState.fabric_realm={}
	GameState.elapsed_days=365*60
	GameState.discovery_log.append({"id":"cart_running_gear"})
	_know(["thatched_roofing","framed_construction"])
	var Roads:=preload("res://scripts/settlement_roads.gd")
	assert_int(Roads.known_tier()).is_equal(1)
	# Before any reckoning, the readers see the town as it stands, not lean-tos.
	assert_float(Fabric.quality()).is_greater(0.0)
	Fabric.data()
	assert_float(Fabric.roads()).is_greater_equal(Fabric.ROAD_SEED[1])
	assert_int(int(Roads.knowledge().tier)).is_equal(1)
	# Unkept, the roads wear, but the map keeps the kind the people know and
	# its marches keep their pace: only the ink and the speed of what
	# travels the roads tell their state.
	var f:=Fabric.data()
	f.roads=0.0;Fabric._cache(f);Fabric._report_town(f,Fabric.realm_data())
	assert_int(int(Roads.knowledge().tier)).is_equal(1)
	assert_float(Fabric.ink_quality(GameState)).is_equal(0.0)
	# The realm hears of the town at once.
	assert_bool((GameState.fabric_realm.towns as Dictionary).has("home")).is_true()


## Review 7: the fabric never takes what a great work under way still needs.
func test_great_works_under_way_keep_their_materials()->void:
	var city:={"id":"c1","primary":true,"name":"Here","undertakings":[]}
	GameState.player_settlements=[city]
	var U:=preload("res://scripts/undertaking_system.gd")
	var Concept:=preload("res://scripts/wonder_concept.gd")
	var id:=Concept.make_id("ring","honor_dead","grand","stone",0,"t1")
	var d:=preload("res://scripts/undertaking_catalog.gd").get_definition(id)
	assert_bool(d.is_empty()).is_false()
	city.undertakings.append({"id":id,"status":"building","progress":0.0,"work_scale":1.0})
	var bills:=Fabric.great_bills()
	for item:String in (d.cost as Dictionary):assert_float(float(bills.get(item,0.0))).is_equal_approx(float(d.cost[item]),0.01)
	for item in ["Timber","Clay","Stone","Fiber Plants"]:GameState.resource_stockpiles[item]=float((d.cost as Dictionary).get(item,0.0))+100.0
	var spare:=Fabric._spare(200.0,GameState.resource_stockpiles)
	for item:String in (d.cost as Dictionary):assert_float(float(spare.get(item,0.0))).is_less_equal(100.0)
	# Half built: half the bill is kept.
	city.undertakings[0].progress=U.total_work(city.undertakings[0])*0.5
	assert_float(float(Fabric.great_bills().get("Stone",0.0))).is_equal_approx(float((d.cost as Dictionary).get("Stone",0.0))*0.5,0.01)
	# Second review 3: a grander work (x1.25) still has its larger bill to use.
	city.undertakings[0].work_scale=1.25
	city.undertakings[0].progress=0.0
	assert_float(float(Fabric.great_bills().get("Stone",0.0))).is_equal_approx(float((d.cost as Dictionary).get("Stone",0.0))*1.25,0.01)


## Review 1: a great work resolved inside one town's count reads the whole
## people's craft, as the screen states it.
func test_a_great_works_roll_reads_the_whole_peoples_craft()->void:
	_skill(4.0)
	var whole:=Fabric.craft()
	var model=WorldSimulation.settlements
	model._local_population_scope=true
	model._national_population_in_scope=float(GameState.population_exact)
	var saved:=float(GameState.population_exact)
	GameState.population_exact=saved*0.25
	assert_float(Fabric.craft_of(GameState)).is_equal_approx(whole,0.0001)
	assert_float(Fabric.great_payoff(GameState,false)).is_equal_approx(1.0+Fabric.GREAT_PAYOFF*whole,0.0001)
	GameState.population_exact=saved
	model._local_population_scope=false


## Minor: "settles at" counts every town's builders against the whole people;
## the odds count the crew on the work.
func test_craft_settles_over_every_town_and_odds_count_the_crew_on_the_work()->void:
	Fabric.realm_data()
	GameState.fabric_realm["towns"]={"home":{"day":int(GameState.elapsed_days),"pop":100.0,"builder_days":10.0},"t2":{"day":int(GameState.elapsed_days),"pop":100.0,"builder_days":30.0}}
	assert_float(Fabric.craft_settles()).is_equal_approx(40.0*365.0*Fabric.CRAFT_YEARS/float(GameState.population_exact)/Fabric.CRAFT_PER_LEVEL,0.01)
	var all:=float(GameState.effective_workers("Construction"))
	assert_float(Fabric.great_crew(GameState)).is_equal_approx(all*Fabric.GREAT_CREW_SHARE,0.01)
	# Second review 4: a work under way counts its own crew, never another's.
	var city:={"id":"c1","primary":true,"name":"Here","undertakings":[{"id":"x","status":"building","policy":"press","speed":1.0},{"id":"y","status":"building","policy":"careful","speed":1.0}]}
	GameState.player_settlements=[city]
	var whole:=float(GameState.effective_workers("Construction"))/(1.0-0.65)
	assert_float(Fabric.great_crew(GameState,city.undertakings[1])).is_equal_approx(whole*0.20,0.01)
	assert_float(Fabric.great_crew(GameState,city.undertakings[0])).is_equal_approx(whole*0.50,0.01)


func test_walls_and_stone_strengthen_the_defences_and_might()->void:
	var mc=WorldSimulation.military
	mc._ensure_settlement_defense()
	mc.settlement_defense["stage"]=3
	mc.settlement_defense["integrity"]=1.0
	var before:=float(mc.settlement_defense_snapshot().defense_bonus)
	var f:=Fabric.data()
	f.homes=[0.0,0.0,0.0,0.5,0.5]
	Fabric._cache(f)
	Fabric._report_town(f,Fabric.realm_data())
	var after:=float(mc.settlement_defense_snapshot().defense_bonus)
	assert_float(after).is_greater(before+0.07)
	var Standing:=preload("res://scripts/standing.gd")
	assert_str(String(Standing.strengths().might.why)).contains("walls and stone")


func test_a_great_works_odds_and_payoff_follow_the_builders_and_are_stated()->void:
	var built:Dictionary=Fabric.great_capability(GameState,{"Stone":400.0})
	_skill(5.0)
	var skilled:Dictionary=Fabric.great_capability(GameState,{"Stone":400.0})
	assert_float(float(skilled.total)).is_greater(float(built.total))
	assert_float(Fabric.great_payoff(GameState,false)).is_equal_approx(1.0+Fabric.GREAT_PAYOFF*5.0,0.01)
	assert_float(Fabric.great_payoff(GameState,true)).is_greater(Fabric.great_payoff(GameState,false))
	var words:=Fabric.great_words(skilled,1.25,{"collapse":0.1,"triumph":0.2,"flawed":0.1},"Ama")
	assert_str(words).contains("the odds it stands are 90 in 100")
	assert_str(words).contains("x1.25")
	assert_str(words).contains("Ama, a gifted master builder")


func test_the_screens_say_what_more_builders_would_buy()->void:
	_know(["thatched_roofing","framed_construction"])
	_skill(3.0)
	_reckon(30)
	var line:=Fabric.role_line(10.0)
	assert_str(String(line.now)).contains("Homes")
	assert_str(String(line.plus_ten)).starts_with("Ten more")
	var plus:=Fabric.plus_builders(10.0)
	# Ten more builders: their share after new homes ahead of need (a third)
	# goes to the fabric, about 7 x 365 builder-days.
	assert_float(float(plus.days)).is_greater(1500.0)
	assert_float(float(plus.craft_then)).is_greater(float(plus.craft_settles))
	assert_array(Fabric.effect_lines()).is_not_empty()
	assert_array(Fabric.plus_lines(10.0)).is_not_empty()
	# The Buildings page carries the fabric's blocks.
	var dock=preload("res://scripts/hud/content/dock_content_construction.gd").new(null,null)
	var blocks:Array=dock._fabric_blocks()
	var headings:=[]
	for block:Dictionary in blocks:headings.append(String(block.get("heading","")))
	assert_array(headings).contains(["Homes by kind","The built fabric","What the built fabric does","What ten more builders would buy now"])
