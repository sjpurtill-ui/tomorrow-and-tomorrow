extends GdUnitTestSuite
## Scouting must stay a viable path when population growth is historically
## slow (about 0.15-0.3% a year). A village of a few hundred gains roughly one
## person a year, so steady scout attrition would bleed it dry. These tests run
## two centuries of standing scouting through the real survival rules and the
## Chief Scout's prudence, and check the civilization-system wiring.

const Survival=preload("res://scripts/scout_survival.gd")
const System=preload("res://scripts/civilization_system.gd")

var system:Node


func before_test()->void:
	WorldSimulation.clear()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	GameState.reset_for_new_world(424242);ProgressionSystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world();FoodSystem.reset_for_new_world()
	GameState.ensure_population_total(300);GameState.settlement_site_committed=true
	GameState.resource_stockpiles.Food=20000.0;GameState.food_stocks={"Preserved food":20000.0}
	system=auto_free(System.new());system.reset_for_new_world();system.register_player_origin(Vector2.ZERO)
	system.set_scout_geography_authority(func(_point:Vector2)->bool:return true)


func after_test()->void:
	GameState.set_process(true);CivilizationSystem.set_process(true);MilitaryCampaign.set_process(true)


## The pre-change rule: every mission rolled 10% + 22% per year of duration
## and, on a hit, lost 1..personnel/4 scouts. Kept here only to document the
## audit baseline.
static func _legacy_mission_deaths(duration:int,personnel:int)->float:
	var hazard:=clampf(0.10+float(duration)/365.0*0.22,0.0,0.34)
	var cap:=maxi(1,personnel/4)
	return hazard*(1.0+float(cap))/2.0 if personnel>1 else 0.0


