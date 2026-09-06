extends "res://tests/focused_journey_probe.gd"
func _ready()->void:
	assert(OS.get_user_data_dir().ends_with("TomorrowAndTomorrow_FocusedJourney_Test"))
	GameState.reset_for_new_world(551188);GameState.civic_api_enabled=false
	DiscoverySystem.reset_for_new_world();ProgressionSystem.reset_for_new_world();ResourceSystem.reset_for_new_world();FoodSystem.reset_for_new_world();ConsequenceEngine.reset_for_new_world();CivilizationSystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world()
	GameState.select_founding_focus("provision");PeopleDirection.choose(String(PeopleDirection.AMBITIONS.keys()[0]))
	GameState.settlement_site_committed=true;GameState.settlement_completed=["Hearth Circle"];SettlementModel.ensure_founded()
	terrain=preload("res://local_terrain.tscn").instantiate();add_child(terrain);terrain._set_game_speed(0);await frames();hud=terrain.hud
	get_window().content_scale_size=Vector2i.ZERO;get_window().size=Vector2i(1280,900);await frames()
	for id:String in ["bow_craft","joinery"]:GameState.known_discoveries.append(id);GameState.discovery_adoption[id]=1.0
	GameState.resource_stockpiles.Timber=1000.0;GameState.resource_stockpiles["Fiber Plants"]=1000.0;GameState.resource_stockpiles.Stone=1000.0
	GameState.population_allocations.Crafting=10
	get_window().size=Vector2i(800,600);await frames()
	hud.open_dock("military",3);await frames();await click_label("MAKE AMMUNITION");await click_label("ARROWS");await capture("arrows-order-small")
	var arrows:=int(MilitaryCampaign.military_consumables.get("arrows",0))
	await click_label("MAKE 5 ARROWS")
	assert(int(MilitaryCampaign.military_consumables.get("arrows",0))==arrows)
	for day in 2000:
		if MilitaryCampaign.equipment_queue.is_empty():break
		MilitaryCampaign._process_equipment_production_day()
	assert(MilitaryCampaign.equipment_queue.is_empty())
	assert(int(MilitaryCampaign.military_consumables.arrows)==arrows+5)
	hud.open_dock("military",3);await frames();await click_label("WORKSHOP & TRANSPORT");await click_label("BUILD CARTS");await click_label("1 CART");await capture("cart-order-small")
	var carts:=float(GameState.resource_stockpiles.get("Transport Carts",0))
	await click_label("MAKE 1 CART")
	assert(float(GameState.resource_stockpiles.get("Transport Carts",0))==carts)
	for day in 2000:
		if MilitaryCampaign.equipment_queue.is_empty():break
		MilitaryCampaign._process_equipment_production_day()
	assert(MilitaryCampaign.equipment_queue.is_empty())
	assert(float(GameState.resource_stockpiles["Transport Carts"])==carts+1)
	hud.open_dock("military",3);await frames();await click_label("WORKSHOP & TRANSPORT");await capture("cart-finished-small")
	MilitaryCampaign.damaged_equipment.improvised=2;hud.request_immediate_dock_refresh();await frames()
	await click_label("REPAIR IMPROVISED");await capture("repair-order-small");await click_label("REPAIR 1 SET")
	assert(int(MilitaryCampaign.damaged_equipment.improvised)==1)
	print("SUPPLY_JOURNEY_PASS real ammo/cart orders finish through production work, correct cart stock, repair review and actual reservation")
	get_tree().quit()
