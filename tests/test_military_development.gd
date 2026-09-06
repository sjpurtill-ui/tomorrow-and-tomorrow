extends GdUnitTestSuite

const CIVILIZATION_SYSTEM_SCRIPT:=preload("res://scripts/civilization_system.gd")
const DEVELOPMENT:=preload("res://scripts/military_development_catalog.gd")

var system:Node


func before_test()->void:
	GameState.reset_for_new_world(74017)
	GameState.settlement_site_committed=true
	GameState.resource_stockpiles={"Food":1_000_000.0,"Timber":1_000_000.0,"Stone":1_000_000.0,"Fiber Plants":1_000_000.0,"Iron Ore":1_000_000.0,"Copper Ore":1_000_000.0,"Tin Ore":1_000_000.0,"Sulfur":1_000_000.0,"Nitrates":1_000_000.0}
	GameState.population_allocations["Crafting"]=100_000
	DiscoverySystem.reset_for_new_world()
	ProgressionSystem.reset_for_new_world()
	MilitaryCampaign.reset_for_new_world()
	system=auto_free(CIVILIZATION_SYSTEM_SCRIPT.new())
	system.reset_for_new_world()
	for index in system.civilizations.size():
		var civ:Dictionary=system.civilizations[index]
		civ.player_relation["contact_level"]=2
		civ.player_relation["contact_intelligence"]=0.8
		civ.player_relation["met_day"]=0
		civ.player_relation["home_location_known"]=true
		civ.player_relation["home_position"]={"x":float(index+1)*1000.0,"z":float(index+1)*750.0}
		system.civilizations[index]=civ
		for region:Dictionary in civ.strategic_regions:system.city_intelligence.publish("player",system.city_intelligence.capture("player",String(region.id),.9,0,"returned survey","fixture"),0)


func test_military_era_requires_security_and_supporting_research_scale()->void:
	var unsupported:=DEVELOPMENT.era_for_tiers(7,2,2,2)
	assert_int(int(unsupported.tier)).is_equal(3)
	var national:=DEVELOPMENT.era_for_tiers(6,6,6,6)
	assert_str(String(national.id)).is_equal("national")
	assert_int(int(national.production_lines)).is_equal(8)
	for domain in ["security","production","logistics","institutions"]: ProgressionSystem.domain_levels[domain]=6
	var capabilities:=MilitaryCampaign.military_capabilities()
	assert_str(String(capabilities.development.id)).is_equal("national")
	assert_bool(bool(capabilities.units.armored_formation.unlocked)).is_true()
	assert_bool(bool(capabilities.equipment.modern_field_gun.unlocked)).is_true()


func test_billion_person_force_remains_one_aggregate_formation_record()->void:
	var organization:=DEVELOPMENT.organization_snapshot([{"unit":"rifle_infantry","weapon":"service_rifle","count":1_000_000_000}])
	assert_int(int(organization.personnel)).is_equal(1_000_000_000)
	assert_int(int(organization.record_count)).is_equal(1)
	assert_str(String(organization.largest.id)).is_equal("theater_force")


func test_modern_aggregate_equipment_has_real_crew_and_ammunition_requirements()->void:
	var simulator:=CombatSimulator.new()
	var armored:=simulator.create_formation_force("Armored force",[{"id":1,"unit":"armored_formation","weapon":"armored_vehicle","count":50_000}])
	assert_int(int(armored.formations[0].equipment_required)).is_equal(10_000)
	assert_int(int(armored.formations[0].ammunition_required)).is_equal(180_000)
	var rifles:=simulator.create_formation_force("Rifle force",[{"id":1,"unit":"rifle_infantry","weapon":"service_rifle","count":50_000}])
	var spears:=simulator.create_formation_force("Spear force",[{"id":1,"unit":"line_infantry","weapon":"spear","count":50_000}])
	assert_float(float(rifles.attack)).is_greater(float(spears.attack))
	assert_int((rifles.formations as Array).size()).is_equal(1)


