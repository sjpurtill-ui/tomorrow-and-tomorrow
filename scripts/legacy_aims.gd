extends RefCounted
## GENERATIONAL AIMS (the Legacy ledger): what a people strives for between
## centuries. An aim lasts 5 to 25 years, is measured against the real
## simulation, and ends in a legacy or a grief. Aims never end the game and are
## never victory conditions: when one resolves, the people soon want another.
##
## Where aims come from
## - The court and the people propose them out of real state: hunger at the
##   fires, a rival's slight, a practice half learned, a river no one can cross,
##   the memory of someone lost, a shrinking or growing band. Only envoys come
##   unbidden, so a proposal waits as a court matter (held by an official)
##   until the god summons them. If the god stays silent until the matter
##   lapses, the people take up the favoured aim themselves.
## - The god may set one. Online, typed words are mapped onto a measurable
##   target (from_words); offline, the god chooses among the proposals.
## - Each aim belongs to one of the century ambitions (PeopleDirection
##   AMBITIONS): taking it up records a cultural action for that ambition, so
##   research and scouting inclinations follow it through the existing focus
##   system. Growth targets are calibrated against the historical growth
##   bands (docs/research/benchmarks_600.json, BENCHMARKS_FOCUS_600.md): a
##   focus aligned with the aim paces toward the boosted band, never past the
##   era's plausible maximum.
##
## How it shows
## - The Known World board and the court's roll show the live aim, its
##   progress in the people's words, known rival aims and the legacies won.
## - Taking up, milestones (a quarter, half, three quarters), fulfilment and
##   failure are told through Chronicle.record.
## - Fulfilment: love, legitimacy, cohesion, and a named legacy. Failure: grief
##   and dread, but never ruin. Letting an aim go: a smaller grief.
## - Halfway through, an aim that is falling behind brings its keeper back to
##   court: press harder, give it more winters, hold the course, or let it go.
##
## Rivals hold aims of their own (grow past us, make us yield, bind us to
## them, spread their lands), seeded from their leader's temperament. The
## player learns of one when that people's envoy comes; some clash with the
## player's aim, and one side's success is the other's setback.
##
## State lives in PeopleDirection.aims (saved with the people-direction block;
## older saves start empty). Static helpers; reference with preload.

const Hall:=preload("res://scripts/audience_hall.gd")
const Lives:=preload("res://scripts/court_lives.gd")
const Chronicle:=preload("res://scripts/chronicle.gd")
const DIVINE:=preload("res://scripts/divine_regard.gd")
const EraNames:=preload("res://scripts/era_names.gd")
const Lines:=preload("res://scripts/legacy_aims_lines.gd")
const CV:=preload("res://scripts/character_voice.gd")
const PERSONALITY:=preload("res://scripts/leader_personality.gd")

const VERSION:=1
const HISTORY_MAX:=24
const LEGACIES_MAX:=24
const RIVALS_MAX:=8
const CANDIDATES_MAX:=12
const LOG_MAX:=60
const MIN_YEARS:=5
const MAX_YEARS:=25
## Days after founding before the court first speaks of an aim.
const FIRST_PROPOSAL_DAYS:=150
## Days of rest after an aim resolves before the next is proposed.
const REST_MIN:=45
const REST_MAX:=120
## A template is not proposed again within this many days (50 years).
const REPEAT_DAYS:=18250
const MILESTONES:=[25,50,75]
## Crisis proposals while an aim is live: at most one per this many days.
const CRISIS_GAP:=1095
## Historical growth bands, % per year (benchmarks_600.json growth_pct).
const GROWTH_BANDS:={0:{"min":-2.0,"low":-0.5,"typical":0.4,"high":1.2,"max":2.0},100:{"min":-1.0,"low":-0.3,"typical":0.5,"high":1.4,"max":1.8},300:{"min":-1.0,"low":-0.2,"typical":0.5,"high":1.5,"max":1.9},600:{"min":-1.0,"low":-0.2,"typical":0.4,"high":1.3,"max":1.8}}
## Largest single work at the founding, person-days (benchmarks_600.json
## largest_structure_person_days: low 500, typical 3000 at year 0).
const WORK_PERSON_DAYS:={"low":500.0,"typical":3000.0,"high":20000.0}
## Share of the builders' days an aim of stone can claim.
const WORK_SHARE:=0.12
const WORK_PRESSED_SHARE:=0.2
## Stores that count as plenty, in days of eating, and the share of the aim's
## days that must be days of plenty.
const PLENTY_STORES:=30.0
const PLENTY_SHARE:=0.8

## Each template: its century ambition (focus), research domain, legacy word,
## and which office speaks for it first.
const TEMPLATES:={
	"grow":{"focus":"wellbeing","domain":"demography","offices":["Steward","settlement"],"words":["many","more","children","grow","number","numerous","souls","multiply","populous","families","people"]},
	"plenty":{"focus":"sustenance","domain":"nutrition","offices":["Steward","Quartermaster"],"words":["hunger","hungry","food","feed","famine","stores","harvest","plenty","starve","eat","full bellies"]},
	"learn":{"focus":"inquiry","domain":"knowledge","offices":["Scholar"],"words":["master","secret","learn the","understand"]},
	"knowledge":{"focus":"inquiry","domain":"knowledge","offices":["Scholar"],"words":["learn","know","knowledge","discover","wisdom","teach","lore","ideas","wise"]},
	"reach":{"focus":"horizons","domain":"logistics","offices":["ChiefScout","Envoy"],"words":["reach","explore","walk","journey","find","beyond","far","horizon","mountain","sea","lake","travel"]},
	"fear":{"focus":"retribution","domain":"security","offices":["Marshal"],"words":["fear","terror","tremble","dread","humble","crush","punish","afraid","bow","submit","conquer"]},
	"friend":{"focus":"gathering","domain":"culture","offices":["Envoy"],"words":["friend","friendship","peace","ally","bond","marry","trust","kin with","brothers"]},
	"settle":{"focus":"expansion","domain":"demography","offices":["ChiefScout","settlement"],"words":["settle","village","new home","daughter","found a","new hearth","colony","second hearth"]},
	"work":{"focus":"makers","domain":"infrastructure","offices":["Quartermaster"],"words":["build","raise","monument","stone","stones","ring","wall","tower","mound","cairn","carve","great work","hall","bridge"]},
	"unity":{"focus":"gathering","domain":"institutions","offices":["Steward"],"words":["together","one people","united","unity","harmony","quarrel","one fire","peace among"]},
}
## What each press answer sends to the civic council (existing decree pipeline).
const PRESS_DECREES:={"grow":"Support families and care for children","plenty":"Conserve the land and rest the fields","learn":"Support scholars and fund research","knowledge":"Support scholars and fund research",
	"reach":"Improve roads and organize haulers","settle":"Build shelters and repair housing","work":"Quarry stone and prioritize stone","unity":"Hold a public council to hear the people","fear":"Post guards and patrol the frontier"}
const CROSSING_WORDS:=["bridge","ford","raft","boat","crossing","river","float","span","ferry","canoe"]

# --------------------------------------------------------------------------
# State
# --------------------------------------------------------------------------

static func state()->Dictionary:
	var s:Dictionary=PeopleDirection.aims
	# Aims belong to one world and one moment: a save from before aims (which
	# leaves the live block untouched) or another world starts afresh.
	if not s.is_empty() and (int(s.get("world_seed",GameState.world_seed))!=int(GameState.world_seed) or float(s.get("last_day",0))>GameState.elapsed_days+1.0): s.clear()
	if int(s.get("version",0))!=VERSION or not s.get("stats") is Dictionary: _seed(s)
	return s

static func _seed(s:Dictionary)->void:
	for key in ["active","candidates","rivals","used","stats"]:
		if not s.get(key) is Dictionary: s[key]={}
	for key in ["history","legacies","log","pop_samples"]:
		if not s.get(key) is Array: s[key]=[]
	for key in ["serial","last_day","next_proposal_day","matter_day","crisis_day","low_food_day","slight_day"]:
		if not _num(s.get(key)): s[key]=-1 if key in ["next_proposal_day","low_food_day","slight_day"] else 0
	if not s.get("matter_id") is String: s["matter_id"]=""
	for key in ["tracked","active_days","decisions","proposals","fulfilled","failed","released","people_took"]:
		if not _num((s.stats as Dictionary).get(key)): s.stats[key]=0
	s["world_seed"]=int(GameState.world_seed)
	s["version"]=VERSION

static func valid_state(data:Variant)->bool:
	## Optional save block; absent in older saves.
	if not data is Dictionary: return false
	var d:Dictionary=data
	if JSON.stringify(d).length()>200000: return false
	for key in ["active","candidates","rivals","used","stats"]:
		if d.has(key) and not d[key] is Dictionary: return false
	var limits:={"history":HISTORY_MAX,"legacies":LEGACIES_MAX,"log":LOG_MAX,"pop_samples":12}
	for key:String in limits:
		if not d.has(key): continue
		if not d[key] is Array or (d[key] as Array).size()>int(limits[key]): return false
		for entry in d[key]:
			if key=="pop_samples":
				if not _num(entry): return false
			elif not entry is Dictionary: return false
	if d.has("candidates") and (d.candidates as Dictionary).size()>CANDIDATES_MAX*2: return false
	if d.has("rivals") and (d.rivals as Dictionary).size()>RIVALS_MAX*2: return false
	if d.has("active") and not (d.active as Dictionary).is_empty():
		var a:Dictionary=d.active
		if not TEMPLATES.has(String(a.get("template",""))) or not _num(a.get("start_day")) or not _num(a.get("deadline")): return false
	return true

static func _num(value:Variant)->bool:
	return (value is int or value is float) and is_finite(float(value))

static func _day()->int:
	return int(GameState.elapsed_days)

static func _rng(key:String)->RandomNumberGenerator:
	var rng:=RandomNumberGenerator.new()
	rng.seed=hash("%d:aims:%s" % [int(GameState.world_seed),key])
	return rng

static func _pick(list:Array,key:String)->String:
	if list.is_empty(): return ""
	return String(list[posmod(hash("%d|%s" % [int(GameState.world_seed),key]),list.size())])

static func _log(kind:String,text:String,extra:Dictionary={})->void:
	## A bounded record of what happened (tests and the playtest harness read it).
	var entry:Dictionary={"day":_day(),"kind":kind,"text":text.substr(0,300)}
	for key in extra:
		var value:Variant=extra[key]
		if value is String or value is int or value is float or value is bool: entry[String(key)]=value
	var list:Array=state().log
	list.push_front(entry)
	while list.size()>LOG_MAX: list.pop_back()

static func active()->Dictionary:
	return state().active

static func has_active()->bool:
	return not (state().active as Dictionary).is_empty()

# --------------------------------------------------------------------------
# Words
# --------------------------------------------------------------------------

static func number_words(n:int)->String:
	if n>=0 and n<Lines.NUMBER_WORDS.size(): return String(Lines.NUMBER_WORDS[n])
	return str(n)

static func winters(years:int)->String:
	return "one winter" if years==1 else "%s winters" % number_words(years)

static func _the(people:String)->String:
	## "the Keshan", "the Nine Fires": a people's name inside a sentence.
	var bare:=people.strip_edges()
	if bare.to_lower().begins_with("the "): bare=bare.substr(4)
	return "the "+bare

static func _title(text:String)->String:
	## Title case for names: "building and water" -> "Building and Water".
	var words:=text.split(" ")
	for i in words.size():
		if i==0 or not words[i] in ["and","of","the","to","a","in"]: words[i]=_cap(words[i])
	return " ".join(words)

static func _cap(text:String)->String:
	return text.substr(0,1).to_upper()+text.substr(1) if text!="" else text

static func _fill(template:String,tokens:Dictionary)->String:
	var out:=template
	for key in tokens: out=out.replace("{"+String(key)+"}",String(tokens[key]))
	out=out.strip_edges()
	for i in range(out.length()):
		if i==0 or (i>=2 and out[i-1]==" " and out[i-2] in ".!?"):
			out=out.substr(0,i)+out[i].to_upper()+out.substr(i+1)
	return out

