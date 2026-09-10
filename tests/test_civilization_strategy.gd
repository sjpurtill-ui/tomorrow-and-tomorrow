extends GdUnitTestSuite
const Strategy=preload("res://scripts/civilization_strategy.gd")
const Controller=preload("res://scripts/civilization_controller.gd")
const Peaceful={"openness":.8,"discipline":.3,"empathy":.95,"assertiveness":.15,"risk_tolerance":.15}
const Martial={"openness":.35,"discipline":.9,"empathy":.15,"assertiveness":.95,"risk_tolerance":.9}

func after_test()->void:
	WorldSimulation.clear()
	WorldSimulation.context_provider=Callable()

func test_personality_changes_real_strategic_choices_with_identical_conditions()->void:
	var situation:={"food_days":120,"food_intake_ratio":1,"at_war":false}
	var peace:=Strategy.preferences(Peaceful,situation)
	var martial:=Strategy.preferences(Martial,situation)
	assert_float(peace.recruit_share).is_less(martial.recruit_share)
	assert_float(peace.expansion_food).is_greater(martial.expansion_food)
	assert_str(peace.training).is_equal("maintain")
	assert_str(martial.training).is_equal("intensive")
	assert_str(peace.ambition).is_not_equal(martial.ambition)
	assert_str(Strategy.diplomatic_action({"opinion":-.55,"treaty":"none"},peace,120)).is_not_equal("declare_war")
	assert_str(Strategy.diplomatic_action({"opinion":-.55,"treaty":"none"},martial,120)).is_equal("declare_war")

func test_survival_overrides_preference_without_free_resources()->void:
	for personality in [Peaceful,Martial]:
		var plan:=Strategy.preferences(personality,{"food_days":5,"food_intake_ratio":.7,"at_war":true})
		assert_bool(plan.hungry).is_true()
		assert_str(plan.training).is_equal("suspended")
		assert_str(plan.goals[0].id).is_equal("care")
		assert_str(Strategy.diplomatic_action({"at_war":true},plan,5)).is_equal("seek_peace")

func test_abundant_food_is_not_misreported_as_hunger_from_population_ratio()->void:
	var goals:=Strategy.PERSONALITY.agenda({"food_days":120,"food_capacity":65,"population":110},Martial)
	assert_str(goals[0].id).is_not_equal("care")

func test_research_redistribution_keeps_the_same_attention_budget()->void:
	for personality in [Peaceful,Martial]:
		var plan:=Strategy.preferences(personality,{"food_days":120})
		for budget in [0,1,17,36,144]:
			var distribution:=Strategy.research_plan(plan.research_weights,budget)
			var total:=0
			for value in distribution.values():
				total+=int(value);assert_int(value).is_between(0,12)
			assert_int(total).is_equal(budget)

func test_navy_and_air_have_distinct_feasible_doctrines()->void:
	var defensive:=Strategy.preferences(Peaceful,{"food_days":120,"at_war":true})
	var offensive:=Strategy.preferences(Martial,{"food_days":120,"at_war":true})
	assert_str(Strategy.preferred_mission("navy",["hold","patrol","convoy_escort","convoy_raiding"],defensive)).is_equal("convoy_escort")
	assert_str(Strategy.preferred_mission("navy",["hold","patrol","convoy_escort","convoy_raiding"],offensive)).is_equal("convoy_raiding")
	assert_str(Strategy.preferred_mission("air",["hold","reconnaissance","interception","strategic_bombing"],defensive)).is_equal("interception")
	assert_str(Strategy.preferred_mission("air",["hold","reconnaissance","interception","strategic_bombing"],offensive)).is_equal("strategic_bombing")
	assert_str(Strategy.preferred_mission("air",["hold","reconnaissance"],offensive)).is_equal("hold")

func test_twelve_rulers_vary_research_and_timing_without_reducing_frequency()->void:
	var ambitions:Dictionary={};var research:Dictionary={};var review_days:Dictionary={}
	for i in 12:
		var id:="civ_%02d" % i
		var plan:=Strategy.preferences(Strategy.PERSONALITY.foreign(777,id),{"food_days":120})
		ambitions[plan.ambition]=true
		research[JSON.stringify(Strategy.research_plan(plan.research_weights,36))]=true
		var reviews:=0
		for day in range(1,361):
			if Controller.review_due(id,day):reviews+=1;review_days[day%30]=true
		assert_int(reviews).is_equal(12)
	assert_int(ambitions.size()).is_greater_equal(3)
	assert_int(research.size()).is_greater_equal(8)
	assert_int(review_days.size()).is_greater_equal(6)

func _actor(id:String)->void:
	WorldSimulation.create_actor(id,777,Vector2.ZERO)
	WorldSimulation.context_provider=func(_point:Vector2)->Dictionary:return {"environment_profile":PlanetEnvironment.profile_at(Vector2.ZERO),"surface_water_distance_km":.1,"surface_water_recognized":true}
	WorldSimulation.scoped(id,func()->void:
		WorldSimulation.world.scout_land_authority=func(_point:Vector2)->bool:return true
		WorldSimulation.state.simulation_metrics["food_days"]=120.0
		WorldSimulation.state.simulation_metrics["food_intake_ratio"]=1.0
	)