func test_rival_military_industry_uses_the_same_supporting_domain_cap()->void:
	var civ:Dictionary=system.civilizations[0]
	for domain in civ.progression_tiers: civ.progression_tiers[domain]=2
	civ.progression_tiers["security"]=7
	civ=system._advance_rival_military_training(civ,civ.allocations,0.0)
	assert_int(int(civ.military_era_tier)).is_equal(3)
	for domain in ["production","logistics","institutions"]: civ.progression_tiers[domain]=6
	civ=system._advance_rival_military_training(civ,civ.allocations,0.0)
	assert_int(int(civ.military_era_tier)).is_equal(7)
	assert_int(int(civ.military_production_lines)).is_equal(10)


func test_industrial_production_lines_run_in_parallel_and_remain_bounded()->void:
	for domain in ["security","production","logistics","institutions"]: ProgressionSystem.domain_levels[domain]=6
	GameState.population_allocations["Crafting"]=10
	var first:=MilitaryCampaign.queue_equipment_production("service_rifle",1000)
	var second:=MilitaryCampaign.queue_consumable_production("small_arms_ammunition",10_000)
	assert_bool(bool(first.get("id",0)>0)).is_true()
	assert_bool(bool(second.get("id",0)>0)).is_true()
	var before:=MilitaryCampaign.production_lines_snapshot()
	assert_int(int(before.active)).is_equal(2)
	assert_int(int(before.capacity)).is_equal(8)
	MilitaryCampaign._process_equipment_production_day()
	var after:=MilitaryCampaign.production_lines_snapshot()
	assert_float(float(after.lines[0].remaining_work)).is_less(float(before.lines[0].remaining_work))
	assert_float(float(after.lines[1].remaining_work)).is_less(float(before.lines[1].remaining_work))
	assert_int((after.lines as Array).size()).is_less_equal(MilitaryCampaign.ABSOLUTE_MAX_PRODUCTION_LINES)


func test_declared_war_gets_a_name_front_and_permanent_closed_record()->void:
	var civ:Dictionary=system.civilizations[0]
	var civ_id:=String(civ.id)
	var target:=String(civ.strategic_regions[0].id)
	system.city_intelligence.records.clear()
	assert_bool(system.conduct_player_action(civ_id,"declare_war",true).has("error")).is_true()
	system.city_intelligence.publish("player",system.city_intelligence.capture("player",target,1.0,0,"returned survey","fixture"),0)
	civ.player_relation.war_target_region_id=target;system.civilizations[0]=civ
	var declaration:Dictionary=system.conduct_player_action(civ_id,"declare_war",true)
	assert_bool(bool(declaration.get("ok",false))).is_true()
	var records:Array=system.war_history_snapshot()
	assert_int(records.size()).is_equal(1)
	assert_str(String(records[0].name)).contains("War")
	assert_str(String(records[0].status)).is_equal("active")
	var fronts:Dictionary=system.military_fronts_snapshot()
	assert_int(int(fronts.active)).is_equal(1)
	assert_str(String(fronts.fronts[0].war_id)).is_equal(String(records[0].id))
	var pressured:Dictionary=system.civilizations[0]
	pressured.player_relation["war_score"]=100.0
	pressured.player_relation["rival_war_exhaustion"]=1.0
	system.civilizations[0]=pressured
	var peace:Dictionary=system.conduct_player_action(civ_id,"seek_peace",true)
	assert_bool(bool(peace.get("ok",false))).is_true()
	records=system.war_history_snapshot()
	assert_str(String(records[0].status)).is_equal("ended")
	assert_int(int(records[0].ended_day)).is_equal(int(GameState.elapsed_days))


