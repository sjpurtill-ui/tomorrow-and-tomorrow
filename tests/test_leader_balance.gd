extends GdUnitTestSuite
## Every automated leader plays by the same rules; only its temper moves its
## preferences. A computer ruler's temper is its personality; the player's own
## leaders take the people's tendency, the values they live by
## (leader_personality.gd from_values, as the delegated research does).

const Personality:=preload("res://scripts/leader_personality.gd")
const Strategy:=preload("res://scripts/civilization_strategy.gd")
const Controller:=preload("res://scripts/civilization_controller.gd")
const AutoFounding:=preload("res://scripts/auto_founding.gd")
const Culture:=preload("res://scripts/cultural_inheritance.gd")
const Orders:=preload("res://scripts/civilization_orders.gd")
const Fixture:=preload("res://tests/diplomacy_fixture.gd")
const Bold:={"openness":.6,"discipline":.3,"empathy":.4,"assertiveness":.7,"risk_tolerance":.9}
const Cautious:={"openness":.45,"discipline":.5,"empathy":.85,"assertiveness":.2,"risk_tolerance":.15}
const Martial:={"openness":.35,"discipline":.9,"empathy":.15,"assertiveness":.95,"risk_tolerance":.9}
const Even:={"openness":.5,"discipline":.5,"empathy":.5,"assertiveness":.5,"risk_tolerance":.5}

func after_test()->void:
	WorldSimulation.clear()
	PeopleDirection.reset_for_new_world()

## Every ambition a people can take up is open to a computer ruler, and across
## rulers drawn as the game draws them none crowds out the others.
func test_every_ambition_is_open_to_rulers_and_none_dominates()->void:
	var rng:=RandomNumberGenerator.new();rng.seed=20260929
	var counts:Dictionary={}
	var rulers:=3000
	for i in rulers:
		var plan:=Strategy.preferences(Personality.generate(rng),{"food_days":120,"peoples_known":2})
		counts[plan.ambition]=int(counts.get(plan.ambition,0))+1
	for ambition:String in PeopleDirection.AMBITIONS:
		var share:=float(counts.get(ambition,0))/rulers
		assert_float(share).override_failure_message("%s taken up by %.3f of rulers" % [ambition,share]).is_greater(.02)
		assert_float(share).override_failure_message("%s taken up by %.3f of rulers" % [ambition,share]).is_less(.14)
	assert_int(counts.size()).is_equal(PeopleDirection.AMBITIONS.size())

## Arms, rule over others, vengeance and trade wait until another people is known.
func test_ambitions_needing_others_wait_until_another_people_is_known()->void:
	var alone:=Strategy.preferences(Martial,{"food_days":120,"peoples_known":0})
	var met:=Strategy.preferences(Martial,{"food_days":120,"peoples_known":1})
	assert_bool(String(alone.ambition) in Strategy.AMBITIONS_NEEDING_OTHERS).is_false()
	assert_str(String(met.ambition)).is_equal("military")
	# Callers that do not say (older tests, other systems) see no change.
	assert_str(String(Strategy.preferences(Martial,{"food_days":120}).ambition)).is_equal(String(met.ambition))

## A temper leaning toward each ambition takes it up: every ambition is reachable.
func test_every_ambition_has_tempers_that_take_it_up()->void:
	for ambition:String in PeopleDirection.AMBITIONS:
		var temper:Dictionary={}
		for axis:String in Personality.AXES:temper[axis]=clampf(.5+float((Personality.AMBITION_TEMPER[ambition] as Dictionary).get(axis,0.0))*.6,.12,.92)
		assert_str(String(Strategy.preferences(temper,{"food_days":120,"peoples_known":1}).ambition)).is_equal(ambition)

