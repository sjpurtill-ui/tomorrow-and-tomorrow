extends "res://scripts/hud/content/dock_content_base.gd"
const Indicators:=preload("res://scripts/civilization_indicators.gd")
const EarlyCare:=preload("res://scripts/early_life_conditions.gd")
const EraWords:=preload("res://scripts/hud/era_words.gd")
const Hardships:=preload("res://scripts/hardship_log.gd")
const Icons:=preload("res://scripts/resource_icons.gd")
const Card:=preload("res://scripts/hud/chronicle_card.gd")
## Dedicated health and longevity view opened directly from the HEALTH KPI.
## Its second tab is the sickness & disaster log (hardship_log.gd): every
## fever, hungry season, dry spell, flood and fire, newest first, with what it
## cost. They do not interrupt the player; this is where they are looked up.

func meta()->Dictionary:
	if not EraWords.reckoned():return {"spatial_view":true,"eyebrow":"Life and death","title":"How long we live","subtabs":["Lives","Sickness & disasters"]}
	return {
		"spatial_view":true,"eyebrow":"Health and survival",
		"title":"Health & Life Expectancy",
		"subtabs":["Lives","Sickness & disasters"],
	}

func tab(sub:int)->Dictionary:
	if sub==1:return _hardships()
	return SettlementModel.with_city_resources(GameState.selected_player_settlement_id,func()->Dictionary:return SettlementModel.with_local_population(_city_health))

## Read the existing ledger; the retained dashboard owns selection and paging.
func _hardships()->Dictionary:
	var waiting:Dictionary={}
	for c:Dictionary in load("res://scripts/crisis_system.gd").call("active"):
		if String(c.get("matter",""))!="" and int(c.get("holder_pid",0))>0:waiting["%s@%d" % [String(c.get("id","")),int(c.get("start",0))]]=c
	var events:Array=[]
	for e:Dictionary in Hardships.entries():
		var row:=hardship_row(e,waiting.get(String(e.get("id","")),{}))
		row.merge({"id":String(e.get("id","")),"day":int(e.get("start",0)),"date":EraWords.when(int(e.get("start",0))),
			"kind":String(Hardships.WHAT.get(String(e.get("type","")),"Hard times")),"ongoing":not Hardships.over(e),
			"dead":int(e.get("dead",0)),"sick":int(e.get("sick",0)),"food":roundi(float(e.get("food_lost",0))),
			"shelter":int(e.get("house_lost",0)),"timber":roundi(float(e.get("timber_lost",0)))})
		events.append(row)
	return {"blocks":[{"type":"hardship_dashboard","events":events,"today":int(GameState.elapsed_days),
		"empty":"Nothing written yet","tip":"Only an extreme event interrupts: one in twenty of the people dead, or half the stores or shelter lost. All events remain in this record."}]}

