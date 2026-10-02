extends RefCounted
## PEOPLES WE KNOW: every people we have met, ranked, with our own people as
## a row to measure them by. The ledger of HOI4's and Victoria's diplomacy
## views, read at a glance (hud/peoples_known_board.gd draws it at the head of
## the Known World).
##
## AS WE KNOW IT. A foreign figure is only ever our estimate:
##   - each town's figures are its report in city_intelligence (known(): the
##     range our people saw, widened with the report's age), with the day it
##     was seen and who saw it (scouts, the watch, envoys, traders, spies...);
##   - a people's totals add up the towns we know they hold. Counts (people,
##     fighters, lore, hands at work) are summed, low with low and high with
##     high; levels (stores, crafts, lives, walls) are the towns' average,
##     weighted by how many live in each;
##   - fighters add the bands of theirs our lookouts saw in the last season.
## Nothing here reads their true numbers: not their civilization record, not
## city_intelligence.truth(), not their own state. A people with no town
## report is "unknown". Our own row is our own count, the top bar's figures
## (civilization_kpi_model.gd), in the same units the reports use.
##
## RANKED. Rows sort by any column, by how many they are at first. A people
## stands behind every people whose whole range lies above its own; where two
## ranges overlap, the two are "about level", for nobody can say which leads.
##
## Static. rows() turns plain inputs into rows (tests build them by hand);
## build() reads them from the live game; order() sorts them for the board.

const EraWords:=preload("res://scripts/hud/era_words.gd")
const WarLoop:=preload("res://scripts/war_loop.gd")
const KPI:=preload("res://scripts/hud/civilization_kpi_model.gd")
## The War screen owns the stance words (war_board.gd STANCES).
const WAR_BOARD_PATH:="res://scripts/hud/war_board.gd"

## The columns, left to right. "field": what each town reports; "add": how a
## people's towns add up ("sum" or "mean"); "fallback": an older people's
## index, shown in words when no town gives the main figure; "headline": its
## rank is shown under every value.
const COLUMNS:=[
	{"id":"name"},
	{"id":"towns","add":"count"},
	{"id":"people","field":"population","add":"sum","headline":true},
	{"id":"fighters","field":"garrison","add":"sum","headline":true},
	{"id":"stores","field":"supply","add":"mean","headline":true},
	{"id":"crafts","field":"production","add":"mean"},
	{"id":"lore","field":"science_capacity","add":"sum","fallback":"science"},
	{"id":"lives","field":"life_expectancy","add":"mean","fallback":"health"},
	{"id":"wealth","field":"gdp","add":"sum","headline":true},
	{"id":"walls","field":"fortification","add":"mean"},
	{"id":"between","add":"relation"},
	{"id":"envoys","add":"envoys"},
]
## The columns a people is ranked in.
const RANKED:=["towns","people","fighters","stores","crafts","lore","lives","wealth","walls"]
## Titles in the people's own words, by what they know (era_words.gd stages).
const TITLES:={
	"hearth":{"name":"People","towns":"Hearths","people":"How many","fighters":"Fighters","stores":"Stores","crafts":"Crafts","lore":"Lore","lives":"Lives","wealth":"Hands","walls":"Walls","between":"Between us","envoys":"Envoys"},
	"lettered":{"name":"People","towns":"Towns","people":"How many","fighters":"Fighters","stores":"Stores","crafts":"Crafts","lore":"Learning","lives":"Lives","wealth":"Labour","walls":"Walls","between":"Between us","envoys":"Envoys"},
	"reckoned":{"name":"People","towns":"Cities","people":"Population","fighters":"Soldiers","stores":"Food","crafts":"Production","lore":"Science","lives":"Health","wealth":"Output","walls":"Defences","between":"Relations","envoys":"Envoys"},
}
## What each column means, for the header's pointer.
const MEANINGS:={
	"name":"Every people we have met. Their figures are our estimates.",
	"towns":"Their towns that we know of and that they still hold.",
	"people":"How many live in their towns that we know of.",
	"fighters":"Armed people seen guarding their towns, and their bands seen in the field.",
	"stores":"How long their food would last if cut off.",
	"crafts":"How busy their crafts and workshops looked.",
	"lore":"How many of them work at learning.",
	"lives":"How long their people usually live.",
	"wealth":"What their people make in a day, in working hands.",
	"walls":"How hard their towns would be to break into.",
	"between":"Peace, feud or war between us, and their ruler's trust in us.",
	"envoys":"Whether envoys pass between our peoples.",
}
## Bands of these kinds are not fighters.
const NOT_FIGHTERS:=["scout","expedition","migration","movement"]
## Sightings older than this no longer count (days): a season.
const BAND_MEMORY_DAYS:=90
## Levels in plain words before the statistical age: [upper bound, word].
const LEVEL_WORDS:=[[0.1,"none"],[0.3,"slight"],[0.55,"fair"],[0.8,"strong"],[INF,"great"]]


