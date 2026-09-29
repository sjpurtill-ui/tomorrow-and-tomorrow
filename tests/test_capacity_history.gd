extends GdUnitTestSuite
## The twelve capacities keep a monthly history of how they moved and why,
## read from the one capacity ledger (docs/ADJUDICATION.md): the parts add up
## to the value the people have, every told reason has its sign and size, an
## event is told only for a capacity it feeds, and the record stays small and
## saves with the world. An older save without it loads empty.

const Society:=preload("res://scripts/society_model.gd")
const History:=preload("res://scripts/capacity_history.gd")
const Values:=preload("res://scripts/societal_values_model.gd")
const Words:=preload("res://scripts/hud/capacity_words.gd")

var model:Object
var slot:=""
var _processing:Dictionary={}

func before_test()->void:
	slot="capacity_history_%d_%d" % [OS.get_process_id(),Time.get_ticks_usec()]
	if _processing.is_empty():
		for node:Node in [GameState,CivilizationSystem,MilitaryCampaign,ProgressionSystem]: _processing[node]=node.is_processing()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	WorldSimulation.clear()
	GameState.reset_for_new_world(515151)
	DiscoverySystem.reset_for_new_world();DiscoverySystem.initialize()
	GameState.initialize_population_model();GameState.ensure_population_total(200)
	GameState.housing_capacity=180
	GameState.settlement_completed=["Hearth Circle"]
	# No research emphasis: every practice is worked at its plain level.
	for line in GameState.research_allocations: GameState.research_allocations[line]=0
	GameState.simulation_metrics.merge({"health":0.64,"cohesion":0.61,"legitimacy":0.58,"security":0.36,"ecology":0.84,"knowledge":0.22,
		"material_capacity":0.18,"logistics":0.20,"food_diet_quality":0.48},true)
	GameState.food_security=0.66
	model=DiscoverySystem.society_model

func after_test()->void:
	if slot!="": DirAccess.remove_absolute(SaveSystem.slot_path(slot))
	GameState.elapsed_days=0
	GameState.reset_for_new_world(515151)
	DiscoverySystem.reset_for_new_world()
	for system:Node in [ProgressionSystem,ResourceSystem,FoodSystem,MilitaryCampaign,CivilizationSystem,ForeignDiplomacy,GovernmentPeopleSystem,SettlementModel]: system.reset_for_new_world()
	WorldSimulation.clear()
	for node:Node in _processing: node.set_process(bool(_processing[node]))

## Makes a discovery known at a given level of use, as its registration does.
func _know(id:String,level:float)->Dictionary:
	var definition:=DiscoverySystem.discovery_definition(id)
	assert_dict(definition).override_failure_message("no discovery "+id).is_not_empty()
	if id not in GameState.known_discoveries: GameState.known_discoveries.append(id)
	GameState.discovery_adoption[id]=level
	return definition

## Counts the month's practices and records the month, as process_day does.
func _record(day:int)->void:
	GameState.elapsed_days=day
	model._rebuild_effect_totals(DiscoverySystem.catalog)
	History.record(model,model.capacity_inputs(),day)

func _reason(entry:Dictionary,key:String)->float:
	for reason:Array in entry.reasons:
		if String(reason[0])==key: return float(reason[1])
	return 0.0

## A practice's reason key: its place among the known practices.
func _taken_up(id:String)->String:
	return "d:%d" % GameState.known_discoveries.find(id)

func _learned(id:String)->String:
	return "n:%d" % GameState.known_discoveries.find(id)


# --- One ledger ---------------------------------------------------------------

func test_the_parts_add_up_to_the_values_the_people_have()->void:
	_know("supply_groups",0.4)
	GameState.elapsed_days=0
	model.process_day(DiscoverySystem.catalog,{"food":0.8,"travel":0.3})
	var ledger:Dictionary=model.capacity_ledger()
	for dynamic_id:String in Society.DYNAMICS:
		var row:Dictionary=ledger[dynamic_id]
		var total:=float(row.clamp)
		for part in row.drivers: total+=float(row.drivers[part])
		assert_float(float(row.value)).override_failure_message(dynamic_id).is_equal(float(GameState.society_capacities[dynamic_id]))
		assert_float(total).override_failure_message(dynamic_id).is_equal_approx(float(GameState.society_capacities[dynamic_id]),0.000001)
		# A middling people is held at no limit: the parts alone make the value.
		assert_float(float(row.clamp)).override_failure_message(dynamic_id).is_equal(0.0)
		assert_bool((row.drivers as Dictionary).size()>=3).override_failure_message(dynamic_id).is_true()
	# The clamp is said when it bites: health cannot pass the whole.
	var inputs:Dictionary=model.capacity_inputs()
	inputs["health"]=1.0;inputs["fx:health_protection"]=0.5
	var held:Dictionary=model.capacity_ledger(inputs).health
	assert_float(float(held.value)).is_equal(1.0)
	assert_float(float(held.clamp)).is_less(-0.05)

