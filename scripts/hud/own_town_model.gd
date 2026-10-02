extends RefCounted
## OUR OWN TOWN, as its page tells it (settlement_overview.gd). Every figure
## is the one its owning dock shows, read from the same ledger: the Health
## page's lives, the Food page's stores and water, the Buildings page's roofs,
## repair and works, the Military ledger's levy and walls, and the city ledger
## a stranger's scout would count. Nothing here makes a second estimate.
##
## facts() must run inside the town's own scope (the Settlement dock's tab()
## wraps it in SettlementModel.with_city_resources and with_local_population);
## strength() reads who would defend it (the home levy, watch and walls, or
## the town's own watch) outside it, as the Military ledger does. The towns
## of strangers appear only as the bands our scouts brought home
## (city_intelligence.known_cities), each with its age.
const EraWords:=preload("res://scripts/hud/era_words.gd")
const V:=preload("res://scripts/hud/city_report_visuals.gd")
const Words:=preload("res://scripts/hud/home_plain.gd")
const Plain:=preload("res://scripts/hud/production_plain.gd")
const Indicators:=preload("res://scripts/civilization_indicators.gd")
const Construction:=preload("res://scripts/settlement_construction.gd")
const Identity:=preload("res://scripts/city_map_identity.gd")
const Shelter:=preload("res://scripts/hud/shelter_status.gd")
const Goods:=preload("res://scripts/civilian_goods.gd")
const Combat:=preload("res://scripts/civilization_combat.gd")
const Labels:=preload("res://scripts/hud/city_labels.gd")

## The page's groups and their rows, in order. The foreign page's groups,
## plus what only we can know.
const GROUPS:=[["THE PEOPLE",["population","life_expectancy","infant_mortality","learning"]],["STRENGTH",["garrison","fortification","damage"]],["LIVELIHOOD",["supply","water","production","logistics"]],["HOMES AND WORKS",["roofs","works","building"]]]
## The dock that owns each figure: [section, sub]. "population" opens the
## town's own ages and families.
const OWNERS:={"life_expectancy":["health",0,"Health"],"infant_mortality":["health",0,"Health"],"learning":["inquiry",0,"Research"],"garrison":["military",0,"Military"],"fortification":["military",0,"Military"],"damage":["construction",0,"Buildings"],
	"supply":["economy",0,"Food"],"water":["economy",0,"Food"],"production":["production",0,"Production"],"logistics":["economy",1,"Materials"],"roofs":["construction",0,"Buildings"],"works":["construction",1,"Buildings"],"building":["construction",1,"Buildings"]}
## Foreign towns drawn for comparison, most recently seen first.
const MAX_TOWNS:=3
## The foreign field each of our rows is compared with.
const FOREIGN_KEY:={"population":"population","life_expectancy":"life_expectancy","infant_mortality":"infant_mortality","learning":"education","garrison":"garrison","fortification":"fortification","damage":"damage","supply":"supply","production":"production","logistics":"logistics"}
const TENS:=["","","twenty","thirty","forty","fifty","sixty","seventy","eighty","ninety"]
const TEENS:=["ten","eleven","twelve","thirteen","fourteen","fifteen","sixteen","seventeen","eighteen","nineteen"]

# --------------------------------------------------------------------------
# The ledger, read once
# --------------------------------------------------------------------------

## Who defends the town if it is attacked now, as its battle musters them
## (civilization_combat.gd defenders): at home the trained levy and home's
## share of the watch, with the home walls; any other town of ours its share
## of the watch and no walls; a town another people holds (home too, once
## taken) none of ours.
## `defenders` is the one count its map badge shows too. Read unscoped, as
## the Military ledger does.
static func strength(primary:bool,settlement_id:String="")->Dictionary:
	var record:=SettlementModel.settlement_record(settlement_id)
	if record.is_empty() and primary:
		for city:Dictionary in GameState.player_settlements:
			if bool(city.get("primary",false)):record=city;break
	var held_by:=String(record.get("occupied_by",""))
	var guard:=Combat.defenders_of(record)
	if not primary:
		return {"town":true,"held_by":held_by,"fighters":0,"watch":guard,"defenders":guard,"capital":_capital_name(),
			"wall_stage":0,"wall_name":"Open ground","wall_integrity":1.0,"wall_words":""}
	var defense:Dictionary=MilitaryCampaign.settlement_defense_snapshot()
	var home:=Combat.home_defenders() if held_by.is_empty() else {"trained":0,"watch":0}
	return {"held_by":held_by,"fighters":int(home.trained),"watch":int(home.watch),"defenders":guard if not record.is_empty() else int(home.trained)+int(home.watch),
		"wall_stage":int(defense.get("stage",0)),"wall_name":String(defense.get("short","Open ground")),"wall_integrity":float(defense.get("integrity",1.0)),
		"wall_words":String(defense.get("description",""))}

