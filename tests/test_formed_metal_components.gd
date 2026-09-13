extends GdUnitTestSuite
const K=preload("res://scripts/formed_metal_knowledge.gd")
const I=preload("res://scripts/civilian_industry.gd")
const P=preload("res://scripts/persistent_production.gd")
const F=preload("res://scripts/civilian_production_planner.gd")
const Ops=preload("res://scripts/technology_operations.gd")
const ITEMS=["metal_spinning_tool_sets", "spun_motor_shrouds", "rotary_swaging_dies", "cast_terminal_pin_blanks", "swaged_terminal_pins", "terminated_motor_leads", "formed_component_motors", "centrifugal_tube_molds", "centrifugal_steel_tube_blanks", "bored_steel_tubes", "tube_bend_tool_sets", "formed_steel_pipe_bends", "qualified_bent_pipe_fittings", "channel_roll_tool_sets", "roll_formed_channels", "qualified_channel_press_frames", "channel_frame_pneumatic_presses", "continuity_test_sets"]
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("formed",1209)
func after_test()->void:
	WorldSimulation.clear();GameState.set_process(true);CivilizationSystem.set_process(true);MilitaryCampaign.set_process(true)
func learn(id:String)->void:
	if id not in WorldSimulation.state.known_discoveries:WorldSimulation.state.known_discoveries.append(id)
	WorldSimulation.state.discovery_adoption[id]=1.0
func outputs()->Array[String]:
	var out:Array[String]=[]
	for item:String in ITEMS:
		var name:=String(I.product(item).output)
		if name not in out:out.append(name)
	return out
func prepare()->void:
	var state=WorldSimulation.state
	state.settlement_site_committed=true;state.convoy_traveling=false
	state.population_health=1;state.simulation_metrics.labor_efficiency=1
	state.population_allocations.Crafting=100;state.population_allocations.Logistics=100
	var made:=outputs()
	for item:String in ITEMS:
		var spec:=I.product(item);learn(spec.gate)
		for field:String in ["materials","tooling"]:
			for r:String in spec[field]:
				if r not in made:state.resource_stockpiles[r]=1000.0
	for r:String in made:state.resource_stockpiles[r]=0.0
	Ops.data().last_day=int(state.elapsed_days);Ops.data().services={"electricity":1000.0}
func provision(item:String)->Dictionary:
	var spec:=I.product(item);learn(spec.gate)
	for field:String in ["materials","tooling"]:
		for r:String in spec[field]:WorldSimulation.state.resource_stockpiles[r]=100.0
	WorldSimulation.state.resource_stockpiles[spec.output]=0.0
	Ops.data().last_day=int(WorldSimulation.state.elapsed_days);Ops.data().services={"electricity":1000.0}
	return start(item,1)
func start(item:String,target:int)->Dictionary:
	var result:=WorldSimulation.military.start_production_line(item,target)
	assert_bool(result.get("ok",false)).override_failure_message(str(result)).is_true()
	return WorldSimulation.military.equipment_queue.back() if result.get("ok",false) else {}
func make(item:String,target:int)->void:
	var job:=start(item,target)
	if job.is_empty():return
	P.advance(WorldSimulation.military,job,1000)
	assert_float(float(WorldSimulation.state.resource_stockpiles.get(I.product(item).output,0))).is_greater_equal(float(target))
	WorldSimulation.military.cancel_equipment_job(int(job.id))
func test_five_original_definitions_and_eighteen_paid_routes()->void:
	WorldSimulation.scoped("formed",func()->void:
		assert_int(K.entries().size()).is_equal(5)
		assert_array(preload("res://scripts/technology_catalog_contract.gd").validate(K.entries(),WorldSimulation.discovery.technology_catalog)).is_empty()
		var expected={"metal_spinning_forming":["centre_lathe_assembly","sheet_steel_rolling"],"rotary_swaging":["precision_machinery","toolbit_heat_treatment"],"tube_rotary_draw_bending":["precision_machinery","stress_strain_relations"],"roll_formed_sections":["sheet_steel_rolling","shaft_alignment_methods"],"centrifugal_tube_casting":["metal_casting_feed_design","precision_machinery"]}
		for e:Dictionary in K.entries():
			assert_array(e.requires_all).is_equal(expected[e.id]);assert_array(e.requires_any).is_empty()
		for item:String in ITEMS:assert_bool(I.product(item).is_empty()).is_false())
