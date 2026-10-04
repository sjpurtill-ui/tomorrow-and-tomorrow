extends RefCounted
## THE CHRONICLE — one feed that holds the story of the people.
##
## Every report the player is told is graded:
##   whisper  a routine line (seasonal tally, drill, quiet news). Kept, never pushed.
##   notice   worth reading (a death in office, scouts with news, a discovery).
##   moment   worth feeling: an illustrated card with a sound sting. Capped at
##            MOMENTS_PER_WINDOW per MOMENT_WINDOW_DAYS; extra moments are kept
##            as notices. A moment never pauses the world.
##
## PUBLIC API (other systems call these; all are static and safe to call from
## any scope — rival simulations are ignored):
##   Chronicle.record(moment:Dictionary)->Dictionary
##       Required: "title". Optional: "text" (one or two sentences, era-voiced),
##       "tier" ("moment"|"notice"|"whisper"; omitted -> graded), "kind" (card
##       mark: founding, birth, death, discovery, contact, settlement, ceremony,
##       milestone, scout, omen, war, court, work, hearth_count), "key" (dedupe:
##       a key is recorded once), "day" (defaults to today), "art"
##       ({"discovery_id":id} | {"domain":dynamic} | {"building":index}),
##       "action" ({"kind":"ceremony","work_id":id} | {"kind":"court","focus":{}}
##       | {"kind":"section","section":id,"sub":n} | {"kind":"scout_report",
##       "mission_id":n}), "ledger" (default true: a
##       notice or moment also appears in the event ledger), "domain".
##       Returns the stored entry (its "tier" says what it became), or {}.
##       "priority" (true: a moment that the monthly cap never downgrades,
##       for first contact and the first winter).
##       Folding (the Chronicle's diet): a notice whose family was told within
##       FOLD_WINDOW_DAYS, to the same people or place (the same card action),
##       folds into that card instead of becoming a new one. The card counts
##       it and shows its words as the latest line; the repeat is kept as a
##       tally line, in the event ledger and in its own year's telling.
##       "fold_as" (a group key; default the title's family), "fold_days"
##       (that group's window) and "fold" (false: never folded) shape it.
##       Moments, firsts, priority lines, warnings and anything waiting on the
##       god (see foldable) never fold.
##   Chronicle.record_first(key:String, moment:Dictionary)->Dictionary
##       Records only the first time `key` is seen for this people.
##   Chronicle.record_beat(beat:Dictionary)->Dictionary
##       Tells an Opening Arc beat (opening_arc.gd). A beat that is the same
##       event as an entry already told (the first birth, the first winter,
##       the first sign of strangers, a first contact, a first discovery, a
##       headcount) enriches that entry instead of adding a second one.
##   Chronicle.entries(min_tier:String="whisper", limit:int=0)->Array
##   Chronicle.latest_headline()->String   newest moment/notice, era-voiced
##   Chronicle.voice()->Dictionary          era wording (tally-marks / annals)
##
## The feed lives in GameState.chronicle, so it saves with the world. Older
## saves start an empty feed, seeded so known fields are not "first" again.

const VERSION:=1
const TIERS:=["whisper","notice","moment"]
const MOMENT_WINDOW_DAYS:=30
const MOMENTS_PER_WINDOW:=3
const ENTRY_LIMIT:=900
const WHISPER_LIMIT:=160
const CONDITION_QUIET_DAYS:=60
## A notice of a family told within this many days (of the family's latest
## telling) folds into the card that told it.
const FOLD_WINDOW_DAYS:=1095
## A card gathers repeats for at most this long; the next one is told afresh.
const FOLD_SPAN_DAYS:=3650
## A season's repeat discoveries each get a line in the event ledger only up
## to this many; past it the season's tally tells the rest as one line, so a
## rush of learning (a foundation found late opening a whole tree) reads as
## "This season the people learned 25 new ways" and never floods the ledger.
const LEARNED_LEDGER_LINES:=3
## Names a long list shows before "and N more".
const LIST_NAMES:=4
## How far back fresh() looks for a queued card's stored entry.
const FRESH_LOOK:=400
## Never folded, by kind, key or the action the card offers: deaths, births,
## foundings, the year's entries, warnings (they ask the god to act), crises,
## the story's firsts and turnings, aims taken up, kept or failed, wars and
## feuds begun, turned or ended, a price named for peace, raids and battles
## (each keeps its own report), ceremonies waiting.
const FOLD_NEVER_KINDS:=["death","birth","founding","annal","warning"]
const FOLD_NEVER_KEYS:=["annal:","age:","crisis:","first:","beat:","discovery:","milestone:","learned:","turning:","court:death","court:succession",
	"aim:start:","aim:done:","aim:fail:","aim:release:","ceremony:","war:feud:","war:declared:","war:terms:","war:war_to_feud:","war:peace:",
	"war:raid:","war:battle:","court_war:","town_fate:","aftermath:","battle"]
## Era-defining practices stay moments even when their field is not new.
const RESEARCH_MILESTONES:=["seed_selection","public_schools","printing_process","steam_propulsion","powered_flight","reactor_engineering"]
## Headcounts the people have never reached before are remembered once.
const PEOPLE_MILESTONES:=[150,200,300,500,1000,2000,5000,10000,20000,50000,100000,250000,500000,1000000]
const Annals:=preload("res://scripts/chronicle_annals.gd")
const Polish:=preload("res://scripts/chronicle_polish.gd")
const DOMAIN_NAMES:={"demography":"people & homes","nutrition":"food & farming","health":"health & care","labor":"work & tools","knowledge":"learning & records","production":"craft & making","infrastructure":"water & building","logistics":"travel & carrying","ecology":"land & seasons","institutions":"custom & law","security":"watch & war","culture":"song & custom","wealth":"exchange & wealth"}

## Moment cards waiting to be shown; hud/chronicle_card.gd drains this.
static var pending_cards:Array[Dictionary]=[]
static var _voice_cache:Dictionary={}
static var _voice_signature:=-1


static func active()->bool:
	## Only the player's people keep a chronicle; rival simulations do not.
	return Engine.get_main_loop()!=null and WorldSimulation.state==GameState


static func data()->Dictionary:
	var c:Dictionary=GameState.chronicle
	if int(c.get("version",0))<VERSION:_seed(c)
	return c


