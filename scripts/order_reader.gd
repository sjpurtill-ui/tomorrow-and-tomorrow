extends RefCounted
## THE ORDER READER: what did the ruler mean?
##
## With a live model, the ruler's words are read FIRST by one short dedicated
## call that only reads intent (no dialogue). It is given the words, the last
## few lines of the audience, the hall roster (with keys) and a compact brief
## of the war: our towns, towns we hold and their garrisons, the peoples we
## know and whether we fight them, our bands and where they stand, and any
## question still open in this audience. It answers in strict JSON whose ids
## can only be ids we supplied; the engine resolves them. The model never
## invents a target, and harm to a group, a town or a people can never
## resolve to anyone in the hall (court_commands.harm_to_people stays the
## hard safety net underneath).
##
## decide() turns a validated reading into one plan:
##   speak    - talk or a question: the voice answers, nothing is done;
##   engine   - an order the engine carries out (court_commands.hear with a
##              resolved live reading, or a war reading built here from ids);
##   clarify  - low confidence, or a grave act (kill, maim, raze, war, leaving
##              a town) whose target is uncertain: the court asks ONE plain
##              question and keeps the order pending; "yes" carries it out;
##   legacy   - anything the reader does not own (civic business, trade,
##              envoys, a failed or rejected reading): the unchanged regex
##              path decides, exactly as offline.
## Offline there is no reader: the predetermined, state-driven path stands.
## Static helpers; preload. The HTTP call itself lives in audience_voice.gd.

const Hall:=preload("res://scripts/audience_hall.gd")
const CC:=preload("res://scripts/court_commands.gd")
const WarOrders:=preload("res://scripts/court_war_orders.gd")
const TownFate:=preload("res://scripts/town_fate.gd")
const Measures:=preload("res://scripts/occupation_measures.gd")
const Ledger:=preload("res://scripts/town_ledger.gd")
const AiMode:=preload("res://scripts/ai_mode.gd")

## The reader must be quick: past this the regex classifier answers instead.
## Measured in play (reasoning models at low effort): readings take 2.4 to
## 3.5 seconds and about one in four went past the old 4-second limit, so the
## plain reading decided orders the live reader would have read better.
const TIMEOUT_SECONDS:=8.0
## Room for a reasoning model's thinking and the reply: short follow-ups were
## cut off at 420 (only the tokens used are billed).
const MAX_COMPLETION_TOKENS:=900
const MAX_RESPONSE_BYTES:=32768
## Below this nothing is carried out without asking.
const MIN_CONFIDENCE:=0.6
## A grave, irreversible act needs this much and a certain target.
const GRAVE_CONFIDENCE:=0.8
const PENDING_DAYS:=2
## The brief is kept small: the last few lines (the open question is given on
## its own line), each cut short.
const RECENT_LINES:=4
const RECENT_CHARS:=160
const MAX_ROSTER:=18
const MAX_CLARIFY_CHARS:=160
## Routes calls with the same static prefix to the same cache (OpenAI).
const PROMPT_CACHE_KEY:="court-order-reader-v3"
## The effort a reasoning model spends reading (OpenAI reasoning models).
const REASONING_EFFORT:="low"

const KINDS:=["speech","question","order"]
## Existing person verbs (court_commands.VERBS less the generic ones), what
## becomes of a held town, war objectives, and the business the regex path
## keeps (trade, envoy, civic, order).
const PERSON_ACTIONS:=["kill","maim","exile","detain","penance","terrify","bless","boon","raise","demote","appoint","give","take"]
const WAR_ACTIONS:=["town_fate","town_measure","attack","siege","raid","storm","intercept","pursue","recall","defend","drill"]
## What a garrison may do with the people of a town we hold
## (occupation_measures.gd), and how hard its hand is.
const MEASURE_IDS:=Measures.IDS
const STANCES:=["","lenient","firm","harsh","brutal"]
## Whom the order is about, as the words name them ("kill all the women":
## women). The reader never widens a group the words name.
const WHO:=["","men","women","children","elders","everyone","bound"]
const LEGACY_ACTIONS:=["send","trade","envoy","civic","order"]
const ACTIONS:=["none"]+PERSON_ACTIONS+WAR_ACTIONS+LEGACY_ACTIONS+["confirm","cancel"]
const TARGET_TYPES:=["person","group","town","people","band","none"]
const DETAIL_FLAGS:=["kill_men","kill_all","captives","raze","tribute","spare","hold","leave","free","full_force"]
const HARM:=["kill","maim"]

## Static, so the schema and these instructions form the same prefix on every
## call and the provider can cache it (they come before the brief, which is
## the only part that changes). The examples teach the flat reading shape.
const SYSTEM_PROMPT:="""You read what a ruler means in a royal audience of a fictional early society. You do NOT write dialogue. Return only the JSON asked for, one flat object.
kind: 'question' for a question; 'order' for any instruction however phrased ('I want you to...', 'go ahead', 'come home'), and for the ruler's decrees said as statements ('<name> is dismissed', 'you are no longer war leader', '<name> must die', 'I curse you', 'I bless my people', 'our town is now called X', 'women may now hunt', 'stealing is forbidden'); 'speech' for talk, thanks, musing, what someone did or what happened ('<name> whipped the boy'), threats without an order, and words that forbid or hold back an act ('don't kill him', 'never whip <name> again', '<name> must not be punished', 'do not attack <a town>').
action: what is ordered. Person acts (kill, maim, exile, detain, penance, terrify, bless, boon, raise, demote, appoint, give, take) fall on ONE person from HALL (maim: wound, cut, flog, whip or beat them; raise: honour, exalt or promote them; boon: reward them with a gift; take: seize goods FROM them as a fine, never bringing someone in; terrify: the god's anger on them: curse, frighten, 'kneel before me', 'obey me', or a punishment only if something happens later, 'flog <name> if he lies again' ('beat him until he learns' is a beating now); demote: dismiss, fire or strip ONE person of office, 'X is no longer war leader' (dismissing, releasing or sending home a NUMBER or GROUP of our fighters, 'dismiss 5 of our soldiers', 'send the recruits home', is order, never demote); appoint: give an office of our council, 'make X war leader', 'promote X to keeper of stores', 'X is now keeper of stores'; setting someone over a town we hold, 'set <name> over them', is town_measure set_headman). An office named ('the steward', 'the headman', 'the war leader') is the one in HALL who holds it (each office and its other names follow the name), never a renowned figure. Freeing, releasing, pardoning or sparing one person ('free <name>', 'let him go', 'pardon <name>'), and marrying someone off: order, type person, ref that person. The god's anger or favour on many is terrify or bless: type people (a whole people), town (a town), group with ref home (our own people: 'the people', 'my people', 'everyone', 'let them all tremble' when no other place is spoken of), or type none (the whole court, the fields, our fighters). A law, custom or standing rule for our own people ('punish the thieves', 'execute every thief', 'flog anyone caught sleeping on watch', 'nobody leaves their house after dark', 'anyone who murders will be put to death', 'never kill a man who has surrendered', 'every newborn shall be named for me', 'a man must give ten hides for his bride'), a feast or rite, a great work, or a new name for our town: order, type none; never a person act, and never town_measure unless a town we hold is named. Summoning someone ('summon her', 'bring him to me', 'bring me the woman who found the salt spring', 'I want to see the oldest man', 'get me the tallest woman', 'put them on trial'): order, action none. town_fate: what becomes of a town WE HOLD and its people (set flags). town_measure: what our garrison is to DO with the people of a town WE HOLD while holding it; measures lists every measure named: bind_men (round up, tie, bind, chain, detain, lock up, hold under guard), disarm (take or burn their weapons), hostages, curfew (keep them in their houses), search (search the houses), labour (make them work, build walls, clear roads, work fields), requisition (take their food or stores), conscript (take their men into our bands), execute_ringleaders (kill the leaders, make an example), release (free, untie, let go), relief (feed, protect, reward those who help), set_headman (set someone over them), settle (move our families in). stance is how hard the hand is: harsh for threats to families or beatings ("if any resist, threaten their wives"), brutal for "kill any who resist", lenient for gently, else ''. Group acts on a town's people are town_measure, never a person act. attack, siege, raid, storm: war on a FOREIGN town (a raid or war on a people: type people, ref that people). Killing, taking captives from or burning the people of a town we do NOT hold is still kill (type group) or town_fate with its flags, NEVER attack: the court asks to take the town first. intercept or pursue: go after their army or band in the field, or the men who fled a town. recall: bring bands home, or stop something under way (call off the chase, bring the men back; 'no, don't attack' or 'call it off' when OUR BANDS show that march UNDER WAY) (type band and a band's id for one band, type none for all). defend: guard home or a place. drill: a band told to train before it marches ('let them drill first'). send (scouts, envoys), trade, envoy, civic, order (recruit, train or arm new fighters of our own ('recruit, train and arm 5 levies', 'train the recruits'), make weapons, build, haul, any other work at home): other business. confirm: yes / do it / go ahead / send them, to the OPEN QUESTION. cancel: no / wait / leave it, ONLY as the answer to the OPEN QUESTION. A short answer to the OPEN QUESTION that names someone or something ('<a people>', '<name>', 'our own people') is the order the question was about, aimed at what it names. none: not an order. Telling an envoy to leave or refusing them ('no tribute, get out', 'go home') is speech, not exile, unless the words order them driven out, bound or harmed.
type and ref: ref MUST be a whole id copied from the lists, prefix and all (town:..., people:..., person:..., figure:..., band:..., ours:..., home; a foreign envoy before the ruler is envoy), or '' when none fits. 'him', 'her', 'you' mean a person (the one marked SPEAKING is the one before the ruler). Killing or harming many people (all the men, the villagers, everyone, them all, a town's people, a whole people) is NEVER a person in HALL: use type group (ref = the town or people meant, or ''), town, or people. A town we hold is a town_fate, never an attack. actor: the id of the one told to do it, from HALL, or ''.
who: whom the order is about as the words name them: men, women, children, elders, bound (those we tied up), everyone (only when the words say everyone), else ''. flags: each that applies to a town's fate (kill_men for killing, kill_all ONLY when the words say everyone, captives, raze, tribute, spare, hold, leave, free), and full_force for 'with everything'. Taking people back to our town is town_fate with captives and destination that town (hostages are held in their own town). count: a number said, else 0. resource: goods named, else ''. destination: an id or ''. measures and stance: for town_measure, else [] and ''.
confidence 0 to 1 for how CLEAR the words are about the action and the target, not how grave the act is: a named act on a named place, people or person is 0.9 or more. If the words are unclear about something grave (killing, maiming, burning a town, going to war, abandoning a town), give low confidence and write clarify: ONE short, plain question the court would ask the ruler (no flattery, no promise); for the god's anger on 'them' with nobody spoken of, ask 'Whom do you mean?'. Otherwise clarify is ''.
Examples (ids stand for ids from the lists):
"kill all the males of <a town we hold>" -> order, town_fate, type group, ref that town, who men, flags [kill_men].
"kill all the women of <a town we hold>" -> order, town_fate, type group, ref that town, who women, flags [kill_men] (never kill_all).
"kill the men of <a town we do not hold>" -> order, kill, type group, ref that town, who men, flags [kill_men], confidence 0.9.
"take all girls under 10 back to <home>" -> order, town_fate, type group, ref the town, who children, flags [captives], destination home.
"take the women and girls to <home> and burn it" -> order, town_fate, type group, ref the town, flags [captives, raze], destination home.
"round up the men and tie them up; if any resist, threaten their wives" -> order, town_measure, type group, ref the town, measures [bind_men], stance harsh.
"send everything we have against <their town>" -> order, attack, type town, ref that town, flags [full_force].
"chase the men who fled <a town we hold>" -> order, pursue, type town, ref that town. "call off the chase" -> order, recall.
"always ransom the captives" or "from now on bring captives home as bondservants" -> order, order.
"curse <name>" -> order, terrify, type person, ref that person's id. "terrify the people" -> order, terrify, type group, ref home. "curse <a people>" -> order, terrify, type people, ref that people.
"punish the thieves" or "execute every thief" -> order, order, type none. "free <name>" -> order, order, type person, ref that person's id.
"stop founding new towns" or "our leaders may settle new land again" -> order, order, type none.
"bring her to me" -> order, none. "don't kill him" -> speech, none. "<name> is no longer war leader" -> order, demote, type person, ref that person's id.
"how many are bound?" -> question, none. "yes" or "do it" with an OPEN QUESTION -> order, confirm."""

