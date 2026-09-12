extends GdUnitTestSuite
const K=preload("res://scripts/communications_knowledge.gd")
const I=preload("res://scripts/civilian_industry.gd")
const P=preload("res://scripts/persistent_production.gd")
const R=preload("res://scripts/technology_requirements.gd")
const A=preload("res://scripts/communications_analysis.gd")
const Ops=preload("res://scripts/technology_operations.gd")
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("communications",997)
func after_test()->void:WorldSimulation.clear()
func learn(id:String)->void:
	if id not in WorldSimulation.state.known_discoveries:WorldSimulation.state.known_discoveries.append(id)
	WorldSimulation.state.discovery_adoption[id]=1.0
func test_catalog_and_amplifier_alternatives()->void:
	WorldSimulation.scoped("communications",func()->void:
		assert_int(K.entries().size()).is_equal(48)
		assert_array(preload("res://scripts/technology_catalog_contract.gd").validate(K.entries(),WorldSimulation.discovery.technology_catalog)).is_empty()
		for entry:Dictionary in K.entries():
			if entry.id not in ["telephone_repeaters","feedback_radio_oscillators"]:continue
			var common:Array=entry.requires_all.duplicate()
			assert_bool(R.evaluate(entry,common).ready).is_false()
			assert_bool(R.evaluate(entry,common+["triode_valves"]).ready).is_true()
			assert_bool(R.evaluate(entry,common+["transistor_amplifiers"]).ready).is_true()
			common.pop_back()
			assert_bool(R.evaluate(entry,common+["triode_valves","transistor_amplifiers"]).ready).is_false()
	)
func test_valve_and_transistor_equipment_consume_paid_inputs()->void:
	WorldSimulation.scoped("communications",func()->void:
		var state=WorldSimulation.state
		for item:String in ["valve_telephone_repeaters","transistor_radio_oscillators","transistor_frequency_mixers","valve_frequency_modulation"]:
			var spec:=I.product(item);learn(spec.gate)
			state.resource_stockpiles.clear()
			for material:String in spec.materials:state.resource_stockpiles[material]=float(spec.materials[material])
			for material:String in spec.tooling:state.resource_stockpiles[material]=float(state.resource_stockpiles.get(material,0))+float(spec.tooling[material])
			assert_bool(WorldSimulation.military.start_production_line(item,1).get("ok",false)).is_true()
			var job:Dictionary=WorldSimulation.military.equipment_queue.back()
			P.advance(WorldSimulation.military,job,float(spec.days)*.5)
			assert_float(float(state.resource_stockpiles.get(spec.output,0))).is_equal(0.0)
			P.advance(WorldSimulation.military,job,float(spec.days))
			assert_int(int(job.completed)).is_equal(1)
			assert_float(float(state.resource_stockpiles.get(spec.output,0))).is_equal(1.0)
			for material:String in spec.materials:assert_float(float(state.resource_stockpiles.get(material,0))).is_equal(0.0)
			WorldSimulation.military.cancel_equipment_job(int(job.id))
	)
func test_signal_analysis_is_subject_specific_and_exhaustible()->void:
	WorldSimulation.scoped("communications",func()->void:
		Ops.data().last_day=int(WorldSimulation.state.elapsed_days)
		Ops.data().services.analysis_electrical=1.0
		var item:={"reverse_engineered":true,"discovery_id":"telephone_repeaters","specimen_item":"valve_telephone_repeaters"}
		assert_float(A.use(item,2.0,10.0)).is_equal(.5)
		assert_float(A.use(item,2.0,2.25)).is_equal(.25)
		assert_float(A.use(item,2.0,10.0)).is_equal(.25)
		assert_float(A.use(item,2.0,10.0)).is_equal(0.0)
		Ops.data().services.analysis_electrical=1.0
		item.specimen_item="carbon_resistors"
		assert_float(A.use(item,2.0,10.0)).is_equal(0.0)
		item.specimen_item="valve_telephone_repeaters";item.reverse_engineered=false
		assert_float(A.use(item,2.0,10.0)).is_equal(0.0)
		assert_float(float(Ops.data().services.analysis_electrical)).is_equal(1.0)
	)