func test_all_eighteen_routes_pay_fractional_material_power_and_resume_once()->void:
	WorldSimulation.scoped("formed",func()->void:
		for item:String in ITEMS:
			var spec:=I.product(item);var job:=provision(item)
			if job.is_empty():return
			var before:Dictionary=WorldSimulation.state.resource_stockpiles.duplicate(true);var power:=Ops.service("electricity")
			P.advance(WorldSimulation.military,job,float(spec.days)/2)
			assert_int(int(job.completed)).is_equal(0)
			var saved:Dictionary=bytes_to_var(var_to_bytes(job));assert_str(P.validate_saved({"equipment_queue":[saved]})).is_empty()
			P.advance(WorldSimulation.military,saved,float(spec.days)/2)
			assert_float(float(WorldSimulation.state.resource_stockpiles[spec.output])).override_failure_message(item).is_equal(1.0)
			for r:String in spec.materials:assert_float(float(before[r])-float(WorldSimulation.state.resource_stockpiles[r])).is_equal_approx(float(spec.materials[r]),.000001)
			assert_float(power-Ops.service("electricity")).is_equal_approx(float(spec.get("power",0)),.000001)
			before=WorldSimulation.state.resource_stockpiles.duplicate(true);P.advance(WorldSimulation.military,saved,100)
			assert_dict(WorldSimulation.state.resource_stockpiles).is_equal(before)
			WorldSimulation.military.cancel_equipment_job(int(job.id)))
func test_spinning_and_swaging_reach_actual_motor_assembly()->void:
	WorldSimulation.scoped("formed",func()->void:
		prepare();var state=WorldSimulation.state;var copper:=float(state.resource_stockpiles["Refined Copper"])
		for step:Array in [["metal_spinning_tool_sets",1],["spun_motor_shrouds",1],["rotary_swaging_dies",2],["cast_terminal_pin_blanks",4],["swaged_terminal_pins",4],["continuity_test_sets",1],["terminated_motor_leads",1],["formed_component_motors",1]]:make(step[0],step[1])
		for r:String in ["Spun Steel Shrouds","Copper Terminal Pin Blanks","Swaged Copper Terminal Pins","Terminated Motor Leads"]:assert_float(float(state.resource_stockpiles[r])).is_equal(0.0)
		assert_float(float(state.resource_stockpiles["Electric Motors"])).is_equal(1.0)
		assert_float(float(state.resource_stockpiles["Refined Copper"])).is_less(copper)
		assert_float(Ops.service("electricity")).is_equal_approx(999.95,.000001))
func test_cast_bend_and_roll_chains_reach_supplied_pneumatic_workshop()->void:
	WorldSimulation.scoped("formed",func()->void:
		prepare();var state=WorldSimulation.state
		# Existing motors and pneumatic-cylinder internals are boundary inputs, not new free outputs.
		state.resource_stockpiles["Electric Motors"]=10.0
		for step:Array in [["centrifugal_tube_molds",1],["centrifugal_steel_tube_blanks",2],["bored_steel_tubes",2],["tube_bend_tool_sets",2],["formed_steel_pipe_bends",2],["qualified_bent_pipe_fittings",2],["channel_roll_tool_sets",2],["roll_formed_channels",2],["qualified_channel_press_frames",1]]:make(step[0],step[1])
		var spec:=I.product("pneumatic_cylinder");learn(spec.gate)
		for field:String in ["materials","tooling"]:
			for r:String in spec[field]:
				if r not in outputs():state.resource_stockpiles[r]=100.0
		state.resource_stockpiles["Pneumatic Cylinders"]=0.0;make("pneumatic_cylinder",1)
		make("channel_frame_pneumatic_presses",1)
		for r:String in ["Centrifugal Steel Tube Blanks","Bored Steel Tubes","Formed Steel Pipe Bends","Roll-Formed Steel Channels","Qualified Channel Press Frames"]:assert_float(float(state.resource_stockpiles[r])).is_equal(0.0)
		learn("pneumatic_pressing");learn("compressed_air_systems");state.resource_stockpiles["Compressed Air"]=10.0
		assert_bool(Ops.install("pneumatic_workshop").get("ok",false)).is_true()
		assert_float(float(state.resource_stockpiles["Pneumatic Presses"])).is_equal(0.0)
		assert_float(float(state.resource_stockpiles["Pressure Pipe Fittings"])).is_equal(0.0)
		for day:int in range(1,12):state.elapsed_days=day;Ops.advance(day)
		assert_float(Ops.service("mechanical_work")).is_equal(3.0)
		state.resource_stockpiles["Compressed Air"]=.25;state.elapsed_days=12;Ops.advance(12)
		assert_float(Ops.service("mechanical_work")).is_equal(1.5)
		assert_float(float(state.resource_stockpiles["Compressed Air"])).is_equal(0.0)
		state.elapsed_days=13;Ops.advance(13);assert_float(Ops.service("mechanical_work")).is_equal(0.0))
