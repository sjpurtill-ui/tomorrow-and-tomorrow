extends GdUnitTestSuite
const K=preload("res://scripts/textile_mechanization.gd")
const I=preload("res://scripts/civilian_industry.gd")
const P=preload("res://scripts/persistent_production.gd")
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("mill_ruler",995)
func after_test()->void:WorldSimulation.clear()
func prepare(item:String)->Dictionary:
	var recipe:=I.product(item)
	WorldSimulation.state.known_discoveries.append(recipe.gate);WorldSimulation.state.discovery_adoption[recipe.gate]=1.0
	for material:String in recipe.materials:WorldSimulation.state.resource_stockpiles[material]=20.0
	for material:String in recipe.tooling:WorldSimulation.state.resource_stockpiles[material]=20.0
	assert_bool(WorldSimulation.military.start_production_line(item,1).get("ok",false)).is_true()
	return WorldSimulation.military.equipment_queue.back()
func test_six_mechanisms_have_valid_distinct_contracts()->void:
	WorldSimulation.scoped("mill_ruler",func()->void:
		assert_int(K.entries().size()).is_equal(6)
		assert_array(preload("res://scripts/technology_catalog_contract.gd").validate(K.entries(),WorldSimulation.discovery.technology_catalog)).is_empty()
	)
func test_hand_frame_and_shuttle_work_without_electricity()->void:
	WorldSimulation.scoped("mill_ruler",func()->void:
		for item:String in ["wheel_spun_yarn","flyer_spun_yarn","frame_spun_yarn","hand_mule_yarn","shuttle_woven_cloth"]:
			var recipe:=I.product(item);WorldSimulation.state.resource_stockpiles[recipe.output]=0.0
			var job:=prepare(item)
			P.advance(WorldSimulation.military,job,float(recipe.days))
			assert_float(float(WorldSimulation.state.resource_stockpiles[recipe.output])).is_equal(1.0)
			assert_int(int(job.completed)).is_equal(1)
			assert_bool(WorldSimulation.military.cancel_equipment_job(int(job.id)).get("cancelled",false)).is_true()
	)
func test_electric_routes_stop_without_power_and_share_finite_energy()->void:
	WorldSimulation.scoped("mill_ruler",func()->void:
		var yarn:=prepare("electric_mule_yarn")
		var before:=WorldSimulation.state.resource_stockpiles.duplicate(true)
		P.advance(WorldSimulation.military,yarn,10.0)
		assert_dict(WorldSimulation.state.resource_stockpiles).is_equal(before)
		WorldSimulation.state.technology_operations.last_day=int(WorldSimulation.state.elapsed_days)
		WorldSimulation.state.technology_operations.services.electricity=2.0
		P.advance(WorldSimulation.military,yarn,10.0)
		assert_int(int(yarn.completed)).is_equal(1)
		assert_bool(WorldSimulation.military.cancel_equipment_job(int(yarn.id)).get("cancelled",false)).is_true()
		var cloth:=prepare("power_woven_cloth")
		before=WorldSimulation.state.resource_stockpiles.duplicate(true)
		P.advance(WorldSimulation.military,cloth,10.0)
		assert_int(int(cloth.completed)).is_equal(0)
		assert_dict(WorldSimulation.state.resource_stockpiles).is_equal(before)
		assert_float(float(WorldSimulation.state.technology_operations.services.electricity)).is_equal(0.0)
	)
func test_powered_partial_work_roundtrip_cannot_duplicate_cloth()->void:
	WorldSimulation.scoped("mill_ruler",func()->void:
		var job:=prepare("power_woven_cloth")
		WorldSimulation.state.technology_operations.last_day=int(WorldSimulation.state.elapsed_days)
		WorldSimulation.state.technology_operations.services.electricity=1.0
		P.advance(WorldSimulation.military,job,1.0)
		assert_int(int(job.completed)).is_equal(0)
		var restored:Dictionary=JSON.parse_string(JSON.stringify(job))
		assert_str(P.validate_saved({"equipment_queue":[restored]})).is_empty()
		WorldSimulation.state.technology_operations.services.electricity=1.0
		P.advance(WorldSimulation.military,restored,1.0);P.advance(WorldSimulation.military,restored,100.0)
		assert_float(float(WorldSimulation.state.resource_stockpiles["Woven Cloth"])).is_equal(1.0)
	)