# --------------------------------------------------------------------------
# Gathering from the live game
# --------------------------------------------------------------------------

## The ledger as the board draws it: {stage, day, met (count of peoples),
## rows, unplaced (towns seen whose people we do not know)}.
static func build(day:int=-1)->Dictionary:
	if day<0:day=int(WorldSimulation.state.elapsed_days)
	var stage:=EraWords.stage()
	var records:=known_records(day)
	var peoples:=met_peoples(day)
	var all:=rows(peoples,records,sightings(day),our_count(),day,stage)
	return {"stage":stage,"day":day,"met":peoples.size(),"rows":all,"unplaced":unplaced(records)}

## Every town report in our book, aged to `day` (city_intelligence.known()).
static func known_records(day:int)->Array:
	var intel:Variant=CivilizationSystem.get("city_intelligence")
	var result:Array=[]
	if intel==null:return result
	for city_id:String in (intel.records as Dictionary).get("player",{}):
		var record:Dictionary=intel.known("player",city_id,day)
		if not record.is_empty():result.append(record)
	return result

## Every people we have met (the Known World's own count), with only the
## facts that lie between us: the feud or war, their ruler's trust, whether
## envoys pass, the War screen's stance, when we met and where their home is.
static func met_peoples(day:int)->Array:
	var result:Array=[]
	var by_id:={}
	for civ:Dictionary in CivilizationSystem.civilizations:by_id[String(civ.get("id",""))]=civ
	var mission:Dictionary=CivilizationSystem.diplomatic_mission
	for encounter:Dictionary in CivilizationSystem.contact_encounters_snapshot():
		var id:=String(encounter.get("civ_id",""))
		var civ:Dictionary=by_id.get(id,{})
		var relation:Dictionary=civ.get("player_relation",{}) if civ.get("player_relation") is Dictionary else {}
		var feud:=bool(WarLoop.feuding(id,day))
		var at_war:=bool(relation.get("at_war",false))
		var front:Dictionary=WarLoop._peek(id)
		var leader:=_leader(id)
		result.append({"civ_id":id,"name":String(encounter.get("name",civ.get("name","A people"))),
			"at_war":at_war,"treaty":String(relation.get("treaty","none")),"feud":feud,"hot":bool(WarLoop.hot(id,day)),
			"trust":float(leader.get("trust",0.0)),"withheld":_withholds_envoys(leader),
			"envoys_away":String(mission.get("civ_id",""))==id,"home_known":bool(encounter.get("home_location_known",false)),
			"home_position":(encounter.get("home_position",{}) as Dictionary).duplicate(),"met_day":int(encounter.get("day",-1)),
			"stance":String(front.get("stance","")) if feud or at_war else ""})
	return result

## A foreign ruler as the court knows them, read without making one ({} when
## no word has passed).
static func _leader(civ_id:String)->Dictionary:
	if int(ForeignDiplomacy.seed_value)!=int(WorldSimulation.state.world_seed):return {}
	var leader:Variant=ForeignDiplomacy.leaders.get(civ_id)
	return leader if leader is Dictionary else {}

## Their ruler has told us they send no more envoys, for a wrong done to theirs
## that is not yet set right (rival_rulers.gd withholds_envoys).
static func _withholds_envoys(leader:Dictionary)->bool:
	var character:Variant=leader.get("character")
	if not character is Dictionary or int((character as Dictionary).get("envoys_withheld",0))<=0:return false
	for grudge:Variant in (character as Dictionary).get("grudges",[]):
		if grudge is Dictionary and not bool(grudge.get("settled",false)) and String(grudge.get("source","")).get_slice(":",0).ends_with("_envoy"):return true
	return false

## Bands our lookouts can see now or saw within the season (their public
## estimates: civilization_system.local_observation_snapshot).
static func sightings(_day:int)->Array:
	var snapshot:Dictionary=CivilizationSystem.local_observation_snapshot()
	return (snapshot.get("visible",[]) as Array)+(snapshot.get("recent",[]) as Array)

