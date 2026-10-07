extends GdUnitTestSuite
## EVERY PEOPLE ON THE SAME RULES (covert_ops.gd, eyes_corps.gd in each
## people's own scope): a rival keeps its own eyes and wary, its ruler
## chooses them by temperament, its eyes face the god's wary when moving in,
## one found among the god's people becomes the god's prisoner, and its
## network sharpens what it knows of us.

const Covert:=preload("res://scripts/covert_ops.gd")
const Corps:=preload("res://scripts/eyes_corps.gd")
const Standing:=preload("res://scripts/standing.gd")
const Captives:=preload("res://scripts/captured_agents.gd")

var rival:=""

func before_test()->void:
	OS.set_environment("OPENAI_API_KEY","")
	WorldSimulation.clear()
	GameState.reset_for_new_world(616161)
	SettlementModel.reset_for_new_world()
	GovernmentPeopleSystem.reset_for_new_world()
	ConsequenceEngine.reset_for_new_world()
	CivilizationSystem.reset_for_new_world(); CivilizationSystem.initialize()
	ForeignDiplomacy.reset_for_new_world()
	MilitaryCampaign.reset_for_new_world()
	GameState.civic_api_enabled=false
	GameState.initialize_population_model()
	GameState.settlement_site_committed=true; GameState.settlement_completed=["Hearth Circle"]
	SettlementModel.ensure_founded(); GovernmentPeopleSystem.initialize()
	GameState.elapsed_days=0
	WorldSimulation.context_provider=func(_o:Vector2)->Dictionary:return {"environment_profile":PlanetEnvironment.profile_at(Vector2.ZERO),"surface_water_distance_km":0.3,"surface_water_recognized":true}
	# A two-people world on the normal creation path (each a full simulation).
	CivilizationSystem.civilizations.assign(CivilizationSystem.civilizations.slice(0,2))
	CivilizationSystem.scout_land_authority=func(_at:Vector2)->bool:return true
	WorldSimulation.start_world()
	GameState.elapsed_days=75*365
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	rival=String(civ.id)
	WorldSimulation.scoped(rival,func()->void: WorldSimulation.state.elapsed_days=75*365)
	civ.player_relation.contact_level=2
	WorldSimulation.refresh_projections()
	WorldSimulation.refresh_views()
	Covert.forget()

func after_test()->void:
	WorldSimulation.clear()
	GameState.elapsed_days=0

## The god's people as the rival sees them.
func _us_in_their_view()->Dictionary:
	var found:Variant=WorldSimulation.scoped(rival,func()->Variant:
		for c in WorldSimulation.world.civilizations:
			if String((c as Dictionary).get("id",""))=="human": return c
		return {})
	return found as Dictionary

func test_a_rival_keeps_its_own_eyes_and_wary()->void:
	Corps.set_policy("eyes","many")
	WorldSimulation.scoped(rival,func()->void:
		assert_str(Corps.policy("eyes")).is_equal("none")
		Corps.set_policy("wary","steady"))
	assert_str(Corps.policy("wary")).is_equal("none")
	assert_str(Corps.policy("eyes")).is_equal("many")

func test_a_rivals_ruler_chooses_eyes_by_temperament()->void:
	var lean:float=WorldSimulation.scoped(rival,func()->float: return Covert.ruler_inclination(rival))
	assert_float(lean).is_between(0.0,1.0)
	WorldSimulation.scoped(rival,func()->void:
		Covert._ruler_review(int(WorldSimulation.state.elapsed_days))
		assert_bool(Corps.policy("eyes") in Corps.POLICIES).is_true())

func test_a_rivals_eye_found_among_us_is_our_prisoner_and_our_distrust()->void:
	assert_bool(_us_in_their_view().is_empty()).override_failure_message("the rival should see our people").is_false()
	var held_before:=Captives.held().size()
	var before:=Corps.distrust()
	WorldSimulation.scoped(rival,func()->void:
		var op:=Covert.launch("plant","human","","trader",Covert.volunteer_for("plant"))
		assert_bool(op.has("error")).override_failure_message(String(op.get("error",""))).is_false()
		(op.odds as Dictionary)["settle"]=1.0
		Covert._arrive(op,int(op.arrive_day))
		assert_str(String(op.stage)).is_equal("done"))
	assert_int(Captives.held().size()).is_greater(held_before)
	assert_float(Corps.distrust()).is_greater(before)

func test_our_wary_make_moving_in_among_us_harder_for_them()->void:
	var bare:float=WorldSimulation.scoped(rival,func()->float: return Covert.settle_risk("human","trader",0.6,0.15,0.0,0.0))
	var s:=Corps.state()
	(s.wary as Dictionary)["members"]=float(GameState.population_exact)/1000.0*Corps.FULL_WATCH_PER_K
	(s.wary as Dictionary)["craft"]=0.8
	var watched:float=WorldSimulation.scoped(rival,func()->float: return Covert.settle_risk("human","trader",0.6,0.15,0.0,0.0))
	assert_float(watched).is_greater(bare)

func test_a_rivals_long_network_among_us_sharpens_what_it_knows_of_us()->void:
	var them:=_us_in_their_view()
	(them.player_relation as Dictionary)["contact_level"]=2
	(them.player_relation as Dictionary)["contact_intelligence"]=0.2
	var fresh:float=WorldSimulation.scoped(rival,func()->float: return Standing.certainty("human"))
	WorldSimulation.scoped(rival,func()->void:
		var op:=Covert.launch("plant","human","","trader",Covert.volunteer_for("plant"))
		op["stage"]="in_place"
		op["settled_day"]=int(WorldSimulation.state.elapsed_days)-20*365)
	var old:float=WorldSimulation.scoped(rival,func()->float: return Standing.certainty("human"))
	assert_float(old).is_greater(fresh)
	assert_float(old).is_greater_equal(0.95)
