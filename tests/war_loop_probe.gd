extends Node
## War in the living world (scripts/war_loop.gd), end to end, offline.
##
## A small stone-age people (140) among ten generated neighbours with real
## ledgers. The probe walks the whole loop and checks each step:
##   1. a real tribute demand is refused; the ruler follows through with a
##      raid inside two years; the Chronicle names the dead; the war leader
##      carries a court matter;
##   2. the god summons the war leader and gives an objective in words
##      ("burn their stores"); the general runs it; the combat simulator
##      decides it; a report comes back;
##   3. war: the general is ordered to act, operations and enemy attacks are
##      fought, and the war ends in a truce (or tribute, or exhaustion);
##   4. population falls on both sides by what the log says died; bands stay
##      within the pre-modern mobilisation cap;
##   5. a called bluff still collapses with no raid;
##   6. standing with kin in their war drags the people into it;
##   7. saves: the war ledger round-trips and older saves load.
## Writes a transcript to res://reports/war/war_loop.txt (reports/ is ignored).
##   <godot> --headless --path <worktree> res://tests/war_loop_probe.tscn

const HALL:=preload("res://scripts/audience_hall.gd")
const HallProbe:=preload("res://tests/audience_hall_probe.gd")
const RIVALS:=preload("res://scripts/rival_rulers.gd")
const WAR:=preload("res://scripts/war_loop.gd")
const OUT_PATH:="res://reports/war/war_loop.txt"

var probe:Node
var failures:PackedStringArray=PackedStringArray()
var out:PackedStringArray=PackedStringArray()
var day:=1

func check(ok:bool,message:String)->void:
	if not ok: failures.append(message); push_error(message)

func _ready()->void:
	probe=HallProbe.new()
	_setup()
	out.append("WAR IN THE LIVING WORLD — offline probe, a people of %d among %d neighbours" % [GameState.population_total,CivilizationSystem.civilizations.size()])
	var civ_id:=_refusal_then_raid()
	if civ_id!="":
		_order_the_general(civ_id)
		_war_to_truce(civ_id)
	_bluff_collapses()
	_dragged_in()
	_rival_war_rate()
	_saves()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://reports/war/"))
	var file:=FileAccess.open(OUT_PATH,FileAccess.WRITE)
	file.store_string("\n".join(out)+"\n"); file.close()
	print("\n".join(out))
	print("WAR_LOOP wrote %s" % ProjectSettings.globalize_path(OUT_PATH))
	print("WAR_LOOP "+("PASS" if failures.is_empty() else "FAIL: "+"; ".join(failures)))
	get_tree().quit(0 if failures.is_empty() else 1)

func _setup()->void:
	probe._base()
	GameState.opponent_count=10
	CivilizationSystem.reset_for_new_world()
	ForeignDiplomacy.reset_for_new_world(); GovernmentPeopleSystem.reset_for_new_world()
	probe._people(140)
	probe._refill()
	var index:=0
	for civ in CivilizationSystem.civilizations:
		var relation:Dictionary=civ.player_relation
		relation.contact_level=2; relation.home_location_known=true; relation.met_day=0
		relation.opinion=-0.1; relation.border_tension=0.3
		civ.food_days=45.0
		civ.population=150.0
		for other in civ.relations: civ.relations[other].at_war=false
		probe._stock_actor(String(civ.id),800,120)
		WorldSimulation.scoped(String(civ.id),func()->void:WorldSimulation.state.ensure_population_total(150))
		index+=1
	probe._fill_court()
	day=1
	GameState.elapsed_days=day

func _their_pop(civ_id:String)->int:
	return int(WorldSimulation.scoped(civ_id,func()->int:return int(WorldSimulation.state.population_total)))

func _advance(days:int,civ_id:String="",until:Callable=Callable())->bool:
	for i in days:
		day+=1
		GameState.elapsed_days=day
		probe._refill()
		WAR.daily(day)
		if until.is_valid() and bool(until.call()): return true
	return false

