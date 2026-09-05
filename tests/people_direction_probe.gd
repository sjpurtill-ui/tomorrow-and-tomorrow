extends Node
var failures:Array[String]=[]
func check(condition:bool,message:String)->void:
	if not condition: failures.append(message)
func _ready()->void:
	PeopleDirection.reset_for_new_world(); PeopleDirection.ensure()
	var original:Dictionary=GameState.societal_values.duplicate(true)
	var weights:Dictionary=GameState.population_allocation_percentages.duplicate(true)
	var population:int=GameState.population_total
	var food:float=GameState.resource_stockpiles.get("Food",0)
	check(PeopleDirection.research_multiplier("knowledge")==1,"ambition applied before selection")
	check(PeopleDirection.choose("inquiry").get("ok",false),"valid ambition rejected")
	check(PeopleDirection.research_multiplier("knowledge")==1.25 and PeopleDirection.research_multiplier("production")==.95,"ambition tradeoff absent")
	check(PeopleDirection.choose("makers").has("error"),"rapid ambition switching allowed")
	check(PeopleDirection.decide(0).has("error"),"vision available too early")
	var normalized:Dictionary=PeopleDirection.VALUES.normalize_state(GameState.societal_values)
	var before:float=normalized.official.experimentation
	PeopleDirection.advance(30)
	var after:float=GameState.societal_values.official.experimentation
	check(after>=before,"ambition did not change public values")
	PeopleDirection.advance(30)
	check(GameState.societal_values.official.experimentation==after,"same day applied twice")
	GameState.elapsed_days=30
	check(PeopleDirection.decide(0).get("ok",false),"vision decision failed")
	check(PeopleDirection.decide(0).has("error"),"decision effect could be farmed")
	check(PeopleDirection.resolved==1,"decision not recorded")
	GameState.simulation_metrics["food_days"]=3
	PeopleDirection.routine_work(30)
	var sum:=0.0
	for value in GameState.population_allocation_percentages.values(): sum+=float(value)
	check(absf(sum-100)<.001,"automatic work did not conserve labor shares")
	check(GameState.population_allocation_percentages==weights,"legacy automation competed with settlement leaders")
	check(GameState.population_total==population and GameState.resource_stockpiles.get("Food",0)==food,"automatic work created population or food")
	GameState.adjust_population_role_percentage("Knowledge",1)
	var manual:Dictionary=GameState.population_allocation_percentages.duplicate(true)
	PeopleDirection.routine_work(90)
	check(manual==GameState.population_allocation_percentages,"automatic work overwrote manual choices")
	var save:=PeopleDirection.export_state()
	check(PeopleDirection.import_state(JSON.parse_string(JSON.stringify(save))).get("ok",false),"JSON roundtrip failed")
	var invalid:=save.duplicate(true); invalid.ambition="invalid"
	check(PeopleDirection.import_state(invalid).has("error") and PeopleDirection.ambition=="inquiry","invalid save mutated direction")
	GameState.elapsed_days=5000
	check(PeopleDirection.decide(1).get("ok",false),"unanswered vision expired")
	PeopleDirection.reset_for_new_world()
	check(PeopleDirection.ambition=="" and PeopleDirection.history.is_empty(),"new world retained choices")
	GameState.societal_values=original
	if failures.is_empty(): print("PEOPLE_DIRECTION PASS: ambitions, paced values, no duplicate decisions, no expiry, labor conservation, manual override, save roundtrip, reset")
	else:
		for message in failures: push_error(message)
	get_tree().quit(0 if failures.is_empty() else 1)
