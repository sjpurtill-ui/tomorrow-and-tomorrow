extends GdUnitTestSuite
## Everyday knowledge of the age of towns (scripts/town_practice_knowledge.gd):
## knowledge only with small effects a card can show, adopted into the 0-600
## design at their age, dated, painted, and spread so every research line has
## questions of its own age through game years 180-600.
const Town=preload("res://scripts/town_practice_knowledge.gd")
const Eras=preload("res://scripts/technology_eras.gd")
const Society=preload("res://scripts/society_model.gd")
const Catalog=preload("res://scripts/research_600_catalog.gd")
const Frontier=preload("res://scripts/discovery_frontier_catalog.gd")
const Explainer=preload("res://scripts/effect_explainer.gd")
const Art=preload("res://scripts/hud/research_visuals.gd")
# Consequence hooks that would make an entry a production line, building,
# recipe, operating plant or equipment. These practices are knowledge only.
const OPERATING_FIELDS:=["production_items","production_contract","operating_plants","inspection_items","building_method","grain_method","meal_preparation","food_batch_method","clothing_method","water_conveyance_method","naval_service_method","repair_method","clinical_care_method","medical_method","doctrine","training_profile","prospecting_profile","agronomy_profile","preservation_profile","nutrient_application"]
const RESEARCH_SPEED:=["knowledge_rate","observation_rate","adoption_rate","literacy","survey_speed"]
# The lines whose teams ran furthest ahead of their age around year 186.
const SHORT_LINES:=["nutrition","logistics","institutions","culture","demography","security"]

func before_test()->void:
	WorldSimulation.clear()
	GameState.reset_for_new_world(271828);DiscoverySystem.reset_for_new_world();DiscoverySystem.initialize()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)

func after_test()->void:
	GameState.elapsed_days=0
	WorldSimulation.clear()
	GameState.set_process(true);CivilizationSystem.set_process(true);MilitaryCampaign.set_process(true)

func test_town_practices_are_knowledge_only_with_small_effects()->void:
	var problems:Array[String]=[]
	for entry:Dictionary in Town.entries():
		for field:String in OPERATING_FIELDS:
			if entry.has(field):problems.append("%s has %s" % [entry.id,field])
		var effects:Dictionary=entry.effects
		if effects.is_empty():problems.append("%s has no consequence" % entry.id)
		for key:String in effects:
			if key in RESEARCH_SPEED:problems.append("%s speeds research" % entry.id)
			elif not Society.EFFECT_LIMITS.has(key):problems.append("%s unsupported %s" % [entry.id,key])
			elif absf(float(effects[key]))>0.01:problems.append("%s oversized %s" % [entry.id,key])
		# The live entry keeps the authored effects (no Phase 2 row overrides them).
		var live:=DiscoverySystem.discovery_definition(String(entry.id))
		if live.get("effects",{})!=effects:problems.append("%s live effects differ" % entry.id)
	assert_array(problems).is_empty()

func test_every_effect_shows_a_real_number_on_its_card()->void:
	var problems:Array[String]=[]
	var number:=RegEx.create_from_string("[+-][0-9.]+%")
	for entry:Dictionary in Town.entries():
		var effects:Dictionary=entry.effects
		for key:String in effects:
			var said:=Explainer.describe(key,float(effects[key]))
			if bool(said.inert) or bool(said.steer_only):problems.append("%s: %s reads nothing" % [entry.id,key])
			elif (said.feeds as Array).is_empty():problems.append("%s: %s has no reading" % [entry.id,key])
			var amount:=String(said.amount_words)
			if number.search(amount)==null or amount.contains("<"):problems.append("%s: %s shows %s" % [entry.id,key,amount])
		# The card's tooltip: one line per effect with its size and what it moves.
		var lines:=Explainer.effect_lines(effects,1.0,1.0,false).split("\n")
		if lines.size()!=effects.size():problems.append("%s: %d lines for %d effects" % [entry.id,lines.size(),effects.size()])
		for line:String in lines:
			if number.search(line)==null or not " → " in line:problems.append("%s: card line '%s'" % [entry.id,line])
	assert_array(problems).is_empty()

