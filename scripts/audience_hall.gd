extends RefCounted
## Audience Hall engine. The world comes to the ruler: foreign envoys bring
## gifts, requests, tribute demands, news and proposals; officials petition
## about real conditions, grievances and ambitions. This is the only place the
## hall changes world state. Voice text never moves goods or relations; it may
## only nudge the bounded room `mood`, which adds at most ±0.03 opinion at
## resolve.
##
## Pacing (revision 2). Audiences are occasioned, not timed: a daily watch
## notices what CHANGED or MATTERS (first contact, a relation swing, a war
## beginning or ending, a famine, a recruitment incident, a new official, a
## grievance, a promise left hanging, the sequel to an earlier audience) and
## files an occasion. An occasion becomes an audience only inside a budget:
## about one every `FREQUENCIES[frequency]` days on average, never within
## MIN_GAP days of another, each civilization at most every CIV_GAP days and
## each official every PERSON_GAP days (crises and promised follow-ups may come
## sooner), and never the same speaker twice in a row unless answering a thread.
## A ledger remembers every (speaker, ask) for three years so nothing repeats,
## and later audiences branch on how earlier ones ended.
##
## State lives in ForeignDiplomacy.audiences and is saved with that system.
## Reference with preload (no class_name; the runtime class cache is not
## rebuilt outside the editor).

const EXCHANGE:=preload("res://scripts/civilization_exchange.gd")
const SOCIETY:=preload("res://scripts/society_exchange.gd")
const NAMES:=preload("res://scripts/historical_name_generator.gd")
const COMMITMENTS:=preload("res://scripts/diplomatic_commitments.gd")
const RUMORS:=preload("res://scripts/rumor_network.gd")
const INTEL:=preload("res://scripts/city_intelligence.gd")
const SCHOLARS:=preload("res://scripts/scholar_visits.gd")
const PURCHASE:=preload("res://scripts/research_purchase.gd")
const LICENSES:=preload("res://scripts/research_licenses.gd")
const ARTIFACTS:=preload("res://scripts/artifact_collection.gd")
const RIVALRY:=preload("res://scripts/great_works_rivalry.gd")
const DIVINE:=preload("res://scripts/divine_regard.gd")
const RESOURCES:=["Food","Timber","Stone","Clay","Fiber Plants"]
const KINDS:=["gift","request","threat","news","petition","report","great_work","wonder_proposal","proposal","summons"]
## Kinds raised by our own people (origin "court").
const COURT_KINDS:=["petition","report","great_work","wonder_proposal","summons"]
const WORK_KINDS:=["great_work","wonder_proposal"]
const GREAT_WORKS_PATH:="res://scripts/great_works_audience.gd"
const REPORT_SOURCES:=["scouts","envoys","expedition"]
const REPORT_FACTS_MAX:=24
const TOPICS:=["food","health","housing","security","people","grievance","ambition","introduction","follow_up","war","summons","mourning","callback","omen","aim"]
const LIVES_PATH:="res://scripts/court_lives.gd"
const AIMS_PATH:="res://scripts/legacy_aims.gd"
const RIVALS_PATH:="res://scripts/rival_rulers.gd"
const REACTIONS:=["delighted","pleased","neutral","offended","furious"]
const VERSION:=3
const EXPIRY_DAYS:=20
const QUEUE_MAX:=4
const HISTORY_MAX:=30
const LINES_MAX:=60
const COURT_MAX:=4
const MOOD_OPINION:=0.03

# ---- pacing budget ----
## Average days between audiences the hall raises itself, by setting.
const FREQUENCIES:={"rare":150,"normal":90,"lively":60}
## Hard minimum between any two arrivals.
const MIN_GAP:=20
## Kept for older callers: the global gap is now the hard minimum.
const GAP_DAYS:=MIN_GAP
const CIV_GAP:=180
const CIV_CRISIS_GAP:=60
const PERSON_GAP:=240
const PERSON_THREAD_GAP:=120
const PERSON_CRISIS_GAP:=90
## No speaker repeats the same ask within this many days.
const REPEAT_DAYS:=1095
const LEDGER_MAX:=240
const OCCASIONS_MAX:=48
const SITUATION_JSON_MAX:=4000
## Waiting audiences a legacy save keeps when it is calmed on load.
const MIGRATION_KEEP:=2
## Matters: what the court would raise if summoned. Only foreign envoys come
## to the hall on their own; officials, the Chief Scout and architects keep
## their business as dated matters until the ruler calls them in.
const MATTERS_MAX:=40
const MATTERS_PER_HOLDER:=5
const MATTER_DAYS:=150
## Set while a test, capture or the ruler's own call raises a court audience directly.
static var _court_direct:=false
## Occasions that continue an earlier audience (they may follow sooner).
const THREAD_OCCASIONS:=["sequel","promise_followup","refusal_grievance"]
const COURT_OCCASIONS:=["condition","grievance","appointment","war_council","promise_followup","refusal_grievance","ambition"]

## Every situation the hall can raise, its audience kind, and the real
## mechanic its answers resolve through. `headline` is a short herald phrase.
const SITUATIONS:={
	"gift_goods":{"kind":"gift","headline":"brings a gift","mechanic":"civilization_exchange take/receive between real ledgers"},
	"gratitude_gift":{"kind":"gift","headline":"returns kindness with a gift","mechanic":"civilization_exchange take/receive between real ledgers"},
	"aid_request":{"kind":"request","headline":"asks for help","mechanic":"player stores debited; DiplomaticCommitments.note_food_aid"},
	"tribute_demand":{"kind":"threat","headline":"demands tribute","mechanic":"stores debited or ForeignDiplomacy.apply_conversation_reaction"},
	"emboldened_demand":{"kind":"threat","headline":"demands more tribute","mechanic":"stores debited or ForeignDiplomacy.apply_conversation_reaction"},
	"test_of_resolve":{"kind":"threat","headline":"tests your resolve","mechanic":"stores debited or ForeignDiplomacy.apply_conversation_reaction"},
	"news_report":{"kind":"news","headline":"brings news","mechanic":"third-party facts; contact_intelligence"},
	"rumor_share":{"kind":"news","headline":"shares what travelers say","mechanic":"RumorNetwork.receive into the player's book"},
	"intelligence_share":{"kind":"news","headline":"shares what they have seen of a city","mechanic":"CityIntelligence.publish of their dated observation"},
	"accord_offer":{"kind":"proposal","headline":"proposes an understanding","mechanic":"ForeignDiplomacy accord (forecast blockers, SocietyExchange.accept_accord)"},
	"protection_pact":{"kind":"proposal","headline":"proposes mutual protection","mechanic":"DiplomaticCommitments pacts (eligibility)"},
	"league_invitation":{"kind":"proposal","headline":"speaks of a league","mechanic":"DiplomaticCommitments factions (eligibility, unanimous assessment)"},
	"war_support":{"kind":"proposal","headline":"asks you to take a side","mechanic":"relations with both belligerents; leader memories"},
	"peace_feeler":{"kind":"proposal","headline":"comes seeking peace","mechanic":"CivilizationSystem.conduct_player_action seek_peace"},
	"trade_offer":{"kind":"proposal","headline":"proposes a trade compact","mechanic":"CivilizationSystem.conduct_player_action open_trade"},
	"nonaggression_offer":{"kind":"proposal","headline":"proposes a non-aggression compact","mechanic":"CivilizationSystem.conduct_player_action non_aggression"},
	"scholar_offer":{"kind":"proposal","headline":"offers a visiting teacher","mechanic":"ScholarVisits.envoy_quote/host_from_envoy; goods paid to their ledger"},
	"research_sale":{"kind":"proposal","headline":"offers a validated study for sale","mechanic":"ResearchPurchase.envoy_quote/deliver_from_envoy; goods paid to their ledger"},
	"license_offer":{"kind":"proposal","headline":"offers a production license","mechanic":"ResearchLicenses.envoy_quote/grant_from_envoy; goods paid to their ledger"},
	"artifact_gift":{"kind":"proposal","headline":"brings a treasured object","mechanic":"ArtifactCollection.exchange gift (ownership, provenance, respect)"},
	"artifact_purchase":{"kind":"proposal","headline":"asks for one of your treasures","mechanic":"ArtifactCollection.exchange sell (money and metal backing conserved) or trade"},
	"artifact_return":{"kind":"proposal","headline":"demands a treasure back","mechanic":"GreatWorksRivalry.return_loot or ArtifactCollection.exchange gift"},
	"recruitment_protest":{"kind":"proposal","headline":"protests your recruiters","mechanic":"restraint accord, goods, or apply_conversation_reaction"},
	"crisis_petition":{"kind":"petition","headline":"raises an alarm","mechanic":"civic decree pipeline; official relationship"},
	"grievance":{"kind":"petition","headline":"brings a grievance","mechanic":"official relationship and memory"},
	"ambition":{"kind":"petition","headline":"brings a proposal","mechanic":"civic decree pipeline; official relationship"},
	"promise_followup":{"kind":"petition","headline":"reminds you of a promise","mechanic":"civic decree pipeline; official relationship"},
	"introduction":{"kind":"petition","headline":"presents themselves","mechanic":"civic decree pipeline; official relationship"},
	"war_council":{"kind":"petition","headline":"comes about the war","mechanic":"civic decree pipeline; official relationship"},
	"summons":{"kind":"summons","headline":"answers your summons","mechanic":"the ruler's own call; spoken orders go to the civic pipeline"},
	"mourning":{"kind":"petition","headline":"comes from the burial","mechanic":"court_lives.gd; GovernmentPeopleSystem appoints the successor"},
	"callback":{"kind":"petition","headline":"brings word of an old order","mechanic":"court_lives.gd; what really changed since the order"},
	"omen":{"kind":"petition","headline":"comes about the sign","mechanic":"court_lives.gd; the real weather or health agreed with the god's word"},
	"aim":{"kind":"petition","headline":"speaks of what we should strive for","mechanic":"legacy_aims.gd; a generational aim measured against the real simulation"},
	"dread_tribute":{"kind":"gift","headline":"brings tribute, fearing your wrath","mechanic":"civilization_exchange take/receive between real ledgers"},
	"debt_call":{"kind":"request","headline":"comes to collect a debt","mechanic":"rival_rulers.gd debts; player stores debited"},
	"redress_demand":{"kind":"threat","headline":"demands redress for an old wrong","mechanic":"rival_rulers.gd grudges; stores debited or ForeignDiplomacy.apply_conversation_reaction"},
}

## Which situations an occasion invites, with base weights.
const OCCASION_MIX:={
	"first_contact":{"gift_goods":1.2,"news_report":0.9,"accord_offer":0.7,"rumor_share":0.8,"intelligence_share":0.6,"trade_offer":0.6,"artifact_gift":0.6},
	"relation_warm":{"gift_goods":0.7,"accord_offer":1.0,"protection_pact":0.8,"league_invitation":0.6,"scholar_offer":0.8,"research_sale":0.6,"license_offer":0.5,"trade_offer":0.8,"nonaggression_offer":0.4,"artifact_gift":0.7,"artifact_purchase":0.5},
	"relation_cool":{"tribute_demand":1.0,"nonaggression_offer":0.6,"accord_offer":0.5,"news_report":0.3,"artifact_return":0.9},
	"tension_rise":{"tribute_demand":1.2,"nonaggression_offer":0.8,"accord_offer":0.7,"artifact_return":0.6},
	"war_end":{"gift_goods":0.6,"nonaggression_offer":1.0,"trade_offer":0.6,"accord_offer":0.6,"artifact_return":1.5},
	"peace_possible":{"peace_feeler":1.0},
	"their_famine":{"aid_request":1.0},
	"recruitment_incident":{"recruitment_protest":1.0},
	"third_war":{"war_support":1.0,"news_report":0.35},
	"dread_tribute":{"dread_tribute":1.0},
	"dread_test":{"test_of_resolve":1.0,"tribute_demand":0.4},
	"debt_due":{"debt_call":1.0},
	"grudge":{"redress_demand":1.0,"tribute_demand":0.25},
	"kin_call":{"war_support":1.0},
	"ambient":{"gift_goods":0.6,"accord_offer":0.6,"scholar_offer":0.8,"research_sale":0.6,"license_offer":0.5,"rumor_share":0.8,"intelligence_share":0.6,"news_report":0.5,"trade_offer":0.4,"league_invitation":0.4,"protection_pact":0.3,"artifact_gift":0.7,"artifact_purchase":0.6,"artifact_return":1.0},
}

## An official's evolving ambitions: each is a decree the civic interpreter
## understands. Fulfilled or refused ambitions are not raised again for three
## years; the next one on the list comes instead.
const AMBITIONS:={
	"Steward":["Improve roads and organize haulers","Build stone houses for the families","Support families and care for children","Hold a public council to hear the people"],
	"Quartermaster":["Expand workshops and make tools","Quarry stone and prioritize stone","Improve roads and organize haulers","Conserve the land and rest the fields"],
	"Marshal":["Post guards and patrol the frontier","Raise recruits for the frontier guard","Improve roads and organize haulers"],
	"Scholar":["Support scholars and fund research","Organize healers to care for the sick","Conserve the land and rest the fields"],
	"Envoy":["Hold a public council to hear the people","Send a recruiting expedition to find new people to join us","Improve roads and organize haulers"],
	"ChiefScout":["Send a recruiting expedition to find new people to join us","Post guards and patrol the frontier","Improve roads and organize haulers"],
	"settlement":["Build shelters and repair housing","Improve roads and organize haulers","Hold a public council to hear the people"],
}
const AMBITION_WORDS:={
	"Improve roads and organize haulers":"%s wants the roads improved and hauling organized.",
	"Build stone houses for the families":"%s wants families moved out of brush and hide into houses of stone.",
	"Support families and care for children":"%s wants the settlement to help parents and care for its children.",
	"Hold a public council to hear the people":"%s wants a public council where the people can be heard.",
	"Expand workshops and make tools":"%s wants the workshops enlarged and tools made in earnest.",
	"Quarry stone and prioritize stone":"%s wants crews sent to quarry stone before the next building season.",
	"Conserve the land and rest the fields":"%s wants the land rested before it is worn out.",
	"Post guards and patrol the frontier":"%s wants patrols along the frontier, commanded by them.",
	"Raise recruits for the frontier guard":"%s wants recruits raised and trained for a standing frontier guard.",
	"Support scholars and fund research":"%s wants more hands set to inquiry, under their eye.",
	"Organize healers to care for the sick":"%s wants healers organized before the next sickness, not during it.",
	"Send a recruiting expedition to find new people to join us":"%s wants an expedition sent to find people willing to join us.",
	"Build shelters and repair housing":"%s wants shelters built and the worst houses repaired.",
}

# --------------------------------------------------------------------------
# State
# --------------------------------------------------------------------------

static func state()->Dictionary:
	ForeignDiplomacy.ensure()
	var s:Dictionary=ForeignDiplomacy.audiences
	if not s.has("version"): s["version"]=VERSION
	if not s.get("queue") is Array: s["queue"]=[]
	if not s.get("history") is Array: s["history"]=[]
	if not s.get("next_foreign") is Dictionary: s["next_foreign"]={}
	if not s.get("next_court") is Dictionary: s["next_court"]={}
	if not s.has("last_arrival_day"): s["last_arrival_day"]=-9999
	if not s.has("serial"): s["serial"]=0
	if not s.has("summon_immediately"): s["summon_immediately"]=true
	if not s.get("ledger") is Array: s["ledger"]=[]
	if not s.get("occasions") is Array: s["occasions"]=[]
	if not s.get("matters") is Array: s["matters"]=[]
	for key:String in ["watch","last_civ","last_person"]:
		if not s.get(key) is Dictionary: s[key]={}
	if not s.has("next_any"): s["next_any"]=0
	if not s.get("last_speaker") is String: s["last_speaker"]=""
	if not String(s.get("frequency","")) in FREQUENCIES: s["frequency"]="normal"
	ForeignDiplomacy.audiences=s
	if int(s.version)<2: _migrate(s)
	if int(s.version)<3: _migrate_court(s)
	return s

static func waiting()->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	for audience in state().queue:
		if String(audience.get("status",""))=="waiting": result.append(audience)
	result.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return int(a.arrived_day)<int(b.arrived_day) or (int(a.arrived_day)==int(b.arrived_day) and _serial_of(a)<_serial_of(b)))
	return result

static func find(id:String)->Dictionary:
	var s:=state()
	for list_key in ["queue","history"]:
		for audience in s[list_key]:
			if String(audience.get("id",""))==id: return audience
	return {}

static func _serial_of(audience:Dictionary)->int:
	return int(String(audience.get("id","aud_0")).trim_prefix("aud_"))

static func _day()->int:
	return int(GameState.elapsed_days)

static func _lives()->GDScript:
	## Deaths, successions, omens and callbacks (court_lives.gd); loaded lazily
	## because that module reaches back into this one.
	return load(LIVES_PATH) as GDScript

static func _aims()->GDScript:
	## Generational aims (legacy_aims.gd); loaded lazily because that module
	## reaches back into this one.
	return load(AIMS_PATH) as GDScript

static func _rivals()->GDScript:
	## Rival rulers as characters, and the strings envoys carry
	## (rival_rulers.gd); loaded lazily because it reaches back into this one.
	return load(RIVALS_PATH) as GDScript

static func _great_works()->GDScript:
	## Great Works audiences (architects, rival races, forecasts); loaded lazily
	## because that module reaches back into this one.
	return load(GREAT_WORKS_PATH) as GDScript if ResourceLoader.exists(GREAT_WORKS_PATH) else null

static func _rng(key:String,day:int)->RandomNumberGenerator:
	var rng:=RandomNumberGenerator.new()
	rng.seed=hash("%d:audience:%s:%d" % [int(GameState.world_seed),key,day])
	return rng

# --------------------------------------------------------------------------
# Frequency setting and budget
# --------------------------------------------------------------------------

static func set_frequency(level:String)->bool:
	## "rare" | "normal" | "lively". The next routine audience is pulled in or
	## pushed out to fit the new rhythm; the hard minimum gap still applies.
	if not level in FREQUENCIES: return false
	var s:=state()
	s.frequency=level
	var last:=int(s.last_arrival_day)
	var cap:=last+roundi(float(_gap())*1.3)
	if int(s.next_any)>cap: s.next_any=maxi(cap,last+MIN_GAP)
	return true

static func frequency()->String:
	return String(state().frequency)

static func _gap()->int:
	return int(FREQUENCIES.get(String(state().get("frequency","normal")),90))

static func pacing()->Dictionary:
	## Plain numbers for the modal footer and tests.
	var s:=state()
	return {"frequency":String(s.frequency),"average_gap_days":_gap(),"min_gap_days":MIN_GAP,"next_routine_day":int(s.next_any),
		"last_arrival_day":int(s.last_arrival_day),"pending_occasions":(s.occasions as Array).size(),"civ_gap_days":CIV_GAP,"official_gap_days":PERSON_GAP}

static func _budget_allows(occasion:Dictionary,day:int)->bool:
	var s:=state()
	var since:=day-int(s.last_arrival_day)
	if since<MIN_GAP: return false
	if bool(occasion.get("crisis",false)): return since>=maxi(MIN_GAP,roundi(float(_gap())*0.5))
	return day>=int(s.next_any)

static func _speaker_allows(occasion:Dictionary,day:int)->bool:
	var s:=state()
	var key:=_occasion_speaker(occasion)
	if key=="": return true
	var thread:=String(occasion.get("type","")) in THREAD_OCCASIONS
	var crisis:=bool(occasion.get("crisis",false))
	if key==String(s.last_speaker) and not thread: return false
	if key.begins_with("civ:"):
		var last:=int((s.last_civ as Dictionary).get(key.trim_prefix("civ:"),-99999))
		return day-last>=(CIV_CRISIS_GAP if crisis else CIV_GAP)
	var last_person:=int((s.last_person as Dictionary).get(key.trim_prefix("person:"),-99999))
	return day-last_person>=(PERSON_CRISIS_GAP if crisis else (PERSON_THREAD_GAP if thread else PERSON_GAP))

static func _occasion_speaker(occasion:Dictionary)->String:
	var type:=String(occasion.get("type",""))
	if type in COURT_OCCASIONS:
		var pid:=int(occasion.get("person_id",0))
		return "person:%d" % pid if pid>0 else ""
	var civ_id:=String(occasion.get("civ_id",""))
	return "civ:"+civ_id if civ_id!="" else ""

# --------------------------------------------------------------------------
# Daily arrivals and expiry
# --------------------------------------------------------------------------

static func daily(day:int)->Array[Dictionary]:
	var arrivals:Array[Dictionary]=[]
	if WorldSimulation.actor_id!="player": return arrivals
	var s:=state()
	# Dread curdled with resentment shows first in speech, then in flight.
	for gone in DIVINE.daily(day,_officials()): _drop_matters_of(int(gone.get("person_id",0)))
	_expire(day)
	_observe(day)
	_prune_occasions(day)
	_prune_matters(day)
	_lives().call("daily",day)
	_aims().call("daily",day)
	_rivals().call("daily",day)
	# The court never comes on its own: its occasions become matters, held by
	# the official until the ruler summons them.
	for occasion in (s.occasions as Array).duplicate():
		if not occasion is Dictionary or not String(occasion.get("type","")) in COURT_OCCASIONS: continue
		if int(occasion.get("not_before",0))>day: continue
		(s.occasions as Array).erase(occasion)
		var petition:=_generate_court_occasion(occasion,day)
		if not petition.is_empty(): _file_matter(petition,[])
	if waiting().size()>=QUEUE_MAX or day-int(s.last_arrival_day)<MIN_GAP: return arrivals
	var ready:Array[Dictionary]=[]
	for occasion in s.occasions:
		if occasion is Dictionary and int(occasion.get("not_before",0))<=day and int(occasion.get("expires",0))>day and not String(occasion.get("type","")) in COURT_OCCASIONS: ready.append(occasion)
	ready.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
		var pa:=_occasion_priority(a); var pb:=_occasion_priority(b)
		# Fresh matters first: what happened last week outranks last season.
		return pa>pb or (pa==pb and (int(a.day)>int(b.day) or (int(a.day)==int(b.day) and String(a.key)<String(b.key)))))
	for occasion:Dictionary in ready:
		if not _budget_allows(occasion,day) or not _speaker_allows(occasion,day): continue
		(s.occasions as Array).erase(occasion)
		var audience:=_generate_for(occasion,day)
		if audience.is_empty(): continue
		_enqueue(audience,day)
		arrivals.append(audience)
		break
	return arrivals

static func _occasion_priority(occasion:Dictionary)->int:
	if bool(occasion.get("crisis",false)): return 2
	if String(occasion.get("type","")) in THREAD_OCCASIONS: return 1
	return 0

static func _has_waiting(origin:String,civ_id:String,person_id:int)->bool:
	for audience in state().queue:
		if String(audience.get("status",""))!="waiting" or String(audience.origin)!=origin: continue
		if origin=="foreign" and String(audience.civ_id)==civ_id: return true
		if origin=="court" and int(audience.speaker.get("person_id",0))==person_id: return true
	return false

static func _expire(day:int)->void:
	var s:=state()
	for audience in s.queue.duplicate():
		if String(audience.status)!="waiting" or day<int(audience.expires_day): continue
		audience.status="expired"
		if audience.kind=="wonder_proposal":
			audience.outcome="%s gave up waiting to pitch their great work; the idea is shelved." % String(audience.speaker.name)
		elif audience.kind=="great_work":
			# Works never deadlock: the council answers stage gates after its own delay.
			audience.outcome="%s could wait no longer; the matter of %s passed to the council." % [String(audience.speaker.name),String((audience.get("great_work",{}) as Dictionary).get("title","the work"))]
		elif audience.origin=="foreign":
			var id:=String(audience.civ_id)
			_shift_relation(id,-0.04,0.0)
			var leader:=ForeignDiplomacy.leader(id)
			if not leader.is_empty(): leader.trust=clampf(float(leader.trust)-0.03,-1,1)
			ForeignDiplomacy.remember(id,"Our envoy %s waited %d days in the ruler's antechamber and was never received. They came home insulted." % [String(audience.speaker.name),int(day-int(audience.arrived_day))])
			audience.outcome="%s waited %d days without an audience and has left, insulted. %s thinks less of you (opinion −0.04, trust −0.03)." % [String(audience.speaker.name),int(day-int(audience.arrived_day)),String(audience.civ_name)]
			_add_sequel(audience,"ignored",day)
		else:
			# The ruler called them in; if the ruler never saw them, no one is slighted.
			var matter:String="their report on %s" % String(audience.get("report",{}).get("subject_name","what they found")) if audience.kind=="report" else _topic_words(String(audience.petition.get("topic","")))
			audience.outcome="%s went back to their work; the matter of %s was set aside." % [String(audience.speaker.name),matter]
		_ledger_close(audience,"expired","offended" if audience.origin=="foreign" else "neutral",String(audience.outcome))
		_archive(audience)

static func _enqueue(audience:Dictionary,day:int,external:bool=false)->void:
	var s:=state()
	s.queue.append(audience)
	if String(audience.get("origin",""))=="court":
		# Called in by the ruler: no envoy budget is spent.
		var key:=_speaker_key(audience)
		if key.begins_with("person:"): s.last_person[key.trim_prefix("person:")]=day
		_ledger_add(audience)
		return
	_note_arrival(audience,day,external)

# --------------------------------------------------------------------------
# Matters: court business held until the ruler summons someone
# --------------------------------------------------------------------------

static func _matter_holder(audience:Dictionary)->Dictionary:
	## Who carries this matter: an official, the Chief Scout or an architect.
	var speaker:Dictionary=audience.get("speaker",{}) if audience.get("speaker") is Dictionary else {}
	var pid:=int(speaker.get("person_id",0)) if _num(speaker.get("person_id",0)) else 0
	var kind:=String(audience.get("kind",""))
	var figure:=""
	if kind=="great_work" and audience.get("great_work") is Dictionary: figure=String((audience.great_work as Dictionary).get("architect_id",""))
	elif kind=="wonder_proposal" and audience.get("wonder_proposal") is Dictionary: figure=String((audience.wonder_proposal as Dictionary).get("figure_id",""))
	var role:="official"
	if kind=="report": role="chief_scout"
	elif kind in WORK_KINDS and (figure!="" or pid==0): role="architect"
	var key:=""
	if figure!="": key="figure:"+figure
	elif pid>0: key="person:%d" % pid
	elif role=="chief_scout": key="role:chief_scout"
	else: key="name:"+String(speaker.get("name","")).substr(0,60)
	if String(audience.get("holder_key",""))!="": key=String(audience.holder_key)
	return {"key":key,"role":role,"person_id":pid,"figure_id":figure,"name":String(speaker.get("name","")),"title":String(speaker.get("title",""))}

static func _matter_urgency(audience:Dictionary)->float:
	var situation:=_situation(audience)
	match String(audience.get("kind","")):
		"report": return 0.6
		"wonder_proposal": return 0.4
		"great_work":
			var mode:=String((audience.great_work as Dictionary).get("mode","")) if audience.get("great_work") is Dictionary else ""
			return float({"decision":0.85,"outcome":0.8,"event":0.7,"forecast":0.7,"news":0.3}.get(mode,0.5))
	var occasion:Dictionary=situation.get("occasion",{}) if situation.get("occasion") is Dictionary else {}
	if bool(occasion.get("crisis",false)): return 0.9
	return float({"crisis_petition":0.6,"war_council":0.9,"grievance":0.5,"promise_followup":0.5,"introduction":0.3,"ambition":0.2}.get(_situation_type(audience),0.3))

