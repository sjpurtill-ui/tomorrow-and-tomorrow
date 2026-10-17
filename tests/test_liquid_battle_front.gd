extends GdUnitTestSuite
const Liquid:=preload("res://scripts/hud/liquid_battle_front.gd")
const Overlay:=preload("res://scripts/hud/war_front_overlay.gd")
const Source:=preload("res://scripts/hud/battle_marker_source.gd")
const Tactics:=preload("res://scripts/battle_tactics.gd")

func battle(men:int=2000)->Dictionary:
	return {"id":"fight","pos":Vector2.ZERO,"axis":Vector2.RIGHT,"kind":"battle","status":"fighting","progress":0.0,"age_days":0,"ours":true,"army_id":1,
		"sides":{"a":{"troops":men,"initial":men},"b":{"troops":men,"initial":men}},"seed":7}

func test_small_forces_and_distant_fronts_become_blobs()->void:
	assert_bool(Liquid.geometry(battle(20),Vector2.ZERO,Vector2.RIGHT,300.0,0).blob).is_true()
	assert_bool(Liquid.geometry(battle(),Vector2.ZERO,Vector2.RIGHT,30.0,0).blob).is_true()
	assert_bool(Liquid.geometry(battle(),Vector2.ZERO,Vector2.RIGHT,150.0,0).blob).is_false()

func test_losses_shrink_only_the_affected_side_and_progress_pushes_it_back()->void:
	for count in [20,2000]:
		var b:=battle(count)
		var before:=Liquid.geometry(b,Vector2.ZERO,Vector2.RIGHT,180.0,0,true)
		b.sides.b.troops=count/4;b.progress=0.75
		var after:=Liquid.geometry(b,Vector2.ZERO,Vector2.RIGHT,180.0,0,true)
		assert_float(float(after.bodies[0].radius)).is_equal(float(before.bodies[0].radius))
		assert_float(float(after.bodies[1].radius)).is_equal(float(before.bodies[1].radius)*0.5)
		var mid:=int((after.bodies[1].points as PackedVector2Array).size()/2)
		assert_float(after.bodies[1].points[mid].x).is_greater(before.bodies[1].points[mid].x)
		b.sides.b.troops=0
		assert_int(Liquid.geometry(b,Vector2.ZERO,Vector2.RIGHT,180.0,0,true).bodies.size()).is_equal(1)

func test_flanks_are_body_geometry_and_chokepoints_prevent_wings()->void:
	var b:=battle();b.shape_a=Tactics.shape("double_envelopment",5,"closing")
	var shape:=Liquid.geometry(b,Vector2.ZERO,Vector2.RIGHT,180.0,0,true)
	var points:PackedVector2Array=shape.bodies[0].points
	assert_float(points[0].x).is_greater(points[16].x+30.0)
	assert_float(points[-1].x).is_greater(points[16].x+30.0)
	b.flank_allowed=false
	var narrow:PackedVector2Array=Liquid.geometry(b,Vector2.ZERO,Vector2.RIGHT,180.0,0,true).bodies[0].points
	assert_float(narrow[0].x-narrow[16].x).is_less(10.0)

func test_obsolete_reports_and_reduced_motion_never_keep_fighting()->void:
	var b:=battle();b.age_days=2
	assert_dict(Liquid.geometry(b,Vector2.ZERO,Vector2.RIGHT,180.0,0)).is_equal(Liquid.geometry(b,Vector2.ZERO,Vector2.RIGHT,180.0,9))
	b.age_days=0
	assert_dict(Liquid.geometry(b,Vector2.ZERO,Vector2.RIGHT,180.0,0,true)).is_equal(Liquid.geometry(b,Vector2.ZERO,Vector2.RIGHT,180.0,9,true))
	assert_that(Liquid.geometry(b,Vector2.ZERO,Vector2.RIGHT,180.0,0).bodies[0].points).is_not_equal(Liquid.geometry(b,Vector2.ZERO,Vector2.RIGHT,180.0,1).bodies[0].points)

func test_final_report_drives_last_shrink_then_visual_disappears()->void:
	var chart:Control=auto_free(Overlay.new());var b:=battle()
	chart.set_scene({"battles":[b]},true)
	chart.set_scene({"battles":[],"clashes":[{"pos":Vector2.ZERO,"axis":Vector2.RIGHT,"army_id":1,"finished":true,"seed":7,"won":true,"our_troops":1800,"their_troops":100}]})
	for i in 30:chart.ease_battles(1.0/30.0)
	var shown:Dictionary=chart.live_battles.fight.shown
	assert_float(float(shown.sides.a.troops)).is_greater(1800.0)
	assert_float(float(shown.sides.b.troops)).is_less(300.0)
	assert_float(float(shown.progress)).is_greater(0.9)
	chart.ease_battles(2.0)
	assert_dict(chart.live_battles).is_empty()

