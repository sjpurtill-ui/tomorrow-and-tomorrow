extends RefCounted
## BATTLES ON THE MAP: where fighting is going on now, read from the ledgers
## and from nothing else.
##
## One list for the war chart (hud/war_front_overlay.gd, drawn by
## hud/battle_marks.gd): every battle our people are fighting (the one being
## watched, the battle model's registry of concurrent engagements, and the
## command staff's parallel battles), every siege, and the rivals' battles
## the player can actually see. A rival battle is seen only where our
## watchers are: within the home's lookout radius, near one of our armies in
## the field, or near a town we hold. What was seen is dated: a rival fight
## that passes out of sight stays on the chart as it was last seen, for a
## few days, and is never updated from what nobody saw.
##
## Each battle: {id, kind ("battle"/"siege"), x, z, pos, sides:{a:{civ_id,
## name, colour, troops, initial}, b:{...}}, progress (-1..1; our side
## positive, else side a), status, day, place_name, ours, army_id, seed,
## rounds, commanded, skirmish, age_days}.
##
## Progress comes from the engagement's own `progress` when the battle model
## keeps one; otherwise it is estimated from what each side still has
## standing: men against the men it began with, and how near its morale is
## to breaking. Pure static helpers over plain data: tests pass fixtures
## (a Dictionary shaped like MilitaryCampaign works as well as the node).

const ArmyMarks:=preload("res://scripts/hud/army_marks.gd")

const OURS_COLOUR:=Color("#4f9bb8")
const THEIRS_COLOUR:=Color("#b5503c")
const STRANGER_COLOUR:=Color("#b89a5a")
## Morale at which a side breaks (MilitaryCampaign.MORALE_BREAK) and the
## morale a fresh force usually brings to a fight.
const MORALE_BREAK:=preload("res://scripts/army_lines.gd").BREAK
const MORALE_FULL:=0.7
## Our watchers' reach: a field army sees a fight this far off (as
## civilization_system._nearby_player_army), a held town a little less.
const ARMY_SIGHT_KM:=12.0
const GARRISON_SIGHT_KM:=10.0
const HOME_SIGHT_KM:=28.0
## A rival fight once seen stays on the chart, dated, this many days.
const RIVAL_MEMORY_DAYS:=3
const MAX_BATTLES:=32
const MAX_MEMORY:=32
## A town this close names the ground a battle is fought on (the one rule
## the battle panel and the report use too: battle_account.gd).
const NEAR_TOWN_KM:=preload("res://scripts/battle_account.gd").NEAR_TOWN_KM


# --- Reading plain data ------------------------------------------------------------

## A field of a node, an object or a dictionary, following a path of keys.
static func dig(root:Variant,path:Array)->Variant:
	var at:Variant=root
	for key in path:
		if at is Dictionary: at=(at as Dictionary).get(key)
		elif at is Object and is_instance_valid(at): at=(at as Object).get(key)
		else: return null
	return at


static func v2(position:Variant)->Vector2:
	if position is Vector2: return position
	if position is Vector3: return Vector2(position.x,position.z)
	if position is Dictionary and (position as Dictionary).has("x"): return Vector2(float(position.get("x",0.0)),float(position.get("z",0.0)))
	return Vector2.INF


## One engagement's identity: its own id when the battle model gives one,
## else its seed and the force fighting it.
static func engagement_id(engagement:Dictionary,fallback:String="")->String:
	var own:=String(engagement.get("id",""))
	if own!="": return own
	if fallback!="": return fallback
	return "%s:%s" % [str(engagement.get("seed","")),str(engagement.get("home_force_id",""))]


