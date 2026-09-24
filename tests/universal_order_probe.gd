extends Node
## Nothing the god says is beyond the engine: every explicit order yields an
## in-character reply and at least one bounded change to alterable parameters,
## deterministically and offline. Prints an order -> effects table.

const CustomDirective:=preload("res://scripts/custom_directive.gd")
const SEED:=515151
const ORDERS:=[
	# mundane
	"Build a palisade around the village.",
	"Gather firewood for the winter.",
	"Fish the river every morning.",
	"Plant seeds along the riverbank.",
	"Teach the children to count the stars.",
	"Dig latrines away from the huts and keep the water clean.",
	"Trade our hides with the people across the hills.",
	"Give everyone a day of rest.",
	"Work harder until the stores are full.",
	"Expand the watch.",
	"Ration food for thirty days.",
	# strange
	"Rename the village Emberfall.",
	"Everyone must paint their faces red at dusk.",
	"Crown my horse as magistrate.",
	"Let the men take two wives each.",
	"Raise all children together at one fire.",
	"Sing my name at every meal.",
	"Clear the forest to the east.",
	"Move the village to the far side of the river.",
	"Welcome the strangers camped by the ford.",
	# cruel
	"Have the smartest men father children with other men's wives",
	"Flog anyone who questions my word.",
	"Exile the family that stole the grain.",
	"Enslave the captives and make them haul stone.",
	"Forbid women from speaking at the council fire.",
	"Sacrifice a child at the new moon.",
	"Set informers to watch every hearth.",
	"Separate the men and women for a season.",
	"Kill the dissidents.",
	# religious
	"Build a great temple to me on the hill.",
	"Pray to me at dawn and dusk.",
	"Sacrifice a goat at the stone altar.",
	"Hold a feast in my honour.",
	"Carve my likeness into the cliff.",
	# impossible
	"Make it rain tomorrow.",
	"Raise the dead from the burial mound.",
	"Teach the people to fly.",
	"Turn the river stones into gold.",
	"Stop the winter from coming.",
	"Hunt the great wolf that stalks the herds.",
	"Build stone houses for every family.",
]
const FORBIDDEN:=["cannot simulate","can't simulate","cannot be simulated","not implemented","no mechanic","missing mechanic","outside the civic work","no event has been scheduled","not a failure to understand"]

var failures:Array[String]=[]

