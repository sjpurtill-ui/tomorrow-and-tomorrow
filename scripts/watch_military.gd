extends RefCounted
## KEEPING WATCH IS THE MILITARY (docs/PEOPLE_FIRST.md, workstream E).
##
## The share of the people set to keep watch (the Defense work,
## GameState.population_allocations["Defense"]) IS the military's manpower.
## There is no separate recruiting: raising the watch share raises manpower,
## lowering it sends people home to their work. One ledger: everyone under
## arms (MilitaryCampaign._mobilized_count: at home, in bands, holding towns,
## crews, hurt, scattered or taken) is a Defense worker, and the war leader
## keeps the two equal every day (keep):
##   - short of the share: the shortfall joins the watch at home at once, raw
##     (START_DRILL), armed from the weapons stock (take_weapons) as far as it
##     goes;
##   - above the share: the surplus at home goes back to work, the lastingly
##     hurt first, then the least drilled. Bands away are never sent home on
##     its account: they count against the share until they come back (their
##     work at home stays undone: GameState.civilian_workforce_fraction).
## Drill happens within the watch over time (drill_day): each formation at
## home closes on what our people can teach it (MilitaryCampaign
## _training_quality, less for the unarmed) at the training policy's pace,
## a little higher and faster for a people given to war (martial_edge).
##
## The watch is split in two:
##   - the HOME GUARD: home_share of the watch, kept at home and spread over
##     home and the towns by their people (civilization_combat.gd
##     guard_ledger); the war leader at home (the home general) leads it;
##   - the OFFENSIVE TROOPS: the rest, in bands led by the generals (the war
##     council forms them from those at home beyond the home guard). Bands
##     away do not defend home.
## Every people follows these rules; a computer people's ruler sets its share
## and split through the same calls (set_share, set_split), and until it does
## its split follows its temper (default_home_share).
## Static helpers; preload.

const Law:=preload("res://scripts/army_levy_law.gd")
const EraWords:=preload("res://scripts/hud/era_words.gd")

## The save's mark: a military saved before the watch was the army folds its
## recruits and trainees into the watch on its first day (fold).
const VERSION:=1
## How drilled a person is on the day they join the watch: the least the
## combat engine knows (combat_simulator holds every block at 0.25).
const START_DRILL:=0.25
## The watch is filled or emptied to the share only when it is off by this
## share of it, and by at least SLACK_MIN people, so a day's swing of one in
## who can work does not send people to and fro (the ruler's own word is kept
## to the person: keep's `exact`).
const SLACK:=0.02
const SLACK_MIN:=2
## The player's split until they choose one: a fifth of the watch stays home,
## as the war council has always kept at home (war_council.gd WATCH_SHARE);
## the offensive troops at home stand with them until they are sent out.
const DEFAULT_HOME_SHARE:=0.2
## The split's step on the screen (a tenth of the watch).
const HOME_SHARE_STEP:=0.1
## A LITTLE EXTRA FOR A PEOPLE GIVEN TO WAR (the user, 2026-10-02: "The fun
## of the game is likely to be in the extreme scenarios... Don't make it go
## crazy. Make it be a little extra."). Pre-modern peoples kept 3 to 7 in
## 100 of their people under arms (army_levy_law.gd); a people that keeps
## more on watch than MARTIAL_FROM of its people has old hands enough to
## drill the young harder. Its edge (martial_edge, 0..1) grows to its whole
## at MARTIAL_FULL: the drill it reaches rises by up to MARTIAL_DRILL and its
## drill goes up to MARTIAL_PACE faster. A balanced people has none, so it
## stays within the historical ranges; the all-in people pays in hands taken
## from food, making and learning, and its weapons cost as much as anyone's.
const MARTIAL_FROM:=0.05
const MARTIAL_FULL:=0.20
const MARTIAL_DRILL:=0.08
const MARTIAL_PACE:=0.25


# --------------------------------------------------------------------------
# Reading the watch
# --------------------------------------------------------------------------

## The watch: those set to keep watch (Defense workers). The military's
## manpower.
static func manpower(mc:Variant=null)->int:
	return maxi(0,int(WorldSimulation.state.population_allocations.get("Defense",0)))

## Those keeping watch who are at home: the watch less everyone serving
## away from it (bands and their hurt, garrisons, crews, the scattered and
## taken, drafts on the road).
static func at_home(mc:Variant)->int:
	var away:=maxi(0,serving(mc)-maxi(0,int(mc.home_army.get("troops",0)))-maxi(0,int(mc.home_army.get("wounded_pool",0)))-maxi(0,int(mc.aggregate_recruits))-maxi(0,int(mc._queued_trainees()))-maxi(0,int(mc.training_injury_pool)))
	return maxi(0,manpower(mc)-away)

## Everyone under arms, anywhere (the personnel ledger's total).
static func serving(mc:Variant)->int:
	return maxi(0,int(mc._mobilized_count()))

## The home guard's share of the watch (0..1): the ruler's choice, else the
## default (the player's, or a computer ruler's by temper).
static func home_share(mc:Variant)->float:
	var chosen:Variant=mc.get("watch_home_share")
	if chosen!=null and float(chosen)>=0.0:return clampf(float(chosen),0.0,1.0)
	var auto:Variant=mc.get("watch_home_auto")
	if auto!=null and float(auto)>=0.0:return clampf(float(auto),0.0,1.0)
	return DEFAULT_HOME_SHARE

