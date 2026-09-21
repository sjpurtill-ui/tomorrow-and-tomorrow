extends GdUnitTestSuite
const DAY=preload("res://scripts/civilization_day.gd")

func before_test()->void:
	WorldSimulation.clear()
	WorldSimulation.context_provider=func(_origin:Vector2)->Dictionary:return {"environment_profile":PlanetEnvironment.profile_at(Vector2.ZERO),"surface_water_distance_km":.1,"surface_water_recognized":true}
	for id in ["alpha","beta"]:
		WorldSimulation.create_actor(id,777,Vector2.ZERO)
		WorldSimulation.actors[id].systems.CivilizationSystem.scout_land_authority=func(_point:Vector2)->bool:return true
		WorldSimulation.actors[id].controller="manual"

func after_test()->void:
	WorldSimulation.clear()
	WorldSimulation.context_provider=Callable()

func test_owned_days_do_not_mutate_human_state()->void:
	var initial:=SaveSystem._capture_reflected(GameState,[])
	WorldSimulation.scoped("alpha",func()->void:
		for day in range(1,31):DAY.advance(day,DAY.context(Vector2.ZERO))
	)
	assert_dict(SaveSystem._capture_reflected(GameState,[])).is_equal(initial)
	assert_int(int(WorldSimulation.actors.beta.systems.GameState.elapsed_days)).is_equal(0)

func test_same_orders_and_daily_inputs_produce_identical_owned_state()->void:
	for id in ["alpha","beta"]:
		WorldSimulation.submit(id,{"kind":"ambition","id":"makers"})
		assert_bool(WorldSimulation.submit(id,{"kind":"found"}).get("ok",false)).is_true()
		WorldSimulation.submit(id,{"kind":"production","item":"improvised","target":8})
		WorldSimulation.submit(id,{"kind":"recruit","count":8})
		WorldSimulation.submit(id,{"kind":"train","unit":"levy","weapon":"improvised","count":8})
		WorldSimulation.scoped(id,func()->void:
			for day in range(1,91):DAY.advance(day,DAY.context(Vector2.ZERO))
		)
	var first:=WorldSimulation.capture_actor("alpha")
	var second:=WorldSimulation.capture_actor("beta")
	for name in ["GameState","MilitaryCampaign","DiscoverySystem","GovernmentPeopleSystem","EconomySystem","ProgressionSystem","society_model"]:
		assert_bool(first[name]==second[name]).override_failure_message("Different owned state in "+name).is_true()

func test_save_continuation_preserves_rng_and_owned_balances()->void:
	WorldSimulation.scoped("alpha",func()->void:
		for day in range(1,16):DAY.advance(day,DAY.context(Vector2.ZERO))
	)
	var saved:=WorldSimulation.export_state()
	WorldSimulation.scoped("alpha",func()->void:
		for day in range(16,31):DAY.advance(day,DAY.context(Vector2.ZERO))
	)
	var expected:=WorldSimulation.capture_actor("alpha")
	assert_bool(WorldSimulation.import_state(bytes_to_var(var_to_bytes(saved))).get("ok",false)).is_true()
	WorldSimulation.scoped("alpha",func()->void:
		for day in range(16,31):DAY.advance(day,DAY.context(Vector2.ZERO))
	)
	var actual:=WorldSimulation.capture_actor("alpha")
	for name in ["GameState","MilitaryCampaign","DiscoverySystem","EconomySystem","society_model"]:
		assert_bool(_equivalent(actual[name],expected[name])).override_failure_message("Save continuation diverged in "+name).is_true()

func test_invalid_owned_save_is_rejected_before_mutating_actors()->void:
	var saved:=WorldSimulation.export_state()
	saved.actors.alpha.state.GameState.population_exact=-1
	assert_bool(WorldSimulation.import_state(saved).has("error")).is_true()
	assert_float(WorldSimulation.actors.alpha.systems.GameState.population_exact).is_equal(120.0)

func _equivalent(a:Variant,b:Variant)->bool:
	if a is float and b is float:return absf(a-b)<=1e-9*maxf(1,absf(a))
	if a is Dictionary and b is Dictionary:
		if a.size()!=b.size():return false
		for key in a:
			if not b.has(key) or not _equivalent(a[key],b[key]):
				print("DIFFERENT SAVE FIELD ",key," ",str(a[key]).left(100)," / ",str(b.get(key)).left(100))
				return false
		return true
	if a is Array and b is Array:
		if a.size()!=b.size():return false
		for i in a.size():
			if not _equivalent(a[i],b[i]):return false
		return true
	return a==b

