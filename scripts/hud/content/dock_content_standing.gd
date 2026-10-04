extends "res://scripts/hud/content/dock_content_base.gd"
## STANDING: the heart of the game. What we are (nine strengths drawn as a
## rose), how every people we know sees us and what that makes them do (with
## the engine's own odds), and how our own people feel. Everything is read
## from standing.gd, which reads the one ledger; nothing here is stored.
## docs/STANDING_DESIGN.md.

const Standing:=preload("res://scripts/standing.gd")
const Identity:=preload("res://scripts/city_map_identity.gd")
const History:=preload("res://scripts/strategic_history.gd")
const EraWords:=preload("res://scripts/hud/era_words.gd")
const DIVINE:=preload("res://scripts/divine_regard.gd")
const Hall:=preload("res://scripts/audience_hall.gd")
const RIVALS_PATH:="res://scripts/rival_rulers.gd"
const Memo:=preload("res://scripts/hud/content/dock_memo.gd")
## Costly parts of the page, kept while what they are made from holds.
var memo:=Memo.new()

## The page's own view state, kept across the daily rebuilds: which people's
## rose is laid over ours (a capture may choose one: --capture-compare=<id>).
var view_state:Dictionary={"compare":_capture_compare()}

static func _capture_compare()->String:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-compare="): return argument.trim_prefix("--capture-compare=")
	return ""

func meta()->Dictionary:
	return {"eyebrow":"Our name among the peoples","title":"Standing","subtabs":["Standing"]}

func tab(_sub:int)->Dictionary:
	var our:=Standing.strengths()
	var seen:=views_of(our)
	var board:=board_data(our,seen)
	var blocks:Array=[board]
	# The years' chart reads the demographic ledger and the monthly record,
	# which move only on a death, a birth tally or a month's reading.
	var ledger:Dictionary=WorldSimulation.state.strategic_history.get("scopes",{}).get("civilization",{})
	var chart:Dictionary=memo.take("history",[Memo.log_identity(WorldSimulation.state.demographic_ledger),Memo.log_identity(ledger.get("monthly",[])),Memo.log_identity(ledger.get("annual",[]))],func()->Dictionary:
		return History.block("standing","HOW OUR NAME HAS GROWN","civilization","of 100",[
			{"key":"standing_awe","label":"Awe","color":Tokens.GOLD},
			{"key":"standing_allure","label":"Allure","color":Tokens.TEAL},
			{"key":"standing_pride","label":"Pride","color":Tokens.GREEN},
			{"key":"standing_might","label":"Might","color":Tokens.RED},
			{"key":"standing_genius","label":"Genius","color":Tokens.BLUE}],
			"Read once a month from what the people are and do."))
	chart["_print"]=memo.print_of("history")
	blocks.append(chart)
	return {"brief":_brief(board),"blocks":blocks}

## Every people we have met, with its view of us: Standing.views(), read from
## the strengths this page has already reckoned instead of reckoning them a
## second time (tests/test_dock_content_cache.gd holds the two equal).
static func views_of(our:Dictionary)->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	if String(WorldSimulation.actor_id)!="player": return result
	for civ:Dictionary in WorldSimulation.world.civilizations:
		if not bool(civ.get("alive",true)): continue
		var v:=Standing.view_of(String(civ.id),our)
		if not bool(v.known): continue
		v["civ_id"]=String(civ.id)
		v["civ_name"]=String(civ.get("name",civ.id))
		result.append(v)
	return result

## The one danger that matters most now, with the section that answers it.
func _brief(board:Dictionary)->Dictionary:
	var warnings:Array=board.get("warnings",[])
	if warnings.is_empty(): return {}
	var first:Dictionary=warnings[0]
	var brief:={"tone":"danger" if String(first.tone)=="danger" else "warning","title":String(first.title),"why":String(first.words)}
	if String(first.get("section",""))!="":
		brief["action_label"]=String(first.get("action",""))
		brief["on_action"]=jump(String(first.section),int(first.get("sub",0)))
	return brief