static func _seed(c:Dictionary)->void:
	if not c.get("entries") is Array:c["entries"]=[]
	if not c.get("firsts") is Dictionary:c["firsts"]={}
	if not c.get("keys") is Dictionary:c["keys"]={}
	if not c.get("moment_days") is Array:c["moment_days"]=[]
	if not c.get("moment_ids") is Dictionary:c["moment_ids"]={}
	c["scan_day"]=int(c.get("scan_day",int(GameState.elapsed_days)))
	# A world that already knows things (an older save) does not re-announce
	# its fields as "first"; a new world has an empty log.
	var firsts:Dictionary=c.firsts
	for logged in GameState.discovery_log:
		if not logged is Dictionary:continue
		var dynamic:=_dynamic_of(String((logged as Dictionary).get("id","")))
		if dynamic!="" and not firsts.has("domain:"+dynamic):firsts["domain:"+dynamic]=String((logged as Dictionary).get("id",""))
	if GameState.settlement_founded_day>=0 and GameState.elapsed_days-float(GameState.settlement_founded_day)>1.0:
		firsts["founding"]=GameState.settlement_founded_day
		if GameState.elapsed_days-float(GameState.settlement_founded_day)>120.0:
			for key in ["first_birth","first_burial","first_winter"]:firsts[key]=GameState.settlement_founded_day
	for threshold in PEOPLE_MILESTONES:
		if GameState.population_total>=int(threshold):firsts["people:%d" % int(threshold)]=int(GameState.elapsed_days)
	c["version"]=VERSION


# --- Recording ----------------------------------------------------------------

static func record(moment:Dictionary)->Dictionary:
	if not active():return {}
	var title:=String(moment.get("title","")).strip_edges()
	if title.is_empty():return {}
	var c:=data()
	var day:=int(moment.get("day",int(GameState.elapsed_days)))
	var key:=String(moment.get("key",""))
	if key.is_empty():key="%d|%s" % [day,title]
	var keys:Dictionary=c.keys
	if keys.has(key):return {}
	var tier:=String(moment.get("tier",""))
	if tier not in TIERS:tier=grade(moment)
	var wanted:=tier
	# Routine lines step back into the tallies; the rest gain their callbacks
	# (chronicle_annals.gd).
	var shaped:=Annals.shape(c,moment,tier)
	tier=String(shaped.tier);title=String(shaped.title)
	var downgraded:=false
	if tier=="moment" and not bool(moment.get("priority",false)) and not _moment_room(c,day):
		tier="notice";downgraded=true
	var entry:Dictionary={"key":key,"day":day,"tier":tier,"kind":String(moment.get("kind","story")),"title":plain(title),"text":plain(String(shaped.text).strip_edges())}
	if downgraded:entry["crowded"]=true
	if String(shaped.family)!="":entry["family"]=String(shaped.family)
	if bool(shaped.folded):entry["folded"]=true
	if shaped.has("same_as"):entry["same_as"]=String(shaped.same_as)
	var group:=String(moment.get("fold_as",shaped.family)).strip_edges()
	if group!="" and group!=String(shaped.family):entry["fold_as"]=group
	# A notice already told lately, to the same people or place, folds into
	# its card (FOLD_WINDOW_DAYS); one the year's telling already stepped back
	# is still counted on that card.
	var head:Dictionary={}
	var repeat:=false
	if wanted=="notice" and tier in ["notice","whisper"] and not shaped.has("same_as") and foldable(moment,key):
		head=_fold_head(c,group,String(shaped.family),action_sign(moment.get("action",{})),day,int(moment.get("fold_days",FOLD_WINDOW_DAYS)))
		if not head.is_empty():
			repeat=tier=="notice"
			tier="whisper";entry.tier="whisper";entry["folded"]=true;entry["same_as"]=String(head.key)
			# Still news for its own year's telling (chronicle_annals.gd note).
			if repeat:entry["repeat"]=true
	# The story's own telling replaces a plainer report of the same finding.
	for older in shaped.get("demote",[]):_demote(c,String(older),key)
	for optional in ["art","action","domain","source","first","learned"]:
		if moment.has(optional):entry[optional]=moment[optional].duplicate(true) if moment[optional] is Dictionary or moment[optional] is Array else moment[optional]
	(c.entries as Array).push_front(entry)
	keys[key]=day
	if not head.is_empty():_fold_into(head,entry)
	if tier=="moment":
		var days:Array=c.moment_days
		days.push_front(day)
		if days.size()>12:days.resize(12)
		pending_cards.append(entry.duplicate(true))
		if pending_cards.size()>6:pending_cards.pop_front()
	# A folded repeat keeps its line in the event ledger.
	if (tier!="whisper" or repeat) and bool(moment.get("ledger",true)):_to_ledger(entry)
	Annals.note(c,entry)
	_trim(c)
	return entry


# --- Folding repeats -----------------------------------------------------------

## Whether a record request may fold into an earlier card of its family:
## only a plain notice that asks nothing of the god. Never a moment (nor one
## the monthly cap lowered), a first or priority line, a warning, and never
## anything that waits on the god: a death, a crisis, a war begun or a raid or
## battle, a ceremony, a court summons (a card that opens the court on a
## person), an aim taken up, kept or failed. A card that opens anything but
## the court folds only when its source asks for it by "fold_as", and then
## only to open a page of the dock, never a report or a battle.
static func foldable(moment:Dictionary,key:String="")->bool:
	if key.is_empty():key=String(moment.get("key",""))
	if moment.has("fold") and not bool(moment.fold):return false
	if bool(moment.get("priority",false)) or bool(moment.get("first",false)) or bool(moment.get("crowded",false)):return false
	if String(moment.get("tier",""))=="moment":return false
	if String(moment.get("kind","")) in FOLD_NEVER_KINDS:return false
	for prefix in FOLD_NEVER_KEYS:
		if key.begins_with(prefix):return false
	return plain_action(moment.get("action",{}),String(moment.get("fold_as",""))!="")


## A card's action that a fold may keep: none, or the court opened on a
## people (or on nobody). With `asked` (the source's own "fold_as"), also a
## page of the dock. Never a person summoned, a report, a battle to watch or
## a ceremony to attend.
static func plain_action(action:Variant,asked:bool=false)->bool:
	if not action is Dictionary or (action as Dictionary).is_empty():return true
	var a:Dictionary=action
	if a.has("battle_seed") or a.has("seed"):return false
	match String(a.get("kind","")):
		"court":
			var focus:Variant=a.get("focus",{})
			if not focus is Dictionary:return false
			for field in (focus as Dictionary):
				if String(field)!="civ_id":return false
			return true
		"section":return asked
	return false