## One line of the log as a dock row. `waiting`: its crisis, when a matter
## about it waits at court (the row then summons the holder).
func hardship_row(e:Dictionary,waiting:Dictionary={})->Dictionary:
	var said:=Hardships.words(e)
	var glyph:=Hardships.glyph(e)
	var dead:=int(e.get("dead",0))
	var row:={"name":String(said.title),"sub":String(said.sub),"detail":String(said.detail),"value":String(said.value),
		"value_color":Tokens.RED_TEXT if dead>0 else Tokens.MUTED,"accent":Tokens.RED if bool(e.get("extreme",false)) else Color(0,0,0,0),
		"icon":Icons.moment_texture(glyph,Card.ACCENTS.get(glyph,Tokens.AMBER),48),"tip":String(said.tip)}
	if not waiting.is_empty():
		var holder:=String(waiting.get("holder","")).get_slice(" ",0)
		row["detail"]="%s %s waits to be summoned about it." % [String(row.detail),holder if holder!="" else "An official"]
		row["value"]="Summon"
		row["value_color"]=Tokens.GOLD_TEXT
		row["tip"]="Click to summon %s to the court and answer." % (holder if holder!="" else "them")
		row["on_click"]=court({"person_id":int(waiting.get("holder_pid",0))})
	return row

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
		{"label":"LIFE EXPECTANCY" if EraWords.reckoned() else "HOW LONG WE LIVE","value":"%.1f years" % expectancy if EraWords.reckoned() else EraWords.life(expectancy),"delta":("%s %s since last month" % ["up" if expectancy_delta>0.0 else "down",EraWords.life_change(expectancy_delta).trim_prefix("+").trim_prefix("-")]) if absf(expectancy_delta)*365.25>=1.0 else "no change since last month","delta_color":Tokens.GREEN_TEXT if expectancy_delta>0.0 else (Tokens.RED_TEXT if expectancy_delta<0.0 else Tokens.MUTED),"accent":Tokens.TEAL,"tip":"How long a child born now can hope to live, as things stand."},
		{"label":EraWords.babes_title() if EraWords.reckoned() else ("BABES LOST" if EraWords.hearth() else "INFANTS BURIED"),"value":"%.0f / 1,000" % infant_mortality if EraWords.reckoned() else EraWords.babes_lost(infant_mortality).get_slice(" ",0)+" in "+EraWords.babes_lost(infant_mortality).get_slice(" ",2),"delta":"projected now" if EraWords.reckoned() else "before the first winter" if EraWords.hearth() else "before the first year","accent":Tokens.RED if infant_mortality>=50.0 else Tokens.AMBER,"tip":"Babies who die before their first year, as things stand."},
		{"label":"DEATHS IN THE LAST YEAR" if EraWords.reckoned() else "BURIED THIS YEAR","value":str(int(vital.get("deaths",0))),"delta":"since this time last year","accent":Tokens.RED,"tip":"Everyone who died in the past year."},
		{"label":"MEAN AGE AT DEATH" if EraWords.reckoned() else "AGE OF THE DEAD","value":("%.1f years" % observed_age if EraWords.reckoned() else EraWords.life(observed_age)) if observed_age>=0.0 else "—","delta":"observed" if observed_age>=0.0 else "no deaths","accent":Tokens.AMBER,"tip":"The average age of those who died so far."},
	]
	var Care:=preload("res://scripts/civilian_care.gd")
	var care_city:=GameState.resource_settlement_id
	var rounds:=bool(Care.methods(WorldSimulation.state).get("rounds",false))
	var set_share:=func(share:float)->void:
		SettlementModel.with_city_resources(care_city,func():Care.set_share(share))
		if hud: hud.request_immediate_dock_refresh()
	var alert:=""
	if water_intake<90:alert="Water shortage: only %d%% of drinking need met" % water_intake
	elif housing<80:alert="Shelter shortage: roofs for %d%% of people" % housing
	return {"readings":kpis,"blocks":[{
		"type":"health_dashboard","readings":kpis,"history":history,
		"research":preload("res://scripts/hud/health_discoveries.gd").read(),
		"conditions":_care_rows(),"mortality":mortality_block("Annual risk at today's rate").get("items",[]),
		"care_title":"Care of the sick","care":Care.describe(),"care_share":float(Care.data().staff_share),
		"care_unlocked":rounds,"on_care":set_share,"alert":alert,
		"water":water_intake,"housing":housing,"scope":care_city
	}]}

## The hard times' bar on "What is killing people now" (crisis_background.gd).
const HARD_TIMES_NAME:="Sickness, floods and lean seasons (a usual year)"
const HARD_TIMES_TIP:="Hard times come in bursts. This is what they take in an ordinary year. When one strikes, its dead are counted under its own cause."
const HARD_TIMES_NOTE:="deaths each year at the present rate, hard times averaged in"

## "What is killing people now" (this view and the population ledger): each of
## the day's causes at the present rate, and, muted beside them, what the hard
## times take in a usual year (GameState.usual_hardship_rate, kept with the
## day's metrics), so in a calm year too the bars add up to the rate behind
## LIVES. `tip` is each cause's tooltip. {} with nothing to show.
static func mortality_block(tip:String)->Dictionary:
	var metrics:Dictionary=GameState.simulation_metrics
	var mortality:Dictionary=metrics.get("mortality_components",{}) if metrics.get("mortality_components") is Dictionary else {}
	var usual:=maxf(0.0,float(metrics.get("usual_hardship_rate",0.0)))
	var peak:=maxf(0.000001,usual)
	for cause in mortality: peak=maxf(peak,float(mortality[cause]))
	var items:Array=[]
	for cause in mortality:
		var amount:=float(mortality[cause])
		if amount<=0.0: continue
		items.append({"name":String(cause).replace("_"," ").capitalize(),"value":_per_year_words(amount),"ratio":amount/peak,"color":Tokens.RED,"tip":tip})
	if items.is_empty(): return {}
	if usual>0.0:
		items.append({"name":HARD_TIMES_NAME,"value":_per_year_words(usual),"ratio":usual/peak,"color":Tokens.MUTED,"tip":HARD_TIMES_TIP})
	return {"type":"bars","heading":"What is killing people now","note":HARD_TIMES_NOTE if usual>0.0 else "deaths each year, at the present rate","items":items}

static func _per_year_words(rate:float)->String:
	if rate<=0.0:return "none"
	var people:=1.0/rate
	if people>=10000.0:return "under 1 in 10,000"
	if people>=1000.0:return "1 in %d,000" % roundi(people/1000.0)
	return "1 in %d" % roundi(people)