func test_the_ledger_gives_exactly_the_values_of_the_old_formula()->void:
	_know("supply_groups",0.5);_know("customary_law",0.3);_know("watch_rotation",0.6)
	model._rebuild_effect_totals(DiscoverySystem.catalog)
	var rng:=RandomNumberGenerator.new();rng.seed=4401
	for trial in 24:
		GameState.simulation_metrics.merge({"health":rng.randf(),"cohesion":rng.randf(),"legitimacy":rng.randf(),"security":rng.randf(),"ecology":rng.randf(),
			"knowledge":rng.randf()*1.2,"material_capacity":rng.randf(),"logistics":rng.randf(),"food_diet_quality":rng.randf()},true)
		GameState.food_security=rng.randf()
		GameState.housing_capacity=rng.randi_range(20,400)
		GameState.population_allocations["Administration"]=rng.randi_range(0,30)
		for line in GameState.research_allocations: GameState.research_allocations[line]=rng.randi_range(0,3)
		for key in ["haul_capacity","route_speed","state_capacity","institutional_rigidity","health_protection","labor_demand","fatigue"]: model.effect_totals[key]=rng.randf_range(-0.2,0.6)
		GameState.leadership_positions={"Steward":{"name":"Tova","dynamic_profile":{"demography":rng.randf(),"health":rng.randf(),"labor":rng.randf(),"institutions":rng.randf()},"subcategory_profile":{}}}
		var expected:=_old_capacities()
		var actual:Dictionary=model.evaluate_capacities({})
		for dynamic_id:String in Society.DYNAMICS:
			assert_float(float(actual[dynamic_id])).override_failure_message("%s trial %d" % [dynamic_id,trial]).is_equal(float(expected[dynamic_id]))

## The capacity formulas as they stood before the ledger, kept as an
## independent oracle: the ledger must not have changed any value.
func _old_capacities()->Dictionary:
	var effect:=func(key:String)->float:return float(model.effect_totals.get(key,0.0))
	var metrics:=GameState.simulation_metrics
	var population:=maxf(1.0,GameState.population_exact)
	var able_ratio:=clampf(float(GameState.able_population())/population,0.0,1.0)
	var health:=clampf(float(metrics.get("health",GameState.population_health)),0.0,1.0)
	var food:=clampf(GameState.food_security,0.0,1.0)
	var housing:=clampf(float(GameState.housing_capacity)/population,0.0,1.0)
	var cohesion:=clampf(float(metrics.get("cohesion",0.58)),0.0,1.0)
	var ecology:=clampf(float(metrics.get("ecology",0.88)),0.0,1.0)
	var security:=clampf(float(metrics.get("security",0.38)),0.0,1.0)
	var legitimacy:=clampf(float(metrics.get("legitimacy",0.62)),0.0,1.0)
	var observers:=float(GameState.effective_workers("Knowledge"))
	var active_directions:=0
	for allocation in GameState.research_allocations.values():
		if int(allocation)>0: active_directions+=1
	# Research parity: the keepers a plan asks for are two for each line it
	# follows (Research600.keepers_asked), not the sum of its numbers.
	var inquiry_total:=2.0*float(active_directions)
	var attention_fit:=clampf(observers/maxf(1.0,inquiry_total),0.10,1.0)
	var diversity:=clampf(float(active_directions)/12.0,0.05,1.0)
	var preserved:=clampf(float(metrics.get("knowledge",0.18))+effect.call("knowledge_preservation")*0.55,0.0,1.0)
	var communication:=clampf(0.28+effect.call("route_speed")*0.30+effect.call("standardization")*0.42+effect.call("state_capacity")*0.22,0.10,1.0)
	var institutional_support:=clampf(0.20+float(GameState.population_allocations.get("Administration",0))/maxf(1.0,population*0.06)*0.38+legitimacy*0.22,0.05,1.0)
	var overload:=clampf(maxf(0.0,inquiry_total-observers)/maxf(1.0,observers)*0.22+effect.call("institutional_rigidity")*0.25,0.0,0.55)
	var combined:=clampf((0.18+observers/maxf(1.0,population*0.08)*0.22+health*0.14+preserved*0.17+communication*0.10+institutional_support*0.10+diversity*0.09)*attention_fit*(1.0-overload),0.03,1.0)
	var labor:=clampf(able_ratio*(0.32+health*0.27+food*0.18+cohesion*0.13+housing*0.10)*(1.0+effect.call("labor_efficiency")-effect.call("labor_demand")*0.28-effect.call("fatigue")*0.20),0.08,1.15)
	var result:Dictionary={
		"demography":clampf(health*0.34+food*0.30+housing*0.18+cohesion*0.10+effect.call("maternal_safety")*0.08,0.02,1.0),
		"nutrition":clampf(food*0.72+float(metrics.get("food_diet_quality",0.45))*0.20+effect.call("nutrition_quality")*0.08,0.02,1.0),
		"health":clampf(health+effect.call("health_protection")*0.22-effect.call("disease_exposure")*0.18-effect.call("health_risk")*0.15,0.02,1.0),
		"labor":labor,"knowledge":combined,
		"production":clampf(float(metrics.get("material_capacity",0.12))*0.45+labor*0.30+effect.call("tool_quality")*0.14+effect.call("task_coordination")*0.11,0.02,1.0),
		"infrastructure":clampf(housing*0.38+float(GameState.settlement_completed.size())/10.0*0.32+effect.call("construction_rate")*0.18+effect.call("disaster_resilience")*0.12,0.01,1.0),
		"logistics":clampf(float(metrics.get("logistics",0.16))*0.55+effect.call("haul_capacity")*0.22+effect.call("route_speed")*0.16+effect.call("storage_loss")*-0.07,0.01,1.0),
		"ecology":clampf(ecology+effect.call("ecology_recovery")*0.20-effect.call("ecological_pressure")*0.18-effect.call("pollution")*0.12,0.01,1.0),
		"institutions":clampf(institutional_support+effect.call("state_capacity")*0.22+effect.call("legitimacy")*0.12,0.02,1.0),
		"security":clampf(security+effect.call("security_efficiency")*0.18+effect.call("warfare_readiness")*0.12,0.02,1.0),
		"culture":clampf(cohesion*0.52+legitimacy*0.25+diversity*0.12+effect.call("cohesion")*0.11+preload("res://scripts/artifact_collection.gd").bonus("culture")*.12,0.02,1.0)
	}
	for dynamic_id in result: result[dynamic_id]=clampf(float(result[dynamic_id])+model.leadership_effect(String(dynamic_id)),0.01,1.0)
	for pair in [["institutions","institutions"],["culture","cohesion"],["knowledge","knowledge"],["ecology","ecology"],["security","security"]]:
		result[pair[0]]=clampf(float(result[pair[0]])+Values.simulation_effect(GameState.societal_values,String(pair[1])),0.01,1.0)
	return result


