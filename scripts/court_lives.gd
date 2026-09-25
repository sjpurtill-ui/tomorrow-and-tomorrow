extends RefCounted
## Lives at court: the god's people are born, bound, remembered and replaced,
## and the god's words leave marks that come back.
##
## - Deaths. When a court member dies (an officeholder or a settlement's
##   leader), the ordinary succession in GovernmentPeopleSystem still fills the
##   office at once. The court then holds a mourning matter: summoned, the
##   court mourns in its own voices and two or three candidates speak for
##   themselves. The god may confirm the one already acting or choose another;
##   GovernmentPeopleSystem makes the appointment. Silence lets the ordinary
##   succession stand. The dead join the Remembered roll.
## - Kin. Members of the bounded government cast (the realm's notables and its
##   officials) are linked as parent, child, sibling, master or apprentice.
##   Kin of the dead come forward as candidates first.
## - Portraits. Every living court member gets their own picture from the
##   existing portrait art: a distinct cell, then a mirrored one.
## - Orders. Every order the god gives leaves a small rite on the map for a few
##   days (rite_marks.gd), and 30 to 180 days later the one who carried it
##   brings back what really came of it, as a court matter.
## - Omens. When the god demands something of the sky and the real simulation
##   happens to agree soon after (the weather turns wet, the fevers ease, the
##   thaw comes), love and dread both leap and the court talks of it. Nothing
##   is faked: the world only has to agree.
## - Rivals. Foreign peoples who dread the god answer it by temperament: some
##   send tribute, some keep away, the proudest test the god's resolve.
##
## Chronicle hook: record() is the one place these moments are written down.
## Other systems read chronicle() or add_listener(callable) to receive each
## entry {day,kind,title,text,...} as it happens.
##
## State lives in the hall's saved payload under "lives" (optional; older saves
## simply start empty). Static helpers; reference with preload.

const Hall:=preload("res://scripts/audience_hall.gd")
const CV:=preload("res://scripts/character_voice.gd")
const DIVINE:=preload("res://scripts/divine_regard.gd")
const Lines:=preload("res://scripts/court_lives_lines.gd")
const EraNames:=preload("res://scripts/era_names.gd")

const KEY:="lives"
const TOPICS:=["mourning","callback","omen"]
const REMEMBERED_MAX:=40
const CHRONICLE_MAX:=80
const ORDERS_MAX:=24
const OMENS_MAX:=12
const RITES_MAX:=12
const RITES_VISIBLE:=3
const PORTRAITS_MAX:=96
const KIN_MAX:=4
const CALLBACK_MIN:=30
const CALLBACK_MAX:=180
const RIVAL_GAP:=120

static var listeners:Array[Dictionary]=[]

# --------------------------------------------------------------------------
# State
# --------------------------------------------------------------------------

static func state()->Dictionary:
	var s:Dictionary=Hall.state()
	if not s.get(KEY) is Dictionary: s[KEY]={}
	var l:Dictionary=s[KEY]
	for key in ["remembered","chronicle","rites","orders","omens"]:
		if not l.get(key) is Array: l[key]=[]
	for key in ["portraits","rivals"]:
		if not l.get(key) is Dictionary: l[key]={}
	if not _num(l.get("watch_day")): l["watch_day"]=_day()
	return l

static func _num(value:Variant)->bool:
	return (value is int or value is float) and is_finite(float(value))

static func valid_state(data:Variant)->bool:
	## Optional save block; absent in older saves.
	if not data is Dictionary: return false
	var limits:={"remembered":REMEMBERED_MAX,"chronicle":CHRONICLE_MAX,"rites":RITES_MAX,"orders":ORDERS_MAX,"omens":OMENS_MAX}
	for key:String in limits:
		if not data.has(key): continue
		if not data[key] is Array or (data[key] as Array).size()>int(limits[key]): return false
		for entry in data[key]:
			if not entry is Dictionary or not _num(entry.get("day")) or JSON.stringify(entry).length()>3000: return false
	for key in ["portraits","rivals"]:
		if data.has(key) and (not data[key] is Dictionary or (data[key] as Dictionary).size()>PORTRAITS_MAX*2): return false
	if data.has("portraits"):
		for k in data.portraits:
			var slot:Variant=data.portraits[k]
			if not k is String or not slot is Array or (slot as Array).size()<2 or not _num(slot[0]): return false
	if data.has("watch_day") and not _num(data.watch_day): return false
	return true

static func _day()->int:
	return int(GameState.elapsed_days)

static func _rng(key:String)->RandomNumberGenerator:
	var rng:=RandomNumberGenerator.new()
	rng.seed=hash("%d:lives:%s" % [int(GameState.world_seed),key])
	return rng

static func _pick(list:Array,key:String)->String:
	if list.is_empty(): return ""
	return String(list[posmod(hash("%d|%s" % [int(GameState.world_seed),key]),list.size())])

# --------------------------------------------------------------------------
# Chronicle hook
# --------------------------------------------------------------------------

static func add_listener(callable:Callable)->void:
	## Receive every chronicle entry as it is recorded: callable(entry:Dictionary).
	## Pass an object's method (held weakly, so a freed listener simply drops
	## out); remove_listener when done.
	if not callable.is_valid(): return
	var target:Object=callable.get_object()
	if target!=null and not callable.is_custom():
		for entry in listeners:
			if entry.get("ref")!=null and (entry.ref as WeakRef).get_ref()==target and StringName(entry.method)==callable.get_method(): return
		listeners.append({"ref":weakref(target),"method":callable.get_method()})
	else:
		listeners.append({"callable":callable})

static func remove_listener(callable:Callable)->void:
	var target:Object=callable.get_object()
	for entry in listeners.duplicate():
		if entry.has("callable") and entry.callable==callable: listeners.erase(entry)
		elif entry.has("ref") and (entry.ref as WeakRef).get_ref()==target and StringName(entry.method)==callable.get_method(): listeners.erase(entry)

static func record(kind:String,title:String,text:String,extra:Dictionary={},told:Dictionary={})->Dictionary:
	## The one place deaths, successions, omens, callbacks, rites and rivals'
	## answers are written down. kind: death|succession|omen|callback|rite|rival.
	## Each is also told in the people's Chronicle (chronicle.gd) as a moment or
	## a notice whose card opens the court; `told` may set its "tier", "key",
	## "focus" (AudienceModal.focus target) and "text" (Chronicle wording).
	var entry:={"day":_day(),"kind":kind.substr(0,24),"title":title.substr(0,80),"text":text.strip_edges().substr(0,600)}
	for key in extra:
		var value:Variant=extra[key]
		if value is String or value is int or value is float or value is bool: entry[String(key)]=value
	var list:Array=state().chronicle
	list.push_front(entry)
	while list.size()>CHRONICLE_MAX: list.pop_back()
	# Told once: a repeated key is simply not told again.
	var chronicled:=preload("res://scripts/chronicle.gd").active()
	_tell_chronicle(entry,told)
	if kind!="rite":
		var event:={"day":_day(),"title":title,"description":String(entry.text),"domain":"institutions" if kind in ["death","succession"] else "social","severity":"major" if kind in ["death","omen","succession"] else "notice","court_kind":kind}
		# Already in the Chronicle: its daily ledger scan must not tell it twice.
		if chronicled: event["chronicle"]=true
		GameState.simulation_events.push_front(event)
		if GameState.simulation_events.size()>80: GameState.simulation_events.resize(80)
	for listener in listeners.duplicate():
		if listener.has("callable"):
			var direct:Callable=listener.callable
			if direct.is_valid(): direct.call(entry.duplicate())
			else: listeners.erase(listener)
			continue
		var target:Object=(listener.ref as WeakRef).get_ref()
		if target==null or not is_instance_valid(target): listeners.erase(listener); continue
		target.call(StringName(listener.method),entry.duplicate())
	return entry

## Chronicle tier and card mark for each kind of court record.
const CHRONICLE_TIERS:={"death":"moment","succession":"notice","omen":"moment","callback":"notice","rite":"notice","rival":"notice"}
const CHRONICLE_KINDS:={"death":"death","succession":"court","omen":"omen","callback":"court","rite":"ceremony","rival":"contact"}

static func _tell_chronicle(entry:Dictionary,told:Dictionary)->Dictionary:
	var Chronicle:=preload("res://scripts/chronicle.gd")
	if not Chronicle.active(): return {}
	var kind:=String(entry.kind)
	var text:=String(told.get("text",entry.text))
	var key:=String(told.get("key","court:%s:%d:%s" % [kind,int(entry.day),(String(entry.title)+text).md5_text().left(10)]))
	var focus:Dictionary=told.get("focus",{}) if told.get("focus") is Dictionary else {}
	# The court's own ledger line stands in for the event ledger (rites have none).
	return Chronicle.record({"key":key,"day":int(entry.day),"title":String(entry.title),"text":text,
		"tier":String(told.get("tier",CHRONICLE_TIERS.get(kind,"notice"))),"kind":String(CHRONICLE_KINDS.get(kind,"court")),
		"action":{"kind":"court","focus":focus},"ledger":false,"domain":"institutions" if kind in ["death","succession","callback"] else "court"})

