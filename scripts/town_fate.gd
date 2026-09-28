extends RefCounted
## WHAT BECOMES OF A TOWN WE HOLD.
##
## After a town is taken, the god's words about it are not a new attack.
## They are orders to the garrison that holds it, and the court is the only
## place they are given (the occupation screen now only reports). Each order
## goes through the occupation machinery that already exists, and every
## person it touches is counted in the town's one ledger (town_ledger.gd;
## docs/ADJUDICATION.md):
##   - how we rule it: civilization_system.set_occupation_policy (civil
##     administration, self-rule, equal citizenship, rule by the spear,
##     enslavement of the town), reconstruction;
##   - killing: civilization_system.occupation_resident_order kill_residents.
##     Those we hold (bound, at forced labour, serving, hostages) cannot run:
##     all of them die, and the garrison's hands set only how long it takes.
##     The free are each caught on the stated odds (catch_odds: our fighters
##     to their men, and what already holds them), one seeded roll each; the
##     rest run for their refuge (pursuit.gd offers a chase);
##   - moving people home, free or bonded, and captives:
##     military_campaign.occupation_transfers (they walk the road, eat
##     travel rations and arrive later, into their own community record);
##     each is rounded up on the stated odds; freeing captives already home:
##     occupation_transfers.emancipate;
##   - burning: the houses, stores and walls go and whoever is left free
##     scatters to their people's other towns (or the hills). The town becomes
##     our ruin, in the ledger and in the world: it is not handed back to its
##     old people. With a garrison left there it is ours to hold; when we
##     leave, nobody holds it, and whether its people come back to live in it
##     is its own event, with odds and a date (daily), told when our people
##     hear of it. Our own account of the burning (dated the day) replaces
##     any old scout report of the place;
##   - giving it back: occupation_resident_order restore_self_rule (the
##     garrison marches home);
##   - the garrison's size: military_campaign.reinforce_occupation from a band
##     standing at the town;
##   - tribute: their stores, through civilization_exchange.
##
## Every result is said with its numbers and how it was decided ("17 of ours
## against 38 bound men: none could run. All 38 were killed."). Consequences
## are real and bounded: dread and grudges reach the people who were struck
## and, more faintly, every people that knows us; our war reputation (mercy,
## fear, grievance) and our court's dread of the god move; one sober
## Chronicle entry tells it.
##
## apply() -> {ok, outcome (one plain note), text (the sober account),
##             killed, escaped, captives, moved, burned, tribute, left,
##             spared, policy, reinforced, freed, fled (the flight record)}
##             | {error}.

const Hall:=preload("res://scripts/audience_hall.gd")
const Chronicle:=preload("res://scripts/chronicle.gd")
const DIVINE:=preload("res://scripts/divine_regard.gd")
const Combat:=preload("res://scripts/civilization_combat.gd")
const Governance:=preload("res://scripts/occupation_governance.gd")
const Pursuit:=preload("res://scripts/pursuit.gd")
const Measures:=preload("res://scripts/occupation_measures.gd")
const Ledger:=preload("res://scripts/town_ledger.gd")
const WAR_LOOP_PATH:="res://scripts/war_loop.gd"

## Adult men in a farming village's population (the rest are women,
## children and the old): roughly a quarter.
const MEN_SHARE:=0.24
## The chance to catch each free man as a killing begins, with a garrison of
## about one fighter to three of their men (catch_odds moves it).
const CAUGHT_SHARE:=0.7
## Women and children in the population.
const WOMEN_CHILDREN_SHARE:=0.55
## The chance to round up each woman or child; the rest flee or hide.
const ROUNDED_UP_SHARE:=0.6
## What one fighter can do: kill the men who stand (a day's work), guard
## captives on the road.
const KILLS_PER_FIGHTER:=5
const CAPTIVES_PER_FIGHTER:=4
## Food a band carries off as tribute, per fighter.
const TRIBUTE_PER_FIGHTER:=40.0
## A ruin we burned and left: its people may come back to live in it between
## these many days after, and we hear of it some days later.
const RESETTLE_DAYS:=[60,300]
const LEARN_DAYS:=[10,60]
const RESETTLERS:=[10,60]

const POLICY_WORDS:=[
	["military_rule","\\b(military rule|rule [\\w' ]{0,20}by (the )?(spear|sword|force|fear)|by force of arms|under the spear|martial)"],
	["self_rule","\\b(govern (themselves|itself)|rule themselves|self.rule|their own elders|let them rule|keep their own (ways|elders|chief))"],
	["equal_citizenship","\\b(equal citizens|equal citizenship|make them (our own|our people|citizens|one of us)|full citizens|as equals)"],
	["stewardship","\\b(civil administration|(govern|rule) [\\w' ]{0,20}(well|fairly|justly|kindly)|as a town of ours|administer it|steward|protect (it|them|the town))"],
	["forced_labor","\\b(enslave (the |its |their )?(whole )?(town|people|them|everyone)|make (them|the town|its people) (our )?slaves|forced labou?r|work them as slaves)"],
]
## "Kill the men you have tied up": only those we hold.
const BOUND_ONLY:="\\b((that|whom|who|which)\\s+(you|we|they|your men|the garrison|our men|you've|we've)\\s+(have\\s+|had\\s+|already\\s+|just\\s+)*(tied|bound|chained|taken|captured|caught|rounded up|locked up|roped)|(the|all the|every one of the|those|these)\\s+(bound|tied|captive|chained|roped|captured)\\s+(men|ones|prisoners|males)|the prisoners|those (we|you) (hold|are holding|have tied|have bound)|(who|that) are (tied|bound|chained|held|prisoners|under guard))"

static func _re(pattern:String,text:String)->RegExMatch:
	var r:=RegEx.new(); r.compile(pattern); return r.search(text)

static func _has(pattern:String,text:String)->bool:
	return _re(pattern,text)!=null