## Our own people, counted: the top bar's own figures, our fighters and our
## walls. {name, values: {field: value}, towns: [{name, values}]}.
static func our_count()->Dictionary:
	var t:Dictionary=KPI.snapshot()
	var home:=int(MilitaryCampaign.home_army.get("troops",0))
	var fighters:=home
	for army:Variant in MilitaryCampaign.field_armies:
		if army is Dictionary:fighters+=maxi(0,int((army as Dictionary).get("troops",0)))
	var walls:=clampf(float(MilitaryCampaign.settlement_defense.get("stage",0))/5.0,0.0,1.0)
	var towns:Array=[]
	var cities:Array=t.get("cities",[])
	var index:=0
	# Each town's fighters as its battle musters them and as a stranger's
	# scout counts them (civilization_combat.gd defenders): like for like.
	var guards:Dictionary=preload("res://scripts/civilization_combat.gd").defenders_by_town()
	for city:Dictionary in GameState.player_settlements:
		if String(city.get("occupied_by","")) not in ["","player"]:continue
		var local:Dictionary=cities[index] if index<cities.size() else {}
		index+=1
		var values:={"population":float(local.get("population",0.0))}
		var use:=float(local.get("food_use",0.0))
		if use>0.0:values["supply"]=float(local.get("food_stock",0.0))/use
		values["garrison"]=float(guards.get(String(city.get("id","")),0))
		if bool(city.get("primary",false)):
			values["fortification"]=walls
		towns.append({"name":String(city.get("name","Settlement")),"values":values})
	var values:={"population":float(t.get("population",0)),"garrison":float(fighters),"production":clampf(float(GameState.simulation_metrics.get("material_capacity",0.0)),0.0,1.0),
		"science_capacity":float(t.get("science",0.0)),"life_expectancy":float(t.get("life",0.0)),"gdp":float(t.get("output",0.0)),"fortification":walls}
	if float(t.get("food_days",-1.0))>=0.0:values["supply"]=float(t.food_days)
	return {"name":our_name(),"values":values,"towns":towns}

## Our people's name as the world knows it (the nation's name, once it has one).
static func our_name()->String:
	var raw:=""
	if CivilizationSystem.has_method("_player_civilization_name"):raw=String(CivilizationSystem.call("_player_civilization_name")).strip_edges()
	if raw=="" or raw=="PLAYER CIVILIZATION":return "Our people"
	return title_case(raw) if raw==raw.to_upper() else raw

static func title_case(text:String)->String:
	var words:=text.to_lower().split(" ",false)
	for i in words.size():words[i]=words[i].substr(0,1).to_upper()+words[i].substr(1)
	return " ".join(words)

## Towns our people saw whose people they could not tell.
static func unplaced(records:Array)->Array:
	var result:Array=[]
	for record:Dictionary in records:
		if holder_of(record)=="":result.append({"city_id":String(record.get("city_id","")),"name":String(record.get("name",""))})
	return result


# --------------------------------------------------------------------------
# Rows
# --------------------------------------------------------------------------

## The ledger's rows from plain inputs:
##   peoples  [{civ_id, name, at_war, treaty, feud, hot, trust, withheld,
##            envoys_away, home_known, home_position, met_day, stance}]
##   records  town reports as city_intelligence.known() gives them
##   bands    public sightings {civ_id, kind, strength_estimate_low/high,
##            last_seen_day}
##   us       our_count(): {name, values, towns}; {} for no row of ours
static func rows(peoples:Array,records:Array,bands:Array,us:Dictionary,day:int,stage:String="")->Array:
	if stage=="":stage=EraWords.stage()
	var names:={}
	for people:Dictionary in peoples:names[String(people.civ_id)]=String(people.name)
	# Each report filed once under the people it was first seen with and under
	# its holder.
	var filed:={}
	for record:Dictionary in records:
		var seen_with:=String(record.get("civ_id",""))
		var holder:=holder_of(record)
		for id:String in ([seen_with] if holder==seen_with else [seen_with,holder]):
			if id=="":continue
			if not filed.has(id):filed[id]=[]
			(filed[id] as Array).append(record)
	var result:Array=[]
	for people:Dictionary in peoples:result.append(_people_row(people,filed.get(String(people.civ_id),[]),bands,names,day,stage))
	if not us.is_empty():result.append(_our_row(us,stage))
	for column:String in RANKED:rank(result,column)
	return result

## Who holds a town, as we last heard: its holder, else the people it was
## first seen with; "" when nobody could tell whose it is.
static func holder_of(record:Dictionary)->String:
	var controller:=String(record.get("controller",""))
	return controller if controller!="" else String(record.get("civ_id",""))

## One people's row from the reports of their towns (first seen with them, or
## held by them).
static func _people_row(people:Dictionary,records:Array,bands:Array,names:Dictionary,day:int,stage:String)->Dictionary:
	var id:=String(people.civ_id)
	var held:Array=[]
	var theirs:Array=[]
	for record:Dictionary in records:
		var holder:=holder_of(record)
		if holder==id:held.append(record)
		if holder==id or String(record.get("civ_id",""))==id:theirs.append(record)
	var seen:=bands_of(bands,id,day)
	var cells:={"name":{"text":String(people.name),"known":true},"towns":_towns_cell(held.size(),"Their towns that we know of and that they still hold.")}
	for column:Dictionary in COLUMNS:
		if not column.has("field"):continue
		cells[String(column.id)]=cell(column,held,stage,seen if String(column.id)=="fighters" else [])
	cells["between"]=relation_cell(people)
	cells["envoys"]=envoys_cell(people)
	var towns:Array=[]
	for record:Dictionary in theirs:towns.append(town_row(record,id,names,day,stage,people.get("home_position",{}) if bool(people.get("home_known",false)) else {}))
	towns.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
		if bool(a.theirs)!=bool(b.theirs):return bool(a.theirs)
		if bool(a.home)!=bool(b.home):return bool(a.home)
		return String(a.name)<String(b.name))
	return {"civ_id":id,"name":String(people.name),"us":false,"cells":cells,"fresh":freshness(theirs,day),"towns":towns,"bands":_bands_summary(seen),
		"contact":contact_words(people)}

