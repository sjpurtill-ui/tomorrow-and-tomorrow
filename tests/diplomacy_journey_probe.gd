extends "res://tests/focused_journey_probe.gd"
func _ready()->void:
	assert(OS.get_user_data_dir().ends_with("TomorrowAndTomorrow_FocusedJourney_Test"))
	GameState.reset_for_new_world(424242);GameState.civic_api_enabled=false
	SettlementModel.reset_for_new_world();GovernmentPeopleSystem.reset_for_new_world()
	CivilizationSystem.reset_for_new_world();CivilizationSystem.initialize();ForeignDiplomacy.reset_for_new_world();ForeignDiplomacy.ensure()
	GameState.initialize_population_model();GameState.settlement_site_committed=true;GameState.settlement_completed=["Hearth Circle"]
	SettlementModel.ensure_founded();GovernmentPeopleSystem.initialize()
	FoodSystem.reset_for_new_world();FoodSystem.initialize();FoodSystem.receive_external_food(100000);GameState.resource_stockpiles.Timber=100
	var civ:Dictionary=CivilizationSystem.civilizations[0];var id:=String(civ.id)
	civ.player_relation.contact_level=2;civ.player_relation.opinion=.5;civ.player_relation.home_location_known=true
	civ.player_relation.home_position={"x":CivilizationSystem.player_world_origin.x+1,"z":CivilizationSystem.player_world_origin.y}
	ForeignDiplomacy.leader(id).audience_day=0
	ForeignDialogue._append(id,"user","What could we build together?")
	ForeignDialogue.accept(id,{"reply":"Let us improve the routes between our people. Review a shared contribution before sending your envoys.","accord":"routes","tone":"equals","generous":false})
	get_window().content_scale_size=Vector2i.ZERO
	for size in [Vector2i(1280,900),Vector2i(800,600)]:
		get_window().size=size;ForeignDiplomacy.open(id);await frames();hud=ForeignDiplomacy.panel
		var timber:=float(GameState.resource_stockpiles.Timber);var food:=FoodSystem.total_stored()
		await capture("diplomacy-conversation-%d"%size.x)
		await click_label("REVIEW PROPOSED TERMS");await capture("diplomacy-terms-%d"%size.x)
		assert(GameState.resource_stockpiles.Timber==timber and FoodSystem.total_stored()==food)
		assert(CivilizationSystem.diplomatic_mission.is_empty())
		await click_control(hud.generous)
		assert(hud.generous.button_pressed and "ON" in hud.generous.text and "RESERVED: 12 Timber" in hud.costs.text)
		await capture("diplomacy-larger-offer-%d"%size.x)
		await click_control(hud.generous)
		assert(not hud.generous.button_pressed and "OFF" in hud.generous.text and "RESERVED: 4 Timber" in hud.costs.text)
		assert(GameState.resource_stockpiles.Timber==timber and FoodSystem.total_stored()==food)
		await click_label("LEADER & RECORD");await capture("diplomacy-record-%d"%size.x)
		await click_label("OFFER TERMS")
		if size.x==800:
			var quote:=CivilizationSystem.diplomatic_mission_quote(id,"","leader_parley")
			var forecast:=ForeignDiplomacy.forecast(id,hud.selected_accord(),hud.selected_tone(),false)
			assert(not hud.submit.disabled)
			await click_control(hud.submit)
			assert(not CivilizationSystem.diplomatic_mission.is_empty())
			assert(is_equal_approx(float(GameState.resource_stockpiles.Timber),timber-float(forecast.cost)))
			assert(is_equal_approx(FoodSystem.total_stored(),food-float(quote.provisions)))
			assert(ForeignDiplomacy.leader(id).accord.is_empty())
			assert(hud.submit.disabled)
			await capture("diplomacy-sent-small")
		else:hud.queue_free();await frames()
	print("DIPLOMACY_JOURNEY_PASS focused conversation/review/record at two sizes; review spends nothing, real envoy departure reserves offer and food, no instant agreement")
	get_tree().quit()
