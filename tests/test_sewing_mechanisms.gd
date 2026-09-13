extends GdUnitTestSuite
const K=preload("res://scripts/clothing_knowledge.gd")
const C=preload("res://scripts/household_clothing.gd")
const I=preload("res://scripts/civilian_industry.gd")
const P=preload("res://scripts/persistent_production.gd")
const ID:="sewing_machine_mechanisms"
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("sewing",990)
func after_test()->void:
	WorldSimulation.clear();GameState.set_process(true);CivilizationSystem.set_process(true);MilitaryCampaign.set_process(true)
func learn(id:String)->void:
	if id not in WorldSimulation.state.known_discoveries:WorldSimulation.state.known_discoveries.append(id)
	WorldSimulation.state.discovery_adoption[id]=1.0
func prepare()->void:
	WorldSimulation.state.settlement_site_committed=true;WorldSimulation.state.convoy_traveling=false
	for id:String in [ID]+K.METHODS[ID].requires_all:learn(id)
func supplies()->void:
	for field:String in ["cost","inputs"]:
		for r:String in K.METHODS[ID][field]:WorldSimulation.state.resource_stockpiles[r]=100.0
func report()->Dictionary:return {"workers":0.0,"inputs":{},"methods":{},"discarded":0.0}
func provision(item:String)->Dictionary:
	var spec:=I.product(item);learn(spec.gate)
	for field:String in ["materials","tooling"]:
		for r:String in spec[field]:WorldSimulation.state.resource_stockpiles[r]=100.0
	assert_bool(WorldSimulation.military.start_production_line(item,1).get("ok",false)).is_true()
	return WorldSimulation.military.equipment_queue.back()
func test_discovery_preserves_foundations_and_manufactures_actual_equipment()->void:
	WorldSimulation.scoped("sewing",func()->void:
		assert_array(K.METHODS[ID].requires_all).is_equal(["bone_needle_sewing","cam_motion_design"])
		assert_array(preload("res://scripts/technology_catalog_contract.gd").validate(K.entries(),WorldSimulation.discovery.technology_catalog)).is_empty()
		prepare();supplies();WorldSimulation.state.known_discoveries.erase(ID)
		assert_bool(C.install(ID).has("error")).is_true()
		learn(ID);WorldSimulation.state.known_discoveries.erase("cam_motion_design")
		assert_bool(C.install(ID).has("error")).is_true())
func test_both_fabrication_routes_spend_partial_work_and_real_inputs()->void:
	WorldSimulation.scoped("sewing",func()->void:
		for item:String in ["sewing_service_parts","treadle_sewing_machines"]:
			var spec:=I.product(item);var job:=provision(item);WorldSimulation.state.resource_stockpiles[spec.output]=0.0
			var before:Dictionary=WorldSimulation.state.resource_stockpiles.duplicate(true)
			P.advance(WorldSimulation.military,job,float(spec.days)/2);assert_int(int(job.completed)).is_equal(0)
			var saved:Dictionary=bytes_to_var(var_to_bytes(job));assert_str(P.validate_saved({"equipment_queue":[saved]})).is_empty()
			P.advance(WorldSimulation.military,saved,float(spec.days)/2);assert_int(int(saved.completed)).is_equal(1)
			for r:String in spec.materials:assert_float(float(before[r])-float(WorldSimulation.state.resource_stockpiles[r])).is_equal_approx(float(spec.materials[r]),.000001)
			WorldSimulation.military.cancel_equipment_job(int(job.id)))
func test_finished_machine_is_paid_into_installation_and_makes_ordinary_sewn_garments()->void:
	WorldSimulation.scoped("sewing",func()->void:
		prepare();var job:=provision("treadle_sewing_machines");P.advance(WorldSimulation.military,job,10)
		WorldSimulation.state.resource_stockpiles["Woven Cloth"]=100.0;WorldSimulation.state.resource_stockpiles["Spun Yarn"]=100.0
		assert_bool(C.install(ID).get("ok",false)).is_true();assert_float(C.available("Treadle Sewing Machines")).is_equal(0.0)
		var parts:=C.available("Sewing Service Parts");var r:=report();C.operate(ID,1,100,0,r)
		assert_float(C.count()).is_equal(6.0);assert_float(float(r.workers)).is_equal(1.0)
		assert_float(C.available("Woven Cloth")).is_equal_approx(95.8,.000001)
		assert_float(C.available("Spun Yarn")).is_equal_approx(99.28,.000001)
		assert_float(parts-C.available("Sewing Service Parts")).is_equal_approx(.03,.000001)
		assert_str(String(C.data().lots[0].kind)).is_equal("sew")
		assert_float(float(C.coverage(100,0).cold)).is_equal_approx(6*.32/100,.000001)
		assert_bool(r.inputs.has("Electricity")).is_false())
