extends RefCounted
## THE GOD'S WORD ON THE EYES AND THE WARY (eyes_corps.gd): "teach a few
## eyes", "train many watchers", "stop training spies", "keep the wary
## steady", "set gatekeepers against their watchers". The Pathfinder carries
## it; the answer states the course, its ration and what the wary cost in
## trust, with the engine's numbers.
##
## read()   the words -> {corps, policy} or {} (only with a training word or
##          a word for the wary, so "send spies to Ruvak" stays a covert act).
## carry()  sets the policy and answers.

const Corps:=preload("res://scripts/eyes_corps.gd")

const QUESTION:="(?i)^\\s*(how|what|why|who|when|where|which|do|does|did|is|are|can|could|would|should)\\b|\\?\\s*$"
const TRAIN:="(?i)\\b(train|training|teach|teaching|raise|raising|school|schooling)\\b"
const EYES:="(?i)\\b(eyes|eye|watchers|watcher|spies|spy|informers|informer|agents)\\b"
const WARY:="(?i)\\b(the wary|wary|gatekeepers|gatekeeper|counter[- ]?intelligence|counter[- ]?spies|catch (their|the) (eyes|spies|watchers)|watch for (their|the) (eyes|spies|watchers)|guard against (their|the) (eyes|spies|watchers))\\b"
const NONE:="(?i)\\b(stop|no more|none|cease|end|halt|disband)\\b"
const FEW:="(?i)\\b(a few|few|some|a little|small)\\b"
const MANY:="(?i)\\b(many|lots|a great many|all we can|as many as)\\b"

static func _has(text:String,pattern:String)->bool:
	var re:=RegEx.new(); re.compile(pattern)
	return re.search(text)!=null

static func read(text:String)->Dictionary:
	var lower:=text.strip_edges().to_lower().replace("’","'")
	if lower.is_empty() or _has(lower,QUESTION): return {}
	var corps:=""
	if _has(lower,WARY): corps="wary"
	elif _has(lower,TRAIN) and _has(lower,EYES): corps="eyes"
	if corps=="": return {}
	var policy:="steady"
	if _has(lower,NONE): policy="none"
	elif _has(lower,MANY): policy="many"
	elif _has(lower,FEW): policy="few"
	return {"corps":corps,"policy":policy}

static func perform(reading:Dictionary)->Dictionary:
	var corps:=String(reading.get("corps",""))
	var value:=String(reading.get("policy","steady"))
	var before:=Corps.policy(corps)
	if not Corps.set_policy(corps,value): return {"ok":false,"says":"I do not follow which you mean.","outcome":""}
	var sum:=Corps.summary()
	var name:=Corps.word("eyes") if corps=="eyes" else Corps.word("wary")
	var yearly:=float((Corps.POLICIES[value] as Array)[1])*maxf(1.0,float(GameState.population_exact))/1000.0
	var says:=""
	if value=="none":
		says="No more %s will be taught. Those we have keep serving until the years thin them." % name
	else:
		says="About %s a year will be taught as %s: a course of %d days at %s food a day each. They leave other work while they learn and while they serve." % [_count(yearly),name,int(sum.course_days),_n(float(sum.course_food))]
		if corps=="wary":
			says+=" Watching our own people breeds distrust: with enough of the wary to watch everyone, the people's trust in one another falls by up to %d in 100." % roundi(Corps.WATCH_DISTRUST*Corps.COHESION_COST*100.0)
		else:
			says+=" A taught %s blends in far better than a volunteer; still, moving in among a small people is the dangerous part." % Corps.word("eye")
	return {"ok":true,"changed":before!=value,"says":says,"outcome":"%s: %s." % [name.capitalize(),String((Corps.POLICIES[value] as Array)[0]).to_lower()]}

static func carry(r:Dictionary,reading:Dictionary)->Dictionary:
	var done:=perform(reading)
	r.verb="order"
	r["route"]="eyes"
	r["actor_says"]=String(done.get("says",""))
	r.outcome=String(done.get("outcome",""))
	r.executed=bool(done.get("ok",false)) and bool(done.get("changed",false))
	r.stage="order" if bool(r.executed) else "none"
	r.reaction="neutral"
	return r

static func _count(n:float)->String:
	if n<1.0: return "one every %d years" % maxi(2,roundi(1.0/maxf(0.01,n)))
	return str(roundi(n))

static func _n(v:float)->String:
	return ("%.2f" % v).trim_suffix("0").trim_suffix("0").trim_suffix(".")
