extends GdUnitTestSuite
const K=preload("res://scripts/armor_knowledge.gd")
const A=preload("res://scripts/armor_equipment.gd")
const I=preload("res://scripts/civilian_industry.gd")
const P=preload("res://scripts/persistent_production.gd")
const C=preload("res://scripts/civilization_controller.gd")
const Strategy=preload("res://scripts/civilization_strategy.gd")
const Bills=preload("res://scripts/goods_bills.gd")
const PRODUCTS=["fitted_shields","bronze_armor_plates","iron_armor_plates","padded_armor","lamellar_armor","scale_armor","mail_armor","forged_plate_armor","sheet_plate_armor"]
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("armor",4986)
func after_test()->void:
	WorldSimulation.clear();GameState.set_process(true);CivilizationSystem.set_process(true);MilitaryCampaign.set_process(true)
func know(id:String)->void:
	if id not in WorldSimulation.state.known_discoveries:WorldSimulation.state.known_discoveries.append(id)
	WorldSimulation.state.discovery_adoption[id]=1.0
func setup()->void:
	var s=WorldSimulation.state
	s.settlement_site_committed=true;s.convoy_traveling=false
	s.population_allocations.Crafting=20;s.population_health=1.0;s.simulation_metrics.labor_efficiency=1.0
	know("hafted_weapons");know("shield_wall")
func plan()->Dictionary:
	var p:=Strategy.preferences({}, {"food_days":120,"food_intake_ratio":1.0,"at_war":false})
	p.offensive=false;return p
## Stocks a kit's flattened bill (raw materials and Civilian Goods) for a few
## items and starts one line.
func stock_bill(item:String,items:float=3.0)->Dictionary:
	know(String(A.KITS[item].gate))
	var recipe:=P.recipe(WorldSimulation.military,item)
	assert_bool(recipe.has("error")).override_failure_message(str(recipe)).is_false()
	for resource:String in recipe.materials:WorldSimulation.state.resource_stockpiles[resource]=maxf(100.0,float(recipe.materials[resource])*items)
	for resource:String in recipe.get("tooling",{}):WorldSimulation.state.resource_stockpiles[resource]=maxf(100.0,float(recipe.tooling[resource])+1.0)
	return recipe
func provision(item:String)->Dictionary:
	stock_bill(item)
	var started:=WorldSimulation.military.start_production_line(item,1)
	assert_bool(started.get("ok",false)).override_failure_message(str(started)).is_true()
	return WorldSimulation.military.equipment_queue.back()
func formation(weapon:String,issued:int,unit:String="spearman",count:int=20)->Dictionary:
	return {"unit":unit,"weapon":weapon,"count":count,"authorized_count":count,"equipment":issued,"training":1.0,"experience":0.0}
func test_authored_branches_retain_material_and_forming_alternatives()->void:
	WorldSimulation.scoped("armor",func()->void:
		assert_int(K.entries().size()).is_equal(6)
		assert_array(preload("res://scripts/technology_catalog_contract.gd").validate(K.entries(),WorldSimulation.discovery.technology_catalog)).is_empty()
		var T=preload("res://scripts/technology_requirements.gd")
		var lamellar:Dictionary=WorldSimulation.discovery.discovery_definition("lamellar_armor_assembly")
		assert_bool(T.evaluate(lamellar,["cordage","bronze_alloying"]).ready).is_true()
		assert_bool(T.evaluate(lamellar,["cordage","hardened_edges"]).ready).is_true()
		assert_bool(T.evaluate(lamellar,["cordage"]).ready).is_false()
		var plate:Dictionary=WorldSimulation.discovery.discovery_definition("articulated_plate_armor")
		assert_bool(T.evaluate(plate,["hardened_edges","standard_measures","structural_load_testing"]).ready).is_true()
		assert_bool(T.evaluate(plate,["hardened_edges","standard_measures","sheet_steel_rolling"]).ready).is_true())