static func fate_words(lower:String,home_name:String="")->Dictionary:
	## What the god's words decide about a town we hold. {} when nothing.
	var out:={}
	var home:=home_name.to_lower().strip_edges() if home_name!="" else String(WorldSimulation.state.settlement_name).to_lower() if WorldSimulation.state!=null else ""
	var kill:=_has("\\b(kill|slay|slaughter|massacre|butcher|execute|cut down|put [\\w' ]{0,24}to the sword|put [\\w' ]{0,24}to death|no quarter)",lower)
	var everyone:=_has("\\b(everyone|everybody|every soul|every one of them|all of them|them all|man, woman and child|men, women and children|women and children too|leave none|nobody alive|no one alive)\\b",lower)
	var people:=_has("\\b(women|womenfolk|females?|girls|wives|daughters|children|captives?|slaves?|bondservants?|young ones|people|residents|families|them|villagers|townsfolk|townspeople|inhabitants)\\b",lower)
	var carry:=_has("\\b(take|bring|carry|lead|drive|march|send|haul|herd|move|settle|resettle)\\b",lower)
	var homeward:=_has("\\b(home|back|with us|to our|captives?)\\b",lower) or (home!="" and home in lower)
	var bonded:=_has("\\b(women|womenfolk|females?|girls|wives|daughters|captives?|slaves?|bondservants?|bonded|as spoils)\\b",lower)
	var count_match:=_re("\\b(\\d{1,4})\\b",lower)
	if count_match!=null: out["count"]=int(count_match.get_string(1))
	if kill: out["kill_men"]=true
	if kill and everyone: out["kill_all"]=true
	# Who is to be killed: "kill the women" never kills the men.
	if kill and not everyone:
		var groups:=kill_groups(lower)
		if groups!=["men"]: out["kill_groups"]=groups
	if kill and _has(BOUND_ONLY,lower): out["bound_only"]=true
	if carry and people and homeward and not out.has("kill_all"):
		if _has("\\bas (our own|citizens|free|our people|equals|kin)\\b",lower) and not bonded: out["move"]="citizen"
		elif _has("\\b(penal|to labou?r|to work)\\b",lower) and not bonded: out["move"]="penal"
		else:
			out["captives"]=true
			out["take"]=take_words(lower)
	if _has("\\b(burn|raze|torch|set fire|to the ground|level it|flatten|tear [\\w' ]{0,12}down|destroy (it|the town|what))",lower): out["raze"]=true
	if _has("\\b(tribute|plunder|loot|sack it|take their (food|grain|stores|goods)|strip (it|the town|them|their stores))\\b",lower): out["tribute"]=true
	if _has("\\b(spare|mercy|merciful|leave them (be|in peace)|let them (be|live)|no harm|harm no one|treat them (well|kindly|gently)|be gentle)\\b",lower) and not kill: out["spare"]=true
	if _has("\\b(hold|keep|garrison|govern|rule) (it|the town|the place|them|the ruins?)\\b",lower): out["hold"]=true
	if _has("\\b(give it back|hand it back|(give|hand) [\\w' ]{1,20} back|return it|leave it|withdraw|come home|pull out|abandon|let them have it back)\\b",lower) and not out.has("hold"): out["leave"]=true
	if _has("\\b(rebuild|repair|reconstruct|build it (up|again))\\b",lower) and not out.has("raze"): out["reconstruct"]=true
	if _has("\\b(strengthen|reinforce|more (soldiers|fighters|men|spears) (to|in|at|for)|send more|add [\\w' ]{0,12}to the garrison|bigger garrison)\\b",lower): out["reinforce"]=true
	if _has("\\b(free|release|emancipate|unbind) (the )?(captives|slaves|bonded)",lower) and not kill: out["free"]=true
	if not out.has("captives"):
		for row in POLICY_WORDS:
			if _has(String(row[1]),lower): out["policy"]=String(row[0]); break
	if out.is_empty() or (out.size()==1 and out.has("count")): return {}
	if _has(GROUP_WORDS,lower): out["group"]=true
	return out

## The groups a killing names, from the words after the verb up to the next
## order ("kill the males and take the women" kills the men only). Default men.
const KILL_VERB:="\\b(kill|slay|slaughter|massacre|butcher|execute|cut down|put [\\w' ]{0,24}to the sword|put [\\w' ]{0,24}to death)"

static func kill_groups(lower:String)->Array:
	var m:=_re(KILL_VERB,lower)
	if m==null: return ["men"]
	var span:=lower.substr(m.get_start())
	var cut:=span.length()
	for stop in [" and take"," and bring"," and burn"," and carry"," and drive"," and lead"," and send"," and march"," then ",",",".",";","!"]:
		var at:=span.find(stop)
		if at>0 and at<cut: cut=at
	span=span.substr(0,cut).replace("old men","old ones")
	var out:Array=[]
	if _has("\\b(men|males|menfolk|husbands|fathers|sons|fighting men|grown men|every man)\\b",span): out.append("men")
	if _has("\\b(women|womenfolk|females?|wives|mothers)\\b",span): out.append("women")
	if _has("\\b(children|boys|girls|daughters|young ones|babies|infants)\\b",span): out.append("children")
	if _has("\\b(elders|old people|old ones|old women)\\b",span): out.append("elders")
	return out if not out.is_empty() else ["men"]

## Which people the words take: {group: share of the free}. "the women and
## girls" -> women 1, children 0.5 (the girls). Default: women and children.
static func take_words(lower:String)->Dictionary:
	var out:={}
	if _has("\\b(everyone|everybody|all of them|them all|the people|its people|their people|villagers|townsfolk|townspeople|inhabitants|residents|families)\\b",lower):
		return {"men":1.0,"women":1.0,"children":1.0,"elders":1.0}
	if _has("\\b(women|womenfolk|wives|females?|mothers)\\b",lower): out["women"]=1.0
	var girls:=_has("\\b(girls|daughters)\\b",lower)
	var boys:=_has("\\b(boys)\\b",lower)
	if _has("\\b(children|young ones|little ones|babies|infants)\\b",lower) or (girls and boys): out["children"]=1.0
	elif girls or boys: out["children"]=0.5
	if _has("\\b(elders|old people|old men|old women|old ones)\\b",lower): out["elders"]=1.0
	if _has("\\b(men|males|menfolk|husbands|fathers|sons)\\b",lower.replace("old men","old ones")) and not _has("\\b(kill|slay|put [\\w' ]{0,24}to (the sword|death))",lower): out["men"]=1.0
	if out.is_empty(): out={"women":1.0,"children":1.0}
	return out


## Words for the people of a town as a body: the men, the women, everyone.
## An order that names no town is about a town only when it names them.
const GROUP_WORDS:="\\b(males?|men|menfolk|boys|sons|fighting men|grown men|every man|females?|women|womenfolk|girls|wives|daughters|children|everyone|everybody|every soul|all of them|them all|villagers|townsfolk|townspeople|inhabitants|residents|population|families|captives|its people|their people|the people)\\b"
## Words that point at a town without naming it.
const TOWN_REF:="\\b((the|that|this|their|our new|the captured|the taken|the conquered) (town|village|city|settlement|capital|place|stronghold)|the garrison|the captives)\\b"

static func implicit(fate:Dictionary,lower:String)->bool:
	## Is this fate order about a town we hold even though it names none?
	## Violence to, or carrying off of, the people as a body; freeing its
	## captives; or any other fate (burn, tribute, rule, give back) with words
	## pointing at the town. "Kill him" and "take them home" never are.
	if fate.is_empty(): return false
	var group:=bool(fate.get("group",false))
	if group and (bool(fate.get("kill_men",false)) or bool(fate.get("captives",false)) or String(fate.get("move",""))!="" or bool(fate.get("free",false))): return true
	return _has(TOWN_REF,lower)


