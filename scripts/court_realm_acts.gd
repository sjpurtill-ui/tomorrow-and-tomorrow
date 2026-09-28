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
##                suri", "flog the headman", "let kishan go", "fire kavu").
##   the council's people and the court's known persons: who is in the
##                roster beside the officials (put out of office, held under
##                guard; the commoners the court has named or brought in).
## Static helpers; preload.

const Hall:=preload("res://scripts/audience_hall.gd")
const DIVINE:=preload("res://scripts/divine_regard.gd")
const WarOrders:=preload("res://scripts/court_war_orders.gd")
const Persons:=preload("res://scripts/court_persons.gd")

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
			"office_key":"","settlement_id":"","speaker":false,"present":false,"status":status})
	return out

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
# Verbs that fall on one person, named in any case
# --------------------------------------------------------------------------

## [verb, pattern]: the verb phrase; the person must be named (by name, title
## or "him"/"her") after it, or before it in a passive ("have kishan whipped",
## "Kavu must be punished").
const PERSON_VERBS:=[
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

static func person_verb(text:String,list:Array[Dictionary],mentions:Callable,salient:Callable)->Dictionary:
	## {verb, key, at, harm?} when a person verb falls on one person named in
	## the words; {} otherwise. mentions(text,list) and salient() come from
	## court_commands (its own reading of names and pronouns).
	var clean:=text.strip_edges()
	for pair in PERSON_VERBS:
		var m:=_re(String(pair[1])).search(clean)
		if m==null: continue
		var verb:=String(pair[0])
		var found:Array=mentions.call(clean,list)
		var target:Dictionary={}
		# After the verb (or inside its phrase: "let kishan go", "set her free",
		# "take Kavu's office").
		for f:Dictionary in found:
			if int(f.end)<=m.get_start(): continue
			if String(f.by) in ["guards","god"]: continue
			# "Let them go", "untie them": many people, never one person here.
			if String(f.by)=="pronoun" and not String(f.word) in ONE_PERSON: continue
			if String(f.by) in ["name","title"] and String(f.get("of",""))!="" and not (verb=="demote" and String(f.of) in ["office","post","rank","title","seat","command","place"]): continue
			target=f; break
		# A passive: "have kishan whipped", "Kavu must be punished", "Kavu is dismissed".
		if target.is_empty():
			for f:Dictionary in found:
				if int(f.end)>m.get_start() or not String(f.by) in ["name","title"]: continue
				if String(f.get("of",""))!="": continue
				var between:=clean.substr(int(f.end),m.get_start()-int(f.end)).to_lower().strip_edges()
				var before:=clean.substr(0,int(f.at)).to_lower()
				var passive:=_has(between,"^(must|should|shall|will|is to|are to|is|are|was|to)?\\s*(be|be now|now be|now)?$") and _has(m.get_string(),"(?i)(ed|en)$|^free$")
				var had:=_has(before,"(?i)\\b(have|get|see that|see to it that|let)\\s*$") and _has(m.get_string(),"(?i)(ed|en)$")
				if passive or had: target=f
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
	["terrify","(?i)\\b(terrify|terrorize|terrorise|frighten|scare|strike (fear|terror) into|put (the )?fear (of [\\w ]+ )?into|make (?<o1>[\\w' ]{1,40}?) (fear|dread) me|show (?<o2>[\\w' ]{1,40}?) my (wrath|anger|fury|might|power)|let (?<o3>[\\w' ]{1,40}?) (feel|know|see) my (wrath|anger|fury)|let (?<o4>[\\w' ]{1,40}?) tremble)\\b"],
	["curse","(?i)\\b(curse|damn)\\b"],
	["bless","(?i)\\b(bless|show (?<o5>[\\w' ]{1,40}?) my (favou?r|love|kindness|mercy))\\b"],
]
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
		for n in ["o1","o2","o3","o4","o5"]:
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
					ForeignDiplomacy.remember(civ_id,"The ruler of %s sent their anger against us: fires on the ridges at night and a warning cried to our herders." % home)
					var rivals:=Hall._rivals()
					if rivals!=null and not at_war: rivals.call("grudge",civ_id,"how you threatened us for no cause",0.2,"threatened:%s:%d" % [id,Hall._day()])
					r.outcome="Your anger is carried to the %s%s: %s. Their dread of you rises, and so does their hatred." % [people,place,"our warriors light fires on the ridges above them at night and cry your name down at their herders" if at_war else "word of it goes to them with the herders and traders who pass between us"]
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

