extends RefCounted
## THE YEAR'S TELLING — keeps the Chronicle from saying the same thing every
## year, and gives each year one entry worth reading.
##
## Three jobs, all driven by what the Chronicle is actually told:
##   shape()   Routine lines step back into the season tallies: a crisis's
##             "still has hold of the camp", a holder acting while the god is
##             silent, the season's learning, a watch that reports the same
##             thing again within REPEAT_QUIET_DAYS. What remains is retold
##             with real callbacks: the last fever of its kind, how many
##             troubles in a row the god has left to the court.
##   note()    Every told line (and the ones that stepped back) is counted in
##             the year's accumulator.
##   roll()    When a year ends, its facts become one entry: a name for the
##             year taken from its most memorable event, then only what
##             changed, crossed a record, or reversed a run. A quiet year gets
##             a short line, never a list of nothing.
##
## State (all optional keys of GameState.chronicle, so older saves load and
## simply begin their annals at the next year's end):
##   year_acc     the current year's facts
##   annals       one compact record per closed year (for records and streaks)
##   crisis_log   one line per finished crisis (for callbacks)
##   told_lines   normalised sentences already told by returning scouts
##   annal_year   the last 0-based year already closed

const REPEAT_QUIET_DAYS:=240
## The same words told again within this many days are kept as a tally line.
const REPEAT_TEXT_DAYS:=1095
const ANNALS_MAX:=600
const CRISIS_LOG_MAX:=200
const TOLD_LINES_MAX:=300
## Two sources telling the same finding (a scout return and an arc beat, a
## directive issued and implemented) within this many days are told once.
const SAME_FINDING_DAYS:=60
const SAID_MAX:=240
const SAID_TEXTS_MAX:=400
const NUMBER_WORDS:=["no","one","two","three","four","five","six","seven","eight","nine","ten","eleven","twelve"]
const ORDINALS:=["zeroth","first","second","third","fourth","fifth","sixth","seventh","eighth","ninth","tenth","eleventh","twelfth"]
## Crisis onset titles (crisis_system.gd) to the crisis type.
const CRISIS_TYPES:={"Sickness at the Fires":"sickness","The Strangers' Sickness":"stranger","The Rain Does Not Come":"drought","The Sun Is Dim":"cold","The River Comes In":"flood","Fire in the Camp":"fire","The Land Is Worn Out":"thinning"}
## [singular, plural] for callbacks.
const TYPE_WORDS:={"sickness":["sickness","sicknesses"],"stranger":["strangers' sickness","strangers' sicknesses"],"drought":["dry year","dry years"],"cold":["dim-sun year","dim-sun years"],
	"flood":["flood","floods"],"fire":["fire in the camp","fires in the camp"],"thinning":["wearing-out of the near ground","wearings-out of the near ground"],"hunger":["hunger","hungers"]}
## Scout lines that are ordinary road news: counted, not told as a card.
const ROUTINE_SCOUT:=["turned the party back","hurt on the road","who kept moving","found no wandering band","nomadic groups are scarce","band will not remain there"]
## The people's regard, told in the third person for the year's entry.
const REGARD_WORDS:={"worships":"speak of the god with love and fear together","reveres":"speak of the god with reverence","fearless_love":"speak of the god warmly and without fear",
	"terror":"lower their voices when they speak of the god","hates_dread":"fear the god, and some curse the god in whispers","resents":"grumble about the god when they think no one hears",
	"wary":"keep a careful distance from the god","cold":"speak of the god less and less","dutiful":"do what the god asks, without much feeling"}
const DIVINE_WORDS:={"terrify":"The god's fury fell on %s before the court.","penance":"%s was made to fast and keep vigil for the god.","cast_out":"%s was cast out at the god's word.",
	"strike_down":"%s was put to death at the god's word.","bless":"The god blessed %s before everyone.","boon":"The god gave %s a gift from the stores.","raise_up":"The god raised %s above the others.",
	"flight":"%s fled beyond the god's reach."}


# --- State ----------------------------------------------------------------------

static func _year_of(day:int)->int:
	return maxi(0,day)/365


static func acc(c:Dictionary,day:int=-1)->Dictionary:
	if day<0:day=int(GameState.elapsed_days)
	var a:Variant=c.get("year_acc")
	if not a is Dictionary or (a as Dictionary).is_empty():
		a=_new_acc(_year_of(day))
		c["year_acc"]=a
	return a


static func _new_acc(year:int)->Dictionary:
	return {"year":year,"pop0":_people(),"crises":[],"deaths":[],"learned":[],"firsts":[],"scouts":{"n":0,"km":0,"days":0,"hurt":0,"back":0,"news":0},
		"contacts":[],"aims":[],"works":[],"wars":[],"heads":[],"milestones":[],"born":0,"buried":0,"folded":0,"regard":""}


static func _list_of(c:Dictionary,key:String)->Array:
	if not c.get(key) is Array:c[key]=[]
	return c[key]


static func _people()->int:
	return int(GameState.population_total) if Engine.get_main_loop()!=null else 0


# --- Shaping what is told -------------------------------------------------------

