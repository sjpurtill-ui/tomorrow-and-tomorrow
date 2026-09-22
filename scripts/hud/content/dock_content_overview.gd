extends "res://scripts/hud/content/dock_content_base.gd"
const Overview=preload("res://scripts/hud/civilization_overview_model.gd")

func meta()->Dictionary:
	return {"eyebrow":"CIVILIZATION · ALL SETTLEMENTS","title":"Civilization overview","subtabs":["OVERVIEW"]}

func tab(_sub:int)->Dictionary:
	var report:=Overview.snapshot()
	var active:=0;var waiting:=0
	for job:Dictionary in MilitaryCampaign.equipment_queue:
		if MilitaryCampaign.PersistentProduction.eligible(MilitaryCampaign,job):active+=1
		elif not bool(job.get("paused",false)):waiting+=1
	var offices:=GovernmentPeopleSystem.active_offices()
	var filled:=0
	for office:Dictionary in offices:
		if not GovernmentPeopleSystem.officeholder(String(office.key)).is_empty():filled+=1
	var tiles:Array=[
		metric("POPULATION",str(report.population),"Across the civilization"),
		metric("SETTLEMENTS",str(report.cities.size()),"%d need attention"%report.attention),
		metric("FOOD RESERVE",days(report.food_min),"Lowest reported city reserve" if not report.cities.is_empty() else "Traveling community reserve"),
		metric("WATER RESERVE",days(report.water_min),"Lowest reported city reserve" if not report.cities.is_empty() else "Traveling community reserve"),
		metric("SHELTER","%d / %d"%[report.sheltered,report.residents],"Residents covered locally · %d total places"%report.places),
		metric("LIFE EXPECTANCY","%.1f years"%report.life if report.residents>0 else "Awaiting settlement","Population-weighted across controlled cities"),
		metric("ECONOMIC OUTPUT","%.1f / day"%report.output,"Real output index · all controlled cities"),
		metric("SCIENCE","%.1f"%report.science,"Effective research capacity · %d known practices"%GameState.known_discoveries.size()),
		metric("PRODUCTION","%d working"%active,"%d other unpaused orders"%waiting),
		metric("CONSTRUCTION","%d underway"%report.building,"%d communal works completed"%report.works),
		metric("MILITARY","%d serving"%MilitaryCampaign._mobilized_count(),"Across reserves and field forces"),
		metric("GOVERNMENT","%d / %d"%[filled,offices.size()],"Civic offices filled"),
		metric("MATERIAL STORES","%.1f timber · %.1f stone"%[report.materials.get("Timber",0),report.materials.get("Stone",0)],"Clay %.1f · Plant fiber %.1f · stored across cities"%[report.materials.get("Clay",0),report.materials.get("Fiber Plants",0)]),
		metric("COHESION",percent(report.cohesion,report.cohesion_population),"Weighted by population with a current report"),
		metric("LEGITIMACY",percent(report.legitimacy,report.legitimacy_population),"Confidence in authority · reported population")]
	var rows:Array=[]
	for city:Dictionary in report.cities:
		var id:=String(city.id)
		var issue:="Occupied" if city.occupied else ", ".join(city.issues)
		var pending:bool=city.food<0 or city.water_met<0
		rows.append({"name":String(city.name)+(" · Founding settlement" if city.primary else ""),"sub":"%d residents   ·   Food %s   ·   Water %s   ·   Shelter %d / %d"%[city.population,days(city.food),"%d%% met"%roundi(city.water_met*100) if city.water_met>=0 else "report pending",mini(city.places,city.population),city.population],"value":issue if not issue.is_empty() else "Reports pending" if pending else "Basic needs met","accent":Tokens.AMBER if not issue.is_empty() else Tokens.GREEN,"value_color":Tokens.INK,"tip":"Open this settlement’s overview and history","on_click":open_city.bind(id)})
	var blocks:Array=[{"type":"tiles","heading":"AT A GLANCE","columns":3,"items":tiles},{"type":"rows","heading":"CITIES & SETTLEMENTS","note":"Click a city for local leadership, buildings and history · shortages first","items":rows}]
	if rows.is_empty():blocks.append({"type":"actions","items":[{"label":"FOUNDING & TRAVEL","sub":"Choose a home and establish your first settlement","on_press":jump("settlement",0)}]})
	blocks.append({"type":"actions","heading":"EXPLORE THE DETAILS","items":[{"label":"PROVISIONS","on_press":jump("economy",0)},{"label":"WEALTH","on_press":jump("economy",2)},{"label":"RESEARCH","on_press":jump("inquiry",0)},{"label":"PRODUCTION","on_press":jump("production",0)},{"label":"BUILDINGS","on_press":jump("construction",0)},{"label":"GOVERNMENT","on_press":jump("government",0)}]})
	return {"blocks":blocks}

func open_city(id:String)->void:
	if SettlementModel.select_settlement(id).get("ok",false):hud.section_requested.emit("settlement",0)

static func metric(label:String,value:String,note:String)->Dictionary:
	return {"label":label,"value":value,"note":note}

static func days(value:float)->String:
	return "%.1f days"%value if value>=0 else "Report pending"

func signature()->Array:
	return [GameState.elapsed_days,GameState.population_total,GameState.settlement_network_revision,GameState.morphology_revision,GovernmentPeopleSystem.revision,MilitaryCampaign.equipment_queue.hash(),GameState.simulation_metrics.hash(),GameState.water_metrics.hash()]

static func percent(total:float,population:int)->String:
	return "%d%%"%roundi(total/population*100) if population>0 else "Report pending"