static func _era_ok(text:String)->bool:
	return CV.permits(text,CV.era_tags("player"))

static func _say(bank:Array,tokens:Dictionary,salt:String,fallback:Array=[])->String:
	## The first era-safe line from a salted start.
	for list in [bank,fallback,Lines.GENERIC]:
		var options:Array=list
		if options.is_empty(): continue
		var start:=posmod(hash("%d|%s" % [int(GameState.world_seed),salt]),options.size())
		for offset in options.size():
			var text:=_fill(String(options[(start+offset)%options.size()]),tokens)
			if _era_ok(text) and not text.contains("{"): return text
	return ""

static func _manner(person:Dictionary)->String:
	if person.is_empty(): return ""
	return Lives._manner(person)

static func _civ(civ_id:String)->Dictionary:
	for civ in CivilizationSystem.civilizations:
		if civ is Dictionary and String((civ as Dictionary).get("id",""))==civ_id: return civ
	return {}

static func _civ_name(civ_id:String)->String:
	var civ:=_civ(civ_id)
	return String(civ.get("name","the strangers")) if not civ.is_empty() else "the strangers"

static func _relation(civ_id:String)->Dictionary:
	var civ:=_civ(civ_id)
	return civ.get("player_relation",{}) if civ.get("player_relation") is Dictionary else {}

# --------------------------------------------------------------------------
# Benchmarks
# --------------------------------------------------------------------------

static func growth_band(year:float)->Dictionary:
	## The historical growth band (% per year) for a game year, interpolated.
	var keys:Array=GROWTH_BANDS.keys()
	keys.sort()
	var lo:int=int(keys[0]); var hi:int=int(keys[keys.size()-1])
	for k in keys:
		if float(k)<=year: lo=int(k)
		if float(k)>=year: hi=int(k); break
	var a:Dictionary=GROWTH_BANDS[lo]; var b:Dictionary=GROWTH_BANDS[hi]
	var t:=0.0 if hi==lo else clampf((year-float(lo))/float(hi-lo),0.0,1.0)
	var out:Dictionary={}
	for field in a: out[field]=lerpf(float(a[field]),float(b[field]),t)
	return out

static func _focus_aligned(template:String)->bool:
	## True when this century's chosen ambition shares the aim's research domain.
	var ambition:=String(PeopleDirection.ambition)
	if not PeopleDirection.AMBITIONS.has(ambition): return false
	var domain:=String((TEMPLATES[template] as Dictionary).domain)
	return domain in (PeopleDirection.AMBITIONS[ambition] as Dictionary).domains or ambition==String((TEMPLATES[template] as Dictionary).focus)

static func observed_growth()->float:
	## The band's recent growth, % per year, from yearly samples (0 if unknown).
	var samples:Array=state().pop_samples
	if samples.size()<2: return 0.0
	var first:=maxf(1.0,float(samples[samples.size()-1])); var last:=maxf(1.0,float(samples[0]))
	var years:=float(samples.size()-1)
	return (pow(last/first,1.0/years)-1.0)*100.0

static func growth_target(pop:int,years:int,aligned:bool)->Dictionary:
	## A growth target a people could plausibly reach: somewhat better than
	## its own recent trend, inside the era's band, and toward the focus
	## boost (position 0.35 between typical and high) when the century's
	## ambition favours it. Never past the band's plausible maximum.
	var band:=growth_band(_day()/365.0)
	var trend:=observed_growth()
	var push:=float(band.typical)+(0.35 if aligned else 0.15)*(float(band.high)-float(band.typical))
	var rate:=clampf(minf(trend+0.6,push),float(band.low),float(band.max))
	var peak:=pop
	for sample in state().pop_samples: peak=maxi(peak,int(sample))
	var target:=ceili(float(pop)*pow(1.0+rate/100.0,float(years)))
	var restore:=false
	if peak>pop and target<=peak:
		target=peak; restore=true
	target=maxi(target,pop+maxi(3,ceili(pop*0.02)))
	var ceiling:=floori(float(pop)*pow(1.0+float(band.max)/100.0,float(years)))
	return {"target":mini(target,maxi(ceiling,pop+3)),"rate":rate,"restore":restore,"trend":trend}

# --------------------------------------------------------------------------
# Daily
# --------------------------------------------------------------------------

static func daily(day:int)->void:
	if WorldSimulation.actor_id!="player": return
	if not GameState.settlement_site_committed: return
	var s:=state()
	if day<=int(s.last_day): return
	var span:=clampi(day-int(s.last_day),1,30) if int(s.last_day)>0 else 1
	s.last_day=day
	var stats:Dictionary=s.stats
	stats.tracked=int(stats.tracked)+span
	if has_active(): stats.active_days=int(stats.active_days)+span
	_watch_conditions(day)
	if has_active(): _track(day,span)
	_watch_matter(day)
	if day%10==0 or not has_active(): _maybe_propose(day)
	if day%30==0: _rivals(day)

static func _watch_conditions(day:int)->void:
	var s:=state()
	var metrics:Dictionary=GameState.simulation_metrics
	if float(metrics.get("food_days",30.0))<18.0 or float(metrics.get("food_intake_ratio",1.0))<0.97: s.low_food_day=day
	if day%365==0 or (s.pop_samples as Array).is_empty():
		var samples:Array=s.pop_samples
		samples.push_front(GameState.population_total)
		while samples.size()>6: samples.pop_back()

# --------------------------------------------------------------------------
# Candidates: aims grown out of the real state
# --------------------------------------------------------------------------

static func _new_cid()->String:
	var s:=state()
	s.serial=int(s.serial)+1
	return "a%d" % int(s.serial)

static func _base(template:String,by:Dictionary,years:int)->Dictionary:
	var name:=String(by.get("name",""))
	return {"cid":_new_cid(),"template":template,"focus":String((TEMPLATES[template] as Dictionary).focus),"domain":String((TEMPLATES[template] as Dictionary).domain),
		"years":clampi(years,MIN_YEARS,MAX_YEARS),"by_pid":int(by.get("person_id",0)),"by_name":name.substr(0,60),"by_given":EraNames.given_of(name) if name!="" else "",
		"by_title":String(by.get("office_title",by.get("title",""))).substr(0,60),"source":String(by.get("source","official")),"subject":"","subject_name":""}

static func _cand_grow(by:Dictionary,rng:RandomNumberGenerator)->Dictionary:
	var pop:=GameState.population_total
	var years:=rng.randi_range(12,18)
	var goal:=growth_target(pop,years,_focus_aligned("grow"))
	var c:=_base("grow",by,years)
	c.target=int(goal.target); c.baseline=pop
	if bool(goal.restore):
		c.title="Be %s Souls Again" % _count(int(goal.target))
		c.phrase="see our hearths hold %s souls again, as they did" % _count(int(goal.target))
		c.why="We were %s once; we are %s now, and the old ones count the empty places." % [_count(int(goal.target)),_count(pop)]
		c.legacy="the Hearths Refilled"
	else:
		c.title="Let Our Hearths Hold %s Souls" % _count(int(goal.target))
		c.phrase="see our hearths hold %s souls" % _count(int(goal.target))
		c.why="We are %s. Every child who lives is a hand for the next generation." % _count(pop) if float(goal.trend)>=0.0 else "We are %s, and fewer each winter. That must turn." % _count(pop)
		c.legacy="the Many Hearths"
	return c

static func _count(n:int)->String:
	return number_words(n) if n<=20 else str(n)

static func _cand_plenty(by:Dictionary,rng:RandomNumberGenerator)->Dictionary:
	var years:=rng.randi_range(5,7)
	var c:=_base("plenty",by,years)
	c.target=ceili(float(years)*365.0*PLENTY_SHARE); c.baseline=0; c.threshold=PLENTY_STORES; c.acc=0.0
	c.title="No Child Hungry for %s" % _cap(winters(years))
	c.phrase="keep the stores full and no child hungry through %s" % winters(years)
	var low:=int(state().low_food_day)
	var metrics:Dictionary=GameState.simulation_metrics
	if low>=0 and _day()-low<365:
		c.why="The stores ran down to %d days' eating this year, and the little ones felt it first." % maxi(1,int(float(metrics.get("food_days",10.0))))
	else:
		c.why="A full store is a quiet camp. One bad winter could undo us."
	c.legacy="the Winters Without Hunger"
	return c

## How the people name each field of knowledge when they set out to master it.
const DOMAIN_WORDS:={"demography":"the care of families","nutrition":"food and its keeping","health":"healing","labor":"tools and work","knowledge":"the sky and the counting of days",
	"production":"making things","infrastructure":"building and water","logistics":"carrying and crossing","ecology":"the land and its seasons","institutions":"custom and law","security":"the watch and the spear","culture":"song and custom"}

static func known_in(domain:String)->int:
	var n:=0
	for id in GameState.known_discoveries:
		if String(DiscoverySystem.discovery_definition(String(id)).get("dynamic",""))==domain: n+=1
	return n

static func _half_learned()->Dictionary:
	## The field in which the people are closest to a new way already: the
	## practice under inquiry that is furthest along (a crossing counts double).
	var best:Dictionary={}
	for record in DiscoverySystem.active_investigation_records():
		var progress:=float(record.get("progress",0.0))
		var domain:=String(record.get("dynamic",""))
		if progress<0.2 or progress>=0.98 or not DOMAIN_WORDS.has(domain): continue
		var crossing:=false
		var lname:=String(record.get("name","")).to_lower()
		for word in CROSSING_WORDS:
			if lname.contains(word): crossing=true
		var score:=progress+(0.5 if crossing else 0.0)
		if best.is_empty() or score>float(best.get("score",0.0)): best={"id":String(record.get("id","")),"domain":domain,"progress":progress,"crossing":crossing,"score":score}
	return best

static func _cand_learn(by:Dictionary,rng:RandomNumberGenerator)->Dictionary:
	## Mastery of a field: several new ways in it, the first already half
	## known. Paced by the people's own rate of learning in that field, never
	## by a single practice that may come within a season.
	var half:=_half_learned()
	if half.is_empty(): return {}
	var domain:=String(half.domain)
	var years:=rng.randi_range(8,12)
	var learned:=maxi(0,GameState.known_discoveries.size()-10)
	# The field's share of what the people learn (smoothed: a young people's
	# first finds say little), times their pace of learning.
	var share:=float(known_in(domain)+1)/float(learned+12)
	var rate:=learning_pace()*share*(1.15 if _focus_aligned("learn") else 1.0)
	var gain:=clampi(roundi(rate*float(years)),3,12)
	var c:=_base("learn",by,years)
	c.subject=domain; c.subject_name=String(DOMAIN_WORDS[domain])
	c.first=String(half.id)
	c.target=gain; c.baseline=known_in(domain)
	var field:=String(DOMAIN_WORDS[domain])
	if bool(half.crossing):
		c.title="Cross the Great River"
		c.phrase="learn %s new ways of carrying and crossing, until the river is no wall to us" % _count(gain)
		c.why="We stand at the river and look at the far bank. We are close to a way across already."
		c.legacy="the Crossing"
	else:
		c.title="Master %s" % _title(field)
		c.phrase="learn %s new ways of %s" % [_count(gain),field]
		c.why="We are close to a new way of %s already. It would be a shame to stop at one." % field
		c.legacy="the Mastery of %s" % _title(field)
	return c

## New ways a young people learns in a year, at the least: the first decade
## of play runs at 4-5 a year (fun_playtest, seeds 424242 and 77013), and the
## founders' first finds come faster than any later pace.
const EARLY_LEARNING_PACE:=3.5

static func learning_pace()->float:
	## New ways learned per year: the people's own pace since the founding,
	## never below the early-era pace.
	var since:=maxf(1.0,(_day()-maxi(0,GameState.settlement_founded_day))/365.0)
	return maxf(EARLY_LEARNING_PACE,float(GameState.known_discoveries.size()-10)/since)