static func _matter_summary(audience:Dictionary)->String:
	match String(audience.get("kind","")):
		"report":
			var report:Dictionary=audience.get("report",{}) if audience.get("report") is Dictionary else {}
			return "A report on %s." % String(report.get("subject_name","what the scouts found"))
		"great_work":
			var gw:Dictionary=audience.get("great_work",{}) if audience.get("great_work") is Dictionary else {}
			var text:=String(gw.get("text",""))
			return (text if text!="" else "%s: %s" % [String(gw.get("title","A great work")),String(gw.get("mode",""))]).substr(0,240)
		"wonder_proposal":
			var pitch:Dictionary=audience.get("wonder_proposal",{}) if audience.get("wonder_proposal") is Dictionary else {}
			var trigger:Dictionary=pitch.get("trigger",{}) if pitch.get("trigger") is Dictionary else {}
			return String(trigger.get("text","A great work they would build.")).substr(0,240)
	return _ledger_summary(audience)

static func _matter_key(audience:Dictionary,holder:Dictionary)->String:
	var ask:=_ask_key(audience)
	if String(audience.get("kind",""))=="wonder_proposal":
		var pitch:Dictionary=audience.get("wonder_proposal",{}) if audience.get("wonder_proposal") is Dictionary else {}
		var trigger:Dictionary=pitch.get("trigger",{}) if pitch.get("trigger") is Dictionary else {}
		ask="wonder:"+String(trigger.get("kind",""))
	return (String(holder.key)+"|"+ask).substr(0,200)

static func _file_matter(audience:Dictionary,lines:Array)->Dictionary:
	## Keep court business as a dated matter on its holder. A newer matter with
	## the same key refreshes the old one; the least pressing go quietly.
	var s:=state()
	var day:=_day()
	var holder:=_matter_holder(audience)
	var key:=_matter_key(audience,holder)
	var expires:=day+MATTER_DAYS
	if String(audience.get("kind",""))=="great_work" and _num(audience.get("expires_day",null)) and int(audience.expires_day)>day: expires=int(audience.expires_day)
	var list:Array=s.matters
	var entry:Dictionary={}
	for existing in list:
		if existing is Dictionary and String(existing.get("key",""))==key: entry=existing; break
	var clean_lines:Array=[]
	for line in lines:
		if line is Dictionary and clean_lines.size()<12: clean_lines.append((line as Dictionary).duplicate())
	var stored:=audience.duplicate(true)
	stored["lines"]=[]
	if entry.is_empty():
		s.serial=int(s.serial)+1
		entry={"id":"matter_%d" % int(s.serial),"key":key}
		list.append(entry)
	entry.merge({"holder":holder,"holder_key":String(holder.key),"kind":String(audience.get("kind","")),"situation_type":_situation_type(audience),
		"summary":_matter_summary(audience),"day":day,"expires":expires,"urgency":_matter_urgency(audience),"audience":stored,"lines":clean_lines},true)
	if int(holder.person_id)>0: s.last_person[str(int(holder.person_id))]=day
	# Bounds: a few per holder, a few dozen in all.
	var mine:Array=list.filter(func(m:Variant)->bool:return m is Dictionary and String(m.get("holder_key",""))==String(holder.key))
	while mine.size()>MATTERS_PER_HOLDER:
		var drop:=_least_pressing(mine)
		mine.erase(drop); list.erase(drop)
	while list.size()>MATTERS_MAX:
		list.erase(_least_pressing(list))
	return entry

static func _least_pressing(list:Array)->Dictionary:
	var worst:Dictionary={}
	for m in list:
		if not m is Dictionary: continue
		if worst.is_empty() or float(m.get("urgency",0))<float(worst.get("urgency",0)) or (float(m.get("urgency",0))==float(worst.get("urgency",0)) and int(m.get("day",0))<int(worst.get("day",0))): worst=m
	return worst

static func _prune_matters(day:int)->void:
	## Matters lapse quietly: no one is slighted by what the ruler never heard.
	var list:Array=state().matters
	var gwa:=_great_works()
	for m in list.duplicate():
		if not m is Dictionary or int(m.get("expires",0))<=day: list.erase(m); continue
		var audience:Dictionary=m.get("audience",{}) if m.get("audience") is Dictionary else {}
		if String(audience.get("kind",""))=="great_work" and gwa!=null and bool(gwa.call("stale",audience)): list.erase(m)
		elif String(audience.get("kind",""))=="petition" and _official(int((m.get("holder",{}) as Dictionary).get("person_id",0))).is_empty(): list.erase(m)

static func matters(holder_key:String="")->Array[Dictionary]:
	## Pending matters, most pressing first. Pass a holder key ("person:<id>",
	## "figure:<id>", "role:chief_scout") to see one person's.
	var result:Array[Dictionary]=[]
	for m in state().matters:
		if m is Dictionary and (holder_key=="" or String(m.get("holder_key",""))==holder_key): result.append(m)
	result.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return float(a.urgency)>float(b.urgency) or (float(a.urgency)==float(b.urgency) and int(a.day)>int(b.day)))
	return result

static func matter_counts()->Dictionary:
	## holder_key -> number of pending matters (for small counts in the UI).
	var counts:Dictionary={}
	for m in state().matters:
		if m is Dictionary: counts[String(m.get("holder_key",""))]=int(counts.get(String(m.get("holder_key","")),0))+1
	return counts

static func open_matter(matter_id:String)->Dictionary:
	## The ruler takes up a matter: its holder is called into the hall now.
	var s:=state()
	for m in (s.matters as Array).duplicate():
		if not m is Dictionary or String(m.get("id",""))!=matter_id: continue
		(s.matters as Array).erase(m)
		var stored:Dictionary=(m.get("audience",{}) as Dictionary).duplicate(true)
		var gwa:=_great_works()
		if String(stored.get("kind",""))=="great_work" and gwa!=null and bool(gwa.call("stale",stored)): return {}
		var day:=_day()
		s.serial=int(s.serial)+1
		stored["id"]="aud_%d" % int(s.serial)
		stored["arrived_day"]=day
		stored["expires_day"]=maxi(int(stored.get("expires_day",0)),day+EXPIRY_DAYS)
		stored["status"]="waiting"; stored["lines"]=[]; stored["mood"]=0.0; stored["outcome"]=""; stored["option_id"]=""
		stored["summoned"]=true
		stored["holder_key"]=String(m.get("holder_key",""))
		if not _valid_audience(stored): return {}
		_enqueue(stored,day)
		# A debrief keeps to its first few lines: the ruler can ask for the rest.
		var prefilled:Array=m.get("lines",[])
		for index in mini(prefilled.size(),4):
			if prefilled[index] is Dictionary: append_line(String(stored.id),prefilled[index])
		_lives().call("on_open",stored)
		_aims().call("on_open",stored)
		return stored
	return {}


# --------------------------------------------------------------------------
# Summons: the ruler calls someone into the hall
# --------------------------------------------------------------------------

static func summon_keys(target:Dictionary)->Array[String]:
	## Holder keys whose matters this person carries. target: {person_id} for an
	## official, {figure_id} for an architect, {role:"chief_scout"} for the scouts.
	var keys:Array[String]=[]
	var pid:=int(target.get("person_id",0)) if _num(target.get("person_id",0)) else 0
	var figure:=String(target.get("figure_id",""))
	var chief:Dictionary=GovernmentPeopleSystem.officeholder("ChiefScout")
	if String(target.get("role",""))=="chief_scout":
		if not chief.is_empty(): keys.append("person:%d" % int(chief.person_id))
		keys.append("role:chief_scout")
	if pid>0 and not "person:%d" % pid in keys:
		keys.append("person:%d" % pid)
		if not chief.is_empty() and int(chief.person_id)==pid: keys.append("role:chief_scout")
	if figure!="": keys.append("figure:"+figure)
	var direct:=String(target.get("holder_key",""))
	if direct!="" and not direct in keys: keys.append(direct)
	return keys

static func summonable()->Array[Dictionary]:
	## Everyone the ruler may call in, with how many matters each holds:
	## officials, the Chief Scout (or the scouts when the office is vacant) and
	## architects who hold matters.
	var counts:=matter_counts()
	var result:Array[Dictionary]=[]
	var chief:Dictionary=GovernmentPeopleSystem.officeholder("ChiefScout")
	for person in _officials():
		var target:={"person_id":int(person.person_id)}
		var held:=0
		for key in summon_keys(target): held+=int(counts.get(key,0))
		result.append({"target":target,"name":String(person.name),"title":String(person.get("office_title","Official")),"role":"chief_scout" if not chief.is_empty() and int(chief.person_id)==int(person.person_id) else "official","matters":held})
	if chief.is_empty() and int(counts.get("role:chief_scout",0))>0:
		result.append({"target":{"role":"chief_scout"},"name":"The returning scouts","title":"Scouts","role":"chief_scout","matters":int(counts.get("role:chief_scout",0))})
	var seen:Dictionary={}
	for m in matters():
		var holder:Dictionary=m.get("holder",{})
		if String(holder.get("role",""))!="architect": continue
		var key:=String(m.get("holder_key",""))
		if seen.has(key) or key.begins_with("person:"): continue
		seen[key]=true
		var figure:=String(holder.get("figure_id",""))
		var target:Dictionary={"figure_id":figure,"name":String(holder.get("name",""))} if figure!="" else {"holder_key":key,"name":String(holder.get("name",""))}
		result.append({"target":target,"name":String(holder.get("name","A master builder")),"title":String(holder.get("title","Master builder")),"role":"architect","matters":int(counts.get(key,0))})
	return result

static func summon(target:Dictionary)->Dictionary:
	## Call someone into the hall now. They open with their most pressing
	## matter; with nothing to raise they simply answer the summons.
	var keys:=summon_keys(target)
	if keys.is_empty(): return {}
	for audience in waiting():
		if String(audience.get("origin",""))=="court" and String(_matter_holder(audience).key) in keys: return audience
	var pending:Array[Dictionary]=[]
	for key in keys: pending.append_array(matters(key))
	pending.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return float(a.urgency)>float(b.urgency) or (float(a.urgency)==float(b.urgency) and int(a.day)>int(b.day)))
	for m in pending:
		var opened:=open_matter(String(m.id))
		if not opened.is_empty(): return opened
	var speaker:=_summoned_speaker(target)
	if speaker.is_empty(): return {}
	var day:=_day()
	var audience:=_new_audience("court","summons",day)
	audience.speaker=speaker
	var name:=String(speaker.name)
	audience.petition={"topic":"summons","summary":"%s answers your summons with nothing of their own to raise." % name,"suggested_decree":""}
	audience.situation={"type":"summons","ask":"summons:%d" % day,"headline":"answers your summons","summary":"%s answers your summons." % name,"occasion":{"type":"summons","text":"the ruler sent for them","day":day,"crisis":false}}
	audience["summoned"]=true
	audience["holder_key"]=keys[0]
	if not _valid_audience(audience): return {}
	_enqueue(audience,day)
	return audience

static func _summoned_speaker(target:Dictionary)->Dictionary:
	var pid:=int(target.get("person_id",0)) if _num(target.get("person_id",0)) else 0
	if String(target.get("role",""))=="chief_scout" and pid==0:
		var chief:Dictionary=GovernmentPeopleSystem.officeholder("ChiefScout")
		if not chief.is_empty(): pid=int(chief.person_id)
		else: return {"name":"Your lead scout","title":"Lead Scout","person_id":0,"role":"official"}
	if pid>0:
		var person:=_official(pid)
		if person.is_empty(): person=GovernmentPeopleSystem.person_snapshot(pid)
		if person.is_empty(): return {}
		return {"name":String(person.get("name","")).substr(0,100),"title":String(person.get("office_title",person.get("title","Official"))).substr(0,100),"person_id":pid,"role":"official"}
	var figure:=String(target.get("figure_id",""))
	if figure=="" and String(target.get("name",""))!="":
		return {"name":String(target.name).substr(0,100),"title":"Master builder","person_id":0,"role":"official"}
	if figure!="":
		var found:Dictionary=HistoricalFigures.by_id(figure)
		var name:=String(found.get("name",target.get("name","The master builder")))
		var figure_role:=String(found.get("role","Architect"))
		# War leaders answer the court by their calling, not as builders.
		var figure_title:="War leader" if figure_role=="General" else "%s, master builder" % figure_role.capitalize()
		return {"name":name.substr(0,100),"title":figure_title,"person_id":0,"role":"official"}
	return {}

static func _other_matters(audience:Dictionary)->Array[Dictionary]:
	## What else the summoned person could raise (at most two).
	var result:Array[Dictionary]=[]
	if not bool(audience.get("summoned",false)): return result
	var holder:=String(_matter_holder(audience).key)
	var keys:Array[String]=[holder]
	var speaker:Dictionary=audience.get("speaker",{}) if audience.get("speaker") is Dictionary else {}
	if int(speaker.get("person_id",0))>0: keys=summon_keys({"person_id":int(speaker.person_id)})
	for key in keys:
		for m in matters(key):
			if result.size()<2: result.append(m)
	return result

static func is_directive(text:String)->bool:
	## True when the ruler's words to a summoned official are an order the civic
	## council can carry out (an imperative verb and a recognised policy).
	var clean:=text.strip_edges().to_lower()
	for lead in ["i order that ","i order ","i command that ","i command ","i want you to ","you will ","we will ","let us ","please "]:
		if clean.begins_with(lead): clean=clean.trim_prefix(lead)
	if clean.is_empty() or clean.ends_with("?"): return false
	var first:=String(clean.split(" ",false)[0]).trim_suffix(",").trim_suffix(".")
	if not first in PronouncementInterpreter.DIRECTIVE_VERBS: return false
	for policy in PronouncementInterpreter.POLICY_TERMS:
		if PronouncementInterpreter._policy_has_term_in_text(String(policy),clean): return true
	return false

static func _migrate_court(s:Dictionary)->void:
	## Version 3: the court no longer comes uninvited. Waiting court audiences
	## step out of the antechamber and become matters on their holders.
	s["version"]=3
	for audience in (s.queue as Array).duplicate():
		if not audience is Dictionary or String(audience.get("status",""))!="waiting" or String(audience.get("origin",""))!="court": continue
		(s.queue as Array).erase(audience)
		var lines:Array=(audience.get("lines",[]) as Array).duplicate() if audience.get("lines") is Array else []
		_file_matter(audience,lines if String(audience.get("kind",""))=="report" else [])

static func _note_arrival(audience:Dictionary,day:int,external:bool)->void:
	## Every arrival spends budget: the next routine audience waits about one
	## average gap (half for matters raised elsewhere: reports, great works).
	var s:=state()
	s.last_arrival_day=day
	var gap:=float(_gap())
	var rng:=_rng("budget:%d" % int(s.serial),day)
	var next:=day+(roundi(gap*0.5) if external else roundi(gap*rng.randf_range(0.75,1.3)))
	s.next_any=maxi(int(s.next_any),next)
	var key:=_speaker_key(audience)
	s.last_speaker=key
	if key.begins_with("civ:"): s.last_civ[key.trim_prefix("civ:")]=day
	elif key.begins_with("person:"): s.last_person[key.trim_prefix("person:")]=day
	_ledger_add(audience)

static func _archive(audience:Dictionary)->void:
	var s:=state()
	s.queue.erase(audience)
	s.history.push_front(audience)
	if s.history.size()>HISTORY_MAX: s.history.resize(HISTORY_MAX)

static func _new_audience(origin:String,kind:String,day:int)->Dictionary:
	var s:=state()
	s.serial=int(s.serial)+1
	return {"id":"aud_%d" % int(s.serial),"origin":origin,"kind":kind,"civ_id":"","civ_name":"",
		"speaker":{"name":"","title":"","person_id":0,"role":"envoy" if origin=="foreign" else "official"},
		"arrived_day":day,"expires_day":day+EXPIRY_DAYS,"status":"waiting","terms":{},"news":{},"petition":{},"report":{},
		"situation":{},"lines":[],"outcome":"","option_id":"","mood":0.0}

# --------------------------------------------------------------------------
# Ledger: every (speaker, ask) and how it ended
# --------------------------------------------------------------------------

static func _speaker_key(audience:Dictionary)->String:
	if String(audience.get("origin",""))=="foreign" and String(audience.get("civ_id",""))!="": return "civ:"+String(audience.civ_id)
	var speaker:Dictionary=audience.get("speaker",{}) if audience.get("speaker") is Dictionary else {}
	var pid:=int(speaker.get("person_id",0)) if _num(speaker.get("person_id",0)) else 0
	if pid>0: return "person:%d" % pid
	return "name:"+String(speaker.get("name","")).substr(0,60)

static func _ask_key(audience:Dictionary)->String:
	var situation:Dictionary=audience.get("situation",{}) if audience.get("situation") is Dictionary else {}
	if String(situation.get("ask",""))!="": return String(situation.ask)
	var terms:Dictionary=audience.get("terms",{}) if audience.get("terms") is Dictionary else {}
	match String(audience.get("kind","")):
		"gift": return "gift:"+String(terms.get("resource",""))
		"request": return "request:"+String(terms.get("resource",""))
		"threat": return "tribute:"+String(terms.get("resource",""))
		"news":
			var news:Dictionary=audience.get("news",{}) if audience.get("news") is Dictionary else {}
			return "news:%s:%s" % [String(news.get("subject_civ_id","")),String(news.get("fact_kind",""))]
		"petition":
			var petition:Dictionary=audience.get("petition",{}) if audience.get("petition") is Dictionary else {}
			return "%s:%s" % [String(petition.get("topic","")),String(petition.get("suggested_decree",""))]
		"report": return "report:"+String((audience.get("report",{}) as Dictionary).get("subject_name","")) if audience.get("report") is Dictionary else "report"
		"great_work":
			var gw:Dictionary=audience.get("great_work",{}) if audience.get("great_work") is Dictionary else {}
			return "work:%s:%s:%s" % [String(gw.get("mode","")),String(gw.get("work_id","")),String(gw.get("key",""))]
		"wonder_proposal": return "wonder:%d" % int(audience.get("arrived_day",0))
	return String(audience.get("kind",""))

static func _situation_type(audience:Dictionary)->String:
	var situation:Dictionary=audience.get("situation",{}) if audience.get("situation") is Dictionary else {}
	if String(situation.get("type",""))!="": return String(situation.type)
	match String(audience.get("kind","")):
		"gift": return "gift_goods"
		"request": return "aid_request"
		"threat": return "tribute_demand"
		"news": return "news_report"
		"petition":
			var topic:=String((audience.get("petition",{}) as Dictionary).get("topic","")) if audience.get("petition") is Dictionary else ""
			if topic in ["food","health","housing","security","people"]: return "crisis_petition"
			return "grievance" if topic=="grievance" else "ambition"
	return String(audience.get("kind",""))

static func _ledger_add(audience:Dictionary)->void:
	var s:=state()
	var ledger:Array=s.ledger
	for entry in ledger:
		if entry is Dictionary and String(entry.get("audience_id",""))==String(audience.get("id","")): return
	var speaker:Dictionary=audience.get("speaker",{}) if audience.get("speaker") is Dictionary else {}
	ledger.push_back({"day":int(audience.get("arrived_day",_day())),"audience_id":String(audience.get("id","")),"speaker":_speaker_key(audience),
		"civ_id":String(audience.get("civ_id","")),"person_id":int(speaker.get("person_id",0)) if _num(speaker.get("person_id",0)) else 0,
		"kind":String(audience.get("kind","")),"situation":_situation_type(audience),"ask":_ask_key(audience),
		"option":"","reaction":"","outcome":"","summary":_ledger_summary(audience)})
	while ledger.size()>LEDGER_MAX: ledger.pop_front()

static func _ledger_summary(audience:Dictionary)->String:
	var situation:Dictionary=audience.get("situation",{}) if audience.get("situation") is Dictionary else {}
	if String(situation.get("summary",""))!="": return String(situation.summary).substr(0,240)
	var terms:Dictionary=audience.get("terms",{}) if audience.get("terms") is Dictionary else {}
	if not terms.is_empty(): return ("%s %s" % [String(audience.get("kind","")),_terms_text(terms)]).substr(0,240)
	if audience.get("petition") is Dictionary and String((audience.petition as Dictionary).get("summary",""))!="": return String(audience.petition.summary).substr(0,240)
	if audience.get("news") is Dictionary and String((audience.news as Dictionary).get("fact",""))!="": return String(audience.news.fact).substr(0,240)
	return String(audience.get("kind",""))

static func _ledger_close(audience:Dictionary,option_id:String,reaction:String,outcome:String)->void:
	var ledger:Array=state().ledger
	for index in range(ledger.size()-1,-1,-1):
		var entry:Variant=ledger[index]
		if entry is Dictionary and String(entry.get("audience_id",""))==String(audience.get("id","")):
			entry["option"]=option_id; entry["reaction"]=reaction; entry["outcome"]=outcome.substr(0,300)
			entry["closed_day"]=_day()
			return

static func _used_asks(speaker:String,day:int)->Dictionary:
	var used:Dictionary={}
	for entry in state().ledger:
		if entry is Dictionary and String(entry.get("speaker",""))==speaker and day-int(entry.get("day",-99999))<REPEAT_DAYS: used[String(entry.get("ask",""))]=true
	return used

static func history_with(speaker:String,limit:int=3,exclude_id:String="")->Array[Dictionary]:
	## Last outcomes with a speaker ("civ:<id>" or "person:<id>"), newest first.
	var result:Array[Dictionary]=[]
	var ledger:Array=state().ledger
	var today:=_day()
	for index in range(ledger.size()-1,-1,-1):
		var entry:Variant=ledger[index]
		if not entry is Dictionary or String(entry.get("speaker",""))!=speaker or String(entry.get("audience_id",""))==exclude_id: continue
		if String(entry.get("option",""))=="" or String(entry.get("option","")) in ["set_aside","withdrawn"]: continue
		result.append({"day":int(entry.day),"days_ago":today-int(entry.day),"situation":String(entry.get("situation","")),"kind":String(entry.get("kind","")),
			"ask":String(entry.get("ask","")),"summary":String(entry.get("summary","")),"answer":String(entry.get("option","")),"reaction":String(entry.get("reaction","")),"outcome":String(entry.get("outcome",""))})
		if result.size()>=limit: break
	return result

static func ledger()->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	for entry in state().ledger:
		if entry is Dictionary: result.append((entry as Dictionary).duplicate())
	return result

# --------------------------------------------------------------------------
# Watch: notice what changed and file occasions
# --------------------------------------------------------------------------

static func _add_occasion(occasion:Dictionary)->void:
	var s:=state()
	var list:Array=s.occasions
	for existing in list:
		if existing is Dictionary and String(existing.get("key",""))==String(occasion.key): return
	var day:=_day()
	var clean:={"key":String(occasion.key).substr(0,120),"type":String(occasion.type),"civ_id":String(occasion.get("civ_id","")),"person_id":int(occasion.get("person_id",0)),
		"day":int(occasion.get("day",day)),"not_before":int(occasion.get("not_before",day)),"expires":int(occasion.get("expires",day+120)),
		"crisis":bool(occasion.get("crisis",false)),"data":(occasion.get("data",{}) as Dictionary).duplicate(true) if occasion.get("data") is Dictionary else {}}
	list.append(clean)
	while list.size()>OCCASIONS_MAX:
		var drop:=0
		for index in list.size():
			if not bool(list[index].get("crisis",false)): drop=index; break
		list.remove_at(drop)

static func _prune_occasions(day:int)->void:
	var list:Array=state().occasions
	for occasion in list.duplicate():
		if not occasion is Dictionary or int(occasion.get("expires",0))<=day: list.erase(occasion)

static func occasions()->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	for occasion in state().occasions:
		if occasion is Dictionary: result.append((occasion as Dictionary).duplicate(true))
	return result

static func _tension_band(value:float)->int:
	return 2 if value>=0.7 else (1 if value>=0.45 else 0)

static func _third_wars(civ:Dictionary)->Array:
	var result:Array=[]
	var relations:Dictionary=civ.get("relations",{}) if civ.get("relations") is Dictionary else {}
	for other_id in relations:
		var relation:Variant=relations[other_id]
		if relation is Dictionary and bool(relation.get("at_war",false)) and String(other_id)!="player": result.append(String(other_id))
	result.sort()
	return result

static func _peace_ok(civ_id:String,relation:Dictionary)->bool:
	if not bool(relation.get("at_war",false)): return false
	var forecast:Dictionary=CivilizationSystem.peace_forecast(civ_id)
	return bool(forecast.get("can_accept",false))

static func _observe(day:int)->void:
	var s:=state()
	var watch:Dictionary=s.watch
	var baseline:=not bool(watch.get("ready",false))
	if not watch.get("civs") is Dictionary: watch["civs"]={}
	if not watch.get("people") is Dictionary: watch["people"]={}
	if not watch.get("conditions") is Dictionary: watch["conditions"]={}
	var civs:Dictionary=watch.civs
	for civ in WorldSimulation.world.civilizations:
		if not civ is Dictionary: continue
		var id:=String(civ.get("id",""))
		if id=="": continue
		var relation:Dictionary=civ.get("player_relation",{}) if civ.get("player_relation") is Dictionary else {}
		var contacted:=int(relation.get("contact_level",0))>=2 and bool(civ.get("alive",true))
		var prev:Dictionary=civs.get(id,{}) if civs.get(id) is Dictionary else {}
		var opinion:=float(relation.get("opinion",0.0))
		var now:={"c":contacted,"o":float(prev.get("o",opinion)),"t":_tension_band(float(relation.get("border_tension",0.0))),"w":bool(relation.get("at_war",false)),
			"h":_hungry(civ),"r":int(relation.get("last_recruitment_day",-1)),"p":_peace_ok(id,relation) if contacted else false,"x":_third_wars(civ)}
		if not contacted:
			now.o=opinion
			civs[id]=now
			continue
		var name:=String(civ.get("name",id))
		if baseline or prev.is_empty() or not bool(prev.get("c",false)):
			now.o=opinion
			civs[id]=now
			if not baseline or not _speaker_in_ledger("civ:"+id):
				_add_occasion({"key":"first_contact:"+id,"type":"first_contact","civ_id":id,"day":day,"not_before":day+(5 if not baseline else 0),"expires":day+(150 if not baseline else 240),"data":{"text":"first contact between %s and your people" % name}})
			continue
		# Opinion swings are measured from an anchor that moves only when a
		# swing is noticed or an audience with them ends.
		if absf(opinion-float(prev.get("o",opinion)))>=0.2:
			var warmer:=opinion>float(prev.o)
			_add_occasion({"key":"swing:%s:%d" % [id,day],"type":"relation_warm" if warmer else "relation_cool","civ_id":id,"day":day,"expires":day+120,
				"data":{"text":"%s has grown %s toward your people" % [name,"warmer" if warmer else "colder"]}})
			now.o=opinion
		if int(now.t)>int(prev.get("t",0)) and not bool(now.w):
			_add_occasion({"key":"tension:%s:%d" % [id,day],"type":"tension_rise","civ_id":id,"day":day,"expires":day+90,"crisis":int(now.t)>=2,
				"data":{"text":"the frontier with %s has grown %s" % [name,"dangerous" if int(now.t)>=2 else "tense"]}})
		if bool(now.w) and not bool(prev.get("w",false)):
			_add_occasion({"key":"war_council:%s:%d" % [id,day],"type":"war_council","civ_id":id,"person_id":int(_relevant_official(["Marshal"]).get("person_id",0)),"day":day,"expires":day+45,"crisis":true,
				"data":{"text":"war with %s has begun" % name,"enemy_name":name,"war_day":int(relation.get("war_started_day",day))}})
		if not bool(now.w) and bool(prev.get("w",false)):
			_add_occasion({"key":"war_end:%s:%d" % [id,day],"type":"war_end","civ_id":id,"day":day,"not_before":day+10,"expires":day+160,"data":{"text":"the war with %s has ended" % name}})
		if bool(now.p) and not bool(prev.get("p",false)):
			_add_occasion({"key":"peace:%s:%d" % [id,day],"type":"peace_possible","civ_id":id,"day":day,"expires":day+60,"crisis":true,"data":{"text":"%s has lost its appetite for the war" % name}})
		if bool(now.h) and not bool(prev.get("h",false)) and not bool(now.w):
			_add_occasion({"key":"famine:%s:%d" % [id,day],"type":"their_famine","civ_id":id,"day":day,"expires":day+60,"crisis":true,"data":{"text":"%s's granaries are failing" % name,"episode":day}})
		if int(now.r)>int(prev.get("r",-1)) and int(now.r)>=0:
			_add_occasion({"key":"recruit:%s:%d" % [id,int(now.r)],"type":"recruitment_incident","civ_id":id,"day":day,"expires":day+90,"crisis":true,
				"data":{"text":"your recruiters invited %s's households away" % name,"incident_day":int(now.r)}})
		for enemy in now.x:
			if String(enemy) in (prev.get("x",[]) as Array): continue
			var pair:Array=[id,String(enemy)]; pair.sort()
			var enemy_index:=_civ_index(String(enemy))
			var enemy_name:=String(WorldSimulation.world.civilizations[enemy_index].get("name",enemy)) if enemy_index>=0 else String(enemy)
			_add_occasion({"key":"third_war:%s:%s:%d" % [String(pair[0]),String(pair[1]),floori(day/365.0)],"type":"third_war","civ_id":id,"day":day,"expires":day+100,
				"data":{"text":"war has broken out between %s and %s" % [name,enemy_name],"enemy":String(enemy),"enemy_name":enemy_name}})
		civs[id]=now
	_observe_court(day,baseline)
	watch["ready"]=true
	if baseline: s.next_any=maxi(int(s.next_any),day+10)
	_ambient(day)

