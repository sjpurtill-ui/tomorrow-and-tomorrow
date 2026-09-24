extends GdUnitTestSuite
## AI pursuit of Great Works, observable rival progress, sabotage and war.
const Strategy=preload("res://scripts/civilization_strategy.gd")
const Controller=preload("res://scripts/civilization_controller.gd")
const Rivalry=preload("res://scripts/great_works_rivalry.gd")
const Catalog=preload("res://scripts/undertaking_catalog.gd")
const Artifacts=preload("res://scripts/artifact_collection.gd")
const Peaceful={"openness":.8,"discipline":.3,"empathy":.95,"assertiveness":.15,"risk_tolerance":.15}
const Martial={"openness":.35,"discipline":.9,"empathy":.15,"assertiveness":.95,"risk_tolerance":.9}
const MATERIALS:={"Stone":10000.0,"Timber":10000.0,"Clay":10000.0,"Fiber Plants":10000.0}

func before_test()->void:
	WorldSimulation.clear()
	WorldSimulation.context_provider=func(_origin:Vector2)->Dictionary:return {"environment_profile":PlanetEnvironment.profile_at(Vector2.ZERO),"surface_water_distance_km":.1,"surface_water_recognized":true}
	for id in ["alpha","beta","gamma"]:
		WorldSimulation.create_actor(id,777,Vector2.ZERO)
		WorldSimulation.actors[id].systems.CivilizationSystem.scout_land_authority=func(_point:Vector2)->bool:return true
		WorldSimulation.actors[id].controller="manual"

func after_test()->void:
	WorldSimulation.clear()
	WorldSimulation.context_provider=Callable()

func _found(id:String)->Dictionary:
	return WorldSimulation.scoped(id,func()->Dictionary:
		WorldSimulation.state.settlement_completed=["Hearth Circle"]
		WorldSimulation.state.settlement_site_committed=true
		WorldSimulation.settlements.ensure_founded()
		WorldSimulation.state.simulation_metrics["food_days"]=120.0
		WorldSimulation.state.simulation_metrics["food_intake_ratio"]=1.0
		return WorldSimulation.state.player_settlements[0])

func _work(id:String,work_id:String,status:String,progress_share:float)->Dictionary:
	var city:=_found(id)
	var d:=Catalog.get_definition(work_id)
	var r:={"id":work_id,"status":status,"policy":"careful","progress":float(d.work)*progress_share,"quality":float(d.work)*progress_share*.9,"condition":1.0,"strain":0,"stalled_days":0,"operating_days":0,"last_day":0,"started":0,"reason":"Test","legacy":"Test"}
	city.undertakings=[r]
	return r

## `viewer` sees `other` as a contacted people with one projected city.
func _view(viewer:String,other:String)->Dictionary:
	var civ:Dictionary=CivilizationSystem.civilizations[0].duplicate(true)
	civ.id=other
	civ.name=other.capitalize()
	if other!="player":WorldSimulation.scoped(other,func()->void:WorldSimulation.project(civ))
	civ.player_relation={"contact_level":2,"opinion":0.0,"treaty":"none","at_war":false}
	WorldSimulation.scoped(viewer,func()->void:WorldSimulation.world.civilizations.append(civ))
	return civ

func _capital(civ:Dictionary)->Dictionary:
	for region:Dictionary in civ.strategic_regions:
		if region.has("local_city_id"):return region
	return {}

func _observe(viewer:String,civ:Dictionary,quality:float,day:int)->void:
	var region:=_capital(civ)
	WorldSimulation.scoped(viewer,func()->void:
		var intel=WorldSimulation.world.city_intelligence
		intel.publish("player",intel.capture("player",String(region.id),quality,day,"scout report","test:%d" % day),day))