func test_battle_ledger_separates_real_military_and_civilian_deaths()->void:
	var civ:Dictionary=system.civilizations[0]
	var civ_id:=String(civ.id)
	var scale:=1_000_000.0/maxf(1.0,float(civ.population))
	civ["population"]=1_000_000.0
	civ["cohorts"]=system._scaled_cohorts(civ.cohorts,1_000_000.0)
	civ["military_population"]=100_000.0
	for region_index in (civ.strategic_regions as Array).size(): civ.strategic_regions[region_index]["population"]=float(civ.strategic_regions[region_index].population)*scale
	system.civilizations[0]=civ
	assert_bool(bool(system.conduct_player_action(civ_id,"declare_war",true).get("ok",false))).is_true()
	var target:Dictionary=system.campaign_targets(civ_id).filter(func(region:Dictionary)->bool: return bool(region.available))[0]
	var population_before:=float(system.civilizations[0].population)
	var battle:Dictionary={"home_side":"attacker","campaign_mode":"offensive","target_region_id":String(target.id),"target_region_name":String(target.name),"terrain_defense":1.22,"rounds":[{"attacker_casualties":{"killed":100,"wounded":180,"scattered":40},"defender_casualties":{"killed":200,"wounded":320,"scattered":80}}],"attacker":{"name":"HOME HOST","dead":100,"remaining_troops":50000,"supply_level":1.0,"readiness":1.0},"defender":{"name":String(civ.name),"dead":200},"termination":{"type":"surrender","captor":"HOME HOST","defeated":String(civ.name),"prisoners":60}}
	var outcome:Dictionary=system.resolve_player_battle(civ_id,battle)
	var civilian_dead:=int((outcome.civilian_dead as Dictionary).rival)
	assert_int(civilian_dead).is_greater(0)
	assert_float(float(system.civilizations[0].population)).is_equal_approx(population_before-200.0-float(civilian_dead),0.01)
	var record:Dictionary=system.war_history_snapshot()[0]
	var losses:Dictionary=record.casualties[civ_id]
	assert_int(int(losses.military_dead)).is_equal(200)
	assert_int(int(losses.civilian_dead)).is_equal(civilian_dead)
	assert_int(int(losses.wounded)).is_equal(320)
	assert_int(int(losses.captured)).is_equal(60)
	assert_int((record.battles as Array).size()).is_equal(1)
	assert_bool((record.territorial_changes[0] as Dictionary).has("region_id")).is_true()
	var encoded:=JSON.stringify(system.export_state())
	assert_bool(bool(system.import_state(JSON.parse_string(encoded)).get("ok",false))).is_true()
	assert_int(int(system.war_history_snapshot()[0].casualties[civ_id].civilian_dead)).is_equal(civilian_dead)


func test_mobility_rewards_mounted_pursuit_but_respects_baggage_and_supply()->void:
	var riders:Dictionary={"formations":[{"unit":"cavalry","count":20,"training":0.8,"personnel_condition":1.0}],"supply_level":1.0}
	var foot:Dictionary={"formations":[{"unit":"levy","count":20,"training":0.8,"personnel_condition":1.0}],"supply_level":1.0}
	assert_float(MilitaryCampaign._field_army_speed(riders)).is_greater(MilitaryCampaign._field_army_speed(foot)*1.8)
	var mixed:Dictionary=riders.duplicate(true)
	mixed.formations.append({"unit":"siege_engineer","count":2,"training":0.8,"personnel_condition":1.0})
	assert_float(MilitaryCampaign._field_army_speed(mixed)).is_less(MilitaryCampaign._field_army_speed(foot))
	var hungry:Dictionary=riders.duplicate(true)
	hungry["supply_level"]=0.1
	assert_float(MilitaryCampaign._field_army_speed(hungry)).is_less(MilitaryCampaign._field_army_speed(riders)*0.7)