static func _speaker_in_ledger(speaker:String)->bool:
	for entry in state().ledger:
		if entry is Dictionary and String(entry.get("speaker",""))==speaker: return true
	return false

static func _condition_bands(c:Dictionary)->Dictionary:
	var food:=2 if float(c.food_days)<10.0 or float(c.food_intake)<0.85 else (1 if float(c.food_days)<22.0 or float(c.food_intake)<0.97 else 0)
	var health:=2 if float(c.health)<0.45 or float(c.water_intake)<0.8 else (1 if float(c.health)<0.62 or float(c.water_intake)<0.95 else 0)
	var housing:=2 if float(c.housing_ratio)<0.8 else (1 if float(c.housing_ratio)<1.0 else 0)
	var security:=2 if float(c.foreign_threat)>=0.75 else (1 if float(c.security)<0.36 or float(c.foreign_threat)>0.45 else 0)
	# fun-pop: the people have been fewer at the end of each of the last winters
	# (hearth_count.gd). Two winters running, or a tenth lost, and it is a crisis.
	var people:=0
	var decline_years:=int(c.get("decline_years",0))
	if decline_years>=1:
		people=2 if float(c.get("decline_loss",0.0))>=0.10 or decline_years>=4 else (1 if decline_years>=2 or float(c.get("decline_loss",0.0))>=0.03 else 0)
	return {"food":food,"health":health,"housing":housing,"security":security,"people":people}

const TOPIC_OFFICES:={"food":["Steward","Quartermaster"],"health":["Steward","Scholar"],"housing":["Steward","Quartermaster"],"security":["Marshal"],"people":["Steward","Scholar"]}

static func _observe_court(day:int,baseline:bool)->void:
	var watch:Dictionary=state().watch
	var bands:=_condition_bands(conditions())
	var stored:Dictionary=watch.conditions
	for topic:String in bands:
		var band:=int(bands[topic])
		var before:=int(stored.get(topic,0))
		if band>before and (not baseline or band>=2):
			var person:=_relevant_official(TOPIC_OFFICES[topic])
			if not person.is_empty():
				_add_occasion({"key":"condition:%s:%d:%d" % [topic,band,day],"type":"condition","person_id":int(person.person_id),"day":day,"expires":day+(45 if band>=2 else 90),"crisis":band>=2,
					"data":{"topic":topic,"band":band,"text":"%s %s" % [_topic_words(topic),"has become an emergency" if band>=2 else "has begun to worry the court"]}})
		stored[topic]=band
	var people:Dictionary=watch.people
	var present:Dictionary={}
	for person in _officials():
		var key:=str(int(person.person_id))
		present[key]=true
		# A newly seen official has only just arrived; their own plans come later.
		if not (state().last_person as Dictionary).has(key): state().last_person[key]=day
		var rel:Dictionary=person.get("relationships",{}).get("sovereign",{})
		var resentment:=float(rel.get("resentment",0))
		var trust:=float(rel.get("trust",0.5))
		var band:=2 if resentment>=0.3 or trust<0.2 else (1 if resentment>0.15 or trust<0.35 else 0)
		var prev:Dictionary=people.get(key,{}) if people.get(key) is Dictionary else {}
		if not baseline and prev.is_empty() and day>1:
			_add_occasion({"key":"appointment:%s" % key,"type":"appointment","person_id":int(person.person_id),"day":day,"not_before":day+7,"expires":day+120,
				"data":{"text":"%s has newly taken up office as %s" % [String(person.name),String(person.get("office_title","an official"))]}})
		if band>int(prev.get("g",0 if not baseline else band)):
			_add_occasion({"key":"grievance:%s:%d:%d" % [key,band,day],"type":"grievance","person_id":int(person.person_id),"day":day,"expires":day+120,"crisis":band>=2,
				"data":{"band":band,"text":"%s's resentment has grown" % String(person.name)}})
		people[key]={"g":band}
		# A quiet official turns over a plan of their own; it waits as a matter.
		if not baseline and day-int((state().last_person as Dictionary).get(key,-99999))>=PERSON_GAP and matters("person:"+key).is_empty() and _next_ambition(person,day)!="":
			_add_occasion({"key":"ambition:%s:%d" % [key,day],"type":"ambition","person_id":int(person.person_id),"day":day,"expires":day+45,"data":{"text":"a plan they have been turning over"}})
	for key in people.keys():
		if not present.has(String(key)): people.erase(key)

static func _ambient(day:int)->void:
	## When nothing has happened for a long while, a people not heard from in
	## half a year sends an envoy. Still subject to the budget. (The court never
	## comes uninvited; see _observe_court for officials' own plans.)
	var s:=state()
	var gap:=_gap()
	if day-int(s.last_arrival_day)<roundi(float(gap)*1.2) or day<int(s.next_any): return
	for occasion in s.occasions:
		if occasion is Dictionary and int(occasion.get("not_before",0))<=day and _speaker_allows(occasion,day): return
	var pool:Array[Dictionary]=[]
	for civ in WorldSimulation.world.civilizations:
		var id:=String(civ.get("id",""))
		if ForeignDiplomacy.civilization(id).is_empty() or bool(civ.player_relation.get("at_war",false)): continue
		var silent:=day-int((s.last_civ as Dictionary).get(id,-99999))
		if silent>=CIV_GAP and "civ:"+id!=String(s.last_speaker): pool.append({"w":minf(3.0,float(silent)/365.0+0.5),"civ_id":id})
	if pool.is_empty(): return
	var rng:=_rng("ambient",day)
	var total:=0.0
	for entry in pool: total+=float(entry.w)
	var roll:=rng.randf()*total
	var pick:Dictionary=pool[-1]
	for entry in pool:
		roll-=float(entry.w)
		if roll<=0.0: pick=entry; break
	if pick.has("civ_id"):
		_add_occasion({"key":"ambient:%d" % day,"type":"ambient","civ_id":String(pick.civ_id),"day":day,"expires":day+45,"data":{"text":"a long silence between your peoples"}})
	else:
		_add_occasion({"key":"ambition:%d" % day,"type":"ambition","person_id":int(pick.person_id),"day":day,"expires":day+45,"data":{"text":"a plan they have been turning over"}})

static func _add_sequel(audience:Dictionary,option_id:String,day:int)->void:
	## The next envoy from this people remembers how this audience ended.
	if String(audience.get("origin",""))!="foreign" or String(audience.get("civ_id",""))=="": return
	var civ_id:=String(audience.civ_id)
	var list:Array=state().occasions
	for existing in list.duplicate():
		if existing is Dictionary and String(existing.get("type",""))=="sequel" and String(existing.get("civ_id",""))==civ_id: list.erase(existing)
	var rng:=_rng("sequel:"+civ_id,day)
	var start:=day+CIV_GAP+rng.randi_range(0,90)
	var terms:Dictionary=audience.get("terms",{}) if audience.get("terms") is Dictionary else {}
	_add_occasion({"key":"sequel:%s:%d" % [civ_id,day],"type":"sequel","civ_id":civ_id,"day":day,"not_before":start,"expires":start+240,
		"data":{"text":"what came of the last audience","previous":{"day":int(audience.get("arrived_day",day)),"situation":_situation_type(audience),"kind":String(audience.get("kind","")),
			"option":option_id,"ask":_ask_key(audience),"resource":String(terms.get("resource","")),"amount":float(terms.get("amount",0.0)),"outcome":String(audience.get("outcome","")).substr(0,240)}}})

# --------------------------------------------------------------------------
# Stores (always read the real ledgers)
# --------------------------------------------------------------------------

static func player_stock(resource:String)->float:
	return float(WorldSimulation.scoped("player",func()->float:
		return WorldSimulation.food.total_stored() if resource=="Food" else maxf(0.0,float(WorldSimulation.state.resource_stockpiles.get(resource,0.0)))))

static func foreign_stock(civ_id:String,resource:String)->float:
	## -1 when the polity has no simulated ledger (it cannot hand over goods).
	if SOCIETY.owner_state(civ_id)==null or not WorldSimulation.actors.has(SOCIETY.owner_id(civ_id)): return -1.0
	return float(WorldSimulation.scoped(SOCIETY.owner_id(civ_id),func()->float:
		return WorldSimulation.food.total_stored() if resource=="Food" else maxf(0.0,float(WorldSimulation.state.resource_stockpiles.get(resource,0.0)))))

static func _player_population()->float:
	return maxf(1.0,float(GameState.population_exact))

static func _nice(amount:float)->float:
	if amount>=60: return float(roundi(amount/10.0)*10)
	if amount>=20: return float(roundi(amount/5.0)*5)
	return float(maxi(1,roundi(amount)))

static func _debit_player(resource:String,amount:float)->float:
	return EXCHANGE.take("player",resource,amount)

static func _credit_civ(civ_id:String,resource:String,amount:float)->void:
	var index:=_civ_index(civ_id)
	if SOCIETY.owner_state(civ_id)!=null and WorldSimulation.actors.has(SOCIETY.owner_id(civ_id)):
		EXCHANGE.receive(civ_id,resource,amount)
	elif resource=="Food" and index>=0:
		var civ:Dictionary=WorldSimulation.world.civilizations[index]
		civ["food_days"]=clampf(float(civ.get("food_days",0.0))+amount/maxf(1.0,float(civ.get("population",1.0))),0.0,180.0)
	if index>=0:
		var target:Dictionary=WorldSimulation.world.civilizations[index]
		target["gift_value_received"]=maxf(0.0,float(target.get("gift_value_received",0.0)))+amount

# --------------------------------------------------------------------------
# Relations
# --------------------------------------------------------------------------

static func _civ_index(civ_id:String)->int:
	for index in WorldSimulation.world.civilizations.size():
		if String(WorldSimulation.world.civilizations[index].get("id",""))==civ_id: return index
	return -1

static func _civ_name(civ_id:String)->String:
	var index:=_civ_index(civ_id)
	return String(WorldSimulation.world.civilizations[index].get("name",civ_id)) if index>=0 else civ_id

static func _shift_relation(civ_id:String,opinion:float,tension:float,extra:Dictionary={})->void:
	var index:=_civ_index(civ_id)
	if index<0: return
	var civ:Dictionary=WorldSimulation.world.civilizations[index]
	var relation:Dictionary=civ.get("player_relation",{})
	relation["opinion"]=clampf(float(relation.get("opinion",0.0))+opinion,-1.0,1.0)
	relation["border_tension"]=clampf(float(relation.get("border_tension",0.0))+tension,0.0,1.0)
	for key in extra: relation[key]=extra[key]
	civ["player_relation"]=relation
	WorldSimulation.world.civilizations[index]=civ

static func _leader_trust(civ_id:String,delta:float)->void:
	var leader:=ForeignDiplomacy.leader(civ_id)
	if leader.is_empty(): return
	leader.trust=clampf(float(leader.trust)+delta,-1.0,1.0)

static func _personality(civ_id:String)->Dictionary:
	var p:Dictionary=ForeignDiplomacy.leader(civ_id).get("personality",{})
	return p if not p.is_empty() else {"openness":.5,"discipline":.5,"empathy":.5,"assertiveness":.5,"risk_tolerance":.5}

static func _hungry(civ:Dictionary)->bool:
	return float(civ.get("food_days",30.0))<22.0

static func _commitments()->COMMITMENTS:
	ForeignDiplomacy.ensure()
	return ForeignDiplomacy.commitments as COMMITMENTS

# --------------------------------------------------------------------------
# Foreign generation
# --------------------------------------------------------------------------

static func _generate_for(occasion:Dictionary,day:int)->Dictionary:
	if String(occasion.get("type","")) in COURT_OCCASIONS: return _generate_court_occasion(occasion,day)
	return _generate_foreign_occasion(occasion,day)

static func _generate_foreign_occasion(occasion:Dictionary,day:int)->Dictionary:
	var civ_id:=String(occasion.get("civ_id",""))
	var civ:=ForeignDiplomacy.civilization(civ_id)
	var leader:=ForeignDiplomacy.leader(civ_id)
	if civ.is_empty() or leader.is_empty(): return {}
	var rng:=_rng("occasion:%s:%s:%d" % [civ_id,String(occasion.get("key","")),int(state().serial)],day)
	# A people that dreads the god and keeps its distance sends fewer envoys.
	if bool(_lives().call("avoids",civ_id,occasion,rng)): return {}
	var used:=_used_asks("civ:"+civ_id,day)
	var candidates:=_foreign_candidates(civ_id,occasion,rng,used,day)
	var chosen:=_weighted(candidates,rng)
	if chosen.is_empty(): return {}
	return _foreign_audience(civ_id,chosen,occasion,day)

static func _weighted(candidates:Array[Dictionary],rng:RandomNumberGenerator)->Dictionary:
	var total:=0.0
	for candidate in candidates: total+=maxf(0.0,float(candidate.w))
	if total<=0.0: return {}
	var roll:=rng.randf()*total
	for candidate in candidates:
		roll-=maxf(0.0,float(candidate.w))
		if float(candidate.w)>0.0 and roll<=0.0: return candidate
	return candidates[-1]

static func _foreign_candidates(civ_id:String,occasion:Dictionary,rng:RandomNumberGenerator,used:Dictionary,day:int)->Array[Dictionary]:
	var type:=String(occasion.get("type","ambient"))
	var mix:Dictionary=OCCASION_MIX.get(type,OCCASION_MIX.ambient)
	var branches:Dictionary={}
	if type=="sequel":
		var plan:=_sequel_plan(civ_id,occasion)
		mix=plan.mix; branches=plan.branch
	var p:=_personality(civ_id)
	var civ:=ForeignDiplomacy.civilization(civ_id)
	var result:Array[Dictionary]=[]
	for situation_type:String in mix:
		var base:=float(mix[situation_type])
		if base<=0.0: continue
		var candidate:=_candidate(situation_type,civ_id,occasion,rng,used,day)
		if candidate.is_empty(): continue
		candidate["w"]=base*_temperament_factor(situation_type,p,civ)*float(_lives().call("dread_weight",situation_type,civ_id))*float(_rivals().call("weight",situation_type,civ_id))
		if branches.has(situation_type):
			var previous:Dictionary=(occasion.get("data",{}) as Dictionary).get("previous",{})
			(candidate.situation as Dictionary)["arc"]={"branch":String(branches[situation_type]),"previous":previous.duplicate(true)}
		result.append(candidate)
	return result

static func _temperament_factor(situation_type:String,p:Dictionary,civ:Dictionary)->float:
	var relation:Dictionary=civ.get("player_relation",{})
	var opinion:=float(relation.get("opinion",0.0))
	var trust:=float(ForeignDiplomacy.leader(String(civ.get("id",""))).get("trust",0.0))
	var size_ratio:=clampf(float(civ.get("population",100))/_player_population(),0.35,1.8)
	match situation_type:
		"gift_goods","gratitude_gift": return maxf(0.05,0.6+float(p.empathy)*0.8+maxf(0.0,opinion))
		"tribute_demand","emboldened_demand","test_of_resolve":
			var hostility:=maxf(0.05,0.3+float(p.assertiveness)*1.2+float(p.risk_tolerance)*0.3-float(p.empathy)*0.4+maxf(0.0,-opinion))*size_ratio
			return hostility*(0.3 if opinion>0.4 else 1.0)
		"news_report","rumor_share","intelligence_share": return 0.6+float(p.openness)*0.8
		"accord_offer","protection_pact","league_invitation","trade_offer":
			var warmth:=0.5+maxf(0.0,opinion)*1.2+trust*0.5
			return maxf(0.05,warmth*(0.25 if opinion<-0.1 else 1.0))
		"nonaggression_offer": return maxf(0.1,0.5+float(p.empathy)*0.6+float(p.discipline)*0.3)
		"scholar_offer","research_sale","license_offer": return 0.5+float(p.openness)*0.9+(0.4 if String(civ.get("strategy",""))=="inquiry" else 0.0)
		"war_support": return 0.5+float(p.assertiveness)*0.6
		"artifact_gift": return maxf(0.05,0.5+float(p.empathy)*0.6+float(p.openness)*0.3+maxf(0.0,opinion))
		"artifact_purchase": return maxf(0.05,0.4+float(p.openness)*0.6+maxf(0.0,opinion)*0.8)
		"artifact_return": return 0.8+float(p.assertiveness)*0.8
	return 1.0

static func _sequel_plan(civ_id:String,occasion:Dictionary)->Dictionary:
	## Continuity: how the last audience ended decides who comes next.
	var previous:Dictionary=(occasion.get("data",{}) as Dictionary).get("previous",{})
	var situation:=String(previous.get("situation",""))
	var option:=String(previous.get("option",""))
	var kind:=String(previous.get("kind",""))
	var p:=_personality(civ_id)
	var relation:Dictionary=ForeignDiplomacy.civilization(civ_id).get("player_relation",{})
	var assertive:=float(p.assertiveness)>0.55 or float(relation.get("border_tension",0.0))>0.4
	var bold:=float(p.assertiveness)+float(p.risk_tolerance)>1.0
	var refused:=option in ["refuse","rebuff","abstain","dismiss","ignored","expired","defy"]
	if option=="decline":
		# A polite no cools the next envoy; only a hard, pressed neighbor turns it into a demand.
		var soft:Dictionary={"news_report":0.9,"rumor_share":0.4}
		if assertive and float(relation.get("border_tension",0.0))>0.4: soft["tribute_demand"]=0.6
		return {"mix":soft,"branch":{"news_report":"cooler","rumor_share":"cooler","tribute_demand":"threat_after_refusal"}}
	if kind=="threat" and option=="pay":
		if assertive: return {"mix":{"emboldened_demand":1.4,"news_report":0.3},"branch":{"emboldened_demand":"emboldened","news_report":"respect"}}
		return {"mix":{"gift_goods":0.8,"news_report":0.6,"nonaggression_offer":0.5},"branch":{"gift_goods":"respect","news_report":"respect","nonaggression_offer":"respect"}}
	if kind=="threat" and option in ["defy","counter"]:
		if bold: return {"mix":{"test_of_resolve":1.4,"news_report":0.2},"branch":{"test_of_resolve":"test_of_resolve","news_report":"cooler"}}
		return {"mix":{"nonaggression_offer":1.0,"accord_offer":0.6},"branch":{"nonaggression_offer":"second_thoughts","accord_offer":"second_thoughts"}}
	if situation=="aid_request" and option in ["grant","grant_half"]:
		return {"mix":{"gratitude_gift":1.3,"artifact_gift":0.6,"protection_pact":0.7,"accord_offer":0.6,"trade_offer":0.5},"branch":{"gratitude_gift":"gratitude","artifact_gift":"gratitude","protection_pact":"alliance_feeler","accord_offer":"alliance_feeler","trade_offer":"alliance_feeler"}}
	if refused:
		var mix:Dictionary={"news_report":0.8,"rumor_share":0.3}
		if assertive: mix["tribute_demand"]=1.3
		return {"mix":mix,"branch":{"news_report":"cooler","rumor_share":"cooler","tribute_demand":"threat_after_refusal"}}
	if kind=="gift" and option in ["accept","accept_return"]:
		return {"mix":{"accord_offer":0.8,"protection_pact":0.5,"trade_offer":0.6,"scholar_offer":0.5,"rumor_share":0.4},"branch":{"accord_offer":"alliance_feeler","protection_pact":"alliance_feeler","trade_offer":"alliance_feeler","scholar_offer":"warming","rumor_share":"warming"}}
	if kind=="proposal":
		return {"mix":{"gratitude_gift":0.6,"artifact_gift":0.4,"scholar_offer":0.5,"research_sale":0.4,"league_invitation":0.5,"protection_pact":0.5,"intelligence_share":0.4},"branch":{"gratitude_gift":"warming","artifact_gift":"warming","scholar_offer":"warming","research_sale":"warming","league_invitation":"warming","protection_pact":"warming","intelligence_share":"warming"}}
	if kind=="news":
		return {"mix":{"rumor_share":0.8,"intelligence_share":0.6,"gift_goods":0.5},"branch":{"rumor_share":"friendship","intelligence_share":"friendship","gift_goods":"friendship"}}
	return {"mix":OCCASION_MIX.ambient,"branch":{}}

static func _candidate(situation_type:String,civ_id:String,occasion:Dictionary,rng:RandomNumberGenerator,used:Dictionary,day:int)->Dictionary:
	var civ:=ForeignDiplomacy.civilization(civ_id)
	if civ.is_empty(): return {}
	var relation:Dictionary=civ.player_relation
	var war:=bool(relation.get("at_war",false))
	var name:=String(civ.get("name",civ_id))
	var data:Dictionary=occasion.get("data",{}) if occasion.get("data") is Dictionary else {}
	var previous:Dictionary=data.get("previous",{}) if data.get("previous") is Dictionary else {}
	var kind:=String(SITUATIONS.get(situation_type,{}).get("kind",""))
	var situation:={"type":situation_type,"headline":String(SITUATIONS.get(situation_type,{}).get("headline",""))}
	match situation_type:
		"gift_goods","gratitude_gift","dread_tribute":
			if war: return {}
			var terms:=_gift_terms(civ_id,civ,rng,used,1.3 if situation_type=="gratitude_gift" else (1.6 if situation_type=="dread_tribute" else 1.0))
			if terms.is_empty(): return {}
			situation.ask="gift:"+String(terms.resource)
			situation.summary=("%s sends %s in thanks for your help." if situation_type=="gratitude_gift" else ("%s sends %s as tribute; they have heard of your wrath." if situation_type=="dread_tribute" else "%s sends %s as a gift.")) % [name,_terms_text(terms)]
			return {"kind":kind,"terms":terms,"situation":situation}
		"aid_request":
			if war or not _hungry(civ): return {}
			var episode:=int(data.get("episode",-1))
			var blocked:=_request_blocked(civ_id,day,episode)
			var request:=_request_terms(civ,rng,blocked)
			if request.is_empty(): return {}
			situation.ask="request:"+String(request.resource)
			if String(request.resource)=="Food" and episode>=0: situation.ask="request:Food:famine%d" % episode
			situation.summary="%s is short of food (about %d days of stores) and asks for %s." % [name,roundi(float(civ.get("food_days",0))),_terms_text(request)]
			return {"kind":kind,"terms":request,"situation":situation}
		"tribute_demand","emboldened_demand","test_of_resolve":
			var scale:=1.4 if situation_type=="emboldened_demand" else (0.7 if situation_type=="test_of_resolve" else 1.0)
			var avoid:=String(previous.get("resource","")) if situation_type=="emboldened_demand" else ""
			var threat:=_threat_terms(civ,rng,used,scale,avoid)
			if threat.is_empty(): return {}
			situation.ask="tribute:"+String(threat.resource)
			situation.summary="%s demands %s in tribute." % [name,_terms_text(threat)]
			if situation_type=="emboldened_demand": situation.summary="%s, paid once, now demands %s more." % [name,_terms_text(threat)]
			elif situation_type=="test_of_resolve": situation.summary="%s, refused before, tests whether you meant it: it demands %s." % [name,_terms_text(threat)]
			return {"kind":kind,"terms":threat,"situation":situation}
		"news_report":
			var fact:=_news_fact(civ_id,rng,used,String(data.get("enemy","")))
			if fact.is_empty(): return {}
			situation.ask="news:%s:%s" % [String(fact.subject_civ_id),String(fact.fact_kind)]
			situation.summary=String(fact.fact)
			return {"kind":kind,"news":fact,"situation":situation}
		"rumor_share":
			return _rumor_candidate(civ_id,name,used,day,situation)
		"intelligence_share":
			return _intel_candidate(civ_id,name,used,day,situation)
		"accord_offer":
			var leader:=ForeignDiplomacy.leader(civ_id)
			if war or not (leader.accord as Dictionary).is_empty() or int(leader.get("next_day",0))>day: return {}
			var preferred:=String(ForeignDiplomacy.situation(civ_id).get("priority","exchange"))
			if String(occasion.get("type","")) in ["tension_rise","relation_cool","war_end","recruitment_incident"] or float(relation.get("border_tension",0.0))>0.45: preferred="restraint"
			var order:Array=[preferred,"exchange","routes","restraint"]
			for accord in order:
				if not ForeignDiplomacy.ACCORDS.has(String(accord)) or used.has("accord:"+String(accord)): continue
				var entry:Dictionary=ForeignDiplomacy.ACCORDS[String(accord)]
				situation.ask="accord:"+String(accord); situation.accord=String(accord); situation.accord_name=String(entry.name)
				situation.summary="%s proposes %s: %s For two years both peoples would gain research support in %s; war would end it." % [name,String(entry.name).to_lower(),String(entry.purpose),String(entry.domain)]
				return {"kind":kind,"situation":situation}
			return {}
		"protection_pact":
			var c:=_commitments()
			if war or used.has("pact:protection") or float(relation.get("opinion",0.0))<0.1 or c.eligibility(civ_id,c.terms("protection"))!="": return {}
			situation.ask="pact:protection"
			situation.summary="%s proposes mutual protection: each would answer a defensive siege against the other with feasible relief. It does not cover offensive wars." % name
			return {"kind":kind,"situation":situation}
		"league_invitation":
			var c2:=_commitments()
			if war or not c2.faction("player").is_empty(): return {}
			var theirs:Dictionary=c2.faction(civ_id)
			if not theirs.is_empty():
				var ask:="league:join:"+String(theirs.id)
				if used.has(ask) or c2.eligibility(civ_id,c2.terms("join_faction"))!="": return {}
				situation.ask=ask; situation.mode="join"; situation.league_id=String(theirs.id); situation.league_name=String(theirs.name)
				var members:Array=[]
				for member in theirs.members: members.append(_civ_name(String(member)))
				situation.summary="%s invites your people into the %s (members: %s). Membership means consultation before offensive war and relief for members under defensive siege." % [name,String(theirs.name),", ".join(members)]
				return {"kind":kind,"situation":situation}
			var ask2:="league:found:"+civ_id
			if used.has(ask2) or float(relation.get("opinion",0.0))<0.25 or c2.eligibility(civ_id,c2.terms("found_faction"))!="": return {}
			var goal:String={"commerce":"routes","inquiry":"exchange"}.get(String(civ.get("strategy","")),"defense")
			situation.ask=ask2; situation.mode="found"; situation.goal=goal; situation.league_name="League of %s" % name
			situation.summary="%s proposes founding a league with your people, devoted to %s. Each member keeps its own leader and army." % [name,String(COMMITMENTS.GOALS[goal]).to_lower()]
			return {"kind":kind,"situation":situation}
		"war_support":
			var enemy:=String(data.get("enemy",""))
			if war or enemy=="" or enemy=="player" or used.has("war_support:"+enemy): return {}
			if not bool((civ.get("relations",{}) as Dictionary).get(enemy,{}).get("at_war",false)): return {}
			var enemy_name:=_civ_name(enemy)
			situation.ask="war_support:"+enemy; situation.enemy=enemy; situation.enemy_name=enemy_name
			situation.summary="%s is at war with %s and asks where your people stand." % [name,enemy_name]
			return {"kind":kind,"situation":situation}
		"peace_feeler":
			if not war or not _peace_ok(civ_id,relation): return {}
			var war_key:=String(relation.get("war_id",""))
			var ask3:="peace:%s" % (war_key if war_key!="" else "day%d" % int(relation.get("war_started_day",0)))
			if used.has(ask3): return {}
			situation.ask=ask3
			situation.summary="%s sends an envoy under a sign of truce: it would end the war and keep a one-year truce along the present line." % name
			return {"kind":kind,"situation":situation}
		"trade_offer":
			if used.has("treaty:trade") or float(relation.get("opinion",0.0))<0.05 or CivilizationSystem.player_action_availability(civ_id,"open_trade").has("error"): return {}
			situation.ask="treaty:trade"
			situation.summary="%s proposes a standing trade compact between your peoples." % name
			return {"kind":kind,"situation":situation}
		"nonaggression_offer":
			if used.has("treaty:non_aggression") or CivilizationSystem.player_action_availability(civ_id,"non_aggression").has("error"): return {}
			situation.ask="treaty:non_aggression"
			situation.summary="%s proposes a compact of non-aggression: neither people to attack the other, and the frontier to calm." % name
			return {"kind":kind,"situation":situation}
		"scholar_offer","research_sale","license_offer":
			if war: return {}
			return _research_candidate(situation_type,civ_id,name,used,situation)
		"artifact_gift":
			if war: return {}
			return _artifact_gift_candidate(civ_id,name,used,situation)
		"artifact_purchase":
			if war: return {}
			return _artifact_purchase_candidate(civ_id,name,used,situation)
		"artifact_return":
			return _artifact_return_candidate(civ_id,name,used,situation)
		"recruitment_protest":
			var incident:=int(relation.get("last_recruitment_day",-1))
			if incident<0 or used.has("protest:recruitment:%d" % incident): return {}
			situation.ask="protest:recruitment:%d" % incident
			situation.visits=int(relation.get("recruitment_visits",0))
			situation.summary="%s protests that your recruiters invited its households away (%d visit%s so far) and wants it stopped." % [name,int(relation.get("recruitment_visits",0)),"" if int(relation.get("recruitment_visits",0))==1 else "s"]
			return {"kind":kind,"situation":situation}
		"debt_call","redress_demand":
			return _rivals().call("candidate",situation_type,civ_id,occasion,rng,used,day)
	return {}

