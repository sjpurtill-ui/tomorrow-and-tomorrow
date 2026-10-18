extends "res://scripts/hud/content/dock_content_base.gd"
## The Chronicle rail entry: the one place for the people's history.
## - The years (hud/chronicle_feed.gd): a small count of years beside every
##   telling, newest first, grouped by year and filtered by kind.
## - Births and deaths: the people's lifetime record and what kills them now,
##   one line per fact (dense_blocks.gd fact_grid, table).
## - What was built: every work's record, one line each, and the materials
##   all building has used.
## Home has no History tab and the town's painted record is gone: the years
## hold every telling once, here.
const Chronicle:=preload("res://scripts/chronicle.gd")
const Years:=preload("res://scripts/hud/chronicle_year_model.gd")
const Icons:=preload("res://scripts/resource_icons.gd")
const Card:=preload("res://scripts/hud/chronicle_card.gd")
const EraWords:=preload("res://scripts/hud/era_words.gd")
const Population:=preload("res://scripts/hud/content/dock_detail_population_ledger.gd")
const Health:=preload("res://scripts/hud/content/dock_detail_health.gd")
## The complete record is read through the bounded Chronicle works browser.

func meta()->Dictionary:
	var voice:=Chronicle.voice()
	# Our nation's name once given: "THE STORY OF THE REEDFOLK" (nation_name.gd).
	var nation:=preload("res://scripts/nation_name.gd").in_sentence(String(GameState.nation_name))
	return {"eyebrow":"THE STORY OF %s" % (nation.to_upper() if nation!="" else "THE PEOPLE"),"title":String(voice.feed),"subtabs":["The years","Births and deaths","What was built"]}

func tab(sub:int)->Dictionary:
	if sub==1:return {"blocks":_lives_blocks()}
	if sub==2:return {"blocks":_works_blocks()}
	var today:=int(GameState.elapsed_days)
	return {"blocks":[{"type":"chronicle_feed","entries":Chronicle.entries("whisper"),"voice":Chronicle.voice(),
		"years":Years.build(Chronicle.data(),today,int(GameState.population_total)),"today":today}]}

static func _mark(glyph:String)->Texture2D:
	return Icons.moment_texture(glyph,Card.ACCENTS.get(glyph,Color("e1c27a")),36)

static func _n(value:int)->String:
	return EraWords.grouped(value)

# --- Births and deaths ------------------------------------------------------------

## The people's lifetime record, where everyone is now, what kills them now
## and every cause of death so far. The people's count and how long they
## live are on the top bar.
func _lives_blocks()->Array:
	var pregnancy:Dictionary=GameState.pregnancy_summary()
	var born:=int(GameState.lifetime_births)
	var lifetime:=[
		{"label":"Born","value":_n(born),"icon":_mark("birth"),"tip":"Every birth since the people set out."},
		{"label":"Died","value":_n(int(GameState.lifetime_deaths)),"icon":_mark("death"),"tone":"bad","tip":"Every death since the people set out."},
		{"label":"With child now","value":_n(int(pregnancy.get("active",0))),"icon":_mark("birth"),"tip":"Women carrying a child now: about %s births in the next year." % _n(roundi(float(GameState.simulation_metrics.get("births_expected_next_year",0.0))))},
		{"label":"Births due next year","value":_n(roundi(float(GameState.simulation_metrics.get("births_expected_next_year",0.0)))),"icon":_mark("birth"),"tip":"From the women with child now and those likely to conceive."},
		{"label":"Lost before birth","value":_n(int(GameState.lifetime_pregnancy_losses)),"icon":_mark("omen"),"tone":"warn","tip":"Children lost before birth, since the people set out."},
		{"label":"Born dead","value":_n(int(GameState.lifetime_stillbirths)),"icon":_mark("omen"),"tone":"warn","tip":"Children born dead, since the people set out."},
		{"label":"Mothers died giving birth","value":_n(int(GameState.lifetime_maternal_deaths)),"icon":_mark("death"),"tone":"bad","tip":"Mothers who died giving birth, since the people set out."},
		{"label":"Newborns died, first month","value":_n(int(GameState.lifetime_neonatal_deaths)),"icon":_mark("death"),"tone":"bad","tip":"Babies who died in their first month, since the people set out."},
	]
	var profile:Dictionary=CivilizationSystem.player_population_function_profile()
	# Those at work are the top bar's AT WORK (war_forces_model.gd at_work); not repeated here.
	var groups:=[["Tending others","support","care and keeping order","ceremony"],["Dependents","dependent","looked after by the rest","birth"],["Defense & away","away","on the road or under arms","scout"]]
	var everyone:=0
	for key:String in ["productive","support","dependent","absent","mobilized"]:everyone+=int(profile.get(key,0))
	var where:Array=[]
	for spec:Array in groups:
		var count:=int(profile.get("absent",0))+int(profile.get("mobilized",0)) if spec[1]=="away" else int(profile.get(String(spec[1]),0))
		where.append({"label":String(spec[0]),"value":_n(count),"bar":float(count)/maxf(1.0,float(everyone)),"icon":_mark(String(spec[3])),"tip":"%s: %s." % [String(spec[0]),String(spec[2])]})
	var workforce:=GameState.workforce_capacity_snapshot()
	where.append({"label":"Their work, in full-strength hands","value":preload("res://scripts/hud/production_plain.gd").number(float(workforce.effective_workers)),"icon":_mark("work"),
		"tip":"A different measure from AT WORK on the top bar: what everyone at work gets done, counted as people at full strength (the skilled count for more, the hurt and weary for less).%s" % ((" %d came home from fighting with lasting injuries; they manage lighter work better than carrying or building." % int(workforce.lasting_injuries)) if int(workforce.lasting_injuries)>0 else "")})
	var blocks:Array=[{"type":"fact_grid","heading":"Since we set out","min_column":250,"items":lifetime},{"type":"fact_grid","heading":"Where everyone is","min_column":250,"items":where}]
	var balance:Dictionary=preload("res://scripts/hud/population_readings.gd").balance(GameState);balance.type="population_balance";balance.heading="Population change";blocks.push_front(balance)
	blocks.append({"type":"actions","items":[focused_action("Search death records","Names, causes, places and the selected account",func()->Dictionary:return {"blocks":[{"type":"death_archive","records":GameState.demographic_ledger.filter(func(r:Dictionary)->bool:return String(r.get("kind",""))=="death")}]} )]})
	var killing:Dictionary=Health.mortality_block("How many people this cause kills each year at the present rate")
	if not killing.is_empty():blocks.append(killing)
	# Every cause of death so far, largest first.
	var causes:Array=Population.death_summary(GameState.demographic_ledger)
	var most:=1
	var named:=0
	for row:Dictionary in causes:most=maxi(most,int(row.count));named+=int(row.count)
	var rows:Array=[]
	for row:Dictionary in causes:
		rows.append({"cells":{"cause":String(row.name).capitalize(),"deaths":_n(int(row.count)),"where":String(row.sub)},"icon":_mark("death"),"bar":{"value":float(row.count)/float(most),"tone":"bad"}})
	blocks.append({"type":"table","heading":"Recorded deaths by cause","note":"the cause is kept for %s of %s deaths" % [_n(named),_n(int(GameState.lifetime_deaths))],"empty":"No one has died yet.","columns":[{"key":"cause","label":"CAUSE"},{"key":"deaths","label":"DEATHS","width":80,"align":"right"},{"key":"where","label":"WHERE","width":110}],"rows":rows})
	return blocks