static func _cand_knowledge(by:Dictionary,rng:RandomNumberGenerator)->Dictionary:
	var years:=rng.randi_range(10,15)
	var known:=GameState.known_discoveries.size()
	var rate:=learning_pace()*(1.1 if _focus_aligned("knowledge") else 1.0)
	var gain:=maxi(3,roundi(rate*float(years)*0.9))
	var c:=_base("knowledge",by,years)
	c.target=gain; c.baseline=known
	c.title="Learn %s New Ways in %s" % [_cap(_count(gain)),_cap(winters(years))]
	c.phrase="learn %s new ways before %s have passed" % [_count(gain),winters(years)]
	c.why="Every new way we learn is a winter we survive that we would not have."
	c.legacy="the Years of Learning"
	return c

static func _cand_reach(by:Dictionary,rng:RandomNumberGenerator)->Dictionary:
	var years:=rng.randi_range(6,10)
	for civ in CivilizationSystem.civilizations:
		if not civ is Dictionary: continue
		var rel:Dictionary=(civ as Dictionary).get("player_relation",{})
		if int(rel.get("contact_level",0))!=1: continue
		var c:=_base("reach",by,years)
		c.subject=String(civ.id); c.subject_name=String(civ.name).substr(0,60)
		c.target=2; c.baseline=1
		c.title="Sit at the Fire of %s" % _the(String(civ.name))
		c.phrase="walk to the fires of %s and sit with them" % _the(String(civ.name))
		c.why="We have seen their smoke and their tracks, and never their faces."
		c.legacy="the Walk to %s" % _the(String(civ.name))
		return c
	var charted:=float(CivilizationSystem.progression_reach_snapshot().get("charted",0.0))
	var c:=_base("reach",by,years)
	if charted<=0.0:
		# Nothing charted yet: count the tellings the walkers bring home.
		var reports:=CivilizationSystem.scout_reports.size()
		c.target=reports+maxi(4,years); c.baseline=reports; c["reports"]=true
	else:
		c.target=charted*1.6; c.baseline=charted
	c.title="Walk Farther Than Any of Us Has Walked"
	c.phrase="walk and mark half again as much land as we know"
	c.why="Past the last ridge we know, the walkers turn back. Someone must not."
	c.legacy="the Long Walk"
	return c

static func _slighted_by()->Dictionary:
	## The people that most recently slighted us: a demand, a threat, a test.
	var best:Dictionary={}
	for entry in Hall.ledger():
		var civ_id:=String(entry.get("civ_id",""))
		if civ_id=="" or _day()-int(entry.get("day",-99999))>1095: continue
		if not String(entry.get("situation","")) in ["tribute_demand","emboldened_demand","test_of_resolve","artifact_return","recruitment_protest"]: continue
		if best.is_empty() or int(entry.day)>int(best.day): best={"civ_id":civ_id,"day":int(entry.day),"situation":String(entry.situation)}
	if best.is_empty():
		var worst:=0.3
		for civ in CivilizationSystem.civilizations:
			if not civ is Dictionary: continue
			var rel:Dictionary=(civ as Dictionary).get("player_relation",{})
			if int(rel.get("contact_level",0))<1: continue
			var tension:=float(rel.get("border_tension",0.0))+(0.6 if bool(rel.get("at_war",false)) else 0.0)
			if tension>worst: worst=tension; best={"civ_id":String(civ.id),"day":-1,"situation":"tension"}
	return best

static func _cand_fear(by:Dictionary,rng:RandomNumberGenerator)->Dictionary:
	var slight:=_slighted_by()
	if slight.is_empty(): return {}
	var civ_id:=String(slight.civ_id)
	var name:=_civ_name(civ_id)
	var years:=rng.randi_range(8,12)
	var c:=_base("fear",by,years)
	var dread:=DIVINE.civ_dread(civ_id)
	c.subject=civ_id; c.subject_name=name.substr(0,60)
	c.target=clampf(dread+0.25,0.3,0.9); c.baseline=dread
	c.title="Make %s Fear Our Name" % _the(name)
	c.phrase="make %s fear our name" % _the(name)
	match String(slight.situation):
		"tribute_demand","emboldened_demand": c.why="Their messenger stood at our fire and demanded tribute, as if we were their dogs."
		"test_of_resolve": c.why="They came to see whether we would flinch. Some of us did."
		"tension": c.why="They press on our hunting grounds and laugh about it at their fires."
		_: c.why="They have slighted us, and they think we have forgotten."
	c.legacy="the Years %s Trembled" % _the(name)
	return c

static func _cand_friend(by:Dictionary,rng:RandomNumberGenerator)->Dictionary:
	var best:Dictionary={}
	for civ in CivilizationSystem.civilizations:
		if not civ is Dictionary: continue
		var rel:Dictionary=(civ as Dictionary).get("player_relation",{})
		if int(rel.get("contact_level",0))<2 or bool(rel.get("at_war",false)): continue
		var opinion:=float(rel.get("opinion",0.0))
		if opinion< -0.25 or opinion>0.6: continue
		if best.is_empty() or opinion>float(best.opinion): best={"civ_id":String(civ.id),"name":String(civ.name),"opinion":opinion}
	if best.is_empty(): return {}
	var years:=rng.randi_range(8,12)
	var c:=_base("friend",by,years)
	c.subject=String(best.civ_id); c.subject_name=String(best.name).substr(0,60)
	c.target=minf(0.85,float(best.opinion)+0.3); c.baseline=float(best.opinion)
	c.title="Bind %s to Us in Friendship" % _the(String(best.name))
	c.phrase="bind %s to us, so that their children and ours share a fire" % _the(String(best.name))
	c.why="%s are near, and a neighbour is either a friend or a danger." % _cap(_the(String(best.name)))
	c.legacy="the Bond with %s" % _the(String(best.name))
	return c

static func _cand_settle(by:Dictionary,rng:RandomNumberGenerator)->Dictionary:
	var count:=GameState.player_settlements.size()
	if GameState.population_total<90 or count>=6: return {}
	var years:=rng.randi_range(8,12)
	var c:=_base("settle",by,years)
	c.target=count+1; c.baseline=count
	c.title="Found a Daughter Hearth" if count<=1 else "Found a New Hearth"
	c.phrase="send our young ones out to found a daughter hearth of their own"
	c.why="The young ones want a hearth of their own, and the land beyond the ridge is empty."
	c.legacy="the Daughter Hearth" if count<=1 else "the New Hearth"
	return c

static func _cand_work(by:Dictionary,rng:RandomNumberGenerator,memorial:Dictionary={})->Dictionary:
	var pop:=GameState.population_total
	var years:=rng.randi_range(6,9)
	var c:=_base("work",by,years)
	var typical:=float(WORK_PERSON_DAYS.typical)
	c.target=clampf(float(pop)*18.0,float(WORK_PERSON_DAYS.low)*2.0,typical*2.0); c.baseline=0.0; c.acc=0.0; c.share=WORK_SHARE
	if not memorial.is_empty():
		var given:=String(memorial.get("given",""))
		c.subject=String(memorial.get("key","")); c.subject_name=given
		c.title="Raise a Cairn for %s" % given
		c.phrase="raise a cairn for %s that our grandchildren will see" % given
		c.why="%s is gone, and the grass is already closing over the place. I would not have them forgotten." % given
		c.legacy="%s's Cairn" % given
	else:
		c.title="Raise a Ring of Standing Stones"
		c.phrase="raise a ring of standing stones the whole valley can see"
		c.why="Anyone can live in a place. A people leaves a mark on it."
		c.legacy="%s's Ring" % String(c.by_given) if String(c.by_given)!="" else "the Stone Ring"
	return c

static func _cand_unity(by:Dictionary,rng:RandomNumberGenerator)->Dictionary:
	var years:=rng.randi_range(5,8)
	var c:=_base("unity",by,years)
	var coh:=float(GameState.simulation_metrics.get("cohesion",0.58))
	c.target=minf(0.95,coh+0.06); c.baseline=coh
	c.title="Keep One Fire"
	c.phrase="keep every hearth at one fire, with no family splitting away"
	c.why="The quarrels between the hearths are louder than they were."
	c.legacy="the One Fire"
	return c

static func _memorial()->Dictionary:
	## Someone remembered who died in the last three years (court_lives roll).
	for entry in Lives.remembered(6):
		var died:=int(entry.get("died",entry.get("day",-99999)))
		if _day()-died>1095: continue
		var name:=String(entry.get("name",""))
		if name=="": continue
		return {"given":EraNames.given_of(name),"key":"dead:%d" % int(entry.get("pid",0))}
	return {}

static func _build(template:String,by:Dictionary,rng:RandomNumberGenerator)->Dictionary:
	match template:
		"grow": return _cand_grow(by,rng)
		"plenty": return _cand_plenty(by,rng)
		"learn": return _cand_learn(by,rng)
		"knowledge": return _cand_knowledge(by,rng)
		"reach": return _cand_reach(by,rng)
		"fear": return _cand_fear(by,rng)
		"friend": return _cand_friend(by,rng)
		"settle": return _cand_settle(by,rng)
		"work": return _cand_work(by,rng,_memorial() if by.get("source","")=="people" else {})
		"unity": return _cand_unity(by,rng)
	return {}

static func _recent(template:String,day:int)->bool:
	var used:Dictionary=state().used
	return used.has(template) and day-int(used[template])<REPEAT_DAYS

static func _condition_scores(day:int)->Dictionary:
	## How strongly the real state asks for each template right now.
	var s:=state()
	var scores:Dictionary={}
	for t in TEMPLATES: scores[t]=0.3
	var metrics:Dictionary=GameState.simulation_metrics
	if int(s.low_food_day)>=0 and day-int(s.low_food_day)<365: scores.plenty=2.5
	elif float(metrics.get("food_days",30.0))<30.0: scores.plenty=1.0
	if observed_growth()< -0.2: scores.grow=1.8
	else: scores.grow=0.8
	if not _slighted_by().is_empty(): scores.fear=2.2
	if not _memorial().is_empty(): scores.work=1.6
	var half:=_half_learned()
	if not half.is_empty(): scores.learn=2.0 if bool(half.crossing) else 1.2
	scores.knowledge=0.6
	for civ in CivilizationSystem.civilizations:
		if not civ is Dictionary: continue
		var level:=int(((civ as Dictionary).get("player_relation",{}) as Dictionary).get("contact_level",0))
		if level==1: scores.reach=1.4
		if level>=2: scores.friend=maxf(float(scores.friend),0.9)
	if GameState.player_settlements.size()<=1 and GameState.population_total>=110: scores.settle=1.0
	if float(metrics.get("cohesion",0.58))<0.5: scores.unity=1.5
	# The century's ambition colours what the court reaches for.
	var ambition:=String(PeopleDirection.ambition)
	for t in scores:
		if String((TEMPLATES[t] as Dictionary).focus)==ambition or _focus_aligned(String(t)): scores[t]=float(scores[t])+0.5
		if _recent(String(t),day): scores[t]=float(scores[t])*0.15
	return scores

static func _officials()->Array[Dictionary]:
	return Hall._officials()