# --------------------------------------------------------------------------
# Configuration
# --------------------------------------------------------------------------

static func reader_model(voice_model:String)->String:
	## LEVIATHAN_AI_READER_MODEL, else the device setting (ai_mode.cfg), else
	## the voice model itself.
	var env:=OS.get_environment("LEVIATHAN_AI_READER_MODEL").strip_edges()
	if env!="": return env
	var chosen:=AiMode.reader_model()
	return chosen if chosen!="" else voice_model

static func reader_config(config:Dictionary)->Dictionary:
	if config.is_empty(): return {}
	var out:=config.duplicate()
	out["model"]=reader_model(String(config.get("model","")))
	return out

# --------------------------------------------------------------------------
# The world brief
# --------------------------------------------------------------------------

static func world_brief(audience_id:String)->Dictionary:
	## Everything the reader may point at, each with an id:
	## {roster, ours, held, towns, peoples, bands, home_troops, besieging,
	##  pending, recent, ids:{id->type}}.
	var audience:=Hall.find(audience_id)
	var brief:={"roster":[],"ours":[],"held":[],"towns":[],"peoples":[],"bands":[],"home_troops":0,"besieging":"","pending":"","recent":[],"ids":{}}
	var ids:Dictionary=brief.ids
	var list:=CC.roster(audience)
	list.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return int(bool(a.speaker))*2+int(bool(a.present))>int(bool(b.speaker))*2+int(bool(b.present)))
	for e:Dictionary in list.slice(0,MAX_ROSTER):
		var office:=String(e.get("title",""))
		# A figure of renown holds no council office ("war leader" is their
		# calling), so "the war leader" is the one who holds the office.
		if String(e.get("kind",""))=="figure" and office!="": office="renowned %s, holds no office" % office
		(brief.roster as Array).append({"id":String(e.key),"name":String(e.name),"office":office,"aka":_office_aka(String(e.get("office_key","")),String(e.get("title",""))),"speaking":bool(e.speaker),"present":bool(e.present)})
		ids[String(e.key)]="person"
	if WorldSimulation.state!=null:
		for s in WorldSimulation.state.player_settlements:
			if not s is Dictionary: continue
			var sid:="ours:"+String((s as Dictionary).get("id",""))
			(brief.ours as Array).append({"id":sid,"name":String((s as Dictionary).get("name",""))})
			ids[sid]="town"
	if WorldSimulation.military!=null and WorldSimulation.world!=null:
		for t:Dictionary in WarOrders.held_towns():
			var tid:="town:"+String(t.city_id)
			# What the garrison is doing there now (occupation_measures.gd).
			var in_force:Array=Measures.card_labels(String(t.civ_id),String(t.city_id))
			# Who is there and what became of the rest: the town's one ledger.
			var c:=Ledger.counts(String(t.civ_id),String(t.city_id))
			(brief.held as Array).append({"id":tid,"name":String(t.name),"people":String(t.civ_name),"garrison":int(t.garrison),"commander":String(t.commander),"measures":in_force,
				"here":Ledger.here_words(c) if not c.is_empty() else "","gone":Ledger.gone_words(c) if not c.is_empty() else ""})
			ids[tid]="town"
		for t:Dictionary in WarOrders.known_places():
			var tid:="town:"+String(t.city_id)
			if ids.has(tid): continue
			# A town we took once and no longer hold: said so (town_ledger.hold).
			var h:=Ledger.hold(String(t.civ_id),String(t.city_id))
			var once:=Ledger.hold_words(h) if bool(h.taken) else ""
			(brief.towns as Array).append({"id":tid,"name":String(t.name).trim_prefix("Reported home of "),"people":String(t.civ_name),"once":once})
			ids[tid]="town"
		# A town we burned or left keeps its id: it is still a place the ruler
		# may speak of ("what is left of Tsaren", "go back to Tsaren").
		for pair in Ledger.towns():
			var tid2:="town:"+String(pair[1])
			if ids.has(tid2): continue
			var h2:=Ledger.hold(String(pair[0]),String(pair[1]))
			var region:Dictionary=WorldSimulation.world.region_snapshot(String(pair[0]),String(pair[1]))
			if String(region.get("name",""))=="": continue
			(brief.towns as Array).append({"id":tid2,"name":String(region.name),"people":Hall._civ_name(String(pair[0])),"once":Ledger.hold_words(h2)})
			ids[tid2]="town"
		for c:Dictionary in WorldSimulation.world.civilizations:
			var cid:=String(c.get("id",""))
			if cid=="" or cid=="player": continue
			var rel:Dictionary=c.get("player_relation",{}) if c.get("player_relation") is Dictionary else {}
			if int(rel.get("contact_level",0))<=0 and not bool(rel.get("at_war",false)): continue
			# A feud short of war (war_loop.gd): their raiders and ours, nothing declared.
			var feud:=not bool(rel.get("at_war",false)) and bool((load("res://scripts/war_loop.gd") as GDScript).call("feuding",cid))
			(brief.peoples as Array).append({"id":"people:"+cid,"name":String(c.get("name",cid)),"at_war":bool(rel.get("at_war",false)),"feud":feud})
			ids["people:"+cid]="people"
		var mc:Variant=WorldSimulation.military
		brief.home_troops=maxi(0,int((mc.home_army as Dictionary).get("troops",0)))
		for a in mc.field_armies:
			var army:Dictionary=a
			if int(army.get("troops",0))<=0: continue
			var bid:="band:%d" % int(army.get("army_id",0))
			var commander:Dictionary=army.get("commander",{}) if army.get("commander") is Dictionary else {}
			# What it is doing now: a chase under way, a march on a town.
			var doing:=preload("res://scripts/pursuit.gd").doing_words(army)
			if doing=="" and String(army.get("status",""))=="moving" and army.get("court_order") is Dictionary: doing="marching on %s" % String((army.court_order as Dictionary).get("name",(army.court_order as Dictionary).get("city_name","their town")))
			(brief.bands as Array).append({"id":bid,"name":String(army.get("name","")),"troops":int(army.troops),"where":WarOrders._where(army),"status":String(army.get("status","")),"leader":String(commander.get("name","")),"doing":doing})
			ids[bid]="band"
		brief.besieging=String(WarOrders._besieged().get("name",""))
	ids["home"]="town"
	brief.pending=_pending_words(audience)
	var lines:Array=audience.get("lines",[])
	for i in range(maxi(0,lines.size()-RECENT_LINES),lines.size()):
		var line:Dictionary=lines[i]
		var said:=String(line.get("text",""))
		(brief.recent as Array).append("%s: %s" % [String(line.get("speaker","")) if String(line.get("role",""))!="narrator" else "(narration)",said if said.length()<=RECENT_CHARS else said.substr(0,RECENT_CHARS-3)+"..."])
	return brief