## The first town's name, lettered as the map letters it (city_labels.gd
## chart_name of the home label): where our trained fighters live. "home"
## before it has one.
static func _capital_name()->String:
	var name:=String(GameState.settlement_name).strip_edges()
	return Labels.chart_name(name.to_upper()) if name!="" else "home"

## Every exact figure of the town in scope. `settlement` is the dock's
## selected settlement snapshot; `strong` is strength() for this town.
static func facts(settlement:Dictionary,strong:Dictionary={})->Dictionary:
	var id:=String(settlement.get("id",""))
	var record:Dictionary=SettlementModel.settlement_record(id) if id!="" else {}
	var primary:=id=="" or bool(record.get("primary",settlement.get("primary",false)))
	var metrics:Dictionary=GameState.simulation_metrics
	var health:=Indicators.health()
	var science:=Indicators.science()
	var population:=int(settlement.get("population",GameState.population_total))
	var flow:={"produced":float(metrics.get("food_production",0.0)),"eaten":float(metrics.get("food_eaten",0.0)),"spoiled":float(metrics.get("food_spoilage",0.0)),"missions":FoodSystem.issued_on_day(int(GameState.elapsed_days)),"net":float(metrics.get("food_net",0.0))}
	var definitions:=Construction._settlement_definitions()
	var known:=0
	for project:Dictionary in definitions:
		var discovery:=String(project.get("discovery",""))
		if String(project.name) in GameState.settlement_completed or discovery=="" or discovery in GameState.known_discoveries:known+=1
	var current:=Construction._current_settlement_project()
	var building:Dictionary={}
	if not current.is_empty():
		# The Buildings page's own reading of the project (state, progress, blockers).
		building=preload("res://scripts/hud/content/dock_content_construction.gd").new(null,null)._project(current,current,false)
	var out:={"id":id,"name":String(settlement.get("name",GameState.settlement_name)),"primary":primary,
		"classification":String(settlement.get("classification","settlement")).to_lower(),
		"occupied":String(record.get("occupied_by","")),"founded_day":int(settlement.get("founded_day",record.get("founded_day",0))),
		"population":population,"places":maxi(0,int(GameState.housing_capacity)),
		"shelter":Shelter.describe(GameState.settlement_completed,GameState.housing_capacity,population,Construction.carried_places()),
		"life":float(health.life_expectancy),"infant":float(health.infant_mortality_per_1000),
		"keepers":float(science.minds),"education":float(science.education),"known":GameState.known_discoveries.size(),
		"food_days":float(metrics.get("food_days",-1.0)),"food_reported":metrics.has("food_days"),"flow":flow,
		"water":(GameState.water_metrics as Dictionary).duplicate(),
		"material":float(metrics.get("material_capacity",0.0)),"logistics":float(metrics.get("logistics",0.0)),
		"hauling":GameState.material_metrics.get("flow_ratio",null),"goods":Goods.coverage(),
		"condition":float(SettlementModel.city_form().get("condition",1.0)),"broken":broken_share(),
		"completed":(GameState.settlement_completed as Array).duplicate(),"works_known":maxi(known,GameState.settlement_completed.size()),
		"building":building,"strength":strong.duplicate()}
	return out