static func _rumor_candidate(civ_id:String,name:String,used:Dictionary,day:int,situation:Dictionary)->Dictionary:
	var net:=CivilizationSystem.rumor_network as RUMORS
	if net==null: return {}
	var mine:Dictionary=net.books.get("player",{})
	for lead in net.list_leads(civ_id,day):
		if not lead is Dictionary: continue
		var subject:=String(lead.get("subject",""))
		var lead_id:=String(lead.get("id",""))
		if subject in ["player",civ_id,""] or mine.has(lead_id) or used.has("rumor:"+lead_id): continue
		situation.ask="rumor:"+lead_id; situation.lead_id=lead_id
		var confidence:="fair" if float(lead.get("confidence",0))>=.35 else ("thin" if float(lead.get("confidence",0))>=.15 else "faint")
		situation.summary="%s's people carry an account of %s, first observed on day %d; the account is %s." % [name,String(lead.get("name","a distant people")),int(lead.get("observed_day",0)),confidence]
		var news:={"subject_civ_id":subject,"subject_civ_name":String(lead.get("name","")),"fact_kind":"rumor","fact":String(situation.summary)}
		return {"kind":"news","news":news,"situation":situation}
	return {}

static func _intel_candidate(civ_id:String,name:String,used:Dictionary,day:int,situation:Dictionary)->Dictionary:
	var intel:=CivilizationSystem.city_intelligence as INTEL
	if intel==null: return {}
	var theirs:Dictionary=intel.records.get(civ_id,{})
	var ids:Array=theirs.keys(); ids.sort()
	for city_id in ids:
		var record:Variant=theirs[city_id]
		if not record is Dictionary: continue
		var owner:=String(record.get("civ_id",""))
		if owner in ["",civ_id,"player"] or ForeignDiplomacy.civilization(owner).is_empty() or used.has("intel:"+String(city_id)): continue
		if day-int(record.get("observed_day",-9999))>365: continue
		var mine:Dictionary=intel.known("player",String(city_id))
		if not mine.is_empty() and int(mine.get("observed_day",-1))>=int(record.get("observed_day",0))-45: continue
		situation.ask="intel:"+String(city_id); situation.city_id=String(city_id); situation.city_name=String(record.get("name","a city"))
		situation.summary="%s offers what its people saw of %s, a settlement of %s, on day %d." % [name,String(record.get("name","a city")),_civ_name(owner),int(record.get("observed_day",0))]
		var news:={"subject_civ_id":owner,"subject_civ_name":_civ_name(owner),"fact_kind":"city_intelligence","fact":String(situation.summary)}
		return {"kind":"news","news":news,"situation":situation}
	return {}

static func _payment_option(civ_id:String)->Dictionary:
	## The standard diplomatic gift the player can actually spare, non-Food first.
	var options:=CivilizationSystem.diplomatic_gift_options(civ_id)
	for option:Dictionary in options:
		if bool(option.get("can_send",false)) and String(option.resource)!="Food": return {"resource":String(option.resource),"amount":_nice(float(option.amount))}
	for option2:Dictionary in options:
		if bool(option2.get("can_send",false)): return {"resource":String(option2.resource),"amount":_nice(float(option2.amount))}
	return {}

static func _research_quote(situation_type:String,civ_id:String,subject:String)->Dictionary:
	## The envoy brings the teacher, study or contract with them, so these use
	## each mechanic's envoy path (same rules, no mission slot of ours).
	match situation_type:
		"scholar_offer": return SCHOLARS.envoy_quote(civ_id,subject)
		"research_sale": return PURCHASE.envoy_quote(civ_id,subject)
		"license_offer": return LICENSES.envoy_quote(civ_id,subject)
	return {"error":"Unknown offer."}

static func _travel_days(civ_id:String)->int:
	var civ:=ForeignDiplomacy.civilization(civ_id)
	var home:Dictionary=(civ.get("player_relation",{}) as Dictionary).get("home_position",{})
	if not home.has("x"): return 10
	var distance:=CivilizationSystem.player_world_origin.distance_to(Vector2(float(home.x),float(home.get("z",0.0))))
	return clampi(ceili(distance/17.0),3,120)

static func _research_candidate(situation_type:String,civ_id:String,name:String,used:Dictionary,situation:Dictionary)->Dictionary:
	var provider:=SOCIETY.owner_state(civ_id)
	if provider==null: return {}
	if String(provider.society_exchange.get("sharing_policy","selective"))!="open": return {}
	var payment:=_payment_option(civ_id)
	if payment.is_empty(): return {}
	var known:Array=provider.known_discoveries
	var subjects:Array[String]=[]
	if situation_type=="license_offer":
		for subject in LICENSES.subjects():
			if subject in known: subjects.append(subject)
	else:
		for subject in known:
			if not String(subject) in GameState.known_discoveries: subjects.append(String(subject))
	var prefix:String={"scholar_offer":"scholar:","research_sale":"purchase:","license_offer":"license:"}[situation_type]
	var tried:=0
	for subject in subjects:
		if used.has(prefix+subject): continue
		tried+=1
		if tried>40: break
		var quote:=_research_quote(situation_type,civ_id,subject)
		if quote.has("error"): continue
		var subject_name:=String(quote.get("subject_name",subject))
		situation.ask=prefix+subject; situation.subject=subject; situation.subject_name=subject_name
		situation.payment=String(payment.resource); situation.payment_amount=float(payment.amount)
		var what:String={"scholar_offer":"a teacher of %s, who would stay sixty days","research_sale":"a validated study of %s for your researchers to reproduce","license_offer":"a one-year license to manufacture by %s"}[situation_type] % subject_name
		situation.summary="%s offers %s, for %s." % [name,what,_terms_text({"resource":payment.resource,"amount":payment.amount})]
		return {"kind":"proposal","situation":situation}
	return {}

# ---- artifacts ----

static func _ensure_ties(civ_id:String)->void:
	## An envoy standing in the hall means the two peoples have met in person;
	## record the acquaintance on both sides so objects can change hands.
	if SOCIETY.owner_state(civ_id)==null: return
	SOCIETY.connection(civ_id)
	WorldSimulation.scoped(SOCIETY.owner_id(civ_id),func()->void:SOCIETY.connection("player"))

static func _artifact_label(item:Dictionary)->String:
	return "%s (%s)" % [String(item.get("name","an object")),String(ARTIFACTS.TIERS[clampi(int(item.get("rarity",0)),0,4)]).to_lower()]

static func _artifact_ids_by_price(holdings:Dictionary,ascending:bool)->Array:
	var ids:Array=holdings.keys()
	ids.sort_custom(func(a:Variant,b:Variant)->bool:
		var pa:=ARTIFACTS.price(holdings[a]); var pb:=ARTIFACTS.price(holdings[b])
		return (pa<pb if ascending else pa>pb) or (pa==pb and String(a)<String(b)))
	return ids

static func _artifact_gift_candidate(civ_id:String,name:String,used:Dictionary,situation:Dictionary)->Dictionary:
	_ensure_ties(civ_id)
	var theirs:=ARTIFACTS.holdings(civ_id)
	if theirs.is_empty(): return {}
	# A piece of our own people's making comes home first; otherwise a modest piece.
	var ids:=_artifact_ids_by_price(theirs,true)
	var ours:Array=[]
	for id in ids:
		if String((theirs[id] as Dictionary).get("source_id",""))=="player": ours.append(id)
	for id in ours+ids:
		if used.has("artifact_gift:"+String(id)) or ARTIFACTS.exchange_check(civ_id,String(id),"player","gift").has("error"): continue
		var item:Dictionary=theirs[id]
		var homecoming:=String(item.get("source_id",""))=="player"
		situation.ask="artifact_gift:"+String(id); situation.artifact_id=String(id); situation.artifact_name=String(item.get("name","")); situation.value=ARTIFACTS.price(item)
		situation.summary="%s offers %s as a gift%s." % [name,_artifact_label(item)," — a piece made by your own people, coming home" if homecoming else ""]
		return {"kind":"proposal","situation":situation}
	return {}

static func _artifact_purchase_candidate(civ_id:String,name:String,used:Dictionary,situation:Dictionary)->Dictionary:
	_ensure_ties(civ_id)
	var ours:=ARTIFACTS.holdings("player")
	if ours.is_empty(): return {}
	var theirs:=ARTIFACTS.holdings(civ_id)
	for id in _artifact_ids_by_price(ours,false):
		var item:Dictionary=ours[id]
		if used.has("artifact_buy:"+String(id)) or String(item.get("source_id",""))==civ_id: continue
		var can_sell:=not ARTIFACTS.exchange_check("player",String(id),civ_id,"sell").has("error")
		var offered:=""
		for other_id in _artifact_ids_by_price(theirs,false):
			if ARTIFACTS.price(theirs[other_id])<=ARTIFACTS.price(item) and not ARTIFACTS.exchange_check("player",String(id),civ_id,"trade",String(other_id)).has("error"):
				offered=String(other_id); break
		if not can_sell and offered=="": continue
		situation.ask="artifact_buy:"+String(id); situation.artifact_id=String(id); situation.artifact_name=String(item.get("name","")); situation.value=ARTIFACTS.price(item)
		situation.offered_id=offered
		situation.offered_name=String((theirs.get(offered,{}) as Dictionary).get("name","")) if offered!="" else ""
		var terms:="for %.0f in coin" % ARTIFACTS.price(item) if can_sell else ""
		if offered!="": terms+=(" or " if terms!="" else "")+"in exchange for %s" % _artifact_label(theirs[offered])
		situation.summary="%s has heard of your %s and asks for it, %s." % [name,_artifact_label(item),terms]
		return {"kind":"proposal","situation":situation}
	return {}

static func _looted_from(civ_id:String)->Array[Dictionary]:
	## Treasures our people carried off from their great works and still hold.
	var result:Array[Dictionary]=[]
	var ours:=ARTIFACTS.holdings("player")
	for city in RIVALRY.cities(civ_id):
		if not city is Dictionary: continue
		for r in (city as Dictionary).get("undertakings",[]):
			if not r is Dictionary: continue
			var rivalry:Dictionary=(r as Dictionary).get("rivalry",{}) if (r as Dictionary).get("rivalry") is Dictionary else {}
			for entry in rivalry.get("looted",[]):
				if entry is Dictionary and String(entry.get("by",""))=="player" and not bool(entry.get("returned",false)) and ours.has(String(entry.get("id",""))):
					result.append({"item_id":String(entry.id),"work_id":String((r as Dictionary).get("id","")),"day":int(entry.get("day",0))})
	return result

static func _artifact_return_candidate(civ_id:String,name:String,used:Dictionary,situation:Dictionary)->Dictionary:
	var ours:=ARTIFACTS.holdings("player")
	for looted in _looted_from(civ_id):
		if used.has("artifact_return:"+String(looted.item_id)): continue
		var item:Dictionary=ours[String(looted.item_id)]
		situation.ask="artifact_return:"+String(looted.item_id); situation.artifact_id=String(looted.item_id); situation.artifact_name=String(item.get("name",""))
		situation.mode="looted"; situation.work_id=String(looted.work_id); situation.value=ARTIFACTS.price(item)
		situation.summary="%s demands the return of %s, carried off by your soldiers from one of its great works on day %d." % [name,_artifact_label(item),int(looted.day)]
		return {"kind":"proposal","situation":situation}
	_ensure_ties(civ_id)
	for id in _artifact_ids_by_price(ours,false):
		var piece:Dictionary=ours[id]
		if String(piece.get("source_id",""))!=civ_id or used.has("artifact_return:"+String(id)): continue
		if ARTIFACTS.exchange_check("player",String(id),civ_id,"gift").has("error"): continue
		situation.ask="artifact_return:"+String(id); situation.artifact_id=String(id); situation.artifact_name=String(piece.get("name",""))
		situation.mode="origin"; situation.value=ARTIFACTS.price(piece)
		situation.summary="%s asks for %s back: it was made by their people and they want it home." % [name,_artifact_label(piece)]
		return {"kind":"proposal","situation":situation}
	return {}

static func _request_blocked(civ_id:String,day:int,episode:int)->Dictionary:
	## Resources this people may not ask for again yet: never within a year; a
	## Food request for a distinct famine episode may return after that.
	var blocked:Dictionary={}
	for entry in state().ledger:
		if not entry is Dictionary or String(entry.get("speaker",""))!="civ:"+civ_id: continue
		var ask:=String(entry.get("ask",""))
		if not ask.begins_with("request:"): continue
		var parts:=ask.split(":")
		var resource:=String(parts[1]) if parts.size()>1 else ""
		var age:=day-int(entry.get("day",-99999))
		if age<365: blocked["request:"+resource]=true
		elif age<REPEAT_DAYS:
			var new_episode:=resource=="Food" and episode>=0 and ask!="request:Food:famine%d" % episode
			if not new_episode: blocked["request:"+resource]=true
	return blocked

static func _foreign_audience(civ_id:String,chosen:Dictionary,occasion:Dictionary,day:int)->Dictionary:
	var civ:=ForeignDiplomacy.civilization(civ_id)
	var leader:=ForeignDiplomacy.leader(civ_id)
	var kind:=String(chosen.kind)
	var audience:=_new_audience("foreign",kind,day)
	audience.civ_id=civ_id
	audience.civ_name=String(civ.get("name",civ_id))
	audience.speaker=_envoy(civ_id,String(audience.id),kind,leader)
	if chosen.get("terms") is Dictionary: audience.terms=(chosen.terms as Dictionary).duplicate()
	if chosen.get("news") is Dictionary: audience.news=(chosen.news as Dictionary).duplicate()
	var situation:Dictionary=(chosen.get("situation",{}) as Dictionary).duplicate(true)
	situation["occasion"]={"type":String(occasion.get("type","")),"text":String((occasion.get("data",{}) as Dictionary).get("text","")),"day":int(occasion.get("day",day)),"crisis":bool(occasion.get("crisis",false))}
	audience.situation=situation
	# The ruler behind the envoy: memory, a string on the business, a bluff.
	_rivals().call("dress",audience,occasion,day)
	return audience

static func _generate_foreign(civ_id:String,day:int,forced_kind:String)->Dictionary:
	## Forced generation (tests, captures): any situation of that kind that the
	## world can truthfully back, ignoring the ledger and the budget.
	var civ:=ForeignDiplomacy.civilization(civ_id)
	if civ.is_empty() or ForeignDiplomacy.leader(civ_id).is_empty(): return {}
	var rng:=_rng("forced:%s:%s:%d" % [civ_id,forced_kind,int(state().serial)],day)
	var occasion:={"type":"debug","key":"debug","civ_id":civ_id,"data":{"text":"a summons from the ruler"}}
	var order:Array=[]
	for situation_type:String in SITUATIONS:
		if String(SITUATIONS[situation_type].kind)==forced_kind and not situation_type in ["gratitude_gift","emboldened_demand","test_of_resolve"]: order.append(situation_type)
	if forced_kind=="proposal":
		for index in order.size():
			var swap:=rng.randi_range(index,order.size()-1)
			var t:Variant=order[index]; order[index]=order[swap]; order[swap]=t
	for situation_type in order:
		var candidate:=_candidate(String(situation_type),civ_id,occasion,rng,{},day)
		if not candidate.is_empty(): return _foreign_audience(civ_id,candidate,occasion,day)
	return {}

static func _envoy(civ_id:String,audience_id:String,kind:String,leader:Dictionary)->Dictionary:
	var serial:=posmod(hash(civ_id),10000)
	var traditions:Array=NAMES.POOLS.keys()
	var tradition:String=traditions[serial%traditions.size()]
	var envoy_serial:=posmod(hash(civ_id+":"+audience_id),100000)+10000
	# Envoys of other peoples keep their own names: one name, one person.
	var taken:={String(leader.get("name","")):true,"given:"+String(leader.get("name","")).get_slice(" ",0):true}
	for list_key in ["history","queue"]:
		for other in state().get(list_key,[]):
			if other is Dictionary and String(other.get("origin",""))=="foreign" and String(other.get("civ_id",""))!=civ_id:
				var other_name:=String((other.get("speaker",{}) as Dictionary).get("name",""))
				if other_name!="": taken[other_name]=true; taken["given:"+other_name.get_slice(" ",0)]=true
	var identity:Dictionary=preload("res://scripts/era_names.gd").make(int(GameState.world_seed),envoy_serial,envoy_serial%2==0,civ_id,taken)
	if String(identity.get("name",""))=="": identity=NAMES.make(int(GameState.world_seed),envoy_serial,envoy_serial%2==0,tradition,{String(leader.get("name","")):true})
	var leader_name:=String(leader.get("name","their leader"))
	var titles:Dictionary={
		"gift":["Gift-bearer of %s","Friend of the house of %s","Hand of %s"],
		"request":["Petitioner for %s","Voice of %s","Messenger of %s"],
		"threat":["Herald of %s","Spear-speaker of %s","Envoy of %s"],
		"news":["Road-walker for %s","Listener of %s","Messenger of %s"],
		"proposal":["Envoy of %s","Speaker for %s","Emissary of %s"],
	}
	var options:Array=titles.get(kind,titles.news)
	return {"name":String(identity.get("name","A traveling envoy")),"title":String(options[envoy_serial%options.size()]) % leader_name,"person_id":0,"role":"envoy"}

static func _gift_terms(civ_id:String,civ:Dictionary,rng:RandomNumberGenerator,used:Dictionary={},scale:float=1.0)->Dictionary:
	var p:=_personality(civ_id)
	var best:={}
	var best_score:=0.0
	var recent:=_recent_resources("gift:")
	for resource in RESOURCES:
		if used.has("gift:"+String(resource)): continue
		var stock:=foreign_stock(civ_id,resource)
		if stock<=0.0: continue
		if resource=="Food" and _hungry(civ): continue
		var cap:=_player_population()*(1.6 if resource=="Food" else 0.35)*(0.6+float(p.empathy)*0.8)*scale
		var amount:=_nice(minf(stock*rng.randf_range(0.05,0.12)*scale,cap*rng.randf_range(0.7,1.2)))
		if amount<5.0 or amount>stock: continue
		var score:=amount/maxf(1.0,cap)*rng.randf_range(0.6,1.4)*pow(0.4,float(recent.get(String(resource),0)))
		if score>best_score: best_score=score; best={"resource":resource,"amount":amount}
	return best

static func _request_terms(civ:Dictionary,rng:RandomNumberGenerator,used:Dictionary={})->Dictionary:
	var wants:Array=[]
	if _hungry(civ): wants.append("Food")
	match String(civ.get("strategy","")):
		"expansion","growth": wants.append_array(["Timber","Fiber Plants"])
		"fortification": wants.append_array(["Stone","Timber"])
		"commerce": wants.append_array(["Clay","Fiber Plants"])
		"inquiry": wants.append("Clay")
		_: wants.append_array(["Food","Timber"])
	var others:Array=RESOURCES.duplicate()
	for index in others.size():
		var swap:=rng.randi_range(index,others.size()-1)
		var t:Variant=others[index]; others[index]=others[swap]; others[swap]=t
	for resource in others:
		if resource not in wants: wants.append(resource)
	# What others asked for lately goes to the back, unless hunger makes Food the point.
	var recent:=_recent_resources("request:")
	var fresh:Array=[]; var stale:Array=[]
	for resource in wants:
		if recent.has(String(resource)) and not (String(resource)=="Food" and _hungry(civ)): stale.append(resource)
		else: fresh.append(resource)
	wants=fresh+stale
	var their_pop:=maxf(20.0,float(civ.get("population",100)))
	for resource:String in wants:
		if used.has("request:"+resource): continue
		var stock:=player_stock(resource)
		var want:=their_pop*(0.6 if resource=="Food" else 0.12)*rng.randf_range(0.7,1.3)
		var amount:=_nice(minf(want,stock*0.3))
		if amount>=5.0 and amount<=stock: return {"resource":resource,"amount":amount}
	return {}

static func _recent_resources(prefix:String,days:int=365)->Dictionary:
	## Resources anyone has recently asked for or given under this ask prefix,
	## so the hall does not hear "Food, Food, Food" from every neighbor.
	var recent:Dictionary={}
	var today:=_day()
	for entry in state().ledger:
		if entry is Dictionary and String(entry.get("ask","")).begins_with(prefix) and today-int(entry.get("day",-99999))<days:
			var resource:=String(String(entry.ask).trim_prefix(prefix).split(":")[0])
			recent[resource]=int(recent.get(resource,0))+1
	return recent

const STRATEGY_WANTS:={"fortification":["Stone","Timber"],"expansion":["Timber","Fiber Plants"],"growth":["Food","Timber"],"commerce":["Clay","Fiber Plants"],"inquiry":["Clay"],"sustenance":["Food"]}

static func _threat_terms(civ:Dictionary,rng:RandomNumberGenerator,used:Dictionary={},scale:float=1.0,avoid:String="")->Dictionary:
	var best:={}
	var best_value:=0.0
	var their_pop:=maxf(20.0,float(civ.get("population",100)))
	var recent:=_recent_resources("tribute:")
	var wants:Array=STRATEGY_WANTS.get(String(civ.get("strategy","")),[])
	for resource in RESOURCES:
		if used.has("tribute:"+String(resource)) or String(resource)==avoid: continue
		var stock:=player_stock(resource)
		var demand:=_nice(minf(stock*rng.randf_range(0.25,0.45)*scale,their_pop*(1.2 if resource=="Food" else 0.3)*scale))
		if demand<8.0 or demand>stock: continue
		var value:=demand/maxf(1.0,their_pop*(1.2 if resource=="Food" else 0.3)*scale)*rng.randf_range(0.7,1.3)
		value*=(1.6 if resource in wants else 1.0)*pow(0.4,float(recent.get(String(resource),0)))
		if value>best_value: best_value=value; best={"resource":resource,"amount":demand}
	return best