func test_mounted_army_can_order_pursuit_of_a_scout_without_formal_war()->void:
	CivilizationSystem.reset_for_new_world()
	CivilizationSystem.register_player_origin(Vector2.ZERO)
	CivilizationSystem.set_scout_geography_authority(func(_point:Vector2)->bool: return true)
	var scout_index:=CivilizationSystem.foreign_formations.find_custom(func(entry:Dictionary)->bool: return String(entry.get("kind",""))=="scout")
	var scout:Dictionary=CivilizationSystem.foreign_formations[scout_index]
	scout["point_a"]=Vector2(10,0)
	scout["point_b"]=Vector2(100,0)
	scout["leg_days"]=6.0
	scout["depart_day"]=0
	scout["disabled_until_day"]=0
	scout["evaded_until_day"]=0
	CivilizationSystem.foreign_formations[scout_index]=scout
	GameState.elapsed_days=0
	MilitaryCampaign.home_army=MilitaryCampaign.simulator.create_formation_force("Riders",[{"id":1,"unit":"cavalry","weapon":"lance","count":20,"training":0.8,"equipment":20}],0.8,0.8)
	MilitaryCampaign.home_army["supply_level"]=1.0
	var created:Dictionary=MilitaryCampaign.create_field_army(20)
	var army_id:=int(created.army.army_id)
	CivilizationSystem._process_local_observation(0,true)
	var available:Dictionary=MilitaryCampaign.map_engagement_availability(army_id,String(scout.id))
	assert_bool(bool(available.get("can_order",false))).is_true()
	var ordered:Dictionary=MilitaryCampaign.order_field_army_intercept(army_id,String(scout.id))
	assert_bool(bool(ordered.get("ok",false))).is_true()
	MilitaryCampaign._process_field_army_movement_day()
	assert_str(String(MilitaryCampaign.field_armies[0].status)).is_equal("stationed")
	assert_bool(MilitaryCampaign.field_armies[0].has("target_formation_id")).is_false()
	assert_bool(MilitaryCampaign.active_engagement.is_empty()).is_true()


func test_trained_personnel_form_a_bounded_army_and_move_over_known_geography()->void:
	var formation:={"id":1,"unit":"line_infantry","weapon":"spear","count":1000,"authorized_count":1000,"equipment":1000,"equipment_required":1000,"ammunition":0,"ammunition_required":0,"training":0.72,"experience":0.18,"personnel_condition":0.86}
	MilitaryCampaign.home_army=MilitaryCampaign.simulator.create_formation_force("Home reserve",[formation],0.72,0.70)
	MilitaryCampaign.home_army["supply_level"]=1.0
	MilitaryCampaign.home_army["commander"]=MilitaryCampaign.simulator.create_commander("General staff",0.65,0.62,0.70,0.64)
	MilitaryCampaign.next_formation_id=2
	CivilizationSystem.reset_for_new_world()
	var known:Dictionary=CivilizationSystem.civilizations[0]
	known.player_relation["contact_level"]=2
	known.player_relation["contact_intelligence"]=0.8
	known.player_relation["home_location_known"]=true
	known.player_relation["home_position"]={"x":1200.0,"z":900.0}
	CivilizationSystem.civilizations[0]=known
	CivilizationSystem.set_scout_geography_authority(func(_point:Vector2)->bool:return true)
	for region:Dictionary in known.strategic_regions:CivilizationSystem.city_intelligence.publish("player",CivilizationSystem.city_intelligence.capture("player",String(region.id),.9,0,"returned survey","fixture"),0)
	CivilizationSystem._add_revealed_area(Vector2(1200.0,900.0),300.0,"returned military chart")
	var created:=MilitaryCampaign.create_field_army(600)
	assert_bool(bool(created.get("ok",false))).is_true()
	assert_int(int(MilitaryCampaign.home_army.troops)).is_equal(400)
	assert_int(int(MilitaryCampaign.field_armies[0].troops)).is_equal(600)
	var destinations:Array=CivilizationSystem.military_movement_destinations()
	assert_int(destinations.size()).is_greater(1)
	var target:Dictionary=destinations[1]
	var order:=MilitaryCampaign.move_field_army(int(MilitaryCampaign.field_armies[0].army_id),String(target.id))
	assert_bool(bool(order.get("ok",false))).is_true()
	assert_str(String(MilitaryCampaign.field_armies[0].status)).is_equal("moving")
	var ordered_army:Dictionary=order.get("army",{})
	var maximum_travel_days:=ceili(float(ordered_army.get("distance_total_km",0.0))/4.0)+1
	for _day in maximum_travel_days:
		MilitaryCampaign._process_field_army_movement_day()
		if String(MilitaryCampaign.field_armies[0].status)=="stationed": break
	assert_str(String(MilitaryCampaign.field_armies[0].status)).is_equal("stationed")
	assert_str(String(MilitaryCampaign.field_armies[0].location_id)).is_equal(String(target.id))
	var front_assignment:Dictionary=MilitaryCampaign.front_force_snapshot(String(target.civ_id),String(target.region_id))
	assert_int(int(front_assignment.field_personnel)).is_equal(600)
	assert_int(int(front_assignment.reserve_personnel)).is_equal(400)
	assert_int((front_assignment.armies as Array).size()).is_equal(1)
	assert_bool(bool(CivilizationSystem.conduct_player_action(String(target.civ_id),"declare_war",true).get("ok",false))).is_true()
	var fronts:Dictionary=CivilizationSystem.military_fronts_snapshot()
	assert_int((fronts.get("fronts",[]) as Array).size()).is_equal(1)
	var active_front:Dictionary=(fronts.get("fronts",[]) as Array)[0]
	assert_int(int(active_front.field_personnel)).is_equal(600)
	assert_int(int(active_front.reserve_personnel)).is_equal(400)
	var campaign:=MilitaryCampaign.offensive_campaign_availability(String(target.civ_id),String(target.region_id))
	assert_bool(bool(campaign.get("ok",false))).is_true()
	assert_int(int((campaign.get("incident",{}) as Dictionary).get("field_army_id",0))).is_equal(int(MilitaryCampaign.field_armies[0].army_id))
	assert_int(MilitaryCampaign._mobilized_count()).is_equal(1000)
	assert_array(MilitaryCampaign.validate_state()).is_empty()
	assert_int(JSON.stringify(MilitaryCampaign.export_state()).length()).is_less(100_000)


