extends GdUnitTestSuite
const Cast=preload("res://scripts/hud/people_workforce_cast.gd")

func _cast()->RefCounted:
	var slots:Dictionary={};var gates:Dictionary={}
	for r in Cast.ROLES.size():
		var role:String=Cast.ROLES[r];var points:=PackedVector2Array();var center:=Vector2(r*.03,.02)
		for i in 100:points.append(center+Vector2(i%10,i/10)*.0015)
		slots[role]=points;gates[role]=center-Vector2(0,.005)
	var cast:=Cast.new();cast.configure(slots,gates,Vector2(0,-.01));return cast

func test_percentages_sum_to_one_hundred_without_inventing_small_jobs()->void:
	for weights:Dictionary in [{"Food":9,"Crafting":1},{"Food":1,"Crafting":1,"Defense":1},{"Food":9999,"Defense":1},{"Food":NAN,"Defense":-1}]:
		var apportioned:=Cast.apportion(weights);var total:=0
		for count:int in apportioned.values():total+=count
		assert_int(total).is_equal(100)
	assert_int(Cast.apportion({"Food":9999,"Defense":1}).Defense).is_equal(0)
	assert_int(Cast.apportion({}).Unassigned).is_equal(100)

func test_one_percentage_point_moves_one_persistent_person_continuously()->void:
	var cast:=_cast();cast.set_weights({"Food":60,"Crafting":40})
	var before:Array=cast.population();cast.set_weights({"Food":59,"Crafting":41})
	var changed:=0;var men:=0
	for person:Dictionary in cast.people:
		men+=int(person.sex)
		assert_that(person.position).is_equal(before[int(person.id)].position)
		if person.role!=before[int(person.id)].role:changed+=1;assert_bool(person.moving).is_true()
	assert_int(cast.people.size()).is_equal(100);assert_int(men).is_equal(50);assert_int(changed).is_equal(1)
	cast.advance(.1)
	var traveling:=0
	for person:Dictionary in cast.people:
		if not person.moving:continue
		traveling+=1;assert_float(Vector2(person.position).distance_to(before[int(person.id)].position)).is_greater(0)
		assert_float(Vector2(person.position).distance_to(before[int(person.id)].position)).is_less_equal(.000401)
	assert_int(traveling).is_equal(1)

func test_mid_trip_cancel_preserves_identity_position_and_restores_distribution()->void:
	var cast:=_cast();cast.set_weights({"Food":60,"Crafting":40});cast.set_weights({"Food":40,"Crafting":60})
	cast.advance(1);var during:Array=cast.population();cast.set_weights({"Food":60,"Crafting":40})
	for person:Dictionary in cast.people:assert_that(person.position).is_equal(during[int(person.id)].position)
	cast.advance(300)
	var counts:Dictionary={}
	for person:Dictionary in cast.people:counts[person.role]=int(counts.get(person.role,0))+1;assert_bool(person.moving).is_false()
	assert_int(counts.Food).is_equal(60);assert_int(counts.Crafting).is_equal(40)

func test_every_person_can_change_job_without_respawn_or_shared_destination()->void:
	var cast:=_cast();cast.set_weights({"Food":100});cast.set_weights({"Defense":100})
	var targets:Dictionary={}
	for person:Dictionary in cast.people:targets[person.target]=true;assert_str(person.role).is_equal("Defense")
	assert_int(targets.size()).is_equal(100);cast.advance(300)
	for person:Dictionary in cast.people:assert_that(person.position).is_equal(person.target)
	var settled:Array=cast.population();cast.set_weights({"Defense":100})
	assert_that(var_to_bytes(cast.population())).is_equal(var_to_bytes(settled))
