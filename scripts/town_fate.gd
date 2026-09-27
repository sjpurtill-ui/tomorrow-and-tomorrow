extends RefCounted
## WHAT BECOMES OF A TOWN WE HOLD.
##
## After a town is taken, the god's words about it ("put the men to the
## sword", "take the women and children back to Seanstone", "burn it to the
## ground", "spare them", "take tribute and leave", "hold it") are not a new
## attack. They are orders to the garrison that holds it, carried out with
## the occupation machinery that already exists (civilization_system.gd:
## rival civilian deaths, displacement, occupation governance and razing,
## giving the town back; military_campaign.gd: war reputation, bringing the
## garrison home).
##
## Everything is bounded by what the garrison can physically do and by the
## town's real population, in the range of early warfare: a small band that
## holds a village can kill the men who do not get away, drive home the
## captives it can guard on the road (a few per fighter), and burn the
## houses. Most people flee a sack; the rest are not counted twice.
##
## Consequences are real and bounded: deaths and captives move population,
## the town is burned or kept, dread and grudges reach the people who were
## struck and, more faintly, every people that knows us; our own war
## reputation (mercy, fear, grievance) and our court's dread of the god move;
## one sober Chronicle entry tells it.
##
## apply() -> {ok, outcome (one plain note), text (the sober account),
##             killed, captives, displaced, burned, tribute, left, spared}
##          | {error}.

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
## A home village can absorb captives up to this share of its own people.
const CAPTIVES_MAX_SHARE:=0.2
## Food a band carries off as tribute, per fighter.
const TRIBUTE_PER_FIGHTER:=40.0

static func fate_words(lower:String)->Dictionary:
	## What the god's words decide about a town we hold. {} when nothing.
	var out:={}
	var re:=func(pattern:String)->bool:
		var r:=RegEx.new(); r.compile(pattern); return r.search(lower)!=null
	var kill:bool=re.call("\\b(kill|slay|slaughter|massacre|butcher|execute|cut down|put [\\w' ]{0,24}to the sword|put [\\w' ]{0,24}to death|no quarter)")
	var everyone:bool=re.call("\\b(everyone|every soul|every one of them|all of them|man, woman and child|men, women and children|women and children too|leave none|nobody alive|no one alive)\\b")
	var captive_people:bool=re.call("\\b(women|girls|wives|children|captives?|slaves?|bondservants?|young ones)\\b")
	var carry:bool=re.call("\\b(take|bring|carry|lead|drive|march|send|haul|herd|enslave|make slaves)")
	if kill: out["kill_men"]=true
	if kill and everyone: out["kill_all"]=true
	if captive_people and carry and not out.has("kill_all"): out["captives"]=true
	if re.call("\\b(burn|raze|torch|set fire|to the ground|level it|flatten|tear [\\w' ]{0,12}down|destroy (it|the town|what))"): out["raze"]=true
	if re.call("\\b(tribute|plunder|loot|sack it|take their (food|grain|stores|goods)|strip (it|the town|them))\\b"): out["tribute"]=true
	if re.call("\\b(spare|mercy|merciful|leave them (be|in peace)|let them (be|live)|no harm|harm no one|treat them (well|kindly|gently)|be gentle)\\b") and not kill: out["spare"]=true
	if re.call("\\b(hold|keep|garrison|govern|rule) (it|the town|the place|them)\\b"): out["hold"]=true
	if re.call("\\b(give it back|hand it back|leave it|withdraw|come home|pull out|abandon it)\\b") and not out.has("hold"): out["leave"]=true
	return out