func test_missing_parts_or_work_produces_no_clothes_and_figured_identity_survives()->void:
	WorldSimulation.scoped("sewing",func()->void:
		prepare();supplies();C.install(ID)
		C.operate(ID,0,100,0,report());assert_float(C.count()).is_equal(0.0)
		WorldSimulation.state.resource_stockpiles["Sewing Service Parts"]=0.0
		C.operate(ID,100,100,0,report());assert_float(C.count()).is_equal(0.0)
		WorldSimulation.state.resource_stockpiles["Sewing Service Parts"]=1.0;WorldSimulation.state.resource_stockpiles["Figured Cloth"]=100.0
		C.operate(ID,1,100,0,report());assert_float(C.figured_count()).is_equal(6.0)
		assert_float(C.available("Woven Cloth")).is_equal(100.0)
		assert_bool(C.valid(C.data())).is_true())
func test_actual_daily_owner_shares_budget_installs_once_and_cannot_repeat()->void:
	WorldSimulation.scoped("sewing",func()->void:
		prepare();supplies();var result:=C.advance(10,100,false)
		assert_int(int(C.data().tools[ID])).is_equal(1)
		assert_float(float(result.workers)).is_less_equal(2.0);assert_float(C.count()).is_equal(6.0)
		var before:Dictionary=C.data().duplicate(true);var stocks:Dictionary=WorldSimulation.state.resource_stockpiles.duplicate(true)
		C.advance(100,100,false)
		assert_dict(C.data()).is_equal(before);assert_dict(WorldSimulation.state.resource_stockpiles).is_equal(stocks))
func test_real_planner_orders_missing_service_parts_for_adopted_sewing()->void:
	WorldSimulation.scoped("sewing",func()->void:
		prepare();supplies();WorldSimulation.state.population_allocations.Crafting=40;WorldSimulation.state.population_allocations.Logistics=20
		WorldSimulation.state.resource_stockpiles["Sewing Service Parts"]=0.0
		for field:String in ["materials","tooling"]:
			for r:String in I.PRODUCTS.sewing_service_parts[field]:WorldSimulation.state.resource_stockpiles[r]=100.0
		var order:=preload("res://scripts/civilian_production_planner.gd").clothing_recommendation()
		assert_str(String(order.get("item",""))).is_equal("sewing_service_parts")
		preload("res://scripts/civilization_controller.gd").production_order("sewing",order)
		assert_array(WorldSimulation.military.equipment_queue).is_not_empty())
func test_secondary_city_installs_and_uses_its_own_unpowered_machine()->void:
	WorldSimulation.scoped("sewing",func()->void:
		prepare();supplies();C.install(ID);C.add("sew",20)
		WorldSimulation.state.player_settlements.append({"id":"second","name":"Second","position":Vector2(10,0),"population_share":.25,"founded_day":0})
		WorldSimulation.settlements.with_city_resources("second",func()->void:
			assert_float(C.count()).is_equal(0.0);supplies();assert_bool(C.install(ID).get("ok",false)).is_true()
			C.operate(ID,1,100,0,report());assert_float(C.count()).is_equal(6.0))
		assert_float(C.count()).is_equal(20.0))
func test_full_world_save_retains_machine_garments_and_partial_paid_fabrication()->void:
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	WorldSimulation.scoped("sewing",func()->void:
		prepare();supplies();C.install(ID);C.advance(10,100,false)
		var job:=provision("sewing_service_parts");job.target_stock=200;P.advance(WorldSimulation.military,job,1.5))
	var slot:="sewing_mechanism_%d"%OS.get_process_id();assert_bool(SaveSystem.save_game(slot).get("ok",false)).is_true()
	WorldSimulation.clear();var loaded:=SaveSystem.load_game(slot);DirAccess.remove_absolute(SaveSystem.slot_path(slot))
	assert_bool(loaded.get("ok",false)).override_failure_message(str(loaded)).is_true()
	if not loaded.get("ok",false):return
	WorldSimulation.scoped("sewing",func()->void:
		assert_int(int(C.data().tools[ID])).is_equal(1);assert_float(C.count()).is_equal(6.0)
		var before:Dictionary=C.data().duplicate(true);C.advance(100,100,false);assert_dict(C.data()).is_equal(before)
		var job:Dictionary=WorldSimulation.military.equipment_queue.back();assert_float(float(job.progress_days)).is_equal(1.5)
		P.advance(WorldSimulation.military,job,1.5);assert_int(int(job.completed)).is_equal(1))