## The share of the town's buildings standing damaged or in ruins, from its
## own fabric (the plots the map draws). Only the sketch uses it.
static func broken_share()->float:
	var standing:=0;var broken:=0
	for plot:Dictionary in GameState.settlement_plots:
		if String(plot.get("land_use","")) in ["field","pasture","water","waste"]:continue
		var status:=String(plot.get("status","active"))
		if status in ["reclaimed","vacant"]:continue
		standing+=1
		if status in ["damaged","ruin"]:broken+=1
	return float(broken)/float(standing) if standing>0 else 0.0

# --------------------------------------------------------------------------
# The towns of strangers, as our scouts brought them home
# --------------------------------------------------------------------------

## Up to MAX_TOWNS foreign towns our scouts have reported with any figure,
## most recently seen first. Towns we hold are told by our garrison, not here.
static func foreign_towns(limit:int=MAX_TOWNS)->Array:
	var intel=CivilizationSystem.city_intelligence
	if intel==null:return []
	var towns:Array=[]
	for city:Dictionary in intel.known_cities("player"):
		if String(city.get("civ_id",""))=="player" or String(city.get("controller",""))=="player":continue
		if (city.get("fields",{}) as Dictionary).is_empty():continue
		towns.append(city)
	towns.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
		if int(a.get("observed_day",-1))!=int(b.get("observed_day",-1)):return int(a.get("observed_day",-1))>int(b.get("observed_day",-1))
		return String(a.get("name",""))<String(b.get("name","")))
	return towns.slice(0,limit)

## A people's band colour, from the one emblem engine.
static func town_color(city:Dictionary)->Color:
	var accent:Color=Identity.foreign(String(city.get("civ_id",""))).get("accent",Color("7c8588"))
	return accent.darkened(0.18)

## The legend under which the bands are drawn.
static func legend(towns:Array)->Array:
	var out:Array=[]
	for city:Dictionary in towns:out.append({"name":String(city.get("name","A town")),"color":town_color(city),"seen":EraWords.ago(int(city.get("observed_day",-1)))})
	return out

## Each known town's band for one of our rows: only returned estimates, with
## the town's name and the age of the sighting. Empty when none was seen.
static func marks(key:String,towns:Array)->Array:
	var field_key:=String(FOREIGN_KEY.get(key,""))
	if field_key=="" or field_key not in V.shown_keys():return []
	var out:Array=[]
	for city:Dictionary in towns:
		var field:Dictionary=(city.get("fields",{}) as Dictionary).get(field_key,{})
		if field.is_empty():continue
		var band:=V.bounds(field)
		var words:=V.words(field_key,field)
		# Repair is the whole of the town less its damage.
		if key=="damage":
			band=Vector2(1.0-band.y,1.0-band.x)
			words="no damage" if words=="none seen" else words+" damage"
		out.append({"name":String(city.get("name","A town")),"low":band.x,"high":band.y,"color":town_color(city),"words":words,
			"seen":EraWords.ago(int(field.get("observed_day",city.get("observed_day",-1))))})
	return out

# --------------------------------------------------------------------------
# Rows
# --------------------------------------------------------------------------

## The page's groups: [{title, rows:[row]}]. A row carries its key, label,
## value, an optional coloured note, the exact number it shows, where its
## bar sits (own, top), the foreign marks and the dock that owns it.
static func groups(f:Dictionary,towns:Array=[])->Array:
	var out:Array=[]
	for group:Array in GROUPS:
		var rows:Array=[]
		for key:String in group[1]:
			var row:=row_for(key,f)
			if row.is_empty():continue
			row["marks"]=marks(key,towns)
			# A count with no natural scale draws a bar only beside a stranger's.
			if bool(row.get("relative",false)) and (row.marks as Array).is_empty():row["bar"]=false
			if row.get("capacity",false):row["top"]=1.0
			else:
				var top:=maxf(float(row.get("own",0.0)),0.0)
				for mark:Dictionary in row.marks:top=maxf(top,float(mark.high))
				row["top"]=maxf(float(row.get("top_min",1.0)),top*1.25)
			var owner:Array=OWNERS.get(key,["",0,""])
			row["section"]=String(owner[0]);row["sub"]=int(owner[1]);row["owner"]=String(owner[2])
			row["tip"]=_tip(row,f)
			rows.append(row)
		if not rows.is_empty():out.append({"title":String(group[0]),"rows":rows})
	return out