## The player's leaders have no ruler of their own: their temper is the people's
## tendency, the values they live by, the same reading their delegated research uses.
func test_the_council_takes_its_temper_from_the_values_the_people_live_by()->void:
	GameState.reset_for_new_world(515);PeopleDirection.reset_for_new_world();PeopleDirection.ensure()
	assert_dict(Personality.of_owner("player")).is_equal(Personality.from_values(GameState.societal_values))
	GameState.societal_values.lived.hierarchy=.9;GameState.societal_values.lived.experimentation=.9;GameState.societal_values.lived.ecological_restraint=.1
	var bold:=Personality.of_owner("player")
	assert_float(float(bold.assertiveness)).is_equal_approx(.9,.001)
	assert_float(float(bold.risk_tolerance)).is_equal_approx(.9,.001)
	assert_dict(Controller.current_plan("player").personality).is_equal(bold)
	# A given tendency still stands in for it (PeopleDirection's delegated research).
	assert_dict(Controller.current_plan("player",Cautious).personality).is_equal(Cautious)
	# A computer ruler keeps its own personality.
	WorldSimulation.create_actor("ruler",515)
	assert_dict(Personality.of_owner("ruler")).is_equal(Personality.foreign(515,"ruler"))

## One rule for how often a council looks for land; the temper and an
## expansionist tradition only move the interval.
func test_one_rule_for_when_leaders_look_for_land()->void:
	assert_int(Strategy.expansion_months({"risk_tolerance":.92,"assertiveness":.92})).is_equal(1)
	assert_int(Strategy.expansion_months(Bold)).is_equal(2)
	assert_int(Strategy.expansion_months(Even)).is_equal(3)
	assert_int(Strategy.expansion_months(Cautious)).is_equal(4)
	assert_int(Strategy.expansion_months({"risk_tolerance":.12,"assertiveness":.12})).is_equal(5)
	assert_int(Strategy.expansion_months(Cautious,Strategy.EXPANSIONIST_DRIVE)).is_equal(1)
	var looks:=0
	for month in 12:
		if Strategy.looks_for_land(month*30,3):looks+=1
	assert_int(looks).is_equal(4)
	# The player's leaders read the same rule through the people's tendency.
	GameState.reset_for_new_world(516);PeopleDirection.reset_for_new_world();PeopleDirection.ensure()
	assert_int(AutoFounding.look_months(0)).is_equal(Strategy.expansion_months(Personality.from_values(GameState.societal_values)))
	assert_int(int(Controller.current_plan("player").expansion_months)).is_equal(AutoFounding.look_months(0))
	Culture.record(PeopleDirection.cultural_memory,"century:0","expansion",0,10.0)
	assert_int(AutoFounding.look_months(0)).is_equal(1)
	assert_int(int(Controller.current_plan("player").expansion_months)).is_equal(1)
	# A computer ruler's search waits for its month like the council's.
	var plan:={"expansion_months":3,"hungry":false,"at_war":false,"expansion_food":0.0,"settle_distance":20.0,"personality":Even}
	GameState.settlement_completed.assign(["Hearth Circle"])
	GameState.elapsed_days=30.0
	assert_that((Controller.expansion_order_steps("player",func()->Dictionary:return plan)[0][1] as Callable).call()).is_null()
	GameState.elapsed_days=90.0
	assert_that((Controller.expansion_order_steps("player",func()->Dictionary:return plan)[0][1] as Callable).call()).is_not_null()

## Boldness settles sooner and farther and sends thinner rations; caution
## waits for full stores and provisions its settlers well.
func test_risk_trades_sooner_settling_for_thinner_rations()->void:
	var bold:=Strategy.preferences(Bold,{"food_days":120})
	var cautious:=Strategy.preferences(Cautious,{"food_days":120})
	assert_float(float(bold.expansion_food)).is_less(float(cautious.expansion_food))
	# The stores are a lean buffer: gates count FoodCare.store_gate of the old days.
	assert_float(float(bold.expansion_food)).is_greater_equal(preload("res://scripts/food_care.gd").store_gate(45.0))
	assert_float(float(bold.settle_distance)).is_greater(float(cautious.settle_distance))
	assert_float(float(bold.settle_distance)).is_less_equal(40.0)
	assert_float(float(bold.settle_margin_days)).is_less(Strategy.ESTABLISHMENT_DAYS)
	assert_float(float(cautious.settle_margin_days)).is_greater(Strategy.ESTABLISHMENT_DAYS)
	assert_float(float(Strategy.preferences(Even,{"food_days":120}).settle_margin_days)).is_equal_approx(Strategy.ESTABLISHMENT_DAYS,.001)

