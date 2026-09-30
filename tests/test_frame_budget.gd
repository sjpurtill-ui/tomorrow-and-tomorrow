extends GdUnitTestSuite
## How much of a frame the day in progress may take (local_terrain.gd
## _day_step_budget_usec): the same small shares as ever while the day keeps
## up with the calendar, and, at the fast speeds when the calendar has run
## ahead of the day being computed, what the frame has to spare, up to a frame
## of DAY_FRAME_TARGET_USEC. The world computed is the same either way; only
## how many of its steps share a frame changes.

class Terrain extends "res://scripts/local_terrain.gd":
	func _ready()->void:pass
	func _process(_delta:float)->void:pass

var terrain

func before_test()->void:
	terrain=auto_free(Terrain.new())
	terrain.camera_input_msec=-100000
	terrain.calendar_bank_days=0.0
	terrain.scheduled_world_elapsed=0.0

func test_the_day_keeps_its_share_while_it_keeps_up()->void:
	terrain.game_speed=3.0
	assert_int(terrain._day_step_budget_usec()).is_equal(terrain.DAY_STEP_BUDGET_USEC)
	terrain.game_speed=5.0
	assert_int(terrain._day_step_budget_usec()).is_equal(terrain.DAY_STEP_BUDGET_FAST_USEC)
	# Moving the map always keeps the frame light.
	terrain.calendar_bank_days=0.5
	terrain.camera_input_msec=Time.get_ticks_msec()
	assert_int(terrain._day_step_budget_usec()).is_equal(terrain.DAY_STEP_BUDGET_NAVIGATING_USEC)

func test_behind_the_calendar_the_day_takes_what_the_frame_spares()->void:
	terrain.game_speed=5.0
	terrain.calendar_bank_days=0.5
	terrain._frame_sim_usec=0
	terrain._frame_other_usec=12000.0
	assert_int(terrain._day_step_budget_usec()).is_equal(terrain.DAY_FRAME_TARGET_USEC-12000)
	# A light frame: no more than the most the day may take.
	terrain._frame_other_usec=2000.0
	assert_int(terrain._day_step_budget_usec()).is_equal(terrain.DAY_STEP_BUDGET_MAX_USEC)
	# A heavy frame, or one that already ran the day: never less than before.
	terrain._frame_other_usec=30000.0
	assert_int(terrain._day_step_budget_usec()).is_equal(terrain.DAY_STEP_BUDGET_FAST_USEC)
	terrain._frame_other_usec=12000.0;terrain._frame_sim_usec=15000
	assert_int(terrain._day_step_budget_usec()).is_equal(terrain.DAY_STEP_BUDGET_FAST_USEC)
	# Comparisons can turn it off.
	terrain._frame_sim_usec=0;terrain.catch_up_budget=false
	assert_int(terrain._day_step_budget_usec()).is_equal(terrain.DAY_STEP_BUDGET_FAST_USEC)
	# At the slower speeds nothing changes.
	terrain.catch_up_budget=true;terrain.game_speed=3.0
	assert_int(terrain._day_step_budget_usec()).is_equal(terrain.DAY_STEP_BUDGET_USEC)

## Keeping up at 3 days a second: the rest of a day's work is shared over the
## frames before its span is 60 in 100 through, never below a small floor nor
## above the usual share.
func test_a_day_is_spread_over_its_calendar_span()->void:
	var T=terrain.get_script()
	# A 100 ms day at 3 days a second and 60 frames a second, just begun:
	# 0.6 of the span is 0.2 s, 12 frames, for 125 ms of planned work.
	assert_int(T.paced_budget_usec(100000.0,0,1.0,3.0,1.0/60.0,0)).is_equal(roundi(125000.0/12.0))
	# Half the work done, a third of the span gone: the rest over what remains.
	var halfway:int=T.paced_budget_usec(100000.0,62500,2.0/3.0,3.0,1.0/60.0,0)
	assert_int(halfway).is_equal(roundi(62500.0/maxf(1.0,(2.0/3.0-0.4)/3.0*60.0)))
	# Work already done: only the floor. Late in the span: never more than usual.
	assert_int(T.paced_budget_usec(100000.0,200000,0.5,3.0,1.0/60.0,0)).is_equal(terrain.DAY_STEP_BUDGET_PACED_MIN_USEC)
	assert_int(T.paced_budget_usec(400000.0,0,0.41,3.0,1.0/60.0,0)).is_equal(terrain.DAY_STEP_BUDGET_FAST_USEC)
	# Simulation already run in this frame comes off its share.
	assert_int(T.paced_budget_usec(100000.0,0,1.0,3.0,1.0/60.0,4000)).is_equal(roundi(125000.0/12.0)-4000)
