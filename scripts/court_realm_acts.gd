extends RefCounted
## THE REALM'S OWN BUSINESS AT COURT.
##
## Read from the ruler's words and carried out through the real systems, then
## said plainly (docs/ADJUDICATION.md): court_commands.hear() asks these first
## for words that are not war.
##
##   group acts   the god's anger or favour on a whole people, a town, our own
##                people, the court, or the fields ("Terrify the Esurai",
##                "Bless the harvest", "Show them my wrath"): the peoples'
##                dread and opinion (divine_regard.gd, the relation), the
##                people's love and dread of the god, the court's own bonds.
##                Never a hand on the one who hears it. Unclear: one question.
##   laws         a law for our own people ("Punish the thieves", "Banish
##                anyone who hoards grain", "From now on a man may take only
##                one wife"): a standing order through the council's custom
##                directive path; a harsh law is remembered with dread.
##                Never a war order, never a hand on anyone in the hall.
##   the name     "Rename Seanstone to Godshold": the settlement model.
##   person verbs a verb that falls on one person named in any case ("bless
##                suri", "flog the headman", "let kishan go", "fire kavu",
##                "kavu your fired", "Kavu must die"); never what they did
##                ("Kavu whipped the boy"); on a condition, a threat.
##   held back    the clauses of the words, and which of them hold an act back
##                ("don't kill him", "Kavu must not be punished"): read by
##                court_commands._held_back, never carried out as the act.
##   the council's people and the court's known persons: who is in the
##                roster beside the officials (put out of office, held under
##                guard; the commoners the court has named or brought in).
## Static helpers; preload.

const Hall:=preload("res://scripts/audience_hall.gd")
const DIVINE:=preload("res://scripts/divine_regard.gd")
const WarOrders:=preload("res://scripts/court_war_orders.gd")
const Persons:=preload("res://scripts/court_persons.gd")
const NationName:=preload("res://scripts/nation_name.gd")
const EraWords:=preload("res://scripts/hud/era_words.gd")

static func _re(pattern:String)->RegEx:
	var re:=RegEx.new(); re.compile(pattern)
	return re

static func _has(text:String,pattern:String)->bool:
	return _re(pattern).search(text)!=null

# --------------------------------------------------------------------------
# Who else is at court: the council's people and the court's known persons
# --------------------------------------------------------------------------

## Known commoners listed beside the officials (the one before the god, the
## one just named, and the few most recently seen).
const KNOWN_IN_ROSTER:=6
## The council's people out of office listed beside the officials.
const FORMER_IN_ROSTER:=8

static func former_entries(listed:Dictionary)->Array[Dictionary]:
	## The council's people who hold no office now but whom the god has dealt
	## with: put out of office, or held under guard. {key "person:<pid>",
	## kind "former", status}. listed: person ids already in the roster.
	var out:Array[Dictionary]=[]
	for p in GovernmentPeopleSystem.people:
		if not p is Dictionary: continue
		var pid:=int((p as Dictionary).get("person_id",0))
		if pid<=0 or listed.has(pid): continue
		var status:=String((p as Dictionary).get("status",""))
		var reason:=String((p as Dictionary).get("removal_reason",""))
		var held:=status=="detained"
		var put_out:=status=="active" and String((p as Dictionary).get("office_key",""))=="" and reason in ["dismissed","arrested","exiled"]
		if not held and not put_out: continue
		out.append({"key":"person:%d" % pid,"kind":"former","person_id":pid,"figure_id":"","name":String(p.get("name","")),"title":"held under guard" if held else "once of the council",
			"office_key":"","settlement_id":"","speaker":false,"present":false,"status":status,"since":int((p as Dictionary).get("removed_day",0))})
	# The most recent first, a handful at most (the roster stays short).
	out.sort_custom(func(a:Dictionary,b:Dictionary)->bool: return int(a.since)>int(b.since))
	return out.slice(0,FORMER_IN_ROSTER)

static func known_entries(audience:Dictionary)->Array[Dictionary]:
	## The commoners the court knows by name: the one before the god first,
	## then whoever was just named, then the most recently seen.
	var out:Array[Dictionary]=[]
	var speaker_id:=String(((audience.get("speaker",{}) as Dictionary) if audience.get("speaker") is Dictionary else {}).get("known_id",""))
	var focus:Dictionary=Persons.state().focus.get("person",{}) if Persons.state().focus.get("person") is Dictionary else {}
	var focus_id:=String(focus.get("id","")) if String(focus.get("kind",""))=="known" else ""
	var living:Array=[]
	for p in Persons.people():
		if not p is Dictionary: continue
		if String((p as Dictionary).get("status",""))!="living" or int((p as Dictionary).get("count",1))>1: continue
		living.append(p)
	living.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
		var ra:=2 if String(a.id)==speaker_id else (1 if String(a.id)==focus_id else 0)
		var rb:=2 if String(b.id)==speaker_id else (1 if String(b.id)==focus_id else 0)
		if ra!=rb: return ra>rb
		return int(a.get("last_seen_day",0))>int(b.get("last_seen_day",0)))
	for p in living.slice(0,KNOWN_IN_ROSTER):
		var rec:Dictionary=p
		var here:=String(rec.id)==speaker_id
		out.append({"key":"known:"+String(rec.id),"kind":"known","person_id":0,"figure_id":"","known_id":String(rec.id),"name":String(rec.get("name","")),"title":Persons.title_of(rec),
			"office_key":"","settlement_id":"","speaker":here,"present":here,"focus":String(rec.id)==focus_id,"trade":String(rec.get("trade",""))})
	return out

# --------------------------------------------------------------------------
# Words that hold an act back ("don't kill him", "Kavu must not be punished")
# --------------------------------------------------------------------------

## A clause that forbids or holds back what it names: "don't", "never",
## "I won't", "you must not", "no need to".
const HOLD_LEAD:="(?i)^\\W*(?:(?:no|nay|nope|wait|stop|hold|enough|please|god|gods|oh|ah|now|listen|look|i said|i told you|i say)\\b[\\s,.!]*)*(?:please\\s+)?(?<lead>don'?t|do not|dont|never(?: again| ever)?|you (?:will|shall|must|may) not|you won'?t|you mustn'?t|you shan'?t|i (?:will|shall|do) not|i won'?t|i don'?t|we (?:will|shall|do) not|we won'?t|we don'?t|let us not|let'?s not|lets not|no need to|there is no need to|nobody is to|no ?one is to|none of you (?:is|are) to|none of you (?:will|shall|may)|(?:nobody|no ?one|none of you)(?= (?:lays|touches|harms|hurts|strikes|hits|kills)\\b))\\b\\s*"
## "Kavu must not be punished", "Suri is not to be harmed", "he won't be flogged".
const HOLD_PASSIVE:="(?i)^\\W*(?<who>[\\w' -]{2,40}?)\\s+(?:(?:must|shall|will|should|is|are)\\s*(?:not|n't|never)|won'?t|shan'?t|mustn'?t)\\s+(?:to\\s+)?(?<rest>be\\b.*)$"
## A clause that is no act at all ("no", "wait", "instead").
const FILLER_CLAUSE:="(?i)^\\W*(?:(?:no|nay|nope|wait|stop|hold|enough|please|god|gods|oh|ah|now|just|instead|rather|not yet|not now|not that|never|never mind|sorry|forget it|no no)\\b[\\s,.!]*)*$"
## Where one thing said ends and the next begins.
const CLAUSE_BREAK:="(?i)[,;.!?]+|\\s+but\\s+|\\s+instead\\b|\\s+rather\\b"

