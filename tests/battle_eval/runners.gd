extends "res://tests/battle_eval/harness.gd"
## The scenario runners: each plays one kind of war situation through the
## real engine's own entry points and hands every battle it produced to the
## harness's checks (harness.gd). One runner per scenario kind.


# =============================================================================
# One battle in the field
# =============================================================================

## Our army meets their band in the field and fights it out. Scenario keys:
## ours, theirs, our/their morale and generals, hungry, ground, seed,
## approach (a night strike), like (their readiness and heart as ours),
## seek (try seeds until: our_general_killed | their_general_killed).
func _run_field()->void:
	var seeds:=[int(s.get("seed",11))]
	var seek:=String(s.get("seek",""))
	if seek!="":
		for n in range(1,40): seeds.append(int(s.get("seed",11))+n*101)
	for attempt in seeds.size():
		if attempt>0:
			fails=[]; notes=[]; resolved=[]; traces={}
			reset_world(s)
		var result:=_field_once(int(seeds[attempt]))
		if seek=="" or _sought(seek,result): break
		if attempt==seeds.size()-1: _fail("setup","no seed gave the battle this scenario is about (%s)" % seek)


func _field_once(seed:int)->Dictionary:
	var a:=our_army(s.get("ours",[]),{"morale":float(s.get("our_morale",0.8)),"general":s.get("our_general",{}),"hungry":bool(s.get("hungry",false)),"at":s.get("at",Vector2(5.0,0.0))})
	if a<=0: return {}
	var enemy:=their_force(s.get("theirs",[]),{"morale":float(s.get("their_morale",0.7)),"readiness":float(s.get("their_readiness",-1.0)) if s.has("their_readiness") else army(a).get("readiness",0.6),
		"general":s.get("their_general",{}),"hungry":bool(s.get("their_hungry",false))})
	var key:={"kind":"field_army","id":a}
	var pre:=_ledger_for(key)
	var opts:={"seed":seed}
	if s.has("approach"): opts["approach"]=s.approach
	if s.has("toward"): opts["toward"]=s.toward
	var started:=field_contact(a,enemy,opts)
	if started.has("error"): return {}
	var engagement:Dictionary=MilitaryCampaign.engagements.get(String(started.get("id","")),{})
	if not engagement.is_empty(): _expect_start(engagement)
	if bool((s.get("expect",{}) as Dictionary).get("skirmish",false)) and not live().is_empty(): check_no_front("the skirmish")
	fight_out(int(s.get("max_days",20)))
	var rec:=_newest_record(seed)
	var t:Dictionary=traces.get(String(rec.get("id","")),{"before":pre,"force":key})
	if not t.has("before"): t["before"]=pre
	var done:=check_finished(rec,t)
	if not done.is_empty():
		expect_outcome(rec,String(done.kind))
		_expect_end(rec,done,a)
	return {"record":rec,"done":done,"army":a}


func _sought(seek:String,result:Dictionary)->bool:
	var rec:Dictionary=result.get("record",{})
	if rec.is_empty(): return false
	var term:Dictionary=rec.get("termination",{})
	var home_side:=String(rec.get("home_side","attacker"))
	var ours:=String((rec.get(home_side,{}) as Dictionary).get("name",""))
	var fate:=String(term.get("commander_fate",""))
	match seek:
		"our_general_killed": return fate=="killed" and String(term.get("defeated",""))==ours
		"their_general_killed": return fate=="killed" and String(term.get("defeated",""))!=ours and String(term.get("captor",""))==ours
		"their_general_taken": return fate=="captured" and String(term.get("captor",""))==ours
	return true


func _newest_record(seed:int)->Dictionary:
	for r in MilitaryCampaign.battle_history:
		if int((r as Dictionary).get("seed",-1))==seed: return r
	return MilitaryCampaign.battle_history[0] if not MilitaryCampaign.battle_history.is_empty() else {}


## What the scenario says about how the battle is drawn up.
func _expect_start(e:Dictionary)->void:
	var want:Dictionary=s.get("expect",{})
	var ground:Dictionary=e.get("ground",{})
	if want.has("ground"): _check(String(ground.get("kind",""))==String(want.ground),"expect","the battle should be fought on %s ground, not %s" % [String(want.ground),String(ground.get("kind",""))])
	if want.has("reserves"):
		var battle:Dictionary=e.get("battle",{})
		_check(Blocks.limited(battle)==bool(want.reserves),"expect","reserves waiting behind the line should be %s (capacity %d)" % [str(bool(want.reserves)),int(battle.get("capacity",0))])
	if want.has("unseen"):
		var plan:Dictionary=e.get("tactics",{})
		var surprise:Dictionary=((plan.get(String(e.get("home_side","attacker")),{}) as Dictionary).get("surprise",{}) as Dictionary)
		_check(not surprise.is_empty(),"expect","a strike by night carries no chance of surprise")
		if not surprise.is_empty(): _check(bool(surprise.get("unseen",false))==bool(want.unseen),"expect","the night strike should be %s" % ("unseen" if bool(want.unseen) else "seen"))