## A people's figure, added up from the towns they hold: the range, how many
## towns gave it, how old the word is and who brought it.
static func cell(column:Dictionary,towns:Array,stage:String,bands:Array=[])->Dictionary:
	var id:=String(column.id)
	var field:=String(column.field)
	var giving:=_giving(towns,field)
	var unit:="main"
	if giving.is_empty() and column.has("fallback"):
		field=String(column.fallback)
		giving=_giving(towns,field)
		unit="index"
	if giving.is_empty() and bands.is_empty():
		return {"known":false,"text":"unknown" if id=="people" else "?","tip":("No town of theirs has been seen." if towns.is_empty() else "No report tells us this."),"unit":unit}
	var add:=String(column.add) if unit=="main" else "mean"
	var low:=0.0;var high:=0.0
	if add=="sum":
		for town:Dictionary in giving:
			var f:Dictionary=town.fields[field]
			low+=float(f.low);high+=float(f.high)
	elif not giving.is_empty():
		var weights:=_weights(giving)
		var total:=0.0
		for i in giving.size():
			var f:Dictionary=giving[i].fields[field]
			low+=float(f.low)*float(weights[i]);high+=float(f.high)*float(weights[i]);total+=float(weights[i])
		low/=maxf(total,0.0001);high/=maxf(total,0.0001)
	for band:Dictionary in bands:
		low+=float(band.low);high+=float(band.high)
	var partial:=add=="sum" and giving.size()<towns.size()
	var result:={"known":true,"low":low,"high":high,"unit":unit,"of":giving.size(),"towns":towns.size(),"partial":partial,"bands":bands.size()}
	result["text"]=value_text(id,low,high,false,partial,stage,unit)
	result["tip"]=_evidence_tip(giving,field,towns.size(),bands,partial)
	return result

## The towns whose report gives this figure.
static func _giving(towns:Array,field:String)->Array:
	var giving:Array=[]
	for town:Dictionary in towns:
		if (town.get("fields",{}) as Dictionary).has(field):giving.append(town)
	return giving

## Each town counts by how many live there, where that was seen.
static func _weights(towns:Array)->Array:
	var mids:Array=[]
	var told:=0.0;var count:=0
	for town:Dictionary in towns:
		var f:Dictionary=(town.get("fields",{}) as Dictionary).get("population",{})
		var mid:=(float(f.low)+float(f.high))*0.5 if not f.is_empty() else -1.0
		mids.append(mid)
		if mid>0.0:told+=mid;count+=1
	var fill:=told/float(count) if count>0 else 1.0
	for i in mids.size():
		if float(mids[i])<=0.0:mids[i]=fill
	return mids

## "From 2 of 3 towns · scouts, the watch · seen this season to a year ago."
static func _evidence_tip(giving:Array,field:String,towns:int,bands:Array,partial:bool)->String:
	var parts:=PackedStringArray()
	if not giving.is_empty():
		parts.append("From %s" % ("%d of %d towns" % [giving.size(),towns] if giving.size()<towns else ("their one town" if towns==1 else "all %d towns" % towns)))
		var sources:=PackedStringArray()
		var newest:=-1;var oldest:=-1
		for town:Dictionary in giving:
			var f:Dictionary=town.fields[field]
			var word:=source_word(String(f.get("source",town.get("source",""))),String(f.get("reference",town.get("reference",""))))
			if not word in sources:sources.append(word)
			var seen:=int(f.get("observed_day",-1))
			if seen>=0:
				newest=maxi(newest,seen)
				oldest=seen if oldest<0 else mini(oldest,seen)
		parts.append(", ".join(sources))
		if newest>=0:parts.append("seen %s" % ago(newest) if oldest==newest or ago(oldest)==ago(newest) else "seen %s to %s" % [ago(newest),ago(oldest)])
	if not bands.is_empty():
		parts.append("%d band%s seen in the field" % [bands.size(),"" if bands.size()==1 else "s"])
	var said:=" · ".join(parts)+"."
	if partial:said+=" Towns that gave no figure are not counted."
	return said+" Older word is less sure."

