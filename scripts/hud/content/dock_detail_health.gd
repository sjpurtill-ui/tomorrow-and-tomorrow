extends "res://scripts/hud/content/dock_content_base.gd"
const Indicators:=preload("res://scripts/civilization_indicators.gd")
const EarlyCare:=preload("res://scripts/early_life_conditions.gd")
const EraWords:=preload("res://scripts/hud/era_words.gd")
## Dedicated health and longevity view opened directly from the HEALTH KPI.

func meta()->Dictionary:
	if not EraWords.reckoned():return {"eyebrow":"THE PEOPLE · LIFE & DEATH","title":"How long we live","subtabs":["LIVES"]}
	return {
		"eyebrow":"POPULATION · HEALTH & SURVIVAL",
		"title":"Health & Life Expectancy",
		"subtabs":["LONGEVITY"],
	}

func tab(_sub:int)->Dictionary:
	return SettlementModel.with_city_resources(GameState.selected_player_settlement_id,func()->Dictionary:return SettlementModel.with_local_population(_city_health))

func _city_health()->Dictionary:
	var expectancy:=GameState.projected_life_expectancy()
	var history:Array[Dictionary]=GameState.health_history_snapshot()
	var prior:=expectancy
	if history.size()>1: prior=float(history[-2].get("life_expectancy",expectancy))
	var expectancy_delta:=expectancy-prior
	var vital:Dictionary=GameState.rolling_vital_balance(365)
	var profile:Dictionary=GameState.population_age_profile()
	var observed_age:=float(profile.get("observed_age_at_death",-1.0))
	var water_intake:=roundi(float(GameState.water_metrics.get("intake_ratio",1.0))*100.0)
	var housing:=roundi(float(GameState.simulation_metrics.get("housing_ratio",1.0))*100.0)
	var infant_mortality:=Indicators.infant_mortality_per_1000()
	var kpis:Array=[
		{"label":"LIFE EXPECTANCY" if EraWords.reckoned() else "HOW LONG WE LIVE","value":"%.1f years" % expectancy if EraWords.reckoned() else EraWords.life(expectancy),"delta":"%+.1f" % expectancy_delta if absf(expectancy_delta)>=0.05 else "stable","delta_color":Tokens.GREEN if expectancy_delta>0.0 else (Tokens.RED if expectancy_delta<0.0 else Tokens.MUTED),"accent":Tokens.TEAL,"tip":"Expected lifespan at birth under current age-specific mortality and living conditions. Early societies lose many infants and young children; each care practice they learn removes part of that loss (see WHAT DECIDES WHO SURVIVES)."},
		{"label":EraWords.babes_title() if EraWords.reckoned() else ("BABES LOST" if EraWords.hearth() else "INFANTS BURIED"),"value":"%.0f / 1,000" % infant_mortality if EraWords.reckoned() else EraWords.babes_lost(infant_mortality).get_slice(" ",0)+" in "+EraWords.babes_lost(infant_mortality).get_slice(" ",2),"delta":"projected now" if EraWords.reckoned() else "before the first winter" if EraWords.hearth() else "before the first year","accent":Tokens.RED if infant_mortality>=50.0 else Tokens.AMBER,"tip":"Projected deaths before a first birthday per 1,000 live births under current birth care, diet, water and living conditions"},
		{"label":"DEATHS · 12M" if EraWords.reckoned() else "BURIED THIS YEAR","value":str(int(vital.get("deaths",0))),"delta":"recorded" if EraWords.reckoned() else "since this time last year","accent":Tokens.RED,"tip":"Actual deaths during the trailing 365 days"},
		{"label":"MEAN AGE AT DEATH" if EraWords.reckoned() else "AGE OF THE DEAD","value":("%.1f years" % observed_age if EraWords.reckoned() else EraWords.life(observed_age)) if observed_age>=0.0 else "—","delta":"observed" if observed_age>=0.0 else "no deaths","accent":Tokens.AMBER,"tip":"Observed mean age among recorded deaths; unlike life expectancy, this depends on who has died so far"},
	]
	var brief:=_health_brief(expectancy,expectancy_delta,water_intake,housing)
	var blocks:Array=[{
		"type":"line_chart","heading":"LIFE EXPECTANCY HISTORY" if EraWords.reckoned() else "HOW LONG WE LIVE, OVER THE YEARS","note":"monthly · up to 40 years","items":history,
		"tip":"Projected life expectancy recorded from the simulation. Gold diamonds mark health-related discoveries; circles mark meaningful changes without a health discovery."
	}]
	var care_rows:=_care_rows()
	if not care_rows.is_empty():blocks.append({"type":"rows","heading":"WHAT DECIDES WHO SURVIVES","note":"known practices · diet","items":care_rows})
	blocks.append({"type":"text","heading":"CIVILIAN CARE","text":preload("res://scripts/civilian_care.gd").describe()})
	var care_city:=GameState.resource_settlement_id
	blocks.append({"type":"actions","items":[{"label":"STANDARD CARE DUTY","sub":"Reserve 25% of available Knowledge labor","on_press":func():SettlementModel.with_city_resources(care_city,func():preload("res://scripts/civilian_care.gd").set_share(.25));hud.request_immediate_dock_refresh()},{"label":"EXPAND CARE DUTY","sub":"Reserve 50%; less time remains for research","on_press":func():SettlementModel.with_city_resources(care_city,func():preload("res://scripts/civilian_care.gd").set_share(.5));hud.request_immediate_dock_refresh()},{"label":"PAUSE CARE DUTY","sub":"Return these workers to other Knowledge work","on_press":func():SettlementModel.with_city_resources(care_city,func():preload("res://scripts/civilian_care.gd").set_share(0));hud.request_immediate_dock_refresh()}]})
	var changes:Array=[]
	for index in range(history.size()-1,-1,-1):
		var point:Dictionary=history[index]
		var marker:=String(point.get("marker_type",""))
		if marker=="": continue
		var delta:=float(point.get("delta",0.0))
		changes.append({
			"name":String(point.get("marker_label","Living conditions changed")),
			"sub":"Year %d · day %d" % [int(point.get("day",0))/365+1,int(point.get("day",0))%365+1],
			"detail":("Life expectancy %+.1f years" if EraWords.reckoned() else "%+.1f years of life") % delta,
			"value":"DISCOVERY" if marker=="discovery" else "CONDITIONS",
			"value_color":Tokens.GOLD if marker=="discovery" else (Tokens.RED if delta<0.0 else Tokens.BLUE),
			"accent":Tokens.GOLD if marker=="discovery" else (Tokens.RED if delta<0.0 else Tokens.BLUE),
			"tip":"A health-related discovery occurred in this interval." if marker=="discovery" else "No health-related discovery occurred in this interval; the shift came from simulated living conditions."
		})
		if changes.size()>=6: break
	if not changes.is_empty(): blocks.append({"type":"rows","heading":"WHY THE LINE MOVED","note":"latest marked changes","items":changes})
	var mortality:Dictionary=GameState.simulation_metrics.get("mortality_components",{})
	var mortality_items:Array=[]
	var peak:=0.000001
	for cause in mortality: peak=maxf(peak,float(mortality[cause]))
	for cause in mortality:
		var amount:=float(mortality[cause])
		if amount<=0.0: continue
		mortality_items.append({"name":String(cause),"value":"%.2f%% / yr" % (amount*100.0),"ratio":amount/peak,"color":Tokens.RED,"tip":"Current modeled annual mortality pressure"})
	if not mortality_items.is_empty(): blocks.append({"type":"bars","heading":"CURRENT MORTALITY PRESSURES","note":"modeled annual risk","items":mortality_items})
	blocks.append({"type":"tiles","heading":"CURRENT LIVING CONDITIONS","items":[
		{"label":"DRINKING NEED MET","value":"%d%%" % water_intake,"note":"daily access","note_color":Tokens.GREEN if water_intake>=98 else Tokens.RED,"tip":"Share of current drinking-water requirement met"},
		{"label":"SHELTER COVERAGE","value":"%d%%" % housing,"note":"population housed","note_color":Tokens.GREEN if housing>=95 else Tokens.RED,"tip":"Shelter capacity relative to the living population"},
	]})
	return {"kpis":kpis,"brief":brief,"blocks":blocks}