static func chronicle(limit:int=40,kind:String="")->Array[Dictionary]:
	var out:Array[Dictionary]=[]
	for entry in state().chronicle:
		if entry is Dictionary and (kind=="" or String(entry.get("kind",""))==kind): out.append(entry)
		if out.size()>=limit: break
	return out

static func remembered(limit:int=REMEMBERED_MAX)->Array[Dictionary]:
	var out:Array[Dictionary]=[]
	for entry in state().remembered:
		if entry is Dictionary: out.append(entry)
		if out.size()>=limit: break
	return out

# --------------------------------------------------------------------------
# Daily
# --------------------------------------------------------------------------

static func daily(day:int)->void:
	if WorldSimulation.actor_id!="player": return
	var l:=state()
	_ensure_kin()
	_watch_deaths(day)
	_watch_successions(day)
	_orders_due(day)
	_watch_omens(day)
	_rivals(day)
	_prune_rites(day)
	_assign_portraits()
	l.watch_day=day

# --------------------------------------------------------------------------
# Kin
# --------------------------------------------------------------------------

static func _age(person:Dictionary)->float:
	return float(_day()-int(person.get("born_day",_day())))/365.0

static func _primary_skill(person:Dictionary)->String:
	var skills:Dictionary=person.get("skills",{}) if person.get("skills") is Dictionary else {}
	var best:=""
	for skill in skills:
		if best=="" or int(skills[skill])>int(skills[best]): best=String(skill)
	return best

static func _link(a:Dictionary,b:Dictionary,rel_a:String,rel_b:String)->void:
	var ka:Array=a.get("kin",[]); var kb:Array=b.get("kin",[])
	ka.append({"pid":int(b.person_id),"rel":rel_a}); kb.append({"pid":int(a.person_id),"rel":rel_b})
	a["kin"]=ka; b["kin"]=kb

static func _ensure_kin()->void:
	## Each member of the cast is placed in a family once: some are children
	## of older members, some siblings, some apprentices of a master in the same
	## craft. Links are additive fields on GovernmentPeopleSystem's records.
	var people:Array=GovernmentPeopleSystem.people
	for person_variant in people:
		var person:Dictionary=person_variant
		if person.has("kin"): continue
		person["kin"]=[]
		if String(person.get("status","active"))!="active": continue
		var rng:=_rng("kin:%d" % int(person.get("person_id",0)))
		var roll:=rng.randf()
		var age:=_age(person)
		var best:Dictionary={}
		var best_score:=-1.0
		for other_variant in people:
			var other:Dictionary=other_variant
			if int(other.get("person_id",0))==int(person.get("person_id",0)) or not other.has("kin"): continue
			if (other.get("kin",[]) as Array).size()>=KIN_MAX: continue
			var gap:=_age(other)-age
			var score:=-1.0
			if roll<0.30 and gap>=17.0 and gap<=40.0: score=1.0-absf(gap-26.0)/30.0
			elif roll>=0.30 and roll<0.46 and absf(gap)<=9.0: score=1.0-absf(gap)/10.0
			elif roll>=0.46 and roll<0.62 and gap>=8.0 and _primary_skill(other)==_primary_skill(person): score=0.8
			if score>best_score: best_score=score; best=other
		if best.is_empty() or best_score<0.0: continue
		if roll<0.30: _link(person,best,"parent","child")
		elif roll<0.46: _link(person,best,"sibling","sibling")
		else: _link(person,best,"master","apprentice")

static func kin_of(pid:int)->Array[Dictionary]:
	## [{pid,rel,name,status}]: rel is what that person is to pid.
	var out:Array[Dictionary]=[]
	var record:=_record(pid)
	for link in record.get("kin",[]):
		if not link is Dictionary: continue
		var other:=_record(int(link.get("pid",0)))
		if other.is_empty(): continue
		out.append({"pid":int(link.pid),"rel":String(link.get("rel","")),"name":String(other.get("name","")),"status":String(other.get("status",""))})
	return out

static func _record(pid:int)->Dictionary:
	for person in GovernmentPeopleSystem.people:
		if int((person as Dictionary).get("person_id",0))==pid: return person
	return {}

const REL_WORDS:={"parent":"parent","child":"child","sibling":"sibling","master":"teacher","apprentice":"apprentice"}

static func kin_words(of_pid:int,to_pid:int)->String:
	## "Iska's child" style: what of_pid is to to_pid, or "".
	for link in _record(of_pid).get("kin",[]):
		if link is Dictionary and int(link.get("pid",0))==to_pid:
			# link.rel is what to_pid is to of_pid; invert it.
			var rel:=String(link.get("rel",""))
			var mine:=String({"parent":"child","child":"parent","sibling":"sibling","master":"apprentice","apprentice":"teacher"}.get(rel,""))
			return mine
	return ""

# --------------------------------------------------------------------------
# Deaths and the Remembered
# --------------------------------------------------------------------------

static func _years_words(months:int)->String:
	var years:=int(months/12.0)
	if years<=0: return "a season"
	var word:String=["one","two","three","four","five","six","seven","eight","nine","ten","eleven","twelve"][years-1] as String if years<=12 else str(years)
	return "%s winter%s" % [word,"" if years==1 else "s"]

static func _deed(person:Dictionary)->String:
	## Why they mattered: an order of the god's they carried, else an act of the
	## god upon them, else what they were good at.
	var pid:=int(person.get("person_id",0))
	for order in state().orders:
		if order is Dictionary and int(order.get("pid",0))==pid and String(order.get("topic","")).length()>0:
			return "carried out your word for %s" % String(order.topic)
	for event in DIVINE.events(6,pid):
		if int(event.get("person_id",0))==pid:
			match String(event.get("action","")):
				"raise_up": return "was raised up by your own hand before us all"
				"bless": return "stood in your blessing"
	var skill:=_primary_skill(person)
	var options:Array=Lines.DEEDS.get(skill,["served us"])
	return _pick(options,"deed:%d" % pid)

static func _watch_deaths(day:int)->void:
	var l:=state()
	var since:=int(l.watch_day)
	var known:Dictionary={}
	for entry in l.remembered:
		if entry is Dictionary: known[String(entry.get("key",""))]=true
	for person_variant in GovernmentPeopleSystem.people:
		var person:Dictionary=person_variant
		if String(person.get("status",""))!="deceased": continue
		var died:=int(person.get("died_day",-1))
		if died<since: continue
		var key:="person:%d" % int(person.get("person_id",0))
		if known.has(key): continue
		var office_key:=String(person.get("died_office_key",person.get("office_key","")))
		var local:=String(person.get("died_local_leader_of",person.get("local_leader_of","")))
		if office_key=="" and local=="" and String(person.get("removal_reason",""))!="executed": _on_notable_death(person,day)
		else: _on_official_death(person,day)
	if is_instance_valid(HistoricalFigures):
		for figure in HistoricalFigures.people:
			if not figure is Dictionary or String(figure.get("status",""))!="dead": continue
			var died_on:=int(figure.get("death_day",-1))
			if died_on<since or known.has("figure:"+String(figure.get("id",""))): continue
			_on_figure_death(figure)

## Days after a death before the people say aloud who keeps the fire, when
## the god has not yet named anyone.
const SUCCESSION_DAYS:=30

static func _watch_successions(day:int)->void:
	## A death in office is followed by a succession the people see: if the god
	## has named no one within a month, the one keeping the fire is named, with
	## what they are to the dead. The god may still choose another at court.
	for entry_variant in state().remembered:
		var entry:Dictionary=entry_variant
		if bool(entry.get("told_successor",false)) or String(entry.get("successor",""))!="" or int(entry.get("pid",0))<=0: continue
		if String(entry.get("title",""))=="of the hearth" or String(entry.get("cause",""))!="old age": continue
		var died:=int(entry.get("died",entry.get("day",day)))
		if day-died<SUCCESSION_DAYS: continue
		entry["told_successor"]=true
		if day-died>SUCCESSION_DAYS+30: continue
		var dead:=_record(int(entry.pid))
		if dead.is_empty(): continue
		var office:=_office_of(dead)
		var acting:=_acting(office)
		if acting.is_empty(): continue
		var given:=EraNames.given_of(String(entry.get("name","")))
		var kin:=kin_words(int(acting.get("person_id",0)),int(entry.pid))
		var who:="%s%s" % [String(acting.get("name","")),(", %s," % kin) if kin!="" else ""]
		var age:=GovernmentPeopleSystem.age_years(acting)
		record("succession","%s Keeps the Fire" % EraNames.given_of(String(acting.get("name",""))).substr(0,40),
			"A month after %s's burning, %s keeps the fire as %s. %s is %d and has %s. The god has named no one; the people take this as the god's leave." % [given,who,String(office.title).to_lower(),EraNames.given_of(String(acting.get("name",""))),age,_own_words(acting)],
			{"pid":int(acting.get("person_id",0))},{"key":"court:succession:kept:%d" % int(entry.pid),"tier":"moment","focus":{"person_id":int(acting.get("person_id",0))}})