static func row_for(key:String,f:Dictionary)->Dictionary:
	var stage:=EraWords.stage()
	match key:
		"population":
			var people:=int(f.population)
			return {"key":key,"name":"Souls" if stage=="hearth" else "People","value":EraWords.people(people),"number":people,"own":float(people),"relative":true,
				"meaning":"How many live here now, every one counted."}
		"life_expectancy":
			var life:=float(f.life)
			return {"key":key,"name":EraWords.life_title(),"value":"%.1f years" % life if stage=="reckoned" else EraWords.life(life),"number":life,"own":life,"top_min":80.0,
				"meaning":"How long a child born here now can hope to live."}
		"infant_mortality":
			var infant:=float(f.infant)
			var said:=EraWords.babes_lost(infant)
			return {"key":key,"name":"Babes lost" if stage=="hearth" else "Infants buried" if stage=="lettered" else "Infant deaths","value":"%.0f / 1,000" % infant if stage=="reckoned" else said.get_slice(" ",0)+" in "+said.get_slice(" ",2),
				"number":infant,"own":infant,"top_min":1000.0,
				"meaning":"Babies who die before their first %s, as things stand." % ("winter" if stage=="hearth" else "year")}
		"learning":
			var keepers:=roundi(float(f.keepers))
			var education:=clampf(float(f.education),0.0,1.0)
			if stage=="reckoned":
				return {"key":key,"name":"Schooling","value":"%d%% schooled" % roundi(education*100.0),"number":education,"own":education,"capacity":true,
					"note":"%d scholars" % keepers,"meaning":"How many of us are schooled, and who works at learning."}
			var who:="lore keeper" if stage=="hearth" else "scholar"
			return {"key":key,"name":"Lore" if stage=="hearth" else "Learning","value":("%s %s%s" % [EraWords.grouped(keepers),who,"" if keepers==1 else "s"]) if keepers>0 else "no one yet",
				"number":keepers,"own":education,"capacity":true,"note":kept_words(education,stage),
				"meaning":"Who keeps what we know, and how well it is passed on."}
		"garrison":
			# Everyone who would fight here today: the count on the map badge.
			var s:Dictionary=f.get("strength",{})
			var guard:=maxi(0,int(s.get("defenders",0)))
			if String(s.get("held_by",""))!="":
				return {"key":key,"name":"Fighters here","value":"none of ours","number":0,"own":0.0,"relative":true,
					"meaning":"Another people holds this town. None of ours stand guard here."}
			if s.is_empty() or bool(s.get("town",false)):
				return {"key":key,"name":"Fighters here","value":("%s on watch" % EraWords.grouped(guard)) if guard>0 else "no one on watch","number":guard,"own":float(guard),"relative":true,
					"meaning":"Townsfolk who take up arms when raiders come. Our trained fighters stay at %s unless a general sends them." % String(s.get("capital","home"))}
			var trained:=int(s.fighters)
			var value:="no one"
			if trained>0:value="%s fighter%s" % [EraWords.grouped(guard),"" if guard==1 else "s"]
			elif guard>0:value="%s on watch" % EraWords.grouped(guard)
			return {"key":key,"name":"Fighters here","value":value,"number":guard,"own":float(guard),"relative":true,
				"note":("%s trained" % EraWords.grouped(trained)) if trained>0 and guard>trained else "","meaning":"Our trained fighters, and townsfolk who take up arms when raiders come."}
		"fortification":
			var s:Dictionary=f.get("strength",{})
			if s.is_empty() or int(s.wall_stage)<=0:
				return {"key":key,"name":V.label("fortification"),"value":"none","number":0,"own":0.0,"capacity":true,"stage":0,
					"meaning":"No walls have been raised here yet."}
			var stage_index:=int(s.wall_stage)
			var integrity:=float(s.wall_integrity)
			return {"key":key,"name":V.label("fortification"),"value":String(s.wall_name) if stage_index>0 else "none","number":stage_index,"own":stage_index/5.0,"capacity":true,"stage":stage_index,
				"note":"needs repair" if stage_index>0 and integrity<0.7 else "","note_tone":"warn",
				"meaning":String(s.wall_words)}
		"damage":
			var condition:=clampf(float(f.condition),0.0,1.0)
			# A stranger's damage is war damage; our repair also counts wear. Their
			# sightings are told in the tooltip, not drawn against our scale.
			return {"key":key,"name":"Repair" if stage!="reckoned" else "Condition","value":repair_words(condition) if stage=="hearth" else "%d%%" % roundi(condition*100.0),"bands":false,
				"number":roundi(condition*100.0),"own":condition,"capacity":true,"meaning":"How well our buildings are kept up. Builders mend them; war, fire and neglect wear them."}
		"supply":
			var days:=float(f.food_days)
			var reading:=Words.food(days,f.flow,bool(f.food_reported) and days>=0.0)
			var value:=String(reading.headline)
			if not bool(f.food_reported) or days<0.0:value="not counted yet"
			elif days<=0.05:value="none left"
			elif days>=3650.0:value="for years"
			else:value=value.trim_prefix("Food lasts ")
			return {"key":key,"name":V.label("supply"),"value":value,"number":days,"own":maxf(days,0.0),"top_min":365.0,
				"note":String(reading.trend) if String(reading.trend)!="steady" and bool(f.food_reported) else "","note_tone":"good" if String(reading.trend)=="rising" else "bad",
				"reading":reading,"meaning":"How long the food put by would last us."}
		"water":
			var water:Dictionary=f.water
			var reading:=Words.water(water)
			var ratio:=float(reading.get("ratio",-1.0))
			var value:="not counted yet"
			if ratio>=0.98:value="enough for all"
			elif ratio>=0.1:value="%d in 10 drink enough" % roundi(ratio*10.0)
			elif ratio>=0.0:value="almost none drink enough"
			return {"key":key,"name":"Water","value":value,"number":ratio,"own":maxf(ratio,0.0),"capacity":true,
				"note_tone":String(reading.get("tone","muted")),"reading":reading,"meaning":"Who has the water they need each day."}
		"production":
			var capacity:=clampf(float(f.material),0.0,1.0)
			return {"key":key,"name":V.label("production"),"value":V.words("production",_exact(capacity)),"number":capacity,"own":capacity,"capacity":true,
				"meaning":"How busy our makers are."}
		"logistics":
			var capacity:=clampf(float(f.logistics),0.0,1.0)
			return {"key":key,"name":V.label("logistics"),"value":V.words("logistics",_exact(capacity)),"number":capacity,"own":capacity,"capacity":true,
				"meaning":"How easily food and goods are carried home."}
		"roofs":
			var people:=int(f.population);var places:=int(f.places)
			var outside:=maxi(0,people-places)
			return {"key":key,"name":"Roofs" if stage=="hearth" else "Houses","value":"room for %s" % EraWords.grouped(places),"number":places,
				"own":float(mini(people,places))/float(maxi(1,people)),"capacity":true,
				"note":"%s sleep out" % EraWords.grouped(outside) if outside>0 else "a roof for all","note_tone":"bad" if outside>0 else "good",
				"meaning":String(f.shelter.detail)}
		"works":
			var built:=(f.completed as Array).size()
			var known:=maxi(built,int(f.works_known))
			return {"key":key,"name":"Works built","value":"%d of %d" % [built,known],"number":built,"own":float(built)/float(maxi(1,known)),"capacity":true,
				"meaning":"Shared works the people have raised here, of those they know how to raise."}
		"building":
			var project:Dictionary=f.building
			if project.is_empty():
				return {"key":key,"name":"Building now","value":"nothing","number":0.0,"own":0.0,"capacity":true,"meaning":"No shared work is under way."}
			var progress:=clampf(float(project.get("progress",0.0)),0.0,1.0)
			var waiting:=not bool(project.get("active",false))
			return {"key":key,"name":"Building now","value":String(project.name),"number":progress,"own":progress,"capacity":true,
				"note":EraWords.way_along(progress) if not waiting else "waiting","note_tone":"warn" if waiting else "muted",
				"state":String(project.get("state","")),"meaning":"It "+String(project.get("effect","serves the town"))+"."}
	return {}

