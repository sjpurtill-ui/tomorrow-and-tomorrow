extends GdUnitTestSuite
## The war at sea and in the air, run in the live world model (WorldSimulation
## enabled, two owned civilizations "alpha" and "beta" at war): blockades felt
## by the blockaded people, bombing's cost to towns, crews' fates, the ruler's
## authority, repairs, carriers, raiding, landings, named commanders and saves.
const AN=preload("res://scripts/air_naval_consequences.gd")
const Contact=preload("res://scripts/civilization_joint_contact.gd")
const Controller=preload("res://scripts/civilization_controller.gd")
const Blockade=preload("res://scripts/naval_blockade.gd")

var views:Dictionary={}

func before_test()->void:
	WorldSimulation.clear()
	WorldSimulation.context_provider=func(_origin:Vector2)->Dictionary:return {"environment_profile":PlanetEnvironment.profile_at(Vector2.ZERO),"surface_water_distance_km":.1,"surface_water_recognized":true}
	for id in ["alpha","beta"]:
		WorldSimulation.create_actor(id,777,Vector2.ZERO)
		WorldSimulation.actors[id].systems.CivilizationSystem.scout_land_authority=func(_point:Vector2)->bool:return true
		WorldSimulation.actors[id].controller="manual"
	WorldSimulation.enabled=true
	views={}
	for id in ["alpha","beta"]:
		WorldSimulation.scoped(id,func()->void:
			WorldSimulation.state.ensure_population_total(4000)
			WorldSimulation.state.settlement_completed=["Hearth Circle"]
			WorldSimulation.settlements.ensure_founded()
			for item in ["Timber","Stone","Iron Ore","Clay"]:WorldSimulation.state.resource_stockpiles[item]=10000.0
			for discovery in ["aerostat_observation","fighter_tactics","aerial_bombardment","powered_flight","advanced_airframes","river_craft","galley_navigation","naval_torpedoes","armored_hulls"]:
				WorldSimulation.state.known_discoveries.append(discovery);WorldSimulation.state.discovery_adoption[discovery]=1.0
		)
		var civ:=CivilizationSystem.civilizations[0].duplicate(true)
		civ.id=id;civ.name=id.capitalize()
		WorldSimulation.scoped(id,func()->void:WorldSimulation.project(civ))
		views[id]=civ
	for id in ["alpha","beta"]:
		var other:="beta" if id=="alpha" else "alpha"
		var view:Dictionary=(views[other] as Dictionary).duplicate(true)
		view.player_relation={"at_war":true,"opinion":0.0,"contact_level":3}
		WorldSimulation.scoped(id,func()->void:
			WorldSimulation.world.civilizations.assign([view])
			var intel=WorldSimulation.world.city_intelligence
			for region:Dictionary in view.strategic_regions:
				if bool(region.get("settlement_founded",false)):intel.publish("player",intel.capture("player",String(region.id),1.0,0,"test","t"),0)
		)

func after_test()->void:
	WorldSimulation.clear()
	WorldSimulation.context_provider=Callable()

## The enemy's founded city as `observer` knows it.
func _enemy_city(observer:String)->Dictionary:
	return WorldSimulation.scoped(observer,func()->Dictionary:
		var known:Array=WorldSimulation.world.city_intelligence.known_cities("player","",false)
		return known[0] if not known.is_empty() else {}
	)

func _force(owner:String,domain:String,type_id:String,count:int,mission:String)->int:
	return WorldSimulation.scoped(owner,func()->int:
		var op=WorldSimulation.military.joint_operations
		var city:=String(WorldSimulation.state.player_settlements[0].id)
		var base_id:=0
		for base:Dictionary in op.state.bases:
			if String(base.domain)==domain:base_id=int(base.id)
		if base_id==0:
			if domain=="navy":
				op.state.bases.append({"id":op._id(),"owner":"player","city_id":city,"name":"Harbour","domain":"navy","position":{"x":0.0,"z":0.0},"capacity":20,"condition":1.0,"construction_work":30.0,"required_work":30.0})
			else:
				assert_bool(op.build_base(city,"air").has("ok")).is_true()
			base_id=int(op.state.bases.back().id)
			op.state.bases.back().construction_work=30.0
		var units:={};units[type_id]=count
		var id:int=op._id()
		op.state.forces.append({"id":id,"owner":"player","name":"%s %s" % [owner.capitalize(),type_id],"domain":domain,"base_id":base_id,"units":units,"authorized":units.duplicate(),"mission":mission,"region":{},"regions":[],"status":"","training":1.0,"condition":1.0,"experience":0.0,"efficiency":1.0,"auto_replace":false,"repair_threshold":.2,"fuel_used":0,"loss_fraction":0.0,"damage":0.0,"position":{"x":0.0,"z":0.0},"route":[],"carrier_id":0,"fleet_id":id})
		# A drawn zone over the enemy town (the test world has no water to validate).
		var zone:={"id":"area:%d" % op._id(),"domain":domain,"owner":"player","name":"Zone","vertices":op.R.rectangle(Vector2.ZERO,10),"position":{"x":0.0,"z":0.0}}
		op.state.regions.append(zone)
		op.force(id).region=zone.duplicate(true)
		return id
	)

func _sum(values:Dictionary)->int:
	var total:=0
	for value in values.values():total+=int(value)
	return total

# --- 1. Blockades reach the blockaded people -------------------------------------

