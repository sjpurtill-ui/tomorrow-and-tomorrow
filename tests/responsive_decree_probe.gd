extends Node
## Responsive decrees: leaders stay in character, improvised villagers persist,
## and every explicit order ripples through real engine inputs over time.
## Offline and deterministic. Prints a transcript and metric timeline.

const CustomDirective:=preload("res://scripts/custom_directive.gd")
const VillageNotables:=preload("res://scripts/village_notables.gd")
const QUESTION:="Who is the smartest fertile man in the village?"
const BREEDING:="Have the smartest men father children with other men's wives"
const MILD:="Encourage the cleverest families to have more children"
const POPULATION:=600
const DAYS:=540
const SEEDS:=[481902,77123,90210,31337]
const CHECKPOINTS:=[30,90,180,270,360,450,540]

var failures:Array[String]=[]

func _ready()->void:
	_scenario_transcript()
	_scenario_timeline()
	_scenario_mild_order()
	_scenario_catalog_and_questions()
	await _scenario_offline_mode()
	if failures.is_empty():
		print("RESPONSIVE_DECREE_PROBE PASS")
		get_tree().quit(0)
		return
	for failure in failures: push_error(failure)
	print("RESPONSIVE_DECREE_PROBE FAIL (%d)" % failures.size())
	get_tree().quit(1)

func _expect(condition:bool,message:String)->void:
	if not condition: failures.append(message)

func _world(seed_value:int)->String:
	GameState.reset_for_new_world(seed_value)
	ForeignDiplomacy.reset_for_new_world()
	GovernmentPeopleSystem.reset_for_new_world()
	PronouncementInterpreter.reset_for_new_world()
	ConsequenceEngine.reset_for_new_world()
	AdvisorSystem.reset_for_new_world()
	GameState.civic_api_enabled=false
	GameState.initialize_population_model()
	GameState.settlement_name="Dawngate"
	GameState.settlement_site_committed=true
	GameState.settlement_completed=["Hearth Circle","Lean-to Shelters"]
	SettlementModel.ensure_founded()
	GovernmentPeopleSystem.initialize()
	GameState.ensure_population_total(POPULATION)
	GameState.housing_capacity=POPULATION+60
	GameState.food_stocks.clear()
	GameState.resource_stockpiles["Food"]=float(POPULATION)*400.0
	GameState.resource_stockpiles["Freshwater"]=float(POPULATION)*6.0
	GameState.resource_stockpiles["Timber"]=float(POPULATION)*0.4
	GameState.resource_stockpiles["Stone"]=float(POPULATION)*0.4
	FoodSystem.reset_for_new_world()
	FoodSystem.initialize()
	ConsequenceEngine.initialize()
	# Only the consequence engine runs here; hold drinking water steady so the
	# experiment isolates the order (ResourceSystem is not stepped).
	GameState.water_metrics={"intake_ratio":1.0,"days":30.0,"stored":float(POPULATION)*6.0}
	return String(GameState.player_settlements[0].id)

func _say(settlement_id:String,text:String)->Dictionary:
	var leader:=GovernmentPeopleSystem.settlement_leader(settlement_id)
	var reading:=PronouncementInterpreter._local_interpretation(text,{"settlement":{"id":settlement_id}})
	var order:=AdvisorSystem.begin_civic_directive(text,settlement_id,leader)
	return AdvisorSystem.resolve_civic_directive(text,reading,order,settlement_id,int(leader.get("person_id",0)))

func _speech(order:Dictionary)->String:
	var reply:=String(order.get("leader_reply",""))
	return reply.split("\n\nSTATE ·")[0]

func _in_character(text:String)->bool:
	return not text.strip_edges().is_empty() and not CustomDirective.breaks_frame(text.split("\n\nRECEIPT · ")[0])

func _run_days(settlement_id:String,days:int,record:Callable=Callable())->void:
	for day in days:
		GameState.elapsed_days+=1.0
		ConsequenceEngine.process_day({"traveling":false})
		CivicImplementationSystem.process_day()
		if record.is_valid(): record.call(int(GameState.elapsed_days))