## What a card opens, as words: two lines fold together only when they open
## the same thing (the same people, the same page).
static func action_sign(action:Variant)->String:
	if not action is Dictionary or (action as Dictionary).is_empty():return ""
	return JSON.stringify(action)


## The group a told entry folds by: its "fold_as", else its family.
static func fold_group(entry:Dictionary)->String:
	if String(entry.get("fold_as",""))!="":return String(entry.fold_as)
	if String(entry.get("family",""))!="":return String(entry.family)
	return Annals._family(String(entry.get("title","")))


## The newest card of `group` that opens the same thing (`sign`) and still
## gathers repeats on `day`: told (or last folded into) within `window`
## days, and first told within FOLD_SPAN_DAYS (or `window`, when longer). {}
## when the next one is news again. A card an older save kept before groups
## were named is matched by its `family`.
static func _fold_head(c:Dictionary,group:String,family:String,sign:String,day:int,window:int)->Dictionary:
	if group.is_empty():return {}
	for e in c.entries:
		if not e is Dictionary:continue
		var entry:Dictionary=e
		if String(entry.get("tier",""))=="whisper":continue
		var same:=fold_group(entry)==group or (family!="" and not entry.has("fold_as") and String(entry.get("family",""))==family)
		if not same or action_sign(entry.get("action",{}))!=sign:continue
		# A card that itself waits on the god is never rewritten.
		if not foldable({"kind":entry.get("kind",""),"action":entry.get("action",{}),"fold_as":entry.get("fold_as","")},String(entry.get("key",""))):return {}
		var first_day:=int(entry.get("day",day))
		if day-int(entry.get("last_day",first_day))>window:return {}
		if day-first_day>maxi(FOLD_SPAN_DAYS,window):return {}
		return entry
	return {}


## Counts a repeat on its card: how many times now, and the latest words,
## after the card's own. The card keeps its own action: a repeat folds only
## into a card that opens the same thing. A card still waiting to be shown
## shows the count too (fresh(), used by hud/chronicle_card.gd).
static func _fold_into(head:Dictionary,entry:Dictionary)->void:
	if not head.has("told"):
		head["told"]=1
		head["base_text"]=String(head.get("text",""))
	head["told"]=int(head.told)+1
	head["last_day"]=int(entry.get("day",0))
	head["last_key"]=String(entry.get("key",""))
	head["last_text"]=String(entry.get("text",""))
	if String(entry.get("title",""))!=String(head.get("title","")):head["last_title"]=String(entry.get("title",""))
	else:head.erase("last_title")
	head["text"]=fold_text(head)
	for card in pending_cards:
		if String(card.get("key",""))==String(head.get("key","")):card.merge(head,true)


## A card as the Chronicle now holds it: a card queued for showing may have
## gathered repeats since (its count and latest line). `card` itself when
## the Chronicle no longer keeps it.
static func fresh(card:Dictionary)->Dictionary:
	if not active() or String(card.get("key",""))=="":return card
	var key:=String(card.key)
	var looked:=0
	for e in data().entries:
		looked+=1
		if looked>FRESH_LOOK:break
		if e is Dictionary and String((e as Dictionary).get("key",""))==key:return (e as Dictionary).duplicate(true)
	return card


## A card's words with its repeats: "... Told twelve times since Year 218;
## the latest, Year 229 · Summer: A cairn of stones: for the dead of the Dry
## Year of year 229."
static func fold_text(head:Dictionary)->String:
	var base:=String(head.get("base_text",head.get("text","")))
	var told:=int(head.get("told",1))
	if told<2:return base
	var latest:=String(head.get("last_text",""))
	if latest.is_empty():latest=String(head.get("last_title",head.get("title","")))
	var line:="Told %s since Year %d; the latest, %s: %s" % [Annals._times(told),int(head.get("day",0))/365+1,date_label(int(head.get("last_day",head.get("day",0)))),latest]
	if not line.ends_with(".") and not line.ends_with("!") and not line.ends_with("?"):line+="."
	return (base+" "+line).strip_edges() if base!="" else line


## Whether these words were told before by an entry whose key begins with
## `key_prefix`, within `within_days` of `day` (-1: at any time kept).
static func told_before(text:String,key_prefix:String="",within_days:int=-1,day:int=-1)->bool:
	if not active() or text.strip_edges().is_empty():return false
	if day<0:day=int(GameState.elapsed_days)
	var said:=Annals._family(plain(text.strip_edges()))
	for e in data().entries:
		if not e is Dictionary:continue
		var entry:Dictionary=e
		if within_days>=0 and day-int(entry.get("day",day))>within_days:continue
		if key_prefix!="" and not String(entry.get("key","")).begins_with(key_prefix):continue
		if Annals._family(String(entry.get("base_text",entry.get("text",""))))==said:return true
	return false


## Whether a stored Chronicle has the shape this file reads. Older saves,
## without the fold fields ("told", "last_day", "last_text", "base_text",
## "fold_as"), are valid as they are.
static func valid_state(c:Variant)->bool:
	if not c is Dictionary:return false
	var d:Dictionary=c
	for field in ["entries","moment_days"]:
		if d.has(field) and not d[field] is Array:return false
	for field in ["firsts","keys","moment_ids"]:
		if d.has(field) and not d[field] is Dictionary:return false
	for e in d.get("entries",[]):
		if not e is Dictionary:return false
		var entry:Dictionary=e
		if not entry.get("key") is String or not entry.get("title") is String:return false
		if not (entry.get("day") is int or entry.get("day") is float):return false
		if String(entry.get("tier","")) not in TIERS:return false
		for field in ["told","last_day"]:
			if entry.has(field) and not (entry[field] is int or entry[field] is float):return false
		for field in ["text","family","fold_as","base_text","last_text","last_key","last_title","same_as"]:
			if entry.has(field) and not entry[field] is String:return false
		if entry.has("action") and not entry.action is Dictionary:return false
	return true


## Mends a saved Chronicle in place rather than losing it: an entry that
## does not read as one is dropped (only that entry), and a container of the
## wrong kind starts afresh (only that field). Returns how many were mended.
static func repair(c:Dictionary)->int:
	var mended:=0
	for field in ["entries","moment_days"]:
		if c.has(field) and not c[field] is Array: c[field]=[]; mended+=1
	for field in ["firsts","keys","moment_ids"]:
		if c.has(field) and not c[field] is Dictionary: c[field]={}; mended+=1
	if c.get("entries") is Array:
		var kept:Array=[]
		for e in c.entries:
			if valid_state({"entries":[e]}): kept.append(e)
			else: mended+=1
		c["entries"]=kept
	return mended