## A computer ruler's split by temper (leader_personality axes 0..1): the
## bold and assertive keep fewer at home, the caring more; at war fewer stay.
## About the player's fifth for an even temper.
static func default_home_share(personality:Dictionary,at_war:bool=false)->float:
	var assertive:=clampf(float(personality.get("assertiveness",.5)),0.0,1.0)
	var risk:=clampf(float(personality.get("risk_tolerance",.5)),0.0,1.0)
	var empathy:=clampf(float(personality.get("empathy",.5)),0.0,1.0)
	return snappedf(clampf(.35-assertive*.2-risk*.1+empathy*.15-(.1 if at_war else 0.0),.1,.6),.05)

## The home guard the split asks for: its share of everyone serving (the
## watch under arms, at home or away; whole people).
static func home_guard_target(mc:Variant)->int:
	return roundi(float(serving(mc))*home_share(mc))

## The home guard standing now: those at home, up to the split's share. 0
## while home is held by an enemy.
static func home_guard(mc:Variant)->int:
	if mc.recovery.home_unavailable():return 0
	return mini(maxi(0,int(mc.home_army.get("troops",0))),home_guard_target(mc))

## Those at home beyond the home guard: offensive troops not yet in a band,
## whom the war council may send.
static func offensive_at_home(mc:Variant)->int:
	return maxi(0,int(mc.home_army.get("troops",0))-home_guard(mc))

## How far a people is given to war (0..1): nothing up to MARTIAL_FROM of
## its people keeping watch, all of it at MARTIAL_FULL.
static func martial_edge(mc:Variant=null)->float:
	var population:=maxi(1,int(WorldSimulation.state.population_total))
	var share:=float(manpower(mc))/float(population)
	return clampf((share-MARTIAL_FROM)/(MARTIAL_FULL-MARTIAL_FROM),0.0,1.0)

## Everything the military screen shows, in the engine's own numbers:
## {watch, population, able, share (of the people), work_share (of those who
## can work), serving, gap (watch - serving), home_share, guard_target, guard
## (standing at home), at_home (everyone at home), offensive (the rest of
## those serving), offensive_home (at home, not in a band), away (in bands),
## held (holding towns), crews, hurt, missing, drill (0..1, at home), armed
## (0..1 of the gear the watch needs), bands:[{army_id, name, men, general}]}.
static func reading(mc:Variant)->Dictionary:
	var state=WorldSimulation.state
	var population:=maxi(0,int(state.population_total))
	var able:=maxi(0,int(state.able_population()))
	var watch:=manpower(mc)
	var ledger:Dictionary=mc.personnel_ledger()
	var total:=int(ledger.total)
	var at_home:=maxi(0,int(mc.home_army.get("troops",0)))
	var guard:=home_guard(mc)
	var bands:Array=[]
	var away:=0
	for army in mc.field_armies:
		if not army is Dictionary or int((army as Dictionary).get("troops",0))<=0:continue
		var men:=int((army as Dictionary).troops)
		away+=men
		var commander:Dictionary=(army as Dictionary).get("commander",{}) if (army as Dictionary).get("commander") is Dictionary else {}
		bands.append({"army_id":int((army as Dictionary).get("army_id",0)),"name":String((army as Dictionary).get("name","Band")),"men":men,"general":String(commander.get("name",""))})
	var held:=int(ledger.get("occupation",0))
	var crews:=int(ledger.get("naval_air",0))
	var hurt:=int(ledger.get("recovering",0))
	var missing:=int(ledger.get("missing",0))
	var drill:=drill_of(mc.home_army.get("formations",[]))
	var offensive_home:=maxi(0,at_home-guard)
	var offensive:=offensive_home+away+held
	var chosen:Variant=mc.get("watch_home_share")
	return {"watch":watch,"population":population,"able":able,
		"share":float(watch)/float(population) if population>0 else 0.0,
		"work_share":float(watch)/float(able) if able>0 else 0.0,
		"serving":total,"gap":watch-total,"home_share":home_share(mc),"chosen":chosen!=null and float(chosen)>=0.0,
		"guard_target":home_guard_target(mc),"guard":guard,"at_home":at_home,
		"offensive":offensive,"offensive_home":offensive_home,"away":away,"held":held,"crews":crews,
		# Serving but neither guarding nor ready to fight: hurt, scattered or
		# taken, crews of boats and wings, in drill or walking out to a band.
		"not_ready":maxi(0,total-guard-offensive),
		"hurt":hurt,"missing":missing,"drill":drill,"armed":armed_of(mc.home_army.get("formations",[])),"bands":bands,
		# A people given to war drills a little higher and faster.
		"martial":martial_edge(mc),"martial_drill":MARTIAL_DRILL*martial_edge(mc),"martial_pace":MARTIAL_PACE*martial_edge(mc)}

## How drilled these formations are, weighted by their men (0..1).
static func drill_of(formations:Array)->float:
	var men:=0;var sum:=0.0
	for f in formations:
		if not f is Dictionary:continue
		var count:=maxi(0,int((f as Dictionary).get("count",0)))
		men+=count;sum+=clampf(float((f as Dictionary).get("training",0.0)),0.0,1.0)*float(count)
	return sum/float(men) if men>0 else 0.0

## The share of the gear these formations need that is in their hands (0..1).
static func armed_of(formations:Array)->float:
	var issued:=0;var required:=0
	for f in formations:
		if not f is Dictionary:continue
		var formation:Dictionary=f
		issued+=mini(int(formation.get("equipment",0)),int(formation.get("equipment_required",formation.get("count",0))))
		required+=int(formation.get("equipment_required",formation.get("count",0)))
	return clampf(float(issued)/float(required),0.0,1.0) if required>0 else 1.0