static func _office_of(person:Dictionary)->Dictionary:
	## {key, settlement_id, title}: the post a dead person held.
	var office_key:=String(person.get("died_office_key",person.get("office_key","")))
	var local:=String(person.get("died_local_leader_of",person.get("local_leader_of","")))
	var title:=String(person.get("died_office_title",person.get("office_title","")))
	if office_key=="" and local!="":
		office_key="settlement"
		if title=="": title=GovernmentPeopleSystem.settlement_leader_title()
		for settlement in GameState.player_settlements:
			if String(settlement.get("id",""))==local and String(settlement.get("name",""))!="": title+=" of "+String(settlement.name)
	if title=="" and office_key!="": title=String(GovernmentPeopleSystem.office_definition(office_key).get("title",office_key))
	if title=="": title="one of your officials"
	return {"key":office_key,"settlement_id":local,"title":title}

static func _on_official_death(person:Dictionary,day:int)->void:
	var pid:=int(person.get("person_id",0))
	var office:=_office_of(person)
	var executed:=String(person.get("removal_reason",""))=="executed"
	var age:=GovernmentPeopleSystem.age_years(person)
	var deed:=_deed(person)
	var kin:Array[String]=[]
	for link in kin_of(pid):
		if String(link.status)=="active": kin.append("%s (%s)" % [String(link.name),String(REL_WORDS.get(String(link.rel),"kin"))])
	var entry:={"key":"person:%d" % pid,"pid":pid,"day":day,"name":String(person.get("name","")),"title":String(office.title),"age":age,
		"born":int(person.get("born_day",0)),"died":int(person.get("died_day",day)),"deed":deed,"served":_years_words(int(person.get("experience_months",0))),
		"cause":"struck down by your word" if executed else "old age","kin":", ".join(PackedStringArray(kin)).substr(0,160),"successor":""}
	var list:Array=state().remembered
	list.push_front(entry)
	while list.size()>REMEMBERED_MAX: list.pop_back()
	var given:=EraNames.given_of(String(person.get("name","")))
	_replace_hr_notice(String(person.get("name","")))
	# The mourning is filed first so the Chronicle's card can open it.
	# Summoning the one who holds the mourning opens it (AudienceHall.summon).
	var holder_pid:=0 if executed else _file_mourning(person,office,day)
	var months:=int(person.get("experience_months",0))
	var tenure:=(" after %s in office" % _years_words(months)) if months>=12 else ""
	var said:="%s, %s, died aged %d%s. They %s. The court gathers at the fire to mourn them." % [String(person.get("name","")),String(office.title),age,tenure,deed]
	var told:={"key":"court:death:person:%d" % pid,"focus":{"person_id":holder_pid} if holder_pid>0 else {}}
	if holder_pid>0: told["text"]=said+" Summon the court to name who follows."
	record("death","%s Is Dead" % String(person.get("name","")).substr(0,60),said,{"pid":pid},told)
	_mark_rite("pyre","for "+given,day,5,pid)

static func _replace_hr_notice(name:String)->void:
	## The court's own words replace the government's one-line notice.
	var events:Array=GameState.simulation_events
	for index in range(events.size()-1,-1,-1):
		var event:Variant=events[index]
		if event is Dictionary and String(event.get("title",""))=="Officeholder Died" and String(event.get("description","")).begins_with(name): events.remove_at(index)

static func _on_notable_death(person:Dictionary,day:int)->void:
	## One of the realm's notables (the bounded public cast) held no office: no
	## succession, but the court remembers them and their kin grieve.
	var pid:=int(person.get("person_id",0))
	var age:=GovernmentPeopleSystem.age_years(person)
	var deed:=_deed(person)
	var mourners:Array[String]=[]
	for link in kin_of(pid):
		if String(link.status)=="active": mourners.append("%s, their %s" % [String(link.name),String(REL_WORDS.get(String(link.rel),"kin"))])
	var entry:={"key":"person:%d" % pid,"pid":pid,"day":day,"name":String(person.get("name","")),"title":"of the hearth","age":age,
		"born":int(person.get("born_day",0)),"died":int(person.get("died_day",day)),"deed":deed,"served":"","cause":"old age","kin":"; ".join(PackedStringArray(mourners)).substr(0,160),"successor":""}
	var list:Array=state().remembered
	list.push_front(entry)
	while list.size()>REMEMBERED_MAX: list.pop_back()
	_replace_hr_notice(String(person.get("name","")))
	var grief:=(" %s, keeps vigil." % mourners[0]) if not mourners.is_empty() else ""
	record("death","%s Is Dead" % String(person.get("name","")).substr(0,60),"%s died aged %d. They %s.%s" % [String(person.get("name","")),age,deed,grief],{"pid":pid,"notable":true},{"key":"court:death:person:%d" % pid,"tier":"notice"})

static func _on_figure_death(figure:Dictionary)->void:
	var role:=String(figure.get("role",""))
	var title:="War leader" if role=="General" else ("Master builder" if role=="Architect" else role.capitalize())
	var deed:="led our spears" if role=="General" else ("raised what will outlast us" if role=="Architect" else "served the realm")
	var entry:={"key":"figure:"+String(figure.get("id","")),"pid":0,"day":_day(),"name":String(figure.get("name","")),"title":title,
		"age":int((int(figure.get("death_day",_day()))-int(figure.get("born",_day())))/365.0),"born":int(figure.get("born",0)),"died":int(figure.get("death_day",_day())),
		"deed":deed,"served":"","cause":String(figure.get("death_cause","")).substr(0,60),"kin":"","successor":""}
	var list:Array=state().remembered
	list.push_front(entry)
	while list.size()>REMEMBERED_MAX: list.pop_back()
	record("death","%s Is Dead" % String(figure.get("name","")).substr(0,60),"%s, %s, is dead. They %s." % [String(figure.get("name","")),title.to_lower(),deed],{},{"key":"court:death:figure:"+String(figure.get("id","")),"tier":"notice"})

static func _acting(office:Dictionary)->Dictionary:
	if String(office.key)=="settlement": return GovernmentPeopleSystem.settlement_leader(String(office.settlement_id))
	return GovernmentPeopleSystem.officeholder(String(office.key))

static func _candidates(dead:Dictionary,office:Dictionary)->Array[Dictionary]:
	## The acting successor, then kin of the dead, then the best fit; two or three.
	var out:Array[Dictionary]=[]
	var seen:Dictionary={int(dead.get("person_id",0)):true}
	var acting:=_acting(office)
	if not acting.is_empty():
		out.append(acting); seen[int(acting.person_id)]=true
	var query_key:="SettlementLeader" if String(office.key)=="settlement" else String(office.key)
	var pool:=GovernmentPeopleSystem.candidates_for_office(query_key,String(office.settlement_id) if String(office.key)=="settlement" else "",24,true)
	var free:Array[Dictionary]=[]
	for candidate in pool:
		var cid:=int(candidate.get("person_id",0))
		if seen.has(cid) or String(candidate.get("status","active"))!="active": continue
		# Someone already holding another central office stays where they are.
		if String(candidate.get("office_key",""))!="": continue
		free.append(candidate)
	var dead_pid:=int(dead.get("person_id",0))
	for candidate in free:
		if out.size()>=3: break
		if kin_words(int(candidate.person_id),dead_pid)!="": out.append(candidate); seen[int(candidate.person_id)]=true
	for candidate in free:
		if out.size()>=3: break
		if not seen.has(int(candidate.person_id)): out.append(candidate); seen[int(candidate.person_id)]=true
	return out

static func _bind_voice()->void:
	## The same lifelong voice registry the hall's voice uses (saved with it).
	var st:=Hall.state()
	if not st.get("voice") is Dictionary: st["voice"]={}
	var v:Dictionary=st.voice
	for key in ["models","addresses","said","counts"]:
		if not v.get(key) is Dictionary: v[key]={}
	if not v.has("serial"): v["serial"]=0
	CV.registry=v