func test_offensive_requires_a_formed_army_at_the_objective()->void:
	var formation:={"id":1,"unit":"line_infantry","weapon":"spear","count":1000,"authorized_count":1000,"equipment":1000,"equipment_required":1000,"ammunition":0,"ammunition_required":0,"training":0.72,"experience":0.18,"personnel_condition":0.86}
	MilitaryCampaign.home_army=MilitaryCampaign.simulator.create_formation_force("Home reserve",[formation],0.72,0.70)
	MilitaryCampaign.next_formation_id=2
	CivilizationSystem.reset_for_new_world()
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	civ.player_relation["contact_level"]=2
	civ.player_relation["contact_intelligence"]=0.8
	civ.player_relation["home_location_known"]=true
	civ.player_relation["home_position"]={"x":1200.0,"z":900.0}
	civ.player_relation["at_war"]=true
	civ.player_relation["treaty"]="war"
	CivilizationSystem.civilizations[0]=civ
	for region:Dictionary in civ.strategic_regions:CivilizationSystem.city_intelligence.publish("player",CivilizationSystem.city_intelligence.capture("player",String(region.id),.9,0,"returned survey","fixture"),0)
	var target:Dictionary=CivilizationSystem.campaign_targets(String(civ.id)).filter(func(region:Dictionary)->bool: return bool(region.available))[0]
	var blocked:Dictionary=MilitaryCampaign.offensive_campaign_availability(String(civ.id),String(target.id))
	assert_bool(blocked.has("error")).is_true()
	assert_str(String(blocked.error)).contains("Form a field army")
	var created:Dictionary=MilitaryCampaign.create_field_army(600)
	var army_id:=int((created.get("army",{}) as Dictionary).get("army_id",0))
	assert_bool(MilitaryCampaign.offensive_campaign_availability(String(civ.id),String(target.id)).has("error")).is_true()
	MilitaryCampaign.field_armies[0]["status"]="stationed"
	MilitaryCampaign.field_armies[0]["location_id"]=String(target.id)
	MilitaryCampaign.field_armies[0]["location_name"]=String(target.name)
	var ready:Dictionary=MilitaryCampaign.offensive_campaign_availability(String(civ.id),String(target.id))
	assert_bool(bool(ready.get("ok",false))).is_true()
	assert_int(int((ready.incident as Dictionary).field_army_id)).is_equal(army_id)