func test_blockade_is_felt_by_the_blockaded_civilization()->void:
	var city:=_enemy_city("alpha")
	assert_bool(city.is_empty()).is_false()
	WorldSimulation.scoped("alpha",func()->void:
		WorldSimulation.military.joint_operations.state.blockades[String(city.city_id)]={"level":.5,"held":true,"since":1,"day":1,"civ_id":"beta","owner":"player","tactic":"close_blockade","name":"Beta"}
	)
	Contact.share_sea_pressure(1)
	var local:=String(WorldSimulation.actors.beta.systems.GameState.player_settlements[0].id)
	WorldSimulation.scoped("beta",func()->void:
		var military=WorldSimulation.military
		var entry:Dictionary=military.joint_operations.state.blockades.get(local,{})
		assert_bool(bool(entry.get("mirrored",false))).is_true()
		assert_str(String(entry.owner)).is_equal("alpha")
		assert_float(military.port_blockade_level(local)).is_equal_approx(.5,.0001)
		# Trade, sea fish and supply all read it, within the bounds.
		assert_float(military.blockade_trade_factor("player")).is_less(1.0)
		assert_float(military.blockade_trade_factor("player")).is_greater_equal(1.0-Blockade.TRADE_LOSS*Blockade.CLOSE_CAP)
		assert_float(military.joint_operations.sea_trade_factor()).is_less(1.0)
		assert_float(Blockade.sea_food_factor(military.port_blockade_level(local))).is_equal_approx(.75,.0001)
		# The blockaded people's own day keeps the mirrored level as it is.
		military.joint_operations._advance_blockades(2)
		assert_float(military.port_blockade_level(local)).is_equal_approx(.5,.0001)
		# Their armies in the field lose sea supply toward a floor.
		military.field_armies.assign([{"army_id":9,"troops":10,"supply_level":1.0,"position":{"x":0.0,"z":0.0},"formations":[]}])
		for day in 60:military.joint_operations.effects.advance(2+day)
		var floor_level:float=1.0-military.joint_operations.blockade_closure("player")*Blockade.CIV_SUPPLY_LOSS
		assert_float(float(military.field_armies[0].supply_level)).is_equal_approx(floor_level,.0001)
		military.field_armies.clear()
	)
	# The blockader sees the port in its own ledger; the defender sees its own port.
	WorldSimulation.scoped("alpha",func()->void:WorldSimulation.military.joint_operations.state.blockades.clear())
	Contact.share_sea_pressure(3)
	WorldSimulation.scoped("beta",func()->void:
		assert_bool(WorldSimulation.military.joint_operations.state.blockades.has(local)).is_false()
		assert_float(WorldSimulation.military.joint_operations.sea_trade_factor()).is_equal(1.0)
	)

# --- 2 & 3. Bombing towns, and the ruler's authority -------------------------------

func test_bombing_needs_the_rulers_word_and_then_costs_the_town_dearly_but_boundedly()->void:
	var city:=_enemy_city("alpha")
	var id:=_force("alpha","air","tactical_bomber",40,"logistics_strike")
	var before:=int(WorldSimulation.actors.beta.systems.GameState.population_total)
	# No decision: the commander refuses the town, and holds.
	WorldSimulation.scoped("alpha",func()->void:
		var op=WorldSimulation.military.joint_operations
		var refused:Dictionary=op.assign(id,op.force(id).region,"strategic_bombing")
		assert_str(String(refused.get("kind",""))).is_equal("authority")
		op.force(id).mission="strategic_bombing"
		op.effects.advance(1)
		assert_bool(bool(op.force(id).get("held_by_ruler",false))).is_true()
	)
	assert_int(int(WorldSimulation.actors.beta.systems.GameState.population_total)).is_equal(before)
	# The rival ruler decides in council; the human cannot use that path.
	assert_bool(WorldSimulation.military.record_ruler_decision("aerial_bombardment","test").has("error")).is_true()
	WorldSimulation.scoped("alpha",func()->void:
		assert_bool(WorldSimulation.military.record_ruler_decision("aerial_bombardment","Their towns arm their armies.").has("ok")).is_true()
		var op=WorldSimulation.military.joint_operations
		assert_bool(op.assign(id,op.force(id).region,"strategic_bombing").has("ok")).is_true()
		op.force(id).efficiency=1.0
		for day in range(2,32):
			op.force(id).efficiency=1.0
			op.effects.advance(day)
	)
	var beta_state:Object=WorldSimulation.actors.beta.systems.GameState
	var dead:=before-int(beta_state.population_total)
	assert_int(dead).is_greater(0)
	# At most the daily cap for thirty days.
	assert_int(dead).is_less_equal(roundi(4000.0*AN.DEATH_CAP_PER_DAY*30.0)+30)
	var damaged:=0
	for plot:Dictionary in beta_state.settlement_plots:
		if String(plot.get("status","")) in ["damaged","ruin"]:damaged+=1
	assert_int(damaged).is_greater(0)
	assert_float(float(beta_state.simulation_metrics.get("war_fear",0.0))).is_greater(0.0)
	WorldSimulation.scoped("beta",func()->void:
		var relation:=AN.relation("alpha")
		assert_float(float(relation.get("opinion",0.0))).is_less(0.0)
		assert_float(float(relation.get("player_war_exhaustion",0.0))).is_greater(0.0)
		var ledger:Dictionary=WorldSimulation.military.joint_operations.state.war_ledger
		assert_int(int(ledger.alpha.ours.get("civilian_dead",0))).is_equal(dead)
	)
	WorldSimulation.scoped("alpha",func()->void:
		assert_float(float(AN.relation("beta").get("rival_war_exhaustion",0.0))).is_greater(0.0)
		assert_int(int(WorldSimulation.military.joint_operations.state.war_ledger.beta.theirs.get("civilian_dead",0))).is_equal(dead)
	)