func _care_rows()->Array:
	var care:Dictionary=GameState.early_care
	if care.is_empty():return []
	var rows:Array=[]
	var diet:=float(care.get("diet",0.6))
	var child_factor:=float(care.get("under5",1.0))
	rows.append({
		"name":"Diet of the last four months","sub":"variety, protein, fresh food and preparation",
		"detail":"Young children die %.1f× as often as under full early care." % child_factor if child_factor>1.05 else "Children are as safe as early care allows.",
		"value":"%d%%" % roundi(diet*100.0),"value_color":Tokens.GREEN if diet>=0.70 else (Tokens.AMBER if diet>=0.55 else Tokens.RED),
		"accent":Tokens.TEAL,"tip":"A thin or monotonous diet raises child and newborn deaths and slows conception; hunger raises them further. Fresh plants, game and fish together, cooking and weaning foods lift it."
	})
	if float(care.get("overwork",0.0))>0.15:
		rows.append({"name":"Overwork","sub":"heavy labor share and labor drives","detail":"Hard work delays conception and endangers pregnancies.","value":"%d%%" % roundi(float(care.overwork)*100.0),"value_color":Tokens.RED,"accent":Tokens.RED,"tip":"More than about 70% of working people in food, extraction and building, or a labor mobilization, strains mothers and the young."})
	for row:Dictionary in EarlyCare.explanation(care):
		var coverage:=float(row.coverage)
		rows.append({
			"name":String(row.name),"sub":String(row.status),"detail":String(row.detail),
			"value":"%d%%" % roundi(coverage*100.0),
			"value_color":Tokens.GREEN if coverage>=0.95 else (Tokens.AMBER if coverage>=0.35 else Tokens.RED),
			"accent":Tokens.GREEN if coverage>=0.95 else Color(0,0,0,0),
			"tip":"How much of the avoidable early death this protection removes, from discoveries in practice (weighted by adoption) or later equivalent knowledge."
		})
	return rows

