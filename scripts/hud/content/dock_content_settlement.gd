extends "res://scripts/hud/content/dock_content_base.gd"
## SETTLEMENT section: People & Labor / Works & Defense / History.
## Replaces the settlement dashboard, the settler side panel, and the
## population ledger summary.

const COHORT_LABELS:Array[Array]=[["children","0–4","Dependent cohort"],["youth","5–14","Partly productive"],["early_adults","15–29","Productive-age cohort"],["established_adults","30–44","Productive-age cohort"],["mature_adults","45–59","Productive-age cohort"],["elders","60+","Dependent cohort"]]
const ROLES:Array[Array]=[
	["Food","Sustenance","Produces food immediately. Heavy local gathering can exhaust the surrounding ecology."],
	["Survey","Survey","Creates clues, recognizes deposits, measures quality."],
	["Extraction","Gatherers","Works accessible timber, stone, clay, fiber, and later deposits."],
	["Construction","Builders","Causes needed communal works and access routes to emerge."],
	["Crafting","Makers","Improves tools and material capacity."],
	["Logistics","Carriers","Moves food and materials; determines whether distant resources are usable."],
	["Knowledge","Researchers","Aggregate research workforce; distribution across inquiry decides the path."],
	["Administration","Stewards","Coordinates labor and reserves; strengthens cohesion and legitimacy."],
	["Defense","Watch","Raises security and readiness; every watcher is absent from other work."],
]

func meta()->Dictionary:
	return {
		"eyebrow":"SETTLEMENT · POP %d" % GameState.population_total,
		"title":terrain._settlement_display_name().capitalize(),
		"subtabs":["PEOPLE & LABOR","WORKS & DEFENSE","HISTORY"],
	}

func tab(sub:int)->Dictionary:
	var metrics:Dictionary=GameState.simulation_metrics
	var profile:Dictionary=CivilizationSystem.player_population_function_profile()
	var health:=roundi(GameState.population_health*100.0)
	var productive:=int(profile.get("productive",terrain._able_population()))
	var efficiency:=roundi(float(metrics.get("labor_efficiency",0.0))*100.0)
	var births:=roundi(float(metrics.get("births_expected_next_year",0.0)))
	var kpis:Array=[
		{"label":"POPULATION","value":str(GameState.population_total),"delta":"+%d /yr" % births if births>0 else "—","delta_color":Tokens.GREEN if births>0 else Tokens.MUTED,"accent":Tokens.GREEN,"tip":"Six aging cohorts"},
		{"label":"HEALTH","value":"%d%%" % health,"delta":"","accent":Tokens.TEAL,"tip":"Physical condition and freedom from preventable harm"},
		{"label":"PRODUCTIVE","value":str(productive),"delta":"of %d" % GameState.population_total,"accent":Tokens.GREEN,"tip":"Productive-age cohort"},
		{"label":"LABOR EFF.","value":"%d%%" % efficiency,"delta":"","accent":Tokens.AMBER,"tip":"Effective work per assigned person"},
	]
	var conditions:={"health":GameState.population_health,"housing_ratio":float(metrics.get("housing_ratio",1.0))}
	var raw_brief:Dictionary=terrain._population_attention_brief(profile,conditions)
	var status:=String(raw_brief.get("status",""))
	var tone:="info" if "SUSTAINABLE" in status else ("danger" if "HEALTH" in status else "warn")
	var brief:=adapt_brief(raw_brief,tone,"OPEN ECONOMY" if "Provisions" in String(raw_brief.get("next","")) else "",jump("economy",0))
	match sub:
		1: return {"kpis":kpis,"brief":brief,"blocks":_works_blocks(metrics,profile)}
		2: return {"kpis":kpis,"brief":brief,"blocks":_history_blocks(metrics)}
	return {"kpis":kpis,"brief":brief,"blocks":_people_blocks(int(terrain._able_population()))}

func _people_blocks(productive:int)->Array:
	var cohorts:Dictionary=GameState._integer_age_cohorts()
	var segment_items:Array=[]
	var dependents:=0
	for entry in COHORT_LABELS:
		var count:=int(cohorts.get(String(entry[0]),0))
		if String(entry[0]) in ["children","elders"]: dependents+=count
		segment_items.append({"label":String(entry[1]),"value":str(count),"share":maxf(0.5,float(count)),"color":Tokens.COHORT_COLORS[COHORT_LABELS.find(entry)],"tip":String(entry[2])})
	var dependency:=float(dependents)/maxf(1.0,float(GameState.population_total-dependents))
	var alloc_items:Array=[]
	var assigned:=0
	for index in ROLES.size():
		var role:Array=ROLES[index]
		var key:=String(role[0])
		var count:=int(GameState.population_allocations.get(key,0))
		assigned+=count
		alloc_items.append({
			"name":String(role[1]),"count":count,
			"pct":"%d%%" % roundi(float(count)/maxf(1.0,float(productive))*100.0),
			"color":Tokens.ROLE_COLORS[index],"tip":String(role[2]),
			"on_minus":terrain._change_population_allocation.bind(key,-2),
			"on_plus":terrain._change_population_allocation.bind(key,2),
		})
	return [
		{"type":"segments","heading":"AGE STRUCTURE","note":"dependency %.2f" % dependency,"items":segment_items,"legend":"Green = productive-age • warm/grey = dependent"},
		{"type":"alloc","heading":"LABOR ALLOCATION","note":"%d of %d assigned" % [assigned,productive],"items":alloc_items},
		{"type":"text","text":"Shares persist as population changes. Unassigned people rest and recover health."},
	]