static func propose(day:int,crisis:bool=false)->Array[Dictionary]:
	## Two or three aims from different voices: the official best placed to
	## speak, a second official, and the people at the fires.
	var officials:=_officials()
	var scores:=_condition_scores(day)
	var rng:=_rng("propose:%d" % day)
	var out:Array[Dictionary]=[]
	var taken:Dictionary={}
	var active_t:=String((state().active as Dictionary).get("template",""))
	if active_t!="": taken[active_t]=true
	var ranked:Array=scores.keys()
	ranked.sort_custom(func(a:Variant,b:Variant)->bool:return float(scores[a])>float(scores[b]) or (float(scores[a])==float(scores[b]) and String(a)<String(b)))
	# Officials first: each speaks for what their office cares about most.
	var speakers:Array[Dictionary]=[]
	for person in officials:
		var best:=""
		for t in ranked:
			if taken.has(t): continue
			var office:=String(person.get("office_key",""))
			if office in (TEMPLATES[t] as Dictionary).offices or (office=="settlement" and "settlement" in (TEMPLATES[t] as Dictionary).offices):
				best=String(t); break
		if best=="": continue
		var by:=person.duplicate(); by["source"]="official"
		var cand:=_build(best,by,rng)
		if cand.is_empty(): continue
		cand["score"]=float(scores[best])
		speakers.append(cand)
	speakers.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return float(a.score)>float(b.score))
	for cand in speakers:
		if out.size()>=2: break
		if taken.has(String(cand.template)): continue
		taken[String(cand.template)]=true
		out.append(cand)
	# The people: the strongest condition not yet spoken for.
	for t in ranked:
		if taken.has(t) or out.size()>=3: continue
		var cand:=_build(String(t),{"source":"people","name":"","person_id":0},rng)
		if cand.is_empty(): continue
		taken[String(t)]=true
		out.append(cand)
		break
	# Never a single voice: fill from what remains.
	for t in ranked:
		if out.size()>=2: break
		if taken.has(t): continue
		var by:=officials[0].duplicate() if not officials.is_empty() else {"source":"people"}
		if not by.has("source"): by["source"]="official"
		var cand:=_build(String(t),by,rng)
		if cand.is_empty(): continue
		taken[String(t)]=true
		out.append(cand)
	if crisis and not out.is_empty(): out.resize(1)
	return out

# --------------------------------------------------------------------------
# Matters: aims wait at court
# --------------------------------------------------------------------------

static func _holder_for(cands:Array[Dictionary])->Dictionary:
	var officials:=_officials()
	for cand in cands:
		for person in officials:
			if int(person.get("person_id",0))==int(cand.get("by_pid",0)) and int(cand.get("by_pid",0))>0: return person
	for person in officials:
		if String(person.get("office_key",""))=="Steward": return person
	return officials[0] if not officials.is_empty() else {}

static func _store_candidate(cand:Dictionary)->void:
	var list:Dictionary=state().candidates
	list[String(cand.cid)]=cand
	while list.size()>CANDIDATES_MAX:
		var oldest:=""
		for key in list:
			if oldest=="" or String(key).trim_prefix("a").to_int()<String(oldest).trim_prefix("a").to_int(): oldest=String(key)
		list.erase(oldest)

static func _option_sub(cand:Dictionary)->String:
	var who:="The people ask it." if String(cand.get("source",""))=="people" else ("You declare it." if String(cand.get("source",""))=="god" else "%s proposes it." % String(cand.get("by_given","")))
	return ("%s, within %s. %s" % [_cap(String(cand.get("phrase",""))),winters(int(cand.get("years",MIN_YEARS))),who]).substr(0,220)

static func file_proposal(day:int,cands:Array[Dictionary],mode:String="propose")->Dictionary:
	## Files the proposal as a court matter held by the leading official.
	if cands.is_empty(): return {}
	var holder:=_holder_for(cands)
	if holder.is_empty(): return {}
	var s:=state()
	var rows:Array=[]
	var titles:PackedStringArray=PackedStringArray()
	for cand in cands:
		_store_candidate(cand)
		rows.append({"cid":String(cand.cid),"title":String(cand.title).substr(0,80),"by":String(cand.get("by_given","")) if String(cand.source)!="people" else "the people"})
		titles.append(String(cand.title))
	var audience:=Hall._new_audience("court","petition",day)
	audience.speaker={"name":String(holder.get("name","")).substr(0,100),"title":String(holder.get("office_title","Official")).substr(0,100),"person_id":int(holder.get("person_id",0)),"role":"official"}
	var summary:=""
	if mode=="crisis":
		summary="%s would have us set our aim aside for this: %s." % [String(holder.get("name","")),titles[0]]
	else:
		summary="What should our children say of us? The court speaks of: %s." % "; ".join(titles)
	audience.petition={"topic":"aim","summary":summary.substr(0,400),"suggested_decree":""}
	audience.situation={"type":"aim","ask":"aim:%d" % int(s.serial),"headline":"speaks of what we should strive for","summary":summary.substr(0,400),
		"occasion":{"type":"aim","text":"what our children should say of us","day":day,"crisis":mode=="crisis"},
		"aim":{"mode":mode,"candidates":rows}}
	var entry:=Hall._file_matter(audience,[])
	s.matter_id=String(entry.get("id",""))
	s.matter_day=day
	s.stats.proposals=int(s.stats.proposals)+1
	_log("proposed",summary,{"mode":mode,"holder":String(holder.get("name","")),"titles":" | ".join(titles)})
	Chronicle.record({"key":"aim:proposed:%d:%s" % [day,String(cands[0].cid)],"title":"The Court Speaks of an Aim" if mode!="crisis" else "A Call to Set Our Aim Aside",
		"text":"%s waits to be summoned. %s" % [String(holder.get("name","")),summary],"tier":"notice","kind":"court","domain":"institutions",
		"action":{"kind":"court","focus":{"person_id":int(holder.get("person_id",0))}},"ledger":false})
	return entry

static func file_course(day:int)->Dictionary:
	## Halfway and falling behind: the aim's keeper comes back to court.
	var s:=state()
	var aim:Dictionary=s.active
	if aim.is_empty(): return {}
	var officials:=_officials()
	var holder:Dictionary={}
	for person in officials:
		if int(person.get("person_id",0))==int(aim.get("by_pid",0)): holder=person
	if holder.is_empty(): holder=_holder_for([aim])
	if holder.is_empty(): return {}
	var audience:=Hall._new_audience("court","petition",day)
	audience.speaker={"name":String(holder.get("name","")).substr(0,100),"title":String(holder.get("office_title","Official")).substr(0,100),"person_id":int(holder.get("person_id",0)),"role":"official"}
	var left:=maxi(0,int(ceil((int(aim.deadline)-day)/365.0)))
	var summary:="%s: %s, and %s left." % [String(aim.title),value_words(aim),winters(left)]
	audience.petition={"topic":"aim","summary":summary.substr(0,400),"suggested_decree":""}
	audience.situation={"type":"aim","ask":"aim:course:%s" % String(aim.id),"headline":"comes about our aim","summary":summary.substr(0,400),
		"occasion":{"type":"aim","text":"how our aim goes","day":day,"crisis":false},"aim":{"mode":"course","aim_id":String(aim.id)}}
	var entry:=Hall._file_matter(audience,[])
	s.matter_id=String(entry.get("id",""))
	s.matter_day=day
	aim["course_filed"]=day
	_log("course",summary,{"holder":String(holder.get("name",""))})
	Chronicle.record({"key":"aim:course:%s" % String(aim.id),"title":"Our Aim Falters","text":"%s. %s would speak with the god about it." % [summary,String(holder.get("name",""))],
		"tier":"notice","kind":"court","domain":"institutions","action":{"kind":"court","focus":{"person_id":int(holder.get("person_id",0))}},"ledger":false})
	return entry

static func file_halfway(day:int)->Dictionary:
	## Halfway there: the aim's keeper asks how the people should mark it.
	var s:=state()
	var aim:Dictionary=s.active
	if aim.is_empty(): return {}
	var holder:Dictionary={}
	for person in _officials():
		if int(person.get("person_id",0))==int(aim.get("by_pid",0)): holder=person
	if holder.is_empty(): holder=_holder_for([aim])
	if holder.is_empty(): return {}
	var audience:=Hall._new_audience("court","petition",day)
	audience.speaker={"name":String(holder.get("name","")).substr(0,100),"title":String(holder.get("office_title","Official")).substr(0,100),"person_id":int(holder.get("person_id",0)),"role":"official"}
	var summary:="%s is half done: %s. The people want to mark it." % [String(aim.title),value_words(aim)]
	audience.petition={"topic":"aim","summary":summary.substr(0,400),"suggested_decree":""}
	audience.situation={"type":"aim","ask":"aim:halfway:%s" % String(aim.id),"headline":"comes about our aim","summary":summary.substr(0,400),
		"occasion":{"type":"aim","text":"halfway to our aim","day":day,"crisis":false},"aim":{"mode":"halfway","aim_id":String(aim.id)}}
	var entry:=Hall._file_matter(audience,[])
	s.matter_id=String(entry.get("id",""))
	s.matter_day=day
	_log("halfway",summary,{"holder":String(holder.get("name",""))})
	return entry

static func _matter_live(matter_id:String)->bool:
	## The proposal still waits: as a matter (perhaps refiled after being set
	## aside for another) or as an audience the god has opened.
	for m in Hall.state().matters:
		if not m is Dictionary: continue
		if String(m.get("id",""))==matter_id: return true
		if String(m.get("situation_type",""))=="aim":
			state().matter_id=String(m.get("id",""))
			return true
	for audience in Hall.state().queue:
		if not audience is Dictionary or String(audience.get("status",""))!="waiting": continue
		var situation:Dictionary=audience.get("situation",{}) if audience.get("situation") is Dictionary else {}
		if String(situation.get("type",""))=="aim": return true
	return false

static func pending_matter()->Dictionary:
	var id:=String(state().matter_id)
	if id=="": return {}
	for m in Hall.state().matters:
		if m is Dictionary and String(m.get("id",""))==id: return m
	return {}

static func _watch_matter(day:int)->void:
	## A proposal the god never heard: the people take up the aim themselves.
	var s:=state()
	var id:=String(s.matter_id)
	if id=="" or _matter_live(id): return
	s.matter_id=""
	var last:Dictionary={}
	for entry in s.log:
		if entry is Dictionary and String(entry.get("kind","")) in ["proposed","course"]: last=entry; break
	if String(last.get("kind",""))!="proposed" or String(last.get("mode",""))=="crisis" or has_active(): return
	# The last proposal's candidates, in the order they were put.
	var first:Dictionary={}
	var people:Dictionary={}
	for key in s.candidates:
		var cand:Dictionary=s.candidates[key]
		if int(cand.get("proposed_day",-1))!=int(s.matter_day): continue
		if first.is_empty() or String(cand.cid).trim_prefix("a").to_int()<String(first.cid).trim_prefix("a").to_int(): first=cand
		if String(cand.get("source",""))=="people": people=cand
	var chosen:=people if not people.is_empty() else first
	if chosen.is_empty(): s.next_proposal_day=day+60; return
	s.stats.people_took=int(s.stats.people_took)+1
	adopt(chosen,"people",day)

static func _maybe_propose(day:int)->void:
	var s:=state()
	if String(s.matter_id)!="": return
	if int(s.next_proposal_day)<0:
		s.next_proposal_day=maxi(GameState.settlement_founded_day,0)+FIRST_PROPOSAL_DAYS
	if has_active():
		# A crisis can call the court to set the aim aside: hunger, a slight.
		if day-int(s.crisis_day)<CRISIS_GAP or day-int((s.active as Dictionary).get("start_day",day))<365: return
		var scores:=_condition_scores(day)
		var active_t:=String((s.active as Dictionary).template)
		var urgent:=""
		for t in ["plenty","fear"]:
			if t!=active_t and float(scores.get(t,0.0))>=2.2 and not _recent(t,day): urgent=t
		if urgent=="": return
		var holder:=_holder_for([])
		var by:=holder.duplicate(); by["source"]="official"
		var cand:=_build(urgent,by,_rng("crisis:%d" % day))
		if cand.is_empty(): return
		cand["proposed_day"]=day
		s.crisis_day=day
		file_proposal(day,[cand],"crisis")
		return
	if day<int(s.next_proposal_day) or _officials().is_empty(): return
	var cands:=propose(day)
	if cands.is_empty(): s.next_proposal_day=day+90; return
	for cand in cands: cand["proposed_day"]=day
	file_proposal(day,cands)