func _health_brief(expectancy:float,delta:float,water_intake:int,housing:int)->Dictionary:
	var lives:="Life expectancy is %.1f years." % expectancy if EraWords.reckoned() else "A child born now can hope for %s." % EraWords.life(expectancy)
	if water_intake<90:
		return {"tone":"danger","title":"Water access is shortening lives","why":"Only %d%% of daily drinking need is met. %s" % [water_intake,lives]}
	if housing<80:
		return {"tone":"warn","title":"Exposure is shortening lives","why":"Shelter covers %d%% of the population. %s" % [housing,lives]}
	if delta<=-0.5:
		return {"tone":"warn","title":"Life expectancy has fallen" if EraWords.reckoned() else "Lives are growing shorter","why":"The latest monthly observation changed by %.1f years. Check the marked history and current mortality pressures below." % delta}
	if not EraWords.reckoned():
		return {"tone":"info","title":"A child born now can hope for %s" % EraWords.life(expectancy),"why":"This is how long a newborn may live as things stand, not the age of everyone alive. %s The chart shows which changes came from new knowledge and which from how the people live." % EraWords.babes_lost_sentence(Indicators.infant_mortality_per_1000())}
	return {"tone":"info","title":"Expected lifespan is %.1f years" % expectancy,"why":"This is the modeled lifespan of a newborn under current conditions, not the average age of everyone alive. The chart distinguishes research-linked changes from shifts in living conditions."}

func signature()->Array:
	return SettlementModel.with_city_resources(GameState.selected_player_settlement_id,func()->Array:return SettlementModel.with_local_population(_city_signature))

func _city_signature()->Array:
	var history:Array[Dictionary]=GameState.health_history_snapshot()
	var latest:Dictionary=history[-1] if not history.is_empty() else {}
	return [GameState.selected_player_settlement_id,GameState.civilian_care.duplicate(true),roundi(GameState.projected_life_expectancy()*10.0),roundi(Indicators.infant_mortality_per_1000()),roundi(float(GameState.early_care.get("under5",1.0))*100.0),roundi(float(GameState.early_care.get("diet",0.0))*100.0),GameState.lifetime_deaths,latest.duplicate(true),GameState.simulation_metrics.get("mortality_components",{}).duplicate(true),roundi(float(GameState.simulation_metrics.get("housing_ratio",0.0))*1000.0),roundi(float(GameState.water_metrics.get("intake_ratio",0.0))*1000.0)]