# --- Recording ----------------------------------------------------------------

func test_a_month_is_recorded_as_its_mean_and_the_record_stays_bounded_and_small()->void:
	for day in 61:
		GameState.elapsed_days=day
		model.process_day(DiscoverySystem.catalog,{"food":0.8})
	var history:Dictionary=GameState.capacity_history
	assert_int((history.days as PackedInt32Array).size()).is_equal(3)
	assert_array(Array(history.days as PackedInt32Array)).contains_exactly([0,30,60])
	for dynamic_id:String in Society.DYNAMICS:
		assert_int((history.values[dynamic_id] as PackedByteArray).size()).is_equal(6)
		# A steady month reads as the days it was made of.
		var recorded:=History.months(dynamic_id)
		assert_float(float(recorded[-1].value)).is_equal_approx(float(GameState.society_capacities[dynamic_id])*100.0,0.051)
	# The month's mean is counting again from the day it turned.
	assert_float(float((history.month as Dictionary).get("days",0.0))).is_equal(1.0)
	# A day inside the month records nothing.
	GameState.elapsed_days=70
	model.process_day(DiscoverySystem.catalog,{"food":0.8})
	assert_int((history.days as PackedInt32Array).size()).is_equal(3)
	# Forty years of months at most.
	for month in 520: History.append_month(history,90+month*30,GameState.society_capacities)
	assert_int((history.days as PackedInt32Array).size()).is_equal(History.MONTHS)
	assert_int(int((history.days as PackedInt32Array)[-1])).is_equal(90+519*30)
	for dynamic_id:String in Society.DYNAMICS:
		assert_int((history.values[dynamic_id] as PackedByteArray).size()).is_equal(History.MONTHS*2)
	# The worst the record can hold: every told change and every gathering
	# filled with long names, and a people that knows every practice anyone
	# can research (retired frontier entries cannot be learned).
	var crisis:="the Summer Flux of the ninth long year"
	var decree:="coercive_pronatalism_enforcement"
	for dynamic_id:String in Society.DYNAMICS:
		var told:Array=[]
		for entry in History.KEEP_WHY:
			told.append([100000+entry,99000+entry,512,777,History.MARK_CRISIS,["fx:knowledge_preservation",-12345,"d:10354",23456,"n:10353",3456,"~",-123],["crisis",crisis,12345,"decree",decree,1]])
		history.why[dynamic_id]=told
		var gathered:Dictionary={"fx:knowledge_preservation":0.123456789}
		for index in History.PENDING_REASONS-1: gathered["d:%d" % (10000+index)]=0.123456789
		var events:Array=[]
		for index in History.PENDING_EVENTS: events.append_array(["crisis",crisis,12345])
		history.pending[dynamic_id]={"since":100000,"from":512,"d":0.0123456789,"r":gathered,"e":events}
	var known:Array[String]=[]
	for definition:Dictionary in DiscoverySystem.catalog:
		if not bool(definition.get("frontier",false)): known.append(String(definition.id))
	GameState.known_discoveries.assign(known)
	var inputs:Dictionary=model.capacity_inputs()
	for key in inputs: inputs[key]=0.123456789
	var offices:Dictionary={}
	for office in Society.OFFICE_DYNAMICS: offices[office]="Someone With A Long Name|representative"
	history.last={"day":100000,"inputs":inputs,"basis":model.practice_basis(),"works":40,"offices":offices}
	var size:=var_to_bytes(history).size()
	print("CAPACITY_HISTORY_WORST_CASE_BYTES ",size," known practices ",known.size())
	assert_int(size).is_less(60000)