static func _demote(c:Dictionary,older_key:String,by_key:String)->void:
	for e in c.entries:
		if String((e as Dictionary).get("key",""))!=older_key:continue
		if String(e.get("tier",""))=="whisper":return
		e["tier"]="whisper";e["folded"]=true;e["same_as"]=by_key
		for i in range(pending_cards.size()-1,-1,-1):
			if String((pending_cards[i] as Dictionary).get("key",""))==older_key:pending_cards.remove_at(i)
		return


## The people's own words: a cart, saddle or gun they cannot name yet is told
## as the nearest thing they know (character_voice.gd ERA_STANDINS), and an
## ore by what it looks like until they know its metal (resource_names.gd).
static func plain(text:String)->String:
	if text.is_empty():return text
	return preload("res://scripts/resource_names.gd").plain(preload("res://scripts/character_voice.gd").era_plain_for(text,"player"))


static func record_first(first_key:String,moment:Dictionary)->Dictionary:
	if not active() or first_key.is_empty():return {}
	var firsts:Dictionary=data().firsts
	if firsts.has(first_key):return {}
	firsts[first_key]=int(GameState.elapsed_days)
	var copy:=moment.duplicate(true)
	if not copy.has("key"):copy["key"]="first:"+first_key
	copy["first"]=true
	return record(copy)


## Rewrites a told entry (and its card, if it has not yet been shown) with a
## fuller telling of the same event. A notice may become a moment; a moment is
## never lowered. Returns the entry, or {} when `key` was never told.
static func amend(key:String,fields:Dictionary)->Dictionary:
	if not active() or key.is_empty():return {}
	var c:=data()
	for e in c.entries:
		var entry:Dictionary=e
		if String(entry.get("key",""))!=key:continue
		for field in ["title","text","kind","art","action","domain"]:
			if fields.has(field):entry[field]=fields[field].duplicate(true) if fields[field] is Dictionary else (plain(String(fields[field])) if field in ["title","text"] else fields[field])
		var shown:=false
		for card in pending_cards:
			if String(card.get("key",""))==key:
				card.merge(entry,true);shown=true
		if String(fields.get("tier",""))=="moment" and String(entry.get("tier",""))!="moment" and (bool(fields.get("priority",false)) or _moment_room(c,int(entry.get("day",0)))):
			entry["tier"]="moment";entry.erase("crowded")
			var days:Array=c.moment_days
			days.push_front(int(entry.get("day",0)))
			if days.size()>12:days.resize(12)
			if not shown:
				pending_cards.append(entry.duplicate(true))
				if pending_cards.size()>6:pending_cards.pop_front()
		return entry
	return {}


static func _find(predicate:Callable)->Dictionary:
	for e in data().entries:
		if predicate.call(e):return e
	return {}


## Beat kinds that are the same news as one of the Chronicle's own firsts.
const BEAT_FIRSTS:={"first_winter":"first_winter","first_signs":"band_sighted","named_child":"first_birth"}
## Beats that must never be buried by the monthly moment cap.
const PRIORITY_BEATS:=["first_contact","first_winter"]

static func record_beat(beat:Dictionary)->Dictionary:
	if not active():return {}
	var kind:=String(beat.get("kind",""))
	var day:=int(beat.get("day",int(GameState.elapsed_days)))
	var refs:Dictionary=beat.get("refs",{}) if beat.get("refs") is Dictionary else {}
	var civ_id:=String(refs.get("civ_id",""))
	var contact:=kind=="first_contact" or kind.begins_with("met_")
	var told:={"key":"beat:"+String(beat.get("id",kind)),"day":day,"title":String(beat.get("title","")),"text":String(beat.get("text","")),
		"tier":String(beat.get("tier","moment")),"kind":_beat_kind(kind),"domain":"opening","priority":contact or kind in PRIORITY_BEATS,
		# The beat keeps its own line in the event ledger.
		"ledger":false}
	if contact and civ_id!="":told["action"]={"kind":"court","focus":{"civ_id":civ_id}}
	elif int(refs.get("person_id",refs.get("parent_id",0)))>0:told["action"]={"kind":"court","focus":{"person_id":int(refs.get("person_id",refs.get("parent_id",0)))}}
	elif kind=="first_discovery":
		told["action"]={"kind":"section","section":"inquiry","sub":0}
		told["art"]={"discovery_id":String(refs.get("discovery_id","")),"domain":_dynamic_of(String(refs.get("discovery_id","")))}
	var c:=data()
	var firsts:Dictionary=c.firsts
	# The same event, already told: tell it more fully instead of twice.
	var same:Dictionary={}
	if BEAT_FIRSTS.has(kind):
		var first_key:=String(BEAT_FIRSTS[kind])
		if firsts.has(first_key):
			# The first birth is this child only if born the same day; the first
			# sign of strangers is this sign only if the same party brought it.
			if kind=="first_winter" or int(firsts[first_key])==day:same=_find(func(e:Dictionary)->bool:return String(e.get("key",""))=="first:"+first_key)
			if same.is_empty() and kind=="first_winter":return {}
		else:
			firsts[first_key]=day
			told["key"]="first:"+first_key
			told["first"]=true
	elif contact and civ_id!="":
		same=_find(func(e:Dictionary)->bool:return String(e.get("source",""))=="civ:"+civ_id and String(e.get("kind",""))=="contact")
	elif kind=="first_discovery":
		same=_find(func(e:Dictionary)->bool:return String(e.get("key",""))=="discovery:"+String(refs.get("discovery_id","")))
	elif kind.begins_with("headcount_") and PEOPLE_MILESTONES.has(int(kind.trim_prefix("headcount_"))):
		var people_key:="people:"+kind.trim_prefix("headcount_")
		if firsts.has(people_key):
			same=_find(func(e:Dictionary)->bool:return String(e.get("key",""))=="first:"+people_key)
			# Passed silently (at founding, or in one leap past several marks).
			if same.is_empty():return {}
		else:
			firsts[people_key]=day
			told["key"]="first:"+people_key
			told["first"]=true
	if not same.is_empty():
		var fields:=told.duplicate(true)
		fields.erase("key");fields.erase("day")
		# A first discovery keeps its field's name in the title.
		if kind=="first_discovery":fields.erase("title")
		return amend(String(same.key),fields)
	return record(told)