static func apply(civ_id:String,region_id:String,fate:Dictionary,general:Dictionary={})->Dictionary:
	var world:Variant=WorldSimulation.world
	var mc:Variant=WorldSimulation.military
	if world==null or mc==null: return {"error":"Nobody holds that town for us."}
	var index:int=world._civilization_index(civ_id)
	if index<0: return {"error":"That town's people are no longer known to us."}
	var region:Dictionary=world.region_snapshot(civ_id,region_id)
	if region.is_empty() or String(region.get("controller",""))!="player": return {"error":"We do not hold that town."}
	var garrison:=int(mc.occupation_force_for_region(civ_id,region_id).get("troops",0))
	if garrison<=0: return {"error":"Nobody of ours is left in the town to carry out the order."}
	var name:=String(region.get("name","the town"))
	var home:=String(WorldSimulation.state.settlement_name)
	var day:=int(WorldSimulation.state.elapsed_days)
	# The town's one ledger of its people: every step below reads it afresh
	# and writes it before the world's own count changes (town_ledger.gd).
	var out:={"ok":true,"town":name,"garrison":garrison,"killed":0,"escaped":0,"captives":0,"moved":0,"move_status":"","burned":false,"tribute":0,"left":false,"spared":false,"policy":"","reinforced":0,"freed":0,"arrive_days":0,"fled":{}}
	var parts:PackedStringArray=PackedStringArray()
	var refusals:PackedStringArray=PackedStringArray()
	var harsh:=0.0
	# Strengthen the garrison from a band standing at the town.
	if bool(fate.get("reinforce",false)):
		var before:=garrison
		# The rebuilt garrison record keeps what this garrison is doing and
		# what it did (measures in force, the card note, the totals).
		var kept:={}
		var at_before:int=mc._occupation_force_index(civ_id,region_id)
		if at_before>=0:
			for key in ["measures","measure_note","note_before","fate","fate_note"]:
				if mc.occupation_forces[at_before].has(key): kept[key]=mc.occupation_forces[at_before][key]
		var more:Dictionary=mc.reinforce_occupation(civ_id,region_id)
		var at_after:int=mc._occupation_force_index(civ_id,region_id)
		if at_after>=0:
			for key in kept: mc.occupation_forces[at_after][key]=kept[key]
		if more.has("error"): refusals.append(String(more.error))
		else:
			garrison=int(mc.occupation_force_for_region(civ_id,region_id).get("troops",garrison))
			out.reinforced=maxi(0,garrison-before); out.garrison=garrison
			parts.append("%s more join the garrison of %s; %s hold it now." % [_cap(_count(int(out.reinforced))),name,_count(garrison)])
	# Killing: those we hold, then the free on the stated odds.
	if bool(fate.get("kill_men",false)): harsh+=_kill(civ_id,region_id,name,fate,garrison,out,parts,refusals,day)
	# People walked home: captives in bonds, or residents as our own.
	var status:=String(fate.get("move","enslaved" if bool(fate.get("captives",false)) else ""))
	if status!="": harsh+=_carry(civ_id,region_id,name,home,status,fate,garrison,out,parts,refusals,day)
	# Freeing captives already brought home from this town.
	if bool(fate.get("free",false)):
		var freed_people:=0
		var total:=float(WorldSimulation.state.population_exact) if float(WorldSimulation.state.population_exact)>0.0 else float(WorldSimulation.state.population_total)
		for group:Dictionary in mc.occupation_transfers.data.groups:
			if String(group.get("origin_region",""))!=region_id or String(group.get("status",""))=="citizen": continue
			if not mc.occupation_transfers.emancipate(int(group.id)).has("error"):
				out.freed=int(out.freed)+1
				freed_people+=roundi(float(group.get("share",0.0))*total)
		if int(out.freed)>0:
			var l:=Ledger.of(civ_id,region_id)
			l["freed"]=int(l.get("freed",0))+freed_people
			parts.append("The %s captives from %s living among us are free people now, with our rights." % [_count(freed_people),name] if freed_people>0 else "The captives from %s living among us are free people now, with our rights." % name)
		else: refusals.append("Nobody from %s is held in bonds among us." % name)
	# Tribute: what the band can carry of their stores.
	if bool(fate.get("tribute",false)):
		var stock:=Hall.foreign_stock(civ_id,"Food")
		var got:=0.0
		if stock>0.0: got=Hall.EXCHANGE.take(civ_id,"Food",minf(stock*0.25,float(garrison)*TRIBUTE_PER_FIGHTER))
		if got>0.0:
			Hall.EXCHANGE.receive("player","Food",got)
			out.tribute=roundi(got)
			parts.append("The band carried off %d Food from their stores." % roundi(got))
			harsh+=0.2
		else:
			refusals.append("Their stores are already empty; there is nothing to take.")
	# How we rule it.
	var policy:=String(fate.get("policy",""))
	if policy!="" and not bool(fate.get("raze",false)):
		var ruled:Dictionary=world.set_occupation_policy(civ_id,region_id,policy)
		if ruled.has("error"): refusals.append(String(ruled.error))
		else:
			out.policy=policy
			parts.append(String({"military_rule":"%s is ruled by the spear now: our fighters' word is law there.","self_rule":"%s keeps its own elders; we take little and ask little.",
				"equal_citizenship":"The people of %s are counted as our own people now, with our rights.","stewardship":"%s is governed as a town of ours: its stores kept and its people protected.",
				"forced_labor":"The people of %s are held as slaves and made to work for us."}.get(policy,"%s has a new order.")) % name)
			if policy in ["military_rule","forced_labor"]: harsh+=0.5 if policy=="military_rule" else 0.8
	if bool(fate.get("reconstruct",false)):
		var built:Dictionary=world.set_occupation_policy(civ_id,region_id,"reconstruct")
		if built.has("error"): refusals.append(String(built.error))
		else: parts.append("Rebuilding begins at %s, as fast as our stores and their hands allow." % name)
	# Burning: the town becomes our ruin; the garrison stays only if told to.
	if bool(fate.get("raze",false)): harsh+=_burn(civ_id,region_id,name,fate,garrison,out,parts,refusals,day)
	# Given back, or stripped and left: the town goes back and the garrison comes home.
	if not bool(out.burned) and (bool(fate.get("leave",false)) or (bool(fate.get("tribute",false)) and not bool(fate.get("hold",false)) and policy=="")):
		var back:Dictionary=world.occupation_resident_order(civ_id,region_id,"restore_self_rule")
		if not back.has("error"):
			out.left=true
			parts.append("The garrison marches home%s." % (" behind the captives" if int(out.captives)>0 else ""))
		else:
			refusals.append("The garrison cannot leave yet: %s" % String(back.error))
	if bool(fate.get("spare",false)) or (parts.is_empty() and refusals.is_empty() and bool(fate.get("hold",false))):
		out.spared=true
		var civ:Dictionary=world.civilizations[index]
		var ri:int=world._region_index(civ,region_id)
		if ri>=0:
			var r:Dictionary=civ.strategic_regions[ri]
			var data:Dictionary=Governance.state(r)
			data.grievance=clampf(float(data.grievance)-.1,0,1); data.trust=clampf(float(data.trust)+.1,0,1)
			r.governance=data; civ.strategic_regions[ri]=r; world.civilizations[index]=civ
			if WorldSimulation.enabled: Combat.governance(civ_id,region_id,r)
		parts.append("%s is spared. %s of ours hold it, and nobody there is harmed." % [name,_cap(_count(garrison))])
	if parts.is_empty():
		if not refusals.is_empty(): return {"error":" ".join(refusals)}
		return {"error":"Tell me what is to become of %s: spare it and hold it, take captives and burn it, put the men to the sword, or take tribute and leave." % name}
	_consequences(civ_id,name,out,harsh,general,day)
	out["text"]=" ".join(parts)+(" But "+_lower_first(" ".join(refusals)) if not refusals.is_empty() else "")
	out["outcome"]=_note(name,out)
	# People got away and the garrison still holds the town: a chase can follow.
	var held_at:int=mc._occupation_force_index(civ_id,region_id)
	if int(out.escaped)>0 and held_at>=0 and not bool(out.left) and Ledger.running_men(Ledger.of(civ_id,region_id))>0: out["fled"]=Ledger.running(Ledger.of(civ_id,region_id)).duplicate(true)
	# The garrison's card on the map says what was last done there.
	if held_at>=0:
		var brief:=_note(name,out).trim_prefix(name+": ").trim_suffix(".")
		mc.occupation_forces[held_at]["fate_note"]=_cap(brief).substr(0,80)
		# Measures still in force keep the card; this order waits behind them.
		if bool(mc.occupation_forces[held_at].get("measure_note",false)):
			mc.occupation_forces[held_at]["note_before"]=_cap(brief).substr(0,80)
			Measures.refresh_note(mc.occupation_forces[held_at])
		# The tribute taken (the people are counted in the town's ledger).
		var past:Dictionary=(mc.occupation_forces[held_at].get("fate") as Dictionary).duplicate() if mc.occupation_forces[held_at].get("fate") is Dictionary else {}
		past["tribute"]=int(past.get("tribute",0))+int(out.get("tribute",0))
		past["day"]=day
		mc.occupation_forces[held_at]["fate"]=past
	Chronicle.record({"key":"town_fate:%s:%d" % [region_id,day],"title":_title(name,out).substr(0,70),"text":" ".join(parts),
		"tier":"moment","kind":"war","domain":"security","action":{"kind":"court","focus":{"civ_id":civ_id}}})
	return out