func test_new_world_uses_paid_founding_and_real_city_register()->void:
	WorldSimulation.clear()
	GameState.reset_for_new_world(9241)
	# Match the normal new-world entry point: the complete save also captures
	# player military state, including any previous test's sample bases.
	MilitaryCampaign.reset_for_new_world()
	CivilizationSystem.reset_for_new_world()
	# A two-seat fixture uses the normal creation and controller path.
	CivilizationSystem.civilizations.assign(CivilizationSystem.civilizations.slice(0,2))
	CivilizationSystem.scout_land_authority=func(_at:Vector2)->bool:return true
	WorldSimulation.start_world()
	for actor in WorldSimulation.actors.values():
		assert_float(actor.systems.GameState.population_exact).is_equal(120.0)
		assert_array(actor.systems.GameState.player_settlements).is_empty()
		assert_dict(actor.systems.GameState.settlement_projects).is_empty()
	assert_array(CivilizationSystem.city_intelligence.sites(false)).is_empty()
	WorldSimulation.advance_rivals(60)
	for actor in WorldSimulation.actors.values():
		assert_array(actor.systems.GameState.settlement_completed).contains("Hearth Circle")
		assert_int(actor.systems.GameState.player_settlements.size()).is_equal(1)
		assert_bool(actor.systems.GameState.known_discoveries.has("service_rifle")).is_false()
	assert_int(CivilizationSystem.city_intelligence.sites(false).size()).is_equal(2)

func test_trade_debits_both_real_stores_and_cannot_invent_imports()->void:
	WorldSimulation.enabled=true
	for id:String in ["alpha","beta"]:
		WorldSimulation.scoped(id,func()->void:
			WorldSimulation.state.elapsed_days=1
			WorldSimulation.state.economy_stage=WorldSimulation.economy.STAGE_METAL
			WorldSimulation.state.economy_known_goods={"Stone":true,"Timber":true}
			WorldSimulation.state.resource_stockpiles.Stone=1000.0 if id=="alpha" else 0.0
			WorldSimulation.state.resource_stockpiles.Timber=1000.0 if id=="beta" else 0.0
			WorldSimulation.world.civilizations.assign([{"id":"beta" if id=="alpha" else "alpha","player_relation":{"treaty":"trade","at_war":false}}])
			WorldSimulation.economy._process_external_trade(1.0,100.0)
		)
	preload("res://scripts/civilization_exchange.gd").settle(1)
	var a:Dictionary=WorldSimulation.actors.alpha.systems.GameState.resource_stockpiles
	var b:Dictionary=WorldSimulation.actors.beta.systems.GameState.resource_stockpiles
	assert_float(float(a.Stone+b.Stone)).is_equal_approx(1000,.000001)
	assert_float(float(a.Timber+b.Timber)).is_equal_approx(1000,.000001)
	assert_float(float(a.Timber)).is_greater(0)
	assert_float(float(b.Stone)).is_greater(0)
	assert_float(WorldSimulation.actors.alpha.systems.GameState.external_trade_credit).is_equal(0.0)

func test_treaties_and_war_propagate_both_ways_without_sharing_private_intel()->void:
	WorldSimulation.actors.alpha.systems.CivilizationSystem.civilizations.assign([{"id":"beta","player_relation":{"at_war":false,"treaty":"none","contact_intelligence":.9}}])
	WorldSimulation.actors.beta.systems.CivilizationSystem.civilizations.assign([{"id":"alpha","player_relation":{"at_war":false,"treaty":"none","contact_intelligence":.1}}])
	preload("res://scripts/civilization_relations.gd").synchronize()
	WorldSimulation.actors.alpha.systems.CivilizationSystem.civilizations[0].player_relation.merge({"at_war":true,"treaty":"war"},true)
	preload("res://scripts/civilization_relations.gd").synchronize()
	var relation:Dictionary=WorldSimulation.actors.beta.systems.CivilizationSystem.civilizations[0].player_relation
	assert_bool(relation.at_war).is_true()
	assert_str(relation.treaty).is_equal("war")
	assert_float(float(relation.contact_intelligence)).is_equal(.1)

