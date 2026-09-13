extends GdUnitTestSuite
const K=preload("res://scripts/leather_knowledge.gd")
const I=preload("res://scripts/civilian_industry.gd")
const P=preload("res://scripts/persistent_production.gd")
const B=preload("res://scripts/household_clothing.gd")
const CK=preload("res://scripts/clothing_knowledge.gd")
const Planner=preload("res://scripts/civilian_production_planner.gd")
func before_test()->void:
	WorldSimulation.clear();WorldSimulation.create_actor("leather_owner",4985)
func after_test()->void:
	WorldSimulation.clear()
	GameState.set_process(true);CivilizationSystem.set_process(true);MilitaryCampaign.set_process(true)
func know(id:String)->void:
	if id not in WorldSimulation.state.known_discoveries:WorldSimulation.state.known_discoveries.append(id)
	WorldSimulation.state.discovery_adoption[id]=1.0
func provision(item:String,target:int=1)->Dictionary:
	var recipe:=I.product(item);know(String(recipe.gate))
	for material:String in recipe.materials:WorldSimulation.state.resource_stockpiles[material]=100.0
	for material:String in recipe.tooling:WorldSimulation.state.resource_stockpiles[material]=100.0
	var result:=WorldSimulation.military.start_production_line(item,target)
	assert_bool(result.get("ok",false)).override_failure_message(str(result)).is_true()
	return WorldSimulation.military.equipment_queue.back()
func power(amount:float)->void:
	WorldSimulation.state.technology_operations.last_day=int(WorldSimulation.state.elapsed_days)
	WorldSimulation.state.technology_operations.services["electricity"]=amount
func settle()->void:
	var state=WorldSimulation.state
	state.ensure_population_total(400);state.settlement_site_committed=true;state.convoy_traveling=false
	state.settlement_completed.assign(["Hearth Circle"]);WorldSimulation.settlements.ensure_founded()
func equip(id:String)->void:
	know(id)
	for parent:String in CK.METHODS[id].requires_all:know(parent)
	for group:Array in CK.METHODS[id].requires_any:know(group[0])
	for item:String in CK.METHODS[id].cost:
		if item==B.BONE_RESOURCE:B.data().bone_stock=100.0
		else:WorldSimulation.state.resource_stockpiles[item]=100.0
	assert_bool(B.install(id).get("ok",false)).is_true()
func report()->Dictionary:return {"workers":0.0,"inputs":{},"methods":{},"discarded":0.0}
func test_catalog_preserves_two_authored_parent_predicates()->void:
	WorldSimulation.scoped("leather_owner",func()->void:
		assert_array(K.entries()[0].requires_all).is_equal(["curing_regimens","herbal_classification"])
		assert_array(CK.METHODS.leather_goods_patterning.requires_all).is_equal(["hide_tanning","garment_pattern_cutting"])
		assert_array(preload("res://scripts/technology_catalog_contract.gd").validate(K.entries(),WorldSimulation.discovery.technology_catalog)).is_empty())
func test_actual_hunting_byproduct_ignores_food_stores_forecasts_and_repeat_day()->void:
	WorldSimulation.scoped("leather_owner",func()->void:
		settle();know("hide_tanning");WorldSimulation.food.initialize()
		var state=WorldSimulation.state
		state.food_stocks["Fresh meat"]=10000.0;state.population_allocations.Food=0;state.population_allocations.Logistics=0
		WorldSimulation.food.process_day({"traveling":false},1,1)
		assert_float(B.available("Raw Hides")).is_equal(0.0)
		state.elapsed_days=1;state.population_allocations.Food=20
		var result:=WorldSimulation.food.process_day({"traveling":false},1,1)
		assert_float(float(result.food_harvest["Fresh meat"])).is_greater(0)
		assert_float(B.available("Raw Hides")).is_equal_approx(minf(state.population_exact*.02,float(result.food_harvest["Fresh meat"])*.001),.000001)
		assert_float(B.available("Recovered Animal Fat")).is_equal_approx(B.available("Raw Hides")*.5,.000001)
		var before:=B.available("Raw Hides")
		WorldSimulation.food._forecast(90,result.food_harvest,result.food_demand_breakdown,false)
		B.advance(0,400,false,100000)
		assert_float(B.available("Raw Hides")).is_equal(before)
		state.elapsed_days=2;B.advance(0,400,false,0)
		assert_float(B.available("Raw Hides")).is_equal_approx(before*.75,.000001))
func test_every_tanning_stage_pays_actual_materials_and_produces_only_its_output()->void:
	WorldSimulation.scoped("leather_owner",func()->void:
		for item:String in K.entries()[0].production_items:
			var spec:=I.product(item);var job:=provision(item)
			WorldSimulation.state.resource_stockpiles[spec.output]=0.0
			var before:Dictionary=WorldSimulation.state.resource_stockpiles.duplicate(true)
			P.advance(WorldSimulation.military,job,float(spec.days))
			assert_int(int(job.completed)).override_failure_message(item).is_equal(1)
			assert_float(float(WorldSimulation.state.resource_stockpiles[spec.output])).is_equal(1.0)
			for input:String in spec.materials:assert_float(float(WorldSimulation.state.resource_stockpiles[input])).is_equal_approx(float(before[input])-float(spec.materials[input]),.000001)
			WorldSimulation.military.cancel_equipment_job(int(job.id)))