## Everything the Standing board draws, as plain data.
func board_data(our:Dictionary,seen:Array)->Dictionary:
	var posture:=Standing.posture(our)
	var year_ago:=_year_ago()
	var strengths:Array=[]
	for row:Array in Standing.STRENGTHS:
		var id:=String(row[0])
		var value:=float((our[id] as Dictionary).value)
		var entry:={"id":id,"name":String(row[1]),"means":String(row[2]),"value":value,"why":String((our[id] as Dictionary).why),
			"section":String(row[3]),"sub":int(row[4]),"section_name":String(row[5]),"cost":String(row[6]),"parts":_parts_words(our[id] as Dictionary)}
		if year_ago.has(id): entry["change"]=roundf(value*100.0)-float(year_ago[id])
		strengths.append(entry)
	var peoples:Array=[]
	for v:Dictionary in seen: peoples.append(_people(v,our))
	var compare:=String(view_state.get("compare",""))
	var found:=false
	for p:Dictionary in peoples: found=found or String(p.civ_id)==compare
	if not found: view_state["compare"]=""
	var home:=_home(our,seen)
	return {"type":"standing","people_name":_our_name(),"posture":posture,"renown":Standing.renown(our),"strengths":strengths,"year_ago":year_ago,
		"peoples":peoples,"home":home,"warnings":_warnings(peoples,posture,our),"view_state":view_state,"arts":Standing.arts_at_work(),
		"on_raise":func(section:String,sub:int)->void: jump(section,sub).call(),
		"on_court":func(civ_id:String)->void: court({"civ_id":civ_id}).call(),
		"on_scouts":func()->void: if is_instance_valid(terrain) and terrain.has_method("_open_scout_dispatch_panel"): terrain.call("_open_scout_dispatch_panel"),
		# A people's strengths are reckoned in their own scope only when laid
		# over our rose; the board asks for them when one is chosen.
		"their_strengths":their_strengths}

## Our row's name: the nation's once named, else the people of the first town.
func _our_name()->String:
	return preload("res://scripts/nation_name.gd").people_title()

## Our strengths as they were read a year ago (points of 100), from the
## monthly record (strategic_history.gd): {id: points}.
static func _year_ago()->Dictionary:
	var rows:Array=History.points(WorldSimulation.state.strategic_history,"civilization")
	if rows.is_empty(): return {}
	var today:=int(WorldSimulation.state.elapsed_days)
	var chosen:Dictionary={}
	for row:Dictionary in rows:
		# Only readings against the age (standing_scale.gd): the old absolute
		# ones are not compared with them.
		if int(row.get("day",0))<=today-330 and row.has("standing_might") and int(row.get("standing_scale",1))>=2: chosen=row
	if chosen.is_empty(): return {}
	var result:Dictionary={}
	for row:Array in Standing.STRENGTHS:
		var key:="standing_"+String(row[0])
		if chosen.has(key): result[String(row[0])]=float(chosen[key])
	return result

