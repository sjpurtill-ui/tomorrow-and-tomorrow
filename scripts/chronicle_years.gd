extends RefCounted
## THE YEAR'S TELLING, round three: each year told by what made it different.
##
## chronicle_annals.gd gathers a year's facts; this module turns them into the
## year's entry and, every GENERATION_YEARS, a short account of the generation.
##
##   items()     Every fact the year could tell becomes a candidate line with a
##               weight (how much it marks this year out) and a signature (its
##               content, without names or numbers). A line whose signature is
##               the same as last year's is dropped unless it is news: a record,
##               a first, a reversal, a run reaching a round count.
##   entry()     The heaviest line leads, the rest follow by weight, so the
##               order changes with what happened. Wordings rotate: a phrasing
##               used in the last few years is passed over for another.
##   age()       Every GENERATION_YEARS a generation's account: who kept the
##               fire, what the people came through and at what cost, what the
##               god did, what changed their days, whom they met, set against
##               the generation before.
##
## Pure over its inputs (the year's facts, the earlier years' compact records,
## and a few optional live reads guarded for tests). Nothing here invents a
## person, a number or an event.

const GENERATION_YEARS:=20
## What a new way changed, as the people would notice it, by its largest
## effect (discovery effects: key and sign). Plain words any era has.
const EFFECT_WORDS:={"cohesion+":"households pulled together more","legitimacy+":"people heeded the elders more readily","labor_efficiency+":"the day's work went quicker",
	"knowledge_preservation+":"less of what the old ones knew was forgotten","storage_loss-":"less of the stores went bad","trade_capacity+":"there was more to trade with neighbours",
	"fatigue-":"people came home from work less worn out","task_coordination+":"the work parties got in each other's way less","route_speed+":"the paths were walked faster",
	"travel_speed+":"journeys took fewer days","security_efficiency+":"the watch kept better guard","survey_speed+":"the scouts came to know the land sooner",
	"conception_support+":"more women carried a child","ecological_pressure-":"the ground near camp was spared","ecology_recovery+":"worn ground came back sooner",
	"food_output+":"there was more to eat","disaster_risk-":"floods and fires did less harm","foraging_yield+":"the gatherers brought back more","container_capacity+":"more could be carried and kept",
	"nutrition_quality+":"the meals were better","housing_output+":"huts went up faster","warfare_readiness+":"the young were readier to fight","soil_productivity+":"the sown ground gave more",
	"food_storage+":"food kept longer","maternal_safety+":"fewer mothers died giving birth","water_safety+":"fewer fell sick from the water","craft_output+":"the makers turned out more",
	"hunting_yield+":"the hunters brought home more meat","disaster_resilience+":"the camp stood up better to flood and fire","injury_risk-":"fewer were hurt at their work",
	"stone_yield+":"more good stone came in","fiber_yield+":"there was more fibre for cord","cultivation_yield+":"the sown ground gave more","labor_demand-":"the work needed fewer hands",
	"food_spoilage-":"less food spoiled","pollution-":"the camp was cleaner","construction_rate+":"building went faster","haul_capacity+":"one back could carry more",
	"repair_capacity+":"broken things were mended sooner","neonatal_survival+":"more newborns lived","sanitation+":"the camp was cleaner","water_access+":"water was nearer to hand",
	"disease_exposure-":"fewer caught sickness","timber_yield+":"more timber came in","health_protection+":"fewer fell sick","logistics_endurance+":"parties could stay out longer on the trail",
	"mobile_shelter+":"shelter could be carried on the move","fuel_efficiency+":"the fires burned less wood","clay_yield+":"more good clay was dug","dry_storage+":"the stores stayed dry",
	"health_risk-":"fewer fell sick","timber_pressure-":"fewer trees had to be felled"}
const MAX_LINES:=5
## Wordings used within this many years are passed over when another will do.
const FRESH_YEARS:=6
const NUMBER_WORDS:=["no","one","two","three","four","five","six","seven","eight","nine","ten","eleven","twelve","thirteen","fourteen","fifteen","sixteen","seventeen","eighteen","nineteen","twenty"]
const ORDINALS:=["zeroth","first","second","third","fourth","fifth","sixth","seventh","eighth","ninth","tenth","eleventh","twelfth","thirteenth","fourteenth","fifteenth","sixteenth","seventeenth","eighteenth","nineteenth","twentieth"]
## Counts worth marking in a run (years without trouble, silences, ...).
const ROUND_COUNTS:=[3,5,10,15,20,25,30,40,50]
const REGARD_WORDS:={"worships":"speak of the god with love and fear together","reveres":"speak of the god with reverence","fearless_love":"speak of the god warmly and without fear",
	"terror":"lower their voices when they speak of the god","hates_dread":"fear the god, and some curse the god in whispers","resents":"grumble about the god when they think no one hears",
	"wary":"keep a careful distance from the god","cold":"speak of the god less and less","dutiful":"do what the god asks, without much feeling"}
const DIVINE_WORDS:={"terrify":"The god's fury fell on %s before the court.","penance":"%s was made to fast and keep vigil for the god.","cast_out":"%s was cast out at the god's word.",
	"strike_down":"%s was put to death at the god's word.","bless":"The god blessed %s before everyone.","boon":"The god gave %s a gift from the stores.","raise_up":"The god raised %s above the others.",
	"flight":"%s fled beyond the god's reach.","terrify_envoy":"The god terrified %s, an envoy, before the whole camp.","slay_envoy":"%s, an envoy, was killed at the god's word.",
	"maim_envoy":"%s, an envoy, was maimed at the god's word.","shame_envoy":"%s, an envoy, was shamed and sent home."}
## Figures' callings in the people's own words.
const ROLE_WORDS:={"General":"war leader","Scholar":"one who asks why things are so","Physician":"healer","Engineer":"builder","Agronomist":"grower who compares the harvests","Organizer":"one who orders the common work",
	"Artist":"carver and painter","Explorer":"pathfinder","Architect":"master builder"}