static func _office_aka(office_key:String,title:String)->String:
	## Other names the ruler uses for an office ("steward, headman" for the
	## Hearth Chief), from the court's own words for it (court_commands.OFFICE_WORDS).
	if office_key=="": return ""
	var t:=title.to_lower().replace(" ","")
	var out:=PackedStringArray()
	for word in CC.OFFICE_WORDS:
		if String(CC.OFFICE_WORDS[word])!=office_key or String(word).replace(" ","")==t or out.size()>=3: continue
		out.append(String(word))
	return ", ".join(out)

static func _pending_words(audience:Dictionary)->String:
	var mine:=pending(audience)
	if not mine.is_empty(): return "The court asked \"%s\" about the ruler's order \"%s\"." % [String(mine.get("question","")),String(mine.get("text",""))]
	var p:Dictionary=audience.get("pending_command",{}) if audience.get("pending_command") is Dictionary else {}
	if p.is_empty() or Hall._day()-int(p.get("day",-99))>CC.PENDING_DAYS: return ""
	if bool(p.get("confirm",false)): return "The war leader asked whether to go ahead with: \"%s\"." % String(p.get("text",""))
	if String(p.get("ask",""))=="chase": return "The war leader offered to send men after those who fled; the ruler may say yes (confirm), no (cancel), or name how many (pursue)."
	if String(p.get("ask",""))=="abandon": return "The war leader asked whether to leave the town unguarded and bring its garrison home; yes is confirm, no is cancel."
	if String(p.get("ask",""))=="measure": return "The war leader asked: \"%s\" The ruler may name one of those choices (town_measure or town_fate), say yes (confirm: the first choice), or no (cancel)." % String(p.get("question",""))
	if String(p.get("ask",""))!="": return "The war leader asked the ruler a question about the order \"%s\"; yes is confirm, no is cancel." % String(p.get("text",""))
	if bool(p.get("which_town",false)): return "The war leader asked which town the order \"%s\" is for." % String(p.get("text",""))
	if String(p.get("verb",""))=="war": return "The war leader objected to the order \"%s\"; the ruler may insist." % String(p.get("text",""))
	return "Someone hesitated over the order \"%s\"; the ruler may insist." % String(p.get("text",""))

static func pending(audience:Dictionary)->Dictionary:
	## The reader's own open question in this audience, while fresh.
	var p:Dictionary=audience.get("reader_pending",{}) if audience.get("reader_pending") is Dictionary else {}
	if p.is_empty() or Hall._day()-int(p.get("day",-99))>PENDING_DAYS: return {}
	return p

static func brief_text(brief:Dictionary)->String:
	var out:PackedStringArray=PackedStringArray()
	var rows:PackedStringArray=PackedStringArray()
	for r:Dictionary in brief.roster:
		rows.append("%s = %s%s%s%s" % [String(r.id),String(r.name),(", "+String(r.office)) if String(r.office)!="" else "",(" (also called %s)" % String(r.aka)) if String(r.get("aka",""))!="" else ""," (SPEAKING, before the ruler)" if bool(r.speaking) else (" (present)" if bool(r.present) else "")])
	out.append("HALL: "+("; ".join(rows) if not rows.is_empty() else "nobody"))
	rows=PackedStringArray()
	for t:Dictionary in brief.ours: rows.append("%s = %s" % [String(t.id),String(t.name)])
	var home_name:=String(WorldSimulation.state.settlement_name) if WorldSimulation.state!=null else ""
	rows.append("home = %s (our home settlement)" % home_name if home_name!="" else "home = our home settlement")
	out.append("OUR TOWNS: "+"; ".join(rows))
	rows=PackedStringArray()
	for t:Dictionary in brief.held: rows.append("%s = %s (%s town; our garrison %d%s%s%s%s)" % [String(t.id),String(t.name),String(t.people),int(t.garrison),(", under "+String(t.commander)) if String(t.commander)!="" else "",
		("; in force: "+", ".join(PackedStringArray(t.get("measures",[])))) if not (t.get("measures",[]) as Array).is_empty() else "",
		("; there now: "+String(t.here)) if String(t.get("here",""))!="" else "",("; gone: "+String(t.gone)) if String(t.get("gone",""))!="" and String(t.gone)!="none" else ""])
	out.append("TOWNS WE HOLD: "+("; ".join(rows) if not rows.is_empty() else "none"))
	rows=PackedStringArray()
	for t:Dictionary in brief.towns: rows.append("%s = %s (%s%s)" % [String(t.id),String(t.name),String(t.people),("; NOT HELD: "+String(t.once)+" Nobody of it is in our hands.") if String(t.get("once",""))!="" else ""])
	out.append("FOREIGN TOWNS WE KNOW: "+("; ".join(rows) if not rows.is_empty() else "none"))
	rows=PackedStringArray()
	for p:Dictionary in brief.peoples: rows.append("%s = %s (%s)" % [String(p.id),String(p.name),"AT WAR with us" if bool(p.at_war) else ("IN A FEUD with us: raids back and forth, nothing declared; an order to attack or go to war with them is a raid on them" if bool(p.get("feud",false)) else "at peace")])
	out.append("PEOPLES: "+("; ".join(rows) if not rows.is_empty() else "none known"))
	rows=PackedStringArray()
	for b:Dictionary in brief.bands: rows.append("%s = %s, %d fighters, %s%s%s" % [String(b.id),String(b.name),int(b.troops),String(b.where),(", led by "+String(b.leader)) if String(b.leader)!="" else "",("; UNDER WAY: "+String(b.doing)) if String(b.get("doing",""))!="" else ""])
	out.append("OUR BANDS: "+("; ".join(rows) if not rows.is_empty() else "none in the field")+". Trained at home: %d." % int(brief.home_troops))
	if String(brief.besieging)!="": out.append("WE ARE BESIEGING: "+String(brief.besieging))
	out.append("OPEN QUESTION: "+(String(brief.pending) if String(brief.pending)!="" else "none"))
	if not (brief.recent as Array).is_empty(): out.append("LAST LINES:\n"+"\n".join(PackedStringArray(brief.recent)))
	return "\n".join(out)

# --------------------------------------------------------------------------
# The call
# --------------------------------------------------------------------------

static func build_payload(text:String,brief:Dictionary,config:Dictionary)->Dictionary:
	## Static first (the schema and the instructions: the same bytes on every
	## call, so the provider caches them), the brief and the words last.
	## config may carry the voice's learned endpoint quirks (no_reasoning_effort,
	## no_schema): a field the endpoint rejected is not sent again.
	var said:=text.strip_edges().replace("\n"," ").substr(0,400)
	var payload:={"model":String(config.get("model","")),"max_completion_tokens":MAX_COMPLETION_TOKENS,"messages":[
		{"role":"system","content":SYSTEM_PROMPT},
		{"role":"user","content":brief_text(brief)+"\nTHE RULER SAYS: <<%s>>" % said}]}
	if "api.openai.com" in String(config.get("endpoint","")).to_lower():
		if not bool(config.get("no_reasoning_effort",false)): payload["reasoning_effort"]=REASONING_EFFORT
		payload["prompt_cache_key"]=PROMPT_CACHE_KEY
	if bool(config.get("structured_output",false)) and not bool(config.get("no_schema",false)): payload["response_format"]=response_format()
	return payload