## Our own row: our own count, exact.
static func _our_row(us:Dictionary,stage:String)->Dictionary:
	var values:Dictionary=us.get("values",{})
	var cells:={"name":{"text":String(us.get("name","Our people")),"known":true},"towns":_towns_cell((us.get("towns",[]) as Array).size(),"Our own towns.")}
	for column:Dictionary in COLUMNS:
		if not column.has("field"):continue
		var id:=String(column.id)
		var field:=String(column.field)
		if not values.has(field):
			cells[id]={"known":false,"text":"?","tip":"Not yet counted.","unit":"main"}
			continue
		var value:=float(values[field])
		cells[id]={"known":true,"low":value,"high":value,"unit":"main","exact":true,"text":value_text(id,value,value,true,false,stage),"tip":"Our own count."}
	cells["between"]={"text":"","sub":"","tone":"muted","order":99,"tip":""}
	cells["envoys"]={"text":"","tone":"muted","order":99,"tip":""}
	var towns:Array=[]
	for town:Dictionary in us.get("towns",[]):
		var v:Dictionary=town.get("values",{})
		var shown:={}
		for pair:Array in [["people","population"],["fighters","garrison"],["stores","supply"],["walls","fortification"]]:
			shown[pair[0]]=value_text(String(pair[0]),float(v[pair[1]]),float(v[pair[1]]),true,false,stage) if v.has(pair[1]) else "—"
		towns.append({"city_id":"","name":String(town.get("name","")),"home":false,"theirs":true,"held":"us","cells":shown,"fresh":{"level":"ours","text":"our own count","source":""},"open":false})
	return {"civ_id":"player","name":String(us.get("name","Our people")),"us":true,"cells":cells,"fresh":{"level":"ours","text":preload("res://scripts/hud/hud_tokens.gd").sentence_case(EraWords.register()),"source":"","tip":"Our own count, today."},
		"towns":towns,"bands":{},"contact":[]}

static func _towns_cell(count:int,tip:String)->Dictionary:
	return {"known":true,"low":float(count),"high":float(count),"unit":"main","exact":true,"text":str(count),"tip":tip}


# --------------------------------------------------------------------------
# Words and numbers
# --------------------------------------------------------------------------

## EraWords.ago(), kept for the day: a ledger asks it of the same few days
## many times over.
static var _ago_today:=-1
static var _ago_said:={}
static func ago(day:int)->String:
	var today:=int(floor(GameState.elapsed_days))
	if today!=_ago_today:
		_ago_today=today
		_ago_said.clear()
	if not _ago_said.has(day):_ago_said[day]=EraWords.ago(day)
	return String(_ago_said[day])

## A figure in the people's own reckoning: counts rounded as a crowd is
## counted ("about 300", "250–400"), stores in days, lives in winters or
## years, levels in words before the statistical age and in hundredths after.
## Our own count is told exactly. "+" when some towns gave no figure.
static func value_text(column:String,low:float,high:float,exact:bool,partial:bool,stage:String,unit:String="main")->String:
	if unit=="index":return level_text(low,high,exact,stage)
	match column:
		"towns":return str(roundi(low))
		"people","fighters","wealth":return count_text(low,high,exact,partial,stage)
		"lore":return lore_text(low,high,exact,partial,stage)
		"stores":return days_text(low,high,exact,stage)
		"lives":return years_text(low,high,exact,stage)
		"crafts","walls":return level_text(low,high,exact,stage)
	return count_text(low,high,exact,partial,stage)

static func count_text(low:float,high:float,exact:bool,partial:bool,stage:String)->String:
	var text:String
	if exact:text=_count(roundf(low),stage)
	else:
		var a:=nice(low);var b:=maxi(a,nice(high))
		text=("about "+_count(a,stage)) if a==b else _count(a,stage)+"–"+_count(b,stage)
	return text+("+" if partial else "")

static func _count(value:float,stage:String)->String:
	if stage=="reckoned" and value>=1000000.0:return "%.1fm" % (value/1000000.0)
	if stage=="reckoned" and value>=10000.0:return "%dk" % roundi(value/1000.0)
	return EraWords.grouped(roundi(value))

## Two figures, as people count a crowd: 7, 35, 240, 1,200.
static func nice(value:float)->int:
	if value<20.0:return maxi(0,roundi(value))
	if value<100.0:return roundi(value/5.0)*5
	var step:=pow(10.0,floorf(log(value)/log(10.0))-1.0)
	return roundi(value/step)*roundi(step)

## Those who work at learning. Before the statistical age they are counted
## as people ("about 2", "under 1"); after it, in tenths while under ten.
static func lore_text(low:float,high:float,exact:bool,partial:bool,stage:String="reckoned")->String:
	if stage!="reckoned":
		if high<1.0:return "under 1"
		return count_text(low,high,exact,partial,stage)
	var fine:=high<10.0
	var a:=("%.1f" % low) if fine else EraWords.grouped(roundi(low))
	var b:=("%.1f" % high) if fine else EraWords.grouped(roundi(high))
	var text:=a if exact or a==b else a+"–"+b
	return text+("+" if partial else "")