# --------------------------------------------------------------------------
# Arms: the one accessor (workstream D's weapons stock)
# --------------------------------------------------------------------------

## The kit the war leader arms the watch with: {unit, item}. The best line
## kit in store (Law.kit) while some of it is held and it is no worse than
## what the makers make; else what the makers make, when it arms a line unit
## of ours with its practice learned (weapons_stock.gd made_kit: tied to the
## makers' age, never a prototype); else Law.kit (what the workshops arm);
## the plain levy otherwise.
static func arms_kit(mc:Variant)->Dictionary:
	var made:Dictionary=_arms().call("made_kit",mc)
	var kit:Dictionary=Law.kit(mc)
	var stored:=String(kit.get("item",""))
	if not made.is_empty():
		var in_store:=stored!="" and stored!="improvised" and int((mc.military_inventory as Dictionary).get(stored,0))>0
		if not in_store or Law.Kit.preference(mc,stored,{})<Law.Kit.preference(mc,String(made.item),{}):return made
	if String(kit.get("item",""))=="":kit={"unit":"levy","item":"improvised"}
	return kit

## THE ONE WEAPONS ACCESSOR. Every set of arms the watch takes up, hands back
## or loses passes through these five, and they are workstream D's weapons
## stock (scripts/weapons_stock.gd, called in the people's own scope):
## weapons_held -> weapons_held(item), take_weapons -> take_weapons(n, item),
## return_weapons -> return_weapons(n, item), lose_weapons ->
## lose_weapons(n, item); weapons_stock.weapons_issued() reads
## weapons_carried. A set the makers made becomes the watch's own kit
## (arms_kit().item) in a fighter's hands; kits handed back go to the
## armoury (MilitaryCampaign military_inventory), never traded. Fighters
## without a set fight with what comes to hand (combat_simulator: the
## unarmed share of a formation).
static var _stock:GDScript
static func _arms()->GDScript:
	if _stock==null:_stock=load("res://scripts/weapons_stock.gd") as GDScript
	return _stock

## Sets held that arm the watch's kit (or the kit named): made sets and the
## armoury's kits of it.
static func weapons_held(mc:Variant,item:String="")->int:
	if item=="":item=String(arms_kit(mc).item)
	return int(_arms().call("weapons_held",item,mc))

## Takes up to `n` sets of the watch's kit (or the kit named) for the watch:
## made sets first, then the armoury's; returns how many were taken.
static func take_weapons(mc:Variant,n:int,item:String="")->int:
	if item=="":item=String(arms_kit(mc).item)
	return int(_arms().call("take_weapons",maxi(0,n),item,mc))

## `n` sets the watch hands back as its people go back to work: to the
## armoury, as the kit they are; returns how many went back.
static func return_weapons(mc:Variant,n:int,item:String="")->int:
	if item=="":item=String(arms_kit(mc).item)
	return int(_arms().call("return_weapons",maxi(0,n),item,mc))

## `n` sets the watch lost with its fallen or in a rout (already gone from
## the formations that carried them): kept on the arms record. Returns n.
static func lose_weapons(mc:Variant,n:int,item:String="")->int:
	if item=="":item=String(arms_kit(mc).item)
	return int(_arms().call("lose_weapons",maxi(0,n),item,mc))

## Those at home with what comes to hand take up made arms as the sets come,
## only as many men as there are sets truly spare for the weapon their unit
## can take up (weapons_stock.gd rekit_item: the first on the makers' age's
## list it can carry with its practice learned, a spear for the levy): the
## sets held for it (made sets and the armoury's kits of it, weapons_held)
## less every set already owed to that weapon at home (formations of it not
## yet fully armed, new drill orders not yet reserved). They split off into
## a formation of that weapon, their drill kept, their old arms back to the
## armoury; the day's delivery then arms them
## (MilitaryCampaign._deliver_inventory_replacements). The rest keep what
## comes to hand. So an older save's levy is armed as the makers work, or
## from the armoury's own kits, never left waiting and never stripped of more
## arms than it is given. Returns the men re-kitted.
static func rekit_for_made(mc:Variant)->int:
	if (_arms().call("made_kit",mc) as Dictionary).is_empty():return 0
	var men:=0
	var formations:Array=(mc.home_army.get("formations",[]) as Array).duplicate(true)
	var additions:Array=[]
	var spare:={}
	for index in formations.size():
		var formation:Dictionary=formations[index]
		if String(formation.get("weapon","improvised"))!="improvised":continue
		var item:=String(_arms().call("rekit_item",mc,formation))
		if item=="":continue
		if not spare.has(item):spare[item]=weapons_held(mc,item)-_owed_at_home(mc,item)
		if int(spare[item])<=0:continue
		var unit:=String(formation.get("unit","levy"))
		var count:=int(formation.get("count",0))
		var per:=float(mc._equipment_required_for(unit,count))/maxf(1.0,float(count))
		var moving:=mini(count,floori(float(spare[item])/maxf(0.0001,per)+0.000001))
		if moving<=0:continue
		var need:int=mc._equipment_required_for(unit,moving)
		# Their old arms go back to the armoury; the rest keep theirs.
		var gear:=int(formation.get("equipment",0))
		var back:=mini(gear,roundi(float(gear)*float(moving)/maxf(1.0,float(count))))
		return_weapons(mc,back,"improvised")
		var authorized:=int(formation.get("authorized_count",count))
		formation["count"]=count-moving
		formation["authorized_count"]=maxi(int(formation.count),authorized-moving)
		formation["equipment"]=gear-back
		formation["equipment_required"]=mc._equipment_required_for(unit,int(formation.authorized_count))
		formations[index]=formation
		var target:=_formation_of(mc,unit,item)
		additions.append({"id":int(target.get("id",-1)) if not target.is_empty() else int(mc.next_formation_id),"unit":unit,"weapon":item,"count":moving,"authorized_count":moving,
			"equipment":0,"equipment_required":need,"ammunition":0,"ammunition_required":mc._ammunition_required_for(item,need),
			"training":float(formation.get("training",START_DRILL)),"experience":float(formation.get("experience",0.0)),"personnel_condition":float(formation.get("personnel_condition",1.0))})
		if target.is_empty():mc.next_formation_id=int(mc.next_formation_id)+1
		spare[item]=int(spare[item])-need
		men+=moving
	if additions.is_empty():return 0
	mc.home_army["formations"]=formations.filter(func(f:Dictionary)->bool:return int(f.get("count",0))>0)
	mc._rebuild_home_army_with(additions)
	return men

