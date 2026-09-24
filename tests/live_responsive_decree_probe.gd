extends Node
## Manual live-account probe (three small requests). Verifies the character-
## first civic prompt stays in the world and that the strict schema returns a
## valid custom-directive plan. Not part of the deterministic suite. Never
## prints the key.

const CustomDirective:=preload("res://scripts/custom_directive.gd")
const VillageNotables:=preload("res://scripts/village_notables.gd")
const LINES:=[
	"Who is the smartest fertile man in the village?",
	"Have the smartest men father children with other men's wives",
	"Crown my horse as magistrate and make everyone bow to it.",
]

var received:Dictionary={}
var failures:Array[String]=[]

func _ready()->void:
	GameState.reset_for_new_world(481902)
	ForeignDiplomacy.reset_for_new_world()
	GovernmentPeopleSystem.reset_for_new_world()
	PronouncementInterpreter.reset_for_new_world()
	ConsequenceEngine.reset_for_new_world()
	AdvisorSystem.reset_for_new_world()
	GameState.initialize_population_model()
	GameState.settlement_name="Dawngate"
	GameState.settlement_site_committed=true
	GameState.settlement_completed=["Hearth Circle"]
	SettlementModel.ensure_founded()
	GovernmentPeopleSystem.initialize()
	ConsequenceEngine.initialize()
	GameState.civic_api_enabled=true
	GameState.civic_always_use_ai=true
	# Live mode, and keep these test exchanges out of the player's interaction store.
	var ai_mode:=preload("res://scripts/ai_mode.gd")
	ai_mode.reset_for_tests("user://live_responsive_probe_ai_mode.cfg")
	ai_mode.set_mode(ai_mode.LIVE,false)
	ai_mode.set_records_interactions(false,false)
	var configuration:=PronouncementInterpreter.configuration_status()
	if not bool(configuration.get("configured",false)):
		push_error("LIVE_RESPONSIVE_DECREE_PROBE FAIL · API is not configured")
		get_tree().quit(1)
		return
	print("model: %s · structured output: %s" % [String(configuration.get("model","")),str(configuration.get("structured_output",false))])
	PronouncementInterpreter.interpretation_completed.connect(func(_id:String,result:Dictionary)->void: received=result.duplicate(true))
	var city:=String(GameState.player_settlements[0].id)
	var leader:=GovernmentPeopleSystem.settlement_leader(city)
	for line_variant in LINES:
		var line:=String(line_variant)
		var context:={
			"day":int(GameState.elapsed_days),"population":GameState.population_total,
			"settlement":{"id":city,"name":"Dawngate","population":GameState.population_total,"classification":"village"},
			"leader":{"name":String(leader.get("name","")),"title":String(leader.get("title","")),"background":String(leader.get("background","")),"traits":(leader.get("traits",[]) as Array).duplicate()},
			"conversation":AdvisorSystem.civic_dialogue_history(city,24),"decisions":AdvisorSystem.civic_decision_context(city),"active_policies":[],
		}
		received={}
		var order:=AdvisorSystem.begin_civic_directive(line,city,leader)
		PronouncementInterpreter.interpret(line,context)
		var deadline:=Time.get_ticks_msec()+60000
		while received.is_empty() and Time.get_ticks_msec()<deadline: await get_tree().process_frame
		if received.is_empty():
			failures.append("%s: timed out" % line)
			continue
		var answer:=String(received.get("answer",""))
		var custom:Dictionary=received.get("custom_directive",{})
		print("\nGOD: %s\nMODEL ANSWER (%s): %s" % [line,String(received.get("source","")),answer])
		print("custom_directive: %s" % JSON.stringify(custom))
		if CustomDirective.breaks_frame(answer): failures.append("%s: model answer broke frame" % line)
		var resolved:=AdvisorSystem.resolve_civic_directive(line,received,order,city,int(leader.get("person_id",0)))
		print("LEADER (as shown): %s" % String(resolved.get("leader_reply","")).split("\n\nSTATE ·")[0])
		if line==String(LINES[0]):
			var notable:=VillageNotables.resolve(city,line)
			if String(notable.get("given","")) not in String(resolved.get("leader_reply","")): failures.append("person answer did not name the registered villager")
			if String(resolved.get("status",""))!="discussion": failures.append("person question enacted something")
		else:
			if not bool(custom.get("applies",false)): failures.append("%s: model did not propose a custom directive" % line)
			if (custom.get("effects",[]) as Array).is_empty(): failures.append("%s: model proposed no valid effects" % line)
			if "RECEIPT · " not in String(resolved.get("leader_reply","")): failures.append("%s: no receipt line after execution" % line)
	if failures.is_empty():
		print("\nLIVE_RESPONSIVE_DECREE_PROBE PASS")
		get_tree().quit(0)
		return
	for failure in failures: push_error(failure)
	print("\nLIVE_RESPONSIVE_DECREE_PROBE FAIL (%d)" % failures.size())
	get_tree().quit(1)
