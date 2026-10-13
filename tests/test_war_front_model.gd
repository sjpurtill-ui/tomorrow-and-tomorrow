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


## The border between our town at x=0 and theirs at x=10: a line at x=5.
static func _border()->PackedVector2Array:
	var line:=PackedVector2Array()
	for i in 21: line.append(Vector2(5.0,-10.0+float(i)))
	return line


func test_at_war_the_front_is_where_our_lands_meet()->void:
	var quiet:=Model.border_front(_border(),[Vector2(0,0)],[Vector2(10,0)],[],[],"kez")
	assert_bool(bool(quiet.border)).is_true()
	assert_bool(bool(quiet.quiet)).is_true()
	# With no force near it, the front is the border itself, teeth into their land.
	assert_float(_mean(quiet.points).x).is_equal_approx(5.0,0.01)
	assert_float((quiet.toward as PackedVector2Array)[10].x).is_greater(0.0)
	# A strong host of ours at the middle of the border bends it into their
	# ground there; the ends stay on the border.
	var ours:=[{"id":"1","army_id":1,"pos":Vector2(4.5,0),"strength":6000.0}]
	var theirs:=[{"id":"a","pos":Vector2(6,0),"strength":600.0,"age_days":0}]
	var worked:=Model.border_front(_border(),[Vector2(0,0)],[Vector2(10,0)],ours,theirs,"kez")
	assert_bool(bool(worked.quiet)).is_false()
	var pts:PackedVector2Array=worked.points
	assert_float(pts[pts.size()/2].x).is_greater(5.05)
	assert_float(pts[0].x).is_equal_approx(5.0,0.01)
	assert_float(pts[pts.size()-1].x).is_equal_approx(5.0,0.01)
	# The bend is bounded: a share of the theatre's scale, never a lunge.
	assert_float(pts[pts.size()/2].x).is_less(5.0+float(worked.sigma)*Model.BORDER_BEND+0.01)


func test_a_political_border_does_not_claim_a_deployed_defence()->void:
	# A shared border is quiet context. Town guards do not become troops
	# physically deployed along it merely because the chart needs a line.
	var built:=Overlay.compose({"mode":"raid","stage":"band","friendly":[],"enemy":[],"borders":[{"civ":"kez","points":_border(),"ours_at":[Vector2(0,0)],"theirs_at":[Vector2(10,0)]}]})
	assert_array(built.fronts).is_empty()
	assert_int((built.political as Array).size()).is_equal(1)
	# No shared border: no front in the raid age.
	assert_array(Overlay.compose({"mode":"raid","stage":"band","friendly":[],"enemy":[]}).fronts).is_empty()


func test_deployed_coverage_keeps_real_gaps_and_ignores_intended_assignment()->void:
	var left:={"id":"1","army_id":1,"pos":Vector2(-1,-3),"strength":3000.0,"border_front":{"id":"sector-a","points":[{"x":0.0,"z":-5.0},{"x":0.0,"z":-1.0}]}}
	var right:={"id":"2","army_id":2,"pos":Vector2(-1,3),"strength":1800.0,"defense_points":[{"x":0.0,"z":1.0},{"x":0.0,"z":5.0}]}
	var intended:={"id":"3","army_id":3,"pos":Vector2(-1,0),"strength":2000.0,"border_sector":{"points":[{"x":0.0,"z":-1.0},{"x":0.0,"z":1.0}]},"border_front":{"id":"sector-c","points":[]}}
	var built:=Overlay.compose({"mode":"front","home":Vector2(-10,0),"friendly":[left,right,intended],"enemy":[]})
	assert_int(built.fronts.size()).is_equal(2)
	for front:Dictionary in built.fronts:
		assert_bool(front.deployed).is_true()
		for point:Vector2 in front.points:assert_float(absf(point.y)).is_greater_equal(0.999)
	assert_array(Model.defense_points(intended)).is_empty()
	assert_str(String(built.fronts[0].id)).contains("sector-a")


func test_enemy_held_line_stays_at_the_observed_geometry_and_report_age()->void:
	var seen:={"id":"foe","pos":Vector2(8,0),"strength":900.0,"age_days":25,"defense_points":[{"x":7.0,"z":-2.0},{"x":7.0,"z":2.0}]}
	var before:=var_to_str(seen)
	var held:=Model.deployed_fronts([], [seen], Vector2.ZERO)
	assert_int(held.size()).is_equal(1)
	assert_bool(held[0].ours).is_false()
	assert_bool(held[0].stale).is_true()
	for point:Vector2 in held[0].points:assert_float(point.x).is_equal(7.0)
	assert_float(held[0].age[0]).is_equal(25.0)
	assert_str(var_to_str(seen)).is_equal(before)