## Every engagement a military is fighting now, each once: the watched one,
## the registry (id -> engagement) and the command staff's parallel battles.
## [{id, engagement}] in a stable order.
static func engagements_of(military:Variant)->Array:
	var out:Array=[]
	var seen:Dictionary={}
	var add:=func(engagement:Variant,fallback:String)->void:
		if not engagement is Dictionary or (engagement as Dictionary).is_empty(): return
		var e:Dictionary=engagement
		if String(e.get("status","active")) in ["finished","ended","resolved"]: return
		var id:=engagement_id(e,fallback)
		var twin:="%s:%s" % [str(e.get("seed","")),str(e.get("home_force_id",""))]
		if seen.has(id) or (e.has("seed") and seen.has(twin)): return
		seen[id]=true
		if e.has("seed"): seen[twin]=true
		out.append({"id":id,"engagement":e})
	add.call(dig(military,["active_engagement"]),"")
	var registry:Variant=dig(military,["engagements"])
	if registry is Dictionary:
		var keys:Array=(registry as Dictionary).keys()
		keys.sort()
		for key in keys: add.call(registry[key],str(key))
	var commanded:Variant=dig(military,["command_hierarchy","data","battles"])
	if commanded is Array:
		for engagement in commanded: add.call(engagement,"")
	return out


# --- Progress ---------------------------------------------------------------------

## How much of a side is still standing: men against the men it began with,
## and how far its morale is from breaking (0..1).
static func standing(force:Dictionary,initial:int)->float:
	var troops:=maxf(0.0,float(force.get("troops",force.get("remaining_troops",0))))
	var share:=clampf(troops/maxf(1.0,float(initial)),0.0,1.0)
	var morale:=clampf((float(force.get("morale",MORALE_FULL))-MORALE_BREAK)/(MORALE_FULL-MORALE_BREAK),0.0,1.0)
	return share*(0.35+0.65*morale)


## -1..1, positive when `a` is getting the better of it.
static func estimate(a:Dictionary,a_initial:int,b:Dictionary,b_initial:int)->float:
	var ours:=standing(a,a_initial)
	var theirs:=standing(b,b_initial)
	var top:=maxf(ours,theirs)
	if top<=0.0001: return 0.0
	return clampf((ours-theirs)/top,-1.0,1.0)


## The engagement's progress for its home side (-1..1): the battle model's
## own figure when it keeps one, else the estimate.
static func progress_of(engagement:Dictionary,home_side:String)->float:
	var own:Variant=engagement.get("progress")
	if own is float or own is int: return clampf(float(own),-1.0,1.0)
	if own is Dictionary:
		var table:Dictionary=own
		if table.has(home_side): return clampf(float(table[home_side]),-1.0,1.0)
		if table.has("value"): return clampf(float(table.value),-1.0,1.0)
	var enemy_side:="defender" if home_side=="attacker" else "attacker"
	var a:Dictionary=engagement.get(home_side,{}) if engagement.get(home_side) is Dictionary else {}
	var b:Dictionary=engagement.get(enemy_side,{}) if engagement.get(enemy_side) is Dictionary else {}
	return estimate(a,int(engagement.get(home_side+"_initial",a.get("troops",0))),b,int(engagement.get(enemy_side+"_initial",b.get("troops",0))))


# --- Words for the ground ---------------------------------------------------------------

static func _usable_name(name:String)->bool:
	var low:=name.strip_edges().to_lower()
	if low=="" or ArmyMarks._generic_place(low): return false
	for word in ["contact","intercept","field position","commanded","marked ground","home settlement","the field"]:
		if word in low: return false
	return true


## The name a battle goes by: the town fought for; at home, home's own
## name; else the nearest known town ("Near Tsaren"), else how far and which
## way from home.
static func place_name(pos:Vector2,named:String,context:Dictionary)->String:
	if _usable_name(named): return ArmyMarks.place(named)
	var at_home:Vector2=context.get("home",Vector2.INF)
	if at_home.is_finite() and pos.distance_to(at_home)<2.0:
		var home_name:=String(context.get("home_name",""))
		return ArmyMarks.place(home_name) if home_name!="" else "At home"
	var best:=""; var best_km:=NEAR_TOWN_KM
	for city in context.get("cities",[]):
		var at:=v2((city as Dictionary).get("pos",(city as Dictionary).get("position",{})))
		if not at.is_finite(): continue
		var km:=pos.distance_to(at)
		if km<best_km: best_km=km; best=String(city.get("name",""))
	if best!="": return ArmyMarks.place(best) if best_km<2.0 else "Near %s" % ArmyMarks.place(best)
	var home:Vector2=context.get("home",Vector2.INF)
	if home.is_finite():
		var km:=pos.distance_to(home)
		if km<2.0: return "At home"
		return "%s %s" % [ArmyMarks.km_words(km).trim_prefix("about "),ArmyMarks.compass(pos-home)]
	return "In the field"