func test_more_carriers_and_a_practice_taken_up_are_named_with_their_sign_and_size()->void:
	var definition:=_know("supply_groups",0.20)
	var haul:=float(definition.effects.haul_capacity)
	_record(0)
	GameState.simulation_metrics["logistics"]=0.30
	GameState.discovery_adoption["supply_groups"]=0.60
	_record(30)
	var told:=History.changes("logistics")
	assert_int(told.size()).is_equal(1)
	var entry:Dictionary=told[0]
	# More carrying and hauling: 0.10 of the daily reading at 0.55 a point.
	assert_float(_reason(entry,"hauling")).is_equal_approx(5.5,0.011)
	# Supply groups taken up by 40 in 100 more households, through the haul total.
	assert_float(_reason(entry,_taken_up("supply_groups"))).is_equal_approx(0.22*haul*0.40*100.0,0.011)
	assert_float(float(entry.change)).is_equal_approx(5.5+0.22*haul*0.40*100.0,0.011)
	assert_float(float(entry.change)).is_equal_approx(float(entry.to)-float(entry.from),0.1)
	assert_int(int(entry.mark)).is_equal(History.MARK_UP)
	# The same practice's readiness to fight is told for security, and falls
	# the other way nowhere: labor carries only what its demand costs.
	var watch:=History.gathering("security")
	assert_float(float((watch.r as Dictionary).get(_taken_up("supply_groups"),0.0))).is_greater(0.0)
	var labor:=History.gathering("labor")
	assert_float(float((labor.r as Dictionary).get(_taken_up("supply_groups"),0.0))).is_less(0.0)

func test_one_odd_day_inside_a_month_makes_no_mark()->void:
	_record(0)
	# A month of ordinary days, and one very bad one just before it turns.
	for day in range(1,30):
		GameState.elapsed_days=day
		GameState.food_security=0.46 if day==29 else 0.66
		History.observe_day(model.capacity_inputs(),1.0)
	GameState.food_security=0.46
	var odd_day:=Society.capacity_value("nutrition",model.capacity_inputs())
	GameState.food_security=0.66
	_record(30)
	# Read on its last day alone, nutrition would have fallen 14 points.
	assert_float((float(History.months("nutrition")[0].value)-odd_day*100.0)).is_greater(10.0)
	# As the month's mean it moved half a point: no change told, no mark.
	var recorded:=History.months("nutrition")
	assert_float(absf(float(recorded[-1].value)-float(recorded[0].value))).is_less(1.0)
	assert_int(int(recorded[-1].mark)).is_equal(History.MARK_NONE)
	assert_array(History.changes("nutrition")).is_empty()
	var gathered:=History.gathering("nutrition")
	assert_float(float((gathered.r as Dictionary).get("food",0.0))*100.0).is_equal_approx(-0.2*0.72*100.0/29.0,0.01)