func test_armor_parts_are_not_lines_and_kits_bill_only_raw_materials_and_goods()->void:
	WorldSimulation.scoped("armor",func()->void:
		setup();var host=WorldSimulation.military
		for item:String in PRODUCTS:
			know(String(I.product(item).gate))
			assert_str(String(P.recipe(host,item).get("error",""))).override_failure_message(item).is_equal(P.CIVILIAN_ERROR)
			assert_bool(host.start_production_line(item,1).has("error")).override_failure_message(item).is_true()
		for item:String in A.KITS:
			var recipe:=stock_bill(item)
			assert_float(float(recipe.materials.get(Bills.Goods.GOODS,0.0))).override_failure_message(item).is_greater(0.0)
			for resource:String in recipe.materials:
				assert_bool(Bills.manufactured(resource)).override_failure_message(item+" names part "+resource).is_false())
func test_kits_consume_their_flattened_bill_and_enter_matching_inventory()->void:
	WorldSimulation.scoped("armor",func()->void:
		setup()
		for item:String in A.KITS:
			var spec:Dictionary=A.KITS[item];var job:=provision(item)
			var before:Dictionary=WorldSimulation.state.resource_stockpiles.duplicate(true)
			P.advance(WorldSimulation.military,job,float(spec.days))
			assert_int(int(WorldSimulation.military.military_inventory[item])).override_failure_message(item).is_equal(1)
			for resource:String in job.materials:
				assert_float(float(before[resource])-float(WorldSimulation.state.resource_stockpiles[resource])).override_failure_message(item+" "+resource).is_equal_approx(float(job.materials[resource]),.000001)
			WorldSimulation.military.cancel_equipment_job(int(job.id)))
func test_missing_inputs_or_unlearned_method_cannot_create_kits()->void:
	WorldSimulation.scoped("armor",func()->void:
		setup();var host=WorldSimulation.military
		assert_bool(host.start_production_line("plate_spear",1).has("error")).is_true()
		var job:=provision("plate_spear")
		WorldSimulation.state.resource_stockpiles[Bills.Goods.GOODS]=0.0
		var before:Dictionary=WorldSimulation.state.resource_stockpiles.duplicate(true)
		P.advance(host,job,100)
		assert_dict(WorldSimulation.state.resource_stockpiles).is_equal(before)
		assert_int(int(host.military_inventory.plate_spear)).is_equal(0))
func test_zero_partial_full_armor_and_penetration_follow_issued_kit_fraction()->void:
	var sim:=CombatSimulator.new()
	for item:String in A.KITS:
		for issued:int in [0,10,20]:
			var f:=formation(item,issued)
			var force:=sim.create_formation_force("Armor",[f])
			assert_float(float(force.armor)).is_equal_approx(float(A.KITS[item].armor)*issued/20.0,.000001)
			assert_float(float(force.penetration)).is_equal_approx(.55*issued/20.0,.000001)
			assert_float(sim._enemy_penetration([f])).is_equal_approx(.55*issued/20.0,.000001)
			var evaluation:Dictionary=sim.evaluate_force(force,{"formations":[]})[0]
			var normalized_defense:=float(evaluation.defense)/(.35+.65*issued/20.0)
			var baseline:=1.18*float(A.KITS[item].defense)*.94
			assert_float(normalized_defense).is_equal_approx(baseline*(1+float(A.KITS[item].armor)*issued/20.0*.35),.000001)
			if issued==0:
				var bare:=sim.create_formation_force("Bare",[formation("spear",0)])
				assert_float(float(evaluation.defense)).is_equal(float(sim.evaluate_force(bare,{"formations":[]})[0].defense))
func test_penetration_reduces_armor_advantage_and_missing_armor_has_none()->void:
	var sim:=CombatSimulator.new()
	var defender:=sim.create_formation_force("Plate",[formation("plate_spear",20)])
	var low:={"formations":[formation("bow",20,"archer")]}
	var high:={"formations":[formation("armored_vehicle",4,"armored_formation")]}
	assert_float(float(sim.evaluate_force(defender,low)[0].defense)).is_greater(float(sim.evaluate_force(defender,high)[0].defense))
	var empty_plate:=sim.create_formation_force("Empty plate",[formation("plate_spear",0)])
	var empty_spear:=sim.create_formation_force("Empty spear",[formation("spear",0)])
	assert_float(float(sim.evaluate_force(empty_plate,low)[0].defense)).is_equal(float(sim.evaluate_force(empty_spear,low)[0].defense))
