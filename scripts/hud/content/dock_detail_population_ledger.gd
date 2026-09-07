extends "res://scripts/hud/content/dock_content_base.gd"
const Charts:=preload("res://scripts/hud/strategic_chart_blocks.gd")
## Detail dock: the population ledger — births, deaths, causes, and the
## demographic record. Replaces the full-screen population ledger modal.

var death_page:=0
var summary_page:=0
const PAGE_SIZE:=8

func meta()->Dictionary:
	return {
		"eyebrow":"SETTLEMENT · FULL RECORD",
		"title":"Population Ledger",
		"subtabs":["OVERVIEW","DEATH RECORDS"],
	}

func tab(_sub:int)->Dictionary:
	var pregnancy:Dictionary=GameState.pregnancy_summary()
	var kpis:Array=[
		{"label":"PEOPLE","value":str(GameState.population_total),"delta":"","accent":Tokens.GREEN,"tip":"Living population"},
		{"label":"BIRTHS","value":str(GameState.lifetime_births),"delta":"recorded","accent":Tokens.GREEN,"tip":"Births since founding"},
		{"label":"DEATHS","value":str(GameState.lifetime_deaths),"delta":"recorded","accent":Tokens.RED,"tip":"Deaths since founding"},
		{"label":"LIFE EXP.","value":"%.1f y" % GameState.projected_life_expectancy(),"delta":"","accent":Tokens.TEAL,"tip":"Projected at birth under current conditions"},
	]
	var maternity_items:Array=[
		{"label":"PREGNANCIES","value":str(int(pregnancy.get("active",0))),"note":"~%d births expected / 12 months" % roundi(float(GameState.simulation_metrics.get("births_expected_next_year",0.0))),"note_color":Tokens.GREEN,"tip":"Currently active pregnancies"},
		{"label":"PREGNANCY LOSSES","value":str(GameState.lifetime_pregnancy_losses),"note":"%d stillbirths" % GameState.lifetime_stillbirths,"note_color":Tokens.MUTED,"tip":"Losses before and at birth"},
		{"label":"MATERNAL DEATHS","value":str(GameState.lifetime_maternal_deaths),"note":"","note_color":Tokens.RED,"tip":"Deaths in childbirth"},
		{"label":"NEONATAL DEATHS","value":str(GameState.lifetime_neonatal_deaths),"note":"first month of life","note_color":Tokens.RED,"tip":"Deaths in the first month"},
	]
	var mortality:Dictionary=GameState.simulation_metrics.get("mortality_components",{})
	var mortality_items:Array=[]
	var top:=0.001
	for cause in mortality: top=maxf(top,float(mortality[cause]))
	for cause in mortality:
		var amount:=float(mortality[cause])
		if amount<=0.0: continue
		mortality_items.append({"name":String(cause).capitalize().replace("_"," "),"value":"%.2f%% / yr" % (amount*100.0),"ratio":amount/top,"color":Tokens.RED,"tip":"Modeled contribution to mortality under current conditions; this is not a lifetime death count"})
	var blocks:Array=[
		Charts.population("civilization"),
		{"type":"tiles","heading":"MATERNITY & INFANCY","items":maternity_items},
	]
	var records:=grouped_deaths(GameState.demographic_ledger)
	if _sub==1:
		records.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return int(a.last_day)>int(b.last_day))
		return {"kpis":kpis,"brief":{},"blocks":_death_pages(records,false)}
	blocks.append_array(_death_pages(death_summary(GameState.demographic_ledger),true))
	if not mortality_items.is_empty():
		blocks.append({"type":"bars","heading":"CURRENT MORTALITY RISK","note":"annual pressure now · not historical totals","items":mortality_items})
	var profile:Dictionary=CivilizationSystem.player_population_function_profile()
	blocks.append({"type":"tiles","heading":"WHERE EVERYONE IS","items":[
		{"label":"PRODUCTIVE","value":str(int(profile.get("productive",0))),"note":"direct work","note_color":Tokens.GREEN,"tip":"People in direct productive roles"},
		{"label":"SUPPORT","value":str(int(profile.get("support",0))),"note":"care and coordination","note_color":Tokens.MUTED,"tip":"People sustaining others"},
		{"label":"DEPENDENT","value":str(int(profile.get("dependent",0))),"note":"children and elders","note_color":Tokens.MUTED,"tip":"People supported by the rest"},
		{"label":"AWAY","value":str(int(profile.get("absent",0))+int(profile.get("mobilized",0))),"note":"missions and arms","note_color":Tokens.AMBER,"tip":"Physically absent or mobilized"},
	]})
	var workforce:=GameState.workforce_capacity_snapshot()
	blocks.append({"type":"text","heading":"PEOPLE AND EFFECTIVE WORK","text":"%d assigned people provide %.1f effective workers across current jobs. %d returned veterans have lasting injuries. They remain living population; heavy carrying, construction and extraction lose more capacity than knowledge or administration. Temporary military wounds remain in recovery and are not counted twice here." % [int(workforce.people),float(workforce.effective_workers),int(workforce.lasting_injuries)]})
	return {"kpis":kpis,"brief":{},"blocks":blocks}