func test_personalities_prefer_different_works_from_the_same_offer()->void:
	var peaceful:=Strategy.preferences(Peaceful,{"food_days":120})
	var martial:=Strategy.preferences(Martial,{"food_days":120})
	var picks:Array=[]
	for plan in [peaceful,martial]:
		var best:="";var value:=-INF
		for d:Dictionary in Catalog.all():
			var score:=Strategy.great_work_score(d,plan,{"coverage":1.0})
			if score>value:best=String(d.id);value=score
		picks.append(best)
	assert_str(picks[0]).is_not_equal(picks[1])
	# A known finished rival claim removes a work; a rival ahead lowers it.
	var ring:=Catalog.get_definition("ancestor_ring")
	assert_float(Strategy.great_work_score(ring,peaceful,{"claimed":true})).is_equal(-INF)
	assert_float(Strategy.great_work_score(ring,peaceful,{"rival_ahead":true})).is_less(Strategy.great_work_score(ring,peaceful,{}))

func test_ai_rulers_start_different_works_only_through_paid_orders()->void:
	var started:Array=[]
	for pair in [["alpha",Peaceful],["beta",Martial]]:
		var id:=String(pair[0])
		_found(id)
		WorldSimulation.scoped(id,func()->void:
			var state:=WorldSimulation.state
			state.population_total=900;state.population_exact=900.0
			state.known_discoveries=["clay_shaping","seed_selection","public_stores","framed_construction"]
			state.resource_stockpiles.merge(MATERIALS,true)
			var before:=state.resource_stockpiles.duplicate(true)
			var plan:=Strategy.preferences(pair[1],{"food_days":120})
			Controller.great_work_orders(id,plan)
			var city:Dictionary=state.player_settlements[0]
			var works:Array=city.get("undertakings",[])
			assert_int(works.size()).override_failure_message("No work started by "+id+": "+str(WorldSimulation.actors[id].orders)).is_equal(1)
			if works.is_empty():return
			started.append(String(works[0].id))
			# The start was an order in the audit log, and nothing was granted.
			var logged:=false
			for entry:Dictionary in WorldSimulation.actors[id].orders:
				if String(entry.order.kind)=="great_work_start" and entry.result.has("ok"):logged=true
			assert_bool(logged).is_true()
			for material:String in before:assert_float(float(state.resource_stockpiles[material])).is_less_equal(float(before[material]))
			# A second review cannot run a second concurrent work in the same city.
			Controller.great_work_orders(id,plan)
			assert_int((city.undertakings as Array).size()).is_equal(1)
		)
	assert_int(started.size()).is_equal(2)
	if started.size()==2:assert_str(started[0]).is_not_equal(started[1])

func test_no_stores_no_start_and_invalid_orders_change_nothing()->void:
	_found("alpha")
	WorldSimulation.scoped("alpha",func()->void:
		var state:=WorldSimulation.state
		state.population_total=900;state.population_exact=900.0
		for material:String in MATERIALS:state.resource_stockpiles[material]=0.0
		Controller.great_work_orders("alpha",Strategy.preferences(Martial,{"food_days":120}))
		var city:Dictionary=state.player_settlements[0]
		assert_array(city.get("undertakings",[])).is_empty()
		for order in [{"kind":"great_work_start","city":String(city.id),"id":"no_such_work"},{"kind":"great_work_policy","city":String(city.id),"id":"ancestor_ring","policy":"press"},{"kind":"great_work_policy","city":String(city.id),"id":"ancestor_ring","policy":"conjure"},{"kind":"great_work_restore","city":String(city.id),"id":"ancestor_ring"}]:
			assert_bool(WorldSimulation.submit("alpha",order).has("error")).override_failure_message(str(order)).is_true()
		assert_array(city.get("undertakings",[])).is_empty()
	)

