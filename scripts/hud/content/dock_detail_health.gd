extends "res://scripts/hud/content/dock_content_base.gd"
const Indicators:=preload("res://scripts/civilization_indicators.gd")
const EarlyCare:=preload("res://scripts/early_life_conditions.gd")
const EraWords:=preload("res://scripts/hud/era_words.gd")
const LIFE_REASONS:=preload("res://scripts/hud/life_change_words.gd")
const Hardships:=preload("res://scripts/hardship_log.gd")
const Icons:=preload("res://scripts/resource_icons.gd")
const Card:=preload("res://scripts/hud/chronicle_card.gd")
## Dedicated health and longevity view opened directly from the HEALTH KPI.
## Its second tab is the sickness & disaster log (hardship_log.gd): every
## fever, hungry season, dry spell, flood and fire, newest first, with what it
## cost. They do not interrupt the player; this is where they are looked up.

## Lines of the log shown at once, and the page being read.
const HARDSHIP_PAGE_SIZE:=10
var hardship_page:=0

func meta()->Dictionary:
	if not EraWords.reckoned():return {"eyebrow":"Life and death","title":"How long we live","subtabs":["Lives","Sickness & disasters"]}
	return {
		"eyebrow":"Health and survival",
		"title":"Health & Life Expectancy",
		"subtabs":["Lives","Sickness & disasters"],
	}

func tab(sub:int)->Dictionary:
	if sub==1:return _hardships()
	return SettlementModel.with_city_resources(GameState.selected_player_settlement_id,func()->Dictionary:return SettlementModel.with_local_population(_city_health))

## The sickness & disaster log: a few figures, the rule for what interrupts,
## and one line per trouble, newest first.
func _hardships()->Dictionary:
	var lines:=Hardships.entries()
	var today:=int(GameState.elapsed_days)
	var recent:=0
	var recent_dead:=0
	var worst:Dictionary={}
	for e:Dictionary in lines:
		if today-int(e.get("start",0))<=3650:
			recent+=1
			recent_dead+=int(e.get("dead",0))
		if int(e.get("dead",0))>int(worst.get("dead",0)):worst=e
	var kpis:Array=[
		{"label":"LAST TEN YEARS","value":str(recent),"delta":"sicknesses and disasters","accent":Tokens.AMBER,"tip":"How many were written here in the last ten years."},
		{"label":"DIED OF THEM","value":str(recent_dead),"delta":"in the last ten years","accent":Tokens.RED,"tip":"Everyone they killed in the last ten years."},
		{"label":"DEADLIEST","value":("%d died" % int(worst.dead)) if not worst.is_empty() else "none yet","delta":("%s · %s" % [Hardships.title(worst),EraWords.when(int(worst.get("start",0)))]) if not worst.is_empty() else "no one has died of one","accent":Tokens.RED,"tip":"The deadliest kept in this log."},
	]
	var brief:={"tone":"info","title":"Written here, not brought to you",
		"why":"Fevers, hungry seasons, dry spells, floods and fires are written here as they happen, newest first, with what each cost. They do not interrupt you. Only an extreme one, one in twenty of the people dead or half the stores or shelter lost at once, comes to you as a card and is kept in the Chronicle."}
	var blocks:Array=[]
	if lines.is_empty():
		blocks.append({"type":"text","heading":"Nothing written yet","text":"No sickness or disaster has struck the people since this log began. Each one is written here as it happens."})
		return {"kpis":kpis,"brief":brief,"blocks":blocks}
	# Crises whose matter waits at court, by their line's id ("<crisis>@<start>"):
	# their line can summon the holder.
	var waiting:Dictionary={}
	for c:Dictionary in load("res://scripts/crisis_system.gd").call("active"):
		if String(c.get("matter",""))!="" and int(c.get("holder_pid",0))>0:waiting["%s@%d" % [String(c.get("id","")),int(c.get("start",0))]]=c
	var pages:=maxi(1,ceili(lines.size()/float(HARDSHIP_PAGE_SIZE)))
	hardship_page=clampi(hardship_page,0,pages-1)
	var rows:Array=[]
	for e:Dictionary in lines.slice(hardship_page*HARDSHIP_PAGE_SIZE,(hardship_page+1)*HARDSHIP_PAGE_SIZE):
		rows.append(hardship_row(e,waiting.get(String(e.get("id","")),{})))
	blocks.append({"type":"rows","heading":"Newest first","note":"%d kept" % lines.size(),"items":rows})
	if pages>1:
		blocks.append({"type":"actions","heading":"Page %d of %d" % [hardship_page+1,pages],"items":[
			{"label":"Newer","disabled":hardship_page==0,"on_press":func():_turn_hardship_page(-1)},
			{"label":"Older","disabled":hardship_page==pages-1,"on_press":func():_turn_hardship_page(1)}]})
	return {"kpis":kpis,"brief":brief,"blocks":blocks}

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