## The reading's schema: flat and the same on every call (no ids in it; the
## ids a reading names are checked against the brief's lists in validate()).
static func response_format(_brief:Dictionary={})->Dictionary:
	return {"type":"json_schema","json_schema":{"name":"order_reading","strict":true,"schema":{
		"type":"object","additionalProperties":false,
		"required":["kind","action","actor","type","ref","who","flags","count","resource","destination","measures","stance","confidence","clarify"],
		"properties":{
			"kind":{"type":"string","enum":KINDS},
			"action":{"type":"string","enum":ACTIONS},
			"actor":{"type":"string"},
			"type":{"type":"string","enum":TARGET_TYPES},
			"ref":{"type":"string"},
			"who":{"type":"string","enum":WHO},
			"flags":{"type":"array","items":{"type":"string","enum":DETAIL_FLAGS}},
			"count":{"type":"integer"},
			"resource":{"type":"string"},
			"destination":{"type":"string"},
			"measures":{"type":"array","items":{"type":"string","enum":MEASURE_IDS}},
			"stance":{"type":"string","enum":STANCES},
			"confidence":{"type":"number"},
			"clarify":{"type":"string"}}}}}

static func parse(body:PackedByteArray)->Dictionary:
	var parser:=JSON.new()
	if parser.parse(body.get_string_from_utf8())!=OK or not parser.data is Dictionary: return {}
	var envelope:Dictionary=parser.data
	if envelope.has("action") and envelope.has("kind"): return envelope
	var content:=""
	var choices:Variant=envelope.get("choices",[])
	if choices is Array and not (choices as Array).is_empty() and choices[0] is Dictionary:
		var message:Variant=(choices[0] as Dictionary).get("message",{})
		if message is Dictionary: content=PronouncementInterpreter._content_text((message as Dictionary).get("content",""))
	if content.is_empty(): content=PronouncementInterpreter._content_text(envelope.get("output_text",""))
	var first:=content.find("{"); var last:=content.rfind("}")
	if first<0 or last<=first: return {}
	var inner:=JSON.new()
	if inner.parse(content.substr(first,last-first+1))!=OK or not inner.data is Dictionary: return {}
	return inner.data

static func validate(raw:Dictionary,brief:Dictionary)->Dictionary:
	## The reading as the engine may use it, or {"rejected": why}. Every id
	## must be one we supplied, of the kind its type says.
	if raw.is_empty(): return {"rejected":"no reading"}
	var kind:=String(raw.get("kind",""))
	var action:=String(raw.get("action",""))
	if not kind in KINDS: return {"rejected":"unknown kind"}
	if not action in ACTIONS: return {"rejected":"unknown action"}
	var ids:Dictionary=brief.get("ids",{})
	# The flat reading (type, ref, flags at the top) or the older nested one
	# (target:{type, ref}, details:{kill_men: true, ...}).
	# An empty container (a tool that makes a reading "safe" adds one) is no
	# nested reading: the flat fields stand.
	var nested:=raw.get("target") is Dictionary and not (raw.get("target") as Dictionary).is_empty()
	var target:Dictionary=raw.get("target") if nested else {"type":raw.get("type","none"),"ref":raw.get("ref","")}
	if target.get("type")==null: target["type"]="none"
	if target.get("ref")==null: target["ref"]=""
	var ttype:=String(target.get("type","none"))
	# An id written as a name or without its prefix is the id it plainly
	# means; anything else is refused as before.
	var ref:=resolve_id(String(target.get("ref","")),brief)
	if not ttype in TARGET_TYPES: return {"rejected":"unknown target type"}
	if ref!="":
		if not ids.has(ref): return {"rejected":"target not in the lists"}
		var of:=String(ids[ref])
		match ttype:
			"person": if of!="person": return {"rejected":"target is not a person"}
			"town": if of!="town": return {"rejected":"target is not a town"}
			"people": if of!="people": return {"rejected":"target is not a people"}
			"band": if of!="band": return {"rejected":"target is not a band"}
			"group": if not of in ["town","people"]: return {"rejected":"a group is a town or a people, never a person"}
			"none": ref=""
	var actor:=resolve_id(String(raw.get("actor","")),brief)
	if actor!="" and String(ids.get(actor,""))!="person": return {"rejected":"actor not in the hall"}
	var conf:Variant=raw.get("confidence",0.0)
	var details_in:Dictionary=raw.get("details") if raw.get("details") is Dictionary and not (raw.get("details") as Dictionary).is_empty() else raw
	var details:={}
	for flag:String in DETAIL_FLAGS:
		if bool(details_in.get(flag,false)): details[flag]=true
	var flags_in:Variant=details_in.get("flags",raw.get("flags",[]))
	if flags_in==null: flags_in=[]
	if not flags_in is Array: return {"rejected":"flags is not a list"}
	for f in flags_in:
		if not f is String or not String(f) in DETAIL_FLAGS: return {"rejected":"unknown flag"}
		details[String(f)]=true
	var count:Variant=details_in.get("count",0)
	if (count is int or count is float) and int(count)>0: details["count"]=clampi(int(count),1,100000)
	var dest:=resolve_id(String(details_in.get("destination","")),brief)
	if dest!="" and ids.has(dest): details["destination"]=dest
	var res:=String(details_in.get("resource","")).strip_edges().substr(0,40)
	if res!="": details["resource"]=res
	# Measures and stance come only from their lists: anything else is refused.
	var measures_in:Variant=details_in.get("measures",[])
	if measures_in==null: measures_in=[]
	if not measures_in is Array: return {"rejected":"measures is not a list"}
	var measures:Array[String]=[]
	for m in measures_in:
		if not m is String or not String(m) in MEASURE_IDS: return {"rejected":"unknown measure"}
		if not measures.has(String(m)): measures.append(String(m))
	if not measures.is_empty(): details["measures"]=measures
	var stance_in:Variant=details_in.get("stance","")
	var stance:=String(stance_in) if stance_in is String else ("" if stance_in==null else "?")
	if not stance in STANCES: return {"rejected":"unknown stance"}
	if stance!="": details["stance"]=stance
	var who_in:Variant=details_in.get("who",raw.get("who",""))
	var who:=String(who_in) if who_in is String else ""
	if not who in WHO: return {"rejected":"unknown who"}
	if who!="": details["who"]=who
	var clarify:=String(raw.get("clarify","")).strip_edges().replace("\n"," ").substr(0,MAX_CLARIFY_CHARS)
	return {"kind":kind,"action":action,"actor":actor,"type":ttype,"ref":ref,"details":details,
		"confidence":clampf(float(conf) if (conf is float or conf is int) else 0.0,0.0,1.0),"clarify":clarify}

## An id in a reading that is not in the lists but plainly means one of them:
## the id without its prefix ("civ_01_region_01"), or a name ("town:Tsaren",
## "Tsaren", "people:Esurai", "Kishan", our home's name for "home"). The id
## itself when it is in the lists; the words as given when they mean none, or
## more than one (validate() then refuses them).
static func resolve_id(ref:String,brief:Dictionary)->String:
	var ids:Dictionary=brief.get("ids",{})
	var r:=ref.strip_edges()
	if r=="" or ids.has(r): return r
	var prefix:=r.get_slice(":",0).to_lower() if ":" in r else ""
	var bare:=r.substr(r.find(":")+1).strip_edges() if ":" in r else r
	var hits:={}
	for id in ids:
		if ":" in String(id) and String(id).substr(String(id).find(":")+1)==bare: hits[String(id)]=true
	if hits.size()==1: return String(hits.keys()[0])
	var name:=bare.to_lower().trim_prefix("the ").strip_edges()
	if name=="": return r
	var home:=String(WorldSimulation.state.settlement_name).to_lower() if WorldSimulation.state!=null else ""
	if home!="" and name==home and ids.has("home"): return "home"
	hits.clear()
	for group in ["roster","ours","held","towns","peoples","bands"]:
		for e in brief.get(group,[]):
			if not e is Dictionary: continue
			var n:=String((e as Dictionary).get("name","")).to_lower().trim_prefix("the ").strip_edges()
			if n!="" and (n==name or n.get_slice(" ",0)==name): hits[String((e as Dictionary).get("id",""))]=true
	# A prefix that says what kind of thing is meant settles a tie.
	if hits.size()>1 and prefix!="":
		var narrowed:={}
		for id in hits:
			if String(id).begins_with(prefix+":"): narrowed[id]=true
		if not narrowed.is_empty(): hits=narrowed
	if hits.size()==1: return String(hits.keys()[0])
	return r