func test_bombing_tactic_changes_the_damage_and_early_aircraft_kill_far_fewer()->void:
	var city:=_enemy_city("alpha")
	var night:={"domain":"air","units":{"tactical_bomber":10},"tactic":"night_area_bombing","owner":"player","name":"N"}
	var day_raid:={"domain":"air","units":{"tactical_bomber":10},"tactic":"escorted_day_bombing","owner":"player","name":"D"}
	var outcomes:Array=[]
	for force in [night,day_raid]:
		outcomes.append(WorldSimulation.scoped("alpha",func()->Dictionary:return AN.strike_city(force,city,AN.MAX_STRIKE,"strategic_bombing",true)))
	assert_float(float(outcomes[1].intensity)).is_greater(float(outcomes[0].intensity))
	# Early flight (no heavy airframes) kills about thirty times fewer.
	assert_float(float(AN.CIVILIAN_DEATH_RATE.early_air)*20.0).is_less(float(AN.CIVILIAN_DEATH_RATE.air))

func test_military_strikes_without_authority_hit_defences_and_stores_not_the_town()->void:
	var city:=_enemy_city("alpha")
	WorldSimulation.scoped("beta",func()->void:
		WorldSimulation.military.home_army=WorldSimulation.military.simulator.create_formation_force("Beta",[{"id":1,"unit":"levy","weapon":"improvised","count":300,"equipment":300,"equipment_required":300}],.8,.8)
		WorldSimulation.food.receive_external_food(5000)
	)
	var food_before:float=WorldSimulation.scoped("beta",func()->float:return WorldSimulation.food.total_stored())
	var population_before:=int(WorldSimulation.actors.beta.systems.GameState.population_total)
	var ships:={"domain":"navy","units":{"destroyer":6},"tactic":"","owner":"player","name":"Guns"}
	var troops:=0
	for day in 60:
		troops+=int(WorldSimulation.scoped("alpha",func()->Dictionary:return AN.strike_city(ships,city,AN.MAX_STRIKE,"invasion_support",false)).troops)
	assert_int(troops).is_greater(0)
	WorldSimulation.scoped("beta",func()->void:
		assert_int(int(WorldSimulation.military.home_army.troops)).is_equal(300-troops)
		assert_int(int(WorldSimulation.military.home_army.get("wounded_pool",0))).is_greater(0)
	)
	# No civilian deaths: only soldiers under bombardment died.
	var deaths:=population_before-int(WorldSimulation.actors.beta.systems.GameState.population_total)
	assert_int(deaths).is_less_equal(troops)
	var bombers:={"domain":"air","units":{"tactical_bomber":10},"tactic":"interdiction","owner":"player","name":"B"}
	WorldSimulation.scoped("alpha",func()->void:AN.strike_city(bombers,city,AN.MAX_STRIKE,"logistics_strike",false))
	var food_after:float=WorldSimulation.scoped("beta",func()->float:return WorldSimulation.food.total_stored())
	assert_float(food_after).is_less(food_before)
	assert_float(food_after).is_greater_equal(food_before*(1.0-AN.STORES_LOSS_CAP)-.001)

func test_damaged_buildings_persist_and_are_repaired_then_ruins_rebuilt()->void:
	WorldSimulation.scoped("beta",func()->void:
		var plots:Array=WorldSimulation.state.settlement_plots
		assert_bool(plots.is_empty()).is_false()
		var plot:Dictionary=plots[0]
		plot.status="damaged";plot.condition=.3;plot.pre_damage_use=String(plot.get("land_use",""));plot.damaged_day=0
		WorldSimulation.state.population_allocations["Construction"]=200
		WorldSimulation.settlements._process_occupancy_and_maintenance(30,[] as Array[Dictionary])
		assert_float(float(plot.condition)).is_greater(.3)
		assert_float(float(plot.condition)).is_less(.6)
		assert_str(String(plot.status)).is_equal("damaged")
		for month in range(2,12):WorldSimulation.settlements._process_occupancy_and_maintenance(month*30,[] as Array[Dictionary])
		assert_str(String(plot.status)).is_equal("active")
		plot.status="ruin";plot.condition=0.0;plot.damaged_day=0
		var rebuilt:=false
		for month in range(13,160):
			WorldSimulation.settlements._process_occupancy_and_maintenance(month*30,[] as Array[Dictionary])
			if String(plot.status)!="ruin":rebuilt=true;break
		assert_bool(rebuilt).is_true()
		assert_str(String(plot.status)).is_equal("under_construction")
	)

# --- 4. Repairs to airfields and ports -------------------------------------------

func test_struck_bases_are_repaired_for_materials_and_port_strikes_hit_harbours()->void:
	var city:=_enemy_city("alpha")
	_force("beta","air","fighter",2,"hold")
	_force("beta","navy","destroyer",1,"hold")
	var naval:={"domain":"air","units":{"naval_bomber":8},"tactic":"","owner":"player","name":"Harbour raid"}
	WorldSimulation.scoped("alpha",func()->void:AN.strike_city(naval,city,AN.MAX_STRIKE,"port_strike",false))
	WorldSimulation.scoped("beta",func()->void:
		var op=WorldSimulation.military.joint_operations
		var airfield:Dictionary={};var port:Dictionary={}
		for base:Dictionary in op.state.bases:
			if base.domain=="air":airfield=base
			else:port=base
		assert_float(float(airfield.condition)).is_equal(1.0)
		assert_float(float(port.condition)).is_less(1.0)
		# Knocked out, then rebuilt for timber and stone.
		port.condition=.05;airfield.condition=.05
		assert_bool(op.base_ready(port)).is_false()
		var stone:=float(WorldSimulation.state.resource_stockpiles.Stone)
		for day in 40:op._repair_base(airfield,10.0)
		assert_float(float(airfield.condition)).is_equal(1.0)
		assert_float(float(WorldSimulation.state.resource_stockpiles.Stone)).is_less(stone)
		for day in 40:op._repair_base(port,10.0)
		assert_bool(op.base_ready(port)).is_true()
		assert_float(float(port.condition)).is_less(1.0)
		# Without materials nothing is repaired.
		port.condition=.5
		for item in ["Timber","Stone"]:WorldSimulation.state.resource_stockpiles[item]=0.0
		op._repair_base(port,10.0)
		assert_float(float(port.condition)).is_equal(.5)
	)