## Great works gates: one answer rule for a computer ruler and the player's
## council; the temper moves the lines, an even temper answers as the old
## computer rulers did, and the council is no longer always the cautious one.
func test_great_works_gates_answer_by_one_rule()->void:
	var facts:={"enabled":{"pour":true,"paid":true,"honor":true},"ample":true,"feasibility":.72,"food_days":130.0,"hierarchy":.5,"cohesion":.6,"ego":.4}
	assert_str(Strategy.works_answer("design",facts,Even)).is_equal("grander")
	assert_str(Strategy.works_answer("stores",facts,Even)).is_equal("pour")
	assert_str(Strategy.works_answer("labor",facts,Even)).is_equal("paid")
	assert_str(Strategy.works_answer("demand",facts,Even)).is_equal("honor")
	# A council whose people live by rank and bold trials answers as a bold ruler does.
	var council:=Personality.from_values({"lived":{"hierarchy":.8,"experimentation":.85,"ecological_restraint":.2}})
	var doubtful_for_even:=facts.duplicate();doubtful_for_even.feasibility=.66
	assert_str(Strategy.works_answer("design",doubtful_for_even,council)).is_equal("grander")
	assert_str(Strategy.works_answer("design",doubtful_for_even,Even)).is_equal("practical")
	# Bold tempers believe in a grander design sooner; cautious ones keep it practical.
	var doubtful:=facts.duplicate();doubtful.feasibility=.64
	assert_str(Strategy.works_answer("design",doubtful,Bold)).is_equal("grander")
	assert_str(Strategy.works_answer("design",doubtful,Cautious)).is_equal("practical")
	var lean:=facts.duplicate();lean.food_days=55.0
	assert_str(Strategy.works_answer("stores",lean,Bold)).is_equal("pour")
	assert_str(Strategy.works_answer("stores",lean,Cautious)).is_equal("protect")
	# Only a hard temper levies forced labor, and only from a people that accepts rank.
	var ranked:=facts.duplicate();ranked.hierarchy=.7;ranked.cohesion=.7
	assert_str(Strategy.works_answer("labor",ranked,Martial)).is_equal("levy")
	assert_str(Strategy.works_answer("labor",facts,Martial)).is_equal("paid")
	assert_str(Strategy.works_answer("labor",ranked,Cautious)).is_equal("volunteers")
	# Without the means, nobody pours, pays or honors.
	var poor:=facts.duplicate();poor.enabled={};poor.ample=false
	for temper:Dictionary in [Even,Bold,Cautious,Martial]:
		assert_str(Strategy.works_answer("design",poor,temper)).is_equal("practical")
		assert_str(Strategy.works_answer("stores",poor,temper)).is_equal("protect")
		assert_str(Strategy.works_answer("labor",poor,temper)).is_not_equal("paid")
		assert_str(Strategy.works_answer("demand",poor,temper)).is_equal("refuse")

