extends GdUnitTestSuite
## Research's quicker readings answer exactly as the full readings they
## replace: DiscoverySystem scans and seeded tables, the daily loop's shared
## leadership reading, Pathways.multiplier's route terms, the foundations
## planner's index and near-age pass, repeat foundation work, and design
## conditions judged without their reasons. None of it enters a save.
const P=preload("res://scripts/knowledge_pathways.gd")
const R=preload("res://scripts/technology_requirements.gd")
const F=preload("res://scripts/research_foundations.gd")
const Catalog=preload("res://scripts/research_600_catalog.gd")
const Opening=preload("res://scripts/opening_opportunities.gd")
const Probe=preload("res://tools/research/research_600_probe.gd")
const ACTOR:="scan_equivalence"

func before_test()->void:
	WorldSimulation.clear()
	WorldSimulation.create_actor(ACTOR,318)

func after_test()->void:
	WorldSimulation.clear()

## Every question dated before `year`.
func _known_before(discovery:Node,year:float)->Array[String]:
	var ids:Array[String]=[]
	for entry:Dictionary in discovery.technology_catalog:
		if discovery.research_600_earliest_year(entry)<year:ids.append(String(entry.id))
	return ids

## Pathways.chosen() over Pathways.routes_for, as multiplier() read it.
func _chosen_reference(entry:Dictionary,known:Variant,context:Dictionary,source:Dictionary)->Dictionary:
	var result:Dictionary={};var best:=-1.0
	for route:Dictionary in P.routes_for(entry,known,context,source):
		if not bool(route.ready):continue
		var score:=float(route.support)+float(route.progress_multiplier)+(0.05 if route.id=="local" else .1)
		if score>best:result=route;best=score
	return result

## DiscoverySystem._discovery_is_eligible in its original order of checks.
func _eligible_reference(discovery:Node,entry:Dictionary,day:int,known:Variant)->bool:
	var id:=String(entry.get("id",""))
	if id in known or not discovery._path_is_viable(entry):return false
	if not discovery.research_600_open(entry,{},day):return false
	if not Catalog.pursued(id,discovery.society_model.ceiling_era):return false
	return Opening.ready(id) and P.ready_for(entry,known,discovery.latest_context,P.evidence(id)) and discovery._resource_requirements_met(entry.get("resource_requirements",[]))

## research_foundations.recommendation() as one full pass over the catalog.
func _recommendation_reference()->Dictionary:
	var discovery:Node=WorldSimulation.discovery
	var known:Array=WorldSimulation.state.known_discoveries
	var eligible:Dictionary={};var opens:Dictionary={}
	for entry:Dictionary in discovery.technology_catalog:
		if discovery.research_years_ahead(entry)>=discovery.NEAR_AGE_YEARS:continue
		if discovery._discovery_is_eligible(entry,int(WorldSimulation.state.elapsed_days)):eligible[String(entry.id)]=entry
	for child:Dictionary in discovery.technology_catalog:
		if child.id in known or eligible.has(String(child.id)) or not discovery._resource_requirements_met(child.get("resource_requirements",[])):continue
		for route:Dictionary in P.routes(child):
			if String(route.id).begins_with("experimental") and float(route.get("support",0))<.25:continue
			for parent:String in R.parents(route):
				if not eligible.has(parent):continue
				var potential:=known.duplicate();potential.append(parent)
				if not bool(R.evaluate(route,potential).ready):continue
				if not opens.has(parent):opens[parent]=[]
				if child.id not in opens[parent]:opens[parent].append(child.id)
	var best:Dictionary={};var score:=-INF
	for id:String in opens:
		if opens[id].size()<2:continue
		var value:=float(opens[id].size())+clampf(float(WorldSimulation.state.discovery_progress.get(id,0)),0,1)*.5
		if value>score:
			score=value;best={"id":id,"domain":String(eligible[id].dynamic),"opens":opens[id].duplicate(),"reason":"Investigate a foundation shared by several supported questions"}
	return best

func test_daily_leadership_reading_matches_the_full_reading()->void:
	WorldSimulation.scoped(ACTOR,func()->void:
		var discovery:Node=WorldSimulation.discovery
		var offices:Dictionary={}
		var directions:Array=discovery.RESEARCH_OFFICES.keys()
		directions.append("unlisted")
		for direction:String in directions:
			assert_float(discovery._loop_leader_factor(direction,offices)).is_equal(discovery._leader_factor(direction))
	)