static func clauses(text:String)->Array[Dictionary]:
	## The words split where one thing said ends and another begins:
	## {text, held, stripped, filler}. held: the clause forbids or holds back
	## the act it names ("don't kill him"); stripped: that act itself ("kill
	## him"), for reading what is held back.
	var clean:=text.replace("’","'").strip_edges()
	var pieces:PackedStringArray=[]
	var at:=0
	for m in _re(CLAUSE_BREAK).search_all(clean):
		pieces.append(clean.substr(at,m.get_start()-at)); at=m.get_end()
	pieces.append(clean.substr(at))
	var out:Array[Dictionary]=[]
	for piece in pieces:
		var p:=String(piece).strip_edges()
		if p=="": continue
		var held:=false
		var stripped:=p
		var lead:=_re(HOLD_LEAD).search(p)
		if lead!=null:
			held=true; stripped=p.substr(lead.get_end()).strip_edges()
		else:
			var passive:=_re(HOLD_PASSIVE).search(p)
			if passive!=null:
				held=true; stripped="%s must %s" % [passive.get_string("who").strip_edges(),passive.get_string("rest").strip_edges()]
		out.append({"text":p,"held":held,"stripped":stripped,"filler":_has(p,FILLER_CLAUSE)})
	return out

static func drop_held(text:String)->String:
	## The words less what they hold back: "don't kill the men, take them to
	## Seanstone" -> "take them to Seanstone"; "don't kill the men of Tsaren"
	## -> "". The words unchanged when nothing is held back. For readings of a
	## town's fate or a garrison's measures, which read "kill the men" in them.
	var parts:=clauses(text)
	if not parts.any(func(p:Dictionary)->bool: return bool(p.held)): return text
	var kept:=PackedStringArray()
	for p:Dictionary in parts:
		if not bool(p.held) and not bool(p.filler): kept.append(String(p.text))
	return ", ".join(kept)

# --------------------------------------------------------------------------
# Verbs that fall on one person, named in any case
# --------------------------------------------------------------------------

## [verb, pattern, passive only]: the verb phrase; the person must be named (by
## name, title or "him"/"her") after it, or before it in a passive ("have
## kishan whipped", "Kavu must be punished", "Kavu must die").
const PERSON_VERBS:=[
	["kill","(?i)\\b(killed|executed|slain|beheaded|hanged|hung|put to death|die|dies)\\b",true],
	["exile","(?i)\\b(banished|exiled|expelled|cast out|driven out)\\b",true],
	["maim","(?i)\\b(flog|flogged|whip|whipped|lash|lashed|beat|beaten|thrash|thrashed|cane|caned|scourge|scourged)\\b"],
	["pardon","(?i)\\b(pardon|pardoned|forgive|forgiven|free|freed|release|released|unchain|unchained|unbind|untie|set [\\w' ]{1,20}? free|let [\\w' ]{1,30}? go|spare|spared|show mercy to|have mercy on)\\b"],
	["curse","(?i)\\b(curse|cursed|damn)\\b"],
	["terrify","(?i)\\b(terrify|terrified|frighten|frightened|scare|scared|strike fear into|put (the )?fear (of [\\w ]+ )?into)\\b"],
	["penance","(?i)\\b(punish|punished|chastise|chastised|discipline|disciplined|rebuke)\\b"],
	["bless","(?i)\\b(bless|blessed|praise|thank|commend)\\b"],
	["raise","(?i)\\b(honou?r|honou?red|promote|promoted|exalt|elevate|favou?r)\\b"],
	["boon","(?i)\\b(reward|rewarded)\\b"],
	["demote","(?i)\\b(dismiss|dismissed|fire|fired|sack|sacked|depose|deposed|replace|replaced|unseat|oust|ousted|strip|take [\\w' ]{0,30}?\\b(office|post|rank|title|seat|command)\\b)\\b"],
	["marry","(?i)\\b(marry|married|wed)\\b"],
]
## Pronouns that point at one person ("them" never does on its own).
const ONE_PERSON:=["him","her","you","yourself","himself","herself","this one","that one","the traitor","the wretch","this wretch","the fool","this fool","that fool","the dog","this dog","that dog","the coward","this coward"]
## "Tell Kavu to punish the thieves": the one named is the hand, not the one punished.
const ACTOR_LEAD:="(?i)\\b(tell|ask|order|command|have|let|make|send|get)\\s+$"
## A decree's own ending ("Kavu is dismissed.", "Kavu dies at dawn"): nothing
## after the verb that makes it something they did ("Kavu whipped the boy").
const BARE_TAIL:="(?i)^(now|at once|today|tonight|tomorrow|at dawn|at first light|at sunrise|immediately|forever|for good|again|from (his|her|their|the|this|my) (office|post|place|duties|command|service|court|hall|sight|seat)|for (this|that|it|his crimes|her crimes|their crimes|what (he|she|they) did|(his|her|their) (crimes|lies|failure|insolence|treachery))|before (the court|us all|everyone|you all|them all)|in front of everyone|,? ?(do you hear|understood|is that clear))*\\W*$"
## A decree's words before the verb: "must be", "is to be", "shall".
const STRONG_AUX:="(?i)^(must|should|shall|will|is to|are to|to|you will|you shall|you must|you are to|you're to)\\s*(be|be now|now be|now)?$|^(be|be now|now be)$"
## "Kavu is dismissed", "you're fired": only as the decree's whole ending.
const WEAK_AUX:="(?i)^(is|are|you'?re|youre|your|you are|ur|u r)\\s*(now)?$"
## A condition after the act: a threat, not the act ("flog Kavu if he lies again").
const CONDITION:="(?i)\\b(if|unless|should (he|she|they|you)|next time|the next time|ever again)\\b"