## Returns {"tier","title","text","family","folded"} for a record request.
static func shape(c:Dictionary,moment:Dictionary,tier:String)->Dictionary:
	var key:=String(moment.get("key",""))
	var title:=String(moment.get("title",""))
	var text:=String(moment.get("text",""))
	var out:={"tier":tier,"title":title,"text":text,"family":String(moment.get("family",_family(title))),"folded":false}
	if key.begins_with("crisis:"):
		var parts:=key.split(":")
		var id:=parts[1] if parts.size()>1 else ""
		var phase:=parts[2] if parts.size()>2 else ""
		if phase=="silent":
			# Folded into the end of the crisis and the year's telling.
			out.tier="whisper";out.folded=true
		elif phase=="mid" and tier=="notice":
			out.tier="whisper";out.folded=true
		elif phase=="onset":
			var told:=_onset(c,id,title,text)
			out.title=told[0];out.text=told[1]
		elif phase=="end":
			out.text=_ending(c,id,title,text)
		return out
	if key.begins_with("learned:"):
		# The season's learning is told in the year's entry.
		out.tier="whisper";out.folded=true
		return out
	var day:=int(moment.get("day",int(GameState.elapsed_days)))
	if tier!="whisper" and not key.begins_with("annal:"):
		_same_finding(c,moment,key,out,day)
		if bool(out.folded):return out
	if tier=="notice" and _dampable(moment,key) and (_told_recently(c,String(out.family),day,String(out.text)) or _said_before(c,String(out.text))):
		out.tier="whisper";out.folded=true
	return out


## One finding told by two sources is told once. A beat or a first (the
## story's own telling) takes the place of the plainer report told a few days
## before; anything else drops the sentences already told, and steps back
## into the tallies when nothing new is left.
static func _same_finding(c:Dictionary,moment:Dictionary,key:String,out:Dictionary,day:int)->void:
	var said:Array=c.get("said",[]) if c.get("said") is Array else []
	if said.is_empty():return
	var recent:={}
	for item in said:
		if item is Dictionary and day-int(item.get("day",-99999))<=SAME_FINDING_DAYS:recent[String(item.s)]=String(item.get("key",""))
	if recent.is_empty():return
	var kept:PackedStringArray=[]
	var older:={}
	var sentences:=_sentences(String(out.text))
	for sentence in sentences:
		var norm:=_said_norm(sentence)
		if norm.length()>=24 and recent.has(norm):older[recent[norm]]=true
		else:kept.append(sentence)
	if older.is_empty():return
	var story:=bool(moment.get("priority",false)) or bool(moment.get("first",false))
	for prefix in ["beat:","first:","turning:"]:
		if key.begins_with(prefix):story=true
	if story:
		out["demote"]=older.keys()
		return
	if key.begins_with("crisis:"):return
	var substance:=0
	for sentence in kept:substance+=sentence.length()
	if substance<24:
		out.tier="whisper";out.folded=true;out["same_as"]=String(older.keys()[0])
		return
	out.text=" ".join(kept)


static func _sentences(text:String)->PackedStringArray:
	var out:PackedStringArray=[]
	var re:=RegEx.create_from_string("[^.!?]+[.!?]+['\")]*")
	for m in re.search_all(text):
		var t:=m.get_string().strip_edges()
		if t!="":out.append(t)
	if out.is_empty() and text.strip_edges()!="":out.append(text.strip_edges())
	return out


static func _said_norm(sentence:String)->String:
	return sentence.to_lower().strip_edges().trim_suffix(".").strip_edges()


## The very same words, told at any time before, by a plain report.
static func _said_before(c:Dictionary,text:String)->bool:
	var said:=_family(text)
	if said.length()<=24:return false
	return (c.get("said_texts",{}) as Dictionary).has(said) if c.get("said_texts") is Dictionary else false


static func _remember_said(c:Dictionary,entry:Dictionary)->void:
	var key:=String(entry.get("key",""))
	if String(entry.get("tier",""))=="whisper" or key.begins_with("annal:"):return
	if not c.get("said") is Array:c["said"]=[]
	var said:Array=c.said
	var day:=int(entry.get("day",0))
	for sentence in _sentences(String(entry.get("text",""))):
		var norm:=_said_norm(sentence)
		if norm.length()>=24:said.append({"s":norm,"day":day,"key":key})
	while said.size()>SAID_MAX:said.pop_front()
	if key.begins_with("crisis:"):return
	if not c.get("said_texts") is Dictionary:c["said_texts"]={}
	var texts:Dictionary=c.said_texts
	texts[_family(String(entry.get("text","")))]=day
	while texts.size()>SAID_TEXTS_MAX:texts.erase(texts.keys()[0])


static func _dampable(moment:Dictionary,key:String)->bool:
	if bool(moment.get("priority",false)) or bool(moment.get("first",false)):return false
	if String(moment.get("kind","")) in ["death","annal","birth","founding","ceremony"]:return false
	for prefix in ["aim:","court:death","discovery:","first:","annal:","ceremony:","turning:","war:","beat:","milestone:"]:
		if key.begins_with(prefix):return false
	return true


static func _family(title:String)->String:
	var out:=""
	for ch in title.to_lower():
		out+="#" if ch>="0" and ch<="9" else ch
	return out.strip_edges()


static func _told_recently(c:Dictionary,family:String,day:int,text:String="")->bool:
	if family.is_empty():return false
	var said:=_family(text)
	for e in c.get("entries",[]):
		var entry:Dictionary=e
		var age:=day-int(entry.get("day",day))
		if age>REPEAT_TEXT_DAYS:break
		if String(entry.get("tier",""))=="whisper":continue
		if age<=REPEAT_QUIET_DAYS and String(entry.get("family",_family(String(entry.get("title","")))))==family:return true
		# The very same words, told again within a few years, are no news.
		if said.length()>12 and _family(String(entry.get("text","")))==said:return true
	return false


# --- Crises ---------------------------------------------------------------------

static func crisis_type(title:String,id:String="")->String:
	var live:=_live_crisis(id)
	if not live.is_empty():return String(live.get("type","hunger"))
	for t in CRISIS_TYPES:
		if title.begins_with(String(t)):return String(CRISIS_TYPES[t])
	return "hunger"


static func _live_crisis(id:String)->Dictionary:
	if id.is_empty() or Engine.get_main_loop()==null:return {}
	var system:Script=load("res://scripts/crisis_system.gd")
	if system==null:return {}
	var s:Variant=system.call("state")
	if not s is Dictionary:return {}
	var active:Variant=(s as Dictionary).get("active",{})
	if active is Dictionary and (active as Dictionary).get(id) is Dictionary:return active[id]
	return {}