# --------------------------------------------------------------------------
# Deciding
# --------------------------------------------------------------------------

static func grave(reading:Dictionary)->bool:
	var action:=String(reading.get("action",""))
	var d:Dictionary=reading.get("details",{})
	if action in HARM or action in ["attack","siege","raid","storm"]: return true
	if action=="town_fate": return bool(d.get("kill_men",false)) or bool(d.get("kill_all",false)) or bool(d.get("raze",false)) or bool(d.get("captives",false)) or bool(d.get("leave",false))
	if action=="town_measure": return (d.get("measures",[]) as Array).any(func(m:Variant)->bool: return String(m) in Measures.GRAVE) or String(d.get("stance",""))=="brutal"
	return false

static func _held_by_ref(ref:String)->Dictionary:
	if not ref.begins_with("town:"): return {}
	for t:Dictionary in WarOrders.held_towns():
		if "town:"+String(t.city_id)==ref: return t
	return {}

static func _place_by_ref(ref:String)->Dictionary:
	if not ref.begins_with("town:"): return {}
	for t:Dictionary in WarOrders.known_places():
		if "town:"+String(t.city_id)==ref: return t
	# A town we took and no longer guard: named as what it is, as offline
	# (court_war_orders.find_target), never "we hold no town".
	for t:Dictionary in WarOrders.unguarded_towns():
		if "town:"+String(t.city_id)==ref: return t
	return {}

static func _held_of(civ_id:String)->Array[Dictionary]:
	var out:Array[Dictionary]=[]
	for t:Dictionary in WarOrders.held_towns():
		if String(t.civ_id)==civ_id: out.append(t)
	return out

static func certain(reading:Dictionary)->bool:
	## Is the target of this reading settled beyond doubt?
	var action:=String(reading.get("action",""))
	var ttype:=String(reading.get("type","none"))
	var ref:=String(reading.get("ref",""))
	if action in PERSON_ACTIONS and not action in HARM: return true
	if action in HARM and ttype in ["person","none"]: return ttype=="person" and ref!=""
	if action in HARM or action in ["town_fate","town_measure"]:
		if ref.begins_with("town:"): return true
		if ref.begins_with("people:"): return _held_of(ref.trim_prefix("people:")).size()<=1
		return WarOrders.held_towns().size()==1
	if action in ["attack","siege","raid"]: return ref.begins_with("town:") or ref.begins_with("people:")
	if action=="storm": return not WarOrders._besieged().is_empty() or ref.begins_with("town:")
	return true

static func decide(audience_id:String,text:String,reading:Dictionary,confirmed:bool=false)->Dictionary:
	## One plan from a validated reading (see the header).
	var audience:=Hall.find(audience_id)
	if reading.is_empty() or reading.has("rejected") or audience.is_empty(): return {"route":"legacy","why":String(reading.get("rejected","no reading"))}
	# "The women too" just after an order about a town we hold: that order
	# again for them (court_war_orders.follow_up), whatever the reading says.
	if not confirmed and not WarOrders.follow_up(text,audience_id).is_empty(): return {"route":"engine","context":{"reader":true}}
	# The god's word on new towns ("stop founding new towns", "our leaders may
	# settle new land again") is the engine's own switch (home_orders.gd),
	# whatever the reading made of it.
	if String(reading.kind)!="question" and not CC.HomeOrders.found_reading(text).is_empty(): return {"route":"legacy","why":"the god's word on new towns"}
	# So is who sets the daily work and people moved between tasks (manual_work.gd).
	if String(reading.kind)!="question" and not CC.HomeOrders.work_reading(text).is_empty(): return {"route":"legacy","why":"the god's word on the daily work"}
	# And raising a levy of our own: called up, drilled and armed together
	# (home_orders.gd), never read as a band's drill before a march.
	if String(reading.kind)!="question" and not CC.HomeOrders.levy_reading(text).is_empty(): return {"route":"legacy","why":"raising and drilling a levy of our own"}
	# Standing our fighters down ("dismiss 5 of our soldiers"): a count or a
	# group of our fighters is never one person to demote.
	if String(reading.kind)!="question" and not CC.HomeOrders.stand_down_reading(text).is_empty(): return {"route":"legacy","why":"standing our own fighters down"}
	# The realm's own functions (realm_orders.gd): a band formed, the army's
	# training, workshop lines, research, scouting, strangers, a great work.
	if String(reading.kind)!="question" and not CC.HomeOrders.realm_reading(text).is_empty(): return {"route":"legacy","why":"the realm's own business"}
	var action:=String(reading.action)
	var kind:=String(reading.kind)
	var conf:=float(reading.confidence)
	var mine:=pending(audience)
	var theirs:Dictionary=audience.get("pending_command",{}) if audience.get("pending_command") is Dictionary else {}
	if not theirs.is_empty() and Hall._day()-int(theirs.get("day",-99))>CC.PENDING_DAYS: theirs={}
	if action=="confirm":
		if not mine.is_empty():
			var stored:Dictionary=mine.get("reading",{})
			var plan:=decide(audience_id,String(mine.get("text","")),stored,true)
			plan["text"]=String(mine.get("text",""))
			plan["clear_pending"]=true
			return plan
		if bool(theirs.get("confirm",false)): return {"route":"engine","context":{"confirm":true,"reader":true}}
		# The war leader's own question ("Shall I send some after them?",
		# "Leave Tsaren unguarded?"): the court's answer reading takes the words.
		if String(theirs.get("ask",""))!="": return {"route":"engine","context":{"reader":true}}
		if not theirs.is_empty(): return {"route":"engine","context":{"insist":true,"reader":true}}
		return {"route":"speak"}
	if action=="cancel":
		if String(theirs.get("ask",""))!="": return {"route":"engine","context":{"reader":true}}
		return {"route":"speak","clear_pending":true}
	# The war leader put one question about a town we hold: an answer that is
	# no order of its own goes to him, and an unclear one is taken as his own
	# nearest reading (court_war_orders.pending_answer), never asked again.
	if String(theirs.get("ask",""))=="measure" and kind!="question" and (kind!="order" or action=="none"): return {"route":"engine","context":{"reader":true}}
	if kind!="question":
		# Words that hold back all they name ("don't kill him", "no, don't
		# attack", "Kavu must not be punished"): the engine answers them
		# itself, whatever the reading made of them (court_commands.holds_back).
		if CC.holds_back(audience_id,text): return {"route":"legacy","why":"the words hold the act back"}
		# A summons ("bring her to me", "I want to see the oldest man", "put
		# them on trial") is the persons engine's, never a person act read into it.
		if action in ["none","order","take","give","penance"] and String(CC.Persons.typed_action(text).get("action",""))=="summon": return {"route":"speak","why":"a summons"}
		# Talk read into the realm's own business (a law, the god's curse or
		# blessing on many or on one named, a new name for our town, an office
		# given or taken): the words' own reading carries it, as offline.
		if (kind=="speech" or action=="none") and String(audience.get("origin",""))=="court" and (CC.realm_business(audience_id,text) or CC.DIVINE.intent(text) in ["terrify","bless","raise_up"]): return {"route":"legacy","why":"the realm's own business"}
	# The captives and spoils of our last fight (or the standing word for the
	# next) are read by the war orders' own words, whatever the reading named:
	# "free the captives" read as talk is still that order (never a question).
	var captive:=WarOrders.captive_reading(text) if kind!="question" else {}
	if not captive.is_empty() and WarOrders.captive_applies(captive): return _war_plan(captive)
	if kind!="order" or action=="none": return {"route":"speak"}
	if action in LEGACY_ACTIONS: return {"route":"legacy","why":"not the reader's business"}
	# "Kill the envoy" read with nobody named: the envoy before the ruler.
	if action in PERSON_ACTIONS and String(reading.get("type",""))=="person" and String(reading.get("ref",""))=="" and CC._re("(?i)\\b(envoy|herald|messenger)\\b").search(text)!=null:
		for e:Dictionary in CC.roster(audience):
			if String(e.get("key",""))=="envoy":
				reading=reading.duplicate(); reading["ref"]="envoy"; break
	var is_grave:=grave(reading)
	var sure:=certain(reading)
	if not confirmed and (conf<MIN_CONFIDENCE or (is_grave and (conf<GRAVE_CONFIDENCE or not sure))):
		# The words' own reading (court_war_orders, as offline) names the same
		# act on the same town: two readings agree, so the words are not unclear;
		# the engine carries them as it would offline.
		if mine.is_empty() and _offline_agrees(audience,text,reading): return {"route":"legacy","why":"the words' own reading agrees"}
		var question:=String(reading.get("clarify",""))
		# One plain question, never a promise ("...and it is done").
		if question=="" or not question.ends_with("?") or CC._re(PROMISE_PATTERN).search(question)!=null: question=default_question(reading)
		if not mine.is_empty():
			# We asked already and the answer is still unclear. About a town's
			# people, the reading we asked about stands (a harm aimed at one
			# person never does); otherwise we ask differently, never the same.
			var stored:Dictionary=mine.get("reading",{})
			var stored_action:=String(stored.get("action",""))
			if stored_action in ["town_fate","town_measure"] or (stored_action in HARM and String(stored.get("type",""))!="person" and String(stored.get("type",""))!="none"):
				var plan:=decide(audience_id,String(mine.get("text","")),stored,true)
				plan["text"]=String(mine.get("text",""))
				plan["clear_pending"]=true
				plan["nearest"]=true
				return plan
			if question==String(mine.get("question","")): question="I still cannot tell what you want done, or to whom. Will you say it plainly, with the name?"
		return {"route":"clarify","question":question,"pending":{"text":text.substr(0,300),"reading":reading.duplicate(true),"day":Hall._day(),"question":question}}
	if confirmed and is_grave and not sure and String(reading.get("type",""))=="person":
		return {"route":"legacy","why":"still no one named"}
	return _engine_plan(audience,text,reading,theirs)