func test_route_terms_match_the_chosen_route()->void:
	WorldSimulation.scoped(ACTOR,func()->void:
		var discovery:Node=WorldSimulation.discovery
		var signals:Dictionary={}
		for entry:Dictionary in discovery.technology_catalog:
			for signal_name in entry.get("signals",[]):signals[String(signal_name)]=true
			for route in entry.get("learning_routes",[]):
				for signal_name in (route as Dictionary).get("signals",[]):signals[String(signal_name)]=true
		var busy:Dictionary={};var mixed:Dictionary={}
		var index:=0
		for signal_name:String in signals:
			busy[signal_name]=1.4
			mixed[signal_name]=0.1 if index%2==0 else 0.6
			index+=1
		var sources:Array=[{},{"id":"c1","kind":"specimen","source_name":"Riverfolk","study":1.0},{"id":"c2","kind":"artifact","source_name":"Hill people","study":1.0},{"id":"c3","kind":"artifact","source_name":"Coast","reverse_engineered":true},{"id":"c4","kind":"artifact","source_name":"Guild","research_purchase":true}]
		var catalog:Array=discovery.technology_catalog
		var mismatches:Array=[]
		var chosen:=0
		for known:Variant in [[],R.index_known(_known_before(discovery,150.0)),_known_before(discovery,700.0)]:
			for context:Dictionary in [{},mixed,busy]:
				for source:Dictionary in sources:
					for position in range(0,catalog.size(),4):
						var entry:Dictionary=catalog[position]
						var reference:=_chosen_reference(entry,known,context,source)
						var terms:=P._chosen_terms(entry,known,context,source)
						if reference.is_empty() or terms.is_empty():
							if reference.is_empty()!=terms.is_empty():mismatches.append(String(entry.id))
							continue
						chosen+=1
						var imported:=true if terms.imported else false
						var expected:=true if reference.get("imported",false) else false
						if float(terms.support)!=float(reference.support) or float(terms.progress_multiplier)!=float(reference.progress_multiplier) or imported!=expected:mismatches.append(String(entry.id))
		assert_array(mismatches).is_empty()
		assert_int(chosen).is_greater(1000)
	)

func test_design_condition_answers_match_their_reasons()->void:
	var societies:Array=[{},Probe.permissive_society(),
		{"population":450.0,"settlements":1,"resources":{"Clay":true,"Timber":true},"environment":{"river":true},"institutions":0.3,"contact":false},
		{"population":20000.0,"settlements":3,"resources":{"Stone":true},"environment":{"dry":true},"institutions":0.7,"contact":true}]
	var mismatches:Array=[]
	for id:String in Catalog.ids():
		for society:Dictionary in societies:
			if Catalog.conditions_met(id,society)!=Catalog.unmet_conditions(id,society).is_empty():mismatches.append(id)
	assert_array(mismatches).is_empty()

func test_eligibility_matches_the_original_order_of_checks()->void:
	WorldSimulation.scoped(ACTOR,func()->void:
		var discovery:Node=WorldSimulation.discovery
		var state:Node=WorldSimulation.state
		var mismatches:Array=[]
		for year:float in [0.0,60.0,150.0,400.0]:
			state.known_discoveries.assign(_known_before(discovery,year))
			var day:=int(year*365.0)
			state.elapsed_days=day
			for known:Variant in [state.known_discoveries,R.index_known(state.known_discoveries)]:
				for entry:Dictionary in discovery.technology_catalog:
					if discovery._discovery_is_eligible(entry,day,known)!=_eligible_reference(discovery,entry,day,known):mismatches.append("%s@%d" % [String(entry.id),day])
		assert_array(mismatches).is_empty()
	)

func test_scanned_line_answers_match_unscanned_ones()->void:
	WorldSimulation.scoped(ACTOR,func()->void:
		var discovery:Node=WorldSimulation.discovery
		var state:Node=WorldSimulation.state
		var mismatches:Array=[]
		for year:float in [40.0,150.0]:
			state.known_discoveries.assign(_known_before(discovery,year))
			var day:=int(year*365.0)
			state.elapsed_days=day
			var plain:Dictionary={}
			for channel:String in discovery.catalog_by_channel:
				plain[channel]=[String(discovery._best_candidate_for_channel(channel,day).get("id","")),discovery._channel_has_candidate(channel,day)]
			discovery.begin_research_scan()
			for repeat in 2:
				for channel:String in discovery.catalog_by_channel:
					if String(discovery._best_candidate_for_channel(channel,day).get("id",""))!=String(plain[channel][0]):mismatches.append(channel)
					if discovery._channel_has_candidate(channel,day)!=bool(plain[channel][1]):mismatches.append(channel+" near age")
			discovery.end_research_scan()
			var answered:=0
			for channel:String in plain:
				if String(plain[channel][0])!="":answered+=1
			assert_int(answered).is_greater(5)
		assert_array(mismatches).is_empty()
	)

func test_viable_fields_match_a_plain_pass()->void:
	WorldSimulation.scoped(ACTOR,func()->void:
		var discovery:Node=WorldSimulation.discovery
		var state:Node=WorldSimulation.state
		for year:float in [20.0,150.0]:
			state.known_discoveries.assign(_known_before(discovery,year))
			var day:=int(year*365.0)
			state.elapsed_days=day
			var known:=R.index_known(state.known_discoveries)
			var expected:Dictionary={}
			for entry:Dictionary in discovery.technology_catalog:
				var field:=String(entry.dynamic)
				if expected.has(field):continue
				if discovery._discovery_is_eligible(entry,day,known):expected[field]=true
			assert_int(expected.size()).is_greater(0)
			assert_dict(discovery.viable_fields(day,known)).is_equal(expected)
			discovery.begin_research_scan()
			assert_dict(discovery.viable_fields(day,known)).is_equal(expected)
			assert_dict(discovery.viable_fields(day,known)).is_equal(expected)
			discovery.end_research_scan()
	)

