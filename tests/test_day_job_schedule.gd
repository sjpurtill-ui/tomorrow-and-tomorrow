extends GdUnitTestSuite
## A world day split into bounded steps must commit exactly what the synchronous
## day commits, and must never leave a foreign scope active between steps.
const DAY=preload("res://scripts/civilization_day.gd")
const DAYS:=6

func after_test()->void:
	WorldSimulation.clear()
	WorldSimulation.context_provider=Callable()

func _new_world()->void:
	WorldSimulation.clear()
	GameState.reset_for_new_world(9241)
	MilitaryCampaign.reset_for_new_world()
	GameState.opponent_count=3
	CivilizationSystem.reset_for_new_world()
	DiscoverySystem.reset_for_new_world()
	DiscoverySystem.initialize()
	WorldSimulation.context_provider=func(_point:Vector2)->Dictionary:return {"environment_profile":PlanetEnvironment.profile_at(Vector2.ZERO),"surface_water_distance_km":.1,"surface_water_recognized":true}
	WorldSimulation.start_world()

func _stepped_days(first:int,last:int)->int:
	var fewest:=1<<30
	for day in range(first,last+1):
		var committed:Array=[]
		WorldSimulation.begin_day(day,DAY.context(Vector2.ZERO),Callable(),func(result:Dictionary)->void:committed.append(result))
		var pumps:=0
		while WorldSimulation.day_in_progress():
			# A zero budget runs exactly one step per call.
			WorldSimulation.pump_day(0)
			pumps+=1
			assert_str(WorldSimulation.actor_id).is_equal("player")
			assert_bool(WorldSimulation._active.is_empty()).is_true()
		assert_int(committed.size()).is_equal(1)
		fewest=mini(fewest,pumps)
	return fewest

func test_stepped_days_commit_the_synchronous_outcome()->void:
	var VERIFY=preload("res://tools/verify_campaign_save.gd")
	_new_world()
	for day in range(1,3):WorldSimulation.advance_day(day,DAY.context(Vector2.ZERO))
	var slot:="day_job_probe_%d_%d" % [OS.get_process_id(),Time.get_ticks_usec()]
	assert_bool(SaveSystem.save_game(slot).get("ok",false)).is_true()
	# Synchronous, stepped, then synchronous again, each from the same save.
	var outcomes:Array[Dictionary]=[]
	var fewest:=0
	for stepped in [false,true,false]:
		var loaded:=SaveSystem.load_game(slot)
		assert_bool(loaded.has("error")).override_failure_message(str(loaded)).is_false()
		if stepped:fewest=_stepped_days(3,2+DAYS)
		else:
			for day in range(3,3+DAYS):WorldSimulation.advance_day(day,DAY.context(Vector2.ZERO))
		outcomes.append(VERIFY.capture())
	DirAccess.remove_absolute(SaveSystem.slot_path(slot))
	# If the two synchronous runs differ, the fixture (not scheduling) is unrepeatable.
	assert_bool(outcomes[0]==outcomes[2]).override_failure_message("synchronous control diverged: "+str(VERIFY.details(outcomes[0],outcomes[2]).slice(0,4))).is_true()
	assert_bool(outcomes[0]==outcomes[1]).override_failure_message("stepped days diverged: "+str(VERIFY.details(outcomes[0],outcomes[1]).slice(0,6))).is_true()
	# Three rivals plus the human owner: each owner's phases are separate steps.
	assert_int(fewest).is_greater(40)

func test_flush_completes_a_partial_day_once()->void:
	_new_world()
	var commits:=[0]
	WorldSimulation.begin_day(1,DAY.context(Vector2.ZERO),Callable(),func(_result:Dictionary)->void:commits[0]+=1)
	for i in 5:WorldSimulation.pump_day(0)
	assert_bool(WorldSimulation.day_in_progress()).is_true()
	assert_int(WorldSimulation.day_in_progress_number()).is_equal(1)
	WorldSimulation.flush_day()
	assert_bool(WorldSimulation.day_in_progress()).is_false()
	assert_int(commits[0]).is_equal(1)
	# A synchronous caller after a partial day still advances in calendar order.
	WorldSimulation.begin_day(2,DAY.context(Vector2.ZERO),Callable(),func(_result:Dictionary)->void:commits[0]+=1)
	WorldSimulation.pump_day(0)
	WorldSimulation.advance_day(3,DAY.context(Vector2.ZERO))
	assert_int(commits[0]).is_equal(2)
	assert_int(WorldSimulation.last_day).is_equal(3)

func test_validating_a_save_keeps_the_day_in_progress()->void:
	_new_world()
	WorldSimulation.advance_day(1,DAY.context(Vector2.ZERO))
	var payload:=WorldSimulation.export_state()
	WorldSimulation.begin_day(2,DAY.context(Vector2.ZERO))
	for i in 3:WorldSimulation.pump_day(0)
	var checked:=WorldSimulation.check_payload(bytes_to_var(var_to_bytes(payload)))
	assert_bool(checked.get("ok",false)).override_failure_message(str(checked)).is_true()
	assert_bool(WorldSimulation.day_in_progress()).is_true()
	WorldSimulation.flush_day()
	assert_int(WorldSimulation.last_day).is_equal(2)
	assert_bool(WorldSimulation.advancing).is_false()

func test_clearing_the_world_discards_its_day()->void:
	_new_world()
	WorldSimulation.begin_day(1,DAY.context(Vector2.ZERO))
	WorldSimulation.pump_day(0)
	WorldSimulation.clear()
	assert_bool(WorldSimulation.day_in_progress()).is_false()
	assert_bool(WorldSimulation.advancing).is_false()