func test_unmachined_blanks_and_unqualified_sections_cannot_bypass_consumers()->void:
	WorldSimulation.scoped("formed",func()->void:
		var state=WorldSimulation.state
		for pair:Array in [["formed_steel_pipe_bends","Bored Steel Tubes","Centrifugal Steel Tube Blanks"],["channel_frame_pneumatic_presses","Qualified Channel Press Frames","Roll-Formed Steel Channels"],["terminated_motor_leads","Swaged Copper Terminal Pins","Copper Terminal Pin Blanks"]]:
			var spec:=I.product(pair[0]);learn(spec.gate)
			for field:String in ["materials","tooling"]:
				for r:String in spec[field]:state.resource_stockpiles[r]=10.0
			state.resource_stockpiles[pair[1]]=0.0;state.resource_stockpiles[pair[2]]=10.0
			var before:Dictionary=state.resource_stockpiles.duplicate(true)
			assert_bool(WorldSimulation.military.start_production_line(pair[0],1).has("error")).is_true()
			assert_dict(state.resource_stockpiles).is_equal(before))
func test_missing_and_partial_shared_power_bound_casting_before_feed_debit()->void:
	WorldSimulation.scoped("formed",func()->void:
		var job:=provision("centrifugal_steel_tube_blanks");var state=WorldSimulation.state
		Ops.data().services={};var before:Dictionary=state.resource_stockpiles.duplicate(true)
		P.advance(WorldSimulation.military,job,100);assert_dict(state.resource_stockpiles).is_equal(before)
		Ops.data().services={"electricity":.25};P.advance(WorldSimulation.military,job,100)
		assert_float(float(job.progress_days)).is_equal(1.0)
		assert_float(float(before.Steel)-float(state.resource_stockpiles.Steel)).is_equal_approx(.6,.000001)
		assert_float(Ops.service("electricity")).is_equal(0.0)
		before=state.resource_stockpiles.duplicate(true);P.advance(WorldSimulation.military,job,100);assert_dict(state.resource_stockpiles).is_equal(before)
		Ops.data().services={"electricity":.75};P.advance(WorldSimulation.military,job,100)
		assert_float(float(state.resource_stockpiles["Centrifugal Steel Tube Blanks"])).is_equal(1.0))
func test_imported_bored_tubes_allow_known_bending_without_casting_mastery()->void:
	WorldSimulation.scoped("formed",func()->void:
		var spec:=I.product("formed_steel_pipe_bends")
		for field:String in ["materials","tooling"]:
			for r:String in spec[field]:WorldSimulation.state.resource_stockpiles[r]=10.0
		assert_bool(P.recipe(WorldSimulation.military,"formed_steel_pipe_bends").has("error")).is_true()
		learn("tube_rotary_draw_bending");var job:=start("formed_steel_pipe_bends",1);P.advance(WorldSimulation.military,job,3)
		assert_int(int(job.completed)).is_equal(1)
		assert_bool("centrifugal_tube_casting" in WorldSimulation.state.known_discoveries).is_false())