func test_two_owners_cannot_extract_the_same_finite_deposit_twice()->void:
	WorldSimulation.enabled=true
	WorldSimulation.geography_stock["shared"]={"remaining":10.0,"initial_amount":10.0}
	var deposit:={"world_key":"shared","remaining":10.0}
	var other:=deposit.duplicate(true)
	var first:=preload("res://scripts/civilization_resources.gd").withdraw(deposit,8)
	var second:=preload("res://scripts/civilization_resources.gd").withdraw(other,8)
	assert_float(first+second).is_equal(10.0)
	assert_float(float(WorldSimulation.geography_stock.shared.remaining)).is_equal(0.0)

func test_nested_invalid_military_save_rolls_back_every_owned_system()->void:
	var saved:=WorldSimulation.export_state()
	var expected:=WorldSimulation.capture_actor("alpha")
	saved.actors.alpha.state.MilitaryCampaign.aggregate_recruits=-10
	assert_bool(WorldSimulation.import_state(saved).has("error")).is_true()
	assert_bool(WorldSimulation.capture_actor("alpha")==expected).is_true()

func test_foreign_city_damage_changes_actual_buildings_not_only_reports()->void:
	WorldSimulation.scoped("beta",func()->void:
		WorldSimulation.state.settlement_completed=["Hearth Circle"]
		WorldSimulation.settlements.ensure_founded()
		WorldSimulation.state.settlement_plots=[{"id":1,"land_use":"workshop","condition":1.0}]
	)
	var city:=String(WorldSimulation.actors.beta.systems.GameState.player_settlements[0].id)
	WorldSimulation.scoped("alpha",func()->void:
		WorldSimulation.world.civilizations.assign([{"id":"beta","strategic_regions":[{"id":"enemy_city","local_city_id":city}]}])
		preload("res://scripts/civilization_combat.gd").damage_city("beta","enemy_city",.1)
	)
	assert_float(float(WorldSimulation.actors.beta.systems.GameState.settlement_plots[0].condition)).is_equal_approx(.9,.000001)

func test_shared_woodland_recovery_is_not_multiplied_by_observer_count()->void:
	WorldSimulation.enabled=true
	var field:={"position":Vector3.ZERO,"density":.5,"area_km2":9.0}
	var first:Dictionary=WorldSimulation.scoped("alpha",func()->Dictionary:return preload("res://scripts/civilization_resources.gd").surface("Timber","woodland_catchment",field,600))
	var second:Dictionary=WorldSimulation.scoped("beta",func()->Dictionary:return preload("res://scripts/civilization_resources.gd").surface("Timber","woodland_catchment",field,600))
	assert_str(String(first.world_key)).is_equal(String(second.world_key))
	preload("res://scripts/civilization_resources.gd").withdraw(first,100)
	var remaining:=float(WorldSimulation.geography_stock[first.world_key].remaining)
	for id in ["alpha","beta"]:
		WorldSimulation.scoped(id,func()->void:
			WorldSimulation.state.elapsed_days=1
			preload("res://scripts/civilization_resources.gd").available(first if id=="alpha" else second)
		)
	assert_float(float(WorldSimulation.geography_stock[first.world_key].remaining)).is_equal_approx(remaining+float(first.initial_amount)*.00003,.000001)