func test_controller_issues_distinct_paid_orders_and_preserves_player_state()->void:
	var human_before:=SaveSystem._capture_reflected(GameState,[])
	var training:Array=[];var recruits:Array=[];var research:Array=[]
	for pair in [["alpha",Peaceful],["beta",Martial]]:
		var id:=String(pair[0]);_actor(id)
		WorldSimulation.scoped(id,func()->void:
			var plan:=Strategy.preferences(pair[1],{"food_days":120,"at_war":false})
			WorldSimulation.submit(id,{"kind":"ambition","id":plan.ambition})
			WorldSimulation.submit(id,{"kind":"found"})
			var before:=WorldSimulation.state.population_exact
			var inventory:=WorldSimulation.military.military_inventory.duplicate(true)
			Controller.research_orders(id,plan)
			Controller.military_orders(id,plan)
			training.append(WorldSimulation.military.training_staff.policy("army").id)
			recruits.append(WorldSimulation.military._mobilized_count())
			research.append(WorldSimulation.state.research_allocations.duplicate(true))
			assert_float(WorldSimulation.state.population_exact).is_equal(before)
			# Orders have no right to conjure weapons; production happens over time.
			for item in WorldSimulation.military.military_inventory:
				assert_int(WorldSimulation.military.military_inventory[item]).is_less_equal(int(inventory.get(item,0)))
		)
	assert_str(training[0]).is_not_equal(training[1])
	assert_int(recruits[0]).is_less(recruits[1])
	assert_bool(research[0]==research[1]).is_false()
	assert_dict(SaveSystem._capture_reflected(GameState,[])).is_equal(human_before)

func test_invalid_research_orders_do_not_change_any_budget()->void:
	_actor("validator")
	WorldSimulation.scoped("validator",func()->void:
		var before:=WorldSimulation.state.research_allocations.duplicate(true)
		for order in [{"kind":"research_emphasis","domain":"magic","weight":12},{"kind":"research_emphasis","domain":"knowledge","weight":100}]:
			assert_bool(WorldSimulation.submit("validator",order).has("error")).is_true()
		assert_dict(WorldSimulation.state.research_allocations).is_equal(before)
	)

func test_actual_controller_uses_the_dialogue_personality_and_survives_save()->void:
	_actor("ruler")
	WorldSimulation.scoped("ruler",func()->void:
		var plan:=Controller.current_plan("ruler")
		assert_dict(plan.personality).is_equal(Strategy.PERSONALITY.foreign(777,"ruler"))
		Controller.choose_orders("ruler")
		preload("res://scripts/civilization_day.gd").advance(1,preload("res://scripts/civilization_day.gd").context(Vector2.ZERO))
	)
	var before:=WorldSimulation.capture_actor("ruler")
	var saved:=WorldSimulation.export_state()
	assert_bool(WorldSimulation.import_state(bytes_to_var(var_to_bytes(saved))).get("ok",false)).is_true()
	var after:=WorldSimulation.capture_actor("ruler")
	for system in ["GameState","PeopleDirection","DiscoverySystem","MilitaryCampaign"]:
		assert_bool(after[system]==before[system]).override_failure_message("Save changed "+system).is_true()
	WorldSimulation.scoped("ruler",func()->void:
		assert_dict(Controller.current_plan("ruler").personality).is_equal(Strategy.PERSONALITY.foreign(777,"ruler"))
	)

func test_air_equipment_feasibility_uses_its_own_recipe_and_real_stores()->void:
	_actor("air_planner")
	WorldSimulation.scoped("air_planner",func()->void:
		var state:=WorldSimulation.state
		var campaign:=WorldSimulation.military
		state.settlement_completed=["Hearth Circle"];WorldSimulation.settlements.ensure_founded()
		state.known_discoveries.append("aerostat_observation");state.discovery_adoption["aerostat_observation"]=1.0
		for item in ["Timber","Stone","Iron Ore","Fiber Plants","Bitumen"]:state.resource_stockpiles[item]=1000.0
		assert_bool(campaign.joint_operations.build_base(String(state.player_settlements[0].id),"air").has("ok")).is_true()
		campaign.joint_operations.state.bases[0].construction_work=30.0
		assert_bool(Controller.can_supply_equipment(campaign,"observation_balloon_equipment")).is_true()
		state.resource_stockpiles.Bitumen=0.0
		assert_bool(Controller.can_supply_equipment(campaign,"observation_balloon_equipment")).is_false()
		assert_bool(Controller.can_supply_equipment(campaign,"jet_fighter_equipment")).is_false()
	)

func test_stated_security_goal_receives_research_even_with_small_budget()->void:
	var cautious_guard:={"openness":.2,"discipline":.9,"empathy":.2,"assertiveness":.3,"risk_tolerance":.1}
	var plan:=Strategy.preferences(cautious_guard,{"food_days":120,"food_intake_ratio":1})
	assert_str(plan.goals[0].id).is_equal("security")
	assert_int(Strategy.research_plan(plan.research_weights,4).security).is_greater(0)