static func apply(civ_id:String,region_id:String,fate:Dictionary,general:Dictionary={})->Dictionary:
	var world:Variant=WorldSimulation.world
	var mc:Variant=WorldSimulation.military
	if world==null or mc==null: return {"error":"Nobody holds that town for us."}
	var index:int=world._civilization_index(civ_id)
	if index<0: return {"error":"That town's people are no longer known to us."}
	var region:Dictionary=world.region_snapshot(civ_id,region_id)
	if region.is_empty() or String(region.get("controller",""))!="player": return {"error":"We do not hold that town."}
	var force:Dictionary=mc.occupation_force_for_region(civ_id,region_id)
	var garrison:=int(force.get("troops",0))
	if garrison<=0: return {"error":"Nobody of ours is left in the town to carry out the order."}
	var name:=String(region.get("name","the town"))
	var home:=String(WorldSimulation.state.settlement_name)
	var day:=int(WorldSimulation.state.elapsed_days)
	var population:=maxi(0,roundi(float(region.get("population",0.0))))
	var out:={"ok":true,"town":name,"garrison":garrison,"killed":0,"captives":0,"displaced":0,"burned":false,"tribute":0,"left":false,"spared":false}
	var parts:PackedStringArray=PackedStringArray()
	var harsh:=0.0
	# The men who stand, or everyone the band can catch.
	if bool(fate.get("kill_men",false)):
		var wanted:=roundi(float(population)*(MEN_SHARE if not bool(fate.get("kill_all",false)) else 1.0)*CAUGHT_SHARE)
		var can:=mini(wanted,garrison*KILLS_PER_FIGHTER*(1 if not bool(fate.get("kill_all",false)) else 2))
		if can>0:
			var civ:Dictionary=world.civilizations[index]
			var deaths:Dictionary=world._apply_rival_civilian_deaths(civ,region_id,can)
			world.civilizations[index]=deaths.civilization
			out.killed=int(deaths.dead)
			population=maxi(0,population-int(out.killed))
			if bool(fate.get("kill_all",false)): parts.append("%s people of %s were put to the sword; the rest fled into the hills." % [_count(out.killed),name])
			else: parts.append("%s men of %s were put to the sword; others got away in the dark." % [_count(out.killed),name])
			harsh+=1.0
	# Captives driven home: women and children, as many as the band can guard.
	if bool(fate.get("captives",false)):
		var ours:=int(WorldSimulation.state.population_total)
		var wanted:=roundi(float(population)*WOMEN_CHILDREN_SHARE*ROUNDED_UP_SHARE)
		var can:=mini(wanted,mini(garrison*CAPTIVES_PER_FIGHTER,maxi(1,roundi(float(ours)*CAPTIVES_MAX_SHARE))))
		if can>0:
			var taken:=_carry_off(index,region_id,can)
			if taken>0:
				WorldSimulation.state.register_population_arrivals(taken,"captives from %s" % name,{"children":0.46,"youth":0.22,"early_adults":0.22,"established_adults":0.08,"mature_adults":0.02})
				out.captives=taken
				population=maxi(0,population-taken)
				parts.append("%s women and children were led away to %s as captives." % [_cap(_count(taken)),home])
				harsh+=0.7
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
			parts.append("Their stores were already empty; there was nothing to take.")
	# Burning: the houses go, the people left scatter to their other towns.
	if bool(fate.get("raze",false)):
		var civ:Dictionary=world.civilizations[index]
		var ri:int=world._region_index(civ,region_id)
		if ri>=0:
			var r:Dictionary=civ.strategic_regions[ri]
			var changed:Dictionary=Governance.change(r,"raze",day)
			if changed.has("error"):
				# The administrative lock is for a governed town; a sack does not wait.
				var data:=Governance.state(r) as Dictionary
				data.ruined=true; data.reconstruction=false
				data.grievance=clampf(float(data.grievance)+.25,0,1)
				data.local_institutions=maxf(0,float(data.local_institutions)-.3)
				r.governance=data; r.damage=1.0
			else: r=changed.region
			civ.strategic_regions[ri]=r
			world.civilizations[index]=civ
			if WorldSimulation.enabled: Combat.governance(civ_id,region_id,r)
			if population>0:
				var moved:Dictionary=world._apply_rival_displacement(world.civilizations[index],region_id,population)
				world.civilizations[index]=moved.civilization
				out.displaced=int(moved.get("displaced",0))
		out.burned=true
		parts.append("%s was burned; %s" % [name,"its people scattered to their other towns." if int(out.displaced)>0 else "nothing is left standing."])
		harsh+=0.6
	# A burned or stripped town is not held: the garrison comes home.
	if bool(out.burned) or bool(fate.get("leave",false)) or (bool(fate.get("tribute",false)) and not bool(fate.get("hold",false))):
		var back:Dictionary=mc.evacuate_occupation(civ_id,region_id)
		if not back.has("error"):
			world.abandon_occupied_region(civ_id,region_id)
			out.left=true
			parts.append("The garrison marches home%s, about %d %s." % [" with the captives" if int(out.captives)>0 else "",int(back.get("days",0)),"day" if int(back.get("days",0))==1 else "days"])
		else:
			parts.append("The garrison stays: %s" % String(back.error))
	if bool(fate.get("spare",false)) or (parts.is_empty() and bool(fate.get("hold",false))):
		out.spared=true
		var civ:Dictionary=world.civilizations[index]
		var ri:int=world._region_index(civ,region_id)
		if ri>=0:
			var r:Dictionary=civ.strategic_regions[ri]
			var data:=Governance.state(r) as Dictionary
			data.grievance=clampf(float(data.grievance)-.1,0,1); data.trust=clampf(float(data.trust)+.1,0,1)
			r.governance=data; civ.strategic_regions[ri]=r; world.civilizations[index]=civ
			if WorldSimulation.enabled: Combat.governance(civ_id,region_id,r)
		parts.append("%s is spared. %s of ours hold it, and nobody there is harmed." % [name,_cap(_count(garrison))])
	if parts.is_empty(): return {"error":"Tell me what is to become of %s: spare it and hold it, take captives and burn it, put the men to the sword, or take tribute and leave." % name}
	_consequences(civ_id,name,out,harsh,general,day)
	out["text"]=" ".join(parts)
	out["outcome"]=_note(name,out)
	Chronicle.record({"key":"town_fate:%s:%d" % [region_id,day],"title":_title(name,out).substr(0,70),"text":String(out.text),
		"tier":"moment","kind":"war","domain":"security","action":{"kind":"court","focus":{"civ_id":civ_id}}})
	return out


