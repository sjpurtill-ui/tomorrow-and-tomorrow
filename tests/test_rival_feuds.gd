extends GdUnitTestSuite
## Feuds between two other simulated peoples are fought for real
## (rival_feuds.gd): the same bands and combat simulator as raids on the god's
## people, with the dead and the stolen food out of both peoples' own ledgers.

const Feuds:=preload("res://scripts/rival_feuds.gd")
const CIV:=preload("res://scripts/civilization_system.gd")

var first_id:=""
var second_id:=""

func before_test()->void:
	WorldSimulation.clear()
	GameState.reset_for_new_world(5151)
	CivilizationSystem.reset_for_new_world(); CivilizationSystem.initialize()
	WorldSimulation.context_provider=func(_origin:Vector2)->Dictionary:return {"environment_profile":PlanetEnvironment.profile_at(Vector2.ZERO),"surface_water_distance_km":.1,"surface_water_recognized":true}
	first_id=String(CivilizationSystem.civilizations[0].id)
	second_id=String(CivilizationSystem.civilizations[1].id)
	for id in [first_id,second_id]:
		WorldSimulation.create_actor(id,hash(id)&0x7fffffff,Vector2.ZERO)
		WorldSimulation.actors[id].controller="manual"
		WorldSimulation.actors[id].systems.CivilizationSystem.scout_land_authority=func(_point:Vector2)->bool:return true
		assert_bool(WorldSimulation.submit(id,{"kind":"found"}).get("ok",false)).is_true()
	# Both sides as the god's world sees them: sizes, readiness, what they know.
	for index in 2:
		var civ:Dictionary=CivilizationSystem.civilizations[index]
		civ.population=120.0
		civ.military_readiness=0.5
		civ.knowledge=0.2
		civ.alive=true
	WorldSimulation.enabled=true
	# Each people's own view of the others (their relations live there).
	WorldSimulation.refresh_views()

func after_test()->void:
	WorldSimulation.enabled=false
	WorldSimulation.clear()
	WorldSimulation.context_provider=Callable()

func _population(id:String)->int:
	return int(WorldSimulation.actors[id].systems.GameState.population_total)

func _relation()->Dictionary:
	return (CivilizationSystem.civilizations[0].relations as Dictionary).get(second_id,{})

func test_a_raid_between_simulated_peoples_costs_both_real_ledgers()->void:
	# Peoples of 400, so the raid is fought by bands of a dozen or more: a
	# raid of five against three now ends when one band breaks at a quarter
	# of its will (army_lines.gd), often with nobody killed.
	for index in 2: CivilizationSystem.civilizations[index].population=400.0
	var before_a:=_population(first_id)
	var before_d:=_population(second_id)
	var regard_before:=_their_opinion_of_raiders()
	# Enough loot to carry off, and a raid that is sure to be fought.
	WorldSimulation.scoped(second_id,func()->void: WorldSimulation.state.food_stocks["Stored food"]=2000.0)
	var result:=Feuds.raid(CivilizationSystem.civilizations[0],CivilizationSystem.civilizations[1],400)
	var lost:=before_d-_population(second_id)
	var lost_attackers:=before_a-_population(first_id)
	assert_int(lost).is_equal(int(result.defender_dead))
	assert_int(lost_attackers).is_equal(int(result.attacker_dead))
	assert_int(lost+lost_attackers).is_greater(0)
	# The raided remember it in their own view of the world.
	assert_float(_their_opinion_of_raiders()).is_less(regard_before)

func _their_opinion_of_raiders()->float:
	return float(WorldSimulation.scoped(second_id,func()->float:
		for civ in WorldSimulation.world.civilizations:
			if String(civ.id)==first_id: return float(civ.player_relation.get("opinion",0.0))
		return 99.0))

func test_a_hot_feud_raids_and_counts_its_dead_then_goes_cold()->void:
	CivilizationSystem.start_rival_feud(0,1,300,"old quarrels")
	var start:=_population(first_id)+_population(second_id)
	var day:=300
	while day<300+2*365 and int(_relation().get("feud_raids",0))==0:
		day+=5
		Feuds.tick(day,5)
	assert_int(int(_relation().get("feud_raids",0))).is_greater(0)
	var dead:Dictionary=_relation().get("feud_dead",{})
	var counted:=int(dead.get(first_id,0))+int(dead.get(second_id,0))
	assert_int(start-(_population(first_id)+_population(second_id))).is_equal(counted)
	# Long quiet: the feud goes cold and its bookkeeping is cleared.
	Feuds.tick(int(_relation().get("feud_last",day))+CIV.RIVAL_FEUD_COLD_DAYS+5,5)
	assert_int(int(_relation().get("feud_since",-1))).is_equal(-1)

func test_grudges_fade_between_feuds()->void:
	var relation:Dictionary=_relation().duplicate(true)
	relation.opinion=-0.5
	relation.border_tension=0.9
	CivilizationSystem._set_pair_relation(0,1,relation)
	for month in 12: Feuds.tick(30*(month+1),30)
	assert_float(float(_relation().opinion)).is_greater(-0.5)
	assert_float(float(_relation().border_tension)).is_less(0.9)

func test_simulated_peoples_are_not_left_with_an_undelivered_war_note()->void:
	var relation:Dictionary=_relation().duplicate(true)
	relation.pending_message="war"
	CivilizationSystem._set_pair_relation(0,1,relation)
	Feuds.tick(30,5)
	assert_str(String(_relation().get("pending_message",""))).is_equal("")