static func _offline_agrees(audience:Dictionary,text:String,reading:Dictionary)->bool:
	## Does the words' own reading (court_war_orders.read) name the same grave
	## act, on the same place, as the reader's unsure reading?
	var action:=String(reading.get("action",""))
	if not WarOrders.captive_reading(text).is_empty(): return action in ["kill","maim","town_fate","order"]
	# Harm to a town's people or a whole people ("maim every man in Tsaren"):
	# the offline court reads it as a war order about the town as well.
	if action in HARM and String(reading.get("type","")) in ["group","town","people"]:
		if CC.harm_to_people(text,CC.classify(text),CC.roster(audience))!="": return true
	var offline:=WarOrders.read(text,String(audience.get("civ_id","")),String(audience.get("id","")))
	if offline.is_empty(): return false
	var target:Dictionary=offline.get("target",{}) if offline.get("target") is Dictionary else {}
	var ref:=String(reading.get("ref",""))
	var same:=ref=="" or target.is_empty() or ref=="town:"+String(target.get("city_id","")) or (ref.begins_with("people:") and ref.trim_prefix("people:")==String(target.get("civ_id","")))
	if not same: return false
	match String(offline.get("kind","")):
		"fate","take_first": return action in ["town_fate","kill","maim"]
		"attack","siege","raid","storm": return action in ["attack","siege","raid","storm"]
	return false

static func _engine_plan(audience:Dictionary,text:String,reading:Dictionary,theirs:Dictionary)->Dictionary:
	var action:=String(reading.action)
	var ttype:=String(reading.type)
	var ref:=String(reading.ref)
	var details:Dictionary=reading.details
	var lower:=text.to_lower()
	var base:={"full":bool(details.get("full_force",false)) or WarOrders._has(lower,WarOrders.FULL_WORDS),"insist":WarOrders._has(lower,WarOrders.INSIST_WORDS),"place":"","army_words":true,"text":text.substr(0,300),"reader":true}
	# Harm to many is a town's fate (or a town to be taken first): never a person.
	if action in HARM and ttype in ["group","town","people"]:
		return _war_plan(_group_harm(audience,text,action,ref,details,base))
	if action in HARM and ttype!="person": return {"route":"legacy","why":"harm with no one named"}
	if action in PERSON_ACTIONS:
		if ttype in ["group","town","people","band"]: return {"route":"legacy","why":"a person act aimed at many"}
		var live:={"act":"command","verb":action,"actor_ref":String(reading.actor),"target_ref":ref,"object":String(details.get("resource","")),"confidence":float(reading.confidence)}
		if details.has("count"): live.object=("%d %s" % [int(details.count),String(live.object)]).strip_edges()
		return {"route":"engine","context":{"live":live,"reader":true}}
	match action:
		"town_fate":
			# Burning a town of theirs, with nothing said of its people, is an
			# attack on it (as offline, "Burn Eldwick"); a people's fate asks
			# to take the town first (below).
			var foreign_place:={}
			for t:Dictionary in WarOrders.known_places():
				if "town:"+String(t.city_id)==ref: foreign_place=t
			if not foreign_place.is_empty() and bool(details.get("raze",false)) and not (bool(details.get("kill_men",false)) or bool(details.get("kill_all",false)) or bool(details.get("captives",false))):
				var strike:=base.duplicate(); strike["kind"]="attack"; strike["target"]=foreign_place
				WarOrders.strike_manner(strike,lower)
				return _war_plan(strike)
			if ref.begins_with("town:") and _held_by_ref(ref).is_empty() and not _place_by_ref(ref).is_empty():
				# Their town, not ours: nobody of theirs is in our hands yet.
				var first:=base.duplicate(); first["kind"]="take_first"; first["target"]=_place_by_ref(ref)
				first["fate"]=_fate(lower,details,{}); first["harm"]="kill" if bool((first.fate as Dictionary).get("kill_men",false)) else ""
				return _war_plan(first)
			var town:=_held_by_ref(ref)
			if town.is_empty() and ref.begins_with("people:"):
				var theirs_held:=_held_of(ref.trim_prefix("people:"))
				if theirs_held.size()==1: town=theirs_held[0]
			if town.is_empty() and bool(theirs.get("which_town",false)) and ref.begins_with("town:"): town=_held_by_ref(ref)
			if town.is_empty() and WarOrders.held_towns().size()==1 and ref=="": town=WarOrders.held_towns()[0]
			if town.is_empty() and WarOrders.held_towns().is_empty():
				# The town this audience speaks of, not ours now: why, and what it would take.
				var spoken:=WarOrders._place_in_audience(String(audience.get("id","")))
				if spoken.has("city_id") and not bool(spoken.get("held",false)):
					var again:=base.duplicate(); again["kind"]="take_first"; again["target"]=spoken
					again["fate"]=_fate(lower,details,{}); again["harm"]="kill" if bool((again.fate as Dictionary).get("kill_men",false)) else ""
					return _war_plan(again)
			if town.is_empty():
				var none:=base.duplicate(); none["kind"]="no_town" if WarOrders.held_towns().is_empty() else "which_town"; none["target"]={}
				none["fate"]=_fate(lower,details,theirs)
				var names:Array[String]=[]
				for t:Dictionary in WarOrders.held_towns(): names.append(String(t.name))
				none["towns"]=names
				return _war_plan(none)
			var fate:=_fate(String(Measures.conditions(lower).main),details,theirs)
			if fate.is_empty() or not Measures.read(_unheld(text)).is_empty():
				# Nothing decided about the town itself: what the garrison is to
				# do with its people, or the war leader's nearest reading. Never
				# "it is already ours" to an order that is not an attack.
				return _war_plan(_measure_plan(text,town,details,base))
			var r:=base.duplicate()
			r["kind"]="fate"; r["fate"]=fate
			r["target"]=town
			return _war_plan(r)
		"town_measure":
			var held:=_held_by_ref(ref)
			if held.is_empty() and ref.begins_with("people:"):
				var theirs_held:=_held_of(ref.trim_prefix("people:"))
				if theirs_held.size()==1: held=theirs_held[0]
			if held.is_empty() and WarOrders.held_towns().size()==1: held=WarOrders.held_towns()[0]
			if held.is_empty() and ref.begins_with("town:") and not _place_by_ref(ref).is_empty():
				var first:=base.duplicate(); first["kind"]="take_first"; first["target"]=_place_by_ref(ref); first["fate"]={}; first["harm"]=""
				var ids:Array=details.get("measures",[])
				first["deed"]=String(WarOrders.MEASURE_DEEDS.get(String(ids[0]) if not ids.is_empty() else "","deal with its people"))
				return _war_plan(first)
			if held.is_empty():
				var none:=base.duplicate(); none["kind"]="no_town" if WarOrders.held_towns().is_empty() else "which_town"; none["target"]={}; none["fate"]={}
				var names:Array[String]=[]
				for t:Dictionary in WarOrders.held_towns(): names.append(String(t.name))
				none["towns"]=names; none["measures"]=(details.get("measures",[]) as Array).duplicate()
				return _war_plan(none)
			return _war_plan(_measure_plan(text,held,details,base))
		"attack","siege","raid":
			# "Kill the men of <their town>" read as an attack with the fate in
			# its flags: the fate is what was ordered, so it stays the fate and the
			# war leader asks to take the town first (never a bare march).
			if bool(details.get("kill_men",false)) or bool(details.get("kill_all",false)) or bool(details.get("captives",false)):
				var as_fate:=reading.duplicate(true); as_fate["action"]="town_fate"
				if String(as_fate.get("type",""))=="town": as_fate["type"]="group"
				return _engine_plan(audience,text,as_fate,theirs)
			var r:=base.duplicate(); r["kind"]=action; r["target"]=_foreign_target(ref)
			# By night, and with how many: the same words as offline.
			if details.has("count"): r["count"]=int(details.count)
			WarOrders.strike_manner(r,lower)
			# A town we already hold is not attacked: the war leader says so.
			if bool((r.target as Dictionary).get("held",false)): r["kind"]="held"
			return _war_plan(r)
		"storm":
			var besieged:=WarOrders._besieged()
			var r:=base.duplicate(); r["kind"]="storm" if not besieged.is_empty() else "attack"; r["target"]=besieged if not besieged.is_empty() else _foreign_target(ref)
			return _war_plan(r)
		"intercept","pursue":
			# Men who fled a town we hold: the chase is real (pursuit.gd).
			var held_id:=String(_held_by_ref(ref).get("city_id","")) if ref.begins_with("town:") else ""
			var flight:=preload("res://scripts/pursuit.gd").latest_flight(held_id)
			if action=="pursue" and not flight.is_empty():
				var chase:=base.duplicate(); chase["kind"]="pursue"; chase["target"]=WarOrders._held_town(String(flight.region_id)); chase["count"]=int((reading.get("details",{}) as Dictionary).get("count",0))
				return _war_plan(chase)
			var r:=base.duplicate(); r["kind"]="intercept"
			var civ:=""
			if ref.begins_with("people:"): civ=ref.trim_prefix("people:")
			elif ref.begins_with("town:"): civ=String(_place_by_ref(ref).get("civ_id",_held_by_ref(ref).get("civ_id","")))
			r["target"]={"civ_id":civ} if civ!="" else {}
			if ref.begins_with("band:"): r["army_id"]=int(ref.trim_prefix("band:"))
			return _war_plan(r)
		"recall":
			var r:=base.duplicate(); r["kind"]="recall"; r["target"]={}
			# A band out on a chase is called off as the chase ("call off the
			# chase"), which the recall of all does; another band by its id.
			if ref.begins_with("band:") and not _chasing(int(ref.trim_prefix("band:"))): r["army_id"]=int(ref.trim_prefix("band:"))
			# Home, or back to the town they came from; and whether garrisons are meant.
			var home_name:=String(WorldSimulation.state.settlement_name).to_lower() if WorldSimulation.state!=null else ""
			r["home"]=WarOrders._has(lower,"(home|withdraw|retreat|recall)") or (home_name!="" and WarOrders._name_hit(lower,home_name))
			r["garrison"]=WarOrders._has(lower,"(garrisons?|every ?one|every ?body|all of (you|them)|them all|you all|every soldier|all our|all the)")
			return _war_plan(r)
		"defend":
			# A town we hold named: its garrison is reinforced (court_war_orders._reinforce).
			var r:=base.duplicate(); r["kind"]="defend"; r["target"]=_held_by_ref(ref)
			if details.has("count"): r["count"]=int(details.count)
			return _war_plan(r)
		"drill":
			var r:=base.duplicate(); r["kind"]="drill"; r["target"]={}
			return _war_plan(r)
	return {"route":"legacy","why":"no engine mapping"}