## Dread and grudges; our reputation; the court's dread of the god.
static func _consequences(civ_id:String,name:String,out:Dictionary,harsh:float,general:Dictionary,day:int)->void:
	var mc:Variant=WorldSimulation.military
	var killed:=int(out.killed); var captives:=int(out.captives)
	var weight:=clampf(float(killed+captives)/60.0,0.0,1.0)
	if bool(out.spared):
		Hall._shift_relation(civ_id,0.06,-0.04)
		mc._adjust_war_reputation(0.08,0.0,-0.04)
		return
	if harsh<=0.0: return
	var what:="the men of %s you put to the sword" % name if killed>0 else ("the women and children of %s you carried off" % name if captives>0 else ("%s, which you burned" % name if bool(out.burned) else "what you took from %s" % name))
	# The people who were struck: hatred, dread and a grudge they keep.
	Hall._shift_relation(civ_id,-clampf(0.12*harsh,0.05,0.4),clampf(0.1*harsh,0.05,0.3))
	DIVINE.add_civ_dread(civ_id,clampf(0.06*harsh+0.12*weight,0.04,0.35))
	preload("res://scripts/rival_rulers.gd").grudge(civ_id,what,clampf(0.5+0.5*harsh,0.5,1.5),"town_fate:%s:%d" % [name,day])
	ForeignDiplomacy.remember(civ_id,"The god's people %s." % String({"kill":"put the men of %s to the sword","take":"carried off the women and children of %s","burn":"burned %s"}.get("kill" if killed>0 else ("take" if captives>0 else "burn"),"stripped %s")) % name)
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