func _people(v:Dictionary,our:Dictionary)->Dictionary:
	var civ_id:=String(v.civ_id)
	var civ:=ForeignDiplomacy.civilization(civ_id)
	var relation:Dictionary=civ.get("player_relation",{}) if not civ.is_empty() else {}
	var identity:=Identity.foreign(civ_id)
	var views:Array=[]
	for row:Array in Standing.VIEWS:
		var id:=String(row[0])
		views.append({"id":id,"name":String(row[1]),"means":String(row[2]),"value":float(v.get(id,0.0)),"why":String((v.why as Dictionary).get(id,""))})
	var rivals:=load(RIVALS_PATH) as GDScript if ResourceLoader.exists(RIVALS_PATH) else null
	var character:Dictionary=rivals.call("rival_character",civ_id) if rivals!=null else {}
	var memories:Array=[]
	# What their people still tell of us, and for how long (deeds.gd).
	var deeds:=preload("res://scripts/deeds.gd")
	for told:Dictionary in deeds.remembered(civ_id,2):
		memories.append({"tone":"good" if String(told.tone)=="amends" else "danger","text":"They tell of %s, year %d: %s." % [String(told.words),int(told.year),deeds.years_words(int(told.years_left))]})
	for grudge:Dictionary in character.get("grudges",[]):
		if memories.size()>=3: break
		memories.append({"tone":"danger","text":"They remember %s." % String(grudge.text).trim_suffix(".")})
	for bond:Dictionary in character.get("bonds",[]):
		if memories.size()>=4: break
		memories.append({"tone":"good","text":String(bond.text).trim_suffix(".")+"."})
	return {"civ_id":civ_id,"name":String(v.civ_name),"accent":identity.get("accent",Tokens.GOLD),"emblem":Identity.emblem(civ_id),
		"relation":_relation_words(civ_id,relation),"ruler":_with_path(_ruler_words(character),civ_id),"headline":Standing.view_words(v),
		"views":views,"envy":float(v.envy),"contempt":float(v.contempt),"envy_why":String((v.why as Dictionary).get("envy","")),"contempt_why":String((v.why as Dictionary).get("contempt","")),
		"strength":_estimated_strength_words(civ_id,float(v.strength_ratio)),"ratio":float(v.strength_ratio),
		"consequences":Standing.consequences(civ_id,v),"memories":memories,"known_words":_known_words(civ_id),
		"comparable":comparable(civ_id),"theirs":Standing.their_strengths(civ_id) if comparable(civ_id) else {},
		# Spies between us: cunning against cunning, as we reckon theirs.
		"spies":Standing.spies_words(civ_id)}

## A people's strengths as we know them (Standing.their_strengths: their own
## month's reading through our estimate).
func their_strengths(civ_id:String)->Dictionary:
	return Standing.their_strengths(civ_id)

## Whether a people's strengths can be laid over ours: a people the world
## simulates, that we know well enough to say anything of (certainty at least
## Standing.UNKNOWN_BELOW).
static func comparable(civ_id:String)->bool:
	return civ_id!="" and WorldSimulation.actors.has(civ_id) and Standing.certainty(civ_id)>=Standing.UNKNOWN_BELOW

## How well we know them, in words, with the band our estimates carry.
static func _known_words(civ_id:String)->String:
	var sure:=Standing.certainty(civ_id)
	if sure<Standing.UNKNOWN_BELOW: return "We know too little of them to say how strong they are."
	var band:=roundi(Standing.ESTIMATE_WIDEST*(1.0-sure)*100.0)
	if band<3: return "We know them well: their strengths as our watchers have them, close to the truth."
	return "We know them %s: our watchers' estimates of them run %d points either way, right %d times in 100 (envoys, scouts, agents among them and our cunning make them surer)." % ["fairly well" if sure>=0.5 else ("a little" if sure>=0.25 else "hardly at all"),band,roundi(Standing.estimate_right_odds(sure)*100.0)]

## Their fighting strength against ours as our watchers reckon it: the
## engine's ratio seen through our estimate of them.
static func _estimated_strength_words(civ_id:String,ratio:float)->String:
	var est:=Standing.estimate(civ_id,"strength_ratio",1.0/maxf(0.01,ratio),true)
	if bool(est.get("unknown",false)): return "We cannot say how strong they are in a fight"
	var words:=_strength_words(1.0/maxf(0.01,float(est.value)))
	if bool(est.exact): return words
	return "%s, by our watchers' reckoning (theirs somewhere between %.1f and %.1f times ours)" % [words,float(est.low),float(est.high)]

## A strength's parts as the Standing page's tooltip says them: "food 98%,
## materials 63%, goods 45%".
static func _parts_words(entry:Dictionary)->String:
	var bits:PackedStringArray=[]
	for part in entry.get("parts",[]):
		if part is Dictionary: bits.append("%s %d%%" % [String(PART_NAMES.get(String((part as Dictionary).id),String((part as Dictionary).id))),roundi(float((part as Dictionary).score)*100.0)])
	return ", ".join(bits)

