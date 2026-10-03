extends RefCounted
## THE WAR LEADER'S UPKEEP: bands kept fit to fight without the ruler
## touching them. The leader sees to supply, organization and pacing
## (docs/GENERAL_CAMPAIGN_DESIGN.md); the ruler sets only how many serve, who
## leads and a stance toward each people. Every people runs on it, rivals too.
##
## Once a day, for every band out that is free to be seen to (not fighting,
## besieging, aboard ships, on the general's campaign, or under a general's
## orders from the command hierarchy, whose staff keeps its own pace in
## land_command.gd):
##  - REST AND REFILL. A band that is broken (will below a quarter) or under
##    strength (fewer than half its men, army_lines.gd) is taken out of the
##    fighting. The war leader marches it to the nearest place it can rest
##    and refill, home or a town we hold, and it rests there until it is
##    ready again: will back to half and three in four of its places filled.
##    The army's trained reserve at home and the drafts fill its places
##    meanwhile (field_sustainment.gd draft_day). When nobody more can come
##    for it (the army stands at the size the ruler set, or nobody is free),
##    the rested band is re-formed at the men it has: its empty places are
##    struck off and their gear goes back to store, so it is whole again,
##    only smaller. A band hungry for HUNGRY_DAYS days is brought back to be
##    fed the same way. A resting band is not sent to fight: the war council
##    reads `resting` (and ArmyLines.unfit) before it plans an operation.
##  - MERGE. Weak bands standing in the same place join into one under the
##    senior general among them: the band of the general with the best
##    command, then the larger band. A fit band there is left as it is, so a
##    merge never takes a fit band out of the fighting. Men, gear, the hurt,
##    the drafts on their way and their places go with them; nobody is lost
##    or made. The other general is free for another command.
## What it does is said in plain words: a line of the day's news
## (simulation_events) and the band's own record, which the army bar, the
## counters and the alerts read: resting, rest_reason, rest_place,
## command_status ("Withdrawing to rest and refill", "Resting and
## refilling"), merged_from and merged_day.

const Lines:=preload("res://scripts/army_lines.gd")
const Rations:=preload("res://scripts/field_rations.gd")

## Bands this close (km) stand in the same place.
const SAME_PLACE_KM:=1.0
## A band hungry this many days (field_rations.gd hungry_days: short of food
## three days running makes a band hungry) is brought back to be fed.
const HUNGRY_DAYS:=10.0
const WITHDRAWING:="Withdrawing to rest and refill"
const RESTING:="Resting and refilling"

var host


func _init(owner)->void:
	host=owner


## The day's upkeep: rest and refill, then merge.
func day()->void:
	if host.field_armies.is_empty(): return
	var today:=int(WorldSimulation.state.elapsed_days)
	for index in host.field_armies.size():
		var army:Dictionary=host.field_armies[index]
		if not free_to_see_to(army): continue
		_rest(army,today)
	merge_day(today)


## A band the war leader may move today: it has men, is not fighting,
## besieging, aboard ships, on the general's campaign, nor under a general's
## standing orders (land_command.gd keeps those).
func free_to_see_to(army:Dictionary)->bool:
	if int(army.get("troops",0))<=0 or bool(army.get("embarked",false)): return false
	var id:=int(army.get("army_id",0))
	if host.command_hierarchy.battle.engaged(id) or host._army_in_battle(id): return false
	if String(army.get("status",""))=="besieging" or host._besieging(id): return false
	if bool(army.get("general_managed",false)) and WorldSimulation.campaign!=null and WorldSimulation.campaign.active: return false
	if host.command_hierarchy.controls_army(id): return false
	return true


# --- Rest and refill ------------------------------------------------------------