# --------------------------------------------------------------------------
# Killing
# --------------------------------------------------------------------------

## The chance to catch each free man as a killing starts: our fighters to
## their men, and what already holds them (kept indoors, kin held as
## hostages, their weapons taken). Within what early warfare shows: most who
## stand are caught, a good share of the rest get away.
static func catch_odds(garrison:int,free:int,force:Dictionary,l:Dictionary)->float:
	if free<=0: return 1.0
	var p:=CAUGHT_SHARE+0.2*(clampf(float(garrison)*3.0/float(free),0.0,1.5)-1.0)
	if not Measures._running(force,"curfew").is_empty(): p+=0.08
	if not l.is_empty() and Ledger.count(l,"hostage")>0: p+=0.04
	if not Measures._running(force,"disarm").is_empty(): p+=0.03
	return clampf(p,0.35,0.92)

## The god's order to kill. Those we hold cannot run and all die (a number
## asked takes them first); the garrison's hands set only how long it takes.
## The free are each caught on the stated odds, one seeded roll each, at most
## a day's work of our fighters; the rest run for their refuge.
static func _kill(civ_id:String,region_id:String,name:String,fate:Dictionary,garrison:int,out:Dictionary,parts:PackedStringArray,refusals:PackedStringArray,day:int)->float:
	var world:Variant=WorldSimulation.world
	var l:=Ledger.of(civ_id,region_id)
	var all:=bool(fate.get("kill_all",false))
	var bound_only:=bool(fate.get("bound_only",false))
	var groups:Array=Ledger.GROUPS if all else (fate.get("kill_groups",["men"]) as Array)
	var who:="people" if all or groups.size()>=Ledger.GROUPS.size() else " and ".join(PackedStringArray(groups.map(func(g:Variant)->String: return String(Ledger.GROUP_WORDS.get(String(g),"people")))))
	var asked:=int(fate.get("count",0))
	var held_plan:=Ledger.plan_of(["bound","worker","conscript","hostage"],groups)
	var held:=0
	var bound:=0
	for step in held_plan:
		var k:=Ledger.count(l,String(step[0]),String(step[1]))
		held+=k
		if String(step[0])=="bound": bound+=k
	# "bound men" when all we hold are bound; "men we hold" when some work or serve.
	var held_words:=("bound "+who) if bound==held else (who+" we hold")
	var free_by:={}
	var free:=0
	for g in groups:
		var n:=0 if bound_only else Ledger.count(l,"free",String(g))
		free_by[g]=n; free+=n
	if held+free<=0:
		refusals.append(("There are no %s of %s under our guard to kill. %s" % [who,name,_left_words(civ_id,region_id,name)]) if bound_only else ("There are no %s left in %s to kill. %s" % [who,name,_left_words(civ_id,region_id,name)]))
		return 0.0
	var per_day:=maxi(1,garrison*KILLS_PER_FIGHTER*(2 if all else 1))
	var take_held:=held if asked<=0 else mini(held,asked)
	var want_free:=free if asked<=0 else mini(free,maxi(0,asked-take_held))
	var force:Dictionary=WorldSimulation.military.occupation_force_for_region(civ_id,region_id)
	var p:=catch_odds(garrison,want_free,force,l)
	var r:=Ledger.rng(region_id,day,"kill:"+who)
	var caught_by:={}
	var caught:=0
	var left:=want_free
	for g in groups:
		var n:=mini(int(free_by[g]),left); left-=n
		var c:=mini(Ledger.roll(r,n,p),maxi(0,per_day-caught))
		caught_by[g]=c; caught+=c
	# The rest run as the killing starts (a number asked leaves the others be).
	var escaped_by:={}
	var escaped:=0
	if want_free>0 and asked<=0:
		for g in groups:
			var e:=int(free_by[g])-int(caught_by[g])
			escaped_by[g]=e; escaped+=e
	var total:=take_held+caught
	var available:=maxi(0,roundi(float(Ledger.region_ref(civ_id,region_id).get("population",0.0))))
	total=mini(total,available)
	# The ledger first (the world's deaths rebuild the town's record, and the
	# ledger goes with it): the held, then the caught; the rest run.
	var backup:=l.duplicate(true)
	var held_dead:=int(Ledger.remove(l,held_plan,mini(take_held,total),"killed").total)
	var free_dead:=0
	for g in groups:
		var c:=mini(int(caught_by[g]),total-held_dead-free_dead)
		if c>0: free_dead+=int(Ledger.remove(l,[["free",String(g)]],c,"killed").total)
	var refuge:=Pursuit.refuge(civ_id,region_id)
	for g in groups:
		if int(escaped_by.get(g,0))>0: Ledger.run(l,"free",String(g),int(escaped_by[g]),refuge,day)
	if held_dead+free_dead>0:
		var done:Dictionary=world.occupation_resident_order(civ_id,region_id,"kill_residents",held_dead+free_dead,true)
		if done.has("error"):
			# Nothing happened in the world: nothing happened in the ledger.
			Ledger.region_ref(civ_id,region_id)["ledger"]=backup
			refusals.append(String(done.error)); return 0.0
	out.killed=int(out.killed)+held_dead+free_dead
	out.escaped=int(out.escaped)+escaped
	out["kill_odds"]=p
	out["held_killed"]=held_dead
	out["kill_escaped"]=escaped
	Measures.settle_records(civ_id,region_id)
	parts.append(_kill_words(name,who,garrison,held_dead,take_held,want_free,free_dead,escaped,p,per_day,refuge,held_words,asked>0 and free>want_free))
	return 1.0 if held_dead+free_dead>0 else 0.0