func test_rival_builds_against_returned_demand_and_pays_for_equipment()->void:
	WorldSimulation.scoped("communications",func()->void:
		var state=WorldSimulation.state
		state.settlement_site_committed=true;state.convoy_traveling=false
		state.population_health=1.0;state.simulation_metrics.labor_efficiency=1.0
		state.population_allocations.Crafting=10;state.population_allocations.Knowledge=20
		state.elapsed_days=100
		learn("optical_telegraphy");learn("experimental_controls")
		state.resource_stockpiles["Optical Telegraph Sets"]=1.0
		state.resource_stockpiles["Timber"]=2.0;state.resource_stockpiles["Paper"]=2.0
		var planner=preload("res://scripts/communications_investment.gd")
		assert_dict(planner.recommendation()).is_empty()
		var item:={"reverse_engineered":true,"discovery_id":"optical_telegraphy","specimen_item":"optical_telegraphy","returned_day":101,"study":0.0,"work":300.0}
		preload("res://scripts/society_exchange.gd").data().collections.sample=item
		assert_dict(planner.recommendation()).is_empty()
		item.returned_day=100
		assert_str(planner.recommendation().get("plant","")).is_equal("optical_signal_bench")
		preload("res://scripts/civilization_controller.gd").civilian_orders("communications",{})
		assert_int(int(Ops.data().plants.optical_signal_bench.building)).is_equal(1)
		assert_float(float(state.resource_stockpiles["Optical Telegraph Sets"])).is_equal(0.0)
		assert_dict(planner.recommendation()).is_empty()
		for day in range(101,110):state.elapsed_days=day;Ops.advance(day)
		assert_float(Ops.service("analysis_optical")).is_equal(1.0)
		assert_dict(planner.recommendation()).is_empty()
	)

func test_optical_capacity_cannot_analyze_other_families()->void:
	WorldSimulation.scoped("communications",func()->void:
		Ops.data().last_day=int(WorldSimulation.state.elapsed_days)
		Ops.data().services.analysis_optical=1.0
		for id:String in ["telephone_repeaters","superheterodyne_reception","packet_routers"]:
			var item:={"reverse_engineered":true,"discovery_id":id,"specimen_item":id}
			assert_bool(A.eligible(item)).is_true()
			assert_float(A.use(item,4.0,10.0)).is_equal(0.0)
		assert_float(float(Ops.data().services.analysis_optical)).is_equal(1.0)
		assert_float(A.use({"reverse_engineered":true,"discovery_id":"optical_telegraphy","specimen_item":"optical_telegraphy"},4.0,10.0)).is_equal(1.0)
		for entry:Dictionary in K.entries():
			for recipe:String in entry.get("production_items",[]):
				assert_bool(A.eligible({"reverse_engineered":true,"discovery_id":entry.id,"specimen_item":recipe})).is_true()
	)
func test_rival_does_not_buy_optical_bench_for_digital_demand()->void:
	WorldSimulation.scoped("communications",func()->void:
		var state=WorldSimulation.state
		state.settlement_site_committed=true;state.convoy_traveling=false
		state.population_health=1.0;state.simulation_metrics.labor_efficiency=1.0
		state.population_allocations.Crafting=10;state.population_allocations.Knowledge=20;state.elapsed_days=100
		learn("optical_telegraphy");learn("experimental_controls")
		state.resource_stockpiles["Optical Telegraph Sets"]=1.0;state.resource_stockpiles["Timber"]=2.0;state.resource_stockpiles["Paper"]=2.0
		preload("res://scripts/society_exchange.gd").data().collections.sample={"reverse_engineered":true,"discovery_id":"packet_routers","specimen_item":"packet_routers","returned_day":100,"study":0.0,"work":300.0}
		assert_dict(preload("res://scripts/communications_investment.gd").recommendation()).is_empty()
		for id:String in ["electrical_telegraphy","electrical_measurement","telephone_circuits"]:learn(id)
		Ops.data().plants.optical_signal_bench={"installed":1,"building":0,"work":0.0,"enabled":true}
		Ops.data().plants.solar_array={"installed":1,"building":0,"work":0.0,"enabled":true}
		state.resource_stockpiles["Electrical Telegraph Sets"]=1.0;state.resource_stockpiles["Telephone Sets"]=1.0
		var sample:Dictionary=preload("res://scripts/society_exchange.gd").data().collections.sample
		sample.discovery_id="telephone_repeaters";sample.specimen_item="telephone_repeaters"
		assert_str(preload("res://scripts/communications_investment.gd").recommendation().get("plant","")).is_equal("electrical_signal_bench")
	)