func test_visible_map_formation_requires_war_then_opens_battle_with_the_selected_army()->void:
	var reserve:={"id":1,"unit":"line_infantry","weapon":"spear","count":120,"authorized_count":120,"equipment":120,"equipment_required":120,"ammunition":0,"ammunition_required":0,"training":0.72,"experience":0.18,"personnel_condition":0.86}
	MilitaryCampaign.home_army=MilitaryCampaign.simulator.create_formation_force("Home reserve",[reserve],0.72,0.70)
	MilitaryCampaign.home_army["supply_level"]=1.0
	MilitaryCampaign.home_army["commander"]=MilitaryCampaign.simulator.create_commander("Field speaker",0.65,0.62,0.70,0.64)
	MilitaryCampaign.next_formation_id=2
	CivilizationSystem.reset_for_new_world()
	CivilizationSystem.register_player_origin(Vector2.ZERO)
	var formation_index:=CivilizationSystem.foreign_formations.find_custom(func(entry:Dictionary)->bool: return String(entry.get("kind",""))!="scout")
	assert_int(formation_index).is_greater_equal(0)
	var foreign:Dictionary=CivilizationSystem.foreign_formations[formation_index]
	foreign["point_a"]=Vector2(4.0,0.0)
	foreign["point_b"]=Vector2(4.0,0.0)
	foreign["depart_day"]=0
	foreign["leg_days"]=60.0
	foreign["disabled_until_day"]=0
	CivilizationSystem.foreign_formations[formation_index]=foreign
	var civ_index:=CivilizationSystem._civilization_index(String(foreign.civ_id))
	var civ:Dictionary=CivilizationSystem.civilizations[civ_index]
	civ["military_population"]=120.0
	civ.player_relation["contact_level"]=2
	civ.player_relation["contact_intelligence"]=0.8
	civ.player_relation["met_day"]=0
	civ.player_relation["home_location_known"]=true
	CivilizationSystem.civilizations[civ_index]=civ
	GameState.elapsed_days=1.0
	CivilizationSystem._process_local_observation(1,true)
	var created:Dictionary=MilitaryCampaign.create_field_army(80,"First Pursuit")
	var army_id:=int((created.get("army",{}) as Dictionary).get("army_id",0))
	assert_int(army_id).is_greater(0)
	var neutral:Dictionary=MilitaryCampaign.map_engagement_availability(army_id,String(foreign.id))
	assert_bool(bool(neutral.get("can_order",false))).is_true()
	assert_bool(CivilizationSystem.civilizations[civ_index].player_relation.at_war).is_false()
	var ready:Dictionary=MilitaryCampaign.map_engagement_availability(army_id,String(foreign.id))
	assert_bool(bool(ready.get("can_engage",false))).is_true()
	var launched:Dictionary=MilitaryCampaign.launch_map_engagement(army_id,String(foreign.id))
	assert_bool(bool(launched.get("engagement_started",false))).is_true()
	assert_bool(CivilizationSystem.civilizations[civ_index].player_relation.at_war).is_true()
	assert_bool(MilitaryCampaign.threat_snapshot().is_empty()).is_true()
	var engagement:Dictionary=MilitaryCampaign.engagement_snapshot()
	assert_bool(bool((engagement.get("threat",{}) as Dictionary).get("field_encounter",false))).is_true()
	assert_int(int(engagement.get("home_force_id",0))).is_equal(army_id)
	assert_str(String(engagement.get("home_force_kind",""))).is_equal("field_army")
	assert_str(String((engagement.get("attacker",{}) as Dictionary).get("name",""))).is_equal("First Pursuit")
	assert_array(MilitaryCampaign.validate_state()).is_empty()