static func _beat_kind(kind:String)->String:
	if kind=="first_contact" or kind.begins_with("met_") or kind.begins_with("regard_") or kind.begins_with("tension_") or kind.begins_with("hunger_"):return "contact"
	if kind.begins_with("war_") or kind.begins_with("strife_") or kind.begins_with("peace_"):return "war"
	if kind=="first_signs" or kind.begins_with("signs_"):return "scout"
	if kind.begins_with("named_child") or kind.begins_with("child_year"):return "birth"
	if kind.begins_with("child_lost"):return "death"
	if kind=="first_discovery":return "discovery"
	if kind=="first_winter":return "court"
	if kind=="land":return "settlement"
	return "milestone"


static func has_first(first_key:String)->bool:
	return active() and (data().firsts as Dictionary).has(first_key)


static func _moment_room(c:Dictionary,day:int)->bool:
	var recent:=0
	for d in c.moment_days:
		if day-int(d)<MOMENT_WINDOW_DAYS:recent+=1
	return recent<MOMENTS_PER_WINDOW


static func _to_ledger(entry:Dictionary)->void:
	var events:Array[Dictionary]=GameState.simulation_events
	events.push_front({"day":int(entry.day),"title":String(entry.title),"description":String(entry.text),"domain":String(entry.get("domain","chronicle")),"severity":"major" if String(entry.tier)=="moment" else "notice","chronicle":true,"chronicle_tier":String(entry.tier),"id":"chronicle_"+String(entry.key)})
	if events.size()>80:events.resize(80)


static func _trim(c:Dictionary)->void:
	var entries:Array=c.entries
	if entries.size()<=ENTRY_LIMIT and _count(entries,"whisper")<=WHISPER_LIMIT:return
	var whispers:=_count(entries,"whisper")
	for i in range(entries.size()-1,-1,-1):
		if entries.size()<=ENTRY_LIMIT and whispers<=WHISPER_LIMIT:break
		var tier:=String((entries[i] as Dictionary).get("tier",""))
		if tier=="whisper" or (entries.size()>ENTRY_LIMIT and tier=="notice" and whispers<=0):
			if tier=="whisper":whispers-=1
			(c.keys as Dictionary).erase(String((entries[i] as Dictionary).get("key","")))
			entries.remove_at(i)
	while entries.size()>ENTRY_LIMIT:
		(c.keys as Dictionary).erase(String((entries.back() as Dictionary).get("key","")))
		entries.pop_back()


static func _count(entries:Array,tier:String)->int:
	var n:=0
	for e in entries:
		if String((e as Dictionary).get("tier",""))==tier:n+=1
	return n


# --- Grading ------------------------------------------------------------------

## Grades any report dictionary (a ledger event or a record request).
static func grade(report:Dictionary)->String:
	var title:=String(report.get("title",""))
	var lower:=title.to_lower()
	var kind:=String(report.get("kind",""))
	var severity:=String(report.get("severity",""))
	if kind=="hearth_count" or severity=="minor":return "whisper"
	# A foreign scout seen on the road is folded into the scouts' own return.
	if kind=="unit_sighting":return "whisper"
	if lower.begins_with("first contact") or title in ["Settlement Site Chosen","New Settlement Seeded"]:return "moment"
	if kind in ["founding","contact","ceremony","milestone"]:return "moment"
	if lower.ends_with(" complete") and String(report.get("domain",""))=="security":return "whisper"
	if title in ["Government Expanded","Official Appointed","Officeholder Dismissed","Leader Dismissed","Local Succession"]:return "whisper"
	if severity in ["notice"] and not bool(report.get("recurring_condition",false)):return "whisper" if String(report.get("domain",""))=="security" else "notice"
	return "notice"


static func kind_of(report:Dictionary)->String:
	var kind:=String(report.get("kind",""))
	if kind=="hearth_count":return kind
	if kind=="first_contact":return "contact"
	if String(report.get("severity",""))=="demographic":return "birth" if kind=="birth" else "death"
	var lower:=String(report.get("title","")).to_lower()
	if lower.begins_with("first contact") or "envoy" in lower or "diplomat" in lower:return "contact"
	if lower=="new settlement seeded":return "settlement"
	if lower=="settlement site chosen":return "founding"
	if "died" in lower or "executed" in lower or "death" in lower:return "death"
	if "scout" in lower or "reconnaissance" in lower or "recruitment party" in lower:return "scout"
	if "captured" in lower or " war" in lower or lower.begins_with("war") or "battle" in lower or "raid" in lower or "siege" in lower:return "war"
	if "sky" in lower or "omen" in lower:return "omen"
	if "caravan" in lower:return "settlement"
	if String(report.get("domain",""))=="institutions":return "court"
	return "work"


# --- Daily intake -------------------------------------------------------------

## Called once per committed player day (local_terrain._commit_world_day).
static func ingest_day(day_result:Dictionary)->void:
	if not active():return
	var c:=data()
	# A year just ended: tell it as one entry before today's news.
	for year in Annals.roll(c,int(GameState.elapsed_days)):
		var told:=record(year)
		# With the AI connection on, the finished year may be told better,
		# once, without the game waiting (chronicle_polish.gd).
		if not told.is_empty():Polish.request(c,told,year.get("facts",{}))
	# A season just ended: keep what it taught in the season's tally.
	_flush_learned(c,int(GameState.elapsed_days))
	for discovery in day_result.get("discoveries",[]):
		if discovery is Dictionary:_discovery(discovery)
	# Steps to proof (first cases, repeated) are lines in the season's tally.
	for step in DiscoverySystem.take_research_steps():_research_step(step)
	for progress in day_result.get("progression",[]):
		if not progress is Dictionary:continue
		var p:Dictionary=progress
		record({"key":"milestone:"+String(p.get("id",p.get("name",""))),"title":String(p.get("name","A turning of the age")),"text":_first_sentences(String(p.get("description",p.get("summary",""))),1),"kind":"milestone","tier":"moment","domain":"progression"})
	_scan_ledger(c)
	_people_milestone()