## "The Coughing Winter of year 46" -> "the Coughing Winter".
static func short_name(name:String)->String:
	var n:=name.strip_edges()
	if n.begins_with("After "):n=n.substr(6)
	var re:=RegEx.create_from_string(" of (year \\d+|the [a-z\\-]+ year)$")
	n=re.sub(n,"")
	if n.begins_with("The "):n="the "+n.substr(4)
	return n


static func crisis_log(c:Dictionary)->Array:
	var log:Array=_list_of(c,"crisis_log")
	if log.is_empty() and not bool(c.get("crisis_seeded",false)):
		c["crisis_seeded"]=true
		# An older save: remember the crises the court already recorded.
		if Engine.get_main_loop()!=null:
			var system:Script=load("res://scripts/crisis_system.gd")
			var s:Variant=system.call("state") if system!=null else null
			if s is Dictionary:
				var history:Array=(s as Dictionary).get("history",[])
				for i in range(history.size()-1,-1,-1):
					var h:Variant=history[i]
					if not h is Dictionary:continue
					log.append({"id":String(h.get("id","")),"type":String(h.get("type","")),"short":short_name(String(h.get("name",""))),"y":_year_of(int(h.get("start",0))),"deaths":int(h.get("deaths",0)),"silent":false})
	return log


static func _prior(c:Dictionary,type:String)->Array:
	var out:Array=[]
	for h in crisis_log(c):
		if String((h as Dictionary).get("type",""))==type:out.append(h)
	return out


static func _onset(c:Dictionary,id:String,title:String,text:String)->Array:
	var type:=crisis_type(title,id)
	var a:=acc(c)
	var found:=false
	for cr in a.crises:
		if String(cr.id)==id:found=true
	if not found:(a.crises as Array).append({"id":id,"type":type,"title":title,"short":"","deaths":0,"silent":false,"holder":"","ended":false})
	# A crisis may end in a later year than it began: remember it until then.
	var open:=_open(c)
	open[id]={"type":type,"title":title,"silent":false,"holder":""}
	while open.size()>24:open.erase(open.keys()[0])
	var prior:=_prior(c,type)
	if prior.is_empty():
		if crisis_log(c).size()>=2:return [title,_before_summons(text,"The people have not faced %s here before." % _a(_word(type,false)))]
		return [title,text]
	var last:Dictionary=prior.back()
	var year:=_year_of(int(GameState.elapsed_days))
	var gap:=year-int(last.y)
	var seed:=hash(id)
	var recent:=0
	for p in prior:
		if int(p.y)>=year-9:recent+=1
	var line:=""
	if recent>=3 and recent+1<ORDINALS.size():
		line="It is the %s %s in ten years." % [ORDINALS[recent+1],_word(type,false)]
		title="%s, the %s Time in Ten Years" % [title,ORDINALS[recent+1].capitalize()]
	elif gap<=2:
		var ago:="a year" if gap<=1 else "two years"
		line=["It is barely %s since %s." % [ago,String(last.short)],"Only %s ago it was %s." % [ago,String(last.short)],"%s was only %s ago." % [_cap(String(last.short)),ago]][posmod(seed,3)]
		title+=String([" Again"," Once More"][posmod(seed>>3,2)])
	else:
		var took:=", and it killed no one" if int(last.deaths)==0 else ", which took %s" % _number(int(last.deaths))
		if type in ["thinning","cold"] or int(last.deaths)==0:
			# Nothing to count but the years between.
			line=["The last %s here was %s, in year %d." % [_word(type,false),String(last.short),int(last.y)+1],
				"It is %s years since %s." % [_number(gap),String(last.short)],
				("It is the %s %s since the founding; the last was in year %d." % [ORDINALS[prior.size()+1],_word(type,false),int(last.y)+1]) if prior.size()+1<ORDINALS.size() else ("There have been %d before it; the last was in year %d." % [prior.size(),int(last.y)+1])][posmod(seed>>7,3)]
		else:line="The last %s here was %s, in year %d%s." % [_word(type,false),String(last.short),int(last.y)+1,took]
		if gap<=4:title+=" Again"
	return [title,_before_summons(_summons(text,seed),line)]


## Varies the closing call to court without changing what it asks.
static func _summons(text:String,seed:int)->String:
	var m:=RegEx.create_from_string("(\\S+) waits to be summoned\\.$").search(text)
	if m==null:return text
	var who:=m.get_string(1)
	var said:String=["%s waits to be summoned.","%s asks to come before the god about it.","%s will bring it to the god when summoned."][posmod(seed>>5,3)] % who
	return text.substr(0,m.get_start())+said


## Puts a callback before the closing "X waits to be summoned." line.
static func _before_summons(text:String,line:String)->String:
	var at:=text.rfind(". ")
	if at>=0 and (text.ends_with("waits to be summoned.") or text.ends_with("before the god about it.") or text.ends_with("to the god when summoned.")):
		return "%s. %s %s" % [text.substr(0,at),line,text.substr(at+2)]
	return (text+" "+line).strip_edges()


static func _open(c:Dictionary)->Dictionary:
	if not c.get("crisis_open") is Dictionary:c["crisis_open"]={}
	return c.crisis_open