static func _manner(person:Dictionary)->String:
	_bind_voice()
	return String(CV.for_person(person).get("model",""))

static func _bank(model:String,key:String)->Array:
	var bank:Array=(Lines.BANKS.get(model,{}) as Dictionary).get(key,[])
	return bank if not bank.is_empty() else (Lines.GENERIC.get(key,[]) as Array)

static func _fill(template:String,tokens:Dictionary)->String:
	var out:=template
	for key in tokens: out=out.replace("{"+String(key)+"}",String(tokens[key]))
	out=out.strip_edges()
	# Every sentence starts with a capital, wherever a token landed.
	for i in range(out.length()):
		if i==0 or (i>=2 and out[i-1]==" " and out[i-2] in ".!?"):
			out=out.substr(0,i)+out[i].to_upper()+out.substr(i+1)
	return out

static func _era_ok(text:String)->bool:
	return CV.permits(text,CV.era_tags("player"))

static func _say(model:String,key:String,tokens:Dictionary,salt:String)->String:
	## One line in this manner, the first era-safe choice from a salted start.
	var bank:=_bank(model,key)
	if bank.is_empty(): return ""
	var start:=posmod(hash("%d|%s" % [int(GameState.world_seed),salt]),bank.size())
	for offset in bank.size():
		var text:=_fill(String(bank[(start+offset)%bank.size()]),tokens)
		if _era_ok(text) and not text.contains("{"): return text
	var generic:Array=Lines.GENERIC.get(key,[])
	for template in generic:
		var fallback:=_fill(String(template),tokens)
		if _era_ok(fallback) and not fallback.contains("{"): return fallback
	return ""

static func _own_words(person:Dictionary)->String:
	return _pick(Lines.OWN.get(_primary_skill(person),["served where I was put"]),"own:%d" % int(person.get("person_id",0)))

static func _holder_for(office:Dictionary,candidates:Array[Dictionary],dead_pid:int)->Dictionary:
	## Who brings the mourning to the god: a senior official who is not a
	## candidate, else the one now acting.
	var taken:Dictionary={dead_pid:true}
	for c in candidates: taken[int(c.get("person_id",0))]=true
	var officials:=Hall._officials()
	for official in officials:
		if not taken.has(int(official.get("person_id",0))): return official
	for official in officials:
		if int(official.get("person_id",0))!=dead_pid: return official
	return {}

static func _file_mourning(dead:Dictionary,office:Dictionary,day:int)->int:
	## Returns the person_id of the one who holds the mourning, or 0 when no
	## mourning could be held.
	var candidates:=_candidates(dead,office)
	if candidates.is_empty(): return 0
	var holder:=_holder_for(office,candidates,int(dead.get("person_id",0)))
	if holder.is_empty(): return 0
	var dead_pid:=int(dead.get("person_id",0))
	var given:=EraNames.given_of(String(dead.get("name","")))
	var acting:=_acting(office)
	var rows:Array=[]
	for candidate in candidates:
		var cid:=int(candidate.get("person_id",0))
		rows.append({"pid":cid,"name":String(candidate.get("name","")).substr(0,60),"kin":kin_words(cid,dead_pid),"acting":not acting.is_empty() and cid==int(acting.get("person_id",0)),
			"age":GovernmentPeopleSystem.age_years(candidate),"own":_own_words(candidate)})
	var names:PackedStringArray=PackedStringArray()
	for row in rows: names.append(String(row.name))
	var audience:=Hall._new_audience("court","petition",day)
	audience.speaker={"name":String(holder.get("name","")).substr(0,100),"title":String(holder.get("office_title","Official")).substr(0,100),"person_id":int(holder.person_id),"role":"official"}
	var summary:="%s, %s, is dead. %s speaks for the hearth until you choose: %s." % [String(dead.get("name","")),String(office.title),String(acting.get("name","No one")) if not acting.is_empty() else "No one",", ".join(names)]
	audience.petition={"topic":"mourning","summary":summary.substr(0,400),"suggested_decree":""}
	audience.situation={"type":"mourning","ask":"mourning:%d" % dead_pid,"headline":"comes from the burial","summary":summary.substr(0,400),
		"occasion":{"type":"mourning","text":"the death of %s" % given,"day":day,"crisis":true},
		"mourning":{"dead_pid":dead_pid,"dead":String(dead.get("name","")).substr(0,60),"given":given,"office_key":String(office.key),"settlement_id":String(office.settlement_id),
			"title":String(office.title).substr(0,60),"deed":_deed(dead).substr(0,120),"served":_years_words(int(dead.get("experience_months",0))),"candidates":rows}}
	Hall._file_matter(audience,[])
	return int(holder.person_id)

static func on_open(audience:Dictionary)->void:
	## A lives matter was taken up: stage it in the court's own voices.
	var situation:Dictionary=audience.get("situation",{}) if audience.get("situation") is Dictionary else {}
	match String(situation.get("type","")):
		"mourning": _stage_mourning(audience,situation)
		"callback","omen": _stage_simple(audience,situation)

static func _line(audience:Dictionary,person:Dictionary,text:String,aside:bool=false)->void:
	if text.strip_edges()=="": return
	Hall.append_line(String(audience.id),{"speaker":String(person.get("name","")),"role":"official","person_id":int(person.get("person_id",0)),"civ_id":"player","text":text,"day":_day(),"aside":aside})

static func _narrate(audience:Dictionary,text:String)->void:
	Hall.append_line(String(audience.id),{"speaker":"","role":"narrator","person_id":0,"civ_id":"","text":text,"day":_day(),"aside":false})

static func _stage_mourning(audience:Dictionary,situation:Dictionary)->void:
	var m:Dictionary=situation.get("mourning",{})
	var id:=String(audience.id)
	var speaker:Dictionary=audience.get("speaker",{})
	var holder:=GovernmentPeopleSystem.person_snapshot(int(speaker.get("person_id",0)))
	if holder.is_empty(): holder={"person_id":int(speaker.get("person_id",0)),"name":String(speaker.get("name",""))}
	var tokens:={"dead":String(m.get("given","")),"office":String(m.get("title","")),"deed":String(m.get("deed","served us")),"years":String(m.get("served","a season"))}
	_narrate(audience,"[The fire circle is quiet. %s's place is empty; someone has laid a stone where they sat.]" % String(m.get("given","")))
	_line(audience,holder,_say(_manner(holder),"mourn",tokens,"mourn:%s:holder" % id))
	var bench:=Hall.court(id)
	var spoke:=0
	for member in bench:
		if spoke>=2: break
		var said:=_say(_manner(member),"mourn",tokens,"mourn:%s:%d" % [id,int(member.get("person_id",0))])
		if said=="" : continue
		_line(audience,member,said,spoke==1)
		spoke+=1
	var candidates:Array=m.get("candidates",[])
	if candidates.is_empty(): return
	var who:PackedStringArray=PackedStringArray()
	for row_variant in candidates: who.append(String((row_variant as Dictionary).get("name","")))
	var joined:=" and ".join(who) if who.size()<=2 else "%s and %s" % [", ".join(who.slice(0,who.size()-1)),who[who.size()-1]]
	_narrate(audience,"[%s come forward to be seen by the god.]" % joined)
	for row_variant in candidates:
		var row:Dictionary=row_variant
		var person:=GovernmentPeopleSystem.person_snapshot(int(row.get("pid",0)))
		if person.is_empty(): continue
		var own:=String(row.get("own","served where I was put"))
		var pitch:=_say(_manner(person),"pitch",{"own":own,"dead":String(m.get("given",""))},"pitch:%s:%d" % [id,int(row.pid)])
		var kin:=String(row.get("kin",""))
		if kin!="": pitch="I was %s's %s. %s" % [String(m.get("given","")),kin,pitch]
		if bool(row.get("acting",false)): pitch="I have kept the fire since %s fell. %s" % [String(m.get("given","")),pitch]
		_line(audience,person,pitch)

static func _stage_simple(audience:Dictionary,situation:Dictionary)->void:
	var speaker:Dictionary=audience.get("speaker",{})
	var person:=GovernmentPeopleSystem.person_snapshot(int(speaker.get("person_id",0)))
	if person.is_empty(): person={"person_id":int(speaker.get("person_id",0)),"name":String(speaker.get("name",""))}
	var spoken:String=String(situation.get("spoken",""))
	if spoken=="": spoken=String(situation.get("summary",""))
	_line(audience,person,spoken)
	var aside:=String(situation.get("aside",""))
	var bench:=Hall.court(String(audience.id))
	if aside!="" and not bench.is_empty(): _line(audience,bench[0],aside,true)

# --------------------------------------------------------------------------
# Options and resolution (called from AudienceHall for TOPICS)
# --------------------------------------------------------------------------

