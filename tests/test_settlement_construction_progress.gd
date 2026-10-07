extends GdUnitTestSuite
const VisualState:=preload("res://scripts/settlement_construction_state.gd")

func before_test()->void:
	WorldSimulation.clear()
	WorldSimulation.create_actor("builders",1301)

func after_test()->void:WorldSimulation.clear()

func _found_at_day_30()->void:
	var state=WorldSimulation.state
	state.ensure_population_total(80)
	state.settlement_completed.assign(["Hearth Circle"])
	state.settlement_site_committed=true;state.convoy_traveling=false
	state.population_allocations.Construction=0
	state.population_health=1.0;state.simulation_metrics.labor_efficiency=1.0
	state.elapsed_days=30
	WorldSimulation.settlements.ensure_founded()
	WorldSimulation.settlements.process_local_month()

func _completion_count(plot_id:int)->int:
	var count:=0
	for event:Dictionary in WorldSimulation.state.settlement_plot_history:
		if int(event.get("plot_id",-1))==plot_id and String(event.get("event",""))=="construction_completed":count+=1
	return count

func test_actual_household_passes_four_daily_stages_and_completes_once_at_existing_boundary()->void:
	WorldSimulation.scoped("builders",func()->void:
		_found_at_day_30()
		var state=WorldSimulation.state;var model=WorldSimulation.settlements
		state.ensure_population_total(240)
		state.known_discoveries.append("lime_mortar");state.discovery_adoption.lime_mortar=1.0
		state.resource_stockpiles={"Stone":4.0,"Building Mortar":1.0,"Timber":.8,"Freshwater":0.0}
		var stocks:Dictionary=state.resource_stockpiles.duplicate(true)
		var events:Array[Dictionary]=[];var old_count:int=state.settlement_plots.size()
		# The real third monthly action chooses an edge household rather than infill.
		assert_bool(model._attempt_household_growth(30,events,{},2)).is_true()
		assert_int(state.settlement_plots.size()).is_equal(old_count+1)
		var plot:Dictionary=state.settlement_plots.back()
		assert_str(String(plot.status)).is_equal("under_construction")
		var revision:int=state.morphology_revision
		var history_count:int=state.settlement_plot_history.size()
		var allocations:Dictionary=state.population_allocations.duplicate(true)
		for index in 4:
			state.elapsed_days=[30,38,45,53][index]
			assert_array(model.process_local_month()).is_empty()
			assert_int(int(VisualState.state(plot).stage)).is_equal(index)
			assert_str(String(plot.status)).is_equal("under_construction")
			assert_dict(state.resource_stockpiles).is_equal(stocks)
			assert_int(state.population_total).is_equal(240)
			assert_dict(state.population_allocations).is_equal(allocations)
			assert_int(state.morphology_revision).is_equal(revision)
			assert_int(state.settlement_plot_history.size()).is_equal(history_count)
		assert_int(_completion_count(int(plot.id))).is_zero()
		state.elapsed_days=60;model.process_local_month()
		assert_str(String(plot.status)).is_equal("active")
		assert_float(float(plot.construction_progress)).is_equal(1.0)
		assert_int(int(VisualState.state(plot).stage)).is_equal(4)
		assert_int(_completion_count(int(plot.id))).is_equal(1)
		var completed_revision:int=state.morphology_revision
		model.process_local_month();model.process_month()
		assert_int(_completion_count(int(plot.id))).is_equal(1)
		assert_int(state.morphology_revision).is_equal(completed_revision)
		# Other monthly route work may spend raw stock. This drawn household
		# does not introduce a mortar payment or supplied curing interval.
		assert_float(float(state.resource_stockpiles["Building Mortar"])).is_equal(1.0)
		assert_float(float(state.resource_stockpiles.Freshwater)).is_equal(0.0)
	)