static func _ending(c:Dictionary,id:String,title:String,text:String)->String:
	var a:=acc(c)
	var cr:Dictionary={}
	for x in a.crises:
		if String(x.id)==id:cr=x
	var begun:Dictionary=_open(c).get(id,{})
	_open(c).erase(id)
	if cr.is_empty() and not begun.is_empty():
		# Begun last year: it ends in this year's telling.
		cr={"id":id,"type":String(begun.type),"title":String(begun.title),"short":"","deaths":0,"silent":bool(begun.silent),"holder":String(begun.holder),"ended":false}
		(a.crises as Array).append(cr)
	var re:=RegEx.create_from_string("The god was silent\\. (.+?) acted alone\\.\\s*")
	var m:=re.search(text)
	var silent:=m!=null or bool(cr.get("silent",false))
	var holder:=String(cr.get("holder","")) if String(cr.get("holder",""))!="" else (m.get_string(1) if m!=null else "")
	var body:=re.sub(text,"",true).strip_edges() if m!=null else text.strip_edges()
	var live:=_live_crisis(id)
	var type:=String(live.get("type",cr.get("type",crisis_type(title))))
	var deaths:=int(live.get("deaths",_deaths_in(body))) if not live.is_empty() else _deaths_in(body)
	var short:=short_name(String(live.get("name",title)))
	if cr.is_empty():
		cr={"id":id,"type":type,"title":title,"short":short,"deaths":deaths,"silent":silent,"holder":holder,"ended":true}
		(a.crises as Array).append(cr)
	cr.short=short;cr.deaths=deaths;cr.silent=silent;cr.ended=true;cr.type=type
	if holder!="":cr.holder=holder
	var lines:PackedStringArray=[]
	var prior:=_prior(c,type)
	var seed:=hash(id)
	var passed:=RegEx.create_from_string("^(.+?) has passed\\. ").search(body)
	if passed!=null:body=(["%s has passed. ","%s is over. ","%s has left the camp. "][posmod(seed>>2,3)] % passed.get_string(1))+body.substr(passed.get_end())
	if prior.is_empty():
		if crisis_log(c).size()>=2:lines.append("It was the first %s the people have come through here." % _word(type,false))
	else:
		var worst:=0
		for p in prior:worst=maxi(worst,int(p.deaths))
		var last:Dictionary=prior.back()
		if deaths>0 and deaths>worst:lines.append("No %s before it had killed so many." % _word(type,false))
		elif bool(live.get("compared",false)) or ("year %d" % (int(last.y)+1)) in body:pass # the ending already set it against the last one
		elif deaths==0 and int(last.deaths)>0:lines.append("%s took %s; this one took no one." % [_cap(String(last.short)),_number(int(last.deaths))])
		elif prior.size()+1<ORDINALS.size():lines.append("It was the %s %s since the founding." % [ORDINALS[prior.size()+1],_word(type,false)])
	# The god's part, with the run of silences it continues or breaks.
	var run:=0
	var log:=crisis_log(c)
	for i in range(log.size()-1,-1,-1):
		if bool((log[i] as Dictionary).get("silent",false)):run+=1
		else:break
	var who:=holder if holder!="" else "the court"
	if silent:
		run+=1
		if run==1:lines.append("The god said nothing, and %s decided." % who)
		elif run<=3:lines.append(["Again the god said nothing; %s decided alone." % who,"Once more the god kept silent, and %s chose the course." % who][posmod(seed,2)])
		else:
			# A long silence is counted at its milestones, or when someone new
			# is left to decide; in between the year's entry carries it.
			var last_who:=String(c.get("silence_who",""))
			if run%5==0 or (last_who!="" and last_who!=who):
				lines.append(["That makes %s troubles in a row the god has left to the court; this one fell to %s." % [_number(run),who],"The god has now been silent through %s troubles in a row; %s decided this one." % [_number(run),who]][posmod(seed,2)])
		c["silence_who"]=who
		if run==6:lines.append("At the fires, people have stopped waiting for the god's word when trouble comes.")
	elif run>=2:
		lines.append("This time the god answered, after %s troubles met in silence." % _number(run))
	log.append({"id":id,"type":type,"short":short,"y":_year_of(int(GameState.elapsed_days)),"deaths":deaths,"silent":silent})
	while log.size()>CRISIS_LOG_MAX:log.pop_front()
	return (body+" "+" ".join(lines)).strip_edges()


static func _deaths_in(text:String)->int:
	var lower:=text.to_lower()
	for none in ["no one died","no one starved","killed no one","no one drowned","everyone lived"]:
		if none in lower:return 0
	var re:=RegEx.create_from_string("(?:took|killed|drowned) (\\w+)")
	var m:=re.search(lower)
	if m==null:return 0
	var word:=m.get_string(1)
	if word.is_valid_int():return int(word)
	var at:=NUMBER_WORDS.find(word)
	return maxi(0,at)


# --- Scouts ---------------------------------------------------------------------

## Retells a returning party from the sentences the Chronicle kept. Returns
## [title, text, routine]. Routine road news is counted for the year's entry.
static func scout_story(c:Dictionary,ledger_title:String,kept:PackedStringArray)->Array:
	var seekers:=ledger_title!="SCOUTS RETURN"
	var a:=acc(c)
	var scouts:Dictionary=a.scouts
	var told:Array=_list_of(c,"told_lines")
	var days:=0;var km:=0
	var news:PackedStringArray=[]
	var routine_lines:PackedStringArray=[]
	var re:=RegEx.create_from_string("returns after (\\d+) days and charts roughly (\\d+) km")
	for sentence in kept:
		var m:=re.search(sentence)
		if m!=null:
			days=int(m.get_string(1));km=int(m.get_string(2));continue
		var lower:=sentence.to_lower()
		var routine:=false
		for phrase in ROUTINE_SCOUT:
			if phrase in lower:routine=true
		if routine:
			routine_lines.append(sentence)
			if "hurt on the road" in lower:scouts.hurt=int(scouts.hurt)+maxi(1,NUMBER_WORDS.find(lower.get_slice(" ",0)))
			if "turned the party back" in lower:scouts.back=int(scouts.back)+1
			continue
		var norm:=_family(sentence)
		if told.has(norm):continue
		told.append(norm)
		news.append(sentence)
	while told.size()>TOLD_LINES_MAX:told.pop_front()
	scouts.n=int(scouts.n)+1;scouts.km=int(scouts.km)+km;scouts.days=int(scouts.days)+days
	var party:="The seekers" if seekers else "The scouts"
	var tail:=" They were gone %d days and walked some %s km." % [days,_grouped(km)] if days>0 else ""
	if news.is_empty():
		return [party+" come home",(" ".join(routine_lines)+tail).strip_edges(),true]
	scouts.news=int(scouts.news)+1
	return [_scout_title(party,news[0]),(" ".join(news.slice(0,3))+tail).strip_edges(),false]


