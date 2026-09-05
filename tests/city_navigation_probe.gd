extends Node

var failures:Array[String]=[]

func _ready()->void:
	GameState.reset_for_new_world(314159)
	DiscoverySystem.reset_for_new_world()
	ResourceSystem.reset_for_new_world()
	FoodSystem.reset_for_new_world()
	CivilizationSystem.reset_for_new_world()
	GameState.select_founding_focus("provision")
	var terrain:Node=load("res://local_terrain.tscn").instantiate()
	add_child(terrain)
	await get_tree().process_frame
	await get_tree().process_frame
	GameState.settlement_site_committed=true
	GameState.settlement_completed=["Hearth Circle"]
	GameState.settlement_name="First City"
	GameState.settlement_founded_at=terrain.settler_marker.position
	SettlementModel.ensure_founded()
	var primary:Dictionary=SettlementModel.selected_settlement()
	var point:Vector2=primary.position+Vector2(10,4)
	GameState.player_settlements.append({"id":"dawngate","name":"Dawngate","primary":false,"position":point,"population_share":0.25,"founded_day":0})
	GameState.resource_stockpiles["Timber"]=1234.0
	terrain._refresh_city_selector()
	_expect(terrain.settlement_selector.item_count==2,"Dropdown omitted a city")
	terrain._on_city_selected(1)
	await get_tree().create_timer(0.8).timeout
	_expect(GameState.selected_settlement_id=="dawngate","Dropdown did not select Dawngate")
	_expect(Vector2(terrain.camera_target.x,terrain.camera_target.z).distance_to(point)<0.01,"Camera did not reach Dawngate")
	_expect(terrain.camera.size<=6.0,"City selection did not zoom in")
	_expect("FIRST CITY" in terrain._settlement_map_label_text(5.0),"Selecting Dawngate renamed the first city's map label")
	var before:=GameState.resource_stockpiles.duplicate(true)
	terrain._open_materials_panel()
	_expect(terrain.materials_panel.find_child("CityTradeStatus",true,false)!=null,"Material report omitted city trade access")
	_expect(GameState.resource_stockpiles==before,"Opening the report mutated the capital's stores")
	terrain._cycle_material_priority("Stone")
	_expect(not GameState.resource_priorities.has("Stone"),"Dawngate's priority changed the first city")
	_expect(SettlementModel.settlement_record("dawngate").local_resources.resource_priorities.has("Stone"),"Dawngate's priority did not persist")
	terrain._open_provisions_panel()
	var trade_button:=terrain.provisions_panel.find_child("CityTradeStatus",true,false) as Button
	_expect(trade_button!=null and "DAWNGATE" in trade_button.text,"Provisions report identified the wrong city")
	terrain._open_provisions_detail_overlay()
	terrain._open_settlement_dashboard()
	_expect(_panel_text(terrain.settlement_dashboard_panel).contains("DAWNGATE"),"Settlement dashboard identified the wrong city")
	terrain._open_settlement_naming_panel()
	terrain.settlement_name_input.text="Dawngate Harbor"
	terrain._commit_settlement_name()
	_expect(GameState.settlement_name=="First City","Rename overwrote the first city")
	_expect(String(SettlementModel.settlement_record("dawngate").name)=="Dawngate Harbor","Rename did not update the selected city")
	GameState.population_allocations["Construction"]=40
	GameState.population_allocations["Logistics"]=40
	GameState.population_allocations["Crafting"]=20
	var primary_works:=GameState.settlement_completed.duplicate()
	SettlementModel.with_city_resources("dawngate",func()->void:
		GameState.resource_stockpiles["Timber"]=30.0
		GameState.resource_stockpiles["Fiber Plants"]=30.0
		GameState.settlement_projects={"Lean-to Shelters":100.0,"Storage Pits":100.0,"Open Work Area":100.0,"Gathering Yard":100.0}
		terrain._process_settlement_day()
	)
	_expect(GameState.settlement_completed==primary_works,"Local construction changed the capital's buildings")
	_expect(SettlementModel.settlement_record("dawngate").local_resources.settlement_completed.size()>1,"Dawngate could not complete its own funded building")
	_expect(float(SettlementModel.city_resource_snapshot("dawngate").stores.Timber)<30.0,"Local construction did not consume local materials")
	terrain._select_city(String(primary.id))
	await get_tree().create_timer(0.8).timeout
	_expect(GameState.resource_stockpiles==before,"Switching cities changed inventory")
	if failures.is_empty(): print("CITY_NAVIGATION_PROBE PASS")
	else:
		for failure in failures: push_error(failure)
	terrain.queue_free()
	await get_tree().process_frame
	get_tree().quit(0 if failures.is_empty() else 1)

func _panel_text(panel:Node)->String:
	var text:=""
	for label in panel.find_children("*","Label",true,false): text+=label.text+"\n"
	return text

func _expect(condition:bool,message:String)->void:
	if not condition: failures.append(message)