## A goodwill mission carries a real gift from our own stores, or does not go.
func test_goodwill_carries_a_real_gift_or_does_not_go()->void:
	var plan:=Strategy.preferences(Cautious,{"food_days":120})
	var food:={"resource":"Food","amount":150.0,"available":10000.0,"can_send":true,"reception":"respectable"}
	var timber:={"resource":"Timber","amount":20.0,"available":70.0,"can_send":true,"reception":"especially useful"}
	var scarce:={"resource":"Stone","amount":20.0,"available":30.0,"can_send":true,"reception":"especially useful"}
	assert_str(Strategy.goodwill_gift([food,timber,scarce],120.0,plan)).is_equal("Timber")
	assert_str(Strategy.goodwill_gift([food,scarce],120.0,plan)).is_equal("Food")
	assert_str(Strategy.goodwill_gift([food,scarce],Strategy.GOODWILL_FOOD_DAYS-5.0,plan)).is_equal("")
	# Friends already won receive no more gifts.
	assert_str(Strategy.diplomatic_action({"opinion":.2,"treaty":"trade"},plan,120.0)).is_equal("goodwill")
	assert_str(Strategy.diplomatic_action({"opinion":.7,"treaty":"trade"},plan,120.0)).is_equal("")
	# The order pays the gift from the sender's stores and the mission carries it.
	var id:=Fixture.build_fixture()
	var gift:=Strategy.goodwill_gift(CivilizationSystem.diplomatic_gift_options(id),120.0,plan)
	assert_str(gift).is_not_empty()
	var before:=FoodSystem.total_stored() if gift=="Food" else float(GameState.resource_stockpiles.get(gift,0.0))
	var sent:Dictionary=Orders.execute({"kind":"diplomacy","target":id,"action":"goodwill","gift":gift})
	assert_bool(sent.has("error")).override_failure_message(str(sent)).is_false()
	var carried:=float(CivilizationSystem.diplomatic_mission.get("gift_amount",0.0))
	assert_str(String(CivilizationSystem.diplomatic_mission.get("gift_resource",""))).is_equal(gift)
	assert_float(carried).is_greater(0.0)
	var after:=FoodSystem.total_stored() if gift=="Food" else float(GameState.resource_stockpiles.get(gift,0.0))
	assert_float(after).is_less_equal(before-carried+.01)
	CivilizationSystem.diplomatic_mission.clear()
	assert_bool(Orders.execute({"kind":"diplomacy","target":id,"action":"goodwill"}).has("error")).is_true()

## A computer ruler's own council sends that goodwill: the order leaves with a
## gift paid from its stores (it was refused, gift-less, before).
func test_an_empathetic_ruler_sends_goodwill_with_a_gift_from_its_own_stores()->void:
	GameState.reset_for_new_world(777);CivilizationSystem.reset_for_new_world();CivilizationSystem.initialize()
	WorldSimulation.create_actor("giver",777,Vector2.ZERO)
	var civ:Dictionary=CivilizationSystem.civilizations[0].duplicate(true)
	var stored:Array=[]
	WorldSimulation.scoped("giver",func()->void:
		civ.player_relation.merge({"contact_level":2,"home_location_known":true,"home_position":{"x":24.0,"z":0.0},"opinion":.1,"treaty":"trade","at_war":false},true)
		WorldSimulation.world.civilizations.assign([civ])
		WorldSimulation.food.receive_external_food(20000.0)
		WorldSimulation.state.simulation_metrics["food_days"]=150.0
		stored.append(WorldSimulation.food.total_stored())
		Controller.foreign_orders("giver",Strategy.preferences(Cautious,{"food_days":150,"peoples_known":1}))
		stored.append(WorldSimulation.food.total_stored()))
	var goodwill:Array=[]
	for entry:Dictionary in WorldSimulation.actors.giver.orders:
		if String(entry.order.get("action",""))=="goodwill":goodwill.append(entry)
	assert_int(goodwill.size()).override_failure_message(str(WorldSimulation.actors.giver.orders)).is_equal(1)
	assert_str(String(goodwill[0].order.get("gift",""))).is_not_empty()
	assert_bool((goodwill[0].result as Dictionary).has("error")).override_failure_message(str(goodwill[0].result)).is_false()
	var mission:Dictionary=WorldSimulation.actors.giver.systems.CivilizationSystem.diplomatic_mission
	assert_float(float(mission.get("gift_amount",0.0))).is_greater(0.0)
	assert_float(float(stored[1])).is_less(float(stored[0]))