## Which day of the fighting it is: the battle model's own count of days
## fought (fight_engagement_day keeps it); else, for a block battle, one
## phase a day from the exchanges fought; for an older engagement with no
## blocks, one exchange a day. At least the first.
static func day_of(engagement:Dictionary,today:int)->int:
	for key in ["day_count","days"]:
		if engagement.get(key) is int or engagement.get(key) is float: return maxi(1,int(engagement[key]))
	for key in ["start_day","started_day"]:
		if engagement.get(key) is int or engagement.get(key) is float: return maxi(1,today-int(engagement[key])+1)
	var rounds:Variant=engagement.get("rounds",[])
	var fought:=(rounds as Array).size() if rounds is Array else int(engagement.get("round",1))
	var battle:Variant=engagement.get("battle",{})
	if battle is Dictionary and (battle as Dictionary).has("phase_len"):
		return maxi(1,ceili(float(fought)/float(maxi(1,int((battle as Dictionary).phase_len)))))
	return maxi(1,fought)


static func _colour_for(civ_id:String,context:Dictionary)->Color:
	var table:Dictionary=context.get("colours",{})
	if table.has(civ_id): return table[civ_id]
	if civ_id in ["player","human"]: return OURS_COLOUR
	if not (context.get("civ_names",{}) as Dictionary).has(civ_id): return THEIRS_COLOUR if bool(context.get("at_war_with",{}).get(civ_id,true)) else STRANGER_COLOUR
	var identity:Callable=context.get("identity",Callable())
	if identity.is_valid(): return identity.call(civ_id)
	return THEIRS_COLOUR


static func _name_for(civ_id:String,fallback:String,context:Dictionary)->String:
	var names:Dictionary=context.get("civ_names",{})
	if names.has(civ_id) and String(names[civ_id])!="": return String(names[civ_id])
	return fallback


static func _side(force:Dictionary,initial:int,civ_id:String,name:String,colour:Color)->Dictionary:
	return {"civ_id":civ_id,"name":name,"colour":colour,"troops":maxi(0,int(force.get("troops",force.get("remaining_troops",0)))),"initial":maxi(0,initial),
		"morale":clampf(float(force.get("morale",MORALE_FULL)),0.0,1.5),
		# The latest kit it carries (equipment ledger year): the battle mark's weapons.
		"year":ArmyMarks.force_year(force.get("formations",[]) if force.get("formations") is Array else [])}


# --- Our battles --------------------------------------------------------------------------

## Where one of our engagements is fought: between the army fighting it and
## the foe it met (when the ledger says where they stood), at the town it
## holds or besieges, or at home.
static func _our_position(engagement:Dictionary,context:Dictionary)->Vector2:
	var threat:Dictionary=engagement.get("threat",{}) if engagement.get("threat") is Dictionary else {}
	var target:=v2(threat.get("target_position",{}))
	var armies:Dictionary=context.get("armies",{})
	var force_id:=int(engagement.get("home_force_id",0))
	var kind:=String(engagement.get("home_force_kind","field"))
	var at:=Vector2.INF
	if armies.has(force_id): at=armies[force_id]
	if not at.is_finite():
		for member in engagement.get("command_participants",[]):
			if member is Dictionary and armies.has(int(member.get("army_id",0))): at=armies[int(member.army_id)]; break
	if kind=="occupation":
		var towns:Dictionary=context.get("towns",{})
		var region:=String(engagement.get("home_force_region_id",threat.get("target_region_id","")))
		if towns.has(region): return towns[region]
	if at.is_finite():
		# They met: the contact lies between them when the ledger says where
		# the foe stood, and the army is where it fights otherwise.
		if target.is_finite() and target.distance_to(at)<=8.0: return at.lerp(target,0.5)
		return at
	if target.is_finite(): return target
	var region_id:=String(threat.get("target_region_id",""))
	for city in context.get("cities",[]):
		if String(city.get("id",city.get("city_id","")))==region_id and region_id!="": return v2(city.get("pos",city.get("position",{})))
	return context.get("home",Vector2.INF)


