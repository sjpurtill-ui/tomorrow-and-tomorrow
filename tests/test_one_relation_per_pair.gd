extends GdUnitTestSuite
## ONE RELATION FOR EACH PAIR OF PEOPLES (civilization_relations.gd). What we
## do to a people changes how their ruler decides, because the two sides'
## records of the pair agree; and a war between two other peoples is a war to
## everyone in the god's world who asks.
const Relations:=preload("res://scripts/civilization_relations.gd")

var a:=""
var b:=""

func before_test()->void:
	WorldSimulation.clear()
	WorldSimulation.context_provider=func(_origin:Vector2)->Dictionary:return {"environment_profile":PlanetEnvironment.profile_at(Vector2.ZERO),"surface_water_distance_km":.1,"surface_water_recognized":true}
	GameState.reset_for_new_world(9241)
	MilitaryCampaign.reset_for_new_world()
	ForeignDiplomacy.reset_for_new_world()
	CivilizationSystem.reset_for_new_world()
	CivilizationSystem.civilizations.assign(CivilizationSystem.civilizations.slice(0,2))
	CivilizationSystem.scout_land_authority=func(_at:Vector2)->bool:return true
	WorldSimulation.start_world()
	a=String(CivilizationSystem.civilizations[0].id)
	b=String(CivilizationSystem.civilizations[1].id)

func after_test()->void:
	WorldSimulation.clear()
	WorldSimulation.context_provider=Callable()
	CivilizationSystem.scout_land_authority=Callable()
	ForeignDiplomacy.reset_for_new_world()

## How `owner` regards `other`, in its own world's record.
func _held(owner:String,other:String)->Dictionary:
	return WorldSimulation.scoped(owner,func()->Dictionary:
		var want:="human" if other=="player" else other
		for civ in WorldSimulation.world.civilizations:
			if String(civ.id)==want:return civ.player_relation
		return {})

func test_what_we_do_reaches_the_ruler_who_decides()->void:
	var ours:=_held("player",a)
	var theirs:=_held(a,"player")
	assert_dict(theirs).is_not_empty()
	# We have insulted them for years; their own record never heard of it.
	ours["opinion"]=-0.6; ours["border_tension"]=0.7
	theirs["opinion"]=0.0; theirs["border_tension"]=0.1
	WorldSimulation.relation_baselines.erase(Relations.NUMBERS_KEY+a+":player")
	Relations.synchronize()
	# The first agreement: what the god's people have seen stands.
	assert_float(float(_held(a,"player").opinion)).is_equal_approx(-0.6,0.0001)
	assert_float(float(_held(a,"player").border_tension)).is_equal_approx(0.7,0.0001)
	assert_float(float(_held("player",a).opinion)).is_equal_approx(-0.6,0.0001)
	# After that each side's change counts: a gift in our hall, a slight at their fire.
	_held("player",a)["opinion"]=-0.5
	_held(a,"player")["opinion"]=-0.65
	Relations.synchronize()
	assert_float(float(_held("player",a).opinion)).is_equal_approx(-0.55,0.0001)
	assert_float(float(_held(a,"player").opinion)).is_equal_approx(-0.55,0.0001)
	# Agreed, nothing moves it.
	Relations.synchronize()
	assert_float(float(_held("player",a).opinion)).is_equal_approx(-0.55,0.0001)
	# Kept within its bounds.
	_held("player",a)["opinion"]=-0.95
	_held(a,"player")["opinion"]=-0.95
	Relations.synchronize()
	assert_float(float(_held(a,"player").opinion)).is_equal(-1.0)

func test_a_war_between_two_other_peoples_is_a_war_to_everyone_who_asks()->void:
	var pair:Dictionary=(CivilizationSystem.civilizations[0].relations as Dictionary).get(b,{})
	assert_bool(bool(pair.get("at_war",false))).is_false()
	# One declares war on the other, in its own world.
	var held:=_held(a,b)
	assert_dict(held).is_not_empty()
	held["at_war"]=true; held["treaty"]="war"; held["war_started_day"]=40; held["war_id"]="war_test"
	Relations.synchronize()
	# The other side knows it,
	assert_bool(bool(_held(b,a).get("at_war",false))).is_true()
	# and so does the god's world's record of the two, from either end.
	assert_bool(bool(((CivilizationSystem.civilizations[0].relations as Dictionary)[b] as Dictionary).at_war)).is_true()
	assert_bool(bool(((CivilizationSystem.civilizations[1].relations as Dictionary)[a] as Dictionary).at_war)).is_true()
	assert_str(String(((CivilizationSystem.civilizations[0].relations as Dictionary)[b] as Dictionary).treaty)).is_equal("war")
	assert_int(CivilizationSystem._war_count(CivilizationSystem.civilizations[0])).is_greater(0)
	# Peace is carried the same way.
	held=_held(b,a)
	held["at_war"]=false; held["treaty"]="truce"
	Relations.synchronize()
	assert_bool(bool(_held(a,b).get("at_war",true))).is_false()
	assert_bool(bool(((CivilizationSystem.civilizations[0].relations as Dictionary)[b] as Dictionary).at_war)).is_false()

## A world seen for the first time (a save from before the pair's facts were
## kept): the two records of a pair may disagree. They are settled once, a
## war either side knows of standing, never swapped between them.
func test_two_records_that_disagree_at_first_sight_are_settled_not_swapped()->void:
	WorldSimulation.relation_baselines.clear()
	var held:=_held(b,a)
	held["at_war"]=true; held["treaty"]="war"; held["war_started_day"]=12; held["war_id"]="old_war"
	Relations.synchronize()
	assert_bool(bool(_held(a,b).get("at_war",false))).is_true()
	assert_bool(bool(_held(b,a).get("at_war",false))).is_true()
	assert_bool(bool(((CivilizationSystem.civilizations[0].relations as Dictionary)[b] as Dictionary).at_war)).is_true()

## Another people's record of the god's people is made bare: it holds no
## opinion at all until something writes one. It takes ours.
func test_a_record_that_never_held_the_number_takes_the_other_sides()->void:
	WorldSimulation.relation_baselines.clear()
	var ours:=_held("player",a)
	var theirs:=_held(a,"player")
	ours["opinion"]=-1.0; ours["border_tension"]=0.8
	theirs.erase("opinion"); theirs.erase("border_tension")
	Relations.synchronize()
	assert_bool(_held(a,"player").has("opinion")).is_true()
	assert_float(float(_held(a,"player").opinion)).is_equal(-1.0)
	assert_float(float(_held(a,"player").border_tension)).is_equal_approx(0.8,0.0001)
	assert_float(float(_held("player",a).opinion)).is_equal(-1.0)
