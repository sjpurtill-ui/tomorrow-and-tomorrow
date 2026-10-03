extends RefCounted
## HOW MANY OF THE PEOPLE SERVE: the ruler's one decision about the army's
## size. KEEPING WATCH IS THE MILITARY (watch_military.gd): the army's size
## is the watch share, the share of the people set to keep watch (Defense
## work). It reads the same for a band of 120 and for an empire of a
## billion, as HOI4's conscription laws and Victoria 3's conscription rate
## do. The war leader keeps everyone under arms equal to the watch every day
## (watch_military.gd keep): raising the share sets more people to keep
## watch, and they join the watch at home at once; lowering it sends the
## surplus at home back to their work (the hurt first, then the least
## drilled; never a band in the field).
## The levels follow the historical benchmarks: pre-modern peoples kept 3-7%
## of their people under arms in war (EPOCHAL_SHIFTS.md s3.4, war_loop.gd
## MOBILIZE_MIN/MAX); modern total war reached 10-20%. Every person serving is
## one fewer at other work: the economy reads the same allocation ledger
## (GameState.population_allocations, MilitaryCampaign.personnel_ledger).
## Of the watch, the home guard (MilitaryCampaign.watch_split) stays at home
## and in the towns; the rest are the offensive troops the war council sends
## out in bands (watch()).
## The army's level is read from the watch share itself ("share:0.05");
## MilitaryCampaign.army_levy_level is kept only for older saves.
## A stand-down the ruler orders lowers the watch by those sent home, so
## nobody is set to keep watch in their place (stand_down(), lower()).
## The war leader arms the watch as the best foot our people can train and
## arm (kit()), so the watch of the musket age carries muskets, not spears.
## Static helpers; preload.

const HomeOrders:=preload("res://scripts/home_orders.gd")
const EraWords:=preload("res://scripts/hud/era_words.gd")
const Kit:=preload("res://scripts/armor_equipment.gd")
## Loaded when used (they preload this file).
const COUNCIL_PATH:="res://scripts/war_council.gd"
const WATCH_PATH:="res://scripts/watch_military.gd"
## The kinds of foot an army is mostly made of; the war leader drills the
## best of them our people can train and arm.
const LINE_BRANCHES:=["force_generation","heavy_infantry","missile_infantry"]

## The levels, smallest first: {id, share}. Said as plain shares ("3%").
## "none" is nobody keeping watch: those who come home from the bands go
## back to work (the court's "disband the army").
const LEVELS:=[
	{"id":"none","share":0.0},
	{"id":"few","share":0.01},
	{"id":"some","share":0.03},
	{"id":"many","share":0.05},
	{"id":"war","share":0.10},
	{"id":"all","share":0.20},
]
## The war leader looks at the army's size this often (days) for the bands
## out (war_council.gd fold_idle_bands); the watch itself is kept every day.
const KEEP_EVERY:=5
const RAISE_SLACK:=0.02
const RELEASE_SLACK:=0.10


static func _watch()->GDScript:
	return load(WATCH_PATH) as GDScript


## A level by its id; an exact share ("share:0.0624") reads as a level of
## that share.
static func level(id:String)->Dictionary:
	if id.begins_with(SHARE_PREFIX):
		var share:=float(id.substr(SHARE_PREFIX.length()))
		if share<0.0 or share>1.0:return {}
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


## Everyone under arms on land now: every soldier at home, in the bands and
## holding towns, hurt, scattered or taken, less the crews of boats and
## aircraft. The watch is the army: nobody is netted out for it.
static func under_arms(mc:Node)->int:
	return maxi(0,int(mc._mobilized_count())-int(mc.joint_operations.personnel()))


## The home guard (the watch kept at home and in the towns; the rest are for
## the bands): {target (the split's share of the watch), home (standing at
## home), drill (0: the watch drills at home), kept}.
static func watch(mc:Node)->Dictionary:
	var Watch:=_watch()
	var target:=int(Watch.call("home_guard_target",mc))
	var home:=int(Watch.call("home_guard",mc))
	return {"target":target,"home":home,"drill":0,"kept":home}