## What the scenario says about how it ended.
func _expect_end(rec:Dictionary,done:Dictionary,army_id:int)->void:
	var want:Dictionary=s.get("expect",{})
	var account:Dictionary=done.account
	var text:=Account.text(account)
	var view:Dictionary=done.view
	var rounds:Array=rec.get("rounds",[])
	if want.has("max_exchanges"): _check(rounds.size()<=int(want.max_exchanges),"expect","the fight lasted %d exchanges (at most %d)" % [rounds.size(),int(want.max_exchanges)])
	if want.has("min_exchanges"): _check(rounds.size()>=int(want.min_exchanges),"expect","the fight lasted only %d exchanges (at least %d)" % [rounds.size(),int(want.min_exchanges)])
	if bool(want.get("captives",false)): _check(int((account.theirs as Dictionary).taken)>0,"expect","we took nobody captive")
	if bool(want.get("our_captured",false)): _check(int((account.ours as Dictionary).captured)>0,"expect","none of ours was taken")
	if bool(want.get("spoils",false)):
		var settled:Dictionary=rec.get("aftermath_settled",{}) if rec.get("aftermath_settled") is Dictionary else {}
		_check(bool(settled.get("has_spoils",false)),"expect","nothing was taken from them")
	if want.has("why"):
		var found:=false
		for phase in view.get("phases",[]):
			for item in (phase as Dictionary).get("why",[]):
				if String((item as Dictionary).get("k",""))==String(want.why): found=true
		_check(found,"expect","the battle view never says '%s' helped decide it" % String(want.why))
	if want.has("event"):
		var said:=false
		for r in rounds:
			if String((r as Dictionary).get("tactic_event","")).contains(String(want.event)): said=true
		_check(said,"expect","the fight never had '%s'" % String(want.event))
	if want.has("report_says"): _check(text.contains(String(want.report_says)),"expect","the report does not say '%s': %s" % [String(want.report_says),text.substr(0,240)])
	if want.has("report_not"): _check(not text.contains(String(want.report_not)),"expect","the report says '%s': %s" % [String(want.report_not),text.substr(0,240)])
	var seek:=String(s.get("seek",""))
	if OS.get_environment("BATTLE_EVAL_PROFILE")=="1": _note("succession %s; army commander now %s; gather general %s" % [str(rec.get("commander_succession",{})),String((army(army_id).get("commander",{}) as Dictionary).get("name","")),String(Account.gather(rec).get("general_name","-"))])
	if seek=="our_general_killed":
		var dead:=String(((rec.get(String(rec.get("home_side","attacker")),{}) as Dictionary).get("commander",{}) as Dictionary).get("name",""))
		var first:=Account._first_name(dead)
		var now:Dictionary=army(army_id)
		if not now.is_empty(): _check(String((now.get("commander",{}) as Dictionary).get("name",""))!=dead,"expect","%s fell in the fight but still leads the band" % dead)
		_check(first=="" or text.contains(first+" fell") or text.contains(first+" was killed"),"report","the report never says %s fell: %s" % [dead,text.substr(0,260)])
		_check(first=="" or not text.contains("%s says:" % first),"report","the dead general %s still gives advice in the report" % first)
		_check(first=="" or not text.contains("%s has " % first),"report","the report still has the dead %s leading the band" % first)
	elif seek=="their_general_killed":
		var theirs:=Account._first_name(String((rec.get("termination",{}) as Dictionary).get("commander","")))
		_check(theirs=="" or text.contains(theirs),"report","the report never says their leader %s fell: %s" % [theirs,text.substr(0,260)])
	if bool(want.get("skirmish",false)):
		_check(bool(view.get("skirmish",false)),"front","the battle view shows the tiny fight as a full battle")
		# Over at once, it still stays on the chart for a few days: as a small
		# mark, never a front or a worm.
		check_no_front("the finished skirmish")


# =============================================================================
# Home attacked
# =============================================================================

## Their band comes against home. ours: the trained watch at home; watch:
## the Defense allocation (the rest of it militia). incident: raid|campaign.
func _run_defend_home()->void:
	home_watch(s.get("ours",[]),int(s.get("watch",count_of(s.get("ours",[])))))
	var key:={"kind":"field","id":0}
	var pre:=_ledger_for(key)
	var enemy:=their_force(s.get("theirs",[]),{"morale":float(s.get("their_morale",0.7)),"readiness":float(s.get("their_readiness",0.55)),"general":s.get("their_general",{})})
	var food_before:=float(GameState.resource_stockpiles.get("Food",0.0))
	home_attack(enemy,{"incident":String(s.get("incident","raid")),"seed":int(s.get("seed",11))})
	fight_out(int(s.get("max_days",20)))
	var rec:=_newest_record(int(s.get("seed",11)))
	var t:Dictionary=traces.get(String(rec.get("id","")),{"before":pre,"force":key})
	var done:=check_finished(rec,t,{"force_moves":true})
	if done.is_empty(): return
	expect_outcome(rec,String(done.kind))
	_expect_end(rec,done,0)
	# The watch's militia go back to their work: the home army keeps only its
	# trained survivors; nobody is conjured into it.
	var home_side:=String(rec.get("home_side","defender"))
	var force:Dictionary=rec.get(home_side,{})
	var trained_lost:=0
	var militia:=0
	var formations:Array=force.get("formations",[])
	for r in rec.get("rounds",[]):
		var losses:Array=(r as Dictionary).get(home_side+"_cohort_losses",[])
		for i in mini(losses.size(),formations.size()):
			if not bool((formations[i] as Dictionary).get("emergency_militia",false)): trained_lost+=int(losses[i])
	for f in formations:
		if bool((f as Dictionary).get("emergency_militia",false)): militia+=int((f as Dictionary).get("count",0))
	var after:=int(MilitaryCampaign.home_army.get("troops",0))
	var taken:=int((rec.get("termination",{}) as Dictionary).get("prisoners",0)) if String(done.kind) in ["lost","withdrew"] else 0
	var report_text:=Account.text(done.account)
	_note("report: "+report_text)
	if MilitaryCampaign.recovery.home_unavailable():
		# Home fell: everyone under arms there was taken (siege_recovery.gd).
		_check(after==0,"ledger","home fell but %d are still under arms there" % after)
		_check(report_text.contains("Seanstone is theirs") or report_text.contains("holds Seanstone") or report_text.contains("took Seanstone"),"report","home fell but the report does not say so: %s" % report_text.substr(0,260))
		return
	_check(after<=int(pre.troops),"ledger","home had %d trained defenders before the fight and %d after: the watch's militia were kept as soldiers" % [int(pre.troops),after])
	_check(after>=int(pre.troops)-trained_lost-taken,"ledger","home had %d trained, lost %d of them, but now has %d" % [int(pre.troops),trained_lost,after])
	for f in MilitaryCampaign.home_army.get("formations",[]):
		_check(not bool((f as Dictionary).get("emergency_militia",false)),"ledger","the watch's militia stayed on as a formation of the home army after the fight")
	if String(done.kind) in ["lost"] and String(s.get("incident","raid"))=="raid":
		var gone:=food_before-float(GameState.resource_stockpiles.get("Food",0.0))
		_check(gone>0.0,"expect","the raiders broke through but took nothing from the stores")
		# Never more than the raiders could carry off.
		var carriers:=int(enemy.get("troops",0))
		_check(gone<=float(carriers)*MilitaryCampaign.RAIDER_CARRY+0.5,"range","%d raiders carried off %.0f food (at most %.0f)" % [carriers,gone,float(carriers)*MilitaryCampaign.RAIDER_CARRY])
	# Fought at our own edge, the war leader does not offer to press on or
	# come home, or wait on the field.
	_check(not report_text.contains("press on or come home") and not report_text.contains("waits where the fight was"),"report","the report of a fight at home talks as if the band were away: %s" % report_text.substr(0,260))


# =============================================================================
# A town: the assault, the siege
# =============================================================================

func _army_at_town(spec:Array)->int:
	var a:=our_army(spec,{"morale":float(s.get("our_morale",0.8)),"general":s.get("our_general",{})})
	if a<=0: return 0
	var index:=MilitaryCampaign._field_army_index(a)
	MilitaryCampaign.field_armies[index]["position"]={"x":city.x+0.3,"z":city.y}
	MilitaryCampaign.field_armies[index]["location_id"]=city_id
	MilitaryCampaign.field_armies[index]["location_name"]="Tsaren"
	MilitaryCampaign.field_armies[index]["status"]="stationed"
	return a