func _rest(army:Dictionary,today:int)->void:
	var resting:=bool(army.get("resting",false))
	if resting:
		var stuck:=_nothing_more_coming(army)
		if Lines.rested(army,stuck) and not _starving(army):
			if stuck and Lines.weak(int(army.get("troops",0)),Lines.full_strength(army)): _re_form(army,today)
			_ready_again(army,today)
			return
		# Still resting: on the way, or there. A band turned aside from its rest
		# (an order given meanwhile) is sent back on its way.
		if String(army.get("status",""))=="moving":
			if String(army.get("destination_id",""))!=String(army.get("rest_place","")): _go_rest(army,today,false)
			else: army["command_status"]=WITHDRAWING
			return
		if not _at_rest_place(army): _go_rest(army,today,false)
		else: army["command_status"]=RESTING
		return
	var starving:=_starving(army)
	if not Lines.unfit(army) and not starving: return
	army["resting"]=true
	army["rest_reason"]="broken" if Lines.broken(float(army.get("morale",1.0))) else ("weak" if not starving else "hungry")
	army["rest_since"]=today
	_go_rest(army,today,true)


## Hungry long enough, away from where it is fed by hand.
func _starving(army:Dictionary)->bool:
	return Rations.is_hungry(army) and float(army.get("hungry_days",0.0))>=HUNGRY_DAYS and not host.at_home_point(army)


## The rested band that nobody more can come for is re-formed at the men it
## has: its empty places are struck off, and the gear kept for them goes
## back to store. It is whole again, only smaller.
func _re_form(army:Dictionary,today:int)->void:
	var formations:Array=army.get("formations",[])
	var struck:=0
	for index in formations.size():
		var formation:Dictionary=formations[index]
		var men:=maxi(0,int(formation.get("count",0)))
		var places:=maxi(men,int(formation.get("authorized_count",men)))
		if places<=men: continue
		struck+=places-men
		formation["authorized_count"]=men
		formation["equipment_required"]=host._equipment_required_for(String(formation.get("unit","levy")),men)
		var spare:=maxi(0,int(formation.get("equipment",0))-int(formation.equipment_required))
		if spare>0:
			var weapon:=String(formation.get("weapon","improvised"))
			formation["equipment"]=int(formation.equipment)-spare
			preload("res://scripts/watch_military.gd").return_weapons(host,spare,weapon)
			host.gear_sent_out-=spare
		formation["ammunition_required"]=host._ammunition_required_for(String(formation.get("weapon","improvised")),int(formation.equipment_required))
		formations[index]=formation
	army["formations"]=formations
	army["re_formed_day"]=today
	if struck>0: _say(today,"%s re-formed" % _band_words(army),"Nobody more can come for %s: %s. The war leader re-forms it at the %d men it has; %d empty places are struck off." % [_band_words(army),host.sustainment.block_reason(String(army.get("draft_block",""))),int(army.get("troops",0)),struck])


## Nothing more is coming for the band: no drafts in drill or on the road,
## and none can be called (the army stands at its size, nobody is free, or
## the band cannot be reached).
func _nothing_more_coming(army:Dictionary)->bool:
	var coming:Dictionary=host.sustainment.drafts_for(int(army.get("army_id",0)))
	if int(coming.get("on_road",0))+int(coming.get("in_training",0))>0: return false
	return String(army.get("draft_block",""))!=""


## Marches the band to the nearest place it can rest (home, or a town we
## hold) and says so; a band already there, or with no road to either, rests
## where it stands.
func _go_rest(army:Dictionary,today:int,first:bool)->void:
	var place:=_rest_place(army)
	army.erase("city_operation")
	army["rest_place"]=String(place.get("id",""))
	var name:=String(place.get("name","where they stand"))
	var who:=_band_words(army)
	var why:=Lines.why_unfit(army)
	if place.is_empty() or _at(army,place):
		# It rests here: no march to make.
		army["rest_place"]=""
		army["command_status"]=RESTING
		if first: _say(today,"%s rests and refills" % who,"%s is out of the fighting (%s) and rests at %s until it is fit again." % [who,why,name])
		return
	var moved:Dictionary=host.move_field_army(int(army.army_id),String(place.id))
	if moved.has("error"):
		# No road on: it rests where it stands, and is not sent again each day.
		army["rest_place"]=""
		army["command_status"]=RESTING
		if first: _say(today,"%s rests where it stands" % who,"%s is out of the fighting (%s); there is no road to %s, so it rests where it stands." % [who,why,name])
		return
	army["command_status"]=WITHDRAWING
	if first: _say(today,"%s pulls back to rest" % who,"%s is out of the fighting (%s). The war leader brings it back to %s to rest and refill: about %d %s on the road." % [who,why,name,int(moved.get("days",0)),"day" if int(moved.get("days",0))==1 else "days"])