## "17 of ours against 38 bound men: none could run. All 38 were killed."
static func _kill_words(name:String,who:String,garrison:int,held_dead:int,held:int,free:int,free_dead:int,escaped:int,p:float,per_day:int,refuge:Dictionary,held_words:String,rest_left:bool)->String:
	var ours:="%s of ours" % _cap(_count(garrison))
	var t:=""
	var days:=ceili(float(held_dead+free_dead)/float(maxi(1,per_day)))
	if free<=0:
		t="%s against %s %s: none could run. %s were killed." % [ours,_count(held),held_words,("All %s" % _count(held_dead)) if held_dead==held else _cap(_count(held_dead))]
	elif held<=0:
		t="%s against %s %s of %s, free in their houses: %s. %s %s of %s were put to the sword" % [ours,_count(free),who,name,_chance(p),_cap(_count(free_dead)),who,name]
		t+=("; %s got away %s." % [_count(escaped),Pursuit.toward_words(refuge)]) if escaped>0 else "; none got away."
	else:
		t="%s against %s %s and %s free. %s could not run: %s were killed. Of the free, %s: %s more %s of %s were put to the sword" % [ours,_count(held),held_words,_count(free),"The bound" if held_words.begins_with("bound") else "Those we held",("all %s" % _count(held_dead)) if held_dead==held else _count(held_dead),_chance(p),_count(free_dead),who,name]
		t+=("; %s got away %s." % [_count(escaped),Pursuit.toward_words(refuge)]) if escaped>0 else "; none got away."
	if rest_left: t+=" The rest are left in their houses."
	if days>1: t+=" It took %s." % _days(days)
	return t

## "a good chance to catch each, about 7 in 10".
static func _chance(p:float)->String:
	var quality:="a good chance" if p>=0.6 else ("an even chance" if p>=0.4 else "a poor chance")
	return "%s to catch each, %s" % [quality,Ledger.chance_words(p)]

## Who is still in the town, in words: "Tsaren has 70 women, 93 children and
## 63 old people left, all free in their houses."
static func _left_words(civ_id:String,region_id:String,name:String)->String:
	var c:=Ledger.counts(civ_id,region_id)
	if c.is_empty() or int(c.here)<=0: return "Nobody is left in %s." % name
	return "In %s now: %s." % [name,Ledger.here_words(c)]


# --------------------------------------------------------------------------
# Taking people home
# --------------------------------------------------------------------------

## The chance to round up each of those the god names: the men bound or dead
## leave nobody to hide them; kept indoors, fewer slip away.
static func round_up_odds(l:Dictionary,force:Dictionary)->float:
	var p:=ROUNDED_UP_SHARE
	var men_start:=maxi(1,roundi(float(int(l.get("start",0)))*MEN_SHARE))
	if Ledger.count(l,"free","men")<=roundi(float(men_start)*0.1): p+=0.15
	if not Measures._running(force,"curfew").is_empty(): p+=0.05
	return clampf(p,0.4,0.85)

## Captives in bonds, or residents moved as our own or to labour. Those we
## already hold (bound, hostages) go first and none of them can slip away;
## the free are each rounded up on the stated odds (captives), one seeded roll
## each. All bounded by what the garrison can guard on the road, by the road,
## the rations and the room at home.
static func _carry(civ_id:String,region_id:String,name:String,home:String,status:String,fate:Dictionary,garrison:int,out:Dictionary,parts:PackedStringArray,refusals:PackedStringArray,day:int)->float:
	var mc:Variant=WorldSimulation.military
	var l:=Ledger.of(civ_id,region_id)
	var enslaved:=status=="enslaved"
	var take:Dictionary=fate.get("take",{"women":1.0,"children":1.0}) if enslaved else {"men":1.0,"women":1.0,"children":1.0,"elders":1.0}
	var held_by:={}
	var held_n:=0
	var pool_by:={}
	var pool:=0
	for g in Ledger.GROUPS:
		if not take.has(g): continue
		var share:=clampf(float(take[g]),0.0,1.0)
		var h:=roundi(float(Ledger.count(l,"bound",g)+Ledger.count(l,"hostage",g))*share) if enslaved else 0
		if h>0: held_by[g]=h; held_n+=h
		var n:=roundi(float(Ledger.count(l,"free",g))*share)
		if n>0: pool_by[g]=n; pool+=n
	var whom:=_take_names(take)
	if pool+held_n<=0:
		refusals.append("There are no %s left in %s to take. %s" % [whom,name,_left_words(civ_id,region_id,name)])
		return 0.0
	var wanted:=pool+held_n if enslaved else roundi(float(pool)*0.3)
	var asked:=int(fate.get("count",0))
	if asked>0 and not bool(fate.get("kill_men",false)): wanted=mini(wanted,asked)
	var force:Dictionary=mc.occupation_force_for_region(civ_id,region_id)
	var p:=round_up_odds(l,force) if enslaved else 1.0
	var r:=Ledger.rng(region_id,day,"carry:"+status)
	var cap:=garrison*CAPTIVES_PER_FIGHTER
	var left:=wanted
	# Those we hold: none can slip away.
	var held_caught_by:={}
	var held_caught:=0
	for g in held_by:
		var c:=mini(mini(int(held_by[g]),left),maxi(0,cap-held_caught))
		held_caught_by[g]=c; held_caught+=c; left-=c
	# The free: each on the stated odds.
	var caught_by:={}
	var caught:=0
	var ran_by:={}
	var hid:=0
	for g in pool_by:
		var n:=mini(int(pool_by[g]),maxi(0,left)); left-=n
		var rolled:=Ledger.roll(r,n,p) if enslaved else n
		var c:=mini(rolled,maxi(0,cap-held_caught-caught))
		caught_by[g]=c; caught+=c
		if enslaved:
			# Those who slipped the round-up: some run for it, the rest hide.
			var evaded:=n-rolled
			var ran:=Ledger.roll(r,evaded,0.5)
			ran_by[g]=ran; hid+=evaded-ran
	if held_caught+caught<=0:
		refusals.append("We could not lay hands on any of the %s of %s." % [whom,name])
		return 0.0
	# The road, the rations and the room at home set how many can go.
	var count:=held_caught+caught
	var moved:Dictionary={}
	var last_error:=""
	for attempt in 8:
		if count<1: break
		var tried:Dictionary=mc.occupation_transfers.depart(civ_id,region_id,count,status,enslaved)
		if not tried.has("error"): moved=tried; break
		last_error=String(tried.error)
		count=count/2
	if moved.is_empty():
		refusals.append(last_error if last_error!="" else "There was nobody to take.")
		return 0.0
	var transfer:Dictionary=(mc.occupation_transfers.data.transfers as Array).back()
	out.arrive_days=int(transfer.get("days",0))
	# The ledger: those we held go first, then the free, by group in
	# proportion to those caught.
	var from_held:=mini(count,held_caught)
	var weights:={}
	for g in Ledger.GROUPS: weights[g]=float(held_caught_by.get(g,0))
	var went:=Ledger.split(from_held,weights)
	for g in Ledger.GROUPS:
		if int(went[g])>0: Ledger.remove(l,[["bound",g],["hostage",g]],int(went[g]),"taken")
	weights={}
	for g in Ledger.GROUPS: weights[g]=float(caught_by.get(g,0))
	went=Ledger.split(count-from_held,weights)
	for g in Ledger.GROUPS:
		if int(went[g])>0: Ledger.remove(l,[["free",g]],int(went[g]),"taken")
	var refuge:=Pursuit.refuge(civ_id,region_id)
	var ran:=0
	for g in ran_by:
		var n:=mini(int(ran_by[g]),Ledger.count(l,"free",String(g)))
		if n>0: Ledger.run(l,"free",String(g),n,refuge,day); ran+=n
	out.escaped=int(out.escaped)+ran
	if from_held>0: Measures.settle_records(civ_id,region_id)
	var road:="about %s on the road" % _days(int(out.arrive_days))
	if enslaved:
		out.captives=count
		var how:=""
		if held_caught>0 and pool>0: how="the %s we held could not slip away, and of the rest, %s" % [_count(held_caught),_chance(p)]
		elif held_caught>0: how="all %s were already under our guard, so none could slip away" % _count(held_caught)
		else: how=_chance(p)+(", with their men bound or dead" if p>=ROUNDED_UP_SHARE+0.15-0.001 else "")
		var t:="%s of ours rounded up the %s of %s: %s. %s were led away toward %s as captives, %s." % [_cap(_count(garrison)),whom,name,how,_cap(_count(count)),home,road]
		if held_caught+caught>count: t+=" We could not feed or house more on the road, so %s we had caught stay in the town." % _count(held_caught+caught-count)
		if ran>0: t+=" %s ran %s." % [_cap(_count(ran)),Pursuit.toward_words(refuge)]
		if hid>0: t+=" %s hid in the town and were not found." % _cap(_count(hid))
		parts.append(t)
		return 0.7
	out.moved=count; out.move_status=status
	parts.append("%s people of %s set out for %s %s, %s." % [_cap(_count(count)),name,home,"as our own people" if status=="citizen" else "to labour for us",road])
	return 0.4 if status=="penal" else 0.0

