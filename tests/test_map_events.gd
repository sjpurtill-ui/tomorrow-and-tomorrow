extends GdUnitTestSuite
## Map events animated with restraint (codex/map-motion): a battle that joins
## rings once and briefly; long-running battles do not ring again.
const Overlay:=preload("res://scripts/hud/war_front_overlay.gd")
const Motion:=preload("res://scripts/hud/motion.gd")

func after_test()->void:
	Motion.reduce_motion=false

func test_only_new_clashes_ring_and_pulses_are_bounded()->void:
	var overlay:Control=auto_free(Overlay.new())
	var before:={"clashes":[{"pos":Vector2(10,10)}]}
	var after:={"clashes":[{"pos":Vector2(10.4,10.2)},{"pos":Vector2(80,40)}]}
	overlay._note_new_clashes(before,after)
	assert_int(overlay.clash_pulses.size()).is_equal(1)  # the drifting old battle does not ring
	var many:Array=[]
	for i in 20:many.append({"pos":Vector2(200+i*10,0)})
	overlay._note_new_clashes({"clashes":[]},{"clashes":many})
	assert_int(overlay.clash_pulses.size()).is_equal(Overlay.MAX_CLASH_PULSES)

func test_reduced_motion_never_rings()->void:
	Motion.reduce_motion=true
	var overlay:Control=auto_free(Overlay.new())
	overlay._note_new_clashes({"clashes":[]},{"clashes":[{"pos":Vector2(1,1)}]})
	assert_int(overlay.clash_pulses.size()).is_equal(0)

func test_only_newly_founded_settlements_are_news()->void:
	var Labels:=preload("res://scripts/hud/city_labels.gd")
	var known:={}
	assert_array(Labels.new_foundings(known,[{"id":"a"},{"id":"b"}])).is_equal(["a","b"])
	assert_array(Labels.new_foundings(known,[{"id":"a"},{"id":"b"}])).is_empty()
	assert_array(Labels.new_foundings(known,[{"id":"a"},{"id":"b"},{"id":"c"}])).is_equal(["c"])

func test_founding_rings_wait_for_the_first_look_and_expire()->void:
	var labels:Control=auto_free(preload("res://scripts/hud/city_labels.gd").new())
	GameState.player_settlements=[{"id":"old"}]
	labels._watch_foundings(1.0)
	assert_int(labels.founding_rings.size()).is_equal(0)  # already standing at load
	GameState.player_settlements=[{"id":"old"},{"id":"new"}]
	labels._watch_foundings(1.0)
	assert_int(labels.founding_rings.size()).is_equal(1)
	for i in 40:labels._watch_foundings(0.1)
	assert_int(labels.founding_rings.size()).is_equal(0)
	GameState.player_settlements=[]