func _snapshot()->Dictionary:
	return {
		"conceptions":GameState.lifetime_conceptions,"births":GameState.lifetime_births,"newborn_deaths":GameState.lifetime_neonatal_deaths,
		"deaths":GameState.lifetime_deaths,"departures":GameState.lifetime_departures,"population":GameState.population_total,
		"cohesion":float(GameState.simulation_metrics.get("cohesion",0.0)),"legitimacy":float(GameState.simulation_metrics.get("legitimacy",0.0)),
		"knowledge":float(GameState.simulation_metrics.get("knowledge",0.0)),"health":GameState.population_health,
		"illness":float((GameState.simulation_metrics.get("mortality_components",{}) as Dictionary).get("Illness",0.0)),
		"conception_rate":float(GameState.simulation_metrics.get("annual_conceptions_expected",0.0)),
		"newborn_risk":1.0-clampf(ConsequenceEngine.policy_effect("neonatal_survival"),-0.5,0.6),
	}

func _scenario_transcript()->void:
	print("\n=== TRANSCRIPT (offline, seed %d) ===" % int(SEEDS[0]))
	var city:=_world(int(SEEDS[0]))
	var leader:=GovernmentPeopleSystem.settlement_leader(city)
	print("Leader: %s, %s" % [String(leader.get("name","")),String(leader.get("title",""))])
	var first:=_say(city,QUESTION)
	print("GOD: %s\nLEADER: %s\n" % [QUESTION,_speech(first)])
	var notable:=VillageNotables.resolve(city,QUESTION)
	_expect(String(first.get("status",""))=="discussion","person question enacted something")
	_expect(_in_character(_speech(first)),"person answer broke frame: %s" % _speech(first))
	_expect(String(notable.get("given","")) in _speech(first),"person answer did not name the villager")
	_expect(String(notable.get("sex",""))=="male" and (notable.get("excels",[]) as Array).has("wit") and (notable.get("excels",[]) as Array).has("fertility"),"notable does not match the question")
	var again:=_say(city,QUESTION)
	print("GOD: %s\nLEADER: %s\n" % [QUESTION,_speech(again)])
	_expect(String(notable.get("given","")) in _speech(again),"re-ask named a different man")
	_expect(ConsequenceEngine.active_policies().is_empty(),"questions created a policy")
	var ordered:=_say(city,BREEDING)
	print("GOD: %s\nLEADER: %s\n" % [BREEDING,_speech(ordered)])
	_expect(String(ordered.get("status","")) in ["interpreted","active"],"breeding order was not put into effect (status %s)" % String(ordered.get("status","")))
	_expect(_in_character(_speech(ordered)),"breeding reply broke frame")
	_expect("RECEIPT · " in _speech(ordered),"breeding reply lacks the numeric receipt line")
	var custom:=_custom_policy(ordered)
	_expect(not custom.is_empty() and bool(custom.get("applied",false)),"breeding order did not apply a custom directive")
	var plan:Dictionary=custom.get("directive_parameters",{}).get("custom_plan",{})
	_expect((plan.get("natures",[]) as Array).has("selective_breeding"),"breeding order was not read as selective breeding")
	_run_days(city,120)
	var report:=_latest_report(city)
	print("(120 days later)\nLEADER REPORT: %s\n" % report)
	_expect(not report.is_empty(),"no in-character follow-up report arrived")
	_expect(_in_character(report),"follow-up report broke frame")
	_expect("percentage points" not in report and "What we can see" not in report,"report still reads like a spreadsheet")
	var later:=_say(city,"Is %s still alive?" % String(notable.get("given","")))
	print("GOD: Is %s still alive?\nLEADER: %s\n" % [String(notable.get("given","")),_speech(later)])

func _custom_policy(order:Dictionary)->Dictionary:
	for policy in order.get("parameters",{}).get("interpretation",{}).get("policies",[]):
		if String((policy as Dictionary).get("id",""))==CustomDirective.ID: return policy
	return {}

func _latest_report(settlement_id:String)->String:
	var history:=AdvisorSystem.civic_dialogue_history(settlement_id,24)
	for index in range(history.size()-1,-1,-1):
		if String(history[index].get("status","")).begins_with("outcome_report_"): return String(history[index].get("text","")).split("\n\nSTATE ·")[0]
	return ""

