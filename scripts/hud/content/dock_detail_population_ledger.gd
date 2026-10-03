extends "res://scripts/hud/content/dock_content_base.gd"
const Charts:=preload("res://scripts/hud/strategic_chart_blocks.gd")
const EraWords:=preload("res://scripts/hud/era_words.gd")
## Detail dock: the population ledger — births, deaths, causes, and the
## demographic record. Replaces the full-screen population ledger modal.

var death_page:=0
var summary_page:=0
const PAGE_SIZE:=8

func meta()->Dictionary:
	return {
		"eyebrow":"All our people",
		"title":"Births and deaths",
		"subtabs":["Overview","Every death"],
	}

func tab(_sub:int)->Dictionary:
	var pregnancy:Dictionary=GameState.pregnancy_summary()
	var kpis:Array=[
		{"label":"PEOPLE","value":str(GameState.population_total),"delta":"alive now","accent":Tokens.GREEN,"tip":"Everyone alive now"},
		{"label":"BORN","value":str(GameState.lifetime_births),"delta":"since we set out","accent":Tokens.GREEN,"tip":"Every birth since the people set out"},
		{"label":"DIED","value":str(GameState.lifetime_deaths),"delta":"since we set out","accent":Tokens.RED,"tip":"Every death since the people set out"},
		{"label":"LIFE EXPECTANCY" if EraWords.reckoned() else "HOW LONG WE LIVE","value":"%.1f years" % GameState.projected_life_expectancy() if EraWords.reckoned() else EraWords.life(GameState.projected_life_expectancy()),"delta":"for a child born now","accent":Tokens.TEAL,"tip":"How long a child born now can hope to live, as things stand"},
	]
	var maternity_items:Array=[
		{"label":"WITH CHILD","value":str(int(pregnancy.get("active",0))),"note":"about %d births in the next year" % roundi(float(GameState.simulation_metrics.get("births_expected_next_year",0.0))),"note_color":Tokens.GREEN_TEXT,"tip":"Women carrying a child now"},
		{"label":"LOST BEFORE BIRTH","value":str(GameState.lifetime_pregnancy_losses),"note":"%d born dead" % GameState.lifetime_stillbirths,"note_color":Tokens.MUTED,"tip":"Children lost before or at birth, since the people set out"},
		{"label":"MOTHERS DIED","value":str(GameState.lifetime_maternal_deaths),"note":"in childbirth","note_color":Tokens.RED_TEXT,"tip":"Mothers who died giving birth, since the people set out"},
		{"label":"NEWBORNS DIED","value":str(GameState.lifetime_neonatal_deaths),"note":"in their first month","note_color":Tokens.RED_TEXT,"tip":"Babies who died in their first month, since the people set out"},
	]
	var killing:Dictionary=preload("res://scripts/hud/content/dock_detail_health.gd").mortality_block("How many people this cause kills each year at the present rate")
	var blocks:Array=[
		Charts.population("civilization"),
		{"type":"tiles","heading":"Mothers and babies","items":maternity_items},
	]
	var records:=grouped_deaths(GameState.demographic_ledger)
	if _sub==1:
		records.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return int(a.last_day)>int(b.last_day))
		return {"kpis":kpis,"brief":{},"blocks":_death_pages(records,false)}
	blocks.append_array(_death_pages(death_summary(GameState.demographic_ledger),true))
	if not killing.is_empty():
		blocks.append(killing)
	var profile:Dictionary=CivilizationSystem.player_population_function_profile()
	blocks.append({"type":"tiles","heading":"Where everyone is","items":[
		{"label":"WORKING","value":str(int(profile.get("productive",0))),"note":"gathering, making, building","note_color":Tokens.GREEN_TEXT,"tip":"People doing the day's work"},
		{"label":"TENDING OTHERS","value":str(int(profile.get("support",0))),"note":"care and keeping order","note_color":Tokens.MUTED,"tip":"People looking after others and keeping things running"},
		{"label":"CHILDREN AND ELDERS","value":str(int(profile.get("dependent",0))),"note":"looked after by the rest","note_color":Tokens.MUTED,"tip":"People too young or too old for the day's work"},
		{"label":"AWAY","value":str(int(profile.get("absent",0))+int(profile.get("mobilized",0))),"note":"on the road or under arms","note_color":Tokens.AMBER_TEXT,"tip":"People away on journeys or called to fight"},
	]})
	var workforce:=GameState.workforce_capacity_snapshot()
	blocks.append({"type":"text","heading":"How much work gets done","text":"%d people are at work, and between them they get done what %s people at full strength would.%s" % [int(workforce.people),preload("res://scripts/hud/production_plain.gd").number(float(workforce.effective_workers)),(" %d came home from fighting with lasting injuries; they manage lighter work better than carrying or building." % int(workforce.lasting_injuries)) if int(workforce.lasting_injuries)>0 else ""]})
	return {"kpis":kpis,"brief":{},"blocks":blocks}