## Aggression, diplomacy and adaptability come from the leader's own character,
## also for a people saved when they were drawn at random.
func test_old_traits_come_from_the_leaders_character()->void:
	GameState.reset_for_new_world(9091);CivilizationSystem.reset_for_new_world();CivilizationSystem.initialize()
	for civ:Dictionary in CivilizationSystem.civilizations:
		var traits:=Personality.character_traits(Personality.foreign(GameState.world_seed,String(civ.id)))
		assert_float(float(civ.aggression)).is_equal_approx(float(traits.aggression),.0001)
		assert_float(float(civ.adaptability)).is_equal_approx(float(traits.adaptability),.0001)
		assert_bool(civ.has("character_traits")).is_true()
	var hot:=Personality.character_traits({"openness":.2,"discipline":.5,"empathy":.1,"assertiveness":.92,"risk_tolerance":.9})
	var mild:=Personality.character_traits({"openness":.8,"discipline":.5,"empathy":.9,"assertiveness":.12,"risk_tolerance":.2})
	assert_float(float(hot.aggression)).is_greater(float(mild.aggression))
	assert_float(float(mild.diplomacy)).is_greater(float(hot.diplomacy))
	for traits:Dictionary in [hot,mild]:
		assert_float(float(traits.aggression)).is_between(.18,.88)
		assert_float(float(traits.diplomacy)).is_between(.22,.90)
		assert_float(float(traits.adaptability)).is_between(.30,.90)
	# An older save's random traits are brought to the character once, on load.
	var saved:Dictionary=CivilizationSystem.export_state()
	var expected:=float(CivilizationSystem.civilizations[0].aggression)
	for civ:Dictionary in saved.civilizations:civ.erase("character_traits");civ.aggression=.99
	assert_bool(bool(CivilizationSystem.import_state(saved).get("ok",false))).is_true()
	assert_float(float(CivilizationSystem.civilizations[0].aggression)).is_equal_approx(expected,.0001)
	assert_array(CivilizationSystem.validate_state()).is_empty()

## A people set on lasting abundance plans deeper stores: more hands on food
## while the stores are short of its larger reserve, none once they are full.
func test_sustenance_and_wellbeing_plan_deeper_stores()->void:
	var planned:=func(choice:String,food_days:float)->float:
		GameState.reset_for_new_world(41);PeopleDirection.reset_for_new_world();PeopleDirection.ensure()
		if choice!="":Culture.record(PeopleDirection.cultural_memory,"century:0",choice,0,10.0)
		GameState.elapsed_days=365.0*600.0
		GameState.water_metrics={"intake_ratio":1.0,"source_accessible":true}
		GameState.founding_manifest["food_storage_rations"]=120.0*400.0
		GameState.simulation_metrics={"food_consumption":120.0,"food_production":130.0,"food_labor_share":.5,"food_intake_ratio":1.0,"food_days":food_days,"food_projected_days":food_days}
		return float(GovernmentPeopleSystem._allocations_for_focus("balanced",{},true).Food)
	# Stores a little under the plain reserve (RESERVE_TARGET_DAYS, 30 days):
	# the deeper the reserve a people wants, the more it plans.
	var even:=float(planned.call("",25.0))
	var wellbeing:=float(planned.call("wellbeing",25.0))
	var sustenance:=float(planned.call("sustenance",25.0))
	assert_float(wellbeing).is_greater(even)
	assert_float(sustenance).is_greater(wellbeing)
	# With the deep reserve full, the planners release the extra hands again.
	assert_float(float(planned.call("sustenance",200.0))).is_equal_approx(float(planned.call("",200.0)),.5)
	assert_float(GovernmentPeopleSystem.reserve_lean_of(12.0)).is_equal(1.0)
	assert_float(GovernmentPeopleSystem.reserve_lean_of(6.0)).is_equal(.5)