static func _people_milestone()->void:
	var people:=GameState.population_total
	if GameState.settlement_founded_day<0:return
	var reached:=0
	for threshold in PEOPLE_MILESTONES:
		if people>=int(threshold) and not has_first("people:%d" % int(threshold)):reached=int(threshold)
	if reached<=0:return
	# Crossing several at once (a merger, a load) tells only the highest.
	for threshold in PEOPLE_MILESTONES:
		if int(threshold)<reached:(data().firsts as Dictionary)["people:%d" % int(threshold)]=int(GameState.elapsed_days)
	var annals:=String(voice().era)=="annals"
	var title:=("The registers count %s people" if annals else "The hearths hold %s souls") % _grouped(reached)
	var text:="Never before have there been so many of us. " + ("The count stands at %s." % _grouped(people) if annals else "Counted at the fire: %s." % _grouped(people))
	record_first("people:%d" % reached,{"title":title,"text":text,"kind":"milestone","tier":"moment" if reached>=200 else "notice","domain":"population"})


static func _grouped(value:int)->String:
	var digits:=str(value)
	var out:=""
	for i in digits.length():
		if i>0 and (digits.length()-i)%3==0:out+=","
		out+=digits[i]
	return out


static func _discovery(event:Dictionary)->void:
	var id:=String(event.get("id",""))
	if id.is_empty() or id not in GameState.known_discoveries:return
	var c:=data()
	if (c.keys as Dictionary).has("discovery:"+id):return
	# Proven: its steps this season are told by its proof.
	var pending:Array=(c.get("learned",{}) as Dictionary).get("steps",[])
	for step:Variant in pending.duplicate():
		if step is Dictionary and String((step as Dictionary).get("id",""))==id:pending.erase(step)
	var shown:Dictionary=DiscoverySystem.player_facing_discovery_event(event)
	var dynamic:=String(shown.get("dynamic",_dynamic_of(id)))
	var firsts:Dictionary=c.firsts
	var first:=dynamic!="" and not firsts.has("domain:"+dynamic)
	if first:firsts["domain:"+dynamic]=id
	var name:=String(shown.get("name",id.replace("_"," ").capitalize()))
	var field:=field_name(dynamic)
	var text:=_first_sentences(String(shown.get("description","")),1)
	if first:text=("The first knowing of %s. " % field)+text
	var tier:="moment" if (first or id in RESEARCH_MILESTONES) and GameState.research_notification_mode!="quiet" else "notice"
	if tier=="notice" and not first and id not in RESEARCH_MILESTONES:
		# A repeat discovery in a field already known is kept as a line in the
		# season's tally and the event ledger, and told once at the season's
		# end with everything else the people learned (_flush_learned).
		var kept:=record({"key":"discovery:"+id,"title":name,"text":text.strip_edges(),"kind":"discovery","tier":"whisper","art":{"discovery_id":id,"domain":dynamic},"action":{"kind":"section","section":"inquiry","sub":0},"domain":dynamic,"ledger":false})
		if kept.is_empty():return
		Annals.note_learned(c,name,int(kept.day))
		var learned:Dictionary=c.get("learned",{})
		var season:=season_of(int(kept.day))
		if learned.is_empty() or int(learned.get("season",season))!=season:
			_flush_learned(c)
			learned={"season":season,"ids":[],"names":[],"fields":[]}
		# The first few of a season each get their ledger line; the rest wait
		# for the season's one line (_flush_learned).
		if (learned.ids as Array).size()<LEARNED_LEDGER_LINES:
			var ledger_line:=kept.duplicate(true);ledger_line["tier"]="notice"
			_to_ledger(ledger_line)
		(learned.ids as Array).append(id);(learned.names as Array).append(name)
		if not (learned.fields as Array).has(dynamic):(learned.fields as Array).append(dynamic)
		c["learned"]=learned
		return
	var entry:=record({"key":"discovery:"+id,"title":name,"text":text.strip_edges(),"kind":"discovery","tier":tier,"art":{"discovery_id":id,"domain":dynamic},"action":{"kind":"section","section":"inquiry","sub":0},"domain":dynamic,"first":first})
	if String(entry.get("tier",""))=="moment":(c.moment_ids as Dictionary)[id]=true


## A question under way reached a step to proof: kept for the season's tally
## (_flush_learned), never told on its own.
static func _research_step(step:Dictionary)->void:
	var id:=String(step.get("id",""))
	if id.is_empty() or id in GameState.known_discoveries:return
	var c:=data()
	var learned:Dictionary=c.get("learned",{})
	var season:=season_of(int(step.get("day",int(GameState.elapsed_days))))
	if learned.is_empty() or int(learned.get("season",season))!=season:
		_flush_learned(c)
		learned={"season":season,"ids":[],"names":[],"fields":[]}
	var steps:Array=learned.get("steps",[])
	for kept:Variant in steps:
		# A question that went on to its next step this season is told once, at it.
		if kept is Dictionary and String((kept as Dictionary).get("id",""))==id:steps.erase(kept);break
	steps.append({"id":id,"name":String(step.get("name",id)),"stage":int(step.get("stage",1)),"share":float(step.get("share",0.0)),"dynamic":String(step.get("dynamic",""))})
	learned["steps"]=steps
	c["learned"]=learned


## The season's steps to proof in plain words: "First cases held for clay
## tempering: 5 in 100 households try it. Ox yokes held up when repeated: 15 in
## 100 households use them."
static func _steps_text(steps:Array)->String:
	var parts:PackedStringArray=[]
	for stage in [1,2]:
		var names:Array=[]
		var share:=0.0
		for step:Variant in steps:
			if not step is Dictionary or int((step as Dictionary).get("stage",1))!=stage:continue
			names.append(String((step as Dictionary).get("name","")).to_lower())
			share=maxf(share,float((step as Dictionary).get("share",0.0)))
		if names.is_empty():continue
		var households:=roundi(share*100.0)
		var many:=names.size()>1
		var listed:=_some(names)
		if stage==1:parts.append("First cases held for %s: %d in 100 households try %s." % [listed,households,"them" if many else "it"])
		else:parts.append("%s held up when repeated: %d in 100 households use %s." % [listed.left(1).to_upper()+listed.substr(1),households,"them" if many else "it"])
	return " ".join(parts)


## A field of knowledge in the people's words ("food & foraging" before farming).
static func field_name(dynamic:String)->String:
	if dynamic=="nutrition" and not preload("res://scripts/character_voice.gd").era_tags("player").has("farming"):return "food & foraging"
	return String(DOMAIN_NAMES.get(dynamic,dynamic.replace("_"," ")))


## Season index since the world began (same quarter-years as hearth_count.gd).
static func season_of(day:int)->int:
	return floori((float(day)+45.625)/91.25)


