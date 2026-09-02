extends Node

func _ready()->void:
	GameState.reset_for_new_world(24681357)
	GameState.ensure_population_total(1_000_000_000)
	GameState.settlement_site_committed=true
	GameState.settlement_completed=["Hearth Circle"]
	GameState.resource_stockpiles={"Food":40_000_000_000.0,"Timber":5_000_000_000.0,"Stone":5_000_000_000.0}
	CivilizationSystem.reset_for_new_world()
	assert(CivilizationSystem.civilizations.size()==CivilizationSystem.MAX_RIVAL_CIVILIZATIONS)
	for index in CivilizationSystem.civilizations.size():
		var civ:Dictionary=CivilizationSystem.civilizations[index]
		var scaled_population:=1_000_000_000.0+float(index)*125_000_000.0
		civ["population"]=scaled_population
		civ["food_capacity"]=scaled_population*1.08
		civ["military_population"]=scaled_population*0.06
		civ["cohorts"]=CivilizationSystem._scaled_cohorts(civ.cohorts,scaled_population)
		for region_index in (civ.strategic_regions as Array).size():
			civ.strategic_regions[region_index]["population"]=scaled_population*float(civ.strategic_regions[region_index].population_share)
		CivilizationSystem.civilizations[index]=civ
	CivilizationSystem.advance_to_day(36_500)
	assert(CivilizationSystem.civilizations.size()==CivilizationSystem.MAX_RIVAL_CIVILIZATIONS)
	for civ in CivilizationSystem.civilizations: assert((civ.strategic_regions as Array).size()==CivilizationSystem.STRATEGIC_REGIONS_PER_CIV)
	var ai_wars:=0
	var ai_trade_pairs:=0
	var historical_wars:=0
	var ai_controlled_regions:=0
	for civ in CivilizationSystem.civilizations:
		for region in civ.strategic_regions:
			if String(region.controller)!=String(civ.id) and String(region.controller)!="player": ai_controlled_regions+=1
		for other_id in (civ.relations as Dictionary):
			if String(civ.id)>=String(other_id): continue
			var relation:Dictionary=civ.relations[other_id]
			if bool(relation.get("at_war",false)): ai_wars+=1
			if float(relation.get("trade",0.0))>0.0: ai_trade_pairs+=1
	for event in CivilizationSystem.world_events:
		if String(event.get("domain",""))=="war": historical_wars+=1
	assert(ai_wars+ai_trade_pairs>0)
	assert(historical_wars>0)
	assert(ai_controlled_regions>0)
	assert(CivilizationSystem.world_events.size()<=CivilizationSystem.HISTORY_LIMIT)
	assert(CivilizationSystem.pending_player_incidents.size()<=CivilizationSystem.INCIDENT_LIMIT)
	assert(CivilizationSystem.validate_state().is_empty())
	var selected_index:=0
	for index in CivilizationSystem.civilizations.size():
		if CivilizationSystem._frontline_region_index(CivilizationSystem.civilizations[index])>=0: selected_index=index; break
	var selected:Dictionary=CivilizationSystem.civilizations[selected_index]
	selected.player_relation["opinion"]=0.35
	# Campaign actions require earned direct contact in the live rules. This scale
	# probe establishes that precondition explicitly instead of relying on old
	# omniscient diplomacy.
	selected.player_relation["contact_level"]=2
	selected.player_relation["contact_intelligence"]=1.0
	selected.player_relation["home_location_known"]=true
	selected.player_relation["home_position"]={"x":1250.0,"z":840.0}
	CivilizationSystem.civilizations[selected_index]=selected
	var trade:=CivilizationSystem.conduct_player_action(String(selected.id),"open_trade",true)
	assert(bool(trade.get("ok",false)))
	var war:=CivilizationSystem.conduct_player_action(String(selected.id),"declare_war",true)
	assert(bool(war.get("ok",false)))
	assert(CivilizationSystem.pending_player_incidents.is_empty())
	CivilizationSystem.advance_to_day(36_530)
	assert(not CivilizationSystem.pending_player_incidents.is_empty())
	GameState.elapsed_days=36_500.0
	MilitaryCampaign.reset_for_new_world()
	MilitaryCampaign._process_threat_day()
	assert(String(MilitaryCampaign.active_threat.get("source_civ_id",""))==String(selected.id))
	assert(String((MilitaryCampaign.active_threat.enemy_force as Dictionary).name).contains(String(selected.name)))
	var withdrawal:=MilitaryCampaign.respond_to_threat("withdraw")
	assert(bool(withdrawal.get("resolved",false)))
	var food_after_withdrawal:=float(GameState.resource_stockpiles.get("Food",0.0))
	FoodSystem._sync_total()
	assert(is_equal_approx(float(GameState.resource_stockpiles.get("Food",0.0)),food_after_withdrawal))
	MilitaryCampaign.home_army=MilitaryCampaign.simulator.create_formation_force("PLAYER FIELD HOST",[{"id":1,"unit":"levy","weapon":"improvised","count":1_000_000,"authorized_count":1_000_000,"equipment":1_000_000,"equipment_required":1_000_000}],0.72,0.68)
	var target:Dictionary=CivilizationSystem.campaign_targets(String(selected.id)).filter(func(region:Dictionary)->bool: return bool(region.available))[0]
	var army_created:Dictionary=MilitaryCampaign.create_field_army(750_000)
	assert(bool(army_created.get("ok",false)))
	MilitaryCampaign.field_armies[0]["location_id"]=String(target.id)
	MilitaryCampaign.field_armies[0]["location_name"]=String(target.name)
	var offensive:=MilitaryCampaign.launch_offensive(String(selected.id),String(target.id))
	assert(not offensive.has("error"))
	assert(String((MilitaryCampaign.active_engagement.threat as Dictionary).get("campaign_mode",""))=="offensive")
	var retreat:=MilitaryCampaign.advance_engagement("retreat")
	assert(not retreat.has("error"))
	var competition:=CivilizationSystem.competition_snapshot()
	assert((competition.leaders as Array).size()==CivilizationSystem.MAX_RIVAL_CIVILIZATIONS+1)
	assert(int(competition.player_rank)>=1 and int(competition.player_rank)<=CivilizationSystem.MAX_RIVAL_CIVILIZATIONS+1)
	var exported:=CivilizationSystem.export_state()
	assert(JSON.stringify(exported).length()<250_000)
	assert(bool(CivilizationSystem.import_state(exported).get("ok",false)))
	print("CIVILIZATION_SCALE_PASS rivals=%d regions=%d ai_occupied=%d turns=%d active_ai_wars=%d historical_wars=%d ai_trade_pairs=%d player_rank=%d state_bytes=%d" % [CivilizationSystem.civilizations.size(),CivilizationSystem.MAX_RIVAL_CIVILIZATIONS*CivilizationSystem.STRATEGIC_REGIONS_PER_CIV,ai_controlled_regions,CivilizationSystem.turn_index,ai_wars,historical_wars,ai_trade_pairs,int(competition.player_rank),JSON.stringify(exported).length()])
	get_tree().quit(0)