const PART_NAMES:={"ready":"ready to fight","known":"practices known","scholars":"at research","envoy":"who speaks for us","openness":"openness","familiarity":"familiarity","treaties":"treaties kept",
	"gifts":"gifts given","abroad":"envoys abroad","scout":"chief scout","eyes":"scouts and watch","agents":"agents abroad","caught":"spies caught","intel":"what we know of them",
	"food":"food stores","materials":"materials","goods":"made goods","works":"great works","culture":"culture","beauty":"fine works","legitimacy":"trust in the chiefs",
	"cohesion":"holding together","administration":"administrators","steward":"the steward","water":"water","walls":"walls","health":"health","logistics":"carrying","met":"peoples met"}

static func _relation_words(civ_id:String,relation:Dictionary)->String:
	var parts:PackedStringArray=[]
	var war:=load("res://scripts/war_loop.gd") as GDScript
	var feud:=war!=null and bool(war.call("hot",civ_id))
	if bool(relation.get("at_war",false)): parts.append("At war with us")
	elif feud: parts.append("In a feud with us")
	else:
		var treaty:=String(relation.get("treaty","none"))
		parts.append({"trade":"At peace, trading with us","non_aggression":"At peace, sworn not to attack","truce":"Under a truce","alliance":"Allied with us"}.get(treaty,"At peace"))
	var tension:=float(relation.get("border_tension",0.0))
	if tension>=0.5 and not bool(relation.get("at_war",false)): parts.append("trouble on the border")
	return " · ".join(parts)

static func _ruler_words(character:Dictionary)->String:
	var name:=String(character.get("name",""))
	if name=="": return ""
	var trait_words:=String(character.get("trait_words",""))
	return "Ruled by %s, who %s" % [name,trait_words] if trait_words!="" else "Ruled by %s" % name

## The ruler's line with the path their people's work is set on
## (work_paths.gd): "Ruled by Arun, who ...; their work is set on war".
static func _with_path(ruler:String,civ_id:String)->String:
	var path:=preload("res://scripts/work_paths.gd").people_words(civ_id)
	if path=="": return ruler
	return "%s; %s" % [ruler,path] if ruler!="" else path.substr(0,1).to_upper()+path.substr(1)

## Their fighting strength against ours, as the page says it.
static func _strength_words(ratio:float)->String:
	var theirs:=1.0/maxf(0.01,ratio)
	if theirs>=2.5: return "They could fight with %.0f times our strength" % theirs
	if theirs>=1.6: return "They could fight with about twice our strength"
	if theirs>=1.2: return "They are stronger in a fight than we are"
	if theirs>=0.83: return "We are about as strong in a fight"
	if theirs>=0.55: return "We are stronger in a fight"
	return "We could fight with %.0f times their strength" % ratio if ratio>=2.5 else "We are much stronger in a fight"

func _home(our:Dictionary,seen:Array)->Dictionary:
	var pride:=Standing.pride(our,seen)
	var regard:=DIVINE.people_regard(Hall._officials())
	var legitimacy:=float(GameState.simulation_metrics.get("legitimacy",0.5))
	return {"pride":float(pride.value),"pride_why":String(pride.why),
		"love":float(regard.get("love",0.5)),"dread":float(regard.get("dread",0.0)),"regard_words":String(regard.get("read","")),
		"trust":legitimacy,"resentment":float(regard.get("resentment",0.0)),"effects":Standing.home_effects(),
		"told":_told_at_home()}

## What our own people still tell of their god (deeds.gd), weightiest first.
static func _told_at_home()->String:
	var deeds:=preload("res://scripts/deeds.gd")
	var parts:PackedStringArray=[]
	for told:Dictionary in deeds.remembered("home",3): parts.append("%s (year %d)" % [String(told.words),int(told.year)])
	return ("At every hearth they still tell of "+", ".join(parts)+".") if not parts.is_empty() else ""