static func _scout_title(party:String,sentence:String)->String:
	var lower:=sentence.to_lower()
	if "chose to settle" in lower or "join" in lower and "us" in lower:return "Newcomers walk home with %s" % party.to_lower()
	if "chased" in lower or "armed" in lower:return "Armed strangers drive off %s" % party.to_lower()
	if "died" in lower or "killed" in lower or "did not come back" in lower or "never came back" in lower:return "Not all of %s come home" % party.to_lower()
	if "smoke" in lower or "fires" in lower:return "%s saw smoke far off" % party
	if "contact" in lower or "strangers" in lower or "people" in lower:return "%s met strangers" % party
	var dash:=sentence.find(" — ")
	if dash>3 and dash<60:return "%s found %s" % [party,_lower_first(sentence.substr(0,dash))]
	return "%s bring word" % party


# --- Counting the year ----------------------------------------------------------

## Counts a told entry (after shaping) in the year's facts.
static func note(c:Dictionary,entry:Dictionary)->void:
	var kind:=String(entry.get("kind",""))
	if kind=="annal":return
	_remember_said(c,entry)
	var a:=acc(c,int(entry.get("day",-1)))
	var key:=String(entry.get("key",""))
	var title:=String(entry.get("title",""))
	var tier:=String(entry.get("tier",""))
	if bool(entry.get("folded",false)):a.folded=int(a.folded)+1
	if key.begins_with("crisis:"):
		var parts:=key.split(":")
		if parts.size()>2 and parts[2]=="silent":
			var targets:Array=[]
			for cr in a.crises:
				if String(cr.id)==parts[1]:targets.append(cr)
			if _open(c).get(parts[1]) is Dictionary:targets.append(_open(c)[parts[1]])
			for cr in targets:
				cr.silent=true
				if title.ends_with(" Acts Alone"):cr.holder=title.trim_suffix(" Acts Alone")
		return
	if key.begins_with("learned:"):return
	if key.begins_with("discovery:") and tier!="whisper":
		_add_unique(a.learned,title)
		if bool(entry.get("first",false)):_add_unique(a.firsts,title)
		return
	if title.ends_with(" Is Dead") and kind=="death":
		var age:=RegEx.create_from_string("(?:aged|at) (\\d+)").search(String(entry.get("text","")))
		(a.deaths as Array).append({"name":title.trim_suffix(" Is Dead"),"age":int(age.get_string(1)) if age!=null else 0,"great":tier=="moment"})
		return
	if title.ends_with(" Keeps the Fire") or key.begins_with("court:succession:kept:"):
		var m:=RegEx.create_from_string("^(.+?) (?:Keeps the Fire|Follows |in .+'s Place)").search(title)
		_add_unique(a.heads,m.get_string(1) if m!=null else title.trim_suffix(" Keeps the Fire"))
		return
	if key.begins_with("aim:done:"):(a.aims as Array).append({"kind":"done","name":title.trim_prefix("Remembered: ")});return
	if key.begins_with("aim:fail:"):(a.aims as Array).append({"kind":"fail","name":title.trim_prefix("An Aim Unmet: ")});return
	if key.begins_with("aim:start:"):(a.aims as Array).append({"kind":"start","name":title.trim_prefix("An Aim for a Generation: ")});return
	if key.begins_with("ceremony:") or title.ends_with(" stands finished"):_add_unique(a.works,title.trim_suffix(" stands finished"));return
	if key.begins_with("first:people:"):_add_unique(a.milestones,title);return
	if kind=="contact" and tier=="moment":_add_unique(a.contacts,title);return
	if kind=="war" and tier!="whisper":_add_unique(a.wars,title)


static func note_learned(c:Dictionary,name:String,day:int)->void:
	_add_unique(acc(c,day).learned,name)


static func note_tally(c:Dictionary,ev:Dictionary)->void:
	var a:=acc(c,int(ev.get("day",-1)))
	a.born=int(a.born)+int(ev.get("born",0))
	a.buried=int(a.buried)+int(ev.get("buried",0))


static func _add_unique(list:Array,value:String)->void:
	if value!="" and not list.has(value):list.append(value)


# --- The year's entry -----------------------------------------------------------

## Closes every year that has ended by `today`. Returns the entries told.
static func roll(c:Dictionary,today:int)->Array:
	var now:=_year_of(today)
	var told:Array=[]
	if not c.has("annal_year"):
		# A new world, or an older save: begin with the year in progress.
		c["annal_year"]=now-1
		var fresh:=acc(c,today)
		if int(fresh.year)!=now:c["year_acc"]=_new_acc(now)
		return told
	var a:=acc(c,today)
	while int(c.annal_year)<now-1:
		var closing:=int(c.annal_year)+1
		if int(a.year)==closing:
			var told_year:=compose(c,a)
			if not told_year.is_empty():told.append(told_year)
			a=_new_acc(closing+1)
			c["year_acc"]=a
		c["annal_year"]=closing
	if int(a.year)<now:c["year_acc"]=_new_acc(now)
	return told