## How the god answered an envoy, in the third person, by request and answer.
## {civ} is the people ("the Esurai"); other slots come from the kept facts.
const ENVOY_WORDS:={
	"food_loan:accept":"{Civ} came hungry and borrowed {sent} food from the stores{repaid}.","food_loan:partial":"{Civ} came hungry and were lent {sent} food, less than they asked{repaid}.",
	"food_loan:gift":"{Civ} came hungry, and the god gave them {sent} food and asked nothing back.","food_loan:refuse":"{Civ} came hungry and asked to borrow food; the god sent them home without it.",
	"work_for_food:accept":"Young people of {civ} worked the {where} for food to carry home.","work_for_food:refuse":"{Civ} offered their work for food and were refused.",
	"barter:accept":"{Civ} traded their {get_res} for our {give_res}.","barter:bargain":"{Civ} came to trade {get_res}, and the god drove a hard bargain.","barter:refuse":"{Civ} came to trade and were turned away.",
	"refuge:accept":"{People} of {civ} were taken in at our fires.","refuge:partial":"Mothers and children of {civ} were taken in; the rest were sent home.","refuge:refuse":"Families of {civ} were turned away at the border.",
	"forage_leave:accept":"Hunters of {civ} were let into the {place}.","forage_leave:refuse":"Hunters of {civ} were kept out of the {place}.",
	"craft_teaching:accept":"A teacher of {craft_name} went to {civ}.","craft_teaching:gift":"A teacher of {craft_name} went to {civ}, for nothing.","craft_teaching:refuse":"{Civ} asked to learn {craft_name} and were refused.",
	"healer_plea:accept":"Our healers went into the sick camps of {civ}.","healer_plea:partial":"Plants for the sick went to {civ}, but our healers stayed home.","healer_plea:refuse":"Sickness was in the camps of {civ}, and the paths to them were closed.",
	"mediation:accept":"The god judged the {place} to be {civ}'s, against {third_name}.","mediation:partial":"The god divided the {place} between {civ} and {third_name}.",
	"mediation:other":"The god gave the {place} to {third_name}, against {civ}.","mediation:refuse":"The god would not judge between {civ} and {third_name}.",
	"marriage_request:accept":"One of our people married {heir} of {civ}; the two peoples are kin now.","marriage_request:partial":"{Heir} of {civ} came to live among us as a spouse.",
	"marriage_request:refuse":"{Civ} sought a marriage, and the god refused the match.",
	"border_line:accept":"The {place} was given to {civ}.","border_line:partial":"The {place} was made common ground with {civ}.","border_line:refuse":"The border at the {place} was held against {civ}.",
	"fugitive_return:accept":"{Name} was given back to {civ} to answer for it.","fugitive_return:bargain":"The god paid a blood-price to {civ} to keep {name}.","fugitive_return:refuse":"{Civ} demanded {name} back, and the god sheltered them.",
	"blessing_rite:accept":"The god blessed {what} for {civ}.","blessing_rite:refuse":"{Civ} asked the god's blessing and were refused.",
	"war_supplies:accept":"{Amount} {res} went to {civ} for their war with {enemy_name}.","war_supplies:refuse":"{Civ} asked for help against {enemy_name}; the god kept out of it.",
	"succession_backing:accept":"The god named {ruler} the rightful ruler of {civ}.","succession_backing:refuse":"The god withheld its word from {ruler} of {civ}.",
	"hostage_exchange:accept":"Young kin were exchanged with {civ} as pledges of peace.","hostage_exchange:refuse":"{Civ} offered pledges of peace, and the god declined them.",
	"sacred_site:accept":"People of {civ} were let in to visit {what}.","sacred_site:refuse":"{Civ} were barred from {what}.",
	"captive_scouts:accept":"Scouts held captive between us and {civ} went home.","captive_scouts:refuse":"Scouts held captive between us and {civ} stayed captive.",
	"captive_scouts:bargain":"Scouts were ransomed back from {civ}.","captive_scouts:partial":"The god promised {civ} that no more scouts would cross into their country.",
	"rite_keeper:accept":"One who keeps our rites went to live among {civ}.","rite_keeper:refuse":"{Civ} asked to learn our rites and were refused.",
	"boundary_cairn:accept":"Our elders and those of {civ} raised a cairn together at the {place}.","boundary_cairn:partial":"{Civ} raised their cairn at the {place}.",
	"boundary_cairn:refuse":"{Civ} asked to mark the line at the {place}, and were refused.",
	"joint_hunt:accept":"Our hunters drove the herd with those of {civ} in the {place}.","joint_hunt:gift":"Our hunters drove the herd with those of {civ} and left them all the meat.",
	"joint_hunt:refuse":"{Civ} asked our hunters to join their drive; they stayed home.",
	"safe_passage:accept":"Carriers of {civ} crossed our country to {dest_name}.","safe_passage:refuse":"Our country was closed to the carriers of {civ}.",
	"request:grant":"{Civ} asked for {resource}, and the god gave {amount}.","request:grant_half":"{Civ} asked for {resource} and were given half, {amount}.","request:refuse":"{Civ} asked for {resource} and went home with nothing.",
	"threat:pay":"{Civ} demanded tribute, and the god paid {amount} {resource}.","threat:defy":"{Civ} demanded tribute, and the god would not pay.","threat:counter":"{Civ} demanded tribute, and the god answered with a demand of its own.",
	"gift:accept":"{Civ} sent a gift of {amount} {resource}.","gift:decline":"{Civ} sent a gift, and the god sent it back.",
}


# --- Small words ----------------------------------------------------------------

static func num(n:int)->String:
	return NUMBER_WORDS[n] if n>=0 and n<NUMBER_WORDS.size() else str(n)


static func ordinal(n:int)->String:
	return ORDINALS[n] if n>=0 and n<ORDINALS.size() else "%dth" % n


static func cap(text:String)->String:
	return text.substr(0,1).to_upper()+text.substr(1) if text!="" else text


static func list(items:Array)->String:
	var parts:PackedStringArray=[]
	for i in items:if String(i)!="":parts.append(String(i))
	if parts.is_empty():return ""
	if parts.size()==1:return parts[0]
	return "%s and %s" % [", ".join(parts.slice(0,parts.size()-1)),parts[parts.size()-1]]


static func _lower_first(text:String)->String:
	for article in ["The ","A ","An "]:
		if text.begins_with(article):return article.to_lower()+text.substr(article.length())
	return text


static func first_sentence(text:String)->String:
	var clean:=text.strip_edges()
	for i in clean.length():
		if clean[i] in [".","!","?"] and (i==clean.length()-1 or clean[i+1]==" "):return clean.substr(0,i+1)
	return clean


static func _round(n:int)->bool:
	return ROUND_COUNTS.has(n)


## Picks a wording. `variants` are formatted already; the one used least
## recently (or never) within FRESH_YEARS is preferred, starting from the
## year's seed so neighbouring years differ.
static func say(ctx:Dictionary,id:String,variants:Array)->String:
	if variants.is_empty():return ""
	var recent:Dictionary=ctx.get("recent",{})
	var start:=posmod(int(ctx.get("seed",0))+hash(id),variants.size())
	var pick:=start
	for step in variants.size():
		var i:=(start+step)%variants.size()
		if not recent.has("%s.%d" % [id,i]):pick=i;break
	(ctx.used as Array).append("%s.%d" % [id,pick])
	return String(variants[pick])


# --- The year's candidate lines -------------------------------------------------

