extends GdUnitTestSuite
const K=preload("res://scripts/glass_ceramic_process_knowledge.gd")
const I=preload("res://scripts/civilian_industry.gd")
const P=preload("res://scripts/persistent_production.gd")
const ITEMS=["graded_glass_cullet","cullet_glass","annealed_glass_blanks","annealed_optical_lenses","pottery_plaster_molds","stoneware_body","formed_stoneware_vessels","slip_cast_stoneware","fired_cast_stoneware","glazed_stoneware_vessels","stoneware_purified_brine"]
const INTERMEDIATES=["Graded Glass Cullet","Annealed Glass Blanks","Pottery Plaster Molds","Stoneware Body","Stoneware Vessels","Dry Cast Stoneware","Glazed Stoneware Vessels"]
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("ceramics",128)
func after_test()->void:WorldSimulation.clear()
func learn(id:String)->void:
	if id not in WorldSimulation.state.known_discoveries:WorldSimulation.state.known_discoveries.append(id)
	WorldSimulation.state.discovery_adoption[id]=1.0
func prepare()->void:
	var s=WorldSimulation.state;s.population_allocations.Crafting=100;s.population_allocations.Logistics=100;s.population_health=1.0;s.simulation_metrics.labor_efficiency=1.0
	for item:String in ITEMS:
		var spec:=I.product(item);learn(spec.gate)
		for resource:String in spec.materials.keys()+spec.tooling.keys():
			if resource not in INTERMEDIATES:s.resource_stockpiles[resource]=1000.0
func make(item:String,count:int)->void:
	var spec:=I.product(item)
	var target:=int(WorldSimulation.state.resource_stockpiles.get(spec.output,0))+count
	var started:=WorldSimulation.military.start_production_line(item,target)
	assert_bool(started.get("ok",false)).override_failure_message(str(started)).is_true()
	if not started.get("ok",false):return
	var job:Dictionary=WorldSimulation.military.equipment_queue.back()
	P.advance(WorldSimulation.military,job,1000)
	assert_int(int(job.completed)).is_equal(count)
	WorldSimulation.military.cancel_equipment_job(int(job.id))
func test_five_methods_have_operating_routes_and_no_flat_effects()->void:
	WorldSimulation.scoped("ceramics",func()->void:
		assert_int(K.entries().size()).is_equal(5)
		assert_array(preload("res://scripts/technology_catalog_contract.gd").validate(K.entries(),WorldSimulation.discovery.technology_catalog)).is_empty()
		for e:Dictionary in K.entries():assert_dict(e.effects).is_empty()
		for item:String in ITEMS:assert_bool(I.product(item).is_empty()).is_false())
func test_recorded_cullet_remelts_with_real_yield_loss_and_fuel()->void:
	WorldSimulation.scoped("ceramics",func()->void:
		prepare();var s=WorldSimulation.state
		make("graded_glass_cullet",2)
		assert_float(float(s.resource_stockpiles.Glass)).is_equal(997.5)
		assert_float(float(s.resource_stockpiles["Clay Record Tablets"])).is_equal_approx(999.96,.000001)
		var fuel:=float(s.resource_stockpiles.Timber)
		make("cullet_glass",1)
		assert_float(float(s.resource_stockpiles.Glass)).is_equal(998.5)
		assert_float(float(s.resource_stockpiles["Graded Glass Cullet"])).is_equal(1.0)
		assert_float(float(s.resource_stockpiles.Timber)).is_equal_approx(fuel-1.8,.000001))
func test_annealed_blanks_feed_actual_lens_mounts()->void:
	WorldSimulation.scoped("ceramics",func()->void:
		prepare();var s=WorldSimulation.state
		make("annealed_glass_blanks",1);make("annealed_optical_lenses",1)
		assert_float(float(s.resource_stockpiles["Annealed Glass Blanks"])).is_equal(0.0)
		learn("lens_centering");s.resource_stockpiles["Wrought Iron"]=10.0
		make("centered_lens_mount",1)
		assert_float(float(s.resource_stockpiles["Optical Lenses"])).is_equal(0.0)
		assert_float(float(s.resource_stockpiles["Centered Lens Mounts"])).is_equal(1.0))
