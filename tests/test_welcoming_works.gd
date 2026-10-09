extends GdUnitTestSuite
## A work that welcomes strangers (undertaking_effects traffic) does what its
## words promise, for every people: traders (market access), envoys (computer
## rulers' missions lean toward it; the court's envoys with real business come
## sooner) and households who judge life there better (they come on their own,
## leaving their own people's count). Only those who have heard of the holder's
## works are drawn; every effect is bounded and its size is on the screen.

const Rivalry:=preload("res://scripts/great_works_rivalry.gd")
const Effects:=preload("res://scripts/undertaking_effects.gd")
const Exchange:=preload("res://scripts/society_exchange.gd")
const Controller:=preload("res://scripts/civilization_controller.gd")
const Hall:=preload("res://scripts/audience_hall.gd")
const Catalog:=preload("res://scripts/undertaking_catalog.gd")

func before_test()->void:
	WorldSimulation.clear()
	# Views are copied from a full civilization record; another suite may leave a bare one.
	if CivilizationSystem.civilizations.is_empty() or ((CivilizationSystem.civilizations[0] as Dictionary).get("strategic_regions",[]) as Array).is_empty():CivilizationSystem.reset_for_new_world()
	WorldSimulation.context_provider=func(_origin:Vector2)->Dictionary:return {"environment_profile":PlanetEnvironment.profile_at(Vector2.ZERO),"surface_water_distance_km":.1,"surface_water_recognized":true}
	for id in ["alpha","beta"]:
		WorldSimulation.create_actor(id,777,Vector2.ZERO)
		WorldSimulation.actors[id].systems.CivilizationSystem.scout_land_authority=func(_point:Vector2)->bool:return true
		WorldSimulation.actors[id].controller="manual"

func after_test()->void:
	WorldSimulation.clear()
	WorldSimulation.context_provider=Callable()
	# The court test gives the god's people a work and a known neighbour: undo both.
	var civs:Array=CivilizationSystem.civilizations
	for index in range(civs.size()-1,-1,-1):
		if String((civs[index] as Dictionary).get("id","")) in ["alpha","beta"]:civs.remove_at(index)
	for city:Dictionary in GameState.player_settlements:city["undertakings"]=[]
	ForeignDiplomacy.reset_for_new_world()

func _found(id:String)->Dictionary:
	return WorldSimulation.scoped(id,func()->Dictionary:
		WorldSimulation.state.settlement_completed=["Hearth Circle"]
		WorldSimulation.state.settlement_site_committed=true
		WorldSimulation.settlements.ensure_founded()
		WorldSimulation.state.simulation_metrics["food_days"]=120.0
		WorldSimulation.state.simulation_metrics["food_intake_ratio"]=1.0
		return WorldSimulation.state.player_settlements[0])

## A standing Sanctuary of Safe Passage (a legacy traffic work, pull 0.20).
func _sanctuary(id:String)->Dictionary:
	var city:=_found(id)
	var d:=Catalog.get_definition("safe_passage")
	var r:={"id":"safe_passage","status":"functioning","policy":"careful","progress":float(d.work),"quality":float(d.work),"condition":1.0,"strain":0,"stalled_days":0,"operating_days":400,"last_day":0,"started":0,"reason":"Test","legacy":"Test"}
	city.undertakings=[r]
	return r

## `viewer` knows `other` (contact 2, at peace).
func _view(viewer:String,other:String,opinion:float=0.0)->Dictionary:
	var civ:Dictionary=CivilizationSystem.civilizations[0].duplicate(true)
	civ.id=other
	civ.name=other.capitalize()
	if other!="player":WorldSimulation.scoped(other,func()->void:WorldSimulation.project(civ))
	civ.player_relation={"contact_level":2,"opinion":opinion,"treaty":"none","at_war":false,"met_day":0,"border_tension":0.0}
	civ["alive"]=true
	WorldSimulation.scoped(viewer,func()->void:WorldSimulation.world.civilizations.append(civ))
	return civ

## Travellers from `listener` have seen the work standing.
func _heard(r:Dictionary,listener:String,day:int=10)->void:
	if not r.has("heard_by"):r["heard_by"]={}
	r.heard_by[listener]={"day":day,"condition":1.0,"strain":0}