## Tells the season's repeat discoveries as one notice: "This season the
## people learned: ...". Called when a new season begins (ingest_day) or when
## a discovery of a new season arrives. The first discovery in each field stays
## its own moment.
static func _flush_learned(c:Dictionary,today:int=-1)->Dictionary:
	var learned:Dictionary=c.get("learned",{})
	var steps:Array=learned.get("steps",[])
	if learned.is_empty() or ((learned.get("ids",[]) as Array).is_empty() and steps.is_empty()):
		c.erase("learned");return {}
	var season:=int(learned.season)
	if today>=0 and season_of(today)==season:return {}
	c.erase("learned")
	var names:Array=learned.get("names",[])
	var hemisphere:=float((GameState.hearth_season as Dictionary).get("hemisphere",1.0))
	var season_name:String=["spring","summer","autumn","winter"][posmod(season+(0 if hemisphere>=0.0 else 2),4)]
	var annals:=String(voice().era)=="annals"
	var text:=""
	# More than the ledger told one by one: one line counts them all.
	var rush:=names.size()>LEARNED_LEDGER_LINES
	if not names.is_empty():
		var lowered:=names.map(func(n:Variant)->String:return String(n).to_lower())
		var fields:PackedStringArray=[]
		for f in learned.fields:fields.append(field_name(String(f)))
		if rush:text=("This season the keepers recorded %d new ways, among them %s." if annals else "This season the people learned %d new ways, among them %s.") % [names.size(),_list(lowered.slice(0,LIST_NAMES))]
		else:text=("This season the keepers recorded new learning: %s." if annals else "This season the people learned: %s.") % _list(lowered)
		if fields.size()>1:text+=" Their knowing grew in %s." % _some(Array(fields))
	var stepped:=_steps_text(steps)
	if not stepped.is_empty():text=(text+" "+stepped).strip_edges()
	var day:=int(season*91.25+45.625)-1 if today<0 else today
	var first_id:=String((learned.ids as Array)[0]) if not (learned.ids as Array).is_empty() else String((steps[0] as Dictionary).get("id",""))
	var first_field:=String((learned.fields as Array)[0]) if not (learned.fields as Array).is_empty() else String((steps[0] as Dictionary).get("dynamic","knowledge"))
	var title:="What the %s taught" % season_name
	if rush:title+=": %d new ways" % names.size()
	var told:=record({"key":"learned:%d" % season,"day":mini(day,int(GameState.elapsed_days)),"title":title,"text":text,"kind":"discovery","tier":"notice","art":{"discovery_id":first_id,"domain":first_field},"action":{"kind":"section","section":"inquiry","sub":0},"domain":"knowledge","ledger":false,"learned":(learned.ids as Array).duplicate()})
	if rush and not told.is_empty():
		var ledger_line:=told.duplicate(true);ledger_line["tier"]="notice"
		_to_ledger(ledger_line)
	return told


## A list of at most LIST_NAMES names, the rest counted: "a, b, c, d and 21 more".
static func _some(items:Array)->String:
	if items.size()<=LIST_NAMES:return _list(items)
	return "%s and %d more" % [", ".join(PackedStringArray(items.slice(0,LIST_NAMES).map(func(n:Variant)->String:return String(n)))),items.size()-LIST_NAMES]


static func _list(items:Array)->String:
	if items.is_empty():return ""
	if items.size()==1:return String(items[0])
	var head:=PackedStringArray()
	for i in items.size()-1:head.append(String(items[i]))
	return "%s and %s" % [", ".join(head),String(items.back())]


## True when this discovery was presented as a moment (its card replaces the popup).
static func discovery_is_moment(id:String)->bool:
	return active() and (data().moment_ids as Dictionary).has(id)


static func _scan_ledger(c:Dictionary)->void:
	var from_day:=int(c.get("scan_day",0))-1
	var keys:Dictionary=c.keys
	var found:Array=[]
	for event_variant in GameState.simulation_events:
		if not event_variant is Dictionary:continue
		var ev:Dictionary=event_variant
		if bool(ev.get("chronicle",false)):continue
		# Sickness and disasters are kept in their own log (hardship_log.gd);
		# the rare extreme one is told by the system that keeps that log.
		if bool(ev.get("hardship",false)):continue
		# The court tells a death in office itself, as a mourning moment
		# (court_lives.gd), and removes this clerk's line; never tell it twice.
		if String(ev.get("title",""))=="Officeholder Died":continue
		var day:=int(ev.get("day",int(GameState.elapsed_days)))
		if day<from_day:continue
		var key:=_ledger_key(ev)
		if keys.has(key):continue
		found.push_front([key,ev])
	# Oldest first, so the feed reads in the order things happened.
	for pair in found:
		var ev:Dictionary=pair[1]
		if String(ev.get("kind",""))=="hearth_count":Annals.note_tally(c,ev)
		var told:=_retell(ev)
		var tier:=grade(ev)
		if told.size()>2 and bool(told[2]):tier="whisper"
		# A standing hardship (short water, falling stores) is news when it
		# begins, not every time its warning repeats.
		var condition:=String(ev.get("condition_id",""))
		if condition!="" and tier=="notice":
			var seen:Dictionary=c.get("conditions",{})
			var day:=int(ev.get("day",0))
			if day-int(seen.get(condition,-100000))<CONDITION_QUIET_DAYS:tier="whisper"
			seen[condition]=day
			c["conditions"]=seen
		var told_entry:={"key":String(pair[0]),"day":int(ev.get("day",int(GameState.elapsed_days))),"title":String(told[0]),"text":String(told[1]),"tier":tier,"kind":kind_of(ev),"ledger":false,"domain":String(ev.get("domain",""))}
		# A party home with real news is the Chronicle's own card, and the card
		# opens the party's illustrated report (no separate expedition toast).
		if ev.has("mission_id") and tier!="whisper":
			# A standing city watch reports often; its returns stay notices.
			if String(ev.get("title",""))!="CITY RECONNAISSANCE":told_entry["tier"]="moment"
			told_entry["kind"]="scout"
			told_entry["action"]={"kind":"scout_report","mission_id":int(ev.mission_id)}
		# First contact is never buried by the moment cap, and remembers whom it met.
		if String(ev.get("kind",""))=="first_contact":
			told_entry["priority"]=true
			if String(ev.get("civ_id",""))!="":told_entry["source"]="civ:"+String(ev.civ_id)
		record(told_entry)
	c["scan_day"]=int(GameState.elapsed_days)