func test_rival_news_requires_a_real_observation_and_is_uncertain()->void:
	_work("beta","stone_crown","building",.4)
	var beta:=_view("alpha","beta")
	assert_array(Rivalry.rival_news_for("alpha")).is_empty()
	assert_dict(Rivalry.race_for("alpha","stone_crown",0.0)).is_empty()
	_observe("alpha",beta,.8,40)
	var news:=Rivalry.rival_news_for("alpha")
	assert_int(news.size()).is_equal(1)
	var item:Dictionary=news[0]
	print("RIVAL NEWS: ",item.text)
	assert_str(String(item.work_id)).is_equal("stone_crown")
	assert_str(String(item.owner)).is_equal("beta")
	assert_int(int(item.day)).is_equal(40)
	assert_float(float(item.progress_low)).is_less_equal(.4)
	assert_float(float(item.progress_high)).is_greater_equal(.4)
	assert_float(float(item.progress_high)-float(item.progress_low)).is_greater(0.0)
	# The report is frozen: later hidden progress does not leak into old news.
	WorldSimulation.actors.beta.systems.GameState.player_settlements[0].undertakings[0].progress=float(Catalog.get_definition("stone_crown").work)*.9
	assert_float(float(Rivalry.rival_news_for("alpha")[0].progress_high)).is_less(.9)
	assert_bool(Rivalry.race_for("alpha","stone_crown",.1).rival_ahead).is_true()
	# A poor observation sees a site but cannot name the work.
	_view("gamma","beta")
	_observe("gamma",WorldSimulation.actors.gamma.systems.CivilizationSystem.civilizations[0],.4,41)
	var vague:=Rivalry.rival_news_for("gamma")
	assert_int(vague.size()).is_equal(1)
	if not vague.is_empty():
		print("VAGUE NEWS: ",vague[0].text)
		assert_str(String(vague[0].work_id)).is_empty()
	# Observations survive the civilization save round-trip and validation.
	var saved:=WorldSimulation.export_state()
	assert_bool(WorldSimulation.import_state(bytes_to_var(var_to_bytes(saved))).get("ok",false)).is_true()
	assert_bool(CivilizationSystem.city_intelligence.validate(WorldSimulation.actors.alpha.systems.CivilizationSystem.city_intelligence.records)).is_true()

func test_race_reactions_follow_personality()->void:
	var race:={"owner":"beta","claimed":false,"rival_mid":.7,"rival_ahead":true,"allied":false}
	assert_str(Strategy.great_work_reaction(Strategy.preferences(Martial,{"food_days":120}),race,.5,120)).is_equal("sabotage")
	assert_str(Strategy.great_work_reaction(Strategy.preferences(Peaceful,{"food_days":120}),race,.1,120)).is_equal("abandon")
	assert_str(Strategy.great_work_reaction(Strategy.preferences(Peaceful,{"food_days":120}),race,.5,120)).is_equal("press")
	assert_str(Strategy.great_work_reaction(Strategy.preferences(Martial,{"food_days":120}),race,.5,120,false)).is_equal("press")
	assert_str(Strategy.great_work_reaction(Strategy.preferences(Martial,{"food_days":120}),{"claimed":true,"rival_ahead":true,"rival_mid":1.0},.5,120)).is_equal("abandon")
	assert_str(Strategy.great_work_reaction(Strategy.preferences(Martial,{"food_days":5,"food_intake_ratio":.5}),race,.5,5)).is_equal("careful")

