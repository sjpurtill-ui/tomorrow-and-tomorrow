extends GdUnitTestSuite
## Completion is synchronous inside the final pump. The pace estimate must
## include that pump and its presentation before deciding the next frame budget.
const Job=preload("res://scripts/day_job.gd")
const Meter=preload("res://scripts/perf_meter.gd")

class Terrain extends "res://scripts/local_terrain.gd":
	var commits:=0
	var cost_seen_during_commit:=0.0
	var fallback_heights:=0
	func _ready()->void:pass
	func _process(_delta:float)->void:pass
	func _commit_world_day(_result:Dictionary)->void:
		commits+=1
		cost_seen_during_commit=_day_cost_usec
	func _after_world_time(_days:float)->void:pass
	func _height_at(_x:float,_z:float)->float:
		fallback_heights+=1
		return -1.0

var terrain
var saved_day:=0.0
var saved_job
var saved_day_number:=-1
var saved_costs:Dictionary
var saved_meter:=0

func before_test()->void:
	terrain=auto_free(Terrain.new())
	saved_day=GameState.elapsed_days
	saved_job=WorldSimulation._day_job
	saved_day_number=WorldSimulation._day_number
	saved_costs=Job.step_costs.duplicate()
	saved_meter=Meter._sim_usec
	WorldSimulation._day_job=null
	Job.step_costs.clear()

func after_test()->void:
	WorldSimulation._day_job=saved_job
	WorldSimulation._day_number=saved_day_number
	GameState.elapsed_days=saved_day
	Job.step_costs.clear();Job.step_costs.merge(saved_costs)
	Meter._sim_usec=saved_meter

func _queue_day(step_count:int)->void:
	var job:=Job.new()
	var steps:Array=[]
	for i in step_count:
		steps.append(Job.step("accounting_probe_%d" % i,{},func()->void:pass))
	job.add_group("player",steps,{},func()->void:
		WorldSimulation._day_job=null
		terrain._finish_scheduled_day({},12))
	WorldSimulation._day_job=job
	WorldSimulation._day_number=12

func _timed_pump(minimum_usec:int)->void:
	# A synthetic slice start gives deterministic lower bounds without sleeps.
	var began:=Time.get_ticks_usec()-minimum_usec
	WorldSimulation.pump_day(0)
	terrain._record_world_day_slice(began)

func test_final_pump_is_included_before_the_day_cost_is_sampled()->void:
	_queue_day(2)
	terrain._day_spent_usec=80000
	terrain._day_cost_usec=90000.0
	_timed_pump(1000)
	assert_bool(WorldSimulation.day_in_progress()).is_true()
	assert_float(terrain._day_cost_usec).is_equal(90000.0)
	var before_final:int=terrain._day_spent_usec
	_timed_pump(20000)
	assert_bool(WorldSimulation.day_in_progress()).is_false()
	assert_int(terrain.commits).is_equal(1)
	assert_float(terrain.cost_seen_during_commit).is_equal(90000.0)
	assert_int(terrain._day_spent_usec-before_final).is_greater_equal(20000)
	assert_float(terrain._day_cost_usec).is_equal_approx(lerpf(90000.0,float(terrain._day_spent_usec),0.3),0.001)
	assert_int(terrain._frame_sim_usec).is_equal(terrain._day_spent_usec-80000)

func test_a_day_completed_in_its_first_pump_has_a_nonzero_full_cost()->void:
	_queue_day(1)
	_timed_pump(20000)
	assert_int(terrain.commits).is_equal(1)
	assert_float(terrain._day_cost_usec).is_greater_equal(20000.0)
	assert_float(terrain._day_cost_usec).is_equal(float(terrain._day_spent_usec))

func test_an_external_flush_does_not_publish_an_unmeasured_partial_cost()->void:
	_queue_day(2)
	terrain._day_cost_usec=90000.0
	_timed_pump(1000)
	assert_bool(WorldSimulation.day_in_progress()).is_true()
	WorldSimulation.flush_day()
	assert_int(terrain.commits).is_equal(1)
	assert_float(terrain._day_cost_usec).is_equal(90000.0)
	WorldSimulation.flush_day()
	assert_int(terrain.commits).is_equal(1)

func test_harvest_ground_uses_the_rendered_grid_before_expensive_noise()->void:
	terrain.river_terrain_grid=Vector4(0,0,2,2)
	terrain.rendered_regional_heights=PackedFloat32Array([2.0,2.0,2.0,2.0])
	assert_float(terrain._harvest_ground_height_at(Vector2.ZERO)).is_equal(2.0)
	assert_int(terrain.fallback_heights).is_equal(0)
	assert_float(terrain._harvest_ground_height_at(Vector2(5,5))).is_equal(-1.0)
	assert_int(terrain.fallback_heights).is_equal(1)
