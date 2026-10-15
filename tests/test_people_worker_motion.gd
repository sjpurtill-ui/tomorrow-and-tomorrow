extends GdUnitTestSuite
const View=preload("res://scripts/hud/people_settlement_view.gd")
const Cast=preload("res://scripts/hud/people_workforce_cast.gd")
const World=preload("res://scripts/hud/people_work_world.gd")

func _view()->Control:
	var town:Control=auto_free(View.new());add_child(town);town.size=Vector2(900,600)
	town.configure({"plots":[],"routes":[],"population":2400,"origin":Vector3.ZERO,"allocations":{"Food":60,"Crafting":40}})
	return town

func test_one_point_transfer_keeps_batch_identity_and_heading_follows_displacement()->void:
	var town:=_view();var batch:MultiMesh=town._people.multimesh
	var before:Array[Dictionary]=town.workforce_people()
	town.set_workforce({"Food":59,"Crafting":41},true)
	var changed:=0
	for person:Dictionary in town.workforce_people():
		if person.role==before[int(person.id)].role:continue
		changed+=1
		assert_that(person.position).is_equal(before[int(person.id)].position)
		var direction:Vector2=town._cast.direction(person)
		town._process(.05)
		var after:Dictionary=town.workforce_people()[int(person.id)]
		assert_float(direction.dot(Vector2(after.position-person.position).normalized())).is_greater(.999)
	assert_int(changed).is_equal(1)
	assert_object(town._people.multimesh).is_same(batch)
	assert_int(batch.instance_count).is_equal(100)
	assert_int(town.workforce_percentages().Crafting).is_equal(41)

func test_all_roles_are_painted_work_and_both_sexes_keep_their_identity()->void:
	var town:=_view();var counts:Dictionary={}
	for role:String in Cast.ROLES:counts[role]=10
	town.set_workforce(counts,true);town._cast.advance(300);town._move_people()
	var women:=0;var men:=0;var seen:Dictionary={}
	for person:Dictionary in town.workforce_people():
		seen[int(person.id)]=true
		if int(person.sex)==0:women+=1
		else:men+=1
		assert_int(Cast.ROLES.find(person.role)).is_greater_equal(0)
		assert_bool(bool(person.moving)).is_false()
	assert_int(women).is_equal(50);assert_int(men).is_equal(50);assert_int(seen.size()).is_equal(100)

func test_refresh_does_not_discard_effective_draft_and_cancel_reverses_existing_people()->void:
	var town:=_view();var before:Array[Dictionary]=town.workforce_people()
	town.set_workforce({"Food":55,"Crafting":45},true);town._process(.1)
	var moving:Array[Dictionary]=town.workforce_people()
	town.update_state({"plots":[],"routes":[],"population":2400,"origin":Vector3.ZERO,"allocations":{"Food":60,"Crafting":40}})
	assert_int(town.workforce_percentages().Crafting).is_equal(45)
	town.set_workforce({"Food":60,"Crafting":40},false)
	for person:Dictionary in town.workforce_people():
		assert_that(person.position).is_equal(moving[int(person.id)].position)
		assert_int(person.id).is_equal(before[int(person.id)].id)
	town._cast.advance(300);town._move_people()
	assert_int(town.workforce_percentages().Food).is_equal(60)
	assert_int(town._people.multimesh.instance_count).is_equal(100)

func test_transfer_paths_use_authored_aisles_without_changing_scene_data()->void:
	var zones:Dictionary=World.zones();var before:=var_to_bytes(zones)
	for from_role:String in Cast.ROLES:
		for to_role:String in Cast.ROLES:
			if from_role==to_role:continue
			var path:PackedVector2Array=World.path_for_transfer(from_role,to_role)
			assert_that(path[0]).is_equal(zones[from_role].gate)
			assert_that(path[-1]).is_equal(zones[to_role].gate)
			for index in range(1,path.size()):
				for role:String in Cast.ROLES:
					var nearest:=Geometry2D.get_closest_point_to_segment(zones[role].scenery,path[index-1],path[index])
					assert_float(nearest.distance_to(zones[role].scenery)).is_greater(.0055)
	assert_that(var_to_bytes(zones)).is_equal(before)
