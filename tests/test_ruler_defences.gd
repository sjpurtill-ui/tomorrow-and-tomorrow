extends GdUnitTestSuite
## Computer-run peoples raise settlement defences (civilization_controller
## defense_orders) through the court's own call (civilization_orders
## "settlement_defense" -> MilitaryCampaign.start_settlement_defense_upgrade):
## the same works, materials and Defense labour as the player's order, decided
## from the ruler's own world (war, attacks, hostile or tempting neighbours,
## stores and hands to spare) and weighed by its temper.

const Controller:=preload("res://scripts/civilization_controller.gd")
const Strategy:=preload("res://scripts/civilization_strategy.gd")
const Wary:={"openness":.5,"discipline":.8,"empathy":.7,"assertiveness":.3,"risk_tolerance":.1}
const Bold:={"openness":.4,"discipline":.3,"empathy":.2,"assertiveness":.95,"risk_tolerance":.95}
const STORES:={"Food":20000.0,"Timber":5000.0,"Stone":5000.0,"Fiber Plants":5000.0,"Clay":5000.0}

func before_test()->void:
	WorldSimulation.clear()
	# Views are copied from a full civilization record; another suite may leave a bare one.
	if CivilizationSystem.civilizations.is_empty() or ((CivilizationSystem.civilizations[0] as Dictionary).get("strategic_regions",[]) as Array).is_empty():CivilizationSystem.reset_for_new_world()
	WorldSimulation.context_provider=func(_origin:Vector2)->Dictionary:return {"environment_profile":PlanetEnvironment.profile_at(Vector2.ZERO),"surface_water_distance_km":.1,"surface_water_recognized":true}
	for id in ["alpha","beta"]:
		WorldSimulation.create_actor(id,777,Vector2.ZERO)
		WorldSimulation.actors[id].systems.CivilizationSystem.scout_land_authority=func(_point:Vector2)->bool:return true
		WorldSimulation.actors[id].controller="manual"
		_settle(id)

func after_test()->void:
	WorldSimulation.clear()
	WorldSimulation.context_provider=Callable()

func _settle(id:String)->void:
	WorldSimulation.scoped(id,func()->void:
		var state:=WorldSimulation.state
		state.settlement_site_committed=true
		state.settlement_completed.assign(["Hearth Circle"])
		WorldSimulation.settlements.ensure_founded()
		state.resource_stockpiles.merge(STORES,true)
		state.population_allocations["Defense"]=24
		state.simulation_metrics["food_days"]=120.0
		state.simulation_metrics["labor_efficiency"]=0.82)

func _plan(personality:Dictionary)->Dictionary:
	return Strategy.preferences(personality,{"food_days":120})

## `id` knows another people, and how it feels toward it.
func _neighbour(id:String,opinion:float,tension:float=0.2)->void:
	WorldSimulation.scoped(id,func()->void:
		WorldSimulation.world.civilizations.append({"id":"stranger","name":"Strangers","alive":true,"player_relation":{"contact_level":2,"opinion":opinion,"border_tension":tension,"at_war":false,"treaty":"none"}}))

func _decide(id:String,plan:Dictionary)->Dictionary:
	return WorldSimulation.scoped(id,func()->Dictionary:return Controller.defense_decision(plan))

## The ruler's monthly review runs in its own scope (the day job's group).
func _order(id:String,plan:Dictionary)->void:
	WorldSimulation.scoped(id,func()->void:Controller.defense_orders(id,plan))

func _stage(id:String,stage:int)->void:
	WorldSimulation.actors[id].systems.MilitaryCampaign.settlement_defense={"stage":stage,"integrity":1.0,"project_stage":-1,"project_progress":0.0,"project_work":0.0,"reserved_materials":{},"completed_day":0}

func test_a_ruler_that_knows_no_one_and_fears_nothing_builds_nothing()->void:
	var decision:=_decide("alpha",_plan(Wary))
	assert_bool(bool(decision.build)).is_false()
	assert_float(float(decision.danger)).is_equal(0.0)
	assert_str(" ".join(PackedStringArray(decision.blockers))).contains("below the")
	_order("alpha",_plan(Wary))
	assert_int(int(WorldSimulation.actors.alpha.systems.MilitaryCampaign.settlement_defense.get("project_stage",-1))).is_equal(-1)