func _turn_hardship_page(delta:int)->void:
	hardship_page+=delta
	if hud and hud.has_method("request_immediate_dock_refresh"):hud.request_immediate_dock_refresh()

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
	var brief:=_health_brief(expectancy,expectancy_delta,water_intake,housing)
	var blocks:Array=[{
		"type":"line_chart","heading":"Life expectancy over the years" if EraWords.reckoned() else "How long we live, over the years","note":"counted each month, up to 40 years back","items":history,
		"tip":"Projected life expectancy recorded from the simulation. Gold diamonds mark health-related discoveries; circles mark meaningful changes without a health discovery."
	}]
	var care_rows:=_care_rows()
	if not care_rows.is_empty():blocks.append({"type":"rows","heading":"What decides who survives","note":"what we know and what we eat","items":care_rows})
	var Care:=preload("res://scripts/civilian_care.gd")
	var care_city:=GameState.resource_settlement_id
	var care_words:=preload("res://scripts/hud/home_plain.gd").care(float(Care.data().staff_share),Care.staff(),Care.data().report,preload("res://scripts/civilian_care_fabric.gd").outstanding(Care.data()),bool(Care.methods(WorldSimulation.state).get("rounds",false)))
	var choice:=String(care_words.choice)
	blocks.append({"type":"text","heading":"Care of the sick","text":Care.describe()})
	if bool(Care.methods(WorldSimulation.state).get("rounds",false)):
		var set_share:=func(share:float)->void:
			SettlementModel.with_city_resources(care_city,func():Care.set_share(share))
			hud.request_immediate_dock_refresh()
		blocks.append({"type":"actions","heading":"How many lore keepers look after the sick","items":[
			{"label":"None"+(" (now)" if choice=="none" else ""),"sub":"The sick are looked after at home","primary":choice=="none","on_press":set_share.bind(0.0)},
			{"label":"A quarter of them"+(" (now)" if choice=="standard" else ""),"sub":"The usual share","primary":choice=="standard","on_press":set_share.bind(0.25)},
			{"label":"Half of them"+(" (now)" if choice=="more" else ""),"sub":"More care, slower learning","primary":choice=="more","on_press":set_share.bind(0.5)}]})
	var changes:Array=[]
	for index in range(history.size()-1,-1,-1):
		var point:Dictionary=history[index]
		var marker:=String(point.get("marker_type",""))
		if marker=="": continue
		var delta:=float(point.get("delta",0.0))
		# The whole month's change, in days or weeks when that is its size: a
		# new practice is taken up over years, so its first month is small.
		var change:=EraWords.life_change(delta)
		var detail:=("Life expectancy that month: %s" if EraWords.reckoned() else "That month: %s of life") % change
		if change=="less than a day" and marker=="discovery":detail="That month: less than a day so far; new ways take years to spread"
		# What moved it, with its numbers (GameState.life_change_reasons).
		var reasons:Array=point.get("reasons",[]) if point.get("reasons") is Array else []
		var told:=LIFE_REASONS.tell(reasons,delta,index,history)
		var name:=String(point.get("marker_label","")) if marker=="discovery" else String(told.name)
		if String(told.why)!="":detail+=". "+String(told.why)
		changes.append({
			"name":name,
			"sub":EraWords.when(int(point.get("day",0))),
			"detail":detail,
			"value":"New knowledge" if marker=="discovery" else String(told.category),
			"value_color":Tokens.GOLD_TEXT if marker=="discovery" else (Tokens.RED_TEXT if delta<0.0 else Tokens.BLUE_TEXT),
			"accent":Tokens.GOLD if marker=="discovery" else (Tokens.RED if delta<0.0 else Tokens.BLUE),
			"tip":("A health-related discovery came this month; the new way adds more as more of the people take it up. " if marker=="discovery" else "")+String(told.tip)
		})
		if changes.size()>=6: break
	if not changes.is_empty(): blocks.append({"type":"rows","heading":"Why lives grew longer or shorter","note":"latest changes","items":changes})
	var mortality:Dictionary=GameState.simulation_metrics.get("mortality_components",{})
	var mortality_items:Array=[]
	var peak:=0.000001
	for cause in mortality: peak=maxf(peak,float(mortality[cause]))
	for cause in mortality:
		var amount:=float(mortality[cause])
		if amount<=0.0: continue
		mortality_items.append({"name":String(cause).replace("_"," ").capitalize(),"value":_per_year_words(amount),"ratio":amount/peak,"color":Tokens.RED,"tip":"How many people this is killing each year at present"})
	if not mortality_items.is_empty(): blocks.append({"type":"bars","heading":"What is killing people now","note":"deaths each year, at the present rate","items":mortality_items})
	blocks.append({"type":"tiles","heading":"How people live now","items":[
		{"label":"Enough to drink","value":"%d in 10" % roundi(water_intake/10.0),"note":"everyone drinks enough" if water_intake>=98 else "some go thirsty","note_color":Tokens.GREEN_TEXT if water_intake>=98 else Tokens.RED_TEXT,"tip":"Out of every ten people, how many drink as much as they need each day"},
		{"label":"A roof at night","value":"%d in 10" % mini(10,roundi(housing/10.0)),"note":"everyone is sheltered" if housing>=95 else "some sleep in the open","note_color":Tokens.GREEN_TEXT if housing>=95 else Tokens.RED_TEXT,"tip":"Out of every ten people, how many have shelter"},
	]})
	return {"kpis":kpis,"brief":brief,"blocks":blocks}

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