static func options(audience:Dictionary)->Array[Dictionary]:
	var out:Array[Dictionary]=[]
	var situation:Dictionary=audience.get("situation",{}) if audience.get("situation") is Dictionary else {}
	match String(situation.get("type","")):
		"mourning":
			var m:Dictionary=situation.get("mourning",{})
			var title:=String(m.get("title","the office"))
			for row_variant in m.get("candidates",[]):
				var row:Dictionary=row_variant
				var person:=GovernmentPeopleSystem.person_snapshot(int(row.get("pid",0)))
				var alive:=not person.is_empty() and String(person.get("status",""))=="active"
				var kin:=String(row.get("kin",""))
				var sub:="%s, aged %d.%s %s" % [String(row.get("name","")),int(row.get("age",0))," %s's %s." % [String(m.get("given","")),kin] if kin!="" else "",("Already keeps the fire." if bool(row.get("acting",false)) else "Has %s." % String(row.get("own","")))]
				var label:=("Confirm %s" if bool(row.get("acting",false)) else "Choose %s") % EraNames.given_of(String(row.get("name","")))
				out.append(Hall._option("choose:%d" % int(row.get("pid",0)),label,sub.strip_edges(),"warm",alive,"%s is no longer among the living cast." % String(row.get("name",""))))
			out.append(Hall._option("mourn_only","Choose later","Honour %s; the one acting as %s stays for now." % [String(m.get("given","")),title.to_lower()],"neutral"))
		"omen":
			out.append(Hall._option("claim_sign","It was my doing","Claim the sign. Their awe and their dread both grow.","hostile"))
			out.append(Hall._option("humble_sign","The sky answers no one","Refuse the credit. Love grows; dread eases.","warm"))
			out.append(Hall._option("let_talk","Say nothing","Let the people tell it as they like.","neutral"))
		"callback":
			out.append(Hall._option("praise_work","Praise their work","Words of favour for the one who carried it.","warm"))
			out.append(Hall._option("note_it","It is noted","Hear it and move on.","neutral"))
			out.append(Hall._option("blame_work","It should have gone better","Lay the fault on them.","hostile"))
	return out

static func resolve(audience:Dictionary,option_id:String)->Dictionary:
	var situation:Dictionary=audience.get("situation",{}) if audience.get("situation") is Dictionary else {}
	match String(situation.get("type","")):
		"mourning": return _resolve_mourning(audience,situation,option_id)
		"omen": return _resolve_omen(audience,situation,option_id)
		"callback": return _resolve_callback(audience,option_id)
	return {"outcome":"The matter is set down.","reaction":"neutral"}

static func _resolve_mourning(audience:Dictionary,situation:Dictionary,option_id:String)->Dictionary:
	var m:Dictionary=situation.get("mourning",{})
	var given:=String(m.get("given",""))
	var office:={"key":String(m.get("office_key","")),"settlement_id":String(m.get("settlement_id","")),"title":String(m.get("title",""))}
	var candidates:Array=m.get("candidates",[])
	if option_id=="mourn_only":
		var acting:=_acting(office)
		for row_variant in candidates:
			var row:Dictionary=row_variant
			GovernmentPeopleSystem.record_person_memory(int(row.get("pid",0)),"We mourned %s before the god, who named no one yet." % given,"mourning",0.5,{"emotion":"grief"})
		_set_successor(int(m.get("dead_pid",0)),String(acting.get("name","")))
		return {"outcome":"The court mourned %s. %s keeps the fire for now." % [given,String(acting.get("name","No one")) if not acting.is_empty() else "No one"],"reaction":"neutral"}
	if not option_id.begins_with("choose:"): return {"error":"That answer is not open to you here."}
	var chosen_pid:=int(option_id.trim_prefix("choose:"))
	var chosen:=GovernmentPeopleSystem.person_snapshot(chosen_pid)
	if chosen.is_empty() or String(chosen.get("status",""))!="active": return {"error":"%s can no longer take it." % String(chosen.get("name","That person"))}
	var before:=_acting(office)
	var appointed:=true
	if int(before.get("person_id",0))!=chosen_pid:
		# GovernmentPeopleSystem makes every appointment.
		if String(office.key)=="settlement":
			appointed=bool(GovernmentPeopleSystem.assign_settlement_leader(String(office.settlement_id),chosen_pid).get("ok",false))
		else:
			appointed=not GovernmentPeopleSystem.mark_central_appointment(chosen_pid,String(office.key)).is_empty()
	if not appointed: return {"error":"%s cannot take that office now." % String(chosen.get("name",""))}
	GovernmentPeopleSystem.adjust_person_bonds(chosen_pid,{"trust":0.08,"love":0.06,"obligation":0.06})
	GovernmentPeopleSystem.record_person_memory(chosen_pid,"The god chose me before the fire to follow %s." % given,"mourning",0.9,{"emotion":"pride"})
	var chosen_given:=EraNames.given_of(String(chosen.get("name","")))
	var chosen_model:=_manner(chosen)
	var acceptance:=_say(chosen_model,"quote",{"order":"Keep the fire","order_low":"keep the fire","order_cap":"Keep the fire"},"accept:%s" % String(audience.id))
	_line(audience,chosen,"%s I will keep it as %s did." % [acceptance,given])
	var passed:PackedStringArray=PackedStringArray()
	for row_variant in candidates:
		var row:Dictionary=row_variant
		var pid:=int(row.get("pid",0))
		if pid==chosen_pid: continue
		var person:=GovernmentPeopleSystem.person_snapshot(pid)
		if person.is_empty(): continue
		var pride:=float(person.get("pride",0.5))
		var resent:=0.03+pride*0.08+(0.06 if bool(row.get("acting",false)) else 0.0)
		GovernmentPeopleSystem.adjust_person_bonds(pid,{"resentment":resent,"trust":-0.02})
		GovernmentPeopleSystem.record_person_memory(pid,"The god passed me over for %s after %s died." % [chosen_given,given],"mourning",0.7 if bool(row.get("acting",false)) else 0.5,{"emotion":"slighted"})
		passed.append(EraNames.given_of(String(person.get("name",""))))
	_set_successor(int(m.get("dead_pid",0)),String(chosen.get("name","")))
	var passed_text:=(" %s will remember being passed over." % " and ".join(passed)) if not passed.is_empty() else ""
	record("succession","The God Chose %s" % chosen_given,"Before the fire, the god chose %s to follow %s as %s.%s" % [String(chosen.get("name","")),given,String(office.title).to_lower(),passed_text],{"pid":chosen_pid},{"key":"court:succession:%d" % int(m.get("dead_pid",0)),"focus":{"person_id":chosen_pid}})
	return {"outcome":"You chose %s to follow %s as %s.%s" % [String(chosen.get("name","")),given,String(office.title).to_lower(),passed_text],"reaction":"delighted"}

static func _set_successor(dead_pid:int,name:String)->void:
	for entry in state().remembered:
		if entry is Dictionary and int(entry.get("pid",0))==dead_pid and dead_pid>0: entry["successor"]=name.substr(0,60)

static func typed_choice(audience_id:String,text:String)->String:
	## Online, the god may simply say who: "Let Iska keep the fire." Returns
	## the option id their words name, or "".
	var audience:=Hall.find(audience_id)
	var situation:Dictionary=audience.get("situation",{}) if audience.get("situation") is Dictionary else {}
	if String(situation.get("type",""))!="mourning" or String(audience.get("status",""))!="waiting": return ""
	var lower:=" "+text.to_lower().replace(","," ").replace("."," ").replace("!"," ").replace("?"," ")+" "
	if lower.contains(" later ") or lower.contains(" not yet ") or lower.contains(" wait "): return "mourn_only"
	var found:=""
	for row_variant in (situation.get("mourning",{}) as Dictionary).get("candidates",[]):
		var row:Dictionary=row_variant
		var given:=EraNames.given_of(String(row.get("name",""))).to_lower()
		if given.length()>=2 and lower.contains(" %s " % given):
			if found!="": return ""   # two names: not a choice
			found="choose:%d" % int(row.get("pid",0))
	return found

static func _resolve_omen(audience:Dictionary,situation:Dictionary,option_id:String)->Dictionary:
	var officials:=Hall._officials()
	var metrics:Dictionary=GameState.simulation_metrics
	match option_id:
		"claim_sign":
			for person in officials: GovernmentPeopleSystem.adjust_person_bonds(int(person.person_id),{"fear":0.05,"love":0.02,"hold_days":45})
			metrics["legitimacy"]=clampf(float(metrics.get("legitimacy",0.5))+0.01,0.01,0.99)
			return {"outcome":"You claimed the sign. The court looks at you as at the sky itself.","reaction":"pleased"}
		"humble_sign":
			for person in officials: GovernmentPeopleSystem.adjust_person_bonds(int(person.person_id),{"fear":-0.03,"love":0.04})
			return {"outcome":"You told them the sky answers no one. They loved you for it, and feared you a little less.","reaction":"delighted"}
		"let_talk":
			return {"outcome":"You said nothing. The story grows at every fire.","reaction":"neutral"}
	return {"error":"That answer is not open to you here."}