static func _news_fact(civ_id:String,rng:RandomNumberGenerator,used:Dictionary={},focus:String="")->Dictionary:
	## Real facts about third civilizations only.
	var facts:Array=[]
	var civs:Array=WorldSimulation.world.civilizations
	var player_pop:=_player_population()
	for first in civs:
		var first_id:=String(first.get("id",""))
		if first_id==civ_id or not bool(first.get("alive",true)): continue
		var name:=String(first.get("name",first_id))
		var focus_boost:=3.0 if focus!="" and first_id==focus else 1.0
		for other_id in (first.get("relations",{}) as Dictionary):
			if String(other_id)<=first_id and String(other_id)!=civ_id: continue
			var relation:Dictionary=first.relations[other_id]
			var other_index:=_civ_index(String(other_id))
			if other_index<0 or not bool(civs[other_index].get("alive",true)): continue
			var other_name:=String(civs[other_index].get("name",other_id))
			if bool(relation.get("at_war",false)):
				var text:String="%s and %s are at war." % [name,other_name] if String(other_id)!=civ_id else "%s is at war with %s, the people who sent this envoy." % [name,other_name]
				facts.append({"w":3.0*focus_boost,"f":{"subject_civ_id":first_id,"subject_civ_name":name,"fact_kind":"war","fact":text}})
			elif float(relation.get("border_tension",0))>0.6 and String(other_id)!=civ_id:
				facts.append({"w":1.4,"f":{"subject_civ_id":first_id,"subject_civ_name":name,"fact_kind":"border_tension","fact":"The border between %s and %s is tense; each watches the other." % [name,other_name]}})
		if bool(first.player_relation.get("at_war",false)):
			facts.append({"w":2.2,"f":{"subject_civ_id":first_id,"subject_civ_name":name,"fact_kind":"war_with_you","fact":"%s remains at war with your people." % name}})
		var food_days:=float(first.get("food_days",30))
		if food_days<12.0:
			facts.append({"w":2.6,"f":{"subject_civ_id":first_id,"subject_civ_name":name,"fact_kind":"famine","fact":"%s is going hungry; its stores would last only about %d days." % [name,maxi(0,roundi(food_days))]}})
		elif food_days>90.0:
			facts.append({"w":0.9,"f":{"subject_civ_id":first_id,"subject_civ_name":name,"fact_kind":"plenty","fact":"%s has full granaries, enough for about %d days." % [name,roundi(food_days)]}})
		var strategy_words:Dictionary={"fortification":"is raising defenses and drilling its fighters","expansion":"is pushing out to claim new land","inquiry":"is pouring effort into learning","commerce":"is busy with trade and traveling merchants","growth":"is growing its households quickly","sustenance":"is putting its strength into feeding itself"}
		var strategy:=String(first.get("strategy",""))
		if strategy_words.has(strategy):
			facts.append({"w":1.3 if strategy in ["fortification","expansion"] else 0.8,"f":{"subject_civ_id":first_id,"subject_civ_name":name,"fact_kind":"strategy","fact":"%s %s." % [name,strategy_words[strategy]]}})
		var pop:=float(first.get("population",0))
		if pop>0:
			var ratio:=pop/player_pop
			var comparison:="about as many as yours" if ratio>0.8 and ratio<1.25 else ("more than twice your number" if ratio>=2.0 else ("more than yours" if ratio>=1.25 else ("fewer than half yours" if ratio<=0.5 else "fewer than yours")))
			var rounded:=maxi(10,roundi(pop/10.0)*10) if pop<500 else roundi(pop/50.0)*50
			facts.append({"w":0.7,"f":{"subject_civ_id":first_id,"subject_civ_name":name,"fact_kind":"size","fact":"%s numbers roughly %d people, %s." % [name,rounded,comparison]}})
	var open:Array=[]
	for entry in facts:
		var f:Dictionary=entry.f
		if not used.has("news:%s:%s" % [String(f.subject_civ_id),String(f.fact_kind)]): open.append(entry)
	if open.is_empty(): return {}
	var total:=0.0
	for entry in open: total+=float(entry.w)
	var roll:=rng.randf()*total
	for entry in open:
		roll-=float(entry.w)
		if roll<=0.0: return (entry.f as Dictionary).duplicate()
	return (open[-1].f as Dictionary).duplicate()

# --------------------------------------------------------------------------
# Court petitions
# --------------------------------------------------------------------------

static func _officials()->Array[Dictionary]:
	## Central officeholders first, then settlement leaders; unique by person.
	var result:Array[Dictionary]=[]
	var seen:Dictionary={}
	if WorldSimulation.actor_id!="player": return result
	for office in GovernmentPeopleSystem.active_offices():
		var person:=GovernmentPeopleSystem.officeholder(String(office.key))
		if person.is_empty() or seen.has(int(person.person_id)): continue
		person["office_key"]=String(office.key)
		seen[int(person.person_id)]=true
		result.append(person)
	for settlement in GameState.player_settlements:
		var leader:=GovernmentPeopleSystem.settlement_leader(String(settlement.get("id","")))
		if leader.is_empty() or seen.has(int(leader.person_id)): continue
		var place:=String(settlement.get("name",""))
		leader["office_title"]=String(leader.get("title","Local leader"))+(" of "+place if place!="" else "")
		leader["office_key"]="settlement"
		leader["settlement_id"]=String(settlement.get("id",""))
		seen[int(leader.person_id)]=true
		result.append(leader)
	return result

static func _official(person_id:int)->Dictionary:
	for person in _officials():
		if int(person.person_id)==person_id: return person
	return {}

static func _relevant_official(offices:Array)->Dictionary:
	var officials:=_officials()
	for office in offices:
		for person in officials:
			if String(person.get("office_key",""))==String(office): return person
	for person in officials:
		if String(person.get("office_key",""))=="settlement": return person
	return officials[0] if not officials.is_empty() else {}

static func conditions()->Dictionary:
	var metrics:Dictionary=GameState.simulation_metrics
	var decline:Dictionary=preload("res://scripts/hearth_count.gd").decline()
	var pop:=_player_population()
	var housing:=clampf(float(GameState.housing_capacity)/pop,0.0,2.0)
	var water:Dictionary=GameState.water_metrics
	var threat:=0.0
	var threat_name:=""
	for civ in WorldSimulation.world.civilizations:
		var relation:Dictionary=civ.get("player_relation",{})
		if int(relation.get("contact_level",0))<1: continue
		var level:=float(relation.get("border_tension",0))+(0.6 if bool(relation.get("at_war",false)) else 0.0)
		if level>threat: threat=level; threat_name=String(civ.get("name",""))
	return {"food_days":float(metrics.get("food_days",30.0)),"food_intake":float(metrics.get("food_intake_ratio",1.0)),
		"health":float(GameState.population_health),"security":float(metrics.get("security",0.4)),"cohesion":float(metrics.get("cohesion",0.58)),
		"housing_ratio":housing,"water_intake":float(water.get("intake_ratio",1.0)) if bool(water.get("source_accessible",true)) or float(water.get("required_today",0))>0 else 1.0,
		"foreign_threat":threat,"threat_name":threat_name,"population":pop,
		"decline_years":int(decline.get("years",0)),"decline_loss":-float(decline.get("total_change",0))/maxf(1.0,pop-float(decline.get("total_change",0))),"decline":decline}

static func _ambition_ladder(person:Dictionary)->Array:
	var office:=String(person.get("office_key",""))
	var ladder:Array=(AMBITIONS.get(office,AMBITIONS.settlement) as Array).duplicate()
	var traits:Array=person.get("traits",[])
	var first:=""
	if String(person.get("doctrine",""))=="representative": first="Hold a public council to hear the people"
	elif "Curious" in traits or "Inventive" in traits: first="Support scholars and fund research"
	if first!="":
		ladder.erase(first)
		ladder.push_front(first)
	return ladder

static func _next_ambition(person:Dictionary,day:int)->String:
	var used:=_used_asks("person:%d" % int(person.get("person_id",0)),day)
	for decree in _ambition_ladder(person):
		if not used.has("ambition:"+String(decree)): return String(decree)
	return ""

static func _condition_petition(topic:String,band:int,c:Dictionary)->Dictionary:
	match topic:
		"food":
			var decree:="Ration food for thirty days" if float(c.food_days)<10.0 or band>=2 else "Send gatherers to find food"
			return {"summary":"Food stores would last about %d days; people are %s." % [maxi(0,roundi(float(c.food_days))),"already eating less than they need" if float(c.food_intake)<0.97 else "counting portions"],"decree":decree}
		"health":
			var water_first:=float(c.water_intake)<0.95 and (0.95-float(c.water_intake))*3.0>(0.62-float(c.health))*3.0
			return {"summary":"People are not getting enough clean water; the sick are multiplying." if water_first else "Illness is spreading; health across the settlements has fallen to about %d%%." % roundi(float(c.health)*100),
				"decree":"Secure water and dig wells" if water_first else "Organize healers to care for the sick"}
		"housing":
			var homeless:=maxi(1,roundi(float(c.population)-float(GameState.housing_capacity)))
			return {"summary":"About %d people have no proper shelter." % homeless,"decree":"Build shelters"}
		"people":
			var decline:Dictionary=c.get("decline",{})
			if String(decline.get("summary",""))=="": return {}
			return {"summary":String(decline.summary),"decree":String(decline.get("decree",""))}
		"security":
			var summary:String="The watch is thin; the settlements feel unsafe." if String(c.threat_name)=="" or float(c.foreign_threat)<0.45 else "%s presses on the frontier and the watch is too thin to answer it." % String(c.threat_name)
			return {"summary":summary,"decree":"Raise a watch and post guards"}
	return {}

static func _grievance_words(person:Dictionary,refused_decree:String)->String:
	var rel:Dictionary=person.get("relationships",{}).get("sovereign",{})
	if refused_decree!="": return "%s has not forgotten that you dismissed their proposal to %s." % [String(person.name),refused_decree.to_lower()]
	var why:="feels their counsel has been ignored" if float(rel.get("trust",0.5))<0.35 else "nurses a grudge from past slights"
	if float(person.get("pride",0.5))>0.65: why="feels their standing has been insulted"
	return "%s %s." % [String(person.name),why]

static func _generate_court_occasion(occasion:Dictionary,day:int)->Dictionary:
	var type:=String(occasion.get("type",""))
	var data:Dictionary=occasion.get("data",{}) if occasion.get("data") is Dictionary else {}
	var person:=_official(int(occasion.get("person_id",0)))
	if person.is_empty() and type in ["condition","war_council"]:
		person=_relevant_official(TOPIC_OFFICES.get(String(data.get("topic","security")),["Marshal"]))
	if person.is_empty(): return {}
	var used:=_used_asks("person:%d" % int(person.person_id),day)
	var built:=_court_petition(type,person,data,day)
	if built.is_empty() or used.has(String(built.ask)): return {}
	return _court_audience(person,built,occasion,day)

static func _court_petition(type:String,person:Dictionary,data:Dictionary,day:int)->Dictionary:
	## {topic, summary, decree, ask, situation_type} or {} when not truthful now.
	var c:=conditions()
	match type:
		"condition":
			var topic:=String(data.get("topic",""))
			var band:=int(_condition_bands(c).get(topic,0))
			if band<1: return {}
			var words:=_condition_petition(topic,band,c)
			if words.is_empty(): return {}
			return {"topic":topic,"summary":String(words.summary),"decree":String(words.decree),"ask":"%s:band%d" % [topic,band],"situation_type":"crisis_petition"}
		"war_council":
			var enemy:=String(data.get("enemy_name","the enemy"))
			return {"topic":"war","summary":"War with %s has begun. %s wants the frontier watched and the settlements guarded before the first raid." % [enemy,String(person.name)],
				"decree":"Post guards and patrol the frontier","ask":"war:%s:%d" % [enemy,int(data.get("war_day",day))],"situation_type":"war_council"}
		"grievance","refusal_grievance":
			var rel:Dictionary=person.get("relationships",{}).get("sovereign",{})
			var decree:=String(data.get("decree",""))
			if type=="grievance" and float(rel.get("resentment",0))<=0.15 and float(rel.get("trust",0.5))>=0.35: return {}
			var band:=int(data.get("band",1))
			return {"topic":"grievance","summary":_grievance_words(person,decree),"decree":"","ask":"grievance:refused:"+decree if decree!="" else "grievance:band%d" % band,"situation_type":"grievance"}
		"appointment":
			var first:=_next_ambition(person,day)
			return {"topic":"introduction","summary":"%s has taken up office as %s and asks what the ruler expects of them.%s" % [String(person.name),String(person.get("office_title","an official")),(" They would begin with this: %s." % first.to_lower()) if first!="" else ""],
				"decree":first,"ask":"introduction:"+String(person.get("office_key","")),"situation_type":"introduction"}
		"promise_followup":
			var promised:=String(data.get("decree",""))
			if promised=="": return {}
			return {"topic":"follow_up","summary":"%d days ago you promised %s you would consider this: \"%s\". Nothing has been ordered since." % [day-int(data.get("promised_day",day)),String(person.name),promised],
				"decree":promised,"ask":"follow_up:"+promised,"situation_type":"promise_followup"}
		"ambition":
			var next:=_next_ambition(person,day)
			if next=="": return {}
			return {"topic":"ambition","summary":String(AMBITION_WORDS.get(next,"%s has a plan.")) % String(person.name),"decree":next,"ask":"ambition:"+next,"situation_type":"ambition"}
	return {}

static func _court_audience(person:Dictionary,built:Dictionary,occasion:Dictionary,day:int)->Dictionary:
	var audience:=_new_audience("court","petition",day)
	audience.speaker={"name":String(person.name),"title":String(person.get("office_title","Official")),"person_id":int(person.person_id),"role":"official"}
	audience.petition={"topic":String(built.topic),"summary":String(built.summary),"suggested_decree":String(built.decree)}
	var situation_type:=String(built.situation_type)
	var occasion_data:Dictionary=occasion.get("data",{}) if occasion.get("data") is Dictionary else {}
	audience.situation={"type":situation_type,"ask":String(built.ask),"headline":String(SITUATIONS.get(situation_type,{}).get("headline","")),"summary":String(built.summary),
		"occasion":{"type":String(occasion.get("type","")),"text":String(occasion_data.get("text","")),"day":int(occasion.get("day",day)),"crisis":bool(occasion.get("crisis",false))}}
	if occasion_data.has("promised_day"): (audience.situation as Dictionary)["arc"]={"branch":"promise_unkept","previous":{"day":int(occasion_data.promised_day),"decree":String(occasion_data.get("decree",""))}}
	if String(occasion.get("type",""))=="refusal_grievance": (audience.situation as Dictionary)["arc"]={"branch":"refused_ambition","previous":{"day":int(occasion_data.get("refused_day",day)),"decree":String(occasion_data.get("decree",""))}}
	return audience

static func _generate_petition(person_id:int,day:int,forced_topic:String)->Dictionary:
	## Forced petition (tests, captures): a truthful petition on that topic, or
	## the most pressing one; ignores the ledger and the budget.
	var person:=_official(person_id)
	if person.is_empty(): return {}
	var c:=conditions()
	var bands:=_condition_bands(c)
	var occasion:={"type":"debug","key":"debug","data":{"text":"a summons from the ruler"}}
	var topic:=forced_topic
	if topic=="":
		var worst:=0
		for key:String in bands:
			if int(bands[key])>worst: worst=int(bands[key]); topic=key
		if topic=="": topic="ambition"
	var built:={}
	match topic:
		"food","health","housing","security","people": built=_court_petition("condition",person,{"topic":topic},day)
		"grievance": built=_court_petition("grievance",person,{},day)
		"introduction": built=_court_petition("appointment",person,{},day)
		"war": built=_court_petition("war_council",person,{"enemy_name":"the enemy"},day)
		"follow_up": built=_court_petition("promise_followup",person,{"decree":_ambition_ladder(person)[0],"promised_day":maxi(0,day-150)},day)
		"ambition":
			var ladder:=_ambition_ladder(person)
			var decree:=_next_ambition(person,day)
			if decree=="": decree=String(ladder[0])
			built={"topic":"ambition","summary":String(AMBITION_WORDS.get(decree,"%s has a plan.")) % String(person.name),"decree":decree,"ask":"ambition:"+decree,"situation_type":"ambition"}
	if built.is_empty(): return {}
	return _court_audience(person,built,occasion,day)

static func _topic_words(topic:String)->String:
	return {"food":"the food stores","health":"the sick and the water","people":"the people growing fewer","housing":"shelter for the people","security":"the watch","grievance":"a personal grievance","ambition":"a proposal of their own",
		"introduction":"their new office","follow_up":"a promise you made","war":"the war","summons":"your summons","aim":"what the people should strive for"}.get(topic,"a matter of state")

# --------------------------------------------------------------------------
# Court bench
# --------------------------------------------------------------------------

static func court(id:String)->Array[Dictionary]:
	var audience:=find(id)
	var result:Array[Dictionary]=[]
	var speaker_id:=int(audience.get("speaker",{}).get("person_id",0)) if not audience.is_empty() else 0
	var officials:=_officials()
	# Those who came in with the god's attention (the official who named a
	# summoned person) keep their seats on the bench first.
	var first:Array=audience.get("court_pids",[]) if not audience.is_empty() and audience.get("court_pids") is Array else []
	if not first.is_empty():
		var ordered:Array[Dictionary]=[]
		for pid in first:
			for person in officials:
				if int(person.person_id)==int(pid) and not ordered.has(person): ordered.append(person)
		for person in officials:
			if not ordered.has(person): ordered.append(person)
		officials=ordered
	for person in officials:
		if int(person.person_id)==speaker_id: continue
		result.append(person)
		if result.size()>=COURT_MAX: break
	return result

# --------------------------------------------------------------------------
# Options and resolution
# --------------------------------------------------------------------------

static func _terms_text(terms:Dictionary)->String:
	if terms.is_empty(): return ""
	return "%d %s" % [roundi(float(terms.amount)),String(terms.resource)]

static func _courtesy_terms(audience:Dictionary)->Dictionary:
	## A return gift about 40% of what was offered, in whatever the player holds most of.
	var value:=float(audience.terms.get("amount",0))*0.4
	var best:="";var best_stock:=0.0
	for resource in RESOURCES:
		var stock:=player_stock(resource)
		if stock>best_stock: best_stock=stock; best=resource
	if best=="": best=String(audience.terms.get("resource","Food"))
	return {"resource":best,"amount":_nice(maxf(3.0,value))}

static func _reward_terms()->Dictionary:
	var best:="";var best_stock:=0.0
	for resource in RESOURCES:
		var stock:=player_stock(resource)
		if stock>best_stock: best_stock=stock; best=resource
	if best=="": best="Food"
	return {"resource":best,"amount":_nice(clampf(_player_population()*(0.08 if best=="Food" else 0.03),3.0,40.0))}

static func _option(id:String,label:String,sub:String,tone:String,enabled:bool=true,reason:String="")->Dictionary:
	return {"id":id,"label":label,"sub":sub,"enabled":enabled,"reason":"" if enabled else reason,"tone":tone}

static func _short(resource:String,amount:float)->String:
	var have:=player_stock(resource)
	if have+0.0001>=amount: return ""
	return "Your stores hold only %d %s." % [floori(have),resource]

static func _situation(audience:Dictionary)->Dictionary:
	return audience.get("situation",{}) if audience.get("situation") is Dictionary else {}

static func options(id:String)->Array[Dictionary]:
	var audience:=find(id)
	var result:Array[Dictionary]=[]
	if audience.is_empty() or String(audience.status)!="waiting": return result
	var terms:Dictionary=audience.terms
	var text:=_terms_text(terms)
	match String(audience.kind):
		"gift":
			var courtesy:=_courtesy_terms(audience)
			var short:=_short(String(courtesy.resource),float(courtesy.amount))
			result.append(_option("accept","Accept the gift","Receive %s from %s." % [text,audience.civ_name],"warm"))
			result.append(_option("accept_return","Accept and send a courtesy gift","Receive %s; send back %s." % [text,_terms_text(courtesy)],"warm",short=="",short))
			result.append(_option("decline","Decline it courteously","Thank them and let them take it home: no gift, and nothing owed.","neutral"))
			result.append(_option("refuse","Refuse the gift","Send it back unopened. They will take offence.","hostile"))
		"request":
			var half:={"resource":terms.resource,"amount":_nice(float(terms.amount)*0.5)}
			var short_full:=_short(String(terms.resource),float(terms.amount))
			var short_half:=_short(String(half.resource),float(half.amount))
			result.append(_option("grant","Grant it in full","Give %s to %s." % [text,audience.civ_name],"warm",short_full=="",short_full))
			result.append(_option("grant_half","Grant half","Give %s and no more." % _terms_text(half),"neutral",short_half=="",short_half))
			result.append(_option("refuse","Refuse","Keep your stores.%s" % (" They are hungry and may not forget it." if _hungry(ForeignDiplomacy.civilization(String(audience.civ_id))) else ""),"hostile"))
		"threat":
			var short_pay:=_short(String(terms.resource),float(terms.amount))
			result.append(_option("pay","Pay the tribute","Hand over %s to ease the frontier." % text,"neutral",short_pay=="",short_pay))
			result.append(_option("defy","Refuse to pay","Send the herald home empty-handed.","hostile"))
			result.append(_option("counter","Answer threat with threat","Warn them your people will meet force at the border.","hostile"))
		"news":
			var reward:=_reward_terms()
			var short_reward:=_short(String(reward.resource),float(reward.amount))
			var what:=String({"rumor_share":"Take the account into your people's record of rumors.","intelligence_share":"Add their observation of %s to what you know." % String(_situation(audience).get("city_name","the city"))}.get(_situation_type(audience),"Courteous thanks; the news is noted."))
			var reward_sub:="Send %s home with them." % _terms_text(reward)
			if _situation_type(audience)!="news_report": reward_sub=what+" "+reward_sub
			result.append(_option("thank","Thank the messenger",what,"warm"))
			result.append(_option("reward","Reward the messenger",reward_sub,"warm",short_reward=="",short_reward))
		"proposal":
			result=_proposal_options(audience)
		"great_work","wonder_proposal":
			var gwa:=_great_works()
			if gwa!=null:
				for option:Dictionary in gwa.call("options",audience): result.append(option)
		"report":
			var reward_food:=_scout_reward()
			var short_food:=_short("Food",reward_food)
			result.append(_option("reward_scouts","Well done — reward the scouts","Give the party %d Food from the stores." % roundi(reward_food),"warm",short_food=="",short_food))
			var subject:=String(audience.get("report",{}).get("subject_civ_id",""))
			if subject!="" and not CivilizationSystem._scout_target_option("contact:"+subject).is_empty():
				var proposal:Dictionary=CivilizationSystem.contact_investigation_proposal(subject)
				var sub:String=String(proposal.get("message","Send a party back to look closer.")) if proposal.get("ok",false) else "Send a party back to look closer."
				result.append(_option("send_back","Send them back for a closer look",sub,"neutral",bool(proposal.get("ok",false)),String(proposal.get("error",""))))
			result.append(_option("dismiss","Dismiss","Thank them briefly and move on.","hostile"))
		"petition":
			var petition:Dictionary=audience.petition
			var decree:=String(petition.get("suggested_decree",""))
			match String(petition.get("topic","")):
				"grievance":
					result.append(_option("apologise","Acknowledge the wrong","Admit the slight and make amends in words.","warm"))
					result.append(_option("rebuke","Rebuke them","Remind them whom they serve.","hostile"))
				"introduction":
					result.append(_option("decree","Charge them with their first task","\"%s\"" % decree,"warm",decree!="","They have no task to propose."))
					result.append(_option("welcome","Welcome them warmly","Words of confidence; no order yet.","warm"))
					result.append(_option("rebuke","Remind them of their place","Make plain that the office serves the ruler.","hostile"))
				"mourning","callback","omen":
					for lives_option:Dictionary in _lives().call("options",audience): result.append(lives_option)
				"aim":
					for aim_option:Dictionary in _aims().call("options",audience): result.append(aim_option)
				"follow_up":
					result.append(_option("decree","Issue it now","\"%s\"" % decree,"warm",decree!="","Nothing was promised."))
					result.append(_option("patience","Ask for patience","Admit it waits; promise nothing new.","neutral"))
					result.append(_option("dismiss","Refuse it outright","Tell them it will not be done.","hostile"))
				_:
					result.append(_option("decree","Issue their decree","\"%s\"" % decree,"warm",decree!="","They have no decree to propose."))
					result.append(_option("promise","Promise to consider it","Warm words, no order yet. They will remember the promise.","neutral"))
					result.append(_option("dismiss","Dismiss the petition","Send them away. They will resent it.","hostile"))
		"summons":
			result.append(_option("dismiss_summons","That will be all","Send them back to their work.","neutral"))
	# Every foreign answer shows its cost, and who at court objects.
	if String(audience.get("origin",""))=="foreign": _rivals().call("annotate_options",audience,result)
	# A summoned person may raise one of their other matters instead.
	if String(audience.get("origin",""))=="court":
		for other in _other_matters(audience):
			result.append(_option("hear:"+String(other.id),"Hear their other matter",String(other.get("summary","")),"neutral"))
	return result

static func _accord_blocker(civ_id:String,accord:String)->String:
	var forecast:=ForeignDiplomacy.forecast(civ_id,accord,"equals",false)
	if forecast.has("error"): return String(forecast.error)
	return String(forecast.get("blocker",""))

static func _league_blocker(civ_id:String,situation:Dictionary)->String:
	var c:=_commitments()
	var mode:=String(situation.get("mode","join"))
	var why:=c.eligibility(civ_id,c.terms("join_faction" if mode=="join" else "found_faction"))
	if why!="": return why
	if mode=="join":
		var assessment:=c.assessment(civ_id,c.terms("join_faction"))
		if not bool(assessment.get("accepted",false)):
			var against:Array=[]
			for member in (assessment.get("votes",{}) as Dictionary):
				if not bool(assessment.votes[member].get("accept",false)): against.append(_civ_name(String(member)))
			return "Not every member consents%s." % (": "+", ".join(against)+" would vote against" if not against.is_empty() else "")
	return ""

static func _availability(civ_id:String,action:String)->String:
	var check:=CivilizationSystem.player_action_availability(civ_id,action)
	return String(check.get("error","")) if check.has("error") else ""