## Two hundred years of standing, staff-managed scouting. Natural increase is
## a fixed annual rate; scouting deaths are the only other change. Parties are
## organized every month the way scouting_staff does: a share of the people,
## at most the Chief Scout's party count and duration, and no new party once
## the standing expected toll exceeds the risk budget.
func _simulate(years:int,growth_rate:float,share:float,use_prudence:bool,seed_value:int)->Dictionary:
	var rng:=RandomNumberGenerator.new();rng.seed=seed_value
	var population:=300.0
	var veterancy:=0.0
	var parties:Array[Dictionary]=[]
	var scout_deaths:=0
	var natural_total:=0.0
	var explored_km:=0.0
	var returned:=0
	var mishaps:=0
	var yearly_net:Array[float]=[]
	var year_natural:=0.0
	var year_deaths:=0
	var last_year_net:=population*growth_rate
	var explored_by_block:Array[float]=[0.0,0.0,0.0,0.0]
	var max_stance_duration:=0
	for month in years*12:
		var day:=month*30
		# Natural increase, independent of scouting.
		var natural:=population*growth_rate/12.0
		population+=natural;natural_total+=natural;year_natural+=natural
		# Returns.
		for party:Dictionary in parties.duplicate():
			if day<int(party.return_day):continue
			parties.erase(party)
			var assessment:Dictionary=party.assessment
			var outcome:=Survival.resolve(assessment,int(party.personnel),rng)
			if assessment.has("legacy"):
				# The old flat rule, replayed for the audit baseline.
				var hazard:=clampf(0.10+float(party.duration)/365.0*0.22,0.0,0.34)
				var legacy_lost:=0
				if int(party.personnel)>1 and rng.randf()<hazard:legacy_lost=mini(rng.randi_range(1,maxi(1,int(party.personnel)/4)),int(party.personnel)-1)
				outcome={"kind":"loss" if legacy_lost>0 else "safe","lost":legacy_lost,"mishap":""}
			var lost:=int(outcome.lost)
			scout_deaths+=lost;year_deaths+=lost;population-=lost
			if String(outcome.kind)=="mishap":mishaps+=1
			var reach:=float(party.one_way_km)*(0.6 if String(outcome.mishap)=="turned_back" else 1.0)
			if lost==0:returned+=1
			explored_km+=reach*2.0
			explored_by_block[mini(3,month/(12*50))]+=reach*2.0
			veterancy=Survival.updated_veterancy(veterancy,int(party.personnel)-lost,int(party.personnel),lost)
		if month%12==11:
			last_year_net=year_natural-float(year_deaths)
			yearly_net.append(last_year_net)
			year_natural=0.0;year_deaths=0
		# Staff departures.
		var capacity:=clampi(int(population)/60,1,6)
		var max_duration:=365
		var budget:=INF
		if use_prudence:
			var caution:=Survival.prudence(population,last_year_net)
			capacity=mini(capacity,int(caution.max_parties))
			max_duration=int(caution.max_duration)
			budget=float(caution.budget)
			max_stance_duration=maxi(max_stance_duration,max_duration)
		var target:=int(population*share)
		var away:=0
		var standing:=0.0
		for party:Dictionary in parties:
			away+=int(party.personnel);standing+=float(party.assessment.annual_expected_deaths)
		while parties.size()<capacity and target-away>=2:
			var slots:=capacity-parties.size()
			var personnel:=clampi(ceili(float(target-away)/float(slots)),2,80)
			# Near ground is charted first; later parties need longer journeys.
			var wanted:=30 if explored_km<3000.0 else (90 if explored_km<15000.0 else (180 if explored_km<60000.0 else 365))
			var duration:=mini(wanted,max_duration)
			var one_way:=float(duration)*14.0*0.8
			var assessment:=Survival.assess({"duration_days":duration,"one_way_km":one_way,"personnel":personnel,"terrain_danger":rng.randf_range(0.2,0.6),"start_day":day,"veterancy":veterancy,"reckless":false})
			if not use_prudence:
				# Replay the old flat hazard for the audit baseline.
				assessment={"death_chance":0.0,"mishap_chance":0.0,"annual_expected_deaths":0.0,"legacy":_legacy_mission_deaths(duration,personnel)}
			if parties.size()>0 and standing+float(assessment.annual_expected_deaths)>budget:break
			parties.append({"return_day":day+duration,"duration":duration,"personnel":personnel,"one_way_km":one_way,"assessment":assessment})
			away+=personnel;standing+=float(assessment.annual_expected_deaths)
	return {"population":population,"scout_deaths":scout_deaths,"natural_total":natural_total,"explored_km":explored_km,"returned":returned,"mishaps":mishaps,"yearly_net":yearly_net,"veterancy":veterancy,"explored_by_block":explored_by_block,"max_duration":max_stance_duration}


func test_two_centuries_of_scouting_at_low_growth_never_drives_decline()->void:
	for seed_value in [11,23,57]:
		var run:=_simulate(200,0.002,0.08,true,seed_value)
		var deaths:=int(run.scout_deaths)
		var natural:=float(run.natural_total)
		print("SCOUT_SURVIVAL seed=%d natural=%.1f scout_deaths=%d share=%.3f explored_km=%.0f returned=%d mishaps=%d veterancy=%.2f" % [seed_value,natural,deaths,float(deaths)/natural,float(run.explored_km),int(run.returned),int(run.mishaps),float(run.veterancy)])
		# Scouting alone never turns the people into a shrinking population.
		assert_float(float(run.population)).is_greater(300.0)
		var worst_decade:=INF
		var yearly:Array[float]=run.yearly_net
		for start in range(0,yearly.size()-9,10):
			var decade:=0.0
			for index in range(start,start+10):decade+=yearly[index]
			worst_decade=minf(worst_decade,decade)
		assert_float(worst_decade).override_failure_message("a decade of scouting outweighed natural increase (%.2f)" % worst_decade).is_greater(0.0)
		# Deaths stay a small fraction of natural increase.
		assert_float(float(deaths)/natural).is_less(0.20)
		# Exploration keeps progressing in every half-century.
		for block:float in run.explored_by_block:assert_float(block).is_greater(1000.0)
		assert_int(int(run.returned)).is_greater(400)
		# Most trouble on the road was survivable.
		assert_int(int(run.mishaps)).is_greater(deaths*4)
		# The corps learns.
		assert_float(float(run.veterancy)).is_greater(0.5)