func test_a_season_that_comes_round_again_is_drawn_not_told_but_a_raid_is()->void:
	for month in 24:
		GameState.food_security=0.66+0.08*sin(TAU*float(month)/12.0)
		_record(month*30)
	# The first year has nothing to compare with; the second repeats it.
	var told:=History.changes("nutrition",History.KEEP_WHY)
	assert_int(told.size()).is_greater(0)
	for change:Dictionary in told: assert_int(int(change.day)).is_less(360)
	# Raiders in the second winter: told, and so is the way back.
	GameState.food_issue_history.append({"day":24*30-5,"category":"raid_loss","label":"Stores seized after a failed defense","amount":1800.0,"settlement_days":9.0})
	GameState.food_security=0.66+0.08*sin(TAU*24.0/12.0)-0.15
	_record(24*30)
	var raid:Dictionary=History.changes("nutrition")[0]
	assert_int(int(raid.day)).is_equal(24*30)
	assert_int(int(raid.mark)).is_equal(History.MARK_CRISIS)
	# The raid is told over its own month, not over the seasons drawn before it.
	assert_int(int(raid.since)).is_equal(23*30)
	assert_str(Words.change_name(raid)).starts_with("Less food to go round (-")
	GameState.food_security=0.66+0.08*sin(TAU*25.0/12.0)
	_record(25*30)
	var back:Dictionary=History.changes("nutrition")[0]
	assert_int(int(back.day)).is_equal(25*30)
	assert_float(_reason(back,"food")).is_greater(5.0)
	# The seasons after it are drawn again, the raid's season a year on too.
	for month in range(26,41):
		GameState.food_security=0.66+0.08*sin(TAU*float(month)/12.0)
		_record(month*30)
	assert_int(int(History.changes("nutrition")[0].day)).is_equal(25*30)

## Carriers rise each month by a point or so: one line, however long it runs.
func _more_carriers(months:Array)->void:
	for month in months:
		GameState.simulation_metrics["logistics"]=0.20+0.02*float(month)
		_record(int(month)*30)

func test_a_steady_run_is_one_line_until_an_event_or_a_turn_breaks_it()->void:
	_record(0)
	# Six months of more carriers; a new way with routes is learned in the third.
	_more_carriers([1,2])
	var definition:=_know("route_memory",0.25)
	GameState.discovery_log.push_front({"day":80,"id":"route_memory","name":String(definition.name),"effects":definition.effects.duplicate(true)})
	_more_carriers([3,4,5,6])
	var told:=History.changes("logistics")
	assert_int(told.size()).is_equal(1)
	var run:Dictionary=told[0]
	assert_int(int(run.since)).is_equal(0)
	assert_int(int(run.day)).is_equal(180)
	# The run's reasons add up to its change: carriers, and the routes learned.
	var routes:=float(definition.effects.get("route_speed",0.0))*0.25*0.16*100.0
	assert_float(routes).is_greater(0.05)
	assert_float(_reason(run,_learned("route_memory"))).is_equal_approx(routes,0.011)
	assert_float(float(run.change)).is_equal_approx(6.6+routes,0.02)
	assert_float(float(run.change)).is_equal_approx(float(run.to)-float(run.from),0.1)
	assert_float(_reason(run,"hauling")).is_equal_approx(6.6,0.02)
	assert_str(Words.change_name(run)).is_equal("More carrying and hauling: +7 over two seasons")
	assert_str(Words.change_when(run)).is_equal("%s to %s" % [preload("res://scripts/hud/era_words.gd").when(0),preload("res://scripts/hud/era_words.gd").when(180)])
	# The chart marks the run once, where it stands now; the month the new way
	# was learned keeps its gold mark.
	var marks:Array=[]
	for month:Dictionary in History.months("logistics"): marks.append(int(month.mark))
	assert_array(marks).contains_exactly([History.MARK_NONE,History.MARK_NONE,History.MARK_NONE,History.MARK_DISCOVERY,History.MARK_NONE,History.MARK_NONE,History.MARK_UP])
	# A decree for the carriers begins: that month keeps its own line.
	GameState.active_modifiers.append({"id":"carrying_levy","kind":"policy","effects":{"logistics_target":1.0},"magnitude":0.1,"started_day":195.0,"until_day":400.0,"description":"Carriers for the roads"})
	_more_carriers([7,8,9])
	# Then the carriers fall away: a turn starts a new line.
	for month in [10,11]:
		GameState.simulation_metrics["logistics"]=0.38-0.02*float(month-9)
		_record(month*30)
	var names:Array=[]
	for change:Dictionary in History.changes("logistics"): names.append(Words.change_name(change))
	assert_array(names).contains_exactly(["Less carrying and hauling: -2 over a season","More carrying and hauling: +2 over a season","More carrying and hauling (+1)","More carrying and hauling: +7 over two seasons"])
	var decree:Dictionary=History.changes("logistics")[2]
	assert_array(decree.events).contains_exactly([["decree","carrying_levy",1]])
	# On the page: the run's span, and what else moved it.
	var page:Dictionary=Detail.new(null,null,"logistics").tab(0)
	var rows:Array=page.blocks[1].items
	assert_str(String(rows[3].name)).is_equal("More carrying and hauling: +7 over two seasons")
	assert_str(String(rows[3].sub)).contains(" to ")
	assert_str(String(rows[3].detail)).is_equal("Also: Encoded Routes learned (%s)" % Words.points(routes))
	assert_str(String(rows[2].detail)).is_equal("Decree: carrying levy")
	# A long run's many small parts are said together, so the row adds up.
	var page_maker=Detail.new(null,null,"logistics")
	var long_run:={"since":0,"day":2920,"change":14.7,"reasons":[["hauling",11.4],["n:0",0.7],["n:1",0.1],["~",2.5]]}
	assert_str(Words.change_name(long_run)).is_equal("More carrying and hauling: +11 over eight years")
	assert_str(page_maker._also(long_run,Words.named_reasons(long_run))).is_equal("Also: %s learned (+0.7) and many small changes (+3)" % Words.practice_name(GameState.known_discoveries[0]))