## Sets already owed to a weapon at home: what its formations still lack of
## their need, and what new drill orders for it have not yet reserved.
static func _owed_at_home(mc:Variant,item:String)->int:
	var owed:=0
	for f in mc.home_army.get("formations",[]):
		if not f is Dictionary or String((f as Dictionary).get("weapon",""))!=item:continue
		owed+=maxi(0,int((f as Dictionary).get("equipment_required",(f as Dictionary).get("count",0)))-int((f as Dictionary).get("equipment",0)))
	for order in mc.training_queue:
		if not order is Dictionary or String((order as Dictionary).get("weapon",""))!=item:continue
		var o:Dictionary=order
		if String(o.get("mode",""))=="field_draft" or (String(o.get("mode",""))=="reinforce" and int(o.get("target_formation_id",-1))>=0):continue
		owed+=maxi(0,int(mc._equipment_required_for(String(o.get("unit","levy")),int(o.get("count",0))))-int(o.get("reserved_equipment",0)))
	return owed

## Sets the watch carries now, read from its formations wherever they stand
## (home, bands, garrisons): one ledger, never a counter kept apart.
static func weapons_carried(mc:Variant)->int:
	var carried:=0
	for force in [mc.home_army]+(mc.field_armies as Array)+(mc.occupation_forces as Array):
		if not force is Dictionary:continue
		for f in (force as Dictionary).get("formations",[]):
			if not f is Dictionary:continue
			var formation:Dictionary=f
			if String(formation.get("weapon","improvised"))=="improvised":continue
			carried+=mini(maxi(0,int(formation.get("equipment",0))),int(formation.get("equipment_required",formation.get("count",0))))
	return carried


# --------------------------------------------------------------------------
# Setting the watch
# --------------------------------------------------------------------------

## Sets the home guard's share of the watch (0..1). {ok, home_share, guard,
## said}. Any people, in its own scope.
static func set_split(mc:Variant,share:float)->Dictionary:
	if not is_finite(share):return {"error":"The split must be a share between 0 and 1."}
	mc.set("watch_home_share",clampf(share,0.0,1.0))
	var guard:=home_guard_target(mc)
	# Fewer at home: nothing moves now; the war council may send more.
	# More at home than stand there: idle bands come home to guard it.
	var called:=recall_for_guard(mc)
	return {"ok":true,"home_share":home_share(mc),"guard":guard,"called":called,
		"said":"%d%% of the watch guard home and the towns: %s of %s. The rest, %s, are for the bands." % [roundi(home_share(mc)*100.0),EraWords.grouped(guard),EraWords.grouped(manpower(mc)),EraWords.grouped(maxi(0,manpower(mc)-guard))]}

## The home guard asks for more than stand at home: bands with nothing to do
## come home to guard it, those at home at once (they fold into the host),
## those out on the road home, until enough are home or coming. Bands on an
## errand stay out; so do bands the ruler formed by an order ("stand ready
## at the camp": by_order) and bands guarding a town of ours (war_council
## _guards_ours). Nothing is called while a fight at home is still being
## fought: its result replaces the host's formations. Returns the men called.
static func recall_for_guard(mc:Variant)->int:
	if home_fight_pending(mc):return 0
	var short:=home_guard_target(mc)-maxi(0,int(mc.home_army.get("troops",0)))
	if short<=0:return 0
	var council:=load(Law.COUNCIL_PATH) as GDScript
	var called:=0
	for army in (mc.field_armies as Array).duplicate():
		if short<=0:break
		if not army is Dictionary:continue
		var band:Dictionary=army
		var men:=int(band.get("troops",0))
		if men<=0:continue
		if bool(band.get("by_order",false)) or bool(council.call("_guards_ours",band)):continue
		if Law.home_band(mc,band):
			if not mc.disband_field_army(int(band.get("army_id",0))).has("error"):short-=men;called+=men
			continue
		if String(band.get("destination_id",""))=="player_home" and String(band.get("status",""))=="moving":short-=men;continue
		if not bool(council.call("_idle",band)):continue
		if bool(council.call("_at_home",band)):
			if not mc.disband_field_army(int(band.get("army_id",0))).has("error"):short-=men;called+=men
		elif bool(council.call("_send_home",band)):short-=men;called+=men
	return called