static func _proposal_options(audience:Dictionary)->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	var situation:=_situation(audience)
	var civ_id:=String(audience.civ_id)
	var name:=String(audience.civ_name)
	match String(situation.get("type","")):
		"accord_offer":
			var blocker:=_accord_blocker(civ_id,String(situation.get("accord","exchange")))
			result.append(_option("accept","Agree to %s" % String(situation.get("accord_name","the understanding")).to_lower(),"Two years of shared research support; war ends it.","warm",blocker=="",blocker))
			result.append(_option("decline","Decline politely","Thank them; not now.","neutral"))
			result.append(_option("rebuff","Rebuff them","Tell them your people need nothing from theirs.","hostile"))
		"protection_pact":
			var c:=_commitments()
			var why:=c.eligibility(civ_id,c.terms("protection"))
			result.append(_option("accept","Ratify mutual protection","Answer each other's defensive sieges with feasible relief; no offensive wars.","warm",why=="",why))
			result.append(_option("decline","Decline politely","Keep your hands free.","neutral"))
			result.append(_option("rebuff","Rebuff them","Tell them your people defend themselves.","hostile"))
		"league_invitation":
			var blocker2:=_league_blocker(civ_id,situation)
			var joining:=String(situation.get("mode","join"))=="join"
			result.append(_option("accept","Join the %s" % String(situation.get("league_name","league")) if joining else "Found the %s" % String(situation.get("league_name","league")),"Consult before offensive war; relieve members under defensive siege.","warm",blocker2=="",blocker2))
			result.append(_option("decline","Decline","Stay outside any league for now.","neutral"))
		"war_support":
			var enemy_name:=String(situation.get("enemy_name","their enemy"))
			result.append(_option("stand","Stand with %s" % name,"Warmer with %s; %s will count you an enemy's friend." % [name,enemy_name],"warm"))
			result.append(_option("counsel_peace","Counsel peace","Urge both sides to stop; neither will thank you much.","neutral"))
			result.append(_option("abstain","Stay out of it","Tell them it is not your war.","hostile"))
		"peace_feeler":
			var why2:=_availability(civ_id,"seek_peace")
			result.append(_option("accept","Make peace","End the war; a one-year truce holds the present line.","warm",why2=="",why2))
			result.append(_option("refuse","Fight on","Send the envoy home; the war continues.","hostile"))
		"trade_offer":
			var why3:=_availability(civ_id,"open_trade")
			result.append(_option("accept","Open a trade compact","Standing, value-conserved exchange with %s." % name,"warm",why3=="",why3))
			result.append(_option("decline","Decline","Not now.","neutral"))
		"nonaggression_offer":
			var why4:=_availability(civ_id,"non_aggression")
			result.append(_option("accept","Agree to non-aggression","Neither people attacks the other; the frontier calms.","warm",why4=="",why4))
			result.append(_option("decline","Decline politely","Keep every option open.","neutral"))
			result.append(_option("rebuff","Rebuff them","Tell them your people make no such promises.","hostile"))
		"scholar_offer","research_sale","license_offer":
			var quote:=_research_quote(String(situation.type),civ_id,String(situation.get("subject","")))
			var price_terms:={"resource":String(situation.get("payment","Timber")),"amount":float(situation.get("payment_amount",0.0))}
			var reason:=String(quote.get("error","")) if quote.has("error") else _short(String(price_terms.resource),float(price_terms.amount))
			var label:String={"scholar_offer":"Welcome the teacher","research_sale":"Buy the study","license_offer":"Take the license"}[String(situation.type)]
			result.append(_option("accept",label,"Pay %s into their stores." % _terms_text(price_terms),"warm",reason=="",reason))
			result.append(_option("decline","Decline","Thank them for the offer.","neutral"))
		"artifact_gift":
			var gift_check:=ARTIFACTS.exchange_check(civ_id,String(situation.get("artifact_id","")),"player","gift")
			result.append(_option("accept","Accept %s" % String(situation.get("artifact_name","the object")),"It joins your collection; its history goes with it.","warm",not gift_check.has("error"),String(gift_check.get("error",""))))
			result.append(_option("decline","Decline it graciously","Let them keep their treasure.","neutral"))
			result.append(_option("rebuff","Rebuff them","Tell them you have no need of their trinkets.","hostile"))
		"artifact_purchase":
			var piece:=String(situation.get("artifact_id",""))
			var sell_check:=ARTIFACTS.exchange_check("player",piece,civ_id,"sell")
			result.append(_option("sell","Sell it","For %.0f in coin, paid from their treasury with metal backing." % float(situation.get("value",0.0)),"neutral",not sell_check.has("error"),String(sell_check.get("error",""))))
			var offered:=String(situation.get("offered_id",""))
			if offered!="":
				var trade_check:=ARTIFACTS.exchange_check("player",piece,civ_id,"trade",offered)
				result.append(_option("trade","Trade it","Take %s in exchange." % String(situation.get("offered_name","their piece")),"warm",not trade_check.has("error"),String(trade_check.get("error",""))))
			result.append(_option("decline","Keep it","Politely: it stays here.","neutral"))
			result.append(_option("rebuff","Rebuff them","Tell them it is not for sale at any price.","hostile"))
		"artifact_return":
			var give_back:={}
			if String(situation.get("mode",""))=="origin": give_back=ARTIFACTS.exchange_check("player",String(situation.get("artifact_id","")),civ_id,"gift")
			elif bool(ForeignDiplomacy.civilization(civ_id).get("player_relation",{}).get("at_war",false)): give_back={"error":"Nothing can be returned while at war."}
			var reward2:=_reward_terms()
			var short2:=_short(String(reward2.resource),float(reward2.amount))
			result.append(_option("return","Return it","Give %s back to %s." % [String(situation.get("artifact_name","it")),name],"warm",not give_back.has("error"),String(give_back.get("error",""))))
			result.append(_option("compensate","Keep it, but compensate them","Send %s instead." % _terms_text(reward2),"neutral",short2=="",short2))
			result.append(_option("refuse","Refuse","It stays where it is.","hostile"))
		"recruitment_protest":
			var blocker3:=_accord_blocker(civ_id,"restraint")
			var reward:=_reward_terms()
			var short:=_short(String(reward.resource),float(reward.amount))
			result.append(_option("restraint","Offer a border understanding","Pause recruitment visits both ways for two years and quiet the frontier.","warm",blocker3=="",blocker3))
			result.append(_option("compensate","Compensate them","Send %s for the trouble." % _terms_text(reward),"neutral",short=="",short))
			result.append(_option("defy","Reject the protest","People may go where they are welcome.","hostile"))
	return result

static func resolve(id:String,option_id:String)->Dictionary:
	var audience:=find(id)
	if audience.is_empty() or String(audience.status)!="waiting": return {"ok":false,"outcome":"No audience is waiting.","reaction":"neutral"}
	var chosen:={}
	for option in options(id):
		if String(option.id)==option_id: chosen=option
	if chosen.is_empty(): return {"ok":false,"outcome":"That answer is not open to you here.","reaction":"neutral"}
	if not bool(chosen.enabled): return {"ok":false,"outcome":String(chosen.reason),"reaction":"neutral"}
	if option_id.begins_with("hear:"): return _hear_other(audience,option_id.trim_prefix("hear:"))
	var result:Dictionary
	if String(audience.kind)=="summons":
		result={"outcome":"%s went back to their work." % String(audience.speaker.name),"reaction":"neutral"}
		audience.status="resolved"; audience.outcome=String(result.outcome); audience.option_id=option_id
		_archive(audience)
		_ledger_close(audience,option_id,"neutral",String(result.outcome))
		result["ok"]=true
		return result
	if audience.kind in WORK_KINDS:
		var gwa:=_great_works()
		if gwa==null: return {"ok":false,"outcome":"The master builder has left.","reaction":"neutral"}
		result=gwa.call("resolve",audience,option_id)
		if not bool(result.get("ok",false)): return {"ok":false,"outcome":String(result.get("outcome","That cannot be done now.")),"reaction":"neutral"}
	elif audience.kind=="proposal": result=_resolve_proposal(audience,option_id)
	elif audience.origin=="foreign": result=_resolve_foreign(audience,option_id)
	elif audience.kind=="report": result=_resolve_report(audience,option_id)
	else: result=_resolve_petition(audience,option_id)
	if result.has("error"): return {"ok":false,"outcome":String(result.error),"reaction":"neutral"}
	if String(audience.get("origin",""))=="foreign": result=_rivals().call("after_answer",audience,option_id,result)
	audience.status="resolved"
	audience.outcome=String(result.outcome)
	audience.option_id=option_id
	_archive(audience)
	_after_resolve(audience,option_id,String(result.get("reaction","neutral")))
	result["ok"]=true
	return result

static func _after_resolve(audience:Dictionary,option_id:String,reaction:String)->void:
	var day:=_day()
	_ledger_close(audience,option_id,reaction,String(audience.outcome))
	if String(audience.origin)=="foreign":
		# Re-anchor the watch so the hall's own consequences are not mistaken
		# for fresh news about this people.
		var civ_id:=String(audience.civ_id)
		var civs:Dictionary=(state().watch as Dictionary).get("civs",{})
		var civ:=ForeignDiplomacy.civilization(civ_id)
		if civs.get(civ_id) is Dictionary and not civ.is_empty():
			civs[civ_id]["o"]=float(civ.player_relation.get("opinion",0.0))
			civs[civ_id]["t"]=_tension_band(float(civ.player_relation.get("border_tension",0.0)))
		_add_sequel(audience,option_id,day)
		return
	if String(audience.kind)!="petition": return
	var pid:=int(audience.speaker.get("person_id",0))
	var petition:Dictionary=audience.petition
	var topic:=String(petition.get("topic",""))
	var decree:=String(petition.get("suggested_decree",""))
	var person:=_official(pid)
	if option_id=="promise" and decree!="":
		_add_occasion({"key":"promise:%d:%s" % [pid,decree],"type":"promise_followup","person_id":pid,"day":day,"not_before":day+150,"expires":day+420,"data":{"decree":decree,"promised_day":day,"text":"a promise left hanging"}})
	elif option_id=="dismiss" and topic in ["ambition","follow_up","introduction"] and decree!="" and float(person.get("pride",0.5))>0.55:
		_add_occasion({"key":"refused:%d:%s" % [pid,decree],"type":"refusal_grievance","person_id":pid,"day":day,"not_before":day+150,"expires":day+400,"data":{"decree":decree,"refused_day":day,"text":"a proposal the ruler dismissed"}})
	if option_id=="decree" or topic=="follow_up":
		for occasion in (state().occasions as Array).duplicate():
			if occasion is Dictionary and String(occasion.get("type",""))=="promise_followup" and int(occasion.get("person_id",0))==pid and String((occasion.get("data",{}) as Dictionary).get("decree",""))==decree: (state().occasions as Array).erase(occasion)

static func _hear_other(audience:Dictionary,matter_id:String)->Dictionary:
	## Set the present business aside (it waits again as a matter) and hear the
	## same person's other matter instead.
	var next:=open_matter(matter_id)
	if next.is_empty(): return {"ok":false,"outcome":"That matter has already been settled.","reaction":"neutral"}
	if String(audience.kind)!="summons": _file_matter(audience,[])
	audience.status="resolved"
	audience.outcome="%s set that aside to raise another matter." % String(audience.speaker.name)
	audience.option_id="hear"
	_archive(audience)
	_ledger_close(audience,"set_aside","neutral",String(audience.outcome))
	return {"ok":true,"outcome":String(audience.outcome),"reaction":"neutral","next_audience_id":String(next.id)}

static func _mood_opinion(audience:Dictionary)->float:
	return clampf(float(audience.get("mood",0.0)),-1.0,1.0)*MOOD_OPINION

static func _resolve_foreign(audience:Dictionary,option_id:String)->Dictionary:
	var civ_id:=String(audience.civ_id)
	var civ:=ForeignDiplomacy.civilization(civ_id)
	var p:=_personality(civ_id)
	var leader:=ForeignDiplomacy.leader(civ_id)
	var proud:=String(leader.get("temperament",""))=="Proud guardian"
	var terms:Dictionary=audience.terms
	var resource:=String(terms.get("resource",""))
	var amount:=float(terms.get("amount",0))
	var mood:=_mood_opinion(audience)
	var outcome:=""
	var reaction:="neutral"
	var memory:=""
	# An empty threat, called: they back down (rival_rulers.gd keeps the truth).
	if String(audience.kind)=="threat" and option_id in ["defy","counter"] and bool((audience.get("hidden",{}) as Dictionary).get("bluff",false)):
		return _rivals().call("bluff_called",audience,option_id)
	match "%s:%s" % [audience.kind,option_id]:
		"gift:accept","gift:accept_return":
			var got:=EXCHANGE.take(civ_id,resource,amount)
			var received:=EXCHANGE.receive("player",resource,got) if got>0.0 else 0.0
			outcome="You accepted %d %s from %s." % [roundi(received),resource,audience.civ_name]
			if received+0.5<amount: outcome+=" Only %d of the promised %d actually arrived." % [roundi(received),roundi(amount)]
			if option_id=="accept_return":
				var courtesy:=_courtesy_terms(audience)
				var sent:=_debit_player(String(courtesy.resource),float(courtesy.amount))
				_credit_civ(civ_id,String(courtesy.resource),sent)
				_shift_relation(civ_id,0.08+mood,-0.04)
				_leader_trust(civ_id,0.07)
				outcome+=" You sent %d %s back as a courtesy." % [roundi(sent),String(courtesy.resource)]
				reaction="delighted"
				memory="The ruler received our gift of %d %s and sent %d %s in return. A gracious house." % [roundi(received),resource,roundi(sent),String(courtesy.resource)]
			else:
				_shift_relation(civ_id,0.04+mood,-0.02)
				_leader_trust(civ_id,0.04)
				reaction="pleased"
				memory="The ruler accepted our gift of %d %s." % [roundi(received),resource]
		"gift:decline":
			_shift_relation(civ_id,-0.01+mood,0.0)
			_leader_trust(civ_id,-0.01)
			reaction="neutral"
			outcome="You declined %s's gift of %s with thanks. They took it home, a little stiffly." % [audience.civ_name,_terms_text(terms)]
			memory="The ruler declined our gift of %s, politely." % _terms_text(terms)
		"gift:refuse":
			var sting:=0.05+(0.04 if proud else 0.0)
			_shift_relation(civ_id,-sting+mood,0.02)
			_leader_trust(civ_id,-0.05)
			reaction="furious" if proud else "offended"
			outcome="You refused %s's gift of %s. It went home unopened; they are %s." % [audience.civ_name,_terms_text(terms),"deeply insulted" if proud else "offended"]
			memory="The ruler refused our gift of %s in front of their court." % _terms_text(terms)
		"request:grant","request:grant_half":
			var give:=amount if option_id=="grant" else _nice(amount*0.5)
			var sent:=_debit_player(resource,give)
			_credit_civ(civ_id,resource,sent)
			if resource=="Food" and sent>0.0: _commitments().note_food_aid(civ_id,sent,_day())
			var need_bonus:=0.03 if resource=="Food" and _hungry(civ) else 0.0
			if option_id=="grant":
				_shift_relation(civ_id,0.06+need_bonus+mood,-0.05)
				_leader_trust(civ_id,0.06)
				reaction="delighted"
				outcome="You gave %d %s to %s." % [roundi(sent),resource,audience.civ_name]
				memory="We asked for %d %s and the ruler gave all of it." % [roundi(amount),resource]
			else:
				_shift_relation(civ_id,0.02+need_bonus*0.5+mood,-0.02)
				_leader_trust(civ_id,0.02)
				reaction="neutral" if float(p.assertiveness)>0.62 else "pleased"
				outcome="You gave %d %s to %s, half of what they asked." % [roundi(sent),resource,audience.civ_name]
				memory="We asked for %d %s; the ruler gave half." % [roundi(amount),resource]
		"request:refuse":
			var hungry_and_hard:=_hungry(civ) and float(p.assertiveness)>0.55
			_shift_relation(civ_id,-0.03+mood,0.08 if hungry_and_hard else 0.0)
			_leader_trust(civ_id,-0.03)
			reaction="neutral" if float(p.empathy)>0.65 and float(civ.player_relation.get("opinion",0))>0.2 else "offended"
			outcome="You refused %s's request for %s." % [audience.civ_name,_terms_text(terms)]
			if hungry_and_hard: outcome+=" They are hungry and proud; border tension rose."
			memory="We asked the ruler for %s and were refused%s." % [_terms_text(terms)," while our children went hungry" if _hungry(civ) else ""]
		"threat:pay":
			var paid:=_debit_player(resource,amount)
			_credit_civ(civ_id,resource,paid)
			_shift_relation(civ_id,0.02+mood,-0.15)
			reaction="pleased"
			outcome="You paid %d %s in tribute to %s. The frontier eased." % [roundi(paid),resource,audience.civ_name]
			var lost:Array=[]
			for person in court(String(audience.id)):
				if float(person.get("pride",0.5))>0.6:
					GovernmentPeopleSystem.adjust_person_relationship(int(person.person_id),0,-0.05,0.01)
					GovernmentPeopleSystem.record_person_memory(int(person.person_id),"Watched the ruler pay %d %s in tribute to %s." % [roundi(paid),resource,audience.civ_name],"audience",0.5,{"emotion":"shame"})
					lost.append(String(person.name))
			if not lost.is_empty(): outcome+=" %s lost some respect for you." % ", ".join(lost)
			memory="The ruler paid our demand of %d %s. They can be pressed." % [roundi(paid),resource]
		"threat:defy":
			_shift_relation(civ_id,-0.05+mood,0.08)
			_leader_trust(civ_id,-0.04)
			var requested:="call_bluff" if float(p.assertiveness)>0.6 and float(p.risk_tolerance)>0.5 else "warn"
			var posture:=ForeignDiplomacy.apply_conversation_reaction(civ_id,requested,"We will not pay your tribute.","The ruler refused our demand for %s." % _terms_text(terms))
			var actual:=String(posture.get("actual","unchanged"))
			reaction="furious" if actual in ["harden_border","mobilize","call_bluff"] else "offended"
			outcome="You refused %s's demand for %s. %s" % [audience.civ_name,_terms_text(terms),_posture_words(actual,String(audience.civ_name))]
			memory="The ruler refused our demand for %s." % _terms_text(terms)
		"threat:counter":
			_leader_trust(civ_id,-0.05)
			var posture2:=ForeignDiplomacy.apply_conversation_reaction(civ_id,"harden_border","Our armies will meet yours at the border if you come for what is ours.","The ruler answered our demand with a threat of their own.")
			var actual2:=String(posture2.get("actual","unchanged"))
			if mood!=0.0: _shift_relation(civ_id,mood,0.0)
			reaction="furious" if actual2 in ["harden_border","mobilize","call_bluff"] or float(p.assertiveness)>0.55 else "offended"
			outcome="You answered %s's demand with a threat of force. %s" % [audience.civ_name,_posture_words(actual2,String(audience.civ_name))]
			memory="The ruler answered our demand with threats."
		"news:thank":
			_shift_relation(civ_id,0.015+mood,0.0)
			var learned:=_take_news(audience)
			reaction="pleased"
			outcome="You thanked %s's messenger for news of %s.%s" % [audience.civ_name,String(audience.news.get("subject_civ_name","a neighbor")),learned]
			memory="Our messenger brought the ruler news and was thanked."
		"news:reward":
			var reward:=_reward_terms()
			var sent2:=_debit_player(String(reward.resource),float(reward.amount))
			_credit_civ(civ_id,String(reward.resource),sent2)
			_shift_relation(civ_id,0.04+mood,0.0)
			_leader_trust(civ_id,0.03)
			var learned2:=_take_news(audience) if _situation_type(audience)!="news_report" else ""
			reaction="delighted"
			outcome="You rewarded %s's messenger with %d %s.%s" % [audience.civ_name,roundi(sent2),String(reward.resource),learned2]
			memory="Our messenger came home with %d %s from the ruler's hand." % [roundi(sent2),String(reward.resource)]
	if memory!="": ForeignDiplomacy.remember(civ_id,memory)
	return {"outcome":outcome,"reaction":reaction}

static func _take_news(audience:Dictionary)->String:
	## What the ruler actually learns from a messenger, through the real ledgers.
	var situation:=_situation(audience)
	var civ_id:=String(audience.civ_id)
	var day:=_day()
	match String(situation.get("type","")):
		"rumor_share":
			var net:=CivilizationSystem.rumor_network as RUMORS
			var lead_id:=String(situation.get("lead_id",""))
			var lead:Dictionary=net.books.get(civ_id,{}).get(lead_id,{}) if net!=null else {}
			if lead.is_empty(): return " The account had grown too muddled to keep."
			if net.receive("player",net.packet(lead,civ_id),day): return " The account of %s is now in your people's record of rumors." % String(lead.get("name","them"))
			return " Your people already held that account."
		"intelligence_share":
			var intel:=CivilizationSystem.city_intelligence as INTEL
			var city_id:=String(situation.get("city_id",""))
			var record:Dictionary=intel.records.get(civ_id,{}).get(city_id,{}) if intel!=null else {}
			if record.is_empty(): return " Their record of the city could not be found."
			var copy:=record.duplicate(true)
			copy["source"]="shared by %s" % String(audience.civ_name)
			intel.publish("player",copy,day)
			return " Their observation of %s (day %d) is now in your city reports." % [String(record.get("name","the city")),int(record.get("observed_day",0))]
	var subject_id:=String(audience.news.get("subject_civ_id",""))
	var subject_index:=_civ_index(subject_id)
	if subject_index>=0 and not ForeignDiplomacy.civilization(subject_id).is_empty():
		var subject:Dictionary=WorldSimulation.world.civilizations[subject_index]
		var relation:Dictionary=subject.player_relation
		relation["contact_intelligence"]=clampf(float(relation.get("contact_intelligence",0))+0.05,0.0,1.0)
		subject["player_relation"]=relation
		WorldSimulation.world.civilizations[subject_index]=subject
		return " What you know of %s grew a little." % String(subject.get("name",subject_id))
	return ""

static func _ratify_accord(civ_id:String,accord:String)->Dictionary:
	## The envoy carries the proposal here, so no delegation needs to travel;
	## the same blockers, bonus and two-year term as a returned proposal apply.
	var blocker:=_accord_blocker(civ_id,accord)
	if blocker!="": return {"error":blocker}
	var leader:=ForeignDiplomacy.leader(civ_id)
	var day:=_day()
	var entry:Dictionary=ForeignDiplomacy.ACCORDS[accord]
	leader.counter={}
	leader.accord={"kind":accord,"until":day+730,"bonus":0.12}
	leader["audience_day"]=day
	leader.trust=clampf(float(leader.trust)+0.12,-1.0,1.0)
	_shift_relation(civ_id,0.06,-0.25 if accord=="restraint" else 0.0)
	SOCIETY.accept_accord(civ_id,accord,String(entry.domain),0.12,day+730)
	var message:="You agreed to %s with %s. Both peoples gain 12%% support for %s research for two years; war ends it." % [String(entry.name).to_lower(),_civ_name(civ_id),String(entry.domain)]
	if accord=="restraint": message+=" Recruitment visits pause both ways and the frontier quiets."
	ForeignDiplomacy.remember(civ_id,message)
	return {"ok":true,"message":message}

static func _resolve_proposal(audience:Dictionary,option_id:String)->Dictionary:
	var situation:=_situation(audience)
	var civ_id:=String(audience.civ_id)
	var name:=String(audience.civ_name)
	var mood:=_mood_opinion(audience)
	var p:=_personality(civ_id)
	var outcome:=""
	var reaction:="neutral"
	var memory:=""
	var type:=String(situation.get("type",""))
	if option_id=="decline":
		_shift_relation(civ_id,-0.02+mood,0.0)
		reaction="neutral" if float(p.empathy)>0.5 else "offended"
		outcome="You declined %s's proposal. They noted it." % name
		memory="The ruler declined our proposal (%s)." % String(SITUATIONS.get(type,{}).get("headline","a proposal"))
	elif option_id=="rebuff":
		_shift_relation(civ_id,-0.06+mood,0.03)
		_leader_trust(civ_id,-0.05)
		reaction="furious" if float(p.assertiveness)>0.6 else "offended"
		outcome="You rebuffed %s's proposal before the court. They are %s." % [name,"angry" if reaction=="furious" else "offended"]
		memory="The ruler rebuffed our proposal in front of their court."
	else:
		match "%s:%s" % [type,option_id]:
			"accord_offer:accept","recruitment_protest:restraint":
				var ratified:=_ratify_accord(civ_id,"restraint" if option_id=="restraint" else String(situation.get("accord","exchange")))
				if ratified.has("error"): return ratified
				if mood!=0.0: _shift_relation(civ_id,mood,0.0)
				reaction="delighted"
				outcome=String(ratified.message)
			"protection_pact:accept":
				var c:=_commitments()
				var why:=c.eligibility(civ_id,c.terms("protection"))
				if why!="": return {"error":why}
				c.state.pacts[civ_id]={"since":_day(),"trigger":"defensive_siege","obligation":COMMITMENTS.OBLIGATION}
				outcome="Mutual protection with %s is ratified. It covers defensive sieges beginning after today, subject to real forces, provisions and access; it does not authorize offensive wars." % name
				c.record(outcome)
				_shift_relation(civ_id,0.05+mood,-0.03)
				_leader_trust(civ_id,0.08)
				reaction="delighted"
				memory=outcome
			"league_invitation:accept":
				var blocker:=_league_blocker(civ_id,situation)
				if blocker!="": return {"error":blocker}
				var c2:=_commitments()
				var day:=_day()
				if String(situation.get("mode","join"))=="join":
					var league:Dictionary=c2.faction(civ_id)
					var assessment:=c2.assessment(civ_id,c2.terms("join_faction"))
					(league.members as Array).append("player")
					league.joined["player"]=day
					league.votes=assessment.votes
					outcome="The members consent: your people join the %s." % String(league.name)
				else:
					var goal:=String(situation.get("goal","defense"))
					(c2.state.factions as Array).append({"id":"league_hall_%d" % _serial_of(audience),"name":"League of %s" % name,"members":["player",civ_id],"joined":{"player":day,civ_id:day},"goal":goal,"since":day,"votes":{},"obligation":COMMITMENTS.OBLIGATION})
					outcome="The League of %s is founded with your people, devoted to %s. Each member keeps its leader, people and army." % [name,String(COMMITMENTS.GOALS[goal]).to_lower()]
				c2.record(outcome)
				_shift_relation(civ_id,0.05+mood,-0.02)
				_leader_trust(civ_id,0.06)
				reaction="delighted"
				memory=outcome
			"war_support:stand":
				var enemy:=String(situation.get("enemy",""))
				_shift_relation(civ_id,0.08+mood,-0.03)
				_leader_trust(civ_id,0.05)
				if not ForeignDiplomacy.civilization(enemy).is_empty():
					_shift_relation(enemy,-0.07,0.07)
					ForeignDiplomacy.remember(enemy,"The ruler declared for %s in its war against us." % name)
				reaction="delighted"
				outcome="You declared for %s in its war with %s. %s warms to you; %s will not forget it. No troops were promised." % [name,String(situation.get("enemy_name","its enemy")),name,String(situation.get("enemy_name","its enemy"))]
				memory="The ruler stood with us against %s." % String(situation.get("enemy_name","our enemy"))
			"war_support:counsel_peace":
				var enemy2:=String(situation.get("enemy",""))
				_shift_relation(civ_id,-0.01+mood,0.0)
				if not ForeignDiplomacy.civilization(enemy2).is_empty(): _shift_relation(enemy2,0.02,0.0)
				reaction="neutral"
				outcome="You urged %s and %s to make peace. Neither side has moved." % [name,String(situation.get("enemy_name","its enemy"))]
				memory="The ruler told us to make peace rather than choose a side."
			"war_support:abstain":
				_shift_relation(civ_id,-0.03+mood,0.0)
				reaction="offended" if float(p.assertiveness)>0.5 else "neutral"
				outcome="You told %s its war with %s is not yours." % [name,String(situation.get("enemy_name","its enemy"))]
				memory="The ruler would not stand with us against %s." % String(situation.get("enemy_name","our enemy"))
			"peace_feeler:accept","trade_offer:accept","nonaggression_offer:accept":
				var action:String={"peace_feeler":"seek_peace","trade_offer":"open_trade","nonaggression_offer":"non_aggression"}[type]
				var done:=CivilizationSystem.conduct_player_action(civ_id,action,true)
				if done.has("error"): return {"error":String(done.error)}
				if mood!=0.0: _shift_relation(civ_id,mood,0.0)
				reaction="delighted" if type=="peace_feeler" else "pleased"
				outcome=String(done.get("message","It is agreed."))
				memory=outcome
			"peace_feeler:refuse":
				var posture:=ForeignDiplomacy.apply_conversation_reaction(civ_id,"warn","We will not make peace on these terms.","The ruler turned our peace envoy away.")
				_shift_relation(civ_id,-0.03+mood,0.0)
				reaction="offended"
				outcome="You sent %s's peace envoy home. The war goes on. %s" % [name,_posture_words(String(posture.get("actual","unchanged")),name)]
				memory="The ruler refused our offer of peace."
			"scholar_offer:accept","research_sale:accept","license_offer:accept":
				var subject:=String(situation.get("subject",""))
				var payment:=String(situation.get("payment",""))
				var amount:=float(situation.get("payment_amount",0.0))
				var short_pay:=_short(payment,amount)
				if short_pay!="": return {"error":short_pay}
				var price_text:=_terms_text({"resource":payment,"amount":amount})
				var sent:Dictionary
				match type:
					"scholar_offer": sent=SCHOLARS.host_from_envoy(civ_id,subject,_travel_days(civ_id))
					"research_sale": sent=PURCHASE.deliver_from_envoy(civ_id,name,subject,price_text)
					_: sent=LICENSES.grant_from_envoy(civ_id,subject)
				if sent.has("error"): return {"error":String(sent.error)}
				var paid_goods:=_debit_player(payment,amount)
				_credit_civ(civ_id,payment,paid_goods)
				_shift_relation(civ_id,0.03+mood,0.0)
				reaction="pleased"
				outcome="You paid %d %s to %s. %s" % [roundi(paid_goods),payment,name,String(sent.get("message",""))]
				memory="The ruler paid %s for our offer concerning %s." % [price_text,String(situation.get("subject_name",subject))]
			"artifact_gift:accept":
				var got:=ARTIFACTS.exchange(civ_id,String(situation.get("artifact_id","")),"player","gift")
				if got.has("error"): return {"error":String(got.error)}
				_shift_relation(civ_id,0.05+mood,-0.02)
				_leader_trust(civ_id,0.05)
				reaction="delighted"
				outcome="You accepted %s from %s; it is now in your collection." % [String(situation.get("artifact_name","the object")),name]
				memory="The ruler accepted %s from our hands." % String(situation.get("artifact_name","our gift"))
			"artifact_purchase:sell","artifact_purchase:trade":
				var piece:=String(situation.get("artifact_id",""))
				var done:=ARTIFACTS.exchange("player",piece,civ_id,option_id,String(situation.get("offered_id","")) if option_id=="trade" else "")
				if done.has("error"): return {"error":String(done.error)}
				_shift_relation(civ_id,0.04+mood,0.0)
				reaction="pleased"
				outcome=("You sold %s to %s for %.0f in coin." % [String(situation.get("artifact_name","the piece")),name,float(done.get("value",0.0))]) if option_id=="sell" else ("You traded %s to %s for %s." % [String(situation.get("artifact_name","the piece")),name,String(situation.get("offered_name","their piece"))])
				memory="The ruler let us have %s." % String(situation.get("artifact_name","the piece"))
			"artifact_return:return":
				var returned:Dictionary
				if String(situation.get("mode",""))=="looted": returned=RIVALRY.return_loot(civ_id,String(situation.get("work_id","")))
				else: returned=ARTIFACTS.exchange("player",String(situation.get("artifact_id","")),civ_id,"gift")
				if returned.has("error"): return {"error":String(returned.error)}
				_shift_relation(civ_id,0.06+mood,-0.04)
				_leader_trust(civ_id,0.06)
				reaction="delighted"
				outcome="You returned %s to %s.%s" % [String(situation.get("artifact_name","the piece")),name,(" "+String(returned.get("message",""))) if returned.has("message") else ""]
				memory="The ruler returned %s to us." % String(situation.get("artifact_name","our treasure"))
			"artifact_return:compensate":
				var reward3:=_reward_terms()
				var paid3:=_debit_player(String(reward3.resource),float(reward3.amount))
				_credit_civ(civ_id,String(reward3.resource),paid3)
				_shift_relation(civ_id,-0.01+mood,0.0)
				reaction="offended" if float(p.assertiveness)>0.6 else "neutral"
				outcome="You kept %s and sent %d %s to %s instead." % [String(situation.get("artifact_name","the piece")),roundi(paid3),String(reward3.resource),name]
				memory="The ruler kept %s and paid us off with %d %s." % [String(situation.get("artifact_name","our treasure")),roundi(paid3),String(reward3.resource)]
			"artifact_return:refuse":
				var posture3:=ForeignDiplomacy.apply_conversation_reaction(civ_id,"warn","It stays with us.","The ruler refused to return %s." % String(situation.get("artifact_name","our treasure")))
				_shift_relation(civ_id,-0.06+mood,0.04)
				_leader_trust(civ_id,-0.05)
				reaction="furious" if String(situation.get("mode",""))=="looted" else "offended"
				outcome="You refused to return %s to %s. %s" % [String(situation.get("artifact_name","the piece")),name,_posture_words(String(posture3.get("actual","unchanged")),name)]
				memory="The ruler refused to return %s." % String(situation.get("artifact_name","our treasure"))
			"recruitment_protest:compensate":
				var reward:=_reward_terms()
				var paid:=_debit_player(String(reward.resource),float(reward.amount))
				_credit_civ(civ_id,String(reward.resource),paid)
				_shift_relation(civ_id,0.04+mood,-0.03)
				reaction="neutral"
				outcome="You sent %d %s to %s for the trouble your recruiters caused." % [roundi(paid),String(reward.resource),name]
				memory="The ruler paid %d %s for luring our households; the practice has not been renounced." % [roundi(paid),String(reward.resource)]
			"recruitment_protest:defy":
				var posture2:=ForeignDiplomacy.apply_conversation_reaction(civ_id,"warn","People may go where they are welcome.","The ruler rejected our protest over their recruiters.")
				_shift_relation(civ_id,-0.04+mood,0.04)
				reaction="furious" if float(p.assertiveness)>0.6 else "offended"
				outcome="You rejected %s's protest. %s" % [name,_posture_words(String(posture2.get("actual","unchanged")),name)]
				memory="The ruler rejected our protest over their recruiters."
			_:
				return {"error":"That answer is not open to you here."}
	if memory!="" and not type in ["accord_offer"]: ForeignDiplomacy.remember(civ_id,memory)
	return {"outcome":outcome,"reaction":reaction}

