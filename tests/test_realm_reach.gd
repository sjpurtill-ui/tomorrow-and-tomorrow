extends GdUnitTestSuite
## Every people holds country beyond its towns, growing with its people and
## its reach into the world (realm_reach.gd); where two countries overlap the
## stronger holds the ground, as the borders cut it.
const Realm:=preload("res://scripts/realm_reach.gd")
const Borders:=preload("res://scripts/nation_borders.gd")


func test_country_grows_with_the_people_and_its_reach()->void:
	# A village of 400 ranges about 60 km; a people of 25,000 some 470 km,
	# more with good roads and a wide knowledge of the world.
	assert_float(Realm.reach_km(400,0.0)).is_equal_approx(72.0,0.5)
	assert_float(Realm.reach_km(25000,0.0)).is_equal_approx(569.2,0.5)
	assert_float(Realm.reach_km(25000,0.3)).is_greater(Realm.reach_km(25000,0.0)*1.5)
	# Bounded: never under a town's fields, never past half a continent.
	assert_float(Realm.reach_km(0,0.0)).is_equal(Realm.MIN_KM)
	assert_float(Realm.reach_km(1e9,1.0)).is_equal(Realm.MAX_KM)


func test_two_peoples_a_continent_apart_meet_only_when_grown()->void:
	# Two peoples 1,100 km apart (civilization_start SEAT_SEPARATION_KM):
	# villages are far from meeting; peoples of 25,000 with some reach meet.
	var apart:=1100.0
	assert_float(Realm.reach_km(400,0.05)*2.0).is_less(apart)
	assert_float(Realm.reach_km(25000,0.2)*2.0).is_greater(apart)


func test_ground_goes_to_the_country_that_scores_higher_there()->void:
	var ours:={"owner":"player","center":Vector2.ZERO,"reach":500.0}
	var theirs:={"owner":"kez","center":Vector2(800,0),"reach":500.0}
	# Halfway they score alike; nearer them, theirs.
	assert_bool(Realm.held_by_other(Vector2(300,0),[theirs],ours)).is_false()
	assert_bool(Realm.held_by_other(Vector2(500,0),[theirs],ours)).is_true()
	# Beyond their reach, nobody's but ours.
	assert_bool(Realm.held_by_other(Vector2(-200,0),[theirs],ours)).is_false()
	# The partition cuts the same line: the claims' scores are equal halfway.
	var a:=Borders.make_claim("player","realm:player",Vector2.ZERO,500.0)
	var b:=Borders.make_claim("kez","realm:kez",Vector2(800,0),500.0)
	var Partition:=preload("res://scripts/nation_border_partition.gd")
	assert_float(Partition.claim_score(a,Vector2(400,0))).is_equal_approx(Partition.claim_score(b,Vector2(400,0)),0.01)