## Moves `n` people onto the watch (n<0: off it, back to other work), and
## keeps them there. When the ruler sets the daily work by hand
## (manual_work.gd), it is the ruler's own split, the People view's lever.
## Otherwise the people's leaders share out the work and keep the watch at
## the share set here (hold_share, GovernmentPeopleSystem's daily split), so
## setting the watch never takes the rest of the work out of their hands.
## The same for every people. Returns the people moved.
static func move(n:int)->int:
	if n==0:return 0
	var mc:Variant=WorldSimulation.military
	var state=WorldSimulation.state
	var able:=maxi(1,int(state.able_population()))
	var before:=manpower()
	var target:=clampi(before+n,0,able)
	if WorldSimulation.actor_id=="player" and preload("res://scripts/manual_work.gd").manual():
		preload("res://scripts/manual_work.gd").move("Defense",target-before)
	else:
		var share:=float(target)/float(able)*100.0
		state.adjust_population_role_percentage("Defense",share-float(state.population_allocation_percentages.get("Defense",0.0)))
		# Exact, whatever the rounding of the other tasks.
		var moved:=manpower()-before
		if moved!=target-before:_set_defense(state,target)
	if mc!=null:mc.set("watch_work_share",float(manpower())/float(able))
	return manpower()-before

## Puts exactly `target` on the watch, taking from or giving to the task
## with the most people (whole people, the ledger's own count).
static func _set_defense(state:Variant,target:int)->void:
	var allocations:Dictionary=state.population_allocations
	var gap:=target-int(allocations.get("Defense",0))
	while gap!=0:
		var donor:="";var most:=-1
		for role in allocations:
			if String(role)=="Defense":continue
			if int(allocations[role])>most:most=int(allocations[role]);donor=String(role)
		if donor=="" or (gap>0 and most<=0):break
		var step:=1 if gap>0 else -1
		allocations[donor]=int(allocations[donor])-step
		allocations["Defense"]=int(allocations.get("Defense",0))+step
		gap-=step

## The leaders' daily split (GovernmentPeopleSystem) keeps the watch at the
## share the ruler set (watch_work_share of those who can work, in
## percentages that add to 100); the other tasks keep their proportions.
## Nothing changes when no share is set (-1).
static func hold_share(percentages:Dictionary)->void:
	var mc:Variant=WorldSimulation.military
	if mc==null:return
	# The leaders' own choice for the watch before any share the ruler set
	# (their path's weight: work_paths.gd), for a computer ruler to read.
	var sum:=0.0
	for role in percentages:sum+=maxf(0.0,float(percentages[role]))
	if sum>0.0:mc.set("watch_path_share",maxf(0.0,float(percentages.get("Defense",0.0)))/sum)
	var held:Variant=mc.get("watch_work_share")
	if held==null or float(held)<0.0:return
	var want:=clampf(float(held),0.0,0.9)*100.0
	var others:=0.0
	for role in percentages:
		if String(role)!="Defense":others+=maxf(0.0,float(percentages[role]))
	if others<=0.0:return
	var total:=others+maxf(0.0,float(percentages.get("Defense",0.0)))
	var room:=total-total*want/100.0
	for role in percentages:
		if String(role)!="Defense":percentages[role]=maxf(0.0,float(percentages[role]))*room/others
	percentages["Defense"]=total*want/100.0

## Sets the watch to `share` of the people (0..1): moves people onto or off
## it. {ok, moved, watch, said}.
static func set_share(mc:Variant,share:float)->Dictionary:
	if not is_finite(share) or share<0.0:return {"error":"The share must be 0 or more."}
	var population:=maxi(0,int(WorldSimulation.state.population_total))
	var want:=roundi(float(population)*share)
	var moved:=move(want-manpower(mc))
	return {"ok":true,"moved":moved,"watch":manpower(mc),"said":share_words(mc)}

## "48 keep watch: 6% of the people (1 in 10 of those who can work)."
static func share_words(mc:Variant)->String:
	var r:=reading(mc)
	var one_in:=roundi(1.0/float(r.work_share)) if float(r.work_share)>0.0 else 0
	return "%s keep watch: %s of the people%s." % [EraWords.grouped(int(r.watch)),percent(float(r.share)),(" (1 in %d of those who can work)" % one_in) if one_in>0 else ""]

