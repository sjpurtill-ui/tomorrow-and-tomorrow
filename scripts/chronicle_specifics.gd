extends RefCounted
## SPECIFICS — the Chronicle's recurring lines told from what actually happened.
##
## Round one (chronicle_annals.gd) stopped the feed from repeating itself. The
## lines that remained still used one fixed sentence each time: every aim
## "has begun to show", every successor "keeps the fire" with the same closing,
## every sickness "has passed". These composers take the real facts of the
## event (who, what exactly, how far, how long, what was tried and what it
## cost, and how it compares with the last one of its kind) and build the line
## from them, so two sicknesses read differently because they were different.
##
## Pure functions: facts in, words out. Callers gather the facts from live
## state (crisis_system.gd, legacy_aims.gd, court_lives.gd); tests pass them
## directly. Nothing here invents a person, a number or an event.

const NUMBER_WORDS:=["no","one","two","three","four","five","six","seven","eight","nine","ten","eleven","twelve","thirteen","fourteen","fifteen","sixteen","seventeen","eighteen","nineteen","twenty"]

## What was tried against a sickness, in the order it would be told.
const SICK_COURSE:={
	"tend":"the whole camp took turns sitting with the sick","apart":"the sick were kept at their own fire, with food left at the edge of the light",
	"herbs":"the plant-knowers were sent for with their bitter roots","water":"the water was boiled and the drinking place moved upstream",
	"burn":"the sick huts were burned and the families slept elsewhere","healers":"healers were asked for from the neighbours",
	"rite":"the people were called to the fire to hear their god","speak":"the god went among the sick","close":"the path to the strangers was closed",
	"blame":"the people looked for someone to blame"}
const SICK_COURSE_SHORT:={"tend":"everyone tended the sick","apart":"the sick were kept apart","herbs":"the plant-knowers came","water":"the water was boiled",
	"burn":"the sick huts were burned","healers":"healers were sent for","rite":"the people gathered to hear their god","speak":"the god went among them",
	"close":"the path was closed","blame":"they looked for someone to blame"}
const SICK_MID:={"children_apart":"the children were kept away from the sick","mothers":"the mothers nursed their own","far_camp":"the well walked a day upstream to a clean camp",
	"send_away":"some families were sent away to kin","hold":"","stay":""}
## What the course did, as the simulation actually weighs it (crisis_system._apply).
const SICK_EFFECT:={"tend":"With everyone at the bedside, it passed from the sick to their carers.","apart":"Kept apart, the sick passed it to fewer of the well.",
	"herbs":"The fevers broke sooner with the roots.","water":"The flux went where the old water went, and stopped when it stopped.",
	"burn":"With the huts burned, it had fewer places to linger."}
const FIRE_COURSE:={"rebuild":"the huts went back up as they were","apart":"the huts were rebuilt apart, with the hearths outside",
	"earth":"the walls went back up in packed earth","blame":"the people went looking for whoever let the fire loose","rite":"the ashes were given to the god","hold":"","save_stores":"the stores were carried out first"}
const DRY_COURSE:={"carry":"water was carried from the far pools","hardy":"the seed that needs little water was sown","rain":"the people were told their god would bring rain",
	"hold":"the people held on as they were","ration":"what there was was made to last","seed":"the seed was eaten","range":"the gatherers walked farther"}
const WORN_COURSE:={"range":"the gatherers walked farther for food","rest":"the near ground was left alone for a year","burn_brush":"the old brush was burned for new growth",
	"press":"the gatherers kept working the same worn ground"}


static func num(n:int)->String:
	return NUMBER_WORDS[n] if n>=0 and n<NUMBER_WORDS.size() else str(n)


static func cap(text:String)->String:
	return text.substr(0,1).to_upper()+text.substr(1) if text!="" else text


static func _pick(options:Array,seed:int)->String:
	return String(options[posmod(seed,options.size())]) if not options.is_empty() else ""


static func _ordinal(n:int)->String:
	var words:=["zeroth","first","second","third","fourth","fifth","sixth","seventh","eighth","ninth","tenth","eleventh","twelfth","thirteenth","fourteenth","fifteenth","sixteenth","seventeenth","eighteenth","nineteenth","twentieth"]
	return words[n] if n>=0 and n<words.size() else "%dth" % n


static func _weeks(days:int)->String:
	var w:=maxi(1,roundi(float(days)/7.0))
	return "a week" if w==1 else "%s weeks" % num(w)


static func _winters(n:int)->String:
	return "one winter" if n==1 else ("%s winters" % num(n) if n>0 else "less than a winter")


