extends GdUnitTestSuite
const K=preload("res://scripts/textile_process_knowledge.gd")
const I=preload("res://scripts/civilian_industry.gd")
const P=preload("res://scripts/persistent_production.gd")
const B=preload("res://scripts/household_clothing.gd")
const CK=preload("res://scripts/clothing_knowledge.gd")
const Planner=preload("res://scripts/civilian_production_planner.gd")
func before_test()->void:
	WorldSimulation.clear();WorldSimulation.create_actor("textile_owner",4985)
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
func test_six_authored_mechanisms_have_causal_operating_contracts()->void:
	WorldSimulation.scoped("textile_owner",func()->void:
		assert_int(K.entries().size()).is_equal(6)
		assert_array(preload("res://scripts/technology_catalog_contract.gd").validate(K.entries(),WorldSimulation.discovery.technology_catalog)).is_empty()
		for entry:Dictionary in K.entries():
			assert_array(entry.production_items).is_not_empty()
			assert_bool(preload("res://scripts/technology_requirements.gd").evaluate(entry,[]).ready).is_false())
func test_every_route_pays_its_materials_and_produces_one_real_batch()->void:
	WorldSimulation.scoped("textile_owner",func()->void:
		for entry:Dictionary in K.entries():
			for item:String in entry.production_items:
				var spec:=I.product(item);var job:=provision(item)
				WorldSimulation.state.resource_stockpiles[spec.output]=0.0
				var before:Dictionary=WorldSimulation.state.resource_stockpiles.duplicate(true)
				power(float(spec.get("power",0)))
				P.advance(WorldSimulation.military,job,float(spec.days))
				assert_int(int(job.completed)).override_failure_message(item).is_equal(1)
				assert_float(float(WorldSimulation.state.resource_stockpiles[spec.output])).is_equal(1.0)
				for input:String in spec.materials:
					assert_float(float(WorldSimulation.state.resource_stockpiles[input])).override_failure_message(item+": "+input).is_equal_approx(float(before[input])-float(spec.materials[input]),.000001)
				WorldSimulation.military.cancel_equipment_job(int(job.id)))
func test_missing_sample_record_or_pattern_cards_prevents_output()->void:
	WorldSimulation.scoped("textile_owner",func()->void:
		for pair:Array in [["measured_yarn","Clay"],["card_figured_cloth","Loom Pattern Cards"]]:
			var job:=provision(pair[0]);var output:String=I.product(pair[0]).output
			WorldSimulation.state.resource_stockpiles[pair[1]]=0.0
			WorldSimulation.state.resource_stockpiles[output]=0.0
			var before:Dictionary=WorldSimulation.state.resource_stockpiles.duplicate(true)
			P.advance(WorldSimulation.military,job,100)
			assert_float(float(WorldSimulation.state.resource_stockpiles[output])).is_equal(0.0)
			assert_dict(WorldSimulation.state.resource_stockpiles).is_equal(before)
			WorldSimulation.military.cancel_equipment_job(int(job.id)))
func test_ring_hand_route_survives_outage_but_powered_lines_share_supply()->void:
	WorldSimulation.scoped("textile_owner",func()->void:
		var hand:=provision("hand_ring_yarn")
		WorldSimulation.state.resource_stockpiles["Spun Yarn"]=0.0
		power(0);P.advance(WorldSimulation.military,hand,10)
		assert_int(int(hand.completed)).is_equal(1)
		WorldSimulation.military.cancel_equipment_job(int(hand.id))
		WorldSimulation.state.resource_stockpiles["Spun Yarn"]=0.0
		var ring:=provision("electric_ring_yarn");P.advance(WorldSimulation.military,ring,10)
		assert_int(int(ring.completed)).is_equal(0)
		power(1.5);P.advance(WorldSimulation.military,ring,10)
		assert_int(int(ring.completed)).is_equal(1)
		WorldSimulation.military.cancel_equipment_job(int(ring.id))
		WorldSimulation.state.resource_stockpiles["Spun Yarn"]=0.0
		var rotor:=provision("rotor_spun_yarn");P.advance(WorldSimulation.military,rotor,10)
		assert_int(int(rotor.completed)).is_equal(0)
		assert_float(preload("res://scripts/technology_operations.gd").service("electricity")).is_equal(0.0))