## WHAT KEEPING WATCH DOES (the People view's row, workstream F): now and
## with ten more, in the engine's numbers. {role, now, ten_more, watch,
## guard, offensive, drill, armed, drill_days}.
static func role_effect(mc:Variant=null)->Dictionary:
	if mc==null:mc=WorldSimulation.military
	var r:=reading(mc)
	var unit:=String(arms_kit(mc).unit)
	var pace:=float(mc._training_rate())*float(mc.training_staff.policy("army",WorldSimulation.actor_id).get("intake",1.0))
	var days:=roundi(float(mc.UnitCatalog.training_days(unit))/pace) if pace>0.0 else -1
	var guard_more:=roundi(10.0*float(r.home_share))
	var now:="%s keep watch: they are the army. %s guard home and the towns; %s are for the bands. Drilled %d in 100, armed %d in 100." % [EraWords.grouped(int(r.watch)),EraWords.grouped(int(r.guard)),EraWords.grouped(int(r.offensive)),roundi(float(r.drill)*100.0),roundi(float(r.armed)*100.0)]
	if float(r.martial)>0.0:now+=" Given to war: their drill reaches %d in 100 higher." % roundi(float(r.martial_drill)*100.0)
	var more:="Ten more: 10 more under arms at once (%d to the home guard, %d for the bands), raw at first%s; 10 fewer at other work." % [guard_more,10-guard_more,(", most of their drill in about %d days" % days) if days>0 else ", not drilled while drill is stopped"]
	# The People view's row (role_effects.gd), twelve words or fewer each:
	# the army, and the safety ten more lift the people toward
	# (consequence_engine.gd: +42 points for every 5 in 100 on watch).
	var Impact:=preload("res://scripts/task_impact.gd")
	var pop:=maxf(1.0,float(WorldSimulation.state.population_exact))
	var lift:=func(people:float)->int:return roundi(people/maxf(1.0,pop*Impact.WATCH_SHARE)*Impact.WATCH_SAFETY*100.0)
	# Order is kept by the watch at home (consequence_engine.gd), not its bands away.
	var keeping:=float(at_home(mc))
	var short_now:="%s keep watch: %s guard home, %s for bands." % [EraWords.grouped(int(r.watch)),EraWords.grouped(int(r.guard)),EraWords.grouped(maxi(0,int(r.watch)-int(r.guard)))]
	# Ten more join at home: the home guard's share of them is spread over
	# the towns by their people, the rest stand at home until sent out.
	var Combat:=preload("res://scripts/civilization_combat.gd")
	var home:=Combat._home_record()
	var here:=1.0
	if not home.is_empty():
		var people:=0.0;var at_home:=0.0
		for city:Dictionary in WorldSimulation.state.player_settlements:
			if not Combat.keeps_watch(city):continue
			var n:=maxf(0.0,float(WorldSimulation.settlements._settlement_population(city)))
			people+=n
			if String(city.get("id",""))==String(home.get("id","")):at_home=n
		if people>0.0:here=at_home/people
	var home_more:=roundi(10.0*(1.0-float(r.home_share))+10.0*float(r.home_share)*here)
	var short_more:="Ten more: safety +%d points; guard at home +%d." % [int(lift.call(keeping+10.0))-int(lift.call(keeping)),home_more]
	return {"role":"Defense","now":short_now,"plus_ten":short_more,"detail":now,"ten_more":more,"watch":int(r.watch),"guard":int(r.guard),"offensive":int(r.offensive),"drill":float(r.drill),"armed":float(r.armed),"drill_days":days}


## A share in plain words: "6%", "0.4%" below one in a hundred.
static func percent(share:float)->String:
	if share>0.0 and share<0.0095:return "%.1f%%" % (share*100.0)
	return "%d%%" % roundi(share*100.0)


# --------------------------------------------------------------------------
# The war leader's daily keeping
# --------------------------------------------------------------------------

## Every day, every people: an older save's recruits and trainees fold into
## the watch, nobody waits to be called up, the watch is filled or emptied
## to the share at home, and those at home drill. `exact`: the ruler's own
## word, kept to the person (else within SLACK). {joined, released, folded}.
static func keep(mc:Variant,day:int,exact:=false)->Dictionary:
	var out:={"joined":0,"released":0,"folded":0}
	if mc.recovery.home_unavailable():return out
	# Nothing moves at home while any fight against our home is still being
	# fought, ours or another people's: those mustered for it, the guard
	# posted in our other towns among them, come back to it after.
	if home_fight_pending(mc):return out
	if not bool(mc.get("watch_folded")):out.folded=fold(mc)
	# A computer people's split follows its ruler's temper until set (its
	# ruler's orders keep it to the plan: civilization_controller
	# military_orders), with its own wars in its own scope.
	if WorldSimulation.actor_id!="player" and float(mc.get("watch_home_share"))<0.0 and float(mc.get("watch_home_auto"))<0.0:
		var personality:Dictionary=preload("res://scripts/leader_personality.gd").of_owner(WorldSimulation.actor_id)
		mc.set("watch_home_auto",default_home_share(personality,_at_war()))
	# Nobody waits to be called up: whoever is waiting joins the watch.
	if int(mc.aggregate_recruits)>0:out.folded=int(out.folded)+join_waiting(mc)
	var watch:=manpower(mc)
	var have:=serving(mc)
	var slack:=1 if exact else maxi(SLACK_MIN,ceili(float(watch)*SLACK))
	if watch-have>=slack or (watch>have and have==0):
		out.joined=join(mc,watch-have)
	elif have-watch>=slack:
		out.released=release(mc,have-watch)
	return out

## Whether the people in scope is at war with anyone, by its own world's
## record (each people's world holds its own relations).
static func _at_war()->bool:
	var world=WorldSimulation.world
	if world==null:return false
	for civ in world.civilizations:
		if civ is Dictionary and bool(((civ as Dictionary).get("player_relation",{}) as Dictionary).get("at_war",false)):return true
	return false

## Whether a fight against our home is still being fought: ours (the home
## host's battle) or another people's against our home town.
static func home_fight_pending(mc:Variant)->bool:
	if mc._home_battle_running():return true
	return not _their_fights_at_home(mc).is_empty()