func _health_brief(expectancy:float,delta:float,water_intake:int,housing:int)->Dictionary:
	var lives:="Life expectancy is %.1f years." % expectancy if EraWords.reckoned() else "A child born now can hope for %s." % EraWords.life(expectancy)
	if water_intake<90:
		return {"tone":"danger","title":"Water access is shortening lives","why":"Only %d%% of daily drinking need is met. %s" % [water_intake,lives]}
	if housing<80:
		return {"tone":"warn","title":"Exposure is shortening lives","why":"Shelter covers %d%% of the population. %s" % [housing,lives]}
	if delta<=-0.5:
		return {"tone":"warn","title":"Life expectancy has fallen" if EraWords.reckoned() else "Lives are growing shorter","why":"Last month it changed by %s. Check the marked history and current mortality pressures below." % EraWords.life_change(delta)}
	if not EraWords.reckoned():
		return {"tone":"info","title":"A child born now can hope for %s" % EraWords.life(expectancy),"why":"This is how long a newborn may live as things stand, not the age of everyone alive. %s The chart shows which changes came from new knowledge and which from how the people live." % EraWords.babes_lost_sentence(Indicators.infant_mortality_per_1000())}
	return {"tone":"info","title":"Expected lifespan is %.1f years" % expectancy,"why":"This is the modeled lifespan of a newborn under current conditions, not the average age of everyone alive. The chart distinguishes research-linked changes from shifts in living conditions."}

func signature()->Array:
	var sig:Array=SettlementModel.with_city_resources(GameState.selected_player_settlement_id,func()->Array:return SettlementModel.with_local_population(_city_signature))
	# The log's lines change as troubles run their course.
	sig.append_array([Hardships.revision(),hardship_page])
	return sig

func _city_signature()->Array:
	var history:Array[Dictionary]=GameState.health_history_snapshot()
	var latest:Dictionary=history[-1] if not history.is_empty() else {}
	return [GameState.selected_player_settlement_id,GameState.civilian_care.duplicate(true),roundi(GameState.projected_life_expectancy()*10.0),roundi(Indicators.infant_mortality_per_1000()),roundi(float(GameState.early_care.get("under5",1.0))*100.0),roundi(float(GameState.early_care.get("diet",0.0))*100.0),GameState.lifetime_deaths,latest.duplicate(true),GameState.simulation_metrics.get("mortality_components",{}).duplicate(true),roundi(float(GameState.simulation_metrics.get("housing_ratio",0.0))*1000.0),roundi(float(GameState.water_metrics.get("intake_ratio",0.0))*1000.0)]
