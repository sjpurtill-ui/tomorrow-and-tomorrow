extends RefCounted
## HOW MANY OF THE PEOPLE SERVE: the ruler's one decision about the army's
## size. It is a share of the people, so it reads the same for a band of 120
## and for an empire of a billion, as HOI4's conscription laws and Victoria 3's
## conscription rate do. The war leader keeps the army at that share:
##   - every KEEP_EVERY days they call up, drill and arm people to reach it,
##     through the court's own levy (home_orders.gd: free adults leave their
##     work, start their drill, and the weapons they lack go to the workshops);
##   - when the army stands above it, they send the surplus home (demobilize:
##     the hurt first, then recruits waiting, then the levy at home; never a
##     band in the field).
## The levels follow the historical benchmarks: pre-modern peoples kept 3-7%
## of their people under arms in war (EPOCHAL_SHIFTS.md s3.4, war_loop.gd
## MOBILIZE_MIN/MAX); modern total war reached 10-20%. Every person serving is
## one fewer at work at home: the economy reads the same personnel ledger
## (MilitaryCampaign.personnel_ledger).
## The watch at home is not the army: home defence is kept by those set to
## Defense work (MilitaryCampaign._home_garrison_target) and the home troops
## and basic trainees who keep it. No level counts it, calls it up or sends it
## home (watch()).
## MilitaryCampaign.army_levy_level holds the chosen level ("" until the ruler
## chooses: then nobody is called up or sent home on its account; "none" keeps
## no army at all).
## A stand-down the ruler orders stands like a levy does: the bands at home
## fold back, the surplus goes home, and the level falls to fit what is left
## (stand_down(), lower()), so nobody is called up again in their place.
## The war leader drills them as the best foot our people can train and arm
## (kit()), so the levy of the musket age carries muskets, not spears. A levy
## the ruler orders in court stands: it lifts the level to cover it (cover()).
## Static helpers; preload.

const HomeOrders:=preload("res://scripts/home_orders.gd")
const EraWords:=preload("res://scripts/hud/era_words.gd")
const Kit:=preload("res://scripts/armor_equipment.gd")
## Loaded when used: the war council preloads this file.
const COUNCIL_PATH:="res://scripts/war_council.gd"
## The kinds of foot an army is mostly made of; the war leader drills the
## best of them our people can train and arm.
const LINE_BRANCHES:=["force_generation","heavy_infantry","missile_infantry"]

## The levels, smallest first: {id, share}. Said as plain shares ("3%").
## "none" is no army: nobody is called up, and those who come home from the
## bands go back to work (the court's "disband the army").
const LEVELS:=[
	{"id":"none","share":0.0},
	{"id":"few","share":0.01},
	{"id":"some","share":0.03},
	{"id":"many","share":0.05},
	{"id":"war","share":0.10},
	{"id":"all","share":0.20},
]
## The war leader looks at the army's size this often (days).
const KEEP_EVERY:=5
## They call up when short by more than this share of the target (so a band
## of 120 keeping one under arms calls that one up), and send home when over
## by more than RELEASE_SLACK of it (at least one).
const RAISE_SLACK:=0.02
const RELEASE_SLACK:=0.10


## A level by its id; an exact share a stand-down left ("share:0.0624",
## lower()) reads as a level of that share.
static func level(id:String)->Dictionary:
	if id.begins_with(SHARE_PREFIX):
		var share:=float(id.substr(SHARE_PREFIX.length()))
		if share<0.0 or share>float((LEVELS[-1] as Dictionary).share):return {}
		return {"id":id,"share":share}
	for entry:Dictionary in LEVELS:
		if String(entry.id)==id:return entry
	return {}

const SHARE_PREFIX:="share:"


## The level as a plain share: "3%" ("0.4%" below one in a hundred).
static func level_name(id:String)->String:
	var entry:=level(id)
	if entry.is_empty():return "Not set"
	var share:=float(entry.share)
	if share>0.0 and share<0.0095:return "%.1f%%" % (share*100.0)
	return "%d%%" % roundi(share*100.0)


## The people the army is kept to at this level, of `population` people.
static func target_men(id:String,population:int)->int:
	var entry:=level(id)
	if entry.is_empty():return -1
	return roundi(float(maxi(0,population))*float(entry.share))