## The ledger speaks like a clerk; the Chronicle retells the few lines that
## matter most in the people's own terms. Returns [title, text].
static func _retell(ev:Dictionary)->Array:
	var title:=String(ev.get("title",""))
	var description:=String(ev.get("description",""))
	match title:
		"Settlement Site Chosen":
			var place:=GameState.settlement_name.strip_edges()
			return ["The wandering ends" if place=="" else "The wandering ends at %s" % place,"The god bade the people halt and make a home. The first fire is lit; the hearth circle will rise from their own hands."]
		"New Settlement Seeded":
			var parts:=description.split(" arrived and established ")
			if parts.size()==2:
				var founders:=parts[0].strip_edges()
				var village:=parts[1].get_slice(".",0).strip_edges()
				return ["%s is founded" % village,"%s of our people walked out and raised a new hearth at %s. They are still our people, and still the god's." % [founders,village]]
		"SCOUTS RETURN","RECRUITMENT PARTY RETURNS":
			# Tell what was new, not the clerk's lines about what was not.
			var kept:PackedStringArray=[]
			for sentence in _sentences(description):
				var lower:=sentence.to_lower()
				if "no organized foreign polity" in lower or "met no other people" in lower or "knowledge workers will examine" in lower or "specific evidence becomes usable" in lower or "the map now reveals" in lower:continue
				# Near neighbours' scouts cross ours all the time; their trails are
				# marked on the map, not told at the fire.
				if "crossed the trail of a foreign" in lower or kept.has(sentence):continue
				kept.append(sentence)
			# Road news the people have heard before is counted for the year's
			# telling; only what is new is told (chronicle_annals.gd).
			var story:=Annals.scout_story(data(),title,kept)
			return [String(story[0]),String(story[1]).left(360),bool(story[2])]
	return [_story_title(title),_story_text(ev)]


static func _sentences(text:String)->PackedStringArray:
	var out:PackedStringArray=[]
	var clean:=text.strip_edges()
	var start:=0
	for i in clean.length():
		if clean[i] in [".","!","?"] and (i==clean.length()-1 or clean[i+1]==" "):
			out.append(clean.substr(start,i-start+1).strip_edges())
			start=i+1
	if start<clean.length() and clean.substr(start).strip_edges()!="":out.append(clean.substr(start).strip_edges())
	return out


static func _ledger_key(ev:Dictionary)->String:
	# Demographic episodes grow in place; their id is the stable identity.
	if ev.has("id") and String(ev.get("severity",""))=="demographic":return "demo|"+String(ev.id)
	return "ev|%d|%s|%s" % [int(ev.get("day",0)),String(ev.get("title","")),String(ev.get("description","")).left(48)]


# --- Presentation helpers -----------------------------------------------------

static func voice()->Dictionary:
	var signature:=GameState.known_discoveries.size()
	if signature==_voice_signature and not _voice_cache.is_empty():return _voice_cache
	_voice_signature=signature
	var tags:Array=preload("res://scripts/character_voice.gd").era_tags("player")
	if tags.has("writing"):
		_voice_cache={"era":"annals","feed":"The Annals","subtitle":"What the keepers of the annals have written of the people.","moment":"ENTERED IN THE ANNALS","notice":"NOTED IN THE ANNALS","whisper":"THE REGISTER","ticker":"THE ANNALS","count":"Register","people":"people","born":"births","buried":"deaths","show_whispers":"Show the season registers","hide_whispers":"Hide the season registers"}
	else:
		_voice_cache={"era":"tally","feed":"Hearth-Tales","subtitle":"What the people tell at the fire, and mark as notches on the tally-stick.","moment":"TOLD AT THE FIRE","notice":"REMEMBERED","whisper":"TALLY-MARKS","ticker":"HEARTH-TALE","count":"Tally","people":"souls at the hearths","born":"born","buried":"buried","show_whispers":"Show the season tallies","hide_whispers":"Hide the season tallies"}
	return _voice_cache


static func entries(min_tier:String="whisper",limit:int=0)->Array:
	if Engine.get_main_loop()==null:return []
	var floor_index:=maxi(0,TIERS.find(min_tier))
	var out:Array=[]
	for e in data().entries:
		if TIERS.find(String((e as Dictionary).get("tier","whisper")))<floor_index:continue
		out.append(e)
		if limit>0 and out.size()>=limit:break
	return out


static func latest_headline()->String:
	var newest:=entries("notice",1)
	if newest.is_empty():return ""
	var e:Dictionary=newest[0]
	var text:=String(e.get("text",""))
	return "%s: %s%s" % [String(voice().ticker),String(e.title).to_upper(),"  •  "+text.left(160) if text!="" else ""]


static func date_label(day:int)->String:
	# Same quarter-year seasons as scripts/hearth_count.gd (kept free of a
	# cyclic preload).
	var key:=floori((float(day)+45.625)/91.25)
	var hemisphere:=float((GameState.hearth_season as Dictionary).get("hemisphere",1.0))
	var season:String=["Spring","Summer","Autumn","Winter"][posmod(key+(0 if hemisphere>=0.0 else 2),4)]
	return "Year %d · %s" % [day/365+1,season]


static func _story_title(title:String)->String:
	var t:=title.strip_edges()
	if t==t.to_upper() and t.length()>3:t=t.capitalize()
	return t


static func _story_text(ev:Dictionary)->String:
	var text:=String(ev.get("description",""))
	for boilerplate in [" The map now reveals only the physical route contained in its returned report."," The office and local duties now pass through the same succession rules as every other appointment."]:
		text=text.replace(boilerplate,"")
	return _first_sentences(text,2).left(260)


static func _first_sentences(text:String,count:int)->String:
	var clean:=text.strip_edges()
	if clean.is_empty():return ""
	var out:=""
	var taken:=0
	var start:=0
	for i in clean.length():
		var ch:=clean[i]
		if ch in [".","!","?"] and (i==clean.length()-1 or clean[i+1]==" "):
			out+=clean.substr(start,i-start+1)
			taken+=1
			start=i+1
			if taken>=count:break
	if taken==0:out=clean
	return out.strip_edges()


static func _dynamic_of(id:String)->String:
	if id.is_empty():return ""
	var definition:Dictionary=DiscoverySystem.discovery_definition(id) if DiscoverySystem.has_method("discovery_definition") else {}
	return String(definition.get("dynamic",""))