## The rested band is fit again: it holds where it is, ready for orders.
func _ready_again(army:Dictionary,today:int)->void:
	var full:=Lines.full_strength(army)
	army["resting"]=false
	army["command_status"]="Rested and ready"
	army.erase("rest_reason")
	_say(today,"%s is ready again" % _band_words(army),"%s has rested: %d of %d men, will %d%%. It is fit to take the field." % [_band_words(army),int(army.get("troops",0)),full,roundi(float(army.get("morale",1.0))*100.0)])


## The nearest place to rest: home (unless the enemy holds it), or a town
## we hold with a garrison in it. {id, name, position} or {} with none.
func _rest_place(army:Dictionary)->Dictionary:
	var here:=_pos(army)
	var best:={}
	var best_km:=INF
	if not host.recovery.home_unavailable():
		var home:Dictionary=host._movement_destination("player_home")
		if not home.is_empty():
			var at:=_v2(home.get("position",{}))
			best={"id":"player_home","name":String(home.get("label","home")),"position":at}
			best_km=here.distance_to(at) if here.is_finite() and at.is_finite() else INF
	for garrison in host.occupation_forces:
		if not garrison is Dictionary or int((garrison as Dictionary).get("troops",0))<=0: continue
		var region_id:=String((garrison as Dictionary).get("region_id",""))
		var town:Dictionary=host._movement_destination(region_id)
		if town.is_empty(): continue
		var at:=_v2(town.get("position",{}))
		var km:=here.distance_to(at) if here.is_finite() and at.is_finite() else INF
		if km<best_km:
			best_km=km
			best={"id":region_id,"name":String(town.get("label",(garrison as Dictionary).get("region_name","the town"))),"position":at}
	return best


func _at_rest_place(army:Dictionary)->bool:
	var id:=String(army.get("rest_place",""))
	if id=="": return true
	if id=="player_home": return host._army_is_home(army)
	return String(army.get("location_id",""))==id and String(army.get("status",""))=="stationed"


func _at(army:Dictionary,place:Dictionary)->bool:
	if String(place.get("id",""))=="player_home" and host._army_is_home(army): return true
	var here:=_pos(army)
	var at:Vector2=place.get("position",Vector2.INF)
	return here.is_finite() and at.is_finite() and here.distance_to(at)<=0.5


# --- Merging weak bands -----------------------------------------------------------

## Weak bands standing in the same place join the senior general's band
## among them (a fit band there is left as it is). Returns how many bands
## were merged away.
func merge_day(today:int)->int:
	var places:={}
	for army in host.field_armies:
		if not army is Dictionary or String((army as Dictionary).get("status",""))!="stationed" or not free_to_see_to(army): continue
		var at:=_pos(army)
		if not at.is_finite(): continue
		var key:=Vector2i(floori(at.x/SAME_PLACE_KM),floori(at.y/SAME_PLACE_KM))
		if not places.has(key): places[key]=[]
		(places[key] as Array).append(int((army as Dictionary).army_id))
	var merged:=0
	for key in places:
		var ids:Array=places[key]
		if ids.size()<2: continue
		var weak:Array=[]
		for id in ids:
			var army:Dictionary=host.field_armies[host._field_army_index(int(id))]
			if Lines.weak(int(army.get("troops",0)),Lines.full_strength(army)) or Lines.broken(float(army.get("morale",1.0))): weak.append(int(id))
		if weak.size()<2: continue
		var senior:=_senior(weak)
		for id in weak:
			if int(id)==senior: continue
			if merge(int(id),senior,today): merged+=1
	return merged