## The army on land now: every soldier, recruit, trainee, hurt or scattered
## soldier the personnel ledger counts, less the crews of boats and aircraft
## and less the watch at home.
static func under_arms(mc:Node)->int:
	return maxi(0,int(mc._mobilized_count())-int(mc.joint_operations.personnel())-int(watch(mc).kept))


## The watch at home (home defence, not the army): {target (those set to
## Defense work), home (home troops keeping it), drill (basic trainees
## keeping it), kept}.
static func watch(mc:Node)->Dictionary:
	var target:=maxi(0,int(mc._home_garrison_target()))
	var home:=mini(maxi(0,int(mc.home_army.get("troops",0))),target)
	var drill:=mini(maxi(0,int(mc._automatic_basic_trainees())),maxi(0,target-home))
	return {"target":target,"home":home,"drill":drill,"kept":home+drill}


## The army against its level today: {level, name, share, target, now, gap
## (target - now), population, able (who can work)}.
static func reading(mc:Node)->Dictionary:
	var id:=_level_of(mc)
	var population:=int(WorldSimulation.state.population_total)
	var now:=under_arms(mc)
	var target:=target_men(id,population)
	return {"level":id,"name":level_name(id),"share":float(level(id).get("share",0.0)),"target":target,"now":now,"gap":(target-now) if target>=0 else 0,
		"population":population,"able":int(WorldSimulation.state.able_population())}


static func _level_of(mc:Node)->String:
	var held:Variant=mc.get("army_levy_level")
	return String(held) if held is String else ""


## The ruler chooses the level; the war leader acts on it at once.
## {ok, said} or {error}.
static func choose(mc:Node,id:String)->Dictionary:
	if id!="" and level(id).is_empty():return {"error":"There is no such level."}
	mc.set("army_levy_level",id)
	# Fewer: the bands at home with nothing to do fold back first, so the
	# surplus goes home at once; those out are called in (war_council.gd).
	if id!="" and int(reading(mc).gap)<0:(load(COUNCIL_PATH) as GDScript).call("fold_idle_bands")
	var done:=keep(mc,int(WorldSimulation.state.elapsed_days),true)
	return {"ok":true,"said":String(done.get("said",""))}


## The war leader's look at the army's size (every KEEP_EVERY days, or at once
## when `now` is set). {raised, released, said} or {} when nothing was done.
static func keep(mc:Node,day:int,now:=false)->Dictionary:
	var id:=_level_of(mc)
	if id=="" or (not now and day%KEEP_EVERY!=0):return {}
	if mc.recovery.home_unavailable():return {}
	var read:=reading(mc)
	var target:=int(read.target)
	var have:=int(read.now)
	if target-have>floori(float(target)*RAISE_SLACK):
		var asked:=target-have
		var pick:=kit(mc)
		var result:Dictionary=HomeOrders.perform({"kind":"levy","count":asked,"recruit":true,"fill":false,"arm_said":true,"unit":String(pick.unit),"item":String(pick.item),"by_law":true})
		var raised:=int(result.get("raised",0))
		return {"raised":raised,"released":0,"said":("%d called up to bring the army to %s of the people. They begin their drill." % [raised,level_name(id)]) if raised>0 else "Nobody free to call up: every able adult is already serving or away."}
	if have-target>maxi(0,ceili(float(target)*RELEASE_SLACK)):
		var surplus:=have-target
		# Those still in drill go home first, the newest orders first: their
		# drill stops (cancel_training gives back the weapons set aside), then
		# the recruits waiting go back to work. The watch's own drill stays.
		var queue:Array=mc.training_queue.duplicate()
		queue.reverse()
		for order in queue:
			if int(mc.aggregate_recruits)>=surplus:break
			if not order is Dictionary:continue
			var drill:Dictionary=order
			if String(drill.get("mode",""))=="field_draft" or drill.has("deployment_line") or bool(drill.get("automated_basic",false)):continue
			mc.cancel_training(int(drill.get("id",-1)))
		# Never below the watch: only the lastingly hurt at home, recruits
		# waiting and home troops beyond the watch go back to work.
		var hurt:=mini(int(mc.home_army.get("disabled_pool",0)),int(mc.home_army.get("wounded_pool",0)))
		var spare:=maxi(0,int(mc.home_army.get("troops",0))-int(watch(mc).home))
		surplus=mini(surplus,maxi(0,hurt)+int(mc.aggregate_recruits)+spare)
		if surplus<=0:return {}
		var result:Dictionary=mc.demobilize(surplus)
		var released:=int(result.get("released",0))
		if released>0:return {"raised":0,"released":released,"said":"%d sent home to their work: the army was above %s of the people." % [released,level_name(id)]}
	return {}


