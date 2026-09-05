extends Node
## Focused regression probe for evidence-driven foreign exploration. It checks
## that scouts change routes after homecoming, distant rumors cannot precede
## physical information reach, and indirect traces are not promoted to contact.

var failures:Array[String]=[]


func _ready()->void:
	GameState.reset_for_new_world(112358)
	GameState.settlement_site_committed=true
	GameState.settlement_founded_day=0
	GameState.population_exact=10_000.0
	CivilizationSystem.reset_for_new_world()
	CivilizationSystem.register_player_origin(Vector2.ZERO)
	_hide_all_contacts()
	var initial_save_bytes:=JSON.stringify(CivilizationSystem.export_state()).to_utf8_buffer().size()
	print("FOREIGN_EXPLORATION_SAVE_BYTES %d" % initial_save_bytes)
	_expect(initial_save_bytes<250_000,"dynamic scouting exceeded the bounded civilization save-size class")
	_probe_route_replacement()
	_probe_reachable_rumor()
	_probe_returned_trace()
	_probe_v9_save_migration()
	_probe_three_centuries_of_emergent_search()
	_finish()


func _hide_all_contacts()->void:
	for index in CivilizationSystem.civilizations.size():
		var civ:Dictionary=CivilizationSystem.civilizations[index]
		civ.player_relation["contact_level"]=0
		civ.player_relation["contact_intelligence"]=0.0
		civ.player_relation["met_day"]=-1
		civ.player_relation["rival_contact_level"]=0
		civ.player_relation["rival_player_intelligence"]=0.0
		civ.player_relation.erase("rival_player_trace_confidence")
		civ.player_relation.erase("rival_player_trace_center")
		civ.player_relation.erase("rival_player_trace_radius_km")
		CivilizationSystem.civilizations[index]=civ


func _first_scout_index()->int:
	for index in CivilizationSystem.foreign_formations.size():
		if String(CivilizationSystem.foreign_formations[index].get("kind",""))=="scout": return index
	return -1


func _probe_route_replacement()->void:
	var scout_index:=_first_scout_index()
	_expect(scout_index>=0,"world has no foreign scout")
	if scout_index<0: return
	var scout:Dictionary=CivilizationSystem.foreign_formations[scout_index]
	var civ_index:=CivilizationSystem._civilization_index(String(scout.civ_id))
	var civ:Dictionary=CivilizationSystem.civilizations[civ_index]
	civ["world_reach"]=0.52
	civ["logistics"]=0.42
	civ["knowledge"]=0.38
	CivilizationSystem.civilizations[civ_index]=civ
	var home:=CivilizationSystem._civilization_world_position(civ)
	scout["point_a"]=home
	scout["point_b"]=home+Vector2(100.0,0.0)
	scout["depart_day"]=0
	scout["leg_days"]=10.0
	scout["last_report_cycle"]=0
	var sequence_before:=int(scout.search_sequence)
	CivilizationSystem.foreign_formations[scout_index]=scout
	CivilizationSystem._process_foreign_scout_reports(20)
	var replacement:Dictionary=CivilizationSystem.foreign_formations[scout_index]
	_expect(int(replacement.search_sequence)==sequence_before+1,"returned scout repeated its old search sequence")
	_expect(Vector2(replacement.point_a).distance_to(home)<0.01,"replacement scout did not depart from home")
	_expect(Vector2(replacement.point_a).distance_to(Vector2(replacement.point_b))>1000.0,"mature world reach did not expand the next mission")


func _probe_reachable_rumor()->void:
	var civ:Dictionary=CivilizationSystem.civilizations[1]
	civ["position"]=Vector2(0.20,0.0)
	civ["world_reach"]=0.0
	civ["logistics"]=0.12
	civ["institutions"]=0.12
	CivilizationSystem.civilizations[1]=civ
	CivilizationSystem._process_foreign_player_rumors(30)
	_expect(float(CivilizationSystem.civilizations[1].player_relation.get("rival_player_trace_confidence",0.0))==0.0,"an unreachable civilization received a player rumor")
	civ=CivilizationSystem.civilizations[1]
	civ["world_reach"]=0.62
	civ["logistics"]=0.58
	civ["institutions"]=0.52
	civ["diplomacy"]=0.55
	CivilizationSystem.civilizations[1]=civ
	for day in range(60,12001,30):
		CivilizationSystem._process_foreign_player_rumors(day)
		if float(CivilizationSystem.civilizations[1].player_relation.get("rival_player_trace_confidence",0.0))>0.0: break
	var relation:Dictionary=CivilizationSystem.civilizations[1].player_relation
	_expect(float(relation.get("rival_player_trace_confidence",0.0))>0.0,"reachable human networks never produced a coarse lead")
	_expect(int(relation.get("rival_contact_level",0))==1,"a rumor did not remain below direct contact")
	_expect(int(relation.get("rival_met_day",-1))==-1,"a rumor fabricated a meeting")
	_expect(int(relation.get("contact_level",0))==0,"foreign hearsay leaked into player knowledge")


