extends GdUnitTestSuite
const H=preload("res://scripts/home_army_reinforcement.gd")
const D=preload("res://scripts/combined_arms_doctrine.gd")
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("attachment",119)
func after_test()->void:WorldSimulation.clear()
func setup()->int:
	var host=WorldSimulation.military;var state=WorldSimulation.state
	state.ensure_population_total(1000);state.settlement_site_committed=true;state.convoy_traveling=false
	state.population_health=1.0;state.food_security=1.0
	state.known_discoveries.append("skirmisher_infantry_screens");state.discovery_adoption.skirmisher_infantry_screens=1.0
	host.home_army=host.simulator.create_formation_force("Home",[{"id":1,"unit":"spearman","weapon":"spear","count":60,"equipment":60,"training":1.0}])
	var formed:Dictionary=host.create_field_army(60);assert_bool(formed.get("ok",false)).is_true()
	host._rebuild_home_army_with([{"id":2,"unit":"skirmisher","weapon":"bow","count":50,"equipment":50,"ammunition":100,"training":1.0,"doctrines":{"skirmisher_infantry_screens":.4}},{"id":3,"unit":"levy","weapon":"improvised","count":20,"equipment":20,"training":1.0}])
	host.next_formation_id=4;host.home_army.exercise_readiness_bonus=0.0;host.home_army.wounded_pool=3;host.field_armies[0].wounded_pool=2
	return int(formed.army.army_id)
func totals()->Dictionary:
	var result:={"people":WorldSimulation.military._mobilized_count(),"equipment":0,"ammunition":0}
	for force:Dictionary in [WorldSimulation.military.home_army]+WorldSimulation.military.field_armies:
		for formation:Dictionary in force.formations:
			result.equipment+=int(formation.get("equipment",0));result.ammunition+=int(formation.get("ammunition",0))
	return result
func test_normal_order_moves_only_requested_support_and_preserves_issued_stocks()->void:
	WorldSimulation.scoped("attachment",func()->void:
		var id:=setup();var host=WorldSimulation.military;var before:=totals()
		var commander:Dictionary=host.field_armies[0].commander.duplicate(true)
		var order:=H.recommendation(host);assert_int(int(order.count)).is_equal(30)
		assert_bool(WorldSimulation.submit("attachment",order).get("ok",false)).is_true()
		assert_dict(totals()).is_equal(before);assert_int(int(host.field_armies[0].troops)).is_equal(90);assert_int(int(host.home_army.troops)).is_equal(40)
		assert_dict(host.field_armies[0].commander).is_equal(commander)
		assert_int(int(host.home_army.wounded_pool)).is_equal(3);assert_int(int(host.field_armies[0].wounded_pool)).is_equal(2)
		var ids:Array=[]
		for formation:Dictionary in host.field_armies[0].formations:
			assert_bool(formation.id in ids).is_false();ids.append(formation.id)
			if formation.unit=="skirmisher":assert_float(float(formation.doctrines.skirmisher_infantry_screens)).is_equal(.4)
		assert_dict(H.recommendation(host)).is_empty();assert_int(int(host.field_armies[0].army_id)).is_equal(id)
	)
func test_distant_moving_embarked_and_battle_committed_armies_cannot_teleport_support()->void:
	WorldSimulation.scoped("attachment",func()->void:
		var id:=setup();var host=WorldSimulation.military;var before:=totals()
		for condition:Dictionary in [{"location_id":"distant_city"},{"position":{"x":100000.0,"z":100000.0}},{"status":"moving"},{"embarked":true}]:
			var original:Dictionary=host.field_armies[0].duplicate(true)
			host.field_armies[0].merge(condition,true)
			assert_bool(H.transfer(host,id,"skirmisher",10).has("error")).is_true()
			assert_dict(totals()).is_equal(before);host.field_armies[0]=original
		host.pending_aftermath={"pending":true};assert_bool(H.transfer(host,id,"skirmisher",10).has("error")).is_true()
		assert_dict(totals()).is_equal(before)
	)
func test_invalid_count_or_unit_has_no_partial_transfer()->void:
	WorldSimulation.scoped("attachment",func()->void:
		var id:=setup();var host=WorldSimulation.military;var before:=totals()
		for count in [-1,0,51]:assert_bool(H.transfer(host,id,"skirmisher",count).has("error")).is_true()
		assert_bool(H.transfer(host,id,"unknown",1).has("error")).is_true()
		assert_dict(totals()).is_equal(before)
	)
func test_attached_formations_can_rehearse_and_protect_the_field_army()->void:
	WorldSimulation.scoped("attachment",func()->void:
		var id:=setup();var host=WorldSimulation.military
		assert_bool(H.transfer(host,id,"skirmisher",30).get("ok",false)).is_true()
		var army:Dictionary=host.field_armies[0]
		var threat:Dictionary=host.simulator.create_formation_force("Mounted threat",[{"unit":"cavalry","weapon":"lance","count":100,"equipment":100,"training":1.0}])
		assert_float(float(host.simulator.evaluate_force(army,threat)[0].doctrine_defense)).is_equal(1.0)
		for day in range(40):D.practice(army.formations,D.levels(),1.0)
		assert_float(float(host.simulator.evaluate_force(army,threat)[0].doctrine_defense)).is_greater(1.0)
	)

func test_owned_save_round_trip_preserves_reinforced_formations()->void:
	var expected:Dictionary={}
	WorldSimulation.scoped("attachment",func()->void:
		var id:=setup();var host=WorldSimulation.military
		assert_bool(H.transfer(host,id,"skirmisher",30).get("ok",false)).is_true()
		expected["home"]=host.home_army.duplicate(true);expected["field"]=host.field_armies.duplicate(true);expected["totals"]=totals()
	)
	var saved:Dictionary=WorldSimulation.export_state()
	assert_bool(WorldSimulation.import_state(bytes_to_var(var_to_bytes(saved))).get("ok",false)).is_true()
	WorldSimulation.scoped("attachment",func()->void:
		assert_dict(WorldSimulation.military.home_army).is_equal(expected.home)
		assert_array(WorldSimulation.military.field_armies).is_equal(expected.field)
		assert_dict(totals()).is_equal(expected.totals)
	)

func test_monthly_controller_attaches_the_available_supporting_contingent()->void:
	WorldSimulation.scoped("attachment",func()->void:
		setup();var host=WorldSimulation.military;var before:=totals()
		var plan:=preload("res://scripts/civilization_strategy.gd").preferences({}, {"food_days":120,"food_intake_ratio":1.0,"at_war":false})
		plan.capacity_share=0.0;plan.recruit_share=0.0
		preload("res://scripts/civilization_controller.gd").military_orders("attachment",plan)
		assert_dict(totals()).is_equal(before)
		assert_int(int(host.field_armies[0].troops)).is_equal(90)
		assert_int(int(host.home_army.troops)).is_equal(40)
	)

func test_basic_archers_can_join_spears_before_screen_doctrine_is_learned()->void:
	WorldSimulation.scoped("attachment",func()->void:
		setup();var state=WorldSimulation.state;var host=WorldSimulation.military
		state.known_discoveries.erase("skirmisher_infantry_screens");state.discovery_adoption.erase("skirmisher_infantry_screens")
		var before:=totals()
		var order:=H.recommendation(host)
		assert_str(String(order.unit)).is_equal("skirmisher")
		assert_bool(H.transfer(host,int(order.army),String(order.unit),int(order.count)).get("ok",false)).is_true()
		assert_dict(totals()).is_equal(before)
		assert_dict(D.levels()).is_empty()
	)