func _threat(civ_id:String,bluff:bool)->Dictionary:
	var audience:=HALL._new_audience("foreign","threat",day)
	audience.civ_id=civ_id; audience.civ_name=HALL._civ_name(civ_id)
	audience.speaker={"name":"Herald of "+HALL._civ_name(civ_id),"title":"Herald","person_id":0,"role":"envoy"}
	audience.terms={"resource":"Food","amount":40.0}
	audience.situation={"type":"tribute_demand","ask":"tribute:Food","headline":"demands tribute","summary":"%s demands 40 Food in tribute." % HALL._civ_name(civ_id)}
	audience["hidden"]={"bluff":bluff}
	RIVALS.character(civ_id)
	HALL._enqueue(audience,day,true)
	return audience

func _log_since(count:int)->Array:
	var list:Array=WAR.state().log
	return list.slice(0,maxi(0,list.size()-count))

func _war_matter(civ_id:String)->Dictionary:
	for m in HALL.matters():
		if String(m.get("situation_type",""))=="war_campaign" and String((((m.get("audience",{}) as Dictionary).get("situation",{}) as Dictionary).get("war",{}) as Dictionary).get("civ_id",""))==civ_id: return m
	return {}

func _feed(prefix:String)->Array:
	var found:Array=[]
	for entry in (GameState.chronicle.get("entries",[]) as Array):
		if String(entry.get("key","")).begins_with(prefix): found.append(entry)
	return found

# ------------------------------------------------------------------ 1

func _refusal_then_raid()->String:
	out.append("\n1. A REAL DEMAND REFUSED")
	var chosen:=""
	for civ in CivilizationSystem.civilizations:
		var civ_id:=String(civ.id)
		var audience:=_threat(civ_id,false)
		var result:=HALL.resolve(String(audience.id),"defy")
		check(bool(result.get("ok",false)),"Refusing a demand failed: %s" % String(result.get("outcome","")))
		var entry:Dictionary=(WAR.state().refusals as Array)[0]
		out.append("  %s (%s): %s -> follow-through %s (chance %.2f)" % [HALL._civ_name(civ_id),String(RIVALS.character(civ_id).trait),String(result.get("outcome","")).left(120),str(entry.follow),float(entry.chance)])
		if bool(entry.follow): chosen=civ_id; break
	check(chosen!="","No ruler followed through on a real refusal among ten")
	if chosen=="": return ""
	var pop_before:=GameState.population_total
	var food_before:=HALL.player_stock("Food")
	var raided:=_advance(730,chosen,func()->bool:return (WAR.state().log as Array).any(func(e:Dictionary)->bool:return String(e.civ)==chosen and String(e.kind) in ["raid","skirmish","war"]))
	check(raided,"The refusal was not followed by a raid within two years")
	var refusal:Dictionary=(WAR.state().refusals as Array).filter(func(r:Dictionary)->bool:return String(r.civ)==chosen)[0]
	check(int(refusal.harm_day)>=0 and int(refusal.harm_day)-int(refusal.day)<=730,"The refusal is not marked as followed by harm within two years")
	var entry2:Dictionary=(WAR.state().log as Array).filter(func(e:Dictionary)->bool:return String(e.civ)==chosen and String(e.kind) in ["raid","skirmish","war"])[0]
	out.append("  day %d (%d days later): %s" % [int(entry2.day),int(entry2.day)-int(refusal.day),String(entry2.text)])
	var dead:=int(entry2.get("our_dead",0))+int(entry2.get("captives",0))
	check(GameState.population_total==pop_before-dead,"Our population changed by %d, the raid reported %d dead or taken" % [pop_before-GameState.population_total,dead])
	check(int(entry2.get("taken",0))==0 or HALL.player_stock("Food")<food_before+4000,"Food taken was not debited")
	check(not _feed("war:raid:"+chosen).is_empty(),"The raid is not in the Chronicle")
	var m:=_war_matter(chosen)
	check(not m.is_empty(),"The war leader carries no matter after the raid")
	if not m.is_empty(): out.append("  matter held by %s (%s): %s" % [String(m.holder.name),String(m.holder.title),String(m.summary).left(160)])
	return chosen