## "women and girls", "women and children", "people".
static func _take_names(take:Dictionary)->String:
	if take.size()>=4: return "people"
	var words:PackedStringArray=PackedStringArray()
	for g in Ledger.GROUPS:
		if not take.has(g): continue
		if g=="children" and float(take[g])<1.0: words.append("girls")
		else: words.append(String(Ledger.GROUP_WORDS[g]))
	return " and ".join(words)


# --------------------------------------------------------------------------
# Burning: our ruin
# --------------------------------------------------------------------------

## Burning: the houses, the stores and the walls go; whoever is still free in
## the town scatters to their people's other towns (or the hills); those we
## hold stay under guard only if the garrison stays. The town becomes our
## ruin in the ledger and the world, dated the day; it is not given back.
static func _burn(civ_id:String,region_id:String,name:String,fate:Dictionary,garrison:int,out:Dictionary,parts:PackedStringArray,refusals:PackedStringArray,day:int)->float:
	var world:Variant=WorldSimulation.world
	var mc:Variant=WorldSimulation.military
	var l:=Ledger.of(civ_id,region_id)
	# The town is gone: whoever was running from it reaches their refuge now.
	if not Ledger.running(l).is_empty():
		Pursuit.arrive(civ_id,region_id)
		l=Ledger.of(civ_id,region_id)
	var index:int=world._civilization_index(civ_id)
	var stays:=bool(fate.get("hold",false)) or String(fate.get("policy",""))!=""
	var refuge:=Pursuit.refuge(civ_id,region_id)
	var where:="the hills" if bool(refuge.get("hills",false)) else String(refuge.get("name","the hills"))
	# Who scatters: the free, and those we hold if we go.
	var statuses:Array=["free"] if stays else Ledger.PRESENT
	var n:=0
	for status in statuses: n+=Ledger.count(l,String(status))
	var men:=0
	if n>0:
		var removed:=Ledger.remove(l,Ledger.plan_of(statuses),n,"displaced")
		Ledger.went_to(l,where,int(removed.total))
		men=int(removed.get("men",0))
		Pursuit._reach_refuge(civ_id,region_id,int(removed.total),refuge,men)
	# The town itself: houses, stores and walls.
	var civ:Dictionary=world.civilizations[index]
	var ri:int=world._region_index(civ,region_id)
	if ri>=0:
		var r:Dictionary=civ.strategic_regions[ri]
		var data:Dictionary=Governance.state(r)
		data.ruined=true; data.reconstruction=false
		data.grievance=clampf(float(data.grievance)+.25,0,1)
		data.local_institutions=maxf(0,float(data.local_institutions)-.3)
		data.last_coercive_day=day
		r.governance=data
		r["damage"]=1.0
		r["fortification"]=0.0
		if Ledger.present_total(l)<=0: r["resistance"]=0.0
		if r.has("stores"): r["stores"]={}
		civ.strategic_regions[ri]=r
		world.civilizations[index]=civ
		if WorldSimulation.enabled:
			Combat.governance(civ_id,region_id,r)
			Combat.damage_city(civ_id,region_id,1.0)
	# Measures that held people end when those people are gone.
	Measures.settle_records(civ_id,region_id)
	out.burned=true
	# The town's record as the world keeps it now (the scattering rebuilt it).
	l=Ledger.of(civ_id,region_id)
	var remain:=Ledger.present_total(l)
	var t:="%s was burned: its houses, its stores and its walls." % name
	if n>0: t+=" %s who were still there scattered %s." % [_cap(_count(n)),Pursuit.toward_words(refuge)]
	var ruin:={"day":day,"before":Ledger.accounted(l),"by":"player","held":true,"left_day":-1,"stores_lost":true,"resettle":{}}
	l["ruin"]=ruin
	if not stays:
		# Nobody left to hold: the garrison comes home and the ruin is nobody's.
		var gone:Dictionary=mc.evacuate_occupation(civ_id,region_id)
		if gone.has("error"):
			refusals.append("The garrison cannot leave yet: %s" % String(gone.error))
		else:
			out.left=true
			ruin.held=false; ruin.left_day=day
			_schedule_resettle(civ_id,region_id,l,day)
			t+=" The garrison marches home%s; nobody holds the ruins." % (" behind the captives" if int(out.captives)>0 else "")
	else:
		t+=" %s of ours stay to hold the ruins%s." % [_cap(_count(garrison)),(", with %s under guard" % _count(remain)) if remain>0 else ""]
	t+=" Nobody lives there now." if remain<=0 else ""
	parts.append(t)
	# Our own account of it, dated the day, replaces any old report of the place.
	firsthand(civ_id,region_id,day,"our own fighters")
	return 0.6

## Our people saw it themselves: the city's record is today's, from them.
static func firsthand(civ_id:String,region_id:String,day:int,source:String)->void:
	var world:Variant=WorldSimulation.world
	if world==null or world.city_intelligence==null: return
	var intel:Variant=world.city_intelligence
	var seen:Dictionary=intel.capture("player",region_id,0.9,day,source,"ruin:%s:%d" % [region_id,day])
	if seen.is_empty(): return
	var book:Dictionary=intel.records.get("player",{})
	if book.has(region_id) and (book[region_id] as Dictionary).get("position") is Dictionary:
		seen["position"]=((book[region_id] as Dictionary).position as Dictionary).duplicate(true)
	intel.publish("player",seen,day)