func test_audit_baseline_old_rule_bled_the_people()->void:
	var legacy:=_simulate(50,0.002,0.08,false,11)
	var modern:=_simulate(50,0.002,0.08,true,11)
	print("SCOUT_SURVIVAL_AUDIT 50y legacy: deaths=%d natural=%.1f pop=%.0f | new: deaths=%d natural=%.1f pop=%.0f" % [int(legacy.scout_deaths),float(legacy.natural_total),float(legacy.population),int(modern.scout_deaths),float(modern.natural_total),float(modern.population)])
	assert_int(int(legacy.scout_deaths)).is_greater(roundi(float(legacy.natural_total)))
	assert_float(float(legacy.population)).is_less(300.0)
	assert_float(float(modern.population)).is_greater(300.0)


func test_expected_toll_is_a_small_share_of_natural_increase()->void:
	## Analytic check without dice: the Chief Scout's standing program at
	## 0.2%/yr costs a small fraction of the ~0.6 people a year gained.
	var population:=300.0
	var increase:=population*0.002
	var caution:=Survival.prudence(population,increase)
	assert_str(String(caution.stance)).is_equal("steady")
	assert_int(int(caution.max_duration)).is_less_equal(180)
	var one:=Survival.assess({"duration_days":90,"one_way_km":90.0*14.0*0.8,"personnel":4,"terrain_danger":0.4,"start_day":0,"veterancy":0.0})
	var allowed:=maxi(1,floori(float(caution.budget)/float(one.annual_expected_deaths)))
	var standing:=float(one.annual_expected_deaths)*float(mini(allowed,int(caution.max_parties)))
	assert_float(standing).is_less_equal(maxf(float(caution.budget),float(one.annual_expected_deaths)))
	assert_float(standing/increase).is_less(0.20)
	# Audit baseline: the old rule cost several times the entire increase.
	var legacy_per_year:=_legacy_mission_deaths(30,3)*12.0*5.0
	print("SCOUT_SURVIVAL_AUDIT legacy_deaths_per_year=%.2f new_standing=%.3f natural_increase=%.2f" % [legacy_per_year,standing,increase])
	assert_float(legacy_per_year).is_greater(increase*5.0)


func test_shrinking_people_make_the_chief_scout_guarded()->void:
	var shrinking:=Survival.prudence(300.0,-0.9)
	assert_str(String(shrinking.stance)).is_equal("guarded")
	assert_int(int(shrinking.max_duration)).is_equal(30)
	assert_int(int(shrinking.max_parties)).is_equal(1)
	assert_float(float(shrinking.budget)).is_equal(Survival.FLOOR_BUDGET)
	assert_str(String(Survival.prudence(300.0,0.3).stance)).is_equal("cautious")
	assert_str(String(Survival.prudence(300.0,0.6).stance)).is_equal("steady")
	assert_str(String(Survival.prudence(300.0,0.9).stance)).is_equal("steady")
	assert_str(String(Survival.prudence(3000.0,30.0).stance)).is_equal("bold")
	# Even while shrinking, a single short party stays out and loses almost no one.
	var run:=_simulate(200,-0.003,0.08,true,5)
	assert_float(float(run.explored_km)).is_greater(1000.0)
	assert_int(int(run.max_duration)).is_equal(30)
	assert_int(int(run.scout_deaths)).is_less_equal(12)


func test_reckless_orders_raise_the_honest_risk()->void:
	var context:={"duration_days":365,"one_way_km":4000.0,"personnel":6,"terrain_danger":0.5,"start_day":300,"veterancy":0.2}
	var careful:=Survival.assess(context)
	context["reckless"]=true
	var reckless:=Survival.assess(context)
	assert_float(float(reckless.death_chance)).is_greater(float(careful.death_chance)*2.0)
	assert_float(float(reckless.hostile_multiplier)).is_greater(float(careful.hostile_multiplier))
	assert_float(Survival.destroyed_share(0.5,false,true)).is_greater(Survival.destroyed_share(0.5,false,false))
	assert_float(float(reckless.death_chance)).is_less_equal(Survival.MAX_DEATH_CHANCE)
	assert_str(String(reckless.label)).is_not_equal("LOW")