static func _names(list:Array)->String:
	var items:PackedStringArray=[]
	for n in list:items.append(String(n))
	if items.is_empty():return ""
	if items.size()==1:return items[0]
	return "%s; and %s" % ["; ".join(items.slice(0,items.size()-1)),items[items.size()-1]]


## "the Coughing Winter of year 47" -> "the Coughing Winter".
static func short_name(name:String)->String:
	var n:=name.strip_edges()
	var re:=RegEx.create_from_string(" of (year \\d+|the [a-z\\-]+ year)$")
	n=re.sub(n,"")
	if n.begins_with("The "):n="the "+n.substr(4)
	return n


# --- Crises ---------------------------------------------------------------------

## The end of a crisis, told from its facts:
##   type, name, days, sick, where, deaths, dead[], choice, mid_choice, helper,
##   house_lost, back (thinning: the ground recovered), prior (the last crisis
##   of this type: {name, year, deaths, choice}), seed.
## Returns the text. The words for the dead always say "took N" or "no one
## died" so the year's telling can count them from the text alone.
static func crisis_end(f:Dictionary)->String:
	var type:=String(f.get("type",""))
	match type:
		"sickness","stranger":return _sickness_end(f)
		"fire":return _fire_end(f)
		"drought":return _drought_end(f)
		"thinning":return _worn_end(f)
	return ""


static func _deaths_words(f:Dictionary,seed:int,noun:String="it")->String:
	var n:=int(f.get("deaths",0))
	var dead:Array=f.get("dead",[])
	var named:=_names(dead.slice(0,3))
	if n<=0:return ""
	var more:=", among them " if n>mini(3,dead.size()) and named!="" else (": " if named!="" else "")
	return _pick(["%s took %s%s%s.","%s took %s before it was done%s%s."],seed) % [cap(noun),num(n),more,named]


static func _sickness_end(f:Dictionary)->String:
	var seed:=int(f.get("seed",0))
	var name:=String(f.get("name","the sickness"))
	var sick:=int(f.get("sick",0))
	var where:=String(f.get("where",""))
	var days:=int(f.get("days",0))
	var deaths:=int(f.get("deaths",0))
	var choice:=String(f.get("choice",""))
	var mid:=String(f.get("mid_choice",""))
	var lines:PackedStringArray=[]
	# 1. How long, how many, where.
	if sick>0 and days>0:
		var at:=(" "+where) if where!="" else ""
		lines.append(_pick([
			"%s ran %s%s; %s fell ill." % [cap(name),_weeks(days),at,num(sick)],
			"For %s %s kept %s people down%s." % [_weeks(days),name,num(sick),at],
			"%s fell ill%s before %s burned itself out, %s after it began." % [cap(num(sick)),at,short_name(name),_weeks(days)],
			"%s is over. It lasted %s and put %s on their backs%s." % [cap(name),_weeks(days),num(sick),at]],seed))
	else:
		lines.append("%s has passed." % cap(name))
	# 2. The dead.
	if deaths>0:lines.append(_deaths_words(f,seed>>2))
	elif sick>0:lines.append(_pick(["All %s got up again; no one died of it." % num(sick),"No one died of it.","Every one of them lived; no one died of it."],seed>>2))
	else:lines.append("No one died of it.")
	# 3 and 4. What was tried, and how that has gone before.
	var course:=String(SICK_COURSE.get(choice,""))
	var then:=String(SICK_MID.get(mid,""))
	var tried:=""
	if course!="" and then!="":tried="%s; when it spread, %s." % [cap(course),then]
	elif course!="":tried="%s." % cap(course)
	var prior:Dictionary=f.get("prior",{}) if f.get("prior") is Dictionary else {}
	var year:=int(f.get("year",0))
	var run:=int(f.get("run",1))
	if not prior.is_empty() and int(prior.get("year",0))>0:
		var py:=int(prior.year)
		var when:="earlier this year" if py==year else "in year %d" % py
		var pd:=int(prior.get("deaths",0))
		var same:=String(prior.get("choice",""))==choice and choice!=""
		var was:="no one died" if pd==0 else ("one died" if pd==1 else "%s died" % num(pd))
		if same and run>=3 and String(SICK_COURSE_SHORT.get(choice,""))!="":
			# The same answer, sickness after sickness: count it instead of retelling it.
			var rd:=int(f.get("run_deaths",0))
			var cost:="no one has died of them" if rd==0 else ("one has died of them" if rd==1 else "%s have died of them" % num(rd))
			var since:=int(f.get("since",py))
			lines.append(_pick(["As at every sickness since year %d, %s; that is %s in a row, and %s." % [since,String(SICK_COURSE_SHORT[choice]),num(run),cost],
				"It was met the way the last %s were met, %s; since year %d %s." % [num(run-1),"with the whole camp at the bedside" if choice=="tend" else "the same way",since,cost],
				"%s, for the %s sickness running; %s since year %d." % [cap(String(SICK_COURSE_SHORT[choice])),_ordinal(run),cost,since]],seed>>4))
			if then!="":lines.append("When it spread, %s." % then)
		elif same:
			var outcome:="this time it cost less" if deaths<pd else ("this time it went worse" if deaths>pd else ("and again no one was lost" if pd==0 else "and it took the same toll"))
			lines.append("%s, as %s, when %s; %s." % [cap(String(SICK_COURSE_SHORT.get(choice,course))),when,was,outcome])
			if then!="":lines.append("When it spread, %s." % then)
		else:
			if tried!="":lines.append(tried)
			if String(SICK_COURSE_SHORT.get(String(prior.get("choice","")),""))!="" and choice!="":
				lines.append("%s %s and %s; this time %s, and %s." % [cap(when),String(SICK_COURSE_SHORT[String(prior.choice)]),was,String(SICK_COURSE_SHORT.get(choice,"it was met differently")),"no one died" if deaths==0 else ("one died" if deaths==1 else "%s died" % num(deaths))])
	else:
		if tried!="":lines.append(tried)
		if String(SICK_EFFECT.get(choice,""))!="" and (deaths>0 or choice!="tend"):lines.append(String(SICK_EFFECT[choice]))
	# 5. The one the people remember.
	var helper:=String(f.get("helper",""))
	if helper!="":
		lines.append(_pick(["%s sat with the sick every night and never fell ill; the people remember it.","%s carried water to the sick fire every day of it and stayed well.","It was %s who sat up with the worst of them, night after night, and did not fall ill."],seed>>6) % helper)
	return " ".join(lines)