## Writes the entry for the year held in `a` and remembers it. Returns the
## record request (Chronicle.record is called by the caller) with "memory".
static func compose(c:Dictionary,a:Dictionary)->Dictionary:
	var y:=int(a.year)
	var annals:Array=_list_of(c,"annals")
	var chronicle:Script=load("res://scripts/chronicle.gd")
	var tally:=String((chronicle.call("voice") as Dictionary).get("era",""))!="annals" if Engine.get_main_loop()!=null else true
	var seed:=y*7919+int(GameState.world_seed) if Engine.get_main_loop()!=null else y*7919
	var crises:Array=a.crises
	var memory:={"y":y,"crises":crises.size(),"deaths":0,"learned":(a.learned as Array).size(),"pop":_people(),"km":int(a.scouts.km),"silent":0,"answered":0,"regard":"","name":""}
	var lines:PackedStringArray=[]
	# 1. Troubles, with the run of quiet years they end or extend.
	var crisis_deaths:=0
	for cr in crises:crisis_deaths+=int(cr.deaths)
	memory.deaths=crisis_deaths
	if crises.is_empty():
		var quiet:=1
		for i in range(annals.size()-1,-1,-1):
			if int((annals[i] as Dictionary).get("crises",1))==0:quiet+=1
			else:break
		var log:=crisis_log(c)
		if annals.size()>=1 and quiet==1:
			if not log.is_empty() and posmod(seed,3)==2:
				var last:Dictionary=log.back()
				lines.append("No trouble came this year; the last was %s, in year %d." % [String(last.short),int(last.y)+1])
			else:lines.append(["No sickness, hunger, fire or flood came this year.","It was a year without sickness, hunger or fire.","No sickness, hunger, fire or flood came this year."][posmod(seed,3)])
		elif quiet>=2 and quiet<ORDINALS.size():lines.append("It was the %s year in a row without sickness, hunger or fire." % ORDINALS[quiet])
		elif quiet>=ORDINALS.size():lines.append("%d years now without sickness, hunger or fire." % quiet)
	else:
		var shorts:PackedStringArray=[]
		var seen_short:={}
		for cr in crises:
			var sn:=_crisis_short(cr)
			seen_short[sn]=int(seen_short.get(sn,0))+1
			if int(seen_short[sn])==1 and shorts.size()<3:shorts.append(sn)
		for i in shorts.size():
			if int(seen_short[shorts[i]])>1:shorts[i]="%s %s" % [shorts[i],_times(int(seen_short[shorts[i]]))]
		if crises.size()==1:
			var cr:Dictionary=crises[0]
			if not bool(cr.ended):lines.append("%s was still on the camp at the year's end." % _cap(shorts[0]))
			elif int(cr.deaths)>0:lines.append("%s took %s." % [_cap(shorts[0]),_number(int(cr.deaths))])
			else:lines.append(["%s came and went without a death." % _cap(shorts[0]),"No one died of %s." % shorts[0]][posmod(seed,2)])
		else:
			var head:="%s troubles came: %s." % [_cap(_number(crises.size())),_list(Array(shorts))]
			if crisis_deaths>0:head+=" Together they took %s." % _number(crisis_deaths)
			else:head+=" "+["None of them killed anyone.","No one died of any of them.","All of them passed without a death."][posmod(seed,3)]
			lines.append(head)
		var worst_year:=0
		for m in annals:worst_year=maxi(worst_year,int((m as Dictionary).get("deaths",0)))
		if crisis_deaths>0 and crisis_deaths>worst_year and annals.size()>=3:lines.append("No year since the founding has lost so many to its troubles.")
	# 2. The god: silence or word in the troubles, acts of wrath and favour,
	# and how the people's talk of the god has turned.
	var holders:PackedStringArray=[]
	var silent:=0;var answered:=0
	for cr in crises:
		if not bool(cr.ended):continue
		if bool(cr.silent):
			silent+=1
			if String(cr.holder)!="" and not holders.has(String(cr.holder)):holders.append(String(cr.holder))
		else:answered+=1
	memory.silent=silent;memory.answered=answered
	if silent>0 and answered==0:
		var who:=_list(Array(holders)) if not holders.is_empty() else "the court"
		var years:=1
		for i in range(annals.size()-1,-1,-1):
			var m:Dictionary=annals[i]
			if int(m.get("crises",0))==0:continue
			if int(m.get("silent",0))>0 and int(m.get("answered",0))==0:years+=1
			else:break
		if years>=3 and years<ORDINALS.size():lines.append(["For the %s year the god kept silent through every trouble, and %s decided." % [ORDINALS[years],who],"%s decided again; in %s years of troubles the god has not answered once." % [_cap(who),_number(years)]][posmod(seed>>2,2)])
		elif silent==1:lines.append(_cap(String(["The god kept silent, and %s decided.","%s decided; the god said nothing.","The god gave no word, and %s chose the course."][posmod(seed>>1,3)]) % who))
		else:lines.append(["Each time the god kept silent, and %s decided.","The god was silent through all of them; %s decided each time."][posmod(seed>>1,2)] % who)
	elif answered>0 and silent>0:
		lines.append("The god answered %s and left %s to the court." % [_times(answered),_times(silent)])
	elif answered>0:
		lines.append("When trouble came to the court, the god answered.")
	for line in _divine_lines(y):lines.append(line)
	var regard:=_regard()
	memory.regard=regard
	if regard!="" and not annals.is_empty():
		var before:=String((annals.back() as Dictionary).get("regard",""))
		if before!="" and before!=regard:
			lines.append("By the year's end people %s; a year before they would %s." % [String(REGARD_WORDS.get(regard,"")),String(REGARD_WORDS.get(before,""))])
	# 3. The dead and the living who took their place.
	var deaths:Array=a.deaths
	if not deaths.is_empty():
		var named:PackedStringArray=[]
		for d in deaths.slice(0,3):
			named.append(("%s, at %d" % [String(d.name),int(d.age)]) if int(d.age)>0 else String(d.name))
		var more:=" and %s others the people knew" % _number(deaths.size()-3) if deaths.size()>3 else ""
		lines.append("Died this year: %s%s." % ["; ".join(named),more])
	if not (a.heads as Array).is_empty():
		lines.append("%s now %s the fire." % [_list(a.heads),"keeps" if (a.heads as Array).size()==1 else "keep"])
	# 4. What was learned, measured against earlier years.
	var learned:Array=a.learned
	var most:=0
	for m in annals:most=maxi(most,int((m as Dictionary).get("learned",0)))
	if learned.size()>0:
		var names:Array=[]
		for n in learned:names.append(String(n).to_lower())
		var who_learned:="the keepers recorded" if not tally else "the people learned"
		if names.size()<=3:lines.append("%s %s." % [_cap(who_learned),_list(names)])
		else:lines.append("%s %s new ways, among them %s." % [_cap(who_learned),_number(names.size()),_list(names.slice(0,3))])
		if names.size()>most and annals.size()>=3 and names.size()>=3:lines.append("No year before had taught so much.")
	else:
		var dry:=1
		for i in range(annals.size()-1,-1,-1):
			if int((annals[i] as Dictionary).get("learned",1))==0:dry+=1
			else:break
		if dry>=3 and dry<ORDINALS.size():lines.append("Nothing new was learned, for the %s year running." % ORDINALS[dry])
	# 5. The roads.
	var sc:Dictionary=a.scouts
	if int(sc.n)>0:
		var road:="%s went out %s and walked some %s km" % ["Scouts" if tally else "Parties",_times(int(sc.n)),_grouped(int(sc.km))]
		if posmod(seed>>4,2)==1:road="The scouts walked some %s km on %s" % [_grouped(int(sc.km)),"one journey" if int(sc.n)==1 else "%s journeys" % _number(int(sc.n))]
		var far:=0
		for m in annals:far=maxi(far,int((m as Dictionary).get("km",0)))
		if int(sc.km)>far and annals.size()>=3 and far>0:road+=", farther than in any year before"
		var hard:PackedStringArray=[]
		if int(sc.hurt)>0:hard.append("%s hurt and carried home" % ("one was" if int(sc.hurt)==1 else "%s were" % _number(int(sc.hurt))))
		if int(sc.back)>0:hard.append("%s turned back by sickness or hard going" % ("one party" if int(sc.back)==1 else "%s parties" % _number(int(sc.back))))
		lines.append(road+("; "+" and ".join(hard) if not hard.is_empty() else "")+".")
	# 6. Aims, works and other peoples.
	for aim in a.aims:
		match String(aim.kind):
			"done":lines.append("The people kept their aim: %s." % String(aim.name))
			"fail":lines.append("%s was not done in time." % String(aim.name))
			"start":lines.append("A new aim was taken up: %s." % String(aim.name))
	for work in a.works:lines.append("%s was finished." % String(work))
	if not (a.contacts as Array).is_empty():
		var told:PackedStringArray=[]
		for t in (a.contacts as Array).slice(0,2):
			told.append(("the %s came into our knowing" % String(t).get_slice(": ",1)) if ": " in String(t) else String(t))
		lines.append("Of other peoples: %s." % "; ".join(told))
	if not (a.wars as Array).is_empty():lines.append("Of war: %s." % "; ".join(PackedStringArray((a.wars as Array).slice(0,2))))
	# 7. The count of the people, against the last year and the best.
	var pop:=int(memory.pop)
	var pop0:=int(a.pop0)
	if pop>0 and pop0>0:
		var delta:=pop-pop0
		var peak:=0
		for m in annals:peak=maxi(peak,int((m as Dictionary).get("pop",0)))
		var count:=("%d souls at the hearths" if tally else "%d people in the registers") % pop
		var change:=""
		if delta>0:change=", %d more than a year before" % delta
		elif delta<0:change=", %d fewer than a year before" % -delta
		var rec:=""
		if pop>peak and peak>0 and delta>0:rec=", more than ever before"
		elif delta!=0 or int(a.born)+int(a.buried)>0:
			var falls:=0
			for i in range(annals.size()-1,-1,-1):
				var prev_pop:=int((annals[i] as Dictionary).get("pop",0))
				var older:=int((annals[i-1] as Dictionary).get("pop",0)) if i>0 else 0
				if older>0 and prev_pop<older:falls+=1
				else:break
			if delta>0 and falls>=2:rec=", the first rise in %s years" % _number(falls+1)
		var births:=""
		if int(a.born)+int(a.buried)>0:births=" (%s born, %s buried)" % [_number(int(a.born)),_number(int(a.buried))]
		if delta!=0 or rec!="":lines.append("%s%s%s%s." % [_cap(count),change,rec,births])
	# The year's name, from its most memorable event.
	var name:=_name_year(a,annals)
	memory.name=name
	annals.append(memory)
	while annals.size()>ANNALS_MAX:annals.pop_front()
	var title:=_cap(name) if name!="" else _quiet_title(a,seed)
	if lines.is_empty():lines.append("Nothing out of the ordinary was told at the fires." if tally else "The keepers found little to add to the registers.")
	var text:=" ".join(lines)
	if text.length()>900:text=text.left(897)+"..."
	return {"key":"annal:%d" % y,"day":y*365+364,"title":title,"text":text,"kind":"annal","tier":"notice","ledger":false,"domain":"annals","year":y+1,"memory":memory,"facts":_facts(a,memory,title)}