static func _resolve_callback(audience:Dictionary,option_id:String)->Dictionary:
	var pid:=int((audience.get("speaker",{}) as Dictionary).get("person_id",0))
	var name:=String((audience.get("speaker",{}) as Dictionary).get("name",""))
	match option_id:
		"praise_work":
			GovernmentPeopleSystem.adjust_person_bonds(pid,{"trust":0.05,"love":0.03})
			GovernmentPeopleSystem.record_person_memory(pid,"The god praised how I carried out an old order.","callback",0.5,{"emotion":"pride"})
			return {"outcome":"You praised %s for the work. They stood a little taller." % name,"reaction":"delighted"}
		"note_it":
			return {"outcome":"You heard %s out." % name,"reaction":"neutral"}
		"blame_work":
			GovernmentPeopleSystem.adjust_person_bonds(pid,{"resentment":0.05,"fear":0.04,"trust":-0.03})
			GovernmentPeopleSystem.record_person_memory(pid,"The god blamed me for how an old order turned out.","callback",0.6,{"emotion":"slighted"})
			return {"outcome":"You laid the fault on %s. They will remember it." % name,"reaction":"offended"}
	return {"error":"That answer is not open to you here."}

# --------------------------------------------------------------------------
# Orders: rites on the map, and what came of them
# --------------------------------------------------------------------------

const RITE_BY_NATURE:={"feast":["bonfire",4],"worship":["procession",5],"monument":["stone",10],"human_sacrifice":["pyre",6],"miracle":["bonfire",7],
	"rename":["cairn",4],"custom_art":["cairn",4],"punishment":["procession",3],"exile":["procession",3],"mercy":["bonfire",3],"hunt_beast":["bonfire",3],
	"marriage":["bonfire",4],"teaching":["cairn",3],"defense_works":["cairn",6],"relocation":["procession",4],"welcome":["bonfire",3],"raid":["procession",3],"fasting":["procession",4]}

static func note_order(text:String,policies:Array,leader:Dictionary,order_id:String)->void:
	## An order the god gave was carried out (AdvisorSystem). Mark it on the
	## map, schedule the court's callback, and watch the sky if it was asked.
	if WorldSimulation.actor_id!="player" or text.strip_edges()=="": return
	var natures:Array[String]=[]
	var catalog:Array[String]=[]
	for policy_variant in policies:
		var policy:Dictionary=policy_variant
		if not bool(policy.get("applied",false)): continue
		var plan:Dictionary=(policy.get("directive_parameters",{}) as Dictionary).get("custom_plan",{}) if policy.get("directive_parameters") is Dictionary else {}
		for nature in plan.get("natures",[]):
			if not natures.has(String(nature)): natures.append(String(nature))
		if String(policy.get("id",""))!="custom_directive": catalog.append(String(policy.get("id","")))
	if natures.is_empty() and catalog.is_empty(): return
	var day:=_day()
	var pid:=int(leader.get("person_id",0))
	var first:=natures[0] if not natures.is_empty() else ""
	var since:=String(Lines.SINCE_BY_NATURE.get(first,""))
	if since=="":
		var gist:=text.strip_edges().trim_suffix(".").trim_suffix("!")
		since="you said “%s”" % gist.substr(0,70)
	var delay:=CALLBACK_MIN+posmod(hash("%d|callback|%s|%d" % [int(GameState.world_seed),order_id,day]),CALLBACK_MAX-CALLBACK_MIN+1)
	var orders:Array=state().orders
	var topic:=String(preload("res://scripts/divine_reply.gd").topic(policies,text))
	orders.push_front({"id":order_id.substr(0,40),"day":day,"due":day+delay,"pid":pid,"text":text.substr(0,140),"natures":natures.slice(0,3),"since":since.substr(0,90),"topic":topic.substr(0,60),"base":_snapshot(),"done":false})
	while orders.size()>ORDERS_MAX: orders.pop_back()
	var rite:Array=RITE_BY_NATURE.get(first,["cairn",3])
	_mark_rite(String(rite[0]),since,day,int(rite[1]),pid)
	var wish:=_wish_of(text)
	if wish!="" or natures.has("miracle"): _watch_sky(wish if wish!="" else "any",text,day,pid)

static func _snapshot()->Dictionary:
	var metrics:Dictionary=GameState.simulation_metrics
	return {"cohesion":float(metrics.get("cohesion",0.5)),"legitimacy":float(metrics.get("legitimacy",0.5)),"health":float(GameState.population_health),
		"security":float(metrics.get("security",0.5)),"knowledge":float(metrics.get("knowledge",0.0)),"food":float(GameState.resource_stockpiles.get("Food",0.0)),
		"population":float(GameState.population_total),"births":int(GameState.lifetime_births),"deaths":int(GameState.lifetime_deaths)}

static func _change_line(base:Dictionary)->String:
	## The largest real change since the order, in plain words.
	var now:=_snapshot()
	var best:=""; var best_size:=0.0
	var scales:={"cohesion":0.02,"legitimacy":0.02,"health":0.02,"security":0.03,"knowledge":0.03}
	for key:String in scales:
		var delta:=float(now.get(key,0.0))-float(base.get(key,0.0))
		var size:=absf(delta)/float(scales[key])
		if size>best_size: best_size=size; best=String((Lines.CHANGE_WORDS[key] as Array)[0 if delta>0.0 else 1])
	var food_before:=maxf(1.0,float(base.get("food",0.0)))
	var food_delta:=(float(now.food)-float(base.get("food",0.0)))/food_before
	if absf(food_delta)/0.2>best_size: best_size=absf(food_delta)/0.2; best=String((Lines.CHANGE_WORDS.food as Array)[0 if food_delta>0.0 else 1])
	var births:=int(now.births)-int(base.get("births",0))
	var deaths:=int(now.deaths)-int(base.get("deaths",0))
	var tail:=""
	if births>0 and deaths>0: tail=" %d children were born and we buried %d." % [births,deaths]
	elif births>0: tail=" %d children were born." % births
	elif deaths>0: tail=" We buried %d." % deaths
	if best=="" or best_size<0.5: best="little has changed that anyone can see"
	return best+"."+tail

static func _orders_due(day:int)->void:
	for order_variant in state().orders:
		var order:Dictionary=order_variant
		if bool(order.get("done",false)) or int(order.get("due",0))>day: continue
		order["done"]=true
		_file_callback(order,day)

static func _file_callback(order:Dictionary,day:int)->void:
	var officials:=Hall._officials()
	if officials.is_empty(): return
	var person:Dictionary={}
	for official in officials:
		if int(official.get("person_id",0))==int(order.get("pid",0)): person=official
	var carried:=not person.is_empty()
	if person.is_empty(): person=officials[0]
	var change:=_change_line(order.get("base",{}))
	var since:=String(order.get("since","your order"))
	var spoken:=_say(_manner(person),"callback",{"since":since,"change":change},"callback:%s" % String(order.get("id","")))
	if not carried:
		spoken="%s is gone, so I will tell it. %s" % [String(_record(int(order.get("pid",0))).get("name","The one who carried it")),spoken]
	var audience:=Hall._new_audience("court","petition",day)
	audience.speaker={"name":String(person.get("name","")).substr(0,100),"title":String(person.get("office_title","Official")).substr(0,100),"person_id":int(person.person_id),"role":"official"}
	var summary:="Since %s: %s" % [since,change]
	audience.petition={"topic":"callback","summary":summary.substr(0,400),"suggested_decree":""}
	audience.situation={"type":"callback","ask":"callback:%s" % String(order.get("id","")).substr(0,40),"headline":"brings word of an old order","summary":summary.substr(0,400),"spoken":spoken.substr(0,400),
		"occasion":{"type":"callback","text":"what came of %s" % since,"day":day,"crisis":false}}
	Hall._file_matter(audience,[])
	record("callback","An Old Order Remembered","%s has word for you of what came of it: %s" % [String(person.get("name","")),spoken],{"pid":int(person.person_id)},{"key":"court:callback:"+String(order.get("id","")).substr(0,40),"focus":{"person_id":int(person.person_id)}})

# --------------------------------------------------------------------------
# Omens: when the sky happens to agree
# --------------------------------------------------------------------------