func test_distance_terrain_season_and_skill_shape_the_odds()->void:
	var base:={"duration_days":90,"one_way_km":300.0,"personnel":4,"terrain_danger":0.3,"start_day":180,"veterancy":0.0}
	var reference:=float(Survival.assess(base).death_chance)
	var harsh:=base.duplicate();harsh["terrain_danger"]=0.9
	var far:=base.duplicate();far["one_way_km"]=1200.0
	var winter:=base.duplicate();winter["start_day"]=340
	var veteran:=base.duplicate();veteran["veterancy"]=0.8
	assert_float(float(Survival.assess(harsh).death_chance)).is_greater(reference)
	assert_float(float(Survival.assess(far).death_chance)).is_greater(reference)
	assert_float(float(Survival.assess(winter).death_chance)).is_greater(reference)
	assert_float(float(Survival.assess(veteran).death_chance)).is_less(reference*0.6)
	assert_float(Survival.terrain_danger([{"height":7.0,"biome":"tundra","temperature":0.05}])).is_greater(Survival.terrain_danger([{"height":0.5,"biome":"grassland","temperature":0.5}]))
	var skill:=0.0
	for trip in 30:skill=Survival.updated_veterancy(skill,4,4,0)
	assert_float(skill).is_greater(0.5)
	assert_float(Survival.updated_veterancy(skill,3,4,1)).is_less(Survival.updated_veterancy(skill,4,4,0))


func test_most_trouble_on_the_road_is_not_death()->void:
	var assessment:=Survival.assess({"duration_days":90,"one_way_km":1000.0,"personnel":4,"terrain_danger":0.4,"start_day":0,"veterancy":0.1})
	var rng:=RandomNumberGenerator.new();rng.seed=99
	var losses:=0;var mishaps:=0
	for trial in 20000:
		var outcome:=Survival.resolve(assessment,4,rng)
		if String(outcome.kind)=="loss":losses+=1
		elif String(outcome.kind)=="mishap":mishaps+=1
	assert_float(float(losses)/20000.0).is_less(0.02)
	assert_int(mishaps).is_greater(losses*8)


func test_real_parties_carry_field_odds_and_train_the_corps()->void:
	var careful:Dictionary=system.scout_mission_quote(90,"open_world","north",4)
	var reckless:Dictionary=system.scout_mission_quote(90,"open_world","north",4,false,"",true)
	assert_bool(bool(careful.can_dispatch)).override_failure_message(str(careful.get("blocker",""))).is_true()
	assert_float(float(reckless.field_risk.death_chance)).is_greater(float(careful.field_risk.death_chance))
	var sent:Dictionary=system.dispatch_scouts(90,"open_world","north",4,false,"",true)
	assert_bool(bool(sent.get("ok",false))).override_failure_message(str(sent)).is_true()
	assert_str(String(sent.message)).contains("regardless of danger")
	var mission:Dictionary=system.scout_missions[0]
	assert_bool(bool(mission.reckless)).is_true()
	assert_float(float(mission.field_death_chance)).is_greater(0.0)
	assert_array(system.validate_state()).is_empty()
	var before:float=system.scouting_staff.veterancy()
	var population_before:=GameState.population_total
	var fate:Dictionary=system._resolve_party_fate(mission,90)
	assert_int(int(fate.lost)).is_less_equal(2)
	assert_int(GameState.population_total).is_equal(population_before-int(fate.lost))
	if int(fate.returned)>0:assert_float(system.scouting_staff.veterancy()).is_greater(before)
	var saved:Dictionary=JSON.parse_string(JSON.stringify(system.scouting_staff.data))
	assert_bool(system.scouting_staff.valid(saved)).is_true()
	# Older saves have no field odds: the route is judged on return.
	var legacy:Dictionary=mission.duplicate(true)
	for key in ["terrain_danger","veterancy","reckless","field_death_chance","field_annual_risk"]:legacy.erase(key)
	assert_float(float(system._scout_field_assessment(legacy).death_chance)).is_greater(0.0)
	assert_bool(system.scouting_staff.valid({"share":0.05,"focus":"exploration"})).is_true()


