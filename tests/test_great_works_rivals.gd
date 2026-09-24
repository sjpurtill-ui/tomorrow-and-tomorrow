extends GdUnitTestSuite
## AI conception of wonders, news of other peoples' works, envy, sabotage and war.
const Strategy=preload("res://scripts/civilization_strategy.gd")
const Controller=preload("res://scripts/civilization_controller.gd")
const Rivalry=preload("res://scripts/great_works_rivalry.gd")
const Catalog=preload("res://scripts/undertaking_catalog.gd")
const Artifacts=preload("res://scripts/artifact_collection.gd")
const Orders=preload("res://scripts/civilization_orders.gd")
const Cautious={"openness":.5,"discipline":.5,"empathy":.6,"assertiveness":.3,"risk_tolerance":.1}
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
	Orders.works_engine_override=null
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

func test_rival_news_requires_a_real_observation_and_is_uncertain()->void:
	_work("beta","stone_crown","building",.4)
	var beta:=_view("alpha","beta")
	assert_array(Rivalry.rival_news_for("alpha")).is_empty()
	assert_array(Rivalry.heard_works("alpha",-1,"")).is_empty()
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
	assert_int(Rivalry.heard_works("alpha",-1,"building").size()).is_equal(1)
	assert_array(Rivalry.heard_works("alpha",-1,"functioning")).is_empty()
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
	for day in range(800,16000,730):
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

func test_route_drawing_work_widens_only_the_external_market_quote()->void:
	WorldSimulation.enabled=true
	_work("beta","safe_passage","functioning",1.0)
	assert_float(Rivalry.trade_routing("beta")).is_greater(0.0)
	assert_float(Rivalry.trade_routing("beta")).is_less_equal(.1)
	assert_float(Rivalry.trade_routing("alpha")).is_equal(0.0)
	# A captured sanctuary no longer routes traders to its builders.
	WorldSimulation.actors.beta.systems.GameState.player_settlements[0].occupied_by="alpha"
	assert_float(Rivalry.trade_routing("beta")).is_equal(0.0)

## A stand-in works engine: offers concepts, assesses by ambition, records the
## commission. The real engine (great_works.gd) is reached the same way.
class FakeEngine extends RefCounted:
	var commissioned:Array=[]
	var triggers:Array=[]
	func conceive(owner:String,trigger:Dictionary)->Array:
		triggers.append(trigger.duplicate())
		return [{"name":"The Weeping Stair of Varrow","form":"stair","purpose":"honor_dead"},{"name":"Crown That Outshines Theirs","form":"tower","purpose":"awe_rivals"}]
	func assess(concept:Dictionary,owner:String)->Dictionary:
		return {"score":{"modest":.9,"grand":.6,"audacious":.3}.get(String(concept.get("ambition","modest")),.5),"spoken":"test"}
	func commission(city_id:String,concept:Dictionary,ambition:String,owner:String)->Dictionary:
		commissioned.append({"owner":owner,"city":city_id,"name":String(concept.name),"ambition":ambition,"purpose":String(concept.purpose)})
		WorldSimulation.state.player_settlements[0].undertakings=[{"id":"w_"+owner,"status":"building","policy":"careful","started":int(WorldSimulation.state.elapsed_days),"name":String(concept.name)}]
		return {"ok":true}
	func direct(city_id:String,id:String,policy:String)->void:pass

func test_motives_and_ambition_follow_temperament()->void:
	var peaceful:=Strategy.preferences(Peaceful,{"food_days":120})
	var martial:=Strategy.preferences(Martial,{"food_days":120})
	var cautious:=Strategy.preferences(Cautious,{"food_days":120})
	# Grief moves the compassionate; triumph moves the proud.
	assert_float(Strategy.wonder_motive({"kind":"death"},peaceful)).is_greater_equal(Strategy.WONDER_MOTIVE_THRESHOLD)
	assert_float(Strategy.wonder_motive({"kind":"death"},martial)).is_less(Strategy.WONDER_MOTIVE_THRESHOLD)
	assert_float(Strategy.wonder_motive({"kind":"victory"},martial)).is_greater_equal(Strategy.WONDER_MOTIVE_THRESHOLD)
	assert_float(Strategy.wonder_motive({"kind":"victory"},peaceful)).is_less(Strategy.WONDER_MOTIVE_THRESHOLD)
	# Same assessed feasibility, different choices: the bold overreach.
	var choices:Dictionary={}
	for pair in [["peaceful",peaceful],["martial",martial],["cautious",cautious]]:
		var best:="";var value:=-INF
		for ambition:String in Strategy.WONDER_AMBITIONS:
			var v:=Strategy.wonder_ambition_value(ambition,{"modest":.9,"grand":.6,"audacious":.3}[ambition],pair[1])
			if v>value:best=ambition;value=v
		choices[pair[0]]=best
	print("AMBITION CHOICES: ",choices)
	assert_str(String(choices.martial)).is_equal("audacious")
	assert_str(String(choices.cautious)).is_equal("modest")
	assert_float(Strategy.wonder_ambition_value("audacious",.2,cautious)).is_equal(-INF)
	assert_float(Strategy.wonder_ambition_value("audacious",.2,martial)).is_greater(0.0)
	# Reckless rulers keep building a doubtful work; prudent ones cut their losses.
	assert_bool(Strategy.wonder_abandon(cautious,.1)).is_true()
	assert_bool(Strategy.wonder_abandon(martial,.1)).is_false()
	assert_bool(Strategy.wonder_abandon(cautious,-1.0)).is_false()
	assert_int(Strategy.wonder_interval_days(martial)).is_less(Strategy.wonder_interval_days(cautious))