static func days_text(low:float,high:float,exact:bool,stage:String)->String:
	var unit:=" d" if stage=="reckoned" else " days"
	var a:=roundi(low);var b:=maxi(a,roundi(high))
	if exact:return "%d%s" % [a,unit]
	return ("about %d" % a if a==b else "%d–%d" % [a,b])+unit

static func years_text(low:float,high:float,exact:bool,stage:String)->String:
	var unit:=String({"hearth":" winters","lettered":" years"}.get(stage," yr"))
	var a:=roundi(low);var b:=maxi(a,roundi(high))
	if exact or a==b:return "%d%s" % [a,unit]
	return "%d–%d%s" % [a,b,unit]

static func level_text(low:float,high:float,exact:bool,stage:String)->String:
	if stage=="reckoned":
		var a:=roundi(low*100.0);var b:=maxi(a,roundi(high*100.0))
		return "%d%%" % a if exact or a==b else "%d–%d%%" % [a,b]
	var first:=level_word(low);var last:=level_word(high)
	return first if exact or first==last else first+"–"+last

static func level_word(value:float)->String:
	for pair:Array in LEVEL_WORDS:
		if value<float(pair[0]):return String(pair[1])
	return "great"

## Who brought the word, in one or two plain words (kept per source).
static var _sources:={}
static func source_word(source:String,reference:String="")->String:
	var key:=source+"|"+reference.get_slice(":",0)
	if not _sources.has(key):
		if _sources.size()>=256:_sources.clear()
		_sources[key]=_source_word(source,reference)
	return String(_sources[key])

static func _source_word(source:String,reference:String)->String:
	var s:=source.to_lower();var ref:=reference.to_lower()
	if ref.begins_with("covert") or "spy" in s or "spies" in s or "covert" in s or "agent" in s:return "spies"
	if s.begins_with("shared by") or "envoy" in s or "messenger" in s or "delegat" in s:return "envoys"
	if "trade" in s or "caravan" in s or "merchant" in s:return "traders"
	if s.begins_with("air ") or "aerial" in s:return "air scouts"
	if "local observation" in s or "lookout" in s or "watch" in s or "nearby" in s:return "the watch"
	if "campaign" in s or "band" in s or "fighter" in s or "trail" in s or "battle" in s or ref.begins_with("war:") or ref.begins_with("battle:") or ref.begins_with("ruin:"):return "our fighters"
	if "hunter" in s:return "hunters"
	if "reconnaissance" in s or "scout" in s or "route" in s or "encounter" in s or ref.begins_with("scout:"):return "scouts"
	if "earlier" in s or "legacy" in s:return "old word"
	return "travellers"

## How fresh our word of a people is: their newest town report's mark
## (known(): recent within a month, aging within half a year, then stale),
## how long ago it was seen and who brought it.
static func freshness(records:Array,day:int)->Dictionary:
	if records.is_empty():return {"level":"none","text":"no town seen yet","source":"","tip":"Scouts or the watch must see one of their towns."}
	var newest:={}
	var oldest:=-1
	for record:Dictionary in records:
		var seen:=int(record.get("observed_day",-1))
		if seen<0:continue
		if newest.is_empty() or seen>int(newest.observed_day):newest=record
		oldest=seen if oldest<0 else mini(oldest,seen)
	if newest.is_empty():
		var first:Dictionary=records[0]
		return {"level":"undated","text":"undated","source":source_word(String(first.get("source","")),String(first.get("reference",""))),"tip":"Undated: only where it lies is known, not when it was seen."}
	var age:=maxi(0,day-int(newest.observed_day))
	var level:="recent" if age<=30 else ("aging" if age<=180 else "stale")
	var tip:=String({"recent":"Recent: seen within the month.","aging":"Aging: seen within half a year; it may have changed.","stale":"Stale: over half a year old; much may have changed."}[level])
	if oldest>=0 and oldest<int(newest.observed_day) and ago(oldest)!=ago(int(newest.observed_day)):tip+=" Our oldest word of them is from %s." % ago(oldest)
	return {"level":level,"text":ago(int(newest.observed_day)),"source":source_word(String(newest.get("source","")),String(newest.get("reference",""))),"age_days":age,"tip":tip}