# --------------------------------------------------------------------------
# The court: staging, options, answers
# --------------------------------------------------------------------------

static func on_open(audience:Dictionary)->void:
	var situation:Dictionary=audience.get("situation",{}) if audience.get("situation") is Dictionary else {}
	if String(situation.get("type",""))!="aim": return
	var aim_part:Dictionary=situation.get("aim",{}) if situation.get("aim") is Dictionary else {}
	var id:=String(audience.id)
	var speaker:Dictionary=audience.get("speaker",{})
	var holder:=GovernmentPeopleSystem.person_snapshot(int(speaker.get("person_id",0)))
	if holder.is_empty(): holder={"person_id":int(speaker.get("person_id",0)),"name":String(speaker.get("name",""))}
	if String(aim_part.get("mode",""))=="course":
		var aim:Dictionary=state().active
		if aim.is_empty(): return
		var left:=maxi(0,int(ceil((int(aim.deadline)-_day())/365.0)))
		_line(audience,holder,"%s. %s, and %s left. At this pace we will not do it. Tell me what you want of us." % [String(aim.title),_cap(value_words(aim)),winters(left)])
		return
	if String(aim_part.get("mode",""))=="halfway":
		var aim:Dictionary=state().active
		if aim.is_empty(): return
		_narrate(audience,"[%s comes in with dust on their feet and something like a smile.]" % EraNames.given_of(String(holder.get("name","Someone"))))
		_line(audience,holder,"We are halfway there. We set out to %s, and now it is %s. The people want to mark it before we go on. A feast, or a stone to show how far we have come, or no rest at all. It is yours to say." % [String(aim.phrase),value_words(aim)])
		return
	_narrate(audience,"[The fire is built high. %s has asked to speak of what the people should strive for.]" % EraNames.given_of(String(holder.get("name","Someone"))))
	var spoke_people:=false
	for row_variant in aim_part.get("candidates",[]):
		var row:Dictionary=row_variant
		var cand:Dictionary=(state().candidates as Dictionary).get(String(row.get("cid","")),{})
		if cand.is_empty(): continue
		var tokens:={"aim":String(cand.phrase),"why":String(cand.why),"why_low":String(cand.why),"years":winters(int(cand.years))}
		if String(cand.get("source",""))=="people":
			if spoke_people: continue
			spoke_people=true
			_narrate(audience,_say(Lines.PEOPLE,tokens,"people:%s" % String(cand.cid),Lines.PEOPLE))
			continue
		var person:=GovernmentPeopleSystem.person_snapshot(int(cand.get("by_pid",0)))
		if person.is_empty(): person=holder
		var model:=_manner(person)
		_line(audience,person,_say(Lines.URGE.get(model,[]),tokens,"urge:%s" % String(cand.cid)))
	if String(aim_part.get("mode",""))=="crisis" and has_active():
		var aim:Dictionary=state().active
		_narrate(audience,"[Others at the fire shake their heads. We are sworn to %s: %s.]" % [String(aim.title),value_words(aim)])

static func _line(audience:Dictionary,person:Dictionary,text:String,aside:bool=false)->void:
	if text.strip_edges()=="": return
	Hall.append_line(String(audience.id),{"speaker":String(person.get("name","")),"role":"official","person_id":int(person.get("person_id",0)),"civ_id":"player","text":text,"day":_day(),"aside":aside})

static func _narrate(audience:Dictionary,text:String)->void:
	if text.strip_edges()=="": return
	Hall.append_line(String(audience.id),{"speaker":"","role":"narrator","person_id":0,"civ_id":"","text":text,"day":_day(),"aside":false})

static func options(audience:Dictionary)->Array[Dictionary]:
	var out:Array[Dictionary]=[]
	var situation:Dictionary=audience.get("situation",{}) if audience.get("situation") is Dictionary else {}
	var aim_part:Dictionary=situation.get("aim",{}) if situation.get("aim") is Dictionary else {}
	if String(aim_part.get("mode",""))=="course":
		var aim:Dictionary=state().active
		if aim.is_empty() or String(aim.get("id",""))!=String(aim_part.get("aim_id","")):
			out.append(Hall._option("aim_hold","It is past","The aim this was about has already been settled.","neutral"))
			return out
		var template:=String(aim.template)
		var press_sub:="Drive them harder: more hands to it. Some will grumble; the court will fear your eye."
		if template=="friend": press_sub="Send gifts of food to %s from our stores." % _the(String(aim.subject_name))
		elif template=="fear": press_sub="A show of strength at the border. %s will hear of it." % _cap(_the(String(aim.subject_name)))
		out.append(Hall._option("aim_press","Press harder",press_sub,"hostile"))
		var total:=int(aim.deadline)-int(aim.start_day)
		out.append(Hall._option("aim_extend","Give it two more winters","The people will have longer; some will say the god has doubts.","neutral",total+730<=MAX_YEARS*365,"The aim cannot run past %s." % winters(MAX_YEARS)))
		out.append(Hall._option("aim_hold","Hold the course","Change nothing; trust the people.","warm"))
		out.append(Hall._option("aim_release","Let the aim go","Set it down before it breaks them. There will be sorrow.","hostile"))
		return out
	if String(aim_part.get("mode",""))=="halfway":
		var aim:Dictionary=state().active
		if aim.is_empty() or String(aim.get("id",""))!=String(aim_part.get("aim_id","")):
			out.append(Hall._option("aim_hold","It is past","The aim this was about has already been settled.","neutral"))
			return out
		var food:=_feast_food()
		var short:=Hall._short("Food",food)
		out.append(Hall._option("aim_feast","Hold a feast","Share %d Food from the stores at one great fire. The people will love you for it." % roundi(food),"warm",short=="",short))
		out.append(Hall._option("aim_mark","Raise a marker stone","A stone at the edge of the camp to show how far they have come.","warm"))
		out.append(Hall._option("aim_onward","No rest: go on","Not a day lost. Some will grumble; the court will fear your eye.","hostile"))
		return out
	for row_variant in aim_part.get("candidates",[]):
		var row:Dictionary=row_variant
		var cand:Dictionary=(state().candidates as Dictionary).get(String(row.get("cid","")),{})
		if cand.is_empty(): continue
		var label:=String(cand.title).substr(0,70)
		out.append(Hall._option("aim_adopt:%s" % String(cand.cid),label,_option_sub(cand),"warm"))
	if String(aim_part.get("mode",""))=="crisis":
		out.append(Hall._option("aim_keep","Hold to our aim","We keep the aim we swore. The call is heard, and set aside.","neutral"))
	else:
		out.append(Hall._option("aim_wait","Not yet","Let the people wait for a better aim. If you stay silent too long, they will choose one themselves.","neutral"))
	return out

static func resolve(audience:Dictionary,option_id:String)->Dictionary:
	## The god's answer. A refused answer leaves the matter waiting.
	var s:=state()
	var held:=String(s.matter_id)
	s.matter_id=""
	var result:=_answer(audience,option_id)
	if result.has("error"):
		s.matter_id=held
		return result
	s.stats.decisions=int(s.stats.decisions)+1
	return result

static func _answer(audience:Dictionary,option_id:String)->Dictionary:
	var s:=state()
	var day:=_day()
	var situation:Dictionary=audience.get("situation",{}) if audience.get("situation") is Dictionary else {}
	var aim_part:Dictionary=situation.get("aim",{}) if situation.get("aim") is Dictionary else {}
	var speaker:Dictionary=audience.get("speaker",{})
	var pid:=int(speaker.get("person_id",0))
	if option_id.begins_with("aim_adopt:"):
		var cid:=option_id.trim_prefix("aim_adopt:")
		var cand:Dictionary=(s.candidates as Dictionary).get(cid,{})
		if cand.is_empty(): return {"error":"That aim is no longer spoken of."}
		if has_active():
			release("set aside for %s" % String(cand.title))
		var aim:=adopt(cand,"god",day)
		# The one who proposed it is proud; those passed over, a little stung.
		for row_variant in aim_part.get("candidates",[]):
			var other:Dictionary=(s.candidates as Dictionary).get(String((row_variant as Dictionary).get("cid","")),{})
			var other_pid:=int(other.get("by_pid",0))
			if other_pid<=0 or String(other.get("source",""))!="official": continue
			if String(other.cid)==cid:
				GovernmentPeopleSystem.adjust_person_bonds(other_pid,{"trust":0.05,"love":0.04})
				GovernmentPeopleSystem.record_person_memory(other_pid,"The god took up the aim I put before the fire: %s." % String(cand.title),"aim",0.8,{"emotion":"pride"})
			else:
				GovernmentPeopleSystem.adjust_person_bonds(other_pid,{"resentment":0.02})
				GovernmentPeopleSystem.record_person_memory(other_pid,"The god passed over the aim I proposed for %s." % String(cand.title),"aim",0.4,{"emotion":"slighted"})
		var aside:=_pick(Lines.TAKEN,"taken:%s" % String(cand.cid))
		var bench:=Hall.court(String(audience.id))
		if not bench.is_empty() and aside!="": _line(audience,bench[0],aside,true)
		return {"outcome":"You set the people an aim: %s. They have %s. %s" % [String(cand.title),winters(int(aim.years)),"It was %s's proposal." % String(cand.by_given) if String(cand.get("by_given",""))!="" and String(cand.source)=="official" else ""],"reaction":"delighted"}
	match option_id:
		"aim_wait":
			s.next_proposal_day=day+_rng("wait:%d" % day).randi_range(150,300)
			_log("waited","The god bid the people wait for a better aim.")
			if pid>0: GovernmentPeopleSystem.adjust_person_bonds(pid,{"trust":-0.01})
			return {"outcome":"You told them to wait. The talk at the fires goes on without an answer.","reaction":"neutral"}
		"aim_keep":
			_log("kept","The god held to the aim already sworn.")
			return {"outcome":"You held to the aim already sworn: %s." % String((s.active as Dictionary).get("title","our aim")),"reaction":"pleased"}
		"aim_hold":
			_log("held","The god bid the people hold the course.")
			if pid>0: GovernmentPeopleSystem.adjust_person_bonds(pid,{"trust":0.02})
			return {"outcome":"You told them to hold the course.","reaction":"pleased"}
		"aim_extend":
			var aim:Dictionary=s.active
			if aim.is_empty(): return {"error":"There is no aim to extend."}
			aim.deadline=mini(int(aim.deadline)+730,int(aim.start_day)+MAX_YEARS*365)
			aim["extended"]=int(aim.get("extended",0))+1
			GameState.simulation_metrics["legitimacy"]=clampf(float(GameState.simulation_metrics.get("legitimacy",0.5))-0.005,0.01,0.99)
			_log("extended","The god gave %s two more winters." % String(aim.title))
			return {"outcome":"You gave them two more winters for %s." % String(aim.title),"reaction":"pleased"}
		"aim_press":
			var aim:Dictionary=s.active
			if aim.is_empty(): return {"error":"There is no aim to press."}
			return _press(aim,pid)
		"aim_feast":
			var aim:Dictionary=s.active
			if aim.is_empty(): return {"error":"There is no aim to mark."}
			var paid:=Hall._debit_player("Food",_feast_food())
			_bonds_all({"love":0.03,"hold_days":45})
			GameState.simulation_metrics["cohesion"]=clampf(float(GameState.simulation_metrics.get("cohesion",0.58))+0.01,0.01,0.99)
			Lives._mark_rite("bonfire","%s, half done" % String(aim.title),day,4,pid)
			_log("feast","A feast for halfway to %s." % String(aim.title))
			return {"outcome":"You gave them a feast: %d Food at one great fire, for an aim half done. They sang about it for days." % roundi(paid),"reaction":"delighted"}
		"aim_mark":
			var aim:Dictionary=s.active
			if aim.is_empty(): return {"error":"There is no aim to mark."}
			GameState.simulation_metrics["legitimacy"]=clampf(float(GameState.simulation_metrics.get("legitimacy",0.5))+0.005,0.01,0.99)
			if pid>0: GovernmentPeopleSystem.adjust_person_bonds(pid,{"trust":0.02})
			Lives._mark_rite("cairn","%s, half done" % String(aim.title),day,8,pid)
			_log("marked","A marker stone for halfway to %s." % String(aim.title))
			return {"outcome":"A stone stands at the edge of the camp to show how far they have come. The children climb it.","reaction":"pleased"}
		"aim_onward":
			var aim:Dictionary=s.active
			if aim.is_empty(): return {"error":"There is no aim to press."}
			GameState.simulation_metrics["cohesion"]=clampf(float(GameState.simulation_metrics.get("cohesion",0.58))-0.005,0.01,0.99)
			for person in _officials(): GovernmentPeopleSystem.adjust_person_bonds(int(person.person_id),{"fear":0.01,"hold_days":20})
			PeopleDirection.record_cultural_action("aim:"+String(aim.template),String(aim.focus),0.5)
			PeopleDirection.inclination_review_day=-1
			_log("onward","No rest on the way to %s." % String(aim.title))
			return {"outcome":"No rest, you told them. They went back to it with their heads down.","reaction":"neutral"}
		"aim_release":
			if not has_active(): return {"error":"There is no aim to let go."}
			var title:=String((s.active as Dictionary).title)
			release("let go by the god's word")
			return {"outcome":"You let %s go. The people are quiet tonight." % title,"reaction":"neutral"}
	return {"error":"That answer is not open to you here."}

