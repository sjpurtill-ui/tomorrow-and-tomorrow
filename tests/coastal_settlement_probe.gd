extends Node

var failures:=PackedStringArray()

func _ready()->void:
	GameState.reset_for_new_world(704221)
	GameState.initialize_population_model()
	GameState.settlement_completed=["Hearth Circle"]
	GameState.settlement_site_committed=true
	GameState.settlement_founded_at=Vector3(12.0,0.0,-8.0)
	GameState.elapsed_days=18.0
	SettlementModel.ensure_founded()
	var settlement_id:=String(GameState.player_settlements[0].id)
	GameState.province_terrain="Plains"
	SettlementModel.set_settlement_territory_context(settlement_id,{"terrain_permeability":0.72,"water_access":0.4,"work_access":0.5,"travel_access":0.5,"shoreline_access":0.0})
	var inland:Dictionary=SettlementModel.settlement_network_snapshot().settlements[0]
	var inland_support:=float(inland.territory_drivers.support)
	var inland_radius:=float(inland.claim_radius_km)
	var resources_before:=GameState.resource_stockpiles.duplicate(true)
	var deposits_before:=GameState.resource_deposits.duplicate(true)
	SettlementModel.set_settlement_territory_context(settlement_id,{"shoreline_access":0.82,"marine_productivity":0.72,"salt_opportunity":0.55,"storm_exposure":0.64,"erosion_exposure":0.46,"open_water_exposure":0.58})
	var coastal:Dictionary=SettlementModel.settlement_network_snapshot().settlements[0]
	var profile:Dictionary=coastal.intrinsic
	_expect(bool(profile.coastal),"coastal site was not recognized")
	_expect(float(profile.early_food_factor)>1.0 and float(profile.early_food_factor)<=1.08,"early coastal food escaped its modest cap")
	_expect(float(profile.foraging_factor)>1.0 and float(profile.foraging_factor)<=1.06,"coastal foraging escaped its modest cap")
	_expect(float(profile.marine_opportunity)>0.0 and float(profile.salt_opportunity)>0.0,"coastal opportunities were absent")
	_expect(float(profile.waterborne_access_potential)>0.0 and float(profile.waterborne_access_potential)<=0.42,"waterborne potential was missing or unbounded")
	_expect(float(profile.maintenance_factor)>1.0 and float(coastal.territory_drivers.support)<inland_support and float(coastal.claim_radius_km)<inland_radius,"storm and erosion exposure did not create a counterweight")
	_expect(int(profile.runtime_people_entities)==0 and bool(profile.bounded),"coastal state created unbounded runtime representation")
	_expect(GameState.resource_stockpiles==resources_before and GameState.resource_deposits==deposits_before,"coastal opportunity magically created a resource stock or deposit")
	_expect(not bool(profile.maritime_trade_ready) and not bool(profile.maritime_movement_ready),"coastline unlocked maritime capability without knowledge")
	_expect(float(profile.maritime_trade_factor)==0.0 and float(profile.maritime_movement_factor)==0.0,"pre-knowledge maritime bonuses were nonzero")
	GameState.known_discoveries=["boat_building","coastal_navigation","port_operations","maritime_supply"]
	GameState.discovery_adoption={"boat_building":0.6,"coastal_navigation":0.5,"port_operations":0.4,"maritime_supply":0.45}
	var learned:Dictionary=SettlementModel.settlement_intrinsic_profile()
	_expect(bool(learned.maritime_trade_ready) and float(learned.maritime_trade_factor)>0.0,"specific port knowledge did not unlock bounded trade potential")
	_expect(bool(learned.maritime_movement_ready) and float(learned.maritime_movement_factor)>0.0,"specific supply knowledge did not unlock bounded movement potential")
	GameState.known_discoveries=[]
	GameState.discovery_adoption={}
	GameState.water_metrics["source_accessible"]=false
	GameState.resource_deposits=[]
	GameState.player_settlements[0]["territory_context"]={}
	GameState.province_terrain="Plains"
	var inland_food:Dictionary=FoodSystem._produce(100.0,0.7,0.7,false)
	GameState.province_terrain="Coast"
	var coastal_food:Dictionary=FoodSystem._produce(100.0,0.7,0.7,false)
	var traveling_food:Dictionary=FoodSystem._produce(100.0,0.7,0.7,true)
	_expect(float(inland_food.Fish)==0.0 and float(coastal_food.Fish)>0.0,"shoreline subsistence was not applied to settlement food")
	_expect(float(traveling_food.Fish)==0.0,"shoreline subsistence incorrectly followed a traveling party")
	var validation:=SettlementModel.validate_settlement_network()
	_expect(validation.is_empty(),"settlement validation failed: %s" % JSON.stringify(validation))
	if failures.is_empty():
		print("COASTAL_SETTLEMENT_PASS food_factor=%.3f support_factor=%.3f waterborne_potential=%.3f" % [float(profile.early_food_factor),float(profile.territory_support_factor),float(profile.waterborne_access_potential)])
		get_tree().quit()
	else:
		for failure in failures: push_error("COASTAL_SETTLEMENT_FAIL "+failure)
		get_tree().quit(1)

func _expect(condition:bool,message:String)->void:
	if not condition: failures.append(message)
