extends Node
const SLOT:="release_recovery_qa"
func setup()->void:
	GameState.reset_for_new_world(74017);GameState.civic_api_enabled=false
	GameState.ensure_population_total(200);GameState.settlement_completed=["Hearth Circle"];GameState.settlement_name="Old Home";GameState.settlement_site_committed=true
	CivilizationSystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world();SettlementModel.reset_for_new_world();SettlementModel.ensure_founded()
	FoodSystem.reset_for_new_world();FoodSystem.initialize();FoodSystem.receive_external_food(100000)
	GameState.resource_stockpiles.Timber=1000.0
	CivilizationSystem.set_scout_geography_authority(func(_p:Vector2)->bool:return true)
	CivilizationSystem.set_ground_survey_authority(func(_p:Vector2)->Dictionary:return {"river_distance_km":2.0,"forage":.7,"fertility":.7})
	MilitaryCampaign.recovery.surface_assessor=func(_p:Vector3)->Dictionary:return {"valid":true}
	var civ:Dictionary=CivilizationSystem.civilizations[0];civ.player_relation.at_war=true;civ.player_relation.treaty="war";civ.player_relation.contact_level=2
	MilitaryCampaign._create_civilization_threat({"source_civ_id":civ.id,"source_name":civ.name,"strength":1000,"incident_kind":"campaign"},"defensive")
	assert(MilitaryCampaign.begin_siege().get("ok",false))

func _ready()->void:
	var args:=OS.get_cmdline_user_args()
	var phase:=int(args[0]) if not args.is_empty() else 0
	if phase==0:
		setup()
		assert(MilitaryCampaign.recovery.prepare(20,90).has("ok"))
	else:
		var result:=SaveSystem.load_game(SLOT)
		print("RECOVERY_LOAD phase=",phase," result=",result)
		if result.has("error"):
			print("CIV_VALIDATION=",CivilizationSystem.import_state(SaveSystem._read_payload(SLOT).curated_CivilizationSystem))
			get_tree().quit(1);return
		CivilizationSystem.set_scout_geography_authority(func(_p:Vector2)->bool:return true)
		CivilizationSystem.set_ground_survey_authority(func(_p:Vector2)->Dictionary:return {"river_distance_km":2.0,"forage":.7,"fertility":.7})
		MilitaryCampaign.recovery.surface_assessor=func(_p:Vector3)->Dictionary:return {"valid":true}
	var model=MilitaryCampaign.recovery
	if phase==1:
		assert(int(model.data.preparation.people)==20)
		var seed_value:=GameState.world_seed^int(MilitaryCampaign.active_siege.threat.seed)
		for attempt in 100:
			var rng:=RandomNumberGenerator.new();rng.seed=seed_value^attempt*104729
			if rng.randf()<.7:model.data.attempts=attempt;break
		assert(model.escape("east").get("escaped",false))
		assert(model.capture(String(CivilizationSystem.civilizations[0].id)).has("ok"))
	elif phase==2:
		assert(model.home_unavailable());assert(int(model.data.remnant.people)==20)
		model.advance(3);assert(model.seek_site("east").has("ok"));model.advance(7)
		assert(model.data.remnant.is_empty());assert(not model.home_unavailable())
	elif phase==3:
		assert(model.data.remnant.is_empty());assert(not model.home_unavailable())
		assert(GameState.population_total==200)
		assert(SettlementModel.validate_settlement_network().is_empty())
		var terrain:=preload("res://local_terrain.tscn").instantiate()
		add_child(terrain);terrain._set_game_speed(0)
		assert(GameState.population_total==200);assert(model.has_active_occupation())
		DirAccess.remove_absolute(SaveSystem.slot_path(SLOT))
	else:pass
	if phase<3:
		print("PRE_SAVE_VALIDATION=",CivilizationSystem.validate_state())
		assert(SaveSystem.save_game(SLOT).has("ok"))
	print("RECOVERY_FRESH_PROCESS_PASS phase=",phase)
	get_tree().quit()