# --- 5 & 6. Crews: killed, wounded, rescued, captured -------------------------------

func test_lost_hulls_split_their_crews_and_prisoners_reach_the_captor()->void:
	var id:=_force("alpha","navy","destroyer",4,"patrol")
	var alpha_state=WorldSimulation.actors.alpha.systems.GameState
	var before:int=int(alpha_state.population_total)
	var prisoners_before:=int(WorldSimulation.actors.beta.systems.MilitaryCampaign.foreign_prisoners)
	var recruits_before:=int(WorldSimulation.actors.alpha.systems.MilitaryCampaign.aggregate_recruits)
	WorldSimulation.scoped("alpha",func()->void:
		var op=WorldSimulation.military.joint_operations
		var record:Dictionary=op.force(id)
		record.position={"x":900.0,"z":0.0}
		op._losses(record,2.0*2.5*3.0,"beta","navy")
		assert_int(int(record.units.destroyer)).is_equal(2)
	)
	var military=WorldSimulation.actors.alpha.systems.MilitaryCampaign
	var op=military.joint_operations
	var dead:int=before-int(alpha_state.population_total)
	var wounded:int=op.wounded_count()
	var captured:int=int(military.home_army.get("captured_pool",0))+int(op.state.get("captured_holding",0))
	var rescued:int=int(military.aggregate_recruits)-recruits_before
	# Two destroyers' crews (300), plus those hit aboard the two still afloat:
	# all accounted for, none twice.
	var hit_aboard:=int(op.force(id).get("crew_shortfall",0))
	assert_int(dead+wounded+captured+rescued).is_equal(300+hit_aboard)
	assert_int(hit_aboard).is_less(30)
	assert_int(dead).is_between(100,200)
	assert_int(captured).is_greater(0)
	assert_int(int(WorldSimulation.actors.beta.systems.MilitaryCampaign.foreign_prisoners)-prisoners_before).is_equal(captured)
	# The service's strength still counts the wounded and the prisoners.
	assert_int(op.personnel()).is_greater_equal(2*150+wounded)
	# Wounded recover after the recovery period; some die of their wounds.
	var population_after:int=int(alpha_state.population_total)
	WorldSimulation.scoped("alpha",func()->void:op._advance_wounded(int(alpha_state.elapsed_days)+AN.RECOVERY_DAYS+1))
	assert_int(op.wounded_count()).is_equal(0)
	assert_int(int(alpha_state.population_total)).is_less(population_after)

func test_hits_short_of_a_loss_wound_crews_and_airmen_over_home_are_mostly_saved()->void:
	var id:=_force("alpha","navy","destroyer",4,"patrol")
	WorldSimulation.scoped("alpha",func()->void:
		var op=WorldSimulation.military.joint_operations
		op._losses(op.force(id),3.0,"beta","navy")
		assert_int(int(op.force(id).units.destroyer)).is_equal(4)
		assert_int(int(op.force(id).get("crew_shortfall",0))).is_greater(0)
		assert_int(op.crew(op.force(id))).is_less(600)
	)
	# Profiles: sums are whole, bomber crews over enemy ground are mostly lost.
	for type_id in ["fighter","strategic_bomber","galley","submarine","sailing_frigate"]:
		for own in [true,false]:
			var fate:=AN.crew_casualties(type_id,10,own,7)
			assert_int(int(fate.killed)+int(fate.wounded)+int(fate.captured)+int(fate.rescued)).is_equal(int(fate.people))
	assert_int(int(AN.crew_casualties("strategic_bomber",20,false,1).killed)).is_greater(int(AN.crew_casualties("fighter",140,true,1).killed)/2)
	assert_int(int(AN.crew_casualties("recon_drone",5,false).killed)).is_equal(0)

# --- 7. Rival fleets and wings take the war to the enemy ----------------------------

func test_rival_commanders_aim_offensive_zones_at_known_enemy_towns_and_obey_the_ruler()->void:
	var bombers:=_force("alpha","air","tactical_bomber",10,"hold")
	var ships:=_force("alpha","navy","destroyer",3,"hold")
	WorldSimulation.scoped("alpha",func()->void:
		var op=WorldSimulation.military.joint_operations
		var enemies:=Controller.war_enemies()
		assert_array(enemies).contains(["beta"])
		var aim:=Controller.offensive_target(op,op.force(bombers),op.missions_for(op.force(bombers)),enemies)
		assert_str(String(aim.mission)).is_equal("logistics_strike")
		Controller.ruler_strike_decision("alpha",{"personality":{"empathy":.1,"assertiveness":.9}})
		aim=Controller.offensive_target(op,op.force(bombers),op.missions_for(op.force(bombers)),enemies)
		assert_str(String(aim.mission)).is_equal("strategic_bombing")
		var naval:=Controller.offensive_target(op,op.force(ships),op.missions_for(op.force(ships)),enemies)
		assert_array(["patrol","convoy_raiding"]).contains([String(naval.mission)])
		# A gentle ruler whose towns are untouched does not decide it.
		WorldSimulation.military.sovereign_decisions.clear()
		Controller.ruler_strike_decision("alpha",{"personality":{"empathy":.8,"assertiveness":.9}})
		assert_bool(WorldSimulation.military.sovereign_decisions.is_empty()).is_true()
		# ...but reprisal after its own towns burned does move a middling one.
		WorldSimulation.state.simulation_metrics["war_fear"]=.2
		Controller.ruler_strike_decision("alpha",{"personality":{"empathy":.5,"assertiveness":.4}})
		assert_bool(WorldSimulation.military.sovereign_decisions.has("aerial_bombardment")).is_true()
	)

# --- 8. Air defence and carriers --------------------------------------------------