## Returns [{t (topic), w (weight), text, sig}], unsorted. `a` is the year's
## facts, `annals` the earlier years' records (oldest first), `ctx` carries the
## seed, era ("tally" or "annals"), recently used wordings, the people's regard
## and the god's acts this year.
static func items(a:Dictionary,annals:Array,ctx:Dictionary)->Array:
	var out:Array=[]
	var y:=int(a.get("year",0))
	var last:Dictionary=annals.back() if not annals.is_empty() else {}
	var last_sig:Dictionary=last.get("sig",{}) if last.get("sig") is Dictionary else {}
	_troubles(a,annals,ctx,out,last_sig)
	_god(a,annals,ctx,out,last_sig)
	_dead(a,annals,ctx,out)
	_learning(a,annals,ctx,out,last_sig)
	_abroad(a,annals,ctx,out)
	_people(a,annals,ctx,out,last_sig)
	_aims_and_works(a,ctx,out)
	_roads(a,annals,ctx,out)
	for item in out:item["y"]=y
	return out


static func _crisis_name(cr:Dictionary)->String:
	for field in ["told","short"]:
		if String(cr.get(field,""))!="":return String(cr.get(field,""))
	return "a trouble"


## "the Coughing Winter twice", or the name alone.
static func _named(crises:Array)->PackedStringArray:
	var names:PackedStringArray=[]
	var counts:={}
	for cr in crises:
		var n:=_crisis_name(cr)
		counts[n]=int(counts.get(n,0))+1
		if int(counts[n])==1:names.append(n)
	var told:PackedStringArray=[]
	for n in names.slice(0,3):told.append(n if int(counts[n])==1 else "%s %s" % [n,["","once","twice","three times","four times"][mini(int(counts[n]),4)]])
	return told


static func _troubles(a:Dictionary,annals:Array,ctx:Dictionary,out:Array,last_sig:Dictionary)->void:
	var crises:Array=a.get("crises",[])
	var deaths:=0
	for cr in crises:deaths+=int(cr.get("deaths",0))
	if crises.is_empty():
		_calm(a,annals,ctx,out,last_sig)
		return
	var ended:Array=[]
	var still:Array=[]
	for cr in crises:
		if bool(cr.get("ended",true)) or int(cr.get("deaths",0))>0:ended.append(cr)
		else:still.append(cr)
	var victims:PackedStringArray=[]
	for cr in crises:
		for v in cr.get("dead",[]):if victims.size()<3:victims.append(String(v))
	# The one who stood out: named when the year cost lives, or when no one
	# has been named so for a couple of years.
	var named_lately:=false
	for m in annals.slice(maxi(0,annals.size()-2)):
		if String(((m as Dictionary).get("sig",{}) as Dictionary).get("helper",""))!="":named_lately=true
	for cr in crises:
		var helper:=String(cr.get("helper",""))
		if helper=="" or (named_lately and deaths==0):continue
		var what:=_crisis_name(cr)
		out.append({"t":"helper","w":4.0 if deaths>0 else 2.5,"sig":"named","text":say(ctx,"helper",["It was %s who sat with the sick through %s and never fell ill." % [helper,what],"Through %s, %s kept the sick fire going and stayed well." % [what,helper],"People talk of %s, who nursed the sick through %s and stayed well." % [helper,what],"%s nursed the sick through %s; the people remember it." % [helper,what]])})
		break
	if not still.is_empty():
		var open:=_named(still)
		out.append({"t":"open","w":3.0 if ended.is_empty() else 2.0,"sig":"","text":say(ctx,"open",["%s was still on the camp at the year's end." % cap(list(Array(open))),"At the year's end %s had not yet let go." % list(Array(open)),"The year ended with %s still on the camp." % list(Array(open))])})
	if ended.is_empty():return
	var told:=_named(ended)
	var came:=list(Array(told))
	if deaths>0:
		var who:=(": "+"; ".join(victims)) if not victims.is_empty() else ""
		var text:=""
		if told.size()==1:text=say(ctx,"deaths_one",["%s took %s%s." % [cap(came),num(deaths),who],"%s died of %s%s." % [cap(num(deaths)),came,who],"%s came, and %s did not live through it%s." % [cap(came),num(deaths),who]])
		else:text=say(ctx,"deaths_many",["%s troubles came: %s. Together they took %s%s." % [cap(num(ended.size())),came,num(deaths),who],"The people buried %s after %s%s." % [num(deaths),came,who],"%s between them killed %s%s." % [cap(came),num(deaths),who]])
		var w:=5.0+float(deaths)
		# Set against the years before: the worst since the founding, or since year N.
		var worst:=0
		for m in annals:worst=maxi(worst,int((m as Dictionary).get("deaths",0)))
		var extra:=""
		if deaths>worst and annals.size()>=3:
			extra=say(ctx,"deaths_record",["No year since the founding has lost so many to its troubles.","The people had never buried so many to the year's troubles."]);w+=4.0
		elif deaths>=2:
			var since:=_since(annals,func(m:Dictionary)->bool:return int(m.get("deaths",0))>=deaths)
			if since>=0 and y_of(a)-since>=8:
				extra=say(ctx,"deaths_since",["Not since year %d had the troubles cost so many." % (since+1),"It was the heaviest toll since year %d." % (since+1),"The last year to bury as many was year %d." % (since+1)]);w+=2.0
		out.append({"t":"troubles","w":w,"sig":"deaths","text":(text+(" "+extra if extra!="" else "")).strip_edges()})
		return
	# No one died of them. Worth saying when the year before cost lives, or
	# when the run of deathless troubles reaches a round count; otherwise the
	# troubles are only named.
	var safe:=1
	for i in range(annals.size()-1,-1,-1):
		var m:Dictionary=annals[i]
		if int(m.get("crises",0))>0 and int(m.get("deaths",0))==0:safe+=1
		elif int(m.get("crises",0))==0:continue
		else:break
	var last:Dictionary=annals.back() if not annals.is_empty() else {}
	var text2:=""
	var w2:=2.0
	var it:="it" if told.size()==1 else "them"
	if int(last.get("deaths",0))>0:
		text2=say(ctx,"safe_after",["%s came and went, and this time no one died of %s." % [cap(came),it],"After last year's graves, %s passed without a death." % came,"This time %s took no one." % came]);w2=4.0
	elif safe>=5 and _round(safe):
		text2=say(ctx,"safe_run",["%s came; that is %s years of troubles now without a single death from them." % [cap(came),num(safe)],"No one died of %s, and no one has died of the year's troubles for %s years." % [came,num(safe)],"It is %s years since the year's troubles last killed anyone; %s passed like the rest." % [num(safe),came]]);w2=4.0
	elif String(last_sig.get("troubles",""))=="safe":
		text2=say(ctx,"safe_brief",["%s came %s." % [cap(came),"again" if _all_seen(told,annals) else "this year"],"This year it was %s." % came,"%s had its turn at the camp." % cap(came)]) if told.size()==1 else say(ctx,"safe_brief_many",["%s troubles came: %s." % [cap(num(ended.size())),came],"The year brought %s." % came])
		w2=1.5
	else:
		text2=say(ctx,"safe",["%s came and went without a death." % cap(came),"No one died of %s." % came,"%s passed, and everyone lived." % cap(came)])
	out.append({"t":"troubles","w":w2,"sig":"safe","text":text2})


