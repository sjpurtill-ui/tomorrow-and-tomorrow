extends RefCounted
## A representative diplomatic state for tests and court captures: three
## peoples met and located, a three-people league, a protection treaty, a
## marriage and a debt, a called-upon promise, relief on the road, and a
## handful of dated dealings.

static func build_fixture()->String:
	GameState.reset_for_new_world(424242)
	MilitaryCampaign.reset_for_new_world()
	SettlementModel.reset_for_new_world(); GovernmentPeopleSystem.reset_for_new_world()
	CivilizationSystem.reset_for_new_world(); CivilizationSystem.initialize()
	ForeignDiplomacy.reset_for_new_world(); ForeignDiplomacy.ensure()
	GameState.civic_api_enabled=false
	GameState.initialize_population_model(); GameState.settlement_site_committed=true
	GameState.settlement_completed=["Hearth Circle"]
	SettlementModel.ensure_founded(); GovernmentPeopleSystem.initialize()
	FoodSystem.reset_for_new_world(); FoodSystem.initialize(); FoodSystem.receive_external_food(10000)
	var ids:Array[String]=[]
	var opinions:=[.55,.35,-.3]
	for index:int in 3:
		var civ:Dictionary=CivilizationSystem.civilizations[index]
		civ.player_relation.contact_level=2; civ.player_relation.home_location_known=true; civ.player_relation.opinion=opinions[index]
		civ.player_relation.home_position={"x":CivilizationSystem.player_world_origin.x+1+index,"z":CivilizationSystem.player_world_origin.y}
		ids.append(String(civ.id))
	for civ:Dictionary in CivilizationSystem.civilizations:
		for relation:Dictionary in civ.relations.values(): relation.opinion=.4
	var model=ForeignDiplomacy.commitments
	# Dated in a later year without moving the clock: advancing elapsed_days
	# here would make every daily system catch up thousands of days.
	var start:=15000
	for id:String in ids: ForeignDiplomacy.leader(id)
	model.state.pacts[ids[0]]={"since":start,"trigger":"defensive_siege","obligation":model.OBLIGATION}
	model.state.factions.append({"id":"league_1","name":"League of %s" % String(CivilizationSystem.civilizations[0].name),"members":["player",ids[0],ids[1]],
		"joined":{"player":start+120,ids[0]:start+120,ids[1]:start+260},"goal":"defense","since":start+120,
		"votes":{ids[0]:{"accept":true,"reason":"Our dealings give this proposal a basis."},ids[1]:{"accept":true,"reason":"We judge the candidate by our own relationship with them."}},"obligation":model.OBLIGATION})
	model.state.obligations.append({"donor":"player","beneficiary":ids[1],"attacker":ids[2],"siege_id":"war:fixture","day":start+390,"status":"requested"})
	model.state.relief.append({"id":"relief_9","siege_id":"siege_fixture","donor_civ_id":ids[0],"beneficiary_id":"player","troops":24,"food":24*30*.55,"travel_food":24*6*.55,"travel_days":6,"due_day":start+410,"status":"outbound","survivors":24,"unused_food":0.0})
	model.state.history=[
		{"day":start+400,"text":"Day %d: 60.0 Food reached %s in response to their call. Food support has been delivered; no military force was promised or created by this shipment." % [start+400,ids[1]]},
		{"day":start+390,"text":"%s requests defensive relief from %s under an existing promise." % [ids[1],"player"]},
		{"day":start+260,"text":"The candidate and existing members consent. %s joins the league." % String(CivilizationSystem.civilizations[1].name)},
		{"day":start+120,"text":"Our league is founded. Each member keeps its leader, people and army. New members and policy changes require consultation and unanimous consent."},
		{"day":start,"text":"Mutual protection is ratified. It covers defensive sieges beginning after today, subject to real forces, provisions and access; it does not authorize offensive wars."}]
	var rivals:=preload("res://scripts/rival_rulers.gd")
	rivals.bond(ids[0],"inlaw","the marriage of Asha to one of your people",1<<30,{"heir":"Asha"})
	rivals.debt(ids[1],"them","Food",40,300,"the food you lent us in the thin winter")
	rivals.grudge(ids[2],"the hunters you turned back at the ford",.6,"fixture")
	return ids[0]