func test_ground_guns_shoot_down_raiders_within_bounds()->void:
	var city:=_enemy_city("alpha")
	var before_flight:float=WorldSimulation.scoped("beta",func()->float:
		WorldSimulation.state.known_discoveries.erase("powered_flight");WorldSimulation.state.known_discoveries.erase("aerial_bombardment")
		return AN.defence_strength(""))
	assert_float(before_flight).is_equal(0.0)
	WorldSimulation.scoped("beta",func()->void:
		WorldSimulation.state.known_discoveries.append("powered_flight")
		WorldSimulation.military.home_army=WorldSimulation.military.simulator.create_formation_force("Guns",[{"id":1,"unit":"anti_air","weapon":"anti_air_gun","count":200,"equipment":200,"equipment_required":200}],.8,.8)
	)
	var share:float=WorldSimulation.scoped("alpha",func()->float:return AN.ground_fire_share(city))
	assert_float(share).is_greater(AN.AA_BASELINE)
	assert_float(share).is_less_equal(AN.AA_BASELINE+AN.AA_LOSS_CAP)
	var id:=_force("alpha","air","tactical_bomber",40,"logistics_strike")
	WorldSimulation.scoped("alpha",func()->void:
		var op=WorldSimulation.military.joint_operations
		for day in 120:op.ground_fire(op.force(id),share,"beta")
		var left:=int(op.force(id).units.tactical_bomber)
		assert_int(left).is_less(40)
		# Four months under the heaviest guns: no more than about three in five lost.
		assert_int(left).is_greater(14)
	)

func test_a_sunk_carrier_takes_most_of_its_wings_with_it()->void:
	var carrier:=_force("alpha","navy","aircraft_carrier",1,"strike_force")
	var wing:=_force("alpha","air","fighter",30,"air_superiority")
	WorldSimulation.scoped("alpha",func()->void:
		var op=WorldSimulation.military.joint_operations
		op.force(wing).carrier_id=carrier
		op.force(carrier).position={"x":2000.0,"z":0.0}
		# Half the carriers' decks lost: the overflow goes over the side.
		op.force(carrier).units.aircraft_carrier=1
		op._overloaded_decks()
		assert_int(int(op.force(wing).units.fighter)).is_equal(30)
		op.force(carrier).units.aircraft_carrier=0
		op._deck_lost(op.force(wing),1.0)
		assert_int(int(op.force(wing).units.fighter)).is_equal(0)
	)
	var events:Array=WorldSimulation.actors.alpha.systems.MilitaryCampaign.joint_operations.state.events
	assert_str(String(events[0].text)).contains("with its carrier")

func test_close_support_aircraft_over_a_battle_take_ground_fire()->void:
	var id:=_force("alpha","air","close_air_support",30,"close_air_support")
	WorldSimulation.scoped("alpha",func()->void:
		var op=WorldSimulation.military.joint_operations
		WorldSimulation.military.active_engagement={"id":"fight"}
		for day in 60:
			op.force(id).efficiency=1.0
			op.effects.advance(day+1)
		WorldSimulation.military.active_engagement={}
		assert_int(int(op.force(id).units.close_air_support)).is_less(30)
	)

# --- 9. Named commanders ---------------------------------------------------------

func test_fleets_get_named_admirals_who_can_fall_with_their_ships()->void:
	var id:=_force("alpha","navy","destroyer",2,"patrol")
	WorldSimulation.scoped("alpha",func()->void:
		var op=WorldSimulation.military.joint_operations
		op.ensure_commander(op.force(id))
		var named:Dictionary=op.force(id).get("commander",{})
		assert_bool(named.is_empty()).is_false()
		var person:Dictionary=WorldSimulation.figures.by_id(String(named.figure_id))
		assert_str(String(person.role)).is_equal("Admiral")
		op.force(id).position={"x":900.0,"z":0.0}
		op._losses(op.force(id),100.0,"beta","navy")
		assert_int(op.hardware(op.force(id))).is_equal(0)
		person=WorldSimulation.figures.by_id(String(named.figure_id))
		assert_array(["living","dead","captured","wounded"]).contains([String(person.status)])
		assert_bool((person.events as Array).size()>=2).is_true()
	)

# --- 10. Commerce raiding and landings --------------------------------------------

func test_raiders_cut_the_targets_sea_trade_and_escorts_blunt_them()->void:
	var raider:=_force("alpha","navy","submarine",6,"convoy_raiding")
	Contact.share_sea_pressure(1)
	var open_sea:float=WorldSimulation.scoped("beta",func()->float:return float(WorldSimulation.military.joint_operations.merchant_loss()))
	assert_float(open_sea).is_greater(0.0)
	assert_float(open_sea).is_less_equal(AN.MERCHANT_LOSS_CAP)
	assert_float(float((WorldSimulation.actors.alpha.systems.MilitaryCampaign.joint_operations.state.get("raids_out",{}) as Dictionary).get("beta",0.0))).is_equal_approx(open_sea,.0001)
	_force("beta","navy","destroyer",6,"convoy_escort")
	Contact.share_sea_pressure(2)
	var escorted:float=WorldSimulation.scoped("beta",func()->float:return float(WorldSimulation.military.joint_operations.merchant_loss()))
	assert_float(escorted).is_less(open_sea)
	WorldSimulation.scoped("alpha",func()->void:WorldSimulation.military.joint_operations.force(raider).mission="hold")
	Contact.share_sea_pressure(3)
	assert_float(WorldSimulation.scoped("beta",func()->float:return float(WorldSimulation.military.joint_operations.sea_trade_factor()))).is_equal(1.0)