static func _calm(a:Dictionary,annals:Array,ctx:Dictionary,out:Array,last_sig:Dictionary)->void:
	if annals.is_empty():return
	var quiet:=1
	for i in range(annals.size()-1,-1,-1):
		if int((annals[i] as Dictionary).get("crises",1))==0:quiet+=1
		else:break
	var best:=_longest_quiet(annals)
	var last:Dictionary=annals.back()
	if quiet==1 and int(last.get("deaths",0))>0:
		out.append({"t":"troubles","w":6.0,"sig":"calm","text":say(ctx,"calm_after",["After the graves of last year, no sickness, hunger, fire or flood came at all.","No trouble came this year, a year after %s had filled graves." % _lower_first(String(last.get("worst","the troubles"))),"This time no sickness, hunger or fire came; the year before had cost %s %s." % [num(int(last.get("deaths",0))),"life" if int(last.get("deaths",0))==1 else "lives"]])})
	elif quiet==1:
		var since:=_since(annals,func(m:Dictionary)->bool:return int(m.get("crises",1))==0)
		var gap:=y_of(a)-since if since>=0 else -1
		if gap>=4:out.append({"t":"troubles","w":5.0,"sig":"calm","text":say(ctx,"calm_first",["It was the first year without sickness, hunger or fire since year %d." % (since+1),"For the first time since year %d, no trouble came to the camp." % (since+1),"No trouble came at all, which had not happened since year %d." % (since+1)])})
		elif String(last_sig.get("troubles",""))!="calm":out.append({"t":"troubles","w":2.0,"sig":"calm","text":say(ctx,"calm",["No sickness, hunger, fire or flood came this year.","It was a year without sickness, hunger or fire.","The fevers, the dry sky and the fire all kept away this year."])})
	elif quiet>best and quiet>=3:
		out.append({"t":"troubles","w":7.0,"sig":"calm","text":say(ctx,"calm_record",["That makes %s years in a row without sickness, hunger or fire, the longest such time since the founding." % num(quiet),"No stretch since the founding has been so free of trouble: %s years now." % num(quiet)])})
	elif _round(quiet):
		out.append({"t":"troubles","w":4.0,"sig":"calm","text":say(ctx,"calm_run",["It was the %s year in a row without sickness, hunger or fire." % ordinal(quiet),"%s years now without sickness, hunger or fire." % cap(num(quiet))])})


static func _all_seen(names:PackedStringArray,annals:Array)->bool:
	for n in names:
		var seen:=false
		for m in annals:
			if String((m as Dictionary).get("worst",""))==n or ((m as Dictionary).get("kinds",[]) as Array).has(n):seen=true
		if not seen:return false
	return true


static func y_of(a:Dictionary)->int:
	return int(a.get("year",0))


## The most recent earlier year (0-based) whose record satisfies `test`, or -1.
static func _since(annals:Array,test:Callable)->int:
	for i in range(annals.size()-1,-1,-1):
		var m:Dictionary=annals[i]
		if test.call(m):return int(m.get("y",-1))
	return -1


static func _longest_quiet(annals:Array)->int:
	var best:=0;var run:=0
	for m in annals:
		if int((m as Dictionary).get("crises",1))==0:run+=1;best=maxi(best,run)
		else:run=0
	return best


static func _god(a:Dictionary,annals:Array,ctx:Dictionary,out:Array,last_sig:Dictionary)->void:
	var crises:Array=a.get("crises",[])
	var silent:=0;var answered:=0
	var holders:PackedStringArray=[]
	for cr in crises:
		if not bool(cr.get("ended",true)):continue
		if bool(cr.get("silent",false)):
			silent+=1
			if String(cr.get("holder",""))!="" and not holders.has(String(cr.holder)):holders.append(String(cr.holder))
		else:answered+=1
	var who:=list(Array(holders)) if not holders.is_empty() else "the court"
	if silent>0 and answered==0:
		var years:=1
		for i in range(annals.size()-1,-1,-1):
			var m:Dictionary=annals[i]
			if int(m.get("crises",0))==0:continue
			if int(m.get("silent",0))>0 and int(m.get("answered",0))==0:years+=1
			else:break
		var last_holders:=String(last_sig.get("decider",""))
		if years==1:
			out.append({"t":"god","w":4.0 if annals.size()>=1 else 2.0,"sig":"silent","text":say(ctx,"silent_first",["The god kept silent, and %s decided." % who,"%s decided; the god said nothing." % cap(who),"The god gave no word, and %s chose the course." % who])})
		elif years>=5 and years%5==0:
			out.append({"t":"god","w":4.5,"sig":"silent","text":say(ctx,"silent_run",["In %s years of troubles the god has not answered once; this year %s decided." % [num(years),who],"For the %s year the god kept silent through every trouble, and %s decided." % [ordinal(years),who],
				"%s years now the court has met every trouble without a word from the god; this year it was %s." % [cap(num(years)),who],"Still no word came from the god in trouble, as for %s years before; %s decided." % [num(years-1),who]])})
		elif last_holders!="" and last_holders!=String(";".join(holders)) and not holders.is_empty():
			out.append({"t":"god","w":2.5,"sig":"silent","text":say(ctx,"silent_new",["With the god still silent, the choosing fell to %s." % who,"It was %s who decided this year; the god still said nothing." % who])})
		ctx["decider"]=";".join(holders)
	elif answered>0 and silent>0:
		out.append({"t":"god","w":4.0,"sig":"mixed","text":say(ctx,"mixed",["The god answered %s and left %s to the court." % [_times(answered),_times(silent)],"Some troubles the god answered; %s it left to %s." % ["one" if silent==1 else num(silent),who]])})
	elif answered>0:
		var quiet_run:=0
		for i in range(annals.size()-1,-1,-1):
			var m:Dictionary=annals[i]
			if int(m.get("crises",0))==0:continue
			if int(m.get("answered",0))==0 and int(m.get("silent",0))>0:quiet_run+=1
			else:break
		if quiet_run>=2:out.append({"t":"god","w":8.0,"sig":"answered","text":say(ctx,"answered_after",["When trouble came, the god answered, for the first time in %s years of troubles." % num(quiet_run+1),"After %s years of silence through every trouble, the god spoke." % num(quiet_run)])})
		elif String(last_sig.get("god",""))!="answered":out.append({"t":"god","w":3.0,"sig":"answered","text":say(ctx,"answered",["When trouble came to the court, the god answered.","The god gave its word in the year's trouble."])})
	for line in ctx.get("divine",[]):out.append({"t":"divine","w":8.0,"sig":"","text":String(line)})
	var regard:=String(ctx.get("regard",""))
	if regard!="" and not annals.is_empty():
		var before:=String((annals.back() as Dictionary).get("regard",""))
		if before!="" and before!=regard:
			out.append({"t":"regard","w":7.5,"sig":"","text":say(ctx,"regard",["By the year's end people %s; a year before they would %s." % [String(REGARD_WORDS.get(regard,"")),String(REGARD_WORDS.get(before,""))],
				"Something changed in how people talk of the god: they %s now, where a year ago they would %s." % [String(REGARD_WORDS.get(regard,"")),String(REGARD_WORDS.get(before,""))]])})