func test_siege_is_visible_to_defender_and_blocks_only_that_city()->void:
	WorldSimulation.enabled=true
	WorldSimulation.scoped("beta",func()->void:
		WorldSimulation.state.settlement_completed=["Hearth Circle"]
		WorldSimulation.settlements.ensure_founded()
	)
	var city_id:=String(WorldSimulation.actors.beta.systems.GameState.player_settlements[0].id)
	WorldSimulation.scoped("alpha",func()->void:
		WorldSimulation.military.active_siege={"id":"paired","active":true,"mode":"offensive","attacker_id":"player","defender_id":"beta","start_day":0,"last_day":0,"days":0,"target_position":{"x":0,"z":0},"region_id":"beta_city","army_id":7,"threat":{"owned_target":{"actor":"beta","field_id":0,"city_id":city_id},"target_region_name":"Beta"},"pressure":.2,"fatigue":0.0,"blockade":.5,"hardship":0.0,"starving_days":0,"relief":[]}
		preload("res://scripts/civilization_siege.gd").publish()
	)
	WorldSimulation.scoped("beta",func()->void:
		assert_str(String(WorldSimulation.military.siege_public_snapshot().mode)).is_equal("defensive")
		assert_float(WorldSimulation.military.siege_home_food_access()).is_equal_approx(.6,.000001)
		WorldSimulation.state.resource_settlement_id="other_city"
		assert_float(WorldSimulation.military.siege_home_food_access()).is_equal(1.0)
		WorldSimulation.state.resource_settlement_id=""
		WorldSimulation.military._end_siege("Ceasefire",false,false)
	)
	assert_dict(WorldSimulation.actors.alpha.systems.MilitaryCampaign.active_siege).is_empty()
	assert_dict(WorldSimulation.actors.beta.systems.MilitaryCampaign.active_siege).is_empty()

func test_foreign_command_battle_reserves_actual_defender()->void:
	WorldSimulation.enabled=true
	WorldSimulation.actors.alpha.systems.MilitaryCampaign.command_hierarchy.data.battles=[{"home_force_id":3,"threat":{"owned_target":{"actor":"beta","field_id":8,"city_id":""}}}]
	WorldSimulation.scoped("beta",func()->void:
		assert_bool(WorldSimulation.military.command_hierarchy.battle.engaged(8)).is_true()
		assert_bool(WorldSimulation.military.command_hierarchy.battle.engaged(9)).is_false()
	)

func test_new_world_default_and_complete_save_restore_owned_cities()->void:
	WorldSimulation.clear()
	GameState.opponent_count=12
	GameState.reset_for_new_world(9241)
	CivilizationSystem.reset_for_new_world()
	CivilizationSystem.scout_land_authority=func(_at:Vector2)->bool:return true
	WorldSimulation.start_world()
	assert_int(WorldSimulation.actors.size()).is_equal(12)
	WorldSimulation.advance_rivals(35)
	GameState.elapsed_days=35
	var first_id:=String(WorldSimulation.actors.keys()[0])
	var expected:=WorldSimulation.capture_actor(first_id)
	var saved:=SaveSystem.save_game("owned_parity_test")
	assert_bool(saved.get("ok",false)).is_true()
	var loaded:=SaveSystem.load_game("owned_parity_test")
	assert_bool(loaded.get("ok",false)).override_failure_message(str(loaded)).is_true()
	assert_int(WorldSimulation.actors.size()).is_equal(12)
	assert_bool(_equivalent(WorldSimulation.capture_actor(first_id),expected)).is_true()
	DirAccess.remove_absolute(SaveSystem.slot_path("owned_parity_test"))

func test_battle_losses_reach_both_actual_populations_and_formations()->void:
	WorldSimulation.enabled=true
	for id in ["alpha","beta"]:
		WorldSimulation.scoped(id,func()->void:
			WorldSimulation.state.ensure_population_total(1000)
			WorldSimulation.military.home_army=WorldSimulation.military.simulator.create_formation_force(id,[{"id":1,"unit":"levy","weapon":"improvised","count":100,"equipment":100,"equipment_required":100}],.8,.8)
		)
	var result:Dictionary=WorldSimulation.actors.alpha.systems.MilitaryCampaign.simulator.simulate(WorldSimulation.actors.alpha.systems.MilitaryCampaign.home_army,WorldSimulation.actors.beta.systems.MilitaryCampaign.home_army,{"seed":77,"max_rounds":4})
	result.merge({"home_side":"attacker","home_force_kind":"field","home_force_id":0,"seed":77,"commander_managed":true,"threat":{"owned_target":{"actor":"beta","field_id":0,"city_id":""}}},true)
	WorldSimulation.scoped("alpha",func()->void:
		WorldSimulation.military._commit_campaign_battle(result)
		preload("res://scripts/civilization_combat.gd").commit_enemy(result)
	)
	for pair in [["alpha","attacker"],["beta","defender"]]:
		var killed:=0
		for round_data:Dictionary in result.rounds:killed+=int(round_data.get(pair[1]+"_casualties",{}).get("killed",0))
		assert_int(killed).is_greater(0)
		var actor:Dictionary=WorldSimulation.actors[pair[0]]
		assert_int(actor.systems.GameState.population_total).is_equal(1000-killed)
		assert_int(int(actor.systems.MilitaryCampaign.home_army.troops)).is_equal(int(result[pair[1]].remaining_troops))