func _probe_returned_trace()->void:
	var scout_index:=_first_scout_index()
	var scout:Dictionary=CivilizationSystem.foreign_formations[scout_index]
	var civ_index:=CivilizationSystem._civilization_index(String(scout.civ_id))
	var civ:Dictionary=CivilizationSystem.civilizations[civ_index]
	var relation:Dictionary=civ.player_relation
	relation["rival_contact_level"]=0
	relation["rival_player_intelligence"]=0.0
	relation.erase("rival_player_trace_confidence")
	relation.erase("rival_player_trace_center")
	relation.erase("rival_player_trace_radius_km")
	civ["player_relation"]=relation
	CivilizationSystem.civilizations[civ_index]=civ
	var signal_radius:=CivilizationSystem._player_settlement_signal_radius(40)
	var direct_radius:=CivilizationSystem._foreign_scout_direct_contact_radius(40)
	var trace_distance:=(signal_radius+direct_radius)*0.5
	scout["point_a"]=Vector2(-120.0,trace_distance)
	scout["point_b"]=Vector2(120.0,trace_distance)
	scout["depart_day"]=20
	scout["leg_days"]=10.0
	scout["last_report_cycle"]=0
	CivilizationSystem.foreign_formations[scout_index]=scout
	CivilizationSystem._process_foreign_scout_reports(39)
	_expect(float(CivilizationSystem.civilizations[civ_index].player_relation.get("rival_player_trace_confidence",0.0))==0.0,"outbound observations reached home before the party")
	CivilizationSystem._process_foreign_scout_reports(40)
	relation=CivilizationSystem.civilizations[civ_index].player_relation
	_expect(float(relation.get("rival_player_trace_confidence",0.0))>0.0,"returned physical traces produced no investigation lead")
	_expect(int(relation.get("rival_contact_level",0))==1,"indirect settlement traces became direct contact")
	_expect(int(relation.get("rival_met_day",-1))==-1,"indirect settlement traces fabricated a meeting")
	var validation_errors:=CivilizationSystem.validate_state()
	_expect(validation_errors.is_empty(),"foreign exploration state validation failed: %s" % str(validation_errors))


func _probe_v9_save_migration()->void:
	var legacy:=CivilizationSystem.export_state()
	legacy["version"]=9
	for formation in legacy.foreign_formations:
		if String(formation.get("kind",""))=="scout": formation.erase("search_sequence")
	var result:Dictionary=CivilizationSystem.import_state(legacy)
	_expect(bool(result.get("ok",false)),"v9 fixed-route save did not migrate: %s" % str(result))
	for formation in CivilizationSystem.foreign_formations:
		if String(formation.get("kind",""))=="scout":
			_expect(int(formation.get("search_sequence",-1))>=0,"migrated scout has no dynamic search sequence")


func _probe_three_centuries_of_emergent_search()->void:
	GameState.reset_for_new_world(1789860055)
	GameState.settlement_site_committed=true
	GameState.settlement_founded_day=0
	GameState.population_exact=800.0
	CivilizationSystem.reset_for_new_world()
	CivilizationSystem.register_player_origin(Vector2(15.0,20.0))
	_hide_all_contacts()
	var first_rumor_day:=-1
	var first_contact_day:=-1
	for day in range(30,302*365+1,30):
		CivilizationSystem.last_turn_day=day
		for index in CivilizationSystem.civilizations.size():
			var civ:Dictionary=CivilizationSystem.civilizations[index]
			if bool(civ.get("alive",true)): CivilizationSystem.civilizations[index]=CivilizationSystem._advance_civilization(civ)
		CivilizationSystem._process_foreign_player_rumors(day)
		CivilizationSystem._process_foreign_scout_reports(day)
		for civ in CivilizationSystem.civilizations:
			var relation:Dictionary=civ.player_relation
			if first_rumor_day<0 and int(relation.get("rival_contact_level",0))>=1: first_rumor_day=day
			if first_contact_day<0 and int(relation.get("rival_contact_level",0))>=2: first_contact_day=day
		if day==10*365:
			_expect(first_contact_day<0,"planetary civilization was found implausibly within the first decade")
	var foreign_contacts:=0
	for civ in CivilizationSystem.civilizations:
		if int(civ.player_relation.get("rival_contact_level",0))>=2: foreign_contacts+=1
	print("FOREIGN_EXPLORATION_TIMELINE first_rumor_day=%d first_contact_day=%d contacts_at_year_302=%d" % [first_rumor_day,first_contact_day,foreign_contacts])
	_expect(first_rumor_day>0,"three centuries produced no physically reachable foreign rumors")
	_expect(first_contact_day>first_rumor_day,"direct contact did not require investigation after rumor")
	_expect(foreign_contacts>0,"three centuries of growing exploration still could not find a settled player")


func _expect(condition:bool,message:String)->void:
	if not condition:
		failures.append(message)
		push_error("FOREIGN_EXPLORATION_PROBE %s" % message)


func _finish()->void:
	if failures.is_empty():
		print("FOREIGN_EXPLORATION_PROBE PASS")
		get_tree().quit(0)
	else:
		print("FOREIGN_EXPLORATION_PROBE FAIL (%d)" % failures.size())
		get_tree().quit(1)
