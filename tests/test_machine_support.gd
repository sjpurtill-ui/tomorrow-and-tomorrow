extends GdUnitTestSuite
const S=preload("res://scripts/machine_support.gd")
const Bills=preload("res://scripts/goods_bills.gd")
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("machine_support",1212)
func after_test()->void:WorldSimulation.clear()
func line()->Dictionary:return {"completed":0,"last_work":0.0,"last_consumed":{},"machine_wear":1.0}
## Adds the raw materials and Civilian Goods of `bill` to the local stock.
func stock(bill:Dictionary)->void:
	var stocks:Dictionary=WorldSimulation.state.resource_stockpiles
	var flat:=Bills.flatten(bill)
	for item:String in flat:stocks[item]=float(stocks.get(item,0))+float(flat[item])
func test_paid_deterioration_measurement_requires_repair_and_recheck()->void:
	WorldSimulation.scoped("machine_support",func()->void:
		var state=WorldSimulation.state
		state.known_discoveries.append_array(["machine_tool_stiffness_assessment","machine_condition_monitoring"])
		state.resource_stockpiles={}
		stock({"Machine Load Test Sets":1.0,"Machine Vibration Test Sets":1.0,"Paper":1.0,"Refined Copper":1.0})
		var job:=line()
		assert_float(S.prepare(job,{},2)).is_equal(0.0)
		assert_bool(job.machine_support.repair_needed).is_true()
		assert_float(float(job.machine_wear)).is_equal(1.0)
		stock({"Steel":1.0,"Graphite":1.0})
		var iron:=float(state.resource_stockpiles["Iron Ore"])
		S.prepare(job,{},.25)
		assert_float(float(job.machine_support.repair_work)).is_equal(.25)
		var restored:Dictionary=bytes_to_var(var_to_bytes(job))
		S.prepare(restored,{},.25)
		assert_float(float(restored.machine_wear)).is_equal(.05)
		assert_float(float(state.resource_stockpiles["Iron Ore"])).is_equal_approx(iron-float(Bills.flatten({"Steel":.2,"Graphite":.02})["Iron Ore"]),.000001)
		assert_float(S.prepare(restored,{},1)).is_equal(.5)
		assert_bool(restored.machine_support.observations[-1].failed).is_false()
		assert_bool(S.valid(restored.machine_support,0)).is_true()
		var forged:Dictionary=restored.machine_support.duplicate(true)
		forged.observations[-1].failed=true
		assert_bool(S.valid(forged,0)).is_false()
	)
func test_water_film_and_filter_require_actual_fluid_and_discard_spent_water()->void:
	WorldSimulation.scoped("machine_support",func()->void:
		var state=WorldSimulation.state
		state.known_discoveries.append_array(["fluid_film_bearings","cutting_fluid_management"])
		state.resource_stockpiles={}
		stock({"Water-Film Bearing Sets":1.0,"Machining Water Filter Sets":1.0})
		var job:=line();S.prepare(job,{},1)
		assert_int(job.machine_support.installed.size()).is_equal(2)
		state.resource_stockpiles={}
		assert_float(S.limit_work(job,2)).is_equal(0.0)
		stock({"Woven Cloth":1.0});state.resource_stockpiles.Freshwater=.3
		# Bearing and cutting water plus the cloth's own process water, per unit of work.
		var water:=.15+float(S.FILTER_CLOTH.get("Freshwater",0))
		var possible:=S.limit_work(job,4)
		assert_float(possible).is_equal_approx(.3/water,.000001)
		S.consume(job,possible)
		assert_float(float(state.resource_stockpiles.Freshwater)).is_equal_approx(0.0,.000001)
		assert_float(float(state.resource_stockpiles["Spent Machining Water"])).is_equal_approx(.1*possible,.000001)
	)
func test_small_measurement_work_accumulates_without_rebuying_observations()->void:
	WorldSimulation.scoped("machine_support",func()->void:
		var state=WorldSimulation.state
		state.known_discoveries.append("machine_tool_stiffness_assessment")
		state.resource_stockpiles={}
		stock({"Machine Load Test Sets":1.0,"Paper":1.0,"Refined Copper":1.0})
		var fiber:=float(state.resource_stockpiles["Fiber Plants"])
		var job:=line();job.machine_wear=0.0
		S.prepare(job,{},.25)
		S.prepare(job,{},.1);S.prepare(job,{},.1);S.prepare(job,{},.1)
		assert_int(job.machine_support.observations.size()).is_equal(1)
		assert_float(float(state.resource_stockpiles["Fiber Plants"])).is_equal_approx(fiber-float(Bills.flatten({"Paper":.01,"Refined Copper":.005})["Fiber Plants"]),.000001)
	)

func test_bearing_load_speed_and_flow_constrain_supported_work()->void:
	WorldSimulation.scoped("machine_support",func()->void:
		WorldSimulation.state.known_discoveries.append("fluid_film_bearings")
		WorldSimulation.state.resource_stockpiles={}
		stock({"Water-Film Bearing Sets":1.0})
		var job:=line();job.machine_wear=0.0;S.prepare(job,{},1)
		WorldSimulation.state.resource_stockpiles.Freshwater=1.0
		assert_float(S.limit_work(job,1,{"bearing_load":2.0,"bearing_speed":0.0})).is_equal(0.0)
		assert_float(S.limit_work(job,1,{"bearing_load":1.0,"bearing_speed":1.0})).is_equal(1.0)
		S.consume(job,1)
		assert_float(float(job.machine_support.film_observation.separation)).is_greater(.8)
		assert_float(float(job.machine_support.film_observation.water)).is_equal(.05)
		assert_float(S.film_separation(1,10,0)).is_equal(0.0)
		assert_bool(S.valid(job.machine_support,0)).is_true()
	)
func test_clogged_filter_stops_work_until_paid_partial_service_finishes()->void:
	WorldSimulation.scoped("machine_support",func()->void:
		var state=WorldSimulation.state
		state.known_discoveries.append("cutting_fluid_management")
		state.resource_stockpiles={}
		stock({"Machining Water Filter Sets":1.0,"Woven Cloth":1.0})
		var job:=line();S.prepare(job,{},1)
		state.resource_stockpiles.Freshwater=10.0
		S.consume(job,S.limit_work(job,10))
		assert_float(S.limit_work(job,1)).is_equal(0.0)
		var cloth:=float(state.resource_stockpiles["Fiber Plants"])
		assert_float(S.service_filter(job,.1)).is_equal(0.0)
		var restored:Dictionary=bytes_to_var(var_to_bytes(job))
		assert_float(S.service_filter(restored,.2)).is_equal_approx(.1,.000001)
		assert_float(float(state.resource_stockpiles["Fiber Plants"])).is_equal_approx(cloth-float(Bills.flatten({"Woven Cloth":.01})["Fiber Plants"]),.000001)
		assert_float(S.limit_work(restored,1)).is_equal(1.0)
		assert_float(float(state.resource_stockpiles["Spent Machining Filters"])).is_equal(.01)
	)