static func person_verb(text:String,list:Array[Dictionary],mentions:Callable,salient:Callable)->Dictionary:
	## {verb, key, at, harm?} when a person verb falls on one person named in
	## the words; {} otherwise. mentions(text,list) and salient() come from
	## court_commands (its own reading of names and pronouns).
	var clean:=text.strip_edges().replace("’","'")
	for pair in PERSON_VERBS:
		var m:=_re(String(pair[1])).search(clean)
		if m==null: continue
		var verb:=String(pair[0])
		var passive_only:=(pair as Array).size()>2 and bool(pair[2])
		var found:Array=mentions.call(clean,list)
		var target:Dictionary={}
		# After the verb (or inside its phrase: "let kishan go", "set her free",
		# "take Kavu's office").
		for f:Dictionary in found:
			if passive_only: break
			if int(f.end)<=m.get_start(): continue
			if String(f.by) in ["guards","god"]: continue
			# "Let them go", "untie them": many people, never one person here.
			if String(f.by)=="pronoun" and not String(f.word) in ONE_PERSON: continue
			if String(f.by) in ["name","title"] and String(f.get("of",""))!="" and not (verb=="demote" and String(f.of) in ["office","post","rank","title","seat","command","place"]): continue
			target=f; break
		# A passive: "have kishan whipped", "Kavu must be punished", "Kavu is
		# dismissed", "kavu, you're fired", "Kavu must die". Never what they did
		# themselves ("Kavu whipped the boy", "Suri blessed the hunt"), nor what
		# was ("Kavu was flogged").
		var word:=m.get_string().to_lower()
		# A condition after it ("Kavu must die if the stores fail again") is a
		# threat, read below; the decree's words are otherwise the same.
		var bare:=_has(clean.substr(m.get_end()).strip_edges(),BARE_TAIL) or _has(clean.substr(m.get_end()),CONDITION)
		var participle:=_has(word,"(ed|en)$") or word in ["free","slain","hung","put to death","cast out","driven out"]
		# Words of what someone is, not what is done to them ("Suri is scared").
		var weak_ok:=not verb in ["terrify","bless","raise","marry"]
		if target.is_empty():
			for f:Dictionary in found:
				if int(f.end)>m.get_start() or not String(f.by) in ["name","title"]: continue
				if String(f.get("of",""))!="": continue
				var between:=clean.substr(int(f.end),m.get_start()-int(f.end)).to_lower().replace(",","").strip_edges()
				var before:=clean.substr(0,int(f.at)).to_lower()
				var passive:=false
				if word in ["die","dies"]:
					passive=bare and (_has(between,"^(must|shall|is to|are to|has to|have to)$") or (between=="" and word=="dies"))
				else:
					passive=participle and ((between!="" and _has(between,STRONG_AUX)) or (weak_ok and bare and (between=="" or _has(between,WEAK_AUX))))
				var had:=_has(before,"(?i)\\b(have|get|see that|see to it that|let)\\s*$") and participle and not passive_only
				if passive or had: target=f
		# "You're fired", "your fired", "you are to be flogged": the one before the god.
		if target.is_empty() and participle:
			var lead:=clean.substr(0,m.get_start())
			if _has(lead,"(?i)(^|[^\\w'])(you will be|you shall be|you must be|you are to be|you're to be)\\s+(now\\s+)?$") or (weak_ok and bare and _has(lead,"(?i)(^|[^\\w'])(you'?re|youre|your|you are|ur|u r)\\s+(now\\s+)?$")):
				target={"by":"pronoun","word":"you","at":0,"end":0,"key":""}
		if target.is_empty(): continue
		# The one told to do it is the hand: "tell Kavu to punish the thieves"
		# (but "have kishan whipped" is done to Kishan).
		if _has(clean.substr(0,int(target.at)),ACTOR_LEAD) and int(target.at)<m.get_start() and not _has(m.get_string(),"(?i)(ed|en)$"): continue
		var key:=String(target.get("key",""))
		if String(target.by)=="pronoun":
			# "You" is the one before the god; "him", "her" the one just dealt with.
			var who:Dictionary={}
			if String(target.word) in ["you","yourself"]:
				for e:Dictionary in list:
					if bool(e.get("speaker",false)): who=e
			# "Kishan is useless. Replace him": the one named just before.
			if who.is_empty() and String(target.word) in ["him","her","them"]:
				var before:Array=found.filter(func(f:Dictionary)->bool: return int(f.end)<=int(target.at) and String(f.by) in ["name","title"] and String(f.get("of",""))=="")
				if before.size()==1:
					for e:Dictionary in list:
						if String(e.key)==String((before[0] as Dictionary).key): who=e
			if who.is_empty(): who=salient.call()
			key=String(who.get("key",""))
		if key=="": continue
		var out:={"verb":verb,"key":key,"at":m.get_start(),"end":m.get_end()}
		if verb=="maim": out["harm"]="beat"
		if verb=="kill": out["harm"]="kill"
		# "Flog Kavu if he lies again", "Kavu must die if the stores fail": a
		# threat to them, not the act; a promise of favour is only words.
		if _has(clean,CONDITION):
			if verb in ["kill","exile","maim","curse","terrify","penance","demote"]:
				out["verb"]="terrify"; out["threat"]=true; out.erase("harm")
			else: continue
		return out
	return {}

## "Give Suri a gift of bronze", "Give Suri a gift from the stores", "Take a
## gift from the stores" (to the one before the god): a gift, maybe of a
## thing the stores do not hold.
const GIFT_RE:="(?i)\\b(give|grant|bestow|send|bring|take)\\b[\\w' ]{0,30}?\\b(a |some |this |my )?(gift|present|reward|token)s?\\b"
const MATERIALS:="(?i)\\b(bronze|iron|gold|golden|silver|copper|tin|jewels?|gems?|pearls?|amber|jade|ivory|silk|horses?|cattle|wine|salt|glass|steel|coins?)\\b"

static func gift(text:String)->Dictionary:
	## {gift:true, material:"bronze"?} for words that give someone a gift.
	var g:=_re(GIFT_RE).search(text)
	var mat:=_re(MATERIALS).search(text)
	var give_thing:=_re("(?i)\\b(give|grant|bestow|send)\\b").search(text)
	if g==null and not (give_thing!=null and mat!=null): return {}
	var out:={"gift":true}
	if mat!=null: out["material"]=mat.get_string(1).to_lower().trim_suffix("en") if mat.get_string(1).to_lower()=="golden" else mat.get_string(1).to_lower()
	out["take"]=g!=null and g.get_string(1).to_lower()=="take"
	return out

## Is this material something the stores hold? ("Stone" yes; bronze, before
## anyone works metal, no.)
static func stores_hold(material:String)->bool:
	for res in GameState.resource_stockpiles:
		if String(res).to_lower()==material or String(res).to_lower().begins_with(material): return float(GameState.resource_stockpiles[res])>=1.0
	return false

# --------------------------------------------------------------------------
# The god's anger and favour on a whole people, a town, the court, the fields
# --------------------------------------------------------------------------

