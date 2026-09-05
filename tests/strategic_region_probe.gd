extends Node

func _ready()->void:
	_run_shape_audit()
	_run_capture_and_recapture_loop()
	print("STRATEGIC_REGION_PASS regions=",CivilizationSystem.civilizations.size()*CivilizationSystem.STRATEGIC_REGIONS_PER_CIV," occupation_forces=",MilitaryCampaign.occupation_forces.size())
	get_tree().quit()


func _run_shape_audit()->void:
	GameState.reset_for_new_world(112358)
	GameState.settlement_site_committed=true
	MilitaryCampaign.reset_for_new_world()
	CivilizationSystem.reset_for_new_world()
	CivilizationSystem.advance_to_day(3650)
	for civ in CivilizationSystem.civilizations:
		var region_population:=0.0
		for region in civ.strategic_regions: region_population+=float(region.population)
		print("REGION_AUDIT ",String(civ.id)," population=",float(civ.population)," represented=",region_population)
	var errors:=CivilizationSystem.validate_state()
	if not errors.is_empty():
		push_error("STRATEGIC_REGION_FAIL %s" % JSON.stringify(errors))
		get_tree().quit(1)
		return


func _run_capture_and_recapture_loop()->void:
	GameState.reset_for_new_world(778899)
	GameState.ensure_population_total(100_000)
	GameState.settlement_site_committed=true
	GameState.resource_stockpiles={"Food":1_000_000.0,"Timber":100_000.0,"Stone":100_000.0}
	GameState.simulation_metrics.merge({"logistics":0.78,"security":0.72,"cohesion":0.70},true)
	GameState.society_capacities.merge({"institutions":0.68,"logistics":0.78},true)
	MilitaryCampaign.reset_for_new_world()
	CivilizationSystem.reset_for_new_world()
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	civ.player_relation["at_war"]=true
	civ.player_relation["treaty"]="war"
	civ.player_relation["border_tension"]=1.0
	civ["military_population"]=5.0
	civ["military_readiness"]=0.20
	CivilizationSystem.civilizations[0]=civ
	for known_region:Dictionary in civ.strategic_regions:
		CivilizationSystem.city_intelligence.publish("player",CivilizationSystem.city_intelligence.capture("player",String(known_region.id),1.0,0,"test visit","test"),0)
	var target:Dictionary=CivilizationSystem.campaign_targets(String(civ.id))[0]
	MilitaryCampaign.home_army=MilitaryCampaign.simulator.create_formation_force("PLAYER FIELD HOST",[{"id":1,"unit":"line_infantry","weapon":"spear","count":2_000,"authorized_count":2_000,"equipment":2_000,"equipment_required":2_000,"ammunition":0,"ammunition_required":0,"training":0.78,"experience":0.35,"personnel_condition":0.92}],0.88,0.90)
	MilitaryCampaign.next_formation_id=2
	var army_created:Dictionary=MilitaryCampaign.create_field_army(1_700)
	assert(bool(army_created.get("ok",false)))
	MilitaryCampaign.field_armies[0]["location_id"]=String(target.id)
	MilitaryCampaign.field_armies[0]["location_name"]=String(target.name)
	MilitaryCampaign.field_armies[0]["position"]=(target.position as Dictionary).duplicate(true)
	var launched:=MilitaryCampaign.launch_offensive(String(civ.id),String(target.id))
	assert(not launched.has("error"))
	assert(String((MilitaryCampaign.active_engagement.threat as Dictionary).target_region_id)==String(target.id))
	var battle:Dictionary={}
	for _round in 12:
		if MilitaryCampaign.active_engagement.is_empty(): break
		battle=MilitaryCampaign.advance_engagement("push")
	assert(MilitaryCampaign.active_engagement.is_empty())
	var captured:=CivilizationSystem.region_snapshot(String(civ.id),String(target.id))
	assert(String(captured.controller)=="player")
	var occupation:=MilitaryCampaign.occupation_force_for_region(String(civ.id),String(target.id))
	assert(int(occupation.get("troops",0))>0)
	var mobilized_before_reinforcement:=MilitaryCampaign._mobilized_count()
	var field_before_reinforcement:=int(MilitaryCampaign.field_armies[0].troops)
	var home_before_reinforcement:=int(MilitaryCampaign.home_army.troops)
	var reinforcement:=MilitaryCampaign.reinforce_occupation(String(civ.id),String(target.id))
	assert(bool(reinforcement.get("ok",false)))
	assert(int(MilitaryCampaign.field_armies[0].troops)<field_before_reinforcement)
	assert(int(MilitaryCampaign.home_army.troops)==home_before_reinforcement)
	assert(MilitaryCampaign._mobilized_count()==mobilized_before_reinforcement)
	var mobilized_before_evacuation:=MilitaryCampaign._mobilized_count()
	var evacuation:=MilitaryCampaign.evacuate_occupation(String(civ.id),String(target.id))
	assert(bool(evacuation.get("ok",false)))
	assert(MilitaryCampaign.occupation_force_for_region(String(civ.id),String(target.id)).is_empty())
	assert(MilitaryCampaign._mobilized_count()==mobilized_before_evacuation)
	var withdrawal_index:=MilitaryCampaign._field_army_index(int(evacuation.army_id))
	assert(withdrawal_index>=0)
	assert(MilitaryCampaign.disband_field_army(int(evacuation.army_id)).has("error"))
	assert(int(MilitaryCampaign.home_army.troops)==home_before_reinforcement)
	assert(String(MilitaryCampaign.field_armies[withdrawal_index].status)=="moving")
	var restation:=MilitaryCampaign.establish_occupation_force(String(civ.id),captured,float(target.occupation_required),int(MilitaryCampaign.field_armies[0].army_id))
	assert(not restation.has("error"))
	assert(bool((battle.get("strategic_outcome",{}) as Dictionary).get("region_captured",false)))
	assert(bool(CivilizationSystem.campaign_targets(String(civ.id))[1].available))
	assert(CivilizationSystem.validate_state().is_empty())
	assert(MilitaryCampaign.validate_state().is_empty())
	var military_json:=JSON.stringify(MilitaryCampaign.export_state())
	assert(bool(MilitaryCampaign.import_state(JSON.parse_string(military_json)).get("ok",false)))
	MilitaryCampaign.pending_aftermath.clear()
	var live_civ:Dictionary=CivilizationSystem.civilizations[0]
	live_civ.player_relation["last_incident_day"]=-9999
	CivilizationSystem.civilizations[0]=live_civ
	CivilizationSystem._queue_player_incident_if_due(live_civ,live_civ.player_relation,120)
	assert(String(CivilizationSystem.pending_player_incidents[0].target_region_id)==String(target.id))
	GameState.elapsed_days=120.0
	MilitaryCampaign._process_threat_day()
	assert(String(MilitaryCampaign.active_threat.target_region_id)==String(target.id))
	var refused_tribute:=MilitaryCampaign.respond_to_threat("tribute")
	assert(refused_tribute.has("error"))
	assert(not MilitaryCampaign.active_threat.is_empty())
	var defense:=MilitaryCampaign.respond_to_threat("defend")
	assert(not defense.has("error"))
	assert(String(MilitaryCampaign.active_engagement.home_force_kind)=="occupation")
	assert(String(MilitaryCampaign.active_engagement.home_side)=="defender")
	var retreat:=MilitaryCampaign.advance_engagement("retreat")
	assert(not retreat.has("error"))
	assert(String(CivilizationSystem.region_snapshot(String(civ.id),String(target.id)).controller)==String(civ.id))
	assert(MilitaryCampaign.occupation_force_for_region(String(civ.id),String(target.id)).is_empty())
	assert(CivilizationSystem.validate_state().is_empty())
	assert(MilitaryCampaign.validate_state().is_empty())