static func _fire_end(f:Dictionary)->String:
	var seed:=int(f.get("seed",0))
	var lost:=int(f.get("house_lost",0))
	var days:=int(f.get("days",0))
	var roofs:=clampi(roundi(float(lost)/5.0),1,12) if lost>0 else 0
	var lines:PackedStringArray=[]
	var course:=String(FIRE_COURSE.get(String(f.get("choice","")),""))
	if roofs>0:lines.append(_pick(["The camp has its roofs again, %s after the fire took %s huts." % [_weeks(days),num(roofs)],
		"The %s burned huts stand again, %s on." % [num(roofs),_weeks(days)],"It took %s to put back the %s huts the fire had eaten." % [_weeks(days),num(roofs)]],seed))
	else:lines.append("The camp has its roofs again.")
	if course!="":lines.append("%s." % cap(course))
	var deaths:=int(f.get("deaths",0))
	if deaths>0:lines.append(_deaths_words(f,seed>>2,"the fire"))
	else:lines.append(_pick(["The fire killed no one.","No one died in it.","Everyone got out; no one died."],seed>>2))
	var prior:Dictionary=f.get("prior",{}) if f.get("prior") is Dictionary else {}
	if not prior.is_empty() and int(prior.get("year",0))>0:
		var same:=String(prior.get("choice",""))==String(f.get("choice",""))
		if same and String(f.get("choice",""))=="rebuild":lines.append("The huts went up the same way after the fire of year %d, close together as before." % int(prior.year))
		elif not same and course!="":lines.append("After the fire of year %d they had built as before; not this time." % int(prior.year))
	return " ".join(lines)


static func _drought_end(f:Dictionary)->String:
	var seed:=int(f.get("seed",0))
	var days:=int(f.get("days",0))
	var lines:PackedStringArray=[]
	lines.append(_pick(["The rain came back after %s of hard sky." % _weeks(days),"The springs are running again, %s after they began to fail." % _weeks(days),"It rained at last. The dry spell had held %s." % _weeks(days)],seed))
	var course:=String(DRY_COURSE.get(String(f.get("choice","")),""))
	var mid:=String(DRY_COURSE.get(String(f.get("mid_choice","")),""))
	if course!="" and mid!="" and mid!=course:lines.append("%s; later %s." % [cap(course),mid])
	elif course!="":lines.append("%s." % cap(course))
	var deaths:=int(f.get("deaths",0))
	if deaths>0:lines.append(_deaths_words(f,seed>>2,"the dry year"))
	else:lines.append(_pick(["Everyone lived through it.","No one died of the dry year.","The dry year killed no one."],seed>>2))
	var prior:Dictionary=f.get("prior",{}) if f.get("prior") is Dictionary else {}
	if not prior.is_empty() and int(prior.get("year",0))>0 and String(prior.get("choice",""))==String(f.get("choice","")) and course!="":
		lines.append("It was met as the dry year of year %d was met." % int(prior.year))
	return " ".join(lines)