static func _wish_of(text:String)->String:
	var lower:=" "+text.to_lower()+" "
	for wish:String in ["dry","winter","healing","harvest","rain"]:
		for term in (Lines.WISHES[wish] as Dictionary).terms:
			if lower.contains(String(term)): return wish
	if lower.contains("the dead") or lower.contains("back to life"): return "dead"
	return ""

static func _weather(day:int)->float:
	if not is_instance_valid(FoodSystem) or not FoodSystem.has_method("_weather_yield_factor") or not FoodSystem.has_method("_environment_mix"): return 1.0
	return float(FoodSystem.call("_weather_yield_factor",FoodSystem.call("_environment_mix"),float(day)))

static func _season(day:int)->float:
	if not is_instance_valid(FoodSystem) or not FoodSystem.has_method("_environment_mix") or not is_instance_valid(PlanetEnvironment): return 0.0
	return float(PlanetEnvironment.season_wave(FoodSystem.call("_environment_mix"),float(day)))

static func _watch_sky(wish:String,text:String,day:int,pid:int)->void:
	var window:=20 if wish=="rain" else 30
	var omens:Array=state().omens
	omens.push_front({"day":day,"until":day+window,"wish":wish,"text":text.substr(0,100),"pid":pid,"weather":_weather(day),"season":_season(day),"health":float(GameState.population_health),"food_days":float(GameState.simulation_metrics.get("food_days",30.0)),"state":"watching"})
	while omens.size()>OMENS_MAX: omens.pop_back()

static func sky_agrees(omen:Dictionary,day:int)->bool:
	## True when the real simulation happens to give what was asked. Nothing
	## here changes the weather, the season or anyone's health.
	match String(omen.get("wish","")):
		"rain": return _weather(day)-float(omen.get("weather",1.0))>=0.010
		"dry","harvest": return _weather(day)>=maxf(1.025,float(omen.get("weather",1.0))+0.012)
		"winter":
			var then:=float(omen.get("season",0.0)); var now:=_season(day)
			return then<0.0 and (now>=0.0 or now-then>=0.18)
		"healing": return float(GameState.population_health)-float(omen.get("health",0.0))>=0.012
	return false

static func _watch_omens(day:int)->void:
	for omen_variant in state().omens:
		var omen:Dictionary=omen_variant
		if String(omen.get("state",""))!="watching": continue
		if day>int(omen.get("until",day)):
			omen["state"]="silent"
			_silence(omen,day)
			continue
		if day<=int(omen.get("day",day)): continue
		if not sky_agrees(omen,day): continue
		omen["state"]="agreed"
		omen["agreed_day"]=day
		_omen(omen,day)

## When the sky does not agree, the rite is remembered as a failure.
const SILENCE_WORDS:={"rain":"The drummers have gone home hoarse, and the hides are dry.","dry":"The smoke-fires are out and the rain still falls.",
	"winter":"The cold held to its own time.","harvest":"The baskets came home no heavier than before.","healing":"The sick are no better for the singing.",
	"dead":"The mound is as it was.","any":"Nothing came of it."}

static func _silence(omen:Dictionary,day:int)->void:
	## A rite that nothing answered: a little doubt, and the one who led it
	## remembers. Belief rises only on coincidence (_omen), never by decree.
	var wish:=String(omen.get("wish","any"))
	var metrics:Dictionary=GameState.simulation_metrics
	metrics["legitimacy"]=clampf(float(metrics.get("legitimacy",0.5))-0.01,0.01,0.99)
	var pid:=int(omen.get("pid",0))
	if pid>0: GovernmentPeopleSystem.record_person_memory(pid,"I led the rite the god asked for, and nothing came of it.","omen",0.5,{"emotion":"doubt"})
	var wish_words:=String((Lines.WISHES.get(wish,{}) as Dictionary).get("wish","what was asked")) if Lines.WISHES.has(wish) else "what was asked"
	preload("res://scripts/chronicle.gd").record({"key":"court:silent:%d:%s" % [int(omen.get("day",day)),wish],"title":"The Sky Kept Silent",
		"text":"The god called for %s, and nothing came. %s Some at the fires have stopped looking up." % [wish_words,String(SILENCE_WORDS.get(wish,SILENCE_WORDS.any))],
		"tier":"notice","kind":"omen","domain":"court","ledger":false})

static func _omen(omen:Dictionary,day:int)->void:
	var wish:=String(omen.get("wish","rain"))
	var spec:Dictionary=Lines.WISHES.get(wish,Lines.WISHES.rain)
	var sign:=_pick(spec.get("sign",["the sky answered"]),"sign:%d" % day)
	var officials:=Hall._officials()
	# Awe: both love and dread leap, and the people talk.
	for person in officials: GovernmentPeopleSystem.adjust_person_bonds(int(person.person_id),{"love":0.05,"fear":0.05,"hold_days":30})
	var metrics:Dictionary=GameState.simulation_metrics
	metrics["legitimacy"]=clampf(float(metrics.get("legitimacy",0.5))+0.03,0.01,0.99)
	metrics["cohesion"]=clampf(float(metrics.get("cohesion",0.5))+0.015,0.01,0.99)
	for civ in CivilizationSystem.civilizations:
		if civ is Dictionary and int((civ.get("player_relation",{}) as Dictionary).get("contact_level",0))>0: DIVINE.add_civ_dread(String(civ.get("id","")),0.04)
	var person:Dictionary={}
	for official in officials:
		if int(official.get("person_id",0))==int(omen.get("pid",0)): person=official
	if person.is_empty() and not officials.is_empty(): person=officials[0]
	var days:=day-int(omen.get("day",day))
	var wish_words:=String(spec.get("wish","a sign"))
	var spoken:=_say(_manner(person),"omen",{"wish":wish_words,"sign":sign},"omen:%d:%s" % [day,wish]) if not person.is_empty() else ""
	record("omen","The Sky Answered","%s after the god demanded %s, %s. The people swear it was the god's doing." % [("%d days" % days) if days!=1 else "A day",wish_words,sign],{"wish":wish},
		{"key":"court:omen:%d:%s" % [day,wish],"focus":{"person_id":int(person.person_id)} if not person.is_empty() else {}})
	_mark_rite("bonfire","thanks for "+wish_words,day,4,int(person.get("person_id",0)))
	if person.is_empty(): return
	var audience:=Hall._new_audience("court","petition",day)
	audience.speaker={"name":String(person.get("name","")).substr(0,100),"title":String(person.get("office_title","Official")).substr(0,100),"person_id":int(person.person_id),"role":"official"}
	var summary:="You demanded %s; %d days later %s. The people are talking." % [wish_words,days,sign]
	var bench_aside:=_pick(["They are saying at the fires that nothing is beyond you now.","Even the children are daring each other to ask you for things.","The doubters have gone very quiet."],"aside:%d" % day)
	audience.petition={"topic":"omen","summary":summary.substr(0,400),"suggested_decree":""}
	audience.situation={"type":"omen","ask":"omen:%d" % day,"headline":"comes about the sign","summary":summary.substr(0,400),"spoken":spoken.substr(0,400),"aside":bench_aside,
		"occasion":{"type":"omen","text":"the sign in the sky","day":day,"crisis":false}}
	Hall._file_matter(audience,[])

# --------------------------------------------------------------------------
# Rites on the map
# --------------------------------------------------------------------------

static func _mark_rite(kind:String,label:String,day:int,days:int,pid:int=0)->void:
	var rites:Array=state().rites
	rites.push_front({"day":day,"until":day+clampi(days,3,10),"kind":kind,"label":label.substr(0,80),"pid":pid,"slot":posmod(hash("%d|%s|%d" % [int(GameState.world_seed),label,day]),8)})
	while rites.size()>RITES_MAX: rites.pop_back()
	if kind!="pyre": record("rite","A Rite at the Camp","%s: %s." % [String(Lines.RITE_WORDS.get(kind,"a rite")).capitalize(),label])

static func _prune_rites(day:int)->void:
	var rites:Array=state().rites
	for rite in rites.duplicate():
		if rite is Dictionary and int(rite.get("until",0))<day-30: rites.erase(rite)

static func active_rites(day:int=-1)->Array[Dictionary]:
	## At most RITES_VISIBLE rites burning on the map today, newest first.
	var today:=_day() if day<0 else day
	var out:Array[Dictionary]=[]
	for rite in state().rites:
		if rite is Dictionary and int(rite.get("day",0))<=today and int(rite.get("until",0))>=today: out.append(rite)
		if out.size()>=RITES_VISIBLE: break
	return out

# --------------------------------------------------------------------------
# Rivals and the god's dread
# --------------------------------------------------------------------------

static func rival_dread(civ_id:String)->float:
	## How much a foreign people dreads the god: their own memory of its wrath,
	## and what travellers say of how it treats its own.
	var people:=float(DIVINE.people_regard(Hall._officials()).get("dread",0.0))
	return clampf(DIVINE.civ_dread(civ_id)+people*0.35,0.0,1.0)