# ------------------------------------------------------------------ 2

func _summon(civ_id:String)->Dictionary:
	var m:=_war_matter(civ_id)
	if m.is_empty(): return {}
	return HALL.open_matter(String(m.id))

func _order_the_general(civ_id:String)->void:
	out.append("\n2. THE GOD GIVES AN OBJECTIVE")
	var audience:=_summon(civ_id)
	check(not audience.is_empty(),"The war leader could not be summoned")
	if audience.is_empty(): return
	for line in HALL.find(String(audience.id)).get("lines",[]): out.append("  %s: %s" % [String(line.speaker),String(line.text)])
	var ids:Array=HALL.options(String(audience.id)).map(func(o:Dictionary)->String:return String(o.id))
	out.append("  options: %s" % ", ".join(PackedStringArray(HALL.options(String(audience.id)).map(func(o:Dictionary)->String:return "%s (%s)" % [String(o.label),String(o.sub)]))))
	for want in ["war_pursue","war_burn","war_guard","war_parley","war_let"]: check(want in ids,"Raid matter lacks %s" % want)
	var typed:=WAR.typed_choice(String(audience.id),"Burn their stores to the ground.")
	check(typed=="war_burn","Typed 'burn their stores' mapped to '%s'" % typed)
	check(WAR.typed_choice(String(audience.id),"Hold the ford against them")=="war_guard","Typed 'hold the ford' did not map to guarding")
	var their_before:=_their_pop(civ_id)
	var ours_before:=GameState.population_total
	var result:=HALL.resolve(String(audience.id),typed)
	check(bool(result.get("ok",false)),"Ordering the general failed: %s" % String(result.get("outcome","")))
	out.append("  You: Burn their stores to the ground.\n  -> %s" % String(result.get("outcome","")))
	var done:=_advance(60,civ_id,func()->bool:return (WAR.state().log as Array).any(func(e:Dictionary)->bool:return String(e.civ)==civ_id and String(e.kind)=="op_burn"))
	check(done,"The burning raid never came back")
	var op:Dictionary=(WAR.state().log as Array).filter(func(e:Dictionary)->bool:return String(e.civ)==civ_id and String(e.kind)=="op_burn")[0]
	out.append("  day %d: %s" % [int(op.day),String(op.text)])
	check(_their_pop(civ_id)<=their_before-int(op.their_dead),"Their population did not fall by their dead (%d -> %d, %d dead)" % [their_before,_their_pop(civ_id),int(op.their_dead)])
	check(GameState.population_total<=ours_before-int(op.our_dead)+1,"Our population did not fall by our dead")
	check(not _war_matter(civ_id).is_empty(),"No report matter came back from the field")

# ------------------------------------------------------------------ 3