const GROUP_ACTS:=[
	["terrify","(?i)\\b(terrify|terrorize|terrorise|frighten|scare|strike (fear|terror) into|put (the )?fear (of [\\w ]+ )?into|make (?<o1>[\\w' ]{1,40}?) (fear|dread) me|show (?<o2>[\\w' ]{1,40}?) my (wrath|anger|fury|might|power)|let (?<o3>[\\w' ]{1,40}?) (feel|know|see) my (wrath|anger|fury)|let (?<o4>[\\w' ]{1,40}?) tremble|make (?<o6>[\\w' ]{1,40}?) (tremble|shake|cower|quake|quail|shiver)|show (?<o7>[\\w' ]{1,40}?) what (happens|befalls|comes) to (those|anyone|any|all) who (defy|cross|oppose|anger|disobey|mock|insult) me)\\b"],
	["curse","(?i)\\b(curse|damn)\\b"],
	["bless","(?i)\\b(bless|show (?<o5>[\\w' ]{1,40}?) my (favou?r|love|kindness|mercy))\\b"],
]
## Our own fighters, as a body ("bless my warriors", "curse the band").
const FIGHTERS_RE:="(?i)^(the |my |our |all (the |my |our )?|every one of (the |my |our )?)?(warriors|fighters|soldiers|spearmen|spears|men at arms|war ?band|band|bands|host|army|armies|levy|garrison|troops)\\b"
const OURS_RE:="(?i)\\b(the people|my people|our people|the townsfolk|the villagers|every ?one|every ?body|all of them|them all|all the people|the town|the camp|the village|our town|my town|the settlement|the realm|my realm|our realm|the land|my subjects|the hearths|every hearth)\\b"
const COURT_RE:="(?i)\\b(the (whole )?court|the (whole )?council|all of you|you all|every ?one here|every ?body here|my officials|the officials|this hall|the hall|the bench)\\b"
const FIELDS_RE:="(?i)\\b(the |our |my )?(harvest|fields?|crops?|herds?|flocks?|seed|sowing|planting|gardens?|orchards?|rains?|hunt|nets|the river|the land)\\b"
const VAGUE_RE:="(?i)^\\s*(them|they|those|these|those people|these people|the enemy|our enemies|our foes|the foe)\\s*[!.]*$"

static func group_act(text:String,audience:Dictionary,list:Array[Dictionary],mentions:Callable)->Dictionary:
	## {act, target:{kind:"people"|"town"|"held"|"ours"|"court"|"fields"|"unclear", ...}}
	## when the god's anger or favour falls on many; {} otherwise (a person,
	## or no such words).
	var clean:=text.strip_edges()
	var lower:=clean.to_lower()
	for pair in GROUP_ACTS:
		var m:=_re(String(pair[1])).search(clean)
		if m==null: continue
		var act:=String(pair[0])
		# The object: named inside the phrase ("make the Esurai fear me"), else after it.
		var object:=""
		for n in ["o1","o2","o3","o4","o5","o6","o7"]:
			if m.get_string(n)!="": object=m.get_string(n)
		if object=="": object=clean.substr(m.get_end())
		object=object.strip_edges()
		var lo:=object.to_lower()
		# Ending words that name no one ("now", "for me", "before you all").
		lo=_re("(?i)\\b(now|at once|today|tonight|for me|in my name|before (you|them) all|before the court)\\b").sub(lo,"",true).strip_edges(true,true)
		lo=lo.trim_suffix("!").trim_suffix(".").strip_edges()
		# One person named: that is a person act, not this.
		for f:Dictionary in mentions.call(object,list):
			if String(f.by) in ["name","title"] and String(f.get("of",""))=="": return {}
			if String(f.by)=="pronoun" and String(f.word) in ["him","her","you","yourself","himself","herself"]: return {}
		var target:=_group_target(lo,audience)
		if target.is_empty(): continue
		if act=="curse" and String(target.kind)=="fields": continue
		return {"act":act,"target":target,"words":clean.substr(0,200)}
	return {}

static func _group_target(lo:String,audience:Dictionary)->Dictionary:
	if lo=="": return {}
	# A town we hold, or one of theirs; a people by name.
	for t:Dictionary in WarOrders.held_towns():
		if WarOrders._name_hit(lo,String(t.name)): return {"kind":"held","civ_id":String(t.civ_id),"city_id":String(t.city_id),"name":String(t.name)}
	for t:Dictionary in WarOrders.known_places():
		var tname:=String(t.name).trim_prefix("Reported home of ")
		if WarOrders._name_hit(lo,tname): return {"kind":"town","civ_id":String(t.civ_id),"city_id":String(t.city_id),"name":tname}
	if WorldSimulation.world!=null:
		for c in WorldSimulation.world.civilizations:
			if not c is Dictionary or String((c as Dictionary).get("id",""))=="player": continue
			var cname:=String((c as Dictionary).get("name",""))
			if cname!="" and WarOrders._name_hit(lo,cname): return {"kind":"people","civ_id":String(c.id),"name":cname}
	var home:=String(GameState.settlement_name).to_lower()
	if _has(lo,COURT_RE): return {"kind":"court"}
	if _has(lo,FIGHTERS_RE): return {"kind":"fighters"}
	if home!="" and WarOrders._name_hit(lo,home): return {"kind":"ours","name":String(GameState.settlement_name)}
	# "Them", "them all", "everyone": the town this audience is speaking of.
	var pronoun:=_has(lo,VAGUE_RE) or _has(lo,"(?i)^\\s*(them all|all of them|every ?one|every ?body|all of them there)\\s*[!.]*$")
	if pronoun:
		var spoken:=WarOrders._place_in_audience(String(audience.get("id","")))
		if spoken.has("city_id"):
			var held:=bool(spoken.get("held",false)) or not WarOrders._held_town(String(spoken.city_id)).is_empty()
			return {"kind":"held" if held else "town","civ_id":String(spoken.get("civ_id","")),"city_id":String(spoken.city_id),"name":String(spoken.get("name","")).trim_prefix("Reported home of ")}
	if _has(lo,OURS_RE): return {"kind":"ours","name":String(GameState.settlement_name)}
	if _has(lo,FIELDS_RE): return {"kind":"fields"}
	# "Them" with nobody spoken of: nobody can tell whom.
	if _has(lo,VAGUE_RE): return {"kind":"unclear"}
	return {}

## What each act does to a foreign people: [their dread, opinion, border tension].
const PEOPLE_ACT:={"terrify":[0.15,-0.05,0.06],"curse":[0.12,-0.08,0.05],"bless":[0.0,0.05,-0.03]}