## The band of the senior general among these: the best command, then the
## most men, then the oldest band.
func _senior(ids:Array)->int:
	var best:=-1
	var best_key:=[-INF,-1,0]
	for id in ids:
		var army:Dictionary=host.field_armies[host._field_army_index(int(id))]
		var commander:Dictionary=army.get("commander",{}) if army.get("commander") is Dictionary else {}
		var named:=1.0 if String(commander.get("figure_id",""))!="" else 0.0
		var key:=[named*2.0+float(commander.get("command",0.0)),int(army.get("troops",0)),-int(id)]
		if best<0 or key[0]>best_key[0] or (key[0]==best_key[0] and (key[1]>best_key[1] or (key[1]==best_key[1] and key[2]>best_key[2]))):
			best=int(id); best_key=key
	return best


## One band joins another where both stand: formations of the same kind and
## arms become one (their places, men, gear and rounds added), others come
## over whole; the hurt, scattered and taken, the drafts in drill and on
## the road follow. Nobody is lost or made. False when either band is gone.
func merge(from_id:int,into_id:int,today:int=-1)->bool:
	if today<0: today=int(WorldSimulation.state.elapsed_days)
	var from_index:int=host._field_army_index(from_id)
	var into_index:int=host._field_army_index(into_id)
	if from_index<0 or into_index<0 or from_id==into_id: return false
	var from:Dictionary=host.field_armies[from_index]
	var into:Dictionary=host.field_armies[into_index]
	var men_from:=maxi(0,int(from.get("troops",0)))
	var men_into:=maxi(0,int(into.get("troops",0)))
	var formations:Array=(into.get("formations",[]) as Array).duplicate(true)
	var ids:={}
	for formation in formations: ids[int((formation as Dictionary).get("id",-1))]=true
	var moved_to:={}
	for f in from.get("formations",[]):
		var formation:Dictionary=(f as Dictionary).duplicate(true)
		var target:=-1
		for index in formations.size():
			var there:Dictionary=formations[index]
			if String(there.get("unit",""))==String(formation.get("unit","")) and String(there.get("weapon",""))==String(formation.get("weapon","")): target=index; break
		if target<0:
			if ids.has(int(formation.get("id",-1))):
				formation["id"]=host.next_formation_id
				host.next_formation_id+=1
			ids[int(formation.id)]=true
			moved_to[int((f as Dictionary).get("id",-1))]=int(formation.id)
			formations.append(formation)
			continue
		var there:Dictionary=formations[target]
		var a:=maxi(0,int(there.get("count",0)))
		var b:=maxi(0,int(formation.get("count",0)))
		for quality in ["training","experience","personnel_condition"]:
			there[quality]=(float(there.get(quality,0.5))*a+float(formation.get(quality,0.5))*b)/maxf(1.0,float(a+b))
		there["count"]=a+b
		there["authorized_count"]=maxi(a,int(there.get("authorized_count",a)))+maxi(b,int(formation.get("authorized_count",b)))
		there["equipment"]=int(there.get("equipment",0))+int(formation.get("equipment",0))
		there["equipment_required"]=host._equipment_required_for(String(there.get("unit","levy")),int(there.authorized_count))
		there["ammunition"]=int(there.get("ammunition",0))+int(formation.get("ammunition",0))
		there["ammunition_required"]=host._ammunition_required_for(String(there.get("weapon","improvised")),int(there.equipment_required))
		formations[target]=there
		moved_to[int((f as Dictionary).get("id",-1))]=int(there.get("id",-1))
	var weight:=maxf(1.0,float(men_from+men_into))
	var rebuilt:Dictionary=host.simulator.create_formation_force(String(into.get("name","Army")),formations,(float(into.get("morale",0.6))*men_into+float(from.get("morale",0.6))*men_from)/weight,(float(into.get("readiness",0.5))*men_into+float(from.get("readiness",0.5))*men_from)/weight)
	for key in ["troops","attack","defense","armor","penetration","formations","morale","readiness"]: into[key]=rebuilt[key]
	for pool in ["wounded_pool","disabled_pool","severe_disabled_pool","scattered_pool","captured_pool","hunger_sick"]:
		into[pool]=int(into.get(pool,0))+int(from.get(pool,0))
	for share in ["supply_level","provision_ratio","personnel_condition"]:
		if into.has(share) or from.has(share): into[share]=(float(into.get(share,1.0))*men_into+float(from.get(share,1.0))*men_from)/weight
	into["hungry_days"]=maxf(float(into.get("hungry_days",0.0)),float(from.get("hungry_days",0.0)))
	# The drafts follow the men: in drill, and on the road.
	for order in host.training_queue:
		if String((order as Dictionary).get("mode",""))=="field_draft" and int((order as Dictionary).get("field_army_id",0))==from_id and String((order as Dictionary).get("garrison",""))=="":
			order["field_army_id"]=into_id
			order["target_formation_id"]=int(moved_to.get(int(order.get("target_formation_id",-1)),int(order.get("target_formation_id",-1))))
	for draft in host.field_drafts:
		if int((draft as Dictionary).get("army_id",0))==from_id and String((draft as Dictionary).get("garrison",""))=="":
			draft["army_id"]=into_id
			draft["formation_id"]=int(moved_to.get(int(draft.get("formation_id",-1)),int(draft.get("formation_id",-1))))
	var names:Array=(into.get("merged_from",[]) as Array).duplicate() if into.get("merged_from") is Array else []
	names.append(_band_words(from))
	into["merged_from"]=names.slice(maxi(0,names.size()-4))
	into["merged_day"]=today
	# The other general is free for another command.
	var from_general:=String((from.get("commander",{}) as Dictionary).get("figure_id","")) if from.get("commander") is Dictionary else ""
	var into_general:=String((into.get("commander",{}) as Dictionary).get("figure_id","")) if into.get("commander") is Dictionary else ""
	if from_general!="" and from_general!=into_general and WorldSimulation.figures!=null and WorldSimulation.figures.has_method("release_assignment"):
		WorldSimulation.figures.release_assignment("army_%d" % from_id)
	host.field_armies[into_index]=into
	host.field_armies.remove_at(host._field_army_index(from_id))
	host._refresh_readiness()
	var full:=Lines.full_strength(into)
	_say(today,"%s joins %s" % [_band_words(from),_band_words(into)],"%s, %d men, joined %s where both stood: one band of %d of %d men under %s." % [_band_words(from),men_from,_band_words(into),int(into.troops),full,_leader_words(into)])
	return true