func _war_to_truce(civ_id:String)->void:
	out.append("\n3. WAR, AND ITS END")
	var s:=WAR.state()
	var f:=WAR.front(civ_id)
	f["pending"]={}; f["last_war_end"]=-99999
	var their_before:=_their_pop(civ_id)
	var ours_before:=GameState.population_total
	WAR.declare(civ_id,day,"the tribute you would not pay")
	var relation:Dictionary=WAR._relation(civ_id)
	check(bool(relation.get("at_war",false)),"Declared war did not set the relation at war")
	check(String(relation.get("war_id",""))!="","War has no war record")
	var audience:=_summon(civ_id)
	check(not audience.is_empty(),"No war matter to summon the general for")
	if not audience.is_empty():
		for line in HALL.find(String(audience.id)).get("lines",[]): out.append("  %s: %s" % [String(line.speaker),String(line.text)])
		var ids:Array=HALL.options(String(audience.id)).map(func(o:Dictionary)->String:return String(o.id))
		for want in ["war_guard","war_burn","war_chief","war_parley","war_general"]: check(want in ids,"War matter lacks %s" % want)
		check(WAR.typed_choice(String(audience.id),"Bring me their chief in chains")=="war_chief","Typed 'bring me their chief' did not map")
		var r:=HALL.resolve(String(audience.id),"war_chief")
		out.append("  You: Bring me their chief.\n  -> %s" % String(r.get("outcome","")))
	var ended:=false
	var guard:=0
	while not ended and guard<30:
		guard+=1
		ended=_advance(40,civ_id,func()->bool:return (WAR.front(civ_id).war as Dictionary).is_empty())
		if ended: break
		var m:=_war_matter(civ_id)
		if not m.is_empty():
			var a:=HALL.open_matter(String(m.id))
			if not a.is_empty():
				var choice:="war_parley" if guard>=3 else "war_burn"
				if "war_pay" in HALL.options(String(a.id)).map(func(o:Dictionary)->String:return String(o.id)) and guard>=5: choice="war_pay"
				var r2:=HALL.resolve(String(a.id),choice)
				out.append("  day %d, you: %s -> %s" % [day,choice,String(r2.get("outcome","")).left(160)])
	check(ended,"The war never ended")
	for e in (s.log as Array).slice(0,12):
		if String(e.civ)==civ_id and String(e.kind) in ["op_burn","op_chief","op_parley","enemy_attack","war_end","parley_ok","parley_refused"]: out.append("  [%s day %d] %s" % [String(e.kind),int(e.day),String(e.text)])
	relation=WAR._relation(civ_id)
	check(not bool(relation.get("at_war",false)) and String(relation.get("treaty",""))=="truce","The war did not end in a truce (treaty %s)" % String(relation.get("treaty","")))
	var record:Dictionary={}
	for w in CivilizationSystem.war_history:
		if String(w.get("id",""))==String(relation.get("war_id","")): record=w
	check(not record.is_empty() and String(record.get("status",""))=="ended","The war record was not closed")
	var end:Dictionary=(s.log as Array).filter(func(e:Dictionary)->bool:return String(e.civ)==civ_id and String(e.kind)=="war_end")[0] if (s.log as Array).any(func(e:Dictionary)->bool:return String(e.civ)==civ_id and String(e.kind)=="war_end") else {}
	check(not end.is_empty(),"No war end in the log")
	out.append("  population: ours %d -> %d, theirs %d -> %d" % [ours_before,GameState.population_total,their_before,_their_pop(civ_id)])
	check(GameState.population_total<ours_before or _their_pop(civ_id)<their_before,"Neither population changed through a war")
	check(_their_pop(civ_id)<their_before,"Their population did not fall in the war")
	# Mobilisation stays within the pre-modern cap (EPOCHAL_SHIFTS s3.4).
	for e in s.log:
		if int(e.get("band",0))>0: check(int(e.band)<=maxi(3,ceili(GameState.population_total*0.07))+1,"A band of %d exceeds the mobilisation cap" % int(e.band))
	check(WAR._truce_binds(civ_id,day),"No truce binds after the war")

# ------------------------------------------------------------------ 5

func _bluff_collapses()->void:
	out.append("\n5. A CALLED BLUFF")
	var civ_id:=String(CivilizationSystem.civilizations[-1].id)
	var f:=WAR.front(civ_id)
	f["pending"]={}
	var audience:=_threat(civ_id,true)
	var result:=HALL.resolve(String(audience.id),"defy")
	out.append("  %s" % String(result.get("outcome","")))
	check(String(result.get("outcome","")).contains("bluff"),"A called bluff did not collapse")
	check((WAR.front(civ_id).pending as Dictionary).is_empty(),"A called bluff scheduled a raid")

# ------------------------------------------------------------------ 6