func test_existing_personnel_and_crew_equipment_retain_full_values()->void:
	var sim:=CombatSimulator.new()
	for item:String in ["sword_shield","lance","chariot_kit","armored_vehicle","field_gun"]:
		var required:=sim.equipment_required_for_weapon(item,40)
		for fraction:float in [0.0,.5,1.0]:
			var issued:=floori(required*fraction)
			var f:=formation(item,issued,"levy",40)
			assert_float(sim.issued_equipment_ratio(f)).is_equal_approx(float(issued)/required,.000001)
			var force:=sim.create_formation_force("Existing",[f])
			assert_float(float(force.armor)).is_equal_approx(float(sim.WEAPONS[item].armor)*issued/required,.000001)
			assert_float(float(force.penetration)).is_equal_approx(float(sim.WEAPONS[item].penetration)*issued/required,.000001)
func test_same_unit_selection_uses_supplied_armor_and_preserves_cheap_fallback()->void:
	WorldSimulation.scoped("armor",func()->void:
		setup();var host=WorldSimulation.military;var p:=plan()
		WorldSimulation.state.resource_stockpiles.clear();host.military_inventory.spear=20
		know("articulated_plate_armor")
		assert_str(A.selection(host,"spearman",p)).is_equal("spear")
		host.military_inventory.plate_spear=20
		assert_str(A.selection(host,"spearman",p)).is_equal("plate_spear")
		WorldSimulation.state.known_discoveries.erase("articulated_plate_armor")
		assert_str(A.selection(host,"spearman",p)).is_equal("spear")
		assert_bool(host._training_gate("archer","plate_spear").has("error")).is_true())
func test_controller_orders_armor_kits_while_recruiting_with_ready_spears()->void:
	WorldSimulation.scoped("armor",func()->void:
		setup();var host=WorldSimulation.military;var p:=plan()
		know("articulated_plate_armor");host.military_inventory.spear=20;host.aggregate_recruits=4
		stock_bill("plate_spear",8.0)
		var next:=A.investment(host,"spearman","spear",4,p)
		assert_str(String(next.get("item",""))).is_equal("plate_spear")
		C.land_training_orders("armor","spearman","spear",4,p)
		assert_int(host.training_queue.size()).is_equal(1)
		assert_str(host.training_queue[0].weapon).is_equal("spear")
		assert_int(int(host.military_inventory.get("plate_spear",0))).is_equal(0)
		var kit_lines:Array=host.equipment_queue.filter(func(job:Dictionary)->bool:return String(job.item)=="plate_spear")
		assert_int(kit_lines.size()).is_equal(1)
		P.advance(host,kit_lines[0],6)
		assert_int(int(host.military_inventory.get("plate_spear",0))).is_equal(1)
		assert_str(A.selection(host,"spearman",p)).is_equal("plate_spear"))
func test_impossible_or_paused_kit_line_has_no_investment()->void:
	WorldSimulation.scoped("armor",func()->void:
		setup();know("mail_armor_fabrication")
		WorldSimulation.state.resource_stockpiles.clear()
		assert_dict(A.upstream(WorldSimulation.military,"mail_spear",4)).is_empty()
		var job:=provision("mail_spear");job.paused=true
		assert_dict(A.upstream(WorldSimulation.military,"mail_spear",4)).is_empty()
		job.paused=false
		assert_str(String(A.upstream(WorldSimulation.military,"mail_spear",4).get("item",""))).is_equal("mail_spear"))
func test_player_training_issues_only_matching_manufactured_kits()->void:
	WorldSimulation.scoped("armor",func()->void:
		setup();var host=WorldSimulation.military
		for item:String in A.KITS:
			know(String(A.KITS[item].gate));host.aggregate_recruits=4;host.military_inventory[item]=3
			var result:=host.start_training("spearman",item,4)
			assert_int(int(result.get("accepted",0))).is_equal(4)
			var training:Dictionary=host.training_queue.back()
			host._complete_training(training);host.training_queue.clear()
			assert_int(int(host.military_inventory[item])).is_equal(0)
			var f:Dictionary=host.home_army.formations.back()
			assert_str(f.weapon).is_equal(item);assert_int(int(f.count)).is_equal(4);assert_int(int(f.equipment)).is_equal(3)
		assert_array(host.validate_state()).is_empty())