# --- Words --------------------------------------------------------------------------

## "Rovik's band", "the 3rd band".
func _band_words(army:Dictionary)->String:
	var commander:Dictionary=army.get("commander",{}) if army.get("commander") is Dictionary else {}
	var name:=String(commander.get("name","")).strip_edges()
	if name!="" and name!=name.to_upper() and not "staff" in name.to_lower(): return "%s's band" % name.get_slice(" ",0)
	var label:=String(army.get("name","")).strip_edges()
	return label if label!="" else "A band of ours"


func _leader_words(army:Dictionary)->String:
	var commander:Dictionary=army.get("commander",{}) if army.get("commander") is Dictionary else {}
	var name:=String(commander.get("name","")).strip_edges()
	if name!="" and name!=name.to_upper() and not "staff" in name.to_lower(): return name.get_slice(" ",0)
	return "the war leader"


## A line of the day's news, known at home only for a band of ours.
func _say(today:int,title:String,text:String)->void:
	if WorldSimulation.actor_id!="player": return
	WorldSimulation.state.simulation_events.push_front({"day":today,"title":title,"description":text,"domain":"security","severity":"notice"})
	if WorldSimulation.state.simulation_events.size()>80: WorldSimulation.state.simulation_events.resize(80)


static func _v2(p:Variant)->Vector2:
	if p is Vector2: return p
	if p is Dictionary and (p as Dictionary).has("x"): return Vector2(float(p.get("x",0.0)),float(p.get("z",0.0)))
	return Vector2.INF


func _pos(army:Dictionary)->Vector2:
	return _v2(army.get("position",{}))