static func rival_stance(civ_id:String)->String:
	## "tribute", "avoid" or "provoke": how this people answers dread.
	var p:=Hall._personality(civ_id)
	var civ:=ForeignDiplomacy.civilization(civ_id)
	if p.is_empty() or civ.is_empty(): return "avoid"
	var size_ratio:=clampf(float(civ.get("population",100))/maxf(1.0,Hall._player_population()),0.2,3.0)
	if (float(p.get("assertiveness",0.5))+float(p.get("risk_tolerance",0.5)))*0.5>0.6 and size_ratio>=0.9: return "provoke"
	if float(p.get("empathy",0.5))>0.55 or float(p.get("discipline",0.5))>0.62 or size_ratio<0.8: return "tribute"
	return "avoid"

static func dread_weight(situation_type:String,civ_id:String)->float:
	## Multiplier on how likely each kind of envoy business is, by dread.
	var d:=rival_dread(civ_id)
	if d<0.2: return 1.0
	match rival_stance(civ_id):
		"tribute":
			if situation_type in ["gift_goods","nonaggression_offer","dread_tribute"]: return 1.0+d*2.0
			if situation_type in ["tribute_demand","emboldened_demand","test_of_resolve"]: return maxf(0.1,1.0-d*0.9)
		"provoke":
			if situation_type in ["test_of_resolve","tribute_demand"]: return 1.0+d*2.2
			if situation_type in ["gift_goods","nonaggression_offer"]: return maxf(0.2,1.0-d*0.6)
		"avoid":
			if situation_type in ["tribute_demand","emboldened_demand","test_of_resolve","artifact_return"]: return maxf(0.1,1.0-d)
	return 1.0

static func avoids(civ_id:String,occasion:Dictionary,rng:RandomNumberGenerator)->bool:
	## A people that fears the god and keeps its distance sends fewer envoys.
	if bool(occasion.get("crisis",false)) or String(occasion.get("type","")) in ["dread_tribute","dread_test","first_contact"]: return false
	if rival_stance(civ_id)!="avoid": return false
	return rng.randf()<rival_dread(civ_id)*0.6

static func _rivals(day:int)->void:
	if day%10!=0: return
	var rivals:Dictionary=state().rivals
	for civ in CivilizationSystem.civilizations:
		if not civ is Dictionary or not bool(civ.get("alive",true)): continue
		var relation:Dictionary=civ.get("player_relation",{}) if civ.get("player_relation") is Dictionary else {}
		if int(relation.get("contact_level",0))<1 or bool(relation.get("at_war",false)): continue
		var civ_id:=String(civ.get("id",""))
		if day-int(rivals.get(civ_id,-99999))<RIVAL_GAP: continue
		var d:=rival_dread(civ_id)
		if d<0.35: continue
		var name:=String(civ.get("name",civ_id))
		rivals[civ_id]=day
		match rival_stance(civ_id):
			"tribute":
				Hall._add_occasion({"key":"dread_tribute:%s:%d" % [civ_id,day],"type":"dread_tribute","civ_id":civ_id,"day":day,"not_before":day,"expires":day+90,"crisis":true,"data":{"text":"they fear your wrath"}})
				record("rival","%s Send Tribute" % name.substr(0,40),"Word of the god's wrath reached %s. Their envoys are on the road with tribute." % name,{"civ_id":civ_id},{"focus":{"civ_id":civ_id}})
			"provoke":
				Hall._add_occasion({"key":"dread_test:%s:%d" % [civ_id,day],"type":"dread_test","civ_id":civ_id,"day":day,"not_before":day,"expires":day+90,"crisis":true,"data":{"text":"they mean to test whether the god's wrath is real"}})
				record("rival","%s Test You" % name.substr(0,40),"%s have heard what is said of the god and mean to see if it is true." % name,{"civ_id":civ_id},{"focus":{"civ_id":civ_id}})
			_:
				ForeignDiplomacy.remember(civ_id,"We keep our hunters off the far ridge. The god of that people is not to be crossed.")
				var index:=Hall._civ_index(civ_id)
				if index>=0:
					var rel:Dictionary=CivilizationSystem.civilizations[index].get("player_relation",{})
					rel["border_tension"]=clampf(float(rel.get("border_tension",0.0))-0.04*d,0.0,1.0)
				record("rival","%s Keep Away" % name.substr(0,40),"%s keep their hunters off the ridge since word of the god's wrath reached them." % name,{"civ_id":civ_id},{"focus":{"civ_id":civ_id}})

# --------------------------------------------------------------------------
# Portraits: one picture per living court member
# --------------------------------------------------------------------------

static func _portrait_key(person:Dictionary)->String:
	var pid:=int(person.get("person_id",0)) if _num(person.get("person_id",0)) else 0
	if pid>0: return "person:%d" % pid
	var name:=String(person.get("name",""))
	return "name:"+name if name!="" else ""

static func portrait_slot(person:Dictionary)->Array:
	## [index, mirrored] for a court member, or [] to use the ordinary picture.
	if person.is_empty() or String(person.get("appearance_civ_id",person.get("civilization_id","player")))!="player": return []
	if not is_instance_valid(ForeignDiplomacy) or not ForeignDiplomacy.audiences is Dictionary: return []
	var lives:Variant=ForeignDiplomacy.audiences.get(KEY,{})
	if not lives is Dictionary: return []
	var slots:Variant=(lives as Dictionary).get("portraits",{})
	if not slots is Dictionary: return []
	var slot:Variant=(slots as Dictionary).get(_portrait_key(person),[])
	return slot if slot is Array and (slot as Array).size()>=2 else []

static func court_faces()->Array[Dictionary]:
	## Everyone whose face the court shows now: officials, the realm's war
	## leaders and master builders, and those waiting to be chosen.
	var out:Array[Dictionary]=[]
	for official in Hall._officials(): out.append(official)
	if is_instance_valid(HistoricalFigures):
		for figure in HistoricalFigures.people:
			if figure is Dictionary and String(figure.get("status",""))!="dead" and String(figure.get("role","")) in ["General","Architect"]:
				out.append({"name":String(figure.get("name","")),"person_id":0})
	for m in Hall.matters():
		var situation:Dictionary=((m.get("audience",{}) as Dictionary).get("situation",{})) if m.get("audience") is Dictionary else {}
		for row in (situation.get("mourning",{}) as Dictionary).get("candidates",[]):
			if row is Dictionary: out.append(GovernmentPeopleSystem.person_snapshot(int(row.get("pid",0))))
	# Each person once, however many ways they are at court.
	var unique:Array[Dictionary]=[]
	var seen:Dictionary={}
	for face in out:
		var key:=_portrait_key(face)
		if key=="" or seen.has(key): continue
		seen[key]=true
		unique.append(face)
	return unique

static func _assign_portraits()->void:
	var PortraitScript:GDScript=load("res://scripts/hud/person_portrait.gd")
	var slots:Dictionary=state().portraits
	var faces:=court_faces()
	var taken:Dictionary={}
	var present:Dictionary={}
	for face in faces:
		if face.is_empty(): continue
		var key:=_portrait_key(face)
		if key=="" or present.has(key): continue
		present[key]=true
		var count:=int(PortraitScript.call("cells_for",face))
		var saved:Variant=slots.get(key,[])
		var pair:=""
		if saved is Array and (saved as Array).size()>=2:
			pair="%d:%d" % [posmod(int(saved[0]),count),1 if bool(saved[1]) else 0]
			if taken.has(pair): pair=""
		if pair=="":
			var natural:=posmod(int(PortraitScript.call("natural_index",face)),count)
			var order:Array=[]
			for mirror in [0,1]:
				order.append("%d:%d" % [natural,mirror])
				for offset in range(1,count): order.append("%d:%d" % [posmod(natural+offset,count),mirror])
			for option in order:
				if not taken.has(String(option)): pair=String(option); break
			if pair=="": pair="%d:1" % natural
		taken[pair]=true
		slots[key]=[int(pair.get_slice(":",0)),pair.get_slice(":",1)=="1",_day()]
	# Keep the saved map bounded: faces no longer at court go first, oldest first.
	if slots.size()>PORTRAITS_MAX:
		var gone:Array=slots.keys().filter(func(k:Variant)->bool:return not present.has(String(k)))
		gone.sort_custom(func(a:Variant,b:Variant)->bool:return int((slots[a] as Array)[2] if (slots[a] as Array).size()>2 else 0)<int((slots[b] as Array)[2] if (slots[b] as Array).size()>2 else 0))
		for k in gone:
			if slots.size()<=PORTRAITS_MAX: break
			slots.erase(k)