func test_missing_hides_tannin_water_or_finishing_fat_blocks_without_spend()->void:
	WorldSimulation.scoped("leather_owner",func()->void:
		for pair:Array in [["prepared_tanning_hides","Raw Hides"],["vegetable_tanned_leather","Plant Tannin Extract"],["vegetable_tanned_leather","Freshwater"],["finished_flexible_leather","Rendered Animal Fat"]]:
			var job:=provision(pair[0]);WorldSimulation.state.resource_stockpiles[pair[1]]=0.0
			var before:Dictionary=WorldSimulation.state.resource_stockpiles.duplicate(true)
			P.advance(WorldSimulation.military,job,100)
			assert_int(int(job.completed)).is_equal(0)
			assert_dict(WorldSimulation.state.resource_stockpiles).is_equal(before)
			WorldSimulation.military.cancel_equipment_job(int(job.id)))
func test_imported_finished_leather_becomes_paid_issued_garments()->void:
	WorldSimulation.scoped("leather_owner",func()->void:
		settle();equip("leather_goods_patterning")
		WorldSimulation.state.resource_stockpiles["Flexible Leather"]=10.0;WorldSimulation.state.resource_stockpiles["Spun Yarn"]=10.0
		var result:=report();B.operate("leather_goods_patterning",1,400,0,result)
		assert_float(B.leather_count()).is_equal(1.5)
		assert_float(float(result.workers)).is_equal(1.0)
		assert_float(B.available("Flexible Leather")).is_equal_approx(10-.65*1.5,.000001)
		assert_float(float(B.coverage(400,0).issued)).is_equal(1.5)
		assert_float(B.available("Tanned Leather")).is_equal(0.0))
func test_patching_spends_compatible_leather_preserves_quantity_and_shares_work()->void:
	WorldSimulation.scoped("leather_owner",func()->void:
		settle();equip("leather_goods_patterning");B.add("leather",10,.4)
		WorldSimulation.state.resource_stockpiles["Flexible Leather"]=10.0;WorldSimulation.state.resource_stockpiles["Spun Yarn"]=10.0
		var result:=report();B.operate("leather_goods_patterning",1,400,0,result)
		assert_float(B.leather_count()).is_equal(10.0)
		assert_float(float(B.data().lots[0].condition)).is_equal_approx(.445,.000001)
		assert_float(B.available("Flexible Leather")).is_equal_approx(9.88,.000001)
		assert_float(float(result.workers)).is_equal(1.0)
		B.data().lots[0].condition=.14;B.operate("leather_goods_patterning",0,400,0,report())
		assert_float(float(B.data().lots[0].condition)).is_equal(.14))
func test_textile_services_and_power_demand_do_not_treat_leather_as_cloth()->void:
	WorldSimulation.scoped("leather_owner",func()->void:
		settle();B.add("leather",10,.4,.9)
		for id:String in ["textile_laundering_practice","mechanical_washing_machines","textile_repair_methods","textile_moisture_transport","textile_durability_testing"]:
			equip(id)
			for item:String in CK.METHODS[id].inputs:WorldSimulation.state.resource_stockpiles[item]=100.0
			power(100)
			var before:Dictionary=WorldSimulation.state.resource_stockpiles.duplicate(true)
			var result:=report();B.operate(id,100,0,0,result)
			assert_dict(WorldSimulation.state.resource_stockpiles).is_equal(before)
			assert_float(float(result.workers)).is_equal(0.0)
		assert_float(B.power_demand()).is_equal(0.0)
		assert_float(B.leather_count()).is_equal(10.0))
func test_leather_wear_and_layering_remain_bounded_and_do_not_multiply_coverage()->void:
	WorldSimulation.scoped("leather_owner",func()->void:
		settle();equip("layered_clothing_design");B.add("leather",20)
		B.operate("layered_clothing_design",100,10,0,report())
		assert_float(B.leather_count()).is_equal(12.0)
		assert_float(float(B.coverage(10,0).issued)).is_equal(10.0)
		var before:=float(B.coverage(10,0).cold)
		B.advance(0,10,true,0)
		assert_float(float(B.coverage(10,0).cold)).is_less(before)
		assert_bool(B.valid(B.data())).is_true())
func test_full_lot_ledger_does_not_spend_on_unadmitted_leather_garments()->void:
	WorldSimulation.scoped("leather_owner",func()->void:
		settle();equip("leather_goods_patterning")
		for i in B.LIMIT:B.add("sew",1,1,0,false,false,i+1)
		WorldSimulation.state.resource_stockpiles["Flexible Leather"]=10.0;WorldSimulation.state.resource_stockpiles["Spun Yarn"]=10.0
		var before:Dictionary=WorldSimulation.state.resource_stockpiles.duplicate(true)
		B.operate("leather_goods_patterning",100,400,0,report())
		assert_dict(WorldSimulation.state.resource_stockpiles).is_equal(before))