## Our army before Tsaren storms it (launch_offensive: the town's own
## garrison, from the world, stands against it).
func _run_assault()->void:
	var a:=_army_at_town(s.get("ours",[]))
	if a<=0: return
	var key:={"kind":"field_army","id":a}
	var pre:=_ledger_for(key)
	var result:=MilitaryCampaign.launch_offensive(civ_id,city_id,a)
	if result.has("error"): _fail("setup","the assault did not begin: %s" % String(result.error)); return
	fight_out(int(s.get("max_days",20)))
	var rec:Dictionary=MilitaryCampaign.battle_history[0] if not MilitaryCampaign.battle_history.is_empty() else {}
	var t:Dictionary=traces.get(String(rec.get("id","")),{"before":pre,"force":key})
	var done:=check_finished(rec,t)
	if done.is_empty(): return
	expect_outcome(rec,String(done.kind))
	_expect_end(rec,done,a)
	if String(done.kind)=="taken":
		var garrison:=MilitaryCampaign.occupation_force_for_region(civ_id,city_id)
		_check(not garrison.is_empty(),"ledger","Tsaren was taken but nobody holds it")
		_check(int(garrison.get("troops",-1))==int(rec.get("detached",-2)),"ledger","the report says %d were left to hold Tsaren, the garrison has %d" % [int(rec.get("detached",0)),int(garrison.get("troops",0))])
		_check(String((done.account as Dictionary).now).contains("Tsaren is ours"),"report","the town was taken but the report does not say so")
		_check(Ledger.holds(civ_id,city_id),"ledger","the town ledger does not say we hold Tsaren")
		# The garrison's card stands on Tsaren as our chart draws it, counting
		# the men inside.
		var cards:Array=OverlayScript._garrison_inputs()
		if _check(cards.size()==1,"marker","the map has %d garrison cards for one held town" % cards.size()):
			_check((cards[0].pos as Vector2).distance_to(city)<0.5,"marker","the garrison card stands %.1f km from Tsaren" % (cards[0].pos as Vector2).distance_to(city))
			_check(int(cards[0].troops)==int(garrison.get("troops",-1)),"marker","the garrison card says %d, the garrison has %d" % [int(cards[0].troops),int(garrison.get("troops",-1))])


## Our army rings Tsaren, the days pass, then it storms the walls.
func _run_siege()->void:
	var a:=_army_at_town(s.get("ours",[]))
	if a<=0: return
	var key:={"kind":"field_army","id":a}
	var begun:=MilitaryCampaign.start_offensive_siege(civ_id,city_id,a)
	if begun.has("error"): _fail("setup","the siege did not begin: %s" % String(begun.error)); return
	var siege_days:=int(s.get("siege_days",6))
	for n in siege_days:
		day()
		if MilitaryCampaign.active_siege.is_empty(): break
		_observe_siege()
	if MilitaryCampaign.active_siege.is_empty():
		_check(bool((s.get("expect",{}) as Dictionary).get("lifted",false)),"expect","the siege ended by itself after %d days" % siege_days)
		return
	var pre:=_ledger_for(key)
	var order:=MilitaryCampaign.siege_order(String(MilitaryCampaign.active_siege.id),"assault")
	if order.has("error"): _fail("setup","the assault on the walls did not begin: %s" % String(order.error)); return
	fight_out(int(s.get("max_days",20)))
	var rec:Dictionary=MilitaryCampaign.battle_history[0] if not MilitaryCampaign.battle_history.is_empty() else {}
	var t:Dictionary=traces.get(String(rec.get("id","")),{"before":pre,"force":key})
	var done:=check_finished(rec,t)
	if done.is_empty(): return
	expect_outcome(rec,String(done.kind))
	_expect_end(rec,done,a)


func _observe_siege()->void:
	var siege:Dictionary=MilitaryCampaign.active_siege
	if siege.is_empty() or not is_instance_valid(overlay): return
	var inputs:Dictionary=overlay.collect()
	var marks:Array=(inputs.get("battles",[]) as Array).filter(func(m:Dictionary)->bool: return String(m.get("kind",""))=="siege")
	if not _check(marks.size()==1,"marker","the siege of Tsaren has %d marks on the map (should be one)" % marks.size()): return
	var m:Dictionary=marks[0]
	var offensive:=String(siege.get("mode",""))=="offensive"
	var enemy:Dictionary=(siege.get("threat",{}) as Dictionary).get("enemy_force",{})
	_check(int(m.get("day",0))==maxi(1,int(siege.get("days",0))),"timing","the map says day %d of the siege, the engine day %d" % [int(m.get("day",0)),int(siege.get("days",0))])
	_check(absf(float(m.get("progress",0.0))-float(siege.get("pressure",0.0))*(1.0 if offensive else -1.0))<0.001,"marker","the map's siege pressure %.2f is not the engine's %.2f" % [float(m.get("progress",0.0)),float(siege.get("pressure",0.0))])
	var place:=String(m.get("place_name",""))
	_check(place==("Tsaren" if offensive else "Seanstone"),"marker","the siege is marked at '%s'" % place)
	var ours_in:=int(army(int(siege.get("army_id",0))).get("troops",-2)) if offensive else int(MilitaryCampaign.settlement_defense_snapshot().get("garrison_personnel",-2))
	_check(int((m.sides.a as Dictionary).get("troops",-1))==ours_in,"marker","the siege mark counts %d of ours, the engine %d" % [int((m.sides.a as Dictionary).get("troops",-1)),ours_in])
	_check(int((m.sides.b as Dictionary).get("troops",-1))==int(enemy.get("troops",-2)),"marker","the siege mark counts %d of theirs, the engine %d" % [int((m.sides.b as Dictionary).get("troops",-1)),int(enemy.get("troops",-2))])


# =============================================================================
# Many battles at once
# =============================================================================