func _care_rows()->Array:
	var care:Dictionary=GameState.early_care
	if care.is_empty():return []
	var rows:Array=[]
	var diet:=float(care.get("diet",0.6))
	var child_factor:=float(care.get("under5",1.0))
	rows.append({
		"name":"Diet of the last four months","sub":"variety, protein, fresh food and preparation",
		"detail":"Young children die %.1f times as often as they would with the best early care." % child_factor if child_factor>1.05 else "Children are as safe as early care allows.",
		"value":"Good" if diet>=0.70 else ("Thin" if diet>=0.55 else "Poor"),"value_color":Tokens.GREEN_TEXT if diet>=0.70 else (Tokens.AMBER_TEXT if diet>=0.55 else Tokens.RED_TEXT),
		"accent":Tokens.TEAL,"tip":"A thin or monotonous diet raises child and newborn deaths and slows conception; hunger raises them further. Fresh plants, game and fish together, cooking and weaning foods lift it."
	})
	# Fresh food and the carers (food_care.gd), with the engine's numbers.
	var FoodCare:=preload("res://scripts/food_care.gd")
	var metrics:Dictionary=GameState.simulation_metrics
	if metrics.has("food_fresh_share"):
		var share:=clampf(float(metrics.food_fresh_share),0.0,1.0)
		var points:=FoodCare.fresh_health(share)*100.0
		rows.append({"name":"Fresh food","sub":"%d in 10 of what is eaten is fresh" % roundi(share*10.0),"detail":FoodCare.fresh_sentence(share),
			"value":("+%d" if points>=0.0 else "%d") % roundi(points)+" health","value_color":Tokens.GREEN_TEXT if points>=0.0 else Tokens.RED_TEXT,
			"accent":Tokens.TEAL,"tip":"Health leans up to %d points when everything eaten is fresh, and down %d on stored food alone. Fresh food spoils fast: getting food and carrying bring it to mouths before it turns." % [roundi(FoodCare.fresh_health(1.0)*100.0),roundi(-FoodCare.fresh_health(0.0)*100.0)]})
	var tended:=FoodCare.care_cover_of(GameState)
	rows.append({"name":"Carers","sub":"keeping and caring: newborns, mothers, the sick","detail":FoodCare.caring_sentence(tended,float(care.get("carer_cover_target",tended)),maxf(1.0,GameState.population_exact)),
		"value":"%d in 100" % roundi(tended*100.0),"value_color":Tokens.GREEN_TEXT if tended>=0.95 else (Tokens.AMBER_TEXT if tended>=0.35 else Tokens.RED_TEXT),
		"accent":Tokens.GREEN if tended>=0.95 else Color(0,0,0,0),"tip":"Of full care: carers at %d in 100 of the people cover part of what missing child care, remedies, clean water and wound care would, and lift part of the old burden of disease from babies, small children and mothers. A people that leans hard on caring may outdo the best the old world knew, a little." % roundi(FoodCare.CARE_SHARE*100.0)})
	if float(care.get("overwork",0.0))>0.15:
		rows.append({"name":"Overwork","sub":"too many at heavy work, or a labour drive","detail":"Hard work delays conception and endangers pregnancies.","value":"Heavy" if float(care.overwork)>=0.4 else "Some","value_color":Tokens.RED_TEXT,"accent":Tokens.RED,"tip":"More than about 70% of working people in food, extraction and building, or a labor mobilization, strains mothers and the young."})
	for row:Dictionary in EarlyCare.explanation(care):
		var coverage:=float(row.coverage)
		rows.append({
			"name":String(row.name),"sub":String(row.status),"detail":String(row.detail),
			"value":"In use" if coverage>=0.95 else ("Partly" if coverage>=0.35 else "Not yet"),
			"value_color":Tokens.GREEN_TEXT if coverage>=0.95 else (Tokens.AMBER_TEXT if coverage>=0.35 else Tokens.RED_TEXT),
			"accent":Tokens.GREEN if coverage>=0.95 else Color(0,0,0,0),
			"tip":"How much of the avoidable early death this protection removes, from discoveries in practice (weighted by adoption) or later equivalent knowledge."
		})
	return rows

func signature()->Array:
	var sig:Array=SettlementModel.with_city_resources(GameState.selected_player_settlement_id,func()->Array:return SettlementModel.with_local_population(_city_signature))
	# The log's lines change as troubles run their course.
	sig.append_array([Hardships.revision()])
	return sig

func _city_signature()->Array:
	var history:Array[Dictionary]=GameState.health_history_snapshot()
	var latest:Dictionary=history[-1] if not history.is_empty() else {}
	return [GameState.selected_player_settlement_id,GameState.elapsed_days,GameState.known_discoveries.size(),GameState.discovery_adoption.hash(),GameState.civilian_care.duplicate(true),roundi(GameState.projected_life_expectancy()*10.0),roundi(Indicators.infant_mortality_per_1000()),roundi(float(GameState.early_care.get("under5",1.0))*100.0),roundi(float(GameState.early_care.get("diet",0.0))*100.0),GameState.lifetime_deaths,latest.duplicate(true),GameState.simulation_metrics.get("mortality_components",{}).duplicate(true),float(GameState.simulation_metrics.get("usual_hardship_rate",0.0)),roundi(float(GameState.simulation_metrics.get("housing_ratio",0.0))*1000.0),roundi(float(GameState.water_metrics.get("intake_ratio",0.0))*1000.0)]
