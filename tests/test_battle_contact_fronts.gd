extends GdUnitTestSuite

const Contact:=preload("res://scripts/battle_contact_fronts.gd")
const Model:=preload("res://scripts/war_front_model.gd")
const Source:=preload("res://scripts/hud/battle_marker_source.gd")


func _ours(at:=Vector2(-0.3,0))->Dictionary:
	return {"id":"7","army_id":7,"name":"The first band","pos":at,"strength":400,"border_front":{"assigned":true,"points":[]}}

func _enemy()->Dictionary:
	return {"id":"guard","owner":"rival","name":"The border guard","pos":Vector2(0.2,0),"strength":500,"age_days":0,
		"defense_points":[{"x":0.2,"z":-5.0},{"x":0.2,"z":5.0}]}

func _battle()->Dictionary:
	return {"id":"battle:7","kind":"battle","status":"fighting","ours":true,"army_id":7,"pos":Vector2.ZERO,"age_days":0,"skirmish":false,
		"sides":{"a":{"troops":380,"name":"Our people"},"b":{"troops":470,"civ_id":"rival","name":"Our rival"}}}

func test_departed_assignment_gets_a_compact_fighting_front_beside_the_observed_defender()->void:
	var ours:=_ours();var enemy:=_enemy();var battle:=_battle()
	var held:=Model.deployed_fronts([ours],[enemy],Vector2(-10,0))
	assert_int(held.size()).is_equal(1)
	assert_bool(bool(held[0].ours)).is_false()
	var before:=[ours.duplicate(true),enemy.duplicate(true),battle.duplicate(true),held.duplicate(true)]
	var fronts:=Contact.build([battle],[ours],[enemy],held)
	assert_int(fronts.size()).is_equal(1)
	if fronts.is_empty():return
	var front:Dictionary=fronts[0]
	assert_bool(bool(front.ours)).is_true()
	assert_bool(bool(front.combat)).is_true();assert_bool(bool(front.held)).is_false()
	assert_int(int(front.troops)).is_equal(380)
	assert_array(front.armies).is_equal([7])
	assert_vector(front.points[Contact.POINTS/2]).is_equal(Vector2.ZERO)
	assert_float((front.points[0] as Vector2).distance_to(front.points[-1])).is_less_equal(Contact.MAX_LENGTH_KM)
	assert_float((front.toward[0] as Vector2).dot(held[0].toward[0])).is_less(-0.99)
	assert_array([ours,enemy,battle,held]).is_equal(before)

func test_current_own_battle_is_local_observation_of_two_mobile_sides()->void:
	var result:=Contact.build([_battle()],[_ours()],[],[])
	assert_int(result.size()).is_equal(2)
	if result.size()!=2:return
	assert_array(Array(result[0].points)).is_equal(Array(result[1].points))
	assert_float((result[0].toward[0] as Vector2).dot(result[1].toward[0])).is_less(-0.99)
	assert_str(String(result[0].battle_id)).is_equal("battle:7")
	assert_array(result[1].armies).is_empty()

func test_drawn_up_stale_finished_skirmish_and_foreign_battles_do_not_create_fighting_fronts()->void:
	for change:Dictionary in [{"status":"drawn up"},{"age_days":1},{"status":"won"},{"status":"withdrew"},{"skirmish":true},{"ours":false},{"kind":"siege"}]:
		var battle:=_battle();battle.merge(change,true)
		assert_array(Contact.build([battle],[_ours()],[_enemy()],[])).override_failure_message(str(change)).is_empty()
	assert_array(Contact.build([_battle()],[],[_enemy()],[])).is_empty()

func test_existing_current_coverage_or_inferred_contact_is_not_doubled()->void:
	var ours:=_ours()
	ours.border_front.points=[{"x":-0.2,"z":-5.0},{"x":-0.2,"z":5.0}]
	var lines:=Model.deployed_fronts([ours],[_enemy()],Vector2(-10,0))
	assert_array(Contact.build([_battle()],[ours],[_enemy()],lines)).is_empty()
	var inferred:={"points":PackedVector2Array([Vector2(0,-5),Vector2(0,5)]),"armies":[7]}
	assert_array(Contact.build([_battle()],[_ours()],[_enemy()],[inferred])).is_empty()
	var faceoffs:=Model.face_offs([_ours()],[_enemy()],2.5)
	assert_array(faceoffs).is_not_empty()
	assert_array(Contact.build([_battle()],[_ours()],[_enemy()],faceoffs)).is_empty()

func test_remote_or_old_sectors_are_not_extended_into_the_battle()->void:
	var enemy:=_enemy();enemy.defense_points=[{"x":20.0,"z":-5.0},{"x":20.0,"z":5.0}]
	var held:=Model.deployed_fronts([_ours()],[enemy])
	var fronts:=Contact.build([_battle()],[_ours()],[enemy],held)
	assert_int(fronts.size()).is_equal(2)
	for front:Dictionary in fronts:
		for point:Vector2 in front.points:assert_float(point.length()).is_less_equal(Contact.MAX_LENGTH_KM*0.5+0.001)
	var stale:=_enemy();stale.age_days=3;stale.pos=Vector2(0,4)
	var old_lines:=Model.deployed_fronts([_ours()],[stale])
	assert_array(Contact.build([_battle()],[_ours()],[stale],old_lines)).is_equal(Contact.build([_battle()],[_ours()],[],[]))

func test_front_count_geometry_and_identifiers_remain_bounded_and_stable()->void:
	var battles:Array=[]
	for i in 100:
		var battle:=_battle();battle.id="battle:%d" % i;battles.append(battle)
	var fronts:=Contact.build(battles,[_ours()],[],[])
	assert_int(fronts.size()).is_equal(Contact.MAX_BATTLES*2)
	for front:Dictionary in fronts:
		assert_int((front.points as PackedVector2Array).size()).is_equal(Contact.POINTS)
	assert_array(Contact.build([_battle(),_battle()],[_ours()],[],[])).is_equal(Contact.build([_battle()],[_ours()],[],[]))

func test_normal_battle_source_only_exposes_fighting_front_after_an_exchange()->void:
	var engagement:={"home_side":"attacker","home_force_id":7,"attacker":{"troops":400},"defender":{"troops":500},"round":0,
		"threat":{"source_civ_id":"rival","source_name":"Our rival","target_position":{"x":0.2,"z":0.0}}}
	var context:={"today":100,"armies":{7:Vector2(-0.3,0)},"home":Vector2(-10,0)}
	var before:=Source.from_engagement(engagement,"battle:7",context)
	assert_str(String(before.status)).is_equal("drawn up")
	assert_array(Contact.build([before],[_ours()],[_enemy()],[])).is_empty()
	engagement.round=1
	var after:=Source.from_engagement(engagement,"battle:7",context)
	assert_str(String(after.status)).is_equal("fighting")
	var fronts:=Contact.build([after],[_ours()],[_enemy()],[])
	assert_int(fronts.size()).is_equal(2)
	if not fronts.is_empty():assert_vector(fronts[0].points[Contact.POINTS/2]).is_equal(after.pos)