static func _carry_off(index:int,region_id:String,count:int)->int:
	## Captives leave their people alive: fewer of them, none recorded as dead.
	var world:Variant=WorldSimulation.world
	var civ:Dictionary=world.civilizations[index]
	if WorldSimulation.enabled:
		var id:=Combat.owner(String(civ.id))
		var local:=Combat.local_city(String(civ.id),region_id)
		if id=="player" or not WorldSimulation.actors.has(id): return 0
		return int(WorldSimulation.scoped(id,func()->int:
			return WorldSimulation.settlements.with_city_resources(local,func()->int:
				return WorldSimulation.settlements.with_local_population(func()->int:
					return int(WorldSimulation.state.register_population_departures(count,"carried off as captives",{"children":1.6,"youth":1.3,"early_adults":1.0,"established_adults":0.5,"mature_adults":0.2,"elders":0.05}).get("count",0)),true)
			)
		))
	var ri:int=world._region_index(civ,region_id)
	if ri<0: return 0
	var regions:Array=(civ.get("strategic_regions",[]) as Array).duplicate(true)
	var region:Dictionary=regions[ri]
	var actual:=mini(count,mini(roundi(float(region.get("population",0.0))),maxi(0,roundi(float(civ.get("population",1.0))-1.0))))
	if actual<=0: return 0
	region["population"]=maxf(0.0,float(region.get("population",0.0))-float(actual))
	regions[ri]=region
	civ["strategic_regions"]=regions
	civ["population"]=maxf(1.0,float(civ.get("population",1.0))-float(actual))
	civ["cohorts"]=world._scaled_cohorts(world._remove_weighted_cohort_population(civ.get("cohorts",{}),float(actual),{"children":1.6,"youth":1.3,"early_adults":1.0,"established_adults":0.5,"mature_adults":0.2,"elders":0.05}),float(civ.population))
	world.civilizations[index]=civ
	return actual


static func _note(name:String,out:Dictionary)->String:
	var bits:PackedStringArray=PackedStringArray()
	if int(out.killed)>0: bits.append("%s killed" % _count(out.killed))
	if int(out.captives)>0: bits.append("%s captives led to %s" % [_count(out.captives),String(WorldSimulation.state.settlement_name)])
	if bool(out.burned): bits.append("the town burned")
	if int(out.tribute)>0: bits.append("%d Food taken" % int(out.tribute))
	if bool(out.spared): return "%s is spared and held." % name
	if bits.is_empty(): return "The garrison leaves %s." % name
	return "%s: %s." % [name,", ".join(bits)]


static func _title(name:String,out:Dictionary)->String:
	if bool(out.spared): return "%s Spared" % name
	if int(out.killed)>0 and bool(out.burned): return "The Sack of %s" % name
	if int(out.killed)>0: return "The Men of %s Put to the Sword" % name
	if int(out.captives)>0 and bool(out.burned): return "%s Burned, Its Women and Children Taken" % name
	if bool(out.burned): return "%s Burned" % name
	if int(out.captives)>0: return "Captives Taken From %s" % name
	return "Tribute From %s" % name


static func _memory(name:String,out:Dictionary)->String:
	var bits:PackedStringArray=PackedStringArray()
	if int(out.killed)>0: bits.append("killed %s men of %s" % [_count(out.killed),name])
	if int(out.captives)>0: bits.append("drove %s captives home" % _count(out.captives))
	if bool(out.burned): bits.append("burned %s" % name)
	if int(out.tribute)>0: bits.append("stripped its stores")
	return " and ".join(bits) if not bits.is_empty() else "left %s" % name


static func _count(n:int)->String:
	## Counted heads: words for a few, figures beyond a dozen.
	return preload("res://scripts/battle_account.gd").count_words(n) if n<=12 else str(n)


static func _cap(text:String)->String:
	return text if text.is_empty() else text.substr(0,1).to_upper()+text.substr(1)
