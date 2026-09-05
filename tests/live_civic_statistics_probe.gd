extends Node

var received:Dictionary={}

func _ready()->void:
	GameState.reset_for_new_world(884203)
	ConsequenceEngine.reset_for_new_world()
	ConsequenceEngine.initialize()
	PronouncementInterpreter.reset_for_new_world()
	GameState.civic_always_use_ai=true
	GameState.ensure_population_total(120)
	GameState.simulation_metrics["security"]=0.7
	GameState.society_capacities["institutions"]=0.7
	GameState.settlement_site_committed=true
	GameState.settlement_completed=["Hearth Circle"]
	GameState.settlement_name="Statistics Probe"
	SettlementModel.ensure_founded()
	GovernmentPeopleSystem.initialize()
	var city_id:=String(GameState.player_settlements[0].id)
	var leader:=GovernmentPeopleSystem.settlement_leader(city_id)
	PronouncementInterpreter.interpretation_completed.connect(func(_id:String,result:Dictionary)->void: received=result)
	var wording:="Just execute one example to scare the workers."
	PronouncementInterpreter.interpret(wording,{"leader":leader,"population":120})
	var deadline:=Time.get_ticks_msec()+90000
	while received.is_empty() and Time.get_ticks_msec()<deadline: await get_tree().process_frame
	if String(received.get("source",""))!="generative API" or received.get("policies",[]).size()!=1:
		fail("No validated Terra policy: "+JSON.stringify(received)); return
	var policy:Dictionary=received.policies[0]
	var parameters:Dictionary=policy.get("directive_parameters",{})
	var target:Dictionary=parameters.get("demographic_target",{})
	if int(target.get("exact_count",0))!=1 or target.has("sex") or String(target.get("role",""))!="worker":
		fail("Wrong target: "+JSON.stringify(target)); return
	if parameters.get("statistical_effects",[]).is_empty():
		fail("Terra supplied no statistical reasoning: "+JSON.stringify(received)); return
	var before:=GameState.population_exact
	var order:=AdvisorSystem.begin_civic_directive(wording,city_id,leader)
	var resolved:=AdvisorSystem.resolve_civic_directive(wording,received,order,city_id,int(leader.person_id))
	var outcome:Dictionary=resolved.parameters.interpretation.policies[0]
	if not bool(outcome.get("applied",false)) or not is_equal_approx(GameState.population_exact,before-1.0) or int(outcome.get("direct_effects",{}).get("population_deaths",0))!=1:
		fail("Execution did not conserve exact count: "+JSON.stringify(outcome)); return
	print("LIVE_CIVIC_STATISTICS PASS · "+JSON.stringify({"answer":received.get("answer",""),"leader_reply":resolved.get("leader_reply",""),"target":target,"estimates":parameters.statistical_effects,"actual":outcome.direct_effects,"ledger":GameState.demographic_ledger[0]}))
	get_tree().quit(0)

func fail(reason:String)->void:
	push_error("LIVE_CIVIC_STATISTICS FAIL · "+reason)
	get_tree().quit(1)