func test_hostile_contact_usually_ends_in_capture_or_a_chase()->void:
	system.initialize()
	system.civilizations[0]["aggression"]=0.5
	assert_bool(bool(system.dispatch_scouts(90).get("ok",false))).is_true()
	var mission:Dictionary=system.scout_missions[0]
	var route:Array=mission.route
	var waypoint:Dictionary=route[route.size()/2]
	system.civilizations[0]["position"]=Vector2(float(waypoint.x)/18000.0,float(waypoint.z)/9000.0)
	var fates:Dictionary={}
	for step in 100:
		var roll:=(float(step)+0.5)/100.0
		var result:Dictionary=system._resolve_player_scout_interception(mission,90,0.0,roll)
		fates[String(result.fate)]=int(fates.get(String(result.fate),0))+1
	assert_int(int(fates.get("destroyed",0))).is_less(20)
	assert_int(int(fates.get("driven_off",0))).is_greater(0)
	# A chased party comes home early with a partial chart instead of dying.
	var population_before:=GameState.population_total
	var length_before:float=system._scout_route_distance(route)
	system._turn_scout_party_back(mission,0.5,"chased")
	assert_float(system._scout_route_distance(mission.route)).is_equal_approx(length_before*0.5,length_before*0.01)
	assert_str(String(mission.route_status)).is_equal("turned_back")
	assert_int(GameState.population_total).is_equal(population_before)


func test_guarded_chief_scout_keeps_one_short_party_when_people_shrink()->void:
	# A year of recorded deaths outpacing births.
	GameState.elapsed_days=500
	GameState.vital_statistics_tracking_start_day=100
	GameState.vital_statistics_history.append({"day":480,"births":0,"deaths":6})
	var caution:Dictionary=system.scouting_staff.prudence()
	assert_str(String(caution.stance)).is_equal("guarded")
	system.scouting_staff.set_policy(.10,"exploration")
	for day in range(500,560,7):
		GameState.elapsed_days=day;system.scouting_staff.advance(day)
	assert_int(system.scout_missions.size()).is_less_equal(1)
	for mission:Dictionary in system.scout_missions:assert_int(int(mission.duration_days)).is_equal(30)
	assert_dict(system.scouting_staff.snapshot().prudence).contains_keys(["stance","budget","standing_risk"])


func test_court_order_to_go_far_regardless_sends_a_reckless_party()->void:
	var commands:=preload("res://scripts/court_commands.gd")
	CivilizationSystem.reset_for_new_world();CivilizationSystem.register_player_origin(Vector2.ZERO)
	CivilizationSystem.set_scout_geography_authority(func(_point:Vector2)->bool:return true)
	var result:Dictionary=commands._send("scout_order",{},{},{},{"heading":"north"},{},"Send scouts north, far beyond the hills, regardless of the danger.")
	assert_bool(bool(result.get("executed",false))).override_failure_message(str(result)).is_true()
	var party:Dictionary=CivilizationSystem.scout_missions[-1]
	assert_bool(bool(party.get("reckless",false))).is_true()
	assert_int(int(party.duration_days)).is_greater(30)
	assert_str(String(result.outcome)).contains("not to turn back")
	var careful:Dictionary=commands._send("scout_order_2",{},{},{},{"heading":"south"},{},"Send scouts to the south.")
	assert_bool(bool(careful.get("executed",false))).is_true()
	assert_bool(bool((CivilizationSystem.scout_missions[-1] as Dictionary).get("reckless",false))).is_false()
	CivilizationSystem.scout_missions.clear()
	CivilizationSystem.set_scout_geography_authority(Callable())