## `battles` armies on as many fronts, each against a band of its own size.
func _run_concurrent()->void:
	var n:=int(s.get("battles",2))
	var armies:Array=[]
	var ids:Array=[]
	for i in n:
		var spec:Array=s.get("ours",[{"unit":"levy","weapon":"spear","count":80}])
		var a:=our_army(spec,{"morale":0.85,"at":Vector2(4.0+3.0*float(i),-6.0+3.0*float(i%5))})
		if a<=0: return
		var like:Dictionary=spec[0]
		var theirs:Array=s.get("theirs",[{"unit":String(like.unit),"weapon":String(like.weapon),"count":int(count_of(spec)*0.95),"training":float(like.get("training",0.6))}])
		var started:=field_contact(a,their_force(theirs,{"morale":0.85},a),{"seed":int(s.get("seed",11))+i*17,"formation":"band%d" % i})
		if started.has("error"): return
		armies.append(a); ids.append(String(started.get("id","")))
	_check(View.list_now().size()==n,"panel","%d battles are being fought but the panel lists %d" % [n,View.list_now().size()])
	var marked:=((overlay.collect() as Dictionary).get("battles",[]) as Array).filter(func(m:Dictionary)->bool: return bool(m.get("ours",false))).size()
	_check(marked==n,"marker","%d battles are being fought but the map marks %d" % [n,marked])
	var held:=int(MilitaryCampaign.foreign_prisoners); var bound:=float(GameState.resource_stockpiles.get("Forced Labor",0.0))
	fight_out(int(s.get("max_days",30)),bool(s.get("timed",false)))
	var checked:=check_all()
	# Every battle's captives, together, are where their generals put them.
	var want_held:=0; var want_bound:=0
	for done in checked:
		if (done as Dictionary).is_empty(): continue
		var rec:Dictionary=done.record
		var settled:Dictionary=rec.get("aftermath_settled",{}) if rec.get("aftermath_settled") is Dictionary else {}
		var taken:=int((done.account.theirs as Dictionary).taken)
		var policy:=String(settled.get("prisoner_policy","hold")) if not settled.is_empty() else "hold"
		if policy=="hold": want_held+=taken
		elif policy=="enslave": want_bound+=taken
	_check(int(MilitaryCampaign.foreign_prisoners)-held==want_held,"ledger","%d captives should be held under guard across the battles, %d are" % [want_held,int(MilitaryCampaign.foreign_prisoners)-held])
	_check(roundi(float(GameState.resource_stockpiles.get("Forced Labor",0.0))-bound)==want_bound,"ledger","%d captives should be bondservants across the battles, %d are" % [want_bound,roundi(float(GameState.resource_stockpiles.get("Forced Labor",0.0))-bound)])
	_check(checked.size()==n,"report","%d battles were fought, %d were checked" % [n,checked.size()])
	for id in ids:
		_check(not record_of(String(id)).is_empty(),"report","battle %s ended without a record" % String(id))


# =============================================================================
# A march: water, hills, a ford, no road
# =============================================================================

## Our army marches to a point beyond the scenario's water or hills. Checks
## the road the general picked (never across open water, a ford waded), the
## map's road, the days it takes against what was said, and arrival.
func _run_march()->void:
	var a:=our_army(s.get("ours",[{"unit":"levy","weapon":"spear","count":60}]),{"at":Vector2(0.4,0.0)})
	if a<=0: return
	var goal:Vector2=home+Vector2(s.get("goal",Vector2(24.0,0.0)))
	CivilizationSystem._add_revealed_area(goal,20.0,"test survey")
	CivilizationSystem._add_revealed_area(home.lerp(goal,0.5),30.0,"test survey")
	var order:=MilitaryCampaign.move_field_army_to_position(a,goal.x,goal.y,"the far bank")
	var want:Dictionary=s.get("expect",{})
	if bool(want.get("refused",false)):
		_check(order.has("error"),"expect","a march with no land road was ordered anyway")
		if order.has("error"):
			var words:=String(order.error)
			_check(not words.contains("_") and not words.to_upper()==words and words.length()<220,"report","the refusal is not plain words: %s" % words)
			_check(String(army(a).get("status",""))!="moving","expect","the army set out although no road was found")
		return
	if not _check(not order.has("error"),"expect","the march was refused: %s" % String(order.get("error",""))): return
	var said_days:=int(ceil(float(order.get("army",{}).get("distance_total_km",0.0))/maxf(0.1,float(order.get("army",{}).get("speed_km_day",1.0)))))
	var legs:=Route.unpack(army(a).get("march_route",[]))
	var start:=_v2(army(a).get("origin_position",{}))
	var points:Array=[start]+legs
	for i in points.size()-1:
		_check(Route.segment_land(points[i],points[i+1],Callable(self,"_land")),"expect","the road crosses open water between %s and %s" % [str(points[i]),str(points[i+1])])
	if want.has("direct"): _check(bool(army(a).get("march_direct",true))==bool(want.direct),"expect","the road should be %s" % ("straight" if bool(want.direct) else "round the water"))
	# The map draws the same road, not a straight line over the water.
	var inputs:Dictionary=overlay.collect()
	var mine:=(inputs.get("friendly",[]) as Array).filter(func(f:Dictionary)->bool: return int(f.get("army_id",0))==a)
	if _check(mine.size()==1,"marker","the marching army is marked %d times" % mine.size()):
		var road:Variant=mine[0].get("road",PackedVector2Array())
		if OS.get_environment("BATTLE_EVAL_PROFILE")=="1": _note("mark %s road %s legs %d status %s" % [str(mine[0].get("pos")),str(road),legs.size(),String(army(a).get("status",""))])
		if not bool(army(a).get("march_direct",true)):
			_check(road is PackedVector2Array and (road as PackedVector2Array).size()>=3,"marker","the map draws the march as a straight line although it goes round the water")
		if road is PackedVector2Array:
			var r:PackedVector2Array=road
			for i in r.size()-1:
				_check(Route.segment_land(r[i],r[i+1],Callable(self,"_land")),"marker","the map's road crosses open water"); break
	var days:=0
	while String(army(a).get("status",""))=="moving" and days<60:
		day(); days+=1
	_check(String(army(a).get("status",""))=="stationed","expect","the army never arrived (%d days)" % days)
	_check(_v2(army(a).get("position",{})).distance_to(goal)<1.0,"expect","the army stopped %.1f km short" % _v2(army(a).get("position",{})).distance_to(goal))
	_check(days<=said_days+1,"timing","the march was said to take about %d days and took %d" % [said_days,days])
	if want.has("min_days"): _check(days>=int(want.min_days),"expect","the march through the hills took only %d days (at least %d)" % [days,int(want.min_days)])
	_note("march %d km in %d days" % [roundi(float(order.get("army",{}).get("distance_total_km",0.0))),days])


# =============================================================================
# The court orders an attack; the war leader reports once
# =============================================================================