func _scenario_timeline()->void:
	print("=== TIMELINE: control vs. breeding order, %d people, %d days ===" % [POPULATION,DAYS])
	var side_effects_seen:Dictionary={}
	var fertility_up:=0
	var cohesion_down:=0
	var knowledge_up:=0
	for seed_variant in SEEDS:
		var seed_value:=int(seed_variant)
		var control:=_timeline(seed_value,false)
		var ordered:=_timeline(seed_value,true)
		print("seed %d" % seed_value)
		print("  day | conceptions/yr rate c/o | conceptions c/o | births c/o | newborn risk x c/o | newborn deaths c/o | cohesion c/o | knowledge c/o | illness mortality/yr c/o")
		for checkpoint in CHECKPOINTS:
			var c:Dictionary=control.series[checkpoint]; var o:Dictionary=ordered.series[checkpoint]
			print("  %3d | %5.2f / %5.2f | %3d / %3d | %3d / %3d | %.2f / %.2f | %d / %d | %.3f / %.3f | %.4f / %.4f | %.4f / %.4f" % [checkpoint,float(c.conception_rate),float(o.conception_rate),int(c.conceptions),int(o.conceptions),int(c.births),int(o.births),float(c.newborn_risk),float(o.newborn_risk),int(c.newborn_deaths),int(o.newborn_deaths),float(c.cohesion),float(o.cohesion),float(c.knowledge),float(o.knowledge),float(c.illness),float(o.illness)])
		var end_c:Dictionary=control.series[DAYS]; var end_o:Dictionary=ordered.series[DAYS]
		var active_c:Dictionary=control.series[180]; var active_o:Dictionary=ordered.series[180]
		if float(active_o.conception_rate)>float(active_c.conception_rate) and int(end_o.conceptions)>=int(end_c.conceptions) and int(end_o.births)>=int(end_c.births): fertility_up+=1
		if float(end_o.cohesion)<float(end_c.cohesion): cohesion_down+=1
		if float(end_o.knowledge)>float(end_c.knowledge): knowledge_up+=1
		var fired:Array=ordered.get("side_effects",[])
		print("  unforeseen side effects rolled: %s" % (", ".join(PackedStringArray(fired)) if not fired.is_empty() else "none"))
		for parameter in ordered.get("names",[]): side_effects_seen[String(parameter)]=true
		var growth_c:=int(end_c.births)-int(end_c.newborn_deaths)
		var growth_o:=int(end_o.births)-int(end_o.newborn_deaths)
		print("  net surviving births control %d, ordered %d (%+.1f%%)" % [growth_c,growth_o,(float(growth_o)/maxf(1.0,float(growth_c))-1.0)*100.0])
	_expect(fertility_up==SEEDS.size(),"fertility rose in only %d of %d seeds" % [fertility_up,SEEDS.size()])
	_expect(cohesion_down==SEEDS.size(),"cohesion fell in only %d of %d seeds" % [cohesion_down,SEEDS.size()])
	_expect(knowledge_up>=3,"knowledge rose in only %d of %d seeds" % [knowledge_up,SEEDS.size()])
	_expect(side_effects_seen.has("infant_mortality") or side_effects_seen.has("disease"),"no infant-mortality or disease side effect in any seed")
	print("")

func _timeline(seed_value:int,with_order:bool)->Dictionary:
	var city:=_world(seed_value)
	var series:Dictionary={0:_snapshot()}
	var labels:Array=[]
	var names:Array=[]
	if with_order:
		var order:=_say(city,BREEDING)
		for effect_variant in _custom_policy(order).get("custom_realized",[]):
			var effect:Dictionary=effect_variant
			if not bool(effect.get("side_effect",false)): continue
			labels.append("%s from day %d" % [String(effect.parameter),int(effect.delay_days)])
			names.append(String(effect.parameter))
	_run_days(city,DAYS,func(day:int)->void:
		if day in CHECKPOINTS: series[day]=_snapshot())
	return {"series":series,"side_effects":labels,"names":names}

func _scenario_mild_order()->void:
	print("=== MILD ORDER ===")
	var city:=_world(int(SEEDS[1]))
	var order:=_say(city,MILD)
	print("GOD: %s\nLEADER: %s\n" % [MILD,_speech(order)])
	var ids:Array[String]=[]
	for policy in order.get("parameters",{}).get("interpretation",{}).get("policies",[]): ids.append(String((policy as Dictionary).get("id","")))
	print("  engine reading: %s" % ", ".join(PackedStringArray(ids)))
	_expect(String(order.get("status","")) in ["interpreted","active"],"mild order was not put into effect")
	_expect(ids.has("family_support"),"mild order lost its catalog family-support reading")
	_expect(ids.has(CustomDirective.ID),"mild order's selective part did not ripple")
	_expect(_in_character(_speech(order)),"mild reply broke frame")