static func perform_group(id:String,audience:Dictionary,r:Dictionary,g:Dictionary)->Dictionary:
	## Carries out the god's act on many, through the real ledgers, and says it.
	var act:=String(g.get("act","terrify"))
	var t:Dictionary=g.get("target",{})
	r.verb=act; r.stage="divine_group"; r.executed=true; r["group"]=t.duplicate()
	r.actor={}; r.actor_name=""; r.target={}; r.target_name=""
	var home:=String(GameState.settlement_name) if String(GameState.settlement_name)!="" else "home"
	match String(t.get("kind","")):
		"people","town":
			var civ_id:=String(t.get("civ_id",""))
			var people:=Hall._civ_name(civ_id)
			var row:Array=PEOPLE_ACT.get(act,[0.0,0.0,0.0])
			var rel:Dictionary=(WorldSimulation.world.civilizations[Hall._civ_index(civ_id)] as Dictionary).get("player_relation",{}) if Hall._civ_index(civ_id)>=0 else {}
			var at_war:=bool(rel.get("at_war",false))
			if float(row[0])>0.0: DIVINE.add_civ_dread(civ_id,float(row[0]))
			Hall._shift_relation(civ_id,float(row[1]),float(row[2]))
			var place:=(" at "+String(t.name)) if String(t.kind)=="town" else ""
			match act:
				"terrify":
					ForeignDiplomacy.remember(civ_id,"The ruler of %s proclaimed their anger against us before their whole court, and the word reached every hearth of ours." % home)
					var rivals:=Hall._rivals()
					if rivals!=null and not at_war: rivals.call("grudge",civ_id,"how you threatened us for no cause",0.2,"threatened:%s:%d" % [id,Hall._day()])
					r.outcome="You proclaim your anger against the %s%s before the court, and %s. Their dread of you rises, and so does their hatred." % [people,place,"the war carries the word to them" if at_war else "word of it goes to them with the herders and traders who pass between us"]
				"curse":
					ForeignDiplomacy.remember(civ_id,"The ruler of %s cursed our people before their whole court." % home)
					r.outcome="You curse the %s%s before the court, and the curse is carried to them. Their dread of you rises; they will not forget it." % [people,place]
				_:
					ForeignDiplomacy.remember(civ_id,"The ruler of %s blessed our people before their court." % home)
					r.outcome="You bless the %s before the court, and word of it goes to them. They think a little better of you." % people
			r["civ_dread"]=DIVINE.civ_dread(civ_id)
		"held":
			var civ2:=String(t.get("civ_id","")); var city:=String(t.get("city_id",""))
			var name:=String(t.get("name","the town"))
			if act=="bless":
				_resistance(civ2,city,-0.03)
				r.outcome="Your word of favour is carried to %s; the garrison tells its people you mean them no harm while they keep the peace. They are calmer for it." % name
			else:
				DIVINE.add_civ_dread(civ2,0.1 if act=="terrify" else 0.08)
				_resistance(civ2,city,-0.05)
				r.outcome="The garrison gathers %s's people in the open and shows them your anger%s. Nobody is harmed; they are afraid, and quieter for it." % [name," and your curse" if act=="curse" else ""]
			r["civ_dread"]=DIVINE.civ_dread(civ2)
		"ours":
			var officials:=Hall._officials()
			if act=="bless":
				DIVINE.apply_to_court("bless",{"person_id":0,"name":"the people"},officials)
				DIVINE.record_people_act("bless_people")
				_metric("cohesion",0.005)
				r.outcome="You bless your people before the fire at %s; they take heart, and love you the more for it." % home
			else:
				DIVINE.apply_to_court("terrify",{"person_id":0,"name":"the people"},officials)
				DIVINE.record_people_act("curse_people" if act=="curse" else "terrify_people")
				_metric("cohesion",-0.005)
				r.outcome=("Your anger goes out through %s: the people are gathered at the fire and see it. They are afraid of you now, and some will not forget it." if act=="terrify" else "You curse your own people before the fire at %s. They are afraid, and their love for you cools.") % home
		"court":
			var watchers:=Hall._officials()
			if act=="bless":
				DIVINE.apply_to_court("bless",{"person_id":0,"name":"the court"},watchers)
				r.outcome="You bless the whole court; every one of them stands straighter for it."
			else:
				DIVINE.apply_to_court("terrify",{"person_id":0,"name":"the court"},watchers)
				for p in watchers: GovernmentPeopleSystem.adjust_person_bonds(int(p.person_id),{"fear":0.05,"hold_days":7})
				r.outcome="Your anger fills the hall and falls on the whole court at once; nobody on the bench dares lift their eyes."
		"fighters":
			# Our own fighters: their heart for the fight, at home and in the field.
			var delta:=0.05 if act=="bless" else -0.05
			var touched:=0
			var home_army:Dictionary=MilitaryCampaign.home_army
			if int(home_army.get("troops",0))>0:
				home_army["morale"]=clampf(float(home_army.get("morale",1.0))+delta,0.0,1.5); touched+=int(home_army.troops)
			for a in MilitaryCampaign.field_armies:
				if a is Dictionary and int((a as Dictionary).get("troops",0))>0:
					a["morale"]=clampf(float((a as Dictionary).get("morale",1.0))+delta,0.0,1.5); touched+=int(a.troops)
			if touched<=0:
				r.executed=false; r.stage="none"
				r.outcome="There are no fighters of ours to %s yet." % act
				return r
			DIVINE.apply_to_court("bless" if act=="bless" else "terrify",{"person_id":0,"name":"the fighters"},Hall._officials())
			match act:
				"bless": r.outcome="You bless the fighters before the fire, all %d of them; they stand taller for it and go back to the drill ground in good heart." % touched
				"curse": r.outcome="You curse your own fighters before the court. All %d of them hear of it; they are afraid, and their heart for the fight sinks." % touched
				_: r.outcome="Your anger falls on your own fighters. All %d of them hear of it; they are afraid, and their heart for the fight sinks." % touched
		"fields":
			DIVINE.record_people_act("bless_fields")
			DIVINE.apply_to_court("bless",{"person_id":0,"name":"the fields"},Hall._officials())
			_metric("cohesion",0.005)
			r.outcome="You walk the fields with the people and bless them before everyone; they take heart and go back to the work gladly. The harvest itself will be what their work makes it."
		_:
			# Nobody can tell whom: one plain question, nothing done yet.
			r.executed=false; r.stage="none"
			var peoples:PackedStringArray=PackedStringArray()
			if WorldSimulation.world!=null:
				for c in WorldSimulation.world.civilizations:
					if not c is Dictionary or String((c as Dictionary).get("id",""))=="player": continue
					var rel2:Dictionary=(c as Dictionary).get("player_relation",{}) if (c as Dictionary).get("player_relation") is Dictionary else {}
					if int(rel2.get("contact_level",0))>0 or bool(rel2.get("at_war",false)): peoples.append("the "+String(c.get("name","")))
			peoples.append("our own people")
			var question:="Whom do you mean: %s?" % (", ".join(peoples.slice(0,peoples.size()-1))+" or "+peoples[peoples.size()-1] if peoples.size()>1 else peoples[0])
			r["actor_says"]=question
			r.outcome="Nothing is done yet: the court waits to hear whom you mean."
			audience["pending_command"]={"verb":"divine","ask":"whom","act":act,"actor":"","target":"","day":Hall._day(),"text":String(g.get("words","")).substr(0,200)}
	return r