## The year's structured facts, for the optional live rewrite
## (chronicle_polish.gd): only what the entry was built from.
static func _facts(a:Dictionary,memory:Dictionary,title:String)->Dictionary:
	var troubles:Array=[]
	for cr in a.crises:
		troubles.append({"name":_crisis_short(cr),"deaths":int(cr.get("deaths",0)),"over":bool(cr.get("ended",false)),"god_silent":bool(cr.get("silent",false)),"decided_by":String(cr.get("holder",""))})
	var dead:Array=[]
	for d in a.deaths:dead.append({"name":String(d.name),"age":int(d.age)})
	return {"year":int(a.year)+1,"title":title,"troubles":troubles,"dead":dead,"new_keepers":(a.heads as Array).duplicate(),"learned":(a.learned as Array).duplicate(),
		"scouts":(a.scouts as Dictionary).duplicate(),"aims":(a.aims as Array).duplicate(true),"works":(a.works as Array).duplicate(),"peoples":(a.contacts as Array).duplicate(),
		"wars":(a.wars as Array).duplicate(),"people_now":int(memory.get("pop",0)),"people_a_year_before":int(a.pop0),"born":int(a.born),"buried":int(a.buried)}


static func _crisis_short(cr:Dictionary)->String:
	if String(cr.get("short",""))!="":return String(cr.short)
	return _a(_word(String(cr.get("type","hunger")),false))