func test_casting_needs_molds_and_separate_paid_firing_and_glazing()->void:
	WorldSimulation.scoped("ceramics",func()->void:
		prepare();var s=WorldSimulation.state
		make("stoneware_body",4)
		var before:Dictionary=s.resource_stockpiles.duplicate(true)
		assert_bool(WorldSimulation.military.start_production_line("slip_cast_stoneware",1).has("error")).is_true()
		assert_dict(s.resource_stockpiles).is_equal(before)
		make("pottery_plaster_molds",3);make("slip_cast_stoneware",3)
		assert_float(float(s.resource_stockpiles.get("Stoneware Vessels",0))).is_equal(0.0)
		assert_float(float(s.resource_stockpiles["Pottery Plaster Molds"])).is_equal_approx(.94,.000001)
		make("fired_cast_stoneware",3)
		assert_float(float(s.resource_stockpiles["Dry Cast Stoneware"])).is_equal(0.0)
		assert_bool(WorldSimulation.military.start_production_line("stoneware_purified_brine",1).has("error")).is_true()
		make("glazed_stoneware_vessels",2)
		assert_float(float(s.resource_stockpiles["Stoneware Vessels"])).is_equal_approx(.8,.000001)
		var salt:=float(s.resource_stockpiles.Salt);make("stoneware_purified_brine",1)
		assert_float(float(s.resource_stockpiles["Glazed Stoneware Vessels"])).is_equal(0.0)
		assert_float(float(s.resource_stockpiles["Purified Brine"])).is_equal(1.0)
		assert_float(float(s.resource_stockpiles.Salt)).is_equal(salt-1.0))
func test_imported_glazed_vessels_work_without_manufacturing_mastery()->void:
	WorldSimulation.scoped("ceramics",func()->void:
		prepare();var s=WorldSimulation.state
		for e:Dictionary in K.entries():s.known_discoveries.erase(e.id)
		s.resource_stockpiles["Glazed Stoneware Vessels"]=2.0
		make("stoneware_purified_brine",1)
		assert_float(float(s.resource_stockpiles["Purified Brine"])).is_equal(1.0)
		assert_bool("ceramic_glaze_formulation" in s.known_discoveries).is_false())
func test_partial_firing_roundtrips_without_duplicate_inputs()->void:
	WorldSimulation.scoped("ceramics",func()->void:
		prepare();var s=WorldSimulation.state
		make("stoneware_body",2)
		assert_bool(WorldSimulation.military.start_production_line("formed_stoneware_vessels",1).get("ok",false)).is_true()
		var job:Dictionary=WorldSimulation.military.equipment_queue.back();P.advance(WorldSimulation.military,job,1)
		assert_float(float(s.resource_stockpiles.get("Stoneware Vessels",0))).is_equal(0.0)
		var stock:Dictionary=s.resource_stockpiles.duplicate(true)
		var restored:Dictionary=bytes_to_var(var_to_bytes(job))
		assert_str(P.validate_saved({"equipment_queue":[restored]})).is_empty()
		P.advance(WorldSimulation.military,restored,100)
		assert_float(float(s.resource_stockpiles["Stoneware Vessels"])).is_equal(1.0)
		for item:String in I.product("formed_stoneware_vessels").materials:
			assert_float(float(s.resource_stockpiles[item])).is_equal_approx(float(stock[item])-float(I.product("formed_stoneware_vessels").materials[item])*.75,.000001)
		P.advance(WorldSimulation.military,restored,100)
		assert_float(float(s.resource_stockpiles["Stoneware Vessels"])).is_equal(1.0))