## One of their towns as we know it, for the opened row.
static func town_row(record:Dictionary,people_id:String,names:Dictionary,day:int,stage:String,home:Dictionary={})->Dictionary:
	var holder:=holder_of(record)
	var fields:Dictionary=record.get("fields",{})
	var shown:={}
	for pair:Array in [["people","population"],["fighters","garrison"],["stores","supply"],["walls","fortification"]]:
		var f:Dictionary=fields.get(pair[1],{})
		shown[pair[0]]="?" if f.is_empty() else value_text(String(pair[0]),float(f.low),float(f.high),false,false,stage)
	var held:="them"
	if holder=="player":held="us"
	elif holder=="":held="not known"
	elif holder!=people_id:held=String(names.get(holder,"another people"))
	var at:Dictionary=record.get("position",{})
	var is_home:=not home.is_empty() and Vector2(float(at.get("x",0)),float(at.get("z",0))).distance_to(Vector2(float(home.get("x",0)),float(home.get("z",0))))<=1.0
	var seen:=int(record.get("observed_day",-1))
	var level:=String(record.get("freshness","undated"))
	if seen<0:level="undated"
	elif not level in ["recent","aging","stale"]:level="recent" if day-seen<=30 else ("aging" if day-seen<=180 else "stale")
	return {"city_id":String(record.get("city_id","")),"name":String(record.get("name","A town")),"home":is_home,"theirs":holder==people_id,"held":held,"cells":shown,
		"fresh":{"level":level,"text":ago(seen) if seen>=0 else "undated","source":source_word(String(record.get("source","")),String(record.get("reference","")))},"open":true}

## Their bands our lookouts saw in the last season: [{low, high, seen}].
static func bands_of(bands:Array,civ_id:String,day:int)->Array:
	var result:Array=[]
	for band:Dictionary in bands:
		if String(band.get("civ_id",""))!=civ_id or String(band.get("kind","")) in NOT_FIGHTERS:continue
		var seen:=int(band.get("last_seen_day",day))
		if day-seen>BAND_MEMORY_DAYS:continue
		result.append({"low":float(band.get("strength_estimate_low",0)),"high":float(band.get("strength_estimate_high",band.get("strength_estimate_low",0))),"seen":seen})
	return result

static func _bands_summary(seen:Array)->Dictionary:
	if seen.is_empty():return {}
	var low:=0.0;var high:=0.0;var last:=-1
	for band:Dictionary in seen:
		low+=float(band.low);high+=float(band.high);last=maxi(last,int(band.seen))
	return {"count":seen.size(),"low":low,"high":high,"seen":last}

## Peace, feud or war between us, and their ruler's trust in us. The feud's
## words are the War screen's own (Hot, Simmering).
static func relation_cell(people:Dictionary)->Dictionary:
	var word:="Peace";var tone:="ink";var order:=4
	var tip:="At peace with us."
	# Their answer to us (world_answer.gd): bowed and paying, or gathering every spear.
	var answer:=load("res://scripts/world_answer.gd") as GDScript
	var civ_id:=String(people.get("civ_id",""))
	var bowed:Dictionary=answer.call("tributary",civ_id) if answer!=null and civ_id!="" else {}
	var arming:Dictionary=answer.call("arming",civ_id) if answer!=null and civ_id!="" else {}
	if not arming.is_empty():
		word="Arming against us";tone="danger";order=0
		tip="Gathering every spear against us: they march in about %d days." % maxi(0,int(arming.get("march",0))-int(GameState.elapsed_days))
	elif not bowed.is_empty():
		word="Bows to us";tone="good";order=8
		tip="They bowed to us and pay tribute every season%s." % ((": %s is our hostage" % String(bowed.get("hostage",""))) if String(bowed.get("hostage",""))!="" else "")
	elif bool(people.get("feud",false)):
		var hot:=bool(people.get("hot",false))
		word="Hot feud" if hot else "Simmering feud";tone="danger" if hot else "warn";order=1 if hot else 2
		tip="In a feud with us; blood was spilled lately." if hot else "In a feud with us, quiet for now."
	elif bool(people.get("at_war",false)):
		word="War";tone="danger";order=0;tip="At war with us."
	else:
		match String(people.get("treaty","none")):
			"truce":word="Truce";tone="warn";order=3;tip="Under a truce with us."
			"non_aggression":word="Sworn peace";order=5;tip="Sworn not to attack us."
			"trade":word="Trading";tone="good";order=6;tip="At peace and trading with us."
			"alliance":word="Allied";tone="good";order=7;tip="Allied with us."
	var trust:=float(people.get("trust",0.0))
	var sub:="trusts us" if trust>=0.1 else ("distrusts us" if trust<=-0.1 else "unsure of us")
	var stance:=stance_word(String(people.get("stance","")))
	if stance!="":tip+=" Our stance on the War screen: %s." % stance
	return {"text":word,"sub":sub,"stance":stance,"tone":tone,"order":order,"tip":tip+" Their ruler %s." % sub.replace(" us"," you").replace("unsure of you","is unsure of you")}