func test_a_run_stored_line_by_line_is_folded_when_read()->void:
	_record(0)
	_more_carriers([1,2,3])
	# As the first build stored it: a line and a mark for every month.
	var history:Dictionary=GameState.capacity_history
	var recorded:=History.months("logistics")
	var lines:Array=[]
	for month in range(1,4):
		lines.append([month*30,(month-1)*30,roundi(float(recorded[month-1].value)*10.0),roundi(float(recorded[month].value)*10.0),History.MARK_UP,["hauling",110],[]])
		History._set_mark(history,"logistics",month,History.MARK_UP)
	history.why["logistics"]=lines
	var told:=History.changes("logistics")
	assert_int(told.size()).is_equal(1)
	assert_array(told[0].folded_days).contains_exactly([30,60])
	assert_str(Words.change_name(told[0])).is_equal("More carrying and hauling: +3 over a season")
	var chart:Dictionary=Detail.new(null,null,"logistics").tab(0).blocks[0]
	var marks:Array=[]
	for item:Dictionary in chart.items: marks.append(String(item.marker_type))
	assert_array(marks).contains_exactly(["","","","up"])

func test_a_practice_learned_in_the_month_is_told_as_learned_and_marked_gold()->void:
	_record(0)
	var definition:=_know("supply_groups",0.025)
	GameState.discovery_log.push_front({"day":12,"id":"supply_groups","name":String(definition.name),"effects":definition.effects.duplicate(true)})
	_record(30)
	var gathered:=History.gathering("logistics")
	assert_float(float((gathered.r as Dictionary).get(_learned("supply_groups"),0.0))).is_greater(0.0)
	assert_str(History.practice_id(_learned("supply_groups"))).is_equal("supply_groups")
	var recorded:=History.months("logistics")
	assert_int(int(recorded[-1].mark)).is_equal(History.MARK_DISCOVERY)

func test_an_event_is_told_only_for_a_capacity_it_feeds()->void:
	_record(0)
	# Raiders carry off stores: food supply falls. Carrying work also grows.
	GameState.food_issue_history.append({"day":14,"category":"raid_loss","label":"Stores seized after a failed defense","amount":1800.0,"settlement_days":9.0})
	GameState.food_security=0.50
	GameState.simulation_metrics["logistics"]=0.30
	_record(30)
	var nutrition:Dictionary=History.changes("nutrition")[0]
	assert_array(nutrition.events).contains([["raid",9,0]])
	assert_float(_reason(nutrition,"food")).is_less(-5.0)
	assert_int(int(nutrition.mark)).is_equal(History.MARK_CRISIS)
	var logistics:Dictionary=History.changes("logistics")[0]
	assert_array(logistics.events).is_empty()
	assert_float(_reason(logistics,"food")).is_equal(0.0)

func test_a_new_work_and_a_new_office_holder_are_told_where_they_count()->void:
	_record(0)
	GameState.settlement_completed.append("Granary")
	GameState.leadership_positions={"Marshal":{"name":"Orrin","dynamic_profile":{"security":0.95,"logistics":0.9,"labor":0.9,"institutions":0.9},"subcategory_profile":{}}}
	_record(30)
	var infrastructure:Dictionary=History.changes("infrastructure")[0]
	assert_float(_reason(infrastructure,"works")).is_equal_approx(3.2,0.011)
	assert_array(infrastructure.events).contains([["built","Granary",1]])
	assert_int(int(infrastructure.mark)).is_equal(History.MARK_BUILDING)
	var security:Dictionary=History.changes("security")[0]
	assert_float(_reason(security,"officials")).is_greater(0.0)
	assert_array(security.events).contains([["official","Marshal","Orrin"]])
	# The war leader's office does not carry nutrition, and no work fed it.
	for entry:Dictionary in History.changes("nutrition"):
		assert_array(entry.events).is_empty()


# --- Saves --------------------------------------------------------------------

func _settle_for_saving()->void:
	# Every system on the same world, as a new game starts them.
	ProgressionSystem.reset_for_new_world();ResourceSystem.reset_for_new_world();FoodSystem.reset_for_new_world()
	MilitaryCampaign.reset_for_new_world();CivilizationSystem.reset_for_new_world();ForeignDiplomacy.reset_for_new_world();ForeignDiplomacy.ensure()
	GovernmentPeopleSystem.reset_for_new_world()
	GameState.settlement_site_committed=true;GameState.settlement_name="Ashford"
	SettlementModel.reset_for_new_world();SettlementModel.ensure_founded()