func test_full_save_retains_partial_armor_job_kits_and_formation_identity()->void:
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	WorldSimulation.scoped("armor",func()->void:
		setup();var host=WorldSimulation.military;var job:=provision("mail_spear")
		P.advance(host,job,2)
		host.military_inventory.mail_spear=2;host.damaged_equipment.mail_spear=1
		host.aggregate_recruits=4
		var order:=host.start_training("spearman","mail_spear",4)
		assert_int(int(order.get("accepted",0))).is_equal(4)
		host._complete_training(host.training_queue.back());host.training_queue.clear()
		assert_array(host.validate_state()).is_empty())
	var slot:="armor_%d"%OS.get_process_id()
	assert_bool(SaveSystem.save_game(slot).get("ok",false)).is_true()
	WorldSimulation.clear();var result:=SaveSystem.load_game(slot)
	DirAccess.remove_absolute(SaveSystem.slot_path(slot))
	assert_bool(result.get("ok",false)).override_failure_message(str(result)).is_true()
	if not result.get("ok",false):return
	WorldSimulation.scoped("armor",func()->void:
		var host=WorldSimulation.military;var job:Dictionary=host.equipment_queue.back()
		assert_float(float(job.progress_days)).is_equal(2.0)
		assert_str(host.home_army.formations.back().weapon).is_equal("mail_spear")
		assert_int(int(host.home_army.formations.back().equipment)).is_equal(2)
		assert_int(int(host.damaged_equipment.mail_spear)).is_equal(1)
		P.advance(host,job,2)
		assert_int(int(job.completed)).is_equal(1)
		assert_array(host.validate_state()).is_empty())
func test_actual_automatic_military_orders_select_available_armor_for_infantry()->void:
	WorldSimulation.scoped("armor",func()->void:
		setup();know("articulated_plate_armor")
		var host=WorldSimulation.military;var state=WorldSimulation.state
		state.resource_stockpiles.clear();host.military_inventory.spear=20;host.military_inventory.plate_spear=20
		host.aggregate_recruits=4
		var preference:=plan();preference.personality.discipline=.95
		C.military_orders("armor",preference)
		assert_array(host.training_queue).is_not_empty()
		assert_str(String(host.training_queue.back().weapon)).is_equal("plate_spear")
		assert_int(int(host.military_inventory.plate_spear)).is_equal(20)
		assert_int(int(host.home_army.get("troops",0))).is_equal(0))
func test_automatic_armor_kits_use_one_free_workshop_and_replenish_after_issue()->void:
	WorldSimulation.scoped("armor",func()->void:
		setup();know("articulated_plate_armor")
		var host=WorldSimulation.military;var state=WorldSimulation.state
		stock_bill("plate_spear",12.0);host.military_inventory.spear=20
		# Occupied manual slots are left alone; one free slot makes the kits.
		for n:int in range(host.production_line_capacity()-1):
			var result:=host.start_production_line("spear",50)
			assert_bool(result.get("ok",false)).is_true()
			host.equipment_queue.back().paused=true
		var p:=plan()
		for cycle:int in 2:
			for day:int in 12:
				var weapon:=A.selection(host,"spearman",p)
				C.land_training_orders("armor","spearman",weapon,4,p)
				preload("res://scripts/ai_workshop_turnover.gd").advance("armor",host)
				for job:Dictionary in host.equipment_queue:
					if not bool(job.paused):P.advance(host,job,20)
				if int(host.military_inventory.plate_spear)>=4:break
			assert_int(int(host.military_inventory.plate_spear)).is_equal(4)
			assert_int(host.equipment_queue.size()).is_equal(host.production_line_capacity())
			if cycle==0:host.military_inventory.plate_spear=0
		for job:Dictionary in host.equipment_queue:
			if String(job.item)=="spear":assert_bool(job.paused).is_true())