## How well what is known is kept and passed on (the education index), said
## of the thing that keeps it: the lore told at the fire, then the records.
static func kept_words(education:float,stage:String="hearth")->String:
	if stage=="hearth":
		if education>=0.8:return "lore well passed on"
		if education>=0.6:return "lore passed on steadily"
		if education>=0.4:return "lore passed on in part"
		if education>=0.2:return "lore thinly passed on"
		return "lore barely passed on"
	if education>=0.8:return "records well kept"
	if education>=0.6:return "records kept"
	if education>=0.4:return "records patchy"
	if education>=0.2:return "records thin"
	return "records scarce"

static func _exact(value:float)->Dictionary:
	return {"low":value,"high":value,"observed_low":value,"observed_high":value}

## The Buildings page's condition, in the words of a people who do not count
## in hundredths.
static func repair_words(condition:float)->String:
	if condition>=0.9:return "sound"
	if condition>=0.75:return "fair"
	if condition>=0.5:return "worn"
	if condition>=0.25:return "broken"
	return "ruined"

## A row's tooltip: what it means, the exact figure with its source, and each
## known town's band with the age of the sighting.
static func _tip(row:Dictionary,f:Dictionary)->String:
	var lines:PackedStringArray=[String(row.get("meaning",""))]
	var key:=String(row.key)
	match key:
		"garrison":
			var s:Dictionary=f.get("strength",{})
			if not s.is_empty() and not bool(s.get("town",false)) and int(s.fighters)>0 and int(s.watch)>0:
				lines.append("%s trained, %s townsfolk on watch." % [EraWords.grouped(int(s.fighters)),EraWords.grouped(int(s.watch))])
		"fortification":
			var s:Dictionary=f.get("strength",{})
			if not s.is_empty() and int(s.wall_stage)>0:lines.append("They stand %s whole." % ("mostly" if float(s.wall_integrity)>=0.7 else "only partly") if EraWords.hearth() else "They stand %d%% whole." % roundi(float(s.wall_integrity)*100.0))
		"damage":
			if not EraWords.hearth():lines.append("Condition %d%%, as the Buildings page shows." % int(row.number))
			if not (row.get("marks",[]) as Array).is_empty():lines.append("What our scouts saw of theirs:")
		"supply":
			var reading:Dictionary=row.get("reading",{})
			if bool(f.food_reported):lines.append(String(reading.get("sentence","")));lines.append(Words.flow_sentence(f.flow))
		"water":
			var reading:Dictionary=row.get("reading",{})
			if reading.has("sentence"):lines.append(String(reading.sentence))
			var water:Dictionary=f.water
			if float(water.get("required_today",0.0))>0.0:lines.append("Yesterday %s drinks were fetched for the %s needed." % [Plain.number(float(water.get("collected_today",0.0))),Plain.number(float(water.required_today))])
		"production":
			lines.append("Tools and gear: %s." % _goods_words(float(f.goods)))
		"logistics":
			if f.hauling!=null and float(f.hauling)>0.05:lines.append(_first_up(String(Words.supply(0.0,0.0,f.hauling).carry_words))+".")
		"works":
			if not (f.completed as Array).is_empty():lines.append("Built: %s." % ", ".join(PackedStringArray(f.completed)))
		"building":
			if String(row.get("state",""))!="" and String(row.value)!="nothing":lines.append("Now: %s." % String(row.state))
		"learning":
			lines.append(("We know %s ways of doing things." if EraWords.hearth() else "We have learned %s things.") % EraWords.grouped(int(f.known)))
			lines.append("The bar shows how well what we know is kept and passed on.")
	for mark:Dictionary in row.get("marks",[]):
		lines.append("%s: %s, seen %s." % [String(mark.name),String(mark.words),String(mark.seen)])
	lines.append("Opens %s." % ("this town's ages and families" if key=="population" else "the %s page" % String(row.get("owner",""))))
	var said:PackedStringArray=[]
	for line:String in lines:
		if line.strip_edges()!="":said.append(line)
	return "\n".join(said)