static func from_engagement(engagement:Dictionary,id:String,context:Dictionary)->Dictionary:
	var home_side:=String(engagement.get("home_side","attacker"))
	var enemy_side:="defender" if home_side=="attacker" else "attacker"
	var ours:Dictionary=engagement.get(home_side,{}) if engagement.get(home_side) is Dictionary else {}
	var theirs:Dictionary=engagement.get(enemy_side,{}) if engagement.get(enemy_side) is Dictionary else {}
	var threat:Dictionary=engagement.get("threat",{}) if engagement.get("threat") is Dictionary else {}
	var pos:=_our_position(engagement,context)
	if not pos.is_finite(): return {}
	var today:=int(context.get("today",0))
	var enemy:=String(threat.get("source_civ_id",""))
	var enemy_name:=_name_for(enemy,String(threat.get("source_name","")),context)
	var ours_initial:=int(engagement.get(home_side+"_initial",ours.get("troops",0)))
	var theirs_initial:=int(engagement.get(enemy_side+"_initial",theirs.get("troops",0)))
	var a:=_side(ours,ours_initial,"player",String(context.get("player_name","")),OURS_COLOUR)
	# This is our battle: the opposing side shares the hostile front's red,
	# even when that civilization's identity happens to use our blue.
	var b:=_side(theirs,theirs_initial,enemy,enemy_name,THEIRS_COLOUR)
	var named:=String(threat.get("target_region_name",""))
	var rounds:Variant=engagement.get("rounds",[])
	return {"id":id,"kind":"battle","x":pos.x,"z":pos.y,"pos":pos,"sides":{"a":a,"b":b},"progress":progress_of(engagement,home_side),
		"status":_status(engagement),
		"day":day_of(engagement,today),"place_name":place_name(pos,named,context),"ours":true,"army_id":int(engagement.get("home_force_id",0)),
		"seed":int(engagement.get("seed",0)),"rounds":(rounds as Array).size() if rounds is Array else 0,"commanded":bool(engagement.get("commander_managed",false)),
		"skirmish":_skirmish(int(a.troops),int(b.troops)),"age_days":0,"observed_day":today}


## What a battle is doing now, as the battle panel says it
## (hud/battle_view.gd): drawn up before the first exchange, then fighting.
static func _status(engagement:Dictionary)->String:
	var own:=String(engagement.get("status","active"))
	if own not in ["active","","fighting"]: return own
	var rounds:Variant=engagement.get("rounds",[])
	var fought:=int(engagement.get("round",(rounds as Array).size() if rounds is Array else 0))
	return "fighting" if fought>0 else "drawn up"


## A fight in which one side is a handful, or hopelessly outnumbered
## (war_front_model.skirmish): a small mark, no worm on the front.
static func _skirmish(a:int,b:int)->bool:
	if a<=0 or b<=0: return false
	var small:=float(mini(a,b)); var large:=float(maxi(a,b))
	return small<8.0 or (small<60.0 and small<large*0.2)