func test_sabotage_costs_real_provisions_and_carries_real_risk()->void:
	var target:=_work("beta","stone_crown","building",.5)
	var before_progress:=float(target.progress)
	_found("alpha")
	var beta:=_view("alpha","beta")
	_view("beta","alpha")
	assert_bool(WorldSimulation.submit("alpha",{"kind":"great_work_sabotage","target":"beta","city":String(_capital(beta).local_city_id),"id":"stone_crown"}).has("error")).is_true()
	_observe("alpha",beta,.8,10)
	var people:=float(WorldSimulation.actors.alpha.systems.GameState.population_exact)
	var food:float=WorldSimulation.scoped("alpha",func()->float:return WorldSimulation.food.total_stored())
	var result:=WorldSimulation.submit("alpha",{"kind":"great_work_sabotage","target":"beta","city":String(_capital(beta).local_city_id),"id":"stone_crown"})
	if result.has("error") and String(result.error).contains("food"):
		WorldSimulation.scoped("alpha",func()->void:WorldSimulation.economy._receive_trade_resource("Food",5000.0))
		food=WorldSimulation.scoped("alpha",func()->float:return WorldSimulation.food.total_stored())
		result=WorldSimulation.submit("alpha",{"kind":"great_work_sabotage","target":"beta","city":String(_capital(beta).local_city_id),"id":"stone_crown"})
	assert_bool(result.get("ok",false)).override_failure_message(str(result)).is_true()
	if not result.get("ok",false):return
	print("SABOTAGE: ",result.message)
	assert_float(WorldSimulation.scoped("alpha",func()->float:return WorldSimulation.food.total_stored())).is_less(food)
	if bool(result.success):
		assert_float(float(target.progress)).is_less(before_progress)
	else:
		assert_float(float(WorldSimulation.actors.alpha.systems.GameState.population_exact)).is_less(people)
		assert_float(Rivalry.grievance("beta","alpha")).is_greater(0.0)
	# Agents need time before another attempt.
	assert_bool(WorldSimulation.submit("alpha",{"kind":"great_work_sabotage","target":"beta","city":String(_capital(beta).local_city_id),"id":"stone_crown"}).has("error")).is_true()
	# Both outcomes across many seeds occur: real risk, not a guaranteed effect.
	var outcomes:={}
	for day in range(200,4000,190):
		WorldSimulation.scoped("alpha",func()->void:
			WorldSimulation.state.elapsed_days=day
			WorldSimulation.economy._receive_trade_resource("Food",200.0))
		_observe("alpha",beta,.8,day)
		var attempt:=WorldSimulation.submit("alpha",{"kind":"great_work_sabotage","target":"beta","city":String(_capital(beta).local_city_id),"id":"stone_crown"})
		if attempt.get("ok",false):outcomes[bool(attempt.success)]=true
	assert_int(outcomes.size()).is_equal(2)

func test_capture_transfers_holding_and_looting_moves_real_artifacts_with_memory()->void:
	WorldSimulation.enabled=true
	var r:=_work("beta","stone_crown","functioning",1.0)
	var artifact:=Artifacts.find_at(777,Vector2(300,40),5)
	WorldSimulation.actors.beta.systems.GameState.society_exchange.collections[String(artifact.id)]=artifact
	r["enshrined"]=[String(artifact.id)]
	var beta:=_view("alpha","beta")
	_view("beta","alpha")
	_view("gamma","alpha")
	var region:=_capital(beta)
	WorldSimulation.scoped("alpha",func()->void:
		var host:=WorldSimulation.military
		host.home_army=host.simulator.create_formation_force("Alpha",[{"id":1,"unit":"levy","weapon":"improvised","count":50,"equipment":50,"equipment_required":50}],.9,.9)
		var captured:=preload("res://scripts/civilization_combat.gd").capture(beta,String(region.id),host.home_army)
		assert_bool(captured.outcome.get("region_captured",false)).override_failure_message(str(captured)).is_true())
	var city:Dictionary=WorldSimulation.actors.beta.systems.GameState.player_settlements[0]
	assert_str(Rivalry.holder("beta",city)).is_equal("alpha")
	var held:=Rivalry.held_works("alpha")
	assert_int(held.size()).is_equal(1)
	# Only the occupier may loot; an uninvolved people cannot.
	assert_bool(WorldSimulation.submit("gamma",{"kind":"great_work_loot","owner":"beta","city":String(city.id),"id":"stone_crown"}).has("error")).is_true()
	var gamma_before:=float(Rivalry.relation("gamma","alpha").opinion)
	var loot:=WorldSimulation.submit("alpha",{"kind":"great_work_loot","owner":"beta","city":String(city.id),"id":"stone_crown"})
	assert_bool(loot.get("ok",false)).override_failure_message(str(loot)).is_true()
	assert_bool(WorldSimulation.actors.alpha.systems.GameState.society_exchange.collections.has(String(artifact.id))).is_true()
	assert_bool(WorldSimulation.actors.beta.systems.GameState.society_exchange.collections.has(String(artifact.id))).is_false()
	assert_array(r.enshrined).is_empty()
	assert_float(float(Rivalry.relation("gamma","alpha").opinion)).is_less(gamma_before)
	assert_float(float(Rivalry.relation("beta","alpha").opinion)).is_less(0.0)
	# The daily world pass records the capture as a lasting grievance and memories.
	Rivalry.advance_world(30)
	assert_str(String(r.rivalry.holder)).is_equal("alpha")
	assert_float(Rivalry.grievance("beta","alpha")).is_greater_equal(.35)
	assert_float(Rivalry.grievance("beta","alpha")).is_less_equal(.6)
	var memories:Array=WorldSimulation.actors.alpha.systems.ForeignDiplomacy.leaders.get("beta",{}).get("memories",[])
	assert_bool(memories.any(func(m:Dictionary)->bool:return String(m.text).contains("seized"))).override_failure_message(str(memories)).is_true()
	var news:=Rivalry.rival_news_for("gamma")
	assert_bool(news.any(func(n:Dictionary)->bool:return String(n.get("event",""))=="looted")).is_true()
	for n:Dictionary in news:print("WAR NEWS (gamma): ",n.text)
	# Recovery ends the holding but not the memory of loot never returned.
	WorldSimulation.actors.beta.systems.GameState.player_settlements[0].occupied_by=""
	Rivalry.advance_world(31)
	assert_str(String(r.rivalry.holder)).is_equal("beta")
	var lingering:=Rivalry.grievance("beta","alpha")
	assert_float(lingering).is_greater(0.0)
	assert_float(lingering).is_less(.35)
	# Returning the treasure moves the real item back and softens the grievance.
	var returned:=WorldSimulation.submit("alpha",{"kind":"great_work_return_loot","owner":"beta","id":"stone_crown"})
	assert_bool(returned.get("ok",false)).override_failure_message(str(returned)).is_true()
	assert_bool(WorldSimulation.actors.beta.systems.GameState.society_exchange.collections.has(String(artifact.id))).is_true()
	assert_float(Rivalry.grievance("beta","alpha")).is_less(lingering)
	assert_bool(preload("res://scripts/undertaking_system.gd").valid(WorldSimulation.actors.beta.systems.GameState.player_settlements)).is_true()
	assert_bool(Rivalry.valid_rivalry(r)).is_true()