static func _times(n:int)->String:
	return ["no times","once","twice"][n] if n<3 else "%s times" % num(n)


static func _dead(a:Dictionary,annals:Array,ctx:Dictionary,out:Array)->void:
	var deaths:Array=a.get("deaths",[])
	if not deaths.is_empty():
		var oldest:=0
		for m in annals:oldest=maxi(oldest,int((m as Dictionary).get("oldest",0)))
		var told:PackedStringArray=[]
		var record_age:=""
		var roles:=false
		for d in deaths.slice(0,3):
			var name:=String(d.get("name",""))
			var age:=int(d.get("age",0))
			var role:=String(d.get("role",""))
			var bit:=name
			if role!="":
				roles=true
				bit="%s, %s" % [name,role if role.begins_with("one who") else "the "+role]
			if age>0 and deaths.size()>1:bit+=" (%d)" % age
			told.append(bit)
			if age>oldest and oldest>0 and annals.size()>=5 and record_age=="":record_age=name.get_slice(" ",0)
		var more:=" and %s others the people knew" % num(deaths.size()-3) if deaths.size()>3 else ""
		var great:=false
		for d in deaths:if bool(d.get("great",false)):great=true
		var text:=""
		if deaths.size()==1:
			var age1:=int(deaths[0].get("age",0))
			var comma:="," if roles else ""
			text=say(ctx,"dead_one",["%s%s died this year%s." % [told[0],comma," at %d" % age1 if age1>0 else ""],
				"The people buried %s%s." % [told[0],(", who was %d" % age1) if age1>0 else ""],
				"This year the people lost %s%s." % [told[0],(", at %d" % age1) if age1>0 else ""]])
		elif roles:text=say(ctx,"dead_roles",["Died this year: %s%s." % ["; ".join(told),more],"The year's dead: %s%s." % ["; ".join(told),more]])
		else:text=say(ctx,"dead_many",["Died this year: %s%s." % ["; ".join(told),more],"The people buried %s%s." % [list(Array(told)),more],"%s died this year%s." % [list(Array(told)),more]])
		if record_age!="":text+=" "+say(ctx,"oldest",["No one the people had buried before had lived so long as %s." % record_age,"%s was the oldest of the people to die since the founding." % record_age])
		out.append({"t":"dead","w":6.0+(3.0 if great else 0.0)+(1.0 if record_age!="" else 0.0),"sig":"","text":text})
	var heads:Array=a.get("heads",[])
	if not heads.is_empty():
		var count:=0
		for m in annals:count+=((m as Dictionary).get("heads",[]) as Array).size()
		var n:=count+heads.size()
		var text2:=""
		if heads.size()==1:
			text2=say(ctx,"head",["%s now keeps the fire%s." % [String(heads[0]),", the %s to keep it since the founding" % ordinal(n+1) if n+1<ORDINALS.size() and count>0 else ""],
				"The fire passed to %s%s." % [String(heads[0]),", the %s to hold it" % ordinal(n+1) if n+1<ORDINALS.size() and count>0 else ""]])
		else:text2="%s kept the fire in turn this year." % list(heads)
		out.append({"t":"heads","w":6.5,"sig":"","text":text2})
	var births:Array=a.get("births",[])
	for b in births.slice(0,2):out.append({"t":"births","w":5.0,"sig":"","text":String(b)})
	for f in a.get("figures",[]).slice(0,2):out.append({"t":"figures","w":4.0,"sig":"","text":String(f)})


static func _learning(a:Dictionary,annals:Array,ctx:Dictionary,out:Array,last_sig:Dictionary)->void:
	var turnings:Array=a.get("turnings",[])
	for t in turnings.slice(0,2):
		var tt:Dictionary=t
		var title:=_lower_first(String(tt.get("title","")))
		var line:=String(tt.get("text",""))
		out.append({"t":"turning","w":7.0,"sig":"","text":say(ctx,"turning",["It was the year of %s. %s" % [title,line],"%s: %s" % [cap(title),line],"This was when %s came. %s" % [title,line]]).strip_edges()})
	var learned:Array=a.get("learned",[])
	var n:=learned.size()
	if n>0:
		var most:=0
		for m in annals:most=maxi(most,int((m as Dictionary).get("learned",0)))
		var pick:Dictionary=ctx.get("change",{}) if ctx.get("change") is Dictionary else {}
		var who:="the keepers recorded" if String(ctx.get("era",""))=="annals" else "the people learned"
		var text:=""
		if not pick.is_empty() and turnings.is_empty():
			var name:=String(pick.get("name","")).to_lower()
			var how:=String(EFFECT_WORDS.get(String(pick.get("effect","")),""))
			if how=="":text=say(ctx,"change_plain",["%s came into use." % cap(name),"This year the people took up %s." % name])
			else:text=say(ctx,"change",["%s came into use, and %s." % [cap(name),how],"This year the people took up %s, and %s." % [name,how],"With %s, %s." % [name,how],"Of all the new ways, %s mattered most: %s." % [name,how]])
		else:
			# Named only in words the people have (a name can run ahead of them).
			var sayable:Array=ctx.get("sayable",learned) if ctx.get("sayable") is Array else learned
			if sayable.is_empty():text=say(ctx,"learned_count",["%s %s new %s." % [cap(who),num(n),"way" if n==1 else "ways"],"%s new %s came into use." % [cap(num(n)),"way" if n==1 else "ways"]])
			elif n<=3 and sayable.size()==n:text=say(ctx,"learned_few",["%s %s." % [cap(who),list(_lowered(sayable))],"New this year: %s." % list(_lowered(sayable))])
			else:text=say(ctx,"learned_many",["%s %s new ways, among them %s." % [cap(who),num(n),list(_lowered(sayable.slice(0,2)))],"%s new ways were learned, %s among them." % [cap(num(n)),list(_lowered(sayable.slice(0,2)))]])
		var w:=3.0 if not pick.is_empty() else 2.0
		if n>most and annals.size()>=3 and n>=3:text+=" "+say(ctx,"learned_record",["No year before had taught so much: %s new ways." % num(n),"%s new ways in one year, more than ever before." % cap(num(n))]);w+=3.0
		elif annals.size()>=10:
			var since:=_since(annals,func(m:Dictionary)->bool:return int(m.get("learned",0))>=n)
			if since>=0 and y_of(a)-since>=10 and n>=3:text+=" "+say(ctx,"learned_since",["Not since year %d had so much been learned in one year." % (since+1),"%s new ways in one year; the last year to match it was year %d." % [cap(num(n)),since+1]]);w+=2.0
		out.append({"t":"learned","w":w,"sig":"learned","text":text})
	else:
		var dry:=1
		for i in range(annals.size()-1,-1,-1):
			if int((annals[i] as Dictionary).get("learned",1))==0:dry+=1
			else:break
		if dry==1 and annals.size()>=3 and int((annals.back() as Dictionary).get("learned",0))>=3:out.append({"t":"learned","w":2.5,"sig":"dry","text":say(ctx,"dry",["Nothing new was learned this year.","No new way was found this year."])})
		elif _round(dry):out.append({"t":"learned","w":3.0,"sig":"dry","text":"Nothing new was learned, for the %s year running." % ordinal(dry)})