func test_imported_measured_yarn_can_feed_controlled_weaving_without_count_mastery()->void:
	WorldSimulation.scoped("textile_owner",func()->void:
		var job:=provision("tensioned_woven_cloth")
		assert_bool("yarn_count_standards" in WorldSimulation.state.known_discoveries).is_false()
		var before:=float(WorldSimulation.state.resource_stockpiles["Measured Yarn"])
		P.advance(WorldSimulation.military,job,3)
		assert_float(before-float(WorldSimulation.state.resource_stockpiles["Measured Yarn"])).is_equal_approx(1.8,.000001)
		assert_float(float(WorldSimulation.state.resource_stockpiles["Woven Cloth"])).is_greater_equal(1.0))
func test_imported_figured_cloth_is_sewn_and_retained_without_loom_knowledge()->void:
	WorldSimulation.scoped("textile_owner",func()->void:
		settle();equip("bone_needle_sewing")
		WorldSimulation.state.resource_stockpiles["Woven Cloth"]=0.0
		WorldSimulation.state.resource_stockpiles["Figured Cloth"]=10.0
		WorldSimulation.state.resource_stockpiles["Spun Yarn"]=10.0
		var result:=report();B.operate("bone_needle_sewing",1,400,0,result)
		assert_float(B.figured_count()).is_equal(2.0)
		assert_float(float(WorldSimulation.state.resource_stockpiles["Figured Cloth"])).is_equal_approx(8.6,.000001)
		assert_bool("drawloom_pattern_control" in WorldSimulation.state.known_discoveries).is_false()
		assert_bool("punched_card_loom_control" in WorldSimulation.state.known_discoveries).is_false()
		assert_float(float(result.workers)).is_equal(1.0))
func test_plain_and_figured_lots_do_not_merge_or_change_protection()->void:
	WorldSimulation.scoped("textile_owner",func()->void:
		B.add("sew",10,1,0,false,false,0,"plain")
		var plain:=B.coverage(10,0)
		B.data().lots.clear();B.add("sew",10,1,0,false,false,0,"figured")
		assert_dict(B.coverage(10,0)).is_equal(plain)
		B.add("sew",10)
		assert_int(B.data().lots.size()).is_equal(2)
		assert_float(B.figured_count()).is_equal(10.0)
		B.data().lots[0].fabric="invalid"
		assert_bool(B.valid(B.data())).is_false()
		B.data().lots[0].erase("fabric")
		assert_bool(B.valid(B.data())).is_true())
func test_washing_and_layering_preserve_figured_identity_and_quantity()->void:
	WorldSimulation.scoped("textile_owner",func()->void:
		settle();equip("textile_laundering_practice");equip("layered_clothing_design")
		WorldSimulation.state.resource_stockpiles.Freshwater=100.0
		B.add("sew",20,1,.8,false,false,0,"figured")
		B.operate("textile_laundering_practice",100,10,0,report())
		assert_float(B.figured_count()).is_equal(20.0)
		var delayed:=false
		for lot:Dictionary in B.data().lots:
			assert_str(String(lot.fabric)).is_equal("figured")
			if int(lot.ready)==1:delayed=true
		assert_bool(delayed).is_true()
		B.operate("layered_clothing_design",100,10,1,report())
		assert_float(B.figured_count()).is_less(20.0)
		for lot:Dictionary in B.data().lots:assert_str(String(lot.fabric)).is_equal("figured"))
func test_bounded_full_lots_cannot_spend_cloth_without_admitting_garments()->void:
	WorldSimulation.scoped("textile_owner",func()->void:
		settle();equip("bone_needle_sewing")
		WorldSimulation.state.resource_stockpiles["Figured Cloth"]=10.0;WorldSimulation.state.resource_stockpiles["Spun Yarn"]=10.0
		for i in B.LIMIT:B.add("sew",1,1,0,false,false,i+1,"plain")
		var before:Dictionary=WorldSimulation.state.resource_stockpiles.duplicate(true)
		B.operate("bone_needle_sewing",10,400,0,report())
		assert_dict(WorldSimulation.state.resource_stockpiles).is_equal(before)
		assert_int(B.data().lots.size()).is_equal(B.LIMIT))
