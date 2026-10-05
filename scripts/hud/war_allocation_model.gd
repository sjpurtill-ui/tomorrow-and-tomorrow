extends RefCounted
## WHERE EVERY SOLDIER STANDS, read from one ledger (MilitaryCampaign
## personnel_ledger, watch_military.gd reading), as HOI4 shows manpower and
## the divisions on each front. Nothing here is estimated on our side: the
## parts always add up to everyone under arms.
##
## read(mc) -> {
##   total        everyone under arms, anywhere (the ledger's total)
##   watch        the share of the people set to keep watch (what the ruler asks)
##   population, able, share (watch of the people), can_raise (able not yet
##                keeping watch)
##   parts        [{id, label, men, ink_key, tip}] in drawing order, adding to total:
##                guard (home guard standing at home), ready (at home, free
##                for the bands), front:<civ> (in bands against that people,
##                one part per people), field (bands with no enemy errand),
##                held (holding towns), crews (boats and wings), drill
##                (joining or in a drill course), away (hurt, scattered,
##                taken, drafts on the road)
##   towns        [{id, name, guard, need, short}] home first: each town's
##                share of the home guard against what it needs
##                (watch_military GUARD_SHARE of its people, GUARD_MIN at least)
##   bands        [{army_id, name, men, full, will, fed, state, civ, where, days}]
##   enemies      {civ_id: {ours (men in bands against them), theirs, low,
##                high, unknown} (enemy() with the road adds their nearest
##                known town, {name, km, days} by the general's own road)}
##   ready_share  {drill, armed, fed (-1 nobody out), will (-1 nobody out)}
## }
## Static; preload.

const Watch:=preload("res://scripts/watch_military.gd")
const BarModel:=preload("res://scripts/hud/army_bar_model.gd")
const Ledger:=preload("res://scripts/hud/war_ledger_model.gd")
const EraWords:=preload("res://scripts/hud/era_words.gd")
## A band on the road covers about this much a day (auto_founding.gd's walk);
## the general's own road and pace are on the band's card.
const MARCH_KM_PER_DAY:=16.0


static func read(mc:Node)->Dictionary:
	var r:=Watch.reading(mc)
	var ledger:Dictionary=mc.personnel_ledger()
	var total:=int(ledger.total)
	var parts:Array=[]
	var guard:=int(r.guard)
	var ready:=int(r.offensive_home)
	parts.append(_part("guard","Guarding home",guard,"guard","Standing at home and in the towns, spread over them by their people. They meet raiders; the war council never sends them away."))
	parts.append(_part("ready","Ready at home",ready,"ready","At home beyond the home guard: drilled, armed as far as the stock goes, free for the war council to send when a stance needs them."))
	var council:GDScript=load("res://scripts/war_council.gd")
	var by_civ:={}
	var bands:Array=[]
	var other_field:=0
	var today:=int(WorldSimulation.state.elapsed_days)
	for army_variant in mc.field_armies:
		if not army_variant is Dictionary:continue
		var army:Dictionary=army_variant
		var men:=int(army.get("troops",0))
		if men<=0:continue
		var errand:Variant=army.get("council")
		var civ:=String((errand as Dictionary).get("civ","")) if errand is Dictionary else ""
		if civ!="":by_civ[civ]=int(by_civ.get(civ,0))+men
		else:other_field+=men
		var card:=BarModel.army_card(mc,army)
		var moving:=String(army.get("status",""))=="moving"
		var commander:Dictionary=army.get("commander",{}) if army.get("commander") is Dictionary else {}
		bands.append({"army_id":int(army.get("army_id",0)),"name":String(army.get("name","Band")),"men":men,"full":maxi(men,int(card.get("full",men))),
			"will":clampf(float(army.get("morale",card.get("will",0.6))),0.0,1.0),"fed":clampf(float(card.get("supply",1.0)),0.0,1.0),"state":String(card.get("state","holding")),
			"civ":civ,"general":String(commander.get("name","")),
			"where":String(army.get("destination_name","")) if moving else String(army.get("location_name","")),
			"home":String(army.get("destination_id",""))=="player_home","moving":moving,
			"days":maxi(0,int(army.get("arrival_day",today))-today) if moving else 0})
	for civ:String in by_civ:
		parts.append(_part("front:"+civ,"Against "+_name(civ),int(by_civ[civ]),"front","In bands out against them, under the generals."))
	parts.append(_part("field","In the field",other_field,"field","In bands out on errands of their own (scouting, escort, a march home)."))
	parts.append(_part("held","Holding towns",int(r.held),"held","Garrisons in the towns we took."))
	parts.append(_part("crews","Boats and wings",int(r.crews),"crews","Crews of our boats and wings."))
	var drill:=maxi(0,int(ledger.get("recruits",0)))+maxi(0,int(ledger.get("training",0)))
	parts.append(_part("drill","Drilling",drill,"drill","Called to the watch and still in a drill course: not yet ready to fight."))
	var counted:=0
	for part:Dictionary in parts:counted+=int(part.men)
	# Hurt, scattered and taken, and drafts walking out to a band: the rest of
	# the ledger, so the parts always add up to everyone under arms.
	parts.append(_part("away","Hurt or away",maxi(0,total-counted),"away","Hurt and mending, scattered after a fight, taken, or walking out to join a band."))
	parts=parts.filter(func(p:Dictionary)->bool:return int(p.men)>0 or String(p.id) in ["guard","ready"])
	# Each town's guard against what it needs.
	var Combat:=preload("res://scripts/civilization_combat.gd")
	var guards:Dictionary=Combat.guard_ledger(mc)
	var towns:Array=[]
	for city:Dictionary in WorldSimulation.state.player_settlements:
		var id:=String(city.get("id",""))
		if not Combat.keeps_watch(city):continue
		var people:=maxf(1.0,float(WorldSimulation.settlements._settlement_population(city)))
		var need:=maxi(Watch.GUARD_MIN,ceili(people*Watch.GUARD_SHARE))
		var here:=int((guards.get(id,{}) as Dictionary).get("watch",0))
		var entry:={"id":id,"name":String(city.get("name","")) if String(city.get("name",""))!="" else String(WorldSimulation.state.settlement_name),
			"guard":here,"need":need,"short":maxi(0,need-here),"people":roundi(people)}
		if bool(city.get("primary",false)):towns.push_front(entry)
		else:towns.append(entry)
	# Every people at feud or war: our men against them and theirs as our
	# watchers reckon them, and how far their nearest known town lies.
	var enemies:={}
	for e:Dictionary in Ledger.entries():
		if String(e.kind)=="ended":continue
		enemies[String(e.civ_id)]=enemy(String(e.civ_id),int(by_civ.get(String(e.civ_id),0)),false)
	var glance:=_will_and_fed(bands)
	return {"total":total,"watch":int(r.watch),"population":int(r.population),"able":int(r.able),"share":float(r.share),
		"can_raise":maxi(0,int(r.able)-int(r.watch)),"guard_target":int(r.guard_target),"home_share":float(r.home_share),
		"parts":parts,"towns":towns,"bands":bands,"enemies":enemies,
		"ready_share":{"drill":float(r.drill),"armed":float(r.armed),"fed":float(glance.fed),"will":float(glance.will)}}


