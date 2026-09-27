extends GdUnitTestSuite
## Fronts are derived from real, dated positions: deterministic, bounded,
## bulging toward the weaker side, broken where the forces part, and never
## drawn against an enemy nobody has seen.
const Model:=preload("res://scripts/war_front_model.gd")
const Overlay:=preload("res://scripts/hud/war_front_overlay.gd")


static func _mean(points:PackedVector2Array)->Vector2:
	var total:=Vector2.ZERO
	for p in points: total+=p
	return total/float(maxi(1,points.size()))


func test_no_observed_enemy_means_no_front()->void:
	var ours:=[{"id":"1","pos":Vector2(0,0),"strength":3000.0}]
	assert_array(Model.derive(ours,[]).fronts).is_empty()
	assert_array(Model.derive([],[{"id":"e","pos":Vector2(4,0),"strength":3000.0,"age_days":0}]).fronts).is_empty()


func test_front_lies_between_and_is_deterministic()->void:
	var ours:=[{"id":"1","pos":Vector2(0,-2),"strength":4000.0},{"id":"2","pos":Vector2(0,2),"strength":4000.0}]
	var theirs:=[{"id":"a","pos":Vector2(6,-2),"strength":4000.0,"age_days":0},{"id":"b","pos":Vector2(6,2),"strength":4000.0,"age_days":0}]
	var first:=Model.derive(ours,theirs)
	var second:=Model.derive(ours,theirs)
	assert_int(first.fronts.size()).is_equal(1)
	assert_that(first.fronts[0].points).is_equal(second.fronts[0].points)
	var centre:=_mean(first.fronts[0].points)
	assert_float(centre.x).is_between(2.4,3.6)
	# The line runs across the axis between the armies.
	var pts:PackedVector2Array=first.fronts[0].points
	assert_float(absf(pts[0].y-pts[-1].y)).is_greater(absf(pts[0].x-pts[-1].x))
	# Teeth face the enemy.
	assert_float((first.fronts[0].toward as PackedVector2Array)[pts.size()/2].x).is_greater(0.0)


func test_stronger_side_pushes_the_line_toward_the_weaker()->void:
	var theirs:=[{"id":"a","pos":Vector2(6,0),"strength":2000.0,"age_days":0}]
	var even:=_mean(Model.derive([{"id":"1","pos":Vector2(0,0),"strength":2000.0}],theirs).fronts[0].points).x
	var strong:=_mean(Model.derive([{"id":"1","pos":Vector2(0,0),"strength":40000.0}],theirs).fronts[0].points).x
	assert_float(strong).is_greater(even+0.3)


func test_a_gap_breaks_the_front()->void:
	var ours:=[{"id":"1","pos":Vector2(0,-20),"strength":3000.0},{"id":"2","pos":Vector2(0,20),"strength":3000.0}]
	var theirs:=[{"id":"a","pos":Vector2(5,-20),"strength":3000.0,"age_days":0},{"id":"b","pos":Vector2(5,20),"strength":3000.0,"age_days":0}]
	var derived:=Model.derive(ours,theirs)
	assert_int(derived.fronts.size()).is_equal(2)
	assert_bool(bool(derived.broken)).is_true()


func test_old_reports_fade_and_are_marked_stale()->void:
	var ours:=[{"id":"1","pos":Vector2(0,0),"strength":3000.0}]
	var fresh:=Model.derive(ours,[{"id":"a","pos":Vector2(6,0),"strength":3000.0,"age_days":0}])
	var old:=Model.derive(ours,[{"id":"a","pos":Vector2(6,0),"strength":3000.0,"age_days":120}])
	assert_bool(bool(fresh.fronts[0].stale)).is_false()
	assert_bool(bool(old.fronts[0].stale)).is_true()
	# A stale sighting weighs less: the line sits nearer where they were seen.
	assert_float(_mean(old.fronts[0].points).x).is_greater(_mean(fresh.fronts[0].points).x)