func test_field_army_captives_are_removed_from_the_force_that_lost_them()->void:
	var reserve:={"id":1,"unit":"line_infantry","weapon":"spear","count":1000,"authorized_count":1000,"equipment":1000,"equipment_required":1000,"ammunition":0,"ammunition_required":0,"training":0.72,"experience":0.18,"personnel_condition":0.86}
	MilitaryCampaign.home_army=MilitaryCampaign.simulator.create_formation_force("Home reserve",[reserve],0.72,0.70)
	MilitaryCampaign.next_formation_id=2
	var created:Dictionary=MilitaryCampaign.create_field_army(600)
	var field_force:Dictionary=created.army
	var army_id:=int(field_force.army_id)
	var losing_side:Dictionary=field_force.duplicate(true)
	losing_side["remaining_troops"]=600
	losing_side["troops"]=600
	var result:Dictionary={"seed":991,"outcome":"attacker_surrendered","home_side":"attacker","home_force_kind":"field_army","home_force_id":army_id,"campaign_mode":"offensive","attacker":losing_side,"defender":{"name":"Rival host","troops":700,"remaining_troops":700,"dead":0,"morale":0.7},"rounds":[],"termination":{"type":"surrender","captor":"Rival host","defeated":String(field_force.name),"prisoners":100}}
	MilitaryCampaign._commit_campaign_battle(result)
	assert_int(int(MilitaryCampaign.home_army.troops)).is_equal(400)
	assert_int(int(MilitaryCampaign.home_army.get("captured_pool",0))).is_equal(0)
	assert_int(int(MilitaryCampaign.field_armies[0].troops)).is_equal(500)
	assert_int(int(MilitaryCampaign.field_armies[0].captured_pool)).is_equal(100)
	assert_int(MilitaryCampaign._mobilized_count()).is_equal(1000)
	assert_array(MilitaryCampaign.validate_state()).is_empty()


func test_defense_allocation_immediately_mans_watch_and_automates_basic_training()->void:
	GameState.population_exact=500.0
	GameState.population_total=500
	GameState.population_allocations["Defense"]=16
	var defense:=MilitaryCampaign.settlement_defense_snapshot()
	assert_int(int(defense.garrison_personnel)).is_equal(16)
	assert_int(int(defense.garrison_trained)).is_equal(0)
	assert_int(int(defense.garrison_militia)).is_equal(16)
	MilitaryCampaign._ensure_automatic_basic_training()
	assert_int(MilitaryCampaign._automatic_basic_trainees()).is_greater(0)
	assert_bool(bool(MilitaryCampaign.training_queue[0].get("automated_basic",false))).is_true()


func test_supplied_peacetime_home_garrison_does_not_inevitably_desert()->void:
	var levy:={"id":1,"unit":"levy","weapon":"improvised","count":16,"authorized_count":16,"equipment":0,"equipment_required":16,"ammunition":0,"ammunition_required":0,"training":0.48,"experience":0.0,"personnel_condition":1.0}
	MilitaryCampaign.home_army=MilitaryCampaign.simulator.create_formation_force("Home watch",[levy],1.0,0.5)
	MilitaryCampaign.home_army["supply_level"]=1.0
	MilitaryCampaign.home_army["recent_combat_days"]=0
	MilitaryCampaign.home_army["service_strain"]=0.0
	MilitaryCampaign.home_army["desertion_accumulator"]=0.0
	for day in 1000:
		MilitaryCampaign._process_aggregate_service_strain_day()
	assert_int(int(MilitaryCampaign.home_army.troops)).is_equal(16)
	assert_int(int(MilitaryCampaign.home_army.get("desertions_total",0))).is_equal(0)


func test_untrained_local_watch_can_defend_home_before_basic_training_finishes()->void:
	GameState.population_allocations["Defense"]=12
	var enemy:Dictionary=MilitaryCampaign.simulator.create_formation_force("Raiders",[{"id":91,"unit":"levy","weapon":"improvised","count":8,"equipment":0}],0.55,0.35)
	MilitaryCampaign.active_threat={"id":"raid_probe","source_civ_id":"","source_name":"Raiders","campaign_mode":"defensive","enemy_force":enemy,"estimated_strength":8,"terrain_defense":1.0,"seed":991}
	var engagement:=MilitaryCampaign.begin_threat_engagement()
	assert_bool(engagement.has("error")).is_false()
	assert_int(int((engagement.get("defender",{}) as Dictionary).get("troops",0))).is_equal(12)
