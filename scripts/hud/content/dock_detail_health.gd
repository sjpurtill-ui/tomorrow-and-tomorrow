extends "res://scripts/hud/content/dock_content_base.gd"
## Dedicated health and longevity view opened directly from the HEALTH KPI.

func meta()->Dictionary:
	return {
		"eyebrow":"POPULATION · HEALTH & SURVIVAL",
		"title":"Health & Life Expectancy",
		"subtabs":["LONGEVITY"],
	}

func tab(_sub:int)->Dictionary:
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
	var kpis:Array=[
		{"label":"LIFE EXPECTANCY","value":"%.1f years" % expectancy,"delta":"%+.1f" % expectancy_delta if absf(expectancy_delta)>=0.05 else "stable","delta_color":Tokens.GREEN if expectancy_delta>0.0 else (Tokens.RED if expectancy_delta<0.0 else Tokens.MUTED),"accent":Tokens.TEAL,"tip":"Expected lifespan at birth under current age-specific mortality and living conditions"},
		{"label":"HEALTH","value":"%d%%" % roundi(GameState.population_health*100.0),"delta":"current","accent":Tokens.TEAL,"tip":"Current physical condition and freedom from preventable harm"},
		{"label":"DEATHS · 12M","value":str(int(vital.get("deaths",0))),"delta":"recorded","accent":Tokens.RED,"tip":"Actual deaths during the trailing 365 days"},
		{"label":"MEAN AGE AT DEATH","value":"%.1f years" % observed_age if observed_age>=0.0 else "—","delta":"observed" if observed_age>=0.0 else "no deaths","accent":Tokens.AMBER,"tip":"Observed mean age among recorded deaths; unlike life expectancy, this depends on who has died so far"},
	]
	var brief:=_health_brief(expectancy,expectancy_delta,water_intake,housing)
	var blocks:Array=[{
		"type":"line_chart","heading":"LIFE EXPECTANCY HISTORY","note":"monthly · up to 40 years","items":history,
		"tip":"Projected life expectancy recorded from the simulation. Gold diamonds mark health-related discoveries; circles mark meaningful changes without a health discovery."
	}]
	var changes:Array=[]
	for index in range(history.size()-1,-1,-1):
		var point:Dictionary=history[index]
		var marker:=String(point.get("marker_type",""))
		if marker=="": continue
		var delta:=float(point.get("delta",0.0))
		changes.append({
			"name":String(point.get("marker_label","Living conditions changed")),
			"sub":"Year %d · day %d" % [int(point.get("day",0))/365+1,int(point.get("day",0))%365+1],
			"detail":"Life expectancy %+.1f years" % delta,
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

func _health_brief(expectancy:float,delta:float,water_intake:int,housing:int)->Dictionary:
	if water_intake<90:
		return {"tone":"danger","title":"Water access is shortening lives","why":"Only %d%% of daily drinking need is met. Life expectancy is %.1f years." % [water_intake,expectancy]}
	if housing<80:
		return {"tone":"warn","title":"Exposure is shortening lives","why":"Shelter covers %d%% of the population. Life expectancy is %.1f years." % [housing,expectancy]}
	if delta<=-0.5:
		return {"tone":"warn","title":"Life expectancy has fallen","why":"The latest monthly observation changed by %.1f years. Check the marked history and current mortality pressures below." % delta}
	return {"tone":"info","title":"Expected lifespan is %.1f years" % expectancy,"why":"This is the modeled lifespan of a newborn under current conditions, not the average age of everyone alive. The chart distinguishes research-linked changes from shifts in living conditions."}

func signature()->Array:
	var history:Array[Dictionary]=GameState.health_history_snapshot()
	var latest:Dictionary=history[-1] if not history.is_empty() else {}
	return [roundi(GameState.projected_life_expectancy()*10.0),roundi(GameState.population_health*1000.0),GameState.lifetime_deaths,latest.duplicate(true),GameState.simulation_metrics.get("mortality_components",{}).duplicate(true),roundi(float(GameState.simulation_metrics.get("housing_ratio",0.0))*1000.0),roundi(float(GameState.water_metrics.get("intake_ratio",0.0))*1000.0)]