func test_lost_coverage_opens_a_gap_without_morphing_a_neighbour_into_it()->void:
	var overlay:Control=auto_free(Overlay.new())
	var forces:=[{"id":"left","army_id":1,"pos":Vector2(0,-3),"strength":3000.0,"defense_points":[Vector2(0,-5),Vector2(0,-1)]},
		{"id":"right","army_id":2,"pos":Vector2(0,3),"strength":3000.0,"defense_points":[Vector2(0,1),Vector2(0,5)]}]
	overlay.set_scene(Overlay.compose({"mode":"front","friendly":forces}),true)
	forces[0].defense_points=[]
	overlay.set_scene(Overlay.compose({"mode":"front","friendly":forces}))
	assert_int(overlay.live_fronts.size()).is_equal(1)
	assert_str(overlay.live_fronts[0].data.id).contains("right")
	for point:Vector2 in overlay.live_fronts[0].points:assert_float(point.y).is_greater_equal(0.999)


func test_reported_coverage_is_bounded_and_does_not_heat_without_live_contact()->void:
	var sources:Array=[]
	for i in 120:sources.append({"id":str(i),"pos":Vector2(i,0),"strength":10000.0,"defense_points":[Vector2(i,-2),Vector2(i,2)]})
	var held:=Model.deployed_fronts(sources,sources)
	assert_int(held.size()).is_less_equal(Model.MAX_DEPLOYED_FRONTS)
	for front:Dictionary in held:
		assert_int(front.points.size()).is_less_equal(Model.DEPLOYED_POINTS)
		for value:float in Overlay._coverage_heat(front,[]):assert_float(value).is_equal(0.0)


func test_mobile_snapshot_does_not_become_a_guard_and_only_current_coverage_heats()->void:
	var mobile:={"id":"mobile","army_id":1,"pos":Vector2(-1,0),"strength":5000.0,"border_front":{"assigned":false,"points":[]}}
	assert_bool(Model.has_deployment(mobile)).is_false()
	var old:=mobile.duplicate(true)
	old.border_front={"assigned":true,"id":"old","points":[Vector2(0,-2),Vector2(0,2)]}
	old.report_age=2
	var now:=old.duplicate(true);now.report_age=0
	var battle:={"pos":Vector2.ZERO,"age_days":0,"kind":"battle","skirmish":false}
	var dated:=Overlay._coverage_heat(Model.deployed_fronts([old],[])[0],[battle])
	for value:float in dated:assert_float(value).is_equal(0.0)
	var heated:=Overlay._coverage_heat(Model.deployed_fronts([now],[])[0],[battle])
	assert_float(heated[heated.size()/2]).is_greater(0.9)
	battle.status="won"
	for value:float in Overlay._coverage_heat(Model.deployed_fronts([now],[])[0],[battle]):assert_float(value).is_equal(0.0)


func test_a_border_front_splits_into_sectors_with_who_holds_each()->void:
	# Two towns of ours along the border at x=0, y=-6 and y=+6; their towns
	# across it with fighters counted; a band of ours by the northern town.
	var ours:=[{"at":Vector2(0,-6),"name":"North","men":10},{"at":Vector2(0,6),"name":"South","men":4}]
	var theirs:=[{"at":Vector2(10,-6),"men":30,"known":true},{"at":Vector2(10,6),"men":0,"known":false}]
	var sectors:=Model.border_sectors(_border(),ours,theirs,[{"pos":Vector2(4,-5),"strength":12.0}],[])
	assert_int(sectors.size()).is_equal(2)
	var north:Dictionary=sectors[0]; var south:Dictionary=sectors[1]
	assert_str(String(north.town)).is_equal("North")
	assert_int(int(north.ours)).is_equal(22)
	assert_int(int(north.theirs)).is_equal(30)
	assert_int(int(south.ours)).is_equal(4)
	assert_bool(bool(south.known)).is_false()
	# Every soldier counted once: the guards and the band, nowhere else.
	assert_int(int(north.ours)+int(south.ours)).is_equal(26)