func test_the_history_saves_loads_and_an_older_save_loads_empty()->void:
	_settle_for_saving()
	_know("supply_groups",0.2)
	_record(0)
	GameState.simulation_metrics["logistics"]=0.32
	GameState.discovery_adoption["supply_groups"]=0.5
	_record(30)
	var kept:Dictionary=GameState.capacity_history.duplicate(true)
	assert_int(History.changes("logistics").size()).is_equal(1)
	var saved:=SaveSystem.save_game(slot)
	assert_bool(saved.has("error")).override_failure_message(str(saved)).is_false()
	GameState.capacity_history.clear()
	var loaded:=SaveSystem.load_game(slot)
	assert_bool(loaded.has("error")).override_failure_message(str(loaded)).is_false()
	assert_bool(GameState.capacity_history==kept).override_failure_message(str(GameState.capacity_history.keys())).is_true()
	assert_int(History.changes("logistics").size()).is_equal(1)
	# A save made before the history existed: the field is absent.
	var payload:=SaveSystem._read_payload(slot)
	assert_bool((payload.reflected_GameState as Dictionary).erase("capacity_history")).is_true()
	assert_bool(SaveSystem._write_payload(SaveSystem.slot_path(slot),payload).has("error")).is_false()
	var older:=SaveSystem.load_game(slot)
	assert_bool(older.has("error")).override_failure_message(str(older)).is_false()
	assert_dict(GameState.capacity_history).is_empty()
	assert_int(History.months("logistics").size()).is_equal(1)
	# It starts filling at the next month.
	model=DiscoverySystem.society_model
	_record(60)
	assert_int((GameState.capacity_history.days as PackedInt32Array).size()).is_equal(1)
	_record(90)
	assert_int((GameState.capacity_history.days as PackedInt32Array).size()).is_equal(2)


# --- The screens --------------------------------------------------------------

const Blocks:=preload("res://scripts/hud/dock_blocks.gd")
const Detail:=preload("res://scripts/hud/content/dock_detail_capacity.gd")
const Civilization:=preload("res://scripts/hud/content/dock_content_civilization.gd")
const T:=preload("res://scripts/hud/hud_tokens.gd")

class OpeningHud extends Control:
	signal section_requested(section:String,sub:int)
	var opened:Object
	func open_detail(provider:Object,_sub:int=0)->void:opened=provider
	func request_immediate_dock_refresh()->void:pass

class Terrain extends Node:
	func _dynamic_definition(dynamic_id:String)->String:return "What %s is, in a sentence or two for the tooltip." % dynamic_id

## A few lived months: more carriers, supply groups taken up, raiders.
func _lived_months()->void:
	_know("supply_groups",0.20)
	_record(0)
	GameState.simulation_metrics["logistics"]=0.30
	GameState.discovery_adoption["supply_groups"]=0.60
	GameState.food_issue_history.append({"day":14,"category":"raid_loss","label":"Stores seized after a failed defense","amount":1800.0,"settlement_days":9.0})
	GameState.food_security=0.50
	_record(30)
	GameState.society_capacities=model.evaluate_capacities({})

func _texts(node:Node)->PackedStringArray:
	var out:PackedStringArray=[]
	for child in node.find_children("*","Label",true,false): out.append((child as Label).text)
	return out

func _render(blocks:Array)->VBoxContainer:
	var box:VBoxContainer=auto_free(VBoxContainer.new())
	add_child(box)
	Blocks.render(box,blocks)
	return box

func test_each_strength_carries_its_years_and_opens_its_history()->void:
	_lived_months()
	var hud:=OpeningHud.new();add_child(hud);auto_free(hud)
	var terrain:=Terrain.new();add_child(terrain);auto_free(terrain)
	var content=Civilization.new(terrain,hud)
	var blocks:Array=content._society_blocks(GameState.society_capacities)
	var caps:Dictionary=blocks[0]
	assert_int(int(caps.columns)).is_equal(1)
	assert_int((caps.items as Array).size()).is_equal(12)
	for item:Dictionary in caps.items:
		assert_int((item.history as PackedFloat32Array).size()).is_equal(2)
		assert_bool(item.on_press is Callable).is_true()
		assert_str(String(item.change_text)).is_not_equal("+0.0").is_not_equal("-0.0")
	var box:=_render(blocks)
	var row:Control=box.find_child("CapacityRow_logistics",true,false)
	assert_object(row).is_not_null()
	assert_object(row.find_child("Sparkline",true,false)).is_not_null()
	assert_str(String((row.find_child("Change",true,false) as Label).text)).is_equal("+6")
	var click:=InputEventMouseButton.new();click.button_index=MOUSE_BUTTON_LEFT;click.pressed=true
	row.gui_input.emit(click)
	assert_object(hud.opened).is_not_null()
	assert_str(String(hud.opened.dynamic_id)).is_equal("logistics")
	# Rows without a history keep the old two-column bars.
	var plain:=_render([{"type":"caps","items":[{"name":"Plain","pct":40.0,"trend":"—"}]}])
	assert_object(plain.find_child("CapacityRow_*",true,false)).is_null()
	assert_int((plain.find_children("*","GridContainer",true,false)[0] as GridContainer).columns).is_equal(2)