static func _resistance(civ_id:String,city_id:String,delta:float)->void:
	var index:=Hall._civ_index(civ_id)
	if index<0: return
	var civ:Dictionary=WorldSimulation.world.civilizations[index]
	for region in civ.get("strategic_regions",[]):
		if region is Dictionary and String((region as Dictionary).get("id",""))==city_id:
			region["resistance"]=clampf(float(region.get("resistance",0.0))+delta,0.0,1.0)

static func _metric(key:String,delta:float)->void:
	var m:Dictionary=GameState.simulation_metrics
	m[key]=clampf(float(m.get(key,0.5))+delta,0.01,0.99)

static func answer_whom(audience:Dictionary,text:String,list:Array[Dictionary],mentions:Callable,consume:bool=true)->Dictionary:
	## After "Whom do you mean?": the words that name them carry the act asked
	## about ({act, target}); {} when these are other words. consume: the
	## reader's own open question is settled by it (false: only read).
	var p:Dictionary=audience.get("pending_command",{}) if audience.get("pending_command") is Dictionary else {}
	var act:=""; var said:=""
	if String(p.get("verb",""))=="divine" and String(p.get("ask",""))=="whom" and Hall._day()-int(p.get("day",-99))<=2:
		act=String(p.get("act","terrify")); said=String(p.get("text",""))
	else:
		# The live reader asked it (order_reader.gd's own open question).
		var mine:Dictionary=audience.get("reader_pending",{}) if audience.get("reader_pending") is Dictionary else {}
		if not mine.is_empty() and Hall._day()-int(mine.get("day",-99))<=2:
			var asked:=group_act(String(mine.get("text","")),audience,list,mentions)
			if not asked.is_empty() and String((asked.get("target",{}) as Dictionary).get("kind",""))=="unclear":
				act=String(asked.act); said=String(mine.get("text",""))
	if act=="": return {}
	var lo:=text.strip_edges().to_lower().trim_suffix(".").trim_suffix("!").strip_edges()
	lo=_re("(?i)^(i mean|i meant|them|the ones|,|\\s)+").sub(lo,"",true).strip_edges()
	lo=_re("(?i)\\b(of course|obviously|who else|naturally)\\b").sub(lo,"",true).strip_edges().trim_suffix(",").strip_edges()
	var target:=_group_target(lo,audience)
	if target.is_empty() or String(target.kind)=="unclear": return {}
	if consume: audience.erase("reader_pending")
	return {"act":act,"target":target,"words":said}

# --------------------------------------------------------------------------
# Laws for our own people
# --------------------------------------------------------------------------

## Explicit words of law.
const LAW_WORDS:="(?i)(\\bfrom (now|this day|today)( on)?\\b|\\bhenceforth\\b|\\bmake (it )?a law\\b|\\bpass a law\\b|\\bit is (now )?(the )?law\\b|\\b(is|are) (now )?forbidden\\b|\\bforbid\\b|\\bno ?(one|body)\\b[\\w' ]{0,30}?\\b(may|shall|is to|can|will|must|leaves?|goes|works?|eats|walks|sleeps|hunts)\\b|\\bnone (may|shall)\\b|\\bevery ?(one|body)\\b[\\w' ]{0,30}?\\b(must|shall|is to)\\b|\\bevery (newborn|child|man|woman|family|household|hearth|hunter|boy|girl)\\b[\\w' ]{0,30}?\\b(must|shall|is to|will)\\b|\\b(a|any|each) (man|woman|husband|wife|child|family|household)\\b[\\w' ]{0,20}?\\b(must|may|shall|is to)\\b|\\bevery (second|third|fourth|fifth|sixth|seventh|tenth|\\w+th) day\\b|\\b(thieves|liars|hoarders|murderers|deserters|cowards|drunkards)\\b[\\w' ]{0,12}\\b(are|will be|shall be) to be\\b|\\b(are|is) to be (flogged|whipped|beaten|banished|exiled|driven out|put to death|killed|hanged|fined|branded|punished|burned)\\b|\\b(outlaw|ban|prohibit)\\s+(all\\s+|any\\s+)?[a-z]|\\b(women|men|children|boys|girls|widows|wives|husbands|strangers|foreigners|hunters|elders|the young|the old|everyone|everybody|anyone)\\s+(may|must|shall|can|cannot|may not|must not|shall not|are to|are allowed to|are forbidden to|are free to)\\s+(now\\s+|no longer\\s+|never\\s+|also\\s+)?[a-z]|\\b(allow|permit)\\s+(the\\s+|our\\s+)?(women|men|children|widows|anyone|everyone|people|strangers|foreigners|hunters)\\s+to\\b|^\\W*never\\s+(again\\s+)?(kill|slay|harm|hurt|strike|beat|rob|steal from|take from|burn|enslave|sell|touch)\\s+(a|any|an)\\s+(man|woman|child|captive|prisoner|stranger|guest|envoy|herald|messenger|one|soul|boy|girl)\\b)"
## Our own wrongdoers, never a foe: the objects of a law.
const CRIME_RE:="(?i)\\b(thie(f|ves)|steal(s|ing|ers?)?|stole|hoard(s|ers?|ing)?|murder(s|ers?|ing)?|killers?|the lazy|lazy|idle(rs)?|the idle|slackers?|shirk(ers|ing)?|drunk(ards?|s)?|liars?|lying|cheat(s|ers)?|adulter(y|ers?)|deserters?|cowards?|oath-?breakers?|poach(ers|ing)?|brawl(ers|ing)?|sleep(s|ing)? on (the )?(watch|duty)|trespass(ers)?|robbers?|robbing)\\b"
## Hard hands a law may lay on them.
const HARSH_RE:="(?i)\\b(kill|execute|put to death|hang|behead|slay|flog|whip|lash|beat|burn|banish|exile|drive out|cast out|brand|maim|cut off|blind|stone)\\w*\\b"
## "Anyone who resists": a garrison's standing word, never a law at home.
const WAR_CLAUSE:="(?i)\\b(who|whoever|that|if|when|any who|those who)\\b[\\w' ]{0,16}?\\b(resist|resists|resisted|run|runs|ran|flee|flees|fled|fight|fights|fought|attack|attacks|escape|escapes|escaped|hide|hides|raise|raises|rebel|rebels|refuse|refuses|got away)\\b"

