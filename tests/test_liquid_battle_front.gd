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
		assert_float(float(after.bodies[1].radius)).is_equal(float(before.bodies[1].radius)*(0.5 if count<180 else 0.25))
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
	for point:Vector2 in points:assert_bool((start.bounds as Rect2).has_point(point)).is_true()
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

func test_losses_thin_the_front_without_abandoning_either_flank()->void:
	var b:=battle();b.sides.b.troops=500
	var shape:=Liquid.geometry(b,Vector2.ZERO,Vector2.RIGHT,180,0,true)
	var a:Dictionary=shape.bodies[0];var other:Dictionary=shape.bodies[1]
	assert_float(float(other.radius)).is_equal(float(a.radius)*0.25)
	for endpoint in [0,Liquid.SAMPLES-1]:
		assert_float(a.points[endpoint].y).is_equal(other.points[endpoint].y)
	assert_float(absf(other.points[-1].y-other.points[0].y)).is_equal(180.0)
	# Even when a tactic bends the seam, both sides back every segment.
	b.shape_a=Tactics.shape("flank_attack",3,"closing")
	shape=Liquid.geometry(b,Vector2.ZERO,Vector2.RIGHT,180,0,true)
	for body:Dictionary in shape.bodies:
		for k in Liquid.SAMPLES:
			assert_float(body.points[k].distance_to(shape.seam[k])).is_equal_approx(float(body.radius)+1.1,0.001)

func test_head_fans_both_ways_while_tail_stays_behind_the_junction()->void:
	var trail:=PackedVector2Array([Vector2(-80,0),Vector2(-160,0),Vector2(-240,0)])
	var column_shape:=Liquid.column(trail[0],trail,Vector2.RIGHT,2000,70,0,true)
	var shape:=Liquid.geometry(battle(),Vector2.ZERO,Vector2.RIGHT,180,0,true)
	var halfway:=Liquid.deploy(shape,{"a":column_shape},0.5)
	var front:PackedVector2Array=halfway.bodies[0].points
	var junction:Vector2=front[Liquid.SAMPLES/2]
	assert_float(front[0].y).is_greater(junction.y+30)
	assert_float(front[-1].y).is_less(junction.y-30)
	assert_float(front[0].x).is_greater(junction.x+15)
	assert_float(front[-1].x).is_greater(junction.x+15)
	assert_float(front[0].x).is_equal_approx(front[-1].x,2.0)
	var stem:Dictionary=halfway.bodies[-1]
	assert_str(String(stem.side)).is_equal("a_feeding")
	assert_that(stem.points[0]).is_equal(junction)
	for point:Vector2 in stem.points:
		assert_float(absf(point.y)).is_less(0.001)
		assert_float(point.x).is_less_equal(junction.x+0.001)

func test_confirmed_breakthrough_opens_two_defending_fronts_for_either_side()->void:
	for attacker in ["a","b"]:
		var b:=battle()
		b["shape_"+attacker]=Tactics.shape("armoured_breakthrough",5,"closing")
		var before:=b.duplicate(true)
		var shape:=Liquid.geometry(b,Vector2.ZERO,Vector2.RIGHT,180,0,true)
		assert_int(shape.seams.size()).is_equal(2)
		assert_str(String(shape.piercing_side)).is_equal(attacker)
		var attacking:=0;var defending:=0
		for body:Dictionary in shape.bodies:
			if String(body.side)==attacker:attacking+=1
			else:defending+=1
			for point:Vector2 in body.points:
				assert_bool(point.is_finite()).is_true()
				assert_bool((shape.bounds as Rect2).has_point(point)).is_true()
		assert_int(attacking).is_equal(1)
		assert_int(defending).is_equal(2)
		assert_float(shape.seams[0][-1].distance_to(shape.seams[1][0])).is_greater(35.0)
		assert_dict(b).is_equal(before)

func test_attempted_or_failed_breakthrough_never_splits_the_front()->void:
	for phase in ["hold","break_in","failed"]:
		var b:=battle();b.shape_a=Tactics.shape("armoured_breakthrough",5,phase)
		var shape:=Liquid.geometry(b,Vector2.ZERO,Vector2.RIGHT,180,0,true)
		assert_int(shape.bodies.size()).is_equal(2)
		assert_int(shape.seams.size()).is_equal(1)
		assert_str(String(shape.piercing_side)).is_empty()
	var small:=battle(20);small.shape_a=Tactics.shape("armoured_breakthrough",5,"closing")
	assert_bool(Liquid.geometry(small,Vector2.ZERO,Vector2.RIGHT,180,0,true).blob).is_true()

func test_double_envelopment_curls_both_ends_without_cutting_the_middle()->void:
	var b:=battle();b.shape_a=Tactics.shape("double_envelopment",5,"closing")
	var shape:=Liquid.geometry(b,Vector2.ZERO,Vector2.RIGHT,180,0,true)
	assert_int(shape.seams.size()).is_equal(1)
	var seam:PackedVector2Array=shape.seam
	assert_float(seam[0].x).is_greater(seam[Liquid.SAMPLES/2].x+60.0)
	assert_float(seam[-1].x).is_greater(seam[Liquid.SAMPLES/2].x+60.0)
	assert_float(absf(seam[0].y-seam[-1].y)).is_less(70.0)
	b.flank_allowed=false
	shape=Liquid.geometry(b,Vector2.ZERO,Vector2.RIGHT,180,0,true)
	assert_float(absf(shape.seam[0].y-shape.seam[-1].y)).is_equal(180.0)

func test_new_tactic_identity_reaches_live_geometry_without_reusing_old_closure()->void:
	var chart:Control=auto_free(Overlay.new());var b:=battle()
	b.shape_a=Tactics.shape("double_envelopment",5,"closing")
	chart.set_scene({"battles":[b]},true)
	b.shape_a=Tactics.shape("armoured_breakthrough",2,"break_in")
	chart.set_scene({"battles":[b]})
	chart.ease_battles(0.1)
	assert_str(String(chart.live_battles.fight.shown.shape_a.shape)).is_equal("pocket")
	assert_float(float(chart.live_battles.fight.shown.shape_a.closure)).is_equal(0.0)

func test_deployment_reaches_both_ends_of_a_pierced_front()->void:
	var b:=battle();b.shape_a=Tactics.shape("armoured_breakthrough",5,"closing")
	var shape:=Liquid.geometry(b,Vector2.ZERO,Vector2.RIGHT,180,0,true)
	var column_shape:=Liquid.column(Vector2(-80,0),PackedVector2Array([Vector2(-80,0),Vector2(-160,0)]),Vector2.RIGHT,2000,70,0,true)
	var near_end:=Liquid.deploy(shape,{"a":column_shape},0.99)
	var points:PackedVector2Array=near_end.bodies[0].points
	var target:PackedVector2Array=shape.bodies[0].points
	assert_float(points[0].distance_to(target[0])).is_less(1.0)
	assert_float(points[-1].distance_to(target[-1])).is_less(1.0)