func test_bounded_and_cheap_whatever_the_armies()->void:
	var rng:=RandomNumberGenerator.new(); rng.seed=7
	var ours:=[]; var theirs:=[]
	for i in 200: ours.append({"id":str(i),"pos":Vector2(rng.randf_range(-40,-2),rng.randf_range(-60,60)),"strength":rng.randf_range(100,2_000_000)})
	for i in 400: theirs.append({"id":"e%d" % i,"pos":Vector2(rng.randf_range(2,40),rng.randf_range(-60,60)),"strength":rng.randf_range(100,2_000_000),"age_days":rng.randi_range(0,90)})
	var start:=Time.get_ticks_usec()
	var derived:=Model.derive(ours,theirs)
	var elapsed_ms:=float(Time.get_ticks_usec()-start)/1000.0
	print("FRONT DERIVE %.1f ms for %d fronts" % [elapsed_ms,derived.fronts.size()])
	assert_int(derived.fronts.size()).is_less_equal(Model.MAX_FRONTS)
	for front in derived.fronts: assert_int((front.points as PackedVector2Array).size()).is_less_equal(Model.MAX_POINTS)
	assert_float(elapsed_ms).is_less(250.0)
	var built:=Overlay.compose({"mode":"theatre","friendly":ours,"enemy":theirs,"home":Vector2(-50,0)})
	assert_int((built.arrows as Array).size()).is_less_equal(Model.MAX_ARROWS)
	assert_int(Overlay.primitive_count(built)).is_less(80)


func test_presentation_follows_what_the_people_field()->void:
	assert_str(Model.mode("hearth",[],40,1,40)).is_equal("raid")
	assert_str(Model.mode("hearth",["formation_drill"],400,1,400)).is_equal("host")
	assert_str(Model.mode("lettered",["formation_drill"],3000,2,5000)).is_equal("front")
	assert_str(Model.mode("reckoned",["formation_drill","military_staffs"],30000,4,90000)).is_equal("theatre")
	# The raid age draws no front, only raid tracks and clashes.
	var early:=Overlay.compose({"mode":"raid","friendly":[{"id":"1","pos":Vector2.ZERO,"strength":30.0,"objective":Vector2(3,0),"offensive":true}],"enemy":[{"id":"a","pos":Vector2(3,0),"strength":30.0,"age_days":0}],
		"raids":[{"ours":true,"from":Vector2.ZERO,"to":Vector2(2,0),"fought":false}]})
	assert_array(early.fronts).is_empty()
	assert_array(early.faceoffs).is_empty()
	assert_array(early.arrows).is_empty()
	# The band's own path out (from its general's objective) and the feud's raid.
	assert_int((early.raids as Array).size()).is_equal(2)
	# Hosts in touch get a short face-off line, not a continuous front.
	var hosts:=Overlay.compose({"mode":"host","friendly":[{"id":"1","pos":Vector2.ZERO,"strength":600.0}],"enemy":[{"id":"a","pos":Vector2(1.5,0),"strength":500.0,"age_days":1}]})
	assert_array(hosts.fronts).is_empty()
	assert_int((hosts.faceoffs as Array).size()).is_equal(1)


func test_a_clash_carries_the_generals_tactic_shape()->void:
	var built:=Overlay.compose({"mode":"front","stage":"lettered","friendly":[{"id":"1","pos":Vector2.ZERO,"strength":5000.0}],"enemy":[{"id":"a","pos":Vector2(5,0),"strength":5000.0,"age_days":0}],
		"engagements":[{"pos":Vector2(2.5,0),"axis":Vector2.RIGHT,"ours":"double_envelopment","theirs":"dense_line","rounds":4,"phase_ours":"closing","phase_theirs":"hold"}]})
	var clash:Dictionary=built.clashes[0]
	assert_str(String(clash.label)).is_equal("A double envelopment")
	assert_float(float(clash.shape_ours.closure)).is_greater(0.0)
	assert_float(float(clash.shape_ours.wings)).is_greater(0.5)