func test_siege_damages_condition_and_restoration_pays_from_local_stores()->void:
	var r:=_work("beta","stone_crown","functioning",1.0)
	var city_id:=String(WorldSimulation.actors.beta.systems.GameState.player_settlements[0].id)
	WorldSimulation.actors.beta.systems.MilitaryCampaign.active_siege={"id":"s1","mode":"defensive","home_city":{"id":city_id},"pressure":.5}
	for day in range(1,201):Rivalry.advance_world(day)
	WorldSimulation.actors.beta.systems.MilitaryCampaign.active_siege={}
	assert_float(float(r.condition)).is_less(.9)
	assert_float(float(r.condition)).is_greater_equal(Rivalry.SIEGE_FLOOR)
	assert_bool((r.rivalry.events as Array).any(func(e:Dictionary)->bool:return String(e.kind)=="siege_damage")).is_true()
	var damaged:=float(r.condition)
	WorldSimulation.scoped("beta",func()->void:
		for material:String in MATERIALS:WorldSimulation.state.resource_stockpiles[material]=0.0)
	assert_bool(WorldSimulation.submit("beta",{"kind":"great_work_restore","city":city_id,"id":"stone_crown"}).has("error")).is_true()
	assert_float(float(r.condition)).is_equal(damaged)
	WorldSimulation.scoped("beta",func()->void:WorldSimulation.state.resource_stockpiles.merge(MATERIALS,true))
	assert_bool(WorldSimulation.submit("beta",{"kind":"great_work_restore","city":city_id,"id":"stone_crown"}).get("ok",false)).is_true()
	assert_float(float(r.condition)).is_greater(damaged)
	assert_float(float(WorldSimulation.actors.beta.systems.GameState.resource_stockpiles.Stone)).is_less(10000.0)