static func _lowered(names:Array)->Array:
	var out:Array=[]
	for n in names:out.append(String(n).to_lower())
	return out


## Word of other peoples. The same word (a vow, a famine) told within
## ABROAD_YEARS is not told again; of one people's vow only the furthest step
## this year is told.
const ABROAD_YEARS:=8
const VOW_RANK:={"known":1,"warn":2,"heir":2,"fulfilled":3}
static func _abroad(a:Dictionary,annals:Array,ctx:Dictionary,out:Array)->void:
	var before:={}
	for m in annals.slice(maxi(0,annals.size()-ABROAD_YEARS)):
		for s in (m as Dictionary).get("abroad",[]):before[String(s)]=true
	var best_vow:={}
	for item in a.get("abroad",[]):
		var sig:=String((item as Dictionary).get("sig",""))
		if not sig.begins_with("vow:"):continue
		var parts:=sig.split(":")
		var civ:=parts[2] if parts.size()>2 else ""
		var rank:=int(VOW_RANK.get(parts[1] if parts.size()>1 else "",1))
		if rank>int((best_vow.get(civ,{"r":0}) as Dictionary).r):best_vow[civ]={"r":rank,"sig":sig}
	var seen:={}
	var told:=0
	for item in a.get("abroad",[]):
		var it:Dictionary=item
		var sig:=String(it.get("sig",""))
		if sig.begins_with("vow:"):
			var civ:=sig.split(":")[2] if sig.split(":").size()>2 else ""
			if String((best_vow.get(civ,{}) as Dictionary).get("sig",""))!=sig:continue
		if sig!="" and (seen.has(sig) or before.has(sig)):continue
		seen[sig]=true
		told+=1
		if told>2:break
		out.append({"t":"abroad","w":float(it.get("w",4.0)),"sig":"","asig":sig,"text":String(it.get("text",""))})
	for line in (a.get("envoys",[]) as Array).slice(0,2):out.append({"t":"envoy","w":5.0,"sig":"","text":String(line)})
	var contacts:Array=a.get("contacts",[])
	for t in contacts.slice(0,2):
		var s:=String(t)
		if s.ends_with(" Is Dead"):out.append({"t":"abroad","w":4.0,"sig":"","text":"Word came that %s had died." % s.trim_suffix(" Is Dead")})
		elif ": " in s:out.append({"t":"contact","w":8.0,"sig":"","text":say(ctx,"contact",["The %s came into the people's knowing." % s.get_slice(": ",1),"This was the year the people first knew of the %s." % s.get_slice(": ",1)])})
		else:out.append({"t":"contact","w":7.0,"sig":"","text":"It was the year of %s." % _lower_first(s.trim_suffix(".")).to_lower()})
	for w in (a.get("wars",[]) as Array).slice(0,2):out.append({"t":"war","w":7.0,"sig":"","text":"%s." % String(w).trim_suffix(".")})


static func _people(a:Dictionary,annals:Array,ctx:Dictionary,out:Array,last_sig:Dictionary)->void:
	var pop:=int(ctx.get("pop",0))
	var pop0:=int(a.get("pop0",0))
	if pop<=0 or pop0<=0:return
	var delta:=pop-pop0
	var born:=int(a.get("born",0));var buried:=int(a.get("buried",0))
	var peak:=0
	for m in annals:peak=maxi(peak,int((m as Dictionary).get("pop",0)))
	var tally:=String(ctx.get("era",""))!="annals"
	var count:=("%d souls at the hearths" if tally else "%d people in the registers") % pop
	var falls:=0
	for i in range(annals.size()-1,-1,-1):
		var p1:=int((annals[i] as Dictionary).get("pop",0))
		var p0:=int((annals[i-1] as Dictionary).get("pop",0)) if i>0 else 0
		if p0>0 and p1<p0:falls+=1
		else:break
	var births:=" (%s born, %s buried)" % [num(born),num(buried)] if born+buried>0 else ""
	var big:=absi(delta)>=maxi(5,pop0/20)
	if pop>peak and peak>0 and delta>0:
		out.append({"t":"people","w":5.0,"sig":"pop+","text":say(ctx,"pop_peak",["%s, more than ever before%s." % [cap(count),births],"The hearths held more people than ever: %d%s." % [pop,births]])})
	elif delta>0 and falls>=2:
		out.append({"t":"people","w":5.0,"sig":"pop+","text":"%s, the first rise in %s years%s." % [cap(count),num(falls+1),births]})
	elif delta<0 and big:
		out.append({"t":"people","w":5.5,"sig":"pop-","text":say(ctx,"pop_fall",["%s, %d fewer than a year before%s." % [cap(count),-delta,births],"The people were %d fewer at the year's end: %d%s." % [-delta,pop,births]])})
	elif delta>0 and big:
		out.append({"t":"people","w":4.0,"sig":"pop+","text":"%s, %d more than a year before%s." % [cap(count),delta,births]})
	elif born>=buried*2+3:
		out.append({"t":"people","w":3.5,"sig":"births","text":say(ctx,"births",["Children came often this year: %s born against %s buried." % [num(born),num(buried)],"It was a year of births: %s, and %s buried." % [num(born),num(buried)]])})
	elif buried>=born+3:
		out.append({"t":"people","w":3.5,"sig":"burials","text":"There were more graves than births: %s buried, %s born." % [num(buried),num(born)]})
	elif delta!=0 and String(last_sig.get("people",""))=="" and annals.size()>=1:
		out.append({"t":"people","w":1.0,"sig":"pop~","text":"%s at the year's end%s." % [cap(count),births]})


static func _aims_and_works(a:Dictionary,ctx:Dictionary,out:Array)->void:
	for aim in a.get("aims",[]):
		var name:=String(aim.get("name",""))
		var to:=String(aim.get("phrase",""))
		if to=="":to=aim_words(name)
		var short:=short_aim(to)
		match String(aim.get("kind","")):
			"done":
				var legacy:=_lower_first(name)
				out.append({"t":"aim","w":8.0,"sig":"","text":say(ctx,"aim_done",["The people kept their aim, to %s; they call it %s." % [short,legacy],"The aim to %s was kept, and the people call it %s." % [short,legacy],"The people did what they had set out to do, and will remember it as %s." % legacy])})
			"fail":out.append({"t":"aim","w":6.0,"sig":"","text":say(ctx,"aim_fail",["The aim to %s ran out of winters unmet." % short,"The winters ran out before the people could %s." % short])})
			"start":out.append({"t":"aim","w":4.5,"sig":"","text":say(ctx,"aim_start",["The people set themselves to %s." % to,"A new aim was taken up: to %s." % to])})
	for work in a.get("works",[]):out.append({"t":"work","w":8.0,"sig":"","text":say(ctx,"work",["%s was finished." % String(work),"The builders finished %s." % _lower_first(String(work))])})