static func _goods_words(coverage:float)->String:
	if coverage>=0.9:return "every household has what it needs"
	if coverage>=0.6:return "most households have what they need"
	if coverage>=0.3:return "half the households have what they need"
	return "few households have what they need"

static func _first_up(text:String)->String:
	return text.left(1).to_upper()+text.substr(1) if text!="" else text

# --------------------------------------------------------------------------
# The leader's words and the sketch
# --------------------------------------------------------------------------

## A number as the leader would say it: words below a hundred, figures above.
static func spoken(value:int)->String:
	if value<0:return EraWords.grouped(value)
	if value<=12:return EraWords.count_word(value)
	if value<20:return String(TEENS[value-10])
	if value<100:return String(TENS[value/10])+("" if value%10==0 else "-"+EraWords.count_word(value%10))
	return EraWords.grouped(value)

## One plain line in the local leader's voice, from exact facts: how many we
## are and whether all have a roof, how long the food lasts, and the water.
## Trouble is said before good news; no sayings.
static func lead(f:Dictionary)->String:
	var people:=int(f.population);var places:=int(f.places)
	var parts:PackedStringArray=[]
	var outside:=maxi(0,people-places)
	parts.append("We are %s, %s" % [spoken(people),"%s without a roof" % spoken(outside) if outside>0 else "a roof for every one"])
	var days:=float(f.food_days)
	if bool(f.food_reported) and days>=0.0:
		var reading:=Words.food(days,f.flow,true)
		if days<=0.05:parts.append("the food is gone")
		else:parts.append(EraWords.store_span(days)+(", falling" if String(reading.trend)=="falling" else ", growing" if String(reading.trend)=="rising" else ""))
	var ratio:=float(Words.water(f.water).get("ratio",-1.0))
	if ratio>=0.98:parts.append("water for all")
	elif ratio>=0.1:parts.append("%s in ten drink enough" % spoken(roundi(ratio*10.0)))
	elif ratio>=0.0:parts.append("almost no one drinks enough")
	var line:="; ".join(parts)+"."
	return line.left(1).to_upper()+line.substr(1)