## The dangers the page leads with, worst first: what the peoples we know
## will do about what they see, then what the shape of our strengths risks.
func _warnings(peoples:Array,posture:Dictionary,our:Dictionary)->Array:
	var warnings:Array=[]
	for p:Dictionary in peoples:
		for c:Dictionary in p.consequences:
			if String(c.tone)!="danger": continue
			var title:=""
			match String(c.id):
				"arming": title="%s is gathering every spear against us" % String(p.name)
				"all_in": title="%s may come at us with everything" % String(p.name)
				"league": title="%s stand together against us" % String(p.name)
				"envy": title="%s envy our goods" % String(p.name)
				"grudge": title="%s nurse a grudge against us" % String(p.name)
				"tribute_demand": title="%s think us easy to push" % String(p.name)
				"redress_demand": title="%s want old wrongs righted" % String(p.name)
				_: title="%s may move against us" % String(p.name)
			var fix:=_fix_for(String(c.id),our)
			warnings.append({"tone":"danger","title":title,"words":String(c.words)+". "+String(fix.words),"civ_id":String(p.civ_id),"section":String(fix.section),"sub":int(fix.sub),"action":String(fix.action),"rank":_rank(String(c.id))})
	if bool(posture.get("lopsided",false)):
		var low:Dictionary=posture.low
		for row:Array in Standing.STRENGTHS:
			if String(row[0])!=String(low.id): continue
			warnings.append({"tone":"warning","title":"%s is neglected" % String(row[1]),"words":"%s stands at %d%%, far below our %s at %d%%. %s." % [String(row[1]),roundi(float(low.value)*100.0),String(posture.top.name),roundi(float(posture.top.value)*100.0),_neglect_words(String(row[0]))],"section":String(row[3]),"sub":int(row[4]),"action":String(row[5]),"rank":9})
	warnings.sort_custom(func(a:Dictionary,b:Dictionary)->bool: return int(a.rank)<int(b.rank))
	return warnings

static func _rank(id:String)->int:
	return {"arming":-1,"league":0,"all_in":1,"envy":1,"grudge":2,"tribute_demand":3,"redress_demand":4}.get(id,5)

## What answers a danger, in the engine's own terms.
static func _fix_for(id:String,our:Dictionary)->Dictionary:
	match id:
		"envy","tribute_demand":
			return {"words":"More under arms and ready would make them think again (Might %d%%)." % roundi(float(our.might.value)*100.0),"section":"military","sub":0,"action":"Warriors"}
		"grudge","redress_demand":
			return {"words":"An envoy with gifts or redress can ease a grudge.","section":"","sub":0,"action":""}
		"league":
			return {"words":"Fear binds them: fewer warbands at their borders, gifts and kept word ease it; more spears only deepen it.","section":"","sub":0,"action":""}
		"arming","all_in":
			return {"words":"More under arms and ready at home meets them; a blood price or gifts sent first may turn them back (Might %d%%)." % roundi(float(our.might.value)*100.0),"section":"military","sub":0,"action":"Warriors"}
	return {"words":"","section":"","sub":0,"action":""}

static func _neglect_words(id:String)->String:
	return String({"might":"With few under arms, rich neighbours are envied and weak ones pushed","endurance":"A bad season or a siege would break us quickly","wealth":"Few goods to trade or give, and nothing that draws traders","reach":"Few peoples know us, so our works and word carry nowhere",
		"persuasion":"Our envoys win little, and peoples find our ways closed","splendor":"Nothing we have built makes others hold back or want to come","genius":"Others learn faster than we do, and their respect falls","cunning":"We learn late what others plan","order":"The people trust their chiefs little and hold together poorly"}.get(id,""))

func signature()->Array:
	var met:=0
	var at_war:=0
	for civ:Dictionary in CivilizationSystem.civilizations:
		var relation:Dictionary=civ.get("player_relation",{})
		if int(relation.get("contact_level",0))>=2: met+=1
		if bool(relation.get("at_war",false)): at_war+=1
	# The page reads live state; a new reading every few days is plenty.
	return [int(GameState.elapsed_days)/5,met,at_war,int(MilitaryCampaign.home_army.get("troops",0)),GameState.known_discoveries.size(),String(view_state.get("compare","")),GameState.strategic_history.get("last_day",-1),GameState.nation_name]