func _scenario_offline_mode()->void:
	## Offline AI mode: the interaction database answers through the real
	## interpret() entry point; the custom path consumes its effects.
	print("=== OFFLINE MODE (interaction database) ===")
	var ai_mode:=preload("res://scripts/ai_mode.gd")
	ai_mode.reset_for_tests("user://responsive_probe_ai_mode.cfg")
	ai_mode.set_mode(ai_mode.OFFLINE,false)
	var city:=_world(int(SEEDS[3]))
	GameState.civic_api_enabled=true
	_expect(PronouncementInterpreter._api_config().is_empty(),"offline mode still built an API configuration")
	for line in [QUESTION,BREEDING,"Hold a feast for the whole village."]:
		var leader:=GovernmentPeopleSystem.settlement_leader(city)
		var holder:Dictionary={}
		var capture:=func(_id:String,result:Dictionary)->void: holder["result"]=result
		PronouncementInterpreter.interpretation_completed.connect(capture)
		var order:=AdvisorSystem.begin_civic_directive(line,city,leader)
		PronouncementInterpreter.interpret(line,{"settlement":{"id":city,"name":"Dawngate","population":GameState.population_total,"classification":"village"},"leader":{"name":String(leader.get("name",""))}})
		for frame in 30:
			if holder.has("result"): break
			await get_tree().process_frame
		PronouncementInterpreter.interpretation_completed.disconnect(capture)
		var reading:Dictionary=holder.get("result",{})
		_expect(String(reading.get("source",""))=="offline interaction database","%s: offline mode did not answer from the database (%s)" % [line,String(reading.get("source",""))])
		var resolved:=AdvisorSystem.resolve_civic_directive(line,reading,order,city,int(leader.get("person_id",0)))
		print("GOD: %s
LEADER (offline): %s
" % [line,_speech(resolved)])
		_expect(_in_character(_speech(resolved)),"%s: offline reply broke frame" % line)
		if line==QUESTION:
			_expect(String(resolved.get("status",""))=="discussion","offline person question enacted something")
			_expect(String(VillageNotables.resolve(city,QUESTION).get("given","")) in _speech(resolved),"offline answer did not name the registered villager")
			_expect("Keen-Eye" not in _speech(resolved) and "Old Hollin" not in _speech(resolved),"offline answer used a placeholder name")
		else:
			var custom:=_custom_policy(resolved)
			_expect(not custom.is_empty() and bool(custom.get("applied",false)),"%s: offline order did not ripple" % line)
			if not custom.is_empty(): print("  plan source: %s · type %s" % [String(custom.directive_parameters.custom_plan.get("source","")),String(custom.directive_parameters.custom_plan.get("offline_type",""))])
	ai_mode.set_mode(ai_mode.LIVE,false)
	GameState.civic_api_enabled=false

func _scenario_catalog_and_questions()->void:
	print("=== CATALOG ORDER AND QUESTIONS ===")
	var city:=_world(int(SEEDS[2]))
	var watch:=_say(city,"Expand the watch.")
	print("GOD: Expand the watch.\nLEADER: %s\n" % _speech(watch))
	var ids:Array[String]=[]
	for policy in watch.get("parameters",{}).get("interpretation",{}).get("policies",[]): ids.append(String((policy as Dictionary).get("id","")))
	_expect(ids==["expanded_watch"],"catalog order changed shape: %s" % str(ids))
	_expect("report back around Year" in _speech(watch),"catalog order lost its report promise")
	var before:=ConsequenceEngine.active_policies().size()
	for question in ["Why are we rationing food?","Would killing dissidents help?","What do you think about a temple?","The river is high this spring."]:
		var answer:=_say(city,question)
		print("GOD: %s\nLEADER: %s\n" % [question,_speech(answer)])
		_expect(String(answer.get("status",""))=="discussion","question enacted something: %s" % question)
		_expect(_in_character(_speech(answer)),"question answer broke frame: %s" % question)
	_expect(ConsequenceEngine.active_policies().size()==before,"questions changed active policies")
