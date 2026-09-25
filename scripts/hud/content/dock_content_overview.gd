extends "res://scripts/hud/content/dock_content_base.gd"
const Overview=preload("res://scripts/hud/civilization_overview_model.gd")
const EraWords=preload("res://scripts/hud/era_words.gd")
const People=preload("res://scripts/hud/people_model.gd")
const Buildings=preload("res://scripts/hud/construction_art.gd")
## THE PEOPLE: the god looking down on their people. One living scene (the
## settlement at this hour, a headline and one voice from the fires), the
## faces of named people, the vitals as meters with a trend and a cause, what
## the people are doing now, the season's story and each hearth. Output, lore,
## crafts, buildings, warriors, chiefs and stores stay in the tallies row, one
## click away. Drawn by hud/people_screen.gd; the data is people_model.gd.

func meta()->Dictionary:
	if EraWords.reckoned():return {"eyebrow":"CIVILIZATION · ALL SETTLEMENTS","title":"The People","subtabs":["OVERVIEW"]}
	return {"eyebrow":"THE PEOPLE · ALL OUR %s" % EraWords.word("places","hearths").to_upper(),"title":"The People","subtabs":["THE PEOPLE"]}

func tab(_sub:int)->Dictionary:
	var report:=Overview.snapshot()
	var modern:=EraWords.reckoned()
	var hearth:=EraWords.hearth()
	var totals:Dictionary=preload("res://scripts/hud/civilization_kpi_model.gd").snapshot()
	var celsius:=NAN
	if terrain!=null and is_instance_valid(terrain) and terrain.has_method("site_temperature_c"):celsius=float(terrain.site_temperature_c())
	var primary:=""
	for city in GameState.player_settlements:
		if bool((city as Dictionary).get("primary",false)):primary=String(city.id)
	var faces:=People.faces(primary)
	var scene:={"season":People.weather_line(celsius),"register":EraWords.register(),"headline":People.headline(report,totals),"voice":People.voice(faces),"hearth":hearth}
	var profile:Dictionary=CivilizationSystem.player_population_function_profile() if CivilizationSystem.has_method("player_population_function_profile") else {}
	var productive:=int(profile.get("productive",roundi(float(GameState.population_total)*0.6)))
	var tasks:=People.labor(productive)
	var most:=1
	for task:Dictionary in tasks:most=maxi(most,int(task.count))
	var labor:={"heading":"WHAT THE PEOPLE ARE DOING TODAY" if hearth else ("TODAY'S LABOUR, FROM THE ROLLS" if not modern else "LABOR FORCE BY TASK"),
		"tasks":tasks,"per_figure":maxi(1,ceili(float(most)/float(People.FIGURES_MAX))),
		"note":"%s can work; the rest are small children, the old and the sick." % EraWords.count_word(productive).capitalize() if hearth else "%s of working age at work." % EraWords.grouped(productive)}
	var story:={"heading":"TOLD THIS SEASON" if hearth else "THE SEASON'S ANNALS","items":People.story(4),"link":"The whole Chronicle","on_open":jump("chronicle",0)}
	var hearths:Array=[]
	for city:Dictionary in report.cities:
		var id:=String(city.id)
		var issue:="Occupied" if city.occupied else ", ".join(city.issues)
		var pending:bool=city.food<0 or city.water_met<0
		var art:=0
		for work in ["Framed Hall","Public Stores","Gathering Yard","Storage Pits","Lean-to Shelters"]:
			if GameState.settlement_completed.has(work):art=Buildings.building(work);break
		hearths.append({"id":id,"name":String(city.name),"sub":("%s · %s" % [EraWords.people(int(city.population)),"first hearth" if hearth else "founding settlement"]) if city.primary else EraWords.people(int(city.population)),
			"needs":People.needs_words(city),"status":issue if not issue.is_empty() else "Reports pending" if pending else "Basic needs met",
			"attention":not issue.is_empty(),"art":art,"tip":"Open this %s: its leader, buildings and story" % EraWords.word("place","hearth"),"on_click":open_city.bind(id)})
	var hearth_actions:Array=[]
	if hearths.is_empty():hearth_actions.append({"label":"Choose a home","sub":"Choose a home and establish your first settlement","on_press":jump("settlement",0)})
	var tallies:Array=[{"label":"Food & water","on_press":jump("economy",0)},{"label":EraWords.word("rail.wealth","Wealth"),"on_press":jump("economy",2)},{"label":EraWords.word("rail.inquiry","Research"),"on_press":jump("inquiry",0)},{"label":EraWords.word("rail.production","Production"),"on_press":jump("production",0)},{"label":"Buildings","on_press":jump("construction",0)},{"label":EraWords.word("rail.government","Government"),"on_press":jump("government",0)}]
	var block:={"type":"people","scene":scene,"faces":faces,"vitals":People.vitals(report,totals),"labor":labor,"story":story,"hearths":hearths,"hearth_actions":hearth_actions,"tallies":tallies,
		"vitals_heading":"HOW THEY FARE" if not modern else "VITAL STATISTICS","hearths_heading":("OUR %s" % EraWords.word("places","hearths").to_upper()) if not modern else "CITIES & SETTLEMENTS",
		"hearths_note":"the neediest first" if hearths.size()>1 else "","tallies_heading":EraWords.word("rail.drawer","Ledgers").to_upper(),"on_summon":summon}
	return {"blocks":[block]}

func summon(target:Dictionary)->void:
	court(target).call()

func open_city(id:String)->void:
	if SettlementModel.select_settlement(id).get("ok",false):hud.section_requested.emit("settlement",0)

static func metric(label:String,value:String,note:String)->Dictionary:
	return {"label":label,"value":value,"note":note}

static func days(value:float)->String:
	return EraWords.days(value) if value>=0 else "Report pending"

func signature()->Array:
	return [floori(GameState.elapsed_days),GameState.population_total,GameState.settlement_network_revision,GameState.morphology_revision,GovernmentPeopleSystem.revision,MilitaryCampaign.equipment_queue.hash(),GameState.simulation_metrics.hash(),GameState.water_metrics.hash()]

static func percent(total:float,population:int)->String:
	return "%d%%"%roundi(total/population*100) if population>0 else "Report pending"