func test_an_opposed_landing_costs_both_sides_and_a_strong_beach_throws_it_back()->void:
	var city:=_enemy_city("alpha")
	WorldSimulation.scoped("beta",func()->void:
		WorldSimulation.military.home_army=WorldSimulation.military.simulator.create_formation_force("Beta",[{"id":1,"unit":"levy","weapon":"improvised","count":400,"equipment":400,"equipment_required":400}],.8,.8)
	)
	# What the beach is defended with: the garrison in the town as it stands.
	WorldSimulation.scoped("alpha",func()->void:
		for region:Dictionary in WorldSimulation.world.civilizations[0].strategic_regions:
			if String(region.id)==String(city.city_id):region.garrison=400
	)
	var convoy:={"destination_owner":String(city.get("controller",city.civ_id)),"destination_id":String(city.city_id)}
	var weak:={"army_id":1,"name":"Landing force","troops":1000,"formations":[{"count":1000}]}
	# Who stood there for them: their levy, their watch and their townsfolk
	# (civilization_combat.guard_of), each hit by its share.
	var stood:Dictionary=WorldSimulation.scoped("beta",func()->Dictionary:
		var home:Dictionary={}
		for town:Dictionary in WorldSimulation.state.player_settlements:
			if bool(town.get("primary",false)):home=town
		return preload("res://scripts/civilization_combat.gd").guard_of(home))
	var everyone:=int(stood.trained)+int(stood.watch)+int(stood.rise)
	var outcome:Dictionary=WorldSimulation.scoped("alpha",func()->Dictionary:return AN.opposed_landing(weak,convoy,.5))
	assert_bool(bool(outcome.repulsed)).is_false()
	var lost:=int(outcome.attacker_killed)+int(outcome.attacker_wounded)
	assert_int(lost).is_between(20,350)
	assert_int(int(weak.troops)).is_equal(1000-lost)
	assert_int(int(outcome.defender_hit)).is_greater(0)
	var trained_hit:=roundi(float(outcome.defender_hit)*400.0/float(everyone))
	assert_int(int(WorldSimulation.actors.beta.systems.MilitaryCampaign.home_army.troops)).is_equal(400-trained_hit)
	var small:={"army_id":2,"name":"Raid","troops":30,"formations":[{"count":30}]}
	var thrown:Dictionary=WorldSimulation.scoped("alpha",func()->Dictionary:return AN.opposed_landing(small,convoy,0.0))
	assert_bool(bool(thrown.repulsed)).is_true()

# --- 11. What each side is told, and the Chronicle ---------------------------------

func test_the_human_chronicle_tells_big_losses_and_folds_the_rest_into_the_year()->void:
	var chronicle:=preload("res://scripts/chronicle.gd")
	AN.note_losses("player","",{"military_dead":180,"wounded":40,"captured":20},{"sunk":1,"crew":300,"force":"Home Fleet","type_label":"Destroyers"})
	var found:=false
	for entry:Dictionary in chronicle.entries("notice"):
		if String(entry.title)=="Home Fleet Lost":found=true
	assert_bool(found).is_true()
	AN.note_losses("player","",{"military_dead":1},{"downed":1,"crew":1,"force":"Wing"})
	var totals:Dictionary=chronicle.data().year_acc.get("war_losses",{})
	assert_int(int(totals.get("sunk",0))).is_equal(1)
	assert_int(int(totals.get("downed",0))).is_equal(1)
	var lines:Array=[]
	preload("res://scripts/chronicle_years.gd")._war_at_sea_and_air({"war_losses":totals},{"era":"annals","recent":{},"used":[],"seed":1},lines)
	assert_bool(lines.is_empty()).is_false()
	assert_str(String(lines[0].text)).contains("1 ship")

# --- 12. Saves ------------------------------------------------------------------

func test_new_state_saves_and_bad_fields_are_rejected_old_saves_load()->void:
	var id:=_force("alpha","navy","destroyer",4,"patrol")
	WorldSimulation.scoped("alpha",func()->void:
		var op=WorldSimulation.military.joint_operations
		op.force(id).position={"x":900.0,"z":0.0}
		op._losses(op.force(id),30.0,"beta","navy")
		op.state.raiding={"level":.2,"by":["beta"],"day":1,"since":1,"carry":.3}
		var saved:Dictionary=bytes_to_var(var_to_bytes(op.export_state()))
		assert_str(op.validate(saved)).override_failure_message(op.validate(saved)).is_equal("")
		op.import_state(saved)
		assert_int(op.wounded_count()).is_greater(0)
		assert_float(float(op.state.raiding.level)).is_equal(.2)
		var bad:Dictionary=saved.duplicate(true);bad.forces[0]["tactic"]="teleport"
		assert_str(op.validate(bad)).is_not_empty()
		bad=saved.duplicate(true);bad.forces[0]["mission_destination"]={"x":"n"}
		assert_str(op.validate(bad)).is_not_empty()
		bad=saved.duplicate(true);bad.blockades["x"]={"level":5.0}
		assert_str(op.validate(bad)).is_not_empty()
		bad=saved.duplicate(true);bad.wounded=[{"due":1,"count":2,"fatal":5}]
		assert_str(op.validate(bad)).is_not_empty()
		var old:Dictionary=saved.duplicate(true)
		for key in ["wounded","captured_holding","raiding","raids_out","war_ledger"]:old.erase(key)
		for force:Dictionary in old.forces:
			for key in ["crew_shortfall","commander","strike_carry","held_by_ruler"]:force.erase(key)
		assert_str(op.validate(old)).override_failure_message(op.validate(old)).is_equal("")
	)

# --- A fast multi-year war check -------------------------------------------------
## Two owned civilizations at war run their fleets and air wings day by day
## through the ordinary joint-operations day, the shared contact step and their
## rulers' monthly service orders (whole civilization days are not run: the
## fast surrogate). Prints both sides' losses and checks they stay in bounds.
const YEARS:=3

func _coast(point:Vector2)->bool:return point.x<25.0