func test_serialized_legacy_dates_and_repeated_days_preserve_milestone_and_other_state()->void:
	WorldSimulation.scoped("builders",func()->void:
		# These predate construction_started_day. JSON round-trip uses the same
		# numeric/key representation as old serialized drawing records.
		var saved:Array=JSON.parse_string(JSON.stringify([
			{"id":1,"status":"under_construction","created_day":4,"last_update_day":30,"construction_progress":0.0},
			{"id":2,"status":"under_construction","created_day":30,"construction_progress":0.0},
			{"id":3,"status":"active","created_day":0,"construction_progress":1.0},
			{"id":4,"status":"ruin","created_day":0,"construction_progress":0.12}]))
		WorldSimulation.state.settlement_plots.assign(saved)
		var model=WorldSimulation.settlements
		var untouched_active:Dictionary=saved[2].duplicate(true)
		var untouched_ruin:Dictionary=saved[3].duplicate(true)
		model._advance_plot_construction_progress(38.0)
		for plot:Dictionary in [saved[0],saved[1]]:
			assert_float(float(plot.construction_progress)).is_equal_approx(8.0/30.0,.000001)
			assert_int(int(VisualState.state(plot).stage)).is_equal(1)
		var signature:Array=VisualState.signature(saved[0])
		model._advance_plot_construction_progress(39.0)
		assert_array(VisualState.signature(saved[0])).is_equal(signature)
		var repeated:Dictionary=saved[0].duplicate(true)
		model._advance_plot_construction_progress(39.0)
		model._advance_plot_construction_progress(35.0)
		assert_dict(saved[0]).is_equal(repeated)
		model._advance_plot_construction_progress(60.0)
		assert_str(String(saved[0].status)).is_equal("under_construction")
		assert_float(float(saved[0].construction_progress)).is_less(1.0)
		assert_dict(saved[2]).is_equal(untouched_active)
		assert_dict(saved[3]).is_equal(untouched_ruin)
		assert_int(WorldSimulation.state.morphology_revision).is_zero()
		assert_array(WorldSimulation.state.settlement_plot_history).is_empty()
	)

func test_actual_ruin_reconstruction_records_new_start_instead_of_old_foundation_age()->void:
	WorldSimulation.scoped("builders",func()->void:
		_found_at_day_30()
		var state=WorldSimulation.state;var model=WorldSimulation.settlements
		state.population_allocations.Construction=20
		var plot:Dictionary=state.settlement_plots[0]
		plot.status="ruin";plot.pre_damage_use=String(plot.land_use)
		plot.damaged_day=0;plot.created_day=0;plot.last_update_day=30
		plot.construction_progress=1.0
		# Select a real seeded monthly rebuilding roll, without altering the RNG
		# or increasing the production reconstruction probability.
		var day:=0;var rng:=RandomNumberGenerator.new()
		for month in range(13,525):
			var candidate:=month*30
			rng.seed=state.world_seed^candidate^0x27d4eb2d
			if rng.randf()<1.0/24.0:day=candidate;break
		assert_int(day).is_greater(0)
		state.elapsed_days=day
		var events:Array[Dictionary]=[]
		model._process_occupancy_and_maintenance(day,events)
		assert_str(String(plot.status)).is_equal("under_construction")
		assert_int(int(plot.get("construction_started_day",-1))).is_equal(day)
		assert_float(float(plot.construction_progress)).is_equal(0.0)
		model._advance_plot_construction_progress(float(day+8))
		assert_float(float(plot.construction_progress)).is_equal_approx(8.0/30.0,.000001)
		assert_int(int(VisualState.state(plot).stage)).is_equal(1)
	)

func test_daily_construction_progress_is_scoped_to_the_actual_owner()->void:
	WorldSimulation.create_actor("neighbor",1302)
	for owner:String in ["builders","neighbor"]:
		WorldSimulation.scoped(owner,func()->void:
			WorldSimulation.state.settlement_plots.assign([{"id":1,"status":"under_construction","construction_started_day":30,"construction_progress":0.0}])
		)
	WorldSimulation.scoped("builders",func()->void:
		WorldSimulation.settlements._advance_plot_construction_progress(53.0)
		assert_int(int(VisualState.state(WorldSimulation.state.settlement_plots[0]).stage)).is_equal(3)
	)
	WorldSimulation.scoped("neighbor",func()->void:
		assert_float(float(WorldSimulation.state.settlement_plots[0].construction_progress)).is_equal(0.0)
		assert_int(WorldSimulation.state.morphology_revision).is_zero()
		assert_array(WorldSimulation.state.settlement_plot_history).is_empty()
	)