static func law(text:String,list:Array[Dictionary],mentions:Callable)->Dictionary:
	## {law:true, harsh:bool} for a law for our own people; {} otherwise.
	var clean:=text.strip_edges()
	var lower:=clean.to_lower()
	if clean.ends_with("?"): return {}
	var explicit:=_has(clean,LAW_WORDS)
	var crime:=_has(clean,CRIME_RE)
	# A law names a wrong, or says it is a law. "Anyone who resists" is the
	# garrison's standing word, never a law at home.
	if not explicit and not crime: return {}
	if not crime and _has(lower,WAR_CLAUSE): return {}
	# The captives and spoils keep their own standing word.
	if not WarOrders.captive_reading(clean).is_empty(): return {}
	# A law is about people in general: one person named is a person act.
	for f:Dictionary in mentions.call(clean,list):
		if String(f.by) in ["name","title"] and String(f.get("of",""))=="": return {}
		if String(f.by)=="pronoun" and String(f.word) in ["him","her"]: return {}
	# A town or a foe named is war business, not a law at home.
	if not crime and bool((load("res://scripts/court_commands.gd") as GDScript).call("_names_a_place",lower)): return {}
	return {"law":true,"harsh":_has(clean,HARSH_RE)}

# --------------------------------------------------------------------------
# The realm's own name
# --------------------------------------------------------------------------

const PLACE_WORDS:="(town|camp|village|settlement|home|place|hold|stead)"

static func rename(text:String)->Dictionary:
	## {name, old} when the words give our home a new name; {} otherwise.
	var clean:=text.strip_edges().trim_suffix(".").trim_suffix("!").strip_edges()
	var home:=String(GameState.settlement_name)
	var patterns:=[
		"(?i)^\\s*rename\\s+(?<old>[\\w' ]{1,40}?)\\s+(to|as|into)\\s+(?<new>[\\w' -]{2,32}?)(\\s+from now on)?$",
		"(?i)^\\s*((i|we)\\s+((shall|will)\\s+)?)?(call|name)\\s+(our|the|this|my)\\s+%s\\s+(?<new>[\\w' -]{2,32}?)(\\s+from (now|today|this day)( on)?)?$" % PLACE_WORDS,
		"(?i)^\\s*(from (now|today|this day)( on)?,?\\s+)?(?<old>[\\w' ]{2,40}?)\\s+(shall|will|is to)\\s+(now\\s+)?be\\s+(called|named|known as)\\s+(?<new>[\\w' -]{2,32}?)(\\s+from (now|today|this day)( on)?)?$",
		"(?i)^\\s*(from (now|today|this day)( on)?,?\\s+)?(our|the|my|this)\\s+%s\\s+(is|shall be|will be)\\s+(now\\s+)?(called|named|known as)\\s+(?<new>[\\w' -]{2,32}?)(\\s+from (now|today|this day)( on)?)?$" % PLACE_WORDS,
		"(?i)^\\s*(from (now|today|this day)( on)?,?\\s+)?(the |our |my |this )?(town|camp|village|settlement|place)'s (new )?name is (now\\s+)?(?<new>[\\w' -]{2,32}?)$",
	]
	for pat in patterns:
		var m:=_re(String(pat)).search(clean)
		if m==null: continue
		var old:=""
		for g in ["old"]:
			if m.names.has(g): old=m.get_string(g).strip_edges()
		# The old name, when given, must be ours (or "our town").
		if old!="" and not _has(old.to_lower(),"^(our|the|my|this) %s$" % PLACE_WORDS) and old.to_lower()!=home.to_lower(): continue
		var new_name:=m.get_string("new").strip_edges()
		if new_name=="" or new_name.to_lower()==home.to_lower(): continue
		var words:=PackedStringArray()
		for w in new_name.split(" ",false): words.append(w.substr(0,1).to_upper()+w.substr(1))
		return {"name":" ".join(words).substr(0,32),"old":home}
	return {}

static func perform_rename(id:String,r:Dictionary,reading:Dictionary)->Dictionary:
	var primary:Dictionary=GameState.player_settlements[0] if not GameState.player_settlements.is_empty() else {}
	for s in GameState.player_settlements:
		if s is Dictionary and bool((s as Dictionary).get("primary",false)): primary=s
	r.verb="rename"; r.stage="none"
	if primary.is_empty():
		r.executed=false
		r.outcome="Nothing is changed: there is no settlement of ours to name."
		return r
	var done:Dictionary=SettlementModel.rename_settlement(String(primary.get("id","")),String(reading.name))
	if not bool(done.get("ok",false)):
		r.executed=false
		r.outcome="Nothing is changed: %s" % String(done.get("reason","the name cannot be given."))
		return r
	GameState.settlement_name=String(done.get("name",reading.name)) if bool(primary.get("primary",true)) else GameState.settlement_name
	r.executed=true
	r.outcome="From today %s is called %s. The name is cried at every hearth, and the court will use no other." % [String(reading.get("old","our home")),String(done.get("name",reading.name))]
	preload("res://scripts/chronicle.gd").record({"key":"rename:%s:%d" % [String(primary.get("id","")),Hall._day()],"title":"A New Name: %s" % String(done.get("name","")),"text":"By the god's word, %s is called %s from this day." % [String(reading.get("old","our home")),String(done.get("name",""))],"tier":"moment","kind":"milestone","domain":"culture","ledger":true})
	return r

# --------------------------------------------------------------------------
# Our nation's name (nation_name.gd)
# --------------------------------------------------------------------------

## All our towns together, as the god says it: "our people", "our folk",
## "our tribe", or "our", "the" or "this" for a realm ("the nation").
const NATION_WHOLE:="(?:(?:our|my)\\s+(?:people|folk|tribe|clan|kin|land|nation|realm|kingdom|country|state)|(?:the|this)\\s+(?:nation|realm|kingdom|country|state))"
## "Kishan, ..." or "From now on, ..." before the words (a harsh act there is
## no name for anyone: nation() refuses it).
const NATION_LEAD:="(?:(?<voc>[\\w' ]{1,40}),\\s*)?(?:(?:from\\s+(?:now|today|this\\s+day)(?:\\s+on(?:ward)?)?|henceforth|hereafter)\\s*,?\\s+)?"
const NATION_TAIL:="(?:\\s*,?\\s+(?:from\\s+(?:now|today|this\\s+day)(?:\\s+on(?:ward)?)?|henceforth|hereafter|forever|for all time))?"
const NATION_PATTERNS:=[
	# "call our nation the Reedfolk", "name our realm Ashmark", "I name our people X", "rename the nation to X"
	"(?i)^{lead}(?:(?:i|we)\\s+(?:(?:shall|will)\\s+)?)?(?:(?:call|name|dub)\\s+{whole}|rename\\s+{whole}(?:\\s+(?:to|as|into))?)\\s+{name}{tail}$",
	# "our people shall be called X", "let our nation be known as X", "the realm is to be named X"
	"(?i)^{lead}(?:let\\s+)?{whole}\\s+(?:(?:shall|will|must|is\\s+to|are\\s+to)\\s+)?(?:now\\s+)?be\\s+(?:called|named|known\\s+as)\\s+{name}{tail}$",
	# "our nation is now called X", "our people are named X"
	"(?i)^{lead}{whole}\\s+(?:is|are)\\s+(?:now\\s+)?(?:called|named|known\\s+as)\\s+{name}{tail}$",
	# "the name of our nation is X", "our people's name shall be X"
	"(?i)^{lead}(?:the\\s+name\\s+of\\s+{whole}|{whole}'s\\s+name)\\s+(?:is|shall\\s+be|will\\s+be)\\s+(?:now\\s+)?{name}{tail}$",
	# "we shall be known as the Reedfolk", "let us be called X", "from now on we are called X"
	"(?i)^{lead}(?:let\\s+us\\s+be|we\\s+(?:are|shall\\s+be|will\\s+be))\\s+(?:now\\s+)?(?:called|named|known\\s+as)\\s+{name}{tail}$",
	# "we shall call ourselves the Reedfolk", "let us call ourselves X"
	"(?i)^{lead}(?:we\\s+(?:shall|will)\\s+|let\\s+us\\s+|let'?s\\s+)?(?:call|name)\\s+ourselves\\s+{name}{tail}$",
]
## A "name" that is no name: "call our people to the fire", "...home".
const NATION_NOT_A_NAME:=["to","in","into","at","for","from","with","back","home","out","up","down","together","here","there","now","again","forth","away","off","on","upon","before","after","and","or","so","if","when","because","by","a","an","our","my","your","their","his","her","its","them","him","us","me","you","it","that","this","these","those","what","who","whom","which","something","anything","nothing","everyone","everybody","all","every","today","tomorrow","not","no","never"]

