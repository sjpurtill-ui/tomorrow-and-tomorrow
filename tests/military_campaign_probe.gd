extends Node


func _ready()->void:
	call_deferred("_run")


func _run()->void:
	GameState.reset_for_new_world(90210)
	GameState.initialize_citizen_registry()
	GameState.population_allocations["Crafting"]=6
	GameState.population_allocations["Logistics"]=4
	GameState.resource_stockpiles={"Timber":100.0,"Stone":100.0,"Fiber Plants":100.0,"Iron Ore":100.0,"Food":1000.0}
	MilitaryCampaign.reset_for_new_world()
	DiscoverySystem.reset_for_new_world()
	DiscoverySystem.initialize()
	assert(DiscoverySystem.validate_catalog().is_empty())
	assert(MilitaryCampaign.validate_military_progression().is_empty())
	var locked_spear:Dictionary=MilitaryCampaign.queue_equipment_production("spear",1)
	assert(String(locked_spear.get("required_discovery",""))=="hafted_weapons")
	var locked_cart:Dictionary=MilitaryCampaign.queue_transport_cart_production(1)
	assert(String(locked_cart.get("required_discovery",""))=="joinery")
	assert(String(MilitaryCampaign.military_capabilities().transport_carts.discovery)=="joinery")
	var locked_siege_kit:Dictionary=MilitaryCampaign.queue_equipment_production("siege_kit",1)
	assert(String(locked_siege_kit.get("required_discovery",""))=="siege_engineering")
	assert(String(MilitaryCampaign.military_capabilities().units.siege_engineer.discovery)=="siege_engineering")
	var spear_gate:Dictionary=MilitaryCampaign.military_capabilities().equipment.spear
	assert(String(spear_gate.discovery)=="hafted_weapons")
	assert("hafted_tools" in (spear_gate.prerequisites as Array))
	assert(float(spear_gate.minimum_adoption)>0.0)
	var timber_before_cancel:=float(GameState.resource_stockpiles.Timber)
	GameState.population_allocations["Crafting"]=1
	var cancelled_job:Dictionary=MilitaryCampaign.queue_equipment_production("improvised",4)
	assert(not cancelled_job.has("error"))
	assert(MilitaryCampaign.workshop_utilization()>0.0)
	assert(MilitaryCampaign.civilian_crafting_fraction()<1.0)
	assert(float(MilitaryCampaign.military_capabilities().equipment_backlog_work)>0.0)
	var timber_after_reservation:=float(GameState.resource_stockpiles.Timber)
	MilitaryCampaign._process_equipment_production_day()
	var cancelled_equipment:Dictionary=MilitaryCampaign.cancel_equipment_job(int(cancelled_job.id))
	assert(bool(cancelled_equipment.cancelled))
	assert(float(GameState.resource_stockpiles.Timber)>timber_after_reservation)
	assert(float(GameState.resource_stockpiles.Timber)<timber_before_cancel)
	assert(is_equal_approx(MilitaryCampaign.civilian_crafting_fraction(),1.0))
	GameState.population_allocations["Crafting"]=6
	var locked_line:Dictionary=MilitaryCampaign.start_training("line_infantry","improvised",1)
	assert(String(locked_line.get("required_discovery",""))=="shield_wall")
	var impossible_cavalry:Dictionary=MilitaryCampaign.start_training("cavalry","lance",1)
	assert(String(impossible_cavalry.get("error","")).contains("domesticated mount"))
	assert(String(MilitaryCampaign.military_capabilities().units.cavalry.get("physical_requirement",""))=="domesticated_mounts")
	var raised:Dictionary=MilitaryCampaign.raise_recruits(12)
	var raised_count:=int(raised.raised)
	assert(raised_count>0)
	assert(raised_count<=int(raised.capacity))
	assert(MilitaryCampaign._effective_training_rate(MilitaryCampaign.training_capacity()*3)<MilitaryCampaign._training_rate())
	assert(int(MilitaryCampaign.military_capabilities().training_capacity)>0)
	var production:Dictionary=MilitaryCampaign.queue_equipment_production("improvised",raised_count)
	assert(not production.has("error"))
	var training:Dictionary=MilitaryCampaign.start_training("levy","improvised",raised_count)
	assert(int(training.accepted)==raised_count)
	for day in 4:
		MilitaryCampaign._process_military_day()
		if int(MilitaryCampaign.military_inventory.improvised)>0: break
	assert(int(MilitaryCampaign.military_inventory.improvised)>0)
	assert(int(MilitaryCampaign.military_inventory.improvised)<raised_count)
	var partial_training:=float(GameState.citizen_by_id(int(MilitaryCampaign.training_queue[0].soldier_ids[0])).get("military_training",0.0))
	assert(partial_training>0.0)
	var cancelled:Dictionary=MilitaryCampaign.cancel_training(int(training.id))
	assert(int(cancelled.returned)==raised_count)
	assert(MilitaryCampaign.training_queue.is_empty())
	training=MilitaryCampaign.start_training("levy","improvised",raised_count)
	assert(int(training.accepted)==raised_count)
	assert(float(training.required_days)<7.0)
	for day in 13: MilitaryCampaign._process_military_day()
	var army:Dictionary=MilitaryCampaign.campaign_army_snapshot()
	assert(int(army.troops)==raised_count)
	assert(int(army.formations[0].equipment)==raised_count)
	assert(int(army.formations[0].id)>0)
	assert(float(army.formations[0].training)<1.0)
	assert(float(army.readiness)>0.0 and float(army.readiness)<=1.0)
	assert((army.readiness_components as Dictionary).has("condition"))
	MilitaryCampaign.home_army.formations[0]["wear_accumulator"]=0.99
	MilitaryCampaign.home_army["recent_combat_days"]=7
	var damaged_before:=int(MilitaryCampaign.damaged_equipment.improvised)
	MilitaryCampaign._process_equipment_wear_day()
	assert(int(MilitaryCampaign.damaged_equipment.improvised)==damaged_before+1)
	var repair:Dictionary=MilitaryCampaign.queue_equipment_repair("improvised",1)
	assert(not repair.has("error"))
	var cancelled_repair:Dictionary=MilitaryCampaign.cancel_equipment_job(int(repair.id))
	assert(int(cancelled_repair.damaged_items_returned)==1)
	assert(int(MilitaryCampaign.damaged_equipment.improvised)==damaged_before+1)
	repair=MilitaryCampaign.queue_equipment_repair("improvised",1)
	assert(not repair.has("error"))
	for day in 3: MilitaryCampaign._process_equipment_production_day()
	assert(int(MilitaryCampaign.military_inventory.improvised)==1)
	assert(MilitaryCampaign._deliver_inventory_replacements(1)==1)
	assert(int(army.recruits)==0)
	assert(int(army.reserve_manpower)==0)
	assert(MilitaryCampaign._mobilized_count()==raised_count)
	assert((army.training_queue as Array).is_empty())
	assert((army.equipment_queue as Array).is_empty())
	GameState.known_discoveries.append("hafted_weapons")
	GameState.discovery_adoption["hafted_weapons"]=0.20
	var basic_training_quality:=MilitaryCampaign._training_quality("line_infantry")
	GameState.known_discoveries.append_array(["formation_drill","professional_corps"])
	GameState.discovery_adoption["formation_drill"]=0.80
	GameState.discovery_adoption["professional_corps"]=0.70
	assert(MilitaryCampaign._training_quality("line_infantry")>basic_training_quality)
	var unlocked_spear:Dictionary=MilitaryCampaign.queue_equipment_production("spear",1)
	assert(not unlocked_spear.has("error"))
	var capabilities:Dictionary=MilitaryCampaign.military_capabilities()
	assert(bool(capabilities.equipment.spear.unlocked))
	assert(not bool(capabilities.units.line_infantry.unlocked))
	var bronze_recipe:Dictionary=MilitaryCampaign._equipment_recipe("sword_shield")
	assert(bronze_recipe.materials.has("Copper Ore"))
	assert(bronze_recipe.materials.has("Tin Ore"))
	assert(not bronze_recipe.materials.has("Iron Ore"))
	var low_training:Dictionary=MilitaryCampaign.simulator.create_formation_force("Low",[{"unit":"line_infantry","weapon":"spear","count":10,"equipment":10,"training":0.30}],1.0,1.0)
	var high_training:Dictionary=MilitaryCampaign.simulator.create_formation_force("High",[{"unit":"line_infantry","weapon":"spear","count":10,"equipment":10,"training":1.10}],1.0,1.0)
	var dummy:Dictionary=MilitaryCampaign.simulator.create_formation_force("Dummy",[{"unit":"levy","weapon":"improvised","count":10,"equipment":10}],1.0,1.0)
	assert(float(MilitaryCampaign.simulator.evaluate_force(high_training,dummy)[0].attack)>float(MilitaryCampaign.simulator.evaluate_force(low_training,dummy)[0].attack))
	var green_force:Dictionary=MilitaryCampaign.simulator.create_formation_force("Green",[{"unit":"line_infantry","weapon":"spear","count":10,"equipment":10,"training":0.70,"experience":0.0}],1.0,1.0)
	var veteran_force:Dictionary=MilitaryCampaign.simulator.create_formation_force("Veteran",[{"unit":"line_infantry","weapon":"spear","count":10,"equipment":10,"training":0.70,"experience":0.80}],1.0,1.0)
	assert(float(MilitaryCampaign.simulator.evaluate_force(veteran_force,dummy)[0].attack)>float(MilitaryCampaign.simulator.evaluate_force(green_force,dummy)[0].attack))
	var enemy:Dictionary=MilitaryCampaign.simulator.create_formation_force("Raiders",[{"unit":"levy","weapon":"improvised","count":8,"equipment":8}],0.7,0.8)
	var damaged_before_battle:=int(MilitaryCampaign.damaged_equipment.improvised)
	var battle:Dictionary=MilitaryCampaign.resolve_campaign_battle(enemy,{"seed":77,"max_rounds":2})
	assert(not battle.has("error"))
	var battlefield_equipment_losses:=0
	for round_data in battle.rounds:
		for amount in round_data.attacker_cohort_equipment_losses: battlefield_equipment_losses+=int(amount)
	assert(int(MilitaryCampaign.damaged_equipment.improvised)-damaged_before_battle==floori(float(battlefield_equipment_losses)*0.35))
	var post_battle:Dictionary=MilitaryCampaign.campaign_army_snapshot()
	assert(int(post_battle.troops)==(post_battle.soldier_ids as Array).size())
	if not (post_battle.soldier_ids as Array).is_empty():
		var veteran_id:=int(post_battle.soldier_ids[0])
		var veteran:Dictionary=GameState.citizen_by_id(veteran_id)
		assert(float(veteran.get("military_experience",0.0))>0.0)
		assert(int(veteran.get("battles_survived",0))==1)
		var veteran_experience:=float(veteran.military_experience)
		var veteran_quality:=MilitaryCampaign._training_quality("line_infantry",[veteran_id])
		veteran["military_experience"]=0.0
		var novice_quality:=MilitaryCampaign._training_quality("line_infantry",[veteran_id])
		veteran["military_experience"]=veteran_experience
		MilitaryCampaign._refresh_formation_experience()
		assert(veteran_quality>novice_quality)
	if not MilitaryCampaign.pending_aftermath.is_empty():
		var aftermath:Dictionary=MilitaryCampaign.resolve_aftermath("hold","army stores","hold")
		assert(not aftermath.has("error"))
	for day in 120:
		if int(MilitaryCampaign.home_army.get("wounded_pool",0))+int(MilitaryCampaign.home_army.get("scattered_pool",0))<=0: break
		MilitaryCampaign._process_military_day()
	var recovered:Dictionary=MilitaryCampaign.campaign_army_snapshot()
	assert(int(recovered.troops)==(recovered.soldier_ids as Array).size())
	assert(int(recovered.wounded_pool)==(recovered.wounded_ids as Array).size())
	assert(int(recovered.scattered_pool)==(recovered.scattered_ids as Array).size())
	var before_capture:=int(recovered.troops)
	var captured_before:=(recovered.captured_ids as Array).size()
	var equipment_before_capture:=0
	for formation in recovered.formations: equipment_before_capture+=int(formation.equipment)
	MilitaryCampaign._mark_home_prisoners(1)
	var captured:Dictionary=MilitaryCampaign.campaign_army_snapshot()
	assert(int(captured.troops)==before_capture-1)
	assert(int(captured.troops)==(captured.soldier_ids as Array).size())
	assert((captured.captured_ids as Array).size()==captured_before+1)
	var equipment_after_capture:=0
	for formation in captured.formations: equipment_after_capture+=int(formation.equipment)
	assert(equipment_after_capture==equipment_before_capture)
	assert(MilitaryCampaign._mobilized_count()==raised_count)
	var open_capacity:=maxi(0,MilitaryCampaign.recruitment_capacity()-MilitaryCampaign._mobilized_count())
	var capped_replacement:Dictionary=MilitaryCampaign.raise_recruits(raised_count)
	assert(int(capped_replacement.raised)==mini(raised_count,open_capacity))
	if not MilitaryCampaign.recruit_pool.is_empty():
		var injury_order:Dictionary=MilitaryCampaign.start_training("levy","improvised",1)
		assert(not injury_order.has("error"))
		MilitaryCampaign.training_queue[-1]["injury_accumulator"]=1.0
		MilitaryCampaign._process_training_day()
		assert(MilitaryCampaign.training_injuries.size()==1)
		var injured_id:=int(MilitaryCampaign.training_injuries[0].citizen_id)
		assert(String(GameState.citizen_by_id(injured_id).army_status)=="training_injured")
		for day in 13: MilitaryCampaign._process_training_injuries_day()
		assert(injured_id in MilitaryCampaign.recruit_pool)
	var target_id:=int(MilitaryCampaign.home_army.formations[0].id)
	var veteran_cohort_experience:=float(MilitaryCampaign.home_army.formations[0].experience)
	var reinforcement:Dictionary=MilitaryCampaign.reinforce_formation(target_id,raised_count)
	if not reinforcement.has("error"):
		for day in 20: MilitaryCampaign._process_training_day()
		var reinforced_index:=MilitaryCampaign._formation_index(target_id)
		assert(reinforced_index>=0)
		assert(float(MilitaryCampaign.home_army.formations[reinforced_index].experience)<=veteran_cohort_experience)
	captured=MilitaryCampaign.campaign_army_snapshot()
	assert(MilitaryCampaign.validate_state().is_empty())
	var saved:Dictionary=MilitaryCampaign.export_state()
	MilitaryCampaign.reset_for_new_world()
	var restored:Dictionary=MilitaryCampaign.import_state(saved)
	assert(bool(restored.get("ok",false)))
	var restored_army:Dictionary=MilitaryCampaign.campaign_army_snapshot()
	assert(int(restored_army.troops)==int(captured.troops))
	assert((restored_army.captured_ids as Array)==(captured.captured_ids as Array))
	var legacy:=saved.duplicate(true)
	legacy["version"]=1
	legacy.erase("next_training_order_id"); legacy.erase("next_formation_id"); legacy.erase("training_injuries")
	for formation in legacy.home_army.formations: formation.erase("id")
	MilitaryCampaign.reset_for_new_world()
	var migrated:Dictionary=MilitaryCampaign.import_state(legacy)
	assert(bool(migrated.get("ok",false)))
	assert(MilitaryCampaign.validate_state().is_empty())
	var anonymous_job_save:=saved.duplicate(true)
	anonymous_job_save.erase("next_equipment_job_id")
	anonymous_job_save["equipment_queue"]=[{"item":"improvised","count":2,"completed":0,"progress_days":0.0,"work_per_item":0.25,"required_days":0.5}]
	MilitaryCampaign.reset_for_new_world()
	var normalized_jobs:Dictionary=MilitaryCampaign.import_state(anonymous_job_save)
	assert(bool(normalized_jobs.get("ok",false)))
	assert(int(MilitaryCampaign.equipment_queue[0].id)>0)
	assert((MilitaryCampaign.equipment_queue[0].reserved_materials as Dictionary).has("Timber"))
	assert(MilitaryCampaign.validate_state().is_empty())
	var invalid:=saved.duplicate(true)
	if not (invalid.home_army.soldier_ids as Array).is_empty(): invalid.home_army.wounded_ids.append(invalid.home_army.soldier_ids[0])
	var rejected:Dictionary=MilitaryCampaign.import_state(invalid)
	assert(rejected.has("error"))
	assert(MilitaryCampaign.validate_state().is_empty())
	var marshal_citizen:Dictionary={}
	for citizen in GameState.living_citizens():
		if int(citizen.id) not in (MilitaryCampaign.home_army.soldier_ids as Array) and int(citizen.id) not in (MilitaryCampaign.home_army.captured_ids as Array): marshal_citizen=citizen; break
	assert(not marshal_citizen.is_empty())
	var marshal_record:={"citizen_id":int(marshal_citizen.id),"name":String(marshal_citizen.name),"courage":0.72,"suspicion":0.64,"honesty":0.61,"pride":0.55,"skills":{"Strategy":72,"Tactics":68,"Logistics":58},"relationships":{"sovereign":{"trust":0.5,"respect":0.5,"fear":0.1,"resentment":0.0,"obligation":0.5}}}
	GameState.leadership_positions["Marshal"]=marshal_record
	MilitaryCampaign.home_army["commander"]=MilitaryCampaign._marshal_commander()
	GameState.known_discoveries.append("shield_wall")
	GameState.discovery_adoption["shield_wall"]=0.80
	var retrain_target:=int(MilitaryCampaign.home_army.formations[0].id)
	var experience_before_retraining:=float(MilitaryCampaign.home_army.formations[0].experience)
	var retraining:Dictionary=MilitaryCampaign.retrain_formation(retrain_target,"line_infantry","spear")
	assert(not retraining.has("error"))
	for day in 10: MilitaryCampaign._process_training_day()
	assert(not MilitaryCampaign.training_queue.is_empty())
	assert(float(MilitaryCampaign.training_queue[0].equipment_access_today)<1.0)
	var under_equipped_progress:=float(MilitaryCampaign.training_queue[0].progress_days)
	MilitaryCampaign.military_inventory["spear"]=maxi(int(MilitaryCampaign.military_inventory.get("spear",0)),int(retraining.accepted))
	for day in 55: MilitaryCampaign._process_training_day()
	assert(under_equipped_progress<float(MilitaryCampaign.training_queue[0].required_days) if not MilitaryCampaign.training_queue.is_empty() else true)
	assert(not MilitaryCampaign.home_army.formations.is_empty())
	assert(String(MilitaryCampaign.home_army.formations[-1].unit)=="line_infantry")
	assert(is_equal_approx(float(MilitaryCampaign.home_army.formations[-1].experience),experience_before_retraining))
	MilitaryCampaign._apply_home_commander_fate({"defeated":MilitaryCampaign.home_army.name,"commander_fate":"killed"})
	assert(not bool(GameState.citizen_by_id(int(marshal_citizen.id)).alive))
	assert(GameState.leadership_positions.has("Marshal"))
	assert(int(GameState.leadership_positions.Marshal.citizen_id)!=int(marshal_citizen.id))
	assert(bool(MilitaryCampaign.home_army.commander.get("acting",false)))
	var before_stand_down:=int(MilitaryCampaign.home_army.troops)
	var experience_before_stand_down:Dictionary={}
	for citizen_id in MilitaryCampaign.home_army.soldier_ids: experience_before_stand_down[int(citizen_id)]=float(GameState.citizen_by_id(int(citizen_id)).get("military_experience",0.0))
	var stood_down:Dictionary=MilitaryCampaign.stand_down(1)
	assert(int(stood_down.released)==1)
	assert(int(MilitaryCampaign.home_army.troops)==before_stand_down-1)
	var released_citizen:Dictionary=GameState.citizen_by_id(int(stood_down.citizen_ids[0]))
	assert(String(released_citizen.army_status)=="civilian")
	assert(is_equal_approx(float(released_citizen.get("military_experience",0.0)),float(experience_before_stand_down[int(released_citizen.id)])))
	released_citizen["service_strain"]=0.5
	MilitaryCampaign._process_service_rest_day()
	assert(float(released_citizen.service_strain)<0.5)
	assert(MilitaryCampaign.validate_state().is_empty())
	GameState.simulation_metrics["food_intake_ratio"]=0.0
	GameState.population_allocations["Logistics"]=0
	MilitaryCampaign.home_army["supply_level"]=1.0
	MilitaryCampaign._refresh_readiness()
	var supplied_readiness:=float(MilitaryCampaign.home_army.readiness)
	for day in 8: MilitaryCampaign._process_military_day()
	var depleted_supply:=float(MilitaryCampaign.home_army.supply_level)
	var depleted_readiness:=float(MilitaryCampaign.home_army.readiness)
	assert(depleted_supply<0.40)
	assert(depleted_readiness<supplied_readiness)
	GameState.simulation_metrics["food_intake_ratio"]=1.0
	GameState.population_allocations["Logistics"]=10
	for day in 12: MilitaryCampaign._process_military_day()
	assert(float(MilitaryCampaign.home_army.supply_level)>depleted_supply)
	if not (MilitaryCampaign.home_army.soldier_ids as Array).is_empty():
		var service_id:=int(MilitaryCampaign.home_army.soldier_ids[0])
		var service_days_before:=int(GameState.citizen_by_id(service_id).get("military_service_days",0))
		MilitaryCampaign.home_army["desertion_accumulator"]=1.0
		for citizen_id in MilitaryCampaign.home_army.soldier_ids: GameState.citizen_by_id(int(citizen_id))["service_strain"]=1.0
		var service_result:Dictionary=MilitaryCampaign._process_service_strain_day()
		assert(int(service_result.deserted)==1)
		assert(String(GameState.citizen_by_id(int(service_result.citizen_ids[0])).army_status)=="deserter")
		if service_id in MilitaryCampaign.home_army.soldier_ids: assert(int(GameState.citizen_by_id(service_id).military_service_days)==service_days_before+1)
		MilitaryCampaign._refresh_readiness()
		assert((MilitaryCampaign.home_army.readiness_components as Dictionary).has("discipline"))
		assert(MilitaryCampaign.validate_state().is_empty())
	var locked_count:=0
	for citizen in GameState.living_citizens():
		if GameState._citizen_locked_to_military(citizen): locked_count+=1
	GameState.population_allocation_percentages["Defense"]=0.0
	GameState.synchronize_population_allocations()
	assert(int(GameState.population_allocations.Defense)>=locked_count)
	for citizen_id in MilitaryCampaign.home_army.soldier_ids: assert(String(GameState.citizen_by_id(int(citizen_id)).role)=="Defense")
	var allocated_total:=0
	for allocation in GameState.population_allocations.values(): allocated_total+=int(allocation)
	assert(allocated_total==GameState.able_population())
	var cost:Dictionary=MilitaryCampaign.campaign_army_snapshot().mobilization_cost
	assert(int(cost.citizens_withheld)==locked_count)
	if not (MilitaryCampaign.home_army.captured_ids as Array).is_empty():
		var home_captive:=int(MilitaryCampaign.home_army.captured_ids[0])
		MilitaryCampaign.foreign_prisoners+=1
		var exchange:Dictionary=MilitaryCampaign.exchange_prisoners(1)
		assert(int(exchange.exchanged)==1)
		assert(home_captive in MilitaryCampaign.recruit_pool)
		assert(String(GameState.citizen_by_id(home_captive).army_status)=="recruit")
	var custody_food_before:=float(FoodSystem._calculate_demand(false).prisoner_custody)
	MilitaryCampaign.foreign_prisoners+=2
	assert(is_equal_approx(float(FoodSystem._calculate_demand(false).prisoner_custody)-custody_food_before,1.30))
	MilitaryCampaign.prisoner_escape_accumulator=1.0
	var custody_result:Dictionary=MilitaryCampaign._process_prisoner_custody_day()
	assert(int(custody_result.escaped)==1)
	assert(int(MilitaryCampaign.prisoner_custody_snapshot().escaped_total)>0)
	if MilitaryCampaign.foreign_prisoners>0:
		var held_before:=MilitaryCampaign.foreign_prisoners
		var released_held:Dictionary=MilitaryCampaign.resolve_held_prisoners("release",1)
		assert(int(released_held.disposed)==1)
		assert(MilitaryCampaign.foreign_prisoners==held_before-1)
	MilitaryCampaign.held_generals.append({"name":"Test captive","captured_day":0})
	var general_disposition:Dictionary=MilitaryCampaign.resolve_held_general(0,"ransom")
	assert(int(general_disposition.ransom_income)==50)
	assert(MilitaryCampaign.held_generals.is_empty())
	var stranded_recoveree:=released_citizen
	stranded_recoveree["army_status"]="scattered"
	stranded_recoveree["role"]="Defense"
	stranded_recoveree["pre_army_role"]="Food"
	MilitaryCampaign.home_army.scattered_ids.append(int(stranded_recoveree.id))
	MilitaryCampaign.home_army["scattered_pool"]=(MilitaryCampaign.home_army.scattered_ids as Array).size()
	for formation in MilitaryCampaign.home_army.formations:
		formation["authorized_count"]=int(formation.count)
		formation["equipment_required"]=int(formation.count)
	MilitaryCampaign.home_army["scattered_recovery_accumulator"]=1.0
	MilitaryCampaign._process_military_day()
	assert(int(stranded_recoveree.id) in MilitaryCampaign.recruit_pool)
	assert(int(stranded_recoveree.id) not in (MilitaryCampaign.home_army.scattered_ids as Array))
	assert(String(stranded_recoveree.army_status)=="recruit")
	assert(MilitaryCampaign.validate_state().is_empty())
	if "bow_craft" not in GameState.known_discoveries: GameState.known_discoveries.append("bow_craft")
	GameState.discovery_adoption["bow_craft"]=0.20
	GameState.resource_stockpiles["Timber"]=100.0
	GameState.resource_stockpiles["Fiber Plants"]=100.0
	GameState.resource_stockpiles["Stone"]=100.0
	var arrow_job:Dictionary=MilitaryCampaign.queue_consumable_production("arrows",24)
	assert(not arrow_job.has("error"))
	for day in 100:
		MilitaryCampaign._process_equipment_production_day()
		if int(MilitaryCampaign.military_consumables.arrows)>=24: break
	assert(int(MilitaryCampaign.military_consumables.arrows)==24)
	if not (MilitaryCampaign.home_army.formations as Array).is_empty():
		MilitaryCampaign.home_army.formations[0]["weapon"]="bow"
		MilitaryCampaign.home_army.formations[0]["ammunition"]=0
		MilitaryCampaign.home_army.formations[0]["ammunition_required"]=24
		assert(MilitaryCampaign._deliver_ammunition(9)==9)
		assert(int(MilitaryCampaign.home_army.formations[0].ammunition)==9)
		assert(int(MilitaryCampaign.military_consumables.arrows)==15)
	GameState.food_stocks={"Fresh plants":0.0,"Fresh meat":0.0,"Fish":0.0,"Dry staples":10000.0,"Preserved food":0.0}
	GameState.resource_stockpiles["Food"]=10000.0
	GameState.resource_stockpiles["Transport Carts"]=0.0
	GameState.population_allocations["Logistics"]=0
	FoodSystem.initialized=true
	var provisioned_soldier:Dictionary={}
	if not (MilitaryCampaign.home_army.soldier_ids as Array).is_empty(): provisioned_soldier=GameState.citizen_by_id(int(MilitaryCampaign.home_army.soldier_ids[0]))
	var nutrition_before:=float(provisioned_soldier.get("nutrition_condition",1.0))
	var low_provision_day:Dictionary=FoodSystem.process_day({"traveling":false},1.0,1.0)
	assert(float(low_provision_day.army_provisions_required)>0.0)
	assert(float(low_provision_day.army_provisions_delivered)<float(low_provision_day.army_provisions_required))
	var low_provision_ratio:=float(MilitaryCampaign.home_army.provision_ratio)
	if not provisioned_soldier.is_empty(): assert(float(provisioned_soldier.nutrition_condition)<nutrition_before)
	GameState.resource_stockpiles["Transport Carts"]=20.0
	GameState.population_allocations["Logistics"]=20
	var high_provision_day:Dictionary=FoodSystem.process_day({"traveling":false},1.0,1.0)
	assert(float(MilitaryCampaign.home_army.provision_ratio)>low_provision_ratio)
	assert(float(high_provision_day.army_provisions_delivered)>float(low_provision_day.army_provisions_delivered))
	if "joinery" not in GameState.known_discoveries: GameState.known_discoveries.append("joinery")
	GameState.discovery_adoption["joinery"]=0.20
	GameState.resource_stockpiles["Timber"]=100.0
	GameState.resource_stockpiles["Fiber Plants"]=100.0
	var carts_before:=float(GameState.resource_stockpiles.get("Transport Carts",0.0))
	var cart_job:Dictionary=MilitaryCampaign.queue_transport_cart_production(1)
	assert(not cart_job.has("error"))
	for day in 100:
		MilitaryCampaign._process_equipment_production_day()
		if float(GameState.resource_stockpiles.get("Transport Carts",0.0))>carts_before: break
	assert(is_equal_approx(float(GameState.resource_stockpiles.get("Transport Carts",0.0)),carts_before+1.0))
	if "siege_engineering" not in GameState.known_discoveries: GameState.known_discoveries.append("siege_engineering")
	GameState.discovery_adoption["siege_engineering"]=0.20
	GameState.resource_stockpiles["Timber"]=100.0
	GameState.resource_stockpiles["Fiber Plants"]=100.0
	GameState.resource_stockpiles["Stone"]=100.0
	GameState.resource_stockpiles["Iron Ore"]=100.0
	var siege_job:Dictionary=MilitaryCampaign.queue_equipment_production("siege_kit",1)
	assert(not siege_job.has("error"))
	for day in 100:
		MilitaryCampaign._process_equipment_production_day()
		if int(MilitaryCampaign.military_inventory.siege_kit)>0: break
	assert(int(MilitaryCampaign.military_inventory.siege_kit)==1)
	print("MILITARY_CAMPAIGN_PROBE raised=%d trained=%d equipped=%d battle=%s" % [raised.raised,army.troops,army.formations[0].equipment,battle.outcome])
	get_tree().quit()