static func _feast_food()->float:
	return Hall._nice(clampf(float(GameState.population_total)*0.25,10.0,80.0))

static func _press(aim:Dictionary,pid:int)->Dictionary:
	aim["pressed"]=int(aim.get("pressed",0))+1
	var metrics:Dictionary=GameState.simulation_metrics
	metrics["cohesion"]=clampf(float(metrics.get("cohesion",0.58))-0.01,0.01,0.99)
	for person in _officials(): GovernmentPeopleSystem.adjust_person_bonds(int(person.person_id),{"fear":0.02,"hold_days":30})
	var template:=String(aim.template)
	var outcome:="You pressed them harder for %s." % String(aim.title)
	var result:={"reaction":"pleased"}
	match template:
		"work": aim.share=WORK_PRESSED_SHARE
		"friend":
			var civ_id:=String(aim.subject)
			var gift:=Hall._nice(clampf(float(GameState.population_total)*0.2,10.0,60.0))
			var paid:=Hall._debit_player("Food",gift)
			if paid>0.0:
				Hall._credit_civ(civ_id,"Food",paid)
				Hall._shift_relation(civ_id,0.05,-0.02)
				outcome="You sent %d Food to %s as a gift, for %s." % [roundi(paid),_the(String(aim.subject_name)),String(aim.title)]
		"fear":
			var civ_id:=String(aim.subject)
			DIVINE.add_civ_dread(civ_id,0.05)
			Hall._shift_relation(civ_id,-0.02,0.04)
			outcome="You showed your strength at the border. %s will hear of it." % _cap(_the(String(aim.subject_name)))
	if PRESS_DECREES.has(template) and template not in ["friend"]:
		result["decree"]=String(PRESS_DECREES[template])
	PeopleDirection.record_cultural_action("aim:"+template,String(aim.focus),1.0)
	PeopleDirection.inclination_review_day=-1
	_log("pressed",outcome)
	result["outcome"]=outcome
	return result

# --------------------------------------------------------------------------
# Typed aims
# --------------------------------------------------------------------------

static func is_aim_audience(audience_id:String)->bool:
	var audience:=Hall.find(audience_id)
	var situation:Dictionary=audience.get("situation",{}) if audience.get("situation") is Dictionary else {}
	return String(situation.get("type",""))=="aim" and String(audience.get("status",""))=="waiting"

static func template_of_words(text:String)->String:
	var lower:=" "+text.to_lower()+" "
	var best:=""; var best_hits:=0
	for t in TEMPLATES:
		var hits:=0
		for word in (TEMPLATES[t] as Dictionary).words:
			if lower.contains(" "+String(word)): hits+=1
		if hits>best_hits: best=String(t); best_hits=hits
	for word in CROSSING_WORDS:
		if lower.contains(" "+word) and (best=="" or best_hits<=1): return "learn" if not _half_learned().is_empty() and bool(_half_learned().crossing) else "work"
	return best

static func typed_choice(audience_id:String,text:String,live:bool)->String:
	## The god's own words in an aim audience. Names one of the proposed aims
	## ("the stones"), answers a course question ("give them longer"), or, with a
	## live voice, declares an aim of the god's own. Returns an option id or "".
	if not is_aim_audience(audience_id): return ""
	var audience:=Hall.find(audience_id)
	var aim_part:Dictionary=((audience.get("situation",{}) as Dictionary).get("aim",{})) if (audience.get("situation",{}) as Dictionary).get("aim") is Dictionary else {}
	var lower:=" "+text.to_lower().replace(","," ").replace("."," ").replace("!"," ").replace("?"," ")+" "
	if String(aim_part.get("mode",""))=="halfway":
		for pair in [[["feast","eat","share the food"],"aim_feast"],[["stone","cairn","marker","mark it"],"aim_mark"],[["no rest","go on","keep working","onward","press"],"aim_onward"]]:
			for word in pair[0]:
				if lower.contains(String(word)): return String(pair[1])
		return ""
	if String(aim_part.get("mode",""))=="course":
		for pair in [[["harder","press","drive","push","more hands"],"aim_press"],[["longer","more time","more winters","extend"],"aim_extend"],[["let it go","give it up","abandon","release","set it down"],"aim_release"],[["hold","keep going","stay","continue","trust"],"aim_hold"]]:
			for word in pair[0]:
				if lower.contains(String(word)): return String(pair[1])
		return ""
	if lower.contains(" not yet ") or lower.contains(" wait "): return "aim_wait" if String(aim_part.get("mode",""))!="crisis" else "aim_keep"
	var template:=template_of_words(text)
	var found:=""
	for row_variant in aim_part.get("candidates",[]):
		var cand:Dictionary=(state().candidates as Dictionary).get(String((row_variant as Dictionary).get("cid","")),{})
		if cand.is_empty(): continue
		var named:=String(cand.get("subject_name","")).to_lower()
		if String(cand.template)==template or (named.length()>=3 and lower.contains(named)):
			if found!="": found="#"; break
			found="aim_adopt:%s" % String(cand.cid)
	if found!="" and found!="#": return found
	if not live: return ""
	var mine:=from_words(text)
	if mine.is_empty(): return ""
	mine["proposed_day"]=_day()
	_store_candidate(mine)
	var rows:Array=aim_part.get("candidates",[])
	rows.append({"cid":String(mine.cid),"title":String(mine.title).substr(0,80),"by":"the god"})
	return "aim_adopt:%s" % String(mine.cid)

static func from_words(text:String)->Dictionary:
	## Any aim the god speaks is accepted and mapped onto the nearest
	## measurable target, kept within what history says a people can do.
	var words:=text.strip_edges()
	if words.length()<3: return {}
	var god:={"source":"god","name":"","person_id":0}
	var template:=template_of_words(words)
	var lower:=" "+words.to_lower()+" "
	var rng:=_rng("typed:%d:%s" % [_day(),words.md5_text()])
	var named_civ:=""
	for civ in CivilizationSystem.civilizations:
		if not civ is Dictionary: continue
		if int(((civ as Dictionary).get("player_relation",{}) as Dictionary).get("contact_level",0))<1: continue
		var cname:=String(civ.name).to_lower().trim_prefix("the ")
		if cname.length()>=3 and lower.contains(cname): named_civ=String(civ.id)
	var cand:Dictionary={}
	match template:
		"fear","friend":
			if named_civ=="":
				for civ in CivilizationSystem.civilizations:
					if civ is Dictionary and int(((civ as Dictionary).get("player_relation",{}) as Dictionary).get("contact_level",0))>=(2 if template=="friend" else 1): named_civ=String(civ.id); break
			if named_civ!="":
				var civ_name:=_civ_name(named_civ)
				var years:=rng.randi_range(8,12)
				cand=_base(template,god,years)
				cand.subject=named_civ; cand.subject_name=civ_name.substr(0,60)
				if template=="fear":
					var dread:=DIVINE.civ_dread(named_civ)
					cand.target=clampf(dread+0.25,0.3,0.9); cand.baseline=dread
					cand.legacy="the Years %s Trembled" % _the(civ_name)
				else:
					var opinion:=float(_relation(named_civ).get("opinion",0.0))
					cand.target=minf(0.85,opinion+0.3); cand.baseline=opinion
					cand.legacy="the Bond with %s" % _the(civ_name)
			else:
				cand=_cand_unity(god,rng)
		"grow":
			cand=_cand_grow(god,rng)
			var re:=RegEx.new(); re.compile("\\b(\\d{2,6})\\b")
			var m:=re.search(words)
			if m!=null:
				var asked:=int(m.get_string(1))
				var pop:=GameState.population_total
				if asked>pop:
					var band:=growth_band(_day()/365.0)
					var years:=MIN_YEARS
					while years<MAX_YEARS and float(pop)*pow(1.0+float(band.high)/100.0,float(years))<float(asked): years+=1
					var ceiling:=floori(float(pop)*pow(1.0+float(band.max)/100.0,float(years)))
					cand.years=years; cand.target=mini(asked,ceiling)
					cand.phrase="see our hearths hold %s souls" % _count(int(cand.target))
		"settle": cand=_cand_settle(god,rng)
		"plenty": cand=_cand_plenty(god,rng)
		"learn": cand=_cand_learn(god,rng)
		"knowledge": cand=_cand_knowledge(god,rng)
		"reach": cand=_cand_reach(god,rng)
		"work": cand=_cand_work(god,rng)
		_: cand=_cand_unity(god,rng)
	# When the world offers no such target, the nearest measurable one.
	if cand.is_empty() and template=="learn": cand=_cand_knowledge(god,rng)
	if cand.is_empty() and template=="settle": cand=_cand_grow(god,rng)
	if cand.is_empty(): cand=_cand_unity(god,rng)
	# The god's own words become the aim's name.
	var spoken:=words.substr(0,90)
	cand.title=_cap(spoken.trim_suffix(".").trim_suffix("!")).substr(0,70)
	cand.phrase=(spoken.substr(0,1).to_lower()+spoken.substr(1)).trim_suffix(".").trim_suffix("!")
	cand.why="The god has spoken."
	cand.source="god"
	cand["spoken"]=spoken
	if not cand.has("legacy") or String(cand.legacy)=="": cand.legacy="the God's Word"
	return cand

# --------------------------------------------------------------------------
# Taking up, tracking, resolution
# --------------------------------------------------------------------------

static func adopt(cand:Dictionary,chosen_by:String,day:int)->Dictionary:
	var s:=state()
	var aim:=cand.duplicate(true)
	aim.erase("score")
	aim["id"]="aim_%d_%s" % [day,String(cand.cid)]
	aim["start_day"]=day
	aim["deadline"]=day+int(aim.years)*365
	aim["chosen_by"]=chosen_by
	aim["progress"]=0.0
	aim["milestones"]=[]
	aim["status"]="active"
	# Re-read the starting point today, so progress counts only what is new.
	match String(aim.template):
		"grow": aim.baseline=GameState.population_total
		"knowledge": aim.baseline=GameState.known_discoveries.size()
		"settle": aim.baseline=GameState.player_settlements.size()
		"learn": aim.baseline=known_in(String(aim.subject))
	s.active=aim
	(s.used as Dictionary)[String(aim.template)]=day
	(s.candidates as Dictionary).erase(String(cand.cid))
	PeopleDirection.record_cultural_action("aim:"+String(aim.template),String(aim.focus),2.0)
	PeopleDirection.inclination_review_day=-1
	if String(aim.template)=="learn" and String(aim.get("first",""))!="": DiscoverySystem.select_research_target(String(aim.first))
	var by:=""
	if chosen_by=="people": by="The god said nothing, so the people took it up themselves."
	elif String(aim.source)=="god": by="The god declared it."
	elif String(aim.source)=="people": by="The god chose what the people asked for."
	else: by="The god chose %s's proposal." % String(aim.by_given)
	var text:="%s %s They have %s." % [_cap(String(aim.phrase))+".",by,winters(int(aim.years))]
	Chronicle.record({"key":"aim:start:"+String(aim.id),"title":"An Aim for a Generation: %s" % String(aim.title),"text":text,
		"tier":"moment","kind":"milestone","domain":String(aim.domain),"art":{"domain":String(aim.domain)},"ledger":true})
	PeopleDirection._log(day,"Took up an aim: %s." % String(aim.title))
	_log("adopted",String(aim.title),{"template":String(aim.template),"by":chosen_by,"years":int(aim.years),"target":str(aim.get("target",""))})
	_note_clash(aim)
	return aim

