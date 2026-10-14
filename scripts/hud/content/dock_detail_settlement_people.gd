extends "res://scripts/hud/content/dock_content_base.gd"
## Detail dock for one settlement's bounded pool of real potential leaders.
## These people remain part of the aggregate population, but keep their own age,
## lifespan, skills, traits, appointments, experience, and relationships.

var settlement_id:=""


func _init(terrain_node:Node,hud_node:Control,target_settlement_id:String)->void:
	super._init(terrain_node,hud_node)
	settlement_id=target_settlement_id
	GovernmentPeopleSystem.initialize()


func _settlement()->Dictionary:
	return SettlementModel.settlement_by_id(settlement_id)


func meta()->Dictionary:
	var settlement:=_settlement()
	return {
		"eyebrow":"Settlement · local government",
		"title":"Leadership of %s" % String(settlement.get("name","Settlement")),
		"subtabs":[],
	}


func tab(_sub:int)->Dictionary:
	var settlement:=_settlement()
	var leader:=GovernmentPeopleSystem.settlement_leader(settlement_id)
	var title:=GovernmentPeopleSystem.settlement_leader_title()
	var structure:=GovernmentPeopleSystem.structure_snapshot()
	var combined_founding_office:=int(structure.get("stage",0))==0 and GameState.player_settlements.size()==1
	# There is only one office at founding scale, but the player must still be
	# able to choose which real person carries it.
	var candidates:Array[Dictionary]=GovernmentPeopleSystem.candidates_for_office("SettlementLeader",settlement_id,6,false)
	var kpis:Array=[
		{"label":"LOCAL OFFICE","value":title.substr(0,16),"delta":"evolves","accent":Tokens.GOLD,"tip":"This title changes as the civilization's government changes."},
		{"label":"HOLDER","value":String(leader.get("name","vacant")).substr(0,15),"delta":"age %d" % int(leader.get("age",0)) if not leader.is_empty() else "","accent":Tokens.GREEN if not leader.is_empty() else Tokens.RED,"tip":"The named person currently responsible for this settlement."},
		{"label":"KNOWN PEOPLE","value":str(int(structure.get("living_people",0))),"delta":"max %d" % int(structure.get("pool_limit",96)),"accent":Tokens.BLUE,"tip":"A bounded governing cast; the rest of the population remains aggregate."},
		{"label":"LOCAL POP.","value":str(int(settlement.get("population",0))),"delta":String(settlement.get("classification","settlement")),"accent":Tokens.TEAL,"tip":"The settlement population this person is expected to coordinate."},
	]
	var brief:Dictionary={
		"tone":"info" if not leader.is_empty() else "warn",
		"title":"%s currently serves as %s" % [String(leader.get("name","No one")),title] if not leader.is_empty() else "Appoint a local leader",
		"why":("Age %d. " % int(leader.get("age",0)) if not leader.is_empty() else "")+("The founding leader also looks after the only settlement. Choose who carries this responsibility." if combined_founding_office else "The local leader directs work toward water, food, shelter, defense and development. Choose by their record and reputation."),
	}
	var blocks:Array=[]
	for candidate_variant in candidates:
		var candidate:Dictionary=candidate_variant
		var assessment:=GovernmentPeopleSystem.appointment_assessment(candidate,"SettlementLeader")
		var is_incumbent:=int(candidate.get("person_id",0))==int(leader.get("person_id",-1))
		var candidate_blocks:Array=[{"type":"rows","items":[{
			"name":String(candidate.get("background","Settlement resident")),
			"detail":"%s · %s\nKNOWN FOR · %s\nDOUBT · %s" % [String((candidate.get("traits",[]) as Array)[0]) if not (candidate.get("traits",[]) as Array).is_empty() else "Unrecorded",String((candidate.get("traits",[]) as Array)[1]) if (candidate.get("traits",[]) as Array).size()>1 else "",String(assessment.known_for),String(assessment.public_concern)],
			"value":"SERVING" if is_incumbent else "%s · %s" % [String(assessment.record),String(assessment.standing)],
			"value_color":Tokens.GREEN if is_incumbent else Tokens.BODY_2,"accent":Tokens.GREEN if is_incumbent else Tokens.BLUE,
			"tip":"A partial local reputation, not a forecast. Their real strengths and limits emerge through service.",
		}]}]
		candidate_blocks.append({"type":"actions","items":[{
			"label":"KEEP IN OFFICE" if is_incumbent else "APPOINT %s" % String(candidate.get("name","THIS PERSON")).split(" ")[0].to_upper(),
			"sub":("founding leader and %s" % title) if combined_founding_office else "%s of %s" % [title,String(settlement.get("name","the settlement"))],"primary":false,"disabled":is_incumbent,
			"on_press":_appoint.bind(int(candidate.get("person_id",0)),combined_founding_office),"tip":"Assign this actual person to the one combined founding office." if combined_founding_office else "Assign this actual person to manage the selected settlement.",
		}]})
		blocks.append({"type":"frame","heading":"%s · age %d" % [String(candidate.get("name","Unknown")),int(candidate.get("age",0))],"blocks":candidate_blocks})
	if blocks.is_empty(): blocks.append({"type":"text","text":"No living eligible person is recorded here. The bounded pool will recruit recognizable adults from the aggregate population as government grows."})
	blocks.append({"type":"text","heading":"People known to the council","text":"The council follows %d people by name, with room to follow up to %d as government grows. Other residents are counted among the population." % [int(structure.get("living_people",0)),int(structure.get("pool_limit",96))]})
	var readings:Array=[kpis[3],kpis[2]]
	for reading:Dictionary in readings:reading["glance"]=true
	return {"kpis":readings,"brief":brief,"blocks":blocks}


func _appoint(person_id:int,combined_founding_office:bool=false)->void:
	var result:Dictionary
	if combined_founding_office:
		var appointed:=GovernmentPeopleSystem.mark_central_appointment(person_id,"Steward")
		result={"ok":not appointed.is_empty(),"leader":appointed,"title":GovernmentPeopleSystem.settlement_leader_title(),"reason":"That person could not take the founding office."}
	else:
		result=GovernmentPeopleSystem.assign_settlement_leader(settlement_id,person_id)
	terrain._report_military_action({"message":"%s appointed %s of %s." % [String((result.get("leader",{}) as Dictionary).get("name","A local leader")),String(result.get("title","leader")),String(_settlement().get("name","the settlement"))] if bool(result.get("ok",false)) else String(result.get("reason","Appointment failed."))})
	hud.live_refresh_dock()


func signature()->Array:
	var leader:=GovernmentPeopleSystem.settlement_leader(settlement_id)
	return [settlement_id,GovernmentPeopleSystem.revision,GameState.settlement_network_revision,int(leader.get("person_id",0)),int(GameState.elapsed_days/30.0)]