## Our siege (MilitaryCampaign.active_siege): at the town, with the
## pressure told as progress (ours positive when we besiege).
static func from_siege(siege:Dictionary,context:Dictionary)->Dictionary:
	if siege.is_empty() or not bool(siege.get("active",true)): return {}
	var offensive:=String(siege.get("mode","offensive"))=="offensive"
	var pos:Vector2=v2(siege.get("target_position",{})) if offensive else context.get("home",Vector2.INF)
	if not pos.is_finite(): pos=v2(siege.get("target_position",{}))
	if not pos.is_finite(): return {}
	var threat:Dictionary=siege.get("threat",{}) if siege.get("threat") is Dictionary else {}
	var rival:=String(siege.get("defender_id","") if offensive else siege.get("attacker_id",""))
	var pressure:=clampf(float(siege.get("pressure",0.0)),0.0,1.0)
	var armies:Dictionary=context.get("armies_troops",{})
	# Ours: the army ringing their town, or the garrison behind our own walls.
	var besiegers:=int(armies.get(int(siege.get("army_id",0)),0)) if offensive else int(context.get("home_garrison",0))
	# Theirs: the host behind their walls or around ours, as the siege holds it.
	var enemy:Dictionary=threat.get("enemy_force",{}) if threat.get("enemy_force") is Dictionary else {}
	var their_men:=int(enemy.get("troops",threat.get("estimated_strength",threat.get("strength",0))))
	var name:=String(threat.get("target_region_name",""))
	var place:=ArmyMarks.place(name) if _usable_name(name) else (String(context.get("home_name","home")) if not offensive else place_name(pos,"",context).trim_prefix("Near "))
	var a:={"civ_id":"player","name":String(context.get("player_name","")),"colour":OURS_COLOUR,"troops":besiegers,"initial":besiegers,"morale":MORALE_FULL}
	var b:={"civ_id":rival,"name":_name_for(rival,String(threat.get("source_name","")),context),"colour":THEIRS_COLOUR,"troops":their_men,"initial":their_men,"morale":MORALE_FULL}
	return {"id":"siege:%s" % String(siege.get("id","")),"kind":"siege","x":pos.x,"z":pos.y,"pos":pos,"sides":{"a":a,"b":b},"progress":pressure if offensive else -pressure,
		"status":"besieging" if offensive else "besieged","day":maxi(1,int(siege.get("days",0))),"place_name":place,"ours":true,"army_id":int(siege.get("army_id",0)),
		"seed":0,"rounds":0,"commanded":false,"skirmish":false,"age_days":0,"observed_day":int(context.get("today",0)),"siege_id":String(siege.get("id",""))}


## Every battle and siege of ours, bounded.
static func ours(military:Variant,context:Dictionary)->Array:
	var out:Array=[]
	for entry in engagements_of(military):
		var battle:=from_engagement(entry.engagement,String(entry.id),context)
		if not battle.is_empty(): out.append(battle)
		if out.size()>=MAX_BATTLES: return out
	var siege:Variant=dig(military,["active_siege"])
	if siege is Dictionary:
		var marker:=from_siege(siege,context)
		if not marker.is_empty(): out.append(marker)
	return out


# --- What our watchers can see --------------------------------------------------------------

## Whether our watchers see this ground today. context.observers: {home,
## radius, armies:[Vector2], garrisons:[Vector2]}.
static func observed(pos:Vector2,observers:Dictionary)->bool:
	if not pos.is_finite(): return false
	var home:Vector2=observers.get("home",Vector2.INF)
	if home.is_finite() and pos.distance_to(home)<=float(observers.get("radius",HOME_SIGHT_KM)): return true
	for at in observers.get("armies",[]):
		if pos.distance_to(at)<=ARMY_SIGHT_KM: return true
	for at in observers.get("garrisons",[]):
		if pos.distance_to(at)<=GARRISON_SIGHT_KM: return true
	return false