func test_human_and_owned_civilization_use_identical_daily_economy_and_demography()->void:
	WorldSimulation.clear()
	GameState.reset_for_new_world(777)
	for name in WorldSimulation.OWNED_SYSTEMS:
		if name=="GameState":continue
		var instance:=WorldSimulation.system(name)
		if instance.has_method("reset_for_new_world"):instance.reset_for_new_world()
	GameState.initialize_population_model()
	ResourceSystem.initialize();FoodSystem.initialize();ConsequenceEngine.initialize();EconomySystem.initialize();DiscoverySystem.initialize()
	WorldSimulation.create_actor("alpha",777,Vector2.ZERO)
	CivilizationSystem.player_world_origin=Vector2.ZERO
	# The actor factory seeds founding map knowledge; give the human fixture
	# the same evidence so seed trials and surface recognition receive equal inputs.
	CivilizationSystem._add_revealed_area(Vector2.ZERO,72.0,"founding knowledge")
	WorldSimulation.enabled=true
	for id in ["player","alpha"]:
		WorldSimulation.scoped(id,func()->void:
			WorldSimulation.state.settlement_name="Parity"
			WorldSimulation.world.scout_land_authority=func(_point:Vector2)->bool:return true
			# Compare equal orders: the human steward otherwise schedules extra jobs,
			# while this owned actor deliberately has no AI controller review.
			WorldSimulation.military.workshop.set_enabled(false)
		)
		WorldSimulation.submit(id,{"kind":"ambition","id":"makers"})
		WorldSimulation.submit(id,{"kind":"found"})
	for day in range(1,31):
		for id in ["player","alpha"]:
			WorldSimulation.scoped(id,func()->void:DAY.advance(day,DAY.context(Vector2.ZERO)))
	var other:Node=WorldSimulation.actors.alpha.systems.GameState
	for field in ["population_exact","population_cohorts","food_stocks","resource_stockpiles","settlement_completed","known_discoveries","discovery_adoption","population_allocation_percentages"]:
		assert_bool(_equivalent(GameState.get(field),other.get(field))).override_failure_message("Human / owned divergence in "+field).is_true()

func test_allied_relief_reserves_actual_trained_units_gear_and_food()->void:
	WorldSimulation.enabled=true
	WorldSimulation.scoped("beta",func()->void:
		WorldSimulation.state.ensure_population_total(1000)
		WorldSimulation.food.receive_external_food(100000)
		WorldSimulation.military.home_army=WorldSimulation.military.simulator.create_formation_force("Donor",[{"id":1,"unit":"levy","weapon":"improvised","count":50,"equipment":50,"equipment_required":50}],.8,.8)
	)
	var before:float=WorldSimulation.scoped("beta",func()->float:return WorldSimulation.food.total_stored())
	var quote:=preload("res://scripts/civilization_relief.gd").quote("beta",{"x":50.0,"z":0.0})
	assert_bool(quote.get("ok",false)).override_failure_message(str(quote)).is_true()
	var receipt:=preload("res://scripts/civilization_relief.gd").reserve("beta",quote)
	assert_bool(receipt.has("owned_army")).is_true()
	WorldSimulation.scoped("beta",func()->void:
		assert_int(WorldSimulation.military._mobilized_count()).is_equal(50)
		assert_int(int(WorldSimulation.military.home_army.troops)).is_equal(50-int(quote.troops))
		assert_float(WorldSimulation.food.total_stored()).is_equal_approx(before-float(quote.food),.00001)
		assert_bool(WorldSimulation.military.command_hierarchy.battle.engaged(int(receipt.owned_army))).is_true()
	)
	receipt.unused_food=quote.camp_food
	preload("res://scripts/civilization_relief.gd").restore(receipt)
	WorldSimulation.scoped("beta",func()->void:
		assert_int(WorldSimulation.military._mobilized_count()).is_equal(50)
		assert_bool(WorldSimulation.military.command_hierarchy.battle.engaged(int(receipt.owned_army))).is_false()
		assert_float(WorldSimulation.food.total_stored()).is_equal_approx(before-float(quote.food)+float(quote.camp_food),.00001)
	)