## The kind of foot the war leader drills new levies as: {unit, item}. The
## best fighting kit (attack × defence, with armour) among the line kinds our
## people can train and can arm from store or workshop; the plain levy with
## whatever comes to hand when there is none.
static func kit(mc:Node)->Dictionary:
	var best:={"unit":"levy","item":""}
	var score:=-INF
	for unit:String in mc.UnitCatalog.ARCHETYPES:
		if String((mc.UnitCatalog.ARCHETYPES[unit] as Dictionary).get("branch","")) not in LINE_BRANCHES:continue
		var item:=Kit.selection(mc,unit,{})
		if item=="" or not mc.simulator.WEAPONS.has(item):continue
		var value:=Kit.preference(mc,item,{})
		if value>score:score=value;best={"unit":unit,"item":item}
	return best


## A levy the ruler orders in court stands. When it lifts the army above the
## chosen level, the level rises to the smallest that holds everyone; above
## the largest, the war leader stops keeping a share (nobody is sent home on
## its account). The words to add to the court's answer, or "".
static func cover(mc:Node)->String:
	var id:=_level_of(mc)
	if id=="":return ""
	var population:=int(WorldSimulation.state.population_total)
	var now:=under_arms(mc)
	var target:=target_men(id,population)
	if now<=target+maxi(0,ceili(float(target)*RELEASE_SLACK)):return ""
	for entry:Dictionary in LEVELS:
		if target_men(String(entry.id),population)>=now:
			mc.set("army_levy_level",String(entry.id))
			return "The army is now kept at %s of the people." % level_name(String(entry.id))
	mc.set("army_levy_level","")
	return "That is more than any share the war leader keeps: none is kept now, and nobody is sent home on its account."


## A stand-down the ruler orders stands too: the size the war leader keeps
## falls to the share the army is left at, exactly, so nobody is called up in
## their place and nobody more is sent home; with no share chosen yet, that
## share is chosen now. With `everyone`, no army is kept at all ("none"), so
## the men coming home from the bands go back to work as well. The words to
## add to the court's answer, or "" when the level is unchanged.
static func lower(mc:Node,everyone:=false,leaving:=0)->String:
	var id:=_level_of(mc)
	if everyone:
		if id=="none":return ""
		mc.set("army_levy_level","none")
		return NO_ARMY_WORDS
	if id=="none":return ""
	var population:=maxi(1,int(WorldSimulation.state.population_total))
	# `leaving`: a band on its way home to be stood down still counts today.
	var now:=maxi(0,under_arms(mc)-maxi(0,leaving))
	if id!="" and now>=target_men(id,population):return ""
	if now<=0:
		mc.set("army_levy_level","none")
		return NO_ARMY_WORDS
	var exact:="%s%.5f" % [SHARE_PREFIX,float(now)/float(population)]
	mc.set("army_levy_level",exact)
	return "The army is now kept at %s of the people." % level_name(exact)

const NO_ARMY_WORDS:="The war leader keeps no army now: nobody is called up."