func _dragged_in()->void:
	out.append("\n6. KIN AT WAR")
	var ally:=String(CivilizationSystem.civilizations[1].id)
	var enemy:=String(CivilizationSystem.civilizations[2].id)
	if WAR.has_campaign(enemy) or WAR._truce_binds(enemy,day): enemy=String(CivilizationSystem.civilizations[3].id)
	RIVALS.character(ally)
	RIVALS.bond(ally,"marriage","the marriage of Wren into your people")
	probe._set_war(ally,enemy,true)
	var audience:=HALL._new_audience("foreign","proposal",day)
	audience.civ_id=ally; audience.civ_name=HALL._civ_name(ally)
	audience.speaker={"name":"Envoy","title":"Envoy","person_id":0,"role":"envoy"}
	audience.situation={"type":"war_support","ask":"war_support:"+enemy,"enemy":enemy,"enemy_name":HALL._civ_name(enemy),"headline":"asks you to take a side","summary":"%s is at war with %s." % [HALL._civ_name(ally),HALL._civ_name(enemy)]}
	HALL._enqueue(audience,day,true)
	var stand:Dictionary=HALL.options(String(audience.id)).filter(func(o:Dictionary)->bool:return String(o.id)=="stand")[0]
	out.append("  option: %s — %s" % [String(stand.label),String(stand.sub)])
	var result:=HALL.resolve(String(audience.id),"stand")
	out.append("  %s" % String(result.get("outcome","")))
	check(WAR.has_campaign(enemy),"Standing with kin did not bring war with their enemy")
	check(bool(WAR._relation(enemy).get("at_war",false)),"The enemy's relation is not at war")
	var entry:Dictionary=(WAR.state().log as Array)[0]
	out.append("  %s" % String(entry.get("text","")))

# ------------------------------------------------------------------ 8

func _rival_war_rate()->void:
	out.append("
8. RIVAL WARS: BENCHMARK HAZARD")
	var civs:=CivilizationSystem.civilizations
	var counts:=WAR.neighbour_counts()
	var expected:=0.0
	var pairs:=0
	for i in civs.size():
		for j in range(i+1,civs.size()):
			var a:Vector2=civs[i].get("position",Vector2.ZERO); var b:Vector2=civs[j].get("position",Vector2.ZERO)
			if a.distance_to(b)>WAR.NEIGHBOUR_RANGE: continue
			var relation:Dictionary=(civs[i].relations as Dictionary).get(String(civs[j].id),{})
			if relation.is_empty(): continue
			pairs+=1
			expected+=WAR.rival_war_hazard(civs[i],civs[j],{"opinion":relation.get("opinion",0.0),"border_tension":relation.get("border_tension",0.2)},(float(counts.get(String(civs[i].id),1))+float(counts.get(String(civs[j].id),1)))*0.5)
	var per_civ_century:=expected*2.0/maxf(1.0,civs.size())*100.0
	out.append("  %d neighbouring pairs; expected war participation %.2f per people per century (benchmark 0.15-0.6 ancient, up to 1.0 medieval)" % [pairs,per_civ_century])
	check(per_civ_century>=0.1 and per_civ_century<=1.0,"Rival war hazard %.2f per people-century is outside the benchmark" % per_civ_century)

# ------------------------------------------------------------------ 7

func _saves()->void:
	out.append("\n7. SAVES")
	var saved:=ForeignDiplomacy.export_state()
	check(HALL.validate_state(saved.audiences),"The audience state with a war ledger does not validate")
	var before:=JSON.stringify(WAR.summary())
	var imported:=ForeignDiplomacy.import_state(saved.duplicate(true))
	check(not imported.has("error"),"Round trip failed: %s" % String(imported.get("error","")))
	check(JSON.stringify(WAR.summary())==before,"The war ledger changed across a save round trip")
	var old:Dictionary=saved.duplicate(true)
	(old.audiences as Dictionary).erase("war")
	var legacy:=ForeignDiplomacy.import_state(old)
	check(not legacy.has("error"),"A save from before the war ledger does not load: %s" % String(legacy.get("error","")))
	check((WAR.state().fronts as Dictionary).is_empty(),"An older save did not start an empty war ledger")
	out.append("  round trip and older save: %s" % ("ok" if failures.is_empty() else "see failures"))