func test_deterrence_is_bounded_and_needs_knowledge()->void:
	var plan:=Strategy.preferences(Martial,{"food_days":120})
	var hostile:={"opinion":float(plan.war_opinion)-.05,"treaty":"none"}
	assert_str(Strategy.diplomatic_action(hostile,plan,120)).is_equal("declare_war")
	assert_str(Strategy.diplomatic_action(hostile,plan,120,.2)).is_not_equal("declare_war")
	var furious:={"opinion":float(plan.war_opinion)-.35,"treaty":"none"}
	# Deterrence restrains; it never forbids a war beyond its bound.
	assert_str(Strategy.diplomatic_action(furious,plan,120,5.0)).is_equal("declare_war")
	_work("beta","stone_crown","functioning",1.0)
	var beta:=_view("alpha","beta")
	assert_float(Rivalry.known_deterrence("alpha","beta")).is_equal(0.0)
	# Once alpha has seen the Crown standing, it weighs war against beta more gravely.
	_observe("alpha",beta,.8,20)
	assert_float(Rivalry.known_deterrence("alpha","beta")).is_greater(0.0)
	assert_float(Rivalry.known_deterrence("alpha","beta")).is_less_equal(.3)
	for owner in ["player","alpha","beta"]:
		assert_float(Rivalry.known_deterrence(owner,"beta")).is_between(0.0,.3)
		assert_float(Rivalry.trade_routing(owner)).is_between(0.0,.1)

func test_controller_reacts_to_an_observed_race_by_personality()->void:
	var reactions:Dictionary={}
	for pair in [["alpha",Peaceful],["gamma",Martial]]:
		var id:=String(pair[0])
		var own:=_work(id,"stone_crown","building",.1)
		_work("beta","stone_crown","building",.6)
		var beta:=_view(id,"beta")
		_view("beta",id)
		WorldSimulation.scoped(id,func()->void:WorldSimulation.economy._receive_trade_resource("Food",5000.0))
		_observe(id,beta,.8,15)
		var city:=String(WorldSimulation.actors[id].systems.GameState.player_settlements[0].id)
		WorldSimulation.scoped(id,func()->void:
			WorldSimulation.state.elapsed_days=20
			Controller.great_work_orders(id,Strategy.preferences(pair[1],{"food_days":120})))
		var kinds:Array=[]
		for entry:Dictionary in WorldSimulation.actors[id].orders:kinds.append(String(entry.order.kind)+":"+String(entry.order.get("policy","")))
		reactions[id]=kinds
		if id=="alpha":assert_str(String(own.status)).is_equal("abandoned")
		else:
			assert_array(kinds).contains(["great_work_sabotage:"])
			assert_str(String(own.policy)).is_equal("press")
		assert_str(city).is_not_empty()
	print("RACE REACTIONS: ",reactions)

func test_lost_race_monument_is_quarried_or_repurposed_by_the_ai()->void:
	var results:Dictionary={}
	for pair in [["alpha",Peaceful],["gamma",Martial]]:
		var id:=String(pair[0])
		var r:=_work(id,"stone_crown","rival",.4)
		WorldSimulation.scoped(id,func()->void:
			var stone:=float(WorldSimulation.state.resource_stockpiles.get("Stone",0))
			Controller.great_work_orders(id,Strategy.preferences(pair[1],{"food_days":120}))
			results[id]=[String(r.status),float(WorldSimulation.state.resource_stockpiles.get("Stone",0))-stone])
	assert_str(String(results.alpha[0])).is_equal("functioning")
	assert_str(String(results.gamma[0])).is_equal("quarried")
	assert_float(float(results.gamma[1])).is_greater(0.0)

func test_route_drawing_work_widens_only_the_external_market_quote()->void:
	WorldSimulation.enabled=true
	_work("beta","safe_passage","functioning",1.0)
	assert_float(Rivalry.trade_routing("beta")).is_greater(0.0)
	assert_float(Rivalry.trade_routing("beta")).is_less_equal(.1)
	assert_float(Rivalry.trade_routing("alpha")).is_equal(0.0)
	# A captured sanctuary no longer routes traders to its builders.
	WorldSimulation.actors.beta.systems.GameState.player_settlements[0].occupied_by="alpha"
	assert_float(Rivalry.trade_routing("beta")).is_equal(0.0)
