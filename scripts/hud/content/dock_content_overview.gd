extends "res://scripts/hud/content/dock_content_base.gd"
const Overview=preload("res://scripts/hud/civilization_overview_model.gd")
const EraWords=preload("res://scripts/hud/era_words.gd")
## THE PEOPLE: six plain answers (how many, how fed, how watered, how
## sheltered, how long they live, how they hold together), then each hearth.
## Output, lore, crafts, buildings, warriors, chiefs and stores live in the
## ledgers drawer, one click away.

func meta()->Dictionary:
	if EraWords.reckoned():return {"eyebrow":"CIVILIZATION · ALL SETTLEMENTS","title":"The People","subtabs":["OVERVIEW"]}
	return {"eyebrow":"THE PEOPLE · ALL OUR %s" % EraWords.word("places","hearths").to_upper(),"title":"The People","subtabs":["THE PEOPLE"]}

func tab(_sub:int)->Dictionary:
	var report:=Overview.snapshot()
	var modern:=EraWords.reckoned()
	var totals:Dictionary=preload("res://scripts/hud/civilization_kpi_model.gd").snapshot()
	var fed:=EraWords.fed(int(totals.population),float(totals.food_eaten),float(totals.food_need))
	var cohesion:float=float(report.cohesion)/float(report.cohesion_population) if int(report.cohesion_population)>0 else -1.0
	var legitimacy:float=float(report.legitimacy)/float(report.legitimacy_population) if int(report.legitimacy_population)>0 else -1.0
	var spirit:="Report pending" if cohesion<0 else EraWords.spirit(cohesion)
	var trust_note:="Trust in the chiefs: "+(EraWords.trust(legitimacy) if legitimacy>=0 else "not yet told")
	var tiles:Array=[
		metric("THE PEOPLE" if not modern else "POPULATION",EraWords.people(int(report.population)) if not modern else str(report.population),("%s fed in full today" % ("%d of %d" % [fed,int(totals.population)] if fed>=0 else "none yet counted")) if not modern else "Across the civilization · %s" % EraWords.places(report.cities.size())),
		metric("STORES OF FOOD" if not modern else "FOOD RESERVE",days(report.food_min),"At today's eating, at the neediest %s" % EraWords.word("place","hearth") if not report.cities.is_empty() else "Carried by the traveling people"),
		metric("WATER" if not modern else "WATER RESERVE",days(report.water_min),"At today's drinking, at the neediest %s" % EraWords.word("place","hearth") if not report.cities.is_empty() else "Carried by the traveling people"),
		metric("SHELTER","%d of %d" % [report.sheltered,report.residents] if not modern else "%d / %d"%[report.sheltered,report.residents],"Under a roof tonight · room for %d" % report.places),
		metric("HOW LONG WE LIVE" if not modern else "LIFE EXPECTANCY",EraWords.life(float(report.life)) if report.residents>0 else "Awaiting settlement",EraWords.babes_lost_sentence(float(totals.infant)) if report.residents>0 else "Told once the people settle"),
		metric("SPIRIT" if not modern else "COHESION",spirit,trust_note if not modern else "Legitimacy %s" % percent(report.legitimacy,report.legitimacy_population))]
	var rows:Array=[]
	for city:Dictionary in report.cities:
		var id:=String(city.id)
		var issue:="Occupied" if city.occupied else ", ".join(city.issues)
		var pending:bool=city.food<0 or city.water_met<0
		rows.append({"name":String(city.name)+(" · Founding settlement" if city.primary else ""),"sub":"%d residents   ·   Food %s   ·   Water %s   ·   Shelter %d / %d"%[city.population,days(city.food),"%d%% met"%roundi(city.water_met*100) if city.water_met>=0 else "report pending",mini(city.places,city.population),city.population],"value":issue if not issue.is_empty() else "Reports pending" if pending else "Basic needs met","accent":Tokens.AMBER if not issue.is_empty() else Tokens.GREEN,"value_color":Tokens.INK,"tip":"Open this settlement’s overview and history","on_click":open_city.bind(id)})
	var places_heading:=("OUR %s" % EraWords.word("places","hearths").to_upper()) if not modern else "CITIES & SETTLEMENTS"
	var blocks:Array=[{"type":"tiles","heading":"AT A GLANCE","columns":3,"items":tiles},{"type":"rows","heading":places_heading,"note":"Click one for its chiefs, buildings and story · the neediest first","items":rows}]
	if rows.is_empty():blocks.append({"type":"actions","items":[{"label":"FOUNDING & TRAVEL","sub":"Choose a home and establish your first settlement","on_press":jump("settlement",0)}]})
	blocks.append({"type":"actions","heading":"THE %s" % EraWords.word("rail.drawer","Ledgers").to_upper(),"items":[{"label":"FOOD & WATER","on_press":jump("economy",0)},{"label":EraWords.word("rail.wealth","Wealth").to_upper(),"on_press":jump("economy",2)},{"label":EraWords.word("rail.inquiry","Research").to_upper(),"on_press":jump("inquiry",0)},{"label":EraWords.word("rail.production","Production").to_upper(),"on_press":jump("production",0)},{"label":"BUILDINGS","on_press":jump("construction",0)},{"label":EraWords.word("rail.government","Government").to_upper(),"on_press":jump("government",0)}]})
	return {"blocks":blocks}

func open_city(id:String)->void:
	if SettlementModel.select_settlement(id).get("ok",false):hud.section_requested.emit("settlement",0)

static func metric(label:String,value:String,note:String)->Dictionary:
	return {"label":label,"value":value,"note":note}

static func days(value:float)->String:
	return EraWords.days(value) if value>=0 else "Report pending"

func signature()->Array:
	return [GameState.elapsed_days,GameState.population_total,GameState.settlement_network_revision,GameState.morphology_revision,GovernmentPeopleSystem.revision,MilitaryCampaign.equipment_queue.hash(),GameState.simulation_metrics.hash(),GameState.water_metrics.hash()]

static func percent(total:float,population:int)->String:
	return "%d%%"%roundi(total/population*100) if population>0 else "Report pending"
