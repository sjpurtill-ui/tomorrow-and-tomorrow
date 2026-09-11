extends GdUnitTestSuite
const K=preload("res://scripts/printing_knowledge.gd")
const I=preload("res://scripts/civilian_industry.gd")
const P=preload("res://scripts/persistent_production.gd")
const S=preload("res://scripts/paper_study.gd")
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("printer",995)
func after_test()->void:WorldSimulation.clear()
func learn(id:String)->void:
	if id not in WorldSimulation.state.known_discoveries:WorldSimulation.state.known_discoveries.append(id)
	WorldSimulation.state.discovery_adoption[id]=1.0
func test_eight_authored_methods_make_physical_ink_forms_and_printed_sheets()->void:
	WorldSimulation.scoped("printer",func()->void:
		assert_int(K.entries().size()).is_equal(8)
		assert_array(preload("res://scripts/technology_catalog_contract.gd").validate(K.entries(),WorldSimulation.discovery.technology_catalog)).is_empty()
		var state=WorldSimulation.state
		var plan:={"pressed_seed_oil":1,"captured_lampblack":1,"oil_printing_ink":2,"carved_printing_blocks":1,"hand_printed_sheets":2}
		var outputs:Array=[]
		for item:String in plan:outputs.append(I.product(item).output);state.resource_stockpiles[I.product(item).output]=0.0
		for item:String in plan:
			var r:=I.product(item);learn(r.gate)
			for material:String in r.materials:
				if material not in outputs:state.resource_stockpiles[material]=50.0
			for material:String in r.tooling:
				if material not in outputs:state.resource_stockpiles[material]=50.0
			assert_bool(WorldSimulation.military.start_production_line(item,int(plan[item])).get("ok",false)).is_true()
			var job:Dictionary=WorldSimulation.military.equipment_queue.back()
			P.advance(WorldSimulation.military,job,float(r.days)*int(plan[item]))
			assert_int(int(job.completed)).is_equal(int(plan[item]))
			WorldSimulation.military.cancel_equipment_job(int(job.id))
		assert_float(float(state.resource_stockpiles["Printed Sheets"])).is_equal(2.0)
		for resource:String in ["Drying Oil","Lampblack","Printing Forms"]:assert_float(float(state.resource_stockpiles[resource])).is_equal(0.0)
		assert_float(float(state.resource_stockpiles["Printing Ink"])).is_equal_approx(1.8,.000001)
		assert_float(float(state.resource_stockpiles.Paper)).is_equal(48.0)
	)
func test_printed_and_blank_paper_support_are_finite_alternatives()->void:
	WorldSimulation.scoped("printer",func()->void:
		var state=WorldSimulation.state;state.resource_stockpiles["Printed Sheets"]=.05;state.resource_stockpiles.Paper=1.0
		var result:=S.use(10.0,100.0)
		assert_float(float(result.work)).is_equal(10.0)
		assert_float(float(result.progress)).is_equal_approx(12.5,.000001)
		assert_float(float(result.printed_sheets)).is_equal_approx(.05,.000001)
		assert_float(float(result.paper)).is_equal_approx(.05,.000001)
		state.resource_stockpiles["Printed Sheets"]=1.0
		var before:=float(state.resource_stockpiles.Paper)
		result=S.use(10.0,1.3)
		assert_float(float(result.work)).is_equal_approx(1.0,.000001)
		assert_float(float(result.progress)).is_equal_approx(1.3,.000001)
		assert_float(float(state.resource_stockpiles.Paper)).is_equal(before)
		S.use(10.0,0.0);S.use(0.0,100.0)
		assert_float(float(state.resource_stockpiles["Printed Sheets"])).is_equal_approx(.99,.000001)
	)
func test_motor_press_waits_for_power_and_saved_partial_impression_finishes_once()->void:
	WorldSimulation.scoped("printer",func()->void:
		var r:=I.product("motor_printed_sheets");learn(r.gate);var state=WorldSimulation.state
		for resource:String in r.materials:state.resource_stockpiles[resource]=10.0
		for resource:String in r.tooling:state.resource_stockpiles[resource]=10.0
		assert_bool(WorldSimulation.military.start_production_line("motor_printed_sheets",1).get("ok",false)).is_true()
		var job:Dictionary=WorldSimulation.military.equipment_queue.back();var before:Dictionary=state.resource_stockpiles.duplicate(true)
		P.advance(WorldSimulation.military,job,1.0)
		assert_dict(state.resource_stockpiles).is_equal(before)
		state.technology_operations.last_day=int(state.elapsed_days);state.technology_operations.services.electricity=.5
		P.advance(WorldSimulation.military,job,.25)
		var saved:Dictionary=JSON.parse_string(JSON.stringify(job));assert_str(P.validate_saved({"equipment_queue":[saved]})).is_empty()
		state.technology_operations.services.electricity=.5;P.advance(WorldSimulation.military,saved,.25);P.advance(WorldSimulation.military,saved,1.0)
		assert_float(float(state.resource_stockpiles["Printed Sheets"])).is_equal(1.0)
		assert_float(float(state.technology_operations.services.electricity)).is_equal(0.0)
	)
func test_ai_prefers_affordable_printing_and_counts_existing_printed_stock()->void:
	WorldSimulation.scoped("printer",func()->void:
		var state=WorldSimulation.state;state.population_allocations.Knowledge=10
		preload("res://scripts/society_exchange.gd").data().collections["test"]={"study":0.0,"work":240.0,"returned_day":0}
		learn("hand_relief_printing")
		state.resource_stockpiles.merge({"Paper":10.0,"Printing Ink":2.0,"Printing Forms":1.0,"Timber":5.0},true)
		var f=preload("res://scripts/civilian_production_planner.gd")
		assert_str(f.recommendation().item).is_equal("hand_printed_sheets")
		state.resource_stockpiles["Printed Sheets"]=1.0
		assert_int(f.recommendation().target).is_equal(2)
		state.resource_stockpiles["Printed Sheets"]=2.0
		assert_dict(f.recommendation()).is_empty()
	)