## Another people's battles still being fought against our home town: their
## engagements whose target (civilization_combat.force_for owned_target) is
## our home host.
static func _their_fights_at_home(mc:Variant)->Array:
	var out:Array=[]
	var me:=WorldSimulation.actor_id
	var home_id:=String(preload("res://scripts/civilization_combat.gd")._home_record().get("id",""))
	var ids:Array=WorldSimulation.actors.keys();ids.append("player")
	for id:String in ids:
		if id==me:continue
		var military:Variant=MilitaryCampaign if id=="player" else (WorldSimulation.actors[id] as Dictionary).systems.get("MilitaryCampaign")
		if military==null or military==mc:continue
		# Every battle they fight, their generals' too (MilitaryCampaign
		# engagements: their own and command_hierarchy's).
		for operation in military.engagements.values():
			if not operation is Dictionary:continue
			var threat:Dictionary=(operation as Dictionary).get("threat",{}) if (operation as Dictionary).get("threat") is Dictionary else {}
			var target:Dictionary=threat.get("owned_target",{}) if threat.get("owned_target") is Dictionary else {}
			if String(target.get("actor",""))!=me or int(target.get("field_id",0))!=0:continue
			var city:=String(target.get("city_id",""))
			if city!="" and city!=home_id:continue
			out.append(operation)
	return out

## The home guard posted in our other towns for each fight at home still
## being fought: the posted_guard records those fights give back to home's
## formations after (MilitaryCampaign._return_posted_guard). While one is
## pending, a town's guard losses come off it, not off the host at home
## (whose formations the fight's result replaces).
static func pending_home_postings(mc:Variant)->Array:
	var out:Array=[]
	for engagement in mc.own_battles():
		var fight:Dictionary=engagement
		if String(fight.get("home_force_kind","field"))!="field":continue
		var side:Dictionary=fight.get(String(fight.get("home_side","defender")),{}) if fight.get(String(fight.get("home_side","defender"))) is Dictionary else {}
		if side.get("posted_guard") is Dictionary and not (side.posted_guard as Dictionary).is_empty():out.append(side.posted_guard)
	for operation in _their_fights_at_home(mc):
		var force:Variant=((operation as Dictionary).get("threat",{}) as Dictionary).get("enemy_force",{})
		if force is Dictionary and (force as Dictionary).get("posted_guard") is Dictionary and not ((force as Dictionary).posted_guard as Dictionary).is_empty():out.append((force as Dictionary).posted_guard)
	return out

## Men of a posted guard record (MilitaryCampaign._take_posted_guard), its
## pools aside.
static func posted_men(posted:Dictionary)->int:
	var men:=0
	for key in posted:
		if String(key)=="_pools" or not posted[key] is Dictionary:continue
		men+=maxi(0,int((posted[key] as Dictionary).get("count",0)))
	return men

## `n` people join the watch at home, raw, armed from the stock as far as it
## goes. Returns those who joined.
static func join(mc:Variant,n:int)->int:
	if n<=0:return 0
	if mc.home_army.is_empty():mc.home_army=mc._empty_home_army()
	var kit:=arms_kit(mc)
	var unit:=String(kit.unit);var item:=String(kit.item)
	var sets:int=mc._equipment_required_for(unit,n)
	var armed:=take_weapons(mc,sets,item)
	var target:=_formation_of(mc,unit,item)
	var addition:={"id":int(target.get("id",-1)) if not target.is_empty() else int(mc.next_formation_id),"unit":unit,"weapon":item,"count":n,"authorized_count":n,
		"equipment":armed,"equipment_required":sets,"ammunition":0,"ammunition_required":mc._ammunition_required_for(item,sets),
		"training":START_DRILL,"experience":0.0,"personnel_condition":float(mc._trainee_condition())}
	if target.is_empty():mc.next_formation_id=int(mc.next_formation_id)+1
	mc._rebuild_home_army_with([addition])
	mc.army_changed.emit(mc.home_army.duplicate(true))
	return n

## The largest formation at home of this kit, or {}.
static func _formation_of(mc:Variant,unit:String,item:String)->Dictionary:
	var best:={}
	for f in mc.home_army.get("formations",[]):
		if not f is Dictionary:continue
		var formation:Dictionary=f
		if String(formation.get("unit",""))!=unit or String(formation.get("weapon",""))!=item:continue
		if bool(formation.get("emergency_militia",false)):continue
		if best.is_empty() or int(formation.get("count",0))>int(best.get("count",0)):best=formation
	return best

## Those waiting (an older save's recruits, a court levy's leftovers, the
## mended back from their wounds) join the watch at home. They already
## count among those serving, so the share does not move.
static func join_waiting(mc:Variant)->int:
	var waiting:=maxi(0,int(mc.aggregate_recruits))
	if waiting<=0:return 0
	mc.aggregate_recruits=0
	return join(mc,waiting)

## The surplus at home goes back to work: the lastingly hurt first, then the
## least drilled at home. Never a band away, never a garrison. Returns those
## released.
static func release(mc:Variant,n:int)->int:
	if n<=0:return 0
	var released:=0
	released+=mc._demobilize_disabled(n)
	var waiting:=mini(n-released,maxi(0,int(mc.aggregate_recruits)))
	mc.aggregate_recruits=int(mc.aggregate_recruits)-waiting;released+=waiting
	if released<n:released+=_release_least_drilled(mc,n-released)
	if released>0:mc.army_changed.emit(mc.home_army.duplicate(true))
	return released