func test_danger_and_temper_decide_and_the_order_pays_like_the_courts()->void:
	for id in ["alpha","beta"]:
		_neighbour(id,-0.4)
		_stage(id,2)
	var wary:=_decide("alpha",_plan(Wary))
	var bold:=_decide("beta",_plan(Bold))
	print("DEFENCE WARY: ",wary.reason," · BOLD: ",bold.reason,bold.blockers)
	# The same hostile neighbour: the wary ruler raises a palisade, the bold one trusts its spears.
	assert_float(float(wary.danger)).is_equal(float(Controller.DEFENSE_DANGER.hostile))
	assert_float(float(wary.wariness)).is_greater(float(bold.wariness))
	assert_bool(bool(wary.build)).override_failure_message(str(wary)).is_true()
	assert_bool(bool(bold.build)).is_false()
	assert_int(int(wary.stage)).is_equal(3)
	var before:Dictionary=WorldSimulation.actors.alpha.systems.GameState.resource_stockpiles.duplicate(true)
	_order("alpha",_plan(Wary))
	var defense:Dictionary=WorldSimulation.actors.alpha.systems.MilitaryCampaign.settlement_defense
	assert_int(int(defense.project_stage)).is_equal(3)
	var logged:Array=WorldSimulation.actors.alpha.orders.filter(func(entry:Dictionary)->bool:return String(entry.order.kind)=="settlement_defense")
	assert_int(logged.size()).is_equal(1)
	assert_str(String(logged[0].order.reason)).contains("Palisade")
	# The court's own call with the same stores costs exactly the same.
	var stage:Dictionary=MilitaryCampaign.SETTLEMENT_DEFENSE_STAGES[3]
	var after:Dictionary=WorldSimulation.actors.alpha.systems.GameState.resource_stockpiles
	for material:String in stage.materials:
		assert_float(float(before[material])-float(after[material])).is_equal_approx(float(stage.materials[material]),.0001)
	# One stage at a time: another review adds nothing while it rises.
	_order("alpha",_plan(Wary))
	assert_int(WorldSimulation.actors.alpha.orders.filter(func(entry:Dictionary)->bool:return String(entry.order.kind)=="settlement_defense").size()).is_equal(1)
	# (A new world for the court's side clears the owned peoples.)
	GameState.reset_for_new_world(777)
	GameState.settlement_site_committed=true
	GameState.resource_stockpiles.merge(STORES,true)
	GameState.population_allocations["Defense"]=24
	MilitaryCampaign.reset_for_new_world()
	MilitaryCampaign.settlement_defense={"stage":2,"integrity":1.0,"project_stage":-1,"project_progress":0.0,"project_work":0.0,"reserved_materials":{},"completed_day":0}
	var court:=MilitaryCampaign.start_settlement_defense_upgrade()
	assert_bool(bool(court.get("ok",false))).is_true()
	for material:String in stage.materials:
		assert_float(float(STORES[material])-float(GameState.resource_stockpiles[material])).is_equal_approx(float(stage.materials[material]),.0001)

func test_war_and_a_raid_on_the_home_are_read_from_the_rulers_own_world()->void:
	_stage("alpha",3)
	var calm:=_decide("alpha",_plan(Bold))
	assert_bool(bool(calm.build)).is_false()
	WorldSimulation.scoped("alpha",func()->void:
		WorldSimulation.state.elapsed_days=900
		WorldSimulation.military.battle_history.push_front({"day":700,"campaign_mode":"defensive","target_region_id":"","outcome":"attacker_victory"}))
	var raided:=_decide("alpha",_plan(Bold))
	assert_float(float((raided.parts as Dictionary).get("attacked",0.0))).is_equal(float(Controller.DEFENSE_DANGER.attacked))
	var at_war:=_plan(Bold);at_war["at_war"]=true
	var warring:=_decide("alpha",at_war)
	assert_float(float(warring.danger)).is_equal(1.0)
	# A raid remembered for two years; after that it is history.
	WorldSimulation.scoped("alpha",func()->void:WorldSimulation.state.elapsed_days=700+Controller.DEFENSE_MEMORY_DAYS+1)
	assert_bool((_decide("alpha",_plan(Bold)).parts as Dictionary).has("attacked")).is_false()

func test_no_stores_or_hands_to_spare_means_no_works()->void:
	_neighbour("alpha",-0.6,0.6)
	var stage:Dictionary=MilitaryCampaign.SETTLEMENT_DEFENSE_STAGES[1]
	WorldSimulation.scoped("alpha",func()->void:
		for material:String in stage.materials:WorldSimulation.state.resource_stockpiles[material]=float(stage.materials[material])*1.5)
	var thin:=_decide("alpha",_plan(Wary))
	assert_bool(bool(thin.build)).is_false()
	assert_str(" ".join(PackedStringArray(thin.blockers))).contains("needed to spare it")
	WorldSimulation.scoped("alpha",func()->void:
		WorldSimulation.state.resource_stockpiles.merge(STORES,true)
		WorldSimulation.state.population_allocations["Defense"]=0)
	var idle:=_decide("alpha",_plan(Wary))
	assert_bool(bool(idle.build)).is_false()
	assert_str(" ".join(PackedStringArray(idle.blockers))).contains("Defense workers")
	WorldSimulation.scoped("alpha",func()->void:
		WorldSimulation.state.population_allocations["Defense"]=24
		WorldSimulation.state.simulation_metrics["food_days"]=10.0)
	assert_str(" ".join(PackedStringArray(_decide("alpha",_plan(Wary)).blockers))).contains("food for 10 days")

func test_the_order_takes_only_the_next_stage_and_the_works_rise_on_the_map()->void:
	assert_bool(WorldSimulation.submit("alpha",{"kind":"settlement_defense","stage":4}).has("error")).is_true()
	assert_bool(bool(WorldSimulation.submit("alpha",{"kind":"settlement_defense","stage":1}).get("ok",false))).is_true()
	# Defense labour raises it day by day, as it does the player's.
	WorldSimulation.scoped("alpha",func()->void:
		for day in 60:WorldSimulation.military._process_settlement_defense_day())
	var defense:Dictionary=WorldSimulation.actors.alpha.systems.MilitaryCampaign.settlement_defense
	assert_int(int(defense.stage)).is_equal(1)
	# Others see the town fortified (world_simulation projection: stage / 5).
	var civ:Dictionary=CivilizationSystem.civilizations[0].duplicate(true)
	civ.id="alpha"
	WorldSimulation.scoped("alpha",func()->void:WorldSimulation.project(civ))
	var fortified:=0.0
	for region:Dictionary in civ.strategic_regions:fortified=maxf(fortified,float(region.get("fortification",0.0)))
	assert_float(fortified).is_equal_approx(1.0/5.0,.0001)