static func _posture_words(actual:String,name:String)->String:
	match actual:
		"call_bluff": return "%s means to call your bluff; the frontier is close to open conflict." % name
		"mobilize": return "%s is mustering fighters and hardening its border." % name
		"harden_border": return "%s is hardening its border." % name
		"warn": return "%s answered with a warning but did not move." % name
		"conciliate": return "%s chose to calm matters." % name
	return "%s made no change in its posture." % name

static func _resolve_petition(audience:Dictionary,option_id:String)->Dictionary:
	if String((audience.get("petition",{}) as Dictionary).get("topic","")) in ["mourning","callback","omen"]: return _lives().call("resolve",audience,option_id)
	if String((audience.get("petition",{}) as Dictionary).get("topic",""))=="aim": return _aims().call("resolve",audience,option_id)
	var pid:=int(audience.speaker.person_id)
	var person:=_official(pid)
	var name:=String(audience.speaker.name)
	var petition:Dictionary=audience.petition
	var mood:=_mood_opinion(audience)
	var pride:=float(person.get("pride",0.5))
	var suspicion:=float(person.get("suspicion",0.5))
	var outcome:=""
	var reaction:="neutral"
	var memory:=""
	var emotion:="duty"
	var topic:=String(petition.get("topic",""))
	match option_id:
		"decree":
			GovernmentPeopleSystem.adjust_person_relationship(pid,0.06+mood,0.03,-0.03)
			reaction="delighted"; emotion="vindicated"
			outcome="You took up %s's petition and ordered: \"%s\"." % [name,String(petition.suggested_decree)]
			memory="Petitioned about %s; the ruler issued my decree: %s." % [_topic_words(topic),String(petition.suggested_decree)]
			if topic=="follow_up": memory="The ruler kept a promise to me at last and ordered: %s." % String(petition.suggested_decree)
		"promise":
			GovernmentPeopleSystem.adjust_person_relationship(pid,0.02+mood,0.0,-0.01)
			reaction="neutral" if suspicion>0.6 else "pleased"; emotion="hope"
			outcome="You promised %s the matter of %s would be considered. No order has been given." % [name,_topic_words(topic)]
			memory="Petitioned about %s; the ruler promised to consider it." % _topic_words(topic)
		"dismiss":
			GovernmentPeopleSystem.adjust_person_relationship(pid,-0.03+mood,0.0,0.05 if topic!="follow_up" else 0.08)
			reaction="furious" if pride>0.7 or topic=="follow_up" else "offended"; emotion="slighted"
			outcome="You dismissed %s's petition. Their resentment rose." % name if topic!="follow_up" else "You told %s the promised matter will not be done. They feel deceived." % name
			memory="Petitioned about %s and was dismissed." % _topic_words(topic) if topic!="follow_up" else "The ruler broke a promise to me: %s will not be done." % String(petition.suggested_decree)
		"patience":
			GovernmentPeopleSystem.adjust_person_relationship(pid,-0.01+mood,0.0,0.02)
			reaction="offended" if pride>0.65 else "neutral"; emotion="doubt"
			outcome="You asked %s for patience. The promise still stands, unkept." % name
			memory="Reminded the ruler of a promise and was asked for patience."
		"welcome":
			GovernmentPeopleSystem.adjust_person_relationship(pid,0.04+mood,0.02,-0.02)
			reaction="pleased"; emotion="hope"
			outcome="You welcomed %s to their office with words of confidence." % name
			memory="Presented myself to the ruler and was welcomed."
		"apologise":
			GovernmentPeopleSystem.adjust_person_relationship(pid,0.05+mood,0.0,-0.08)
			reaction="pleased"; emotion="relief"
			outcome="You acknowledged %s's grievance. Their resentment eased." % name
			memory="Brought a grievance before the ruler, who acknowledged the wrong."
		"rebuke":
			GovernmentPeopleSystem.adjust_person_relationship(pid,-0.05+mood,0.02,0.06)
			reaction="furious" if pride>0.65 else "offended"; emotion="anger"
			outcome="You rebuked %s before the court. They will remember it." % name
			memory="Brought a grievance before the ruler and was rebuked in front of the court." if topic=="grievance" else "Presented myself to the ruler and was put in my place."
	if memory!="": GovernmentPeopleSystem.record_person_memory(pid,memory,"audience",0.6,{"emotion":emotion,"outcome":option_id})
	return {"outcome":outcome,"reaction":reaction}

static func _scout_reward()->float:
	return _nice(clampf(_player_population()*0.05,5.0,30.0))

static func _resolve_report(audience:Dictionary,option_id:String)->Dictionary:
	var pid:=int(audience.speaker.get("person_id",0))
	var name:=String(audience.speaker.name)
	var report:Dictionary=audience.get("report",{})
	var subject:=String(report.get("subject_name","what they found"))
	if subject=="": subject="what they found"
	var mood:=_mood_opinion(audience)
	var outcome:=""
	var reaction:="neutral"
	var memory:=""
	match option_id:
		"reward_scouts":
			var paid:=_debit_player("Food",_scout_reward())
			if pid>0: GovernmentPeopleSystem.adjust_person_relationship(pid,0.05+mood,0.02,-0.02)
			reaction="delighted"
			outcome="You rewarded %s's scouts with %d Food for their report on %s." % [name,roundi(paid),subject]
			memory="Reported on %s; the ruler rewarded my scouts with %d Food." % [subject,roundi(paid)]
		"send_back":
			var sent:Dictionary=CivilizationSystem.investigate_known_contact(String(report.get("subject_civ_id","")))
			if sent.has("error"):
				outcome="The scouts could not be sent back: %s" % String(sent.error)
			else:
				if pid>0: GovernmentPeopleSystem.adjust_person_relationship(pid,0.02+mood,0.02,0.0)
				outcome="You sent %s's scouts back to look closer at %s. %s" % [name,subject,String(sent.get("message",""))]
				reaction="pleased"
				memory="Reported on %s; the ruler sent us back for a closer look." % subject
		"dismiss":
			if pid>0: GovernmentPeopleSystem.adjust_person_relationship(pid,-0.02+mood,0.0,0.03)
			reaction="offended"
			outcome="You heard %s's report on %s and dismissed them." % [name,subject]
			memory="Reported on %s; the ruler barely listened." % subject
	if memory!="" and pid>0: GovernmentPeopleSystem.record_person_memory(pid,memory,"audience",0.5,{"emotion":"pride" if reaction=="delighted" else "duty","outcome":option_id})
	return {"outcome":outcome,"reaction":reaction}

static func enqueue(record:Dictionary)->Dictionary:
	## Accept a prebuilt audience (used for Chief Scout "report" and great works).
	## The hall assigns id, dates and status, records it in the ledger and counts
	## it against the budget. Reports are never refused for a full antechamber;
	## the oldest waiting petition is set aside (without penalty) to make room.
	## Returns the stored audience, or {} when the record is invalid.
	var kind:=String(record.get("kind","report"))
	if kind not in KINDS: return {}
	var origin:=String(record.get("origin","court" if kind in COURT_KINDS else "foreign"))
	if origin not in ["foreign","court"] or (origin=="court")!=(kind in COURT_KINDS): return {}
	var speaker:Variant=record.get("speaker",{})
	if not speaker is Dictionary or String(speaker.get("name","")).strip_edges()=="": return {}
	var day:=_day()
	var audience:=_new_audience(origin,kind,day)
	audience.speaker={"name":String(speaker.name).substr(0,100),"title":String(speaker.get("title","")).substr(0,100),
		"person_id":int(speaker.get("person_id",0)) if _num(speaker.get("person_id",0)) else 0,"role":"official" if origin=="court" else "envoy"}
	audience.civ_id=String(record.get("civ_id","")).substr(0,64)
	audience.civ_name=String(record.get("civ_name","")).substr(0,100)
	if kind=="report":
		var report:Variant=record.get("report",{})
		if not _valid_report(report): return {}
		audience.report=(report as Dictionary).duplicate(true)
		if audience.civ_id=="": audience.civ_id=String(report.get("subject_civ_id",""))
		if audience.civ_name=="": audience.civ_name=String(report.get("subject_name",""))
	elif kind=="wonder_proposal":
		var gwp:=_great_works()
		var pitch:Variant=record.get("wonder_proposal",{})
		if gwp==null or not bool(gwp.call("valid_proposal",pitch)): return {}
		audience["wonder_proposal"]=(pitch as Dictionary).duplicate(true)
	elif kind=="great_work":
		var gwa:=_great_works()
		var facts:Variant=record.get("great_work",{})
		if gwa==null or not bool(gwa.call("valid",facts)): return {}
		audience["great_work"]=(facts as Dictionary).duplicate(true)
		if record.get("petition",{}) is Dictionary: audience.petition=(record.get("petition",{}) as Dictionary).duplicate(true)
		# A stage gate waits as long as the council does; other matters keep the usual patience.
		if _num(record.get("expires_day",null)) and int(record.expires_day)>day: audience.expires_day=mini(int(record.expires_day),day+120)
	else:
		for key in ["terms","news","petition","situation"]:
			if record.get(key,{}) is Dictionary: audience[key]=(record.get(key,{}) as Dictionary).duplicate(true)
	var lines:Array=[]
	if record.get("lines") is Array:
		for line in record.lines:
			if line is Dictionary: lines.append(line)
	if not _valid_audience(audience): return {}
	if origin=="court" and not bool(record.get("summoned",false)) and not _court_direct:
		# Only envoys come uninvited. Court business waits as a matter on its
		# holder until the ruler summons them; nothing is enqueued.
		_file_matter(audience,lines)
		return {}
	if origin=="court":
		# Heard now at the ruler's call: the same matter no longer waits.
		var matter_key:=_matter_key(audience,_matter_holder(audience))
		for m in (state().matters as Array).duplicate():
			if m is Dictionary and String(m.get("key",""))==matter_key: (state().matters as Array).erase(m)
	if waiting().size()>=QUEUE_MAX:
		for old in waiting():
			if old.kind=="petition":
				old.status="expired"
				old.outcome="Set aside so %s could be heard; %s may ask again." % ["a great work" if kind in WORK_KINDS else "the scouts' report",String(old.speaker.name)]
				_ledger_close(old,"set_aside","neutral",String(old.outcome))
				_archive(old)
				break
	_enqueue(audience,day,true)
	for line in lines: append_line(String(audience.id),line)
	return audience

static func room_for(category:String="routine")->bool:
	## Pacing hook kept for older callers. Court business now becomes matters,
	## which need no budget; this only reports whether an envoy could arrive.
	if WorldSimulation.actor_id!="player": return false
	var s:=state()
	var day:=_day()
	if waiting().size()>=QUEUE_MAX or day-int(s.last_arrival_day)<MIN_GAP: return false
	if category=="urgent": return true
	return day>=int(s.next_any)

static func _valid_report(report:Variant)->bool:
	if not report is Dictionary: return false
	if not report.get("facts",[]) is Array or (report.get("facts",[]) as Array).size()>REPORT_FACTS_MAX: return false
	for fact in report.get("facts",[]):
		if fact is String:
			if String(fact).length()>600: return false
		elif fact is Dictionary:
			if JSON.stringify(fact).length()>1200: return false
		else: return false
	if not report.get("subject_civ_id","") is String or not report.get("subject_name","") is String: return false
	if report.has("source") and report.source not in REPORT_SOURCES: return false
	if report.has("observed_day") and not _num(report.observed_day): return false
	return true

## Wonder proposals: the ruler's current pick and a vision described in words.
static func proposal_choice(id:String,choice:Dictionary)->Dictionary:
	var audience:=find(id)
	var gwp:=_great_works()
	if audience.is_empty() or String(audience.status)!="waiting" or audience.kind!="wonder_proposal" or gwp==null: return {"error":"No proposal is before you."}
	return gwp.call("set_choice",audience,choice)

static func proposal_describe(id:String,text:String,mapping:Dictionary={})->Dictionary:
	var audience:=find(id)
	var gwp:=_great_works()
	if audience.is_empty() or String(audience.status)!="waiting" or audience.kind!="wonder_proposal" or gwp==null: return {"error":"No proposal is before you."}
	return gwp.call("describe",audience,text,mapping)

static func defer(id:String)->void:
	var audience:=find(id)
	if audience.is_empty() or String(audience.status)!="waiting": return
	audience["deferred_day"]=_day()

static func conclude(id:String,outcome:String,option_id:String="concluded")->void:
	## Close a waiting audience whose business ended outside the option cards
	## (e.g. the ruler dismissed a settlement leader from office in court).
	var audience:=find(id)
	if audience.is_empty() or String(audience.status)!="waiting": return
	audience.status="resolved"
	audience.outcome=outcome.substr(0,600)
	audience.option_id=option_id.substr(0,40)
	_archive(audience)
	_ledger_close(audience,audience.option_id,"neutral",audience.outcome)

# --------------------------------------------------------------------------
# Scene support
# --------------------------------------------------------------------------

static func append_line(id:String,line:Dictionary)->void:
	var audience:=find(id)
	if audience.is_empty(): return
	var clean:={
		"speaker":String(line.get("speaker","")).substr(0,80),
		"role":String(line.get("role","narrator")) if String(line.get("role","")) in ["envoy","official","ruler","narrator"] else "narrator",
		"person_id":int(line.get("person_id",0)) if (line.get("person_id",0) is int or line.get("person_id",0) is float) else 0,
		"civ_id":String(line.get("civ_id","")).substr(0,64),
		"text":String(line.get("text","")).strip_edges().substr(0,1200),
		"day":int(line.get("day",_day())) if (line.get("day") is int or line.get("day") is float) else _day(),
		"aside":bool(line.get("aside",false)),
	}
	if clean.text=="": return
	var lines:Array=audience.lines
	lines.append(clean)
	while lines.size()>LINES_MAX: lines.remove_at(0)

static func apply_mood(id:String,shift:float)->void:
	var audience:=find(id)
	if audience.is_empty() or String(audience.status)!="waiting" or not is_finite(shift): return
	audience.mood=clampf(float(audience.get("mood",0.0))+clampf(shift,-0.25,0.25),-1.0,1.0)

static func _words(value:float,bands:Array)->String:
	## bands: [[threshold,word],...] ascending; first threshold value<= wins.
	for band in bands:
		if value<=float(band[0]): return String(band[1])
	return String(bands[-1][1])

static func _known_numbers(audience:Dictionary,c:Dictionary)->Dictionary:
	## Exact figures the speakers may state when the ruler asks. A figure the
	## state does not know is simply absent, so the speaker says so.
	var numbers:={"food_days":maxi(0,roundi(float(c.food_days))),"population":roundi(float(c.population)),
		"days_waiting":maxi(0,_day()-int(audience.get("arrived_day",_day()))),"days_until_leaving":maxi(0,int(audience.get("expires_day",_day()))-_day())}
	var water:Dictionary=GameState.water_metrics
	if float(water.get("required_today",0.0))>0.0 and _num(water.get("stored",null)): numbers["water_days"]=maxi(0,floori(float(water.stored)/float(water.required_today)))
	var housing:=float(GameState.housing_capacity)
	if housing>0.0 and float(c.population)>housing: numbers["homeless"]=roundi(float(c.population)-housing)
	if String(audience.get("origin",""))=="foreign":
		var civ:=ForeignDiplomacy.civilization(String(audience.civ_id))
		if not civ.is_empty():
			numbers["their_population"]=roundi(float(civ.get("population",0)))
			numbers["their_food_days"]=maxi(0,roundi(float(civ.get("food_days",0))))
	var report:Dictionary=audience.get("report",{}) if audience.get("report") is Dictionary else {}
	if not report.is_empty():
		if _num(report.get("observed_day",null)): numbers["days_since_seen"]=maxi(0,_day()-int(report.observed_day))
		for fact in report.get("facts",[]):
			if not fact is Dictionary: continue
			var key:=String(fact.get("key",fact.get("kind","")))
			var value:Variant=fact.get("value",null)
			if not _num(value): continue
			if key=="population": numbers["their_population"]=roundi(float(value))
			elif key in ["garrison","troops","soldiers"]: numbers["soldiers_seen"]=roundi(float(value))
	return numbers

static func voice_context(id:String)->Dictionary:
	var audience:=find(id)
	if audience.is_empty(): return {}
	var c:=conditions()
	var context:={
		"audience_id":id,"origin":audience.origin,"kind":audience.kind,"status":audience.status,
		"speaker":(audience.speaker as Dictionary).duplicate(),"terms":(audience.terms as Dictionary).duplicate(),"terms_text":_terms_text(audience.terms),
		"news":(audience.news as Dictionary).duplicate(),"petition":(audience.petition as Dictionary).duplicate(),"report":(audience.get("report",{}) as Dictionary).duplicate(true),
		"situation":_situation(audience).duplicate(true),"situation_type":_situation_type(audience),
		"days_waiting":_day()-int(audience.arrived_day),"days_until_leaving":int(audience.expires_day)-_day(),"mood":float(audience.mood),
		"player_settlement":String(GameState.settlement_name),"player_population":roundi(float(c.population)),
		"food_situation":_words(float(c.food_days),[[7,"the stores are nearly empty"],[16,"food is short"],[35,"food is adequate but not generous"],[1e9,"the stores are well stocked"]]),
		"health_situation":_words(float(c.health),[[0.45,"sickness is widespread"],[0.62,"many are unwell"],[1e9,"people are mostly healthy"]]),
		"housing_situation":"some people lack shelter" if float(c.housing_ratio)<1.0 else "everyone has a roof",
		"court":[],
		"history_with_speaker":history_with(_speaker_key(audience),3,id),
		"history_with_civ":[],
	}
	if String(audience.civ_id)!="": context["history_with_civ"]=history_with("civ:"+String(audience.civ_id),3,id)
	context["numbers"]=_known_numbers(audience,c)
	if not audience.terms.is_empty():
		context["player_stock_of_terms"]=floori(player_stock(String(audience.terms.resource)))
	for person in court(id):
		context.court.append({"name":String(person.name),"title":String(person.get("office_title","")),"person_id":int(person.person_id),"disposition":String(GovernmentPeopleSystem.leader_disposition(person).get("id","pragmatic")),"traits":(person.get("traits",[]) as Array).duplicate(),"regard":_regard_words(DIVINE.regard(person))})
	context["recent_acts_of_the_god"]=_divine_history()
	if audience.origin=="foreign":
		var civ:=ForeignDiplomacy.civilization(String(audience.civ_id))
		var leader:=ForeignDiplomacy.leader(String(audience.civ_id))
		var relation:Dictionary=civ.get("player_relation",{})
		var wars:Array=[]
		if bool(relation.get("at_war",false)): wars.append("at war with the ruler's people")
		for other_id in (civ.get("relations",{}) as Dictionary):
			if bool(civ.relations[other_id].get("at_war",false)):
				var index:=_civ_index(String(other_id))
				if index>=0: wars.append("at war with %s" % String(WorldSimulation.world.civilizations[index].get("name",other_id)))
		var goals:Array=[]
		for goal in leader.get("goals",[]): goals.append(String(goal.get("title","")))
		context["civ"]={"id":String(audience.civ_id),"name":String(audience.civ_name),"population":roundi(float(civ.get("population",0))),"strategy":String(civ.get("strategy","")),
			"opinion":_words(float(relation.get("opinion",0)),[[-0.4,"hostile"],[-0.1,"cool"],[0.15,"wary but civil"],[0.4,"friendly"],[1e9,"warm"]]),
			"border":_words(float(relation.get("border_tension",0)),[[0.2,"quiet"],[0.45,"watchful"],[0.7,"tense"],[1e9,"on the edge of violence"]]),
			"at_war_with_player":bool(relation.get("at_war",false)),"treaty":String(relation.get("treaty","none")),"wars":wars,
			"food":_words(float(civ.get("food_days",30)),[[12,"going hungry"],[22,"short of food"],[60,"fed"],[1e9,"well provisioned"]])}
		context["leader"]={"name":String(leader.get("name","")),"temperament":String(leader.get("temperament","")),"bio":String(leader.get("bio","")),"goals":goals.slice(0,3),
			"trust":_words(float(leader.get("trust",0)),[[-0.3,"distrustful"],[0.1,"undecided"],[1e9,"trusting"]]),"character":_rivals().call("prompt_view",String(audience.civ_id))}
		var regard:=DIVINE.foreign_regard(String(audience.civ_id))
		if not regard.is_empty(): context["their_regard"]={"reads":"they "+String(regard.read),"reverence":_band_word(float(regard.love)),"dread":_band_word(float(regard.dread))}
	else:
		if audience.kind in WORK_KINDS:
			var gwa:=_great_works()
			if gwa!=null: context["wonder_proposal" if audience.kind=="wonder_proposal" else "great_work"]=gwa.call("voice_facts",audience)
		var known_id:=String((audience.speaker as Dictionary).get("known_id",""))
		if known_id!="":
			# A summoned commoner speaks for themselves, from their own life.
			var persons:GDScript=load("res://scripts/court_persons.gd")
			var known:Dictionary=persons.call("by_id",known_id)
			if not known.is_empty(): context["summoned_person"]=persons.call("view",known)
		var person:=_official(int(audience.speaker.person_id))
		if not person.is_empty():
			var rel:Dictionary=person.get("relationships",{}).get("sovereign",{})
			context["petitioner"]={"name":String(person.name),"title":String(person.get("office_title","")),"traits":(person.get("traits",[]) as Array).duplicate(),"background":String(person.get("background","")),"doctrine":String(person.get("doctrine","")),
				"disposition":String(GovernmentPeopleSystem.leader_disposition(person).get("id","pragmatic")),
				"trust":_words(float(rel.get("trust",0.5)),[[0.35,"low"],[0.65,"moderate"],[1e9,"high"]]),"resentment":_words(float(rel.get("resentment",0)),[[0.1,"none"],[0.3,"some"],[1e9,"deep"]]),
				"regard":_regard_words(DIVINE.regard(person))}
	return context