func _setup_sides()->void:
	for id in ["alpha","beta"]:
		WorldSimulation.actors[id].systems.CivilizationSystem.scout_land_authority=func(point:Vector2)->bool:return _coast(point)
		WorldSimulation.scoped(id,func()->void:
			var military=WorldSimulation.military
			military.joint_operations.geography.land_query=func(point:Vector2)->bool:return _coast(point)
			military.military_consumables["fuel"]=10000000
			# A declared war, so air and sea losses reach its record monthly.
			var enemy:="beta" if id=="alpha" else "alpha"
			AN.relation(enemy)["war_id"]=WorldSimulation.world._start_war("player",enemy,"limited","",0,"test")
			# Repair yards stocked with everything the hulls and airframes are built of.
			for type_id:String in military.joint_operations.C.UNITS:
				for material:String in preload("res://scripts/goods_bills.gd").flatten(military.joint_operations.C.UNITS[type_id].materials):WorldSimulation.state.resource_stockpiles[material]=1000000.0
			WorldSimulation.state.known_discoveries.append("submersible_hulls");WorldSimulation.state.discovery_adoption["submersible_hulls"]=1.0
			military.home_army=military.simulator.create_formation_force(id.capitalize(),[{"id":1,"unit":"levy","weapon":"improvised","count":300,"equipment":300,"equipment_required":300},{"id":2,"unit":"anti_air","weapon":"anti_air_gun","count":60 if id=="beta" else 20,"equipment":60,"equipment_required":60}],.8,.8)
		)
	for spec in [["alpha","air","tactical_bomber",30],["alpha","air","fighter",20],["alpha","navy","destroyer",6],["alpha","navy","submarine",4],
			["beta","air","fighter",24],["beta","air","tactical_bomber",12],["beta","navy","destroyer",6]]:
		var id:=_force(String(spec[0]),String(spec[1]),String(spec[2]),int(spec[3]),"hold")
		WorldSimulation.scoped(String(spec[0]),func()->void:
			var op=WorldSimulation.military.joint_operations
			var record:Dictionary=op.force(id)
			record.region={};record.regions=[]
			if record.domain=="navy":
				var harbour:Dictionary=op.base(int(record.base_id))
				harbour.position={"x":26.0,"z":0.0};record.position={"x":26.0,"z":0.0}
		)

func test_three_years_of_war_at_sea_and_in_the_air_stay_in_bounds()->void:
	_setup_sides()
	var plans:={"alpha":{"personality":{"empathy":.1,"openness":.3,"discipline":.6,"assertiveness":.9},"at_war":true,"offensive":true},
		"beta":{"personality":{"empathy":.55,"openness":.5,"discipline":.6,"assertiveness":.4},"at_war":true,"offensive":false}}
	var start:={}
	for id in ["alpha","beta"]:start[id]=int(WorldSimulation.actors[id].systems.GameState.population_total)
	var missions_seen:={"alpha":{},"beta":{}}
	var blockade_peak:={"alpha":0.0,"beta":0.0}
	var raiding_peak:={"alpha":0.0,"beta":0.0}
	for day in range(1,YEARS*365+1):
		for id in ["alpha","beta"]:
			WorldSimulation.scoped(id,func()->void:
				WorldSimulation.state.elapsed_days=day
				if day%30==1:Controller.service_orders(id,plans[id])
				var op=WorldSimulation.military.joint_operations
				op.advance(day)
				for force:Dictionary in op.state.forces:
					if String(force.mission)!="hold":missions_seen[id][String(force.mission)]=true
			)
		Contact.advance(day)
		for id in ["alpha","beta"]:
			var op=WorldSimulation.actors[id].systems.MilitaryCampaign.joint_operations
			blockade_peak[id]=maxf(float(blockade_peak[id]),float(op.blockade_closure("player")))
			raiding_peak[id]=maxf(float(raiding_peak[id]),float(op.merchant_loss()))
	var summary:=PackedStringArray()
	var totals:={}
	for id in ["alpha","beta"]:
		var state=WorldSimulation.actors[id].systems.GameState
		var military=WorldSimulation.actors[id].systems.MilitaryCampaign
		var op=military.joint_operations
		var civilians:=0;var crew:=0;var wounds:=0
		for entry:Dictionary in state.demographic_ledger:
			if String(entry.get("kind",""))!="death":continue
			match String(entry.get("cause","")):
				"Civilian deaths in war","Lost at sea":civilians+=int(entry.get("count",0))
				"Lost at sea (crew)":crew+=int(entry.get("count",0))
		var war:Dictionary=WorldSimulation.actors[id].systems.CivilizationSystem.war_history[0]
		var ours:Dictionary=(war.get("casualties",{}) as Dictionary).get("player",{})
		var theirs:Dictionary=(war.get("casualties",{}) as Dictionary).get("beta" if id=="alpha" else "alpha",{})
		summary.append("%s war record: ours %s; theirs %s; %d monthly air and sea entries" % [id,str(ours),str(theirs),int(war.get("battle_count",0))])
		var hardware:=0
		for force:Dictionary in op.state.forces:hardware+=op.hardware(force)
		var damaged:=0
		for plot:Dictionary in state.settlement_plots:
			if String(plot.get("status","")) in ["damaged","ruin"]:damaged+=1
		var commanders:=PackedStringArray()
		for person:Dictionary in WorldSimulation.actors[id].systems.HistoricalFigures.people:
			if String(person.role) in ["Admiral","Air Commander"]:commanders.append("%s %s (%s)" % [person.role,person.name,person.status])
		totals[id]={"civilians":int(ours.get("civilian_dead",0)),"crew_dead":int(ours.get("military_dead",0)),"dead":int(start[id])-int(state.population_total),"wounded_pool":op.wounded_count(),"captured":int(military.home_army.get("captured_pool",0))+int(op.state.get("captured_holding",0)),"prisoners_held":int(military.foreign_prisoners),"hardware":hardware,"damaged_plots":damaged}
		summary.append("%s: people dead %d of %d; wounded crews recovering %d; crews held by the enemy %d; enemy prisoners held %d; hulls and airframes left %d; buildings damaged or ruined %d; peak blockade closure %.2f; peak raiding loss %.2f; sea trade now %.2f; missions flown %s; commanders %s; war exhaustion %.3f; opinion of the enemy %.2f" % [id,int(totals[id].dead),int(start[id]),int(totals[id].wounded_pool),int(totals[id].captured),int(totals[id].prisoners_held),hardware,damaged,float(blockade_peak[id]),float(raiding_peak[id]),float(op.sea_trade_factor()),", ".join(PackedStringArray((missions_seen[id] as Dictionary).keys())),"; ".join(commanders),float(_relation(id).get("player_war_exhaustion",0.0)),float(_relation(id).get("opinion",0.0))])
		for force:Dictionary in op.state.forces:summary.append("  %s: %s, %s, %d left, condition %.2f" % [String(force.name),String(force.mission),String(force.status),op.hardware(force),float(force.condition)])
		var events:=PackedStringArray()
		for event:Dictionary in (op.state.events as Array).slice(0,12):events.append("  day %d: %s" % [int(event.day),String(event.text)])
		summary.append("\n".join(events))
	print("AIR-NAVAL WAR CHECK\n"+"\n".join(summary))
	# Both sides lost crews and townspeople; civilian deaths from bombing and
	# shelling stay inside the heaviest historical campaigns (about 3% of a city
	# a year at the worst); every death is a real person gone from the people.
	for id in ["alpha","beta"]:
		assert_int(int(totals[id].dead)).is_greater(0)
		assert_int(int(totals[id].civilians)).is_less_equal(roundi(float(start[id])*.03*YEARS))
		assert_int(int(totals[id].crew_dead)+int(totals[id].civilians)).is_less_equal(int(totals[id].dead))
	assert_int(int(totals.alpha.crew_dead)+int(totals.beta.crew_dead)).is_greater(0)
	assert_int(int(totals.alpha.captured)+int(totals.beta.captured)).is_greater(0)
	assert_int(int(totals.alpha.captured)).is_equal(int(totals.beta.prisoners_held))
	# The hard ruler's commanders took the war to the enemy's towns and waters.
	assert_bool((missions_seen.alpha as Dictionary).has("strategic_bombing")).is_true()
	assert_bool((missions_seen.alpha as Dictionary).has("convoy_raiding") or (missions_seen.alpha as Dictionary).has("patrol")).is_true()
	# The gentler ruler struck back at the towns only after its own burned.
	var beta_decision:Dictionary=WorldSimulation.actors.beta.systems.MilitaryCampaign.sovereign_decisions.get("aerial_bombardment",{})
	if not beta_decision.is_empty():assert_str(String(beta_decision.spoken)).contains("burned")
	assert_float(float(raiding_peak.beta)).is_less_equal(AN.MERCHANT_LOSS_CAP)