## A ruin we burned and left: will its people come back to live in it? The
## odds from who survived to return, their dread of us and the war; the roll
## is made once (seeded) with its date and the day our people hear of it.
static func _schedule_resettle(civ_id:String,region_id:String,l:Dictionary,day:int)->void:
	var ruin:Dictionary=l.get("ruin",{})
	if ruin.is_empty() or not (ruin.get("resettle",{}) as Dictionary).is_empty(): return
	var before:=maxi(1,int(ruin.get("before",1)))
	var alive:=Ledger.gone(l,"fled")+Ledger.gone(l,"displaced")+Ledger.running_total(l)
	var share:=clampf(float(alive)/float(before),0.0,1.0)
	var dread:=clampf(DIVINE.civ_dread(civ_id),0.0,1.0)
	var at_war:=false
	var index:int=WorldSimulation.world._civilization_index(civ_id)
	if index>=0: at_war=bool((WorldSimulation.world.civilizations[index].get("player_relation",{}) as Dictionary).get("at_war",false))
	var p:=clampf(0.3+0.4*share-0.3*dread-(0.15 if at_war else 0.0),0.05,0.85)
	var r:=Ledger.rng(region_id,day,"resettle")
	var when:=day+r.randi_range(int(RESETTLE_DAYS[0]),int(RESETTLE_DAYS[1]))
	ruin["resettle"]={"chance":p,"happens":r.randf()<p,"day":when,"learn_day":when+r.randi_range(int(LEARN_DAYS[0]),int(LEARN_DAYS[1])),"done":false,"happened":false,"known":false,"people":0}

## Each day: whoever we held where no garrison of ours stands is free again; an empty
## ruin has nobody to resist us; a ruin's people come back on their day (if
## the roll said so and nobody of ours holds it), and our people hear of it
## later. Returns report matters filed.
static func daily(day:int)->Array:
	var filed:Array=[]
	var world:Variant=WorldSimulation.world
	var mc:Variant=WorldSimulation.military
	if world==null or mc==null: return filed
	for pair in Ledger.towns():
		var civ_id:=String(pair[0]); var region_id:=String(pair[1])
		var r:=Ledger.region_ref(civ_id,region_id)
		var l:=Ledger.of(civ_id,region_id)
		# No garrison of ours there any more: whoever we held is free again.
		if mc._occupation_force_index(civ_id,region_id)<0 and Ledger.held(l)>0:
			for status in ["bound","hostage","worker","conscript"]:
				for g in Ledger.GROUPS: Ledger.move(l,String(status),"free",String(g),Ledger.count(l,String(status),String(g)))
		var ruin:Dictionary=l.get("ruin",{}) if l.get("ruin") is Dictionary else {}
		if ruin.is_empty(): continue
		var ours:=String(r.get("controller",""))=="player"
		var held:bool=mc._occupation_force_index(civ_id,region_id)>=0
		if ours and Ledger.present_total(l)<=0: r["resistance"]=0.0
		if not held and ours and (ruin.get("resettle",{}) as Dictionary).is_empty():
			ruin["held"]=false
			if int(ruin.get("left_day",-1))<0: ruin["left_day"]=day
			_schedule_resettle(civ_id,region_id,l,day)
		var rs:Dictionary=ruin.get("resettle",{}) if ruin.get("resettle") is Dictionary else {}
		if rs.is_empty(): continue
		if not bool(rs.get("done",false)) and day>=int(rs.get("day",day+1)):
			rs["done"]=true
			if bool(rs.get("happens",false)) and not held and ours:
				var n:=_resettle(civ_id,region_id,day)
				# The town's record was rebuilt: say so on the ledger it has now.
				var fresh:Dictionary=Ledger.of(civ_id,region_id).get("ruin",{})
				rs=fresh.get("resettle",{}) if fresh.get("resettle") is Dictionary else rs
				rs["done"]=true
				if n>=0: rs["happened"]=true; rs["people"]=n; rs["day"]=day
		if bool(rs.get("happened",false)) and not bool(rs.get("known",false)) and day>=int(rs.get("learn_day",day+1)):
			rs["known"]=true
			filed.append(_heard(civ_id,region_id,rs,day))
	return filed

## Their people come back to live in the ruin: the town is theirs again,
## still broken, with some settlers from their largest town. Returns how
## many came (-1 when it could not happen).
static func _resettle(civ_id:String,region_id:String,day:int)->int:
	var world:Variant=WorldSimulation.world
	var index:int=world._civilization_index(civ_id)
	if index<0: return -1
	var civ:Dictionary=world.civilizations[index]
	var source:=-1
	var best:=0.0
	for i in (civ.strategic_regions as Array).size():
		var sr:Dictionary=civ.strategic_regions[i]
		if String(sr.get("id",""))==region_id or String(sr.get("controller",civ_id))!=civ_id: continue
		if float(sr.get("population",0.0))>best: best=float(sr.get("population",0.0)); source=i
	var r:=Ledger.rng(region_id,day,"resettlers")
	var n:=0
	if source>=0: n=mini(r.randi_range(int(RESETTLERS[0]),int(RESETTLERS[1])),roundi(best*0.2))
	var back:Dictionary=world.abandon_occupied_region(civ_id,region_id)
	if back.has("error"): return -1
	civ=world.civilizations[index]
	var ri:int=world._region_index(civ,region_id)
	if ri>=0:
		var ruined:Dictionary=civ.strategic_regions[ri]
		ruined["damage"]=maxf(0.85,float(ruined.get("damage",0.0)))
		if n>0 and not WorldSimulation.enabled:
			var sri:int=world._region_index(civ,String(civ.strategic_regions[source].id)) if source>=0 else -1
			if sri>=0:
				civ.strategic_regions[sri]["population"]=maxf(0.0,float(civ.strategic_regions[sri].get("population",0.0))-float(n))
				ruined["population"]=float(ruined.get("population",0.0))+float(n)
		civ.strategic_regions[ri]=ruined
		world.civilizations[index]=civ
	return n

## Our people hear the ruin is lived in again: one report, one Chronicle
## line, and the chart shows their town again from what we heard.
static func _heard(civ_id:String,region_id:String,rs:Dictionary,day:int)->Dictionary:
	var world:Variant=WorldSimulation.world
	var region:Dictionary=world.region_snapshot(civ_id,region_id)
	var name:=String(region.get("name","the ruin"))
	var people:String=load("res://scripts/map_ownership.gd").people(civ_id)
	var n:=int(rs.get("people",0))
	var parts:=String(preload("res://scripts/hud/era_words.gd").when(int(rs.get("day",day)))).split(" · ")
	var when:=("in the %s of %s" % [parts[1].to_lower(),parts[0]]) if parts.size()==2 else "lately"
	var text:="Hunters from the %s side say %s have come back to live in the ruins of %s%s. They moved in %s; nobody of ours was there to stop them." % [name,people,name,(", about %d of them" % (roundi(float(n)/5.0)*5 if n>=10 else n)) if n>0 else "",when]
	var war_loop:GDScript=load(WAR_LOOP_PATH)
	var matter:Variant=war_loop.call("_file",civ_id,"report",text,day)
	Chronicle.record({"key":"ruin_resettled:%s:%d" % [region_id,int(rs.get("day",day))],"title":("%s Lived In Again" % name).substr(0,70),"text":text,"tier":"notice","kind":"war","domain":"security","action":{"kind":"court","focus":{"civ_id":civ_id}}})
	firsthand(civ_id,region_id,day,"hunters' word")
	return matter if matter is Dictionary and not (matter as Dictionary).is_empty() else {"text":text}