## The ruler sends people home from the army (the court's stand-down). The
## bands at home with no errand fold back into the army at home (resting ones
## too: home is where they rest), drill not yet done stops when everyone goes,
## and `count` go back to work (every one with `everyone`): the lastingly hurt
## first, then recruits, then the levy at home. Never the watch, never a band
## out: those go home when they come back, as the level falls (lower()) and
## the war leader sends home whoever stands above it. {released,
## released_injured_veterans, released_recruits, released_field_soldiers,
## returned_equipment, folded, away (men in bands out), held (men holding
## towns), watch, said (the level's words)}.
static func stand_down(mc:Node,count:int,everyone:bool)->Dictionary:
	var folded:=fold_home_bands(mc)
	if everyone:
		for order in (mc.training_queue as Array).duplicate():
			if not order is Dictionary or bool((order as Dictionary).get("automated_basic",false)):continue
			mc.cancel_training(int((order as Dictionary).get("id",-1)))
	var free:=free_to_go(mc)
	var n:=free if everyone else mini(maxi(0,count),free)
	var out:={"released":0,"released_injured_veterans":0,"released_recruits":0,"released_field_soldiers":0,"returned_equipment":{}}
	if n>0:
		var r:Dictionary=mc.demobilize(n)
		if not r.has("error"):out.merge(r,true)
	out["folded"]=folded
	var away:=0
	for army in mc.field_armies:
		if army is Dictionary:away+=maxi(0,int((army as Dictionary).get("troops",0)))
	var held:=0
	for force in mc.occupation_forces:
		if force is Dictionary:held+=maxi(0,int((force as Dictionary).get("troops",0)))
	out["away"]=away
	out["held"]=held
	out["watch"]=int(watch(mc).kept)
	out["said"]=lower(mc,everyone)
	return out


## Those the ruler can send home from the army at home today: the lastingly
## hurt, recruits waiting, and the levy at home beyond the watch.
static func free_to_go(mc:Node)->int:
	var hurt:=mini(int(mc.home_army.get("disabled_pool",0)),int(mc.home_army.get("wounded_pool",0)))
	var spare:=maxi(0,int(mc.home_army.get("troops",0))-int(watch(mc).home))
	return maxi(0,hurt)+maxi(0,int(mc.aggregate_recruits))+spare


## Bands standing at home with no errand under way fold back into the army
## at home, resting ones too (home is where they rest and refill). Returns
## the men folded.
static func fold_home_bands(mc:Node)->int:
	var men:=0
	for army in (mc.field_armies as Array).duplicate():
		if not army is Dictionary or not home_band(mc,army):continue
		var troops:=int((army as Dictionary).get("troops",0))
		if not mc.disband_field_army(int((army as Dictionary).get("army_id",0))).has("error"):men+=troops
	return men


## A band at home with nothing under way: stationed at home, not fighting,
## aboard ships, under a general's standing orders or on the general's
## campaign, and no errand of the war council's still out.
static func home_band(mc:Node,band:Dictionary)->bool:
	if int(band.get("troops",0))<=0 or bool(band.get("embarked",false)):return false
	if String(band.get("status",""))!="stationed" or String(band.get("location_id",""))!="player_home":return false
	var id:=int(band.get("army_id",0))
	if mc.command_hierarchy.battle.engaged(id) or mc._army_in_battle(id) or mc._besieging(id):return false
	if mc.command_hierarchy.controls_army(id):return false
	if WorldSimulation.campaign!=null and bool(WorldSimulation.campaign.active) and id==int(WorldSimulation.campaign.state.get("army_id",-1)):return false
	var errand:Variant=band.get("council")
	if errand is Dictionary and not String((errand as Dictionary).get("phase","")) in ["","home","done"]:return false
	return true


## Who stands at home under arms, in a few words for the court: "the 24 on
## the watch at home" when nobody else is home, else "the 30 under arms at
## home".
static func at_home_words(mc:Node)->String:
	var home:=maxi(0,int(mc.home_army.get("troops",0)))
	if home>0 and home<=int(watch(mc).home):return "the %d on the watch at home" % home
	return "the %d under arms at home" % home


## What a level costs, in plain words: "16 of 535 serve · 1 in 21 hands
## leaves work".
static func cost_words(id:String,population:int,able:int)->String:
	var target:=target_men(id,population)
	if target<0:return ""
	var share_of_work:=float(target)/float(maxi(1,able))
	var one_in:=roundi(1.0/share_of_work) if share_of_work>0.0 else 0
	return "%s of %s serve%s" % [EraWords.grouped(target),EraWords.grouped(population),(" · 1 in %d hands leaves work" % one_in) if one_in>0 else ""]
