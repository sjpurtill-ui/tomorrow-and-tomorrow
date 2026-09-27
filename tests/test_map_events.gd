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