func test_every_town_practice_resolves_to_a_painting()->void:
	var problems:Array[String]=[]
	for entry:Dictionary in Town.entries():
		var id:=String(entry.id)
		for item:Dictionary in [DiscoverySystem.discovery_definition(id),{"id":id}]:
			var path:=Art.subject_art_key(item)
			if path.is_empty():problems.append(id+" has no painting");continue
			if not ResourceLoader.exists(path):problems.append("%s painting missing: %s" % [id,path])
			# A related subject's own painting, not the line's general one.
			if path=="res://assets/ui/research/%s-v1.png" % String(entry.dynamic):problems.append(id+" falls back to its line painting")
		if Art.for_discovery({"id":id})==null:problems.append(id+" painting does not load")
	assert_array(problems).is_empty()

func test_town_practices_are_live_unique_dated_and_adopted_at_their_age()->void:
	var problems:Array[String]=[]
	var names:Dictionary={}
	for entry:Dictionary in DiscoverySystem.technology_catalog:names[String(entry.name).to_lower()]=int(names.get(String(entry.name).to_lower(),0))+1
	for entry:Dictionary in Town.entries():
		var id:=String(entry.id)
		var live:=DiscoverySystem.discovery_definition(id)
		if live.is_empty():problems.append(id+" missing from live catalog");continue
		if int(names.get(String(live.name).to_lower(),0))!=1:problems.append(id+" duplicate name")
		if String(live.subcategory) not in Frontier.SUBCATEGORIES[String(live.dynamic)]:problems.append(id+" has no research channel")
		# A design item of the 0-600 window: it opens at the low edge of its band.
		if not Catalog.has(id) or Catalog.block_of(id)!="y0_600":problems.append(id+" not in the 0-600 design");continue
		var item:=Catalog.item(id)
		var opens:=DiscoverySystem.research_600_earliest_year(live)
		if opens<150.0 or opens>565.0:problems.append("%s opens at %d" % [id,int(opens)])
		if not is_equal_approx(opens,float(item.band_low)):problems.append(id+" does not open at its band")
		if absf(float(live.chance)-Catalog.chance_for(float(item.research_years),float(item.proposed_year)))>0.0000001:problems.append(id+" pace differs from the design")
		if Array(entry.requires)!=Array(item.requires_all):problems.append(id+" foundations differ from the design")
		# Dated on the campaign curve to its design year.
		if not Eras.HISTORICAL_YEAR.has(id):problems.append(id+" undated");continue
		if absf(Eras.game_year_for(float(Eras.HISTORICAL_YEAR[id]))-float(item.proposed_year))>3.0:problems.append(id+" dated away from its design year")
		for parent:String in entry.requires:
			if DiscoverySystem.discovery_definition(parent).is_empty():problems.append(id+" unknown foundation "+parent)
			elif DiscoverySystem.discovery_era(parent)>DiscoverySystem.discovery_era(id):problems.append(id+" foundation later than itself: "+parent)
	assert_array(problems).is_empty()

func test_every_line_and_sub_line_gains_questions_of_its_own_age()->void:
	var by_channel:Dictionary={}
	var early:Dictionary={}
	for entry:Dictionary in Town.entries():
		var opens:=float(Catalog.item(String(entry.id)).band_low)
		var channel:="%s::%s" % [entry.dynamic,entry.subcategory]
		by_channel[channel]=int(by_channel.get(channel,0))+1
		if opens>=180.0 and opens<260.0:early[String(entry.dynamic)]=int(early.get(String(entry.dynamic),0))+1
	var thin:Array[String]=[]
	for domain:String in Frontier.SUBCATEGORIES:
		for line:String in Frontier.SUBCATEGORIES[domain]:
			if int(by_channel.get("%s::%s" % [domain,line],0))<1:thin.append("%s::%s" % [domain,line])
		if int(early.get(domain,0))<1:thin.append(domain+" has nothing of its age in 180-260")
		if domain in SHORT_LINES and int(early.get(domain,0))<5:thin.append(domain+" has fewer than five questions in 180-260")
	assert_array(thin).is_empty()

func test_foundations_form_no_cycles()->void:
	var by_id:Dictionary={}
	for entry:Dictionary in Town.entries():by_id[String(entry.id)]=entry
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