static func answer_whom(audience:Dictionary,text:String,list:Array[Dictionary],mentions:Callable)->Dictionary:
	## After "Whom do you mean?": the words that name them carry the act asked
	## about ({act, target}); {} when these are other words.
	var p:Dictionary=audience.get("pending_command",{}) if audience.get("pending_command") is Dictionary else {}
	if String(p.get("verb",""))!="divine" or String(p.get("ask",""))!="whom" or Hall._day()-int(p.get("day",-99))>2: return {}
	var lo:=text.strip_edges().to_lower().trim_suffix(".").trim_suffix("!").strip_edges()
	lo=_re("(?i)^(i mean|i meant|them|the ones|,|\\s)+").sub(lo,"",true).strip_edges()
	var target:=_group_target(lo,audience)
	if target.is_empty() or String(target.kind)=="unclear": return {}
	return {"act":String(p.get("act","terrify")),"target":target,"words":String(p.get("text",""))}

# --------------------------------------------------------------------------
# Laws for our own people
# --------------------------------------------------------------------------

## Explicit words of law.
const LAW_WORDS:="(?i)(\\bfrom (now|this day|today)( on)?\\b|\\bhenceforth\\b|\\bmake (it )?a law\\b|\\bpass a law\\b|\\bit is (now )?(the )?law\\b|\\b(is|are) (now )?forbidden\\b|\\bforbid\\b|\\bno ?(one|body)\\b[\\w' ]{0,30}?\\b(may|shall|is to|can|will|must|leaves?|goes|works?|eats|walks|sleeps|hunts)\\b|\\bnone (may|shall)\\b|\\bevery ?(one|body)\\b[\\w' ]{0,30}?\\b(must|shall|is to)\\b|\\bevery (newborn|child|man|woman|family|household|hearth|hunter|boy|girl)\\b[\\w' ]{0,30}?\\b(must|shall|is to|will)\\b|\\b(a|any|each) (man|woman|husband|wife|child|family|household)\\b[\\w' ]{0,20}?\\b(must|may|shall|is to)\\b|\\bevery (second|third|fourth|fifth|sixth|seventh|tenth|\\w+th) day\\b|\\b(thieves|liars|hoarders|murderers|deserters|cowards|drunkards)\\b[\\w' ]{0,12}\\b(are|will be|shall be) to be\\b|\\b(are|is) to be (flogged|whipped|beaten|banished|exiled|driven out|put to death|killed|hanged|fined|branded|punished|burned)\\b)"
## Our own wrongdoers, never a foe: the objects of a law.
const CRIME_RE:="(?i)\\b(thie(f|ves)|steal(s|ing|ers?)?|stole|hoard(s|ers?|ing)?|murder(s|ers?|ing)?|killers?|the lazy|lazy|idle(rs)?|the idle|slackers?|shirk(ers|ing)?|drunk(ards?|s)?|liars?|lying|cheat(s|ers)?|adulter(y|ers?)|deserters?|cowards?|oath-?breakers?|poach(ers|ing)?|brawl(ers|ing)?|sleep(s|ing)? on (the )?(watch|duty)|trespass(ers)?|robbers?|robbing)\\b"
## Hard hands a law may lay on them.
const HARSH_RE:="(?i)\\b(kill|execute|put to death|hang|behead|slay|flog|whip|lash|beat|burn|banish|exile|drive out|cast out|brand|maim|cut off|blind|stone)\\w*\\b"
## "Anyone who resists": a garrison's standing word, never a law at home.
const WAR_CLAUSE:="(?i)\\b(resist|resists|resisted|run|runs|ran|flee|flees|fled|fight|fights|fought|attack|attacks|escape|escapes|escaped|hide|hides|raise|raises|rebel|rebels|refuse|refuses|got away)\\b"

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
		"(?i)^\\s*(call|name)\\s+(our|the|this|my)\\s+%s\\s+(?<new>[\\w' -]{2,32}?)(\\s+from (now|today|this day)( on)?)?$" % PLACE_WORDS,
		"(?i)^\\s*(from (now|today|this day)( on)?,?\\s+)?(?<old>[\\w' ]{2,40}?)\\s+(shall|will|is to)\\s+(now\\s+)?be\\s+(called|named|known as)\\s+(?<new>[\\w' -]{2,32}?)(\\s+from (now|today|this day)( on)?)?$",
		"(?i)^\\s*(from (now|today|this day)( on)?,?\\s+)?(our|the|my)\\s+%s\\s+(is|shall be|will be)\\s+(called|named)\\s+(?<new>[\\w' -]{2,32})$" % PLACE_WORDS,
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
