extends GdUnitTestSuite
## Where a scout party is reckoned to be along its route (scout_progress.gd),
## shared by the map's walker glyph and the watchers' reckoning. The user saw
## the walker go "out and around twice": a circuit (a loop that comes home the
## other way) was walked out and then walked again in reverse.

const Progress:=preload("res://scripts/scout_progress.gd")
const Walker:=preload("res://scripts/scout_chart_walker.gd")

func _loop()->Array:
	return [{"x":0.0,"z":0.0},{"x":10.0,"z":0.0},{"x":10.0,"z":10.0},{"x":0.0,"z":10.0},{"x":0.0,"z":0.0}]

func test_a_circuit_is_walked_once_round_never_back_again()->void:
	var mission:={"start_day":0,"return_day":20,"circuit":true,"route":_loop()}
	var last:=-1.0
	for day in range(0,21):
		var f:=Progress.fraction(mission,float(day))
		assert_float(f).override_failure_message("day %d went backwards (%.3f < %.3f)" % [day,f,last]).is_greater_equal(last)
		last=f
	assert_float(Progress.fraction(mission,5.0)).is_equal_approx(0.25,0.0001)
	assert_float(Progress.fraction(mission,10.0)).is_equal_approx(0.5,0.0001)
	assert_float(Progress.fraction(mission,20.0)).is_equal_approx(1.0,0.0001)

func test_an_out_and_back_route_waits_at_its_goal_then_comes_home()->void:
	var mission:={"start_day":0,"return_day":20,"travel_leg_days":6.0}
	assert_float(Progress.fraction(mission,3.0)).is_equal_approx(0.5,0.0001)
	assert_float(Progress.fraction(mission,6.0)).is_equal_approx(1.0,0.0001)
	assert_float(Progress.fraction(mission,10.0)).is_equal_approx(1.0,0.0001)
	assert_float(Progress.fraction(mission,17.0)).is_equal_approx(0.5,0.0001)
	assert_float(Progress.fraction(mission,20.0)).is_equal_approx(0.0,0.0001)

func test_a_party_turning_back_or_home_early_is_followed()->void:
	var turning:={"start_day":0,"return_day":10,"route_status":"turning_back","travel_leg_days":2.0}
	assert_float(Progress.fraction(turning,5.0)).is_equal_approx(1.0,0.0001)
	assert_float(Progress.fraction(turning,7.5)).is_equal_approx(0.5,0.0001)
	var early:={"start_day":0,"return_day":30,"actual_return_day":10}
	assert_float(Progress.fraction(early,10.0)).is_equal_approx(0.0,0.0001)

func test_the_walker_follows_the_same_rule_and_the_live_mission()->void:
	var mission:={"start_day":0,"return_day":20,"circuit":true,"route":_loop()}
	var walker:Sprite3D=Walker.new()
	walker.set("mission",mission)
	for day in [0.0,4.0,10.0,15.0,20.0]:
		assert_float(float(walker.call("reach_at",day))).is_equal_approx(Progress.fraction(mission,day),0.0001)
	# The walker holds the live mission, so a change is followed at once.
	mission["circuit"]=false
	mission["route_status"]="turning_back"
	assert_float(float(walker.call("reach_at",15.0))).is_equal_approx(Progress.fraction(mission,15.0),0.0001)
	walker.free()

func test_the_watchers_reckon_the_same_place_as_the_walker()->void:
	var intel=CivilizationSystem.city_intelligence
	var mission:={"start_day":0,"return_day":20,"circuit":true,"route":_loop()}
	for day in [0.0,5.0,12.0,20.0]:
		var at:Vector2=intel.mission_position(mission,day)
		var expected:Vector2=intel.route_position(mission.route,Progress.fraction(mission,day))
		assert_vector(at).is_equal_approx(expected,Vector2(0.0001,0.0001))
	# Half-way round a circuit the party is on the far side of the loop, not home.
	assert_vector(intel.mission_position(mission,10.0)).is_not_equal(Vector2.ZERO)