func test_the_history_page_tells_why_in_short_plain_words()->void:
	_lived_months()
	var terrain:=Terrain.new();add_child(terrain);auto_free(terrain)
	var page=Detail.new(terrain,null,"logistics")
	var data:Dictionary=page.tab(0)
	var types:Array=[]
	for block:Dictionary in data.blocks: types.append(String(block.type))
	assert_array(types).contains_exactly(["line_chart","rows","bars"])
	var why:Dictionary=data.blocks[1]
	var told:Dictionary=why.items[0]
	assert_str(String(told.name)).contains("More carrying and hauling (+6)").contains("Organized Supply Parties taken up (+")
	assert_str(String(told.value)).is_equal("+6")
	assert_str(String(told.tip)).contains("What moved it")
	var chart:Dictionary=data.blocks[0]
	assert_int((chart.items as Array).size()).is_equal(2)
	assert_str(String(chart.items[1].marker_type)).is_equal("up")
	assert_str(String(chart.items[1].marker_label)).contains("More carrying and hauling")
	# What it is made of now adds up to the value the people have.
	var made:Dictionary=data.blocks[2]
	assert_str(String(made.note)).contains(preload("res://scripts/hud/capacity_words.gd").percent(float(GameState.society_capacities.logistics)*100.0))
	var names:Array=[]
	for bar:Dictionary in made.items: names.append(String(bar.name))
	assert_array(names).contains(["Carrying and hauling","Ways of carrying loads"])
	# Nutrition names the raid; logistics does not.
	var nutrition:Dictionary=Detail.new(terrain,null,"nutrition").tab(0)
	assert_str(String(nutrition.blocks[1].items[0].detail)).contains("Raiders carried off 9 days of food")
	assert_str(String(nutrition.blocks[0].items[1].marker_type)).is_equal("crisis")
	for block:Dictionary in data.blocks: assert_str(JSON.stringify(block)).not_contains("Raiders")
	# Every visible label keeps to twelve words and never says +0.0.
	for mode:String in ["light","dark"]:
		T.set_color_mode(mode)
		for dynamic_id:String in Society.DYNAMICS:
			var rendered:=_render(Detail.new(terrain,null,dynamic_id).tab(0).blocks)
			for text:String in _texts(rendered):
				assert_int(text.split(" ",false).size()).override_failure_message("too long: "+text).is_less_equal(12)
				assert_str(text).not_contains("+0.0").not_contains("-0.0")
			# Text reads on the paper it sits on, in both palettes.
			for label:Label in rendered.find_children("*","Label",true,false):
				var ink:=label.get_theme_color("font_color")
				for ground:Color in [T.DOCK_BG,T.ROW_BG,T.TILE_BG]:
					assert_float(T.contrast(ink,ground)).override_failure_message("%s: %s on %s in %s" % [label.text,ink.to_html(false),ground.to_html(false),mode]).is_greater_equal(4.5)
	T.set_color_mode("light")

func test_small_changes_are_told_in_points_never_as_nothing()->void:
	assert_str(Words.points(6.04)).is_equal("+6")
	assert_str(Words.points(-2.6)).is_equal("-3")
	assert_str(Words.points(0.36)).is_equal("+0.4")
	assert_str(Words.points(-0.04)).is_equal("-<0.1")
	assert_str(Words.points(0.0)).is_equal("0")
	assert_str(Words.amount(-0.36)).is_equal("0.4")
	assert_str(Words.reason("upkeep",-1.2)).is_equal("More full-time keepers to feed (-1)")
	assert_str(Words.reason("limit",0.7)).is_equal("Our age allows more (+0.7)")
	assert_str(Words.event(["crisis","the Kintara Fever",12])).is_equal("The Kintara Fever: 12 died")
	assert_str(Words.event(["official","Marshal",""])).is_equal("No war leader now")
	# How long a run took, as the Chronicle counts time.
	assert_str(Words.over(60)).is_equal("over a season")
	assert_str(Words.over(200)).is_equal("over two seasons")
	assert_str(Words.over(400)).is_equal("over a year")
	assert_str(Words.over(1187)).is_equal("over three years")