func test_real_clothing_planner_pays_finishing_line_and_uses_output()->void:
	WorldSimulation.scoped("leather_owner",func()->void:
		settle();equip("leather_goods_patterning")
		WorldSimulation.state.population_allocations.Logistics=20;WorldSimulation.state.population_allocations.Crafting=40
		for item:String in I.PRODUCTS.finished_flexible_leather.tooling:WorldSimulation.state.resource_stockpiles[item]=100.0
		for item:String in I.PRODUCTS.finished_flexible_leather.materials:WorldSimulation.state.resource_stockpiles[item]=100.0
		WorldSimulation.state.resource_stockpiles["Flexible Leather"]=0.0;WorldSimulation.state.resource_stockpiles["Spun Yarn"]=10.0
		var order:=Planner.clothing_recommendation()
		assert_str(String(order.get("item",""))).is_equal("finished_flexible_leather")
		preload("res://scripts/civilization_controller.gd").production_order("leather_owner",order)
		assert_array(WorldSimulation.military.equipment_queue).is_not_empty()
		if WorldSimulation.military.equipment_queue.is_empty():return
		P.advance(WorldSimulation.military,WorldSimulation.military.equipment_queue.back(),3)
		B.operate("leather_goods_patterning",1,400,0,report())
		assert_float(B.leather_count()).is_greater(0))
func test_actor_full_save_restores_partial_tanning_job_and_leather_lot()->void:
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	WorldSimulation.scoped("leather_owner",func()->void:
		settle();var job:=provision("vegetable_tanned_leather")
		P.advance(WorldSimulation.military,job,3)
		assert_int(int(job.completed)).is_equal(0)
		B.add("leather",3,1,.4))
	var human:=GameState.resource_stockpiles.duplicate(true)
	var slot:="leather_process_%d"%OS.get_process_id()
	assert_bool(SaveSystem.save_game(slot).get("ok",false)).is_true()
	WorldSimulation.clear();var loaded:=SaveSystem.load_game(slot)
	DirAccess.remove_absolute(SaveSystem.slot_path(slot))
	assert_bool(loaded.get("ok",false)).override_failure_message(str(loaded)).is_true()
	assert_dict(GameState.resource_stockpiles).is_equal(human)
	if not loaded.get("ok",false):return
	WorldSimulation.scoped("leather_owner",func()->void:
		assert_float(B.leather_count()).is_equal(3.0)
		var job:Dictionary=WorldSimulation.military.equipment_queue.back()
		P.advance(WorldSimulation.military,job,9)
		assert_int(int(job.completed)).is_equal(1)
		var after:Dictionary=WorldSimulation.state.resource_stockpiles.duplicate(true)
		P.advance(WorldSimulation.military,job,10)
		assert_dict(WorldSimulation.state.resource_stockpiles).is_equal(after))
func test_leather_is_debited_in_transit_before_secondary_fitting()->void:
	WorldSimulation.scoped("leather_owner",func()->void:
		settle();equip("leather_goods_patterning")
		var state=WorldSimulation.state;var model=WorldSimulation.settlements
		state.player_settlements.append({"id":"weaver_city","name":"Weaver City","primary":false,"position":Vector2(10,0),"population_share":.25,"founded_day":0})
		WorldSimulation.system("CivilizationSystem").register_player_origin(Vector2.ZERO)
		WorldSimulation.system("CivilizationSystem").record_player_travel(Vector2(10,0))
		state.society_capacities.logistics=.8;state.society_capacities.institutions=.8;state.population_allocations.Logistics=100
		state.resource_stockpiles["Flexible Leather"]=100.0
		model.with_city_resources("weaver_city",func()->void:state.resource_stockpiles.Food=10000.0)
		model.process_city_trade()
		var shipped:=0.0
		for shipment:Dictionary in state.city_trade_shipments:
			if String(shipment.resource)=="Flexible Leather" and String(shipment.destination_id)=="weaver_city":shipped+=float(shipment.quantity)
		assert_float(shipped).is_greater(0)
		assert_float(float(state.resource_stockpiles["Flexible Leather"])+shipped).is_equal_approx(100,.000001)
		assert_float(float(model.city_resource_snapshot("weaver_city").stores.get("Flexible Leather",0))).is_equal(0.0)
		state.elapsed_days=20;state.society_capacities.logistics=0;model.process_city_trade()
		assert_float(float(model.city_resource_snapshot("weaver_city").stores.get("Flexible Leather",0))).is_equal_approx(shipped,.000001)
		var capital:Dictionary=state.resource_stockpiles.duplicate(true)
		model.with_city_resources("weaver_city",func()->void:
			model.with_local_population(func()->void:
				equip("leather_goods_patterning");state.resource_stockpiles["Spun Yarn"]=2.0
				B.operate("leather_goods_patterning",1,state.population_exact,20,report())
				assert_float(B.leather_count()).is_greater(0)))
		assert_float(B.leather_count()).is_equal(0.0)
		assert_dict(state.resource_stockpiles).is_equal(capital))