func test_triggers_come_from_the_peoples_own_history_and_news()->void:
	_found("alpha")
	var martial:=Strategy.preferences(Martial,{"food_days":120})
	var peaceful:=Strategy.preferences(Peaceful,{"food_days":120})
	WorldSimulation.scoped("alpha",func()->void:
		WorldSimulation.state.elapsed_days=400
		assert_dict(Controller.conception_trigger("alpha",martial)).is_empty()
		WorldSimulation.military.battle_history.push_front({"day":380,"home_side":"defender","defender":{"name":"Alpha Host"},"winner":"Alpha Host","target_region_name":"the Ford"})
		assert_str(String(Controller.conception_trigger("alpha",martial).get("kind",""))).is_equal("victory")
		assert_dict(Controller.conception_trigger("alpha",peaceful)).is_empty()
		WorldSimulation.military.battle_history.clear()
		WorldSimulation.state.demographic_ledger.append({"kind":"death","cause":"Hunger","count":6,"day":200})
		assert_str(String(Controller.conception_trigger("alpha",peaceful).get("kind",""))).is_equal("famine"))
	# Hearing of another people's finished work stirs envy in the proud.
	_work("beta","stone_crown","functioning",1.0)
	var beta:=_view("alpha","beta")
	WorldSimulation.scoped("alpha",func()->void:WorldSimulation.state.demographic_ledger.clear())
	assert_dict(WorldSimulation.scoped("alpha",func()->Dictionary:return Controller.conception_trigger("alpha",martial))).is_empty()
	_observe("alpha",beta,.8,390)
	var envy:Dictionary=WorldSimulation.scoped("alpha",func()->Dictionary:return Controller.conception_trigger("alpha",martial))
	assert_str(String(envy.get("kind",""))).is_equal("envy")
	assert_str(String(envy.get("source_owner",""))).is_equal("beta")
	print("ENVY TRIGGER: ",envy)

func test_rulers_conceive_and_commission_through_validated_orders()->void:
	var engine:=FakeEngine.new()
	Orders.works_engine_override=engine
	var results:Dictionary={}
	for pair in [["alpha",Peaceful],["gamma",Martial]]:
		var id:=String(pair[0])
		_found(id)
		var plan:=Strategy.preferences(pair[1],{"food_days":120})
		WorldSimulation.scoped(id,func()->void:
			WorldSimulation.state.elapsed_days=400
			# Grief for the compassionate ruler, victory for the proud one.
			WorldSimulation.state.demographic_ledger.append({"kind":"death","cause":"Illness","count":40,"day":300})
			WorldSimulation.military.battle_history.push_front({"day":380,"home_side":"attacker","attacker":{"name":"Host"},"winner":"Host","target_region_name":"the Ridge"})
			Controller.great_work_orders(id,plan)
			# One work at a time; another review adds nothing.
			Controller.great_work_orders(id,plan))
		var logged:Array=[]
		for entry:Dictionary in WorldSimulation.actors[id].orders:
			if String(entry.order.kind)=="great_work_commission":logged.append(entry.order)
		assert_int(logged.size()).override_failure_message(str(WorldSimulation.actors[id].orders)).is_equal(1)
		if not logged.is_empty():results[id]={"trigger":logged[0].trigger,"ambition":logged[0].ambition,"name":logged[0].concept.name,"feasibility":logged[0].feasibility}
	print("CONCEPTION: ",results)
	assert_int(engine.commissioned.size()).is_equal(2)
	if results.size()==2:
		assert_str(String(results.alpha.trigger)).is_equal("death")
		assert_str(String(results.alpha.name)).is_equal("The Weeping Stair of Varrow")
		assert_str(String(results.gamma.trigger)).is_equal("victory")
		assert_str(String(results.gamma.ambition)).is_equal("audacious")
		assert_str(String(results.alpha.ambition)).is_not_equal("audacious")