static func _release_least_drilled(mc:Variant,n:int)->int:
	var formations:Array=(mc.home_army.get("formations",[]) as Array).duplicate(true)
	var order:Array=range(formations.size())
	order.sort_custom(func(a:int,b:int)->bool:return float((formations[a] as Dictionary).get("training",0.0))<float((formations[b] as Dictionary).get("training",0.0)))
	var left:=n
	for index:int in order:
		if left<=0:break
		var formation:Dictionary=formations[index]
		var count:=int(formation.get("count",0))
		var off:=mini(left,count)
		if off<=0:continue
		var gear:=mini(int(formation.get("equipment",0)),roundi(float(int(formation.get("equipment",0)))*float(off)/maxf(1.0,float(count))))
		return_weapons(mc,gear,String(formation.get("weapon","improvised")))
		formation["count"]=count-off
		formation["authorized_count"]=maxi(int(formation.count),int(formation.get("authorized_count",count))-off)
		formation["equipment"]=int(formation.get("equipment",0))-gear
		formation["equipment_required"]=mc._equipment_required_for(String(formation.get("unit","levy")),int(formation.authorized_count))
		formations[index]=formation
		left-=off
	var kept:Array=formations.filter(func(f:Dictionary)->bool:return int(f.get("count",0))>0)
	mc.home_army["formations"]=kept
	var released:=n-left
	mc.home_army["troops"]=maxi(0,int(mc.home_army.get("troops",0))-released)
	mc._refresh_readiness()
	return released

## Drill within the watch: each formation at home closes on what our people
## can teach it (MilitaryCampaign._training_quality, less for the unarmed:
## 0.72 + 0.28 x gear in hand) at the training policy's pace, a share
## mc._training_rate() / training_days(unit) of the gap a day, slower when
## the people go hungry. Nothing is drilled while home is fought over or the
## policy suspends it. Returns the mean drill after.
static func drill_day(mc:Variant)->float:
	var formations:Array=mc.home_army.get("formations",[])
	if formations.is_empty() or mc.recovery.home_unavailable() or mc._home_battle_running():return drill_of(formations)
	var policy:Dictionary=mc.training_staff.policy("army",WorldSimulation.actor_id)
	var intake:=float(policy.get("intake",1.0))
	if intake<=0.0:return drill_of(formations)
	var fed:=clampf(float(WorldSimulation.state.food_security),0.3,1.0)
	var edge:=martial_edge(mc)
	var rate:=float(mc._training_rate())*intake*fed*(1.0+MARTIAL_PACE*edge)*float(maxi(1,int(WorldSimulation.span)))
	for f in formations:
		if not f is Dictionary:continue
		var formation:Dictionary=f
		if bool(formation.get("emergency_militia",false)) or int(formation.get("count",0))<=0:continue
		var unit:=String(formation.get("unit","levy"))
		var required:=maxi(1,int(formation.get("equipment_required",formation.get("count",1))))
		var armed:=clampf(float(formation.get("equipment",0))/float(required),0.0,1.0)
		var ceiling:=(float(mc._training_quality(unit,clampf(float(formation.get("experience",0.0)),0.0,1.0)))+MARTIAL_DRILL*edge)*(0.72+0.28*armed)
		var now:=float(formation.get("training",0.0))
		if now>=ceiling:continue
		var step:=clampf(rate/maxf(1.0,float(mc.UnitCatalog.training_days(unit))),0.0,1.0)
		formation["training"]=minf(ceiling,now+(ceiling-now)*step)
	return drill_of(formations)


# --------------------------------------------------------------------------
# An older save
# --------------------------------------------------------------------------

## An older save's army folds into the watch without losing or making
## anyone: recruits waiting and everyone in drill (but drafts walking out to
## their bands) join the watch at home with the drill they had; bands in the
## field stay as offensive bands; garrisons stay. When more serve than the
## watch share, the share rises to hold them all (they were already away
## from their work: GameState.civilian_workforce_fraction), so nobody is sent
## home and nobody is called up. Returns those folded from waiting and
## drill.
static func fold(mc:Variant)->int:
	mc.set("watch_folded",true)
	var folded:=0
	for order in (mc.training_queue as Array).duplicate():
		if not order is Dictionary:continue
		var drill:Dictionary=order
		if String(drill.get("mode",""))=="field_draft":continue
		var count:=maxi(0,int(drill.get("count",0)))
		mc.training_queue.erase(order)
		if count<=0:
			return_weapons(mc,maxi(0,int(drill.get("reserved_equipment",0))),String(drill.get("weapon","improvised")))
			continue
		var done:=clampf(float(drill.get("progress_days",0.0))/maxf(1.0,float(drill.get("required_days",1.0))),0.0,1.0)
		var as_drilled:=drill.duplicate(true)
		as_drilled.erase("deployment_line");as_drilled.erase("build_batch")
		as_drilled["prior_skill"]=maxf(START_DRILL,float(mc._training_quality(String(drill.get("unit","levy")),clampf(float(drill.get("experience",0.0)),0.0,1.0)))*done)
		if String(as_drilled.get("mode",""))=="reinforce" and mc._formation_index(int(as_drilled.get("target_formation_id",-1)))<0:as_drilled["mode"]="new"
		mc._complete_training(as_drilled)
		folded+=count
	# The lines and the army builds that called people up stand no more.
	if mc.recruit_deploy!=null and mc.recruit_deploy.data.has("lines"):(mc.recruit_deploy.data.lines as Array).clear()
	for template in mc.army_templates:
		if template is Dictionary:(template as Dictionary)["recruitment_requested"]=false
	folded+=join_waiting(mc)
	mc.set("army_levy_level","")
	var over:=serving(mc)-manpower(mc)
	if over>0:move(over)
	mc.army_changed.emit(mc.home_army.duplicate(true))
	return folded