func _relation(id:String)->Dictionary:
	return WorldSimulation.scoped(id,func()->Dictionary:return AN.relation("beta" if id=="alpha" else "alpha"))

func test_air_transports_are_hunted_by_interceptors_and_ai_can_order_a_landing()->void:
	var hunters:=_force("beta","air","fighter",20,"interception")
	var lift:=_force("alpha","air","transport_aircraft",10,"transport")
	WorldSimulation.scoped("alpha",func()->void:
		var op=WorldSimulation.military.joint_operations
		var record:Dictionary=op.force(lift)
		record.region=op.region_at(Vector2.ZERO,"air")
		op.state.convoys.append({"id":op._id(),"owner":"player","force_id":lift,"source_base":int(record.base_id),"destination_id":"x","destination_owner":"player","destination_position":{"x":500.0,"z":0.0},"position":{"x":0.0,"z":0.0},"route":[{"x":500.0,"z":0.0}],"food":100.0,"army_id":0,"status":"outbound","depart_day":0,"initial_hardware":10,"last_hardware":10,"invasion":false,"delivered":0.0})
		for day in 30:
			record.efficiency=1.0;record.position={"x":0.0,"z":0.0};op.state.convoys.back().position={"x":0.0,"z":0.0}
			op.logistics.advance(day+1)
		assert_int(op.hardware(record)).is_less(10)
		# The rival's validated order reaches the same transport rules as the player's.
		var refused:=preload("res://scripts/civilization_orders.gd").execute({"kind":"transport","force":lift,"destination":"nowhere","army":0})
		assert_bool(refused.has("error")).is_true()
	)
	assert_int(hunters).is_greater(0)

func test_soldiers_on_a_lost_transport_drown_or_are_saved_and_the_chronicle_tells_it()->void:
	var military=MilitaryCampaign
	var saved_armies:Array=military.field_armies.duplicate(true)
	var recruits:=int(military.aggregate_recruits)
	var population:=int(GameState.population_total)
	military.field_armies.append({"army_id":9901,"name":"The Second Host","troops":200,"embarked":true,"status":"embarked","formations":[{"count":200,"equipment":200,"ammunition":0}],"position":{"x":0.0,"z":0.0}})
	var lost:int=military.apply_transport_casualties(9901,.5,"")
	var army:Dictionary=military.field_armies[military._field_army_index(9901)]
	assert_int(lost).is_equal(100)
	var drowned:=population-int(GameState.population_total)
	assert_int(drowned).is_between(40,50)
	assert_int(int(army.get("wounded_pool",0))).is_equal(10)
	assert_int(int(military.aggregate_recruits)-recruits).is_equal(100-drowned-10)
	var told:=false
	for entry:Dictionary in preload("res://scripts/chronicle.gd").entries("notice"):
		if String(entry.title)=="Transports Went Down":told=true
	assert_bool(told).is_true()
	military.field_armies.assign(saved_armies)
	military.aggregate_recruits=recruits
