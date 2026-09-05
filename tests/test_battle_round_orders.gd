extends "res://tests/test_surprise_hostilities.gd"
func test_explicit_hold_preserves_original_round()->void:
	var fixture:=_peace_fixture()
	MilitaryCampaign.field_armies[0].position=CivilizationSystem.city_intelligence.known("player",fixture.region).position.duplicate(true)
	MilitaryCampaign.order_city_operation(fixture.army,fixture.civ,fixture.region)
	var state:Dictionary=MilitaryCampaign.export_state().duplicate(true)
	MilitaryCampaign.advance_engagement("hold")
	var baseline:Dictionary=(MilitaryCampaign.active_engagement if not MilitaryCampaign.active_engagement.is_empty() else MilitaryCampaign.battle_history.front()).duplicate(true)
	assert_dict(baseline).is_not_empty()
	assert_bool(MilitaryCampaign.import_state(state).has("ok")).is_true()
	var side:=MilitaryCampaign._engagement_home_side(MilitaryCampaign.active_engagement)
	for i in MilitaryCampaign.active_engagement[side].formations.size():MilitaryCampaign.set_battle_formation_order(i,"hold")
	MilitaryCampaign.advance_engagement("hold")
	var actual:Dictionary=(MilitaryCampaign.active_engagement if not MilitaryCampaign.active_engagement.is_empty() else MilitaryCampaign.battle_history.front()).duplicate(true)
	assert_dict(actual.get("attacker",{})).is_equal(baseline.get("attacker",{}))
	assert_dict(actual.get("defender",{})).is_equal(baseline.get("defender",{}))
	if not actual.is_empty():
		var a:Dictionary=actual.rounds.back().duplicate(true);var b:Dictionary=baseline.rounds.back().duplicate(true)
		a.erase("formation_orders");b.erase("formation_orders");assert_dict(a).is_equal(b)
func test_orders_validate_targets_and_survive_save()->void:
	var fixture:=_peace_fixture()
	MilitaryCampaign.field_armies[0].position=CivilizationSystem.city_intelligence.known("player",fixture.region).position.duplicate(true)
	MilitaryCampaign.order_city_operation(fixture.army,fixture.civ,fixture.region)
	assert_bool(MilitaryCampaign.set_battle_formation_order(-1,"charge",0).has("error")).is_true()
	assert_bool(MilitaryCampaign.set_battle_formation_order(0,"charge",-1).has("error")).is_true()
	assert_bool(MilitaryCampaign.set_battle_formation_order(0,"charge",0).get("ok",false)).is_true()
	var saved:Dictionary=MilitaryCampaign.export_state().duplicate(true)
	assert_bool(MilitaryCampaign.import_state(saved).has("ok")).is_true()
	assert_str(MilitaryCampaign.active_engagement.formation_orders["0"].kind).is_equal("charge")
	MilitaryCampaign.advance_engagement("hold")
	var resolved:Dictionary=MilitaryCampaign.active_engagement if not MilitaryCampaign.active_engagement.is_empty() else MilitaryCampaign.battle_history.front()
	assert_dict(resolved).is_not_empty()
	if not resolved.is_empty():
		for side in ["attacker","defender"]:
			for formation in resolved[side].formations:
				assert_bool(formation.has("round_order_attack")).is_false()
				assert_bool(formation.has("round_order_exposure")).is_false()
func test_targeted_losses_are_deterministic_and_conserved()->void:
	var sim:=CombatSimulator.new()
	var a:=sim.create_formation_force("Attack",[{"unit":"levy","weapon":"improvised","count":500}],1,1)
	var d:=sim.create_formation_force("Defend",[{"unit":"levy","weapon":"improvised","count":500},{"unit":"levy","weapon":"improvised","count":500}],1,1)
	var cohorts:=sim.evaluate_force(d,a)
	var rng:=RandomNumberGenerator.new();rng.seed=192
	var baseline:Dictionary=sim._apply_cohort_losses(d.formations,cohorts,100,rng)
	rng.seed=192
	var targeted:Dictionary=sim._apply_cohort_losses(d.formations,cohorts,100,rng,-1,{"1":1.0})
	rng.seed=192
	assert_dict(sim._apply_cohort_losses(d.formations,cohorts,100,rng,-1,{"1":1.0})).is_equal(targeted)
	assert_int(int(targeted.losses[1])).is_greater(int(baseline.losses[1]))
	assert_int(int(targeted.losses[0])+int(targeted.losses[1])).is_equal(100)
	assert_int(int(targeted.formations[0].count)+int(targeted.formations[1].count)).is_equal(900)