func test_planner_and_controller_follow_supplied_channel_demand()->void:
	WorldSimulation.scoped("formed",func()->void:
		prepare();var state=WorldSimulation.state;var spec:=I.product("roll_formed_channels")
		for field:String in ["materials","tooling"]:
			for r:String in spec[field]:state.resource_stockpiles[r]=10.0
		var order:=F.supply("Roll-Formed Steel Channels",1,{})
		assert_str(String(order.get("item",""))).is_equal("roll_formed_channels")
		preload("res://scripts/civilization_controller.gd").production_order("formed",order)
		assert_array(WorldSimulation.military.equipment_queue).is_not_empty()
		if WorldSimulation.military.equipment_queue.is_empty():return
		P.advance(WorldSimulation.military,WorldSimulation.military.equipment_queue.back(),2)
		assert_float(float(state.resource_stockpiles["Roll-Formed Steel Channels"])).is_equal(1.0))
func test_full_save_retains_partial_bending_and_other_actor_stocks()->void:
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	WorldSimulation.create_actor("other",1210)
	WorldSimulation.scoped("other",func()->void:WorldSimulation.state.resource_stockpiles["Bored Steel Tubes"]=7.0)
	WorldSimulation.scoped("formed",func()->void:
		var job:=provision("formed_steel_pipe_bends");P.advance(WorldSimulation.military,job,1.5))
	var slot:="formed_metal_%d"%OS.get_process_id()
	assert_bool(SaveSystem.save_game(slot).get("ok",false)).is_true()
	WorldSimulation.clear();var result:=SaveSystem.load_game(slot);DirAccess.remove_absolute(SaveSystem.slot_path(slot))
	assert_bool(result.get("ok",false)).override_failure_message(str(result)).is_true()
	if not result.get("ok",false):return
	WorldSimulation.scoped("formed",func()->void:
		var job:Dictionary=WorldSimulation.military.equipment_queue.back()
		assert_float(float(job.progress_days)).is_equal(1.5);P.advance(WorldSimulation.military,job,1.5)
		var stock:Dictionary=WorldSimulation.state.resource_stockpiles.duplicate(true);P.advance(WorldSimulation.military,job,100)
		assert_dict(WorldSimulation.state.resource_stockpiles).is_equal(stock)
		assert_float(float(stock["Formed Steel Pipe Bends"])).is_equal(1.0))
	WorldSimulation.scoped("other",func()->void:assert_float(float(WorldSimulation.state.resource_stockpiles["Bored Steel Tubes"])).is_equal(7.0))
func test_actual_daily_generation_supplies_paid_rolling_work_once()->void:
	WorldSimulation.scoped("formed",func()->void:
		prepare();var job:=provision("roll_formed_channels");job.target_stock=100
		var state=WorldSimulation.state;var gen:Dictionary=Ops.PLANTS.steam_generator;learn(gen.gate)
		for id:String in gen.requires:learn(id)
		for r:String in gen.cost:state.resource_stockpiles[r]=100.0
		state.resource_stockpiles.Coal=100.0;state.resource_stockpiles.Food=100000.0;state.resource_stockpiles.Freshwater=100000.0
		assert_bool(Ops.install("steam_generator").get("ok",false)).is_true()
		Ops.data().services={}
		var day=preload("res://scripts/civilization_day.gd");var context:Dictionary=day.context(Vector2.ZERO)
		# An observed adjacent source supplies the normal daily water owner.
		context.merge({"surface_water_distance_km":0.0,"surface_water_kind":"fixture observed river","surface_water_id":"forming_river"},true)
		var completed_day:=0
		for n:int in range(1,61):
			day.advance(n,context)
			if float(job.completed)*float(job.work_per_item)+float(job.progress_days)>0:
				completed_day=n;break
		assert_float(float(job.last_work)).is_greater(0.0)
		assert_float(float(job.last_consumed.get("Steel Sheets",0))).is_greater(0.0)
		assert_int(completed_day).is_greater(0)
		assert_int(int(Ops.data().plants.steam_generator.installed)).is_equal(1)
		assert_float(float(Ops.data().inputs.get("Coal",0))).is_greater(0.0)
		assert_float(float(state.water_metrics.get("collected_today",0))).is_greater(0.0)
		var worked:=float(job.completed)*float(job.work_per_item)+float(job.progress_days)
		day.advance(completed_day,context)
		assert_float(float(job.completed)*float(job.work_per_item)+float(job.progress_days)).is_equal(worked))
