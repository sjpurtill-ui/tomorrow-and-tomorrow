extends RefCounted
## WHAT BECOMES OF A TOWN WE HOLD.
##
## After a town is taken, the god's words about it are not a new attack.
## They are orders to the garrison that holds it, and the court is the only
## place they are given (the occupation screen now only reports). Each order
## goes through the occupation machinery that already exists:
##   - how we rule it: civilization_system.set_occupation_policy (civil
##     administration, self-rule, equal citizenship, rule by the spear,
##     enslavement of the town), reconstruction, razing;
##   - killing: civilization_system.occupation_resident_order kill_residents;
##   - moving people home, free or bonded, and captives:
##     military_campaign.occupation_transfers (they walk the road, eat
##     travel rations and arrive later, into their own community record);
##     freeing captives already home: occupation_transfers.emancipate;
##   - giving it back: occupation_resident_order restore_self_rule (the
##     garrison marches home);
##   - the garrison's size: military_campaign.reinforce_occupation from a band
##     standing at the town;
##   - tribute: their stores, through civilization_exchange.
##
## A sack given as the town falls (kill, captives, burn) is bounded by what
## the garrison can physically do, in the range of early warfare: a small
## band that holds a village can kill the men who do not get away and drive
## home the captives it can guard on the road, a few per fighter. Most
## people flee a sack. The slower orders (rule by the spear, enslave the
## town, move residents as citizens) keep the existing control checks.
##
## Consequences are real and bounded: deaths and captives move population,
## the town is burned or kept, dread and grudges reach the people who were
## struck and, more faintly, every people that knows us; our war reputation
## (mercy, fear, grievance) and our court's dread of the god move; one sober
## Chronicle entry tells it.
##
## apply() -> {ok, outcome (one plain note), text (the sober account),
##             killed, captives, moved, burned, tribute, left, spared, policy,
##             reinforced, freed} | {error}.

const Hall:=preload("res://scripts/audience_hall.gd")
const Chronicle:=preload("res://scripts/chronicle.gd")
const DIVINE:=preload("res://scripts/divine_regard.gd")
const Combat:=preload("res://scripts/civilization_combat.gd")
const Governance:=preload("res://scripts/occupation_governance.gd")

## Adult men in a farming village's population (the rest are women,
## children and the old): roughly a quarter.
const MEN_SHARE:=0.24
## Of those, the share who do not get away when a sack begins.
const CAUGHT_SHARE:=0.7
## Women and children in the population.
const WOMEN_CHILDREN_SHARE:=0.55
## Of those, the share a band can round up; the rest flee or hide.
const ROUNDED_UP_SHARE:=0.6
## What one fighter can do: kill the men who stand, guard captives on the road.
const KILLS_PER_FIGHTER:=5
const CAPTIVES_PER_FIGHTER:=4
## Food a band carries off as tribute, per fighter.
const TRIBUTE_PER_FIGHTER:=40.0