static func measure(aim:Dictionary)->float:
	## Progress 0..1 from the real simulation.
	var template:=String(aim.get("template",""))
	var base:=float(aim.get("baseline",0.0)); var target:=float(aim.get("target",1.0))
	match template:
		"grow","knowledge","settle":
			var now:=float(GameState.population_total) if template=="grow" else (float(GameState.known_discoveries.size()) if template=="knowledge" else float(GameState.player_settlements.size()))
			if template=="knowledge": return clampf((now-base)/maxf(1.0,target),0.0,1.0)
			return clampf((now-base)/maxf(1.0,target-base),0.0,1.0)
		"plenty","work":
			return clampf(float(aim.get("acc",0.0))/maxf(1.0,target),0.0,1.0)
		"learn":
			return clampf(float(known_in(String(aim.subject))-int(base))/maxf(1.0,target),0.0,1.0)
		"reach":
			if String(aim.subject)!="":
				var rel:=_relation(String(aim.subject))
				if int(rel.get("contact_level",0))>=2: return 1.0
				return 0.5 if bool(rel.get("home_location_known",false)) else 0.0
			if bool(aim.get("reports",false)): return clampf((float(CivilizationSystem.scout_reports.size())-base)/maxf(1.0,target-base),0.0,1.0)
			var charted:=float(aim.get("charted_now",base))
			return clampf((charted-base)/maxf(0.000001,target-base),0.0,1.0)
		"fear":
			return clampf((DIVINE.civ_dread(String(aim.subject))-base)/maxf(0.01,target-base),0.0,1.0)
		"friend":
			return clampf((float(_relation(String(aim.subject)).get("opinion",base))-base)/maxf(0.01,target-base),0.0,1.0)
		"unity":
			return clampf((float(GameState.simulation_metrics.get("cohesion",base))-base)/maxf(0.01,target-base),0.0,1.0)
	return 0.0

static func value_words(aim:Dictionary)->String:
	## Progress in the people's words.
	var template:=String(aim.get("template",""))
	var p:=float(aim.get("progress",0.0))
	match template:
		"grow": return "%s souls of %s" % [_count(GameState.population_total),_count(int(aim.target))]
		"knowledge": return "%s new ways of %s" % [_count(maxi(0,GameState.known_discoveries.size()-int(aim.baseline))),_count(int(aim.target))]
		"learn": return "%s new ways of %s" % [_count(maxi(0,known_in(String(aim.subject))-int(aim.baseline))),_count(int(aim.target))]
		"settle": return "%s of %s hearths" % [_count(GameState.player_settlements.size()),_count(int(aim.target))]
		"plenty": return "%s of %s full" % [winters(int(floor(float(aim.get("acc",0.0))/365.0))),winters(int(aim.years))]
		"reach":
			if String(aim.get("subject",""))!="": return "their fires found; not yet sat at" if p>=0.5 else "their smoke seen, their fires not yet found"
	var words:=["barely begun","a quarter done","half done","most of the way","all but done"]
	return String(words[clampi(int(p*4.0),0,4)])

static func _track(day:int,span:int)->void:
	var s:=state()
	var aim:Dictionary=s.active
	match String(aim.template):
		"plenty":
			var metrics:Dictionary=GameState.simulation_metrics
			if float(metrics.get("food_days",0.0))>=float(aim.get("threshold",PLENTY_STORES)) and float(metrics.get("food_intake_ratio",1.0))>=0.98: aim.acc=float(aim.get("acc",0.0))+float(span)
		"work":
			var builders:=float(GameState.population_total)*float(GameState.population_allocation_percentages.get("Construction",8.0))/100.0
			aim.acc=float(aim.get("acc",0.0))+builders*float(aim.get("share",WORK_SHARE))*float(span)
		"reach":
			if String(aim.get("subject",""))=="" and not bool(aim.get("reports",false)) and day%10==0: aim["charted_now"]=float(CivilizationSystem.progression_reach_snapshot().get("charted",0.0))
	# A target people that is gone takes the aim with it, without blame.
	if String(aim.template) in ["fear","friend","reach"] and String(aim.get("subject",""))!="" and _civ(String(aim.subject)).is_empty():
		release("%s are gone" % _the(String(aim.subject_name)),false)
		return
	var p:=measure(aim)
	aim.progress=p
	var reached:Array=aim.milestones
	for mark in MILESTONES:
		if p*100.0>=float(mark) and not int(mark) in reached and p<1.0:
			reached.append(int(mark))
			var text:=_say(Lines.MILESTONE[mark],{"name":String(aim.title)},"mile:%s:%d" % [String(aim.id),int(mark)],Lines.MILESTONE[mark])
			Chronicle.record({"key":"aim:mile:%s:%d" % [String(aim.id),int(mark)],"title":"%s: %s" % [String(aim.title),{25:"A Quarter Done",50:"Halfway",75:"Nearly Done"}[mark]],
				"text":"%s (%s.)" % [text,value_words(aim)],"tier":"moment" if int(mark)==50 else "notice","kind":"milestone","domain":String(aim.domain),"ledger":false})
			_log("milestone",String(aim.title),{"mark":int(mark)})
			if int(mark)==50 and String(s.matter_id)=="" and not aim.has("course_filed"): file_halfway(day)
	if p>=1.0:
		fulfil(day)
		return
	if day>=int(aim.deadline):
		fail(day)
		return
	# Halfway through its winters and well behind: the keeper comes back to court.
	var elapsed:=float(day-int(aim.start_day))/maxf(1.0,float(int(aim.deadline)-int(aim.start_day)))
	if elapsed>=0.5 and not aim.has("course_filed") and p<elapsed-0.1 and String(s.matter_id)=="":
		file_course(day)

static func _bonds_all(deltas:Dictionary)->void:
	for person in _officials(): GovernmentPeopleSystem.adjust_person_bonds(int(person.person_id),deltas)

static func _close(aim:Dictionary,status:String,day:int)->void:
	var s:=state()
	aim.status=status
	aim["ended_day"]=day
	var record:={"id":String(aim.id),"template":String(aim.template),"title":String(aim.title),"status":status,"start_day":int(aim.start_day),"ended_day":day,
		"progress":float(aim.get("progress",0.0)),"by":String(aim.get("by_given","")),"source":String(aim.get("source","")),"chosen_by":String(aim.get("chosen_by",""))}
	var history:Array=s.history
	history.push_front(record)
	while history.size()>HISTORY_MAX: history.pop_back()
	s.active={}
	s.next_proposal_day=day+_rng("rest:%d" % day).randi_range(REST_MIN,REST_MAX)
	# A course matter left waiting is moot now.
	if String(s.matter_id)!="":
		for m in (Hall.state().matters as Array).duplicate():
			if m is Dictionary and String(m.get("id",""))==String(s.matter_id): (Hall.state().matters as Array).erase(m)
		s.matter_id=""

static func fulfil(day:int)->void:
	var s:=state()
	var aim:Dictionary=s.active
	if aim.is_empty(): return
	aim.progress=1.0
	var god_chose:=String(aim.get("chosen_by",""))=="god"
	var metrics:Dictionary=GameState.simulation_metrics
	metrics["legitimacy"]=clampf(float(metrics.get("legitimacy",0.5))+(0.04 if god_chose else 0.02),0.01,0.99)
	metrics["cohesion"]=clampf(float(metrics.get("cohesion",0.58))+0.02,0.01,0.99)
	_bonds_all({"love":0.06 if god_chose else 0.03,"trust":0.03,"hold_days":90})
	if int(aim.get("by_pid",0))>0:
		GovernmentPeopleSystem.record_person_memory(int(aim.by_pid),"The aim I proposed was done: %s." % String(aim.title),"aim",0.9,{"emotion":"pride"})
	var legacy:=String(aim.get("legacy","the Aim Fulfilled"))
	var years:=maxi(1,roundi(float(day-int(aim.start_day))/365.0))
	var text:=_say(Lines.FULFIL,{"name":String(aim.title),"legacy":legacy},"fulfil:%s" % String(aim.id),Lines.FULFIL)
	var entry:={"day":day,"name":legacy,"title":String(aim.title),"years":years,"by":String(aim.get("by_given","")),"source":String(aim.get("source","")),"template":String(aim.template),"text":text.substr(0,300)}
	var legacies:Array=s.legacies
	legacies.push_front(entry)
	while legacies.size()>LEGACIES_MAX: legacies.pop_back()
	s.stats.fulfilled=int(s.stats.fulfilled)+1
	Chronicle.record({"key":"aim:done:"+String(aim.id),"title":"Remembered: %s" % _cap(legacy),"text":"%s It took %s." % [text,winters(years)],
		"tier":"moment","priority":true,"kind":"milestone","domain":String(aim.domain),"art":{"domain":String(aim.domain)},"ledger":true})
	PeopleDirection._log(day,"Fulfilled an aim: %s. It is remembered as %s." % [String(aim.title),legacy])
	_log("fulfilled",String(aim.title),{"legacy":legacy,"years":years})
	if String(aim.template)=="work": Lives._mark_rite("stone",legacy,day,10,int(aim.get("by_pid",0)))
	_clash_on_fulfil(aim)
	_close(aim,"fulfilled",day)

static func fail(day:int)->void:
	var s:=state()
	var aim:Dictionary=s.active
	if aim.is_empty(): return
	var metrics:Dictionary=GameState.simulation_metrics
	metrics["cohesion"]=clampf(float(metrics.get("cohesion",0.58))-0.015,0.01,0.99)
	metrics["legitimacy"]=clampf(float(metrics.get("legitimacy",0.5))-0.01,0.01,0.99)
	_bonds_all({"love":-0.02,"fear":0.04,"hold_days":60})
	if int(aim.get("by_pid",0))>0:
		GovernmentPeopleSystem.record_person_memory(int(aim.by_pid),"The aim I proposed was not done in time: %s." % String(aim.title),"aim",0.8,{"emotion":"grief"})
	var text:=_say(Lines.FAIL,{"name":String(aim.title)},"fail:%s" % String(aim.id),Lines.FAIL)
	s.stats.failed=int(s.stats.failed)+1
	Chronicle.record({"key":"aim:fail:"+String(aim.id),"title":"An Aim Unmet: %s" % String(aim.title),"text":"%s (%s.)" % [text,value_words(aim)],
		"tier":"moment","priority":true,"kind":"court","domain":String(aim.domain),"ledger":true})
	PeopleDirection._log(day,"An aim was not met: %s." % String(aim.title))
	_log("failed",String(aim.title),{"progress":float(aim.get("progress",0.0))})
	_close(aim,"failed",day)