static func _chasing(army_id:int)->bool:
	if WorldSimulation.military==null: return false
	for a in WorldSimulation.military.field_armies:
		if a is Dictionary and int((a as Dictionary).get("army_id",-1))==army_id: return (a as Dictionary).get("pursuit") is Dictionary
	return false

static func _war_plan(reading:Dictionary)->Dictionary:
	return {"route":"engine","context":{"war_reading":reading,"reader":true}}

static func _measure_plan(text:String,town:Dictionary,details:Dictionary,base:Dictionary)->Dictionary:
	## The reader's measures (ids from the list only) with what the words
	## themselves carry: who, the work, a count, a name, a condition. Nothing
	## named at all: the war leader's nearest reading ("town_word").
	var lower:=text.to_lower()
	var words:=Measures.read(_unheld(text))
	var main:=String(Measures.conditions(_unheld(lower)).main)
	var measure:Dictionary=words.duplicate(true) if not words.is_empty() else {"measures":[],"stance":"firm","stance_set":false,"families":false,"clause":"","who":"men","work":"","count":0,"headman":"","release":[],"destroy":false,"heavy":false,"people":false,"pronoun":false,"consumes":[]}
	var ids:Array[String]=[]
	for id in (details.get("measures",[]) as Array): ids.append(String(id))
	if ids.is_empty():
		for id in (measure.measures as Array): ids.append(String(id))
	measure["measures"]=ids
	var stance:=String(details.get("stance",""))
	if stance!="": measure["stance"]=stance; measure["stance_set"]=true
	if details.has("count"): measure["count"]=int(details.count)
	measure["words"]=text
	var r:=base.duplicate()
	r["target"]=town
	if ids.is_empty() and not bool(measure.stance_set):
		var fate:=_fate(main,details,{})
		if not fate.is_empty():
			r["kind"]="fate"; r["fate"]=fate
			return r
		r["kind"]="town_word"
		return r
	var reading:=WarOrders._measure_reading(text,main,town,measure,false)
	if reading.is_empty():
		r["kind"]="town_word"
		return r
	# Fate flags the reader named beside the measures ("round up the men and
	# kill them"), less those the measures already explain.
	var fate:Dictionary=(reading.get("fate",{}) as Dictionary).duplicate()
	for flag in ["kill_men","kill_all","captives","raze","tribute","leave","free"]:
		if bool(details.get(flag,false)) and not (measure.get("consumes",[]) as Array).has(flag): fate[flag]=true
	reading["fate"]=fate
	reading.merge({"reader":true,"insist":bool(base.get("insist",false)),"full":bool(base.get("full",false))},true)
	return reading

## The words less what they hold back ("don't kill the men, take them to
## Seanstone" reads only "take them to Seanstone"): a town's fate or a
## garrison's measure is never read out of a "don't" (court_realm_acts.drop_held).
static func _unheld(text:String)->String:
	return CC.Realm.drop_held(text)

static func _foreign_target(ref:String)->Dictionary:
	if ref.begins_with("town:"):
		var held:=_held_by_ref(ref)
		if not held.is_empty(): return held
		return _place_by_ref(ref)
	if ref.begins_with("people:"):
		var civ:=ref.trim_prefix("people:")
		var best:=WarOrders._primary_place(WarOrders.known_places(),civ)
		if not best.is_empty(): return best
		return {"unknown":Hall._civ_name(civ),"civ_id":civ}
	return {}

static func _fate(lower:String,details:Dictionary,theirs:Dictionary)->Dictionary:
	## What the words decide about the town, with what the reader read. The
	## reader never widens a group the words name: "kill all the women" is the
	## women, never everyone (the bound men with them).
	var fate:=TownFate.fate_words(_unheld(lower)).duplicate()
	# "Put the men to the sword": the words name whom (kill_named), and the
	# reader's "who" (often the ones to be taken) never widens it.
	var named:=fate.has("kill_groups") or fate.has("kill_named") or bool(fate.get("bound_only",false))
	var who:=String(details.get("who",""))
	for flag:String in ["kill_men","kill_all","captives","raze","tribute","spare","hold","leave","free"]:
		if not bool(details.get(flag,false)): continue
		if flag=="kill_all" and (named or who in ["men","women","children","elders","bound"]): continue
		fate[flag]=true
	# Whom the reader heard, when the words' own reading named nobody.
	if bool(fate.get("kill_men",false)) and not named and not bool(fate.get("kill_all",false)):
		match who:
			"women","children","elders": fate["kill_groups"]=[who]
			"bound": fate["bound_only"]=true
			"everyone": fate["kill_all"]=true
	if bool(fate.get("kill_all",false)): fate["kill_men"]=true
	if bool(fate.get("kill_men",false)): fate.erase("spare")
	if details.has("count"): fate["count"]=int(details.count)
	if fate.is_empty() and theirs.get("fate") is Dictionary: fate=(theirs.fate as Dictionary).duplicate()
	return fate