func _ready()->void:
	print("\n=== UNIVERSAL ORDER TABLE (offline, seed %d) ===" % SEED)
	print("order | path | engine changes (receipt) | leader")
	var custom_count:=0
	for order_text_variant in ORDERS:
		var order_text:=String(order_text_variant)
		var city:=_world()
		var leader:=GovernmentPeopleSystem.settlement_leader(city)
		var reading:=PronouncementInterpreter._local_interpretation(order_text,{"settlement":{"id":city}})
		var order:=AdvisorSystem.begin_civic_directive(order_text,city,leader)
		var resolved:=AdvisorSystem.resolve_civic_directive(order_text,reading,order,city,int(leader.get("person_id",0)))
		var reply:=String(resolved.get("leader_reply",""))
		var speech:=reply.split("\n\nSTATE ·")[0].split("\n\nRECEIPT · ")[0].replace("\n"," ")
		var receipt:=reply.split("\n\nSTATE ·")[0].split("\n\nRECEIPT · ")[1] if "\n\nRECEIPT · " in reply else ""
		var path:Array[String]=[]
		var changed:=false
		for policy_variant in resolved.get("parameters",{}).get("interpretation",{}).get("policies",[]):
			var policy:Dictionary=policy_variant
			var policy_id:=String(policy.get("id",""))
			if policy_id==CustomDirective.ID:
				custom_count+=1
				path.append("custom[%s]" % ",".join(PackedStringArray(policy.get("directive_parameters",{}).get("custom_plan",{}).get("natures",[]))))
				for effect in policy.get("custom_realized",[]):
					if absf(float((effect as Dictionary).get("value",0.0)))>0.0: changed=true
			else:
				path.append(policy_id)
			if bool(policy.get("applied",false)): changed=true
		var status:=String(resolved.get("status",""))
		# A clear grave order may first ask one question; confirm and continue.
		if status in ["awaiting_clarification","awaiting_confirmation"]:
			var confirm:=AdvisorSystem.begin_civic_directive("Yes, do it.",city,leader)
			resolved=AdvisorSystem.resolve_civic_directive("Yes, do it.",PronouncementInterpreter._local_interpretation("Yes, do it."),confirm,city,int(leader.get("person_id",0)))
			status=String(resolved.get("status",""))
			for policy_variant in resolved.get("parameters",{}).get("interpretation",{}).get("policies",[]):
				if bool((policy_variant as Dictionary).get("applied",false)): changed=true
			reply=String(resolved.get("leader_reply",""))
			speech=reply.split("\n\nSTATE ·")[0].split("\n\nRECEIPT · ")[0].replace("\n"," ")
			receipt=reply.split("\n\nSTATE ·")[0].split("\n\nRECEIPT · ")[1] if "\n\nRECEIPT · " in reply else receipt
		print("%s | %s | %s | %s" % [order_text,"+".join(PackedStringArray(path)),receipt if not receipt.is_empty() else "(catalog standing effects; see policy)",speech.substr(0,220)])
		_expect(not speech.strip_edges().is_empty(),"%s: empty reply" % order_text)
		_expect(not CustomDirective.breaks_frame(speech),"%s: reply broke frame: %s" % [order_text,speech])
		for phrase in FORBIDDEN: _expect(String(phrase) not in reply.to_lower(),"%s: reply says '%s'" % [order_text,phrase])
		_expect(status not in ["proposal","discussion","leader_unavailable"],"%s: order did not take effect (status %s)" % [order_text,status])
		_expect(changed,"%s: no bounded parameter changed" % order_text)
	print("orders: %d, custom directives used: %d" % [ORDERS.size(),custom_count])
	# Determinism: the same world and words give the same receipt.
	var first:=_receipt_for(String(ORDERS[20]))
	var second:=_receipt_for(String(ORDERS[20]))
	_expect(first==second and not first.is_empty(),"custom directive is not deterministic")
	if failures.is_empty():
		print("UNIVERSAL_ORDER_PROBE PASS")
		get_tree().quit(0)
		return
	for failure in failures: push_error(failure)
	print("UNIVERSAL_ORDER_PROBE FAIL (%d)" % failures.size())
	get_tree().quit(1)

func _expect(condition:bool,message:String)->void:
	if not condition: failures.append(message)

func _receipt_for(order_text:String)->String:
	var city:=_world()
	var leader:=GovernmentPeopleSystem.settlement_leader(city)
	var order:=AdvisorSystem.begin_civic_directive(order_text,city,leader)
	var resolved:=AdvisorSystem.resolve_civic_directive(order_text,PronouncementInterpreter._local_interpretation(order_text),order,city,int(leader.get("person_id",0)))
	var reply:=String(resolved.get("leader_reply",""))
	return reply.split("\n\nRECEIPT · ")[1].split("\n\nSTATE ·")[0] if "\n\nRECEIPT · " in reply else ""

func _world()->String:
	GameState.reset_for_new_world(SEED)
	ForeignDiplomacy.reset_for_new_world()
	GovernmentPeopleSystem.reset_for_new_world()
	PronouncementInterpreter.reset_for_new_world()
	ConsequenceEngine.reset_for_new_world()
	AdvisorSystem.reset_for_new_world()
	GameState.civic_api_enabled=false
	GameState.initialize_population_model()
	GameState.settlement_name="Dawngate"
	GameState.settlement_site_committed=true
	GameState.settlement_completed=["Hearth Circle"]
	SettlementModel.ensure_founded()
	GovernmentPeopleSystem.initialize()
	ConsequenceEngine.initialize()
	return String(GameState.player_settlements[0].id)