## One people's side of the ledger: {ours, theirs, low, high, unknown,
## nearest:{name, km, days} or {}}.
static func enemy(civ_id:String,ours:int,with_road:=true)->Dictionary:
	var WarLoop:=preload("res://scripts/war_loop.gd")
	var truth:=float(WarLoop._their_fighters(civ_id))
	var est:Dictionary=preload("res://scripts/standing.gd").estimate(civ_id,"fighters",truth,true)
	var out:={"ours":ours,"unknown":bool(est.get("unknown",false)),"theirs":roundi(float(est.get("value",-1.0))),
		"low":roundi(float(est.get("low",-1.0))),"high":roundi(float(est.get("high",-1.0))),"nearest":{}}
	if not with_road:return out
	var council:GDScript=load("res://scripts/war_council.gd")
	var home:Vector2=CivilizationSystem.player_world_origin
	var best:={}
	var best_km:=INF
	for town:Dictionary in council.call("known_towns",civ_id):
		var at:Dictionary=town.get("position",{}) if town.get("position") is Dictionary else {}
		if at.is_empty():continue
		var km:=home.distance_to(Vector2(float(at.get("x",0.0)),float(at.get("z",0.0))))
		if km<best_km:best_km=km;best=town
	if not best.is_empty():
		# The road and pace the general would take from home (army_orders
		# preview's own reckoning: march_terrain through MilitaryCampaign);
		# a walker's pace on the straight line only when no road is found.
		var at:Dictionary=best.position
		var there:=Vector2(float(at.get("x",0.0)),float(at.get("z",0.0)))
		var km:=best_km
		var days:=maxi(1,ceili(best_km/MARCH_KM_PER_DAY))
		var mc:Node=WorldSimulation.military
		if mc!=null and mc.has_method("field_route") and best_km>=0.5:
			var road:Dictionary=mc.field_route(home,there,mc.home_army)
			if not road.has("error") and float(road.get("length_km",0.0))>0.0:
				km=float(road.length_km)
				if not (mc.home_army.get("formations",[]) as Array).is_empty():days=maxi(1,int(mc.march_days(mc.home_army,road)))
				else:days=maxi(1,ceili(km/12.0))
		out.nearest={"name":String(best.get("name","their town")),"city_id":String(best.get("city_id","")),"km":km,"days":days}
	return out


## The bands' will and fed, weighted by their men; -1 with nobody out.
static func _will_and_fed(bands:Array)->Dictionary:
	var men:=0;var will:=0.0;var fed:=0.0
	for band:Dictionary in bands:
		men+=int(band.men);will+=float(band.will)*float(band.men);fed+=float(band.fed)*float(band.men)
	if men<=0:return {"will":-1.0,"fed":-1.0}
	return {"will":will/float(men),"fed":fed/float(men)}


static func _part(id:String,label:String,men:int,ink:String,tip:String)->Dictionary:
	return {"id":id,"label":label,"men":maxi(0,men),"ink":ink,"tip":tip}


static func _name(civ_id:String)->String:
	return String(preload("res://scripts/war_loop.gd")._name(civ_id))


## Their warriors in a few words: "about 240", "180–300", "unknown".
static func theirs_words(e:Dictionary)->String:
	if bool(e.get("unknown",true)) or int(e.get("theirs",-1))<0:return "?"
	if int(e.high)-int(e.low)<=maxi(2,int(e.theirs)/10):return EraWords.grouped(int(e.theirs))
	return "%s–%s" % [EraWords.grouped(int(e.low)),EraWords.grouped(int(e.high))]