## How long ago the town was settled, in the people's own counting.
static func since(days:int)->String:
	if days<30:return "this season"
	if EraWords.hearth():
		if days<365:
			var moons:=maxi(1,roundi(days/29.5))
			return "a moon ago" if moons==1 else "%s moons ago" % spoken(moons)
		var winters:=roundi(days/365.0)
		return "a winter ago" if winters==1 else "%s winters ago" % spoken(winters)
	return Plain.span_text(float(days))+" ago"

## The sketch's inputs, from exact figures: houses for those under a roof in
## ink and pencil ones for those without, the walls by what stands, the levy
## at the gate, the stores, the well and the works. Our banner flies at the gate.
static func sketch_data(f:Dictionary,caption:String)->Dictionary:
	var people:=float(f.population);var housed:=minf(people,float(f.places))
	var fields:={"population":{"low":housed,"high":people,"observed_low":housed,"observed_high":people}}
	if float(f.broken)>0.0:fields["damage"]=_exact(clampf(float(f.broken),0.0,1.0))
	var s:Dictionary=f.get("strength",{})
	if int(s.get("defenders",0))>0:fields["garrison"]=_exact(float(s.defenders))
	if bool(f.food_reported) and float(f.food_days)>=0.0:fields["supply"]=_exact(float(f.food_days))
	if float(f.material)>0.0:fields["production"]=_exact(clampf(float(f.material),0.0,1.0))
	if float(f.logistics)>0.0:fields["logistics"]=_exact(clampf(float(f.logistics),0.0,1.0))
	var water:=float(Words.water(f.water).get("ratio",-1.0))
	return {"city_id":"own:"+String(f.id),"fields":fields,"fresh_level":5,"fresh_status":"","caption":"","held_caption":caption,
		"flag":String(f.get("occupied",""))=="","wall_stage":int(s.get("wall_stage",0)) if not s.is_empty() else 0,
		"wall_integrity":float(s.get("wall_integrity",1.0)) if not s.is_empty() else 1.0,"water":water,
		"works":(f.completed as Array).duplicate(),"food_days":float(f.food_days)}