static func release(reason:String,grieve:bool=true)->void:
	## Letting an aim go: a smaller grief than failing it.
	var s:=state()
	var aim:Dictionary=s.active
	if aim.is_empty(): return
	var day:=_day()
	if grieve:
		_bonds_all({"love":-0.01,"fear":0.01})
		GameState.simulation_metrics["cohesion"]=clampf(float(GameState.simulation_metrics.get("cohesion",0.58))-0.005,0.01,0.99)
	var text:=_say(Lines.RELEASE,{"name":String(aim.title)},"release:%s" % String(aim.id),Lines.RELEASE)
	s.stats.released=int(s.stats.released)+1
	Chronicle.record({"key":"aim:release:"+String(aim.id),"title":"An Aim Set Down: %s" % String(aim.title),"text":"%s It was %s." % [text,reason],
		"tier":"notice","kind":"court","domain":String(aim.domain),"ledger":false})
	_log("released",String(aim.title),{"reason":reason})
	_close(aim,"released",day)

# --------------------------------------------------------------------------
# Rivals' aims
# --------------------------------------------------------------------------

const RIVAL_TEMPLATES:={
	"outnumber":{"title":"Outnumber the God's People","phrase":"grow until they outnumber us","clashes":["grow"]},
	"humble":{"title":"Make the God's People Yield","phrase":"make us yield to them, and pay for their peace","clashes":["fear","friend"]},
	"bond":{"title":"Bind the God's People to Them","phrase":"bind us to them in friendship","clashes":[]},
	"spread":{"title":"Spread Their Hunting Grounds","phrase":"spread their hunting grounds toward ours","clashes":["reach","settle"]},
}

static func _rival_template(civ:Dictionary)->String:
	var civ_id:=String(civ.get("id",""))
	var p:=PERSONALITY.foreign(int(GameState.world_seed),civ_id)
	var rel:Dictionary=civ.get("player_relation",{})
	var tension:=float(rel.get("border_tension",0.0))
	if float(p.assertiveness)>0.55 and tension>=0.3: return "humble"
	if float(p.empathy)>0.6 and float(rel.get("opinion",0.0))> -0.1: return "bond"
	if float(p.openness)>0.6: return "spread"
	return "outnumber"

static func _yields_to(civ_id:String,since:int)->int:
	var n:=0
	for entry in Hall.ledger():
		if String(entry.get("civ_id",""))==civ_id and int(entry.get("day",0))>=since and String(entry.get("option","")) in ["pay","grant","grant_half"]: n+=1
	return n

static func _rival_progress(r:Dictionary)->float:
	var civ:=_civ(String(r.civ_id))
	if civ.is_empty(): return 0.0
	var base:=float(r.get("baseline",0.0)); var target:=float(r.get("target",1.0))
	match String(r.template):
		"outnumber": return clampf((float(civ.get("population",0.0))-base)/maxf(1.0,target-base),0.0,1.0)
		"humble": return clampf(float(_yields_to(String(r.civ_id),int(r.start_day)))/maxf(1.0,target),0.0,1.0)
		"bond": return clampf((float(((civ.get("player_relation",{}) as Dictionary)).get("opinion",base))-base)/maxf(0.01,target-base),0.0,1.0)
		"spread": return clampf((float(civ.get("territory",0.0))-base)/maxf(0.0001,target-base),0.0,1.0)
	return 0.0

static func _new_rival_aim(civ:Dictionary,day:int)->Dictionary:
	var civ_id:=String(civ.id)
	var template:=_rival_template(civ)
	var rng:=_rng("rival:%s:%d" % [civ_id,day])
	var years:=rng.randi_range(8,14)
	var r:={"civ_id":civ_id,"civ_name":String(civ.get("name","")).substr(0,60),"template":template,"title":String((RIVAL_TEMPLATES[template] as Dictionary).title),"phrase":String((RIVAL_TEMPLATES[template] as Dictionary).phrase),
		"start_day":day,"deadline":day+years*365,"years":years,"status":"active","known":false,"progress":0.0}
	var rel:Dictionary=civ.get("player_relation",{})
	match template:
		"outnumber":
			var theirs:=float(civ.get("population",0.0))
			r.baseline=theirs; r.target=maxf(theirs*1.08,float(GameState.population_total)*1.05)
			if r.target<=theirs: r.target=theirs*1.08
		"humble": r.baseline=0.0; r.target=2.0
		"bond":
			var op:=float(rel.get("opinion",0.0)); r.baseline=op; r.target=minf(0.9,op+0.25)
		"spread":
			var t:=float(civ.get("territory",0.0)); r.baseline=t; r.target=t*1.15+0.001
	var leader:=ForeignDiplomacy.leader(civ_id)
	r["leader"]=String(leader.get("name","their chief")).substr(0,60)
	return r

static func _rivals(day:int)->void:
	var s:=state()
	var rivals:Dictionary=s.rivals
	for civ in CivilizationSystem.civilizations:
		if not civ is Dictionary: continue
		var civ_id:=String(civ.get("id",""))
		var level:=int(((civ as Dictionary).get("player_relation",{}) as Dictionary).get("contact_level",0))
		if level<2: continue
		var r:Dictionary=rivals.get(civ_id,{})
		if r.is_empty() or String(r.get("status",""))!="active":
			if not r.is_empty() and day<int(r.get("rest_until",0)): continue
			if rivals.size()>=RIVALS_MAX and not rivals.has(civ_id): continue
			r=_new_rival_aim(civ,day)
			rivals[civ_id]=r
			_log("rival_aim",String(r.title),{"civ":String(r.civ_name)})
		# Learned from their envoy: anyone who came to court since the vow.
		if not bool(r.get("known",false)):
			for entry in Hall.ledger():
				if String(entry.get("civ_id",""))==civ_id and int(entry.get("day",0))>=int(r.start_day):
					r.known=true
					var clash:=_clashes(r)
					Chronicle.record({"key":"aim:rival:known:%s:%d" % [civ_id,int(r.start_day)],"title":"What %s Has Sworn" % String(r.leader),
						"text":"Their messenger let it slip: %s of %s has sworn to %s.%s" % [String(r.leader),_the(String(r.civ_name)),String(r.phrase),(" It crosses our own aim: %s." % String((s.active as Dictionary).get("title",""))) if clash else ""],
						"tier":"notice","kind":"contact","domain":"culture","ledger":true})
					_log("rival_known",String(r.title),{"civ":String(r.civ_name),"clash":clash})
					break
		r.progress=_rival_progress(r)
		if float(r.progress)>=1.0: _rival_close(r,"fulfilled",day)
		elif day>=int(r.deadline): _rival_close(r,"failed",day)

static func _clashes(r:Dictionary)->bool:
	var aim:Dictionary=state().active
	if aim.is_empty(): return false
	var clash_with:Array=(RIVAL_TEMPLATES[String(r.template)] as Dictionary).clashes
	if not String(aim.template) in clash_with: return false
	if String(aim.template) in ["fear","friend"]: return String(aim.get("subject",""))==String(r.civ_id)
	return true

static func _note_clash(aim:Dictionary)->void:
	for civ_id in state().rivals:
		var r:Dictionary=state().rivals[civ_id]
		if String(r.get("status",""))=="active" and bool(r.get("known",false)) and _clashes(r):
			aim["clash"]=_cap(_the(String(r.civ_name)))
			_log("clash","%s against %s" % [String(aim.title),String(r.title)],{"civ":String(r.civ_name)})

static func _rival_close(r:Dictionary,status:String,day:int)->void:
	r.status=status
	r["ended_day"]=day
	r["rest_until"]=day+365
	var clash:=_clashes(r)
	if status=="fulfilled":
		match String(r.template):
			"humble":
				# They got what they wanted from us: they fear the god less.
				DIVINE.add_civ_dread(String(r.civ_id),-0.05)
			"outnumber":
				if clash: _bonds_all({"love":-0.01})
	if bool(r.get("known",false)):
		var text:=""
		if status=="fulfilled": text="%s of %s has done what they swore: %s.%s" % [String(r.leader),_the(String(r.civ_name)),String(r.phrase),(" It sets back our own aim.") if clash else ""]
		else: text="%s of %s swore to %s, and it came to nothing. Our people laugh about it at the fires." % [String(r.leader),_the(String(r.civ_name)),String(r.phrase)]
		Chronicle.record({"key":"aim:rival:%s:%s:%d" % [status,String(r.civ_id),int(r.start_day)],"title":("%s Have Their Way" if status=="fulfilled" else "The Boast of %s Came to Nothing") % _cap(_the(String(r.civ_name))),
			"text":text,"tier":"notice","kind":"contact","domain":"culture","ledger":true})
	_log("rival_"+status,String(r.title),{"civ":String(r.civ_name),"clash":clash})

static func _clash_on_fulfil(aim:Dictionary)->void:
	## Our success is their setback: a clashing rival vow fails.
	for civ_id in state().rivals:
		var r:Dictionary=state().rivals[civ_id]
		if String(r.get("status",""))!="active" or not _clashes(r): continue
		if String(r.template)=="humble" or (String(r.template)=="outnumber" and String(aim.template)=="grow" and GameState.population_total>float(_civ(String(civ_id)).get("population",0.0))):
			_rival_close(r,"failed",_day())

# --------------------------------------------------------------------------
# Read models for the board and the court
# --------------------------------------------------------------------------

static func board_model()->Dictionary:
	var s:=state()
	var aim:Dictionary=s.active
	var out:={"active":{},"waiting":"","rivals":[],"legacies":[],"history":[]}
	if not aim.is_empty():
		var left:=maxi(0,int(ceil((int(aim.deadline)-_day())/365.0)))
		var by:=""
		if String(aim.get("source",""))=="god": by="Declared by the god"
		elif String(aim.get("chosen_by",""))=="people": by="Taken up by the people"
		elif String(aim.get("source",""))=="people": by="Asked by the people"
		else: by="Proposed by %s" % String(aim.get("by_name",""))
		out.active={"title":String(aim.title),"phrase":String(aim.phrase),"progress":float(aim.get("progress",0.0)),"words":value_words(aim),"left":winters(left),"years_left":left,
			"by":by,"milestones":(aim.get("milestones",[]) as Array).duplicate(),"clash":String(aim.get("clash","")),"template":String(aim.template),"subject":String(aim.get("subject",""))}
	var matter:=pending_matter()
	if not matter.is_empty(): out.waiting=String((matter.get("holder",{}) as Dictionary).get("name",""))
	for civ_id in s.rivals:
		var r:Dictionary=s.rivals[civ_id]
		if not bool(r.get("known",false)) or String(r.get("status",""))!="active": continue
		(out.rivals as Array).append({"civ_id":String(civ_id),"civ_name":String(r.civ_name),"people":_the(String(r.civ_name)),"leader":String(r.leader),"title":String(r.title),"phrase":String(r.phrase),"progress":float(r.get("progress",0.0)),"clash":_clashes(r)})
	for entry in s.legacies:
		if (out.legacies as Array).size()>=4: break
		(out.legacies as Array).append((entry as Dictionary).duplicate())
	for entry in s.history:
		if (out.history as Array).size()>=4: break
		(out.history as Array).append((entry as Dictionary).duplicate())
	return out

static func rival_aim(civ_id:String)->Dictionary:
	var r:Dictionary=state().rivals.get(civ_id,{})
	if r.is_empty() or not bool(r.get("known",false)) or String(r.get("status",""))!="active": return {}
	return r.duplicate()

static func court_line()->String:
	## One line for the court's roll: what the people strive for now.
	var aim:Dictionary=state().active
	var matter:=pending_matter()
	if aim.is_empty():
		if not matter.is_empty(): return "The people want an aim. Summon %s to hear what they would strive for." % String((matter.get("holder",{}) as Dictionary).get("name",""))
		return ""
	var left:=maxi(0,int(ceil((int(aim.deadline)-_day())/365.0)))
	var text:="The people strive to %s: %s, %s left." % [String(aim.phrase),value_words(aim),winters(left)]
	if not matter.is_empty(): text+=" %s would speak of it." % String((matter.get("holder",{}) as Dictionary).get("name",""))
	return text

static func share_active()->float:
	var stats:Dictionary=state().stats
	return float(stats.active_days)/maxf(1.0,float(stats.tracked))