## The army against the watch today: {level (the watch's share of the
## people, "share:0.05"), name, share, target (the watch), now (everyone
## serving), gap (target - now), population, able (who can work)}.
static func reading(mc:Node)->Dictionary:
	var population:=int(WorldSimulation.state.population_total)
	var target:=int(_watch().call("manpower",mc))
	var share:=float(target)/float(population) if population>0 else 0.0
	var id:="%s%.5f" % [SHARE_PREFIX,share]
	var now:=maxi(0,int(mc._mobilized_count()))
	return {"level":id,"name":level_name(id),"share":share,"target":target,"now":now,"gap":target-now,
		"population":population,"able":int(WorldSimulation.state.able_population())}


static func _level_of(mc:Node)->String:
	return String(reading(mc).level)


## The ruler chooses a level: the watch is set to that share of the people
## and the war leader acts on it at once. {ok, said} or {error}.
static func choose(mc:Node,id:String)->Dictionary:
	if level(id).is_empty():return {"error":"There is no such level."}
	var applied:Dictionary=_watch().call("set_share",mc,float(level(id).share))
	if applied.has("error"):return applied
	# Fewer: the bands at home with nothing to do fold back first, so the
	# surplus goes home at once; those out are called in (war_council.gd).
	if int(reading(mc).gap)<0:(load(COUNCIL_PATH) as GDScript).call("fold_idle_bands")
	var done:Dictionary=keep(mc,int(WorldSimulation.state.elapsed_days),true)
	var said:=String(applied.get("said",""))
	if int(done.get("released",0))>0:said+=" %d go back to their work." % int(done.released)
	elif int(done.get("joined",0))>0:said+=" %d join the watch at home." % int(done.joined)
	return {"ok":true,"said":said}


## The war leader's keeping of the watch (watch_military.gd keep; every
## day). {joined, released, folded}.
static func keep(mc:Node,day:int,now:=false)->Dictionary:
	return _watch().call("keep",mc,day,now)


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


## A levy the ruler orders in court raises the watch itself
## (MilitaryCampaign.raise_recruits): nothing more to cover. "".
static func cover(_mc:Node)->String:
	return ""


## A stand-down the ruler orders stands: those sent home already came off
## the watch (MilitaryCampaign.demobilize). With `everyone`, nobody keeps
## watch at all, so the men coming home from the bands go back to work as
## well; `leaving`: a band on its way home to be stood down comes off the
## watch now. The words to add to the court's answer, or "".
static func lower(mc:Node,everyone:=false,leaving:=0)->String:
	var Watch:=_watch()
	if everyone:
		if int(Watch.call("manpower",mc))<=0:return ""
		Watch.call("set_share",mc,0.0)
		return NO_ARMY_WORDS
	if leaving>0:Watch.call("move",-leaving)
	return String(Watch.call("share_words",mc))

const NO_ARMY_WORDS:="Nobody keeps watch now: the army is stood down."


## The ruler sends people home from the army (the court's stand-down). The
## bands at home with no errand fold back into the watch at home (resting
## ones too: home is where they rest), drill not yet done stops when everyone
## goes, and `count` go back to work (every one with `everyone`): the
## lastingly hurt first, then those waiting, then the watch at home. Never a
## band out: those go home when they come back, as the watch falls (lower()).
## {released, released_injured_veterans, released_recruits,
## released_field_soldiers, returned_equipment, folded, away (men in bands
## out), held (men holding towns), watch (the watch left), said}.
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
	out["said"]=lower(mc,everyone)
	out["watch"]=int(_watch().call("manpower",mc))
	return out


## Those the ruler can send home from the army at home today: the lastingly
## hurt, those waiting and the watch at home.
static func free_to_go(mc:Node)->int:
	var hurt:=mini(int(mc.home_army.get("disabled_pool",0)),int(mc.home_army.get("wounded_pool",0)))
	return maxi(0,hurt)+maxi(0,int(mc.aggregate_recruits))+maxi(0,int(mc.home_army.get("troops",0)))


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
## the watch at home".
static func at_home_words(mc:Node)->String:
	var home:=maxi(0,int(mc.home_army.get("troops",0)))
	return "the %d on the watch at home" % home


## What a level costs, in plain words: "16 of 535 keep watch · 1 in 21
## hands leaves other work".
static func cost_words(id:String,population:int,able:int)->String:
	var target:=target_men(id,population)
	if target<0:return ""
	var share_of_work:=float(target)/float(maxi(1,able))
	var one_in:=roundi(1.0/share_of_work) if share_of_work>0.0 else 0
	return "%s of %s keep watch%s" % [EraWords.grouped(target),EraWords.grouped(population),(" · 1 in %d hands leaves other work" % one_in) if one_in>0 else ""]
