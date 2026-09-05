extends Node
var failures:Array[String]=[]
func check(value:bool,message:String)->void:
	if not value: failures.append(message)
func _ready()->void:
	GameState.reset_for_new_world(190887)
	CivilizationSystem.reset_for_new_world(); CivilizationSystem.initialize()
	CommunityNetwork.ensure()
	check(CommunityNetwork.nodes().size()==1,"unmet communities leaked into network")
	check(CommunityNetwork.propose("unknown","open_trade").has("error"),"unknown community accepted proposal")
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	civ.player_relation.contact_level=2
	civ.player_relation.home_location_known=false
	check(CommunityNetwork.nodes().size()==2,"known contact absent")
	check(CommunityNetwork.propose(String(civ.id),"open_trade").has("error"),"proposal bypassed destination requirement")
	check(CommunityNetwork.start("records").has("error"),"archive ignored knowledge prerequisite")
	GameState.known_discoveries.append("test_observation")
	GameState.resource_stockpiles["Timber"]=20.0; GameState.resource_stockpiles["Fiber Plants"]=20.0
	check(CommunityNetwork.start("records").get("ok",false),"eligible shared records project rejected")
	check(GameState.resource_stockpiles.Timber==12.0 and GameState.resource_stockpiles["Fiber Plants"]==16.0,"project did not charge exact materials")
	check(CommunityNetwork.start("records").has("error"),"duplicate project charged twice")
	check(CommunityNetwork.multiplier("knowledge")==.92,"project opportunity cost absent")
	GameState.population_allocations.Knowledge=0; GameState.population_allocations.Administration=0
	CommunityNetwork.advance(30)
	check(CommunityNetwork.progress==0,"project created work without workers")
	GameState.population_allocations.Knowledge=4
	CommunityNetwork.advance(90)
	var progress:float=CommunityNetwork.progress
	CommunityNetwork.advance(90)
	check(CommunityNetwork.progress==progress,"duplicate day created work")
	CommunityNetwork.advance(150)
	check("records" in CommunityNetwork.completed and CommunityNetwork.active=="","project did not complete from real work")
	check(is_equal_approx(CommunityNetwork.multiplier("knowledge"),1.12),"completed capability has no benefit")
	check(CommunityNetwork.start("records").has("error"),"completed project repeated")
	var state:=CommunityNetwork.export_state()
	check(CommunityNetwork.import_state(JSON.parse_string(JSON.stringify(state))).get("ok",false),"network JSON save failed")
	var bad:=state.duplicate(true); bad.completed.append("records")
	check(CommunityNetwork.import_state(bad).has("error") and CommunityNetwork.completed.size()==1,"invalid save changed network")
	check(CommunityNetwork.import_state({"version":1,"seed":190887}).has("error"),"incomplete save accepted")
	bad=state.duplicate(true); bad.progress=10
	check(CommunityNetwork.import_state(bad).has("error"),"inactive project retained work")
	if failures.is_empty(): print("COMMUNITY_NETWORK PASS: fog, known contacts, physical diplomacy, prerequisites, exact costs, real work, deduplication, capability effects, JSON persistence")
	else:
		for message in failures: push_error(message)
	get_tree().quit(0 if failures.is_empty() else 1)