static func debug_force(kind:String,civ_id:String="")->Dictionary:
	## Test/capture helper: create one audience now, bypassing pacing and the
	## ledger but never the truth rules (no audience if the stores cannot back it).
	if kind not in KINDS: return {}
	var day:=_day()
	var audience:={}
	if kind=="report":
		return _debug_report(civ_id)
	if kind=="wonder_proposal":
		var gwp:=_great_works()
		if gwp==null: return {}
		_court_direct=true
		var pitched:Dictionary=gwp.call("proposal_audience",{"trigger":{"kind":"debug","text":"A test of the court's imagination."}})
		_court_direct=false
		if pitched.is_empty(): pitched=gwp.call("ruler_proposal")
		return pitched
	if kind=="great_work":
		## civ_id may name a work id; the first pending stage gate otherwise.
		var gwa:=_great_works()
		if gwa==null: return {}
		for pending in gwa.call("api_list","pending_decisions"):
			if not pending is Dictionary: continue
			if civ_id!="" and String(pending.get("work_id",""))!=civ_id: continue
			_court_direct=true
			var made:Dictionary=gwa.call("decision_audience",String(pending.get("work_id","")),String(pending.get("city_id","")))
			_court_direct=false
			if not made.is_empty(): return made
			for waiting_audience in waiting():
				if String(waiting_audience.kind)=="great_work" and String((waiting_audience.get("great_work",{}) as Dictionary).get("work_id",""))==String(pending.get("work_id","")): return waiting_audience
		return {}
	if kind=="petition":
		var topic:=civ_id if civ_id in TOPICS else ""
		for person in _officials():
			audience=_generate_petition(int(person.person_id),day,topic)
			if not audience.is_empty(): break
	else:
		var ids:Array=[civ_id] if civ_id!="" else []
		if ids.is_empty():
			for civ in WorldSimulation.world.civilizations: ids.append(String(civ.get("id","")))
		for id in ids:
			if ForeignDiplomacy.civilization(String(id)).is_empty(): continue
			audience=_generate_foreign(String(id),day,kind)
			if not audience.is_empty(): break
	if audience.is_empty(): return {}
	_enqueue(audience,day)
	return audience

static func debug_situation(situation_type:String,target:String="",data:Dictionary={})->Dictionary:
	## Test/capture helper: raise one specific situation now (foreign target is
	## a civ id; court target is a person id), bypassing pacing and the ledger.
	if not SITUATIONS.has(situation_type): return {}
	var day:=_day()
	var kind:=String(SITUATIONS[situation_type].kind)
	var audience:={}
	if kind=="petition":
		var court_type:String={"crisis_petition":"condition","grievance":"grievance","ambition":"ambition","promise_followup":"promise_followup","introduction":"appointment","war_council":"war_council"}[situation_type]
		var people:Array[Dictionary]=_officials()
		if target.is_valid_int() and not _official(int(target)).is_empty(): people=[_official(int(target))]
		for person in people:
			var payload:=data.duplicate(true)
			if court_type=="promise_followup" and not payload.has("decree"): payload["decree"]=String(_ambition_ladder(person)[0]); payload["promised_day"]=maxi(0,day-150)
			var built:=_court_petition(court_type,person,payload,day)
			if built.is_empty(): continue
			audience=_court_audience(person,built,{"type":court_type,"key":"debug","data":payload},day)
			break
	else:
		var ids:Array=[target] if target!="" else []
		if ids.is_empty():
			for civ in WorldSimulation.world.civilizations: ids.append(String(civ.get("id","")))
		for id in ids:
			if ForeignDiplomacy.civilization(String(id)).is_empty(): continue
			var occasion:={"type":"debug","key":"debug","civ_id":String(id),"data":data.duplicate(true)}
			var candidate:=_candidate(situation_type,String(id),occasion,_rng("debug:"+situation_type,day),{},day)
			if candidate.is_empty(): continue
			audience=_foreign_audience(String(id),candidate,occasion,day)
			break
	if audience.is_empty(): return {}
	_enqueue(audience,day)
	return audience

static func _debug_report(civ_id:String)->Dictionary:
	## Build a report from real facts about a contacted civilization.
	var civ:={}
	for candidate in WorldSimulation.world.civilizations:
		var id:=String(candidate.get("id",""))
		if (civ_id=="" or id==civ_id) and not ForeignDiplomacy.civilization(id).is_empty(): civ=candidate; break
	if civ.is_empty(): return {}
	var speaker:=GovernmentPeopleSystem.officeholder("ChiefScout")
	if speaker.is_empty():
		var officials:=_officials()
		speaker=officials[0] if not officials.is_empty() else {"name":"A returning scout","office_title":"Scout","person_id":0}
	var pop:=float(civ.get("population",0))
	var facts:Array=[
		{"kind":"population","text":"about %d people" % (roundi(pop/10.0)*10),"value":roundi(pop),"certainty":0.6},
		{"kind":"strategy","text":String(civ.get("strategy","")),"certainty":0.5},
		{"kind":"food","text":"granaries low" if float(civ.get("food_days",30))<22 else "granaries full","certainty":0.5},
	]
	return enqueue({"kind":"report","origin":"court","summoned":true,"speaker":{"name":String(speaker.name),"title":String(speaker.get("office_title","Chief Scout")),"person_id":int(speaker.get("person_id",0))},
		"report":{"facts":facts,"subject_civ_id":String(civ.id),"subject_name":String(civ.get("name","")),"source":"scouts","observed_day":maxi(0,_day()-4)}})

# --------------------------------------------------------------------------
# Legacy saves: calm a stuffed antechamber
# --------------------------------------------------------------------------

static func _migrate(s:Dictionary)->void:
	## Version-1 halls scheduled an envoy per civilization every few weeks and a
	## petition per official every month or two. On load: rebuild the ledger from
	## history, keep at most MIGRATION_KEEP distinct waiting audiences (others
	## withdraw quietly, without penalty), drop the old timers and give the
	## ruler a breathing space before the next routine audience.
	s["version"]=2
	var day:=_day()
	var ledger:Array=s.ledger
	var old_history:Array=(s.history as Array).duplicate()
	old_history.reverse()
	for audience in old_history:
		if audience is Dictionary:
			_ledger_add(audience)
			_ledger_close(audience,String(audience.get("option_id","")) if String(audience.get("option_id",""))!="" else String(audience.get("status","resolved")),"",String(audience.get("outcome","")))
	var queue:Array=(s.queue as Array).duplicate()
	queue.sort_custom(func(a:Variant,b:Variant)->bool:return a is Dictionary and b is Dictionary and int(a.get("arrived_day",0))<int(b.get("arrived_day",0)))
	var seen:Dictionary={}
	var kept:=0
	for audience in queue:
		if not audience is Dictionary or String(audience.get("status",""))!="waiting": continue
		var kind:=String(audience.get("kind",""))
		if kind in WORK_KINDS or kind=="report":
			_ledger_add(audience)
			continue
		var speaker:=_speaker_key(audience)
		var key:=speaker+"|"+_ask_key(audience)
		if seen.has(key) or seen.has(speaker) or kept>=MIGRATION_KEEP:
			audience["status"]="expired"
			audience["option_id"]="withdrawn"
			audience["outcome"]="%s withdrew quietly after a long wait; no offence was taken, and the matter will return if it still matters." % String((audience.get("speaker",{}) as Dictionary).get("name","The visitor"))
			_ledger_add(audience)
			_ledger_close(audience,"withdrawn","neutral",String(audience.outcome))
			(s.queue as Array).erase(audience)
			(s.history as Array).push_front(audience)
			continue
		seen[key]=true; seen[speaker]=true; kept+=1
		audience["expires_day"]=maxi(int(audience.get("expires_day",day)),day+EXPIRY_DAYS)
		_ledger_add(audience)
	if (s.history as Array).size()>HISTORY_MAX: (s.history as Array).resize(HISTORY_MAX)
	s["next_foreign"]={}
	s["next_court"]={}
	var last_civ:Dictionary={}
	var last_person:Dictionary={}
	for entry in ledger:
		if not entry is Dictionary: continue
		var speaker2:=String(entry.get("speaker",""))
		if speaker2.begins_with("civ:"): last_civ[speaker2.trim_prefix("civ:")]=maxi(int(last_civ.get(speaker2.trim_prefix("civ:"),-99999)),int(entry.day))
		elif speaker2.begins_with("person:"): last_person[speaker2.trim_prefix("person:")]=maxi(int(last_person.get(speaker2.trim_prefix("person:"),-99999)),int(entry.day))
	s["last_civ"]=last_civ
	s["last_person"]=last_person
	s["occasions"]=[]
	s["watch"]={}
	s["last_arrival_day"]=maxi(int(s.get("last_arrival_day",-9999)),day)
	s["next_any"]=day+roundi(float(FREQUENCIES.get(String(s.get("frequency","normal")),90))*0.6)

# --------------------------------------------------------------------------
# The god's wrath and favour (see divine_regard.gd)
# --------------------------------------------------------------------------

static func _band_word(value:float)->String:
	return _words(value,[[0.15,"none"],[0.35,"little"],[0.55,"some"],[0.75,"high"],[1e9,"overwhelming"]])

static func _regard_words(regard:Dictionary)->Dictionary:
	## Plain words for the voice: how this person holds the god right now.
	if regard.is_empty(): return {}
	var out:={"reads":String(regard.get("read","")),"love":_band_word(float(regard.get("love",0.5))),"dread":_band_word(float(regard.get("dread",0.0))),
		"candor":_words(float(regard.get("candor",0.5)),[[0.35,"evasive: softens bad news, flatters, overpromises"],[0.6,"guarded"],[1e9,"frank: tells hard truths unasked"]])}
	if bool(regard.get("warned",false)): out["thinking_of_flight"]="lets slip, sideways, that they have thought of slipping away beyond the hills"
	return out

const DIVINE_HISTORY_WORDS:={"terrify":"the god raged at %s before the court","penance":"the god demanded penance of %s","cast_out":"the god cast %s out of the realm",
	"strike_down":"the god had %s put to death before the court","bless":"the god blessed %s","boon":"the god gave %s a gift from the stores",
	"raise_up":"the god raised %s above their peers","terrify_envoy":"the god terrified %s, an envoy","flight":"%s fled beyond the hills in fear"}

static func _divine_history()->Array:
	var out:Array=[]
	for e in DIVINE.events(4):
		var words:=String(DIVINE_HISTORY_WORDS.get(String(e.get("action","")),"the god acted on %s")) % String(e.get("name","someone"))
		out.append("%s: %s" % [_when(int(e.get("day",_day()))),words])
	return out

static func _when(day:int)->String:
	var ago:=_day()-day
	if ago<=0: return "today"
	if ago<=2: return "days ago"
	if ago<=40: return "this month"
	if ago<=400: return "this year"
	return "years ago"

static func _divine_target(audience:Dictionary)->Dictionary:
	## The summoned official the god may act on: a current officeholder.
	if String(audience.get("origin",""))!="court": return {}
	var pid:=int((audience.get("speaker",{}) as Dictionary).get("person_id",0))
	if pid<=0: return {}
	return _official(pid)

static func _boon_terms()->Dictionary:
	var best:="";var best_stock:=0.0
	for resource in RESOURCES:
		var stock:=player_stock(resource)
		if stock>best_stock: best_stock=stock; best=resource
	if best=="": best="Food"
	return {"resource":best,"amount":_nice(clampf(_player_population()*(0.05 if best=="Food" else 0.02),3.0,25.0))}

static func regard_of(id:String)->Dictionary:
	## For the modal's meter: the summoned person's love and dread, or how the
	## envoy's people regard the ruler.
	var audience:=find(id)
	if audience.is_empty(): return {}
	if String(audience.get("origin",""))=="foreign": return DIVINE.foreign_regard(String(audience.get("civ_id","")))
	var pid:=int((audience.get("speaker",{}) as Dictionary).get("person_id",0))
	if pid<=0: return {}
	var person:=_official(pid)
	if person.is_empty(): person=GovernmentPeopleSystem.person_snapshot(pid)
	return DIVINE.regard(person)

static func people_regard()->Dictionary:
	return DIVINE.people_regard(_officials())

static func divine_options(id:String)->Array[Dictionary]:
	## The god's wrath and favour open in this audience. Each act at most once
	## per audience; a boon needs stores that can pay it.
	var audience:=find(id)
	var result:Array[Dictionary]=[]
	if audience.is_empty() or String(audience.get("status",""))!="waiting": return result
	var done:Array=audience.get("divine",[]) if audience.get("divine") is Array else []
	if String(audience.get("origin",""))=="foreign":
		if ForeignDiplomacy.civilization(String(audience.get("civ_id",""))).is_empty(): return result
		var free:=not "terrify" in done
		result.append({"id":"terrify","label":"Terrify the envoy","sub":"Send your fury home with them. Their ruler decides what to make of it.","tone":"wrath","enabled":free,"reason":"" if free else "They are already grey to the lips."})
		return result
	if _divine_target(audience).is_empty(): return result
	for action:String in DIVINE.WRATH+DIVINE.FAVOR:
		var definition:Dictionary=DIVINE.ACTIONS[action]
		var enabled:=not action in done
		var reason:="" if enabled else "Already done in this audience."
		var sub:=String(definition.sub)
		if action=="boon":
			var boon:=_boon_terms()
			sub="Give them %s from the stores." % _terms_text(boon)
			var short:=_short(String(boon.resource),float(boon.amount))
			if enabled and short!="":
				enabled=false; reason=short
		result.append({"id":action,"label":String(definition.label),"sub":sub,"tone":String(definition.tone),"enabled":enabled,"reason":reason})
	return result

static func divine_intent(id:String,text:String)->String:
	## The ruler's words, read for a spoken act the god may perform here.
	var action:=DIVINE.intent(text)
	if action.is_empty(): return ""
	for option in divine_options(id):
		if String(option.id)==action and bool(option.enabled): return action
	return ""

static func divine(id:String,action:String,words:String="",target_pid:int=0,how:Dictionary={})->Dictionary:
	## Perform an act of wrath or favour. Real, bounded effects only: bonds and
	## memories, stores for a boon, exile or execution through the government.
	## target_pid: another official present at court (default: the one before
	## you). how: {"agent_name","agent_pid"} when an official carries it out by
	## the god's command; {"quiet":true} when the caller narrates the act itself.
	var audience:=find(id)
	if audience.is_empty() or String(audience.get("status",""))!="waiting": return {"ok":false,"outcome":"No audience is waiting."}
	var speaker_pid:=int((audience.get("speaker",{}) as Dictionary).get("person_id",0))
	var done:Array=audience.get("divine",[]) if audience.get("divine") is Array else []
	if target_pid>0 and target_pid!=speaker_pid:
		if String(audience.origin)!="court" and not action in DIVINE.WRATH+DIVINE.FAVOR: return {"ok":false,"outcome":"That is not open to you here."}
		var other:=_official(target_pid)
		if other.is_empty(): return {"ok":false,"outcome":"They are not at your court."}
		var key:="%s:%d" % [action,target_pid]
		if key in done: return {"ok":false,"outcome":"Already done in this audience."}
		if action=="boon" and _short(String(_boon_terms().resource),float(_boon_terms().amount))!="": return {"ok":false,"outcome":_short(String(_boon_terms().resource),float(_boon_terms().amount))}
		var watchers:Array[Dictionary]=[]
		for p in _officials():
			var wid:=int(p.person_id)
			if wid==target_pid: continue
			if wid==speaker_pid or court(id).any(func(c:Dictionary)->bool:return int(c.person_id)==wid): watchers.append(p)
		done.append(key)
		audience["divine"]=done
		return _divine_act(audience,action,other,watchers,false,how)
	var chosen:={}
	for option in divine_options(id):
		if String(option.id)==action: chosen=option
	if chosen.is_empty(): return {"ok":false,"outcome":"That is not open to you here."}
	if not bool(chosen.enabled): return {"ok":false,"outcome":String(chosen.reason)}
	done.append(action)
	audience["divine"]=done
	if String(audience.origin)=="foreign": return _terrify_envoy(audience,words)
	var person:=_divine_target(audience)
	return _divine_act(audience,action,person,court(id),true,how)   # witnesses read before any removal, so a successor is not a witness

static func _divine_act(audience:Dictionary,action:String,person:Dictionary,witnesses:Array,is_speaker:bool,how:Dictionary)->Dictionary:
	var id:=String(audience.id)
	var pid:=int(person.person_id)
	var name:=String(person.get("name","them"))
	var agent:=String(how.get("agent_name",""))
	var removal:=action in DIVINE.TERMINAL
	var terminal:=removal and is_speaker
	var result:={"ok":true,"action":action,"terminal":terminal,"removed":removal,"person_id":pid,"name":name,"reaction":"neutral","agent":agent,"agent_pid":int(how.get("agent_pid",0))}
	var narration:=""
	var outcome:=""
	match action:
		"boon":
			var boon:=_boon_terms()
			var paid:=_debit_player(String(boon.resource),float(boon.amount))
			result["terms"]={"resource":String(boon.resource),"amount":paid}
			narration="You give %s %d %s from the stores." % [name,roundi(paid),String(boon.resource)]
			outcome="You gave %s %d %s from the stores." % [name,roundi(paid),String(boon.resource)]
		"cast_out":
			var gone:=GovernmentPeopleSystem.person_departs(pid,"exiled")
			if not bool(gone.get("ok",false)): return {"ok":false,"outcome":String(gone.get("reason","They cannot be cast out now."))}
			var heirs:Array=gone.get("successors",[])
			narration="At your word %s is stripped of office and driven out beyond the hearths%s." % [name," by "+agent if agent!="" else ""]
			outcome="You cast %s out of the realm.%s" % [name," %s took up the work." % ", ".join(PackedStringArray(heirs)) if not heirs.is_empty() else ""]
		"strike_down":
			var removed:Dictionary
			if String(person.get("office_key",""))=="settlement": removed=GovernmentPeopleSystem.remove_settlement_leader(String(person.get("settlement_id","")),"execute")
			else: removed=GovernmentPeopleSystem.remove_central_officeholder(String(person.get("office_key","")),"execute")
			if not bool(removed.get("ok",false)): return {"ok":false,"outcome":String(removed.get("reason","They cannot be put to death now."))}
			var heir:=String((removed.get("successor",{}) as Dictionary).get("name",""))
			result["successor"]=heir
			if agent!="":
				narration="At your word %s kills %s before the court." % [agent,name]
				outcome="%s was killed by %s at your word, before the court.%s The killing cost you legitimacy and cohesion." % [name,agent," %s now holds the office." % heir if heir!="" else " The office stands empty."]
			else:
				narration="At your word the guards seize %s. They are taken out, and put to death." % name
				outcome="%s was put to death at your word, before the court.%s The execution cost you legitimacy and cohesion." % [name," %s now holds the office." % heir if heir!="" else " The office stands empty."]
		"terrify": narration="The god's fury falls on %s before the whole court." % name
		"penance": narration="You demand penance of %s: fasting and vigil until you are appeased." % name
		"bless": narration="You bless %s before the whole court." % name
		"raise_up": narration="You raise %s above their peers before the whole court." % name
	var effects:=DIVINE.apply_to_court(action,person,witnesses)
	result["effects"]=effects
	result["response"]=String(effects.get("response","none"))
	if not bool(how.get("quiet",false)):
		append_line(id,{"speaker":"","role":"narrator","person_id":0,"civ_id":"","text":narration,"day":_day(),"aside":false})
	if outcome=="":
		outcome=String({"terrify":"You terrified %s before the court.","penance":"You demanded penance of %s.","bless":"You blessed %s.","raise_up":"You raised %s above their peers."}.get(action,"You acted on %s.")) % name
	var shaken:=0
	for w in (effects.witnesses as Dictionary).values():
		if action in DIVINE.WRATH and String((w as Dictionary).get("response",""))=="shaken": shaken+=1
	if action in DIVINE.WRATH and shaken>0: outcome+=" %d of your court %s shaken." % [shaken,"was" if shaken==1 else "were"]
	result["outcome"]=outcome
	if removal: _drop_matters_of(pid)
	if not terminal:
		apply_mood(id,-0.2 if action in DIVINE.WRATH else 0.2)
		result["reaction"]=String({"cower":"offended","defy":"furious","endure":"offended","relief":"delighted","blessed":"delighted"}.get(String(result.response),"neutral"))
		return result
	result["reaction"]="furious"
	audience.status="resolved"
	audience.outcome=outcome
	audience.option_id=action
	_archive(audience)
	_ledger_close(audience,action,"furious",outcome)
	return result

static func _drop_matters_of(person_id:int)->void:
	## Matters held by someone who is gone leave with them.
	if person_id<=0: return
	var key:="person:%d" % person_id
	for m in (state().matters as Array).duplicate():
		if m is Dictionary and String(m.get("holder_key",""))==key: (state().matters as Array).erase(m)

static func _terrify_envoy(audience:Dictionary,words:String)->Dictionary:
	## An envoy can be terrified too. It is intimidation between peoples: the
	## engine reads the threat and the foreign ruler's temperament decides the
	## real posture; that people's dread of you rises.
	var civ_id:=String(audience.civ_id)
	var name:=String((audience.speaker as Dictionary).get("name","the envoy"))
	var leader:=ForeignDiplomacy.leader(civ_id)
	var p:Dictionary=leader.get("personality",{}) if leader.get("personality") is Dictionary else {}
	var assertive:=float(p.get("assertiveness",0.5))
	var risk:=float(p.get("risk_tolerance",0.5))
	var requested:="call_bluff" if assertive>0.62 and risk>0.55 else ("harden_border" if assertive>0.5 else "conciliate")
	var spoken:=words.strip_edges().substr(0,400)
	if spoken.is_empty(): spoken="Kneel, and carry this home: cross me and I will destroy you."
	var engine_words:=spoken if "destroy you" in spoken.to_lower() else spoken+" (the ruler's fury: destroy you)"
	var posture:=ForeignDiplomacy.apply_conversation_reaction(civ_id,requested,engine_words,"The ruler raged at our envoy like a storm.")
	var actual:=String(posture.get("actual","unchanged"))
	var gain:=0.10+0.12*(1.0-assertive)
	DIVINE.record_envoy_terror(civ_id,String(audience.civ_name),name,gain)
	append_line(String(audience.id),{"speaker":"","role":"narrator","person_id":0,"civ_id":"","text":"Your fury falls on %s, envoy of %s, before the whole court." % [name,String(audience.civ_name)],"day":_day(),"aside":false})
	apply_mood(String(audience.id),-0.25)
	append_line(String(audience.id),{"speaker":"","role":"narrator","person_id":0,"civ_id":"","text":"Word of it reaches their ruler: "+_posture_words(actual,String(audience.civ_name)),"day":_day(),"aside":false})
	var response:="defy" if assertive>0.62 else "cower"
	return {"ok":true,"action":"terrify","terminal":false,"person_id":0,"name":name,"response":response,"posture":actual,"civ_dread":DIVINE.civ_dread(civ_id),
		"reaction":"furious" if response=="defy" else "offended",
		"outcome":"You terrified %s's envoy. %s" % [String(audience.civ_name),_posture_words(actual,String(audience.civ_name))]}

# --------------------------------------------------------------------------
# Save validation
# --------------------------------------------------------------------------

static func _num(value:Variant)->bool:
	return (value is int or value is float) and is_finite(float(value))

static func validate_state(data:Variant)->bool:
	if not data is Dictionary: return false
	if (data as Dictionary).is_empty(): return true
	for key in ["queue","history"]:
		if not data.get(key,[]) is Array or (data.get(key,[]) as Array).size()>(QUEUE_MAX*4 if key=="queue" else HISTORY_MAX): return false
		for audience in data.get(key,[]):
			if not _valid_audience(audience): return false
	for key in ["next_foreign","next_court","last_civ","last_person"]:
		if not data.get(key,{}) is Dictionary or (data.get(key,{}) as Dictionary).size()>512: return false
		for entry in data.get(key,{}):
			if not entry is String or not _num(data[key][entry]): return false
	for key in ["last_arrival_day","serial","next_any","version"]:
		if data.has(key) and not _num(data[key]): return false
	if data.has("summon_immediately") and not data.summon_immediately is bool: return false
	if data.has("frequency") and not String(data.frequency) in FREQUENCIES: return false
	if data.has("last_speaker") and (not data.last_speaker is String or String(data.last_speaker).length()>120): return false
	if data.has("divine") and not DIVINE.valid_state(data.divine): return false
	if data.has("lives") and not bool(_lives().call("valid_state",data.lives)): return false
	if data.has("court_persons"):
		var persons:GDScript=load("res://scripts/court_persons.gd")
		if persons==null or not bool(persons.call("valid_state",data.court_persons)): return false
	if not data.get("ledger",[]) is Array or (data.get("ledger",[]) as Array).size()>LEDGER_MAX: return false
	for entry in data.get("ledger",[]):
		if not entry is Dictionary or not _num(entry.get("day")) or not entry.get("speaker","") is String or not entry.get("ask","") is String or JSON.stringify(entry).length()>2000: return false
	if not data.get("occasions",[]) is Array or (data.get("occasions",[]) as Array).size()>OCCASIONS_MAX: return false
	for occasion in data.get("occasions",[]):
		if not occasion is Dictionary or not occasion.get("key","") is String or not occasion.get("type","") is String or not _num(occasion.get("expires")) or not _num(occasion.get("not_before",0)) or JSON.stringify(occasion).length()>3000: return false
	if not data.get("watch",{}) is Dictionary or JSON.stringify(data.get("watch",{})).length()>100000: return false
	if not data.get("matters",[]) is Array or (data.get("matters",[]) as Array).size()>MATTERS_MAX: return false
	for m in data.get("matters",[]):
		if not m is Dictionary or not m.get("id","") is String or not m.get("key","") is String or not m.get("holder_key","") is String or not m.get("holder",{}) is Dictionary: return false
		if not _num(m.get("day")) or not _num(m.get("expires")) or not _num(m.get("urgency",0)) or not m.get("lines",[]) is Array or (m.get("lines",[]) as Array).size()>12: return false
		if JSON.stringify(m).length()>30000 or not _valid_audience(m.get("audience",{})) or String((m.get("audience",{}) as Dictionary).get("origin",""))!="court": return false
	return true

static func _valid_audience(a:Variant)->bool:
	if not a is Dictionary: return false
	if not a.has_all(["id","origin","kind","civ_id","speaker","arrived_day","expires_day","status","lines","mood"]): return false
	if not a.id is String or a.origin not in ["foreign","court"] or a.kind not in KINDS or a.status not in ["waiting","resolved","expired"]: return false
	if not a.civ_id is String or not a.speaker is Dictionary or String(a.speaker.get("name","")).length()>100: return false
	if not _num(a.arrived_day) or not _num(a.expires_day) or not _num(a.mood) or absf(float(a.mood))>1.0: return false
	if not a.lines is Array or a.lines.size()>LINES_MAX: return false
	for line in a.lines:
		if not line is Dictionary or not line.get("text","") is String or String(line.get("text","")).length()>2000: return false
	var terms:Variant=a.get("terms",{})
	if not terms is Dictionary: return false
	if not (terms as Dictionary).is_empty() and (terms.get("resource","") not in RESOURCES or not _num(terms.get("amount")) or float(terms.amount)<0): return false
	if not a.get("news",{}) is Dictionary or not a.get("petition",{}) is Dictionary: return false
	var situation:Variant=a.get("situation",{})
	if not situation is Dictionary or JSON.stringify(situation).length()>SITUATION_JSON_MAX: return false
	if not (situation as Dictionary).is_empty() and not SITUATIONS.has(String(situation.get("type",""))): return false
	if a.kind=="proposal" and (situation as Dictionary).is_empty(): return false
	var topic:=String((a.get("petition",{}) as Dictionary).get("topic",""))
	if a.kind=="petition" and topic not in TOPICS: return false
	if a.kind=="report" and not _valid_report(a.get("report",{})): return false
	if a.kind=="great_work":
		var gwa:=_great_works()
		if gwa==null or not bool(gwa.call("valid",a.get("great_work",{}))): return false
	if a.kind=="wonder_proposal":
		var gwp:=_great_works()
		if gwp==null or not bool(gwp.call("valid_proposal",a.get("wonder_proposal",{}))): return false
	return true