func _run_court()->void:
	home_watch(s.get("ours",[{"unit":"levy","weapon":"spear","count":90}]),3)
	var reading:=WO.read(String(s.get("words","Attack Tsaren")))
	if not _check(not reading.is_empty(),"expect","the court did not read '%s' as a war order" % String(s.get("words",""))): return
	var answer:=WO.perform(reading,true)
	if not _check(String(answer.get("verdict",""))=="act","expect","the war leader did not act: %s" % String(answer.get("says",answer.get("outcome","")))): return
	var says:=String(answer.get("says",""))
	_check(says.contains("day"),"report","the war leader's answer does not say how long the march is: %s" % says)
	var a:=int((answer.get("objective",{}) as Dictionary).get("army_id",0))
	var key:={"kind":"field_army","id":a}
	var pre:=_ledger_for(key)
	var days:=0
	while MilitaryCampaign.battle_history.is_empty() and days<40:
		day(); days+=1
		observe()
	if not _check(not MilitaryCampaign.battle_history.is_empty() or not live().is_empty(),"expect","the host never fought at Tsaren (%d days)" % days): return
	fight_out(int(s.get("max_days",20)))
	for n in 2: day()
	var rec:Dictionary=MilitaryCampaign.battle_history[0]
	var t:Dictionary=traces.get(String(rec.get("id","")),{"before":pre,"force":key})
	t["before"]=pre
	var done:=check_finished(rec,t,{"court":true})
	if done.is_empty(): return
	expect_outcome(rec,String(done.kind))
	var court:=_court_reports(int(rec.get("seed",0)))
	if OS.get_environment("BATTLE_EVAL_PROFILE")=="1":
		_note("ledger %s" % str(WO._ledger()).substr(0,400))
		_note("matters %s" % str(_war_matters().map(func(m:Dictionary)->String: return "%s %s" % [str((m.war as Dictionary).get("mode","")),String(m.text).substr(0,80)])))
	if court.size()==1:
		var text:=String((court[0] as Dictionary).text)
		_check(text.contains("My ") or text.contains(" I ") or text.begins_with("I "),"report","the war leader's court report is not in his own voice: %s" % text.substr(0,200))


# =============================================================================
# The war leader's clashes (war_loop.gd): the raid on our fields
# =============================================================================

func _run_war_raid()->void:
	var day_now:=int(GameState.elapsed_days)
	var raid:Dictionary=WarLoop._raid(civ_id,day_now,"",bool(s.get("skirmish",false)))
	var kept:Array=WarLoop.observed_battles()
	if not _check(not kept.is_empty(),"record","the raid was not kept to be watched"): return
	var rec:Dictionary=kept[0]
	var view:=Record.view(rec,View.words(rec,false))
	var left:Dictionary=((view.sides as Dictionary).left as Dictionary).totals
	var right:Dictionary=((view.sides as Dictionary).right as Dictionary).totals
	var our_dead:=int(raid.get("our_dead",0)); var their_dead:=int(raid.get("their_dead",0))
	_check(int(left.killed)==our_dead,"record","the Chronicle says %d of ours were killed, the battle view %d" % [our_dead,int(left.killed)])
	_check(int(right.killed)==their_dead,"record","the Chronicle says %d of theirs fell, the battle view %d" % [their_dead,int(right.killed)])
	_check(int(left.captured)==int(raid.get("captives",0)),"record","the Chronicle says %d of ours were taken, the battle view %d" % [int(raid.get("captives",0)),int(left.captured)])
	var entries:=(GameState.chronicle.get("entries",[]) as Array).filter(func(e:Dictionary)->bool: return String(e.get("key","")).begins_with("war:raid:%s:%d" % [civ_id,day_now]))
	_check(entries.size()==1,"report","the raid has %d Chronicle entries (should be one)" % entries.size())
	var matters:Array=_war_matters().filter(func(m:Dictionary)->bool: return String((m.war as Dictionary).get("mode",""))=="raided")
	_check(matters.size()<=1,"report","the war leader came %d times about one raid" % matters.size())
	_check(int((view.sides.left as Dictionary).totals.went_in)>0 and int((view.sides.right as Dictionary).totals.went_in)>0,"record","the kept raid has nobody on a side")


# =============================================================================
# A chase after the men who fled a town we hold
# =============================================================================

func _run_chase()->void:
	var a:=_army_at_town([{"unit":"levy","weapon":"spear","count":int(s.get("garrison",18))+1}])
	if a<=0: return
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	var ri:=CivilizationSystem._region_index(civ,city_id)
	civ.strategic_regions[ri]["controller"]="player"
	var garrison:=MilitaryCampaign.establish_occupation_force(civ_id,civ.strategic_regions[ri],float(int(s.get("garrison",18))),a)
	var held:=int(garrison.get("troops",0))
	if not _check(held>0,"setup","no garrison was left in Tsaren"): return
	Pursuit.record_flight(civ_id,city_id,int(s.get("fled",12)))
	var chase:=Pursuit.begin(civ_id,city_id)
	if not _check(not chase.has("error"),"expect","the chase did not begin: %s" % String(chase.get("error",""))): return
	var sent:=int(chase.get("troops",chase.get("sent",0)))
	var reports:=0
	for n in 12:
		GameState.elapsed_days=float(int(GameState.elapsed_days)+1)
		MilitaryCampaign.last_processed_day=int(GameState.elapsed_days)
		MilitaryCampaign._process_field_army_movement_day()
		reports+=WO.daily(int(GameState.elapsed_days)).size()
		if Pursuit.detachments().is_empty(): break
	var told:=(GameState.chronicle.get("entries",[]) as Array).filter(func(e:Dictionary)->bool: return String(e.get("key","")).begins_with("pursuit:"))
	_check(told.size()==1,"report","the chase has %d Chronicle entries (should be one)" % told.size())
	_check(reports<=1,"report","the chase was reported %d times" % reports)
	_check(Pursuit.detachments().is_empty(),"expect","the chasers never came back")
	var force:=MilitaryCampaign.occupation_force_for_region(civ_id,city_id)
	_check(int(force.get("troops",0))+int(force.get("wounded_pool",0))==held,"ledger","the garrison had %d and sent %d; now %d with %d hurt" % [held,sent,int(force.get("troops",0)),int(force.get("wounded_pool",0))])
	var flight:=Pursuit.flight_of(civ_id,city_id)
	_check(int(flight.get("caught",0))+int(flight.get("reached",0))==int(flight.get("ran",-1)),"ledger","of %d who ran, %d were caught and %d got away" % [int(flight.get("ran",0)),int(flight.get("caught",0)),int(flight.get("reached",0))])


# =============================================================================
# Pulling back: a retreat in battle; calling a march home
# =============================================================================

func _run_recall()->void:
	var a:=our_army(s.get("ours",[]),{"morale":0.8})
	if a<=0: return
	var enemy:=their_force(s.get("theirs",[]),{"morale":0.8},a)
	var key:={"kind":"field_army","id":a}
	var pre:=_ledger_for(key)
	var started:=field_contact(a,enemy,{"seed":int(s.get("seed",11))})
	if started.has("error"): return
	var id:=String(started.get("id",""))
	fight_days(1)
	_check(MilitaryCampaign.focus_engagement(id),"expect","the battle cannot be found to call the band back")
	MilitaryCampaign.advance_engagement("retreat")
	var rec:=record_of(id)
	if not _check(not rec.is_empty(),"expect","the retreat did not end the battle"): return
	var t:Dictionary=traces.get(id,{"before":pre,"force":key})
	var done:=check_finished(rec,t)
	if done.is_empty(): return
	_check(String(done.kind)=="withdrew","expect","the band was called back but the report says '%s'" % String(done.kind))
	# Then home: the recall moves them.
	var back:=MilitaryCampaign.return_field_army(a)
	_check(not back.has("error"),"expect","the band cannot be called home after pulling back: %s" % String(back.get("error","")))
	_check(String(army(a).get("status",""))=="moving" and String(army(a).get("destination_id",""))=="player_home","expect","called home, the band did not set out")
	var days:=0
	while String(army(a).get("status",""))=="moving" and days<20:
		day(); days+=1
	_check(String(army(a).get("location_id",""))=="player_home","expect","the band never reached home (%d days)" % days)