# --- What was built ---------------------------------------------------------------

## Every work's record, newest first, one line each, and the materials all
## building has used.
func _works_blocks()->Array:
	var id:=String(GameState.selected_player_settlement_id)
	var summary:=GameState.building_ledger_summary(id)
	var records:Array=summary.get("records",[])
	var materials:Dictionary={}
	var phases:=0
	var damaged:=0
	var destroyed:=0
	for row:Dictionary in records:
		if bool(row.get("counts_materials",false)):
			for material:Variant in row.get("materials",{}):materials[material]=float(materials.get(material,0.0))+float(row.materials[material])
		var event:=String(row.get("event",""))
		if event in ["founded","started","infilled","rebuilt","legacy_completed","legacy_surviving_fabric"] or (event=="completed" and int(row.get("plot_id",-1))<0):phases+=1
		if event=="damaged":damaged+=1
		elif event=="destroyed":destroyed+=1
	var used:=0.0
	for material:Variant in materials:used+=float(materials[material])
	var facts:=[
		{"label":"Works recorded","value":_n(records.size()),"icon":_mark("work"),"tip":"Building, infill, renewal, damage and loss; routine days are not kept."},
		{"label":"Building phases","value":_n(phases),"icon":_mark("settlement"),"tip":"Founded, built, infilled and renewed."},
		{"label":"Material used","value":"%s units" % preload("res://scripts/hud/production_plain.gd").number(used),"icon":_mark("work"),"tip":"Every unit of material taken from the stores for building, infill and rebuilding."},
	]
	if damaged+destroyed>0:facts.append({"label":"Damaged or destroyed","value":"%d · %d destroyed" % [damaged+destroyed,destroyed],"icon":_mark("fire"),"tone":"bad" if destroyed>0 else "","tip":"Recorded damage and destruction."})
	var rows:Array=[]
	var ordered:=records.duplicate();ordered.reverse()
	for row:Dictionary in ordered:
		var parts:Array[String]=[]
		for material:Variant in row.get("materials",{}):parts.append("%s %s" % [preload("res://scripts/hud/production_plain.gd").number(float(row.materials[material])),String(material).to_lower()])
		rows.append({"key":str(row.get("id",[row.get("day",0),row.get("event",""),row.get("kind","")])),"title":String(row.get("kind","Building")).replace("_"," ").capitalize(),
			"date":preload("res://scripts/calendar_date.gd").words(int(row.get("day",0)),true),"event":String(row.get("event","recorded")).replace("_"," ").capitalize(),
			"materials":", ".join(parts) if not parts.is_empty() else "none recorded","note":String(row.get("note","")),"place":String(row.get("settlement_name",""))})
	var material_rows:Array=[]
	var names:Array=materials.keys();names.sort_custom(func(a:Variant,b:Variant)->bool:return float(materials[a])>float(materials[b]))
	for material:Variant in names:material_rows.append({"label":String(material),"value":"%s units" % preload("res://scripts/hud/production_plain.gd").number(float(materials[material]))})
	return [{"type":"chronicle_works","facts":facts,"records":rows,"materials":material_rows}]

func signature()->Array:
	var entries:Array=GameState.chronicle.get("entries",[])
	var annals:Array=GameState.chronicle.get("annals",[]) if GameState.chronicle.get("annals") is Array else []
	return [entries.size(),String((entries[0] as Dictionary).get("key","")) if not entries.is_empty() else "",GameState.known_discoveries.size(),annals.size(),int(GameState.elapsed_days)/365,
		GameState.lifetime_deaths,GameState.lifetime_births,GameState.demographic_ledger.size(),GameState.building_ledger.size() if GameState.get("building_ledger") is Array else 0]