## A rival people's battle, as our watchers see it: side a is the people
## whose battle it is, side b whoever they fight.
static func from_rival(owner:String,military:Variant,engagement:Dictionary,id:String,context:Dictionary)->Dictionary:
	var home_side:=String(engagement.get("home_side","attacker"))
	var enemy_side:="defender" if home_side=="attacker" else "attacker"
	var threat:Dictionary=engagement.get("threat",{}) if engagement.get("threat") is Dictionary else {}
	var foe:=String(threat.get("source_civ_id",""))
	if foe in ["human","player",""] or foe==owner: return {}
	var pos:=Vector2.INF
	var force_id:=int(engagement.get("home_force_id",0))
	var armies:Variant=dig(military,["field_armies"])
	if armies is Array and force_id>0:
		for army in armies:
			if army is Dictionary and int(army.get("army_id",0))==force_id: pos=v2(army.get("position",{})); break
	var target:=v2(threat.get("target_position",{}))
	if pos.is_finite() and target.is_finite() and target.distance_to(pos)<=8.0: pos=pos.lerp(target,0.5)
	elif not pos.is_finite(): pos=target
	if not pos.is_finite(): return {}
	var a_force:Dictionary=engagement.get(home_side,{}) if engagement.get(home_side) is Dictionary else {}
	var b_force:Dictionary=engagement.get(enemy_side,{}) if engagement.get(enemy_side) is Dictionary else {}
	var a:=_side(a_force,int(engagement.get(home_side+"_initial",a_force.get("troops",0))),owner,_name_for(owner,"strangers",context),_colour_for(owner,context))
	var b:=_side(b_force,int(engagement.get(enemy_side+"_initial",b_force.get("troops",0))),foe,_name_for(foe,"strangers",context),_colour_for(foe,context))
	var today:=int(context.get("today",0))
	return {"id":"rival:%s:%s" % [owner,id],"kind":"battle","x":pos.x,"z":pos.y,"pos":pos,"sides":{"a":a,"b":b},"progress":progress_of(engagement,home_side),
		"status":_status(engagement),"day":day_of(engagement,today),"place_name":place_name(pos,String(threat.get("target_region_name","")),context),"ours":false,"army_id":0,
		"seed":int(engagement.get("seed",0)),"rounds":(engagement.get("rounds",[]) as Array).size() if engagement.get("rounds") is Array else 0,"commanded":false,
		"skirmish":_skirmish(int(a.troops),int(b.troops)),"age_days":0,"observed_day":today}


## The rivals' battles our watchers see today, and those seen in the last
## few days as they were last seen. actors: {civ_id: military-like}.
## memory (the caller's, never saved): id -> {day, battle}.
static func rivals(actors:Dictionary,context:Dictionary,memory:Dictionary)->Array:
	var out:Array=[]
	var today:=int(context.get("today",0))
	var observers:Dictionary=context.get("observers",{})
	var now:Dictionary={}
	var owners:Array=actors.keys()
	owners.sort()
	for owner in owners:
		var military:Variant=actors[owner]
		for entry in engagements_of(military):
			var battle:=from_rival(String(owner),military,entry.engagement,String(entry.id),context)
			if battle.is_empty() or not observed(battle.pos,observers): continue
			now[String(battle.id)]=true
			memory[String(battle.id)]={"day":today,"battle":battle.duplicate(true)}
			out.append(battle)
			if out.size()>=MAX_BATTLES: break
	# Out of sight: kept as last seen, dated, until it is too old to matter.
	# A fight that ended where our watchers still stand is seen to be over.
	for id in memory.keys():
		if now.has(id): continue
		var kept:Dictionary=memory[id]
		var age:=today-int(kept.get("day",today))
		var last:Dictionary=kept.get("battle",{})
		if age>RIVAL_MEMORY_DAYS or age<0 or last.is_empty() or observed(v2(last.get("pos",Vector2.INF)),observers):
			memory.erase(id); continue
		var dated:=last.duplicate(true)
		dated["age_days"]=age
		dated["status"]="seen"
		out.append(dated)
	while memory.size()>MAX_MEMORY:
		var oldest:=""; var oldest_day:=1<<30
		for id in memory:
			if int(memory[id].get("day",0))<oldest_day: oldest_day=int(memory[id].get("day",0)); oldest=String(id)
		memory.erase(oldest)
	return out.slice(0,MAX_BATTLES)


## Whether anything is being fought at all (a cheap look before the rest).
static func any_fighting(military:Variant,actors:Dictionary)->bool:
	if not engagements_of(military).is_empty(): return true
	var siege:Variant=dig(military,["active_siege"])
	if siege is Dictionary and not (siege as Dictionary).is_empty(): return true
	for owner in actors:
		if not engagements_of(actors[owner]).is_empty(): return true
	return false


## Everything: ours first, then what our watchers see of the rivals'.
static func collect(military:Variant,actors:Dictionary,context:Dictionary,memory:Dictionary)->Array:
	var out:=ours(military,context)
	for battle in rivals(actors,context,memory):
		if out.size()>=MAX_BATTLES: break
		out.append(battle)
	return out