func test_clothing_demand_manufactures_patterned_fabric_from_real_yarn()->void:
	WorldSimulation.scoped("textile_owner",func()->void:
		settle();equip("bone_needle_sewing");know("drawloom_pattern_control")
		WorldSimulation.state.population_allocations.Logistics=20;WorldSimulation.state.population_allocations.Crafting=40
		for item:String in I.PRODUCTS.drawloom_figured_cloth.tooling:WorldSimulation.state.resource_stockpiles[item]=100
		WorldSimulation.state.resource_stockpiles["Spun Yarn"]=100
		var order:=Planner.clothing_recommendation()
		assert_str(String(order.get("item",""))).is_equal("drawloom_figured_cloth")
		preload("res://scripts/civilization_controller.gd").production_order("textile_owner",order)
		assert_array(WorldSimulation.military.equipment_queue).is_not_empty()
		if WorldSimulation.military.equipment_queue.is_empty():return
		P.advance(WorldSimulation.military,WorldSimulation.military.equipment_queue.back(),10)
		assert_float(float(WorldSimulation.state.resource_stockpiles["Figured Cloth"])).is_greater(0)
		B.operate("bone_needle_sewing",10,400,0,report())
		assert_float(B.figured_count()).is_greater(0))
func test_actor_full_save_restores_partial_powered_job_and_fabric_identity()->void:
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	WorldSimulation.scoped("textile_owner",func()->void:
		settle();var job:=provision("rotor_spun_yarn")
		power(1);P.advance(WorldSimulation.military,job,.2)
		assert_int(int(job.completed)).is_equal(0)
		B.add("sew",3,1,.4,false,false,0,"figured"))
	var human:=GameState.resource_stockpiles.duplicate(true)
	var slot:="textile_process_%d"%OS.get_process_id()
	assert_bool(SaveSystem.save_game(slot).get("ok",false)).is_true()
	WorldSimulation.clear();var loaded:=SaveSystem.load_game(slot)
	DirAccess.remove_absolute(SaveSystem.slot_path(slot))
	assert_bool(loaded.get("ok",false)).override_failure_message(str(loaded)).is_true()
	assert_dict(GameState.resource_stockpiles).is_equal(human)
	if not loaded.get("ok",false):return
	WorldSimulation.scoped("textile_owner",func()->void:
		assert_float(B.figured_count()).is_equal(3.0)
		var job:Dictionary=WorldSimulation.military.equipment_queue.back();power(1)
		P.advance(WorldSimulation.military,job,.2)
		assert_int(int(job.completed)).is_equal(1)
		var after:Dictionary=WorldSimulation.state.resource_stockpiles.duplicate(true)
		P.advance(WorldSimulation.military,job,10)
		assert_dict(WorldSimulation.state.resource_stockpiles).is_equal(after))
func test_figured_cloth_is_debited_in_transit_before_secondary_sewing()->void:
	WorldSimulation.scoped("textile_owner",func()->void:
		settle();equip("bone_needle_sewing")
		var state=WorldSimulation.state;var model=WorldSimulation.settlements
		state.player_settlements.append({"id":"weaver_city","name":"Weaver City","primary":false,"position":Vector2(10,0),"population_share":.25,"founded_day":0})
		WorldSimulation.system("CivilizationSystem").register_player_origin(Vector2.ZERO)
		WorldSimulation.system("CivilizationSystem").record_player_travel(Vector2(10,0))
		state.society_capacities.logistics=.8;state.society_capacities.institutions=.8;state.population_allocations.Logistics=100
		state.resource_stockpiles["Figured Cloth"]=100.0
		model.with_city_resources("weaver_city",func()->void:state.resource_stockpiles.Food=10000.0)
		model.process_city_trade()
		var shipped:=0.0
		for shipment:Dictionary in state.city_trade_shipments:
			if String(shipment.resource)=="Figured Cloth" and String(shipment.destination_id)=="weaver_city":shipped+=float(shipment.quantity)
		assert_float(shipped).is_greater(0)
		assert_float(float(state.resource_stockpiles["Figured Cloth"])+shipped).is_equal_approx(100,.000001)
		assert_float(float(model.city_resource_snapshot("weaver_city").stores.get("Figured Cloth",0))).is_equal(0.0)
		state.elapsed_days=20;state.society_capacities.logistics=0;model.process_city_trade()
		assert_float(float(model.city_resource_snapshot("weaver_city").stores.get("Figured Cloth",0))).is_equal_approx(shipped,.000001)
		var capital:Dictionary=state.resource_stockpiles.duplicate(true)
		model.with_city_resources("weaver_city",func()->void:
			model.with_local_population(func()->void:
				equip("bone_needle_sewing");state.resource_stockpiles["Spun Yarn"]=2.0
				B.operate("bone_needle_sewing",1,state.population_exact,20,report())
				assert_float(B.figured_count()).is_greater(0)))
		assert_float(B.figured_count()).is_equal(0.0)
		assert_dict(state.resource_stockpiles).is_equal(capital))