## A marching band called back turns round at once.
func _run_recall_march()->void:
	var a:=our_army([{"unit":"levy","weapon":"spear","count":40}],{"at":Vector2(0.4,0.0)})
	if a<=0: return
	var goal:=home+Vector2(30.0,0.0)
	CivilizationSystem._add_revealed_area(goal,30.0,"test survey")
	var order:=MilitaryCampaign.move_field_army_to_position(a,goal.x,goal.y,"the far hills")
	if not _check(not order.has("error"),"setup","the march was refused: %s" % String(order.get("error",""))): return
	day(); day()
	var out_at:=_v2(army(a).get("position",{}))
	var back:=MilitaryCampaign.return_field_army(a)
	_check(not back.has("error"),"expect","the marching band cannot be called home: %s" % String(back.get("error","")))
	_check(String(army(a).get("destination_id",""))=="player_home","expect","called home, the band still marches on")
	day()
	_check(_v2(army(a).get("position",{})).distance_to(home)<out_at.distance_to(home),"expect","called home, the band walked on away from home")
	var days:=0
	while String(army(a).get("status",""))=="moving" and days<20:
		day(); days+=1
	_check(String(army(a).get("location_id",""))=="player_home","expect","the band never got home")


# =============================================================================
# Our garrison attacked in a town we hold
# =============================================================================

func _run_garrison()->void:
	var a:=_army_at_town(s.get("ours",[{"unit":"levy","weapon":"spear","count":40}]))
	if a<=0: return
	var civ:Dictionary=CivilizationSystem.civilizations[0]
	var ri:=CivilizationSystem._region_index(civ,city_id)
	civ.strategic_regions[ri]["controller"]="player"
	MilitaryCampaign.establish_occupation_force(civ_id,civ.strategic_regions[ri],float(int(s.get("garrison",30))),a)
	var key:={"kind":"occupation","id":0,"civ":civ_id,"region":city_id}
	var pre:=_ledger_for(key)
	var enemy:=their_force(s.get("theirs",[]),{"morale":0.75,"readiness":0.6})
	MilitaryCampaign._create_civilization_threat({"id":"retake","source_civ_id":civ_id,"source_name":"Esurai","incident_kind":"campaign","strength":int(enemy.troops),"technology":0.2,"readiness":0.6,
		"target_region_id":city_id,"target_region_name":"Tsaren","recapture_campaign":true,"terrain_defense":1.15},"defensive")
	MilitaryCampaign.active_threat["enemy_force"]=enemy
	MilitaryCampaign.active_threat["seed"]=int(s.get("seed",11))
	var answer:=MilitaryCampaign.respond_to_threat("defend")
	if answer.has("error"): _fail("setup","the garrison did not stand: %s" % String(answer.error)); return
	fight_out(int(s.get("max_days",20)))
	var rec:Dictionary=MilitaryCampaign.battle_history[0] if not MilitaryCampaign.battle_history.is_empty() else {}
	var t:Dictionary=traces.get(String(rec.get("id","")),{"before":pre,"force":key})
	var done:=check_finished(rec,t,{"force_moves":String(done_kind_of(rec))=="lost"})
	if done.is_empty(): return
	expect_outcome(rec,String(done.kind))
	if String(done.kind)=="won":
		_check(Ledger.holds(civ_id,city_id),"ledger","the garrison held Tsaren but the town ledger says we do not hold it")


func done_kind_of(rec:Dictionary)->String:
	return String(Account.outcome_kind(rec)) if not rec.is_empty() else ""


# =============================================================================
# A save in the middle of a battle
# =============================================================================

## A battle saved after its first day and loaded again ends exactly as the
## same battle fought straight through: nothing is rolled again.
func _run_save()->void:
	var a:=our_army(s.get("ours",[]),{"morale":0.85})
	if a<=0: return
	var enemy:=their_force(s.get("theirs",[]),{"morale":0.85},a)
	var started:=field_contact(a,enemy,{"seed":int(s.get("seed",11))})
	if started.has("error"): return
	var id:=String(started.get("id",""))
	day()
	var saved:Dictionary=JSON.parse_string(JSON.stringify(MilitaryCampaign.export_state()))
	var day_saved:=int(GameState.elapsed_days)
	var population:=int(GameState.population_total)
	fight_out(20)
	var first:=record_of(id)
	var loaded:=MilitaryCampaign.import_state(saved)
	if not _check(not loaded.has("error"),"record","the save made mid-battle does not load: %s" % String(loaded.get("error",""))): return
	GameState.elapsed_days=float(day_saved); MilitaryCampaign.last_processed_day=day_saved
	GameState.ensure_population_total(population)
	resolved=[]; traces={}
	fight_out(20)
	var second:=record_of(id)
	if not _check(not first.is_empty() and not second.is_empty(),"record","the battle has no record after the load"): return
	_check(String(first.outcome)==String(second.outcome),"record","saved and loaded, the battle ended '%s' instead of '%s'" % [String(second.outcome),String(first.outcome)])
	_check((first.rounds as Array).size()==(second.rounds as Array).size(),"record","saved and loaded, it lasted %d exchanges instead of %d" % [(second.rounds as Array).size(),(first.rounds as Array).size()])
	for side in ["attacker","defender"]:
		_check(int((first[side] as Dictionary).remaining_troops)==int((second[side] as Dictionary).remaining_troops),"record","saved and loaded, the %s were left %d instead of %d" % [side,int((second[side] as Dictionary).remaining_troops),int((first[side] as Dictionary).remaining_troops)])


# =============================================================================
# Orders during and after a fight: never blocked by paperwork
# =============================================================================