func test_only_those_who_have_heard_are_drawn_and_traders_get_the_stated_access()->void:
	var r:=_sanctuary("beta")
	_view("alpha","beta")
	assert_float(Effects.traffic_bonus("beta")).is_equal_approx(.20,.0001)
	assert_float(Rivalry.known_traffic("alpha","beta")).is_equal(0.0)
	assert_float(Controller.mission_pull("alpha","beta","open_trade")).is_equal(1.0)
	_heard(r,"alpha")
	assert_float(Rivalry.known_traffic("alpha","beta")).is_equal_approx(.20,.0001)
	# Computer rulers lean their trade and goodwill missions toward it, never their wars.
	assert_float(Controller.mission_pull("alpha","beta","goodwill")).is_equal_approx(1.20,.0001)
	assert_float(Controller.mission_pull("alpha","beta","declare_war")).is_equal(1.0)
	# Traders: the pull x 0.25, as the effect's words say.
	assert_float(Rivalry.trade_routing("beta")).is_equal_approx(.20*Effects.TRAFFIC_MARKET,.0001)
	var words:=Effects.describe("safe_passage",1.0,r)
	print("TRAFFIC WORDS: ",words)
	assert_str(words).contains("+%d points of market access" % roundi(.20*Effects.TRAFFIC_MARKET*100.0))
	assert_str(words).contains("up to 20% sooner")
	assert_str(words).contains("x1.20")
	assert_str(Effects.traffic_detail("beta")).contains("at 20%")

func _living(id:String,good:bool)->void:
	WorldSimulation.scoped(id,func()->void:
		var state=WorldSimulation.state
		state.ensure_population_total(1000)
		state.food_security=1.0 if good else 0.2
		state.housing_capacity=roundi(state.population_exact*(1.5 if good else 0.5))
		state.simulation_metrics["security"]=0.6 if good else 0.2
		state.simulation_metrics["cohesion"]=0.7 if good else 0.3
		state.simulation_metrics["food_days"]=120.0
		state.water_metrics["intake_ratio"]=1.0
		state.population_allocations["Administration"]=40)

func test_households_who_judge_life_better_come_on_their_own_and_the_counts_add_up()->void:
	var r:=_sanctuary("beta")
	_found("alpha")
	_living("alpha",false)
	_living("beta",true)
	_view("beta","alpha")
	_view("alpha","beta")
	var day:=400
	for id in ["alpha","beta"]:WorldSimulation.scoped(id,func()->void:WorldSimulation.state.elapsed_days=day)
	# Not yet heard of it: nobody comes.
	assert_int(WorldSimulation.scoped("beta",func()->int:return Exchange.drawn_households(day))).is_equal(0)
	_heard(r,"alpha")
	var alpha_before:=int(WorldSimulation.actors.alpha.systems.GameState.population_total)
	var beta_before:=int(WorldSimulation.actors.beta.systems.GameState.population_total)
	var ours:float=WorldSimulation.scoped("beta",func()->float:return Exchange.attraction())
	var theirs:float=WorldSimulation.scoped("alpha",func()->float:return Exchange.attraction())
	assert_float(ours-theirs).is_greater_equal(Exchange.MINIMUM_ATTRACTION_ADVANTAGE)
	day+=Exchange.DRAWN_REVIEW_DAYS
	for id in ["alpha","beta"]:WorldSimulation.scoped(id,func()->void:WorldSimulation.state.elapsed_days=day)
	var came:int=WorldSimulation.scoped("beta",func()->int:return Exchange.drawn_households(day))
	print("DRAWN HOUSEHOLDS: %d (advantage %.2f, pull %.2f)" % [came,ours-theirs,Effects.traffic_bonus("beta")])
	var expected:=minf(1000.0*Exchange.DRAWN_SHARE_MAX,1000.0*Exchange.DRAWN_RATE*.20*(ours-theirs))
	assert_int(came).is_between(floori(expected),ceili(expected))
	assert_int(came).is_greater(0)
	# One ledger: they left one people's count and joined the other's.
	assert_int(alpha_before-int(WorldSimulation.actors.alpha.systems.GameState.population_total)).is_equal(came)
	assert_int(int(WorldSimulation.actors.beta.systems.GameState.population_total)-beta_before).is_equal(came)
	var settling:Array=WorldSimulation.actors.beta.systems.GameState.society_exchange.integration
	assert_bool(settling.any(func(group:Dictionary)->bool:return String(group.origin)=="alpha" and int(group.remaining)==came)).is_true()
	assert_int(int(WorldSimulation.actors.alpha.systems.GameState.society_exchange.connections.beta.departures)).is_equal(came)
	# At most once a review period, and never while reception is closed.
	assert_int(WorldSimulation.scoped("beta",func()->int:return Exchange.drawn_households(day+1))).is_equal(0)
	WorldSimulation.scoped("beta",func()->void:Exchange.policy("consolidate","selective"))
	assert_int(WorldSimulation.scoped("beta",func()->int:return Exchange.drawn_households(day+Exchange.DRAWN_REVIEW_DAYS))).is_equal(0)
	assert_bool(Exchange.valid(WorldSimulation.actors.beta.systems.GameState.society_exchange)).is_true()