static func _group_harm(audience:Dictionary,text:String,verb:String,ref:String,details:Dictionary,base:Dictionary)->Dictionary:
	## Harm to a people or a town's people: that town's fate when we hold it,
	## the town to be taken first when it is theirs, else what the engine
	## reads from the words (which town / we hold none). Never {} and never a
	## person.
	var town:=_held_by_ref(ref)
	if town.is_empty() and ref.begins_with("people:"):
		var held:=_held_of(ref.trim_prefix("people:"))
		if held.size()==1: town=held[0]
	# "Kill the ringleaders", "kill any who run": a measure or a standing word
	# to the garrison, never every man in the town.
	var words:=Measures.read(_unheld(text))
	if not words.is_empty() and ((words.measures as Array).has("execute_ringleaders") or String(words.get("clause",""))!=""):
		var at:=town
		if at.is_empty() and WarOrders.held_towns().size()==1: at=WarOrders.held_towns()[0]
		if not at.is_empty(): return _measure_plan(text,at,{},base)
	var fate:=_fate(String(Measures.conditions(_unheld(text.to_lower())).main),details,{})
	if verb=="kill": fate["kill_men"]=true
	fate["group"]=true
	var out:=base.duplicate(); out["fate"]=fate; out["harm"]=verb; out["group_harm"]=true
	if not town.is_empty():
		out["kind"]="fate" if verb=="kill" else "group_maim"; out["target"]=town
		return out
	var foreign:=_foreign_target(ref)
	if foreign.has("city_id") or foreign.has("unknown"):
		out["kind"]="take_first"; out["target"]=foreign
		return out
	var own:=WarOrders.group_harm_reading(text,verb,"",String(audience.get("civ_id","")),String(audience.get("id","")))
	own["reader"]=true
	return own

static func default_question(reading:Dictionary)->String:
	## ONE plain question, and never a promise: nothing is done until the
	## ruler answers (docs/ADJUDICATION.md: honest words).
	var action:=String(reading.get("action",""))
	var ref:=String(reading.get("ref",""))
	var name:=_ref_name(ref)
	if action in HARM and String(reading.get("type",""))=="person":
		return "Whom do you mean? Name them." if name=="" else "You mean %s? Shall I go ahead?" % name
	if action in HARM or action=="town_fate":
		var what:=_fate_phrase(reading)
		return ("Which town's people do you mean, and what is to be done: %s?" % what) if name=="" else ("%s: %s. Is that your word?" % [name,what.capitalize() if what=="" else what])
	if action in ["attack","siege","raid","storm"]:
		return "Which town do we march on?" if name=="" else "Shall we march on %s now?" % name
	if action=="town_measure":
		var shorts:PackedStringArray=PackedStringArray()
		for id in ((reading.get("details",{}) as Dictionary).get("measures",[]) as Array):
			shorts.append(String((Measures.CATALOGUE.get(String(id),{}) as Dictionary).get("short",id)))
		var what:=" and ".join(shorts) if not shorts.is_empty() else "deal harshly with any who resist"
		return ("Which town's people do you mean, for this: %s?" % what) if name=="" else ("In %s, %s. Is that your word?" % [name,what])
	return "What would you have done?"

static func _fate_phrase(reading:Dictionary)->String:
	var d:Dictionary=reading.get("details",{})
	var parts:PackedStringArray=PackedStringArray()
	var who:=String(d.get("who",""))
	if who in ["women","children","elders","bound"] and (bool(d.get("kill_men",false)) or bool(d.get("kill_all",false)) or String(reading.get("action",""))=="kill"):
		parts.append("put %s to death" % String({"women":"the women","children":"the children","elders":"the old people","bound":"the bound men"}[who]))
	elif bool(d.get("kill_all",false)) or who=="everyone": parts.append("put everyone to death")
	elif bool(d.get("kill_men",false)) or String(reading.get("action",""))=="kill": parts.append("put the men to death")
	if bool(d.get("captives",false)): parts.append("take captives")
	if bool(d.get("raze",false)): parts.append("burn it")
	if bool(d.get("leave",false)): parts.append("leave it")
	return " and ".join(parts) if not parts.is_empty() else "what is to become of it"

static func _ref_name(ref:String)->String:
	if ref=="": return ""
	if ref.begins_with("town:"):
		var t:=_held_by_ref(ref)
		if t.is_empty(): t=_place_by_ref(ref)
		return String(t.get("name","")).trim_prefix("Reported home of ")
	if ref.begins_with("people:"): return Hall._civ_name(ref.trim_prefix("people:"))
	return ""

# --------------------------------------------------------------------------
# Carrying out a plan (the modal and the tests share this)
# --------------------------------------------------------------------------

static func carry_out(audience_id:String,text:String,plan:Dictionary,context:Dictionary={})->Dictionary:
	## Engine and clarify plans are acted on here; speak and legacy are the
	## caller's (they need the voice or the regex path). Returns
	## {route, result?, question?}. context carries terrain / civic_settlement.
	var audience:=Hall.find(audience_id)
	var route:=String(plan.get("route","legacy"))
	if audience.is_empty(): return {"route":"legacy"}
	if bool(plan.get("clear_pending",false)): audience.erase("reader_pending")
	match route:
		"clarify":
			audience["reader_pending"]=(plan.get("pending",{}) as Dictionary).duplicate(true)
			var question:=String(plan.get("question",""))
			var speaker:Dictionary=audience.get("speaker",{}) if audience.get("speaker") is Dictionary else {}
			var line:={"speaker":"","role":"narrator","person_id":0,"civ_id":"","text":question,"day":Hall._day(),"aside":false}
			if String(audience.get("origin",""))=="court" and String(speaker.get("name",""))!="":
				line={"speaker":String(speaker.name),"role":"official","person_id":int(speaker.get("person_id",0)),"civ_id":"player","text":question,"day":Hall._day(),"aside":false}
			Hall.append_line(audience_id,line)
			return {"route":"clarify","question":question}
		"engine":
			var ctx:=context.duplicate()
			ctx.merge(plan.get("context",{}) as Dictionary,true)
			ctx["echoed"]=true
			var said:=String(plan.get("text",text))
			var heard:=CC.hear(audience_id,said,ctx)
			if bool(heard.get("handled",false)): audience.erase("reader_pending")
			return {"route":"engine","result":heard}
		"speak":
			return {"route":"speak"}
	return {"route":"legacy"}

## A question that promises the deed before the ruler has answered.
const PROMISE_PATTERN:="(?i)\\b(it is done|it's done|it will be done|it shall be done|consider it done|and we go|and i go|i will see it done|see it done)\\b"

## A plain no to a question the court asked.
const NO_PATTERN:="(?i)^\\s*(no|nay|not yet|not now|wait|hold|stop|leave it|let it be|never mind|forget it|don't|do not)(,? (not yet|not now|wait|leave it|let it be|don't|do not|stop))?[\\s!.]*$"

static func quick_plan(audience_id:String,text:String)->Dictionary:
	## Words the reader need not read (no model call, no wait on it): a
	## question is discussion, never an order (the engine's own rule, as
	## offline); a plain yes or no to a question the court itself asked is
	## that question's answer, decided exactly as the reader's confirm or
	## cancel would be. {} when the reader should read the words.
	var clean:=text.strip_edges()
	var audience:=Hall.find(audience_id)
	if audience.is_empty() or clean.is_empty(): return {}
	if clean.ends_with("?"): return {"route":"speak","quick":"question"}
	var theirs:Dictionary=audience.get("pending_command",{}) if audience.get("pending_command") is Dictionary else {}
	var open:=not pending(audience).is_empty() or (not theirs.is_empty() and Hall._day()-int(theirs.get("day",-99))<=CC.PENDING_DAYS)
	# A bare "SEND THEM!" or "Do it!" with nothing open: the court's own
	# answer to it (the march already on the road, or "send whom, and
	# where?"), never a fresh order read into it (court_commands._assent).
	if not open: return {"route":"legacy","quick":"assent"} if CC.bare_assent(clean) else {}
	var action:=""
	if CC._re(CC.CONFIRM_PATTERN).search(clean)!=null or CC._re(CC.INSIST_PATTERN).search(clean)!=null or CC.bare_assent(clean): action="confirm"
	elif CC._re(NO_PATTERN).search(clean)!=null: action="cancel"
	if action=="": return {}
	var plan:=decide(audience_id,text,{"kind":"order","action":action,"actor":"","type":"none","ref":"","details":{},"confidence":0.95,"clarify":""})
	plan["quick"]=action
	return plan

static func offline_confirm(audience_id:String,text:String)->Dictionary:
	## The reader failed on an answer to its own question: a plain "yes"
	## still carries the order it asked about (read then), a plain "no"
	## drops it. {} when there is no such question or these are other words.
	var audience:=Hall.find(audience_id)
	var mine:=pending(audience)
	if mine.is_empty(): return {}
	var re:=RegEx.new(); re.compile(CC.CONFIRM_PATTERN)
	if re.search(text.strip_edges())!=null or CC._re(CC.INSIST_PATTERN).search(text.strip_edges())!=null:
		var plan:=decide(audience_id,String(mine.get("text","")),mine.get("reading",{}),true)
		plan["text"]=String(mine.get("text",""))
		plan["clear_pending"]=true
		return plan
	var no:=RegEx.new(); no.compile("(?i)^\\s*(no|nay|not yet|wait|hold|stop|leave it|never mind|forget it|don't|do not)\\b")
	if no.search(text)!=null: return {"route":"speak","clear_pending":true}
	return {}