func _run_blocked()->void:
	var what:=String(s.get("case","after_victory"))
	match what:
		"after_victory":
			var a:=our_army([{"unit":"levy","weapon":"spear","count":120}],{"morale":0.9})
			var b:=our_army([{"unit":"levy","weapon":"spear","count":40}],{"at":Vector2(3.0,3.0)})
			field_contact(a,their_force([{"unit":"levy","weapon":"improvised","count":30}],{"morale":0.5,"readiness":0.4}),{"seed":int(s.get("seed",11))})
			fight_out(10)
			_check(MilitaryCampaign.pending_aftermath.is_empty(),"aftermath","captives wait on the ruler after the victory")
			var quote:=MilitaryCampaign.city_operation_quote(b,civ_id,city_id)
			_check(not quote.has("error"),"aftermath","after the victory another band cannot be sent to Tsaren: %s" % String(quote.get("error","")))
			var formed:=MilitaryCampaign.create_field_army(1) if int(MilitaryCampaign.home_army.get("troops",0))>0 else {}
			_check(not formed.has("error") or not String(formed.get("error","")).contains("aftermath"),"aftermath","a band cannot form: %s" % String(formed.get("error","")))
			_check(not MilitaryCampaign.template_recruitment_blocker().contains("aftermath"),"aftermath","recruiting waits on the aftermath")
		"raid_pending":
			# Raiders are coming at home (a decision pending); a band is sent to Tsaren.
			var a:=our_army([{"unit":"levy","weapon":"spear","count":80}],{"morale":0.9,"at":Vector2(0.4,0.0)})
			home_watch([{"unit":"levy","weapon":"spear","count":30}],30)
			MilitaryCampaign._create_civilization_threat({"id":"raiders","source_civ_id":civ_id,"source_name":"Esurai","incident_kind":"raid","strength":40,"technology":0.2,"readiness":0.6},"defensive")
			var order:=MilitaryCampaign.order_city_operation(a,civ_id,city_id)
			_check(not order.has("error"),"aftermath","with raiders coming at home, a band cannot be sent to Tsaren: %s" % String(order.get("error","")))
			if order.has("error"): return
			var began:=false
			for n in 20:
				day()
				if not live().is_empty() or not MilitaryCampaign.battle_history.is_empty(): began=true; break
			_check(began,"aftermath","the band reached Tsaren but never attacked (raiders were coming at home)")
			var blocked:=(GameState.simulation_events as Array).filter(func(ev:Dictionary)->bool: return String(ev.get("title",""))=="City order blocked")
			_check(blocked.is_empty(),"aftermath","the attack on Tsaren was blocked: %s" % (String(blocked[0].get("description","")) if not blocked.is_empty() else ""))
		"siege_elsewhere":
			# One band besieges Tsaren; another is sent against the rival's town.
			var a:=_army_at_town([{"unit":"levy","weapon":"spear","count":400}])
			var begun:=MilitaryCampaign.start_offensive_siege(civ_id,city_id,a)
			if not _check(not begun.has("error"),"setup","the siege did not begin: %s" % String(begun.get("error",""))): return
			var b:=our_army([{"unit":"levy","weapon":"spear","count":60}],{"at":Vector2(0.4,0.0)})
			var rel:Dictionary=CivilizationSystem.civilizations[1].player_relation
			rel["at_war"]=true; rel["treaty"]="war"
			var quote:=MilitaryCampaign.city_operation_quote(b,civ2_id,city2_id)
			_check(not quote.has("error"),"aftermath","with a siege at Tsaren, no other band can march on Varrow: %s" % String(quote.get("error","")))


# =============================================================================
# Rivals fighting each other where our watchers can see
# =============================================================================

func _run_rival()->void:
	var place:=home+Vector2(s.get("at",Vector2(18.0,0.0)))
	WorldSimulation.create_actor(civ_id,WORLD_SEED,city)
	WorldSimulation.create_actor(civ2_id,WORLD_SEED+1,city2)
	WorldSimulation.enabled=true
	var theirs:Array=s.get("theirs",[{"unit":"levy","weapon":"spear","count":300}])
	var others:Array=s.get("others",[{"unit":"levy","weapon":"spear","count":260}])
	var rival_id:=civ_id
	var foe_id:=civ2_id
	var made:Variant=WorldSimulation.scoped(rival_id,func()->Dictionary:
		var m:Node=WorldSimulation.military
		var additions:=formations(theirs,false)
		var fid:=1000
		for f in additions: f["id"]=fid; fid+=1
		m._rebuild_home_army_with(additions)
		var formed:Dictionary=m.create_field_army(count_of(theirs),"Esurai host")
		if formed.has("error"): return formed
		var aid:=int((formed.army as Dictionary).army_id)
		var index:int=m._field_army_index(aid)
		m.field_armies[index]["position"]={"x":place.x,"z":place.y}
		m.field_armies[index]["status"]="stationed"
		var enemy:Dictionary=m.simulator.create_formation_force("Cedar League band",formations(others,false),0.75,float(m.field_armies[index].get("readiness",0.6)))
		enemy["commander"]=m.simulator.create_commander("Oru Vell",0.5,0.5,0.5,0.55)
		m.active_threat={"id":"rival","title":"x","incident_kind":"campaign","campaign_mode":"offensive","source_civ_id":foe_id,"source_name":"Cedar League","field_encounter":true,"formation_id":"cedar",
			"target_region_id":"","target_region_name":"","field_army_id":aid,"enemy_force":enemy,"terrain_defense":1.0,"seed":int(s.get("seed",11)),"deadline_day":99999,"discovered_day":int(WorldSimulation.state.elapsed_days),
			"target_position":{"x":place.x+0.3,"z":place.y}}
		return m.begin_threat_engagement(false))
	if not _check(made is Dictionary and not (made as Dictionary).has("error"),"setup","the rivals' battle did not begin: %s" % str(made)): WorldSimulation.enabled=false; return
	# Our watchers: a band of ours nearby, or none.
	var watching:=bool(s.get("watched",true))
	if watching: our_army([{"unit":"levy","weapon":"spear","count":30}],{"at":Vector2(s.get("at",Vector2(18.0,0.0)))+Vector2(-6.0,0.0)})
	var seen_days:=0
	for n in int(s.get("days",4)):
		var engine:Dictionary=WorldSimulation.scoped(rival_id,func()->Dictionary:
			var m:Node=WorldSimulation.military
			return m.active_engagement.duplicate(true) if not m.active_engagement.is_empty() else {})
		var inputs:Dictionary=overlay.collect()
		var rival_marks:=(inputs.get("battles",[]) as Array).filter(func(m:Dictionary)->bool: return not bool(m.get("ours",true)))
		_check(View.list_now().is_empty(),"panel","a battle between two other peoples is listed as one of ours")
		if engine.is_empty():
			break
		if watching:
			if _check(rival_marks.size()==1,"marker","the rivals' battle in sight of our band is marked %d times" % rival_marks.size()):
				var m:Dictionary=rival_marks[0]
				var sides:Dictionary=m.sides
				_check(String((sides.a as Dictionary).name)=="Esurai" and String((sides.b as Dictionary).name)=="Cedar League","marker","the rivals' battle names '%s' and '%s'" % [String((sides.a as Dictionary).name),String((sides.b as Dictionary).name)])
				var home_side:=String(engine.get("home_side","attacker"))
				_check(int((sides.a as Dictionary).troops)==int((engine.get(home_side,{}) as Dictionary).get("troops",0)),"marker","the rivals' battle shows %d Esurai, the engine %d" % [int((sides.a as Dictionary).troops),int((engine.get(home_side,{}) as Dictionary).get("troops",0))])
				_check(absf(float(m.progress)-Blocks.progress_for(engine.get("battle",{}),home_side))<0.001,"marker","the rivals' battle progress %.2f is not the engine's" % float(m.progress))
				seen_days+=1
		else:
			_check(rival_marks.is_empty(),"marker","a battle nobody of ours can see is on the map")
		WorldSimulation.scoped(rival_id,func()->void:
			WorldSimulation.state.elapsed_days=GameState.elapsed_days+1.0
			WorldSimulation.military.last_processed_day=int(WorldSimulation.state.elapsed_days)
			WorldSimulation.military._fight_own_battles_day())
		GameState.elapsed_days=float(int(GameState.elapsed_days)+1)
	if watching: _check(seen_days>0,"marker","our band never saw the rivals' battle")
	WorldSimulation.enabled=false
	WorldSimulation.clear()