func test_air_contacts_with_matching_local_ids_damage_the_correct_owners()->void:
	WorldSimulation.enabled=true
	for id:String in ["alpha","beta"]:
		WorldSimulation.scoped(id,func()->void:
			WorldSimulation.state.ensure_population_total(4000)
			WorldSimulation.state.settlement_completed=["Hearth Circle"]
			WorldSimulation.settlements.ensure_founded()
			for discovery in ["aerostat_observation","fighter_tactics"]:
				WorldSimulation.state.known_discoveries.append(discovery);WorldSimulation.state.discovery_adoption[discovery]=1.0
			for item in ["Timber","Stone","Iron Ore"]:WorldSimulation.state.resource_stockpiles[item]=10000.0
			WorldSimulation.world.civilizations.assign([{"id":"beta" if id=="alpha" else "alpha","player_relation":{"at_war":true}}])
			var op=WorldSimulation.military.joint_operations
			assert_bool(op.build_base(String(WorldSimulation.state.player_settlements[0].id),"air").has("ok")).is_true()
			op.state.bases[0].construction_work=30.0
			WorldSimulation.military.military_inventory.fighter_equipment=20
			var commissioned:Dictionary=op.commission(int(op.state.bases[0].id),"fighter",20)
			assert_bool(commissioned.get("ok",false)).override_failure_message(str(commissioned)).is_true()
			var force:Dictionary=op.force(int(commissioned.id))
			force.training=1.0;force.efficiency=1.0;force.mission="air_superiority";force.auto_replace=false
			var created:Dictionary=op.create_region("air",op.R.rectangle(Vector2.ZERO,10),"Contested airspace")
			force.region=created.region
		)
	for day in range(1,61):preload("res://scripts/civilization_joint_contact.gd").advance(day)
	for id in ["alpha","beta"]:
		WorldSimulation.scoped(id,func()->void:
			var op=WorldSimulation.military.joint_operations
			var remaining:=int(op.state.forces[0].units.fighter)
			assert_int(remaining).is_less(20)
			assert_int(WorldSimulation.state.population_total).is_equal(4000-(20-remaining)*int(op.C.UNITS.fighter.crew))
			assert_bool(op.state.contacts.has(("beta" if id=="alpha" else "alpha")+":"+str(op.state.forces[0].id))).is_true()
		)

func test_occupation_changes_real_city_and_detaches_real_holding_troops()->void:
	WorldSimulation.enabled=true
	var city:Dictionary={}
	WorldSimulation.scoped("beta",func()->void:
		WorldSimulation.state.settlement_completed=["Hearth Circle"]
		WorldSimulation.settlements.ensure_founded()
	)
	var civ:=CivilizationSystem.civilizations[0].duplicate(true)
	civ.id="beta"
	WorldSimulation.scoped("beta",func()->void:WorldSimulation.project(civ))
	var region:Dictionary=civ.strategic_regions[4]
	WorldSimulation.scoped("alpha",func()->void:
		WorldSimulation.world.civilizations.assign([civ])
		var host:=WorldSimulation.military
		host.home_army=host.simulator.create_formation_force("Alpha",[{"id":1,"unit":"levy","weapon":"improvised","count":50,"equipment":50,"equipment_required":50}],.9,.9)
		var captured:=preload("res://scripts/civilization_combat.gd").capture(civ,String(region.id),host.home_army)
		assert_bool(captured.outcome.get("region_captured",false)).override_failure_message(str(captured)).is_true()
		assert_float(float(captured.outcome.occupation_required)).is_greater(0)
		var held:=host.establish_occupation_force("beta",captured.outcome.region,float(captured.outcome.occupation_required),0)
		assert_bool(held.has("error")).is_false()
		assert_int(host._mobilized_count()).is_equal(50)
		assert_int(int(host.occupation_forces[0].troops)).is_greater(0)
	)
	WorldSimulation.scoped("beta",func()->void:
		assert_str(String(WorldSimulation.state.player_settlements[0].occupied_by)).is_equal("alpha")
		assert_int(WorldSimulation.state.population_total).is_equal(120)
		assert_bool(WorldSimulation.military.recovery.home_unavailable()).is_true()
	)