static func _worn_end(f:Dictionary)->String:
	var seed:=int(f.get("seed",0))
	var back:=bool(f.get("back",false))
	var lines:PackedStringArray=[]
	lines.append(_pick(["The gatherers say the near ground %s." % ("is coming back" if back else "is still worn"),
		("Green is coming back to the dug-over ground near camp." if back else "The ground near camp is still bare and dug over."),
		("The snares by the stream catch again." if back else "The snares by the stream still come back empty.")],seed))
	var course:=String(WORN_COURSE.get(String(f.get("choice","")),""))
	if course!="":lines.append("For half a year %s." % course)
	var prior:Dictionary=f.get("prior",{}) if f.get("prior") is Dictionary else {}
	if not prior.is_empty() and int(prior.get("year",0))>0:
		var n:=int(f.get("count",0))
		if n>=3:lines.append("It is the %s time the near ground has given out since the founding; the last was in year %d." % [["","first","second","third","fourth","fifth","sixth","seventh","eighth","ninth","tenth"][mini(n,10)],int(prior.year)])
		else:lines.append("The last time, in year %d, %s." % [int(prior.year),String(WORN_COURSE.get(String(prior.get("choice","")),"the gatherers went on as before"))])
	return " ".join(lines)


# --- Aims -----------------------------------------------------------------------

## An aim's milestone, from its facts:
##   title, template, mark (25|50|75), value (value_words), keeper (given name),
##   used (winters since sworn), left (winters left), pace ("ahead"|"even"|
##   "behind"), latest[] (new ways learned lately), pop0/pop (grow), builders
##   (work), subject (a people's name), seed.
## Returns [title, text].
static func aim_mark(f:Dictionary)->Array:
	var seed:=int(f.get("seed",0))
	var name:=String(f.get("title","Our aim"))
	var mark:=int(f.get("mark",25))
	var value:=String(f.get("value",""))
	var keeper:=String(f.get("keeper",""))
	var used:=int(f.get("used",0))
	var left:=int(f.get("left",0))
	var pace:=String(f.get("pace","even"))
	var how_far:=String({25:"a quarter of the way",50:"halfway",75:"three parts of the way"}.get(mark,"part of the way"))
	var stage:=String({25:"A Quarter Done",50:"Halfway",75:"Nearly Done"}.get(mark,"Under Way"))
	var title:=""
	match pace:
		"ahead":title=_pick(["%s: %s, Ahead of Time" % [name,stage],"%s Runs Ahead of Its Winters" % name],seed)
		"behind":title=_pick(["%s: %s, Behind Time" % [name,stage],"%s Falls Behind Its Winters" % name],seed)
		_:title="%s: %s" % [name,stage]
	var lines:PackedStringArray=[]
	# How far, in the thing itself, and in winters.
	var time:=""
	if used>0 or left>0:
		time="after %s, with %s left" % [_winters(used),_winters(left)] if left>0 else "after %s, with the last winter running" % _winters(used)
	if value!="" and time!="":lines.append(_pick(["%s: %s %s." % [name,value,time],"%s, %s stands at %s." % [cap(time),name,value],"%s stands at %s, %s." % [name,value,time]],seed>>1))
	elif value!="":lines.append("%s stands at %s." % [name,value])
	else:lines.append("%s is %s done." % [name,how_far])
	# Against the winters it was given.
	match pace:
		"ahead":lines.append(_pick(["That is faster than the winters asked for.","At this pace it will be done with winters to spare."],seed>>3))
		"behind":lines.append(_pick(["At this pace the winters will run out first.",("It is slower than the winters allow; one more year like these will not be enough." if left<=1 else "It is slower than the winters allow; %s more years like these will not be enough." % num(left))],seed>>3))
	# What exactly moved it, and what it cost.
	var template:=String(f.get("template",""))
	var latest:Array=f.get("latest",[])
	match template:
		"knowledge","learn":
			if not latest.is_empty():lines.append("The newest %s %s." % ["was" if latest.size()==1 else "were",_list_lower(latest.slice(0,3))])
		"grow":
			var p0:=int(f.get("pop0",0));var p:=int(f.get("pop",0))
			if p0>0 and p>0 and p!=p0:lines.append("There were %d at the hearths when it was sworn; there are %d now." % [p0,p])
		"work":
			var b:=int(f.get("builders",0))
			if b>0:lines.append("About %s people give their days to it instead of to gathering." % num(b))
		"plenty":
			var fd:=int(f.get("food_days",0))
			if fd>0:lines.append("The pits hold about %d days of food." % fd)
		"reach":
			var km:=int(f.get("km",0))
			if km>0:lines.append("The scouts have charted about %d km more of the land." % km)
	if keeper!="":lines.append(_pick(["%s keeps count of it." % keeper,"%s is the one who tells the court how it goes." % keeper,"%s has charge of it." % keeper],seed>>5))
	return [title," ".join(lines)]