func _works_blocks(metrics:Dictionary,profile:Dictionary)->Array:
	var defense:Dictionary=MilitaryCampaign.settlement_defense_snapshot()
	var housing:=roundi(float(metrics.get("housing_ratio",1.0))*100.0)
	var builders:=int(GameState.population_allocations.get("Construction",0))
	var works:=GameState.settlement_completed.size()
	var absent:=int(profile.get("absent",0))
	var mobilized:=int(profile.get("mobilized",0))
	var works_text:="No permanent works have emerged. Builders create shelter and access routes as need accumulates; nothing is placed by hand."
	if works>0:
		works_text="Completed works: %s." % ", ".join(GameState.settlement_completed)
	return [
		{"type":"tiles","heading":"LOCAL CONDITION","items":[
			{"label":"HOUSING","value":"%d%%" % housing,"note":"Shelter covers everyone" if housing>=100 else "Shelter is short","note_color":Tokens.GREEN if housing>=100 else Tokens.RED,"tip":"Share of the population with shelter"},
			{"label":"DEFENSE","value":String(defense.get("short","Open ground")),"note":"integrity %d%% · lookout %.0f km" % [roundi(float(defense.get("integrity",0.0))*100.0),float(defense.get("observation_radius_km",0.0))],"note_color":Tokens.RED if float(defense.get("integrity",0.0))<0.4 else Tokens.MUTED,"tip":String(defense.get("description",""))},
			{"label":"CONSTRUCTION","value":"%d builders" % builders,"note":"%d works completed" % works,"note_color":Tokens.MUTED,"tip":"Assigned Builders and emerged communal works"},
			{"label":"COMMITMENTS","value":"%d away" % absent,"note":"%d mobilized" % mobilized,"note_color":Tokens.MUTED,"tip":"People physically away on missions or under arms"},
		]},
		{"type":"text","heading":"EMERGING WORKS","text":works_text},
	]

func _history_blocks(metrics:Dictionary)->Array:
	var pregnancy:Dictionary=GameState.pregnancy_summary()
	var births:=GameState.lifetime_births
	var deaths:=GameState.lifetime_deaths
	var net:=births-deaths
	var chronicle_items:Array=[]
	var log:Array=GameState.discovery_log
	for index in range(log.size()-1,maxi(-1,log.size()-4),-1):
		var event:Dictionary=log[index]
		chronicle_items.append({
			"name":String(event.get("name",event.get("title","Event"))),
			"sub":"Day %d" % int(event.get("day",0)),
			"value":"","accent":Tokens.AMBER,
			"tip":String(event.get("causal_mechanism","")),
		})
	var blocks:Array=[
		{"type":"tiles","heading":"SINCE FOUNDING","items":[
			{"label":"BIRTHS","value":str(births),"note":"%d pregnancies active" % int(pregnancy.get("active",0)),"note_color":Tokens.GREEN,"tip":"Total births since the expedition began"},
			{"label":"DEATHS","value":str(deaths),"note":"all causes","note_color":Tokens.RED if deaths>0 else Tokens.MUTED,"tip":"Total deaths since the expedition began"},
			{"label":"NET","value":"%+d" % net,"note":"births − deaths","note_color":Tokens.GREEN if net>=0 else Tokens.RED,"tip":"Natural change since founding"},
			{"label":"LIFE EXPECT.","value":"%.1f y" % GameState.projected_life_expectancy(),"note":"projected at birth","note_color":Tokens.MUTED,"tip":"Projected life expectancy under current conditions"},
		]},
	]
	if not chronicle_items.is_empty():
		blocks.append({"type":"rows","heading":"CHRONICLE","items":chronicle_items})
	else:
		blocks.append({"type":"text","heading":"CHRONICLE","text":"Nothing notable has been recorded yet. Events accumulate here as the settlement lives."})
	blocks.append({"type":"actions","items":[{
		"label":"FULL LEDGER","sub":"births, deaths, causes, maternity","primary":true,
		"on_press":func()->void: hud.open_detail(preload("res://scripts/hud/content/dock_detail_population_ledger.gd").new(terrain,hud)),
		"tip":"Open the complete population record beside this panel",
	}]})
	return blocks

func signature()->Array:
	return [GameState.population_total,GameState.population_health,GameState.population_allocations.duplicate(),GameState.lifetime_births,GameState.lifetime_deaths,GameState.settlement_completed.size()]