func test_no_conception_when_hungry_at_war_or_unmoved()->void:
	var engine:=FakeEngine.new()
	Orders.works_engine_override=engine
	_found("alpha")
	WorldSimulation.scoped("alpha",func()->void:
		WorldSimulation.state.elapsed_days=400
		Controller.great_work_orders("alpha",Strategy.preferences(Martial,{"food_days":120}))
		WorldSimulation.military.battle_history.push_front({"day":380,"home_side":"attacker","attacker":{"name":"Host"},"winner":"Host"})
		Controller.great_work_orders("alpha",Strategy.preferences(Martial,{"food_days":5,"food_intake_ratio":.5}))
		Controller.great_work_orders("alpha",Strategy.preferences(Martial,{"food_days":120,"at_war":true})))
	assert_array(engine.commissioned).is_empty()
	assert_bool(WorldSimulation.submit("alpha",{"kind":"great_work_commission","city":"x","ambition":"grand"}).has("error")).is_true()
	Orders.works_engine_override=null
	assert_bool(WorldSimulation.submit("alpha",{"kind":"great_work_policy","city":"nowhere","id":"x","policy":"conjure"}).has("error")).is_true()

func test_real_engine_conceptions_differ_by_ruler()->void:
	var results:Dictionary={}
	for pair in [["alpha",Peaceful],["gamma",Martial],["beta",Cautious]]:
		var id:=String(pair[0])
		_found(id)
		var plan:=Strategy.preferences(pair[1],{"food_days":120})
		WorldSimulation.scoped(id,func()->void:
			var state:=WorldSimulation.state
			state.elapsed_days=400
			state.population_total=900;state.population_exact=900.0
			state.known_discoveries=["clay_shaping","seed_selection","public_stores","framed_construction","joinery","masonry_bond_patterns","seasonal_patterns","tallies","festival_calendar"]
			state.resource_stockpiles.merge(MATERIALS,true)
			state.demographic_ledger.append({"kind":"death","cause":"Illness","count":40,"day":300})
			WorldSimulation.military.battle_history.push_front({"day":380,"home_side":"attacker","attacker":{"name":"Host"},"winner":"Host","target_region_name":"the Ridge"})
			var before:=state.resource_stockpiles.duplicate(true)
			Controller.great_work_orders(id,plan)
			for material:String in before:assert_float(float(state.resource_stockpiles.get(material,0))).is_less_equal(float(before[material]))
			var works:Array=state.player_settlements[0].get("undertakings",[])
			if works.is_empty():
				results[id]={"none":str(WorldSimulation.actors[id].orders).left(400)}
				return
			var r:Dictionary=works[0]
			var concept:Dictionary=r.get("concept",{})
			results[id]={"name":String(r.get("custom_name","")),"purpose":String(concept.get("purpose","")),"form":String(concept.get("form","")),"ambition":String(concept.get("ambition","")),"trigger":String(concept.get("trigger","")),"feasibility":float(r.get("feasibility",-1))})
	print("REAL CONCEPTIONS: ",results)
	for id in ["alpha","gamma"]:assert_bool(results[id].has("name")).override_failure_message(str(results[id])).is_true()
	if results.alpha.has("name") and results.gamma.has("name"):
		assert_str(String(results.alpha.trigger)).is_equal("death")
		assert_str(String(results.gamma.trigger)).is_equal("victory")
		assert_str(String(results.alpha.name)).is_not_equal(String(results.gamma.name))

func test_news_of_conceived_works_names_scale_purpose_and_follies()->void:
	_found("beta")
	var made:Dictionary=WorldSimulation.scoped("beta",func()->Dictionary:
		var state:=WorldSimulation.state
		state.population_total=900;state.population_exact=900.0
		state.known_discoveries=["clay_shaping","joinery","masonry_bond_patterns","seasonal_patterns"]
		var concepts:Variant=Orders.great_works_call("conceive",["beta",{"kind":"victory"}])
		if not concepts is Array or (concepts as Array).is_empty():return {}
		var concept:Dictionary=Orders.great_works_call("retarget",[concepts[0],"audacious"])
		return WorldSimulation.submit("beta",{"kind":"great_work_commission","city":String(state.player_settlements[0].id),"concept":concept,"ambition":"audacious"}))
	assert_bool(made.get("ok",false)).override_failure_message(str(made)).is_true()
	if not made.get("ok",false):return
	var r:Dictionary=WorldSimulation.actors.beta.systems.GameState.player_settlements[0].undertakings[0]
	var beta:=_view("alpha","beta")
	_observe("alpha",beta,.4,50)
	var far:Dictionary=Rivalry.rival_news_for("alpha")[0]
	print("FAR NEWS: ",far.text)
	assert_str(String(far.ambition)).is_equal("audacious")
	assert_str(String(far.title)).is_not_equal(String(r.custom_name))
	_observe("alpha",beta,.8,60)
	var near:Dictionary=Rivalry.rival_news_for("alpha")[0]
	print("NEAR NEWS: ",near.text)
	assert_str(String(near.title)).is_equal(String(r.custom_name))
	assert_str(String(near.purpose)).is_not_empty()
	# A collapse becomes a named folly in the next report.
	r.status="ruined";r.outcome="collapse"
	_observe("alpha",beta,.8,90)
	var folly:Dictionary=Rivalry.rival_news_for("alpha")[0]
	print("FOLLY NEWS: ",folly.text)
	assert_str(String(folly.text)).contains("folly")
