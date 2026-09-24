extends GdUnitTestSuite
const Early=preload("res://scripts/early_practice_knowledge.gd")
const Eras=preload("res://scripts/technology_eras.gd")
const Society=preload("res://scripts/society_model.gd")
const Frontier=preload("res://scripts/discovery_frontier_catalog.gd")
# Consequence hooks that would make an entry a production line, building,
# recipe, operating plant or equipment. Early practices are knowledge only.
const OPERATING_FIELDS:=["production_items","production_contract","operating_plants","inspection_items","building_method","grain_method","meal_preparation","food_batch_method","clothing_method","water_conveyance_method","naval_service_method","repair_method","clinical_care_method","medical_method","doctrine","training_profile","prospecting_profile","agronomy_profile","preservation_profile","nutrient_application"]
const RESEARCH_SPEED:=["knowledge_rate","observation_rate","adoption_rate"]

func before_test()->void:
	WorldSimulation.clear()
	GameState.reset_for_new_world(314159);DiscoverySystem.reset_for_new_world();DiscoverySystem.initialize()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)

func after_test()->void:
	WorldSimulation.clear()
	GameState.set_process(true);CivilizationSystem.set_process(true);MilitaryCampaign.set_process(true)

func test_early_practices_are_knowledge_only_with_bounded_effects()->void:
	var problems:Array[String]=[]
	for entry:Dictionary in Early.entries():
		for field:String in OPERATING_FIELDS:
			if entry.has(field):problems.append("%s has %s" % [entry.id,field])
		var effects:Dictionary=entry.effects
		if effects.is_empty():problems.append("%s has no consequence" % entry.id)
		for key:String in effects:
			if key in RESEARCH_SPEED:problems.append("%s speeds research" % entry.id)
			elif not Society.EFFECT_LIMITS.has(key):problems.append("%s unsupported %s" % [entry.id,key])
			elif absf(float(effects[key]))>0.045:problems.append("%s oversized %s" % [entry.id,key])
	assert_array(problems).is_empty()

func test_early_practices_are_live_unique_and_dated_to_their_age()->void:
	var problems:Array[String]=[]
	var names:Dictionary={}
	for entry:Dictionary in DiscoverySystem.technology_catalog:names[String(entry.name).to_lower()]=int(names.get(String(entry.name).to_lower(),0))+1
	for entry:Dictionary in Early.entries():
		var id:=String(entry.id)
		if DiscoverySystem.discovery_definition(id).is_empty():problems.append(id+" missing from live catalog")
		if int(names.get(String(entry.name).to_lower(),0))!=1:problems.append(id+" duplicate name")
		if not Eras.HISTORICAL_YEAR.has(id):problems.append(id+" undated");continue
		var year:=int(Eras.HISTORICAL_YEAR[id])
		if year<-6500 or year>-2300:problems.append(id+" outside the early window")
		for parent:String in entry.requires:
			if DiscoverySystem.discovery_definition(parent).is_empty():problems.append(id+" unknown foundation "+parent)
			elif int(Eras.HISTORICAL_YEAR.get(parent,99999))>year:problems.append(id+" foundation later than itself: "+parent)
	assert_array(problems).is_empty()

func test_every_research_line_has_work_of_the_first_three_centuries()->void:
	var counts:Dictionary={}
	for entry:Dictionary in DiscoverySystem.technology_catalog:
		var era:=DiscoverySystem.discovery_era(String(entry.id))
		if era>0.0 and era<=300.0:
			var channel:="%s::%s" % [entry.dynamic,entry.subcategory]
			counts[channel]=int(counts.get(channel,0))+1
	var thin:Array[String]=[]
	for domain:String in Frontier.SUBCATEGORIES:
		for line:String in Frontier.SUBCATEGORIES[domain]:
			if int(counts.get("%s::%s" % [domain,line],0))<2:thin.append("%s::%s" % [domain,line])
	assert_array(thin).is_empty()

func test_foundations_form_no_cycles()->void:
	var by_id:Dictionary={}
	for entry:Dictionary in Early.entries():by_id[String(entry.id)]=entry
	var cycles:Array[String]=[]
	for id:String in by_id:
		var seen:Dictionary={}
		var frontier:Array=[id]
		while not frontier.is_empty():
			var current:String=frontier.pop_back()
			for parent:String in (by_id.get(current,{}) as Dictionary).get("requires",[]):
				if parent==id:cycles.append(id)
				elif by_id.has(parent) and not seen.has(parent):seen[parent]=true;frontier.append(parent)
	assert_array(cycles).is_empty()