func test_tactic_snapshot_uses_correct_side_and_its_current_phase()->void:
	var e:={"round":7,"tactics":{"defender":{"id":"feigned_retreat","since":5}},"rounds":[{"defender_tactic_phase":"turn"}]}
	assert_float(float(Source.tactical_shape(e,"defender").bulge)).is_greater(0.0)
	e.rounds[0].defender_tactic_phase="yield"
	assert_float(float(Source.tactical_shape(e,"defender").bulge)).is_less(0.0)

func test_work_is_bounded_and_input_is_unchanged()->void:
	var b:=battle(200000);var copy:=b.duplicate(true)
	var shape:=Liquid.geometry(b,Vector2.ZERO,Vector2.RIGHT,100000.0,5.0)
	assert_int(shape.bodies.size()).is_equal(2)
	assert_int(shape.bodies[0].points.size()).is_equal(Liquid.SAMPLES)
	assert_float(shape.bounds.size.length()).is_less(400.0)
	assert_dict(b).is_equal(copy)

func test_column_follows_route_bends_and_spreads_into_front()->void:
	var trail:=PackedVector2Array([Vector2(80,0),Vector2(40,0),Vector2(40,60),Vector2.ZERO])
	var column_shape:=Liquid.column(trail[0],trail,Vector2.RIGHT,3000,70,0,true)
	var points:PackedVector2Array=column_shape.bodies[0].points
	assert_that(points[0]).is_equal(trail[0])
	for point:Vector2 in points:
		var distance:=INF
		for k in range(1,trail.size()):distance=minf(distance,point.distance_to(Geometry2D.get_closest_point_to_segment(point,trail[k-1],trail[k])))
		assert_float(distance).is_less(0.001)
	var shape:=Liquid.geometry(battle(),Vector2(80,0),Vector2.RIGHT,180,0,true)
	var start:=Liquid.deploy(shape,{"a":column_shape},0)
	var end:=Liquid.deploy(shape,{"a":column_shape},1)
	assert_that(start.bodies[0].points).is_equal(points)
	assert_that(end.bodies[0].points).is_equal(shape.bodies[0].points)
	assert_float((end.bodies[0].points[-1]-end.bodies[0].points[0]).abs().y).is_greater(150.0)

func test_marching_interpolation_stays_on_the_road_instead_of_cutting_corner()->void:
	var trail:=PackedVector2Array([Vector2(20,10),Vector2(10,10),Vector2(10,0),Vector2.ZERO])
	assert_that(Liquid.trail_at_progress(trail,Vector2.ZERO,0)[0]).is_equal(Vector2.ZERO)
	assert_that(Liquid.trail_at_progress(trail,Vector2.ZERO,0.5)[0]).is_equal(Vector2(10,5))
	assert_that(Liquid.trail_at_progress(trail,Vector2.ZERO,1)[0]).is_equal(Vector2(20,10))
	var route:={"origin_position":{"x":0,"z":0},"march_route":[{"x":10,"z":0},{"x":10,"z":10},{"x":20,"z":10}]}
	assert_that(Overlay._road_behind(route,Vector2(10,5))).is_equal(PackedVector2Array([Vector2(10,5),Vector2(10,0),Vector2.ZERO]))

func test_new_contact_unfolds_the_previous_marching_force_without_mutating_it()->void:
	var chart:Control=auto_free(Overlay.new())
	var mark:={"id":"ours:1","side":"ours","army_id":1,"pos":Vector2(-1,0),"moving":true,"troops":2000,"trail":PackedVector2Array([Vector2(-1,0),Vector2(-2,0)])}
	chart.set_scene({"marks":[mark]},true)
	chart.set_scene({"battles":[battle()],"marks":[]})
	assert_float(float(chart.live_battles.fight.deployment)).is_equal(0.0)
	assert_that(chart.live_battles.fight.columns.a.trail).is_equal(mark.trail)
	chart.ease_battles(0.6)
	assert_float(float(chart.live_battles.fight.deployment)).is_between(0.4,0.6)
	chart.ease_battles(1.0)
	assert_float(float(chart.live_battles.fight.deployment)).is_equal(1.0)
	assert_float(float(mark.pos.x)).is_equal(-1.0)