## An aim's title as the words of a sentence: "Master The Sky and the Counting
## of Days" -> "master the sky and the counting of days". Names keep their
## capitals.
const AIM_COMMON:=["be","souls","again","let","our","hearths","hold","no","child","hungry","for","cross","great","river","master","learn","new","ways","in","sit","at","the","fire","fires",
	"of","walk","farther","than","any","us","has","walked","make","fear","name","bind","to","friendship","found","a","daughter","hearth","raise","cairn","ring","standing","stones","keep",
	"one","and","winters","winter","making","things","healing","sky","counting","days","building","water","food","farming","foraging","carrying","crossing","people","homes","health","care",
	"work","tools","learning","records","craft","travel","land","seasons","custom","law","watch","war","song","exchange","wealth","two","three","four","five","six","seven","eight",
	"nine","ten","eleven","twelve","god's","yield","them","spread","their","hunting","grounds","outnumber"]
static func aim_words(title:String)->String:
	var words:=title.strip_edges().split(" ",false)
	for i in words.size():
		if AIM_COMMON.has(words[i].to_lower()):words[i]=words[i].to_lower()
	return third_person(" ".join(words))


## The heart of an aim, without its reasons or its reckoning of winters:
## "bind the Ildor to us, so that ..." -> "bind the Ildor to us".
static func short_aim(to:String)->String:
	var out:=to
	for cut in [", "," before "," through "," until "]:
		var at:=out.find(cut)
		if at>8:out=out.substr(0,at)
	return out


## The people's own "our", told by the keeper of the annals: "their".
static func third_person(text:String)->String:
	return RegEx.create_from_string("\\bour\\b").sub(RegEx.create_from_string("\\bOur\\b").sub(text,"Their",true),"their",true)


static func _roads(a:Dictionary,annals:Array,ctx:Dictionary,out:Array)->void:
	var sc:Dictionary=a.get("scouts",{})
	if int(sc.get("n",0))<=0:return
	var km:=int(sc.get("km",0))
	var far:=0
	for m in annals:far=maxi(far,int((m as Dictionary).get("km",0)))
	var hard:PackedStringArray=[]
	if int(sc.get("hurt",0))>0:hard.append("%s hurt and carried home" % ("one was" if int(sc.hurt)==1 else "%s were" % num(int(sc.hurt))))
	if int(sc.get("back",0))>0:hard.append("%s turned back by sickness or hard going" % ("one party" if int(sc.back)==1 else "%s parties" % num(int(sc.back))))
	var road:=say(ctx,"road",["Scouts went out %s and walked some %s km" % [_times(int(sc.n)),_grouped(km)],"The scouts walked some %s km on %s" % [_grouped(km),"one journey" if int(sc.n)==1 else "%s journeys" % num(int(sc.n))]])
	var w:=1.0
	# A longer year on the roads is news only when it clearly beats the best.
	if far>0 and annals.size()>=3 and float(km)>float(far)*1.2:road+=", farther than in any year before";w=4.0
	if not hard.is_empty():road+="; "+" and ".join(hard);w=maxf(w,2.5)
	out.append({"t":"roads","w":w,"sig":"","text":road+"."})


static func _grouped(value:int)->String:
	var digits:=str(value)
	var out:=""
	for i in digits.length():
		if i>0 and (digits.length()-i)%3==0:out+=","
		out+=digits[i]
	return out


## Orders and trims the year's lines. Returns {lines, sig, abroad}.
static func entry(all:Array)->Dictionary:
	var order:Array=all.duplicate()
	for i in order.size():(order[i] as Dictionary)["i"]=i
	order.sort_custom(func(x:Dictionary,z:Dictionary)->bool:return float(x.w)>float(z.w) or (float(x.w)==float(z.w) and int(x.i)<int(z.i)))
	var lines:PackedStringArray=[]
	var sig:={}
	var abroad:Array=[]
	var budget:=MAX_LINES
	for item in order:
		var it:Dictionary=item
		if String(it.get("text","")).strip_edges()=="":continue
		# The lightest lines fill a thin year only.
		if float(it.w)<2.0 and lines.size()>=2:continue
		if lines.size()>=budget:break
		var said:=cap(one_people(String(it.text).strip_edges()))
		if technical(said)!="":continue
		lines.append(said)
		if String(it.get("sig",""))!="":sig[String(it.t)]=String(it.sig)
		if String(it.get("asig",""))!="":abroad.append(String(it.asig))
	return {"lines":lines,"sig":sig,"abroad":abroad}


## "Hoya of Windgap of the Ildor" -> "the Ildor's Hoya of Windgap".
static func one_people(text:String)->String:
	var re:=RegEx.create_from_string("\\b([A-Z][\\w'\\-]*) of ([A-Z][\\w'\\-]*(?: [A-Z][\\w'\\-]*)?) of (?:the )?([A-Z][\\w'\\-]*)")
	return re.sub(text,"the $3's $1 of $2",true)


## Words of research papers, not of people at a fire. Returns the first one
## found, or "".
const TECHNICAL:=["reproduce","reproducible","managed","manage","cultures","temperature","repeatable","systematic","efficiency","efficient","process","processes","consistently",
	"coordinated","coordination","capacity","optimal","structural","separation","treatment","enclosed","chambers","residue","reactive","sustained","quantities",
	"regulate","regulated","standardized","methodical","variables","output","technique","techniques","mechanism","durable","permanently"]
static func technical(text:String)->String:
	var re:=RegEx.create_from_string("[A-Za-z']+")
	for m in re.search_all(text.to_lower()):
		if TECHNICAL.has(m.get_string()):return m.get_string()
	return ""


# --- A generation ---------------------------------------------------------------

## True when the year just closed (0-based) ends a generation worth telling.
static func age_due(y:int,annals:Array)->bool:
	return (y+1)%GENERATION_YEARS==0 and annals.size()>=GENERATION_YEARS/2