func signature()->Array:
	return [death_page,summary_page,GameState.demographic_ledger.size(),GameState.strategic_history.get("last_day",-1),GameState.civilian_injuries.duplicate(true),GameState.population_allocations.duplicate(true),GameState.population_total,GameState.lifetime_births,GameState.lifetime_deaths,int(GameState.pregnancy_summary().get("active",0)),GameState.housing_capacity,float(GameState.simulation_metrics.get("housing_ratio",-1.0)),GameState.simulation_metrics.get("mortality_components",{}).duplicate(true),float(GameState.simulation_metrics.get("usual_hardship_rate",0.0))]

static func grouped_deaths(ledger:Array)->Array:
	var groups:Dictionary={}
	for record:Dictionary in ledger:
		if String(record.get("kind",""))!="death":continue
		var day:=int(record.get("day",0));var cause:=String(record.get("cause","Unknown cause"))
		var place:=String(record.get("location",record.get("target_label","Location unrecorded"))).trim_suffix(" in The Known World")
		var key:="%s/%s/%s/%d" % [String(record.get("target_id",place)),place,cause,day/30]
		if not groups.has(key):groups[key]={"place":place,"cause":cause,"first":day,"last":day,"count":0,"records":0}
		var group:Dictionary=groups[key];group.first=mini(int(group.first),day);group.last=maxi(int(group.last),day);group.count+=int(record.get("count",0));group.records+=1
	var result:Array=[]
	for group:Dictionary in groups.values():
		result.append({"last_day":int(group.last),"name":group.place,"value":"%d death%s" % [int(group.count),"" if int(group.count)==1 else "s"],"sub":"%s · %s" % [String(group.cause).capitalize(),EraWords.when(int(group.first)) if EraWords.when(int(group.first))==EraWords.when(int(group.last)) else "%s to %s" % [EraWords.when(int(group.first)),EraWords.when(int(group.last))]],"tip":"Deaths from this cause here, gathered by month.","accent":Tokens.RED})
	return result

static func death_summary(ledger:Array)->Array:
	var groups:Dictionary={}
	for record:Dictionary in ledger:
		if String(record.get("kind",""))!="death":continue
		var cause:=String(record.get("cause","Unknown cause"))
		if not groups.has(cause):groups[cause]={"count":0,"places":{},"records":0}
		var group:Dictionary=groups[cause]
		group.count+=int(record.get("count",0));group.records+=1
		group.places[String(record.get("target_id",record.get("location","Location unrecorded")))]=true
	var rows:Array=[]
	for cause:String in groups:
		var group:Dictionary=groups[cause]
		rows.append({"name":cause,"value":"%d death%s"%[int(group.count),"" if int(group.count)==1 else "s"],"count":int(group.count),"sub":"in %d place%s" % [group.places.size(),"" if group.places.size()==1 else "s"],"accent":Tokens.RED})
	rows.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return int(a.count)>int(b.count) if a.count!=b.count else String(a.name)<String(b.name))
	return rows

func _death_pages(rows:Array,summary:bool)->Array:
	var page:=summary_page if summary else death_page
	var pages:=maxi(1,ceili(rows.size()/float(PAGE_SIZE)))
	page=clampi(page,0,pages-1)
	if summary:summary_page=page
	else:death_page=page
	var heading:="Deaths by cause" if summary else "Every death, newest first"
	if rows.is_empty():return [{"type":"text","heading":heading,"text":"No one has died yet."}]
	var blocks:Array=[{"type":"rows","heading":heading,"items":rows.slice(page*PAGE_SIZE,(page+1)*PAGE_SIZE)},{"type":"text","text":"Open \"Every death\" above for when and where." if summary else "Deaths from the same cause in the same place and month are listed together."}]
	if pages>1:blocks.append({"type":"actions","heading":"Page %d of %d"%[page+1,pages],"items":[{"label":"Newer","disabled":page==0,"on_press":func():_change_death_page(summary,-1)},{"label":"Older","disabled":page==pages-1,"on_press":func():_change_death_page(summary,1)}]})
	return blocks

func _change_death_page(summary:bool,delta:int)->void:
	if summary:summary_page+=delta
	else:death_page+=delta
	hud.request_immediate_dock_refresh()