func test_foundations_advice_matches_a_full_pass()->void:
	WorldSimulation.scoped(ACTOR,func()->void:
		var discovery:Node=WorldSimulation.discovery
		var state:Node=WorldSimulation.state
		var advised:=0
		for year:float in [5.0,60.0,150.0,400.0]:
			state.known_discoveries.assign(_known_before(discovery,year))
			state.elapsed_days=int(year*365.0)
			var reference:=_recommendation_reference()
			assert_dict(F.recommendation()).is_equal(reference)
			discovery.begin_research_scan()
			assert_dict(F.recommendation()).is_equal(reference)
			discovery.end_research_scan()
			if not reference.is_empty():advised+=1
		assert_int(advised).is_greater(1)
	)

func test_foundations_advice_reads_every_opening_year_as_a_full_pass_did()->void:
	WorldSimulation.scoped(ACTOR,func()->void:
		var discovery:Node=WorldSimulation.discovery
		discovery._open_year_cache.clear()
		F.recommendation()
		var ids:Array=[]
		for entry:Dictionary in discovery.technology_catalog:
			if not ids.has(String(entry.id)):ids.append(String(entry.id))
		assert_array(discovery._open_year_cache.keys()).is_equal(ids)
	)

## DiscoverySystem._research_600_foundation_ids as one full pass over the
## catalog (without its result cache).
func _foundation_reference(discovery:Node,dynamic_id:String,current_day:int)->Array[String]:
	var known:Dictionary={}
	for id:Variant in WorldSimulation.state.known_discoveries:known[String(id)]=true
	var frontier:Array[String]=[]
	for entry:Dictionary in discovery.technology_catalog:
		if String(entry.get("dynamic",""))!=dynamic_id or known.has(String(entry.get("id",""))):continue
		if discovery.research_600_open(entry,{},current_day,discovery.FOUNDATION_HORIZON_YEARS) and Catalog.pursued(String(entry.get("id","")),discovery.society_model.ceiling_era):frontier.append_array(discovery._research_600_missing_parents(entry,known))
	var found:Dictionary={}
	var visited:Dictionary={}
	var depth:=0
	while not frontier.is_empty() and depth<8:
		var next:Array[String]=[]
		for id:String in frontier:
			if visited.has(id) or known.has(id):continue
			visited[id]=true
			var foundation:Dictionary=discovery.discovery_definition(id)
			if foundation.is_empty() or not discovery.research_600_open(foundation,{},current_day):continue
			if discovery._discovery_is_eligible(foundation,current_day,known):
				# Foundation work keeps near its age (DiscoverySystem.NEAR_AGE_YEARS).
				if discovery.research_years_ahead(foundation,float(current_day)/365.0)<discovery.NEAR_AGE_YEARS:found[id]=discovery.research_open_year(foundation)
			else:next.append_array(discovery._research_600_missing_parents(foundation,known))
		frontier=next
		depth+=1
	var ids:Array[String]=[]
	for id:Variant in found:ids.append(String(id))
	ids.sort_custom(func(a:String,b:String)->bool: return float(found[a])<float(found[b]))
	return ids

func test_repeat_foundation_work_matches_full_passes_and_records_the_same_years()->void:
	var records:Array=[]
	for reference:bool in [true,false]:
		WorldSimulation.clear();WorldSimulation.create_actor(ACTOR,318)
		WorldSimulation.scoped(ACTOR,func()->void:
			var discovery:Node=WorldSimulation.discovery
			var state:Node=WorldSimulation.state
			var results:Array=[]
			for year:float in [60.0,75.0,140.0,260.0]:
				state.known_discoveries.assign(_known_before(discovery,year-40.0))
				var day:=int(year*365.0)
				state.elapsed_days=day
				discovery._research_600_foundation_cache.clear()
				for dynamic:String in discovery.society_model.DYNAMICS:
					results.append(_foundation_reference(discovery,dynamic,day) if reference else discovery._research_600_foundation_ids(dynamic,day))
			records.append([results,discovery._open_year_cache.duplicate()])
		)
	assert_array(records[1][0]).is_equal(records[0][0])
	assert_dict(records[1][1]).is_equal(records[0][1])
	var found:=0
	for ids:Array in records[0][0]:found+=ids.size()
	assert_int(found).is_greater(0)

func test_research_bookkeeping_never_enters_saves()->void:
	WorldSimulation.scoped(ACTOR,func()->void:
		var discovery:Node=WorldSimulation.discovery
		discovery.refresh_investigations()
		var captured:=SaveSystem._capture_reflected(discovery,SaveSystem.REFLECT_SKIP.get("DiscoverySystem",[]))
		assert_bool(captured.has("_scan")).is_false()
		assert_bool(captured.has("_team_memo")).is_false()
		var society:=SaveSystem._capture_reflected(discovery.society_model,SaveSystem.SOCIETY_REFLECT_SKIP)
		for name:String in ["_today","_lower_keys","_tech_keys","_early_keys"]:assert_bool(society.has(name)).is_false()
	)