static func nation(text:String)->Dictionary:
	## {name} when the words give all our towns together a name ("call our
	## nation the Reedfolk", "our people shall be called the Reedfolk", "name
	## our realm Ashmark"); {} otherwise, and for any question. A name in
	## quotes or after a colon reads the same.
	var clean:=text.strip_edges().replace("’","'").replace("\"","").replace("“","").replace("”","").replace(":"," ").strip_edges().trim_suffix(".").trim_suffix("!").strip_edges()
	if clean=="" or clean.ends_with("?"): return {}
	for pat in NATION_PATTERNS:
		var full:=String(pat).replace("{lead}",NATION_LEAD).replace("{whole}",NATION_WHOLE).replace("{tail}",NATION_TAIL).replace("{name}","(?<new>[\\w' -]{2,32}?)")
		var m:=_re(full).search(clean)
		if m==null: continue
		# Words before a comma are whom the god speaks to, never another order.
		var voc:=m.get_string("voc").strip_edges()
		if voc!="" and (voc.split(" ",false).size()>4 or _has(voc,HARSH_RE) or _has(voc,"(?i)\\b(and|attack|march|raid|send|give|take|bring|make|build|stop|don'?t|never|not)\\b")): continue
		var said:=m.get_string("new").strip_edges().trim_prefix("'").trim_suffix("'").strip_edges()
		var first:=said.get_slice(" ",0).to_lower()
		if said=="" or first in NATION_NOT_A_NAME: continue
		var name:=NationName.tidy(said)
		if name.length()<2: continue
		return {"name":name}
	return {}

static func perform_nation(id:String,r:Dictionary,reading:Dictionary)->Dictionary:
	## Names (or renames) our nation at the god's word; the one before the god
	## answers. With one town, the people go by its name and nothing changes.
	r.verb="nation_name"; r.stage="none"
	var place:=EraWords.word("place","town")
	var home:=String(GameState.settlement_name).strip_edges()
	var done:=NationName.give_name(String(reading.get("name","")),"court")
	r.executed=bool(done.get("ok",false))
	var why:="" if r.executed else String(done.get("why","refused"))
	match why:
		"one_town":
			r["actor_says"]="We have one %s yet, and the people go by %s. When a second %s stands, they can take a name of their own." % [place,home if home!="" else "its name",place]
			r.outcome="Nothing is changed: our people have one %s%s and go by its name until a second %s stands." % [place,(", %s," % home) if home!="" else "",place]
		"same":
			r["actor_says"]="We are %s already, as you named us." % NationName.in_sentence(String(done.get("name","")))
			r.outcome="Nothing is changed: our people are already called %s." % NationName.in_sentence(String(done.get("name","")))
		"taken":
			r["actor_says"]=String(done.get("reason",""))
			r.outcome="Nothing is changed: %s" % _lower_first(String(done.get("reason","")))
		"":
			var name:=NationName.in_sentence(String(done.get("name","")))
			var towns:=NationName.towns_words()
			r["actor_says"]=_nation_answer(r,name,NationName.in_sentence(String(done.get("old",""))),towns)
			r.outcome="From today our people are called %s. The name is told in %s, and the court will use no other." % [name,towns]
		_:
			r["actor_says"]=""
			r.outcome="Nothing is changed: %s" % _lower_first(String(done.get("reason","the name cannot be given.")))
	return r

## The one before the god answers a new name in their own manner (their
## disposition, government_people_system.leader_disposition): the name, and
## that word goes to our towns. old: the name it replaces, or "".
const NATION_ANSWERS:={
	"pragmatic":["Then we are {name}. I will send word to {towns}.","No longer {old}, then, but {name}. I will send word to {towns}."],
	"sycophantic":["{Name}! A fine name, and it suits us. I will have it cried in {towns}.","{Name}! A better name than {old}. I will have it cried in {towns}."],
	"principled":["{Name}, then. It is a good plain name. I will send word to {towns}.","{Name}, then, and not {old}. I will send word to {towns}."],
	"cantankerous":["{Name}. The people will grumble at a new name for a season, then use it. I will send word to {towns}.","Another name? Still, {name} it is. I will send word to {towns}."],
	"diplomatic":["{Name}. Strangers will know us by it now. I will send word to {towns}, and to any people we meet.","{Name}. Those who knew us as {old} will need telling too. I will send word to {towns}."],
}

static func _nation_answer(r:Dictionary,name:String,old:String,towns:String)->String:
	var person:Dictionary=GovernmentPeopleSystem.person_snapshot(int((r.get("actor",{}) as Dictionary).get("person_id",0))) if int((r.get("actor",{}) as Dictionary).get("person_id",0))>0 else {}
	var manner:=String(GovernmentPeopleSystem.leader_disposition(person).get("id","pragmatic")) if not person.is_empty() else "pragmatic"
	var pair:Array=NATION_ANSWERS.get(manner,NATION_ANSWERS.pragmatic)
	return String(pair[1] if old!="" else pair[0]).replace("{Name}",name.substr(0,1).to_upper()+name.substr(1)).replace("{name}",name).replace("{old}",old).replace("{towns}",towns)

static func _lower_first(text:String)->String:
	return text.substr(0,1).to_lower()+text.substr(1)
