extends Node
var failures:Array[String]=[]
func check(ok:bool,message:String)->void:
	if not ok: failures.append(message); push_error(message)
func _ready()->void:
	GameState.reset_for_new_world(424242)
	CivilizationSystem.reset_for_new_world(); CivilizationSystem.initialize()
	FoodSystem.reset_for_new_world(); FoodSystem.initialize()
	FoodSystem.receive_external_food(1000)
	GameState.resource_stockpiles.Timber=100
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	var id:String=civ.id
	check(ForeignDiplomacy.leader(id).is_empty(),"Hidden leader leaked")
	civ.player_relation.contact_level=2
	civ.player_relation.home_location_known=true
	civ.player_relation.home_position={"x":CivilizationSystem.player_world_origin.x+1,"z":CivilizationSystem.player_world_origin.y}
	civ.player_relation.opinion=.1; civ.player_relation.border_tension=0
	var p:=ForeignDiplomacy.leader(id); p.temperament="Bridge-builder"
	var before:float=GameState.resource_stockpiles.Timber
	check(not ForeignDialogue.accept(id,{"reply":"Let us exchange teachers.","accord":"exchange","tone":"equals","generous":false}),"Dialogue opened before any envoy exchange")
	check(CivilizationSystem.diplomatic_mission.is_empty() and GameState.resource_stockpiles.Timber==before,"Conversation enacted proposal")
	check(not ForeignDialogue.accept(id,{"reply":"Invent resources","accord":"spawn_gold","tone":"equals","generous":false}),"Invalid dialogue accepted")
	check(ForeignDiplomacy.send(id,"exchange","equals").get("ok",false),"Envoys failed to leave")
	check(GameState.resource_stockpiles.Timber==96 and p.accord.is_empty(),"Departure applied accord or wrong cost")
	check(ForeignDiplomacy.resolve(id).has("error"),"Remote answer arrived early")
	check(ForeignDiplomacy.send(id,"exchange","equals").has("error") and GameState.resource_stockpiles.Timber==96,"Duplicate mission charged materials")
	GameState.elapsed_days=int(CivilizationSystem.diplomatic_mission.return_day)
	CivilizationSystem._process_diplomatic_mission(int(GameState.elapsed_days))
	check(not p.accord.is_empty() and is_equal_approx(ForeignDiplomacy.multiplier("knowledge"),1.12),"Returned agreement has no effect")
	check(CivilizationSystem.diplomatic_mission.is_empty(),"Returned mission retained")
	check(ForeignDialogue.accept(id,{"reply":"We can discuss what comes next.","accord":"","tone":"equals","generous":false}),"Returned envoys did not enable ongoing dialogue")
	var saved:=ForeignDiplomacy.export_state()
	check(ForeignDiplomacy.import_state(JSON.parse_string(JSON.stringify(saved))).get("ok",false),"Leader state failed JSON roundtrip")
	p=ForeignDiplomacy.leader(id)
	civ.player_relation.at_war=true
	ForeignDiplomacy.advance(int(GameState.elapsed_days)+1)
	check(p.accord.is_empty() and float(p.trust)<0,"War did not break cooperation")
	# A separate negotiation exercises counteroffers and refunded escrow.
	civ.player_relation.at_war=false; p.next_day=0; p.trust=0; p.resolved=1
	civ.player_relation.opinion=0; civ.strategy="commerce"
	check(ForeignDiplomacy.send(id,"exchange","honor").get("ok",false),"Second mission blocked")
	GameState.elapsed_days=int(CivilizationSystem.diplomatic_mission.return_day)
	CivilizationSystem._process_diplomatic_mission(int(GameState.elapsed_days))
	check(not p.counter.is_empty() and GameState.resource_stockpiles.Timber==96,"Counteroffer lost refund")
	check(ForeignDiplomacy.send(id,"exchange","honor",true).get("ok",false),"Revised terms rejected")
	GameState.elapsed_days=int(CivilizationSystem.diplomatic_mission.return_day)
	CivilizationSystem._process_diplomatic_mission(int(GameState.elapsed_days))
	check(not p.accord.is_empty() and is_equal_approx(float(p.accord.bonus),.08) and GameState.resource_stockpiles.Timber==84,"Counteroffer acceptance ignored terms")
	var state:=ForeignDiplomacy.export_state(); var bad:=state.duplicate(true); bad.leaders[id].trust=INF
	check(ForeignDiplomacy.import_state(bad).has("error") and ForeignDiplomacy.export_state()==state,"Invalid import mutated leaders")
	print("FOREIGN_DIPLOMACY "+("PASS: hidden contacts, draft-only dialogue, envoy travel, escrow, refusal/counteroffers, commitments, war and saves" if failures.is_empty() else "FAIL"))
	get_tree().quit(0 if failures.is_empty() else 1)