# =============================================================================
# A battle our general fights on his own (the command staff's battles)
# =============================================================================

## A band meets theirs and the general takes the fight over: it is fought a
## day at a time with the rest, listed, marked and reported once.
func _run_commanded()->void:
	var a:=our_army(s.get("ours",[]),{"morale":0.85})
	if a<=0: return
	var key:={"kind":"field_army","id":a}
	var pre:=_ledger_for(key)
	var started:=field_contact(a,their_force(s.get("theirs",[]),{"morale":0.8},a),{"seed":int(s.get("seed",11))})
	if started.has("error"): return
	var id:=String(started.get("id",""))
	if MilitaryCampaign.active_engagement.is_empty(): _fail("setup","the battle ended before the general could take it over"); return
	MilitaryCampaign.active_engagement["commander_managed"]=true
	MilitaryCampaign.command_hierarchy.battle.archive_active()
	_check(MilitaryCampaign.own_engagements.is_empty(),"expect","the general's battle is still counted among ours")
	_check(live().size()==1,"panel","the general's battle is not among the battles being fought")
	fight_out(int(s.get("max_days",20)))
	var rec:=record_of(id)
	var t:Dictionary=traces.get(id,{"before":pre,"force":key})
	t["before"]=pre
	var done:=check_finished(rec,t)
	if not done.is_empty(): expect_outcome(rec,String(done.kind))


# =============================================================================
# Home besieged; a raid on a town's fields and stores
# =============================================================================

## A host comes against home, behind our palisade: when its day comes it
## rings Seanstone (a siege at home), the days pass, then it storms the wall.
func _run_home_siege()->void:
	home_watch(s.get("ours",[{"unit":"spearman","weapon":"shield_spear","count":120}]),int(s.get("watch",120)))
	MilitaryCampaign.settlement_defense={"stage":2,"integrity":1.0,"project_stage":-1,"project_progress":0.0,"project_work":0.0,"reserved_materials":{},"completed_day":0}
	var enemy:=their_force(s.get("theirs",[{"unit":"spearman","weapon":"shield_spear","count":400}]),{"morale":0.8,"readiness":0.6})
	MilitaryCampaign._create_civilization_threat({"id":"host","source_civ_id":civ_id,"source_name":"Esurai","incident_kind":"campaign","strength":int(enemy.troops),"technology":0.3,"readiness":0.6},"defensive")
	MilitaryCampaign.active_threat["enemy_force"]=enemy
	MilitaryCampaign.active_threat["estimated_strength"]=int(enemy.troops)
	MilitaryCampaign.active_threat["deadline_day"]=int(GameState.elapsed_days)
	MilitaryCampaign.active_threat["seed"]=int(s.get("seed",11))
	day()
	if not _check(not MilitaryCampaign.active_siege.is_empty(),"setup","the host did not ring Seanstone"): return
	for n in int(s.get("siege_days",4)):
		_observe_siege()
		day()
		if MilitaryCampaign.active_siege.is_empty(): break
	if MilitaryCampaign.active_siege.is_empty(): return
	_observe_siege()
	var pre:=_ledger_for({"kind":"field","id":0})
	var order:=MilitaryCampaign.siege_order(String(MilitaryCampaign.active_siege.id),"assault")
	if order.has("error"): _fail("setup","the storm on Seanstone did not begin: %s" % String(order.error)); return
	fight_out(int(s.get("max_days",20)))
	var rec:Dictionary=MilitaryCampaign.battle_history[0] if not MilitaryCampaign.battle_history.is_empty() else {}
	var t:Dictionary=traces.get(String(rec.get("id","")),{"before":pre,"force":{"kind":"field","id":0}})
	var done:=check_finished(rec,t,{"force_moves":true})
	if done.is_empty(): return
	expect_outcome(rec,String(done.kind))
	var said:=Account.text(done.account)
	if String(done.kind) in ["lost","withdrew"]:
		if MilitaryCampaign.recovery.home_unavailable(): _check(said.contains("Seanstone is theirs"),"report","Seanstone fell but the report does not say so: %s" % said.substr(0,260))
		else: _check(said.contains("it is still ours"),"report","they stormed Seanstone but could not hold it, and the report does not say it is still ours: %s" % said.substr(0,260))


## Our band at Tsaren raids its fields and stores (launch_raid).
func _run_raid()->void:
	var a:=_army_at_town(s.get("ours",[]))
	if a<=0: return
	var key:={"kind":"field_army","id":a}
	var pre:=_ledger_for(key)
	var result:=MilitaryCampaign.launch_raid(civ_id,city_id)
	if result.has("error"): _fail("setup","the raid did not begin: %s" % String(result.error)); return
	fight_out(int(s.get("max_days",20)))
	var rec:Dictionary=MilitaryCampaign.battle_history[0] if not MilitaryCampaign.battle_history.is_empty() else {}
	var t:Dictionary=traces.get(String(rec.get("id","")),{"before":pre,"force":key})
	var done:=check_finished(rec,t)
	if done.is_empty(): return
	expect_outcome(rec,String(done.kind))
	# A raid takes no town: Tsaren is still theirs, and no garrison is left.
	_check(MilitaryCampaign.occupation_force_for_region(civ_id,city_id).is_empty(),"expect","a raid left a garrison in Tsaren")
	_check(not String((done.account as Dictionary).headline).contains("took Tsaren"),"report","the report of a raid says we took the town")
	var said:=Account.text(done.account)
	if String(done.kind)=="won":
		_check(said.contains("raided the fields and stores of Tsaren") and not said.contains("gate is shut"),"report","the report of a won raid talks of a gate still to storm: %s" % said.substr(0,260))