# --------------------------------------------------------------------------
# Consequences and words
# --------------------------------------------------------------------------

## Dread and grudges; our reputation; the court's dread of the god.
static func _consequences(civ_id:String,name:String,out:Dictionary,harsh:float,general:Dictionary,day:int)->void:
	var mc:Variant=WorldSimulation.military
	var killed:=int(out.killed); var captives:=int(out.captives)
	var weight:=clampf(float(killed+captives)/60.0,0.0,1.0)
	if bool(out.spared) or int(out.freed)>0 or String(out.policy) in ["self_rule","equal_citizenship","stewardship"]:
		Hall._shift_relation(civ_id,0.06,-0.04)
		mc._adjust_war_reputation(0.08,0.0,-0.04)
	if harsh<=0.0: return
	var what:="the men of %s you put to the sword" % name if killed>0 else ("the women and children of %s you carried off" % name if captives>0 else ("%s, which you burned" % name if bool(out.burned) else "what you did to %s" % name))
	# The people who were struck: hatred, dread and a grudge they keep.
	Hall._shift_relation(civ_id,-clampf(0.12*harsh,0.05,0.4),clampf(0.1*harsh,0.05,0.3))
	DIVINE.add_civ_dread(civ_id,clampf(0.06*harsh+0.12*weight,0.04,0.35))
	preload("res://scripts/rival_rulers.gd").grudge(civ_id,what,clampf(0.5+0.5*harsh,0.5,1.5),"town_fate:%s:%d" % [name,day])
	ForeignDiplomacy.remember(civ_id,"The god's people did this to %s: %s." % [name,_memory(name,out)])
	# Every people that knows us hears of it: dread, and a little less goodwill.
	for civ:Dictionary in WorldSimulation.world.civilizations:
		var other:=String(civ.get("id",""))
		if other==civ_id or other=="player": continue
		if int((civ.get("player_relation",{}) as Dictionary).get("contact_level",0))<2: continue
		DIVINE.add_civ_dread(other,clampf(0.03*harsh+0.05*weight,0.01,0.12))
		Hall._shift_relation(other,-clampf(0.03*harsh,0.01,0.08),clampf(0.02*harsh,0.0,0.06))
	# Our own record: feared, hated, remembered.
	mc._adjust_war_reputation(0.0,clampf(0.05*harsh+0.1*weight,0.02,0.3),clampf(0.04*harsh+0.08*weight,0.02,0.25))
	var metrics:Dictionary=WorldSimulation.state.simulation_metrics
	if killed>0:
		metrics["cohesion"]=clampf(float(metrics.get("cohesion",0.5))-clampf(0.01+0.03*weight,0.01,0.04),0.0,1.0)
	if captives>0:
		metrics["legitimacy"]=clampf(float(metrics.get("legitimacy",0.5))-clampf(0.01+0.02*weight,0.01,0.03),0.0,1.0)
	# The court hears what the god ordered; they fear the god more.
	for person:Dictionary in Hall._officials():
		var pid:=int(person.get("person_id",0))
		if pid<=0: continue
		GovernmentPeopleSystem.adjust_person_bonds(pid,{"fear":clampf(0.015*harsh+0.02*weight,0.01,0.05),"hold_days":60})
	var gpid:=int(general.get("person_id",0))
	if gpid>0:
		GovernmentPeopleSystem.record_person_memory(gpid,"At the god's word my fighters %s." % _memory(name,out),"divine",0.85,{"emotion":"duty","outcome":"town_fate"})


static func _note(name:String,out:Dictionary)->String:
	if bool(out.spared) and int(out.killed)==0 and int(out.captives)==0: return "%s is spared and held." % name
	var bits:PackedStringArray=PackedStringArray()
	if int(out.killed)>0: bits.append("%s killed" % _count(int(out.killed)))
	if int(out.escaped)>0: bits.append("%s got away" % _count(int(out.escaped)))
	if int(out.captives)>0: bits.append("%s captives on the road to %s" % [_count(int(out.captives)),String(WorldSimulation.state.settlement_name)])
	if int(out.moved)>0: bits.append("%s people on the road to %s" % [_count(int(out.moved)),String(WorldSimulation.state.settlement_name)])
	if bool(out.burned): bits.append("the town burned")
	if int(out.tribute)>0: bits.append("%d Food taken" % int(out.tribute))
	if String(out.policy)!="": bits.append(String({"military_rule":"ruled by the spear","self_rule":"left to its own elders","equal_citizenship":"its people made our own","stewardship":"governed as ours","forced_labor":"its people enslaved"}.get(String(out.policy),"a new order")))
	if int(out.reinforced)>0: bits.append("the garrison now %s" % _count(int(out.garrison)))
	if int(out.freed)>0: bits.append("the captives freed")
	if bool(out.left) and not bool(out.burned): bits.append("the garrison coming home")
	if bool(out.left) and bool(out.burned): bits.append("nobody holds the ruins")
	if bits.is_empty(): return "%s: the god's word is carried out." % name
	return "%s: %s." % [name,", ".join(bits)]


static func _title(name:String,out:Dictionary)->String:
	if int(out.killed)>0 and bool(out.burned): return "The Sack of %s" % name
	if int(out.killed)>0: return "The Men of %s Put to the Sword" % name
	if int(out.captives)>0 and bool(out.burned): return "%s Burned, Its Women and Children Taken" % name
	if bool(out.burned): return "%s Burned" % name
	if int(out.captives)>0: return "Captives Taken From %s" % name
	if String(out.policy)=="forced_labor": return "%s Enslaved" % name
	if String(out.policy)=="military_rule": return "%s Under the Spear" % name
	if int(out.tribute)>0: return "Tribute From %s" % name
	if int(out.moved)>0: return "People of %s Come to Live Among Us" % name
	if bool(out.left): return "%s Given Back" % name
	return "%s Spared" % name if bool(out.spared) else "The Order for %s" % name


static func _memory(name:String,out:Dictionary)->String:
	var bits:PackedStringArray=PackedStringArray()
	if int(out.killed)>0: bits.append("killed %s of %s" % [_count(int(out.killed)),name])
	if int(out.captives)>0: bits.append("drove %s captives home" % _count(int(out.captives)))
	if bool(out.burned): bits.append("burned %s" % name)
	if int(out.tribute)>0: bits.append("stripped its stores")
	if String(out.policy)=="forced_labor": bits.append("made its people slaves")
	if String(out.policy)=="military_rule": bits.append("ruled it by the spear")
	return " and ".join(bits) if not bits.is_empty() else "held %s" % name


static func _count(n:int)->String:
	## Counted heads: words for a few, figures beyond a dozen.
	return preload("res://scripts/battle_account.gd").count_words(n) if n<=12 else str(n)


static func _days(n:int)->String:
	return "a day" if n<=1 else "%s days" % _count(n)


static func _cap(text:String)->String:
	return text if text.is_empty() else text.substr(0,1).to_upper()+text.substr(1)


static func _lower_first(text:String)->String:
	return text if text.is_empty() else text.substr(0,1).to_lower()+text.substr(1)