const POLICY_WORDS:=[
	["military_rule","\\b(military rule|rule [\\w' ]{0,20}by (the )?(spear|sword|force|fear)|by force of arms|under the spear|martial)"],
	["self_rule","\\b(govern (themselves|itself)|rule themselves|self.rule|their own elders|let them rule|keep their own (ways|elders|chief))"],
	["equal_citizenship","\\b(equal citizens|equal citizenship|make them (our own|our people|citizens|one of us)|full citizens|as equals)"],
	["stewardship","\\b(civil administration|(govern|rule) [\\w' ]{0,20}(well|fairly|justly|kindly)|as a town of ours|administer it|steward|protect (it|them|the town))"],
	["forced_labor","\\b(enslave (the |its |their )?(whole )?(town|people|them|everyone)|make (them|the town|its people) (our )?slaves|forced labou?r|work them as slaves)"],
]

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
	if carry and people and homeward and not out.has("kill_all"):
		if _has("\\bas (our own|citizens|free|our people|equals|kin)\\b",lower) and not bonded: out["move"]="citizen"
		elif _has("\\b(penal|to labou?r|to work)\\b",lower) and not bonded: out["move"]="penal"
		else: out["captives"]=true
	if _has("\\b(burn|raze|torch|set fire|to the ground|level it|flatten|tear [\\w' ]{0,12}down|destroy (it|the town|what))",lower): out["raze"]=true
	if _has("\\b(tribute|plunder|loot|sack it|take their (food|grain|stores|goods)|strip (it|the town|them|their stores))\\b",lower): out["tribute"]=true
	if _has("\\b(spare|mercy|merciful|leave them (be|in peace)|let them (be|live)|no harm|harm no one|treat them (well|kindly|gently)|be gentle)\\b",lower) and not kill: out["spare"]=true
	if _has("\\b(hold|keep|garrison|govern|rule) (it|the town|the place|them)\\b",lower): out["hold"]=true
	if _has("\\b(give it back|hand it back|return it|leave it|withdraw|come home|pull out|abandon it|let them have it back)\\b",lower) and not out.has("hold"): out["leave"]=true
	if _has("\\b(rebuild|repair|reconstruct|build it (up|again))\\b",lower) and not out.has("raze"): out["reconstruct"]=true
	if _has("\\b(strengthen|reinforce|more (soldiers|fighters|men|spears) (to|in|at|for)|send more|add [\\w' ]{0,12}to the garrison|bigger garrison)\\b",lower): out["reinforce"]=true
	if _has("\\b(free|release|emancipate|unbind) (the )?(captives|slaves|bonded)",lower) and not kill: out["free"]=true
	if not out.has("captives"):
		for row in POLICY_WORDS:
			if _has(String(row[1]),lower): out["policy"]=String(row[0]); break
	if out.is_empty() or (out.size()==1 and out.has("count")): return {}
	if _has(GROUP_WORDS,lower): out["group"]=true
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
	var population:=maxi(0,roundi(float(region.get("population",0.0))))
	var out:={"ok":true,"town":name,"garrison":garrison,"killed":0,"captives":0,"moved":0,"move_status":"","burned":false,"tribute":0,"left":false,"spared":false,"policy":"","reinforced":0,"freed":0,"arrive_days":0}
	var parts:PackedStringArray=PackedStringArray()
	var refusals:PackedStringArray=PackedStringArray()
	var harsh:=0.0
	var asked:=int(fate.get("count",0))
	# Strengthen the garrison from a band standing at the town.
	if bool(fate.get("reinforce",false)):
		var before:=garrison
		var more:Dictionary=mc.reinforce_occupation(civ_id,region_id)
		if more.has("error"): refusals.append(String(more.error))
		else:
			garrison=int(mc.occupation_force_for_region(civ_id,region_id).get("troops",garrison))
			out.reinforced=maxi(0,garrison-before); out.garrison=garrison
			parts.append("%s more join the garrison of %s; %s hold it now." % [_cap(_count(int(out.reinforced))),name,_count(garrison)])
	# The men who stand, or everyone the band can catch.
	if bool(fate.get("kill_men",false)):
		var all:=bool(fate.get("kill_all",false))
		var wanted:=roundi(float(population)*(1.0 if all else MEN_SHARE)*CAUGHT_SHARE)
		if asked>0: wanted=mini(wanted,asked)
		var can:=mini(wanted,garrison*KILLS_PER_FIGHTER*(2 if all else 1))
		if can>0:
			var done:Dictionary=world.occupation_resident_order(civ_id,region_id,"kill_residents",can,true)
			if done.has("error"): refusals.append(String(done.error))
			else:
				out.killed=int(done.get("dead",0))
				population=maxi(0,population-int(out.killed))
				if all: parts.append("%s people of %s were put to the sword; the rest fled into the hills." % [_cap(_count(int(out.killed))),name])
				else: parts.append("%s men of %s were put to the sword; others got away in the dark." % [_cap(_count(int(out.killed))),name])
				harsh+=1.0
	# People walked home: captives in bonds, or residents as our own.
	var status:=String(fate.get("move","enslaved" if bool(fate.get("captives",false)) else ""))
	if status!="":
		var sack:=status=="enslaved" and (bool(fate.get("kill_men",false)) or bool(fate.get("raze",false)) or bool(fate.get("captives",false)))
		var wanted:=roundi(float(population)*WOMEN_CHILDREN_SHARE*ROUNDED_UP_SHARE) if status=="enslaved" else roundi(float(population)*0.3)
		if asked>0 and not bool(fate.get("kill_men",false)): wanted=mini(wanted,asked)
		var count:=mini(wanted,garrison*CAPTIVES_PER_FIGHTER)
		var moved:Dictionary={}
		var last_error:=""
		# The road, the rations and the room at home set how many can go.
		for attempt in 8:
			if count<1: break
			var tried:Dictionary=mc.occupation_transfers.depart(civ_id,region_id,count,status,sack)
			if not tried.has("error"): moved=tried; break
			last_error=String(tried.error)
			count=count/2
		if moved.is_empty():
			refusals.append(last_error if last_error!="" else "There was nobody to take.")
		else:
			var transfer:Dictionary=(mc.occupation_transfers.data.transfers as Array).back()
			out.arrive_days=int(transfer.get("days",0))
			population=maxi(0,population-count)
			if status=="enslaved":
				out.captives=count
				parts.append("%s women and children were led away toward %s as captives, about %s on the road." % [_cap(_count(count)),home,_days(int(out.arrive_days))])
				harsh+=0.7
			else:
				out.moved=count; out.move_status=status
				parts.append("%s people of %s set out for %s %s, about %s on the road." % [_cap(_count(count)),name,home,"as our own people" if status=="citizen" else "to labour for us",_days(int(out.arrive_days))])
				if status=="penal": harsh+=0.4
	# Freeing captives already brought home from this town.
	if bool(fate.get("free",false)):
		for group:Dictionary in mc.occupation_transfers.data.groups:
			if String(group.get("origin_region",""))!=region_id or String(group.get("status",""))=="citizen": continue
			if not mc.occupation_transfers.emancipate(int(group.id)).has("error"): out.freed=int(out.freed)+1
		if int(out.freed)>0: parts.append("The captives from %s living among us are free people now, with our rights." % name)
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
	# Burning: the houses go, the people left scatter to their other towns.
	if bool(fate.get("raze",false)):
		var civ:Dictionary=world.civilizations[index]
		var ri:int=world._region_index(civ,region_id)
		if ri>=0:
			var r:Dictionary=civ.strategic_regions[ri]
			var changed:Dictionary=Governance.change(r,"raze",day)
			if changed.has("error"):
				# The administrative lock is for a governed town; a sack does not wait.
				var data:Dictionary=Governance.state(r)
				data.ruined=true; data.reconstruction=false
				data.grievance=clampf(float(data.grievance)+.25,0,1)
				data.local_institutions=maxf(0,float(data.local_institutions)-.3)
				data.last_coercive_day=day
				r.governance=data; r.damage=1.0
			else: r=changed.region
			civ.strategic_regions[ri]=r
			world.civilizations[index]=civ
			if WorldSimulation.enabled: Combat.governance(civ_id,region_id,r)
			if population>0:
				var scattered:Dictionary=world._apply_rival_displacement(world.civilizations[index],region_id,population)
				world.civilizations[index]=scattered.civilization
		out.burned=true
		parts.append("%s was burned; what was left of its people scattered." % name)
		harsh+=0.6
	# A burned or stripped town is not held: the town goes back and the garrison comes home.
	if bool(out.burned) or bool(fate.get("leave",false)) or (bool(fate.get("tribute",false)) and not bool(fate.get("hold",false)) and policy==""):
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
	# The garrison's card on the map says what was last done there.
	var held_at:int=mc._occupation_force_index(civ_id,region_id)
	if held_at>=0:
		var brief:=_note(name,out).trim_prefix(name+": ").trim_suffix(".")
		mc.occupation_forces[held_at]["fate_note"]=_cap(brief).substr(0,80)
	Chronicle.record({"key":"town_fate:%s:%d" % [region_id,day],"title":_title(name,out).substr(0,70),"text":" ".join(parts),
		"tier":"moment","kind":"war","domain":"security","action":{"kind":"court","focus":{"civ_id":civ_id}}})
	return out


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
	if int(out.captives)>0: bits.append("%s captives on the road to %s" % [_count(int(out.captives)),String(WorldSimulation.state.settlement_name)])
	if int(out.moved)>0: bits.append("%s people on the road to %s" % [_count(int(out.moved)),String(WorldSimulation.state.settlement_name)])
	if bool(out.burned): bits.append("the town burned")
	if int(out.tribute)>0: bits.append("%d Food taken" % int(out.tribute))
	if String(out.policy)!="": bits.append(String({"military_rule":"ruled by the spear","self_rule":"left to its own elders","equal_citizenship":"its people made our own","stewardship":"governed as ours","forced_labor":"its people enslaved"}.get(String(out.policy),"a new order")))
	if int(out.reinforced)>0: bits.append("the garrison now %s" % _count(int(out.garrison)))
	if int(out.freed)>0: bits.append("the captives freed")
	if bool(out.left) and not bool(out.burned): bits.append("the garrison coming home")
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