func signature()->Array:
	return [death_page,summary_page,GameState.demographic_ledger.size(),GameState.strategic_history.get("last_day",-1),GameState.civilian_injuries.duplicate(true),GameState.population_allocations.duplicate(true),GameState.population_total,GameState.lifetime_births,GameState.lifetime_deaths,int(GameState.pregnancy_summary().get("active",0)),GameState.housing_capacity,float(GameState.simulation_metrics.get("housing_ratio",-1.0)),GameState.simulation_metrics.get("mortality_components",{}).duplicate(true)]

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
		result.append({"last_day":int(group.last),"name":group.place,"value":"%d death%s" % [int(group.count),"" if int(group.count)==1 else "s"],"sub":"%s · %s" % [String(group.cause),"Day %d" % int(group.first) if group.first==group.last else "Days %d–%d" % [int(group.first),int(group.last)]],"tip":"%d original records retained; grouped within 30-day periods." % int(group.records),"accent":Tokens.RED})
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
		rows.append({"name":cause,"value":"%d deaths"%int(group.count),"count":int(group.count),"sub":"%d locations · %d retained records"%[group.places.size(),int(group.records)],"accent":Tokens.RED})
	rows.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return int(a.count)>int(b.count) if a.count!=b.count else String(a.name)<String(b.name))
	return rows

func _death_pages(rows:Array,summary:bool)->Array:
	var page:=summary_page if summary else death_page
	var pages:=maxi(1,ceili(rows.size()/float(PAGE_SIZE)))
	page=clampi(page,0,pages-1)
	if summary:summary_page=page
	else:death_page=page
	var heading:="DEATHS BY CAUSE" if summary else "DATED DEATH RECORDS"
	if rows.is_empty():return [{"type":"text","heading":heading,"text":"No deaths have been recorded."}]
	var blocks:Array=[{"type":"rows","heading":heading,"items":rows.slice(page*PAGE_SIZE,(page+1)*PAGE_SIZE)},{"type":"text","text":"Totals here cover retained records. Lifetime deaths remain above. Open Death Records for dates and places." if summary else "Grouped by place, cause and 30-day period; newest first. Original records are retained."}]
	if pages>1:blocks.append({"type":"actions","heading":"PAGE %d / %d"%[page+1,pages],"items":[{"label":"PREVIOUS","disabled":page==0,"on_press":func():_change_death_page(summary,-1)},{"label":"NEXT","disabled":page==pages-1,"on_press":func():_change_death_page(summary,1)}]})
	return blocks

func _change_death_page(summary:bool,delta:int)->void:
	if summary:summary_page+=delta
	else:death_page+=delta
	hud.request_immediate_dock_refresh()