static func _name_year(a:Dictionary,annals:Array)->String:
	# A great death, a deadly trouble, a first meeting, a kept aim, a finished
	# work, a first knowing, then any trouble at all.
	var name:=""
	for d in a.deaths:
		if bool(d.great):name="the year %s died" % String(d.name).get_slice(" ",0);break
	var deadliest:Dictionary={}
	for cr in a.crises:
		if int(cr.deaths)>0 and (deadliest.is_empty() or int(cr.deaths)>int(deadliest.deaths)):deadliest=cr
	if not deadliest.is_empty() and (name=="" or int(deadliest.deaths)>=3):name=_crisis_short(deadliest)
	if name=="":
		for aim in a.aims:
			if String(aim.kind)=="done":name="the year of %s" % String(aim.name);break
	if name=="" and not (a.works as Array).is_empty():name="the year %s was finished" % String(a.works[0])
	if name=="" and not (a.contacts as Array).is_empty():
		var t:=String(a.contacts[0])
		if ": " in t:name="the year of the %s" % t.get_slice(": ",1)
		elif not t.ends_with(" Is Dead"):name="the year of %s" % _lower_first(t)
	if name=="" and not (a.firsts as Array).is_empty():name="the year of %s" % String(a.firsts[0]).to_lower()
	if name=="" and not (a.crises as Array).is_empty():name=_crisis_short(a.crises[0])
	if name=="" or not name.begins_with("the "):return name
	# A name already given to an earlier year is counted: "the second Dry Year".
	var base:=name.substr(4)
	var seen:=0
	for m in annals:
		var old:=String((m as Dictionary).get("name",""))
		if old==name or old.ends_with(" "+base) and old.begins_with("the "):seen+=1
	if seen>0 and seen+1<ORDINALS.size() and not name.begins_with("the year"):name="the %s %s" % [ORDINALS[seen+1],base]
	return name


static func _quiet_title(a:Dictionary,seed:int)->String:
	if int(a.born)>=int(a.buried)+3:return "A year of many births"
	if not (a.learned as Array).is_empty():return "The year of %s" % String(a.learned[0]).to_lower()
	if int(a.scouts.n)>=2:return "A year on the roads"
	return ["A quiet year","A year without a name","An ordinary year"][posmod(seed,3)]


static func _divine_lines(y:int)->Array:
	var out:Array=[]
	if Engine.get_main_loop()==null:return out
	var regard:Script=load("res://scripts/divine_regard.gd")
	if regard==null:return out
	var events:Variant=regard.call("events",24,0)
	if not events is Array:return out
	for e in events:
		if not e is Dictionary or _year_of(int(e.get("day",-1)))!=y:continue
		var words:=String(DIVINE_WORDS.get(String(e.get("action","")),""))
		if words=="" or String(e.get("name",""))=="":continue
		out.push_front(words % String(e.name))
		if out.size()>=2:break
	return out


static func _regard()->String:
	if Engine.get_main_loop()==null:return ""
	var hall:Script=load("res://scripts/audience_hall.gd")
	var regard:Script=load("res://scripts/divine_regard.gd")
	if hall==null or regard==null:return ""
	var officials:Variant=hall.call("_officials")
	if not officials is Array or (officials as Array).is_empty():return ""
	var read:Variant=regard.call("people_regard",officials)
	return String((read as Dictionary).get("id","")) if read is Dictionary else ""


# --- Words ----------------------------------------------------------------------

static func _word(type:String,plural:bool)->String:
	var pair:Array=TYPE_WORDS.get(type,["trouble","troubles"])
	return String(pair[1 if plural else 0])


static func _a(noun:String)->String:
	return ("an " if noun.substr(0,1) in ["a","e","i","o","u"] else "a ")+noun


static func _number(n:int)->String:
	return NUMBER_WORDS[n] if n>=0 and n<NUMBER_WORDS.size() else str(n)


static func _times(n:int)->String:
	return ["no times","once","twice"][n] if n<3 else "%s times" % _number(n)


static func _cap(text:String)->String:
	return text.substr(0,1).to_upper()+text.substr(1) if text!="" else text


static func _lower_first(text:String)->String:
	if text.begins_with("The "):return "the "+text.substr(4)
	if text.begins_with("A "):return "a "+text.substr(2)
	return text


static func _list(items:Array)->String:
	if items.is_empty():return ""
	if items.size()==1:return String(items[0])
	var head:PackedStringArray=[]
	for i in items.size()-1:head.append(String(items[i]))
	return "%s and %s" % [", ".join(head),String(items.back())]


static func _grouped(value:int)->String:
	var digits:=str(value)
	var out:=""
	for i in digits.length():
		if i>0 and (digits.length()-i)%3==0:out+=","
		out+=digits[i]
	return out