func test_a_people_that_lives_as_well_does_not_leave()->void:
	var r:=_sanctuary("beta")
	_found("alpha")
	_living("alpha",true)
	_living("beta",true)
	_view("beta","alpha")
	_heard(r,"alpha")
	assert_int(WorldSimulation.scoped("beta",func()->int:return Exchange.drawn_households(500))).is_equal(0)

func test_the_courts_envoys_with_business_come_sooner_within_the_halls_pace()->void:
	GameState.reset_for_new_world(6161)
	# A new world clears the owned peoples: bring the neighbour back.
	WorldSimulation.create_actor("alpha",777,Vector2.ZERO)
	WorldSimulation.actors.alpha.systems.CivilizationSystem.scout_land_authority=func(_point:Vector2)->bool:return true
	WorldSimulation.actors.alpha.controller="manual"
	GameState.settlement_site_committed=true
	GameState.settlement_completed.assign(["Hearth Circle"])
	SettlementModel.ensure_founded()
	var day:=3000
	GameState.elapsed_days=day
	CivilizationSystem.initialize()
	ForeignDiplomacy.ensure()
	var city:Dictionary=GameState.player_settlements[0]
	var d:=Catalog.get_definition("safe_passage")
	var r:={"id":"safe_passage","status":"functioning","policy":"careful","progress":float(d.work),"quality":float(d.work),"condition":1.0,"strain":0,"stalled_days":0,"operating_days":400,"last_day":0,"started":0,"reason":"Test","legacy":"Test"}
	city.undertakings=[r]
	_found("alpha")
	_view("player","alpha",.4)
	var s:=Hall.state()
	s.last_arrival_day=day-2000
	s.next_any=0
	var usual:=Hall.civ_gap("alpha")
	# Silent 90% of its usual wait: without the work, it waits on.
	(s.last_word as Dictionary)["alpha"]=day-roundi(float(usual)*.9)
	ForeignDiplomacy._drawn_envoys(day)
	assert_bool(Hall.occasions().any(func(o:Dictionary)->bool:return String(o.key).begins_with("drawn:"))).is_false()
	# Heard of the work (pull 0.20): a people silent 90% of its wait comes now.
	_heard(r,"alpha")
	ForeignDiplomacy._drawn_checked_day=-1
	ForeignDiplomacy._drawn_envoys(day)
	var drawn:Array=Hall.occasions().filter(func(o:Dictionary)->bool:return String(o.key)=="drawn:alpha:%d" % day)
	assert_int(drawn.size()).is_equal(1)
	assert_str(String(drawn[0].type)).is_equal("ambient")
	assert_bool(((drawn[0].data as Dictionary).get("business",{}) as Dictionary).is_empty()).is_false()
	assert_int(int((Hall.state().last_word as Dictionary).alpha)).is_equal(day)
	# One visit, not a stream: silence starts again from today.
	ForeignDiplomacy._drawn_envoys(day+1)
	assert_int(Hall.occasions().filter(func(o:Dictionary)->bool:return String(o.key).begins_with("drawn:")).size()).is_equal(1)
	# Silent only 70% of its wait: even a pull of 0.20 does not bring it (80% needed).
	(Hall.state().occasions as Array).clear()
	(Hall.state().last_word as Dictionary)["alpha"]=day+10-roundi(float(usual)*.7)
	ForeignDiplomacy._drawn_envoys(day+10)
	assert_array(Hall.occasions()).is_empty()

func test_the_god_is_told_when_households_leave_and_why()->void:
	var r:=_sanctuary("beta")
	_living("player",false)
	_living("beta",true)
	_view("beta","player")
	_heard(r,"player")
	var day:=400
	for id in ["player","beta"]:WorldSimulation.scoped(id,func()->void:WorldSimulation.state.elapsed_days=day)
	GameState.simulation_events.clear()
	var came:int=WorldSimulation.scoped("beta",func()->int:return Exchange.drawn_households(day))
	assert_int(came).is_greater(0)
	var told:Array=GameState.simulation_events.filter(func(e:Dictionary)->bool:return String(e.title).begins_with("PEOPLE LEAVE FOR"))
	assert_int(told.size()).is_equal(1)
	print("LEAVING NOTICE: ",told[0].description)
	assert_str(String(told[0].description)).contains("%d of our people left for" % came).contains("they eat better there").contains("More on getting food")
	var year:Array=Exchange.leaving_this_year()
	assert_int(year.size()).is_equal(1)
	assert_int(int(year[0].count)).is_equal(came)
	assert_bool(Exchange.valid(GameState.society_exchange)).is_true()
	GameState.society_exchange.erase("emigration")