## Whether envoys pass between our peoples.
static func envoys_cell(people:Dictionary)->Dictionary:
	if bool(people.get("envoys_away",false)):return {"text":"ours away","tone":"info","order":1,"tip":"Our envoys are on the road to them."}
	if bool(people.get("at_war",false)) or bool(people.get("hot",false)):return {"text":"barred","tone":"danger","order":0,"tip":"No envoys come from them while blood is hot; ours go only to seek peace."}
	if bool(people.get("withheld",false)):return {"text":"barred","tone":"danger","order":0,"tip":"They send no envoys to a ruler who harmed theirs."}
	if not bool(people.get("home_known",false)):return {"text":"no road yet","tone":"muted","order":2,"tip":"Envoys must know where their home lies; scouts can find it."}
	return {"text":"welcome","tone":"ink","order":3,"tip":"Envoys may pass between us."}

## The War screen's word for a stance ("Defend", "Take a town").
static var _stances:={}
static func stance_word(id:String)->String:
	if id=="":return ""
	if _stances.is_empty():
		var board:=load(WAR_BOARD_PATH) as GDScript
		for spec:Array in board.get_script_constant_map().get("STANCES",[]):_stances[String(spec[0])]=String(spec[1])
	return String(_stances.get(id,""))

## When we met them and what we know of their home, in short phrases.
static func contact_words(people:Dictionary)->Array:
	var words:Array=[]
	var met:=int(people.get("met_day",-1))
	words.append("Met %s" % ago(met) if met>=0 else "Met some time ago")
	words.append("their home found" if bool(people.get("home_known",false)) else "their home not yet found")
	return words


# --------------------------------------------------------------------------
# Ranking and order
# --------------------------------------------------------------------------

## Each row's place in one column: behind every people whose whole range lies
## above its own ("2nd"); "about level" where its range overlaps another's.
## Only figures of the same kind are ranked; with fewer than two, none is.
static func rank(rows:Array,column:String)->void:
	var ranked:Array=[]
	var lows:=PackedFloat64Array();var highs:=PackedFloat64Array();var names:=PackedStringArray()
	for row:Dictionary in rows:
		var c:Dictionary=row.cells.get(column,{})
		c.erase("rank");c.erase("rank_tip");c.erase("place")
		if bool(c.get("known",false)) and String(c.get("unit","main"))=="main":
			ranked.append(c);lows.append(float(c.low));highs.append(float(c.high))
			names.append("us" if bool(row.us) else String(row.name))
	if ranked.size()<2:return
	for i in ranked.size():
		var c:Dictionary=ranked[i]
		var ahead:=0
		var level:=PackedStringArray()
		for j in ranked.size():
			if j==i:continue
			if lows[j]>highs[i]:ahead+=1
			elif lows[j]<=highs[i] and lows[i]<=highs[j]:level.append(names[j])
		c["place"]=ahead+1
		if level.is_empty():
			c["rank"]=ordinal(ahead+1)
			c["rank_tip"]="%s of %d, as we know it." % [ordinal(ahead+1),ranked.size()]
		else:
			c["rank"]="about level"
			c["rank_tip"]="About level with %s: what we know overlaps." % ", ".join(level)

static func ordinal(n:int)->String:
	var suffix:="th"
	if n%100<11 or n%100>13:
		match n%10:
			1:suffix="st"
			2:suffix="nd"
			3:suffix="rd"
	return "%d%s" % [n,suffix]

## The rows in a column's order: the most first (names A to Z; the fiercest
## relation first; envoys barred first), the other way round when `flip`.
## What we do not know always comes last.
static func order(rows:Array,column:String,flip:bool=false)->Array:
	var sorted:=rows.duplicate()
	sorted.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return _before(a,b,column,flip))
	return sorted

static func _before(a:Dictionary,b:Dictionary,column:String,flip:bool)->bool:
	var ka:Variant=_key(a,column);var kb:Variant=_key(b,column)
	if (ka==null)!=(kb==null):return kb==null
	if ka==null or ka==kb:return String(a.name).to_lower()<String(b.name).to_lower()
	var first:bool=(ka<kb) if column in ["name","between","envoys"] else (ka>kb)
	return first!=flip

## What a column sorts by; null for what we do not know.
static func _key(row:Dictionary,column:String)->Variant:
	var c:Dictionary=row.cells.get(column,{})
	match column:
		"name":return String(row.name).to_lower()
		"between","envoys":return int(c.get("order",99))
	if not bool(c.get("known",false)):return null
	# An older people's index sorts after every figure of the main kind.
	var mid:=(float(c.low)+float(c.high))*0.5
	return mid if String(c.get("unit","main"))=="main" else -1000000000.0+mid

## The column titles for a stage.
static func titles(stage:String)->Dictionary:
	return TITLES.get(stage,TITLES.hearth)