## The account of the GENERATION_YEARS ending with year `y`. `annals` holds
## the years' records, the closed year included. Returns {title, text} or {}.
static func age(y:int,annals:Array,seed:int)->Dictionary:
	var span:Array=[]
	var before:Array=[]
	for m in annals:
		var yy:=int((m as Dictionary).get("y",-1))
		if yy>y-GENERATION_YEARS and yy<=y:span.append(m)
		elif yy>y-2*GENERATION_YEARS and yy<=y-GENERATION_YEARS:before.append(m)
	if span.size()<GENERATION_YEARS/2:return {}
	var first:=int((span[0] as Dictionary).get("y",0))+1
	var lines:PackedStringArray=[]
	# Who kept the fire.
	var heads:Array=[]
	for m in span:for h in (m as Dictionary).get("heads",[]):if not heads.has(String(h)):heads.append(String(h))
	var keeper:=""
	var start_keeper:=""
	for i in range(annals.size()-1,-1,-1):
		var m:Dictionary=annals[i]
		if int(m.get("y",0))<=y-GENERATION_YEARS and not (m.get("heads",[]) as Array).is_empty():start_keeper=String((m.heads as Array).back());break
	if heads.size()>=2:
		var from:="from %s " % start_keeper if start_keeper!="" and not heads.has(start_keeper) else ""
		var to:=("to "+", then to ".join(PackedStringArray(heads))) if heads.size()<=4 else "through %s hands" % num(heads.size())
		lines.append("The fire passed %s%s." % [from,to])
	elif heads.size()==1:lines.append("%s took the fire%s and kept it." % [String(heads[0])," from %s" % start_keeper if start_keeper!="" else ""])
	elif start_keeper!="":lines.append("%s kept the fire all these years." % start_keeper)
	if heads.size()>=1:keeper=String(heads[0]) if heads.size()==1 else ""
	# The count of the people.
	var p0:=0;var p1:=0
	for m in span:
		var p:=int((m as Dictionary).get("pop",0))
		if p>0:
			if p0==0:p0=p
			p1=p
	if p0>0 and p1>0 and p0!=p1:lines.append("The hearths went from %d souls to %d." % [p0,p1])
	# Troubles and their cost, against the generation before.
	var cr:=0;var dead:=0;var silent:=0;var answered:=0;var calm:=0
	var worst:Dictionary={}
	for m in span:
		var mm:Dictionary=m
		cr+=int(mm.get("crises",0));dead+=int(mm.get("deaths",0));silent+=int(mm.get("silent",0));answered+=int(mm.get("answered",0))
		if int(mm.get("crises",0))==0:calm+=1
		if int(mm.get("deaths",0))>0 and (worst.is_empty() or int(mm.deaths)>int(worst.deaths)):worst=mm
	var cr0:=0;var dead0:=0
	for m in before:cr0+=int((m as Dictionary).get("crises",0));dead0+=int((m as Dictionary).get("deaths",0))
	if cr>0:
		var cost:="no one died of them" if dead==0 else ("they took %d lives" % dead)
		var then:=""
		if before.size()>=GENERATION_YEARS/2:
			if dead<dead0:then=", fewer than the %d of the twenty years before" % dead0
			elif dead>dead0:then=", more than the %d of the twenty years before" % dead0
		lines.append("%d troubles came in these years, and %s%s." % [cr,cost,then])
		if not worst.is_empty() and int(worst.deaths)>=2:lines.append("The worst was %s, in year %d." % [_lower_first(String(worst.get("worst",worst.get("name","the troubles")))),int(worst.y)+1])
		if calm>=3:lines.append("%s years passed with no trouble at all." % cap(num(calm)))
	if silent+answered>0:
		if answered==0:lines.append("The god did not answer once; the court met every trouble alone.")
		elif silent==0:lines.append("The god answered every trouble the court brought.")
		else:lines.append("The god answered %s of them and left %s to the court." % [num(answered),num(silent)])
	# What changed their days, what they swore and kept, whom they met.
	var turns:Array=[];var kept:Array=[];var unmet:Array=[];var met:Array=[];var works:Array=[];var lost:Array=[]
	var learned:=0
	for m in span:
		var mm:Dictionary=m
		learned+=int(mm.get("learned",0))
		for t in mm.get("turns",[]):turns.append(_lower_first(String(t)))
		for t in mm.get("kept",[]):kept.append(String(t))
		for t in mm.get("unmet",[]):unmet.append(String(t))
		for t in mm.get("met",[]):met.append(String(t))
		for t in mm.get("works",[]):works.append(String(t))
		for t in mm.get("lost",[]):lost.append(String(t))
	if not turns.is_empty():lines.append("These were the years of %s." % list(turns.slice(0,4)))
	elif learned>0:lines.append("They learned %d new ways." % learned)
	if kept.size()==1:lines.append("One aim was kept, remembered as %s." % _lower_first(String(kept[0])))
	elif kept.size()>1:lines.append("%s aims were kept, remembered as %s." % [cap(num(kept.size())),list(_lowered_articles(kept.slice(0,3)))])
	if unmet.size()==1:lines.append("They set out to %s, and the winters ran out first." % short_aim(String(unmet[0])))
	elif unmet.size()>1:lines.append("%s aims ran out of winters unmet, among them to %s." % [cap(num(unmet.size())),short_aim(String(unmet[0]))])
	if not works.is_empty():lines.append("They finished %s." % list(_lowered_articles(works.slice(0,3))))
	if not met.is_empty():lines.append("They came to know the %s." % list(met.slice(0,3)))
	if not lost.is_empty():lines.append("Of those the people remember, %s died." % list(lost.slice(0,4)))
	if lines.size()<3:return {}
	var title:=""
	if keeper!="":title="The generation of %s" % keeper
	elif not turns.is_empty():title="The years of %s" % String(turns[0])
	else:title="Twenty years, from year %d to year %d" % [first,y+1]
	var text:=one_people(" ".join(lines))
	if text.length()>900:text=text.left(897)+"..."
	return {"title":cap(title),"text":text}


static func _lowered_articles(items:Array)->Array:
	var out:Array=[]
	for i in items:out.append(_lower_first(String(i)))
	return out


# --- Envoys ---------------------------------------------------------------------

## One line for an envoy's business and the god's answer, from the kept facts
## of an answer (envoy_requests.gd answers: {t,o,x,k}). "" when not tellable.
static func envoy_line(civ_name:String,answer:Dictionary)->String:
	var key:="%s:%s" % [String(answer.get("t","")),String(answer.get("o",""))]
	var template:=String(ENVOY_WORDS.get(key,ENVOY_WORDS.get("%s:%s" % [String(answer.get("k","")),String(answer.get("o",""))],"")))
	if template=="" or civ_name=="":return ""
	var x:Dictionary=answer.get("x",{}) if answer.get("x") is Dictionary else {}
	var the:=civ_name if civ_name.begins_with("the ") else "the "+civ_name
	var fill:={"civ":the,"Civ":cap(the)}
	for k in x:
		fill[String(k)]=str(x[k]).to_lower() if String(k) in ["res","resource","get_res","give_res","bres"] else str(x[k])
		fill[cap(String(k))]=cap(str(x[k]))
	var repaid:=String(x.get("repaid",""))
	fill["repaid"]=(", and paid it back" if repaid=="full" else (", and never paid it back" if repaid=="none" else ""))
	var text:=template
	for k in fill:text=text.replace("{%s}" % String(k),String(fill[k]))
	if "{" in text:return ""
	return text