static func _list_lower(items:Array)->String:
	var out:PackedStringArray=[]
	for i in items:out.append(String(i).to_lower())
	if out.size()<=1:return "".join(out)
	return "%s and %s" % [", ".join(out.slice(0,out.size()-1)),out[out.size()-1]]


# --- Successions ----------------------------------------------------------------

## A successor taking up the dead one's place when the god has named no one:
##   dead (given), successor (full name), given, kin (what the successor was
##   to the dead: child, sibling...), office, age, dead_age, served (winters
##   the dead held it), skill (own words), unnamed (how many successions the
##   god has left to the people before this one), others[] (officials passed
##   over, given names), seed.
## Returns [title, text].
static func succession(f:Dictionary)->Array:
	var seed:=int(f.get("seed",0))
	var dead:=String(f.get("dead",""))
	var full:=String(f.get("successor",""))
	var given:=String(f.get("given",full))
	var kin:=String(f.get("kin",""))
	var office:=String(f.get("office","")).to_lower()
	var age:=int(f.get("age",0))
	var dead_age:=int(f.get("dead_age",0))
	var served:=int(f.get("served",0))
	var unnamed:=int(f.get("unnamed",0))
	var who:=full if kin=="" else "%s, %s's %s," % [full,dead,kin]
	var lines:PackedStringArray=[]
	lines.append(_pick(["A month after %s's burning, %s keeps the fire as %s." % [dead,who,office],
		"%s has taken up %s's place as %s." % [who,dead,office],
		"Since %s's burning it is %s who keeps the fire as %s." % [dead,who,office]],seed).replace(",,",","))
	# Who they are, against who came before.
	var skill:=String(f.get("skill",""))
	if age>0 and dead_age>0 and age*2<=dead_age+4:lines.append("At %d %s is young for it; %s died at %d." % [age,given,dead,dead_age])
	elif age>=65:lines.append("%s is %d, older than most who have kept it." % [given,age])
	elif age>0 and skill!="":lines.append("%s is %d and has %s." % [given,age,skill])
	elif age>0:lines.append("%s is %d." % [given,age])
	if served>=10:lines.append("%s held it %s; the people are not used to another face in that place." % [dead,_winters(served)])
	elif served>0 and served<=2:lines.append("%s held it only %s." % [dead,_winters(served)])
	var others:Array=f.get("others",[])
	if not others.is_empty():lines.append("%s %s passed over." % [_names(others.slice(0,2)).replace(";",","),"was" if others.size()==1 else "were"])
	# The god's part, counted.
	if unnamed<=0:lines.append("The god has named no one; the people take this as the god's leave.")
	elif unnamed==1:lines.append(_pick(["Again the god named no one, and the people let the choice stand.","Once more the god left the choosing to the people."],seed>>2))
	else:lines.append(_pick(["It is the %s time the god has left a successor to the people." % ["","first","second","third","fourth","fifth","sixth","seventh","eighth","ninth","tenth"][mini(unnamed+1,10)],
		"The god has not named a successor in %s deaths now; the people choose, and wait to see if the god minds." % num(unnamed+1)],seed>>2))
	var title:=_pick(["%s Keeps the Fire" % given,"%s Follows %s" % [given,dead],"%s in %s's Place" % [given,dead]],seed>>4)
	return [title," ".join(lines)]


## The closing of an official's death notice, varied by who holds the mourning.
static func mourning_close(holder:String,seed:int)->String:
	if holder=="":return _pick(["The court gathers at the fire to mourn them.","The court sits up with the body through the night."],seed)
	return _pick(["The court gathers at the fire to mourn them; %s holds the mourning and asks the god who follows." % holder,
		"%s keeps the vigil and will bring the matter of who follows to the god." % holder,
		"The court mourns at the fire. %s waits to ask the god who is to follow." % holder],seed)
